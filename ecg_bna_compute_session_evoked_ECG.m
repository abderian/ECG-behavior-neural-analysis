function [ session_evoked_ecg ] = ...
    ecg_bna_compute_session_evoked_ECG( session_ecg, session_info, analyse_states, ecg_bna_cfg ) 

% ecg_bna_plot_average_evoked_LFP  - plots average evoked LFP for
% different hand-space tuning conditions for each site and across all sites
% of a session
%
% USAGE:
%	[ session_evoked ] = ecg_bna_plot_site_evoked_LFP( states_lfp, analyse_states, ecg_bna_cfg ) 
%
% INPUTS:
%		states_lfp  	- struct containing raw lfp data for all sites of a 
%       session, output from ecg_bna_process_lfp or
%       ecg_bna_compute_baseline or ecg_bna_reject_noisy_lfp
%       analyse_states  - cell array containing states to be
%       analysed and corresponding time windows
%       ecg_bna_cfg     - struct containing configuration for TFR 
%           Required fields:
%               session_results_fldr            - folder to which the
%               results of the session should be saved
%               mintrials_percondition          - minimum number of trials
%               required per condition for considering the site for
%               averaging
%               analyse_states                  - states to analyse 
%
% OUTPUTS:
%		session_evoked	- output structure which saves the average evoked LFP for  
%                         trials of a given condition for different handspace 
%                         tunings and periods around the states analysed
% 
% REQUIRES:	ecg_bna_compare_conditions, ecg_bna_plot_evoked_lfp
%
% See also ecg_bna_process_lfp, ecg_bna_compute_baseline, ecg_bna_reject_noisy_lfp, 
% ecg_bna_compare_conditions, ecg_bna_plot_evoked_lfp
    
    % suppress warning for xticklabel
    warning ('off', 'MATLAB:hg:willberemoved');

    % make a folder to save figures
    results_folder_evoked = fullfile(session_info.analyse_ecg_fldr, 'Rpeak_evoked_ECG');
    if ~exist(results_folder_evoked, 'dir')
        mkdir(results_folder_evoked);
    end
       
    % condition based Evoked
    sites_evoked = struct();
    session_evoked_ecg = struct();
    session_evoked_ecg.session = session_ecg(1).session;
    
    % get trial conditions for this session
    site_conditions = lfp_tfa_compare_conditions(ecg_bna_cfg, {0, 1});
    
    % loop through each site
    for i = 1:length(session_ecg) 

        rng(ecg_bna_cfg.random_seed); % set random seed for reproducibility
        
        % folder to save sitewise results
        site_results_folder = fullfile(results_folder_evoked);
        if ~exist(site_results_folder, 'dir')
            mkdir(site_results_folder);
        end
        % struct to store condition-wise evoked
        sites_evoked(i).condition = struct();
        sites_evoked(i).session = session_ecg(i).session;
        % flag to indicate if this site should be used for
        % averaging based on minimum no:of trials per condition
        sites_evoked(i).use_for_avg = 1;
        
        % loop through conditions
        for cn = 1:length(site_conditions)

            % hand-space tuning of LFP
            hs_labels = site_conditions(cn).hs_labels;

            % num sites
            nsites = length(session_ecg);                 
            
            % store details of analysed condition
            sites_evoked(i).condition(cn).label = site_conditions(cn).label;
            sites_evoked(i).condition(cn).cfg_condition = site_conditions(cn);
            sites_evoked(i).condition(cn).hs_tuned_evoked = struct(); 
            sites_evoked(i).condition(cn).ntrials = zeros(1,length(hs_labels));        

            % loop through hand space labels
            for hs = 1:length(hs_labels)
                % get trial indices for the given condition
                cond_trials = lfp_tfa_get_condition_trials(session_ecg(i), site_conditions(cn));
                % filter trials by hand-space labels
                if ~strcmp(site_conditions(cn).reach_hands{hs}, 'any')
                    cond_trials = cond_trials & ...
                        strcmp({session_ecg(i).trials.reach_hand}, ...
                        site_conditions(cn).reach_hands{hs});
                end
                if ~strcmp(site_conditions(cn).reach_spaces{hs}, 'any')
                    cond_trials = cond_trials & ...
                        strcmp({session_ecg(i).trials.reach_space}, ...
                        site_conditions(cn).reach_spaces{hs});
                end
                
                sites_evoked(i).condition(cn).ntrials(hs) = sum(cond_trials);

                fprintf('Condition %s - %s\n', site_conditions(cn).label, hs_labels{hs});
                fprintf('Total number of trials %g\n', sum(cond_trials));

                sites_evoked(i).condition(cn).noisytrials(hs) = ...
                    sum(cond_trials & [session_ecg(i).trials.noisy]); 

                % consider only non noisy trials
                fprintf('Number of noisy trials %g\n', sum(cond_trials ...
                    & [session_ecg(i).trials.noisy]));
                cond_trials = cond_trials & ~[session_ecg(i).trials.noisy];

                % check if the site contains a specified minimum number
                % of trials for all conditions
                if sum(cond_trials) < ecg_bna_cfg.mintrials_percondition
                    sites_evoked(i).use_for_avg = 0;
                end
                
                if any(cond_trials)
                    cond_trials_ecg = session_ecg(i).trials(cond_trials);
                else
                    continue;
                end


                % loop through time windows around the states to analyse
                for st = 1:size(analyse_states, 1)                    
                                       
                    
                    if strcmp(analyse_states{st, 1}, 'ecg')
                        state_evoked = ecg_bna_get_Rpeak_based_STA(cond_trials_ecg, ...
                            session_ecg.session, analyse_states(st, :), 'ecg');
                        
                        if isfield(ecg_bna_cfg, 'random_permute_triggers') && ...
                                ecg_bna_cfg.random_permute_triggers
                            nshuffles = 100;
                            if isfield(ecg_bna_cfg, 'n_shuffles')
                                nshuffles = ecg_bna_cfg.n_shuffles;
                            end
                            shuffled_Rpeak_evoked = ecg_bna_get_shuffled_Rpeak_evoked_ECG(cond_trials_ecg,...
                                analyse_states(st, :), nshuffles);
                        end
