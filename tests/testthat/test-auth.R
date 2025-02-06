test_that("using token auth works", {

  skip_on_ci()

  con <- duckhttp_con("http://localhost/duckserve/", api_key = "some token")

  five <- 
    con |> duckhttp_read("from lineitem limit 5")

  is_valid <- nrow(five) == 5

  expect_true(is_valid)

})
