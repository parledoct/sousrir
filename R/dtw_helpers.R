#' Return index of 1-nearest neighbour search using rundtw function from IncDTW package
#'
#' @param query_feats Feature matrix for query
#' @param ref_feats Feature matrix for reference
#'
#' @return
#' An integer indicating the start of the best match for the query within the reference

#' @export
sousrir_1nndtw <- function(query_feats, ref_feats) {

  IncDTW::rundtw(
    Q = query_feats,
    C = ref_feats,
    dist_method = 'norm2',
    step_pattern = 'symmetric2',
    scale = '01',
    ws = 5,
    lower_bound = TRUE,
    k = 1
  )$knn_indices[1]

}

#' Return score of how likely a query occurs in a reference, given a starting index
#'
#' @param query_name Name of query (for error reporting in case function fails)
#' @param ref_name Name of reference (for error reporting in case function fails)
#' @param query_feats Query feature matrix (of shape M rows and F columns)
#' @param ref_feats Reference feature matrix (of shape N rows and F columns)
#' @param top_match_start Top match location returned by \link{sousrir_1nndtw}
#' @param min_match_ratio Minimum match length as ratio of query (default: 0.5 = half the query size)
#' @param max_match_ratio Maximum match length as ratio of query (default: 2.0 = twice the query size)
#' @param distance_func Function to compute distances between query and reference (default: \link{dist_stdeuc})
#' @param distnorm_func Function to normalize computed distances (default: \link{norm_rf2014})
#' @param return_dtwalign Whether or not to return alignment object (i.e. for plotting alignment)
#'
#' @return
#' A numeric score of how likely the query occurs in the reference (or NA if no acceptable alignment was found given the parameters)

#' @export
sousrir_ssdtw <- function(
  query_name,
  ref_name,
  query_feats,
  ref_feats,
  top_match_start,
  min_match_ratio = 0.5,
  max_match_ratio = 2.0,
  distance_func   = dist_stdeuc,
  distnorm_func   = norm_rf2014,
  return_dtwalign = FALSE) {

  # Calculate distance matrix
  qr_dists <- tryCatch(
    expr  = distance_func(query_feats, ref_feats),
    error = function(cond) {
      message(glue::glue("Error: Failed to calculate distances between query '{query_name}' and reference '{ref_name}"))
      stop(cond)
    }
  )

  # Normalize distance matrix
  qr_dists <- tryCatch(
    expr  = distnorm_func(qr_dists),
    error = function(cond) {
      message(glue::glue("Error: Failed to normalize distances between query '{query_name}' and reference '{ref_name}"))
      stop(cond)
    }
  )

  q_length <- nrow(query_feats)
  r_length <- nrow(ref_feats)

  # Create window from start of match returned by IncDTW::rundtw()
  # until maximum allowable match size (e.g. twice length of query)
  # or end of the reference, whichever is smaller
  top_match_window <- list(
    start = top_match_start,
    end   = as.integer(min(r_length, top_match_start + (max_match_ratio * q_length)))
  )

  # Subset the distance matrix as appropriate
  # Doing checks just in case user-provided distance
  # functions don't match dtw function expectations
  if (ncol(qr_dists) == r_length) {

    subseq_dists <- qr_dists[, top_match_window$start:top_match_window$end]

  } else if(nrow(qr_dists) == r_length) {

    subseq_dists <- t(qr_dists)[, top_match_window$start:top_match_window$end]

  } else {

    stop("Error: neither dimension of distance matrix matches reference length.")

  }

  # Try to find an alignment, return NULL if none can be found
  dtw_align <- tryCatch(
    expr = {
      dtw::dtw(
        x = subseq_dists,
        step.pattern = dtw::symmetricP1,
        distance.only = !return_dtwalign,
        open.end = TRUE
      )},
    error = function(cond) {
      NULL
    }
  )

  if(return_dtwalign) {
    return(dtw_align)
  }

  match_ratio <- dtw_align$jmin / q_length

  if(is.null(dtw_align) | match_ratio < min_match_ratio) {

    # Return NA if no alignment can be found
    # or if alignment is less than the minimum match length
    list(
      score       = NA,
      match_start = NA,
      match_end   = NA
    )

  } else {

    list(
      score       = 1 - dtw_align$normalizedDistance,
      match_start = top_match_start,
      match_end   = top_match_start + dtw_align$jmin
    )

  }

}
