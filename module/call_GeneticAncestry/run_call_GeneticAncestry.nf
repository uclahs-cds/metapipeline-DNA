/**
*   Nextflow module for calling the call-GeneticAncestry pipeline
*/

include { combine_input_with_params; generate_weblog_args; generate_graceful_error_controller } from '../common.nf'

/**
*   Process to call the call-GeneticAncestry pipeline
*
*   Input:
*       @param sample_id_for_call_geneticancestry (String): Sample ID
*       @param input_yaml (path): Path to the input YAML containing inputs
*/

process run_call_GeneticAncestry {
    cpus params.call_GeneticAncestry.subworkflow_cpus

    label 'graceful_failure'

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "pipeline-call-genetic-ancestry-*/*"

    publishDir "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_call_geneticancestry}/log${file(it).getName()}" }

    input:
        tuple(
            val(sample_id_for_call_geneticancestry),
            path(input_yaml),
            val(tool)
        )

    output:
        path "pipeline-call-genetic-ancestry-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params["call_GeneticAncestry"].metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_geneticancestry_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-GeneticAncestry/main.nf \
        -params-file combined_call_geneticancestry_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        --global_output_prefix ${sample_id_for_call_geneticancestry.replace(' ', '-')} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
