include { sanitize_string } from '../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
include { combine_input_with_params } from '../common.nf'
/*
* Call the call-gSNP pipeline
*
* Input:
*   A tuple that contains 6 items:
*     @param patient (String): Patient ID
*     @param tumor_sample (String): Sample ID of the tumor sample.
*     @param normal_sample (String): Sample ID of the normal sample.
*     @param input_csv (file): The input CSV file for call-gSNP pipeline.
*
* Output:
*   @return A tuple of 7 items, the input values of patient, tumor_sample, normal_sample,
*     normal_sample, as well as the output tumor and normal BAM files.
*/
process run_call_gSNP {
    cpus params.call_gSNP.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "call-gSNP-*/*"


    input:
        tuple(
            val(patient), val(run_mode), val(sample_id_for_gsnp),
            val(tumor_sample), val(normal_sample),
            val(normal_bam_sm), path(input_csv)
        )

    output:
        tuple val(patient), val(run_mode), val(tumor_sample), val(normal_sample), path("*.bam"), path(normal_bam), emit: full_output
        path("*.bam"), emit: tumor_bam
        file "call-gSNP-*/*"

    script:
    normal_bam = "call-gSNP-*/${sample_id_for_gsnp}/GATK-*/output/*_GATK-*_${sanitize_string(normal_bam_sm)}.bam"
    String params_to_dump = combine_input_with_params(params.call_gSNP.metapipeline_arg_map)
    """
    set -euo pipefail

    WORK_DIR=${params.work_dir}/work-call-gSNP-${sample_id_for_gsnp}
    mkdir \$WORK_DIR

    cat ${moduleDir}/default.config | sed "s:<OUTPUT-DIR-METAPIPELINE>:\$(pwd):g" \
        > call_gsnp_default_metapipeline.config

    printf "${params_to_dump}" > combined_call_gsnp_params.yaml

    nextflow run \
        ${moduleDir}/../../external/pipeline-call-gSNP/main.nf \
        -params-file combined_call_gsnp_params.yaml \
        --input_csv ${input_csv.toRealPath()} \
        --work_dir \$WORK_DIR \
        --metapipeline_final_output_dir "${params.output_dir}/output/align-DNA-*/*/BWA-MEM2-*/output" \
        --metapipeline_delete_input_bams ${params.enable_input_deletion_call_gsnp} \
        --dataset_id ${params.project_id} \
        -c call_gsnp_default_metapipeline.config

    if ${params.sample_mode == 'single'}
    then
        touch NO_FILE.bam
    else
        for i in `ls --hide=*_GATK-*_${sanitize_string(normal_bam_sm)}.bam call-gSNP-*/${sample_id_for_gsnp}/GATK-*/output/ -1 | grep ".bam\$"`
        do
            full_path=`find \$(pwd) -name \$i`
            ln -s \$full_path \$i
        done
    fi

    rm -r \$WORK_DIR
    """
}
