/*
* Module for creating input CSV file for call-mtSNV pipeline
*/

process create_input_csv {
    publishDir "${params.output_dir}/${patient}/${tumor_sample}/intermediate/call_mtSNV/${task.process.replace(':', '/')}",
        enabled: params.save_intermediate_files,
        pattern: 'call_mtSNV_input.csv',
        mode: 'copy'
    
    input:
        tuple(
            val(patient),
            val(tumor_sample),
            val(normal_sample),
            file(tumor_bam),
            file(normal_bam)
        )

    output:
        tuple(
            val(patient),
            val(tumor_sample),
            val(normal_sample),
            file(tumor_bam),
            file(normal_bam),
            file(input_csv)
        )

    script:
    input_csv = 'call_mtSNV_input.csv'
    """
    echo 'sample_input_1_type,sample_input_1_name,sample_input_1_path,sample_input_2_type,sample_input_2_name,sample_input_2_path' > ${input_csv}
    echo "normal,${normal_sample},${normal_bam.toRealPath()},tumor,${tumor_sample},${tumor_bam.toRealPath()}" >> ${input_csv}
    """
}