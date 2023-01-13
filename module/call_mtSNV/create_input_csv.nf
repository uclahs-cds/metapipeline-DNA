/*
* Module for creating input CSV file for call-mtSNV pipeline
*/

process create_input_csv {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${mtsnv_sample_id}",
        enabled: params.save_intermediate_files,
        pattern: 'call_mtSNV_input.csv',
        mode: 'copy'
    
    input:
        tuple(
            val(sample_id),
            val(run_mode),
            val(tumour_id),
            val(normal_id),
            path(tumour_BAM),
            path(normal_BAM)
        )

    output:
        tuple(
            val(sample_id),
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
    } else if (params.sample_mode == 'paired') {
        mtsnv_sample_id = tumour_id
    } else {
        mtsnv_sample_id = tumour_BAM.baseName.replace('_realigned_recalibrated_merged_dedup', '')
    }
    mtsnv_tumour_id = tumour_BAM.baseName.replace('_realigned_recalibrated_merged_dedup', '')
    """
    if ${params.sample_mode == 'single'}
    then
        rm NO_FILE.bam && touch NO_FILE.bam
        echo 'project_id,sample_id,normal_id,normal_BAM' > ${input_csv}
        echo "project_placeholder,${mtsnv_sample_id},${normal_id},${normal_BAM.toRealPath()}" >> ${input_csv}
    else
        echo 'project_id,sample_id,tumour_id,tumour_BAM,normal_id,normal_BAM' > ${input_csv}
        echo "project_placeholder,${mtsnv_sample_id},${mtsnv_tumour_id},${tumour_BAM.toRealPath()},${normal_id},${normal_BAM.toRealPath()}" >> ${input_csv}
    fi
    """
}
