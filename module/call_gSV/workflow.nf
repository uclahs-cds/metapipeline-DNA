/*
    Main entrypoint for calling call-gSV pipeline
*/

include { create_CSV_call_gSV } from "${moduleDir}/create_CSV_call_gSV"
include { run_call_gSV } from "${moduleDir}/run_call_gSV"

/*
* Main workflow for calling the call-gSV pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow call_gSV {
    take:
        ich
    main:
        ich
            .map{ it -> it.normal }
            .flatten()
            .unique{ [it.patient, it.sample, it.state] }
            .map{ it -> [params.patient, it['sample'], it['bam']] }
            .set{ input_ch_create_CSV }

        create_CSV_call_gSV(input_ch_create_CSV)

        run_call_gSV(create_CSV_call_gSV.out)
}
