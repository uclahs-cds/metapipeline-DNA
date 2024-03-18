nextflow.enable.dsl = 2

include { generate_SQC_BAM } from "${projectDir}/../../module/generate_SQC_BAM/workflow"
include { create_status_directory; mark_pipeline_complete; delete_completion_file } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').map{ it -> delete_completion_file("recalibrate-BAM"); return 'done' }.set{ ich }

    generate_SQC_BAM(ich)

    ich.map{ it -> sleep(5000); mark_pipeline_complete("recalibrate-BAM"); return 'done' }.set{ complete_channel }
}
