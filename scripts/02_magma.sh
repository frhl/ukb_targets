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

readonly sumstat="${in_dir}/PublicRelease.WHRadjBMI.C.Eur.Add.txt"
readonly out_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD"
#readonly annot_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD_annot"
#readonly gene_prefix="${out_dir}/WHRadjBMI_C_Eur_ADD_gene"
readonly snp_loc="${out_prefix}.snp_loc"

readonly magma_dir="/well/lindgren/flassen/software/magma"
readonly prefix_ref="${magma_dir}/auxiliary_files/reference/g1000_eur"
readonly genes="${magma_dir}/auxiliary_files/genes/GRCh37/NCBI37.gene.loc"
readonly dbsnp="${magma_dir}/auxiliary_files/dbsnp/dbsnp151.synonyms"
readonly magma="${magma_dir}/./magma"

# * Note: Only SNPs in reference panel and target are used for analysis and
# we should therefore generate a new panel using all imputed SNPs with info > 0.8
# * Note: MAGMA can not read in gzipped data

mkdir -p ${out_dir}

# Format gene gene loc file
if [ ! -f ${snp_loc} ]; then
  cat ${sumstat} | awk '{print $1"\t"$2"\t"$3}' > ${snp_loc}
else
  >&2 echo "${snp_loc} already exists. Skipping.."
fi
# Annotation Step (SNP to gene mapping)
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


# Gene Analysis Step (calculate gene p-values + other gene-level metrics)
${magma} \
    --bfile ${prefix_ref} \
    --gene-annot "${out_prefix}.genes.annot" \
    --pval "${sumstat}" 'pval=9' 'snp-id=1' 'ncol=10' \
    --out ${out_prefix} 
 
#snp-id=snpname "pval=pvalue" "ncol=n" \
 #snp-id="snoname" pval="pvalue"



