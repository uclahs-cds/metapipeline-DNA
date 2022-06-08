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
*       sample ID, state, site, and path to the BAM file.
*
* Output:
*   A tuple of five objects.
*     @return patient (val): the patient ID
*     @return sample (val): the sample ID
*     @return state (val): tumor or normal
*     @return site (val): the sample site
*     @return input_csv (file): the input CSV file generated to be passed to the germline-somatic
*       pipeline.
*/

process create_input_csv_metapipeline_DNA {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}/${patient}/log${file(it).getName()}" }

    publishDir path: "${params.output_dir}/intermediate/${task.process}/${patient}",
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
            val(sample),
            val(state),
            val(site),
            path(input_csv)
        )
        path(".command.*")

    script:
    input_csv = "${patient}_metapipeline_DNA_input.csv"
    lines = []
    sample = records[0][1]
    state = records[0][2]
    site = records[0][3]
    for (record in records) {
        lines.add(record.join(','))
    }
    lines = lines.join('\n')
    """
    echo 'patient,sample,state,site,bam' > ${input_csv}
    echo '${lines}' >> ${input_csv}
    """
}

/*
* Create input CSV file for fastq entry following the input for the call_align_DNA process
*
* Input:
*   A tuple of five objects.
*     @return patient (val): the patient ID
*     @return sample (val): the sample ID
*     @return state (val): tumor or normal
*     @return site (val): the sample site
*     @records (tuple[tuple[str|file]]): A 2D tuple, that each child tuple contains the patient ID,
*       sample ID, state, site, and path to the BAM file.
*
* Output:
*   A tuple of five objects.
*     @return patient (val): the patient ID
*     @return sample (val): the sample ID
*     @return state (val): tumor or normal
*     @return site (val): the sample site
*     @return input_csv (file): the input CSV file generated to be passed to the germline-somatic
*       pipeline.
*/

process create_input_csv_metapipeline_DNA_fastq {
    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}/${patient}/log${file(it).getName()}" }

    publishDir path: "${params.output_dir}/intermediate/${task.process}/${patient}",
        enabled: params.save_intermediate_files,
        mode: "copy",
        pattern: "*.csv"

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            val(records)
        )

    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            path(input_csv)
        )
        path(".command.*")

    script:
    input_csv = "${sample}_align_DNA_input.csv"
    lines = []
    for (record in records) {
        lines.add(record.join(','))
    }
    lines = lines.join('\n')
    """
    echo "index,read_group_identifier,sequencing_center,library_identifier,platform_technology,platform_unit,sample,lane,read1_fastq,read2_fastq" > ${input_csv}
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
    // For the first ${params.maxForks} number of tasks, give each taks a 5 delay. Because reference
    // files are copied to worker node each time, so this would reduce the nextwork burden.
    beforeScript "sleep ${((task.index < task.maxForks ? task.index : task.maxForks) - 1) * 300}"

    publishDir path: "${params.log_output_dir}/process-log",
        mode: "copy",
        pattern: ".command.*",
        saveAs: { "${task.process}/${patient}/log${file(it).getName()}" }


    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
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
        --sample ${sample} \
        --state ${state} \
        --site ${site} \
        --project_id ${params.project_id} \
        --save_intermediate_files ${params.save_intermediate_files} \
        --output_dir ${params.output_dir} \
        --work_dir ${params.work_dir} \
        -c ${file(params.metapipeline_DNA_config)}
    """
}


workflow {
    println params
    if (params.input?.BAM) {
        ich = Channel.from(params.input.BAM)
            .map { [it.patient, [it.patient, it.sample, it.state, it.site, it.path]] }
            .groupTuple(by:[0])
        create_input_csv_metapipeline_DNA(ich)
        // call_metapipeline_DNA(create_input_csv_metapipeline_DNA.out[0])
    } else if (params.input?.FASTQ) {
        ich = Channel.from(params.input.FASTQ)
            .map { [it.patient, it.sample, it.state, it.site, [it.index, it.read_group_identifier, it.sequencing_center, it.library_identifier, it.platform_technology, it.platform_unit, it.bam_header_sm, it.lane, it.read1_fastq, it.read2_fastq]] }
            .groupTuple(by:[0,1,2,3])
        create_input_csv_metapipeline_DNA_fastq(ich)
        // call_metapipeline_DNA(create_input_csv_metapipeline_DNA_fastq.out[0])
    }
}
