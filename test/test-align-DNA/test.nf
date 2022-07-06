
nextflow.enable.dsl = 2

include { align_DNA } from "${projectDir}/../../modules/align_DNA/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map { tuple(it.patient, it.sample, it.state, file(it.input_csv)) }
    align_DNA(ich)
}
