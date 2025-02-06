
<!-- README.md is generated from README.Rmd. Please edit that file -->

# duckhttp

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/KTH-Library/duckhttp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/KTH-Library/duckhttp/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of duckhttp is to provide functions to query and read responses
from a duckdb server running the httpserver extension.

## Getting a connection

``` r
library(duckhttp)

# below we assume a duckdb with httpserver extension is running locally 
# serving http requests against http://localhost/duckserve/ (default)
# the url_base parameter can be used to specify any other location of the service

con <- duckhttp_con("http://localhost/duckserve/")

# to check that the service is up, use:
con |> duckhttp_ping()
#> [1] TRUE

# to access the server ui in the browser (works if the API is not authenticated):
con |> duckhttp_ui()
#> Please open the following url in your browser:
#> [1] "http://localhost/duckserve/&url=/duckserve/"
```

## Query

Once connected, issue a simple query:

``` r
# to issue an sql query, use the duckhttp_read() fcn
query <- "from lineitem limit 5"
con |> duckhttp_read(query)
#> # A tibble: 5 × 16
#>   l_orderkey l_partkey l_suppkey l_linenumber l_quantity l_extendedprice
#>        <int>     <int>     <int>        <int> <chr>      <chr>          
#> 1          1     15519       785            1 17.00      24386.67       
#> 2          1      6731       732            2 36.00      58958.28       
#> 3          1      6370       371            3 8.00       10210.96       
#> 4          1       214       465            4 28.00      31197.88       
#> 5          1      2403       160            5 24.00      31329.60       
#> # ℹ 10 more variables: l_discount <chr>, l_tax <chr>, l_returnflag <chr>,
#> #   l_linestatus <chr>, l_shipdate <date>, l_commitdate <date>,
#> #   l_receiptdate <date>, l_shipinstruct <chr>, l_shipmode <chr>,
#> #   l_comment <chr>
```

The enabled extensions in the remote duckdb instance can be utilized,
including reading from further remote S3 instances etc.

An example where the `json`-extension is utilized to look up identifiers
related a specific set of DOIs by querying the OpenAlex API using
ducksql:

``` r
# example with custom ducksql query which utilizes the duckdb json extension 
# to query the OpenAlex API to resolve DOI identifiers

doi_query <- function(doi) {

    filter <- 
        unique(doi) |> head(50) |> 
        paste0(collapse = "|") |> sprintf(fmt = "doi:%s")

    url <- 
        paste0("https://api.openalex.org/works?filter=%s",
        "&per-page=50&mailto=support@openalex.org") |> 
        sprintf(filter)

    paste0("from (from read_json_auto('", url,
    "') select unnest(results) as r) select unnest(r.ids);")  
}

# these are the DOIs we want to resolve
dois <- 
    paste0(
    "10.1109/JSTQE.2009.2038239, 10.1109/ECOC.2010.5621466, ",
    "10.1063/1.3521361, 10.1364/nfoec.2010.jwa32, ",
    "10.4028/www.scientific.net/MSF.645-648.1033"
    ) |> 
    strsplit(", ") |> unlist()

# here we issue the query to resolve the DOIs above
con |> duckhttp_read(doi_query(dois))
#> # A tibble: 5 × 3
#>   openalex                         doi                                     mag  
#>   <chr>                            <chr>                                   <chr>
#> 1 https://openalex.org/W2037384905 https://doi.org/10.4028/www.scientific… 2037…
#> 2 https://openalex.org/W2117430724 https://doi.org/10.1109/jstqe.2009.203… 2117…
#> 3 https://openalex.org/W2039438467 https://doi.org/10.1109/ecoc.2010.5621… 2039…
#> 4 https://openalex.org/W2033152153 https://doi.org/10.1063/1.3521361       2033…
#> 5 https://openalex.org/W2035055497 https://doi.org/10.1364/nfoec.2010.jwa… 2035…
```

# Running a duckdb instance with the httpserver extension

To get a duckdb server instance running locally serving data at the
connectionstring used above, see instructions below.

## Running a duckdb httpserver extension locally

Please see information about the httpserver extension available here:

<https://duckdb.org/community_extensions/extensions/httpserver.html>

In short start the server process at the command prompt like this:

``` bash
DUCKDB_HTTPSERVER_FOREGROUND=1 DUCKDB_HTTPSERVER_DEBUG=1 duckdb -c "install httpserver from community; load httpserver; select httpserve_start('0.0.0.0', 8888, '');"
```

Then you can use the connectionstring “<http://localhost:8888>” for
example

``` r
library(duckhttp)

con <- duckhttp_con("http://localhost:8888")

query <- 
    " from 'https://shell.duckdb.org/data/tpch/0_01/parquet/orders.parquet' limit 5"

con |> duckhttp_read(query)
#> # A tibble: 5 × 9
#>   o_orderkey o_custkey o_orderstatus o_totalprice o_orderdate o_orderpriority
#>        <int>     <int> <chr>                <dbl> <date>      <chr>          
#> 1          1       370 O                  172799. 1996-01-02  5-LOW          
#> 2          2       781 O                   38426. 1996-12-01  1-URGENT       
#> 3          3      1234 F                  205654. 1993-10-14  5-LOW          
#> 4          4      1369 O                   56001. 1995-10-11  5-LOW          
#> 5          5       445 F                  105368. 1994-07-30  5-LOW          
#> # ℹ 3 more variables: o_clerk <chr>, o_shippriority <int>, o_comment <chr>
```

## Running a containerized “duckserve” instance

A duckdb server instance can also be run containerized with the
httpserver extension to provide a JSON API for duckdb queries. An
example setup configuration is described below.

  - `Containerfile` defining the “duckserve” container
  - `compose.yaml` with a service composition including reverse proxy
  - `serve.sql` a startup script for the “duckserve” service

The following Containerfile can be used to create a container image that
runs duckdb CLI with the httpserver extension installed.

``` dockerfile
FROM debian:bookworm-slim

RUN apt update && apt install -y --no-install-recommends \
    wget \
    ca-certificates \
    unzip \
    procps

ENV DUCKDB_VER=v1.1.3

WORKDIR /usr/local/bin

RUN wget -O cli.zip "https://github.com/duckdb/duckdb/releases/download/$DUCKDB_VER/duckdb_cli-linux-amd6
4.zip" && \
    unzip cli.zip && rm cli.zip && chmod +x duckdb

WORKDIR /data

# get some standard example data into the database
RUN duckdb myduck.db 'CALL dbgen(sf=0.1); select 42;'

# get ability to read over http and s3
RUN duckdb myduck.db 'install httpfs; load httpfs;'

# get ability to serve api requests
RUN duckdb myduck.db 'install httpserver from community; load httpserver;'

# get ability to use read_parquet_mergetree
RUN duckdb myduck.db 'install chsql from community; load chsql;'

# get ability to work with json
RUN duckdb myduck.db 'install json; load json;'


VOLUME ["/data"]
EXPOSE 9999

CMD ["sh", "-c", "duckdb"]
```

The following `compose.yaml` file shows how such a container can be
running as a service and how it can be reverse proxied:

``` yaml

services:
  duckserve:
    image: duckserve
    command: duckdb -init serve.sql myduck.db
    environment:
      - DUCKDB_HTTPSERVER_DEBUG=1
      - DUCKDB_HTTPSERVER_FOREGROUND=1
    volumes:
      - ./serve.sql:/data/serve.sql:ro

  nginx:
    image: nginx:alpine
    volumes:
      - ./proxy.conf:/etc/nginx/conf.d/default.conf
    ports:
      - "80:80"

```

The “duckserve” service starts with an “init script”, setting for
example credentials providing access to relevant remote sources. Here is
how such a “serve.sql” startup script can look like:

``` sql

load httpfs;
load httpserver;
load json;

-- provide credentials
.mode trash
create secret (
    type S3,
    endpoint 'some.public.minio.s3.server.org',
    use_ssl 'true',
    url_style 'path',
    key_id 'some_secret_key',
    secret 'some_secret_passphrase'
);

.mode json

attach database 's3://mybucket/myduck.db' as mydb;

-- begin some sql statements here

-- end some sql statements here

SET disabled_filesystems = 'LocalFileSystem';

select httpserve_start('0.0.0.0', 9999, '');
```

To configure the reverse proxy, use a `proxy.conf` similar to this:

    server {
    
        location /duckserve/ {
            proxy_redirect http://duckserve:9999 /duckserve/;
            proxy_pass http://duckserve:9999/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    
    }
