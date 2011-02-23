#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: isrange.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:08 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        isrange.tcl
# PROCEDURES:  
#==========================================================================auto=

package require Iwidgets


#########################################################
#
if {0} { ;# comment

isrange - a class for interacting with a min/max range

note: this is a widget

# TODO : 

}
#
#########################################################


#
# Default resources
# - sets the default colors for the widget components
#
option add *isrange.title "Range" widgetDefault
option add *isrange.command "" widgetDefault
option add *isrange.height 20 widgetDefault
# TODO: option add *isrange.minvariable "" widgetDefault
# TODO: option add *isrange.maxvariable "" widgetDefault
# TODO: option add *isrange.fromvariable "" widgetDefault
# TODO: option add *isrange.tovariable "" widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class isrange] == "" } {

    itcl::class isrange {
      inherit iwidgets::Labeledwidget

      constructor {args} {}
      destructor {}

      #
      # itk_options for widget options that may need to be
      # inherited or composed as part of other widgets
      # or become part of the option database
      #
      itk_option define -title title Title {}
      itk_option define -command command Command {}
      itk_option define -height height Height {}
      # TODO: itk_option define -tovariable tovariable Tovariable {}
      # TODO: itk_option define -fromvariable fromvariable Fromvariable {}
      # TODO: itk_option define -minvariable minvariable Minvariable {}
      # TODO: itk_option define -maxvariable maxvariable Maxvariable {}

      ### variables
      variable _name
      variable _canvas
      variable _bar 1

      # drag state
      variable _start_fx
      variable _start_fmin
      variable _start_fmax
      variable _mode

      # min/max in [0-1] space
      variable _fmin 0.25
      variable _fmax 0.75

      # full range - these variables are traced
      variable _from 0
      variable _to 100
      variable _fullmin 25
      variable _fullmax 75
      variable _in_trace_callback 0


      ### methods

      method tracing { onoff } {}
      method bindings {} {}
      method dragcb { state x y } {}
      method validate_set {min max} {}
      method validate_set_range {min max} {}
      method update_canvas {} {}
      method update_variables {which args} {}
      method set_bounds {f t} {set _from $f; set _to $t}
      method get_bounds {} {return "$_from $_to"}
      method range {} {}
      method frange {} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body isrange::constructor {args} {

    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name

    set cs [$this childsite]
    #
    # make a canvas
    #
    set _canvas $cs.canvas
    canvas $_canvas -background white -height 20 -width 75
    $this bindings

    #
    # pack em in a row
    #
    pack [iwidgets::spinfloat $cs.from -step 1 -width 5 -labeltext From -labelpos nw -textvariable [itcl::scope _from]] -side left
    pack [iwidgets::spinfloat $cs.min -step 1 -width 5 -labeltext Min -labelpos nw -textvariable [itcl::scope _fullmin]] -side left
    pack $_canvas -fill x -expand true -side left
    pack [iwidgets::spinfloat $cs.max -step 1 -width 5 -labeltext Max -labelpos nw -textvariable [itcl::scope _fullmax]] -side left
    pack [iwidgets::spinfloat $cs.to -step 1 -width 5 -labeltext To -labelpos nw -textvariable [itcl::scope _to]] -side left

    set _from 0
    set _to 100
    set _fullmin 25
    set _fullmax 75
    set _fmin .25
    set _fmax .75

    $this tracing on

    #
    # Initialize the widget based on the command line options.
    #
    eval itk_initialize $args
}


itcl::body isrange::destructor {} {
    $this tracing off
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

itcl::configbody isrange::command {
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------

itcl::body isrange::tracing { onoff } {
    if { $onoff == "on" } {
        trace variable [itcl::scope _from] w "$this update_variables from" 
        trace variable [itcl::scope _to] w "$this update_variables to" 
        trace variable [itcl::scope _fullmin] w "$this update_variables min" 
        trace variable [itcl::scope _fullmax] w "$this update_variables max" 
    } else {
        trace vdelete [itcl::scope _from] w "$this update_variables from" 
        trace vdelete [itcl::scope _to] w "$this update_variables to" 
        trace vdelete [itcl::scope _fullmin] w "$this update_variables min" 
        trace vdelete [itcl::scope _fullmax] w "$this update_variables max" 
    }
}

itcl::body isrange::bindings { } {
    
    catch "bind $_canvas <ButtonPress-1> \"\""
    catch "bind $_canvas <B1-Motion> \"\""
    catch "bind $_canvas <Expose> \"\""

    bind $_canvas <ButtonPress-1> "$this dragcb start %x %y"
    bind $_canvas <B1-Motion> "$this dragcb drag %x %y"
    bind $_canvas <Expose> "$this update_canvas"
}

itcl::body isrange::dragcb {state x y} {

    set width [winfo width $_canvas]
    set fx [expr $x / ($width * 1.0)]

    switch -- $state {
        "start" {
            set _start_fx $fx
            set _start_fmin $_fmin
            set _start_fmax $_fmax
            if { $fx < $_fmax && $fx > $_fmin } {
                set _mode "range"
            } 
            if { $fx < $_fmin } {
                set _mode "min"
            } 
            if { $fx > $_fmax } {
                set _mode "max"
            } 
        }
        "drag" {
            set deltax [expr $fx - $_start_fx]
            switch -- $_mode {
                "range" {
                    set fmin [expr $_start_fmin + $deltax]
                    set fmax [expr $_start_fmax + $deltax]
                    validate_set_range $fmin $fmax
                }
                "min" {
                    set fmin [expr $_start_fmin + $deltax]
                    validate_set $fmin $_fmax
                }
                "max" {
                    set fmax [expr $_start_fmax + $deltax]
                    validate_set $_fmin $fmax
                }
            }
            $this update_canvas

            if { $itk_option(-command) != "" } {
                uplevel #0 $itk_option(-command)
            }
        }
    }
}

itcl::body isrange::update_canvas {} {

    set w [winfo width $_canvas]
    set h [winfo height $_canvas]

    set cmin [expr $_fmin * $w]
    set cmax [expr $_fmax * $w]

    catch "$_canvas delete $_bar"
    set _bar [$_canvas create rectangle $cmin 0 $cmax $h -fill black]
}

#
# set the slider based on the values of the spinfloats
#
itcl::body isrange::update_variables {which args} {

    if { $_in_trace_callback == 1 } {
        return
    }
    set _in_trace_callback 1

    if { $_from == "" || $_to == "" || $_fullmin == "" || $_fullmax == "" } {
        set _in_trace_callback 0
        return
    }


    set ret [catch {

        set fullrange [expr 1.0 * ($_to - $_from)]

        switch -- $which {
            "from" -
            "to" {
                # adjust entries to reflect slider
                set fullmin [expr $_fmin * $fullrange]
                set fullmax [expr $_fmax * $fullrange]
                set _fmin [expr $fullmin / $fullrange]
                set _fmax [expr $fullmax / $fullrange]
                set _fullmin $fullmin
                set _fullmax $fullmax
            }
            "min" -
            "max" {
                # adjust slider to reflect entries
                set _fmin [expr $_fullmin / $fullrange]
                set _fmax [expr $_fullmax / $fullrange]
            }
        }

        $this update_canvas

        if { $itk_option(-command) != "" } {
            uplevel #0 $itk_option(-command)
        }
    } res]

    if { $ret } {
        puts stderr $res
    }

    set _in_trace_callback 0
}

itcl::body isrange::validate_set_range {min max} {
    set range [expr $_fmax - $_fmin]
    if { $min < 0.0 } {
        set _fmin 0.0
        set _fmax $range
        $this range
        return
    }
    if { $max > 1.0 } {
        set _fmax 1.0
        set _fmin [expr $_fmax - $range]
        $this range
        return
    }
    if { $max < $min } {
        set max $min
    }
    set _fmin $min
    set _fmax $max
    $this range
}

itcl::body isrange::validate_set {min max} {

    if { $min < 0.0 } {
        set min 0.0
    }
    if { $max > 1.0 } {
        set max 1.0
    }
    if { $max < $min } {
        set max $min
    }
    set _fmin $min
    set _fmax $max
    $this range
}

itcl::body isrange::range {} {
    set fullrange [expr $_to - $_from]
    # save the state since the traced variable will reset the global
    set fullmin [expr $_from + $fullrange * $_fmin] 
    set fullmax [expr $_from + $fullrange * $_fmax]
    $this tracing off
    set _fullmin $fullmin
    set _fullmax $fullmax
    $this tracing on
    return "$_fullmin $_fullmax"
}

itcl::body isrange::frange {} {
    return "$_fmin $_fmax"
}

