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

include { call_align_DNA } from "${moduleDir}/call_align_DNA"

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
