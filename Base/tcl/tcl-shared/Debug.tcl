#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Debug.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:04 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        Debug.tcl
# PROCEDURES:  
#   DebugInit
#==========================================================================auto=
# Debug.tcl
# 10/16/98 Peter C. Everett peverett@bwh.harvard.edu: Created

#-------------------------------------------------------------------------------
# PROCEDURES in order
#-------------------------------------------------------------------------------
# DebugInit
# DebugMsg

#-------------------------------------------------------------------------------
# .PROC DebugInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DebugInit {} {
    global Debug
set Debug(cnt) 0
    # Debug(types) is read from the slicer.init file at bootup
    }

#-------------------------------------------------------------------------------
# DebugMsg
# Prints msg if type is contained in Debug(types) list.
# If Debug(types) contains "all", then prints all messages.
#-------------------------------------------------------------------------------
proc DebugMsg { msg {type all} } {
#    global Debug

#    if {[lsearch $Debug(types) "all"] > -1 || 
#        [lsearch $Debug(types) $type] > -1} {
##        puts $msg
#        }
    }
