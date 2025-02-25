/**
*   Nextflow module for calling the annotate-VCF pipeline
*/

include { combine_input_with_params; generate_weblog_args; generate_graceful_error_controller } from '../common.nf'

/**
*   Process to call the annotate-VCF pipeline
*
*   Input:
*       @param sample_id_for_annotate_vcf (String): Sample ID
*       @param input_yaml (path): Path to the input YAML containing inputs
*/

process run_annotate_VCF {
    cpus params.annotate_VCF.subworkflow_cpus

    label 'graceful_failure'

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "annotate-VCF-*/*"

    publishDir "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_annotate_vcf}/log${file(it).getName()}" }

    input:
        tuple(
            val(sample_id_for_annotate_vcf),
            path(input_yaml),
            val(tool)
        )

    output:
        path "annotate-VCF-*/*", optional: true
        path ".command.*"
        val('done'), emit: complete
        env EXIT_CODE, emit: exit_code

    script:
    String params_to_dump = combine_input_with_params(params["annotate_VCF"].metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    String setup_commands = generate_graceful_error_controller(task.ext)
    String weblog_args = generate_weblog_args()
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_annotate_vcf_params.yaml

    ${setup_commands}
    \$DISABLE_FAIL

    nextflow run \
        ${moduleDir}/../../external/pipeline-annotate-VCF/main.nf \
        -params-file combined_annotate_vcf_params.yaml \
        --work_dir ${params.work_dir} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config ${weblog_args}

    capture_exit_code
    \$ENABLE_FAIL
    """
}
