%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Composite 02 CHLA response: response curves plus peak-location maps by grouping
%%% Project: MHW_MCS_CHLA
%%% Code:   figure_code
%%% Inputs: figure_code/Cache/Plot_03_*_by_*_plot_data.mat
%%%         figure_code/Cache/Plot_05_*_by_*_plot_data.mat
%%% Output: figure_code/Cache/Composite_0*_..._plot_data.mat
%%%         figure_code/Out/Composite_02_CHLA_Response_*_MHW_MCS_Response_*.tif
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
assert(exist('m_proj', 'file') == 2, 'm_map is required: m_proj was not found on the MATLAB path.');

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
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
ROW_FONT_SIZE = 7;
PANEL_FONT_SIZE = 8;
MARKER_SIZE = 4;
MARKER_ALPHA = 0.45;
LAT_RANGE = [-45, 45];
CACHE_VERSION = 1;

EVENT_TYPES = {'MHW', 'MCS'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';
GROUP_LABELS = {'L1 (0-25%)', 'L2 (25-75%)', 'L3 (75-100%)'};
GROUP_COLORS.MHW = [250 128 114
                    147 127 179
                    165 0 38] / 255;
GROUP_COLORS.MCS = [169 203 140
                    091 189 160
                    000 141 170] / 255;

RESPONSES = struct( ...
    'id', {'CHLA', 'Micro', 'Nano', 'Pico'}, ...
    'label', {'CHLA', 'Micro', 'Nano', 'Pico'}, ...
    'ylabel', {'CHLA anomaly (mg/m^3)', 'Micro anomaly  (mg/m^3)', 'Nano anomaly  (mg/m^3)', 'Pico anomaly  (mg/m^3)'});

PARAMS = struct( ...
    'order', {1, 2, 3}, ...
    'sourceId', {'Duration', 'Max_Area', 'Mean_Intensity'}, ...
    'outId', {'Duration', 'Area', 'Mean_Intensity'}, ...
    'label', {'Duration', 'Area', 'Mean intensity'}, ...
    'absXLimit', {60, 30, 30}, ...
    'absXTick', {30, 15, 15});

% SCMHW 和 SCMCS 的响应强度可能不同，所以 y 轴范围按事件类型分别控制。
% 后续只需要改这里，不需要改绘图函数内部。
FIXED_RESPONSE_Y_LIMITS.MHW.CHLA  = [-2.5e-2, 1.0e-2];
FIXED_RESPONSE_Y_LIMITS.MHW.Micro = [-1.5e-2, 0.5e-2];
FIXED_RESPONSE_Y_LIMITS.MHW.Nano  = [-1.0e-2, 0.5e-2];
FIXED_RESPONSE_Y_LIMITS.MHW.Pico  = [-0.5e-2, 0.25e-2];

FIXED_RESPONSE_Y_LIMITS.MCS.CHLA  = [-1.0e-2, 2.5e-2];
FIXED_RESPONSE_Y_LIMITS.MCS.Micro = [-0.5e-2, 1.5e-2];
FIXED_RESPONSE_Y_LIMITS.MCS.Nano  = [-0.5e-2, 1.0e-2];
FIXED_RESPONSE_Y_LIMITS.MCS.Pico  = [-0.25e-2, 0.5e-2];

% 线图 y 轴刻度间隔，按 SCMHW/SCMCS 和 CHLA/Micro/Nano/Pico 分开控制。
% 数值越小刻度越密，数值越大刻度越疏。
FIXED_RESPONSE_Y_TICKS.MHW.CHLA  = 1.0e-2;
FIXED_RESPONSE_Y_TICKS.MHW.Micro = 0.5e-2;
FIXED_RESPONSE_Y_TICKS.MHW.Nano  = 0.5e-2;
FIXED_RESPONSE_Y_TICKS.MHW.Pico  = 2.5e-3;

FIXED_RESPONSE_Y_TICKS.MCS.CHLA  = 1.0e-2;
FIXED_RESPONSE_Y_TICKS.MCS.Micro = 0.5e-2;
FIXED_RESPONSE_Y_TICKS.MCS.Nano  = 0.5e-2;
FIXED_RESPONSE_Y_TICKS.MCS.Pico  = 2.5e-3;

CACHE_CONFIG_BASE = struct( ...
    'responses', {RESPONSES}, ...
    'params', {PARAMS}, ...
    'lat_range', LAT_RANGE, ...
    'layout_id', 'two_event_rows_five_vertical_columns_v1', ...
    'calculation_id', 'Composite_response_location_grouping_v1');

%% ================== 2. Build caches ==================
Composites = struct();
for iParam = 1:numel(PARAMS)
    param = PARAMS(iParam);
    cache_file = fullfile(cache_dir, sprintf( ...
        'Composite_02_%s_CHLA_Response_plot_data.mat', ...
        param.outId));

    input_files = required_input_files(cache_dir, RESPONSES, param.sourceId);
    cache_config = CACHE_CONFIG_BASE;
    cache_config.param = param;

    if is_plot_cache_current(cache_file, input_files, CACHE_VERSION, cache_config)
        fprintf('Loading cached composite data: %s\n', cache_file);
        C = load(cache_file, 'Composite');
        Composite = C.Composite;
    else
        fprintf('Building composite cache for %s...\n', param.label);
        Composite = build_composite(cache_dir, RESPONSES, param, DISPLAY_EVENT_TYPES, GROUP_LABELS);
        cache_version = CACHE_VERSION;
        save(cache_file, 'Composite', 'cache_version', 'cache_config', '-v7.3');
        fprintf('Saved composite cache: %s\n', cache_file);
    end

    Composites.(param.outId) = Composite;
end

%% ================== 3. Draw MHW/MCS response-density composites ==================
for iParam = 1:numel(PARAMS)
    param = PARAMS(iParam);
    draw_dual_event_response_density_composite(Composites.(param.outId), cache_dir, ...
        param, 'absolute', fullfile(out_dir, sprintf( ...
        'Composite_02_CHLA_Response_%s_MHW_MCS_Response_Absolute', param.outId)), ...
        FULL_WIDTH_CM, FIG_HEIGHT_CM, TIFF_DPI, LINE_WIDTH, MAIN_FONT_SIZE, ...
        TITLE_FONT_SIZE, ROW_FONT_SIZE, PANEL_FONT_SIZE, GROUP_COLORS, ...
        DISPLAY_EVENT_TYPES, LAT_RANGE, FIXED_RESPONSE_Y_LIMITS, FIXED_RESPONSE_Y_TICKS);
    draw_dual_event_response_density_composite(Composites.(param.outId), cache_dir, ...
        param, 'normalized', fullfile(out_dir, sprintf( ...
        'Composite_02_CHLA_Response_%s_MHW_MCS_Response_Normalized', param.outId)), ...
        FULL_WIDTH_CM, FIG_HEIGHT_CM, TIFF_DPI, LINE_WIDTH, MAIN_FONT_SIZE, ...
        TITLE_FONT_SIZE, ROW_FONT_SIZE, PANEL_FONT_SIZE, GROUP_COLORS, ...
        DISPLAY_EVENT_TYPES, LAT_RANGE, FIXED_RESPONSE_Y_LIMITS, FIXED_RESPONSE_Y_TICKS);
end

fprintf('Done.\n');

%% ================== Local functions ==================
function input_files = required_input_files(cache_dir, responses, paramId)
    input_files = cell(1, numel(responses) + 2);
    for iResp = 1:numel(responses)
        input_files{iResp} = fullfile(cache_dir, sprintf( ...
            'Plot_03_%s_by_%s_plot_data.mat', responses(iResp).id, paramId));
    end
    input_files{numel(responses) + 1} = fullfile(cache_dir, sprintf( ...
        'Plot_05_MHW_by_%s_plot_data.mat', paramId));
    input_files{numel(responses) + 2} = fullfile(cache_dir, sprintf( ...
        'Plot_05_MCS_by_%s_plot_data.mat', paramId));
end

function Composite = build_composite(cache_dir, responses, param, displayEventTypes, groupLabels)
    Composite = struct();
    Composite.Param = param;
    Composite.Responses = responses;
    Composite.DisplayEventTypes = displayEventTypes;
    Composite.GroupLabels = groupLabels;

    for iResp = 1:numel(responses)
        response = responses(iResp);
        f = fullfile(cache_dir, sprintf('Plot_03_%s_by_%s_plot_data.mat', ...
            response.id, param.sourceId));
        assert(exist(f, 'file') == 2, 'Missing response cache: %s', f);
        S = load(f, 'Result', 'common_ylim');
        Composite.Response.(response.id).Result = S.Result;
        Composite.Response.(response.id).common_ylim = S.common_ylim;
    end

    for iEvent = 1:2
        event_type = {'MHW', 'MCS'};
        event_type = event_type{iEvent};
        f = fullfile(cache_dir, sprintf('Plot_05_%s_by_%s_plot_data.mat', ...
            event_type, param.sourceId));
        assert(exist(f, 'file') == 2, 'Missing map cache: %s', f);
        S = load(f, 'lon', 'lat', 'grp', 'color_value', 'current_group_labels');
        Composite.Map.(event_type).lon = S.lon;
        Composite.Map.(event_type).lat = S.lat;
        Composite.Map.(event_type).grp = S.grp;
        Composite.Map.(event_type).color_value = S.color_value;
        Composite.Map.(event_type).group_labels = S.current_group_labels;
    end
end

function draw_dual_event_response_density_composite(Composite, cacheDir, param, timeMode, figOut, ...
        fullWidthCm, figHeightCm, tiffDpi, lineWidth, mainFontSize, titleFontSize, ...
        ~, panelFontSize, groupColors, displayEventTypes, latRange, responseYLimits, responseYTicks)
    fprintf('Plotting: %s.tif\n', figOut);
    fig = figure('Units', 'centimeters', ...
        'Position', [1 1 fullWidthCm figHeightCm], 'Color', 'w');

    leftX = 0.055;
    leftW = 0.405;
    chlaH = 0.130;
    pscH = 0.130;
    eventTypes = {'MHW', 'MCS'};
    chlaYByEvent = [0.840, 0.470];
    pscYByEvent = [0.655, 0.285];
    legendYByEvent = [0.640, 0.275];
    % Micro/Nano/Pico 小图的专用横向布局。
    pscColGap = 0.045;
    pscW = (leftW - 2 * pscColGap) / 3;
    % Micro/Nano/Pico 小标题的水平位置。
    % y 轴科学计数法会出现在左上角，标题略向右移可避免遮挡；0.5 为居中，越大越靠右。
    pscTitleXNorm = 0.50;
    responseIds = {'Micro', 'Nano', 'Pico'};
    % 右侧三张 map 纵向排列；mapX/mapW 控制右列整体左右位置和宽度。
    mapX = 0.505;
    mapW = 0.420;
    mapAspectRatio = 3.539057;
    mapStackTop = 0.925;
    mapStackGap = 0.075;
    panelLabels = {'(a)', '(b)', '(c)', '(d)', '(e)', '(f)', '(g)', '(h)', '(i)', '(j)', '(k)'};
    legendH = 0.024;
    legendXOffset = -0.015;
    legendYOffset = -0.010;
    colorbarPos = [0, 0.388, 0, 0.012];
    % 不改变画布大小，只把图内元素以顶部对齐线为锚点做纵向压缩。
    verticalAnchorTop = 0.945;
    verticalScale = 0.88;
    [chlaYByEvent, chlaH] = compress_vertical_positions(chlaYByEvent, chlaH, verticalAnchorTop, verticalScale);
    [pscYByEvent, pscH] = compress_vertical_positions(pscYByEvent, pscH, verticalAnchorTop, verticalScale);

    % Right column layout: direct placement matching user alignment request
    mapH = chlaH;
    mapY = [chlaYByEvent(1), pscYByEvent(1), chlaYByEvent(2)];
    colorbarPos(2) = 0.4920;
    colorbarPos(4) = 0.012;
    legY = 0.3600;
    legH = 0.075;

    for iEvent = 1:numel(eventTypes)
        eventType = eventTypes{iEvent};
        chlaY = chlaYByEvent(iEvent);
        pscY = pscYByEvent(iEvent);
        eventLabelOffset = (iEvent - 1) * 4;

        add_vertical_figure_label(fig, [0.0025, chlaY, 0.012, chlaH], ...
            'CHLA anomaly  (mg/m^3)', mainFontSize);
        add_vertical_figure_label(fig, [0.0025, pscY, 0.012, pscH], ...
            'PSC anomaly  (mg/m^3)', mainFontSize);

        ax = axes(fig, 'Position', [leftX, chlaY, leftW, chlaH]);
        hide_axes_toolbar(ax);
        
        % 默认大图科学计数法位置，可通过修改 chlaExpX 单独调整 a 和 e 图
        if strcmp(eventType, 'MHW')
            chlaExpX = 0.010; % 图 (a) 科学计数法的左右位置
        else
            chlaExpX = 0.010; % 图 (e) 科学计数法的左右位置
        end
        
        draw_grouped_response_axis(ax, Composite, eventType, 'CHLA', timeMode, ...
            groupColors.(eventType), responseYLimits.(eventType).CHLA, ...
            responseYTicks.(eventType).CHLA, lineWidth, ...
            mainFontSize, titleFontSize, true, chlaExpX);
        tResp = title(ax, sprintf('%s CHLA by %s', displayEventTypes.(eventType), param.label), ...
            'FontWeight', 'normal', 'FontSize', titleFontSize, 'Color', [0 0 0]);
        tResp.Units = 'normalized';
        tResp.Position(2) = 1.015;   % 调这个值控制 CHLA 标题高度：>1 上移，<1 下移

        add_panel_label_inside(ax, panelLabels{eventLabelOffset + 1}, panelFontSize);

        for iResp = 1:numel(responseIds)
            responseId = responseIds{iResp};
            
            % 默认小图科学计数法位置
            pscExpX = 0.025;
            if strcmp(eventType, 'MHW') && strcmp(responseId, 'Nano')
                % 可通过修改这里，单独调整 MHW 中的 Nano 图 (c) 科学计数法的左右位置
                pscExpX = 0.025; 
            end
            
            pscX = leftX + (iResp - 1) * (pscW + pscColGap);
            ax = axes(fig, 'Position', [pscX, pscY, pscW, pscH]);
            hide_axes_toolbar(ax);
            draw_grouped_response_axis(ax, Composite, eventType, responseId, timeMode, ...
                groupColors.(eventType), responseYLimits.(eventType).(responseId), ...
                responseYTicks.(eventType).(responseId), lineWidth, ...
                mainFontSize, titleFontSize, true, pscExpX);
            tResp = title(ax, responseId, 'FontWeight', 'normal', 'FontSize', titleFontSize, 'Color', [0 0 0]);
            set_axis_title_x(tResp, pscTitleXNorm);
            labelIdx = eventLabelOffset + 1 + iResp;
            add_panel_label_inside(ax, panelLabels{labelIdx}, panelFontSize);
        end
    end

    density = combine_plot08_density( ...
        load_plot08_density(cacheDir, 'MHW', param.sourceId), ...
        load_plot08_density(cacheDir, 'MCS', param.sourceId));
    for g = 1:3
        ax = axes(fig, 'Position', [mapX, mapY(g), mapW, mapH]);
        hide_axes_toolbar(ax);
        draw_density_map_axis(fig, ax, density, ' ', ...
            param.label, g, [mapX, mapY(g), mapW, mapH], latRange, ...
            lineWidth, mainFontSize, titleFontSize);
        add_map_panel_label_title_level(fig, [mapX, mapY(g), mapW, mapH], ...
            panelLabels{8 + g}, panelFontSize);
    end
    cbW = mapW * 0.90;
    cbX = mapX + (mapW - cbW) / 2;
    draw_density_colorbar(fig, ax, [cbX, colorbarPos(2), cbW, colorbarPos(4)], lineWidth, mainFontSize);

    % Draw the new vertical dual legend below the colorbar
    legendW = cbW * 1.20;
    legendX = cbX - (legendW - cbW) / 2;
    draw_vertical_dual_legend(fig, [legendX, legY, legendW, legH], groupColors, ...
        displayEventTypes, param.label, mainFontSize, lineWidth);

    set(fig, 'InvertHardcopy', 'off');
    exportgraphics(fig, [figOut, '.tif'], 'Resolution', tiffDpi, 'BackgroundColor', 'white');
    exportgraphics(fig, [figOut, '.png'], 'Resolution', tiffDpi, 'BackgroundColor', 'white');
    close(fig);
end

function density = load_plot08_density(cacheDir, eventType, paramSourceId)
    cacheFile = fullfile(cacheDir, sprintf('Plot_08_%s_by_%s_plot_data.mat', ...
        eventType, paramSourceId));
    assert(exist(cacheFile, 'file') == 2, 'Missing Plot08 cache: %s', cacheFile);
    S = load(cacheFile, 'DensityMaps', 'group_event_counts', 'current_group_labels');
    density.maps = S.DensityMaps;
    density.group_event_counts = S.group_event_counts;
    density.group_labels = strip_group_label_ranges(S.current_group_labels);
    density.lon_centers = 2.5:5:357.5;
    density.lat_centers = -42.5:5:42.5;
    [density.LonGrid, density.LatGrid] = meshgrid(density.lon_centers, density.lat_centers);
end

function labels = strip_group_label_ranges(labels)
    for iLabel = 1:numel(labels)
        token = regexp(labels{iLabel}, '^L\d+', 'match', 'once');
        if ~isempty(token)
            labels{iLabel} = token;
        end
    end
end

function [newY, newH] = compress_vertical_positions(y, h, anchorTop, scaleFactor)
    topDistance = anchorTop - (y + h);
    newH = h * scaleFactor;
    newY = anchorTop - topDistance * scaleFactor - newH;
end

function [mapY, mapH] = build_map_stack_layout(mapW, mapAspectRatio, stackTop, stackGap, ...
        fullWidthCm, figHeightCm, anchorTop, scaleFactor)
    % 让压缩后的右侧 map axes 接近 m_map Robinson 自然宽高比。
    finalMapH = mapW * fullWidthCm / (mapAspectRatio * figHeightCm);
    finalMapY = [ ...
        stackTop - finalMapH, ...
        stackTop - 2 * finalMapH - stackGap, ...
        stackTop - 3 * finalMapH - 2 * stackGap];
    mapH = finalMapH / scaleFactor;
    mapY = (finalMapY - anchorTop * (1 - scaleFactor)) / scaleFactor;
end

function density = combine_plot08_density(densityMhw, densityMcs)
    % 第三到第五行每行只画一张 map，因此这里把 MHW/MCS 的 Fig08 density 合并。
    density = densityMhw;
    density.maps = densityMhw.maps + densityMcs.maps;
    density.group_event_counts = densityMhw.group_event_counts + densityMcs.group_event_counts;
end

function draw_density_map_axis(fig, ax, density, eventLabel, paramLabel, groupId, axPos, ...
        latRange, lineWidth, mainFontSize, titleFontSize)
    axes(ax);
    hold(ax, 'on');
    m_proj('robinson', 'lon', [0 360], 'lat', latRange);
    Z = double(density.maps(:, :, groupId));
    m_contourf(density.LonGrid, density.LatGrid, Z, 0:3:30, 'LineStyle', 'none');
    m_coast('patch', [0.92 0.92 0.92], 'edgecolor', 'none');
    set(findobj(gca, 'Type', 'patch'), 'FaceAlpha', 1);
    m_grid('tickdir', 'out', 'linestyle', 'none', 'linewidth', lineWidth, ...
        'fontsize', mainFontSize-1, 'fontname', 'Arial', ...
        'YTick', [-45, -20, 0, 20, 45], ...
        'tickstyle', 'dd', ...
        'XTick', 0:120:360);
    set(findobj(gca, 'Type', 'line'), 'LineWidth', lineWidth);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, ...
        'FontName', 'Arial', 'FontWeight', 'normal', 'Layer', 'top');
    stretch_m_map_to_axes(ax);
    if groupId < numel(density.group_labels)
        suppress_m_grid_longitude_labels(ax);
    end
    colormap(ax, density_colormap());
    clim(ax, [0, 30]);
    add_map_title(fig, axPos, sprintf('%s %s %s (N=%s)', ...
        eventLabel, paramLabel, density.group_labels{groupId}, ...
        add_comma_separator(density.group_event_counts(groupId))), titleFontSize);
