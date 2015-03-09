function varargout = guiBase(varargin)
% GUIBASE MATLAB code for guiBase.fig
%      GUIBASE, by itself, creates a new GUIBASE or raises the existing
%      singleton*.
%
%      H = GUIBASE returns the handle to a new GUIBASE or the handle to
%      the existing singleton*.
%
%      GUIBASE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUIBASE.M with the given input arguments.
%
%      GUIBASE('Property','Value',...) creates a new GUIBASE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before guiBase_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to guiBase_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guiBase

% Last Modified by GUIDE v2.5 27-Feb-2013 13:08:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guiBase_OpeningFcn, ...
                   'gui_OutputFcn',  @guiBase_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before guiBase is made visible.
function guiBase_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiBase (see VARARGIN)

% Choose default command line output for guiBase
handles.output = hObject;


% Update handles structure
guidata(hObject, handles);

set(handles.guiBaseFigure, 'Renderer', 'zbuffer')

% This sets up the initial plot - only do when we are invisible
% so window can get raised using guiBase.
if strcmp(get(hObject,'Visible'),'off')   
    plot(1,1);
    set(handles.eegAxes, 'YTick', [])
    set(handles.eegAxes, 'XTick', [])
    set(handles.eegAxes, 'XLimMode', 'manual')
    set(handles.eegAxes, 'YLimMode', 'manual')
    set(handles.eegAxes, 'DataAspectRatioMode', 'manual')
    plot(1,1);
    set(handles.annotationAxes, 'YTick', [])
    set(handles.annotationAxes, 'XTick', [])
end


% --- Outputs from this function are returned to the command line.
function varargout = guiBase_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;



%%%%%%%%%%%%%%%%%%%%%%---- MENUS -----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    file = uigetfile('*.fig');
    if ~isequal(file, 0)
        open(file);
    end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    printdlg(handles.guiBaseFigure)

% --------------------------------------------------------------------
function SaveCurrentImageMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to SaveCurrentImageMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    currFile = get(handles.titleOfDatasetText, 'String');
    [~,currFileName,~] = fileparts(currFile);
    defaultFileName = [datestr(datevec(now), 'yyyy-mm-dd-HHMM') 'PicOf' currFileName];
    defaultPng = '1';
    defaultFig = '0';
    defaultPdf = '0';
    defaultStrings = {defaultFileName, defaultPng, defaultFig, defaultPdf};
    inputPrompts={'Save Filename of Figures', 'Save Png?', 'Save Fig?', 'Save Pdf?'};
    outputsOfPrompt = inputdlg(inputPrompts,'Saving as image',1,defaultStrings);
    filename = outputsOfPrompt{1};
    if strcmp(outputsOfPrompt{2}, '1')
        set(handles.guiBaseFigure, 'PaperPositionMode', 'auto');
        print(handles.guiBaseFigure,'-dpng', '-opengl', filename);
    end
    if strcmp(outputsOfPrompt{3}, '1')
               saveas(gcf, [filename '.fig']);

    end
    if strcmp(outputsOfPrompt{4}, '1')
        print(gcf,'-dpdf','-painters',filename,sprintf('-r%d',150))
    end

    
% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    selection = questdlg(['Close ' get(handles.guiBaseFigure,'Name') '?'],...
                         ['Close ' get(handles.guiBaseFigure,'Name') '...'],...
                         'Yes','No','Yes');
    if strcmp(selection,'No')
        return;
    end
    delete(handles.guiBaseFigure)

