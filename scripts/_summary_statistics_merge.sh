#!/usr/bin/env bash
#
#$ -N _summary_statistics_merge
#$ -wd /well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/ukb_targets
#$ -o logs/_summary_statistics_merge.log
#$ -e logs/_summary_statistics_merge.errors.log
#$ -V

source utils/bash_utils.sh

readonly prefix=${1?Error: Missing arg1 (prefix)}
readonly out_dir=${2?Error: Missing arg2 (out_dir)}
readonly out=${3?Error: Missing arg3 (out without)}
readonly out_without_gz=$(echo ${out} | sed -e "s/\\.gz//g")

file=$(echo ${prefix} | sed -e "s/CHR//g" )
readonly basename="${file##*/}"
readonly files="${basename}[0-9]+\.txt\.gz"
readonly n=$(ls -l "${out_dir}" | grep -E "${files}" | wc -l)
readonly N=21

if (( $(echo "$n > $N" | bc -l) )); then
  zcat ${file}* | tail -n+2 > "${out_without_gz}"
  for chr in {1..22}; do
     file=$(echo ${prefix} | sed -e "s/CHR/${chr}/g")
     zcat "${file}.txt.gz" | tail -n +2  >> "${out_without_gz}"
  done
  gzip "${out_without_gz}"
else
  >&2 echo "Some chromosomes are missing for ${file}"
fi





