function setPath

base = fileparts(mfilename('fullpath'));
d = dir(base);
d = d([d.isdir]);
d = d(cellfun(@isempty, regexp({d.name}, '^[\+\.](\w*)')));
for i = 1:numel(d)
    addpath(fullfile(base, d(i).name))
end
addpath(base)

% AE ephys lib
old = cd(fullfile(base, '../ephyslib'));
addpath(pwd)

% spike sorting lib (Kalman filter model)
cd(fullfile(base, '../../moksm'))
addpath(pwd)

cd(old)
