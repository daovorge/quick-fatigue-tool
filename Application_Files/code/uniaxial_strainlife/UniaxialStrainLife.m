function varargout = UniaxialStrainLife(varargin)%#ok<*DEFNU>
% UNIAXIALSTRAINLIFE MATLAB code for UniaxialStrainLife.fig
%      UNIAXIALSTRAINLIFE, by itself, creates a new UNIAXIALSTRAINLIFE or raises the existing
%      singleton*.
%
%      H = UNIAXIALSTRAINLIFE returns the handle to a new UNIAXIALSTRAINLIFE or the handle to
%      the existing singleton*.
%
%      UNIAXIALSTRAINLIFE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UNIAXIALSTRAINLIFE.M with the given input arguments.
%
%      UNIAXIALSTRAINLIFE('Property','Value',...) creates a new UNIAXIALSTRAINLIFE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UniaxialStrainLife_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UniaxialStrainLife_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UniaxialStrainLife

% Last Modified by GUIDE v2.5 08-Jun-2017 10:35:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UniaxialStrainLife_OpeningFcn, ...
                   'gui_OutputFcn',  @UniaxialStrainLife_OutputFcn, ...
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


% --- Executes just before UniaxialStrainLife is made visible.
function UniaxialStrainLife_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to UniaxialStrainLife (see VARARGIN)
movegui(hObject, 'center')

% Choose default command line output for UniaxialStrainLife
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes UniaxialStrainLife wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = UniaxialStrainLife_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pButton_analyse.
function pButton_analyse_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_analyse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close UniaxialStrainLife


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(hObject, eventdata, handles)
%{
    This putton resets the GUI to its original state, without any user
    modifications
%}
% Input definition
set(handles.edit_inputFile, 'string', '')

set(handles.rButton_stress, 'value', 1.0)
set(handles.rButton_strain, 'value', 0.0)
set(handles.rButon_strainUnitsStrain, 'value', 1.0, 'enable', 'off')
set(handles.rButton_strainUnitsMicro, 'value', 0.0, 'enable', 'off')
set(handles.rButton_typeElastic, 'value', 1.0, 'enable', 'inactive')
set(handles.rButton_typePlastic, 'value', 0.0, 'enable', 'off')

% Material definition
set(handles.edit_material, 'string', '')

% Analysis definition
set(handles.edit_scf, 'string', '1')
set(handles.pMenu_msc, 'value', 2.0)



function edit_inputFile_Callback(hObject, eventdata, handles)
% hObject    handle to edit_inputFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_inputFile as text
%        str2double(get(hObject,'String')) returns contents of edit_inputFile as a double


% --- Executes during object creation, after setting all properties.
function edit_inputFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_inputFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_browseInput.
function pButton_browseInput_Callback(~, ~, handles)
%{
    Get the input file containing a stress or strain history
%}

% Define the start path
if isappdata(0, 'panel_uniaxialStrainLife_input_path') == 1.0
    startPath_input = getappdata(0, 'panel_uniaxialStrainLife_input_path');
else
    startPath_input = pwd;
end

% Define the GETFILE dialogue name
if get(handles.rButton_stress, 'value') == 1.0
    uigetFileTitle = 'Stress history file';
else
    uigetFileTitle = 'Strain history file';
end

% Get the file
[file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, uigetFileTitle,...
        startPath_input);
    
if isequal(file, 0.0) == 1.0 || isequal(path, 0.0) == 1.0
    % User cancelled operation
else
    set(handles.edit_inputFile, 'string', [path, file])
    
    % Save the file path
    setappdata(0, 'panel_uniaxialStrainLife_input_path', path)
end



