function Knob_Analysis_Suite(varargin)
if ~exist('.git')
    path = 'cd C:\Desktop';
    cmd = [path...
        '& git clone https://github.com/sdb31/Knob_Analysis_Software.git'];
    [~,result] = system(cmd);
    msgbox(result,'Clone Status')
end
set(0,'units','centimeters');
pos = get(0,'screensize');
h = 0.4*pos(4);
w = 3.2*h/3;

handles.fig = figure('numbertitle','off',...
    'name','Dexterity',...
    'units','centimeters', 'Toolbar', 'none',...
    'menubar', 'none',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
handles.Subject_Timeline = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.15,.75,.7,.2],...
    'string','View Subject Timeline',...
    'fontsize',12);
handles.Analyze_Group_Data = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.15,.5,.7,.2],...
    'string','Analyze Group Data',...
    'fontsize',12);
handles.Lab_Specific_Analysis = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.15,.25,.7,.2],...
    'string','Lab Specific Analysis',...
    'fontsize',12);
Push = uicontrol('Parent',handles.fig,'Style','pushbutton','string','Push',...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.175 .05 .3 .15],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Pull = uicontrol('Parent',handles.fig,'Style','pushbutton','string','Pull',...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.525 .05 .3 .15],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
set(handles.Subject_Timeline, 'callback', @SubjectTimeline);
set(handles.Analyze_Group_Data, 'callback', @AnalyzeGroupData);
set(handles.Lab_Specific_Analysis, 'callback', @LabAnalysis);
set(Push,'callback', @PushFcn);
set(Pull,'callback', @PullFcn);
guidata(handles.fig, handles);

end

