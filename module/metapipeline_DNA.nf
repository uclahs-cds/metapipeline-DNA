
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
include { create_status_directory; mark_pipeline_complete } from "${moduleDir}/pipeline_status"

workflow {
    // Create a status directory to track when pipelines complete
    create_status_directory()

    Channel.of('done').set{ bam2fastq_modification_complete }

    if ( params.input_type == 'BAM' ) {
        if (params.override_realignment) {
            ich_align_DNA_fastq = Channel.fromPath(params.input_csv)
                .splitCsv(header:true)
                .map{ tuple(it.patient, it.sample, it.state, file(it.bam)) }
            mark_pipeline_complete('convert-BAM2FASTQ')
        } else {
            convert_BAM2FASTQ()
            ich_align_DNA_fastq = convert_BAM2FASTQ.out.output_ch_convert_bam2fastq
            bam2fastq_modification_complete.mix(convert_BAM2FASTQ.out.bam2fastq_sample_data_updated).set{ bam2fastq_modification_complete }
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

    bam2fastq_modification_complete.collect().map{ 'done' }.set{ align_dna_modification_signal }

    align_DNA(ich_align_DNA_fastq, align_dna_modification_signal)

    if (params.sample_mode == 'single') {
        recalibrate_BAM(align_DNA.out.output_ch_align_dna, align_DNA.out.alignment_sample_data_updated)
    } else {
        recalibrate_BAM(align_DNA.out.output_ch_align_dna.collect(), align_DNA.out.alignment_sample_data_updated)
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
