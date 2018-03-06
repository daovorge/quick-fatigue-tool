function varargout = MaterialEditor(varargin)%#ok<*DEFNU>
%MATERIALEDITOR    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   MATERIALEDITOR is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also checkDataPath, evaluateMaterial, importMaterial,
%   kValueCalculator, LocalMaterialDatabase, material, MaterialManager.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 14-Dec-2017 11:52:41 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MaterialEditor_OpeningFcn, ...
                   'gui_OutputFcn',  @MaterialEditor_OutputFcn, ...
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


% --- Executes just before MaterialEditor is made visible.
function MaterialEditor_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MaterialEditor (see VARARGIN)

clc

%% Load icons
[a,~]=imread('icoR_delete.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_rmSNData, 'CData', g);

[a,~]=imread('icoR_amplitude.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_viewSNData, 'CData', g);

[a,~]=imread('icoR_calculator.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_k, 'CData', g);

[a,~]=imread('icoR_help.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_snHelp, 'CData', g);
set(handles.pButton_rHelp, 'CData', g);

[a,~]=imread('icoR_delete.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_rmRValues, 'CData', g);

[a,~]=imread('icoR_edit.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_viewRValues, 'CData', g);

[a,~]=imread('icoR_fileOpen.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_changeLocation, 'CData', g);

[a,~]=imread('icoR_knee.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_knee, 'CData', g);

%% Other tasks
% Choose default command line output for MaterialEditor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% Define SIMULIA blue color
setappdata(0, 'simulia_blue', [177/255, 206/255, 237/255])

% Initialize APPDATA properties
initializeMaterial

%% Populate dialogue box with user material for editing if user pressed
% "EDIT" in the material manager
if isappdata(0, 'editMaterial') == 1.0
    % Get the name of the material to edit
    materialToEdit = char(getappdata(0, 'materialToEdit'));
    
    % Clean up APPDATA
    rmappdata(0, 'editMaterial')
    rmappdata(0, 'materialToEdit')
    
    % Get the local material path
    localPath = getappdata(0, 'qft_localMaterialDataPath');
    
    % Get the material properties
    try
        properties = open([localPath, '\', materialToEdit, '.mat']);
    catch
        if exist(materialToEdit, 'file') == 0.0
            message = sprintf('Unable to open ''%s''.\n\nThe file is either corrupt or no longer exists in the local database.',...
            [materialToEdit, '.mat']);
        else
            message = sprintf('Unable to open ''%s''.',...
            [materialToEdit, '.mat']);
        end
        errordlg(message, 'Quick Fatigue Tool')
        uiwait
        return
    end    
    
    % Populate the dialogue box with the material properties
    try
        populateGUI(handles, properties, materialToEdit)
    catch
        message1 = sprintf('Error while reading ''%s'': One or more properties are inaccessible.\n\n',...
            [materialToEdit, '.mat']);
        message2 = sprintf('Displayed properties may be incomplete.');
        errordlg([message1 message2], 'Quick Fatigue Tool');    uiwait
    end
end

% Set availability of fatigue test data button
if get(handles.check_nssc, 'value') == 1.0
    set(handles.pButton_k, 'enable', 'off')
else
    set(handles.pButton_k, 'enable', 'on')
end

% Get the MSC string list
string = get(handles.pMenu_msc, 'string');
string{1.0} = 'Morrow';
string{2.0} = 'Goodman';
string{3.0} = 'Soderberg';
string{4.0} = 'Walker';
string{5.0} = 'Smith-Watson-Topper';
string{6.0} = 'Gerber';
string{7.0} = 'R-ratio S-N curves';
string{8.0} = 'None';

% Set the default MSC correction string list
if (get(handles.pMenu_algorithm, 'value') > 0.0 && get(handles.pMenu_algorithm, 'value')  < 7.0) || (get(handles.pMenu_algorithm, 'value') == 12.0 || get(handles.pMenu_algorithm, 'value') == 13.0)
    string{1.0} = 'Morrow (default)';
elseif get(handles.pMenu_algorithm, 'value') == 7.0 || get(handles.pMenu_algorithm, 'value') == 9.0 || get(handles.pMenu_algorithm, 'value') == 11.0
    string{2.0} = 'Goodman (default)';
end

% Set mean stress correction menu if Findley's Method is selected
if get(handles.pMenu_algorithm, 'value') == 8.0
    set(handles.pMenu_msc, 'backgroundColor', getappdata(0, 'simulia_blue')) 
    set(handles.pMenu_msc, 'value', 8.0)
    set(handles.pMenu_msc, 'enable', 'inactive')
    string{8.0} = 'Built-in (default)';
end

% Set mean stress correction menu if NASALIFE is selected
if get(handles.pMenu_algorithm, 'value') == 10.0
    string{4.0} = 'Walker (default)';
    set(handles.pMenu_msc, 'backgroundColor', getappdata(0, 'simulia_blue')) 
    set(handles.pMenu_msc, 'value', 4.0)
    set(handles.pMenu_msc, 'enable', 'inactive')
end

% Set the "Algorithm unavailable" warning string
alg = get(handles.pMenu_algorithm, 'value');
if (alg > 0.0 && alg < 5.0) || (alg == 11.0)
    set(handles.text_algorithmUnavailable, 'visible', 'on')
end

% Save the MSC string list
set(handles.pMenu_msc, 'string', string)

% Set the default material save location
qft_localMaterialDataPath = getappdata(0, 'qft_localMaterialDataPath');
if isempty(qft_localMaterialDataPath) == 1.0
    set(handles.edit_location, 'string', pwd)
else
    set(handles.edit_location, 'string', getappdata(0, 'qft_localMaterialDataPath'))
end

% Disable return button if applicable
if (isappdata(0, 'multiaxial_gauge_fatigue_skip_material_manager') == 1.0) || (isappdata(0, 'uniaxial_strain_life_skip_material_manager') == 1.0)
    set(handles.pButton_manager, 'enable', 'off')
end

% UIWAIT makes MaterialEditor wait for user response (see UIRESUME)
% uiwait(handles.MaterialEditor);


% --- Outputs from this function are returned to the command line.
function varargout = MaterialEditor_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in pMenu_matBehaviour.
function pMenu_matBehaviour_Callback(hObject, ~, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_matBehaviour contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_matBehaviour

switch get(hObject,'Value')
    case 1.0
    case 2.0
    case 3.0
        if get(handles.pMenu_regModel, 'value') == 1.0
            set(handles.pMenu_regModel, 'value', 2.0)
        end
end


% --- Executes during object creation, after setting all properties.
function pMenu_matBehaviour_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_matBehaviour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_regModel.
function pMenu_regModel_Callback(hObject, ~, handles)
switch get(hObject,'Value')
    case 1.0
        if get(handles.pMenu_matBehaviour, 'value') == 3.0
            set(handles.pMenu_matBehaviour, 'value', 1.0)
        end
    case 2.0
    case 3.0
end


% --- Executes during object creation, after setting all properties.
function pMenu_regModel_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_regModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_cael_Callback(~, ~, ~)
% hObject    handle to edit_cael (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cael as text
%        str2double(get(hObject,'String')) returns contents of edit_cael as a double


% --- Executes during object creation, after setting all properties.
function edit_cael_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_cael (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_cael.
function check_cael_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_cael, 'string', [])
        set(handles.edit_cael, 'enable', 'inactive')
        set(handles.edit_cael, 'backgroundColor', [177/255, 206/255, 237/255])
        set(handles.edit_cael, 'string', '2e+07')
        set(handles.text_cael_units, 'enable', 'off')
    case 1.0
        set(handles.edit_cael, 'enable', 'on')
        set(handles.edit_cael, 'backgroundColor', [1.0, 1.0, 1.0])
        set(handles.text_cael_units, 'enable', 'on')
end


function edit_uts_Callback(~, ~, ~)
% hObject    handle to edit_uts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_uts as text
%        str2double(get(hObject,'String')) returns contents of edit_uts as a double


% --- Executes during object creation, after setting all properties.
function edit_uts_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_uts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_uts.
function check_uts_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        setappdata(0, 'uts_value', get(handles.edit_uts, 'string'))
        set(handles.edit_uts, 'string', [])
        set(handles.text_slash, 'enable', 'off')
        set(handles.edit_uts, 'enable', 'inactive')
        set(handles.edit_uts, 'backgroundColor', [241/255, 241/255, 241/255])
        set(handles.text_uts_units, 'enable', 'off')
        
        setappdata(0, 'ucs_value', get(handles.edit_ucs, 'string'))
        set(handles.edit_ucs, 'string', [])
        set(handles.edit_ucs, 'enable', 'inactive')
        set(handles.edit_ucs, 'backgroundColor', [241/255, 241/255, 241/255])
    case 1.0
        set(handles.edit_uts, 'enable', 'on')
        set(handles.edit_uts, 'backgroundColor', [1, 1, 1])
        set(handles.text_slash, 'enable', 'on')
        set(handles.edit_uts, 'string', getappdata(0, 'uts_value'))
        set(handles.text_uts_units, 'enable', 'on')
        
        set(handles.edit_ucs, 'enable', 'on')
        set(handles.edit_ucs, 'backgroundColor', [1, 1, 1])
        set(handles.edit_ucs, 'string', getappdata(0, 'ucs_value'))
end


function edit_e_Callback(~, ~, ~)
% hObject    handle to edit_e (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_e as text
%        str2double(get(hObject,'String')) returns contents of edit_e as a double


% --- Executes during object creation, after setting all properties.
function edit_e_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_e (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_e.
function check_e_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        setappdata(0, 'e_value', get(handles.edit_e, 'string'))
        set(handles.edit_e, 'string', [])
        set(handles.edit_e, 'enable', 'inactive')
        set(handles.edit_e, 'backgroundColor', [241/255, 241/255, 241/255])
        set(handles.text_e_units, 'enable', 'off')
    case 1.0
        set(handles.edit_e, 'enable', 'on')
        set(handles.edit_e, 'backgroundColor', [1.0, 1.0, 1.0])
        set(handles.edit_e, 'string', getappdata(0, 'e_value'))
        set(handles.text_e_units, 'enable', 'on')
end


function edit_proof_Callback(~, ~, ~)
% hObject    handle to edit_proof (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_proof as text
%        str2double(get(hObject,'String')) returns contents of edit_proof as a double


% --- Executes during object creation, after setting all properties.
function edit_proof_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_proof (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_proof.
function check_proof_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_proof, 'enable', 'inactive')
        set(handles.edit_proof, 'backgroundColor', [177/255, 206/255, 237/255])
        set(handles.text_proof_units, 'enable', 'off')
    case 1.0
        set(handles.edit_proof, 'enable', 'on')
        set(handles.edit_proof, 'backgroundColor', [1.0, 1.0, 1.0])
        set(handles.text_proof_units, 'enable', 'on')
end


function edit_sf_Callback(~, ~, ~)
% hObject    handle to edit_sf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_sf as text
%        str2double(get(hObject,'String')) returns contents of edit_sf as a double


% --- Executes during object creation, after setting all properties.
function edit_sf_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_sf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_sf.
function check_sf_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_sf, 'enable', 'inactive')
        set(handles.edit_sf, 'backgroundColor', [177/255, 206/255, 237/255])
        set(handles.text_sf_units, 'enable', 'off')
    case 1.0
        set(handles.edit_sf, 'enable', 'on')
        set(handles.edit_sf, 'backgroundColor', [1.0, 1.0, 1.0])
        set(handles.text_sf_units, 'enable', 'on')
end



function edit_b_Callback(~, ~, ~)
% hObject    handle to edit_b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_b as text
%        str2double(get(hObject,'String')) returns contents of edit_b as a double


% --- Executes during object creation, after setting all properties.
function edit_b_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_b.
function check_b_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        setappdata(0, 'b_value', get(handles.edit_b, 'string'))
        set(handles.edit_b, 'string', [])
        set(handles.edit_b, 'enable', 'inactive')
        set(handles.pButton_knee, 'enable', 'off')
        set(handles.edit_b, 'backgroundColor', [177/255, 206/255, 237/255])
    case 1.0
        set(handles.edit_b, 'enable', 'on')
        set(handles.pButton_knee, 'enable', 'on')
        set(handles.edit_b, 'backgroundColor', [1, 1, 1])
        set(handles.edit_b, 'string', getappdata(0, 'b_value'))
end


function edit_ef_Callback(~, ~, ~)
% hObject    handle to edit_ef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ef as text
%        str2double(get(hObject,'String')) returns contents of edit_ef as a double


% --- Executes during object creation, after setting all properties.
function edit_ef_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_ef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_c_Callback(~, ~, ~)
% hObject    handle to edit_c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_c as text
%        str2double(get(hObject,'String')) returns contents of edit_c as a double


% --- Executes during object creation, after setting all properties.
function edit_c_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_ef.
function check_ef_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_ef, 'enable', 'inactive')
        set(handles.edit_ef, 'backgroundColor', [177/255, 206/255, 237/255])
    case 1.0
        set(handles.edit_ef, 'enable', 'on')
        set(handles.edit_ef, 'backgroundColor', [1, 1, 1])
end


% --- Executes on button press in check_c.
function check_c_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_c, 'enable', 'inactive')
        set(handles.edit_c, 'backgroundColor', [177/255, 206/255, 237/255])
    case 1.0
        set(handles.edit_c, 'enable', 'on')
        set(handles.edit_c, 'backgroundColor', [1, 1, 1])
end


function edit_kp_Callback(~, ~, ~)
% hObject    handle to edit_kp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_kp as text
%        str2double(get(hObject,'String')) returns contents of edit_kp as a double


% --- Executes during object creation, after setting all properties.
function edit_kp_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_kp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_np_Callback(~, ~, ~)
% hObject    handle to edit_np (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_np as text
%        str2double(get(hObject,'String')) returns contents of edit_np as a double


% --- Executes during object creation, after setting all properties.
function edit_np_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_np (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_kp.
function check_kp_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_kp, 'enable', 'inactive')
        set(handles.edit_kp, 'backgroundColor', [177/255, 206/255, 237/255])
        set(handles.text_kp_units, 'enable', 'off')
    case 1.0
        set(handles.edit_kp, 'enable', 'on')
        set(handles.edit_kp, 'backgroundColor', [1.0, 1.0, 1.0])
        set(handles.text_kp_units, 'enable', 'on')
end


% --- Executes on button press in check_np.
function check_np_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_np, 'enable', 'inactive')
        set(handles.edit_np, 'backgroundColor', [177/255, 206/255, 237/255])
    case 1.0
        set(handles.edit_np, 'enable', 'on')
        set(handles.edit_np, 'backgroundColor', [1, 1, 1])
end


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

%% First check that the material name is valid
if isempty(get(handles.edit_name, 'string')) == 1.0
    errordlg('A material name must be entered.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    return
elseif isempty(regexp(get(handles.edit_name, 'string'), '[/\\*:?"<>|]', 'once')) == 0.0
    message1 = sprintf('The material name cannot contain any of the following characters:\n\n');
    message2 = sprintf('/ \\ * : ? " < > | ');
    errordlg([message1, message2], 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    return
end

%% Then check that R-values are consistent with S-N data
S = getappdata(gcf, 'S_values');

if isempty(S) == 0.0
    r_values = getappdata(gcf, 'R_values');
    
    % Get the number of S-N data sets
    [sets, ~] = size(S);
    
    if (length(r_values) ~= sets)
        if sets == 1.0 && isempty(r_values) == 1.0
            setappdata(gcf, 'R_values', -1.0)
        else
            ln1 = sprintf('The number of R-values does not match the number of S-N datasets.\n\n');
            ln2 = sprintf('The material will not be saved.');
            ln = [ln1, ln2];
            errordlg(ln, 'Quick Fatigue Tool')
            uiwait
            
            % Enable the GUI
            enable(handles)
            return
        end
    end
end

%% Did the user specify a custom save location?
if get(handles.check_location, 'value') == 1.0
    pathname = [get(handles.edit_location, 'string'), '\'];
elseif isempty(getappdata(0, 'qft_localMaterialDataPath')) == 0.0
    pathname = [getappdata(0, 'qft_localMaterialDataPath'), '\'];
else
    pathname = [pwd, '\'];
end

shortFilename = get(handles.edit_name, 'string');
filename = [get(handles.edit_name, 'string'), '.mat'];
fullpath = [pathname, filename];
    
if exist(fullpath, 'file') ~= 2.0
    % The material doesn't exist in the user material database, so save it
    % silently
else
    % The material already exists in the user material database, so prompt
    % the user whether they would like to overwrite the original
    msg = sprintf('''%s'' already exists in the local database. Do you wish to overwrite the material?', get(handles.edit_name, 'string'));
    
    response = questdlg(msg, 'Quick Fatigue Tool');
    
    if (strcmpi(response, 'no') == 1.0) || (strcmpi(response, 'cancel') == 1.0) || (isempty(response) == 1.0)
        % Enable the GUI
        enable(handles)
        return
    end
end

material_properties = saveMaterial(handles); %#ok<NASGU>

%% Check that the save directory exists
if strcmpi(pathname, '\') == 1.0
    errordlg('The material save location cannot be empty.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    return
elseif exist(pathname, 'dir') == 0.0
    errordlg('The material save location does not exist.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    return
end

%% Save the material
try
    save(fullpath, 'material_properties')
catch
    errordlg('Unable to save material. Make sure the material save location has read/write access.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    return
end

close 'Material Editor'

%{
    Under normal operation, display the material manager dialogue. If the
    material editor was accessed via the multiaxial gauge fatigue dialogue,
    or if the user pressed cancel, skip the material manager
%}
if isempty(getappdata(0, 'multiaxial_gauge_fatigue_skip_material_manager')) == 1.0 &&...
        isempty(getappdata(0, 'uniaxial_strain_life_skip_material_manager')) == 1.0 &&...
        isempty(getappdata(0, 'pressed_cancel_skip_material_manager')) == 1.0
    MaterialManager
elseif isappdata(0, 'multiaxial_gauge_fatigue_skip_material_manager') == 1.0
    setappdata(0, 'material_for_multiaxial_gauge_fatigue', shortFilename)
elseif isappdata(0, 'uniaxial_strain_life_skip_material_manager') == 1.0
    setappdata(0, 'material_for_uniaxial_strain_life', shortFilename)
end

% Suppress local material path dialogue
setappdata(0, 'qft_suppressDataPath', 1.0)


% --- Executes on button press in pButton_close.
function pButton_close_Callback(hObject, eventdata, handles)
% Blank the GUI
blank(handles)

answer = questdlg('Save changes made in the User Material dialogue?',...
    'Quick Fatigue Tool', 'Yes', 'No', 'Cancel', 'Cancel');
if strcmpi(answer, 'yes') == 1.0
    setappdata(0, 'pressed_cancel_skip_material_manager', 1.0)
    pButton_ok_Callback(hObject, eventdata, handles)
    rmappdata(0, 'pressed_cancel_skip_material_manager')
elseif strcmpi(answer, 'no') == 1.0
    close 'Material Editor'
else
    % Enable the GUI
    enable(handles)
end


function edit_poisson_Callback(~, ~, ~)
% hObject    handle to edit_poisson (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_poisson as text
%        str2double(get(hObject,'String')) returns contents of edit_poisson as a double


% --- Executes during object creation, after setting all properties.
function edit_poisson_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_poisson (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_poisson.
function check_poisson_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        setappdata(0, 'poisson_value', get(handles.edit_poisson, 'string'))
        set(handles.edit_poisson, 'enable', 'inactive')
        set(handles.edit_poisson, 'backgroundColor', [241/255, 241/255, 241/255])
        set(handles.edit_poisson, 'string', '0.33')
    case 1.0
        set(handles.edit_poisson, 'enable', 'on')
        set(handles.edit_poisson, 'backgroundColor', [1, 1, 1])
        if isempty(getappdata(0, 'poisson_value')) == 0.0
            set(handles.edit_poisson, 'string', getappdata(0, 'poisson_value'))
        end
end


function edit_nssc_Callback(~, ~, ~)
% hObject    handle to edit_nssc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_nssc as text
%        str2double(get(hObject,'String')) returns contents of edit_nssc as a double


% --- Executes during object creation, after setting all properties.
function edit_nssc_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_nssc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_nssc.
function check_nssc_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        setappdata(0, 'nssc_value', get(handles.edit_nssc, 'string'))
        set(handles.edit_nssc, 'string', [])
        set(handles.edit_nssc, 'enable', 'inactive')
        set(handles.edit_nssc, 'backgroundColor', [177/255, 206/255, 237/255])
        
        set(handles.pButton_k, 'enable', 'on')
    case 1.0
        set(handles.edit_nssc, 'enable', 'on')
        set(handles.edit_nssc, 'backgroundColor', [1, 1, 1])
        
        set(handles.pButton_k, 'enable', 'off')
        set(handles.edit_nssc, 'string', getappdata(0, 'nssc_value'))
end


% --- Executes on selection change in pMenu_class.
function pMenu_class_Callback(~, ~, ~)
% hObject    handle to pMenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_class contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_class


% --- Executes during object creation, after setting all properties.
function pMenu_class_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_name_Callback(~, ~, ~)
% hObject    handle to edit_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_name as text
%        str2double(get(hObject,'String')) returns contents of edit_name as a double


% --- Executes during object creation, after setting all properties.
function edit_name_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_algorithm.
function pMenu_algorithm_Callback(hObject, ~, handles)
% Get the selected algorithm
selectedAlgorithm = get(hObject, 'value');

% If the user select an algorithm header, select the algorithm directly
% underneath
if selectedAlgorithm == 1.0 || selectedAlgorithm == 5.0 || selectedAlgorithm == 12.0
    set(hObject, 'value', 1.0 + selectedAlgorithm)
    
    % Update the value of the selected algorithm
    selectedAlgorithm = 1.0 + selectedAlgorithm;
end

% Reset the MSC string list
string = get(handles.pMenu_msc, 'string');
string{1.0} = 'Morrow';
string{2.0} = 'Goodman';
string{3.0} = 'Soderberg';
string{4.0} = 'Walker';
string{5.0} = 'Smith-Watson-Topper';
string{6.0} = 'Gerber';
string{7.0} = 'R-ratio S-N curves';
string{8.0} = 'None';

% If the algorithm is set to Findley's Method, disable the mean stress
% correction box
if selectedAlgorithm == 8.0
    set(handles.pMenu_msc, 'backgroundColor', getappdata(0, 'simulia_blue')) 
    set(handles.pMenu_msc, 'value', 8.0)
    set(handles.pMenu_msc, 'enable', 'inactive')
    string{8.0} = 'Built-in (default)';
    set(handles.pMenu_msc, 'string', string)
    setappdata(0, 'builtIn_to_morrow', 1.0)
else
    set(handles.pMenu_msc, 'backgroundColor', 'white') 
    set(handles.pMenu_msc, 'enable', 'on')    
    string{8.0} = 'None';
    set(handles.pMenu_msc, 'string', string)
    
    if getappdata(0, 'builtIn_to_morrow') == 1.0
        set(handles.pMenu_msc, 'value', 1.0)
        rmappdata(0, 'builtIn_to_morrow')
    end
end

% If the algorithm is set to NASALIFE, disable the mean stress
% correction box
if selectedAlgorithm == 10.0
    string{4.0} = 'Walker (default)';
    set(handles.pMenu_msc, 'string', string)
    
    set(handles.pMenu_msc, 'backgroundColor', getappdata(0, 'simulia_blue')) 
    set(handles.pMenu_msc, 'value', 4.0)
    set(handles.pMenu_msc, 'enable', 'inactive')
end

if selectedAlgorithm == 6.0
    % If the algorithm is set to SBBM, change the default MSC
    % to Morrow
    string{1.0} = 'Morrow (default)';
    set(handles.pMenu_msc, 'string', string)
    
    set(handles.pMenu_msc, 'value', 1.0)
elseif selectedAlgorithm == 7.0 || selectedAlgorithm == 9.0 || selectedAlgorithm == 11.0 || selectedAlgorithm == 14.0
    % If the algorithm is set to Goodman-like algorithm, change the default MSC
    % to Goodman
    string{2.0} = 'Goodman (default)';
    set(handles.pMenu_msc, 'string', string)
    
    set(handles.pMenu_msc, 'value', 2.0)
elseif selectedAlgorithm ~= 8.0 && selectedAlgorithm ~= 10.0
    % If the algorithm is set to Morrow-like algorithm, change the default MSC
    % to Goodman
    string{1.0} = 'Morrow (default)';
    set(handles.pMenu_msc, 'string', string)
    
    set(handles.pMenu_msc, 'value', 1.0)
end

% Alert the user if the algorithm is not yet available
algorithm = get(hObject, 'value');
if (algorithm > 0.0 && algorithm < 5.0) || (algorithm == 11.0)
    set(handles.text_algorithmUnavailable, 'visible', 'on')
else
    set(handles.text_algorithmUnavailable, 'visible', 'off')
end


% --- Executes during object creation, after setting all properties.
function pMenu_algorithm_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_algorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_msc.
function pMenu_msc_Callback(~, ~, ~)
% hObject    handle to pMenu_msc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_msc contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_msc


% --- Executes during object creation, after setting all properties.
function pMenu_msc_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_msc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

response = questdlg('All fields will be reset. OK to continue?', 'Quick Fatigue Tool', 'Yes', 'No', 'No');
if (strcmpi(response, 'no') == 1.0) || (isempty(response) == 1.0)
    
    % Enable the GUI
    enable(handles)
    return
else
    %% Reset objects to their original state
    simulia_blue = getappdata(0, 'simulia_blue');
    
    set(handles.edit_name, 'string', 'Material-1')
    set(handles.edit_comment, 'string', '')
    set(handles.edit_location, 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
    qft_localMaterialDataPath = getappdata(0, 'qft_localMaterialDataPath');
    if isempty(qft_localMaterialDataPath) == 1.0
        set(handles.edit_location, 'string', pwd)
    else
        set(handles.edit_location, 'string', getappdata(0, 'qft_localMaterialDataPath'))
    end
    set(handles.check_location, 'value', 0.0)
    set(handles.pButton_changeLocation, 'enable', 'off')
    set(handles.pMenu_algorithm, 'value', 6.0)
    set(handles.pMenu_msc, 'value', 1.0, 'enable', 'on', 'backgroundColor', 'white')
    set(handles.pMenu_class, 'value', 1.0)
    set(handles.edit_cael, 'string', '2e+07', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_cael, 'value', 0.0)
    set(handles.check_ndCompression, 'value', 0.0)
    set(handles.pMenu_matBehaviour, 'value', 1.0)
    set(handles.pMenu_regModel, 'value', 1.0)
    set(handles.edit_e, 'string', '', 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
    set(handles.check_e, 'value', 0.0)
    set(handles.check_uts, 'value', 0.0)
    set(handles.edit_uts, 'string', '', 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
    set(handles.edit_ucs, 'string', '', 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
    set(handles.edit_proof, 'string', '', 'enable', 'inactive', 'backgroundColor', 'white')
    set(handles.edit_proof, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_proof, 'value', 0.0)
    set(handles.edit_poisson, 'string', '0.33', 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
    set(handles.check_poisson, 'value', 0.0)
    set(handles.edit_snData, 'string', 'Undefined')
    set(handles.pButton_viewSNData, 'enable', 'off')
    set(handles.pButton_rmSNData, 'enable', 'off')
    set(handles.edit_rValues, 'string', 'Undefined')
    set(handles.pButton_viewRValues, 'enable', 'off')
    set(handles.pButton_rmRValues, 'enable', 'off')
    setappdata(0, 'panel_userMaterial_snData', [pwd, '/Data/material/sn_data'])
    set(handles.edit_sf, 'string', '', 'enable', 'inactive', 'backgroundColor', 'white')
    set(handles.edit_sf, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_sf, 'value', 0.0)
    set(handles.edit_b, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.pButton_knee, 'enable', 'off')
    set(handles.check_b, 'value', 0.0)
    set(handles.edit_ef, 'string', '', 'enable', 'inactive', 'backgroundColor', 'white')
    set(handles.edit_ef, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_ef, 'value', 0.0)
    set(handles.edit_c, 'string', '', 'enable', 'inactive', 'backgroundColor', 'white')
    set(handles.edit_c, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_c, 'value', 0.0)
    set(handles.edit_kp, 'string', '', 'enable', 'inactive', 'backgroundColor', 'white')
    set(handles.edit_kp, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_kp, 'value', 0.0)
    set(handles.edit_np, 'string', '', 'enable', 'inactive', 'backgroundColor', 'white')
    set(handles.edit_np, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_np, 'value', 0.0)
    set(handles.edit_nssc, 'string', '', 'enable', 'inactive', 'backgroundColor', simulia_blue)
    set(handles.check_nssc, 'value', 0.0)
    set(handles.pButton_k, 'enable', 'on')
    set(handles.text_algorithmUnavailable, 'visible', 'off')
    
    string = get(handles.pMenu_msc, 'string');
    string{1.0} = 'Morrow (default)';
    string{2.0} = 'Goodman';
    string{3.0} = 'Soderberg';
    string{4.0} = 'Walker';
    string{5.0} = 'Smith-Watson-Topper';
    string{6.0} = 'Gerber';
    string{7.0} = 'R-ratio S-N curves';
    string{8.0} = 'None';
    set(handles.pMenu_msc, 'string', string)
    
    set(handles.text_cael_units, 'enable', 'off')
    set(handles.text_e_units, 'enable', 'off')
    set(handles.text_uts_units, 'enable', 'off')
    set(handles.text_proof_units, 'enable', 'off')
    set(handles.text_sf_units, 'enable', 'off')
    set(handles.text_kp_units, 'enable', 'off')
    
    % Knee
    if isappdata(0, 'b2') == 1.0
        rmappdata(0, 'b2')
    end
    if isappdata(0, 'b2Nf') == 1.0
        rmappdata(0, 'b2Nf')
    end
    
    % NSSC
    if isappdata(0, 'nssc_value') == 1.0
        rmappdata(0, 'nssc_value')
    end
    
    % Reset composite failure properties
    
    % Fail stress
    if isappdata(0, 'failStress_tsfd') == 1.0
        rmappdata(0, 'failStress_tsfd')
    end
    if isappdata(0, 'failStress_csfd') == 1.0
        rmappdata(0, 'failStress_csfd')
    end
    if isappdata(0, 'failStress_tstd') == 1.0
        rmappdata(0, 'failStress_tstd')
    end
    if isappdata(0, 'failStress_cstd') == 1.0
        rmappdata(0, 'failStress_cstd')
    end
    if isappdata(0, 'failStress_tsttd') == 1.0
        rmappdata(0, 'failStress_tsttd')
    end
    if isappdata(0, 'failStress_csttd') == 1.0
        rmappdata(0, 'failStress_csttd')
    end
    if isappdata(0, 'failStress_shear') == 1.0
        rmappdata(0, 'failStress_shear')
    end
    if isappdata(0, 'failStress_cross12') == 1.0
        setappdata(0, 'failStress_cross12', 0.0)
    end
    if isappdata(0, 'failStress_cross23') == 1.0
        setappdata(0, 'failStress_cross23', 0.0)
    end
    if isappdata(0, 'failStress_limit12') == 1.0
        rmappdata(0, 'failStress_limit12')
    end
    if isappdata(0, 'failStress_limit23') == 1.0
        rmappdata(0, 'failStress_limit23')
    end
    
    % Fail strain
    if isappdata(0, 'failStrain_tsfd') == 1.0
        rmappdata(0, 'failStrain_tsfd')
    end
    if isappdata(0, 'failStrain_csfd') == 1.0
        rmappdata(0, 'failStrain_csfd')
    end
    if isappdata(0, 'failStrain_tstd') == 1.0
        rmappdata(0, 'failStrain_tstd')
    end
    if isappdata(0, 'failStrain_cstd') == 1.0
        rmappdata(0, 'failStrain_cstd')
    end
    if isappdata(0, 'failStrain_shear') == 1.0
        rmappdata(0, 'failStrain_shear')
    end
    if isappdata(0, 'failStrain_e11') == 1.0
        rmappdata(0, 'failStrain_e11')
    end
    if isappdata(0, 'failStrain_e22') == 1.0
        rmappdata(0, 'failStrain_e22')
    end
    if isappdata(0, 'failStrain_g12') == 1.0
        rmappdata(0, 'failStrain_g12')
    end
    
    % Hashin
    if isappdata(0, 'hashin_alpha') == 1.0
        setappdata(0, 'hashin_alpha', 0.0)
    end
    if isappdata(0, 'hashin_lts') == 1.0
        rmappdata(0, 'hashin_lts')
    end
    if isappdata(0, 'hashin_lcs') == 1.0
        rmappdata(0, 'hashin_lcs')
    end
    if isappdata(0, 'hashin_tts') == 1.0
        rmappdata(0, 'hashin_tts')
    end
    if isappdata(0, 'hashin_tcs') == 1.0
        rmappdata(0, 'hashin_tcs')
    end
    if isappdata(0, 'hashin_lss') == 1.0
        rmappdata(0, 'hashin_lss')
    end
    if isappdata(0, 'hashin_tss') == 1.0
        rmappdata(0, 'hashin_tss')
    end
    
    % LaRC05
    if isappdata(0, 'larc05_lts') == 1.0
        rmappdata(0, 'larc05_lts')
    end
    if isappdata(0, 'larc05_lcs') == 1.0
        rmappdata(0, 'larc05_lcs')
    end
    if isappdata(0, 'larc05_tts') == 1.0
        rmappdata(0, 'larc05_tts')
    end
    if isappdata(0, 'larc05_tcs') == 1.0
        rmappdata(0, 'larc05_tcs')
    end
    if isappdata(0, 'larc05_lss') == 1.0
        rmappdata(0, 'larc05_lss')
    end
    if isappdata(0, 'larc05_tss') == 1.0
        rmappdata(0, 'larc05_tss')
    end
    if isappdata(0, 'larc05_shear') == 1.0
        rmappdata(0, 'larc05_shear')
    end
    if isappdata(0, 'larc05_nl') == 1.0
        rmappdata(0, 'larc05_nl')
    end
    if isappdata(0, 'larc05_nt') == 1.0
        rmappdata(0, 'larc05_nt')
    end
    if isappdata(0, 'larc05_alpha0') == 1.0
        rmappdata(0, 'larc05_alpha0')
    end
    if isappdata(0, 'larc05_phi0') == 1.0
        rmappdata(0, 'larc05_phi0')
    end
    if isappdata(0, 'larc05_iterate') == 1.0
        rmappdata(0, 'larc05_iterate')
    end
    
    % k-value calculation
    if isappdata(0, 'k_solution_model') == 1.0
        rmappdata(0, 'k_solution_model')
    end
    if isappdata(0, 'k_solution_r') == 1.0
        rmappdata(0, 'k_solution_r')
    end
    if isappdata(0, 'k_solution_fi') == 1.0
        rmappdata(0, 'k_solution_fi')
    end
    if isappdata(0, 'k_solution_t') == 1.0
        rmappdata(0, 'k_solution_t')
    end
    if isappdata(0, 'k_solution_uts') == 1.0
        rmappdata(0, 'k_solution_uts')
    end
end

% Enable the GUI
enable(handles)

function material_properties = saveMaterial(handles)
material_properties = struct(...
'default_algorithm', get(handles.pMenu_algorithm, 'value'),...
'default_msc', get(handles.pMenu_msc, 'value'),...
'class', get(handles.pMenu_class, 'value'),...
'behavior', get(handles.pMenu_matBehaviour, 'value'),...
'reg_model', get(handles.pMenu_regModel, 'value'),...
'cael', get(handles.edit_cael, 'string'),...
'cael_active', get(handles.check_cael, 'value'),...
'ndCompression', get(handles.check_ndCompression, 'value'),...
'e', get(handles.edit_e, 'string'),...
'e_active', get(handles.check_e, 'value'),...
'uts', get(handles.edit_uts, 'string'),...
'ucs', get(handles.edit_ucs, 'string'),...
'uts_active', get(handles.check_uts, 'value'),...
'proof', get(handles.edit_proof, 'string'),...
'proof_active', get(handles.check_proof, 'value'),...
'poisson', get(handles.edit_poisson, 'string'),...
'poisson_active', get(handles.check_poisson, 'value'),...
's_values', getappdata(gcf, 'S_values'),...
'n_values', getappdata(gcf, 'N_values'),...
'r_values', getappdata(gcf, 'R_values'),...
'sf', get(handles.edit_sf, 'string'),...
'sf_active', get(handles.check_sf, 'value'),...
'b', get(handles.edit_b, 'string'),...
'b_active', get(handles.check_b, 'value'),...
'b2', getappdata(0, 'b2'),...
'b2Nf', getappdata(0, 'b2Nf'),...
'ef', get(handles.edit_ef, 'string'),...
'ef_active', get(handles.check_ef, 'value'),...
'c', get(handles.edit_c, 'string'),...
'c_active', get(handles.check_c, 'value'),...
'kp', get(handles.edit_kp, 'string'),...
'kp_active', get(handles.check_kp, 'value'),...
'np', get(handles.edit_np, 'string'),...
'np_active', get(handles.check_np, 'value'),...
'nssc', get(handles.edit_nssc, 'string'),...
'nssc_active', get(handles.check_nssc, 'value'),...
'comment', get(handles.edit_comment, 'string'),...
'failStress_tsfd', getappdata(0, 'failStress_tsfd'),...
'failStress_csfd', getappdata(0, 'failStress_csfd'),...
'failStress_tstd', getappdata(0, 'failStress_tstd'),...
'failStress_cstd', getappdata(0, 'failStress_cstd'),...
'failStress_tsttd', getappdata(0, 'failStress_tsttd'),...
'failStress_csttd', getappdata(0, 'failStress_csttd'),...
'failStress_shear', getappdata(0, 'failStress_shear'),...
'failStress_cross12', getappdata(0, 'failStress_cross12'),...
'failStress_cross23', getappdata(0, 'failStress_cross23'),...
'failStress_limit12', getappdata(0, 'failStress_limit12'),...
'failStress_limit23', getappdata(0, 'failStress_limit23'),...
'failStrain_tsfd', getappdata(0, 'failStrain_tsfd'),...
'failStrain_csfd', getappdata(0, 'failStrain_csfd'),...
'failStrain_tstd', getappdata(0, 'failStrain_tstd'),...
'failStrain_cstd', getappdata(0, 'failStrain_cstd'),...
'failStrain_shear', getappdata(0, 'failStrain_shear'),...
'failStrain_e11', getappdata(0, 'failStrain_e11'),...
'failStrain_e22', getappdata(0, 'failStrain_e22'),...
'failStrain_g12', getappdata(0, 'failStrain_g12'),...
'hashin_alpha', getappdata(0, 'hashin_alpha'),...
'hashin_lts', getappdata(0, 'hashin_lts'),...
'hashin_lcs', getappdata(0, 'hashin_lcs'),...
'hashin_tts', getappdata(0, 'hashin_tts'),...
'hashin_tcs', getappdata(0, 'hashin_tcs'),...
'hashin_lss', getappdata(0, 'hashin_lss'),...
'hashin_tss', getappdata(0, 'hashin_tss'),...
'larc05_lts', getappdata(0, 'larc05_lts'),...
'larc05_lcs', getappdata(0, 'larc05_lcs'),...
'larc05_tts', getappdata(0, 'larc05_tts'),...
'larc05_tcs', getappdata(0, 'larc05_tcs'),...
'larc05_lss', getappdata(0, 'larc05_lss'),...
'larc05_tss', getappdata(0, 'larc05_tss'),...
'larc05_shear', getappdata(0, 'larc05_shear'),...
'larc05_nl', getappdata(0, 'larc05_nl'),...
'larc05_nt', getappdata(0, 'larc05_nt'),...
'larc05_alpha0', getappdata(0, 'larc05_alpha0'),...
'larc05_phi0', getappdata(0, 'larc05_phi0'),...
'larc05_iterate', getappdata(0, 'larc05_iterate'));


function [] = populateGUI(handles, properties, materialToEdit)
set(handles.edit_name, 'string', materialToEdit)
set(handles.edit_comment, 'string', properties.material_properties.comment)
set(handles.pMenu_algorithm, 'value', properties.material_properties.default_algorithm)
set(handles.pMenu_msc, 'value', properties.material_properties.default_msc)

set(handles.edit_cael, 'string', properties.material_properties.cael)
if properties.material_properties.cael_active == 1.0
    set(handles.edit_cael, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_cael, 'value', 1.0)
    set(handles.text_cael_units, 'enable', 'on')
else
    set(handles.edit_cael, 'string', '2e+07')
end

try
    if isempty(properties.material_properties.ndCompression) == 1.0
        set(handles.check_ndCompression, 'value', 0.0)
    else
        set(handles.check_ndCompression, 'value', properties.material_properties.ndCompression)
    end
catch
    set(handles.check_ndCompression, 'value', 0.0)
end

if properties.material_properties.reg_model == 5.0
    set(handles.pMenu_matBehaviour, 'value', properties.material_properties.behavior)
    set(handles.pMenu_regModel, 'value', properties.material_properties.reg_model)
elseif properties.material_properties.behavior == 3.0
    set(handles.pMenu_matBehaviour, 'value', properties.material_properties.behavior)
    
    set(handles.pMenu_regModel, 'value', 2.0)
else
    set(handles.pMenu_matBehaviour, 'value', properties.material_properties.behavior)
    set(handles.pMenu_regModel, 'value', properties.material_properties.reg_model)
end

set(handles.edit_e, 'string', properties.material_properties.e)
if properties.material_properties.e_active == 1.0
    set(handles.edit_e, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_e, 'value', 1.0)
    set(handles.text_e_units, 'enable', 'on')
end

set(handles.edit_uts, 'string', properties.material_properties.uts)
try
    if isempty(properties.material_properties.ucs) == 1.0
        set(handles.edit_ucs, 'string', properties.material_properties.uts)
    else
        set(handles.edit_ucs, 'string', properties.material_properties.ucs)
    end
catch
    set(handles.edit_ucs, 'string', properties.material_properties.uts)
end
if properties.material_properties.uts_active == 1.0
    set(handles.edit_uts, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.edit_ucs, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_uts, 'value', 1.0)
    set(handles.text_slash, 'enable', 'on')
    set(handles.text_uts_units, 'enable', 'on')
end

set(handles.edit_proof, 'string', properties.material_properties.proof)
if properties.material_properties.proof_active == 1.0
    set(handles.edit_proof, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_proof, 'value', 1.0)
    set(handles.text_proof_units, 'enable', 'on')
end

set(handles.edit_poisson, 'string', properties.material_properties.poisson)
if properties.material_properties.poisson_active == 1.0
    set(handles.edit_poisson, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_poisson, 'value', 1.0)
else
    set(handles.edit_poisson, 'string', '0.33')
end

if isempty(properties.material_properties.s_values) == 0.0
    set(handles.edit_snData, 'string', 'Selected')
    set(handles.pButton_viewSNData, 'enable', 'on')
    set(handles.pButton_rmSNData, 'enable', 'on')
    
    set(handles.edit_snData, 'backgroundColor', [(204/255), 1.0, (204/255)])
    
    setappdata(gcf, 'S_values', properties.material_properties.s_values)
    setappdata(gcf, 'N_values', properties.material_properties.n_values)
end

if isempty(properties.material_properties.r_values) == 0.0
    set(handles.edit_rValues, 'string', 'Selected')
    set(handles.pButton_viewRValues, 'enable', 'on')
    set(handles.pButton_rmRValues, 'enable', 'on')
    
    set(handles.edit_rValues, 'backgroundColor', [(204/255), 1.0, (204/255)])
    
    setappdata(gcf, 'R_values', properties.material_properties.r_values)
end

set(handles.edit_sf, 'string', properties.material_properties.sf)
if properties.material_properties.sf_active == 1.0
    set(handles.edit_sf, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_sf, 'value', 1.0)
    set(handles.text_sf_units, 'enable', 'on')
end

set(handles.edit_b, 'string', properties.material_properties.b)
if properties.material_properties.b_active == 1.0
    set(handles.edit_b, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.pButton_knee, 'enable', 'on')
    set(handles.check_b, 'value', 1.0)
end

try
    if isempty(properties.material_properties.b2) == 1.0
        setappdata(0, 'b2', [])
    else
        setappdata(0, 'b2', properties.material_properties.b2)
    end
catch
    setappdata(0, 'b2', [])
end
try
    if isempty(properties.material_properties.b2Nf) == 1.0
        setappdata(0, 'b2Nf', [])
    else
        setappdata(0, 'b2Nf', properties.material_properties.b2Nf)
    end
catch
    setappdata(0, 'b2Nf', [])
end

set(handles.edit_ef, 'string', properties.material_properties.ef)
if properties.material_properties.ef_active == 1.0
    set(handles.edit_ef, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_ef, 'value', 1.0)
end

set(handles.edit_c, 'string', properties.material_properties.c)
if properties.material_properties.c_active == 1.0
    set(handles.edit_c, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_c, 'value', 1.0)
end

set(handles.edit_kp, 'string', properties.material_properties.kp)
if properties.material_properties.kp_active == 1.0
    set(handles.edit_kp, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_kp, 'value', 1.0)
    set(handles.text_kp_units, 'enable', 'on')
end

set(handles.edit_np, 'string', properties.material_properties.np)
if properties.material_properties.np_active == 1.0
    set(handles.edit_np, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_np, 'value', 1.0)
end

set(handles.edit_nssc, 'string', properties.material_properties.nssc)
if properties.material_properties.nssc_active == 1.0
    set(handles.edit_nssc, 'backgroundColor', [1.0, 1.0, 1.0], 'enable', 'on')
    set(handles.check_nssc, 'value', 1.0)
end
setappdata(0, 'nssc_value', properties.material_properties.nssc)

set(handles.pMenu_class, 'value', properties.material_properties.class)

% Initliaize fail stress properties
try
    if isempty(properties.material_properties.failStress_tsfd) == 1.0
        setappdata(0, 'failStress_tsfd', [])
    else
        setappdata(0, 'failStress_tsfd', properties.material_properties.failStress_tsfd)
    end
catch
    setappdata(0, 'failStress_tsfd', [])
end
try
    if isempty(properties.material_properties.failStress_csfd) == 1.0
        setappdata(0, 'failStress_csfd', [])
    else
        setappdata(0, 'failStress_csfd', properties.material_properties.failStress_csfd)
    end
catch
    setappdata(0, 'failStress_csfd', [])
end
try
    if isempty(properties.material_properties.failStress_tstd) == 1.0
        setappdata(0, 'failStress_tstd', [])
    else
        setappdata(0, 'failStress_tstd', properties.material_properties.failStress_tstd)
    end
catch
    setappdata(0, 'failStress_tstd', [])
end
try
    if isempty(properties.material_properties.failStress_cstd) == 1.0
        setappdata(0, 'failStress_cstd', [])
    else
        setappdata(0, 'failStress_cstd', properties.material_properties.failStress_cstd)
    end
catch
    setappdata(0, 'failStress_cstd', [])
end
try
    if isempty(properties.material_properties.failStress_tsttd) == 1.0
        setappdata(0, 'failStress_tsttd', [])
    else
        setappdata(0, 'failStress_tsttd', properties.material_properties.failStress_tsttd)
    end
catch
    setappdata(0, 'failStress_tsttd', [])
end
try
    if isempty(properties.material_properties.failStress_csttd) == 1.0
        setappdata(0, 'failStress_csttd', [])
    else
        setappdata(0, 'failStress_csttd', properties.material_properties.failStress_csttd)
    end
catch
    setappdata(0, 'failStress_csttd', [])
end
try
    if isempty(properties.material_properties.failStress_shear) == 1.0
        setappdata(0, 'failStress_shear', [])
    else
        setappdata(0, 'failStress_shear', properties.material_properties.failStress_shear)
    end
catch
    setappdata(0, 'failStress_shear', [])
end
try
    if isempty(properties.material_properties.failStress_cross12) == 1.0
        setappdata(0, 'failStress_cross12', 0.0)
    else
        setappdata(0, 'failStress_cross12', properties.material_properties.failStress_cross12)
    end
catch
    setappdata(0, 'failStress_cross12', 0.0)
end
try
    if isempty(properties.material_properties.failStress_cross23) == 1.0
        setappdata(0, 'failStress_cross23', 0.0)
    else
        setappdata(0, 'failStress_cross23', properties.material_properties.failStress_cross23)
    end
catch
    setappdata(0, 'failStress_cross23', 0.0)
end
try
    if isempty(properties.material_properties.failStress_limit12) == 1.0
        setappdata(0, 'failStress_limit12', [])
    else
        setappdata(0, 'failStress_limit12', properties.material_properties.failStress_limit12)
    end
catch
    setappdata(0, 'failStress_limit12', [])
end
try
    if isempty(properties.material_properties.failStress_limit23) == 1.0
        setappdata(0, 'failStress_limit23', [])
    else
        setappdata(0, 'failStress_limit23', properties.material_properties.failStress_limit23)
    end
catch
    setappdata(0, 'failStress_limit23', [])
end

% Initliaize fail strain properties
try
    if isempty(properties.material_properties.failStrain_tsfd) == 1.0
        setappdata(0, 'failStrain_tsfd', [])
    else
        setappdata(0, 'failStrain_tsfd', properties.material_properties.failStrain_tsfd)
    end
catch
    setappdata(0, 'failStrain_tsfd', [])
end
try
    if isempty(properties.material_properties.failStrain_csfd) == 1.0
        setappdata(0, 'failStrain_csfd', [])
    else
        setappdata(0, 'failStrain_csfd', properties.material_properties.failStrain_csfd)
    end
catch
    setappdata(0, 'failStrain_csfd', [])
end
try
    if isempty(properties.material_properties.failStrain_tstd) == 1.0
        setappdata(0, 'failStrain_tstd', [])
    else
        setappdata(0, 'failStrain_tstd', properties.material_properties.failStrain_tstd)
    end
catch
    setappdata(0, 'failStrain_tstd', [])
end
try
    if isempty(properties.material_properties.failStrain_cstd) == 1.0
        setappdata(0, 'failStrain_cstd', [])
    else
        setappdata(0, 'failStrain_cstd', properties.material_properties.failStrain_cstd)
    end
catch
    setappdata(0, 'failStrain_cstd', [])
end
try
    if isempty(properties.material_properties.failStrain_shear) == 1.0
        setappdata(0, 'failStrain_shear', [])
    else
        setappdata(0, 'failStrain_shear', properties.material_properties.failStrain_shear)
    end
catch
    setappdata(0, 'failStrain_shear', [])
end
try
    if isempty(properties.material_properties.failStrain_e11) == 1.0
        setappdata(0, 'failStrain_e11', [])
    else
        setappdata(0, 'failStrain_e11', properties.material_properties.failStrain_e11)
    end
catch
    setappdata(0, 'failStrain_e11', [])
end
try
    if isempty(properties.material_properties.failStrain_e22) == 1.0
        setappdata(0, 'failStrain_e22', [])
    else
        setappdata(0, 'failStrain_e22', properties.material_properties.failStrain_e22)
    end
catch
    setappdata(0, 'failStrain_e22', [])
end
try
    if isempty(properties.material_properties.failStrain_g12) == 1.0
        setappdata(0, 'failStrain_g12', [])
    else
        setappdata(0, 'failStrain_g12', properties.material_properties.failStrain_g12)
    end
catch
    setappdata(0, 'failStrain_g12', [])
end

% Initialize Hashin properties
try
    if isempty(properties.material_properties.hashin_alpha) == 1.0
        setappdata(0, 'hashin_alpha', 0.0)
    else
        setappdata(0, 'hashin_alpha', properties.material_properties.hashin_alpha)
    end
catch
    setappdata(0, 'hashin_alpha', 0.0)
end
try
    if isempty(properties.material_properties.hashin_lts) == 1.0
        setappdata(0, 'hashin_lts', [])
    else
        setappdata(0, 'hashin_lts', properties.material_properties.hashin_lts)
    end
catch
    setappdata(0, 'hashin_lts', [])
end
try
    if isempty(properties.material_properties.hashin_lcs) == 1.0
        setappdata(0, 'hashin_lcs', [])
    else
        setappdata(0, 'hashin_lcs', properties.material_properties.hashin_lcs)
    end
catch
    setappdata(0, 'hashin_lcs', [])
end
try
    if isempty(properties.material_properties.hashin_tts) == 1.0
        setappdata(0, 'hashin_tts', [])
    else
        setappdata(0, 'hashin_tts', properties.material_properties.hashin_tts)
    end
catch
    setappdata(0, 'hashin_tts', [])
end
try
    if isempty(properties.material_properties.hashin_tcs) == 1.0
        setappdata(0, 'hashin_tcs', [])
    else
        setappdata(0, 'hashin_tcs', properties.material_properties.hashin_tcs)
    end
catch
    setappdata(0, 'hashin_tcs', [])
end
try
    if isempty(properties.material_properties.hashin_lss) == 1.0
        setappdata(0, 'hashin_lss', [])
    else
        setappdata(0, 'hashin_lss', properties.material_properties.hashin_lss)
    end
catch
    setappdata(0, 'hashin_lss', [])
end
try
    if isempty(properties.material_properties.hashin_tss) == 1.0
        setappdata(0, 'hashin_tss', [])
    else
        setappdata(0, 'hashin_tss', properties.material_properties.hashin_tss)
    end
catch
    setappdata(0, 'hashin_tss', [])
end

% Initliaize LaRC05 properties
try
    if isempty(properties.material_properties.larc05_lts) == 1.0
        setappdata(0, 'larc05_lts', [])
    else
        setappdata(0, 'larc05_lts', properties.material_properties.larc05_lts)
    end
catch
    setappdata(0, 'larc05_lts', [])
end
try
    if isempty(properties.material_properties.larc05_lcs) == 1.0
        setappdata(0, 'larc05_lcs', [])
    else
        setappdata(0, 'larc05_lcs', properties.material_properties.larc05_lcs)
    end
catch
    setappdata(0, 'larc05_lcs', [])
end
try
    if isempty(properties.material_properties.larc05_tts) == 1.0
        setappdata(0, 'larc05_tts', [])
    else
        setappdata(0, 'larc05_tts', properties.material_properties.larc05_tts)
    end
catch
    setappdata(0, 'larc05_tts', [])
end
try
    if isempty(properties.material_properties.larc05_tcs) == 1.0
        setappdata(0, 'larc05_tcs', [])
    else
        setappdata(0, 'larc05_tcs', properties.material_properties.larc05_tcs)
    end
catch
    setappdata(0, 'larc05_tcs', [])
end
try
    if isempty(properties.material_properties.larc05_lss) == 1.0
        setappdata(0, 'larc05_lss', [])
    else
        setappdata(0, 'larc05_lss', properties.material_properties.larc05_lss)
    end
catch
    setappdata(0, 'larc05_lss', [])
end
try
    if isempty(properties.material_properties.larc05_tss) == 1.0
        setappdata(0, 'larc05_tss', [])
    else
        setappdata(0, 'larc05_tss', properties.material_properties.larc05_tss)
    end
catch
    setappdata(0, 'larc05_tss', [])
end
try
    if isempty(properties.material_properties.larc05_shear) == 1.0
        setappdata(0, 'larc05_shear', [])
    else
        setappdata(0, 'larc05_shear', properties.material_properties.larc05_shear)
    end
catch
    setappdata(0, 'larc05_shear', [])
end
try
    if isempty(properties.material_properties.larc05_nl) == 1.0
        setappdata(0, 'larc05_nl', [])
    else
        setappdata(0, 'larc05_nl', properties.material_properties.larc05_nl)
    end
catch
    setappdata(0, 'larc05_nl', [])
end
try
    if isempty(properties.material_properties.larc05_nt) == 1.0
        setappdata(0, 'larc05_nt', [])
    else
        setappdata(0, 'larc05_nt', properties.material_properties.larc05_nt)
    end
catch
    setappdata(0, 'larc05_nt', [])
end
try
    if isempty(properties.material_properties.larc05_alpha0) == 1.0
        setappdata(0, 'larc05_alpha0', 53.0)
    else
        setappdata(0, 'larc05_alpha0', properties.material_properties.larc05_alpha0)
    end
catch
    setappdata(0, 'larc05_alpha0', 53.0)
end
try
    if isempty(properties.material_properties.larc05_phi0) == 1.0
        setappdata(0, 'larc05_phi0', [])
    else
        setappdata(0, 'larc05_phi0', properties.material_properties.larc05_phi0)
    end
catch
    setappdata(0, 'larc05_phi0', [])
end
try
    if isempty(properties.material_properties.larc05_iterate) == 1.0
        setappdata(0, 'larc05_iterate', 0.0)
    else
        setappdata(0, 'larc05_iterate', properties.material_properties.larc05_iterate)
    end
catch
    setappdata(0, 'larc05_iterate', 0.0)
end

% --- Executes on button press in pButton_manager.
function pButton_manager_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

answer = questdlg('Unsaved changes will be lost. OK to return to Material Manager?',...
    'Quick Fatigue Tool', 'Yes', 'No', 'No');
if strcmpi(answer, 'yes') == 1.0
    % Suppress local material path dialogue
    setappdata(0, 'qft_suppressDataPath', 1.0)
    
    close 'Material Editor'
    MaterialManager
else
    % Enable the GUI
    enable(handles)
end

function edit_comment_Callback(~, ~, ~)
% hObject    handle to edit_comment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_comment as text
%        str2double(get(hObject,'String')) returns contents of edit_comment as a double


% --- Executes during object creation, after setting all properties.
function edit_comment_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_comment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_snData.
function pButton_snData_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

% Define the start path
if isappdata(0, 'panel_userMaterial_snData') == 1.0
    startPath_snData = getappdata(0, 'panel_userMaterial_snData');
else
    startPath_snData = [pwd, '/Data/material/sn_data'];
end

[filename, pathname] = uigetfile({'*.sn', 'S-N Data File';'*.dat', 'Data File'; '*.txt', 'Text File'; '*.*', 'All Files'}, 'Select an S-N Data File', startPath_snData);
fullpath = [pathname filename];

if (isequal(filename, 0.0) == 1.0) || (isequal(pathname, 0.0) == 1.0)
    % Enable the GUI
    enable(handles)
    return
else
    [~, ~, ext] = fileparts(fullpath);
    
    % Save the file path
    setappdata(0, 'panel_userMaterial_snData', pathname)
end

% Check the file extension
if strcmpi(ext, '.sn') == 0.0 && strcmpi(ext, '.dat') == 0.0 && strcmpi(ext, '.txt') == 0.0
    message = sprintf('"%s" is not a valid file type.', filename);
    errordlg(message, 'Quick Fatigue Tool')
    
    % Enable the GUI
    uiwait
    enable(handles)
    return
end

try
    data = load(fullpath);
    [r, c] = size(data);
    
    setappdata(gcf, 'snData', data)
    response = questdlg('Read data from rows or columns?', 'Quick Fatigue Tool', 'Rows', 'Columns', 'Rows');
    
    if isempty(response)
        
        % Enable the GUI
        uiwait
        enable(handles)
        return
    end
    
    if strcmpi(response, 'rows') == 1.0
        if (r < 2.0)
            errordlg('At least two rows of data are required', 'Quick Fatigue Tool')
            
            % Enable the GUI
            uiwait
            enable(handles)
            return
        elseif (c < 2.0)
            errordlg('At least two data points are required', 'Quick Fatigue Tool')
            
            % Enable the GUI
            uiwait
            enable(handles)
            return
        end
        sets = r - 1.0;
        
        % Check that the N-values are in the correct direction
        j = 0.0;
        N = data(1.0, :);
        
        for i = 1:sets
            S = data(2.0 + j, :);
            
            for k = 2.0:length(S)
                if S(k) > S(k - 1.0)
                    errordlg('S-values must be monotonically decreasing along the row.', 'Quick Fatigue Tool')
                    
                    % Enable the GUI
                    uiwait
                    enable(handles)
                    return
                elseif (i == 1.0) && (N(k) < N(k - 1.0))
                    errordlg('N-values must be monotonically increasing along the row.', 'Quick Fatigue Tool')
                    
                    % Enable the GUI
                    uiwait
                    enable(handles)
                    return
                end
            end
            
            j = j + 1.0;
        end
        
        setappdata(gcf, 'S_values', data(2.0:r, :))
        setappdata(gcf, 'N_values', data(1.0, :))
    elseif strcmpi(response, 'columns') == 1.0
        if (c < 2.0)
            errordlg('At least two columns of data are required.', 'Quick Fatigue Tool')
            
            % Enable the GUI
            uiwait
            enable(handles)
            return
        elseif (r < 2.0)
            errordlg('At least two data points are required.', 'Quick Fatigue Tool')
            
            % Enable the GUI
            uiwait
            enable(handles)
            return
        end
        sets = c - 1.0;
        N = data(:, 1.0);
        
        % Check that the values are in the correct direction
        j = 0.0;
        for i = 1:sets
            S = data(:, 2.0 + j);
            
            for k = 2:length(S)
                if S(k) > S(k - 1.0)
                    errordlg('S-values must be monotonically decreasing along the column.', 'Quick Fatigue Tool')
                    
                    % Enable the GUI
                    uiwait
                    enable(handles)
                    return
                elseif (i == 1.0) && (N(k) < N(k - 1.0))
                    errordlg('N-values must be monotonically increasing along the column.', 'Quick Fatigue Tool')
                    
                    % Enable the GUI
                    uiwait
                    enable(handles)
                    return
                end
            end
            
            j = j + 1.0;
        end
        
        setappdata(gcf, 'S_values', data(:, 2.0:c)')
        setappdata(gcf, 'N_values', data(:, 1.0)')
    end
catch
    message = sprintf('Error while reading "%s". Make sure there are the same number of S and N data points.', filename);
    errordlg(message, 'Quick Fatigue Tool')
    
    % Enable the GUI
    uiwait
    enable(handles)
    return
end

% Check that the number of R-values matches the S-N data
S = getappdata(gcf, 'S_values');
r_values = getappdata(gcf, 'R_values');

if isempty(r_values) == 0.0
    % Get the number of S-N data sets
    [sets, ~] = size(S);
    
    if (length(r_values) ~= sets)
        ln1 = sprintf('WARNING: The number of S-N datasets must match the number of R-values.\n\n');
        ln2 = sprintf('S-N datasets: %.0f\n', sets);
        ln3 = sprintf('R-values: %.0f', length(r_values));
        warndlg([ln1, ln2, ln3], 'Quick Fatigue Tool')
        uiwait
    end
end

% Enable the GUI
enable(handles)

set(handles.edit_snData, 'string', 'Selected')
set(handles.pButton_rmSNData, 'enable', 'on')
set(handles.pButton_viewSNData, 'enable', 'on')

set(handles.edit_snData, 'backgroundColor', [(204.0/255.0), 1.0, (204.0/255.0)])


function edit_snData_Callback(~, ~, ~)
% hObject    handle to edit_snData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_snData as text
%        str2double(get(hObject,'String')) returns contents of edit_snData as a double


% --- Executes during object creation, after setting all properties.
function edit_snData_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_snData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_rmSNData.
function pButton_rmSNData_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

answer = questdlg('Remove S-N data?', 'Quick Fatigue Tool', 'Yes', 'No', 'No');
if (strcmpi(answer, 'no') == 1.0) || (isempty(answer) == 1.0)
    % Enable the GUI
    enable(handles)
    return
end

set(handles.edit_snData, 'string', 'Undefined')
set(handles.pButton_rmSNData, 'enable', 'off')
set(handles.pButton_viewSNData, 'enable', 'off')

set(handles.edit_snData, 'backgroundColor', [(241/255), (241/255), (241/255)])

rmappdata(gcf, 'S_values')
rmappdata(gcf, 'N_values')

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_viewSNData.
function pButton_viewSNData_Callback(~, ~, handles)
S = getappdata(gcf, 'S_values');
N = getappdata(gcf, 'N_values');
rValues = getappdata(gcf, 'R_values');

% Get the number of S-N data sets
[sets, ~] = size(S);

H = figure('visible', 'off');
movegui(H, 'center')
f_handles = zeros(1.0, sets);

for i = 1:sets
    if sets == 1.0
        color = 'black';
    else
        color = [rand(), rand(), rand()];
    end
    
    if sets == 1.0
        p = loglog(N, S, '-', 'lineWidth', 2, 'Color', color);
    else
        p = loglog(N, S(i, :), '-', 'lineWidth', 2, 'Color', color);
    end
    
    f_handles(i) = p;
    hold on
end

try
    axis tight
catch
    % Don't tighten the axis
end

xlabel('Cycles (Nf)', 'FontSize', 16);    ylabel('Stress Amplitude (MPa)', 'FontSize', 16)
string = sprintf('S-N Data for %s', get(handles.edit_name, 'string'));
title(string, 'FontSize', 18);   grid on

label = cell(1, sets);
if ~isempty(rValues) && (length(rValues) == sets)
    % Label each S-N curve with its respective R-value
    for i = 1:sets
        label(i) = {sprintf('R = %g', rValues(i))};
    end
else
    for i = 1:sets
        label(i) = {sprintf('R = ?')};
    end
end

legend(f_handles, label)
set(H, 'visible', 'on');


% --- Executes on button press in pButton_snHelp.
function pButton_snHelp_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

ln1 = sprintf('Use Stress-Life (S-N) datapoints for fatigue analysis:\n\n\n');
ln2 = sprintf('* S-N data is imported from a comma, space or tab separated text file\n\n');
ln3 = sprintf('* Data can be read from columns or rows\n\n');
ln4 = sprintf('* N-values are specified once as the first row/column\n\n');
ln5 = sprintf('* S-values are specified in subsequent rows/columns\n\n');
ln6 = sprintf('* Each S-dataset references an S-N curve at a different load ratio\n\n');
ln7 = sprintf('* Units of stress must be MPa');
msgbox([ln1, ln2, ln3, ln4, ln5, ln6, ln7], 'S-N Data')
uiwait

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_k.
function pButton_k_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

% Get a copy of the current material name
setappdata(0, 'kValue_material', get(handles.edit_name, 'string'))

setappdata(0, 'updateKValue', 0)
if isempty(get(handles.edit_uts, 'string')) == 0.0
    setappdata(0, 'k_solution_uts', get(handles.edit_uts, 'string'))
end
kValueCalculator
uiwait
if (isappdata(0, 'k_solution') == 1.0) && (get(handles.check_nssc, 'value') == 0.0) && (getappdata(0, 'updateKValue') == 1.0)
    set(handles.edit_nssc, 'string', getappdata(0, 'k_solution'))
    setappdata(0, 'nssc_value', get(handles.edit_nssc, 'string'))
end

% Enable the GUI
enable(handles)


% --- Executes during object deletion, before destroying properties.
function MaterialEditor_DeleteFcn(~, ~, ~)    
if isappdata(0, 'k_solution_model')
    rmappdata(0, 'k_solution_model')
    rmappdata(0, 'k_solution_r')
    rmappdata(0, 'k_solution_fi')
    rmappdata(0, 'k_solution_t')
    rmappdata(0, 'k_solution_uts')
end


% --- Executes on button press in pButton_rValues.
function pButton_rValues_Callback(hObject, eventdata, handles)
% Blank the GUI
blank(handles)

user_rValues = inputdlg('Define R-value list:', 'R-Values', 1.0);

if isempty(user_rValues) == 1.0
    % Enable the GUI
    enable(handles)
    return
end

r_values = str2num(user_rValues{:}); %#ok<ST2NM>

% Check that the input is numeric
if isempty(r_values) == 1.0 || any(isnan(r_values)) == 1.0
    errordlg('Could not read R-values due to a syntax error.', 'Quick Fatigue Tool')
    uiwait
    pButton_rValues_Callback(hObject, eventdata, handles)
    
    % Enable the GUI
    enable(handles)
    return
end

% The R-values must be strictly increasing
if all(diff(r_values) > 0.0) == 0.0
    errordlg('R-values must be strictly increasing.', 'Quick Fatigue Tool')
    uiwait
    pButton_rValues_Callback(hObject, eventdata, handles)
    
    % Enable the GUI
    enable(handles)
    return
end

% The R-values must be less than 1.0
if any(r_values >= 1.0) == 1.0
    errordlg('R-values must less than 1.', 'Quick Fatigue Tool')
    uiwait
    pButton_rValues_Callback(hObject, eventdata, handles)
    
    % Enable the GUI
    enable(handles)
    return
end

setappdata(gcf, 'R_values', r_values)

% Check that the number of R-values matches the S-N data
S = getappdata(gcf, 'S_values');

if isempty(S) == 0.0
    % Get the number of S-N data sets
    [sets, ~] = size(S);
    
    if (length(r_values) ~= sets)
        ln1 = sprintf('WARNING: The number of R-values must match the number of S-N datasets.\n\n');
        ln2 = sprintf('R-values: %.0f\n', length(r_values));
        ln3 = sprintf('S-N datasets: %.0f', sets);
        warndlg([ln1, ln2, ln3], 'Quick Fatigue Tool')
        uiwait
        pButton_rValues_Callback(hObject, eventdata, handles)
    end
end

set(handles.edit_rValues, 'string', 'Selected')
set(handles.pButton_rmRValues, 'enable', 'on')
set(handles.pButton_viewRValues, 'enable', 'on')

set(handles.edit_rValues, 'backgroundColor', [(204.0/255.0), 1.0, (204.0/255.0)])

% Enable the GUI
enable(handles)


function edit_rValues_Callback(~, ~, ~)
% hObject    handle to edit_rValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_rValues as text
%        str2double(get(hObject,'String')) returns contents of edit_rValues as a double


% --- Executes during object creation, after setting all properties.
function edit_rValues_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_rValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_rHelp.
function pButton_rHelp_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

ln1 = sprintf('Associate S-N data with multiple load ratios (R-values):\n\n\n');
ln2 = sprintf('* The number of R-values must be equal to the number of S-N datasets\n\n');
ln3 = sprintf('* If one S-N dataset is provided, an R-value of -1 will always be assumed\n\n');
ln4 = sprintf('* R-values are treated in the same order as the S-N data');
msgbox([ln1, ln2, ln3, ln4], 'R-Values')
uiwait

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_rmRValues.
function pButton_rmRValues_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

answer = questdlg('Remove R-values?', 'Quick Fatigue Tool', 'Yes', 'No', 'No');
if (strcmpi(answer, 'no') == 1.0) || (isempty(answer) == 1.0)
    % Enable the GUI
    enable(handles)
    return
end

set(handles.edit_rValues, 'string', 'Undefined')
set(handles.pButton_rmRValues, 'enable', 'off')
set(handles.pButton_viewRValues, 'enable', 'off')

set(handles.edit_rValues, 'backgroundColor', [(241/255), (241/255), (241/255)])

rmappdata(gcf, 'R_values')

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_viewRValues.
function pButton_viewRValues_Callback(hObject, eventdata, handles)
% Blank the GUI
blank(handles)

r_values = getappdata(gcf, 'R_values');
if length(r_values) == 1.0
    r_values = {sprintf('%g', r_values)};
else
    r_values = {[sprintf('%g, ', r_values(1:end-1)), sprintf('%g', r_values(end))]};
end

user_rValues = inputdlg('Redefine R-value list:', 'R-Values', 1.0, r_values);

if isempty(user_rValues) == 1.0
    % Enable the GUI
    enable(handles)
    return
end

r_values = str2num(user_rValues{:}); %#ok<ST2NM>

% Make sure data is numeric
if isempty(r_values) == 1.0 || any(isnan(r_values)) == 1.0
    errordlg('Could not read R-values due to a syntax error.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    
    pButton_viewRValues_Callback(hObject, eventdata, handles)
    return
end

% The R-values must be strictly increasing
if all(diff(r_values) > 0.0) == 0.0
    errordlg('R-values must be strictly increasing.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    
    pButton_viewRValues_Callback(hObject, eventdata, handles)
    return
end

% The R-values must be less than 1.0
if any(r_values >= 1.0) == 1.0
    errordlg('R-values must less than 1.', 'Quick Fatigue Tool')
    uiwait
    
    % Enable the GUI
    enable(handles)
    
    pButton_viewRValues_Callback(hObject, eventdata, handles)
    return
end

setappdata(gcf, 'R_values', r_values)

% Check that the number of R-values matches the S-N data
S = getappdata(gcf, 'S_values');

if isempty(S) == 0.0
    % Get the number of S-N data sets
    [sets, ~] = size(S);
    
    if (length(r_values) ~= sets)
        ln1 = sprintf('WARNING: The number of R-values must match the number of S-N datasets.\n\n');
        ln2 = sprintf('R-values: %.0f\n', length(r_values));
        ln3 = sprintf('S-N datasets: %.0f', sets);
        warndlg([ln1, ln2, ln3], 'Quick Fatigue Tool')
        uiwait
        pButton_viewRValues_Callback(hObject, eventdata, handles)
    end
end

% Enable the GUI
enable(handles)


function edit_location_Callback(~, ~, ~)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_location as text
%        str2double(get(hObject,'String')) returns contents of edit_location as a double


% --- Executes during object creation, after setting all properties.
function edit_location_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pButton_changeLocation.
function pButton_changeLocation_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

% Define the start path
if exist(getappdata(0, 'qft_localMaterialDataPath'), 'dir') == 7.0
    startPath_output = [pwd, '/Data/material/local'];
else
    startPath_output = pwd;
end

% Get the material storage path
location = uigetdir(startPath_output, 'Select a Storage Directory');

% Enable the GUI
enable(handles)

if location == 0.0
    return
end

set(handles.edit_location, 'string', location)

setappdata(0, 'qft_materialLocation', location)

% --- Executes on button press in check_location.
function check_location_Callback(hObject, ~, handles)
qft_localMaterialDataPath = getappdata(0, 'qft_localMaterialDataPath');

switch get(hObject, 'value')
    case 0.0
        set(handles.edit_location, 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
        
        if isempty(qft_localMaterialDataPath) == 0.0
            set(handles.edit_location, 'string', qft_localMaterialDataPath)
        else
            set(handles.edit_location, 'string', pwd)
        end
        
        set(handles.pButton_changeLocation, 'enable', 'off')
    case 1.0
        set(handles.edit_location, 'enable', 'on', 'backgroundColor', 'white')
        if isappdata(0, 'qft_materialLocation') == 1.0
            set(handles.edit_location, 'string', getappdata(0, 'qft_materialLocation'))
        elseif isempty(qft_localMaterialDataPath) == 0.0
            set(handles.edit_location, 'string', qft_localMaterialDataPath)
        else
            set(handles.edit_location, 'string', pwd)
        end
        set(handles.pButton_changeLocation, 'enable', 'on')
    otherwise
end


% --- Executes when MaterialEditor is resized.
function MaterialEditor_ResizeFcn(~, ~, ~)
% hObject    handle to MaterialEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close MaterialEditor.
function MaterialEditor_CloseRequestFcn(hObject, ~, ~)
if isappdata(0, 'qft_materialLocation') == 1.0
    rmappdata(0, 'qft_materialLocation')
end

% Fatigue
if isappdata(0, 'e_value') == 1.0
    rmappdata(0, 'e_value')
end
if isappdata(0, 'uts_value') == 1.0
    rmappdata(0, 'uts_value')
end
if isappdata(0, 'b_value') == 1.0
    rmappdata(0, 'b_value')
end
if isappdata(0, 'b2') == 1.0
    rmappdata(0, 'b2')
end
if isappdata(0, 'b2Nf') == 1.0
    rmappdata(0, 'b2Nf')
end

% nssc
if isappdata(0, 'nssc_value') == 1.0
    rmappdata(0, 'nssc_value')
end

% Stress-based failure
if isappdata(0, 'failStress_tsfd') == 1.0
    rmappdata(0, 'failStress_tsfd')
end
if isappdata(0, 'failStress_csfd') == 1.0
    rmappdata(0, 'failStress_csfd')
end
if isappdata(0, 'failStress_tstd') == 1.0
    rmappdata(0, 'failStress_tstd')
end
if isappdata(0, 'failStress_cstd') == 1.0
    rmappdata(0, 'failStress_cstd')
end
if isappdata(0, 'failStress_tsttd') == 1.0
    rmappdata(0, 'failStress_tsttd')
end
if isappdata(0, 'failStress_csttd') == 1.0
    rmappdata(0, 'failStress_csttd')
end
if isappdata(0, 'failStress_shear') == 1.0
    rmappdata(0, 'failStress_shear')
end
if isappdata(0, 'failStress_cross12') == 1.0
    rmappdata(0, 'failStress_cross12')
end
if isappdata(0, 'failStress_cross23') == 1.0
    rmappdata(0, 'failStress_cross23')
end
if isappdata(0, 'failStress_limit12') == 1.0
    rmappdata(0, 'failStress_limit12')
end
if isappdata(0, 'failStress_limit23') == 1.0
    rmappdata(0, 'failStress_limit23')
end

% Strain-based failure
if isappdata(0, 'failStrain_tsfd') == 1.0
    rmappdata(0, 'failStrain_tsfd')
end
if isappdata(0, 'failStrain_csfd') == 1.0
    rmappdata(0, 'failStrain_csfd')
end
if isappdata(0, 'failStrain_tstd') == 1.0
    rmappdata(0, 'failStrain_tstd')
end
if isappdata(0, 'failStrain_cstd') == 1.0
    rmappdata(0, 'failStrain_cstd')
end
if isappdata(0, 'failStrain_shear') == 1.0
    rmappdata(0, 'failStrain_shear')
end
if isappdata(0, 'failStrain_e11') == 1.0
    rmappdata(0, 'failStrain_e11')
end
if isappdata(0, 'failStrain_e22') == 1.0
    rmappdata(0, 'failStrain_e22')
end
if isappdata(0, 'failStrain_g12') == 1.0
    rmappdata(0, 'failStrain_g12')
end

% Hashin damage initiation
if isappdata(0, 'hashin_alpha') == 1.0
    rmappdata(0, 'hashin_alpha')
end
if isappdata(0, 'hashin_lts') == 1.0
    rmappdata(0, 'hashin_lts')
end
if isappdata(0, 'hashin_lcs') == 1.0
    rmappdata(0, 'hashin_lcs')
end
if isappdata(0, 'hashin_tts') == 1.0
    rmappdata(0, 'hashin_tts')
end
if isappdata(0, 'hashin_tcs') == 1.0
    rmappdata(0, 'hashin_tcs')
end
if isappdata(0, 'hashin_lss') == 1.0
    rmappdata(0, 'hashin_lss')
end
if isappdata(0, 'hashin_tss') == 1.0
    rmappdata(0, 'hashin_tss')
end

% LaRC05
if isappdata(0, 'larc05_lts') == 1.0
    rmappdata(0, 'larc05_lts')
end
if isappdata(0, 'larc05_lcs') == 1.0
    rmappdata(0, 'larc05_lcs')
end
if isappdata(0, 'larc05_tts') == 1.0
    rmappdata(0, 'larc05_tts')
end
if isappdata(0, 'larc05_tcs') == 1.0
    rmappdata(0, 'larc05_tcs')
end
if isappdata(0, 'larc05_lss') == 1.0
    rmappdata(0, 'larc05_lss')
end
if isappdata(0, 'larc05_tss') == 1.0
    rmappdata(0, 'larc05_tss')
end
if isappdata(0, 'larc05_shear') == 1.0
    rmappdata(0, 'larc05_shear')
end
if isappdata(0, 'larc05_nl') == 1.0
    rmappdata(0, 'larc05_nl')
end
if isappdata(0, 'larc05_nt') == 1.0
    rmappdata(0, 'larc05_nt')
end
if isappdata(0, 'larc05_alpha0') == 1.0
    rmappdata(0, 'larc05_alpha0')
end
if isappdata(0, 'larc05_phi0') == 1.0
    rmappdata(0, 'larc05_phi0')
end
if isappdata(0, 'larc05_iterate') == 1.0
    rmappdata(0, 'larc05_iterate')
end

% Make sure any open files are closed
fclose('all');

delete(hObject);

function blank(handles)
set(findall(handles.MaterialEditor, '-property', 'Enable'), 'Enable', 'off')

function enable(handles)
set(findall(handles.MaterialEditor, '-property', 'Enable'), 'Enable', 'on')

simuliaBlue = getappdata(0, 'simulia_blue');

% General
if get(handles.check_location, 'value') == 0.0
    set(handles.edit_location, 'enable', 'inactive')
    set(handles.pButton_changeLocation, 'enable', 'off')
end
if get(handles.check_cael, 'value') == 0.0
    set(handles.edit_cael, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
    set(handles.text_cael_units, 'enable', 'off')
end

% Mechanical
if get(handles.check_e, 'value') == 0.0
    set(handles.edit_e, 'enable', 'off')
    set(handles.text_e_units, 'enable', 'off')
end
if get(handles.check_poisson, 'value') == 0.0
    set(handles.edit_poisson, 'enable', 'inactive')
end
if get(handles.check_uts, 'value') == 0.0
    set(handles.edit_uts, 'enable', 'off')
    set(handles.text_slash, 'enable', 'off')
    set(handles.edit_ucs, 'enable', 'off')
    set(handles.text_uts_units, 'enable', 'off')
end
if get(handles.check_proof, 'value') == 0.0
    set(handles.edit_proof, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
    set(handles.text_proof_units, 'enable', 'off')
end

% Fatigue
set(handles.edit_snData, 'enable', 'inactive')
set(handles.edit_rValues, 'enable', 'inactive')
set(handles.edit_snData, 'backgroundColor', 'white')
set(handles.edit_snData, 'backgroundColor', [242/255, 242/255, 242/255])
set(handles.edit_rValues, 'backgroundColor', 'white')
set(handles.edit_rValues, 'backgroundColor', [242/255, 242/255, 242/255])

if strncmpi(get(handles.edit_snData, 'string'), 'undefined', 9.0) == 1.0
    set(handles.pButton_rmSNData, 'enable', 'off')
    set(handles.pButton_viewSNData, 'enable', 'off')
else
    set(handles.edit_snData, 'backgroundColor', [(204/255), 1.0, (204/255)])
end
if strncmpi(get(handles.edit_rValues, 'string'), 'undefined', 9.0) == 1.0
    set(handles.pButton_rmRValues, 'enable', 'off')
    set(handles.pButton_viewRValues, 'enable', 'off')
else
    set(handles.edit_rValues, 'backgroundColor', [(204/255), 1.0, (204/255)])
end
if get(handles.check_sf, 'value') == 0.0
    set(handles.edit_sf, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
    set(handles.text_sf_units, 'enable', 'off')
end
if get(handles.check_b, 'value') == 0.0
    set(handles.edit_b, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
    set(handles.pButton_knee, 'enable', 'off')
end
if get(handles.check_ef, 'value') == 0.0
    set(handles.edit_ef, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
end
if get(handles.check_c, 'value') == 0.0
    set(handles.edit_c, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
end

% Cyclic
if get(handles.check_kp, 'value') == 0.0
    set(handles.edit_kp, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
    set(handles.text_kp_units, 'enable', 'off')
end
if get(handles.check_np, 'value') == 0.0
    set(handles.edit_np, 'enable', 'inactive', 'backgroundColor', simuliaBlue)
end

% Non-standard
if get(handles.check_nssc, 'value') == 0.0
    set(handles.edit_nssc, 'enable', 'inactive', 'backgroundColor', [1.0, 1.0, 1.0])
    set(handles.edit_nssc, 'backgroundColor', simuliaBlue)
else
    set(handles.pButton_k, 'enable', 'off')
end

% Back button
if (isappdata(0, 'multiaxial_gauge_fatigue_skip_material_manager') == 1.0) || (isappdata(0, 'uniaxial_strain_life_skip_material_manager') == 1.0)
    set(handles.pButton_manager, 'enable', 'off')
end



function edit_ucs_Callback(~, ~, ~)
% hObject    handle to edit_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ucs as text
%        str2double(get(hObject,'String')) returns contents of edit_ucs as a double


% --- Executes during object creation, after setting all properties.
function edit_ucs_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_failStress.
function pButton_failStress_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

failStress
uiwait

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_hashin.
function pButton_hashin_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

hashin
uiwait

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_failStrain.
function pButton_failStrain_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

failStrain
uiwait

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_knee.
function pButton_knee_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

insertKnee
uiwait

% Enable the GUI
enable(handles)


% --- Executes on button press in check_ndCompression.
function check_ndCompression_Callback(~, ~, ~)
% hObject    handle to check_ndCompression (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_ndCompression


% --- Executes on button press in pButton_larc05.
function pButton_larc05_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

larc05
uiwait

% Enable the GUI
enable(handles)

function initializeMaterial
setappdata(0, 'failStress_cross12', 0.0)
setappdata(0, 'failStress_cross23', 0.0)
setappdata(0, 'hashin_alpha', 0.0)
setappdata(0, 'larc05_alpha0', 53.0)
setappdata(0, 'larc05_iterate', 0.0)
