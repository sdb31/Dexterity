




function handles = Welcome_GUI(handles)
set(0,'units','centimeters');
pos = get(0,'screensize');  
h = 0.3*pos(4);
w = 5*h/3;  

handles.fig = figure( 'numbertitle','off',...
    'name','Knob Analysis',...
    'units','centimeters', 'Toolbar', 'none',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);
handles.Subject_Timeline = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.55,.6,.3],...
    'string','View Subject Timeline',...
    'fontsize',12);      
handles.AnalyzeGroupData = uicontrol(handles.fig,'style','pushbutton',...
    'units','normalized',...
    'Position',[.2,.15,.6,.3],...
    'string','Analyze Group Data',...
    'fontsize',12); 
function handles = SubjectTimeline_GUI(handles)
if ishandle(fig)                                                            %If the user hasn't closed the waitbar figure...
    close(fig);                                                             %Close the waitbar figure.
    drawnow;                                                                %Immediately update the figure to allow it to close.
end