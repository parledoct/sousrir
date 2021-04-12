#' Fetch filenames from named NumPy array archive
#'
#' @param npz_file Path to .npz file
#'
#' @return
#' A character vector of names within the NumPy array archive

#' @export
fetch_npz_names <- function(npz_file) {
  np <- reticulate::import("numpy")

  np$load(npz_file)$files
}

#' Fetch array by item name from NumPy array archive
#'
#' @param npz_file Path to .npz file
#' @param item_name Name within archive dictionary
#'
#' @return
#' A feature matrix with T rows and F columns, where
#' T is the number of time steps and F the number of
#' feature components

#' @export
fetch_npz_item <- function(npz_file, item_name) {
  np <- reticulate::import("numpy")

  np$load(npz_file)$f[[item_name]]
}
