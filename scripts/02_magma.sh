#!/usr/bin/env bash
#
#$ -N magma
#$ -wd /well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/ukb_targets
#$ -o logs/magma.log
#$ -e logs/magma.errors.log
#$ -P lindgren.prjc
#$ -pe shmem 1
#$ -q short.qc@@short.hga
#$ -t 1
#$ -V

module load gcccuda/2020b

readonly in_dir="data/sumstat/giant"
readonly out_dir="data/magma"

readonly sumstat="${in_dir}/PublicRelease.WHRadjBMI.C.Eur.Add.txt.gz"
readonly out_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD"
#readonly annot_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD_annot"
#readonly gene_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD_gene"
readonly snp_loc="${out_prefix}.snp_loc"

readonly magma_dir="/well/lindgren/flassen/software/magma"
readonly prefix_ref="${magma_dir}/auxiliary_files/reference/g1000_eur"
readonly genes="${magma_dir}/auxiliary_files/genes/GRCh37/NCBI37.gene.loc"
readonly dbsnp="${magma_dir}/auxiliary_files/dbsnp/dbsnp151.synonyms"
readonly magma="${magma_dir}/./magma"

mkdir -p ${out_dir}

zcat ${sumstat} | awk '{print $1"\t"$2"\t"$3}' > ${snp_loc}

if [ ! -f "${out_prefix}.genes.annot" ]; then
  set -x
  ${magma} \
    --annotate \
    --snp-loc ${snp_loc} \
    --gene-loc ${genes} \
    --out ${out_prefix} 
  set +x
else
  >&2 echo "${out_prefix}.genes.annot already exist. Skipping.."
fi



${magma} \
    --bfile ${prefix_ref} \
    --gene-annot "${out_prefix}.genes.annot" \
    --pval ${sumstat} \
    --out ${out_prefix} \
    --ncol "n" \
 



