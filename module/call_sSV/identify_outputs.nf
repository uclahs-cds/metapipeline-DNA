include { identify_file } from '../common'
include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

workflow identify_call_ssv_outputs {
    take:
    och_call_ssv

    main:
    och_call_ssv.map{ call_ssv_out ->
        def raw_sample_id = call_ssv_out[0];
        def sample_id = sanitize_string(raw_sample_id);
        def ssv_output_dir = new File(call_ssv_out[1].toString());
        def ssv_output_pattern = /(.*)-([\d\.]*)$/;

        def output_info = [
            'Manta': ['Manta-sSV', "Manta-*${sample_id}*candidateSV.vcf.gz"],
            // 'DELLY': ['Delly2-sSV', "DELLY-*${sample_id}.vcf.gz"]
        ]

        def outputs_to_check = [];
        def match = null;

        ssv_output_dir.eachFile { file ->
            match = (file.name =~ ssv_output_pattern);
            if (match) {
                outputs_to_check << [match[0][1], file.name];
            }
        }

        outputs_to_check.each { output_tool, output_dir_name ->
            params.sample_data[raw_sample_id]['call-sSV'][output_info[output_tool][0]] = identify_file("${ssv_output_dir}/${output_dir_name}/output/${output_info[output_tool][1]}");
        }

        return 'done';
    }
    .collect()
    .map{ 'done' }
    .set{ och_call_ssv_identified }

    emit:
    och_call_ssv_identified = och_call_ssv_identified
}
