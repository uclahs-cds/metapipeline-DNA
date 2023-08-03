/*
* Nextflow module for calling the call-sSNV pipeline
*/

include { combine_input_with_params } from '../common.nf'

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
    String params_to_dump = combine_input_with_params(params.call_sSNV.metapipeline_arg_map + ['algorithm': algorithms], new File(input_yaml))
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" | \
        sed "s:<CALL-REGION-METAPIPELINE>:${params.call_sSNV.call_region}:g" | \
        sed "s:<GNOMAD-VCF-METAPIPELNE>:${params.call_sSNV.germline_resource_gnomad_vcf}:g" \
        > call_ssnv_default_metapipeline.config

    printf "${params_to_dump}" > combined_call_ssnv_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSNV/main.nf \
        --work_dir ${params.work_dir} \
        -params-file combined_call_ssnv_params.yaml \
        --dataset_id ${params.project_id} \g
        -c call_ssnv_default_metapipeline.config
    """
}
