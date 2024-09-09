include { identify_file } from '../common'
include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

workflow identify_call_scna_outputs {
    take:
    och_call_scna

    main:
    och_call_scna.map{ call_scna_out ->
        def raw_sample_id = call_scna_out[0];
        def sample_id = sanitize_string(raw_sample_id);
        def scna_output_dir = new File(call_scna_out[1].toString());
        def scna_output_pattern = /(.*)-([\d\.]*)$/;

        def output_info = [
            'Battenberg': ['Battenberg', ["Battenberg-*${sample_id}*subclones.txt", "Battenberg-*${sample_id}*cellularity-ploidy.txt"]],
            'cnv_facets': ['FACETS', ["CNV-FACETS-*${sample_id}.vcf.gz"]]
        ];

        def outputs_to_check = [];
        def match = null;

        scna_output_dir.eachFile { file ->
            match = (file.name =~ scna_output_pattern);
            if (match) {
                outputs_to_check << [match[0][1], file.name];
            }
        }

        def current_files_to_find = [];
        def found_files = [];
        outputs_to_check.each { output_tool, output_dir_name ->
            current_files_to_find = output_info[output_tool][1];
            found_files = [];
            current_files_to_find.each { f ->
                found_files << identify_file("${scna_output_dir}/${output_dir_name}/output/${f}");
            }

            params.sample_data[raw_sample_id]['call-sCNA'][output_info[output_tool][0]] = found_files;
        }

        return 'done';
    }
    .collect()
    .map{ 'done' }
    .set{ och_call_scna_identified }

    emit:
    och_call_scna_identified = och_call_scna_identified
}
