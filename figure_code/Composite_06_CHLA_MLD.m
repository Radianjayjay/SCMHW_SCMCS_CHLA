
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Composite 06: physical forcing and MLD-CHLA coupling
%%% Project: MHW_MCS_CHLA
%%% Code:   figure_code
%%% Inputs: figure_code/Cache/Plot_07_Physical_Mechanism_MLD_CHLA_PSC_plot_data.mat
%%% Output: figure_code/Cache/Composite_06_CHLA_MLD_plot_data.mat
%%%         figure_code/Out/Composite_06_CHLA_MLD.tif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. Paths and style ==================
this_file = mfilename('fullpath');
plot_dir = fileparts(this_file);
cache_dir = fullfile(plot_dir, 'Cache');
out_dir = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

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
LEGEND_LINE_WIDTH = 13;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
PANEL_FONT_SIZE = 8;
CACHE_VERSION = 1;

ABS_LAG_DAYS = -60:60;
DISPLAY.MHW = 'SCMHW';
DISPLAY.MCS = 'SCMCS';

COL.mld = [125 88 143] / 255;
COL.chla = [64 191 169] / 255;
COL.mhw = [248 127 112] / 255;
COL.mcs = [53 170 209] / 255;

CACHE_CONFIG = struct( ...
    'abs_lag_days', ABS_LAG_DAYS, ...
    'layout_id', 'fig07b_vertical_no_micro_left_fig07a_right_v1', ...
    'calculation_id', 'Composite06_mld_coupling_v1');

%% ================== 2. Build or load composite cache ==================
source_cache_file = fullfile(cache_dir, 'Plot_07_Physical_Mechanism_MLD_CHLA_PSC_plot_data.mat');
composite_cache_file = fullfile(cache_dir, 'Composite_06_CHLA_MLD_plot_data.mat');
input_files = {source_cache_file};

if is_plot_cache_current(composite_cache_file, input_files, CACHE_VERSION, CACHE_CONFIG)
    fprintf('Loading cached Composite 06 data: %s\n', composite_cache_file);
    C = load(composite_cache_file, 'Composite');
    Composite = C.Composite;
else
    fprintf('Building Composite 06 cache...\n');
    assert(exist(source_cache_file, 'file') == 2, ...
        'Missing source cache. Run Plot_07_Physical_Mechanism_MLD_CHLA_PSC.m first: %s', source_cache_file);
    S = load(source_cache_file, 'Result', 'MetricTable');
    Composite = struct();
    Composite.Result = S.Result;
    Composite.MetricTable = S.MetricTable;
    Composite.AbsLagDays = ABS_LAG_DAYS;
    Composite.SourceCache = source_cache_file;

    cache_version = CACHE_VERSION;
    cache_config = CACHE_CONFIG;
    save(composite_cache_file, 'Composite', 'cache_version', 'cache_config', '-v7.3');
    fprintf('Saved Composite 06 cache: %s\n', composite_cache_file);
end

%% ================== 3. Draw composite figure ==================
fprintf('Plotting Composite 06...\n');
fig = figure('Units', 'centimeters', ...
    'Position', [2 2 FULL_WIDTH_CM FIG_HEIGHT_CM], 'Color', 'w');

leftTopPos = [0.075 0.780 0.345 0.145];
rightTopPos = [0.520 0.780 0.345 0.145];
bottomFullPos = [0.075 0.590 0.790 0.145];
legendBoxH = 0.0225;
chlaRightAxisMHW.Lim = [-1.5e-2, 1.5e-2];
chlaRightAxisMHW.Ticks = -1.5e-2:0.5e-2:1.5e-2;
chlaRightAxisMCS.Lim = [-1.5e-2, 1.5e-2];
chlaRightAxisMCS.Ticks = -1.5e-2:0.5e-2:1.5e-2;

% Top Left: Subplot (a) - SCMHW (original subplot a)
ax = axes('Position', leftTopPos);
plot_dual_axis_lag_panel(ax, Composite.AbsLagDays, Composite.Result.MHW.MLD, ...
    Composite.Result.MHW.Bio.CHLA, ...
    [COL.mld; COL.chla], DISPLAY.MHW, true, LINE_WIDTH, CURVE_WIDTH, ...
    MAIN_FONT_SIZE, TITLE_FONT_SIZE, chlaRightAxisMHW);
