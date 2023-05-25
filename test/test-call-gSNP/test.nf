nextflow.enable.dsl = 2

include { call_gSNP } from "${projectDir}/../../module/call_gSNP/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map{ it -> [
                    'patient': it.patient,
                    'sample': it.sample,
                    'state': it.state,
                    'bam_header_sm': it.bam_header_sm,
                    'bam': file(it.bam)
        ] }
        .collect()
    call_gSNP(ich)    
}
