#' Calculate standardized Euclidean distances as done in SciPy cdist
#'
#' @param query_feats Feature matrix for query, of shape M rows and F columns
#' @param ref_feats Feature matrix for reference, of shape N rows and F columns
#'
#' @return
#' A distance matrix with M rows and N columns

#' @export
dist_scipy_stdeuc <- function(query_feats, ref_feats) {

  # Vectorized version of Euclidean distance, inspired by
  # https://github.com/cran/pracma/blob/master/R/distmat.R
  #
  # (x - y)^2 = x^2 + y^2 - 2xy

  # SciPy standardized Euclidean distance from cdist:
  # https://docs.scipy.org/doc/scipy/reference/generated/scipy.spatial.distance.cdist.html
  #
  # (x - y)^2/V = x^2/V + y^2/V - 2xy/V

  q_length  <- nrow(query_feats)
  r_length  <- nrow(ref_feats)

  # Get column variances the same way as SciPy
  # The variance vector for standardized Euclidean.
  # Default: np.var(np.vstack([XA, XB]), axis=0, ddof=1)
  #
  # Multiply by ((r_length - 1) / r_length) to get population variance
  # since R's default is sample variance
  stacked_l <- q_length + r_length
  V <- matrixStats::colVars(rbind(query_feats, ref_feats)) * ((r_length - 1) / r_length)

  # x^2/V, vector of q_length
  std_q2  <- apply(sweep(query_feats^2, MARGIN = 2, STATS = V, FUN = "/"), MARGIN = 1, sum)

  # y^2/V, vector of r_length
  std_r2  <- apply(sweep(ref_feats^2, MARGIN = 2, STATS = V, FUN = "/"), MARGIN = 1, sum)

  # 2xy/V, matrix of q_length x r_length
  std_qr <- sweep(query_feats, MARGIN = 2, STATS = V, FUN = "/") %*% t(ref_feats)

  # Cast x^2/V and y^2/V into matrices of q_length x r_length
  q2_mat <- matrix(rep(std_q2, r_length), q_length, r_length, byrow=FALSE)
  r2_mat <- matrix(rep(std_r2, q_length), q_length, r_length, byrow=TRUE)

  # Return Euclidean distance: sqrt(x^2/V + y^2/V - 2xy/V)
  sqrt(pmax(q2_mat + r2_mat - 2*std_qr, 0))

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
