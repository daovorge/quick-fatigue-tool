function varargout = kValueCalculator(varargin)%#ok<*DEFNU>
%KVALUECALCULATOR    QFT functions to derive normal stress sensitivity
%constant.
%   These functions derive the normal stress sensitivity constant (k) based
%   on material parameters.
%   
%   KVALUECALCULATOR is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also checkDataPath, evaluateMaterial, importMaterial,
%   LocalMaterialDatabase, material, MaterialEditor, MaterialManager.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%      6.4 Findley's Method
%   
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 06-Mar-2018 12:32:23 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @kValueCalculator_OpeningFcn, ...
                   'gui_OutputFcn',  @kValueCalculator_OutputFcn, ...
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


% --- Executes just before kValueCalculator is made visible.
function kValueCalculator_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to kValueCalculator (see VARARGIN)

clc

% Choose default command line output for kValueCalculator
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% Define SIMULIA blue color
blue = [177/255, 206/255, 237/255];
grey = [241/255, 241/255, 241/255];
setappdata(0, 'simulia_blue', blue)
setappdata(0, 'grey', grey)

% Restore panel state
materialName = getappdata(0, 'kValue_material');

try
    setappdata(0, sprintf('%s', materialName), 1.0)
    rmappdata(0, sprintf('%s', materialName))
    
    if isempty(materialName) == 1.0
        materialName = '';
    else
        materialName = [materialName, '_'];
    end
catch
    materialName = '';
end

if isappdata(0, sprintf('%skValueCalculator_pMenu_solution', materialName)) == 1.0
    set(handles.pMenu_solution, 'value', getappdata(0, sprintf('%skValueCalculator_pMenu_solution', materialName)))
    set(handles.edit_r, 'string', getappdata(0, sprintf('%skValueCalculator_edit_r', materialName)))
    set(handles.edit_fi, 'string', getappdata(0, sprintf('%skValueCalculator_edit_fi', materialName)))
    set(handles.edit_t, 'string', getappdata(0, sprintf('%skValueCalculator_edit_t', materialName)))
    set(handles.edit_uts, 'string', getappdata(0, sprintf('%skValueCalculator_edit_uts', materialName)))
    
    switch getappdata(0, 'kValueCalculator_pMenu_solution')
        case 2.0
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'on', 'BackgroundColor', 'White')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
        case 3.0
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
        case 4.0
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'on');    set(handles.edit_uts, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_uts, 'enable', 'on')
        case 5.0
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    end
end

% Check if the symbolic math toolbox is available
[~] = checkToolbox('Symbolic Math Toolbox');

% UIWAIT makes kValueCalculator wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = kValueCalculator_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in pMenu_solution.
function pMenu_solution_Callback(hObject, eventdata, handles)
blue = getappdata(0, 'simulia_blue');
grey = getappdata(0, 'grey');
switch get(hObject, 'Value')
    case 1.0 % Default
        set(handles.text_r, 'enable', 'off');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', grey)
        set(handles.text_fi, 'enable', 'off');    set(handles.edit_fi, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_fi, 'enable', 'off')
        set(handles.text_t, 'enable', 'off');    set(handles.edit_t, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_t, 'enable', 'off')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    case 2.0 % General formula
        % Check if SYMS works
        if getappdata(0, 'noSMT') == 1.0
            % Blank the GUI
            blank(handles)
            
            errordlg('The General Formula derivation method requires the Symbolic Math Toolbox.', 'Quick Fatigue Tool')
            uiwait; set(handles.pMenu_solution, 'value', 1.0)
            pMenu_solution_Callback(hObject, eventdata, handles)
            
            % Enable the GUI
            enable(handles)
            return
        end
        
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'on', 'BackgroundColor', 'White')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    case 3.0 % Dang van
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    case 4.0 % Sines
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'on');    set(handles.edit_uts, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_uts, 'enable', 'on')
        
        set(handles.edit_uts, 'string', getappdata(0, 'k_solution_uts'))
    case 5.0 % Crossland
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
end


% --- Executes during object creation, after setting all properties.
function pMenu_solution_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_solution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_r_Callback(~, ~, ~)
% hObject    handle to edit_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_r as text
%        str2double(get(hObject,'String')) returns contents of edit_r as a double


% --- Executes during object creation, after setting all properties.
function edit_r_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_fi_Callback(~, ~, ~)
% hObject    handle to edit_fi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fi as text
%        str2double(get(hObject,'String')) returns contents of edit_fi as a double


% --- Executes during object creation, after setting all properties.
function edit_fi_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_fi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_t_Callback(~, ~, ~)
% hObject    handle to edit_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_t as text
%        str2double(get(hObject,'String')) returns contents of edit_t as a double


% --- Executes during object creation, after setting all properties.
function edit_t_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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


function edit_fMinus1_Callback(~, ~, ~)
% hObject    handle to edit_fMinus1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fMinus1 as text
%        str2double(get(hObject,'String')) returns contents of edit_fMinus1 as a double


% --- Executes during object creation, after setting all properties.
function edit_fMinus1_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_fMinus1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_solve.
function pButton_solve_Callback(~, ~, handles)
% Check validity of inputs
error = 0.0;

if strcmpi(get(handles.edit_r, 'enable'), 'on')
    r = str2double(get(handles.edit_r, 'String'));
    
    if isnumeric(r) == 0.0
        error = 1.0;
    elseif isnan(r) == 1.0 || isinf(r) == 1.0 || isempty(r) == 1.0
        error = 1.0;
    end
end
if strcmpi(get(handles.edit_fi, 'enable'), 'on')
    fi = str2double(get(handles.edit_fi, 'String'));
    
    if isnumeric(fi) == 0.0
        error = 1.0;
    elseif (isnan(fi) == 1.0) || (isinf(fi) == 1.0) || (isempty(fi) == 1.0)
        error = 1.0;
    end
