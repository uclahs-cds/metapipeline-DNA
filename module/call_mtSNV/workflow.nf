/*
* Module for calling the call-sSNV pipeline
*/

include { create_CSV_call_mtSNV } from "${moduleDir}/create_CSV_call_mtSNV"
include { run_call_mtSNV } from "${moduleDir}/run_call_mtSNV"

workflow call_mtSNV {
    take:
        ich
    main:
        ich
            .map{ it -> [it['patient'], it['run_mode'], it['tumor_sample'], it['normal_sample'], it['tumor_bam'], it['normal_bam']] }
            .set{ input_ch_create_CSV }
        create_CSV_call_mtSNV(input_ch_create_CSV)
        run_call_mtSNV(create_CSV_call_mtSNV.out)
}
