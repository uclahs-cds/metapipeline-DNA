include { identify_file } from '../common'
include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

workflow identify_call_gsv_outputs {
    take:
    och_call_gsv

    main:
    och_call_gsv.map{ call_gsv_out ->
        def raw_sample_id = call_gsv_out[0];
        def sample_id = sanitize_string(raw_sample_id);
        def gsv_output_dir = new File(call_gsv_out[1].toString());
        def gsv_output_pattern = /(.*)-([\d\.]*)$/;

        def output_into = [
            'Manta': ['Manta-gSV', "Manta-*${sample_id}*candidateSV.vcf.gz"],
            'DELLY': ['Delly-gSV', "DELLY-*${sample_id}*gSV.bcf"]
        ]

        def outputs_to_check = [];
        def match = null;

        gsv_output_dir.eachFile { file ->
            match = (file.name =~ gsv_output_pattern);
            if (match) {
                outputs_to_check << [match[0][1], file.name];
            }
        }

        outputs_to_check.each { output_tool, output_dir_name ->
            params.sample_data[raw_sample_id]['call-gSV'][output_info[output_tool][0]] = identify_file("${gsv_output_dir}/${output_dir_name}/output/${output_info[output_tool][1]}");
        }

        return 'done';
    }
    .collect()
    .map{ 'done' }
    .set{ och_call_gsv_identified }

    emit:
    och_call_gsv_identified = och_call_gsv_identified
}
