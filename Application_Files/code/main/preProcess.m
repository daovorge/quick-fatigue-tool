classdef preProcess < handle
%PREPROCESS    QFT class for pre-analysis processing.
%   This class contains methods for pre-analysis processing tasks.
%
%   PREPROCESS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also postProcess.
%
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 28-Mar-2018 09:40:26 GMT
    
    %%
    
    methods(Static = true)
        %% Get material properties from .mat file
        function [error, material] = getMaterial(material, useSN, groups)
            error = 0.0;
            
            % Save the name of the material of the current group
            setappdata(0, 'getMaterial_currentMaterial', material)
            
            %% Check if the material is specified with its .mat extension
            [PATHSTR, ~, EXT] = fileparts(material);
            if isempty(EXT) == 1.0
                material = [material, '.mat'];
            end
            
            %% Open the .mat file for reading:
            if exist(material, 'file') == 0.0
                %{
                    The material file does not exist on the matlab path.
                    RETURN and issue an error
                %}
                setappdata(0, 'material', material)
                error = 1.0;
                return
            elseif isempty(PATHSTR) == 0.0
                %{
                   The material was specified with a path, so search this
                   location only
                %}
                if exist(material, 'file') ~= 2.0
                    setappdata(0, 'material', material)
                    error = 1.0;
                    return
                end
            else
                %{
                    The material was specified without a path. Check if the
                    local material database has been set
                %}
                localPath = getappdata(0, 'qft_localMaterialDataPath');
                
                if (isempty(localPath) == 1.0) && (exist('qft-local-material.txt', 'file') == 2.0)
                    %{
                        The local material path is not set, but there is a
                        marker text file, so try this location first
                    %}
                    [localPath, ~, ~] = fileparts(which('qft-local-material.txt'));
                    
                    if exist([localPath, '\', material], 'file') == 2.0
                        %{
                            The material exists on the path containing the
                            marker file. Use this file
                        %}
                        material = [localPath, '\', material];
                    end
                elseif isempty(localPath) == 1.0
                    %{
                        The local material path is not set and there is no
                        marker file. Try using the default local path
                        DATA\MATERIAL\LOCAL instead
                    %}
                    if exist([pwd, '/Data/material/local/', material], 'file') == 2.0 
                        %{
                            The material exists on the default local path.
                            Use this file
                        %}
                        material = [pwd, '/Data/material/local/', material];
                    end
                else
                    %{
                        The local path is set. Check if the material exists
                        in this location.
                    %}
                    if exist([localPath, '\', material], 'file') == 2.0
                        %{
                            The material exists on the user-defined local
                            material path. Use this file
                        %}
                        material = [localPath, '\', material];
                    end
                end
            end
            
            try load(material)
            catch unhandledException
                setappdata(0, 'error_log_003_exceptionMessage', unhandledException.identifier)
                error = 2.0;
                return
            end
            
            %% Fetch material properties
            %{
                Status
                -1: Undefined
                0: User-defined
                1: Derived
                2: Default
            %}
            
            %% Force material to pass validation if composite analysis
            if getappdata(0, 'compositeCriteria') == 1.0
                material_properties.reg_model = 5.0;
                material_properties.e = 203e3;  material_properties.e_active = 1.0;
                material_properties.uts = 400.0;  material_properties.uts_active = 1.0;
                material_properties.ucs = 400.0;
                material_properties.proof = 325.0;  material_properties.proof_active = 1.0;
                material_properties.sf = 930.0;  material_properties.sf_active = 1.0;
                material_properties.b = -0.095;  material_properties.b_active = 1.0;
                material_properties.ef = 0.26;  material_properties.ef_active = 1.0;
                material_properties.c = -0.47;  material_properties.c_active = 1.0;
                material_properties.kp = 1190.0;  material_properties.kp_active = 1.0;
                material_properties.np = 0.193;  material_properties.np_active = 1.0;
            end
            
            %% Material description
            setappdata(0, 'materialDescription', material_properties.comment)
            
            %% Default analysis algorithm
            defaultAlgorithm = material_properties.default_algorithm;
            if defaultAlgorithm < 5.0
                defaultAlgorithm = defaultAlgorithm - 1.0;
            elseif defaultAlgorithm < 12.0
                defaultAlgorithm = defaultAlgorithm - 2.0;
            else
                defaultAlgorithm = defaultAlgorithm - 3.0;
            end
            setappdata(0, 'defaultAlgorithm', defaultAlgorithm)
            
            %% Default mean stress correction
            setappdata(0, 'defaultMSC', material_properties.default_msc)
            
            %% Material class
            class = material_properties.class;
            switch class
                case 1.0
                    setappdata(0, 'fsc', 0.75)
                case 2.0
                    setappdata(0, 'fsc', 0.90)
                case 3.0
                    setappdata(0, 'fsc', 1.00)
                case 4.0
                    setappdata(0, 'fsc', 0.83)
                case 5.0
                    setappdata(0, 'fsc', 1.30)
                case 6.0
                    setappdata(0, 'fsc', 0.65)
                case 7.0
                    setappdata(0, 'fsc', -1.0)
            end
            
            %% Constant amplitude endurance limit
            if material_properties.cael_active == 1.0
                if ischar(material_properties.cael) == 1.0
                    cael = str2double(material_properties.cael);
                else
                    cael = material_properties.cael;
                end
                
                if isnumeric(cael) == 0.0
                    error = 3.0;
                    return
                elseif isempty(cael) == 1.0 || isnan(cael) == 1.0 || isinf(cael) == 1.0
                    error = 3.0;
                    return
                elseif cael <= 0.0
                    error = 3.0;
                    return
                elseif isreal(cael) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'cael', cael)
                    setappdata(0, 'cael_status', 0.0)
                end
            else
                setappdata(0, 'cael', 2e7)
                setappdata(0, 'cael_status', 2.0)
            end
            
            %% No damage in compression
            try
                if ischar(material_properties.ndCompression) == 1.0
                    ndCompression = str2double(material_properties.failStress_shear);
                else
                    ndCompression = material_properties.ndCompression;
                end
            catch
                ndCompression = 0.0;
            end
            setappdata(0, 'ndCompression', ndCompression)
            
            %% Modulus of elasticity
            if material_properties.e_active == 1.0
                if ischar(material_properties.e)
                    E = str2double(material_properties.e);
                else
                    E = material_properties.e;
                end
                
                if isnumeric(E) == 0.0
                    error = 3.0;
                elseif isempty(E) == 1.0 || isnan(E) == 1.0 || isinf(E) == 1.0
                    error = 3.0;
                    return
                elseif E <= 0.0
                    error = 3.0;
                    return
                elseif isreal(E) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'E', E)
                    setappdata(0, 'E_status', 0.0)
                end
            else
                E = [];
                setappdata(0, 'E', [])
                setappdata(0, 'E_status', -1.0)
            end
            
            
            %% Ultimate tensile strength
            if material_properties.uts_active == 1.0
                if ischar(material_properties.uts)
                    uts = str2double(material_properties.uts);
                else
                    uts = material_properties.uts;
                end
                
                if isnumeric(uts) == 0.0
                    error = 3.0;
                    return
                elseif isempty(uts) == 1.0 || isnan(uts) == 1.0 || isinf(uts) == 1.0
                    error = 3.0;
                    return
                elseif uts <= 0.0
                    error = 3.0;
                    return
                elseif isreal(uts) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'uts', uts)
                    setappdata(0, 'uts_status', 0.0)
                end
            else
                uts = [];
                setappdata(0, 'uts', [])
                setappdata(0, 'uts_status', -1.0)
            end
            
            %% Ultimate compressive strength
            if material_properties.uts_active == 1.0
                try
                    if ischar(material_properties.ucs)
                        ucs = str2double(material_properties.ucs);
                    else
                        ucs = material_properties.ucs;
                    end
                catch
                    ucs = uts;
                end
                
                if isnumeric(ucs) == 0.0
                    error = 3.0;
                    return
                elseif isempty(ucs) == 1.0 || isnan(ucs) == 1.0 || isinf(ucs) == 1.0
                    setappdata(0, 'ucs', uts)
                    setappdata(0, 'ucs_status', 2.0)
                elseif ucs <= 0.0
                    error = 3.0;
                    return
                elseif isreal(ucs) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'ucs', ucs)
                    setappdata(0, 'ucs_status', 0.0)
                end
            else
                setappdata(0, 'ucs', [])
                setappdata(0, 'ucs_status', -1.0)
            end
            
            %% Poisson's ratio
            if material_properties.poisson_active == 1.0
                if ischar(material_properties.poisson)
                    poisson = str2double(material_properties.poisson);
                else
                    poisson = material_properties.poisson;
                end
                
                % Check validity of poisson's ratio
                if poisson <= -1.0 || poisson >= 0.5
                    poisson = 0.33;
                    messenger.writeMessage(45.0)
                end
                
                if isnumeric(poisson) == 0.0
                    setappdata(0, 'poisson', [])
                    error = 3.0;
                    return
                elseif isempty(poisson) == 1.0 || isnan(poisson) == 1.0 || isinf(poisson) == 1.0
                    setappdata(0, 'poisson', [])
                    error = 3.0;
                    return
                elseif isreal(poisson) == 0.0
                    setappdata(0, 'poisson', [])
                    error = 3.0;
                    return
                else
                    setappdata(0, 'poisson', poisson)
                    setappdata(0, 'poisson_status', 0.0)
                end
            else
                setappdata(0, 'poisson', 0.33)
                setappdata(0, 'poisson_status', 2.0)
            end
            
            %% S-N data
            if ischar(material_properties.s_values) == 1.0
                S = str2double(material_properties.s_values);
                
                indexes = find(S == 0.0);
                if isempty(indexes) == 0.0
                    for i = 1:length(indexes)
                        S(indexes(i)) = 0.1;
                    end
                end
            else
                S = material_properties.s_values;
                
                indexes = find(S == 0.0);
                if isempty(indexes) == 0.0
                    for i = 1:length(indexes)
                        S(indexes(i)) = 0.1;
                    end
                end
            end
            
            % Scale the S-N data
            if useSN == 1.0
                snScale = getappdata(0, 'snScale');
                snScale = snScale(getappdata(0, 'getMaterial_currentGroup'));
                
                if isempty(snScale)
                    snScale = 1.0;
                elseif isnumeric(snScale) == 0.0
                    snScale = 1.0;
                    messenger.writeMessage(38.0)
                elseif isempty(snScale) == 1.0 || isnan(snScale) == 1.0 || isinf(snScale) == 1.0
                    snScale = 1.0;
                    messenger.writeMessage(38.0)
                elseif snScale <= 0.0
                    snScale = 1.0;
                    messenger.writeMessage(38.0)
                end
                S = snScale*S;
            end
            
            setappdata(0, 's_values', S)
            
            if ischar(material_properties.n_values)
                N = str2double(material_properties.n_values);
                
                indexes = find(N == 0.0);
                if isempty(indexes) == 0.0
                    for i = 1:length(indexes)
                        N(indexes(i)) = 0.1;
                    end
                end
                
                setappdata(0, 'n_values', str2double(material_properties.n_values))
            else
                N = material_properties.n_values;
                
                indexes = find(N == 0.0);
                if isempty(indexes) == 0.0
                    for i = 1:length(indexes)
                        N(indexes(i)) = 0.1;
                    end
                end
                
                setappdata(0, 'n_values', material_properties.n_values)
            end
            
            if ischar(material_properties.r_values)
                setappdata(0, 'r_values', str2double(material_properties.r_values))
            else
                setappdata(0, 'r_values', material_properties.r_values)
            end
            
            setappdata(0, 'nSNDatasets', length(getappdata(0, 'r_values')))
            
            %% Set the current residual stress
            residualStress = getappdata(0, 'residualStress_original');
            if isempty(residualStress) == 1.0
                setappdata(0, 'residualStress', 0.0);
            else
                setappdata(0, 'residualStress', residualStress(getappdata(0, 'getMaterial_currentGroup')));
            end
            
            %% Normal stress sensitivity constant
            if ischar(material_properties.nssc)
                nssc = str2double(material_properties.nssc);
            else
                nssc = material_properties.nssc;
            end
            
            if isnumeric(nssc) == 0.0
                if material_properties.nssc_active == 1.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'k', 0.2857)
                    setappdata(0, 'k_status', 2.0)
                end
            elseif isempty(nssc) == 1.0
                if material_properties.nssc_active == 1.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'k', 0.2857)
                    setappdata(0, 'k_status', 2)
                end
            elseif isnan(nssc) == 1.0 || isinf(nssc) == 1.0
                if material_properties.nssc_active == 1.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'k', 0.2857)
                    setappdata(0, 'k_status', 2.0)
                    messenger.writeMessage(15.0)
                end
            elseif isreal(nssc) == 0.0
                if material_properties.nssc_active == 1.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'k', 0.2857)
                    setappdata(0, 'k_status', 2.0)
                end
            else
                setappdata(0, 'k', nssc)
                
                if material_properties.nssc_active == 0.0
                    setappdata(0, 'k_status', 1.0)
                else
                    setappdata(0, 'k_status', 0.0)
                end
            end
            
            %% Set the control of the material endurance limit
            %{
               This parameter only needs to be set once. The definition
               applies to all groups
            %}
            behavior = material_properties.behavior;
            
            if groups == 1.0
                if isempty(getappdata(0, 'ndEndurance')) == 0.0
                    switch getappdata(0, 'ndEndurance');
                        case 0.0
                            if behavior == 2.0
                                setappdata(0, 'ndEndurance', 0.0)
                            else
                                setappdata(0, 'ndEndurance', 1.0)
                            end
                        case 1.0
                            setappdata(0, 'ndEndurance', 0.0)
                        case 2.0
                            setappdata(0, 'ndEndurance', 1.0)
                        otherwise
                            setappdata(0, 'ndEndurance', 1.0)
                    end
                else
                    setappdata(0, 'ndEndurance', 0.0)
                end
            end
            
            %% Fatigue strength exponent
            setappdata(0, 'materialBehavior', behavior);
            reg_model = material_properties.reg_model;
            setappdata(0, 'regressionModel', reg_model);
            
            if material_properties.b_active == 1.0
                if ischar(material_properties.b) == 1.0
                    b = str2double(material_properties.b);
                else
                    b = material_properties.b;
                end
                
                if isnumeric(b) == 0.0
                    setappdata(0, 'b', [])
                    error = 3.0;
                    return
                elseif isempty(b) == 1.0 || isnan(b) == 1.0 || isinf(b) == 1.0
                    setappdata(0, 'b', [])
                    error = 3.0;
                    return
                elseif isreal(b) == 0.0
                    setappdata(0, 'b', [])
                    error = 3.0;
                    return
                else
                    setappdata(0, 'b', b)
                    setappdata(0, 'b_status', 0)
                end
            else
                setappdata(0, 'b_status', 1.0)
                switch reg_model
                    case 1.0
                        switch behavior
                            case 1.0
                                setappdata(0, 'b', -0.087)
                            case 2.0
                                setappdata(0, 'b', -0.095)
                        end
                    case 2.0
                        setappdata(0, 'b', -0.12)
                    case 3.0
                        setappdata(0, 'b', -0.09)
                    case 4.0
                        if material_properties.cael_active == 0.0
                            cael = getappdata(0, 'cael');
                        end
                        
                        if uts > 1000.0
                            setappdata(0, 'b', log10((0.9*uts)/(500))/log10(1e3/(0.5*cael)))
                        else
                            setappdata(0, 'b', log10(1.8)/log10(1e3/(0.5*cael)))
                        end
                    case 5.0
                        setappdata(0, 'b_status', -1.0)
                        setappdata(0, 'b', [])
                end
            end
            messenger.writeMessage(10.0)
            
            %% Fatigue strength exponent (beyond user-defined knee)
            if material_properties.b_active == 1.0
                try
                    if ischar(material_properties.b2) == 1.0
                        b2 = str2double(material_properties.b2);
                        b2Nf = str2double(material_properties.b2Nf);
                    else
                        b2 = material_properties.b2;
                        b2Nf = material_properties.b2Nf;
                    end
                catch
                    b2 = [];
                    b2Nf = [];
                end
                
                if isempty(b2) == 1.0
                    setappdata(0, 'b2', [])
                else
                    setappdata(0, 'b2', b2)
                end
                if isempty(b2Nf) == 1.0
                    setappdata(0, 'b2Nf', [])
                else
                    setappdata(0, 'b2Nf', b2Nf)
                end
            else
                setappdata(0, 'b2', [])
                setappdata(0, 'b2Nf', [])
            end
            
            %% Fatigue strength coefficient
            if material_properties.sf_active == 1.0
                % This property is checked active, so verify the user input
                if ischar(material_properties.sf) == 1.0
                    sf = str2double(material_properties.sf);
                else
                    sf = material_properties.sf;
                end
                
                if isnumeric(sf) == 0.0
                    setappdata(0, 'Sf', [])
                    error = 3.0;
                    return
                elseif isempty(sf) == 1.0 || isnan(sf) == 1.0 || isinf(sf) == 1.0
                    setappdata(0, 'Sf', [])
                    error = 3.0;
                    return
                elseif isreal(sf) == 0.0
                    setappdata(0, 'Sf', [])
                    error = 3.0;
                    return
                else
                    setappdata(0, 'Sf', sf)
                    setappdata(0, 'Sf_status', 0.0)
                end
            else
                % The property is unchecked, so try to derive the value
                switch reg_model
                    case 1.0 % Seeger
                        if isempty(uts) == 1.0
                            if ischar(material_properties.sf) == 1.0
                                sf = str2double(material_properties.sf);
                            else
                                sf = material_properties.sf;
                            end
                            
                            if isnumeric(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isempty(sf) == 1.0 || isnan(sf) == 1.0 || isinf(sf) == 1.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isreal(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            else
                                setappdata(0, 'Sf', sf)
                                setappdata(0, 'Sf_status', 0.0)
                            end
                        else
                            setappdata(0, 'Sf_status', 1.0)
                            switch behavior
                                case 1.0
                                    sf = 1.5*uts;
                                    setappdata(0, 'Sf', 1.5*uts)
                                case 2.0
                                    sf = 1.67*uts;
                                    setappdata(0, 'Sf', 1.67*uts)
                            end
                        end
                    case 2.0 % Universal Slopes
                        if isempty(uts) == 1.0 && useSN == 0.0
                            % There is insufficient material data to derive
                            % this property, so check if there is a user
                            % value
                            if ischar(material_properties.sf) == 1.0
                                sf = str2double(material_properties.sf);
                            else
                                sf = material_properties.sf;
                            end
                            
                            if isnumeric(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isempty(sf) == 1.0 || isnan(sf) == 1.0 || isinf(sf) == 1.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isreal(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            else
                                setappdata(0, 'Sf', sf)
                                setappdata(0, 'Sf_status', 0.0)
                            end
                        else
                            setappdata(0, 'Sf_status', 1.0)
                            sf = 1.9*uts;
                            setappdata(0, 'Sf', 1.9*uts)
                        end
                    case 3.0 % Modified Universal Slopes
                        if (isempty(uts) == 1.0 || isempty (E) == 1.0) && useSN == 0.0
                            % There is insufficient material data to derive
                            % this property, so check if there is a user
                            % value
                            if ischar(material_properties.sf) == 1.0
                                sf = str2double(material_properties.sf);
                            else
                                sf = material_properties.sf;
                            end
                            
                            if isnumeric(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isempty(sf) == 1.0 || isnan(sf) == 1.0 || isinf(sf) == 1.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isreal(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            else
                                setappdata(0, 'Sf', sf)
                                setappdata(0, 'Sf_status', 0.0)
                            end
                        else
                            setappdata(0, 'Sf_status', 1)
                            sf = 0.623*(uts^0.823)*E^0.168;
                            setappdata(0, 'Sf', 0.623*(uts^0.823)*E^0.168)
                        end
                    case 4.0 % 90/50 Rule
                        if isempty(uts) == 1.0 && useSN == 0.0
                            % There is insufficient material data to derive
                            % this property, so check if there is a user
                            % value
                            if ischar(material_properties.sf) == 1.0
                                sf = str2double(material_properties.sf);
                            else
                                sf = material_properties.sf;
                            end
                            
                            if isnumeric(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isempty(sf) == 1.0 || isnan(sf) == 1.0 || isinf(sf) == 1.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            elseif isreal(sf) == 0.0
                                setappdata(0, 'Sf', [])
                                error = 4.0;
                                setappdata(0, 'Sf_status', -1.0)
                                return
                            else
                                setappdata(0, 'Sf', sf)
                                setappdata(0, 'Sf_status', 0.0)
                            end
                        else
                            setappdata(0, 'Sf_status', 1.0)
                            if material_properties.b_active == 0.0
                                b = getappdata(0, 'b');
                            end
                            setappdata(0, 'Sf', (0.9*uts)/(2e3)^b);
                        end
                    case 5.0
                        setappdata(0, 'Sf_status', -1.0)
                        setappdata(0, 'Sf', [])
                end
            end
            
            % Check if Sf value is negative
            if getappdata(0, 'Sf') < 0.0
                if isempty(uts) == 0.0
                    sf = 0.9*uts;
                    setappdata(0, 'Sf', (0.9*uts)/((2e3)^(getappdata(0, 'b'))))
                    messenger.writeMessage(64.0)
                else
                    sf = 0.0;
                    setappdata(0, 'Sf', 0.0)
                    messenger.writeMessage(46.0)
                end
                setappdata(0, 'Sf_status', 1.0)
            else
                messenger.writeMessage(9.0)
            end
            
            %% Fatigue ductility coefficient
            if material_properties.ef_active == 1.0
                if ischar(material_properties.ef)
                    ef = str2double(material_properties.ef);
                else
                    ef = material_properties.ef;
                end
                
                if isnumeric(ef) == 0.0
                    setappdata(0, 'Ef', [])
                    error = 3.0;
                    return
                elseif isempty(ef) == 1.0 || isnan(ef) == 1.0 || isinf(ef) == 1.0
                    setappdata(0, 'Ef', [])
                    error = 3.0;
                    return
                elseif isreal(ef) == 0.0
                    setappdata(0, 'Ef', [])
                    error = 3.0;
                    return
                else
                    setappdata(0, 'Ef', ef)
                    setappdata(0, 'Ef_status', 0.0)
                end
            else
                switch reg_model
                    case 1.0
                        if isempty(uts) == 1.0 || isempty(E) == 1.0
                            if ischar(material_properties.ef)
                                ef = str2double(material_properties.ef);
                            else
                                ef = material_properties.ef;
                            end
                            
                            if isnumeric(ef) == 0.0
                                ef = [];
                                setappdata(0, 'Ef', [])
                                setappdata(0, 'Ef_status', -1.0)
                            elseif isempty(ef) == 1.0 || isnan(ef) == 1.0 || isinf(ef) == 1.0
                                ef = [];
                                setappdata(0, 'Ef', [])
                                setappdata(0, 'Ef_status', -1.0)
                            elseif isreal(ef) == 0.0
                                ef = [];
                                setappdata(0, 'Ef', [])
                                setappdata(0, 'Ef_status', -1.0)
                            else
                                setappdata(0, 'Ef', ef)
                                setappdata(0, 'Ef_status', 0.0)
                            end
                        else
                            setappdata(0, 'Ef_status', 1.0)
                            switch behavior
                                case 1.0
                                    if (uts/E) <= 3e-3
                                        a = 1.0;
                                    else
                                        a = (1.375 - 125*(uts/E));
                                    end
                                    
                                    ef = 0.59*a;
                                    setappdata(0, 'Ef', ef)
                                case 2.0
                                    ef = 0.35;
                                    setappdata(0, 'Ef', ef)
                            end
                        end
                    case 2.0
                        switch behavior
                            case 1.0
                                ef = 0.76*(log(1/(1 - 0.1541)))^0.6;
                                setappdata(0, 'Ef', ef)
                                setappdata(0, 'Ef_status', 1.0)
                            case 2.0
                                ef = 0.76*(log(1.0/(1.0 - 0.4394)))^0.6;
                                setappdata(0, 'Ef', ef)
                                setappdata(0, 'Ef_status', 1.0)
                            case 3.0
                                ef = 0.76*(log(1.0/(1.0 - 0.1541)))^0.6;
                                setappdata(0, 'Ef', ef)
                                setappdata(0, 'Ef_status', 1.0)
                        end
                    case 3.0
                        if isempty(uts) == 1.0 || isempty (E) == 1.0
                            if ischar(material_properties.ef)
                                ef = str2double(material_properties.ef);
                            else
                                ef = material_properties.ef;
                            end
                            
                            if isnumeric(ef) == 0.0
                                ef = [];
                                setappdata(0, 'Ef', [])
                                setappdata(0, 'Ef_status', -1.0)
                            elseif isempty(ef) == 1.0 || isnan(ef) == 1.0 || isinf(ef) == 1.0
                                ef = [];
                                setappdata(0, 'Ef', [])
                                setappdata(0, 'Ef_status', -1.0)
                            elseif isreal(ef) == 0.0
                                ef = [];
                                setappdata(0, 'Ef', [])
                                setappdata(0, 'Ef_status', -1.0)
                            else
                                setappdata(0, 'Ef', ef)
                                setappdata(0, 'Ef_status', 0.0)
                            end
                        else
                            setappdata(0, 'Ef_status', 1.0)
                            switch behavior
                                case 1.0
                                    ef = (0.0196*(log(1/(1 - 0.1541)))^0.155)*(uts/E)^-0.53;
                                    setappdata(0, 'Ef', ef)
                                case 2.0
                                    ef = (0.0196*(log(1/(1 - 0.4394)))^0.155)*(uts/E)^-0.53;
                                    setappdata(0, 'Ef', ef)
                                case 3.0
                                    ef = (0.0196*(log(1/(1 - 0.1541)))^0.155)*(uts/E)^-0.53;
                                    setappdata(0, 'Ef', ef)
                            end
                        end
                    case 4.0
                        if ischar(material_properties.ef)
                            ef = str2double(material_properties.ef);
                        else
                            ef = material_properties.ef;
                        end
                        
                        if isnumeric(ef) == 0.0
                            ef = [];
                            setappdata(0, 'Ef', [])
                            setappdata(0, 'Ef_status', -1.0)
                        elseif isempty(ef) == 1.0 || isnan(ef) == 1.0 || isinf(ef) == 1.0
                            ef = [];
                            setappdata(0, 'Ef', [])
                            setappdata(0, 'Ef_status', -1.0)
                        elseif isreal(ef) == 0.0
                            ef = [];
                            setappdata(0, 'Ef', [])
                            setappdata(0, 'Ef_status', -1.0)
                        else
                            setappdata(0, 'Ef', ef)
                            setappdata(0, 'Ef_status', 0.0)
                        end
                    case 5.0
                        setappdata(0, 'Ef_status', -1.0)
                        setappdata(0, 'Ef', [])
                end
            end
            
            % Check if Ef value is negative
            if getappdata(0, 'Ef') < 0.0
                ef = 0.0;
                setappdata(0, 'Ef', 0.0)
                setappdata(0, 'Ef_status', 1.0)
                messenger.writeMessage(47.0)
            else
                messenger.writeMessage(11.0)
            end
            
            %% Fatigue ductility exponent
            if material_properties.c_active == 1.0
                if ischar(material_properties.c)
                    c = str2double(material_properties.c);
                else
                    c = material_properties.c;
                end
                
                if isnumeric(c) == 0.0
                    setappdata(0, 'c', [])
                    error = 3.0;
                    return
                elseif isempty(c) == 1.0 || isnan(c) == 1.0 || isinf(c) == 1.0
                    setappdata(0, 'c', [])
                    error = 3.0;
                    return
                elseif isreal(c) == 0.0
                    setappdata(0, 'c', [])
                    error = 3.0;
                    return
                else
                    setappdata(0, 'c', c)
                    setappdata(0, 'c_status', 0.0)
                end
            else
                setappdata(0, 'c_status', 1.0)
                switch reg_model
                    case 1.0
                        switch behavior
                            case 1.0
                                setappdata(0, 'c', -0.58)
                            case 2.0
                                setappdata(0, 'c', -0.69)
                        end
                    case 2.0
                        setappdata(0, 'c', -0.6)
                    case 3.0
                        setappdata(0, 'c', -0.56)
                    case 4.0
                        if ischar(material_properties.c)
                            c = str2double(material_properties.c);
                        else
                            c = material_properties.c;
                        end
                        
                        if isnumeric(c) == 0.0
                            setappdata(0, 'c', [])
                        elseif isempty(ef) == 1.0 || isnan(c) == 1.0 || isinf(c) == 1.0
                            setappdata(0, 'c', [])
                        elseif isreal(c) == 0.0
                            setappdata(0, 'c', [])
                        else
                            setappdata(0, 'c', c)
                            setappdata(0, 'c_status', 0.0)
                        end
                    case 5.0
                        setappdata(0, 'c_status', -1.0)
                        setappdata(0, 'c', [])
                end
            end
            messenger.writeMessage(12.0)
            
            %% Cyclic stress hardening coefficient
            if material_properties.kp_active == 1.0
                if ischar(material_properties.kp)
                    kp = str2double(material_properties.kp);
                else
                    kp = material_properties.kp;
                end
                
                if isnumeric(kp) == 0.0
                    error = 3.0;
                    return
                elseif isempty(kp) == 1.0 || isnan(kp) == 1.0 || isinf(kp) == 1.0
                    error = 3.0;
                    return
                elseif isreal(kp) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'kp', kp)
                    setappdata(0, 'kp_status', 0.0)
                end
            else
                switch reg_model
                    case 1.0
                        if isempty(uts) == 1.0
                            if ischar(material_properties.kp)
                                kp = str2double(material_properties.kp);
                            else
                                kp = material_properties.kp;
                            end
                            
                            if isnumeric(kp) == 0.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            elseif isempty(kp) == 1.0 || isnan(kp) == 1.0 || isinf(kp) == 1.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            elseif isreal(kp) == 0.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            else
                                setappdata(0, 'kp', kp)
                                setappdata(0, 'kp_status', 0.0)
                            end
                        else
                            setappdata(0, 'kp_status', 1.0)
                            switch behavior
                                case 1.0
                                    kp = 1.65*uts;
                                    setappdata(0, 'kp', kp)
                                case 2.0
                                    kp = 1.61*uts;
                                    setappdata(0, 'kp', kp)
                            end
                        end
                    case 2.0
                        if isempty(ef) == 1.0
                            if ischar(material_properties.kp)
                                kp = str2double(material_properties.kp);
                            else
                                kp = material_properties.kp;
                            end
                            
                            if isnumeric(kp) == 0.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            elseif isempty(kp) == 1.0 || isnan(kp) == 1.0 || isinf(kp) == 1.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            elseif isreal(kp) == 0.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            else
                                setappdata(0, 'kp', kp)
                                setappdata(0, 'kp_status', 0.0)
                            end
                        else
                            kp = sf/(ef^0.2);
                            setappdata(0, 'kp', kp)
                            setappdata(0, 'kp_status', 1.0)
                        end
                    case 3.0
                        if isempty(ef)
                            if ischar(material_properties.kp)
                                kp = str2double(material_properties.kp);
                            else
                                kp = material_properties.kp;
                            end
                            
                            if isnumeric(kp) == 0.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            elseif isempty(kp) == 1.0 || isnan(kp) == 1.0 || isinf(kp) == 1.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            elseif isreal(kp) == 0.0
                                kp = [];
                                setappdata(0, 'kp', [])
                                setappdata(0, 'kp_status', -1.0)
                            else
                                setappdata(0, 'kp', kp)
                                setappdata(0, 'kp_status', 0.0)
                            end
                        else
                            kp = sf/(ef^0.2);
                            setappdata(0, 'kp', kp)
                            setappdata(0, 'kp_status', 1.0)
                        end
                    case 4.0
                        if ischar(material_properties.kp)
                            kp = str2double(material_properties.kp);
                        else
                            kp = material_properties.kp;
                        end
                        
                        if isnumeric(kp) == 0.0
                            kp = [];
                            setappdata(0, 'kp', [])
                            setappdata(0, 'kp_status', -1.0)
                        elseif isempty(kp) == 1.0 || isnan(kp) == 1.0 || isinf(kp) == 1.0
                            kp = [];
                            setappdata(0, 'kp', [])
                            setappdata(0, 'kp_status', -1.0)
                        elseif isreal(kp) == 0.0
                            kp = [];
                            setappdata(0, 'kp', [])
                            setappdata(0, 'kp_status', -1.0)
                        else
                            setappdata(0, 'kp', kp)
                            setappdata(0, 'kp_status', 0.0)
                        end
                    case 5.0
                        kp = [];
                        setappdata(0, 'kp_status', -1.0)
                        setappdata(0, 'kp', [])
                end
            end
            messenger.writeMessage(13.0)
            
            %% Cyclic stress hardening exponent
            if material_properties.np_active == 1.0
                if ischar(material_properties.np)
                    np = str2double(material_properties.np);
                else
                    np = material_properties.np;
                end
                
                if isnumeric(np) == 0.0
                    error = 3.0;
                    return
                elseif isempty(np) == 1.0 || isnan(np) == 1.0 || isinf(np) == 1.0
                    error = 3.0;
                    return
                elseif isreal(np) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'np', np)
                    setappdata(0, 'np_status', 0.0)
                end
            else
                setappdata(0, 'np_status', 1.0)
                switch reg_model
                    case 1.0
                        switch behavior
                            case 1
                                np = 0.15;
                                setappdata(0, 'np', np)
                            case 2
                                np = 0.11;
                                setappdata(0, 'np', np)
                        end
                    case 2.0
                        np = 0.2;
                        setappdata(0, 'np', np)
                    case 3.0
                        np = 0.2;
                        setappdata(0, 'np', np)
                    case 4.0
                        if ischar(material_properties.np)
                            np = str2double(material_properties.np);
                        else
                            np = material_properties.np;
                        end
                        
                        if isnumeric(np) == 0.0
                            np = [];
                            setappdata(0, 'np', [])
                            setappdata(0, 'np_status', -1.0)
                        elseif isempty(np) == 1.0 || isnan(np) == 1.0 || isinf(np) == 1.0
                            np = [];
                            setappdata(0, 'np', [])
                            setappdata(0, 'np_status', -1.0)
                        elseif isreal(np) == 0.0
                            np = [];
                            setappdata(0, 'np', [])
                            setappdata(0, 'np_status', -1.0)
                        else
                            setappdata(0, 'np', np)
                            setappdata(0, 'np_status', 0.0)
                        end
                    case 5.0
                        np = [];
                        setappdata(0, 'np_status', -1.0)
                        setappdata(0, 'np', [])
                end
            end
            messenger.writeMessage(14.0)
            
            %% 0.2% strain proof stress
            if material_properties.proof_active == 1.0
                if ischar(material_properties.proof)
                    twops = str2double(material_properties.proof);
                else
                    twops = material_properties.proof;
                end
                
                if isnumeric(twops) == 0.0
                    error = 3.0;
                    return
                elseif isempty(twops) == 1.0 || isnan(twops) == 1.0 || isinf(twops) == 1.0
                    error = 3.0;
                    return
                elseif isreal(twops) == 0.0
                    error = 3.0;
                    return
                else
                    setappdata(0, 'twops', twops)
                    setappdata(0, 'twops_status', 0)
                end
            elseif isempty(E) == 1.0 || isempty(kp) == 1.0
                if ischar(material_properties.proof)
                    twops = str2double(material_properties.proof);
                else
                    twops = material_properties.proof;
                end
                
                if isnumeric(twops) == 0.0
                    setappdata(0, 'twops', [])
                    setappdata(0, 'twops_status', -1.0)
                elseif isempty(twops) == 1.0 || isnan(twops) == 1.0 || isinf(twops) == 1.0
                    setappdata(0, 'twops', [])
                    setappdata(0, 'twops_status', -1.0)
                elseif isreal(twops) == 0.0
                    setappdata(0, 'twops', [])
                    setappdata(0, 'twops_status', -1.0)
                else
                    setappdata(0, 'twops', twops)
                    setappdata(0, 'twops_status', 0.0)
                end
                
                setappdata(0, 'message_8_group', groups)
                messenger.writeMessage(8.0)
            elseif reg_model ~= 5.0
                twops = preProcess.yield(kp, np);
                setappdata(0, 'twops', twops)
                setappdata(0, 'twops_status', 1.0)
                
                messenger.writeMessage(8.0)
            elseif reg_model == 5.0
                twops = [];
                setappdata(0, 'twops_status', -1.0)
                setappdata(0, 'twops', [])
            end
            
            % The proof stress cannot be greater than the UTS
            if twops > uts
                error = 5.0;
                return
            end
            
            %% Calculate Findley-specific parameters
            fsc = getappdata(0, 'fsc');
            Sf = getappdata(0, 'Sf');
            if fsc == -1.0
                TfPrime = Sf/(2.0*(1.0 + getappdata(0, 'poisson')));
            else
                TfPrime = fsc*Sf;
            end
            
            k = getappdata(0, 'k');
            setappdata(0, 'TfPrime', TfPrime)
            setappdata(0, 'Tfs', sqrt(1.0 + (k*k))*TfPrime)
            
            %% Fail stress parameters for composite failure
            
            % Tensile stress (fiber direction)
            try
                if ischar(material_properties.failStress_tsfd) == 1.0
                    failStress_tsfd = str2double(material_properties.failStress_tsfd);
                else
                    failStress_tsfd = material_properties.failStress_tsfd;
                end
            catch
                failStress_tsfd = [];
                setappdata(0, 'failStress_tsfd', failStress_tsfd)
            end
            if isnan(failStress_tsfd) == 1.0
                failStress_tsfd = [];
            end
            setappdata(0, 'failStress_tsfd', failStress_tsfd)
            
            % Compressive stress (fiber direction)
            try
                if ischar(material_properties.failStress_csfd) == 1.0
                    failStress_csfd = str2double(material_properties.failStress_csfd);
                else
                    failStress_csfd = material_properties.failStress_csfd;
                end
            catch
                failStress_csfd = [];
                setappdata(0, 'failStress_csfd', failStress_csfd)
            end
            if isnan(failStress_csfd) == 1.0
                failStress_csfd = [];
            end
            setappdata(0, 'failStress_csfd', failStress_csfd)
            
            % Tensile stress (transverse direction)
            try
                if ischar(material_properties.failStress_tstd) == 1.0
                    failStress_tstd = str2double(material_properties.failStress_tstd);
                else
                    failStress_tstd = material_properties.failStress_tstd;
                end
            catch
                failStress_tstd = [];
                setappdata(0, 'failStress_tstd', failStress_tstd)
            end
            if isnan(failStress_tstd) == 1.0
                failStress_tstd = [];
            end
            setappdata(0, 'failStress_tstd', failStress_tstd)
            
            % Compressive stress (transverse direction)
            try
                if ischar(material_properties.failStress_cstd) == 1.0
                    failStress_cstd = str2double(material_properties.failStress_cstd);
                else
                    failStress_cstd = material_properties.failStress_cstd;
                end
            catch
                failStress_cstd = [];
                setappdata(0, 'failStress_cstd', failStress_cstd)
            end
            if isnan(failStress_cstd) == 1.0
                failStress_cstd = [];
            end
            setappdata(0, 'failStress_cstd', failStress_cstd)
            
            % Tensile stress (through-thickness direction)
            try
                if ischar(material_properties.failStress_tsttd) == 1.0
                    failStress_tsttd = str2double(material_properties.failStress_tsttd);
                else
                    failStress_tsttd = material_properties.failStress_tsttd;
                end
            catch
                failStress_tsttd = [];
                setappdata(0, 'failStress_tsttd', failStress_tsttd)
            end
            if isnan(failStress_tsttd) == 1.0
                failStress_tsttd = [];
            end
            setappdata(0, 'failStress_tsttd', failStress_tsttd)
            
            % Compressive stress (through-thickness direction)
            try
                if ischar(material_properties.failStress_csttd) == 1.0
                    failStress_csttd = str2double(material_properties.failStress_csttd);
                else
                    failStress_csttd = material_properties.failStress_csttd;
                end
            catch
                failStress_csttd = [];
                setappdata(0, 'failStress_csttd', failStress_csttd)
            end
            if isnan(failStress_csttd) == 1.0
                failStress_csttd = [];
            end
            setappdata(0, 'failStress_csttd', failStress_csttd)
            
            % Shear strength
            try
                if ischar(material_properties.failStress_shear) == 1.0
                    failStress_shear = str2double(material_properties.failStress_shear);
                else
                    failStress_shear = material_properties.failStress_shear;
                end
            catch
                failStress_shear = [];
                setappdata(0, 'failStress_shear', failStress_shear)
            end
            if isnan(failStress_shear) == 1.0
                failStress_shear = [];
            end
            setappdata(0, 'failStress_shear', failStress_shear)
            
            % Cross product coefficient (12-direction)
            try
                if ischar(material_properties.failStress_cross12) == 1.0
                    failStress_cross12 = str2double(material_properties.failStress_cross12);
                else
                    failStress_cross12 = material_properties.failStress_cross12;
                end
            catch
                failStress_cross12 = 0.0;
                setappdata(0, 'failStress_cross12', failStress_cross12)
            end
            
            if isnan(failStress_cross12) == 1.0
                failStress_cross12 = 0.0;
            end
            
            setappdata(0, 'failStress_cross12', failStress_cross12)
            
            % Cross product coefficient (23-direction)
            try
                if ischar(material_properties.failStress_cross23) == 1.0
                    failStress_cross23 = str2double(material_properties.failStress_cross23);
                else
                    failStress_cross23 = material_properties.failStress_cross23;
                end
            catch
                failStress_cross23 = 0.0;
                setappdata(0, 'failStress_cross23', failStress_cross23)
            end
            
            if isnan(failStress_cross23) == 1.0
                failStress_cross23 = 0.0;
            end
            
            setappdata(0, 'failStress_cross23', failStress_cross23)
            
            % Limit stress (12-direction)
            try
                if ischar(material_properties.failStress_limit12) == 1.0
                    failStress_limit12 = str2double(material_properties.failStress_limit12);
                else
                    failStress_limit12 = material_properties.failStress_limit12;
                end
            catch
                failStress_limit12 = [];
                setappdata(0, 'failStress_limit12', failStress_limit12)
            end
            
            if isnan(failStress_limit12) == 1.0
                failStress_limit12 = [];
            end
            
            setappdata(0, 'failStress_limit12', failStress_limit12)
            
            % Limit stress (23-direction)
            try
                if ischar(material_properties.failStress_limit23) == 1.0
                    failStress_limit23 = str2double(material_properties.failStress_limit23);
                else
                    failStress_limit23 = material_properties.failStress_limit23;
                end
            catch
                failStress_limit23 = [];
                setappdata(0, 'failStress_limit23', failStress_limit23)
            end
            
            if isnan(failStress_limit23) == 1.0
                failStress_limit23 = [];
            end
            
            setappdata(0, 'failStress_limit23', failStress_limit23)
            
            %% Fail strain parameters for composite failure
            
            % Tensile strain (fiber direction)
            try
                if ischar(material_properties.failStrain_tsfd) == 1.0
                    failStrain_tsfd = str2double(material_properties.failStrain_tsfd);
                else
                    failStrain_tsfd = material_properties.failStrain_tsfd;
                end
            catch
                failStrain_tsfd = [];
                setappdata(0, 'failStrain_tsfd', failStrain_tsfd)
            end
            if isnan(failStrain_tsfd) == 1.0
                failStrain_tsfd = [];
            end
            setappdata(0, 'failStrain_tsfd', failStrain_tsfd)
            
            % Compressive strain (fiber direction)
            try
                if ischar(material_properties.failStrain_csfd) == 1.0
                    failStrain_csfd = str2double(material_properties.failStrain_csfd);
                else
                    failStrain_csfd = material_properties.failStrain_csfd;
                end
            catch
                failStrain_csfd = [];
                setappdata(0, 'failStrain_csfd', failStrain_csfd)
            end
            if isnan(failStrain_csfd) == 1.0
                failStrain_csfd = [];
            end
            setappdata(0, 'failStrain_csfd', failStrain_csfd)
            
            % Tensile strain (transverse direction)
            try
                if ischar(material_properties.failStrain_tstd) == 1.0
                    failStrain_tstd = str2double(material_properties.failStrain_tstd);
                else
                    failStrain_tstd = material_properties.failStrain_tstd;
                end
            catch
                failStrain_tstd = [];
                setappdata(0, 'failStrain_tstd', failStrain_tstd)
            end
            if isnan(failStrain_tstd) == 1.0
                failStrain_tstd = [];
            end
            setappdata(0, 'failStrain_tstd', failStrain_tstd)
            
            % Compressive strain (transverse direction)
            try
                if ischar(material_properties.failStrain_cstd) == 1.0
                    failStrain_cstd = str2double(material_properties.failStrain_cstd);
                else
                    failStrain_cstd = material_properties.failStrain_cstd;
                end
            catch
                failStrain_cstd = [];
                setappdata(0, 'failStrain_cstd', failStrain_cstd)
            end
            if isnan(failStrain_cstd) == 1.0
                failStrain_cstd = [];
            end
            setappdata(0, 'failStrain_cstd', failStrain_cstd)
            
            % Shear strain
            try
                if ischar(material_properties.failStrain_shear) == 1.0
                    failStrain_shear = str2double(material_properties.failStrain_shear);
                else
                    failStrain_shear = material_properties.failStrain_shear;
                end
            catch
                failStrain_shear = [];
                setappdata(0, 'failStrain_shear', failStrain_shear)
            end
            if isnan(failStrain_shear) == 1.0
                failStrain_shear = [];
            end
            setappdata(0, 'failStrain_shear', failStrain_shear)
            
            % Elastic modulus (fiber direction)
            try
                if ischar(material_properties.failStrain_e11) == 1.0
                    failStrain_e11 = str2double(material_properties.failStrain_e11);
                else
                    failStrain_e11 = material_properties.failStrain_e11;
                end
            catch
                failStrain_e11 = [];
                setappdata(0, 'failStrain_e11', failStrain_e11)
            end
            if isnan(failStrain_e11) == 1.0
                failStrain_e11 = [];
            end
            setappdata(0, 'failStrain_e11', failStrain_e11)
            
            % Elastic modulus (transverse direction)
            try
                if ischar(material_properties.failStrain_e22) == 1.0
                    failStrain_e22 = str2double(material_properties.failStrain_e22);
                else
                    failStrain_e22 = material_properties.failStrain_e22;
                end
            catch
                failStrain_e22 = [];
                setappdata(0, 'failStrain_e22', failStrain_e22)
            end
            if isnan(failStrain_e22) == 1.0
                failStrain_e22 = [];
            end
            setappdata(0, 'failStrain_e22', failStrain_e22)
            
            % Section Poisson's ratio
            try
                if ischar(material_properties.failStrain_g12) == 1.0
                    failStrain_g12 = str2double(material_properties.failStrain_g12);
                else
                    failStrain_g12 = material_properties.failStrain_g12;
                end
            catch
                failStrain_g12 = [];
                setappdata(0, 'failStrain_g12', failStrain_g12)
            end
            if isnan(failStrain_g12) == 1.0
                failStrain_g12 = [];
            end
            setappdata(0, 'failStrain_g12', failStrain_g12)
            
            %% Hashin parameters for composite failure
            
            % Alpha
            try
                if ischar(material_properties.hashin_alpha) == 1.0
                    hashin_alpha = str2double(material_properties.hashin_alpha);
                else
                    hashin_alpha = material_properties.hashin_alpha;
                end
            catch
                hashin_alpha = 0.0;
                setappdata(0, 'hashin_alpha', hashin_alpha)
            end
            if isnan(hashin_alpha) == 1.0
                hashin_alpha = 0.0;
            end
            setappdata(0, 'hashin_alpha', hashin_alpha)
            
            % Longitudinal tensile strength
            try
                if ischar(material_properties.hashin_lts) == 1.0
                    hashin_lts = str2double(material_properties.hashin_lts);
                else
                    hashin_lts = material_properties.hashin_lts;
                end
            catch
                hashin_lts = [];
                setappdata(0, 'hashin_lts', hashin_lts)
            end
            if isnan(hashin_lts) == 1.0
                hashin_lts = [];
            end
            setappdata(0, 'hashin_lts', hashin_lts)
            
            % Longitudinal compressive strength
            try
                if ischar(material_properties.hashin_lcs) == 1.0
                    hashin_lcs = str2double(material_properties.hashin_lcs);
                else
                    hashin_lcs = material_properties.hashin_lcs;
                end
            catch
                hashin_lcs = [];
                setappdata(0, 'hashin_lcs', hashin_lcs)
            end
            if isnan(hashin_lcs) == 1.0
                hashin_lcs = [];
            end
            setappdata(0, 'hashin_lcs', hashin_lcs)
            
            % Transverse tensile strength
            try
                if ischar(material_properties.hashin_tts) == 1.0
                    hashin_tts = str2double(material_properties.hashin_tts);
                else
                    hashin_tts = material_properties.hashin_tts;
                end
            catch
                hashin_tts = [];
                setappdata(0, 'hashin_tts', hashin_tts)
            end
            if isnan(hashin_tts) == 1.0
                hashin_tts = [];
            end
            setappdata(0, 'hashin_tts', hashin_tts)
            
            % Transverse compressive strength
            try
                if ischar(material_properties.hashin_tcs) == 1.0
                    hashin_tcs = str2double(material_properties.hashin_tcs);
                else
                    hashin_tcs = material_properties.hashin_tcs;
                end
            catch
                hashin_tcs = [];
                setappdata(0, 'hashin_tcs', hashin_tcs)
            end
            if isnan(hashin_tcs) == 1.0
                hashin_tcs = [];
            end
            setappdata(0, 'hashin_tcs', hashin_tcs)
            
            % Longitudinal shear strength
            try
                if ischar(material_properties.hashin_lss) == 1.0
                    hashin_lss = str2double(material_properties.hashin_lss);
                else
                    hashin_lss = material_properties.hashin_lss;
                end
            catch
                hashin_lss = [];
                setappdata(0, 'hashin_lss', hashin_lss)
            end
            if isnan(hashin_lss) == 1.0
                hashin_lss = [];
            end
            setappdata(0, 'hashin_lss', hashin_lss)
            
            % Transverse shear strength
            try
                if ischar(material_properties.hashin_tss) == 1.0
                    hashin_tss = str2double(material_properties.hashin_tss);
                else
                    hashin_tss = material_properties.hashin_tss;
                end
            catch
                hashin_tss = [];
                setappdata(0, 'hashin_tss', hashin_tss)
            end
            if isnan(hashin_tss) == 1.0
                hashin_tss = [];
            end
            setappdata(0, 'hashin_tss', hashin_tss)
            
            %% LaRC05 parameters for composite failure
            
            % Longitudinal tensile strength
            try
                if ischar(material_properties.larc05_lts) == 1.0
                    larc05_lts = str2double(material_properties.larc05_lts);
                else
                    larc05_lts = material_properties.larc05_lts;
                end
            catch
                larc05_lts = [];
                setappdata(0, 'larc05_lts', larc05_lts)
            end
            if isnan(larc05_lts) == 1.0
                larc05_lts = [];
            end
            setappdata(0, 'larc05_lts', larc05_lts)
            
            % Longitudinal compressive strength
            try
                if ischar(material_properties.larc05_lcs) == 1.0
                    larc05_lcs = str2double(material_properties.larc05_lcs);
                else
                    larc05_lcs = material_properties.larc05_lcs;
                end
            catch
                larc05_lcs = [];
                setappdata(0, 'larc05_lcs', larc05_lcs)
            end
            if isnan(larc05_lcs) == 1.0
                larc05_lcs = [];
            end
            setappdata(0, 'larc05_lcs', larc05_lcs)
            
            % Transverse tensile strength
            try
                if ischar(material_properties.larc05_tts) == 1.0
                    larc05_tts = str2double(material_properties.larc05_tts);
                else
                    larc05_tts = material_properties.larc05_tts;
                end
            catch
                larc05_tts = [];
                setappdata(0, 'larc05_tts', larc05_tts)
            end
            if isnan(larc05_tts) == 1.0
                larc05_tts = [];
            end
            setappdata(0, 'larc05_tts', larc05_tts)
            
            % Transverse compressive strength
            try
                if ischar(material_properties.larc05_tcs) == 1.0
                    larc05_tcs = str2double(material_properties.larc05_tcs);
                else
                    larc05_tcs = material_properties.larc05_tcs;
                end
            catch
                larc05_tcs = [];
                setappdata(0, 'larc05_tcs', larc05_tcs)
            end
            if isnan(larc05_tcs) == 1.0
                larc05_tcs = [];
            end
            setappdata(0, 'larc05_tcs', larc05_tcs)
            
            % Longitudinal shear strength
            try
                if ischar(material_properties.larc05_lss) == 1.0
                    larc05_lss = str2double(material_properties.larc05_lss);
                else
                    larc05_lss = material_properties.larc05_lss;
                end
            catch
                larc05_lss = [];
                setappdata(0, 'larc05_lss', larc05_lss)
            end
            if isnan(larc05_lss) == 1.0
                larc05_lss = [];
            end
            setappdata(0, 'larc05_lss', larc05_lss)
            
            % Transverse shear strength
            try
                if ischar(material_properties.larc05_tss) == 1.0
                    larc05_tss = str2double(material_properties.larc05_tss);
                else
                    larc05_tss = material_properties.larc05_tss;
                end
            catch
                larc05_tss = [];
                setappdata(0, 'larc05_tss', larc05_tss)
            end
            if isnan(larc05_tss) == 1.0
                larc05_tss = [];
            end
            setappdata(0, 'larc05_tss', larc05_tss)
            
            % Shear modulus
            try
                if ischar(material_properties.larc05_shear) == 1.0
                    larc05_shear = str2double(material_properties.larc05_shear);
                else
                    larc05_shear = material_properties.larc05_shear;
                end
            catch
                larc05_shear = [];
                setappdata(0, 'larc05_shear', larc05_shear)
            end
            if isnan(larc05_shear) == 1.0
                larc05_shear = [];
            end
            setappdata(0, 'larc05_shear', larc05_shear)
            
            % Longitudinal slope coefficient
            try
                if ischar(material_properties.larc05_nl) == 1.0
                    larc05_nl = str2double(material_properties.larc05_nl);
                else
                    larc05_nl = material_properties.larc05_nl;
                end
            catch
                larc05_nl = [];
                setappdata(0, 'larc05_nl', larc05_nl)
            end
            if isnan(larc05_nl) == 1.0
                larc05_nl = [];
            end
            setappdata(0, 'larc05_nl', larc05_nl)
            
            % Transverse slope coefficient
            try
                if ischar(material_properties.larc05_nt) == 1.0
                    larc05_nt = str2double(material_properties.larc05_nt);
                else
                    larc05_nt = material_properties.larc05_nt;
                end
            catch
                larc05_nt = [];
                setappdata(0, 'larc05_nt', larc05_nt)
            end
            if isnan(larc05_nt) == 1.0
                larc05_nt = [];
            end
            setappdata(0, 'larc05_nt', larc05_nt)
            
            % Fracture angle for pure compression
            try
                if ischar(material_properties.larc05_alpha0) == 1.0
                    larc05_alpha0 = str2double(material_properties.larc05_alpha0);
                else
                    larc05_alpha0 = material_properties.larc05_alpha0;
                end
            catch
                larc05_alpha0 = 53.0;
                setappdata(0, 'larc05_alpha0', larc05_alpha0)
            end
            if isnan(larc05_alpha0) == 1.0
                larc05_alpha0 = 53.0;
            end
            setappdata(0, 'larc05_alpha0', larc05_alpha0)
            
            % Initial fiber misalignment angle
            try
                if ischar(material_properties.larc05_phi0) == 1.0
                    larc05_phi0 = str2double(material_properties.larc05_phi0);
                else
                    larc05_phi0 = material_properties.larc05_phi0;
                end
            catch
                larc05_phi0 = [];
                setappdata(0, 'larc05_phi0', larc05_phi0)
            end
            if isnan(larc05_phi0) == 1.0
                larc05_phi0 = [];
            end
            setappdata(0, 'larc05_phi0', larc05_phi0)
            
            % Allow iterative solution for initial fibre misalignment angle
            try
                if ischar(material_properties.larc05_iterate) == 1.0
                    larc05_iterate = str2double(material_properties.larc05_iterate);
                else
                    larc05_iterate = material_properties.larc05_iterate;
                end
            catch
                larc05_iterate = 0.0;
                setappdata(0, 'larc05_iterate', larc05_iterate)
            end
            if (isempty(larc05_iterate) == 1.0) || (isnan(larc05_iterate) == 1.0)
                larc05_iterate = 0.0;
            elseif (larc05_iterate ~= 0.0) && (larc05_iterate ~= 1.0)
                larc05_iterate = 0.0;
            end
            setappdata(0, 'larc05_iterate', larc05_iterate)
        end
        
        %% Approximate the yield stress:
        function twops = yield(K, n)
            twops = K*(0.002)^n;
        end
        
        %% Remove intermediate dat from load history
        function [maxtab, mintab] = peakdet(v, delta, x)
            %PEAKDET Detect peaks in a vector
            %        [MAXTAB, MINTAB] = PEAKDET(V, DELTA) finds the local
            %        maxima and minima ("peaks") in the vector V.
            %        MAXTAB and MINTAB consists of two columns. Column 1
            %        contains indices in V, and column 2 the found values.
            %
            %        With [MAXTAB, MINTAB] = PEAKDET(V, DELTA, X) the indices
            %        in MAXTAB and MINTAB are replaced with the corresponding
            %        X-values.
            %
            %        A point is considered a maximum peak if it has the maximal
            %        value, and was preceded (to the left) by a value lower by
            %        DELTA.
            
            % Eli Billauer, 3.4.05 (Explicitly not copyrighted).
            % This function is released to the public domain; Any use is allowed.
            
            maxtab = [];
            mintab = [];
            
            v = v(:); % Just in case this wasn't a proper vector
            
            if nargin < 3.0
                x = (1:length(v))';
            else
                x = x(:);
                if length(v) ~= length(x)
                    return
                end
            end
            
            if (length(delta(:))) > 1.0
                return
            end
            
            if delta <= 0.0
                return
            end
            
            mn = Inf; mx = -Inf;
            mnpos = NaN; mxpos = NaN;
            
            lookformax = 1.0;
            
            for i = 1:length(v)
                this = v(i);
                if this > mx
                    mx = this;
                    mxpos = x(i);
                end
                if this < mn
                    mn = this;
                    mnpos = x(i);
                end
                
                if lookformax
                    if this < mx-delta
                        maxtab = [maxtab; mxpos, mx]; %#ok<AGROW>
                        mn = this;
                        mnpos = x(i);
                        lookformax = 0.0;
                    end
                else
                    if this > mn+delta
                        mintab = [mintab; mnpos, mn]; %#ok<AGROW>
                        mx = this;
                        mxpos = x(i);
                        lookformax = 1.0;
                    end
                end
            end
            
            [Rmax, ~] = size(maxtab);
            [Rmin, ~] = size(mintab);
            
            if Rmax > Rmin
                mintab = [mintab; mnpos, this];
            end
        end
        
        %% Perform nodal elimination
        function [coldItems, removed, hotspotWarning] = nodalElimination(algorithm,...
                msCorrection, items)
            
            %{
                If a fatigue loading file exists and a recall analysis is
                specified, load the previous nodal elimination data
                instead.
            %}
            if isappdata(0, 'fldData') == 1.0
                % Get the fatigue definition from the %APPDATA%
                fatigueDefinition = getappdata(0, 'fldData');
                
                neData = fatigueDefinition.neData;
                
                coldItems = neData.CI;
                removed = neData.RI;
                hotspotWarning = neData.W;
                
                % Delete the fatigue definition data from the workspace
                clear('fatigueDefinition')
                clear('neData')
                
                return
            end
            
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            % Threshold scaling factor
            scaleFactor = getappdata(0, 'thresholdScaleFactor');
            
            % Save the original number of items
            items_original = items;
            
            if G == 1.0
                groupIDBuffer = -1.0;
            else
                % Get the group ID buffer
                groupIDBuffer = getappdata(0, 'groupIDBuffer');
            end
            
            % Get the principal stress
            s1 = getappdata(0, 'S1');
            s2 = getappdata(0, 'S2');
            s3 = getappdata(0, 'S3');
            
            % Get other parameters related to the hotspot analysis
            plasticSN = getappdata(0, 'plasticSN');
            useSN = getappdata(0, 'useSN');
            
            designLife = getappdata(0, 'dLife');
            nodalElimination = getappdata(0, 'nodalElimination');
            
            j = 1.0;
            coldItems = zeros(1.0, 1.0);
            none = 1.0;
            range_item = zeros(1.0, items);
            mean_item = range_item;
            
            %{
                Set a counter which runs from 1 to the total number of
                analysis items
            %}
            totalCounter = 0.0;
            
            for groups = 1:G
                if G > 1.0
                    % Assign group parameters to the current set of analysis IDs
                    [items, ~] = group.switchProperties(groups, groupIDBuffer(groups));
                end
                
                hotspotWarning = 0.0;
                residual = getappdata(0, 'residualStress');
                
                if nodalElimination == 2.0 && isempty(designLife) == 0.0
                    % Calculate the fatigue limit stress (conditional stress)
                    Sf = getappdata(0, 'Sf');
                    b = getappdata(0, 'b');
                    E = getappdata(0, 'E');
                    
                    if useSN == 1.0
                        N = getappdata(0, 'n_values');
                        
                        if getappdata(0, 'nSNDatasets') > 1.0
                            S = getappdata(0, 's_values_reduced');
                        else
                            S = getappdata(0, 's_values');
                        end
                        
                        conditionalStress = 10^(interp1(log10(N), log10(S), log10(designLife), 'linear', 'extrap'));
                    elseif algorithm == 4.0 %SBBM
                        Ef = getappdata(0, 'Ef');
                        c = getappdata(0, 'c');
                        
                        if plasticSN == 1.0 && (~isempty(Ef) && ~isempty(c))
                            conditionalStress = E*(((1.65*Sf)/(E))*(2.0*designLife)^b + (1.75*Ef)*(2.0*designLife)^c);
                        else
                            conditionalStress = ((1.65*Sf))*(2.0*designLife)^b;
                        end
                    elseif algorithm == 6.0 % Findley
                        Tfs = getappdata(0, 'Tfs');
                        
                        conditionalStress = Tfs*((2.0*designLife)^b);
                    else % PS, von Mises or NASALIFE
                        conditionalStress = Sf*((2.0*designLife)^b);
                    end
                else
                    conditionalStress = getappdata(0, 'fatigueLimit');
                end
                
                % Begin nodal elimination
                for i = 1.0:items
                    
                    % Update the counter
                    totalCounter = totalCounter + 1.0;
                    
                    %{
                        If groups are being used, convert the current item
                        number to the current item ID in the current group
                    %}
                    
                    s1_i = s1(totalCounter, :);
                    s2_i = s2(totalCounter, :);
                    s3_i = s3(totalCounter, :);
                    
                    range_item(totalCounter) = 0.5*(max(s1_i) - min(s3_i));
                    mean_item(totalCounter) = max(0.5.*(s1_i + s3_i));
                    
                    %{
                        The maximum principal stress range does not
                        guarantee safe nodal elimination. The maximum
                        stress cycle must also be corrected for the effect
                        of mean stress
                    %}
                    if algorithm == 4.0 && msCorrection == 1.0 && useSN == 0.0
                        if nodalElimination == 2.0 && isempty(designLife) == 0.0
                            cael = 2.0*getappdata(0, 'dLife');
                        else
                            cael = getappdata(0, 'cael');
                        end
                        E = getappdata(0, 'E');
                        Sf = getappdata(0, 'Sf');
                        b = getappdata(0, 'b');
                        Ef = getappdata(0, 'Ef');
                        c = getappdata(0, 'c');
                        
                        maxShearXY = max(0.5.*(s1_i - s2_i));
                        maxShearYZ = max(0.5.*(s2_i - s3_i));
                        maxShearXZ = max(0.5.*(s1_i - s3_i));
                        shear = 0.5*max([maxShearXY, maxShearYZ, maxShearXZ]);
                        
                        morrowSf = Sf - mean_item(totalCounter);
                        
                        if plasticSN == 1.0 && (isempty(Ef) == 0.0 && isempty(c) == 0.0)
                            conditionalStress = E*(((1.65*morrowSf)/(E))*(cael)^b + (1.75*Ef)*(cael)^c) - shear;
                        else
                            conditionalStress = ((1.65*morrowSf))*(cael)^b - shear;
                        end
                    elseif (msCorrection < 7.0) && (algorithm ~= 6.0 && algorithm ~= 8.0 && algorithm ~= 9.0)
                        [range_item(totalCounter), ~, ~] = analysis.msc(range_item(totalCounter), [min(s3_i), max(s1_i)], msCorrection, residual);
                    end
                    
                    % Check if the maximum stress is lower than the fatigue limit
                    if range_item(totalCounter) < scaleFactor*conditionalStress
                        coldItems(j) = totalCounter;
                        j = j + 1.0;
                        
                        none = 0.0;
                    end
                end
            end
            
            % Check if there is any data remaining
            removed = length(coldItems);
            
            if removed == items_original
                % All items were removed, so keep the worst item only
                maximums = range_item == max(range_item);
                itemsToKeep = length(maximums(maximums == 1.0));
                
                % A maximum of 10 items will be retained
                if itemsToKeep > 10.0
                    maximums_indexes = find(maximums == 1.0);
                    indexesToZero = maximums_indexes(11:end);
                    maximums(indexesToZero) = 0.0;
                    
                    removed = items_original - 10.0;
                elseif itemsToKeep > 1.0
                    removed = items_original - itemsToKeep;
                else
                    removed = items_original - 1.0;
                end
                
                coldItems(maximums) = [];
                hotspotWarning = 1.0;
                
            elseif none == 1.0
                % No items were removed
                removed = 0.0;
				coldItems = [];
                return
            end
        end
        
        %% Scale and combine load/channel dataset pairs:
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, error] = scalecombine(channels, scales, items, gateHistories, historyGate, loadingScale, loadingOffset, elementType)
            
            error = 0.0;
            
            % Make sure the loading and history files exist
            if isempty(channels) == 1.0
                error = 1.0;
                setappdata(0, 'E023', 1.0)
            elseif ischar(channels)
                if exist(channels, 'file') == 0.0
                    error = 1.0;
                    setappdata(0, 'E035', 1.0)
                    setappdata(0, 'errorMissingChannel', channels)
                end
            else
                for i = 1:length(channels)
                    if exist(channels{i}, 'file') == 0.0
                        error = 1.0;
                        setappdata(0, 'E035', 1.0)
                        setappdata(0, 'errorMissingChannel', channels{i})
                        break
                    end
                end
            end
            
            if ischar(scales)
                % Single load history defined from file
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                elseif exist(scales, 'file') == 0.0
                    error = 1.0;
                    setappdata(0, 'E036', 1.0)
                    setappdata(0, 'errorMissingScale', scales)
                end
            elseif isnumeric(scales) == 1.0 && isempty(scales) == 0.0
                % Single load history defined directly
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                end
            else
                for i = 1:length(scales)
                    if isempty(scales{i}) == 1.0
                        error = 1.0;
                        setappdata(0, 'E047', 1.0)
                    elseif (ischar(scales{i}) == 1.0) && (exist(scales{i}, 'file') == 0.0)
                        % The current load history is defined from a file
                        error = 1.0;
                        setappdata(0, 'E036', 1.0)
                        setappdata(0, 'errorMissingScale', scales{i})
                        break
                    elseif (isnumeric(scales{i}) == 1.0) && (isempty(scales{i}) == 1.0)
                        % The current load history is defined directly
                        error = 1.0;
                        setappdata(0, 'E036', 1.0)
                        setappdata(0, 'errorMissingScale', scales{i})
                        break
                    end
                end
            end
            
            if error == 1.0
                Sxx = 0; Syy = 0; Szz = 0; Txy = 0; Tyz = 0; Txz = 0;
                mainID = -999;
                subID = -999;
                
                return
            end
            
            %% If the user specified a dataset sequence, a scale and combine loading is not required
            if isempty(scales) == 1.0
                [error, mainID, subID, Sxx, Syy, Szz, Txy, Tyz, Txz] = preProcess.datasetSequence(channels, items, elementType, loadingScale, loadingOffset);
                
                %% Warn the user if there are any duplicate IDs in the model
                duplicateMainIDs = length(mainID) - length(unique(mainID));
                
                if duplicateMainIDs > 0.0 && getappdata(0, 'nodeType_master') == 1.0
                    setappdata(0, 'duplicateMainIDs', duplicateMainIDs)
                    messenger.writeMessage(153.0)
                end
                return
            end
            
            %% Make sure there are the same number of channels as scales:
            error = false;
            if (isnumeric(scales) == 1.0) && (iscell(channels) == 1.0)
                % A single scale is defined, but the channels appear to have multiple definitions
                if length(channels) == 1.0
                    messenger.writeMessage(29.0)
                else
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    mainID = -999.0;
                    subID = -999.0;
                    
                    error = true;
                    setappdata(0, 'E014', 1.0)
                    return
                end
                
                multiple = 3.0;
            elseif (ischar(scales) == 0.0) && (ischar(channels) == 0.0)
                % Multiple channels and loads appear to be defined
                if (length(channels) ~= length(scales))
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    mainID = -999.0;
                    subID = -999.0;
                    
                    error = true;
                    setappdata(0, 'E012', 1.0)
                    return
                end
                multiple = 1.0;
            elseif (ischar(scales) == 0.0) && (ischar(channels) == 1.0)
                % A single channel is defined, but the scales appear to have multiple definitions
                if isnumeric(scales) == 1.0
                    % The scales appeared to have multiple definitions because they're numeric
                    multiple = 0.0;
                elseif length(scales) == 1.0
                    messenger.writeMessage(29.0)
                    
                    multiple = 2.0;
                else
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    mainID = -999.0;
                    subID = -999.0;
                    
                    error = true;
                    setappdata(0, 'E013', 1.0)
                    return
                end
            elseif (ischar(scales) == 1.0) && (ischar(channels) == 0.0)
                % A single scale is defined, but the channels appear to have multiple definitions
                if length(channels) == 1.0
                    messenger.writeMessage(29.0)
                else
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    mainID = -999.0;
                    subID = -999.0;
                    
                    error = true;
                    setappdata(0, 'E014', 1.0)
                    return
                end
                
                multiple = 3.0;
            else
                multiple = 0.0;
            end
            
            try
                %% Load files:
                
                j1 = 1.0; first_time = 1.0;
                
                if multiple == 1.0
                    L = length(channels);
                else
                    L = 1.0;
                end
                
                % Make sure data label warning can only be displayed once
                setappdata(0, 'dataLabel', [])
                
                % Verify load history gating values
                nGates = length(historyGate);
                
                if L == nGates
                    % Dataset/history pairs equal to number of historyGate values
                elseif L > nGates && gateHistories == 1.0
                    messenger.writeMessage(2.0)
                    
                    % Dataset/history pairs greater than number of historyGate values
                    extraGates = linspace(historyGate(end), historyGate(end), (L - nGates));
                    historyGate = [historyGate, extraGates];
                elseif L < nGates && gateHistories == 1.0
                    messenger.writeMessage(2.0)
                    
                    % Dataset/history pairs less than number of historyGate values
                    gatesToDelete = nGates - L;
                    historyGate(end - (gatesToDelete - 1.0) : end) = [];
                end
                
                % Verify the loading scale factors
                nScaleFactors = length(loadingScale);
                
                if L == nScaleFactors
                    % Dataset/history pairs equal to number of scale factors
                elseif L > nScaleFactors
                    messenger.writeMessage(3.0)
                    
                    % Dataset/history pairs greater than number of scale
                    % factors
                    extraScaleFactors = linspace(loadingScale(end), loadingScale(end), (L - nScaleFactors));
                    loadingScale = [loadingScale, extraScaleFactors];
                elseif L < nScaleFactors
                    messenger.writeMessage(3.0)
                    
                    % Dataset/history pairs less than number of scale factors
                    scaleFactorsToDelete = nScaleFactors - L;
                    loadingScale(end - (scaleFactorsToDelete - 1.0) : end) = [];
                end
                
                % Verify the loading offset values
                if isempty(loadingOffset) == 1.0
                    loadingOffset = zeros(1.0, L);
                    nOffsetValues = L;
                else
                    nOffsetValues = length(loadingOffset);
                end
                
                if L == nOffsetValues
                    % Dataset/history pairs equal to number of offest values
                elseif L > nOffsetValues
                    messenger.writeMessage(4.0)
                    
                    % Dataset/history pairs greater than number of historyGate values
                    extraOffsetValues = linspace(loadingOffset(end), loadingOffset(end), (L - nOffsetValues));
                    loadingOffset = [loadingOffset, extraOffsetValues];
                elseif L < nOffsetValues
                    messenger.writeMessage(4.0)
                    
                    % Dataset/history pairs less than number of historyGate values
                    offsetValuesToDelete = nOffsetValues - L;
                    loadingOffset(end - (offsetValuesToDelete - 1.0) : end) = [];
                end
                
                % Load each loading definition file before combining
                scaleBuffer = cell(1.0, L);
                historyLengths = zeros(1.0, L);
                
                % Number of windows for noise reduction algorithm
                nWindows = getappdata(0, 'numberOfWindows');
                nCoefficient = ones(1.0, nWindows)/nWindows;
                
                for i = 1.0:L
                    if multiple == 1.0 || multiple == 2.0
                        if ischar(scales{i}) == 1.0
                            try
                                scale = dlmread(scales{i});
                            catch unhandledException
                                error = true;
                                setappdata(0, 'E016', 1.0)
                                setappdata(0, 'error_log_016_exceptionMessage', unhandledException.identifier)
                                setappdata(0, 'loadHistoryUnableOpen', scales{i})
                                
                                if exist(scales{i}, 'file') == 0.0
                                    setappdata(0, 'scaleNotFound', 1.0)
                                end
                                
                                mainID = -999.0;
                                subID = -999.0;
                                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                                return
                            end
                        else
                            % The scale is defined directly in the job file
                            scale = scales{i};
                        end
                    else
                        if ischar(scales) == 1.0
                            try
                                scale = dlmread(scales);
                            catch unhandledException
                                error = true;
                                setappdata(0, 'E016', 1.0)
                                setappdata(0, 'error_log_016_exceptionMessage', unhandledException.identifier)
                                setappdata(0, 'loadHistoryUnableOpen', scales)
                                
                                if exist(scales, 'file') == 0.0
                                    setappdata(0, 'scaleNotFound', 1.0)
                                end
                                
                                mainID = -999.0;
                                subID = -999.0;
                                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                                return
                            end
                        else
                            % The scale is defined directly in the job file
                            scale = scales;
                        end
                    end
                    
                    % Remove INF/NaN values from load history data
                    scale(scale == inf) = [];
                    scale(scale == -inf) = [];
                    scale(isnan(scale)) = [];
                    
                    % Check the length of the history data
                    if length(scale) < 2.0
                        if getappdata(0, 'compositeCriteria') == 1.0
                            %{
                                For composite failure criteria analysis, a
                                load history 1 point is permitted. Prepend
                                a zero to the load history
                            %}
                            scale = [0.0, scale]; %#ok<AGROW>
                        else
                            error = true;
                            setappdata(0, 'E017', 1.0)
                            
                            mainID = -999.0;
                            subID = -999.0;
                            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                            return
                        end
                    end
                    
                    % Check the dimensionality of the history data
                    [r, c] = size(scale);
                    if (r ~= 1.0) && (c ~= 1.0)
                        setappdata(0, 'error_log_020', 1.0)
                        setappdata(0, 'loadHistoryUnableOpen', scales{i})
                        
                        error = true;
                        
                        mainID = -999.0;
                        subID = -999.0;
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    elseif c == 1.0
                        scale = scale';
                    end
                    
                    % Perform noise reduction if applicable
                    if getappdata(0, 'noiseReduction') == 1.0
                        messenger.writeMessage(267.0)
                        scale = filter(nCoefficient, 1.0, scale);
                    end
                    
                    % Perform peak-valley detection if a user-defined history is being used
                    if length(scale) > 2.0
                        if gateHistories == 1.0
                            % Get gating values from % of max tensor
                            if historyGate(i) > 0.0
                                historyGate(i) = preProcess.autoGate(scale, historyGate(i));
                            end
                            
                            [peaks, valleys] = preProcess.peakdet(scale, historyGate(i));
                            
                            if (isempty(peaks) == 1.0) || (isempty(valleys) == 1.0)
                                error = true;
                                if ischar(scales) == 1.0
                                    setappdata(0, 'E018', 1.0)
                                    setappdata(0, 'pvDetectionFailFile', scales)
                                elseif iscell(scales) == 1.0
                                    setappdata(0, 'E018', 1.0)
                                    setappdata(0, 'pvDetectionFailFile', scales{i})
                                else
                                    setappdata(0, 'E146', 1.0)
                                end
                                
                                mainID = -999.0;
                                subID = -999.0;
                                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                                return
                            end
                            
                            % Order the P-V time values from low to high
                            times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                            
                            % Reconstruct the history signal
                            newLength = length(times);
                            scale = zeros(1.0, newLength);
                            
                            peak_j = 1.0; valley_j = 1.0;
                            
                            for j = 1.0:newLength
                                if any(peaks(:, 1.0) == times(j))
                                    scale(j) = peaks(peak_j, 2.0);
                                    peak_j = peak_j + 1.0;
                                else
                                    scale(j) = valleys(valley_j, 2.0);
                                    valley_j = valley_j + 1.0;
                                end
                            end
                        elseif gateHistories == 2.0
                            % Use Nielsony's method
                            scale = preProcess.sig2ext(scale)';
                        end
                    end
                    
                    if length(scale) > 2.0
                        %{
                            If the user defined high frequency datasets, the
                            history is three datapoints and there is a leading
                            zero, suppress the warning about the load history
                            only being 3 points in length
                        %}
                        originalLength = length(scale);
                        
                        % Remove leading zeros
                        leadingZeros = 1.0;
                        while leadingZeros == 1.0
                            if scale(1.0) == 0.0
                                scale(1.0) = [];
                            else
                                leadingZeros = 0.0;
                            end
                        end
                        
                        if (originalLength > 2.0) && (length(scale) < 3.0)
                            setappdata(0, 'suppress_ID123', 1.0)
                        end
                    end
                    
                    % Scale the current load history
                    scale = scale.*loadingScale(i);
                    
                    % Offset the current load history
                    scale = scale + loadingOffset(i);
                    
                    % Store the current loading into the buffer
                    scaleBuffer{i} = scale;
                    historyLengths(i) = length(scale);
                end
                
                % Make sure each loading is the same length
                if (max(historyLengths) - min(historyLengths)) ~= 0.0
                    % Get the length of the largest load history
                    maxLength = max(historyLengths);
                    
                    % Correct the length of each load history
                    for i = 1.0:L
                        if (maxLength - length(scaleBuffer{i})) ~= 0.0
                            difference = zeros(1.0, maxLength - length(scaleBuffer{i}));
                            scaleBuffer{i} = [scaleBuffer{i}, difference];
                        end
                    end
                end
                
                %% Combine the load histories with the stress definitions
                for i = 1:L
                    if (multiple == 1.0) || (multiple == 3.0)
                        % Simple loading
                        [channel, subID, mainID, error] = preProcess.readRPT(channels{i}, items);
                    else
                        % Multiple load history
                        [channel, subID, mainID, error] = preProcess.readRPT(channels, items);
                    end
                    
                    if isempty(channel) == 1.0
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        mainID = -999.0;
                        subID = -999.0;
                        
                        error = true;
                        setappdata(0, 'error_log_015', 1.0)
                        return
                    end
                    
                    %% Make sure channel/loading files are correctly defined:
                    
                    [row, col] = size(channel);
                    skip = col - 6.0;
                    if col < 6.0
                        error = 1.0;
                        setappdata(0, 'error_log_019', 1.0)
                        
                        mainID = -999.0;
                        subID = -999.0;
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    if error == 1.0
                        mainID = -999.0;
                        subID = -999.0;
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    %% Scale channel:
                    if first_time == 1.0
                        [Lc, ~] = size(channel);
                        Ls = length(scaleBuffer{i});
                        
                        % It's possible to encounter memory problems here, if
                        % the load history is very large
                        try
                            scaled_channels = zeros(Ls, 6.0, Lc*length(channels));
                        catch unhandledException
                            error = 1.0;
                            setappdata(0, 'E045', 1.0)
                            setappdata(0, 'error_log_045_exceptionMessage', unhandledException)
                            mainID = -999.0;
                            subID = -999.0;
                            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                            return
                        end
                        
                        itemsInPreviousRow = row;
                        first_time = 0.0;
                    else
                        %% Make sure the current channel has the same number of items as the previous channel
                        if row ~= itemsInPreviousRow
                            error = 1.0;
                            setappdata(0, 'E042', 1.0)
                            mainID = -999.0;
                            subID = -999.0;
                            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                            return
                        end
                    end
                    
                    for j = 1:Lc % Loop over each node
                        for k = 1:6 % Loop over tensor components
                            scaled_channels(:, k, j1) = channel(j, k+skip)*scaleBuffer{i};
                        end
                        
                        j1 = j1 + 1.0;
                    end
                end
                
                %% Warn the user if there are any duplicate IDs in the model
                duplicateMainIDs = length(mainID) - length(unique(mainID));
                
                if duplicateMainIDs > 0.0 && getappdata(0, 'nodeType_master') == 1.0
                    setappdata(0, 'duplicateMainIDs', duplicateMainIDs)
                    messenger.writeMessage(153.0)
                end
                
                %% Make sure data position is the same for all RPT files
                dataLabel = getappdata(0, 'dataLabel');
                if (max(dataLabel) - min(dataLabel)) ~= 0.0
                    error = 1.0;
                    setappdata(0, 'E021', 1.0)
                    
                    mainID = -999.0;
                    subID = -999.0;
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    
                    return
                elseif dataLabel(1.0) == 10.0
                    setappdata(0, 'dataPosition', 1.0)
                elseif dataLabel(1.0) == 9.0
                    setappdata(0, 'dataPosition', 2.0)
                elseif dataLabel(1.0) == 8.0
                    setappdata(0, 'dataPosition', 1.0)
                elseif dataLabel(1.0) == 7.0
                    setappdata(0, 'dataPosition', 2.0)
                elseif dataLabel(1.0) == 6.0
                    if getappdata(0, 'elementType') == 0.0
                        setappdata(0, 'dataPosition', 3.0)
                    else
                        setappdata(0, 'dataPosition', 1.0)
                    end
                elseif dataLabel(1.0) == 5.0
                    setappdata(0, 'dataPosition', 2.0)
                elseif dataLabel(1.0) == 4.0
                    setappdata(0, 'dataPosition', 3.0)
                end
                
                %% Combine the scaled channels:
                a = 1.0;  b = Lc - 1.0;
                combined_channel = zeros(Ls, 6.0, Lc);
                
                for i = 1:Lc
                    for j = a:Lc:(length(channels)*Lc) - b
                        combined_channel(:,:,i) = combined_channel(:,:,i)+...
                            scaled_channels(:,:,j);
                    end
                    
                    a = a + 1.0;
                    b = b - 1.0;
                end
                
            catch unhandledException
                error = 1.0;
                setappdata(0, 'E022', 1.0)
                setappdata(0, 'error_log_022_exceptionMessage', unhandledException)
                
                mainID = -999.0;
                subID = -999.0;
                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                return
            end
            
            %% Assign the combined stresses to their individual components:
            Sxx(:,:) = combined_channel(:,1.0,:);
            Syy(:,:) = combined_channel(:,2.0,:);
            Szz(:,:) = combined_channel(:,3.0,:);
            Txy(:,:) = combined_channel(:,4.0,:);
            Txz(:,:) = combined_channel(:,5.0,:);
            Tyz(:,:) = combined_channel(:,6.0,:);
            
            Sxx = Sxx';
            Syy = Syy';
            Szz = Szz';
            Txy = Txy';
            Txz = Txz';
            Tyz = Tyz';
        end
        
        %% Read stresses from RPT file:
        function [TENSOR, subIDs, mainIDs, error] = readRPT(FILENAME, items)
            error = 0.0;
            setappdata(0, 'nodeType_master', 0.0)
            TENSOR = [];
            
            %% Open the .rpt file:
            
            fid = fopen(FILENAME, 'r');
            setappdata(0, 'FOPEN_error_file', FILENAME)
            
            if fid == -1.0
                TENSOR = [];
                mainIDs = -999.0;
                subIDs = -999.0;
                error = 1.0;
                setappdata(0, 'E026', 1.0)
                
                return
            end
            
            %% Check if there is a header:
            
            try
                cellData = textscan(fid, '%f %f %f %f %f %f %f %f %f %f');
            catch unhandledException
                mainIDs = -999.0;
                subIDs = -999.0;
                error = 1.0;
                setappdata(0, 'E027', 1.0)
                setappdata(0, 'error_log_027_exceptionMessage', unhandledException.identifier)
                
                return
            end
            
            if isempty(cellData{1.0})
                hasHeader = true; % There is a header in the file
            else
                hasHeader = false; % There might be no header in the file
            end
            
            if hasHeader == 0.0
                for i = 1.0:length(cellData)
                    if isempty(cellData{i})
                        hasHeader = true;
                        break
                    end
                end
            end
            
            %% Scan the file:
            
            if hasHeader == 1.0
                cellData_region = cell(1.0);
                region = 0.0;
                
                while feof(fid) == 0.0
                    % Begin searching the file for the first set of data
                    fgetl(fid);
                    cellData = textscan(fid, '%f %f %f %f %f %f %f %f %f %f');
                    
                    if isempty(cellData{1.0}) == 0.0
                        %{
                            A region of data has been found. Add the current
                            region to the nested cell
                        %}
                        region = region + 1.0;
                        cellData_region{region} = cellData;
                    end
                end
                
                %{
                    Concatenate individual regions into single cell if
                    necessary
                %}
                if region > 1.0
                    for region_ID = 1:10
                        %{
                            For each region in the model, concatenate
                            each nested cell
                        %}
                        region_index = 2.0;
                        
                        a = cellData_region{1.0};
                        c = a{region_ID};
                        while region_index <= region
                            a = cellData_region{region_index};
                            c = [c; a{region_ID}]; %#ok<AGROW>
                            
                            region_index = region_index + 1.0;
                        end
                        
                        %{
                            The current column of data has been concatenated
                            for every region. Move on to the next column
                        %}
                        cellData{region_ID} = c;
                    end
                end
            end
            
            %{
                If the REGION variable is undefined, it could be because
                multiple data blocks were specified in the RPT file without
                text headers. Assume a single region in the model
            %}
            if exist('region', 'var') == 0.0
                region = 1.0;
            end
            
            %% Remove unused columns if necessary:
            
            % Initialize the dataset buffers
            fieldDataBuffer = cell(1.0, region);
            mainIDBuffer = cell(1.0, region);
            subIDBuffer = cell(1.0, region);
            
            if region < 2.0
                region = 1.0;
                cellData_region_i = cellData;
            end
            
            % Print the number of regions in the message file
            setappdata(0, 'numberOfRegions', region)
            messenger.writeMessage(17.0)
            
            % Buffer for total number of analysis items in the model
            R = 0.0;
            
            for i = 1:region
                remove = 0.0;
                
                % Get the cell data for the current region
                if region > 1.0
                    cellData_region_i = cellData_region{i};
                end
                
                % Plane stress, shell section data, one position label column
                if length(cellData_region_i{10.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{10.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 1.0;
                elseif isnan(cellData_region_i{10.0}) == 1.0
                    cellData_region_i{10.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 1.0;
                end
                
                % 3D stress, two position label columns
                if length(cellData_region_i{9.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{9.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 2.0;
                elseif isnan(cellData_region_i{9.0}) == 1.0
                    cellData_region_i{9.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 2.0;
                end
                
                % 3D stress, one position label column
                if length(cellData_region_i{8.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{8.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 3.0;
                elseif isnan(cellData_region_i{8.0}) == 1.0
                    cellData_region_i{8.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 3.0;
                end
                
                % 3D stress, no position label columns
                % OR
                % Plane stress, two position label columns
                if length(cellData_region_i{7.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{7.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 4.0;
                elseif isnan(cellData_region_i{7.0}) == 1.0
                    cellData_region_i{7.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 4.0;
                end
                
                % Plane stress, one position label column
                if length(cellData_region_i{6.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{6.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 5.0;
                elseif isnan(cellData_region_i{6.0}) == 1.0
                    cellData_region_i{6.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 5.0;
                end
                
                % Plane stress, no position label columns
                if length(cellData_region_i{5.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{5.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 6.0;
                elseif isnan(cellData_region_i{5.0}) == 1.0
                    cellData_region_i{5.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 6.0;
                end
                
                % 1D stress, two position label columns
                if length(cellData_region_i{4.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{4.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 7.0;
                elseif isnan(cellData_region_i{4.0}) == 1.0
                    cellData_region_i{4.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 7.0;
                end
                
                % 1D stress, one position label column
                if length(cellData_region_i{3.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{3.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 8.0;
                elseif isnan(cellData_region_i{3.0}) == 1.0
                    cellData_region_i{3.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 8.0;
                end
                
                % 1D stress, no position label columns
                if length(cellData_region_i{2.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{2.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 9.0;
                elseif isnan(cellData_region_i{2.0}) == 1.0
                    cellData_region_i{2.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 9.0;
                end
                
                %% Check for concatenation errors:
                
                try
                    fieldData_i = cell2mat(cellData_region_i);
                catch unhandledException
                    subIDs = -999.0;
                    mainIDs = -999.0;
                    error = 1.0;
                    setappdata(0, 'E028', 1.0)
                    setappdata(0, 'error_log_028_exceptionMessage', unhandledException.identifier)
                    
                    return
                end
                
                if isempty(fieldData_i) == 1.0
                    subIDs = -999.0;
                    mainIDs = -999.0;
                    error = 1.0;
                    setappdata(0, 'E029', 1.0)
                    
                    return
                elseif (any(any(isnan(fieldData_i))) == 1.0) || (any(any(isinf(fieldData_i))) == 1.0)
                    subIDs = -999.0;
                    mainIDs = -999.0;
                    error = 1.0;
                    setappdata(0, 'E030', 1.0)
                    
                    return
                end
                
                if remove == 9.0
                    fieldData_i(:, 2:10) = [];
                elseif remove == 8.0
                    fieldData_i(:, 3:10) = [];
                elseif remove == 7.0
                    fieldData_i(:, 4:10) = [];
                elseif remove == 6.0
                    fieldData_i(:, 5:10) = [];
                elseif remove == 5.0
                    fieldData_i(:, 6:10) = [];
                elseif remove == 4.0
                    fieldData_i(:, 7:10) = [];
                elseif remove == 3.0
                    fieldData_i(:, 8:10) = [];
                elseif remove == 2.0
                    fieldData_i(:, 9:10) = [];
                elseif remove == 1.0
                    fieldData_i(:, 10) = [];
                end
                
                %% Interpret columns:
                
                %{
                    NODETYPE: Format of nodal information
                    0: No listing. Take item label from row number
                    1: Centroidal or unique nodal
                    2: Element-nodal or integration point
                    -1: Error
                %}
                
                % Get the element type
                elementType = getappdata(0, 'elementType');
                if isempty(elementType) == 1.0
                    elementType = 0.0;
                elseif isnumeric(elementType) == 0.0
                    elementType = 0.0;
                elseif (isnan(elementType) == 1.0) || (isreal(elementType) == 0.0) || ...
                        (isinf(elementType) == 1.0) || (isreal(elementType) == 0.0)
                    elementType = 0.0;
                end
                
                [Ri, C] = size(fieldData_i);
                switch C
                    case 10.0 % Plane stress with shell face data; element-nodal or integration point
                        nodeType = 2.0;
                        mainIDs_i = fieldData_i(:, 1.0);
                        subIDs_i = fieldData_i(:, 2.0);
                        
                        if getappdata(0, 'shellLocation') == 1.0
                            fieldData_i(:, 4:2:10) = [];
                        elseif getappdata(0, 'shellLocation') == 2.0
                            fieldData_i(:, 3:2:9) = [];
                        end
                        
                        fieldData_i(:, 7:8) = 0.0;
                    case 9.0 % Plane stress with shell face data; unique nodal or centroid
                        nodeType = 1.0;
                        mainIDs_i = fieldData_i(:, 1.0);
                        subIDs_i = linspace(1.0, 1.0, Ri)';
                        
                        if getappdata(0, 'shellLocation') == 1.0
                            fieldData_i(:, 3:2:9) = [];
                        elseif getappdata(0, 'shellLocation') == 2.0
                            fieldData_i(:, 2:2:8) = [];
                        end
                        
                        fieldData_i(:, 6:7) = 0.0;
                    case 8.0 % 3D stress; element-nodal or integration point
                        nodeType = 2.0;
                        mainIDs_i = fieldData_i(:, 1.0);
                        subIDs_i = fieldData_i(:, 2.0);
                    case 7.0 % 3D stress; unique-nodal or centroid
                        nodeType = 1.0;
                        subIDs_i = linspace(1.0, 1.0, Ri)';
                        mainIDs_i = fieldData_i(:, 1.0);
                    case 6.0
                        if elementType == 0.0 % 3D stress; unknown
                            nodeType = 0.0;
                            subIDs_i = linspace(1.0, 1.0, Ri)';
                            mainIDs_i = linspace(1.0, Ri, Ri)';
                        else % Plane stress; element-nodal or integration point
                            nodeType = 2.0;
                            mainIDs_i = fieldData_i(:, 1.0);
                            subIDs_i = fieldData_i(:, 2.0);
                            
                            fieldData_i(:, 7:8) = 0.0;
                        end
                        
                        setappdata(0, 'message_181_elementType', elementType)
                        messenger.writeMessage(181.0)
                    case 5.0 % Plane stress; unique-nodal or centroid
                        nodeType = 1.0;
                        subIDs_i = linspace(1.0, 1.0, Ri)';
                        mainIDs_i = fieldData_i(:, 1.0);
                        
                        fieldData_i(:, 6:7) = 0.0;
                    case 4.0
                        if elementType == 0.0 % 2D stress; element-nodal or integration point
                            nodeType = 2.0;
                            subIDs_i = fieldData_i(:, 2.0);
                            mainIDs_i = fieldData_i(:, 1.0);
                            
                            fieldData_i(:, 5:8) = 0.0;
                        else % Plane stress; unknown
                            nodeType = 0.0;
                            subIDs_i = linspace(1.0, 1.0, Ri)';
                            mainIDs_i = linspace(1.0, Ri, Ri)';
                            
                            fieldData_i(:, 5:6) = 0.0;
                        end
                    case 3.0
                        if elementType == 0.0 % 1D stress; element-nodal or integration point
                            nodeType = 2.0;
                            mainIDs_i = fieldData_i(:, 1.0);
                            subIDs_i = fieldData_i(:, 2.0);
                            
                            fieldData_i(:, 4:8) = 0.0;
                        else % 2D stress; unique-nodal or centroid
                            nodeType = 1.0;
                            mainIDs_i = fieldData_i(:, 1.0);
                            subIDs_i = linspace(1.0, 1.0, Ri)';
                            
                            fieldData_i(:, 4:7) = 0.0;
                        end
                    case 2.0
                        if elementType == 0.0 % 1D stress; unique-nodal or centroid
                            nodeType = 1.0;
                            mainIDs_i = fieldData_i(:, 1.0);
                            subIDs_i = linspace(1.0, 1.0, Ri)';
                            
                            fieldData_i(:, 3:7) = 0.0;
                        else % 2D stress; unknown
                            nodeType = 0.0;
                            mainIDs_i = linspace(1.0, 1.0, Ri)';
                            subIDs_i = linspace(1.0, 1.0, Ri)';
                            
                            fieldData_i(:, 3:6) = 0.0;
                        end
                    case 1.0 % 1D stress; unknown
                        nodeType = 0.0;
                        mainIDs_i = linspace(1.0, 1.0, Ri)';
                        subIDs_i = linspace(1.0, 1.0, Ri)';
                        
                        fieldData_i(:, 2:6) = 0.0;
                    otherwise
                        subIDs = -999.0;
                        mainIDs = -999.0;
                        error = 1.0;
                        setappdata(0, 'E031', 1.0)
                        
                        return
                end
                
                % Append the data from the current group to the buffers
                fieldDataBuffer{i} = fieldData_i;
                mainIDBuffer{i} = mainIDs_i;
                subIDBuffer{i} = subIDs_i;
                
                % Compare the current node type to the previous node type
                if i > 1.0
                    if nodeType ~= previousNodeType
                        %{
                            The data position must be the same for each
                            region in the model
                        %}
                        subIDs = -999.0;
                        mainIDs = -999.0;
                        error = 1.0;
                        setappdata(0, 'E113', 1.0)
                        
                        return
                    end
                end
                
                % Record the previous node type
                previousNodeType = nodeType;
                
                % Add the number of items in the region to the total
                R = R + Ri;
            end
            
            setappdata(0, 'dataLabel', [getappdata(0, 'dataLabel'), C])
            
            %% Concatenate data buffers
            fieldData = cell2mat(fieldDataBuffer');
            mainIDs = cell2mat(mainIDBuffer');
            subIDs = cell2mat(subIDBuffer');
            
            %% Save TENSOR to the appdata in case of group handling
            if nodeType == 0.0
                setappdata(0, 'fieldData_master', fieldData)
                
                X = 1.0;
            elseif nodeType == 1.0
                setappdata(0, 'fieldData_master', fieldData(:, 2:end))
                
                X = 2.0;
            else
                setappdata(0, 'fieldData_master', fieldData(:, 3:end))
                
                X = 3.0;
            end
            setappdata(0, 'nodeType_master', nodeType)
            
            %% Filter IDs if user specified individual analysis items
            [items, error, mainIDs, subIDs, readUserItems] = preProcess.readItemsFile(items, R, mainIDs, subIDs, error);
            
            if error == 1.0
                return
            elseif readUserItems == 1.0
                messenger.writeMessage(266.0)
            end
            
            %% Get tensor components:
            if (isempty(items) == 0.0) && (error == 0.0)
                Sxx = fieldData(items, X)';
                Syy = fieldData(items, X + 1.0)';
                Szz = fieldData(items, X + 2.0)';
                Txy = fieldData(items, X + 3.0)';
                Txz = fieldData(items, X + 4.0)';
                Tyz = fieldData(items, X + 5.0)';
            else
                Sxx = fieldData(:, X)';
                Syy = fieldData(:, (X + 1.0))';
                Szz = fieldData(:, (X + 2.0))';
                Txy = fieldData(:, (X + 3.0))';
                Txz = fieldData(:, (X + 4.0))';
                Tyz = fieldData(:, (X + 5.0))';
            end
            
            TENSOR = [Sxx; Syy; Szz; Txy; Txz; Tyz]';
            
            % Warn the user if the tensor is empty
            if all(all(TENSOR == 0.0)) == 1.0
                messenger.writeMessage(121.0)
            end
            
            fclose(fid);
            
            %% For element-nodal or integration point data, check how many items exist in the loading
            if nodeType == 2.0
                numberOfItems = length(fieldData(:, 1.0));
                
                if (numberOfItems == 1.0) && (length(items) ~= 1.0)
                    messenger.writeMessage(16.0)
                end
            end
        end
        
        %% Combine a sequence of stress datasets
        function [error, mainID, subID, Sxx, Syy, Szz, Txy, Tyz, Txz] = datasetSequence(channels, items, elementType, loadingScale, loadingOffset)
            %% Assume that a dataset sequence has been defined
            error = 0.0;
            
            % Get the composite criteria flag
            compositeCriteria = getappdata(0, 'compositeCriteria');
            
            % Get the sequence length
            if (ischar(channels) == 1.0) && (compositeCriteria == 1.0)
                L = 2.0;
            else
                L = length(channels);
            end
            
            first_time = 1.0;
            
            % Verify the loading scale factors
            nScaleFactors = length(loadingScale);
            
            if L == nScaleFactors
                % Dataset/history pairs equal to number of loading scale factors
            elseif L > nScaleFactors
                if ((compositeCriteria == 1.0) && (ischar(channels) == 1.0) && (L > 2.0)) || ((compositeCriteria == 0.0) && (L > nScaleFactors))
                    messenger.writeMessage(281.0)
                end
                
                % Dataset/history pairs greater than number of loading scale factors
                extraScaleFactors = linspace(loadingScale(end), loadingScale(end), (L - nScaleFactors));
                loadingScale = [loadingScale extraScaleFactors];
            elseif L < nScaleFactors
                messenger.writeMessage(281.0)
                
                % Dataset/history pairs less than number of loading scale factors
                scaleFactorsToDelete = nScaleFactors - L;
                loadingScale(end - (scaleFactorsToDelete - 1.0) : end) = [];
            end
            
            % Check if the user specified load offset values. These are not
            % supported for dataset sequence analyses
            if isempty(loadingOffset) == 0.0
                if all(loadingOffset == 0.0) == 0.0
                    messenger.writeMessage(5.0)
                end
            end
            
            % Begin reading datasets
            if compositeCriteria == 1.0
                if ischar(channels) == 1.0
                    channels = {channels, channels};
                elseif length(channels) == 1.0
                    channels = [channels(1.0), channels(1.0)];
                end
            else
                if ischar(channels) == 1.0
                    if isempty(channels) == 1.0
                        setappdata(0, 'E023', 1.0)
                    else
                        setappdata(0, 'E024', 1.0)
                    end
                    
                    error = true;
                    mainID = -999;
                    subID = -999;
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    return
                elseif length(channels) == 1.0
                    setappdata(0, 'E024', 1.0)
                    
                    error = true;
                    mainID = -999.0;
                    subID = -999.0;
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    return
                end
            end
            
            try
                % Make sure data label warning can only be displayed once
                setappdata(0, 'dataLabel', [])
                
                for i = 1:L
                    [channel, subID, mainID, error] = preProcess.readRPT(channels{i}, items);
                    
                    % Scale the channel
                    channel = channel.*loadingScale(i);
                    
                    if isempty(channel) == 1.0
                        error = true;
                        setappdata(0, 'E015', 1.0)
                        
                        mainID = -999;
                        subID = -999;
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    [~, col] = size(channel);
                    if col < 6.0
                        error = true;
                        setappdata(0, 'E019', 1.0)
                        
                        mainID = -999;
                        subID = -999;
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    %% Concatenate the datasets into a sequence
                    if first_time == 1.0
                        [Lc, ~] = size(channel);
                        channelSequence = zeros(Lc, 6, L);
                        first_time = 0.0;
                    end
                    
                    channelSequence(:, :, i) = channel;
                end
                
                %% Make sure data position is the same for all RPT files
                dataLabel = getappdata(0, 'dataLabel');
                if (max(dataLabel) - min(dataLabel)) ~= 0.0
                    error = true;
                    setappdata(0, 'E021', 1.0)
                    
                    mainID = -999;
                    subID = -999;
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    
                    return
                elseif dataLabel(1.0) == 10.0
                    setappdata(0, 'dataPosition', 1.0)
                elseif dataLabel(1.0) == 9.0
                    setappdata(0, 'dataPosition', 2.0)
                elseif dataLabel(1.0) == 8.0
                    setappdata(0, 'dataPosition', 1.0)
                elseif dataLabel(1.0) == 7.0
                    setappdata(0, 'dataPosition', 2.0)
                elseif dataLabel(1.0) == 6.0
                    if elementType == 0.0
                        setappdata(0, 'dataPosition', 3.0)
                    else
                        setappdata(0, 'dataPosition', 4.0)
                    end
                end
            catch unhandledException
                error = true;
                setappdata(0, 'E022', 1.0)
                setappdata(0, 'error_log_022_exceptionMessage', unhandledException.identifier)
                
                mainID = -999;
                subID = -999;
                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                return
            end
            
            %% Get tensor components
            Sxx(:,:) = channelSequence(:, 1.0, :);
            Syy(:,:) = channelSequence(:, 2.0, :);
            Szz(:,:) = channelSequence(:, 3.0, :);
            Txy(:,:) = channelSequence(:, 4.0, :);
            Txz(:,:) = channelSequence(:, 5.0, :);
            Tyz(:,:) = channelSequence(:, 6.0, :);
            
            if Lc == 1.0
                Sxx = Sxx';
                Syy = Syy';
                Szz = Szz';
                Txy = Txy';
                Txz = Txz';
                Tyz = Tyz';
            end
            
            return
        end
        
        %% Interpolate SN data to get R = -1 curve if necessary
        function [] = snInterpolate(msCorrection)
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            for groups = 1:G
                % Re-enable warning messages for the current group
                setappdata(0, 'suppress_ID26', 0.0)
                setappdata(0, 'suppress_ID78', 0.0)
                
                % Switch to the current set of group properties
                group.switchProperties(groups, groupIDBuffer);
                
                if getappdata(0, 'nSNDatasets') > 1.0
                    % Store the current group number
                    setappdata(0, 'message_groupNumber', groups)
                    
                    % Store the current material
                    setappdata(0, 'message_currentMaterial', groupIDBuffer(groups).material)
                    
                    % Get the list of R-values
                    rValues = getappdata(0, 'r_values');
                    sets = length(rValues);
                    S = getappdata(0, 's_values');
                    
                    % If there is an SN curve for R = -1.0, just use this curve
                    rMinus1Pos = find(rValues == -1.0);
                    
                    if isempty(rMinus1Pos) == 0.0
                        % The SN data is defined explicitly for an R = -1.0 load
                        % ratio
                        if msCorrection ~= 7.0
                            rMinus1Pos = rMinus1Pos(1.0);
                            setappdata(0, 's_values', S(rMinus1Pos, :))
                            setappdata(0, 'nSNDatasets', 1.0)
                        end
                        
                        Si = S(rMinus1Pos, :);
                        
                        % Make sure the S-values are monotonically decreasing and
                        % always positive
                        s_zero = 0.1;
                        for i = 1:length(Si)-1.0
                            if Si(i) <= Si(i + 1.0)
                                if Si(i) < Si(i + 1.0)
                                    %{
                                        Warn the user that the interpolated
                                        S-values are not monotonically
                                        decreasing
                                    %}
                                    messenger.writeMessage(78.0)
                                end
                                Si(i) = Si(i + 1.0) + 1e-6;
                            end
                            
                            % If the current value of Si is negative, make it very
                            % close to zero
                            if Si(i) <= 0.0
                                Si(i) = s_zero;
                                s_zero = s_zero - 0.0001;
                                
                                % Warn the user that some interpolated S-values are
                                % negative
                                messenger.writeMessage(26.0)
                            end
                        end
                        
                        setappdata(0, 's_values_reduced', Si)
                    else
                        % The SN data is not defined explicitly for an R = -1.0
                        % load ratio. Interpolate to approximate the curve
                        
                        % Find which curves (if any) the R = -1 curve lies between
                        found = 0.0;
                        for i = 1:sets-1.0
                            if rValues(i) < -1.0 && rValues(i + 1.0) > -1.0
                                highR = rValues(i + 1.0);
                                highRi = (i + 1.0);
                                
                                lowR = rValues(i);
                                lowRi = i;
                                
                                found = 1.0;
                                break
                            elseif rValues(i) > -1.0 && rValues(i + 1.0) < -1.0
                                lowR = rValues(i + 1.0);
                                lowRi = (i + 1.0);
                                
                                highR = rValues(i);
                                highRi = i;
                                
                                found = 1.0;
                                break
                            end
                        end
                        
                        if found == 0.0
                            % The R = -1.0 curve lies outside the range of SN data.
                            % Extrapolate linearly to approximate the curve and
                            % warn the user that the SN data may be inaccurate
                            if msCorrection ~= 7.0
                                messenger.writeMessage(76.0)
                            end
                            
                            % Find on which side of the SN data the R = -1.0 curve lies
                            if max(rValues) < -1.0
                                highR = max(rValues);
                                highRi = find(rValues == max(rValues));
                                
                                rValues2 = rValues;
                                pos = rValues2 == max(rValues2);
                                rValues2(pos) = [];
                                lowR = max(rValues2);
                                lowRi = find(rValues == lowR);
                            else
                                lowR = min(rValues);
                                lowRi = find(rValues == min(rValues));
                                
                                rValues2 = rValues;
                                pos = rValues2 == min(rValues2);
                                rValues2(pos) = [];
                                highR = min(rValues2);
                                highRi = find(rValues == highR);
                            end
                        end
                        
                        nData = length(S(1.0, :));
                        newS = zeros(1.0, nData);
                        
                        % For each SN datapoint, interpolate to find the SN
                        % datapoint at R = -1.0
                        s_zero = 0.1;
                        for i = 1:nData
                            if S(lowRi, i) > S(highRi, i)
                                S2 = S(lowRi, i);
                                S1 = S(highRi, i);
                            else
                                S2 = S(highRi, i);
                                S1 = S(lowRi, i);
                            end
                            
                            newS(i) = S2 - (((S2 - S1)/(highR - lowR))*(-1.0 - lowR));
                            
                            % If current value of newS is greater than
                            % the previous value, make them almost the same
                            if (i > 1.0) && (newS(i) >= newS(i - 1.0))
                                if newS(i) > newS(i - 1.0)
                                    % Warn the user that the interpolated S-values are
                                    % not monotonically decreasing
                                    messenger.writeMessage(78.0)
                                end
                                newS(i) = newS(i - 1.0) - 1e-6;
                            end
                            
                            % If the current value of newS is negative, make it very
                            % close to zero
                            if newS(i) <= 0.0
                                newS(i) = s_zero;
                                s_zero = s_zero - 0.0001;
                                
                                % Warn the user that some interpolated S-values are
                                % negative
                                messenger.writeMessage(26.0)
                            end
                        end
                        
                        % Replace the S data with the new R = -1.0 dataset
                        if msCorrection ~= 7.0
                            setappdata(0, 's_values', newS)
                            setappdata(0, 'nSNDatasets', 1.0)
                        else
                            setappdata(0, 's_values_reduced', newS)
                        end
                    end
                    
                    % Save the S-N definitions for the current group
                    group.saveMaterial(groups)
                end
            end
        end
        
        %% Determine the stress concentration factor (Kt) for the analysis
        function [] = kt(ktDef, ktCurve, uts)
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            %{
                There is a potential complication here. The option KT_DEF
                can refer to a combination of surface finish definition
                files and numerical Kt values. Therefore, the length of
                KT_DEF and KT_CURVE are not necessarily the same. Define a
                counter which keeps track of whether the current KT_DEF is
                a .kt/.ktx file, and if so, locate the next logical value
                in KT_CURVE
            %}
            % If KT_CURVE was defined as a cell, convert to a matrix
            if iscell(ktCurve) == 1.0
                ktCurve = cell2mat(ktCurve);
            end
            
            % Check how many values of KT_DEF are numeric
            if (ischar(ktDef) == 0.0) && (isnumeric(ktDef) == 0.0)
                numberOfCharKts = 0.0;
                
                for i = 1:length(ktDef)
                    if ischar(ktDef{i}) == 1.0
                        numberOfCharKts = numberOfCharKts + 1.0;
                    end
                end
                
                %{
                    If the number of Kt files differs from the number of
                    KT_CURVE definitions, warn the user
                %}
                if ischar(ktCurve) == 0.0
                    numberOfKtCurves = length(ktCurve);
                else
                    numberOfKtCurves = 1.0;
                end
                
                if numberOfCharKts ~= numberOfKtCurves
                    ktCurve = linspace(ktCurve(1.0), ktCurve(1.0), numberOfCharKts);
                    setappdata(0, 'warning_107_numberOfKtFiles', numberOfCharKts)
                    setappdata(0, 'warning_107_numberOfKtCurves', numberOfKtCurves)
                    messenger.writeMessage(107.0)
                end
            else
                if isempty(ktCurve) == 0.0
                    setappdata(0, 'warning_108_numberOfKtCurves', length(ktCurve))
                    ktCurve = ktCurve(1.0);
                    
                    if (ischar(ktDef) == 1.0) && (length(ktCurve) > 1.0)
                        messenger.writeMessage(108.0)
                    elseif ischar(ktDef) == 0.0
                        messenger.writeMessage(109.0)
                    end
                end
            end
            
            % Commit the notch settings to the group materials
            group_materialProps = getappdata(0, 'group_materialProps');
            notchFactors = getappdata(0, 'notchSensitivityConstant');
            notchRadii = getappdata(0, 'notchRootRadius');
            for groups = 1:G
                group_materialProps(groups).notchSensitivityConstant = notchFactors(groups);
                group_materialProps(groups).notchRootRadius = notchRadii(groups);
            end
            setappdata(0, 'group_materialProps', group_materialProps)
            
            curveIndex = 0.0;
            
            % Assign the surface finish for each group
            for groups = 1:G
                % Get the surface finish definition for the current group
                if G > 1.0
                    % Assign material properties for the current group
                    [~, ~] = group.switchProperties(groups, groupIDBuffer(groups));
                    uts = getappdata(0, 'uts');
                    ktDef = groupIDBuffer(groups).kt;
                    if (ischar(ktDef) == 0.0) && (isnumeric(ktDef) == 0.0)
                        ktDef = cell2mat(ktDef);
                    end
                    
                    % Store the current material
                    setappdata(0, 'message_material', groupIDBuffer(groups).material)
                else
                    % Store the current material
                    setappdata(0, 'message_material', getappdata(0, 'material'))
                end
                
                % Store the current group number
                setappdata(0, 'message_groupNumber', groups)
                
                % Store the current Kt file
                setappdata(0, 'message_ktFile', ktDef)
                
                %% Is Kt defined as a value or a surface definition file?
                if isnumeric(ktDef)
                    setappdata(0, 'ktFileType', 0.0)
                    
                    if isempty(ktDef) == 1.0
                        setappdata(0, 'kt', 1.0)
                    elseif isnan(ktDef) || isinf(ktDef) || isempty(ktDef)
                        setappdata(0, 'kt', 1.0)
                        messenger.writeMessage(39.0)
                    elseif ktDef < 1.0
                        setappdata(0, 'kt', 1.0)
                        messenger.writeMessage(39.0)
                    else
                        setappdata(0, 'kt', ktDef)
                    end
                else % ktDef is not numeric, so try to open the surface finish definition file
                    
                    % If Kt data is defined as .kt file
                    [~, ~, EXT] = fileparts(ktDef);
                    
                    if isempty(uts) == 1.0
                        %{
                            The UTS is not defined for this material. Use a
                            default Kt value of 1.0
                        %}
                        if strcmpi(EXT, '.kt') == 1.0
                            setappdata(0, 'ktFileType', 1.0)
                        elseif strcmpi(EXT, '.ktx') == 1.0
                            setappdata(0, 'ktFileType', 2.0)
                        end
                        
                        setappdata(0, 'kt', 1.0)
                        messenger.writeMessage(126.0)
                    elseif ischar(ktDef)
                        % Update the curve index
                        curveIndex = curveIndex + 1.0;
                        
                        try
                            % Open the .kt/.ktx file
                            ktData = dlmread(ktDef);
                        catch unhandledException
                            setappdata(0, 'kt', 1.0)
                            setappdata(0, 'ktCurve', -1.0)
                            setappdata(0, 'warning_028_exceptionMessage', unhandledException.identifier)
                            messenger.writeMessage(40.0)
                            
                            % Save the Kt definitions for the current group
                            group.saveMaterial(groups)
                            
                            continue
                        end
                        
                        % Get the current value of KT_CURVE
                        ktCurve_i = ktCurve(curveIndex);
                        
                        % Check the validity of ktCurve
                        if isempty(ktCurve_i) == 1.0
                            ktCurve_i = 1.0;
                        elseif isnan(ktCurve_i) || isinf(ktCurve_i) || isempty(ktCurve_i)
                            ktCurve_i = 1.0;
                        end
                        
                        setappdata(0, 'ktCurve', ktCurve_i)
                        
                        if strcmpi(EXT, '.kt') == 1.0
                            setappdata(0, 'ktFileType', 1.0)
                            
                            x = ktData(:, 1.0);
                            
                            try
                                y = ktData(:, ktCurve_i + 1.0);
                                %{
                                    If the UTS exceeds the range of UTS
                                    values, take the last Kt value
                                %}
                                if uts > x(end)
                                    setappdata(0, 'kt', y(end))
                                    messenger.writeMessage(42.0)
                                else
                                    setappdata(0, 'kt', interp1(x, y, uts))
                                end
                            catch unhandledException
                                setappdata(0, 'kt', 1.0)
                                setappdata(0, 'warning_030_exceptionMessage', unhandledException.identifier)
                                messenger.writeMessage(43.0)
                            end
                        elseif strcmpi(EXT, '.ktx') == 1.0
                            setappdata(0, 'ktFileType', 2.0)
                            
                            x = ktData(2.0:end, 1.0);
                            
                            % Get Rz values
                            Rz = ktData(1.0, 1.0:end - 1.0);
                            
                            %{
                                If the user Rz value is not in range, take
                                the end Kt values
                            %}
                            if ktCurve_i < Rz(1.0)
                                setappdata(0, 'kt', 1.0)
                                messenger.writeMessage(178.0)
                            elseif ktCurve_i > Rz(end)
                                setappdata(0, 'message_rzValue', ktCurve_i)
                                messenger.writeMessage(41.0)
                                
                                y = ktData(2.0:end, end);
                                
                                %{
                                    If the UTS exceeds the range of UTS
                                    values, take the last Kt value
                                %}
                                if uts > x(end)
                                    setappdata(0, 'kt', y(end))
                                    messenger.writeMessage(42.0)
                                else
                                    setappdata(0, 'kt', interp1(x, y, uts))
                                end
                            elseif isempty(find(Rz == ktCurve_i, 1.0)) == 0.0
                                %{
                                    The user Rz value is an exact match so
                                    there is no need to interpolate
                                %}
                                
                                y = ktData(2.0:end, 1.0 + find(Rz == ktCurve_i, 1.0));
                                
                                %{
                                    If the UTS exceeds the range of UTS
                                    values, take the last Kt value
                                %}
                                if uts > x(end)
                                    setappdata(0, 'kt', y(end))
                                    messenger.writeMessage(42.0)
                                else
                                    setappdata(0, 'kt', interp1(x, y, uts))
                                end
                            else
                                %{
                                    Interpolate to find the Kt data
                                    corresponding to the user Rz value
                                %}
                                for i = 1:length(Rz) - 1.0
                                    if ktCurve_i > Rz(i) && ktCurve_i < Rz(i + 1.0)
                                        Rz_lo = Rz(i);
                                        Rz_lo_i = i;
                                        
                                        Rz_hi = Rz(i + 1.0);
                                        Rz_hi_i = i + 1.0;
                                        break
                                    end
                                end
                                
                                y = zeros(1, length(x));
                                KtGrid = ktData(2.0:end, 2.0:end);
                                
                                for i = 1:length(x)
                                    if KtGrid(i, Rz_lo_i) > KtGrid(i, Rz_hi_i)
                                        Kt2 = KtGrid(Rz_lo_i, i);
                                        Kt1 = KtGrid(Rz_hi_i, i);
                                    else
                                        Kt2 = KtGrid(i, Rz_hi_i);
                                        Kt1 = KtGrid(i, Rz_lo_i);
                                    end
                                    
                                    y(i) = Kt2 - (((Kt2 - Kt1)/(Rz_hi - Rz_lo))*(ktCurve_i - Rz_lo));
                                end
                                
                                %{
                                    If the UTS exceeds the range of UTS
                                    values, take the last Kt value
                                %}
                                if uts > x(end)
                                    setappdata(0, 'kt', y(end))
                                    messenger.writeMessage(42.0)
                                else
                                    setappdata(0, 'kt', interp1(x, y, uts))
                                end
                            end
                        else
                            setappdata(0, 'kt', 1.0)
                            return
                        end
                    else
                        setappdata(0, 'kt', 1.0)
                    end
                end
                
                % Save the Kt definitions for the current group
                group.saveMaterial(groups)
            end
        end
        
        %% Get load proportionality
        function [proportionalItems] = getLoadProportionality(Sxx, Syy, Sxy, N, proportionalItems, tolerance)
            
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            if G == 1.0
                groupIDBuffer = -1.0;
            else
                % Get the group ID buffer
                groupIDBuffer = getappdata(0, 'groupIDBuffer');
            end
            
            %{
                Set a counter which runs from 1 to the total number of
                analysis items
            %}
            totalCounter = 0.0;
            
            for groups = 1:G
                if G > 1.0
                    % Assign group parameters to the current set of analysis IDs
                    [N, groupIDs] = group.switchProperties(groups, groupIDBuffer(groups));
                else
                    % There is one, default group
                    groupIDs = linspace(1.0, N, N);
                end
                
                % Update the counter
                totalCounter = totalCounter + 1.0;
                
                % Calculate the angle between the first and second principal stress
                theta = 0.5.*atand((2.0.*Sxy(groupIDs, :))./(Sxx(groupIDs, :) - Syy(groupIDs, :)));
                
                theta_difference = max(theta, [], 2.0) - min(theta, [], 2.0);
                maxDifference = max(theta_difference, [], 2.0);
                
                proportionalItems(totalCounter:(totalCounter + N) - 1.0) = maxDifference < tolerance;
            end
            
            % If necessary, inform the user that load proportionality was detected
            if any(proportionalItems) == 1.0
                messenger.writeMessage(32.0)
            end
        end
        
        %% Get the principal stress history for the loading
        function [] = getPrincipalStress(N, Sxx, Syy, Szz, Txy, Tyz, Txz, algorithm, isFosIteration)
            %{
                If a fatigue loading file exists and a recall analysis is
                specified, load the previous invariants instead.
            %}
            if isappdata(0, 'fldData') == 1.0
                % Get the fatigue definition from the %APPDATA%
                fatigueDefinition = getappdata(0, 'fldData');
                
                invariants = fatigueDefinition.invariants;
                
                setappdata(0, 'S1', invariants.S1)
                setappdata(0, 'S2', invariants.S2)
                setappdata(0, 'S3', invariants.S3)
                setappdata(0, 'stressInvariantParameter', invariants.SIP)
                
                % Delete the fatigue definition data from the workspace
                clear('fatigueDefinition')
                clear('invariants')
                
                return
            end
            
            % Get the number of groups for the analysis
            if isFosIteration == 1.0
                G = 1.0;
            else
                G = getappdata(0, 'numberOfGroups');
            end
            
            % Get the Eigensolver
            eigenSolver = getappdata(0, 'eigensolver');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            % Get the IDs
            mainID = getappdata(0, 'mainID_original');
            subID = getappdata(0, 'subID_original');
            
            % Get the stress invariant parameter type
            stressInvParam = getappdata(0, 'stressInvariantParameter');
            groupAlpha = cell(1.0, G);
            previousN = 0.0;
            
            [~, L] = size(Sxx);
            
            s1 = zeros(N, L);
            s2 = s1;
            s3 = s1;
            
            totalCounter = 0.0;
            
            % Test REPMAT()
            if eigenSolver == 2.0
                try
                    repmat(eye([3.0, 3.0]), 1.0, 1.0, 2.0);
                catch
                    setappdata(0, 'eigensolver', 1.0)
                    eigenSolver = 1.0;
                end
            end
            
            for groups = 1:G
                if (strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0) || (isFosIteration == 1.0)
                    % There is one, default group
                    groupIDs = linspace(1.0, N, N);
                else
                    % Assign group parameters to the current set of analysis IDs
                    [N, groupIDs] = group.switchProperties(groups, groupIDBuffer(groups));
                end
                
                if eigenSolver == 1.0
                    %% OLD METHOD
                    for i = 1:N
                        totalCounter = totalCounter + 1.0;
                        groupItem = groupIDs(i);
                        
                        for j = 1:L
                            S = [Sxx(groupItem, j), Txy(groupItem, j), Txz(groupItem, j); Txy(groupItem, j), Syy(groupItem, j), Tyz(groupItem, j); Txz(groupItem, j), Tyz(groupItem, j), Szz(groupItem, j)];
                            eigenvalues = eig(S);
                            s1(totalCounter, j) = max(eigenvalues);
                            s2(totalCounter, j) = median(eigenvalues);
                            s3(totalCounter, j) = min(eigenvalues);
                        end
                    end
                else
                    %% NEW METHOD
                    for i = 1.0:N
                        totalCounter = totalCounter + 1.0;
                        groupItem = groupIDs(i);
                        %%
                        
                        %{
                            Construct a 3x3xL multidimensional array of the
                            stress tensor history, where L is the history
                            length
                        %}
                        % Direct stress components
                        normals = [Sxx(groupItem, :); Syy(groupItem, :); Szz(groupItem, :)]';
                        
                        % Shear stress components
                        shears = [Txy(groupItem, :); Txz(groupItem, :); Tyz(groupItem, :)]';
                        
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
                        s1(totalCounter, :) = max(real(eigenvalues));
                        s2(totalCounter, :) = median(real(eigenvalues));
                        s3(totalCounter, :) = min(real(eigenvalues));
                        
                        %{
                            Remove near-zero values which can arise due to
                            numerical artifacting
                        %}
                        s1(totalCounter, abs(s1(totalCounter, :)) < 1e-6) = 0.0;
                        s2(totalCounter, abs(s2(totalCounter, :)) < 1e-6) = 0.0;
                        s3(totalCounter, abs(s3(totalCounter, :)) < 1e-6) = 0.0;
                    end
                end
                
                if isFosIteration == 0.0
                    [previousN, groupAlpha] = getAlpha(mainID, subID,...
                        stressInvParam, previousN, groupAlpha, s1, s2, s3,...
                        groups, algorithm, N, totalCounter, groupIDs, groupIDBuffer);
                end
            end
            
            if isFosIteration == 1.0
                setappdata(0, 'S1_FOS', s1)
                setappdata(0, 'S2_FOS', s2)
                setappdata(0, 'S3_FOS', s3)
            else
                %{
                    If the user-specified stress invariant parameter is
                    PROGRAM CONTROLLED, choose the parameter automatically,
                    based on the biaxiality ratio for each group
                %}
                if (algorithm == 7.0) && (stressInvParam == 0.0)
                    algorithm_sip.getInvariantParameter(groupAlpha, G)
                end
                
                setappdata(0, 'S1', s1)
                setappdata(0, 'S2', s2)
                setappdata(0, 'S3', s3)
            end
        end
        
        %% Get the damage parameter for the Stress Invariant Parameter algorithm
        function [stressInvParam] = getStressInvParam(isFOSIteration)
            % Get the stress invariant parameter
            stressInvParamType = getappdata(0, 'stressInvariantParameter');
            
            if stressInvParamType ~= 1.0
                %{
                    Get the principal stress for non-default stress
                    invariant parameter
                %}
                if isFOSIteration == 1.0
                    S1 = getappdata(0, 'S1_FOS');
                    S2 = getappdata(0, 'S2_FOS');
                    S3 = getappdata(0, 'S3_FOS');
                else
                    S1 = getappdata(0, 'S1');
                    S2 = getappdata(0, 'S2');
                    S3 = getappdata(0, 'S3');
                end
                
                [N, L] = size(S1);
                
                stressInvParam = zeros(N, L);
            end
            
            switch stressInvParamType
                case 1.0    % VON MISES
                    if isFOSIteration == 1.0
                        Sxxi = getappdata(0, 'Sxxi_FOS');
                        Syyi = getappdata(0, 'Syyi_FOS');
                        Szzi = getappdata(0, 'Szzi_FOS');
                        Txyi = getappdata(0, 'Txyi_FOS');
                        Tyzi = getappdata(0, 'Tyzi_FOS');
                        Txzi = getappdata(0, 'Txzi_FOS');
                        
                        stressInvParam = sqrt(0.5.*((Sxxi - Syyi).^2.0+ (Syyi - Szzi).^2.0 +...
                            (Szzi - Sxxi).^2.0 + 6.0*(Txyi.^2.0 + Tyzi.^2.0 + Txzi.^2.0)));
                    else
                        stressInvParam = getappdata(0, 'VM');
                    end
                case 2.0    % PRINCIPAL
                    stressInvParam(abs(S1) >= abs(S3)) = S1(abs(S1) >= abs(S3));
                    stressInvParam(abs(S3) > abs(S1)) = S3(abs(S3) > abs(S1));
                case 3.0    % HYDROSTATIC
                    stressInvParam = -(1.0/3.0).*(S1 + S2 + S3);
                case 4.0    % TRESCA
                    stressInvParam = 0.5*(S1 - S3);
                otherwise   % VON MISES (DEFAULT)
                    stressInvParam = getappdata(0, 'VM');
            end
            setappdata(0, 'stressInvParam', stressInvParam)
        end
        
        %% Get the von Mises stress history for the loading
        function [vm] = getVonMisesStress(N, Sxx, Syy, Szz, Txy, Tyz, Txz)
            % Flag to indicate that the von Mises stress was calculated
            setappdata(0, 'CalculatedVonMisesStress', 1.0)
            
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            [~, L] = size(Sxx);
            
            vm = zeros(N, L);
            
            totalCounter = 0.0;
            
            for groups = 1:G
                if strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0
                    % There is one, default group
                    groupIDs = linspace(1.0, N, N);
                else
                    % Assign group parameters to the current set of analysis IDs
                    [N, groupIDs] = group.switchProperties(groups, groupIDBuffer(groups));
                end
                
                for i = 1.0:N
                    totalCounter = totalCounter + 1.0;
                    groupItem = groupIDs(i);
                    
                    vm(totalCounter, :) = sqrt(0.5.*((Sxx(groupItem, :) - Syy(groupItem, :)).^2 +...
                        (Syy(groupItem, :) - Szz(groupItem, :)).^2 + (Szz(groupItem, :) - Sxx(groupItem, :)).^2 +...
                        6.*(Txy(groupItem, :).^2 + Tyz(groupItem, :).^2 + Txz(groupItem, :).^2)));
                end
            end
            
            setappdata(0, 'VM', vm)
        end
        
        %% Determine if an analysis item experiences plasticity
        function [] = getPlasticItems(N, algorithm, fid_status)
            % Only find yielded items if requested
            yieldCriteria = getappdata(0, 'yieldCriteria');
            
            % Get the history gating value
            historyGate = getappdata(0, 'historyGate');
            
            % Check that the yield criterion definition is correct
            if (yieldCriteria < 1.0) || (yieldCriteria > 3.0) || (algorithm == 8.0)
                setappdata(0, 'YIELD', linspace(-1.0, -1.0, N))
                setappdata(0, 'warning_063', 0.0)
                return
            end
            
            fprintf('\n[PRE] Evaluating yield criterion')
            fprintf(fid_status, '\n[PRE] Evaluating yield criterion');
            
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            % Initialize yield variables
            totalStrainEnergy_buffer = zeros(1.0, N);
            yield = zeros(1.0, N);
            
            % Flag to set the material model
            materialResponse = getappdata(0, 'materialResponse');
            
            startID = 1.0;
            totalCounter = 1.0;
            
            for groups = 1:G
                if strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0
                    % There is one, default group
                    
                    % Store the current material
                    setappdata(0, 'message_groupMaterial', getappdata(0, 'material'))
                else
                    % Assign group parameters to the current set of analysis IDs
                    [N, ~] = group.switchProperties(groups, groupIDBuffer(groups));
                    
                    % Store the current material
                    setappdata(0, 'message_groupMaterial', groupIDBuffer(groups).material)
                end
                
                %{
                    If the total strain energy theory is selected, make sure
                    the poisson ratio is defined
                %}
                v = getappdata(0, 'poisson');
                
                % Store the current group number
                setappdata(0, 'message_groupNumber', groups)
                
                % Check that the proof stress is defined
                if algorithm == 8.0
                    proof = getappdata(0, 'bs7608Twops');
                else
                    proof = getappdata(0, 'twops');
                end
                
                E = getappdata(0, 'E');
                kp = getappdata(0, 'kp');
                np = getappdata(0, 'np');
                
                % Check material properties
                if isempty(proof) == 1.0
                    setappdata(0, 'YIELD', linspace(-2.0, -2.0, N))
                    messenger.writeMessage(118.0)
                    totalCounter = totalCounter + 1.0;
                    continue
                elseif ((isempty(E) == 1.0) || (isempty(kp) == 1.0) || (isempty(np) == 1.0)) && (materialResponse == 2.0)
                    % Nonlinear elastic model was requested, but material properties are insufficient
                    materialResponse = 1.0;
                    messenger.writeMessage(119.0)
                elseif (isempty(v) == 1.0) && (yieldCriteria == 1.0)
                    setappdata(0, 'YIELD', linspace(-2.0, -2.0, N))
                    messenger.writeMessage(162.0)
                    totalCounter = totalCounter + 1.0;
                    continue
                end
                
                % The Tresca criterion requires E for the strain energy calculation
                if (yieldCriteria == 3.0) && (isempty(E) == 1.0) && (materialResponse == 1.0)
                    setappdata(0, 'YIELD', linspace(-2.0, -2.0, N))
                    messenger.writeMessage(290.0)
                    totalCounter = totalCounter + 1.0;
                    continue
                end
                
                % Set the strain limit energy for the current group
                strainLimitEnergy = proof^2.0;
                
                s1 = getappdata(0, 'S1');
                s2 = getappdata(0, 'S2');
                s3 = getappdata(0, 'S3');
                
                s1 = s1(startID:(startID + N) - 1.0, :);
                s2 = s2(startID:(startID + N) - 1.0, :);
                s3 = s3(startID:(startID + N) - 1.0, :);
                
                % Remove compressive stresses if ndCompression=1
                if getappdata(0, 'ndCompression') == 1.0
                    s1(s1 < 0.0) = 0.0;
                    s2(s2 < 0.0) = 0.0;
                    s3(s3 < 0.0) = 0.0;
                end
                
                % Correct the principal stresses for the effect of nonlinearity
                for i = 1:N
                    s1_i = s1(i, :);
                    s2_i = s2(i, :);
                    s3_i = s3(i, :);
                    
                    if materialResponse == 2.0
                        try
                            % Gate the history
                            gate = preProcess.autoGate(s1_i, historyGate);
                            [peaks, valleys] = preProcess.peakdet(s1_i, gate);
                            
                            if isempty(peaks) == 0.0 && isempty(valleys) == 0.0
                                % Order the P-V time values from low to high
                                times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                                
                                % Reconstruct the history signal
                                newLength = length(times);
                                s1_i = zeros(1.0, newLength);
                                
                                peak_j = 1.0; valley_j = 1.0;
                                
                                for j = 1.0:newLength
                                    if any(peaks(:, 1.0) == times(j))
                                        s1_i(j) = peaks(peak_j, 2.0);
                                        peak_j = peak_j + 1.0;
                                    else
                                        s1_i(j) = valleys(valley_j, 2.0);
                                        valley_j = valley_j + 1.0;
                                    end
                                end
                            end
                            
                            [~, e1_i, s1_i, error] = css2b(s1_i, E, kp, np);
                            
                            % Gate the history
                            gate = preProcess.autoGate(s2_i, historyGate);
                            [peaks, valleys] = preProcess.peakdet(s2_i, gate);
                            
                            if isempty(peaks) == 0.0 && isempty(valleys) == 0.0
                                % Order the P-V time values from low to high
                                times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                                
                                % Reconstruct the history signal
                                newLength = length(times);
                                s2_i = zeros(1.0, newLength);
                                
                                peak_j = 1.0; valley_j = 1.0;
                                
                                for j = 1.0:newLength
                                    if any(peaks(:, 1.0) == times(j))
                                        s2_i(j) = peaks(peak_j, 2.0);
                                        peak_j = peak_j + 1.0;
                                    else
                                        s2_i(j) = valleys(valley_j, 2.0);
                                        valley_j = valley_j + 1.0;
                                    end
                                end
                                
                                [~, ~, s2_i, error] = css2b(s2_i, E, kp, np);
                            end
                            
                            % Gate the history
                            gate = preProcess.autoGate(s3_i, historyGate);
                            [peaks, valleys] = preProcess.peakdet(s3_i, gate);
                            
                            if isempty(peaks) == 0.0 && isempty(valleys) == 0.0
                                % Order the P-V time values from low to high
                                times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                                
                                % Reconstruct the history signal
                                newLength = length(times);
                                s3_i = zeros(1.0, newLength);
                                
                                peak_j = 1.0; valley_j = 1.0;
                                
                                for j = 1.0:newLength
                                    if any(peaks(:, 1.0) == times(j))
                                        s3_i(j) = peaks(peak_j, 2.0);
                                        peak_j = peak_j + 1.0;
                                    else
                                        s3_i(j) = valleys(valley_j, 2.0);
                                        valley_j = valley_j + 1.0;
                                    end
                                end
                                
                                [~, e3_i, s3_i, error] = css2b(s3_i, E, kp, np);
                            end
                        catch
                            error = 2.0;
                        end
                        
                        %{
                            If there was an error during the conversion,
                            warn the user
                        %}
                        if error == 1.0
                            yield(totalCounter:(totalCounter + N) - 1.0) = -2.0;
                            setappdata(0, 'yieldCriteria', 0.0)
                            setappdata(0, 'message_214_E', E)
                            setappdata(0, 'message_214_K', kp)
                            setappdata(0, 'message_214_N', np)
                            setappdata(0, 'message_214_groupMaterial', groupIDBuffer(groups).material)
                            setappdata(0, 'message_214_groupName', groupIDBuffer(groups).name)
                            setappdata(0, 'message_214_groupNumber', groups)
                            messenger.writeMessage(214.0)
                            
                            totalCounter = totalCounter + N;
                            break
                        elseif error == 2.0
                            yield(totalCounter:(totalCounter + N) - 1.0) = -2.0;
                            setappdata(0, 'yieldCriteria', 0.0)
                            setappdata(0, 'message_242_groupMaterial', groupIDBuffer(groups).material)
                            setappdata(0, 'message_242_groupName', groupIDBuffer(groups).name)
                            setappdata(0, 'message_242_groupNumber', groups)
                            messenger.writeMessage(242.0)
                            
                            totalCounter = totalCounter + N;
                            break
                        end
                        
                        %{
                            Make sure principal stress histories are the
                            same length after correcting for plasticity
                        %}
                        lengths = [length(s1_i), length(s2_i), length(s3_i)];
                        signalLength = max(lengths);
                        
                        if lengths(1.0) < signalLength
                            s1_i = [s1_i, zeros(1.0, signalLength - lengths(1.0))]; %#ok<AGROW>
                        end
                        if lengths(2.0) < signalLength
                            s2_i = [s2_i, zeros(1.0, signalLength - lengths(2.0))]; %#ok<AGROW>
                        end
                        if lengths(3.0) < signalLength
                            s3_i = [s3_i, zeros(1.0, signalLength - lengths(3.0))]; %#ok<AGROW>
                        end
                    end
                    
                    % Get the maximum strain energy in the loading for each analysis item
                    %{
                        Evaluate the principal stresses based on the
                        selected yield criterion
                    %}
                    switch yieldCriteria
                        case 1.0 % Total strain energy theory
                            totalStrainEnergy = s1_i.^2.0 + s2_i.^2.0 + s3_i.^2.0 - (2.0*v).*((s1_i.*s2_i) + (s2_i.*s3_i) + (s1_i.*s3_i));
                            if max(totalStrainEnergy) >= strainLimitEnergy
                                yield(totalCounter) = 1.0;
                            end
                            
                            totalStrainEnergy_buffer(totalCounter) = max(totalStrainEnergy);
                            
                            totalCounter = totalCounter + 1.0;
                        case 2.0 % Shear strain energy theory
                            totalStrainEnergy = 0.5.*((s1_i - s2_i).^2.0 + (s2_i - s3_i).^2.0 + (s3_i - s1_i).^2.0);
                            if max(totalStrainEnergy) >= strainLimitEnergy
                                yield(totalCounter) = 1.0;
                            end
                            
                            totalStrainEnergy_buffer(totalCounter) = max(totalStrainEnergy);
                            
                            totalCounter = totalCounter + 1.0;
                        case 3.0 % Tresca failure theory
                            tMax = abs(s1_i - s3_i);
                            if max(tMax) >= proof
                                yield(totalCounter) = 1.0;
                            end
                            
                            if materialResponse == 1.0
                                totalStrainEnergy_buffer(totalCounter) = 1e6*max(tMax)^2.0/(2.0*E);
                            else
                                totalStrainEnergy_buffer(totalCounter) = 1e6*0.5*max(tMax)*max(abs(e1_i - e3_i));
                            end
                            
                            totalCounter = totalCounter + 1.0;
                    end
                end
                
                % Save the strain limit energy
                group_materialProps = getappdata(0, 'group_materialProps');
                group_materialProps(groups).strainLimitEnergy = strainLimitEnergy;
                setappdata(0, 'group_materialProps', group_materialProps)
                setappdata(0, 'strainLimitEnergy', strainLimitEnergy)
                
                % Save thte total strain energy
                setappdata(0, 'totalStrainEnergy', totalStrainEnergy_buffer)
                setappdata(0, 'totalStrainEnergy_group', totalStrainEnergy_buffer(startID:totalCounter - 1.0))
                
                yield_group = yield(startID:(startID + N) - 1.0);
                setappdata(0, 'warning_066_N', length(yield_group(yield_group == 1.0)))
                
                if any(yield_group == 1.0) == 1.0
                    setappdata(0, 'warning_066', 1.0)
                else
                    setappdata(0, 'warning_066', 0.0)
                end
                
                messenger.writeMessage(66.0)
                
                % Save the current material state
                group.saveMaterial(groups)
                
                % Update the start ID
                startID = startID + N;
            end
            
            % Save the field variables
            setappdata(0, 'YIELD', yield)
        end
        
        %% Get the normal and shear range from the model data
        function [] = getRanges(Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID)
            % Group the normal stresses
            maxOfNormals = [max(Sxx), max(Syy), max(Szz)];
            maxNormal = max(maxOfNormals);
            
            minOfNormals = [min(Sxx), min(Syy), min(Szz)];
            minNormal = min(minOfNormals);
            
            % Group the shear stresses
            maxOfShears = [max(Txy), max(Tyz), max(Txz)];
            maxShear = max(maxOfShears);
            
            minOfShears = [min(Txy), min(Tyz), min(Txz)];
            minShear = min(minOfShears);
            
            % Get the maximum tensor components
            maxXX = max(max(Sxx));
            maxYY = max(max(Syy));
            maxZZ = max(max(Szz));
            maxXY = max(max(Txy));
            maxYZ = max(max(Tyz));
            maxXZ = max(max(Txz));
            
            maxTensorComponents = [max(maxXX), max(maxYY), max(maxZZ),...
                max(maxXY), max(maxYZ), max(maxXZ)];
            
            % Get the number of history points
            [item, ~] = size(Sxx);
            
            if item == 1.0
                SxxMaxLoc = 1.0;
                SyyMaxLoc = 1.0;
                SzzMaxLoc = 1.0;
                TxyMaxLoc = 1.0;
                TyzMaxLoc = 1.0;
                TxzMaxLoc = 1.0;
            else
                SxxMaxLoc = find(Sxx == maxTensorComponents(1));
                SxxMaxLoc = SxxMaxLoc(1);
                
                SyyMaxLoc = find(Syy == maxTensorComponents(2));
                SyyMaxLoc = SyyMaxLoc(1);
                
                SzzMaxLoc = find(Szz == maxTensorComponents(3));
                SzzMaxLoc = SzzMaxLoc(1);
                
                TxyMaxLoc = find(Txy == maxTensorComponents(4));
                TxyMaxLoc = TxyMaxLoc(1);
                
                TyzMaxLoc = find(Tyz == maxTensorComponents(5));
                TyzMaxLoc = TyzMaxLoc(1);
                
                TxzMaxLoc = find(Txz == maxTensorComponents(6));
                TxzMaxLoc = TxzMaxLoc(1);
                
                SxxMaxLoc = SxxMaxLoc - item*floor(SxxMaxLoc/item);
                if SxxMaxLoc == 0.0
                    SxxMaxLoc = 1.0;
                end
                SyyMaxLoc = SyyMaxLoc - item*floor(SyyMaxLoc/item);
                if SyyMaxLoc == 0.0
                    SyyMaxLoc = 1.0;
                end
                SzzMaxLoc = SzzMaxLoc - item*floor(SzzMaxLoc/item);
                if SzzMaxLoc == 0.0
                    SzzMaxLoc = 1.0;
                end
                TxyMaxLoc = TxyMaxLoc - item*floor(TxyMaxLoc/item);
                if TxyMaxLoc == 0.0
                    TxyMaxLoc = 1.0;
                end
                TyzMaxLoc = TyzMaxLoc - item*floor(TyzMaxLoc/item);
                if TyzMaxLoc == 0.0
                    TyzMaxLoc = 1.0;
                end
                TxzMaxLoc = TxzMaxLoc - item*floor(TxzMaxLoc/item);
                if TxzMaxLoc == 0.0
                    TxzMaxLoc = 1.0;
                end
            end
            
            maxTensorComponentsPosition = {...
                sprintf('%.0f.%.0f', mainID(SxxMaxLoc), subID(SxxMaxLoc)),...
                sprintf('%.0f.%.0f', mainID(SyyMaxLoc), subID(SyyMaxLoc)),...
                sprintf('%.0f.%.0f', mainID(SzzMaxLoc), subID(SzzMaxLoc)),...
                sprintf('%.0f.%.0f', mainID(TxyMaxLoc), subID(TxyMaxLoc)),...
                sprintf('%.0f.%.0f', mainID(TyzMaxLoc), subID(TyzMaxLoc)),...
                sprintf('%.0f.%.0f', mainID(TxzMaxLoc), subID(TxzMaxLoc))};
            
            % Save the data
            setappdata(0, 'directShearRanges', [maxNormal(1), minNormal(1), maxShear(1), minShear(1)])
            setappdata(0, 'maxTensorComponents', maxTensorComponents)
            setappdata(0, 'maxTensorComponentsPosition', maxTensorComponentsPosition)
        end
        
        %% Get the fatigue limit stress
        function [error] = getFatigueLimit(plasticSN, algorithm, msCorrection)
            error = 0.0;
            %{
                Calculate the fatigue limit stress (conditional stress) for
                each analysis group
            %}
            
            enduranceSource = getappdata(0, 'fatigueLimitSource');
            
            G = getappdata(0, 'numberOfGroups');
            
            %% Verify the definition of user-defined endurance limit values
            if enduranceSource == 3.0
                userEnduranceLimit = getappdata(0, 'userFatigueLimit');
                numberOfLimits = length(userEnduranceLimit);
                
                if isnumeric(userEnduranceLimit) == 1.0
                    if (numberOfLimits ~= 1.0) && (numberOfLimits ~= G)
                        %{
                            If the endurance limit is defined as a
                            numerical array with length greater than one,
                            but different to the number of groups, abort
                            the analysis
                        %}
                        setappdata(0, 'E096', 1.0)
                        setappdata(0, 'error_log_096_NEnduranceDefinitions', numberOfLimits)
                        setappdata(0, 'error_log_096_NGroups', G)
                        error = 1.0;
                        return
                    elseif numberOfLimits == 1.0
                        %{
                            If the endurance limit is defined as a single
                            value, modify the definition if necessary so
                            that the number of limit values match the
                            number of groups for analysis
                        %}
                        userEnduranceLimit = linspace(userEnduranceLimit, userEnduranceLimit, G);
                        
                        if numberOfLimits ~= G
                            % Notify the user that the definition will be propagated
                            messenger.writeMessage(136.0)
                        end
                    end
                elseif iscell(userEnduranceLimit) == 1.0
                    %{
                        The endurance limit is defined as a cell. Only
                        numerical arrays are supported for user endurance
                        limit definitions
                    %}
                    
                    setappdata(0, 'E097', 1.0)
                    error = 1.0;
                    return
                else
                    %{
                        The endurance limit definition is unrecognisable.
                        Abort the analysis
                    %}
                    setappdata(0, 'E098', 1.0)
                    error = 1.0;
                    return
                end
            end
            
            %% Calculate the endurance limit
            for i = 1:G
                % Recall the material properties for the current group
                group.recallMaterial(i)
                
                cael = getappdata(0, 'cael');
                cael_status = getappdata(0, 'cael_status');
                E = getappdata(0, 'E');
                Sf = getappdata(0, 'Sf');
                b = getappdata(0, 'b');
                Ef = getappdata(0, 'Ef');
                c = getappdata(0, 'c');
                kp = getappdata(0, 'kp');
                np = getappdata(0, 'np');
                
                setappdata(0, 'enduranceLimitGroupNumber', i)
                
                if (enduranceSource == 3.0) && (isempty(userEnduranceLimit(i)) == 1.0)
                    conditionalStress = Sf*((cael)^b);
                    setappdata(0, 'fatigueLimit', conditionalStress)
                    messenger.writeMessage(88.0)
                elseif (enduranceSource == 3.0) && (isempty(userEnduranceLimit(i)) == 0.0)
                    conditionalStress = userEnduranceLimit(i);
                elseif (getappdata(0, 'useSN') == 1.0) && (algorithm ~= 3.0)
                    N = getappdata(0, 'n_values');
                    
                    if getappdata(0, 'nSNDatasets') > 1.0
                        S = getappdata(0, 's_values_reduced');
                    else
                        S = getappdata(0, 's_values');
                    end
                    
                    if cael_status == 0.0
                        %{
                            If the CAEL is defined explicitly in the
                            material, use this value as the endurance limit
                            instead of the S-N curve
                        %}
                        conditionalStress = 10^(interp1(log10(N), log10(S), log10(0.5*cael), 'linear', 'extrap'));
                    else
                        %{
                            If the CAEL is not explicitly defined in the
                            material (default of 2e+07), use the last
                            S-value on the R=-1.0 S-N curve. The CAEL is
                            the life value at this stress
                        %}
                        conditionalStress = S(end);
                        setappdata(0, 'cael', 2.0*N(end))
                    end
                elseif enduranceSource == 1.0
                    if algorithm == 3.0
                        conditionalStress = E*((Sf/E)*((cael)^b) + Ef*((cael)^c));
                        [~, ~, conditionalStress, ~] = css2(conditionalStress, E, kp, np);
                        
                        messenger.writeMessage(48.0)
                    else
                        conditionalStress = Sf*((cael)^b);
                    end
                elseif algorithm == 4.0 %SBBM
                    if plasticSN == 1.0 && (isempty(Ef) == 0.0 && isempty(c) == 0.0)
                        conditionalStress = E*(((1.65*Sf)/(E))*(cael)^b + (1.75*Ef)*(cael)^c);
                        [~, ~, conditionalStress, ~] = css2(conditionalStress, E, kp, np);
                    else
                        conditionalStress = (1.65*Sf)*(cael)^b;
                    end
                elseif algorithm == 6.0 % Findley
                    Tfs = getappdata(0, 'Tfs');
                    
                    conditionalStress = Tfs*((cael)^b);
                else % PS, von Mises or NASALIFE
                    conditionalStress = Sf*((cael)^b);
                end
                
                setappdata(0, 'fatigueLimit', conditionalStress)
                
                % Save the fatigue limit for the current group
                group.saveMaterial(i)
            end
            
            %{
                Warn the user if the modified endurance limit is used with
                R-ratio S-N curves
            %}
            if msCorrection == 7.0
                messenger.writeMessage(256.0)
            end
        end
        
        %% Verify user-defined Walker gamma definition
        function [error] = getWalkerGamma()
            error = 0.0;
            
            G = getappdata(0, 'numberOfGroups');
            
            group_materialProps = getappdata(0, 'group_materialProps');
            walkerGamma = zeros(1.0, G);
            
            %% Verify the definition of Walker values
            walkerGammaSource = getappdata(0, 'walkerGammaSource');
            
            if walkerGammaSource == 3.0 % USER-DEFINED
                walkerGamma = getappdata(0, 'userWalkerGamma');
                numberOfGammas = length(walkerGamma);
                
                if isnumeric(walkerGamma) == 1.0
                    if (numberOfGammas ~= 1.0) && (numberOfGammas ~= G)
                        %{
                            If gamma is defined as a numerical array with
                            length greater than one, but different to the
                            number of groups, abort the analysis
                        %}
                        setappdata(0, 'E099', 1.0)
                        setappdata(0, 'error_log_099_NGammaDefinitions', numberOfGammas)
                        setappdata(0, 'error_log_099_NGroups', G)
                        error = 1.0;
                        return
                    elseif numberOfGammas == 1.0
                        %{
                            If gamma is defined as a single value, modify the
                            definition if necessary so that the number of gamma
                            values match the number of groups for analysis
                        %}
                        walkerGamma = linspace(walkerGamma, walkerGamma, G);
                        
                        if numberOfGammas ~= G
                            % Notify the user that the definition will be propagated
                            messenger.writeMessage(137.0)
                        end
                    end
                elseif iscell(walkerGamma) == 1.0
                    %{
                        Gamma is defined as a cell. Only numerical arrays are
                        supported for user gamma definitions
                    %}
                    messenger.writeMessage(171.0)
                    walkerGamma = cell2mat(walkerGamma);
                    if numberOfGammas ~= G
                        %{
                            The number of Walker gamma values differs from
                            the number of analysis groups. Abort the analysis
                        %}
                        setappdata(0, 'E099', 1.0)
                        setappdata(0, 'error_log_099_NGammaDefinitions', numberOfGammas)
                        setappdata(0, 'error_log_099_NGroups', G)
                        error = 1.0;
                        return
                    end
                else
                    %{
                        The gamma definition is unrecognisable. Abort the
                        analysis
                    %}
                    setappdata(0, 'E101', 1.0)
                    error = 1.0;
                    return
                end
                
                % Verify the values of gamma
                for groups = 1:G
                    if (walkerGamma(groups) < 0.0) || (walkerGamma(groups) > 1.0)
                        setappdata(0, 'E142', 1.0)
                        setappdata(0, 'error_log_142_group', groups)
                        setappdata(0, 'error_log_142_gamma', walkerGamma(groups))
                        error = 1.0;
                        return
                    end
                end
            else
                for groups = 1:G
                    group.recallMaterial(groups)
                    uts = group_materialProps(groups).uts;
                    behaviour = getappdata(0, 'materialBehavior');
                    
                    if (walkerGammaSource == 2.0) || (isempty(uts) == 1.0) % STANDARD VALUES
                        if behaviour == 1.0
                            % Calculate gamma based on Dowling for steel
                            walkerGamma(groups) = 0.65;
                        elseif behaviour == 2.0
                            % Calculate gamma based on Dowling for aluminium
                            walkerGamma(groups) = 0.45;
                        else
                            % Calculate gamma based on load ratio
                            walkerGamma(groups) = -9999.0;
                        end
                    else % REGRESSION FIT
                        if (behaviour == 1.0) || (behaviour == 3.0)
                            walkerGamma(groups) = (-0.0002*uts) + 0.8818;
                        elseif behaviour == 2.0
                            if uts < 365.0
                                walkerGamma(groups) = 0.651;
                            elseif uts > 475.0
                                walkerGamma(groups) = 0.473;
                            else
                                walkerGamma(groups) = 0.651 + (-0.001618181*(uts - 365.0));
                            end
                        end
                    end
                end
            end
            
            for i = 1:G
                setappdata(0, 'walkerGamma', walkerGamma(i))
                
                % Save the gamma value for the current group
                group.saveMaterial(i)
            end
        end
        
        %% Make sure the output directory exists
        function [dir, error] = checkOutput(jobName, outputField, outputHistory, outputFigure)
            error = 0.0;
            datacheck = getappdata(0, 'dataCheck');
            
            %%  Create the output directory if it doesn't exist
            dir = sprintf('Project/output/%s/', jobName);
            setappdata(0, 'outputDirectory', dir)
            
            % Check the job name for illegal characters
            if isempty(regexp(jobName, '[/\\*:?"<>|]', 'once')) == 0.0
                message1 = sprintf('The job name cannot contain any of the following characters:\n\n');
                message2 = sprintf('/ \\ * : ? " < > |');
                errordlg([message1, message2], 'Quick Fatigue Tool')
                error = 1.0;
                fprintf('\n[ERROR] Invalid job name\n')
                return
            end
            
            % If the output directory doesn't exist, create one
            if exist(dir, 'dir') == 0.0
                try
                    mkdir(dir)
                catch unhandledException
                    message1 = sprintf('The output directory for job ''%s'' could not be created.\n\n', jobName);
                    message2 = sprintf('Please ensure that Quick Fatigue Tool has permission to access the following directory:\n\n');
                    message3 = sprintf('''%s''\n\n', dir);
                    message4 = sprintf('Exception: %s', unhandledException.identifier);
                    errordlg([message1, message2, message3, message4], 'Quick Fatigue Tool')
                    error = 1.0;
                    fprintf('\n[ERROR] Unable to create output directory\n')
                    return
                end
                
                if (outputField == 1.0) || (outputHistory == 1.0) || (getappdata(0, 'workspaceToFile') == 1.0)
                    mkdir([dir, 'Data Files'])
                end
                
                if (outputFigure == 1.0) && (datacheck ~= 1.0)
                    mkdir([dir, 'MATLAB Figures'])
                end
            elseif exist(dir, 'dir') == 7.0
                %{
                    If the output directory already exists, warn user that
                    the directory will be overwritten
                %}
                cantRemovePreviousOutput = 0.0;
                
                if getappdata(0, 'checkOverwrite') == 1.0
                    if getappdata(0, 'analysisDialogues') > 0.0
                        response = questdlg(sprintf('An output directory already exists for job ''%s''.\nOK to overwrite?',...
                            jobName), 'Quick Fatigue Tool', 'OK', 'Cancel', 'OK');
                        
                        checkString = 'OK';
                    else
                        response = input(sprintf('\nAn output directory already exists for job ''%s''. OK to overwrite? [Y/N]: ', jobName), 's');
                        
                        checkString = 'Y';
                    end
                else
                    response = 'OK';
                    checkString = response;
                end
                
                
                if strcmpi(checkString, response) == 1.0
                    try
                        rmdir(dir, 's');
                    catch unhandledException
                        setappdata(0, 'warning_026', 1.0)
                        cantRemovePreviousOutput = 1.0;
                        setappdata(0, 'warning_026_exceptionMessage', unhandledException.identifier)
                    end
                    
                    if (outputField == 1.0) || (outputHistory == 1.0)
                        if exist([dir, 'Data Files'], 'dir') == 0.0
                            try
                                mkdir([dir, 'Data Files'])
                            catch unhandledException
                                setappdata(0, 'E034', 1.0)
                                setappdata(0, 'warning_034_exceptionMessage', unhandledException.identifier)
                                
                                cleanup(1.0)
                                error = 1.0;
                                return
                            end
                        end
                    end
                    
                    if (outputFigure == 1.0) && (ischar(datacheck) == 0.0) && (datacheck ~= 1.0)
                        if exist([dir, 'MATLAB Figures'], 'dir') == 0.0
                            try
                                mkdir([dir, 'MATLAB Figures'])
                            catch unhandledException
                                setappdata(0, 'E034', 1.0)
                                setappdata(0, 'warning_034_exceptionMessage', unhandledException.identifier)
                                
                                cleanup(1.0)
                                error = 1.0;
                                return
                            end
                        end
                    end
                    
                    if (outputField == 0.0) && (outputHistory == 0.0) && (outputFigure == 0.0)
                        %{
                            Only attempt to create the output directory if
                            the previous directory was successfully removed
                        %}
                        if cantRemovePreviousOutput == 0.0
                            mkdir(dir)
                        end
                    end
                else
                    fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                    error = 1.0;
                    return
                end
            end
        end
        
        %% Read a stress history for Uniaxial Stress-Life
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, error, oldSignal] = uniaxialRead(scales, gateHistories, historyGate, loadingScale, loadingOffset)
            error = 0.0;
            setappdata(0, 'dataLabel', -999.0)
            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
            
            % Check that the stress history is defined
            if ischar(scales) == 1.0
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                elseif exist(scales, 'file') == 0.0
                    error = 1.0;
                    setappdata(0, 'E036', 1.0)
                    setappdata(0, 'errorMissingScale', scales)
                end
            elseif isnumeric(scales) == 1.0
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                end
            elseif length(scales) > 1.0
                error = 1.0;
                setappdata(0, 'E037', 1.0)
                setappdata(0, 'errMultipleLoadHistories', scales)
            elseif isempty(scales) == 1.0 || length(scales) == 0.0
                error = 1.0;
                setappdata(0, 'E046', 1.0)
            end
            
            if error == 1.0
                mainID = -999.0;
                subID = -999.0;
                oldSignal = -999.0;
                
                return
            end
            
            % Verify load history gating values
            nGates = length(historyGate);
            
            if nGates == 1.0
                % Dataset/history pairs equal to number of historyGate values
            elseif nGates > 1.0 && gateHistories == 1.0
                messenger.writeMessage(2.0)
                
                % Only one gating value is permitted
                historyGate = historyGate(1.0);
            elseif isempty(nGates) == 1.0 && gateHistories == 1.0
                messenger.writeMessage(2.0)
                
                % No gating values specified
                gateHistories = 0.0;
            end
            
            % Verify the loading scale factors
            nScaleFactors = length(loadingScale);
            
            if nScaleFactors == 1.0
                % Dataset/history pairs equal to number of scale factors
            elseif nScaleFactors > 1.0
                messenger.writeMessage(282.0)
                
                % Only one scale factor is permitted
                loadingScale = loadingScale(1.0);
            elseif isempty(nScaleFactors) == 1.0
                messenger.writeMessage(282.0)
                
                % No scale factors specified
                loadingScale = 1.0;
            end
            
            % Verify the loading offset values
            nOffsetValues = length(loadingOffset);
            
            if nOffsetValues == 1.0
                % Dataset/history pairs equal to number of offest values
            elseif nOffsetValues > 1.0
                messenger.writeMessage(284.0)
                
                % Only one offest value is permitted
                loadingOffset = loadingOffset(1.0);
            elseif isempty(nOffsetValues) == 1.0
                messenger.writeMessage(284.0)
                
                % No load offset values specified
                loadingOffset = 1.0;
            end
            
            %{
                If HISTORY was defined as a cell, convert the cell into a
                numeric vector
            %}
            if iscell(scales) == 1.0
                scales = cell2mat(scales);
            end
            
            % Load the history file
            if isnumeric(scales) == 0.0
                try
                    scale = dlmread(scales);
                catch unhandledException
                    error = true;
                    setappdata(0, 'E016', 1.0)
                    setappdata(0, 'error_log_016_exceptionMessage', unhandledException.identifier)
                    setappdata(0, 'loadHistoryUnableOpen', scales)
                    
                    if exist(scales, 'file') == 0.0
                        setappdata(0, 'scaleNotFound', 1.0)
                    end
                    
                    mainID = -999.0;
                    subID = -999.0;
                    oldSignal = -999.0;
                    return
                end
            else
                % Load history is specified directly in the job file
                scale = scales;
            end
            
            % Remove INF/NaN values from load history data
            scale(scale == inf) = [];
            scale(scale == -inf) = [];
            scale(isnan(scale)) = [];
            
            % Check the length of the history data
            if length(scale) < 2.0
                if getappdata(0, 'compositeCriteria') == 1.0
                    %{
                    	For composite failure criteria analysis, a load
                        history 1 point is permitted. Prepend a zero to the
                        load history
                    %}
                    scale = [0.0, scale];
                else
                    error = true;
                    setappdata(0, 'E017', 1.0)
                    
                    mainID = -999.0;
                    subID = -999.0;
                    oldSignal = -999.0;
                    return
                end
            end
            
            % Check the dimensionality of the history data
            [r, c] = size(scale);
            if r ~= 1.0 && c ~= 1.0
                setappdata(0, 'E020', 1.0)
                setappdata(0, 'loadHistoryUnableOpen', scale)
                
                error = true;
                
                mainID = -999.0;
                subID = -999.0;
                oldSignal = -999.0;
                return
            elseif c == 1.0
                scale = scale';
            end
            
            % Scale the current load history
            scale = scale.*loadingScale;
            
            % Offset the current load history
            if isempty(loadingOffset) == 1.0
                loadingOffset = 0.0;
            end
            scale = scale + loadingOffset;
            
            % Save the old signal
            oldSignal = scale;
            
            % Perform noise reduction is applicable
            if getappdata(0, 'noiseReduction') == 1.0
                messenger.writeMessage(267.0)
                nWindows = getappdata(0, 'numberOfWindows');
                nCoefficient = ones(1.0, nWindows)/nWindows;
                scale = filter(nCoefficient, 1, scale);
            end
            
            % Perform peak-valley detection if a user-defined history is being used
            if length(scale) > 2.0
                if (gateHistories == 1.0)
                    % Get gating values from % of max tensor
                    if historyGate > 0.0
                        historyGate = preProcess.autoGate(scale, historyGate);
                    end
                    
                    [peaks, valleys] = preProcess.peakdet(scale, historyGate);
                    
                    if (isempty(peaks) == 1.0) || (isempty(valleys))
                        error = true;
                        setappdata(0, 'E146', 1.0)
                        
                        mainID = -999.0;
                        subID = -999.0;
                        oldSignal = -999.0;
                        return
                    end
                    
                    % Order the P-V time values from low to high
                    times = sort([peaks(:, 1)' valleys(:, 1)']);
                    
                    % Reconstruct the history signal
                    newLength = length(times);
                    scale = zeros(1, newLength);
                    
                    peak_j = 1; valley_j = 1;
                    
                    for j = 1:newLength
                        if any(peaks(:, 1) == times(j))
                            scale(j) = peaks(peak_j, 2);
                            peak_j = peak_j + 1;
                        else
                            scale(j) = valleys(valley_j, 2);
                            valley_j = valley_j + 1;
                        end
                    end
                elseif (gateHistories == 2.0)
                    % Use Nielsony's method
                    scale = preProcess.sig2ext(scale)';
                end
            end
            
            %{
                Removal of leading/trailing zeros is only required for the
                cycle counting algorithm. Therefore, this adjustment is
                only performed if the signal has a length greater than 2
            %}
            if length(scale) > 2.0
                % Remove leading zeros
                leadingZeros = 1.0;
                while leadingZeros == 1.0
                    if scale(1.0) == 0.0
                        scale(1.0) = [];
                    else
                        leadingZeros = 0.0;
                    end
                end
                
                % Remove trailing zeros
                trailingZeros = 1.0;
                while trailingZeros == 1.0
                    if scale(end) == 0.0
                        scale(end) = [];
                    else
                        trailingZeros = 0.0;
                    end
                end
            end
            
            % Return the stress tensor
            L = length(scale);
            Sxx = scale;
            Syy = zeros(1.0, L);
            Szz = zeros(1.0, L);
            Txy = zeros(1.0, L);
            Tyz = zeros(1.0, L);
            Txz = zeros(1.0, L);
            mainID = 1.0;
            subID = 1.0;
        end
        
        %% Automatically calculate the gating value for peak-valley detection
        function historyGate = autoGate(signal, historyGate)
            % History gate value cannot be equal to or greater than 100%
            if historyGate > 100.0
                historyGate = 100.0;
                messenger.writeMessage(313.0)
            end
            
            % Get the maximum value of the load history
            maxTensor = max(abs(signal));
            historyGate = (historyGate/100)*maxTensor;
            
            if isinf(historyGate) == 1.0 || isnan(historyGate) == 1.0
                historyGate = 1e-6;
            end
        end
        
        %% Gate the load history based on Adam Nielsony's method
        function [ext, exttime] = sig2ext(sig)
            % SIG2EXT - search for local extrema in the time history (signal),
            %
            % function [ext, exttime] = sig2ext(sig, dt, clsn)
            %
            % SYNTAX
            %   sig2ext(sig)
            %   [ext]=sig2ext(sig)
            %   [ext,exttime]=sig2ext(sig)
            %   [ext,exttime]=sig2ext(sig, dt)
            %   [ext,exttime]=sig2ext(sig, dt, clsn)
            %
            % OUTPUT
            %   EXT     - found extrema (turning points of the min and max type)
            %             in time history SIG,
            %   EXTTIME - option, time of extremum occurrence counted from
            %             sampling time DT (in seconds) or time vector DT.
            %             If no sampling time present, DT = 1 is assumed.
            %
            % INPUT
            %   SIG     - required, time history of loading,
            %   DT      - option, descripion as above, scalar or vector of
            %             the same length as SIG,
            %   CLSN    - option, a number of classes of SIG (division is performed
            %             before searching of extrema), no CLSN means no division
            %             into classes.
            %
            % The function caused without an output draws a course graph with
            % the searched extrema.
            %
            
            % By Adam Nies�ony
            % Revised, 10-Nov-2009
            % Visit the MATLAB Central File Exchange for latest version
            
            narginchk(1,3)
            
            % Is the time analysed?
            TimeAnalize=(nargout==0)|(nargout==2);
            
            % Sprawdzam czy przyrost dt jest podany prawid�owo
            if nargin==1,
                dt=1;
            else
                dt=dt(:); %#ok<NODEF>
            end
            
            % Zamieniam dane sig na jedn� kolumn�
            sig=sig(:);
            
            % Dzielimy na klasy je�eli jest podane CLSN
            if nargin==3,
                if nargout==0,
                    oldsig=sig;
                end
                clsn=round(clsn); %#ok<NODEF>
                smax=max(sig);
                smin=min(sig);
                sig=clsn*((sig-smin)./(smax-smin));
                sig=fix(sig);
                sig(sig==clsn)=clsn-1;
                sig=(smax-smin)/(clsn-1)*sig+smin;
            end
            
            % Tworz� wektor binarny w gdzie 1 oznacza ekstremum lub r�wno��,
            % Uznaj� �e pierwszy i ostatni punkt to ekstremum
            w1=diff(sig);
            w=logical([1;(w1(1:end-1).*w1(2:end))<=0;1]);
            ext=sig(w);
            if TimeAnalize,
                if length(dt)==1,
                    exttime=(find(w==1)-1).*dt;
                else
                    exttime=dt(w);
                end
            end
            
            % Usuwam potr�jne warto�ci
            w1=diff(ext);
            w=~logical([0; w1(1:end-1)==0 & w1(2:end)==0; 0]);
            ext=ext(w);
            if TimeAnalize,
                exttime=exttime(w);
            end
            
            % Usuwam podw�jne warto�ci i przesuwam czas na �rodek
            w=~logical([0; ext(1:end-1)==ext(2:end)]);
            ext=ext(w);
            if TimeAnalize,
                w1=(exttime(2:end)-exttime(1:end-1))./2;
                exttime=[exttime(1:end-1)+w1.*~w(2:end); exttime(end)];
                exttime=exttime(w);
            end
            
            % Jeszcze raz sprawdzam ekstrema
            if length(ext)>2,  % warunek: w tym momencie mo�e ju� by� ma�o punkt�w
                w1=diff(ext);
                w=logical([1; w1(1:end-1).*w1(2:end)<0; 1]);
                ext=ext(w);
                if TimeAnalize,
                    exttime=exttime(w);
                end
            end
            
            if nargout==0,
                if length(dt)==1,
                    dt=(0:length(sig)-1).*dt;
                end
                if nargin==3,
                    plot(dt,oldsig,'b-',dt,sig,'g-',exttime,ext,'ro')
                    legend('signal','singal divided in classes','extrema')
                else
                    plot(dt,sig,'b-',exttime,ext,'ro')
                    legend('signal','extrema')
                end
                xlabel('time')
                ylabel('signal & extrema')
                clear ext exttime
            end
            
            % Remove INF/NaN values
            ext(ext == inf) = [];
            ext(ext == -inf) = [];
            ext(isnan(ext)) = [];
        end
        
        %% Read the environment file
        function [error] = readEnvironment(jobName)
            error = 0.0;
            
            if isempty(getappdata(0, 'analysisDialogues')) == 1.0
                setappdata(0, 'analysisDialogues', 1.0)
            end
            
            % Read the global environment file
            if  exist('Application_Files/default/environment.m', 'file') == 0.0
                % The global environment file does not exist. Warn the user
                msg1 = sprintf('The environment file for the working directory was not found. The analysis may crash, or produce unexpected results.\n\n');
                msg2 = sprintf('If the environment file exists elsewhere, move it to ''Application_Files/default'', then re-run the analysis.\n\n');
                msg3 = sprintf('For assistance on creating and managing environment variables, please consult Section 2 of the Quick Fatigue Tool User Settings Reference Guide.\n');
                response = questdlg([msg1, msg2, msg3], 'Quick Fatigue Tool', 'Abort', 'Continue', 'Abort');
                
                if isempty(response) == 1.0
                    return
                elseif strcmpi(response, 'Abort') == 1.0
                    error = 1.0;
                    
                    fprintf('[NOTICE] Job %s was aborted by the user\n', jobName);
                    
                    return
                end
            else
                try
                    run('Application_Files/default/environment.m')
                catch environmentFileException
                    %{
                        The environment file could not be executed. Abort
                        the analysis and print the exception message to the
                        log file
                    %}
                    error = 1.0;
                    
                    fprintf('ERROR: The analysis could not be started\n-> MException ID: %s\n', environmentFileException.identifier);
                    fprintf('-> Current path: %s\n', pwd);
                    fprintf('-> 1) The path should be the root QFT directory. Do not enter the PROJECT folder!\n');
                    fprintf('-> 2) Make sure that a valid environment.m file exists in APPLICATION_FILES\\DEFAULT!\n');
                    
                    return
                end
            end
            
            %{
                Read the local environment file if it exists. First check
                the MATLAB path, then check the JOB firectory
            %}
            [local, error, readLocalFiles] = preProcess.checkLocalEnvironment(jobName);
            
            if error == 1.0
                return
            end
            
            if local == 1.0
                setappdata(0, 'message169_environmentFileName', readLocalFiles)
            end
            
            % Check that the environment is defined
            if isappdata(0, 'gateTensors') == 0.0
                % The environment is not fully defined. Abort the analysis
                error = 1.0;
                fprintf('ERROR: The Quick Fatigue Tool environment is not fully defined\n');
                fprintf('-> Environment variables are either missing or improperly specified\n');
                fprintf('-> Ensure that the folder ''Application_Files'' and all others beneath it have not been renamed\n');
                fprintf('-> For assistance on creating and managing environment files, please consult Section 2 of the Quick Fatigue Tool User Settings Reference Guide\n');
                return
            end
            
            % Read command line option for text input file
            if getappdata(0, 'force_echoMessagesToCWIN') == 1.0
                setappdata(0, 'echoMessagesToCWIN', 1.0)
                rmappdata(0, 'force_echoMessagesToCWIN')
            end
            
            % Clear %APPDATA% if requested
            if (getappdata(0, 'cleanAppData') == 1.0) || (getappdata(0, 'cleanAppData') == 3.0)
                app=getappdata(0.0);
                appdatas = fieldnames(app);
                for kA = 1:length(appdatas)
                    name = sprintf('%s',appdatas{kA});
                    rmappdata(0.0, name)
                end
                
                % Re-read the environment file(s)
                % Read the global environment file
                run('Application_Files/default/environment.m')
                
                % Read the local environment file if it exists
                [local, ~, readLocalFiles] = preProcess.checkLocalEnvironment(jobName);
                
                if local == 1.0
                    setappdata(0, 'message169_environmentFileName', readLocalFiles)
                end
            end
        end
        
        %% GET THE WORST (S1-S3) ITEM IN THE MODEL
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, peekGroup, vm, error] = peekAtNode(Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID)
            error = 0.0;
            
            % Get the principal stress
            s1 = getappdata(0, 'S1');
            s2 = getappdata(0, 'S2');
            s3 = getappdata(0, 'S3');
            
            % Maximum principal stress range per analysis item
            maximumRangePerNode = max(s1, [], 2.0) - min(s3, [], 2.0);
            
            % Item with the maximum principal stress range for the whole model
            peekItem = find(maximumRangePerNode == max(maximumRangePerNode));
            
            %{
                If there is more than one maxps item in the model, save the
                values and inform the user
            %}
            nPeekItems = length(peekItem);
            if nPeekItems > 1.0
                setappdata(0, 'peekItems_mainID', mainID(peekItem))
                setappdata(0, 'peekItems_subID', subID(peekItem))
                setappdata(0, 'peekItems_ranges', maximumRangePerNode(peekItem))
                setappdata(0, 'nPeekItems', nPeekItems)
                setappdata(0, 'multiplePeekItems', 1.0)
                
                preProcess.writePeekItems()
                
                peekItem = peekItem(1.0);
            end
            
            % Save the value of the maxps item
            setappdata(0, 'peekItem', peekItem)
            
            % Update the stress tensors
            Sxx = Sxx(peekItem, :);
            Syy = Syy(peekItem, :);
            Szz = Szz(peekItem, :);
            Txy = Txy(peekItem, :);
            Tyz = Tyz(peekItem, :);
            Txz = Txz(peekItem, :);
            
            % Update the principal stress
            setappdata(0, 'S1', s1(peekItem, :));
            setappdata(0, 'S2', s2(peekItem, :));
            setappdata(0, 'S3', s3(peekItem, :));
            
            % Update the von Mises stress
            if getappdata(0, 'CalculatedVonMisesStress') == 1.0
                vm = getappdata(0, 'VM');
                vm = vm(peekItem, :);
                setappdata(0, 'VM', vm)
            else
                vm = [];
            end
            
            % Update the stress invariant parameter
            if getappdata(0, 'algorithm') == 7.0
                stressInvParam = getappdata(0, 'stressInvParam');
                setappdata(0, 'stressInvParam', stressInvParam(peekItem, :))
            end
            
            % Update the position IDs
            mainID = mainID(peekItem);
            subID = subID(peekItem);
            
            setappdata(0, 'mainID_master', mainID)
            setappdata(0, 'subID_master', subID)
            
            setappdata(0, 'mainID', mainID)
            setappdata(0, 'subID', subID)
            
            % Update the group ID buffer
            G = getappdata(0, 'numberOfGroups');
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            % Initialize the variable whih stores the group contaning the MAXPS item
            peekGroup = 1.0;
            found = 0.0;
            
            for i = 1:G
                IDs = groupIDBuffer(i).IDs;
                if isempty(find(IDs == peekItem, 1.0)) == 0.0
                    % The analysis item belongs to this group
                    peekGroup = i;
                    found = 1.0;
                    break
                end
            end
            
            % Clear the group ID buffers
            groupIDBuffer(peekGroup).IDs = 1.0;
            groupIDBuffer(peekGroup).NIDs = 1.0;
            groupIDBuffer(peekGroup).OIDs = 0.0;
            groupIDBuffer(peekGroup).UIDs = 1.0;
            
            % Save the group name and stress range for the message file
            setappdata(0, 'peekAnalysis_groupName', groupIDBuffer(peekGroup).name)
            setappdata(0, 'peekGroup', peekGroup)
            setappdata(0, 'peekAnalysis_worstStressRange', maximumRangePerNode(peekItem))
            
            %{
                If the MAXPS item does not belong to any of the analysis
                group, warn the user
            %}
            if found == 0.0
                error = 1.0;
                setappdata(0, 'E107', 1.0)
                return
            else
                messenger.writeMessage(163.0)
            end
            
            setappdata(0, 'groupIDBuffer', groupIDBuffer)
        end
        
        %% WRITE MAXPS ITEMS TO A SEPARATE FILE
        function [] = writePeekItems()
            mainIDs = getappdata(0, 'peekItems_mainID');
            subIDs = getappdata(0, 'peekItems_subID');
            ranges = getappdata(0, 'peekItems_ranges');
            
            % Concatenate data
            data = [mainIDs'; subIDs'; ranges']';
            
            % Print information to file
            root = getappdata(0, 'outputDirectory');
            
            if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                mkdir(sprintf('%s/Data Files', root))
            end
            
            dir = [root, 'Data Files/maxps_items.dat'];
            
            fid = fopen(dir, 'w+');
            
            fprintf(fid, 'MAXPS_ITEMS\r\n');
            fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
            
            fprintf(fid, 'Main ID\tSub ID\tMaximum Principal Stress Range [MPa]\r\n');
            fprintf(fid, '%.0f\t%.0f\t%f\r\n', data');
            
            fclose(fid);
        end
        
        %% GET THE GOODMAN LIMIT STRESS
        function [] = goodmanLimitStress(G)
            for groups = 1:G
                % Assign group parameters to the current set of analysis IDs
                group.recallMaterial(groups)
                
                goodmanLimit = getappdata(0, 'goodmanMeanStressLimit');
                
                if strcmpi(goodmanLimit, 'uts') == 1.0
                    % Use the material UTS
                    setappdata(0, 'goodmanMeanStressLimit', getappdata(0, 'uts'));
                elseif strcmpi(goodmanLimit, 'proof') == 1.0
                    if isempty(getappdata(0, 'twops')) == 1.0
                        setappdata(0, 'goodmanMeanStressLimit', getappdata(0, 'uts'));
                        setappdata(0, 'message_165_group', groups)
                        messenger.writeMessage(165.0)
                    else
                        % Use the material proof stress
                        setappdata(0, 'goodmanMeanStressLimit', getappdata(0, 'twops'));
                    end
                elseif strcmpi(goodmanLimit, 's-n') == 1.0
                    % Use the material fatigue strength
                    if getappdata(0, 'useSN') == 1.0
                        nValues = getappdata(0, 'n_values');
                        
                        if getappdata(0, 'msCorrection') == 7.0
                            sValues = getappdata(0, 's_values_reduced');
                        else
                            sValues = getappdata(0, 's_values');
                        end
                        
                        % Interpolate to get the strength at one repeat
                        setappdata(0, 'goodmanMeanStressLimit', 10^(interp1(log10(nValues), log10(sValues), 0.0, 'linear', 'extrap')))
                    else
                        setappdata(0, 'goodmanMeanStressLimit', getappdata(0, 'Sf'));
                    end
                elseif isnumeric(goodmanLimit{1.0})
                    setappdata(0, 'goodmanMeanStressLimit', goodmanLimit{1.0});
                end
                
                group.saveMaterial(groups)
            end
        end
        
        %% CHECK FOR DUPLICATE ITEMS IN THE MODEL
        function [] = checkDuplicateItems(N, mainID, subID)
            % Concatenate the items IDs into an Nx2 matrix
            items = [mainID, subID];
            
            % Identify duplicate rows in the item tensor
            [uniqueItems, IA, IC] = unique(items, 'rows');
            
            % Get the number of duplicate items
            nDuplicateItems = N - length(IA);
            
            % If there are duplicate items in the model, identify them
            if nDuplicateItems > 0.0
                [a, ~] = hist(IC, unique(IC));
                duplicateItems = uniqueItems(a > 1.0, :);
                
                root = getappdata(0, 'outputDirectory');
                
                if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                    mkdir(sprintf('%s/Data Files', root))
                end
                
                dir = [root, 'Data Files/warn_model_duplicate_ids.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'WARN_MODEL_DUPLICATE_IDS\r\n');
                fprintf(fid, 'Job:\t%s\r\n', getappdata(0, 'jobName'));
                fprintf(fid, 'Main ID\tSub ID\r\n');
                fprintf(fid, '%.0f\t%.0f\r\n', duplicateItems');
                fclose(fid);
                
                setappdata(0, 'message_167_nDuplicateItems', nDuplicateItems)
                messenger.writeMessage(167.0)
            end
        end
        
        %% CHECK FOR LOCAL ENVIRONMENT FILES
        function [flag, error, readLocalFiles] = checkLocalEnvironment(jobName)
            flag = 0.0;
            error = 0.0;
            
            localEnvFile_abs = sprintf('%s\\Project\\job\\%s_env.m', pwd, jobName);
            localEnvFile_rel = sprintf('%s_env.m', jobName);
            localFiles = which(localEnvFile_rel, '-ALL');
            
            readLocalFiles = cell(1.0, 1.0);
            readLocalFileIndex = 1.0;
            
            % First check the MATLAB path
            for i = 1:length(localFiles)
                if strcmpi(localFiles{i}, localEnvFile_abs) == 0.0
                    try
                        run(localFiles{i})
                        
                        readLocalFiles{readLocalFileIndex, 1.0} = localFiles{i};
                        readLocalFileIndex = readLocalFileIndex + 1.0;
                        
                        flag = 1.0;
                    catch
                        % The local environment file could not be read
                        error = 1.0;
                        fprintf('ERROR: The local environment file ''%s'' could not be read\n', localFiles{i});
                        fprintf('-> Make sure the job name does not contain spaces or illegal characters\n');
                        return
                    end
                end
            end
            
            % Check the JOB directory
            if any(cell2mat(strfind(localFiles, localEnvFile_abs))) == 1.0
                try
                    run(localEnvFile_abs)
                    
                    readLocalFiles{readLocalFileIndex, 1.0} = localEnvFile_abs;
                    
                    flag = 1.0;
                catch
                    % The local environment file could not be read
                    error = 1.0;
                    fprintf('ERROR: The local environment file ''%s'' could not be read\n', localEnvFile_abs);
                    fprintf('-> Make sure the job name does not contain spaces or illegal characters\n');
                    return
                end
            end
        end
        
        %% READ DATA FILE FOR ITEMS JOB FILE OPTION
        function [items, error, mainIDs, subIDs, readUserItems] = readItemsFile(items, R, mainIDs, subIDs, error)
            % Error indicators
            %{
                1: More items than exist in the model
                2: Some items don't exist in the model
                3: Items are formatted incorrectly
                4: Other
            %}
            
            readUserItems = 0.0;
            
            if (strcmpi(items, 'all') == 1.0) || (strcmpi(items, 'maxps') == 1.0) || (strcmpi(items, 'surface') == 1.0)
                items = [];
            elseif isnumeric(items) == 0.0
                if exist(items, 'file') == 2.0
                    setappdata(0, 'hotspotFile', items)
                    
                    % If ITEMS is defined as a file, verify its contents
                    items_file = importdata(items, '\t');
                    if iscell(items_file) == 1.0
                        items_file = cell2mat(items_file);
                        [~, itemCols] = size(items_file);
                    elseif isstruct(items_file) == 1.0
                        [~, itemCols] = size(items_file.data);
                    elseif isnumeric(items_file) == 1.0
                        [~, itemCols] = size(items_file);
                    else
                        itemCols = 0.0;
                    end
                    
                    if itemCols == 1.0
                        items_header = {'NONE'};
                        items_data = items_file;
                    else
                        try
                            items_data = items_file.data;
                            items_header = items_file.textdata;
                        catch
                            items_data = 'error';
                        end
                    end
                    
                    if strcmpi(items_data, 'error') == 1.0
                        items = [];
                        error = 3.0;
                        setappdata(0, 'items', 'ALL')
                        messenger.writeMessage(144.0)
                    elseif isempty(items_data) == 1.0
                        items = [];
                        error = 3.0;
                        setappdata(0, 'items', 'ALL')
                        messenger.writeMessage(143.0)
                    elseif (strcmpi(items_header{1.0}, 'hotspots') == 0.0 && strcmpi(items_header{1.0}, 'surface items') == 0.0...
                            && strcmpi(items_header{1.0}, 'warn_lcf_items') == 0.0&& strcmpi(items_header{1.0}, 'warn_yielding_items') == 0.0...
                            && strcmpi(items_header{1.0}, 'warn_overflow_items') == 0.0) && (itemCols ~= 1.0 && itemCols ~= 4.0)
                        items = [];
                        error = 3.0;
                        setappdata(0, 'items', 'ALL')
                        messenger.writeMessage(144.0)
                    else
                        items = items_data(:, 1.0);
                        readUserItems = 1.0;
                    end
                elseif exist('items', 'file') == 0.0
                    % The file does not exist, so warn the user
                    setappdata(0, 'hotspotFile', items)
                    items = [];
                    error = 4.0;
                    setappdata(0, 'items', 'ALL')
                    messenger.writeMessage(145.0)
                end
            end
            
            if isempty(items) == 0.0
                % Remove duplicate items
                items = unique(items);
                numberOfItems = length(items);
                
                if numberOfItems > R
                    error = 1.0;
                    setappdata(0, 'E033', 1.0)
                    return
                end
                
                if isempty(find(items > R, 1.0)) == 0.0
                    mainIDs2 = mainIDs';
                    subIDs2 = subIDs';
                    
                    messenger.writeMessage(59.0)
                    
                    error = 2.0;
                else
                    mainIDs2 = mainIDs(items);
                    subIDs2 = subIDs(items);
                end
                
                mainIDs = mainIDs2;
                subIDs = subIDs2;
            end
        end
        
        %% SAVE THE FATIGUE LOADING TO A .MAT FILE
        function [] = saveFatigueLoading(jobName, Sxx, Syy, Szz, Txy, Txz, Tyz, mainID, subID)
            % Check that the directory exists
            root = [pwd, '\Data\library'];
            if exist(root, 'dir') == 0.0
                mkdir(root)
            end
            
            % Get the file name
            fileName = sprintf('%s\\[J]%s_fd.mat', [pwd, '\Data\library'], jobName);
            
            % Gather the fatigue loading into a structure
            fatigueDefinition = struct('S11', Sxx, 'S22', Syy, 'S33', Szz,...
                'S12', Txy, 'S13', Txz, 'S23', Tyz,...
                'labels', [mainID, subID]);
            
            % Save the stress data type
            fatigueDefinition.type = getappdata(0, 'dataLabel');
            
            % Save the uniaxial load history if applicable
            if isappdata(0, 'SIGOriginalSignal') == 1.0
                fatigueDefinition.uniaxial = getappdata(0, 'SIGOriginalSignal');
            end
            
            try
                % Create MAT-file object
                m = matfile(fileName, 'writable', true);
                
                % Add the fatigue definition to the object
                m.fatigueDefinition = fatigueDefinition;
            catch exception
                setappdata(0, 'warning_309_exception', exception.message)
                messenger.writeMessage(309.0)
            end
        end
        
        %% SAVE ELIMINATED ITEMS TO A .MAT FILE
        function [] = saveEliminatedItems(jobName, coldItems, removedItems, hotspotWarning)
            % Check that the file already exists
            fileName = [pwd, sprintf('\\Data\\library\\[J]%s_fd.mat', jobName)];
            
            if exist(fileName, 'file') ~= 2.0
                %{
                    For some reason, the original fatigue load data file
                    was never written, so RETURN
                %}
                return
            end
            
            % Load the MAT-file object into the workspace
            m = matfile(fileName, 'writable', true);
            
            % Read the fatigue definition from the MAT-file
            fatigueDefinition = m.fatigueDefinition;
            
            % Add the nodal elimination data to the fatigue loading data
            fatigueDefinition.neData = struct('CI', coldItems, 'RI', removedItems, 'W', hotspotWarning);
            
            % Update the fatigue definition object
            m.fatigueDefinition = fatigueDefinition;
        end
        
        %% SAVE INVARIANT STRESSES TO A .MAT FILE
        function [] = saveInvariants(jobName)
            % Recall the principal stresses
            S1 = getappdata(0, 'S1');
            S2 = getappdata(0, 'S2');
            S3 = getappdata(0, 'S3');
            
            % Check that the file already exists
            fileName = [pwd, sprintf('\\Data\\library\\[J]%s_fd.mat', jobName)];
            
            if exist(fileName, 'file') ~= 2.0
                %{
                    For some reason, the original fatigue load data file
                    was never written, so RETURN
                %}
                return
            end
            
            % Load the MAT-file object into the workspace
            m = matfile(fileName, 'writable', true);
            
            % Read the fatigue definition from the MAT-file
            fatigueDefinition = m.fatigueDefinition;
            
            % Add the nodal elimination data to the fatigue loading data
            fatigueDefinition.invariants = struct('S1', S1, 'S2', S2, 'S3', S3, 'SIP', getappdata(0, 'stressInvariantParameter'));
            
            % Update the fatigue definition object
            m.fatigueDefinition = fatigueDefinition;
        end
    end
end
