function MotoTrak_File_Editor

handles = Make_GUI;                                                         %Create the main GUI.

set(handles.loadbutton,'callback',@LoadFile);                               %Set the callback for the file load button.
set(handles.savebutton,'callback',@SaveEdits);                              %Set the callback for the edit-save button and disable it.
set(handles.editrat(2),'callback',@EditRat);                                %Set the callback for the rat name editbox.
set(handles.editbooth(2),'callback',@EditBooth);                            %Set the callback for the booth number editbox.
set(handles.editstage(2),'callback',@EditStage);                            %Set the callback for the stage name editbox.

guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function has the user select a file to edit and then loads the header from the file.
function LoadFile(hObject,~)
[file, path] = uigetfile('*.ArdyMotor');                                    %Have the user select an *.ArdyMotor file.
if file(1) == 0                                                             %If the user clicked "cancel"...
    return                                                                  %Skip execution of the rest of the function.
end
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
handles.file = file;                                                        %Save the original file name.
handles.path = path;                                                        %Save the original file's path.
handles.oldfile = file;                                                     %Keep track of the previous file name.
handles.oldpath = path;                                                     %Keep track of the previous path name.
fid = fopen([path file],'r');                                               %Open the *.ArdyMotor file for read access.
handles.version = fread(fid,1,'int8');                                      %Read the file format version from the first byte as a signed integer.
if handles.version ~= -3                                                    %If the file format is an older version...
    fclose(fid);                                                            %Close the file.
    errordlg('Sorry, this program cannot edit Version 1.0 files.',...
        'Old File Format');                                                 %Show an error dialog box.
end
handles.daycode = fread(fid,1,'uint16');                                    %Read in the daycode.
handles.booth = fread(fid,1,'uint8');                                       %Read in the booth number.
N = fread(fid,1,'uint8');                                                   %Read in the number of characters in the rat's name.
handles.rat = fread(fid,N,'*char')';                                        %Read in the characters of the rat's name.
handles.oldrat = handles.rat;                                               %Save the previous rat name.
handles.position = fread(fid,1,'float32');                                  %Read in the device position, in centimeters.
N = fread(fid,1,'uint8');                                                   %Read in the number of characters in the stage description.
handles.stage = fread(fid,N,'*char')';                                      %Read in the characters of the stage description.
i = find(handles.stage == ':',1,'first');                                   %Look for a colon in the stage name.
if isempty(i)                                                               %If no colon was found in the stage name...
    handles.stage_number = [];                                              %Set the stage number to empty brackets by default.
    i = strfind(handles.file,'Stage');                                      %Find the word stage in the filename.
    if ~isempty(i)                                                          %If the word stage was found...
        j = (handles.file == '_' & 1:length(handles.file) > i);             %Find all underscores after the stage number.
        if any(j)                                                           %If any underscores were found.
            j = find(j,1,'first');                                          %Find the first underscore after the stage number.
            handles.stage_number = handles.file(i+5:j-1);                   %Grab the stage number from the filename.
        end
    end
else                                                                        %Otherwise...
    handles.stage_number = handles.stage(1:i-1);                            %Grab the stage number from the stage name.
    handles.stage(1:i) = [];                                                %Kick the stage number out of the stage name.
    handles.stage(1:find(handles.stage ~= ' ',1,'first')-1) = [];           %Kick out any leading spaces from the stage name.
end
N = fread(fid,1,'uint8');                                                   %Read in the number of characters in the device name.
handles.device = fread(fid,N,'*char')';                                     %Read in the characters of the device name.
checker = zeros(1,length(handles.file));                                    %Create a matrix to find the timestamp in the original filename.
for i = 1:length(handles.file) - 14                                         %Step through the characters of the original filename.
    if all(handles.file([i:i+7,i+9:i+14]) >= 48) && ...
            all(handles.file([i:i+7,i+9:i+14]) <= 57) && ...
            handles.file(i+8) == 'T'                                        %If a valid timestamp is found in the filename...
        checker(i) = 1;                                                     %Set the checker for that character to 1.
    end
end
if any(checker)                                                             %If any valid timestamp was found in the filename...
    i = find(checker == 1,1,'first');                                       %Grab the start index for the ifrst timestamp found in the filename.
    handles.daycode = datenum(handles.file(i:i+14),'yyyymmddTHHMMSS');      %Grab the session time from the filename.
