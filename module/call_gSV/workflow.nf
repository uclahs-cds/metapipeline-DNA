/*
    Main entrypoint for calling call-gSV pipeline
*/

include { create_YAML_call_gSV } from "${moduleDir}/create_YAML_call_gSV"
include { run_call_gSV } from "${moduleDir}/run_call_gSV" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"
include { identify_call_gsv_outputs } from "./identify_outputs"

/*
* Main workflow for calling the call-gSV pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow call_gSV {
    take:
        modification_signal
    main:
        if (!params.call_gSV.is_pipeline_enabled) {
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .map{ it ->
                    def tools_to_move = ['Manta-gSV', 'Delly2-gSV'];
                    params.sample_data.each { s, s_data ->
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

            ich
                .map{ it -> it.normal }
                .flatten()
                .unique{ [it.patient, it.sample, it.state] }
                .map{ it -> [params.patient, it['sample'], it['bam']] }
                .set{ input_ch_create_YAML }

            create_YAML_call_gSV(input_ch_create_YAML)

            run_call_gSV(create_YAML_call_gSV.out.call_gsv_yaml)

            identify_call_gsv_outputs(
                modification_signal.until{ it == 'done' }
                    .mix( run_call_gSV.out.identify_call_gsv_out )
            )

            run_call_gSV.out.complete
                .mix( identify_call_gsv_outputs.out.och_call_gsv_identified )
                .mix( pipeline_predecessor_complete )
                .collect()
                .map{ it ->
                    mark_pipeline_complete(params.this_pipeline);
                    return 'done';
                }
                .mix(
                    run_call_gSV.out.exit_code
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
