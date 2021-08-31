#!/usr/bin/env nextflow

// Docker images here...
def docker_image_name = "docker image"
def docker_image_validate_params = "blcdsdockerregistry/validate:2.1.5"

// Log info here
log.info """\
    =================================================
    P I P E L I N E - G E R M L I N E - S O M A T I C
    =================================================
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