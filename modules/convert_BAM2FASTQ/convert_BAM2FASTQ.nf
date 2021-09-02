
def get_sample_name(input_csv) {
    def sample_name
    def reader = new FileReader(input_csv.toRealPath().toString())
    reader.splitEachLine(",") { fields ->
        sample_name = file(fields[1]).getBaseName()
    }
    return sample_name
}

process convert_BAM2FASTQ {
    publishDir "${params.output_dir}",
        mode: 'move',
        pattern: 'bam2fastq'

    cpus params.bam2fastq.subworkflow_cpus

    input:
        path input_csv

    output:
        path 'bam2fastq'
        path("bam2fastq/${sample_name}/create_fastqs_SAMtools/*.fq.gz"), emit: fastqs

    script:
    sample_name = get_sample_name(input_csv)
    """
    nextflow \
        -C ${moduleDir}/default.config \
        run ${moduleDir}/../../external/pipeline-convert-BAM2FASTQ/pipeline/main.nf \
        --run_name ${sample_name} \
        --input_csv ${input_csv} \
        --output_dir bam2fastq \
        --temp_dir ${params.temp_dir} \
        --get_bam_stats_SAMtools_cpus ${params.bam2fastq.get_bam_stats_SAMtools_cpus} \
        --collate_bam_SAMtools_cpus ${params.bam2fastq.collate_bam_SAMtools_cpus}
    cd bam2fastq
    latest=\$(ls -1 | head -n 1)
    mv \${latest}/* ./
    rmdir \${latest}
    """
}