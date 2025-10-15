
<!-- README.md is generated from README.Rmd. Please edit that file -->

# duckhttp

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/KTH-Library/duckhttp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/KTH-Library/duckhttp/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of duckhttp is to provide functions to query and read responses
from a duckdb server running the httpserver extension and/or from a
server exposing data using Arrow Flight SQL.

## Getting a connection

The section below shows how to ake a connection against the remote
source, list tables and issue queries.

``` r
#install.packages("adbi")
#install.packages("adbcflightsql", repos = "https://community.r-multiverse.org")

library(duckhttp)

readRenviron("~/.Renviron")

# load a connectionstring of the format "https://user:pass@hostname:port/path/"
# perhaps from an environment variable in .Renviron
# then make a connection against that server

con <- duckhttp_con(Sys.getenv("CS_DEMETRIUS_HTTP"))

# to check that the service is up, use:
con |> duckhttp_ping()
#> [1] TRUE

# list the tables available
#con |> duckhttp_ls()

# to issue custom SQL use (and read results converted from JSONCompact output)
con |> duckhttp_read("from topics limit 5")
#> # A tibble: 5 × 19
#>   topic_id subfield_id field_id domain_id topic_path  topic description keywords
#>      <int>       <int>    <int>     <int> <chr>       <chr> <chr>       <chr>   
#> 1    10418        2745       27         4 4/27/2745/… Pelv… This clust… Pelvic …
#> 2    13142        1110       11         1 1/11/1110/… Gamm… This clust… Gamma-A…
#> 3    11531        2003       20         2 2/20/2003/… Fina… This clust… Health …
#> 4    12001        1105       11         1 1/11/1105/… Evol… This clust… Insect …
#> 5    13590        1202       12         2 2/12/1202/… Oral… This clust… Oral Hi…
#> # ℹ 11 more variables: subfield <chr>, field <chr>, domain <chr>,
#> #   wiki_url <chr>, wiki_keywords <chr>, updated <dttm>, works_count <int>,
#> #   cited_by_count <int>, works_api_url <chr>, updated_date <date>,
#> #   created_date <date>

# the same but reading CSV from the server
con |> duckhttp_read_csv("from publishers limit 5")
#> # A tibble: 5 × 20
#>   publisher_id display_name   alternate_titles country_codes parent_publisher_id
#>          <dbl> <chr>          <lgl>            <chr>         <lgl>              
#> 1   4366305896 INFAD Associa… NA               <NA>          NA                 
#> 2   4310322437 Centro de Est… NA               ES            NA                 
#> 3   4310312088 Diretório Aca… NA               BR            NA                 
#> 4   4310313036 Gabriel Dumon… NA               CA            NA                 
#> 5   4310317335 Muzeum Małego… NA               PL            NA                 
#> # ℹ 15 more variables: parent_publisher_display_name <lgl>, lineage <dbl>,
#> #   hierarchy_level <dbl>, wikidata_id <dbl>, ror <lgl>, homepage_url <chr>,
#> #   image_url <chr>, image_thumbnail_url <chr>, works_count <dbl>,
#> #   cited_by_count <dbl>, sources_count <dbl>, sources_api_url <chr>,
#> #   updated_date <date>, created_date <date>, updated <dttm>


# now load a connectionstring of the format "grpc://user:pass@hostname:port/"
# perhaps from an environment variable in .Renviron
# then make a connection against that server

#file.edit("~/.Renviron")
#readRenviron("~/.Renviron")
con <- adbc_connect(Sys.getenv("CS_DEMETRIUS_FLIGHTSQL"))

# list tables available in the database
#con |> adbc_tables()

# retrieve full table

con |> adbc_table("publishers")
#> # A tibble: 10,741 × 20
#>    publisher_id display_name  alternate_titles country_codes parent_publisher_id
#>         <int64> <chr>         <chr>            <chr>                     <int64>
#>  1   4366305896 INFAD Associ… <NA>             <NA>                           NA
#>  2   4310322437 Centro de Es… <NA>             ES                             NA
#>  3   4310312088 Diretório Ac… <NA>             BR                             NA
#>  4   4310313036 Gabriel Dumo… <NA>             CA                             NA
#>  5   4310317335 Muzeum Małeg… <NA>             PL                             NA
#>  6   4310317597 Diritto Civi… <NA>             IT                             NA
#>  7   4310311065 Laboratoire … <NA>             FR                             NA
#>  8   4310311121 Société Jule… <NA>             FR                             NA
#>  9   4310311127 Association … <NA>             FR                             NA
#> 10   4310312236 Centro Latin… <NA>             BR                             NA
#> # ℹ 10,731 more rows
#> # ℹ 15 more variables: parent_publisher_display_name <chr>, lineage <chr>,
#> #   hierarchy_level <int>, wikidata_id <chr>, ror <chr>, homepage_url <chr>,
#> #   image_url <chr>, image_thumbnail_url <chr>, works_count <int>,
#> #   cited_by_count <int>, sources_count <int>, sources_api_url <chr>,
#> #   updated_date <date>, created_date <date>, updated <dttm>

# issue a custom query

"from publishers limit 10" |> 
    adbc_query(adbc_con = con)
#> # A tibble: 10 × 20
#>    publisher_id display_name  alternate_titles country_codes parent_publisher_id
#>         <int64> <chr>         <chr>            <chr>                     <int64>
#>  1   4366305896 INFAD Associ… <NA>             <NA>                           NA
#>  2   4310322437 Centro de Es… <NA>             ES                             NA
#>  3   4310312088 Diretório Ac… <NA>             BR                             NA
#>  4   4310313036 Gabriel Dumo… <NA>             CA                             NA
#>  5   4310317335 Muzeum Małeg… <NA>             PL                             NA
#>  6   4310317597 Diritto Civi… <NA>             IT                             NA
#>  7   4310311065 Laboratoire … <NA>             FR                             NA
#>  8   4310311121 Société Jule… <NA>             FR                             NA
#>  9   4310311127 Association … <NA>             FR                             NA
#> 10   4310312236 Centro Latin… <NA>             BR                             NA
#> # ℹ 15 more variables: parent_publisher_display_name <chr>, lineage <chr>,
#> #   hierarchy_level <int>, wikidata_id <chr>, ror <chr>, homepage_url <chr>,
#> #   image_url <chr>, image_thumbnail_url <chr>, works_count <int>,
#> #   cited_by_count <int>, sources_count <int>, sources_api_url <chr>,
#> #   updated_date <date>, created_date <date>, updated <dttm>


con |> adbc_table("topics") |> 
    dplyr::select(topic_path, works_count, cited_by_count)
#> # A tibble: 4,516 × 3
#>    topic_path      works_count cited_by_count
#>    <chr>               <int64>        <int64>
#>  1 4/27/2745/10418       97978        1074822
#>  2 1/11/1110/13142       47318         302847
#>  3 2/20/2003/11531       48907         227195
#>  4 1/11/1105/12001       21690         144078
#>  5 2/12/1202/13590       16386          23924
#>  6 1/13/1307/11650       36930         736965
#>  7 2/20/2003/14101       41743          24683
#>  8 3/26/2604/10940       26270         337964
#>  9 2/33/3312/11755       39028         167651
#> 10 2/12/1204/14506       62646          69107
#> # ℹ 4,506 more rows

con |> adbc_query("from works limit 1")
#> # A tibble: 1 × 32
#>      work_id doi   doi_registration_age…¹ display_name language language_1 type 
#>        <dbl> <chr> <chr>                  <chr>        <chr>    <chr>      <chr>
#> 1 4312954092 10.3… Crossref               <NA>         <NA>     <NA>       grant
#> # ℹ abbreviated name: ¹​doi_registration_agency
#> # ℹ 25 more variables: type_crossref <chr>, indexed_in <chr>,
#> #   cited_by_count <int>, is_retracted <lgl>, is_paratext <lgl>, fwci <dbl>,
#> #   locations_count <int>, publication_date <date>, publication_year <int>,
#> #   referenced_works_count <int>, cited_by_api_url <chr>,
#> #   countries_distinct_count <int>, institutions_distinct_count <int>,
#> #   corresponding_author_ids <chr>, corresponding_institution_ids <chr>, …

"from works_best_oa_location 
select work_id, publisher 
where is_core is true 
limit 5" |> 
adbc_query(adbc_con = con)
#> # A tibble: 5 × 2
#>      work_id publisher                                        
#>        <dbl> <chr>                                            
#> 1 2153665422 Illuminating Engineering Society of Japan        
#> 2 2153680842 American Geophysical Union                       
#> 3 3047879070 Institute of Electrical and Electronics Engineers
#> 4 2512181176 The Iron and Steel Institute of Japan            
#> 5 3047871181 American Physical Society

# disconnect when done
adbc_disconnect(con)
```

# Backend notes

The enabled extensions in the remote duckdb instance can be utilized,
including reading from further remote S3 instances etc.

## Running a duckdb server instance with the httpserver extension

To get a duckdb server instance running locally serving data at the
connectionstring used above, see instructions below. Please first see
information about the httpserver extension available here:

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

ENV DUCKDB_VER=v1.3.2

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