add_panel_label_inside(ax, '(a)', PANEL_FONT_SIZE);

% Top Right: Subplot (b) - SCMCS (original subplot c)
ax = axes('Position', rightTopPos);
plot_dual_axis_lag_panel(ax, Composite.AbsLagDays, Composite.Result.MCS.MLD, ...
    Composite.Result.MCS.Bio.CHLA, ...
    [COL.mld; COL.chla], DISPLAY.MCS, true, LINE_WIDTH, CURVE_WIDTH, ...
    MAIN_FONT_SIZE, TITLE_FONT_SIZE, chlaRightAxisMCS);
add_panel_label_inside(ax, '(b)', PANEL_FONT_SIZE);

% Legend for original subplots a and c (now a and b) placed in the bottom-left of subplot a
legend1Pos = [0.085 0.790 0.100 0.040];
draw_line_legend(fig, {'MLD', 'CHLA'}, [COL.mld; COL.chla], ...
    legend1Pos, MAIN_FONT_SIZE, LEGEND_LINE_WIDTH);

% Bottom: Subplot (c) - MLD lag response (original subplot d stretched to full row width)
ax = axes('Position', bottomFullPos);
plot_combined_mld_lag_panel(ax, Composite.AbsLagDays, Composite.Result.MHW.MLD, ...
    Composite.Result.MCS.MLD, COL.mhw, COL.mcs, LINE_WIDTH, CURVE_WIDTH, ...
    MAIN_FONT_SIZE, TITLE_FONT_SIZE);
add_panel_label_inside(ax, '(c)', PANEL_FONT_SIZE);

% Legend for subplot c placed in the bottom-left of subplot c
legend2Pos = [0.085 0.600 0.120 0.040];
draw_line_legend(fig, {DISPLAY.MHW, DISPLAY.MCS}, [COL.mhw; COL.mcs], ...
    legend2Pos, MAIN_FONT_SIZE, LEGEND_LINE_WIDTH);

set(fig, 'InvertHardcopy', 'off');
fig_out = fullfile(out_dir, 'Composite_06_CHLA_MLD');
fprintf('Saving: %s.tif\n', fig_out);
exportgraphics(fig, [fig_out, '.tif'], 'Resolution', TIFF_DPI, 'BackgroundColor', 'white');
exportgraphics(fig, [fig_out, '.png'], 'Resolution', TIFF_DPI, 'BackgroundColor', 'white');
close(fig);

fprintf('Done.\n');

%% ================== Local functions ==================
function plot_dual_axis_lag_panel(ax, x, mldS, chlaS, colors, panelTitle, showXLabel, lineWidth, curveWidth, mainFontSize, titleFontSize, chlaAxis)
    % Use overlaid axes to avoid missing yyaxis series in 900 dpi exports.
    fig = ancestor(ax, 'figure');
    disable_axes_toolbar(ax);
    hold(ax, 'on');
    box(ax, 'off');
    xline(ax, 0, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth);
    yline(ax, 0, '-', 'Color', [0.75 0.75 0.75], 'LineWidth', lineWidth);
    plot_with_ci(ax, x, mldS.Mean, mldS.CI, colors(1, :), curveWidth);
    if strcmp(panelTitle, 'SCMHW')
        ylabel(ax, 'MLD anomaly (m)');
    end
    set(ax, 'YLim', [-5 5], 'YTick', -5:2.5:5, ...
        'XLim', [min(x) max(x)], 'XTick', -60:30:60, ...
        'YColor', colors(1, :), 'XColor', [0 0 0], ...
        'LineWidth', lineWidth, 'FontSize', mainFontSize, ...
        'TickDir', 'out', 'FontName', 'Arial', 'FontWeight', 'normal');
    if ~showXLabel, xticklabels(ax, {}); end
    grid(ax, 'off');

    rightAx = axes(fig, 'Units', ax.Units, 'Position', ax.Position, ...
        'Color', 'none', 'YAxisLocation', 'right', 'XAxisLocation', 'top', ...
        'XLim', [min(x) max(x)], 'XTick', -60:30:60, 'XTickLabel', {}, ...
        'YLim', [chlaAxis.Lim(1), chlaAxis.Lim(2) * 1.3], ...
        'YTick', chlaAxis.Ticks, 'YColor', colors(2, :), 'XColor', [0 0 0], ...
        'LineWidth', lineWidth, 'FontSize', mainFontSize, ...
        'TickDir', 'out', 'FontName', 'Arial', 'FontWeight', 'normal', 'Box', 'off');
    disable_axes_toolbar(rightAx);
    hold(rightAx, 'on');
    plot_with_ci(rightAx, x, chlaS.Mean, chlaS.CI, colors(2, :), curveWidth);
    if strcmp(panelTitle, 'SCMCS')
        ylabel(rightAx, 'CHLA anomaly (mg/m^3)');
    end
    rightAx.YAxis.Exponent = 0;
    ticks = chlaAxis.Ticks;
    labels = arrayfun(@(v) sprintf('%.1f', v * 100), ticks, 'UniformOutput', false);
    labels(abs(ticks) < 1e-9) = {'0'};
    yticklabels(rightAx, labels);
    text(ax, 0.015, 0.98, '\times10^{-2}', ...
        'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'left', 'Clipping', 'off', ...
        'FontSize', 6, 'FontName', 'Arial', 'FontWeight', 'normal', 'Color', [0 0 0]);
    tObj = title(ax, panelTitle, 'FontWeight', 'normal', ...
        'FontSize', titleFontSize, 'Color', [0 0 0]);
    tObj.Units = 'normalized';
    tObj.Position(2) = 1.025;
    grid(rightAx, 'off');
