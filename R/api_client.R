#' Create a connection to a duckdb httpserver instance
#' @param connectionstring the connectionstring to use for the duckdb httpserver
#' @param quiet a boolean indicating whether some messages should be displayed
#' @param api_key a character only provided if using an API key
#' @details
#' The connectionstring should follow this pattern:
#' http(s)://user:pass@hostname/path/
#' 
#' Examples:
#' 
#' http://localhost/duckserve/
#' https://user:pass@some.server.tld/duckserve/
#' 
#' When not using basic auth (like above), use the api_key parameter
#' 
#' @import httr2
#' @return a connection object which can be used with the other functions
#' @export
duckhttp_con <- function(connectionstring = NULL, quiet = TRUE, api_key) {

  if (is.null(connectionstring)) {
    connectionstring <- "http://localhost/duckserve/"
    if (!quiet) {
      message("No connectionstring (example: 'https://user:pass@some.server.tld/duckserve/') was given")
      message("Attempting default 'http://localhost/duckserve/")
    }
  }

  con <- httr2::url_parse(connectionstring)
  #con$path <- con$path |> gsub(pattern = "(.*?)/$", replacement = "\\1")  

  if (!is.null(con$username) & !is.null(con$password)) {
    user <- con$username
    con$username <- NULL
    pass <- con$password
    con$password <- NULL
    if (!quiet) message("Using basic authorized connection, user and pass was provided.")
  } else {
    user <- pass <- ""
    if (!quiet) message("Note: unauthenticated connection, no user/pass provided.")
  }

  if (!quiet) print(con)

  url_base <- httr2::url_build(con)
  ui_base <- ifelse(nzchar(con$path), paste0(url_base, "&url=", con$path), url_base)
  ping <- url_base |> paste0("ping")

  con <- list(
    url_base = url_base,
    ui_base = ui_base,
    ping = ping,
    user = user,
    pass = pass,
    quiet = quiet
  )

  if (!missing(api_key)) 
    con$api_key <- api_key
  
  return(con)

}


#' Check that a duckdb httpserver instance is available
#' 
#' @param con the connection for the duckdb httpserver, see duckhttp_con()
#' @import httr2
#' @return TRUE if available, otherwise FALSE
#' @export
duckhttp_ping <- function(con = duckhttp_con(quiet = TRUE)) {
  request(con$ping) |> 
  req_auth_basic(username = con$user, password = con$pass) |> 
  req_perform() |> 
  resp_body_string() |> 
  tolower() == "ok"
}

#' List available tables
#' @param con the connection for the duckdb httpserver, see duckhttp_con()
#' @importFrom dplyr pull
#' @return a character vector of table names
#' @export
duckhttp_ls <- function(con = duckhttp_con(quiet = TRUE)) {
  con |> duckhttp_read(
    "from information_schema.tables
    select table_name 
    where table_schema != 'system';"
  ) |> dplyr::pull(1)
}

#' Issue a query against a remote duckdb instance running the httpserver extension (with JSONCompact formatted results converted to data frame)
#' @param con the connection, by default from duckhttp_con()
#' @param query the sql query to issue against the duckdb httpserver
#' @return a tibble with results from the query
#' @import httr2
#' @import RcppSimdJson
#' @importFrom readr type_convert
#' @importFrom stats setNames
#' @importFrom tibble as_tibble
#' @export
duckhttp_read <- function(con = duckhttp_con(quiet = TRUE), query = NULL) {
  
  if (is.null(query))
    stop("Please provide a valid duckdb sql query or statement")
  if (!duckhttp_ping(con))
    stop("No connection available")

  req <- 
    request(con$url_base) |>
    req_url_query(default_format = "JSONCompact") |> 
    req_method("POST") |>
#    req_headers(`Content-Type` = "text/plain") |> 
    req_body_raw(query, type = "text/plain") 
  
  # authenticate if required
  if (!is.null(con$api_key)) {
    req <- req |> 
      req_headers(`X-API-Key` = con$api_key, .redact = "Authorization")
  } else if (is.null(con$api_key) & !is.null(con$user) & !is.null(con$pass)) {
    req <- req |> 
      req_auth_basic(username = con$user, password = con$pass)
  }

  resp <- req |> req_perform()

#resp |> httr2::resp_body_string()

  ct <- function(types) {

    lookup <- function(x) {
      switch(x,
        "Float" = "d",
        "Double" = "d",
        "Int32" = "i",
        "Int64" = "i",
        "UInt64" = "i",
        "String" = "c",
        "DateTime" = "?",
        "Date" = "D",
        "Int8" = "l",
        "NUMBER" = "d",
        "STRING" = "c",
        "?"
      )
    }

    vapply(types, lookup, character(1)) |> unname() |> 
      paste(collapse = "")
    
  }

  tibble_from_jsoncompact <- function(resp) {
    obj <- httr2::resp_body_raw(resp) |> RcppSimdJson::fparse()
    if ("quiet" %in% names(con) && con$quiet == FALSE) {
      print(obj)
      message("Query is: ", query)
      message("Request was: ")
      print(httr2::req_dry_run(httr2::resp_request(resp)))
    }
    df <- obj$data |> as.data.frame() |> tibble::as_tibble() |> setNames(nm = obj$meta$name)
    idx <- which(nchar(names(df)) > 0)
    ct <- rep("?", ncol(df[,idx])) |> paste(collapse = "")
    n_character_cols <- length(idx) #na.omit(names(df)) |> length()
 #     df |> dplyr::select(where(is.character)) |> ncol() 
    if (n_character_cols > 0) {
      res <- 
        df[,idx] |> readr::type_convert(guess_integer = TRUE, col_types = ct)
    } else {
      res <- df
    }

    res
     
  }

  resp |> tibble_from_jsoncompact()

}

