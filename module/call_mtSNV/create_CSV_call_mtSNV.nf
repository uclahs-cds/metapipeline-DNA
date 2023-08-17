/*
* Module for creating input CSV file for call-mtSNV pipeline
*/

process create_CSV_call_mtSNV {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${mtsnv_sample_id}",
        enabled: params.save_intermediate_files,
        pattern: 'call_mtSNV_input.csv',
        mode: 'copy'
    
    input:
        tuple(
            val(tumour_id),
            val(normal_id),
            path(tumour_BAM),
            path(normal_BAM)
        )

    output:
        tuple(
            val(tumour_id),
            val(normal_id),
            path(tumour_BAM),
            path(normal_BAM),
            path(input_csv)
        )

    script:
    input_csv = 'call_mtSNV_input.csv'
    if (params.sample_mode == 'single') {
        mtsnv_sample_id = normal_id
    } else {
        mtsnv_sample_id = tumour_id
    }
    """
    if ${params.sample_mode == 'single'}
    then
        rm NO_FILE.bam && touch NO_FILE.bam
        echo 'project_id,sample_id,normal_id,normal_BAM' > ${input_csv}
        echo "project_placeholder,${mtsnv_sample_id},${normal_id},${normal_BAM.toRealPath()}" >> ${input_csv}
    else
        echo 'project_id,sample_id,tumour_id,tumour_BAM,normal_id,normal_BAM' > ${input_csv}
        echo "project_placeholder,${mtsnv_sample_id},${tumour_id},${tumour_BAM.toRealPath()},${normal_id},${normal_BAM.toRealPath()}" >> ${input_csv}
    fi
    """
}
