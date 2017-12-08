%COMPOSITE_TUTORIAL    Example composite failure criteria analysis.
%   This function contains calls to the job files composite_load_fibre.m
%   and composite_load_matrix.m.
%
%   Analaysis-specific settings for composite_load_fibre.m and
%   composite_load_matrix.m are found in composite_load_fibre_env.m and
%   composite_load_matrix_env.m, respectively.
%
%   Click "Run" or press F5 to start the fatigue analysis. The two analysis
%   jobs are run consecutively.
%
%   Output is written to:
%   
%     Project\output\composite_load_fibre
%     Project\output\composite_load_matrix
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4 Configuring and running an analysis
%      12.3 Composite failure criteria
%   
%   Quick Fatigue Tool 6.11-08 Copyright Louis Vallance 2017
%   Last modified 24-Nov-2017 12:40:07 GMT

job composite_load_fibre
job composite_load_matrix