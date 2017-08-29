function [mainID, subID, N, items, Sxx, Syy, Szz, Txy, Tyz, Txz] = getSurface(mainID, subID, N, items, Sxx, Syy, Szz, Txy, Tyz, Txz)
%FOS    QFT function to find surface elements and nodes.
%   This function uses the ODB file specified by OUTPUT_DATABASE to
%   determine the elements and nodes which lie on the mesh surface.
%
%   GETSURFACE is called when ITEMS='SURFACE'. All non-surface items are
%   excluded from the analysis.
%
%   GETSURFACE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      4.5.3 Custom analysis items
%
%   Quick Fatigue Tool 6.11-02 Copyright Louis Vallance 2017
%   Last modified 24-Aug-2017 12:05:33 GMT

%%

%% Check if surface detection can be used
outputDatabase = getappdata(0, 'outputDatabase');
partInstance = getappdata(0, 'partInstance');
odbResultPosition = getappdata(0, 'odbResultPosition');

% Check intpus
if isempty(outputDatabase) == 1.0
    if strcmpi(items, 'surface') == 1.0
        items = 'ALL';
        setappdata(0, 'items', 'ALL')
    end
    return
end

% Only if ITEMS = 'SURFACE'
if strcmpi(getappdata(0, 'items'), 'surface') == 0.0
    if strcmpi(items, 'surface') == 1.0
        items = 'ALL';
        setappdata(0, 'items', 'ALL')
    end
    return
end

% Only for certain algorithms
algorithm = getappdata(0, 'algorithm');

if (algorithm == 3.0) || (algorithm == 1.0)
    % Surface detection is not supported for uniaxial methods
    if strcmpi(items, 'surface') == 1.0
        items = 'ALL';
        setappdata(0, 'items', 'ALL')
    end
    return
end

%% Collect additional information

% Get the number of part instances
if ischar(partInstance) == 1.0
    numberOfInstances = 1.0;
else
    numberOfInstances = length(partInstance);
end

% Get results position
if strcmpi(odbResultPosition, 'element nodal') == 1.0
    odbResultPosition = 'ELEMENTAL';
elseif strcmpi(odbResultPosition, 'unique nodal') == 1.0
    odbResultPosition = 'NODAL';
elseif strcmpi(odbResultPosition, 'centroid') == 1.0
    odbResultPosition = 'CENTROIDAL';
else
    % Integration point is not currently supported
    messenger.writeMessage(270.0)
    if strcmpi(items, 'surface') == 1.0
        items = 'ALL';
        setappdata(0, 'items', 'ALL')
    end
    return
end

%% Get the Abaqus command
abqCmd = getappdata(0, 'autoExport_abqCmd');
if isempty(abqCmd) == 1.0
    abqCmd = 'abaqus';
end

%% Format the part instances
if iscell(partInstance) == 1.0
    partInstance_i = '';
    for i = 1:numberOfInstances
        if i == numberOfInstances
            partInstance_i = [partInstance_i, sprintf('%s', partInstance{i})]; %#ok<AGROW>
        else
            partInstance_i = [partInstance_i, sprintf('%s', partInstance{i}), ' ']; %#ok<AGROW>
        end
    end
    partInstance = partInstance_i;
end

%% Get the shell surface environment variable
shell = getappdata(0, 'shellFaces');
if isnumeric(shell) == 1.0
    if shell ~= 1.0 && shell ~= 0.0
        shell = 'NO';
    elseif shell == 1.0
        shell = 'YES';
    else
        shell = 'NO';
    end
elseif isempty(shell) == 1.0
    shell = 'NO';
elseif ischar(shell) == 0.0
    shell = 'NO';
elseif strcmpi(shell, 'yes') == 0.0 && strcmpi(shell, 'no') == 0.0
    shell = 'NO';
end

%% Create mainID list if necessary
searchRegion = getappdata(0, 'searchRegion');

if isnumeric(searchRegion) == 1.0
    if searchRegion ~= 1.0 && searchRegion ~= 0.0
        searchRegion = 'DATASET';
    elseif searchRegion == 1.0
        searchRegion = 'INSTANCE';
    else
        searchRegion = 'DATASET';
    end
elseif isempty(searchRegion) == 1.0
    searchRegion = 'DATASET';
elseif ischar(searchRegion) == 0.0
    searchRegion = 'DATASET';
elseif strcmpi(searchRegion, 'DATASET') == 0.0 && strcmpi(searchRegion, 'INSTANCE') == 0.0
    searchRegion = 'DATASET';
end

if (strcmpi(searchRegion, 'dataset') == 1.0) && (strcmpi(odbResultPosition, 'nodal') == 1.0)
    searchRegion = 'INSTANCE';
    messenger.writeMessage(276.0)
elseif strcmpi(searchRegion, 'dataset') == 1.0
    fileName = [pwd, '/Application_Files/code/odb_interface/element_ids.dat'];
    fid = fopen(fileName, 'w+');
    uniqueMainID = unique(mainID);
    L = length(uniqueMainID);
    for i = 1:L
        if i == L
            fprintf(fid, '%.0f', uniqueMainID(i));
        else
            fprintf(fid, '%.0f, ', uniqueMainID(i));
        end
    end
    fclose(fid);
