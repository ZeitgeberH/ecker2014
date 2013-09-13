function stats_summary()
% Summary statistics for dataset
% AE 2013-08-26

key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.spike_count_start = 30;
key.spike_count_end = 530;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 1;
key = genKey(key, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

for k = key'
    
    % general dataset
    n = double(fetchn(nc.AnalysisStims, nc.AnalysisUnits & k, 'count(1) -> n'));
    instab = fetchn(nc.AnalysisStims * nc.UnitStats & k, 'tac_instability') > k.max_instability;
    fprintf('\nBrain state: %s\n', k.state)
    fprintf('  Single units: %d\n', count(nc.AnalysisUnits & k))
    fprintf('  nc.AnalysisStims: %d (%d drifting, %d static)\n', ...
        count(nc.AnalysisStims & k), ...
        count(nc.AnalysisStims * nc.Gratings & k & 'speed > 0'), ...
        count(nc.AnalysisStims * nc.Gratings & k & 'speed = 0'))
    fprintf('  Single units per session\n    range: %d - %d\n    median: %g\n', ...
        min(n), max(n), median(n))
    fprintf('  Units excluded because of instability: %d/%d (%.1f%%)\n', sum(instab), numel(instab), mean(instab) * 100)
    
    % contamination
    c = fetchn(nc.AnalysisUnits * ephys.SingleUnit & k, 'fp + fn -> c');
    fprintf('  Contamination\n    <10%%: %.1f%%\n    <20%%: %.1f%%\n', 100 * mean(c < 0.1), 100 * mean(c < 0.2))
    
    % orientation tuning
    p = fetchn(nc.AnalysisUnits, nc.AnalysisUnits * nc.OriTuning & k, 'min(ori_sel_p) -> p');
    tuned = p < 0.01;
    fprintf('  Orientation tuning: %.1f%% (%d/%d)\n', 100 * mean(tuned), sum(tuned), numel(tuned))
    
    % signal and noise correlations for pairs on same tetrode
    [rsa, rna] = fetchn(nc.AnalysisStims * nc.CleanPairs * nc.NoiseCorrelations & k & 'distance = 0', 'r_signal', 'r_noise_avg');
    [rs, rn] = fetchn(acq.Subjects, ...
        nc.AnalysisStims * nc.CleanPairs * nc.NoiseCorrelations & k & 'distance = 0', ...
        'AVG(r_signal) -> rs', 'AVG(r_noise_avg) -> rn');
    rstxt = sprintf(', %.3f', rs);
    rntxt = sprintf(', %.3f', rn);
    fprintf('  Signal correlations: %.3f (%s)\n', mean(rsa), rstxt(3 : end))
    fprintf('  Noise correlations:  %.3f (%s)\n', mean(rna), rntxt(3 : end))
    fprintf('\n')    
end
