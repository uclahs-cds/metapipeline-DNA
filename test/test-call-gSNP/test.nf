nextflow.enable.dsl = 2

include { call_gSNP } from "${projectDir}/../../modules/call_gSNP/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map { [tuple(it.patient, it.sample, it.state, it.site, it.bam_header_sm, file(it.bam))] }
        .collect()
    call_gSNP(ich)    
}
