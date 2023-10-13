/*
    Main entrypoint for calling call-gSV pipeline
*/

include { create_CSV_call_gSV } from "${moduleDir}/create_CSV_call_gSV"
include { run_call_gSV } from "${moduleDir}/run_call_gSV"

/*
* Main workflow for calling the call-gSV pipeline
*
* Input:
*   Input is a channel containing the samples split by type
*/
workflow call_gSV {
    take:
        modification_signal
    main:
        // Extract inputs from data structure
        modification_signal.until{ it == 'done' }.ifEmpty('done')
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

        ich
            .map{ it -> it.normal }
            .flatten()
            .unique{ [it.patient, it.sample, it.state] }
            .map{ it -> [params.patient, it['sample'], it['bam']] }
            .set{ input_ch_create_CSV }

        create_CSV_call_gSV(input_ch_create_CSV)

        run_call_gSV(create_CSV_call_gSV.out)
}
