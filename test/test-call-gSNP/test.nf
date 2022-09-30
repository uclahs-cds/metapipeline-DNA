nextflow.enable.dsl = 2

include { call_gSNP } from "${projectDir}/../../module/call_gSNP/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map { [tuple(it.patient, it.sample, it.state, it.bam_header_sm, file(it.bam))] }
        .collect()
    call_gSNP(ich)    
}
