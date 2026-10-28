%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Composite 05: PSC HeatMap
%%% Project: MHW_MCS_CHLA
%%% Code:   figure_code
%%% Inputs: figure_code/Cache/Plot_06_CHLA_Micro_Dominance_plot_data.mat
%%% Output: figure_code/Cache/Composite_05_PSC_HeatMap_plot_data.mat
%%%         figure_code/Out/Composite_05_PSC_HeatMap.tif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. Paths and style ==================
this_file = mfilename('fullpath');
plot_dir = fileparts(this_file);
cache_dir = fullfile(plot_dir, 'Cache');
out_dir = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% 外部绘图工具必须由用户预先加入 MATLAB path。

set(groot, 'DefaultFigureColor', 'w');
% Fix neutral text/axis colors explicitly; do not inherit the desktop theme.
set(groot, 'DefaultTextColor', [0 0 0], ...
    'DefaultAxesXColor', [0 0 0], 'DefaultAxesYColor', [0 0 0], ...
    'DefaultAxesZColor', [0 0 0], 'DefaultAxesColor', 'w');
set(groot, 'DefaultAxesFontName', 'Arial');
set(groot, 'DefaultTextFontName', 'Arial');
set(groot, 'DefaultAxesFontSize', 7);
set(groot, 'DefaultTextFontSize', 7);
set(groot, 'DefaultAxesFontWeight', 'normal');
set(groot, 'DefaultTextFontWeight', 'normal');
set(groot, 'DefaultAxesLineWidth', 0.5);
set(groot, 'DefaultAxesTickDir', 'out');

FULL_WIDTH_CM = 17;
FIG_HEIGHT_CM = 20;
TIFF_DPI = 900;
LINE_WIDTH = 0.5;
CURVE_WIDTH = 1.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
PANEL_FONT_SIZE = 8;
CACHE_VERSION = 1;
RESPONSE_Y_LIMITS = [-1.0e-2, 1.5e-2];
RESPONSE_Y_TICK_STEP = 0.5e-2;

