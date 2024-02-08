include { combine_input_with_params } from '../common.nf'
/*
* Call the targeted-coverage pipeline
*
* Input:
*   A tuple that contains 2 items:
      @param sample_id_for_targeted_coverage (String): Sample ID.
*     @param input_yaml (file): The input YAML file for targeted_coverage pipeline.
*/
process run_targeted_coverage {
    cpus params.targeted_coverage.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "targeted-coverage-*/*"


    input:
        tuple(
            val(sample_id_for_targeted_coverage),
            path(input_yaml)
        )

    output:
        file "targeted-coverage-*/*"
        val('done'), emit: complete

    script:
    String params_to_dump = combine_input_with_params(params.targeted_coverage.metapipeline_arg_map, new File(input_yaml.toRealPath().toString()))
    """
    set -euo pipefail

    WORK_DIR=${params.work_dir}/work-targeted-coverage-${sample_id_for_targeted_coverage}
    mkdir \$WORK_DIR && chmod 2777 \$WORK_DIR

    printf "${params_to_dump}" > combined_targeted_coverage_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-targeted-coverage/main.nf \
        -params-file combined_targeted_coverage_params.yaml \
        --work_dir \$WORK_DIR \
        --output_dir \$(pwd) \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    rm -r \$WORK_DIR
    """
}
