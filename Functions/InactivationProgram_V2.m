function InactivationProgram_V2(varargin)
valid = 0;
temp = inputdlg('Number of animals to analyze');
while valid < 1
    num_animals = str2num(temp{1});
    if isempty(num_animals) == 0
        valid = 1;
    else
        temp = inputdlg('Not a valid number');
    end
end

handles.num_animals = num_animals;                                          %Store number of animals in the handles structure
a = 1;

while a <= handles.num_animals
    [temp_pre_files pre_path] = uigetfile('*.ArdyMotor', ... 
        ['Select Animal ' num2str(a) ' Pre Lesion data'], ...
        'multiselect','on');                                                %Have the user pick an input *.ArdyMotor file or pre_files.
    if ~iscell(temp_pre_files) && temp_pre_files(1) == 0                              %If no file was selected...
        return                                                              %Exit the function.
    end
    cd(pre_path);                                                           %Change the current directory to the specified folder.
    if ischar(temp_pre_files)                                                    %If only one file was selected...
        temp_pre_files = {temp_pre_files};                                            %Convert the string to a cell array.
    end
    temp = ArdyMotorFileRead(temp_pre_files{1});
    animal_pre = temp.rat;
    
    %This code sorts the files by daycode in ardymotor function
    num_sessions = length(temp_pre_files);
    for f = 1:num_sessions
        data = ArdyMotorFileRead(temp_pre_files{f});
        pre_daycodes(f) = data.daycode;
    end
    [B,IX] = sort(pre_daycodes);
    for f = 1:num_sessions
        pre_files(f) = temp_pre_files(IX(f));
    end
    
    handles.(animal_pre).pre.files = pre_files;                             %Store the pre_files 
    handles.(animal_pre).pre.path = pre_path;

    [temp_post_files post_path] = uigetfile('*.ArdyMotor', ... 
        ['Select Animal ' num2str(a) ' Post Lesion data'], ...
        'multiselect','on');                                                %Have the user pick an input *.ArdyMotor file or pre_files.
    if ~iscell(temp_post_files) && temp_post_files(1) == 0                                       %If no file was selected...
        return                                                              %Exit the function.
    end
    cd(post_path);                                                               %Change the current directory to the specified folder.
    if ischar(temp_post_files)                                                        %If only one file was selected...
        temp_post_files = {temp_post_files};                                                    %Convert the string to a cell array.
    end
    
    temp = ArdyMotorFileRead(temp_post_files{1});
    animal_post = temp.rat;
    
    if strcmpi(animal_pre, animal_post) == 0
        errordlg('Different animal in pre and post data');
    else
        
        %This code sorts the files by daycode in ardymotor function
        num_sessions = length(temp_post_files);
        for f = 1:num_sessions
            data = ArdyMotorFileRead(temp_post_files{f});
            post_daycodes(f) = data.daycode;
        end
        [B,IX] = sort(post_daycodes);
        for f = 1:num_sessions
            post_files(f) = temp_post_files(IX(f));
        end
        
        handles.(animal_post).post.files = post_files;
        handles.(animal_post).post.path = post_path;
        handles.animals{a} = animal_post;
        
        a = a+1;
    end
end



for k = 1:num_animals
    animal = handles.animals{k};

    %% Do pre-lesion file processing
    handles.(animal).pre.data = TransformKnobData( ... 
        handles.(animal).pre.files, handles.(animal).pre.path);
    handles.(animal).pre.trialdata = TransformTrialData( ...
        handles.(animal).pre.files, handles.(animal).pre.path);

    %% Do post-lesion file processing
    handles.(animal).post.data = TransformKnobData( ... 
        handles.(animal).post.files, handles.(animal).post.path);
    handles.(animal).post.trialdata = TransformTrialData( ...
        handles.(animal).post.files, handles.(animal).post.path);

end
%% Set up axes for plotting
handles.analysis = 'data';



handles = Make_GUI(handles);
set(handles.animal_list, 'string', handles.animals);
handles.cur_animal = handles.animals{1};

sessions_pre = 1:handles.(handles.cur_animal).pre.data.num_sessions;
sessions_post = 1:handles.(handles.cur_animal).post.data.num_sessions;

set(handles.session_list_pre, 'string', sessions_pre);
set(handles.session_list_post, 'string', sessions_post);

set(handles.total_mean_distance, 'callback', @MeanDistance);
set(handles.latency_to_hit, 'callback', @LatencyToHit);
set(handles.peak_velocity, 'callback', @PeakVelocity);
set(handles.peak_acceleration, 'callback', @PeakAcceleration);
set(handles.num_turns, 'callback', @NumberOfTurns);
set(handles.mean_turn_distance, 'callback', @MeanTurnDistance);
set(handles.animal_list, 'callback', @AnimalSelect);
set(handles.trial_viewer, 'callback', @TrialViewer);
set(handles.session_list_pre, 'callback', @SessionSelectPre);
set(handles.session_list_post, 'callback', @SessionSelectPost);
% set(handles.savebutton, 'callback', @SavePlot);

guidata(handles.fig,handles);




%% This sub function plots data
function PlotData(handles,preorpost,parameter,cur_animal)

%Plot the trial data in a scatter plot
scatter(1:sum(handles.(handles.cur_animal).(preorpost).data.sessions), ... 
    handles.(cur_animal).(preorpost).data.(parameter).sessionscombined, ...
    'parent', handles.(preorpost).axes); 

%Calculate y axis limits
y_limit = max(max(max(handles.(cur_animal).pre.data.(parameter).sessionscombined)), ... 
    max(max(handles.(cur_animal).post.data.(parameter).sessionscombined)));
set(handles.pre.axes, 'Ylim', [0 y_limit]);
set(handles.post.axes, 'Ylim', [0 y_limit]);

%Calculate x axis limits
x_limit = 1.01*sum(handles.(cur_animal).(preorpost).data.sessions);
set(handles.(preorpost).axes, 'Xlim',[0 x_limit]);                          %Set Xlimit to 1% larger than max
     


%Plot the line for the total mean of all sessions
line(get(handles.(preorpost).axes, 'Xlim'), ... 
    [handles.(cur_animal).(preorpost).data.(parameter).combinedmean ...
    handles.(cur_animal).(preorpost).data.(parameter).combinedmean], ...
    'color', 'g', 'linewidth', 4, 'linestyle', '--', ...
    'parent', handles.(preorpost).axes);

%Plot the threshold lines if plotting mean distance
if (strcmpi((parameter), 'mean_distance') == 1)
    line(1:length(handles.(cur_animal).(preorpost).data.threshold.sessionscombined), ...
        handles.(cur_animal).(preorpost).data.threshold.sessionscombined, ... 
        'color', 'm', 'linewidth', 3, 'linestyle', '--', 'parent', ... 
        handles.(preorpost).axes);
