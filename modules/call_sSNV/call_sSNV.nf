/*
* Nextflow module for calling the call-sSNV pipeline
*/

include { generate_args } from "${moduleDir}/../common"

/*
* Process to callthe call-sSNV pipeline
*
* Input:
*   @param patient (String): Patient ID
*   @param tumor_sample (String): Sample ID of the tumor sample.
*   @parma normal_sample (String): Sample ID of the nomral sample.
*   @param tumor_site (Sting): The site of the tumor sample (e.g., primary tumor, blood, or
*       adjacent normal)
*   @param normal_site (Sting): The site of the normal sample (e.g., primary tumor, blood, or
*       adjacent normal)
*   @param tumor_bam (file): Tumor's calibrated BAM file output by the call-gSNP pipeline.
*   @param normal_bam (file): Normal's calibrated BAM file output by the call-gSNP pipeline.
*
* Output:
*/
process call_sSNV {
    cpus params.call_sSNV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sSNV-*/*"

    input:
        tuple(
            val(patient),
            val(tumor_sample),
            val(normal_sample),
            val(tumor_site),
            val(normal_site),
            file(tumor_bam),
            file(normal_bam)
        )

    output:
        path "call-sSNV-*/*"

    script:
    arg_list = [
        'reference',
        'exon',
        'split_intervals_extra_args',
        'mutect2_extra_args',
        'filter_mutect_calls_extra_args',
        'gatk_command_mem_diff',
        'scatter_count',
        'intervals',
        'bam_somaticsniper_cpus',
        'bam_somaticsniper_memory_GB',
        'samtools_pileup_cpus',
        'samtools_pileup_memory_GB',
        'samtools_varfilter_cpus',
        'samtools_varfilter_memory_GB',
        'manta_cpus',
        'strelka2_somatic_cpus',
        'm2_cpus',
        'm2_memory_GB',
        'm2_non_canonical_cpus',
        'm2_non_canonical_memory_GB'
    ]
    args = generate_args(params.call_sSNV, arg_list)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_ssnv_default_metapipeline.config

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSNV/pipeline/call-sSNV.nf \
        --temp_dir ${params.temp_dir} \
        --sample_name ${patient} \
        --tumor ${tumor_bam.toRealPath().toString()} \
        --normal ${normal_bam.toRealPath().toString()} \
        --algorithm_str ${params.call_sSNV.algorithm.join(',')} \
        ${args} \
        -c call_ssnv_default_metapipeline.config
    """
}
