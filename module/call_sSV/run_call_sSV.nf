/*
* Nextflow module for calling the call-sSV pipeline
*/

include { combine_input_with_params } from '../common.nf'

/*
* Process to call the call-sSV pipeline
*
* Input:
*   @param input_csv (path): Path to the CSV containing inputs
*/
process run_call_sSV {
    cpus params.call_sSV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sSV-*/*"

    input:
        path(input_csv)

    output:
        path "call-sSV-*/*"

    script:
    String params_to_dump = combine_input_with_params(params.call_sSV.metapipeline_arg_map)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_ssv_default_metapipeline.config

    printf "${params_to_dump}" > combined_call_ssv_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSV/main.nf \
        -params-file combined_call_ssv_params.yaml \
        --work_dir ${params.work_dir} \
        --input_csv ${input_csv} \
        --dataset_id ${params.project_id} \
        -c call_ssv_default_metapipeline.config
    """
}
