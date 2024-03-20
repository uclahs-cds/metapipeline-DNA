/*
* Module for calling the call-sSNV pipeline
*/

include { create_YAML_call_mtSNV } from "${moduleDir}/create_YAML_call_mtSNV"
include { run_call_mtSNV } from "${moduleDir}/run_call_mtSNV" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

workflow call_mtSNV {
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

        if (params.sample_mode == 'single') {
            ich.map{ it -> it.normal }
                .flatten()
                .map{ it -> ['normal': [it], 'tumor': []] }
                .set{ input_ch_normal }
            ich.map{ it -> it.tumor }
                .flatten()
                .map{ it -> ['normal': [], 'tumor': [it]] }
                .set{ input_ch_tumor }

            input_ch_normal.mix(input_ch_tumor).set{ input_ch_create_call_mtsnv_yaml }
        } else {
            ich.map{ it -> it.normal }
                .flatten()
                .unique{ [it.patient, it.sample, it.state] }
                .set{ input_ch_normal }
            ich.map{ it -> it.tumor }
                .flatten()
                .unique{ [it.patient, it.sample, it.state] }
                .set{ input_ch_tumor }

            input_ch_normal.combine(input_ch_tumor).map{ it ->
                ['normal': [it[0]], 'tumor': [it[1]]]
            }
            .set{ input_ch_create_call_mtsnv_yaml }
        }

        create_YAML_call_mtSNV(input_ch_create_call_mtsnv_yaml)
        run_call_mtSNV(create_YAML_call_mtSNV.out.call_mtsnv_yaml)

        run_call_mtSNV.out.complete
            .mix( pipeline_predecessor_complete )
            .collect()
            .map{ it ->
                mark_pipeline_complete(params.this_pipeline);
                return 'done';
            }
            .mix(
                run_call_mtSNV.out.exit_code
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
