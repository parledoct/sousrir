#' Calculate standardized Euclidean distances between query and reference feature matrices
#'
#' @param query_feats Feature matrix for query, of shape M rows and F columns
#' @param ref_feats Feature matrix for reference, of shape N rows and F columns
#'
#' @return
#' A distance matrix with M rows and N columns

#' @export
dist_stdeuc <- function(query_feats, ref_feats) {

  proxy::dist(
    x = scale(query_feats), # Use scale() to standardize feature columns
    y = scale(ref_feats),
    method = "Euclidean",
    by_rows = TRUE          # Recall: feature components = columns, time frames = rows
  )
}

#' Normalize distance matrix according to procedure proposed by Rodriguez-Fuentes et al. (2014)
#'
#' For formal description of procedure see: \href{https://doi.org/10.1109/ICASSP.2014.6855122}{https://doi.org/10.1109/ICASSP.2014.6855122}.
#'
#' @param qr_dists A distance matrix
#'
#' @return
#' A normalized distance matrix

#' @export
norm_rf2014 <- function(qr_dists) {

  min_i  <- apply(qr_dists, MARGIN = 1, FUN = min)
  max_i  <- apply(qr_dists, MARGIN = 1, FUN = max)
  drange <- max_i - min_i

  qr_dists  <- sweep(qr_dists, MARGIN = 1, STATS = min_i, FUN = "-")
  qr_dists  <- sweep(qr_dists, MARGIN = 1, STATS = drange, FUN = "/")

  qr_dists
}
