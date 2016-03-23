function InactivationProgram_V2(varargin)
valid = 0;
temp = inputdlg('Number of animals to analyze');
Titles = inputdlg('List the titles of each data set followed by a space', 'Data Set Titles', [1 50]);
Titles = strsplit(Titles{:});
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
        ['Select Animal ' num2str(a) ' Pre data'], ...
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
        ['Select Animal ' num2str(a) ' Post data'], ...
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
    Pre_Sessions = handles.(animal).pre.data.num_sessions;

    %% Do post-lesion file processing
    handles.(animal).post.data = TransformKnobData( ... 
        handles.(animal).post.files, handles.(animal).post.path);
    handles.(animal).post.trialdata = TransformTrialData( ...
        handles.(animal).post.files, handles.(animal).post.path);
    Post_Sessions = handles.(animal).post.data.num_sessions;
end

figure(2); clf;
for i = 1:Pre_Sessions;
    for t = 1:size(handles.(animal).pre.trialdata.trial(:,:,i), 1);
        hold on;
        patchline(1:500, handles.(animal).pre.trialdata.trial(t,:,i), 'edgecolor', 'b', 'linewidth', .5, 'edgealpha', 0.075);
        hold off;
    end
end
hold on;
Mean_Distance_Pre = handles.(animal).pre.data.mean_distance.sessionscombined';
boxplot(Mean_Distance_Pre, 'positions', 40, 'widths', 50, 'outliersize', 6, 'colors', 'b', 'symbol', 'b.');
hold off;
hold on;
Latency_Pre = handles.(animal).pre.data.latency_to_hit.sessionscombined';
boxplot(Latency_Pre, 'orientation', 'horizontal', 'widths', 30, 'positions', -20, 'outliersize', 6, 'colors', 'b', 'symbol', 'b.');
hold off;
box off; 
YTickLabels = -40:40:round(1.1*max(Mean_Distance_Pre));
set(gca, 'TickDir', 'out', 'YLim', [-40 round(1.1*max(Mean_Distance_Pre))], 'YTick', -40:40:round(1.1*max(Mean_Distance_Pre)), 'XLim', [0 350], 'XTick', 0:50:350, 'XTickLabels', {'0', '50', '100', '150', '200', '250', '300', '350'},...
            'YTickLabels', YTickLabels);
title(Titles(1), 'Fontweight', 'normal', 'Fontsize', 10);
ylabel('Supination (degrees)', 'Fontsize', 10);

figure(3); clf;
for i = 1:Post_Sessions;
    for t = 1:size(handles.(animal).post.trialdata.trial(:,:,i), 1);
        hold on;
        patchline(1:500, handles.(animal).post.trialdata.trial(t,:,i), 'edgecolor', 'b', 'linewidth', .5, 'edgealpha', 0.075);
        hold off;
    end
end
hold on;
Mean_Distance_Post = handles.(animal).post.data.mean_distance.sessionscombined';
boxplot(Mean_Distance_Post, 'positions', 40, 'widths', 50, 'outliersize', 6, 'colors', 'b', 'symbol', 'b.');
hold off;
hold on;
Latency_Post = handles.(animal).post.data.latency_to_hit.sessionscombined';
boxplot(Latency_Post, 'orientation', 'horizontal', 'widths', 30, 'positions', -20, 'outliersize', 6, 'colors', 'b', 'symbol', 'b.');
hold off;
box off; 
YTickLabels = -40:40:round(1.1*max(Mean_Distance_Post));
set(gca, 'TickDir', 'out', 'YLim', [-40 round(1.1*max(Mean_Distance_Post))], 'YTick', -40:40:round(1.1*max(Mean_Distance_Post)), 'XLim', [0 350], 'XTick', 0:50:350, 'XTickLabels', {'0', '50', '100', '150', '200', '250', '300', '350'},...
            'YTickLabels', YTickLabels);
title(Titles(2), 'Fontweight', 'normal', 'Fontsize', 10);
ylabel('Supination (degrees)', 'Fontsize', 10);

figure(5); clf;
Peak_Velocity_Pre = handles.(animal).pre.data.peak_velocity.sessionscombined';
Peak_Velocity_Post = handles.(animal).post.data.peak_velocity.sessionscombined';
set(gca, 'TickDir', 'out', 'XTickLabels', Titles);
box off;
title('Peak Velocity', 'Fontweight', 'normal', 'Fontsize', 10);
ylabel('Velocity (deg/s)', 'Fontsize', 10);



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
