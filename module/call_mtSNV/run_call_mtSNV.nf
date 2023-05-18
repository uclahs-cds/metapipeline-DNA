
include { generate_args } from "${moduleDir}/../common"

process run_call_mtSNV {
    cpus params.call_mtSNV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-mtSNV-*/*"
    
    input:
        tuple(
            val(patient),
            val(tumor_sample),
            val(normal_sample),
            path(tumor_bam),
            path(normal_bam),
            path(input_csv)
        )

    output:
        path "call-mtSNV-*/*"

    script:
    sample_mode = (params.sample_mode == 'single') ? 'single' : 'paired'
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" | \
        sed "s:<SAMPLE-MODE-METAPIPELINE>:${sample_mode}:g" \
        > call_mtsnv_default_metapipeline.config

    nextflow -C call_mtsnv_default_metapipeline.config \
        run ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        ${params.call_mtSNV.metapipeline_arg_string} \
        --run_name ${tumor_sample} \
        --input_csv ${input_csv} \
        --work_dir ${params.work_dir} \
        --patient_id ${params.patient} \
        --dataset_id ${params.project_id}
    """
}
