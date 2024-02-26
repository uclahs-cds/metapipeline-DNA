
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow"
include { align_DNA } from "${moduleDir}/align_DNA/workflow"
include { recalibrate_BAM } from "${moduleDir}/recalibrate_BAM/workflow"
include { calculate_targeted_coverage } from "${moduleDir}/calculate_targeted_coverage/workflow"
include { call_gSNP } from "${moduleDir}/call_gSNP/workflow"
include { call_sSNV } from "${moduleDir}/call_sSNV/workflow"
include { call_mtSNV } from "${moduleDir}/call_mtSNV/workflow"
include { call_gSV } from "${moduleDir}/call_gSV/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { call_sSV } from "${moduleDir}/call_sSV/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { call_sCNA } from "${moduleDir}/call_sCNA/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { create_status_directory; mark_pipeline_complete } from "${moduleDir}/pipeline_status"

workflow {
    // Create a status directory to track when pipelines complete
    create_status_directory()

    Channel.of('done').set{ bam2fastq_modification_complete }

    // If BAM input and performing realignment, call convert_BAM2FASTQ
    if ( params.input_type == 'BAM' ) {
        if ( !params.override_realignment ) {
            convert_BAM2FASTQ()

            bam2fastq_modification_complete.mix(convert_BAM2FASTQ.out.bam2fastq_sample_data_updated)
                .collect()
                .map{ 'done' }
                .set{ bam2fastq_modification_complete }
        }
    }

    bam2fastq_modification_complete
        .map{ mark_pipeline_complete('convert-BAM2FASTQ'); return 'done' }
        .set{ align_dna_modification_signal }

    align_DNA(align_dna_modification_signal)

    recalibrate_BAM(align_DNA.out.alignment_sample_data_updated)

    if (params.calculate_targeted_coverage.is_pipeline_enabled) {
        calculate_targeted_coverage(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    if (params.call_gSNP.is_pipeline_enabled) {
        call_gSNP(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    if (params.call_sSNV.is_pipeline_enabled) {
        call_sSNV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    if (params.call_mtSNV.is_pipeline_enabled) {
        call_mtSNV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    if (params.call_gSV.is_pipeline_enabled) {
        call_gSV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    if (params.call_sSV.is_pipeline_enabled) {
        call_sSV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    if (params.call_sCNA.is_pipeline_enabled) {
        call_sCNA(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }
}