end

function draw_density_colorbar(~, ax, cbPos, lineWidth, mainFontSize)
    axes(ax);
    cb = colorbar('southoutside');
    cb.Color = [0 0 0];
    cb.Label.Color = [0 0 0];
    cb.Position = cbPos;
    cb.Label.String = 'Peak-day events per 5^\circ x 5^\circ bin';
    cb.FontName = 'Arial';
    cb.FontSize = mainFontSize;
    cb.FontWeight = 'normal';
    cb.TickDirection = 'out';
    cb.LineWidth = lineWidth;
    cb.Ticks = 0:5:30;
    cb.TickLabels = compose('%.0f', cb.Ticks);
    cb.Label.FontWeight = 'normal';
end

function stretch_m_map_to_axes(ax)
    % m_map 默认锁定 DataAspectRatio=[1 1 1]，axes 变宽时地图本体不会变长。
    % 这里解除比例锁定，让第三到第五行的横向 map 填满指定 axes 宽度。
    % 注意：这是显示层面的横向拉伸，不改变数据和色标。
    set(ax, 'DataAspectRatioMode', 'auto', 'PlotBoxAspectRatioMode', 'auto');
end

function suppress_m_grid_longitude_labels(ax)
    % I/J 两张 map 删除 m_grid 自动生成的经度文字，只在 K 图保留经度刻度。
    delete(findall(ax, 'Tag', 'm_grid_xticklabel'));