end
if strcmpi(get(handles.edit_uts, 'enable'), 'on')
    uts = str2double(get(handles.edit_uts, 'String'));
    
    if isnumeric(uts) == 0.0
        error = 1.0;
    elseif (isnan(uts) == 1.0) || (isinf(uts) == 1.0) || (isempty(uts) == 1.0)
        error = 1.0;
    end
end
if strcmpi(get(handles.edit_t, 'enable'), 'on')
    t = str2double(get(handles.edit_t, 'String'));
    
    if isnumeric(t) == 0.0
        error = 1.0;
    elseif (isnan(t) == 1.0) || (isinf(t) == 1.0) || (isempty(t) == 1.0)
        error = 1.0;
    end
end

% Blank the GUI
blank(handles)
pause(1e-6)

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait
    set(handles.pButton_solve, 'enable', 'on')
    enable(handles)
    return
end

% Solve for k
switch get(handles.pMenu_solution, 'Value')
    case 1.0
        setappdata(0, 'k_solution', 0.2857)
        setappdata(0, 'updateKValue', 1.0)
        close 'k-Value Calculator'
        return
    case 2.0
        syms k
        eqn = (fi/t) == (2.0*sqrt(1.0 + k^2.0))/(sqrt(((2.0*k)/(1.0-r))^2.0 + 1.0) + ((2.0*k)/(1.0-r)));
        solk = eval(solve(eqn, k)); clc
    case 3.0
        solk = ((3.0*t)/(fi)) - (3.0/2.0);
    case 4.0
        solk = ((3.0*t*(uts + fi))/(uts*fi)) - sqrt(6.0);
    case 5.0
        solk = ((3.0*t)/(fi)) - sqrt(3.0);
end

if isempty(solk) == 1.0
    errordlg('An explicit solution for the specified properties could not be found.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enable(handles)
    
    return
elseif isreal(solk) == 0.0
    errordlg('The calculated solution is complex.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enable(handles)
    
    return
elseif isnan(solk) == 1.0
    errordlg('The calculated solution is NaN.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enable(handles)
    
    return
elseif isinf(solk) == 1.0
    errordlg('The calculated solution is infinite.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enable(handles)
    
    return
elseif solk < 0.0
    errordlg('The calculated solution is negative.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enable(handles)
    
    return
else
    setappdata(0, 'k_solution', solk)
    setappdata(0, 'updateKValue', 1.0)
    close 'k-Value Calculator'
end


% --- Executes on button press in pButton_close.
function pButton_close_Callback(~, ~, ~)
close 'k-Value Calculator'


% --- Executes when user attempts to close kValueCalculator.
function kValueCalculator_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to kValueCalculator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rmappdata(0, 'noSMT')

% Get the name of the current material
materialName = getappdata(0, 'kValue_material');

%{
    Save the panel state based on the name of the material. If the material
    contains certain characters then the panel state will be savaed without
    the material name
%}
try
    setappdata(0, sprintf('%s', materialName), 1.0)
    rmappdata(0, sprintf('%s', materialName))
    
    if isempty(materialName) == 1.0
        materialName = '';
    else
        materialName = [materialName, '_'];
    end
catch
    materialName = '';
end

setappdata(0, sprintf('%skValueCalculator_pMenu_solution', materialName), get(handles.pMenu_solution, 'value'))
setappdata(0, sprintf('%skValueCalculator_edit_r', materialName), get(handles.edit_r, 'string'))
setappdata(0, sprintf('%skValueCalculator_edit_fi', materialName), get(handles.edit_fi, 'string'))
setappdata(0, sprintf('%skValueCalculator_edit_t', materialName), get(handles.edit_t, 'string'))
setappdata(0, sprintf('%skValueCalculator_edit_uts', materialName), get(handles.edit_uts, 'string'))

if isappdata(0, 'kValue_material') == 1.0
    rmappdata(0, 'kValue_material')
end

% Hint: delete(hObject) closes the figure
delete(hObject);


function blank(handles)
set(findall(handles.kValueCalculator, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
%set(findall(handles.kValueCalculator, '-property', 'Enable'), 'Enable', 'on')
set(handles.text_model, 'enable', 'on')
set(handles.pMenu_solution, 'enable', 'on')

switch get(handles.pMenu_solution, 'value')
    case 2.0 % General formula
        set(findall(handles.kValueCalculator, '-property', 'Enable'), 'Enable', 'on')
        
        set(handles.text_uts, 'enable', 'off')
        set(handles.edit_uts, 'enable', 'off')
        set(handles.text_units_uts, 'enable', 'off')
    case 3.0 % Dang van
        set(findall(handles.kValueCalculator, '-property', 'Enable'), 'Enable', 'on')
        
        set(handles.text_uts, 'enable', 'off')
        set(handles.edit_uts, 'enable', 'off')
        set(handles.text_units_uts, 'enable', 'off')
        
        set(handles.edit_r, 'enable', 'inactive', 'backgroundColor', getappdata(0, 'simulia_blue'))
    case 4.0 % Sines
        set(findall(handles.kValueCalculator, '-property', 'Enable'), 'Enable', 'on')
        
        set(handles.edit_r, 'enable', 'inactive', 'backgroundColor', getappdata(0, 'simulia_blue'))
    case 5.0 % Crossland
        set(findall(handles.kValueCalculator, '-property', 'Enable'), 'Enable', 'on')
        
        set(handles.text_uts, 'enable', 'off')
        set(handles.edit_uts, 'enable', 'off')
        set(handles.text_units_uts, 'enable', 'off')
        
        set(handles.edit_r, 'enable', 'inactive', 'backgroundColor', getappdata(0, 'simulia_blue'))
end
