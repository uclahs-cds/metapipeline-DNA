
/*
* This process takes the channel emitted by the align_DNA module, and create tumor normal paires.
* Only one normal sample is allowed. If multiple tumor samples are found (e.g., primary tumor &
* adjacent normal), each tumor sample is paired with the normal sample, and the call_gSNP pipeline
* is called separately.
*
* input:
*   A nested list or tuple, that each child is a list or tuple contains six elements:
*     @param patient (String): Patient ID
*     @param sample (String): Sample ID
*     @param state (String): Must be either normal or tumor.
*     @param bam_header_sm (String): The SM tag value in the BAM header.
*     @param bam (file): Path to the BAM file.
*
* Ouput:
*   @return A CSV file that each line has the information including patient, normal ID, normal BAM,
*     tumor ID, tumor BAM.
*/
process create_normal_tumor_pairs {
    container "python:3.8"

    containerOptions "-v ${moduleDir}:${moduleDir}"

    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}",
        enabled: params.save_intermediate_files,
        pattern: 'paried_input_csv.txt',
        mode: 'copy'
    
    input:
        val records
    
    output:
        file output_file

    script:
    output_file = 'paried_input_csv.txt'
    ich_file = 'ich.txt'
    lines = []
    for (record in records) {
        lines.add(record.join(','))
    }
    lines = lines.join('\n')
    """
    echo "patient,sample,state,bam_header_sm,bam" > ${ich_file}
    echo '${lines}' >> ${ich_file}
    python ${moduleDir}/create_normal_tumor_pairs.py ${ich_file} ${output_file}
    """
}

/*
* Create input CSV file for the call-gSNP pipeline.
*
* Input:
*   A tuple of sevel items:
*     @param patient (String): Patient ID
*     @param tumor_sample (String): Sample ID of the tumor sample.
*     @param normal_sample (String): Sample ID of the nomral sample.
*     @param tumor_bam (file): Path to the BAM file of tumor sample.
*     @param normal_bam (file): Path to the BAM file of normal sample.
*
* Output:
*   @return A tuple of 6 items, inlcuding the patient, tumor_sample, normal_sample of input, and the input CSV file created for the call-gSNP pipeline.
*/
process create_input_csv_call_gSNP {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${task.index}",
        enabled: params.save_intermediate_files,
        pattern: 'call_gSNP_input.csv',
        mode: 'copy'
    
    input:
        tuple(
            val(patient),
            val(tumor_sample), val(normal_sample),
            val(tumor_bam_sm), val(normal_bam_sm),
            val(tumor_bam),    val(normal_bam)
        )
    
    output:
        tuple(
            val(patient),
            val(tumor_sample), val(normal_sample),
            val(tumor_bam_sm), val(normal_bam_sm),
            file(input_csv)
        )
    script:
    input_csv = 'call_gSNP_input.csv'
    """
    echo 'project_id,sample_id,normal_id,normal_BAM,tumour_id,tumour_BAM' > ${input_csv}
    echo "${params.project_id},${patient},${normal_bam_sm},${normal_bam},${tumor_bam_sm},${tumor_bam}" >> ${input_csv}
    """
}