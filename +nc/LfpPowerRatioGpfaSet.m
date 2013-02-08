%{
nc.LfpPowerRatioGpfaSet (computed) # Correlation between LFP power and GPFA

-> cont.Lfp
-> nc.Gratings
-> ae.SpikesByTrialSet
-> nc.GpfaParams
-> nc.DataTransforms
-> nc.LfpPowerRatioGpfaParams
---
power_ratio_avg     : double            # LFP power ratio
%}

classdef LfpPowerRatioGpfaSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioGpfaSet');
        popRel = cont.Lfp * ae.SpikesByTrialSet * nc.Gratings ...
            * nc.GpfaParams * nc.DataTransforms * nc.LfpPowerRatioGpfaParams ...
            & nc.GpfaModelSet & 'max_latent_dim = 1 AND kfold_cv = 1 AND  zscore = 1 AND subject_id IN (9, 11) AND sort_method_num = 5';
    end
    
    methods 
        function self = LfpPowerRatioGpfaSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)

            % determine available tetrodes etc.
            tet = fetchn(detect.Electrodes & key, 'electrode_num');
            nTet = numel(tet);
            lfpFile = getLocalPath(fetch1(cont.Lfp & key, 'lfp_file'));
            br = baseReader(lfpFile, sprintf('t%d', tet(1)));
            Fs = getSamplingRate(br);
            
            % determine blocks
            par = fetch(nc.LfpPowerRatioGpfaParams & key, '*');
            trials = validTrialsCompleteBlocks(nc.Gratings & key);
            showStim = sort(fetchn(trials * stimulation.StimTrialEvents ...
                & 'event_type = "showStimulus"', 'event_time'));
            endStim = sort(fetchn(trials * stimulation.StimTrialEvents ...
                & 'event_type = "endStimulus"', 'event_time'));
            nTrials = numel(showStim);
            nBlocks = par.num_blocks;
            nTrialsPerBlock = fix(nTrials / nBlocks);
            blocks = [showStim((0 : nBlocks - 1) * nTrialsPerBlock + 1), ...
                      endStim((1 : nBlocks) * nTrialsPerBlock)];
            blocks = getSampleIndex(br, blocks);
            
            % extract LFP & compute power spectra
            n = 2^13;
            Pxx = zeros(n + 1, nBlocks, nTet);
            for iTet = 1 : nTet
                br = baseReader(lfpFile, sprintf('t%d', tet(iTet)));
                for iBlock = 1 : nBlocks
                    lfp = br(blocks(iBlock, 1) : blocks(iBlock, 2), 1);
                    Pxx(:, iBlock, iTet) = pwelch(lfp, 2 * n);
                end
            end
            f = linspace(0, Fs / 2, n + 1);
            df = f(2) / 2;
            low = f > par.low_min & f < par.low_max;
            high = (f > par.high_min & f < par.high_max) & ... exclude 50 & 60 Hz (line noise)
                ~(f > 50 - df & f < 50 + df) & ~(f > 60 - df & f < 60 + df);
            ratio = mean(Pxx(low, :, :), 1) ./ mean(Pxx(high, :, :), 1);
            ratio = mean(log2(ratio), 3);
            rank = tiedrank(ratio);

            % get GPFA models
            data = fetch(stimulation.StimTrials * nc.GratingTrials ...
                & nc.GpfaModel & key, 'trial_num', 'condition_num');
            data = dj.struct.sort(data, 'trial_num');
            trials = [data.trial_num];
            conditions = [data.condition_num];
            X = zeros(1, numel(trials));
            for modelKey = fetch(nc.GpfaModel & key & 'cv_run = 1 AND latent_dim = 1')'
                [Y, model] = fetch1(nc.GpfaModelSet * nc.GpfaModel & key & modelKey, 'transformed_data', 'model');
                model = GPFA(model);
                Xi = model.estX(Y);
                Xi = (Xi - mean(Xi(:))) / std(Xi(:), 1);
                X(1 : size(Xi, 2), conditions == modelKey.condition_num) = Xi;
            end
            
            % insert into database
            set = key;
            set.power_ratio_avg = mean(ratio);
            self.insert(set);
            for iBlock = 1 : nBlocks
                ndx = trials > (iBlock - 1) * nTrialsPerBlock ...
                    & trials <= iBlock * nTrialsPerBlock;
                block = key;
                block.block_num = iBlock;
                block.block_rank = rank(iBlock);
                block.power_ratio = ratio(iBlock);
                block.delta_power_ratio = block.power_ratio - set.power_ratio_avg;
                block.mean_x = mean(mean(X(:, ndx)));
                block.var_x = var(reshape(X(:, ndx), [], 1), 1);
                insert(nc.LfpPowerRatioGpfa, block);
            end
        end
    end
end
