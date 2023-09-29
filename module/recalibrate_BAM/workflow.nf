/*
    Main entry point for calling recalibrate-BAM pipeline
*/
include { create_YAML_recalibrate_BAM } from "./create_YAML_recalibrate_BAM"
include {
    run_recalibrate_BAM as run_recalibrate_BAM_delete_tumor
    run_recalibrate_BAM as run_recalibrate_BAM_delete_all
    } from "./run_recalibrate_BAM"
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
        ich
        modification_signal

    main:
        ich.flatten()
            .reduce(['normal': [] as Set, 'tumor': [] as Set]) { a, b ->
                a[b.state] += b;
                return a
            }
            .set{ collected_input_ch }
        skip_recalibrate_output = collected_input_ch

        collected_input_ch.map{ it ->
            it['tumor'].eachWithIndex{ sample, sample_index ->
                sample['states_to_delete'] = (sample_index == 0) ? ['normal', 'tumor'] : ['tumor'];
                return sample
            };
            return it
        }
        .set{ input_ch_with_deletion_info }

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

        if (params.override_recalibrate_bam) {
            skip_recalibrate_output.set{ output_ch_recalibrate_bam }

            // Default to BWA-MEM2 as main aligner unless it's not being used
            def main_aligner = ('BWA-MEM2' in params.align_DNA.aligner) ? 'BWA-MEM2' : params.align_DNA.aligner[0]

            modification_signal.until{ it == 'done' }.mix(skip_recalibrate_output).collect().map{
                params.sample_data.each{ s, s_data ->
                    s_data['recalibrate-BAM']['BAM'] = s_data['align-DNA'][main_aligner]['BAM']
                };
                return 'done'
            }
            .collect()
            .map{
                mark_pipeline_complete('recalibrate-BAM');
                return 'done'
            }.set{ recalibrate_sample_data_updated }
        } else {
            input_ch_recalibrate_bam
                .branch {
                    delete_only_tumor: it[0] == ['tumor']
                    delete_all: it[0] == ['normal', 'tumor']
                }
                .set{ deletion_split }

            run_recalibrate_BAM_delete_tumor(deletion_split.delete_only_tumor.map{ it + ['complete'] })

            run_recalibrate_BAM_delete_tumor.out.metapipeline_out.ifEmpty('default')
                .collect()
                .map{ 'complete' }
                .set{ completion_signal }

            run_recalibrate_BAM_delete_all(deletion_split.delete_all.combine(completion_signal))

            identify_recalibrate_bam_outputs(
                modification_signal.until{ it == 'done' }
                    .mix(run_recalibrate_BAM_delete_tumor.out.identify_recalibrate_bam_out)
                    .mix(run_recalibrate_BAM_delete_all.out.identify_recalibrate_bam_out)
            )

            identify_recalibrate_bam_outputs.out.och_recalibrate_bam_identified.collect().map{ println params.sample_data; mark_pipeline_complete('recalibrate-BAM'); return 'done' }.set{ recalibrate_sample_data_updated }

            run_recalibrate_BAM_delete_tumor.out.metapipeline_out
                .mix(run_recalibrate_BAM_delete_all.out.metapipeline_out)
                .map{ it ->
                    Map resolved_samples = ['normal': [], 'tumor': []];
                    it[0].normal.each{ normal_sample ->
                        def sample_bam_files = file("${it[1]}/*GATK-*${normal_sample}*.bam");
                        assert sample_bam_files.size() == 1;
                        resolved_samples.normal.add([
                            'patient': params.patient,
                            'sample': normal_sample,
                            'state': 'normal',
                            'bam': sample_bam_files[0].toRealPath().toString()
                        ])
                    };
                    it[0].tumor.each{ tumor_sample ->
                        def sample_bam_files = file("${it[1]}/*GATK-*${tumor_sample}*.bam");
                        assert sample_bam_files.size() == 1;
                        resolved_samples.tumor.add([
                            'patient': params.patient,
                            'sample': tumor_sample,
                            'state': 'tumor',
                            'bam': sample_bam_files[0].toRealPath().toString()
                        ])
                    };
                    return resolved_samples
                }
            .reduce(['normal': [] as Set, 'tumor': [] as Set]) { a, b ->
                a.normal += b.normal;
                a.tumor += b.tumor;
                return a
            }
            .set{ output_ch_recalibrate_bam }
        }
    emit:
        output_ch_recalibrate_bam = output_ch_recalibrate_bam
        recalibrate_sample_data_updated = recalibrate_sample_data_updated
}
