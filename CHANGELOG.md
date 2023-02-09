# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

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
