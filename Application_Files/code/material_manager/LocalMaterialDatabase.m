function varargout = LocalMaterialDatabase(varargin)%#ok<*DEFNU>
%LOCALMATERIALDATABASE    QFT functions for Material Manager.
%   These functions are used to set the default user local material path.
%   
%   LOCALMATERIALDATABASE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also checkDataPath, evaluateMaterial, importMaterial,
%   kValueCalculator, material, MaterialEditor, MaterialManager.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-01 Copyright Louis Vallance 2017
%   Last modified 03-Jul-2017 13:40:46 GMT
    
    %%

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LocalMaterialDatabase_OpeningFcn, ...
                   'gui_OutputFcn',  @LocalMaterialDatabase_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before LocalMaterialDatabase is made visible.
function LocalMaterialDatabase_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LocalMaterialDatabase (see VARARGIN)

% Choose default command line output for LocalMaterialDatabase
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LocalMaterialDatabase wait for user response (see UIRESUME)
% uiwait(handles.LocalMaterialDatabase);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

changeDatabase = getappdata(0, 'qft_localMaterialDataPath');

%% Load icons
[a,~]=imread('icoR_fileOpen.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_userDataDirectory, 'CData', g);

if isempty(changeDatabase) == 0.0
    [a,~]=imread('icoR_info.jpg');
    set(handles.text_warning, 'string', 'Change the current local material database.')
else
    [a,~]=imread('icoR_warning.jpg');
end
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_warning, 'CData', g);

