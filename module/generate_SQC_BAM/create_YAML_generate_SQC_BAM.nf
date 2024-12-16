import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the generate-SQC-BAM pipeline.
*
* Input:
*   sample_info: A Map object containing sample information split into normal and tumor
*
* Output:
*   @return Path to input_yaml
*/
process create_YAML_generate_SQC_BAM {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${patient_id}",
        pattern: 'generate_SQC_BAM_input.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(patient_id), path(input_yaml)

    exec:
    input_yaml = 'generate_SQC_BAM_input.yaml'

    sample_states = ['normal': [], 'tumor': []]
    sample_info.each { state, samples ->
        samples.each{ sample ->
            sample_states[state].add(sample.sample)

        }
    }

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
                    ("${single_sample_type}" as String) : sample_info[single_sample_type].collect{ ['path': ("${it['bam']}" as String)] }
                ]
            ]
        ]
    } else {
        input_map = [
            'patient_id': patient_id,
            'input': [
                'BAM': [
                    'normal': sample_info.normal.collect{ ['path': ("${it['bam']}" as String)] },
                    'tumor': sample_info.tumor.collect{ ['path': ("${it['bam']}" as String)] }
                ]
            ]
        ]
    }
    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
