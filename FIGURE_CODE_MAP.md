# Manuscript main-figure to code map

This map covers main Figures 1–6 and states which archived script produces each figure and which precomputed inputs it reads. Input files are not redistributed; see `DATA_SOURCES.md`.

| Main figure | Archived script | Precomputed inputs read |
|---|---|---|
| Figure 1 (mean-intensity classification: counts and L1–L3 maps) | `figure_code/Composite_01_L1L2L3_Map.m` | `figure_code/Cache/Plot_00_Spatial_Distribution_plot_data.mat`; `05_Characteristic/Out/Characteristic_*_Basin_Eps5_MinPts200.mat` |
| Figures 2–4 (CHLA/PSC response curves and centroid maps, mean intensity) | `figure_code/Composite_02_CHLA_Response.m` | `figure_code/Cache/Plot_03_*_by_*_plot_data.mat`, `Plot_05_*_by_*_plot_data.mat`, `Plot_08_*_by_*_plot_data.mat` |
| Figure 5 (PSC contribution heatmap) | `figure_code/Composite_05_PSC_HeatMap.m` | `figure_code/Cache/Plot_06_CHLA_Micro_Dominance_plot_data.mat` |
| Figure 6 (physical forcing, MLD and CHLA coupling) | `figure_code/Composite_06_CHLA_MLD.m` | `figure_code/Cache/Plot_07_Physical_Mechanism_MLD_CHLA_PSC_plot_data.mat` |

## Cache-building chain inside this archive

Within `figure_code/`, the archived scripts form this chain (all event-level inputs arrive precomputed):

1. `Plot_00`, `Plot_03`, `Plot_05`, `Plot_06`, `Plot_07_Physical_Mechanism_MLD_CHLA_PSC`, and `Plot_08` read the event-level inputs and write `figure_code/Cache/Plot_*_plot_data.mat`.
2. `Composite_01`, `Composite_02`, `Composite_05`, and `Composite_06` read those caches and export the final 900 dpi figures to `figure_code/Out/`.

## Multi-variant note

`Composite_01_L1L2L3_Map.m` and `Composite_02_CHLA_Response.m` each render their composite for all three grouping variables (mean intensity, duration, maximum area). The mean-intensity variants are main-text Figures 1–4; the duration and maximum-area variants of these same scripts were published as Supplementary Figures S1–S5. No supplementary-only code exists for those panels.

## Not included

Code for Supplementary Figures S6–S8, for Supplementary Tables S1, S2, S4, S5, and S6, and the entire upstream pipeline (detection, tagging, clustering, statistics, characteristics) is outside this release. Supplementary Table S3 (class ranges and sample sizes) is computed by the grouping logic inside `Composite_01_L1L2L3_Map.m` (`group_by_count`), which is archived.
