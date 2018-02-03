function varargout = failStress(varargin)%#ok<*DEFNU>
%FAILSTRESS    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   FAILSTRESS is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-11 Copyright Louis Vallance 2018
%   Last modified 01-Dec-2017 13:15:24 GMT

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @failStress_OpeningFcn, ...
                   'gui_OutputFcn',  @failStress_OutputFcn, ...
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


% --- Executes just before failStress is made visible.
function failStress_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to failStress (see VARARGIN)

% Choose default command line output for failStress
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes failStress wait for user response (see UIRESUME)
% uiwait(handles.failStress);

if isappdata(0, 'failStress_tsfd') == 1.0
    set(handles.edit_tsfd, 'string', getappdata(0, 'failStress_tsfd'))
end
if isappdata(0, 'failStress_csfd') == 1.0
    set(handles.edit_csfd, 'string', getappdata(0, 'failStress_csfd'))
end
if isappdata(0, 'failStress_tstd') == 1.0
    set(handles.edit_tstd, 'string', getappdata(0, 'failStress_tstd'))
end
if isappdata(0, 'failStress_cstd') == 1.0
    set(handles.edit_cstd, 'string', getappdata(0, 'failStress_cstd'))
end
if isappdata(0, 'failStress_tsttd') == 1.0
    set(handles.edit_tsttd, 'string', getappdata(0, 'failStress_tsttd'))
end
if isappdata(0, 'failStress_csttd') == 1.0
    set(handles.edit_csttd, 'string', getappdata(0, 'failStress_csttd'))
end
if isappdata(0, 'failStress_shear') == 1.0
    set(handles.edit_shear, 'string', getappdata(0, 'failStress_shear'))
end
if isappdata(0, 'failStress_cross12') == 1.0
    if isempty(getappdata(0, 'failStress_cross12')) == 1.0
        set(handles.edit_cross12, 'string', '0')
    else
        set(handles.edit_cross12, 'string', getappdata(0, 'failStress_cross12'))
    end
end
if isappdata(0, 'failStress_cross23') == 1.0
    if isempty(getappdata(0, 'failStress_cross23')) == 1.0
        set(handles.edit_cross23, 'string', '0')
    else
        set(handles.edit_cross23, 'string', getappdata(0, 'failStress_cross23'))
    end
end
if isappdata(0, 'failStress_limit12') == 1.0
    set(handles.edit_limit12, 'string', getappdata(0, 'failStress_limit12'))
end
if isappdata(0, 'failStress_limit23') == 1.0
    set(handles.edit_limit23, 'string', getappdata(0, 'failStress_limit23'))
end

% Load icon
[a,~]=imread('icoR_delete.jpg');
[r,c,~]=size(a); 
x=ceil(r/35); 
y=ceil(c/35); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_reset, 'CData', g);


% --- Outputs from this function are returned to the command line.
function varargout = failStress_OutputFcn(~, ~, handles) 
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



function edit_cross23_Callback(~, ~, ~)
% hObject    handle to edit_cross23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cross23 as text
%        str2double(get(hObject,'String')) returns contents of edit_cross23 as a double


% --- Executes during object creation, after setting all properties.
function edit_cross23_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_cross23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_limit12_Callback(~, ~, ~)
% hObject    handle to edit_limit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_limit12 as text
%        str2double(get(hObject,'String')) returns contents of edit_limit12 as a double


% --- Executes during object creation, after setting all properties.
function edit_limit12_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_limit12 (see GCBO)
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

failStress_tsfd = str2double(get(handles.edit_tsfd, 'string'));
if isempty(get(handles.edit_tsfd, 'string')) == 0.0
    if isnan(failStress_tsfd) == 1.0 || isinf(failStress_tsfd) == 1.0 || isreal(failStress_tsfd) == 0.0
        error = 1.0;
    end
end

