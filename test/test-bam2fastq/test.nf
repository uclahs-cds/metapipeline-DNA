
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${projectDir}/../../module/convert_BAM2FASTQ/workflow" addParams( this_pipeline: "convert-BAM2FASTQ" )
include { create_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_directory(params.pipeline_status_directory)
    create_directory(params.pipeline_exit_status_directory)
    convert_BAM2FASTQ()
}
