classdef importMaterial < handle
%IMPORTMATERIAL    QFT class for material import processing.
%   This class contains methods for material import processing tasks.
%   
%   IMPORTMATERIAL is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also checkDataPath, evaluateMaterial, kValueCalculator,
%   LocalMaterialDatabase, material, MaterialEditor, MaterialManager.
%   
%   Quick Fatigue Tool 6.11-09 Copyright Louis Vallance 2017
%   Last modified 14-Dec-2017 10:22:23 GMT
    
    %%
    
    methods(Static = true)
        %% INITIALIZE DEFAULT KEYWORDS
        function [material_properties, kwStr, kwStrSp, algStr, mscStr, behStr, regStr, fatStr, nssStr, classStr, compositeStr] = initialize()
            % DEFAULT MATERIAL STRUCTURE
            material_properties = struct(...
                'default_algorithm', 6.0,...
                'default_msc', 1.0,...
                'class', 1.0,...
                'behavior', 1.0,...
                'reg_model', 1.0,...
                'cael', 2e+07,...
                'cael_active', 0.0,...
                'ndCompression', 0.0,...
                'e', [],...
                'e_active', 0.0,...
                'uts', [],...
                'ucs', [],...
                'uts_active', 0.0,...
                'proof', [],...
                'proof_active', 0.0,...
                'poisson', 0.33,...
                'poisson_active', 0.0,...
                's_values', [],...
                'n_values', [],...
                'r_values', [],...
                'sf', [],...
                'sf_active', 0.0,...
                'b', [],...
                'b_active', 0.0,...
                'b2', [],...
                'b2Nf', [],...
                'ef', [],...
                'ef_active', 0.0,...
                'c', [],...
                'c_active', 0.0,...
                'kp', [],...
                'kp_active', 0.0,...
                'np', [],...
                'np_active', 0.0,...
                'nssc', 0.2857,...
                'nssc_active', 0.0,...
                'comment', [],...
                'failStress_tsfd', [],...
                'failStress_csfd', [],...
                'failStress_tstd', [],...
                'failStress_cstd', [],...
                'failStress_tsttd', [],...
                'failStress_csttd', [],...
                'failStress_shear', [],...
                'failStress_cross12', 0.0,...
                'failStress_cross23', 0.0,...
                'failStress_limit12', [],...
                'failStress_limit23', [],...
                'failStrain_tsfd', [],...
                'failStrain_csfd', [],...
                'failStrain_tstd', [],...
                'failStrain_cstd', [],...
                'failStrain_shear', [],...
                'failStrain_e11', [],...
                'failStrain_e22', [],...
                'failStrain_g12', [],...
                'hashin_alpha', 0.0,...
                'hashin_lts', [],...
                'hashin_lcs', [],...
                'hashin_tts', [],...
                'hashin_tcs', [],...
                'hashin_lss', [],...
                'hashin_tss', [],...
                'larc05_lts', [],...
                'larc05_lcs', [],...
                'larc05_tts', [],...
                'larc05_tcs', [],...
                'larc05_lss', [],...
                'larc05_tss', [],...
                'larc05_shear', [],...
                'larc05_nl', [],...
                'larc05_nt', [],...
                'larc05_alpha0', 53.0,...
                'larc05_phi0', [],...
                'larc05_iterate', 0.0);
            
            % KEYWORD STRINGS
            kwStr = {'USERMATERIAL', 'DESCRIPTION', 'DEFAULTALGORITHM',...
                'DEFAULTMSC', 'CAEL', 'BEHAVIOR', 'REGRESSION', 'MECHANICAL',...
                'FATIGUE', 'CYCLIC', 'NORMALSTRESSSENSITIVITY', 'CLASS',...
                'COMPOSITE', 'KNEE', 'NOCOMPRESSION', 'ENDMATERIAL'};
            
            kwStrSp = {'USER MATERIAL', 'DESCRIPTION', 'DEFAULT ALGORITHM',...
                'DEFAULT MSC', 'CAEL', 'BEHAVIOR', 'REGRESSION', 'MECHANICAL',...
                'FATIGUE', 'CYCLIC', 'NORMAL STRESS SENSITIVITY', 'CLASS',...
                'COMPOSITE', 'KNEE', 'NO COMPRESSION', 'END MATERIAL'};
            
            % ALGORITHM STRINGS
            algStr = {'UNIAXIALSTRESS', 'UNIAXIALSTRAIN', 'SBBM', 'NORMAL', 'FINDLEY', 'INVARIANT', 'NASALIFE'};
            
            % MSC STRINGS
            mscStr = {'MORROW', 'GOODMAN', 'SODERBERG', 'WALKER', 'SWT', 'GERBER', 'RATIO', 'NONE'};
            
            % BEHAVIOR STRINGS
            behStr = {'STEEL', 'ALUMINIUM', 'OTHER'};
            
            % REGRESSION STRINGS
            regStr = {'UNIFORM', 'UNIVERSAL', 'MODIFIED', '9050', 'NONE'};
            
            % FATIGUE STRINGS
            fatStr = {'CONSTANTS', 'TESTDATA'};
            
            % NSSC STRINGS
            nssStr = {'USER', 'SOCIE', 'GENERAL', 'DANGVAN', 'SINES', 'CROSSLAND'};
            
            % CLASS STRINGS
            classStr = {'WROUGHTSTEEL', 'DUCTILEIRON', 'MALLEABLEIRON', 'WROUGHTIRON', 'CASTIRON', 'ALUMINIUM', 'OTHER'};
            
            % COMPOSITE FAILURE STRINGS
            compositeStr = {'STRESS', 'STRAIN', 'HASHIN', 'LARC05'};
        end
        
        %% PROCESS THE MATERIAL FILE
        function [error, material_properties, materialName, nTLINE_material, nTLINE_total] = processFile(materialFile, nTLINE_total)
            % Initialize the error flag
            %{
                1: Could not open file
                2: No material data
            %}
            error = 0.0;
            
            % Initialize the material properties
            [material_properties, kwStr, kwStrSp, algStr, mscStr, behStr, regStr, fatStr, nssStr, classStr, compositeStr] = importMaterial.initialize();
            
            % Initialize the material name
            materialName = 'Material-1 (empty)';
            
            % Initialize the keyword warnings
            keywordWarnings = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,...
                0.0, 0.0, 0.0, 0.0];
            
            % Counter for number of lines read for the material
            nTLINE_material = 1.0;
            
            % Open the material file
            fid = fopen(materialFile, 'r+');
            
            % If the file could not be opened, RETURN
            if fid == -1.0
                error = 1.0;
                % Print the import summary
                if isappdata(0, 'materialManagerImport') == 1.0
                    importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                    rmappdata(0, 'materialManagerImport')
                end
                return
            end
            
            % Check for *END MATERIAL definition
            text = fileread(materialFile);
            text(ismember(text,' ')) = [];
            text = lower(text);
            flag = strfind(text, '*endmaterial');
            
            if isempty(flag) == 1.0
                error = 3.0;
                % Print the import summary
                if isappdata(0, 'materialManagerImport') == 1.0
                    importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                    rmappdata(0, 'materialManagerImport')
                end
                return
            end
            
            %{
                If the material is being read from a job file and this is
                not the first definition, advance the file by nTLINE so
                that the next definition can be read
            %}
            if nTLINE_total ~= -1.0
                for i = 1:nTLINE_total
                    % Get the next line in the file
                    TLINE = lower(fgetl(fid));
                end
            end
            
            %% Search for material definition keyword
            foundMaterial = 0.0;
            
            while feof(fid) == 0.0
                % Get the next line in the file
                TLINE = lower(fgetl(fid));  nTLINE_total = nTLINE_total + 1.0;
                
                TLINEi = TLINE;
                TLINEi(ismember(TLINEi,' *')) = [];
                
                % Isolate the keyword
                TLINEi = strtok(lower(TLINEi), ',');
                
                % Check if the keyword matches the library
                matchingKw = find(strncmpi({TLINEi}, kwStr, length(TLINEi)) == 1.0);
                
                % If the current line is emtpy, skip to the next line
                if matchingKw == 1.0
                    % A material definition has been found
                    foundMaterial = 1.0;
                    break
                elseif strfind(TLINEi, '*endmaterial') == 1.0
                    break
                end
            end
            
            %% Process *USER MATERIAL
            if foundMaterial == 0.0;
                %{
                    A material definition keyword could not be found in the
                    file. RETURN and warn the user
                %}
                error = 2.0;
                % Print the import summary
                if isappdata(0, 'materialManagerImport') == 1.0
                    importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                    rmappdata(0, 'materialManagerImport')
                end
                return
            end
            
            % Check if the *USER MATERIAL keyword contains the NAME parameter
            [~, TOKEN] = strtok(TLINE, ',');
            TOKEN = lower(TOKEN);
            
            if isempty(TOKEN) == 1.0
                %{
                    A material definition keyword could not be found in the
                    file. RETURN and warn the user
                %}
                error = 2.0;
                if isappdata(0, 'materialManagerImport') == 1.0
                    importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                    rmappdata(0, 'materialManagerImport')
                end
                return
            end
            
            TOKEN(1.0) = [];
            materialName = strtrim(TOKEN);
            
            % Get the next line in the file
            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
            
            % User material end flag
            endOfMaterial = 0.0;
            
            %% Process next keyword
            while (feof(fid) == 0.0) && (endOfMaterial == 0.0)
                % If the current line is emtpy, skip to the next line
                if isempty(TLINE) == 1.0
                    % Get the next line in the file
                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                    
                    continue
                end
                
                % Check if the current line is a comment
                if (length(TLINE) > 1.0) && (strcmp(TLINE(1.0:2.0), '**') == 1.0)
                    % Get the next line in the file
                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                    
                    continue
                % Check that the current line is a keyword
                elseif strcmp(TLINE(1.0), '*') == 1.0
                    % The current line is a keyword definition
                    
                    % Isolate the keyword
                    TOKEN = strtok(TLINE, ',');
                    
                    % Get the length of the token
                    tokenLength = length(TOKEN);
                    
                    % Get the remainder of the keyword definition
                    parameter = TLINE((tokenLength + 1.0):end);
                    
                    % Remove spaces and asterisk from the keyword
                    TOKEN(ismember(TOKEN,' , *')) = [];
                    
                    % Check if the keyword matches the library
                    matchingKw = find(strncmpi({TOKEN}, kwStr, length(TOKEN)) == 1.0);
                    
                    if length(matchingKw) > 1.0
                        % Get the next line in the file
                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        
                        % The keyword definition is ambiguous
                        continue
                    elseif isempty(matchingKw) == 1.0
                        % Get the next line in the file
                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        
                        % The keyword could not be found in the library
                        continue
                    end
                    
                    % Process the appropriate keyword
                    switch matchingKw
                        case 2.0 % *DESCRIPTION
                            %{
                                The material description is defined as all
                                of the text under the keyword until the
                                next keyword is encountered
                            %}
                            % Initialize the description
                            material_description = '';
                            
                            % Set the end criterion
                            continueKeyword = 1.0;
                            
                            while continueKeyword == 1.0
                                % Get the next line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                % Check for end condition
                                if isempty(TLINE) == 0.0 && strcmpi(TLINE(1.0), '*') == 1.0
                                    % End of description
                                    break
                                else
                                    material_description = [material_description, TLINE]; %#ok<AGROW>
                                end
                            end
                            
                            % Add the property to the material
                            material_properties.comment = material_description;
                        case 3.0 % *DEFAULT ALGORITHM
                            %{
                                The default algorithm is defined by a
                                single parameter after the keyword
                                declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, algStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                material_properties.default_algorithm = 6.0;
                                keywordWarnings(3.0) = 1.0;
                            else
                                switch matchingParameter
                                    case 1.0 % Uniaxial Stress-Life
                                        material_properties.default_algorithm = 14.0;
                                    case 2.0 % Uniaxial Strain-Life
                                        material_properties.default_algorithm = 13.0;
                                    case 3.0 % SBBM
                                        material_properties.default_algorithm = 6.0;
                                    case 4.0 % Normal
                                        material_properties.default_algorithm = 7.0;
                                    case 5.0 % Findley
                                        material_properties.default_algorithm = 8.0;
                                    case 6.0 % Invariant
                                        material_properties.default_algorithm = 9.0;
                                    case 7.0 % NASALIFE
                                        material_properties.default_algorithm = 10.0;
                                end
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 4.0 % *DEFAULT MSC
                            %{
                                The default mean stress correction is
                                defined by a single parameter after the
                                keyword declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, mscStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                material_properties.default_msc = 2.0;
                                keywordWarnings(4.0) = 1.0;
                            else
                                switch matchingParameter
                                    case 1.0 % Morrow
                                        material_properties.default_msc = 1.0;
                                    case 2.0 % Goodman
                                        material_properties.default_msc = 2.0;
                                    case 3.0 % Soderberg
                                        material_properties.default_msc = 3.0;
                                    case 4.0 % Walker
                                        material_properties.default_msc = 4.0;
                                    case 5.0 % SWT
                                        material_properties.default_msc = 5.0;
                                    case 6.0 % Gerber
                                        material_properties.default_msc = 6.0;
                                    case 7.0 % Ratio
                                        material_properties.default_msc = 7.0;
                                    case 8.0 % None
                                        material_properties.default_msc = 8.0;
                                    otherwise
                                end
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 5.0 % *CAEL
                            %{
                                The constant amplitude endurance limit is
                                defined as up to two numeric values
                                directly below the keyword declaration
                            %}
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                            
                            % If the next line is a keyword definition, continue
                            if (isempty(TLINE) == 0.0) && (strcmp(TLINE, '*') == 1.0)
                                keywordWarnings(5.0) = 1.0;
                                continue
                            end
                            
                            % Get the numeric value of the data line
                            cael = str2num(TLINE); %#ok<ST2NM>
                            
                            if isempty(cael) == 1.0
                                % Get the next line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(5.0) = 1.0;
                                continue
                            end
                            
                            % Process the data line
                            if length(cael) >= 2.0
                                cael = cael(1.0:2.0);
                                
                                material_properties.cael = cael(1.0);
                                material_properties.cael_active = cael(2.0);
                            else
                                material_properties.cael = cael(1.0);
                                material_properties.cael_active = 1.0;
                            end
                            
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 6.0 % *BEHAVIOR
                            %{
                                The material behavior is defined by a
                                single parameter after the keyword
                                declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, behStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                material_properties.behavior = 1.0;
                                keywordWarnings(6.0) = 1.0;
                            else
                                switch matchingParameter
                                    case 1.0 % Steel
                                        material_properties.behavior = 1.0;
                                    case 2.0 % Aluminium
                                        material_properties.behavior = 2.0;
                                    case 3.0 % Other
                                        material_properties.behavior = 3.0;
                                end
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 7.0 % *REGRESSION
                            %{
                                The regression method is defined by a
                                single parameter after the keyword
                                declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, regStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                material_properties.reg_model = 1.0;
                                keywordWarnings(6.0) = 1.0;
                            else
                                switch matchingParameter
                                    case 1.0 % Uniform
                                        material_properties.reg_model = 1.0;
                                    case 2.0 % Universal
                                        material_properties.reg_model = 2.0;
                                    case 3.0 % Modified
                                        material_properties.reg_model = 3.0;
                                    case 4.0 % 90/50
                                        material_properties.reg_model = 4.0;
                                    case 5.0 % None
                                        material_properties.reg_model = 5.0;
                                end
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 8.0 % *MECHANICAL
                            %{
                                Mechanical properties are defined by up to
                                four numeric values per data line, and up
                                to two datalines, directly below the
                                keyword declaration
                            %}
                            for dataLine = 1:2
                                % Get the data line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                % Initialize the data line flags
                                flags = [];
                                
                                % If the next line is a keyword definition, continue
                                if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                    if dataLine == 1.0
                                        keywordWarnings(7.0) = 1.0;
                                    end
                                    break
                                elseif isempty(TLINE) == 1.0
                                    if dataLine == 1.0
                                        keywordWarnings(7.0) = 1.0;
                                    end
                                    break
                                end
                                
                                %{
                                    There can be empty entries where a
                                    property is left undefined. Parse the
                                    line and identify empty definitions
                                %}
                                TLINE(ismember(TLINE,' ')) = [];
                                
                                index = 1.0;
                                while 1.0 == 1.0
                                    if index == length(TLINE)
                                        break
                                    elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                        TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                        index = index + 6.0;
                                    elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                        % This value is undefined
                                        TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                        index = index + 7.0;
                                    else
                                        index = index + 1.0;
                                    end
                                end
                                
                                if dataLine == 1.0
                                    % Get the numeric value of the data line
                                    properties = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nProperties = length(properties);
                                    if nProperties > 5.0
                                        properties = properties(1.0:5.0);
                                    elseif nProperties < 5.0
                                        properties(nProperties + 1.0:5.0) = -9e100;
                                    end
                                    
                                    % E
                                    if properties(1.0) ~= -9e100
                                        material_properties.e = properties(1.0);
                                    end
                                    
                                    % v
                                    if properties(2.0) ~= -9e100
                                        material_properties.poisson = properties(2.0);
                                    end
                                    
                                    % UTS
                                    if properties(3.0) ~= -9e100
                                        material_properties.uts = properties(3.0);
                                    end
                                    
                                    % UCS
                                    if properties(4.0) ~= -9e100
                                        material_properties.ucs = properties(4.0);
                                    end
                                    
                                    % Proof
                                    if properties(5.0) ~= -9e100
                                        material_properties.proof = properties(5.0);
                                    end
                                else
                                    % Get the numeric value of the data line
                                    flags = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nFlags = length(flags);
                                    if nFlags > 4.0
                                        flags = flags(1.0:4.0);
                                    elseif nFlags < 4.0
                                        flags(nFlags + 1.0:4.0) = -9e100;
                                    end
                                    
                                    % E
                                    if (flags(1.0) ~= 0.0) && (isempty(material_properties.e) == 0.0)
                                        material_properties.e_active = 1.0;
                                    end
                                    
                                    % v
                                    if (flags(2.0) ~= 0.0) && (isempty(material_properties.poisson) == 0.0)
                                        material_properties.poisson_active = 1.0;
                                    end
                                    
                                    % UTS
                                    if (flags(3.0) ~= 0.0) && (isempty(material_properties.uts) == 0.0)
                                        material_properties.uts_active = 1.0;
                                    end
                                    
                                    % Proof
                                    if (flags(4.0) ~= 0.0) && (isempty(material_properties.proof) == 0.0)
                                        material_properties.proof_active = 1.0;
                                    end
                                    
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                end
                            end
                            
                            if isempty(flags) == 1.0
                                if isempty(material_properties.e) == 0.0
                                    material_properties.e_active = 1.0;
                                end
                                
                                if isempty(material_properties.poisson) == 0.0
                                    material_properties.poisson_active = 1.0;
                                end
                                
                                if isempty(material_properties.uts) == 0.0 || isempty(material_properties.ucs) == 0.0
                                    material_properties.uts_active = 1.0;
                                end
                                
                                if isempty(material_properties.proof) == 0.0
                                    material_properties.proof_active = 1.0;
                                end
                            end
                        case 9.0 % *FATIGUE
                            %{
                                Fatigue constants are defined by up to
                                four numeric values per data line, and up
                                to two datalines, directly below the
                                keyword declaration
                            
                                Fatigue test data is defined by up to three
                                numeric values per data line, and as many
                                data lines that are necessary to define the
                                S-N curve
                            %}
                            
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, fatStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                % Get the next line in the file
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(8.0) = 1.0;
                                continue
                            else
                                switch matchingParameter
                                    case 1.0 % Constants
                                        for dataLine = 1:2
                                            % Get the data line
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                            
                                            % Initialize the data line flags
                                            flags = [];
                                            
                                            % If the next line is a keyword definition, continue
                                            if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                                if dataLine == 1.0
                                                    keywordWarnings(8.0) = 1.0;
                                                end
                                                break
                                            elseif isempty(TLINE) == 1.0
                                                if dataLine == 1.0
                                                    keywordWarnings(8.0) = 1.0;
                                                end
                                                break
                                            end
                                            
                                            %{
                                                There can be empty entries
                                                where a property is left
                                                undefined. Parse the line
                                                and identify empty
                                                definitions
                                            %}
                                            TLINE(ismember(TLINE,' ')) = [];
                                            
                                            index = 1.0;
                                            while 1.0 == 1.0
                                                if index == length(TLINE)
                                                    break
                                                elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                                    TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                                    index = index + 6.0;
                                                elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                                    % This value is undefined
                                                    TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                                    index = index + 7.0;
                                                else
                                                    index = index + 1.0;
                                                end
                                            end
                                            
                                            if dataLine == 1.0
                                                % Get the numeric value of the data line
                                                properties = str2num(TLINE); %#ok<ST2NM>
                                                
                                                % Process the data line
                                                nProperties = length(properties);
                                                if nProperties > 4.0
                                                    properties = properties(1.0:4.0);
                                                elseif nProperties < 4.0
                                                    properties(nProperties + 1.0:4.0) = -9e100;
                                                end
                                                
                                                % Sf'
                                                if properties(1.0) ~= -9e100
                                                    material_properties.sf = properties(1.0);
                                                end
                                                
                                                % b
                                                if properties(2.0) ~= -9e100
                                                    material_properties.b = properties(2.0);
                                                end
                                                
                                                % Ef'
                                                if properties(3.0) ~= -9e100
                                                    material_properties.ef = properties(3.0);
                                                end
                                                
                                                % c
                                                if properties(4.0) ~= -9e100
                                                    material_properties.c = properties(4.0);
                                                end
                                            else
                                                % Get the numeric value of the data line
                                                flags = str2num(TLINE); %#ok<ST2NM>
                                                
                                                % Process the data line
                                                nFlags = length(flags);
                                                if nFlags > 4.0
                                                    flags = flags(1.0:4.0);
                                                elseif nFlags < 4.0
                                                    flags(nFlags + 1.0:4.0) = -9e100;
                                                end
                                                
                                                % Sf'
                                                if (flags(1.0) ~= 0.0) && (isempty(material_properties.sf) == 0.0)
                                                    material_properties.sf_active = 1.0;
                                                end
                                                
                                                % b
                                                if (flags(2.0) ~= 0.0) && (isempty(material_properties.b) == 0.0)
                                                    material_properties.b_active = 1.0;
                                                end
                                                
                                                % Ef'
                                                if (flags(3.0) ~= 0.0) && (isempty(material_properties.ef) == 0.0)
                                                    material_properties.ef_active = 1.0;
                                                end
                                                
                                                % c
                                                if (flags(4.0) ~= 0.0) && (isempty(material_properties.c) == 0.0)
                                                    material_properties.c_active = 1.0;
                                                end
                                                
                                                % Get the next line in the file
                                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                            end
                                        end
                                        
                                        if isempty(flags) == 1.0
                                            if isempty(material_properties.sf) == 0.0
                                                material_properties.sf_active = 1.0;
                                            end
                                            
                                            if isempty(material_properties.b) == 0.0
                                                material_properties.b_active = 1.0;
                                            end
                                            
                                            if isempty(material_properties.ef) == 0.0
                                                material_properties.ef_active = 1.0;
                                            end
                                            
                                            if isempty(material_properties.c) == 0.0
                                                material_properties.c_active = 1.0;
                                            end
                                        end
                                    case 2.0 % Test data
                                        % Initialize the test data buffers
                                        n_values = [];
                                        s_values = [];
                                        
                                        dataLine = 0.0;
                                        
                                        while 1.0 == 1.0
                                            % Increment the data line number
                                            dataLine = dataLine + 1.0;
                                            
                                            % Get the data line
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                            
                                            % If the next line is a keyword definition, continue
                                            if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                                if dataLine == 1.0
                                                    keywordWarnings(8.0) = 1.0;
                                                end
                                                break
                                            elseif isempty(TLINE) == 1.0
                                                if dataLine == 1.0
                                                    keywordWarnings(8.0) = 1.0;
                                                end
                                                break
                                            end
                                            
                                            % Get the numeric value of the data line
                                            properties = str2num(TLINE); %#ok<ST2NM>
                                            
                                            % Get the number of S-values
                                            nSValues = length(properties) - 1.0;
                                            
                                            % Process the data line
                                            nProperties = length(properties);
                                            if nProperties < 2.0
                                                % Get the next line in the file
                                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                                
                                                keywordWarnings(8.0) = 1.0;
                                                break
                                            elseif (dataLine > 1.0) && (nSValues ~= nSValuesP)
                                                % Get the next line in the file
                                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                                
                                                keywordWarnings(8.0) = 1.0;
                                                break
                                            end
                                            
                                            n_values(dataLine) = properties(1.0); %#ok<AGROW>
                                            s_values(dataLine, :) = properties(2.0:end); %#ok<AGROW>
                                            
                                            nSValuesP = nSValues;
                                        end
                                        
                                        % Check if there is any S-N data
                                        if isempty(n_values) == 0.0
                                            % Make sure there are at least two rows
                                            if length(n_values) < 2.0
                                                keywordWarnings(8.0) = 1.0;
                                                continue
                                            end
                                            
                                            % Make sure the N-values are increasing
                                            if any(diff(n_values) < 0.0) == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                                continue
                                            end
                                            
                                            % Make sure the S-values are decreasing
                                            for i = 1:nSValues
                                                if any(diff(s_values(1.0, :)) > 0.0) == 1.0
                                                    keywordWarnings(8.0) = 1.0;
                                                    break
                                                end
                                            end
                                            
                                            material_properties.n_values = n_values;
                                            material_properties.s_values = s_values';
                                        end
                                        
                                        %{
                                            If the user specified more than
                                            one S-N curve, the next keyword
                                            must be *R RATIOS
                                        %}
                                        if nSValues > 1.0
                                            if isempty(TLINE) == 1.0
                                                while 1.0 == 1.0
                                                    % Get the next line in the file
                                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                                    
                                                    if isempty(TLINE) == 0.0
                                                        keywordWarnings(8.0) = 1.0;
                                                        break
                                                    end
                                                end
                                            end
                                            % Isolate the keyword
                                            TOKEN = strtok(TLINE, ',');
                                            TOKEN(ismember(TOKEN,' , *')) = [];
                                            
                                            if strcmpi(TOKEN, 'RRATIOS') == 0.0
                                                keywordWarnings(8.0) = 1.0;
                                                continue
                                            end
                                            
                                            % Get the next line in the file
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                            
                                            % Get the numeric value of the data line
                                            r_values = str2num(TLINE); %#ok<ST2NM>
                                            
                                            if isempty(r_values) == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                                continue
                                            end
                                            
                                            if (all(diff(r_values) > 0.0) == 0.0) || (any(r_values >= 1.0) == 1.0) || (length(r_values) ~= nSValues)
                                                keywordWarnings(8.0) = 1.0;
                                                continue
                                            end
                                            
                                            material_properties.r_values = r_values;
                                            
                                            % Get the next line in the file
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        else
                                            %{
                                                There is only one set of
                                                S-N data. Assign an R-value
                                                of -1 to this data
                                            %}
                                            material_properties.r_values = -1.0;
                                        end
                                end
                            end
                        case 10.0 % *CYCLIC
                            for dataLine = 1:2
                                % Get the data line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                % Initialize the data line flags
                                flags = [];
                                
                                % If the next line is a keyword definition, continue
                                if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                    if dataLine == 1.0
                                        keywordWarnings(9.0) = 1.0;
                                    end
                                    break
                                elseif isempty(TLINE) == 1.0
                                    if dataLine == 1.0
                                        keywordWarnings(9.0) = 1.0;
                                    end
                                    keywordWarnings(9.0) = 1.0;
                                    break
                                end
                                
                                %{
                                    There can be empty entries where a
                                    property is left undefined. Parse the
                                    line and identify empty definitions
                                %}
                                TLINE(ismember(TLINE,' ')) = [];
                                
                                index = 1.0;
                                while 1.0 == 1.0
                                    if index == length(TLINE)
                                        break
                                    elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                        TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                        index = index + 6.0;
                                    elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                        % This value is undefined
                                        TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                        index = index + 7.0;
                                    else
                                        index = index + 1.0;
                                    end
                                end
                                
                                if dataLine == 1.0
                                    % Get the numeric value of the data line
                                    properties = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nProperties = length(properties);
                                    if nProperties > 2.0
                                        properties = properties(1.0:2.0);
                                    elseif nProperties < 2.0
                                        properties(nProperties + 1.0:2.0) = -9e100;
                                    end
                                    
                                    % K'
                                    if properties(1.0) ~= -9e100
                                        material_properties.kp = properties(1.0);
                                    end
                                    
                                    % n'
                                    if properties(2.0) ~= -9e100
                                        material_properties.np = properties(2.0);
                                    end
                                else
                                    % Get the numeric value of the data line
                                    flags = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nFlags = length(flags);
                                    if nFlags > 2.0
                                        flags = flags(1.0:2.0);
                                    elseif nFlags < 2.0
                                        flags(nFlags + 1.0:2.0) = -9e100;
                                    end
                                    
                                    % K'
                                    if (flags(1.0) ~= 0.0) && (isempty(material_properties.kp) == 0.0)
                                        material_properties.kp_active = 1.0;
                                    end
                                    
                                    % n'
                                    if (flags(2.0) ~= 0.0) && (isempty(material_properties.np) == 0.0)
                                        material_properties.np_active = 1.0;
                                    end
                                    
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                end
                            end
                            
                            if isempty(flags) == 1.0
                                if isempty(material_properties.kp) == 0.0
                                    material_properties.kp_active = 1.0;
                                end
                                
                                if isempty(material_properties.np) == 0.0
                                    material_properties.np_active = 1.0;
                                end
                            end
                        case 11.0 % *NORMAL STRESS SENSITIVITY
                            %{
                                The normal stress sensitivity is defined by
                                a single parameter after the keyword
                                declaration, followed by upto one data line
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, nssStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(10.0) = 1.0;
                                continue
                            else
                                switch matchingParameter
                                    case 1.0 % User
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        if isempty(TLINE) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get the numeric value of the data line
                                        solk = str2num(TLINE); %#ok<ST2NM>
                                        
                                        if isempty(solk) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        elseif length(solk) > 1.0
                                            solk = solk(1.0);
                                        end
                                    case 2.0 % Socie
                                        solk = 0.2857;
                                    case 3.0 % General
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        % Check if SYMS works
                                        try
                                            %syms x
                                            gfsfdgerg
                                        catch
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        if isempty(TLINE) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get the numeric value of the data line
                                        nssc = str2num(TLINE); %#ok<ST2NM>
                                        
                                        if isempty(nssc) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        elseif length(nssc) > 3.0
                                            nssc = nssc(1.0:3.0);
                                        elseif length(nssc) < 3.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get user input
                                        r = nssc(1.0);
                                        fi = nssc(2.0);
                                        t = nssc(3.0);
                                        
                                        % Calculate k based on user input
                                        syms k
                                        eqn = (fi/t) == (2.0*sqrt(1.0 + k^2))/(sqrt(((2.0*k)/(1.0 - r))^2.0 + 1.0) + ((2.0*k)/(1.0- r)));
                                        solk = eval(solve(eqn, k)); clc
                                    case 4.0 % Dang Van
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        if isempty(TLINE) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get the numeric value of the data line
                                        nssc = str2num(TLINE); %#ok<ST2NM>
                                        
                                        if isempty(nssc) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        elseif length(nssc) > 2.0
                                            nssc = nssc(1.0:2.0);
                                        elseif length(nssc) < 2.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get user input
                                        fi = nssc(1.0);
                                        t = nssc(2.0);
                                        
                                        % Calculate k based on user input
                                        solk = ((3.0*t)/(fi)) - (3.0/2.0);
                                    case 5.0 % Sines
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        if isempty(TLINE) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get the numeric value of the data line
                                        nssc = str2num(TLINE); %#ok<ST2NM>
                                        
                                        if isempty(nssc) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        elseif length(nssc) > 3.0
                                            nssc = nssc(1.0:3.0);
                                        elseif length(nssc) < 3.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get user input
                                        fi = nssc(1.0);
                                        t = nssc(2.0);
                                        uts = nssc(3.0);
                                        
                                        % Calculate k based on user input
                                        solk = ((3.0*t*(uts + fi))/(uts*fi)) - sqrt(6.0);
                                    case 6.0 % Crossland
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        if isempty(TLINE) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get the numeric value of the data line
                                        nssc = str2num(TLINE); %#ok<ST2NM>
                                        
                                        if isempty(nssc) == 1.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        elseif length(nssc) > 2.0
                                            nssc = nssc(1.0:2.0);
                                        elseif length(nssc) < 2.0
                                            keywordWarnings(10.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get user input
                                        fi = nssc(1.0);
                                        t = nssc(2.0);
                                        
                                        % Calculate k based on user input
                                        solk = ((3.0*t)/(fi)) - sqrt(3.0);
                                end
                            end
                            
                            if isempty(solk) == 1.0
                                keywordWarnings(10.0) = 2.0;
                                continue
                            elseif isreal(solk) == 0.0
                                keywordWarnings(10.0) = 3.0;
                                continue
                            elseif isnan(solk) == 1.0
                                keywordWarnings(10.0) = 4.0;
                                continue
                            elseif isinf(solk) == 1.0
                                keywordWarnings(10.0) = 5.0;
                                continue
                            elseif solk < 0.0
                                keywordWarnings(10.0) = 6.0;
                                continue
                            else
                                material_properties.nssc = solk;
                                material_properties.nssc_active = 1.0;
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 12.0 % *CLASS
                            %{
                                The material class is defined by a single
                                parameter after the keyword declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, classStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                material_properties.class = 1.0;
                                keywordWarnings(11.0) = 1.0;
                            else
                                switch matchingParameter
                                    case 1.0 % Wrought steel
                                        material_properties.class = 1.0;
                                    case 2.0 % Ductile iron
                                        material_properties.class = 2.0;
                                    case 3.0 % Malleable iron
                                        material_properties.class = 3.0;
                                    case 4.0 % Wrought iron
                                        material_properties.class = 4.0;
                                    case 5.0 % Cast iron
                                        material_properties.class = 5.0;
                                    case 6.0 % Aluminium
                                        material_properties.class = 6.0;
                                    case 7.0 % Other
                                        material_properties.class = 7.0;
                                end
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 13.0 % *COMPOSITE
                            %{
                                The composite properties are defined by a
                                single parameter after the keyword
                                declaration, followed by upto one data line
                            %}
                            
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            % Check if the parameter matches the library
                            matchingParameter = find(strncmpi({parameter}, compositeStr, length(parameter)) == 1.0);
                            
                            %{
                                If there is not matching parameter, use the
                                default value
                            %}
                            if (isempty(matchingParameter) == 1.0) || (length(matchingParameter) ~= 1.0)
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(12.0) = 1.0;
                                continue
                            else
                                switch matchingParameter
                                    case 1.0 % Stress
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        TLINE(ismember(TLINE,' ')) = [];
                                        
                                        index = 1.0;
                                        while 1.0 == 1.0
                                            if index == length(TLINE)
                                                break
                                            elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                                TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                                index = index + 6.0;
                                            elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                                % This value is undefined
                                                TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                                index = index + 7.0;
                                            else
                                                index = index + 1.0;
                                            end
                                        end
                                        
                                        % Get the numeric value of the data line
                                        properties = str2num(TLINE); %#ok<ST2NM>
                                        
                                        % Process the data line
                                        nProperties = length(properties);
                                        if nProperties > 11.0
                                            properties = properties(1.0:11.0);
                                        elseif nProperties < 11.0
                                            properties(nProperties + 1.0:11.0) = -9e100;
                                        end
                                        
                                        % Tensile stress (11-direction)
                                        if properties(1.0) ~= -9e100
                                            material_properties.failStress_tsfd = properties(1.0);
                                        end
                                        
                                        % Compressive stress (11-direction)
                                        if properties(2.0) ~= -9e100
                                            material_properties.failStress_csfd = properties(2.0);
                                        end
                                        
                                        % Tensile stress (22-direction)
                                        if properties(3.0) ~= -9e100
                                            material_properties.failStress_tstd = properties(3.0);
                                        end
                                        
                                        % Compressive stress (22-direction)
                                        if properties(4.0) ~= -9e100
                                            material_properties.failStress_cstd = properties(4.0);
                                        end
                                        
                                        % Tensile stress (33-direction)
                                        if properties(5.0) ~= -9e100
                                            material_properties.failStress_tsttd = properties(5.0);
                                        end
                                        
                                        % Compressive stress (33-direction)
                                        if properties(6.0) ~= -9e100
                                            material_properties.failStress_csttd = properties(6.0);
                                        end
                                        
                                        % Shear strength (12-direction)
                                        if properties(7.0) ~= -9e100
                                            material_properties.failStress_shear = properties(7.0);
                                        end
                                        
                                        % Cross product coefficient (12-direction)
                                        if properties(8.0) ~= -9e100
                                            material_properties.failStress_cross12 = properties(8.0);
                                        end
                                        
                                        % Cross product coefficient (23-direction)
                                        if properties(9.0) ~= -9e100
                                            material_properties.failStress_cross23 = properties(9.0);
                                        end
                                        
                                        % Limit stress (12-direction)
                                        if properties(10.0) ~= -9e100
                                            material_properties.failStress_limit12 = properties(10.0);
                                        end
                                        
                                        % Limit stress (23-direction)
                                        if properties(11.0) ~= -9e100
                                            material_properties.failStress_limit23 = properties(11.0);
                                        end
                                    case 2.0 % Strain
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        TLINE(ismember(TLINE,' ')) = [];
                                        
                                        index = 1.0;
                                        while 1.0 == 1.0
                                            if index == length(TLINE)
                                                break
                                            elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                                TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                                index = index + 6.0;
                                            elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                                % This value is undefined
                                                TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                                index = index + 7.0;
                                            else
                                                index = index + 1.0;
                                            end
                                        end
                                        
                                        % Get the numeric value of the data line
                                        properties = str2num(TLINE); %#ok<ST2NM>
                                        
                                        % Process the data line
                                        nProperties = length(properties);
                                        if nProperties > 8.0
                                            properties = properties(1.0:8.0);
                                        elseif nProperties < 8.0
                                            properties(nProperties + 1.0:8.0) = -9e100;
                                        end
                                        
                                        % Tensile strain (fiber direction)
                                        if properties(1.0) ~= -9e100
                                            material_properties.failStrain_tsfd = properties(1.0);
                                        end
                                        
                                        % Compressive strain (fiber direction)
                                        if properties(2.0) ~= -9e100
                                            material_properties.failStrain_csfd = properties(2.0);
                                        end
                                        
                                        % Tensile strain (transverse direction)
                                        if properties(3.0) ~= -9e100
                                            material_properties.failStrain_tstd = properties(3.0);
                                        end
                                        
                                        % Compressive strain (transverse direction)
                                        if properties(4.0) ~= -9e100
                                            material_properties.failStrain_cstd = properties(4.0);
                                        end
                                        
                                        % Shear strain
                                        if properties(5.0) ~= -9e100
                                            material_properties.failStrain_shear = properties(5.0);
                                        end
                                        
                                        % Elastic modulus (fiber direction)
                                        if properties(6.0) ~= -9e100
                                            material_properties.failStrain_e11 = properties(5.0);
                                        end
                                        
                                        % Elastic modulus (transverse direction)
                                        if properties(7.0) ~= -9e100
                                            material_properties.failStrain_e22 = properties(5.0);
                                        end
                                        
                                        % Section Poisson's ratio
                                        if properties(8.0) ~= -9e100
                                            material_properties.failStrain_g12 = properties(5.0);
                                        end
                                    case 3.0 % Hashin
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        TLINE(ismember(TLINE,' ')) = [];
                                        
                                        index = 1.0;
                                        while 1.0 == 1.0
                                            if index == length(TLINE)
                                                break
                                            elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                                TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                                index = index + 6.0;
                                            elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                                % This value is undefined
                                                TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                                index = index + 7.0;
                                            else
                                                index = index + 1.0;
                                            end
                                        end
                                        
                                        % Get the numeric value of the data line
                                        properties = str2num(TLINE); %#ok<ST2NM>
                                        
                                        % Process the data line
                                        nProperties = length(properties);
                                        if nProperties > 7.0
                                            properties = properties(1.0:7.0);
                                        elseif nProperties < 7.0
                                            properties(nProperties + 1.0:7.0) = -9e100;
                                        end
                                        
                                        % Alpha
                                        if properties(1.0) ~= -9e100
                                            material_properties.hashin_alpha = properties(1.0);
                                        end
                                        
                                        % Longitudinal tensile strength
                                        if properties(2.0) ~= -9e100
                                            material_properties.hashin_lts = properties(2.0);
                                        end
                                        
                                        % Longitudinal compressive strength
                                        if properties(3.0) ~= -9e100
                                            material_properties.hashin_lcs = properties(3.0);
                                        end
                                        
                                        % Transverse tensile strength
                                        if properties(4.0) ~= -9e100
                                            material_properties.hashin_tts = properties(4.0);
                                        end
                                        
                                        % Transverse compressive strength
                                        if properties(5.0) ~= -9e100
                                            material_properties.hashin_tcs = properties(5.0);
                                        end
                                        
                                        % Longitudinal shear strength
                                        if properties(6.0) ~= -9e100
                                            material_properties.hashin_lss = properties(6.0);
                                        end
                                        
                                        % Transverse shear strength
                                        if properties(7.0) ~= -9e100
                                            material_properties.hashin_tss = properties(7.0);
                                        end
                                    case 4.0 % LaRC05
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        TLINE(ismember(TLINE,' ')) = [];
                                        
                                        index = 1.0;
                                        while 1.0 == 1.0
                                            if index == length(TLINE)
                                                break
                                            elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                                TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                                index = index + 6.0;
                                            elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                                % This value is undefined
                                                TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                                index = index + 7.0;
                                            else
                                                index = index + 1.0;
                                            end
                                        end
                                        
                                        % Get the numeric value of the data line
                                        properties = str2num(TLINE); %#ok<ST2NM>
                                        
                                        % Process the data line
                                        nProperties = length(properties);
                                        if nProperties > 12.0
                                            properties = properties(1.0:12.0);
                                        elseif nProperties < 12.0
                                            properties(nProperties + 1.0:12.0) = -9e100;
                                        end
                                        
                                        % Longitudinal tensile strength
                                        if properties(1.0) ~= -9e100
                                            material_properties.larc05_lts = properties(1.0);
                                        end
                                        
                                        % Longitudinal compressive strength
                                        if properties(2.0) ~= -9e100
                                            material_properties.larc05_lcs = properties(2.0);
                                        end
                                        
                                        % Transverse tensile strength
                                        if properties(3.0) ~= -9e100
                                            material_properties.larc05_tts = properties(3.0);
                                        end
                                        
                                        % Transverse compressive strength
                                        if properties(4.0) ~= -9e100
                                            material_properties.larc05_tcs = properties(4.0);
                                        end
                                        
                                        % Longitudinal shear strength
                                        if properties(5.0) ~= -9e100
                                            material_properties.larc05_lss = properties(5.0);
                                        end
                                        
                                        % Transverse shear strength
                                        if properties(6.0) ~= -9e100
                                            material_properties.larc05_tss = properties(6.0);
                                        end
                                        
                                        % Shear modulus
                                        if properties(7.0) ~= -9e100
                                            material_properties.larc05_shear = properties(7.0);
                                        end
                                        
                                        % Longitudinal slope coefficient
                                        if properties(8.0) ~= -9e100
                                            material_properties.larc05_nl = properties(8.0);
                                        end
                                        
                                        % Transverse slope coefficient
                                        if properties(9.0) ~= -9e100
                                            material_properties.larc05_nt = properties(9.0);
                                        end
                                        
                                        % Fracture plane angle for pure compression
                                        if properties(10.0) ~= -9e100
                                            material_properties.larc05_alpha0 = properties(10.0);
                                        end
                                        
                                        % Initial fier misalignment angle
                                        if properties(11.0) ~= -9e100
                                            material_properties.larc05_phi0 = properties(11.0);
                                        end
                                        
                                        % Allow iterative solution for initial fibre misalignment angle
                                        if properties(12.0) ~= -9e100
                                            material_properties.larc05_iterate = properties(12.0);
                                        end
                                end
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 14.0 % *KNEE
                            %{
                                The S-N knee is defined as up to two
                                numeric values directly below the keyword
                                declaration
                            %}
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                            
                            % If the next line is a keyword definition, continue
                            if (isempty(TLINE) == 0.0) && (strcmp(TLINE, '*') == 1.0)
                                keywordWarnings(13.0) = 1.0;
                                continue
                            end
                            
                            % Get the numeric value of the data line
                            knee = str2num(TLINE); %#ok<ST2NM>
                            
                            if isempty(knee) == 1.0
                                % Get the next line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(13.0) = 1.0;
                                continue
                            end
                            
                            % Process the data line
                            if length(knee) >= 2.0
                                knee = knee(1.0:2.0);
                                
                                material_properties.b2 = knee(1.0);
                                material_properties.b2Nf = knee(2.0);
                            else
                                % Get the next line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(13.0) = 1.0;
                                continue
                            end
                            
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 15.0 % *NO COMPRESSION
                            %{
                                This keyword is declared without a
                                parameter or datalines
                            %}
                            material_properties.ndCompression = 1.0;
                            
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 16.0 % *END MATERIAL
                            %{
                                The user has manually declared the end of
                                the material definition. Stop processing
                                further material definitions
                            %}
                            endOfMaterial = 1.0;
                    end
                else
                    % Get the next line in the file
                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                end
            end
            
            % Print the import summary
            if isappdata(0, 'materialManagerImport') == 1.0
                importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                rmappdata(0, 'materialManagerImport')
            end
            
            % Close the material file
            fclose(fid);
        end
        
        %% PRINT WARNINGS TO THE COMMAND WINDOW
        function [] = printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
            [~, n, e] = fileparts(materialFile);
            materialFile = [n, e];
            clc
            
            % Check for errors
            switch error
                case 0.0
                    fprintf('The material ''%s'' has been imported from the file ''%s''\n', materialName, materialFile)
                case 1.0
                    fprintf('ERROR: The material file ''%s'' could not be opened\n', materialFile)
                case 2.0
                    fprintf('ERROR: The material file ''%s'' contains no valid material definitions\n', materialFile)
                case 3.0
                    fprintf('ERROR: The material file ''%s'' is missing *END MATERIAL. This must be included at the end of the file\n', materialFile)
            end
            
            %{
                Print warning in case the normal stress sensitivty constant
                could not be evaluated
            %}
            if keywordWarnings(10.0) > 1.0
                switch keywordWarnings(10.0)
                    case 2.0
                        fprintf('\nWARNING: In *NORMAL STRESS SENSITIVITY, the k-parameter could not be evaluated\n')
                    case 3.0
                        fprintf('\nWARNING: In *NORMAL STRESS SENSITIVITY, the calculated k-parameter is complex\n')
                    case 4.0
                        fprintf('\nWARNING: In *NORMAL STRESS SENSITIVITY, the calculated k-parameter is NaN\n')
                    case 5.0
                        fprintf('\nWARNING: In *NORMAL STRESS SENSITIVITY, the calculated k-parameter is INF\n')
                    case 6.0
                        fprintf('\nWARNING: In *NORMAL STRESS SENSITIVITY, the calculated k-parameter is negative\n')
                    otherwise
                end
            end
            
            % Summarise processed keywords
            if any(keywordWarnings == 1.0) == 1.0
                fprintf('\nWARNING: The following keywords/parameters were not processed correctly by the material file reader:\n')
                fprintf('-------------------------------------------------------------------------------------------------\n')
                
                keywords = keywordWarnings == 1.0;
                keywords = kwStrSp(keywords);
                
                fprintf('*%s\n', keywords{:})
                fprintf('Check the material file for possible syntax errors. Material data may only be partially saved\n')
                fprintf('Default values will be used, which may cause undesirable behaviour\n')
            end
        end
    end
end