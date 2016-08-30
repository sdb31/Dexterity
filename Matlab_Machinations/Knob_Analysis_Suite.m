function Knob_Analysis_Suite(varargin)
set(0,'units','centimeters');
pos = get(0,'screensize');
h = 0.3*pos(4);
w = 4*h/3;

handles.fig = figure('numbertitle','off',...
    'name','Knob Task Analysis Suite',...
    'units','centimeters', 'Toolbar', 'none',...
    'menubar', 'none',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
handles.Subject_Timeline = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.7,.6,.2],...
    'string','View Subject Timeline',...
    'fontsize',12);
handles.Analyze_Group_Data = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.4,.6,.2],...
    'string','Analyze Group Data',...
    'fontsize',12);
handles.Lab_Specific_Analysis = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.1,.6,.2],...
    'string','Lab Specific Analysis',...
    'fontsize',12);
set(handles.Subject_Timeline, 'callback', @SubjectTimeline);
set(handles.Analyze_Group_Data, 'callback', @AnalyzeGroupData);
set(handles.Lab_Specific_Analysis, 'callback', @LabAnalysis);
guidata(handles.fig, handles);

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

function LabAnalysis(hObject,~)
Table = readtable('LabSpecificAnalysisConfig.txt');
Path = Table{:,2};
pos = get(0,'Screensize');                                              %Grab the screensize.
h = 8;                                                                 %Set the height of the figure, in centimeters.
w = 15;                                                                 %Set the width of the figure, in centimeters.
FileNames = {};
fig = figure('numbertitle','off','units','centimeters',...
    'name',['Lab Specific Analysis: Knob'],'menubar','none',...
    'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
Choose_Lab = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Please choose a lab:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.1 .85 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Analysis_Type = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'callback', {@AnalysisType},'string',FileNames,...
    'units', 'normalized', 'Position', [.525 .1 .45 .7]);
Lab_Name = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','string', Table{:,1},...
    'units', 'normalized', 'Position', [.025 .1 .45 .7],'callback',{@LabName,Path,Analysis_Type},...
    'Fontsize', 12);
Lab_Functions = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Lab Functions', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.65 .85 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;

end

function LabName(hObject,~,Path,Analysis_Type)
index_selected = get(hObject,'value');
Path = Path{index_selected};
cd(Path);
Path = char(Path);
list = dir(Path);
FileNames = {list.name};
FileNames = FileNames(3:end);
set(Analysis_Type,'string',FileNames);
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