end

%Plot the lines for session means
prev_sessions = 1;
for f = 1:length(handles.(handles.cur_animal).(preorpost).files)
    line([prev_sessions (handles.(cur_animal).(preorpost).data.sessions(f)+prev_sessions-1)], ...
        [handles.(cur_animal).(preorpost).data.(parameter).sessionmeans(f,1) ... 
        handles.(cur_animal).(preorpost).data.(parameter).sessionmeans(f,1)], 'Color', ...
        'k', 'linewidth', 2.5, 'parent', ...
        handles.(preorpost).axes);
    prev_sessions = handles.(cur_animal).(preorpost).data.sessions(f) + prev_sessions;
end

prev_session_marker = 0;
session_marker = 0;                                                            
for d = 1:length(handles.(cur_animal).(preorpost).data.sessions)
    %Keep track of where each session begins
    session_marker = session_marker + handles.(cur_animal).(preorpost).data.sessions(d);
    
    %Draw a line to mark end of session
    line([session_marker session_marker],[0 y_limit],'color','r','linestyle','--', ... 
        'linewidth',1, 'parent', handles.(preorpost).axes);  
    
    %Label session line
    text(session_marker,0.9*y_limit, ... 
    ['Session ' num2str(d)],'margin',2,'edgecolor','k',...
    'backgroundcolor','w','rotation',90, 'fontsize',6,...
    'horizontalalignment','center','verticalalignment','middle', ...
    'parent', handles.(preorpost).axes); 
    
    if (length(handles.(cur_animal).(preorpost).data.sessions) < 6)
        text(((session_marker - prev_session_marker)/2)+prev_session_marker,y_limit, ... 
        ['Session Mean: ' num2str(handles.(cur_animal).(preorpost).data.(parameter).sessionmeans(d,1))], ...
        'margin',2,'edgecolor','k',...
        'backgroundcolor',[.7 .9 .7], 'fontsize',7,...
        'horizontalalignment','center','verticalalignment','middle', ...
        'parent', handles.(preorpost).axes); 
    elseif (length(handles.(cur_animal).(preorpost).data.sessions) < 11)
        text(((session_marker - prev_session_marker)/2)+prev_session_marker,y_limit, ... 
        [num2str(handles.(cur_animal).(preorpost).data.(parameter).sessionmeans(d,1))], ...
        'margin',2,'edgecolor','k',...
        'backgroundcolor',[.7 .9 .7], 'fontsize',7,...
        'horizontalalignment','center','verticalalignment','middle', ...
        'parent', handles.(preorpost).axes);
    
    end 
    prev_session_marker = session_marker;
end

switch preorpost
    case 'pre'
        Title_label = 'Pre';
    case 'post'
        Title_label = 'Post';
end

switch parameter
    case 'mean_distance'
        title_text = [cur_animal ' ' Title_label ' Lesion: Max Distance Turned'];
        y_label = 'Degrees';        
    case 'latency_to_hit'
        title_text = [cur_animal ' ' Title_label ' Lesion: Latency To Hit'];
        y_label = 'Time (ms)';
    case 'peak_velocity'
        title_text = [cur_animal ' ' Title_label ' Lesion: Peak Velocity'];
        y_label = 'Velocity (deg/10ms)';
    case 'peak_acceleration'
        title_text = [cur_animal ' ' Title_label ' Lesion: Peak Acceleration'];
        y_label = 'Acceleration (deg/10ms^2)';
    case 'num_turns'
        title_text = [cur_animal ' ' Title_label ' Lesion: Number of Turns'];
        y_label = 'Turns';
    case 'mean_turn_distance'
        title_text = [cur_animal ' ' Title_label ' Lesion: Mean Turn Distance'];
        y_label = 'Degrees';

end

title(title_text, 'FontWeight', 'bold', ... 
    'FontSize', 20, 'parent', handles.(preorpost).axes);
xlabel('Trials', 'parent', handles.(preorpost).axes, 'FontWeight', 'bold', ...
    'FontSize', 14);
ylabel(y_label, 'FontWeight', 'bold', 'parent', ... 
    handles.(preorpost).axes, 'FontSize', 14);

text(x_limit, 1.03*y_limit, ...
    ['Total Mean: ' num2str(handles.(cur_animal).(preorpost).data.(parameter).combinedmean)], ...
    'fontsize', 14, 'FontWeight', 'bold', ...
    'horizontalalignment', 'right', 'verticalalignment', 'bottom', ...
    'parent', handles.(preorpost).axes);

%This function plots the trial data
function PlotTrial(handles, preorpost)

cla(handles.(preorpost).trial_axes);

trial_start = 100;
trial_end = 300;

s_pre = handles.(handles.cur_animal).pre.session_select;
s_post = handles.(handles.cur_animal).post.session_select;


handles.pre.max_signal = max(handles.(handles.cur_animal).pre.trialdata.mean_plot(s_pre,:));
handles.post.max_signal = max(handles.(handles.cur_animal).post.trialdata.mean_plot(s_post,:));
max_signal = max(handles.pre.max_signal, handles.post.max_signal);

y_max = 1.2*max_signal;


y_min = -(0.025*y_max);
s = handles.(handles.cur_animal).(preorpost).session_select;

%Plot confidence interval fill
fill([1:500,500:-1:1], ... 
    [handles.(handles.cur_animal).(preorpost).trialdata.upper(s,:), ... 
    fliplr(handles.(handles.cur_animal).(preorpost).trialdata.lower(s,:))], ... 
    [0 0.5 0], 'parent', handles.(preorpost).trial_axes);
hold on;

%plot mean data line
line((1:500),handles.(handles.cur_animal).(preorpost).trialdata.mean_plot(s,:), ... 
    'Color', 'k', 'linewidth', 2, 'parent', handles.(preorpost).trial_axes);
hold on;

%Plot max pre signal line
line([0 500], [handles.pre.max_signal handles.pre.max_signal], ...
    'parent', handles.(preorpost).trial_axes, 'linestyle', '--', 'color', 'b');
%Label max pre signal line
text(450, handles.pre.max_signal, ['Pre Max: ' num2str(handles.pre.max_signal)], 'parent', ...
    handles.(preorpost).trial_axes, 'horizontalalignment','center','verticalalignment','middle', ...
    'margin',2,'edgecolor','k',...
    'backgroundcolor','w', 'fontsize',8, 'FontWeight', 'bold');

