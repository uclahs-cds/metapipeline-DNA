/*
* Nextflow module for calling the call-sSV pipeline
*/

include { combine_input_with_params } from '../common.nf'

/*
* Process to call the call-sSV pipeline
*
* Input:
*   @param input_yaml (path): Path to the YAML containing inputs
*/
process run_call_sSV {
    cpus params.call_sSV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sSV-*/*"

    input:
        path(input_yaml)

    output:
        path "call-sSV-*/*"

    script:
    String params_to_dump = combine_input_with_params(params.call_sSV.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_ssv_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSV/main.nf \
        -params-file combined_call_ssv_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config
    """
}
