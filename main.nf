#!/usr/bin/env nextflow
/*
* Main entrance of alling the germline somatic pipeline in batches.
*/

nextflow.enable.dsl = 2

import groovy.json.JsonOutput

// Log info here
log.info """\
    =================================================
    P I P E L I N E - G E R M L I N E - S O M A T I C
    =================================================
    Boutros Lab

    Current Configuration:
    - pipeline:
        name: ${workflow.manifest.name}
        version: ${workflow.manifest.version}

    - input:
        input input_csv: ${params.input_csv}
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
        uclahs-cds/pipeline-call-gSNP: ${params.version_call_gSNP}
        uclahs-cds/pipeline-call-sSNV: ${params.version_call_sSNV}
        uclahs-cds/pipeline-call-mtSNV: ${params.version_call_mtSNV}
        uclahs-cds/pipeline-call-gSV: ${params.version_call_gSV}
        uclahs-cds/pipeline-call-sSV: ${params.version_call_sSV}

    ------------------------------------
    Starting workflow...
    ------------------------------------
    """
    .stripIndent()

/*
* Create input CSV file to be passed to the metapipeline-DNA pipeline.
*
* Input:
*   A tuple of two objects.
*     @param patient (val): the patient ID
*     @param identifier (val): the identifier for the file
*     @records (tuple[tuple[str|file]]): A 2D tuple, that each child tuple contains the patient ID,
*       sample ID, state, and other inputs depending on input type.
*
* Output:
*   A tuple of two objects.
*     @return patient (val): the patient ID
*     @return input_csv (file): the input CSV file generated to be passed to the metapipeline-DNA.
*/

process create_CSV_metapipeline_DNA {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}-${identifier}/log${file(it).getName()}" }

    publishDir path: "${params.final_output_dir}/intermediate/${task.process}-${identifier}",
        enabled: params.save_intermediate_files,
        mode: "copy",
        pattern: "*.csv"

    input:
        tuple(
            val(patient),
            val(identifier),
            val(records)
        )

    output:
        tuple(
            val(patient),
            path(input_csv)
        )
        path(".command.*")

    script:
    input_csv = "${identifier}_metapipeline_DNA_input.csv"
    header_line = (params.input_type == 'BAM') ? \
        "patient,sample,state,bam" : \
        "patient,sample,state,read_group_identifier,sequencing_center,library_identifier,platform_technology,platform_unit,bam_header_sm,lane,read1_fastq,read2_fastq"
    lines = []
    for (record in records) {
        lines.add(record.join(','))
    }
    lines = lines.join('\n')
    """
    echo ${header_line} > ${input_csv}
    echo '${lines}' >> ${input_csv}
    """
}

/*
* Dump the pipeline-specific params to a JSON file
*
* Output:
*   @return pipeline_params_json (file): JSON file containing all pipeline-specific params
*/
process create_config_metapipeline_DNA {
    output:
    path "pipeline_specific_params.json", emit: pipeline_params_json

    exec:
    json_params = JsonOutput.prettyPrint(JsonOutput.toJson(params.pipeline_params))
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
        saveAs: { "${task.process}-${patient}/log${file(it).getName()}" }


    input:
        tuple(
            val(patient),
            path(input_csv),
            path(pipeline_params_json)
        )

    output:
        path(".command.*")

    script:
    submission_command = (params.uclahs_cds_wgs) ? params.global_job_submission_sbatch + "-J ${task.process}_${patient} --wrap=\"" : ""
    limiter_wrapper_pre = (params.uclahs_cds_wgs) ? params.global_job_submission_limiter + submission_command : ""
    limiter_wrapper_post = (params.uclahs_cds_wgs) ? "\"; sleep 120" : ""
    limiter_wrapper_pre + """
    NXF_WORK=${params.pipeline_work_dir} \
    nextflow run \
        ${moduleDir}/module/metapipeline_DNA.nf \
        --input_csv ${input_csv} \
        --patient ${patient} \
        --input_type ${params.input_type} \
        --sample_mode ${params.sample_mode} \
        --project_id ${params.project_id} \
        --save_intermediate_files ${params.save_intermediate_files} \
        --output_dir ${params.final_output_dir} \
        --metapipeline_log_output_dir ${params.log_output_dir} \
        --work_dir ${params.work_dir} \
        --override_realignment ${params.override_realignment} \
        --override_call_gsnp ${params.override_call_gsnp} \
        --enable_input_deletion_call_gsnp ${params.enable_input_deletion_call_gsnp} \
        -params-file ${pipeline_params_json}
    """ + limiter_wrapper_post
}

workflow {
    if (params.input_type == 'BAM') {
        ich_individual  = Channel.from(params.input.BAM)
            .map{ [it.patient, [it.patient, it.sample, it.state, it.path]] }
    } else if (params.input_type == 'FASTQ') {
        ich_individual = Channel.from(params.input.FASTQ)
            .map{ [it.patient, [it.patient, it.sample, it.state, it.read_group_identifier, it.sequencing_center, it.library_identifier, it.platform_technology, it.platform_unit, it.bam_header_sm, it.lane, it.read1_fastq, it.read2_fastq]] }
    }

    if (params.sample_mode == 'single') {
        // Group by sample
        ich = ich_individual
            .map{ [it[1][1], it[1]] }
            .groupTuple(by: 0)
            .map{ [it[1][0][0], it[0], it[1]] } // [patient, sample, records]
    } else {
        ich = ich_individual
            .groupTuple(by: 0)
            .map{ [it[0], it[0], it[1]] } // [patient, patient, records]
    }

    create_CSV_metapipeline_DNA(ich)
    create_config_metapipeline_DNA()
    call_metapipeline_DNA(create_CSV_metapipeline_DNA.out[0].combine(create_config_metapipeline_DNA.out.pipeline_params_json))
}
