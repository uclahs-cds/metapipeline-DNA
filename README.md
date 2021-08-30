# Pipeline Name

- [Pipeline Name](#pipeline-name)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Pipeline Steps](#pipeline-steps)
    - [1. Step/Proccess 1](#1-stepproccess-1)
    - [2. Step/Proccess 2](#2-stepproccess-2)
    - [3. Step/Proccess n](#3-stepproccess-n)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Testing and Validation](#testing-and-validation)
    - [Test Data Set](#test-data-set)
    - [Validation <version number\>](#validation-version-number)
    - [Validation Tool](#validation-tool)
  - [References](#references)

## Overview

A 3-4 sentence summary of the pipeline, including the pipeline's purpose, the type of expected scientific inputs/outputs of the pipeline (e.g: FASTQs and BAMs), and a list of tools/steps in the pipeline.

---

## How To Run

1. Update the params section of the .config file

2. Update the input csv

3. See the submission script, [here](https://github.com/uclahs-cds/tool-submit-nf), to submit your pipeline

---

## Flow Diagram

A directed acyclic graph of your pipeline.

![alt text](pipeline-name-DAG.png?raw=true)

---

## Pipeline Steps

### 1. Step/Proccess 1

> A 2-3 sentence description of each step/proccess in your pipeline that includes the purpose of the step/process, the tool(s) being used and their version, and the expected scientific inputs/outputs (e.g: FASTQs and BAMs) of the pipeline.

### 2. Step/Proccess 2

> A 2-3 sentence description of each step/proccess in your pipeline that includes the purpose of the step/process, the tool(s) being used and their version, and the expected scientific inputs/outputs (e.g: FASTQs and BAMs) of the pipeline.

### 3. Step/Proccess n

> A 2-3 sentence description of each step/proccess in your pipeline that includes the purpose of the step/process, the tool(s) being used and their version, and the expected scientific inputs/outputs (e.g: FASTQs and BAMs) of the pipeline.

---

## Inputs

 Input and Input Parameter/Flag | Required | Description |
| ------------ | ------------ | ------------------------ |
| input/ouput 1 | yes/no | 1 - 2 sentence description of the input/output. |
| input/ouput 2 | yes/no | 1 - 2 sentence description of the input/output. |
| input/ouput n | yes/no | 1 - 2 sentence description of the input/output. |

---

## Outputs

 Output and Output Parameter/Flag | Required | Description |
| ------------ | ------------ | ------------------------ |
| input/ouput 1 | yes/no | 1 - 2 sentence description of the input/output. |
| input/ouput 2 | yes/no | 1 - 2 sentence description of the input/output. |
| input/ouput n | yes/no | 1 - 2 sentence description of the input/output. |

---

## Testing and Validation

### Test Data Set

A 2-3 sentence description of the test data set(s) used to validate and test this pipeline. If possible, include references and links for how to access and use the test dataset

### Validation <version number\>

 Input/Output | Description | Result  
 | ------------ | ------------------------ | ------------------------ |
| metric 1 | 1 - 2 sentence description of the metric | quantifiable result |
| metric 2 | 1 - 2 sentence description of the metric | quantifiable result |
| metric n | 1 - 2 sentence description of the metric | quantifiable result |

- [Reference/External Link/Path 1 to any files/plots or other validation results](<link>)
- [Reference/External Link/Path 2 to any files/plots or other validation results](<link>)
- [Reference/External Link/Path n to any files/plots or other validation results](<link>)

### Validation Tool

Included is a template for validating your input files. For more information on the tool check out: https://github.com/uclahs-cds/tool-validate-nf

---

## References

1. [Reference 1](<links-to-papers/external-code/documentation/metadata/other-repos/or-anything-else>)
2. [Reference 2](<links-to-papers/external-code/documentation/metadata/other-repos/or-anything-else>)
3. [Reference n](<links-to-papers/external-code/documentation/metadata/other-repos/or-anything-else>)
