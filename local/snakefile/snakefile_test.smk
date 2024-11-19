# 1000GP vcf high coverage filtered for 10 random EUR and 1240k bed file
input_vcf='1kGP_10_EUR_chr22_1240K_sites.vcf.gz'
prefix = 'example_chr22'

rule all:
    input:
        'LDpruning/' + prefix + '.LDpruned.ped'

rule convert_to_plink_ancestral:
    input:
        vcf = input_vcf
    output:
        ped = 'plink/' + prefix + '.pgen'
    params:
        out = 'plink/' + prefix
    resources:
        mem_mb=4000
    benchmark:
        'benchmarks/plink_' + prefix + '.txt'
    shell:
        '''
	plink2 --vcf {input.vcf} --out {params.out} --allow-extra-chr --maf 0.05 --geno 0.8 --make-pgen --memory {resources.mem_mb}
        '''
rule LD_pruning:
    input:
        ped='plink/' + prefix + '.pgen'
    output:
        prune_in='LDpruning/' + prefix + '.prune.in',
        ped='LDpruning/' + prefix + '.LDpruned.ped'
    params:
        inp='plink/' + prefix ,
        out='LDpruning/' + prefix + '.LDpruned'
    resources:
        mem_mb=4000
    benchmark:
        'benchmarks/LDpruning_' + prefix + '.txt'
    shell:
        '''
        plink2 --pfile {params.inp} --indep-pairwise 500 50 0.4 --out {params.out} --memory {resources.mem_mb}
        plink2 --pfile {params.inp} --extract {output.prune_in}  --out {params.out} --export ped --memory {resources.mem_mb}
        '''
