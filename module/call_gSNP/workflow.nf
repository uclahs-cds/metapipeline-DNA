/*
    Main entry point for calling call-gSNP pipeline
*/
include { create_normal_tumor_pairs; create_input_csv_call_gSNP; create_input_csv_call_gSNP_single } from "${moduleDir}/create_input_csv"
include { call_call_gSNP } from "${moduleDir}/call_call_gSNP"

/*
* Main workflow for calling the call-gSNP pipeline
*
* Input:
*   Input is a channel that each element is a tuple or list of 6 items:
*     @param patient (String): Patient ID
*     @param sample (String): Sample ID
*     @param state (String): Must be either normal or tumor.
*     @param bam_header_sm (String): The SM tag value in the BAM header.
*     @param bam (file): Path to the BAM file.
* 
* Ouput:
*   @return A tuple of 7 items:
*     patient (String): Patient ID
*     tumor_sample (String): Sample ID of the tumor sample.
*     normal_sample (String): Sample ID of the nomral sample.
*     tumor_bam (file): Tumor's calibrated BAM file output by the call-gSNP pipeline.
*     normal_bam (file): Normal's calibrated BAM file output by the call-gSNP pipeline.
*/
workflow call_gSNP {
    take:
        ich
    main:
        if (params.sample_mode != 'single') {
            create_normal_tumor_pairs(ich)
            paired_info = create_normal_tumor_pairs.out.splitCsv(header:true)
                .map{
                    [it.patient, [it.patient, it.tumor_sample, it.normal_sample, it.tumor_bam_sm, it.normal_bam_sm, it.tumor_bam, it.normal_bam]]
                }

            if (params.sample_mode == 'multi') {
                input_ch_create_gsnp_csv = paired_info.groupTuple(by: 0)
            } else {
                input_ch_create_gsnp_csv = paired_info.map{ it ->
                    [it[0], [it[1]]]
                }
            }

            create_input_csv_call_gSNP(input_ch_create_gsnp_csv)
            ich_call_gsnp = create_input_csv_call_gSNP.out
        } else {
            ich_create_csv = ich
                .map{ [it[1], it] } // [sample, records]
                .groupTuple(by: 0)
                .map{ [it[1][0][0], it[1]] } // [patient, records]
            create_input_csv_call_gSNP_single(ich_create_csv)
            ich_call_gsnp = create_input_csv_call_gSNP_single.out
        }
        call_call_gSNP(ich_call_gsnp)

        if (params.sample_mode == 'multi') {
            /**
            *   For multi-sample calling, keep the patient, run_mode, tumor_id, normal_id, and normal_BAM
            *   then combine with each tumor BAM for downstream pipelines
            */
            normal_ch_for_join = call_call_gSNP.out.full_output
                .first()
                .map{ [it[0], it[1], it[2], it[3], it[5]] }

            output_ch_call_gsnp = call_call_gSNP.out.tumor_bam
                .flatten()
                .combine(normal_ch_for_join)
                .map{ [it[1], it[2], it[3], it[4], it[0], it[5]] }
        } else {
            output_ch_call_gsnp = call_call_gSNP.out.full_output
        }
    emit:
        output_ch_call_gsnp
}
