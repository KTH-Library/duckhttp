test_that("adbc connection works", {

  # NOTE: this tests expects a server to be started (see repos/duckdflight/compose.yaml, the gizmosql service)

  skip_on_ci()

  con <- adbc_connect(Sys.getenv("CS_DEMETRIUS_FLIGHTSQL"))

  dat <- 
    con |> adbc_query("from topics limit 5")

    
  is_valid <- nrow(dat) == 5
  on.exit(adbc_disconnect(con))
  expect_true(is_valid)

})

test_that("adbc arrow query works", {

  skip_on_ci()

  con <- adbc_connect(Sys.getenv("CS_DEMETRIUS_FLIGHTSQL"))
  res <- con |> adbc_query("select 42, 43")

  is_valid <- tibble::as_tibble(res) |> ncol() == 2

  on.exit(adbc_disconnect(con))

  expect_true(is_valid)

})

test_that("adbc arrow query can return bigint", {

  skip_on_ci()

  con <- adbc_connect(Sys.getenv("CS_DEMETRIUS_FLIGHTSQL"))
  res <- con |> adbc_query("select 42::bigint, 43::ubigint")

  is_valid <- tibble::as_tibble(res) |> ncol() == 2

  on.exit(adbc_disconnect(con))

  expect_true(is_valid)

})

test_that("adbc arrow query returns ubigint as double", {

  skip_on_ci()

  con <- adbc_connect(Sys.getenv("CS_DEMETRIUS_FLIGHTSQL"))
  res <- con |> adbc_query("select 43::ubigint")

  is_valid <- is.double(res$`CAST(43 AS UBIGINT)`)

  on.exit(adbc_disconnect(con))

  expect_true(is_valid)

})
