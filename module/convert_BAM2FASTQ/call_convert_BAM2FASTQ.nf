include { combine_input_with_params } from '../common.nf'

/*
    Process to call the convert-BAM2FASTQ pipeline.
*/
process call_convert_BAM2FASTQ {
    cpus params.convert_BAM2FASTQ.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: 'copy',
        pattern: 'convert-BAM2FASTQ-*/*',
        saveAs: { "${it}-${portion}" }

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample}-${portion}/log${file(it).getName()}" }

    input:
        tuple(
            val(patient),
            val(sample),
            val(portion),
            val(state),
            path(input_csv),
            path(bam)
        )

    output:
        tuple(
            val(patient),
            val(sample),
            val(portion),
            val(state),
            path("convert-BAM2FASTQ-*/*/*/output/*.fastq.gz"),
            path(output_directory),
            path(bam)
        )
        path "convert-BAM2FASTQ-*/*"
        path ".command.*"

    script:
    output_directory = "convert-BAM2FASTQ-*/${sample}/SAMtools-*/output"
    String params_to_dump = combine_input_with_params(params.convert_BAM2FASTQ.metapipeline_arg_map)
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_bam2fastq_params.yaml

    WORK_DIR=${params.work_dir}/work-bam2fastq-${sample}-${portion}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR
    nextflow \
        -C ${moduleDir}/default.config \
        run ${moduleDir}/../../external/pipeline-convert-BAM2FASTQ/main.nf \
        -params-file combined_bam2fastq_params.yaml \
        --input_csv ${input_csv} \
        --output_dir \$(pwd) \
        --work_dir \$WORK_DIR \
        --portion_id ${portion} \
        --dataset_id ${params.project_id}

    rm -r \$WORK_DIR
    """
}
