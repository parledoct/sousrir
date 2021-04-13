search_mf_expected <- data.frame(
  query     = c("hello", "car", "hello", "car"),
  reference = c("goodbye-hello-goodbye", "goodbye-hello-goodbye", "there's a car", "there's a car")
)

test_that("Building search manifest with all pairwise combinations works", {

  search_mf_created <- create_allcomb_df(
    c("hello", "car"),
    c("goodbye-hello-goodbye", "there's a car")
  )

  expect_equal(
    search_mf_created$query,
    search_mf_expected$query
  )

  expect_equal(
    search_mf_created$reference,
    search_mf_expected$reference
  )

  expect_false(is.factor(search_mf_created$query))
  expect_false(is.factor(search_mf_created$reference))

})

test_that("Building results data frame works", {

  skip("Skip test while output format is still being developed")

})
