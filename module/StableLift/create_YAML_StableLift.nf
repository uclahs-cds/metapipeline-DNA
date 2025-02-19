import org.yaml.snakeyaml.Yaml

/*
* Create input YAML file for the StableLift pipeline.
*
* Input:
*   sample_info: A Map object containing sample information
*
* Output:
*   @return A tuple of 4 items, inlcuding the sample_id and input_yaml and rf model and tool
*/
process create_YAML_StableLift {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${sample_id}",
        pattern: 'stablelift_input.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(sample_id), path(input_yaml), val(run_model), val(sample_info.tool), emit: stablelift_input

    exec:
    input_yaml = 'stablelift_input.yaml'

    sample_id = "${sample_info.sample}-${sample_info.tool}" as String

    input_map = [
        'sample_id': sample_id,
        'input': [
            'vcf': sample_info.path
        ]
    ]

    Map all_models = params["StableLift"].stablelift_models
    run_model = all_models[params["StableLift"].liftover_direction][sample_info.tool]

    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
