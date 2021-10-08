
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${projectDir}/../../modules/convert_BAM2FASTQ/workflow"

workflow {
    convert_BAM2FASTQ()
}