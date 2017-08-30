classdef rosetteTools < handle
%ROSETTETOOLS    QFT class for Rosette Analysis.
%   This class contains methods for the Rosette Analysis application.
%   
%   ROSETTETOOLS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also RosetteAnalysis.
%   
%   Reference section in Quick Fatigue Tool Appendices
%      A3.3 Rosette Analysis
%   
%   Quick Fatigue Tool 6.11-03 Copyright Louis Vallance 2017
%   Last modified 23-Jun-2017 08:19:31 GMT
    
    %%
    
    methods (Static = true)
        %% Blank the GUI
        function [] = blank(handles)
            set(findall(handles.RosetteAnalysis, '-property', 'Enable'), 'Enable', 'off')
        end
        
        %% Show the GUI
        function [] = show(handles)
            set(findall(handles.RosetteAnalysis, '-property', 'Enable'), 'Enable', 'on')
            
            set(handles.pButton_strainUnits, 'enable', 'inactive')
            
            if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                set(handles.text_E, 'enable', 'off')
                set(handles.edit_E, 'enable', 'off')
                set(handles.text_eUnits, 'enable', 'off')
                set(handles.text_poisson, 'enable', 'off')
                set(handles.edit_poisson, 'enable', 'off')
            end
            
            if get(handles.check_outputLocation, 'value') == 0.0
                set(handles.edit_outputLocation, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
                set(handles.pButton_outputLocation, 'enable', 'off') 
            end
        end
        
        %% Verify inputs
        function [alpha, beta, gamma, E, v, outputLocation, gaugeDataA, gaugeDataB, gaugeDataC, error, errorMessage] = verifyInput(handles)
            % Initialize output
            alpha = -1.0;
            beta = -1.0;
            gamma = -1.0;
            E = -1.0;
            v = -1.0;
            outputLocation = -1.0;
            error = 0.0;
            errorMessage = -1.0;
            gaugeANumeric = 0.0;
            gaugeBNumeric = 0.0;
            gaugeCNumeric = 0.0;
            
            gaugeDataA = [];
            gaugeDataB = [];
            gaugeDataC = [];
            
            gaugeFileA = get(handles.edit_gaugeA, 'string');
            gaugeFileB = get(handles.edit_gaugeB, 'string');
            gaugeFileC = get(handles.edit_gaugeC, 'string');
            
            %% Check if the file exists
            % Gauge A
            if isempty(gaugeFileA) == 1.0
                errorMessage = 'All three gauges must be specified.';
                error = 1.0;
                return
            elseif get(handles.edit_gaugeA, 'foregroundColor') ==  [0.5, 0.5, 0.5] %#ok<BDSCA>
                errorMessage = 'All three gauges must be specified.';
                error = 1.0;
                return
            end
            
            % Gauge B
            if isempty(gaugeFileB) == 1.0
                errorMessage = 'All three gauges must be specified.';
                error = 1.0;
                return
            elseif get(handles.edit_gaugeB, 'foregroundColor') ==  [0.5, 0.5, 0.5] %#ok<BDSCA>
                errorMessage = 'All three gauges must be specified.';
                error = 1.0;
                return
            end
            
            % Gauge C
            if isempty(gaugeFileC) == 1.0
                errorMessage = 'All three gauges must be specified.';
                error = 1.0;
                return
            elseif get(handles.edit_gaugeC, 'foregroundColor') ==  [0.5, 0.5, 0.5] %#ok<BDSCA>
                errorMessage = 'All three gauges must be specified.';
                error = 1.0;
                return
            end
            
            %% Check if the input is a numeric array
            %{
                The user can supply the gauge definition directly as a
                numeric array. Before trying to search for the file, see if
                the input can be evaluated as an array
            %}
            % Gauge A
            if (strcmpi(gaugeFileA(1.0), '[') == 1.0) && (isnumeric(str2num(gaugeFileA)) == 1.0) %#ok<ST2NM>
                gaugeDataA = str2num(gaugeFileA); %#ok<ST2NM>
                gaugeANumeric = 1.0;
                
                if isempty(gaugeDataA) == 1.0
                    errorMessage = sprintf('Error while processing input for Gauge A: ''%s''.\n\nThe expression could not be evaluated.', gaugeFileA);
                    error = 1.0;
                    return
                end
            end
            
            % Gauge B
            if (strcmpi(gaugeFileB(1.0), '[') == 1.0) && (isnumeric(str2num(gaugeFileB)) == 1.0) %#ok<ST2NM>
                gaugeDataB = str2num(gaugeFileB); %#ok<ST2NM>
                gaugeBNumeric = 1.0;
                
                if isempty(gaugeDataB) == 1.0
                    errorMessage = sprintf('Error while processing input for Gauge B: ''%s''.\n\nThe expression could not be evaluated.', gaugeFileB);
                    error = 1.0;
                    return
                end
            end
            
            % Gauge C
            if (strcmpi(gaugeFileC(1.0), '[') == 1.0) && (isnumeric(str2num(gaugeFileC)) == 1.0) %#ok<ST2NM>
                gaugeDataC = str2num(gaugeFileC); %#ok<ST2NM>
                gaugeCNumeric = 1.0;
                
                if isempty(gaugeDataC) == 1.0
                    errorMessage = sprintf('Error while processing input for Gauge C: ''%s''.\n\nThe expression could not be evaluated.', gaugeFileC);
                    error = 1.0;
                    return
                end
            end
            
            %% Check if the input is a file
            % Gauge A
            if (gaugeANumeric == 0.0) && (exist(gaugeFileA, 'file') == 0.0)
                errorMessage = sprintf('Error while processing input for Gauge A: ''%s''.\n\nThe expression is not a valid file path or a numerical array.', gaugeFileA);
                error = 1.0;
                return
            end
            
            % Gauge B
            if (gaugeBNumeric == 0.0) && (exist(gaugeFileB, 'file') == 0.0)
                errorMessage = sprintf('Error while processing input for Gauge B: ''%s''.\n\nThe expression is not a valid file path or a numerical array.', gaugeFileB);
                error = 1.0;
                return
            end
            
            % Gauge C
            if (gaugeCNumeric == 0.0) && (exist(gaugeFileC, 'file') == 0.0)
                errorMessage = sprintf('Error while processing input for Gauge C: ''%s''.\n\nThe expression is not a valid file path or a numerical array.', gaugeFileC);
                error = 1.0;
                return
            end
            
            %% Check if the file can be read
            % Gauge A
            if gaugeANumeric == 0.0
                try
                    gaugeDataA = dlmread(gaugeFileA);
                catch
                    errorMessage = sprintf('Error while processing input for Gauge A: ''%s''.\n\nThe file could not be read.', gaugeFileA);
                    error = 1.0;
                    return
                end
            end
            
            % Gauge B
            if gaugeBNumeric == 0.0
                try
                    gaugeDataB = dlmread(gaugeFileB);
                catch
                    errorMessage = sprintf('Error while processing input for Gauge B: ''%s''.\n\nThe file could not be read.', gaugeFileB);
                    error = 1.0;
                    return
                end
            end
            
            % Gauge C
            if gaugeCNumeric == 0.0
                try
                    gaugeDataC = dlmread(gaugeFileC);
                catch
                    errorMessage = sprintf('Error while processing input for Gauge C: ''%s''.\n\nThe file could not be read.', gaugeFileC);
                    error = 1.0;
                    return
                end
            end
            
            %% Check for non-numeric data in each file
            % Gauge A
            if (any(any(isinf(gaugeDataA))) == 1.0) || (any(any(isnan(gaugeDataA))) == 1.0) || (any(any(isreal(gaugeDataA))) == 0.0)
                errorMessage = sprintf('Error while processing input for Gauge A: ''%s''.\n\nSome of the data has inf, NaN or complex values.', gaugeFileA);
                error = 1.0;
                return
            end
            
            % Gauge B
            if (any(any(isinf(gaugeDataB))) == 1.0) || (any(any(isnan(gaugeDataB))) == 1.0) || (any(any(isreal(gaugeDataB))) == 0.0)
                errorMessage = sprintf('Error while processing input for Gauge B: ''%s''.\n\nSome of the data has inf, NaN or complex values.', gaugeFileB);
                error = 1.0;
                return
            end
            
            % Gauge C
            if (any(any(isinf(gaugeDataC))) == 1.0) || (any(any(isnan(gaugeDataC))) == 1.0) || (any(any(isreal(gaugeDataC))) == 0.0)
                errorMessage = sprintf('Error while processing input for Gauge C: ''%s''.\n\nSome of the data has inf, NaN or complex values.', gaugeFileC);
                error = 1.0;
                return
            end
            
            %% Check the gauge orientation defintition
            alpha = str2double(get(handles.edit_alpha, 'string'));
            
            if isempty(get(handles.edit_alpha, 'string')) == 1.0
                error = 1.0;
                errorMessage = 'Please specify a value of Alpha.';
            elseif (isnumeric(alpha) == 0.0) || (isinf(alpha) == 1.0) || (isnan(alpha) == 1.0)
                error = 1.0;
                errorMessage = 'An invalid Alpha value was specified.';
            elseif (alpha < 0.0) || (alpha >= 180.0)
                error = 1.0;
                errorMessage = 'Alpha must be in the range (0 <= Alpha < 180).';
            end
            
            if error == 1.0
                return
            end
            
            beta = str2double(get(handles.edit_beta, 'string'));
            
            if isempty(get(handles.edit_beta, 'string')) == 1.0
                error = 1.0;
                errorMessage = 'Please specify a value of Beta.';
            elseif (isnumeric(beta) == 0.0) || (isinf(beta) == 1.0) || (isnan(beta) == 1.0)
                error = 1.0;
                errorMessage = 'An invalid Beta value was specified.';
            elseif (beta <= 0.0) || (beta >= 180.0)
                error = 1.0;
                errorMessage = 'Beta must be in the range (0 < Beta < 180).';
            end
            
            if error == 1.0
                return
            end
            
            gamma = str2double(get(handles.edit_gamma, 'string'));
            
            if isempty(get(handles.edit_gamma, 'string')) == 1.0
                error = 1.0;
                errorMessage = 'Please specify a value of Gamma.';
            elseif (isnumeric(gamma) == 0.0) || (isinf(gamma) == 1.0) || (isnan(gamma) == 1.0)
                error = 1.0;
                errorMessage = 'An invalid Gamma value was specified.';
            elseif (gamma <= 0.0) || (gamma >= 180.0)
                error = 1.0;
                errorMessage = 'Gamma must be in the range (0 < Gamma < 180).';
            end
            
            if (alpha + beta + gamma) > 360.0
                error = 1.0;
                errorMessage = 'The total angle (Alpha + Beta + Gamma) must not exceed 360 degrees.';
            end
            
            if error == 1.0
                return
            end
            
            %% Check the definition of E and v
            if getappdata(0, 'rosette_pMenu_outputType') == 2.0
                E = str2double(get(handles.edit_E, 'string'));
                
                if isempty(get(handles.edit_alpha, 'string')) == 1.0
                    error = 1.0;
                    errorMessage = 'Please specify a value of the Young''s Modulus.';
                elseif (isnumeric(E) == 0.0) || (isinf(E) == 1.0) || (isnan(E) == 1.0)
                    error = 1.0;
                    errorMessage = 'An invalid Young''s Modulus value was specified.';
                elseif E <= 0.0
                    error = 1.0;
                    errorMessage = 'The Young''s Modulus must be greater than zero.';
                end
                
                if error == 1.0
                    return
                end
                
                v = str2double(get(handles.edit_poisson, 'string'));
                
                if isempty(get(handles.edit_poisson, 'string')) == 1.0
                    error = 1.0;
                    errorMessage = 'Please specify a value of the Poisson''s ratio.';
                elseif (isnumeric(v) == 0.0) || (isinf(v) == 1.0) || (isnan(v) == 1.0)
                    error = 1.0;
                    errorMessage = 'An invalid Poisson''s ratio value was specified.';
                elseif v > 0.5
                    error = 1.0;
                    errorMessage = 'The Poisson''s ratio must not be greater than 0.5.';
                end
                
                if error == 1.0
                    return
                end
            end
            
            %% Verify the output definition
            if get(handles.check_outputLocation, 'value') == 1.0
                outputLocation = get(handles.edit_outputLocation, 'string');
                
                if isempty(outputLocation) == 1.0
                    error = 1.0;
                    errorMessage = 'Please select an output directory for gauge results.';
                    return
                elseif exist(outputLocation, 'dir') ~= 7.0
                    error = 1.0;
                    flag = exist(outputLocation, 'dir');
                    
                    switch flag
                        case 0.0
                            if exist(outputLocation, 'file') == 2.0
                                errorMessage = 'The output directory appears to be a file.';
                            else
                                errorMessage = 'The output directory could not be found.';
                            end
                        otherwise
                            errorMessage = 'The specified output directory is invalid.';
                    end
                    
                    return
                end
            else
                outputLocation = [pwd, '\Project\output\rosette_analysis_results'];
            end
            
            %% Verify the dimensions of the gauge data
            % Gauge A
            [r, c] = size(gaugeDataA);
            
            if r > c
                gaugeDataA = gaugeDataA';
            end
            
            if r > 1.0 && c > 1.0
                error = 1.0;
                errorMessage = 'The data for Gauge A has invalid dimensions. Data must be 1xN or Nx1.';
                return
            end
            
            % Gauge B
            [r, c] = size(gaugeDataB);
            
            if r > c
                gaugeDataB = gaugeDataB';
            end
            
            if r > 1.0 && c > 1.0
                error = 1.0;
                errorMessage = 'The data for Gauge B has invalid dimensions. Data must be 1xN or Nx1.';
                return
            end
            
            % Gauge C
            [r, c] = size(gaugeDataC);
            
            if r > c
                gaugeDataC = gaugeDataC';
            end
            
            if r > 1.0 && c > 1.0
                error = 1.0;
                errorMessage = 'The data for Gauge C has invalid dimensions. Data must be 1xN or Nx1.';
                return
            end
            
            %% Make sure the signals are the same length
            lengths = [length(gaugeDataA), length(gaugeDataB) length(gaugeDataC)];
            if length(unique(lengths)) ~= 1.0
                longest = max(lengths);
                
                % Gauge A
                if length(gaugeDataA) ~= longest
                    diff = longest - length(gaugeDataA);
                    gaugeDataA = [gaugeDataA, zeros(1.0, diff)];
                end
                
                % Gauge B
                if length(gaugeDataB) ~= longest
                    diff = longest - length(gaugeDataB);
                    gaugeDataB = [gaugeDataB, zeros(1.0, diff)];
                end
                
                % Gauge C
                if length(gaugeDataC) ~= longest
                    diff = longest - length(gaugeDataC);
                    gaugeDataC = [gaugeDataC, zeros(1.0, diff)];
                end
            end
        end
        
        %% Calcualte strain from gauge data
        function [E1, E2, E12M, thetaP, thetaS, E11, E22, E12, S1, S2, S12M, S11, S22, S12, error, errorMessage] = processGauges(gaugeA, gaugeB, gaugeC, alpha, beta, gamma, E, v, referenceStrain, referenceOrientation)
            %% Initialize output variables
            E1 = -1.0;
            E2 = -1.0;
            E12M = -1.0;
            
            E11 = -1.0;
            E22 = -1.0;
            E12 = -1.0;
            
            S1 = -1.0;
            S2 = -1.0;
            S12M = -1.0;
            
            S11 = -1.0;
            S22 = -1.0;
            S12 = -1.0;
            
            thetaP = -1.0;
            thetaS = -1.0;
            
            error = -1.0;
            errorMessage = -1.0;
            
            %% Search for special cases
            if alpha == 0.0 && beta == 45.0 && gamma == 45.0 % Rectangular
                % Reference strains
                E11 = gaugeA;
                E22 = gaugeC;
                E12 = (2.0.*gaugeB) - gaugeA - gaugeC;
                
                % Principal strains
                E1 = (0.5.*(E11 + E22)) + ((1.0./sqrt(2.0)).*sqrt((E11 - gaugeB).^2 + (gaugeB - E22).^2));
                E2 = (0.5.*(E11 + E22)) - ((1.0/sqrt(2.0)).*sqrt((E11 - gaugeB).^2 + (gaugeB - E22).^2));
            elseif (alpha == 30.0 && beta == 60.0 && gamma == 60.0) && (referenceStrain == 0.0 && referenceOrientation == 0.0) % Delta
                % Principal strains
                E1 = (1.0/3.0).*(gaugeA + gaugeB + gaugeC) + (sqrt(2.0)./3.0).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2 + (gaugeC - gaugeA).^2);
                E2 = (1.0/3.0)*(gaugeA + gaugeB + gaugeC) - (sqrt(2.0)/3.0).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2 + (gaugeC - gaugeA).^2);
            else
                syms Exx Eyy Exy
                
                % Make rosette angles relative to reference x-axis
                theta1 = alpha;
                theta2 = (alpha + beta);
                theta3 = beta + gamma;
                
                % Reference strain
                eqn1 = 0.5*(Exx + Eyy) + 0.5*(Exx - Eyy)*cosd(2.0*theta1) + (0.5*Exy)*sind(2.0*theta1) == 0.0;
                eqn2 = 0.5*(Exx + Eyy) + 0.5*(Exx - Eyy)*cosd(2.0*theta2) + (0.5*Exy)*sind(2.0*theta2) == 0.0;
                eqn3 = 0.5*(Exx + Eyy) + 0.5*(Exx - Eyy)*cosd(2.0*theta3) + (0.5*Exy)*sind(2.0*theta3) == 0.0;
                
                A = equationsToMatrix([eqn1, eqn2, eqn3], [Exx ,Eyy, Exy]);
                B = [gaugeA; gaugeB; gaugeC];
                
                X = linsolve(A, B);
                
                E11 = double(X(1.0, :));
                E22 = double(X(2.0, :));
                E12 = double(X(3.0, :));
                
                % Check validity of solution
                if (any(isinf(E11)) == 1.0 || any(isnan(E11)) == 1.0) || (any(isinf(E22)) == 1.0 || any(isnan(E22)) == 1.0) || (any(isinf(E12)) == 1.0 || any(isnan(E12)) == 1.0)
                    error = 1.0;
                    errorMessage = 'A solution could not be found for the specified strain gauge orientation.';
                    return
                end
                
                % Principal strains
                E1 = 0.5.*(E11 + E22) + sqrt((0.5.*(E11 - E22)).^2 + (0.5.*E12).^2);
                E2 = 0.5.*(E11 + E22) - sqrt((0.5.*(E11 - E22)).^2 + (0.5.*E12).^2);
            end
            
            %% Get principal stresses if requested:
            if getappdata(0, 'rosette_pMenu_outputType') == 2.0
                S1 = 1e-6.*((E./(1.0 - v^2)).*(E1 + v.*E2));
                S2 = 1e-6*((E./(1.0 - v^2)).*(E2 + v.*E1));
                
                % Maximum shear stress
                S12M = 0.5.*(S1 - S2);
                
                if referenceStrain == 1.0
                    % Calculate the reference stress as well
                    S11 = 1e-6.*((E./(1.0 - v^2)).*(E11 + v.*E22));
                    S22 = 1e-6.*((E./(1.0 - v^2)).*(E22 + v.*E11));
                    S12 = 1e-6.*((E12*E)/(2.0*(1.0 + v)));
                end
            end
            
            %% Get maximum shear strain
            % Maximum shear strain
            E12M = 0.5.*(E1 - E2);
            
            if referenceOrientation == 1.0
                % Principal strain orientation
                thetaP = 0.5.*atand(E12./(E11 - E22));
                thetaP(isnan(thetaP)) = 0.0;
    
                % Maximum shear strain orientation
                thetaS = -0.5.*atand((E11 - E22)./E12);
                thetaS(isnan(thetaS)) = 0.0;
            end
        end
        
        %% Write results data to file
        function [error, errorMessage] = writeData(E1, E2, E12M, thetaP, thetaS, E11, E22, E12, S1, S2, S12M, S11, S22, S12, referenceStrain, referenceOrientation, outputLocation)
            error = 0.0;
            errorMessage = -1.0;
            
            c = clock;
            dateString = datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6)));
            for i = 1:length(dateString)
                if (strcmpi(dateString(i), ':') == 1.0) || (strcmpi(dateString(i), ' ') == 1.0)
                    dateString(i) = '_';
                end
            end
            
            % If the output directory does not exist, create it
            if exist(outputLocation, 'dir') ~= 7.0
                try
                    mkdir(outputLocation)
                catch exception
                    error = 1.0;
                    errorMessage = sprintf('An exception occurred while creating the gauge results directory.\r\n\r\n%s', exception.message);
                    return
                end
            end
            
            fid = fopen([outputLocation, '\', dateString, '.dat'], 'w+');
            
            % Check for valid FID
            if fid == -1.0
                error = 1.0;
                errorMessage = sprintf('Results cannot be written to the selected location.\r\n\r\n%s', outputLocation);
                return
            end
            
            if referenceStrain == 1.0
                if referenceOrientation == 1.0
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M; thetaP; thetaS; E11; E22; E12]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPhi D (degrees)\tPhi S (degrees)\tE11R\tE22R\tE12R\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; E11; E22; E12; S1; S2; S12M; S11; S22; S12; thetaP; thetaS]';
                        
                        fprintf(fid, 'Strain units: uE\r\nStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tE11R\tE22R\tE12R\tPS1\tPS2\tS12 Max\tS11R\tS22R\tS12R\tPhi D (degrees)\tPhi S (degrees)\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n', tableB');
                    end
                else
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M; E11; E22; E12]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tE11R\tE22R\tE12R\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; E11; E22; E12; S1; S2; S12M; S11; S22; S12]';
                        
                        fprintf(fid, 'Strain units: uE\tStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tE11R\tE22R\tE12R\tPS1\tPS2\tS12 Max\tS11R\tS22R\tS12R\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n', tableB');
                    end
                end
            else
                if referenceOrientation == 1.0
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M; thetaP; thetaS]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPhi D (degrees)\tPhi S (degrees)\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; S1; S2; S12M; thetaP; thetaS]';
                        
                        fprintf(fid, 'Strain units: uE\r\nStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPS1\tPS2\tS12 Max\tPhi D (degrees)\tPhi S (degrees)\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n', tableB');
                    end
                else
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\r\n');
                        fprintf(fid, '%f\t%f\t%f\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; S1; S2; S12M]';
                        
                        fprintf(fid, 'Strain units: uE\r\nStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPS1\tPS2\tS12 Max\r\n');
                        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\r\n', tableB');
                    end
                end
            end
            
            fclose(fid);
        end
    end
end