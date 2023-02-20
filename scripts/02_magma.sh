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

source utils/bash_utils.sh

readonly in_dir="data/sumstat/giant/exome"
readonly out_dir="data/magma/WHRadjBMI_eur_add_ref10k"

readonly sumstat="${in_dir}/PublicRelease.WHRadjBMI.C.Eur.Add.txt"
readonly out_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD"
readonly snp_loc="${out_prefix}.snp_loc"

readonly magma_dir="/well/lindgren/flassen/software/magma"
readonly prefix_ref="${magma_dir}/auxiliary_files/reference/g1000_eur"
#readonly ref_dir="/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/wes_ko_ukbb/data/prs/hapmap"
#readonly prefix_ref="${ref_dir}/long_ukb_hapmap_rand_10k_eur"
readonly genes="${magma_dir}/auxiliary_files/genes/GRCh37/NCBI37.gene.loc"
readonly dbsnp="${magma_dir}/auxiliary_files/dbsnp/dbsnp151.synonyms"
readonly magma="${magma_dir}/./magma"

# setup MAGMA window
readonly window="" #"window=50,50"

readonly rscript="scripts/02_magma.R"

# * Note: Only SNPs in reference panel and target are used for analysis and
# we should therefore generate a new panel using all imputed SNPs with info > 0.8
# * Note: MAGMA can not read in gzipped data

mkdir -p ${out_dir}

# Format gene gene loc file
cat ${sumstat} | awk '{print $1"\t"$2"\t"$3}' > ${snp_loc}

# Annotation Step (SNP to gene mapping)
set -x
${magma} \
  --annotate "${window}"\
  --snp-loc "${snp_loc}" \
  --gene-loc "${genes}" \
  --out "${out_prefix}" 
set +x

# Gene Analysis Step (calculate gene p-values + other gene-level metrics)
set -x
${magma} \
  --bfile "${prefix_ref}" \
  --gene-annot "${out_prefix}.genes.annot" \
  --pval "${sumstat}" "pval=9" "snp-id=1" "ncol=10" \
  --out "${out_prefix}"
set +x


set_up_rpy
set -x
Rscript ${rscript} \
  --in_file "${out_prefix}.genes.out" \
  --out_file "${out_prefix}.txt" \
  --out_sep "\t"
set +x



