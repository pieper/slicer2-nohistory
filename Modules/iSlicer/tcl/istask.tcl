#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: istask.tcl,v $
#   Date:      $Date: 2006/03/15 00:17:50 $
#   Version:   $Revision: 1.7 $
# 
#===============================================================================
# FILE:        istask.tcl
# PROCEDURES:  
#   istask_taskcb
#   istask_demo
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

#########################################################
#
if {0} { ;# comment

istask - a widget for managing a background task with a 
configurable delay between invokations and an on/off button

# TODO : 
    - make it look better (maybe some bitmaps?)
}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
option add *istask.taskcommand "" widgetDefault
option add *istask.oncommand "" widgetDefault
option add *istask.offcommand "" widgetDefault
option add *istask.taskdelay 30 widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class istask] == "" } {

    itcl::class istask {
        inherit iwidgets::Labeledwidget

        constructor {args} {}
        destructor {}

        #
        # itk_options for widget options that may need to be
        # inherited or composed as part of other widgets
        # or become part of the option database
        #
        itk_option define -taskcommand taskcommand Taskcommand {}
        itk_option define -oncommand oncommand Oncommand {}
        itk_option define -offcommand offcommand Offcommand {}
        itk_option define -taskdelay taskdelay Taskdelay 30

        variable _w ""
        variable _onoffbutton ""
        variable _mode "off"
        variable _taskafter ""

        method w {} {return $_w}
        method onoffbutton {} {return $_onoffbutton}
        method on {} {}
        method off {} {}
        method toggle {} {}
        method istask_taskcb {} {}

        proc stopall {} {}
    }
}

#-------------------------------------------------------------------------------
# .PROC istask_taskcb
# A placeholder so the task callback isn't undefined if the 
# class instance is destroyed before the after completes.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc istask_taskcb {} {

}

# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body istask::constructor {args} {
    component hull configure -borderwidth 0

    set _w [frame $itk_interior.f]
    pack $_w -fill both -expand true

    set _onoffbutton [button $_w.oob -text "Start" -command "$this on"]
    pack $_onoffbutton -side left 
    
    eval itk_initialize $args
}


itcl::body istask::destructor {} {
    catch "after cancel $_taskafter"
}

itcl::body istask::on {} {
    $_onoffbutton configure -text "Running..." -command "$this off" -relief sunken
    if { $_mode == "off" } {
        eval $itk_option(-oncommand)
    }
    set _mode "on"
    $this istask_taskcb
}

itcl::body istask::off {} {
    $_onoffbutton configure -text "Start" -command "$this on" -relief raised

    set oldmode $_mode
    set _mode "off"
    $this istask_taskcb

    if { $oldmode == "on" } {
        eval $itk_option(-offcommand)
    }
}

itcl::body istask::toggle {} {
    if { $_mode == "off" } {
        $this on
    } else {
        $this off
    }
}

itcl::body istask::istask_taskcb {} {

    switch $_mode {
        "off" {
            if {$_taskafter != ""} {
                after cancel $_taskafter
            }
            set _taskafter ""
        }
        "on" {
            if {$itk_option(-taskcommand) != ""} {
                eval $itk_option(-taskcommand)
            }
            set _taskafter [after $itk_option(-taskdelay) "$this istask_taskcb"]
        }
    }
}

itcl::body istask::stopall {} {
    foreach t [itcl::find objects -class istask] {
        catch "$t off" 
    }
}

#-------------------------------------------------------------------------------
# .PROC istask_demo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc istask_demo {} {
    global istaskcounter

    set istaskcounter 0

    catch "destroy .istaskdemo"
    toplevel .istaskdemo
    wm title .istaskdemo "istaskdemo"

    pack [istask .istaskdemo.task1 \
        -taskcommand ".istaskdemo.task1 configure -labeltext \[clock format \[clock seconds\]\]" \
        -taskdelay 30 ]

    pack [istask .istaskdemo.task2 \
        -taskcommand {
            global istaskcounter
            .istaskdemo.task2 configure -labeltext $istaskcounter
            incr istaskcounter} \
        -taskdelay 300 ]

    pack [button .istaskdemo.stopall -text stopall -command istask::stopall]
}
