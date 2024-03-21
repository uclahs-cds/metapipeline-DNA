
nextflow.enable.dsl = 2

include { align_DNA } from "${projectDir}/../../module/align_DNA/workflow" addParams( this_pipeline: "align-DNA" )
include { create_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_directory(params.pipeline_status_directory)
    create_directory(params.pipeline_exit_status_directory)

    Channel.of('done').set{ ich }

    align_DNA(ich)
}
