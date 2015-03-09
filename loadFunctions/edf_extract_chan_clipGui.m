function [channelData]=edf_extract_chan_clipGui(fullfilepath, channelNo,clipBounds, hinfo)
% edf_extract_chan_clipGui.m extracts single channel's data from file of edf+
% or edf
%
% Input:   fullfilepath - 	string listing full path to edf file 
%          channelNo -      integer listing of channel.
%          clipBounds -     2-vector (i.e. [1 2] or [0, .1]), indicating time in
%                   seconds which want to be clipped.  Note, if clipBounds
%                   don't line up with sampling rate to an integer, this
%                   will be rounded to closest sample.
%          hinfo -          header info from edf_extract_header
%
% Output:  channeldata is array
%
% See: http://www.edfplus.info/specs/edfplus.html and
% http://www.edfplus.info/specs/edf.html for more information edf+

    
%% Open File and get file info
    chanToSave = channelNo; 

    if exist(fullfilepath,'file') == 0
       error('File not found')
    end

    ns = hinfo.nchan;
    duration = hinfo.duration;
    
    [fid, message]=fopen(fullfilepath, 'r');
    if fid<0
       disp(message);
       error('Invalid FID, wait and try again')
   
    %Skip through header and channel information:
    headerlength = 256;  
    fread(fid, headerlength, 'uint8');
    chaninfolength = ns*256;
    fread(fid, chaninfolength, 'uint8');

    isEdfPlus = ~isempty(strfind(hinfo.firstreservedspace,'EDF+'));
    if isEdfPlus&&isempty(strfind(hinfo.firstreservedspace,'EDF+C'))
        disp(['EDF may not be continuous, see EDF website for details.' ... 
        'If first reserved header is EDF+D, then file is discontinuous'])
        %http://www.edfplus.info/specs/edfplus.html#timekeeping
    end 
        
    % Offset of physical units (often 0)
    physicaloffset = hinfo.chan.physicaloffsets(chanToSave);
    scaleperBit = hinfo.chan.scaleperBit(chanToSave);
    
   %% data records
   if isEdfPlus   
       annotChan = find(cellfun('isempty',regexpi(cellstr(hinfo.chan.labels), 'Annotations'))==0);
       
       %Check edge cases:
       if chanToSave==(annotChan)
           error(['Can''t Save Annotation Channel as data channel,'...
               'instead use edf_extract_annotations on annotation channel']);
       elseif chanToSave>ns
           error(['Channel does not exist. Only ' num2str(ns) 'channels in this data set'])
       end
   
       nBytesPerSample = 2; % Each sample is a 2-byte number
       nSamplesPerRecord = hinfo.chan.Nsamplesperrecord(chanToSave);
       otherDataChans = 1:ns;  
       otherDataChans([chanToSave,annotChan])=[];
       nlinesbetween = 512+ nBytesPerSample*sum(hinfo.chan.Nsamplesperrecord(otherDataChans)); 

   else  
       %Not edf+
       if chanToSave>ns
           error(['Channel does not exist. Only ' num2str(ns) 'channels in this data set'])
       end  
       nBytesPerSample = 2;
       nSamplesPerRecord = hinfo.chan.Nsamplesperrecord(chanToSave);
       
       otherDataChans = 1:ns;  
       otherDataChans(chanToSave) = [];
       nlinesbetween = nBytesPerSample*sum(hinfo.chan.Nsamplesperrecord(otherDataChans));
   end
   
    %First move file reader head to first data record of correct channel
    linesToChanOfInterest = nBytesPerSample*sum(hinfo.chan.Nsamplesperrecord(1:(chanToSave-1)));
    fseek(fid,linesToChanOfInterest,0);

    %Find number of lines to clip of interest:*
    clipStartRecord=floor(clipBounds(1)/duration);  
    clipStartIndex =round((clipBounds(1)/duration-clipStartRecord)*nSamplesPerRecord); 
    clipStopRecord = floor(clipBounds(2)/duration); 
    clipStopIndex = round((clipBounds(2)/duration-clipStopRecord)*nSamplesPerRecord);

    %Loop through all clip records
    nFullRecordsWithinClip = clipStopRecord-clipStartRecord-1; 
    isClipContainedWithinSinglePartialRecord = (nFullRecordsWithinClip<0);  

    %Reading clip data
    nTotalSamplesInClip = (nFullRecordsWithinClip+1)*nSamplesPerRecord+clipStopIndex-clipStartIndex;
    clipRawData = zeros(nTotalSamplesInClip,1);

    %Get first partial record in clip
    fseek(fid,(nlinesbetween+nSamplesPerRecord*nBytesPerSample)*clipStartRecord,0);  
    fseek(fid, clipStartIndex*2,0) ;                

    if isClipContainedWithinSinglePartialRecord  
       nInFirstPartialRecord=clipStopIndex-clipStartIndex; 
       clipRawData(1:nInFirstPartialRecord)=fread(fid, nInFirstPartialRecord, 'int16'); 
    else     % If clip extends beyond one record
        nInFirstPartialRecord=nSamplesPerRecord-clipStartIndex;  
        clipRawData(1:nInFirstPartialRecord)=fread(fid, nInFirstPartialRecord, 'int16');     
        fseek(fid, nlinesbetween, 0);  %Skip over other data   
        for p = 1:nFullRecordsWithinClip
            iClipDataLoop=1+(p-1)*nSamplesPerRecord+nInFirstPartialRecord:(p)*nSamplesPerRecord+nInFirstPartialRecord;
            clipRawData(iClipDataLoop)=fread(fid, nSamplesPerRecord, 'int16'); 
            fseek(fid, nlinesbetween, 0);  %Skip over other data                    
        end
        % Read final partial record
        p=p+1; 
        clipRawData(1+(p-1)*nSamplesPerRecord+nInFirstPartialRecord:(p-1)*nSamplesPerRecord+nInFirstPartialRecord+clipStopIndex)=fread(fid, clipStopIndex, 'int16'); %Data integers
    end   

    channelData = clipRawData*scaleperBit+physicaloffset;
    fclose(fid);    
end