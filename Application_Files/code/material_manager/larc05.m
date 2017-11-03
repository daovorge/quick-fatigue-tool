function varargout = larc05(varargin)%#ok<*DEFNU>
%LARC05    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   LARC05 is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-07 Copyright Louis Vallance 2017
%   Last modified 11-Oct-2017 13:08:05 GMT

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @larc05_OpeningFcn, ...
                   'gui_OutputFcn',  @larc05_OutputFcn, ...
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


% --- Executes just before larc05 is made visible.
function larc05_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to larc05 (see VARARGIN)

% Choose default command line output for larc05
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes larc05 wait for user response (see UIRESUME)
% uiwait(handles.larc05);

if isappdata(0, 'larc05_lts') == 1.0
    set(handles.edit_lts, 'string', getappdata(0, 'larc05_lts'))
end
if isappdata(0, 'larc05_lcs') == 1.0
    set(handles.edit_lcs, 'string', getappdata(0, 'larc05_lcs'))
end
if isappdata(0, 'larc05_tts') == 1.0
    set(handles.edit_tts, 'string', getappdata(0, 'larc05_tts'))
end
if isappdata(0, 'larc05_tcs') == 1.0
    set(handles.edit_tcs, 'string', getappdata(0, 'larc05_tcs'))
end
if isappdata(0, 'larc05_lss') == 1.0
    set(handles.edit_lss, 'string', getappdata(0, 'larc05_lss'))
end
if isappdata(0, 'larc05_tss') == 1.0
    set(handles.edit_tss, 'string', getappdata(0, 'larc05_tss'))
end
if isappdata(0, 'larc05_shear') == 1.0
    set(handles.edit_shear, 'string', getappdata(0, 'larc05_shear'))
end
if isappdata(0, 'larc05_nl') == 1.0
    set(handles.edit_nl, 'string', getappdata(0, 'larc05_nl'))
end
if isappdata(0, 'larc05_nt') == 1.0
    set(handles.edit_nt, 'string', getappdata(0, 'larc05_nt'))
end
if isappdata(0, 'larc05_alpha0') == 1.0
    if isempty(getappdata(0, 'larc05_alpha0')) == 1.0
        set(handles.edit_alpha0, 'string', '53')
    else
        set(handles.edit_alpha0, 'string', getappdata(0, 'larc05_alpha0'))
    end
end
if isappdata(0, 'larc05_phi0') == 1.0
    set(handles.edit_phi0, 'string', getappdata(0, 'larc05_phi0'))
end
if isappdata(0, 'larc05_iterate') == 1.0
    set(handles.check_iterate, 'value', getappdata(0, 'larc05_iterate'))
end

% Check if the symbolic math toolbox is available
isAvailable = checkToolbox('Symbolic Math Toolbox');
if isAvailable == 0.0
    set(handles.check_iterate, 'enable', 'off')
end


% --- Outputs from this function are returned to the command line.
function varargout = larc05_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function edit_lts_Callback(~, ~, ~)
% hObject    handle to edit_lts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lts as text
%        str2double(get(hObject,'String')) returns contents of edit_lts as a double


% --- Executes during object creation, after setting all properties.
function edit_lts_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_lts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_lcs_Callback(~, ~, ~)
% hObject    handle to edit_lcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lcs as text
%        str2double(get(hObject,'String')) returns contents of edit_lcs as a double


% --- Executes during object creation, after setting all properties.
function edit_lcs_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_lcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_tts_Callback(~, ~, ~)
% hObject    handle to edit_tts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tts as text
%        str2double(get(hObject,'String')) returns contents of edit_tts as a double


% --- Executes during object creation, after setting all properties.
function edit_tts_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_tcs_Callback(~, ~, ~)
% hObject    handle to edit_tcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tcs as text
%        str2double(get(hObject,'String')) returns contents of edit_tcs as a double


% --- Executes during object creation, after setting all properties.
function edit_tcs_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_lss_Callback(~, ~, ~)
% hObject    handle to edit_lss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lss as text
%        str2double(get(hObject,'String')) returns contents of edit_lss as a double


