/*
    Main entrypoint for calling call-sSV pipeline
*/

include { create_YAML_call_sSV } from "${moduleDir}/create_YAML_call_sSV"
include { run_call_sSV } from "${moduleDir}/run_call_sSV" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"
include { identify_call_ssv_outputs } from "./identify_outputs"

/*
* Main workflow for calling the call-sSV pipeline
*
* Input:
*   Input is a channel where each element is a tuple of list of 6 items:
*     @param patient (String): Patient ID
*     @param run_mode (String): Indicator of type of sample
*     @param tumor_sample (String): Tumor sample name
*     @param normal_sample (String): Normal sample name
*     @param tumor_bam (file): Path to tumor BAM
*     @param normal_bam (file): Path to normal BAM
*/
workflow call_sSV {
    take:
        modification_signal

    main:
        completion_signal = Channel.of('done')
        completion_signal.collect().map{ 0 }.set{ exit_code_ich }

        // Call-sSV only supports paired mode so run only when not in single mode
        if (params.sample_mode != 'single' && params.call_sSV.is_pipeline_enabled) {
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

            ich.map{ it -> it.normal }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_normal }
            ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

            input_ch_normal.combine(input_ch_tumor).map{ it ->
                ['normal': it[0], 'tumor': it[1]]
            }.map{ it ->
                [
                    it['tumor']['sample'],
                    file(it['normal']['bam']).toRealPath(),
                    file(it['tumor']['bam']).toRealPath()
                ]
            }
            .set{ input_ch_create_YAML }

            create_YAML_call_sSV(input_ch_create_YAML)
            run_call_sSV(create_YAML_call_sSV.out)

            identify_call_ssv_outputs(
                modification_signal.until{ it == 'done' }
                    .mix( run_call_sSV.out.identify_call_ssv_out )
            )

            run_call_sSV.out.complete
                .mix(completion_signal)
                .mix( identify_call_ssv_outputs.out.och_call_ssv_identified )
                .set{ completion_signal }
            run_call_sSV.out.exit_code
                .mix( exit_code_ich )
                .set{ exit_code_ich }
        }

        completion_signal
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                exit_code_ich
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

    emit:
        completion_signal = completion_signal
}
