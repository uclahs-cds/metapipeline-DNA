nextflow.enable.dsl = 2

include { recalibrate_BAM } from "${projectDir}/../../module/recalibrate_BAM/workflow"

workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map{ it -> [
            'patient': it.patient,
            'sample': it.sample,
            'state': it.state,
            'bam': it.bam
        ] }
        .collect()
    recalibrate_BAM(ich)    
}
