function varargout = hashin(varargin)
%HASHIN    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   HASHIN is used internally by Quick Fatigue Tool. The user is
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


% --- Executes just before hashin is made visible.
function hashin_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to hashin (see VARARGIN)

% Choose default command line output for hashin
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes hashin wait for user response (see UIRESUME)
% uiwait(handles.hashin);


% --- Outputs from this function are returned to the command line.
function varargout = hashin_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_lts_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lts as text
%        str2double(get(hObject,'String')) returns contents of edit_lts as a double


% --- Executes during object creation, after setting all properties.
function edit_lts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_lcs_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lcs as text
%        str2double(get(hObject,'String')) returns contents of edit_lcs as a double


% --- Executes during object creation, after setting all properties.
function edit_lcs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_tts_Callback(hObject, eventdata, handles)
% hObject    handle to edit_tts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tts as text
%        str2double(get(hObject,'String')) returns contents of edit_tts as a double


% --- Executes during object creation, after setting all properties.
function edit_tts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_tts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_tcs_Callback(hObject, eventdata, handles)
% hObject    handle to edit_tcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tcs as text
%        str2double(get(hObject,'String')) returns contents of edit_tcs as a double


% --- Executes during object creation, after setting all properties.
function edit_tcs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_tcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_lss_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lss as text
%        str2double(get(hObject,'String')) returns contents of edit_lss as a double


% --- Executes during object creation, after setting all properties.
function edit_lss_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_tss_Callback(hObject, eventdata, handles)
% hObject    handle to edit_tss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tss as text
%        str2double(get(hObject,'String')) returns contents of edit_tss as a double


% --- Executes during object creation, after setting all properties.
function edit_tss_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_tss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_limit_Callback(hObject, eventdata, handles)
% hObject    handle to edit_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_limit as text
%        str2double(get(hObject,'String')) returns contents of edit_limit as a double


% --- Executes during object creation, after setting all properties.
function edit_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(hObject, eventdata, handles)
close 'Hashin Parameters'


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(hObject, eventdata, handles)
close 'Hashin Parameters'


% --- Executes when hashin is resized.
function hashin_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to hashin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
