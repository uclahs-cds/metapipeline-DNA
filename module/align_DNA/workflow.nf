/*
* Main entrypoint for the align-DNA module.
*
* Input:
*   A tuple that containes five objects, patient (string), sample (string), state (string),
*   and input csv (path). The input channel is directly passed to the call_align_DNA
*   process to call the align-DNA pipeline.
*    
* Output:
*   A tuple with patient, sample, state, and the aligned BAM.
*/

include { create_CSV_align_DNA } from "./create_CSV_align_DNA" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { call_align_DNA } from "./call_align_DNA"
include { mark_pipeline_complete } from "../pipeline_status"
include { identify_align_dna_outputs } from "./identify_outputs"

workflow align_DNA {
    take:
        modification_signal
    main:
        if (params.override_realignment) {
            // ich.map{ it -> [
            //     'patient': it[0],
            //     'sample': it[1],
            //     'state': it[2],
            //     'bam': it[3]
            //     ] }
            //     .set{ output_ch_align_dna }

            modification_signal.until{ it == 'done' }
                .map{ it ->
                    params.sample_data.each { s, s_data ->
                        s_data['align-DNA'].each {a, a_data ->
                            a_data['BAM'] = s_data['original_data']['path']
                        }
                    };
                    mark_pipeline_complete('align-DNA');
                    println params.sample_data;
                    return 'done'
                }
                .set{ alignment_sample_data_updated }
        } else {
            // Extract inputs from data structure
            modification_signal.until{ it == 'done' }
                .map{ it ->
                    def samples = [];
                    params.sample_data.each { s, s_data ->
                        def data_source = 'original_data'
                        if (params.convert_BAM2FASTQ.is_pipeline_enabled) {
                            data_source = 'convert-BAM2FASTQ'
                        }
                        s_data[data_source].each{ rg ->
                            samples.add(rg + ['sample': s, 'state': s_data['state']]);
                        };
                    };
                    return samples
                }
                .flatten()
                .map{ rg_info ->
                    [rg_info.sample, [
                        rg_info.state,
                        rg_info.read_group_identifier.
                        rg_info.sequencing_center,
                        rg_info.library_identifier,
                        rg_info.platform_technology,
                        rg_info.platform_unit,
                        rg_info.sample,
                        rg_info.lane,
                        rg_info.read1_fastq,
                        rg_info.read2_fastq
                    ]]
                }
                .groupTuple(by: 0)
                .set{ ich_create_csv }

            // Create align-DNA input CSV
            create_CSV_align_DNA(ich_create_csv)

            // Run align-DNA
            call_align_DNA(create_CSV_align_DNA.out.align_dna_csv)

            // Identify outputs
            identify_align_dna_outputs(call_align_DNA.out.align_dna_output_directory)
            println params.sample_data


            identify_align_dna_outputs.out.och_align_dna_outputs_identified
                .collect()
                .map{
                    println params.sample_data;
                    mark_pipeline_complete('align-DNA');
                    return 'done'
                }
                .set{ alignment_sample_data_updated }
        }
    emit:
        alignment_sample_data_updated = alignment_sample_data_updated
}
