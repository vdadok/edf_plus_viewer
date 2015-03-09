function [ header ] = edf_extract_headerGui( filepathname )
% edf_extract_header returns  information from an edf header
%   Input:  filepathname  is full path string to the edf file
%   Output: header is a structure 
%
% See: http://www.edfplus.info/specs/edfplus.html and
% http://www.edfplus.info/specs/edf.html for more information on edf+

%% Other checks:
    fullfilepath = filepathname;
    if exist(fullfilepath,'file') == 0
       error('File not found')
    end

%% Open File and get file info
   [fid, message] = fopen(fullfilepath, 'r');  % read only
   if fid<0
       disp(message)
       error('FID invalid, try again')
   end

    %% Go through header and extract important information:
    headerlength = 256; 
    H=fread(fid, headerlength, 'uint8');
    header=char(H');
        
    hinfo.firstreservedspace = header(193:193+43);
    isEdfPlus = ~isempty(strfind(hinfo.firstreservedspace,'EDF+'));
    hinfo.isEdfPlus = isEdfPlus;
    if (isEdfPlus && isempty(strfind(hinfo.firstreservedspace,'EDF+C')))
        disp(['EDF may not be continuous, see EDF website for details.' ... 
        'If first reserved header is EDF+D, then file is discontinuous'])
        hinfo.edfPlusWarning = 'EDF may not be continuous, see EDF website for details.';
        %http://www.edfplus.info/specs/edfplus.html#timekeeping
    end
        
    % Get info (edf+ you can get additional information)
    % See: http://www.edfplus.info/specs/edfplus.html#additionalspecs
        subInfoLine = header(9:9+79);
        
    %Look at other parts of header    
        localrecord = header(89:89+79); % local recording identification
        hinfo.startdate = header(169:169+7); %startdate
        hinfo.starttime= header(177:177+7); %start time hh.mm.ss
        hinfo.startDateVec = datevec([hinfo.startdate ' ' hinfo.starttime], 'dd.mm.yy HH.MM.SS');
        header(185:185+7); %number of bytes in header record
        hinfo.edfFormat = header(193:193+43); % firstreservedspace reserved for edf+ (44 char)
        hinfo.nrecords = str2num(header(237:237+7));  %number of data records
        hinfo.duration =  str2num(header(245:245+7));  %duration of data in seconds
        hinfo.nchan = str2num(header(253:253+3));  % number of signals (ns) in data record
         ns = hinfo.nchan;
       
        
   %% Look at channel information:  
   % Store relevant channel information in chaninfo structure.
   % Channel labels: (16 ascii/chan). Note last chan will be annotations
       H=fread(fid, ns*16, 'uint8');
       chanlabels=char(H');
       hinfo.chan.labels = vec2mat(chanlabels, 16,ns);
     %Transducer types: (80 ascii/chan)
       H=fread(fid, ns*80, 'uint8');
     %Physical dimensions (muV) (8 ascii/chan)
       H=fread(fid, ns*8, 'uint8');
       physicaldims=char(H');
       hinfo.chan.physicalUnits = vec2mat(physicaldims, 8,ns);
     %physical minimums (8 ascii/chan)
       H=fread(fid, ns*8, 'uint8');
       physicalmins=char(H');
       hinfo.chan.physicalmins = str2num(vec2mat(physicalmins,8, ns));
     %physical maximums (8 ascii/chan)
       H=fread(fid, ns*8, 'uint8');
       physicalmaxes=char(H');
       hinfo.chan.physicalmaxes = str2num(vec2mat(physicalmaxes,8, ns));
     %digitial minimums (8 ascii/chan)
       H=fread(fid, ns*8, 'uint8');
       digitalmins=char(H');
       hinfo.chan.digitalmins= str2num(vec2mat(digitalmins,8, ns));
     %digital maximums (8 ascii/chan)
       H=fread(fid, ns*8, 'uint8');
       digitalmaxes=char(H');
       hinfo.chan.digitalmaxes = str2num(vec2mat(digitalmaxes,8, ns));
     %prefiltering (80 ascii/chan)
       H=fread(fid, ns*80, 'uint8');
       prefilters=char(H'); 
       hinfo.chan.prefilters = vec2mat(prefilters, 80, ns);
     %number of samples in data records (8 ascii/chan), per 1 sec, hz
       H=fread(fid, ns*8, 'uint8');
       nsampperdatarecord=char(H');
       hinfo.chan.Nsamplesperrecord = str2num(vec2mat(nsampperdatarecord, 8, ns));
     %reserved space for each (32ascii/chan)
       H=fread(fid, ns*32, 'uint8');
       reservedspace=char(H');
  
    % First annotation has start time (finer grained than sec)  
    % http://www.edfplus.info/specs/edfplus.html#timekeeping
    for m=1:ns      
        nr=hinfo.chan.Nsamplesperrecord(m); %samples per duration for this channel
        if isempty(strfind(hinfo.chan.labels(m,:), 'Annotation')) 
            fseek(fid,  nr*2,0); 
        else    
            H = fread(fid, 512, 'uint8');   
            char20s=find(H==20);
            hinfo.factionsecondstart =str2double(char(H(2:char20s(1)-1)') );
        end
    end
        
    hinfo.chan.physicaloffsets = (hinfo.chan.physicalmaxes+hinfo.chan.physicalmins)/2;
    hinfo.chan.scaleperBit = (hinfo.chan.physicalmaxes-hinfo.chan.physicalmins)./(hinfo.chan.digitalmaxes-hinfo.chan.digitalmins)  ;
    hinfo.chan.samplingRate = hinfo.chan.Nsamplesperrecord./hinfo.duration; 
    areAllSameSamplngRate =isempty(find(hinfo.chan.samplingRate~=hinfo.chan.samplingRate(1)));
    if areAllSameSamplngRate
        hinfo.samplingRate = hinfo.chan.samplingRate(1);
    else
        hinfo.samplingRate =[];
    end
    hinfo.originatingFile = filepathname;
    hinfo.dateExtractedFromRawFile = datestr(date, 29);   
    header = hinfo;
    fclose(fid);
    
end

