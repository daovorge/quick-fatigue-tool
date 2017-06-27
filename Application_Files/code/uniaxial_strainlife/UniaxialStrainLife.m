function varargout = UniaxialStrainLife(varargin)%#ok<*DEFNU>
%UNIAXIALSTRAINLIFE    QFT functions for Uniaxial Strain-Life
%   These functions are used to call and operate the Uniaxial Strain-Life
%   application.
%   
%   UNIAXIALSTRAINLIFE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also uniaxialAnalysis, uniaxialPostProcess, uniaxialPreProcess
%
%   Reference section in Quick Fatigue Tool Appendices
%      A3.6 Uniaxial Strain-Life
%   
%   Quick Fatigue Tool 6.11-01 Copyright Louis Vallance 2017
%   Last modified 19-Jun-2017 13:56:11 GMT

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
function UniaxialStrainLife_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to UniaxialStrainLife (see VARARGIN)
movegui(hObject, 'center')

% Clear the command window
clc

% Choose default command line output for UniaxialStrainLife
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes UniaxialStrainLife wait for user response (see UIRESUME)
% uiwait(handles.UniaxialStrainLife);

% Load icons
[a,~]=imread('icoR_fileOpen.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_browseInput, 'CData', g);
set(handles.pButton_browseMaterial, 'CData', g);
set(handles.pButton_resultsLocation, 'CData', g);

%% Load the panel state
if isappdata(0, 'panel_uniaxialStrainLife_edit_inputFile') == 1.0
    %{
        figure1_CloseRequestFcn has been called on a previous occasion.
        Recall the panel state
    %}
    
    % Input definition
    set(handles.edit_inputFile, 'string', getappdata(0, 'panel_uniaxialStrainLife_edit_inputFile'))
    
    set(handles.rButton_stress, 'value', getappdata(0, 'panel_uniaxialStrainLife_rButton_stress'))
    set(handles.rButton_strain, 'value', getappdata(0, 'panel_uniaxialStrainLife_rButton_strain'))
    
    set(handles.rButon_strainUnitsStrain, 'value', getappdata(0, 'panel_uniaxialStrainLife_rButon_strainUnitsStrain'))
    set(handles.rButton_strainUnitsMicro, 'value', getappdata(0, 'panel_uniaxialStrainLife_rButton_strainUnitsMicro'))
    
    set(handles.rButton_typeElastic, 'value', getappdata(0, 'panel_uniaxialStrainLife_rButton_typeElastic'))
    set(handles.rButton_typePlastic, 'value', getappdata(0, 'panel_uniaxialStrainLife_rButton_typePlastic'))
    
    if getappdata(0, 'panel_uniaxialStrainLife_rButton_stress') == 1.0
        set(handles.rButon_strainUnitsStrain, 'enable', 'off')
        set(handles.rButton_strainUnitsMicro, 'enable', 'off')
        set(handles.rButton_typePlastic, 'enable', 'off')
        set(handles.rButton_typeElastic, 'enable', 'inactive')
    end
    
    % Analysis definition
    set(handles.edit_scf, 'string', getappdata(0, 'panel_uniaxialStrainLife_edit_scf'))
    set(handles.pMenu_msc, 'value', getappdata(0, 'panel_uniaxialStrainLife_pMenu_msc'))
    set(handles.edit_walkerGamma, 'string', getappdata(0, 'panel_uniaxialStrainLife_edit_walkerGamma'))
    if get(handles.pMenu_msc, 'value') == 6.0
        set(handles.text_walkerGamma, 'enable', 'on')
        set(handles.edit_walkerGamma, 'enable', 'on')
    end
    
    if get(handles.rButton_typeElastic, 'value') == 1.0
        set(handles.text_scf, 'enable', 'on')
        set(handles.edit_scf, 'enable', 'on')
    end
    
    % Output definition
    set(handles.check_resultsLocation, 'value', getappdata(0, 'panel_uniaxialStrainLife_check_resultsLocation'))
    set(handles.edit_resultsLocation, 'string', getappdata(0, 'panel_uniaxialStrainLife_edit_resultsLocation'))
    
    if getappdata(0, 'panel_uniaxialStrainLife_check_resultsLocation') == 1.0
        set(handles.edit_resultsLocation, 'enable', 'on', 'backgroundColor', 'white')
        set(handles.pButton_resultsLocation, 'enable', 'on')
    end
end

%% Material definition
setMaterialName(handles)

%% Check screen resolution
if isappdata(0, 'checkScreenResolution') == 0.0
    resolution = get(0, 'Screensize');
    if (resolution(3.0) ~= 1920.0) || (resolution(4.0) ~= 1080.0)
        msg1 = sprintf('Your screen resolution is set to %.0fx%.0f. This app will only display correctly at 1920x1080. ', resolution(3.0), resolution(4.0));
        msg2 = sprintf('Text scaling must also be set to "Medium" (125%%) from the control panel:\n\n');
        msg3 = 'Control Panel\Appearance and Personalization\Display';
        uiwait(warndlg([msg1, msg2, msg3], 'Quick Fatigue Tool', 'modal'));
    end
    setappdata(0, 'checkScreenResolution', 1.0)
end


% --- Outputs from this function are returned to the command line.
function varargout = UniaxialStrainLife_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pButton_analyse.
function pButton_analyse_Callback(~, ~, handles)

%% Clear the command window
clc; warning('off', 'all')

%% Start the timer
tic

%% Blank the GUI
blank(handles)
pause(1e-6)

%% Suppress output to the message file
setappdata(0, 'uniaxialStrainLifeMessenger', 1.0)

%% Prescan the load history file
[loadHistoryData, error] = uniaxialPreProcess.preScanFile(handles);

if error == 1.0
    % Enable the GUI
    enable(handles)
    warning('on', 'all')
    return
end

%% Get the stress concentration factor
[error, scf] = uniaxialPreProcess.checkSCF(handles);

if error == 1.0
    % Enable the GUI
    set(handles.edit_scf, 'string', '1')
    enable(handles)
    warning('on', 'all')
    return
end

%% Get the mean stress correction
msCorrection = get(handles.pMenu_msc, 'value');

%% Read the material file
error = uniaxialPreProcess.preScanMaterial(handles, msCorrection);

if error == 1.0
    % Enable the GUI
    enable(handles)
    warning('on', 'all')
    return
end

%% Check the validity of the Walker gamma value
uts = getappdata(0, 'uts');
behaviour = getappdata(0, 'materialBehavior');

[error, gamma] = uniaxialPreProcess.checkWalkerGamma(handles, msCorrection, uts, behaviour);

if error == 1.0
    % Enable the GUI
    set(handles.edit_walkerGamma, 'string', '')
    enable(handles)
    warning('on', 'all')
    return
end

%% Check the output definition
[error, outputPath, dateString] = uniaxialPreProcess.checkOutput(get(handles.check_resultsLocation, 'value'), get(handles.edit_resultsLocation, 'string'));

if error == 1.0
    % Enable the GUI
    enable(handles)
    warning('on', 'all')
    return
end

%% Get material properties
cael = getappdata(0, 'cael');
E = getappdata(0, 'E');
Sf = getappdata(0, 'Sf');
b = getappdata(0, 'b');
Ef = getappdata(0, 'Ef');
c = getappdata(0, 'c');
kp = getappdata(0, 'kp');
np = getappdata(0, 'np');

%% Apply strain history unit conversion (if applicable)
if (get(handles.rButton_strain, 'value') == 1.0) && (get(handles.rButton_strainUnitsMicro, 'value') == 1.0)
    loadHistoryData = loadHistoryData./1e6;
end

%% If the input is elastic strain, convert to elastic stress
if (get(handles.rButton_strain, 'value') == 1.0) && (get(handles.rButton_typeElastic, 'value') == 1.0)
    loadHistoryData = loadHistoryData.*E;
end

%% Get the fatigue limit of the material
[fatigueLimitSress, ~] = uniaxialPreProcess.getFatigueLimit(cael, E, Sf, b, Ef, c);

%% Get the history length
L = length(loadHistoryData);

%% Set endurance limit parameters
if behaviour == 2.0
    ndEndurance = 0.0;
else
    ndEndurance = 1.0;
end

%% Get the input quantity type
if (get(handles.rButton_stress, 'value') == 1.0) || ((get(handles.rButton_strain, 'value') == 1.0 && get(handles.rButton_typeElastic, 'value') == 1.0))
    %{
        The user supplied an elastic stress history or an elastic strain
        history. The damage parameter is the elastic stress. Convert the
        elastic stress into the nonlinear elastic stress and strain.
    %}
    type = 1.0;
else
    %{
        The user supplied an inelastic strain history. The damage parameter
        is the inelastic strain. Convert the inelastic strain into the
        nonlinear elastic stress and strain.
    %}
    type = 2.0;
end

%% Get the fatigue damage
[damage, nCycles, error, WCAE, pairE, dParamS, dParamE, dParamGated] = uniaxialAnalysis.main(loadHistoryData, cael, E, Sf, b, Ef, c, kp, np, gamma, msCorrection, L, ndEndurance, fatigueLimitSress, scf, type);

%% Check for errors
if error == 1.0
    errordlg('The Neuber correction failed. Check the material definition for errors.', 'Quick Fatigue Tool')
    uiwait
    % Enable the GUI
    enable(handles)
    warning('on', 'all')
    return
elseif error == 2.0
    errordlg('The monotonic stress excursion exceeds the precision of the solver. Fatigue damage cannot be calculated.', 'Quick Fatigue Tool')
    uiwait
    % Enable the GUI
    enable(handles)
    warning('on', 'all')
    return
end

%% Get the life
life = 1.0/damage;

% Remove message file flag
rmappdata(0, 'uniaxialStrainLifeMessenger')

%% Stop the timer
analysisTime = toc;

%% Export tables
uniaxialPostProcess.outputTables(WCAE, pairE, outputPath, type, dParamS, dParamE, loadHistoryData, dParamGated)

%% Write results to output file
uniaxialPostProcess.outputLog(handles, nCycles, life, cael, analysisTime, gamma, outputPath, dateString)

%% Report the life in a message box
uniaxialPostProcess.outputMsgBox(nCycles, life, cael, outputPath)

%% Close the GUI
warning('on', 'all')
close 'Uniaxial Strain-Life'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'Uniaxial Strain-Life'


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(~, ~, handles)
%{
    This putton resets the GUI to its original state, without any user
    modifications
%}
% Input definition
set(handles.edit_inputFile, 'string', '')

set(handles.rButton_stress, 'value', 0.0)
set(handles.rButton_strain, 'value', 1.0)
set(handles.rButon_strainUnitsStrain, 'value', 0.0, 'enable', 'on')
set(handles.rButton_strainUnitsMicro, 'value', 1.0, 'enable', 'on')
set(handles.rButton_typeElastic, 'value', 0.0, 'enable', 'on')
set(handles.rButton_typePlastic, 'value', 1.0, 'enable', 'on')

% Material definition
setMaterialName(handles)

% Analysis definition
set(handles.text_scf, 'enable', 'off')
set(handles.edit_scf, 'string', '1', 'enable', 'off')
set(handles.pMenu_msc, 'value', 2.0)
set(handles.text_walkerGamma, 'enable', 'off')
set(handles.edit_walkerGamma, 'enable', 'off', 'string', '')

% Output definition
set(handles.check_resultsLocation, 'value', 0.0)
set(handles.edit_resultsLocation, 'enable', 'inactive', 'string', 'Default project output directory', 'backgroundColor', [177.0/255, 206.0/255, 237.0/255])



function edit_inputFile_Callback(~, ~, ~)
% hObject    handle to edit_inputFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_inputFile as text
%        str2double(get(hObject,'String')) returns contents of edit_inputFile as a double


% --- Executes during object creation, after setting all properties.
function edit_inputFile_CreateFcn(hObject, ~, ~)
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
% Blank the GUI
blank(handles)

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

% Enable the GUI
enable(handles)



function edit_material_Callback(~, ~, ~)
% hObject    handle to edit_material (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_material as text
%        str2double(get(hObject,'String')) returns contents of edit_material as a double


% --- Executes during object creation, after setting all properties.
function edit_material_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_material (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_browseMaterial.
function pButton_browseMaterial_Callback(~, ~, handles)
%{
    Get the material file for the fatigue analysis
%}

% Blank the GUI
blank(handles)

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

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_createMaterial.
function pButton_createMaterial_Callback(~, ~, handles)
%{
    Open the material editor GUI
%}
% Blank the GUI
blank(handles)

setappdata(0, 'uniaxial_strain_life_skip_material_manager', 1.0)
MaterialEditor
uiwait

rmappdata(0, 'uniaxial_strain_life_skip_material_manager')
material = getappdata(0, 'material_for_uniaxial_strain_life');

if isempty(material) == 0.0
    set(handles.edit_material, 'string', material)
    rmappdata(0, 'material_for_uniaxial_strain_life')
end

% Enable the GUI
enable(handles)


% --- Executes on button press in pButton_manageMaterial.
function pButton_manageMaterial_Callback(~, ~, handles)
%{
    Start the Material Manager application
%}

% Blank the GUI
blank(handles)

MaterialManager
uiwait

% Check if the material still exists
if exist([get(handles.edit_material, 'string'), '.mat'], 'file') ~= 2.0
    userMaterial = dir('Data/material/local/*.mat');
    
    if isempty(userMaterial) == 0.0
        userMaterial(1.0).name(end-3:end) = [];
        set(handles.edit_material, 'string', userMaterial(1.0).name)
    else
        set(handles.edit_material, 'string', '')
    end
end

% Enable the GUI
enable(handles)



function edit_scf_Callback(~, ~, ~)
% hObject    handle to edit_scf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scf as text
%        str2double(get(hObject,'String')) returns contents of edit_scf as a double


% --- Executes during object creation, after setting all properties.
function edit_scf_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_scf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_msc.
function pMenu_msc_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 6.0 % User selected Walker (gamma)
        set(handles.text_walkerGamma, 'enable', 'on')
        set(handles.edit_walkerGamma, 'enable', 'on')
    otherwise
        set(handles.text_walkerGamma, 'enable', 'off')
        set(handles.edit_walkerGamma, 'enable', 'off')
end


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


% --- Executes when selected object is changed in uipanel_quantity.
function uipanel_quantity_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'tag')
    case 'rButton_stress'
        set(handles.rButon_strainUnitsStrain, 'enable', 'off')
        set(handles.rButton_strainUnitsMicro, 'enable', 'off')
        
        set(handles.rButton_typeElastic, 'enable', 'inactive', 'value', 1.0)
        set(handles.rButton_typePlastic, 'enable', 'off', 'value', 0.0)
        
        set(handles.text_scf, 'enable', 'on')
        set(handles.edit_scf, 'enable', 'on')
    case 'rButton_strain'
        set(handles.rButon_strainUnitsStrain, 'enable', 'on')
        set(handles.rButton_strainUnitsMicro, 'enable', 'on')
        
        set(handles.rButton_typeElastic, 'enable', 'on')
        set(handles.rButton_typePlastic, 'enable', 'on')
    otherwise
end


% --- Executes when selected object is changed in uipanel_units.
function uipanel_units_SelectionChangeFcn(~, ~, ~)
% hObject    handle to the selected object in uipanel_units 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in uipanel_unitsType.
function uipanel_unitsType_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'tag')
    case 'rButton_typeElastic'
        set(handles.text_scf, 'enable', 'on')
        set(handles.edit_scf, 'enable', 'on')
    case 'rButton_typePlastic'
        set(handles.text_scf, 'enable', 'off')
        set(handles.edit_scf, 'enable', 'off')
    otherwise
end


% --- Executes on button press in check_resultsLocation.
function check_resultsLocation_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_resultsLocation, 'enable', 'inactive', 'string', 'Default project output directory', 'backgroundColor', [177.0/255, 206.0/255, 237.0/255])
        set(handles.pButton_resultsLocation, 'enable', 'off')
    case 1.0
        if exist([pwd, '/Project/output'], 'dir') == 7.0
            set(handles.edit_resultsLocation, 'string', [pwd, '/Project/output'])
        else
            set(handles.edit_resultsLocation, 'string', pwd)
        end
        
        set(handles.edit_resultsLocation, 'enable', 'on', 'backgroundColor', 'white')
        set(handles.pButton_resultsLocation, 'enable', 'on')
