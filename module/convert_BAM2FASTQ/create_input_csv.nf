/*
    Create input csv file for the convert-BAM2FASTQ pipeline.
*/
process create_input_csv {

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            file(bam)
        )
    
    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            file(csv_file)
        )
    
    script:
    csv_file = 'input.csv'
    """
    echo 'sample_id,sample' > ${csv_file}
    echo "${sample},${bam.toRealPath()}" >> ${csv_file}
    """
}
