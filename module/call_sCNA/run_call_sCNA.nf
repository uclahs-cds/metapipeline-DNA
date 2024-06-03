/*
* Nextflow module for calling the call-sCNA pipeline
*/

include { combine_input_with_params; generate_graceful_error_controller; generate_weblog_args } from '../common.nf'

/*
* Process to call the call-sCNA pipeline
*
* Input:
*   @param input_yaml (path): Path to the YAML containing inputs
*/
process run_call_sCNA {
    cpus params.call_sCNA.subworkflow_cpus

    label 'graceful_failure'

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${task.index}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sCNA-*/*"

    input:
        tuple val(tumor_id), path(input_yaml)

    output:
        tuple val(tumor_id), path(output_directory), emit: identify_call_scna_out, optional: true
        path "call-sCNA-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    output_directory = "call-sCNA-*/${tumor_id}"
    String params_to_dump = combine_input_with_params(params.call_sCNA.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_scna_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sCNA/main.nf \
        -params-file combined_call_scna_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
