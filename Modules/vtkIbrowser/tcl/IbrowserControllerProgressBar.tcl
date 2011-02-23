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
# FILE:        IbrowserControllerProgressBar.tcl
# PROCEDURES:  
#   IbrowserRaiseProgressBar
#   IbrowserLowerProgressBar
#==========================================================================auto=

proc IbrowserUpdateProgressBar  { percentdone fillchar } {

    #--- label width is 20 characters wide, as
    #--- specified in IbrowseControllerAnimate.tcl
    #--- in proc IbrowserMakeAnimationMenu.
    #--- So 20 chars is the max we can display
    #--- convert the percentdone to a fraction of
    #--- 20 chars: percentdone = numchars/20
    set numchars [ expr $percentdone * 20 ]
    set numchars [ expr int ( $numchars ) ]
    
    #--- now assemble 'numchars' of whatever the
    #--- progress bar character will be.
    set progressStr [string repeat $fillchar $numchars ]
    set ::IbrowserController(ProgressBarTxt) $progressStr 
}



#-------------------------------------------------------------------------------
# .PROC IbrowserRaiseProgressBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRaiseProgressBar { } {

    #--- makes progress bar visible by raising its groove
    $::IbrowserController(ProgressBar) configure -anchor nw \
        -foreground #111111 -relief groove
}



#-------------------------------------------------------------------------------
# .PROC IbrowserLowerProgressBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserLowerProgressBar { } {

    #--- makes progress bar invisible by blending into background
    $::IbrowserController(ProgressBar) configure -foreground #FFFFFF -relief flat
    set ::IbrowserController(ProgressBarTxt) ""
}

