/*
    Main entry point for calling call-gSNP pipeline
*/
include { create_YAML_call_gSNP } from "${moduleDir}/create_YAML_call_gSNP"
include { run_call_gSNP } from "${moduleDir}/run_call_gSNP"

/*
* Main workflow for calling the call-gSNP pipeline
*
* Input:
*   Input is a channel with each element 
*/
workflow call_gSNP {
    take:
        ich
    main:
        ich.flatten()
            .reduce(['normal': [] as Set, 'tumor': [] as Set]) { a, b ->
                a[b.state] += b;
                return a
            }
            .set{ collected_input_ch }

        if (params.sample_mode != 'single') {
            if (params.sample_mode == 'multi') {
                input_ch_create_call_gsnp_yaml = collected_input_ch
            } else {
                collected_input_ch.map{ it -> it.normal }.flatten().set{ input_ch_normal }
                collected_input_ch.map{ it -> it.tumor }.flatten().set{ input_ch_tumor }

                input_ch_normal.combine(input_ch_tumor).map{ it ->
                    ['normal': [it[0]], 'tumor': [it[1]]]
                }
                .set{ input_ch_create_call_gsnp_yaml }
            }
        } else {
            collected_input_ch.map{ it -> it.normal }
                .flatten()
                .map{ it -> ['normal': [it], 'tumor': []] }
                .set{ input_ch_normal }
            collected_input_ch.map{ it -> it.tumor }
                .flatten()
                .map{ it -> ['normal': [], 'tumor': [it]] }
                .set{ input_ch_tumor }

            input_ch_normal.mix(input_ch_tumor).set{ input_ch_create_call_gsnp_yaml }
        }

        create_YAML_call_gSNP(input_ch_create_call_gsnp_yaml)

        run_call_gSNP(create_YAML_call_gSNP.out.call_gsnp_input)
}
