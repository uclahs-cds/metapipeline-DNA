/*
* Nextflow module for calling the call-sSNV pipeline
*/

include { combine_input_with_params } from '../common.nf'

/*
* Process to call the call-sSNV pipeline
*
* Input:
*   @param sample_id (String): Sample ID
*   @param algorithms (String): Comma-separated list of algorithms
*   @param input_yaml (path): Path to YAML containing inputs
*/
process run_call_sSNV {
    cpus params.call_sSNV.subworkflow_cpus

    maxForks 1

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sSNV-*/*"

    input:
        tuple(
            val(sample_id),
            val(algorithms),
            path(input_yaml)
        )

    output:
        path "call-sSNV-*/*"
        path ".command.*"
        val('done'), emit: complete

    script:
    def algorithm_list = (algorithms in List) ? algorithms : [algorithms]
    String params_to_dump = combine_input_with_params(params.call_sSNV.metapipeline_arg_map + ['algorithm': algorithm_list], new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_ssnv_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSNV/main.nf \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        -params-file combined_call_ssnv_params.yaml \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config
    """
}
