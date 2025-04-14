import org.yaml.snakeyaml.Yaml

/*
* Create input YAML file for the calculate-mtDNA-CopyNumber pipeline.
*
* Input:
*   sample_info: A Map object containing sample information
*
* Output:
*   @return A tuple of 3 items, inlcuding the sample_id and input_yaml and tool
*/
process create_YAML_calculate_mtDNA_CopyNumber {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${sample_id}",
        pattern: 'calculate_mtdna_cn.yaml',
        mode: 'copy'

    input:
        val(sample_info)

    output:
        tuple val(sample_id), path(input_yaml), val(sample_info.tool), emit: calculate_mtdna_copynumber_input

    exec:
    input_yaml = 'calculate_mtdna_cn.yaml'

    sample_id = "${sample_info.sample}-${sample_info.tool}" as String

    input_map = [
        'sample_id': sample_id,
        'input': [
            'coverage': [
                ("${sample_info.tool}" as String): sample_info.path
            ]
        ]
    ]

    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
