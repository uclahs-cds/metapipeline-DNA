
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${projectDir}/../../module/convert_BAM2FASTQ/workflow"
include { create_status_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()
    convert_BAM2FASTQ()
}