[a,~]=imread('icoR_help.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_help, 'CData', g);

%% Load the panel state
if isappdata(0, 'defaultDataPath_check_defaultDataDirectory') == 1.0
    set(handles.check_defaultDataDirectory, 'value', getappdata(0, 'defaultDataPath_check_defaultDataDirectory'))
    set(handles.check_saveLocalPath, 'value', getappdata(0, 'defaultDataPath_check_saveLocalPath'))
    
    if get(handles.check_defaultDataDirectory, 'value') == 0.0
        set(handles.text_currentDatabase, 'enable', 'on')
        set(handles.edit_userDataDirectory, 'enable', 'on')
        set(handles.edit_userDataDirectory, 'backgroundColor', 'white')
        set(handles.pButton_userDataDirectory, 'enable', 'on')
    end
end

%% Set the default path
defaultLocalPath = material.searchDatabase();
userLocalPath = getappdata(0, 'qft_localMaterialDataPath');

if (exist([pwd, '\Data\material\local'], 'dir') ~= 7.0) && (isempty(defaultLocalPath) == 1.0)
    setappdata(0, 'missingDefaultLocalDatabase', 1.0)
else
    setappdata(0, 'missingDefaultLocalDatabase', 0.0)
end

if isempty(userLocalPath) == 0.0
    %{
        The local path is already set. Display this path in the edit box.
    %}
    set(handles.edit_userDataDirectory, 'string', userLocalPath)
elseif exist([pwd, '\Data\material\local'], 'dir') == 7.0
    %{
        The local path is not set, but there is a local directory on the
        current MATLAB path. Add this location to the edit box.
    %}
    set(handles.edit_userDataDirectory, 'string', [pwd, '\Data\material\local'])
else
    %{
        The local path is not set and there is no local directory on the
        current MATLAB path. Search PATHDEF for any DATA\MATERIAL\LOCAL
        folder.
    %}
    if isempty(defaultLocalPath) == 0.0
        % An entry for DATA\MATERIAL\LOCAL was found in PATHDEF
        set(handles.edit_userDataDirectory, 'string', defaultLocalPath)
    else
        %{
            An entry for DATA\MATERIAL\LOCAL was not found in PATHDEF. Set
            the edit box to the current working directory and disable the
            default path checkbox.
        %}
        set(handles.edit_userDataDirectory, 'string', pwd)
        
        set(handles.check_defaultDataDirectory, 'enable', 'off')
        set(handles.check_defaultDataDirectory, 'value', 0.0)
        
        set(handles.text_currentDatabase, 'enable', 'on')
        set(handles.edit_userDataDirectory, 'enable', 'on', 'backgroundColor', 'white')
        set(handles.pButton_userDataDirectory, 'enable', 'on')
    end
end

%% Set the current local path
setappdata(0, 'currentLocalPath', get(handles.edit_userDataDirectory, 'string'))


% --- Outputs from this function are returned to the command line.
function varargout = LocalMaterialDatabase_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_userDataDirectory_Callback(~, ~, ~)
% hObject    handle to edit_userDataDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_userDataDirectory as text
%        str2double(get(hObject,'String')) returns contents of edit_userDataDirectory as a double


% --- Executes during object creation, after setting all properties.
function edit_userDataDirectory_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_userDataDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_userDataDirectory.
function pButton_userDataDirectory_Callback(~, ~, handles)
blank(handles)

% Define the start path
outputDirectory = uigetdir(pwd, 'Output Directory');

if isequal(outputDirectory, 0.0)
    % User cancelled operation
else
    set(handles.edit_userDataDirectory, 'string', outputDirectory)
end

enable(handles)


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
blank(handles)

% Get the path from the edit box
dataPath = get(handles.edit_userDataDirectory, 'string');

if get(handles.check_defaultDataDirectory, 'value') == 0.0
    % A user-defined directory is selected
    dataPath = get(handles.edit_userDataDirectory, 'string');
    
    if exist(dataPath, 'dir') ~= 7.0
        errordlg('Please select a valid directory.', 'Quick Fatigue Tool')
        uiwait
        enable(handles)
        return
    end
end
setappdata(0, 'qft_localMaterialDataPath', dataPath)

% Delete the old marker file if it exists
currentPath = getappdata(0, 'currentLocalPath');
if exist([currentPath, '\qft-local-material.txt'], 'file') == 2.0
    delete([currentPath, '\qft-local-material.txt'])
end

% Write the new marker file
try
    fid = fopen([dataPath, '\qft-local-material.txt'], 'w+');
    fprintf(fid, '%s', dataPath);
    fclose(fid);
catch exception
    msg = sprintf('An exception was encountered while setting the local material path.\n\nMATLAB returned the following error:\n\n%s', exception.message);
    errordlg(msg, 'Quick Fatigue Tool')
    uiwait
end

%{
    Try to add the local material directory to PATHDEF.m. This is an
    automatically generated file which contains the saved MATLAB path.
%}
if get(handles.check_saveLocalPath, 'value') == 1.0
    try
        material.saveDatabase(dataPath)
    catch exception
        msg = sprintf('An exception was encountered while saving the local material path.\n\nMATLAB returned the following error:\n\n%s', exception.message);
        errordlg(msg, 'Quick Fatigue Tool')
        uiwait
    end
end

% Close the GUI
close 'Set Local Material Database'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
%{
    The user pressed cancel. Try to set the default local database under
    DATA\MATERIAL\LOCAL.
%}
setappdata(0, 'qft_suppressDataPath', 1.0)

close 'Set Local Material Database'


% --- Executes when LocalMaterialDatabase is resized.
function LocalMaterialDatabase_ResizeFcn(~, ~, ~)
% hObject    handle to LocalMaterialDatabase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_warning.
function pButton_warning_Callback(~, ~, ~)
% hObject    handle to pButton_warning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function blank(handles)
set(findall(handles.LocalMaterialDatabase, '-property', 'Enable'), 'Enable', 'off')

function enable(handles)
set(findall(handles.LocalMaterialDatabase, '-property', 'Enable'), 'Enable', 'on')

if get(handles.check_defaultDataDirectory, 'value') == 1.0
    set(handles.text_currentDatabase, 'enable', 'off')
    set(handles.edit_userDataDirectory, 'enable', 'inactive')
    set(handles.edit_userDataDirectory, 'backgroundColor', [177/255, 206/255, 237/255])
    set(handles.pButton_userDataDirectory, 'enable', 'off')
elseif getappdata(0, 'missingDefaultLocalDatabase') == 1.0
    set(handles.check_defaultDataDirectory, 'enable', 'off')
end

set(handles.pButton_warning, 'enable', 'inactive')


% --- Executes when user attempts to close LocalMaterialDatabase.
function LocalMaterialDatabase_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to LocalMaterialDatabase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0, 'qft_suppressDataPath', 1.0)

% Save the panel state
setappdata(0, 'defaultDataPath_check_defaultDataDirectory', get(handles.check_defaultDataDirectory, 'value'))
setappdata(0, 'defaultDataPath_check_saveLocalPath', get(handles.check_saveLocalPath, 'value'))

% Hint: delete(hObject) closes the figure
delete(hObject);

rmappdata(0, 'missingDefaultLocalDatabase')


