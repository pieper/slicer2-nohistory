#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: istransformoption.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:08 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        istransformoption.tcl
# PROCEDURES:  
#==========================================================================auto=

#########################################################
#
if {0} { ;# comment
select a Slicer transform
}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
#option add *istransformoption.background #cccccc widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class istransformoption] == "" } {

    itcl::class istransformoption {
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
itcl::body istransformoption::constructor {args} {
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

itcl::body istransformoption::initSelection {} {
    global Transform

    $this delete 0 end
    set transformNames ""
    foreach v $Transform(idList) {
#        if {$v == $Transform(idNone) } {
#            if {$_allowNone == "1"} {
#                lappend transformNames "None"
#            }
#        } else {
            lappend transformNames [Transform($v,node) GetName]
#        }

    }
    if {$transformNames != "" && ( $_allowNone == "1" || $transformNames != "None")} {
        foreach n $transformNames {
            $this insert end $n
        }
    }
}


itcl::body istransformoption::allowNone {{allow "1"}} {
    set _allowNone $allow
}


itcl::body istransformoption::selectedID {} {
    global Transform

    set selIdList ""
    set selectedTransform [$this get]
    foreach v $Transform(idList) {
        set index [lsearch -exact $selectedTransform [Transform($v,node) GetName]]
        if {$index > -1} {
            lappend selIdList $v
            break;
        }
    }
    return $selIdList
}

