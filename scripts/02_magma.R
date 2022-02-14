
library(argparse)
library(data.table)

main <- function(){

  d <- fread(args$in_path)
  genes <- fread('/well/lindgren/flassen/software/magma/auxiliary_files/genes/GRCh38/NCBI38.gene.loc')
  gene_mapping <- data.table(GENE = genes$V1, HGNC_SYMBOL=genes$V6)
  mrg <- merge(d, gene_mapping, all.x = TRUE)
  mrg$FDR <- stats::p.adjust(mrg$P, method = 'fdr')
  mrg <- mrg[order(mrg$P),]
  fwrite(mrg, file = args$outpath, sep = args$out_sep)

}


# add arguments
parser <- ArgumentParser()
parser$add_argument("--in_path", default=NULL, required = TRUE, help = "Input")
parser$add_argument("--out_path", default=NULL, required = TRUE, help = "Output")
parser$add_argument("--out_sep", default="\t", help = "Output seperator")
args <- parser$parse_args()

main()

