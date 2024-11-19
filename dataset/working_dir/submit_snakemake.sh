#!/bin/bash
snakemake -s ../../local/snakefile/snakefile_test.smk -c 1 --resources mem_mb=5000 -np
