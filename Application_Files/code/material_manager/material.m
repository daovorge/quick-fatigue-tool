classdef material < handle
%MATERIAL    QFT class for material data processing.
%   This class contains methods for command line functionality of the
%   Material Manager GUI.
%
%   MATERIAL contains the following utility functions:
%
%   MATERIAL.manage()
%   MATERIAL.list()
%   MATERIAL.import(USERMATERIAL)
%   MATERIAL.fetch()
%   MATERIAL.edit(MATERIALNAME)
%   MATERIAL.rename(OLDNAME, NEWNAME)
%   MATERIAL.remove(VARARGIN)
%   MATERIAL.evaluate(MATERIALNAME)
%   MATERIAL.copy(OLDNAME, NEWNAME)
%   MATERIAL.query(MATERIALNAME)
%   MATERIAL.database(VARARGIN)
%   MATERIAL.checkDatabase(PATH)
%   MATERIAL.changeDatabase(VARARGIN)
%   MATERIAL.searchDatabase()
%   MATERIAL.resetDatabase()
%
%   See also checkDataPath, evaluateMaterial, importMaterial,
%   kValueCalculator, LocalMaterialDatabase, MaterialEditor,
%   MaterialManager.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-03 Copyright Louis Vallance 2017
%   Last modified 02-Sep-2017 19:02:40 GMT
    
    %%
    
    methods(Static = true)
        %% Start Material Manager
        function [] = manage()
            %MATERIAL.MANAGE    Start the Material Manager GUI.
            %
            %   MATERIAL.MANAGE() is called without arguments.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            MaterialManager
        end
        
        %% List materials in local database
        function [] = list()
            %MATERIAL.LIST    List materials in the local database.
            %
            %   MATERIAL.LIST() is called without arguments.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            localMaterials = dir([localPath, '\*.mat']);
            
            fprintf('Materials in local database:\n\n')
            
            if isempty(localMaterials) == 1.0
                fprintf('(none)\n')
            else
                for i = 1:length(localMaterials)
                    fprintf('%s\n', localMaterials(i).name(1.0:end - 4.0))
                end
            end
            fprintf('\nCurrent database: %s\n', localPath)
        end
        
        %% Createa a new material
        function [] = create()
            %MATERIAL.CREATE    Create a new material with the material editor.
            %
            %   MATERIAL.CREATE() is called without arguments.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            MaterialEditor
        end
        
        %% Import material into local database from text file
        function [] = import(userMaterial)
            %MATERIAL.IMPORT    QFT function to import material text file.
            %   This function imports a material text file into the local
            %   material database.
            %
            %   MATERIAL.IMPORT(USERMATERIAL) imports material data from a
            %   text file 'USERMATERIAL.*' containing valid material
            %   definitions. The file must begin and end with the keywords
            %   *USER MATERIAL and *END MATERIAL, respectively.
            %
            %   Example material text file:
            %       *USER MATERIAL, steel
            %       *MECHANICAL
            %       200e3, , 400, ,
            %       *FATIGUE, constants
            %       930, -0.095, , ,
            %       *REGRESSION, none
            %       *END MATERIAL
            %
            %   See also importMaterial, keywords, job.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5.6 Creating a material from a text file
            %
            %   Reference section in Quick Fatigue Tool User Settings
            %   Reference Guide
            %      3 Material keywords
            
            clc
            setappdata(0, 'materialManagerImport', 1.0)
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            % Check that the material exists
            if exist(userMaterial, 'file') == 0.0
                fprintf('ERROR: Unable to locate material ''%s''.\n', userMaterial)
                return
            end
            
            [error, material_properties, materialName, ~, ~] = importMaterial.processFile(userMaterial, -1.0); %#ok<ASGLU>
            
            if exist([localPath, '\', materialName, '.mat'], 'file') == 2.0
                % User is attempting to overwrite an existing material
                response = questdlg(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName), 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Cancel', 'Overwrite');
                
                if (strcmpi(response, 'cancel') == 1.0) || (isempty(response) == 1.0)
                    return
                elseif strcmpi(response, 'Keep file') == 1.0
                    % Change the name of the old material
                    oldMaterial = materialName;
                    while exist([oldMaterial, '.mat'], 'file') == 2.0
                        oldMaterial = [oldMaterial , '-old']; %#ok<AGROW>
                    end
                    
                    % Rename the original material
                    movefile([localPath, '\', materialName, '.mat'], [localPath, '\', oldMaterial, '.mat'])
                end
            end
            
            % Save the material
            try
                save([localPath, '\', materialName], 'material_properties')
            catch
                fprintf('ERROR: Unable to save material ''%s''. Make sure the material save location has read/write access.\n', materialName)
                return
            end
            
            % List materials in the local database
            if error == 0.0
                material.list()
            end
        end
        
        %% Fetch material from system database
        function [] = fetch()
            %MATERIAL.FETCH    Fetch material from the system database.
            %   This function fetches a copy of a material from the system
            %   databse into the local database, which can then be edited
            %   and used for analysis.
            %
            %   MATERIAL.FETCH() is called without arguments.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            quest1 = sprintf('Select a database:\n\n');
            quest2 = sprintf('1: Steel (SAE)\n');
            quest3 = sprintf('2: Steel (BS)\n');
            quest4 = sprintf('3: Steel (ASTM)\n');
            quest5 = sprintf('4: Aluminium (AL)\n');
            quest6 = sprintf('5: Iron (ADI)\n');
            quest7 = sprintf('6: Iron (DI)\n');
            quest8 = sprintf('7: Iron (CGI)\n');
            quest9 = sprintf('8: Iron (GI)\n>> ');
            
            databaseToFetch = input([quest1, quest2, quest3, quest4, quest5,...
                quest6, quest7, quest8, quest9]);
            
            % Check validity of user selection
            if isnumeric(databaseToFetch) == 0.0 || (databaseToFetch < 1.0 || databaseToFetch > 8.0 || rem(databaseToFetch, 1.0) ~= 0.0)
                clc
                fprintf('ERROR: Invalid selection.\n');
                return
            end
            
            quest1 = sprintf('Select a material from the database:\n\n');
            switch databaseToFetch
                case 1.0 % SAE
                    quest2 = sprintf('Select a material from the SAE database:\n\n');
                    quest3 = sprintf('1: SAE-950C\n2: SAE-0030\n3: SAE-0080\n4: SAE-1005\n5: SAE-1006\n');
                    quest4 = sprintf('6: SAE-1008\n7: SAE-1015\n8: SAE-1020\n9: SAE-1022\n10: SAE-1025\n');
                    quest5 = sprintf('11: SAE-1030\n12: SAE-1035\n13: SAE-1040\n14: SAE-1040\n15: SAE-1045_2\n');
                    quest6 = sprintf('16: SAE-1045_3\n17: SAE-1045_4\n18: SAE-1045_5\n19: SAE-1045_6\n20: SAE-1055\n');
                    quest7 = sprintf('21: SAE-1080\n22: SAE-1137\n23: SAE-1144\n24: SAE-1522\n25: SAE-30302\n');
                    quest8 = sprintf('26: SAE-30304\n27: SAE-4130\n28: SAE-4140\n29: SAE-4142\n30: SAE-4340\n');
                    quest9 = sprintf('31: SAE-52100\n>> ');
                    quest = [quest1, quest2, quest3, quest4, quest5, quest6, quest7, quest8, quest9];
                    limit = 31.0;
                case 2.0 % BS
                    quest2 = sprintf('Select a material from the BS database:\n\n');
                    quest3 = sprintf('1: BS 1480 G5083\n2: BS 1490 LM13\n3: BS 1490 LM16\n4: BS 1490 LM25\n5: BS 1490\n');
                    quest4 = sprintf('6: BS 1490 LM27\n7: BS 4360 G40B\n8: BS 4360 G43A\n9: BS 4360 G43C\n10: BS 4360 G43D\n');
                    quest5 = sprintf('11: BS 4360 G43D2\n12: BS 970 G040A10\n13: BS 970 G53M40\n14: BS 970 G150M19\n15: BS 4360 G50A\n');
                    quest6 = sprintf('16: BS 970 G225M44\n17: BS 980 G605M36\n18: BS 970 G817M40\n19: BS 970 G835M40\n20: BS 1452 300 4\n');
                    quest7 = sprintf('21: BS 1452 300 6\n22: BS 2789370\n23: BS 2789420\n24: BS 2789420 3\n25: BS 2789600\n');
                    quest8 = sprintf('26: BS 2789700\n27: BS 2789700\n28: BS 1452 5260\n>> ');
                    quest = [quest1, quest2, quest3, quest4, quest5, quest6, quest7, quest8];
                    limit = 28.0;
                case 3.0 % ASTM
                    quest1 = sprintf('Select a material from the ASTM database:\n\n');
                    quest2 = sprintf('1: ASTM A514F\n2: ASTM A579 G71\n3: ASTM A579 G72\n4: ASTM A579 G73\n5: ASTM A715 G50\n');
                    quest3 = sprintf('6: ASTM A715 G80 1\n7: ASTM A715 G80 2\n>> ');
                    quest = [quest1, quest2, quest3];
                    limit = 7.0;
                case 4.0 % AL
                    quest1 = sprintf('Select a material from the AL database:\n\n');
                    quest2 = sprintf('1: AL1100 T6\n2: AL2014 T6\n3: AL 2024 T351\n4: AL 2024 T4\n5: AL5456 H311\n');
                    quest3 = sprintf('6: AL7075 T6\n>> ');
                    quest = [quest1, quest2, quest3];
                    limit = 6.0;
                case 5.0 % ADI
                    quest1 = sprintf('Select a material from the ADI database:\n\n');
                    quest2 = sprintf('1: ADI GRD1 AUS 25mm\n2: ADI GRD1 AUS LIT\n3: ADI GRD2 AUS 25mm\n4: ADI GRD2 AUS CONTRB\n5: ADI GRD3 AUS 25mm\n');
                    quest3 = sprintf('6: ADI GRD3 AUS CONTRB\n7: ADI GRD4 AUS 25mm\n8: ADI GRD4 AUS CONTRB\n>> ');
                    quest = [quest1, quest2, quest3];
                    limit = 8.0;
                case 6.0 % DI
                    quest1 = sprintf('Select a material from the DI database:\n\n');
                    quest2 = sprintf('1: DI 4018 FAN 25mm\n2: DI 4018 SCAN 25mm\n3: DI 4018 AC 25mm\n4: DI 4512 AC 25mm\n5: DI 4512 AC CONTR1\n');
                    quest3 = sprintf('6: DI 4512 AC CONTR2\n7: DI 4512 AC CONTR3\n8: DI 4512 FAN CONTR\n9: DI 5506 AC CONTR1\n10: DI 5506 AC CONTR2');
                    quest4 = sprintf('11: DI 5506 AC CONTR3\n12: DI 5506 AC CONTR4\n13: DI 5506 AC CONTR5\n14: DI 5506 N CONTR\n15: DI 7703 AC 25mm');
                    quest5 = sprintf('16: DI 7703 N 25mm\n17: DI 7703 N 76mm\n18: DI 7703 N CONTR\n19: DI 9002 QT 25mm\n>> ');
                    quest = [quest1, quest2, quest3, quest4, quest5];
                    limit = 19.0;
                case 7.0 % CGI
                    quest1 = sprintf('Select a material from the CGI database:\n\n');
                    quest2 = sprintf('1: CGI 300HN AC 25mm\n2: CGI 350HN AC 25mm\n3: CGI 400HN AC 25mm\n>> ');
                    quest = [quest1, quest2];
                    limit = 3.0;
                case 8.0 % GI
                    quest1 = sprintf('Select a material from the GI database:\n\n');
                    quest2 = sprintf('1: GI 20B AC 25mm\n2: GI 30B AC 13mm\n3: GI 30B AC 25mm\n4: GI 30B AC 76mm\n5: GI 30 AC 25mm CONTR');
                    quest3 = sprintf('6: GI 35B AC 25mm\n7: GI 40B AC 25mm\n8: GI AGI AUS 25mm\n>> ');
                    quest = [quest1, quest2, quest3];
                    limit = 8.0;
                otherwise
            end
            materialToFetch = input(quest);
            
            % Check validity of user selection
            if isnumeric(materialToFetch) == 0.0 || (materialToFetch < 1.0 || materialToFetch > limit || rem(materialToFetch, 1.0) ~= 0.0)
                clc
                fprintf('ERROR: Invalid selection.\n');
                return
            end
            
            % Check that the system database exists
            if exist('mat.mat', 'file') == 2.0
                load('mat.mat')
            else
                fprintf('ERROR: Missing file ''mat.mat''. Check that the file exists in Data\\material\\system.\n')
                return
            end
            
            % Get the database
            switch databaseToFetch
                case 1.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.sae);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.sae, char(materialF)); %#ok<*GFLD>
                case 2.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.bs);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.bs, char(materialF));
                case 3.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.astm);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.astm, char(materialF));
                case 4.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.al);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.al, char(materialF));
                case 5.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.adi);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.adi, char(materialF));
                case 6.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.di);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.di, char(materialF));
                case 7.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.cgi);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.cgi, char(materialF));
                case 8.0
                    % Get the list of materials belonging to this family of metals
                    fields = fieldnames(mat.gi);
                    
                    % Get the material properties
                    materialF = fields(materialToFetch);
                    properties = getfield(mat.gi, char(materialF));
                otherwise
            end
            
            % If there was an error while reading the system databse, RETURN
            if isstruct(properties) == 0.0
                if properties == 0.0
                    return
                end
            end
            
            material_properties = struct(...
                'default_algorithm', properties.default_algorithm,...
                'default_msc', properties.default_msc,...
                'class', properties.class,...
                'behavior', properties.behavior,...
                'reg_model', 1.0,...
                'cael', properties.cael,...
                'cael_active', 1.0,...
                'e', properties.e,...
                'e_active', 1.0,...
                'uts', properties.uts,...
                'uts_active', 1.0,...
                'proof', properties.proof,...
                'proof_active', 1.0,...
                'poisson', properties.poisson,...
                'poisson_active', 1.0,...
                's_values', properties.s_values,...
                'n_values', properties.n_values,...
                'r_values', properties.r_values,...
                'sf', properties.sf,...
                'sf_active', 1.0,...
                'b', properties.b,...
                'b_active', 1.0,...
                'ef', properties.ef,...
                'ef_active', 1.0,...
                'c', properties.c,...
                'c_active', 1.0,...
                'kp', properties.kp,...
                'kp_active', 1.0,...
                'np', properties.np,...
                'np_active', 1.0,...
                'nssc', properties.nssc,...
                'nssc_active', 1.0,...
                'comment', properties.comment);
            
            if isempty(properties.cael)
                material_properties.cael_active = 0.0;
            end
            if isempty(properties.e)
                material_properties.e_active = 0.0;
            end
            if isempty(properties.uts)
                material_properties.uts_active = 0.0;
            end
            if isempty(properties.proof)
                material_properties.proof_active = 0.0;
            end
            if isempty(properties.poisson)
                material_properties.poisson_active = 0.0;
            end
            if isempty(properties.sf)
                material_properties.sf_active = 0.0;
            end
            if isempty(properties.b)
                material_properties.b_active = 0.0;
            end
            if isempty(properties.ef)
                material_properties.ef_active = 0.0;
            end
            if isempty(properties.c)
                material_properties.c_active = 0.0;
            end
            if isempty(properties.kp)
                material_properties.kp_active = 0.0;
            end
            if isempty(properties.np)
                material_properties.np_active = 0.0;
            end
            if isempty(properties.nssc)
                material_properties.nssc_active = 0.0;
            end
            if isempty(properties.comment)
                material_properties.comment = '';
            end
            
            if properties.default_algorithm < 4.0
                material_properties.default_algorithm = properties.default_algorithm + 1.0; %#ok<STRNU>
            elseif properties.default_algorithm < 10.0
                material_properties.default_algorithm = properties.default_algorithm + 2.0; %#ok<STRNU>
            else
                material_properties.default_algorithm = properties.default_algorithm + 3.0; %#ok<STRNU>
            end
            
            % Get the material name
            materialName = char(materialF);
            
            % Check if the material already exists
            userMaterials = dir([localPath, '/*.mat']);
            
            for i = 1:length(userMaterials)
                if strcmpi([materialName, '.mat'], userMaterials(i).name) == 1.0
                    fprintf(sprintf('ERROR: ''%s'' already exists in the local database and cannot be overwritten.\n', materialName));
                    return
                end
            end
            
            % Save the copy in the /LOCAL directory
            try
                save([localPath, '\', materialName, '.mat'], 'material_properties')
            catch
                fprintf('ERROR: Cannot fetch ''%s'' because the local database is not currently on the MATLAB path.\n', copiedMaterial);
                return
            end
            
            % List materials in the local database
            material.list()
        end
        
        %% Edit material in local database
        function [] = edit(userMaterial)
            %MATERIAL.EDIT    Edit material in the local database.
            %   This function opens the material editor GUI for a selected
            %   material in the local database.
            %
            %   MATERIAL.EDIT(MATERIAL) edits the material MATERIAL.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            if strcmpi(userMaterial(end - 3.0:end), '.mat') == 1.0
                userMaterial = userMaterial(1.0:end - 4.0);
            end
            
            % Check that the material exists in the local directory
            if exist([localPath, '\', userMaterial, '.mat'], 'file') == 0.0
                fprintf('ERROR: Material ''%s'' does not exist in the local database.\n', userMaterial);
                return
            end
            
            setappdata(0, 'editMaterial', 1.0)
            
            setappdata(0, 'materialToEdit', userMaterial)
            MaterialEditor
        end
        
        %% Rename material in local database
        function [] = rename(oldName, newName)
            %MATERIAL.RENAME    Rename material in the local database.
            %
            %   MATERIAL.RENAME(OLDNAME, NEWNAME) renames the material
            %   OLDNAME to the material NEWNAME.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            if isempty(newName) == 1.0
                return
            elseif isempty(regexp(newName, '[/\\*:?"<>|]', 'once')) == 0.0
                fprintf('ERROR: The material name cannot contain any of the following characters: / \\ * : ? " < > |\n');
                return
            elseif strcmp(newName, oldName) == 1.0
                % Material already exists
                if exist([newName, '.mat'], 'file') == 0.0
                    fprintf('ERROR: Material ''%s'' does not exist in the local database.\n', oldName);
                else
                    fprintf('ERROR: ''%s'' already exists in the local database and cannot be overwritten.\n', newName);
                end
                return
            else
                % Create paths to old and new material names
                fullpathOld = [localPath, '\', oldName, '.mat'];
                fullpathNew = [localPath, '\', newName, '.mat'];
                
                % Rename the material
                try
                    movefile(fullpathOld, fullpathNew)
                catch
                    if exist(fullpathOld, 'file') == 0.0
                        fprintf('ERROR: Could not rename ''%s'' because it does not exist in the local database.\n', newName);
                    else
                        fprintf('ERROR: Material name ''%s'' is invalid.\n', newName);
                    end
                    return
                end
            end
            
            % List materials in the local database
            material.list()
        end
        
        %% Delete material from local database
        function [] = remove(varargin)
            %MATERIAL.REMOVE    Remove material from the local database.
            %
            %   MATERIAL.REMOVE(VARARGIN) removes the materials specified
            %   with VARARGIN from the local database.
            %
            %   VARARGIN is specified as a series of strings:
            %   MATERIAL.REMOVE('material-1', 'material-2'..., 'material-n')
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            for i = 1:nargin
                materialToRemove = varargin{i};
                
                if strcmpi(materialToRemove(end - 3.0:end), '.mat') == 1.0
                    materialToRemove = materialToRemove(1.0:end - 4.0);
                end
                
                fullpath = [localPath, '\', materialToRemove, '.mat'];
                if exist(fullpath, 'file') ~= 0.0
                    delete(fullpath);
                else
                    fprintf('ERROR: Material ''%s'' does not exist in the local database.\n', materialToRemove);
                    return
                end
            end
            
            % List materials in the local database
            material.list()
        end
        
        %% Evaluate material in local database
        function [] = evaluate(userMaterial)
            %MATERIAL.EVALUATE    Evaluate material in the local database.
            %
            %   MATERIAL.EVALUATE(MATERIAL) evaluates the material MATERIAL
            %   in the local database.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            [error, ~] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            % Flag to prevent messages from being written
            setappdata(0, 'evaluateMaterialMessenger', 1.0)
            
            % Read material properties
            error = preProcess.getMaterial(userMaterial, 0.0, 1.0);
            
            % Remove flag
            rmappdata(0, 'evaluateMaterialMessenger')
            
            %{
                If the material has no regression model selected, abort the
                evaluation process and warn the user
            %}
            if getappdata(0, 'regressionModel') == 5.0
                msg1 = sprintf('ERROR: Material "%s" cannot be evaluated because it is not associated with a regression model.\n', userMaterial);
                msg2 = sprintf('Select a regression model using the drop-down menu in the ''Derivation'' region of the Material Editor, or using the keyword *REGRESSION.\n');
                fprintf([msg1, msg2])
                return
            end
            
            % Remove '.mat' extension
            userMaterial(end - 3.0:end) = [];
            
            % Create file name
            fileName = sprintf('Project/output/material_reports/%s_report.dat', userMaterial);
            
            % Write material evaluation results to file
            evaluateMaterial(fileName, userMaterial, error)
            
            if (error > 0.0)
                return
            end
            
            % User message
            message = sprintf('A material report has been written to ''%s''.', fileName);
            
            if (ispc == 1.0) && (ismac == 0.0)
                userResponse = questdlg(message, 'Quick Fatigue Tool', 'Open in MATLAB...',...
                    'Open in Windows...', 'Dismiss', 'Open in MATLAB...');
            elseif (ispc == 0.0) && (ismac == 1.0)
                userResponse = questdlg(message, 'Quick Fatigue Tool', 'Open in MATLAB...',...
                    'Dismiss', 'Open in MATLAB...');
            else
                userResponse = -1.0;
            end
            
            if strcmpi(userResponse, 'Open in MATLAB...')
                addpath('Project/output/material_reports')
                open(fileName)
            elseif strcmpi(userResponse, 'Open in Windows...')
                winopen(fileName)
            end
        end
        
        %% Copy material in local database
        function [] = copy(oldName, newName)
            %MATERIAL.COPY    Copy material in the local database.
            %
            %   MATERIAL.COPY(OLDNAME, NEWNAME) copies the material OLDNAME
            %   to the material NEWNAME.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            if strcmpi(oldName(end - 3.0:end), '.mat') == 1.0
                oldName = oldName(1.0:end - 4.0);
            end
            
            if strcmpi(newName(end - 3.0:end), '.mat') == 1.0
                newName = newName(1.0:end - 4.0);
            end
            
            % Check that the material name is valid
            if isempty(newName) == 1.0
                return
            elseif isempty(regexp(newName, '[/\\*:?"<>|]', 'once')) == 0.0
                fprintf('ERROR: The material name cannot contain any of the following characters: / \\ * : ? " < > |\n');
                return
            else
                % Check if the material already exists
                userMaterials = dir('Data/material/local/*.mat');
                
                for i = 1:length(userMaterials)
                    if strcmp([newName, '.mat'], userMaterials(i).name) == 1.0
                        fprintf('ERROR: ''%'' already exists in the local database and cannot be overwritten.\n', newName);
                        return
                    end
                end
            end
            
            % Save the new material
            oldPath = [localPath, '\', oldName, '.mat'];
            newPath = [localPath, '\', newName, '.mat'];
            
            try
                copyfile(oldPath, newPath)
            catch
                if exist(oldName, 'file') == 0.0
                    fprintf('ERROR: Material ''%s'' does not exist in the local database.\n', oldName);
                else
                    fprintf('ERROR: Could not copy ''%s''. The material name cannot contain any of the following characters: / \\ * : ? " < > |\n', newName);
                end
                return
            end
            
            % List materials in the local database
            material.list()
        end
        
        %% Query material in the local database
        function [] = query(material)
            %MATERIAL.QUERY    Query material in the local database.
            %
            %   MATERIAL.QUERY(MATERIAL) queries the material MATERIAL.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Check the local database
            [error, localPath] = material.checkDatabase();
            if error == 1.0
                return
            end
            
            if strcmpi(material(end - 3.0:end), '.mat') == 1.0
                material = material(1.0:end - 4.0);
            end
            
            % Get the material properties
            fullpath = [localPath, '\', material, '.mat'];
            if exist(fullpath, 'file') == 0.0
                fprintf('ERROR: Material ''%s'' does not exist in the local database.\n', material);
                return
            else
                load(fullpath)
            end
            
            if exist('material_properties', 'var') == 0.0
                fprintf('ERROR: ''%s'' contains inaccessible properties.\n', material);
            elseif isempty(material_properties.comment) == 1.0
                fprintf('No information available for ''%s''.\n', material);
            else
                fprintf('Information for material ''%s'': %s\n', material, material_properties.comment);
            end
        end
        
        %% Set the local database
        function [] = database(varargin)
            %MATERIAL.DATABASE    Set the local material database.
            %
            %   MATERIAL.DATABASE(PATH) sets the local material database
            %   path to PATH.
            %
            %   MATERIAL.DATABASE(PATH, SAVE) sets the local material
            %   database path to PATH, and writes the value of PATH to
            %   PATHDEF.m, where SAVE is a flag with a value of 1.0.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Initialize result flag
            result = 0.0;
            
            % Process arguments
            switch nargin
                case 0.0
                    fprintf('ERROR: Not enough input arguments.\n')
                    return
                case 1.0
                    path = varargin{1.0};
                    save = 0.0;
                case 2.0
                    path = varargin{1.0};
                    save = varargin{2.0};
                    
                    if (save ~= 0.0) && (save ~= 1.0)
                        fprintf('ERROR: The SAVE argument must be 0.0 or 1.0.\n')
                        return
                    end
                otherwise
                    fprintf('ERROR: Too many input arguments.\n')
                    return
            end
            
            % Check the input
            if exist(path, 'dir') ~= 7.0
                fprintf('ERROR: The specified path is inavlid.\n')
                return
            else
                setappdata(0, 'qft_localMaterialDataPath', path)
            end
            
            % Delete the old marker file if it exists
            currentPath = getappdata(0, 'currentLocalPath');
            if exist([currentPath, '\qft-local-material.txt'], 'file') == 2.0
                delete([currentPath, '\qft-local-material.txt'])
            end
            
            % Write the new marker file
            try
                fid = fopen([path, '\qft-local-material.txt'], 'w+');
                fclose(fid);
            catch exception
                fprintf('ERROR: An exception was encountered while setting the local material path.\n\nMATLAB returned the following error: %s\n', exception.message)
            end
            
            %{
                If the current local material path was written to PATHDEF.m,
                this should be removed from the file to preserve
                consistency and neatness.

                Next, try to add the local material directory to PATHDEF.m.
                This is an automatically generated file which contains the
                saved MATLAB path.
            %}
            try
                [~] = material.changeDatabase(currentPath, 'remove');
            catch exception
                fprintf('ERROR: An exception was encountered while saving the local material path.\n\nMATLAB returned the following error: %s\n', exception.message)
            end
            
            if save == 1.0
                try
                    result = material.changeDatabase(path, 'add');
                catch exception
                    fprintf('ERROR: An exception was encountered while saving the local material path.\n\nMATLAB returned the following error: %s\n', exception.message)
                end
            end
            
            % Set the current local path
            setappdata(0, 'currentLocalPath', path)
            
            % Warn the user if PATHDEF.m is unreadable
            if result == -1.0
                fprintf('ERROR: The string ''%%%% BEGIN ENTRIES %%%%'' could not be found in PATHDEF.m. The file has not been modified.\n');
                return
            end
            
            % List materials in the local database
            material.list()
        end
        
        %% Check the local database
        function [error, localPath] = checkDatabase()
            %MATERIAL.CHECKDATABASE    Check the local material database.
            %
            %   MATERIAL.CHECKDATABASE() checks if the local material
            %   database has been set. If it has not been set, the function
            %   checks for a marker file in case a previously defined
            %   database is available.
            %
            %   [ERROR, LOCALPATH] = MATERIAL.CHECKDATABASE() returns the
            %   error flag ERROR and the path LOCALPATH of the current
            %   material database. If the local material database is not
            %   set, ERROR has a value of 1.0.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            % Initialize the error flag
            error = 0.0;
            
            % Get the path to the current local material database
            localPath = getappdata(0, 'qft_localMaterialDataPath');
            
            if isempty(localPath) == 1.0
                % The default path is not set
                if exist('qft-local-material.txt', 'file') == 2.0
                    try
                        localPath = which('qft-local-material.txt');
                        [localPath, ~, ~] = fileparts(localPath);
                        
                        setappdata(0, 'qft_localMaterialDataPath', localPath)
                    catch
                        error = 1.0;
                    end
                else
                    error = 1.0;
                end
            end
            
            if error == 1.0
                % The local material database is currently undefined
                fprintf('ERROR: The local material database is undefined.\n')
                fprintf('Please specify the local material database with material.database(PATH).\n')
            end
        end
        
        %% Save the local material database to PATHDEF.m
        function [result] = changeDatabase(varargin)
            %MATERIAL.CHANGEDATABASE    Add/remove the local material
            %   database to/from PATHDEF.m.
            %
            %   MATERIAL.CHANGEDATABASE(VARARGIN) checks PATHDEF.m for a
            %   user-specified directory and adds or removes the directory
            %   from the file.
            %
            %   MATERIAL.CHANGEDATABASE(PATH, 'ADD') checks if PATH is
            %   already included in PATHDEF.m. If not, the file is
            %   re-written with this location included.
            %
            %   MATERIAL.CHANGEDATABASE(PATH, 'REMOVE') checks if PATH is
            %   already included in PATHDEF.m. If so, the file is
            %   re-written with this location removed.
            %
            %   RESULT = MATERIAL.CHANGEDATABASE(VARARGIN) returns a status
            %   flag. A value of 1.0 indicates that PATH was either added
            %   to, or removed from, PATHDEF.m. A value of 0.0 indicates
            %   that PATHDEF.m was not modified.
            %
            %   WARNING: This function modifies PATHDEF.m, which is an
            %   automatically generated MATLAB file. The user is strongly
            %   encouraged to keep a back-up of this file.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Process arguments
            switch nargin
                case 0.0
                    fprintf('ERROR: Not enough input arguments.\n')
                    return
                case 1.0
                    path = varargin{1.0};
                    mode = 'add';
                case 2.0
                    path = varargin{1.0};
                    mode = varargin{2.0};
                    
                    if strcmpi(mode, 'add') == 0.0 && strcmpi(mode, 'remove') == 0.0
                        fprintf('ERROR: The MODE argument must be ''ADD'' or ''REMOVE''.\n')
                        return
                    end
                otherwise
                    fprintf('ERROR: Too many input arguments.\n')
                    return
            end
            
            % Initialize output
            result = 0.0;
            
            % Remove spaces from PATH
            pathNS = path;
            pathNS(ismember(pathNS, ''' ;,.')) = [];
            
            % Read data from PATHDEF
            pathDefFiles = which('pathdef', '-ALL');
            pathDefFile = pathDefFiles{1.0};
            
            % READ FILE
            fid = fopen(pathDefFile);
            
            data = char(fread(fid, 'char')');
            fclose(fid);
            
            data(data == 13.0) = []; % Remove carriage returns
            
            % STRSPLIT2
            f = [0.0, strfind(data, 10.0), length(data) + 1.0];
            i0 = f(1:end - 1.0) + 1.0;
            i1 = f(2:end) - 1.0;
            n = length(f) - 1.0;
            data2 = cell(n, 1.0);
            for i=1:n
                data2{i} = data(i0(i):i1(i));
            end
            data = data2;
            
            % Remove spaces, colons and elipses from DATA
            L = length(data);
            dataNS = cell(L, 1.0);
            for i = 1:length(data)
                dataToEdit = data{i};
                dataToEdit(ismember(dataToEdit, ''' ;,.')) = [];
                dataNS{i} = dataToEdit;
            end
            
            %{
                Before writing the local material database path to
                PATHDEF.m, first parse the current path definition to check
                if the directory is already on the path
            %}
            cellfind = @(string)(@(cell_contents)(strcmp(string, cell_contents)));
            logical_cells = cellfun(cellfind(pathNS), dataNS);
            
            if strcmpi(mode, 'add') == 1.0
                %{
                    The function is in ADD mode. If the directory is
                    already on the path, RETURN. Else, find the INDEX where
                    the path definitions begin.
                %}
                if any(logical_cells) == 1.0
                    return
                else
                    % Open PATHDEF for reading
                    fid = fopen(pathDefFile, 'r');
                    
                    % Find the number of lines until the beginning of the path definition
                    keepGoing = 1.0;    index = 1.0;
                    while keepGoing == 1.0
                        tLine = fgetl(fid);
                        
                        if feof(fid) == 1.0
                            %{
                                The parser reached the end of the file
                                without finding the marker line.
                            %}
                            result = -1.0;
                            return
                        elseif strcmp(tLine, '%%% BEGIN ENTRIES %%%') == 1.0
                            break
                        end
                        
                        index = index + 1.0;
                    end
                    
                    % Close PATHDEF
                    fclose(fid);
                end
            else
                %{
                    The function is in REMOVE mode. Find the INDEX of the
                    path to be removed.
                %}
                if any(logical_cells) == 1.0
                    index = find(logical_cells == 1.0);
                else
                    return
                end
            end
            
            % Re-open PATHDEF for writing, discard existing contents
            fid = fopen(pathDefFile, 'wt');
            
            % Re-build PATHDEF from DATA
            if strcmpi(mode, 'add') == 1.0
                % Insert PATH
                fprintf(fid, '%s\n', data{1.0:index});
                fprintf(fid, '     ''%s;'', ...\n', path);
                fprintf(fid,'%s\n', data{(index + 1.0):end});
                fclose(fid);
            else
                % Omit PATH
                indexP = 1.0;
                for i = 1:length(index)
                    fprintf(fid, '%s\n', data{indexP:index(i) - 1.0});
                    indexP = index(i) + 1.0;
                end
                fprintf(fid,'%s\n', data{(index(end) + 1.0):end});
                fclose(fid);
            end
            
            %{
                Since the function did not RETURN, the result is that PATH
                was either added to, or removed from, PATHDEF.m.
            %}
            result = 1.0;
        end
        
        %% Search PATHDEF.m for DATA\MATERIAL\LOCAL
        function [localPath] = searchDatabase()
            %MATERIAL.SEARCHDATABASE    Searches PATHDEF.m for a local
            %   material database entry.
            %
            %   MATERIAL.SEARCHDATABASE() searches PATHDEF.m for an
            %   existing path to DATA\MATERIAL\LOCAL.
            %
            %   LOCALPATH = MATERIAL.SEARCHDATABASE() returns the default
            %   local material database path, if it exists.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Initialize output
            localPath = [];
            
            % Read data from PATHDEF
            pathDefFiles = which('pathdef', '-ALL');
            pathDefFile = pathDefFiles{1.0};
            
            % READ FILE
            fid = fopen(pathDefFile);
            
            data = char(fread(fid, 'char')');
            fclose(fid);
            
            data(data == 13.0) = []; % Remove carriage returns
            
            % STRSPLIT2
            f = [0.0, strfind(data, 10.0), length(data) + 1.0];
            i0 = f(1:end - 1.0) + 1.0;
            i1 = f(2:end) - 1.0;
            n = length(f) - 1.0;
            data2 = cell(n, 1.0);
            for i=1:n
                data2{i} = data(i0(i):i1(i));
            end
            data = data2;
            
            %{
                Before writing the local material database path to
                PATHDEF.m, first parse the current path definition to check
                if the directory is already on the path
            %}
            for i = 1:length(data);
                localPath = char(data{i});
                if isempty(strfind(localPath, 'Data\material\local')) == 0.0
                    break
                end
            end
            
            if isempty(localPath) == 0.0
                localPath(ismember(localPath, '''     ;'', ...')) = [];
            end
        end
        
        %% Remove the local material database
        function [] = resetDatabase()
            %MATERIAL.RESETDATABASE    Removes all references to the local
            %   material directory.
            %
            %   MATERIAL.RESETDATABASE() searches for references of the
            %   local material path in %APPDATA%, marker file(s) and
            %   PATHDEF.m, and removes these references if they exist.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            
            clc
            
            % Get the local path if it exists
            localPath = getappdata(0, 'qft_localMaterialDataPath');
            files = which('qft-local-material.txt', '-ALL');
            
            if (isempty(localPath) == 1.0) && (isempty(files) == 1.0)
                fprintf('ERROR: No local material database to remove.\n');
            else
                % Remove the local material path marker file(s) if applicable
                if isempty(files) == 0.0
                    for i = 1:length(files)
                        %{
                            Remove any database entries from PATHDEF.m
                            which point to FILES
                        %}
                        [path, ~, ~] = fileparts(files{i});
                        
                        if strcmpi(path, [pwd, '\Data\material\local']) == 0.0
                            [~] = material.changeDatabase(path, 'remove');
                        end
                    end
                    
                    delete(files{:})
                end
                
                % Clear local material path %APPDATA% entry if applicable
                if isempty(localPath) == 0.0
                    rmappdata(0, 'qft_localMaterialDataPath')
                    
                    %{
                        Remove any database entries from PATHDEF.m which
                        point to LOCALPATH
                    %}
                    if strcmpi(localPath, [pwd, '\Data\material\local']) == 0.0
                        [~] = material.changeDatabase(localPath, 'remove');
                    end
                    
                    fprintf('The following local database path has been removed:\n''%s''\n', localPath);
                end
            end
        end
    end
end