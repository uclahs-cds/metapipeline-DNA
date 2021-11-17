
process extract_read_groups {
    container "quay.io/biocontainers/pysam:0.16.0.1--py38hf7546f9_3"

    containerOptions "-v ${moduleDir}:${moduleDir}"

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            file(bam)
        )

    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            val(site),
            file(read_group_csv)
        )

    script:
    read_group_csv = 'read_groups.csv'
    cn_tag = params.bam2fastq.containsKey('sequencing_center') ? "--sequencing-center ${params.bam2fastq.sequencing_center}" : ''
    pu_tag = params.bam2fastq.containsKey('platform_unit') ? "--platform-unit ${params.bam2fastq.platform_unit}" : ''
    """
    python ${moduleDir}/extract_read_groups.py \
        --input-bam ${bam} \
        --output-csv ${read_group_csv} \
        ${cn_tag} \
        ${pu_tag}
    """
}