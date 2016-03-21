function QuickStats(varargin)
[files, path] = uigetfile('*.ArdyMotor', ...
    'Select Animals', ...
    'multiselect','on');
cd(path);
if ischar(files)                                                        %If only one file was selected...
    files = {files};                                                    %Convert the string to a cell array.
end
for i = 1:length(files)
    D = dir(files{i});
    Bytes(i) = D.bytes;
end
[row, col] = find(Bytes>25000);
files = files(col);
Latency_To_Hit = nan(500, length(files));
for f = 1:length(files)                                                     %Step through each file.
    data = ArdyMotorFileRead(files{f});
    HIT = mean([data.trial.outcome] == 'H');
    Hits = sum([data.trial.outcome] == 'H');
    Misses = sum([data.trial.outcome] == 'M');
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
        smooth_knob_velocity = boxsmooth(diff(smooth_trial_signal));                %Boxsmooth the velocity signal
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
    HIT2 = nanmean((HIT_NEW./length(data.trial)).*100);
    Mean_Distance = nanmean(total_mean_distance);
    Latency = nanmean(total_latency_to_hit);
    Peak_Vel = nanmean(total_peak_velocity);
    Peak_Accel = nanmean(total_peak_acceleration);
    Turns = nanmean(total_num_turns);
    Mean_Turn_Distance = nanmean(total_mean_turn_distance);
    Max_Mean_TD = max(total_mean_turn_distance);
    Date = cellstr(datestr(data.trial(1).starttime,23));
    Stage = cellstr(data.stage);
    Hit = HIT*100;
    Trials = length(data.trial);
    Output(f,:) = [Date,Stage,Trials,Misses,Hits,Hit,Mean_Distance];
end
f = figure('Position', [100 100 700 250]);
cnames = {'Date', 'Stage', 'Trials', 'Misses', 'Hits', 'Hit', 'Mean_Distance'};
uitable('Parent',f, 'Position', [25 20 650 225], 'Data', Output, 'ColumnName', cnames);
end

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