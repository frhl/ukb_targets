#!/usr/bin/env bash
#
#$ -N summary_statistics
#$ -wd /well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/ukb_targets
#$ -o logs/summary_statistics.log
#$ -e logs/summary_statistics.errors.log
#$ -P lindgren.prjc
#$ -pe shmem 1
#$ -q short.qc@@short.hga
#$ -t 1
#$ -V

# cts
# 1 - 33 contains non-residuals
# 34 - 103 contains residuals

module purge
source utils/bash_utils.sh
source utils/hail_utils.sh

readonly pheno_dir="data/phenotypes"
readonly out_dir="data/sumstat"

readonly bash_script="scripts/_summary_statistics.sh"
readonly hail_script="scripts/01_summary_statistics.py"
readonly merge_script="scripts/_summary_statistics_merge.sh"

readonly covar_file="${pheno_dir}/covars1.csv"
readonly covariates=$( cat ${covar_file} )

readonly pheno_file="${pheno_dir}/curated_phenotypes.tsv" 
readonly pheno_list_cts="${pheno_dir}/curated_phenotypes_cts_header.tsv"
readonly phenotype_cts=$( cut -f${SGE_TASK_ID} ${pheno_list_cts} )
readonly pheno_list_binary="${pheno_dir}/curated_phenotypes_binary_header.tsv"
readonly phenotype_binary=$( cut -f${SGE_TASK_ID} ${pheno_list_binary} )

readonly dataset="imp"
readonly min_info="7e-1"
readonly min_maf="1e-4"

submit_sumstat_job()
{
  mkdir -p ${out_dir}
  local phenotype="${1}"
  local out_prefix="${out_dir}/ukb_${dataset}_info_${min_info}_maf_${min_maf}_eur_${phenotype}"
  local prefix="${out_prefix}_chrCHR"
  set -x
  qsub -N "_${phenotype}_sumstat" \
    -t 21 \
    -q short.qc@@short.hge \
    -pe shmem 1 \
    "${bash_script}" \
    "${hail_script}" \
    "${dataset}" \
    "${min_info}" \
    "${min_maf}" \
    "${pheno_file}" \
    "${phenotype}" \
    "${covariates}" \
    "${prefix}"
  set +x
  #submit_merge_job
}

submit_merge_job()
{
  set -x
  qsub -N "_mrg_${phenotype}" \
    -q short.qc@@short.hge \
    -pe shmem 1 \
    -hold_jid "_${phenotype}_sumstat" \
    "${merge_script}" \
    "${prefix}" \
    "${out_dir}" \
    "${out_prefix}.txt.gz"
  set +x

}

submit_sumstat_job "${phenotype_binary}"



