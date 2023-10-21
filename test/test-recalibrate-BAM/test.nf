nextflow.enable.dsl = 2

include { recalibrate_BAM } from "${projectDir}/../../module/recalibrate_BAM/workflow"
include { create_status_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').set{ ich }

    recalibrate_BAM(ich)
}
