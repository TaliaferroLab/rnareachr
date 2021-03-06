#' Estimate Motif Occurance from Kmers
#'
#' Because scanning for PWM matches across both the case and control
#' DNAStringSets can take quite a bit of time, this function estimates matches
#' from a kmer list. We recommend using significantly enriched or depleted kmers
#' as calculated by \code{kmer_compare}.
#' @param kmer_list a character list of kmers
#' @param motif_set one of "CISBPRNA_mm","CISBPRNA_hs", "JASPAR_mm", "JASPAR_hs", "RBNS", or "custom"
#' @param custom_motif_by_kmer_matrix NULL unless motif_set = "custom". Use
#'   output logical matrix from \code{relate_Kmer_PWM}.
#' @return a summary table of motif matches in kmers including the pvalue as
#'   calculated by \code{phyper}, then corrected by \code{p.adjust} with the
#'   \code{method = "BH"}.
#' @examples
#' enriched_sixmers <- c("AAGGAA", "ACACAC", "AGAAGG", "AGAGAG", "AGAGGG",
#' "AGGAAG", "AGGAGG", "AGGGAG", "CACACA", "GAAGGA", "GAGAAG", "GAGAGA",
#' "GAGGAG", "GAGGGA", "GAGGGG", "GGAAGG", "GGAGGA", "GGAGGG", "GGGAGG")
#' estimate_motif_from_kmer(enriched_sixmers, "RBNS")
#' estimate_motif_from_kmer(enriched_sixmers, "custom", custom_PWM)
#' @export
estimate_motif_from_kmer <- function(kmer_list, motif_set, custom_motif_by_kmer_matrix = NULL){
  #infer k from kmer_list list.
  if (length(unique(nchar(as.character(kmer_list)))) != 1){
    stop("kmers in kmer list are not the same length")
  }
  else
    k = unique(nchar(as.character(kmer_list)))

  #check motif_set input
  if (motif_set != "CISBPRNA_mm" & motif_set != "CISBPRNA_hs" & motif_set != "JASPAR_mm" & motif_set != "JASPAR_hs" & motif_set != "RBNS" & motif_set != "custom"){
    stop("motif_set must be either \"CISBPRNA_mm\", \"CISBPRNA_hs\", \"JASPAR_mm\", \"JASPAR_hs\", \"RBNS\" or \"custom\"")
  }

  #get appropriate motif_by_kmer
  if (k == 4 & motif_set == "CISBPRNA_mm"){
    motif_by_kmer <- FeatureReachR:::fourmer_mm_cisbpRNA
  }
  else if (k == 4 & motif_set == "CISBPRNA_hs"){
    motif_by_kmer <- FeatureReachR:::fourmer_hs_cisbpRNA
  }
  else if (k == 4 & motif_set == "RBNS"){
    motif_by_kmer <- FeatureReachR:::fourmer_RBNS
  }
  else if (k == 4 & motif_set == "JASPAR_hs"){
    motif_by_kmer <- FeatureReachR:::fourmer_hs_JASPAR
  }
  else if (k == 4 & motif_set == "JASPAR_mm"){
    motif_by_kmer <- FeatureReachR:::fourmer_mm_JASPAR
  }
  else if (k == 5 & motif_set == "CISBPRNA_mm"){
    motif_by_kmer <- FeatureReachR:::fivemer_mm_cisbpRNA
  }
  else if (k == 5 & motif_set == "CISBPRNA_hs"){
    motif_by_kmer <- FeatureReachR:::fivemer_hs_cisbpRNA
  }
  else if (k == 5 & motif_set == "JASPAR_mm"){
    motif_by_kmer <- FeatureReachR:::fivemer_mm_JASPAR
  }
  else if (k == 5 & motif_set == "JASPAR_hs"){
    motif_by_kmer <- FeatureReachR:::fivemer_hs_JASPAR
  }
  else if (k == 5 & motif_set == "RBNS"){
    motif_by_kmer <- FeatureReachR:::fivemer_RBNS
  }
  else if (k == 6 & motif_set == "CISBPRNA_mm"){
    motif_by_kmer <- FeatureReachR:::sixmer_mm_cisbpRNA
  }
  else if (k == 6 & motif_set == "CISBPRNA_hs"){
    motif_by_kmer <- FeatureReachR:::sixmer_hs_cisbpRNA
  }
  else if (k == 6 & motif_set == "JASPAR_mm"){
    motif_by_kmer <- FeatureReachR:::sixmer_mm_JASPAR
  }
  else if (k == 6 & motif_set == "JASPAR_hs"){
    motif_by_kmer <- FeatureReachR:::sixmer_hs_JASPAR
  }
  else if (k == 6 & motif_set == "RBNS"){
    motif_by_kmer <- FeatureReachR:::sixmer_RBNS
  }
  else if (k == 7 & motif_set == "CISBPRNA_mm"){
    motif_by_kmer <- FeatureReachR:::sevenmer_mm_cisbpRNA
  }
  else if (k == 7 & motif_set == "CISBPRNA_hs"){
    motif_by_kmer <- FeatureReachR:::sevenmer_hs_cisbpRNA
  }
  else if (k == 7 & motif_set == "JASPAR_mm"){
    motif_by_kmer <- FeatureReachR:::sevenmer_mm_JASPAR
  }
  else if (k == 7 & motif_set == "JASPAR_hs"){
    motif_by_kmer <- FeatureReachR:::sevenmer_hs_JASPAR
  }
  else if (k == 7 & motif_set == "RBNS"){
    motif_by_kmer <- FeatureReachR:::sevenmer_RBNS
  }

  if (motif_set == "custom" & is.null(custom_motif_by_kmer_matrix) == TRUE){
    stop("A custom motif_by_kmer_matrix is required for estimating custom motif occurance from kmers \n
         use ouput from relate_kmer_PWM()")
  } else if (motif_set == "custom" & is.null(custom_motif_by_kmer_matrix) == FALSE){
    motif_by_kmer <- custom_motif_by_kmer_matrix
  }

  ##calculate probablility of matching...

  x <- c(1:nrow(motif_by_kmer))
  motif_estimate <- motif_by_kmer %>%
    dplyr::as_tibble() %>%
    dplyr::mutate(input_kmer = rowSums(dplyr::select(., all_of(kmer_list))),
                   all_kmer = rowSums(dplyr::select(., -motif)),
                   tile = as.character(lapply(x, function(x) strsplit(as.character(motif_by_kmer$motif[x]), "_(?=[^_]+$)", perl=TRUE)[[1]][2])),
                   motif = as.character(lapply(x, function(x) strsplit(as.character(motif_by_kmer$motif[x]), "_(?=[^_]+$)", perl=TRUE)[[1]][1])),
                   motif = ifelse(tile %in% as.character(c(1:99)), motif, paste(motif, tile, sep = "_")),
                   tile = ifelse(tile %in% as.character(c(1:99)), tile, "0")) %>%
    dplyr::group_by(motif) %>%
    dplyr::summarize(input_kmer = sum(input_kmer), all_kmer = sum(all_kmer), .groups = "rowwise") %>%
    dplyr::mutate(input_freq = input_kmer / length(kmer_list),
                  all_freq = (all_kmer - input_kmer) / (4^k - length(kmer_list)),
                  log2FC = log2((input_freq/all_freq)+1),
                  p_val = ifelse(all_kmer > 4^k && input_kmer > length(kmer_list), phyper(length(kmer_list)-1, length(kmer_list), (4^k)-length(kmer_list), 4^k, lower.tail = FALSE),
                                 ifelse(all_kmer > 4^k, phyper(input_kmer-1, length(kmer_list), (4^k)-length(kmer_list), 4^k, lower.tail = FALSE),
                                 ifelse(input_kmer > length(kmer_list), phyper(length(kmer_list)-1, length(kmer_list), (4^k)-length(kmer_list), all_kmer, lower.tail = FALSE),
                                 suppressWarnings(phyper(input_kmer-1, length(kmer_list), (4^k)-length(kmer_list), all_kmer + input_kmer, lower.tail = FALSE)))))) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(p_adj = p.adjust(p_val, method = "BH")) %>%
    dplyr::arrange(p_adj)

  return(motif_estimate)

}
