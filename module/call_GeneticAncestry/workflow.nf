/*
    Main entry point for annotating variants
*/
include { create_YAML_call_GeneticAncestry } from "${moduleDir}/create_YAML_call_GeneticAncestry"
include { run_call_GeneticAncestry } from "${moduleDir}/run_call_GeneticAncestry" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
*   Main workflow for annotating variants
*/
workflow call_GeneticAncestry {
    take:
        modification_signal
    main:
        // Extract inputs from data structure
        modification_signal.until{ it == 'done' }.ifEmpty('done')
            .collect()
            .map{ it ->
                def samples = [];
                params.sample_data.each { s, s_data ->
                    if (!s_data.containsKey("call-gSNP")) {
                        return;
                    }
                    s_data["call-gSNP"].each { tool, data ->
                        samples.add([
                            'tool': tool,
                            'path': data,
                            'sample': s,
                            'patient': s_data['patient']
                        ]);
                    };
                };
                return samples;
            }
            .flatten()
            .set{ input_ch_create_call_geneticancestry_yaml }

        create_YAML_call_GeneticAncestry(input_ch_create_call_geneticancestry_yaml)

        run_call_GeneticAncestry(create_YAML_call_GeneticAncestry.out.call_geneticancestry_input)

        run_call_GeneticAncestry.out.complete
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_call_GeneticAncestry.out.exit_code
                    .map{ it -> (it as Integer) }
                    .sum()
                    .map { exit_code ->
                        mark_pipeline_exit_code(params.this_pipeline, exit_code);
                        return 'done';
                    }
            )
            .collect()
            .map { it -> return 'done' }
            .set{ completion_signal }
}
