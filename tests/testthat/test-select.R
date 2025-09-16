test_that("issuing a query works", {

  skip_on_ci()

  con <- duckhttp_con(Sys.getenv("CS_DEMETRIUS_HTTP"))

  topics <- 
    con |> duckhttp_read("from topics")

  is_valid <- 
      duckhttp_ping(con) == TRUE &&
      nrow(topics) >= 3e3

  expect_true(is_valid)

})

test_that("issuing a query to enumerate tables at a remote server works", {

  skip_on_ci()

  con <- duckhttp_con(Sys.getenv("CS_DEMETRIUS_HTTP"))

  stopifnot(
    duckhttp_ping(con)
  )

  catalog <- 
    con |> duckhttp_ls()

  is_valid <- length(catalog) > 0

  expect_true(is_valid)

})
