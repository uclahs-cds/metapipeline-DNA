
nextflow.enable.dsl = 2

include { align_DNA } from "${projectDir}/../../module/align_DNA/workflow"
include { create_status_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').set{ ich }

    align_DNA(ich)
}
