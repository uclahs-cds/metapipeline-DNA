/*
* Nextflow module for calling the call-gSV pipeline
*/

include { combine_input_with_params } from '../common.nf'

/*
* Process to call the call-gSV pipeline
*
* Input:
*   @param input_csv (path): Path to the CSV containing inputs
*/
process run_call_gSV {
    cpus params.call_gSV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-gSV-*/*"

    input:
        path(input_csv)

    output:
        path "call-gSV-*/*"
        val('done'), emit: complete

    script:
    String params_to_dump = combine_input_with_params(params.call_gSV.metapipeline_arg_map)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_gsv_default_metapipeline.config

    printf "${params_to_dump}" > combined_call_gsv_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSV/main.nf \
        -params-file combined_call_gsv_params.yaml \
        --work_dir ${params.work_dir} \
        --input_csv ${input_csv} \
        --dataset_id ${params.project_id} \
        -c call_gsv_default_metapipeline.config
    """
}