end

function cmap = density_colormap()
    if exist('nclCM', 'file') == 2
        cmap = nclCM(203);
    else
        cmap = parula(10);
    end
end

function draw_grouped_response_axis(ax, Composite, event_type, response_id, timeMode, ...
        colors, yLimVals, yTickStep, lineWidth, mainFontSize, titleFontSize, showXLabels, expXPos)
    data = Composite.Response.(response_id);
    R = data.Result.(event_type);
    hold(ax, 'on');
    if strcmp(timeMode, 'absolute')
        x_label = 'Lag days';
        xlim_vals = [-Composite.Param.absXLimit, Composite.Param.absXLimit];
        % 第二行小图宽度较窄，x 轴只保留两端和 0，避免刻度文字自动倾斜并压到图例。
        x_ticks = [-Composite.Param.absXLimit, 0, Composite.Param.absXLimit];
        for g = 3:-1:1
            plot_one_curve_with_ci(ax, R.abs_lags{g}, R.abs_mean{g}, R.abs_ci{g}, colors(g, :), 1.5);
        end
    else
        x_label = 'Norm. phase';
        xlim_vals = [-1, 2];
        x_ticks = [-1, 0, 1, 2];
        x = linspace(-1, 2, size(R.norm_mean, 2));
        for g = 3:-1:1
            plot_one_curve_with_ci(ax, x, R.norm_mean(g, :), R.norm_ci(g, :), colors(g, :), 1.5);
        end
    end
    % 默认科学计数法字号为 7，Y 轴位置为 1.00
    expFontSize = 6; 
    expYPos = 0.98;
    if strcmp(timeMode, 'normalized') && ~strcmp(response_id, 'CHLA')
        % =========================================================
        % 调这个分支单独控制 Normalized 图中 bcd/fgh (PSC) 科学计数法的字号与上下位置
        % =========================================================
        expFontSize = 5; 
        if strcmp(event_type, 'MHW')
            expYPos = 0.98; % bcd (MHW) 的上下位置，变大上移，变小下移
        else
            expYPos = 0.98; % fgh (MCS) 的上下位置，变大上移，变小下移
        end
    end
    decorate_response_axis(ax, xlim_vals, x_label, response_id, ...
        lineWidth, mainFontSize, titleFontSize, yLimVals, yTickStep, expXPos, expFontSize, expYPos);
    xlim(ax, xlim_vals);
    xticks(ax, x_ticks);
    if ~strcmp(timeMode, 'absolute')
        % 归一化时间用短相位标签，避免数字标签在窄小图中连成一串。
        xticklabels(ax, {'Pre', 'On', 'End', 'Post'});
    end
    xtickangle(ax, 0);
    if ~showXLabels
        xlabel(ax, '');
        xticklabels(ax, {});
    else
        xlabel(ax, '');
    end
