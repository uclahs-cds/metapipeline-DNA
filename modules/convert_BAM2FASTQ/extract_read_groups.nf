
process extract_read_groups {
    container "quay.io/biocontainers/pysam:0.16.0.1--py38hf7546f9_3"

    containerOptions "-v ${projectDir}:${projectDir}"

    input:
        path bam_file

    output:
        path read_group_csv

    script:
    read_group_csv = 'read_groups.csv'
    """
    python ${projectDir}/convert_BAM2FASTQ/extract_read_groups.py \
        --input-bam ${bam_file} \
        --output-csv ${read_group_csv}
    """
}