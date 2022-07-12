
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow"
include { align_DNA } from "${moduleDir}/align_DNA/workflow"
include { call_gSNP } from "${moduleDir}/call_gSNP/workflow"
include { call_sSNV } from "${moduleDir}/call_sSNV/call_sSNV"
include { call_mtSNV } from "${moduleDir}/call_mtSNV/workflow"
include { create_csv_for_align_DNA } from "${moduleDir}/align_DNA/create_csv_for_align_DNA" addParams( log_output_dir: params.metapipeline_log_output_dir )

workflow {
    if ( params.input_type == 'BAM' ) {
        convert_BAM2FASTQ()
        ich_align_DNA_fastq = convert_BAM2FASTQ.out
    } else if ( params.input_type == 'FASTQ' ) {
        // Load CSV and group by sample for align-DNA
        ich = Channel.fromPath(params.input_csv)
            .splitCsv(header: true)
            .map{ [it.sample, [it.state, it.index, it.read_group_identifier, it.sequencing_center, it.library_identifier, it.platform_technology, it.platform_unit, it.bam_header_sm, it.lane, it.read1_fastq, it.read2_fastq]] }
            .groupTuple(by: 0)

        // Create input CSV for align-DNA per sample
        create_csv_for_align_DNA(ich)
        ich_align_DNA_fastq = create_csv_for_align_DNA.out[0]
    }

    align_DNA(ich_align_DNA_fastq)

    call_gSNP(align_DNA.out[0].map{[it]}.collect())
    
    call_sSNV(call_gSNP.out[0])

    call_mtSNV(call_gSNP.out[0])
}
