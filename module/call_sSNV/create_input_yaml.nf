import org.yaml.snakeyaml.Yaml
/*
* Create input YAML file for the call-sSNV pipeline.
*
* Input:
*   A tuple of two items:
*     @param sample_id (String): Sample ID to be used for run
*     @param normal_bam (String): Path to normal BAM
*     @param tumor_bam (List): List of paths to tumor BAMs
*     @param algorithms (String): Comma-separated list of algorithms to run
*
* Output:
*   @return A tuple of 3 items, inlcuding the sample_id, algorithms, and the input YAML file created for the call-sSNV pipeline.
*/
process create_input_yaml_call_sSNV {
    publishDir "${params.output_dir}/intermediate/${task.process.replace(':', '/')}-${params.patient}/${sample_id}",
        enabled: params.save_intermediate_files,
        pattern: 'call_sSNV_input.yaml',
        mode: 'copy'

    input:
        tuple(
            val(sample_id), val(normal_bam), val(tumor_bam), val(algorithms)
        )

    output:
        tuple(
            val(sample_id),
            val(algorithms),
            path(input_yaml)
        )

    exec:
    input_yaml = 'call_sSNV_input.yaml'
    param_tumor_bams = tumor_bam.collect{ ['id': it[0], 'BAM': "${it[1]}" as String] }
    param_normal_bam = normal_bam.collect{ ['id': it[0], 'BAM': "${it[1]}" as String] }
    if (params.sample_mode == 'single') {
        input_map = [
            'patient_id': sample_id,
            'input': [
                'tumor': param_tumor_bams
            ]
        ]
    } else {
        input_map = [
            'patient_id': sample_id,
            'input': [
                'normal': param_normal_bam,
                'tumor': param_tumor_bams
            ]
        ]
    }
    Yaml yaml = new Yaml()
    yaml.dump(input_map, new FileWriter("${task.workDir}/${input_yaml}"))
}
