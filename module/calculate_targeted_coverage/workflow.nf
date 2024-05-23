/*
    Main entry point for calling calculate-targeted-coverage pipeline
*/
include { create_YAML_calculate_targeted_coverage } from "${moduleDir}/create_YAML_calculate_targeted_coverage"
include { run_calculate_targeted_coverage } from "${moduleDir}/run_calculate_targeted_coverage" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"
include { identify_targeted_coverage_outputs; resolve_interval_selection } from './identify_outputs'

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
        ich = Channel.empty()
        if (params.input_type != 'SRC') {
            // Default to BWA-MEM2 as main aligner unless it's not being used
            def main_aligner = ('BWA-MEM2' in params.align_DNA.aligner) ? 'BWA-MEM2' : params.align_DNA.aligner[0]

            // Extract inputs from data structure
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .map{ it ->
                    def samples = [];
                    params.sample_data.each { s, s_data ->
                        samples.add(['patient': s_data['patient'], 'sample': s, 'state': s_data['state'], 'bam': s_data['align-DNA'][main_aligner]['BAM']]);
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
        } else {
            input_ch_create_targeted_coverage_yaml = Channel.empty()
        }

        if (!params.calculate_targeted_coverage.is_pipeline_enabled) {
            modification_signal.until{ it == 'done' }
                .mix(ich)
                .collect()
                .map{ 'done' }
                .set{ completion_signal }
        } else {
            create_YAML_calculate_targeted_coverage(input_ch_create_targeted_coverage_yaml)

            run_calculate_targeted_coverage(create_YAML_calculate_targeted_coverage.out.targeted_coverage_input)

            if (params.use_original_intervals) {
                // Graceful failure allowed so mark exit code
                modification_signal.until{ it == 'done' }
                    .mix(
                        run_calculate_targeted_coverage.out.exit_code
                            .map{ it -> (it as Integer) }
                            .sum()
                            .map{ exit_code ->
                                mark_pipeline_exit_code(params.this_pipeline, exit_code);
                                return 'done'
                            }
                    )
                    .collect()
                    .map{ 'done' }
                    .set{ completion_signal }
            } else {
                // Failure in targeted-coverage will result in failed run so no need to mark exit code
                identify_targeted_coverage_outputs(
                    run_calculate_targeted_coverage.out.identify_targeted_coverage_out
                )

                identify_targeted_coverage_outputs.out.och_targeted_coverage_identified
                    .collect()
                    .map{ outputs_identified ->
                        resolve_interval_selection();
                        return 'done'
                    }
                    .set{ completion_signal }
            }
        }

    emit:
        completion_signal = completion_signal
}
