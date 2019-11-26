function sessions_avg = lfp_tfa_avg_sessions_ECGb2bt_evoked(ecg_b2bt_evoked, lfp_tfa_cfg)
%lfp_tfa_avg_evoked_LFP_across_sessions  - Condition-based evoked LFP response
% average across many session averages
%
% USAGE:
%	sessions_avg = lfp_tfa_avg_sessions_ECG_evoked(evoked_ecg, lfp_tfa_cfg)
%
% INPUTS:
%		lfp_evoked		- struct containing the condition-based evoked LFP response for
%		indiviual sites, output of lfp_tfa_plot_site_evoked_LFP.m
%           Required Fields:
%               1. session.session_avg - 1xN struct containing condition-based
%               average evoked LFP response for N sessions (session_avg =
%               Average of site averages for one session)
%		lfp_tfa_cfg     - struct containing the required settings
%           Required Fields:
%               1. conditions          - trial conditions to compare, see
%               lfp_tfa_settings.m and lfp_tfa_compare_conditions.m
%               2. root_results_fldr   - root folder where results are saved
%               3. compare.targets     - targets to compare, see lfp_tfa_settings.m
%               4. ref_hemisphere      - reference hemisphere for ipsi and
%               contra labeling
% OUTPUTS:
%		sessions_avg    - structure containing condition-based evoked LFP
%		response averaged across multiple sessions
%
% REQUIRES:	lfp_tfa_plot_evoked_lfp
%
% See also lfp_tfa_settings, lfp_tfa_define_settings, lfp_tfa_compare_conditions, 
% lfp_tfa_plot_site_evoked_LFP
%
% Author(s):	S.Nair, DAG, DPZ
% URL:		http://www.dpz.eu/dag
%
% Change log:
% 2019-02-15:	Created function (Sarath Nair)
% 2019-03-05:	First Revision
% ...
% $Revision: 1.0 $  $Date: 2019-03-05 17:18:00 $

% ADDITIONAL INFO:
% ...
%%%%%%%%%%%%%%%%%%%%%%%%%[DAG mfile header version 1]%%%%%%%%%%%%%%%%%%%%%%%%%


    % results folder
    results_fldr = fullfile(lfp_tfa_cfg.root_results_fldr, 'ECG analysis');
    if ~exist(results_fldr, 'dir')
        mkdir(results_fldr);
    end
    
    % Average Evoked LFP response across sessions
    sessions_avg = struct();
    t = 1;
    
    for cn = 1:length(lfp_tfa_cfg.conditions)
        fprintf('Condition %s\n', lfp_tfa_cfg.conditions(cn).label);
        sessions_avg(t).condition(cn).hs_tuned_evoked = struct();
        sessions_avg(t).condition(cn).cfg_condition = lfp_tfa_cfg.conditions(cn);
        sessions_avg(t).condition(cn).label = lfp_tfa_cfg.conditions(cn).label;
        
        % initialize number of site pairs for each handspace
        % label
        for st = 1:size(ecg_b2bt_evoked.session(end).condition(cn).hs_tuned_evoked, 1)
            for hs = 1:size(ecg_b2bt_evoked.session(end).condition(cn).hs_tuned_evoked, 2)
                sessions_avg(t).condition(cn).hs_tuned_evoked(st, hs).nsessions = 0;
                sessions_avg(t).condition(cn).hs_tuned_evoked(st, hs).ecg_b2bt = {};                
            end
        end  

        for i = 1:length(ecg_b2bt_evoked.session)
            if isempty(ecg_b2bt_evoked.session(i).condition)
                continue;
            end
            if isfield(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked, 'mean')
                for st = 1:size(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked, 1)
                    for hs = 1:size(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked, 2)
                        if isfield(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs), 'mean') ...
                                && ~isempty(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs).mean)
                            sessions_avg(t).condition(cn).hs_tuned_evoked(st, hs).nsessions = ...
                                sessions_avg(t).condition(cn).hs_tuned_evoked(st, hs).nsessions + 1;
                            if sessions_avg(t).condition(cn).hs_tuned_evoked(st, hs).nsessions == 1
                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).time ...
                                    = ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs).time;
                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).hs_label ...
                                    = ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs).hs_label;
                                if isfield(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs), 'state') && ...
                                        isfield(ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs), 'state_name')
                                    sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).state ...
                                        = ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs).state;
                                    sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).state_name ...
                                        = ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs).state_name;
                                end
                            end
                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt ...
                                = [sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt, ...
                                ecg_b2bt_evoked.session(i).condition(cn).hs_tuned_evoked(st, hs).mean];  
                        else
                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs) = struct();
                        end
                    end
                end
            end                               
        end

        % compute average
        if isfield(sessions_avg(t).condition(cn).hs_tuned_evoked, 'ecg_b2bt')
            for st = 1:size(sessions_avg(t).condition(cn).hs_tuned_evoked, 1)
                for hs = 1:size(sessions_avg(t).condition(cn).hs_tuned_evoked, 2)
                    if ~isempty(sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt)
                        sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt = ...
                            cat(1, sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt{:});
                        sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).dimord = 'nsessions_time';
