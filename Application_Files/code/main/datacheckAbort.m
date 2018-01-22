function [] = datacheckAbort(Sxx, Syy, Szz, Txy, Tyz, Txz, tic_pre, outputField, fid_status)
%DATACHECKABORT    QFT function to abort analysis at data check phase.
%
%   DATACHECKABORT is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.11-11 Copyright Louis Vallance 2018
%   Last modified 01-Dec-2017 12:42:06 GMT
    
    %%   

% Add output folder to current directory
job = getappdata(0, 'jobName');
addpath(genpath(sprintf('%s\\Project\\output\\%s', pwd, job)))

if outputField == 1.0
    printTensor(Sxx, Syy, Szz, Txy, Tyz, Txz)
end

setappdata(0, 'dataCheck_time', toc(tic_pre))

fprintf('\n[NOTICE] Results have been written to %s', [pwd, '\Project\output\', job])

if getappdata(0, 'echoMessagesToCWIN') == 1.0
    fprintf('\n[NOTICE] Data Check complete. Scroll up for details (%fs)\n', toc(tic_pre))
else
    fprintf('\n[NOTICE] Data Check complete (%fs)\n', toc(tic_pre))
end
messenger.writeMessage(-999.0)
fprintf(fid_status, '\r\n\r\nTHE ANALYSIS HAS COMPLETED SUCCESSFULLY');
fclose(fid_status);

% Perform clean-up tasks
cleanup(0.0)
end