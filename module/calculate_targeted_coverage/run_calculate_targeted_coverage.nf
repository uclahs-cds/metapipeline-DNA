include { combine_input_with_params; generate_graceful_error_controller; generate_weblog_args } from '../common.nf'
/*
* Call the calculate-targeted-coverage pipeline
*
* Input:
*   A tuple that contains 2 items:
      @param sample_id_for_targeted_coverage (String): Sample ID.
*     @param input_yaml (file): The input YAML file for calculate_targeted_coverage pipeline.
*/
process run_calculate_targeted_coverage {
    cpus params.calculate_targeted_coverage.subworkflow_cpus

    label 'graceful_failure'

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_targeted_coverage}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "calculate-targeted-coverage-*/*"


    input:
        tuple(
            val(sample_id_for_targeted_coverage),
            path(input_yaml)
        )

    output:
        tuple val(sample_id_for_targeted_coverage), path(output_directory), emit: identify_targeted_coverage_out, optional: true
        path "calculate-targeted-coverage-*/*", optional: true
        path ".command.*"
        env EXIT_CODE, emit: exit_code

    script:
    output_directory = "calculate-targeted-coverage-*/${sample_id_for_targeted_coverage}/SAMtools-*/output"
    String params_to_dump = combine_input_with_params(params.calculate_targeted_coverage.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    // If expanded intervals are requested for downstream use, disable the graceful failure mechanism
    task.ext.fail_gracefully = params.use_original_intervals
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    WORK_DIR=${params.work_dir}/work-calculate-targeted-coverage-${sample_id_for_targeted_coverage}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR

    printf "${params_to_dump}" > combined_calculate_targeted_coverage_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-calculate-targeted-coverage/main.nf \
        -params-file combined_calculate_targeted_coverage_params.yaml \
        --work_dir \$WORK_DIR \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL

    rm -r \$WORK_DIR
    """
}
