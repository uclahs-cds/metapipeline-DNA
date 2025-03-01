# Changelog

All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- StableLift for sSNV liftover
- StableLift for SV liftover
- StableLift for gSNP liftover
- Annotate-VCF for gSNP

### Changed

- Update module and config submodules

## [6.2.0] - 2024-11-22

### Changed

- Convert-BAM2FASTQ: `2.0.0-rc.2` -> `2.0.0`

## [6.1.0] - 2024-11-08

### Added

- Additional tests at the configuration level

### Changed

- Update README
- Add sanitization to sample IDs to account for standardized filenames

## [6.0.0] - 2024-07-10

### Changed

- Call-SRC: `2.0.0-rc.1` -> `2.0.0`
- Align-DNA: `10.0.0` -> `10.1.0`
- Recalibrate-BAM: `1.0.0` -> `1.0.1`
- Call-sSNV: `8.0.0` -> `8.1.0`
- Call-gSV: `5.0.0` -> `5.2.0`
- Call-sCNA: `3.1.0` -> `3.2.0`

### Fixed

- Issue with empty email addresses resulting in argument errors

## [6.0.0-rc.6] - 2024-06-12

### Added

- Support for inputs to be given through a CSV
- Nextflow wrapper script to capture and consolidate all pipeline logs for a sample
- `status_email_address` parameter to send started/completed emails for child pipelines

### Fixed

- Bug with bad params being loaded from default configs
- Bug with call-SRC pipeline getting stuck with DPClust run

## [6.0.0-rc.5] - 2024-05-29

### Fixed

- Issue with identifier used in WGS mode

## [6.0.0-rc.5] - 2024-05-23 - YANKED

### Added

- Call-SRC pipeline

### Changed

- Input format update to only YAML and to support combinations or BAM/CRAM/FASTQ/SRC inputs

### Fixed

- Issue with status check automatically skipping checks when Slurm commands fail

## [6.0.0-rc.4] - 2024-05-15

### Fixed

- Task hash properly handled between WGS and non-WGS modes
- Job submission properly restricted when Slurm query fails

## [6.0.0-rc.3] - 2024-05-13

### Added

- More descriptive error messages on failure to identify output files
- Add call-sCNA to `requested_pipelines` in `template.config`
- Handling for SRC inputs
- Save nextflow logs sample/patient-specific metapipeline. #187

### Changed

- Use GitHub container registry CI/CD check
- Calculate-targeted-coverage: `1.0.0-rc.2` -> `1.1.0`
- Call-gSNP: `10.0.0` -> `10.0.1`
- Align-DNA: `10.0.0-rc.1` -> `10.0.0`
- Call-mtSNV: `4.0.0-rc.1` -> `4.0.0`
- Call-gSV: `5.0.0-rc.1` -> `5.0.0`
- Call-sCNA: `3.0.0` -> `3.1.0`
- Require parameters only for pipelines being run
- Validate parameters only for pipelines being run

### Fixed

- Issue with status check function not properly detecting and reporting pipeline failures
- Issue with pipeline-specific `default.config` overriding parameter settings in metapipeline config

## [6.0.0-rc.2] - 2024-03-22

### Added

- BAM sample QC pipeline `v1.0.0`

### Changed

- Call-sSNV: `8.0.0-rc.1` -> `8.0.0`
- Call-gSNP: `10.0.0-rc.3` -> `10.0.0`
- Call-mtSNV: `3.0.0` -> `4.0.0-rc.1`
- Call-gSV: `4.0.1` -> `5.0.0-rc.1`
- Recalibrate-BAM: `1.0.0-rc.4` -> `1.0.0`
- call-sSV: `6.0.0-rc.1` -> `6.1.0`
- Allow downstream pipelines to fail gracefully without affecting failure of other pipelines
- Allow waiting on multiple dependencies per pipeline before submission

### Fixed

- Recalibrate-BAM no longer runs automatically when not requested

## [6.0.0-rc.1] - 2024-03-11

### Added

- pipeline-call-sCNA `v3.0.0` and its NFTest
- Targeted coverage pipeline
- Option to skip recalibrate-BAM independent of alignment

### Changed

