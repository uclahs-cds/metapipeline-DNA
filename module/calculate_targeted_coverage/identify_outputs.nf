include { identify_file } from '../common'

workflow identify_targeted_coverage_outputs {
    take:
    och_targeted_coverage

    main:
    och_targeted_coverage.map{ targeted_coverage_out ->
        params.sample_data[targeted_coverage_out[0]]['calculate-targeted-coverage']['expanded-intervals'] = identify_file("${targeted_coverage_out[1]}/BEDtools-*${targeted_coverage_out[0]}*target-with-enriched-off-target-intervals.bed.gz");

        return 'done'
    }
    .collect()
    .map{ return 'done' }
    .set{ och_targeted_coverage_identified }

    emit:
    och_targeted_coverage_identified = och_targeted_coverage_identified
}

/**
*   Update pipelines that use intervals with expanded intervals if necessary
*/
void resolve_interval_selection() {
    if (params.use_original_intervals) {
        return
    }

    // Select the intervals to use based on the following criteria:
    // - In single sample mode, use the sample's intervals
    // - In paired mode, use the normal sample's intervals
    // - In multi mode with 1 normal and n tumors, use the normal sample's intervals
    def intervals_to_use = ''
    if (params.sample_mode == 'single') {
        assert 1 == (params.normal_sample_count + params.tumor_sample_count)
        params.sample_data.each{ sample_id, sample_data ->
            intervals_to_use = sample_data['calculate-targeted-coverage']['expanded-intervals']
        }
    } else {
        assert 1 == params.normal_sample_count
        params.sample_data.each{ sample_id, sample_data ->
            if ('normal' == sample_data['state']) {
                intervals_to_use = sample_data['calculate-targeted-coverage']['expanded-intervals']
            }
        }
    }

    params.pipeline_interval_params.each{ pipeline, interval_param ->
        if (params.containsKey(pipeline)) {
            params[pipeline][interval_param] = intervals_to_use
            params[pipeline]['metapipeline_arg_map'][interval_param] = intervals_to_use
        }
    }
}
