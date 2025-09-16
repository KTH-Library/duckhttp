u <- list(username = "gizmosql_username", password = "sqlflite_password")

u <- list(username = "demetrius", password = "demetrius")

b64creds <- 
	charToRaw(paste0(u$username, ":", u$password)) |> 
	base64enc::base64encode()

header <- paste("Authorization: Basic", b64creds)

adbi_uri <- "grpc://openalex.duckdns.org:31337/"

con <- 
  adbi::dbConnect(
	  drv = adbi::adbi("adbcflightsql"), 
	  uri = adbi_uri,
    username = u$username,
    password = u$password #,
	  # see https://arrow.apache.org/adbc/current/driver/flight_sql.html
	  # adbc.flight.sql.authorization_header = header
	) 

con
on.exit(DBI::dbDisconnect(con))


sql <- "from duckdb_tables() select table_name;"
adbc_query(con, sql)

# print and exit
con |> DBI::dbGetQuery(sql) |> tibble::as_tibble()

con |> DBI::dbListTables()

con |> DBI::dbGetQuery("describe from publishers") |> as_tibble()

con |> DBI::dbGetQuery("from publishers select pid:publisher_id::varchar, display_name") |> as_tibble()

con |> dplyr::tbl("publishers")


# DBI::dbReadTableArrow(con, "topics")

con |> dplyr::tbl("topics") |> 
con |> dplyr::tbl("publishers")

#
con |> DBI::dbWriteTable("my_temp_dois", my_df_with_dois)