end

function plot_one_curve_with_ci(ax, x, y, ci, color, curveWidth)
    axes(ax);
    hold(ax, 'on');
    if isempty(x) || isempty(y) || isempty(ci), return; end
    valid = isfinite(y) & isfinite(ci);
    if sum(valid) < 2, return; end
    xv = x(valid);
    yv = y(valid);
    civ = ci(valid);
    fill(ax, [xv, fliplr(xv)], [yv + civ, fliplr(yv - civ)], color, ...
        'FaceAlpha', 0.16, 'EdgeColor', 'none');
    plot(ax, xv, yv, '-', 'Color', color, 'LineWidth', curveWidth);
end

function decorate_response_axis(ax, x, xLabelText, titleText, lineWidth, mainFontSize, titleFontSize, commonYLim, yTickStep, expXPos, expFontSize, expYPos)
    box(ax, 'on');
    grid(ax, 'off');
    if min(x) < 0 && max(x) > 0
        xline(ax, 0, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.5);
    end
    if min(x) < 1 && max(x) > 1 && max(x) <= 2
        xline(ax, 1, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.5);
    end
    title(ax, titleText, 'FontWeight', 'normal', 'FontSize', titleFontSize, 'Color', [0 0 0]);
    xlabel(ax, xLabelText);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', ...
        'FontName', 'Arial', 'FontWeight', 'normal');
    ylim(ax, commonYLim);
    format_response_y_axis(ax, commonYLim, yTickStep, expXPos, expFontSize, expYPos);
