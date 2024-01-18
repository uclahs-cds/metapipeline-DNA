import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the targeted-coverage pipeline.
*
* Input:
*   sample_info: A Map object containing sample information split into normal and tumor
*
* Output:
*   @return A tuple of 2 items, inlcuding the patient_id and input_yaml
*/
process create_YAML_targeted_coverage {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${patient_id}",
        enabled: params.save_intermediate_files,
        pattern: 'targeted_coverage_input.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(patient_id), path(input_yaml), emit: targeted_coverage_input

    exec:
    input_yaml = 'targeted_coverage_input.yaml'

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
            'sample_id': patient_id,
            'input': [
                'bam': sample_info[single_sample_type].collect{ "${it['bam']}" as String }
            ]
        ]
    } else {
        input_map = [
            'patient_id': patient_id,
            'input': [
                'bam': sample_info.normal.collect{ "${it['bam']}" as String }
            ]
        ]
    }
    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
