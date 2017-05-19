classdef material < handle
%MATERIAL    QFT class for material data processing.
%   This class contains methods for pre-analysis processing tasks.
%   
%   Functions in MATERIAL are used to replicate the behaviour of the 
%   Material Manager GUI.
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 15-May-2017 08:49:00 GMT
    
    %%
    
    methods(Static = true)
        %% List materials in local database
        function [] = list()
            %MATERIAL.LIST    List materials in the local database.
            %   This function lists the materials saved in the local
            %   material databse.
            %
            %   MATERIAL.LIST() is called without arguments.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            localMaterials = dir([pwd, '\Data\material\local\*.mat']);
            
            fprintf('Materials in local database:\n\n')
            
            if isempty(localMaterials) == 1.0
                fprintf('(none)\n')
            else
                for i = 1:length(localMaterials)
                    fprintf('%s\n', localMaterials(i).name(1.0:end - 4.0))
                end
            end
        end
        
        %% Import material into local database from text file
        function [] = import(material)
            %MATERIAL.IMPORT    QFT function to import material text file.
            %   This function imports a material text file into the local
            %   material database.
            %
            %   MATERIAL.IMPORT(MATERIAL) imports material data from a text
            %   file 'MATERIAL.*' containing valid material definitioins.
            %   The file must begin and end with the keywords
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
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            setappdata(0, 'materialManagerImport', 1.0)
            
            % Check that the material exists
            if exist(material, 'file') == 0.0
                fprintf('ERROR: Unable to locate material ''%s''\n', material)
                return
            end
            
            [error, material_properties, materialName, ~, ~] = importMaterial.processFile(material, -1.0); %#ok<ASGLU>
            
            if exist(['Data/material/local/', materialName, '.mat'], 'file') == 2.0
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
                    movefile(['Data/material/local/', materialName, '.mat'], ['Data/material/local/', oldMaterial, '.mat'])
                end
            end
            
            % Save the material
            try
                save(['Data/material/local/', materialName], 'material_properties')
            catch
                fprintf('ERROR: Unable to save material ''%s''. Make sure the material save location has read/write access\n', materialName)
                return
            end
        end
        
        %% Edit material in local database
        function [] = edit(material)
            %MATERIAL.EDIT    Edit material in the local database.
            %   This function opens the material editor GUI for a selected
            %   material in the local database.
            %
            %   MATERIAL.EDIT(MATERIAL) edits the material MATERIAL.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            if strcmpi(material(end - 3.0:end), '.mat') == 1.0
                material = material(1.0:end - 4.0);
            end
            
            setappdata(0, 'editMaterial', 1.0)
            
            setappdata(0, 'materialToEdit', material)
            UserMaterial
        end
        
        %% Rename material in local database
        function [] = rename(oldName, newName)
            %MATERIAL.RENAME    Rename material in the local database.
            %   This function renames a material in the local database.
            %
            %   MATERIAL.RENAME(OLDNAME, NEWNAME) renames the material
            %   OLDNAME to the material NEWNAME.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            if isempty(newName) == 1.0
                return
            elseif isempty(regexp(newName, '[/\\*:?"<>|]', 'once')) == 0.0
                fprintf('The material name cannot contain any of the following characters: / \\ * : ? " < > |\n');
                return
            elseif strcmp(newName, oldName) == 1.0
                % Material already exists
                if exist([newName, '.mat'], 'file') == 0.0
                    fprintf('Could not rename %s because it no longer exists in the local database.\n', oldName);
                else
                    fprintf('%s already exists in the local database and cannot be overwritten.\n', newName);
                end
                return
            else
                % Create paths to old and new material names
                fullpathOld = [pwd, '\Data\material\local\', oldName, '.mat'];
                fullpathNew = [pwd, '\Data\material\local\', newName, '.mat'];
                
                % Rename the material
                try
                    movefile(fullpathOld, fullpathNew)
                catch
                    if exist(fullpathOld, 'file') == 0.0
                        fprintf('Could not rename %s because it does not exist in the local database.\n', newName);
                    else
                        fprintf('Material name %s is invalid.\n', newName);
                    end
                    return
                end
            end
        end
        
        %% Delete material from local database
        function [] = remove(material)
            %MATERIAL.REMOVE    Remove material in the local database.
            %   This function removes a material in the local database.
            %
            %   MATERIAL.REMOVE(MATERIAL) removes the material MATERIAL
            %   from the local database.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            
            if strcmpi(material(end - 3.0:end), '.mat') == 1.0
                material = material(1.0:end - 4.0);
            end
            
            fullpath = [pwd, '\Data\material\local\', material, '.mat'];
            if exist(fullpath, 'file') ~= 0.0
                delete(fullpath);
            else
                fprintf('Could not delete %s because it does not exist in the local database.\n', material);
            end
        end
        
        %% Evaluate material in local database
        function [] = evaluate(material)
            %MATERIAL.EVALUATE    Evaluate material in the local database.
            %   This function evaluates a material in the local database.
            %
            %   MATERIAL.EVALUATE(MATERIAL) evaluates the material MATERIAL
            %   in the local database.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            
            % Flag to prevent messages from being written
            setappdata(0, 'evaluateMaterialMessenger', 1.0)
            
            % Read material properties
            error = preProcess.getMaterial(material, 0.0, 1.0);
            
            % Remove flag
            rmappdata(0, 'evaluateMaterialMessenger')
            
            % Remove '.mat' extension
            material(end - 3.0:end) = [];
            
            % Create file name
            fileName = sprintf('Project/output/material_reports/%s_report.dat', material);
            
            % Write material evaluation results to file
            evaluateMaterial(fileName, material, error)
            
            if (error > 0.0)
                return
            end
            
            % User message
            message = sprintf('A material report has been written to %s.', fileName);
            
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
            %   This function copies a material in the local database.
            %
            %   MATERIAL.COPY(OLDNAME, NEWNAME) copies the material OLDNAME
            %   to the material NEWNAME.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            
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
                fprintf('The material name cannot contain any of the following characters: / \\ * : ? " < > |\n');
                return
            else
                % Check if the material already exists
                userMaterials = dir('Data/material/local/*.mat');
                
                for i = 1:length(userMaterials)
                    if strcmp([newName, '.mat'], userMaterials(i).name) == 1.0
                        fprintf('%s already exists in the local database and cannot be overwritten.\n', newName);
                        return
                    end
                end
            end
            
            % Save the new material
            oldPath = ['Data\material\local\', oldName, '.mat'];
            newPath = ['Data\material\local\', newName, '.mat'];
            
            try
                copyfile(oldPath, newPath)
            catch
                if exist(oldName, 'file') == 0.0
                    fprintf('Could not copy %s because it does not exist in the local database.\n', oldName);
                else
                    fprintf('Could not copy %s. Make sure the material name does not contain any illegal characters.\n', newName);
                end
                return
            end
        end
        
        %% Query material in the local database
        function [] = query(material)
            %MATERIAL.QUERY    Query material in the local database.
            %   This function queries a material in the local database.
            %
            %   MATERIAL.QUERY(MATERIAL) queries the material MATERIAL.
            %
            %   Reference section in Quick Fatigue Tool User Guide
            %      5 Materials
            %
            %   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
            %   Last modified 04-Apr-2017 13:26:59 GMT
            
            clc
            
            if strcmpi(material(end - 3.0:end), '.mat') == 1.0
                material = material(1.0:end - 4.0);
            end
            
            % Get the material properties
            fullpath = ['Data\material\local\', material, '.mat'];
            if exist(fullpath, 'file') == 0.0
                fprintf('Could not query ''%s'' because the file does not exist in the local database.\n', material);
                return
            else
                load(fullpath)
            end
            
            if exist('material_properties', 'var') == 0.0
                fprintf('Error whilst reading ''%s''. Properties are inaccessible.\n', material);
            elseif isempty(material_properties.comment) == 1.0
                fprintf('No information available for %s.\n', material);
            else
                fprintf('Information for material ''%s'': %s\n', material, material_properties.comment);
            end
        end
    end
end