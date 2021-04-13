gos_kdl_queries <- system.file("extdata", "gos-kdl_queries.npz", package="sousrir")
gos_kdl_refs    <- system.file("extdata", "gos-kdl_references.npz", package="sousrir")

test_that("Fetching key names from NPZ archive works", {

  gos_kdl_names <- fetch_npz_names(gos_kdl_queries)

  expect_vector(gos_kdl_names, ptype = character(), size = 83)

  expect_equal(gos_kdl_names[c(1, 40, 83)], c("ED_warren", "OV_kiender", "ED_moane"))

})
