import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the call-gSNP pipeline.
*
* Input:
*   sample_info: A Map object containing sample information split into normal and tumor
*
* Output:
*   @return A tuple of 2 items, inlcuding the patient_id and input_yaml
*/
process create_YAML_call_gSNP {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${patient_id}",
        pattern: 'call_gSNP_input.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(patient_id), path(input_yaml), emit: call_gsnp_input

    exec:
    input_yaml = 'call_gSNP_input.yaml'

    single_sample_type = 'none'
    if (sample_info.tumor.isEmpty()) {
        single_sample_type = 'normal'
    } else {
        single_sample_type = 'tumor'
    }

    patient_id = ''
    if (params.sample_mode == 'single') {
        assert sample_info[single_sample_type].sample.size() == 1
        patient_id = sample_info[single_sample_type].sample[0]
    } else if (params.sample_mode == 'paired') {
        assert sample_info.tumor.sample.size() == 1
        patient_id = sample_info.tumor.sample[0]
    } else {
        patient_id = params.patient
    }

    // params.patient maybe Integer if parsed from CLI.
    patient_id = patient_id as String

    if (params.sample_mode == 'single') {
        input_map = [
            'patient_id': patient_id,
            'input': [
                'BAM': [
                    ("${single_sample_type}" as String) : sample_info[single_sample_type].collect{ "${it['bam']}" as String }
                ]
            ]
        ]
    } else {
        input_map = [
            'patient_id': patient_id,
            'input': [
                'BAM': [
                    'normal': sample_info.normal.collect{ "${it['bam']}" as String },
                    'tumor': sample_info.tumor.collect{ "${it['bam']}" as String }
                ]
            ]
        ]
    }
    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
