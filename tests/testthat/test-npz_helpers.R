gos_kdl_queries <- system.file("extdata", "gos-kdl_queries.npz", package="sousrir")
gos_kdl_refs    <- system.file("extdata", "gos-kdl_references.npz", package="sousrir")

test_that("Fetching key names from NPZ archive works", {

  gos_kdl_names <- fetch_npz_names(gos_kdl_queries)

  # Check expected size
  expect_vector(gos_kdl_names, ptype = character(), size = 83)

  # Spot check some values
  expect_equal(gos_kdl_names[c(1, 40, 83)], c("ED_warren", "OV_kiender", "ED_moane"))

})

test_that("Fetching feature matrix from NPZ archive works", {

  ED_warren <- fetch_npz_item(gos_kdl_queries, "ED_warren")

  # Check expected size
  expect_equal(dim(ED_warren), c(21, 20))

  # Spot check some values
  expect_equal(
    round(ED_warren[c(1,100,150,204,300,400)], 2),
    c(-677.03, 17.49, -30.08, 2.64, -6.54, -3.18)
  )

})
