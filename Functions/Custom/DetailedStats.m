function DetailedStats(vargarin)
%ARDYMOTOR2TEXT.m - Rennaker Neural Engineering Lab, 2013
%
%   ARDYMOTOR2TEXT has the user select one or multiple *.ArdyMotor files
%   and then exports a companion text file for each that is readable in
%   Microsoft Excel.
%
%   QUICK_PSTH(file) exports a companion text file for each *.ArdyMotor
%   file specified.  The variable "file" can either be a single string or a
%   cell array of strings containing file names.
%
%   Last updated January 23, 2013, by Drew Sloan.
%   Revised on February 8, 2016 by Sam Butensky.
%Check to see if any companion *.txt files already exist for these files.
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
existing_files = zeros(1,length(files));                                    %Create a matrix to check for existing files.
for f = 1:length(files)                                                     %Step through each file.
    if ~exist(files{f},'file')                                              %If the file doesn't exist...
        error(['ERROR IN ARDYMOTOR2TEXT: The file "' files{f}...
            '" does not exist!']);                                          %Show an error.
    end
    if ~strcmpi(files{f}(end-9:end),'.Ardymotor')                           %If the file isn't an *.ArdyMotor file...
        error(['ERROR IN ARDYMOTOR2TEXT: The file "' files{f}...
            '" is not an *.ArdyMotor file!']);                              %Show an error.
    end
    newfile = [files{f}(1:end-10) '.txt'];                                  %Create a filename for the text file.
    if exist([pwd '/' newfile],'file')                                      %If the new file already exists in this folder...
        existing_files(f) = 1;                                              %Show that this file already exists.
    end
end
overwrite = 0;                                                              %Keep track of whether the user wants to overwrite any existing files.
if any(existing_files == 1)                                                 %If any of the output files already exist...
    temp = questdlg(['A companion text file already exists for at '...
        'least one file, would you like to overwrite them or rename'...
        ' them?'],'Overwrite?','Overwrite','Rename Each','Cancel',...
        'Overwrite');                                                       %Ask the user if they want to overwrite or rename the files.
    if isempty(temp) || strcmpi(temp,'Cancel')                              %If the user cancelled the dialog box...
        return                                                              %Exit the function.
    else                                                                    %Otherwise...
        overwrite = strcmpi(temp,'Overwrite');                              %Set the overwriting setting to that chosen by the user.
    end
end

%Now step through each file and export a companion *.txt file for each.

