/*
* Main entrypoint for the align-DNA module.
*
* Input:
*   A tuple that containes five objects, patient (string), sample (string), state (string), site
*     (string), and input csv (path). The input channel is directly passed to the call_align_DNA
*     process to call the align-DNA pipeline.
*    
* Output:
*   A tuple with patient, sample, state, site, and the aligned BAM.
*/

include { call_align_DNA } from "${moduleDir}/call_align_DNA"

workflow align_DNA {
    take:
        ich
    main:
        call_align_DNA(ich)
    emit:
        call_align_DNA.out[0]
}