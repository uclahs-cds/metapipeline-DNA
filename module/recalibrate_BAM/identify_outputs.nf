include { identify_file; delete_file } from '../common'

workflow identify_recalibrate_bam_outputs {
    take:
    och_recalibrate_bam

    main:
    och_recalibrate_bam.map{ recalibrate_bam_out ->
        recalibrate_bam_out[0].normal.each { normal_sample ->
            String bam_file = identify_file("${recalibrate_bam_out[1]}/*GATK-*${normal_sample}*.bam");
            if (!params.sample_data[normal_sample]['recalibrate-BAM']['BAM']) {
                params.sample_data[normal_sample]['recalibrate-BAM']['BAM'] = bam_file;
                params.sample_data[normal_sample]['recalibrate-BAM']['contamination_table'] = identify_file("${recalibrate_bam_out[2]}/GATK-*${normal_sample}_alone.table");
            } else {
                // Normal file already found so delete any other normals - only triggered when running multiple samples in paired mode
                String separator = "/recalibrate-BAM-";
                String dir_stripped = recalibrate_bam_out[1].toString().replaceFirst("${params.work_dir}.*${separator}", "");
                delete_file(bam_file, "${params.output_dir}/output${separator}${dir_stripped}/*GATK-*${normal_sample}*.bam");
            };
        };
        recalibrate_bam_out[0].tumor.each { tumor_sample ->
            String table_suffix = (params.sample_mode == 'single') ? 'alone' : 'with-matched-normal'
            params.sample_data[tumor_sample]['recalibrate-BAM']['BAM'] = identify_file("${recalibrate_bam_out[1]}/*GATK-*${tumor_sample}*.bam");
            params.sample_data[tumor_sample]['recalibrate-BAM']['contamination_table'] = identify_file("${recalibrate_bam_out[2]}/GATK-*${tumor_sample}_${table_suffix}.table");
        };

        return 'done'
    }
    .collect()
    .map{ 'done' }
    .set{ och_recalibrate_bam_identified }

    emit:
    och_recalibrate_bam_identified = och_recalibrate_bam_identified
}
