classdef guiDataClass < handle
    % guiDataClass: holds data for GUI
    % by inheriting from the handle class, this won't make copies
    %
    % Assumptions: only one sampling rate across all channels

    properties
        % plotting properties: changes time to load and speed of scrolling
            maxTimeToLoad=120*2;     % amount of time in seconds to load for each window
            lowTimeFraction = .25;   % amount of loaded window for data in 
                                % front of the current plotted window.
            lowTime;
            highTime;
            
        % File I/O properties to enable data loading:
            fullEdfFilePath;
            isEdfPlus;
            edfHeader;
            chosenChans;  %channels for loading
            chosenTime;   %time bounds
            mMap;

       %Current Data properties: (since we won't load all data at once)   
            currentTimeSegment;  % 2-vector of times defining the start 
                                 % and end time of currently loaded data.  
                                 % This is an updating window as you 
                                 % attempt to plot different parts of series
            
        %Data properties
            data;  %data
            sRate; %sample rate
            nChan; %number of channels
            chanLabels; %cell array of channel labels
        
        
        % Calculated Properties
            nSamples; %number of samples.
            tLength;  %time length in seconds
            
            
        %Plot properties
            guiHandles; 
    end
    
    methods
        %CONSTRUCTING AND LOADING FUNCTIONS:
        function c = guiDataClass(varargin) %constructor
            switch nargin
                case 1 
                    %File I/O:
                    c.fullEdfFilePath = varargin{1}.fullEdfFilePath;
                    c.chosenTime = varargin{1}.chosenTime;
                    c.chosenChans = varargin{1}.chosenChans;
                    c.isEdfPlus = varargin{1}.isEdfPlus;
                    
                    %Plotting Variables:
                    c.currentTimeSegment = [c.chosenTime(1), min(c.chosenTime(2), c.chosenTime(1)+c.maxTimeToLoad)];
                    
                    
                    %Load Data from Raw Data Files:
                    initializeChanInfo(c);    % loads chan names etc.
                    initializeMemMap(c);  % make mMap
                    loadCurrentDataWindow(c); % loads data
                    
                    %calculated
                    c.tLength = c.chosenTime(2)-c.chosenTime(1);
                    c.nSamples = c.tLength*c.sRate;                    
                    
                    %More plotting Variables 
                    c.lowTime = round(c.lowTimeFraction*c.maxTimeToLoad*c.sRate)/c.sRate;
                    c.highTime = c.maxTimeToLoad-c.lowTime;
                    
                    %Plotting axes/Gui links to handles:
                    c.guiHandles = varargin{1}.guiHandles;
 
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function initializeMemMap(c);  %make mMap 
            headerlength = 256;  % always true for edf files
            chaninfolength = c.edfHeader.nchan*256;
            c.mMap = memmapfile(c.fullEdfFilePath, 'Format', ...
                'int16', 'Offset', headerlength+chaninfolength);
        end

        function initializeChanInfo(c)
            %Load Header From edf file:
                header = edf_extract_headerGui(c.fullEdfFilePath);
            %Extract info from header into class data members:
                c.edfHeader=header;
                c.chanLabels=cell(1,length(c.chosenChans));
                c.nChan = length(c.chosenChans);
            %Get Sampling Rates:
                if ~c.isEdfPlus
                    c.sRate=header.samplingRate;
                else
                    c.sRate=header.chan.samplingRate(c.chosenChans(1)); 
                end
            %Get Channel Label names:
                for k=1:c.nChan
                    chanNo = c.chosenChans(k);
                    c.chanLabels{k}=deblank(header.chan.labels(chanNo,:));
                end
        end
        
        
        % Loads data within range of currentTimeSegment 
        function loadCurrentDataWindow(c)
            if ~c.isEdfPlus
                for k = 1:c.nChan
                    chanNo = c.chosenChans(k);
                    channelFieldName = ['ch' num2str(k)];
                    c.data.(channelFieldName) = edf_extract_chan_clipGui(c.fullEdfFilePath, chanNo, c.currentTimeSegment, c.edfHeader);
                end      
            else
                c3=edf_extract_chan_clip_rangeMemMapGui(c.fullEdfFilePath,...
                     c.chosenChans, c.currentTimeSegment,c.mMap, c.edfHeader);
                %Rough 60 Hz filter:
                [B,A] = butter(4, [59.0, 61.0]/c.sRate*2, 'stop');
                for k = 1:c.nChan
                    channelFieldName = ['ch' num2str(k)];
                    if 1
                        %60Hz %TODO: make configurable if filtering or not
                        c.data.(channelFieldName)=filtfilt(B,A,c3{k});
                    else
                        c.data.(channelFieldName)=c3{k};
                    end
                end
            end
        end

        
        % Plotting function for GUI
        function plotPiece(c, plotStartTime,timeScale,yScale)
            if ~isPlotTimeInCurrentTimeSegment(c, plotStartTime)||...
                    ~isPlotTimeInCurrentTimeSegment(c, min(plotStartTime+timeScale, c.chosenTime(2)))
                updateCurrentTimeSegment(c, plotStartTime);
            end
            hAxes =  c.guiHandles.eegAxes;
            yscale=yScale;
            
            % Plot a piece of the time series.                     
            nPointsPerWin= timeScale*c.sRate;
            plotStartIndex = round(c.sRate*(plotStartTime-c.currentTimeSegment(1))+1);
            plotStopIndex = min(round(plotStartIndex+nPointsPerWin),...
                round(c.sRate*(c.currentTimeSegment(2)-c.currentTimeSegment(1))));
            plotIndices = plotStartIndex:plotStopIndex;

            axis manual

            for k=1:c.nChan
                % Scale data and offset it
                offset = 0.5 + c.nChan - k;
                yPlotData = offset+yscale * c.data.(['ch' num2str(k)])(plotIndices);
                xPlotData = (plotIndices-1) / c.sRate+c.currentTimeSegment(1);
                plot(hAxes, xPlotData, yPlotData)
                set(hAxes, 'NextPlot', 'add')
            end
            
            % Add yscale line:
            xPlacement =repmat([xPlotData(1)+(xPlotData(end)-xPlotData(1))*.9],2,1);
            textPlacement = [xPlotData(1)+(xPlotData(end)-xPlotData(1))*.91];
            yPlacement = 0.5 + (c.nChan)/2-1+ [yscale*1; yscale*100];
            line(xPlacement,yPlacement, 'Color', 'r' ,  'LineWidth', 2, 'Parent', hAxes);
            text(textPlacement, (yPlacement(1)+yPlacement(2))/2,...
                '100 {\mu}V',...
                'Color', 'r', 'FontWeight', 'bold', ...
                'FontSize', 14, 'BackgroundColor', [1,1 ,1],...
                 'Parent', hAxes);

            set(hAxes, 'NextPlot', 'replacechildren')
            xlim(hAxes,[xPlotData(1), xPlotData(1)+timeScale]);
            ylim(hAxes,[0, c.nChan]);
            set(hAxes, 'YTick', [0.5 : c.nChan - 0.5]);
            set(hAxes, 'YTickLabel', c.chanLabels(end:-1:1));
            set(hAxes, 'XGrid', 'on');
            drawnow
            
            % Draw annotations:
            if isfield(c.guiHandles, 'ainfo')
                set(hAxes, 'NextPlot', 'add') 
                ainfo = c.guiHandles.ainfo;
                xOnsets = ainfo.onsetTimes-ainfo.recordStartTimes(1);
                xOffsets = ainfo.onsetTimes-ainfo.recordStartTimes(1)+ainfo.durationTimes;
                iAllNearText = ...
                    find((xOnsets-xPlotData(1)>=0)&(xOnsets-xPlotData(end)<=0)|...
                    (xOffsets-xPlotData(1)>=0)&(xOffsets-xPlotData(end)<=0));
                for k=1:length(iAllNearText)
                    % highlight locations of start/end annotations. 
                    % Note: add if statement here to only show this for
                    % some annotations.
                    tonset = xOnsets(iAllNearText(k));
                    toffset = xOffsets(iAllNearText(k));
                    plot(hAxes, tonset*[1,1], ylim(hAxes), 'Color', 'g',  'LineWidth', 4 )
                    plot(hAxes, toffset*[1,1], ylim(hAxes), 'Color', 'r', 'LineStyle', '--', 'LineWidth', 3 )
                    if isempty(ainfo.annotations{iAllNearText(k)})
                        textToWrite = 'none';
                    else
                        textToWrite = ainfo.annotations{iAllNearText(k)};
                    end
                    yLimits = ylim(hAxes);
                    yLocation =yLimits(1)+...
                        (yLimits(2)-yLimits(1))*.05;
                    text(tonset, yLocation, ...
                            textToWrite,...
                            'Color', 'k', 'FontWeight', 'bold', ...
                            'FontSize', 14, 'BackgroundColor', [1,1 ,1],...
                            'Parent', hAxes);
                end
                set(hAxes, 'NextPlot', 'replacechildren')
           end
           
        end
        
        
        % Is the time window we'd like to plot in GUI included in
        % already loaded data
        function tf = isPlotTimeInCurrentTimeSegment(c, plotTime)
            tf =  (plotTime>=c.currentTimeSegment(1)) &&...
                    (plotTime<=c.currentTimeSegment(2));
        end
        
        
        % Update the currentTimeSegment to be around plotTime (with
        % lowTime seconds below plotTime and highTime seconds above)
        function updateCurrentTimeSegment(c, plotTime)
            c.currentTimeSegment = ...
                [  max(plotTime-c.lowTime,c.chosenTime(1)) , ...
                   min(plotTime+c.highTime, c.chosenTime(2))        ];
            loadCurrentDataWindow(c);
        end

    end  
end

