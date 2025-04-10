
nextflow.enable.dsl = 2

include { convert_BAM2FASTQ } from "${moduleDir}/convert_BAM2FASTQ/workflow" addParams( this_pipeline: 'convert-BAM2FASTQ' )
include { align_DNA } from "${moduleDir}/align_DNA/workflow" addParams( this_pipeline: 'align-DNA' )
include { recalibrate_BAM } from "${moduleDir}/recalibrate_BAM/workflow" addParams( this_pipeline: 'recalibrate-BAM' )
include { calculate_targeted_coverage } from "${moduleDir}/calculate_targeted_coverage/workflow" addParams( this_pipeline: 'calculate-targeted-coverage' )
include { generate_SQC_BAM } from "${moduleDir}/generate_SQC_BAM/workflow" addParams( this_pipeline: 'generate-SQC-BAM' )
include { call_gSNP } from "${moduleDir}/call_gSNP/workflow" addParams( this_pipeline: 'call-gSNP' )
include { call_sSNV } from "${moduleDir}/call_sSNV/workflow" addParams( this_pipeline: 'call-sSNV' )
include { call_mtSNV } from "${moduleDir}/call_mtSNV/workflow" addParams( this_pipeline: 'call-mtSNV' )
include { call_gSV } from "${moduleDir}/call_gSV/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'call-gSV' )
include { call_sSV } from "${moduleDir}/call_sSV/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'call-sSV' )
include { call_sCNA } from "${moduleDir}/call_sCNA/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'call-sCNA' )
include { call_SRC } from "${moduleDir}/call_SRC/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'call-SRC')
include { stable_lift } from "${moduleDir}/StableLift/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'StableLift' )
include { annotate_VCF } from "${moduleDir}/annotate_VCF/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'annotate-VCF' )
include { call_GeneticAncestry } from "${moduleDir}/call_GeneticAncestry/workflow" addParams( log_output_dir: params.metapipeline_log_output_dir, this_pipeline: 'call-GeneticAncestry' )
include { create_directory; mark_pipeline_complete } from "${moduleDir}/pipeline_status"

workflow {
    // Create a status directory to track when pipelines complete
    create_directory(params.pipeline_status_directory)

    // Create a directory to track pipeline exit codes
    create_directory(params.pipeline_exit_status_directory)

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

    calculate_targeted_coverage(align_DNA.out.alignment_sample_data_updated)

    recalibrate_BAM(calculate_targeted_coverage.out.completion_signal)

    generate_SQC_BAM(recalibrate_BAM.out.recalibrate_sample_data_updated)

    if (params.call_mtSNV.is_pipeline_enabled) {
        call_mtSNV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    }

    call_gSNP(recalibrate_BAM.out.recalibrate_sample_data_updated)
    call_sSV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    call_gSV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    call_sSNV(recalibrate_BAM.out.recalibrate_sample_data_updated)
    call_sCNA(recalibrate_BAM.out.recalibrate_sample_data_updated)


    /**
    *   Call-SRC
    */
    call_sSNV.out.completion_signal.mix(call_sCNA.out.completion_signal)
        .collect()
        .map{ 'done' }
        .set{ src_ready }

    if (params.call_SRC.is_pipeline_enabled) {
        call_SRC(src_ready)
    }


    /**
    *   StableLift
    */
    call_sSNV.out.completion_signal
        .mix(call_gSV.out.completion_signal)
        .mix(call_sSV.out.completion_signal)
        .mix(call_gSNP.out.completion_signal)
        .collect()
        .map{ 'done' }
        .set{ stablelift_ready }

    if (params.StableLift.is_pipeline_enabled) {
        stable_lift(stablelift_ready)
    }

    /**
    *   Annotate-VCF
    */
    call_gSNP.out.completion_signal
        .collect()
        .map{ 'done' }
        .set{ annotate_vcf_ready }

    if (params.annotate_VCF.is_pipeline_enabled) {
        annotate_VCF(annotate_vcf_ready)
    }

    /**
    *   Call-GeneticAncestry
    */
    call_gSNP.out.completion_signal
        .collect()
        .map{ 'done' }
        .set{ call_geneticancestry_ready }

    if (params.call_GeneticAncestry.is_pipeline_enabled) {
        call_GeneticAncestry(call_geneticancestry_ready)
    }

    /**
    *   Calculate-mtDNA-CopyNumber
    */
    generate_SQC_BAM.out.completion_signal
        .collect()
        .map{ 'done' }
        .set{ calculate_mtdna_copynumber_ready }

    // if (params.calculate_mtDNA_CopyNumber.is_pipeline_enabled) {
    //     calculate_mtDNA_CopyNumber(calculate_mtdna_copynumber_ready)
    // }
}
