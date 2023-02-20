
library(argparse)
library(data.table)

main <- function(args){
 
  # read input
  stopifnot(file.exists(args$geneset)) 
  stopifnot(args$genome %in% as.character(c(37,38)))  
  d <- fread(args$geneset)
  loc_path <- paste0('/well/lindgren/flassen/software/magma/auxiliary_files/genes/GRCh',args$genome,'/NCBI',args$genome,'.gene.loc')
  if (!file.exists(loc_path)) stop(paste(loc_path, "does not exist!"))
  if (ncol(d) != 2) stop("Expected two columns, one with geneset and the other with gene name using HGNC symbols")
  colnames(d) <- c("geneset", "hgnc_symbol")

  # read data and create mapping
  genes <- fread(loc_path, header = FALSE)
  colnames(genes) <- c("id", "chr", "start", "stop", "strand", "hgnc_symbol")
  mapping <- genes$id
  names(mapping) <- genes$hgnc_symbol

  # re-map to id used by MAGMA 
  d$id <- mapping[d$hgnc_symbol]

  # remove missing values
  d$missing <- is.na(d$id)
  if (sum(d$missing) > 0) {
    write(paste("excluding", sum(d$missing), "rows with missing gene names.."), stderr())
    d <- d[!d$missing, ]
  }

  # subset to final columns
  d <- d[,c("geneset", "id")]  
  
  # write mapped file 
  outfile <- paste0(args$out, ".geneset")
  fwrite(d, outfile, sep="\t", col.names = FALSE)

}


# add arguments
parser <- ArgumentParser()
parser$add_argument("--geneset", default=NULL, required = TRUE, help = "Input")
parser$add_argument("--out", default=NULL, required = TRUE, help = "Output")
parser$add_argument("--genome", default=NULL, required = TRUE, help = "reference genome")
args <- parser$parse_args()

main(args)

