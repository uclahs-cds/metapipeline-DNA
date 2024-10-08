include { combine_input_with_params; generate_weblog_args } from '../common.nf'

/*
    Process to call the align-DNA pipeline.
*/
process call_align_DNA {
    cpus params.align_DNA.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "align-DNA-*/*"

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample}/log${file(it).getName()}" }

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            path(input_csv)
        )
    
    output:
        tuple val(sample), path(output_directory), emit: align_dna_output_directory
        file "align-DNA-*/*"
        file ".command.*"

    script:
    output_directory = "align-DNA-*/${sample}"
    bam = "align-DNA-*/${sample}/BWA-MEM2-2.2.1/output/BWA-MEM2-*${sample}.bam"

    String params_to_dump = combine_input_with_params(params.align_DNA.metapipeline_arg_map)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_align_dna_params.yaml

    WORK_DIR=${params.work_dir}/work-align-DNA-${sample}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR
    nextflow run \
        ${moduleDir}/../../external/pipeline-align-DNA/main.nf \
        -params-file combined_align_dna_params.yaml \
        --sample_id ${sample} \
        --output_dir \$(pwd) \
        --work_dir \$WORK_DIR \
        --spark_temp_dir \$WORK_DIR \
        --input_csv ${input_csv} \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    rm -r \$WORK_DIR
    """
}
