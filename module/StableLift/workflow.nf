/*
    Main entry point for calling StableLift pipeline
*/
include { create_YAML_StableLift } from "${moduleDir}/create_YAML_StableLift"
include { run_StableLift } from "${moduleDir}/run_StableLift" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
* Main workflow for calling the StableLift pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow stable_lift {
    take:
        modification_signal
    main:
        // Extract inputs from data structure
        modification_signal.until{ it == 'done' }.ifEmpty('done')
            .collect()
            .map{ it ->
                def samples = [];
                params.sample_data.each { s, s_data ->
                    params.StableLift.lift_modes.each { raw_mode ->
                        def mode = raw_mode.replace('StableLift', '');
                        if (!s_data.containsKey("call-${mode}" as String)) {
                            return;
                        }
                        s_data["call-${mode}"].each { tool, data ->
                            if (['BCFtools-Intersect', 'Manta-gSV', 'Manta-sSV'].contains(tool)) {
                                return;
                            }
                            samples.add([
                                'mode': mode,
                                'tool': tool.replace('MuSE', 'Muse2'),
                                'path': data,
                                'sample': s,
                                'patient': s_data['patient']
                            ]);
                        };
                    };
                };
                return samples;
            }
            .flatten()
            .set{ input_ch_create_stablelift_yaml }

        create_YAML_StableLift(input_ch_create_stablelift_yaml)

        run_StableLift(create_YAML_StableLift.out.stablelift_input)

        run_StableLift.out.complete
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_StableLift.out.exit_code
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
