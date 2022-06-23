#! bin/bash

NXF_WORK=./test/work nextflow run main.nf \
-c test/global.config \
-c test/test-metapipeline-DNA-fastq-input/test.config \
# -params-file test/test-metapipeline-DNA-fastq-input/input.yaml \
> test/test-metapipeline-DNA-fastq-input/test.out
