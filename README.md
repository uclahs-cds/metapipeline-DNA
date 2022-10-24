# metapipeline-DNA

- [metapipeline-DNA](#metapipeline-dna)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Pipeline Steps](#pipeline-steps)
    - [1. convert-BAM2FASTQ](#1-convert-bam2fastq)
    - [2. align-DNA](#2-align-dna)
    - [3. call-gSNP](#3-call-gsnp)
    - [4. call-sSNV](#4-call-ssnv)
    - [5. call-mtSNV](#5-call-mtsnv)
  - [Inputs](#inputs)
    - [Input BAM](#input-bam)
    - [Input FASTQ](#input-fastq)
    - [Config Params](#config-params)
  - [Outputs](#outputs)
  - [Discussions](#discussions)
  - [Contributors](#contributors)
  - [License](#license)

## Overview

This meta pipeline takes either aligned sequencing data (BAM - <u>**BETA FEATURE**</u>) and converts it back to FASTQ format or direct FASTQ data. The FASTQs are re-aligned to the reference genome and called for germline SNPs, somatic SNVs and mitochondrial SNVs. The input to this meta pipeline includes a list of patients and their tumor-normal paired samples. Each patient must have **exactly one** normal sample, while multiple tumor samples are allowed. If a patient has multiple tumor samples, each tumor will be paired with the normal and calling will be done for each pair.

The pipeline has a leading process running on the submitter node (can be a F2 node as the leading process does not require many resources) that submits samples of each patient to a worker node (usually an F72 node) for processing. All processes for the same patient run on the same node to avoid network traffic.

![design](img/design.drawio.svg?raw=true)

---

## How To Run

1. Create a config file using the [`template`](config/template.config), which takes the input samples along with general parameters, with a section defining the parameters, reference files, and resources configurations for each run and each pipeline.

2. Create an `input.csv` or an `input.yaml` file (following the descriptions [here](#inputs)) with path to the input files of each patient with both normal and tumor samples. For each patient, there must be one sample where the `state` is `normal` and the other samples for that patient must be `tumor`.

3. See the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit your pipeline.

> **warning**: A low memory node (*e.g* F2) is sufficient for the leading job. Submitting the leading job to a F72 node is wasteful!

---

## Flow Diagram

![alt text](img/diagram.drawio.svg?raw=true)

---

## Pipeline Steps

### 1. convert-BAM2FASTQ
*Optional*: only run when BAMs are provided as input.
> **WARNING - BETA**: The convert-BAM2FASTQ pipeline has *not* officially been released so BAM inputs to metapipeline are a BETA feature. Use with caution.

Aligned BAM file for each sample is first converted back to FASTQ using [pipeline-convert-BAM2FASTQ](https://github.com/uclahs-cds/pipeline-convert-BAM2FASTQ/).

### 2. align-DNA

The FASTQ file for each sample is then realigned to the genome using [pipeline-align-DNA](https://github.com/uclahs-cds/pipeline-align-DNA).

### 3. call-gSNP

Germline SNPs are then called from the re-aligned BAM files using [pipeline-call-gSNP](https://github.com/uclahs-cds/pipeline-call-gSNP). Call-gSNP also performs BAM re-calibration. Tumor and normal samples from the same patient are paired in this step.

### 4. call-sSNV

The calibrated BAM from step 3 is then used to call for somatic SNVs using [pipeline-call-sSNV](https://github.com/uclahs-cds/pipeline-call-sSNV).

### 5. call-mtSNV

The same calibrated BAM from step 3 is also used to call for mitochondrial SNVs usint [pipeline-call-mtSNV](https://github.com/uclahs-cds/pipeline-call-mtSNV)

---

## Inputs

### Input BAM

> **BETA** - See warning above

| Field | Type | Required | Description |
| :---: | :--: | :------: | :---------: |
| patient | string | yes | Identifier for the patient |
| sample | string | yes | Identifier for the sample |
| state | string | yes | Must be either "tumor" or "normal" |
| path | path | yes | Absolute path to the sample BAM file |

See this [template](input/template-input-BAM.csv) for CSV format and this [template](input/template-input-BAM.yaml) for YAML format.

### Input FASTQ

| Field | Type | Required | Description |
| :---: | :--: | :------: | :---------: |
| patient | string | yes | Identifier for the patient |
| sample | string | yes | Identifier for the sample |
| state | string | yes | Must be either "tumor" or "normal" |
| index | integer | yes | Index number for align-DNA |
| read_group_identifier | string | yes | Read group ID |
| sequencing_center | string | yes | Center where sequencing was performed |
| library_identifier | string | yes | Library used for sample |
| platform_technology | string | yes | Technology used for sequencing |
| platform_unit | string | yes | Name of specific platform unit |
| bam_header_sm | string | yes | Sample name tag for BAM |
| lane | string | yes | Lane identifier for sample |
| read1_fastq | path | yes | Absolute path to R1 FASTQ |
| read2_fastq | path | yes | Absolute path to R2 FASTQ |

See this [template](input/template-input-FASTQ.csv) for CSV format and this [template](input/template-input-FASTQ.yaml) for YAML format.

### Config Params

| Input Parameter | Type | Required | Description |
| :---: | :--: | :------: | :---------: |
| `input_csv` | path | no | Absolute path to input CSV when using CSV input format |
 `output_dir` | path | yes | Absolute path to directory where output files will be saved |
| `leading_work_dir` | path | yes | Absolute path to **common** working directory (under `/hot` for example for access across all nodes). **Cannot** be `/scratch` |
| `pipeline_work_dir` | path | yes | Absolute path to outputs from each individual pipeline before copying to `output_dir`. Default: `/scratch` |
| `project_id` | string | yes | Project identifier |
| `save_intermediate_files` | boolean | yes | Whether to save intermediate files. Default: `false` |
| `partition` | string | yes | Partition type for submitting each processing jobs |
| `clusterOptions` | string | yes | Additional `slurm` submission options |
| `per_job_cpus` | integer | yes | Number of CPUs per job |
| `per_job_memory` | float | yes | Memory requested per job |
| `max_parallel_jobs` | integer | yes | Number of jobs to submit at once. Default:  5 |
| `sample_mode` | string | yes | Mode for sample calling. Options: `paired`, `single`, `multi`. Default: `paired` |

---

## Outputs

The output of each pipeline is located in its respective directory under the output directory. See individual pipeline documentation for specific outputs.

---

## Discussions

- [Issue tracker](https://github.com/uclahs-cds/metapipeline-DNA/issues) to report errors and enhancement ideas.
- Discussions can take place in [metapipeline-DNA Discussions](https://github.com/uclahs-cds/metapipeline-DNA/discussions)
- [metapipeline-DNA pull requests](https://github.com/uclahs-cds/metapipeline-DNA/pulls) are also open for discussion

---

## Contributors

Please see list of [Contributors](https://github.com/uclahs-cds/metapipeline-DNA/graphs/contributors) at GitHub.

---

## License

metapipeline-DNA is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

metapipeline-DNA performs alignment, germline SNP calling, somatic SNV calling, and mitochondrial SNV calling for given samples.

Copyright (C) 2021-2022 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
