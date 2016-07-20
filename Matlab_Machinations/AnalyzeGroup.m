function AnalyzeGroup(varargin)
handles.datapath = 'C:\AnalyzeGroup\';                                         %Set the primary local data path for saving data files.
if ~exist(handles.datapath,'dir')                                           %If the primary local data path doesn't already exist...
    mkdir(handles.datapath);                                                %Make the primary local data path.
end

cd(handles.datapath);
Info = dir(handles.datapath);
choice = questdlg('Would you like to create a new experiment or choose from an existing one?',...
    'Choose or Create Experiment',...
    'New Experiment', 'Existing Experiment', 'Cancel');

switch choice
    case 'New Experiment'
        prompt = {'Experiment Name', 'Group Names'};
        dlg_title = 'Create New Experiment';
        ExperimentInfo = inputdlg(prompt,dlg_title,[1 50; 1 50]);
        Groups = strsplit(ExperimentInfo{2});
        mkdir(ExperimentInfo{1});
        temp = [handles.datapath ExperimentInfo{1}];
        cd(temp);
        for i = 1:length(Groups);
            mkdir(temp, Groups{i});
        end
        datapath = uigetdir(handles.datapath,'Where is your experiment data located?');       %Ask the user where their data is located.
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
        rats = files;
        rats2 = files;
        for r = 1:length(rats)                                                      %Step through each file.
            rats{r}(1:find(rats{r} == '\' | rats{r} == '/',1,'last')) = [];         %Kick out the path from the filename.
            rats2{r}(1:find(rats2{r} == '\' | rats2{r} == '/',1,'last')) = [];         %Kick out the path from the filename.
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
        files(keepers == 0) = [];
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
                data(s).filenames = rats2{f};
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
                plotdata(r).filenames = cell(1,length(i));
                for s = 1:length(i)                                                 %Step through each session.
                    plotdata(r).peak(s) = mean(data(i(s)).peak);                    %Save the mean signal peak for each session.
                    plotdata(r).impulse(s) = mean(data(i(s)).impulse);              %Save the mean signal impulse peak for each session.
                    plotdata(r).hitrate(s) = mean(data(i(s)).outcome == 'H');       %Save the hit rate for each session.
                    plotdata(r).numtrials(s) = length(data(i(s)).outcome);          %Save the total number of trials for each session.
                    plotdata(r).stage{s} = data(i(s)).stage;                        %Save the stage for each session.
                    plotdata(r).files{s} = data(i(s)).files;
                    plotdata(r).filenames{s} = data(i(s)).filenames;
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
        end
        uiwait(msgbox('Great! Please assign subjects to each experimental group now.'));        
        Counter = 1;
        for g = 1:length(Groups);
            GG = listdlg('PromptString',['Group ' Groups{g} ' rats'],...
                'name','Subject Assignment',...
                'SelectionMode','multiple',...
                'listsize',[250 250],...
                'initialvalue',1:length(rat_list),...
                'uh',25,...
                'ListString',rat_list);
            %             pos = get(0,'Screensize');
            %             h = 10;
            %             w = 8;
            %             fig = figure('numbertitle', 'off', 'units', 'centimeters',...
            %                 'name', ['Assign Subjects to ' Groups{g}], 'menubar', 'none',...
            %                 'position', [pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
            %             for r = 1:length(rat_list);
            %                 Subject(r) = uicontrol('Parent', fig, 'Style', 'text', 'String', ['Subject ' rat_list{r}], ...
            %                     'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.2, 1-r*.072, .3, .05],...
            %                     'Fontsize', 10, 'Fontweight', 'bold') ;
            %                 Experimental_Group(r) = uicontrol(fig,'style','popup','string',Groups,'HorizontalAlignment', 'left',...
            %                     'units','normalized','position',[.5, 1-r*.07, .3, .05],'fontsize',10,'callback', {@ExperimentalGroup,r});
            %             end
            %             Done = uicontrol('Parent', fig', 'Style', 'pushbutton', 'String', 'Done','callback', {@All_Finished},...
            %                 'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.4, 1-(r+3)*.07, .2, .1]);
            if isempty(g)                                                               %If the user clicked "cancel" or closed the dialog...
                return                                                                  %Skip execution of the rest of the function.
            else                                                                        %Otherwise...
                handles(g).path = ['C:\AnalyzeGroup\' ExperimentInfo{1} '\' Groups{g}];
                handles(g).rat_list = rat_list(GG);                                                 %Pare down the rat list to those that the user selected.
%                 for r = 1:length(GG);
%                     SubjectNames{Counter} = [handles(g).rat_list{r} ' (' Groups{g} ')'];
%                     Counter = Counter + 1;
%                 end
            end
            
            for r = 1:length(handles(g).rat_list)
                cd(handles(g).path)
                mkdir(handles(g).rat_list{r});
                temp = [handles(g).path '\' handles(g).rat_list{r} '\'];
                cd(temp)              
                temp2 = [datapath '\' handles(g).rat_list{r}];
                copyfile(temp2,temp);
%                 Counter = Counter + 1;
            end
            
        end
    case 'Existing Experiment'
        uiwait(msgbox('Existing Experiment'));
end

path = 'C:\AnalyzeGroup';    

pos = get(0,'Screensize');                                              %Grab the screensize.
h = 10;                                                                 %Set the height of the figure, in centimeters.
w = 20;                                                                 %Set the width of the figure, in centimeters.
fig = figure('numbertitle','off','units','centimeters',...
    'name','MotoTrak Analysis: Analyze Group','menubar','none',...
    'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
% Table = readtable('TestFile2.txt');
% ExperimentNames = Table{:,1};
% SubjectNames = Table{:,2};
ExperimentNames = {'Test'};
% SubjectNames = {};

Subjects = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','min', 0,'max',25,...
    'string','Test', 'units', 'normalized', 'Position', [.0475 .05 .27 .7], 'Fontsize', 11);
Subjects_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Subjects:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.0475 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Groups = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Groups', 'units', 'normalized', 'Position', [.365 .05 .27 .7], 'Fontsize', 11);
Groups_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Groups:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.365 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Experiment = uicontrol(fig,'style','popup','string',ExperimentNames,...
        'units','normalized','position',[.15 .91 .25 .05],'fontsize',12,...
        'callback',{@ExperimentCallback,SubjectNames,Subjects,Groups});
Experiment_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Experiment:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.01 .9 .13 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Events = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Events', 'units', 'normalized', 'Position', [.6825 .05 .27 .7], 'Fontsize', 11);
Events_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Events:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.6825 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Make_Plot = uicontrol('Parent', fig, 'Style', 'pushbutton', 'HorizontalAlignment', 'left',...
    'string','Plot', 'units', 'normalized', 'Position', [.82 .86 .15 .1], 'Fontsize', 12);

function ExperimentCallback(hObject,~,SubjectNames,Subjects,Groups)
Table = readtable('TestFile.txt');
index_selected = get(hObject,'value');
if index_selected == length(hObject.String);
%     uiwait(msgbox('Hello'));
    prompt = {'Experiment Name', 'Subject Names', 'Groups'};
    dlg_title = 'Create New Experiment';
    answer = inputdlg(prompt,dlg_title,[1 50; 1 50; 1 50]);
    hObject.String(length(hObject.String)) = answer(1,:);
    hObject.String(length(hObject.String)+1) = {'Create New Experiment'};    
    SubjectNames = strsplit(answer{2,:});
    GroupNames = strsplit(answer{3,:});
    set(Subjects,'string',SubjectNames);
    set(Groups,'string',GroupNames);
    Table{end,1} = answer(1,:); Table{end,2} = answer(2,:);
    Table{size(Table,1)+1,1} = {'Create New Experiment'};
    Table{size(Table,1)+1,2} = {''};
%     save('TestFile.txt', Table)
else
    SubjectNames = SubjectNames{index_selected,:};
    SubjectNames = strsplit(SubjectNames);
    set(Subjects,'string',SubjectNames);
end

function ExperimentalGroup(hObject,~,r)
index_selected = get(hObject,'value');
uiwait(msgbox('Hello'));

