function sessions_avg = lfp_tfa_avg_sessions_Rpeak_evoked_LFP(lfp_evoked, lfp_tfa_cfg)
%lfp_tfa_avg_evoked_LFP_across_sessions  - Condition-based evoked LFP response
% average across many session averages
%
% USAGE:
%	sessions_avg = lfp_tfa_avg_evoked_LFP_across_sessions(lfp_evoked, lfp_tfa_cfg)
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
    results_fldr = fullfile(lfp_tfa_cfg.root_results_fldr, 'Avg_across_sessions', 'LFP_Evoked');
    if ~exist(results_fldr, 'dir')
        mkdir(results_fldr);
    end
    
    % Average Evoked LFP response across sessions
    sessions_avg = struct();
    
    for t = 1:length(lfp_tfa_cfg.compare.targets)
        sessions_avg(t).target = lfp_tfa_cfg.compare.targets{t};        
        for cn = 1:length(lfp_tfa_cfg.conditions)
            fprintf('Condition %s\n', lfp_tfa_cfg.conditions(cn).label);
            sessions_avg(t).condition(cn).avg_across_sessions = struct();
            sessions_avg(t).condition(cn).cfg_condition = lfp_tfa_cfg.conditions(cn);
            sessions_avg(t).condition(cn).label = lfp_tfa_cfg.conditions(cn).label;
                        
            nsessions = 0;
            for i = 1:length(lfp_evoked.session)
                for k = 1:length(lfp_evoked.session(i).session_avg)
                    if strcmp(lfp_evoked.session(i).session_avg(k).target, lfp_tfa_cfg.compare.targets{t})
                        if ~isempty(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked) && ... 
                            isfield(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked, 'mean')
                            nsessions = nsessions + 1;   
                            for st = 1:size(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked, 1)
                                for hs = 1:size(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked, 2)
                                    if isfield(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs), 'mean') ...
                                            && ~isempty(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).mean)
                                        if nsessions == 1%~isfield(sessions_avg(t).condition(cn).avg_across_sessions, 'mean')
                                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).time ...
                                                = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).time;
                                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).hs_label ...
                                                = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).hs_label;
                                            if isfield(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs), 'state') && ...
                                                    isfield(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs), 'state_name')
                                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).state ...
                                                    = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).state;
                                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).state_name ...
                                                    = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).state_name;
                                            end
                                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean ...
                                                = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).mean;
                                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).std ...
                                                = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).std;                                
                                            if isfield(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs), 'nsites')
                                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).nsites ...
                                                    = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).nsites;
                                            end
                                        else
                                            ntimebins = length(sessions_avg(t).condition(cn).hs_tuned_evoked(st, hs).time);
                                            % average same number of time bins
                                            if ntimebins > length(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).time)
                                                ntimebins = length(lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).time);
                                            end
                                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean ...
                                                = (lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).mean(1:ntimebins)) + ...
                                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean(1:ntimebins);
                                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).std ...
                                                = (lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).std(1:ntimebins)) + ...
                                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).std(1:ntimebins);
                                            if isfield(sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs), 'nsites')
                                                sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).nsites ...
                                                    = lfp_evoked.session(i).session_avg(k).condition(cn).hs_tuned_evoked(st, hs).nsites + ...
                                                    sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).nsites;
                                            end                               
                                        end
                                    end
                                end
                            end
                        end
                    else
                        continue;
                    end                    
                end
            end

            % compute average
            if isfield(sessions_avg(t).condition(cn).hs_tuned_evoked, 'mean')
                for st = 1:size(sessions_avg(t).condition(cn).hs_tuned_evoked, 1)
                    for hs = 1:size(sessions_avg(t).condition(cn).hs_tuned_evoked, 2)
                        if ~isempty(sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean)
                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).nsessions = nsessions;  
                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).std = ...
                                (1/nsessions) * sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).std;
                            sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean = ...
                                (1/nsessions) * sessions_avg(t).condition(cn).hs_tuned_evoked(st,hs).mean;                            
                        end
                    end
                end
            end


            if ~isempty(sessions_avg(t).condition(cn).hs_tuned_evoked)
                if isfield(sessions_avg(t).condition(cn).hs_tuned_evoked,... 
                        'mean')
                    plottitle = [lfp_tfa_cfg.compare.targets{t},...
                         '(ref_' lfp_tfa_cfg.ref_hemisphere, ')', ...
                         lfp_tfa_cfg.conditions(cn).label];
                    result_file = fullfile(results_fldr, ...
                                    ['LFP_Evoked_' sessions_avg(t).target '_' ...
                                    lfp_tfa_cfg.conditions(cn).label '.png']);
                    lfp_tfa_plot_evoked_lfp(sessions_avg(t).condition(cn).hs_tuned_evoked, ...
                                lfp_tfa_cfg, plottitle, result_file);
                end
            end
            % save session average tfs
            save(fullfile(results_fldr, 'sessions_average_evoked.mat'), 'sessions_avg');
        end
        
        % difference between conditions
        sessions_avg(t).difference = [];
        for diff = 1:size(lfp_tfa_cfg.diff_condition, 2)
            diff_condition = lfp_tfa_cfg.diff_condition{diff};
            sessions_avg(t).difference = [sessions_avg(t).difference, ...
                lfp_tfa_compute_diff_condition_evoked(sessions_avg(t).condition, diff_condition)];
        end
        % plot Difference TFR
        for dcn = 1:length(sessions_avg(t).difference)
            if ~isempty(sessions_avg(t).difference(dcn).hs_tuned_evoked)
                if isfield(sessions_avg(t).difference(dcn).hs_tuned_evoked,... 
                        'mean')
                    plottitle = ['Target ', lfp_tfa_cfg.compare.targets{t}, ...
                    ' (ref_', lfp_tfa_cfg.ref_hemisphere, ') ', ...
                    sessions_avg(t).difference(dcn).label];
                    result_file = fullfile(results_fldr, ...
                        ['LFP_DiffEvoked_' lfp_tfa_cfg.compare.targets{t} ...
                        '_' 'diff_condition' num2str(dcn) '.png']);
                        %sessions_avg(t).difference(dcn).label '.png']);
                    lfp_tfa_plot_evoked_lfp(sessions_avg(t).difference(dcn).hs_tuned_evoked, ...
                        lfp_tfa_cfg, plottitle, result_file);
                end
            end
        end
        
    end
    close all;
end