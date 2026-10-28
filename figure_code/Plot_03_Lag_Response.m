%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot 03: Lag response of CHLA and PSC to SCMHW/SCMCS event properties
%%% Project: MHW_MCS_CHLA
%%%
%%% Code:   figure_code
%%% Inputs: 05_Characteristic/Out/Characteristic_*_Basin_Eps5_MinPts200.mat
%%%         figure_code/In/MLD_*_Eps5_MinPts200.mat
%%% Output: figure_code/Out/Fig03_Lag_*_by_*.tif
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
LINE_WIDTH = 0.5;
MAIN_FONT_SIZE = 7;
TITLE_FONT_SIZE = 8;

EVENT_TYPES = {'MHW', 'MCS'};
DISPLAY_EVENT_TYPES.MHW = 'SCMHW';
DISPLAY_EVENT_TYPES.MCS = 'SCMCS';

GROUP_PCTS = [0, 25, 75, 100];
GROUP_LABELS = {'L1 (0-25%)', 'L2 (25-75%)', 'L3 (75-100%)'};
LATITUDE_GROUP_LABELS = {'15-45N', '15S-15N', '45-15S'};
GROUP_COLORS.MHW = [250 128 114
                    147 127 179
                    165 000 038] / 255;
GROUP_COLORS.MCS = [169 203 140
                    091 189 160
                    000 141 170] / 255;

DYNAMIC_ABS_MIN_LAG = 30;
NORM_GRID = linspace(-1, 2, 150);
BASELINE_DAYS = -60:-1;
MIN_GROUP_N = 5;
CACHE_VERSION = 1;

% 当前验证版复现旧的 MLD lag 图：MLD 自身响应，按 Duration 四分位分组。
RESPONSES = struct( ...
    'id',        {'CHLA',           'Pico',           'Nano',           'Micro'}, ...
    'label',     {'CHLA',           'Pico',           'Nano',           'Micro'}, ...
    'field',     {'Box_CHLA_Full',  'Box_Pico_Full',  'Box_Nano_Full',  'Box_Micro_Full'}, ...
    'dateField', {'Box_Date_Idx',   'Box_Date_Idx',   'Box_Date_Idx',   'Box_Date_Idx'}, ...
    'source',    {'Characteristic', 'Characteristic', 'Characteristic', 'Characteristic'}, ...
    'ylabel',    {'CHLA anomaly (mg/m^3)', 'Pico anomaly (mg/m^3)', ...
                  'Nano anomaly (mg/m^3)', 'Micro anomaly (mg/m^3)'} );

PARAMS = struct( ...
    'id',       {'Duration', 'Max_Area', 'Mean_Intensity', 'MLD',            'Speed',     'Latitude'}, ...
    'label',    {'Duration', 'Max Area', 'Mean Intensity', 'MLD',            'Speed',     'Latitude'}, ...
    'fieldMHW', {'Duration', 'Max_Area', 'MHW_Global_Mean', 'MLD_Event_Mean', 'Wgt_Speed', 'Mean_Lat'}, ...
    'fieldMCS', {'Duration', 'Max_Area', 'MCS_Global_Mean', 'MLD_Event_Mean', 'Wgt_Speed', 'Mean_Lat'}, ...
    'useAbs',   {false,      false,      true,              false,           false,       false} );
CACHE_CONFIG_BASE = struct( ...
    'dynamic_abs_min_lag', DYNAMIC_ABS_MIN_LAG, ...
    'norm_grid', NORM_GRID, ...
    'baseline_days', BASELINE_DAYS, ...
    'min_group_n', MIN_GROUP_N, ...
    'group_pcts', GROUP_PCTS, ...
    'responses', {RESPONSES}, ...
    'params', {PARAMS}, ...
    'calculation_id', 'Plot03_lag_response_v1');

%% ================== 2. Input files ==================
char_file_mhw = fullfile(char_dir, 'Characteristic_MHW_Basin_Eps5_MinPts200.mat');
char_file_mcs = fullfile(char_dir, 'Characteristic_MCS_Basin_Eps5_MinPts200.mat');
mld_file_mhw = fullfile(in_dir, 'MLD_MHW_Eps5_MinPts200.mat');
mld_file_mcs = fullfile(in_dir, 'MLD_MCS_Eps5_MinPts200.mat');
input_files = {char_file_mhw, char_file_mcs, mld_file_mhw, mld_file_mcs};
data_loaded = false;

