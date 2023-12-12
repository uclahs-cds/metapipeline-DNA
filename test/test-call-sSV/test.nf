nextflow.enable.dsl = 2

include { call_sSV } from "${projectDir}/../../module/call_sSV/workflow"
include { create_status_directory; mark_pipeline_complete } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').set{ ich }

    call_sSV(ich)

    ich.map{ it -> sleep(5000); mark_pipeline_complete("recalibrate-BAM"); return 'done' }.set{ complete_channel }
}
