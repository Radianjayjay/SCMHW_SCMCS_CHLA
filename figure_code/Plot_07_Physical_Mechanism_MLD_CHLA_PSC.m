%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot 07: Physical mechanism diagnostics linking MLD, CHLA and PSC
%%% Project: MHW_MCS_CHLA
%%%
%%% Goal:
%%%   Test whether SCMHW/SCMCS thermal forcing is associated with MLD
%%%   response, and whether event-scale MLD response helps explain CHLA and
%%%   PSC responses, especially Micro.
%%%
%%% Notes:
%%%   1. The current Characteristic files do not contain an independent
%%%      full-window SST time series. This script therefore uses signed event
%%%      intensity as the thermal forcing proxy in event-scale metrics:
%%%      MHW: Daily_MHW_Int / MHW_Global_Mean, positive warm anomaly.
%%%      MCS: Daily_MCS_Int / MCS_Global_Mean, negative cold anomaly.
%%%      Figure A does not plot this as a continuous lag curve; it shows MLD
%%%      lag response plus a signed intensity summary to avoid implying that
%%%      a full-window SST anomaly time series is available.
%%%   2. MLD is treated as a positive depth variable. Positive MLD anomaly
%%%      means mixed-layer deepening; negative anomaly means shoaling.
%%%   3. Baseline is Start-60:Start-1 for MLD, CHLA and PSC anomalies.
%%%   4. Absolute lag day 0 is the event peak day.
%%%
%%% Code:   figure_code
%%% Inputs: 05_Characteristic/Out/Characteristic_*_Basin_Eps5_MinPts200.mat
%%%         figure_code/In/MLD_*_Eps5_MinPts200.mat
%%% Output: figure_code/Out/Fig07_*.tif, optional metrics csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. Paths and style ==================
this_file = mfilename('fullpath');
plot_dir = fileparts(this_file);
base_dir = fileparts(plot_dir);

char_dir = fullfile(base_dir, '05_Characteristic', 'Out');
in_dir   = fullfile(plot_dir, 'In');
cache_dir = fullfile(plot_dir, 'Cache');
out_dir  = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

set(groot, 'DefaultFigureColor', 'w');
set(groot, 'DefaultAxesFontName', 'Arial');
set(groot, 'DefaultTextFontName', 'Arial');
set(groot, 'DefaultAxesFontSize', 7);
set(groot, 'DefaultTextFontSize', 7);
set(groot, 'DefaultAxesFontWeight', 'normal');
set(groot, 'DefaultTextFontWeight', 'normal');
set(groot, 'DefaultAxesLineWidth', 0.5);
set(groot, 'DefaultAxesTickDir', 'out');

FULL_WIDTH_CM = 17;
TIFF_DPI = 900;
WRITE_METRICS_CSV = should_write_metrics_csv();
LINE_WIDTH = 0.5;
CURVE_WIDTH = 1.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
MIN_N = 5;

EVENT_TYPES = {'MHW', 'MCS'};
DISPLAY.MHW = 'SCMHW';
DISPLAY.MCS = 'SCMCS';

ABS_LAG_DAYS = -60:60;
BASELINE_DAYS = -60:-1;
WINDOWS = struct( ...
    'id', {'Pre30d', 'Peak_pm5d', 'Post30d', 'Full'}, ...
    'label', {'Pre30d', 'Peak +/-5d', 'Post30d', 'Full'});
BIO = struct( ...
    'id', {'CHLA', 'Pico', 'Nano', 'Micro'}, ...
    'field', {'Box_CHLA_Full', 'Box_Pico_Full', 'Box_Nano_Full', 'Box_Micro_Full'}, ...
    'label', {'CHLA', 'Pico', 'Nano', 'Micro'});
CACHE_VERSION = 1;
CACHE_CONFIG = struct( ...
    'abs_lag_days', ABS_LAG_DAYS, ...
    'baseline_days', BASELINE_DAYS, ...
    'windows', WINDOWS, ...
    'bio', BIO, ...
    'min_n', MIN_N, ...
    'calculation_id', 'Plot07_physical_mechanism_mld_chla_psc_v1');

COL.thermal = [248 127 112] / 255;
COL.mld = [125 88 143] / 255;
COL.mhw = [248 127 112] / 255;
COL.mcs = [53 170 209] / 255;
COL.chla = [64 191 169] / 255;
COL.pico = [169 203 140] / 255;
COL.nano = [091 189 160] / 255;
COL.micro = [000 141 170] / 255;

