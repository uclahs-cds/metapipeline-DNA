include { combine_input_with_params } from '../common.nf'
/*
* Call the generate-SQC-BAM pipeline
*
* Input:
*   input_yaml: The input YAML file
*/
process run_generate_SQC_BAM {
    cpus params.generate_SQC_BAM.subworkflow_cpus

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${params.patient}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "generate-SQC-BAM-*/*"

    input:
        path(input_yaml)

    output:
        file "generate-SQC-BAM-*/*"
        file ".command.*"
        val('done'), emit: complete

    script:
    String params_to_dump = combine_input_with_params(params.generate_SQC_BAM.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_generate_sqc_bam_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-generate-SQC-BAM/main.nf \
        -params-file combined_generate_sqc_bam_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        --patient_id ${params.patient} \
        -c ${moduleDir}/default.config
    """
}
