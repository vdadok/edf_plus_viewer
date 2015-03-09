function [channelData]=edf_extract_chan_clip_rangeMemMapGui(fullfilepath, channelArray,clipBounds,mMap,hinfo)
%edf_extract_chan_clip_rangeMemMapGui
%
% Input:   fullfilepath - 	string listing full path to edf+ file 
%          channelNo -      integer listing of channel.
%          clipBounds -     2-vector (i.e. [1 2]), indicating time in
%                   seconds which want to be clipped.  Note, if clipBounds
%                   don't line up with sampling rate to an integer, this
%                   will be rounded to closest sample.
%          mMap -           memory map
%          hinfo -          header info from edf_extract_header
% See: http://www.edfplus.info/specs/edfplus.html and
% http://www.edfplus.info/specs/edf.html for more information  on data
% setup and specs.



%% User Settings
    [sortedChansToSave, iSorted] = sort(channelArray);  
    nChansToSave = length(sortedChansToSave);

%% Go through header and extract important information:
    ns = hinfo.nchan;

    % Determine if File is an EDF+ or EDF filetype:
    isEdfPlus = ~isempty(strfind(hinfo.firstreservedspace,'EDF+'));

    %Check for discontinuous EDF+ (not dalt with so far)
    if isEdfPlus&&isempty(strfind(hinfo.firstreservedspace,'EDF+C'))
        disp(['EDF may not be continuous, see EDF website for details.' ... 
        'If first reserved header is EDF+D, then file is discontinuous'])
        %http://www.edfplus.info/specs/edfplus.html#timekeeping
    end 
        
  
%% Open File and get file info
    % Skip through header and channel information
    if isempty(mMap)
      headerlength = 256; 
      chaninfolength = ns*256;   
      mMap = memmapfile(fullfilepath, 'Format', 'int16',...
       'Offset', headerlength+chaninfolength);
    end
   
    if ~isempty(find(sortedChansToSave==ns))
       error(['Channel may be annotation channel. ' num2str(ns) 'channels in this data set'])
    end
    if ~isempty(find(sortedChansToSave>ns))
       error(['Channel does not exist. Only ' num2str(ns) 'channels in this data set'])
    end

   
     nLinesWithinChansOfInterest = hinfo.chan.Nsamplesperrecord(sortedChansToSave);

     areAllChanSameSamplingRate = isempty(find(nLinesWithinChansOfInterest-nLinesWithinChansOfInterest(1)));
     if areAllChanSameSamplingRate
        channelDataSorted = extractClipRangeSameSamplingRatesB(mMap, channelArray,clipBounds,hinfo);
        channelData=channelDataSorted(iSorted);
     else
         channelData=cell(1,nChansToSave);
         for k=1:nChansToSave
             edf_extract_chan_clipMemMapGui(fullfilepath, channelArray(k),clipBounds,mMap,hinfo);
           
         end
     end
end

function [channelData] = extractClipRangeSameSamplingRatesB(mMap, sortedChansToSave,clipBounds,hinfo)
    ns = hinfo.nchan;
    duration = hinfo.duration;
    
    nChansToSave = length(sortedChansToSave);

    firstChanToSave = sortedChansToSave(1);
    cumSumChannelLines = [0; cumsum(hinfo.chan.Nsamplesperrecord(:))];
    linesToFirstChanOfInterest =cumSumChannelLines(firstChanToSave);     
    linesBetweenFirstAndOtherChansOfInterest =...
        (cumSumChannelLines(sortedChansToSave))-...
        linesToFirstChanOfInterest;
       
    chanToSave = sortedChansToSave(1);
    nBytesPerSample=1;  
    nSamplesPerRecordOfInterest =hinfo.chan.Nsamplesperrecord(chanToSave);

    %Define the number of lines between each consecutive record for this channel
    iOtherDataChans = 1:ns;       
    iOtherDataChans(chanToSave)=[];
    nlinesbetween = nBytesPerSample*sum(hinfo.chan.Nsamplesperrecord(iOtherDataChans));
 
    nlinesperrecord = nlinesbetween+nSamplesPerRecordOfInterest*nBytesPerSample;
   
    linesToChanOfInterest =...
        nBytesPerSample*sum(hinfo.chan.Nsamplesperrecord(1:(chanToSave-1))); 
   
    %Find number of lines to clip of interest
    iRecordClipStart=floor(clipBounds(1)/duration); 
    iIndexWithinRecordStart =round((clipBounds(1)/duration-iRecordClipStart)*nSamplesPerRecordOfInterest);
    iRecordClipStop = floor(clipBounds(2)/duration); 
    iIndexWithinRecordStop = round((clipBounds(2)/duration-iRecordClipStop)*nSamplesPerRecordOfInterest);

    % Loop through all clip records
    nFullRecordsWithinClip = iRecordClipStop-iRecordClipStart-1; 
    isClipContainedWithinSinglePartialRecord = (nFullRecordsWithinClip<0);  
  

