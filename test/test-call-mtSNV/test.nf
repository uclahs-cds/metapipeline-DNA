nextflow.enable.dsl = 2

include { call_mtSNV } from "${projectDir}/../../module/call_mtSNV/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map{ it -> [
            'patient': it.patient,
            'run_mode': 'multi',
            'tumor_sample': it.tumour_id,
            'normal_sample': it.normal_id,
            'tumor_bam': file(it.tumour_BAM),
            'normal_bam': file(it.normal_BAM)
        ] }
    call_mtSNV(ich)
}
