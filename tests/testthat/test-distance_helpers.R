# Simulate a feature vector whose components (columns)
# are on different scales
query <- matrix(c(
# k a t
   1, -10, -100,  # time step 1
  -1,  10, -100,  # time step 2
  -1, -10,  100),  # time step 3
  ncol = 3,
  nrow = 3,
  byrow = TRUE
)

test_that("Calculating standardised Euclidean distances works", {

  # There should only be 2 unique values when calculating a
  # standardised Euclidean distance between the query and itself
  expect_equal(
    unique(dist_stdeuc(query, query)),
    c(0.00000000, 2.44948974)
  )

})

test_that("Normalising matrix according using Rodriguez-Fuentes et al. (2014) procedure works", {

  # The procedure range-normalises the matrix by columns (i.e. feature components)
  # yielding 1 where the max value occurs in that column (i.e. 100 for third column)
  # and 0 where the min value occurs (i.e. -100 for the third column)
  expect_equal(
    norm_rf2014(query)[ , 3],
    c(0, 0, 1)
  )

})
