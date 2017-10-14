function [isAvailable] = checkToolbox(toolboxName)
%CHECKTOOLBOX    QFT function to check for toolbox installation.
%   
%   CHECKTOOLBOX is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   Quick Fatigue Tool 6.11-05 Copyright Louis Vallance 2017
%   Last modified 14-Oct-2017 18:15:15 GMT
    
    %%
    
    % Check if the required toolbox is installed
    versionData = ver;
    isAvailable = any(strcmp(cellstr(char(versionData.Name)), toolboxName));
    
    % Create appdata variable name
    switch toolboxName
        case 'Image Processing Toolbox'
            tag = 'noIPT';
        case 'Symbolic Math Toolbox'
            tag = 'noSMT';
        case 'Statistics and Machine Learning Toolbox'
            tag = 'noSMLT';
    end
    
    % Set the appdata flag accordingly
    if isAvailable == 0.0
        setappdata(0, tag, 1.0)
    else
        setappdata(0, tag, 0.0)
    end
end