end

function format_response_y_axis(ax, yLimVals, yTickStep, expXPos, expFontSize, expYPos)
    if nargin < 5
        expFontSize = 7;
    end
    if nargin < 6
        expYPos = 1.00;
    end
    yMax = max(abs(yLimVals));
    if ~isfinite(yMax) || yMax <= 0
        ytickformat(ax, '%.1f');
        return
    end
    if isfinite(yTickStep) && yTickStep > 0
        y_ticks = yLimVals(1):yTickStep:yLimVals(2);
        yticks(ax, y_ticks);
    end
    
    ax.YAxis.Exponent = 0; 
    ticks = yticks(ax);

    if yMax < 0.1
        expVal = floor(log10(yMax));
        % 格式化非 0 刻度，并将接近 0 的刻度一键替换为 '0'
        labels = arrayfun(@(v) sprintf('%.1f', v / 10^expVal), ticks, 'UniformOutput', false);
        labels(abs(ticks) < 1e-9) = {'0'};
        yticklabels(ax, labels);
        
        ylabel(ax, '');
        text(ax, expXPos, expYPos, sprintf('\\times10^{%d}', expVal), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'left', ...
            'Clipping', 'off', ...
            'FontSize', expFontSize, 'FontName', 'Arial', ...
            'FontWeight', 'normal');
            
    elseif yMax < 1
        labels = arrayfun(@(v) sprintf('%.2f', v), ticks, 'UniformOutput', false);
        labels(abs(ticks) < 1e-9) = {'0'};
        yticklabels(ax, labels);
        
    else
        labels = arrayfun(@(v) sprintf('%.1f', v), ticks, 'UniformOutput', false);
        labels(abs(ticks) < 1e-9) = {'0'};
        yticklabels(ax, labels);
    end
