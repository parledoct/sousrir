#' Calculate standardized Euclidean distances as done in NumPy cdist
#'
#' @param query_feats Feature matrix for query, of shape M rows and F columns
#' @param ref_feats Feature matrix for reference, of shape N rows and F columns
#'
#' @return
#' A distance matrix with M rows and N columns

#' @export
dist_npstdeuc <- function(query_feats, ref_feats) {

  q_length  <- nrow(query_feats)
  r_length  <- nrow(ref_feats)

  stacked_l <- q_length + r_length
  V <- matrixStats::colVars(rbind(query_feats, ref_feats)) * ((r_length - 1) / r_length)

  dists <- matrix(nrow = q_length, ncol = r_length)

  for (i in 1:nrow(query_feats)) {
    for (j in 1:nrow(ref_feats)) {
      dists[i, j] <- sqrt(sum((query_feats[i, ] - ref_feats[j, ])^2 / V))
    }
  }

  dists

}

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
    x = fast_scale(query_feats), # Use fast_scale() to standardize feature columns
    y = fast_scale(ref_feats),
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

  min_i  <- apply(qr_dists, MARGIN = 2, FUN = min)
  max_i  <- apply(qr_dists, MARGIN = 2, FUN = max)
  drange <- max_i - min_i

  qr_dists  <- sweep(qr_dists, MARGIN = 2, STATS = min_i, FUN = "-")
  qr_dists  <- sweep(qr_dists, MARGIN = 2, STATS = drange, FUN = "/")

  qr_dists
}

#' A fast scale function for calcuating the standardised Euclidean
#'
#' Adapted from \href{https://www.r-bloggers.com/2016/02/a-faster-scale-function/}{https://www.r-bloggers.com/2016/02/a-faster-scale-function/}
fast_scale <- function(feature_matrix) {

  cm  <- colMeans(feature_matrix)
  csd <- matrixStats::colSds(feature_matrix, center = cm)

  t( (t(feature_matrix) - cm) / csd )

}