%% ================== 2. Compute or load diagnostics ==================
files.MHW.char = fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat');
files.MCS.char = fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat');
files.MHW.mld  = fullfile(in_dir, 'MLD_MHW_Eps5_MinPts200.mat');
files.MCS.mld  = fullfile(in_dir, 'MLD_MCS_Eps5_MinPts200.mat');
input_files = {files.MHW.char, files.MCS.char, files.MHW.mld, files.MCS.mld};
cache_file = fullfile(cache_dir, 'Plot_07_Physical_Mechanism_MLD_CHLA_PSC_plot_data.mat');

for iEvent = 1:numel(EVENT_TYPES)
    eventType = EVENT_TYPES{iEvent};
    assert(exist(files.(eventType).char, 'file') == 2, 'Missing file: %s', files.(eventType).char);
    assert(exist(files.(eventType).mld, 'file') == 2, 'Missing file: %s', files.(eventType).mld);
end

if is_plot_cache_current(cache_file, input_files, CACHE_VERSION, CACHE_CONFIG)
    fprintf('Loading cached Plot 07 diagnostics: %s\n', cache_file);
    C = load(cache_file, 'Result', 'MetricTable');
    Result = C.Result;
    MetricTable = C.MetricTable;
else
    fprintf('Loading Plot07 input data...\n');
    D_MHW = load(files.MHW.char);
    D_MCS = load(files.MCS.char);
    M_MHW = load(files.MHW.mld);
    M_MCS = load(files.MCS.mld);

    Data.MHW.Basic = D_MHW.MHW_Basic_Table;
    Data.MHW.Series = D_MHW.MHW_Series_Table;
    Data.MHW.MLD = M_MHW.MHW_MLD_Table;
    Data.MCS.Basic = D_MCS.MCS_Basic_Table;
    Data.MCS.Series = D_MCS.MCS_Series_Table;
    Data.MCS.MLD = M_MCS.MCS_MLD_Table;

    validate_inputs(Data.MHW.Basic, Data.MHW.Series, Data.MHW.MLD, 'MHW', BIO);
    validate_inputs(Data.MCS.Basic, Data.MCS.Series, Data.MCS.MLD, 'MCS', BIO);

    fprintf('Computing physical mechanism diagnostics...\n');
    Result = struct();
    MetricTables = cell(numel(EVENT_TYPES), 1);

    for iEvent = 1:numel(EVENT_TYPES)
        eventType = EVENT_TYPES{iEvent};
        [Result.(eventType), MetricTables{iEvent}] = analyze_event_type( ...
            Data.(eventType).Basic, Data.(eventType).Series, Data.(eventType).MLD, ...
            eventType, BIO, ABS_LAG_DAYS, BASELINE_DAYS, WINDOWS, MIN_N);
    end

    MetricTable = vertcat(MetricTables{:});
    cache_version = CACHE_VERSION; %#ok<NASGU>
    cache_config = CACHE_CONFIG; %#ok<NASGU>
    save(cache_file, 'Result', 'MetricTable', 'cache_version', 'cache_config', '-v7.3');
    fprintf('Saved cached Plot 07 diagnostics: %s\n', cache_file);
end

if WRITE_METRICS_CSV
    metric_csv = fullfile(out_dir, 'Fig07_Physical_Mechanism_Metrics.csv');
    writetable(MetricTable, metric_csv);
    fprintf('Wrote: %s\n', metric_csv);
end

%% ================== 4. Figure A: MLD lag response and intensity proxy summary ==================
figA = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 11], 'Color', 'w');
tlA = tiledlayout(2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

ax = nexttile(1);
plot_combined_intensity_summary_panel(ax, Result.MHW.IntensitySummary, ...
    Result.MCS.IntensitySummary, COL.mhw, COL.mcs, LINE_WIDTH, ...
    MAIN_FONT_SIZE, TITLE_FONT_SIZE);

ax = nexttile(2);
plot_combined_mld_lag_panel(ax, ABS_LAG_DAYS, Result.MHW.MLD, ...
    Result.MCS.MLD, COL.mhw, COL.mcs, LINE_WIDTH, CURVE_WIDTH, ...
    MAIN_FONT_SIZE, TITLE_FONT_SIZE);
sgtitle(figA, 'MLD lag response with signed event-intensity proxy summary', ...
    'FontName', 'Arial', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');
save_figure(figA, out_dir, 'Fig07_A_Physical_Forcing_Lag_Response', TIFF_DPI);

%% ================== 5. Figure B: MLD-CHLA-Micro temporal coupling ==================
figB = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 9], 'Color', 'w');
tlB = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
tlB.Units = 'normalized';
tlB.OuterPosition = [0.04 0.14 0.94 0.82];

