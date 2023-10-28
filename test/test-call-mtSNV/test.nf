nextflow.enable.dsl = 2

include { call_mtSNV } from "${projectDir}/../../module/call_mtSNV/workflow"
include { create_status_directory } from "${projectDir}/../../module/pipeline_status"

workflow {
    create_status_directory()

    Channel.of('done').set{ ich }

    call_mtSNV(ich)
}
