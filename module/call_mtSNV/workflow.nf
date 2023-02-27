/*
* Module for calling the call-sSNV pipeline
*/

include { create_input_csv } from "${moduleDir}/create_input_csv"
include { run_call_mtSNV } from "${moduleDir}/run_call_mtSNV"

workflow call_mtSNV {
    take:
        ich
    main:
        ich
            .map{ it -> [it['patient'], it['run_mode'], it['tumor_sample'], it['normal_sample'], it['tumor_bam'], it['normal_bam']] }
            .set{ input_ch_create_csv }
        create_input_csv(input_ch_create_csv)
        run_call_mtSNV(create_input_csv.out)
}
