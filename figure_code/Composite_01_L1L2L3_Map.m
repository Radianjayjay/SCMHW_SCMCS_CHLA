%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Composite 01：分级数量柱状图 + L1-L3 空间分布拼图
%%% 项目：MHW_MCS_CHLA
%%% 代码目录：figure_code
%%% 输入：05_Characteristic/Out/Characteristic_*_Basin_Eps5_MinPts200.mat
%%%         figure_code/Cache/Plot_00_Spatial_Distribution_plot_data.mat
%%% 输出：figure_code/Cache/Composite_01_*_plot_data.mat
%%%         figure_code/Out/Composite_01_Area.tif
%%%         figure_code/Out/Composite_01_Duration.tif
%%%         figure_code/Out/Composite_01_Mean_intensity.tif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. 路径和绘图风格 ==================
this_file = mfilename('fullpath');
plot_dir = fileparts(this_file);
base_dir = fileparts(plot_dir);

char_dir = fullfile(base_dir, '05_Characteristic', 'Out');
cache_dir = fullfile(plot_dir, 'Cache');
out_dir  = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% 外部绘图工具路径：nclCM 负责配色，m_map 负责地图投影。
% 外部绘图工具必须由用户预先加入 MATLAB path。
assert(exist('m_proj', 'file') == 2, 'm_map is required: m_proj was not found on the MATLAB path.');
assert(exist('nclCM', 'file') == 2, 'nclCM is required: nclCM was not found on the MATLAB path.');

% 全局绘图风格。这里会影响本脚本后面创建的所有 axes/text。
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

% 三张 Composite 01 图共用的尺寸和样式参数。
% 图尺寸单位是厘米；后面 axes 的 Position 都是归一化坐标：
% [left bottom width height]，四个数都在 0-1 之间。
FULL_WIDTH_CM = 17;
FIG_HEIGHT_CM = 20;
TIFF_DPI = 900;
LINE_WIDTH = 0.5;
MAP_LINE_WIDTH = 0.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
PANEL_FONT_SIZE = 8;
GRID_RES = 0.5;
LAT_RANGE = [-45, 45];
% 地图显示插值倍数：1=不插值；2/3/4 会让地图显示更平滑，但不会改变缓存数据。
MAP_INTERP_FACTOR = 2;

