/*
* Create input CSV file for align-DNA  for fastq entry
*
* Input:
*   A tuple of two objects.
*     @param patient (val): the patient ID
*     @records (tuple[tuple[str|file]]): A 2D tuple, that each child tuple contains the state,
*       and required inputs for align-DNA.
*
* Output:
*   A tuple of five objects.
*     @return patient (val): the patient ID
*     @return sample (val): the sample ID
*     @return state (val): tumor or normal
*     @return input_csv (file): the input CSV file generated to be passed to align-DNA
*/
process create_CSV_align_DNA {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${params.patient}/${sample}/log${file(it).getName()}" }

    publishDir path: "${params.output_dir}/intermediate/${task.process}-${params.patient}/${sample}",
        mode: "copy",
        pattern: "*.csv"

    input:
        tuple(
            val(sample),
            val(records)
        )

    output:
        tuple val(params.patient), val(sample), val(state), path(input_csv), emit: align_dna_csv
        path(".command.*")

    script:
    input_csv = "${sample}_align_DNA_input.csv"
    lines = []
    state = records[0][0]
    for (record in records) {
        lines.add(record[1..-1].join(','))
    }
    lines = lines.join('\n')
    """
    echo "read_group_identifier,sequencing_center,library_identifier,platform_technology,platform_unit,sample,lane,read1_fastq,read2_fastq" > ${input_csv}
    echo '${lines}' >> ${input_csv}
    """
}
