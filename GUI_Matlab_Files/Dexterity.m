function Dexterity(varargin)
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
w = 2.8*h/3;

handles.fig = figure('numbertitle','off',...
    'name','Dexterity',...
    'units','centimeters', 'Toolbar', 'none',...
    'menubar', 'none',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
handles.Subject_Timeline = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.15,.75,.7,.2],...
    'string','Subjects',...
    'fontsize',12);
handles.Analyze_Group_Data = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.15,.5,.7,.2],...
    'string','Experiments',...
    'fontsize',12);
handles.Lab_Specific_Analysis = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.15,.25,.7,.2],...
    'string','Labs',...
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
Subjects
guidata(handles.fig,handles);
end

function AnalyzeGroupData(hObject,~)
handles = guidata(hObject);
Experiments
guidata(handles.fig,handles);
end

function LabAnalysis(~,~)
datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';                                         %Set the primary local data path for saving data files.
if ~exist(datapath,'dir')                                           %If the primary local data path doesn't already exist...
    mkdir(datapath);                                                %Make the primary local data path.
end
masterdatapath = 'C:\KnobAnalysis\Master_Lab_Specific_Config\';
if ~exist(masterdatapath,'dir');
    mkdir(masterdatapath);
end

Info = dir(datapath);
if length(Info) < 3
    Load_or_Create = questdlg('Would you like to load a config file or add a new lab?',...
        'Load Existing or Add Lab',...
        'Load Existing', 'Add Lab', 'Cancel');
    switch Load_or_Create
        case 'Add Lab'
            Lab_Name = inputdlg('What is the name of the lab?', 'Lab Name', [1 50]);
            functionspath = uigetdir('C:\', 'Where are your lab''s functions located?');
%             cd(functionspath); 
            temp_directory = [char(datapath) char(Lab_Name) '\']; mkdir(temp_directory);
            functionspath = [functionspath '\'];
            [Success,Message,MessageID] = copyfile(functionspath,temp_directory);
            Lab_Analyses_Repository = [getenv('homedrive') getenv('homepath') filesep 'Desktop' filesep 'Knob_Analysis_Software' filesep 'LabSpecificAnalyses' filesep];
            Info = dir(Lab_Analyses_Repository); Repo_Labs = {Info.name};
            if length(Repo_Labs)<3
                source = ['C:\KnobAnalysis\Lab_Specific_Config_Files\' char(Lab_Name)];
                Lab_Analyses_Repository = [Lab_Analyses_Repository char(Lab_Name)];
                mkdir(Lab_Analyses_Repository); %cd(Lab_Analyses_Repository);
                [Success,Message,MessageID] = copyfile(source,Lab_Analyses_Repository);
            else
                BoolCompare = strcmpi(Lab_Name,Repo_Labs);
                if any(BoolCompare) == 0;
                    source = ['C:\KnobAnalysis\Lab_Specific_Config_Files\' char(Lab_Name)];
                    Lab_Analyses_Repository = [Lab_Analyses_Repository char(Lab_Name)];
                    mkdir(Lab_Analyses_Repository); %cd(Lab_Analyses_Repository);
                    [Success,Message,MessageID] = copyfile(source,Lab_Analyses_Repository);
                end
            end
        case 'Load Existing'
            Lab_Analyses_Repository = [getenv('homedrive') getenv('homepath') filesep 'Desktop' filesep 'Knob_Analysis_Software' filesep 'LabSpecificAnalyses' filesep];
            configfolderpath = uigetdir(Lab_Analyses_Repository,'Please select the lab folder where functions are located');
            temp_lab_name = find(configfolderpath == filesep);
            temp_lab_name = configfolderpath(temp_lab_name(end)+1:end); new_folder = ['C:\KnobAnalysis\Lab_Specific_Config_Files\' temp_lab_name];
            mkdir(new_folder); 
            [Success,Message,MessageID] = copyfile(configfolderpath,new_folder);
    end
end
Info = dir(datapath); LabNames = {Info.name}; LabNames = LabNames(3:end);
for i = 1:length(LabNames);
    temp_lab_directory = [datapath char(LabNames(i))];
    temp_filenames = dir(temp_lab_directory); temp_filenames = {temp_filenames.name};
    temp_filenames = temp_filenames(3:end);
    FileInfo(i).functions = temp_filenames;
    FileInfo(i).lab_directory = {temp_lab_directory};
end
pos = get(0,'Screensize');                                              %Grab the screensize.
h = 9;                                                                 %Set the height of the figure, in centimeters.
w = 15;                                                                 %Set the width of the figure, in centimeters.
fig = figure('numbertitle','off','units','centimeters',...
    'name','Dexterity: Labs','menubar','none',...
    'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
Choose_Lab = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Please choose a lab:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.1 .9 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Analysis_Type = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string',FileInfo(1).functions,...
    'units', 'normalized', 'Position', [.525 .25 .45 .6],'userdata', FileInfo);
Lab_Name = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','string', LabNames,...
    'units', 'normalized', 'Position', [.025 .25 .45 .6],'callback',{@LabName,Analysis_Type},...
    'Fontsize', 12);
Lab_Functions = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Lab Functions', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.65 .9 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
MoreLabs = uicontrol('Parent',fig,'Style','pushbutton','string','Add New Lab',...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.15 .05 .3 .15],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
ConfigFile = uicontrol('Parent',fig,'Style','pushbutton','string','Load Existing Lab',...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.55 .05 .3 .15],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
set(MoreLabs,'callback',{@AddNewLab,Analysis_Type,Lab_Name});
set(ConfigFile,'callback',{@LoadConfigFile,Lab_Name,Analysis_Type});
set(Analysis_Type,'callback',{@AnalysisType,Lab_Name});
end

function LoadConfigFile(~,~,Lab_Name,Analysis_Type)
Lab_Analyses_Repository = [getenv('homedrive') getenv('homepath') filesep 'Desktop' filesep 'Knob_Analysis_Software' filesep 'LabSpecificAnalyses' filesep];
configfolderpath = uigetdir(Lab_Analyses_Repository,'Please select the lab folder where functions are located');
temp_lab_name = find(configfolderpath == filesep);
temp_lab_name = configfolderpath(temp_lab_name(end)+1:end); new_folder = ['C:\KnobAnalysis\Lab_Specific_Config_Files\' temp_lab_name];
mkdir(new_folder);
[Success,Message,MessageID] = copyfile(configfolderpath,new_folder);
datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';  
Info = dir(datapath); LabNames = {Info.name}; LabNames = LabNames(3:end);
for i = 1:length(LabNames);
    temp_lab_directory = [datapath char(LabNames(i))];
    temp_filenames = dir(temp_lab_directory); temp_filenames = {temp_filenames.name};
    temp_filenames = temp_filenames(3:end);
    FileInfo(i).functions = temp_filenames;
    FileInfo(i).lab_directory = {temp_lab_directory};
end
set(Analysis_Type,'userdata',FileInfo);
set(Lab_Name,'string',LabNames);
end

function AddNewLab(~,~,Analysis_Type,lab_name)
datapath = 'C:\KnobAnalysis\Lab_Specific_Config_Files\';                                         %Set the primary local data path for saving data files.
if ~exist(datapath,'dir')                                           %If the primary local data path doesn't already exist...
    mkdir(datapath);                                                %Make the primary local data path.
end
Lab_Name = inputdlg('What is the name of the lab?', 'Lab Name', [1 50]);
functionspath = uigetdir('C:\', 'Where are your lab''s functions located?');
temp_directory = [char(datapath) char(Lab_Name) '\']; mkdir(temp_directory);
functionspath = [functionspath '\'];
[Success,Message,MessageID] = copyfile(functionspath,temp_directory);
Info = dir(datapath); LabNames = {Info.name}; LabNames = LabNames(3:end);
for i = 1:length(LabNames);
    temp_lab_directory = [datapath char(LabNames(i))];
    temp_filenames = dir(temp_lab_directory); temp_filenames = {temp_filenames.name};
    temp_filenames = temp_filenames(3:end);
    FileInfo(i).functions = temp_filenames;
    FileInfo(i).lab_directory = {temp_lab_directory};
end
set(Analysis_Type,'userdata',FileInfo);
set(lab_name,'string',LabNames);
Lab_Analyses_Repository = [getenv('homedrive') getenv('homepath') filesep 'Desktop' filesep 'Knob_Analysis_Software' filesep 'LabSpecificAnalyses' filesep];
Info = dir(Lab_Analyses_Repository); Repo_Labs = {Info.name}; 
if length(Repo_Labs)<3
    source = ['C:\KnobAnalysis\Lab_Specific_Config_Files\' char(Lab_Name)];
    Lab_Analyses_Repository = [Lab_Analyses_Repository char(Lab_Name)];
    mkdir(Lab_Analyses_Repository); %cd(Lab_Analyses_Repository);
    [Success,Message,MessageID] = copyfile(source,Lab_Analyses_Repository);
else
    BoolCompare = strcmpi(Lab_Name,Repo_Labs);
    if any(BoolCompare) == 0;
        source = ['C:\KnobAnalysis\Lab_Specific_Config_Files\' char(Lab_Name)];
        Lab_Analyses_Repository = [Lab_Analyses_Repository char(Lab_Name)];
        mkdir(Lab_Analyses_Repository); %cd(Lab_Analyses_Repository);
        [Success,Message,MessageID] = copyfile(source,Lab_Analyses_Repository);
    end
end
end

function LabName(hObject,~,Analysis_Type)
index_selected = get(hObject,'value'); FileInfo = get(Analysis_Type,'userdata');
set(Analysis_Type,'value',1);
Functions = FileInfo(index_selected).functions;
set(Analysis_Type,'string',Functions);
end

function AnalysisType(hObject,~,LabName)
index_selected = get(hObject,'value'); 
Lab_Selected = get(LabName,'value');
FileNames = get(hObject,'string');
FileInfo = get(hObject,'userdata');
Current_Selection = FileNames{index_selected};
Active_Function = [char(FileInfo(Lab_Selected).lab_directory) '\' Current_Selection];
try
    run(Active_Function)
catch ME
    return    
end
end