EVENT_TYPES = {'MHW', 'MCS'};
LEVEL_IDS = 1:3;
LEVEL_LABELS = {'L1 (0-25%)', 'L2 (25-75%)', 'L3 (75-100%)'};
LEVEL_SHORT_LABELS = {'L1', 'L2', 'L3'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';

% L1-L3 的颜色，同时也用于最上方的堆叠柱状图。
LEVEL_COLORS = [254 229 217
                252 146 114
                203 024 029] / 255;

% 三个指标共用同一套绘图函数，只通过 METRICS 切换数据字段、标题和输出名。
METRICS = struct( ...
    'id', {'Area', 'Duration', 'Mean_intensity'}, ...
    'sourceGrid', {'Area', 'Duration', 'Intensity'}, ...
    'groupField', {'Area_Group', 'Duration_Group', 'Intensity_Group'}, ...
    'valueField', {'Max_Area', 'Duration', ''}, ...
    'title', {'Area grouping', 'Duration grouping', 'Mean intensity grouping'}, ...
    'mapTitle', {'Area', 'Duration', 'Mean intensity'}, ...
    'outName', {'Composite_01_Area', 'Composite_01_Duration', 'Composite_01_Mean_intensity'});

CACHE_VERSION = 2;

%% ================== 2. 构建共享事件表 ==================
char_file_mhw = fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat');
char_file_mcs = fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat');
spatial_cache_file = fullfile(cache_dir, 'Plot_00_Spatial_Distribution_plot_data.mat');
input_files = {char_file_mhw, char_file_mcs, spatial_cache_file};

assert(exist(spatial_cache_file, 'file') == 2, ...
    'Missing spatial cache. Run Plot_00_MHW_MCS_Spatial_Distribution.m first: %s', spatial_cache_file);

% 读取 MHW/MCS 事件基础表，并为 Area/Duration/Intensity 分别生成 L1-L3 分组。
Tables.MHW = load_basic_table(char_file_mhw, 'MHW');
Tables.MCS = load_basic_table(char_file_mcs, 'MCS');
for iEvent = 1:numel(EVENT_TYPES)
    event_type = EVENT_TYPES{iEvent};
    int_col = sprintf('%s_Global_Mean', event_type);
    % group_by_count 按事件数量分位数分组，尽量得到 L1/L2/L3 约 25/50/25 的数量。
    Tables.(event_type).Area_Group = group_by_count(Tables.(event_type).Max_Area, [0 25 75 100]);
    Tables.(event_type).Duration_Group = group_by_count(Tables.(event_type).Duration, [0 25 75 100]);
    Tables.(event_type).Intensity_Group = group_by_count(abs(Tables.(event_type).(int_col)), [0 25 75 100]);
end

%% ================== 3. 构建/读取缓存并绘制拼图 ==================
for iMetric = 1:numel(METRICS)
    metric = METRICS(iMetric);
    % 缓存配置写进 mat 文件；只要布局/计算逻辑变化，就应同步更新这些 id 或 CACHE_VERSION。
    cache_config = struct( ...
        'grid_res', GRID_RES, ...
        'lat_range', LAT_RANGE, ...
        'metric', metric.id, ...
        'source_grid', metric.sourceGrid, ...
        'level_ids', LEVEL_IDS, ...
        'level_colors', LEVEL_COLORS, ...
        'group_pcts', [0 25 75 100], ...
        'layout_id', 'top_bar_bottom_two_map_columns_v2', ...
        'calculation_id', 'Composite00_metric_v2');
    composite_cache_file = fullfile(cache_dir, sprintf('Composite_01_%s_plot_data.mat', metric.id));

    % 如果缓存版本、配置和输入文件时间都匹配，就直接复用缓存；否则重新打包拼图数据。
    if is_plot_cache_current(composite_cache_file, input_files, CACHE_VERSION, cache_config)
        fprintf('Loading cached Composite 01 %s data: %s\n', metric.id, composite_cache_file);
        C = load(composite_cache_file, 'Composite');
        Composite = C.Composite;
        % 颜色属于绘图样式，加载旧缓存后也强制同步为当前脚本中的配色。
        Composite.LevelColors = LEVEL_COLORS;
    else
        fprintf('Building Composite 01 %s cache...\n', metric.id);
        S = load(spatial_cache_file, 'Grids');
        Composite = build_composite_metric(Tables, S.Grids, metric, EVENT_TYPES, ...
            LEVEL_IDS, LEVEL_LABELS, LEVEL_SHORT_LABELS, LEVEL_COLORS, DISPLAY_EVENT_TYPES, ...
            GRID_RES, LAT_RANGE, spatial_cache_file, char_file_mhw, char_file_mcs);
        cache_version = CACHE_VERSION;
        save(composite_cache_file, 'Composite', 'cache_version', 'cache_config', '-v7.3');
        fprintf('Saved cached Composite 00 %s data: %s\n', metric.id, composite_cache_file);
    end

    draw_composite_metric(Composite, fullfile(out_dir, metric.outName), FULL_WIDTH_CM, ...
        FIG_HEIGHT_CM, TIFF_DPI, LINE_WIDTH, MAP_LINE_WIDTH, ...
        MAIN_FONT_SIZE, TITLE_FONT_SIZE, PANEL_FONT_SIZE, MAP_INTERP_FACTOR);
end

fprintf('Done.\n');

%% ================== 本脚本局部函数 ==================
function T = load_basic_table(mat_file, event_type)
    % 从 Characteristic_*.mat 中读取事件基础表；旧数据没有 Event_ID 时现场补一个。
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
    % 按排序后的事件个数分组。遇到相同取值时尽量不在相同值中间硬切分。
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

function Composite = build_composite_metric(Tables, Grids, metric, eventTypes, levelIds, ...
        levelLabels, levelShortLabels, levelColors, displayEventTypes, gridRes, latRange, ...
        spatialCacheFile, charFileMhw, charFileMcs)
    % Composite 结构体是后续重绘拼图所需的全部缓存数据。
    [level_count_data, level_count_labels] = build_level_count_data( ...
        Tables, eventTypes, metric.groupField, levelIds, displayEventTypes);

    Composite = struct();
    Composite.Metric = metric;
    Composite.LevelCountData = level_count_data;
    Composite.LevelCountLabels = level_count_labels;
    Composite.LevelLabels = levelLabels;
    Composite.LevelShortLabels = levelShortLabels;
    Composite.LevelColors = levelColors;
    Composite.DisplayEventTypes = displayEventTypes;
    Composite.GridRes = gridRes;
    Composite.LatRange = latRange;
    for iEvent = 1:numel(eventTypes)
        event_type = eventTypes{iEvent};
        % 地图数据直接复用 Plot_00 的网格缓存，按当前 metric 取 Area/Duration/Intensity。
        Composite.GridMetric.(event_type) = Grids.(event_type).(metric.sourceGrid);
    end
    Composite.CacheSource = struct( ...
        'spatial_cache_file', spatialCacheFile, ...
        'char_file_mhw', charFileMhw, ...
        'char_file_mcs', charFileMcs);
end

function [count_data, row_labels] = build_level_count_data(Tables, eventTypes, groupField, levelIds, displayEventTypes)
    % 统计 MHW/MCS 在 L1-L3 中的事件数量，用于顶部堆叠柱状图。
    count_data = zeros(numel(eventTypes), numel(levelIds));
    row_labels = cell(numel(eventTypes), 1);
    for iEvent = 1:numel(eventTypes)
        event_type = eventTypes{iEvent};
        T = Tables.(event_type);
        row_labels{iEvent} = displayEventTypes.(event_type);
        for iLevel = 1:numel(levelIds)
            count_data(iEvent, iLevel) = sum(T.(groupField) == levelIds(iLevel));
        end
    end
end

function draw_composite_metric(Composite, figOut, fullWidthCm, figHeightCm, tiffDpi, ...
        lineWidth, mapLineWidth, mainFontSize, titleFontSize, panelFontSize, mapInterpFactor)
    fprintf('Plotting %s...\n', Composite.Metric.id);
    % 新建整张拼图画布；后续所有子图都通过归一化 Position 手动摆放。
    fig = figure('Units', 'centimeters', ...
        'Position', [2 2 fullWidthCm figHeightCm], 'Color', 'w');

    draw_count_bar(fig, Composite, lineWidth, mainFontSize, titleFontSize, panelFontSize);

    vec_lon = 0.5:Composite.GridRes:360;
    vec_lat = Composite.LatRange(1):Composite.GridRes:Composite.LatRange(2);
    [LonGrid, LatGrid] = meshgrid(vec_lon, vec_lat);

    % 地图布局调参入口，全部是归一化坐标。
    % map_x：MHW/MCS 两列地图的左边界。
    % map_y：L1/L2/L3 三行地图的底边位置；某一行数值变大，该行就上移。
    %       想缩小两行之间的红框间隙，就把相邻两个 map_y 的差值调小。
    % map_w/map_h：地图 axes 的宽和高。map_h 变大会拉高 axes，但 Robinson
    %       投影内部仍会保留自身比例，所以通常要和 map_y、colorbar 位置一起微调。
    map_x = [0.06, 0.52];
    map_y = [0.580, 0.440, 0.302];
    map_w = 0.44;
    map_h = 0.3;

    % 左右两列都删除 m_map 自带纬度文字，随后用独立透明坐标轴在两列中间画共享纬度刻度。
    % shared_lat_pos = [left width]，控制中间纬度刻度列的水平位置和宽度。
    shared_lat_pos = [map_x(1) + map_w + 0.015, map_x(2) - (map_x(1) + map_w) - 0.030];
    draw_map_column(fig, Composite, 'MHW', map_x(1), map_y, map_w, map_h, ...
        LonGrid, LatGrid, mapLineWidth, mainFontSize, titleFontSize, mapInterpFactor);
    draw_map_column(fig, Composite, 'MCS', map_x(2), map_y, map_w, map_h, ...
        LonGrid, LatGrid, mapLineWidth, mainFontSize, titleFontSize, mapInterpFactor);
%     add_shared_latitude_axes(fig, shared_lat_pos, map_y, mainFontSize);

    % b-g 分别标注六张地图；放在每个地图标题左侧。
    % 如果标记离标题太近/太远，主要调 map_label_x_offset 和 map_label_y_offset。
    map_label_x_offset = 0.015;
    map_label_y_offset = 0.198;
    map_labels = {'(b)', '(c)'; '(d)', '(e)'; '(f)', '(g)'};
    for iLevel = 1:numel(Composite.LevelLabels)
        add_panel_label(fig, [map_x(1) + map_label_x_offset, map_y(iLevel) + map_label_y_offset, 0.030, 0.030], ...
            map_labels{iLevel, 1}, panelFontSize);
        add_panel_label(fig, [map_x(2) + map_label_x_offset, map_y(iLevel) + map_label_y_offset, 0.030, 0.030], ...
            map_labels{iLevel, 2}, panelFontSize);
    end

    set(fig, 'InvertHardcopy', 'off');
    fprintf('Saving: %s.tif and .png\n', figOut);
    export_composite_figure(fig, figOut, tiffDpi);
    close(fig);
end

function export_composite_figure(fig, figOut, tiffDpi)
    % 输出同分辨率 TIF 和 PNG（exportgraphics 自动紧贴内容裁切，无多余白边）
    exportgraphics(fig, [figOut, '.tif'], 'Resolution', tiffDpi, 'BackgroundColor', 'white');
    exportgraphics(fig, [figOut, '.png'], 'Resolution', tiffDpi, 'BackgroundColor', 'white');
end

function draw_count_bar(fig, Composite, lineWidth, mainFontSize, titleFontSize, panelFontSize)
    % 顶部柱状图位置：[left bottom width height]。
    % 第二个数控制上下位置，第四个数控制柱状图区域高度。
    % 这里的 left/width 和下面两列地图整体宽度对齐：0.06 到 0.94。
    ax_bar = axes(fig, 'Position', [0.080 0.805 0.840 0.115]);
    hide_axes_toolbar(ax_bar);
    % bar_y 控制 SCMHW/SCMCS 两根柱子的中心位置；步长越小，两根柱子越近。
    % barh 的第 4 个参数 0.50 控制每根横向柱子的厚度。
    bar_y = 1 + (0:numel(Composite.LevelCountLabels)-1) * 0.20;
    bar_handles = barh(ax_bar, bar_y, Composite.LevelCountData, 0.60, 'stacked', ...
        'EdgeColor', 'none', 'LineWidth', lineWidth);
    for iLevel = 1:numel(bar_handles)
        bar_handles(iLevel).FaceColor = Composite.LevelColors(iLevel, :);
    end
    hold(ax_bar, 'on');

    max_total = max(sum(Composite.LevelCountData, 2));
    % 在每个堆叠色块中心写入 L1=xxxx 这样的数量标签；太窄的色块不写，避免重叠。
    for iRow = 1:size(Composite.LevelCountData, 1)
        x_left = 0;
        for iLevel = 1:size(Composite.LevelCountData, 2)
            count_value = Composite.LevelCountData(iRow, iLevel);
            if count_value > 0
                x_mid = x_left + count_value / 2;
                if count_value >= max_total * 0.055
                    formatted_value = char(java.text.DecimalFormat('#,###').format(count_value));
                    label_color = [0 0 0];
                    if iLevel == 3, label_color = [1 1 1]; end
                    text(ax_bar, x_mid, bar_y(iRow), ...
                        sprintf('%s = %s', Composite.LevelShortLabels{iLevel}, formatted_value), ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'FontSize', 8, ...
                        'FontName', 'Arial', ...
                        'FontWeight', 'normal', ...
                        'Color', label_color);
                end
            end
            x_left = x_left + count_value;
        end
        % 左侧 SCMHW/SCMCS 行标签已删除，这里改为贴着每根柱子的右侧标注。
        text(ax_bar, x_left + max_total * 0.015, bar_y(iRow), ...
            Composite.LevelCountLabels{iRow}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', mainFontSize+1, ...
            'FontName', 'Arial', ...
            'FontWeight', 'normal', ...
            'Color', [0 0 0]);
    end

    set(ax_bar, 'Box', 'off', 'TickDir', 'out', ...
        'YTick', [], ...
        'YTickLabel', {}, ...
        'XTick', [], ...
        'XTickLabel', {}, ...
        'XAxisLocation', 'origin', ...
        'XColor', 'none', ...
        'YDir', 'reverse', ...
        ... % YLim 控制外框离两根柱子的上下距离。
        'YLim', [bar_y(1) - 0.14, bar_y(end) + 0.14], ...
        'XLim', [0 max_total * 1.12], ...
        'XGrid', 'off', 'YGrid', 'off', ...
        'GridAlpha', 0.18, ...
        'LineWidth', lineWidth, ...
        'FontSize', mainFontSize+1, ...
        'FontName', 'Arial', ...
        'FontWeight', 'normal');
    draw_tight_bar_box(ax_bar, lineWidth);
    xlabel(ax_bar, '');
    hTitle = title(ax_bar, Composite.Metric.title, ...
        'FontWeight', 'normal', 'FontSize', titleFontSize, 'Color', [0 0 0]);
    hTitle.Units = 'normalized';
    hTitle.Position(2) = 0.87;
    add_panel_label(fig, [0.075 0.895 0.030 0.030], '(a)', panelFontSize);
end

function draw_map_column(~, Composite, event_type, x0, y_positions, ax_w, ax_h, ...
        LonGrid, LatGrid, lineWidth, mainFontSize, titleFontSize, mapInterpFactor)
    % 根据当前指标和事件类型返回地图色标范围、刻度、标签和 colormap。
    [c_lim, c_ticks, c_tick_labels, c_label, cmap] = metric_color_settings(Composite.Metric.sourceGrid, event_type);

    for iLevel = 1:numel(Composite.LevelLabels)
        % 每个 L 等级画一张地图，位置由 draw_composite_metric 中的 map_y 控制。
        ax = axes('Position', [x0, y_positions(iLevel), ax_w, ax_h]);
        hide_axes_toolbar(ax);
        G = Composite.GridMetric.(event_type)(iLevel);
        if strcmp(Composite.Metric.sourceGrid, 'Duration')
            % Duration 用总天数 Count；Area/Intensity 用 SumInt/Count 得到平均强度。
            Z = double(G.Count);
        else
            Z = double(G.SumInt) ./ double(G.Count);
            Z(G.Count == 0) = NaN;
        end
        % 无事件网格（Count=0）视为无数据，单独记录成掩膜，绘图时留白。
        % 否则它会被画成 0，和"强度/天数接近 0"的真实取值混为一谈。
        valid = double(G.Count) > 0;
        % m_map 绘图时经纬度矩阵方向和缓存矩阵方向不同，这里转置一次。
        % 插值前先把无数据格临时填 0，避免 NaN 在插值时扩散到相邻有数据格。
        Z_plot = Z';
        Z_plot(isnan(Z_plot)) = 0;
        valid_plot = valid';
        [LonDraw, LatDraw, Z_draw] = interpolate_map_for_display(LonGrid, LatGrid, Z_plot, mapInterpFactor);
        % 插值后再按最近邻把无数据格还原成 NaN，交给 m_contourf 留白。
        % 掩膜必须放在插值之后：放前面会被 interp2 抹开，放这里才能保持网格块的边界。
        valid_draw = interp2(LonGrid, LatGrid, double(valid_plot), LonDraw, LatDraw, 'nearest');
        Z_draw(valid_draw < 0.5) = NaN;

        % Robinson 投影地图。经度 0-360，纬度范围由 LAT_RANGE 控制。
        m_proj('robinson', 'lon', [0 360], 'lat', Composite.LatRange);
        m_contourf(LonDraw, LatDraw, Z_draw, 200, 'LineStyle', 'none');
        hold(ax, 'on');
        m_coast('patch', [0.92 0.92 0.92], 'edgecolor', 'none');
        % YTick 控制纬度刻度；tickstyle='dd' 使用十进制度数，
        % 这样 22.5 会显示为 22.5，而不是 22 度 30 分。
        m_grid('tickdir', 'out', 'linestyle', 'none', 'linewidth', lineWidth, ...
            'fontsize', mainFontSize-1, 'fontname', 'Arial', ...
            'YTick', [-45, -20, 0, 20, 45], ...
            'tickstyle', 'dd', ...
            'XTick', 0:60:360);
        set(findobj(gca, 'Type', 'line'), 'LineWidth', lineWidth);
        set(gca, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'FontWeight', 'normal');
        colormap(gca, cmap);
        clim(c_lim);
        add_map_title(gca, sprintf('%s %s L%d', ...
            Composite.DisplayEventTypes.(event_type), Composite.Metric.mapTitle, iLevel), titleFontSize);
        if ~strcmp(event_type, 'MHW')
            suppress_m_grid_latitude_labels(gca);
        end
        if iLevel < numel(Composite.LevelLabels)
            % 前两行 b/c/d/e 删除经度刻度文字，只保留底行 f/g 的经度刻度。
            suppress_m_grid_longitude_labels(gca);
        end
        set(findall(gca, 'Type', 'Text'), 'FontWeight', 'normal');
    end

    cb = colorbar('southoutside');

    cb.Color = [0 0 0];

    cb.Label.Color = [0 0 0];
    cb.Label.String = c_label;
    cb.Label.FontWeight = 'normal';
    cb.Ticks = c_ticks;
    cb.TickLabels = c_tick_labels;
    cb.TickDirection = 'out';
    cb.LineWidth = lineWidth;
    cb.FontSize = mainFontSize;
    cb.FontWeight = 'normal';
    % colorbar 位置：[left bottom width height]。
    % 第二个数变大，colorbar 上移，和 L3 地图之间的间隙会变小。
    cb.Position = [x0+0.02, 0.363, ax_w-0.04, 0.012];
end

function draw_tight_bar_box(ax, lineWidth)
    % 只保留子图(a)左侧边框；上/下/右边框不画。
    xl = xlim(ax);
    yl = ylim(ax);
    line(ax, [xl(1), xl(1)], ...
        [yl(1), yl(2)], ...
        'Color', 'k', 'LineWidth', lineWidth, 'Clipping', 'off');
end

function [c_lim, c_ticks, c_tick_labels, c_label, cmap] = metric_color_settings(metric, event_type)
    if strcmp(metric, 'Duration')
        % Duration 地图色标范围。当前 [0,30] 和 0:6:30 对应 0,6,12,18,24,30。
        c_lim = [0, 30];
        c_ticks = 0:6:30;
        c_tick_labels = compose('%.0f', c_ticks);
        c_label = 'Total days';
        % 从 nclCM(446) 采样 10 色，浅粉到暗红。
        cmap = nclCM(446, 10);
    elseif strcmp(event_type, 'MHW')
        % MHW 强度为正值，使用暖色系，从 nclCM(187) 采样 10 色。
        c_lim = [0, 3];
        c_ticks = 0:0.6:3;
        c_tick_labels = {'0', '0.6', '1.2', '1.8', '2.4', '3.0'};
        c_label = 'Mean Intensity (°C)';
        cmap = nclCM(187, 10);
    else
        % MCS 强度为负值，使用冷色系，从 nclCM(162) 采样 10 色并翻转，让颜色方向更直观。
        c_lim = [-3, 0];
        c_ticks = -3:0.6:0;
        c_tick_labels = {'-3.0', '-2.4', '-1.8', '-1.2', '-0.6', '0'};
        c_label = 'Mean Intensity (°C)';
        cmap = flipud(nclCM(162, 10));
    end
end

function add_map_title(ax, titleText, titleFontSize)
    % m_map 的默认 title 位置不好统一，所以用 normalized text 手动放标题。
    title(ax, '', 'Color', [0 0 0]);
    text(ax, 0.5, 1.02, titleText, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontName', 'Arial', ...
        'FontSize', titleFontSize, ...
        'FontWeight', 'normal', ...
        'Clipping', 'off');
end

function suppress_m_grid_latitude_labels(ax)
    % 右列地图删除纬度文字，让每行左右两张地图共用中间这一套纬度标签。
    delete(findall(ax, 'Tag', 'm_grid_yticklabel'));
end

function suppress_m_grid_longitude_labels(ax)
    % 前两行地图删除 m_map 生成的经度文字；底行保留，减少行间空白。
    delete(findall(ax, 'Tag', 'm_grid_xticklabel'));
end

function [LonDraw, LatDraw, ZDraw] = interpolate_map_for_display(LonGrid, LatGrid, ZPlot, interpFactor)
    % 仅用于显示层面的插值平滑。interpFactor=1 时完全使用原始网格；
    % interpFactor 越大越平滑，但也会越慢，通常 2-4 就够了。
    if interpFactor <= 1
        LonDraw = LonGrid;
        LatDraw = LatGrid;
        ZDraw = ZPlot;
        return
    end

    lon_fine = linspace(min(LonGrid(:)), max(LonGrid(:)), size(LonGrid, 2) * interpFactor);
    lat_fine = linspace(min(LatGrid(:)), max(LatGrid(:)), size(LatGrid, 1) * interpFactor);
    [LonDraw, LatDraw] = meshgrid(lon_fine, lat_fine);
    ZDraw = interp2(LonGrid, LatGrid, ZPlot, LonDraw, LatDraw, 'linear');
end

function add_shared_latitude_axes(fig, sharedLatPos, mapY, mainFontSize)
    % 在两列地图中间添加共享纬度刻度列。
    % lat_axis_y_offset/lat_axis_h 控制纬度刻度列和每一行地图的垂直对齐。
    lat_axis_y_offset = 0.095;
    lat_axis_h = 0.105;
    lat_values = [-45, 0, 45];
    lat_labels = {'45°S', '0°', '45°N'};
    for iRow = 1:numel(mapY)
        ax_lat = axes(fig, 'Position', [sharedLatPos(1), mapY(iRow) + lat_axis_y_offset, sharedLatPos(2), lat_axis_h]);
        set(ax_lat, 'Color', 'none', 'XLim', [0 1], 'YLim', [-45 45], 'Visible', 'off');
        for iLat = 1:numel(lat_values)
            text(ax_lat, 0.5, lat_values(iLat), lat_labels{iLat}, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontName', 'Arial', ...
                'FontSize', mainFontSize, ...
                'FontWeight', 'normal');
        end
    end
end

function add_panel_label(fig, pos, labelText, fontSize)
    % 添加 a/b/c 面板编号；pos 同样是归一化 [left bottom width height]。
    annotation(fig, 'textbox', pos, ...
        'String', labelText, ...
        'LineStyle', 'none', ...
        'FontName', 'Arial', ...
        'FontSize', fontSize, ...
        'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', 'Color', [0 0 0]);
end

function hide_axes_toolbar(ax)
    % 导出图片前关闭 MATLAB 坐标轴工具栏，避免工具栏图标进入高分辨率输出。
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
    % 判断拼图缓存是否可复用：版本一致、配置一致、且所有输入文件都没有更新。
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
