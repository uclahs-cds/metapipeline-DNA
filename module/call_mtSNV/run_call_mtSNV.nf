include { combine_input_with_params; generate_graceful_error_controller; generate_weblog_args } from '../common.nf'

process run_call_mtSNV {
    cpus params.call_mtSNV.subworkflow_cpus

    label 'graceful_failure'

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${mtsnv_sample_id}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-mtSNV-*/*"
    
    input:
        tuple(
            val(mtsnv_sample_id),
            path(input_yaml)
        )

    output:
        path "call-mtSNV-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params.call_mtSNV.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_mtsnv_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        -params-file combined_call_mtsnv_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --patient_id ${params.patient} \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
