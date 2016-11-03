function [files, varargout] = file_miner(folders,str)

if nargin == 1                                                              %If the user didn't specify a search directory.
    str = folders;                                                          %Set the string variable to what the user entered for the folder.
    folders = uigetdir(cd,['Select macro directory to search for "'...
        str '"']);                                                          %Have the user choose a starting directory.
    if folders(1) == 0                                                      %If the user clicked "cancel"...
        return                                                              %Skip execution of the rest of the function.
    end
end
if ~iscell(folders)                                                         %If the directories input is not yet a cell array...
    folders = {folders};                                                    %Convert the directories input to a cell array.
end
if ~iscell(str)                                                             %If the search string isn't a cell array...
    str = {str};                                                            %Convert the search string to a cell array.
end
str = str(:);                                                               %Make sure the search string cell array has a singleton dimension.
for f = 1:length(folders)                                                   %Step through each specified directory...
    if folders{f}(end)  ~= '\'                                              %If a directory doesn't end in a forward slash...
        folders{f}(end+1) = '\';                                            %Add a forward slash to the end of the main path.
    end
end
wb = waitbar(0,'Finding all subfolders...');                                %Open a wait bar dialog box.
set(wb,'Name','Finding files...','CloseRequestFcn',[]);                     %Prevent the waitbar from being closed...
checker = zeros(1,length(folders));                                         %Create a checking matrix to see if we've looked in all the subfolders.
while any(checker == 0)                                                     %Keep looking until all subfolders have been checked for *.xls files.
    a = find(checker == 0,1,'first');                                       %Find the next folder that hasn't been checked for subfolders.
    temp = dir(folders{a});                                                 %Grab all the files and folders in the current folder.
    for f = 1:length(temp)                                                  %Step through all of the returned contents.
        if ~any(temp(f).name == '.') && temp(f).isdir == 1                  %If an item is a folder, but not a system folder...
            subfolder = [folders{a} temp(f).name '\'];                      %Concatenate the full subfolder name...
            if ~any(strcmpi(subfolder,folders))                             %If the subfolder is not yet in the list of subfolders...                
                folders{end+1} = [folders{a} temp(f).name '\'];             %Add the subfolder to the list of subfolders.
                checker(end+1) = 0;                                         %Add an entry to the checker matrix to check this subfolder for more subfolders.
            end
        end
    end
    checker(a) = 1;                                                         %Mark the last folder as having been checked.
    waitbar(sum(checker)/length(checker),wb);                               %Update the waitbar.
end
N = 0;                                                                      %Create a file counter.
for i = 1:length(str)                                                       %Step through each search string.
    for f = 1:length(folders)                                               %Step through every subfolder.
        temp = dir([folders{f} str{i}]);                                    %Grab all the matching filenames in the subfolder.
        N = N + length(temp);                                               %Add the number of files to the file counter.
        waitbar(f/length(folders),wb,['Counting ' str{i} ' files...']);     %Update the waitbar.
    end
end
N = 0;                                                                      %Reset the file counter.
files = cell(N,1);                                                          %Create an empty cell array to hold filenames.
file_times = zeros(N,1);                                                    %Create a matrix to hold file modification dates.
for i = 1:length(str)                                                       %Step through each search string.
    for f = 1:length(folders)                                               %Step through every subfolder.
        temp = dir([folders{f} str{i}]);                                    %Grab all the matching filenames in the subfolder.
        for j = 1:length(temp)                                              %Step through every matching file.
            N = N + 1;                                                      %Increment the file counter.
            files{N} = [folders{f} temp(j).name];                           %Save the filename with it's full path.
            file_times(N) = temp(j).datenum;                                %Save the last file modification date.
        end
        waitbar(f/length(folders),wb,['Saving ' str{i} ' filenames...']);   %Update the waitbar.
    end
end
set(wb,'CloseRequestFcn','closereq');                                       %Re-enable closing of the waitbar.
close(wb);                                                                  %Close the wait bar dialog box.
varargout{1} = file_times;                                                  %Return the file modification times as an optional output argument.
varargout{2} = folders;                                                     %Return the folders cell array as an optional output argument.
drawnow;                                                                    %Update all figures to close the waitbar.