
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
    """
    python ${moduleDir}/extract_read_groups.py \
        --input-bam ${bam} \
        --output-csv ${read_group_csv}
    """
}