else                                                                        %Otherwise, if no valid timestamp was found...
    if any(strcmpi({'pull', 'knob', 'lever'},handles.device))               %If the device was the pull, knob, or lever.
        fseek(fid,8,'cof');                                                 %Skip over two float32 values.
    elseif any(strcmpi(handles.device,{'wheel'}))                           %Otherwise, if the device was the wheel...
        fseek(fid,4,'cof');                                                 %Skip over one float32 value.
    end
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the constraint description.
    fseek(fid,N,'cof');                                                     %Skip over the characters of the constraint description.
    N = fread(fid,1,'uint8');                                               %Read in the number of characters in the threshold type description.
    fseek(fid,N,'cof');                                                     %Skip over the characters of the threshold type description.
    temp = fread(fid,1,'uint32');                                           %Read in the trial number.
    if ~isempty(temp)                                                       %If a trial number was read...
        handles.daycode = fread(fid,1,'float64');                           %Grab the first trial start time as the session start time.
    else                                                                    %If there was no trial number to read...
        temp = dir([handles.path, handles.file]);                           %Grab the file info for the data file.
        handles.daycode = temp.datenum;                                     %Use the last date modified as the session start time for this file.
    end
end
fclose(fid);                                                                %Close the data file.
set(handles.editrat,'string',handles.rat);                                  %Set the string for both subject editboxes.
set(handles.editbooth,'string',num2str(handles.booth,'%1.0f'));             %Set the string for both booth number editboxes.
if ~isempty(handles.stage_number)                                           %If a stage number was found...
    set(handles.editstage,...
        'string',[handles.stage_number ': ' handles.stage]);                %Set the string for both subject editboxes.
else                                                                        %Otherwise...
    set(handles.editstage,'string',handles.stage);                          %Set the string for both subject editboxes.
end
set(handles.editfile,'string',handles.file,'horizontalalignment','left');   %Set the string for both file editboxes.
set(handles.editpath,'string',handles.path,'horizontalalignment','left');   %Set the string for both path editboxes.
set([handles.editrat(2), handles.editbooth(2), handles.editstage(2)],...
    'enable','on');                                                         %Enable the various editboxes.
