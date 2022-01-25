nextflow.enable.dsl = 2

include { call_mtSNV } from "${projectDir}/../../modules/call_mtSNV/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map { tuple(
            it.patient, it.tumor_sample, it.normal_sample, it.tumor_site,
            it.normal_site, file(it.tumor_bam), file(it.normal_bam)
        ) }
    call_mtSNV(ich)
}
