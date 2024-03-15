include { combine_input_with_params } from '../common.nf'

process run_call_mtSNV {
    cpus params.call_mtSNV.subworkflow_cpus

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
        path "call-mtSNV-*/*"
        path ".command.*"
        val('done'), emit: complete

    script:
    String params_to_dump = combine_input_with_params(params.call_mtSNV.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_call_mtsnv_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        -params-file combined_call_mtsnv_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --patient_id ${params.patient} \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config
    """
}