function edit_material_Callback(hObject, eventdata, handles)
% hObject    handle to edit_material (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_material as text
%        str2double(get(hObject,'String')) returns contents of edit_material as a double


% --- Executes during object creation, after setting all properties.
function edit_material_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_material (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_browseMaterial.
function pButton_browseMaterial_Callback(hObject, eventdata, handles)
%{
    Get the material file for the fatigue analysis
%}

% Define the start path
if isappdata(0, 'panel_uniaxialStrainLife_material_path') == 1.0
    startPath_material = getappdata(0, 'panel_uniaxialStrainLife_material_path');
else
    startPath_material = [pwd, '/Data/material/local'];
end

[materialName, path, ~] = uigetfile({'*.mat','MAT-Files (*.mat)'},...
    'Material File', startPath_material);

if isequal(materialName, 0.0) == 1.0 || isequal(path, 0.0) == 1.0
else
    setappdata(0, 'uniaxialStrainLife_material', [path, materialName])
    
    materialName(end-3: end) = [];
    set(handles.edit_material, 'string', materialName)
    
    % Save the file path
    setappdata(0, 'panel_uniaxialStrainLife_material_path', path)
    setappdata(0, 'panel_uniaxialStrainLife_edit_material', materialName)
end


% --- Executes on button press in pButton_createMaterial.
function pButton_createMaterial_Callback(hObject, eventdata, handles)
%{
    Open the material editor GUI
%}
setappdata(0, 'uniaxial_strain_life_skip_material_manager', 1.0)
UserMaterial
uiwait

rmappdata(0, 'uniaxial_strain_life_skip_material_manager')
material = getappdata(0, 'material_for_uniaxial_strain_life');

if isempty(material) == 0.0
    set(handles.edit_material, 'string', getappdata(0, 'material_for_uniaxial_strain_life'))
end

if isappdata(0, 'material_for_uniaxial_strain_life') == 1.0
    rmappdata(0, 'material_for_uniaxial_strain_life')
end


% --- Executes on button press in pButton_manageMaterial.
function pButton_manageMaterial_Callback(hObject, eventdata, handles)
%{
    Start the Material Manager application
%}
MaterialManager
uiwait



function edit_scf_Callback(hObject, eventdata, handles)
% hObject    handle to edit_scf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scf as text
%        str2double(get(hObject,'String')) returns contents of edit_scf as a double


% --- Executes during object creation, after setting all properties.
function edit_scf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_msc.
function pMenu_msc_Callback(hObject, eventdata, handles)
% hObject    handle to pMenu_msc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_msc contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_msc


% --- Executes during object creation, after setting all properties.
function pMenu_msc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pMenu_msc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel_quantity.
function uipanel_quantity_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'tag')
    case 'rButton_stress'
        set(handles.rButon_strainUnitsStrain, 'enable', 'off')
        set(handles.rButton_strainUnitsMicro, 'enable', 'off')
        
        set(handles.rButton_typeElastic, 'enable', 'inactive', 'value', 1.0)
        set(handles.rButton_typePlastic, 'enable', 'off', 'value', 0.0)
    case 'rButton_strain'
        set(handles.rButon_strainUnitsStrain, 'enable', 'on')
        set(handles.rButton_strainUnitsMicro, 'enable', 'on')
        
        set(handles.rButton_typeElastic, 'enable', 'on')
        set(handles.rButton_typePlastic, 'enable', 'on')
    otherwise
end


% --- Executes when selected object is changed in uipanel_units.
function uipanel_units_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_units 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in uipanel_unitsType.
function uipanel_unitsType_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_unitsType 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in check_resultsLocation.
function check_resultsLocation_Callback(hObject, eventdata, handles)
% hObject    handle to check_resultsLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_resultsLocation



function edit_resultsLocation_Callback(hObject, eventdata, handles)
% hObject    handle to edit_resultsLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_resultsLocation as text
%        str2double(get(hObject,'String')) returns contents of edit_resultsLocation as a double


% --- Executes during object creation, after setting all properties.
function edit_resultsLocation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_resultsLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_resultsLocation.
function pButton_resultsLocation_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_resultsLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
