#!/usr/bin/env nextflow
/*
* Main entrance of alling the germline somatic pipeline in batches.
*/

nextflow.enable.dsl = 2

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

    - options:
        option metapipeline_DNA_config: ${params.metapipeline_DNA_config}
        option executor: ${params.executor}
        option partition: ${params.partition}
        option per_job_cpus: ${params.per_job_cpus} 
        option per_job_memory_GB: ${params.per_job_memory_GB}
        option max_parallel_jobs: ${params.max_parallel_jobs}

    Tools Used:
        uclahs-cds/pipeline-convert-BAM2FASTQ: ${params.version_BAM2FASTQ}
        uclahs-cds/pipeline-align-DNA: ${params.version_align_DNA}
        uclahs-cds/pipeline-call-gSNP: ${params.version_call_gSNP}
        uclahs-cds/pipeline-call-sSNV: ${params.version_call_sSNV}
        uclahs-cds/pipeline-call-mtSNV: ${params.version_call_mtSNV}

    ------------------------------------
    Starting workflow...
    ------------------------------------
    """
    .stripIndent()

/*
* Create input CSV file with all samples belong to a single patient to be passed to the germline-
* somatic pipeline.
*
* Input:
*   A tuple of two objects.
*     @param patient (val): the patient ID
*     @records (tuple[tuple[str|file]]): A 2D tuple, that each child tuple contains the patient ID,
*       sample ID, state, and other inputs depending on input type.
*
* Output:
*   A tuple of two objects.
*     @return patient (val): the patient ID
*     @return input_csv (file): the input CSV file generated to be passed to the metapipeline-DNA.
*/

process create_input_csv_metapipeline_DNA {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}-${patient}/log${file(it).getName()}" }

    publishDir path: "${params.output_dir}/intermediate/${task.process}-${patient}",
        enabled: params.save_intermediate_files,
        mode: "copy",
        pattern: "*.csv"

    input:
        tuple(
            val(patient),
            val(records)
        )

    output:
        tuple(
            val(patient),
            path(input_csv)
        )
        path(".command.*")

    script:
    input_csv = "${patient}_metapipeline_DNA_input.csv"
    header_line = (params.input_type == 'BAM') ? \
        "patient,sample,state,bam" : \
        "patient,sample,state,index,read_group_identifier,sequencing_center,library_identifier,platform_technology,platform_unit,bam_header_sm,lane,read1_fastq,read2_fastq"
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
            path(input_csv)
        )

    output:
        path(".command.*")

    script:
    """
    NXF_WORK=${params.pipeline_work_dir} \
    nextflow run \
        ${moduleDir}/modules/metapipeline_DNA.nf \
        --input_csv ${input_csv} \
        --patient ${patient} \
        --input_type ${params.input_type} \
        --project_id ${params.project_id} \
        --save_intermediate_files ${params.save_intermediate_files} \
        --output_dir ${params.output_dir} \
        --metapipeline_log_output_dir ${params.log_output_dir} \
        --work_dir ${params.work_dir} \
        -c ${file(params.metapipeline_DNA_config)}
    """
}

workflow {
    if (params.input_type == 'BAM') {
        ich  = Channel.from(params.input.BAM)
            .map{ [it.patient, [it.patient, it.sample, it.state, it.path]] }
            .groupTuple(by: 0)
    } else if (params.input_type == 'FASTQ') {
        ich = Channel.from(params.input.FASTQ)
            .map{ [it.patient, [it.patient, it.sample, it.state, it.index, it.read_group_identifier, it.sequencing_center, it.library_identifier, it.platform_technology, it.platform_unit, it.bam_header_sm, it.lane, it.read1_fastq, it.read2_fastq]] }
            .groupTuple(by: 0)
    }
    create_input_csv_metapipeline_DNA(ich)
    call_metapipeline_DNA(create_input_csv_metapipeline_DNA.out[0])
}
