function result = putSlicerVolume( volume )

% This is an example script that shows how to establish a writing pipe to a
% running slicer daemon (start Slicer3 with option --daemon).
% These steps have to be done to adapt the script to your environment:
% - matlab extentions "popenr" and "popenw" have to be compiled for your
%   machine: cd into $SLICER_HOME/Modules/SlicerDaemon/matlab/popen , and
%   do "mex popenr.c" and "mex popenw.c" in matlab.
% - make sure you add the path to popen
% - make sure to add the path to the matlab scripts in 
%   $SLICER_HOME/Modules/SlicerDaemon/Tcl
%
% Sends the structure "volume" to Slicer. This structure has to follow the 
% conventions in ....
% The Name of the volume in Slicer will be volume.content

% add path for popen
cpath = pwd;
cd('popen');
pName = pwd;
addpath (pName);

% find slicerput.tcl script
cd( cpath );
cd('../Tcl');
pScript = pwd;
cd( cpath );

% write to pipe
cmd_w = sprintf('%s/slicerput.tcl %s',pScript, volume.content);
p_w = popenw(cmd_w);
if p_w < 0
    error(['Error running popenr(',cmd_w,')']);
end

pwriteNrrd(p_w,volume)

% close pipe
popenw(p_w,[])

return
