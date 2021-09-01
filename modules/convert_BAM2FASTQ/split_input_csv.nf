
process split_input_csv {
    
    input:
        path pipeline_csv
    
    output:
        path normal_csv, emit: normal
        path tumor_csv, emit: tumor
    
    script:
    normal_csv = 'normal.csv'
    tumor_csv = 'tumor.csv'
    """
    echo 'sample_name,sample' > ${normal_csv}
    echo 'sample_name,sample' > ${tumor_csv}
    cat ${pipeline_csv} | tail -n +2 | cut -d ',' -f 1,2 >> ${normal_csv}
    cat ${pipeline_csv} | tail -n +2 | cut -d ',' -f 1,3 >> ${tumor_csv}
    """
}