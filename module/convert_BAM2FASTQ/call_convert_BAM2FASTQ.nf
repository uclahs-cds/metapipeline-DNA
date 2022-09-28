
include { generate_args } from "${moduleDir}/../common"

/*
    Get sample name from the input_csv. The sample_name must be in the 1st column.
*/
def get_sample_name(input_csv) {
    def sample_name
    def reader = new FileReader(input_csv.toRealPath().toString())
    reader.splitEachLine(",") { fields ->
        sample_name = file(fields[1]).getBaseName()
    }
    return sample_name
}

/*
    Process to call the convert-BAM2FASTQ pipeline.
*/
process call_convert_BAM2FASTQ {
    cpus params.bam2fastq.subworkflow_cpus
    
    publishDir "${params.output_dir}/output/${patient}/${sample}/",
        mode: 'copy',
        pattern: 'bam2fastq'

    input:
        tuple(
            val(patient),
            val(sample),
            val(state),
            file(input_csv)
        )

    output:
        tuple(
            val(patient),
            val(sample),
            val(state),
            file("${output_dir}/create_fastqs_SAMtools/*.fq.gz")
        )
        file output_dir
        
    script:
    output_dir = 'bam2fastq'
    sample_name = get_sample_name(input_csv)
    arg_list = ['get_bam_stats_SAMtools_cpus', 'collate_bam_SAMtools_cpus']
    args = generate_args(params.bam2fastq, arg_list)
    """
    set -euo pipefail

    nextflow \
        -C ${moduleDir}/default.config \
        run ${moduleDir}/../../external/pipeline-convert-BAM2FASTQ/pipeline/main.nf \
        --run_name ${sample_name} \
        --input_csv ${input_csv} \
        --output_dir ${output_dir} \
        --temp_dir ${params.work_dir} \
        ${args}

    # organize output directory
    cd ${output_dir}
    latest=\$(ls -1 | head -n 1)
    mv \${latest}/${sample_name}/* ./
    rmdir \${latest}/${sample_name}
    mv \${latest}/* ./
    rmdir \${latest}
    """
}