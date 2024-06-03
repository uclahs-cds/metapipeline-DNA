import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the call-SRC pipeline.
*
* Input:
*   sample_info: A Map object containing sample information split into normal and tumor
*
* Output:
*   @return A tuple of 2 items, inlcuding the patient_id and input_yaml
*/
process create_YAML_call_SRC {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${sample_id}",
        pattern: 'call_SRC_input.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(sample_id), path(input_yaml), emit: call_src_input

    exec:
    input_yaml = 'call_SRC_input.yaml'

    String single_sample_type = 'tumor'

    sample_id = ''
    if (params.sample_mode == 'multi') {
        sample_id = params.patient
    } else {
        assert sample_info[single_sample_type].sample.size() == 1
        sample_id = sample_info[single_sample_type].sample[0]
    }

    input_map = [
        'patient_id': params.patient,
        'sample_id': sample_id,
        'input': [
            'SNV': [
                'algorithm': null
            ],
            'CNA': [
                'algorithm': null
            ]
        ]
    ]

    sample_info[single_sample_type].each { sample_data ->
        sample_data.src_input.each { src_input_data ->
            if (!input_map.input[src_input_data.src_input_type].algorithm) {
                input_map.input[src_input_data.src_input_type].algorithm = src_input_data.algorithm
            }

            assert input_map.input[src_input_data.src_input_type].algorithm == src_input_data.algorithm : "Found multiple algorithms for `${src_input_data.src_input_type}`: `${input_map.input[src_input_data.src_input_type].algorithm}` and `${src_input_data.algorithm}`"

            if (!input_map.input[src_input_data.src_input_type].containsKey(sample_data.sample)) {
                input_map.input[src_input_data.src_input_type][sample_data.sample] = []
            }

            input_map.input[src_input_data.src_input_type][sample_data.sample].add("${src_input_data.path}" as String)
        }
    }

    assert input_map.input.SNV.algorithm != null : "Found no SNV input!"
    assert input_map.input.CNA.algorithm != null : "Found no CNA input!"

    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
