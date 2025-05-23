#!/usr/bin/env nextflow
/*
* Main entrance of calling the germline somatic pipeline in batches.
*/

nextflow.enable.dsl = 2

import groovy.json.JsonOutput

// Log info here
log.info """\
    =================================================
             M E T A P I P E L I N E - D N A
    =================================================
    Boutros Lab

    Current Configuration:
    - pipeline:
        name: ${workflow.manifest.name}
        version: ${workflow.manifest.version}

    - input:
        input input_csv: ${params.containsKey('input_csv') ? params.input_csv : 'YAML input used.'}
        input project_id: ${params.project_id}

    - output:
        output_dir: ${params.output_dir}
        final_output_dir: ${params.final_output_dir}

    - options:
        option executor: ${params.executor}
        option partition: ${params.partition}
        option max_parallel_jobs: ${params.max_parallel_jobs}
        option sample_mode: ${params.sample_mode}

    Tools Used:
        uclahs-cds/pipeline-convert-BAM2FASTQ: ${params.version_BAM2FASTQ}
        uclahs-cds/pipeline-align-DNA: ${params.version_align_DNA}
        uclahs-cds/pipeline-recalibrate-BAM: ${params.version_recalibrate_BAM}
        uclahs-cds/pipeline-call-gSNP: ${params.version_call_gSNP}
        uclahs-cds/pipeline-call-sSNV: ${params.version_call_sSNV}
        uclahs-cds/pipeline-call-mtSNV: ${params.version_call_mtSNV}
        uclahs-cds/pipeline-call-gSV: ${params.version_call_gSV}
        uclahs-cds/pipeline-call-sSV: ${params.version_call_sSV}
        uclahs-cds/pipeline-call-sCNA: ${params.version_call_sCNA}
        uclahs-cds/pipeline-calculate-targeted-coverage: ${params.version_calculate_targeted_coverage}
        uclahs-cds/pipeline-generate-SQC-BAM: ${params.version_generate_SQC_BAM}
        uclahs-cds/pipeline-StableLift: ${params.version_StableLift}
        uclahs-cds/pipeline-annotate-VCF: ${params.version_annotate_VCF}
        uclahs-cds/pipeline-call-GeneticAncestry: ${params.version_call_GeneticAncestry}
        uclahs-cds/pipeline-calculate-mtDNA-CopyNumber: ${params.version_calculate_mtDNA_CopyNumber}

    ------------------------------------
    Starting workflow...
    ------------------------------------
    """
    .stripIndent()

/*
* Dump the pipeline-specific params to a JSON file
*
* Output:
*   @return pipeline_params_json (file): JSON file containing all pipeline-specific params
*/
process create_config_metapipeline_DNA {
    publishDir path: "${params.final_output_dir}/intermediate",
        mode: "copy",
        pattern: "*.json",
        saveAs: { "${task.process}/${identifier}-${file(it).getName()}" }

    input:
        tuple(
            val(patient),
            val(identifier)
        )

    output:
    tuple val(patient), path("pipeline_specific_params.json"), val(identifier), emit: metapipeline_dna_input

    exec:
    def filtering_criteria = { k, v ->
        if (params.sample_mode == 'single') {
            return k == identifier
        } else {
            return v['patient'] == identifier
        }
    }
    Map sample_data = ['sample_data': params.sample_data.findAll{ sample, sample_vals -> filtering_criteria(sample, sample_vals) }]
    Map pipeline_predecessor = ['pipeline_predecessor': params.pipeline_predecessor]
    Map pipeline_interval_params = ['pipeline_interval_params': params.pipeline_interval_params]
    json_params = JsonOutput.prettyPrint(JsonOutput.toJson(params.pipeline_params + sample_data + pipeline_predecessor + pipeline_interval_params))
    writer = file("${task.workDir}/pipeline_specific_params.json")
    writer.write(json_params)
}

