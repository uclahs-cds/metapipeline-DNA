include { identify_file } from '../common'
include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

workflow identify_generate_sqc_bam_outputs {
    take:
    och_generate_sqc_bam

    main:
    och_generate_sqc_bam.map{ generate_sqc_bam_out ->

        // Every sample is expected to have an output so search for all samples
        def samples_to_search = [:];
        params.sample_data.each { sample, sample_data ->
            samples_to_search[sample] = sanitize_string(sample);
        }

        def sqc_bam_output_dir = new File(generate_sqc_bam_out[1].toString());
        def sqc_bam_output_pattern = /(.*)-([\d\.]*)$/;

        def output_info = [
            'Qualimap': ['Qualimap', { sample_id -> "Qualimap-*${sample_id}_stats/genome_results.txt" }]
        ]

        def outputs_to_check = [];
        def match = null;

        sqc_bam_output_dir.eachFile { file ->
            match = (file.name =~ sqc_bam_output_pattern);
            if (match) {
                outputs_to_check << [match[0][1], file.name];
            }
        }

        outputs_to_check.each { output_tool, output_dir_name ->
            samples_to_search.each { sample_key, sample_sanitized ->
                params.sample_data[sample_key]['generate-SQC-BAM'][output_info[output_tool][0]] = identify_file("${sqc_bam_output_dir}/${output_dir_name}/output/${output_info[output_tool][1](sample_sanitized)}");
            }
        }

        System.out.println(params.sample_data);
        return 'done';
    }
    .collect()
    .map{ 'done' }
    .set{ och_generate_sqc_bam_identified }

    emit:
    och_generate_sqc_bam_identified = och_generate_sqc_bam_identified
}
