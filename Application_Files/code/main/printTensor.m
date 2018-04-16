function [] = printTensor(Sxx, Syy, Szz, Txy, Tyz, Txz)
%printTensor    QFT function to print tensor components to a text file.
%    This function contains code to print tensor components to a text file
%    during a data check analysis.
%
%    printTensor is used internally by Quick Fatigue Tool. The user is not
%    required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4.2 Configuring a data check analysis
%    
%    Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%    Last modified 05-Apr-2018 08:59:50 GMT
    
    %%
    
%% Get the maximum tensor components
s11 = max(Sxx, [], 2.0); s11min = min(Sxx, [], 2.0);
s11(abs(s11min) > s11) = s11min(abs(s11min) > s11);

s22 = max(Syy, [], 2.0); s22min = min(Syy, [], 2.0);
s22(abs(s22min) > s22) = s22min(abs(s22min) > s22);

s33 = max(Szz, [], 2.0); s33min = min(Szz, [], 2.0);
s33(abs(s33min) > s33) = s33min(abs(s33min) > s33);

s12 = max(Txy, [], 2.0); s12min = min(Txy, [], 2.0);
s12(abs(s12min) > s12) = s12min(abs(s12min) > s12);

s13 = max(Txz, [], 2.0); s13min = min(Txz, [], 2.0);
s13(abs(s13min) > s13) = s13min(abs(s13min) > s13);

s23 = max(Tyz, [], 2.0); s23min = min(Tyz, [], 2.0);
s23(abs(s23min) > s23) = s23min(abs(s23min) > s23);

[A, ~] = size(s11);
if A > 1.0
    s11 = s11';
    s22 = s22';
    s33 = s33';
    s12 = s12';
    s13 = s13';
    s23 = s23';
end

%% Get the principal stresses
s1 = getappdata(0, 'S1');
s3 = getappdata(0, 'S3');

% Take the maximum principal value for each item
s1 = max(s1, [], 2.0);
s3 = min(s3, [], 2.0);

[A, ~] = size(s1);
if A > 1.0
    s1 = s1';
    s3 = s3';
end

%% Get the analysis IDs
mainID = getappdata(0, 'mainID');
subID = getappdata(0, 'subID');

[A, ~] = size(mainID);
if A > 1.0
    mainID = mainID';
    subID = subID';
end

%% Worst principal file
% Concatenate field data
data = [mainID; subID; s1; s3]';

dir = [getappdata(0, 'outputDirectory'), 'Data Files/datacheck_principal.dat'];

fid = fopen(dir, 'w+');

fprintf(fid, 'WORST PRINCIPAL STRESS [WHOLE MODEL]\r\nJob:\t%s\r\nUnits:\tMPa\r\n', getappdata(0, 'jobName'));

fprintf(fid, 'Main ID\tSub ID\tMax. Principal\tMin. Principal\r\n');
fprintf(fid, '%.0f\t%.0f\t%.4f\t%.4f\r\n', data');

fclose(fid);

%% Worst tensor file
if length(mainID) == length(s11)
    % Concatenate field data
    data = [mainID; subID; s11; s22; s33; s12; s13; s23]';
    
    dir = [getappdata(0, 'outputDirectory'), 'Data Files/datacheck_tensor.dat'];
    
    fid = fopen(dir, 'w+');
    
    fprintf(fid, 'WORST TENSOR [WHOLE MODEL]\r\nJob:\t%s\r\nUnits:\tMPa\r\n', getappdata(0, 'jobName'));
    
    fprintf(fid, 'Main ID\tSub ID\tS11\tS22\tS33\tS12\tS13\tS23\r\n');
    fprintf(fid, '%.0f\t%.0f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');
    
    fclose(fid);
end