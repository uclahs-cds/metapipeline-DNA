
workflow recalibrate_BAM {
    take:
        ich
    main:
        if (params.sample_mode != 'single') {
            ich.flatten()
                .reduce(['normal': [], 'tumor': []]) { a, b ->
                    a[b.state] += b;
                    return a
                }
                .set{ collected_input_ch }
            skip_gsnp_output = collected_input_ch
        }
}










/*
    Main entry point for calling recalibrate-BAM pipeline
*/
include { create_normal_tumor_pairs; create_CSV_call_gSNP; create_CSV_recalibrate_BAM_single } from "${moduleDir}/create_CSV_recalibrate_BAM"
include { run_recalibrate_BAM } from "${moduleDir}/run_recalibrate_BAM"
include { flatten_nonrecursive } from "${moduleDir}/../functions"

/*
* Main workflow for calling the recalibrate-BAM pipeline
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
*     tumor_bam (file): Tumor's calibrated BAM file output by the recalibrate-BAM pipeline.
*     normal_bam (file): Normal's calibrated BAM file output by the recalibrate-BAM pipeline.
*/
workflow recalibrate_BAM {
    take:
        ich
    main:
        if (params.sample_mode != 'single') {
            flatten_nonrecursive(ich)
            flatten_nonrecursive.out.och
                .map{ it[0] }
                .map{ [[it['patient'], it['sample'], it['state'], it['bam_header_sm'], it['bam']]] }
                .collect()
                .set{ input_ch_create_pairs }
            create_normal_tumor_pairs(input_ch_create_pairs)
            skip_gsnp_output = create_normal_tumor_pairs.out.splitCsv(header:true)
                .map{ it -> [
                    'patient': it.patient,
                    'run_mode': 'multi',
                    'tumor_sample': it.tumor_sample,
                    'normal_sample': it.normal_sample,
                    'tumor_bam': it.tumor_bam,
                    'normal_bam': it.normal_bam
                ] }
            paired_info = create_normal_tumor_pairs.out.splitCsv(header:true)
                .map{
                    [it.patient, [it.patient, it.tumor_sample, it.normal_sample, it.tumor_bam_sm, it.normal_bam_sm, it.tumor_bam, it.normal_bam]]
                }

            if (params.sample_mode == 'multi') {
                input_ch_create_gsnp_csv = paired_info.groupTuple(by: 0) // Group and gather all records
            } else {
                input_ch_create_gsnp_csv = paired_info.map{ it ->
                    [it[0], [it[1]]] // Put each pair into tuple to match grouping operator
                }
            }

            create_CSV_call_gSNP(input_ch_create_gsnp_csv)
            ich_call_gsnp = create_CSV_call_gSNP.out
        } else {
            // In single sample mode, put file as normal regardless of actual state
            // to match call-gSNP processing
            skip_gsnp_output = ich.map{ it -> [
                'patient': it['patient'],
                'run_mode': it['state'],
                'tumor_sample': 'NO_SAMPLE',
                'normal_sample': it['sample'],
                'tumor_bam': file('/scratch/NO_FILE.bam'),
                'normal_bam': file(it['bam']).toRealPath()
                ] }

            ich_create_csv = ich
                .map{ [it['sample'], [it['patient'], it['sample'], it['state'], it['bam_header_sm'], it['bam']]] } // [sample, records]
                .groupTuple(by: 0)
                .map{ [it[1][0][0], it[1]] } // [patient, records]
            create_CSV_call_gSNP_single(ich_create_csv)
            ich_call_gsnp = create_CSV_call_gSNP_single.out
        }

        if (params.override_call_gsnp) {
            output_ch_call_gsnp = skip_gsnp_output
        } else {
            run_call_gSNP(ich_call_gsnp)

            if (params.sample_mode == 'multi') {
                /**
                *   For multi-sample calling, keep the patient, run_mode, normal_id, and normal_BAM
                *   then combine with each tumor BAM for downstream pipelines
                *   then derive the tumor sample name from the BAM
                */
                normal_ch_for_join = run_call_gSNP.out.full_output
                    .first()
                    .map{ [it[0], it[1], it[3], it[5]] } // [patient, run_mode, normal_id, normal_bam]

                output_ch_call_gsnp_flat = run_call_gSNP.out.tumor_bam
                    .flatten()
                    .combine(normal_ch_for_join)
                    .map{ [it[1], it[2], it[0].baseName.split('_')[-1], it[3], it[0], it[4]] }
            } else {
                output_ch_call_gsnp_flat = run_call_gSNP.out.full_output
            }

            output_ch_call_gsnp_flat
                .map{ it -> [
                    'patient': it[0],
                    'run_mode': it[1],
                    'tumor_sample': it[2],
                    'normal_sample': it[3],
                    'tumor_bam': it[4],
                    'normal_bam': it[5]
                ] }
                .set{ output_ch_call_gsnp }
        }

    emit:
        output_ch_call_gsnp = output_ch_call_gsnp
}