end


function edit_resultsLocation_Callback(~, ~, ~)
% hObject    handle to edit_resultsLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_resultsLocation as text
%        str2double(get(hObject,'String')) returns contents of edit_resultsLocation as a double


% --- Executes during object creation, after setting all properties.
function edit_resultsLocation_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_resultsLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_resultsLocation.
function pButton_resultsLocation_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

% Define the start path
if isappdata(0, 'panel_uniaxialStrainLife_output_path') == 1.0
    startPath_output = getappdata(0, 'panel_uniaxialStrainLife_output_path');
else
    if exist([pwd, '/Project/output'], 'dir') == 7.0
        startPath_output = [pwd, '/Project/output'];
    else
        startPath_output = pwd;
    end
end

outputDirectory = uigetdir(startPath_output, 'Output Directory');

if isequal(outputDirectory, 0.0)
    % User cancelled operation
else
    set(handles.edit_resultsLocation, 'string', outputDirectory)
    
    % Save the directory
    setappdata(0, 'panel_uniaxialStrainLife_output_path', outputDirectory)
end

% Enable the GUI
enable(handles)


% --- Executes when user attempts to close UniaxialStrainLife.
function UniaxialStrainLife_CloseRequestFcn(hObject, ~, handles)
% Save the panel state

% Input definition
setappdata(0, 'panel_uniaxialStrainLife_edit_inputFile', get(handles.edit_inputFile, 'string'))

