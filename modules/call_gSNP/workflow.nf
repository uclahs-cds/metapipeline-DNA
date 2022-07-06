/*
    Main entry point for calling call-gSNP pipeline
*/
include { create_normal_tumor_pairs; create_input_csv_call_gSNP } from "${moduleDir}/create_input_csv"
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
        create_normal_tumor_pairs(ich)
        paired_info = create_normal_tumor_pairs.out.splitCsv(header:true)
            .map { [
                it.patient,
                it.tumor_sample, it.normal_sample,
                it.tumor_bam_sm, it.normal_bam_sm,
                it.tumor_bam,    it.normal_bam
            ] }
        create_input_csv_call_gSNP(paired_info)
        call_call_gSNP(create_input_csv_call_gSNP.out)
    emit:
        call_call_gSNP.out[0]
}