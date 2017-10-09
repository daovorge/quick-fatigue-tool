function varargout = hashin(varargin)%#ok<*DEFNU>
%HASHINDAMAGE    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   HASHINDAMAGE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-05 Copyright Louis Vallance 2017
%   Last modified 09-Oct-2017 11:03:00 GMT

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @hashin_OpeningFcn, ...
                   'gui_OutputFcn',  @hashin_OutputFcn, ...
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


% --- Executes just before hashinDamage is made visible.
function hashin_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to hashinDamage (see VARARGIN)

% Choose default command line output for hashinDamage
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes hashinDamage wait for user response (see UIRESUME)
% uiwait(handles.hashinDamage);

if isappdata(0, 'hashin_alpha') == 1.0
    if isempty(getappdata(0, 'hashin_alpha')) == 1.0
        set(handles.edit_alpha, 'string', '0')
    else
        set(handles.edit_alpha, 'string', getappdata(0, 'hashin_alpha'))
    end
end
if isappdata(0, 'hashin_lts') == 1.0
    set(handles.edit_lts, 'string', getappdata(0, 'hashin_lts'))
end
if isappdata(0, 'hashin_lcs') == 1.0
    set(handles.edit_lcs, 'string', getappdata(0, 'hashin_lcs'))
end
if isappdata(0, 'hashin_tts') == 1.0
    set(handles.edit_tts, 'string', getappdata(0, 'hashin_tts'))
end
if isappdata(0, 'hashin_tcs') == 1.0
    set(handles.edit_tcs, 'string', getappdata(0, 'hashin_tcs'))
end
if isappdata(0, 'hashin_lss') == 1.0
    set(handles.edit_lss, 'string', getappdata(0, 'hashin_lss'))
end
if isappdata(0, 'hashin_tss') == 1.0
    set(handles.edit_tss, 'string', getappdata(0, 'hashin_tss'))
end


% --- Outputs from this function are returned to the command line.
function varargout = hashin_OutputFcn(~, ~, handles) 
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



function edit_limit_Callback(~, ~, ~)
% hObject    handle to edit_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_limit as text
%        str2double(get(hObject,'String')) returns contents of edit_limit as a double


% --- Executes during object creation, after setting all properties.
function edit_limit_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_limit (see GCBO)
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

if isempty(get(handles.edit_alpha, 'string')) == 1.0
    set(handles.edit_alpha, 'string', '0')
else
    hashin_alpha = str2double(get(handles.edit_alpha, 'string'));
    if isnan(hashin_alpha) == 1.0 || isinf(hashin_alpha) == 1.0 || isreal(hashin_alpha) == 0.0
        error = 1.0;
    elseif hashin_alpha < -1.0 || hashin_alpha > 1.0
        errordlg('Alpha must be in the range (0 <= alpha <= 1.0).', 'Quick Fatigue Tool')
        uiwait; enable(handles)
        return
    end
end

hashin_lts = str2double(get(handles.edit_lts, 'string'));
if isempty(get(handles.edit_lts, 'string')) == 0.0
    if isnan(hashin_lts) == 1.0 || isinf(hashin_lts) == 1.0 || isreal(hashin_lts) == 0.0
        error = 1.0;
    end
end

hashin_lcs = str2double(get(handles.edit_lcs, 'string'));
if isempty(get(handles.edit_lcs, 'string')) == 0.0
    if isnan(hashin_lcs) == 1.0 || isinf(hashin_lcs) == 1.0 || isreal(hashin_lcs) == 0.0
        error = 1.0;
    end
end

hashin_tts = str2double(get(handles.edit_tts, 'string'));
if isempty(get(handles.edit_tts, 'string')) == 0.0
    if isnan(hashin_tts) == 1.0 || isinf(hashin_tts) == 1.0 || isreal(hashin_tts) == 0.0
        error = 1.0;
    end
end

hashin_tcs = str2double(get(handles.edit_tcs, 'string'));
if isempty(get(handles.edit_tcs, 'string')) == 0.0
    if isnan(hashin_tcs) == 1.0 || isinf(hashin_tcs) == 1.0 || isreal(hashin_tcs) == 0.0
        error = 1.0;
    end
end

hashin_lss = str2double(get(handles.edit_lss, 'string'));
if isempty(get(handles.edit_lss, 'string')) == 0.0
    if isnan(hashin_lss) == 1.0 || isinf(hashin_lss) == 1.0 || isreal(hashin_lss) == 0.0
        error = 1.0;
    end
end

hashin_tss = str2double(get(handles.edit_tss, 'string'));
if isempty(get(handles.edit_tss, 'string')) == 0.0
    if isnan(hashin_tss) == 1.0 || isinf(hashin_tss) == 1.0 || isreal(hashin_tss) == 0.0
        error = 1.0;
    end
end

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

% Save panel state
setappdata(0, 'hashin_alpha', get(handles.edit_alpha, 'string'))
setappdata(0, 'hashin_lts', get(handles.edit_lts, 'string'))
setappdata(0, 'hashin_lcs', get(handles.edit_lcs, 'string'))
setappdata(0, 'hashin_tts', get(handles.edit_tts, 'string'))
setappdata(0, 'hashin_tcs', get(handles.edit_tcs, 'string'))
setappdata(0, 'hashin_lss', get(handles.edit_lss, 'string'))
setappdata(0, 'hashin_tss', get(handles.edit_tss, 'string'))

close 'Hashin Parameters'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'Hashin Parameters'


% --- Executes when hashinDamage is resized.
function hashinDamage_ResizeFcn(~, ~, ~)
% hObject    handle to hashinDamage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_alpha_Callback(~, ~, ~)
% hObject    handle to edit_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_alpha as text
%        str2double(get(hObject,'String')) returns contents of edit_alpha as a double


% --- Executes during object creation, after setting all properties.
function edit_alpha_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function blank(handles)
set(findall(handles.hashinDamage, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
set(findall(handles.hashinDamage, '-property', 'Enable'), 'Enable', 'on')