%% ================== 3. Compute and plot lag composites ==================
fprintf('Plotting Plot 03 lag-response figures...\n');

for iParam = 1:numel(PARAMS)
    param = PARAMS(iParam);
    if strcmp(param.id, 'Duration')
        abs_x_limit = 60;
        abs_x_tick = 30;
    else
        abs_x_limit = 30;
        abs_x_tick = 15;
    end
    if strcmp(param.id, 'Latitude')
        current_group_labels = LATITUDE_GROUP_LABELS;
    else
        current_group_labels = GROUP_LABELS;
    end

    for iResp = 1:numel(RESPONSES)
        response = RESPONSES(iResp);

        cache_file = fullfile(cache_dir, sprintf('Plot_03_%s_by_%s_plot_data.mat', response.id, param.id));
        cache_config = CACHE_CONFIG_BASE;
        cache_config.response_id = response.id;
        cache_config.param_id = param.id;
        if is_plot_cache_current(cache_file, input_files, CACHE_VERSION, cache_config)
            fprintf('Loading cached Plot 03 data: %s by %s\n', response.id, param.id);
            C = load(cache_file, 'Result', 'common_ylim');
            Result = C.Result;
            common_ylim = C.common_ylim;
        else
            if ~data_loaded
                fprintf('Loading characteristic and MLD tables...\n');
                D_MHW = load(char_file_mhw);
                D_MCS = load(char_file_mcs);
                Basic.MHW = D_MHW.MHW_Basic_Table;
                Series.MHW = D_MHW.MHW_Series_Table;
                Basic.MCS = D_MCS.MCS_Basic_Table;
                Series.MCS = D_MCS.MCS_Series_Table;
                MLD_MHW = load(mld_file_mhw);
                MLD_MCS = load(mld_file_mcs);
                Basic.MHW = append_mld_event_mean(Basic.MHW, MLD_MHW.MHW_MLD_Table);
                Basic.MCS = append_mld_event_mean(Basic.MCS, MLD_MCS.MCS_MLD_Table);
                SeriesMLD.MHW = MLD_MHW.MHW_MLD_Table;
                SeriesMLD.MCS = MLD_MCS.MCS_MLD_Table;
                data_loaded = true;
            end
            Result = struct();
            for iEvent = 1:numel(EVENT_TYPES)
                event_type = EVENT_TYPES{iEvent};
                if strcmp(event_type, 'MHW')
                    sort_field = param.fieldMHW;
                else
                    sort_field = param.fieldMCS;
                end

                if strcmp(param.id, 'Latitude')
                    grp = get_latitude_groups(Basic.(event_type).(sort_field));
                else
                    grp = get_groups_by_count(Basic.(event_type), sort_field, param.useAbs, GROUP_PCTS);
                end
                Result.(event_type).grp = grp;
                if strcmp(response.source, 'MLD')
                    SeriesCurrent = SeriesMLD.(event_type);
                else
                    SeriesCurrent = Series.(event_type);
                end
                [Result.(event_type).abs_lags, Result.(event_type).abs_mean, Result.(event_type).abs_ci, Result.(event_type).abs_n] = ...
                    compute_dynamic_absolute_lag(Basic.(event_type), SeriesCurrent, grp, response.field, response.dateField, ...
                    event_type, DYNAMIC_ABS_MIN_LAG, BASELINE_DAYS, MIN_GROUP_N);
                [Result.(event_type).norm_mean, Result.(event_type).norm_ci, Result.(event_type).norm_n] = ...
                    compute_normalized_lag(Basic.(event_type), SeriesCurrent, grp, response.field, response.dateField, ...
                    NORM_GRID, BASELINE_DAYS, MIN_GROUP_N);
            end

            common_ylim = get_common_ylim(Result);
            cache_version = CACHE_VERSION; %#ok<NASGU>
            save(cache_file, 'Result', 'common_ylim', 'cache_version', 'cache_config', '-v7.3');
            fprintf('Saved cached Plot 03 data: %s\n', cache_file);
        end

        fig = figure('Units', 'centimeters', 'Position', [2 2 FULL_WIDTH_CM 15.5], 'Color', 'w');
        set(fig, 'Toolbar', 'none');
        tileObj = tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
        tileObj.Units = 'normalized';
        tileObj.OuterPosition = [0, 0.130, 1, 0.780];

        ax = nexttile(1); hold(ax, 'on');
        plot_lag_panel(ax, Result.MHW.abs_lags, Result.MHW.abs_mean, Result.MHW.abs_ci, Result.MHW.abs_n, ...
            current_group_labels, GROUP_COLORS.MHW, sprintf('%s absolute time', DISPLAY_EVENT_TYPES.MHW), ...
            'Lag days (0 = peak)', response.ylabel, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE, false, common_ylim);
        xlim(ax, [-abs_x_limit, abs_x_limit]);
        xticks(ax, -abs_x_limit:abs_x_tick:abs_x_limit);

        ax = nexttile(2); hold(ax, 'on');
        plot_lag_panel(ax, Result.MCS.abs_lags, Result.MCS.abs_mean, Result.MCS.abs_ci, Result.MCS.abs_n, ...
            current_group_labels, GROUP_COLORS.MCS, sprintf('%s absolute time', DISPLAY_EVENT_TYPES.MCS), ...
            'Lag days (0 = peak)', response.ylabel, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE, false, common_ylim);
        xlim(ax, [-abs_x_limit, abs_x_limit]);
        xticks(ax, -abs_x_limit:abs_x_tick:abs_x_limit);

        ax = nexttile(3); hold(ax, 'on');
        plot_lag_panel(ax, NORM_GRID, Result.MHW.norm_mean, Result.MHW.norm_ci, Result.MHW.norm_n, ...
            current_group_labels, GROUP_COLORS.MHW, sprintf('%s normalized time', DISPLAY_EVENT_TYPES.MHW), ...
            'Normalized event phase', response.ylabel, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE, false, common_ylim);
        xlim(ax, [-1, 2]);
        xticks(ax, [-1, 0, 1, 2]);
        xticklabels(ax, {'Pre', 'On', 'End', 'Post'});

        ax = nexttile(4); hold(ax, 'on');
        plot_lag_panel(ax, NORM_GRID, Result.MCS.norm_mean, Result.MCS.norm_ci, Result.MCS.norm_n, ...
            current_group_labels, GROUP_COLORS.MCS, sprintf('%s normalized time', DISPLAY_EVENT_TYPES.MCS), ...
            'Normalized event phase', response.ylabel, LINE_WIDTH, MAIN_FONT_SIZE, TITLE_FONT_SIZE, false, common_ylim);
        xlim(ax, [-1, 2]);
        xticks(ax, [-1, 0, 1, 2]);
        xticklabels(ax, {'Pre', 'On', 'End', 'Post'});

        add_shared_group_legend(tileObj, current_group_labels, GROUP_COLORS, DISPLAY_EVENT_TYPES, MAIN_FONT_SIZE);

        sgtitle(sprintf('%s response anomaly by %s', response.label, param.label), ...
            'FontName', 'Arial', 'FontSize', TITLE_FONT_SIZE, 'FontWeight', 'normal');

        set(fig, 'InvertHardcopy', 'off');
        fig_out = fullfile(out_dir, sprintf('Fig03_Lag_%s_by_%s', response.id, param.id));
        fprintf('Saving: %s.tif\n', fig_out);
        exportgraphics(fig, [fig_out, '.tif'], 'Resolution', TIFF_DPI);
        close(fig);
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
    assert(ismember(sortField, BasicT.Properties.VariableNames), 'Missing grouping field: %s', sortField);
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
        if current_group < num_groups && i > target_counts(current_group + 1) && i > 1 && sorted_s(i) > sorted_s(i - 1)
            current_group = current_group + 1;
        end
        grp(sorted_idx(i)) = current_group;
    end