%Plot max post signal line
line([0 500], [handles.post.max_signal handles.post.max_signal], ...
    'parent', handles.(preorpost).trial_axes, 'linestyle', '--', 'color', [1 0.4 0.7]);
%Label max post signal line
text(450, handles.post.max_signal, ['Post Max: ' num2str(handles.post.max_signal)], 'parent', ...
    handles.(preorpost).trial_axes, 'horizontalalignment','center','verticalalignment','middle', ...
    'margin',2,'edgecolor','k',...
    'backgroundcolor','w', 'fontsize',8,'FontWeight', 'bold');


%Plot x axis line 
line([0 500], [0 0], 'linewidth', 2, 'parent', handles.(preorpost).trial_axes, ...
    'color', 'k');

%plot hit window start line
line([trial_start trial_start], [0 y_max], 'parent', handles.(preorpost).trial_axes, ...
    'Color', 'k', 'linestyle', '--', 'linewidth', 1);

%Plot hit window end line
line([trial_end trial_end], [0 y_max], 'parent', handles.(preorpost).trial_axes, ...
    'Color', 'k', 'linestyle', '--', 'linewidth', 1);

%plot Hit Window line up top
line([trial_start trial_end], [0.95*y_max 0.95*y_max], 'parent', handles.(preorpost).trial_axes, ...
    'Color', 'k', 'linestyle', '--', 'linewidth', 1);

%Plot hit window text box
text(trial_end - trial_start,0.95*y_max, ... 
    'Hit Window','margin',2,'edgecolor','k',...
    'backgroundcolor','w', 'fontsize',10,...
    'horizontalalignment','center','verticalalignment','middle', ...
    'parent', handles.(preorpost).trial_axes, 'FontWeight', 'bold'); 

%Label axes

if (strcmpi(preorpost, 'pre'))
    title_label = 'Pre';
else
    title_label = 'Post';
end

title([handles.cur_animal ' ' title_label ' Lesion: Mean Trial with 95% Confidence Interval'], ...
    'parent', handles.(preorpost).trial_axes, 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Degrees', 'parent', handles.(preorpost).trial_axes, 'FontWeight', 'bold', ...
    'FontSize', 12);
xlabel('Time (10ms)', 'parent', handles.(preorpost).trial_axes, 'FontWeight', 'bold');



random_trials = sort(round(rand(1,9)*handles.(handles.cur_animal).(preorpost).trialdata.session_length(s)));
if (random_trials(1) == 0)
    random_trials(1) = 1;
end

for i = 1:9
    cla(handles.(preorpost).sub_axes(i), 'reset');
    area(1:500, handles.(handles.cur_animal).(preorpost).trialdata.trial((random_trials(i)), :, s), ...
        'linewidth', 2,'facecolor',[0.5 0.5 1], 'parent', handles.(preorpost).sub_axes(i));

    text(425, max_signal, ['Trial ' num2str(random_trials(i))], 'parent', ...
    handles.(preorpost).sub_axes(i), 'horizontalalignment','center','verticalalignment','middle', ...
    'margin',2,'edgecolor','k',...
    'backgroundcolor','w', 'fontsize',8,'FontWeight', 'bold');

    set(handles.(preorpost).sub_axes(i), 'Ylim', [y_min y_max], 'Xlim', [0 500]);
    
    %plot hit window start line
    line([trial_start trial_start], [0 y_max], 'parent', handles.(preorpost).sub_axes(i), ...
        'Color', 'k', 'linestyle', '--', 'linewidth', 1);

    %Plot hit window end line
    line([trial_end trial_end], [0 y_max], 'parent', handles.(preorpost).sub_axes(i), ...
        'Color', 'k', 'linestyle', '--', 'linewidth', 1);

end

set(handles.(preorpost).trial_axes, 'Ylim', [y_min y_max], 'Xlim', [0 500]);
    

%% This function is called when MeanDistance button is pushed
function MeanDistance(hObject,~)
handles = guidata(hObject);
if ~strcmpi(handles.analysis, 'data')
    handles.analysis = 'data';
    Axes_Select(handles);
end
guidata(handles.fig,handles);
PlotData(handles, 'pre', 'mean_distance', handles.cur_animal);
PlotData(handles,'post','mean_distance', handles.cur_animal);
guidata(handles.fig, handles);

%% This function is called when LatencyToHit button is pushed
function LatencyToHit(hObject,~)
handles = guidata(hObject);
if ~strcmpi(handles.analysis, 'data')
    handles.analysis = 'data';
    Axes_Select(handles);
end
guidata(handles.fig,handles);

guidata(handles.fig,handles);
PlotData(handles, 'pre', 'latency_to_hit', handles.cur_animal);
PlotData(handles,'post','latency_to_hit', handles.cur_animal);

%% This function is called when PeakVelocity button is pushed
function PeakVelocity(hObject,~)
handles = guidata(hObject);
if ~strcmpi(handles.analysis, 'data')
    handles.analysis = 'data';
    Axes_Select(handles);
end
guidata(handles.fig,handles);

PlotData(handles, 'pre', 'peak_velocity', handles.cur_animal);
PlotData(handles,'post','peak_velocity', handles.cur_animal);

%% This function is called when PeakAcceleration button is pushed
function PeakAcceleration(hObject,~)
handles = guidata(hObject);
if ~strcmpi(handles.analysis, 'data')
    handles.analysis = 'data';
    Axes_Select(handles);
end
guidata(handles.fig,handles);

PlotData(handles, 'pre', 'peak_acceleration', handles.cur_animal);
PlotData(handles,'post','peak_acceleration', handles.cur_animal);
guidata(handles.fig,handles);

%% This function is called when NumberOfTurns button is pushed
function NumberOfTurns(hObject,~)
handles = guidata(hObject);
if ~strcmpi(handles.analysis, 'data')
    handles.analysis = 'data';
    Axes_Select(handles);
end
guidata(handles.fig,handles);

PlotData(handles, 'pre', 'num_turns', handles.cur_animal);
PlotData(handles,'post','num_turns', handles.cur_animal);
guidata(handles.fig,handles);

%% This function is called when MeanTurnDistance button is pushed
function MeanTurnDistance(hObject,~)
handles = guidata(hObject);
if ~strcmpi(handles.analysis, 'data')
    handles.analysis = 'data';
    Axes_Select(handles);
end
guidata(handles.fig,handles);

PlotData(handles, 'pre', 'mean_turn_distance', handles.cur_animal);
PlotData(handles,'post','mean_turn_distance', handles.cur_animal);
guidata(handles.fig,handles);

%% This function is called when rat list drop down is manipulated
function AnimalSelect(hObject, ~)
handles = guidata(hObject);
sel = get(handles.animal_list, 'Value');
animal_list = get(handles.animal_list, 'string');
handles.cur_animal = animal_list{sel};

