function varargout = KnobAnalysis(varargin)
% KnobAnalysis MATLAB code for KnobAnalysis.fig
%      KnobAnalysis, by itself, creates a new KnobAnalysis or raises the existing
%      singleton*.
%
%      H = KnobAnalysis returns the handle to a new KnobAnalysis or the handle to
%      the existing singleton*.
%
%      KnobAnalysis('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in KnobAnalysis.M with the given input arguments.
%
%      KnobAnalysis('Property','Value',...) creates a new KnobAnalysis or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before KnobAnalysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to KnobAnalysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help KnobAnalysis

% Last Modified by GUIDE v2.5 14-Mar-2016 11:30:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @KnobAnalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @KnobAnalysis_OutputFcn, ...
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

% --- Executes just before KnobAnalysis is made visible.
function KnobAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to KnobAnalysis (see VARARGIN)

% Choose default command line output for KnobAnalysis
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes KnobAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = KnobAnalysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% Single Animal Functions
% --- Executes on button press in Single Animal: Quick Session Info.
function Quick_Stats_2_Callback(hObject, eventdata, handles)
% hObject    handle to Quick_Stats_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    QuickStats
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Single Animal: Detailed Session Info.
function Detailed_Session_Info2_Callback(hObject, eventdata, handles)
% hObject    handle to Detailed_Session_Info2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    DetailedStats
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Single Animal: Raw Waveforms.
function Raw_Waveforms_2_Callback(hObject, eventdata, handles)
% hObject    handle to Raw_Waveforms_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    RawWaveformsGUI
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Single Animal: Peaks Program.
function Peak_Program_Callback(hObject, eventdata, handles)
% hObject    handle to Peak_Program (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    PeaksProgramGUI
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Single Animal: Pre/Post Lesion.
function Pre_Post_Lesion_Single_Callback(hObject, eventdata, handles)
% hObject    handle to Pre_Post_Lesion_Single (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    Knob_Analysis_Viewer_V3
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Single Animal: Progress Tracker.
function Progress_Tracker_Single_Animal_Callback(hObject, eventdata, handles)
% hObject    handle to Progress_Tracker_Single_Animal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    Multi_Animal_Progress_Tracker_V1
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

%% Multi Animal Programs
% --- Executes on button press in Multiple Animals: Compare Animals.
function Compare_Each_Animal_Callback(hObject, eventdata, handles)
% hObject    handle to Compare_Each_Animal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    Compare_Each_Animal_V1
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Multiple Animals: Analyze Group.
function Compare_Animals_Callback(hObject, eventdata, handles)
% hObject    handle to Compare_Animals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    Compare_Animals_V1
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Multiple Animals: Pre/Post Lesion.
function Pre_Post_Lesion_Callback(hObject, eventdata, handles)
% hObject    handle to Pre_Post_Lesion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    Knob_Analysis_Viewer_V3
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

% --- Executes on button press in Multiple Animals: Progress Tracker.
function Multi_Animal_Progress_Tracker_Callback(hObject, eventdata, handles)
% hObject    handle to Multi_Animal_Progress_Tracker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'watch')
try
    Multi_Animal_Progress_Tracker_V1
catch ME
    set(handles.figure1, 'pointer', 'arrow')
end
% toc;
% if toc <5
%     msgbox('Analysis Incomplete!', 'No Analysis');
% else 
%     msgbox('Analysis Complete!', 'Success');
% end
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);


%% Reset pointer
% --- Executes on button press in Reset_Pointer.
function Reset_Pointer_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_Pointer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'pointer', 'arrow')
guidata(hObject, handles);

%% Knob Peak Finder - required for data extraction algorithms
function [pks, sig] = Knob_Peak_Finder(signal)
%This code finds and kicks out peaks that have a std dev between
%them less than 1

smoothed_signal = boxsmooth(signal);                                        %smooth out the trial signal
[pks, sig] = findpeaks(smoothed_signal, 'MINPEAKHEIGHT', 5, ...
    'MINPEAKDISTANCE', 10);                                            %Find local maximma
n = length(pks);
j = 1;
if n>1
    while j <= n-1
        if (abs(pks(j)-pks(j+1)) <= 5)                                 % if the diff between 2 peaks is less than or equal to 5
            start_sig = sig(j);
            end_sig = sig(j+1);
            
            signal_interest = smoothed_signal(start_sig:end_sig);
            deviation_signal = std(signal_interest);
            
            if deviation_signal < 1
                pks(j+1) = [];
                sig(j+1) = [];
                j = j-1;
            end
            
        end
        n = length(pks);
        j = j+1;
    end
end
