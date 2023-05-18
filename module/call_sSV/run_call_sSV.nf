/*
* Nextflow module for calling the call-sSV pipeline
*/

include { generate_args } from "${moduleDir}/../common"

/*
* Process to call the call-sSV pipeline
*
* Input:
*   @param input_csv (path): Path to the CSV containing inputs
*/
process run_call_sSV {
    cpus params.call_sSV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-sSV-*/*"

    input:
        tuple(
            path(input_csv),
            val(algorithms)
        )

    output:
        path "call-sSV-*/*"

    script:
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_ssv_default_metapipeline.config

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-sSV/main.nf \
        ${params.call_sSV.metapipeline_arg_string} \
        --work_dir ${params.work_dir} \
        --input_csv ${input_csv} \
        --dataset_id ${params.project_id} \
        --algorithm_str ${algorithms} \
        -c call_ssv_default_metapipeline.config
    """
}
