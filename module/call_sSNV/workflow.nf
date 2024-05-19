/*
    Main entry point for calling call-sSNV pipeline
*/
include { create_YAML_call_sSNV } from "${moduleDir}/create_YAML_call_sSNV"
include { run_call_sSNV } from "${moduleDir}/run_call_sSNV" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete; mark_pipeline_exit_code } from "../pipeline_status"

/*
* Main workflow for calling the call-sSNV pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow call_sSNV {
    take:
        modification_signal
    main:
        if (!params.call_sSNV.is_pipeline_enabled) {
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .map{ it ->
                    if (params.call_SRC.is_pipeline_enabled) {
                        params.sample_data.each { s, s_data ->
                            s_data['original_src_data'].each { src_data ->
                                if (src_data['src_input_type'] == 'SNV') {
                                    s_data[params.this_pipeline][src_data['algorithm']] = src_data['path'];
                                }
                            };
                        };
                    }

                    mark_pipeline_complete(params.this_pipeline);
                    mark_pipeline_exit_code(params.this_pipeline, 0);
                    return 'done';
                }
                .set{ completion_signal }
        } else {
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

            ich.map{ it -> it.normal }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_normal }
            ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

            if (params.sample_mode == 'single') {
                // Only Mutect2 supports tumor-only calling
                if ('mutect2' in params.call_sSNV.algorithm) {
                    input_ch_tumor
                        .map{ [it['sample'], [['NO_ID', 'NO_BAM.bam']], [[it['sample'], file(it['bam']).toRealPath()]], 'mutect2'] }
                        .set{ input_ch_tumor_only }
                } else {
                    Channel.empty().set{ input_ch_tumor_only }
                }
                create_YAML_call_sSNV(input_ch_tumor_only)
            } else {
                // [patient, [normal_ID,normal_BAM], [tumor_ID,tumor_BAM]]
                input_ch_normal.combine(input_ch_tumor).map{ it ->
                    ['normal': it[0], 'tumor': it[1]]
                }.map{ it ->
                    [
                        params.patient,
                        [[it['normal']['sample'], file(it['normal']['bam']).toRealPath()]],
                        [it['tumor']['sample'], file(it['tumor']['bam']).toRealPath()]
                    ]
                }.groupTuple(by: [0,1])
                .set{ input_ch_create_ssnv_yaml_multisample }

                input_ch_normal.combine(input_ch_tumor).map{ it ->
                    ['normal': it[0], 'tumor': it[1]]
                }.map{ it ->
                    [
                        it['tumor']['sample'],
                        [[it['normal']['sample'], file(it['normal']['bam']).toRealPath()]],
                        [[it['tumor']['sample'], file(it['tumor']['bam']).toRealPath()]]
                    ]
                }.set{ input_ch_create_ssnv_yaml_pairedsample }

                input_ch_create_ssnv_yaml = Channel.empty()
                requested_ssnv_algorithms = params.call_sSNV.algorithm.unique(false)

                if ( params.sample_mode == 'multi' &&
                    'mutect2' in requested_ssnv_algorithms &&
                    (params.normal_sample_count > 1 || params.tumor_sample_count > 1) ) {
                    input_ch_create_ssnv_yaml = input_ch_create_ssnv_yaml_multisample
                        .combine( Channel.of( ['mutect2'] ) )

                    // With multiple algorithms requested, run Mutect2 twice (in multi and paired mode)
                    // to include Mutect2 in intersection results
                    if (requested_ssnv_algorithms.size() == 1) {
                        requested_ssnv_algorithms.removeAll{ it == 'mutect2' }
                    }
                }

                if ( !requested_ssnv_algorithms.isEmpty() ) {
                    input_ch_create_ssnv_yaml = input_ch_create_ssnv_yaml_pairedsample
                        .combine( Channel.of( [requested_ssnv_algorithms] ) )
                        .mix( input_ch_create_ssnv_yaml )
                }

                create_YAML_call_sSNV(input_ch_create_ssnv_yaml)
            }
            run_call_sSNV(create_YAML_call_sSNV.out)

            run_call_sSNV.out.complete
                .mix( pipeline_predecessor_complete )
                .collect()
                .map{ it ->
                    mark_pipeline_complete(params.this_pipeline);
                    return 'done';
                }
                .mix(
                    run_call_sSNV.out.exit_code
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

    emit:
    completion_signal = completion_signal
}
