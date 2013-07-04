%{
nc.GpfaVarExpl (computed) # Variance explained for GPFA model

-> nc.GpfaUnits
-> nc.GpfaCovExpl
---
var_expl_train          : double     # avg var expl on train set model based
var_expl_test           : double     # avg var expl on test set model based
%}

classdef GpfaVarExpl < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaVarExpl');
    end

    methods
        function self = GpfaVarExpl(varargin)
            self.restrict(varargin{:})
        end
    end
end
