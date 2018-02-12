classdef uniaxialPreProcess < handle
%UNIAXIALPREPROCESS    QFT class for Uniaxial Strain-Life.
%   This class contains methods for the Uniaxial Strain-Life application.
%   
%   UNIAXIALPREPROCESS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also uniaxialAnalysis, uniaxialPostProcess, UniaxialStrainLife
%   
%   Reference section in Quick Fatigue Tool Appendices
%      A3.6 Uniaxial Strain-Life
%   
%   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
%   Last modified 30-Aug-2017 18:00:59 GMT
    
    %%
    
    methods (Static = true)
        %% Prescan the file selection
        function [loadHistoryData, error] = preScanFile(handles)
            %% Initialise output
            error = 0.0;
            loadHistoryData = [];
            
            %% Get the string of the input file dialogue
            loadHistoryPath = get(handles.edit_inputFile, 'string');
            
            %% Check if the file exists
            if isempty(loadHistoryPath) == 1.0
                errordlg('A load history must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            elseif get(handles.edit_inputFile, 'foregroundColor') ==  [0.5, 0.5, 0.5] %#ok<BDSCA>
                errordlg('A load history must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Check if the input is a numeric array
            %{
                The user can supply the load history directly as a numeric
                array. Before trying to search for the file, see if the
                input can be evaluated as an array
            %}
            errorString = sprintf('input: ''%s''', loadHistoryPath);
            fileOrNum = 0.0;
            if (strcmpi(loadHistoryPath(1.0), '[') == 1.0) && (isnumeric(str2num(loadHistoryPath)) == 1.0) %#ok<ST2NM>
                loadHistoryData = str2num(loadHistoryPath); %#ok<ST2NM>
                
                if isempty(loadHistoryData) == 1.0
                    errorMessage = sprintf('Error while processing numerical input.\n\nThe expression could not be evaluated.');
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                end
                
                fileOrNum = 1.0;
                errorString = sprintf('numerical input');
            end
            
            %% Check if the input is a file
            if (exist(loadHistoryPath, 'file') == 0.0) && (fileOrNum == 0.0)
                errorMessage = sprintf('Error while processing input: ''%s''.\n\nThe expression is not a valid file path or a numerical array.', loadHistoryPath);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            elseif fileOrNum == 0.0
                %% Check if the file can be read
                try
                    loadHistoryData = dlmread(loadHistoryPath);
                catch
                    errorMessage = sprintf('Error while processing input: ''%s''.\n\nThe file could not be read.', loadHistoryPath);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                    return
                end
            end
            
            %% Check for non-numeric data in each file
            if (any(any(isinf(loadHistoryData))) == 1.0) || (any(any(isnan(loadHistoryData))) == 1.0) || (any(any(isreal(loadHistoryData))) == 0.0)
                errorMessage = sprintf('Error while processing %s.\n\nSome of the data has inf, NaN or complex values.', errorString);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Make sure the dimensions of the data channel are consistent
            %{
                The load history data must be either a 1xN or an Nx1 vector
            %}
            errorMessage1 = sprintf('Error while processing %s.\n\n', errorString);
            
            [R, C] = size(loadHistoryData);
            if (R == 1.0) && (C == 1.0)
                %{
                    The user supplied a single load history point. Fatigue
                    analysis is not possible
                %}
                errorMessage2 = sprintf('The load history data contains a single point. At least two points are required for fatigue analysis.');
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            elseif (R > 1.0) && (C > 1.0)
                %{
                    The user suppled a an NxM load history. Only 1xN and
                    Nx1 is supported
                %}
                errorMessage2 = sprintf('The load history data is %.0fx%.0f. Only 1xN and Nx1 vectors are supported.', R, C);
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            % If the load history is Nx1, convert it to 1xN
            if R > 1.0
                loadHistoryData = loadHistoryData';
            end
            
            % Check for fatigue
            if length(unique(loadHistoryData)) == 1.0
                errorMessage = sprintf('Error while processing %s.\n\nThere is no fatigue in the load history.', errorString);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
        end
        
        %% Check the stress concentration factor
        function [error, scf] = checkSCF(handles)
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
        function [error, gamma] = checkWalkerGamma(handles, msCorrection, uts, behaviour)
            % Initialize error variable
            error = 0.0;
            gamma = [];
            
            switch msCorrection
                case 4.0 % Walker (standard)
                    switch behaviour
                        case 1.0 % Calculate gamma based on Dowling for steel
                            gamma = 0.65;
                        case 2.0 % Calculate gamma based on Dowling for aluminium
                            gamma = 0.45;
                        otherwise % Calculate gamma based on load ratio
                            gamma = -9999.0;
                    end
                case 5.0 % Walker (regression)
                    switch behaviour
                        case 1.0 % Steel
                            gamma = (-0.0002*uts) + 0.8818;
                        case 2.0 % Aluminium
                            if uts < 365.0
                                gamma = 0.651;
                            elseif uts > 475.0
                                gamma = 0.473;
                            else
                                gamma = 0.651 + (-0.001618181*(uts - 365.0));
                            end
                        case 3.0 % Other
                            gamma = (-0.0002*uts) + 0.8818;
                        otherwise
                    end
                case 6.0 % Walker (gamma)
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
                otherwise
            end
        end
        
        %% Read the material file
        function [error] = preScanMaterial(handles, msCorrection)
            %% Initialise output
            error = 0.0;
            
            %% Get the material properties
            material = get(handles.edit_material, 'string');
            [~, material, ~] = fileparts(material);
            materialError = preProcess.getMaterial(material, 0.0, 1.0);
            
            %% Check for errors
            switch materialError
                case 1.0
                    if strcmpi(material, 'Undefined.mat') == 1.0
                        errorMessage = sprintf('A material must be selected for analysis.');
                    elseif isempty(material) == 1.0
                        errorMessage = sprintf('A material must be selected for analysis.');
                    else
                        errorMessage = sprintf('Error while processing material ''%s''. The file could not be located.', material);
                    end
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                    return
                case 2.0
                    errorMessage = sprintf('Error while processing material ''%s''. The file could not be opened.', material);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                    return
                case 3.0
                    errorMessage = sprintf('Error while processing material ''%s''. The file contains one or more syntax errors.', material);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                    return
                otherwise
            end
            
            %% Check that the required material properties are available
            %{
                All of the following properties must be defined in order to
                perform the uniaxial strain-life fatigue analysis:
            
                E
                Sf'
                b
                Ef'
                c
                kp'
                np'
            
                If the Walker (regression) mean stress correction is
                selected, the material UTS is also required.
            %}
            % Cell containing missing material properties
            missingProperties = cell([], []);
            
            if isempty(getappdata(0, 'E')) == 1.0
                missingProperties = [missingProperties, 'Young''s Modulus: E'];
            end
            
            if isempty(getappdata(0, 'Sf')) == 1.0
                missingProperties = [missingProperties, 'Fatigue strength coefficient: Sf'];
            end
            
            if isempty(getappdata(0, 'b')) == 1.0
                missingProperties = [missingProperties, 'Fatigue strength exponent: b'];
            end
            
            if isempty(getappdata(0, 'Ef')) == 1.0
                missingProperties = [missingProperties, 'Fatigue ductility coefficient: Ef'];
            end
            
            if isempty(getappdata(0, 'c')) == 1.0
                missingProperties = [missingProperties, 'Fatigue ductility exponent: c'];
            end
            
            if isempty(getappdata(0, 'kp')) == 1.0
                missingProperties = [missingProperties, 'Cyclic strain-hardening coefficient: kp'];
            end
            
            if isempty(getappdata(0, 'np')) == 1.0
                missingProperties = [missingProperties, 'Cyclic strain-hardening exponent: np'];
            end
            
            % If there are any missing properties, exit with an error
            if isempty(missingProperties) == 0.0
                errorMessage1 = sprintf('The material definition is insufficient for strain-life fatigue analysis. The following properties are missing:\r\n\r\n');
                errorMessage2 = sprintf('%s\r\n', missingProperties{:});
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            % Check for the ultimate tensile stress if applicable
            if (msCorrection == 5.0) && (isempty(getappdata(0, 'uts')) == 1.0)
                errorMessage = sprintf('The Walker (regression) mean stress correction requires a value of the ultimate tensile strength. Check the material definition.');
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
        end
        
        %% Check if the output directory exists
        function [error, path, dateString] = checkOutput(checkLocation, path)
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
                
                path = [pwd, sprintf('\\Project\\output\\uniaxial_strain_life_results_%s', dateString)];
                
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
                    errorMessage = sprintf('The results location cannot be empty.');
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                elseif exist(path, 'dir') == 0.0
                    try
                        mkdir(path)
                    catch
                        try
                            rmdir(path)
                        catch
                        end
                        
                        errorMessage = sprintf('The specified output file path could not be created. Check that the drive location exists and has read/write access.');
                        errordlg(errorMessage, 'Quick Fatigue Tool')
                        uiwait
                        error = 1.0;
                    end
                end
            end
        end
        
        %% Get the elastic principal stress
        function [S1, S2] = getElasticPrincipalStressFromElasticStress(Sxx, Syy, Szz, Txy, Txz, Tyz, L)
            %{
                This function is required if the input load history is
                elastic stress
            %}
            
            %{
            	Construct a 3x3xL multidimensional array of the
                stress tensor history, where L is the history
                length
            %}
            % Direct stress components
            normals = [Sxx; Syy; Szz]';
            
            % Shear stress components
            shears = [Txy; Txz; Tyz]';
            
            % Assign normal stress component histories to diagonal terms
            diagonals = repmat(eye([3.0, 3.0]), 1.0, 1.0, L);
            diagonals(diagonals > 0.0) = normals';
            
            % Assign shear stress component histories to non-diagonal terms
            nonDiagonals = repmat(tril(ones(3.0), -1.0), 1.0, 1.0, L);
            nonDiagonals(nonDiagonals > 0.0) = shears';
            
            % Combine diagonal and non-diagonal terms
            multidimensionalStressTensor = diagonals + nonDiagonals + permute(nonDiagonals, [2.0, 1.0, 3.0]);
            
            % Get the Eigenvalues for each frame of the tensor data
            eigenvalues = eig3(multidimensionalStressTensor);
            
            %{
            	The principal stresses are the maximum, median
                and minimum values of the Eigenvector at each
                tensor frame
            %}
            S1 = max(real(eigenvalues));
            S2 = min(real(eigenvalues));
        end
        
        %% Get inelastic stress history from inelastic strain history (NEW)
        function [rfData, sigma, trueStressCurveBuffer, trueStrainCurveBuffer] =...
                getInelasticStressFromInelasticStrain(epsilon, E, kp, np)
            
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
                    %trueStressCurve = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    %trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
                    %[~, limitPoint] = min(abs(abs(trueStrainCurve) - currentStrainRange));
                    %trueStressCurveBuffer{i - 1.0} = trueStressCurve(1.0:limitPoint);
                    %trueStrainCurveBuffer{i - 1.0} = trueStrainCurve(1.0:limitPoint);
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
                    %trueStressCurve = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    %trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
                    %[~, limitPoint] = min(abs(abs(trueStrainCurve) - currentStrainRange));
                    %trueStressCurveBuffer{i - 1.0} = trueStressCurve(1.0:limitPoint);
                    %trueStrainCurveBuffer{i - 1.0} = trueStrainCurve(1.0:limitPoint);
                end
            end
            
            %% Rainflow cycle count the inelastic histories
            
            % Rainflow cycle count the inelastic stress/strain signals
            rfData_e = analysis.rainFlow_2(epsilon);
            rfData_s = analysis.rainFlow_2(sigma);
            
            % Get the number of cycle
            [nCycles_e, ~] = size(rfData_e);
            [nCycles_s, ~] = size(rfData_s);
            
            % Make sure matrices are same size
            if nCycles_e > nCycles_s
                diff = nCycles_e - nCycles_s;
                rfData_s(end + 1.0: end + diff, 1:4) = zeros(diff, 4.0);
            elseif nCycles_e < nCycles_s
                diff = nCycles_s - nCycles_e;
                rfData_e(end + 1.0: end + diff, 1:4) = zeros(diff, 4.0);
            end
            
            % Concatenate cycles into single buffer
            %{
                1: Min. stress
                2: Max. stress
                3: Min. strain
                4: Max. strain
                5: Min. index
                6: Max. index
            %}
            rfData = [rfData_s(:, 1:2), rfData_e(:, 1:2), rfData_s(:, 3:4)];
            
            % Remove leading zero from stress signal if applicable
            if removeZero == 1.0
                sigma(1.0) = [];
            end
        end
        
        %% Get the fatigue limit stress
        function [fatigueLimitSress, fatigueLimitSrain] = getFatigueLimit(cael, E, kp, np, Sf, b, Ef, c)
            %{
                Calculate the fatigue limit of the material based on the
                strain-life relationship.
            %}

            fatigueLimitSrain = (Sf/E)*(cael)^b + Ef*(cael)^c;
            [~, fatigueLimitSress, ~, ~] = uniaxialPreProcess.getInelasticStressFromInelasticStrain(fatigueLimitSrain, E, kp, np);
        end
    end
end