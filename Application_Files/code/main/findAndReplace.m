oldString = '6.10-09';
newString = '6.10-09';
directory = dir('E:\Projects\Quick_Fatigue_Tool\git\quick-fatigue-tool\quick-fatigue-tool\Application_Files\code\main\*.m');
L = length(directory);
fileList = cell(1.0, L);
for i = 1:L
    fileList{i} = directory(i).name;
end

find_and_replace(fileList, oldString, newString)