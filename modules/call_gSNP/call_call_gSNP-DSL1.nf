
include { generate_args } from "${moduleDir}/../common"

/*
* Call the call-gSNP pipeline
*
* Input:
*   A tuple that contains 6 items:
*     @param patient (String): Patient ID
*     @param tumor_sample (String): Sample ID of the tumor sample.
*     @param normal_sample (String): Sample ID of the nomral sample.
*     @param tumor_site (Sting): The site of the tumor sample (e.g., primary tumor, blood, or
*       adjacent normal)
*     @param normal_site (Sting): The site of the normal sample (e.g., primary tumor, blood, or
*       adjacent normal)
*     @param input_csv (file): The input CSV file for call-gSNP pipeline.
*
* Output:
*   @return A tuple of 7 items, the input values of patient, tumor_sample, normal_sample,
*     normal_sample, tumor_site, normal_site, as well as the output tumor and normal BAM files.
*/
process call_call_gSNP {
    cpus params.call_gSNP.subworkflow_cpus

    publishDir "${params.output_dir}/${patient}/${tumor_sample}/",
        mode: 'copy',
        pattern: 'call_gSNP'

    input:
        tuple(
            val(patient),
            val(tumor_sample), val(normal_sample),
            val(tumor_site),   val(normal_site),
            val(tumor_bam_sm), val(normal_bam_sm),
            file(input_csv)
        )
    
    output:
        tuple(
            val(patient),
            val(tumor_sample), val(normal_sample),
            val(tumor_site),   val(normal_site),
            file(tumor_bam),   file(normal_bam)
        )
        file output_dir

    script:
    output_dir = 'call_gSNP'
    normal_bam = "${output_dir}/SAMtools-1.10_Picard-2.23.3/recalibrated_reheadered_bam_and_bai/${normal_bam_sm}_realigned_recalibrated_reheadered.bam"
    tumor_bam = "${output_dir}/SAMtools-1.10_Picard-2.23.3/recalibrated_reheadered_bam_and_bai/${tumor_bam_sm}_realigned_recalibrated_reheadered.bam"
    arg_list = [
        'java_temp_dir',
        'is_NT_paired',
        'input_all_chromosomes_group_small_contigs',
        'input_all_chromosomes_each_per_line',
        'reference_prefix',
        'bundle_mills_and_1000g_gold_standard_indels_vcf_gz',
        'bundle_known_indels_vcf_gz',
        'bundle_v0_dbsnp138_vcf_gz',
        'bundle_hapmap_3p3_vcf_gz',
        'bundle_omni_1000g_2p5_vcf_gz',
        'bundle_phase1_1000g_snps_high_conf_vcf_gz',
        'bundle_contest_hapmap_3p3_vcf_gz',
        'max_number_of_parallel_jobs'
    ]
    args = generate_args(params.call_gSNP, arg_list)
    """
    set -euo pipefail

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSNP-DSL1/call-gSNP.nf \
        --input_csv ${input_csv.toRealPath()} \
        --output_dir ${output_dir} \
        --temp_dir ${params.temp_dir} \
        ${args} \
        -c ${moduleDir}/default-DSL1.config

    cd ${output_dir}
    latest=\$(ls -1 | head -n 1)
    mv \${latest}/${patient}/* ./
    mv \${latest}/logs ./
    rm -rf \${latest}
    """
}