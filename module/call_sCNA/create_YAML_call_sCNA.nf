import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the call-sCNA pipeline.
*
* Input:
*   sample_info: A Map object containing sample information split into normal and tumor
*
* Output:
*   @return A path to the input YAML
*/
process create_YAML_call_sCNA {

    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${tumor_id}",
        enabled: params.save_intermediate_files,
        pattern: 'call_sCNA_input.yaml',
        mode: 'copy'

    input:
        tuple(
            val(tumor_id), val(normal_bam), val(tumor_bam)
        )

    output:
        tuple val(tumor_id), path(input_yaml)

    exec:
    input_yaml = 'call_sCNA_input.yaml'

    input_map = [
            'patient_id': tumor_id,
            'input': [
                'BAM': [
                    'normal': [ "${normal_bam}" as String ],
                    'tumor': [ "${tumor_bam}" as String ]
                ]
            ]
        ]
    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
