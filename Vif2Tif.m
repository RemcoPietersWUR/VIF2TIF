%Convert VIF to tiff

%%Load video information
%User input Excel sheet with video/sequence information
[File, Path] = uigetfile({'*.xlsx','Excel-sheet'},...
    'Video information sheet','MultiSelect', 'off');
[PathName,FileName,Ext] = fileparts(fullfile(Path,File));
VideoInfo=readtable(fullfile(PathName,[FileName,Ext]));

%Process vif2tif
%Work per sequence
Nseq=unique(VideoInfo.Sequence);
row=1;
for i_seq=1:Nseq
    Ncam=numel(find(VideoInfo.Sequence==i_seq));
    %Preallocate timestamp array, assumption all recordings in same
    %sequences have the same frame number per recording
    timestamp=zeros(VideoInfo.Nframes(row),Ncam,'uint64');
    %Preallocate StartFrame array
    StartFrame=NaN(1,Ncam);
    %Preallocate StopFrame array
    StopFrame=NaN(1,Ncam);
    %Read timestamp
    for i_cam=1:Ncam
        %Get video props
        PathNameSeq{1,i_cam}=VideoInfo.PathName(row);
        FileNameSeq{1,i_cam}=VideoInfo.FileName(row);
        Nframes=VideoInfo.Nframes(row);
        AOIWidth=VideoInfo.AOIWidth(row);
        AOIHeight=VideoInfo.AOIHeight(row);
        %Get timestamp
        timestamp(:,i_cam)=VIFtimestamp(char(PathNameSeq{1,i_cam}),char(FileNameSeq{1,i_cam}),Nframes,AOIWidth,AOIHeight);
        %Get start-stop frames user indicated
        StartFrame(1,i_cam)=VideoInfo.Start(row);
        StopFrame(1,i_cam)=VideoInfo.Stop(row);
        row=row+1;
    end
    %Assump circular buffer with event stop trigger
    %Find frame number stop event
    [~,EventStop] =max(timestamp);
    %Calculate delay between stop frame, user indicated, and stop event
    %This delay is equal for all recordings in one sequence (if cameras are
    %synced). Delay is use to find corresponding frames in the other
    %recodings in the same sequence.
    Delay=EventStop-StopFrame;
    %Find cameras without indicated start stop frames
    noStartStopcam=find(isnan(Delay));
    StartStopcam=find(isfinite(Delay));
    %Indicate which frames have to converted, array of 1's and 0's. 1 = convert, 0 = no conversion
    ConvertFrames=zeros(Nframes,Ncam);
    for i_cam=1:Ncam
        if any(noStartStopcam == i_cam)
            %Assume only for one cam start & stop frame is known
           FramesRecording = StopFrame(StartStopcam)-StartFrame(StartStopcam)+1;
           if FramesRecording < 0
               FramesRecording=(Nframes-StartFrame(StartStopcam))+StopFrame(StartStopcam);
           end
           StopFrame(1,i_cam)=EventStop(1,i_cam)-Delay(1,StartStopcam);
           if StopFrame(1,i_cam)<0
               StopFrame(1,i_cam)=Nframes+StopFrame(1,i_cam);
           end
           StartFrame(1,i_cam)=StopFrame(1,i_cam)-(FramesRecording-1);
           if StartFrame(1,i_cam)<0
               StartFrame(1,i_cam)=StopFrame(1,i_cam)-(FramesRecording-0);
               StartFrame(1,i_cam)=Nframes+StartFrame(1,i_cam);
           end
        end
            %Start and Stop frames are indicated by the user
            if StartFrame(1,i_cam)>StopFrame(1,i_cam)
                ConvertFrames(1:StopFrame(1,i_cam)+1,i_cam)=1;
                ConvertFrames(StartFrame(1,i_cam)+1:Nframes,i_cam)=1;
            else
                ConvertFrames(StartFrame(1,i_cam)+1:StopFrame(1,i_cam)+1,i_cam)=1;
            end
    end
    for i_cam=1:Ncam
    %Convert VIF to tiff
    FramesRecording_t(i_cam) = StopFrame(i_cam)-StartFrame(i_cam)+1;
    StartTimestamp=timestamp(StartFrame(1,i_cam)+1,i_cam);
    [ddd,FrameNumber]=convertVIF2TIF(char(PathNameSeq{:,i_cam}),char(FileNameSeq{:,i_cam}),ConvertFrames(:,i_cam),StartTimestamp,AOIWidth,AOIHeight,'TIF');
    end
end




