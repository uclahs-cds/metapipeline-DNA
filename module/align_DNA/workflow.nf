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
        ich.view{"inaligndnabefore: $it"}
        call_align_DNA(ich)
        call_align_DNA.out[0].view{"inaligndnaafter: $it"}
    emit:
        call_align_DNA.out[0]
}