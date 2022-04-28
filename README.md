# germline-somatic

- [germline-somatic](#germline-somatic)
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
    - [Input CSV](#input-csv)

## Overview

This meta pipeline takes aligned WGS data (BAM), convert them back to FASTQ, re-align to the reference genome, and calls for germline SNPs, somatic SNVs and mitochondrial SNVs. The input of this meta pipeline is a CSV file with a list of patients and their tumor normal paired BAM samples. Each patient must have **exact one** normal sample, while multiple tumor samples are allowed. If a patient has multiple tumor samples, each tumor is paired with the normal an it will call gSNP, sSNV and mtSNV separately.

The pipeline has a leading process running on the submitter node (can be a F2 node) that submits processes of all pipelines (align-DNA, call-gSNP etc.) on all samples of the patient to the same worker node (usually a F72 node). All processes for the same patient run on the sample node to avoid network traffic.

![design](img/design.drawio.svg?raw=true)

---

## How To Run

1. Creating a leading [`lead.config`](config/template_meta-lead.config) and a patient specific [`meta-pipeline.config`](config/template_meta-pipeline.config) file, using the template given in the links. The former `lead.config` takes the patient sample list, while the latter one defines the parameters, reference files, and resources configurations for each run.

2. Create an [input.csv](inputs/template-inputs.csv) fille with path to the BAM files of each patient with both normal and tumor. For example patient, there must be exactly one sample that the `state` column is `normal`, while the other samples are `tumor`. It is then able to create each tumor with the only normal sample within this patient.

3. See the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit your pipeline

> :warning: A low memory node (*e.g* F2) is sufficient for the leading job. Submitting the leading job to a F72 node is wasty!

---

## Flow Diagram

![alt text](img/diagram.drawio.svg?raw=true)

---

## Pipeline Steps

### 1. convert-BAM2FASTQ

Aligned BAM file for each sample is first converted back to FASTQ using [pipeline-convert-BAM2FASTQ](https://github.com/uclahs-cds/pipeline-convert-BAM2FASTQ/).

### 2. align-DNA

The FASTQ file for each sample is then realigned to the genome using [pipeline-align-DNA](https://github.com/uclahs-cds/pipeline-align-DNA).

### 3. call-gSNP

Germline SNP is then called from the re-aligned BAM files using [pipeline-call-gSNP](https://github.com/uclahs-cds/pipeline-call-gSNP). The call-gSNP also performs BAM calibration. Tumor and normal samples from the sam patient are paired in this step.

### 4. call-sSNV

The calibrated BAM from step 3 is then used to call for somatic SNVs using [pipeline-call-sSNV](https://github.com/uclahs-cds/pipeline-call-sSNV).

### 5. call-mtSNV

The same calibrated BAM from step 3 is also used to call for mitochondrial SNVs usint [pipeline-call-mtSNV](https://github.com/uclahs-cds/pipeline-call-mtSNV)

---

## Inputs

### Input CSV

The input CSV file must contain 5 fields as listed below.

| Parameter/Flag | Description                                |
| -------------- | ------------------------------------------ |
| patient        | Patient ID                                 |
| sample         | Sample ID                                  |
| state          | Must be either "tumor" or "normal"         |
| site           | The site of sample (*e.g.* primary, blood) |
| bam            | Absolute path to the BAM file.             |

See this [template](input/template-inputs.csv),
