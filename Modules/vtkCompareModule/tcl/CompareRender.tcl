#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareRender.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:23 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareRender.tcl
# PROCEDURES:  
#   CompareRenderSlice int
#   CompareRenderActive
#   CompareRenderSlices
#   CompareRenderMosaik
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC CompareRenderSlice
# Renders a particular slice
#
# .ARGS
# s int the slice id
# .END
#-------------------------------------------------------------------------------
proc CompareRenderSlice {s {scale ""}} {
    global CompareSlice

    if { [info command slCompare${s}Win] != "" } {
        slCompare${s}Win Render
        CompareRenderMosaik
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareRenderActive
# Renders the slice set as active in CompareSlice framework
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareRenderActive {{scale ""}} {
    global CompareSlice

    CompareRenderSlice $CompareSlice(activeID)
}

#-------------------------------------------------------------------------------
# .PROC CompareRenderSlices
# Renders every slice in the CompareSlice framework
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareRenderSlices {{scale ""}} {
    global CompareSlice

    foreach s $CompareSlice(idList) {
        CompareRenderSlice $s
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareRenderMosaik
# Renders the mosaik
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareRenderMosaik {{scale ""}} {
    global CompareMosaik

    set s $CompareMosaik(mosaikIndex)
    if { [info command slCompare${s}Win] != "" } {
        slCompare${s}Win Render
    }
}
