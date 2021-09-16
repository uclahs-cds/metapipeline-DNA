
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow"
include { align_DNA } from "${moduleDir}/align_DNA/workflow"
include { call_gSNP } from "${moduleDir}/call_gSNP"
inlcude { call_sSNV } from "${moduleDir}/call_sSNV"

workflow {
    convert_BAM2FASTQ()
    
    align_DNA(convert_BAM2FASTQ.out)
    
    call_gSNP(align_DNA.out.collect())
    
    call_sSNV(call_gSNP.out)
}