# MHW MCS CHLA main-figure code

Version 1.0.0

This archive contains the code that generates the main-text figures (Figures 1–6) of the manuscript "Global phytoplankton responses to spatiotemporally continuous marine heatwaves and cold spells" by Jie Ren, Yulong Yao, and Chunzai Wang. The scripts render event-aligned chlorophyll-a (CHLA), model-derived phytoplankton size-class (PSC: pico/nano/micro), and mixed-layer-depth (MLD) responses for spatiotemporally continuous marine heatwaves (SCMHW) and cold spells (SCMCS), grouped by mean intensity, duration, and maximum area.

## Scope of this archive

This is a **main-figure code release**. By the authors' decision it contains only the plotting and figure-assembly scripts for the six main figures, not the upstream analysis pipeline and not the supplementary-figure code. Specifically, the archive does not include:

- the grid-cell MHW/MCS detection, basin-wise DBSCAN clustering, event-statistics, and event-characteristic stages that produced the event dataset (its outputs are inputs here, see `DATA_SOURCES.md`);
- the code for Supplementary Figures S6–S8 and for Supplementary Tables S4–S6;
- any data files.

Note that two of the archived scripts are multi-variant by design: `Composite_01_L1L2L3_Map.m` renders the classification composite for all three grouping variables, and `Composite_02_CHLA_Response.m` renders the response composite for all three; the mean-intensity variants are main-text Figures 1 and 2–4, while the duration and maximum-area variants of the same scripts were published as Supplementary Figures S1–S5. No additional code is needed for those variants.

`MANIFEST.md` states the full inclusion and exclusion policy; `FIGURE_CODE_MAP.md` links each main figure to its script and inputs.

## Directory structure

```text
figure_code/  Plot-data scripts (Plot_*.m) and main-figure composites (Composite_*.m)
```

All scripts derive the project root from their own location (`mfilename('fullpath')`); no machine-specific paths are hard-coded.

## Software requirements

The code was developed on Windows 11 with MATLAB R2024b. MATLAB is proprietary and not included. The scripts require these separately installed MATLAB packages on the MATLAB path:

- `m_map` (map projection and coastlines), providing `m_proj` and related functions
- `nclCM` (NCL color palettes)
- `slanCM` (slan color palettes)

Each map-based script checks for `m_proj` (and, where used, `nclCM`) at startup and stops with an explanatory error if the toolbox is missing. No Python or other runtime is required.

## Expected inputs

The scripts read precomputed event-level files from fixed locations relative to the project root:

- `05_Characteristic/Out/Characteristic_{MHW,MCS}_Basin_Eps5_MinPts200.mat` — event-level characteristics and aligned response series
- `04_Statistic/Out/Statistic_{MHW,MCS}_Basin_Eps5_MinPts200.mat` — event statistics (used by `Plot_00`)
- `figure_code/In/MLD_{MHW,MCS}_Eps5_MinPts200.mat` — event-aligned MLD series

These files are produced by the upstream pipeline, which is not part of this release, and they are not redistributed. Their content ultimately derives from the NOAA OISST, OCNET chlorophyll-a, and GLORYS products documented in `DATA_SOURCES.md`.

## Usage

1. Place the precomputed inputs at the paths listed above, and add `m_map`, `nclCM`, and `slanCM` to the MATLAB path.
2. Run the required `Plot_*.m` scripts in `figure_code/`. Each builds a plot-data cache under `figure_code/Cache/`.
3. Run the corresponding `Composite_*.m` scripts to assemble the main figures from the caches and export them to `figure_code/Out/`.

`Plot_00` → `Composite_01` (Figure 1); `Plot_03`, `Plot_05`, `Plot_08` → `Composite_02` (Figures 2–4); `Plot_06` → `Composite_05` (Figure 5); `Plot_07_Physical_Mechanism_MLD_CHLA_PSC` → `Composite_06` (Figure 6).

Scripts create `Cache/` and `Out/` directories as needed; generated files are not part of this archive.

## Reproducibility notes

- The analysis grid is 0.5 degrees over 45 degrees S–45 degrees N for 2001–2023.
- The event dataset shown in the figures is the manuscript configuration: basin-wise DBSCAN with `Eps = 5` and `MinPts = 200` (8,663 SCMHW and 7,295 SCMCS events).
- Figure scripts read but do not modify the scientific inputs; they write plot-data caches and figure files only.
- Figures are exported as 900 dpi TIFF and PNG files. External toolboxes remain subject to their own licenses.
- Before executing MATLAB source obtained from an archive, review it and confirm all input paths and dependencies in your own environment.

## Citation

Please cite the Zenodo software record for the exact version used. Citation metadata are provided in `CITATION.cff`. When the associated journal article becomes available, cite both the software record and the article.

## License

The code in this curated archive is released under the MIT License; see `LICENSE`. External MATLAB packages and the underlying data products are not included and are governed by their respective terms.

## Contact

Questions about the scientific analysis should be directed to the authors of the associated manuscript.
