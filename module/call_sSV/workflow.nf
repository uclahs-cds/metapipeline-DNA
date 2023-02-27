/*
    Main entrypoint for calling call-gSV pipeline
*/

include { create_input_csv_call_sSV } from "${moduleDir}/create_input_csv"
include { run_call_sSV } from "${moduleDir}/run_call_sSV"

/*
* Main workflow for calling the call-sSV pipeline
*
* Input:
*   Input is a channel where each element is a tuple of list of 6 items:
*     @param patient (String): Patient ID
*     @param run_mode (String): Indicator of type of sample
*     @param tumor_sample (String): Tumor sample name
*     @param normal_sample (String): Normal sample name
*     @param tumor_bam (file): Path to tumor BAM
*     @param normal_bam (file): Path to normal BAM
*/
workflow call_sSV {
    take:
        ich
    main:
        // Call-sSV only supports paired mode so filter only for 'multi'
        ich
            .filter{ it['run_mode'] == 'multi' }
            .map{ [it['tumor_sample'], file(it['normal_bam']).toRealPath(), file(it['tumor_bam']).toRealPath()] }
            .set{ input_ch_create_csv }

        create_input_csv_call_sSV(input_ch_create_csv)

        create_input_csv_call_sSV.out
            .combine( Channel.of( params.call_sSV.algorithm.join(',') ) )
            .set{ input_ch_call_ssv }

        run_call_sSV(input_ch_call_ssv)
}
