function [ini]=loadXCAPini
%loadXCAPini, open XCAP ini files and get file information.



input_Ncam = inputdlg('Enter number of synced cameras:',...
    'Number of Cameras',[1 40],{'3'});
Ncam = str2double(input_Ncam{1});

%Read ini files and get file information
Sequence = 1;
iniT=[]; %Table with file information
Path=pwd;
while (isnan(Sequence)==false)
    for Camera=1:Ncam
        %User input for file location
        [File, Path] = uigetfile({'*.ini','XCAP ini-file'},...
            ['Open INI-file camera ',num2str(Camera)],Path,'MultiSelect', 'off');
        [PathName,FileName,~] = fileparts(fullfile(Path,File));
        %Read information from ini-file
        fid = fopen(fullfile(Path,File));
        ini_raw=textscan(fid,'%s %q','Delimiter','=');
        fclose(fid);
        %Put file info in a struct
        ini{Sequence,Camera}.Sequence=Sequence;
        ini{Sequence,Camera}.Camera=Camera;
        ini{Sequence,Camera}.PathName={PathName};
        ini{Sequence,Camera}.FileName={[FileName,'.vif']};
        ini{Sequence,Camera}.Nframes = str2double(ini_raw{1,2}(10));
        ini{Sequence,Camera}.AOIWidth = str2double(ini_raw{1,2}(32));
        ini{Sequence,Camera}.AOIHeight = str2double(ini_raw{1,2}(34));
        
        %Define user input field
        Inputfield{1,(Camera*2-1)}=['Start frame Camera ',num2str(Camera)];
        Inputfield{1,(Camera*2)}=['Stop frame Camera ',num2str(Camera)];
    end
    %user input start stop frame
    Triggers = inputdlg(Inputfield,'Start-Stop frame');
    for Camera=1:Ncam
        ini{Sequence,Camera}.Start=str2double(Triggers{(Camera*2-1),1});
        ini{Sequence,Camera}.Stop=str2double(Triggers{(Camera*2),1});
        if isempty(iniT)
        iniT = struct2table(ini{Sequence,Camera});
        else
        iniT=[iniT;struct2table(ini{Sequence,Camera})];
        end
    end
    NewSeq = questdlg('Load new sequence?','New sequence?','Yes','No','Yes');
    if strcmpi(NewSeq,'No')
        Sequence = NaN;
    else
        Sequence = Sequence+1;
    end
end
%Save XCAP ini-file information
[filename_table, pathname_table] = uiputfile(fullfile(Path,'VideoFile-Information.xlsx'),...
                       'Save file');
if isequal(filename_table,0) || isequal(pathname_table,0)
   disp('User selected Cancel')
else
   writetable(iniT,fullfile(pathname_table,filename_table));
end
end