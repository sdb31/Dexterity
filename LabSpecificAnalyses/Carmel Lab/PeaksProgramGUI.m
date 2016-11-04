function PeaksProgramGUI(varargin)
[files, path] = uigetfile('*.ArdyMotor', ...
    'Select Animal(s) Data', ...
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
knob_data.trial_length = 500;                                           %Set the number of points collected in each trial
knob_data.num_sessions = length(files);                                 %Initialize combined session length
knob_data.combined_sessions_length = 0;
knob_data.session_length = nan(1, length(files));
knob_data.max_session_trials = 0;
for s = 1:knob_data.num_sessions                                        %For loop to collect and sort the data into sessions
    data = ArdyMotorFileRead(files{s});
    temp = length(data.trial);
    knob_data.combined_length = temp+knob_data.combined_sessions_length;
    knob_data.session_length(s) = temp;
    if knob_data.session_length(s) > knob_data.max_session_trials;
        knob_data.max_session_trials = knob_data.session_length(s);
    end
end
knob_data.combined_trials = nan(knob_data.combined_length, 500);
knob_data.trial = nan(knob_data.max_session_trials, 500, knob_data.num_sessions);
for s = 1:knob_data.num_sessions
    data = ArdyMotorFileRead(files{s});
    for t = 1:knob_data.session_length(s);
        knob_data.trial(t, :, s) = data.trial(t).signal;                %Grabs the signal
    end
end
%% User defined variables
Weeks = inputdlg('How many data sets would you like to analyze?', 'Data Sets', [1 50]);
Weeks = Weeks{:};
Weeks = str2double(Weeks);
Sessions = inputdlg('How many sessions are in each data set?', 'Sessions per Data Set', [1 50]);
Sessions = strsplit(Sessions{:});
Sessions = str2double(Sessions);
Titles = inputdlg('List the titles of each data set followed by a space', 'Data Set Titles', [1 50]);
Titles = strsplit(Titles{:});
Analysis_Type = inputdlg('Please write ''Random'', ''All Points'', or ''First Points''', 'Data Analysis', [1 50]);
Analysis_Type = Analysis_Type{:};                                                    %Number of sessions in each time point

%% Initialize Variables
Session_Count = zeros(1,(length(Sessions)+1));
for i = 1:length(Sessions);
    Session_Count(i+1) = sum(Sessions(1:i));
end
for i = 1:length(Sessions);
    Weekly_Trial_Sum(i) = sum(knob_data.session_length((Session_Count(i)+1):(Session_Count(i+1))));
end
Min_Random_Trials = round(0.9*min(Weekly_Trial_Sum));
Counter = ones(1,7);


%% Plots and Analysis
switch Analysis_Type
    case 'Random'
        for i = 1:Weeks;
            figure(i+1); clf;
            TempMatrix = [];
            for m = (Session_Count(i)+1):(Session_Count(i+1));
                for t = 1:knob_data.session_length(m)
                    [row, col] = find(knob_data.trial(t,:,m) == max(max(knob_data.trial(t,:,m))),1);
                    TempMatrix(Counter(i),:) = [col, knob_data.trial(t,col,m)];
                    Counter(i) = Counter(i) + 1;
                end
            end
            TempMatrix = datasample(TempMatrix,Min_Random_Trials,'Replace',false);
            OVL_Mean_Time(i) = nanmean(TempMatrix(:,1));
            OVL_Mean_Peak(i) = nanmean(TempMatrix(:,2));
            Time_STD(i) = std(TempMatrix(:,1),0,1);
            Peak_STD(i) = std(TempMatrix(:,2),0,1);
            plot(TempMatrix(:,1), TempMatrix(:,2), 'bo', 'MarkerSize', 2);
            hold on;
            plot(OVL_Mean_Time(i), OVL_Mean_Peak(i), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
            errorbarxy(OVL_Mean_Time(i), OVL_Mean_Peak(i), Time_STD(i), Peak_STD(i), {'k.', 'k', 'k'});
            hold off;
            title(Titles(i), 'Fontsize', 10, 'Fontweight', 'normal');
            set(gca, 'TickDir', 'out', 'YLim', [-25 150], 'YTick', -25:25:150, 'XLim', [0 500], 'XTick', 0:100:500);
            ylabel('Angle (degrees)', 'Fontsize', 10);
            box off;
        end
    case 'All Points'
        for i = 1:Weeks;
            figure(i+1); clf;
            TempMatrix = [];
            for m = (Session_Count(i)+1):(Session_Count(i+1));
                for t = 1:knob_data.session_length(m)
                    [row, col] = find(knob_data.trial(t,:,m) == max(max(knob_data.trial(t,:,m))),1);
                    TempMatrix(Counter(i),:) = [col, knob_data.trial(t,col,m)];
                    Counter(i) = Counter(i) + 1;
                end
            end
            OVL_Mean_Time(i) = nanmean(TempMatrix(:,1));
            OVL_Mean_Peak(i) = nanmean(TempMatrix(:,2));
            Time_STD(i) = std(TempMatrix(:,1),0,1);
            Peak_STD(i) = std(TempMatrix(:,2),0,1);
            plot(TempMatrix(:,1), TempMatrix(:,2), 'bo', 'MarkerSize', 2);
            hold on;
            plot(OVL_Mean_Time(i), OVL_Mean_Peak(i), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
            errorbarxy(OVL_Mean_Time(i), OVL_Mean_Peak(i), Time_STD(i), Peak_STD(i), {'k.', 'k', 'k'});
            hold off;
            title(Titles(i), 'Fontsize', 10, 'Fontweight', 'normal');
            set(gca, 'TickDir', 'out', 'YLim', [-25 150], 'YTick', -25:25:150, 'XLim', [0 500], 'XTick', 0:100:500);
            ylabel('Angle (degrees)', 'Fontsize', 10);
            box off;
        end
    case 'First Points'
        for i = 1:Weeks;
            figure(i+1); clf;
            TempMatrix = [];
            for m = (Session_Count(i)+1):(Session_Count(i+1));
                for t = 1:knob_data.session_length(m)
                    [row, col] = find(knob_data.trial(t,:,m) == max(max(knob_data.trial(t,:,m))),1);
                    TempMatrix(Counter(i),:) = [col, knob_data.trial(t,col,m)];
                    Counter(i) = Counter(i) + 1;
                    if Counter(i) >= Min_Random_Trials;
                        break;
                    end
                end
                if Counter >= Min_Random_Trials
                    break;
                end
            end
            OVL_Mean_Time(i) = nanmean(TempMatrix(:,1));
            OVL_Mean_Peak(i) = nanmean(TempMatrix(:,2));
            Time_STD(i) = std(TempMatrix(:,1),0,1);
            Peak_STD(i) = std(TempMatrix(:,2),0,1);
            plot(TempMatrix(:,1), TempMatrix(:,2), 'bo', 'MarkerSize', 2);
            hold on;
            plot(OVL_Mean_Time(i), OVL_Mean_Peak(i), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
            errorbarxy(OVL_Mean_Time(i), OVL_Mean_Peak(i), Time_STD(i), Peak_STD(i), {'k.', 'k', 'k'});
            hold off;
            title(handles.Titles(i), 'Fontsize', 10, 'Fontweight', 'normal');
            set(gca, 'TickDir', 'out', 'YLim', [-25 150], 'YTick', -25:25:150, 'XLim', [0 500], 'XTick', 0:100:500);
            ylabel('Angle (degrees)', 'Fontsize', 10);
            box off;
        end
end

%% Overall Means Plot
PeakSE = Peak_STD./sqrt(200);
TimeSE = Time_STD./sqrt(200);
Colors1 = 'kgbcymr';
Colors2 = 'kogobocoyomoro';
Colors3 = 'k.g.b.c.y.m.r.';

% Figure Creation
FF = 2*Weeks+4;
figure(FF); clf;
subplot(2,2,[1 3]);
for p = 1:Weeks;
    hold on;
    plot(OVL_Mean_Time(p), OVL_Mean_Peak(p), Colors2((2*p-1):2*p), 'MarkerSize', 6, 'MarkerFaceColor', Colors1(p));
    errorbarxy(OVL_Mean_Time(p), OVL_Mean_Peak(p), TimeSE(p), PeakSE(p), {Colors3((2*p-1):2*p), Colors1(p), Colors1(p)});
    hold off;
end

ylabel('Degrees', 'Fontsize', 10); xlabel('Time (ms)', 'Fontsize', 10);
set(gca, 'TickDir', 'out');
%     legend(gca, Weeks(i), 0);
box off;

s1 = subplot(2,2,2);
b = bar(Peak_STD); b.FaceColor = 'b';
set(s1, 'XTickLabel', Titles);
title(s1, 'Degree STD', 'Fontweight', 'normal', 'Fontsize', 10);
box off;

s2 = subplot(2,2,4);
b2 = bar(Time_STD); b2.FaceColor = 'b';
set(s2, 'XTickLabel', Titles);
title(s2, 'Time STD', 'Fontweight', 'normal', 'Fontsize', 10);
box off;
end