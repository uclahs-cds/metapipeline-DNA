include { identify_file } from '../common'

workflow identify_recalibrate_bam_outputs {
    take:
    och_recalibrate_bam

    main:
    och_recalibrate_bam.map{ recalibrate_bam_out ->
        recalibrate_bam_out[0].normal.each { normal_sample ->
            if (!params.sample_data[normal_sample]['recalibrate-BAM']['BAM']) {
                params.sample_data[normal_sample]['recalibrate-BAM']['BAM'] = identify_file("${recalibrate_bam_out[1]}/*GATK-*${normal_sample}*.bam");
                params.sample_data[normal_sample]['recalibrate-BAM']['contamination_table'] = identify_file("${recalibrate_bam_out[2]}/GATK-*${normal_sample}_alone.table");
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
