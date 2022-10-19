/*
* Module for creating input CSV file for call-mtSNV pipeline
*/

process create_input_csv {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${mtsnv_tumour_id}",
        enabled: params.save_intermediate_files,
        pattern: 'call_mtSNV_input.csv',
        mode: 'copy'
    
    input:
        tuple(
            val(sample_id),
            val(tumour_id),
            val(normal_id),
            file(tumour_BAM),
            file(normal_BAM)
        )

    output:
        tuple(
            val(sample_id),
            val(tumour_id),
            val(normal_id),
            file(tumour_BAM),
            file(normal_BAM),
            file(input_csv)
        )

    script:
    input_csv = 'call_mtSNV_input.csv'
    mtsnv_sample_id = (params.sample_mode == 'multi') ?
        "${tumour_BAM.baseName.replace('_realigned_recalibrated_merged_dedup', '')}" :
        "${tumour_id}"
    mtsnv_tumour_id = "${tumour_BAM.baseName.replace('_realigned_recalibrated_merged_dedup', '')}"
    """
    echo 'project_id,sample_id,tumour_id,tumour_BAM,normal_id,normal_BAM' > ${input_csv}
    echo "project_placeholder,${mtsnv_sample_id},${mtsnv_tumour_id},${tumour_BAM.toRealPath()},${normal_id},${normal_BAM.toRealPath()}" >> ${input_csv}
    """
}
