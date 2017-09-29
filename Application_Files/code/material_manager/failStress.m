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
%   Quick Fatigue Tool 6.11-04 Copyright Louis Vallance 2017
%   Last modified 29-Sep-2017 15:10:28 GMT

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

if isappdata(0, 'failStress_tsfd')
    set(handles.edit_tsfd, 'string', getappdata(0, 'failStress_tsfd'))
end
if isappdata(0, 'failStress_csfd')
    set(handles.edit_csfd, 'string', getappdata(0, 'failStress_csfd'))
end
if isappdata(0, 'failStress_tstd')
    set(handles.edit_tstd, 'string', getappdata(0, 'failStress_tstd'))
end
if isappdata(0, 'failStress_cstd')
    set(handles.edit_cstd, 'string', getappdata(0, 'failStress_cstd'))
end
if isappdata(0, 'failStress_shear')
    set(handles.edit_shear, 'string', getappdata(0, 'failStress_shear'))
end
if isappdata(0, 'failStress_cross')
    set(handles.edit_cross, 'string', getappdata(0, 'failStress_cross'))
end
if isappdata(0, 'failStress_limit')
    set(handles.edit_limit, 'string', getappdata(0, 'failStress_limit'))
end


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
error = 0.0;

failStress_tsfd = str2double(get(handles.edit_tsfd, 'string'));
if isnan(failStress_tsfd) == 1.0 || isinf(failStress_tsfd) == 1.0 || isreal(failStress_tsfd) == 0.0
    error = 1.0;
end
failStress_csfd = str2double(get(handles.edit_csfd, 'string'));
if isnan(failStress_csfd) == 1.0 || isinf(failStress_csfd) == 1.0 || isreal(failStress_csfd) == 0.0
    error = 1.0;
end
failStress_tstd = str2double(get(handles.edit_tstd, 'string'));
if isnan(failStress_tstd) == 1.0 || isinf(failStress_tstd) == 1.0 || isreal(failStress_tstd) == 0.0
    error = 1.0;
end
failStress_cstd = str2double(get(handles.edit_cstd, 'string'));
if isnan(failStress_cstd) == 1.0 || isinf(failStress_cstd) == 1.0 || isreal(failStress_cstd) == 0.0
    error = 1.0;
end
failStress_shear = str2double(get(handles.edit_shear, 'string'));
if isnan(failStress_shear) == 1.0 || isinf(failStress_shear) == 1.0 || isreal(failStress_shear) == 0.0
    error = 1.0;
end

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    return
end

if failStress_tsfd < 0.0  || failStress_csfd < 0.0 || failStress_tstd < 0.0 || failStress_cstd < 0.0 || failStress_shear < 0.0
    errordlg('Stress values cannot be negative.', 'Quick Fatigue Tool')
    return
end

failStress_cross = str2double(get(handles.edit_cross, 'string'));
if failStress_cross < -1.0 || failStress_cross > 1.0
    errordlg('The cross product coefficient must be in the range (-1 >= x <= 1.0).', 'Quick Fatigue Tool')
    return
end

% Save panel state
setappdata(0, 'failStress_tsfd', get(handles.edit_tsfd, 'string'))
setappdata(0, 'failStress_csfd', get(handles.edit_csfd, 'string'))
setappdata(0, 'failStress_tstd', get(handles.edit_tstd, 'string'))
setappdata(0, 'failStress_cstd', get(handles.edit_cstd, 'string'))
setappdata(0, 'failStress_shear', get(handles.edit_shear, 'string'))
setappdata(0, 'failStress_cross', get(handles.edit_cross, 'string'))
setappdata(0, 'failStress_limit', get(handles.edit_limit, 'string'))

close 'Fail Stress'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'Fail Stress'


% --- Executes when failStress is resized.
function failStress_ResizeFcn(~, ~, ~)
% hObject    handle to failStress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