- Convert-BAM2FASTQ: 2.0.0-rc.1 -> 2.0.0-rc.2
- Align-DNA: 9.0.0 -> 10.0.0-rc.1
- Sanitize metadata passed to align-DNA
- Calculate-targeted-coverage: update name from targeted-coverage
- Save logs and input files for all pipelines
- Update test samples

## [5.3.1] - 2024-01-10

### Added

- Pipeline ordering option for pipelines downstream of recalibrate-BAM
- Parameter to run pipelines sequentially

### Changed

- Call-sSNV: 7.0.0-rc.2 -> 8.0.0-rc.1

## [5.2.1] - 2023-12-07

### Removed

- Remove validation of pipeline-level parameter from metapipeline level validation

## [5.2.0] - 2023-11-17

### Added

- Deletion step for normal BAMs when running multi-sample patients in paired mode

### Changed

- Default to alt-aware reference for align-DNA
- Re-order FASTQ CSV to match order in align-DNA

## [5.1.0] - 2023-10-30

### Changed

- Make WGS limits dynamically configurable

## [5.0.0] - 2023-10-25

### Changed

- Use data structure in params to pass outputs between pipelines
- Update tests
- Update README with current status and parameters

## [5.0.0-rc.10] - 2023-10-10

### Changed

- Update call-sSV `actual` paths in `nftest.yaml`
- Update input structure for call-sSV `6.0.0-rc.1`
- Update call-sSV `6.0.0-rc.1`
- Update tests to conform to pipeline and [nftest](https://github.com/uclahs-cds/tool-NFTest) updates.
- Call-sSNV: 5.0.0 -> 7.0.0-rc.2

## [5.0.0-rc.9] - 2023-08-24

### Changed

- Split call-gSNP into recalibrate-BAM and call-gSNP
- Call-sSNV: 5.0.0 -> 7.0.0-rc.1

## [5.0.0-rc.8] - 2023-08-11

### Changed

- Pass pipeline-specific params through a YAML instead of commandline string

### Fixed

- Call-sSNV outputs no longer overwritten when encountering paired samples in `multi` mode
- Allow pipelines to run under job-specific work_dir

## [5.0.0-rc.7] - 2023-08-03

### Added

- Incorporate user-defined sample-name for "SM" tags when starting from BAM2FASTQ

## [5.0.0-rc.6] - 2023-07-13

### Added

- Working directory hashes to global limiter job names
- Separate WGS vs non-WGS queues

## [5.0.0-rc.5] - 2023-06-16

### Added

- Global job volume and submission rate limiter

### Changed

- Handle pipeline-specific params without a hard-coded list per pipeline
- Update tests for current pipeline versions
- Update handling of `output_dir` param to avoid modifications

### Fixed

- BAM SM tag handling for call-gSNP output filenames
- Empty intervals parameters

## [5.0.0-rc.4] - 2023-05-04

### Added

- Parameter validation
- Custom schema types with parameter validation

### Changed

- Standardize process and script names
- Automatically detect CPU and memory for specified partition type
- Automate setting of subworkflow CPUs
- Divide `/scratch` into pipeline-specific directories for deletion once pipeline ends
- Slurm job name to include work directory path

### Removed

- Unnecessary `index` field in FASTQ input

## [5.0.0-rc.3] - 2023-02-08

### Added

- Option for intermediate file saving per pipeline

## [5.0.0-rc.2] - 2023-02-06

### Changed

- align-DNA: 8.1.0 -> 9.0.0
- call-gSNP: 9.2.0 -> 9.2.1
- call-sSV: 4.0.0 -> 5.0.0

### Fixed

- Output tuple emission syntax
- Pipeline selection with FASTQ input

## [5.0.0-rc.1] - 2023-01-30

### Added

- Pipeline selection options
- Default BAM read group tag values

### Changed

- Replace tuples with Maps for clarity

## [4.0.0] - 2022-12-19

### Added

- call-gSV v4.0.0
- call-sSV v4.0.0

### Changed

- Parameterize time interval between job submissions
- call-gSV: 4.0.0 -> 4.0.1

## [3.0.0] - 2022-11-23

### Changed

- call-sSNV: 4.0.1 -> 5.0.0
- call-gSNP: 9.1.0 -> 9.2.0

## [3.0.0-rc.1] - 2022-11-08

### Added

- Support for single-sample mode (single normal and single tumor samples)

### Changed

- convert-BAM2FASTQ: v2.0.0-rc.1

## [2.0.0] - 2022-10-13

### Added

- Additional call-gSNP params

### Changed

- Extract submodule version from `nextflow.config`
- Identify gSNP `sample_id` based on run mode

## [2.0.0-rc.1] - 2022-09-30

### Added

- Pipeline selection module
- Option for multi-sample gSNP calling
- Option for multi-sample sSNV Mutect2 calling

### Changed

- Merge configs into one config
- call-mtSNV: 3.0.0-rc.1 -> 3.0.0
- call-gSNP: 9.0.1 -> 9.1.0
- align-DNA: 8.0.0 -> 8.1.0
- Standardize directories to use singular form

## [1.0.0] - 2022-07-29

### Changed

- Use `executor` rate limit to limit job submission rate rather than custom sleep command

## [1.0.0-rc.1] - 2022-07-15

### Added

- Main pipelines, including convert-BAM2FASTQ, align-DNA, call-gSNP, call-sSNV, and call-mtSNV.
- "Unit tests" with a downsampled CPTAC WGS sample.
- Nextflow testing module
- Checks for working directories
- YAML input
- GPL2 license

### Changed

- Standardize output directory
- Reduce number of temp files in /hot
- align-DNA: 7.3.1 -> 8.0.0
- call-gSNP: 7.2.1 -> 9.0.1
- call-sSNV: 3.0.0-rc.1 -> 4.0.1
- Automatically set the work_dir parameter for ucla_cds
- Update README
- Main process `errorStrategy` set to `ignore`
- call-mtSNV: 2.0.0 -> 3.0.0-rc.1
- Standardize output directory

### Removed

- `site` from inputs

### Fixed

- Remove carriage-return/Windows-specific characters from input examples

[1.0.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v1.0.0-rc.1...v1.0.0
[1.0.0-rc.1]: https://github.com/uclahs-cds/metapipeline-DNA/releases/tag/v1.0.0-rc.1
[2.0.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v2.0.0-rc.1...v2.0.0
[2.0.0-rc.1]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v1.0.0...v2.0.0-rc.1
[3.0.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v3.0.0-rc.1...v3.0.0
[3.0.0-rc.1]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v2.0.0...v3.0.0-rc.1
[4.0.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v3.0.0...v4.0.0
[5.0.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.10...v5.0.0
[5.0.0-rc.1]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v4.0.0...v5.0.0-rc.1
[5.0.0-rc.10]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.9...v5.0.0-rc.10
[5.0.0-rc.2]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.1...v5.0.0-rc.2
[5.0.0-rc.3]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.2...v5.0.0-rc.3
[5.0.0-rc.4]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.3...v5.0.0-rc.4
[5.0.0-rc.5]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.4...v5.0.0-rc.5
[5.0.0-rc.6]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.5...v5.0.0-rc.6
[5.0.0-rc.7]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.6...v5.0.0-rc.7
[5.0.0-rc.8]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.7...v5.0.0-rc.8
[5.0.0-rc.9]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0-rc.8...v5.0.0-rc.9
[5.1.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.0.0...v5.1.0
[5.2.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.1.0...v5.2.0
[5.2.1]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.2.0...v5.2.1
[5.3.1]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.2.1...v5.3.1
[6.0.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0-rc.6...v6.0.0
[6.0.0-rc.1]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v5.3.1...v6.0.0-rc.1
[6.0.0-rc.2]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0-rc.1...v6.0.0-rc.2
[6.0.0-rc.3]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0-rc.2...v6.0.0-rc.3
[6.0.0-rc.4]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0-rc.3...v6.0.0-rc.4
[6.0.0-rc.5]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0-rc.5...v6.0.0-rc.5
[6.0.0-rc.6]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0-rc.5...v6.0.0-rc.6
[6.1.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.0.0...v6.1.0
[6.2.0]: https://github.com/uclahs-cds/metapipeline-DNA/compare/v6.1.0...v6.2.0
