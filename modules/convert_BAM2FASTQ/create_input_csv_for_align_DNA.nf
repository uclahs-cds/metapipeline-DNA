/*
    Create input csv file for the align-DNA pipeline.
*/
process create_input_csv_for_align_DNA {
    container "quay.io/biocontainers/pysam:0.16.0.1--py38hf7546f9_3"

    containerOptions "-v ${moduleDir}:${moduleDir}"

    publishDir "${params.output_dir}/${sample}/intermediates/${task.process.replace(':', '/')}",
        mode: 'copy',
        enabled: params.save_intermediate_files,
        pattern: 'align_DNA_input.csv'

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            file(read_group_csv),
            file(fastqs)
        )
    
    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            file(csv_file)
        )
    
    script:
    csv_file = 'align_DNA_input.csv'
    """
    python ${moduleDir}/create_input_csv_for_align_DNA.py \
        -r ${read_group_csv} \
        -q ${fastqs} \
        -o ${csv_file}
    """
}