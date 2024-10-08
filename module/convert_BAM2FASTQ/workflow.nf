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

include { call_convert_BAM2FASTQ } from './call_convert_BAM2FASTQ' addParams( log_output_dir: params.metapipeline_log_output_dir )
include { extract_read_groups } from './extract_read_groups' addParams( log_output_dir: params.metapipeline_log_output_dir )
include { create_CSV_BAM2FASTQ } from './create_CSV_BAM2FASTQ' addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete } from '../pipeline_status'
include { identify_convert_bam2fastq_outputs } from './identify_outputs'

workflow convert_BAM2FASTQ {
    main:
        List samples = [];
        params.sample_data.each { s, s_data ->
            samples << ['patient': s_data.patient, 'sample': s, 'state': s_data.state, 'bam': s_data.original_data.path]
        }

        ich = Channel.from(samples)
            .map{ tuple(it.patient, it.sample, it.state, file(it.bam)) }

        extract_read_groups(ich)
        create_CSV_BAM2FASTQ(ich)
        call_convert_BAM2FASTQ(create_CSV_BAM2FASTQ.out.convert_bam2fastq_csv)

        data_ch = call_convert_BAM2FASTQ.out[0].map { [it[1], it] }
            .join(extract_read_groups.out[0].map { [it[1], it] })
            .map { tuple(it[1][0], it[1][1], it[1][2], it[2][3], it[1][4]) }

        identify_convert_bam2fastq_outputs(data_ch)

        identify_convert_bam2fastq_outputs.out.och_bam2fastq_outputs_identified
            .collect()
            .map{
                mark_pipeline_complete(params.this_pipeline);
                return 'done'
            }
            .set{ bam2fastq_sample_data_updated }

    emit:
        bam2fastq_sample_data_updated = bam2fastq_sample_data_updated
}