%                     else 
%                         state_evoked = ecg_bna_get_state_evoked_ECG(cond_trials_ecg, ...
%                             analyse_states(st, :));    
                    end


                    if ~isempty(state_evoked.trial)

                        % save evoked ECG
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).trial = state_evoked.trial;
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).mean = state_evoked.mean;
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).std = state_evoked.std; 
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).time = state_evoked.time;
                        
                        if isfield(ecg_bna_cfg, 'random_permute_triggers') && ...
                                ecg_bna_cfg.random_permute_triggers
                            
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).shuffled_trial = ...
                                shuffled_Rpeak_evoked.trial;
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).shuffled_mean = ...
                                shuffled_Rpeak_evoked.mean;
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).shuffled_std = ...
                                shuffled_Rpeak_evoked.std;
                            
                        end
                        
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).trial_idx = find(cond_trials);
                        if strfind(state_evoked.dimord, 'npeaks')
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).npeaks = size(state_evoked.trial, 1);
                        elseif strfind(state_evoked.dimord, 'nshuffles')
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).nshuffles = size(state_evoked.trial, 1);
                        end
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).dimord = state_evoked.dimord;
                        sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).hs_label = hs_labels(hs);
                        if isfield(state_evoked, 'state_id') && isfield(state_evoked, 'state_name')
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).state = state_evoked.state_id;
                            sites_evoked(i).condition(cn).hs_tuned_evoked(st, hs).state_name = state_evoked.state_name;
                        end

                    end

                end

            end
            
            % plots
            % Evoked LFP
            if ~isempty(fieldnames(sites_evoked(i).condition(cn).hs_tuned_evoked))
                plottitle = ['Session: ', sites_evoked(i).session ...
                    site_conditions(cn).label '), '];
                if site_conditions(cn).choice == 0
                    plottitle = [plottitle 'Instructed trials'];
                elseif site_conditions(cn).choice == 1
                    plottitle = [plottitle 'Choice trials'];
                end
                result_file = fullfile(site_results_folder, ...
                    ['ECG_Evoked_' sites_evoked(i).session '_' site_conditions(cn).label '.png']);

                ecg_bna_plot_evoked_lfp (sites_evoked(i).condition(cn).hs_tuned_evoked, ecg_bna_cfg, ...
                    plottitle, result_file, 'ylabel', 'ECG amplitude');
            end

        end
        
        % difference between conditions
        sites_evoked(i).difference = [];
        for diff = 1:size(ecg_bna_cfg.diff_condition, 2)
            diff_condition = ecg_bna_cfg.diff_condition{diff};
            diff_color = []; diff_legend = [];
            if isfield(ecg_bna_cfg, 'diff_color')
                diff_color = ecg_bna_cfg.diff_color{diff};
            end
            if isfield(ecg_bna_cfg, 'diff_legend')
                diff_legend = ecg_bna_cfg.diff_legend{diff};
            end
            sites_evoked(i).difference = [sites_evoked(i).difference, ...
                ecg_bna_compute_diff_condition_average('Rpeak_evoked_ECG', ...
                sites_evoked(i).condition, diff_condition, diff_color, diff_legend)];
        end
        % plot Difference evoked
        for dcn = 1:length(sites_evoked(i).difference)
            if ~isempty(sites_evoked(i).difference(dcn).hs_tuned_evoked)
                if isfield(sites_evoked(i).difference(dcn).hs_tuned_evoked,... 
                        'mean')
                    plottitle = ['Session: ', sites_evoked(i).session ...
                        sites_evoked(i).difference(dcn).label];
                    result_file = fullfile(site_results_folder, ...
                        ['ECG_DiffEvoked_' sites_evoked(i).session ...
                        '_' 'diff_condition' num2str(dcn) '.png']);
                        %sites_avg(t).difference(dcn).label '.png']);
                    ecg_bna_plot_evoked_lfp(sites_evoked(i).difference(dcn).hs_tuned_evoked, ...
                        ecg_bna_cfg, plottitle, result_file, 'ylabel', 'ECG amplitude');
                end
            end
        end
        
        site_evoked_ecg = sites_evoked(i);
        % save mat file for site
        save(fullfile(site_results_folder, ['ECG_evoked_' sites_evoked(i).session '.mat']), 'site_evoked_ecg');
        % save to a mother struct
        session_evoked_ecg = site_evoked_ecg;
    end
        
end
        