/**
*   Nextflow module for calling the StableLift pipeline
*/

include { combine_input_with_params; generate_weblog_args; generate_graceful_error_controller } from '../common.nf'

/**
*   Process to call the StableLift pipeline
*
*   Input:
*       @param sample_id_for_stablelift (String): Sample ID
*       @param input_yaml (path): Path to the input YAML containing inputs
*/

process run_StableLift {
    cpus params.StableLift.subworkflow_cpus

    label 'graceful_failure'

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "pipeline-StableLift-*/*"

    publishDir "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_stablelift}/log${file(it).getName()}" }

    input:
        tuple(
            val(sample_id_for_stablelift),
            path(input_yaml)
        )

    output:
        path "pipeline-StableLift-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params.StableLift.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    Map all_models = params["StableLift"].stablelift_models
    String run_model = all_models[params.["StableLift"].liftover_direction][sample_info.tool]
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_stablelift_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-StableLift/main.nf \
        -params-file combined_stablelift_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        --rf_model "${run_model}" \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
