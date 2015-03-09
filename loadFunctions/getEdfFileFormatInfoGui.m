function [isEdfPlus, dataChannels] = getEdfFileFormatInfoGui(header)
% getEdfFileFormatInfoGui(): HELPER LOAD FUNCTION
% Purpose: returns info about the file format, and a vector containing channel numbers that
% are the dataChannels,
% Input:  header from edf_extract_header.
%
% Used in guiBase.m load functions 

	isEdfPlus = header.isEdfPlus;
    if ~header.isEdfPlus    
         nDataChannels = header.nchan;
         dataChannels = [1:nDataChannels];
    else
        %Find annotation channel:
        annoteChan = find(cellfun('isempty',regexpi(cellstr(header.chan.labels), 'annotations'))==0);
        nDataChannels = header.nchan-1; 
        dataChannels = [1:nDataChannels];
        if  nDataChannels>=annoteChan
            error(['Unimplemented: way to deal with dialog box'...
                'for annotation and manual channels that are not last channels'])
        end 
    end