for f = 1:length(files)                                                     %Step through each file.
    data = ArdyMotorFileRead(files{f});                                     %Read in the data from the *.ArdyMotor file.
    if ~isfield(data,'trial') || isempty(data.trial)                        %If there's no trials in this data file...
        warning('ARDYMOTOR2TEXT:NoTrials',['WARNING FROM '...
            'ARDYMOTOR2TEXT: The file "' files{f} '" has zero trials '...
            'and will be skipped.']);                                       %Show a warning.
        continue                                                            %Skip to the next file.
    end
    
    if strcmpi(data.threshtype,'bidirectional')                             %If the threshold type is "bidirectional"...
        data.threshtype = 'degrees (bidirectional)';                        %Change the threshold type to "degrees (bidirectional)".
    end
    
    %   Create the companion *.txt file name and check or overwriting...
    newfile = [files{f}(1:end-10) '.txt'];                                  %Create a filename for the text file.
    if exist([pwd '/' newfile],'file') && overwrite == 0                    %If the new file already exists in this folder...
        [newfile, path] = uiputfile('*.txt','Name Companion File',...
            newfile);                                                       %Ask the user for a new filename.
        if newfile(1) == 0                                                  %If the user selected cancel...
            return                                                          %Exit the function.
        else                                                                %Otherwise...
            cd(path);                                                       %Step into the specified directory.
        end
    end
    disp(['ARDYMOTOR2TEXT: Writing "' newfile '"']);                        %Show the user the filename being written.
    fid = fopen(newfile,'wt');                                              %Open a new text file to write the trial data to.
    %     clc;                                                                    %Clear the command window during debugging.
    %     fid = 1;                                                                %Have the function write to the command line for debugging.
    
    %Write the file header.
    fprintf(fid,'%s\t','Subject:');                                         %Write a label for the subject name.
    fprintf(fid,'%s\n',data.rat);                                           %Write the subject's name.
    fprintf(fid,'%s\t','Date:');                                            %Write a label for the date.
    fprintf(fid,'%s\n',datestr(data.trial(1).starttime,23));                %Write the date.
    fprintf(fid,'%s\t','Stage:');                                           %Write a label for the stage.
    fprintf(fid,'%s\n',data.stage);                                         %Write the stage.
    fprintf(fid,'%s\t','Device:');                                          %Write a label for the device type.
    fprintf(fid,'%s\n',data.device);                                        %Write the device type.
    fprintf(fid,'%s\t','Device Position:');                                 %Write a label for the device position.
    fprintf(fid,'%f\n',data.position);                                      %Write the device position.
    fprintf(fid,'%s\t','Constraint:');                                      %Write a label for the constraint.
    fprintf(fid,'%s\n',data.constraint);                                    %Write the constraint.
    fprintf(fid,'%s\t','Trial Initiation Threshold:');                      %Write a label for the trial initiation threshold.
    fprintf(fid,'%1.2f ',data.trial(1).init);                               %Write the trial initiation threshold.
    fprintf(fid,'%s\n',data.threshtype);                                    %Write the threshold units.
    fprintf(fid,'%s\t','Hit Threshold:');                                   %Write a label for the hit threshold.
    fprintf(fid,'%1.2f ',data.trial(1).thresh);                             %Write the hit threshold.
    fprintf(fid,'%s\n',data.threshtype);                                    %Write the threshold units.
    fprintf(fid,'%s\t','Hit Window:');                                      %Write a label for the hit threshold.
    fprintf(fid,'%1.2f ',data.trial(1).hitwin);                             %Write the hit window.
    fprintf(fid,'%s\n\n','s');                                              %Write the hit window units.
    
    %Write the overall session results.
    temp = mean([data.trial.outcome] == 'H');                               %Calculate the overall hit rate.
    fprintf(fid,'%s\t','Overall Hit Rate:');                                %Write a label for the overall hit rate.
    fprintf(fid,'%1.2f',100*temp);                                          %Write the overall hit rate.
    fprintf(fid,'%s\n','%');                                                %Write a percentage label.
    fprintf(fid,'%s\t','Hits:');                                            %Write a label for the number of hits.
    fprintf(fid,'%1.0f\n',sum([data.trial.outcome] == 'H'));                %Write the number of hits.
    fprintf(fid,'%s\t','Misses:');                                          %Write a label for the number of misses.
    fprintf(fid,'%1.0f\n',sum([data.trial.outcome] == 'M'));                %Write the number of misses.
    
    total_mean_distance = nan(1, length(data.trial));
    total_latency_to_hit = nan(1, length(data.trial));
    total_peak_velocity = nan(1, length(data.trial));
    total_peak_acceleration = nan(1, length(data.trial));
    total_num_turns = nan(1, length(data.trial));
    total_mean_turn_distance = nan(1, length(data.trial));
    total_threshold = nan(1, length(data.trial));
    
    days = 1:length(data.trial);
    
    for t = 1:length(data.trial)                                            %Step through each trial.
        %         a = find((data.trial(t).sample_times >= 0 & ...
        %             data.trial(t).sample_times < 1000*data.trial(t).hitwin));       %Find all samples within the hit window.
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
        
    end
    
    Mean_total_mean_distance = ones(1,max(days))*nanmean(total_mean_distance);
    Mean_total_latency_to_hit = ones(1,max(days))*nanmean(total_latency_to_hit);
    Mean_total_peak_velocity = ones(1,max(days))*nanmean(total_peak_velocity);
    Mean_total_peak_acceleration = ones(1,max(days))*nanmean(total_peak_acceleration);
    Mean_total_num_turns = ones(1,max(days))*nanmean(total_num_turns);
    Mean_total_mean_turn_distance = ones(1,max(days))*nanmean(total_mean_turn_distance);
    
    figure(30);
    subplot(3,2,1);
    hold on;
    scatter(days,total_mean_distance);
    hold off;
    hold on;
    plot(days, Mean_total_mean_distance, 'Color', 'r');
    hold off;
    hold on;
    plot(days, total_threshold, 'Color', 'k');
    hold off;
    legend('Max Distance turned', ['Mean:' num2str(max(Mean_total_mean_distance))],...
        ['Threshold:' num2str(max(total_threshold))]);
    title('Max Distance Turned', 'FontWeight', 'bold', 'FontSize', 12);
    xlabel('Trials');
    ylabel('Distance (degrees)');
    
    
    subplot(3,2,2);
    scatter(days,total_latency_to_hit);
    hold on;
    plot(days, Mean_total_latency_to_hit, 'Color', 'r');
    legend('Latency to hit', ['Mean:' num2str(max(Mean_total_latency_to_hit))]);
    title('Latency to Hit', 'FontWeight', 'bold', 'FontSize', 12);
    xlabel('Trials');
    ylabel('Time (ms)');
    
    
    
    subplot(3,2,3);
    scatter(days,total_peak_velocity);
    hold on;
    plot(days, Mean_total_peak_velocity, 'Color', 'r');
    legend('Peak Velocity', ['Mean:' num2str(max(Mean_total_peak_velocity))]);
    title('Peak Velocity', 'FontWeight', 'bold', 'FontSize', 12);
    xlabel('Trials');
    ylabel('Velocity (degrees per 10ms)');
    
    subplot(3,2,4);
    scatter(days,total_peak_acceleration);
    hold on;
    plot(days, Mean_total_peak_acceleration, 'Color', 'r');
    legend('Peak Acceleration', ['Mean:' num2str(max(Mean_total_peak_acceleration))]);
    title('Peak Acceleration', 'FontWeight', 'bold', 'FontSize', 12);
    xlabel('Trials');
    ylabel('Acceleration (degrees per 10ms^2)');
    
    subplot(3,2,5);
    scatter(days,total_num_turns);
    hold on;
    plot(days, Mean_total_num_turns, 'Color', 'r');
    legend('Number of Turns', ['Mean:' num2str(max(Mean_total_num_turns))]);
    title('Number of Turns', 'FontWeight', 'bold', 'FontSize', 12);
    xlabel('Trials');
    ylabel('Turns');
    
    subplot(3,2,6);
    scatter(days,total_mean_turn_distance);
    hold on;
    plot(days, Mean_total_mean_turn_distance, 'Color', 'r');
    legend('Mean Turn distance', ['Mean:' num2str(max(Mean_total_mean_turn_distance))]);
    title('Mean Turn Distance per Trial', 'FontWeight', 'bold', 'FontSize', 12);
    xlabel('Trials');
    ylabel('Distance (degrees)');
    
    
    fprintf(fid,'%s\t','Mean Max Turn Distance for Session:');              %Write a label for the average response.
    fprintf(fid,'%1.2f ',mean([data.trial.max]));                           %Write the average maximum.
    fprintf(fid,'%s\n',data.threshtype);                                    %Write the threshold units.
    
    fprintf(fid, '%s\t', 'Standard Deviation:');
    fprintf(fid, '%1.2f\n', std([data.trial.max]));
    
    fprintf(fid, '%s\t', 'Max of Signal (deg):');
    fprintf(fid, '%f\n', max([data.trial.max]));
    
    fprintf(fid, '%s\t', 'Min of Signal (deg):');
    fprintf(fid, '%f\n', min([data.trial.min]));
    
    fprintf(fid, '%s\t', 'Mean Peak Velocity (deg/10ms):');
    fprintf(fid, '%f\n', nanmean([data.trial.peak_velocity]));
    
    fprintf(fid, '%s\t', 'Mean Peak Acceleration (deg/10ms^2):');
    fprintf(fid, '%f\n', nanmean([data.trial.peak_acceleration]));
    
    fprintf(fid, '%s\t', 'Mean Number of Turns:');
    fprintf(fid, '%f\n', nanmean([data.trial.num_turns]));
    
    fprintf(fid, '%s\t', 'Mean Latency to Hit (ms):');
    fprintf(fid, '%f\n', nanmean([data.trial.latency_to_hit]));
    
    fprintf(fid, '%s\t', 'Total Mean Turn Distance (deg):');
    fprintf(fid, '%f\n\n', nanmean([data.trial.mean_turn_distance]));
    
    %Write the column labels.
    fprintf(fid,'%s\t','Trial ');                                            %Write a column label for the trial number.
    fprintf(fid,'%s\t\t','Time');                                             %Write a column label for the time.
    fprintf(fid,'%s\t\t','Outcome');                                          %Write a column label for the outcome.
    fprintf(fid,'%s\t\t','degrees');                                    %Write a column for the signal units.
    fprintf(fid,'%s\t', 'Hit Thres');                                   %Write a column for hit threshold
    fprintf(fid,'%s\t','Peak Vel');                                          %Write a column label for the
    fprintf(fid,'%s\t','Peak Accel');                                          %Write a column label for the .
    fprintf(fid,'%s\t','# of Turns');                                          %Write a column label for the .
    fprintf(fid,'%s\t','Latency to hit');                                          %Write a column label for the .
    fprintf(fid,'%s\n','Avg turn distance');
    
    %Write all of the trial data.
    for t = 1:length(data.trial)                                            %Step through each trial.
        fprintf(fid,'%1.0f\t',t);                                           %Write the trial number.
        fprintf(fid,'%s\t',datestr(data.trial(t).starttime,13));            %Write the trial time.
        fprintf(fid,'%s\t\t',char(data.trial(t).outcome));                    %Write the trial outcome.
        fprintf(fid,'%1.2f\t\t',data.trial(t).max);                           %Write the hit window signal maximum.
        fprintf(fid,'%1.2f\t\t',data.trial(t).thresh);
        fprintf(fid,'%1.2f\t\t',data.trial(t).peak_velocity);
        fprintf(fid,'%1.2f\t\t',data.trial(t).peak_acceleration);
        fprintf(fid,'%1.2f\t\t',data.trial(t).num_turns);
        fprintf(fid,'%1.2f\t\t',data.trial(t).latency_to_hit);
        fprintf(fid,'%1.2f\n',data.trial(t).mean_turn_distance);
    end
    
    fclose(fid);                                                            %Close the text file.
end
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