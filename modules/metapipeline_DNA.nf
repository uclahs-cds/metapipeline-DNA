
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow"
include { align_DNA } from "${moduleDir}/align_DNA/workflow"
include { call_gSNP } from "${moduleDir}/call_gSNP/workflow"
include { call_sSNV } from "${moduleDir}/call_sSNV/call_sSNV"
include { call_mtSNV } from "${moduleDir}/call_mtSNV/workflow"

workflow {
    if (params.file_type.equals('BAM')) {
    convert_BAM2FASTQ()
    align_DNA_input = convert_BAM2FASTQ.out

    } else if (params.file_type.equals('FASTQ')) { 
        align_DNA_input = Channel.value([
            params.patient, 
            params.sample,
            params.state,
            params.site,
            params.input_csv
            ])
        align_DNA_input.view()
        
    }

    align_DNA(align_DNA_input)

    call_gSNP(align_DNA.out[0].map{[it]}.collect())
    
    call_sSNV(call_gSNP.out[0])

    call_mtSNV(call_gSNP.out[0])
}
