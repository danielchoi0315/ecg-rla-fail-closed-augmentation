# Governance and Limitations

The study evaluates a fail-closed certification policy for deciding when synthetic ECG augmentation is authorized during training. The policy is not a prospective clinical deployment system.

Key boundaries:

- Certification is development-domain evidence, not a formal distribution-free guarantee.
- Report cells are experimental policy cells, not patients.
- Harm rates are algorithmic performance-degradation rates over report cells.
- Decision-curve and triage analyses are retrospective offline proxies.
- Leipzig analyses are out-of-distribution stress tests, not validation for pediatric or congenital-heart-disease clinical use.
- Privacy and memorization audits should be added before releasing any synthetic ECG pools.
- No raw ECG waveforms are released in this repository.

This repository supports reproducibility and peer review. It should not be used for clinical decision-making.