end

function grp = get_latitude_groups(latValues)
    lat = double(latValues);
    if size(lat, 2) > 1
        lat = lat(:, 1);
    end
    grp = nan(size(lat));

    % L1: Northern subtropical/mid-latitude band, 15N-45N.
    grp(lat >= 15 & lat <= 45) = 1;

    % L2: Tropical band, 15S-15N.
    grp(lat > -15 & lat < 15) = 2;

    % L3: Southern subtropical/mid-latitude band, 45S-15S.
    grp(lat >= -45 & lat <= -15) = 3;
end

function [grp_lags, grp_mean, grp_ci, grp_n] = compute_dynamic_absolute_lag(BasicT, SeriesT, grp, responseField, dateField, eventType, minLag, baselineDays, minN)
    num_groups = max(grp, [], 'omitnan');
    if isempty(num_groups) || isnan(num_groups), num_groups = 3; end
    grp_lags = cell(num_groups, 1);
    grp_mean = cell(num_groups, 1);
    grp_ci = cell(num_groups, 1);
    grp_n = zeros(num_groups, 1);
    eidS = string(SeriesT.Event_ID);

    if strcmp(eventType, 'MHW')
        peak_field = 'Peak_MHW_Date';
    else
        peak_field = 'Peak_MCS_Date';
    end

    for g = 1:num_groups
        event_idx = find(grp == g);
        grp_n(g) = numel(event_idx);
        mean_duration = mean(double(BasicT.Duration(event_idx)), 'omitnan');
        if ~isfinite(mean_duration)
            continue
        end

        max_lag = max(round(mean_duration), minLag);
        lagDays = -max_lag:max_lag;
        num_lags = numel(lagDays);
        grp_lags{g} = lagDays;
        M = nan(numel(event_idx), num_lags);

        for k = 1:numel(event_idx)
            i = event_idx(k);
            j = find(eidS == string(BasicT.Event_ID(i)), 1);
            if isempty(j), continue; end

            dateVec = SeriesT.(dateField){j};
            yVec = SeriesT.(responseField){j};
            if isempty(dateVec) || isempty(yVec), continue; end

            peak_date = BasicT.(peak_field)(i);
            if ~isfinite(peak_date), continue; end

            target_dates = peak_date + lagDays;
            row = nan(1, num_lags);
            for lag_idx = 1:num_lags
                match_idx = find(dateVec == target_dates(lag_idx), 1);
                if ~isempty(match_idx)
                    row(lag_idx) = double(yVec(match_idx));
                end
            end

            t_start = BasicT.Start_Date_Idx(i);
            base_dates = t_start + baselineDays;
            [~, loc] = ismember(base_dates, dateVec);
            loc = loc(loc > 0);
            if isempty(loc)
                % baseline 窗口被完全裁掉（clip），anomaly 无定义，剔除该事件
                continue;
            end
            baseline = mean(double(yVec(loc)), 'omitnan');
            if ~isnan(baseline)
                row = row - baseline;
            end
            M(k, :) = row;
        end

        [grp_mean{g}, grp_ci{g}] = mean_ci_by_column(M, minN);
    end
