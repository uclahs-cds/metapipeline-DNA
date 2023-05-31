nextflow.enable.dsl = 2

include { call_gSV } from "${projectDir}/../../module/call_gSV/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map{ it -> [
            'patient': it.patient,
            'run_mode': 'multi',
            'tumor_sample': it.tumor_sample,
            'normal_sample': it.normal_sample,
            'tumor_bam': file(it.tumor_bam),
            'normal_bam': file(it.normal_bam)
        ] }
    call_gSV(ich)
}
