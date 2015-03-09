function [ folderPathString ] = edfPlusViewerPath()
% edfPlusViewerPath() returns the path to the folder in which this m-file is located 
% with an appended filesep
   
   p = mfilename('fullpath');
   [pathstr, name, ext] = fileparts(p) ; 
   folderPathString=[pathstr filesep];

end

