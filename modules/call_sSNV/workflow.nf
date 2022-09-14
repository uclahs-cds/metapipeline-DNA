/*
    Main entry point for calling call-sSNV pipeline
*/
include { create_input_yaml_call_sSNV } from "${moduleDir}/create_input_yaml"
include { call_call_sSNV } from "${moduleDir}/call_call_sSNV"

/*
* Main workflow for calling the call-gSNP pipeline
*
* Input:
*   Input is a channel that each element is a tuple or list of 6 items:
*     @param patient (String): Patient ID
*     @param tumor_sample (String): Tumor sample name
*     @param normal_sample (String): Normal sample name
*     @param tumor_bam (file): Path to tumor BAM
*     @param normal_bam (file): Path to normal BAM
*/
workflow call_sSNV {
    take:
        ich
    main:
        // [patient, normal_BAM, tumor_BAM]
        input_ch_create_ssnv_yaml_multisample = ich.map{ it ->
            [it[0], it[4], it[3]]
        }.groupTuple(by: [0,1])

        // [sample_id, normal_BAM, [tumor_BAM]]
        input_ch_create_ssnv_yaml_pairedsample = ich.map{ it ->
            (params.multi_sample_calling) ? \
                [it[3].baseName.replace('_realigned_recalibrated_merged_dedup', ''), it[4], [it[3]]] : \
                [it[1], it[4], [it[3]]]
        }


        input_ch_create_ssnv_yaml = Channel.empty()
        requested_ssnv_algorithms = params.call_sSNV.algorithm

        if ( params.multi_sample_calling && 'mutect2' in requested_ssnv_algorithms ) {
            input_ch_create_ssnv_yaml = input_ch_create_ssnv_yaml_multisample
                .combine( Channel.of( 'mutect2' ) )

            requested_ssnv_algorithms.removeAll{ it == 'mutect2' }
        }

        if ( !requested_ssnv_algorithms.isEmpty() ) {
            input_ch_create_ssnv_yaml = input_ch_create_ssnv_yaml_pairedsample
                .combine( Channel.of( requested_ssnv_algorithms.join(',') ) )
                .mix( input_ch_create_ssnv_yaml )
        }

        create_input_yaml_call_sSNV(input_ch_create_ssnv_yaml)

        call_call_sSNV(create_input_yaml_call_sSNV.out)

}