setappdata(0, 'panel_uniaxialStrainLife_rButton_stress', get(handles.rButton_stress, 'value'))
setappdata(0, 'panel_uniaxialStrainLife_rButton_strain', get(handles.rButton_strain, 'value'))

setappdata(0, 'panel_uniaxialStrainLife_rButon_strainUnitsStrain', get(handles.rButon_strainUnitsStrain, 'value'))
setappdata(0, 'panel_uniaxialStrainLife_rButton_strainUnitsMicro', get(handles.rButton_strainUnitsMicro, 'value'))

setappdata(0, 'panel_uniaxialStrainLife_rButton_typeElastic', get(handles.rButton_typeElastic, 'value'))
setappdata(0, 'panel_uniaxialStrainLife_rButton_typePlastic', get(handles.rButton_typePlastic, 'value'))

% Material definition
setappdata(0, 'panel_uniaxialStrainLife_edit_material', get(handles.edit_material, 'string'))

% Analysis definition
setappdata(0, 'panel_uniaxialStrainLife_edit_scf', get(handles.edit_scf, 'string'))
setappdata(0, 'panel_uniaxialStrainLife_pMenu_msc', get(handles.pMenu_msc, 'value'))
setappdata(0, 'panel_uniaxialStrainLife_edit_walkerGamma', get(handles.edit_walkerGamma, 'string'))

