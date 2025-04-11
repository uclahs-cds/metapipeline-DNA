/*
    Main entry point for calculating mtDNA copy number
*/
include { create_YAML_calculate_mtDNA_CopyNumber } from "${moduleDir}/create_YAML_calculate_mtDNA_CopyNumber"
include { run_calculate_mtDNA_CopyNumber } from "${moduleDir}/run_calculate_mtDNA_CopyNumber" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
*   Main workflow for calculating mtDNA copy number
*/
workflow calculate_mtDNA_CopyNumber {
    take:
        modification_signal
    main:
        // Extract inputs from data structure
        modification_signal.until{ it == 'done' }.ifEmpty('done')
            .collect()
            .map{ it ->
                def samples = [];
                params.sample_data.each { s, s_data ->
                    if (!s_data.containsKey("generate-SQC-BAM")) {
                        return;
                    }
                    s_data["generate-SQC-BAM"].each { tool, data ->
                        if (!['Qualimap'].contains(tool)) {
                            return;
                        }
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
            .set{ input_ch_create_calculate_mtdna_copynumber_yaml }

        create_YAML_calculate_mtDNA_CopyNumber(input_ch_create_calculate_mtdna_copynumber_yaml)

        run_calculate_mtDNA_CopyNumber(create_YAML_calculate_mtDNA_CopyNumber.out.calculate_mtdna_copynumber_input)

        run_calculate_mtDNA_CopyNumber.out.complete
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_calculate_mtDNA_CopyNumber.out.exit_code
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
