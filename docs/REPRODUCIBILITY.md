# Reproducibility Notes

## Scope

This repository reproduces manuscript numerical summaries and regenerates result figures from locked derived outputs. Figure files and manuscript submission files are not committed to this lean public archive. It is not a full raw-waveform preprocessing repository and does not include source ECG waveforms.

## Required Runtime

The final figures were generated in R using ggplot2, ggprism, patchwork, readr, dplyr, tidyr, jsonlite, scales, svglite, and ragg. Package versions from the generating environment are recorded in `environment/R_SESSION_INFO_20260525.txt`.

## Figure Rebuild

From the repository root:

```powershell
Rscript scripts/build_full_r_ggprism_figure_set.R
```

Expected local outputs:

- `figures/final_locked/Figure2_external_multicohort_policy_validation_locked.pdf`
- `figures/final_locked/Figure3_patient_any_abnormal_offline_triage_locked.pdf`
- `figures/final_locked/Figure4_transportability_subgroup_stress_locked.pdf`
- `figures/supplementary_locked/Supplementary_Figure_S1_calibration_reliability.pdf`
- `figures/supplementary_locked/Supplementary_Figure_S2_decision_curve_analysis.pdf`
- `figures/supplementary_locked/Supplementary_Figure_S3_target_recalibration_sensitivity.pdf`
- `figures/supplementary_locked/Supplementary_Figure_S4_scarcity_pool_behavior.pdf`
- `figures/supplementary_locked/Supplementary_Figure_S5_subgroup_stress_detail.pdf`
- `figures/supplementary_locked/Supplementary_Figure_S6_certification_diagnostics.pdf`

Figure 1 is a schematic and is not regenerated from result tables. The final submission package maintains that artwork separately.

## Manuscript Rebuild

The public GitHub repository does not include manuscript source or compiled manuscript PDFs. The submitted manuscript package is maintained separately from this reproducibility repository to avoid archiving editorial submission materials in the DOI record.

## Locked Outputs

The manuscript figures and result tables are derived from locked CSV/JSON outputs under:

- `data/locked_tables/`
- `data/multicohort/`

The SHA-256 manifest in `metadata/file_manifest_sha256.csv` records release-file hashes.

Regenerate the manifest after intentional release-content changes with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/make_release_manifest.ps1
```
