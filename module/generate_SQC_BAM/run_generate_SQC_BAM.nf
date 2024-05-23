include { combine_input_with_params; generate_graceful_error_controller; generate_weblog_args } from '../common.nf'
/*
* Call the generate-SQC-BAM pipeline
*
* Input:
*   input_yaml: The input YAML file
*/
process run_generate_SQC_BAM {
    cpus params.generate_SQC_BAM.subworkflow_cpus

    label 'graceful_failure'

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${resolved_id}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "generate-SQC-BAM-*/*"

    input:
        tuple val(resolved_id), path(input_yaml)

    output:
        path "generate-SQC-BAM-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params.generate_SQC_BAM.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_generate_sqc_bam_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-generate-SQC-BAM/main.nf \
        -params-file combined_generate_sqc_bam_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
