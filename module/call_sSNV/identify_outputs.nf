include { identify_file } from '../common'

workflow identify_call_ssnv_outputs {
    take:
    och_call_ssnv

    main:
    och_call_ssnv.map{ call_ssnv_out ->
        def sample_id = call_ssnv_out[0];
        def ssnv_output_dir = new File(call_ssnv_out[1].toString());
        def ssnv_output_pattern = /(.*)-([\d\.]*)$/;
        if (sample_id == params.patient) { // Output from multi-mode, skip
            return 'done';
        }

        def output_info = [
            'Mutect2': ['Mutect2', "Mutect2-*${sample_id}*SNV.vcf.gz"],
            'Strelka2': ['Strelka2', "Strelka2-*${sample_id}*SNV.vcf.gz"],
            'SomaticSniper': ['SomaticSniper', "SomaticSniper-*${sample_id}*SNV.vcf.gz"],
            'MuSE': ['MuSE', "MuSE-*${sample_id}*SNV.vcf.gz"],
            'Intersect-BCFtools': ['BCFtools-Intersect', "BCFtools-*${sample_id}*SNV-concat.vcf.gz"]
        ];

        def outputs_to_check = [];
        def match = null;

        ssnv_output_dir.eachFile { file ->
            match = (file.name =~ ssnv_output_pattern);
            if (match) {
                outputs_to_check << [match[0][1], file.name];
            }
        }

        outputs_to_check.each { output_tool, output_dir_name ->
            params.sample_data[sample_id]['call-sSNV'][output_info[output_tool][0]] = identify_file("${ssnv_output_dir}/${output_dir_name}/output/${output_info[output_tool][1]}");
        }

        return 'done';
    }
    .collect()
    .map{ 'done' }
    .set{ och_call_ssnv_identified }

    emit:
    och_call_ssnv_identified = och_call_ssnv_identified
}
