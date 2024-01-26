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
        tuple val(sample_id), val(bam)

    output:
        tuple val(sample_id), path(input_yaml), emit: targeted_coverage_input

    exec:
    input_yaml = 'targeted_coverage_input.yaml'

    input_map = [
        'sample_id': sample_id,
        'input': [
            'bam': "${bam}"
        ]
    ]

    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
