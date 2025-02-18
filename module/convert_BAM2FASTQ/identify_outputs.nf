include { identify_file } from '../common'
include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

workflow identify_convert_bam2fastq_outputs {
    take:
    och_convert_BAM2FASTQ

    main:
    och_convert_BAM2FASTQ.map{ bam2fastq_out ->
        new File(bam2fastq_out[3].toRealPath().toString()).eachLine{ line, line_num ->
            if (line_num == 1) { return; };
            def rg_info = line.split(",");
            params.sample_data[bam2fastq_out[1]]['convert-BAM2FASTQ'].add(
                [
                    'read_group_identifier': rg_info[0],
                    'sequencing_center': rg_info[1],
                    'library_identifier': rg_info[2],
                    'platform_technology': rg_info[3],
                    'platform_unit': rg_info[4],
                    'sample': rg_info[5],
                    'lane': rg_info[6],
                    'read1_fastq': identify_file("${bam2fastq_out[4]}/SAMtools-*${sanitize_string(rg_info[0])}*R1.fastq.gz"),
                    'read2_fastq': identify_file("${bam2fastq_out[4]}/SAMtools-*${sanitize_string(rg_info[0])}*R2.fastq.gz")
                ]
            );

            return
        };

        return 'done'
    }
    .collect()
    .map{ 'done' }
    .set{ och_bam2fastq_outputs_identified }

    emit:
    och_bam2fastq_outputs_identified = och_bam2fastq_outputs_identified
}