end

function add_map_title(fig, axPos, titleText, titleFontSize)
    annotation(fig, 'textbox', ...
        [axPos(1), axPos(2) + axPos(4) - 0.002, axPos(3), 0.020], ...
        'String', titleText, ...
        'LineStyle', 'none', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', titleFontSize, ...
        'FontWeight', 'normal', ...
        'Interpreter', 'none', ...
        'FitBoxToText', 'off', 'Color', [0 0 0]);
end

function add_map_panel_label_title_level(fig, axPos, labelText, fontSize)
    % I/J/K 的面板标号；和 map 小标题使用同一高度，x 控制左右位置。
    annotation(fig, 'textbox', ...
        [axPos(1) + 0.018, axPos(2) + axPos(4) - 0, 0.050, 0.020], ...
        'String', labelText, ...
        'LineStyle', 'none', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', fontSize, ...
        'FontWeight', 'normal', ...
        'Interpreter', 'none', ...
        'FitBoxToText', 'off', 'Color', [0 0 0]);
end

function draw_vertical_dual_legend(fig, pos, groupColors, displayEventTypes, paramLabel, mainFontSize, lineWidth)
    % 下方的双列竖向简约图例；pos=[left bottom width height]。
    axLeg = axes(fig, 'Position', pos);
    hold(axLeg, 'on');
    set(axLeg, 'Color', 'none', 'XLim', [0 2], 'YLim', [0 1.2], ...
        'Visible', 'off');

    legendLineWidth = max(4.4, lineWidth * 8);
    labels = {'L1 (0-25%)', 'L2 (25-75%)', 'L3 (75-100%)'};

    % 第一列：SCMHW — 左移与颜色块对齐
    text(axLeg, 0.15, 1.05, displayEventTypes.MHW, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', mainFontSize, ...
        'FontWeight', 'bold', ...
        'Color', [0 0 0]);
    % 在第一列原标题位置添加参数标签
    text(axLeg, 0.46, 1.05, paramLabel, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', mainFontSize, ...
        'FontWeight', 'normal', ...
        'Color', [0 0 0]);

    y_positions = [0.75, 0.45, 0.15];
    for g = 1:3
        plot(axLeg, [0.15 0.38], [y_positions(g) y_positions(g)], '-', ...
            'Color', groupColors.MHW(g, :), ...
            'LineWidth', legendLineWidth, ...
            'Clipping', 'off');
        text(axLeg, 0.46, y_positions(g), labels{g}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', ...
            'FontSize', mainFontSize, ...
            'FontWeight', 'normal', ...
            'Color', [0 0 0]);
    end

    % 第二列：SCMCS — 左移与颜色块对齐
    text(axLeg, 1.15, 1.05, displayEventTypes.MCS, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', mainFontSize, ...
        'FontWeight', 'bold', ...
        'Color', [0 0 0]);
    % 在第二列原标题位置添加参数标签
    text(axLeg, 1.46, 1.05, paramLabel, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', mainFontSize, ...
        'FontWeight', 'normal', ...
        'Color', [0 0 0]);

    for g = 1:3
        plot(axLeg, [1.15 1.38], [y_positions(g) y_positions(g)], '-', ...
            'Color', groupColors.MCS(g, :), ...
            'LineWidth', legendLineWidth, ...
            'Clipping', 'off');
        text(axLeg, 1.46, y_positions(g), labels{g}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', ...
            'FontSize', mainFontSize, ...
            'FontWeight', 'normal', ...
            'Color', [0 0 0]);
    end
