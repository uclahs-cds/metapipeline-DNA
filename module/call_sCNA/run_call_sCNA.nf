/*
* Nextflow module for calling the call-sCNA pipeline
*/

include { combine_input_with_params } from '../common.nf'

/*
* Process to call the call-sCNA pipeline
*
* Input:
*   @param input_yaml (path): Path to the YAML containing inputs
*/
process run_call_sCNA {
    cpus params.call_sCNA.subworkflow_cpus

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${task.id}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sCNA-*/*"

    input:
        path(input_yaml)

    output:
        path "call-sCNA-*/*"
        path ".command.*"
        val('done'), emit: complete

    script:
    String params_to_dump = combine_input_with_params(params.call_sCNA.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_scna_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sCNA/main.nf \
        -params-file combined_call_scna_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config
    """
}
