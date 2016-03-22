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
%   Last modified January 28th, 2016, by Drew Sloan.

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
        if (version ~= -3 && version ~= -4)
            version = 1;                                                        %Set the file format version to 1.
        end
    end
% end

data.version = version;

if version < 0                                                              %If the file format version indicates ArdyMotor V2.0...
    
    if version == -1 || version <= -3
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
      
    if (version <= -3)
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
    if version == -1 || version <= -3                                       %If the file format version is -1...
        data.pre_trial_sampling_dur = 1000;                                 %Indicate 1000 milliseconds of pre-trial sampling.
    else                                                                    %Otherwise, for later versions...
        data.pre_trial_sampling_dur = fread(fid,1,'float32');               %Read in the pre-trial sampling duration (in milliseconds).
    end
    data.pauses = [];                                                       %Create a field in the data structure to hold pause times.
    data.manual_feeds = [];                                                 %Create a field in the data structure to hold manual feed times.
    while ~feof(fid)                                                        %Loop until the end of the file.
        trial = fread(fid,1,'uint32');                                      %Read in the trial number.
        if isempty(trial)                                                   %If no trial number was read or that's the end of the file...
            continue                                                        %Skip execution of the rest of the loop.
        end
        starttime = fread(fid,1,'float64');                                 %Read in the trial start time.
        outcome = fread(fid,1,'uint8');                                     %Read in the trial outcome.
        if feof(fid)                                                        %If we've reached the end of the file.
            continue                                                        %Skip execution of the rest of the loop.
        end
        if outcome == 'P'                                                   %If the outcome was a pause...
            temp = fread(fid,1,'float64');                                  %Read in the end time of the pause.
            data.pauses(end+1,1:2) = [starttime, temp];                     %Save the start and end time of the pause.
        elseif outcome == 'F'                                               %If the outcome was a manual feeding.
            data.manual_feeds(end+1,1) = starttime;                         %Save the timing of the manual feeding.
        elseif trial ~= 0                                                   %Otherwise, if the outcome was a hit or a miss...
            if fileinfo.datenum < 735122.5980                               %If a file was created before 9/10/2012...
                fseek(fid,-1,'cof');                                        %Rewind the file one byte.
            end
            data.trial(trial).starttime = starttime;                        %Save the trial start time.
            data.trial(trial).hitwin = fread(fid,1,'float32');              %Read in the hit window.
            data.trial(trial).init = fread(fid,1,'float32');                %Read in the initiation threshold.
            data.trial(trial).thresh = fread(fid,1,'float32');              %Read in the hit threshold.
            if version == -4                                                %If the file version is -4...
                data.trial(trial).ceiling = fread(fid,1,'float32');         %Read in the force ceiling.
            end
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
    temp = zeros(length(data.trial),1);                                     %Pre-allocation a matrix to mark incomplete trials for exclusion.
    for t = 1:length(data.trial)                                            %Step through each trial.
        if isempty(data.trial(t).signal)                                    %If a trial has no signal...
            temp(t) = 1;                                                    %Mark the trial for exclusion.
        end
    end
    data.trial(temp == 1) = [];                                             %Kick out all trials marked for exclusion.
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