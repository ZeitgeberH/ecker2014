function covExpl(varargin)
% Analyze how well the GPFA model approximates the covariance matrix.
%
%   For this analysis we take the matrix norm (Frobenius) of the difference
%   between the observed covariance matrix and that predicted by the GPFA
%   model. This difference is taken relative to the matrix norm of the
%   observed covariance matrix (to account for number of cells and
%   different variances).
%
% AE 2012-12-11

if ~nargin
    restrictions = {'subject_id in (9, 11)', ...
                    'sort_method_num = 5', ...
                    'transform_num = 2', ...
                    'kfold_cv = 2'};
else
    restrictions = varargin;
end

rel = (nc.GpfaModelSet * nc.GpfaCovExpl) & restrictions;

n = count(rel & 'latent_dim = 0');
pmax = 10;
dtrain = zeros(n, pmax + 1);
dtest = zeros(n, pmax + 1);

for p = 0 : pmax
    relp = rel & struct('latent_dim', p);
    [dtrain(:, p + 1), dtest(:, p + 1)] = fetchn(relp, 'rel_diff_train', 'rel_diff_test');
end

% plot
figure(10), clf, hold on
subplot(211)
errorbar(0 : pmax, mean(dtrain), std(dtrain) / sqrt(n), '.-k')
xlim([-1 pmax + 1])
ylabel('Relative norm of difference')
set(legend('Training set'), 'box', 'off')
box off
subplot(212)
errorbar(0 : pmax, mean(dtest), std(dtest) / sqrt(n), '.-r')
xlim([-1 pmax + 1])
xlabel('Latent factors')
ylabel('Relative norm of difference')
set(legend('Test set'), 'box', 'off')
box off
