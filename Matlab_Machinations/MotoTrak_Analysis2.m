function MotoTrak_Analysis2
%% Find the path containing the MotoTrak Analysis program.
if isdeployed                                                               %If this is deployed code...
    progpath = [pwd '\'];                                                   %The default data path will begin with the current directory...
else                                                                        %Otherwise, if we're evaluating code or running an *.m file...
    temp = mfilename('fullpath');                                           %Grab the current *.m filename.
    if isempty(temp)                                                        %If we're evaluating code...
        progpath = which('NeuroTriage_Analysis.m');                         %Find the path containing the current folder.
        progpath(find(progpath == '\',1,'last')+1:end) = [];                %Kick out everything after the path.
    else
        progpath = temp(1:find(temp == '\',1,'last'));                      %Pull the path out of the m-file name.
    end
end 
%% Have the user choose a path containing data files to analyze.
datapath = 'C:\Users\sab3005\Desktop\KnobAnalysisProject';                                                  %Set the expected primary local data path for saving data files.
if ~exist(datapath,'dir')                                                   %If the primary local data path doesn't exist...
    datapath = pwd;                                                         %Set the default path to the current directory.
end
datapath = uigetdir(datapath,'Where is your MotoTrak data located?');       %Ask the user where their data is located.
if datapath(1) == 0                                                         %If the user pressed "cancel"...
    return                                                                  %Skip execution of the rest of the function.
end

%% Find all of the MotoTrak data files in the data path.
files = file_miner(datapath,'*.ArdyMotor');                                 %Find all LPS *.ArdyMotor files in the LPS folders.
pause(0.01);                                                                %Pause for 10 milliseconds.
if isempty(files)                                                           %If no files were found...
    errordlg('No MotoTrak data files were found in the that directory!');   %Show an error dialog box.
end

%% Have the user select rats to include or exclude in the analysis.
rats = files;                                                               %Copy the filenames to another cell array.
% TrialViewerFiles = files;
for r = 1:length(rats)                                                      %Step through each file.
    rats{r}(1:find(rats{r} == '\' | rats{r} == '/',1,'last')) = [];         %Kick out the path from the filename.
%     TrialViewerFiles{r}(1:find(TrialViewerFiles{r} == '\' | TrialViewerFiles{r} == '/',1,'last')) = [];
    i = strfind(rats{r},'_20');                                             %Find the start of the timestamp.
    if isempty(i) || length(i) > 1                                          %If no timestamp was found in the filename, or multiple timestamps were found...
        rats{r} = [];                                                       %Set the rat name to empty brackets.
    else                                                                    %Otherwise...
        rats{r}(i:end) = [];                                                %Kick out all characters of the filename except the rat name.
    end
end

rat_list = unique(rats);                                                    %Make a list of all the unique rat names.
i = listdlg('PromptString','Which rats would you like to include?',...
    'name','MotoTrak Analysis',...
    'SelectionMode','multiple',...
    'listsize',[250 250],...
    'initialvalue',1:length(rat_list),...
    'uh',25,...
    'ListString',rat_list);                                                 %Have the user pick rats to include.
if isempty(i)                                                               %If the user clicked "cancel" or closed the dialog...
    return                                                                  %Skip execution of the rest of the function.
else                                                                        %Otherwise...
    rat_list = rat_list(i);                                                 %Pare down the rat list to those that the user selected.
end
keepers = ones(length(rats),1);                                             %Create a matrix to check which files match the selected rat names.
for r = 1:length(rats)                                                      %Step through each file's rat name.
    if ~any(strcmpi(rat_list,rats{r})) && ~isempty(rats{r})                 %If this file's rat name wasn't selected and a rat name was found in the filename...
        keepers(r) = 0;                                                     %Mark the file for exclusion.
    end
end
files(keepers == 0) = [];                                                   %Kick out all files the user doesn't want to include.

%% Step through all of the data files and load them into a structure.
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'Screensize');                                                  %Grab the screensize.
h = 2;                                                                      %Set the height of the figure.
w = 15;                                                                     %Set the width of the figure.
fig = figure('numbertitle','off','name','Loading MotoTrak Files...',...
    'units','centimeters','Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h],...
    'menubar','none','resize','off');                                       %Create a figure to show the progress of reading in the files.
ax = axes('units','centimeters','position',[0.25,0.25,w-0.5,h/2-0.3],...
    'parent',fig);                                                          %Create axes for showing loading progress.
obj = fill([0 1 1 0 0],[0 0 1 1 0],'b','edgecolor','k');                    %Create a fill object to show loading progress.
set(ax,'xtick',[],'ytick',[],'box','on','xlim',[0,length(files)],...
    'ylim',[0,1]);                                                          %Set the axis limits and ticks.
txt = uicontrol(fig,'style','text','units','centimeters',...
    'position',[0.25,h/2+0.05,w-0.5,h/2-0.3],'fontsize',8,...
    'horizontalalignment','left','backgroundcolor',get(fig,'color'));       %Create a text object to show which file is being loaded.
data = [];                                                                  %Create a structure to receive data.
for f = 1:length(files)                                                     %Step through the data files.
    a = find(files{f} == '\',1,'last');                                     %Find the last forward slash in the filename.
    temp = files{f}(a+1:end);                                               %Grab the filename minus the path.
    if ishandle(fig)                                                        %If the user hasn't closed the waitbar figure...
        set(txt,'string',...
            [sprintf('Loading (%1.0f/%1.0f): ',[f,length(files)]) temp]);   %Update the waitbar figure.
        set(obj,'xdata',f*[0 1 1 0 0]);                                     %Update the x-coordinates for the fill object.
        drawnow;                                                            %Update the plot immediately.
    else                                                                    %Otherwise, if the user has closed the waitbar...
        return                                                              %Skip execution of the rest of the function.
    end
    try                                                                     %Try to read in the data file...
        temp = ArdyMotorFileRead(files{f});                                 %Read in the data from each file.
    catch err                                                               %If an error occurs...
        warning(['ERROR READING: ' files{f}]);                              %Show which file had a read problem...
        warning(err.message);                                               %Show the actual error message.
    end
    if isfield(temp,'trial') && length(temp.trial) >= 5 && ...
             any(strcmpi(rat_list,temp.rat))                                 %If there were at least 5 trials...        
        s = length(data) + 1;                                               %Create a new field index.
        for field = {'rat','device','stage'}                               %Step through the fields we want to save from the data file...
            data(s).(field{1}) = temp.(field{1});                           %Grab each field from the data file and save it.
        end
        data(s).outcome = char([temp.trial.outcome]');                      %Grab the outcome of each trial.
        data(s).thresh = [temp.trial.thresh]';                              %Grab the threshold for each trial.
        data(s).starttime = [temp.trial.starttime]';                        %Grab the start time for each trial.
        data(s).peak = nan(length(temp.trial),1);                           %Create a matrix to hold the peak force.
        for t = 1:length(temp.trial)                                        %Step through every trial.
            i = (temp.trial(t).sample_times >= 0 & ...
                temp.trial(t).sample_times < 1000*temp.trial(t).hitwin);    %Find the indices for samples in the hit window.
            if any(i ~= 0)                                                  %If there's any samples...
                data(s).peak(t) = max(temp.trial(t).signal(i));             %Find the maximum force in each hit window.
                data(s).impulse(t) = max(diff(temp.trial(t).signal(i)));    %Find the maximum impulse in each hit window.
            end
        end
        data(s).timestamp = data(s).starttime(1);                           %Grab the timestamp from the start of the first trial.
        data(s).files = files{f};
    end
end
if ishandle(fig)                                                            %If the user hasn't closed the waitbar figure...
    close(fig);                                                             %Close the waitbar figure.
    drawnow;                                                                %Immediately update the figure to allow it to close.
end
if isempty(data)                                                            %If no data files were found...
    errordlg(['There were no MotoTrak data files with 5 or more trials '...
        'for the selected rats!']);                                         %Show an error dialog box.
end
[~,i] = sort([data.timestamp]);                                             %Find the indices to sort all files chronologically.
data = data(i);                                                             %Sort all files chronologically.
% files = files(i);
% TrialViewerFiles = TrialViewerFiles(i);
devices = unique({data.device});                                            %Grab the unique device names across all sessions.

%% Create interactive figures for each of the device types.
for d = 1:length(devices)                                                   %Step through the devices.
    s = strcmpi({data.device},devices{d});                                  %Find all sessions with each device.
    rats = unique({data(s).rat});                                           %Find all of the unique rat names that have used this device.
    plotdata = struct([]);                                                  %Create a structure to hold data just for the plot.
    for r = 1:length(rats)                                                  %Step through each rat.
        plotdata(r).rat = rats{r};                                          %Save the rat's name to the plotdata structure.
        plotdata(r).device = devices{d};                                    %Save the device to the plotdata structure.
        i = find(strcmpi({data.rat},rats{r}) & ...
            strcmpi({data.device},devices{d}));                             %Find all the session for this rat on this device.
        plotdata(r).times = [data(i).timestamp];                            %Grab the timestamps for all sessions.
        plotdata(r).peak = nan(1,length(i));                                %Pre-allocate a matrix to hold the average peak signal for each session.
        plotdata(r).hitrate = nan(1,length(i));                             %Pre-allocate a matrix to hold the hit rate for each session.
        plotdata(r).numtrials = nan(1,length(i));                           %Pre-allocate a matrix to hold the number of trials for each session.
        plotdata(r).peak = nan(1,length(i));                                %Pre-allocate a matrix to hold the average peak signal for each session.
        plotdata(r).first_hit_five = nan(1,length(i));                      %Pre-allocate a matrix to hold the number of hits in the first 5 minutes.
        plotdata(r).first_trial_five = nan(1,length(i));                    %Pre-allocate a matrix to hold the number of trials in the first 5 minutes.
        plotdata(r).any_hit_five = nan(1,length(i));                        %Pre-allocate a matrix to hold the maximum number of hits in any 5 minutes.
        plotdata(r).any_trial_five = nan(1,length(i));                      %Pre-allocate a matrix to hold the maximum number of trials in any 5 minutes.
        plotdata(r).any_hitrate_five = nan(1,length(i));                    %Pre-allocate a matrix to hold the maximum hit rate in any 5 minutes.
        plotdata(r).min_iti = nan(1,length(i));                             %Pre-allocate a matrix to hold the minimum inter-trial interval.
        plotdata(r).impulse = nan(1,length(i));                             %Pre-allocate a matrix to hold the average peak impulse for each session.
        plotdata(r).stage = cell(1,length(i));                              %Pre-allocate a cell array to hold the stage name for each session..
        plotdata(r).files = cell(1,length(i));
        for s = 1:length(i)                                                 %Step through each session.
            plotdata(r).peak(s) = mean(data(i(s)).peak);                    %Save the mean signal peak for each session.
            plotdata(r).impulse(s) = mean(data(i(s)).impulse);              %Save the mean signal impulse peak for each session.
            plotdata(r).hitrate(s) = mean(data(i(s)).outcome == 'H');       %Save the hit rate for each session.
            plotdata(r).numtrials(s) = length(data(i(s)).outcome);          %Save the total number of trials for each session.
            plotdata(r).stage{s} = data(i(s)).stage;                        %Save the stage for each session.
            plotdata(r).files{s} = data(i(s)).files;
            times = data(i(s)).starttime;                                   %Grab the trial start times.
            times = 86400*(times - data(i(s)).timestamp);                   %Convert the trial start times to seconds relative to the first trial.
            if any(times >= 300)                                            %If the session lasted for at least 5 minutes...
                plotdata(r).first_hit_five(s) = ...
                    sum(data(i(s)).outcome(times <= 300) == 'H');           %Count the number of hits in the first 5 minutes.
                plotdata(r).first_trial_five(s) = sum(times <= 300);        %Count the number of trials in the first 5 minutes.
                a = zeros(length(times)-1,2);                               %Create a matrix to hold hit counts in any 5 minutes.
                for j = 1:length(times) - 1                                 %Step through each trial.
                    a(j,2) = sum(times(j:end) - times(j) <= 300);           %Count the number of trials within 5 minutes of each trial.
                    a(j,1) = sum(times(j:end) - times(j) <= 300 & ...
                        data(i(s)).outcome(j:end) == 'H');                  %Count the number of hits within 5 minutes of each trial.
                end
                plotdata(r).any_hit_five(s) = nanmax(a(:,1));               %Find the maximum number of hits in any 5 minutes.
                plotdata(r).any_trial_five(s) = nanmax(a(:,2));             %Find the maximum number of trials in any 5 minutes.
                a(a(:,2) < 10,:) = NaN;                                     %Kick out any epochs with fewer than 10 trials.
                a = a(:,1)./a(:,2);                                         %Calculate the hit rate within each 5 minute epoch.
                plotdata(r).any_hitrate_five(s) = nanmax(a);                %Find the maximum hit rate of trials in any 5 minutes.
            end
            if length(times) > 1                                            %If there's more than one trial...
                times = diff(times);                                        %Calculate the inter-trial intervals.
                times = boxsmooth(times,10);                                %Box-smooth the inter-trial intervals over 10 trials.
                if length(times) > 11                                       %If there's mor than 11 trials...
                    plotdata(r).min_iti(s) = nanmin(times(6:end-5));        %Find the minimum inter-trial interval over full groups of 10 trials.
                else                                                        %Otherwise...
                    plotdata(r).min_iti(s) = times(round(length(times)/2)); %Set the minimum inter-trial interval to the middle-most value.
                end
            end
        end
    end
    for r = 1:length(plotdata)                                                  %Step through each rat.
        clear dates
        plotdata2(r).times = plotdata(r).times';
        for i = 1:size(plotdata2(r).times,1)                                         %Step through each timepoint.
            if rem(plotdata2(r).times(i,1),1) ~= 0                                   %If the timestamp is a fractional number of days...
                temp = datestr(plotdata2(r).times(i,1),'mm/dd/yyyy, HH:MM');         %Show the date and the time.
            elseif plotdata2(r).x(i,2) - plotdata2(r).x(i,1) == 1                 %If the timestamps only cover one day...
                temp = datestr(plotdata2(r).times(i,1),'mm/dd/yyyy');                %Show only the date.
            else                                                                %Otherwise...
                temp = [datestr(plotdata2(r).times(i,1),'mm/dd/yyyy') '-' ...
                    datestr(plotdata2(r).times(i,2)-1,'mm/dd/yyyy')];                %Show the date range.
            end
            dates{i} = temp;
        end
        FinalDates{r} = dates{end};
    end
    pos = get(0,'Screensize');                                              %Grab the screensize.
    h = 5;                                                                 %Set the height of the figure, in centimeters.
    w = 15;                                                                 %Set the width of the figure, in centimeters.
    fig = figure('numbertitle','off','units','centimeters',...
        'name',['MotoTrak Analysis: ' devices{d}],'menubar','none',...
        'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
    tgroup = uitabgroup('Parent', fig);
    tabs = rat_list;
    for i = 1:length(tabs);
        tab(i) = uitab('Parent', tgroup, 'Title', sprintf('Animal %s', tabs{i}));
        tabs_info(i,:) = get(tab(i));
        laststages(i) = plotdata(i).stage(length(plotdata(i).stage));
        numberofsessions(i) = length(plotdata(i).stage);
        AnimalName(i) = uicontrol('Parent', tab(i), 'Style', 'text', 'String', sprintf('Animal Name: %s', tabs{i}), ...
            'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.05 .85 .4 .1],...
            'Fontsize', 10, 'Fontweight', 'normal') ;
        LastSessionRun(i) = uicontrol('Parent', tab(i), 'Style', 'text', 'String', sprintf('Last Session Run: %s', laststages{i}), ...
            'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.05 .65 .6 .1],...
            'Fontsize', 10, 'Fontweight', 'normal') ;
        LastDateRun(i) = uicontrol('Parent', tab(i), 'Style', 'text', 'String', sprintf('Last Date Run: %s', FinalDates{i}), ...
            'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.05 .45 .4 .1],...
            'Fontsize', 10, 'Fontweight', 'normal') ;
        NumberOfSessions(i) = uicontrol('Parent', tab(i), 'Style', 'text', 'String', sprintf('Number of Sessions: %d', numberofsessions(i)), ...
            'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.05 .25 .4 .1],...
            'Fontsize', 10, 'Fontweight', 'normal') ;
        DevicesRuns(d) = uicontrol('Parent', tab(i), 'Style', 'text', 'String', sprintf('Devices: %s', devices{d}), ...
            'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.05 .05 .4 .1],...
            'Fontsize', 10, 'Fontweight', 'normal') ;
%         Timeline(i) = uicontrol('Parent', tab(i), 'Style', 'text', 'String', 'Timeline', ...
%             'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.05 .48 .4 .05],...
%             'Fontsize', 10, 'Fontweight', 'bold') ;
        General_Analysis(i) = uicontrol('Parent', tab(i),'style','pushbutton','string','General Analysis','HorizontalAlignment', 'left',...
            'units','normalized','position',[.7 .625 .25 .25],'fontsize',10, 'callback', {@GeneralAnalysis,devices(d)},'userdata',plotdata(i));    
%         Lab_Analysis(i) = uicontrol('Parent', tab(i),'style','pushbutton','string','Lab Analysis','HorizontalAlignment', 'left',...
%             'units','normalized','position',[.7 .125 .25 .25],'fontsize',10, 'callback', {@LabAnalysis,devices(d)},'userdata',plotdata(i));        
%         hold on;
%         ax = axes('Parent', tab(i), 'units','normalized','position',[.03 .3 .94 .1 ],'Visible', 'off'); 
%         line([0, 1], [1, 1], 'Parent', ax, 'linewidth', 2, 'color', 'k')
%         hold off;
    end
end

%% This function is called when the user selects the General Analysis Pushbutton
function GeneralAnalysis(hObject,~,devices)
data = hObject.UserData;
pos = get(0,'Screensize');                                              %Grab the screensize.
h = 10;                                                                 %Set the height of the figure, in centimeters.
w = 15;                                                                 %Set the width of the figure, in centimeters.
for d = 1:length(devices)                                                   %Step through the devices.
    fig = figure('numbertitle','off','units','centimeters',...
        'name',['MotoTrak Analysis: ' devices{d}],'menubar','none',...
        'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);                     %Create a figure.
    ui_h = 0.07*h;                                                          %Set the heigh of the uicontrols.
    fontsize = 0.6*28.34*ui_h;                                              %Set the fontsize for all uicontrols.
    sp1 = 0.02*h;                                                           %Set the vertical spacing between axes and uicontrols.
    sp2 = 0.01*w;                                                           %Set the horizontal spacing between axes and uicontrols.
    pos = [7*sp2,3*sp1,w-8*sp2,h-ui_h-5*sp1];                               %Set the position of the axes.
    ax = axes('units','centimeters','position',pos,'box','on',...
        'linewidth',2);                                                     %Create axes for showing the log events histogram.
    obj = zeros(1,5);                                                       %Create a matrix to hold timescale uicontrol handles.
    str = {'Overall Hit Rate',...
        'Total Trial Count',...
        'Mean Peak Force',...
        'Median Peak Force',...
        'Trial Count',...
        'Hits in First 5 Minutes',...
        'Trials in First 5 Minutes',...
        'Max. Hits in Any 5 Minutes',...
        'Max. Trials in Any 5 Minutes',...
        'Max. Hit Rate in Any 5 Minutes',...
        'Min. Inter-Trial Interval (Smoothed)',...
        'Mean Peak Impulse',...
        'Median Peak Impulse'};                                             %List the available plots for the pull data.
    if any(strcmpi(devices{d},{'knob','lever'}))                            %If we're plotting knob data...
        str(2:3) = {'Mean Peak Angle','Median Peak Angle'};                 %Set the plots to show "angle" instead of "force".
    elseif ~any(strcmpi(devices{d},{'knob','lever','pull'}))                %Otherwise, if this isn't pull, knob, or lever data...
        str(2:3) = {'Mean Signal Peak','Median Signal Peak'};               %Set the plots to show "signal" instead of "peak force".
    end
    pos = [sp2, h-sp1-ui_h, 2*(w-6*sp2)/6, ui_h];                           %Set the position for the pop-up menu.
    obj(1) = uicontrol(fig,'style','popup','string',str,...
        'units','centimeters','position',pos,'fontsize',fontsize);      %Create pushbuttons for selecting the timescale.
    str = {'Session','Daily','Weekly','Export'};                            %List the timescale labels.
    for i = 2:5                                                             %Step through the 3 timescales.
        pos = [i*sp2+i*(w-6*sp2)/6, h-sp1-ui_h, (w-6*sp2)/6, ui_h];         %Set the position for each pushbutton.
        obj(i) = uicontrol(fig,'style','pushbutton','string',str{i-1},...
            'units','centimeters','position',pos,'fontsize',fontsize);      %Create pushbuttons for selecting the timescale.
    end
    set(obj(1),'callback',{@Set_Plot_Type,obj,data});                            %Set the callback for the pop-up menu.
    set(obj(2:4),'callback',{@Plot_Timeline,obj,[],data});                       %Set the callback for the timescale buttons.
    set(obj(5),'callback',{@Export_Data,ax,obj});                           %Set the callback for the export button.
    set(fig,'userdata',data);                                           %Save the plot data to the figure's 'UserData' property.
    Plot_Timeline(obj(2),[],obj,[],data);                                        %Call the function to plot the session data in the figure.
    set(fig,'ResizeFcn',{@Resize,ax,obj});
end

%% This function is called when the user selects the Lab Analysis Pushbutton
% function LabAnalysis(hObject,~,devices)
% data = hObject.UserData;
% Table = readtable('LabSpecificAnalysisConfig.txt');
% Path = Table{:,2};
% pos = get(0,'Screensize');                                              %Grab the screensize.
% h = 8;                                                                 %Set the height of the figure, in centimeters.
% w = 15;                                                                 %Set the width of the figure, in centimeters.
% FileNames = {};
% for d = 1:length(devices)
%     fig = figure('numbertitle','off','units','centimeters',...
%         'name',['Lab Specific Analysis: ' devices{d}],'menubar','none',...
%         'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
%     Choose_Lab = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Please choose a lab:', ...
%         'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.1 .85 .3 .05],...
%         'Fontsize', 12, 'Fontweight', 'bold') ;
%     Analysis_Type = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
%         'callback', {@AnalysisType,devices},'userdata',data,'string',FileNames,...
%         'units', 'normalized', 'Position', [.525 .1 .45 .7]);
%     Lab_Name = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','string', Table{:,1},...
%         'units', 'normalized', 'Position', [.025 .1 .45 .7],'callback',{@LabName,devices,Path,Analysis_Type},'userdata',data,...
%         'Fontsize', 12);
%     Lab_Functions = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Lab Functions', ...
%         'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.65 .85 .3 .05],...
%         'Fontsize', 12, 'Fontweight', 'bold') ;
% end

function LabName(hObject,~,devices,Path,Analysis_Type)
data = hObject.UserData;
index_selected = get(hObject,'value');
Path = Path{index_selected};
cd(Path);
Path = char(Path);
list = dir(Path);
FileNames = {list.name};
FileNames = FileNames(3:end);
set(Analysis_Type,'string',FileNames);
% guidata(hObject,handles);
% AnalysisType(hObject,[],devices,FileNames);

function AnalysisType(hObject,~,devices)
uiwait(msgbox('Hello!'));
index_selected = get(hObject,'value');

%% This function is called when the user selects a plot type in the pop-up menu.
function Set_Plot_Type(~,~,obj,data)
i = strcmpi(get(obj,'fontweight'),'bold');                                  %Find the pushbutton with the bold fontweight.
Plot_Timeline(obj(i),[],obj,[],data);                                            %Call the subfunction to plot the data by the appropriate timeline.

%% This subfunction sorts the data into single-session values and sends it to the plot function.
function Plot_Timeline(hObject,~,obj,fid,data)
TrialViewerData = data;
set(hObject,'fontweight','bold','foregroundcolor',[0 0.5 0]);               %Make this pushbutton's text bold.
set(setdiff(obj(2:4),hObject),'fontweight','normal','foregroundcolor','k'); %Make the other pushbutton's text normal and black.
fig = get(hObject,'parent');                                                %Grab the parent figure of the pushbutton.
data = get(fig,'userdata');                                                 %Grab the plot data from the figure's 'UserData' property.
i = find(hObject == obj);                                                   %Find the index of the button that called the function.
t = unique(horzcat(data.times));                                            %Horizontally concatenate all of the timestamps.
if i == 2                                                                   %If the user wants to plot by session...
    t = [t; t + 0.00001]';                                                  %Set the time bounds to enclose only a single session.
elseif i == 3                                                               %If the user wants to plot by day...
    t = unique(fix(t));                                                     %Find the unique truncated serial date numbers.
    t = [t; t + 1]';                                                        %Set the time bounds to go from the start of the day to the end of the day.
else                                                                        %Otherwise, if the user wants to plot by week...
    t = [min(fix(t)), max(fix(t))];                                         %Find the first and last timestamp.
    i = find(strcmpi({'sun','mon','tue','wed','thu','fri','sat'},...
        datestr(t(1),'ddd')));                                              %Find the index for the day of the week of the first timestamp.
    t(1) = t(1) - i + 1;                                                    %Round down the timestamp to the nearest Sunday.
    t = t(1):7:t(2);                                                        %Find the timestamps for weekly spacing.
    t = [t; t + 7]';                                                        %Set the time bounds to go from the start of the week to the end of the week.
end
str = get(obj(1),'string');                                                 %Grab the strings from the pop-up menu.
i = get(obj(1),'value');                                                    %Grab the value of the pop-up menu.
str = str{i};                                                               %Grab the selected plot type.
plotdata = struct([]);                                                      %Create a structure to hold plot data.
for r = 1:length(data)                                                      %Step through each rat in the data structure.
    plotdata(r).rat = data(r).rat;                                          %Copy the rat name to the plot data structure.
    y = nan(1,size(t,1));                                                   %Pre-allocate a matrix to hold the data y-coordinates.
    s = cell(1,size(t,1));                                                  %Pre-allocate a cell array to hold the last stage of each time frame.
    n = cell(1,size(t,1));                                                  %Pre-allocate a cell array to hold the hit rate and trial count text.
    for i = 1:size(t,1)                                                     %Step through the specified time frames.
        j = data(r).times >= t(i,1) & data(r).times < t(i,2);               %Find all sessions within the time frame.
        if any(j)                                                           %If any sessions are found.
            if strcmpi(str,'overall hit rate')                              %If we're plotting overall hit rate...
                y(i) = nanmean(data(r).hitrate(j));                         %Grab the mean hit rate over this time frame.
            elseif strcmpi(str,'total trial count')                         %If we're plotting trial count...
                y(i) = nanmean(data(r).numtrials(j));                       %Grab the mean number of trials over this time frame.
            elseif any(strcmpi(str,{'median peak force',...
                    'median peak angle','median signal peak'}))             %If we're plotting the median signal peak...
                y(i) = nanmedian(data(r).peak(j));                          %Grab the mean signal peak over this time frame.
            elseif any(strcmpi(str,{'mean peak force',...
                    'mean peak angle','mean signal peak'}))                 %If we're plotting the mean signal peak...
                y(i) = nanmean(data(r).peak(j));                            %Grab the mean signal peak over this time frame.
            elseif strcmpi(str,'trial count')                               %If we're plotting number of trials....
                y(i) = nanmean(data(r).numtrials(j));                       %Grab the mean number of trials over this time frame.
            elseif strcmpi(str,'hits in first 5 minutes')                   %If we're plotting the hit count within the first 5 minutes.
                y(i) = nanmean(data(r).first_hit_five(j));                  %Grab the mean number of hits within the first 5 minutes over this time frame.
            elseif strcmpi(str,'trials in first 5 minutes')                 %If we're plotting the trial count within the first 5 minutes.
                y(i) = nanmean(data(r).first_trial_five(j));                %Grab the mean number of hits within the first 5 minutes over this time frame.
            elseif strcmpi(str,'max. hits in any 5 minutes')                %If we're plotting the maximum hit count within any 5 minutes.
                y(i) = nanmean(data(r).any_hit_five(j));                    %Grab the mean maximum number of hits within any 5 minutes over this time frame.
            elseif strcmpi(str,'max. trials in any 5 minutes')              %If we're plotting the maximum trial count within any 5 minutes.
                y(i) = nanmean(data(r).any_trial_five(j));                  %Grab the mean maximum number of trials within any 5 minutes over this time frame.
            elseif strcmpi(str,'max. hit rate in any 5 minutes')            %If we're plotting the maximum hit rate within any 5 minutes.
                y(i) = nanmean(data(r).any_hitrate_five(j));                %Grab the mean maximum hit rate within any 5 minutes over this time frame.
            elseif strcmpi(str,'min. inter-trial interval (smoothed)')      %If we're plotting the minimum inter-trial interval.
                y(i) = nanmean(data(r).min_iti(j));                         %Grab the mean minimum inter-trial interval over this time frame.
            elseif strcmpi(str,'median peak impulse')                       %If we're plotting the median signal impulse...
                y(i) = nanmedian(data(r).impulse(j));                       %Grab the mean signal impulse over this time frame.
            elseif strcmpi(str,'mean peak impulse')                         %If we're plotting the mean signal impulse...
                y(i) = nanmean(data(r).impulse(j));                         %Grab the mean signal impulse over this time frame.
            end
            temp = [nanmean(data(r).hitrate(j)),...
                nansum(data(r).numtrials(j))];                              %Grab the mean hit rate and total number of trials over this time frame.
            temp(1) = temp(1)*temp(2);                                      %Calculate the number of hits in the total number of trials.
            n{i} = sprintf('%1.0f hits/%1.0f trials',temp);                 %Create a string showing the number of hits and trials.
            j = find(j,1,'last');                                           %Find the last matching session.
            s{i} = data(r).stage{j};                                        %Save the last stage the rat ran on for this trime frame.            
        end
    end
    plotdata(r).x = t(~isnan(y),:);                                         %Grab the daycodes at the start of each time frame.
    plotdata(r).y = y(~isnan(y))';                                          %Save only the non-NaN y-coordinates.
    plotdata(r).s = s(~isnan(y))';                                          %Save the stage information for each time frame.
    plotdata(r).n = n(~isnan(y))';                                          %Save the hit rate and trial information for each time frame.
end
ax = get(fig,'children');                                                   %Grab all children of the figure.
ax(~strcmpi(get(ax,'type'),'axes')) = [];                                   %Kick out all non-axes objects.
if isempty(fid)                                                             %If no text file handle was passed to this function...
    Make_Plot(plotdata,ax,str,TrialViewerData);                                             %Call the subfunction to make the plot.
else                                                                        %Otherwise...
    t = vertcat(plotdata.x);                                                %Vertically concatenate all time-points.
    t = unique(t,'rows');                                                   %Find all unique rows of the timepoints.
    fprintf(fid,'%s,\t','DATE/TIME');                                       %Print a date column header.
    for r = 1:length(plotdata)                                              %Step through the rats.
        if r == length(plotdata)                                            %If this is the last rat...
            fprintf(fid,'%s,\n',plotdata(r).rat);                           %Print the rat name followed by a carraige return.
        else                                                                %Otherwise...
            fprintf(fid,'%s,\t',plotdata(r).rat);                           %Print the rat name followed by a tab.
        end
    end
    for i = 1:size(t,1)                                                     %Step through each time-point.
        if rem(t(i,1),1) ~= 0                                               %If the timestamp is a fractional number of days...
            fprintf(fid,'%s,\t',datestr(t(i,1),'mm/dd/yyyy - HH:MM'));      %Show the date and the time.
        elseif t(i,2) - t(i,1) == 1                                         %If the timestamps only cover one day...
            fprintf(fid,'%s,\t',datestr(t(i,1),'mm/dd/yyyy'));              %Show only the date.
        else                                                                %Otherwise...
            fprintf(fid,'%s,\t',[datestr(t(i,1),'mm/dd/yyyy') '-' ...
                datestr(t(i,2)-1,'mm/dd/yyyy')]);                           %Show the date range.
        end
        for r = 1:length(plotdata)                                          %Step through the rats.
            j = plotdata(r).x(:,1) == t(i,1) & ...
                plotdata(r).x(:,1) == t(i,1);                               %Find any matching timepoint for this rat.
            if any(j)                                                       %If any matching timepoint was found...
                fprintf(fid,'%1.3f,',plotdata(r).y(j));                     %Print the value for this date range.
            else                                                            %Otherwise...
                fprintf(fid,'-,');                                          %Print a hyphen.
            end
            if r == length(plotdata)                                        %If this is the last rat...
                fprintf(fid,'\n');                                          %Print a carraige return.
            else                                                            %Otherwise...
                fprintf(fid,'\t');                                          %Print a tab.
            end
        end
    end
end

%% This subfunction sorts the data into daily values and sends it to the plot function.
function Export_Data(hObject,~,ax,obj)
output = questdlg(['Would you like to export the data as a spreadsheet '...
    'or figure image?'],'Data Type?','Spreadsheet','Image','Both','Both');  %Ask the user if they'd like to export the data as a spreadsheet or image.
fig = get(hObject,'parent');                                                %Grab the parent figure of the export button.
if any(strcmpi({'image','both'},output))                                    %If the user wants to save an image...
    [file, path] = uiputfile({'*.png';'*.jpg';'*.pdf'},...
        'Save Figure Image');                                               %Ask the user for a filename.
    if file(1) == 0                                                         %If the user clicked cancel...
        return                                                              %Skip execution of the rest of the function.
    end
    set(fig,'units','centimeters','resizefcn',[]);                          %Set the figure units to centimeters.
    pos = get(fig,'position');                                              %Get the figure position.
    temp = get(fig,'color');                                                %Grab the curret figure color.
    set(fig,'paperunits','centimeters','papersize',pos(3:4),...
        'inverthardcopy','off','paperposition',[0 0 pos(3:4)],'color','w'); %Set the paper size and paper position, in centimeters.
    w = pos(3);                                                             %Grab the width of the figure.
    h = pos(4);                                                             %Grab the height of the figure.
    ui_h = 0.07*h;                                                          %Set the height of all uicontrols.
    sp1 = 0.02*h;                                                           %Set the vertical spacing between axes and uicontrols.
    sp2 = 0.01*w;                                                           %Set the horizontal spacing between axes and uicontrols.
    pos = [7*sp2,3*sp1,w-8*sp2,h-4*sp1];                                    %Create an axes position matrix.
    set(ax,'units','centimeters','position',pos);                           %Expand the axes to fill the figure.
    set(obj,'visible','off');                                               %Make all of the other figures invisible.
    drawnow;                                                                %Immediately update the figure.    
    a = find(file == '.',1,'last');                                         %Find the start of the file extension.
    ext = file(a:end);                                                      %Grab the file extension.
    if strcmpi(ext,'.png')                                                  %If the user chose to save as a PNG...
        print(fig,[path file(1:a-1)],'-dpng');                              %Save the figure as a PNG file.
    elseif strcmpi(ext,'.jpg')                                              %If the user chose to save as a JPEG...
        print(fig,[path file(1:a-1)],'-djpeg');                             %Save the figure as a JPEG file.
    elseif strcmpi(ext,'.pdf')                                              %If the user chose to save as a PDF...
        print(fig,[path file(1:a-1)],'-dpdf');                              %Save the figure as a PDF file.
    end
    pos = [7*sp2,3*sp1,w-8*sp2,h-ui_h-5*sp1];                               %Create an axes position matrix.
    set(ax,'units','centimeters','position',pos);                           %Reset the position of the axes.
    set(obj,'visible','on');                                                %Make all of the other figures visible again.
    i = strcmpi(get(obj,'fontweight'),'bold');                              %Find the pushbutton with the bold fontweight.
    Plot_Timeline(obj(i),[],obj,[]);                                        %Call the subfunction to plot the data by the appropriate timeline.
    set(fig,'color',temp,'ResizeFcn',{@Resize,ax,obj});                     %Set the Resize function for the figure.
    drawnow;                                                                %Immediately update the figure.    
end
if any(strcmpi({'spreadsheet','both'},output))                              %If the user wants to save a spreadsheet...
    temp = get(ax,'ylabel');                                                %Grab the handle for the axes y-label.
    file = lower(get(temp,'string'));                                       %Grab the axes y-axis label.
    file(file == ' ') = '_';                                                %Replace any spaces with underscores.
    for i = '<>:"/\|?*().'                                                  %Step through all reserved characters.
        file(file == i) = [];                                               %Kick out any reserved characters.
    end
    file = [file '_' datestr(now,'yyyymmdd')];                              %Add today's date to the default filename.
    temp = lower(get(fig,'name'));                                          %Grab the figure name.
    file = [temp(20:end) '_' file];                                         %Add the device name to the default filename.
    [file, path] = uiputfile('*.csv','Save Spreadsheet',file);              %Ask the user for a filename.
    if file(1) == 0                                                         %If the user clicked cancel...
        return                                                              %Skip execution of the rest of the function.
    end
    fid = fopen([path file],'wt');                                          %Open a new text file to write the data to.   
    i = strcmpi(get(obj,'fontweight'),'bold');                              %Find the pushbutton with the bold fontweight.
    Plot_Timeline(obj(i),[],obj,fid);                                       %Call the subfunction to write the data by the appropriate timeline.
    fclose(fid);                                                            %Close the figure.
    winopen([path file]);                                                   %Open the CSV file.
end

%% This section plots session/daily/weekly data in the specified axes.
function Make_Plot(plotdata,ax,str,TrialViewerData)
fig = get(ax,'parent');                                                     %Grab the figure handle for the axes' parent.
set(fig,'units','centimeters');                                             %Set the figure's units to centimeters.
temp = get(fig,'position');                                                 %Grab the figure position.
h = temp(4);                                                                %Grab the figure height, in centimeters.
linewidth = 0.1*h;                                                          %Set the linewidth for the plots.
markersize = 0.75*h;                                                        %Set the marker size for the plots.
fontsize = 0.6*h;                                                           %Set the fontsize for all text objects.
cla(ax);                                                                    %Clear the axes.
colors = hsv(length(plotdata));                                             %Grab unique colors for all the rats.
hoverdata = struct([]);                                                     %Create an empty structure to hold data for the MouseHover function.
for r = 1:length(plotdata)                                                  %Step through each rat.
    line(mean(plotdata(r).x,2),plotdata(r).y,'color',colors(r,:),...
        'linewidth',linewidth,'userdata',1,'parent',ax);                    %Show the rat's performance as a thick line.
    for i = 1:size(plotdata(r).x,1)                                         %Step through each timepoint.
        l = line(mean(plotdata(r).x(i,:)),plotdata(r).y(i),...
            'markeredgecolor',colors(r,:),'linestyle','none',...
            'markerfacecolor',colors(r,:),'marker','.',...
            'linewidth',linewidth,'markersize',markersize,'userdata',2,...
            'parent',ax, 'ButtonDownFcn', {@TrialViewer,plotdata(r),i,TrialViewerData});                                                   %Mark each session with a unique marker.        
        hoverdata(end+1).xy = [mean(plotdata(r).x(i,:)),plotdata(r).y(i)];  %Save the x- and y-coordinates.
        if rem(plotdata(r).x(i,1),1) ~= 0                                   %If the timestamp is a fractional number of days...
            temp = datestr(plotdata(r).x(i,1),'mm/dd/yyyy, HH:MM');         %Show the date and the time.
        elseif plotdata(r).x(i,2) - plotdata(r).x(i,1) == 1                 %If the timestamps only cover one day...
            temp = datestr(plotdata(r).x(i,1),'mm/dd/yyyy');                %Show only the date.
        else                                                                %Otherwise...
            temp = [datestr(plotdata(r).x(i,1),'mm/dd/yyyy') '-' ...
                datestr(plotdata(r).x(i,2)-1,'mm/dd/yyyy')];                %Show the date range.
        end
        hoverdata(end).txt = {plotdata(r).rat,plotdata(r).s{i},...
            temp,plotdata(r).n{i}};                                         %Save the rat's name, stage, date, and hit rate/num trials.
        hoverdata(end).handles = l;                                         %Save the line handle for the point.
    end
end
temp = vertcat(hoverdata.xy);                                               %Grab all of the datapoint coordinates.
x = [min(temp(:,1)), max(temp(:,1))];                                       %Find the minimim and maximum x-values.
x = x + [-0.05,0.05]*(x(2) - x(1));                                         %Add some padding to the x-axis limits.
if length(x) < 2 || any(isnan(x))                                           %If there are any missing x values.
    x = now + [-1,1];                                                       %Set arbitrary x-axis limits.
end
if x(1) == x(2)                                                             %If the x-axis limits are the same...
    x = x + [-1,1];                                                         %Add a day to each side of the single point.
end
xlim(ax,x);                                                                 %Set the x-axis limits.
y = [min(temp(:,2)), max(temp(:,2))];                                       %Find the minimim and maximum x-values.
y = y + [-0.05,0.05]*(y(2) - y(1));                                         %Add some padding to the y-axis limits.
if length(y) < 2 || any(isnan(y))                                           %If there are any missing y values.
    y = [0,1];                                                              %Set arbitrary y-axis limits.
end
if y(1) == y(2)                                                             %If the y-axis limits are the same...
    y = y + [-0.1, 0.1];                                                    %Add 0.1 to each side of the single point.
end
ylim(ax,y);                                                                 %Set the y-axis limits.
set(ax,'xticklabel',datestr(get(ax,'xtick'),'mm/dd'),...
    'fontsize',fontsize,'fontweight','bold','linewidth',linewidth);         %Show the date for each x-axis tick.
ylabel(ax,str,'fontweight','bold','fontsize',1.1*fontsize);                 %Label the x-axis.
temp = get(ax,'ytick');                                                     %Grab the y-axis ticks.
for i = 1:length(temp)                                                      %Step through the y-axis ticks.
    temp(i) = line(xlim(ax),temp(i)*[1,1],'color',[0.75 0.75 0.75],...
        'linestyle','--','linewidth',0.5*linewidth,'userdata',3,...
        'parent',ax);                                                       %Draw a gridline at each y-tick.
end
uistack(temp,'bottom');                                                     %Send all grid lines to the bottom.
txt = text(x(1),y(1),' ','fontsize',fontsize,'margin',2,...
    'backgroundcolor','w','edgecolor','k','visible','off',...
    'verticalalignment','bottom','horizontalalignment','center',...
    'userdata',4);                                                          %Create a text object for labeling points.
set(fig,'WindowButtonMotionFcn',{@MouseHover,ax,hoverdata,txt});            %Set the mouse hover function for the figure.
% set(fig,'ButtonDownFcn', {@TrialViewer,ax,hoverdata,txt});

%% This function executes while the mouse hovers over the axes of an interactive figure.
function MouseHover(~,~,ax,data,txt)
xy = get(ax,'CurrentPoint');                                                %Grab the current mouse position in the axes.
xy = xy(1,1:2);                                                             %Pare down the x-y coordinates matrix.
a = [get(ax,'xlim'), get(ax,'ylim')];                                       %Grab the x- and y-axis limits.
if xy(1) >= a(1) && xy(1) <= a(2) && xy(2) >= a(3) && xy(2) <= a(4)         %If the mouse was clicked inside the axes...
    fig = get(ax,'parent');                                                 %Grab the parent figure of the axes.
    set(fig,'units','centimeters');                                         %Set the figure units to centimeters
    pos = get(fig,'position');                                              %Grab the current figure size, in centimeters.
    markersize = 0.75*pos(4);                                               %Set the marker size for the plots.
    xy = (xy - a([1,3]))./[a(2) - a(1), a(4) - a(3)];                       %Normalize the mouse x-y coordinates.
    temp = vertcat(data.xy);                                                %Vertically concatenate the point x-y coordinates.
    temp(:,1) = (temp(:,1) - a(1))/(a(2) - a(1));                           %Normalize the point x coordinates.
    temp(:,2) = (temp(:,2) - a(3))/(a(4) - a(3));                           %Normalize the point 3 coordinates.
    set(ax,'units','centimeters');                                          %Set the axes position units to centimeters.
    a = get(ax,'position');                                                 %Get the axes position.
    xy = xy.*a(3:4);                                                        %Calculate the axes position in centimeters.
    temp(:,1) = a(3)*temp(:,1);                                             %Calculate the point x coordinates in centimeters
    temp(:,2) = a(4)*temp(:,2);                                             %Calculate the point y coordinates in centimeters
    d = [xy(1) - temp(:,1), xy(2) - temp(:,2)];                             %Calculate the x-y distances from the mouse to the points.
    d = sqrt(sum(d.^2,2));                                                  %Find the straight-line distance to each point.
    if any(d <= 0.5)                                                        %If we're within half a centimeter of any data point...
        i = find(d == min(d),1,'first');                                    %Find the closest point.
        xy = data(i).xy;                                                    %Grab the data point x-y coordinate.
        temp = xlim(ax);                                                    %Grab the x-axis limits.
        if xy(1) < temp(1) + 0.25*(temp(2) - temp(1))                       %If the data point is in the left-most quartile...
            set(txt,'horizontalalignment','left');                          %Set the horizontal alignment to left-hand.
        elseif xy(1) > temp(1) + 0.75*(temp(2) - temp(1))                   %If the data point is in the right-most quartile...
            set(txt,'horizontalalignment','right');                         %Set the horizontal alignment to right-hand.
        else                                                                %Otherwise...
            set(txt,'horizontalalignment','center');                        %Set the horizontal alignment to centered.
        end
        if xy(2) > mean(ylim(ax))                                           %If the data point is in the top half...
            xy(2) = xy(2) - 0.05*range(ylim);                               %Adjust the y coordinate to place the text below the data point.
            set(txt,'verticalalignment','top');                             %Set the vertical alignment to top.
        else                                                                %Otherwise...
            xy(2) = xy(2) + 0.05*range(ylim);                               %Adjust the y coordinate to place the text above the data point.
            set(txt,'verticalalignment','bottom');                          %Set the vertical alignment to bottom.
        end
        temp = get(txt,'position');                                         %Grab the current text object position.
        str = get(txt,'string');                                            %Grab the rat's name.
        if ~isequal(xy,temp) || ~strcmpi(str,data(i).txt)                   %If the current label is incorrect...
            set(txt,'position',xy,'string',data(i).txt,'visible','on');     %Update the position, string, and visibility of the text object.
            set(data(i).handles,'markersize',2*markersize);                 %Make the selected marker larger.
            set(setdiff([data.handles],data(i).handles),...
                'markersize',markersize);                                   %Make the other markers smaller.
        end
    else                                                                    %Otherwise...
        set([data.handles],'markersize',markersize);                        %Make all markers smaller.
        set(txt,'visible','off');                                           %Make the text object invisible.
    end
end

%% This function is called whenever the main figure is resized.
function Resize(hObject,~,ax,obj)
set(hObject,'units','centimeters');                                         %Set the figure units to centimeters
pos = get(hObject,'position');                                              %Grab the current figure size, in centimeters.
w = pos(3);                                                                 %Grab the width of the figure.
h = pos(4);                                                                 %Grab the height of the figure.
ui_h = 0.07*h;                                                              %Set the heigh of all uicontrols.
sp1 = 0.02*h;                                                               %Set the vertical spacing between axes and uicontrols.
sp2 = 0.01*w;                                                               %Set the horizontal spacing between axes and uicontrols.
fontsize = 0.6*28.34*ui_h;                                                  %Set the fontsize for all uicontrols.
pos = [7*sp2,3*sp1,w-8*sp2,h-ui_h-5*sp1];                                   %Create an axes position matrix.
set(ax,'units','centimeters','position', pos);                              %Reset the position of the axes.
pos = [sp2, h-sp1-ui_h, 2*(w-6*sp2)/6, ui_h];                               %Create the position matrix for the pop-up menu.
set(obj(1),'units','centimeters','position',pos,'fontsize',fontsize);       %Set the position of the pop-up menu.
for i = 2:5                                                                 %Step through the timescale and export pushbuttons.      
    pos = [i*sp2+i*(w-6*sp2)/6, h-sp1-ui_h, (w-6*sp2)/6, ui_h];             %Create the position matrix for each pushbutton.
    set(obj(i),'units','centimeters','position',pos,'fontsize',fontsize);   %Set the pushbutton position and fontsize.
end
linewidth = 0.1*h;                                                          %Set the linewidth for the plots.
markersize = 0.75*h;                                                        %Set the marker size for the plots.
fontsize = 0.6*h;                                                           %Set the fontsize for all text objects.
obj = get(ax,'children');                                                   %Grab all children of the axes.
temp = vertcat(get(obj,'userdata'));                                        %Vertically concatenate the 'UserData' from each objects.
temp = vertcat(temp{:});                                                    %Change the 'UserData' from a cell array to matrix.
i = strcmpi(get(obj,'type'),'line') & temp == 1;                            %Find all plot line objects.
set(obj(i),'linewidth',linewidth);                                          %Set the linewidth for all plot line objects.
i = strcmpi(get(obj,'type'),'line') & temp == 2;                            %Find all plot marker objects.
set(obj(i),'markersize',markersize);                                        %Set the markersize for all plot line objects.
i = strcmpi(get(obj,'type'),'line') & temp == 3;                            %Find all grid line objects.
set(obj(i),'linewidth',0.5*linewidth);                                      %Set the linewidth for all grid line objects.
i = strcmpi(get(obj,'type'),'text');                                        %Find all text objects.
set(obj(i),'fontsize',fontsize);                                            %Set the font size for all text objects.
set(ax,'fontsize',fontsize,'linewidth',linewidth);                          %Set the axes linewidth and fontsize.
temp = get(ax,'ylabel');                                                    %Grab the y-axis label handle for the axes.
set(temp,'fontsize',1.1*fontsize);                                          %Set the font size for y-axis label.

%% This function is called whenever a point is selected in General Analysis
function TrialViewer(hObject,~,plotdata,i,TrialViewerData)
choice = questdlg('Would you like to view each trial of this session?',...
    'Analyze Data',...
    'Yes', 'No', 'No');
switch choice
    case 'Yes'
        Files = TrialViewerData.files;
        a = find(Files{i} == '\',1,'last');                                     %Find the last forward slash in the filename.
        files = Files{i}(a+1:end);                                               %Grab the filename minus the path.
        path = Files{i}(1:a);
        MotoTrak_Supination_Viewer_Edit(files,path)
end
