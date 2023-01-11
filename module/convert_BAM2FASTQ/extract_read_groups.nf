
process extract_read_groups {
    container "quay.io/biocontainers/pysam:0.16.0.1--py38hf7546f9_3"

    containerOptions "-v ${moduleDir}:${moduleDir}"

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            file(bam)
        )

    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            file(read_group_csv)
        )

    script:
    read_group_csv = 'read_groups.csv'
    cn_tag = params.convert_BAM2FASTQ.containsKey('sequencing_center') ? "--sequencing-center ${params.convert_BAM2FASTQ.sequencing_center}" : ''
    pu_tag = params.convert_BAM2FASTQ.containsKey('platform_unit') ? "--platform-unit ${params.convert_BAM2FASTQ.platform_unit}" : ''
    id_for_pu_tag = params.convert_BAM2FASTQ.containsKey('id_for_pu') && params.convert_BAM2FASTQ.id_for_pu ? "--id-for-pu" : ''
    """
    python ${moduleDir}/extract_read_groups.py \
        --input-bam ${bam} \
        --output-csv ${read_group_csv} \
        ${cn_tag} \
        ${pu_tag} \
        ${id_for_pu_tag}
    """
}