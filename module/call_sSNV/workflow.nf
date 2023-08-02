/*
    Main entry point for calling call-sSNV pipeline
*/
include { create_YAML_call_sSNV } from "${moduleDir}/create_YAML_call_sSNV"
include { run_call_sSNV } from "${moduleDir}/run_call_sSNV"

/*
* Main workflow for calling the call-sSNV pipeline
*
* Input:
*   Input is a channel that each element is a tuple or list of 6 items:
*     @param patient (String): Patient ID
*     @param run_mode (String): Indicator of type of sample
*     @param tumor_sample (String): Tumor sample name
*     @param normal_sample (String): Normal sample name
*     @param tumor_bam (file): Path to tumor BAM
*     @param normal_bam (file): Path to normal BAM
*/
workflow call_sSNV {
    take:
        ich
    main:
        if (params.sample_mode == 'single') {
            // Only Mutect2 supports tumor-only calling
            if ('mutect2' in params.call_sSNV.algorithm) {
                input_ch_tumor_only = ich
                    .filter{ it['run_mode'] == 'tumor' }
                    .map{ [it['normal_sample'], [['NO_ID', 'NO_BAM.bam']], [[it['normal_sample'], file(it['normal_bam']).toRealPath()]], 'mutect2'] }
            } else {
                input_ch_tumor_only = Channel.empty()
            }
            create_YAML_call_sSNV(input_ch_tumor_only)
        } else {
            // [patient, [normal_ID,normal_BAM], [tumor_ID,tumor_BAM]]
            input_ch_create_ssnv_yaml_multisample = ich.map{ it ->
                [it['patient'], [[it['normal_sample'], file(it['normal_bam']).toRealPath()]], [it['tumor_sample'], file(it['tumor_bam']).toRealPath()]]
            }.groupTuple(by: [0,1])

            // [sample_id, normal_BAM, [tumor_BAM]]
            input_ch_create_ssnv_yaml_pairedsample = ich.map{ it ->
                [it['tumor_sample'], [[it['normal_sample'], file(it['normal_bam']).toRealPath()]], [[it['tumor_sample'], file(it['tumor_bam']).toRealPath()]]]
            }

            input_ch_create_ssnv_yaml = Channel.empty()
            requested_ssnv_algorithms = params.call_sSNV.algorithm

            if ( params.sample_mode == 'multi' &&
                'mutect2' in requested_ssnv_algorithms &&
                (params.normal_sample_count > 1 || params.tumor_sample_count > 1) ) {
                input_ch_create_ssnv_yaml = input_ch_create_ssnv_yaml_multisample
                    .combine( Channel.of( ['mutect2'] ) )

                requested_ssnv_algorithms.removeAll{ it == 'mutect2' }
            }

            if ( !requested_ssnv_algorithms.isEmpty() ) {
                input_ch_create_ssnv_yaml = input_ch_create_ssnv_yaml_pairedsample
                    .combine( Channel.of( requested_ssnv_algorithms ) )
                    .mix( input_ch_create_ssnv_yaml )
            }

            create_YAML_call_sSNV(input_ch_create_ssnv_yaml)
        }
        run_call_sSNV(create_YAML_call_sSNV.out)
}
