import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the recalibrate-BAM pipeline.
*
* Input:
*   sample_info: A Map object containing sample information split into normal and tumor
*
* Output:
*   @return A tuple of 4 items, inlcuding the states_to_delete, patient_id, sample_states, and input_yaml
*/
process create_YAML_recalibrate_BAM {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${patient_id}",
        enabled: true, //params.save_intermediate_files,
        pattern: 'recalibrate_BAM_input.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(states_to_delete), val(patient_id), val(sample_states), path(input_yaml), emit: recalibrate_bam_input

    exec:
    input_yaml = 'recalibrate_BAM_input.yaml'

    states_to_delete = (params.sample_mode == 'paired') ? sample_info.tumor.states_to_delete : ['normal', 'tumor']

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
    } else if (params.sample_mode == 'paired') {
        assert sample_info.tumor.sample.size() == 1
        patient_id = sample_info.tumor.sample[0]
    } else {
        patient_id = params.patient
    }

    if (params.sample_mode == 'single') {
        input_map = [
            'metapipeline_states_to_delete': states_to_delete,
            'patient_id': patient_id,
            'input': [
                'BAM': [
                    ("${single_sample_type}" as String) : sample_info[single_sample_type].collect{ "${it['bam']}" as String }
                ]
            ]
        ]
    } else {
        input_map = [
            'metapipeline_states_to_delete': states_to_delete,
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
