function [] = checkDataPath()
%CHECKDATAPATH    QFT function to set the MATLAB path for QFT apps.
%   
%   CHECKDATAPATH is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%
%   See also evaluateMaterial, importMaterial, kValueCalculator,
%   LocalMaterialDatabase, material, MaterialEditor, MaterialManager.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-11 Copyright Louis Vallance 2017
%   Last modified 02-Sep-2017 19:02:40 GMT
    
    %%

% Suppress the local path GUI if applicable
if isappdata(0, 'qft_suppressDataPath') == 1.0
    return
end

%{
    The default user material path is stored in the text file 'user.txt'.
    Check if this file exists and set the default user material path if
    applicable.
%}
localPath = getappdata(0, 'qft_localMaterialDataPath');

if isempty(localPath) == 1.0
    % The default path is not set
    if exist('qft-local-material.txt', 'file') == 2.0
        try
            dataPath = which('qft-local-material.txt');
            [dataPath, ~, ~] = fileparts(dataPath);
            
            setappdata(0, 'qft_localMaterialDataPath', dataPath)
        catch
            LocalMaterialDatabase
            uiwait(LocalMaterialDatabase)
        end
    else
        LocalMaterialDatabase
        uiwait(LocalMaterialDatabase)
    end
else
    %{
        The default path is already set. Re-build the marker file if it
        does not exist
    %}
    if exist([localPath, '\qft-local-material.txt'], 'file') ~= 2.0
        % Write the marker file
        fid = fopen([localPath, '\qft-local-material.txt'], 'w+');
        fclose(fid);
    end
end