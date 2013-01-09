function visualize(key, trials)
% Visualize GPFA model.
% AE 2013-01-09

window = 30 + [0 2000];  % 30 ms offset hard-coded in nc.GpfaModelSet

nUnits = count(nc.GpfaUnits & key);
nTrials = count(nc.GratingTrials & key);

spikes = (nc.GpfaUnits * ae.SpikesByTrial * nc.GratingConditions * nc.GratingTrials) & key;
spikes = fetch(spikes, 'spikes_by_trial');
spikes = dj.struct.sort(spikes, {'trial_num', 'unit_id'});
spikes = reshape(spikes, nUnits, nTrials);

[model, Y] = fetch1(nc.GpfaModelSet * nc.GpfaModel & key, 'model', 'transformed_data');
model.C = model.C * sign(mean(model.C));
model = GPFA(model);
X = model.estX(Y(:, :, trials));
tbins = window(1) + key.bin_size / 2 : key.bin_size : window(2);
[~, order] = sort(model.C, 'descend');

% Plot
figure(1), clf
nSelTrials = numel(trials);
for iTrial = 1 : nSelTrials
    hold on
    for iUnit = 1 : nUnits
        y = (iTrial - 1) + (iUnit - 1) / nUnits;
        t = spikes(order(iUnit), trials(iTrial)).spikes_by_trial';
        t = t(t > window(1) & t < window(2));
        if ~isempty(t)
            t = repmat(t, 2, 1);
            plot(t, y + [0; 1 / nUnits / 2], 'k')
        end
    end
    plot(tbins, 0.2 * X(:, :, iTrial) + iTrial - 0.6, '-r')
end
plot(window, repmat(1 : nSelTrials - 1, 2, 1), 'k')
set(gca, 'xlim', window, 'ylim', [0 nSelTrials], 'Box', 'on')
xlabel('Time [ms]')
ylabel('Trial')
