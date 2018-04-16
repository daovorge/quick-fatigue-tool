function [continueAnalysis] = datacheckAbort(Sxx, Syy, Szz, Txy, Tyz, Txz, tic_pre, outputField, fid_status)
%DATACHECKABORT    QFT function to abort analysis at data check phase.
%
%   DATACHECKABORT is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 05-Apr-2018 08:59:50 GMT
    
    %%   
    
% Add output folder to current directory
job = getappdata(0, 'jobName');
if exist(sprintf('%s\\Project\\output\\%s', pwd, job), 'dir') ~= 7.0
    addpath(genpath(sprintf('%s\\Project\\output\\%s', pwd, job)))
end

% Write whole model worst tensor/principal stress values to file 
if outputField == 1.0
    printTensor(Sxx, Syy, Szz, Txy, Tyz, Txz)
end

% Check if user wishes to continue
continueAnalysis = 0.0;
datacheckTime = toc(tic_pre);

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
        
        %{
            If the user originally requested MATLAB figures, create the
            directory now
        %}
        if getappdata(0, 'outputFigure') == 1.0
            % Folder for MATLAB figures
            figureFolder = [getappdata(0, 'outputDirectory'), 'MATLAB Figures'];
            
            if exist(figureFolder, 'dir') == 0.0
                try
                    mkdir(figureFolder)
                catch exception
                    setappdata(0, 'E034', 1.0)
                    setappdata(0, 'warning_034_exceptionMessage', exception.identifier)
                    
                    cleanup(1.0)
                    continueAnalysis = 0.0;
                    return
                end
            end
        end
        return
    end
end

% Print footer to command window
setappdata(0, 'dataCheck_time', datacheckTime)
fprintf('\n[NOTICE] Results have been written to %s', [pwd, '\Project\output\', job])

if getappdata(0, 'echoMessagesToCWIN') == 1.0
    fprintf('\n[NOTICE] Data Check complete. Scroll up for details (%fs)\n', datacheckTime)
else
    fprintf('\n[NOTICE] Data Check complete (%fs)\n', datacheckTime)
end
messenger.writeMessage(-999.0)
fprintf(fid_status, '\r\n\r\nTHE ANALYSIS HAS COMPLETED SUCCESSFULLY');
fclose(fid_status);

% Perform clean-up tasks
cleanup(0.0)
end