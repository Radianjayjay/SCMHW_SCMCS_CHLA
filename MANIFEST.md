# Release manifest

## Inclusion rule

This release contains only the code that generates the main-text figures (Figures 1–6) of the manuscript: the plotting scripts that compute plot-data caches from precomputed event-level inputs, and the composite scripts that assemble the final figures, together with the documentation needed to identify dependencies and input provenance.

Both the upstream analysis pipeline and the supplementary-figure code are intentionally not part of this release; this archive documents the pipeline outputs as inputs rather than re-implementing or redistributing them.

## Included source groups

- `figure_code/` cache-building scripts: `Plot_00_MHW_MCS_Spatial_Distribution.m`, `Plot_03_Lag_Response.m`, `Plot_05_Peak_Location_Maps.m`, `Plot_06_CHLA_Micro_Dominance.m`, `Plot_07_Physical_Mechanism_MLD_CHLA_PSC.m`, `Plot_08_Peak_Day_Bin_Density_Maps.m`
- `figure_code/` figure composites: `Composite_01_L1L2L3_Map.m` (Figure 1), `Composite_02_CHLA_Response.m` (Figures 2–4), `Composite_05_PSC_HeatMap.m` (Figure 5), `Composite_06_CHLA_MLD.m` (Figure 6)

`Composite_01` and `Composite_02` also render the duration and maximum-area variants of the same composites (published as Supplementary Figures S1–S5); no separate code exists or is needed for those variants.

## Intentionally excluded

- All upstream pipeline code: grid-cell MHW/MCS detection, basin tagging, DBSCAN clustering, event statistics, and event-characteristic computation (by release scope)
- All supplementary-only figure and table code: the background-PSC-climatology pair (`Plot_02b`, `Composite_07`), the standalone MLD lag-response analysis (`Plot_04`), the recovery/event-end diagnostics (`Plot_10`), the k-distance and MinPts-sensitivity figure scripts, and the MLD event-series preprocessing stage
- Exploratory and non-manuscript plotting work: alternative peak-centre and PSC-distribution figures, response-map work, peak-footprint maps, response-decomposition diagnostics, and superseded legacy entry points
- Raw or derived `.nc`, `.mat`, `.xlsx`, `.pptx`, `.docx`, `.pdf`, `.png`, `.tif`, and `.tiff` files
- `In`, `Out`, `Cache`, notebook outputs, and Python cache directories
- Manuscript and figure documents; internal project-planning, handoff, and memory records
- Machine-specific SLURM launch scripts and all Python processing code
- `03_CC3D/`, an exploratory connected-component clustering comparison outside the manuscript mainline (since removed from the source workspace)
- The Copernicus-GlobColour comparison implementation for Table S5, which was never archived in the source workspace

## Portability changes made only in this release copy

- Removed hard-coded local MATLAB toolbox paths and replaced them with startup checks (`assert` on `m_proj` and, where used, `nclCM`) that stop with an explanatory error when a toolbox is missing.
- Renamed the script directory from its source-workspace name `06_Plot/` to `figure_code/`, and updated that name in the header comments of the archived scripts and in the paths cited in this documentation. No executable line was touched: every script resolves its own location at run time with `mfilename('fullpath')`, so the directory name does not affect behaviour.
- Source files are stored with Unix (LF) line endings.

No scientific formula, threshold, grouping rule, statistical calculation, colour specification, or input/output schema was changed during packaging. Apart from the release-copy edits listed above, the archived scripts correspond to the exact source versions that produced the 900 dpi main-text figures.
