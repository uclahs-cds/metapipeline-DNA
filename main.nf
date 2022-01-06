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
        option sample_level_config: ${params.sample_level_config}
        option executor: ${params.executor}
        option partition: ${params.partition}
        option per_job_cpus: ${params.per_job_cpus} 
        option per_job_memory_GB: ${params.per_job_memory_GB}
        option max_parallel_jobs: ${params.max_parallel_jobs}

    Tools Used:
        uclahs-cds/pipeline-convert-BAM2FASTQ: ${params.version_BAM2FASTQ}
        uclahs-cds/pipeline-align-DNA: ${params.version_align_DNA}
        uclahs-cds/pipeline-caall-gSNP: ${params.version_call_gSNP}
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
*   A tuple of tow objects.
*     @return patient (val): the patient ID
*     @return input_csv (file): the input CSV file generated to be passed to the germline-somatic
*       pipeline.
*/
process create_input_csv_germline_somatic {
    input:
        tuple(
            val(patient),
            val(records)
        )

    output:
        tuple(
            val(patient),
            file(input_csv)
        )
        file output_dir

    script:
    input_csv = 'germline_somatci_input.csv'
    lines = []
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
process call_germline_somatic {
    // For the first ${params.maxForks} number of tasks, give each taks a 5 delay. Because reference
    // files are copied to worker node each time, so this would reduce the nextwork burden.
    beforeScript "sleep ${((task.index < task.maxForks ? task.index : task.maxForks) - 1) * 300}"

    publishDir params.output_dir, mode: 'move'

    input:
        tuple(
            val(patient),
            file(input_csv)
        )
    output:
        file patient

    script:
    """
    NXF_WORK=${params.temp_dir} \
    nextflow run \
        ${moduleDir}/modules/germline_somatic.nf \
        --input_csv ${input_csv} \
        --patient ${patient} \
        --project_id ${params.project_id} \
        --save_intermediate_files ${params.save_intermediate_files} \
        --output_dir ./ \
        -c ${file(params.germline_somatic_config)} \
        -c ${projectDir}/modules/methods.config
    """
}


workflow {
    ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
        .map { [it.patient, [it.patient, it.sample, it.state, it.site, it.bam]] }
        .groupTuple(by:0)
    create_input_csv_germline_somatic(ich)
    call_germline_somatic(create_input_csv_germline_somatic.out[0])
}