sessions_pre = 1:handles.(handles.cur_animal).pre.data.num_sessions;
sessions_post = 1:handles.(handles.cur_animal).post.data.num_sessions;



set(handles.session_list_pre, 'string', sessions_pre);
set(handles.session_list_post, 'string', sessions_post);

guidata(handles.fig,handles);

function SessionSelectPre(hObject, ~)
handles = guidata(hObject);
sel = get(handles.session_list_pre, 'Value');
handles.(handles.cur_animal).pre.session_select = sel;
guidata(handles.fig,handles);
PlotTrial(handles,'pre');
PlotTrial(handles,'post');

function SessionSelectPost(hObject, ~)
handles = guidata(hObject);
sel = get(handles.session_list_post, 'Value');
handles.(handles.cur_animal).post.session_select = sel;
guidata(handles.fig, handles);
PlotTrial(handles,'pre');
PlotTrial(handles,'post');

function TrialViewer(hObject, ~)
handles = guidata(hObject);

handles.(handles.cur_animal).pre.session_select = 1;
handles.(handles.cur_animal).post.session_select = 1;

if ~strcmpi(handles.analysis, 'trial')
    handles.analysis = 'trial';
    guidata(handles.fig,handles);
    Axes_Select(handles);
end

%Clear the trial axes
cla(handles.pre.trial_axes, 'reset');
cla(handles.post.trial_axes, 'reset');

%Clear all the sub axes
for i = 1:9
    cla(handles.pre.sub_axes(i), 'reset');
    cla(handles.post.sub_axes(i), 'reset');
end
    

PlotTrial(handles, 'pre');
PlotTrial(handles, 'post');


% axes(handles.pre.axes);

guidata(handles.fig, handles);

%% Make GUI function
function handles = Make_GUI(handles)
set(0,'units','centimeters');
pos = get(0,'screensize');  
h = 0.8*pos(4);
w = 4*h/3;  

handles.fig = figure( 'numbertitle','off',...
    'name','Knob Trial Pre Post Viewer',...
    'units','centimeters', 'Toolbar', 'figure',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);                         %Create a figure.
handles.label =  uicontrol(handles.fig,'style','text',...
    'units','normalized',...
    'position',[0.01,0.95,0.98,0.04],...
    'string','Parameter:',...
    'fontsize',0.7*h,...
    'backgroundcolor',get(handles.fig,'color'),...
    'horizontalalignment','left',...
    'fontweight','bold');                                                   %Create a text label for showing the trial number and time.

handles.pre.axes = axes('units','normalized',...
    'position',[0.05,0.525,0.925,0.375],...
    'box','on',...
    'linewidth',2, 'Visible', 'on');                                                         %Create axes for showing the IR signal.
handles.post.axes = axes('units','normalized',...
    'position',[0.05,0.05,0.925,0.375],...
    'box','on',...
    'linewidth',2, 'Visible', 'on');    

handles.pre.trial_axes = axes('units','normalized',...
    'position',[0.05,0.5,0.925/2,0.375],...
    'box','on',...
    'linewidth',2, 'Visible', 'off');  

handles.post.trial_axes = axes('units','normalized',...
    'position',[0.05,0.05,0.925/2,0.375],...
    'box','on',...
    'linewidth',2, 'Visible', 'off'); 

handles.pre.sub_axes = nan(1,9);
handles.post.sub_axes = nan(1,9);

positions = [0.55, 0.7, 0.85; 0.775, 0.6375, 0.5; 0.325, 0.1875, 0.05];

j = 1;
k = 1;
for i = 1:9
    handles.pre.sub_axes(i) = axes('units','normalized',...
    'position',[positions(1,j),positions(2,k),0.125,0.1],...
    'box','on',...
    'linewidth',2, 'Visible', 'off');  


    handles.post.sub_axes(i) = axes('units','normalized',...
    'position',[positions(1,j),positions(3,k),0.125,0.1],...
    'box','on',...
    'linewidth',2, 'Visible', 'off');  


    if i == 3 || i == 6
        j = 0;
        k = k+1;
    end
    j = j+1;
    
end
    
handles.total_mean_distance = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.125,0.95,0.15,0.04],...
    'string','Mean Distance',...
    'fontsize',0.75*h);                                                     %Create a button for saving a plot image.
handles.latency_to_hit = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.285,0.95,0.125,0.04],...
    'string','Hit Latency',...
    'fontsize',0.75*h);                                                     %Create a button for saving a plot image.
handles.peak_velocity = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.42,0.95,0.15,0.04],...
    'string','Peak Velocity',...
    'fontsize',0.75*h);                                                     %Create a button for saving a plot image.
handles.peak_acceleration = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.58,0.95,0.125,0.04],...
    'string','Peak Accel',...
    'fontsize',0.75*h);                                                     %Create a button for saving a plot image.
handles.num_turns = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.715,0.95,0.125,0.04],...
    'string','# of Turns',...
    'fontsize',0.75*h);                                                     %Create a button for saving a plot image.
handles.mean_turn_distance = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.85,0.95,0.125,0.04],...
    'string','Turn Distance',...
    'fontsize',0.75*h);                                                     %Create a button for saving a plot image.

handles.animal_label =  uicontrol(handles.fig,'style','text',...
    'units','normalized',...
    'position',[0.01,0.9,0.1,0.04],...
    'string','Animal:',...
    'fontsize',0.7*h,...
    'backgroundcolor',get(handles.fig,'color'),...
    'horizontalalignment','left',...
    'fontweight','bold');                                                   %Create a text label for showing the trial number and time.

handles.animal_list = uicontrol(handles.fig, 'Style', 'popupmenu', ...
    'String', '-', 'units', 'normalized', 'enable', 'on', ...
    'Position', [0.0825 0.9 0.04 0.04], 'Value', 1);
handles.trial_viewer = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'position',[0.125,0.915,0.1,0.03],...
    'string','Trial Viewer',...
    'fontsize',0.6*h); 

handles.session_label_pre =  uicontrol(handles.fig,'style','text',...
    'units','normalized',...
    'position',[0.25,0.91,0.1,0.03],...
    'string','Session:',...
    'fontsize',0.7*h,...
    'backgroundcolor',get(handles.fig,'color'),...
    'horizontalalignment','left',...
    'fontweight','bold', 'Visible', 'off');                                                   %Create a text label for showing the trial number and time.g

handles.session_list_pre = uicontrol(handles.fig, 'Style', 'popupmenu', ...
    'String', '-', 'units', 'normalized', 'enable', 'on', ...
    'Position', [0.325 0.91 0.04 0.03], 'Value', 1, 'Visible', 'off');


