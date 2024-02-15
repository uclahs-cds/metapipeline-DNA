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
include { sanitize_string } from "../../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

workflow align_DNA {
    take:
        modification_signal
    main:
        if (params.override_realignment) {
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .map{ it ->
                    params.sample_data.each { s, s_data ->
                        s_data['align-DNA'].each {a, a_data ->
                            a_data['BAM'] = s_data['original_data']['path']
                        }
                    };
                    mark_pipeline_complete('align-DNA');
                    return 'done'
                }
                .set{ alignment_sample_data_updated }
        } else {
            // Extract inputs from data structure
            modification_signal.until{ it == 'done' }.ifEmpty('done')
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
                .map{ it ->
                    [it.sample, [
                        it.state,
                        sanitize_string(it.read_group_identifier),
                        sanitize_string(it.sequencing_center),
                        sanitize_string(it.library_identifier),
                        sanitize_string(it.platform_technology),
                        sanitize_string(it.platform_unit),
                        it.sample,
                        sanitize_string(it.lane),
                        it.read1_fastq,
                        it.read2_fastq
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

            identify_align_dna_outputs.out.och_align_dna_outputs_identified
                .collect()
                .map{
                    mark_pipeline_complete('align-DNA');
                    return 'done'
                }
                .set{ alignment_sample_data_updated }
        }
    emit:
        alignment_sample_data_updated = alignment_sample_data_updated
}
