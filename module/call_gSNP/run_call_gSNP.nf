include { combine_input_with_params } from '../common.nf'
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
        file "call-gSNP-*/*"
        file ".command.*"
        val('done'), emit: complete

    script:
    String params_to_dump = combine_input_with_params(params.call_gSNP.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    WORK_DIR=${params.work_dir}/work-call-gSNP-${sample_id_for_call_gsnp}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR

    printf "${params_to_dump}" > combined_call_gsnp_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSNP/main.nf \
        -params-file combined_call_gsnp_params.yaml \
        --work_dir \$WORK_DIR \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    rm -r \$WORK_DIR
    """
}
