function [ diff_evoked ] = lfp_tfa_compute_diff_condition_evoked( lfp_evoked, diff_condition, diff_color, diff_legend )
%lfp_tfa_compute_diff_tfr - function to compute the difference in time freq
%response between control and inactivation trials
%
% USAGE:
%	diff_tfr = lfp_tfa_compute_diff_tfr( lfp_tfr, lfp_tfa_cfg )
%
% INPUTS:
%       lfp_tfr         - struct containing the condition-based average LFP time freq spectrogram
%       for individual sites or average across sites or average across
%       sessions, see lfp_tfa_site_average_tfr,
%       lfp_tfa_avg_tfr_across_sessions, lfp_tfa_avg_across_sites
%		lfp_tfa_cfg     - struct containing the required settings
%
% OUTPUTS:
%		diff_tfr        - struct containing the condition-based LFP time freq spectrogram
%       average difference between post and pre injection
%
% REQUIRES:	
%
% See also lfp_tfa_site_average_tfr, lfp_tfa_avg_tfr_across_sessions, lfp_tfa_avg_across_sites 
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

    conditions = [lfp_evoked.cfg_condition];
    
    cfg_condition1 = struct();
    cfg_condition2 = struct();
    
    for i = 1:length(diff_condition)/2
        diff_evoked = struct();
        compare.field = diff_condition{1, 2*(i-1) + 1};
        compare.values = diff_condition{1, 2*(i-1) + 2};
        % check if conditions to compare exist
        if strcmp(compare.field, 'perturbation')
            if sum([compare.values{:}] == unique([conditions.perturbation])) < 2
                continue;
            end
        elseif strcmp(compare.field, 'choice')
            if sum([compare.values{:}] == unique([conditions.choice])) < 2
                continue;
            end
        elseif strcmp(compare.field, 'success')
            if sum([compare.values{:}] == unique([conditions.success])) < 2
                continue;
            end
        elseif strcmp(compare.field, 'type_eff')
            if sum(ismember(vertcat(compare.values{:}), ...
                unique([conditions.type; conditions.effector]', 'rows'), 'rows')) < 2
                continue;
            end
        end
    
        dcn = 0;
        traversed_idx = [];
        for cn = 1:length(lfp_evoked)
            condition_found = false;
            if strcmp(compare.field, 'choice')
                condition_found = lfp_evoked(cn).cfg_condition.choice == compare.values{1};

            elseif strcmp(compare.field, 'perturbation')
                condition_found = lfp_evoked(cn).cfg_condition.perturbation == compare.values{1};
            
            elseif strcmp(compare.field, 'success')
                condition_found = lfp_evoked(cn).cfg_condition.success == compare.values{1};
                
            elseif strcmp(compare.field, 'type_eff')
                condition_found = lfp_evoked(cn).cfg_condition.type == compare.values{1}(1) ...
                    & lfp_evoked(cn).cfg_condition.effector == compare.values{1}(2);

            end
            % initially load the pre-injection data structure
            if condition_found
                traversed_idx = [traversed_idx cn];            
            else
                continue;
            end
            for d = 1:length(lfp_evoked)
                if any(traversed_idx == d), continue; end
                comparison_pair_found = false;

                if strcmp(compare.field, 'choice')
                    comparison_pair_found = lfp_evoked(d).cfg_condition.type == lfp_evoked(cn).cfg_condition.type ...
                        & lfp_evoked(d).cfg_condition.effector == lfp_evoked(cn).cfg_condition.effector ...
                        & lfp_evoked(d).cfg_condition.choice == compare.values{2} ...
                        & lfp_evoked(d).cfg_condition.perturbation == lfp_evoked(cn).cfg_condition.perturbation ...
                        & lfp_evoked(d).cfg_condition.success == lfp_evoked(cn).cfg_condition.success;

                elseif strcmp(compare.field, 'perturbation')
                    comparison_pair_found = lfp_evoked(d).cfg_condition.type == lfp_evoked(cn).cfg_condition.type ...
                        & lfp_evoked(d).cfg_condition.effector == lfp_evoked(cn).cfg_condition.effector ...
                        & lfp_evoked(d).cfg_condition.choice == lfp_evoked(cn).cfg_condition.choice ...
                        & lfp_evoked(d).cfg_condition.perturbation == compare.values{2} ...
                        & lfp_evoked(d).cfg_condition.success == lfp_evoked(cn).cfg_condition.success;
                    
                elseif strcmp(compare.field, 'success')
                    comparison_pair_found = lfp_evoked(d).cfg_condition.type == lfp_evoked(cn).cfg_condition.type ...
                        & lfp_evoked(d).cfg_condition.effector == lfp_evoked(cn).cfg_condition.effector ...
                        & lfp_evoked(d).cfg_condition.choice == lfp_evoked(cn).cfg_condition.choice ...
                        & lfp_evoked(d).cfg_condition.success == compare.values{2} ...
                        & lfp_evoked(d).cfg_condition.perturbation == lfp_evoked(cn).cfg_condition.perturbation;
                    
                elseif strcmp(compare.field, 'type_eff')
                    comparison_pair_found = lfp_evoked(d).cfg_condition.type == compare.values{2}(1) ...
                        & lfp_evoked(d).cfg_condition.effector == compare.values{2}(2) ...
                        & lfp_evoked(d).cfg_condition.choice == lfp_evoked(cn).cfg_condition.choice ...
                        & lfp_evoked(d).cfg_condition.success == lfp_evoked(cn).cfg_condition.success ...
                        & lfp_evoked(d).cfg_condition.perturbation == lfp_evoked(cn).cfg_condition.perturbation;
                end
                if comparison_pair_found

                    dcn = dcn + 1;
                    %diff_tfr.difference(dcn) = struct();
                    % pre injection
                    cond1_evoked = lfp_evoked(cn);
                    if isempty(cond1_evoked.hs_tuned_evoked) 
                        continue;
                    end
                    % post injection
                    cond2_evoked = lfp_evoked(d);
                    if isempty(cond2_evoked.hs_tuned_evoked)
                        continue;
                    end

                    if ~isfield(cond2_evoked.hs_tuned_evoked, 'mean')
                        continue;
                    end
                    
                    diff_evoked.difference(dcn) = cond2_evoked;
                    
                                      
                    diff_evoked.difference(dcn).cfg_condition = cond2_evoked.cfg_condition;
                    
                    plot_legend = cell(1,2);
%                     if strcmp(compare.field, 'choice')                        
%                         diff_evoked.difference(dcn).cfg_condition.choice = ['diff' num2str(i)];
%                         cfg_condition1.choice = cond2_evoked.cfg_condition.choice;
%                         cfg_condition2.choice = cond1_evoked.cfg_condition.choice;
%                         legend{1} = lfp_tfa_get_condition_label(cfg_condition1, 'long');
%                         legend{2} = lfp_tfa_get_condition_label(cfg_condition2, 'long');
%                     elseif strcmp(compare.field, 'perturbation')
%                         diff_evoked.difference(dcn).cfg_condition.perturbation = ['diff' num2str(i)];
%                         cfg_condition1.perturbation = cond2_evoked.cfg_condition.perturbation;
%                         cfg_condition2.perturbation = cond1_evoked.cfg_condition.perturbation;
%                         legend{1} = lfp_tfa_get_condition_label(cfg_condition1, 'long');
%                         legend{2} = lfp_tfa_get_condition_label(cfg_condition2, 'long');
%                     elseif strcmp(compare.field, 'success')
%                         diff_evoked.difference(dcn).cfg_condition.success = ['diff' num2str(i)];
%                         cfg_condition1.success = cond2_evoked.cfg_condition.success;
%                         cfg_condition2.success = cond1_evoked.cfg_condition.success;
%                         legend{1} = lfp_tfa_get_condition_label(cfg_condition1, 'long');
%                         legend{2} = lfp_tfa_get_condition_label(cfg_condition2, 'long');
%                     elseif strcmp(compare.field, 'type_eff')
%                         diff_evoked.difference(dcn).cfg_condition.type_eff = ['diff' num2str(i)];
%                         cfg_condition1.type = cond2_evoked.cfg_condition.type;
%                         cfg_condition1.effector = cond2_evoked.cfg_condition.effector;
%                         cfg_condition2.type = cond1_evoked.cfg_condition.type;
%                         cfg_condition2.effector = cond1_evoked.cfg_condition.effector;
%                         legend{1} = lfp_tfa_get_condition_label(cfg_condition1, 'long');
%                         legend{2} = lfp_tfa_get_condition_label(cfg_condition2, 'long');
%                     end
                    if nargin > 3 && ~isempty(diff_legend)
                        plot_legend = diff_legend;
                    end
                    
                    % change the condition label
                    diff_evoked.difference(dcn).label = lfp_tfa_get_condition_label(...
                        diff_evoked.difference(dcn).cfg_condition, 'long'); 
                    
                    % loop through handspace tunings
                    diff_evoked.difference(dcn).hs_tuned_evoked = cond2_evoked.hs_tuned_evoked;
                    for hs = 1:size(cond2_evoked.hs_tuned_evoked, 2)
                        for st = 1:size(cond2_evoked.hs_tuned_evoked, 1)
                            
                            if isfield(cond1_evoked.hs_tuned_evoked(st, hs), 'mean') && ...
                                    isfield(cond2_evoked.hs_tuned_evoked(st, hs), 'mean') && ...
                                    ~isempty(cond1_evoked.hs_tuned_evoked(st, hs).mean) && ...
                                ~isempty(cond2_evoked.hs_tuned_evoked(st, hs).mean)
                                ntimebins = min([length(cond2_evoked.hs_tuned_evoked(st, hs).time), ...
                                    length(cond1_evoked.hs_tuned_evoked(st, hs).time)]);
                                % calculate the difference
%                                 diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).lfp = ...
%                                     cat(cond2_evoked.hs_tuned_evoked(st, hs).lfp(:,1:ntimebins), ...
%                                     cond1_evoked.hs_tuned_evoked(st, hs).lfp(:,1:ntimebins));
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).mean = ...
                                    [cond2_evoked.hs_tuned_evoked(st, hs).mean(:,1:ntimebins); ...
                                    cond1_evoked.hs_tuned_evoked(st, hs).mean(:,1:ntimebins)];
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).std = ...
                                    [cond2_evoked.hs_tuned_evoked(st, hs).std(:,1:ntimebins); ...
                                    cond1_evoked.hs_tuned_evoked(st, hs).std(:,1:ntimebins)];
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).time = ...
                                    cond2_evoked.hs_tuned_evoked(st, hs).time(1:ntimebins);  
                                if isfield(cond2_evoked.hs_tuned_evoked(st, hs), 'ntrials')
                                    diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).ntrials = ...
                                        [];
                                elseif isfield(cond2_evoked.hs_tuned_evoked(st, hs), 'npeaks')
                                    diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).npeaks = ...
                                        [];
                                end
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).legend = ...
                                    plot_legend;
                                
                                if nargin > 2 && ~isempty(diff_color)
                                    diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).color = ...
                                        diff_color;
                                end
                                
                            else
                                %diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).lfp = [];
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).time = [];
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).mean = [];
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).std = [];
                                diff_evoked.difference(dcn).hs_tuned_evoked(st, hs).legend = [];
                            end
                        end
                    end
                else
                    continue;
                end
            end
        end
        if isfield(diff_evoked, 'difference')
            lfp_evoked = diff_evoked.difference;
        end
    end
    
    % generate return variable
    if isfield(diff_evoked, 'difference')
        diff_evoked = diff_evoked.difference;
    else
        diff_evoked = [];
    end
end
