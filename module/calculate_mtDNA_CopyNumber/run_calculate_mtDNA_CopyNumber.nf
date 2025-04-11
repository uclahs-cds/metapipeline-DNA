/**
*   Nextflow module for calling the calculate-mtDNA-CopyNumber pipeline
*/

include { combine_input_with_params; generate_weblog_args; generate_graceful_error_controller } from '../common.nf'

/**
*   Process to call the calculate-mtDNA-CopyNumber pipeline
*
*   Input:
*       @param sample_id_for_calculate_mtdna_copynumber (String): Sample ID
*       @param input_yaml (path): Path to the input YAML containing inputs
*/

process run_calculate_mtDNA_CopyNumber {
    cpus params.calculate_mtDNA_CopyNumber.subworkflow_cpus

    label 'graceful_failure'

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "calculate-mtDNA-CopyNumber-*/*"

    publishDir "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_calculate_mtdna_copynumber}/log${file(it).getName()}" }

    input:
        tuple(
            val(sample_id_for_calculate_mtdna_copynumber),
            path(input_yaml),
            val(tool)
        )

    output:
        path "calculate-mtDNA-CopyNumber-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params["calculate_mtDNA_CopyNumber"].metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_calculate_mtdna_copynumber_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-calculate-mtDNA-CopyNumber/main.nf \
        -params-file combined_calculate_mtdna_copynumber_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
