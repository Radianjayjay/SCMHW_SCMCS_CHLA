%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot 00: SCMHW/SCMCS event count and L1-L3 spatial distributions
%%% Project: MHW_MCS_CHLA
%%% Code:   figure_code
%%% Output: figure_code/Out/Fig00*.tif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. Paths and style ==================
this_file = mfilename('fullpath');
plot_dir = fileparts(this_file);
base_dir = fileparts(plot_dir);

char_dir = fullfile(base_dir, '05_Characteristic', 'Out');
stat_dir = fullfile(base_dir, '04_Statistic', 'Out');
cache_dir = fullfile(plot_dir, 'Cache');
out_dir  = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% 外部绘图工具必须由用户预先加入 MATLAB path。
assert(exist('m_proj', 'file') == 2, 'm_map is required: m_proj was not found on the MATLAB path.');

set(groot, 'DefaultFigureColor', 'w');
set(groot, 'DefaultAxesFontName', 'Arial');
set(groot, 'DefaultTextFontName', 'Arial');
set(groot, 'DefaultAxesFontSize', 7);
set(groot, 'DefaultTextFontSize', 7);
set(groot, 'DefaultAxesFontWeight', 'normal');
set(groot, 'DefaultTextFontWeight', 'normal');
set(groot, 'DefaultAxesLineWidth', 0.5);
set(groot, 'DefaultAxesTickDir', 'out');

HALF_WIDTH_CM = 8;
TWO_THIRD_WIDTH_CM = 14;
FULL_WIDTH_CM = 17;
TIFF_DPI = 900;
LINE_WIDTH = 0.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
GRID_RES = 0.5;
NX = 720;
NY = 181;
LAT_RANGE = [-45, 45];

