
include { generate_args } from "${moduleDir}/../common"

/*
    Process to call the align-DNA pipeline.
*/
process call_align_DNA {
    cpus params.align_DNA.subworkflow_cpus

    publishDir "${params.output_dir}/${sample}/",
        mode: 'copy',
        pattern: 'align_DNA'

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            file(input_csv)
        )
    
    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            file(bam)
        )
        file output_dir
    
    script:
    output_dir = 'align_DNA'
    bam = "${output_dir}/BWA-MEM2-2.2.1/${sample}.bam"
    arg_list = [
        'reference_fasta_bwa',
        'reference_fasta_hisat2',
        'hisat2_index_prefix',
        'align_DNA_BWA_MEM2_cpus',
        'align_DNA_HISAT2_cpus',
        'run_SortSam_Picard_cpus',
        'run_SortSam_Picard_memory_GB',
        'run_MarkDuplicate_Picard_cpus',
        'run_MarkDuplicate_Picard_memory_GB',
        'run_BuildBamIndex_Picard_cpus',
        'run_BuildBamIndex_Picard_memory_GB'
    ]
    args = generate_args(params.align_DNA, arg_list)
    aligner = params.align_DNA.aligner.join(',')
    """
    mkdir ${output_dir}
    nextflow run \
        ${moduleDir}/../../external/pipeline-align-DNA/pipeline/align-DNA.nf \
        --sample_name ${sample} \
        --aligner ${aligner} \
        ${args} \
        --output_dir \$(pwd)/${output_dir} \
        --temp_dir \$(pwd)/work \
        --input_csv ${input_csv} \
        -c ${moduleDir}/default.config
    cd ${output_dir}
    latest=\$(ls -1 | head -n 1)
    mv \${latest}/* ./
    rmdir \${latest}
    """
}