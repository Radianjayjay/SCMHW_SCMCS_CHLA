%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot 06: CHLA Micro dominance diagnostics
%%% Project: MHW_MCS_CHLA
%%%
%%% Goal:
%%%   Test whether CHLA response is mainly dominated by Micro from:
%%%   A. temporal response-shape similarity,
%%%   B. event-scale amplitude explanatory power,
%%%   C. anomaly magnitude contribution,
%%%   D. rank-style dominance summary.
%%%
%%% Code:   figure_code
%%% Inputs: 05_Characteristic/Out/Characteristic_*_Basin_Eps5_MinPts200.mat
%%% Output: figure_code/Out/Fig06_*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. Paths and style ==================
this_file = mfilename('fullpath');
plot_dir = fileparts(this_file);
base_dir = fileparts(plot_dir);

char_dir = fullfile(base_dir, '05_Characteristic', 'Out');
cache_dir = fullfile(plot_dir, 'Cache');
out_dir  = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% 外部绘图工具必须由用户预先加入 MATLAB path。

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
LINE_WIDTH = 0.5;
CURVE_WIDTH = 1.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
MIN_N = 5;
EPS_DENOM = 1.0e-10;

EVENT_TYPES = {'MHW', 'MCS'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';

COMPONENTS = {'CHLA', 'Pico', 'Nano', 'Micro'};
PSC_CLASSES = {'Pico', 'Nano', 'Micro'};
SERIES_FIELDS.CHLA = 'Box_CHLA_Full';
SERIES_FIELDS.Pico = 'Box_Pico_Full';
SERIES_FIELDS.Nano = 'Box_Nano_Full';
SERIES_FIELDS.Micro = 'Box_Micro_Full';

COMP_COLORS.CHLA = [0.02 0.02 0.02];
COMP_COLORS.Pico = [169 203 140] / 255;
COMP_COLORS.Nano = [091 189 160] / 255;
COMP_COLORS.Micro = [000 141 170] / 255;

ABS_LAG_DAYS = -60:60;
NORM_GRID = linspace(-1, 2, 151);
BASELINE_DAYS = -60:-1;
WINDOW_NAMES = {'Pre30d', 'Peak_pm5d', 'Post30d', 'Full'};
WINDOW_LABELS = {'Pre30d', 'Peak\pm5d', 'Post30d', 'Full'};
CACHE_VERSION = 1;
CACHE_CONFIG = struct( ...
    'components', {COMPONENTS}, ...
    'psc_classes', {PSC_CLASSES}, ...
    'series_fields', SERIES_FIELDS, ...
    'abs_lag_days', ABS_LAG_DAYS, ...
    'norm_grid', NORM_GRID, ...
    'baseline_days', BASELINE_DAYS, ...
    'window_names', {WINDOW_NAMES}, ...
    'min_n', MIN_N, ...
    'eps_denom', EPS_DENOM, ...
    'calculation_id', 'Plot06_chla_micro_dominance_v1');

%% ================== 2. Compute or load diagnostics ==================
char_file_mhw = fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat');
char_file_mcs = fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat');
input_files = {char_file_mhw, char_file_mcs};
cache_file = fullfile(cache_dir, 'Plot_06_CHLA_Micro_Dominance_plot_data.mat');

if is_plot_cache_current(cache_file, input_files, CACHE_VERSION, CACHE_CONFIG)
    fprintf('Loading cached Plot 06 diagnostics: %s\n', cache_file);
    C = load(cache_file, 'Result', 'Metrics');
    Result = C.Result;
    Metrics = C.Metrics;
else
    fprintf('Loading characteristic tables...\n');
    D_MHW = load(char_file_mhw);
    D_MCS = load(char_file_mcs);
    Basic.MHW = D_MHW.MHW_Basic_Table;
    Series.MHW = D_MHW.MHW_Series_Table;
    Basic.MCS = D_MCS.MCS_Basic_Table;
    Series.MCS = D_MCS.MCS_Series_Table;

    fprintf('Computing anomaly matrices, window responses, and diagnostics...\n');
    Result = struct();
    MetricTables = cell(numel(EVENT_TYPES), 1);

    for iEvent = 1:numel(EVENT_TYPES)
        event_type = EVENT_TYPES{iEvent};
        Result.(event_type) = analyze_event_type( ...
            Basic.(event_type), Series.(event_type), event_type, COMPONENTS, PSC_CLASSES, ...
            SERIES_FIELDS, ABS_LAG_DAYS, NORM_GRID, BASELINE_DAYS, WINDOW_NAMES, MIN_N, EPS_DENOM);
        MetricTables{iEvent} = Result.(event_type).MetricTable;
    end

    Metrics = vertcat(MetricTables{:});
    cache_version = CACHE_VERSION; %#ok<NASGU>
    cache_config = CACHE_CONFIG; %#ok<NASGU>
    save(cache_file, 'Result', 'Metrics', 'cache_version', 'cache_config', '-v7.3');
    fprintf('Saved cached Plot 06 diagnostics: %s\n', cache_file);
end

%% ================== 3. Figure A: temporal response similarity ==================
fprintf('Plotting Figure A: temporal response similarity...\n');
figA = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 12.5], 'Color', 'w');
tlA = tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
common_ylim = get_common_ylim(Result, COMPONENTS);

