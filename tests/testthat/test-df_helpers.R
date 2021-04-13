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

  dtw_scores <- c(1.0, 0.5, 0.5, 1.0)

  results_df_created <- create_qbestd_df(search_mf_expected, dtw_scores)

  results_df_expected <- data.frame(
    query     = c("car", "car", "hello", "hello"), # Sorted alphabetically
    reference = c("there's a car", "goodbye-hello-goodbye", "goodbye-hello-goodbye", "there's a car"),
    score     = c(1.0, 0.5, 1.0, 0.5)              # Sorted in descending order by query
  )

  expect_equal(
    results_df_created$query,
    results_df_expected$query
  )

  expect_equal(
    results_df_created$reference,
    results_df_expected$reference
  )

  expect_equal(
    results_df_created$score,
    results_df_expected$score
  )

})
