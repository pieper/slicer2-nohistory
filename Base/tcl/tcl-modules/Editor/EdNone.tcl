#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdNone.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:03 $
#   Version:   $Revision: 1.14 $
# 
#===============================================================================
# FILE:        EdNone.tcl
# PROCEDURES:  
#   EdNoneInit
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdNoneInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdNoneInit {} {
    global Ed

    set e EdNone
    set Ed($e,name)      "None"
    set Ed($e,initials)  "No"
    set Ed($e,desc)      "First, select an effect."
    set Ed($e,rank)      100
}

