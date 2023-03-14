#! bin/bash

# python3 /hot/user/hwinata/pipelines/tool-submit-nf/submit_nextflow_pipeline.py \
#     --nextflow_script /hot/user/hwinata/pipelines/metapipeline-DNA/main.nf \
#     --nextflow_config /hot/user/hwinata/pipelines/metapipeline-DNA/test/test-metapipeline-DNA-fastq-input/test.config \
#     --pipeline_run_name test-meta-DNA \
#     --partition_type F16

sbatch \
--exclusive \
--partition=F2 \
-J test-meta-DNA \
--wrap="TEMP_DIR=\$(mktemp -d /scratch/XXXXXXX) && cd \$TEMP_DIR && nextflow run /hot/user/hwinata/pipelines/metapipeline-DNA/main.nf -config /hot/user/hwinata/pipelines/metapipeline-DNA/test/test-metapipeline-DNA-batch/test.config"