%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot 08 auxiliary maps: 5-degree peak-day bin density by event groups
%%% Project: MHW_MCS_CHLA
%%%
%%% Code:   figure_code
%%% Inputs: 05_Characteristic/Out/Characteristic_*_Basin_Eps5_MinPts200.mat
%%%         figure_code/In/MLD_*_Eps5_MinPts200.mat
%%% Output: figure_code/Out/Fig08_Peak_Day_Bin_Density_Map_*_by_*.tif
%%%
%%% Note:
%%%   Peak-day location follows Fig05: intensity-weighted centroid on the
%%%   event peak day. The locations are counted in 5 deg x 5 deg bins.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;

%% ================== 1. Paths and style ==================
this_file = mfilename('fullpath');
plot_dir  = fileparts(this_file);
base_dir  = fileparts(plot_dir);

char_dir = fullfile(base_dir, '05_Characteristic', 'Out');
in_dir   = fullfile(plot_dir, 'In');
cache_dir = fullfile(plot_dir, 'Cache');
out_dir  = fullfile(plot_dir, 'Out');
if ~exist(cache_dir, 'dir'), mkdir(cache_dir); end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% 外部绘图工具必须由用户预先加入 MATLAB path。

assert(exist('m_proj', 'file') == 2, ...
    'm_map is required: m_proj was not found on the MATLAB path.');

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
FIG_HEIGHT_CM = 17.5;
TIFF_DPI = 900;
LINE_WIDTH = 0.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;
BIN_SIZE_DEG = 5;
LAT_RANGE = [-45, 45];
COUNT_CLIM = [0, 30];
COUNT_CTICKS = 0:5:30;
LON_EDGES = 0:BIN_SIZE_DEG:360;
LAT_EDGES = LAT_RANGE(1):BIN_SIZE_DEG:LAT_RANGE(2);
[LonEdgeGrid, LatEdgeGrid] = meshgrid(LON_EDGES, LAT_EDGES);
LON_CENTERS = LON_EDGES(1:end-1) + BIN_SIZE_DEG / 2;
LAT_CENTERS = LAT_EDGES(1:end-1) + BIN_SIZE_DEG / 2;
[LonCenterGrid, LatCenterGrid] = meshgrid(LON_CENTERS, LAT_CENTERS);

