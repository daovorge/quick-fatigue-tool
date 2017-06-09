classdef uniaxialPreProcess < handle
%UNIAXIALPREPROCESS    QFT class for Uniaxial Strain-Life.
%   This class contains methods for the Uniaxial Strain-Life application.
%   
%   UNIAXIALPREPROCESS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also multiaxialAnalysis, multiaxialPostProcess, gaugeOrientation,
%   materialOptions, MultiaxialFatigue.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.2 Multiaxial Gauge Fatigue
%   
%   Quick Fatigue Tool 6.11-00 Copyright Louis Vallance 2017
%   Last modified 17-May-2017 14:54:51 GMT
    
    %%
    
    methods (Static = true)
        %% Prescan the file selection
        function [loadHistoryData, error] = preScanFile(handles)
            %% Initialise output
            error = 0.0;
            loadHistoryData = [];
            
            %% Check if the file exists
            loadHistoryPath = get(handles.edit_inputFile, 'string');
            
            if isempty(loadHistoryPath) == 1.0
                errordlg('A load history file must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if exist(loadHistoryPath, 'file') == 0.0
                errorMessage = sprintf('Error while processing ''%s''. The file could not be located.', loadHistoryPath);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Check if the file can be read
            try
                loadHistoryData = dlmread(loadHistoryPath);
            catch
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.', loadHistoryPath);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Check for non-numeric data in each file
            if (any(any(isinf(loadHistoryData))) == 1.0) || (any(any(isnan(loadHistoryData))) == 1.0) || (any(any(isreal(loadHistoryData))) == 0.0)
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', loadHistoryPath);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Make sure the dimensions of the data channel are consistent
            %{
                The load history data must be either a 1xN or an Nx1 vector
            %}
            errorMessage1 = sprintf('Error while processing ''%s''.', loadHistoryPath);
            
            [R, C] = size(loadHistoryData);
            if (R == 1.0) && (C == 1.0)
                %{
                    The user supplied a single load history point. Fatigue
                    analysis is not possible
                %}
                errorMessage2 = sprintf('\n\nThe load history data contains a single point. At least two points are required for fatigue analysis.');
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            elseif (R > 1.0) && (C > 1.0)
                %{
                    The user suppled a an NxM load history. Only 1xN and
                    Nx1 is supported
                %}
                errorMessage2 = sprintf('\n\nThe load history data is %.0fx%.0f. Only 1xN and Nx1 vectors are supported.', R, C);
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            % If the load history is Nx1, convert it to 1xN
            if R > 1.0
                loadHistoryData = loadHistoryData';
            end
        end
        
        %% Check the stress concentration factor
        function [error] = checkSCF(handles)
            % Initialize error variable
            error = 0.0;
            
            scf = str2double(get(handles.edit_scf, 'string'));
            
            if isempty(get(handles.edit_scf, 'string')) == 1.0
                errorMessage = sprintf('The stress concentration factor must be specified.');
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
            elseif (isinf(scf) == 1.0) || (isnan(scf) == 1.0) || (isreal(scf) == 0.0)
                errorMessage = sprintf('The specified stress concentration factor is invalid.');
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
            elseif (scf < 1.0) || (scf > 10.0)
                errorMessage = sprintf('The stress concentration factor must be in the range (1 <= SCF <= 10).');
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
            end
        end
        
        %% Check the user-defined value of the Walker gamma parameter
        function [error] = checkWalkerGamma(handles, msCorrection)
            % Initialize error variable
            error = 0.0;
            
            if msCorrection == 6.0
                gamma = str2double(get(handles.edit_walkerGamma, 'string'));
                
                if isempty(get(handles.edit_walkerGamma, 'string')) == 1.0
                    errorMessage = sprintf('The Walker gamma parameter must be specified.');
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                elseif (isinf(gamma) == 1.0) || (isnan(gamma) == 1.0) || (isreal(gamma) == 0.0)
                    errorMessage = sprintf('The specified Walker gamma parameter is invalid.');
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                elseif (gamma < 0.0) || (gamma > 1.0)
                    errorMessage = sprintf('The Walker gamma parameter must be in the range (0 <= Gamma <= 1).');
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                end
            end
        end
        
        %% Read the material file
        function [returnError] = preScanMaterial(handles, msCorrection)
            %% Initialise output
            returnError = 0.0;
            
            %% Get the material properties
            material = get(handles.edit_material, 'string');
            [~, material, ~] = fileparts(material);
            error = preProcess.getMaterial(material, 0.0, 1.0);
            
            %% Check for errors
            switch error
                case 1.0
                    if strcmpi(material, 'Undefined.mat') == 1.0
                        errorMessage = sprintf('A meterial must be selected for analysis.');
                    elseif isempty(material) == 1.0
                        errorMessage = sprintf('A meterial must be selected for analysis.');
                    else
                        errorMessage = sprintf('Error while processing material ''%s''. The file could not be located.\r\n\r\nThe material must be located in ''Data/material/local'' to be used for analysis.', material);
                    end
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                case 2.0
                    errorMessage = sprintf('Error while processing material ''%s''. The file could not be opened.', material);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                case 3.0
                    errorMessage = sprintf('Error while processing material ''%s''. The file contains one or more syntax errors.', material);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                otherwise
            end
            
            %% Check that the required material properties are available
            if isempty(getappdata(0, 'poisson')) == 1.0
                missingProperties{1} = 'UNDEFINED';
            else
                missingProperties{1} = 'OK';
            end
            
            if isempty(getappdata(0, 'Sf')) == 1.0
                missingProperties{2} = 'UNDEFINED';
                missingProperties{5} = 'NOT EVALUATED';
                missingProperties{6} = 'NOT EVALUATED';
            else
                missingProperties{2} = 'OK';
                
                if isempty(getappdata(0, 'Ef')) == 1.0
                    missingProperties{5} = 'UNDEFINED';
                else
                    missingProperties{5} = 'OK';
                end
                
                if isempty(getappdata(0, 'c')) == 1.0
                    missingProperties{6} = 'UNDEFINED';
                else
                    missingProperties{6} = 'OK';
                end
            end
            
            if isempty(getappdata(0, 'E')) == 1.0
                missingProperties{3} = 'UNDEFINED';
            else
                missingProperties{3} = 'OK';
            end
            
            if isempty(getappdata(0, 'b')) == 1.0
                missingProperties{4} = 'UNDEFINED';
            else
                missingProperties{4} = 'OK';
            end
            
            if msCorrection > 0.0
                if isempty(getappdata(0, 'kp')) == 1.0
                    missingProperties{7} = 'UNDEFINED';
                else
                    missingProperties{7} = 'OK';
                end
                
                if isempty(getappdata(0, 'np')) == 1.0
                    missingProperties{8} = 'UNDEFINED';
                else
                    missingProperties{8} = 'OK';
                end
                
                if isempty(getappdata(0, 'uts')) == 1.0 && msCorrection == 2.0
                    errordlg('The ultimate tensile strength of the material is required for user-defined mean stress correction', 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                elseif isempty(getappdata(0, 'kp')) == 1.0 ||...
                        isempty(getappdata(0, 'np')) == 1.0 ||...
                        isempty(getappdata(0, 'E')) == 1.0
                    errorMessage1 = 'Cyclic properties are required for mean stress correction. The following properties are required for analysis:';
                    errorMessage2 = sprintf('\n\nYoung''s Modulus (%s)\nCyclic strain hardening coefficient (%s)\nCyclic strain hardening exponent (%s)',...
                        missingProperties{3}, missingProperties{7}, missingProperties{8});
                    errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                end
            elseif msCorrection == 2.0 && isempty(getappdata(0, 'uts')) == 1.0
                errordlg('The ultimate tensile strength of the material is required for user-defined mean stress correction', 'Quick Fatigue Tool')
                uiwait
                returnError = 1.0;
                return
            end
            
            if any(strcmpi(missingProperties, 'UNDEFINED') == 1.0)
                errorMessage1 = sprintf('Error while processing the material definition. The following properties are required for analysis:\n\n');
                errorMessage2 = sprintf('Poisson''s ratio (%s)\nYoung''s Modulus (%s)\nFatigue strength coefficient (%s)\n',...
                    missingProperties{1}, missingProperties{3}, missingProperties{2});
                errorMessage3 = sprintf('Fatigue strength exponent (%s)\nFatigue ductility coefficient (%s)\nFatigue ductility exponent (%s)',...
                    missingProperties{4}, missingProperties{5}, missingProperties{6});
                errorMessage = [errorMessage1, errorMessage2, errorMessage3];
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                returnError = 1.0;
                return
            end
        end
        
        %% Check if the output directory exists
        function [error, path] = checkOutput(checkLocation, path)
            error = 0.0;
            
            c = clock;
            dateString = datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6)));
            
            if checkLocation == 0.0
                %{
                    Using the default results directory. Construct
                    the results directory using the current itme stamp
                %}
                for i = 1:length(dateString)
                    if (strcmpi(dateString(i), ':') == 1.0) || (strcmpi(dateString(i), ' ') == 1.0)
                        dateString(i) = '_';
                    end
                end
                
                path = [pwd, sprintf('/Project/output/gauge_fatigue_results_%s', dateString)];
                
                % If the output directory  does not exist, create it
                if exist(path, 'dir') == 0.0
                    mkdir(path)
                elseif exist(path, 'dir') == 7.0
                    %{
                        The current output path already exists, so append
                        an additional character to the path
                    %}
                    path = [path, '_1'];
                end
            else
                %{
                    Using a custom results directory. Check if the results
                    directory exists
                %}
                if isempty(path) == 1.0
                    error = 1.0;
                    return
                elseif exist(path, 'dir') == 0.0
                    try
                        mkdir(path)
                    catch
                        error = 2.0;
                        return
                    end
                end
            end
            
            % Save the file name and date
            setappdata(0, 'outputPath', path)
            setappdata(0, 'dateString', dateString)
        end
        
        %% Get principal stress history from principal strain history (NEW)
        function [sigma, trueStressCurveBuffer, trueStrainCurveBuffer] =...
                getPrincipalStress(epsilon, E, kp, np)
            
            %{
                If out-of-plane strains are being ignored, EPSILON will be
                0.0. In this case, skip the calculation
            %}
            if length(epsilon) == 1.0
                if epsilon == 0.0
                    sigma = 0.0;
                    trueStressCurveBuffer = 0.0;
                    trueStrainCurveBuffer = 0.0;
                    return
                end
            end
            
            %% Append the signal with zero if necessary
            removeZero = 0.0;
            if epsilon(1.0) ~= 0.0
                epsilon = [0.0, epsilon];
                removeZero = 1.0;
            end
            
            %% Initialize the precision
            precision = 1e3;
            %method = 'pchip';
            method = 'linear';
            
            % Get the signal length
            signalLength = length(epsilon);

            % Initialize the true stress values
            sigma = zeros(1.0, signalLength);
            
            %{
                Initialize the buffer to store the stress-strain curves for
                MATLAB figures
            %}
            trueStressCurveBuffer = cell(1.0, 1.0);
            trueStrainCurveBuffer = cell(1.0, 1.0);
            
            %% Calcualte the monotonic stage
            %{
                The first excursion is assumed to be monotonic, therefore
                it is calculated separately
            %}
            %{
                Get the range of stresses along the R-O curve. Since the
                true stress at the current strain is not yet known, the
                upper bound of the curve is estimated as the elastic
                stress. This is a safe guess since the elastic stress is
                larger than the true stress
            %}
            trueStressCurve = linspace(0.0, epsilon(2.0)*E, precision);
            
            %{
                The true strain curve is found by substituting the true
                stress curve into the monotonic R-O equation
            %}
            trueStrainCurve = real((trueStressCurve./E) + (trueStressCurve./kp).^(1.0/np));
            
            %{
                The true stress at the current strain is found by
                interpolating the R-O curve. Linear extrapolation should
                not be required since the stress datapoints should always
                contain the true stress value somewhere within it
            %}
            sigma(2.0) = interp1(trueStrainCurve, trueStressCurve, epsilon(2.0), method, 'extrap');
            
            %{
                Save the stress and strain curves into the buffer. Only the
                stress-strain points upto the stress solution (or current
                strain range) are required
            %}
            [~, limitPoint] = min(abs(trueStrainCurve - epsilon(2.0)));
            trueStressCurveBuffer{1.0} = trueStressCurve(1.0:limitPoint);
            trueStrainCurveBuffer{1.0} = trueStrainCurve(1.0:limitPoint);
            
            %% Calculate the cyclic stage
            %{
                The remainder of stress-strain data points are assumed to
                be cyclically stable i.e. the cyclic version of the R-O
                equation can be used to determine every other stress point
                in the strain history
            %}
            
            currentStrainRange = abs(epsilon(2.0));
            
            strainRangeBuffer = currentStrainRange;
            
            allowClosure = 1.0;
            
            matMemFirstExcursion = 1.0;
            matMemFirstExcursionIndex = 2.0;
            ratchetStrain = 0.0;
            
            for i = 3:signalLength
                
                %{
                    Calculate the current strain range. If the signal did
                    not reverse direction, the current strain range must
                    take into account the entire excursion, not just the
                    current strain increment
                %}
                previousStrainRange = currentStrainRange;
                currentStrainRange = abs(epsilon(i) - epsilon(i - 1.0));
                strainRangeBuffer(i - 1.0) = currentStrainRange;
                
                % Record the direction of the current excursion
                if epsilon(i) - epsilon(i - 1.0) > 0.0
                    % The current excursion is moving forward
                    currentDirection = 1.0;
                else
                    % The current excursion is moving backwards
                    currentDirection = -1.0;
                end
                
                %{
                    The current strain range is smaller than the first
                    cyclic excusrion since the previous cycle closure.
                    Successive cycle closures cannot assume the path of the
                    monotonic excursion
                %}
                if currentStrainRange < strainRangeBuffer(matMemFirstExcursionIndex)
                    matMemFirstExcursion = 0.0;
                end
                
                %{
                    It is now possible for hysteresis loops to be closed.
                    If the current strain range exceeds the previous strain
                    range, a loop has bee closed
                    
                    When a loop is closed, the material memory effect
                    becomes observable, so the next stress data point must
                    be calculated from the curve defining the stress value
                    two indexes previously
                
                    The cycle is only closed if the current (larger) strain
                    range is in the opposite direction to the previous
                    strain range
                %}
                if (currentStrainRange > previousStrainRange) && (i > 3.0) && (allowClosure == 1.0)
                    %%
                    %{
                        A cycle has been closed
                    
                        The current strain range exceeds the previous
                        strain range, therefore material memory must be
                        accounted for
                    
                        The first cycle closure can only occur at the
                        earliest on the third reversal. Therefore, do not
                        allow cycle closures before i > 3.0
                    %}
                    
                    %{
                        Since the cycle closure includes the effect of
                        material memory, the next reversal may not close a
                        cycle
                    %}
                    allowClosure = 0.0;
                    
                    %{
                        The stable loop strain range is taken to be the
                        strain rang eof the previously closed cycle
                    %}
                    matMemFirstExcursionIndex = i;
                    
                    %{
                        Calculate the portion of the strain range which
                        accounts only for the distance beyond the cycle
                        closure point
                    %}
                    strainRangeBeyondClosure = currentStrainRange - previousStrainRange;
                    
                    %{
                        The stress is calculated from the curve two
                        excursions ago. The current strain range is the
                        strain range from this excursion, plus the
                        additional strain range beyond the current cycle
                        closure point
                    %}
                    if matMemFirstExcursion == 1.0
                        strainRange = strainRangeBuffer(1.0) + strainRangeBeyondClosure + ratchetStrain;
                    else
                        strainRange = strainRangeBuffer(i - 3.0) + strainRangeBeyondClosure;
                    end
                    
                    if currentDirection == -1.0
                        trueStressCurve = linspace(0.0, -strainRange*E, precision);
                    else
                        trueStressCurve = linspace(0.0, strainRange*E, precision);
                    end
                    
                    % Calculate the stress-strain curve
                    %{
                        If the excursion used for the material memory is
                        the first excursion in the loading, the monotonic
                        stress-strain curve must be used instead
                    %}
                    if matMemFirstExcursion == 1.0
                        previousRatchetStrain = ratchetStrain;
                        ratchetStrain = ratchetStrain + strainRangeBeyondClosure;
                        
                        trueStrainCurve = real((abs(trueStressCurve)./E) + (abs(trueStressCurve)./kp).^(1.0/np));
                    else
                        trueStrainCurve = real((abs(trueStressCurve)./E) + 2.0.*(abs(trueStressCurve)./(2.0*kp)).^(1.0/np));
                    end
                    
                    % Solve for the stress range
                    stressRange = interp1(trueStrainCurve, trueStressCurve, strainRange, method, 'extrap');
                    
                    if matMemFirstExcursion == 1.0
                        sigma(i) = sigma(1.0) + stressRange;
                    else
                        sigma(i) = sigma(i - 3.0) + stressRange;
                    end
                    
                    %%
                    %{
                        In order to plot the curves later on, it is
                        necessary to save the portion of the curve up to
                        cycle closure and the extension region where
                        material memory takes effect, then concatenate
                        these two curves together
                    %}
                    
                    strainRange_A = currentStrainRange - strainRangeBeyondClosure;
                    strainRange_B = strainRange;
                    
                    trueStressCurve_A = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    trueStressCurve_B = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    
                    % Get the stress-strain curve up to the point of cycle closure
                    trueStrainCurve_A = real((trueStressCurve_A./E) + 2.0.*(trueStressCurve_A./(2.0*kp)).^(1.0/np));
                    
                    [~, limitPoint_A] = min(abs(abs(trueStrainCurve_A) - strainRange_A));
                    
                    trueStrainCurve_A = trueStrainCurve_A(1.0:limitPoint_A);
                    trueStressCurve_A = trueStressCurve_A(1.0:limitPoint_A);
                    
                    % Get the stress-strsin curve beyond the point of cycle closure
                    if matMemFirstExcursion == 1.0
                        trueStrainCurve_B = real((trueStressCurve_B./E) + (trueStressCurve_B./kp).^(1.0/np));
                        [~, limitPoint_A] = min(abs(abs(trueStrainCurve_B) - (strainRangeBuffer(1.0) + previousRatchetStrain)));
                    else
                        trueStrainCurve_B = real((trueStressCurve_B./E) + 2.0.*(trueStressCurve_B./(2.0*kp)).^(1.0/np));
                        [~, limitPoint_A] = min(abs(abs(trueStrainCurve_B) - strainRangeBuffer(i - 3.0)));
                    end
                    
                    [~, limitPoint_B] = min(abs(abs(trueStrainCurve_B) - strainRange_B));
                    
                    trueStressCurve_B = trueStressCurve_B(limitPoint_A : limitPoint_B);
                    trueStrainCurve_B = trueStrainCurve_B(limitPoint_A : limitPoint_B);
                    
                    stressDifference = abs(trueStressCurve_B(1.0) - trueStressCurve_A(end));
                    strainDifference = abs(trueStrainCurve_B(1.0) - trueStrainCurve_A(end));
                    if trueStressCurve_B(1.0) > trueStressCurve_A(end)
                        trueStressCurve_B = trueStressCurve_B - stressDifference;
                    else
                        trueStressCurve_B = trueStressCurve_B + stressDifference;
                    end
                    
                    if trueStrainCurve_B(1.0) > trueStrainCurve_A(end)
                        trueStrainCurve_B = trueStrainCurve_B - strainDifference;
                    else
                        trueStrainCurve_B = trueStrainCurve_B + strainDifference;
                    end
                    
                    trueStressCurveBuffer{i - 1.0} = [trueStressCurve_A, trueStressCurve_B];
                    trueStrainCurveBuffer{i - 1.0} = [trueStrainCurve_A, trueStrainCurve_B];
                elseif (currentStrainRange == previousStrainRange) && (i > 3.0) && (allowClosure == 1.0)
                    %%
                    %{
                        A cycle has been closed
                    
                        The current strain range equals the previous
                        strain range, therefore material memory does not
                        take effect
                    
                        The first cycle closure can only occur at the
                        earliest on the third reversal. Therefore, do not
                        allow cycle closures before i > 3.0
                    %}
                    
                    %{
                        Since the cycle closure does not include the effect
                        of material memory, the next reversal may close a
                        cycle
                    %}
                    allowClosure = 1.0;
                    
                    if currentDirection == -1.0
                        trueStressCurve = linspace(0.0, -currentStrainRange*E, precision);
                    else
                        trueStressCurve = linspace(0.0, currentStrainRange*E, precision);
                    end
                    
                    % Calculate the stress-strain curve
                    trueStrainCurve = real((abs(trueStressCurve)./E) + 2.0.*(abs(trueStressCurve)./(2.0*kp)).^(1.0/np));
                    
                    % Solve for the stress range
                    stressRange = interp1(trueStrainCurve, trueStressCurve, currentStrainRange, method, 'extrap');
                    
                    sigma(i) = sigma(i - 1.0) + stressRange;
                    
                    %%
                    %{
                        Save the stress and strain curves into the buffer.
                        Only the stress-strain points upto the stress
                        solution (or current strain range) are required
                    %}
                    trueStressCurve = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
                    [~, limitPoint] = min(abs(abs(trueStrainCurve) - currentStrainRange));
                    trueStressCurveBuffer{i - 1.0} = trueStressCurve(1.0:limitPoint);
                    trueStrainCurveBuffer{i - 1.0} = trueStrainCurve(1.0:limitPoint);
                else
                    %%
                    %{
                        No cycle has been closed

                        The current stress curve starts at the previously
                        calculated true stress value, and ends at a
                        location defined by the elastic stress
                        corresponding to the current strain point
                    %}
                    
                    %{
                        Since this reversal did not result in cycle
                        closure, the next reversal may close a cycle
                    %}
                    allowClosure = 1.0;
                    
                    if currentDirection == -1.0
                        trueStressCurve = linspace(0.0, -currentStrainRange*E, precision);
                    else
                        trueStressCurve = linspace(0.0, currentStrainRange*E, precision);
                    end
                    
                    trueStrainCurve = real((abs(trueStressCurve)./E) + 2.0.*(abs(trueStressCurve)./(2.0*kp)).^(1.0/np));
                    
                    % Solve for the stress range
                    stressRange = interp1(trueStrainCurve, trueStressCurve, currentStrainRange, method, 'extrap');
                    
                    sigma(i) = sigma(i - 1.0) + stressRange;
                    
                    %{
                        Save the stress and strain curves into the buffer.
                        Only the stress-strain points upto the stress
                        solution (or current strain range) are required
                    %}
                    trueStressCurve = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
                    [~, limitPoint] = min(abs(abs(trueStrainCurve) - currentStrainRange));
                    trueStressCurveBuffer{i - 1.0} = trueStressCurve(1.0:limitPoint);
                    trueStrainCurveBuffer{i - 1.0} = trueStrainCurve(1.0:limitPoint);
                end
            end
            
            if removeZero == 1.0
                sigma(1.0) = [];
            end
        end
        
        %% Get the fatigue limit stress
        function [] = getFatigueLimit(algorithm)
            %% Calculate the endurance limit
            
            % Recall the material properties
            cael = getappdata(0, 'cael');
            Sf = getappdata(0, 'Sf');
            b = getappdata(0, 'b');
            E = getappdata(0, 'E');
            Ef = getappdata(0, 'Ef');
            c = getappdata(0, 'c');

            if algorithm == 2.0 %SBBM
                conditionalStrain = ((1.65*Sf)/(E))*(cael)^b + (1.75*Ef)*(cael)^c;
            else % PS
                conditionalStrain = (Sf/E)*(cael)^b + Ef*(cael)^c;
            end
            
            setappdata(0, 'fatigueLimit_strain', conditionalStrain)
            setappdata(0, 'fatigueLimit_stress', conditionalStrain*E)
        end
    end
end