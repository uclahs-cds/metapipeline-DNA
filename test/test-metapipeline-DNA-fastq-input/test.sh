#! bin/bash

NXF_WORK=./test/work nextflow run main.nf \
-c test/global.config \
-c test/test-metapipeline-DNA-fastq-input/test.config \
> test/test-metapipeline-DNA-fastq-input/test.out