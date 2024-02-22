/*
* Create input CSV file for the call-gSV pipeline.
*
* Input:
*   A tuple of 3 items:
*     @param patient_id (String): Patient ID
*     @param sample_id (String): Sample ID of BAM
*     @param bam (path): Path to BAM
*
* Output:
*   @return A path to the input CSV
*/
process create_CSV_call_gSV {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}-${patient_id}/${sample_id}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${patient_id}/${sample_id}",
        pattern: 'call_gSV_input.csv',
        mode: 'copy'

    input:
        tuple(
            val(patient_id), val(sample_id), path(bam)
        )

    output:
        path(input_csv)

    script:
    input_csv = "call_gSV_input.csv"
    """
    echo 'patient,sample,input_bam' > ${input_csv}
    echo "${patient_id},${sample_id},${bam.toRealPath()}" >> ${input_csv}
    """
}