%% Reading Clip Data In:
    nTotalSamplesInClip = (nFullRecordsWithinClip+1)*nSamplesPerRecordOfInterest+iIndexWithinRecordStop-iIndexWithinRecordStart;
%% Prep indices to load from mmap
    iToLoad=zeros(nTotalSamplesInClip,1);
    currFseekOffset = 1;
    currFseekOffset=currFseekOffset+linesToChanOfInterest;
    currFseekOffset=currFseekOffset+nlinesperrecord*iRecordClipStart;
    currFseekOffset=currFseekOffset+iIndexWithinRecordStart*nBytesPerSample;
   
    if isClipContainedWithinSinglePartialRecord
        nInFirstPartialRecord=iIndexWithinRecordStop-iIndexWithinRecordStart;
        iToLoad = currFseekOffset:currFseekOffset+nInFirstPartialRecord-1;
    else    
        %First partial record
        nInFirstPartialRecord=nSamplesPerRecordOfInterest-iIndexWithinRecordStart;
        iInFirstPartialRecord = currFseekOffset:currFseekOffset+nInFirstPartialRecord-1;
        iToLoad(1:nInFirstPartialRecord) = iInFirstPartialRecord;
        currFseekOffset=currFseekOffset+nInFirstPartialRecord+nlinesbetween;

        %All full records:
        iPerFullRecord = 0:nSamplesPerRecordOfInterest-1;
        fullRecordStartI = currFseekOffset+[0:nFullRecordsWithinClip-1]*nlinesperrecord;
        tmpFullRecords = repmat(iPerFullRecord',1,nFullRecordsWithinClip);
        iInAllFullRecords = bsxfun(@plus, tmpFullRecords, fullRecordStartI);
        lenFullRecs = nSamplesPerRecordOfInterest*nFullRecordsWithinClip;
        iToLoad(nInFirstPartialRecord+(1:lenFullRecs))=iInAllFullRecords(1:end);
        iToLoadOffest = nInFirstPartialRecord+lenFullRecs;
        currFseekOffset = currFseekOffset+(nFullRecordsWithinClip)*nlinesperrecord;

        % Indices from final partial record
        iInLastPartialRecord = currFseekOffset:currFseekOffset+iIndexWithinRecordStop-1;
        iToLoad(iToLoadOffest+1:end) = iInLastPartialRecord;
    end
   
%% Load DATA:
    % Offset of physical units (often 0)
    physicaloffset = hinfo.chan.physicaloffsets(sortedChansToSave);
    % mV (or other physical unit) per unit of integer in data.
    scaleperBit = hinfo.chan.scaleperBit(sortedChansToSave);

    tmp1 = repmat(iToLoad, 1, nChansToSave);
    allIToLoad = bsxfun(@plus, tmp1, linesBetweenFirstAndOtherChansOfInterest');
    rawChanData = double(mMap.Data(allIToLoad(:)));
    rawChanData = reshape(rawChanData, nTotalSamplesInClip,nChansToSave);
    rawChanData = bsxfun(@times, rawChanData, scaleperBit');
    rawChanData= bsxfun(@plus, rawChanData, physicaloffset');
    channelData= num2cell(rawChanData,[1])';

end  
