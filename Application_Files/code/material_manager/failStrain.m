function varargout = failStrain(varargin)%#ok<*DEFNU>
%FAILSTRAIN    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   FAILSTRAIN is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-04 Copyright Louis Vallance 2017
%   Last modified 01-Oct-2017 14:09:15 GMT

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @failStrain_OpeningFcn, ...
                   'gui_OutputFcn',  @failStrain_OutputFcn, ...
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


% --- Executes just before failStrain is made visible.
function failStrain_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to failStrain (see VARARGIN)

% Choose default command line output for failStrain
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes failStrain wait for user response (see UIRESUME)
% uiwait(handles.failStrain);

if isappdata(0, 'failStrain_tsfd')
    set(handles.edit_tsfd, 'string', getappdata(0, 'failStrain_tsfd'))
end
if isappdata(0, 'failStrain_csfd')
    set(handles.edit_csfd, 'string', getappdata(0, 'failStrain_csfd'))
end
if isappdata(0, 'failStrain_tstd')
    set(handles.edit_tstd, 'string', getappdata(0, 'failStrain_tstd'))
end
if isappdata(0, 'failStrain_cstd')
    set(handles.edit_cstd, 'string', getappdata(0, 'failStrain_cstd'))
end
if isappdata(0, 'failStrain_shear')
    set(handles.edit_shear, 'string', getappdata(0, 'failStrain_shear'))
end
if isappdata(0, 'failStrain_e11')
    set(handles.edit_e11, 'string', getappdata(0, 'failStrain_e11'))
end
if isappdata(0, 'failStrain_e22')
    set(handles.edit_e22, 'string', getappdata(0, 'failStrain_e22'))
end
if isappdata(0, 'failStrain_g12')
    set(handles.edit_g12, 'string', getappdata(0, 'failStrain_g12'))
end


% --- Outputs from this function are returned to the command line.
function varargout = failStrain_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_tsfd_Callback(~, ~, ~)
% hObject    handle to edit_tsfd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tsfd as text
%        str2double(get(hObject,'String')) returns contents of edit_tsfd as a double


% --- Executes during object creation, after setting all properties.
function edit_tsfd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tsfd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_csfd_Callback(~, ~, ~)
% hObject    handle to edit_csfd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_csfd as text
%        str2double(get(hObject,'String')) returns contents of edit_csfd as a double


% --- Executes during object creation, after setting all properties.
function edit_csfd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_csfd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_tstd_Callback(~, ~, ~)
% hObject    handle to edit_tstd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tstd as text
%        str2double(get(hObject,'String')) returns contents of edit_tstd as a double


% --- Executes during object creation, after setting all properties.
function edit_tstd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tstd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_cstd_Callback(~, ~, ~)
% hObject    handle to edit_cstd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cstd as text
%        str2double(get(hObject,'String')) returns contents of edit_cstd as a double


% --- Executes during object creation, after setting all properties.
function edit_cstd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_cstd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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



