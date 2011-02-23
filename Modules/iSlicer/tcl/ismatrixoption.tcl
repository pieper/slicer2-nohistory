#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ismatrixoption.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:08 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        ismatrixoption.tcl
# PROCEDURES:  
#==========================================================================auto=

#########################################################
#
if {0} { ;# comment
select a Slicer matrix
}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
#option add *ismatrixoption.background #cccccc widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class ismatrixoption] == "" } {

    itcl::class ismatrixoption {
        inherit iwidgets::Optionmenu
        
        constructor {args} {}
        destructor {}
        
        #itk_option define -command command Command {}
        #itk_option define -background background Background {}
        
        variable _allowNone
        
        method initSelection {} {}
        method allowNone {{allow "1"}} {}
        method selectedID {} {}
    }
}

# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body ismatrixoption::constructor {args} {
    #
    # Initialize the widget based on the command line options.
    #
    set _allowNone "1"
    $this initSelection
    eval itk_initialize $args
}
# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------

itcl::body ismatrixoption::initSelection {} {
    global Matrix

    $this delete 0 end
    set matrixNames ""
    foreach v $Matrix(idList) {
#        if {$v == $Matrix(idNone) } {
#            if {$_allowNone == "1"} {
#                lappend matrixNames "None"
#            }
#        } else {
            lappend matrixNames [Matrix($v,node) GetName]
#        }
    }
    if {$matrixNames != "" && ( $_allowNone == "1" || $matrixNames != "None")} {
        foreach n $matrixNames {
            $this insert end $n
        }
    }
}


itcl::body ismatrixoption::allowNone {{allow "1"}} {
    set _allowNone $allow
}


itcl::body ismatrixoption::selectedID {} {
    global Matrix

    set selIdList ""
    set selectedMatrix [$this get]
    foreach v $Matrix(idList) {
        set index [lsearch -exact $selectedMatrix [Matrix($v,node) GetName]]
        if {$index > -1} {
            lappend selIdList $v
            break;
        }
    }
    return $selIdList
}