% --- Executes during object creation, after setting all properties.
function edit_lss_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_lss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_tss_Callback(~, ~, ~)
% hObject    handle to edit_tss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tss as text
%        str2double(get(hObject,'String')) returns contents of edit_tss as a double


% --- Executes during object creation, after setting all properties.
function edit_tss_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
blank(handles)
error = 0.0;

larc05_lts = str2double(get(handles.edit_lts, 'string'));
if isempty(get(handles.edit_lts, 'string')) == 0.0
    if isnan(larc05_lts) == 1.0 || isinf(larc05_lts) == 1.0 || isreal(larc05_lts) == 0.0
        error = 1.0;
    end
end

larc05_lcs = str2double(get(handles.edit_lcs, 'string'));
if isempty(get(handles.edit_lcs, 'string')) == 0.0
    if isnan(larc05_lcs) == 1.0 || isinf(larc05_lcs) == 1.0 || isreal(larc05_lcs) == 0.0
        error = 1.0;
    end
end

larc05_tts = str2double(get(handles.edit_tts, 'string'));
if isempty(get(handles.edit_tts, 'string')) == 0.0
    if isnan(larc05_tts) == 1.0 || isinf(larc05_tts) == 1.0 || isreal(larc05_tts) == 0.0
        error = 1.0;
    end
end

larc05_tcs = str2double(get(handles.edit_tcs, 'string'));
if isempty(get(handles.edit_tcs, 'string')) == 0.0
    if isnan(larc05_tcs) == 1.0 || isinf(larc05_tcs) == 1.0 || isreal(larc05_tcs) == 0.0
        error = 1.0;
    end
end

larc05_lss = str2double(get(handles.edit_lss, 'string'));
if isempty(get(handles.edit_lss, 'string')) == 0.0
    if isnan(larc05_lss) == 1.0 || isinf(larc05_lss) == 1.0 || isreal(larc05_lss) == 0.0
        error = 1.0;
    end
end

larc05_tss = str2double(get(handles.edit_tss, 'string'));
if isempty(get(handles.edit_tss, 'string')) == 0.0
    if isnan(larc05_tss) == 1.0 || isinf(larc05_tss) == 1.0 || isreal(larc05_tss) == 0.0
        error = 1.0;
    end
end

larc05_shear = str2double(get(handles.edit_shear, 'string'));
if isempty(get(handles.edit_shear, 'string')) == 0.0
    if isnan(larc05_shear) == 1.0 || isinf(larc05_shear) == 1.0 || isreal(larc05_shear) == 0.0
        error = 1.0;
    end
end

larc05_nl = str2double(get(handles.edit_nl, 'string'));
if isempty(get(handles.edit_nl, 'string')) == 0.0
    if isnan(larc05_nl) == 1.0 || isinf(larc05_nl) == 1.0 || isreal(larc05_nl) == 0.0
        error = 1.0;
    elseif larc05_nl < 0.0 || larc05_nl > 1.0
        errordlg('nl must be in the range (0 <= nl <= 1.0).', 'Quick Fatigue Tool')
        uiwait; enable(handles)
        return
    end
end

larc05_nt = str2double(get(handles.edit_nt, 'string'));
if isempty(get(handles.edit_nt, 'string')) == 0.0
    if isnan(larc05_nt) == 1.0 || isinf(larc05_nt) == 1.0 || isreal(larc05_nt) == 0.0
        error = 1.0;
    elseif larc05_nt < 0.0 || larc05_nt > 1.0
        errordlg('nt must be in the range (0 <= nt <= 1.0).', 'Quick Fatigue Tool')
        uiwait; enable(handles)
        return
    end
end

if isempty(get(handles.edit_alpha0, 'string')) == 1.0
    set(handles.edit_alpha0, 'string', '53')
else
    larc05_alpha0 = str2double(get(handles.edit_alpha0, 'string'));
    if isnan(larc05_alpha0) == 1.0 || isinf(larc05_alpha0) == 1.0 || isreal(larc05_alpha0) == 0.0
        error = 1.0;
    elseif larc05_alpha0 < 0.0 || larc05_alpha0 > 180.0
        errordlg('Alpha must be in the range (0 <= alpha <= 180.0).', 'Quick Fatigue Tool')
        uiwait; enable(handles)
        return
    end