end

function [grp_mean, grp_ci, grp_n] = compute_normalized_lag(BasicT, SeriesT, grp, responseField, dateField, xGrid, baselineDays, minN)
    num_groups = max(grp, [], 'omitnan');
    if isempty(num_groups) || isnan(num_groups), num_groups = 3; end
    num_pts = numel(xGrid);
    grp_mean = nan(num_groups, num_pts);
    grp_ci = nan(num_groups, num_pts);
    grp_n = zeros(num_groups, 1);
    eidS = string(SeriesT.Event_ID);

    NormM = nan(height(BasicT), num_pts);
    for i = 1:height(BasicT)
        j = find(eidS == string(BasicT.Event_ID(i)), 1);
        if isempty(j), continue; end

        dateVec = SeriesT.(dateField){j};
        yVec = SeriesT.(responseField){j};
        if isempty(dateVec) || isempty(yVec), continue; end

        t_start = BasicT.Start_Date_Idx(i);
        t_end = BasicT.End_Date_Idx(i);
        if ~isfinite(t_start) || ~isfinite(t_end) || t_end < t_start, continue; end

        norm_t = nan(size(dateVec));
        pre = dateVec < t_start;
        during = dateVec >= t_start & dateVec <= t_end;
        post = dateVec > t_end;
        norm_t(pre) = (dateVec(pre) - t_start) / 30;
        if t_end == t_start
            norm_t(during) = 0.5;
        else
            norm_t(during) = (dateVec(during) - t_start) / (t_end - t_start);
        end
        norm_t(post) = 1 + (dateVec(post) - t_end) / 30;

        valid = ~isnan(yVec);
        if sum(valid) <= 2, continue; end

        [u_norm_t, ia] = unique(norm_t(valid));
        u_y = double(yVec(valid));
        u_y = u_y(ia);
        if numel(u_norm_t) >= 3
            NormM(i, :) = interp1(u_norm_t, u_y, xGrid, 'linear', NaN);
        end

        base_dates = t_start + baselineDays;
        [~, loc] = ismember(base_dates, dateVec);
        loc = loc(loc > 0);
        if isempty(loc)
            % baseline 窗口被完全裁掉（clip），anomaly 无定义，剔除该事件
            NormM(i, :) = NaN;
            continue;
        end
        baseline = mean(double(yVec(loc)), 'omitnan');
        if ~isnan(baseline)
            NormM(i, :) = NormM(i, :) - baseline;
        end
    end

    for g = 1:num_groups
        idx = find(grp == g);
        grp_n(g) = numel(idx);
        [grp_mean(g, :), grp_ci(g, :)] = mean_ci_by_column(NormM(idx, :), minN);
    end
