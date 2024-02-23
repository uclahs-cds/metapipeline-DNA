include { combine_input_with_params } from '../common.nf'
/*
* Call the recalibrate-BAM pipeline
*
* Input:
*   A tuple that contains 4 items:
*     @param states_to_delete (List): List of states to delete.
      @param sample_id_for_recalibrate (String): Sample ID.
*     @param sample_states (Map): Map of sample IDs organized by state.
*     @param input_yaml (file): The input YAML file for recalibrate-BAM pipeline.
*
* Output:
*   @return A Map...
*/
process run_recalibrate_BAM {
    cpus params.recalibrate_BAM.subworkflow_cpus

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process.replace(':', '/')}-${sample_id_for_recalibrate}/log${file(it).getName()}" }

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "recalibrate-BAM-*/*"

    input:
        tuple(
            val(states_to_delete),
            val(sample_id_for_recalibrate),
            val(sample_states),
            path(input_yaml),
            val(completion_signal)
        )

    output:
        tuple val(sample_states), path(output_directory), path(qc_directory), emit: identify_recalibrate_bam_out
        file "recalibrate-BAM-*/*"
        file ".command.*"

    script:
    output_directory = "recalibrate-BAM-*/${sample_id_for_recalibrate}/GATK-*/output"
    qc_directory = "recalibrate-BAM-*/${sample_id_for_recalibrate}/GATK-*/QC/run_CalculateContamination_GATK"
    String params_to_dump = combine_input_with_params(params.recalibrate_BAM.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    WORK_DIR=${params.work_dir}/work-recalibrate-BAM-${sample_id_for_recalibrate}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR

    printf "${params_to_dump}" > combined_recalibrate_bam_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-recalibrate-BAM/main.nf \
        -params-file combined_recalibrate_bam_params.yaml \
        --work_dir \$WORK_DIR \
        --metapipeline_final_output_dir "${params.output_dir}/output/align-DNA-*/*/BWA-MEM2-*/output" \
        --metapipeline_delete_input_bams ${params.enable_input_deletion_recalibrate_bam} \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    rm -r \$WORK_DIR
    """
}
