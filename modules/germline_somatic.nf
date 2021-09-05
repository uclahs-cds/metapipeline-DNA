
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from './convert_BAM2FASTQ/workflow'

workflow {
    
    convert_BAM2FASTQ(params.input_csv)
}