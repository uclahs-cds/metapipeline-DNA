/*
    Main entry point for calling call-gSNP pipeline
*/
include { create_YAML_targeted_coverage } from "${moduleDir}/create_YAML_targeted_coverage"
include { run_targeted_coverage } from "${moduleDir}/run_targeted_coverage"
include { mark_pipeline_complete } from "../pipeline_status"

/*
* Main workflow for calling the targeted-coverage pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow targeted_coverage {
    take:
        modification_signal
    main:
        // Watch for pipeline ordering
        Channel.watchPath( "${params.pipeline_status_directory}/*.complete" )
            .until{ it -> it.name == "${params.pipeline_predecessor['targeted-coverage']}.complete" }
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

        if (params.sample_mode != 'single') {
            if (params.sample_mode == 'multi') {
                input_ch_create_targeted_coverage_yaml = ich
            } else {
                ich.map{ it -> it.normal }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_normal }
                ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

                input_ch_normal.combine(input_ch_tumor).map{ it ->
                    ['normal': [it[0]], 'tumor': [it[1]]]
                }
                .set{ input_ch_create_targeted_coverage_yaml }
            }
        } else {
            ich.map{ it -> it.normal }
                .flatten()
                .map{ it -> ['normal': [it], 'tumor': []] }
                .set{ input_ch_normal }
            ich.map{ it -> it.tumor }
                .flatten()
                .map{ it -> ['normal': [], 'tumor': [it]] }
                .set{ input_ch_tumor }

            input_ch_normal.mix(input_ch_tumor).set{ input_ch_create_targeted_coverage_yaml }
        }

        create_YAML_targeted_coverage(input_ch_create_targeted_coverage_yaml)

        run_targeted_coverage(create_YAML_targeted_coverage.out.targeted_coverage_input)

        run_targeted_coverage.out.complete
            .mix( pipeline_predecessor_complete )
            .collect()
            .map{ it ->
                mark_pipeline_complete('targeted-coverage');
                return 'done';
            }
           .set{ completion_signal }
}