EVENT_TYPES = {'MHW', 'MCS'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';
HEATMAP_TITLES.MHW = 'SCMHW PSC metric';
HEATMAP_TITLES.MCS = 'SCMCS PSC metric';
COMPONENTS = {'CHLA', 'Pico', 'Nano', 'Micro'};
LEGEND_COMPONENTS = {'CHLA', 'Micro', 'Nano', 'Pico'};
PSC_CLASSES = {'Pico', 'Nano', 'Micro'};
COMP_COLORS.CHLA = [0.02 0.02 0.02];
BAR_COLORS.Pico = [169 203 140] / 255;
BAR_COLORS.Nano = [091 189 160] / 255;
BAR_COLORS.Micro = [000 141 170] / 255;
% abcd 折线中的 PSC 颜色与 ef 柱状图保持一致；只保留 CHLA 为黑色。
COMP_COLORS.Pico = BAR_COLORS.Pico;
COMP_COLORS.Nano = BAR_COLORS.Nano;
COMP_COLORS.Micro = BAR_COLORS.Micro;
ABS_LAG_DAYS = -60:60;
NORM_GRID = linspace(-1, 2, 151);
WINDOW_NAMES = {'Pre30d', 'Peak_pm5d', 'Post30d', 'Full'};
WINDOW_LABELS = {'Pre30d', 'Peak\pm5d', 'Post30d', 'Full'};

CACHE_CONFIG = struct( ...
    'components', {COMPONENTS}, ...
    'psc_classes', {PSC_CLASSES}, ...
    'abs_lag_days', ABS_LAG_DAYS, ...
    'norm_grid', NORM_GRID, ...
    'window_names', {WINDOW_NAMES}, ...
    'layout_id', 'fig06_a_b_d_vertical_v1', ...
    'calculation_id', 'Composite05_psc_heatmap_v1');

%% ================== 2. Build or load composite cache ==================
source_cache_file = fullfile(cache_dir, 'Plot_06_CHLA_Micro_Dominance_plot_data.mat');
composite_cache_file = fullfile(cache_dir, 'Composite_05_PSC_HeatMap_plot_data.mat');
input_files = {source_cache_file};

if is_plot_cache_current(composite_cache_file, input_files, CACHE_VERSION, CACHE_CONFIG)
    fprintf('Loading cached Composite 05 data: %s\n', composite_cache_file);
    C = load(composite_cache_file, 'Composite');
    Composite = C.Composite;
else
    fprintf('Building Composite 05 cache...\n');
    assert(exist(source_cache_file, 'file') == 2, ...
        'Missing source cache. Run Plot_06_CHLA_Micro_Dominance.m first: %s', source_cache_file);
    S = load(source_cache_file, 'Result', 'Metrics');
    Composite = struct();
    Composite.Result = S.Result;
    Composite.Metrics = S.Metrics;
    Composite.Summary = build_summary_table(S.Metrics, EVENT_TYPES, PSC_CLASSES);
    Composite.SourceCache = source_cache_file;
    Composite.DisplayEventTypes = DISPLAY_EVENT_TYPES;
    Composite.Components = COMPONENTS;
    Composite.PscClasses = PSC_CLASSES;
    Composite.AbsLagDays = ABS_LAG_DAYS;
    Composite.NormGrid = NORM_GRID;
    Composite.WindowNames = WINDOW_NAMES;
    Composite.WindowLabels = WINDOW_LABELS;

    cache_version = CACHE_VERSION;
    cache_config = CACHE_CONFIG;
    save(composite_cache_file, 'Composite', 'cache_version', 'cache_config', '-v7.3');
    fprintf('Saved Composite 05 cache: %s\n', composite_cache_file);
end

%% ================== 3. Draw composite figure ==================
fprintf('Plotting Composite 05...\n');
fig = figure('Units', 'centimeters', ...
    'Position', [2 2 FULL_WIDTH_CM FIG_HEIGHT_CM], 'Color', 'w');

common_ylim = RESPONSE_Y_LIMITS;

ax_pos_a = [0.070 0.825 0.325 0.120;
            0.455 0.825 0.325 0.120;
            0.070 0.660 0.325 0.120;
            0.455 0.660 0.325 0.120];
ax = axes('Position', ax_pos_a(1, :));
plot_response_panel(ax, Composite.AbsLagDays, Composite.Result.MHW.AbsMean, ...
    COMPONENTS, COMP_COLORS, 'SCMHW absolute time', 'Lag days (0 = peak)', ...
    common_ylim, RESPONSE_Y_TICK_STEP, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
ylabel(ax, 'CHLA anomaly (mg/m^3)');
xticks(ax, [-60 0 60]);
xtickangle(ax, 0);
add_panel_label_inside(ax, '(a)', PANEL_FONT_SIZE);

ax = axes('Position', ax_pos_a(2, :));
plot_response_panel(ax, Composite.AbsLagDays, Composite.Result.MCS.AbsMean, ...
    COMPONENTS, COMP_COLORS, 'SCMCS absolute time', 'Lag days (0 = peak)', ...
    common_ylim, RESPONSE_Y_TICK_STEP, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
xticks(ax, [-60 0 60]);
xtickangle(ax, 0);
add_panel_label_inside(ax, '(b)', PANEL_FONT_SIZE);

ax = axes('Position', ax_pos_a(3, :));
plot_response_panel(ax, Composite.NormGrid, Composite.Result.MHW.NormMean, ...
    COMPONENTS, COMP_COLORS, 'SCMHW normalized time', 'Normalized event phase', ...
    common_ylim, RESPONSE_Y_TICK_STEP, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
ylabel(ax, 'CHLA anomaly (mg/m^3)');
xticks(ax, [-1 0 1 2]);
xticklabels(ax, {'Pre', 'On', 'End', 'Post'});
xtickangle(ax, 0);
add_panel_label_inside(ax, '(c)', PANEL_FONT_SIZE);

ax = axes('Position', ax_pos_a(4, :));
plot_response_panel(ax, Composite.NormGrid, Composite.Result.MCS.NormMean, ...
    COMPONENTS, COMP_COLORS, 'SCMCS normalized time', 'Normalized event phase', ...
    common_ylim, RESPONSE_Y_TICK_STEP, CURVE_WIDTH, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
xticks(ax, [-1 0 1 2]);
xticklabels(ax, {'Pre', 'On', 'End', 'Post'});
xtickangle(ax, 0);
add_panel_label_inside(ax, '(d)', PANEL_FONT_SIZE);
draw_line_legend_inside(fig, ax, LEGEND_COMPONENTS, COMP_COLORS, [0.005 0.06 0.98 0.18], ...
    MAIN_FONT_SIZE, CURVE_WIDTH, LINE_WIDTH);

% D: dominance summary heatmap.
heatmapPosMhw = [0.090 0.435 0.230 0.180];
heatmapPosMcs = [0.475 0.435 0.230 0.180];
heatmapLabelPosMhw = [0.095 0.415 0.040 0.192];
heatmapLabelPosMcs = [0.480 0.415 0.040 0.192];
heatmapMetricNames = {'Temporal', 'R^2', 'Contribution'};
ax = axes('Position', heatmapPosMhw);
plot_summary_heatmap(ax, Composite.Summary, 'MHW', DISPLAY_EVENT_TYPES.MHW, ...
    PSC_CLASSES, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
add_panel_label_title_level(fig, heatmapLabelPosMhw, '(e)', TITLE_FONT_SIZE);
add_heatmap_title_title_level(fig, heatmapPosMhw, heatmapLabelPosMhw, HEATMAP_TITLES.MHW, TITLE_FONT_SIZE);
ax = axes('Position', heatmapPosMcs);
plot_summary_heatmap(ax, Composite.Summary, 'MCS', DISPLAY_EVENT_TYPES.MCS, ...
    PSC_CLASSES, MAIN_FONT_SIZE, TITLE_FONT_SIZE);
add_panel_label_title_level(fig, heatmapLabelPosMcs, '(f)', TITLE_FONT_SIZE);
add_heatmap_title_title_level(fig, heatmapPosMcs, heatmapLabelPosMcs, HEATMAP_TITLES.MCS, TITLE_FONT_SIZE);
add_shared_heatmap_row_labels(fig, [0.350 0.435 0.095 0.180], heatmapMetricNames, MAIN_FONT_SIZE);
draw_shared_heatmap_colorbar(fig, [0.740 0.440 0.012 0.170], MAIN_FONT_SIZE);

set(fig, 'InvertHardcopy', 'off');
fig_out = fullfile(out_dir, 'Composite_05_PSC_HeatMap');
fprintf('Saving: %s.tif\n', fig_out);
exportgraphics(fig, [fig_out, '.tif'], 'Resolution', TIFF_DPI, 'BackgroundColor', 'white');
exportgraphics(fig, [fig_out, '.png'], 'Resolution', TIFF_DPI, 'BackgroundColor', 'white');
close(fig);

fprintf('Done.\n');

%% ================== Local functions ==================
function plot_response_panel(ax, x, S, components, colors, panelTitle, ~, yLimVals, yTickStep, curveWidth, lineWidth, mainFontSize, titleFontSize)
    axes(ax);
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
    tObj = title(panelTitle, 'FontSize', titleFontSize, 'FontWeight', 'normal', 'Color', [0 0 0]);
    tObj.Units = 'normalized';
    tObj.Position(2) = 1.025; % 调这个值控制折线图标题高度：>1 上移，<1 下移
    xlabel('');
    ylabel('');
    xlim([min(x), max(x)]);
    ylim(yLimVals);
    if isfinite(yTickStep) && yTickStep > 0
        yticks(ax, yLimVals(1):yTickStep:yLimVals(2));
    end
    format_response_y_axis(ax, yLimVals);
    xtickangle(ax, 0);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', ...
        'FontName', 'Arial', 'FontWeight', 'normal');
end

function Summary = build_summary_table(Metrics, eventTypes, pscClasses)
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
    end
    Summary = cell2table(rows, 'VariableNames', ...
        {'Event_Type', 'PSC_Class', 'Temporal_similarity', 'R2', 'Contribution'});
end

function plot_summary_heatmap(ax, Summary, eventType, ~, ~, mainFontSize, ~)
    axes(ax);
    disable_axes_toolbar(ax);
    metricNames = {'Temporal', 'R^2', 'Contribution'};
    pscDisplay = {'Micro', 'Nano', 'Pico'};
    Z = nan(numel(metricNames), numel(pscDisplay));
    for iPSC = 1:numel(pscDisplay)
        mask = Summary.Event_Type == string(eventType) & Summary.PSC_Class == string(pscDisplay{iPSC});
        Z(:, iPSC) = [Summary.Temporal_similarity(mask); Summary.R2(mask); Summary.Contribution(mask)];
    end
    colormap(ax, dominance_colormap());
    clim(ax, [0 1]);
    hold(ax, 'on');
    set(ax, 'Color', 'w');
    cmap = colormap(ax);
    for i = 1:size(Z, 1)
        for j = 1:size(Z, 2)
            if ~isfinite(Z(i, j)), continue; end
            faceColor = value_to_colormap_rgb(Z(i, j), cmap, [0 1]);
            rectangle(ax, 'Position', [j - 0.42, i - 0.42, 0.84, 0.84], ...
                'Curvature', [0.16, 0.16], ...
                'FaceColor', faceColor, ...
                'EdgeColor', [0.5 0.5 0.5], ...
                'LineWidth', 0.5);
            text(j, i, sprintf('%.2f', Z(i, j)), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', mainFontSize, ...
                'FontName', 'Arial', ...
                'FontWeight', 'normal', ...
                'Color', [0 0 0]);
        end
    end
    xticks([]);
    yticks([]);
    title('', 'Color', [0 0 0]);
    axis(ax, 'equal');
    xlim(ax, [0.5, numel(pscDisplay) + 0.5]);
    ylim(ax, [0.5, numel(metricNames) + 0.5]);
    set(ax, 'YDir', 'reverse');
    set(ax, 'LineWidth', 0.5, 'FontSize', mainFontSize, 'TickDir', 'out', ...
        'FontName', 'Arial', 'FontWeight', 'normal', ...
        'XGrid', 'off', 'YGrid', 'off', 'Layer', 'top', ...
        'TickLength', [0 0], ...
        'XColor', 'none', 'YColor', 'none');
    box(ax, 'off');
    for j = 1:numel(pscDisplay)
        text(ax, j, numel(metricNames) + 0.52, pscDisplay{j}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ...
            'FontSize', mainFontSize, ...
            'FontName', 'Arial', ...
            'FontWeight', 'normal', ...
            'Color', [0 0 0], ...
            'Clipping', 'off', ...
            'Interpreter', 'none');
    end
end

function add_shared_heatmap_row_labels(fig, pos, metricNames, mainFontSize)
    ax = axes(fig, 'Units', 'normalized', 'Position', pos, ...
        'Visible', 'off', 'Color', 'none', 'XLim', [0 1], ...
        'YLim', [0.5, numel(metricNames) + 0.5], 'YDir', 'reverse');
    for iMetric = 1:numel(metricNames)
        text(ax, 0.5, iMetric, metricNames{iMetric}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', mainFontSize, ...
            'FontName', 'Arial', ...
            'FontWeight', 'normal', ...
            'Color', [0 0 0], ...
            'Interpreter', 'tex');
    end
end

function draw_shared_heatmap_colorbar(fig, cbPos, mainFontSize)
    ax = axes(fig, 'Units', 'normalized', 'Position', [cbPos(1) - 0.012, cbPos(2), 0.010, cbPos(4)], ...
        'Visible', 'off');
    colormap(ax, dominance_colormap());
    clim(ax, [0 1]);
    cb = colorbar(ax, 'eastoutside');
    cb.Color = [0 0 0];
    cb.Label.Color = [0 0 0];
    cb.Position = cbPos;
    cb.Ticks = 0:0.2:1;
    cb.TickLabels = {'0', '0.2', '0.4', '0.6', '0.8', '1'};
    cb.FontName = 'Arial';
    cb.FontSize = mainFontSize;
    cb.FontWeight = 'normal';
    cb.TickDirection = 'out';
    cb.LineWidth = 0.5;
end

function cmap = dominance_colormap()
    n = 5;
    c5 = [linspace(1.00, 0.96, n)', ...
          linspace(1.00, 0.39, n)', ...
          linspace(1.00, 0.43, n)'];
    % Repeat each color 100 times to create a 500-level discrete colormap
    cmap = zeros(500, 3);
    for i = 1:5
        cmap((i-1)*100+1 : i*100, :) = repmat(c5(i, :), 100, 1);
    end
end

function rgb = value_to_colormap_rgb(value, cmap, limits)
    value = min(max(value, limits(1)), limits(2));
    norm_val = (value - limits(1)) / (limits(2) - limits(1));
    idx = floor(norm_val * size(cmap, 1)) + 1;
    idx = min(idx, size(cmap, 1));
    rgb = cmap(idx, :);
end

function draw_line_legend_inside(fig, parentAx, components, colors, pos, mainFontSize, ~, lineWidth)
    parentPos = get(parentAx, 'Position');
    legendPos = [parentPos(1) + pos(1) * parentPos(3), ...
                 parentPos(2) + pos(2) * parentPos(4), ...
                 pos(3) * parentPos(3), ...
                 pos(4) * parentPos(4)];
    ax = axes(fig, 'Units', 'normalized', 'Position', legendPos, ...
        'Visible', 'off', 'Color', 'none', 'XLim', [0 4], 'YLim', [0 1]);
    hold(ax, 'on');
    for iComp = 1:numel(components)
        itemX = (iComp - 1) * 4 / numel(components);
        comp = components{iComp};
        rectangle(ax, 'Position', [itemX + 0.18, 0.30, 0.30, 0.40], ...
            'FaceColor', colors.(comp), ...
            'EdgeColor', 'none', ...
            'LineWidth', lineWidth);
        text(ax, itemX + 0.58, 0.5, comp, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', 'FontSize', mainFontSize, 'FontWeight', 'normal');
    end
end

function add_panel_label_inside(ax, labelText, fontSize)
    % 面板编号放在各自 axes 外部左上角
    text(ax, 0.01, 1.16, labelText, ...
        'Units', 'normalized', ...
        'FontName', 'Arial', ...
        'FontSize', fontSize, ...
        'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'Color', [0 0 0], ...
        'Interpreter', 'none', ...
        'Clipping', 'off');
end

function add_panel_label_title_level(fig, axPos, labelText, fontSize)
    % =========================================================
    % 调这个值单独控制 (e)(f) 标号的高度：变大上移，变小下移
    % 左右位置由第一个值 axPos(1) 控制，想右移就给 axPos(1) 加一点。
    % =========================================================
    labelYOffset = 0.000;
    annotation(fig, 'textbox', [axPos(1), axPos(2) + axPos(4) + labelYOffset, 0.040, 0.025], ...
        'String', labelText, ...
        'LineStyle', 'none', ...
        'FontName', 'Arial', ...
        'FontSize', fontSize, ...
        'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none', ...
        'FitBoxToText', 'off', 'Color', [0 0 0]);
end

function add_heatmap_title_title_level(fig, heatmapPos, labelPos, titleText, fontSize)
    % 标题的垂直位置跟 (e)(f) 标号齐平；水平位置按各自 heatmap 居中并向右微调以防与左侧标号重叠。
    titleWidth = 0.300; % 给定足够宽度以防自动换行
    % 标题水平位置按各自 heatmap 居中
    leftPos = (heatmapPos(1) + heatmapPos(3)/2) - titleWidth/2 + 0.015;
    % =========================================================
    % 调这个值单独控制热图标题高度：变大上移，变小下移
    % =========================================================
    titleYOffset = -0.001; 
    annotation(fig, 'textbox', [leftPos, labelPos(2) + labelPos(4) + titleYOffset, titleWidth, 0.025], ...
        'String', titleText, ...
        'LineStyle', 'none', ...
        'FontName', 'Arial', ...
        'FontSize', fontSize, ...
        'FontWeight', 'normal', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none', ...
        'FitBoxToText', 'off', 'Color', [0 0 0]);
end

function format_response_y_axis(ax, yLimVals)
    yMax = max(abs(yLimVals));
    if yMax < 0.1
        expVal = floor(log10(yMax));
        ax.YAxis.Exponent = 0;
        ticks = yticks(ax);
        labels = arrayfun(@(v) sprintf('%.1f', v / 10^expVal), ticks, 'UniformOutput', false);
        labels(abs(ticks) < 1e-9) = {'0'};
        yticklabels(ax, labels);
        
        % 科学计数法放到图左上角的内侧
        expXPos = 0.015; 
        text(ax, expXPos, 0.98, sprintf('\\times10^{%d}', expVal), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'left', ...
            'Clipping', 'off', ...
            'FontSize', 6, 'FontName', 'Arial', ...
            'FontWeight', 'normal');
            
    elseif yMax < 1
        ax.YAxis.Exponent = 0;
        ticks = yticks(ax);
        labels = arrayfun(@(v) sprintf('%.2f', v), ticks, 'UniformOutput', false);
        labels(abs(ticks) < 1e-9) = {'0'};
        yticklabels(ax, labels);
    else
        ax.YAxis.Exponent = 0;
        ticks = yticks(ax);
        labels = arrayfun(@(v) sprintf('%.1f', v), ticks, 'UniformOutput', false);
        labels(abs(ticks) < 1e-9) = {'0'};
        yticklabels(ax, labels);
    end
end

function disable_axes_toolbar(ax)
    try
        axtoolbar(ax, {});
    catch
    end
    try
        disableDefaultInteractivity(ax);
    catch
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
