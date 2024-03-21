nextflow.enable.dsl = 2

include { calculate_targeted_coverage } from "${projectDir}/../../module/calculate_targeted_coverage/workflow" addParams( this_pipeline: "calculate-targeted-coverage" )
include { create_directory; mark_pipeline_complete; delete_completion_file } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_directory(params.pipeline_status_directory)
    create_directory(params.pipeline_exit_status_directory)

    Channel.of('done').map{ it -> delete_completion_file("recalibrate-BAM"); return 'done' }.set{ ich }

    calculate_targeted_coverage(ich)

    ich.map{ it -> sleep(5000); mark_pipeline_complete("recalibrate-BAM"); return 'done' }.set{ complete_channel }
}
