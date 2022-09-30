
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${projectDir}/../../module/convert_BAM2FASTQ/workflow"

workflow {
    convert_BAM2FASTQ()
}