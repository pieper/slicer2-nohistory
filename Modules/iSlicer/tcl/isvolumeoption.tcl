#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: isvolumeoption.tcl,v $
#   Date:      $Date: 2006/07/07 17:59:00 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        isvolumeoption.tcl
# PROCEDURES:  
#==========================================================================auto=

#########################################################
#
if {0} { ;# comment
select a Slicer volume
}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
#option add *isvolumeoption.background #cccccc widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class isvolumeoption] == "" } {

    itcl::class isvolumeoption {
        inherit iwidgets::Optionmenu
        
        constructor {args} {}
        destructor {}
        
        #itk_option define -command command Command {}
        #itk_option define -background background Background {}
        
        variable _numScalars
        variable _allowNone
        
        method initSelection {} {}
        method numScalars {{num ""}} {}
        method allowNone {{allow "1"}} {}
        method selectedID {} {}
        method selectByID {id} {}
    }
}

# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body isvolumeoption::constructor {args} {
    #
    # Initialize the widget based on the command line options.
    #
    set _numScalars ""
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

itcl::body isvolumeoption::initSelection {} {
    global Volume
    
    set selected [$this selectedID]

    $this delete 0 end
    set volumeNames ""
    foreach v $Volume(idList) {
        if {$v == $Volume(idNone) } {
            if {$_allowNone == "1"} {
                lappend volumeNames "None"
            }
        } else {
            if {$_numScalars == "" || ([Volume($v,node) GetNumScalars] == $_numScalars) } {
                lappend volumeNames [Volume($v,node) GetName]
            }
        }
    }
    if {$volumeNames != "" && ( $_allowNone == "1" || $volumeNames != "None")} {
        foreach n $volumeNames {
            $this insert end $n
        }
    }
    foreach v $selected {
        $this selectByID $v
    }
}


itcl::body isvolumeoption::numScalars {{num ""}} {
    set _numScalars $num
}

itcl::body isvolumeoption::allowNone {{allow "1"}} {
    set _allowNone $allow
}


itcl::body isvolumeoption::selectedID {} {
    global Volume

    set selIdList ""
    set selectedVolume [$this get]
    foreach v $Volume(idList) {
        set index [lsearch -exact $selectedVolume [Volume($v,node) GetName]]
        if {$index > -1} {
            lappend selIdList $v
            break;
        }
    }
    return $selIdList
}

itcl::body isvolumeoption::selectByID {id} {
    global Volume

    set selected ""

    set volNames [$this get 0 end]
    set i 0
    foreach vol $volNames {
    if { $id == [MainVolumesGetVolumeByName $vol] } {
        $this select $i
        return $i
    }
    incr i
    }

    return -1
}
