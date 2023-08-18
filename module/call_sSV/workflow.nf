/*
    Main entrypoint for calling call-gSV pipeline
*/

include { create_CSV_call_sSV } from "${moduleDir}/create_CSV_call_sSV"
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
        // Call-sSV only supports paired mode so run only when not in single mode
        if (params.sample_mode != 'single') {
            ich.map{ it -> it.normal }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_normal }
            ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

            input_ch_normal.combine(input_ch_tumor).map{ it ->
                ['normal': it[0], 'tumor': it[1]]
            }.map{ it ->
                [
                    it['tumor']['sample'],
                    file(it['normal']['bam'].toRealPath()),
                    file(it['tumor']['bam'].toRealPath())
                ]
            }
            .set{ input_ch_create_CSV }

            create_CSV_call_sSV(input_ch_create_CSV)
            run_call_sSV(create_CSV_call_sSV.out)
        }
}
