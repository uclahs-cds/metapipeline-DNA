nextflow.enable.dsl = 2

include { call_gSNP } from "${projectDir}/../../module/call_gSNP/workflow"
include { create_status_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').set{ ich }

    call_gSNP(ich)
}
