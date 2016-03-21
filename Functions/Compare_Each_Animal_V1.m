function Compare_Each_Animal_V1(varargin)
Ask_Number_of_Animals = inputdlg('Number of Animals to Analyze', 'Animals', [1 35]);
Number_of_Animals = str2num(Ask_Number_of_Animals{:});
Retroactive_HIT = nan(500,30,Number_of_Animals);
Mean_Distance_PP = nan(500,30,Number_of_Animals);
Latency_PP = nan(500,30,Number_of_Animals);
Peak_Vel_PP = nan(500,30,Number_of_Animals);
Peak_Accel_PP = nan(500,30,Number_of_Animals);
Turns_PP = nan(500,30,Number_of_Animals);
Mean_Turn_Distance_PP = nan(500,30,Number_of_Animals);
Max_Mean_TD_PP = nan(500,30,Number_of_Animals);
Hit_PP = nan(500,30,Number_of_Animals);
Trials_PP = nan(500,30,Number_of_Animals);
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
    AskSessions = inputdlg('How many sessions are in each week?', 'Session Count');
    Sessions_Per_Week(:,N) = str2num(AskSessions{:});    
    AskAnimalName = inputdlg('What''s the animal''s ID?', 'Animal ID');
    Animal_Name(N) = AskAnimalName;    
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
%         Output(f,:) = table(Date, Stage, Trials, Misses, Hits, Hit, Mean_Distance);
    end
    Session_Count = zeros(1,(size(Sessions_Per_Week,1)+1));
    for s = 1:length(files);                                      %For loop to collect and sort the data into sessions
        data = ArdyMotorFileRead(files{s});
        temp = length(data.trial);
        knob_data.session_length(s) = temp;
    end
    for i = 1:size(Sessions_Per_Week,1);
        Session_Count((i+1),N) = sum(Sessions_Per_Week(1:i,N));
    end
    for i = 1:size(Sessions_Per_Week,1);
        Weekly_Trial_Sum(i) = sum(knob_data.session_length((Session_Count(i,N)+1):(Session_Count((i+1),N))));
    end
    Min_Random_Trials = round(0.9*min(Weekly_Trial_Sum));
    Counter = ones(1,7);    
    
%     Retroactive_HIT = nan(length(files), length(files));
%     Mean_Distance_PP = nan(length(files), length(files));
%     Latency_PP = nan(length(files), length(files));
%     Peak_Vel_PP = nan(length(files), length(files));
%     Peak_Accel_PP = nan(length(files), length(files));
%     Turns_PP = nan(length(files), length(files));
%     Mean_Turn_Distance_PP = nan(length(files), length(files));
%     Max_Mean_TD_PP = nan(length(files), length(files));
%     Hit_PP = nan(length(files), length(files));
%     Trials_PP = nan(length(files), length(files));
    
    for i = 1:size(Sessions_Per_Week,1);
        for m = (Session_Count(i,N)+1):(Session_Count((i+1),N));
            Retroactive_HIT(m,i,N) = HIT2(m,N);
            Mean_Distance_PP(m,i,N) = Mean_Distance(m,N);
            Latency_PP(m,i,N) = Latency(m,N);
            Peak_Vel_PP(m,i,N) = Peak_Vel(m,N);
            Peak_Accel_PP(m,i,N) = Peak_Accel(m,N);
            Turns_PP(m,i,N) = Turns(m,N);
            Mean_Turn_Distance_PP(m,i,N) = Mean_Turn_Distance(m,N);
            Max_Mean_TD_PP(m,i,N) = Max_Mean_TD(m,N);
            Hit_PP(m,i,N) = Hit(m,N);
            Trials_PP(m,i,N) = Trials(m,N);
        end 
    end
