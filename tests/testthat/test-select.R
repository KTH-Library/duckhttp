test_that("issuing a query works", {
  skip_on_ci()

  # this requests 600 000 rows, so limit to 5  
  con <- duckhttp_con("http://localhost/duckserve/")

  lineitems <- 
    con |> duckhttp_read("from lineitem limit 5")

  is_valid <- nrow(lineitems) == 5

  expect_true(is_valid)

})

test_that("issuing a query to a remote server works", {
  skip_on_ci()

  cs <- "https://%s:%s@bibliometrics.lib.kth.se/duckserve/" |> 
    sprintf(Sys.getenv("DUCKSERVE_USER"), Sys.getenv("DUCKSERVE_PASS"))

  con <- duckhttp_con(cs)

  stopifnot(duckhttp_ping(con))

  top20 <- 
    con |> duckhttp_read("from top20 limit 5")

  is_valid <- nrow(top20) == 5

  expect_true(is_valid)

})