%                         sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt(...
%                             :, isnan(sum(sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt, 1))) = nan;
                        sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).std = ...
                            std(sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt, 0, 1);
                        sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean = ...
                            mean(sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).ecg_b2bt, 1);                           
                    end
                end
            end
        end


        if ~isempty(sessions_avg(t).condition(cn).hs_tuned_evoked)
            if isfield(sessions_avg(t).condition(cn).hs_tuned_evoked,... 
                    'mean')
                plottitle = [lfp_tfa_cfg.compare.targets{t},...
                     lfp_tfa_cfg.conditions(cn).label];
                result_file = fullfile(results_fldr, ...
                                ['ECG_b2bt_Evoked_' lfp_tfa_cfg.conditions(cn).label]);
                lfp_tfa_plot_evoked_R2Rt(sessions_avg(t).condition(cn).hs_tuned_evoked, ...
                            lfp_tfa_cfg, plottitle, result_file);
            end
        end
        
    end

    % difference between conditions
    sessions_avg(t).difference = [];
    for diff = 1:size(lfp_tfa_cfg.diff_condition, 2)
        diff_condition = lfp_tfa_cfg.diff_condition{diff};
        diff_color = []; diff_legend = [];
        if isfield(lfp_tfa_cfg, 'diff_color')
            diff_color = lfp_tfa_cfg.diff_color{diff};
        end
        if isfield(lfp_tfa_cfg, 'diff_legend')
            diff_legend = lfp_tfa_cfg.diff_legend{diff};
        end
        sessions_avg(t).difference = [sessions_avg(t).difference, ...
            lfp_tfa_compute_diff_condition_R2Rt_evoked(sessions_avg(t).condition, diff_condition, diff_color,diff_legend)];
    end
    % plot Difference TFR
    for dcn = 1:length(sessions_avg(t).difference)
        if ~isempty(sessions_avg(t).difference(dcn).hs_tuned_evoked)
            if isfield(sessions_avg(t).difference(dcn).hs_tuned_evoked,... 
                    'mean')
                plottitle = ['Target ', lfp_tfa_cfg.compare.targets{t}, ...
                    sessions_avg(t).difference(dcn).label];
                result_file = fullfile(results_fldr, ...
                    ['ECG_b2bt_DiffEvoked_' 'diff_condition' num2str(dcn)]);
                    %sessions_avg(t).difference(dcn).label '.png']);
                lfp_tfa_plot_evoked_R2Rt(sessions_avg(t).difference(dcn).hs_tuned_evoked, ...
                    lfp_tfa_cfg, plottitle, result_file);
            end
        end
    end
    
    % save session average tfs
    save(fullfile(results_fldr, 'sessions_evoked_ECG.mat'), 'sessions_avg');
        
    close all;
end