library(tidyverse)

plot_qbe_std <- function(query_feats, ref_feats, dist) {

  qr_dists <- dist_stdeuc(query_feats, ref_feats)
  qr_dists <- norm_rf2014(qr_dists)

  dists_df <- t(qr_dists) %>%
    as.data.frame.matrix() %>%
    dplyr::mutate(ref_frame = 1:n()) %>%
    tidyr::gather(query_frame, norm_dist, -ref_frame) %>%
    dplyr::mutate(query_frame = stringr::str_extract(query_frame, "\\d+") %>% as.integer()) %>%
    arrange(ref_frame, query_frame)

  top_match_index <- sousrir_1nndtw(query_feats, ref_feats)
  top_match_align <- sousrir_ssdtw("Query", "Reference", query_feats, ref_feats, top_match_index, return_dtwalign = TRUE)

  top_match_end   <- top_match_index + top_match_align$jmin

  path_df <- tibble(
    query_frame = top_match_align$index1,
    ref_frame = top_match_index + top_match_align$index2 - 1,
    norm_dist = min(dists_df$norm_dist)
  )

  dists_df %>%
    ggplot(aes(x = ref_frame, y = query_frame, fill = norm_dist)) +
    geom_tile() +
    geom_tile(data = path_df, fill = "red") +
    scale_fill_gradient2(low = "black", mid = "grey", high = "white", midpoint = 0.5) +
    scale_x_continuous(position = "bottom", n.breaks = 10) +
    scale_y_continuous(n.breaks = 5) +
    xlab("Reference (frame number)") +
    ylab("Query (frame number)")+
    guides(fill=guide_legend(title="Distance")) +
    theme_bw() +
    coord_fixed() +
    annotate(geom = "label", alpha = 0.75,
             x = top_match_index, y = 0.75 * nrow(query_feats),
             label = paste(
               "Match start: ", top_match_index, "\n",
               "Match end: ", top_match_end, "\n",
               "Distance: ", round(top_match_align$normalizedDistance, 2),
               sep = ""
             )
    )

}
