
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
con |> duckhttp_ls()
#>  [1] "authors_raw"                         
#>  [2] "concepts"                            
#>  [3] "concepts_ancestors"                  
#>  [4] "concepts_ids"                        
#>  [5] "concepts_relations"                  
#>  [6] "funders"                             
#>  [7] "funders_concepts"                    
#>  [8] "funders_counts"                      
#>  [9] "funders_roles"                       
#> [10] "funders_stats"                       
#> [11] "institutions"                        
#> [12] "institutions_counts"                 
#> [13] "institutions_geo"                    
#> [14] "institutions_ids"                    
#> [15] "institutions_relations"              
#> [16] "publishers"                          
#> [17] "sources"                             
#> [18] "sources_counts"                      
#> [19] "sources_ids"                         
#> [20] "topics"                              
#> [21] "authors"                             
#> [22] "authors_affiliations"                
#> [23] "authors_concepts"                    
#> [24] "authors_counts"                      
#> [25] "authors_institutions"                
#> [26] "authors_stats"                       
#> [27] "authors_topics"                      
#> [28] "authors_topic_shares"                
#> [29] "works"                               
#> [30] "works_apc_list"                      
#> [31] "works_apc_paid"                      
#> [32] "works_authorships"                   
#> [33] "works_biblio"                        
#> [34] "works_citation_normalized_percentile"
#> [35] "works_cited_by_percentile_year"      
#> [36] "works_counts_by_year"                
#> [37] "works_grants"                        
#> [38] "works_ids"                           
#> [39] "works_institution_assertions"        
#> [40] "works_keywords"                      
#> [41] "works_locations"                     
#> [42] "works_mesh"                          
#> [43] "works_primary_location"              
#> [44] "works_primary_topic"                 
#> [45] "works_referenced_works"              
#> [46] "works_related_works"                 
#> [47] "works_sdgs"                          
#> [48] "works_summary_stats"                 
#> [49] "works_topics"

# to issue custom SQL use (and read results converted from JSONCompact output)
con |> duckhttp_read("from topics limit 5")
#> # A tibble: 5 × 19
#>   topic_id subfield_id field_id domain_id topic_path topic field subfield domain
#>      <int>       <int>    <int>     <int> <chr>      <chr> <chr> <chr>    <chr> 
#> 1    10418        2745       27         4 4/27/2745… Pelv… Medi… Rheumat… Healt…
#> 2    13142        1110       11         1 1/11/1110… Gamm… Agri… Plant S… Life …
#> 3    11531        2003       20         2 2/20/2003… Fina… Econ… Finance  Socia…
#> 4    12001        1105       11         1 1/11/1105… Evol… Agri… Ecology… Life …
#> 5    13590        1202       12         2 2/12/1202… Oral… Arts… History  Socia…
#> # ℹ 10 more variables: wiki_url <chr>, wiki_keywords <chr>, keywords <chr>,
#> #   updated <dttm>, description <chr>, works_count <int>, cited_by_count <int>,
#> #   works_api_url <chr>, updated_date <date>, created_date <date>

# the same but reading CSV from the server
con |> duckhttp_read_csv("from topics limit 5")
#> # A tibble: 5 × 19
#>   topic_id subfield_id field_id domain_id topic_path topic field subfield domain
#>      <dbl>       <dbl>    <dbl>     <dbl> <chr>      <chr> <chr> <chr>    <chr> 
#> 1    10418        2745       27         4 4/27/2745… Pelv… Medi… Rheumat… Healt…
#> 2    13142        1110       11         1 1/11/1110… Gamm… Agri… Plant S… Life …
#> 3    11531        2003       20         2 2/20/2003… Fina… Econ… Finance  Socia…
#> 4    12001        1105       11         1 1/11/1105… Evol… Agri… Ecology… Life …
#> 5    13590        1202       12         2 2/12/1202… Oral… Arts… History  Socia…
#> # ℹ 10 more variables: wiki_url <chr>, wiki_keywords <chr>, keywords <chr>,
#> #   updated <dttm>, description <chr>, works_count <dbl>, cited_by_count <dbl>,
#> #   works_api_url <chr>, updated_date <date>, created_date <date>



# now load a connectionstring of the format "grpc://user:pass@hostname:port/"
# perhaps from an environment variable in .Renviron
# then make a connection against that server

con <- adbc_connect(Sys.getenv("CS_DEMETRIUS_FLIGHTSQL"))

