
include { generate_args } from "${moduleDir}/../common"

process call_call_mtSNV {
    cpus params.call_mtSNV.subworkflow_cpus

    publishDir "${params.output_dir}/output/${patient}/${tumor_sample}",
        mode: "copy",
        pattern: "call_mtSNV"
    
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
        file output_dir

    script:
    output_dir = 'call_mtSNV'
    arg_list = [
        'directory_containing_mt_ref_genome_chrRSRS_files',
        'gmapdb'
    ]
    args = generate_args(params.call_mtSNV, arg_list)
    """
    set -euo pipefail

    nextflow -C ${moduleDir}/default.config \
        run ${moduleDir}/../../external/pipeline-call-mtSNV/main.nf \
        --output_dir ${output_dir} \
        --run_name ${tumor_sample} \
        --input_csv ${input_csv} \
        --temp_dir ${params.work_dir} \
        ${args}

    cd ${output_dir}
    latest=\$(ls -1 | head -n 1)
    mv \${latest}/* ./
    rmdir \${latest}
    heteroplasmy_dir=call_heteroplasmy
    heteroplasmy_csv=\$(ls -1 \${heteroplasmy_dir} | head -n 1)
    mv \${heteroplasmy_dir}/\${heteroplasmy_csv} \${heteroplasmy_dir}/${tumor_sample}_vs_${normal_sample}.tsv
    """
}