#' Issue a query against a remote duckdb instance running the httpserver extension (with CSV formatted results converted to data frame)
#' @param con the connection, by default from duckhttp_con()
#' @param query the sql query to issue against the duckdb httpserver
#' @return a tibble with results from the query
#' @import httr2
#' @importFrom tibble as_tibble
#' @importFrom readr read_csv
#' @export
duckhttp_read_csv <- function(con = duckhttp_con(quiet = TRUE), query = NULL) {
  
  if (is.null(query))
    stop("Please provide a valid duckdb sql query or statement")
  if (!duckhttp_ping(con))
    stop("No connection available")

  req <- 
    request(con$url_base) |>
    req_url_query(default_format = "CSV") |> 
    req_method("POST") |>
#    req_headers(`Content-Type` = "text/plain") |> 
    req_body_raw(query, type = "text/plain") 
  
  # authenticate if required
  if (!is.null(con$api_key)) {
    req <- 
      req |> 
      req_headers(`X-API-Key` = con$api_key, .redact = "Authorization")
  } else if (is.null(con$api_key) & !is.null(con$user) & !is.null(con$pass)) {
    req <- req |> 
      req_auth_basic(username = con$user, password = con$pass)
  }

  resp <- req |> req_perform()

  httr2::resp_body_string(resp) |> 
    readr::read_csv(show_col_types = FALSE)


}

#' Open the duckdb httpserver web UI
#' @param con the connection object from duckhttp_con()
#' @return the url base for the web ui
#' @export 
#' @importFrom utils browseURL
duckhttp_ui <- function(con = duckhttp_con(quiet = FALSE)) {
  message("Please open the following url in your browser: ")
  if (interactive()) browseURL(con$ui_base)
  con$ui_base
}



duckhttp_adbc_con_default <- function(uri, username = "gizmosql_username", password = "gizmosql_password") {
  if (Sys.getenv("ADBC_FLIGHTSQL_URI") != "") {
    message("No connectionstring given, but found ADBC_FLIGHTSQL_URI in env.")
    uri <- Sys.getenv("ADBC_FLIGHTSQL_URI")
  } else {
    message("No uri given (such as 'user[:password]@grpc://127.0.0.1:31337/database[?param1=value1]')... attempting defaults")
    uri <- "grpc://127.0.0.1:31337/"
  }
  return(list(uri = uri, password = password, username = username))
}


#' Get a connection to flight sql server
#' @param cs connectionstring, by default duckhttp_adbc_con_default
#' @return an adbc connection object
#' @importFrom adbcdrivermanager adbc_database_init adbc_connection_init
#' @importFrom adbi dbConnect
#' @export
adbc_connect <- function(cs) {

  if (missing(cs)) {
    cs <- duckhttp_adbc_con_default()
  } else {
    cs <- duckhttp_con(cs)
    cs$uri <- cs$url_base
    cs$username <- cs$user
    cs$password <- cs$pass
  }

  
  adbi::dbConnect(adbi::adbi("adbcflightsql"),
    uri = cs$uri,
    username = cs$username,
    password = cs$password
  )
  
}

#' Enumerate tables at remote Flight SQL server
#' @param adbc_con an object returned from adbc_connect
#' @return a character vector of available tables
#' @importFrom DBI dbListTables
#' @export
adbc_tables <- function(adbc_con) {
    DBI::dbListTables(adbc_con)
}

#' Read full table from remote Flight SQL server
#' @param adbc_con an object returned from adbc_connect
#' @param tablename the name of a table to return data from
#' @return a tibble
#' @importFrom DBI dbReadTable
#' @importFrom tibble as_tibble
#' @export
adbc_table <- function(adbc_con, tablename) {
    DBI::dbReadTable(adbc_con, name = tablename) |> tibble::as_tibble()
}

#' Disconnect from the Flight SQL server
#' @param adbc_con an adbc connection object
#' @importFrom adbi dbDisconnect
#' @export
adbc_disconnect <- function(adbc_con) {
  adbi::dbDisconnect(adbc_con)
}

#' Query a Flight SQL server
#' @param adbc_con an adbc connection object
#' @param query the sql query
#' @param silent boolean to indicate if progress should be reported
#' @importFrom DBI dbSendQueryArrow dbHasCompleted dbFetchArrowChunk 
#' @importFrom dplyr bind_rows as_tibble
#' @export
adbc_query <- function(adbc_con, query, silent = FALSE) {

  res <- DBI::dbSendQueryArrow(adbc_con, statement = query)
  ret <- as.data.frame(DBI::dbFetchArrowChunk(res))

  while (!DBI::dbHasCompleted(res)) {
    ret <- dplyr::bind_rows(ret, as.data.frame(DBI::dbFetchArrowChunk(res)))
    #if (!silent) message("fetched ", nrow(ret), " rows")
  }

  DBI::dbClearResult(res)

  return (dplyr::as_tibble(ret)) 
}

# # would like to connect to an sqlflite server started like this
# docker run --name sqlflite --detach --rm --tty --init --publish 31337:31337 \
#   --env TLS_ENABLED="0" --env SQLFLITE_PASSWORD="sqlflite_password" \
#   --env PRINT_QUERIES="1" --env INIT_SQL_COMMANDS="SET threads = 1; SET memory_limit = '1GB';" \
#   --pull missing voltrondata/sqlflite:latest

# this works

#sqlflite_client --command Execute --host localhost --port 31337 \
  #--username "sqlflite_username" --password "sqlflite_password" \
  #--query "from read_json_auto('https://api.openalex.org/works?page=1&filter=authorships.author.id:a5058057533&sort=cited_by_count:desc&per_page=10');" \
  #--tls-skip-verify

