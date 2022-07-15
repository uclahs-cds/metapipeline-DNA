
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
        'directory_containing_mt_ref_genome_chrRSRS_files',
        'gmapdb'
    ]
    args = generate_args(params.call_mtSNV, arg_list)
    """
    set -euo pipefail

    nextflow -C ${moduleDir}/default.config \
        run ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        --output_dir \$(pwd) \
        --run_name ${tumor_sample} \
        --input_csv ${input_csv} \
        --temp_dir ${params.work_dir} \
        --patient_id ${params.patient_id} \
        ${args}
    """
}
