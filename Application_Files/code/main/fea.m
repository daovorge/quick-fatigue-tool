function [] = fea(varargin)
%FEA    QFT function to csubmit an Abaqus input file for analysis.
%   FEA is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   FEA(JOBNAME) submits 'JOBNAME.inp' for analysis.
%
%   FEA(ABQCMD JOBNAME) submits 'JOBNAME.inp' for analysis using the
%   Abaqus command ABQCMD.
%
%   FEA(ABQCMD JOBNAME CPUS) submits 'JOBNAME.inp' for analysis using the
%   Abaqus command ABQCMD and CPUS processors.
%   
%   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
%   Last modified 20-Feb-2018 15:43:20 GMT
    
    %%

%% GET THE INPUTS
switch nargin
    case 1.0
        abqCmd = 'abaqus';
        jobName = varargin{1.0};
        cpus = 1.0;
    case 2.0
        abqCmd = varargin{1.0};
        jobName = varargin{2.0};
        cpus = 1.0;
    case 3.0
        abqCmd = varargin{1.0};
        jobName = varargin{2.0};
        cpus = str2double(varargin{3.0});
    otherwise
end

logFile = [jobName, '.log'];
% Clear the command window
clc

%% SUBMIT THE JOB FOR ANALYSIS
fprintf('[QFT] Submitting job ''%s'' for analysis\n', jobName);
[~, message] = system(sprintf('%s j=%s cpus=%.0f', abqCmd, jobName, cpus));

if isempty(message) == 0.0
    fprintf('[ABAQUS] %s', message);
    return
end

%% WAIT FOR THE LOG FILE TO APPEAR
x = 1.0;
while x == 1.0
    if exist(logFile, 'file') == 2.0
        x = 0.0;
    end
end

%% WAIT FOR THE ANALYSIS TO COMPLETE
fprintf('[QFT] Waiting for FEA analysis to complete\n');
x = 1.0;
while x == 1.0
    fid = fopen(logFile);
    data = char(fread(fid, 'char')');
    fclose(fid);
    
    if isempty(strfind(data, sprintf('Abaqus JOB %s COMPLETED', jobName))) == 0.0
        fprintf('[QFT] The Abaqus analysis has been completed\n');
        x = 0.0;
    elseif isempty(strfind(data, sprintf('Abaqus/Analysis exited with errors'))) == 0.0
        % Clear up Abaqus files
        pause(3.0)
        directoryStructure = dir(sprintf('*%s*.*', jobName));
        
        L = length(directoryStructure);
        for i = 1:L
            if (strcmp(directoryStructure(i).name, [jobName, '.log']) == 1.0) ||...
                    (strcmp(directoryStructure(i).name, [jobName, '.inp']) == 1.0) ||...
                    (strcmp(directoryStructure(i).name, [jobName, '.dat']) == 1.0) ||...
                    (strcmp(directoryStructure(i).name, [jobName, '.msg']) == 1.0) ||...
                    (strcmp(directoryStructure(i).name, [jobName, '.odb']) == 1.0)
                
                continue
            else
                delete(directoryStructure(i).name)
            end
        end
        
        fprintf('[QFT] The Abaqus analysis exited with errors. Check the .log file for details\n');
        return
    end
end

%% CLEAN UP ABAQUS FILES
pause(3.0)
directoryStructure = dir(sprintf('*%s*.*', jobName));
for i = 1:length(directoryStructure)
    if (strcmp(directoryStructure(i).name, [jobName, '.odb']) == 1.0) || (strcmp(directoryStructure(i).name, [jobName, '.inp']) == 1.0)
        continue
    else
        delete(directoryStructure(i).name)
    end
end

answer = questdlg('FEA complete. Ready for fatigue analysis', 'Quick Fatigue Tool', 'Continue', 'Stop', 'Continue');
if strcmp(answer, 'Stop') == 1.0
    return
else
    run('test.m')
end
end