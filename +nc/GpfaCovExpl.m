%{
nc.GpfaCovExpl (computed) # Covariance explained by GPFA model

-> nc.GpfaModel
---
cov_train           : mediumblob    # covariance matrix of training set
cov_test            : mediumblob    # covariance matrix of test set
cov_pred            : mediumblob    # predicted covariance matrix
cov_resid_train     : mediumblob    # residual covariance for training set
cov_resid_test      : mediumblob    # residual covariance for test set
cov_resid_raw_train : mediumblob    # resid cov for untrans data (training)
cov_resid_raw_test  : mediumblob    # resid cov for untrans data (test)
norm_train          : double        # norm for training set
norm_test           : double        # norm for tes set
norm_pred           : double        # norm for prediction
norm_diff_train     : double        # difference in norms for training set
norm_diff_test      : double        # difference in norms for test set
rel_diff_train      : double        # relative difference for training set
rel_diff_test       : double        # relative difference for test set
%}

classdef GpfaCovExpl < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaCovExpl');
        popRel = nc.GpfaModel;
    end
    
    methods 
        function self = GpfaCovExpl(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            [Y, Yt] = fetch1(nc.GpfaModelSet(key), 'raw_data', 'transformed_data');
            [train, test, model] = fetch1(nc.GpfaModel(key), 'train_set', 'test_set', 'model');
            model = GPFA(model);
            Qtrain = cov(Ysub(Yt, train));
            Qtest = cov(Ysub(Yt, test));
            Qpred = model.C * model.C' + model.R;
            Ypred = model.predict(Yt);
            Yres = Yt - Ypred;
            YpredRaw = invert(nc.DataTransforms & key, Ypred);
            YresRaw = Y - YpredRaw;
            tuple = key;
            tuple.cov_train = Qtrain;
            tuple.cov_test = Qtest;
            tuple.cov_pred = Qpred;
            tuple.cov_resid_train = cov(Ysub(Yres, train));
            tuple.cov_resid_test = cov(Ysub(Yres, test));
            tuple.cov_resid_raw_train = cov(Ysub(YresRaw, train));
            tuple.cov_resid_raw_test = cov(Ysub(YresRaw, test));
            tuple.norm_diff_train = norm(Qtrain - Qpred, 'fro');
            tuple.norm_diff_test = norm(Qtest - Qpred, 'fro');
            tuple.norm_train = norm(Qtrain, 'fro');
            tuple.norm_test = norm(Qtest, 'fro');
            tuple.norm_pred = norm(Qpred, 'fro');
            tuple.rel_diff_train = tuple.norm_diff_train / tuple.norm_train;
            tuple.rel_diff_test = tuple.norm_diff_test / tuple.norm_test;
            self.insert(tuple);
        end
    end
    
end


function Y = Ysub(Y, index)
    Y = Y(:, :, index);
    Y = reshape(Y, size(Y, 1), size(Y, 2) * size(Y, 3))';
end
