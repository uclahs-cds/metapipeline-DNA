/*
* Main entrypoint for the convert-BAM2FASTQ workflow module
*
* This module is implemented in a ways that each process takes a tuple as input includes the
* patient, sample, state, and also output these values in a tuple. The reason is that we
* need to know the state information in call-gSNP and call-sSNV. Nextflow's channel isn't
* too smart, as samples may mix with the wrong labels otherwise.
*    
* params:
*   params.input_csv (String): The path to the input csv file.
*
* output:
*   A tuple of five elements, patient, sample, state, and the input_csv file for align-DNA 
*/

include { call_convert_BAM2FASTQ } from './call_convert_BAM2FASTQ'
include { extract_read_groups } from './extract_read_groups'
include { create_CSV_BAM2FASTQ } from './create_CSV_BAM2FASTQ'
include { create_CSV_align_DNA } from './create_CSV_align_DNA'
include { mark_pipeline_complete } from '../pipeline_status'
include { identify_convert_bam2fastq_outputs } from './identify_outputs'

workflow convert_BAM2FASTQ {
    main:
        ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
            .map { tuple(it.patient, it.sample, it.state, file(it.bam)) }
        extract_read_groups(ich)
        create_CSV_BAM2FASTQ(ich)
        call_convert_BAM2FASTQ(create_CSV_BAM2FASTQ.out[0])
        
        data_ch = call_convert_BAM2FASTQ.out[0].map { [it[1], it] }
            .join(extract_read_groups.out[0].map { [it[1], it] })
            .map { tuple(it[1][0], it[1][1], it[1][2], it[2][3], it[1][3]) }

        data_ch2 = call_convert_BAM2FASTQ.out[0].map { [it[1], it] }
            .join(extract_read_groups.out[0].map { [it[1], it] })
            .map { tuple(it[1][0], it[1][1], it[1][2], it[2][3], it[1][4]) }

        identify_convert_bam2fastq_outputs(data_ch2)

        println params.sample_data

        identify_convert_bam2fastq_outputs.out.och_bam2fastq_outputs_identified.collect().map{ println params.sample_data; mark_pipeline_complete('convert-BAM2FASTQ'); return 'done' }

        create_CSV_align_DNA(data_ch)
    emit:
        create_CSV_align_DNA.out[0]
}