%     Retroactive_Hit_Temp = nanmean(Retroactive_HIT(:,:,N))';
%     Retroactive_Hit_Final(:,N) = Retroactive_Hit_Temp(:,:);
%     Retroactive_Hit_Final_STD(:,N) = nanstd(Retroactive_HIT(:,:))';
%     Mean_Distance_Final(:,N) = nanmean(Mean_Distance_PP(:,:))';
%     Mean_Distance_Final_STD(:,N) = nanstd(Mean_Distance_PP(:,:))';
%     Latency_Final(:,N) = nanmean(Latency_PP(:,:))';
%     Latency_Final_STD(:,N) = nanstd(Latency_PP(:,:))';
%     Peak_Vel_Final(:,N) = (nanmean(Peak_Vel_PP(:,:))')*100;
%     Peak_Vel_Final_STD(:,N) = nanstd(Peak_Vel_PP(:,:)*100)';
%     Peak_Accel_Final(:,N) = nanmean(Peak_Accel_PP(:,:))';
%     Peak_Accel_Final_STD(:,N) = nanstd(Peak_Accel_PP(:,:))';
%     Turns_Final(:,N) = nanmean(Turns_PP(:,:))';
%     Turns_Final_STD(:,N) = nanstd(Turns_PP(:,:))';
%     Mean_Turn_Distance_Final(:,N) = nanmean(Mean_Turn_Distance_PP(:,:))';
%     Mean_Turn_Distance_Final_STD(:,N) = nanstd(Mean_Turn_Distance_PP(:,:))';
%     Max_Mean_TD_Final(:,N) = nanmean(Max_Mean_TD_PP(:,:))';
%     Max_Mean_TD_Final_STD(:,N) = nanstd(Max_Mean_TD_PP(:,:))';
%     Hit_Final(:,N) = nanmean(Hit_PP(:,:))';
%     Hit_Final_STD(:,N) = nanstd(Hit_PP(:,:))';
%     Trials_Final(:,N) = nanmean(Trials_PP(:,:))';
%     Trials_Final_STD(:,N) = nanstd(Trials_PP(:,:))';
end
for i = 1:Number_of_Animals;
    Retroactive_Hit_Final(i,:) = nanmean(Retroactive_HIT(:,:,i));
    Retroactive_Hit_Final_STD(i,:) = nanstd(Retroactive_HIT(:,:,i));
    Mean_Distance_Final(i,:) = nanmean(Mean_Distance_PP(:,:,i));
    Mean_Distance_Final_STD(i,:) = nanstd(Mean_Distance_PP(:,:,i));
    Latency_Final(i,:) = nanmean(Latency_PP(:,:,i));
    Latency_Final_STD(i,:) = nanstd(Latency_PP(:,:,i));
    Peak_Vel_Final(i,:) = (nanmean(Peak_Vel_PP(:,:,i)))*100;
    Peak_Vel_Final_STD(i,:) = nanstd(Peak_Vel_PP(:,:,i)*100);
    Peak_Accel_Final(i,:) = nanmean(Peak_Accel_PP(:,:,i));
    Peak_Accel_Final_STD(i,:) = nanstd(Peak_Accel_PP(:,:,i));
    Turns_Final(i,:) = nanmean(Turns_PP(:,:,i));
    Turns_Final_STD(i,:) = nanstd(Turns_PP(:,:,i));
    Mean_Turn_Distance_Final(i,:) = nanmean(Mean_Turn_Distance_PP(:,:,i));
    Mean_Turn_Distance_Final_STD(i,:) = nanstd(Mean_Turn_Distance_PP(:,:,i));
    Max_Mean_TD_Final(i,:) = nanmean(Max_Mean_TD_PP(:,:,i));
    Max_Mean_TD_Final_STD(i,:) = nanstd(Max_Mean_TD_PP(:,:,i));
    Hit_Final(i,:) = nanmean(Hit_PP(:,:,i));
    Hit_Final_STD(i,:) = nanstd(Hit_PP(:,:,i));
    Trials_Final(i,:) = nanmean(Trials_PP(:,:,i));
    Trials_Final_STD(i,:) = nanstd(Trials_PP(:,:,i));
end
XTickLabels_temp = inputdlg('X Tick Labels', 'Tick Labels');
XTickLabels = strsplit(XTickLabels_temp{:});
while length(XTickLabels) ~= size(Sessions_Per_Week,1)
   msgbox('Please use the same number of labels as there are weeks')
   pause(4);
   XTickLabels_temp = inputdlg('X Tick Labels', 'Tick Labels');
   XTickLabels = strsplit(XTickLabels_temp{:});
   if length(XTickLabels) == size(Sessions_Per_Week,1)
       break
   end
end
[FileName, PathName] = uiputfile('*.xlsx', 'Save Output Excel File As'); 
Path = sprintf('%s\%s', PathName, FileName);
Hit_Final = Hit_Final'; 
Hit_Final_STD = Hit_Final_STD';
Mean_Distance_Final = Mean_Distance_Final';
Mean_Distance_Final_STD = Mean_Distance_Final_STD';
Latency_Final = Latency_Final';
Latency_Final_STD = Latency_Final_STD';
Peak_Vel_Final = Peak_Vel_Final';
Peak_Vel_Final_STD = Peak_Vel_Final_STD';
Peak_Accel_Final = Peak_Accel_Final';
Peak_Accel_Final_STD = Peak_Accel_Final_STD';
Turns_Final = Turns_Final';
Turns_Final_STD = Turns_Final_STD';
Mean_Turn_Distance_Final = Mean_Turn_Distance_Final';
Mean_Turn_Distance_Final_STD = Mean_Turn_Distance_Final_STD;
Max_Mean_TD_Final = Max_Mean_TD_Final';
Max_Mean_TD_Final_STD = Max_Mean_TD_Final_STD';
Trials_Final = Trials_Final';
Trials_Final_STD = Trials_Final_STD';
for i = 1:Number_of_Animals;
    Output = table(XTickLabels', Hit_Final(1:size(Sessions_Per_Week,1),i), Hit_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Mean_Distance_Final(1:size(Sessions_Per_Week,1),i), Mean_Distance_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Latency_Final(1:size(Sessions_Per_Week,1),i), Latency_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Peak_Vel_Final(1:size(Sessions_Per_Week,1),i), Peak_Vel_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Peak_Accel_Final(1:size(Sessions_Per_Week,1),i), Peak_Accel_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Turns_Final(1:size(Sessions_Per_Week,1),i), Turns_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Mean_Turn_Distance_Final(1:size(Sessions_Per_Week,1),i), Mean_Turn_Distance_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Max_Mean_TD_Final(1:size(Sessions_Per_Week,1),i), Max_Mean_TD_Final_STD(1:size(Sessions_Per_Week,1),i),...
        Trials_Final(1:size(Sessions_Per_Week,1),i), Trials_Final_STD(1:size(Sessions_Per_Week,1),i), 'VariableNames', {'XTickLabel', 'Hit', 'HitSTD',...
        'MeanDistance', 'MeanDistanceSTD', 'Latency', 'LatencySTD', 'PeakVelocity', 'PeakVelocitySTD',...
        'PeakAcceleration', 'PeakAccelerationSTD', 'Turns', 'TurnsSTD', 'MeanTurnDistance', 'MeanTurnDistanceSTD',...
        'MaxTurnDistance', 'MaxTurnDistanceSTD', 'Trials', 'TrialsSTD'});
    writetable(Output, Path, 'Sheet', i);
    clearvars Output
end
%% Overall Means and Stds
for i = 1:Number_of_Animals;
    for j = 1:size(Sessions_Per_Week,1);
        Hit_Final_SE(i,j) = Hit_Final_STD(i,j)/sqrt(Sessions_Per_Week(j,i));
        Mean_Distance_Final_SE(i,j) = Mean_Distance_Final_STD(i,j)/sqrt(Sessions_Per_Week(j,i));
        Mean_Turn_Distance_Final_SE(i,j) = Mean_Turn_Distance_Final_STD(i,j)/sqrt(Sessions_Per_Week(j,i));
        Peak_Vel_Final_SE(i,j) = Peak_Vel_Final_STD(i,j)/sqrt(Sessions_Per_Week(j,i));
    end
end

Hit_Final_SE = Hit_Final_SE';
Mean_Distance_Final_SE = Mean_Distance_Final_SE';
Mean_Turn_Distance_Final_SE = Mean_Turn_Distance_Final_SE';
Peak_Vel_Final_SE = Peak_Vel_Final_SE';

numgroups = size(Sessions_Per_Week, 1);
numbars = size(Sessions_Per_Week, 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
ZERO = zeros(numbars,numbars);

figure(2); clf;
Success_Rate = bar(Hit_Final(1:numgroups,1:numbars)); 
set(gca, 'XTickLabel', XTickLabels, 'TickDir', 'out', 'YLim', [0 100]);
legend(Success_Rate, Animal_Name); ylabel('Success Rate (%)');
title('Success Rate Comparison', 'Fontweight', 'normal');
box off;
hold on;
for i = 1:numbars;
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups;
        errorbar(x(j), Hit_Final(j,i), ZERO(j,i), Hit_Final_SE(j,i), 'k', 'linestyle', 'none');
    end
end
hold off;

figure(3); clf;
MD = bar(Mean_Distance_Final(1:numgroups,1:numbars)); 
set(gca, 'XTickLabel', XTickLabels, 'TickDir', 'out');
legend(MD, Animal_Name); ylabel('Degrees');
title('Mean Distance Comparison', 'Fontweight', 'normal');
box off;
hold on;
for i = 1:numbars;
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups;
        errorbar(x(j), Mean_Distance_Final(j,i), ZERO(j,i), Mean_Distance_Final_SE(j,i), 'k', 'linestyle', 'none');
    end
end
hold off;
 
figure(4); clf;
MTD = bar(Mean_Turn_Distance_Final(1:numgroups,1:numbars));
set(gca, 'XTickLabel', XTickLabels, 'TickDir', 'out');
legend(MTD, Animal_Name); ylabel('Degrees');
title('Mean Turn Distance Comparison', 'Fontweight', 'normal');
box off;
hold on;
for i = 1:numbars;
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups;
        errorbar(x(j), Mean_Turn_Distance_Final(j,i), ZERO(j,i), Mean_Turn_Distance_Final_SE(j,i), 'k', 'linestyle', 'none');
    end
end
hold off;

figure(5); clf;
PV = bar(Peak_Vel_Final(1:numgroups,1:numbars));
set(gca, 'XTickLabel', XTickLabels, 'TickDir', 'out');
legend(PV, Animal_Name); ylabel('Velocity (deg/s)');
title('Peak Velocity Comparison', 'Fontweight', 'normal');
box off;
hold on;
for i = 1:numbars;
    x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);  % Aligning error bar with individual bar
    for j = 1:numgroups;
        errorbar(x(j), Peak_Vel_Final(j,i), ZERO(j,i), Peak_Vel_Final_SE(j,i), 'k', 'linestyle', 'none');
    end
end
hold off;
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
