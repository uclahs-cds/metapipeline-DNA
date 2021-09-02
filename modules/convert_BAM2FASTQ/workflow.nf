
include { convert_BAM2FASTQ as convert_BAM2FASTQ_process } from './convert_BAM2FASTQ'
include { extract_read_groups } from './extract_read_groups.nf'

workflow convert_BAM2FASTQ {
    take:
        input_csv
    main:
        bam = Channel.fromPath(input_csv).splitCsv(header: true).map({ it.sample })
        extract_read_groups(bam)
        convert_BAM2FASTQ_process(input_csv)
        
    emit:
        read_groups = extract_read_groups.out
        fastqs = convert_BAM2FASTQ_process.out.fastqs
}