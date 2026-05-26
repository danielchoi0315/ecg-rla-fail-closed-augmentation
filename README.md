# Fail Closed Synthetic ECG Augmentation for External Clinical AI Validation

This repository contains the lean reproducibility package for the manuscript **"Fail Closed Synthetic ECG Augmentation for External Clinical AI Validation"**.

The study evaluates a fail-closed certification policy for synthetic 12-lead ECG augmentation. PTB-XL is used as the development domain; ECG-Arrhythmia is the primary external validation cohort; CPSC2018 and G12EC are secondary external cohorts; Chapman-Shaoxing is retained only as a provenance-sensitivity analysis because of public-source overlap concerns with ECG-Arrhythmia provenance; Leipzig is reserved as an out-of-distribution stress test.

## What Is Included

- Locked result tables used for the manuscript and figures.
- Multicohort summary tables for the final external validation figure.
- R/ggplot2/ggprism figure-generation script.
- Build metadata, environment information, and integrity manifests.
- SHA-256 manifest generation and integrity-check script.

## What Is Not Included

This repository does **not** redistribute source ECG waveforms. The public datasets must be obtained from the original providers under their own licenses, access terms, and citation requirements.

The included tables are derived analysis outputs intended to reproduce the manuscript figures and numerical summaries. They are not intended for clinical use or patient-level decision-making.

## Repository Layout

```text
data/locked_tables/          Locked primary result tables and patient-level summaries
data/multicohort/            Secondary cohort and multicohort summary files
scripts/                    Figure-generation and integrity-check scripts
docs/                       Reproducibility and governance notes
metadata/                   Build logs, export QA, and SHA-256 manifest
environment/                R session information
```

## Reproducing Figures

Install R and the packages listed in `environment/R_SESSION_INFO_20260525.txt`. The final figures can be regenerated with:

```powershell
Rscript scripts/build_full_r_ggprism_figure_set.R
```

The script reads from `data/locked_tables/` and `data/multicohort/`. Generated figure outputs are written locally under `figures/`, which is intentionally ignored by Git.

## Integrity Check

After cloning or downloading the archive, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check_release_integrity.ps1
```

This recomputes SHA-256 hashes for all tracked release files and compares them with `metadata/file_manifest_sha256.csv`.

To regenerate the manifest after an intentional release-content change:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/make_release_manifest.ps1
```

## Data Sources

This work uses public ECG resources from their original providers:

- PTB-XL v1.0.3
- ECG-Arrhythmia v1.0.0
- Leipzig Heart Center ECG-Database v1.0.0
- CPSC2018
- Chapman-Shaoxing / PhysioNet-Challenge-derived ECG resources (provenance-sensitivity analysis only)
- G12EC / PhysioNet-Challenge-derived ECG resources

Please cite and access these datasets through their original pages and publications. See `docs/DATA_SOURCES.md` for details.

## Clinical Use

This is a retrospective offline validation package. It does not establish prospective clinical benefit and must not be used as a clinical diagnostic tool.

## Citation

If using this repository, cite the archived Zenodo DOI, [10.5281/zenodo.20400510](https://doi.org/10.5281/zenodo.20400510), and the manuscript when published. A machine-readable citation file is provided in `CITATION.cff`.
