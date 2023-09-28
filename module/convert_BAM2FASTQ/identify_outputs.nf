include { identify_file } from '../common'

workflow identify_convert_bam2fastq_outputs {
    take:
    och_convert_BAM2FASTQ

    main:
    och_convert_BAM2FASTQ.view().map{ it ->
        new File(it[3].toRealPath().toString()).eachLine{ line, line_num ->
            if (line_num == 1) { return; };
            def rg_info = line.split(",");
            params.sample_data[it[1]]['convert-BAM2FASTQ'].add(
                [
                    'read_group_identifier': rg_info[0],
                    'sequencing_center': rg_info[1],
                    'library_identifier': rg_info[2],
                    'platform_techology': rg_info[3],
                    'platform_unit': rg_info[4],
                    'sample': rg_info[5],
                    'lane': rg_info[6],
                    'read1_fastq': identify_file("${it[4]}/${rg_info[0]}_collated_R1.fq.gz" as String),
                    'read2_fastq': identify_file("${it[4]}/${rg_info[0]}_collated_R2.fq.gz" as String)
                ]
            );

            return
        };

        return 'done'
    }
    .collect()
    .map{ 'done' }
    .set{ och_outputs_identified }

    emit:
    och_outputs_identified = och_outputs_identified
}