failStress_csfd = str2double(get(handles.edit_csfd, 'string'));
if isempty(get(handles.edit_csfd, 'string')) == 0.0
    if isnan(failStress_csfd) == 1.0 || isinf(failStress_csfd) == 1.0 || isreal(failStress_csfd) == 0.0
        error = 1.0;
    end
end

failStress_tstd = str2double(get(handles.edit_tstd, 'string'));
if isempty(get(handles.edit_tstd, 'string')) == 0.0
    if isnan(failStress_tstd) == 1.0 || isinf(failStress_tstd) == 1.0 || isreal(failStress_tstd) == 0.0
        error = 1.0;
    end
end

failStress_cstd = str2double(get(handles.edit_cstd, 'string'));
if isempty(get(handles.edit_cstd, 'string')) == 0.0
    if isnan(failStress_cstd) == 1.0 || isinf(failStress_cstd) == 1.0 || isreal(failStress_cstd) == 0.0
        error = 1.0;
    end
end

failStress_tsttd = str2double(get(handles.edit_tsttd, 'string'));
if isempty(get(handles.edit_tsttd, 'string')) == 0.0
    if isnan(failStress_tsttd) == 1.0 || isinf(failStress_tsttd) == 1.0 || isreal(failStress_tsttd) == 0.0
        error = 1.0;
    end
end

failStress_csttd = str2double(get(handles.edit_csttd, 'string'));
if isempty(get(handles.edit_csttd, 'string')) == 0.0
    if isnan(failStress_csttd) == 1.0 || isinf(failStress_csttd) == 1.0 || isreal(failStress_csttd) == 0.0
        error = 1.0;
    end
end

failStress_shear = str2double(get(handles.edit_shear, 'string'));
if isempty(get(handles.edit_shear, 'string')) == 0.0
    if isnan(failStress_shear) == 1.0 || isinf(failStress_shear) == 1.0 || isreal(failStress_shear) == 0.0
        error = 1.0;
    end
end

if isempty(get(handles.edit_cross12, 'string')) == 1.0
    set(handles.edit_cross12, 'string', '0')
else
    failStress_cross12 = str2double(get(handles.edit_cross12, 'string'));
    if isnan(failStress_cross12) == 1.0 || isinf(failStress_cross12) == 1.0 || isreal(failStress_cross12) == 0.0
        error = 1.0;
    end
end

if isempty(get(handles.edit_cross23, 'string')) == 1.0
    set(handles.edit_cross23, 'string', '0')
else
    failStress_cross23 = str2double(get(handles.edit_cross23, 'string'));
    if isnan(failStress_cross23) == 1.0 || isinf(failStress_cross23) == 1.0 || isreal(failStress_cross23) == 0.0
        error = 1.0;
    end
end

failStress_limit12 = str2double(get(handles.edit_limit12, 'string'));
if isempty(get(handles.edit_limit12, 'string')) == 0.0
    if isnan(failStress_limit12) == 1.0 || isinf(failStress_limit12) == 1.0 || isreal(failStress_limit12) == 0.0
        error = 1.0;
    end
