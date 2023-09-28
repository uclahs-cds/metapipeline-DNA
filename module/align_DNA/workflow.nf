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

include { call_align_DNA } from "./call_align_DNA"
include { mark_pipeline_complete } from "../pipeline_status"
include { identify_align_dna_outputs } from "./identify_outputs"

workflow align_DNA {
    take:
        ich
    main:
        if (params.override_realignment) {
            ich.map{ it -> [
                'patient': it[0],
                'sample': it[1],
                'state': it[2],
                'bam': it[3]
                ] }
                .set{ output_ch_align_dna }
        } else {
            call_align_DNA(ich)
            identify_align_dna_outputs(call_align_DNA.out.align_dna_output_directory)
            println params.sample_data
            identify_align_dna_outputs.out.och_align_dna_outputs_identified.collect().map{ println params.sample_data; mark_pipeline_complete('align-DNA'); return 'done' }
            call_align_DNA.out.metapipeline_out
                .map{ it -> [
                    'patient': it[0],
                    'sample': it[1],
                    'state': it[2],
                    'bam': it[3]
                ] }
                .set{ output_ch_align_dna }
        }
    emit:
        output_ch_align_dna = output_ch_align_dna
}