end

%% Run the script
% Run script like this:
% abaqus python getSurface_qft.py -- <odbName> <position> <shell> <instance-1> <instance-n> <n>

inputString = sprintf('%s python Application_Files\\code\\odb_interface\\getSurface.py -- "%s" %s %s %s %s %.0f',...
    abqCmd, outputDatabase, odbResultPosition, searchRegion, shell, partInstance, numberOfInstances);

[status, message] = system(inputString);

if strcmpi(searchRegion, 'dataset') == 1.0
    % Delete the element ID file
    delete(fileName);
end

% Check the result of running the script
if (isempty(strfind(message, 'SUCCESS')) == 0.0) && (status == 0.0)
    % The script completed successfully
    
    % Check for element shape incompatibility:
    if isempty(strfind(message, 'ELEM_INCOMPATIBLE')) == 0.0
        % Write to message file
        messenger.writeMessage(271.0)
    end
    
    % Check for geometric order incompatibility:
    if isempty(strfind(message, 'GEOM_INCOMPATIBLE')) == 0.0
        % Write to message file
        messenger.writeMessage(272.0)
    end
else
    message = [message, sprintf('\nOutcome: FAIL\n')];
    % Print the message to the message file
    setappdata(0, 'message_273', message)
    messenger.writeMessage(273.0)
    if strcmpi(items, 'surface') == 1.0
        items = 'ALL';
        setappdata(0, 'items', 'ALL')
    end
    return
end

% Read the output
if strcmpi(odbResultPosition, 'nodal') == 1.0
    fileName = sprintf('%s\\Application_Files\\code\\odb_interface\\surface_nodes.dat', pwd);
    surfaceNodes = importdata(fileName, ',');
    mainID_surface = str2num(cell2mat(surfaceNodes))'; %#ok<ST2NM>
    
    % Delete the node file
    delete(fileName)
    
    % Check if there are any surface elements/nodes
    if isempty(surfaceNodes) == 1.0
        messenger.writeMessage(269.0)
        if strcmpi(items, 'surface') == 1.0
            items = 'ALL';
            setappdata(0, 'items', 'ALL')
        end
        return
    end
    
    % Update the main IDs
    [intersectingIDs, ~, intersectingIndexes] = intersect(mainID_surface, mainID);
    
    % Check if any dataset items lie on the surface
    if isempty(intersectingIDs) == 1.0
        messenger.writeMessage(277.0)
        if strcmpi(items, 'surface') == 1.0
            items = 'ALL';
            setappdata(0, 'items', 'ALL')
        end
        return
    end
    
    mainID = mainID(intersectingIndexes);
    subID = subID(intersectingIndexes);
    
    % Update the tensors
    Sxx = Sxx(intersectingIndexes, :);
    Syy = Syy(intersectingIndexes, :);
    Szz = Szz(intersectingIndexes, :);
    Txy = Txy(intersectingIndexes, :);
    Tyz = Tyz(intersectingIndexes, :);
    Txz = Txz(intersectingIndexes, :);
    
    setappdata(0, 'Sxx', Sxx)
    setappdata(0, 'Syy', Syy)
    setappdata(0, 'Szz', Szz)
    setappdata(0, 'Txy', Txy)
    setappdata(0, 'Tyz', Tyz)
    setappdata(0, 'Txz', Txz)
    
    % Update the number of items
    N = length(mainID);
    
    % Update the message file
    setappdata(0, 'message_274', N)
    if length(mainID_surface) == N
        messenger.writeMessage(280.0)
    else
        messenger.writeMessage(274.0)
    end