end

function baseline = get_baseline_mean(dateVec, yVec, startDate, baselineDays)
    baseline = NaN;
    if ~isfinite(startDate)
        return
    end
    base_dates = startDate + baselineDays;
    [tf, loc] = ismember(base_dates, dateVec);
    if any(tf)
        base_values = double(yVec(loc(tf)));
        baseline = mean(base_values, 'omitnan');
    end
end

function [m, ci] = mean_ci_by_column(M, minN)
    n_cols = size(M, 2);
    m = nan(1, n_cols);
    ci = nan(1, n_cols);
    for c = 1:n_cols
        x = M(:, c);
        x = x(isfinite(x));
        if numel(x) >= minN
            m(c) = mean(x);
            ci(c) = 1.96 * std(x) / sqrt(numel(x));
        end
    end
end

function lim = get_common_ylim(Result)
    vals = [];
    event_types = {'MHW', 'MCS'};
    time_types = {'abs', 'norm'};
    for iEvent = 1:numel(event_types)
        event_type = event_types{iEvent};
        for iTime = 1:numel(time_types)
            time_type = time_types{iTime};
            mean_field = [time_type, '_mean'];
            ci_field = [time_type, '_ci'];
            M = Result.(event_type).(mean_field);
            C = Result.(event_type).(ci_field);
            if iscell(M)
                for g = 1:numel(M)
                    if isempty(M{g}) || isempty(C{g}), continue; end
                    vals = [vals; M{g}(:) + C{g}(:); M{g}(:) - C{g}(:)]; %#ok<AGROW>
                end
            else
                vals = [vals; M(:) + C(:); M(:) - C(:)]; %#ok<AGROW>
            end
        end
    end
    vals = vals(isfinite(vals));
    if isempty(vals)
        lim = [-1, 1];
        return
    end
    max_abs = max(abs(vals));
    if max_abs == 0 || ~isfinite(max_abs)
        max_abs = 1;
    end
    max_abs = max_abs * 1.08;
    lim = [-max_abs, max_abs];
end

