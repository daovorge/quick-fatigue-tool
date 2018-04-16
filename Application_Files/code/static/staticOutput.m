classdef staticOutput < handle
%STATICOUTPUT    QFT class to export static analysis results to an ODB file.
%   
%   STATICOUTPUT is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also yieldCriterion, compositeFailure, LaRC05.
%
%   Reference section in Quick Fatigue Tool User Guide
%      12.2 Yield criteria
%      12.3 Composite failure criteria
%   
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 12-Apr-2018 09:52:19 GMT
    
    %%
    
    methods(Static = true)
        %% Write composite results field data to an .ODB file
        function [] = exportODB(fid_status, mainID, yieldOrComposite)
            %% Pre-processing tasks
            % Flag to indicate the ODB Interface is operating in auto mode
            setappdata(0, 'ODB_interface_auto', 1.0)
            
            % Get path and name of field data
            if yieldOrComposite == 1.0
                fieldDataPath = [getappdata(0, 'outputDirectory'), 'Data Files/yield_assessment.dat'];
            else
                fieldDataPath = [getappdata(0, 'outputDirectory'), 'Data Files/composite_criteria.dat'];
            end
            
            [~, fieldDataName, EXT] = fileparts(fieldDataPath);
            fieldDataName = [fieldDataName, EXT];
            
            % Get the abaqus command line
            abqCmd = getappdata(0, 'autoExport_abqCmd');
            if isempty(abqCmd) == 1.0
                abqCmd = 'abaqus';
            end
            
            % Get path and name of model output database
            modelDatabasePath = getappdata(0, 'outputDatabase');
            if isempty(modelDatabasePath) == 1.0
                messenger.writeMessage(33.0)
                return
            elseif exist(modelDatabasePath, 'file') ~= 2.0
                setappdata(0, 'autoExport_modelDatabaseNotFound', modelDatabasePath)
                messenger.writeMessage(81.0)
                return
            end
            [~, modelDatabaseNameShort, ~] = fileparts(modelDatabasePath);
            
            % Print header
            fprintf('\n[POST] Quick Fatigue Tool 6.12-00 ODB Interface');
            fprintf(fid_status, '\n[POST] Quick Fatigue Tool 6.12-00 ODB Interface');
            
            % Warn user if there is only one item in the model
            if length(mainID) == 1.0
                messenger.writeMessage(204.0)
            end
            
            % Get the job name
            jobName = getappdata(0, 'jobName');
            
            % Get name and directory of results output database
            resultsDatabasePath = [getappdata(0, 'outputDirectory'), 'Data Files'];
            resultsDatabaseName = [modelDatabaseNameShort, sprintf('_%s', jobName), 'Results'];
            
            % Get the part instance name
            partInstanceList = getappdata(0, 'partInstance');
            if ischar(partInstanceList) == 1.0
                partInstanceList = cellstr(partInstanceList);
            end
            
            % Get the number of part instances
            nInstances = length(partInstanceList);
            
            % Get the step type
            stepType_m = getappdata(0, 'autoExport_stepType');
            if (stepType_m ~= 1.0) && (stepType_m ~= 2.0)
                stepType_m = 1.0;
            end
            
            if stepType_m == 1.0
                if nInstances > 1.0
                    stepType_m = [1.0, linspace(2.0, 2.0, (nInstances - 1.0))];
                else
                    stepType_m = 1.0;
                end
            else
                stepType_m = linspace(2.0, 2.0, nInstances);
            end
            
            % Get the ODB set settings
            if nInstances > 1.0
                createODBSet = 0.0;
            elseif getappdata(0, 'autoExport_createODBSet') == 1.0
                createODBSet = 1.0;
            else
                createODBSet = 0.0;
            end
            
            % Get the step name
            stepName = getappdata(0, 'stepName');
            
            % Open the log file for writing
            debugFileName = [sprintf('Project/output/%s/Data Files/', jobName), resultsDatabaseName, '.log'];
            fid_debug = fopen(debugFileName, 'w+');
            fprintf(fid_debug, 'Quick Fatigue Tool 6.12-00 ODB Interface Log');
            
            %% Print Abaqus installation info to the debug log file
            try
                [status, message] = system(sprintf('%s whereami', abqCmd));
                
                if status == 1.0
                    % An exception occurred whilst getting installation info
                    fprintf(fid_debug, '\r\n\r\n[QFT Error]: Abaqus installation info was not found\r\n');
                    fprintf(fid_debug, '\tPlease ensure that the Abaqus command line argument points to a valid Abaqus batch file');
                    fprintf(fid_debug, '\r\n\tAn Abaqus installation is required to write fatigue results to the output database (.odb) file');
                else
                    fprintf(fid_debug, '\r\n\r\nAbaqus installation info:\r\n%s', message);
                    fprintf(fid_debug, '(NOTE: The Abaqus version is determined by the autoExport_abqCmd environment variable)\r\n');
                end
            catch exception
                % An unhandled exception was encountered
                fprintf(fid_debug, '\n[Abaqus Error]: %s', exception.message);
                fprintf('\n[ERROR] ODB Interface exited with errors');
                fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors');
                fprintf(fid_debug, '\n\nRESULTS WERE NOT WRITTEN TO THE OUTPUT DATABASE');
                return
            end
            
            %% Verify the inputs
            error = python.verifyAuto(1.0, fieldDataPath, fieldDataName,...
                resultsDatabasePath, partInstanceList);
            
            % If there was an error whilst verifying the inputs, stop execution
            if error == 1.0
                return
            end
            
            % Copy the model output database to the abaqus directory
            % Try to upgrade the ODB
            if getappdata(0, 'autoExport_upgradeODB') == 1.0
                [status, message] = system(sprintf('%s -upgrade -job "%s" -odb "%s"', abqCmd, [resultsDatabasePath, '/', resultsDatabaseName], modelDatabasePath(1.0:end - 4.0)));

                if status == 1.0
                    % An exception occurred whilst upgrading the ODB file
                    fprintf(fid_debug, '\n[Abaqus Error]: %s', message);
                    
                    if isempty(strfind(message, 'is not recognized as an internal or external command,')) == 0.0
                        % There is no Abaqus executable on the host machine
                        fprintf(fid_debug, '\n[QFT Error]: The Abaqus command ''%s'' could not be found on the system. Check your Abaqus installation. Results will not be written to the output database.', abqCmd);
                    end
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_debug, '\n\nRESULTS WERE NOT WRITTEN TO THE OUTPUT DATABASE');
                    return
                elseif strcmp(message, sprintf('ODB FILE UPGRADE COMPLETED\n')) == 1.0
                    fprintf(fid_debug, '\n%s', message);
                end
            end
            
            % If the ODB is already up-to-date, try to copy the file instead
            if exist([resultsDatabasePath, '/', resultsDatabaseName, '.odb'], 'file') == 0.0
                try
                    copyfile(modelDatabasePath, [resultsDatabasePath, '/', resultsDatabaseName, '.odb'])
                catch exception
                    % The file could not be copied
                    fprintf(fid_debug, '\n[Abaqus Error]: %s', exception.message);
                    fprintf(fid_debug, '\nThe cause of this error could not be determined. Please contact the developer at louisvallance@hotmail.co.uk for further assistance.');
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_debug, '\n\nRESULTS WERE NOT WRITTEN TO THE OUTPUT DATABASE');
                    return
                end
            end
            
            % Delete the upgrade log file
            delete([resultsDatabasePath, '/', resultsDatabaseName, '-upgrade', '.log'])
            if exist([pwd, '\', modelDatabaseNameShort, '-upgrade', '.log'], 'file') == 2.0
                delete([pwd, '\', modelDatabaseNameShort, '-upgrade', '.log'])
            end
            
            % Remove the lock file if it exists
            if exist([resultsDatabasePath, '/', modelDatabaseNameShort, '.lck'], 'file') == 2.0
                delete([resultsDatabasePath, '/', modelDatabaseNameShort, '.lck'])
            end
            
            %% Get the selected position
            userPosition = getappdata(0, 'odbResultPosition');
            if strcmpi('unique nodal', userPosition) == 1.0
                userPosition = 2.0;
            elseif strcmpi('integration point', userPosition) == 1.0
                userPosition = 3.0;
            elseif strcmpi('centroid', userPosition) == 1.0
                userPosition = 4.0;
            else
                userPosition = 1.0;
            end
            if ischar(userPosition) == 0.0
                if (userPosition ~= 1.0) && (userPosition ~= 2.0) && (userPosition ~= 3.0) && (userPosition ~= 4.0)
                    userPosition = 1.0;
                end
            end
            
            positions = {'Element-Nodal', 'Unique Nodal', 'Integration Point', 'Centroidal'};
            fprintf(fid_debug, '\r\n\r\nUser-selected results position: %s', positions{userPosition});
            fprintf('\n[POST] User-selected results position: %s', positions{userPosition});
            fprintf(fid_status, '\n[POST] User-selected results position: %s', positions{userPosition});
            
            % Check if position should be determined automatically
            autoPosition = getappdata(0, 'autoExport_autoPosition');
            if autoPosition == 1.0
                fprintf(fid_debug, '\r\nAllow Quick Fatigue Tool to determine results position based on field IDs: YES');
            else
                fprintf(fid_debug, '\r\nAllow Quick Fatigue Tool to determine results position based on field IDs: NO');
            end
            
            if isempty(stepName) == 1.0
                fprintf(fid_debug, '\r\nThe step name was not specified (a default name will be used)');
            else
                fprintf(fid_debug, '\r\nStep name: ''%s''', stepName);
            end
            
            if yieldOrComposite == 1.0                    
                fprintf(fid_debug, '\r\nField output request: YIELD COMPONENTS ONLY');
            else
                fprintf(fid_debug, '\r\nField output request: COMPOSITE FAILURE MEASURE / DAMAGE INITIATION COMPONENTS ONLY');
            end
            
            for instanceNumber = 1:nInstances
                partInstanceName = partInstanceList{instanceNumber};
                stepType = stepType_m(instanceNumber);
                
                % Get the field data
                if yieldOrComposite == 1.0
                    string = 'yield';
                else
                    string = 'composite';
                end
                fprintf(fid_debug, '\r\n\r\nCollecting %s field data for instance ''%s''...', string, partInstanceName);
                fprintf('\n[POST] Collecting %s field data for instance ''%s''', string, partInstanceName);
                fprintf(fid_status, '\n[POST] Collecting %s field data', string);
                
                [positionLabels, position, positionLabelData, positionID, connectivity,...
                    mainIDs, subIDs, stepDescription, fieldData, fieldNames, fieldDescriptions,...
                    connectedElements, error] = staticOutput.getFieldData(fieldDataPath,...
                    userPosition, partInstanceName, autoPosition,...
                    fid_debug, resultsDatabasePath, resultsDatabaseName,...
                    yieldOrComposite);
                
                if error > 0.0
                    switch error
                        case 1.0
                            fprintf(fid_debug, 'No matching position labels were found in the model output database. Check the log file for details.');
                        case 2.0
                            fprintf(fid_debug, 'An error occurred while retrieving the connectivity matrix. Check the log file for details.');
                        case 3.0
                            fprintf(fid_debug, 'An error occurred while reading the connectivity matrix. Check the log file for details.');
                        case 4.0
                            fprintf(fid_debug, 'An error occurred while reading the field data file. Check the log file for details.');
                        case 5.0
                            fprintf(fid_debug, 'No matching position labels were found in the model output database. Check the log file for details.');
                    end
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_debug, '\n\nRESULTS WERE NOT WRITTEN TO THE OUTPUT DATABASE');
                    
                    % Delete the results output database from the output directory if applicable
                    if exist([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)], 'file') == 2.0
                        delete([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)])
                    end
                    
                    fclose(fid_debug);
                    return
                end
                
                %% Create the Python script
                fprintf(fid_debug, '\r\n\r\nPreparing field data...');
                fprintf('\n[POST] Preparing field data:\n');
                fprintf(fid_status, '\n[POST] Preparing field data\n');
                
                % Determine whether the FEA was from an Abaqus/Explicit procedure
                isExplicit = getappdata(0, 'isExplicit');
                if isnumeric(isExplicit) == 0.0
                    isExplicit = 0.0;
                end
                
                % Get ODB set name (if applicable)
                ODBSetName = getappdata(0, 'autoExport_ODBSetName');
                if createODBSet == 1.0
                    if isempty(ODBSetName) == 1.0
                        ODBSetName = sprintf('QFT_%s_%s', partInstanceName, stepName);
                    end
                    if ischar(ODBSetName) == 0.0
                        ODBSetName = sprintf('QFT_%s_%s', partInstanceName, stepName);
                    end
                end
                
                % Write the Python script
                [scriptFile, newLocation, stepName, error] = python.writePythonScript(resultsDatabaseName,...
                    resultsDatabasePath, partInstanceName, positionLabels,...
                    position, positionLabelData, positionID, connectivity, mainIDs,...
                    subIDs, stepDescription, fieldData, fieldNames, fieldDescriptions, fid_debug,...
                    stepName, isExplicit, connectedElements, createODBSet,...
                    ODBSetName, stepType);
                
                %{
                    If the analysis is a yield criterion assessment, the
                    user might choose to conitnue the analysis. This will
                    ead to a an error when the same step name is used, so
                    update the step name now just to be safe
                %}
                if yieldOrComposite == 1.0
                    setappdata(0, 'stepName', [stepName, '_1'])
                end
                
                % If there was an error while writing the field data, abort the export process
                if (error == 1.0) || (error == 2.0)
                    if error == 1.0
                        setappdata(0, 'warning_087_partInstance', partInstanceName)
                        messenger.writeMessage(87.0)
                    elseif error == 2.0
                        messenger.writeMessage(179.0)
                    end
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                    fprintf(fid_debug, '\n\nRESULTS WERE NOT WRITTEN TO THE OUTPUT DATABASE');
                    
                    fclose(fid_debug);
                    return
                end
                
                if getappdata(0, 'warning_180') == 1.0
                    messenger.writeMessage(180.0)
                    postProcess.writeCollapsedElements()
                end
                
                %{
                    If the user requested to retain the python script, copy
                    the file to the results database directory
                %}
                if getappdata(0, 'autoExport_executionMode') > 1.0
                    if nInstances > 1.0
                        copyfile(scriptFile, [resultsDatabasePath, '/', resultsDatabaseName, sprintf('_%s', partInstanceName), '.py'])
                    else
                        copyfile(scriptFile, [resultsDatabasePath, '/', resultsDatabaseName, '.py'])
                    end
                end
                
                %% System command to execute python script
                if getappdata(0, 'autoExport_executionMode') < 3.0
                    fprintf(fid_debug, '\r\n\r\nWriting field data to ODB...');
                    fprintf('[POST] Writing field data to ODB');
                    fprintf(fid_status, '[POST] Writing field data to ODB');
                    
                    try
                        [~, message] = system(sprintf('%s python %s', abqCmd, scriptFile));
                        
                        if isempty(message) == 0.0
                            fprintf(fid_debug, '\n[Abaqus Error]: %s', message);
                            
                            if isempty(strfind(message, sprintf('KeyError: ''%s''', stepName))) == 0.0
                                % The step name is invalid
                                fprintf(fid_debug, '\n[QFT Error]: The step name ''%s'' could not be found in the ODB. Results will not be written to the output database.', stepName);
                            elseif isempty(strfind(message, sprintf('KeyError: ''%s''', partInstanceName))) == 0.0
                                % The part instance name is invalid
                                fprintf(fid_debug, '\n[QFT Error]: The part instance name ''%s'' could not be found in the ODB. Results will not be written to the output database.', partInstanceName);
                            elseif isempty(strfind(message, 'OdbError: Invalid node label')) == 0.0
                                %{
                                    The field data does not exactly match
                                    the part instance name, so an ODB
                                    element/node set could not be created
                                %}
                                fprintf(fid_debug, '\n[QFT Error]: The ODB element/node set could not be written because the field data does not exactly match the specified part instance. Results will not be written to the output database.');
                            elseif isempty(strfind(message, 'is not recognized as an internal or external command')) == 0.0
                                % There is no Abaqus executable on the host machine
                                fprintf(fid_debug, '\n[QFT Error]: The Abaqus command ''%s'' could not be found on the system. Check your Abaqus installation. Results will not be written to the output database.', abqCmd);
                            elseif isempty(strfind(message, 'OdbError: illegal argument type for built-in operation')) == 0.0
                                % There is no Abaqus executable on the host machine
                                fprintf(fid_debug, '\n[QFT Error]: The Abaqus API rejected the fatigue results data. For element-nodal and integration point data, results for at least one element are required. For centroidal and unique-nodal data, results for at least two centroids or nodes are required, respectively.');
                            elseif isempty(strfind(message, sprintf('OdbError: A Step named "%s" already exists.', stepName))) == 0.0
                                % Abaqus tried to create a step whose name already exists in the .odb file
                                fprintf(fid_debug, '\n[QFT Error]: Abaqus does not permit more than one step to have the same name. Use the STEP_NAME option to define a step that does not already exist in the output database.');
                            elseif isempty(strfind(message, 'AbaqusException: Interaction cannot be used with the current procedure')) == 0.0
                                % Fatigue results are being written to an Abaqus/Explicit step
                                fprintf(fid_debug, '\n[QFT Error]: The Abaqus API rejected the fatigue results data. If the model output database contains results from an Abaqus/Explicit analysis procedure, then EXPLICIT_FEA=1 must be set in the job file.');
                            else
                                % Unkown exception
                                fprintf(fid_debug, '\nThe cause of this error could not be determined. Please contact the developer at louisvallance@hotmail.co.uk for further assistance.');
                            end
                            
                            if getappdata(0, 'autoExport_executionMode') == 1.0
                                delete(scriptFile)
                            end
                            
                            % Delete the results output database from the output directory if applicable
                            if exist([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)], 'file') == 2.0
                                delete([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)])
                            end
                            
                            fprintf('\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName');
                            fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                            fprintf(fid_debug, '\n\nRESULTS WERE NOT WRITTEN TO THE OUTPUT DATABASE');
                            return
                        end
                    catch unhandledException
                        fprintf(fid_debug, '\r\nError: %s', unhandledException.message);
                        fprintf('\n[POST] [QFT Error]: An unknown exception was encountered while writing field data to the output database. Please contact the developer at louisvallance@hotmail.co.uk for further assistance')
                        fprintf('\n[ERROR] ODB Interface exited with errors. Check %s for details', debugFileName);
                        messenger.writeMessage(86.0)
                        
                        fclose(fid_debug);
                        
                        if getappdata(0, 'autoExport_executionMode') == 1.0
                            delete(scriptFile)
                        end
                        return
                    end
                elseif instanceNumber == nInstances
                    delete(newLocation)
                end
            end
            
            %% Additional tasks
            fprintf(fid_debug, ' Success\r\n\r\nFatigue results have been written to ''%s''', sprintf('%s/%s.odb', resultsDatabasePath, resultsDatabaseName));
            fprintf(fid_debug, '\r\n\r\nEND OF FILE');
            fprintf('\n[POST] Export complete. Check %s for details ', debugFileName);
            fprintf(fid_status, '\n[POST] Export complete. Check %s for details', debugFileName);
            fclose(fid_debug);
            
            % Update the message file
            messenger.writeMessage(265.0)
            
            % Delete the Python script from the data directory
            delete(scriptFile)
            
            % Copy the results ODB path to the clipboard
            clipboard('copy', [pwd, sprintf('/Project/output/%s/Data Files/%s.odb', jobName, resultsDatabaseName)])
        end
        
        %% Obtain field data from analysis results
        function [positionLabels, position, positionLabelData,...
                positionID, connectivity, mainIDs, subIDs, stepDescription,...
                fieldData, fieldNames, fieldDescriptions, connectedElements, error] = getFieldData(fieldDataPath,...
                userPosition, partInstanceName, autoPosition, fid_debug,...
                resultsDatabasePath, resultsDatabaseName, yieldOrComposite)
            
            error = 0.0;
            connectedElements = [];
            
            %% Collect field data columns in cells
            fieldDataFile = importdata(fieldDataPath, '\t');
            
            %% Get the position labels
            try
                positionLabels = fieldDataFile.data(:, 1:2);
            catch unhandledException
                fprintf(fid_debug, '\r\n\t\tError: Field data file does not contain field information');
                fprintf(fid_debug, '\r\n\t\tError: %s', unhandledException.message);
                
                error = 4.0;
                positionLabels = 0.0;
                position = 0.0;
                positionLabelData = 0.0;
                positionID = 0.0;
                connectivity = 0.0;
                mainIDs = 0.0;
                subIDs = 0.0;
                stepDescription = 0.0;
                fieldData = 0.0;
                fieldNames = 0.0;
                fieldDescriptions = 0.0;
                return
            end
            
            % Extract the main IDs
            mainIDs = positionLabels(:, 1.0);
            subIDs = positionLabels(:, 2.0);
            
            %% Determine the position of the field data
            %{
                Centroidal or Unique Nodal:
                1.1
                2.1
                3.1
                .
                N.1
            %}
            if autoPosition == 1.0
                if all(subIDs == 1.0) == 1.0 || length(subIDs) == 1.0
                    % Write information to log file
                    if length(subIDs) == 1.0
                        fprintf(fid_debug, '\r\n\tOnly one item detected in the field data');
                    else
                        fprintf(fid_debug, '\r\n\tBased on field IDs, data is either NODAL or CENTROID');
                    end
                    
                    % Data is centroidal or unique nodal
                    if userPosition == 2.0
                        position = 'NODAL';
                        positionID = 1.0;
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as NODAL');
                    elseif userPosition == 4.0
                        position = 'CENTROID';
                        positionID = 4.0;
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as CENTROID');
                    else
                        position = 'NODAL';
                        positionID = 1.0;
                        
                        fprintf(fid_debug, '\r\n\tWarning: User-selected position does not match format of data: field data will be read as NODAL');
                    end
                    
                    positionLabels = mainIDs;
                    connectivity = 0.0;
                    
                    fprintf(fid_debug, '\r\n\tTaking position labels from field data main IDs');
                    fprintf(fid_debug, '\r\n\tThe nodal connectivity matrix is not required');
                else
                    % Data is element-nodal or integration point
                    if userPosition == 1.0
                        position = 'ELEMENT_NODAL';
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as ELEMENT_NODAL');
                        positionID = 2.0;
                        
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getNodalConnectivity(partInstanceName, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            fieldDescriptions = 0.0;
                            return
                        end
                        
                        connectivity = connectivityData.nodes;
                    elseif userPosition == 3.0
                        position = 'INTEGRATION_POINT';
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as INTEGRATION_POINT');
                        positionID = 3.0;
                        
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getIntegrationPointConnectivity(partInstanceName, mainIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            fieldDescriptions = 0.0;
                            return
                        end
                        
                        connectivity = connectivityData.nodes;
                    else
                        position = 'ELEMENT_NODAL';
                        
                        fprintf(fid_debug, '\r\n\tWarning: User-selected position does not match format of data: field data will be read as ELEMENT_NODAL');
                        positionID = 2.0;
                        
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getNodalConnectivity(partInstanceName, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            fieldDescriptions = 0.0;
                            return
                        end
                        
                        connectivity = connectivityData.nodes;
                    end
                    
                    fprintf(fid_debug, '\r\n\tTaking position labels from ODB element listing');
                    positionLabels = connectivityData.elements;
                end
            else
                switch userPosition
                    case 1.0
                        position = 'ELEMENT_NODAL';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as ELEMENT_NODAL');
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getNodalConnectivity(partInstanceName, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            fieldDescriptions = 0.0;
                            return
                        end
                        
                        fprintf(fid_debug, '\r\n\tTaking position labels from ODB element listing');
                        positionLabels = connectivityData.elements;
                        connectivity = connectivityData.nodes;
                        positionID = 2.0;
                    case 2.0
                        position = 'NODAL';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as NODAL');
                        fprintf(fid_debug, '\r\n\tTaking position labels from field data main IDs');
                        fprintf(fid_debug, '\r\n\tThe nodal connectivity matrix is not required');
                        positionLabels = mainIDs;
                        connectivity = 0.0;
                        positionID = 1.0;
                    case 3.0
                        position = 'INTEGRATION_POINT';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as INTEGRATION_POINT');
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getIntegrationPointConnectivity(partInstanceName, mainIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            fieldDescriptions = 0.0;
                            return
                        end
                        
                        fprintf(fid_debug, '\r\n\tTaking position labels from ODB element listing');
                        positionLabels = connectivityData.elements;
                        connectivity = connectivityData.nodes;
                        positionID = 3.0;
                    case 4.0
                        position = 'CENTROID';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as CENTROID');
                        fprintf(fid_debug, '\r\n\tTaking position labels from field data main IDs');
                        fprintf(fid_debug, '\r\n\tThe nodal connectivity matrix is not required');
                        positionLabels = mainIDs;
                        connectivity = 0.0;
                        positionID = 4.0;
                end
            end
            
            if isempty(positionLabels) == 1.0
                fprintf(fid_debug, '\r\n\tError: No matching position labels were found from the model output database');
                error = 1.0;
                positionLabels = 0.0;
                position = 0.0;
                positionLabelData = 0.0;
                positionID = 0.0;
                connectivity = 0.0;
                mainIDs = 0.0;
                subIDs = 0.0;
                stepDescription = 0.0;
                fieldData = 0.0;
                fieldNames = 0.0;
                fieldDescriptions = 0.0;
                return
            end
            
            fprintf(fid_debug, '\r\n\tGenerating position labels...');
            positionLabelData = '(';
            if strcmpi(position, 'ELEMENT_NODAL') == 1.0
                for i = 1:length(connectedElements)
                    if i == length(connectedElements)
                        positionLabelData = [positionLabelData, sprintf('%.0f)', connectedElements(i))]; %#ok<AGROW>
                        break
                    end
                    
                    positionLabelData = [positionLabelData, sprintf('%.0f, ', connectedElements(i))]; %#ok<AGROW>
                end
            else
                for i = 1:length(positionLabels)
                    if i == length(positionLabels)
                        positionLabelData = [positionLabelData, sprintf('%.0f)', positionLabels(i))]; %#ok<AGROW>
                        break
                    end
                    
                    positionLabelData = [positionLabelData, sprintf('%.0f, ', positionLabels(i))]; %#ok<AGROW>
                end
            end
            
            %% Get step description
            [job, loading] = fieldDataFile.textdata{2:3};
            stepDescription = ['version 6.12-00; ', job, ', ', loading];
            
            if yieldOrComposite == 1.0
                %% Get yield criterion name
                switch getappdata(0, 'yieldCriteria')
                    case 4.0
                        yieldCriterion = 'von Mises criterion yield index';
                    case 3.0
                        yieldCriterion = 'Tresca criterion yield index';
                    case 2.0
                        yieldCriterion = 'Maximum shear strain energy theory yield index';
                    case 1.0
                        yieldCriterion = 'Total strain energy theory yield index';
                end
                
                %% Get the yield field data
                fieldNamesFile = fieldDataFile.colheaders(3.0:end);
                fieldNamesFile{1.0} = 'SMAX-MPa';
                allFieldData = fieldDataFile.data(:, 3.0:end);
                fieldDescriptionsData = {'Maximum stress in loading',...
                    'Yield criterion flag', yieldCriterion,...
                    'Normalised equivalent plastic strain energy density'};
                [R, ~] = size(allFieldData);
                
                fieldData = zeros(R, 0.0);
                fieldNames = cell(1.0, 0.0);
                fieldDescriptions = fieldNames;
                index = 1.0;
                for i = 1:4.0
                    if all(allFieldData(:, i) == -1.0) == 0.0
                        fieldData(:, index) = allFieldData(:, i);
                        fieldNames(index) = fieldNamesFile(i);
                        fieldDescriptions(index) = fieldDescriptionsData(i);
                        
                        index = index + 1.0;
                    end
                end
            else
                %% Get the composite field data
                fieldNamesFile = fieldDataFile.colheaders(3.0:end);
                allFieldData = fieldDataFile.data(:, 3.0:end);
                fieldDescriptionsData = {'Maximum stress theory failure measure', 'Maximum strain theory failure measure', 'Tsai-Hill theory failure measure',...
                    'Tsai-Wu theory failure measure', 'Tsai-Wu theory failue measure for closed cell PVC foam', 'Azzi-Tsai-Hill theory failure measure',...
                    'Hashin''s fibre tensile damage initiation criterion', 'Hashin''s fibre compression damage initiation criterion',...
                    'Hashin''s matrix tensile damage initiation criterion', 'Hashin''s matrix compression damage initiation criterion',...
                    'LaRC05 polymer failure measure', 'LaRC05 matrix failure measure', 'LaRC05 fibre kink failure measure', 'LaRC05 fibre split failure measure',...
                    'LaRC05 fibre tensile failure measure'};
                [R, ~] = size(allFieldData);
                
                fieldData = zeros(R, 0.0);
                fieldNames = cell(1.0, 0.0);
                fieldDescriptions = fieldNames;
                index = 1.0;
                for i = 1:15.0
                    if all(allFieldData(:, i) == -1.0) == 0.0
                        fieldData(:, index) = allFieldData(:, i);
                        fieldNames(index) = fieldNamesFile(i);
                        fieldDescriptions(index) = fieldDescriptionsData(i);
                        
                        index = index + 1.0;
                    end
                end
            end
            
            %% Re-order position labels
            %{
                The Abaqus API requires that node and element labels
                supplied to the LABELS argument of the ADDDATA function are
                in ascending order. Therefore, if the values in
                POSITIONLABELS are not in ascending order, re-order them as
                well as the field data
            %}
            if (all(diff(positionLabels) >= 0.0) ~= 1.0) && (strcmpi(position, 'ELEMENT_NODAL') == 0.0)
                % Update the debug log file
                fprintf(fid_debug, '\r\n\tNote: Element IDs for argument LABEL in function ODB.ADDDATA are not increasing. The IDs will be re-ordered');
                
                % Get the length of the label list
                numberOfLabels = length(positionLabels);
                
                % Sort the labels list in ascending order
                positionLabelsSorted = sort(positionLabels);
                
                % Get the number of fields
                [numberOfItems, numberOfFields] = size(fieldData);
                
                % Initialize the variable for the sorted field data
                fieldDataSorted = zeros(numberOfItems, numberOfFields);
                
                % Initialize the index
                index = 1.0;
                
                % Replace the original labels with the sorted labels
                positionLabelData = '(';
                for i = 1:numberOfLabels
                    if i == numberOfLabels
                        positionLabelData = [positionLabelData, sprintf('%.0f)', positionLabelsSorted(i))]; %#ok<AGROW>
                        break
                    end
                    
                    positionLabelData = [positionLabelData, sprintf('%.0f, ', positionLabelsSorted(i))]; %#ok<AGROW>
                end
                
                % Replace the original position labels with the sorted position labels
                positionLabels = positionLabelsSorted;
                
                % Rearrange the field data so that it matches the new position label list
                for label = 1:numberOfLabels
                    newIndex = mainIDs == positionLabelsSorted(label);
                    
                    fieldDataSorted(index:((index - 1.0) + length(find(newIndex == 1.0))), :) = fieldData(newIndex, :);
                    
                    index = 1.0 + ((index - 1.0) + length(find(newIndex == 1.0)));
                end
                
                % Rearrange the main and sub IDs so that they match the new position label list
                mainIDsSorted = sort(mainIDs);
                subIDsSorted = zeros(length(subIDs), 1.0);
                
                % Initialize the index
                index = 1.0;
                
                for i = 1:length(mainIDs)
                    newIndex = find(mainIDs == mainIDsSorted(index));
                    
                    subIDsSorted(index:((index - 1.0) + length(newIndex))) = subIDs(newIndex);
                    
                    index = 1.0 + ((index - 1.0) + length(newIndex));
                    
                    if index > length(mainIDs)
                        break
                    end
                end
                mainIDs = mainIDsSorted;
                subIDs = subIDsSorted;
                
                % Replace the original field data with the sorted field data
                fieldData = fieldDataSorted;
                
                % Rearrange the connectivity matrix so that it matches the new position label list
                if connectivity ~= 0.0
                    connectivitySorted = zeros(numberOfLabels, 20.0);
                    for i = 1:numberOfLabels
                        newIndex = find(positionLabels == positionLabelsSorted(i));
                        connectivitySorted(i, :) = connectivity(newIndex, :); %#ok<FNDSB>
                    end
                    connectivity = connectivitySorted;
                end
            end
        end
        
        %% Get whole model model summary for message file
        function [N_MSTRS, N_MSTRN, N_TSAIH, N_TSAIW, N_TSAIWTT,...
                N_AZZIT, N_HSNFTCRT, N_HSNFCCRT, N_HSNMTCRT, N_HSNMCCRT,...
                N_LARPFCRT, N_LARMFCRT, N_LARKFCRT, N_LARSFCRT,...
                N_LARTFCRT] =...
                getCompositeSummary(MSTRS, MSTRN, TSAIH, TSAIW, TSAIWTT,...
                AZZIT, HSNFTCRT, HSNFCCRT, HSNMTCRT, HSNMCCRT, LARPFCRT,...
                LARMFCRT, LARKFCRT, LARSFCRT, LARTFCRT, k,...
                failStressGeneral, tsaiWuTT, failStrain, hashin, larc05,...
                mainIDs, subIDs)
            
            %% Get the number of PASS/FAIL items            
            N_MSTRS = length(MSTRS(MSTRS >= 1.0));
            N_MSTRN = length(MSTRN(MSTRN >= 1.0));
            N_TSAIH = length(TSAIH(TSAIH >= 1.0));
            N_TSAIW = length(TSAIW(TSAIW >= 1.0));
            N_TSAIWTT = length(TSAIWTT(TSAIWTT >= (1.0 - k.^2.0)));
            N_AZZIT = length(AZZIT(AZZIT >= 1.0));
            N_HSNFTCRT = length(HSNFTCRT(HSNFTCRT >= 1.0));
            N_HSNFCCRT = length(HSNFCCRT(HSNFCCRT >= 1.0));
            N_HSNMTCRT = length(HSNMTCRT(HSNMTCRT >= 1.0));
            N_HSNMCCRT = length(HSNMCCRT(HSNMCCRT >= 1.0));
            N_LARPFCRT = length(LARPFCRT(LARPFCRT >= 1.0));
            N_LARMFCRT = length(LARMFCRT(LARMFCRT >= 1.0));
            N_LARKFCRT = length(LARKFCRT(LARKFCRT >= 1.0));
            N_LARSFCRT = length(LARSFCRT(LARSFCRT >= 1.0));
            N_LARTFCRT = length(LARTFCRT(LARTFCRT >= 1.0));
            
            % General stress-based failure criteria
            if failStressGeneral == 1.0
                if N_MSTRS == 0.0
                    setappdata(0, 'MSTRS_NL', 'ALL')
                else
                    setappdata(0, 'MSTRS_NL', sprintf('%s', num2str(N_MSTRS)))
                end
                
                if N_TSAIH == 0.0
                    setappdata(0, 'TSAIH_NL', 'ALL')
                else
                    setappdata(0, 'TSAIH_NL', sprintf('%s', num2str(N_TSAIH)))
                end
                
                if N_TSAIW == 0.0
                    setappdata(0, 'TSAIW_NL', 'ALL')
                else
                    setappdata(0, 'TSAIW_NL', sprintf('%s', num2str(N_TSAIW)))
                end
                
                if N_AZZIT == 0.0
                    setappdata(0, 'AZZIT_NL', 'ALL')
                else
                    setappdata(0, 'AZZIT_NL', sprintf('%s', num2str(N_AZZIT)))
                end
            else
                setappdata(0, 'MSTRS_NL', 'N/A')
                setappdata(0, 'TSAIH_NL', 'N/A')
                setappdata(0, 'TSAIW_NL', 'N/A')
                setappdata(0, 'AZZIT_NL', 'N/A')
            end
            
            % Tsai-Wu for PVC foam
            if tsaiWuTT == 1.0
                if N_TSAIWTT == 0.0
                    setappdata(0, 'TSAIWTT_NL', 'ALL')
                else
                    setappdata(0, 'TSAIWTT_NL', sprintf('%s', num2str(N_TSAIWTT)))
                end
            else
                setappdata(0, 'TSAIWTT_NL', 'N/A')
            end
            
            % Maximum strain failure theory
            if failStrain == 1.0
                if N_MSTRN == 0.0
                    setappdata(0, 'MSTRN_NL', 'ALL')
                else
                    setappdata(0, 'MSTRN_NL', sprintf('%s', num2str(N_MSTRN)))
                end
            else
                setappdata(0, 'MSTRN_NL', 'N/A')
            end
            
            % Hashin's damage initiation criteria
            if hashin == 1.0
                if N_HSNFTCRT == 0.0
                    setappdata(0, 'HSNFTCRT_NL', 'ALL')
                else
                    setappdata(0, 'HSNFTCRT_NL', sprintf('%s', num2str(N_HSNFTCRT)))
                end
                
                if N_HSNFCCRT == 0.0
                    setappdata(0, 'HSNFCCRT_NL', 'ALL')
                else
                    setappdata(0, 'HSNFCCRT_NL', sprintf('%s', num2str(N_HSNFCCRT)))
                end
                
                if N_HSNMTCRT == 0.0
                    setappdata(0, 'HSNMTCRT_NL', 'ALL')
                else
                    setappdata(0, 'HSNMTCRT_NL', sprintf('%s', num2str(N_HSNMTCRT)))
                end
                
                if N_HSNMCCRT == 0.0
                    setappdata(0, 'HSNMCCRT_NL', 'ALL')
                else
                    setappdata(0, 'HSNMCCRT_NL', sprintf('%s', num2str(N_HSNMCCRT)))
                end
            else
                setappdata(0, 'HSNFTCRT_NL', 'N/A')
                setappdata(0, 'HSNFCCRT_NL', 'N/A')
                setappdata(0, 'HSNMTCRT_NL', 'N/A')
                setappdata(0, 'HSNMCCRT_NL', 'N/A')
            end
            
            % LaRC05 damage initiation criteria
            if larc05 == 1.0
                if N_LARPFCRT == 0.0
                    setappdata(0, 'LARPFCRT_NL', 'ALL')
                else
                    setappdata(0, 'LARPFCRT_NL', sprintf('%s', num2str(N_LARPFCRT)))
                end
                
                if N_LARMFCRT == 0.0
                    setappdata(0, 'LARMFCRT_NL', 'ALL')
                else
                    setappdata(0, 'LARMFCRT_NL', sprintf('%s', num2str(N_LARMFCRT)))
                end
                
                if N_LARKFCRT == 0.0
                    setappdata(0, 'LARKFCRT_NL', 'ALL')
                else
                    setappdata(0, 'LARKFCRT_NL', sprintf('%s', num2str(N_LARKFCRT)))
                end
                
                if N_LARSFCRT == 0.0
                    setappdata(0, 'LARSFCRT_NL', 'ALL')
                else
                    setappdata(0, 'LARSFCRT_NL', sprintf('%s', num2str(N_LARSFCRT)))
                end
                
                if N_LARTFCRT == 0.0
                    setappdata(0, 'LARTFCRT_NL', 'ALL')
                else
                    setappdata(0, 'LARTFCRT_NL', sprintf('%s', num2str(N_LARTFCRT)))
                end
            else
                setappdata(0, 'LARPFCRT_NL', 'N/A')
                setappdata(0, 'LARMFCRT_NL', 'N/A')
                setappdata(0, 'LARKFCRT_NL', 'N/A')
                setappdata(0, 'LARSFCRT_NL', 'N/A')
                setappdata(0, 'LARTFCRT_NL', 'N/A')
            end
            
            %% Get PASS/FAIL status
            
            % General stress-based failure criteria
            if failStressGeneral == 1.0
                if N_MSTRS > 0.0
                    setappdata(0, 'MSTRS_STAT', 'FAIL')
                else
                    setappdata(0, 'MSTRS_STAT', 'PASS')
                end
                
                if N_TSAIH > 0.0
                    setappdata(0, 'TSAIH_STAT', 'FAIL')
                else
                    setappdata(0, 'TSAIH_STAT', 'PASS')
                end
                
                if N_TSAIW > 0.0
                    setappdata(0, 'TSAIW_STAT', 'FAIL')
                else
                    setappdata(0, 'TSAIW_STAT', 'PASS')
                end
                
                if N_AZZIT > 0.0
                    setappdata(0, 'AZZIT_STAT', 'FAIL')
                else
                    setappdata(0, 'AZZIT_STAT', 'PASS')
                end
            else
                setappdata(0, 'MSTRS_STAT', 'N/A')
                setappdata(0, 'TSAIH_STAT', 'N/A')
                setappdata(0, 'TSAIW_STAT', 'N/A')
                setappdata(0, 'AZZIT_STAT', 'N/A')
            end
            
            % Tsai-Wu for PVC foam
            if tsaiWuTT == 1.0
                if N_TSAIWTT > 0.0
                    setappdata(0, 'TSAIWTT_STAT', 'FAIL')
                else
                    setappdata(0, 'TSAIWTT_STAT', 'PASS')
                end
            else
                setappdata(0, 'TSAIWTT_STAT', 'N/A')
            end
            
            % Maximum strain failure theory
            if failStrain == 1.0
                if N_MSTRN > 0.0
                    setappdata(0, 'MSTRN_STAT', 'FAIL')
                else
                    setappdata(0, 'MSTRN_STAT', 'PASS')
                end
            else
                setappdata(0, 'MSTRN_STAT', 'N/A')
            end
            
            % Hashin's damage initiation criteria
            if hashin == 1.0
                if N_HSNFTCRT > 0.0
                    setappdata(0, 'HSNFTCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'HSNFTCRT_STAT', 'PASS')
                end
                
                if N_HSNFCCRT > 0.0
                    setappdata(0, 'HSNFCCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'HSNFCCRT_STAT', 'PASS')
                end
                
                if N_HSNMTCRT > 0.0
                    setappdata(0, 'HSNMTCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'HSNMTCRT_STAT', 'PASS')
                end
                
                if N_HSNMCCRT > 0.0
                    setappdata(0, 'HSNMCCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'HSNMCCRT_STAT', 'PASS')
                end
            else
                setappdata(0, 'HSNFTCRT_STAT', 'N/A')
                setappdata(0, 'HSNFCCRT_STAT', 'N/A')
                setappdata(0, 'HSNMTCRT_STAT', 'N/A')
                setappdata(0, 'HSNMCCRT_STAT', 'N/A')
            end
            
            % LaRC05 damage initiation criteria
            if larc05 == 1.0
                if N_LARPFCRT > 0.0
                    setappdata(0, 'LARPFCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'LARPFCRT_STAT', 'PASS')
                end
                
                if N_LARMFCRT > 0.0
                    setappdata(0, 'LARMFCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'LARMFCRT_STAT', 'PASS')
                end
                
                if N_LARKFCRT > 0.0
                    setappdata(0, 'LARKFCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'LARKFCRT_STAT', 'PASS')
                end
                
                if N_LARSFCRT > 0.0
                    setappdata(0, 'LARSFCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'LARSFCRT_STAT', 'PASS')
                end
                
                if N_LARTFCRT > 0.0
                    setappdata(0, 'LARTFCRT_STAT', 'FAIL')
                else
                    setappdata(0, 'LARTFCRT_STAT', 'PASS')
                end
            else
                setappdata(0, 'LARPFCRT_STAT', 'N/A')
                setappdata(0, 'LARMFCRT_STAT', 'N/A')
                setappdata(0, 'LARKFCRT_STAT', 'N/A')
                setappdata(0, 'LARSFCRT_STAT', 'N/A')
                setappdata(0, 'LARTFCRT_STAT', 'N/A')
            end
            
            %% Get maximum value of each criterion
            if max(MSTRS) == -1.0
                setappdata(0, 'MSTRS_MV', 'N/A')
            else
                setappdata(0, 'MSTRS_MV', sprintf('%s', num2str(max(MSTRS))))
            end
            
            if max(MSTRN) == -1.0
                setappdata(0, 'MSTRN_MV', 'N/A')
            else
                setappdata(0, 'MSTRN_MV', sprintf('%s', num2str(max(MSTRN))))
            end
            
            if max(TSAIH) == -1.0
                setappdata(0, 'TSAIH_MV', 'N/A')
            else
                setappdata(0, 'TSAIH_MV', sprintf('%s', num2str(max(TSAIH))))
            end
            
            if max(TSAIW) == -1.0
                setappdata(0, 'TSAIW_MV', 'N/A')
            else
                setappdata(0, 'TSAIW_MV', sprintf('%s', num2str(max(TSAIW))))
            end
            
            if max(TSAIWTT) == -1.0
                setappdata(0, 'TSAIWTT_MV', 'N/A')
            else
                setappdata(0, 'TSAIWTT_MV', sprintf('%s', num2str(max(TSAIWTT))))
            end
            
            if max(AZZIT) == -1.0
                setappdata(0, 'AZZIT_MV', 'N/A')
            else
                setappdata(0, 'AZZIT_MV', sprintf('%s', num2str(max(AZZIT))))
            end
            
            if max(HSNFTCRT) == -1.0
                setappdata(0, 'HSNFTCRT_MV', 'N/A')
            else
                setappdata(0, 'HSNFTCRT_MV', sprintf('%s', num2str(max(HSNFTCRT))))
            end
            
            if max(HSNFCCRT) == -1.0
                setappdata(0, 'HSNFCCRT_MV', 'N/A')
            else
                setappdata(0, 'HSNFCCRT_MV', sprintf('%s', num2str(max(HSNFCCRT))))
            end
            
            if max(HSNMTCRT) == -1.0
                setappdata(0, 'HSNMTCRT_MV', 'N/A')
            else
                setappdata(0, 'HSNMTCRT_MV', sprintf('%s', num2str(max(HSNMTCRT))))
            end
            
            if max(HSNMCCRT) == -1.0
                setappdata(0, 'HSNMCCRT_MV', 'N/A')
            else
                setappdata(0, 'HSNMCCRT_MV', sprintf('%s', num2str(max(HSNMCCRT))))
            end
            
            if max(LARPFCRT) == -1.0
                setappdata(0, 'LARPFCRT_MV', 'N/A')
            else
                setappdata(0, 'LARPFCRT_MV', sprintf('%s', num2str(max(LARPFCRT))))
            end
            
            if max(LARMFCRT) == -1.0
                setappdata(0, 'LARMFCRT_MV', 'N/A')
            else
                setappdata(0, 'LARMFCRT_MV', sprintf('%s', num2str(max(LARMFCRT))))
            end
            
            if max(LARKFCRT) == -1.0
                setappdata(0, 'LARKFCRT_MV', 'N/A')
            else
                setappdata(0, 'LARKFCRT_MV', sprintf('%s', num2str(max(LARKFCRT))))
            end
            
            if max(LARSFCRT) == -1.0
                setappdata(0, 'LARSFCRT_MV', 'N/A')
            else
                setappdata(0, 'LARSFCRT_MV', sprintf('%s', num2str(max(LARSFCRT))))
            end
            
            if max(LARTFCRT) == -1.0
                setappdata(0, 'LARTFCRT_MV', 'N/A')
            else
                setappdata(0, 'LARTFCRT_MV', sprintf('%s', num2str(max(LARTFCRT))))
            end
            
            %% Get Main/Sub IDs of worst item
            if max(MSTRS) == -1.0
                setappdata(0, 'MSTRS_MV_MainID', 'N/A')
                setappdata(0, 'MSTRS_MV_SubID', 'N/A')
            else
                MSTRS_MV_MainID = mainIDs(MSTRS == max(MSTRS));
                setappdata(0, 'MSTRS_MV_MainID', sprintf('%s', num2str(MSTRS_MV_MainID(1.0))))
                
                MSTRS_MV_SubID = subIDs(MSTRS == max(MSTRS));
                setappdata(0, 'MSTRS_MV_SubID', sprintf('%s', num2str(MSTRS_MV_SubID(1.0))))
            end
            
            if max(MSTRN) == -1.0
                setappdata(0, 'MSTRN_MV_MainID', 'N/A')
                setappdata(0, 'MSTRN_MV_SubID', 'N/A')
            else
                MSTRN_MV_MainID = mainIDs(MSTRN == max(MSTRN));
                setappdata(0, 'MSTRN_MV_MainID', sprintf('%s', num2str(MSTRN_MV_MainID(1.0))))
                
                MSTRN_MV_SubID = subIDs(MSTRN == max(MSTRN));
                setappdata(0, 'MSTRN_MV_SubID', sprintf('%s', num2str(MSTRN_MV_SubID(1.0))))
            end
            
            if max(TSAIH) == -1.0
                setappdata(0, 'TSAIH_MV_MainID', 'N/A')
                setappdata(0, 'TSAIH_MV_SubID', 'N/A')
            else
                TSAIH_MV_MainID = mainIDs(TSAIH == max(TSAIH));
                setappdata(0, 'TSAIH_MV_MainID', sprintf('%s', num2str(TSAIH_MV_MainID(1.0))))
                
                TSAIH_MV_SubID = subIDs(TSAIH == max(TSAIH));
                setappdata(0, 'TSAIH_MV_SubID', sprintf('%s', num2str(TSAIH_MV_SubID(1.0))))
            end
            
            if max(TSAIW) == -1.0
                setappdata(0, 'TSAIW_MV_MainID', 'N/A')
                setappdata(0, 'TSAIW_MV_SubID', 'N/A')
            else
                TSAIW_MV_MainID = mainIDs(TSAIW == max(TSAIW));
                setappdata(0, 'TSAIW_MV_MainID', sprintf('%s', num2str(TSAIW_MV_MainID(1.0))))
                
                TSAIW_MV_SubID = subIDs(TSAIW == max(TSAIW));
                setappdata(0, 'TSAIW_MV_SubID', sprintf('%s', num2str(TSAIW_MV_SubID(1.0))))
            end
            
            if max(TSAIWTT) == -1.0
                setappdata(0, 'TSAIWTT_MV_MainID', 'N/A')
                setappdata(0, 'TSAIWTT_MV_SubID', 'N/A')
            else
                TSAIWTT_MV_MainID = mainIDs(TSAIWTT == max(TSAIWTT));
                setappdata(0, 'TSAIWTT_MV_MainID', sprintf('%s', num2str(TSAIWTT_MV_MainID(1.0))))
                
                TSAIWTT_MV_SubID = subIDs(TSAIWTT == max(TSAIWTT));
                setappdata(0, 'TSAIWTT_MV_SubID', sprintf('%s', num2str(TSAIWTT_MV_SubID(1.0))))
            end
            
            if max(AZZIT) == -1.0
                setappdata(0, 'AZZIT_MV_MainID', 'N/A')
                setappdata(0, 'AZZIT_MV_SubID', 'N/A')
            else
                AZZIT_MV_MainID = mainIDs(AZZIT == max(AZZIT));
                setappdata(0, 'AZZIT_MV_MainID', sprintf('%s', num2str(AZZIT_MV_MainID(1.0))))
                
                AZZIT_MV_SubID = subIDs(AZZIT == max(AZZIT));
                setappdata(0, 'AZZIT_MV_SubID', sprintf('%s', num2str(AZZIT_MV_SubID(1.0))))
            end
            
            if max(HSNFTCRT) == -1.0
                setappdata(0, 'HSNFTCRT_MV_MainID', 'N/A')
                setappdata(0, 'HSNFTCRT_MV_SubID', 'N/A')
            else
                HSNFTCRT_MV_MainID = mainIDs(HSNFTCRT == max(HSNFTCRT));
                setappdata(0, 'HSNFTCRT_MV_MainID', sprintf('%s', num2str(HSNFTCRT_MV_MainID(1.0))))
                
                HSNFTCRT_MV_SubID = subIDs(HSNFTCRT == max(HSNFTCRT));
                setappdata(0, 'HSNFTCRT_MV_SubID', sprintf('%s', num2str(HSNFTCRT_MV_SubID(1.0))))
            end
            
            if max(HSNFCCRT) == -1.0
                setappdata(0, 'HSNFCCRT_MV_MainID', 'N/A')
                setappdata(0, 'HSNFCCRT_MV_SubID', 'N/A')
            else
                HSNFCCRT_MV_MainID = mainIDs(HSNFCCRT == max(HSNFCCRT));
                setappdata(0, 'HSNFCCRT_MV_MainID', sprintf('%s', num2str(HSNFCCRT_MV_MainID(1.0))))
                
                HSNFCCRT_MV_SubID = subIDs(HSNFCCRT == max(HSNFCCRT));
                setappdata(0, 'HSNFCCRT_MV_SubID', sprintf('%s', num2str(HSNFCCRT_MV_SubID(1.0))))
            end
            
            if max(HSNMTCRT) == -1.0
                setappdata(0, 'HSNMTCRT_MV_MainID', 'N/A')
                setappdata(0, 'HSNMTCRT_MV_SubID', 'N/A')
            else
                HSNMTCRT_MV_MainID = mainIDs(HSNMTCRT == max(HSNMTCRT));
                setappdata(0, 'HSNMTCRT_MV_MainID', sprintf('%s', num2str(HSNMTCRT_MV_MainID(1.0))))
                
                HSNMTCRT_MV_SubID = subIDs(HSNMTCRT == max(HSNMTCRT));
                setappdata(0, 'HSNMTCRT_MV_SubID', sprintf('%s', num2str(HSNMTCRT_MV_SubID(1.0))))
            end
            
            if max(HSNMCCRT) == -1.0
                setappdata(0, 'HSNMCCRT_MV_MainID', 'N/A')
                setappdata(0, 'HSNMCCRT_MV_SubID', 'N/A')
            else
                HSNMCCRT_MV_MainID = mainIDs(HSNMCCRT == max(HSNMCCRT));
                setappdata(0, 'HSNMCCRT_MV_MainID', sprintf('%s', num2str(HSNMCCRT_MV_MainID(1.0))))
                
                HSNMCCRT_MV_SubID = subIDs(HSNMCCRT == max(HSNMCCRT));
                setappdata(0, 'HSNMCCRT_MV_SubID', sprintf('%s', num2str(HSNMCCRT_MV_SubID(1.0))))
            end
            
            if max(LARPFCRT) == -1.0
                setappdata(0, 'LARPFCRT_MV_MainID', 'N/A')
                setappdata(0, 'LARPFCRT_MV_SubID', 'N/A')
            else
                LARPFCRT_MV_MainID = mainIDs(LARPFCRT == max(LARPFCRT));
                setappdata(0, 'LARPFCRT_MV_MainID', sprintf('%s', num2str(LARPFCRT_MV_MainID(1.0))))
                
                LARPFCRT_MV_SubID = subIDs(LARPFCRT == max(LARPFCRT));
                setappdata(0, 'LARPFCRT_MV_SubID', sprintf('%s', num2str(LARPFCRT_MV_SubID(1.0))))
            end
            
            if max(LARMFCRT) == -1.0
                setappdata(0, 'LARMFCRT_MV_MainID', 'N/A')
                setappdata(0, 'LARMFCRT_MV_SubID', 'N/A')
            else
                LARMFCRT_MV_MainID = mainIDs(LARMFCRT == max(LARMFCRT));
                setappdata(0, 'LARMFCRT_MV_MainID', sprintf('%s', num2str(LARMFCRT_MV_MainID(1.0))))
                
                LARMFCRT_MV_SubID = subIDs(LARMFCRT == max(LARMFCRT));
                setappdata(0, 'LARMFCRT_MV_SubID', sprintf('%s', num2str(LARMFCRT_MV_SubID(1.0))))
            end
            
            if max(LARKFCRT) == -1.0
                setappdata(0, 'LARKFCRT_MV_MainID', 'N/A')
                setappdata(0, 'LARKFCRT_MV_SubID', 'N/A')
            else
                LARKFCRT_MV_MainID = mainIDs(LARKFCRT == max(LARKFCRT));
                setappdata(0, 'LARKFCRT_MV_MainID', sprintf('%s', num2str(LARKFCRT_MV_MainID(1.0))))
                
                LARKFCRT_MV_SubID = subIDs(LARKFCRT == max(LARKFCRT));
                setappdata(0, 'LARKFCRT_MV_SubID', sprintf('%s', num2str(LARKFCRT_MV_SubID(1.0))))
            end
            
            if max(LARSFCRT) == -1.0
                setappdata(0, 'LARSFCRT_MV_MainID', 'N/A')
                setappdata(0, 'LARSFCRT_MV_SubID', 'N/A')
            else
                LARSFCRT_MV_MainID = mainIDs(LARSFCRT == max(LARSFCRT));
                setappdata(0, 'LARSFCRT_MV_MainID', sprintf('%s', num2str(LARSFCRT_MV_MainID(1.0))))
                
                LARSFCRT_MV_SubID = subIDs(LARSFCRT == max(LARSFCRT));
                setappdata(0, 'LARSFCRT_MV_SubID', sprintf('%s', num2str(LARSFCRT_MV_SubID(1.0))))
            end
            
            if max(LARTFCRT) == -1.0
                setappdata(0, 'LARTFCRT_MV_MainID', 'N/A')
                setappdata(0, 'LARTFCRT_MV_SubID', 'N/A')
            else
                LARTFCRT_MV_MainID = mainIDs(LARTFCRT == max(LARTFCRT));
                setappdata(0, 'LARTFCRT_MV_MainID', sprintf('%s', num2str(LARTFCRT_MV_MainID(1.0))))
                
                LARTFCRT_MV_SubID = subIDs(LARTFCRT == max(LARTFCRT));
                setappdata(0, 'LARTFCRT_MV_SubID', sprintf('%s', num2str(LARTFCRT_MV_SubID(1.0))))
            end
        end
        
        %% Get master flags for composite failure output
        function [compositeFile_stress, compositeFile_strain,...
                compositeFile_hashin, compositeFile_larc05] = compositeFile()
            compositeFile_stress = getappdata(0, 'compositeFile_stress');
            compositeFile_strain = getappdata(0, 'compositeFile_strain');
            compositeFile_hashin = getappdata(0, 'compositeFile_hashin');
            compositeFile_larc05 = getappdata(0, 'compositeFile_larc05');
            
            if (isempty(compositeFile_stress) == 1.0) || (compositeFile_stress ~=0.0 && compositeFile_stress ~= 1.0)
                compositeFile_stress = 1.0;
            end
            if (isempty(compositeFile_strain) == 1.0) || (compositeFile_strain ~=0.0 && compositeFile_strain ~= 1.0)
                compositeFile_strain = 1.0;
            end
            if (isempty(compositeFile_hashin) == 1.0) || (compositeFile_hashin ~=0.0 && compositeFile_hashin ~= 1.0)
                compositeFile_hashin = 1.0;
            end
            if (isempty(compositeFile_larc05) == 1.0) || (compositeFile_larc05 ~=0.0 && compositeFile_larc05 ~= 1.0)
                compositeFile_larc05 = 1.0;
            end
        end
    end
end