function [session_tfs] = lfp_tfa_compute_session_Rpeak_evoked_TFS( session_proc_lfp, analyse_states, lfp_tfa_cfg ) 
% lfp_tfa_compute_plot_tfr  - compute and plot average lfp time freq
% response for different hand-space tuning conditions for each site and
% across all sites of a session
%
% USAGE:
%	[ session_tfs ] = lfp_tfa_plot_average_tfr( sites_lfp_folder, analyse_states, lfp_tfa_cfg )
%
% INPUTS:
%		states_lfp  	- folder containing lfp data for all sites of  
%       a session, output from lfp_tfa_compute_baseline
%       analyse_states  - cell array containing states to be
%       analysed, see lfp_tfa_settings
%       lfp_tfa_cfg     - struct containing configuration for TFR 
%           Required fields:
%               session_results_fldr            - folder to which the
%               results of the session should be saved
%               mintrials_percondition          - minimum number of trials
%               required per condition for considering the site for
%               averaging
%               analyse_states                  - states to analyse 
%               baseline_method                 - method used for baseline
%               normalization ('zscore', 'relchange', 'subtraction',
%               'division')
%               compare.perturbations           - perturbations to compare
%               (0 = pre-injection, 1 = post-injection)
%
% OUTPUTS:
%		session_tfs    	- output structure which saves the average tfs for  
%                         trials of a given condition for different handspace 
%                         tunings and periods around the states analysed
%
% REQUIRES:	lfp_tfa_compare_conditions, lfp_tfa_plot_hs_tuned_tfr,
% lfp_tfa_compute_diff_tfr, bluewhitered
%
% See also lfp_tfa_process_lfp, lfp_tfa_compute_baseline_power, 
% lfp_tfa_compare_conditions, lfp_tfa_compute_diff_tfr, 
% lfp_tfa_plot_hs_tuned_tfr, bluewhitered
    
    % suppress warning for xticklabel
    warning ('off', 'MATLAB:hg:willberemoved');

    % make a folder to save figures
    results_folder_tfr = fullfile(lfp_tfa_cfg.session_results_fldr, 'Condition_based_TFS');
    if ~exist(results_folder_tfr, 'dir')
        mkdir(results_folder_tfr);
    end
       
    % condition based TFS
    % struct to store TFR for each site
    sites_tfr = struct();
    % struct to accumulate TFR for each site and store session average
    session_tfs = struct();
    % session name
    session_tfs.session = session_proc_lfp(1).session;
    % get the trial conditions for this session
    site_conditions = lfp_tfa_compare_conditions(lfp_tfa_cfg, {0, 1});
        
    % loop through each site
    for i = 1:length(session_proc_lfp)
        
        rng(lfp_tfa_cfg.random_seed); % set random seed for reproducibility    
        
        site_lfp = session_proc_lfp(i);
        
        % folder to save sitewise results
        site_results_folder = fullfile(results_folder_tfr, 'sites');
        if ~exist(site_results_folder, 'dir')
            mkdir(site_results_folder);
        end
        
        % structure to store condition-wise tfs
        sites_tfr(i).condition = struct();
        % info about session and site
        sites_tfr(i).site_ID = site_lfp.site_ID;
        sites_tfr(i).session = site_lfp.session;
        sites_tfr(i).target = site_lfp.target;
        % flag to indicate if this site should be used for
        % averaging based on minimum no:of trials per condition
        sites_tfr(i).use_for_avg = 1;
        
        % loop through each condition
        for cn = 1:length(site_conditions)

            % hand-space tuning of LFP
            hs_labels = site_conditions(cn).hs_labels;
                         
            % store details of condition analysed
            sites_tfr(i).condition(cn).label = site_conditions(cn).label;
            sites_tfr(i).condition(cn).cfg_condition = site_conditions(cn);
            sites_tfr(i).condition(cn).hs_tuned_tfs = struct(); 
            sites_tfr(i).condition(cn).ntrials = zeros(1,length(hs_labels));                

            % loop through hand space labels
            for hs = 1:length(hs_labels)
                % get the trial indices which satisfy the given condition
                cond_trials = lfp_tfa_get_condition_trials(site_lfp, site_conditions(cn));
                                
                % get the trial indices which satisfy the given hand-space
                % label for the given condition
                if ~strcmp(site_conditions(cn).reach_hands{hs}, 'any')
                    cond_trials = cond_trials & ...
                        strcmp({session_proc_lfp(i).trials.reach_hand}, ...
                        site_conditions(cn).reach_hands{hs});
                end
                if ~strcmp(site_conditions(cn).reach_spaces{hs}, 'any')
                    cond_trials = cond_trials & ...
                        strcmp({session_proc_lfp(i).trials.reach_space}, ...
                        site_conditions(cn).reach_spaces{hs});
                end
                
                sites_tfr(i).condition(cn).ntrials(hs) = sum(cond_trials);

                fprintf('Condition %s - %s\n', site_conditions(cn).label, hs_labels{hs});
                fprintf('Total number of trials %g\n', sum(cond_trials));
                
                sites_tfr(i).condition(cn).noisytrials(hs) = ...
                    sum(cond_trials & [site_lfp.trials.noisy]); 

                % consider only non noisy trials
                fprintf('Number of noisy trials %g\n', sum(cond_trials ...
                    & [session_proc_lfp(i).trials.noisy]));
                cond_trials = cond_trials & ~[site_lfp.trials.noisy];

                % check if the site contains a specified minimum number
                % of trials for all conditions
                if sum(cond_trials) < lfp_tfa_cfg.mintrials_percondition
                    sites_tfr(i).use_for_avg = 0;
                end
                % loop through states to analyse 

                for st = 1:size(analyse_states, 1)
                    