% --------------------------------------------------------------------
function LoadEdfMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to LoadEdfMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    folderName = [edfPlusViewerPath() 'settings'];
    fileName = [folderName filesep 'lastFolderLoaded'] ;
    if (~exist(folderName,'dir')) 
        mkdir(folderName);
    end
    if (~exist([fileName '.mat'],'file')) 
       lastFolder = '';
       save(fileName , 'lastFolder'); 
    end
    
    load(fileName, 'lastFolder');
    if lastFolder == 0 
        lastFolder='';
    end
    if exist(lastFolder, 'dir')
        baseLoadFolder = lastFolder;
    else
        baseLoadFolder = '';
    end
    
    loadString = [baseLoadFolder '*.edf'];
    [file, pathname] = uigetfile(loadString);
    lastFolder = pathname;
    save(fileName , 'lastFolder');
    if ~isequal(file, 0)
        %Load header of edf file:
            fullEdfFilePath = [pathname, file];
            header = edf_extract_headerGui(fullEdfFilePath);
        %Get info about EDF file format and which channels have data:
            [isEdfPlus, dataChannels] = getEdfFileFormatInfoGui(header);
        %Run load-dialog
            [chosenChans, chosenTime,loadAnnoteYN] = runLoadEdfDialog(dataChannels, header);
         set(handles.titleOfDatasetText, 'String',fullEdfFilePath);

         %load annotations
         if (isEdfPlus && loadAnnoteYN)
             loadAnnotationsFromEdfFile(handles, fullEdfFilePath, header)
         end

        %Save and plot
            multiChan.chosenChans = chosenChans;
            multiChan.fullEdfFilePath=fullEdfFilePath;
            multiChan.chosenTime = chosenTime;
            multiChan.isEdfPlus = isEdfPlus;
            multiChan.guiHandles = guidata(gcbo);
            myTimeSeries=guiDataClass(multiChan);
            set(handles.guiBaseFigure, 'UserData',myTimeSeries);

            plotStartTime = 0; 
            set(handles.dataSlider,'UserData',plotStartTime);
            set(handles.dataSlider,'Value', 0);  
            plotPartOfTimeSeries(handles);   
    end

function loadAnnotationsFromEdfFile(handles,fullEdfFilePath, header)
    ainfo = edf_extract_annotationsGui(fullEdfFilePath);
    setAnnotationsIntoTimeSeries(handles, ainfo) 
    showAnnotations(handles); 
    

            
function  [chosenChans, chosenTime,loadAnnoteYN]= runLoadEdfDialog(dataChannels, header)
    %Purpose: This function makes a load dialog that returns the user-selected
    %channel numbers and time segment to explore with this GUI
    
    %User selects channels:
        defaultChan = mat2str(dataChannels);%['[1:' num2str(nDataChannels) ']'];
        defaultTime1 = ['0'];
        defaultTime2 = [num2str(header.nrecords*header.duration)];
        defaultYN = '1';
        defaultAnswers = {defaultChan,defaultTime1,defaultTime2, defaultYN};
        prompt = {'Channels to load (vector, default=all, use commas, colons, and brackets)',...
            'Start time in seconds (default=0 (first second of recording))',...
            'Stop time in seconds  (default=length of recording)', ...
            'Use EDF+ to load annotations? 1 means yes'};
        dlg_title = 'Enter channels and segments to load';
        num_lines = 1;
        dlgResults = inputdlg(prompt,dlg_title,num_lines,defaultAnswers);
    %Check start and stop time inputs
        if isempty(dlgResults)
            dlgResults = {defaultChan, defaultTime1, defaultTime2, defaultYN};
        end
        dlgStart = regexp(dlgResults{2}, '(\d)+', 'match');
        dlgStop = regexp(dlgResults{3}, '(\d)+', 'match');
        if length(dlgStart)~=1
            errordlg('Invalid start time, only use digits 0-9')
            error('Invalid start time, only use digits 0-9')
        elseif length(dlgStop)~=1
            errordlg('Invalid stop time, use only digits 0-9')
            error('Invalid start time, only use digits 0-9')
        end

        chosenTime =[str2num(dlgResults{2}), str2num(dlgResults{3})];
        if chosenTime(1)<0 ||chosenTime(2)<0
            errordlg('Invalid start or stop time, must be >= 0')
            error('blah')
        elseif chosenTime(1)>header.nrecords*header.duration ||chosenTime(2)>header.nrecords*header.duration
            errordlg('Invalid start or stop time, must be < length of file')
        elseif chosenTime(1)> chosenTime(2)
            errordlg('Invalid start or stop time, stop time must occur after start time')
        end
    
    %Check channel inputs:
        if isempty(regexpi(dlgResults{1}, '([).*?(])'))
            chosenChanStr = regexpi(dlgResults{1},'(\d)+', 'match')
            if length(chosenChanStr)~=1
                errordlg('Invalid channel input format')
            else
                chosenChans = str2num(chosenChanStr{1});
            end
        elseif length(regexpi(dlgResults{1}, '([).*?(])'))~=1
            errordlg('Invalid channel input format')
        end 
        chosenChans = eval(dlgResults{1});
        loadAnnoteYN = str2num(dlgResults{4}); 


