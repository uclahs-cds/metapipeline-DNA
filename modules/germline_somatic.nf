
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow"
include { align_DNA } from "${moduleDir}/align_DNA/workflow"
include { call_gSNP } from "${moduleDir}/call_gSNP/workflow-DSL1"
include { call_sSNV } from "${moduleDir}/call_sSNV/call_sSNV"
include { call_mtSNV } from "${moduleDir}/call_mtSNV/workflow"

workflow {
    convert_BAM2FASTQ()
    
    align_DNA(convert_BAM2FASTQ.out)
    
    align_DNA.out[0]

    call_gSNP(align_DNA.out[0].map{[it]}.collect())
    
    call_sSNV(call_gSNP.out[0])

    call_mtSNV(call_gSNP.out[0])
}