function plot_lag_panel(ax, x, grpMean, grpCI, grpN, groupLabels, colors, panelTitle, xLabelText, yLabelText, lineWidth, mainFontSize, titleFontSize, showLegend, commonYLim)
    axes(ax); %#ok<LAXES>
    hold(ax, 'on');
    box(ax, 'on');
    grid(ax, 'off');

    if iscell(x)
        non_empty_x = x(~cellfun('isempty', x));
        all_x = [non_empty_x{:}];
    else
        all_x = x;
    end
    if isempty(all_x)
        all_x = [0, 1];
    end

    if min(all_x) < 0 && max(all_x) > 0
        xline(ax, 0, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth);
    end
    if min(all_x) < 1 && max(all_x) > 1 && max(all_x) <= 2
        xline(ax, 1, '--', 'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth);
    end

    if iscell(grpMean)
        num_groups = numel(grpMean);
    else
        num_groups = size(grpMean, 1);
    end

    h = gobjects(num_groups, 1);
    legend_text = strings(num_groups, 1);
    for g = num_groups:-1:1
        if iscell(grpMean)
            xg = x{g};
            y = grpMean{g};
            ci = grpCI{g};
        else
            xg = x;
            y = grpMean(g, :);
            ci = grpCI(g, :);
        end
        if isempty(xg) || isempty(y) || isempty(ci), continue; end
        valid = isfinite(y) & isfinite(ci);
        if sum(valid) < 2, continue; end

        xv = xg(valid);
        yv = y(valid);
        civ = ci(valid);
        fill(ax, [xv, fliplr(xv)], [yv + civ, fliplr(yv - civ)], colors(g, :), ...
            'FaceAlpha', 0.18, 'EdgeColor', 'none');
        h(g) = plot(ax, xv, yv, '-', 'Color', colors(g, :), 'LineWidth', 1.5);
        legend_text(g) = sprintf('%s, N=%d', groupLabels{g}, grpN(g));
    end

    title(ax, panelTitle, 'FontWeight', 'normal', 'FontSize', titleFontSize);
    xlabel(ax, xLabelText);
    ylabel(ax, yLabelText);
    set(ax, 'LineWidth', lineWidth, 'FontSize', mainFontSize, 'TickDir', 'out', ...
        'FontName', 'Arial');
    ylim(ax, commonYLim);
    yMax = max(abs(commonYLim));
    if isfinite(yMax) && yMax > 0
        ax.YAxis.Exponent = floor(log10(yMax));
    end
    ytickformat(ax, '%.1f');

    if numel(all_x) > 10
        xlim(ax, [min(all_x), max(all_x)]);
    end

    valid_h = isgraphics(h);
    if showLegend && any(valid_h)
        lgd = legend(ax, h(valid_h), legend_text(valid_h), 'Location', 'southoutside', ...
            'Orientation', 'vertical', 'Box', 'on', 'FontSize', mainFontSize);
        set(lgd, 'LineWidth', 0.5);
    end
end

function add_shared_group_legend(tileObj, groupLabels, colors, displayEventTypes, mainFontSize)
    num_groups = numel(groupLabels);
    fig = tileObj.Parent;
    legAx = axes(fig, 'Units', 'normalized', ...
        'Position', [0.12, 0.060, 0.76, 0.070], ...
        'Visible', 'off', ...
        'Color', 'none', ...
        'XLim', [0, 1], ...
        'YLim', [0, 1]);
    hold(legAx, 'on');

    rectangle(legAx, 'Position', [0.02, 0.08, 0.96, 0.84], ...
        'EdgeColor', [0.15, 0.15, 0.15], ...
        'LineWidth', 0.5, ...
        'FaceColor', 'none');

    event_ids = {'MHW', 'MCS'};
    event_y = [0.66, 0.34];
    item_width = 0.74 / num_groups;
    item_start = 0.22 + (0:num_groups-1) * item_width;
    for iEvent = 1:numel(event_ids)
        event_type = event_ids{iEvent};
        text(legAx, 0.06, event_y(iEvent), displayEventTypes.(event_type), ...
            'Units', 'data', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', ...
            'FontSize', mainFontSize, ...
            'Color', [0.10, 0.10, 0.10]);
        for g = 1:num_groups
            x0 = item_start(g);
            plot(legAx, [x0, x0 + 0.055], [event_y(iEvent), event_y(iEvent)], '-', ...
                'Color', colors.(event_type)(g, :), ...
                'LineWidth', 1.5);
            text(legAx, x0 + 0.070, event_y(iEvent), groupLabels{g}, ...
                'Units', 'data', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'middle', ...
                'FontName', 'Arial', ...
                'FontSize', mainFontSize, ...
                'Color', [0.10, 0.10, 0.10]);
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
