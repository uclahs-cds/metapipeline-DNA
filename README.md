# metapipeline-DNA

- [metapipeline-DNA](#metapipeline-dna)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Pipeline Steps](#pipeline-steps)
    - [1. convert-BAM2FASTQ](#1-convert-bam2fastq)
    - [2. align-DNA](#2-align-dna)
    - [3. recalibrate-BAM]($3-recalibrate-bam)
    - [4. call-gSNP](#4-call-gsnp)
    - [5. call-sSNV](#5-call-ssnv)
    - [6. call-mtSNV](#6-call-mtsnv)
    - [7. call-gSV](#7-call-gsv)
    - [8. call-sSV](#8-call-ssv)
    - [Sample modes](#sample-modes)
  - [Inputs](#inputs)
    - [Input BAM](#input-bam)
    - [Input FASTQ](#input-fastq)
    - [Config Params](#config-params)
      - [UCLAHS-CDS WGS Params](#uclahs-cds-wgs-global-sample-job-submission-parameters)
  - [Outputs](#outputs)
  - [Discussions](#discussions)
  - [Contributors](#contributors)
  - [License](#license)

## Overview

This meta pipeline takes either aligned sequencing data (BAM - <u>**BETA FEATURE**</u>) and converts it back to FASTQ format or direct FASTQ data. The FASTQs are re-aligned to the reference genome and called for germline SNPs (single-nucleotide polymorphisms), somatic SNVs (single-nucleotide variants), mitochondrial SNVs, somatic SVs (structural variants), and germline SVs. The input to this meta pipeline includes a list of patients and their tumor-normal paired samples. Each patient must have **exactly one** normal sample, while multiple tumor samples are allowed. There are 3 available calling modes: paired mode where each tumour sample will be paired with the normal sample for calling; multi mode where all samples for a patient will be called together; single mode where each sample for the patient will be called separately.

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

### 3. recalibrate-BAM

The aligned BAM goes through Indel Realignment and base quality score recalibration using [pipeline-recalibrate-BAM](https://github.com/uclahs-cds/pipeline-recalibrate-BAM).

### 4. call-gSNP

Germline SNPs are then called from the re-calibrated BAMs using [pipeline-call-gSNP](https://github.com/uclahs-cds/pipeline-call-gSNP).

### 5. call-sSNV

The re-calibrated BAMs from step 3 are then used to call somatic SNVs using [pipeline-call-sSNV](https://github.com/uclahs-cds/pipeline-call-sSNV).

### 6. call-mtSNV

The re-calibrated BAMs from step 3 are used to call mitochondrial SNVs using [pipeline-call-mtSNV](https://github.com/uclahs-cds/pipeline-call-mtSNV).

### 7. call-gSV

The re-calibrated BAMs from step 3 are used to call germline structural variants using [pipeline-call-gSV](https://github.com/uclahs-cds/pipeline-call-gSV).

> **Note**: The `run_regenotyping` mode from the call-gSV pipeline is disabled for the metapipeline. Regenotyping should be performed separately at the cohort-level.

### 8. call-sSV

The re-calibrated BAMs from step 3 are used to call for somatic structural variants using [pipeline-call-sSV](https://github.com/uclahs-cds/pipeline-call-sSV).

### Sample modes

The metapipeline supports running samples in three modes: `single`, `paired`, and `multi`.

#### Single sample mode
All samples are processed individually as separate jobs.
- Normal samples will go through germline calling (call-gSNP, call-gSV) and somatic SNV calling with Mutect2's normal-only mode.
- Tumor samples will go through germline calling (call-gSNP) and somatic SNV calling with Mutect2's tumor-only mode.

#### Paired sample mode

All samples from the same patient are processed as a single job.
- Individual samples will go through the convert-BAM2FASTQ and align-DNA pipelines.
- The normal sample will then be paired with each tumor sample and each pair will go through recalibrate-BAM, call-gSNP, call-sSNV, call-mtSNV, and call-sSV.
- The normal sample will go through call-gSV.

#### Multi sample mode

All samples from the same patient are processed as a single job.
- Individual samples will go through the convert-BAM2FASTQ and align-DNA pipelines.
- The recalibration and germline SNP calling will then proceed on the entire set of samples together.
- Somatic SNV calling will proceed in two ways:
    1. The normal sample will be paired with each tumor sample and run through the call-sSNV pipeline
    2. If Mutect2 was requested, the entire set of samples will go through multi-sample calling with just Mutect2 in call-sSNV.
- The normal sample will be paired with each tumor sample and each pair will go through call-mtSNV and call-sSV.
- The normal sample will go through call-gSV.

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
| `output_dir` | path | yes | Absolute path to directory where output files will be saved |
| `leading_work_dir` | path | yes | Absolute path to **common** working directory (under `/hot` for example for access across all nodes). **Cannot** be `/scratch` |
| `pipeline_work_dir` | path | yes | Absolute path to outputs from each individual pipeline before copying to `output_dir`. Default: `/scratch` |
| `project_id` | string | yes | Project identifier |
| `save_intermediate_files` | boolean | yes | Whether to save intermediate files. Default: `false` |
| `partition` | string | yes | Partition type for submitting each processing jobs |
| `clusterOptions` | string | yes | Additional `slurm` submission options |
| `max_parallel_jobs` | integer | yes | Number of jobs to submit at once. Default:  5 |
| `cluster_submission_interval` | integer | yes | Time in minutes to wait between job submissions, Default: 90 |
| `sample_mode` | string | yes | Mode for sample calling. Options: `paired`, `single`, `multi`. Default: `paired` |
| `requested_pipelines` | list | yes | List of pipelines requested. |
| `override_realignment` | boolean | yes | Whether to override conversion to FASTQ and realignment when given BAM input. Default: `false` |
| `override_recalibrate_bam` | boolean | yes | Whether to override recalibrate-BAM pipeline when given BAM input. Default: `false` |

#### UCLAHS-CDS WGS global sample job submission parameters

The following parameters are intended to control the global number and rate of WGS jobs. By default, these parameters are enabled; in the case of non-WGS samples, disable `uclahs_cds_wgs` in the config file params.

| Input Parameter | Type | Required | Description |
| :---: | :--: | :------: | :---------: |
| `uclahs_cds_wgs` | boolean | yes | Whether global job number and submission limits should be applied. Default: `true` |
| `global_allowed_jobs` | integer | yes | Global number of WGS jobs allowed. Default: 12 |
| `per_user_allowed_jobs` | integer | yes | Number of jobs allowed to be running per-user. Default: 3 |
| `global_rate_limit` | integer | yes | Time in minutes between submission of any WGS jobs. Default: 90 |

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

Copyright (C) 2021-2023 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
