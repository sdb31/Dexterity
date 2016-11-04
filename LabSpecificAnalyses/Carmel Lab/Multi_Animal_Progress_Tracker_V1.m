function Multi_Animal_Progress_Tracker_V1(varargin)
Ask_Number_of_Animals = inputdlg('Number of Animals to Analyze', 'Animals', [1 35]);
Ask_Excel_File = inputdlg('Do you want an excel file? (y/n)', 'Excel File', [1 35]);  
if Ask_Excel_File{:} == 'y';
    [FileName, PathName] = uiputfile('*.xlsx', 'Save Output Excel File As');
    Path = sprintf('%s\%s', PathName, FileName);
end
Number_of_Animals = str2num(Ask_Number_of_Animals{:});
Hit = nan(500,20);
Mean_Distance = nan(500,20);
for N = 1:Number_of_Animals;
    clear Bytes
    clear files
    clear D
    if nargin > 1                                                               %If the user entered too many input arguments...
        error(['ERROR IN ARDYMOTOR2TEXT: Too many inputs! Input should be a'...
            ' *.ArdyMotor filename string or cell array of filename strings']); %Show an error.
    end
    if nargin > 0                                                               %If the user specified file names.
        temp = varargin{1};                                                     %Grab the first input argument.
        if ischar(temp)                                                         %If the argument is a string...
            files = {temp};                                                     %Save the filename as a string.
        elseif iscell(temp)                                                     %If the argument is a cell array...
            files = temp;                                                       %Save the filenames as a cell array.
        else                                                                    %If the input isn't a string or cell array..., string, or number, show an error.
            error(['ERROR IN ARDYMOTOR2TEXT: Input argument must be an '...
                '*.ArdyMotor filename string or cell array of filenames!']);    %Show an error.
        end
    else                                                                        %Otherwise, if the user hasn't specified an input file...
        [files path] = uigetfile('*.ArdyMotor','multiselect','on', 'Select Animal''s Data');             %Have the user pick an input *.ArdyMotor file or files.
        if ~iscell(files) && files(1) == 0                                       %If no file was selected...
            return                                                              %Exit the function.
        end
        cd(path);                                                               %Change the current directory to the specified folder.
        if ischar(files)                                                        %If only one file was selected...
            files = {files};                                                    %Convert the string to a cell array.
        end
    end
    for i = 1:length(files)
        D = dir(files{i});
        Bytes(i) = D.bytes;
    end
    [row, col] = find(Bytes>15000);
    files = files(col);
    %     AskSessions = inputdlg('How many sessions are in each week?', 'Session Count');
    %     Sessions_Per_Week(:,N) = str2num(AskSessions{:});
    AskAnimalName = inputdlg('What''s the animal''s ID?', 'Animal ID');
    Animal_Name(N) = AskAnimalName;
    Latency_To_Hit = nan(500, length(files));
    for f = 1:length(files)                                                     %Step through each file.
        data = ArdyMotorFileRead(files{f});
        HIT = mean([data.trial.outcome] == 'H');
        Hits(f,N) = sum([data.trial.outcome] == 'H');
        Misses(f,N) = sum([data.trial.outcome] == 'M');
        total_mean_distance = nan(1, length(data.trial));
        total_latency_to_hit = nan(1, length(data.trial));
        total_peak_velocity = nan(1, length(data.trial));
        total_peak_acceleration = nan(1, length(data.trial));
        total_num_turns = nan(1, length(data.trial));
        total_mean_turn_distance = nan(1, length(data.trial));
        total_threshold = nan(1, length(data.trial));
        days = 1:length(data.trial);
        HIT_NEW = 0;
        for t = 1:length(data.trial)                                            %Step through each trial.
            a = find((data.trial(t).sample_times < 1000*data.trial(t).hitwin));       %Find all samples within the hit window.
            if strcmpi(data.threshtype,'degrees (bidirectional)')               %If the threshold type is bidirectional knob-turning...
                signal = abs(data.trial(t).signal(a) - ....
                    data.trial(t).signal(1));                                   %Subtract the starting degrees value from the trial signal.
            elseif strcmpi(data.threshtype,'# of spins')                        %If the threshold type is the number of spins...
                temp = diff(data.trial(t).signal);                              %Find the velocity profile for this trial.
                temp = boxsmooth(temp,10);                                      %Boxsmooth the wheel velocity with a 100 ms smooth.
                [pks,i] = PeakFinder(temp,10);                                  %Find all peaks in the trial signal at least 100 ms apart.
                i(pks < 1) = [];                                                %Kick out all peaks that are less than 1 degree/sample.
                i = intersect(a,i+1)-1;                                         %Find all peaks that are in the hit window.
                signal = length(i);                                             %Set the trial signal to the number of wheel spins.
            elseif strcmpi(data.threshtype, 'degrees (total)')
                signal = data.trial(t).signal(a);
            else
                signal = data.trial(t).signal(a) - data.trial(t).signal(1);    %Grab the raw signal for the trial.
            end
            data.trial(t).range = range(signal);                                %Find the hit window range of each trial signal.
            data.trial(t).max = max(signal);                                    %Find the hit window maximum of each trial signal.
            data.trial(t).min = min(signal);                                    %Find the hit window minimum of each trial signal.
            [pks, sig] = Knob_Peak_Finder(signal);
            data.trial(t).num_turns = length(sig);                             %Calculate number of turns
            if data.trial(t).num_turns == 0                                    %If a turn was initiated in the previous session, and not registered
                data.trial(t).num_turns = 1;                                   %in this session, then count it as 1
            end
            smooth_trial_signal = boxsmooth(signal);
            smooth_knob_velocity = boxsmooth(diff(smooth_trial_signal));    %Boxsmooth the velocity signal
            data.trial(t).peak_velocity = max(smooth_knob_velocity);
            knob_acceleration = boxsmooth(diff(smooth_knob_velocity));
            data.trial(t).peak_acceleration = max(knob_acceleration);
            if (data.trial(t).outcome == 72)                                   %If it was a hit
                hit_time = find(data.trial(t).signal >= ...                    %Calculate the hit time
                    data.trial(t).thresh,1);
                data.trial(t).latency_to_hit = hit_time;                       %hit time is then latency to hit
            else
                data.trial(t).latency_to_hit = NaN;                            %If trial resulted in a miss, then set latency to hit to NaN
            end
            data.trial(t).mean_turn_distance = mean(pks);                       %Take the mean peak distance to find mean turn distance in trial
            %Put each parameter of individual trial in its array
            total_mean_distance(1,t) = data.trial(t).max;
            total_threshold(1,t) = data.trial(t).thresh;
            total_latency_to_hit(1,t) = data.trial(t).latency_to_hit;
            total_peak_velocity(1,t) = data.trial(t).peak_velocity;
            total_peak_acceleration(1,t) = data.trial(t).peak_acceleration;
            total_num_turns(1,t) = data.trial(t).num_turns;
            total_mean_turn_distance(1,t) = data.trial(t).mean_turn_distance;
            Latency_To_Hit(t,f) = data.trial(t).latency_to_hit;
            if data.trial(t).max >= 75
                HIT_NEW = HIT_NEW+1;
            end
        end
        HIT2(f,N) = nanmean((HIT_NEW./length(data.trial)).*100);
        Mean_Distance(f,N) = nanmean(total_mean_distance);
        Latency(f,N) = nanmean(total_latency_to_hit);
        Peak_Vel(f,N) = nanmean(total_peak_velocity);
        Peak_Accel(f,N) = nanmean(total_peak_acceleration);
        Turns(f,N) = nanmean(total_num_turns);
        Mean_Turn_Distance(f,N) = nanmean(total_mean_turn_distance);
        Max_Mean_TD(f,N) = max(total_mean_turn_distance);
        Date(f,N) = cellstr(datestr(data.trial(1).starttime,23));
        Stage(f,N) = cellstr(data.stage);
        Hit(f,N) = HIT*100;
        Trials(f,N) = length(data.trial);
    end
    if Ask_Excel_File{:} == 'y';
        Output = table(Date(1:f,N), Stage(1:f,N), Trials(1:f,N), Misses(1:f,N), Hits(1:f,N), Hit(1:f,N), Mean_Distance(1:f,N), Latency(1:f,N), Peak_Vel(1:f,N),...
            'VariableNames', {'Date', 'Stage', 'Trials', 'Misses', 'Hits', 'HIT', 'Mean_Distance', 'Latency', 'Peak_Vel'});
        writetable(Output, Path, 'Sheet', N);
        clearvars Output
    end
end

%% Overall Means and Stds
figure(2); clf;
plot(Hit, 'Marker', 'o'); grid on; box off; set(gca, 'TickDir', 'out', 'YLim', [0 100], 'XLim', [0.5 (size(Date,1)+.5)]);
legend(Animal_Name); title(gca, 'Progress Tracker: Success Rate', 'Fontsize', 10, 'Fontweight', 'normal');
ylabel(gca, 'Success Rate (%)', 'Fontsize', 10); xlabel(gca, 'Sessions', 'Fontsize', 10);

figure(3); clf;
plot(Mean_Distance, 'Marker', 'o'); grid on; box off; set(gca, 'TickDir', 'out', 'XLim', [0.5 (size(Date,1)+0.5)]);
legend(Animal_Name); title(gca, 'Progress Tracker: Mean Distance', 'Fontsize', 10, 'Fontweight', 'normal');
ylabel(gca, 'Degrees', 'Fontsize', 10); xlabel(gca, 'Sessions', 'Fontsize', 10);

end

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
end
