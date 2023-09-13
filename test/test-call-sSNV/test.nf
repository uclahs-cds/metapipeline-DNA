nextflow.enable.dsl = 2

include { call_sSNV } from "${projectDir}/../../module/call_sSNV/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map{ it -> [
            'normal': [[
                'patient': it.patient,
                'sample': it.normal_sample,
                'state': 'normal',
                'bam': it.normal_bam
                ]],
            'tumor': [[
                'patient': it.patient,
                'sample': it.tumor_sample,
                'state': 'tumor',
                'bam': it.tumor_bam
                ]],
            ] }
    call_sSNV(ich)
}
