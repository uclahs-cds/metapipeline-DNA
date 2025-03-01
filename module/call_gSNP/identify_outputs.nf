include { identify_file } from '../common'
include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

workflow identify_call_gsnp_outputs {
    take:
    och_call_gsnp

    main:
    och_call_gsnp.map{ call_gsnp_out ->
        def raw_sample_id = call_gsnp_out[0];
        def sample_id = sanitize_string(raw_sample_id);
        def gsnp_output_dir = new File(call_gsnp_out[1].toString());
        def gsnp_output_pattern = /(.*)-([\d\.]*)$/;

        def output_info = [
            'GATK': ['HaplotypeCaller', "GATK-*${sample_id}_snv.vcf.gz"]
        ]

        def outputs_to_check = [];
        def match = null;

        gsnp_output_dir.eachFile { file ->
            match = (file.name =~ gsnp_output_pattern);
            if (match) {
                outputs_to_check << [match[0][1], file.name];
            }
        }

        // If multi-mode, assign output to normal sample by default
        // In all other cases, use the raw_sample_id
        def id_to_assign = raw_sample_id;
        if (raw_sample_id == params.patient) {
            for (element in params.sample_data) {
                if (element.value['state'] == 'normal') {
                    id_to_assign = element.key;
                    break;
                }
            }
        }

        outputs_to_check.each { output_tool, output_dir_name ->
            params.sample_data[id_to_assign]['call-gSNP'][output_info[output_tool][0]] = identify_file("${gsnp_output_dir}/${output_dir_name}/output/${output_info[output_tool][1]}");
        }

        return 'done';
    }
    .collect()
    .map{ 'done' }
    .set{ och_call_gsnp_identified }

    emit:
    och_call_gsnp_identified = och_call_gsnp_identified
}