for iEvent = 1:numel(EVENT_TYPES)
    eventType = EVENT_TYPES{iEvent};
    ax = nexttile(iEvent);
    seriesSet = [Result.(eventType).MLD.Mean(:), ...
        Result.(eventType).Bio.CHLA.Mean(:), ...
        Result.(eventType).Bio.Micro.Mean(:)];
    plot_standardized_lag_panel(ax, ABS_LAG_DAYS, seriesSet, ...
        {'MLD', 'CHLA', 'Micro'}, [COL.mld; COL.chla; COL.micro], ...
        DISPLAY.(eventType), LINE_WIDTH, CURVE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
end
add_shared_line_legend(tlB, {'MLD', 'CHLA', 'Micro'}, ...
    [COL.mld; COL.chla; COL.micro], MAIN_FONT_SIZE);
title(tlB, 'Temporal coupling among MLD, CHLA and Micro anomalies', ...
    'FontName', 'Arial', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');
save_figure(figB, out_dir, 'Fig07_B_MLD_CHLA_Micro_Coupling', TIFF_DPI);

%% ================== 6. Figure C: mechanism path strength summary ==================
figC = figure('Units', 'centimeters', 'Position', [2 2 19 13], 'Color', 'w');
axC = axes(figC);
plot_mechanism_heatmap(axC, MetricTable, WINDOWS, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
save_figure(figC, out_dir, 'Fig07_C_Physical_Mechanism_Path_Summary', TIFF_DPI);

fprintf('Done Plot07.\n');

%% ================== Local functions ==================
function tf = should_write_metrics_csv()
    tf = true;
end

function validate_inputs(BasicT, SeriesT, MLDT, eventType, bio)
    if strcmp(eventType, 'MHW')
        requiredBasic = {'Event_ID', 'Duration', 'Start_Date_Idx', 'End_Date_Idx', ...
            'MHW_Global_Mean', 'Peak_Daily_Mean_MHW', 'Peak_MHW_Date'};
        requiredSeries = {'Event_ID', 'Date_Idx', 'Daily_MHW_Int', 'Box_Date_Idx'};
    else
        requiredBasic = {'Event_ID', 'Duration', 'Start_Date_Idx', 'End_Date_Idx', ...
            'MCS_Global_Mean', 'Peak_Daily_Mean_MCS', 'Peak_MCS_Date'};
        requiredSeries = {'Event_ID', 'Date_Idx', 'Daily_MCS_Int', 'Box_Date_Idx'};
    end
    requiredMLD = {'Event_ID', 'MLD_Date_Idx', 'MLD_Full', 'MLD_Event_Mean'};
    for k = 1:numel(bio)
        requiredSeries{end+1} = bio(k).field; %#ok<AGROW>
    end
    assert(all(ismember(requiredBasic, BasicT.Properties.VariableNames)), 'Missing Basic fields for %s.', eventType);
    assert(all(ismember(requiredSeries, SeriesT.Properties.VariableNames)), 'Missing Series fields for %s.', eventType);
    assert(all(ismember(requiredMLD, MLDT.Properties.VariableNames)), 'Missing MLD fields for %s.', eventType);
end

function [R, MetricT] = analyze_event_type(BasicT, SeriesT, MLDT, eventType, bio, lagDays, baselineDays, windows, minN)
    nEvents = height(BasicT);
    nLag = numel(lagDays);
    nBio = numel(bio);
    ThermalM = nan(nEvents, nLag);
    MLDM = nan(nEvents, nLag);
    BioM = nan(nEvents, nLag, nBio);
    WindowResponse = initialize_window_response(nEvents, windows, bio);

    if strcmp(eventType, 'MHW')
        peakField = 'Peak_MHW_Date';
        thermalSeriesField = 'Daily_MHW_Int';
        thermalScalarField = 'MHW_Global_Mean';
        thermalPeakField = 'Peak_Daily_Mean_MHW';
    else
        peakField = 'Peak_MCS_Date';
        thermalSeriesField = 'Daily_MCS_Int';
        thermalScalarField = 'MCS_Global_Mean';
        thermalPeakField = 'Peak_Daily_Mean_MCS';
    end

    eidSeries = string(SeriesT.Event_ID);
    eidMLD = string(MLDT.Event_ID);
    thermalScalar = double(BasicT.(thermalScalarField));

    for i = 1:nEvents
        peakDate = double(BasicT.(peakField)(i));
        tStart = double(BasicT.Start_Date_Idx(i));
        tEnd = double(BasicT.End_Date_Idx(i));
        if ~isfinite(peakDate) || ~isfinite(tStart) || ~isfinite(tEnd)
            continue
        end

        targetDates = peakDate + lagDays;
        jSeries = find(eidSeries == string(BasicT.Event_ID(i)), 1);
        if ~isempty(jSeries)
            eventDates = row_cell(SeriesT.Date_Idx, jSeries);
            thermalVals = row_cell(SeriesT.(thermalSeriesField), jSeries);
            ThermalM(i, :) = get_values_at_dates(eventDates, double(thermalVals), targetDates);

            boxDates = row_cell(SeriesT.Box_Date_Idx, jSeries);

            % baseline 窗口被完全裁掉（clip）时 CHLA baseline 为 NaN，anomaly 无定义，剔除该事件
            chlaY = double(row_cell(SeriesT.(bio(1).field), jSeries));
            chlaBase = baseline_mean(boxDates, chlaY, tStart, baselineDays);
            if isnan(chlaBase)
                continue;
            end

            for iBio = 1:nBio
                y = double(row_cell(SeriesT.(bio(iBio).field), jSeries));
                base = baseline_mean(boxDates, y, tStart, baselineDays);
                BioM(i, :, iBio) = get_values_at_dates(boxDates, y, targetDates) - base;
                for iWin = 1:numel(windows)
                    dates = window_dates(windows(iWin).id, tStart, tEnd, peakDate);
                    vals = get_values_at_dates(boxDates, y, dates) - base;
                    WindowResponse.(windows(iWin).id).(bio(iBio).id)(i) = mean(vals, 'omitnan');
                end
            end
        end

        jMLD = find(eidMLD == string(BasicT.Event_ID(i)), 1);
        if ~isempty(jMLD)
            mldDates = row_cell(MLDT.MLD_Date_Idx, jMLD);
            mldVals = double(row_cell(MLDT.MLD_Full, jMLD));
            mldBase = baseline_mean(mldDates, mldVals, tStart, baselineDays);
            % baseline 窗口被完全裁掉（clip）时 MLD baseline 为 NaN，跳过 MLDM 计算
            if isnan(mldBase)
                jMLD = [];
            else
                MLDM(i, :) = get_values_at_dates(mldDates, mldVals, targetDates) - mldBase;
                for iWin = 1:numel(windows)
                    dates = window_dates(windows(iWin).id, tStart, tEnd, peakDate);
                    vals = get_values_at_dates(mldDates, mldVals, dates) - mldBase;
                    WindowResponse.(windows(iWin).id).MLD(i) = mean(vals, 'omitnan');
                    tvals = thermal_values_for_window(SeriesT, jSeries, thermalSeriesField, dates, thermalScalar(i));
                    WindowResponse.(windows(iWin).id).ThermalProxy(i) = mean(tvals, 'omitnan');
                end
            end
        end
    end

    R.Thermal = summarize_matrix(ThermalM, minN);
    R.MLD = summarize_matrix(MLDM, minN);
    for iBio = 1:nBio
        R.Bio.(bio(iBio).id) = summarize_matrix(BioM(:, :, iBio), minN);
    end
    R.IntensitySummary = summarize_intensity_proxy(BasicT.(thermalScalarField), BasicT.(thermalPeakField));
    R.WindowResponse = WindowResponse;
    MetricT = build_metric_table(eventType, WindowResponse, windows, bio);
end

function S = summarize_intensity_proxy(meanIntensity, peakIntensity)
    meanIntensity = double(meanIntensity(:));
    peakIntensity = double(peakIntensity(:));
    S.Labels = {'Mean', 'Peak'};
    S.Values = [mean(meanIntensity, 'omitnan'), mean(peakIntensity, 'omitnan')];
    S.CI = [confidence_interval(meanIntensity), confidence_interval(peakIntensity)];
end

function ci = confidence_interval(x)
    x = double(x(:));
    x = x(isfinite(x));
    if numel(x) < 3
        ci = NaN;
    else
        ci = 1.96 * std(x) / sqrt(numel(x));
    end
end

function S = initialize_window_response(nEvents, windows, bio)
    S = struct();
    for iWin = 1:numel(windows)
        win = windows(iWin).id;
        S.(win).ThermalProxy = nan(nEvents, 1);
        S.(win).MLD = nan(nEvents, 1);
        for iBio = 1:numel(bio)
            S.(win).(bio(iBio).id) = nan(nEvents, 1);
        end
    end
end

function MetricT = build_metric_table(eventType, WindowResponse, windows, bio)
    rows = {};
    relationships = {};
    for iBio = 1:numel(bio)
        relationships(end+1, :) = {'MLD', bio(iBio).id}; %#ok<AGROW>
        relationships(end+1, :) = {'ThermalProxy', bio(iBio).id}; %#ok<AGROW>
    end
    relationships(end+1, :) = {'ThermalProxy', 'MLD'};
    relationships(end+1, :) = {'Micro', 'CHLA'};

    for iWin = 1:numel(windows)
        win = windows(iWin).id;
        for iRel = 1:size(relationships, 1)
            xName = relationships{iRel, 1};
            yName = relationships{iRel, 2};
            x = WindowResponse.(win).(xName);
            y = WindowResponse.(win).(yName);
            [r, slope, n] = correlation_and_slope(x, y);
            rows(end+1, :) = {DISPLAY_NAME(eventType), windows(iWin).label, xName, yName, ...
                mean(x, 'omitnan'), mean(y, 'omitnan'), r, r.^2, slope, n, interpretation_flag(r)}; %#ok<AGROW>
        end
    end
    MetricT = cell2table(rows, 'VariableNames', ...
        {'Event_Type', 'Window', 'Physical_Variable', 'Biological_Variable', ...
         'Mean_Physical_Response', 'Mean_Biological_Response', 'Correlation', ...
         'R2', 'Regression_Slope', 'N_Events', 'Interpretation_Flag'});
end

function name = DISPLAY_NAME(eventType)
    if strcmp(eventType, 'MHW')
        name = 'SCMHW';
    else
        name = 'SCMCS';
    end
end

function flag = interpretation_flag(r)
    if ~isfinite(r)
        flag = "Insufficient";
        return
    end
    ar = abs(r);
    if ar >= 0.5
        strength = "Strong";
    elseif ar >= 0.3
        strength = "Moderate";
    elseif ar >= 0.1
        strength = "Weak";
    else
        strength = "Little";
    end
    if r > 0
        flag = strength + "_positive";
    elseif r < 0
        flag = strength + "_negative";
    else
        flag = "Zero";
    end
end

function [r, slope, n] = correlation_and_slope(x, y)
    x = double(x(:));
    y = double(y(:));
    valid = isfinite(x) & isfinite(y);
    n = sum(valid);
    if n < 3
        r = NaN;
        slope = NaN;
        return
    end
    xv = x(valid);
    yv = y(valid);
    C = corrcoef(xv, yv);
    r = C(1, 2);
    if std(xv) == 0
        slope = NaN;
    else
        p = polyfit(xv, yv, 1);
        slope = p(1);
    end
end

function plot_combined_intensity_summary_panel(ax, mhwSummary, mcsSummary, mhwColor, mcsColor, lineWidth, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    hold(ax, 'on');
    box(ax, 'on');

    Y = [mhwSummary.Values(:), mcsSummary.Values(:)];
    E = [mhwSummary.CI(:), mcsSummary.CI(:)];
    b = bar(ax, Y, 'grouped', 'LineWidth', lineWidth, 'BarWidth', 0.72);
    b(1).FaceColor = mhwColor;
    b(2).FaceColor = mcsColor;
    b(1).EdgeColor = [0.15 0.15 0.15];
    b(2).EdgeColor = [0.15 0.15 0.15];

    drawnow;
    for k = 1:2
        valid = isfinite(Y(:, k)) & isfinite(E(:, k));
        if any(valid)
            errorbar(ax, b(k).XEndPoints(valid), Y(valid, k), E(valid, k), ...
                'k', 'LineStyle', 'none', 'LineWidth', lineWidth, 'CapSize', 4);
        end
    end
    yline(ax, 0, '-', 'Color', [0.65 0.65 0.65], 'LineWidth', lineWidth);
    set(ax, 'XTick', 1:2, 'XTickLabel', mhwSummary.Labels, ...
        'FontName', 'Arial', 'FontSize', mainFontSize, ...
        'LineWidth', lineWidth, 'TickDir', 'out', 'Box', 'on');
    xlim(ax, [0.35, 2.65]);
    ylabel(ax, 'Signed intensity proxy (degC)');
    title(ax, 'Thermal forcing proxy', 'FontWeight', 'normal', 'FontSize', titleFontSize);

    vals = [Y(:) - E(:); Y(:) + E(:)];
    vals = vals(isfinite(vals));
    if isempty(vals)
        ylim(ax, [-1, 1]);
    else
        pad = 0.12 * (max(vals) - min(vals));
        if ~isfinite(pad) || pad == 0
            pad = 0.1;
        end
        ylim(ax, [min(0, min(vals) - pad), max(0, max(vals) + pad)]);
    end
    lgd = legend(ax, {'SCMHW', 'SCMCS'}, 'Box', 'on', ...
        'Location', 'best', 'FontSize', mainFontSize);
    set(lgd, 'LineWidth', 0.5);
    grid(ax, 'off');
end

function plot_combined_mld_lag_panel(ax, x, mhwMLD, mcsMLD, mhwColor, mcsColor, lineWidth, curveWidth, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    hold(ax, 'on');
    box(ax, 'on');
    xline(ax, 0, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth);
    yline(ax, 0, '-', 'Color', [0.78 0.78 0.78], 'LineWidth', 0.5);
    plot_with_ci(ax, x, mhwMLD.Mean, mhwMLD.CI, mhwColor, curveWidth);
    plot_with_ci(ax, x, mcsMLD.Mean, mcsMLD.CI, mcsColor, curveWidth);
    hMHW = plot(ax, nan, nan, '-', 'Color', mhwColor, 'LineWidth', curveWidth);
    hMCS = plot(ax, nan, nan, '-', 'Color', mcsColor, 'LineWidth', curveWidth);
    xlabel(ax, 'Lag days (0 = peak)');
    ylabel(ax, 'MLD anomaly (m)');
    title(ax, 'MLD lag response', 'FontWeight', 'normal', 'FontSize', titleFontSize);
    xlim(ax, [min(x), max(x)]);
    xticks(ax, -60:30:60);
    vals = [mhwMLD.Mean(:) + mhwMLD.CI(:); mhwMLD.Mean(:) - mhwMLD.CI(:); ...
        mcsMLD.Mean(:) + mcsMLD.CI(:); mcsMLD.Mean(:) - mcsMLD.CI(:)];
    vals = vals(isfinite(vals));
    if ~isempty(vals)
        maxAbs = max(abs(vals)) * 1.08;
        ylim(ax, [-maxAbs, maxAbs]);
    end
    lgd = legend(ax, [hMHW, hMCS], {'SCMHW', 'SCMCS'}, ...
        'Box', 'on', 'Location', 'best', 'FontSize', mainFontSize);
    set(lgd, 'LineWidth', 0.5);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, ...
        'TickDir', 'out', 'FontName', 'Arial');
    grid(ax, 'off');
end

function S = summarize_matrix(M, minN)
    nCols = size(M, 2);
    S.Mean = nan(1, nCols);
    S.CI = nan(1, nCols);
    S.N = zeros(1, nCols);
    for c = 1:nCols
        x = M(:, c);
        x = x(isfinite(x));
        S.N(c) = numel(x);
        if numel(x) >= minN
            S.Mean(c) = mean(x);
            S.CI(c) = 1.96 * std(x) / sqrt(numel(x));
        end
    end
end

function dates = window_dates(win, tStart, tEnd, peakDate)
    switch win
        case 'Pre30d'
            dates = (tStart - 30):(tStart - 1);
        case 'Peak_pm5d'
            dates = (peakDate - 5):(peakDate + 5);
        case 'Post30d'
            dates = (tEnd + 1):(tEnd + 30);
        case 'Full'
            dates = tStart:tEnd;
        otherwise
            error('Unknown window: %s', win);
    end
end

function vals = thermal_values_for_window(SeriesT, jSeries, thermalField, dates, scalarFallback)
    vals = nan(size(dates));
    if isempty(jSeries) || isnan(jSeries)
        if isfinite(scalarFallback)
            vals(:) = scalarFallback;
        end
        return
    end
    eventDates = row_cell(SeriesT.Date_Idx, jSeries);
    thermalVals = double(row_cell(SeriesT.(thermalField), jSeries));
    vals = get_values_at_dates(eventDates, thermalVals, dates);
    if all(~isfinite(vals)) && isfinite(scalarFallback)
        vals(:) = scalarFallback;
    end
end

function baseline = baseline_mean(dateVec, yVec, startDate, baselineDays)
    vals = get_values_at_dates(dateVec, yVec, startDate + baselineDays);
    baseline = mean(vals, 'omitnan');
end

function vals = get_values_at_dates(dateVec, yVec, targetDates)
    vals = nan(size(targetDates));
    if isempty(dateVec) || isempty(yVec)
        return
    end
    dateVec = double(dateVec(:));
    yVec = double(yVec(:));
    [tf, loc] = ismember(double(targetDates(:)), dateVec);
    out = nan(numel(targetDates), 1);
    out(tf) = yVec(loc(tf));
    vals = reshape(out, size(targetDates));
end

function value = row_cell(tableVar, rowIdx)
    if iscell(tableVar)
        value = tableVar{rowIdx};
    else
        value = tableVar(rowIdx, :);
        value = squeeze(value);
    end
end

function plot_standardized_lag_panel(ax, x, Y, ~, colors, panelTitle, lineWidth, curveWidth, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    hold(ax, 'on');
    box(ax, 'on');
    xline(ax, 0, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth);
    for k = 1:size(Y, 2)
        y = Y(:, k);
        scale = max(abs(y), [], 'omitnan');
        if ~isfinite(scale) || scale == 0
            scale = 1;
        end
        plot(ax, x, y ./ scale, '-', 'Color', colors(k, :), 'LineWidth', curveWidth);
    end
    yline(ax, 0, '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
    xlabel(ax, 'Lag days (0 = peak)');
    ylabel(ax, 'Standardized anomaly');
    title(ax, panelTitle, 'FontWeight', 'normal', 'FontSize', titleFontSize);
    xlim(ax, [min(x), max(x)]);
    xticks(ax, -60:30:60);
    ylim(ax, [-1.1, 1.1]);
    if size(Y, 2) >= 3
        rVal = curve_correlation(Y(:, 2), Y(:, 3));
        text(ax, 0.04, 0.92, sprintf('r(CHLA, Micro)\\newline= %.2f', rVal), ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', ...
            'FontName', 'Arial', ...
            'FontSize', mainFontSize - 1, ...
            'Color', [0.05 0.05 0.05], ...
            'BackgroundColor', 'w', ...
            'Margin', 1, ...
            'Interpreter', 'tex');
    end
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', 'FontName', 'Arial');
    grid(ax, 'off');
end

function rVal = curve_correlation(y1, y2)
    valid = isfinite(y1) & isfinite(y2);
    if sum(valid) < 3
        rVal = nan;
        return
    end
    C = corrcoef(y1(valid), y2(valid));
    rVal = C(1, 2);
end

function add_shared_line_legend(tileObj, labels, colors, mainFontSize)
    numItems = numel(labels);
    fig = tileObj.Parent;
    legAx = axes(fig, 'Units', 'normalized', ...
        'Position', [0.28, 0.090, 0.44, 0.055], ...
        'Visible', 'off', ...
        'Color', 'none', ...
        'XLim', [0, 1], ...
        'YLim', [0, 1]);
    hold(legAx, 'on');

    rectangle(legAx, 'Position', [0.02, 0.18, 0.96, 0.64], ...
        'EdgeColor', [0.15, 0.15, 0.15], ...
        'LineWidth', 0.5, ...
        'FaceColor', 'none');

    itemWidth = 0.78 / numItems;
    itemStart = 0.11 + (0:numItems-1) * itemWidth;
    for k = 1:numItems
        x0 = itemStart(k);
        plot(legAx, [x0, x0 + 0.065], [0.50, 0.50], '-', ...
            'Color', colors(k, :), ...
            'LineWidth', 1.5);
        text(legAx, x0 + 0.085, 0.50, labels{k}, ...
            'Units', 'data', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', ...
            'FontSize', mainFontSize, ...
            'Color', [0.10, 0.10, 0.10]);
    end
end

function plot_with_ci(ax, x, y, ci, color, curveWidth)
    valid = isfinite(y) & isfinite(ci);
    if sum(valid) < 2
        return
    end
    xv = x(valid);
    yv = y(valid);
    civ = ci(valid);
    fill(ax, [xv, fliplr(xv)], [yv + civ, fliplr(yv - civ)], color, ...
        'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(ax, xv, yv, '-', 'Color', color, 'LineWidth', curveWidth);
end

function plot_mechanism_heatmap(ax, T, windows, lineWidth, mainFontSize, titleFontSize)
    set(ax, 'Units', 'normalized', 'Position', [0.23 0.34 0.56 0.50]);
    eventLabels = {'SCMHW', 'SCMCS'};
    shortEventLabels = {'HW', 'CS'};
    rowPairs = {'MLD', 'CHLA'; 'MLD', 'Pico'; 'MLD', 'Nano'; 'MLD', 'Micro'; 'Micro', 'CHLA'; 'ThermalProxy', 'MLD'};
    rowLabels = {'MLD vs CHLA', 'MLD vs Pico', 'MLD vs Nano', 'MLD vs Micro', 'Micro vs CHLA', 'Int. vs MLD'};
    colLabels = {};
    Z = nan(size(rowPairs, 1), numel(eventLabels) * numel(windows));
    c = 0;
    for iEvent = 1:numel(eventLabels)
        for iWin = 1:numel(windows)
            c = c + 1;
            colLabels{c} = sprintf('%s %s', shortEventLabels{iEvent}, windows(iWin).label); %#ok<AGROW>
            for r = 1:size(rowPairs, 1)
                mask = strcmp(T.Event_Type, eventLabels{iEvent}) & strcmp(T.Window, windows(iWin).label) & ...
                    strcmp(T.Physical_Variable, rowPairs{r, 1}) & strcmp(T.Biological_Variable, rowPairs{r, 2});
                if any(mask)
                    Z(r, c) = T.Correlation(find(mask, 1));
                end
            end
        end
    end
    imagesc(ax, Z);
    colormap(ax, mechanism_correlation_colormap());
    clim(ax, [-1, 1]);
    cb = colorbar(ax);
    cb.Label.String = 'Correlation (r)';
    cb.LineWidth = lineWidth;
    cb.TickDirection = 'out';
    cb.Ticks = -1:0.5:1;
    cb.FontName = 'Arial';
    cb.FontSize = mainFontSize;
    cb.Label.FontName = 'Arial';
    cb.Label.FontWeight = 'normal';
    set(ax, 'XTick', 1:numel(colLabels), 'XTickLabel', colLabels, ...
        'YTick', 1:numel(rowLabels), 'YTickLabel', rowLabels, ...
        'LineWidth', lineWidth, 'FontSize', mainFontSize, ...
        'TickDir', 'out', 'FontName', 'Arial');
    xtickangle(ax, 30);
    title(ax, 'Physical mechanism path strength summary', ...
        'FontWeight', 'normal', 'FontSize', titleFontSize - 1);
    for r = 1:size(Z, 1)
        for c = 1:size(Z, 2)
            if isfinite(Z(r, c))
                text(ax, c, r, sprintf('%.2f', Z(r, c)), ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                    'FontName', 'Arial', 'FontSize', mainFontSize, 'Color', text_color_for_value(Z(r, c)));
            end
        end
    end
    box(ax, 'on');
end

function c = text_color_for_value(v)
    if abs(v) > 0.55
        c = [1 1 1];
    else
        c = [0.05 0.05 0.05];
    end
end

function cmap = mechanism_correlation_colormap()
    if exist('nclCM', 'file') == 2
        cmap = nclCM(484, 11);
        cmap = interp1(linspace(0, 1, size(cmap, 1)), cmap, linspace(0, 1, 256), 'linear');
    else
        cmap = redblue_colormap(256);
    end
end

function cmap = redblue_colormap(n)
    x = linspace(0, 1, n)';
    bottom = [0.10 0.18 0.80];
    middle = [0.98 0.98 0.98];
    top = [0.82 0.10 0.10];
    cmap = zeros(n, 3);
    for k = 1:n
        if x(k) <= 0.5
            t = x(k) / 0.5;
            cmap(k, :) = bottom * (1 - t) + middle * t;
        else
            t = (x(k) - 0.5) / 0.5;
            cmap(k, :) = middle * (1 - t) + top * t;
        end
    end
end

function tf = is_plot_cache_current(cache_file, input_files, expected_version, expected_config)
    tf = false;
    if exist(cache_file, 'file') ~= 2
        return
    end
    try
        C = load(cache_file, 'cache_version', 'cache_config');
        if ~isfield(C, 'cache_version') || C.cache_version ~= expected_version
            return
        end
        if ~isfield(C, 'cache_config') || ~isequaln(C.cache_config, expected_config)
            return
        end
        cache_info = dir(cache_file);
        for iFile = 1:numel(input_files)
            input_info = dir(input_files{iFile});
            if isempty(input_info) || input_info.datenum > cache_info.datenum
                return
            end
        end
        tf = true;
    catch
        tf = false;
    end
end

function save_figure(fig, outDir, baseName, tiffDpi)
    outBase = fullfile(outDir, baseName);
    fprintf('Saving: %s.tif\n', outBase);
    set(fig, 'InvertHardcopy', 'off');
    drawnow;
    exportgraphics(fig, [outBase, '.tif'], 'Resolution', tiffDpi);
    close(fig);
end
