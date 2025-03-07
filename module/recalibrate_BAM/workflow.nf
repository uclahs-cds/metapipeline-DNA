/*
    Main entry point for calling recalibrate-BAM pipeline
*/
include { create_YAML_recalibrate_BAM } from "./create_YAML_recalibrate_BAM"
include {
    run_recalibrate_BAM as run_recalibrate_BAM_delete_tumor
    run_recalibrate_BAM as run_recalibrate_BAM_delete_all
    } from "./run_recalibrate_BAM" addParams( log_output_dir: params.metapipeline_log_output_dir )
include { mark_pipeline_complete } from '../pipeline_status'
include { identify_recalibrate_bam_outputs } from './identify_outputs'

/*
* Main workflow for calling the recalibrate-BAM pipeline
*
* Input:
*   Input is a channel that each element is a tuple or list of 4 items:
*     @param patient (String): Patient ID
*     @param sample (String): Sample ID
*     @param state (String): Must be either normal or tumor.
*     @param bam (file): Path to the BAM file.
* 
* Ouput:
*   @return A Map containing information for samples split into normal and tumor states
*/
workflow recalibrate_BAM {
    take:
        modification_signal

    main:
        // Default to BWA-MEM2 as main aligner unless it's not being used
        def main_aligner = ('BWA-MEM2' in params.align_DNA.aligner) ? 'BWA-MEM2' : params.align_DNA.aligner[0]

        if (!['VCF', 'SRC'].contains(params.input_type)) {
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
                .set{ collected_input_ch }

            collected_input_ch.map{ it ->
                it['tumor'].eachWithIndex{ sample, sample_index ->
                    sample['states_to_delete'] = (sample_index == 0) ? ['normal', 'tumor'] : ['tumor'];
                    return sample
                };
                return it
            }
            .set{ input_ch_with_deletion_info }
        } else {
            collected_input_ch = Channel.empty()
            input_ch_with_deletion_info = Channel.empty()
        }

        if (params.override_recalibrate_bam || !params.recalibrate_BAM.is_pipeline_enabled) {
            modification_signal.until{ it == 'done' }.ifEmpty('done')
                .mix(collected_input_ch)
                .collect()
                .map{
                    if (!['VCF', 'SRC'].contains(params.input_type)) {
                        params.sample_data.each{ s, s_data ->
                            s_data[params.this_pipeline]['BAM'] = s_data['align-DNA'][main_aligner]['BAM'];
                        };
                    }
                    return 'done'
                }
                .map{
                    mark_pipeline_complete(params.this_pipeline);
                    return 'done'
                }.set{ recalibrate_sample_data_updated }
        } else {
            if (params.sample_mode != 'single') {
                if (params.sample_mode == 'multi') {
                    input_ch_create_recalibrate_yaml = input_ch_with_deletion_info
                } else {
                    input_ch_with_deletion_info.map{ it -> it.normal }.flatten().set{ input_ch_normal }
                    input_ch_with_deletion_info.map{ it -> it.tumor }.flatten().set{ input_ch_tumor }

                    input_ch_normal.combine(input_ch_tumor).map{ it ->
                        ['normal': [it[0]], 'tumor': [it[1]]]
                    }
                    .set{ input_ch_create_recalibrate_yaml }
                }

                create_YAML_recalibrate_BAM(input_ch_create_recalibrate_yaml)

                create_YAML_recalibrate_BAM.out.recalibrate_bam_input.set{ input_ch_recalibrate_bam }
            } else {
                input_ch_with_deletion_info.map{ it -> it.normal }
                    .flatten()
                    .map{ it -> ['normal': [it], 'tumor': []] }
                    .set{ input_ch_normal }
                input_ch_with_deletion_info.map{ it -> it.tumor }
                    .flatten()
                    .map{ it -> ['normal': [], 'tumor': [it]] }
                    .set{ input_ch_tumor }

                input_ch_normal.mix(input_ch_tumor).set{ input_ch_create_recalibrate_yaml }
                create_YAML_recalibrate_BAM(input_ch_create_recalibrate_yaml)

                create_YAML_recalibrate_BAM.out.recalibrate_bam_input.set{ input_ch_recalibrate_bam }
            }

            input_ch_recalibrate_bam
                .branch {
                    delete_only_tumor: it[0] == ['tumor']
                    delete_all: it[0] == ['normal', 'tumor']
                }
                .set{ deletion_split }

            run_recalibrate_BAM_delete_tumor(deletion_split.delete_only_tumor.map{ it + ['complete'] })

            run_recalibrate_BAM_delete_tumor.out.identify_recalibrate_bam_out.ifEmpty('default')
                .collect()
                .map{ 'complete' }
                .set{ completion_signal }

            run_recalibrate_BAM_delete_all(deletion_split.delete_all.combine(completion_signal))

            // Identify outputs
            identify_recalibrate_bam_outputs(
                modification_signal.until{ it == 'done' }
                    .mix(run_recalibrate_BAM_delete_tumor.out.identify_recalibrate_bam_out)
                    .mix(run_recalibrate_BAM_delete_all.out.identify_recalibrate_bam_out)
            )

            identify_recalibrate_bam_outputs.out.och_recalibrate_bam_identified
                .collect()
                .map{
                    mark_pipeline_complete(params.this_pipeline);
                    return 'done'
                }
                .set{ recalibrate_sample_data_updated }
        }

    emit:
        recalibrate_sample_data_updated = recalibrate_sample_data_updated
}