% --- Executes on button press in check_defaultDataDirectory.
function check_defaultDataDirectory_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    % Save the current path string
    setappdata(0, 'previousLocalPath', get(handles.edit_userDataDirectory, 'string'))
    
    % Search PATHDEF for any DATA\MATERIAL\LOCAL folder.
    defaultLocalPath = material.searchDatabase();
    
    if (isempty(defaultLocalPath) == 0.0) || (exist([pwd, '\Data\material\local'], 'dir') == 7.0)
        % An entry for DATA\MATERIAL\LOCAL was found in PATHDEF
        setappdata(0, 'missingDefaultLocalDatabase', 0.0)
        
        if isempty(defaultLocalPath) == 0.0
            set(handles.edit_userDataDirectory, 'string', defaultLocalPath)
        else
            set(handles.edit_userDataDirectory, 'string', [pwd, '\Data\material\local'])
        end
        
        set(handles.text_currentDatabase, 'enable', 'off')
        set(handles.edit_userDataDirectory, 'enable', 'inactive')
        set(handles.edit_userDataDirectory, 'backgroundColor', [177/255, 206/255, 237/255])
        set(handles.pButton_userDataDirectory, 'enable', 'off')
    else
        %{
            An entry for DATA\MATERIAL\LOCAL was not found in PATHDEF. Set
            the edit box to the current working directory and disable the
            default path checkbox.
        %}
        setappdata(0, 'missingDefaultLocalDatabase', 1.0)
        
        set(handles.check_defaultDataDirectory, 'enable', 'off')
        set(handles.check_defaultDataDirectory, 'value', 0.0)
        
        set(handles.text_currentDatabase, 'enable', 'on')
        set(handles.edit_userDataDirectory, 'enable', 'on')
        set(handles.edit_userDataDirectory, 'string', pwd)
        set(handles.edit_userDataDirectory, 'backgroundColor', 'white')
        set(handles.pButton_userDataDirectory, 'enable', 'on')
        
        blank(handles)
        errordlg('The default local material directory could not be found', 'Quick Fatigue Tool')
        uiwait
        enable(handles)
    end
else
    % Restore the previous path if applicable
    if isappdata(0, 'previousLocalPath') == 1.0
        set(handles.edit_userDataDirectory, 'string', getappdata(0, 'previousLocalPath'))
        rmappdata(0, 'previousLocalPath')
    end
    
    set(handles.text_currentDatabase, 'enable', 'on')
    set(handles.edit_userDataDirectory, 'enable', 'on')
    set(handles.edit_userDataDirectory, 'backgroundColor', 'white')
    set(handles.pButton_userDataDirectory, 'enable', 'on')
end


% --- Executes on button press in pButton_help.
function pButton_help_Callback(~, ~, handles)
blank(handles)

messages = sprintf('Specify the directory in which material data is to be stored.\n\n');

if isempty(getappdata(0, 'qft_localMaterialDataPath')) == 1.0
    string = 'suggested';
else
    string = 'current';
end

if getappdata(0, 'missingDefaultLocalDatabase') == 1.0
    msg1 = sprintf('The default local material directory is currently unavailable because it ');
    msg2 = sprintf('does not exist on the MATLAB path or inside PATHDEF.m.\n\n');
    msg3 = sprintf('Please ensure that the DATA folder included with the Quick Fatigue Tool ');
    msg4 = sprintf('application has not been renamed or removed, and exists on MATLAB''s ');
    msg5 = sprintf('current search path. In the meantime, an alternativelocal material directory should be specified.\n\n');
    
    messages = [messages, msg1, msg2, msg3, msg4, msg5];
elseif get(handles.check_defaultDataDirectory, 'value') == 1.0
    msg1 = sprintf('The %s (default) local material directory is the folder:\n\n', string);
    msg2 = sprintf('''%s''\n\n', get(handles.edit_userDataDirectory, 'string'));
    msg3 = sprintf('If you wish to specify the folder yourself, deselect "Default" ');
    msg4 = sprintf('and manually enter the path to the new folder.\n\n');
    
    messages = [messages, msg1, msg2, msg3, msg4];
else
    msg1 = sprintf('The %s local material directory is the folder:\n\n', string);
    msg2 = sprintf('''%s''\n\n', get(handles.edit_userDataDirectory, 'string'));
    
    messages = [messages, msg1, msg2];
end

msg1 = sprintf('If "Save path" is selected, the local material database path ');
msg2 = sprintf('will be written to PATHDEF.m so that it is remembered even if the location is ');
msg3 = sprintf('removed from MATLAB''s current search path. If this option is selected, it is ');
msg4 = sprintf('strongly recommended that you keep a back-up of this file.');
messages = [messages, msg1, msg2, msg3, msg4];

if getappdata(0, 'missingDefaultLocalDatabase') == 1.0
    warndlg(messages, 'Quick Fatigue Tool')
else
    msgbox(messages, 'Quick Fatigue Tool')
end

uiwait
enable(handles)


% --- Executes on button press in check_saveLocalPath.
function check_saveLocalPath_Callback(~, ~, ~)
