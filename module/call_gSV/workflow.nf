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
        // Get normal sample
        ich
            .first()
            .map{ [it[0], it[3], it[5]] } // [patient, sample, BAM]
            .set{ input_ch_create_csv_normal }

        // Tumor samples
        ich
            .map{ [it[0], it[2], it[4]] } // [patient, sample, BAM]
            .set{ input_ch_create_csv_tumor }

        create_input_csv_call_gSV(
            input_ch_create_csv_normal.mix(input_ch_create_csv_tumor)
        )

        call_call_gSV(create_input_csv_call_gSV.out)
}