end

larc05_phi0 = str2double(get(handles.edit_phi0, 'string'));
if isempty(get(handles.edit_phi0, 'string')) == 0.0
    if isnan(larc05_phi0) == 1.0 || isinf(larc05_phi0) == 1.0 || isreal(larc05_phi0) == 0.0
        error = 1.0;
    elseif larc05_phi0 < 0.0 || larc05_phi0 > 180.0
        errordlg('Phi must be in the range (0 <= phi <= 180.0).', 'Quick Fatigue Tool')
        uiwait; enable(handles)
        return
    end
end

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

% Save panel state
setappdata(0, 'larc05_lts', get(handles.edit_lts, 'string'))
setappdata(0, 'larc05_lcs', get(handles.edit_lcs, 'string'))
setappdata(0, 'larc05_tts', get(handles.edit_tts, 'string'))
setappdata(0, 'larc05_tcs', get(handles.edit_tcs, 'string'))
setappdata(0, 'larc05_lss', get(handles.edit_lss, 'string'))
setappdata(0, 'larc05_tss', get(handles.edit_tss, 'string'))
setappdata(0, 'larc05_shear', get(handles.edit_shear, 'string'))
setappdata(0, 'larc05_nl', get(handles.edit_nl, 'string'))
setappdata(0, 'larc05_nt', get(handles.edit_nt, 'string'))
setappdata(0, 'larc05_alpha0', get(handles.edit_alpha0, 'string'))
setappdata(0, 'larc05_phi0', get(handles.edit_phi0, 'string'))
setappdata(0, 'larc05_iterate', get(handles.check_iterate, 'value'))

close 'LaRC05 Parameters'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'LaRC05 Parameters'


% --- Executes when larc05 is resized.
function larc05_ResizeFcn(~, ~, ~)
% hObject    handle to larc05 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function blank(handles)
set(findall(handles.larc05, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
set(findall(handles.larc05, '-property', 'Enable'), 'Enable', 'on')
set(handles.edit_alpha0, 'backgroundColor', 'white')
set(handles.edit_alpha0, 'backgroundColor', [177/255, 206/255, 237/255])

if getappdata(0, 'noSMT') == 1.0
    set(handles.check_iterate, 'enable', 'off')
end


function edit_shear_Callback(~, ~, ~)
% hObject    handle to edit_shear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_shear as text
%        str2double(get(hObject,'String')) returns contents of edit_shear as a double


% --- Executes during object creation, after setting all properties.
function edit_shear_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_shear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_nl_Callback(~, ~, ~)
% hObject    handle to edit_nl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_nl as text
%        str2double(get(hObject,'String')) returns contents of edit_nl as a double


% --- Executes during object creation, after setting all properties.
function edit_nl_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_nl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_nt_Callback(~, ~, ~)
% hObject    handle to edit_nt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_nt as text
%        str2double(get(hObject,'String')) returns contents of edit_nt as a double


% --- Executes during object creation, after setting all properties.
function edit_nt_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_nt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_phi0_Callback(~, ~, ~)
% hObject    handle to edit_phi0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_phi0 as text
%        str2double(get(hObject,'String')) returns contents of edit_phi0 as a double


% --- Executes during object creation, after setting all properties.
function edit_phi0_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_phi0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_alpha0_Callback(~, ~, ~)
% hObject    handle to edit_alpha0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_alpha0 as text
%        str2double(get(hObject,'String')) returns contents of edit_alpha0 as a double


% --- Executes during object creation, after setting all properties.
function edit_alpha0_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_alpha0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_iterate.
function check_iterate_Callback(~, ~, ~)
% hObject    handle to check_iterate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_iterate


% --- Executes when user attempts to close larc05.
function larc05_CloseRequestFcn(hObject, ~, ~)
% hObject    handle to larc05 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rmappdata(0, 'noSMT')

% Hint: delete(hObject) closes the figure
delete(hObject);