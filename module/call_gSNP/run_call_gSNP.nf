include { combine_input_with_params; generate_graceful_error_controller } from '../common.nf'
/*
* Call the call-gSNP pipeline
*
* Input:
*   A tuple that contains 4 items:
      @param sample_id_for_call_gsnp (String): Sample ID.
*     @param input_yaml (file): The input YAML file for call-gSNP pipeline.
*
* Output:
*   @return A Map...
*/
process run_call_gSNP {
    cpus params.call_gSNP.subworkflow_cpus

    label 'graceful_failure'

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_call_gsnp}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-gSNP-*/*"

    input:
        tuple(
            val(sample_id_for_call_gsnp),
            path(input_yaml)
        )

    output:
        path "call-gSNP-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params.call_gSNP.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    """
    set -euo pipefail

    WORK_DIR=${params.work_dir}/work-call-gSNP-${sample_id_for_call_gsnp}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR

    printf "${params_to_dump}" > combined_call_gsnp_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSNP/main.nf \
        -params-file combined_call_gsnp_params.yaml \
        --work_dir \$WORK_DIR \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    capture_code
    \$ENABLE_FAIL

    rm -r \$WORK_DIR
    """
}
