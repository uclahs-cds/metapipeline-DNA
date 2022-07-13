nextflow.enable.dsl = 2

include { call_mtSNV } from "${projectDir}/../../modules/call_mtSNV/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map { tuple(
            it.sample_id, it.tumour_id, it.normal_id,
            file(it.tumour_BAM), file(it.normal_BAM)
        ) }
    call_mtSNV(ich)
}
