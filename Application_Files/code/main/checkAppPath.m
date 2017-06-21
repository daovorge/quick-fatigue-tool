%CHECKAPPPATH    QFT function to set the MATLAB path for QFT apps.
%   
%   CHECKAPPPATH is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.11-00 Copyright Louis Vallance 2017
%   Last modified 21-Jun-2017 12:45:05 GMT
    
    %%

% Get the path of the MATLAB application directory
files = matlab.apputil.getInstalledAppInfo;
[appPath, ~, ~] = fileparts(files(1.0).location);

%{
    The file ANCHOR is a dummy file in the main QFT code directory. If the
    user is running a QFT app outside of the QFT environment, ANCHOR may
    not exist on the MATLAB path. In such cases, the user is probably
    running the app from the app bar, and the app directory should be added
    to the MATLAB path
%}
if exist('anchor', 'file') ~= 2.0
    %{
        The main QFT code is probably not on the MATLAB path. Add the app
        folder to the MATLAB path
    %}
    try
        addpath(genpath(appPath))
        savepath
    catch
        %{
            For some reason this did not work. Continue as normal, but warn
            the user that the app probably won't work properly
        %}
        fprintf('Quick Fatigue Tool error: The MATLAB path could not be set. App may not work properly!\n')
    end
elseif exist(appPath, 'dir') == 7.0
    % The app path exists. Check if this path is also on the MATLAB path
    pathCell = regexp(path, pathsep, 'split');
    if ispc == 1.0 % Windows is not case-sensitive
        onPath = any(strcmpi(appPath, pathCell));
    else
        onPath = any(strcmp(appPath, pathCell));
    end
    
    if onPath == 1.0
        %{
            The app folder and the QFT code are both on the MATLAB path.
            Remove the app folder from the MATLAB path
        %}
        rmpath(genpath(appPath))
    end
end