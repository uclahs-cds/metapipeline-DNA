/*
* Module for calling the call-sSNV pipeline
*/

include { create_input_csv } from "${moduleDir}/create_input_csv"
include { call_call_mtSNV } from "${moduleDir}/call_call_mtSNV"

workflow call_mtSNV {
    take:
        ich
    main:
        create_input_csv(ich)
        call_call_mtSNV(create_input_csv.out)
}