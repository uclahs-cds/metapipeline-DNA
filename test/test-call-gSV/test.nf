nextflow.enable.dsl = 2

include { call_gSV } from "${projectDir}/../../module/call_gSV/workflow"
include { create_directory; mark_pipeline_complete; delete_completion_file } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_directory(params.pipeline_status_directory)
    create_directory(params.pipeline_exit_status_directory)

    Channel.of('done').map{ it -> delete_completion_file("recalibrate-BAM"); return 'done' }.set{ ich }

    call_gSV(ich)

    ich.map{ it -> sleep(5000); mark_pipeline_complete("recalibrate-BAM"); return 'done' }.set{ complete_channel }
}
