/*
    Workflow module for flattening an input channel by one layer, while keeping remaining structure intact.
   
    input:
        ich: channel where each emission is a list of structured elements like tuples
    
    output:
        och: channel where each structured element is its own emission
*/
workflow flatten_samples {
    take:
    ich

    main:
    ich.map{ it ->
        outer_tuple = []
        for(elem in it) {
            outer_tuple = outer_tuple + ["key": elem]
            }
        outer_tuple
        }
        .flatten()
        .map{ it ->
            it.values().flatten()
            }
        .set{ och }

    emit:
    och = och    
}