handles.session_label_post =  uicontrol(handles.fig,'style','text',...
    'units','normalized',...
    'position',[0.5,0.91,0.1,0.03],...
    'string','Session:',...
    'fontsize',0.7*h,...
    'backgroundcolor',get(handles.fig,'color'),...
    'horizontalalignment','left',...
    'fontweight','bold', 'Visible', 'off');                                                   %Create a text label for showing the trial number and time.g

handles.session_list_post = uicontrol(handles.fig, 'Style', 'popupmenu', ...
    'String', '-', 'units', 'normalized', 'enable', 'on', ...
    'Position', [0.6 0.91 0.04 0.03], 'Value', 1, 'Visible', 'off');
%% This function is called whenever the main figure is resized
function Resize(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
pos = get(handles.fig,'position');                                          %Grab the main figure position.
% ylabel('Test','parent',handles.pre.axes,'fontsize',0.75*pos(4),...
%     'rotation',0,'verticalalignment','middle',...
%     'horizontalalignment','right');                                    
% ylabel('TestPost','parent',handles.post.axes,'fontsize',0.75*pos(4),...
%     'rotation',0,'verticalalignment','middle',...
%     'horizontalalignment','right');     

set([handles.label,handles.savebutton],'fontsize',0.75*pos(4));             %Update the trial label and savebutton fontsize.

objs_pre = get(handles.pre.axes,'children');                                  %Grab all children of the force axes.
objs_post = get(handles.post.axes,'children');

% objs_pre(~strcmpi('text',get(objs_pre,'type'))) = [];                               %Kick out all non-text objects.
% objs_post(~strcmpi('text',get(objs_post,'type'))) = [];                               %Kick out all non-text objects.


set(objs_pre,'fontsize',0.5*pos(4));                                            %Update the fontsize of all text objects.
set(objs_post, 'fontsize', 0.5*post(4));

ylabel('TestPre)','parent',handles.pre.axes,'fontsize',0.75*pos(4));     %Label the force signal.
xlabel('Trial','parent',handles.pre.axes,'fontsize',0.75*pos(4));     %Label the time axis.

ylabel('TestPost','parent',handles.post.axes,'fontsize',0.75*pos(4));     %Label the force signal.
xlabel('Trial','parent',handles.post.axes,'fontsize',0.75*pos(4));     %Label the time axis.

%% This subfunction finds peaks in the signal, accounting for equality of contiguous samples.
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

function [data, varargout] = ArdyMotorFileRead(file)
%
%ARDYMOTORFILEREAD.m - Rennaker Neural Engineering Lab, 2011
%
%   ArdyMotorFileRead reads in the sensor recordings from motor behavioral
%   tasks controlled by an Arduino board.  The data is organized into a
%   MATLAB structure for easy analysis
%
%   data = ArdyMotorFileRead(file) reads in the behavioral record from the
%   *.ARDYMOTOR files specified by the string variable "file" into the
%   output "data" structure.
%
%   Last modified February 18, 2013, by Drew Sloan.

data = [];                                                                  %Start a data structure to receive the recordings.
fid = fopen(file,'r');                                                      %Open the file for read access.
fseek(fid,0,-1);                                                            %Rewind to the beginning of the file.

temp = dir(file);                                                           %Grab the file information.
% if temp.datenum >= 735264                                                   %If the file was created after January 29, 2013...
%     version = fread(fid,1,'int16');                                         %Read the version from the first two bytes as an signed integer.
%     if version > 0                                                          %If the integer is greater than zero...
%         version = 1;                                                        %Set the file format version to 1.
%     end
% else
    version = fread(fid,1,'int8');                                          %Read the file format version from the first byte as a signed integer.
    if (version ~= -1) || (version == -1 && daycode(temp.datenum) == 255)     %If the version isn't -1...
        if (version ~= -3)
            version = 1;                                                        %Set the file format version to 1.
        end
    end
% end

data.version = version;

if version < 0                                                              %If the file format version indicates ArdyMotor V2.0...
    
    if version == -1 || version == -3
        data.daycode = fread(fid,1,'uint16');                               %Read in the daycode.
    end
    data.booth = fread(fid,1,'uint8');                                      %Read in the booth number.
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the rat's name.
    data.rat = fread(fid,N,'*char')';                                       %Read in the characters of the rat's name.
    data.position = fread(fid,1,'float32');                                 %Read in the device position, in centimeters.
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the stage description.
    data.stage = fread(fid,N,'*char')';                                     %Read in the characters of the stage description.
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the device name.
    data.device = fread(fid,N,'*char')';                                    %Read in the characters of the device name.
    fileinfo = dir(file);                                                   %Grab the input file information.
    
    data.cal = [1,0];                                                       %Assume by default that no calibration conversion was applied.
    if fileinfo.datenum < 735088                                            %If this file was written between 8/3/2012 and 8/6/2012
        data.device = 'Wheel';                                              %Set the device name to 'Wheel'.
        data.cal(1) = 0.5;                                                  %Set the degrees/tick calibration constant to 0.5.
    end
      
    if (version == -3)
        if any(strcmpi(data.device,{'pull', 'knob', 'lever'}))
            data.cal(:) = fread(fid,2,'float32');
        elseif any(strcmpi(data.device,{'wheel'}))
            data.cal(1) = fread(fid,1,'float32');                              
        end
    else      
        if any(strcmpi(data.device,{'pull'}))                                   %If the device was a pull...
            data.cal(:) = fread(fid,2,'float32');                               %Read in the grams/tick and baseline grams calibration coefficients.
        elseif any(strcmpi(data.device,{'wheel','knob'})) && ...
                fileinfo.datenum > 735088                                       %If the device was a wheel or a knob...
            data.cal(1) = fread(fid,1,'float32');                               %Read in the degrees/tick calibration coefficient.
        end
    end
    
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the constraint description.
    data.constraint = fread(fid,N,'*char')';                                %Read in the characters of the constraint description.
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the threshold type description.
    data.threshtype = fread(fid,N,'*char')';                                %Read in the characters of the threshold type  description.
    if version == -1 || version == -3                                       %If the file format version is -1...
        data.pre_trial_sampling_dur = 1000;                                 %Indicate 1000 milliseconds of pre-trial sampling.
    else                                                                    %Otherwise, for later versions...
        data.pre_trial_sampling_dur = fread(fid,1,'float32');               %Read in the pre-trial sampling duration (in milliseconds).
    end
    data.pauses = [];                                                       %Create a field in the data structure to hold pause times.
    data.manual_feeds = [];                                                 %Create a field in the data structure to hold manual feed times.
    while ~feof(fid)                                                        %Loop until the end of the file.
        trial = fread(fid,1,'uint32');                                      %Read in the trial number.
        if isempty(trial)                                                   %If no trial number was read...
            continue                                                        %Skip execution of the rest of the loop.
        end
        starttime = fread(fid,1,'float64');                                 %Read in the trial start time.
        outcome = fread(fid,1,'uint8');                                     %Read in the trial outcome.
        if outcome == 'P'                                                   %If the outcome was a pause...
            temp = fread(fid,1,'float64');                                  %Read in the end time of the pause.
            data.pauses(end+1,1:2) = [starttime, temp];                     %Save the start and end time of the pause.
        elseif outcome == 'F'                                               %If the outcome was a manual feeding.
            data.manual_feeds(end+1,1) = starttime;                         %Save the timing of the manual feeding.
        else                                                                %Otherwise, if the outcome was a hit or a miss...
            if fileinfo.datenum < 735122.5980                               %If a file was created before 9/10/2012...
                fseek(fid,-1,'cof');                                        %Rewind the file one byte.
            end

            data.trial(trial).starttime = starttime;                        %Save the trial start time.
            data.trial(trial).hitwin = fread(fid,1,'float32');              %Read in the hit window.
            data.trial(trial).init = fread(fid,1,'float32');                %Read in the initiation threshold.
            data.trial(trial).thresh = fread(fid,1,'float32');              %Read in the hit threshold.
            data.trial(trial).hittime = [];                                 %List no hit times for this trial by default.
            N = fread(fid,1,'uint8');                                       %Read in the number of hits for this trial.
            data.trial(trial).hittime = fread(fid,N,'float64');             %Read in the hit times for this trial.
            if fileinfo.datenum <  735122.5980                              %If a file was created before 9/10/2012...
                if N > 1                                                    %If there was at least one hit time...
                    outcome = 'H';                                          %Label the trial as a hit.
                else                                                        %Otherwise...
                    outcome = 'M';                                          %Label the trial as a miss.
                end
            end
            data.trial(trial).outcome = outcome;                            %Save the trial outcome.
            N = fread(fid,1,'uint8');                                       %Read in the number of VNS events for this trial.
            data.trial(trial).vnstime = fread(fid,N,'float64');             %Read in the VNS event times for this trial.
            buffsize = fread(fid,1,'uint32');                               %Read in the number of samples for this trial.
            data.trial(trial).sample_times = ...
                fread(fid,buffsize,'uint16');                               %Read in the sample times, in milliseconds.
            data.trial(trial).signal = fread(fid,buffsize,'float32');       %Read in the device signal.
            data.trial(trial).ir = fread(fid,buffsize,'int16');             %Read in the IR signal.
            if all(data.trial(trial).sample_times == 0)                     %If all of the sample times equal zero...
                if trial ~= 1                                               %If this isn't the first trial...
                    data.trial(trial).sample_times = ...
                        data.trial(trial-1).sample_times;                   %Use the previous trial's sample times.
                else                                                        %Otherwise...
                    data.trial(trial).sample_times = ...
                        int16(10*(1:length(data.trial(trial).signal)) - ...
                        data.pre_trial_sampling_dur)';                      %Subtract the pre-trial sampling duration from the sample times.
                end
            else                                                            %Otherwise...
                data.trial(trial).sample_times = ...
                    int16(data.trial(trial).sample_times) - ...
                    data.pre_trial_sampling_dur;                            %Subtract the pre-trial sampling duration from the sample times.
            end
        end
    end
    if version < -1 && isfield(data,'trial') && ...
            isfield(data.trial,'starttime')                                 %If the file format version is newer than version -1 and the daycode function exists...
        data.daycode = daycode(data.trial(1).starttime);                    %Find the daycode for this file.
    end
elseif version == 1                                                         %If the file format version is 1...
    fseek(fid,0,-1);                                                        %Rewind to the beginning of the file.
    data.version = 1;                                                       %Version of the struct
    data.daycode = fread(fid,1,'uint16');                                   %DayCode.
    data.booth = fread(fid,1,'uint8');                                      %Booth number.
    N = fread(fid,1,'uint8');                                               %Number of characters in the rat's name.
    data.rat = fread(fid,N,'*char')';                                       %Characters of the rat's name.
    data.position = fread(fid,1,'uint8');                                   %Position of the input device (0-3 inches).
    data.responsewindow = fread(fid,1,'uint8');                             %Response window.
    data.stage(1) = fread(fid,1,'uchar');                                   %First character of the stage title stage number.
    temp = fread(fid,1,'uchar');                                            %Read in the next character.
    while temp(end) ~= data.stage(1)                                        %Loop until we get to the first letter of the device description.
        temp = [temp, fread(fid,1,'uchar')];                                %Read in the next character.
    end
    data.stage = char(horzcat(data.stage,temp(1:end-1)));                   %Concatenate the stage name together.
    if data.stage(1) == 'P'                                                 %If the stage is a pull stage...
        data.device = horzcat(temp(end),fread(fid,3,'*char')');             %Read in the selected device (Pull).
    else                                                                    %Otherwise, if the stage is a lever or wheel stage...
        data.device = horzcat(temp(end),fread(fid,4,'*char')');             %Read in the selected device (Lever or Wheel).
    end
    data.bin = fread(fid,1,'uint8');                                        %Bin Size.
    numparams = fread(fid,1,'uint8');                                       %Number of stimulus parameters.
    for i = 1:numparams                                                     %Step through each stimulus parameter.
        N = fread(fid,1,'uint16');                                          %Number of characters in a parameter name.
        data.param(i).name = fread(fid,N,'*char')';                         %Parameter name.
    end
    trial = 0;                                                              %Start a trial counter.
    while ~feof(fid)                                                        %Loop until the end of the file.
        trial=trial+1;                                                      %Increment the trial counter.
        try                                                                 %Try to read in a trial, abort if the trial is corrupted.
            data.trial(trial).threshold = fread(fid,1,'uint16');            %Read Threshold.
            data.trial(trial).starttime = fread(fid,1,'float64');           %Read trial start time.
            data.trial(trial).hittime = fread(fid,1,'float64');             %Read hit/reward time.
            data.trial(trial).outcome = fread(fid,1,'float64');             %Read Trial Outcome.
            for i = 1:3                                                     %Step through the three IR inputs.
                numIR = fread(fid,1,'uint32');                              %Read the number of breaks on the IR input.
                data.trial(trial).IR1(i).times = ...
                    fread(fid,numIR,'float64');                             %Read in the timestamp for the IR break.
            end
            numbins = fread(fid,1,'uint32');                                %Read in the number of signal datapoints.
            data.trial(trial).signal = fread(fid,numbins,'float64');        %Read in the sensory signal.
        catch ME                                                            %If an error occurs...
            lastwarn(['ARDYMOTORFILEREAD: ' ME.message],...
                ['ARDYMOTORFILEREAD:' ME.identifier]);                      %Save the warning ID.
        end
    end
    if isempty(data.trial(end).starttime)                                   %If the last trial had no data...
        data.trial(end) =[];                                                %Remove the empty trial.
    end
end
if isfield(data,'trial') && ~isempty(data.trial)                            %If there's at least one trial...
    data.daycode = fix(data.trial(1).starttime);                            %Set the daycode to the fixed first trial timestamp.
end
fclose(fid);                                                                %Close the input file.
varargout{1} = version;                                                     %Output the format version number if the user asked for it.

%% This subfunction returns the daycode (1-365) for a given date.
function d = daycode(date)
date = datevec(date);                                                       %Convert the serial date number to a date vector.
year = date(1);                                                             %Pull the year out of the date vector.
month = date(2);                                                            %Pull out the month.
day = date(3);                                                              %Pull out the day.
if year/4 == fix(year/4);                                                   %If the year is a leap year...
    numDays = [31 29 31 30 31 30 31 31 30 31 30 31];                        %Include 29 days in February.
else                                                                        %Otherwise...
	numDays = [31 28 31 30 31 30 31 31 30 31 30 31];                        %Include 28 days in February.
end
date = sum(numDays(1:(month-1)));                                           %Sum the days in the preceding months...
d = date + day;                                                             %...and add the day of the specified month.

function X = boxsmooth(X,wsize)
%Box smoothing function for 2-D matrices.

%X = BOXSMOOTH(X,WSIZE) performs a box-type smoothing function on 2-D
%matrices with window width and height equal to WSIZE.  If WSIZE isn't
%given, the function uses a default value of 5.

if (nargin < 2)                                                             %If the use didn't specify a box size...
    wsize = 5;                                                              %Set the default box size to a 5x5 square.
end     
if (nargin < 1)                                                             %If the user entered no input arguments...
   error('BoxSmooth requires 2-D matrix input.');                           %Show an error.
end

if length(wsize) == 1                                                       %If the user only inputted one dimension...
    rb = round(wsize);                                                      %Round the number of row bins to the nearest integer.
    cb = rb;                                                                %Set the number of column bins equal to the number of row bins.
elseif length(wsize) == 2                                                   %If the user inputted two dimensions...
    rb = round(wsize(1));                                                   %Round the number of row bins to the nearest integer.
    cb = round(wsize(2));                                                   %Round the number of column bins to the nearest integer.
else                                                                        %Otherwise, if the 
    error('The input box size for the boxsmooth can only be a one- or two-element matrix.');
end

w = ones(rb,cb);                                                            %Make a matrix to hold bin weights.
if rem(rb,2) == 0                                                           %If the number of row bins is an even number.
    rb = rb + 1;                                                            %Add an extra bin to the number of row bins.
    w([1,end+1],:) = 0.5;                                                   %Set the tail bins to have half-weight.
end
if rem(cb,2) == 0                                                           %If the number of column bins is an even number.
    cb = cb + 1;                                                            %Add an extra bin to the number of row bins.
    w(:,end+1) = w(:,1);                                                    %Make a new column of weights with the weight of the first column.
    w(:,[1,end]) = 0.5*w(:,[1,end]);                                        %Set the tail bins to have half-weight.
end

[r,c] = size(X);                                                            %Find the number of rows and columns in the input matrix.
S = nan(r+rb-1,c+cb-1);                                                     %Pre-allocate an over-sized matrix to hold the original data.
S((1:r)+(rb-1)/2,(1:c)+(cb-1)/2) = X;                                       %Copy the original matrix to the center of the over-sized matrix.

temp = zeros(size(w));                                                      %Pre-allocate a temporary matrix to hold the box values.
for i = 1:r                                                                 %Step through each row of the original matrix.
    for j = 1:c                                                             %Step through each column of the original matrix.
        temp(:) = S(i:(i+rb-1),j:(j+cb-1));                                 %Pull all of the bin values into a temporary matrix.
        k = ~isnan(temp(:));                                                %Find all the non-NaN bins.
        X(i,j) = sum(w(k).*temp(k))/sum(w(k));                              %Find the weighted mean of the box and save it to the original matrix.
    end
end

%% This function analyzes the data 
function [knob_data] = TransformKnobData(files, path)

parameters = {'mean_distance', 'latency_to_hit', 'peak_velocity', ...
    'peak_acceleration', 'num_turns', 'mean_turn_distance'};


%% Find the maximum length across all files
max_session = 0;
cd(path);

num_sessions = length(files);
knob_data.num_sessions = num_sessions;

for f = 1:knob_data.num_sessions
    data = ArdyMotorFileRead(files{f});
    temp = length(data.trial);
    if temp > max_session
        max_session = temp;
    end
end



%% Declare all variables

for p = 1:length(parameters)
    % Create matricies to store the totals trial variables
    knob_data.(parameters{p}).sessions = nan(num_sessions, max_session);
    %Create matricies to store the means of individual sessions
    knob_data.(parameters{p}).sessionmeans = nan(num_sessions, 1);
    %Create matricies to store the combined session data
    knob_data.(parameters{p}).sessionscombined = nan(1,num_sessions);
end

knob_data.threshold.combined = nan(1, num_sessions);

for f = 1:num_sessions                                                     %Step through each file.
    
    cd(path);
    data = ArdyMotorFileRead(files{f});                                     %Read in the data from the *.ArdyMotor file.
    if ~isfield(data,'trial') || isempty(data.trial)                        %If there's no trials in this data file...
        warning('ARDYMOTOR2TEXT:NoTrials',['WARNING FROM '...
            'ARDYMOTOR2TEXT: The file "' file{f} '" has zero trials '...
            'and will be skipped.']);                                       %Show a warning.
        continue                                                            %Skip to the next file.
    end
    
    knob_data.sessions(f,1) = length(data.trial);

    for t = 1:length(data.trial)                                            %Step through each trial.
        a = find((data.trial(t).sample_times >= 0 & ...
        data.trial(t).sample_times < 1000*data.trial(t).hitwin));           %Find all samples within the hit window.
    
        signal = data.trial(t).signal(a);                                   %Define the signal as the raw signal
        
        data.trial(t).range = range(signal);                                %Find the hit window range of each trial signal.
        data.trial(t).max = max(signal);                                    %Find the hit window maximum of each trial signal.
        data.trial(t).min = min(signal);                                    %Find the hit window minimum of each trial signal.
        
        [pks, sig] = Knob_Peak_Finder(signal);                              %Find the peaks in the signal
        data.trial(t).num_turns = length(sig);                              %Calculate number of turns
        data.trial(t).mean_turn_distance = mean(pks);                       %Take the mean peak distance to find mean turn distance in trial
        
        if data.trial(t).num_turns == 0                                     %If a turn was initiated in the previous session, and not registered
            data.trial(t).num_turns = 1;                                    %in this session, then count it as 1
        end
         
        smooth_trial_signal = boxsmooth(signal);                            %Smooth the signal 
        
        smooth_knob_velocity = boxsmooth(diff(smooth_trial_signal));        %Boxsmooth the velocity signal
        data.trial(t).peak_velocity = max(smooth_knob_velocity);            %Calculate the max of the velocity signal
        
        knob_acceleration = boxsmooth(diff(smooth_knob_velocity));          %Calculate the acceleration by differentiating the velocity signal
        data.trial(t).peak_acceleration = max(knob_acceleration);           %Find the max of the acceleration signal
        
        if (data.trial(t).outcome == 72)                                    %If it was a hit
            hit_time = find(data.trial(t).signal >= ...                     %Calculate the hit time
                data.trial(t).thresh,1);                                   
            data.trial(t).latency_to_hit = hit_time;                        %Set this hit_time to the latency_to_hit structure variable
        else
            data.trial(t).latency_to_hit = NaN;                             %If trial resulted in a miss, then set latency to hit to NaN
        end
        
        %Put each parameter of individual trial in its appropriate array,
        %store each trial from a session in consecutive columns,
        %and each session in consecutive rows
        
        
            knob_data.mean_distance.sessions(f,t) = data.trial(t).max;                   
            knob_data.threshold.sessions(f,t) = data.trial(t).thresh;
            knob_data.latency_to_hit.sessions(f,t) = data.trial(t).latency_to_hit;
            knob_data.peak_velocity.sessions(f,t) = data.trial(t).peak_velocity;
            knob_data.peak_acceleration.sessions(f,t) = data.trial(t).peak_acceleration;
            knob_data.num_turns.sessions(f,t) = data.trial(t).num_turns;
            knob_data.mean_turn_distance.sessions(f,t) = data.trial(t).mean_turn_distance;
        
    end
    
    
    
    %Store the total mean of the session in consecutive rows
    knob_data.mean_distance.sessionmeans(f,1) = nanmean(knob_data.mean_distance.sessions(f,:));
    knob_data.latency_to_hit.sessionmeans(f,1) = nanmean(knob_data.latency_to_hit.sessions(f,:));
    knob_data.peak_velocity.sessionmeans(f,1) = nanmean(knob_data.peak_velocity.sessions(f,:));
    knob_data.peak_acceleration.sessionmeans(f,1) = nanmean(knob_data.peak_acceleration.sessions(f,:));
    knob_data.num_turns.sessionmeans(f,1) = nanmean(knob_data.num_turns.sessions(f,:));
    knob_data.mean_turn_distance.sessionmeans(f,1) = nanmean(knob_data.mean_turn_distance.sessions(f,:));

end

for p = 1:length(parameters)
    prev_sessions = 1;
    
    %Concatenate all trials from consecutive sessions in to one long array
    for s = 1:num_sessions
        knob_data.(parameters{p}).sessionscombined(prev_sessions:(knob_data.sessions(s)+prev_sessions-1)) ...       %Throw everything in to one array
            = knob_data.(parameters{p}).sessions(s,1:knob_data.sessions(s));
        if (strcmpi((parameters{p}), 'mean_distance') == 1)
            knob_data.threshold.sessionscombined(prev_sessions:(knob_data.sessions(s)+prev_sessions-1)) ...
                = knob_data.threshold.sessions(s,1:knob_data.sessions(s));
        end
        prev_sessions = knob_data.sessions(s) + prev_sessions;
    end
    
    %Calculate the mean of concatenated matrix
    knob_data.(parameters{p}).combinedmean = nanmean(knob_data.(parameters{p}).sessionscombined);
    
end


function [knob_data] = TransformTrialData(files,path)

cd(path);

if ischar(files)                                                        %If only one file was selected...
    files = {files};                                                    %Convert the string to a cell array.
end


knob_data.trial_length = 500;
knob_data.combined_length = 0;
knob_data.num_sessions = length(files);

knob_data.session_length = nan(1, length(files));

knob_data.max_session_trials = 0;

for s = 1:knob_data.num_sessions
    data = ArdyMotorFileRead(files{s});
    temp = length(data.trial);
    knob_data.combined_length = temp+knob_data.combined_length;
    knob_data.session_length(s) = temp;
    
    if knob_data.session_length(s) > knob_data.max_session_trials;
        knob_data.max_session_trials = knob_data.session_length(s);
    end
end

knob_data.combined_trials = nan(knob_data.combined_length, 500);
knob_data.trial = nan(knob_data.max_session_trials, 500, knob_data.num_sessions);

for s = 1:knob_data.num_sessions
    data = ArdyMotorFileRead(files{s});
    for t = 1:knob_data.session_length(s)
%         if any(data.trial(t).signal < -10)
%             knob_data.trial(t,:,s) = NaN;
%             disp('Abnormal negative signal detected.... Removing');
%         elseif any(data.trial(t).signal > 150)
%             disp('Abnormal positive signal detected >150 deg... Removing')
%         else
            knob_data.trial(t, :, s) = data.trial(t).signal;
%         end
    end
end

for s = 1:knob_data.num_sessions
    for j=1:500
        knob_data.mean_plot(s,j) = nanmean(knob_data.trial(:,j,s));
%         interval(s,j) = nanstd(knob_data.trial(:,j,s))/(sqrt(knob_data.session_length(s)));
        knob_data.interval(s,j) = simple_ci(knob_data.trial(:,j,s));
        knob_data.upper(s,j) = knob_data.mean_plot(s,j) + knob_data.interval(s,j);
        knob_data.lower(s,j) = knob_data.mean_plot(s,j) - knob_data.interval(s,j);
    end
end

function ci = simple_ci(X,alpha)
%Simple confidence interval calculator.

%CI = SIMPLE_CI(X,ALPHA) finds the confidence range for the single column
%dataset X using the significance level ALPHA.  If ALPHA isn't specified,
%the function uses a default value of 0.05.

if (nargin < 2)     %If the use didn't specify an alpha.
    alpha = 0.05; 
end     
if (nargin < 1)
   error('simple_ci requires single column data input.');
end
[h,p,ci] = ttest(X,0,alpha);
ci = nanmean(X,1)-ci(1,:);