elseif strcmpi(odbResultPosition, 'elemental') == 1.0
    % Get the elements
    fileName = sprintf('%s\\Application_Files\\code\\odb_interface\\surface_elements.dat', pwd);
    surfaceElements = importdata(fileName, ',');
    surfaceElements = str2num(cell2mat(surfaceElements)); %#ok<ST2NM>
    
    nElements = length(surfaceElements);
    
    % Delete the element file
    delete(fileName)
    
    % Get the nodes
    fileName = sprintf('%s\\Application_Files\\code\\odb_interface\\surface_nodes.dat', pwd);
    connectedSurfaceNodes = fileread(fileName);
    connectedSurfaceNodes = char(connectedSurfaceNodes);
    
    % Delete the node file
    delete(fileName)
    
    % Check if there are any surface elements/nodes
    if (isempty(surfaceElements) == 1.0) || (isempty(connectedSurfaceNodes) == 1.0)
        messenger.writeMessage(269.0)
        if strcmpi(items, 'surface') == 1.0
            items = 'ALL';
            setappdata(0, 'items', 'ALL')
        end
        return
    end
    
    % Arrange the sub (node) IDs
    subID_surface = str2double(regexp(connectedSurfaceNodes, '\d+', 'match'))';
    connectivityLengths = regexp(connectedSurfaceNodes, '[^,]*', 'match');
    
    nodesPerElement = zeros(1.0, nElements);
    mainID_surface = zeros(length(subID_surface), 1.0);
    
    index = 1.0;
    for i = 1:length(connectivityLengths)
        if isempty(strfind(connectivityLengths{i}, ')')) == 0.0
            if index == 1.0
                nodesPerElement(index) = i;
            else
                nodesPerElement(index) = (i - sum(nodesPerElement(1:index - 1.0)));
            end
            
            if index == 1.0
                mainID_surface(index:nodesPerElement(index)) = linspace(surfaceElements(index), surfaceElements(index), nodesPerElement(index));
            else
                mainID_surface(1.0 + sum(nodesPerElement(1.0:index - 1.0)):sum(nodesPerElement(1.0:index))) = linspace(surfaceElements(index), surfaceElements(index), nodesPerElement(index));
            end
            
            index = index + 1.0;
        end
    end
    
    % Update the main and sub IDs
    allItems = [mainID, subID];
    surfaceItems = [mainID_surface, subID_surface];
    commonItems = ismember(allItems, surfaceItems, 'rows');
    
    % Check if any dataset items lie on the surface
    if any(commonItems) == 0.0
        messenger.writeMessage(277.0)
        if strcmpi(items, 'surface') == 1.0
            items = 'ALL';
            setappdata(0, 'items', 'ALL')
        end
        return
    end
    
    mainID = mainID(commonItems);
    subID = subID(commonItems);
    
    Sxx = Sxx(commonItems, :);
    Syy = Syy(commonItems, :);
    Szz = Szz(commonItems, :);
    Txy = Txy(commonItems, :);
    Tyz = Tyz(commonItems, :);
    Txz = Txz(commonItems, :);
    
    setappdata(0, 'Sxx', Sxx)
    setappdata(0, 'Syy', Syy)
    setappdata(0, 'Szz', Szz)
    setappdata(0, 'Txy', Txy)
    setappdata(0, 'Tyz', Tyz)
    setappdata(0, 'Txz', Txz)
    
    % Update the number of items
    N = length(mainID);
    
    % Update the message file
    setappdata(0, 'message_275', nElements)
    if length(mainID_surface) == N
        messenger.writeMessage(279.0)
    else
        messenger.writeMessage(275.0)
    end
    
    % Get intersecting IDs from common items
    intersectingIndexes = find(commonItems == 1.0);
else
    fileName = sprintf('%s\\Application_Files\\code\\odb_interface\\surface_elements.dat', pwd);
    surfaceElements = importdata(fileName, ',');
    mainID_surface = str2num(cell2mat(surfaceElements))'; %#ok<ST2NM>
    
    nElements = length(mainID_surface);
    
    % Delete the node file
    delete(fileName)
    
    % Check if there are any surface elements/nodes
    if isempty(surfaceElements) == 1.0
        messenger.writeMessage(269.0)
        if strcmpi(items, 'surface') == 1.0
            items = 'ALL';
            setappdata(0, 'items', 'ALL')
        end
        return
    end
    
    % Update the main IDs
    [intersectingIDs, ~, intersectingIndexes] = intersect(mainID_surface, mainID);
    
    % Check if any dataset items lie on the surface
    if isempty(intersectingIDs) == 1.0
        messenger.writeMessage(277.0)
        if strcmpi(items, 'surface') == 1.0
            items = 'ALL';
            setappdata(0, 'items', 'ALL')
        end
        return
    end
    
    mainID = mainID(intersectingIndexes);
    subID = subID(intersectingIndexes);
    
    % Update the tensors
    Sxx = Sxx(intersectingIndexes, :);
    Syy = Syy(intersectingIndexes, :);
    Szz = Szz(intersectingIndexes, :);
    Txy = Txy(intersectingIndexes, :);
    Tyz = Tyz(intersectingIndexes, :);
    Txz = Txz(intersectingIndexes, :);
    
    setappdata(0, 'Sxx', Sxx)
    setappdata(0, 'Syy', Syy)
    setappdata(0, 'Szz', Szz)
    setappdata(0, 'Txy', Txy)
    setappdata(0, 'Tyz', Tyz)
    setappdata(0, 'Txz', Txz)
    
    % Update the number of items
    N = length(mainID);
    
    % Update the message file
    setappdata(0, 'message_275', nElements)
    if length(mainID_surface) == N
        messenger.writeMessage(279.0)
    else
        messenger.writeMessage(275.0)
    end
end

%% Write surface items to text file
% Concatenate data
data = [intersectingIndexes'; mainID'; subID']';

% Check that the directory exists
jobName = getappdata(0, 'jobName');
root = getappdata(0, 'outputDirectory');

if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
    mkdir(sprintf('%s/Data Files', root))
end

% Create the file
dir = [pwd, sprintf('\\Project\\output\\%s\\Data Files\\', jobName), 'surface_items.dat'];
fid = fopen(dir, 'w+');

fprintf(fid, 'SURFACE ITEMS\r\n');

fprintf(fid, 'Item #\tMain ID\tSub ID\r\n');
fprintf(fid, '%.0f\t%.0f\t%.0f\r\n', data');

fclose(fid);

% Inform the user that hotpots have been written to file
messenger.writeMessage(278.0)
end