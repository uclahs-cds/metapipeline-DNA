nextflow.enable.dsl = 2

include { recalibrate_BAM } from "${projectDir}/../../module/recalibrate_BAM/workflow" addParams( this_pipeline: "recalibrate-BAM" )
include { create_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_directory(params.pipeline_status_directory)
    create_directory(params.pipeline_exit_status_directory)

    Channel.of('done').set{ ich }

    recalibrate_BAM(ich)
}
