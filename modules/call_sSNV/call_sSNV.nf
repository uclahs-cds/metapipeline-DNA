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
            file(tumor_bam),
            file(normal_bam)
        )

    output:
        path "call-sSNV-*/*"

    script:
    arg_list = [
        'reference',
        'exome',
        'split_intervals_extra_args',
        'mutect2_extra_args',
        'filter_mutect_calls_extra_args',
        'gatk_command_mem_diff',
        'scatter_count',
        'intervals'
    ]
    args = generate_args(params.call_sSNV, arg_list)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" | \
        sed "s:<CALL-REGION-METAPIPELINE>:${params.call_sSNV.call_region}:g" | \
        sed "s:<GNOMAD-VCF-METAPIPELNE>:${params.call_sSNV.germline_resource_gnomad_vcf}:g" \
        > call_ssnv_default_metapipeline.config

    cat ${moduleDir}/base.yaml | \
        sed "s:<NORMAL_PATH>:${normal_bam.toRealPath().toString()}:g" | \
        sed "s:<TUMOR_PATH>:${tumor_bam.toRealPath().toString()}:g" \
        > call_ssnv_input.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSNV/main.nf \
        --work_dir ${params.work_dir} \
        --sample_id ${patient} \
        -params-file call_ssnv_input.yaml \
        --algorithm_str ${params.call_sSNV.algorithm.join(',')} \
        ${args} \
        -c call_ssnv_default_metapipeline.config
    """
}
