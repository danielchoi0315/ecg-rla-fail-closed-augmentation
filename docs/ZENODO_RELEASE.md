# Zenodo DOI Release Workflow

This repository includes `.zenodo.json`, `CITATION.cff`, locked result tables, figure-generation scripts, and release-ready metadata. It intentionally excludes generated figure files and manuscript submission files from Git; those outputs can be regenerated or maintained separately.

## Preferred Workflow Through GitHub Integration

1. Log in to Zenodo with the GitHub account that owns this repository.
2. Go to Zenodo GitHub integration.
3. Enable archiving for `danielchoi0315/ecg-rla-fail-closed-augmentation`.
4. Create a GitHub release, for example `v1.0.0`.
5. Zenodo will archive the release and mint a DOI.
6. Add the DOI badge and DOI text back into `README.md` and `CITATION.cff`.
7. If the manuscript has not yet been submitted, update the Code Availability section with the repository URL and DOI.

## Direct Zenodo API Alternative

If using the Zenodo API, create a personal access token with deposit permissions and store it locally as `ZENODO_ACCESS_TOKEN`. Do not commit the token.

The archive should include the GitHub release source archive or the repository zip produced from the tagged release. Do not include raw ECG waveforms.
