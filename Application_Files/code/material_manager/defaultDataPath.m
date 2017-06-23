function varargout = defaultDataPath(varargin)%#ok<*DEFNU>
%DEFAULTDATAPATH    QFT functions for Material Manager.
%   These functions are used to set the default user local material path.
%   
%   DEFAULTDATAPATH is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also checkDataPath, evaluateMaterial, importMaterial, kSolution,
%   material, MaterialManager, UserMaterial.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-00 Copyright Louis Vallance 2017
%   Last modified 23-Jun-2017 13:18:41 GMT
    
    %%

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @defaultDataPath_OpeningFcn, ...
                   'gui_OutputFcn',  @defaultDataPath_OutputFcn, ...
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


% --- Executes just before defaultDataPath is made visible.
function defaultDataPath_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to defaultDataPath (see VARARGIN)

% Choose default command line output for defaultDataPath
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes defaultDataPath wait for user response (see UIRESUME)
% uiwait(handles.figure1);

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
    set(handles.text_currentDatabase, 'string', 'Current local material directory:')
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
    
    if get(handles.check_defaultDataDirectory, 'value') == 0.0
        set(handles.text_currentDatabase, 'enable', 'on')
        set(handles.edit_userDataDirectory, 'enable', 'on')
        set(handles.pButton_userDataDirectory, 'enable', 'on')
    end
end

%% Check if the default path is available
if exist([pwd, '\Data\material\local'], 'dir') ~= 7.0
    set(handles.check_defaultDataDirectory, 'enable', 'off')
    set(handles.check_defaultDataDirectory, 'value', 0.0)
    set(handles.check_defaultDataDirectory, 'string', 'Default (currently unavailable)')
    
    set(handles.text_currentDatabase, 'enable', 'on')
    set(handles.edit_userDataDirectory, 'enable', 'on')
    set(handles.pButton_userDataDirectory, 'enable', 'on')
end

%% Set the default path
localPath = getappdata(0, 'qft_localMaterialDataPath');

if isempty(localPath) == 0.0
    set(handles.edit_userDataDirectory, 'string', localPath)
elseif exist([pwd, '\Data\material\local'], 'dir') == 7.0
    set(handles.edit_userDataDirectory, 'string', [pwd, '\Data\material\local'])
else
    set(handles.edit_userDataDirectory, 'string', pwd)
end

%% Set the current local path
if get(handles.check_defaultDataDirectory, 'value') == 1.0
    setappdata(0, 'currentLocalPath', [pwd, '\Data\material\local'])
else
    setappdata(0, 'currentLocalPath', get(handles.edit_userDataDirectory, 'string'))
end


% --- Outputs from this function are returned to the command line.
function varargout = defaultDataPath_OutputFcn(~, ~, handles) 
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
% Define the start path
outputDirectory = uigetdir(pwd, 'Output Directory');

if isequal(outputDirectory, 0.0)
    % User cancelled operation
else
    set(handles.edit_userDataDirectory, 'string', outputDirectory)
end


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
if get(handles.check_defaultDataDirectory, 'value') == 1.0
    % The default LOCAL directory is selected
    dataPath = [pwd, '\Data\material\local'];
    
    setappdata(0, 'qft_localMaterialDataPath', dataPath)
else
    % A user-defined directory is selected
    dataPath = get(handles.edit_userDataDirectory, 'string');
    
    if exist(dataPath, 'dir') ~= 7.0
        blank(handles)
        errordlg('Please select a valid directory.', 'Quick Fatigue Tool')
        uiwait
        enable(handles)
        return
    else
        setappdata(0, 'qft_localMaterialDataPath', dataPath)
    end
end

% Delete the old marker file if it exists
currentPath = getappdata(0, 'currentLocalPath');
if exist([currentPath, '\qft-local-material.txt'], 'file') == 2.0
    delete([currentPath, '\qft-local-material.txt'])
end

% Write the marker file
try
    fid = fopen([dataPath, '\qft-local-material.txt'], 'w+');
    fprintf(fid, '%s', dataPath);
    fclose(fid);
catch
end

% Close the GUI
close defaultDataPath


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
%{
    The user pressed cancel. Try to set the default local database under
    DATA\MATERIAL\LOCAL.
%}
setappdata(0, 'qft_suppressDataPath', 1.0)

close defaultDataPath


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(~, ~, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_warning.
function pButton_warning_Callback(~, ~, ~)
% hObject    handle to pButton_warning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function blank(handles)
set(findall(handles.figure1, '-property', 'Enable'), 'Enable', 'off')

function enable(handles)
set(findall(handles.figure1, '-property', 'Enable'), 'Enable', 'on')


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0, 'qft_suppressDataPath', 1.0)

% Save the panel state
setappdata(0, 'defaultDataPath_check_defaultDataDirectory', get(handles.check_defaultDataDirectory, 'value'))

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in check_defaultDataDirectory.
function check_defaultDataDirectory_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.text_currentDatabase, 'enable', 'off')
    set(handles.edit_userDataDirectory, 'enable', 'off')
    set(handles.pButton_userDataDirectory, 'enable', 'off')
else
    set(handles.text_currentDatabase, 'enable', 'on')
    set(handles.edit_userDataDirectory, 'enable', 'on')
    set(handles.pButton_userDataDirectory, 'enable', 'on')
end


% --- Executes on button press in pButton_help.
function pButton_help_Callback(~, ~, handles)
if strcmpi(get(handles.check_defaultDataDirectory, 'enable'), 'off') == 1.0
    msg1 = sprintf('The default local material directory is currently unavailable because it\n');
    msg2 = sprintf('does not exist on the MATLAB path.\n\n');
    msg3 = sprintf('Please ensure that the DATA folder included with the Quick Fatigue Tool\n');
    msg4 = sprintf('application has not been renamed or removed. In the meantime, an alternative ');
    msg5 = sprintf('local material directory should be specified.\n\n');
    msg6 = sprintf('This behaviour is normal when running Material Manager from the App bar\n');
    msg7 = sprintf('for the first time. Once the default local material path is initially set,\n');
    msg8 = sprintf('Quick Fatigue Tool will remember your choice.');
    msgbox([msg1, msg2, msg3, msg4, msg5, msg6, msg7, msg8], 'Quick Fatigue Tool')
else
    msg1 = sprintf('The default local material directory is the folder:\n\n');
    msg2 = sprintf('''%s\\Data\\material\\local''\n\n', pwd);
    msg3 = sprintf('If you wish to use another folder, deselect the check box and specify the\n');
    msg4 = sprintf('path to the new folder.\n');
    msgbox([msg1, msg2, msg3, msg4], 'Quick Fatigue Tool')
end