function edit_cross_Callback(~, ~, ~)
% hObject    handle to edit_cross (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cross as text
%        str2double(get(hObject,'String')) returns contents of edit_cross as a double


% --- Executes during object creation, after setting all properties.
function edit_cross_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_cross (see GCBO)
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

% Check for bad inputs
failStrain_tsfd = str2double(get(handles.edit_tsfd, 'string'));
if isempty(get(handles.edit_tsfd, 'string')) == 0.0
    if isnan(failStrain_tsfd) == 1.0 || isinf(failStrain_tsfd) == 1.0 || isreal(failStrain_tsfd) == 0.0
        error = 1.0;
    end
end

failStrain_csfd = str2double(get(handles.edit_csfd, 'string'));
if isempty(get(handles.edit_csfd, 'string')) == 0.0
    if isnan(failStrain_csfd) == 1.0 || isinf(failStrain_csfd) == 1.0 || isreal(failStrain_csfd) == 0.0
        error = 1.0;
    end
end

failStrain_tstd = str2double(get(handles.edit_tstd, 'string'));
if isempty(get(handles.edit_tstd, 'string')) == 0.0
    if isnan(failStrain_tstd) == 1.0 || isinf(failStrain_tstd) == 1.0 || isreal(failStrain_tstd) == 0.0
        error = 1.0;
    end
end

failStrain_cstd = str2double(get(handles.edit_cstd, 'string'));
if isempty(get(handles.edit_cstd, 'string')) == 0.0
    if isnan(failStrain_cstd) == 1.0 || isinf(failStrain_cstd) == 1.0 || isreal(failStrain_cstd) == 0.0
        error = 1.0;
    end
end

failStrain_shear = str2double(get(handles.edit_shear, 'string'));
if isempty(get(handles.edit_shear, 'string')) == 0.0
    if isnan(failStrain_shear) == 1.0 || isinf(failStrain_shear) == 1.0 || isreal(failStrain_shear) == 0.0
        error = 1.0;
    end
end

failStrain_e11 = str2double(get(handles.edit_e11, 'string'));
if isempty(get(handles.edit_e11, 'string')) == 0.0
    if isnan(failStrain_e11) == 1.0 || isinf(failStrain_e11) == 1.0 || isreal(failStrain_e11) == 0.0
        error = 1.0;
    end
end

failStrain_e22 = str2double(get(handles.edit_e22, 'string'));
if isempty(get(handles.edit_e22, 'string')) == 0.0
    if isnan(failStrain_e22) == 1.0 || isinf(failStrain_e22) == 1.0 || isreal(failStrain_e22) == 0.0
        error = 1.0;
    end
end

failStrain_g12 = str2double(get(handles.edit_g12, 'string'));
if isempty(get(handles.edit_g12, 'string')) == 0.0
    if isnan(failStrain_g12) == 1.0 || isinf(failStrain_g12) == 1.0 || isreal(failStrain_g12) == 0.0
        error = 1.0;
    end
end

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

% Check for non-physical inputs
if failStrain_tsfd <= 0.0  || failStrain_csfd <= 0.0 || failStrain_tstd <= 0.0 || failStrain_cstd <= 0.0 || failStrain_shear <= 0.0 || failStrain_e11 <= 0.0 || failStrain_e22 <= 0.0 || failStrain_g12 <= 0.0
    errordlg('Stress/strain values must be positive.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

% Save panel state
setappdata(0, 'failStrain_tsfd', get(handles.edit_tsfd, 'string'))
setappdata(0, 'failStrain_csfd', get(handles.edit_csfd, 'string'))
setappdata(0, 'failStrain_tstd', get(handles.edit_tstd, 'string'))
setappdata(0, 'failStrain_cstd', get(handles.edit_cstd, 'string'))
setappdata(0, 'failStrain_shear', get(handles.edit_shear, 'string'))
setappdata(0, 'failStrain_e11', get(handles.edit_e11, 'string'))
setappdata(0, 'failStrain_e22', get(handles.edit_e22, 'string'))
setappdata(0, 'failStrain_g12', get(handles.edit_g12, 'string'))

close 'Fail Strain'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'Fail Strain'


% --- Executes when failStrain is resized.
function failStrain_ResizeFcn(~, ~, ~)
% hObject    handle to failStrain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function blank(handles)
set(findall(handles.failStrain, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
set(findall(handles.failStrain, '-property', 'Enable'), 'Enable', 'on')



function edit_e11_Callback(~, ~, ~)
% hObject    handle to edit_e11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_e11 as text
%        str2double(get(hObject,'String')) returns contents of edit_e11 as a double


% --- Executes during object creation, after setting all properties.
function edit_e11_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_e11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_e22_Callback(~, ~, ~)
% hObject    handle to edit_e22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_e22 as text
%        str2double(get(hObject,'String')) returns contents of edit_e22 as a double


% --- Executes during object creation, after setting all properties.
function edit_e22_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_e22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_g12_Callback(~, ~, ~)
% hObject    handle to edit_g12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_g12 as text
%        str2double(get(hObject,'String')) returns contents of edit_g12 as a double


% --- Executes during object creation, after setting all properties.
function edit_g12_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_g12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
