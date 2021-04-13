#' Convert Librosa MFCC sample number into seconds
#'
#' @param sample_number An integer vector of sample numbers to convert
#' @param sample_rate Sample rate of original audio
#' @param hop_length Hop length used when extracting MFCC features (default: 512)
#'
#' @return
#' A numeric vector of time in seconds corresponding to the sample numbers

#' @export
samp2sec_libmfcc <- function(sample_number, sample_rate, hop_length = 512) {

  (sample_number * hop_length)/sample_rate

}
