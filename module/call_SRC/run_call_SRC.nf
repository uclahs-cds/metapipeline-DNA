/**
*   Nextflow module for calling the call-SRC pipeline
*/

include { combine_input_with_params; generate_graceful_error_controller } from '../common.nf'

/**
*   Process to call the call-SRC pipeline
*
*   Input:
*       @param sample_id_for_call_src (String): Sample ID
*       @param input_yaml (path): Path to the input YAML containing inputs
*/

process run_call_SRC {
    cpus params.call_SRC.subworkflow_cpus

    label 'graceful_failure'

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-SRC-*/*"

    publishDir "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_call_src}/log${file(it).getName()}" }

    input:
        tuple(
            val(sample_id_for_call_src),
            path(input_yaml)
        )

    output:
        path "call-SRC-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params.call_SRC.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_src_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-SRC/main.nf \
        -params-file combined_call_src_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    capture_exit_code
    \$ENABLE_FAIL
    """
}
