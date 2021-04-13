#' Create combination of all queries and all references
#'
#' @param query_names Character vector of query names
#' @param reference_names Character vector of reference names
#'
#' @return
#' A data frame with columns 'query' and 'reference' where each row is a unique pairing of a query and a reference

#' @export
create_allcomb_df <- function(query_names, reference_names) {

  expand.grid(
    query     = query_names,
    reference = reference_names,
    stringsAsFactors = FALSE
  )

}

#' Create results data frame
#'
#' @param search_mf Search manifest with pairs of query and references searched
#' @param search_results Matrix of scores, start and end indices returned by DTW search
#'
#' @return
#' A data frame with columns 'query', 'reference', and 'score'

#' @export
create_qbestd_df <- function(search_mf, search_results) {

  return_df <- cbind(
    search_mf,
    search_results,
    stringsAsFactors = FALSE
  )

  return_df <- return_df[order(return_df$query, -return_df$score), ]
  rownames(return_df) <- 1:nrow(return_df)

  return_df

}
