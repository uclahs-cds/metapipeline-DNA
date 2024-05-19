/*
    Main entry point for calling call-SRC pipeline
*/
include { create_YAML_call_SRC } from "${moduleDir}/create_YAML_call_SRC"
include { run_call_SRC } from "${moduleDir}/run_call_SRC" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
* Main workflow for calling the call-SRC pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow call_SRC {
    take:
        modification_signal
    main:
        // Watch for pipeline ordering
        // Channel.watchPath( "${params.pipeline_status_directory}/*.ready" )
        //     .until{ it -> it.name == "${params.this_pipeline}.ready" }
        //     .ifEmpty('done')
        //     .collect()
        //     .map{ 'done' }
        //     .set{ pipeline_predecessor_complete }

        // Extract inputs from data structure
        modification_signal.until{ it == 'done' }.ifEmpty('done')
            .collect()
            .map{ it ->
                def samples = [];
                params.sample_data.each { s, s_data ->
                    samples.add(['patient': s_data['patient'], 'sample': s, 'state': s_data['state'], 'src_input': s_data['original_data']]);
                };
                return samples
            }
            .flatten()
            .reduce(['normal': [] as Set, 'tumor': [] as Set]) { a, b ->
                a[b.state] += b;
                return a
            }
            .set{ ich }

        /**
        *   Call-SRC only runs on tumor samples so
        *   In multi-sample mode, pass all inputs together to pipeline
        *   In paired or single sample modes, pass each tumor individually to pipeline
        */
        if (params.sample_mode == 'multi') {
            input_ch_create_call_src_yaml = ich
        } else {
            ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

            input_ch_tumor.map{ it -> ['tumor': [it]] }
                .set{ input_ch_create_call_src_yaml }
        }

        create_YAML_call_SRC(input_ch_create_call_src_yaml)

        run_call_SRC(create_YAML_call_SRC.out.call_src_input)

        run_call_SRC.out.complete
            // .mix( pipeline_predecessor_complete )
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_call_SRC.out.exit_code
                    .map { it -> (it as Integer) }
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
