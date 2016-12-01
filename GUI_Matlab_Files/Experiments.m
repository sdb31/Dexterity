function Experiments(varargin)
datapath = 'C:\AnalyzeGroup\';                                         %Set the primary local data path for saving data files.
if ~exist(datapath,'dir')                                           %If the primary local data path doesn't already exist...
    mkdir(datapath);                                                %Make the primary local data path.
end

% cd(datapath);
Info = dir(datapath);

choice = questdlg('Would you like to create a new experiment or choose from an existing one?',...
    'Choose or Create Experiment',...
    'New Experiment', 'Existing Experiment', 'Cancel');


switch choice
    case 'New Experiment'
        prompt = {'Experiment Name', 'Group Names', 'Event Data', 'Total Weeks'};
        dlg_title = 'Create New Experiment';
        ExperimentInfo = inputdlg(prompt,dlg_title,[1 50; 1 50; 1 50; 1 20]);
        Groups = strsplit(ExperimentInfo{2});
        Events = strsplit(ExperimentInfo{3});
        Weeks = str2num(ExperimentInfo{4});
        mkdir(ExperimentInfo{1});
        temp = [datapath ExperimentInfo{1}];
        cd(temp);
        mkdir('TreatmentGroups');
        temp = [temp '\TreatmentGroups'];
        for i = 1:length(Groups);
            mkdir(temp, Groups{i});
        end
        
        %% Find all of the MotoTrak data files in the data path.
        datapath = uigetdir(datapath,'Where is your experiment data located?');       %Ask the user where their data is located.
        if datapath(1) == 0                                                         %If the user pressed "cancel"...
            return                                                                  %Skip execution of the rest of the function.
        end
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
        for d = 1:length(rat_list)
            dispfiles(d).files = [];
            dispfiles(d).realfiles = [];
        end
        for q = 1:length(files)
            r = 1;
            temp = [char(rat_list(r)) '_'];
            t = strfind(files{q},temp);
            %             if length(t) == 1;
            %                 t = [];
            %             end
            while isempty(t) == 1;
                r = r + 1;
                temp = [char(rat_list(r)) '_'];
                t = strfind(files{q},temp);
                %                 if length(t) == 1;
                %                     t = [];
                %                 end
            end
            if length(t) > 2
                temp = length(t) - 1;
                t = t(temp);
            elseif length(t) == 2
                temp = 2;
                t = t(temp);
            else
                t = t(1);
            end
            Count = length(dispfiles(r).files);
            Count = Count + 1;
            dispfiles(r).files{Count} = files{q}(t:end);
            dispfiles(r).realfiles{Count} = files{q};
        end
        
        for d = 1:length(dispfiles)
            test = listdlg('PromptString', ['Which files would you like to include for Animal ' rat_list{d} '?'],...
                'name','File Selection',...
                'SelectionMode','multiple',...
                'listsize',[500 500],...
                'initialvalue',1:length(dispfiles(d).files),...
                'ListString',dispfiles(d).files);
            dispfiles(d).files = dispfiles(d).files(test);
            dispfiles(d).realfiles = dispfiles(d).realfiles(test);
        end
        Counter = 1;
        for d = 1:length(dispfiles);
            for f = 1:length(dispfiles(d).realfiles);
                TestFiles(Counter) = dispfiles(d).realfiles(f);
                Counter = Counter + 1;
            end
        end
        files = TestFiles;
        %% Step through all of the data files and load them into a structure.
        set(0,'units','centimeters');                                               %Set the system units to centimeters.
        pos = get(0,'Screensize');                                                  %Grab the screensize.
        h = 2;                                                                      %Set the height of the figure.
        w = 15;                                                                     %Set the width of the figure.
        fig = figure('numbertitle','off','name','Loading and Processing MotoTrak Files...',...
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
            %     if isfield(temp,'trial') && length(temp.trial) >= 5 && ...
            if any(strcmpi(rat_list,temp.rat))                                 %If there were at least 5 trials...
                s = length(data) + 1;                                               %Create a new field index.
                for field = {'rat','device','stage'}                               %Step through the fields we want to save from the data file...
                    data(s).(field{1}) = temp.(field{1});                           %Grab each field from the data file and save it.
                end
                if isfield(temp,'trial') == 0;
                    KeepFile = questdlg(['There is no data in this file: ' files{f}(a+1:end)],...
                        'Keep or Discard File',...
                        'Keep', 'Discard', 'Discard');
                    switch KeepFile
                        case 'Keep'
                            data(s).outcome = NaN;
                            data(s).thresh = NaN;
                            data(s).starttime = NaN;
                            data(s).peak = NaN;
                            data(s).impulse = NaN;
                            data(s).latency_to_hit = NaN;
                            data(s).raw_peak_velocity = NaN;
                            data(s).peak_velocity = NaN;
                            data(s).timestamp = temp.daycode;
                        case 'Discard'
                            data(s) = [];
                    end
                else
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
                    data(s).trial = temp.trial;
                    data(s).threshtype = temp.threshtype;
                    data(s).files = files{f};
                    data(s).filenames = files{f}(a+1:end);
                    %         end
                    data(s).files = files{f};
                    for t = 1:length(data(s).trial)                                            %Step through each trial.
                        a = find((data(s).trial(t).sample_times < 1000*data(s).trial(t).hitwin));       %Find all samples within the hit window.
                        if strcmpi(data(s).threshtype,'degrees (bidirectional)')               %If the threshold type is bidirectional knob-turning...
                            signal = abs(data(s).trial(t).signal(a) - ....
                                data(s).trial(t).signal(1));                                   %Subtract the starting degrees value from the trial signal.
                        elseif strcmpi(data(s).threshtype,'# of spins')                        %If the threshold type is the number of spins...
                            temp = diff(data(s).trial(t).signal);                              %Find the velocity profile for this trial.
                            temp = boxsmooth(temp,10);                                      %Boxsmooth the wheel velocity with a 100 ms smooth.
                            [pks,i] = PeakFinder(temp,10);                                  %Find all peaks in the trial signal at least 100 ms apart.
                            i(pks < 1) = [];                                                %Kick out all peaks that are less than 1 degree/sample.
                            i = intersect(a,i+1)-1;                                         %Find all peaks that are in the hit window.
                            signal = length(i);                                             %Set the trial signal to the number of wheel spins.
                        elseif strcmpi(data(s).threshtype, 'degrees (total)')
                            signal = data(s).trial(t).signal(a);
                        else
                            signal = data(s).trial(t).signal(a) - data(s).trial(t).signal(1);    %Grab the raw signal for the trial.
                        end
                        %             smooth_trial_signal = boxsmooth(signal);
                        %             smooth_knob_velocity = boxsmooth(diff(smooth_trial_signal));                %Boxsmooth the velocity signal
                        GOLAY_smooth_trial_signal = sgolayfilt(signal,5,7);
                        GOLAY_smooth_knob_velocity = sgolayfilt(diff(GOLAY_smooth_trial_signal),5,7);
                        %             data(s).peak_velocity(t) = max(smooth_knob_velocity);
                        data(s).raw_peak_velocity(t) = max(diff(signal));
                        data(s).sgolayfilter_PV(t) = max(GOLAY_smooth_knob_velocity);
                        %             knob_acceleration = boxsmooth(diff(smooth_knob_velocity));
                        %             data(s).peak_acceleration(t) = max(knob_acceleration);
                        if (data(s).trial(t).outcome == 72)                                   %If it was a hit
                            hit_time = find(data(s).trial(t).signal >= ...                    %Calculate the hit time
                                data(s).trial(t).thresh,1);
                            if isempty(hit_time) == 1
                                hit_time = 1;
                            end
                            data(s).latency_to_hit(t) = hit_time;                       %hit time is then latency to hit
                        else
                            data(s).latency_to_hit(t) = NaN;                            %If trial resulted in a miss, then set latency to hit to NaN
                        end
                    end
                    %         data(s).peak_velocity = nanmean(data(s).peak_velocity);
                    %         data(s).peak_acceleration = nanmean(data(s).peak_acceleration);
                    data(s).latency_to_hit = nanmean(data(s).latency_to_hit);
                    data(s).raw_peak_velocity = nanmean(data(s).raw_peak_velocity);
                    data(s).peak_velocity = nanmean(data(s).sgolayfilter_PV);
                end
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
                plotdata(r).peak_velocity = nan(1,length(i));
                plotdata(r).latency = nan(1,length(i));
                for s = 1:length(i)                                                 %Step through each session.
                    plotdata(r).peak(s) = mean(data(i(s)).peak);                    %Save the mean signal peak for each session.
                    plotdata(r).impulse(s) = mean(data(i(s)).impulse);              %Save the mean signal impulse peak for each session.
                    plotdata(r).hitrate(s) = mean(data(i(s)).outcome == 'H');       %Save the hit rate for each session.
                    plotdata(r).numtrials(s) = length(data(i(s)).outcome);          %Save the total number of trials for each session.
                    plotdata(r).stage{s} = data(i(s)).stage;                        %Save the stage for each session.
                    plotdata(r).files{s} = data(i(s)).files;
                    plotdata(r).filenames{s} = data(i(s)).filenames;
                    plotdata(r).peak_velocity(s) = data(i(s)).peak_velocity;
                    plotdata(r).latency(s) = data(i(s)).latency_to_hit;
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
        for r = 1:length(plotdata);
            temp_hitrate = isnan(plotdata(r).hitrate);
            temp_peak = isnan(plotdata(r).peak);
            if ~isempty(find(temp_hitrate == 1, 1)) == 1;
                plotdata(r).hitrate(temp_hitrate) = 0;
                plotdata(r).peak(temp_peak) = 0;
            end
        end
        uiwait(msgbox('Great! Please assign subjects to each experimental group now.', 'Proceed to Subject Assignment'));
        %         Counter = 1;
        AnimalName = cell(1,length(rat_list));
        SessionsInfo = cell(1,length(rat_list));
        for g = 1:length(Groups);
            GG = listdlg('PromptString',['Group: ' Groups{g}],...
                'name','Subject Assignment',...
                'SelectionMode','multiple',...
                'listsize',[250 250],...
                'initialvalue',1:length(rat_list),...
                'uh',25,...
                'ListString',rat_list);
            if isempty(g)                                                               %If the user clicked "cancel" or closed the dialog...
                return                                                                  %Skip execution of the rest of the function.
            else                                                                        %Otherwise...
                handles(g).path = ['C:\AnalyzeGroup\' ExperimentInfo{1} '\TreatmentGroups\' Groups{g}];
                handles(g).rat_list = rat_list(GG);                                                 %Pare down the rat list to those that the user selected.
                handles(g).GroupName = Groups{g};
            end
            
            for r = 1:length(handles(g).rat_list)
                cd(handles(g).path)
                mkdir(handles(g).rat_list{r});
                temp = [handles(g).path '\' handles(g).rat_list{r} '\'];
                cd(temp)
                %                 temp2 = [datapath '\' handles(g).rat_list{r}];
                %                 copyfile(temp2,temp);
                temp3 = ['Number of sessions per week over ' num2str(Weeks) ' weeks for Animal ' handles(g).rat_list{r}];
                dlg_title = 'Session per Week';
                SessionsInfo(GG(r)) = inputdlg(temp3, dlg_title, [1 50]);
                AnimalName(GG(r)) = handles(g).rat_list(r);
                %                 Counter = Counter + 1;
            end
        end
        FilePath = ['C:\AnalyzeGroup\' ExperimentInfo{1}];
        cd(FilePath);
        mkdir('ConfigFiles');
        FilePath = [FilePath '\ConfigFiles'];
        cd(FilePath);
        config.weeks = Weeks;
        %         config.events = ExperimentInfo{3}; config.events = {config.events};
        config.events = Events;
        config.devices = devices;
        config.plotdata = plotdata;
        xlabels = inputdlg('What are your xlabels?','XLabels', [1 50]);
        config.xlabels = strsplit(xlabels{:});
        for i = 1:length(config.events);
            event_location = listdlg('PromptString', ['Where does ' config.events{i} ' occur ?'],...
                'name','Event Location',...
                'SelectionMode','multiple',...
                'listsize',[250 100],...
                'initialvalue',1,...
                'ListString',config.xlabels);
            config.event_location(i) = event_location;
        end
        for m = 1:length(rat_list);
            config.animal(m).name = AnimalName{m};
            config.animal(m).sessions = SessionsInfo{m};
        end
        filename = [ExperimentInfo{1} 'Config.mat'];
        save(filename, 'config');
end

if isempty(choice) == 1;
    return
else
path = 'C:\AnalyzeGroup';    
% cd(path);
Info = dir(path);
ExperimentNames = {Info.name};
ExperimentNames = ExperimentNames(3:end);
for i = 1:length(ExperimentNames);
   Counter = 1;
   testpath = {};
   testpath = ['C:\AnalyzeGroup\' ExperimentNames{i} '\TreatmentGroups'] ;
   Info_Groups = dir(testpath);
   GroupNames = {Info_Groups.name};
   GroupNames = GroupNames(3:end);
   GUI_GroupNames{i} = GroupNames;
   for k = 1:length(GroupNames)
       subjectpath = {};
       subjectpath = [testpath '\' GroupNames{k}];
       Info_Subjects = dir(subjectpath);
       SubjectNames = {Info_Subjects.name};
       handles(k).SubjectNames = SubjectNames(3:end);
       for t = 1:length(handles(k).SubjectNames);
          GUI_Subjects{i,Counter} = [handles(k).SubjectNames{t} ' (' GroupNames{k} ')']; 
          Counter = Counter + 1;
       end
   end
end

pos = get(0,'Screensize');                                              %Grab the screensize.
h = 10;                                                                 %Set the height of the figure, in centimeters.
w = 20;                                                                 %Set the width of the figure, in centimeters.
fig = figure('numbertitle','off','units','centimeters',...
    'name','Dexterity: Experiments','menubar','none',...
    'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);

Subjects = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','min', 0,'max',25,...
    'string','Subjects', 'units', 'normalized', 'Position', [.0475 .05 .27 .7], 'Fontsize', 11);
Subjects_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Subjects:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.0475 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Groups = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Groups', 'units', 'normalized', 'Position', [.365 .45 .27 .3], 'Fontsize', 11);
Groups_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Groups:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.365 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Labels = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Labels', 'units', 'normalized', 'Position', [.52375 .05 .27 .3], 'Fontsize', 11);
Labels_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'XLabels:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.52375 .37 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Experiment = uicontrol(fig,'style','popup','string',ExperimentNames,...
        'units','normalized','position',[.15 .91 .25 .05],'fontsize',12);
Experiment_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Experiment:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.01 .9 .13 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Events = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Events', 'units', 'normalized', 'Position', [.6825 .45 .27 .3],'Fontsize', 11);
Events_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Events:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.6825 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Plot = uicontrol('Parent', fig, 'Style', 'pushbutton', 'HorizontalAlignment', 'left',...
    'string','Plot', 'units', 'normalized', 'Position', [.82 .86 .15 .1], 'Fontsize', 12);
set(Experiment,'callback', {@ExperimentCallback,GUI_Subjects,GUI_GroupNames,ExperimentNames,Subjects,Groups,Events,Labels});
set(Plot, 'callback', {@PlotButton,Experiment,ExperimentNames});
end

%% This function is called whenever the Plot button is selected
function PlotButton(hObject,~, Experiment,ExperimentNames)
index_selected = get(Experiment,'value');
SelectedExperiment = ExperimentNames(index_selected);
temp = ['C:\AnalyzeGroup\' SelectedExperiment{:} '\ConfigFiles\'];
% cd(temp);
temp = [temp SelectedExperiment{:} 'Config.mat'];
load(temp);
devices = config.devices;
data = config.plotdata;
% % Calculate training days
% for r = 1:length(data);
%    clear temp
%    for l = 1:length(data(r).times)
%        temp(l) = {datestr(data(r).times(l),1)};
%    end
%    data(r).training_days = length(unique(temp)); 
% end
Weeks = config.weeks;
AnimalData = config.animal;
EventData.name = config.events; EventData.location = config.event_location;
xlabels = config.xlabels;
pos = get(0,'Screensize');                                              %Grab the screensize.
h = 10;                                                                 %Set the height of the figure, in centimeters.
w = 15;                                                                 %Set the width of the figure, in centimeters.
Plotvalue = {};
Grayscale_string = 'Color';
for d = 1:length(devices)                                                   %Step through the devices.
    fig = figure('numbertitle','off','units','centimeters',...
        'name',['Dexterity: Group Analysis'],'menubar','none',...
        'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);                     %Create a figure.
    ui_h = 0.07*h;                                                          %Set the heigh of the uicontrols.
    fontsize = 0.6*28.34*ui_h;                                              %Set the fontsize for all uicontrols.
    sp1 = 0.02*h;                                                           %Set the vertical spacing between axes and uicontrols.
    sp2 = 0.01*w;                                                           %Set the horizontal spacing between axes and uicontrols.
    pos = [8*sp2,8*sp1,w-10*sp2,h-ui_h-10.5*sp1];                               %Set the position of the axes.
    ax = axes('units','centimeters','position',pos,'box','on',...
        'linewidth',2);                                                     %Create axes for showing the log events histogram.
    obj = zeros(1,6);                                                       %Create a matrix to hold timescale uicontrol handles.
    str = {'Overall Hit Rate',...
        'Dummy1',...
        'Dummy2',...
        'Trial Count',...
        'Peak Velocity',...
        'Latency to Hit'};
    %         'Hits in First 5 Minutes',...
    %         'Trials in First 5 Minutes',...
    %         'Max. Hits in Any 5 Minutes',...
    %         'Max. Trials in Any 5 Minutes',...
    %         'Max. Hit Rate in Any 5 Minutes',...
    %         'Min. Inter-Trial Interval (Smoothed)',...
    %         'Mean Peak Impulse',...
    %         'Median Peak Impulse'};                                             %List the available plots for the pull data.
    if any(strcmpi(devices{d},{'knob','lever'}))                            %If we're plotting knob data...
        str(2:3) = {'Mean Peak Angle','Median Peak Angle'};                 %Set the plots to show "angle" instead of "force".
    elseif ~any(strcmpi(devices{d},{'knob','lever','pull'}))                %Otherwise, if this isn't pull, knob, or lever data...
        str(2:3) = {'Mean Signal Peak','Median Signal Peak'};               %Set the plots to show "signal" instead of "peak force".
    end
    pos = [sp2, h-sp1-ui_h, 2*(w-6*sp2)/6, ui_h];                           %Set the position for the pop-up menu.
    obj(1) = uicontrol(fig,'style','popup','string',str,...
        'units','centimeters','position',pos,'fontsize',fontsize);      %Create pushbuttons for selecting the timescale.
    pos = [5*sp2+5*(w-6*sp2)/6, h-sp1-ui_h, (w-6*sp2)/6, ui_h]; 
    obj(2) = uicontrol(fig,'style','pushbutton','string','Export',...
        'units','centimeters','position',pos,'fontsize',fontsize);
    pos = [30*sp2, .95*sp1, (w-6*sp2)/6, .9*ui_h]; 
%     bg = uibuttongroup(fig,'Position',pos,'SelectionChangedFcn',@graphselection);
    obj(3) = uicontrol(fig,'style','radiobutton','string','Line Graph',...
        'units','centimeters','position',pos,'fontsize',.8*fontsize);
    pos = [35*sp2+(w-6*sp2)/6, .95*sp1, (w-6*sp2)/6, .9*ui_h]; 
    obj(4) = uicontrol(fig,'style','radiobutton','string','Bar Graph',...
        'units','centimeters','position',pos,'fontsize',.8*fontsize);
    pos = [60*sp2+(w-6*sp2)/6, .95*sp1, (w-6*sp2)/6, .9*ui_h]; 
    obj(5) = uicontrol(fig,'style','pushbutton','string','Add Sig Stars',...
        'units','centimeters','position',pos,'fontsize',.8*fontsize);
    pos = [5*sp2, .95*sp1, (w-6*sp2)/6, .9*ui_h]; 
    obj(6) = uicontrol(fig,'style','radiobutton','string','Grayscale',...
        'units','centimeters','position',pos,'fontsize',.8*fontsize);
%     bg.Visible = 'on';
%     str = {'Export'};                            %List the timescale labels.
%     for i = 2:5                                                             %Step through the 3 timescales.
%         pos = [i*sp2+i*(w-6*sp2)/6, h-sp1-ui_h, (w-6*sp2)/6, ui_h];         %Set the position for each pushbutton.
%         obj(i) = uicontrol(fig,'style','pushbutton','string',str{i-1},...
%             'units','centimeters','position',pos,'fontsize',fontsize);      %Create pushbuttons for selecting the timescale.
%     end
    set(obj(1),'callback',{@Set_Plot_Type,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string});                            %Set the callback for the pop-up menu.
%     set(obj(2:4),'callback',{@Plot_Timeline,obj,[],data});                       %Set the callback for the timescale buttons.
    set(obj(2),'callback',{@Export_Data,ax,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,obj(3),Grayscale_string});                           %Set the callback for the export button.
    set(obj(3),'callback',{@Linegraph,obj(4),obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Grayscale_string},'Value',1);
    set(obj(4),'callback',{@Bargraph,obj(3),obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Grayscale_string});
    set(obj(5),'callback',{@Sigstars});
    set(obj(6),'callback',{@Grayscale,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string});
    set(fig,'userdata',data);                                           %Save the plot data to the figure's 'UserData' property.
    Plot_Timeline(obj(2),[],obj,[],data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string);                                        %Call the function to plot the session data in the figure.
    set(fig,'ResizeFcn',{@Resize,ax,obj});
end

function Grayscale(~,~,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string)
Plot_Timeline(obj(2),[],obj,[],data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string)

function Sigstars(~,~)
SigStarText = questdlg('How many sigstars would you like to use?',...
    'Number of Sigstars',...
    'One', 'Two', 'Three', 'Cancel');
switch SigStarText
    case 'One'
        t = '*';
    case 'Two'
        t = '**';
    case 'Three'
        t = '***';
end
gtext(t,'HorizontalAlignment', 'center');

function Linegraph(hObject,~,BarUI,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Grayscale_string)
Line_value = get(hObject, 'value');
Bar_value = get(BarUI, 'value');
if Line_value == 1;
    set(BarUI, 'value', 0);
elseif Line_value == 0 && Bar_value == 0;
    set(hObject, 'value', 1);
else
    set(BarUI, 'value', 1);
end
Plotvalue = 'Line';
Plot_Timeline(obj(2),[],obj,[],data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string);  

function Bargraph(hObject,~,LineUI,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Grayscale_string)
Bar_value = get(hObject, 'value');
Line_value = get(LineUI, 'value');
if Bar_value == 1;
    set(LineUI, 'value', 0);
elseif Bar_value == 0 && Line_value == 0;
    set(hObject,'value',1);
else
    set(LineUI, 'value', 1);
end
Plotvalue = 'Bar';
Plot_Timeline(obj(2),[],obj,[],data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string); 

%% This subfunction sorts the data into single-session values and sends it to the plot function.
function Plot_Timeline(hObject,~,obj,fid,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string)
path = 'C:\AnalyzeGroup';
% cd(path);
Info = dir(path);
for q = 1:length(AnimalData);
    Sessions(q,:) = str2num(AnimalData(q).sessions);
    Names(q) = {AnimalData(q).name};
end
for l = 1:size(Sessions,1);
    for m = 1:size(Sessions,2);
        SessionCount(l,m+1) = sum(Sessions(l,1:m));
    end
end
ExperimentNames = {Info.name};
ExperimentNames = ExperimentNames(3:end);
for i = 1:length(ExperimentNames);
    %    Counter = 1;
    testpath = {};
    testpath = ['C:\AnalyzeGroup\' ExperimentNames{i} '\TreatmentGroups'] ;
    Info_Groups = dir(testpath);
    GroupNames = {Info_Groups.name};
    GroupNames = GroupNames(3:end);
    %    GUI_GroupNames{i} = GroupNames;
    TimelineData(i).ExpName = ExperimentNames(i);
    for k = 1:length(GroupNames)
        subjectpath = {};
        subjectpath = [testpath '\' GroupNames{k}];
        Info_Subjects = dir(subjectpath);
        SubjectNames = {Info_Subjects.name};
        handles(k).SubjectNames = SubjectNames(3:end);
        TimelineData(i).Groups(k).name = GroupNames(k);
        for t = 1:length(handles(k).SubjectNames);
            %           GUI_Subjects{i,Counter} = [handles(k).SubjectNames{t} ' (' GroupNames{k} ')'];
            TimelineData(i).Groups(k).Subjects(t) = handles(k).SubjectNames(t);
            if i == index_selected;
                for l = 1:length(Names);
                    temp(l) = strcmpi(Names(l),handles(k).SubjectNames{t});
                end
%                 Loc = find(char(Names) == handles(k).SubjectNames{t});
                TimelineData(i).Groups(k).Sessions(t,:) = {AnimalData(temp).sessions};
                TimelineData(i).Groups(k).SessionCount(t) = {SessionCount(temp,:)};
            end
            %           Counter = Counter + 1;
        end
    end
end
for g = 1:length(TimelineData(index_selected).Groups);
    for s = 1:length(TimelineData(index_selected).Groups(g).Subjects);
        for l = 1:length(Names);
            temp(l) = strcmpi(Names(l),TimelineData(index_selected).Groups(g).Subjects{s});
        end
%         Loc = Names == TimelineData(index_selected).Groups(g).Subjects{s};
        TimelineData(index_selected).Groups(g).data.HitRate(s) = {data(temp).hitrate};
        TimelineData(index_selected).Groups(g).data.TotalTrialCount(s) = {data(temp).numtrials};
        TimelineData(index_selected).Groups(g).data.Peak(s) = {data(temp).peak};
        TimelineData(index_selected).Groups(g).data.Peak_Velocity(s) = {data(temp).peak_velocity};
        TimelineData(index_selected).Groups(g).data.Latency(s) = {data(temp).latency};
    end
%     Counter = 1;
    for s = 1:length(TimelineData(index_selected).Groups(g).Subjects);
        Sessions = cell2mat(TimelineData(index_selected).Groups(g).Sessions(s));
        Sessions = strsplit(Sessions);
        SessionCount = cell2mat(TimelineData(index_selected).Groups(g).SessionCount(s));
        for l = 1:length(Sessions);
            temp_hitrate = cell2mat(TimelineData(index_selected).Groups(g).data.HitRate(s));           
            temp_TrialCount = cell2mat(TimelineData(index_selected).Groups(g).data.TotalTrialCount(s));
            temp_Peak = cell2mat(TimelineData(index_selected).Groups(g).data.Peak(s));
            temp_Peak_Velocity = cell2mat(TimelineData(index_selected).Groups(g).data.Peak_Velocity(s));
            temp_Latency = cell2mat(TimelineData(index_selected).Groups(g).data.Latency(s));
            temp_meanhitrate(s,l) = nanmean(temp_hitrate((SessionCount(l)+1):SessionCount(l+1)));
            temp_hitratestd(s,l) = nanstd(temp_hitrate((SessionCount(l)+1):SessionCount(l+1)));
            temp_MeanTrialCount(s,l) = nanmean(temp_TrialCount((SessionCount(l)+1):SessionCount(l+1)));
            temp_meantrialcountstd(s,l) = nanstd(temp_TrialCount((SessionCount(l)+1):SessionCount(l+1)));
            temp_MeanPeak(s,l) = nanmean(temp_Peak((SessionCount(l)+1):SessionCount(l+1)));
            temp_meanpeakstd(s,l) = nanstd(temp_Peak((SessionCount(l)+1):SessionCount(l+1)));
            temp_MedianPeak(s,l) = nanmedian(temp_Peak((SessionCount(l)+1):SessionCount(l+1)));
            temp_medianpeakstd(s,l) = nanstd(temp_Peak((SessionCount(l)+1):SessionCount(l+1)));
            temp_MeanPeakVelocity(s,l) = nanmean(temp_Peak_Velocity((SessionCount(l)+1):SessionCount(l+1)));
            temp_meanpeakvelocitystd(s,l) = nanstd(temp_Peak_Velocity((SessionCount(l)+1):SessionCount(l+1)));
            temp_MeanLatency(s,l) = nanmean(temp_Latency((SessionCount(l)+1):SessionCount(l+1)));
            temp_meanlatencystd(s,l) = nanstd(temp_Latency((SessionCount(l)+1):SessionCount(l+1)));
        end
    end
    TimelineData(index_selected).Groups(g).data.PerAnimalHitRate = temp_meanhitrate;
    TimelineData(index_selected).Groups(g).data.PerAnimalMeanTrialCount = temp_MeanTrialCount;
    TimelineData(index_selected).Groups(g).data.PerAnimalMeanPeak = temp_MeanPeak;
    TimelineData(index_selected).Groups(g).data.PerAnimalMedianPeak = temp_MedianPeak;
    TimelineData(index_selected).Groups(g).data.PerAnimalMeanPeakVelocity = temp_MeanPeakVelocity;
    TimelineData(index_selected).Groups(g).data.PerAnimalMeanLatency = temp_MeanLatency;
%     PerAnimal(g).Hitrate = temp_meanhitrate;
%     PerAnimal(g).MeanTrialCount = temp_MeanTrialCount;
%     PerAnimal(g).MeanPeak = temp_MeanPeak;
%     PerAnimal(g).MedianPeak = temp_MedianPeak;
%     PerAnimal(g).MeanPeakVelocity = temp_MeanPeakVelocity;
%     PerAnimal(g).MeanLatency = temp_MeanLatency;
%     PerAnimal(g).Subjects = TimelineData.Groups(g).Subjects;
    
    if length(TimelineData(index_selected).Groups(g).Sessions) > 1;
        temp_hitratestd = nanstd(temp_meanhitrate);
        temp_meanhitrate = nanmean(temp_meanhitrate);
        temp_meantrialcountstd = nanstd(temp_MeanTrialCount);
        temp_MeanTrialCount = nanmean(temp_MeanTrialCount);
        temp_meanpeakstd = nanstd(temp_MeanPeak);
        temp_MeanPeak = nanmean(temp_MeanPeak);
        temp_medianpeakstd = nanstd(temp_MedianPeak);
        temp_MedianPeak = nanmedian(temp_MedianPeak);
        temp_meanpeakvelocitystd = nanstd(temp_MeanPeakVelocity);
        temp_MeanPeakVelocity = nanmean(temp_MeanPeakVelocity);
        temp_meanlatencystd = nanstd(temp_MeanLatency);
        temp_MeanLatency = nanmean(temp_MeanLatency);
    end
    TimelineData(index_selected).Groups(g).data.MeanHitRate = {temp_meanhitrate};
    TimelineData(index_selected).Groups(g).data.hitratestd = {temp_hitratestd};
    TimelineData(index_selected).Groups(g).data.MeanTrialCount = {temp_MeanTrialCount};
    TimelineData(index_selected).Groups(g).data.meantrialcountstd = {temp_meantrialcountstd};
    TimelineData(index_selected).Groups(g).data.MeanPeak = {temp_MeanPeak};
    TimelineData(index_selected).Groups(g).data.meanpeakstd = {temp_meanpeakstd};
    TimelineData(index_selected).Groups(g).data.MedianPeak = {temp_MedianPeak};
    TimelineData(index_selected).Groups(g).data.medianpeakstd = {temp_medianpeakstd};
    TimelineData(index_selected).Groups(g).data.MeanPeakVelocity = {temp_MeanPeakVelocity};
    TimelineData(index_selected).Groups(g).data.meanpeakvelocitystd = {temp_meanpeakvelocitystd};
    TimelineData(index_selected).Groups(g).data.MeanLatency = {temp_MeanLatency};
    TimelineData(index_selected).Groups(g).data.meanlatencystd = {temp_meanlatencystd};
end

TrialViewerData = data;
fig = get(hObject,'parent');                                                %Grab the parent figure of the pushbutton.
data = get(fig,'userdata');                                                 %Grab the plot data from the figure's 'UserData' property.

str = get(obj(1),'string');                                                 %Grab the strings from the pop-up menu.
i = get(obj(1),'value');                                                    %Grab the value of the pop-up menu.
str = str{i};
% set(hObject,'units','centimeters');     
pos = get(hObject,'position');                                              %Grab the current figure size, in centimeters.
w = pos(3);                                                                 %Grab the width of the figure.
h = pos(4);
ui_h = 0.07*h;                                                              %Set the heigh of all uicontrols.
sp1 = 0.02*h;                                                               %Set the vertical spacing between axes and uicontrols.
sp2 = 0.01*w;                                                               %Set the horizontal spacing between axes and uicontrols.
% fontsize = 0.6*28.34*ui_h;   %Create a structure to hold plot data.
linewidth = .1*h;                                                          %Set the linewidth for the plots.
markersize = 0.75*h;                                                        %Set the marker size for the plots.
% fontsize = 0.6*h;  
temp_plot_value = get(obj(3), 'value');
if temp_plot_value == 1;
    Plotvalue = 'Line';
else
    Plotvalue = 'Bar';
end
temp_grayscale_value = get(obj(6),'value');
if temp_grayscale_value == 1;
    Grayscale_string = 'Gray';
else
    Grayscale_string = 'Color';
end
colors = 'kbrgy';
linestyles = {'-' '--' ':' '-.'};  
markerstyles = {'o' 's' 'x' 'd' '<' '>' 'p' 'h'};
numbars = length(TimelineData(index_selected).Groups);
numgroups = length(cell2mat(TimelineData(index_selected).Groups(1).data.MeanHitRate));
groupwidth = min(0.8, numbars/(numbars+1.5));
if strcmpi(str,'overall hit rate')                              %If we're plotting overall hit rate...
    ax = gcf; cla(ax); %tempaxis = gca;
    for p = 1:length(TimelineData(index_selected).Groups)
        HitRate(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.MeanHitRate);
        StandardDev(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.hitratestd);
        GroupLegend(p) = TimelineData(index_selected).Groups(p).name;        
        hold on;
        gcf; %plot(HitRate(p,:), 'Color', colors(p),'Marker', 'o','MarkerFaceColor', colors(p));
        switch Plotvalue
            case 'Line'
                switch Grayscale_string
                    case 'Color'
                        errorbar(HitRate(:,p), StandardDev(:,p)./sqrt(length(HitRate)),'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
                    case 'Gray'
                        errorbar(HitRate(:,p), StandardDev(:,p)./sqrt(length(HitRate)),'Color', 'k', 'Marker', markerstyles{p},'MarkerFaceColor', 'k', 'Linestyle', linestyles{p});
                end
        end
        hold off;
        CSV_Data(:,p) = HitRate(:,p); GroupInfo(p).data = TimelineData(index_selected).Groups(p).data.PerAnimalHitRate;
    end
    switch Plotvalue
        case 'Bar'
            temp = bar(HitRate);
            %             switch Grayscale_string
            switch Grayscale_string
                case 'Color'                              
                    for p = 1:length(temp)
                        temp(p).FaceColor = colors(p);
                        temp(p).EdgeColor = colors(p);
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, HitRate(:,i)', StandardDev(:,i)'./sqrt(length(HitRate)),colors(i), 'linestyle', 'none');
                    end
                    hold off;
                case 'Gray'
                    for p = 1:length(temp)
                        temp(p).LineStyle = linestyles{p};
                        temp(p).FaceColor = p*[.15 .15 .15];
                        temp(p).EdgeColor = 'k';
                        temp(p).LineWidth = 1.5;
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, HitRate(:,i)', zeros(size(x)),StandardDev(:,i)'./sqrt(length(HitRate)),'k', 'linestyle', 'none');
                    end
                    hold off;
            end
    end
    legend(GroupLegend,0,'Fontsize',10); box off; set(gca, 'TickDir', 'out','YLim', [0 1],...
        'XLim', [.5 length(HitRate)+.5],'XTickLabels', xlabels);
    yL = get(gca, 'YLim'); yLMax = max(yL);
    for q = 1:length(EventData);
        hold on;
        x = EventData(q).location - .5;
        line([x x], yL, 'Color', 'k', 'Linestyle', '--');
        text(x,.95*yLMax, ['\leftarrow' char(EventData(q).name)]);
        hold off;
    end
elseif any(strcmpi(str,{'median peak force',...
        'median peak angle','median signal peak'}))             %If we're plotting the median signal peak...
    ax = gcf; cla(ax);
    for p = 1:length(TimelineData(index_selected).Groups)
        MedianPeak(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.MedianPeak);
        StandardDev(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.medianpeakstd);
        GroupLegend(p) = TimelineData(index_selected).Groups(p).name;
        hold on;
        gcf; %plot(MedianPeak(p,:), 'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
        switch Plotvalue
            case 'Line'
                switch Grayscale_string
                    case 'Color'
                        errorbar(MedianPeak(:,p), StandardDev(:,p)./sqrt(length(MedianPeak)),'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
                    case 'Gray'
                        errorbar(MedianPeak(:,p), StandardDev(:,p)./sqrt(length(MedianPeak)),'Color', 'k', 'Marker', markerstyles{p},'MarkerFaceColor', 'k', 'Linestyle', linestyles{p});
                end
        end
        hold off;
        CSV_Data(:,p) = MedianPeak(:,p); GroupInfo(p).data = TimelineData(index_selected).Groups(p).data.PerAnimalMedianPeak;
    end
    switch Plotvalue
        case 'Bar'
            temp = bar(MedianPeak);
            switch Grayscale_string
                case 'Color'                              
                    for p = 1:length(temp)
                        temp(p).FaceColor = colors(p);
                        temp(p).EdgeColor = colors(p);
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, MedianPeak(:,i)', StandardDev(:,i)'./sqrt(length(MedianPeak)),colors(i), 'linestyle', 'none');
                    end
                    hold off;
                case 'Gray'
                    for p = 1:length(temp)
                        temp(p).LineStyle = linestyles{p};
                        temp(p).FaceColor = p*[.15 .15 .15];
                        temp(p).EdgeColor = 'k';
                        temp(p).LineWidth = 1.5;
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, MedianPeak(:,i)', zeros(size(x)), StandardDev(:,i)'./sqrt(length(MedianPeak)),'k', 'linestyle', 'none');
                    end
                    hold off;
            end
    end
    YMax = 1.1*max(max(MedianPeak)); YMax = round(YMax,-2); 
    legend(GroupLegend,0,'Fontsize',10); box off; set(gca, 'TickDir', 'out','Linewidth', linewidth,'YLim', [0 YMax],...
        'XLim', [.5 length(MedianPeak)+.5],'XTickLabels', xlabels);
    yL = get(gca, 'YLim'); yLMax = max(yL);
    for q = 1:length(EventData);
        hold on;
        x = EventData(q).location - .5;
        line([x x], yL, 'Color', 'k', 'Linestyle', '--');
        text(x,.95*yLMax, ['\leftarrow' char(EventData(q).name)]);
        hold off;
    end
elseif any(strcmpi(str,{'mean peak force',...
        'mean peak angle','mean signal peak'}))                 %If we're plotting the mean signal peak...
    ax = gcf; cla(ax); %ax = gca; cla(ax);
    for p = 1:length(TimelineData(index_selected).Groups)
        MeanPeak(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.MeanPeak);
        StandardDev(:,p) = cell2mat(TimelineData(index_selected).Groups(g).data.meanpeakstd);
        GroupLegend(p) = TimelineData(index_selected).Groups(p).name;       
        hold on;
        gcf; %plot(MeanPeak(p,:), 'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
        switch Plotvalue
            case 'Line'
                switch Grayscale_string
                    case 'Color'
                        errorbar(MeanPeak(:,p), StandardDev(:,p)./sqrt(length(MeanPeak)),'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
                    case 'Gray'
                        errorbar(MeanPeak(:,p), StandardDev(:,p)./sqrt(length(MeanPeak)),'Color', 'k', 'Marker', markerstyles{p},'MarkerFaceColor', 'k', 'Linestyle', linestyles{p});
                end
        end
        hold off;
        CSV_Data(:,p) = MeanPeak(:,p); GroupInfo(p).data = TimelineData(index_selected).Groups(p).data.PerAnimalMeanPeak;
    end
    switch Plotvalue
        case 'Bar'
            temp = bar(MeanPeak);
            switch Grayscale_string
                case 'Color'                              
                    for p = 1:length(temp)
                        temp(p).FaceColor = colors(p);
                        temp(p).EdgeColor = colors(p);
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, MeanPeak(:,i)', StandardDev(:,i)'./sqrt(length(MeanPeak)),colors(i), 'linestyle', 'none');
                    end
                    hold off;
                case 'Gray'
                    for p = 1:length(temp)
                        temp(p).LineStyle = linestyles{p};
                        temp(p).FaceColor = p*[.15 .15 .15];
                        temp(p).EdgeColor = 'k';
                        temp(p).LineWidth = 1.5;
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, MeanPeak(:,i)', zeros(size(x)), StandardDev(:,i)'./sqrt(length(MeanPeak)),'k', 'linestyle', 'none');
                    end
                    hold off;
            end
    end
    YMax = 1.1*max(max(MeanPeak)); YMax = round(YMax,-2);
    legend(GroupLegend,0,'Fontsize',10); box off; set(gca, 'TickDir', 'out','Linewidth', linewidth,'YLim', [0 YMax],...
        'XLim', [.5 length(MeanPeak)+.5],'XTickLabels', xlabels);
    yL = get(gca, 'YLim'); yLMax = max(yL);
    for q = 1:length(EventData);
        hold on;
        x = EventData(q).location - .5;
        line([x x], yL, 'Color', 'k', 'Linestyle', '--');
        text(x,.95*yLMax, ['\leftarrow' char(EventData(q).name)]);
        hold off;
    end
elseif strcmpi(str,'trial count')                               %If we're plotting number of trials....
    ax = gcf; cla(ax);
    for p = 1:length(TimelineData(index_selected).Groups)
        TrialCount(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.MeanTrialCount);
        StandardDev(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.meantrialcountstd);
        GroupLegend(p) = TimelineData(index_selected).Groups(p).name;
        hold on;
        gcf; %plot(TrialCount(p,:), 'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
        switch Plotvalue
            case 'Line'
                switch Grayscale_string
                    case 'Color'
                        errorbar(TrialCount(:,p), StandardDev(:,p)./sqrt(length(TrialCount)),'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
                    case 'Gray'
                        errorbar(TrialCount(:,p), StandardDev(:,p)./sqrt(length(TrialCount)),'Color', 'k', 'Marker', markerstyles{p},'MarkerFaceColor', 'k', 'Linestyle', linestyles{p});
                end
        end
        hold off;
        CSV_Data(:,p) = TrialCount(:,p); GroupInfo(p).data = TimelineData(index_selected).Groups(p).data.PerAnimalMeanTrialCount;
    end
    switch Plotvalue
        case 'Bar'
            temp = bar(TrialCount);
            switch Grayscale_string
                case 'Color'                              
                    for p = 1:length(temp)
                        temp(p).FaceColor = colors(p);
                        temp(p).EdgeColor = colors(p);
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, TrialCount(:,i)', StandardDev(:,i)'./sqrt(length(TrialCount)),colors(i), 'linestyle', 'none');
                    end
                    hold off;
                case 'Gray'
                    for p = 1:length(temp)
                        temp(p).LineStyle = linestyles{p};
                        temp(p).FaceColor = p*[.15 .15 .15];
                        temp(p).EdgeColor = 'k';
                        temp(p).LineWidth = 1.5;
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, TrialCount(:,i)', zeros(size(x)),StandardDev(:,i)'./sqrt(length(TrialCount)),'k', 'linestyle', 'none');
                    end
                    hold off;
            end
    end
    YMax = 1.5*max(max(TrialCount)); YMax = round(YMax,-1);
    legend(GroupLegend,0,'Fontsize',10); box off; set(gca, 'TickDir', 'out','Linewidth', linewidth,'YLim', [0 YMax],...
        'XLim', [.5 length(TrialCount)+.5],'XTickLabels', xlabels);
    yL = get(gca, 'YLim'); yLMax = max(yL);
    for q = 1:length(EventData);
        hold on;
        x = EventData(q).location - .5;
        line([x x], yL, 'Color', 'k', 'Linestyle', '--');
        text(x,.95*yLMax, ['\leftarrow' char(EventData(q).name)]);
        hold off;
    end
elseif strcmpi(str,'peak velocity');
    ax = gcf; cla(ax);
    for p = 1:length(TimelineData(index_selected).Groups)
        PeakVelocity(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.MeanPeakVelocity);
        StandardDev(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.meanpeakvelocitystd);
        GroupLegend(p) = TimelineData(index_selected).Groups(p).name;
        hold on;
        gcf; %plot(PeakVelocity(p,:), 'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
        switch Plotvalue
            case 'Line'
                switch Grayscale_string
                    case 'Color'
                        errorbar(PeakVelocity(:,p), StandardDev(:,p)./sqrt(length(PeakVelocity)),'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
                    case 'Gray'
                        errorbar(PeakVelocity(:,p), StandardDev(:,p)./sqrt(length(PeakVelocity)),'Color', 'k', 'Marker', markerstyles{p},'MarkerFaceColor', 'k', 'Linestyle', linestyles{p});
                end
        end
        hold off;
        CSV_Data(:,p) = PeakVelocity(:,p); GroupInfo(p).data = TimelineData(index_selected).Groups(p).data.PerAnimalMeanPeakVelocity;
    end
    switch Plotvalue
        case 'Bar'
            temp = bar(PeakVelocity);
            switch Grayscale_string
                case 'Color'
                    for p = 1:length(temp)
                        temp(p).FaceColor = colors(p);
                        temp(p).EdgeColor = colors(p);
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, PeakVelocity(:,i)', StandardDev(:,i)'./sqrt(length(PeakVelocity)),colors(i), 'linestyle', 'none');
                    end
                    hold off;
                case 'Gray'
                    for p = 1:length(temp)
                        temp(p).LineStyle = linestyles{p};
                        temp(p).FaceColor = p*[.15 .15 .15];
                        temp(p).EdgeColor = 'k';
                        temp(p).LineWidth = 1.5;
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, PeakVelocity(:,i)', zeros(size(x)),StandardDev(:,i)'./sqrt(length(PeakVelocity)),'k', 'linestyle', 'none');
                    end
                    hold off;
            end
    end
    YMax = 1.1*max(max(PeakVelocity)); YMax = round(YMax);
    legend(GroupLegend,0,'Fontsize',10); box off; set(gca, 'TickDir', 'out','Linewidth', linewidth,'YLim', [0 YMax],...
        'XLim', [.5 length(PeakVelocity)+.5],'XTickLabels', xlabels);
    yL = get(gca, 'YLim'); yLMax = max(yL);
    for q = 1:length(EventData);
        hold on;
        x = EventData(q).location - .5;
        line([x x], yL, 'Color', 'k', 'Linestyle', '--');
        text(x,.95*yLMax, ['\leftarrow' char(EventData(q).name)]);
        hold off;
    end
elseif strcmpi(str,'latency to hit');
    ax = gcf; cla(ax);
    for p = 1:length(TimelineData(index_selected).Groups)
        Latency(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.MeanLatency);
        StandardDev(:,p) = cell2mat(TimelineData(index_selected).Groups(p).data.meanlatencystd);
        GroupLegend(p) = TimelineData(index_selected).Groups(p).name;
        hold on;
        gcf; %plot(Latency(p,:), 'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
        switch Plotvalue
            case 'Line'
                switch Grayscale_string
                    case 'Color'
                        errorbar(Latency(:,p), StandardDev(:,p)./sqrt(length(Latency)),'Color', colors(p), 'Marker', 'o','MarkerFaceColor', colors(p));
                    case 'Gray'
                        errorbar(Latency(:,p), StandardDev(:,p)./sqrt(length(Latency)),'Color', 'k', 'Marker', markerstyles{p},'MarkerFaceColor', 'k', 'Linestyle', linestyles{p});
                end
        end
        hold off;
        CSV_Data(:,p) = Latency(:,p); GroupInfo(p).data = TimelineData(index_selected).Groups(p).data.PerAnimalMeanLatency;
    end
    switch Plotvalue
        case 'Bar'
            temp = bar(Latency);
            switch Grayscale_string
                case 'Color'
                    for p = 1:length(temp)
                        temp(p).FaceColor = colors(p);
                        temp(p).EdgeColor = colors(p);
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, Latency(:,i)', StandardDev(:,i)'./sqrt(length(Latency)),colors(i), 'linestyle', 'none');
                    end
                    hold off;
                case 'Gray'
                    for p = 1:length(temp)
                        temp(p).LineStyle = linestyles{p};
                        temp(p).FaceColor = p*[.15 .15 .15];
                        temp(p).EdgeColor = 'k';
                        temp(p).LineWidth = 1.5;
                    end
                    hold on;
                    for i = 1:numbars
                        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
                        errorbar(x, Latency(:,i)', zeros(size(x)),StandardDev(:,i)'./sqrt(length(Latency)),'k', 'linestyle', 'none');
                    end
                    hold off;
            end
    end
    YMax = 1.4*max(max(Latency)); YMax = round(YMax,-1);
    legend(GroupLegend,0,'Fontsize',10); box off; set(gca, 'TickDir', 'out','Linewidth', linewidth,'YLim', [0 YMax],...
        'XLim', [.5 length(Latency)+.5],'XTickLabels', xlabels);
    yL = get(gca, 'YLim'); yLMax = max(yL);
    for q = 1:length(EventData);
        hold on;
        x = EventData(q).location - .5;
        line([x x], yL, 'Color', 'k', 'Linestyle', '--');
        text(x,.95*yLMax, ['\leftarrow' char(EventData(q).name)]);
        hold off;
    end
end

CSV_Data = CSV_Data'; 
t = unique(horzcat(data.times));                                            %Horizontally concatenate all of the timestamps.
t = unique(fix(t));                                                     %Find the unique truncated serial date numbers.
t = [t; t + 1]';
t = [min(fix(t)), max(fix(t))];                                         %Find the first and last timestamp.
i = find(strcmpi({'sun','mon','tue','wed','thu','fri','sat'},...
    datestr(t(1),'ddd')));                                              %Find the index for the day of the week of the first timestamp.
t(1) = t(1) - i + 1;                                                    %Round down the timestamp to the nearest Sunday.
t = t(1):7:t(2);                                                        %Find the timestamps for weekly spacing.
t = [t; t + 7]';                                                        %Set the time bounds to go from the start of the week to the end of the week.

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
    [file, path] = uiputfile('*.xls','Save Spreadsheet');
    filename = [path file];
    for d = 1:length(TimelineData(index_selected).Groups);
        xlswrite(filename, {'Experiment Name:'},d,'A1');
        xlswrite(filename, TimelineData(index_selected).ExpName,d,'B1');
        xlswrite(filename,{'Groups:'},d,'A2');
        xlswrite(filename,GroupNames,d,'B2');
        xlswrite(filename,{'Group Name:'},d,'A4')
        xlswrite(filename,GroupNames(d),d,'B4');
        xlswrite(filename,TimelineData(index_selected).Groups(d).Subjects,d,'A5');
        xlswrite(filename,GroupInfo(d).data',d,'A6');
    end
%     fopen(filename);
winopen(filename)
%     msgbox('Done!');
%     fprintf(fid,'%s,\t','Experiment Name:');
%     fprintf(fid,'%s,\n',TimelineData(index_selected).ExpName{:});
%     fprintf(fid,'%s,\t','Groups:');
%     for g = 1:length(TimelineData(index_selected).Groups)
%         if g == length(TimelineData(index_selected).Groups);
%             fprintf(fid,'%s,\n\n',TimelineData(index_selected).Groups(g).name{:});
%         else
%             fprintf(fid,'%s,\t',TimelineData(index_selected).Groups(g).name{:});
%         end
%     end
%     for g = 1:length(TimelineData(index_selected).Groups)
%         fprintf(fid,'%s Subjects,\t',TimelineData(index_selected).Groups(g).name{:});
%         for s = 1:length(TimelineData(index_selected).Groups(g).Subjects);
%             if s == length(TimelineData(index_selected).Groups(g).Subjects);
%                 fprintf(fid,'%s,\n',TimelineData(index_selected).Groups(g).Subjects{s});
%             else
%                 fprintf(fid,'%s,\t',TimelineData(index_selected).Groups(g).Subjects{s});
%             end
%         end
%     end
%     fprintf(fid,'\n%s\n',str);
%     for g = 1:length(TimelineData(index_selected).Groups)
%         if g == length(TimelineData(index_selected).Groups);
%             fprintf(fid,'%s,\n',TimelineData(index_selected).Groups(g).name{:});
%         else
%             fprintf(fid,'%s,\t',TimelineData(index_selected).Groups(g).name{:});
%         end
%     end
%     for d = 1:length(CSV_Data);
%         for g = 1:length(TimelineData(index_selected).Groups)
%             if g == length(TimelineData(index_selected).Groups)
%                 fprintf(fid,'%f,\n',CSV_Data(g,d));
%             else
%                 fprintf(fid,'%f,\t',CSV_Data(g,d));
%             end
%         end
%     end
%     fprintf(fid,'\n%s','Group Data');
%     for d = 1:length(TimelineData(index_selected).Groups);
%         fprintf(fid,'\n%s\n',TimelineData(index_selected).Groups(d).name{:});
%         for g = 1:length(TimelineData(index_selected).Groups(d).Subjects);
%             if g == length(TimelineData(index_selected).Groups(d).Subjects);
%                 fprintf(fid,'%s,\n',TimelineData(index_selected).Groups(d).Subjects{g});
%             else
%                 fprintf(fid,'%s,\t',TimelineData(index_selected).Groups(d).Subjects{g});
%             end
%         end
%         for i = 1:size(GroupInfo(d).data,2);
%             for g = 1:length(TimelineData(index_selected).Groups(d).Subjects);
%                 if g == length(TimelineData(index_selected).Groups(d).Subjects);
%                     fprintf(fid,'%d,\n',GroupInfo(d).data(g,i));
%                 else
%                     fprintf(fid,'%d,\t',GroupInfo(d).data(g,i));
%                 end
%             end
%         end
%     end
end

%% This subfunction sorts the data into daily values and sends it to the plot function.
function Export_Data(hObject,~,ax,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,LineUI,Grayscale_string)
LineStatus = get(LineUI, 'value');
if LineStatus == 1;
    Plotvalue = 'Line';
else
    Plotvalue = 'Bar';
end
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
%     pos = [7*sp2,3*sp1,w-8*sp2,h-4*sp1];                                    %Create an axes position matrix.
    pos = [9*sp2,5*sp1,w-10*sp2,h-7*sp1];                                                          %Set the horizontal spacing between axes and uicontrols.
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
%     pos = [7*sp2,3*sp1,w-8*sp2,h-ui_h-5*sp1];                               %Create an axes position matrix.
    pos = [8*sp2,8*sp1,w-10*sp2,h-ui_h-10.5*sp1]; 
    
    set(ax,'units','centimeters','position',pos);                           %Reset the position of the axes.
    set(obj,'visible','on');                                                %Make all of the other figures visible again.
%     i = strcmpi(get(obj,'fontweight'),'bold');                              %Find the pushbutton with the bold fontweight.
    Plot_Timeline(obj(2),[],obj,[],data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string);                                        %Call the subfunction to plot the data by the appropriate timeline.
    set(fig,'color',temp,'ResizeFcn',{@Resize,ax,obj});                     %Set the Resize function for the figure.
    drawnow;                                                                %Immediately update the figure.    
end
if any(strcmpi({'spreadsheet','both'},output))                              %If the user wants to save a spreadsheet...
%     temp = get(ax,'ylabel');                                                %Grab the handle for the axes y-label.
%     file = lower(get(temp,'string'));                                       %Grab the axes y-axis label.
%     file(file == ' ') = '_';                                                %Replace any spaces with underscores.
%     for i = '<>:"/\|?*().'                                                  %Step through all reserved characters.
%         file(file == i) = [];                                               %Kick out any reserved characters.
%     end
%     file = [file '_' datestr(now,'yyyymmdd')];                              %Add today's date to the default filename.
%     temp = lower(get(fig,'name'));                                          %Grab the figure name.
%     file = [temp(20:end) '_' file];                                         %Add the device name to the default filename.
%     [file, path] = uiputfile('*.xls','Save Spreadsheet',file);              %Ask the user for a filename.
%     if file(1) == 0                                                         %If the user clicked cancel...
%         return                                                              %Skip execution of the rest of the function.
%     end
%     fid = fopen([path file],'wt');                                          %Open a new text file to write the data to.   
%     i = strcmpi(get(obj,'fontweight'),'bold');                              %Find the pushbutton with the bold fontweight.
fid = 1;
    Plot_Timeline(obj(2),[],obj,fid,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string);                                       %Call the subfunction to write the data by the appropriate timeline.
%     fclose(fid);                                                            %Close the figure.
%     winopen([path file]);                                                   %Open the CSV file.
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
pos = [8*sp2,8*sp1,w-10*sp2,h-ui_h-10.5*sp1]; 
    
% pos = [7*sp2,3*sp1,w-8*sp2,h-ui_h-5*sp1];                                   %Create an axes position matrix.
set(ax,'units','centimeters','position', pos);                              %Reset the position of the axes.
pos = [sp2, h-sp1-ui_h, 2*(w-6*sp2)/6, ui_h];                               %Create the position matrix for the pop-up menu.
set(obj(1),'units','centimeters','position',pos,'fontsize',fontsize);       %Set the position of the pop-up menu.
pos = [5*sp2+5*(w-6*sp2)/6, h-sp1-ui_h, (w-6*sp2)/6, ui_h];
set(obj(2),'units','centimeters','position',pos,'fontsize',fontsize);       %Set the position of the export button.
pos = [30*sp2, .95*sp1, (w-6*sp2)/6, .9*ui_h];
set(obj(3),'units','centimeters','position',pos,'fontsize',.7*fontsize);
pos = [35*sp2+(w-6*sp2)/6, .95*sp1, (w-6*sp2)/6, .9*ui_h];
set(obj(4),'units','centimeters','position',pos,'fontsize',.7*fontsize);
pos = [60*sp2+(w-6*sp2)/6, .95*sp1, (w-6*sp2)/6, .9*ui_h]; 
set(obj(5),'units','centimeters','position',pos,'fontsize',.7*fontsize);
pos = [5*sp2, .95*sp1, (w-6*sp2)/6, .9*ui_h]; 
set(obj(6),'units','centimeters','position',pos,'fontsize',.7*fontsize);
linewidth = 0.1*h;                                                          %Set the linewidth for the plots.
markersize = 0.75*h;                                                        %Set the marker size for the plots.
fontsize = 0.6*h;                                                           %Set the fontsize for all text objects.
obj = get(ax,'children');                                                   %Grab all children of the axes.
% temp = vertcat(get(obj,'userdata'));                                        %Vertically concatenate the 'UserData' from each objects.
% temp = vertcat(temp{:});                                                    %Change the 'UserData' from a cell array to matrix.
i = strcmpi(get(obj,'type'),'line'); %& temp == 1;                            %Find all plot line objects.
set(obj(i),'linewidth',linewidth);                                          %Set the linewidth for all plot line objects.
i = strcmpi(get(obj,'type'),'line'); %& temp == 2;                            %Find all plot marker objects.
set(obj(i),'markersize',markersize);                                        %Set the markersize for all plot line objects.
i = strcmpi(get(obj,'type'),'line'); %& temp == 3;                            %Find all grid line objects.
set(obj(i),'linewidth',0.5*linewidth);                                      %Set the linewidth for all grid line objects.
i = strcmpi(get(obj,'type'),'text');                                        %Find all text objects.
set(obj(i),'fontsize',1.5*fontsize);                                            %Set the font size for all text objects.
set(ax,'fontsize',fontsize,'linewidth',linewidth);                          %Set the axes linewidth and fontsize.
temp = get(ax,'ylabel');                                                    %Grab the y-axis label handle for the axes.
set(temp,'fontsize',1.1*fontsize);                                          %Set the font size for y-axis label.

%% This section plots weekly data in the specified axes.
function Make_Plot(plotdata,ax,str,TrialViewerData)
fig = get(ax,'parent');                                                     %Grab the figure handle for the axes' parent.
set(fig,'units','centimeters');                                             %Set the figure's units to centimeters.
temp = get(fig,'position');                                                 %Grab the figure position.
h = temp(4);                                                                %Grab the figure height, in centimeters.
linewidth = .1*h;                                                          %Set the linewidth for the plots.
markersize = 0.75*h;                                                        %Set the marker size for the plots.
fontsize = 0.6*h;                                                           %Set the fontsize for all text objects.
% cla(ax);                                                                    %Clear the axes.
% colors = hsv(length(plotdata));                                             %Grab unique colors for all the rats.
% hoverdata = struct([]);                                                     %Create an empty structure to hold data for the MouseHover function.
% for r = 1:length(plotdata)                                                  %Step through each rat.
% %     line(mean(plotdata(r).x,2),plotdata(r).y,'color',colors(r,:),...
% %         'linewidth',linewidth,'userdata',1,'parent',ax);                    %Show the rat's performance as a thick line.
%     for i = 1:size(plotdata(r).x,1)                                         %Step through each timepoint.
% %         l = line(mean(plotdata(r).x(i,:)),plotdata(r).y(i),...
% %             'markeredgecolor',colors(r,:),'linestyle','none',...
% %             'markerfacecolor',colors(r,:),'marker','.',...
% %             'linewidth',linewidth,'markersize',markersize,'userdata',2,...
% %             'parent',ax);                                                   %Mark each session with a unique marker.        
%         hoverdata(end+1).xy = [mean(plotdata(r).x(i,:)),plotdata(r).y(i)];  %Save the x- and y-coordinates.
%         if rem(plotdata(r).x(i,1),1) ~= 0                                   %If the timestamp is a fractional number of days...
%             temp = datestr(plotdata(r).x(i,1),'mm/dd/yyyy, HH:MM');         %Show the date and the time.
%         elseif plotdata(r).x(i,2) - plotdata(r).x(i,1) == 1                 %If the timestamps only cover one day...
%             temp = datestr(plotdata(r).x(i,1),'mm/dd/yyyy');                %Show only the date.
%         else                                                                %Otherwise...
%             temp = [datestr(plotdata(r).x(i,1),'mm/dd/yyyy') '-' ...
%                 datestr(plotdata(r).x(i,2)-1,'mm/dd/yyyy')];                %Show the date range.
%         end
%         hoverdata(end).txt = {plotdata(r).rat,plotdata(r).s{i},...
%             temp,plotdata(r).n{i}};                                         %Save the rat's name, stage, date, and hit rate/num trials.
% %         hoverdata(end).handles = l;                                         %Save the line handle for the point.
%     end
% end
% temp = vertcat(hoverdata.xy);                                               %Grab all of the datapoint coordinates.
% x = [min(temp(:,1)), max(temp(:,1))];                                       %Find the minimim and maximum x-values.
% x = x + [-0.05,0.05]*(x(2) - x(1));                                         %Add some padding to the x-axis limits.
% if length(x) < 2 || any(isnan(x))                                           %If there are any missing x values.
%     x = now + [-1,1];                                                       %Set arbitrary x-axis limits.
% end
% if x(1) == x(2)                                                             %If the x-axis limits are the same...
%     x = x + [-1,1];                                                         %Add a day to each side of the single point.
% end
% % xlim(ax,x);                                                                 %Set the x-axis limits.
% y = [min(temp(:,2)), max(temp(:,2))];                                       %Find the minimim and maximum x-values.
% y = y + [-0.05,0.05]*(y(2) - y(1));                                         %Add some padding to the y-axis limits.
% if length(y) < 2 || any(isnan(y))                                           %If there are any missing y values.
%     y = [0,1];                                                              %Set arbitrary y-axis limits.
% end
% if y(1) == y(2)                                                             %If the y-axis limits are the same...
%     y = y + [-0.1, 0.1];                                                    %Add 0.1 to each side of the single point.
% end
% ylim(ax,y);                                                                 %Set the y-axis limits.
% set(ax,'xticklabel',datestr(get(ax,'xtick'),'mm/dd'),...
%     'fontsize',fontsize,'fontweight','bold','linewidth',linewidth);         %Show the date for each x-axis tick.
ylabel(ax,str,'fontweight','bold','fontsize',1.1*fontsize);                 %Label the x-axis.
set(ax,'Linewidth', linewidth);
% temp = get(ax,'ytick');                                                     %Grab the y-axis ticks.
% for i = 1:length(temp)                                                      %Step through the y-axis ticks.
%     temp(i) = line(xlim(ax),temp(i)*[1,1],'color',[0.75 0.75 0.75],...
%         'linestyle','--','linewidth',0.5*linewidth,'userdata',3,...
%         'parent',ax);                                                       %Draw a gridline at each y-tick.
% end
% uistack(temp,'bottom');                                                     %Send all grid lines to the bottom.
% txt = text(x(1),y(1),' ','fontsize',fontsize,'margin',2,...
%     'backgroundcolor','w','edgecolor','k','visible','off',...
%     'verticalalignment','bottom','horizontalalignment','center',...
%     'userdata',4);                                                          %Create a text object for labeling points.
% set(fig,'WindowButtonMotionFcn',{@MouseHover,ax,hoverdata,txt});            %Set the mouse hover function for the figure.
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
%             set(data(i).handles,'markersize',2*markersize);                 %Make the selected marker larger.
            set(setdiff([data.handles],data(i).handles),...
                'markersize',markersize);                                   %Make the other markers smaller.
        end
    else                                                                    %Otherwise...
%         set([data.handles],'markersize',markersize);                        %Make all markers smaller.
        set(txt,'visible','off');                                           %Make the text object invisible.
    end
end

%% This function is called when the user selects a plot type in the pop-up menu.
function Set_Plot_Type(~,~,obj,data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string)
% i = strcmpi(get(obj,'fontweight'),'bold');                                  %Find the pushbutton with the bold fontweight.
Plot_Timeline(obj(1),[],obj,[],data,Weeks,AnimalData,index_selected,xlabels,EventData,Plotvalue,Grayscale_string);                                            %Call the subfunction to plot the data by the appropriate timeline.

%% This function updates the GUI with Experiment Name, Subjects, and Event Data
function ExperimentCallback(hObject,~,GUI_Subjects,GUI_GroupNames,ExperimentNames,Subjects,Groups,Events,Labels)
index_selected = get(hObject,'value');
SelectedExperiment = ExperimentNames{index_selected};
temp = ['C:\AnalyzeGroup\' SelectedExperiment '\ConfigFiles\'];
% cd(temp);
temp = [temp SelectedExperiment 'Config.mat'];
load(temp);
EventNames = config.events; %EventNames = strsplit(EventNames);
SubjectNames = GUI_Subjects(index_selected,:);
GroupNames = GUI_GroupNames{index_selected};
set(Subjects,'string',SubjectNames);
set(Groups,'string',GroupNames);
set(Events,'string',EventNames);
set(Labels,'string',config.xlabels);