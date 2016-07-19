function AnalyzeGroup(varargin)
pos = get(0,'Screensize');                                              %Grab the screensize.
h = 10;                                                                 %Set the height of the figure, in centimeters.
w = 20;                                                                 %Set the width of the figure, in centimeters.
fig = figure('numbertitle','off','units','centimeters',...
    'name',['MotoTrak Analysis: Analyze Group'],'menubar','none',...
    'position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
Table = readtable('TestFile.txt');
ExperimentNames = Table{:,1};
SubjectNames = Table{:,2};


Subjects = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left','min', 0,'max',25,...
    'string','Subjects', 'units', 'normalized', 'Position', [.0475 .05 .27 .7], 'Fontsize', 11);
Subjects_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Subjects:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.0475 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Groups = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Groups', 'units', 'normalized', 'Position', [.365 .05 .27 .7], 'Fontsize', 11);
Groups_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Groups:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.365 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Experiment = uicontrol(fig,'style','popup','string',ExperimentNames,...
        'units','normalized','position',[.15 .91 .25 .05],'fontsize',12,...
        'callback',{@ExperimentCallback,SubjectNames,Subjects,Groups});
Experiment_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Experiment:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.01 .9 .13 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Events = uicontrol('Parent', fig, 'Style', 'listbox', 'HorizontalAlignment', 'left',...
    'string','Events', 'units', 'normalized', 'Position', [.6825 .05 .27 .7], 'Fontsize', 11);
Events_Text = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Events:', ...
    'HorizontalAlignment', 'left', 'units', 'normalized', 'Position', [.6825 .77 .3 .05],...
    'Fontsize', 12, 'Fontweight', 'bold') ;
Make_Plot = uicontrol('Parent', fig, 'Style', 'pushbutton', 'HorizontalAlignment', 'left',...
    'string','Plot', 'units', 'normalized', 'Position', [.82 .86 .15 .1], 'Fontsize', 12);

function ExperimentCallback(hObject,~,SubjectNames,Subjects,Groups)
Table = readtable('TestFile.txt');
index_selected = get(hObject,'value');
if index_selected == length(hObject.String);
%     uiwait(msgbox('Hello'));
    prompt = {'Experiment Name', 'Subject Names', 'Groups'};
    dlg_title = 'Create New Experiment';
    answer = inputdlg(prompt,dlg_title,[1 50; 1 50; 1 50]);
    hObject.String(length(hObject.String)) = answer(1,:);
    hObject.String(length(hObject.String)+1) = {'Create New Experiment'};    
    SubjectNames = strsplit(answer{2,:});
    GroupNames = strsplit(answer{3,:});
    set(Subjects,'string',SubjectNames);
    set(Groups,'string',GroupNames);
    Table{end,1} = answer(1,:); Table{end,2} = answer(2,:);
    Table{size(Table,1)+1,1} = {'Create New Experiment'};
    save('TestFile.txt', Table)
else
    SubjectNames = SubjectNames{index_selected,:};
    SubjectNames = strsplit(SubjectNames);
    set(Subjects,'string',SubjectNames);
end
