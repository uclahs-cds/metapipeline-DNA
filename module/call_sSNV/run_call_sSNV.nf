/*
* Nextflow module for calling the call-sSNV pipeline
*/

include { generate_args } from "${moduleDir}/../common"

/*
* Process to call the call-sSNV pipeline
*
* Input:
*   @param sample_id (String): Sample ID
*   @param algorithms (String): Comma-separated list of algorithms
*   @param input_yaml (path): Path to YAML containing inputs
*/
process run_call_sSNV {
    cpus params.call_sSNV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sSNV-*/*"

    input:
        tuple(
            val(sample_id),
            val(algorithms),
            path(input_yaml)
        )

    output:
        path "call-sSNV-*/*"

    script:
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" | \
        sed "s:<CALL-REGION-METAPIPELINE>:${params.call_sSNV.call_region}:g" | \
        sed "s:<GNOMAD-VCF-METAPIPELNE>:${params.call_sSNV.germline_resource_gnomad_vcf}:g" \
        > call_ssnv_default_metapipeline.config

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSNV/main.nf \
        ${params.call_sSNV.metapipeline_arg_string} \
        --work_dir ${params.work_dir} \
        -params-file ${input_yaml} \
        --algorithm_str ${algorithms} \
        --dataset_id ${params.project_id} \
        -c call_ssnv_default_metapipeline.config
    """
}
