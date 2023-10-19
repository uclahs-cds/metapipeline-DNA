/*
* Module for calling the call-sSNV pipeline
*/

include { create_CSV_call_mtSNV } from "${moduleDir}/create_CSV_call_mtSNV"
include { run_call_mtSNV } from "${moduleDir}/run_call_mtSNV"

workflow call_mtSNV {
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

        if (params.sample_mode == 'single') {
            // In signle sample mode, call-mtSNV expects the input to be in the normal sample column
            ich.map{ it -> it.normal }
                .flatten()
                .set{ input_ch_normal }
            ich.map{ it -> it.tumor }
                .flatten()
                .set{ input_ch_tumor }

            input_ch_normal.mix(input_ch_tumor).map{ it ->
                [
                    'NO_ID',
                    it['sample'],
                    '/scratch/NO_FILE.bam',
                    it['bam']
                ]
            }.set{ input_ch_create_CSV }
        } else {
            // Call-mtSNV only supports single or paired modes, not multi
            ich.map{ it -> it.normal }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_normal }
            ich.map{ it -> it.tumor }.flatten().unique{ [it.patient, it.sample, it.state] }.set{ input_ch_tumor }

            input_ch_normal.combine(input_ch_tumor).map{ it ->
                ['normal': it[0], 'tumor': it[1]]
            }.map{ it ->
                [
                    it['tumor']['sample'],
                    it['normal']['sample'],
                    it['tumor']['bam'],
                    it['normal']['bam']
                ]
            }.set{ input_ch_create_CSV }
        }

        create_CSV_call_mtSNV(input_ch_create_CSV)
        run_call_mtSNV(create_CSV_call_mtSNV.out)
}
