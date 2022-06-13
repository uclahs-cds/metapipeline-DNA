/*
* Create input CSV file for align-DNA  for fastq entry
*
* Input:
*   A tuple of five objects.
*     @param patient (val): the patient ID
*     @records (tuple[tuple[str|file]]): A 2D tuple, that each child tuple contains the state, site,
*       and required inputs for align-DNA.
*
* Output:
*   A tuple of five objects.
*     @return patient (val): the patient ID
*     @return sample (val): the sample ID
*     @return state (val): tumor or normal
*     @return site (val): the sample site
*     @return input_csv (file): the input CSV file generated to be passed to align-DNA
*/
process create_csv_for_align_DNA {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}/${sample}/log${file(it).getName()}" }

    publishDir path: "${params.output_dir}/intermediate/${task.process}/${sample}",
        enabled: params.save_intermediate_files,
        mode: "copy",
        pattern: "*.csv"

    input:
        tuple(
            val(sample),
            val(records)
        )

    output:
        tuple(
            val(params.patient),
            val(sample),
            val(state),
            val(site),
            path(input_csv)
        )
        path(".command.*")

    script:
    input_csv = "${sample}_align_DNA_input.csv"
    lines = []
    state = records[0][0]
    site = records[0][1]
    for (record in records) {
        lines.add(record[2..-1].join(','))
    }
    lines = lines.join('\n')
    """
    echo "index,read_group_identifier,sequencing_center,library_identifier,platform_technology,platform_unit,sample,lane,read1_fastq,read2_fastq" > ${input_csv}
    echo '${lines}' >> ${input_csv}
    """
}
