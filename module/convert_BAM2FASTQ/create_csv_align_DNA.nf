/*
    Create input csv file for the align-DNA pipeline.
*/
process create_csv_align_DNA {
    container "quay.io/biocontainers/pysam:0.16.0.1--py38hf7546f9_3"
    containerOptions "-v ${moduleDir}:${moduleDir}"

    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${patient}/${sample}",
        mode: 'copy',
        enabled: params.save_intermediate_files,
        pattern: 'align_DNA_input.csv'

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            path(read_group_csv),
            path(fastqs)
        )
    
    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            path(csv_file)
        )
    
    script:
    csv_file = 'align_DNA_input.csv'
    """
    python ${moduleDir}/create_csv_align_dna.py \
        -r ${read_group_csv} \
        -q ${fastqs} \
        -o ${csv_file}
    """
}