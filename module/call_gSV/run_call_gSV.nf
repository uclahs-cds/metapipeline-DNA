/*
* Nextflow module for calling the call-gSV pipeline
*/

include { combine_input_with_params; generate_graceful_error_controller } from '../common.nf'

/*
* Process to call the call-gSV pipeline
*
* Input:
*   @param input_csv (path): Path to the CSV containing inputs
*/
process run_call_gSV {
    cpus params.call_gSV.subworkflow_cpus

    label 'graceful_failure'

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${task.index}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-gSV-*/*"

    input:
        path(input_yaml)

    output:
        path "call-gSV-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params.call_gSV.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_gsv_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSV/main.nf \
        -params-file combined_call_gsv_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    capture_exit_code
    \$ENABLE_FAIL
    """
}