function PushFcn(hObject,~)
handles = guidata(hObject);
PushPath = uigetdir('C:\','Select folder you want to push');
PushPathCMD = ['cd ' PushPath];
cmd = [PushPathCMD...
    '& git status'...
    '& git commit -am "New Config File"'...
    '& git push'];
[~,result] = system(cmd);
msgbox(result,'Push Status')
guidata(handles.fig,handles);
end

function PullFcn(hObject,~)
handles = guidata(hObject);
PullPath = uigetdir('C:\','Select folder you want to pull');
PullPathCMD = ['cd ' PullPath];
cmd = [PullPathCMD...
    '& git status'...
    '& git pull'];
[~,result] = system(cmd);
msgbox(result,'Pull Status')
guidata(handles.fig,handles);
end

function SubjectTimeline(hObject,~)
handles = guidata(hObject);
MotoTrak_Analysis2
guidata(handles.fig,handles);
end

function AnalyzeGroupData(hObject,~)
handles = guidata(hObject);
AnalyzeGroup
guidata(handles.fig,handles);
end

function LabAnalysis(~,~)
% Table = readtable('LabSpecificAnalysisConfig.txt');
% Path = Table{:,2};
datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';                                         %Set the primary local data path for saving data files.
if ~exist(datapath,'dir')                                           %If the primary local data path doesn't already exist...
    mkdir(datapath);                                                %Make the primary local data path.
end
masterdatapath = 'C:\KnobAnalysis\Master_Lab_Specific_Config\';
if ~exist(masterdatapath,'dir');
    mkdir(masterdatapath);
end
% cd(datapath);
Info = dir(datapath);
if length(Info) < 3
    Load_or_Create = questdlg('Would you like to load a config file or add a new lab?',...
        'Load Config or Add Lab',...
        'Load Config', 'Add Lab', 'Cancel');
    switch Load_or_Create
        case 'Add Lab'
            
            Lab_Name = inputdlg('What is the name of the lab?', 'Lab Name', [1 50]);
            Lab_NameNS = char(Lab_Name); Lab_NameNS = Lab_NameNS(Lab_NameNS~=' ');
            functionspath = uigetdir('C:\', 'Where are your lab''s functions located?');
            ConfigFileName = [Lab_NameNS 'Config.mat'];
            config.Lab_Name = Lab_Name; config.path = functionspath;
            functionspath = [functionspath '\']; cd(functionspath); FctInfo = dir(functionspath);
            FctInfo = {FctInfo.name}; FctInfo = FctInfo(3:end);
            config.function_names = FctInfo;
            cd(datapath);
            configfolderpath = uigetdir('C:\','Where are KnobAnalysis config files located?');
            %config.masterconfigpath = configfolderpath;
            save(ConfigFileName, 'config');
            cd(configfolderpath); Info = dir(configfolderpath); ConfigNames = {Info.name};
            BoolCompare = strcmpi(ConfigFileName,ConfigNames);
            datapath = [datapath ConfigFileName];
            if any(BoolCompare) == 0;
                [Success,Message,MessageID] = copyfile(datapath,configfolderpath);
            end
            MasterConfigFileName = 'MasterConfig.mat'; cd(masterdatapath); save(MasterConfigFileName,'configfolderpath');
        case 'Load Config'
            configfolderpath = uigetdir('C:\','Where are Dexterity config files located?');
            MasterConfigFileName = 'MasterConfig.mat'; cd(masterdatapath); save(MasterConfigFileName,'configfolderpath');
            [FileName,PathName] = uigetfile('*.mat','Select the configuration file');
            datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';
            olddatapath = [PathName FileName];
            copyfile(olddatapath,datapath); %cd(datapath);
%             load(FileName);
    end
end
cd(datapath);
Info = dir(datapath); FileNames = {Info.name}; FileNames = FileNames(3:end);
for i = 1:length(FileNames);
    load(FileNames{i})
    LabNames(i) = config.Lab_Name;
    FileInfo(i).functions = config.function_names;
end
% load(FileNames{1}); Lab_Name = config.Lab_Name; Functions = config.function_names;
pos = get(0,'Screensize');                                              %Grab the screensize.
h = 9;                                                                 %Set the height of the figure, in centimeters.
w = 15;                                                                 %Set the width of the figure, in centimeters.
% FileNames = {};
fig = figure('numbertitle','off','units','centimeters',...
    'name','Lab Specific Analysis','menubar','none',...
    'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
Choose_Lab = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Please choose a lab:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.1 .9 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Analysis_Type = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'callback', {@AnalysisType},'string',FileInfo(1).functions,...
    'units', 'normalized', 'Position', [.525 .25 .45 .6]);
Lab_Name = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','string', LabNames,...
    'units', 'normalized', 'Position', [.025 .25 .45 .6],'callback',{@LabName,Analysis_Type},...
    'Fontsize', 12);
Lab_Functions = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Lab Functions', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.65 .9 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
MoreLabs = uicontrol('Parent',fig,'Style','pushbutton','string','Add New Lab',...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.15 .05 .3 .15],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
ConfigFile = uicontrol('Parent',fig,'Style','pushbutton','string','Load Config File',...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.55 .05 .3 .15],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
% Push = uicontrol('Parent',fig,'Style','pushbutton','string','Push',...
%     'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.65 .05 .1 .15],...
%     'Fontsize', 12, 'Fontweight', 'bold') ;
% Pull = uicontrol('Parent',fig,'Style','pushbutton','string','Pull',...
%     'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.8 .05 .1 .15],...
%     'Fontsize', 12, 'Fontweight', 'bold') ;
set(MoreLabs,'callback',{@AddNewLab,Lab_Name});
set(ConfigFile,'callback',{@LoadConfigFile,Lab_Name});
end

function LoadConfigFile(~,~,Lab_Name)
% datapath = 'C:\';
[FileName,PathName] = uigetfile('*.mat','Select the configuration file');
datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';
olddatapath = [PathName FileName];
copyfile(olddatapath,datapath); cd(datapath);
load(FileName); 

% masterdatapath = 'C:\KnobAnalysis\Master_Lab_Specific_Config\';
% cd(masterdatapath); load('MasterConfig.mat'); 
New_Lab_Name = config.Lab_Name; %NewFunctions = config.function_names;
LabNames = get(Lab_Name,'string'); LabNames(length(LabNames)+1) = New_Lab_Name;
set(Lab_Name,'string',LabNames);
% set(Analysis_Type,'string',Functions);
% set(Lab_Name,'string',LabName);
end

function AddNewLab(~,~,Lab_Name)
datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';                                         %Set the primary local data path for saving data files.
if ~exist(datapath,'dir')                                           %If the primary local data path doesn't already exist...
    mkdir(datapath);                                                %Make the primary local data path.
end
masterdatapath = 'C:\KnobAnalysis\Master_Lab_Specific_Config\';
cd(masterdatapath); load('MasterConfig.mat'); 

New_Lab_Name = inputdlg('What is the name of the lab?', 'Lab Name', [1 50]);
Lab_NameNS = char(New_Lab_Name); Lab_NameNS = Lab_NameNS(Lab_NameNS~=' ');
functionspath = uigetdir('C:\', 'Where are your lab''s functions located?');
ConfigFileName = [Lab_NameNS 'Config.mat'];
config.Lab_Name = New_Lab_Name; config.path = functionspath;
functionspath = [functionspath '\']; cd(functionspath); FctInfo = dir(functionspath);
FctInfo = {FctInfo.name}; FctInfo = FctInfo(3:end);
config.function_names = FctInfo;
cd(datapath); save(ConfigFileName, 'config');
LabNames = get(Lab_Name,'string'); LabNames(length(LabNames)+1) = New_Lab_Name;
set(Lab_Name,'string',LabNames);
cd(configfolderpath); Info = dir(configfolderpath); ConfigNames = {Info.name};
BoolCompare = strcmpi(ConfigFileName,ConfigNames);
datapath = [datapath ConfigFileName];
if any(BoolCompare) == 0;
    [Success,Message,MessageID] = copyfile(datapath,configfolderpath);
end
end

function LabName(hObject,~,Analysis_Type)
index_selected = get(hObject,'value'); 
string_selected = get(hObject,'string'); string_selected = string_selected(index_selected);
string_selected = char(string_selected);
string_selected = string_selected(string_selected ~= ' ');
configfile = [string_selected 'Config.mat'];
load(configfile);
Lab_Name = config.Lab_Name; Functions = config.function_names;
set(Analysis_Type,'string',Functions);
end

function AnalysisType(hObject,~)
index_selected = get(hObject,'value');
FileNames = get(hObject,'string');
Current_Selection = FileNames{index_selected};
try
    run(Current_Selection)
catch ME
    return
end
end