EVENT_TYPES = {'MHW', 'MCS'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';

GROUP_PCTS = [0, 25, 75, 100];
GROUP_LABELS = {'L1 (0-25%)', 'L2 (25-75%)', 'L3 (75-100%)'};
LATITUDE_GROUP_LABELS = {'L1 (15-45N)', 'L2 (15S-15N)', 'L3 (45-15S)'};

PARAMS = struct( ...
    'id',       {'Duration', 'Max_Area', 'Mean_Intensity', 'MLD',            'Speed',     'Latitude'}, ...
    'label',    {'Duration', 'Max Area', 'Mean Intensity', 'MLD',            'Speed',     'Latitude'}, ...
    'fieldMHW', {'Duration', 'Max_Area', 'MHW_Global_Mean', 'MLD_Event_Mean', 'Wgt_Speed', 'Mean_Lat'}, ...
    'fieldMCS', {'Duration', 'Max_Area', 'MCS_Global_Mean', 'MLD_Event_Mean', 'Wgt_Speed', 'Mean_Lat'}, ...
    'useAbs',   {false,      false,      true,              false,           false,       false} );
CACHE_VERSION = 1;
CACHE_CONFIG_BASE = struct( ...
    'bin_size_deg', BIN_SIZE_DEG, ...
    'lat_range', LAT_RANGE, ...
    'group_pcts', GROUP_PCTS, ...
    'params', {PARAMS}, ...
    'calculation_id', 'Plot08_peak_day_bin_density_maps_v1');

MAP_AXES_POS = [0.075 0.720 0.850 0.190;
                0.075 0.440 0.850 0.190;
                0.075 0.160 0.850 0.190];
COLORBAR_POS = [0.075 0.070 0.850 0.020];

%% ================== 2. Input files ==================
char_file_mhw = fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat');
char_file_mcs = fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat');
mld_file_mhw = fullfile(in_dir, 'MLD_MHW_Eps5_MinPts200.mat');
mld_file_mcs = fullfile(in_dir, 'MLD_MCS_Eps5_MinPts200.mat');
input_files = {char_file_mhw, char_file_mcs, mld_file_mhw, mld_file_mcs};
data_loaded = false;

%% ================== 3. Plot 5-degree bin density maps ==================
fprintf('Plotting Plot08 peak-day 5-degree bin density maps...\n');

for iParam = 1:numel(PARAMS)
    param = PARAMS(iParam);

    for iEvent = 1:numel(EVENT_TYPES)
        event_type = EVENT_TYPES{iEvent};
        display_event_type = DISPLAY_EVENT_TYPES.(event_type);

        if strcmp(event_type, 'MHW')
            sort_field = param.fieldMHW;
            peak_date_field = 'Peak_MHW_Date';
        else
            sort_field = param.fieldMCS;
            peak_date_field = 'Peak_MCS_Date';
        end

        cache_file = fullfile(cache_dir, sprintf('Plot_08_%s_by_%s_plot_data.mat', event_type, param.id));
        cache_config = CACHE_CONFIG_BASE;
        cache_config.event_type = event_type;
        cache_config.param_id = param.id;
        if is_plot_cache_current(cache_file, input_files, CACHE_VERSION, cache_config)
            fprintf('Loading cached Plot 08 data: %s by %s\n', event_type, param.id);
            C = load(cache_file, 'DensityMaps', 'group_event_counts', 'current_group_labels', 'max_count');
            DensityMaps = C.DensityMaps;
            group_event_counts = C.group_event_counts;
            current_group_labels = C.current_group_labels;
            max_count = C.max_count;
        else
            if ~data_loaded
                fprintf('Loading characteristic and MLD tables...\n');
                D_MHW = load(char_file_mhw);
                D_MCS = load(char_file_mcs);
                Basic.MHW = D_MHW.MHW_Basic_Table;
                Basic.MCS = D_MCS.MCS_Basic_Table;
                Series.MHW = D_MHW.MHW_Series_Table;
                Series.MCS = D_MCS.MCS_Series_Table;
                MLD_MHW = load(mld_file_mhw);
                MLD_MCS = load(mld_file_mcs);
                Basic.MHW = append_mld_event_mean(Basic.MHW, MLD_MHW.MHW_MLD_Table);
                Basic.MCS = append_mld_event_mean(Basic.MCS, MLD_MCS.MCS_MLD_Table);
                data_loaded = true;
            end

            assert(ismember(peak_date_field, Basic.(event_type).Properties.VariableNames), ...
                'Missing peak date field: %s', peak_date_field);

            if strcmp(param.id, 'Latitude')
                grp = get_latitude_groups(Basic.(event_type).(sort_field));
                current_group_labels = LATITUDE_GROUP_LABELS;
            else
                grp = get_groups_by_count(Basic.(event_type), sort_field, param.useAbs, GROUP_PCTS);
                current_group_labels = GROUP_LABELS;
            end

            [lon, lat] = get_peak_weighted_centroids(Basic.(event_type), ...
                Series.(event_type), peak_date_field);
            lon = normalize_lon_360(lon);
            [DensityMaps, group_event_counts] = build_bin_density_maps( ...
                lon, lat, grp, LON_EDGES, LAT_EDGES);
            max_count = max(DensityMaps(:), [], 'omitnan');
            if isempty(max_count) || ~isfinite(max_count)
                max_count = 0;
            end

            cache_version = CACHE_VERSION; %#ok<NASGU>
            save(cache_file, 'DensityMaps', 'group_event_counts', 'current_group_labels', ...
                'max_count', 'cache_version', 'cache_config', '-v7.3');
            fprintf('Saved cached Plot 08 data: %s\n', cache_file);
        end

        render_modes = {'Pcolor', 'Contourf'};
        for iRender = 1:numel(render_modes)
            render_mode = render_modes{iRender};
            fig = figure('Units', 'centimeters', ...
                'Position', [2 2 FULL_WIDTH_CM FIG_HEIGHT_CM], 'Color', 'w');
            set(fig, 'Toolbar', 'none');
            cmap = density_colormap();

            for g = 1:numel(current_group_labels)
                ax = axes('Position', MAP_AXES_POS(g, :));
                hold(ax, 'on');

                m_proj('robinson', 'lon', [0 360], 'lat', LAT_RANGE);
                if strcmp(render_mode, 'Contourf')
                    Z_plot = double(DensityMaps(:, :, g));
                    m_contourf(LonCenterGrid, LatCenterGrid, Z_plot, ...
                        density_contour_levels(max_count), 'LineStyle', 'none');
                else
                    Z_plot = make_pcolor_grid(DensityMaps(:, :, g));
                    m_pcolor(LonEdgeGrid, LatEdgeGrid, Z_plot);
                    shading flat;
                end
                hold on;
                m_coast('patch', [0.92 0.92 0.92], 'edgecolor', 'none');
                set(findobj(gca, 'Type', 'patch'), 'FaceAlpha', 1);
                m_grid('tickdir', 'out', 'linestyle', 'none', 'linewidth', LINE_WIDTH, ...
                    'fontsize', MAIN_FONT_SIZE, 'fontname', 'Arial', ...
                    'YTick', -45:15:45, 'XTick', 0:60:360);
                set(findobj(gca, 'Type', 'line'), 'LineWidth', LINE_WIDTH);

                set(ax, 'LineWidth', LINE_WIDTH, 'FontSize', MAIN_FONT_SIZE, ...
                    'FontName', 'Arial', 'Layer', 'top');
                colormap(ax, cmap);
                clim(ax, COUNT_CLIM);
                add_map_title(fig, MAP_AXES_POS(g, :), sprintf('%s %s %s, N=%d', ...
                    display_event_type, param.label, current_group_labels{g}, group_event_counts(g)), ...
                    TITLE_FONT_SIZE);
            end

            axes(ax); %#ok<LAXES>
            cb = colorbar('southoutside');
            cb.Position = COLORBAR_POS;
            cb.Label.String = sprintf('Peak-day events per %d^\\circ x %d^\\circ bin', ...
                BIN_SIZE_DEG, BIN_SIZE_DEG);
            cb.FontName = 'Arial';
            cb.FontSize = MAIN_FONT_SIZE;
            cb.TickDirection = 'out';
            cb.LineWidth = LINE_WIDTH;
            cb.Ticks = COUNT_CTICKS;
            cb.TickLabels = compose('%.0f', COUNT_CTICKS);

            set(fig, 'InvertHardcopy', 'off');
            output_suffix = '';
            if strcmp(render_mode, 'Contourf')
                output_suffix = '_Contourf';
            end
            fig_out = fullfile(out_dir, sprintf( ...
                'Fig08_Peak_Day_Bin_Density_Map_%s_by_%s%s', ...
                display_event_type, param.id, output_suffix));
            fprintf('Saving: %s.tif\n', fig_out);
            drawnow;
            pause(3);
            exportgraphics(fig, [fig_out, '.tif'], 'Resolution', TIFF_DPI);
            close(fig);
        end
    end
end

fprintf('Done.\n');

%% ================== Local functions ==================
function BasicT = append_mld_event_mean(BasicT, MLDT)
    BasicT.MLD_Event_Mean = nan(height(BasicT), 1);
    eid_mld = string(MLDT.Event_ID);
    for i = 1:height(BasicT)
        j = find(eid_mld == string(BasicT.Event_ID(i)), 1);
        if ~isempty(j) && ismember('MLD_Event_Mean', MLDT.Properties.VariableNames)
            BasicT.MLD_Event_Mean(i) = MLDT.MLD_Event_Mean(j);
        end
    end
end

function grp = get_groups_by_count(BasicT, sortField, useAbs, pcts)
    assert(ismember(sortField, BasicT.Properties.VariableNames), ...
        'Missing grouping field: %s', sortField);
    s = double(BasicT.(sortField));
    if size(s, 2) > 1
        s = s(:, 1);
    end
    if useAbs
        s = abs(s);
    end

    valid = isfinite(s);
    grp = nan(size(s));
    idx_valid = find(valid);
    s_valid = s(valid);
    [sorted_s, order] = sort(s_valid);
    sorted_idx = idx_valid(order);

    n = numel(sorted_s);
    num_groups = numel(pcts) - 1;
    if n == 0
        return
    end

    target_counts = round(n * pcts / 100);
    target_counts(1) = 1;
    current_group = 1;
    for i = 1:n
        if current_group < num_groups && i > target_counts(current_group + 1) ...
                && i > 1 && sorted_s(i) > sorted_s(i - 1)
            current_group = current_group + 1;
        end
        grp(sorted_idx(i)) = current_group;
    end
end

function grp = get_latitude_groups(latValues)
    lat = double(latValues(:));
    grp = nan(size(lat));
    grp(lat >= 15 & lat <= 45)   = 1;
    grp(lat > -15 & lat < 15)    = 2;
    grp(lat >= -45 & lat <= -15) = 3;
end

function lon = normalize_lon_360(lon)
    lon = mod(lon, 360);
    lon(lon == 0) = 360;
end

function [peakLon, peakLat] = get_peak_weighted_centroids(BasicT, SeriesT, peakDateField)
    peakLon = nan(height(BasicT), 1);
    peakLat = nan(height(BasicT), 1);

    series_ids = string(SeriesT.Event_ID);
    for i = 1:height(BasicT)
        series_idx = find(series_ids == string(BasicT.Event_ID(i)), 1);
        if isempty(series_idx)
            continue
        end

        dates = row_value(SeriesT.Date_Idx, series_idx);
        wgt_centroid = row_value(SeriesT.Wgt_Centroid, series_idx);
        if isempty(dates) || isempty(wgt_centroid) || size(wgt_centroid, 2) < 2
            continue
        end

        peak_date = BasicT.(peakDateField)(i);
        peak_idx = find(double(dates(:)) == double(peak_date), 1);
        if isempty(peak_idx) || peak_idx > size(wgt_centroid, 1)
            continue
        end

        peakLon(i) = wgt_centroid(peak_idx, 1);
        peakLat(i) = wgt_centroid(peak_idx, 2);
    end
end

function value = row_value(tableVar, rowIdx)
    if iscell(tableVar)
        value = tableVar{rowIdx};
    else
        value = tableVar(rowIdx, :);
        value = squeeze(value);
    end
end

function [DensityMaps, group_event_counts] = build_bin_density_maps(lon, lat, grp, lonEdges, latEdges)
    num_groups = 3;
    nLon = numel(lonEdges) - 1;
    nLat = numel(latEdges) - 1;
    DensityMaps = zeros(nLat, nLon, num_groups, 'single');
    group_event_counts = zeros(1, num_groups);

    for g = 1:num_groups
        idx = grp == g & isfinite(lon) & isfinite(lat) ...
            & lat >= latEdges(1) & lat <= latEdges(end) ...
            & lon >= lonEdges(1) & lon <= lonEdges(end);
        group_event_counts(g) = nnz(idx);
        if ~any(idx)
            continue
        end

        lon_idx = discretize(lon(idx), lonEdges);
        lat_idx = discretize(lat(idx), latEdges);
        lon_idx(lon(idx) == lonEdges(end)) = nLon;
        lat_idx(lat(idx) == latEdges(end)) = nLat;
        valid = isfinite(lon_idx) & isfinite(lat_idx);
        bin_idx = sub2ind([nLat, nLon], lat_idx(valid), lon_idx(valid));
        counts = accumarray(bin_idx, 1, [nLat * nLon, 1], @sum, 0);
        DensityMaps(:, :, g) = reshape(counts, [nLat, nLon]);
    end
end

function Z_plot = make_pcolor_grid(Z)
    Z = double(Z);
    Z_plot = nan(size(Z, 1) + 1, size(Z, 2) + 1);
    Z_plot(1:end-1, 1:end-1) = Z;
end

function levels = density_contour_levels(~)
    levels = 0:3:30;
end

function cmap = density_colormap()
    if exist('nclCM', 'file') == 2
        cmap = nclCM(203);
    else
        cmap = parula(10);
    end
end

function add_map_title(fig, axPos, titleText, titleFontSize)
    annotation(fig, 'textbox', ...
        [axPos(1), axPos(2) + axPos(4) + 0.012, axPos(3), 0.035], ...
        'String', titleText, ...
        'LineStyle', 'none', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', ...
        'FontSize', titleFontSize, ...
        'FontWeight', 'normal', ...
        'Interpreter', 'none', ...
        'FitBoxToText', 'off');
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
