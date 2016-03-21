function InactivationProgram(varargin)
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

valid2 = 0;
temp = inputdlg('Number of inactivation groups');
while valid2 < 1
    num_groups = str2num(temp{1});
    if isempty(num_groups) == 0
        valid2 = 1;
    else
        temp = inputdlg('Not a valid number');
    end
end
handles.num_groups = num_groups;

temp = inputdlg('Labels for inactivation groups');
group_names = strsplit(temp{:});
handles.group_names = group_names;

a = 1;
while a<= handles.num_animals
    files = cell(num_groups, 500);
    temp_files = cell(num_groups,500);
    path = cell(num_groups,500);
    for b = 1:handles.num_groups
        clear daycodes
        [temp_files path] = uigetfile('*.ArdyMotor', ...
            ['Select Animal ' num2str(a) ' ' char(handles.group_names(b)) ' data'], ...
            'multiselect','on');
        if ~iscell(temp_files) && temp_files(1) == 0                              %If no file was selected...
            return                                                              %Exit the function.
        end
        cd(path);                                                           %Change the current directory to the specified folder.
        if ischar(temp_files)                                                    %If only one file was selected...
            temp_files = {temp_files};                                            %Convert the string to a cell array.
        end
        temp = ArdyMotorFileRead(temp_files{1});
        handles.Rat_Name(a) = cellstr(temp.rat);
        %This code sorts the files by daycode in ardymotor function
        num_sessions = length(temp_files);
        
        for f = 1:num_sessions
            data = ArdyMotorFileRead(temp_files{f});
            daycodes(f) = data.daycode;
        end
        [B,IX] = sort(daycodes);
        for f = 1:num_sessions
            files(b,f) = temp_files(IX(f));
        end
        
    end
    handles.(temp.rat).files = files;                             %Store the pre_files 
    handles.(temp.rat).path = path;
    a = a+1;
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
