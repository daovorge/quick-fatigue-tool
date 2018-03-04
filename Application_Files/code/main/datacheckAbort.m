function [continueAnalysis] = datacheckAbort(Sxx, Syy, Szz, Txy, Tyz, Txz, tic_pre, outputField, fid_status)
%DATACHECKABORT    QFT function to abort analysis at data check phase.
%
%   DATACHECKABORT is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
%   Last modified 14-Feb-2018 19:58:29 GMT
    
    %%   
    
% Check if user wishes to continue
continueAnalysis = 0.0;

if getappdata(0, 'analysisDialogues') > 0.0
    message = sprintf('Results of the data check have been written to:\n\n''%s''', [pwd, '\Project\output\', getappdata(0, 'jobName')]);
    
    if (ispc == 1.0) && (ismac == 0.0) && (getappdata(0, 'compositeCriteria') == 0.0)
        answer = questdlg(message, 'Quick Fatigue Tool', 'Stop', 'Continue', 'Stop');
    elseif (ispc == 0.0) && (ismac == 1.0)
        answer = msgbox(message, 'Quick Fatigue Tool');
    else
        answer = -1.0;
    end
    
    if strcmpi(answer, 'continue') == 1.0
        continueAnalysis = 1.0;
        setappdata(0, 'dataCheck', 0.0)
        return
    end
end

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