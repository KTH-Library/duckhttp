cs <- function(username, password, fmt) {

  cs <- Sys.getenv("CS_DUCKSERVE")

  if (cs != "") 
    return(cs) 
  
  if (missing(fmt)) {
    fmt <- "https://%s:%s@bibliometrics.lib.kth.se/api/duckserve/?default_format=CSV"
    stop("Please provide a connection string format, such as ", fmt)
  }
  
  fmt |> sprintf(username, password)

}

cs_default <- function() {
  cs("dauf", "dauf", "https://%s:%s@bibliometrics.lib.kth.se/api/duckserve/?default_format=CSV")
}

read_csv_httpserver <- function(query, cs = cs_default()) {
  if(missing(cs)) 
    stop("please provide connectionstring using the cs() fcn")
  
  paste0(cs, "&q=%s") |> 
    sprintf(utils::URLencode(reserved = TRUE, query)) |> 
    readr::read_csv(show_col_types = FALSE, col_names = FALSE)
}

read_csv_duckserve <- function(query, cs = cs_default()) {
  read_csv_httpserver(query, cs)
}

query <- "from state" 

read_csv_duckserve(query)

"from 's3://openalex/data/merged_ids/authors/2024-07-22.csv.gz'" |> 
  read_csv_duckserve(cs = 
    "https://demetrius:demetrius@openalex.duckdns.org/api/?url=/api/"
  )

"describe from 's3://openalex/data/merged_ids/authors/2024-07-22.csv.gz'" |> 
  read_csv_duckserve(cs = 
    "https://demetrius:demetrius@openalex.duckdns.org/api/?url=/api/&format=CSV"
  )

