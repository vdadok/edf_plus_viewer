function [annotations] = edf_extract_annotationsGui(fullfileinputpath)
% [annotations] = edf_extract_annotationsGui(fullfileinputpath)
% Extracts annotations from an edf+ file
% 
% Inputs
%       fullfileinputpath  - path to the edf file to get annotations from
% 
% Outputs
%       hinfo - contains header information that's relevant
%
% See: http://www.edfplus.info/specs/edfplus.html and
% http://www.edfplus.info/specs/edf.html for more information  on data
% setup and specs.


%% Open file
    hinfo = edf_extract_headerGui(fullfileinputpath);
    chaninfo = hinfo.chan;
    ns = hinfo.nchan;
    
    if exist(fullfileinputpath,'file') == 0
       error('File not found')
    end

    [fid, message] = fopen(fullfileinputpath, 'r'); 
    if fid<0
       disp(message);
       error('Invalid FID, wait and try again')
    end
   
    %Skip through header and channel information
    headerlength = 256; 
    fread(fid, headerlength, 'uint8'); 
    chaninfolength = ns*256;
    fread(fid, chaninfolength, 'uint8'); 

%% Look at Data Records
    annotChan = find(cellfun('isempty',regexpi(cellstr(chaninfo.labels), 'Annotations'))==0);

    if (annotChan~=ns)
       % Annotation channel is likely
       error(['This code assumes annotation channel is the last channel'...
           'Need to edit the code to get to to first annotation '...
           'line']);
    end

    nlinesBtwnAnnotations = 2*sum(chaninfo.Nsamplesperrecord(1:(annotChan-1)));
    ainfo.recordStartTimes = -ones(hinfo.nrecords,1);  
    allocatesize =  floor(hinfo.nrecords/200);
    ainfo.onsetTimes = -ones( allocatesize,1);
    ainfo.durationTimes = zeros( allocatesize,1);
    ainfo.annotations = cell(allocatesize,1);
    acount = 1;
    nrecordsToExplore = hinfo.nrecords; %number of records, each duration seconds
    for p = 1:nrecordsToExplore 
       %preallocate space
       maxNTAL = 50;
       durationTimes = -ones(maxNTAL, 1);
       onsetOffsetTimes = -ones(maxNTAL, 1);
       TALannotations = cell(maxNTAL, 1);
       
       if (mod(p, 1000) == 0)
           disp([num2str(p) 'of' num2str(nrecordsToExplore)])  
       end       
       %Data channels:
            fseek(fid,nlinesBtwnAnnotations,0);
       %Annotation channel data:
            H = fread(fid, 512, 'uint8')';  
             
        char20s=find(H==20);
        recordStartTime =str2double(char(H(1:char20s(1)-1)));
        
        if length(char20s)==2  %There are no real annotations
           ainfo.recordStartTimes(p) = recordStartTime; 
           nTAL=0;
        else      
            char0s = [find(H==0)];
            btwn0sL = [1, char0s(1:end-1)+1];
            btwn0sR = [char0s-1];             
            emptyannotes=find(btwn0sR-btwn0sL<0); % ignore consecutive zeros
            btwn0sL(emptyannotes) = [];
            btwn0sR(emptyannotes) =[];
            nTAL = length(btwn0sL)-1; %first annotation is just time stamp.
            for o=1:nTAL
                currTAL = (H(btwn0sL(o+1):btwn0sR(o+1)));
                curr20s = find(currTAL==20);
                curr21s =find(currTAL==21);  
                Ncurrannot= length(curr20s)-1;
                if isempty(curr21s) 
                    durationTimes(o) = 0;  % default is 0 duration
                    onsetOffsetTimes(o) = str2num(char(currTAL(1:curr20s(1)-1)));
                else 
                    durationTimes(o) = str2double(char(currTAL(curr21s+1:curr20s(1)-1)));
                    onsetOffsetTimes(o) = str2num(char(currTAL(1:curr21s(1)-1)));
                end
                if Ncurrannot == 1  % only one annotation 
                    TALannotations{o}= char(currTAL(curr20s(1)+1:curr20s(2)-1));
                else % multiple annotations:
                    error('Multiple annotations unexpected and unimplemented')
                end
            end

        %For only 1 annotation per TAL:
            ainfo.onsetTimes(acount:acount+nTAL-1) = onsetOffsetTimes(1:nTAL);
            ainfo.durationTimes(acount:acount+nTAL-1)= durationTimes(1:nTAL);
            ainfo.annotations(acount:acount+nTAL-1) =  TALannotations(1:nTAL);
            ainfo.recordStartTimes(p) = recordStartTime;
            acount = acount+nTAL;       
        end
  
    end
   
    % Remove extra allocated space in matrices
    extraindices=find(ainfo.onsetTimes==-1);
    ainfo.onsetTimes(extraindices)=[];
    ainfo.durationTimes(extraindices)=[];
    ainfo.annotations(extraindices)=[];

    % Close file:
    fclose(fid);
    
    % Toss out recordStartTimes if all are continuous
    if isempty(find(diff(ainfo.recordStartTimes(:))~=1))
         rmfield(ainfo, 'recordStartTimes');
    else
        error('EDF fxn seems discontinuous')
    end
        
   % Save final annotations to return 
   annotations = ainfo;
end
     
