
include { generate_args } from "${moduleDir}/../common"

/*
    Process to call the convert-BAM2FASTQ pipeline.
*/
process call_convert_BAM2FASTQ {
    cpus params.convert_BAM2FASTQ.subworkflow_cpus
    
    publishDir "${params.output_dir}/output",
        mode: 'copy',
        pattern: 'convert-BAM2FASTQ-*/*'

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            path(input_csv)
        )

    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            path("convert-BAM2FASTQ-*/*/*/output/*.fq.gz")
        )
        path "convert-BAM2FASTQ-*/*"
        
    script:
    arg_list = ['get_bam_stats_SAMtools_cpus', 'collate_bam_SAMtools_cpus']
    args = generate_args(params.convert_BAM2FASTQ, arg_list)
    """
    set -euo pipefail

    nextflow \
        -C ${moduleDir}/default.config \
        run ${moduleDir}/../../external/pipeline-convert-BAM2FASTQ/main.nf \
        --input_csv ${input_csv} \
        --output_dir \$(pwd) \
        --temp_dir ${params.work_dir} \
        ${args}
    """
}
