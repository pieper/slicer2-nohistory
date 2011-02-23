#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: isbutton.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:07 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        isbutton.tcl
# PROCEDURES:  
#   isbutton_demo
#==========================================================================auto=

#########################################################
#
if {0} { ;# comment

isbutton - an example incr widget that uses vtk
to render a sphere to implement the button's 3D 
animated drawing.  

The current demo shows a couple things that
couldn't easily be done using pre-rendered
images - e.g. having the light source follow
the mouse while over the sphere.
The method can be extended to make
general 3D animations inside a tcl widget.

Interesting things:

* most the tk widget functionality is inherited from the
incr widget "labeledwidget" class.  This class overrides
the background configuration option to also set the 3D
renderer background

* the vtk class instances are automatically named based
on the name of this widget instance.  They are also automatically
cleaned up by the destructor.

}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
option add *isbutton.background #cccccc widgetDefault
option add *isbutton.geomforeground #5050aa widgetDefault
option add *isbutton.geom sphere widgetDefault
option add *isbutton.spin off widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class isbutton] == "" } {

    itcl::class isbutton {
      inherit iwidgets::Labeledwidget

      constructor {args} {}
      destructor {}

      itk_option define -command command Command {}
      itk_option define -background background Background {}
      itk_option define -geomforeground geomforeground Geomforeground {}
      itk_option define -geom geom Geom {}
      itk_option define -spin spin Spin {}

      variable _ren
      variable _source
      variable _mapper
      variable _actor
      variable _light
      variable _spinafter ""

      method invoke {} {}
      method spin {cmd} {}
      method expose {} {}
      method highlight {args} {}
      method draglight {args} {}
      method actor {} {return $_actor}
      method rw {} {return [$itk_interior.tkrw GetRenderWindow]}

    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body isbutton::constructor {args} {
    component hull configure -borderwidth 0
    
    itk_component add tkrw {
    vtkTkRenderWidget $itk_interior.tkrw -width 70 -height 70
    } {
        # placeholder for configuration options...
    }

    pack $itk_interior.tkrw -expand true -fill both
    bind $itk_interior.tkrw <Expose> "$this expose"
    bind $itk_interior.tkrw <Motion> "$this draglight %x %y"
    bind $itk_interior <Enter> "$this highlight on"
    bind $itk_interior <Leave> "$this highlight off"

    # make a unique name associated with this object
    set name [namespace tail $this]

    set _ren ren_$name
    set _source source_$name
    set _mapper mapper_$name
    set _actor actor_$name
    set _light light_$name

    vtkRenderer $_ren
    [$this rw] AddRenderer $_ren

    vtkSphereSource $_source
      $_source SetThetaResolution 50
      $_source SetPhiResolution 50

    vtkPolyDataMapper $_mapper
      $_mapper SetInput [$_source GetOutput]

    vtkActor $_actor
      $_actor SetMapper $_mapper

    $_ren AddActor $_actor

    vtkLight $_light
      $_light SetFocalPoint 0 0 0 
      $_light SetPosition 3 3 10
      $_light SetColor .5 .5 .5
    $_ren AddLight $_light

    #
    # Initialize the widget based on the command line options.
    #
    eval itk_initialize $args
}


itcl::body isbutton::destructor {} {
    catch "after cancel $_spinafter"
    destroy $itk_interior.tkrw 
    $_ren Delete
    $_source Delete
    $_mapper Delete
    $_actor Delete
    $_light Delete
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# OPTION: -command
#
# DESCRIPTION: Invoke the given command to simulate the Tk button's -command
#   option.  The command is invoked on <ButtonRelease-1> events only or by
#   direct calls to the public invoke() method.
#-------------------------------------------------------------------------------
itcl::configbody isbutton::command {

  if {$itk_option(-command) == ""} {
    return
  }

  # Only create the tag binding if the button is operable.
  if {$itk_option(-state) == "normal"} {
    bind $this-commandtag <ButtonRelease-1> [itcl::code $this invoke]
  }

  # Associate the tag with each component if it's not already done.
  if {[lsearch [bindtags $itk_interior] $this-commandtag] == -1} {
    foreach component [component] {
      bindtags [component $component] \
        [linsert [bindtags [component $component]] end $this-commandtag]
    }
  }
}

#-------------------------------------------------------------------------------
# OPTION: -background
#
# DESCRIPTION: 
#-------------------------------------------------------------------------------
itcl::configbody isbutton::background {

  if {$itk_option(-background) == ""} {
    return
  }

  scan $itk_option(-background) "#%02x%02x%02x" r g b

  $_ren SetBackground [expr ($r/255.)] [expr ($g/255.)] [expr ($b/255.)]
  expose

}

#-------------------------------------------------------------------------------
# OPTION: -geomforeground
#
# DESCRIPTION: 
#-------------------------------------------------------------------------------
itcl::configbody isbutton::geomforeground {

  if {$itk_option(-geomforeground) == ""} {
    return
  }

  scan $itk_option(-geomforeground) "#%02x%02x%02x" r g b

  [$_actor GetProperty] SetColor [expr ($r/255.)] [expr ($g/255.)] [expr ($b/255.)]
  expose

}

#-------------------------------------------------------------------------------
# OPTION: -geom
#
# DESCRIPTION: 
#-------------------------------------------------------------------------------
itcl::configbody isbutton::geom {

  if {$itk_option(-geom) == ""} {
    return
  }

  if { [info command $_source] != "" } {
      $_source Delete
  }

  switch -glob $itk_option(-geom) {
    "sphere" {
      vtkSphereSource $_source
        $_source SetThetaResolution 50
        $_source SetPhiResolution 50
      $_actor SetScale 1 1 1
        $_mapper SetInput [$_source GetOutput]
    }
    "cone" {
      vtkConeSource $_source
        $_source SetResolution 50
      $_actor SetScale 1 1 1
        $_mapper SetInput [$_source GetOutput]
    }
    *.vtk {
      vtkPolyDataReader $_source
      $_source SetFileName $itk_option(-geom)
        $_mapper SetInput [$_source GetOutput]
      $_mapper Update
      set s [$_actor GetXRange] 
      set ss [expr 1. / ([lindex $s 1] - [lindex $s 0])]
      $_actor SetScale $ss $ss $ss
      set c [$_actor GetCenter]
      $_actor SetPosition \
          [expr -1. * [lindex $c 0]] \
          [expr -1. * [lindex $c 1]] \
          [expr -1. * [lindex $c 2]] 
      eval $_actor SetOrigin  0 0 0
    }
    default {
      vtkTextSource $_source
      $_source SetText $itk_option(-geom)
        $_mapper SetInput [$_source GetOutput]
      $_mapper Update
      set s [$_actor GetXRange] 
      set ss [expr 1. / ([lindex $s 1] - [lindex $s 0])]
      $_actor SetScale $ss $ss $ss
      set c [$_actor GetCenter]
      $_actor SetPosition \
          [expr -1. * [lindex $c 0]] \
          [expr -1. * [lindex $c 1]] \
          [expr -1. * [lindex $c 2]] 
      eval $_actor SetOrigin  0 0 0
    }
   }


  expose

}

itcl::configbody isbutton::spin {

    switch $itk_option(-spin) {
        "off" {
            catch "after cancel $_spinafter"
        }
        "on" {
            catch "after cancel $_spinafter"
            set _spinafter [after 100 "$this spin cb"]
        }
    }
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------

itcl::body isbutton::invoke {} {
    
    set oscale [lindex [$_actor GetScale] 0]
    set nscale [expr 1.2 * $oscale]
    for {set i 0} {$i < 4} {incr i} {
        $_actor SetScale $nscale $nscale $nscale
        [$_actor GetProperty] SetAmbient 1
        expose
        after 50
        $_actor SetScale $oscale $oscale $oscale
        [$_actor GetProperty] SetAmbient 0
        expose
        after 50
    }
    eval $itk_option(-command)
}

itcl::body isbutton::spin {cmd} {
    
    switch $cmd {
        "cb" {
            $_actor RotateY 10
            expose
            set _spinafter [after 100 "$this spin cb"]
        }
        "toggle" {
            if {[$this cget -spin] == "on"} {
                $this configure -spin off
            } else {
                $this configure -spin on
            }
        }
    }
}


itcl::body isbutton::expose {} {
    $itk_interior.tkrw Render
}

itcl::body isbutton::highlight {args} {

    if {$args == "on"} {
        $_light SetColor 1 1 1
    } else {
        $_light SetColor .5 .5 .5
    }
    expose
}

itcl::body isbutton::draglight {x y} {

    set x [expr $x - 33.]
    set y [expr (100. - $y) - 66.]

    $_light SetPosition [expr $x/10.] [expr $y/10.] 1
    expose
}

#-------------------------------------------------------------------------------
# .PROC isbutton_demo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc isbutton_demo { {n 0} } {
    global BUTTONS env

    set datadir $env(SLICER_HOME)/Modules/iSlicer/data
    #
    # create a toplevel window
    #
    set w .isbuttondemo$n
    catch "destroy $w"
    toplevel $w
    wm title $w "isbutton demo"
    wm geometry $w 160x370+50+20

    #
    # put everything in a frame with automatic scrollbars
    #
    iwidgets::scrolledframe $w.f \
        -hscrollmode dynamic -vscrollmode dynamic \
        -background #ffffff
    pack $w.f -expand true -fill both
    

    set buttonlist [list \
        red #ff0000 cone   \
        green #00ff00 sphere   \
        blue #0000ff $datadir/vtk.vtk \
        usa #a0a0ff $datadir/usa.vtk \
        text #a0f0ff "text"  \
        brain #a0a0ff $datadir/brainImageSmooth.vtk \
        fran #a0a0ff $datadir/fran_cut.vtk \
    ]
    #
    # create buttons using the new widget
    #
    set cs [$w.f childsite]
    foreach {label color geom} $buttonlist {
        set BUTTONS($label) $cs.b$label
        isbutton $BUTTONS($label) \
            -labeltext $label -labelpos e \
            -geomforeground $color \
            -geom $geom \
            -background #ffffff \
            -command "wm title $w $label; $BUTTONS($label) spin toggle"
        pack $BUTTONS($label) -side top -anchor w
    }
}
