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
  ui_base <- paste0(url_base, "&url=", con$path)
  ping <- paste0(url_base, "/ping")

  con <- list(
    url_base = url_base,
    ui_base = ui_base,
    ping = ping,
    user = user,
    pass = pass
  )

  if (!missing(api_key)) con$api_key <- api_key
  return(con)

}


#' Check that a duckdb httpserver instance is available
#' 
#' @param con the connection for the duckdb httpserver, see duckhttp_con()
#' @import httr2
#' @return TRUE if available, otherwise FALSE
#' @export
duckhttp_ping <- function(con = duckhttp_con(quiet = TRUE)) {
  request(con$ping) |> req_perform() |> resp_body_string() == "OK"
}

#' Read data from duckdb running httpserver extension
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
        "?"
      )
    }

    vapply(types, lookup, character(1)) |> unname() |> 
      paste(collapse = "")
    
  }

  tibble_from_jsoncompact <- function(resp) {
    obj <- httr2::resp_body_raw(resp) |> RcppSimdJson::fparse()
    df <- obj$data |> as.data.frame() |> tibble::as_tibble() |> setNames(nm = obj$meta$name)
    ct <- rep("?", ncol(df)) |> paste(collapse = "")
    df |> readr::type_convert(guess_integer = TRUE, col_types = ct(obj$meta$type)) 
  }

  resp |> tibble_from_jsoncompact()

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
