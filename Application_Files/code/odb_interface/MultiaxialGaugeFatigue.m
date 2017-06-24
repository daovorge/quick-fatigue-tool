function varargout = MultiaxialGaugeFatigue(varargin)
%MULTIAXIALGAUGEFATIGUE M-file for MultiaxialGaugeFatigue.fig
%      MULTIAXIALGAUGEFATIGUE, by itself, creates a new MULTIAXIALGAUGEFATIGUE or raises the existing
%      singleton*.
%
%      H = MULTIAXIALGAUGEFATIGUE returns the handle to a new MULTIAXIALGAUGEFATIGUE or the handle to
%      the existing singleton*.
%
%      MULTIAXIALGAUGEFATIGUE('Property','Value',...) creates a new MULTIAXIALGAUGEFATIGUE using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to MultiaxialGaugeFatigue_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      MULTIAXIALGAUGEFATIGUE('CALLBACK') and MULTIAXIALGAUGEFATIGUE('CALLBACK',hObject,...) call the
%      local function named CALLBACK in MULTIAXIALGAUGEFATIGUE.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MultiaxialGaugeFatigue

% Last Modified by GUIDE v2.5 24-Jun-2017 15:14:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MultiaxialGaugeFatigue_OpeningFcn, ...
                   'gui_OutputFcn',  @MultiaxialGaugeFatigue_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before MultiaxialGaugeFatigue is made visible.
function MultiaxialGaugeFatigue_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for MultiaxialGaugeFatigue
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MultiaxialGaugeFatigue wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MultiaxialGaugeFatigue_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close MultiaxialGaugeFatigue.
function MultiaxialGaugeFatigue_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to MultiaxialGaugeFatigue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_analyse.
function pButton_analyse_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_analyse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_location_Callback(hObject, eventdata, handles)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_location as text
%        str2double(get(hObject,'String')) returns contents of edit_location as a double


% --- Executes during object creation, after setting all properties.
function edit_location_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_location.
function pButton_location_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in check_location.
function check_location_Callback(hObject, eventdata, handles)
% hObject    handle to check_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_location


% --- Executes when selected object is changed in panel_algorithm.
function panel_algorithm_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_algorithm 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in panel_msc.
function panel_msc_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_msc 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in panel_kt.
function panel_kt_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_kt 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_createMaterial.
function pButton_createMaterial_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_createMaterial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_matManager.
function pButton_matManager_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_matManager (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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
% hObject    handle to pButton_browseMaterial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_materialOptions.
function pButton_materialOptions_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_materialOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_gauge_0_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gauge_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gauge_0 as text
%        str2double(get(hObject,'String')) returns contents of edit_gauge_0 as a double


% --- Executes during object creation, after setting all properties.
function edit_gauge_0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gauge_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_gauge_45_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gauge_45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gauge_45 as text
%        str2double(get(hObject,'String')) returns contents of edit_gauge_45 as a double


% --- Executes during object creation, after setting all properties.
function edit_gauge_45_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gauge_45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_gauge_90_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gauge_90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gauge_90 as text
%        str2double(get(hObject,'String')) returns contents of edit_gauge_90 as a double


% --- Executes during object creation, after setting all properties.
function edit_gauge_90_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gauge_90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_gauge_0_path.
function pButton_gauge_0_path_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_gauge_0_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_gauge_45_path.
function pButton_gauge_45_path_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_gauge_45_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pButton_gauge_90_path.
function pButton_gauge_90_path_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_gauge_90_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in pMenu_units.
function pMenu_units_Callback(hObject, eventdata, handles)
% hObject    handle to pMenu_units (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_units contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_units


% --- Executes during object creation, after setting all properties.
function pMenu_units_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pMenu_units (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_conversionFactor_Callback(hObject, eventdata, handles)
% hObject    handle to edit_conversionFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_conversionFactor as text
%        str2double(get(hObject,'String')) returns contents of edit_conversionFactor as a double


% --- Executes during object creation, after setting all properties.
function edit_conversionFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_conversionFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_gaugeOrientation.
function pButton_gaugeOrientation_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_gaugeOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in pMenu_kt_list.
function pMenu_kt_list_Callback(hObject, eventdata, handles)
% hObject    handle to pMenu_kt_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_kt_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_kt_list


% --- Executes during object creation, after setting all properties.
function pMenu_kt_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pMenu_kt_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_surfaceFinish.
function pMenu_surfaceFinish_Callback(hObject, eventdata, handles)
% hObject    handle to pMenu_surfaceFinish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_surfaceFinish contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_surfaceFinish


% --- Executes during object creation, after setting all properties.
function pMenu_surfaceFinish_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pMenu_surfaceFinish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_rz_Callback(hObject, eventdata, handles)
% hObject    handle to edit_rz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_rz as text
%        str2double(get(hObject,'String')) returns contents of edit_rz as a double


% --- Executes during object creation, after setting all properties.
function edit_rz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_rz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_kt_Callback(hObject, eventdata, handles)
% hObject    handle to edit_kt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_kt as text
%        str2double(get(hObject,'String')) returns contents of edit_kt as a double


% --- Executes during object creation, after setting all properties.
function edit_kt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_kt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_kt_direct.
function check_kt_direct_Callback(hObject, eventdata, handles)
% hObject    handle to check_kt_direct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_kt_direct


% --- Executes on button press in pButton_msc_user.
function pButton_msc_user_Callback(hObject, eventdata, handles)
% hObject    handle to pButton_msc_user (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_msc_user_Callback(hObject, eventdata, handles)
% hObject    handle to edit_msc_user (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_msc_user as text
%        str2double(get(hObject,'String')) returns contents of edit_msc_user as a double


% --- Executes during object creation, after setting all properties.
function edit_msc_user_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_msc_user (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_ucs.
function check_ucs_Callback(hObject, eventdata, handles)
% hObject    handle to check_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_ucs



function edit_ucs_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ucs as text
%        str2double(get(hObject,'String')) returns contents of edit_ucs as a double


% --- Executes during object creation, after setting all properties.
function edit_ucs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_precision_Callback(hObject, eventdata, handles)
% hObject    handle to edit_precision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_precision as text
%        str2double(get(hObject,'String')) returns contents of edit_precision as a double


% --- Executes during object creation, after setting all properties.
function edit_precision_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_precision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
