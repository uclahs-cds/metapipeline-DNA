/*
    Main entry point for calling calculate-targeted-coverage pipeline
*/
include { create_YAML_calculate_targeted_coverage } from "${moduleDir}/create_YAML_calculate_targeted_coverage"
include { run_calculate_targeted_coverage } from "${moduleDir}/run_calculate_targeted_coverage" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
* Main workflow for calling the targeted-coverage pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow calculate_targeted_coverage {
    take:
        modification_signal
    main:
        // Watch for pipeline ordering
        Channel.watchPath( "${params.pipeline_status_directory}/*.complete" )
            .until{ it -> it.name == "${params.pipeline_predecessor[params.this_pipeline]}.complete" }
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

        ich.map{ it -> it.normal }
            .flatten()
            .map{ it -> [it.sample, it.bam] }
            .set{ input_ch_normal }
        ich.map{ it -> it.tumor }
            .flatten()
            .map{ it -> [it.sample, it.bam] }
            .set{ input_ch_tumor }

        input_ch_normal.mix(input_ch_tumor)
            .set{ input_ch_create_targeted_coverage_yaml }

        create_YAML_calculate_targeted_coverage(input_ch_create_targeted_coverage_yaml)

        run_calculate_targeted_coverage(create_YAML_calculate_targeted_coverage.out.targeted_coverage_input)

        run_calculate_targeted_coverage.out.complete
            .mix( pipeline_predecessor_complete )
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_calculate_targeted_coverage.out.exit_code
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