# list tables available in the database
con |> adbc_tables()
#>  [1] "authors"                             
#>  [2] "authors_affiliations"                
#>  [3] "authors_concepts"                    
#>  [4] "authors_counts"                      
#>  [5] "authors_institutions"                
#>  [6] "authors_raw"                         
#>  [7] "authors_stats"                       
#>  [8] "authors_topic_shares"                
#>  [9] "authors_topics"                      
#> [10] "concepts"                            
#> [11] "concepts_ancestors"                  
#> [12] "concepts_ids"                        
#> [13] "concepts_relations"                  
#> [14] "funders"                             
#> [15] "funders_concepts"                    
#> [16] "funders_counts"                      
#> [17] "funders_roles"                       
#> [18] "funders_stats"                       
#> [19] "institutions"                        
#> [20] "institutions_counts"                 
#> [21] "institutions_geo"                    
#> [22] "institutions_ids"                    
#> [23] "institutions_relations"              
#> [24] "publishers"                          
#> [25] "sources"                             
#> [26] "sources_counts"                      
#> [27] "sources_ids"                         
#> [28] "topics"                              
#> [29] "works"                               
#> [30] "works_apc_list"                      
#> [31] "works_apc_paid"                      
#> [32] "works_authorships"                   
#> [33] "works_biblio"                        
#> [34] "works_citation_normalized_percentile"
#> [35] "works_cited_by_percentile_year"      
#> [36] "works_counts_by_year"                
#> [37] "works_grants"                        
#> [38] "works_ids"                           
#> [39] "works_institution_assertions"        
#> [40] "works_keywords"                      
#> [41] "works_locations"                     
#> [42] "works_mesh"                          
#> [43] "works_primary_location"              
#> [44] "works_primary_topic"                 
#> [45] "works_referenced_works"              
#> [46] "works_related_works"                 
#> [47] "works_sdgs"                          
#> [48] "works_summary_stats"                 
#> [49] "works_topics"

# retrieve full table
con |> adbc_table("topics")
#> # A tibble: 4,516 × 19
#>    topic_id subfield_id field_id domain_id topic_path      topic  field subfield
#>       <int>       <int>    <int>     <int> <chr>           <chr>  <chr> <chr>   
#>  1    10418        2745       27         4 4/27/2745/10418 Pelvi… Medi… Rheumat…
#>  2    13142        1110       11         1 1/11/1110/13142 Gamma… Agri… Plant S…
#>  3    11531        2003       20         2 2/20/2003/11531 Finan… Econ… Finance 
#>  4    12001        1105       11         1 1/11/1105/12001 Evolu… Agri… Ecology…
#>  5    13590        1202       12         2 2/12/1202/13590 Oral … Arts… History 
#>  6    11650        1307       13         1 1/13/1307/11650 Biolo… Bioc… Cell Bi…
#>  7    14101        2003       20         2 2/20/2003/14101 The F… Econ… Finance 
#>  8    10940        2604       26         3 3/26/2604/10940 Mathe… Math… Applied…
#>  9    11755        3312       33         2 2/33/3312/11755 Influ… Soci… Sociolo…
#> 10    14506        1204       12         2 2/12/1204/14506 Archa… Arts… Archeol…
#> # ℹ 4,506 more rows
#> # ℹ 11 more variables: domain <chr>, wiki_url <chr>, wiki_keywords <chr>,
#> #   keywords <chr>, updated <dttm>, description <chr>, works_count <int>,
#> #   cited_by_count <int>, works_api_url <chr>, updated_date <date>,
#> #   created_date <date>

# issue a custom query
con |> adbc_query("from publishers limit 5")
#> # A tibble: 5 × 11
#>   publisher_id display_name       alternate_titles country_codes hierarchy_level
#>          <dbl> <chr>              <chr>            <chr>                   <dbl>
#> 1   4366305896 INFAD Association  <NA>             <NA>                        0
#> 2   4310322437 Centro de Estudio… <NA>             ES                          0
#> 3   4310312088 Diretório Acadêmi… <NA>             BR                          0
#> 4   4310313036 Gabriel Dumont In… <NA>             CA                          0
#> 5   4310317335 Muzeum Małego Mia… <NA>             PL                          0
#> # ℹ 6 more variables: parent_publisher_id <dbl>,
#> #   parent_publisher_display_name <chr>, works_count <dbl>,
#> #   cited_by_count <dbl>, sources_api_url <chr>, updated_date <date>

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
