
include { generate_args } from "${moduleDir}/../common"

def get_header_sample_name(path) {
    def reader = new FileReader(path)
    def sm = []
    reader.splitEachLine(",") { fields ->
        sm.add(fields[6])
    }
    sm.removeAt(0)
    sm.unique()
    if (sm.size() > 1) {
        throw new Exception('Input csv should have same SM for all fastq pairs')
    }
    return sm[0]
}

/*
    Process to call the align-DNA pipeline.
*/
process call_align_DNA {
    cpus params.align_DNA.subworkflow_cpus

    publishDir "${params.output_dir}/output",
        mode: "copy",
        pattern: "align-DNA-*/*"

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
            val(bam_header_sm),
            file(bam)
        ), emit: metapipeline_out
        file "align-DNA-*/*"
    
    script:
    bam_header_sm = get_header_sample_name(input_csv.toRealPath().toString())
    bam = "align-DNA-*/${sample}/BWA-MEM2-2.2.1/output/${sample}.bam"
    arg_list = [
        'enable_spark',
        'mark_duplicates',
        'reference_fasta_bwa',
        'reference_fasta_hisat2',
        'hisat2_index_prefix',
        'align_DNA_BWA_MEM2_cpus',
        'align_DNA_HISAT2_cpus',
        'run_SortSam_Picard_cpus',
        'run_SortSam_Picard_memory_GB',
        'run_MarkDuplicate_Picard_cpus',
        'run_MarkDuplicate_Picard_memory_GB',
        'run_MarkDuplicatesSpark_GATK_cpus',
        'run_MarkDuplicatesSpark_GATK_memory_GB'
    ]

    args = generate_args(params.align_DNA, arg_list)
    aligner = params.align_DNA.aligner.join(',')

    """
    nextflow run \
        ${moduleDir}/../../external/pipeline-align-DNA/main.nf \
        --sample_name ${sample} \
        --aligner ${aligner} \
        ${args} \
        --output_dir \$(pwd) \
        --work_dir ${params.work_dir} \
        --input_csv ${input_csv} \
        -c ${moduleDir}/default.config
    """
}
