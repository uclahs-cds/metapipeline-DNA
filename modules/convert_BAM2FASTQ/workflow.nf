
include { convert_BAM2FASTQ as convert_BAM2FASTQ_normal } from './convert_BAM2FASTQ'
include { convert_BAM2FASTQ as convert_BAM2FASTQ_tumor } from './convert_BAM2FASTQ'
include { extract_read_groups as extract_read_groups_normal } from './extract_read_groups.nf'
include { extract_read_groups as extract_read_groups_tumor } from './extract_read_groups.nf'
include { split_input_csv } from './split_input_csv'

workflow convert_BAM2FASTQ {
    take:
        input_csv
    main:
        split_input_csv(input_csv)
        normal_bam = split_input_csv.out.normal
            .splitCsv(header: true)
            .map({ it.normal })
        extract_read_groups_normal(normal_bam)
    //     extract_read_groups_tumor(split_input_csv.out.tumor)
        convert_BAM2FASTQ_normal(split_input_csv.out.normal)
    //     convert_BAM2FASTQ_tumor(split_input_csv.out.tumor)
    // emit:
    //     read_groups_normal = extract_read_groups_normal.out
    //     red_groups_tumor = extract_read_groups_tumor.out
    //     fastqs_normal = convert_BAM2FASTQ_normal.out.fastqs
    //     fastqs_tumor = convert_BAM2FASTQ_tumor.out.fastqs
}