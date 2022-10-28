
include { generate_args } from "${moduleDir}/../common"

process call_call_mtSNV {
    cpus params.call_mtSNV.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-mtSNV-*/*"
    
    input:
        tuple(
            val(patient),
            val(tumor_sample),
            val(normal_sample),
            file(tumor_bam),
            file(normal_bam),
            file(input_csv)
        )

    output:
        path "call-mtSNV-*/*"

    script:
    arg_list = [
        'mt_ref_genome_dir',
        'gmapdb'
    ]
    sample_mode = (params.sample_mode == 'single') ? 'single' : 'paired'
    args = generate_args(params.call_mtSNV, arg_list)
    """
    set -euo pipefail

    cat ${moduleDir}/default.config | \
        sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" | \
        sed "s:<SAMPLE-MODE-METAPIPELINE>:${sample_mode}:g" \
        > call_mtsnv_default_metapipeline.config

    nextflow -C call_mtsnv_default_metapipeline.config \
        run ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        --run_name ${tumor_sample} \
        --input_csv ${input_csv} \
        --work_dir ${params.work_dir} \
        --patient_id ${params.patient} \
        --dataset_id ${params.project_id} \
        ${args}
    """
}
