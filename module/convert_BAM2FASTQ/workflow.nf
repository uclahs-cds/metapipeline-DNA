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
include { extract_read_groups } from './extract_read_groups.nf'
include { create_input_csv } from './create_input_csv.nf'
include { create_input_csv_for_align_DNA } from './create_input_csv_for_align_DNA.nf'

workflow convert_BAM2FASTQ {
    main:
        ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
            .map { tuple(it.patient, it.sample, it.state, file(it.bam)) }
        extract_read_groups(ich)
        create_input_csv(ich)        
        call_convert_BAM2FASTQ(create_input_csv.out[0])
        
        data_ch = call_convert_BAM2FASTQ.out[0].map { [it[1], it] }
            .join(extract_read_groups.out[0].map { [it[1], it] })
            .map { tuple(it[1][0], it[1][1], it[1][2], it[2][3], it[1][3]) }

        create_input_csv_for_align_DNA(data_ch)
    
    emit:
        create_input_csv_for_align_DNA.out[0]
}