end

function ylim_symmetric_from_ci(ax, y, ci)
    vals = [y(:) + ci(:); y(:) - ci(:)];
    vals = vals(isfinite(vals));
    if isempty(vals)
        ylim(ax, [-1, 1]);
        return
    end
    maxAbs = max(abs(vals)) * 1.12;
    if ~isfinite(maxAbs) || maxAbs == 0
        maxAbs = 1;
    end
    ylim(ax, [-maxAbs, maxAbs]);
end

function plot_combined_mld_lag_panel(ax, x, mhwMLD, mcsMLD, mhwColor, mcsColor, lineWidth, curveWidth, mainFontSize, titleFontSize)
    axes(ax);
    disable_axes_toolbar(ax);
    hold(ax, 'on');
    box(ax, 'on');
    xline(ax, 0, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth);
    yline(ax, 0, '-', 'Color', [0.78 0.78 0.78], 'LineWidth', lineWidth);
    plot_with_ci(ax, x, mhwMLD.Mean, mhwMLD.CI, mhwColor, curveWidth);
    plot_with_ci(ax, x, mcsMLD.Mean, mcsMLD.CI, mcsColor, curveWidth);
    xlabel(ax, 'Lag (days)');
    ylabel(ax, 'MLD anomaly (m)');
    tObj = title(ax, 'MLD Lag Response', 'FontWeight', 'normal', 'FontSize', titleFontSize, 'Color', [0 0 0]);
    tObj.Units = 'normalized';
    tObj.Position(2) = 1.032; % 调这个值控制底部图标题高度：>1 上移，<1 下移
    xlim(ax, [min(x), max(x)]);
    xticks(ax, -60:30:60);
    ylim(ax, [-5, 5]);
    yticks(ax, -5:2.5:5);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, ...
        'TickDir', 'out', 'FontName', 'Arial', 'FontWeight', 'normal');
    grid(ax, 'off');
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

function draw_line_legend(fig, labels, colors, pos, mainFontSize, legendLineWidth)
    ax = axes(fig, 'Units', 'normalized', 'Position', pos, ...
        'Visible', 'off', 'Color', 'none', 'XLim', [0 1], 'YLim', [0 numel(labels)]);
    hold(ax, 'on');
    blockHeight = min(0.95, legendLineWidth / 12);
    for k = 1:numel(labels)
        itemY = numel(labels) - k + 0.5;
        rectangle(ax, 'Position', [0.05, itemY - blockHeight / 2, 0.30, blockHeight], ...
            'FaceColor', colors(k, :), ...
            'EdgeColor', 'none', ...
            'Clipping', 'off');
        text(ax, 0.45, itemY, labels{k}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', ...
            'FontSize', mainFontSize, ...
            'FontWeight', 'normal');
    end
end

function add_panel_label_inside(ax, labelText, fontSize)
    % 面板编号放在各自 axes 外部左上角
    text(ax, 0.01, 1.14, labelText, ...
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
