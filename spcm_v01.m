% SPCM GUI for data acquisition and motor control
% Author: Mathew L. Kelley
% Affiliation: University of South Carolina
% Version 0-1: to be continued in Version 0-2

function varargout = spcm_v01(varargin)
% SPCM_V01 MATLAB code for spcm_v01.fig
%      SPCM_V01, by itself, creates a new SPCM_V01 or raises the existing
%      singleton*.
%
%      H = SPCM_V01 returns the handle to a new SPCM_V01 or the handle to
%      the existing singleton*.
%
%      SPCM_V01('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPCM_V01.M with the given input arguments.
%
%      SPCM_V01('Property','Value',...) creates a new SPCM_V01 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before spcm_v01_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to spcm_v01_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help spcm_v01

% Last Modified by GUIDE v2.5 03-Aug-2020 06:59:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @spcm_v01_OpeningFcn, ...
                   'gui_OutputFcn',  @spcm_v01_OutputFcn, ...
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

% MK development notes: (as of 20200318)
% ActiveX controls are for Thorlabs TDC001 motors with progid 'MGMOTOR.MGMotorCtrl.1'
% X motor (activex1) SN: 83847329
% Y motor (activex2) SN: 83847348
% Z motor (not used, but available) SN: 83847385

% --- Executes just before spcm_v01 is made visible.
function spcm_v01_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spcm_v01 (see VARARGIN)

% Choose default command line output for spcm_v01 
handles.output = hObject;

% Clear global variables (avoid start scan without output directory):
clearvars -global

% Notify user to wait on motors to boot up: 
bootup_init_message(hObject, eventdata, handles)

% Display the SPCM application logo:
axes(handles.axes7)
logo = imread(['C:\Users\greytaklab\Documents\MATLAB\spcm_guide\SPCM_v01\mk_spcm_applogo.png']);
image(logo)
axis off
axis image

% Syntax to initialize variables in handles:
% https://www.mathworks.com/matlabcentral/answers/335294-how-to-initialize-a-variable-in-a-gui
% handles.n=0;
% handles.string_test = 'hello world';
% disp(handles)
% disp(handles.n)

% Motor setup: (used global variables; not sure if best practice)
% Put 'global variablename' at beginning of each function that needs to see
% that variable
global x y;  % variables for X motor, Y motor, IChanID; not sure if best practice 

% Initialize handle vales: (value of '0' until the 'Home', 'Line scan', or 'Initiate' pushbuttons are selected)
handles.home_init = 0;
handles.line_scan_init = 0;
handles.scan_initiate_init = 0;
handles.scan_mode = 0;  % '0' = step/jog/step mode, '1' = continuous scan mode

% Make x and y global variables so they can be used outside the scope of main function. 
%   Useful when you do event handling and sequential move
% To check the available methods for the 'MGMOTOR.MGMotorCtrl.1' class,
%   enter 'activexobject.methodsview' (e.g. x.methodsview):
%   (opens a window with ReturnType, Name, Arguments fields for all methods)
% Also refer to the APT Server.chm HTML file on the Thorlabs program folder:
%   C:\Program Files (x86)\Thorlabs\APT\APT Server

% X motor initialization:
x = handles.activex4;
x.StartCtrl;
% Set the Serial Number
SN = 83847385; % put in the serial number of the hardware (z for now)
set(x, 'HWSerialNum', SN);  % specify the serial number of the APT motor using HWSerialNum property
% Indentify the device
x.Identify;
pause(3); % waiting for the GUI to load up;

% Y motor initialization:
y = handles.activex7;
y.StartCtrl;
% Set the Serial Number
SN = 83847348; % **83847348 is true y motor SN, change back after tests**
set(y, 'HWSerialNum', SN);  % specify the serial number of the APT motor using HWSerialNum property
% Indentify the device
y.Identify;
pause(3); % waiting for the GUI to load up;

% Set IChanID:
handles.IChanID = single(0);  % Not sure purpose; Labview set this to '0' in EnableHWChannel method (numbers >1 do not work)
% Channel ID of 0: set to single data type
y.EnableHWChannel(handles.IChanID);  % This method enables drive ouptut 
x.EnableHWChannel(handles.IChanID);  % This method enables drive ouptut

% Store original motor velocity and acceleration values:
% [IChanID, minvelocity, acceleration, maxvelocity] = should be [0, 0, 1.5, 2.2]
[IChanID, handles.v_min_original, handles.accn_original, handles.v_max_original] = x.GetVelParams(handles.IChanID, 1, 1, 1);

% Notify user that motors have initialized:
bootup_complete_message(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes spcm_v01 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = spcm_v01_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on startup: (spcm_v01_OpeningFcn)
function bootup_init_message(hObject, eventdata, handles)
    myString = sprintf(['Motors are initializing. Please wait.']);
    set(handles.Status_display_message_static_text, 'String', myString);

% Update handles structure
guidata(hObject, handles);


% --- Executes following initialization of motors in startup:
% (spcm_v01_OpeningFcn)
function bootup_complete_message(hObject, eventdata, handles)
    myString = sprintf(['Motors are initialized. General status' ...
        ' messages will be displayed here. Global variables have' ...
        ' been cleared.']);
    set(handles.Status_display_message_static_text, 'String', myString);
    
% Update handles structure
guidata(hObject, handles);


function x_start_edit_Callback(hObject, eventdata, handles)
% hObject    handle to x_start_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of x_start_edit as text
%        str2double(get(hObject,'String')) returns contents of x_start_edit as a double


% --- Executes during object creation, after setting all properties.
function x_start_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x_start_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function x_end_edit_Callback(hObject, eventdata, handles)
% hObject    handle to x_end_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of x_end_edit as text
%        str2double(get(hObject,'String')) returns contents of x_end_edit as a double


% --- Executes during object creation, after setting all properties.
function x_end_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x_end_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function x_step_size_edit_Callback(hObject, eventdata, handles)
% hObject    handle to x_step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of x_step_size_edit as text
%        str2double(get(hObject,'String')) returns contents of x_step_size_edit as a double


% --- Executes during object creation, after setting all properties.
function x_step_size_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x_step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function y_start_edit_Callback(hObject, eventdata, handles)
% hObject    handle to y_start_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of y_start_edit as text
%        str2double(get(hObject,'String')) returns contents of y_start_edit as a double


% --- Executes during object creation, after setting all properties.
function y_start_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y_start_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function y_end_edit_Callback(hObject, eventdata, handles)
% hObject    handle to y_end_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of y_end_edit as text
%        str2double(get(hObject,'String')) returns contents of y_end_edit as a double


% --- Executes during object creation, after setting all properties.
function y_end_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y_end_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function y_step_size_edit_Callback(hObject, eventdata, handles)
% hObject    handle to y_step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of y_step_size_edit as text
%        str2double(get(hObject,'String')) returns contents of y_step_size_edit as a double


% --- Executes during object creation, after setting all properties.
function y_step_size_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y_step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in Home_pushbutton.
function Home_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Home_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global x
global y

% Returns variables 'x_home' and 'y_home' with absolute current motor position (e.g. position is 4.035 mm)
% The returned variables 'IChanID_' are the IChanID value assigned in
% earlier block; they are assigned and deleted in this block.
[IChanID_x_return, x_home] = x.GetPosition(handles.IChanID, 1);
[IChanID_y_return, y_home] = y.GetPosition(handles.IChanID, 1);

clear IChanID_y_return  %IChanID_x_return

set(handles.Status_display_message_static_text, 'String', '');
myString = sprintf(['Stage is now homed. Current X and Y motor positions of ' ...
    num2str(y_home) ' mm and ' num2str(x_home) ' were set to the home' ...
    ' positions. If these are not the desired positions, move to the' ...
    ' desired position and select ''Home'' again.']);
set(handles.Status_display_message_static_text, 'String', myString);
drawnow; % Needed only if this is in a fast loop.

handles.home_init = 1;  % sets handles.home_init to '1' from '0', allowing SPCM to start

handles.y_home = y_home;
handles.x_home = x_home;

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Initiate_scan_pushbutton.
function Initiate_scan_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Start_scan_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check the scan mode: (continuous or step mode)
current_checkbox_value = get(handles.scan_mode_checkbox1, 'value');

if isfield(handles, 'pathname')
    if(isempty(handles.pathname))
        % initialization_denied function: (path handle exists, but path cleared)
        initialization_denied(hObject, eventdata, handles);
    else
        if isequal(handles.home_init, 1)
            % Scan parameter setup: ('str2double'returns 'NaN' for non-numeric data)
            handles.scan_parameter_values = {str2double(get(handles.x_start_edit, 'String')), ...
                str2double(get(handles.x_end_edit, 'String')), ...
                str2double(get(handles.x_step_size_edit, 'String')), ...
                str2double(get(handles.y_start_edit, 'String')), ...
                str2double(get(handles.y_end_edit, 'String')), ...
                str2double(get(handles.y_step_size_edit, 'String'))};
            
            % Check that scan parameter fields all contain data of the double type:
            handles.scan_parameter_values_check = cell(1,6);  % preallocate empty cell array
            for h = 1:6  % returns 1x6 cell array; non-numbers are NaNs and return '1'
                handles.scan_parameter_values_check{h} = isnan(handles.scan_parameter_values{h});
            end
            % Update handles structure
            guidata(hObject, handles);
            if isequal(handles.scan_parameter_values_check, {0, 0, 0, 0, 0, 0})  % cell array of doubles showing all edittexts have values of double data type

                % Save experimental notes from the edit text box: (.mat)
                experimental_notes_edit_Callback(hObject, eventdata, handles);                
                                
                % Create handles for X scan parameters:
                handles.x_start = str2double(get(handles.x_start_edit, 'String'));  % start position, typically 0, units of mm
                handles.x_end = str2double(get(handles.x_end_edit, 'String'));  % end position from x_home, units of mm
                handles.x_stepsize = str2double(get(handles.x_step_size_edit, 'String'));  % stage step size, units of mm, do 0.01 today
                handles.x_points = (handles.x_end - handles.x_start)/handles.x_stepsize;  % number of points between x_start and x_end
                handles.x_points_plus = handles.x_points + 1;  % Labview adds 1 (to include beginning point)
                handles.x_distances = linspace(handles.x_start, handles.x_end, handles.x_points_plus);  % array for each distance based on x_start, x_end, and x_points  

                % Create handles for Y scan parameters and empty map :
                handles.y_start = str2double(get(handles.y_start_edit, 'String'));  % start position, typically 0, units of mm
                handles.y_end = str2double(get(handles.y_end_edit, 'String'));  % end position from x_home, units of mm
                handles.y_stepsize = str2double(get(handles.y_step_size_edit, 'String'));  % stage step size, units of mm, do 0.01 today
                handles.y_points = (handles.y_end - handles.y_start)/handles.y_stepsize;  % number of points between x_start and x_end
                handles.y_points_plus = handles.y_points + 1;  % Labview adds 1 (to include beginning point)
                handles.y_distances = linspace(handles.y_start, handles.y_end, handles.y_points_plus);  % array for each distance based on x_start, x_end, and x_points 

                % --- Make empty arrays for channels ai0, ai1, ai2: (BNC #1-3)
                handles.data1_matrix_1 = zeros(length(handles.x_distances), length(handles.y_distances));  % channel ai0, value 1 (because 2 scans are acquired, take first)
                handles.data2_matrix_1 = zeros(length(handles.x_distances), length(handles.y_distances));  % channel ai1, value 1 (because 2 scans are acquired, take first)
                handles.data3_matrix_1 = zeros(length(handles.x_distances), length(handles.y_distances));  % channel ai2, value 1 (because 2 scans are acquired, take first)
                handles.data4_matrix_1 = zeros(length(handles.x_distances), length(handles.y_distances));  % channel ai3, value 1 (because 2 scans are acquired, take first)
                
                % --- Make structure for X and Y motor scan parameters and empty map arrays:
                handles.SPCM_struct = struct('x_start', handles.x_start, ...
                    'x_end', handles.x_end, 'x_stepsize', handles.x_stepsize, ...
                    'x_points', handles.x_points, 'x_points_plus', handles.x_points_plus, ...
                    'x_distances', handles.x_distances, 'y_start', handles.y_start, ...
                    'y_end', handles.y_end, 'y_stepsize', handles.y_stepsize, ...
                    'y_points', handles.y_points, 'y_points_plus', handles.y_points_plus, ...
                    'y_distances', handles.y_distances, 'ch_ai0_map', handles.data1_matrix_1, ...
                    'ch_ai1_map', handles.data2_matrix_1, 'ch_ai2_map', handles.data3_matrix_1, ...
                    'ch_ai3_map', handles.data4_matrix_1);
                
                % Initiate scan parameters: (save structures
                scan_initiate(hObject, eventdata, handles);              
                                   
                % Assign value of '1' to 'handles.scan_initiate_init' field:
                % (enables 'scan_run' function to execute)
                handles.scan_initiate_init = 1;
                
                % Status display message according to scan mode:
                if current_checkbox_value == 1 
                    myString = sprintf(['Scan has been initialized successfully.' ...
                        ' Scan will be taken in ''Continuous mode''. If this is' ...
                        ' incorrect, uncheck the ''Scan mode'' checkbox and' ...
                        ' select ''Initialize scan'' to change the scan mode' ...
                        ' to ''Step mode''. Otherwise, the scan may begin' ...
                        ' by selecting ''Start scan''.']);
                    set(handles.Status_display_message_static_text, 'String', myString);
                    
                else
                    myString = sprintf(['Scan has been initialized successfully.' ...
                        ' Scan will be taken in ''Step mode''. If this is' ...
                        ' incorrect, check the ''Scan mode'' checkbox and' ...
                        ' select ''Initialize scan'' to change the scan mode' ...
                        ' to ''Continuous mode''. Otherwise, the scan may' ...
                        ' begin by selecting ''Start scan''.']);
                    set(handles.Status_display_message_static_text, 'String', myString);
                end              
                
            else
                % initialization_denied function: (non-numeric scan parameters)
                initialization_denied(hObject, eventdata, handles);
            end
        else
            % initialization_denied function: (stage home not set)
            initialization_denied(hObject, eventdata, handles);
        end
    end
else
    % initialization_denied function: (user not yet chosen a path)
    initialization_denied(hObject, eventdata, handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes when SPCM scan has successfully initialized
function experimental_notes_edit_Callback(hObject, eventdata, handles)
% hObject    handle to experimental_notes_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of experimental_notes_edit as text
%        str2double(get(hObject,'String')) returns contents of experimental_notes_edit as a double

% Assign contents to 'experimental_notes_edit' handle:
handles.experimental_notes_edit_data = get(handles.experimental_notes_edit, 'String');
% https://www.mathworks.com/matlabcentral/answers/90312-how-to-save-data-from-gui-handles

handles.experimental_notes_edit_data{1, 1};
cd(handles.pathname)
mkdir('SPCM_mat_files'); cd('SPCM_mat_files');
SPCM_experimental_notes_mat = handles.experimental_notes_edit_data{1, 1};
save('SPCM_experimental_notes.mat', 'SPCM_experimental_notes_mat')
cd ..

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function experimental_notes_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to experimental_notes_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Choose_pushbutton.
function Choose_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Choose_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.pathname = uigetdir();  % UI select directory to save output data to
    if isequal(handles.pathname, 0)
        myString = sprintf(['No directory selected. Please choose a directory ' ...
            'to save output data before beginning the SPCM scan.']);
        set(handles.Status_display_message_static_text, 'String', myString);
        set(handles.Output_path_static_text, 'String', 'Choose directory here');
        clearvars -global -except x* y*  % clears globals except motor information
        handles.pathname = [];
    else
        myString = sprintf('%s', ['Output data will be saved in:' ...
            sprintf('\n') fullfile(handles.pathname)]);  % '%s' works to eliminate escape characters
        set(handles.Status_display_message_static_text, 'String', myString);
        set(handles.Output_path_static_text, 'String', fullfile(handles.pathname));
        drawnow; % Needed only if this is in a fast loop.
    end
    
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Line_scan_pushbutton.
function Line_scan_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Line_scan_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myString = sprintf(['Line scan functionality has not been implemented yet!']);
set(handles.Status_display_message_static_text, 'String', myString);

% make it so the line scan occurs dependent on scan mode checkbox
% if statement for value of handles.scan_mode field
% do after get the actual motor parameters setup in the scan_start callback


% Update handles structure
guidata(hObject, handles);


% --- Executes if conditions are unsatisfactory for SPCM scan to begin
function initialization_denied(hObject, eventdata, handles)
    myString = sprintf(['SPCM scan did not initiate. Ensure that the' ...
        ' stage has been homed, an output directory has been chosen, and' ...
        ' all fields in the scan parameters panel include numeric values.']);
    set(handles.Status_display_message_static_text, 'String', myString);
    
    
% Update handles structure
guidata(hObject, handles);


% --- Calculates number of steps and other scan parameters:
function scan_initiate(hObject, eventdata, handles)

% Create and save scan parameter struct in .mat directory:
% (contains x/y start/end, step size, etc.)
cd(handles.pathname);
cd SPCM_mat_files
SPCM_struct = handles.SPCM_struct;
save('SPCM_struct.mat', 'SPCM_struct')
cd ..


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Start_scan_pushbutton.
function Start_scan_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Initiate_scan_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    

global x y ai0 ai1 ai2 ai3

warning('off','MATLAB:MKDIR:DirectoryExists')
% Could not update handle values in the loop, so resorted to global
% variables (all globals are cleared on startup and ai0-ai3 can be cleared
% after loop completes and data is saved as .txt though to avoid
% complications and allow a second scan without requiring restart app to
% clear global variables?)

current_checkbox_value = get(handles.scan_mode_checkbox1, 'value');

if isequal(handles.scan_initiate_init, 1)
    % Global variables here because handle fields do not update in callback
    % until the function has executed
    ai0 = zeros(length(handles.x_distances), length(handles.y_distances));
    ai1 = zeros(length(handles.x_distances), length(handles.y_distances));
    ai2 = zeros(length(handles.x_distances), length(handles.y_distances));
    ai3 = zeros(length(handles.x_distances), length(handles.y_distances));
    
    % Status display message:
    start_time = datestr(datetime);
    myString_pathname_check = sprintf('%s', ['SPCM scan will begin.' ...
        ' Output data will be saved in: ' fullfile(handles.pathname) '. ']);
    myString_home_init_check = sprintf(['User has homed the stages at ' ...
        ' X = ' num2str(handles.x_home) ' mm and Y = ' num2str(handles.y_home) ...
        ' mm. ']);
    myString_SPCM_init = sprintf(['Start time: ' start_time '. ' ...
        'Please record pertinent details in your laboratory notebook.']);
    set(handles.Status_display_message_static_text, 'String', [myString_pathname_check ...
        myString_home_init_check myString_SPCM_init]);

%     if current_checkbox_value == 0;
        
        % Motor movement, data acquisition, and data display:
        for j = 1:handles.y_points_plus(1)  % if the first value in for loop is 0 or negative, this gives matlab error when assigning data to the matrix indices (negative or 0 values give error)

                for k = 1:handles.x_points_plus(1)
                    handles = guidata(hObject);
                    % Measure data before moving:
                    % Setup NIDAQ sesison object:
                    % nidaq_device_info = daq.getDevices;
                    step = daq.createSession('ni');
                    addAnalogInputChannel(step,'Dev1', [0 1 2 3], 'Voltage');  % [0 1 2] records values from channels ai0, ai1, and ai2 simultaneously
                    % s.Rate = 1;  % change session rate from default 1000 scans/sec to 8000 scans/second
                    step.DurationInSeconds = 0.002;  % minimum of 2 scans (for startForeground command; maybe make it record both
                    [data, timeStamps, triggerTime] = step.startForeground;

                    myString_current_data = sprintf(['Ch. ai0 data of: ' num2str(data(1, 1)) ' recorded.' ...
                        '        Ch. ai1 data of: ' num2str(data(1, 2)) ' recorded.' ...
                        '        Ch. ai2 data of: ' num2str(data(1, 3)) ' recorded.' ...
                        '        Ch. ai3 data of: ' num2str(data(1, 4)) ' recorded.']);
                    set(handles.Status_display_message_static_text, 'String', [myString_pathname_check ...
                        myString_home_init_check sprintf('\n') myString_SPCM_init ...
                        sprintf('\n') myString_current_data]);

                    % Global variables here to save data before loops finish:
                    ai0(k, j) = data(1, 1);
                    ai1(k, j) = data(1, 2);
                    ai2(k, j) = data(1, 3);
                    ai3(k, j) = data(1, 4);

                    % Attempted to update data in handles fields, but doesn't seem
                    % to work as hoped(guidata doesn't update until callback
                    % function has completed execution, which is after loops?)
                    handles.data1_matrix_1(k, j) = data(1, 1);  % channel ai0, data value for scan 1
                    handles.data2_matrix_1(k, j) = data(1, 2);  % channel ai1, data value for scan 1
                    handles.data3_matrix_1(k, j) = data(1, 3);  % channel ai2, data value for scan 1
                    handles.data4_matrix_1(k, j) = data(1, 4);  % channel ai3, data value for scan 1

                    % Update values handles in the loop structure (thought it would update the
                    % iteration .mat map data but just gives arrays of zeros)
                    guidata(hObject, handles);

                    pause(0.001)  % is this actually necessary? BB labview was 100 ms maybe. check later

                    % Move stage: 
                    x.SetAbsMovePos(handles.IChanID, handles.x_home + k*handles.x_stepsize);
                    x.MoveAbsolute(handles.IChanID, 1);

                    pause(0.001)  % same here
                    guidata(hObject, handles);
                end

            % Needs to save each whole profile line too!  
            guidata(hObject, handles);

            % Channel ai0 (BNC 1) data:
            ai0_raw_image = handles.data1_matrix_1;
            axes(handles.axes1)
            imshow(ai0_raw_image,[],'border','loose')
            title('Ch. ai0 (BNC 1)')
            colormap('jet')
            colorbar
            iptsetpref('ImshowAxesVisible','on')
        %     caxis([ai0_lower ai0_upper])
            drawnow

            axes(handles.axes3)
            plot(linspace(0, handles.x_points - 1, handles.x_points_plus), handles.data1_matrix_1(:, j))  % profile plot with respect to index j
        %     ylim([ai0_lower ai0_upper])
            xlim([0 handles.x_points-1])
            set(handles.axes3, 'Fontsize', 9);
            xlabel('Distance (pixels)')
            ylabel('Intensity')
            drawnow

            % Channel ai1 (BNC 2) data:
            ai1_raw_image = handles.data2_matrix_1;
            axes(handles.axes5)
            imshow(ai1_raw_image,[],'border','loose')
            title('Ch. ai1 (BNC 2)')
            colormap('jet')
            colorbar
            iptsetpref('ImshowAxesVisible','on')
        %     caxis([ai1_lower ai1_upper])
            drawnow

            axes(handles.axes6)
            plot(linspace(0, handles.x_points - 1, handles.x_points_plus), handles.data2_matrix_1(:, j))
        %     ylim([ai1_lower ai1_upper])
            xlim([0 handles.x_points-1])
            set(handles.axes6, 'Fontsize', 9);
            xlabel('Distance (pixels)')
            ylabel('')
            drawnow

            % Move back to X home:
            x.SetAbsMovePos(handles.IChanID, handles.x_home);
            x.MoveAbsolute(handles.IChanID, 1);

            % Move to next Y position for the Y loop iteration:
            y.SetAbsMovePos(handles.IChanID, handles.y_home + j*handles.y_stepsize);
            y.MoveAbsolute(handles.IChanID, 1);

            % Save .txt file with the most recent map data:
            cd(handles.pathname);
            mkdir('SPCM_txt_files')
            cd('SPCM_txt_files');
    %         SPCM_txt_data = struct
            save([num2str(j) '_ai0_test.txt'],'ai0','-ascii')
            save([num2str(j) '_ai1_test.txt'],'ai1','-ascii')
            save([num2str(j) '_ai2_test.txt'],'ai2','-ascii')
            save([num2str(j) '_ai3_test.txt'],'ai3','-ascii')
            cd ..
        end

        % Move back to Y home:
        y.SetAbsMovePos(handles.IChanID, handles.y_home);
        y.MoveAbsolute(handles.IChanID, 1);

        myString = sprintf(['SPCM scan complete! End time: ' datestr(datetime)]);
                set(handles.Status_display_message_static_text, 'String', myString);

        % Update handles structure
        guidata(hObject, handles);
%     else
%         % Test moving for a row in X direction, acquiring data, and
%         % resampling depending on motor velocity, # data points, and
%         % timestamps:
%         continuous = daq.createSession('ni');
%         addAnalogInputChannel(continuous,'Dev1', [0 1 2 3], 'Voltage');  % [0 1 2] records values from channels ai0, ai1, and ai2 simultaneously
%         % s.Rate = 1;  % change session rate from default 1000 scans/sec to 8000 scans/second
%         continuous.DurationInSeconds = 0.002;  % minimum of 2 scans (for startForeground command; maybe make it record both
%         [data, timeStamps, triggerTime] = continuous.startForeground;
%         
%         % Tinker with motor velocity parameters (related to time, distance,
%         % etc.): 
%         test1 = x.GetStatusBits_Bits(handles.IChanID, 1)
%         % Acquire data during motor movement, using timestamps and motor
%         % velocity (from set accn and vel), convert from signal/time to
%         % signal/distance (bin and average to fit in # of X steps?)
%         
%         myString = sprintf(['Continuous mode chosen.']);
%         set(handles.Status_display_message_static_text, 'String', myString);
%     end
    
else
    myString = sprintf(['SPCM scan will not start. Ensure that the' ...
        ' scan has been initialized after setting up other parameters' ...
        ' (e.g. stage has been homed, an output directory has been chosen, and' ...
        ' all fields in the scan parameters panel include numeric values).']);
    set(handles.Status_display_message_static_text, 'String', myString);
end

clearvars -global -except x* y*  % clears globals except motor information


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Stop_reset_pushbutton.
function Stop_reset_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Stop_reset_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global x y

myString = sprintf(['Stop/Reset functionality has not been implemented yet!']);
set(handles.Status_display_message_static_text, 'String', myString);


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in scan_mode_checkbox1.
function scan_mode_checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to scan_mode_checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of scan_mode_checkbox1

global x y

% Checks the current value of the checkbox:
%   *If checked, value = '1' (continuous scan mode)
%   *If unchecked, value = '0' (step scan mode)

current_checkbox_value = get(handles.scan_mode_checkbox1, 'value');

myString = sprintf(['Scan mode functionality has not been implemented yet!']);
set(handles.Status_display_message_static_text, 'String', myString);

% if current_checkbox_value == 1
%     % Status display message:
%     myString = sprintf(['User has set the scan to ''Continuous scan'' mode.' ...
%         sprintf('\n') 'During the scan, the X-motor will be continuously' ...
%         ' rastered with data acquisition instead of a step/measure/step' ...
%         ' movement.']);
%     set(handles.Status_display_message_static_text, 'String', myString);
%     handles.scan_mode = 1;
%     
%     handles   
% else
%    % Status display message:
%     myString = sprintf(['User has set the scan to ''Step scan'' mode.' ...
%         sprintf('\n') 'During the scan, the X-motor will be stepped,' ...
%         ' paused, and stepped with data acquisition instead of a continuous' ...
%         ' movement.']);
%     set(handles.Status_display_message_static_text, 'String', myString); 
%     handles.scan_mode = 0;
% end

% Update handles structure
guidata(hObject, handles);
