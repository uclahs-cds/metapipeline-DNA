/*
    Main entry point for annotating variants
*/
include { create_YAML_annotate_VCF } from "${moduleDir}/create_YAML_annotate_VCF"
include { run_annotate_VCF } from "${moduleDir}/run_annotate_VCF" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
*   Main workflow for annotating variants
*/
workflow annotate_VCF {
    take:
        modification_signal
    main:
        // Extract inputs from data structure
        modification_signal.until{ it == 'done' }.ifEmpty('done')
            .collect()
            .map{ it ->
                def samples = [];
                params.sample_data.each { s, s_data ->
                    params.annotate_VCF.pipelines_to_annotate.each { raw_mode ->
                        def mode = raw_mode.replace('annotate-', '');
                        if (!s_data.containsKey("call-${mode}" as String)) {
                            return;
                        }
                        s_data["call-${mode}"].each { tool, data ->
                            samples.add([
                                'mode': mode,
                                'tool': tool,
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
            .set{ input_ch_create_annotate_vcf_yaml }

        create_YAML_annotate_VCF(input_ch_create_annotate_vcf_yaml)

        run_annotate_VCF(create_YAML_annotate_VCF.out.annotate_vcf_input)

        run_annotate_VCF.out.complete
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_annotate_VCF.out.exit_code
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
