function [  ] = startEdfPlusViewer(  )
%startEdfPlusViewer:  starts up GUI program.  
%   Functions:  
%       (1)  Adds paths to all subfunctions
%       (2)  Opens GUI interface
%   Detailed explanation goes here

%%(1)  Add paths to all functions in GUI
    baseFolder = edfPlusViewerPath();
    addpath(genpath([baseFolder filesep 'loadFunctions' ]))
    addpath(genpath([baseFolder filesep 'guiFunctions' ]))
    addpath(genpath([baseFolder filesep 'settings' ]))
%%(2)  Open/ run GUI
    guiBase

end