%                     state_tfs = lfp_tfa_get_state_tfs(site_lfp, ...
%                             cond_trials, analyse_states(st, :), lfp_tfa_cfg);  
                        
                    if strcmp(analyse_states{st, 1}, 'ecg')
                        state_tfs = lfp_tfa_get_ECG_triggered_tfs(site_lfp, ...
                            cond_trials, analyse_states(st, :), lfp_tfa_cfg);
                    end

                    if ~isempty(state_tfs.powspctrm)

                        % save average tfs for this condition, hand-space
                        % label, and state
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm = state_tfs.powspctrm_normmean;
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm_raw = state_tfs.powspctrm;
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).time = state_tfs.time;
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).freq = state_tfs.freq; 
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).cfg = state_tfs.cfg;
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).hs_label = hs_labels(hs);
                        if isfield(state_tfs, 'state_id') && isfield(state_tfs, 'state_name')
                            sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).state = state_tfs.state_id;
                            sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).state_name = state_tfs.state_name;
                        end
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).trials = find(cond_trials);
                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).ntrials = length(find(cond_trials));
                    end

                end

            end

            
            % plot TFR
            if ~isempty(fieldnames(sites_tfr(i).condition(cn).hs_tuned_tfs))
                if site_conditions(cn).perturbation == 0
                    injection = 'Pre';
                elseif site_conditions(cn).perturbation == 1
                    injection = 'Post';
                else
                    injection = 'Any';
                end
                plottitle = ['LFP TFR (' injection '): Site ' sites_tfr(i).site_ID ...
                    ', Target ' sites_tfr(i).target '(ref_' lfp_tfa_cfg.ref_hemisphere '), '  ...
                    site_conditions(cn).label];
                if site_conditions(cn).choice == 0
                    plottitle = [plottitle 'Instructed trials'];
                elseif site_conditions(cn).choice == 1
                    plottitle = [plottitle 'Choice trials'];
                end
                
                result_file = fullfile(site_results_folder, ...
                    ['LFP_TFR_' sites_tfr(i).site_ID '_' site_conditions(cn).label '.png']);
                lfp_tfa_plot_hs_tuned_tfr_multiple_img(sites_tfr(i).condition(cn).hs_tuned_tfs, ...
                    lfp_tfa_cfg, plottitle, result_file);
            end

        end
        
        sites_tfr(i).difference = [];
        % difference between conditions
        for diff = 1:size(lfp_tfa_cfg.diff_condition, 2)
            diff_condition = lfp_tfa_cfg.diff_condition{diff};
            sites_tfr(i).difference = [sites_tfr(i).difference, ...
                lfp_tfa_compute_difference_condition_tfr(sites_tfr(i).condition, diff_condition)];
        end
        % Plot TFR difference
        for dcn = 1:length(sites_tfr(i).difference)
            if ~isempty(fieldnames(sites_tfr(i).difference(dcn).hs_tuned_tfs))
                plottitle = [' Target ' ...
                    sites_tfr(i).target, ' (ref_', lfp_tfa_cfg.ref_hemisphere, ...
                    '), Site ', sites_tfr(i).site_ID ...
                    sites_tfr(i).difference(dcn).label ];

                result_file = fullfile(site_results_folder, ...
                    ['LFP_DiffTFR_' sites_tfr(i).site_ID '_' ...
                    'diff_condition' num2str(dcn) '.png']);%sites_tfr(i).difference(dcn).label '.png']);
                lfp_tfa_plot_hs_tuned_tfr_multiple_img(sites_tfr(i).difference(dcn).hs_tuned_tfs, ...
                    lfp_tfa_cfg, plottitle, result_file, 'bluewhitered');
            end
        end
        %end
        
        % save mat file for each site
        site_tfr = sites_tfr(i);
        save(fullfile(site_results_folder, ...
            ['LFP_TFR_' site_tfr.site_ID '.mat']), 'site_tfr');
        % save into a mother struct
        session_tfs.sites(i) = site_tfr;       
        
    end
       
    
    % Calculate average TFR across all sites
    session_avg = struct();
    % targets for this session
    targets = unique({session_proc_lfp.target});
    % average each target separately
    for t = 1:length(targets)
        session_avg(t).target = targets{t};
        session_avg(t).session = session_proc_lfp(1).session;
        % loop through conditions
        for cn = 1:length(site_conditions) 
            % condition-wise session average tfs
            session_avg(t).condition(cn).hs_tuned_tfs = struct();
            isite = 0;
            for i = 1:length(session_proc_lfp)
                site_lfp = session_proc_lfp(i);
                if strcmp(site_lfp.target, targets{t})
                    % check if this site should be used for averaging
                    if sites_tfr(i).use_for_avg
                        % calculate the average across sites for this condition 
                        if ~isempty(sites_tfr(i).condition(cn).hs_tuned_tfs) && ... 
                            isfield(sites_tfr(i).condition(cn).hs_tuned_tfs, 'powspctrm')
                            isite = isite + 1;                                
                            
                            for hs = 1:size(sites_tfr(i).condition(cn).hs_tuned_tfs, 2)
                                for st = 1:size(sites_tfr(i).condition(cn).hs_tuned_tfs, 1)                        
                                    if ~isempty(sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm)
                                        if isite == 1
                                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm = ...
                                                sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm ;
                                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).time = ...
                                                sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).time;
                                        else
                                            ntimebins = size(session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm, 3);
                                            % average same number of time bins
                                            if ntimebins > length(sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).time)
                                                ntimebins = length(sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).time);
                                                session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm = ...
                                                        session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm(1,:,1:ntimebins) + ...
                                                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm(1,:,1:ntimebins) ;
                                            else
                                                if ~isempty(session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm)
                                                    session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm = ...
                                                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm + ...
                                                            sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm(1,:,1:ntimebins) ;
                                                else
                                                    session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm = ...
                                                        sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).powspctrm(1,:,1:ntimebins) ;
                                                end
                                            end
                                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).time = ...
                                                sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).time(1:ntimebins);
                                        end
                                        % store session tfs
                                        session_avg(t).condition(cn).hs_tuned_tfs(st, hs).freq = sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).freq;
                                        session_avg(t).condition(cn).hs_tuned_tfs(st, hs).hs_label = sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).hs_label;
                                        if isfield(sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs), 'state') && ...
                                                isfield(sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs), 'state_name')
                                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).state = sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).state;
                                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).state_name = sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).state_name;
                                        end
                                        session_avg(t).condition(cn).hs_tuned_tfs(st, hs).cfg = sites_tfr(i).condition(cn).hs_tuned_tfs(st, hs).cfg;
                                        session_avg(t).condition(cn).cfg_condition = site_conditions(cn);
                                        session_avg(t).condition(cn).label = site_conditions(cn).label;
                                        session_avg(t).condition(cn).session = site_lfp.session;
                                        session_avg(t).condition(cn).target = site_lfp.target;
                                    end
                                end
                            end
                        end
                    end
                else
                    continue;
                end            
            end
            % average TFR across sites for a session
            if isfield(session_avg(t).condition(cn).hs_tuned_tfs, 'powspctrm') 
                for hs = 1:size(session_avg(t).condition(cn).hs_tuned_tfs, 2)
                    for st = 1:size(session_avg(t).condition(cn).hs_tuned_tfs, 1)
                        session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm = ...
                            session_avg(t).condition(cn).hs_tuned_tfs(st, hs).powspctrm / isite;
                        session_avg(t).condition(cn).hs_tuned_tfs(st, hs).nsites = isite;
                    end
                end
            end
            
            % plot average TFR for this condition and target
            if ~isempty(session_avg(t).condition(cn).hs_tuned_tfs)
                if isfield(session_avg(t).condition(cn).hs_tuned_tfs, 'powspctrm') 
                    plottitle = ['LFP TFR: Target = ' session_avg(t).target ...
                        ', (ref_', lfp_tfa_cfg.ref_hemisphere, ') ',  ...
                        'Session ', session_avg(t).condition(cn).session, ...
                        ' ', site_conditions(cn).label];
                    if site_conditions(cn).choice == 0
                        plottitle = [plottitle 'Instructed trials'];
                    elseif site_conditions(cn).choice == 1
                        plottitle = [plottitle 'Choice trials'];
                    end
                    result_file = fullfile(results_folder_tfr, ...
                                    ['LFP_TFR_' session_avg(t).target '_'...
                                    session_avg(t).condition(cn).session '_' site_conditions(cn).label '.png']);
                    lfp_tfa_plot_hs_tuned_tfr_multiple_img(session_avg(t).condition(cn).hs_tuned_tfs, ...
                                lfp_tfa_cfg, plottitle, result_file);
                end
            end
        
        end
        
        % Difference TFR for session
        % check if both pre- and post- injection blocks exist
        %if sum(lfp_tfa_cfg.compare.perturbations == [0, 1]) > 1
            %session_avg(t).difference = lfp_tfa_compute_diff_tfr(session_avg(t), lfp_tfa_cfg);
            session_avg(t).difference = [];
            % difference between conditions
            for diff = 1:size(lfp_tfa_cfg.diff_condition, 2)
                diff_condition = lfp_tfa_cfg.diff_condition{diff};
                session_avg(t).difference = [session_avg(t).difference, ...
                    lfp_tfa_compute_difference_condition_tfr(session_avg(t).condition, diff_condition)];
            end
            
            % plot average TFR difference across sites for this session
            for dcn = 1:length(session_avg(t).difference)
                if ~isempty(fieldnames(session_avg(t).difference(dcn).hs_tuned_tfs))
                    plottitle = ['LFP Diff TFR: Target ' session_avg(t).target ...
                        '(ref_' lfp_tfa_cfg.ref_hemisphere '), '  ...
                        'Session ', session_avg(t).difference(dcn).session, ...
                        ' ', session_avg(t).difference(dcn).label];
%                     if session_avg(t).difference(dcn).cfg_condition.choice == 0
%                         plottitle = [plottitle 'Instructed trials'];
%                     else
%                         plottitle = [plottitle 'Choice trials'];
%                     end
                    result_file = fullfile(results_folder_tfr, ...
                                    ['LFP_DiffTFR_' session_avg(t).target '_' ...
                                    session_avg(t).difference(dcn).session '_' ...
                                    'diff_condition' num2str(dcn) '.png']); 
                                    %session_avg(t).difference(dcn).label '.png']);
                    lfp_tfa_plot_hs_tuned_tfr_multiple_img(session_avg(t).difference(dcn).hs_tuned_tfs, ...
                                lfp_tfa_cfg, plottitle, result_file, 'bluewhitered');

                end
            end
        %end
        
    end
    
    session_tfs.session_avg = session_avg;
    
    % close figures
    close all;    
    
    % save session average tfs
    save(fullfile(results_folder_tfr, ['LFP_TFR_' session_tfs.session '.mat']), 'session_tfs');
    % save settings file
    save(fullfile(results_folder_tfr, 'lfp_tfa_settings.mat'), 'lfp_tfa_cfg');

end