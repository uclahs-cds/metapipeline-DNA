nextflow.enable.dsl = 2

include { call_gSV } from "${projectDir}/../../module/call_gSV/workflow"
include { create_status_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').set{ ich }

    call_gSV(ich)
}
