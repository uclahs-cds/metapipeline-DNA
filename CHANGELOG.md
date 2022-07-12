# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]
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
### Removed
+ `site` from inputs
