# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]
### Added
+ Deletion step for normal BAMs when running multi-sample patients in paired mode

---

## [5.2.0] - 2023-11-17
### Changed
+ Default to alt-aware reference for align-DNA
+ Re-order FASTQ CSV to match order in align-DNA

---

## [5.1.0] - 2023-10-30
### Changed
+ Make WGS limits dynamically configurable

---

## [5.0.0] - 2023-10-25
### Changed
+ Use data structure in params to pass outputs between pipelines
+ Update tests
+ Update README with current status and parameters

---

## [5.0.0-rc.10] - 2023-10-10
### Changed
+ Update call-sSV `actual` paths in `nftest.yaml`
+ Update input structure for call-sSV `6.0.0-rc.1`
+ Update call-sSV `6.0.0-rc.1`
+ Update tests to conform to pipeline and [nftest](https://github.com/uclahs-cds/tool-NFTest) updates.
+ Call-sSNV: 5.0.0 -> 7.0.0-rc.2

---

## [5.0.0-rc.9] - 2023-08-24
### Changed
+ Split call-gSNP into recalibrate-BAM and call-gSNP
+ Call-sSNV: 5.0.0 -> 7.0.0-rc.1

---

## [5.0.0-rc.8] - 2023-08-11
### Changed
+ Pass pipeline-specific params through a YAML instead of commandline string
### Fixed
+ Call-sSNV outputs no longer overwritten when encountering paired samples in `multi` mode
+ Allow pipelines to run under job-specific work_dir

---

## [5.0.0-rc.7] - 2023-08-03
### Added
+ Incorporate user-defined sample-name for "SM" tags when starting from BAM2FASTQ

---

## [5.0.0-rc.6] - 2023-07-13
### Added
+ Working directory hashes to global limiter job names
+ Separate WGS vs non-WGS queues

---

## [5.0.0-rc.5] - 2023-06-16
### Added
+ Global job volume and submission rate limiter
### Changed
+ Handle pipeline-specific params without a hard-coded list per pipeline
+ Update tests for current pipeline versions
+ Update handling of `output_dir` param to avoid modifications
### Fixed
+ BAM SM tag handling for call-gSNP output filenames
+ Empty intervals parameters

---

## [5.0.0-rc.4] - 2023-05-04
### Added
+ Parameter validation
+ Custom schema types with parameter validation
### Changed
+ Standardize process and script names
+ Automatically detect CPU and memory for specified partition type
+ Automate setting of subworkflow CPUs
+ Divide `/scratch` into pipeline-specific directories for deletion once pipeline ends
+ Slurm job name to include work directory path
### Removed
+ Unnecessary `index` field in FASTQ input

---

## [5.0.0-rc.3] - 2023-02-08
### Added
+ Option for intermediate file saving per pipeline

---

## [5.0.0-rc.2] - 2023-02-06
### Changed
+ align-DNA: 8.1.0 -> 9.0.0
+ call-gSNP: 9.2.0 -> 9.2.1
+ call-sSV: 4.0.0 -> 5.0.0
### Fixed
+ Output tuple emission syntax
+ Pipeline selection with FASTQ input

---

## [5.0.0-rc.1] - 2023-01-30
### Added
+ Pipeline selection options
+ Default BAM read group tag values
### Changed
+ Replace tuples with Maps for clarity

---

## [4.0.0] - 2022-12-19
### Added
+ call-gSV v4.0.0
+ call-sSV v4.0.0
### Changed
+ Parameterize time interval between job submissions
+ call-gSV: 4.0.0 -> 4.0.1

---

## [3.0.0] - 2022-11-23
### Changed
+ call-sSNV: 4.0.1 -> 5.0.0
+ call-gSNP: 9.1.0 -> 9.2.0

---

## [3.0.0-rc.1] - 2022-11-08
### Added
+ Support for single-sample mode (single normal and single tumor samples)
### Changed
+ convert-BAM2FASTQ: v2.0.0-rc.1

---

## [2.0.0] - 2022-10-13
### Added
+ Additional call-gSNP params
### Changed
+ Extract submodule version from `nextflow.config`
+ Identify gSNP `sample_id` based on run mode

---

## [2.0.0-rc.1] - 2022-09-30
### Added
+ Pipeline selection module
+ Option for multi-sample gSNP calling
+ Option for multi-sample sSNV Mutect2 calling
### Changed
+ Merge configs into one config
+ call-mtSNV: 3.0.0-rc.1 -> 3.0.0
+ call-gSNP: 9.0.1 -> 9.1.0
+ align-DNA: 8.0.0 -> 8.1.0
+ Standardize directories to use singular form

---

## [1.0.0] - 2022-07-29
### Changed
+ Use `executor` rate limit to limit job submission rate rather than custom sleep command

---

## [1.0.0-rc.1] - 2022-07-15
### Added
+ Main pipelines, including convert-BAM2FASTQ, align-DNA, call-gSNP, call-sSNV, and call-mtSNV.
+ "Unit tests" with a downsampled CPTAC WGS sample.
+ Nextflow testing module
+ Checks for working directories
+ YAML input
+ GPL2 license
### Changed
+ Standardize output directory
+ Reduce number of temp files in /hot
+ align-DNA: 7.3.1 -> 8.0.0
+ call-gSNP: 7.2.1 -> 9.0.1
+ call-sSNV: 3.0.0-rc.1 -> 4.0.1
+ Automatically set the work_dir parameter for ucla_cds
+ Update README
+ Main process `errorStrategy` set to `ignore`
+ call-mtSNV: 2.0.0 -> 3.0.0-rc.1
+ Standardize output directory
### Removed
+ `site` from inputs
### Fixed
+ Remove carriage-return/Windows-specific characters from input examples
