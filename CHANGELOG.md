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
### Changed
+ Standardize output directory
+ Reduce number of temp files in /hot
+ align-DNA: 7.3.1 -> 8.0.0
+ call-gSNP: 7.2.1 -> 8.0.0
