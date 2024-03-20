/*
    Main entry point for generating BAM SQC
*/
include { create_YAML_generate_SQC_BAM } from "${moduleDir}/create_YAML_generate_SQC_BAM"
include { run_generate_SQC_BAM } from "${moduleDir}/run_generate_SQC_BAM" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
* Main workflow for generating BAM SQC
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow generate_SQC_BAM {
    take:
        modification_signal
    main:
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

        create_YAML_generate_SQC_BAM(ich)

        run_generate_SQC_BAM(create_YAML_generate_SQC_BAM.out)

        run_generate_SQC_BAM.out.complete
            .mix( pipeline_predecessor_complete )
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_generate_SQC_BAM.out.exit_code
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