set(handles.editfile(2),'ButtonDownFcn',@EditFile);                         %Set the buttondown function for the filename editbox.
set(handles.editpath(2),'ButtonDownFcn',@EditPath);                         %Set the buttondown function for the path editbox.
set(handles.savebutton,'enable','on');                                      %Enable the edit-saving pushbutton.
handles.autoset_file = 1;                                                   %Create a field to control auto-setting of the path name.
handles.autoset_path = 1;                                                   %Create a field to control auto-setting of the path name.
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function saves the file edits, replacing the old file or creating a new one.
function SaveEdits(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
set([handles.editrat(2), handles.editbooth(2), handles.editstage(2),...
    handles.loadbutton, handles.savebutton],'enable','off');                %Disable the various editboxes and pushbuttons.
set(handles.editfile(2),'ButtonDownFcn',[]);                                %Remove the buttondown function for the filename editbox.
set(handles.editpath(2),'ButtonDownFcn',[]);                                %Remove the buttondown function for the path editbox.
if exist([handles.path, handles.file],'file')                               %If a file already exists with the specified filename...
    if strcmpi([handles.path, handles.file],...
            [handles.oldpath handles.oldfile])                              %If the filename hasn't changed...
        temp = questdlg(['The filename hasn''t changed. Do you want to '...
            'replace the original file?'],'Replace Original?','Yes',...
            'No','Yes');                                                    %Ask the user if they want to replace the original file.
        if ~strcmpi(temp,'Yes')                                             %If the user didn't select "Yes"...
            set([handles.editrat(2), handles.editbooth(2),...
                handles.editstage(2),handles.savebutton,...
                handles.loadbutton],'enable','on');                         %Re-enable the various editboxes and pushbuttons.
            set(handles.editfile(2),'ButtonDownFcn',@EditFile);             %Reset the buttondown function for the filename editbox.
            set(handles.editpath(2),'ButtonDownFcn',@EditPath);             %Reset the buttondown function for the path editbox.
            return                                                          %Skip execution of the rest of the function.
        end
    else                                                                    %Otherwise...
        temp = questdlg(['Another file already exists with this '...
            'filename. Do you want to replace it?'],...
            'Replace Other File?','Yes','No','Yes');                        %Ask the user if they want to replace the other file.
        if ~strcmpi(temp,'Yes')                                             %If the user didn't select "Yes"...
            set([handles.editrat(2), handles.editbooth(2),...
                handles.editstage(2),handles.savebutton,...
                handles.loadbutton],'enable','on');                         %Re-enable the various editboxes and pushbuttons.
            set(handles.editfile(2),'ButtonDownFcn',@EditFile);             %Reset the buttondown function for the filename editbox.
            set(handles.editpath(2),'ButtonDownFcn',@EditPath);             %Reset the buttondown function for the path editbox.
            return                                                          %Skip execution of the rest of the function.
        end
    end
end
delete_original = 0;                                                        %Set the program to not delete the original file by default.
if ~strcmpi([handles.path, handles.file],[handles.oldpath handles.oldfile]) %If the filename changed from the original...
    temp = questdlg('Do you want to delete the original file?',...
            'Delete Original?','Yes','No','No');                            %Ask the user if they want to replace the other file.
    if strcmpi(temp,'Yes')                                                  %If the user selected "Yes"...
        delete_original = 1;                                                %Set the program to delete the original file after copying.
    elseif isempty(temp)                                                    %If the user closed the dialog box without clicking a button...
        set([handles.editrat(2), handles.editbooth(2),...
            handles.editstage(2),handles.savebutton,handles.loadbutton],...
            'enable','on');                                                 %Re-enable the various editboxes and pushbuttons.
        set(handles.editfile(2),'ButtonDownFcn',@EditFile);                 %Reset the buttondown function for the filename editbox.
        set(handles.editpath(2),'ButtonDownFcn',@EditPath);                 %Reset the buttondown function for the path editbox.
        return                                                              %Skip execution of the rest of the function.
    end
else                                                                        %Otherwise, if the filename hasn't changed...
    copyfile([handles.oldpath, handles.oldfile],...
        [handles.oldpath, 'temp.ArdyMotor'],'f');                           %Copy the original file to a temporary filename.   
    handles.oldfile = 'temp.ArdyMotor';                                     %Use the new temporary file as the old filename.
end

waitbar = big_waitbar('title','Saving File Edits...',...
    'string',['Saving to: ' handles.file],'color','m');                     %Create a waitbar figure.
waitbar.value(0);                                                           %Set the waitbar value to zero.

a = find(handles.path == '\');                                              %Find all forward slashes in the new path.
for i = a                                                                   %Step through all forward slashes.
    if ~exist(handles.path(1:i),'dir')                                      %If the directory doesn't already exist...
        mkdir(handles.path(1:i));                                           %Create the directory.
    end
end
oldfid = fopen([handles.oldpath, handles.oldfile],'r');                     %Open the original *.ArdyMotor file for read access.
newfid = fopen([handles.path, handles.file],'w');                           %Open a new *.ArdyMotor file for overwrite access.

fwrite(newfid,fread(oldfid,1,'int8'),'int8');                               %Write the data file version number.

fseek(oldfid,3,'cof');                                                      %Skip over the daycode and booth number in the original file.
fwrite(newfid,fix(handles.daycode),'uint16');                               %Write the DayCode.
fwrite(newfid,handles.booth,'uint8');                                       %Write the booth number.

N = fread(oldfid,1,'uint8');                                                %Read in the number of characters in the original rat name.
fseek(oldfid,N,'cof');                                                      %Skip the characters of the original rat name.
fwrite(newfid,length(handles.rat),'uint8');                                 %Write the number of characters in the new rat name.
fwrite(newfid,handles.rat,'uchar');                                         %Write the characters of the new rat name.

fwrite(newfid,fread(oldfid,1,'float32'),'float32');                         %Write the position of the input device (in centimeters).

if ~isempty(handles.stage_number)                                           %If a stage number was set...
    temp = [handles.stage_number ': ' handles.stage];                       %Set the string for the stage description to include the stage number.
else                                                                        %Otherwise...
    temp = handles.stage;                                                   %Set the string to just the stage description.
end

N = fread(oldfid,1,'uint8');                                                %Read in the number of characters in the original stage description.
fseek(oldfid,N,'cof');                                                      %Skip the characters of the original stage description.
fwrite(newfid,length(temp),'uint8');                                        %Write the number of characters in the stage description.
fwrite(newfid,temp,'uchar');                                                %Write the characters of the stage description.
counter = 0;                                                                %Create a counter variable.
temp = fread(oldfid,1,'int8');                                              %Grab one byte from the original file.
while ~isempty(temp)                                                        %Loop until there's no more bytes in the original file.
    counter = counter + 0.0001;                                             %Add 0.0001 to the counter.
    if rem(counter,0.01) == 0                                               %If the counter is at an even hundredth...
        waitbar.value(counter);                                             %Update the waitbar value.
    end
    if counter >= 1                                                         %If the counter value is greater than or equal to 1...
        counter = 0;                                                        %Reset the counter to zero.
    end
    fwrite(newfid,temp,'int8');                                             %Write the byte to the new file.
    temp = fread(oldfid,1,'int8');                                          %Grab another byte from the original file.
end
while counter < 1;                                                          %Loop until the counter is greater than 1...
    counter = counter + 0.01;                                               %Add 0.01 to the counter.
    waitbar.value(counter);                                                 %Update the waitbar value.
end
waitbar.close();                                                            %Close the waitbar.
fclose(oldfid);                                                             %Close the original file.
fclose(newfid);                                                             %Close the new file.
if delete_original == 1                                                     %If the user selected to delete the original file...
    delete([handles.oldpath, handles.oldfile]);                             %Delete the original file.
end
if exist([handles.oldpath,'temp.ArdyMotor'],'file')                         %If a temporary file was created...
    delete([handles.oldpath,'temp.ArdyMotor']);                             %Delete the temporary file.
end
set(handles.editrat,'string',handles.rat);                                  %Set the string for both subject editboxes.
set(handles.editbooth,'string',num2str(handles.booth,'%1.0f'));             %Set the string for both booth number editboxes.
if ~isempty(handles.stage_number)                                           %If a stage number was found...
    set(handles.editstage,...
        'string',[handles.stage_number ': ' handles.stage]);                %Set the string for both subject editboxes.
else                                                                        %Otherwise...
    set(handles.editstage,'string',handles.stage);                          %Set the string for both subject editboxes.
end
set(handles.editfile,'string',handles.file,'horizontalalignment','left');   %Set the string for both file editboxes.
set(handles.editpath,'string',handles.path,'horizontalalignment','left');   %Set the string for both path editboxes.
handles.oldfile = handles.file;                                             %Set the current file name to be the new original file.
handles.oldpath = handles.path;                                             %Set the current path to be the new original path.
set([handles.editrat(2), handles.editbooth(2), handles.editstage(2),...
    handles.savebutton,handles.loadbutton],'enable','on');                  %Re-enable the various editboxes and pushbuttons
set(handles.editfile(2),'ButtonDownFcn',@EditFile);                         %Reset the buttondown function for the filename editbox.
set(handles.editpath(2),'ButtonDownFcn',@EditPath);                         %Reset the buttondown function for the path editbox.
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.



%% This function executes when the user enters a rat's name in the editbox
function EditRat(hObject,~)           
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
temp = get(hObject,'string');                                               %Grab the string from the rat name editbox.
for c = '/\?%*:|"<>. '                                                      %Step through all reserved characters.
    temp(temp == c) = [];                                                   %Kick out any reserved characters from the rat name.
end
if ~strcmpi(temp,handles.rat)                                               %If the rat's name was changed.
    handles.rat = upper(temp);                                              %Save the new rat name in the handles structure.
end
set(handles.editrat(2),'string',handles.rat);                               %Reset the rat name in the rat name editbox.
if handles.autoset_file == 1                                                %If the user hasn't yet overridden the auto-set filename...
    handles.file = UpdateFilename(handles);                                 %Call the function to update the filename.
end
if handles.autoset_path == 1                                                %If the user hasn't yet overridden the auto-set path name...
    handles.path = UpdatePath(handles);                                     %Call the function to update the path.
end
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function executes when the user changes the booth number in the editbox.
function EditBooth(hObject,~)           
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
temp = get(hObject,'string');                                               %Grab the string from the booth number editbox.
temp = str2double(temp);                                                    %Convert the string to a number.
if temp > 0 && mod(temp,1) == 0 && temp < 65535                             %If the entered booth number is positive and a whole number...
    handles.booth = temp;                                                   %Save the booth number in the handles structure.
end
set(handles.editbooth(2),'string',num2str(handles.booth,'%1.0f'));          %Reset the string in the booth number editbox to the current booth number.
if handles.autoset_file == 1                                                %If the user hasn't yet overridden the auto-set filename...
    handles.file = UpdateFilename(handles);                                 %Call the function to update the filename.
end
if handles.autoset_path == 1                                                %If the user hasn't yet overridden the auto-set path name...
    handles.path = UpdatePath(handles);                                     %Call the function to update the path.
end
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function executes when the user enters a rat's name in the editbox
function EditStage(hObject,~)           
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
temp = get(hObject,'string');                                               %Grab the string from the rat name editbox.
temp(temp < 32) = [];                                                       %Kick out any special characters.
i = find(temp == ':',1,'first');                                            %Look for a colon in the entered stage name.
if isempty(i)                                                               %If no colon was found in the stage name...
    handles.stage_number = [];                                              %Set the stage number to empty brackets.
    handles.stage = temp;                                                   %Set the stage name to the entered text.
else                                                                        %Otherwise...
    handles.stage_number = temp(1:i-1);                                     %Grab the stage number from the stage name.
    for c = '/\?%*:|"<>. '                                                  %Step through all reserved characters.
        handles.stage_number(handles.stage_number == c) = [];               %Kick out any reserved characters from the stage number.
    end
    temp(1:i) = [];                                                         %Kick the stage number out of the stage name.
    temp(1:find(temp ~= ' ',1,'first')-1) = [];                             %Kick out any leading spaces from the stage name.
    handles.stage = temp;                                                   %Save the stage name.
end
if ~isempty(handles.stage_number)                                           %If a stage number was found...
    set(handles.editstage(2),...
        'string',[handles.stage_number ': ' handles.stage]);                %Set the string for both subject editboxes.
else                                                                        %Otherwise...
    set(handles.editstage(2),'string',handles.stage);                       %Set the string for both subject editboxes.
end
if handles.autoset_file == 1                                                %If the user hasn't yet overridden the auto-set filename...
    handles.file = UpdateFilename(handles);                                 %Call the function to update the filename.
end
if handles.autoset_path == 1                                                %If the user hasn't yet overridden the auto-set path name...
    handles.path = UpdatePath(handles);                                     %Call the function to update the path.
end
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function auto-sets the filename and path for the editted data file.
function file = UpdateFilename(handles)
i = find(handles.oldfile == '_',1,'last');                                  %Find the last underscore in the filename.
if ~isempty(i)                                                              %If an underscore was found...
    suffix = handles.oldfile(i:end-10);                                     %Grab the existing suffix from the previous file.
else                                                                        %Otherwise...
    suffix = [];                                                            %Don't include a suffix in the expected filename.
end
temp = datestr(handles.daycode,30);                                         %Grab a timestamp accurate to the second.
if ~isempty(handles.stage_number)                                           %If there's a valid stage number...
    file = [handles.rat '_' temp '_Stage' handles.stage_number...          
        '_' handles.device suffix '.ArdyMotor' ];                           %Create the expected filename.
else                                                                        %Otherwise...
    file = [handles.rat '_' temp '_' handles.device suffix '.ArdyMotor' ];  %Create the expected filename, minus the stage number
end
set(handles.editfile(2),'string',file);                                     %Show the new filename in the editted filename editbox.


%% This function auto-sets the filename and path for the editted data file.
function path = UpdatePath(handles)
path = handles.oldpath;                                                     %Set the default path to the original path name.
i = strfind(handles.oldpath,handles.oldrat);                                %Find the original rat name in the search path.
if ~isempty(i)                                                              %If the original rat's name was found in the path...
    i = strfind(handles.oldpath,handles.rat);                               %Find the new rat name in the search path.
end
if ~isempty(i)                                                              %If a match was found to either the original or new rat name. 
    path = handles.oldpath(1:i(1)-1);                                       %Grab the path up to the rat name.
    i = find(path == '\');                                                  %Find the last forward slash in the path name.
    if ~isempty(i)                                                          %If a forward slash was found...
        path(i:end) = [];                                                   %Kick out everything from the forward slash and after.
    end
    path = [path '\' handles.rat '\'];                                      %Add the rat name to the expected path.
    if ~isempty(handles.stage_number)                                       %If there's a valid stage number...
        path = [path handles.rat '-Stage' handles.stage_number '\'];        %Make a subfolder name for the current stage in the rat's folder.
    end
end
set(handles.editpath(2),'string',path);                                     %Show the new path in the editted path editbox.


%% This function sets the filename when the user specifies a specific filename in the editbox.
function EditFile(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
if exist(handles.path,'dir')                                                %If the current new path exists...
    path = handles.path;                                                    %Set the default path to the specified path.
else                                                                        %Otherwise...
    path = handles.oldpath;                                                 %Set the default path to the original path.
end
[file, path] = uiputfile([path, handles.file],...
    'Specific a New Filename');                                             %Have the user explicitly specified a filename.
if file(1) == 0                                                             %If the user clicked cancel...
    return                                                                  %Skip execution of the rest of the function.
end
if ~strcmpi(file,handles.file)                                              %If the filename was changed...
    handles.file = file;                                                    %Set the new filename to that specified.
    handles.autoset_file = 0;                                               %Turn off auto-setting of the filename from here on.
    set(handles.editfile,'string',handles.file);                            %Show the new filename in the editbox.
end
if ~strcmpi(path,handles.path)                                              %If the path was changed...
    handles.path = path;                                                    %Set the new path to that specified.
    handles.autoset_path = 0;                                               %Turn off auto-setting of the path from here on.
    set(handles.editpath,'string',handles.path);                         %Show the new path in the editbox.
end
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function sets the path when the user specifies a specific path in the editbox.
function EditPath(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
if exist(handles.path,'dir')                                                %If the current new path exists...
    path = handles.path;                                                    %Set the default path to the specified path.
else                                                                        %Otherwise...
    path = handles.oldpath;                                                 %Set the default path to the original path.
end
path = uigetdir(path,'Select a Destination Directory');                     %Have the user select a path with a dialog box.
if path(1) == 0                                                             %If the user clicked "cancel"...
    return                                                                  %Skip execution of the rest of the function.
end
if ~strcmpi(path,handles.path)                                              %If the path was changed...
    handles.path = path;                                                    %Set the new path to that specified.
    handles.autoset_path = 0;                                               %Turn off auto-setting of the path from here on.
    set(handles.editpath,'string',handles.path);                            %Show the new path in the editbox.
end
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function creates the main figure and populates it with the required uicontrols.
function handles = Make_GUI
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'ScreenSize');                                                  %Grab the system screen size.
w = 0.9*pos(3);                                                             %Set the figure width relative to the screensize.
h = 0.3*w;                                                                  %Set the height relative to the width.
sp = 0.01*h;                                                                %Set the spacing for all uicontrols.
fontsize = 1.2*h;                                                           %Set the fontsize relative to the figure height.
ui_h = 0.069*fontsize;                                                      %Set the height of all uicontrols relative to the fontsize.
lbl_w = 0.2*fontsize;                                                       %Set the width for editbox labels relative to the fontsize.

%Create the main figure.
pos = [pos(3)/2-w/2, pos(4)/2-h/2, w, h];                                   %Set the figure position.
handles.mainfig = figure('units','centimeters',...
    'Position',pos,...
    'MenuBar','none',...
    'numbertitle','off',...
    'resize','off',...
    'name','MotoTrak File Editor',...
    'color',[0.8 0.8 0.8]);                                                 %Create the main figure.

%Create a panel showing the header info from the original file.
p_h = 3.5*ui_h + (3+1)*sp;                                                  %Set the height of the figure.
pos = [sp, h-p_h-2*sp, w/2-2*sp, p_h];                                      %Set the position of the upper-left panel.
for j = 1:2                                                                 %Step through two panels.
    if j == 2                                                               %If this is the second panel.
        pos(1) = w/2 + 0.1;                                                 %Set the position of the upper-right panel.
    end
    p = uipanel(handles.mainfig,'units','centimeters',...
        'position',pos,...
        'title','Original File',...
        'fontweight','bold',...
        'fontsize',fontsize,...
        'backgroundcolor',[0.7 0.7 0.8]);                                   %Create the panel to hold the session information uicontrols.
    h = fliplr({'editrat','editbooth','editstage'});                        %Create the uicontrol handle names for editabble header parameter.
    l = fliplr({'Subject:','Booth:','Stage:'});                             %Create the labels for the uicontrols' string property.
    for i = 1:length(h)                                                     %Step through the uicontrols.
        handles.label(i+3*(j-1)) = uicontrol(p,'style','edit',...
            'enable','inactive',...
            'string',l{i},...
            'units','centimeters',...
            'position',[sp/2, sp*i/2+ui_h*(i-1), lbl_w, ui_h],...
            'fontweight','bold',...
            'fontsize',fontsize,...
            'horizontalalignment','right',...
            'backgroundcolor',get(p,'backgroundcolor'));                    %Make a static text label for each uicontrol.
        temp = uicontrol(p,'style','edit',...
            'enable','inactive',...
            'units','centimeters',...
            'string','-',...
            'position',[lbl_w+sp/2, sp*i/2+ui_h*(i-1), pos(3)-lbl_w-3*sp/2, ui_h],...
            'fontweight','bold',...
            'fontsize',fontsize,...
            'horizontalalignment','center',...
            'backgroundcolor','w');                                         %Create an editbox for entering in each parameter.
        handles.(h{i})(j) = temp;                                           %Save the uicontrol handle to the specified field in the handles structure.
    end
end
set(p,'title','Editted File','backgroundcolor',[0.7 0.8 0.7]);              %Change the second panel title and backgroundcolor.
set(handles.label(4:6),'backgroundcolor',[0.7 0.8 0.7]);                    %Change the background color of the text labels in the right-hand panel.
set([handles.editrat(2), handles.editbooth(2), handles.editstage(2)],...
    'enable','off');                                                        %Create an editbox for entering in each parameter.

%Create a panel showing the original file name and path.
p_h = 2.5*ui_h + (2+1)*sp;                                                  %Set the height of the figure.
pos = [sp, pos(2)-p_h-3*sp, w - 2*sp, p_h];                                 %Set the position of the middle panel.
for j = 1:2                                                                 %Step through two panels.
    if j == 2                                                               %If this is the second panel.
        pos(2) = pos(2) - p_h - 0.3;                                        %Set the position of the bottom panel.
    end
    p = uipanel(handles.mainfig,'units','centimeters',...
        'position',pos,...
        'title','Original File ',...
        'fontweight','bold',...
        'fontsize',fontsize,...
        'backgroundcolor',[0.7 0.7 0.8]);                                   %Create the panel to hold the session information uicontrols.
    h = fliplr({'editfile','editpath'});                                    %Create the uicontrol handle names for editabble header parameter.
    l = fliplr({'File:','Path:'});                                          %Create the labels for the uicontrols' string property.
    for i = 1:length(h)                                                     %Step through the uicontrols.
        handles.label(6+i+2*(j-1)) = uicontrol(p,'style','edit',...
            'enable','inactive',...
            'string',l{i},...
            'units','centimeters',...
            'position',[sp/2, sp*i/2+ui_h*(i-1), lbl_w, ui_h],...
            'fontweight','bold',...
            'fontsize',fontsize,...
            'horizontalalignment','right',...
            'backgroundcolor',[0.7 0.7 0.8]);                               %Make a static text label for each uicontrol.
        temp = uicontrol(p,'style','edit',...
            'enable','inactive',...
            'units','centimeters',...
            'string','-',...
            'position',[lbl_w+sp/2, sp*i/2+ui_h*(i-1), pos(3)-lbl_w-3*sp/2, ui_h],...
            'fontweight','bold',...
            'fontsize',fontsize,...
            'horizontalalignment','center',...
            'backgroundcolor','w');                                         %Create an editbox for entering in each parameter.
        handles.(h{i})(j) = temp;                                           %Save the uicontrol handle to the specified field in the handles structure.
    end
end
set(p,'title','Editted File','backgroundcolor',[0.7 0.8 0.7]);              %Change the second panel title and backgroundcolor.
set(handles.label(9:10),'backgroundcolor',[0.7 0.8 0.7]);                   %Change the background color of the text labels in the right-hand panel.

%Create buttons for loading data files and for saving the file edits.
pos = [sp, pos(2)-ui_h-2*sp, w/2 - 2*sp, ui_h];                             %Set the position of the middle panel.
handles.loadbutton = uicontrol(handles.mainfig,'style','pushbutton',...
    'string','Load File',...
    'units','centimeters',...
    'position',pos,...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'foregroundcolor','k',...
    'backgroundcolor',[0.8 0.8 0.8]);                                       %Make a file load pushbutton.
pos(1) = w/2 + sp;                                                          %Set the position of the upper-right panel.
handles.savebutton = uicontrol(handles.mainfig,'style','pushbutton',...
    'string','Save Edits',...
    'enable','off',...
    'units','centimeters',...
    'position',pos,...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'foregroundcolor','k',...
    'backgroundcolor',[0.8 0.8 0.8]);                                       %Make an edit-saving pushbutton.