%%%%%%%%%%%%%%%----- FUNCTIONS OF BASE GUI WINDOW ------ %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% i.e.  guiBaseFigure  (properties in handles.guiBaseFigure)
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function guiBaseFigure_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to guiBaseFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.eegAxes, 'ButtonDownFcn',{@eegAxes_ButtonDownFcn, handles} )
set(handles.annotationAxes, 'ButtonDownFcn', {@annotationAxes_ButtonDownFcn, handles});

% --- Executes on key release with focus on guiBaseFigure and none of its controls.
function guiBaseFigure_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to guiBaseFigure (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
 set(handles.guiBaseFigure, 'WindowButtonMotionFcn', '')
 setScrollingFlag(handles, '');  %Turns off scrolling

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function guiBaseFigure_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to guiBaseFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% This is for continuous keyboard scroll and arrow scroll when you hold
% button:
 set(handles.guiBaseFigure, 'WindowButtonMotionFcn', '')
 setScrollingFlag(handles, '');  %Turns off scrolling
     

% --- Executes on key press with focus on guiBaseFigure and none of its controls.
function guiBaseFigure_KeyPressFcn(hObject, eventData, handles)
% Clicking different arrows on the base gui will scroll the data left or
% right.  
% Info:
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

    %Go left options:
        arrowLeftCharVal = 28;
        lCharVal = double('l');
    %Go right options:
        arrowRightCharVal = 29;
        rCharVal = double('r');  
        uCharVal = double('u');
        dCharVal =double('d');
  % Compare key input to those
    currentChar=eventData.Character; %currentChar=get(gcf,'CurrentCharacter');
    charVal = double(currentChar);
    isLeftKey = (strcmp(eventData.Key, 'leftarrow') || charVal == arrowLeftCharVal || charVal == lCharVal);
    isRightKey = (strcmp(eventData.Key, 'rightarrow')|| charVal == arrowRightCharVal || charVal == rCharVal);
       isUpKey = (strcmp(eventData.Key, 'uparrow') || charVal == 30 || charVal == uCharVal);
    isDownKey = (strcmp(eventData.Key, 'downarrow') || charVal == 31 || charVal == dCharVal);
    if isLeftKey
        moveSliderAndPlot(handles, 'Left', .01)
    elseif isRightKey
        %fprintf('h') %this is what gets done if arrow key is held down
        moveSliderAndPlot(handles, 'Right', .01)
    elseif isUpKey
        moveSliderAndPlot(handles, 'Left', .5)
    elseif isDownKey
        moveSliderAndPlot(handles, 'Right', .5)   
    else
        disp('use ''r'' or ''l'' keys or arrow keys to scroll with keyboard')
    end
    
    
%%%%%%%%%%%% ----- GET/SET/STATE OF GUI -related fxns ----- %%%%%%%%%%%%%%%%%%%
%%%---GET FXNS---%%%
function timeSeries = getGuiTimeSeries(handles)
    timeSeries=get(handles.guiBaseFigure, 'UserData');

function sliderPosition = getSliderPosition(handles)
    sliderPosition= get(handles.dataSlider,'Value');
    
%%%---STATE OF GUI FXNS---%%%       
function [tf]=isDataLoaded(handles)
%HELPER FXN:  STATE OF GUI: have you loaded the GUI Data?
 timeSeries=getGuiTimeSeries(handles); 
 tf =(~isempty(timeSeries)) ;
 


%%%%%%%%%%%% ----- OTHER UICONTROL ELEMENTS--------%%%%%%%%%%%%%%%%%%%%

%%%%% ---- YSCALE CONTROLS ---- %%%%%
function yScaleEditText_Callback(hObject, eventdata, handles)
% hObject    handle to yScaleEditText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
     plotPartOfTimeSeries(handles);
 
% --- Executes during object creation, after setting all properties.
function yScaleEditText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yScaleEditText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', '.001' )



%SCALE POPUP MENU UICONTROL      (HANDLES.scalePopupMenu)  
% --- Executes during object creation, after setting all properties.
function scalePopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scalePopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    possibleScales = {'1','5','10', '20', '30', '60', '90','120'};
    set(hObject, 'String', possibleScales);
    set(hObject, 'Value', 3); %set default to third index
    %Note: timeScale 'UserData' set to the timeScale of the screen.
    timeScaleValue = str2num(possibleScales{get(hObject,'Value')});
    set(hObject, 'UserData', timeScaleValue);

% --- Executes on selection change in scalePopupMenu.
function scalePopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to scalePopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    contents = cellstr(get(hObject,'String'));
    newScaleValue =  str2num(contents{get(hObject,'Value')});
    set(hObject, 'UserData',newScaleValue);   
    % Update plot with new timeScale:    
    plotPartOfTimeSeries(handles);
        

%DATA SLIDER UICONTROL       (HANDLES.dataSlider)  
% --- Executes during object creation, after setting all properties.
function dataSlider_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to dataSlider (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    set(hObject,'UserData',0); %time in seconds of position initially

% --- Executes on slider movement.
function dataSlider_Callback(hObject, eventdata, handles)
% hObject    handle to dataSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    updatePlotFromSliderPosition(handles);

      
% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over scrollRightButton.
function scrollRightButton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to scrollRightButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 directionString = 'Right';
 moveSliderAndPlot(handles, directionString, .1) 


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over leftScrollButton.
function leftScrollButton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to leftScrollButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    directionString='Left';
    moveSliderAndPlot(handles, directionString, .1) 

% SCROLLING FUNCTIONS FOR DATA:
function setScrollingFlag(handles, OnOffString)
    %Sets a flag somewhere to 'scrolling' or '' depending on onoffstring
    %NOTE:  must match
    if strcmp(OnOffString, 'scrolling')
        %Unset this in windowUpButtonFcn
        set(handles.scrollRightButton, 'UserData', 'scrolling'); 
    else
        %default behavior is to turn it off, so passing an incorrect value will turn off
        set(handles.scrollRightButton, 'UserData', '');
    end

function [scrollString]= getScrollingFlag(handles)
    % Must match setScrollingFlag  
    scrollString=get(handles.scrollRightButton, 'UserData');
    
    
%%%%%%%%%%%%%%%%%%----  CAP - SPECIFIC BUTTONS ----%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on mouse press over axes background.
function eegAxes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to eegAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currPt=get(handles.eegAxes, 'CurrentPoint');
set(handles.eegAxes, 'UserData', currPt(1));  %set user data as clicked pt.


% --- Executes on button press in A1Button.
function A1Button_Callback(hObject, eventdata, handles)
% hObject    handle to A1Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function text1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


%%%%%%%%%%%%%%%%%%%%----- HELPER FUNCTIONS ----%%%%%%%%%%%%%%%%%%%%%%%%%
% (not callbacks)
function [] = setTimeOfEegAxesAndUpdate(handles, newT)
 %Sets the time of the eeg axes and updates the plot and slider
     
 %Set time in user data:
    handles=guidata(gcbo); %update handles (mostly for annotation stuff)
 %Update Plots:
     plotStartTime=newT;
     timeScale= getAxesScale(handles);  
     yScale = getAxesYScale(handles);
     myTimeSeries = getGuiTimeSeries(handles);
     if ~isempty(myTimeSeries);
         plotPiece(myTimeSeries,plotStartTime, timeScale, yScale);
     end
 % Update slider position:
    [sliderPosition] = timePositionToSliderPosition(handles, plotStartTime);
    set(handles.dataSlider,'Value', sliderPosition);
    set(handles.dataSlider, 'UserData', plotStartTime);
 % Update annotation position
    updateAnnotationAxestoEegAxesPositionAnnotation(plotStartTime);
    
   
function plotPartOfTimeSeries(handles)
    % Plots a segment of the time series from plotStartTime,(in seconds)
    sliderPosition = getSliderPosition(handles);
    plotStartTime= sliderPositionToTimePosition(handles, sliderPosition);
    timeScale= getAxesScale(handles);  
    yScale = getAxesYScale(handles);
    myTimeSeries = getGuiTimeSeries(handles);
    if ~isempty(myTimeSeries);
        plotPiece(myTimeSeries,plotStartTime, timeScale, yScale);
    end
    updateAnnotationAxestoEegAxesPositionAnnotation(plotStartTime);
            
function updatePlotFromSliderPosition(handles)
% This updates the plot for the new slider position
    sliderPosition = getSliderPosition(handles);
    myTimeSeries=getGuiTimeSeries(handles);
    if ~isempty(myTimeSeries) 
        timeLocation= sliderPositionToTimePosition(handles, sliderPosition);
        % update internal variable
        set(handles.dataSlider,'UserData', timeLocation); %time in seconds of position in timeseries
        plotPartOfTimeSeries(handles);    
    end
    
function moveSliderAndPlot(handles, directionString, deltaScale)
    myTimeSeries=getGuiTimeSeries(handles);
    if ~isempty(myTimeSeries) 
        sliderPosition = getSliderPosition(handles);
        deltaTime = deltaScale*getAxesScale(handles);
        deltaPosition = timePositionToSliderPosition(handles, deltaTime);

        switch directionString
            case 'Left'
                newPosition= max(0,sliderPosition-deltaPosition);
                set(handles.dataSlider,'Value',newPosition); %in seconds
                updatePlotFromSliderPosition(handles); 
            case 'Right'
                newPosition = min(sliderPosition+deltaPosition, 1);
                set(handles.dataSlider,'Value',newPosition); %in seconds
                updatePlotFromSliderPosition(handles);
            otherwise
                disp('Warning, didn''t move slider, press l or r or arrows')
        end
    else
         disp('Warning, didn''t move slider because no data loaded')
    end
    

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get functions

function [scaleOfWindow] = getAxesScale(handles)
%Gets the scale in seconds that axes displays.
    scaleOfWindow = get(handles.scalePopupMenu, 'UserData');
 
function [yScaleOfWindow] = getAxesYScale(handles)
    %returns the current y-scale
    yScaleOfWindow=str2double(get(handles.yScaleEditText, 'String'));
 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions that convert from the slider positionto the time position (seconds) in 
% the time series and vice versa    
function [sliderPosition] = timePositionToSliderPosition(handles, timePosition)
    minSlider =  get(handles.dataSlider,'Min');
    maxSlider =  get(handles.dataSlider,'Max');
    
    myTimeSeries=getGuiTimeSeries(handles); 
    if ~isempty(myTimeSeries) %if you've defined values yet:
        nPoints = myTimeSeries.nSamples;
        sRate = myTimeSeries.sRate;
        sliderNormPosition = sRate*timePosition/(nPoints-1);
        sliderPosition= sliderNormPosition*(maxSlider-minSlider)+minSlider;       
    else 
        sliderPosition = [];
    end
    
    
function [timePosition] = sliderPositionToTimePosition(handles, sliderPosition)
    minSlider =  get(handles.dataSlider,'Min');
    maxSlider =  get(handles.dataSlider,'Max');
    sliderNormPosition = sliderPosition/(maxSlider-minSlider); %just in case
    myTimeSeries=getGuiTimeSeries(handles);
    
    if ~isempty(myTimeSeries) 
        nPoints = myTimeSeries.nSamples;
        sRate = myTimeSeries.sRate;
        timePosition= round((nPoints-1)*sliderNormPosition)/sRate;
    else
        timePosition=[];
    end



% --------------------------------------------------------------------
function LoadAllMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to LoadAllMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function annotationAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotationAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%----- Annotation FUNCTIONS ----%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Helper load function: setAnnotationsIntoTimeSeries(handles, ainfo)
function [] = setAnnotationsIntoTimeSeries(handles, ainfo)        
    handles.ainfo = ainfo;  
    guidata(gcbo, handles);
            
function ainfo = getAnnotations(handles)
 ainfo = getfield(guidata(gcbo), 'ainfo');

function showAnnotations(handles)
    set(handles.annotationAxes, 'NextPlot', 'replacechildren')
    if isfield(guidata(gcbo), 'ainfo')
        ainfo=getAnnotations(handles);
        for k=1:length(ainfo.onsetTimes)
            tsegment = ainfo.onsetTimes(k)+[0, ainfo.durationTimes(k)];
            htmp = plot(handles.annotationAxes, tsegment, [1,1], 'Marker', '.',...
                'MarkerSize', 6, 'LineWidth', 2);
            set(htmp, 'HitTest', 'off', 'HandleVisibility', 'off')
            set(handles.annotationAxes, 'NextPlot', 'add')
        end
        xlim([ainfo.recordStartTimes(1), ainfo.recordStartTimes(end)])
        ylim([0,5])
        %Turn on button down function
        set(handles.annotationAxes, 'ButtonDownFcn', {@annotationAxes_ButtonDownFcn, handles});
    else
        errordlg('Can''t showAnnotations if no annotations loaded')
    end
     

% --- Executes on mouse press over axes background.
function annotationAxes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to annotationAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    showClosestAnnotationLabel(handles)
    moveEegPlotToCenterOnAnnotationLocation(handles);


function showClosestAnnotationLabel(handles)
%Show closest annotation to where you clicked on annotationAxes
    currPt=get(handles.annotationAxes, 'CurrentPoint');
    currX = currPt(1);
    ainfo=getAnnotations(handles);
    [~, imin] = min(abs(ainfo.onsetTimes-currX));

%Handles: Delete previous annotation if exists, and create new handles showing annotations
    if isfield(handles, 'hannote')        
        delete(handles.hannote(find(ishandle(handles.hannote))))
    end
    
    handles.hannote(1) = plot(ainfo.onsetTimes(imin), 1, 'ro'); 
    handles.hannote(2) = plot(currX+[0,getAxesScale(handles)], [1 1], 'go-');
    %Uncomment to display annotation next to annotation axes
    %textPlacement = ainfo.onsetTimes(imin);
    %textToWrite = getAnnotationText(ainfo, imin);
    %handles.hannote(1) = addTextToAnnotationAxes(handles, textPlacement, textToWrite);
    for k=1:2
        set(handles.hannote(k), 'HandleVisibility', 'off', 'HitTest', 'off');
    end
    
    %Must update gui data so we can delete these annotations:
    guidata(gcbo, handles);
    
function textToWrite = getAnnotationText(ainfo, indx)
    if isempty(ainfo.annotations{indx})
        textToWrite = 'none';
    else
        textToWrite = ainfo.annotations{indx};
    end


function htext = addTextToAnnotationAxes(handles, textPlacement, textToWrite)
           htext= text(textPlacement, 3,...
                            textToWrite,...
                            'Color', 'k', 'FontWeight', 'bold', ...
                            'FontSize', 14, ...%'BackgroundColor', [1,1 ,1],...
                            'Parent', handles.annotationAxes);

function moveEegPlotToCenterOnAnnotationLocation(handles)    
% Only annotation function that currently interacts with rest of data,
% simply moves the location of plotting
    currPt = get(handles.annotationAxes, 'CurrentPoint');
    currX = currPt(1);
    ainfo = getAnnotations(handles);
    currT = currX - ainfo.recordStartTimes(1);
    setTimeOfEegAxesAndUpdate(handles, currT);
    
function updateAnnotationAxestoEegAxesPositionAnnotation(plotStartTime)
    %Handles: Delete previous annotation if exists, and create new handles showing annotations
    handles = guidata(gcbo);
    if isfield(handles, 'hannote') 
        if ishandle(handles.hannote(2))
            delete(handles.hannote(2))           
        end
        ainfo = getAnnotations(handles);
        tannote = plotStartTime + ainfo.recordStartTimes(1);
        handles.hannote(2) =plot(tannote+[0,getAxesScale(handles)], [1 1], 'go-');
        guidata(gcbo, handles); 
    end
