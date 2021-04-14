#' Detect queries in test items
#'
#' @param queries_loc Location of queries (default: an npz file containing a named dictionary of NumPy feature matrices of shape TxF)
#' @param references_loc Location of references (default: an npz file containing a named dictionary of NumPy feature matrices of shape TxF)
#' @param names_fetcher A function that takes queries_loc/references_loc and returns the items contained in them (default: \link{fetch_npz_names})
#' @param features_fetcher A function that takes queries_loc/references_loc and an item name, and returns the features associated with that item (default: \link{fetch_npz_item})
#' @param search_mf_maker A function that takes the list of query and reference names and returns a two-column data frame with pairs of queries and references (default: \link{create_allcomb_df})
#' @param post_processor A function to process the search results (default: \link{create_qbestd_df})
#' @param nndtw_func A function to shortlist starting indices (default: \link{sousrir_1nndtw})
#' @param ssdtw_func A function to calculate a score of how likely a query occurs in a reference, given starting indices (default: \link{sousrir_ssdtw})
#' @param progress_bar Show progress bar while running search
#' @param use_multisession Use future::multisession to run search using multiple R sessions in parallel

#' @export
qbe_std <- function(
  queries_loc,
  references_loc,
  names_fetcher    = fetch_npz_names,
  features_fetcher = fetch_npz_item,
  search_mf_maker  = create_allcomb_df,
  post_processor   = create_qbestd_df,
  nndtw_func       = sousrir_1nndtw,
  ssdtw_func       = sousrir_ssdtw,
  progress_bar = TRUE,
  use_multisession = TRUE) {

  query_names     <- names_fetcher(queries_loc)
  reference_names <- names_fetcher(references_loc)

  search_mf       <- search_mf_maker(query_names, reference_names)

  if(use_multisession) {
    future::plan(future::multisession)
  }

  search_results  <- furrr::future_map2_dfr(
    .x = search_mf$query,
    .y = search_mf$reference,
    function(query_name, ref_name) {

      query_feats <- tryCatch(
        expr  = features_fetcher(queries_loc, query_name),
        error = function(cond) {
          stop(
            glue::glue("Error: could not fetch features for query '{query_name}'.")
          )
        }
      )

      ref_feats <- tryCatch(
        expr  = features_fetcher(references_loc, ref_name),
        error = function(cond) {
          stop(
            glue::glue("Error: could not fetch features for reference '{ref_name}'.")
          )
        }
      )

      if(ncol(query_feats) != ncol(ref_feats)) {
        stop(
          glue::glue("Error: Different number of feature columns between query '{query_name}' and reference '{ref_name}'.")
        )
      }

      top_match_starts <- tryCatch(
        expr  = nndtw_func(query_feats, ref_feats),
        error = function(cond) {
          message(glue::glue("Error: Failed to run nearest neighbour DTW function (nndtw_func) for query '{query_name}' and reference '{ref_name}"))
          stop(cond)
        }
      )

      if(all(is.na(top_match_starts))) {

        # If no good matches, then let ssdtw_func know to return a null result
        ssdtw_func(query_name, ref_name, query_feats, ref_feats, -1)

      } else {

        # If any good matches, keep only non-NA indices
        top_match_starts <- top_match_starts[which(!is.na(top_match_starts))]

        # Use preferred subsequence dtw method on shortlisted indices returned by IncDTW
        ssdtw_func(query_name, ref_name, query_feats, ref_feats, top_match_starts)
      }
    },
    .progress = progress_bar,
    .options = furrr::furrr_options(seed = TRUE)
  )

  post_processor(search_mf, search_results)

}
