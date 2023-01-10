/*
    Main entrypoint for calling call-gSV pipeline
*/

include { create_input_csv_call_gSV } from "${moduleDir}/create_input_csv"
include { call_call_gSV } from "${moduleDir}/call_call_gSV"

/*
* Main workflow for calling the call-gSV pipeline
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
workflow call_gSV {
    take:
        ich
    main:
        if (params.sample_mode == 'single') {
            // Single sample mode always has BAM in normal
            ich
                .filter{ it['run_mode'] == 'normal' }
                .map{ [it['patient'], it['normal_sample'], it['normal_bam']] }
                .set{ input_ch_create_csv }
        } else {
            // Get normal sample from first emission since normal sample is common for all emissions
            ich
                .first()
                .map{ [it['patient'], it['normal_sample'], it['normal_bam']] }
                .set{ input_ch_create_csv }
        }

        create_input_csv_call_gSV(input_ch_create_csv)

        call_call_gSV(create_input_csv_call_gSV.out)
}
