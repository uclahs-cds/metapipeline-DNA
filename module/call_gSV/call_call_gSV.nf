/*
* Nextflow module for calling the call-gSV pipeline
*/

include { generate_args } from "${moduleDir}/../common"

/*
* Process to call the call-gSV pipeline
*
* Input:
*   @param input_csv (path): Path to the CSV containing inputs
*/
process call_call_gSV {
    cpus params.call_gSV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-gSV-*/*"

    input:
        path(input_csv)

    output:
        path "call-gSV-*/*"

    script:
    arg_list = [
        'reference_fasta',
        'exclusion_file',
        'mappability_map',
        'run_discovery',
        'run_regenotyping',
        'run_delly',
        'run_manta',
        'run_qc',
        'map_qual'
    ]
    args = generate_args(params.call_gSV, arg_list)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_gsv_default_metapipeline.config

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSV/main.nf \
        --work_dir ${params.work_dir} \
        --input_csv ${input_csv} \
        --dataset_id ${params.project_id} \
        ${args} \
        -c call_gsv_default_metapipeline.config
    """
}
