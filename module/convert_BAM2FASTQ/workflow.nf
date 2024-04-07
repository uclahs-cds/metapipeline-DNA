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
        ich = Channel.fromPath(params.input_csv).splitCsv(header:true)
            .map { [it.sample, [it.patient, it.sample, it.state, file(it.bam)]] }
            // For samples with the same sample_id, append a suffix to the output
            // directory so they won't override each other.
            .groupTuple(by:0)
            .flatMap { sample, records ->
                records.eachWithIndex { it, i ->
                    it.add(records.size() > 1 ? "-${i + 1}": '')
                }
                return records
            }
            // [ patient, sample, state, bam, suffix ]
        extract_read_groups(ich)
        create_CSV_BAM2FASTQ(ich)
        call_convert_BAM2FASTQ(create_CSV_BAM2FASTQ.out.convert_bam2fastq_csv)

        data_ch = call_convert_BAM2FASTQ.out[0]
            // [patient, sample, state, [fastq], output_dir, bam]
            .map { [it[5].toRealPath(), it] }
            .join(
                // [patient, sample, state, read_group_csv, bam]
                extract_read_groups.out[0].map { [it[4].toRealPath(), it] }
            )
            // [bam, [patient, sample, state, [fastq], output_dir, bam], [patient, sample, state, read_group_csv, bam]]
            .map { [it[1][1], [it[1][0], it[1][1], it[1][2], it[2][3], it[1][4]]] }
            // [sample, [patient, sample, state, read_group_csv, output_dir]]
            .groupTuple(by:0)
            // [sample, [[patient, sample, state, read_group_csv, output_dir]]]
            .map { sample, records ->
                def patient = records[0][0]
                def state = records[0][2]
                def read_group_and_output_dir = []
                records.each { it ->
                    assert it[0] == patient
                    assert it[2] == state
                    read_group_and_output_dir.add([it[3], it[4]])
                }
                return [patient, sample, state, read_group_and_output_dir]
            }

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
