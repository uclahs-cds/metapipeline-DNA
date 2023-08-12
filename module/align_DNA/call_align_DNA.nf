include { combine_input_with_params } from '../common.nf'

def get_header_sample_name(path) {
    def reader = new FileReader(path)
    def sm = []
    reader.splitEachLine(",") { fields ->
        sm.add(fields[5])
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
            path(input_csv)
        )
    
    output:
        tuple val(patient), val(sample), val(state), val(bam_header_sm), path(bam), emit: metapipeline_out
        file "align-DNA-*/*"
    
    script:
    bam_header_sm = get_header_sample_name(input_csv.toRealPath().toString())
    bam = "align-DNA-*/${sample}/BWA-MEM2-2.2.1/output/BWA-MEM2-*${sample}.bam"

    aligner = params.align_DNA.aligner.join(',')

    String params_to_dump = combine_input_with_params(params.align_DNA.metapipeline_arg_map)
    """
    set -euo pipefail

    printf "${params_to_dump}" > combined_align_dna_params.yaml

    WORK_DIR=${params.work_dir}/work-align-DNA-${sample}
    mkdir \$WORK_DIR
    nextflow run \
        ${moduleDir}/../../external/pipeline-align-DNA/main.nf \
        -params-file combined_align_dna_params.yaml \
        --sample_id ${sample} \
        --aligner ${aligner} \
        --output_dir \$(pwd) \
        --work_dir \$WORK_DIR \
        --spark_temp_dir \$WORK_DIR \
        --input_csv ${input_csv} \
        --dataset_id ${params.project_id} \
        -c ${moduleDir}/default.config

    rm -r \$WORK_DIR
    """
}
