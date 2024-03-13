import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the call-gSV pipeline.
*
* Input:
*   A tuple consisting of patient_id, sample_id, and the path to the input BAM
*
* Output:
*   @return A path to the input YAML
*/
process create_YAML_call_gSV {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${patient_id}/${sample_id}",
        pattern: 'call_gSV_input.yaml',
        mode: 'copy'

    input:
        tuple(
            val(patient_id), val(sample_id), val(bam)
        )

    output:
        path(input_yaml), emit: call_gsv_yaml

    exec:
    input_yaml = "call_gSV_input.yaml"

    input_map = [
        'input': [
            'BAM': ['normal': [ "${bam}" as String ]]
        ]
    ]

    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
