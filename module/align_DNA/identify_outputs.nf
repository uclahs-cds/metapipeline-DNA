include { identify_file } from '../common'

workflow identify_align_dna_outputs {
    take:
    och_align_dna

    main:
    och_align_dna.map{ align_dna_out ->
        params.sample_data[align_dna_out[0]]['align-DNA'].each { aligner_tool, aligner_output ->
            aligner_output['BAM'] = identify_file("${align_dna_out[1]}/${aligner_tool}*/output/${aligner_tool}*${align_dna_out[0]}.bam")
        };

        return 'done'
    }
    .collect()
    .map{ 'done' }
    .set{ och_align_dna_outputs_identified }

    emit:
    och_align_dna_outputs_identified = och_align_dna_outputs_identified
}
