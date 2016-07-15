function Knob_Analysis_Suite(varargin)
set(0,'units','centimeters');
pos = get(0,'screensize');  
h = 0.3*pos(4);
w = 5*h/3;  

handles.fig = figure('numbertitle','off',...
    'name','Knob Analysis',...
    'units','centimeters', 'Toolbar', 'none',...
    'menubar', 'none',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
handles.Subject_Timeline = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.55,.6,.3],...
    'string','View Subject Timeline',...
    'fontsize',12);      
handles.Analyze_Group_Data = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.15,.6,.3],...
    'string','Analyze Group Data',...
    'fontsize',12);
set(handles.Subject_Timeline, 'callback', @SubjectTimeline);
set(handles.Analyze_Group_Data, 'callback', @AnalyzeGroupData);
guidata(handles.fig, handles);

end

function SubjectTimeline(hObject,~)
handles = guidata(hObject);
MotoTrak_Analysis2
guidata(handles.fig,handles);
end

function AnalyzeGroupData(hObject,~)
handles = guidata(hObject);
figure; plot(linspace(1,100),sin(linspace(1,100)));
guidata(handles.fig,handles);
end

function SetDatapath(hObject,~)
handles = guidata(hObject);
[files, path] = uigetfile('*.ArdyMotor','Select MotoTrak Files',...
    'multiselect','off');
end