ax = nexttile(1);
plot_response_panel(ax, ABS_LAG_DAYS, Result.MHW.AbsMean, COMPONENTS, COMP_COLORS, ...
    sprintf('%s absolute time', DISPLAY_EVENT_TYPES.MHW), 'Lag days (0 = peak)', common_ylim, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
xticks(ax, -60:30:60);

ax = nexttile(2);
plot_response_panel(ax, ABS_LAG_DAYS, Result.MCS.AbsMean, COMPONENTS, COMP_COLORS, ...
    sprintf('%s absolute time', DISPLAY_EVENT_TYPES.MCS), 'Lag days (0 = peak)', common_ylim, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
xticks(ax, -60:30:60);

ax = nexttile(3);
plot_response_panel(ax, NORM_GRID, Result.MHW.NormMean, COMPONENTS, COMP_COLORS, ...
    sprintf('%s normalized time', DISPLAY_EVENT_TYPES.MHW), 'Normalized event phase', common_ylim, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
xticks(ax, [-1 0 1 2]);
xticklabels(ax, {'Pre', 'On', 'End', 'Post'});

ax = nexttile(4);
plot_response_panel(ax, NORM_GRID, Result.MCS.NormMean, COMPONENTS, COMP_COLORS, ...
    sprintf('%s normalized time', DISPLAY_EVENT_TYPES.MCS), 'Normalized event phase', common_ylim, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
xticks(ax, [-1 0 1 2]);
xticklabels(ax, {'Pre', 'On', 'End', 'Post'});

sgtitle('CHLA and PSC lag-response anomalies', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');
add_shared_line_legend(tlA, COMPONENTS, COMP_COLORS, MAIN_FONT_SIZE);
save_figure(figA, out_dir, 'Fig06_A_CHLA_PSC_Lag_Response', TIFF_DPI);

%% ================== 4. Figure B: event-scale explanatory power ==================
fprintf('Plotting Figure B: event-scale R2 bar chart...\n');
figB = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 8.2], 'Color', 'w');
tlB = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
for iEvent = 1:numel(EVENT_TYPES)
    event_type = EVENT_TYPES{iEvent};
    ax = nexttile(iEvent);
    plot_metric_bar_panel(ax, Metrics, event_type, DISPLAY_EVENT_TYPES.(event_type), ...
        PSC_CLASSES, COMP_COLORS, 'R2_With_CHLA', WINDOW_NAMES, WINDOW_LABELS, ...
        'R^2', [0 1], LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
end
sgtitle('Event-scale explanatory power of PSC responses', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');
add_shared_patch_legend(tlB, PSC_CLASSES, COMP_COLORS, MAIN_FONT_SIZE);
save_figure(figB, out_dir, 'Fig06_B_Response_R2_Bar', TIFF_DPI);

%% ================== 5. Figure C: magnitude contribution ==================
fprintf('Plotting Figure C: PSC magnitude contribution...\n');
figC = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 8.2], 'Color', 'w');
tlC = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
for iEvent = 1:numel(EVENT_TYPES)
    event_type = EVENT_TYPES{iEvent};
    ax = nexttile(iEvent);
    plot_contribution_panel(ax, Metrics, event_type, DISPLAY_EVENT_TYPES.(event_type), ...
        PSC_CLASSES, COMP_COLORS, WINDOW_NAMES, WINDOW_LABELS, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
end
sgtitle('PSC anomaly magnitude contribution', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');
add_shared_patch_legend(tlC, PSC_CLASSES, COMP_COLORS, MAIN_FONT_SIZE);
save_figure(figC, out_dir, 'Fig06_C_Response_Contribution_StackedBar', TIFF_DPI);

%% ================== 6. Figure D: Micro dominance summary ==================
fprintf('Plotting Figure D: dominance summary heatmap...\n');
Summary = build_summary_table(Metrics, EVENT_TYPES, PSC_CLASSES, WINDOW_NAMES);
figD = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 8.2], 'Color', 'w');
tlD = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
for iEvent = 1:numel(EVENT_TYPES)
    event_type = EVENT_TYPES{iEvent};
    ax = nexttile(iEvent);
    plot_summary_heatmap(ax, Summary, event_type, DISPLAY_EVENT_TYPES.(event_type), PSC_CLASSES, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
end
sgtitle('Micro dominance summary', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');
save_figure(figD, out_dir, 'Fig06_D_Dominance_Summary_Heatmap', TIFF_DPI);

fprintf('Done. Outputs are in: %s\n', out_dir);

%% ================== Local functions ==================
function R = analyze_event_type(BasicT, SeriesT, eventType, components, pscClasses, seriesFields, absLagDays, normGrid, baselineDays, windowNames, minN, epsDenom)
    nEvents = height(BasicT);
    nComp = numel(components);
    nAbs = numel(absLagDays);
    nNorm = numel(normGrid);

    AbsRaw = nan(nEvents, nAbs, nComp);
    NormRaw = nan(nEvents, nNorm, nComp);
    WindowResponse = struct();
    for iWin = 1:numel(windowNames)
        WindowResponse.(windowNames{iWin}) = nan(nEvents, nComp);
    end

    if strcmp(eventType, 'MHW')
        peakField = 'Peak_MHW_Date';
    else
        peakField = 'Peak_MCS_Date';
    end

    eidS = string(SeriesT.Event_ID);
    for i = 1:nEvents
        j = find(eidS == string(BasicT.Event_ID(i)), 1);
        if isempty(j), continue; end

        dateVec = double(SeriesT.Box_Date_Idx{j}(:));
        if isempty(dateVec), continue; end

        tStart = double(BasicT.Start_Date_Idx(i));
        tEnd = double(BasicT.End_Date_Idx(i));
        peakDate = double(BasicT.(peakField)(i));
        if ~isfinite(tStart) || ~isfinite(tEnd) || tEnd < tStart
            continue;
        end

        Y = struct();
        baseline = struct();
        for iComp = 1:nComp
            comp = components{iComp};
            y = double(SeriesT.(seriesFields.(comp)){j}(:));
            Y.(comp) = y;
            baseline.(comp) = get_baseline_mean(dateVec, y, tStart, baselineDays);
        end

        % baseline 窗口被完全裁掉（clip）时 baseline 为 NaN，anomaly 无定义，剔除该事件
        if isnan(baseline.CHLA)
            continue;
        end

        if isfinite(peakDate)
            targetDates = peakDate + absLagDays;
            for iComp = 1:nComp
                comp = components{iComp};
                AbsRaw(i, :, iComp) = get_values_at_dates(dateVec, Y.(comp), targetDates) - baseline.(comp);
            end
        end

        normT = build_normalized_time(dateVec, tStart, tEnd);
        for iComp = 1:nComp
            comp = components{iComp};
            NormRaw(i, :, iComp) = interp_unique(normT, Y.(comp) - baseline.(comp), normGrid);
        end

        windows.Pre30d = tStart + (-30:-1);
        windows.Peak_pm5d = peakDate + (-5:5);
        windows.Post30d = tEnd + (1:30);
        windows.Full = tStart:tEnd;
        for iWin = 1:numel(windowNames)
            winName = windowNames{iWin};
            if ~isfield(windows, winName), continue; end
            for iComp = 1:nComp
                comp = components{iComp};
                vals = get_values_at_dates(dateVec, Y.(comp), windows.(winName)) - baseline.(comp);
                WindowResponse.(winName)(i, iComp) = mean(vals, 'omitnan');
            end
        end
    end

    R.AbsRaw = AbsRaw;
    R.NormRaw = NormRaw;
    R.AbsMean = squeeze_mean(AbsRaw, minN);
    R.NormMean = squeeze_mean(NormRaw, minN);
    R.WindowResponse = WindowResponse;
    R.TemporalSimilarity = compute_temporal_similarity(R.AbsMean, R.NormMean, components, pscClasses);
    R.MetricTable = build_metric_table(eventType, WindowResponse, R.TemporalSimilarity, components, pscClasses, windowNames, epsDenom);
end

function S = squeeze_mean(M, minN)
    [~, nX, nComp] = size(M);
    S.Mean = nan(nX, nComp);
    S.CI = nan(nX, nComp);
    S.N = zeros(nX, nComp);
    for iComp = 1:nComp
        for ix = 1:nX
            vals = M(:, ix, iComp);
            vals = vals(isfinite(vals));
            S.N(ix, iComp) = numel(vals);
            if numel(vals) >= minN
                S.Mean(ix, iComp) = mean(vals, 'omitnan');
                S.CI(ix, iComp) = 1.96 * std(vals, 'omitnan') / sqrt(numel(vals));
            end
        end
    end
end

function TSim = compute_temporal_similarity(absMean, normMean, components, pscClasses)
    chlaIdx = find(strcmp(components, 'CHLA'), 1);
    TSim = struct();
    for iPSC = 1:numel(pscClasses)
        psc = pscClasses{iPSC};
        pscIdx = find(strcmp(components, psc), 1);
        rAbs = pair_corr(absMean.Mean(:, chlaIdx), absMean.Mean(:, pscIdx));
        rNorm = pair_corr(normMean.Mean(:, chlaIdx), normMean.Mean(:, pscIdx));
        TSim.(psc) = mean([rAbs, rNorm], 'omitnan');
    end
end

function T = build_metric_table(eventType, WindowResponse, temporalSimilarity, components, pscClasses, windowNames, epsDenom)
    rows = {};
    chlaIdx = find(strcmp(components, 'CHLA'), 1);
    [~, pscIdx] = ismember(pscClasses, components);

    for iWin = 1:numel(windowNames)
        winName = windowNames{iWin};
        X = WindowResponse.(winName);
        chlaResp = X(:, chlaIdx);
        pscResp = X(:, pscIdx);

        meanResp = mean(pscResp, 1, 'omitnan');
        absMeanResp = abs(meanResp);
        den = sum(absMeanResp, 'omitnan');
        if isfinite(den) && den > epsDenom
            contributionPct = 100 .* absMeanResp ./ den;
        else
            contributionPct = nan(size(absMeanResp));
        end

        for iPSC = 1:numel(pscClasses)
            psc = pscClasses{iPSC};
            x = chlaResp;
            y = pscResp(:, iPSC);
            rVal = pair_corr(x, y);
            r2Val = rVal .^ 2;
            nEvents = sum(isfinite(x) & isfinite(y));
            rows(end+1, :) = {string(eventType), string(winName), string(psc), ...
                meanResp(iPSC), absMeanResp(iPSC), contributionPct(iPSC), ...
                rVal, r2Val, temporalSimilarity.(psc), nEvents}; %#ok<AGROW>
        end
    end

    T = cell2table(rows, 'VariableNames', ...
        {'Event_Type', 'Window', 'PSC_Class', 'Mean_Response', 'Abs_Mean_Response', ...
         'Contribution_Percent', 'Correlation_With_CHLA', 'R2_With_CHLA', ...
         'Temporal_Correlation_With_CHLA', 'N_Events'});
end

function Summary = build_summary_table(Metrics, eventTypes, pscClasses, windowNames)
    rows = {};
    for iEvent = 1:numel(eventTypes)
        eventType = eventTypes{iEvent};
        for iPSC = 1:numel(pscClasses)
            psc = pscClasses{iPSC};
            mask = Metrics.Event_Type == string(eventType) & Metrics.PSC_Class == string(psc);
            temporalScore = mean(Metrics.Temporal_Correlation_With_CHLA(mask), 'omitnan');
            r2Score = mean(Metrics.R2_With_CHLA(mask), 'omitnan');
            contributionScore = mean(Metrics.Contribution_Percent(mask), 'omitnan') / 100;
            rows(end+1, :) = {string(eventType), string(psc), temporalScore, r2Score, contributionScore}; %#ok<AGROW>
        end

        for iWin = 1:numel(windowNames)
            winName = windowNames{iWin};
            maskWin = Metrics.Event_Type == string(eventType) & Metrics.Window == string(winName);
            [~, bestR2] = max(Metrics.R2_With_CHLA(maskWin));
            [~, bestContribution] = max(Metrics.Contribution_Percent(maskWin));
            pscWin = Metrics.PSC_Class(maskWin);
            fprintf('%s %s best R2: %s; best contribution: %s\n', ...
                eventType, winName, pscWin(bestR2), pscWin(bestContribution));
        end
    end
    Summary = cell2table(rows, 'VariableNames', ...
        {'Event_Type', 'PSC_Class', 'Temporal_similarity', 'R2', 'Contribution'});
end

function baseline = get_baseline_mean(dateVec, yVec, startDate, baselineDays)
    baseline = NaN;
    if ~isfinite(startDate), return; end
    vals = get_values_at_dates(dateVec, yVec, startDate + baselineDays);
    baseline = mean(vals, 'omitnan');
end

function vals = get_values_at_dates(dateVec, yVec, targetDates)
    vals = nan(size(targetDates));
    [tf, loc] = ismember(targetDates, dateVec);
    vals(tf) = yVec(loc(tf));
end

function normT = build_normalized_time(dateVec, tStart, tEnd)
    normT = nan(size(dateVec));
    pre = dateVec < tStart;
    during = dateVec >= tStart & dateVec <= tEnd;
    post = dateVec > tEnd;
    normT(pre) = (dateVec(pre) - tStart) / 30;
    if tEnd == tStart
        normT(during) = 0.5;
    else
        normT(during) = (dateVec(during) - tStart) / (tEnd - tStart);
    end
    normT(post) = 1 + (dateVec(post) - tEnd) / 30;
end

function yi = interp_unique(x, y, xi)
    yi = nan(size(xi));
    valid = isfinite(x) & isfinite(y);
    if sum(valid) < 3, return; end
    [ux, ia] = unique(x(valid));
    uy = y(valid);
    uy = uy(ia);
    if numel(ux) >= 3
        yi = interp1(ux, uy, xi, 'linear', NaN);
    end
end

function rVal = pair_corr(x, y)
    valid = isfinite(x) & isfinite(y);
    if sum(valid) < 3 || std(x(valid)) == 0 || std(y(valid)) == 0
        rVal = NaN;
        return;
    end
    C = corrcoef(x(valid), y(valid));
    rVal = C(1, 2);
end

function commonYLim = get_common_ylim(Result, components)
    vals = [];
    eventTypes = fieldnames(Result);
    for iEvent = 1:numel(eventTypes)
        eventType = eventTypes{iEvent};
        vals = [vals; Result.(eventType).AbsMean.Mean(:); Result.(eventType).NormMean.Mean(:)]; %#ok<AGROW>
    end
    vals = vals(isfinite(vals));
    maxAbs = max(abs(vals));
    if isempty(maxAbs) || ~isfinite(maxAbs) || maxAbs == 0
        maxAbs = 1;
    end
    commonYLim = [-1 1] * maxAbs * 1.10;
    if numel(components) < 1
        commonYLim = [-1 1];
    end
end

function plot_response_panel(ax, x, S, components, colors, panelTitle, xLabelText, yLimVals, curveWidth, lineWidth, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    disable_axes_toolbar(ax);
    hold on; box on; grid off;
    yline(0, '-', 'Color', [0.75 0.75 0.75], 'LineWidth', lineWidth);
    if min(x) < 0 && max(x) > 0
        xline(0, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', lineWidth);
    end
    if min(x) < 1 && max(x) > 1 && max(x) <= 2.05
        xline(1, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', lineWidth);
    end
    chlaIdx = find(strcmp(components, 'CHLA'), 1);
    if ~isempty(chlaIdx) && isfield(S, 'CI')
        y = S.Mean(:, chlaIdx);
        ci = S.CI(:, chlaIdx);
        valid = isfinite(x(:)) & isfinite(y(:)) & isfinite(ci(:));
        if sum(valid) >= 2
            xv = x(valid);
            yv = y(valid);
            civ = ci(valid);
            fill(ax, [xv(:); flipud(xv(:))], [yv(:) + civ(:); flipud(yv(:) - civ(:))], ...
                [0.2 0.2 0.2], 'FaceAlpha', 0.16, 'EdgeColor', 'none');
        end
    end
    for iComp = 1:numel(components)
        comp = components{iComp};
        y = S.Mean(:, iComp);
        valid = isfinite(x(:)) & isfinite(y(:));
        if sum(valid) < 2, continue; end
        plot(ax, x(valid), y(valid), '-', 'Color', colors.(comp), 'LineWidth', curveWidth);
    end
    title(panelTitle, 'FontSize', titleFontSize, 'FontWeight', 'normal');
    xlabel(xLabelText);
    ylabel('Anomaly (mg m^{-3})');
    xlim([min(x), max(x)]);
    ylim(yLimVals);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', 'FontName', 'Arial');
    yMax = max(abs(yLimVals));
    if isfinite(yMax) && yMax > 0
        ax.YAxis.Exponent = floor(log10(yMax));
    end
    ytickformat(ax, '%.1f');
end

function plot_metric_bar_panel(ax, Metrics, eventType, displayEventType, pscClasses, colors, metricField, windowNames, windowLabels, yLabelText, yLimits, lineWidth, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    disable_axes_toolbar(ax);
    Y = get_metric_matrix(Metrics, eventType, pscClasses, metricField, windowNames);
    b = bar(Y, 'grouped', 'LineWidth', lineWidth, 'BarWidth', 0.78);
    for iPSC = 1:numel(pscClasses)
        b(iPSC).FaceColor = colors.(pscClasses{iPSC});
    end
    box on; grid off;
    ylim(yLimits);
    xticks(1:numel(windowLabels));
    xticklabels(windowLabels);
    xtickangle(ax, 0);
    ylabel(yLabelText);
    title(displayEventType, 'FontSize', titleFontSize, 'FontWeight', 'normal');
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', 'FontName', 'Arial');
end

function plot_contribution_panel(ax, Metrics, eventType, displayEventType, pscClasses, colors, windowNames, windowLabels, lineWidth, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    disable_axes_toolbar(ax);
    Y = get_metric_matrix(Metrics, eventType, pscClasses, 'Contribution_Percent', windowNames);
    xPos = 1 + (0:numel(windowNames)-1) * 1.45;
    b = bar(xPos, Y, 'stacked', 'LineWidth', lineWidth, 'BarWidth', 0.62);
    for iPSC = 1:numel(pscClasses)
        b(iPSC).FaceColor = colors.(pscClasses{iPSC});
    end
    annotate_stacked_percentages(xPos, Y, mainFontSize);
    box on; grid off;
    ylim([0 100]);
    yticks(0:20:100);
    xlim([min(xPos) - 0.75, max(xPos) + 0.75]);
    xticks(xPos);
    xticklabels(windowLabels);
    xtickangle(ax, 0);
    ylabel('Contribution (%)');
    title(displayEventType, 'FontSize', titleFontSize, 'FontWeight', 'normal');
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', 'FontName', 'Arial');
end

function Y = get_metric_matrix(Metrics, eventType, pscClasses, metricField, windowNames)
    Y = nan(numel(windowNames), numel(pscClasses));
    for iWin = 1:numel(windowNames)
        for iPSC = 1:numel(pscClasses)
            mask = Metrics.Event_Type == string(eventType) & ...
                Metrics.Window == string(windowNames{iWin}) & ...
                Metrics.PSC_Class == string(pscClasses{iPSC});
            if any(mask)
                Y(iWin, iPSC) = Metrics.(metricField)(mask);
            end
        end
    end
end

function plot_summary_heatmap(ax, Summary, eventType, displayEventType, pscClasses, mainFontSize, titleFontSize)
    axes(ax); %#ok<LAXES>
    disable_axes_toolbar(ax);
    metricNames = {'Temporal', 'R^2', 'Contribution'};
    Z = nan(numel(pscClasses), numel(metricNames));
    for iPSC = 1:numel(pscClasses)
        mask = Summary.Event_Type == string(eventType) & Summary.PSC_Class == string(pscClasses{iPSC});
        Z(iPSC, :) = [Summary.Temporal_similarity(mask), Summary.R2(mask), Summary.Contribution(mask)];
    end
    imagesc(ax, Z);
    colormap(ax, dominance_colormap());
    clim(ax, [0 1]);
    cb = colorbar(ax);
    cb.Ticks = 0:0.2:1;
    cb.Label.String = 'Score';
    xticks(1:numel(metricNames));
    xticklabels(metricNames);
    xtickangle(ax, 0);
    yticks(1:numel(pscClasses));
    yticklabels(pscClasses);
    title(displayEventType, 'FontSize', titleFontSize, 'FontWeight', 'normal');
    set(ax, 'LineWidth', 0.5, 'FontSize', mainFontSize, 'TickDir', 'out', 'FontName', 'Arial');
    for i = 1:size(Z, 1)
        for j = 1:size(Z, 2)
            if isfinite(Z(i, j))
                text(j, i, sprintf('%.2f', Z(i, j)), 'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', 'FontSize', mainFontSize, 'FontName', 'Arial', 'Color', 'w');
            end
        end
    end
end

function cmap = dominance_colormap()
    n = 5;
    c5 = [linspace(1.00, 0.96, n)', ...
          linspace(1.00, 0.39, n)', ...
          linspace(1.00, 0.43, n)'];
    cmap = zeros(500, 3);
    for i = 1:5
        cmap((i-1)*100+1 : i*100, :) = repmat(c5(i, :), 100, 1);
    end
end

function annotate_stacked_percentages(xPos, Y, mainFontSize)
    for iWin = 1:size(Y, 1)
        yBase = 0;
        for iComp = 1:size(Y, 2)
            val = Y(iWin, iComp);
            if ~isfinite(val), continue; end
            yMid = yBase + val / 2;
            if val >= 5
                text(xPos(iWin), yMid, sprintf('%.0f%%', val), ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                    'FontName', 'Arial', 'FontSize', mainFontSize, 'Color', 'w');
            end
            yBase = yBase + val;
        end
    end
end

function add_shared_line_legend(tileObj, components, colors, mainFontSize)
    ax = nexttile(tileObj, 1);
    hold(ax, 'on');
    h = gobjects(numel(components), 1);
    for iComp = 1:numel(components)
        comp = components{iComp};
        h(iComp) = plot(ax, nan, nan, '-', 'Color', colors.(comp), 'LineWidth', 1.5);
    end
    lgd = legend(ax, h, components, 'Orientation', 'horizontal', 'Box', 'on', ...
        'FontSize', mainFontSize, 'FontName', 'Arial', 'NumColumns', numel(components));
    lgd.Layout.Tile = 'south';
    set(lgd, 'LineWidth', 0.5);
end

function add_shared_patch_legend(tileObj, pscClasses, colors, mainFontSize)
    ax = nexttile(tileObj, 1);
    hold(ax, 'on');
    h = gobjects(numel(pscClasses), 1);
    for iPSC = 1:numel(pscClasses)
        psc = pscClasses{iPSC};
        h(iPSC) = plot(ax, nan, nan, 's', 'MarkerFaceColor', colors.(psc), ...
            'MarkerEdgeColor', [0.15 0.15 0.15], 'MarkerSize', 6, 'LineStyle', 'none');
    end
    lgd = legend(ax, h, pscClasses, 'Orientation', 'horizontal', 'Box', 'on', ...
        'FontSize', mainFontSize, 'FontName', 'Arial', 'NumColumns', numel(pscClasses));
    lgd.Layout.Tile = 'south';
    set(lgd, 'LineWidth', 0.5);
end

function save_figure(fig, outDir, baseName, tiffDpi)
    outBase = fullfile(outDir, baseName);
    exportgraphics(fig, [outBase, '.tif'], 'Resolution', tiffDpi);
    fprintf('Saved: %s.tif\n', outBase);
    close(fig);
end

function disable_axes_toolbar(ax)
    if isprop(ax, 'Toolbar') && ~isempty(ax.Toolbar)
        ax.Toolbar.Visible = 'off';
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
