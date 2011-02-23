#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ismvolumeselector.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:08 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        ismvolumeselector.tcl
# PROCEDURES:  
#==========================================================================auto=

#########################################################
#
if {0} { ;# comment
select multiple Slicer volumes
}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
#option add *ismvolumeselector.background #cccccc widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class ismvolumeselector] == "" } {

    itcl::class ismvolumeselector {
      inherit iwidgets::Disjointlistbox

      constructor {args} {}
      destructor {}

      #itk_option define -command command Command {}
      #itk_option define -background background Background {}

      variable _numScalars

      method initSelection {} {}
      method numScalars {{num ""}} {}
      method selectedIDs {} {}
    }
}

# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body ismvolumeselector::constructor {args} {
    set _numScalars ""
    $this initSelection

    #
    # Initialize the widget based on the command line options.
    #
    eval itk_initialize $args
}
# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------

itcl::body ismvolumeselector::initSelection {} {
    global Volume

    set volumeNames ""
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone)} {
            if {$_numScalars == "" || [Volume($v,node) GetNumScalars] == $_numScalars} {
                lappend volumeNames [Volume($v,node) GetName]
            }
        } 
    }
    if {$volumeNames != "" || $volumeNames != "None"} {
        $this setlhs $volumeNames
    }
}


itcl::body ismvolumeselector::numScalars {{num ""}} {
    set _numScalars $num
}


itcl::body ismvolumeselector::selectedIDs {} {
    global Volume

    set selIdList ""
    set volumeNames [$this getrhs]
    foreach v $Volume(idList) {
        set index [lsearch -exact $volumeNames [Volume($v,node) GetName]]
        if {$index > -1} {
            lappend selIdList $v 
        }
    }
    return $selIdList
}

