/*
    Main entry point for calling call-gSNP pipeline
*/
include { create_YAML_call_gSNP } from "${moduleDir}/create_YAML_call_gSNP"
include { run_call_gSNP } from "${moduleDir}/run_call_gSNP" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"
include { identify_call_gsnp_outputs } from "./identify_outputs"

/*
* Main workflow for calling the call-gSNP pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow call_gSNP {
    take:
        modification_signal
    main:
        if (!params.call_gSNP.is_pipeline_enabled) {
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .map{ it ->
                    def tools_to_move = ['HaplotypeCaller'];
                    params.sample_data.each { s, s_data ->
                        if (!(s_data["original_data"] instanceof Map)) {
                            return;
                        }
                        s_data["original_data"].getOrDefault("VCF", []).each { vcf_data ->
                            if (tools_to_move.contains(vcf_data['tool'])) {
                                s_data[params.this_pipeline][vcf_data['tool']] = vcf_data['vcf_path'];
                            }
                        }
                    };
                    System.out.println(params.sample_data);
                    mark_pipeline_complete(params.this_pipeline);
                    mark_pipeline_exit_code(params.this_pipeline, 0);
                    return 'done';
                }
                .set{ completion_signal }
        } else {
            // Watch for pipeline ordering
            Channel.watchPath( "${params.pipeline_status_directory}/*.ready" )
                .until{ it -> it.name == "${params.this_pipeline}.ready" }
                .ifEmpty('done')
                .collect()
                .map{ 'done' }
                .set{ pipeline_predecessor_complete }

            // Extract inputs from data structure
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .mix(pipeline_predecessor_complete)
                .collect()
                .map{ it ->
                    def samples = [];
                    params.sample_data.each { s, s_data ->
                        samples.add(['patient': s_data['patient'], 'sample': s, 'state': s_data['state'], 'bam': s_data['recalibrate-BAM']['BAM']]);
                    };
                    return samples
                }
                .flatten()
                .reduce(['normal': [] as Set, 'tumor': [] as Set]) { a, b ->
                    a[b.state] += b;
                    return a
                }
                .set{ ich }

            if (params.sample_mode != 'single') {
                if (params.sample_mode == 'multi') {
                    input_ch_create_call_gsnp_yaml = ich
                } else {
                    ich.map{ it -> it.normal }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_normal }
                    ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

                    input_ch_normal.combine(input_ch_tumor).map{ it ->
                        ['normal': [it[0]], 'tumor': [it[1]]]
                    }
                    .set{ input_ch_create_call_gsnp_yaml }
                }
            } else {
                ich.map{ it -> it.normal }
                    .flatten()
                    .map{ it -> ['normal': [it], 'tumor': []] }
                    .set{ input_ch_normal }
                ich.map{ it -> it.tumor }
                    .flatten()
                    .map{ it -> ['normal': [], 'tumor': [it]] }
                    .set{ input_ch_tumor }

                input_ch_normal.mix(input_ch_tumor).set{ input_ch_create_call_gsnp_yaml }
            }

            create_YAML_call_gSNP(input_ch_create_call_gsnp_yaml)

            run_call_gSNP(create_YAML_call_gSNP.out.call_gsnp_input)

            identify_call_gsnp_outputs(
                modification_signal.until{ it == 'done' }
                    .mix( run_call_gSNP.out.identify_call_gsnp_out )
            )

            run_call_gSNP.out.complete
                .mix( identify_call_gsnp_outputs.out.och_call_gsnp_identified )
                .mix( pipeline_predecessor_complete )
                .collect()
                .map{ it ->
                    mark_pipeline_complete(params.this_pipeline);
                    return 'done';
                }
                .mix(
                    run_call_gSNP.out.exit_code
                        .map{ it -> (it as Integer) }
                        .sum()
                        .map { exit_code ->
                            mark_pipeline_exit_code(params.this_pipeline, exit_code);
                            return 'done';
                        }
                )
                .collect()
                .map { it -> return 'done'; }
                .set{ completion_signal }
        }

    emit:
        completion_signal = completion_signal
}
