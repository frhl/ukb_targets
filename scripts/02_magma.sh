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


source utils/bash_utils.sh

readonly in_dir="data/sumstat/giant/exome"
readonly out_dir="data/magma/WHRadjBMI_eur_add_ref10k"

readonly sumstat="${in_dir}/PublicRelease.WHRadjBMI.C.Eur.Add.txt"
readonly out_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD"
readonly snp_loc="${out_prefix}.snp_loc"

readonly magma_dir="/well/lindgren/flassen/software/magma"
#readonly prefix_ref="${magma_dir}/auxiliary_files/reference/g1000_eur"
readonly ref_dir="/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/wes_ko_ukbb/data/prs/hapmap"
readonly prefix_ref="${ref_dir}/long_ukb_hapmap_rand_10k_eur"
readonly genes="${magma_dir}/auxiliary_files/genes/GRCh37/NCBI37.gene.loc"
readonly dbsnp="${magma_dir}/auxiliary_files/dbsnp/dbsnp151.synonyms"
readonly magma="${magma_dir}/./magma"
readonly genome="37"

# geneset to be tested
readonly geneset_dir="/well/lindgren/flassen/projects/adipogenesis/derived/magma/genesets"
readonly geneset="${geneset_dir}/230220_sig_001_test.txt"

# setup MAGMA window
readonly window="window=50,50"

readonly rscript_post_hoc="scripts/02_magma.R"
readonly rscript_map_geneset="scripts/map_geneset.R"

# * Note: Only SNPs in reference panel and target are used for analysis and
# we should therefore generate a new panel using all imputed SNPs with info > 0.8
# * Note: MAGMA can not read in gzipped data

mkdir -p ${out_dir}

if [ ! -f "${out_prefix}.genes.annot" ]; then
  # Format gene gene loc file
  cat ${sumstat} | awk '{print $1"\t"$2"\t"$3}' > ${snp_loc}
  # Annotation Step (SNP to gene mapping)
  module purge
  module load gcccuda/2020b
  ${magma} \
    --annotate "${window}"\
    --snp-loc "${snp_loc}" \
    --gene-loc "${genes}" \
    --out "${out_prefix}" 
fi

if [ ! -f "${out_prefix}.genes.raw" ]; then
  # Gene Analysis Step (calculate gene p-values + other gene-level metrics)
  module purge
  module load gcccuda/2020b
  ${magma} \
    --bfile "${prefix_ref}" \
    --gene-annot "${out_prefix}.genes.annot" \
    --pval "${sumstat}" "pval=9" "snp-id=1" "ncol=10" \
    --out "${out_prefix}"
fi

if [ ! -f "${out_prefix}.geneset" ]; then
  # map geneset for competetive enrichment analysis
  module purge
  set_up_rpy
  Rscript ${rscript_map_geneset} \
    --geneset ${geneset} \
    --genome ${genome} \
    --out ${out_prefix}
fi

if [ ! -f "${out_prefix}.gsa.out" ]; then
  # Gene enrichment step
  module purge
  module load gcccuda/2020b
  ${magma} \
    --gene-results "${out_prefix}.genes.raw" \
    --set-annot "${out_prefix}.geneset" "col=2,1" \
    --out ${out_prefix}
fi

#set -x
#Rscript ${rscript} \
#  --in_file "${out_prefix}.genes.out" \
#  --out_file "${out_prefix}.txt" \
#  --out_sep "\t"
#set +x



