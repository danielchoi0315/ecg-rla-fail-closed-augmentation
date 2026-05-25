# Data Sources

This repository does not redistribute source ECG waveforms. The analysis used public ECG datasets that must be accessed through their original providers.

## Development Domain

- PTB-XL v1.0.3
  - Development/source domain.
  - Used for model fitting, utility screening, and certification splits.

## Primary External Validation

- ECG-Arrhythmia v1.0.0
  - Primary external validation cohort.
  - Used for macro-AUPRC policy comparison and patient-level any-abnormal evaluation.

## Secondary External Cohorts

- CPSC2018
- Chapman-Shaoxing / PhysioNet Challenge 2020-derived ECG resources
- G12EC / PhysioNet Challenge 2020-derived ECG resources

These cohorts were used for multicohort robustness analyses after the primary ECG-Arrhythmia result was locked.

## Stress Test

- Leipzig Heart Center ECG-Database v1.0.0
  - Out-of-distribution stress-test dataset.
  - Not treated as co-primary clinical validation.

## Redistribution Boundary

The repository includes derived result tables and figure source files. It excludes raw ECG waveforms, source dataset files, and private identifiable information.