/*
* Process to call the germline-somatic pipeline. The pipeline accepts one patient with all samples
* of them.
*
* Input:
*   A tuple of two objects:
*     @param patient (val): patient ID
*     @param input_csv (file): Input CSV file
*
* Output:
*   @return Directory contains all data for the patient.
*/
process call_metapipeline_DNA {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}/${identifier}-${new StringBuilder(task.hash).insert(2, '-').toString()}/log${file(it).getName()}" }

    input:
        tuple(
            val(patient),
            path(pipeline_params_json),
            val(identifier)
        )

    output:
        tuple env(CURRENT_WORK_DIR), env(SBATCH_RET), emit: submit_out
        path(".command.*")

    script:
    submission_command = (params.uclahs_cds_wgs)
        ? params.global_job_submission_sbatch + "-J wgs_${task.process}_${identifier}_\${FIRST_DIR_HASH}_\${SECOND_DIR_HASH} --wrap=\""
        : ""
    limiter_wrapper_pre = (params.uclahs_cds_wgs)
        ? params.global_job_submission_limiter + submission_command
        : ""
    limiter_wrapper_post = (params.uclahs_cds_wgs)
        ? "\")"
        : ""
    limiter_wrapper_pre + """

    : "\${CURRENT_WORK_DIR:=`pwd`}"
    : "\${SBATCH_RET:=-1}"

    NXF_WORK=${params.resolved_work_dir} \
    ${projectDir}/templates/nextflow-wrapper run \
        ${moduleDir}/module/metapipeline_DNA.nf \
        --status_email_address '${params.status_email_address}' \
        --patient ${patient} \
        --input_type ${params.input_type} \
        --sample_mode ${params.sample_mode} \
        --project_id ${params.project_id} \
        --save_intermediate_files ${params.save_intermediate_files} \
        --output_dir ${params.final_output_dir} \
        --metapipeline_log_output_dir ${params.log_output_dir} \
        --work_dir ${params.resolved_work_dir} \
        --pipeline_status_directory ${params.resolved_work_dir}/PIPELINESTATUSDIRECTORY \
        --pipeline_exit_status_directory "\$(pwd)/PIPELINEEXITSTATUS" \
        --override_realignment ${params.override_realignment} \
        --override_recalibrate_bam ${params.override_recalibrate_bam} \
        --enable_input_deletion_recalibrate_bam ${params.enable_input_deletion_recalibrate_bam} \
        --normal_sample_count ${params.sample_counts[patient]['normal']} \
        --tumor_sample_count ${params.sample_counts[patient]['tumor']} \
        --use_original_intervals ${params.use_original_intervals} \
        --task_hash \$(pwd | rev | cut -d '/' -f 1,2 | rev | sed 's/\\//_/') \
        --src_snv_tool ${params.src_snv_tool} \
        --src_cna_tool ${params.src_cna_tool} \
        -params-file ${pipeline_params_json} \
        -c ${moduleDir}/config/metapipeline_DNA_base.config
    """ + limiter_wrapper_post
}

process check_process_status {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}/${file(work_dir).getParent().getFileName()}-${file(work_dir).getFileName()}/log${file(it).getName()}" }

    input:
        tuple val(work_dir), val(sbatch_ret)

    debug true

    output:
    path(".command.*")

    shell:
    template 'status_check.sh'
}

workflow {
    List input_data = [];
    params.input.each { patient, patient_data ->
        patient_data.each {sample, sample_data ->
            input_data.add(['patient': patient, 'sample': sample]);
        }
    }

    ich_individual = Channel.from(input_data);

    if (params.sample_mode == 'single') {
        // Group by sample
        ich = ich_individual
            .map{ [it.patient, it.sample] }
    } else {
        ich = ich_individual
            .map{ it.patient }
            .unique()
            .map{ [it, it] }
    }

    create_config_metapipeline_DNA(ich)
    call_metapipeline_DNA(create_config_metapipeline_DNA.out.metapipeline_dna_input)

    check_process_status(call_metapipeline_DNA.out.submit_out)
}
