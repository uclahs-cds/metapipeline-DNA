#!/usr/bin/env nextflow

// Docker images here...
def docker_image_name = "docker image"
def docker_image_validate_params = "blcdsdockerregistry/validate:2.1.5"

// Log info here
log.info """\
        ======================================
        T E M P L A T E - N F  P I P E L I N E
        ======================================
        Boutros Lab

        Current Configuration:
        - pipeline:
            name: ${workflow.manifest.name}
            version: ${workflow.manifest.version}

        - input:
            input a: ${params.variable_name}
            ...

        - output: 
            output a: ${params.output_path}
            ...

        - options:
            option a: ${params.option_name}
            ...

        Tools Used:
            tool a: ${docker_image_name}

        ------------------------------------
        Starting workflow...
        ------------------------------------
        """
        .stripIndent()

// Channels here
// Decription of input channel
Channel
   .fromPath(params.input_csv)
   .ifEmpty { error "Cannot find input csv: ${params.input_csv}" }
   .splitCsv(header:true)
   .map { row -> 
       return tuple(row.row_1_name,
           row.row_2_name_file_extension
      )
   }
   .into { input_ch_input_csv; input_ch_input_csv_validate } // copy into two channels, one is for validation

// Decription of input channel
Channel
   .fromPath(params.variable_name)
   .ifEmpty { error "Cannot find: ${params.variable_name}" }
   .into { input_ch_variable_name; input_ch_variable_name_validate } // copy into two channels, one is for validation

// Pre-validation steps
input_ch_input_csv_validate // flatten csv channel to only file paths
   .flatMap { library, lane, read_group_name, read1_fastq, read2_fastq ->
      [read1_fastq, read2_fastq]
   }
   .set { input_ch_input_csv_validate_flat } // new flat channel

// Processes here
// Input validation process
process validate_inputs {
    container docker_image_validate_params // docker img reference

    input:
    path(file_to_validate) from input_ch_input_csv_validate_flat.mix(
      input_ch_input_csv_validate // add all input channels
   ) // combine and mix all input file channels into one channel

    output:
      val(true) into output_ch_validate_inputs

    script:
    """
    set -euo pipefail
    python -m validate -t file-input ${file_to_validate}
    """
}

// Decription of main process
process tool_name_command_name {
   container docker_image_name

   publishDir params.output_dir, enabled: true, mode: 'copy'

   label "resource_allocation_tool_name_command_name"

   // Additional directives here
   
   input: 
      tuple(val(row_1_name), 
         path(row_2_name_file_extension),
      ) from input_ch_input_csv
      val(variable_name) from input_ch_variable_name

   output:
      file("${variable_name}.command_name.file_extension") into output_ch_tool_name_command_name

   script:
   """
   # make sure to specify pipefail to make sure process correctly fails on error
   set -euo pipefail

   # the script should ideally only have call to a tool
   # to make the command more human readable:
   #  - seperate components of the call out on different lines
   #  - when possible by explict with command options, spelling out their long names
   tool_name \
      command_name \
      --option_1_long_name ${row_1_name} \
      --input ${row_2_name_file_extension} \
      --output ${variable_name}.command_name.file_extension
   """
}