EVENT_TYPES = {'MHW', 'MCS'};
METRICS = {'Area', 'Duration', 'Intensity'};
LEVEL_IDS = 1:3;
LEVEL_LABELS = {'L1 (0-25%)', 'L2 (25-75%)', 'L3 (75-100%)'};
LEVEL_SHORT_LABELS = {'L1', 'L2', 'L3'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';

EVENT_COLORS.MHW = [242 90 91] / 255;
EVENT_COLORS.MCS = [58 184 237] / 255;
LEVEL_COLORS = [254 229 217
                252 146 114
                203 024 029] / 255;
CACHE_VERSION = 1;
CACHE_CONFIG = struct( ...
    'grid_res', GRID_RES, ...
    'nx', NX, ...
    'ny', NY, ...
    'lat_range', LAT_RANGE, ...
    'metrics', {METRICS}, ...
    'level_ids', LEVEL_IDS, ...
    'group_pcts', [0 25 75 100], ...
    'calculation_id', 'Plot00_spatial_grid_v1');

%% ================== 2. Load data and define L1-L3 ==================
fprintf('Loading characteristic tables...\n');
Tables.MHW = load_basic_table(fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat'), 'MHW');
Tables.MCS = load_basic_table(fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat'), 'MCS');

Counts.MHW = height(Tables.MHW);
Counts.MCS = height(Tables.MCS);
disp(struct2table(Counts));

fprintf('Building L1-L3 groups from 25%% and 75%% count percentiles...\n');
for iEvent = 1:numel(EVENT_TYPES)
    event_type = EVENT_TYPES{iEvent};
    int_col = sprintf('%s_Global_Mean', event_type);
    Tables.(event_type).Area_Group = group_by_count(Tables.(event_type).Max_Area, [0 25 75 100]);
    Tables.(event_type).Duration_Group = group_by_count(Tables.(event_type).Duration, [0 25 75 100]);
    Tables.(event_type).Intensity_Group = group_by_count(abs(Tables.(event_type).(int_col)), [0 25 75 100]);
end

print_level_summary(Tables, EVENT_TYPES, METRICS, LEVEL_IDS, LEVEL_LABELS);

%% ================== 3. Figure 00a: Event count ==================
fprintf('Plotting Figure 00a...\n');
fig00a = figure('Units', 'centimeters', 'Position', [2 2 HALF_WIDTH_CM 6], 'Color', 'w');
ax = axes('Position', [0.24 0.20 0.68 0.68]);

type_x = 1:2;
type_y = [Counts.MHW, Counts.MCS];
bar_handle = bar(ax, type_x, type_y, 0.62, 'EdgeColor', 'k', 'LineWidth', LINE_WIDTH);
bar_handle.FaceColor = 'flat';
bar_handle.CData = [EVENT_COLORS.MHW; EVENT_COLORS.MCS];

for iBar = 1:numel(type_y)
    text(type_x(iBar), type_y(iBar) + max(type_y) * 0.025, sprintf('%d', type_y(iBar)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'normal');
end

set(ax, 'Box', 'on', 'TickDir', 'out', 'XTick', type_x, ...
    'XTickLabel', {'SCMHW', 'SCMCS'}, 'XLim', [0.35 2.65], ...
    'YLim', [0 max(type_y) * 1.16], 'XGrid', 'off', 'YGrid', 'off', ...
    'LineWidth', LINE_WIDTH, 'FontSize', MAIN_FONT_SIZE);
ylabel(ax, ' ', 'Units', 'normalized', 'Position', [-0.18, 0.5, 0]);
title(ax, ' ', 'FontWeight', 'normal', 'FontSize', TITLE_FONT_SIZE);

set(fig00a, 'InvertHardcopy', 'off');
fig00a_out = fullfile(out_dir, 'Fig00a_MHW_MCS_Event_Count');
fprintf('Saving: %s.tif\n', fig00a_out);
exportgraphics(fig00a, [fig00a_out, '.tif'], 'Resolution', TIFF_DPI);

%% ================== 4. Figure 00c: L1-L3 event counts ==================
fprintf('Plotting Figure 00c...\n');
for iMetric = 1:numel(METRICS)
    metric = METRICS{iMetric};
    [level_count_data, level_count_labels] = build_level_count_data(Tables, EVENT_TYPES, {metric}, LEVEL_IDS, DISPLAY_EVENT_TYPES);

    fig00c = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 7], 'Color', 'w');
    ax = axes('Position', [0.135 0.345 0.790 0.390]);
    bar_y = 1 + (0:numel(level_count_labels)-1) * 0.58;
    bar_handles = barh(ax, bar_y, level_count_data, 0.30, 'stacked', ...
        'EdgeColor', 'k', 'LineWidth', LINE_WIDTH);
    for iLevel = 1:numel(bar_handles)
        bar_handles(iLevel).FaceColor = LEVEL_COLORS(iLevel, :);
    end
    hold(ax, 'on');

    max_total = max(sum(level_count_data, 2));
    for iRow = 1:size(level_count_data, 1)
        x_left = 0;
        for iLevel = 1:size(level_count_data, 2)
            count_value = level_count_data(iRow, iLevel);
            if count_value > 0
                x_mid = x_left + count_value / 2;
                if count_value >= max_total * 0.055
                    text(ax, x_mid, bar_y(iRow), sprintf('%s=%d', LEVEL_SHORT_LABELS{iLevel}, count_value), ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'FontSize', MAIN_FONT_SIZE, ...
                        'FontName', 'Arial', ...
                        'Color', [0.10 0.10 0.10]);
                end
            end
            x_left = x_left + count_value;
        end
    end

    set(ax, 'Box', 'on', 'TickDir', 'out', ...
        'YTick', bar_y, ...
        'YTickLabel', level_count_labels, ...
        'XTick', [], ...
        'XTickLabel', {}, ...
        'YDir', 'reverse', ...
        'YLim', [bar_y(1) - 0.18, bar_y(end) + 0.18], ...
        'XLim', [0 max_total * 1.12], ...
        'XGrid', 'off', 'YGrid', 'off', ...
        'GridAlpha', 0.18, ...
        'LineWidth', LINE_WIDTH, ...
        'FontSize', MAIN_FONT_SIZE, ...
        'FontName', 'Arial');
    xlabel(ax, '');
    hTitle = title(ax, sprintf('%s grouping', metric), ...
        'FontWeight', 'normal', 'FontSize', TITLE_FONT_SIZE);
    hTitle.Units = 'normalized';
    hTitle.Position(2) = 1.12;

    set(fig00c, 'InvertHardcopy', 'off');
    fig00c_out = fullfile(out_dir, sprintf('Fig00c_MHW_MCS_Level_Count_%s_StackedBar', metric));
    fprintf('Saving: %s.tif\n', fig00c_out);
    exportgraphics(fig00c, [fig00c_out, '.tif'], 'Resolution', TIFF_DPI);
    close(fig00c);
end

%% ================== 5. Spatial grids for Figure 00b ==================
cache_file = fullfile(cache_dir, 'Plot_00_Spatial_Distribution_plot_data.mat');
input_files = { ...
    fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat'), ...
    fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat'), ...
    fullfile(stat_dir, 'Statistic_MHW_Basin_Eps5_MinPts200.mat'), ...
    fullfile(stat_dir, 'Statistic_MCS_Basin_Eps5_MinPts200.mat')};

if is_plot_cache_current(cache_file, input_files, CACHE_VERSION, CACHE_CONFIG)
    fprintf('Loading cached Plot 00 spatial grids: %s\n', cache_file);
    C = load(cache_file, 'Grids');
    Grids = C.Grids;
else
    fprintf('Accumulating spatial grids. This is the slow step.\n');
    for iEvent = 1:numel(EVENT_TYPES)
        event_type = EVENT_TYPES{iEvent};
        for iMetric = 1:numel(METRICS)
            metric = METRICS{iMetric};
            for level_id = LEVEL_IDS
                Grids.(event_type).(metric)(level_id).SumInt = zeros(NX, NY, 'single');
                Grids.(event_type).(metric)(level_id).Count = zeros(NX, NY, 'single');
            end
        end
    end

    for iEvent = 1:numel(EVENT_TYPES)
        event_type = EVENT_TYPES{iEvent};
        stat_file = fullfile(stat_dir, sprintf('Statistic_%s_Basin_Eps5_MinPts200.mat', event_type));
        Grids.(event_type) = accumulate_event_grids(stat_file, Tables.(event_type), event_type, ...
            Grids.(event_type), NX, NY);
    end

    cache_version = CACHE_VERSION; %#ok<NASGU>
    cache_config = CACHE_CONFIG; %#ok<NASGU>
    save(cache_file, 'Grids', 'cache_version', 'cache_config', '-v7.3');
    fprintf('Saved cached Plot 00 spatial grids: %s\n', cache_file);
end

%% ================== 6. Figure 00b: Spatial distribution by metric ==================
fprintf('Plotting Figure 00b maps...\n');
vec_lon = 0.5:GRID_RES:360;
vec_lat = LAT_RANGE(1):GRID_RES:LAT_RANGE(2);
[LonGrid, LatGrid] = meshgrid(vec_lon, vec_lat);

x_pos = 0.09;
y_pos = [0.720, 0.440, 0.160];
ax_w = 0.84;
ax_h = 0.190;

for iEvent = 1:numel(EVENT_TYPES)
    event_type = EVENT_TYPES{iEvent};
    for iMetric = 1:numel(METRICS)
        metric = METRICS{iMetric};
        fig = figure('Units', 'centimeters', 'Position', [2 2 TWO_THIRD_WIDTH_CM 16], 'Color', 'w');

        if strcmp(metric, 'Duration')
            c_lim = [0, 40];
            c_ticks = 0:8:40;
            c_tick_labels = compose('%.0f', c_ticks);
            c_label = 'Total days';
            temp_colors = nclCM(157);
            cmap = temp_colors(end-9:end, :);
        elseif strcmp(event_type, 'MHW')
            c_lim = [0, 3];
            c_ticks = 0:0.6:3;
            c_tick_labels = {'0', '0.6', '1.2', '1.8', '2.4', '3.0'};
            c_label = 'Mean Intensity (degC)';
            cmap = nclCM(188, 10);
        else
            c_lim = [-3, 0];
            c_ticks = -3:0.6:0;
            c_tick_labels = {'-3.0', '-2.4', '-1.8', '-1.2', '-0.6', '0'};
            c_label = 'Mean Intensity (degC)';
            cmap = flipud(nclCM(161, 10));
        end

        for iLevel = 1:numel(LEVEL_IDS)
            level_id = LEVEL_IDS(iLevel);
            axes('Position', [x_pos, y_pos(iLevel), ax_w, ax_h]); %#ok<LAXES>

            G = Grids.(event_type).(metric)(level_id);
            if strcmp(metric, 'Duration')
                Z = double(G.Count);
            else
                Z = double(G.SumInt) ./ double(G.Count);
                Z(G.Count == 0) = NaN;
            end

            Z_plot = Z';
            Z_plot(isnan(Z_plot)) = 0;
            m_proj('robinson', 'lon', [0 360], 'lat', LAT_RANGE);
            m_contourf(LonGrid, LatGrid, Z_plot, 100, 'LineStyle', 'none');
            hold on;
            m_coast('patch', [0.92 0.92 0.92], 'edgecolor', 'none');
            m_grid('tickdir', 'out', 'linestyle', 'none', 'linewidth', LINE_WIDTH, ...
                'fontsize', MAIN_FONT_SIZE, 'fontname', 'Arial', ...
                'YTick', -45:15:45, 'XTick', 0:60:360);
            set(findobj(gca, 'Type', 'line'), 'LineWidth', LINE_WIDTH);
            set(gca, 'LineWidth', LINE_WIDTH, 'FontSize', MAIN_FONT_SIZE);
            colormap(gca, cmap);
            clim(c_lim);
            add_map_title(gca, sprintf('%s %s L%d', ...
                DISPLAY_EVENT_TYPES.(event_type), metric, level_id), TITLE_FONT_SIZE);
        end

        cb = colorbar('southoutside');
        cb.Label.String = c_label;
        cb.Ticks = c_ticks;
        cb.TickLabels = c_tick_labels;
        cb.TickDirection = 'out';
        cb.LineWidth = LINE_WIDTH;
        cb.FontSize = MAIN_FONT_SIZE;
        cb.Position = [0.24, 0.070, 0.52, 0.020];

        set(fig, 'InvertHardcopy', 'off');
        fig00b_out = fullfile(out_dir, sprintf('Fig00b_%s_Spatial_Distribution_%s', event_type, metric));
        fprintf('Saving: %s.tif\n', fig00b_out);
        exportgraphics(fig, [fig00b_out, '.tif'], 'Resolution', TIFF_DPI);
    end
end

fprintf('Done.\n');

%% ================== Local functions ==================
function T = load_basic_table(mat_file, event_type)
    assert(exist(mat_file, 'file') == 2, 'Missing file: %s', mat_file);
    S = load(mat_file);
    table_name = sprintf('%s_Basic_Table', event_type);
    assert(isfield(S, table_name), 'Variable %s not found in %s', table_name, mat_file);
    T = S.(table_name);
    if ~ismember('Event_ID', T.Properties.VariableNames)
        T.Event_ID = compose('%s_%d', event_type, (1:height(T))');
    end
end

function grp = group_by_count(values, pcts)
    values = double(values(:));
    n = numel(values);
    grp = ones(n, 1);
    [sorted_values, sort_idx] = sort(values, 'ascend');
    target_counts = round(n * pcts / 100);
    target_counts(1) = 1;
    n_groups = numel(pcts) - 1;
    current_group = 1;
    for i = 1:n
        if current_group < n_groups && i > target_counts(current_group + 1) ...
                && i > 1 && sorted_values(i) > sorted_values(i - 1)
            current_group = current_group + 1;
        end
        grp(sort_idx(i)) = current_group;
    end
end

function print_level_summary(Tables, eventTypes, metrics, levelIds, levelLabels)
    summary_rows = {};
    for iEvent = 1:numel(eventTypes)
        event_type = eventTypes{iEvent};
        T = Tables.(event_type);
        for iMetric = 1:numel(metrics)
            metric = metrics{iMetric};
            if strcmp(metric, 'Area')
                values = double(T.Max_Area);
                group_col = 'Area_Group';
            elseif strcmp(metric, 'Duration')
                values = double(T.Duration);
                group_col = 'Duration_Group';
            else
                values = abs(double(T.(sprintf('%s_Global_Mean', event_type))));
                group_col = 'Intensity_Group';
            end
            for level_id = levelIds
                mask = T.(group_col) == level_id;
                summary_rows(end + 1, :) = {event_type, metric, sprintf('L%d', level_id), ...
                    levelLabels{level_id}, sum(mask), min(values(mask)), max(values(mask))}; %#ok<AGROW>
            end
        end
    end
    Level_Summary = cell2table(summary_rows, ...
        'VariableNames', {'event', 'metric', 'level', 'percent_range', 'n_events', 'min', 'max'});
    disp(Level_Summary);
end

function [count_data, row_labels] = build_level_count_data(Tables, eventTypes, metrics, levelIds, displayEventTypes)
    n_rows = numel(eventTypes) * numel(metrics);
    count_data = zeros(n_rows, numel(levelIds));
    row_labels = cell(n_rows, 1);
    iRow = 0;
    for iEvent = 1:numel(eventTypes)
        event_type = eventTypes{iEvent};
        T = Tables.(event_type);
        for iMetric = 1:numel(metrics)
            metric = metrics{iMetric};
            iRow = iRow + 1;
            group_col = sprintf('%s_Group', metric);
            if isscalar(metrics)
                row_labels{iRow} = displayEventTypes.(event_type);
            else
                row_labels{iRow} = sprintf('%s %s', displayEventTypes.(event_type), metric);
            end
            for iLevel = 1:numel(levelIds)
                count_data(iRow, iLevel) = sum(T.(group_col) == levelIds(iLevel));
            end
        end
    end
end

function add_map_title(ax, titleText, titleFontSize)
    title(ax, '');
    text(ax, 0.5, 1.08, titleText, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontName', 'Arial', ...
        'FontSize', titleFontSize, ...
        'FontWeight', 'normal', ...
        'Clipping', 'off');
end

function GridEvent = accumulate_event_grids(stat_file, T, event_type, GridEvent, nx, ny)
    assert(exist(stat_file, 'file') == 2, 'Missing file: %s', stat_file);
    S = load(stat_file);
    cluster_name = sprintf('%s_Clusters', event_type);
    assert(isfield(S, cluster_name), 'Variable %s not found in %s', cluster_name, stat_file);
    Clusters = S.(cluster_name);
    cluster_fields = fieldnames(Clusters);

    group_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i = 1:height(T)
        group_map(char(string(T.Event_ID(i)))) = [T.Area_Group(i), T.Duration_Group(i), T.Intensity_Group(i)];
    end

    for iField = 1:numel(cluster_fields)
        event_id = cluster_fields{iField};
        if ~isKey(group_map, event_id), continue; end
        raw = double(Clusters.(event_id));
        if isempty(raw), continue; end
        if size(raw, 2) >= 4
            x = round(raw(:, 1));
            y = round(raw(:, 2));
            val = raw(:, 4);
        elseif size(raw, 1) >= 4
            x = round(raw(1, :)');
            y = round(raw(2, :)');
            val = raw(4, :)';
        else
            error('Unexpected cluster array size: %s', mat2str(size(raw)));
        end

        valid = x >= 1 & x <= nx & y >= 1 & y <= ny & isfinite(val);
        if ~any(valid), continue; end
        idx = sub2ind([nx, ny], x(valid), y(valid));
        val = single(val(valid));
        groups = group_map(event_id);

        g = groups(1);
        GridEvent.Area(g).SumInt(idx) = GridEvent.Area(g).SumInt(idx) + val;
        GridEvent.Area(g).Count(idx) = GridEvent.Area(g).Count(idx) + 1;

        g = groups(2);
        GridEvent.Duration(g).Count(idx) = GridEvent.Duration(g).Count(idx) + 1;

        g = groups(3);
        GridEvent.Intensity(g).SumInt(idx) = GridEvent.Intensity(g).SumInt(idx) + val;
        GridEvent.Intensity(g).Count(idx) = GridEvent.Intensity(g).Count(idx) + 1;
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