end
if failStress_limit12 == 0.0
    errordlg('The stress limit (12) must be non-zero.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

failStress_limit23 = str2double(get(handles.edit_limit23, 'string'));
if isempty(get(handles.edit_limit23, 'string')) == 0.0
    if isnan(failStress_limit23) == 1.0 || isinf(failStress_limit23) == 1.0 || isreal(failStress_limit23) == 0.0
        error = 1.0;
    end
end
if failStress_limit23 == 0.0
    errordlg('The stress limit (23) must be non-zero.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

if failStress_tsfd <= 0.0  || failStress_csfd <= 0.0 || failStress_tstd <= 0.0 || failStress_cstd <= 0.0 || failStress_tsttd <= 0.0 || failStress_csttd <= 0.0 || failStress_shear <= 0.0
    errordlg('Stress values must be positive.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

if isempty(get(handles.edit_cross12, 'string')) == 1.0
    set(handles.edit_cross12, 'string', '0')
end
failStress_cross12 = str2double(get(handles.edit_cross12, 'string'));
if failStress_cross12 < -1.0 || failStress_cross12 > 1.0
    errordlg('The cross product coefficient (12) must be in the range (-1 <= x <= 1.0).', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

if isempty(get(handles.edit_cross23, 'string')) == 1.0
    set(handles.edit_cross23, 'string', '0')
end
failStress_cross23 = str2double(get(handles.edit_cross23, 'string'));
if failStress_cross23 < -1.0 || failStress_cross23 > 1.0
    errordlg('The cross product coefficient (23) must be in the range (-1 <= x <= 1.0).', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

% Save panel state
setappdata(0, 'failStress_tsfd', get(handles.edit_tsfd, 'string'))
setappdata(0, 'failStress_csfd', get(handles.edit_csfd, 'string'))
setappdata(0, 'failStress_tstd', get(handles.edit_tstd, 'string'))
setappdata(0, 'failStress_cstd', get(handles.edit_cstd, 'string'))
setappdata(0, 'failStress_tsttd', get(handles.edit_tsttd, 'string'))
setappdata(0, 'failStress_csttd', get(handles.edit_csttd, 'string'))
setappdata(0, 'failStress_shear', get(handles.edit_shear, 'string'))
setappdata(0, 'failStress_cross12', get(handles.edit_cross12, 'string'))
setappdata(0, 'failStress_cross23', get(handles.edit_cross23, 'string'))
setappdata(0, 'failStress_limit12', get(handles.edit_limit12, 'string'))
setappdata(0, 'failStress_limit23', get(handles.edit_limit23, 'string'))

close 'Fail Stress Parameters'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'Fail Stress Parameters'


% --- Executes when failStress is resized.
function failStress_ResizeFcn(~, ~, ~)
% hObject    handle to failStress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function blank(handles)
set(findall(handles.failStress, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
set(findall(handles.failStress, '-property', 'Enable'), 'Enable', 'on')
set(handles.edit_cross12, 'backgroundColor', 'white')
set(handles.edit_cross12, 'backgroundColor', [177/255, 206/255, 237/255])
set(handles.edit_cross23, 'backgroundColor', 'white')
set(handles.edit_cross23, 'backgroundColor', [177/255, 206/255, 237/255])


function edit_tsttd_Callback(~, ~, ~)
% hObject    handle to edit_tsttd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tsttd as text
%        str2double(get(hObject,'String')) returns contents of edit_tsttd as a double


% --- Executes during object creation, after setting all properties.
function edit_tsttd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tsttd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_csttd_Callback(~, ~, ~)
% hObject    handle to edit_csttd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_csttd as text
%        str2double(get(hObject,'String')) returns contents of edit_csttd as a double


% --- Executes during object creation, after setting all properties.
function edit_csttd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_csttd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_limit23_Callback(~, ~, ~)
% hObject    handle to edit_limit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_limit23 as text
%        str2double(get(hObject,'String')) returns contents of edit_limit23 as a double


% --- Executes during object creation, after setting all properties.
function edit_limit23_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_limit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_cross12_Callback(~, ~, ~)
% hObject    handle to edit_cross12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cross12 as text
%        str2double(get(hObject,'String')) returns contents of edit_cross12 as a double


% --- Executes during object creation, after setting all properties.
function edit_cross12_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_cross12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(~, ~, handles)
set(handles.edit_tsfd, 'string', [])
set(handles.edit_csfd, 'string', [])
set(handles.edit_tstd, 'string', [])
set(handles.edit_cstd, 'string', [])
set(handles.edit_tsttd, 'string', [])
set(handles.edit_csttd, 'string', [])
set(handles.edit_shear, 'string', [])
set(handles.edit_cross12, 'string', 0)
set(handles.edit_cross23, 'string', 0)
set(handles.edit_limit12, 'string', [])
set(handles.edit_limit23, 'string', [])
