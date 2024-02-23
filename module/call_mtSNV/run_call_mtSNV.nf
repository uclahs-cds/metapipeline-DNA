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
            val(tumor_sample),
            val(normal_sample),
            path(tumor_bam),
            path(normal_bam),
            path(input_csv)
        )

    output:
        path "call-mtSNV-*/*"
        val('done'), emit: complete

    script:
    sample_mode = (params.sample_mode == 'single') ? 'single' : 'paired'
    if (sample_mode == 'single') {
        mtsnv_sample_id = normal_sample
    } else {
        mtsnv_sample_id = tumor_sample
    }
    String params_to_dump = combine_input_with_params(params.call_mtSNV.metapipeline_arg_map)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" | \
        sed "s:<SAMPLE-MODE-METAPIPELINE>:${sample_mode}:g" \
        > call_mtsnv_default_metapipeline.config

    printf "${params_to_dump}" > combined_call_mtsnv_params.yaml

    nextflow -C call_mtsnv_default_metapipeline.config \
        run ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        -params-file combined_call_mtsnv_params.yaml \
        --run_name ${tumor_sample} \
        --input_csv ${input_csv} \
        --work_dir ${params.work_dir} \
        --patient_id ${params.patient} \
        --dataset_id ${params.project_id}
    """
}
