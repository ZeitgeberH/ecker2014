function fanoLayersDirSel(varargin)
% Fano factors as a function of layers.
%    Laminar locations are computed differently for different monkeys but
%    were selected such that the profiles of direction selectivity indices
%    were roughly consistent between monkeys (peaks in layer 4B and 6, as
%    reported by Snodderly & Gur 1996).
%
% AE 2013-08-02

key.sort_method_num = 5;
key.detect_method_num = 4;
key.spike_count_end = 2030;
key = genKey(key, varargin{:});

subj = [9 11 28];
wmDepth = [NaN 2720 2520];
bins = -2000 : 200 : 600;

dds = [];
ddc = [];
FF = [];

fig = Figure(1, 'size', [80 150]);
for i = 1 : numel(subj)
    key.subject_id = subj(i);
    
    cells = ae.TetrodeDepths * ae.TetrodeProperties * nc.OriTuning * ephys.Spikes * nc.UnitStats;
    [dc, ds, ttc, F] = fetchn(cells & key & 'instability < 0.1', ...
        'depth + depth_to_brain -> d', 'dir_sel_ind', 'electrode_num', 'mean_fano');
    
    % convert depths relative to white matter
    if subj(i) == 9
        % fit white matter plane
        [dtw, x, y, tet] = fetchn(ae.TetrodeProperties & key, 'depth_to_brain + depth_to_wm -> d', 'loc_x', 'loc_y', 'electrode_num', 'ORDER BY electrode_num');
        b = robustfit([x y], dtw);
        wm = zeros(24, 1);
        wm(tet) = b(1) + [x y] * b(2: 3);
    else
        % use constant depth determined manually from the tetrodes that
        % definitely hit white matter
        wm = wmDepth(i) * ones(24, 1);
    end
    dc = dc - wm(ttc);
    
    [m, p25, p75, binc] = makeBinned(dc, ds, bins, @median, @(x) prctile(x, 25), @(x) prctile(x, 75), 'include');
    
    subplot(3, 2, 2 * i - 1), cla
    plot(ds, -dc, '.k')
    hold on
    plot(m, -binc, 'o-r', 'linewidth', 1)
    plot(p25, -binc, '--r', p75, -binc, '--r');
    axis([0 1 -600 2000])

    [m, p25, p75, binc] = makeBinned(dc, F, bins, @median, @(x) prctile(x, 25), @(x) prctile(x, 75), 'include');
    
    subplot(3, 2, 2 * i)
    plot(F, -dc, '.k')
    hold on
    plot(m, -binc, 'o-r', p25, -binc, '--r', p75, -binc, '--r');

    axis([0 10 -600 2000])
    
    dds = [dds; ds]; %#ok
    ddc = [ddc; dc]; %#ok
    FF = [FF; F];    %#ok
end

xlabel('Fano factors')
subplot(3, 2, 5)
xlabel('Dir. sel. index')
ylabel('Depth relative to white matter')

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file '_indiv'])
pause(0.5)
fig.save([file '_indiv.png'])


% Summary plot
fig2 = Figure(2, 'size', [80 60]);
[m, p25, p75, binc] = makeBinned(ddc, dds, bins, @median, @(x) prctile(x, 25), @(x) prctile(x, 75), 'include');

subplot(121), cla
plot(dds, -ddc, '.k', m, -binc, 'o-r', p25, -binc, '--r', p75, -binc, '--r');
axis([0 1 -600 2000])
xlabel('Dir. sel. index')
ylabel('Depth relative to white matter')

[m, p25, p75, binc] = makeBinned(ddc, FF, bins, @median, @(x) prctile(x, 25), @(x) prctile(x, 75), 'include');

subplot(122)
plot(FF, -ddc, '.k', m, -binc, 'o-r', p25, -binc, '--r', p75, -binc, '--r');
axis([0 10 -600 2000])
xlabel('Fano factors')

fig2.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig2.save(file)
pause(0.5)
fig2.save([file '.png'])
