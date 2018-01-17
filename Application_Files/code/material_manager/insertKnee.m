function varargout = insertKnee(varargin)%#ok<*DEFNU>
%INSERTKNEE    QFT functions for user material editor.
%   These functions are used to call and operate the User Material user
%   interface.
%   
%   INSERTKNEE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.11-11 Copyright Louis Vallance 2017
%   Last modified 03-Oct-2017 13:44:11 GMT

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @insertKnee_OpeningFcn, ...
                   'gui_OutputFcn',  @insertKnee_OutputFcn, ...
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


% --- Executes just before insertKnee is made visible.
function insertKnee_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to insertKnee (see VARARGIN)

% Choose default command line output for insertKnee
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes insertKnee wait for user response (see UIRESUME)
% uiwait(handles.insertKnee);

if isappdata(0, 'b2')
    set(handles.edit_kneeValue, 'string', getappdata(0, 'b2'))
end
if isappdata(0, 'b2Nf')
    set(handles.edit_kneeLife, 'string', getappdata(0, 'b2Nf'))
end


% --- Outputs from this function are returned to the command line.
function varargout = insertKnee_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close 'Insert Knee'


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
blank(handles)
errors = [0.0, 0.0];
emptyInputs = [0.0, 0.0];

% Check for bad inputs
b2 = str2double(get(handles.edit_kneeValue, 'string'));
if isempty(get(handles.edit_kneeValue, 'string')) == 0.0
    if isnan(b2) == 1.0 || isinf(b2) == 1.0 || isreal(b2) == 0.0
        errors(1.0) = 1.0;
    end
else
    emptyInputs(1.0) = 1.0;
end

b2nf = str2double(get(handles.edit_kneeLife, 'string'));
if isempty(get(handles.edit_kneeLife, 'string')) == 0.0
    if isnan(b2nf) == 1.0 || isinf(b2nf) == 1.0 || isreal(b2nf) == 0.0
        errors(2.0) = 1.0;
    end
else
    emptyInputs(2.0) = 1.0;
end

if any(errors) == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
elseif any(emptyInputs) == 1.0 && all(emptyInputs) == 0.0
    errordlg('Both inputs are required.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

% Check for non-physical inputs
if b2nf <= 0.0
    errordlg('The life at the start of the knee must be positive.', 'Quick Fatigue Tool')
    uiwait; enable(handles)
    return
end

setappdata(0, 'b2', get(handles.edit_kneeValue, 'string'))
setappdata(0, 'b2Nf', get(handles.edit_kneeLife, 'string'))

close 'Insert Knee'



function edit_kneeValue_Callback(~, ~, ~)
% hObject    handle to edit_kneeValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_kneeValue as text
%        str2double(get(hObject,'String')) returns contents of edit_kneeValue as a double


% --- Executes during object creation, after setting all properties.
function edit_kneeValue_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_kneeValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_kneeLife_Callback(~, ~, ~)
% hObject    handle to edit_kneeLife (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_kneeLife as text
%        str2double(get(hObject,'String')) returns contents of edit_kneeLife as a double


% --- Executes during object creation, after setting all properties.
function edit_kneeLife_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_kneeLife (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function blank(handles)
set(findall(handles.insertKnee, '-property', 'Enable'), 'Enable', 'off')


function enable(handles)
set(findall(handles.insertKnee, '-property', 'Enable'), 'Enable', 'on')
