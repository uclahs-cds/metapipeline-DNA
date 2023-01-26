
include { generate_args } from "${moduleDir}/../common"

/*
* Call the call-gSNP pipeline
*
* Input:
*   A tuple that contains 6 items:
*     @param patient (String): Patient ID
*     @param tumor_sample (String): Sample ID of the tumor sample.
*     @param normal_sample (String): Sample ID of the normal sample.
*     @param input_csv (file): The input CSV file for call-gSNP pipeline.
*
* Output:
*   @return A tuple of 7 items, the input values of patient, tumor_sample, normal_sample,
*     normal_sample, as well as the output tumor and normal BAM files.
*/
process call_call_gSNP {
    cpus params.call_gSNP.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-gSNP-*/*"


    input:
        tuple(
            val(patient), val(run_mode), val(sample_id_for_gsnp),
            val(tumor_sample), val(normal_sample),
            val(normal_bam_sm), path(input_csv)
        )

    output:
        tuple val(patient), val(run_mode), val(tumor_sample), val(normal_sample), path("*.bam"), path(normal_bam), emit: full_output
        path("*.bam"), emit: tumor_bam
        file "call-gSNP-*/*"

    script:
    normal_bam = "call-gSNP-*/${sample_id_for_gsnp}/GATK-*/output/${normal_bam_sm}_realigned_recalibrated_merged_dedup.bam"
    arg_list = [
        'bundle_mills_and_1000g_gold_standard_indels_vcf_gz',
        'bundle_known_indels_vcf_gz',
        'bundle_v0_dbsnp138_vcf_gz',
        'bundle_hapmap_3p3_vcf_gz',
        'bundle_omni_1000g_2p5_vcf_gz',
        'bundle_phase1_1000g_snps_high_conf_vcf_gz',
        'bundle_contest_hapmap_3p3_vcf_gz',
        'intervals',
        'scatter_count',
        'gatk_ir_compression'
    ]
    args = generate_args(params.call_gSNP, arg_list)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_gsnp_default_metapipeline.config

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSNP/main.nf \
        --input_csv ${input_csv.toRealPath()} \
        --work_dir ${params.work_dir} \
        ${args} \
        -c call_gsnp_default_metapipeline.config

    if ${params.sample_mode == 'single'}
    then
        touch NO_FILE.bam
    else
        for i in `ls --hide=${normal_bam_sm}_realigned_recalibrated_merged_dedup.bam call-gSNP-*/${sample_id_for_gsnp}/GATK-*/output/ -1 | grep ".bam\$"`
        do
            full_path=`find \$(pwd) -name \$i`
            ln -s \$full_path \$i
        done
    fi
    """
}
