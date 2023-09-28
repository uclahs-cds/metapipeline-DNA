
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow"
include { align_DNA } from "${moduleDir}/align_DNA/workflow"
include { recalibrate_BAM } from "${moduleDir}/recalibrate_BAM/workflow"
include { call_gSNP } from "${moduleDir}/call_gSNP/workflow"
include { call_sSNV } from "${moduleDir}/call_sSNV/workflow"
include { call_mtSNV } from "${moduleDir}/call_mtSNV/workflow"
include { call_gSV } from "${moduleDir}/call_gSV/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { call_sSV } from "${moduleDir}/call_sSV/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { create_CSV_align_DNA } from "${moduleDir}/align_DNA/create_CSV_align_DNA" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { create_status_directory } from "${moduleDir}/pipeline_status"

workflow {
    // Create a status directory to track when pipelines complete
    create_status_directory()

    if ( params.input_type == 'BAM' ) {
        if (params.override_realignment) {
            ich_align_DNA_fastq = Channel.fromPath(params.input_csv)
                .splitCsv(header:true)
                .map{ tuple(it.patient, it.sample, it.state, file(it.bam)) }
        } else {
            convert_BAM2FASTQ()
            ich_align_DNA_fastq = convert_BAM2FASTQ.out
        }
    } else if ( params.input_type == 'FASTQ' ) {
        // Load CSV and group by sample for align-DNA
        ich = Channel.fromPath(params.input_csv)
            .splitCsv(header: true)
            .map{ [it.sample, [it.state, it.read_group_identifier, it.sequencing_center, it.library_identifier, it.platform_technology, it.platform_unit, it.bam_header_sm, it.lane, it.read1_fastq, it.read2_fastq]] }
            .groupTuple(by: 0)

        // Create input CSV for align-DNA per sample
        create_CSV_align_DNA(ich)
        ich_align_DNA_fastq = create_CSV_align_DNA.out.align_dna_csv
    }

    align_DNA(ich_align_DNA_fastq)

    if (params.sample_mode == 'single') {
        recalibrate_BAM(align_DNA.out.output_ch_align_dna)
    } else {
        recalibrate_BAM(align_DNA.out.output_ch_align_dna.collect())
    }

    recalibrate_BAM.out.output_ch_recalibrate_bam.view()

    if (params.call_gSNP.is_pipeline_enabled) {
        call_gSNP(recalibrate_BAM.out.output_ch_recalibrate_bam)
    }

    if (params.call_sSNV.is_pipeline_enabled) {
        call_sSNV(recalibrate_BAM.out.output_ch_recalibrate_bam)
    }

    if (params.call_mtSNV.is_pipeline_enabled) {
        call_mtSNV(recalibrate_BAM.out.output_ch_recalibrate_bam)
    }

    if (params.call_gSV.is_pipeline_enabled) {
        call_gSV(recalibrate_BAM.out.output_ch_recalibrate_bam)
    }

    if (params.call_sSV.is_pipeline_enabled) {
        call_sSV(recalibrate_BAM.out.output_ch_recalibrate_bam)
    }
}
