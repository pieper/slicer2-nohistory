#=auto==========================================================================
# (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors.
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for  
# research purposes only, provided that (1) the above copyright notice and 
# the following four paragraphs appear on all copies of this software, and 
# (2) that source code to any modifications to this software be made 
# publicly available under terms no more restrictive than those in this 
# License Agreement. Use of this software constitutes acceptance of these 
# terms and conditions.
# 
# 3D Slicer Software has not been reviewed or approved by the Food and 
# Drug Administration, and is for non-clinical, IRB-approved Research Use 
# Only.  In no event shall data or images generated through the use of 3D 
# Slicer Software be used in the provision of patient care.
# 
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
# ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
# DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
# EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
# OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
# NON-INFRINGEMENT.
# 
# THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
# 
# 
#===============================================================================
# FILE:        IbrowserHelpGUI.tcl
# PROCEDURES:  
#   IbrowserUpdateHelpTab
#   IbrowserBuildHelpFrame
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateHelpTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateHelpTab { } {

    set ::Ibrowser(currentTab) "Help"
}



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildHelpFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildHelpFrame { } {
    #-------------------------------------------
    #--- Help frame
    #-------------------------------------------
    bind $::Module(Ibrowser,bHelp) <ButtonPress-1> "IbrowserUpdateHelpTab"
    
    set help " The <B> Interval Browser</B> or <B>Ibrowser </B> is a developing module for loading, organizing 
and processing mutl-volume sequences. Additional viewing and processing options, more 
flexible load and populate options, and the ability to load models, label maps and other 
data will be added in the future. Multi-volume sequences loaded through the Ibrowser are selectable in the
<B> fMRIEngine </B> module for statistical processing of 
functional MRI datasets.
<P>  The <B> Ibrowser </B> loads multi-volume datasets into <I> intervals </I>, which are represented 
as individual tracks on an independent pop-up control panel. Individual volumes are shown arrayed along 
an ordinal scale that registers all intervals. Selected data is displayed, manipulated and animated in the 
Slicer's Main Viewer. 
 The pop-up <B>Controller</B> lets you scroll through the volumes in an interval; select an interval; 
change the order of intervals shown in the controller; put one interval in the foreground (FG) and 
one in the background (BG); toggle the visibility in the FG and BG together; copy the contents of 
one interval to another; delete an interval and its contents; and specify whether the last 
volume within an interval should be maintained or turned off in the viewer when the index 
is scrolled beyond its index. Clicking on an interval outlines it in red and selects it as the active 
interval to which processing is applied. The active interval may be different from the FG or BG 
intervals. <P> The Controller also has a set of <B> animation controls </B>, which 
enable (from left to right) single frame stepping; zoom in and out (not yet working); goto first volume; play 
backward; stop; record; pause; play forward; goto last volume; continuous animation loop; 
and continous animation ping-pong (both of which are stopped with the stop button). The behavior of 
animation controls depends on the number of volumes in the current active interval. <P> 
The controller also has a scrolled <B> message box </B> into which messages are logged. 
<P> <B>New</B> lets you create and populate intervals. The Ibrowser currently reads 
Analyze, DICOM and BXH format images and will create a sequence out of either a single file, or multiple files from a 
single directory, specified using a filter. The assemble tab allows you to assign a set of volumes already loaded 
in Slicer to a new interval. 
<P> <B>Display</B> options allow you to adjust window, level and threshold for the entire sequence on 'mouse UP'. 
<P> <B>Process</B> options allow you to perform general processing operations on the sequence.  A suite of options is being developed. 
<P> <B>Inspect</B> options allows you to click on a voxel in the slice windows and view a plot of the 
corresponding voxel's intensity in all volumes in the selected interval."
    
    regsub -all "\n" $help {} help
    MainHelpApplyTags Ibrowser $help
    MainHelpBuildGUI Ibrowser

}