end

function add_vertical_figure_label(fig, pos, labelText, fontSize)
    % 组级 y 轴标题；pos=[left bottom width height]，改 left 可左右移动，改 bottom/height 可上下移动。
    axLabel = axes(fig, 'Position', pos, 'Visible', 'off', ...
        'Color', 'none', 'XLim', [0 1], 'YLim', [0 1]);
    text(axLabel, 0.50, 0.50, labelText, ...
        'Units', 'normalized', ...
        'Rotation', 90, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', fontSize, ...
        'FontWeight', 'normal', ...
        'Interpreter', 'tex', ...
        'Clipping', 'off');
end

function add_panel_label_inside(ax, labelText, fontSize)
    % 面板编号放在各自 axes 外部左上角。
    add_panel_label_inside_at(ax, labelText, fontSize, 0.01, 1.175);
end

function add_panel_label_inside_at(ax, labelText, fontSize, xNorm, yNorm)
    % 支持自定义位置的 panel 编号。
    text(ax, xNorm, yNorm, labelText, ...
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

function set_axis_title_x(titleHandle, xNorm)
    % 只调整 axes title 的横向位置，保留 MATLAB 自动计算的纵向标题高度。
    set(titleHandle, 'Units', 'normalized');
    titleHandle.Position(1) = xNorm;
    titleHandle.HorizontalAlignment = 'center';
end

function hide_axes_toolbar(ax)
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

function str = add_comma_separator(num)
    % 给整数添加美式逗号分隔，如 4932 -> '4,932'
    str = sprintf('%d', num);
    nDigits = numel(str);
    if nDigits <= 3 || str(1) == '-'
        return;
    end
    parts = {};
    pos = nDigits;
    while pos > 3
        parts{end+1} = str(pos-2:pos);
        pos = pos - 3;
    end
    parts{end+1} = str(1:pos);
    str = strjoin(fliplr(parts), ',');
end
