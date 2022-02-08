#!/usr/bin/env python3

import hail as hl
import argparse

from ko_utils import qc
from ukb_utils import hail_init
from ukb_utils import genotypes
from ukb_utils import samples
from ukb_utils import variants

def main(args):

    # parser
    chrom = args.chrom
    ancestry = args.ancestry
    dataset = args.dataset
    extract_samples = args.extract_samples
    hapmap = args.hapmap
    min_maf = args.min_maf
    min_info = args.min_info 
    liftover = args.liftover
    dbsnp = args.dbsnp
    response = args.response
    covariates = args.covariates
    phenotypes = args.phenotypes
    out_prefix = args.out_prefix

    hail_init.hail_bmrc_init_local('logs/hail/hail_format.log', 'GRCh38')
    hl._set_flags(no_whole_stage_codegen='1') # from zulip
    
    if chrom in "AUTOSOMES":
        chrom = list(map(str, range(1, 23)))
    else:
        chrom = [chrom]

    if dataset in "imp":
        mt = genotypes.get_ukb_imputed_v3_bgen(chroms=chrom)
        if min_info:
            ht = genotypes.get_ukb_parsed_imputed_v3_mfi(chroms=chrom)
            mt = mt.annotate_rows(info_score = ht[(mt.locus, mt.alleles)].info)
            mt = mt.filter_rows(mt.info_score >= float(min_info))
    elif dataset in "calls":
        mt = genotypes.get_ukb_genotypes_bed(chroms=chrom)
    else:
        raise TypeError(f"{dataset} is not 'imp' or 'calls'")

    if extract_samples:
        ht_samples = hl.import_table(extract_samples, no_header=True, key='f0', delimiter=',')
        mt = mt.filter_cols(hl.is_defined(ht_samples[mt.col_key]))

    if ancestry:
        mt = samples.filter_ukb_to_ancestry(mt, ancestry)

    if hapmap:
        ht = hl.read_table(hapmap)
        ht = ht.key_by('locus_grch37')
        mt = mt.filter_rows(hl.is_defined(ht[mt.locus]))
        print("Finished filter variants by hapmap SNPs")

    if min_maf:
        mt = mt.filter_rows(variants.get_maf_expr(mt) > float(min_maf))
        print("Finished subsetting by MAF")

    if liftover:
        mt = variants.liftover(mt, from_build='GRCh37', to_build='GRCh38', drop_annotations=True)
        print("Finished performing liftover")

    if dbsnp:
        ht = variants.get_dbsnp_table(version=155, build='GRCh38')
        mt = mt.annotate_rows(rsid = ht.rows()[mt.row_key].rsid)
        print("Finished annotating with dbsnp")
    #
    if phenotypes:
        ht = hl.import_table(phenotypes,
                     types={'eid': hl.tstr},
                     missing=["",'""'],
                     impute=True,
                     key='eid') 
        mt = mt.annotate_cols(pheno=ht[mt.s])
    else:
        raise ValueError("param 'phenotypes' is not set! ")
    
    covariates = covariates.split(',')
    if set(list(mt.pheno)) >= set(covariates):
        covariates = [mt.pheno[x] for x in covariates]
        covariates.insert(0, 1) 
        if response in list(mt.pheno):
            if mt.pheno[response].dtype == hl.dtype('float64'):
                reg = hl.linear_regression_rows(
                        y=mt.pheno[response],
                        x=mt.GT.n_alt_alleles(),
                        covariates=covariates
                        )
            elif mt.pheno[response].dtype == hl.dtype('bool'):
                reg = hl.logistic_regression_rows(
                        test='wald',
                        y=mt.pheno[response],
                        x=mt.GT.n_alt_alleles(),
                        covariates=covariates
                        )
            else:
                raise TypeError("Response variable is not a float64 or boolean!")
        else:
            raise TypeError("Response variable is not in phenotype file")
    else:    
        raise TypeError("Some or all covariates are not in phenotype file!")

    # get AFs
    #mt = qc.recalc_info(mt) # already being done in qc.get_table
    reg = reg.annotate(
        AN = mt.rows()[reg.key].info.AN,
        AC = mt.rows()[reg.key].info.AC,
        AF = mt.rows()[reg.key].info.AF
    )
    
    # Get individual alleles
    reg = reg.annotate(
        a0 = reg.alleles[0],
        a1 = reg.alleles[1]
    )    

    reg.flatten().export(out_prefix + ".txt.gz")



if __name__=='__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--chrom', default=None, help='chromosomes to be parsed.')
    parser.add_argument('--input_path', default=None, help='Path to input.')
    parser.add_argument('--input_type', default=None, help='Input type (vcf/mt/plink).')
    parser.add_argument('--min_info', default=None, help='minimum info score (only imputed data)')
    parser.add_argument('--min_maf', default=None, help='minimum MAF score')
    parser.add_argument('--liftover', default=None, action='store_true', help='perform liftover')
    parser.add_argument('--extract_samples', default=None, help='Subset to sample IDs in file')
    parser.add_argument('--hapmap', default=None, help='Path to HapMap SNPs')
    parser.add_argument('--dbsnp', default=None, help='annotate with rsids from dbsnp')
    parser.add_argument('--dataset', default=None, help='Either "imp" or "calls".')
    parser.add_argument('--response', default=None, help='Response variable')
    parser.add_argument('--covariates', default=None, help='list of covariates')
    parser.add_argument('--phenotypes', default=None, help='File path to phenotypes.')
    parser.add_argument('--out_prefix', default=None, help='Path prefix for output dataset')
    args = parser.parse_args()

    main(args)


