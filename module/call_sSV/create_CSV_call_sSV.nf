/*
* Create input CSV file for the call-sSV pipeline.
*
* Input:
*   A tuple of 3 items:
*     @param tumor_id (String): ID for tumor sample
*     @param normal_bam (path): Path to normal BAM
*     @param tumor_bam (path): Path to tumor BAM
*
* Output:
*   @return A path to the input CSV
*/
process create_CSV_call_sSV {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}-${tumor_id}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${tumor_id}",
        enabled: params.save_intermediate_files,
        pattern: 'call_sSV_input.csv',
        mode: 'copy'

    input:
        tuple(
            val(tumor_id), val(normal_bam), path(tumor_bam)
        )

    output:
        path(input_csv)

    script:
    input_csv = "call_sSV_input.csv"
    """
    echo 'normal_bam,tumor_bam' > ${input_csv}
    echo "${normal_bam.toRealPath()},${tumor_bam.toRealPath()}" >> ${input_csv}
    """
}