% Output definition
setappdata(0, 'panel_uniaxialStrainLife_check_resultsLocation', get(handles.check_resultsLocation, 'value'))
setappdata(0, 'panel_uniaxialStrainLife_edit_resultsLocation', get(handles.edit_resultsLocation, 'string'))

delete(hObject);

function blank(handles)
set(findall(handles.UniaxialStrainLife, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
set(findall(handles.UniaxialStrainLife, '-property', 'Enable'), 'Enable', 'on')

% Input definition
if get(handles.rButton_stress, 'value') == 1.0
    set(handles.rButon_strainUnitsStrain, 'enable', 'off')
    set(handles.rButton_strainUnitsMicro, 'enable', 'off')
    set(handles.rButton_typeElastic, 'enable', 'inactive')
    set(handles.rButton_typePlastic, 'enable', 'off')
end

% Analysis definition
if get(handles.pMenu_msc, 'value') ~= 6.0
    set(handles.text_walkerGamma, 'enable', 'off')
    set(handles.edit_walkerGamma, 'enable', 'off')
end

% Output definition
if get(handles.check_resultsLocation, 'value') == 0.0
    set(handles.edit_resultsLocation, 'enable', 'inactive')
    set(handles.pButton_resultsLocation, 'enable', 'off')
end

function setMaterialName(handles)
material = getappdata(0, 'panel_uniaxialStrainLife_edit_material');
if isempty(material) == 0.0
    [~, material, ~] = fileparts(material);
    if exist(['Data/material/local/', material, '.mat'], 'file') == 2.0
        % Use a previously selected material
        set(handles.edit_material, 'string', material)
    else
        % Use the first material in the /local directory if it exists
        userMaterial = dir('Data/material/local/*.mat');
        
        if isempty(userMaterial) == 0.0
            userMaterial(1.0).name(end-3:end) = [];
            set(handles.edit_material, 'string', userMaterial(1.0).name)
        else
            set(handles.edit_material, 'string', [])
        end
    end
else
    userMaterial = dir('Data/material/local/*.mat');
    
    if isempty(userMaterial) == 0.0
        userMaterial(1.0).name(end-3:end) = [];
        set(handles.edit_material, 'string', userMaterial(1.0).name)
    else
        set(handles.edit_material, 'string', '')
    end
end


function edit_walkerGamma_Callback(~, ~, ~)
% hObject    handle to edit_walkerGamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_walkerGamma as text
%        str2double(get(hObject,'String')) returns contents of edit_walkerGamma as a double


% --- Executes during object creation, after setting all properties.
function edit_walkerGamma_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_walkerGamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
