#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: isframes.tcl,v $
#   Date:      $Date: 2006/04/18 22:02:43 $
#   Version:   $Revision: 1.13 $
# 
#===============================================================================
# FILE:        isframes.tcl
# PROCEDURES:  
#   isframes_demo
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

#########################################################
#
if {0} { ;# comment

isframes - a widget for looking at a sequence of frames

# TODO : 
}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
option add *isframes.frame 0 widgetDefault
option add *isframes.start 0 widgetDefault
option add *isframes.end 0 widgetDefault
option add *isframes.skip 1 widgetDefault
option add *isframes.filepattern "" widgetDefault
option add *isframes.filetype "" widgetDefault
option add *isframes.dumpcommand "" widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class isframes] == "" } {

    itcl::class isframes {
      inherit iwidgets::Labeledwidget

      constructor {args} {}
      destructor {}

      #
      # itk_options for widget options that may need to be
      # inherited or composed as part of other widgets
      # or become part of the option database
      #
      itk_option define -filepattern filepattern Filepattern ""
      itk_option define -filetype filetype Filetype ""
      itk_option define -dumpcommand dumpcommand Dumpcommand ""
      itk_option define -frame frame Frame 0
      itk_option define -start start Start 0
      itk_option define -end end End 0
      itk_option define -skip skip Skip 1

      # widgets for the control area
      variable _task
      variable _patternentry
      variable _patternentry_value
      variable _startentry
      variable _startentry_value
      variable _endentry
      variable _endentry_value
      variable _slider

      # state variables
      variable _first
      variable _last

      # a scrolled text for displaying ascii content
      variable _text
      # vtk objects in the frame render
      variable _name
      variable _image
      variable _tkrw
      variable _ren
      variable _mapper
      variable _actor

      # methods
      method expose {}   {}
      method task  {}    {return $_task}
      method actor  {}   {return $_actor}
      method mapper {}   {return $_mapper}
      method ren    {}   {return $_ren}
      method tkrw   {}   {return $_tkrw}
      method rw     {}   {return [$_tkrw GetRenderWindow]}

      method middle     {}   {}
      method next     {}   {}
      method entrycallback {}   {}
      
      method pre_destroy {} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body isframes::constructor {args} {
    component hull configure -borderwidth 0


    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name

    #
    # build the controls
    # - TODO - split this into separate class as it gets more complex
    #

    set _task $itk_interior.task
    istask $_task -taskcommand "$this next; update"
    pack $_task -side top -expand false -fill x

    set _patternentry $itk_interior.pentry
    iwidgets::entryfield $_patternentry \
        -labeltext "Pattern: " -textvariable [itcl::scope _patternentry_value] \
        -command "$this entrycallback"
    set _startentry $itk_interior.sentry
    iwidgets::entryfield $_startentry \
        -labeltext "Start: " -textvariable [itcl::scope _startentry_value] \
        -command "$this entrycallback"
    set _endentry $itk_interior.eentry
    iwidgets::entryfield $_endentry \
        -labeltext "End: " -textvariable [itcl::scope _endentry_value] \
        -command "$this entrycallback"
    pack $_patternentry $_startentry $_endentry -side top -expand false -fill x

    set _slider $itk_interior.slider
    scale $_slider -orient horizontal -command "$this configure -frame "
    pack $_slider -side top -expand false -fill x

    
    #
    # build the vtk image viewer
    #
    set _image $itk_interior.sframe
    iwidgets::scrolledframe $_image \
        -hscrollmode dynamic -vscrollmode dynamic 
    pack $_image -fill both -expand true
    set cs [$_image childsite]
    set _tkrw $cs.tkrw
    vtkTkRenderWidget $_tkrw -width 256 -height 256

    pack $_tkrw -expand true -fill both
    bind $_tkrw <Expose> "$this expose"

    set _ren ::ren_$_name
    set _mapper ::mapper_$_name
    set _actor ::actor_$_name
    catch "$_ren Delete"
    catch "$_mapper Delete"
    catch "$_actor Delete"

    vtkRenderer $_ren
    [$this rw] AddRenderer $_ren
    vtkImageMapper $_mapper
    $_mapper SetColorWindow 255
    $_mapper SetColorLevel 128
    vtkActor2D $_actor
    $_actor SetMapper $_mapper
    $_ren AddActor2D $_actor

    #
    # a scrolled text for ascii content for filetype "text"
    #
    set _text $itk_interior.text
    iwidgets::scrolledtext $_text\
        -hscrollmode dynamic -vscrollmode dynamic 

    #
    # Initialize the widget based on the command line options.
    #
    eval itk_initialize $args
}


itcl::body isframes::destructor {} {
    destroy $_tkrw 
    if { $_ren != "" } {
        $_ren Delete
    }
    if { $_mapper != "" } {
        $_mapper Delete
    }
    if { $_actor != "" } {
        $_actor Delete
    }
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# OPTION: -filepattern
#
# DESCRIPTION: e.g. c:/tmp/frames-%0d.jpg
#-------------------------------------------------------------------------------
itcl::configbody isframes::filepattern {
    set _patternentry_value $itk_option(-filepattern)
    if { [string first "*" $itk_option(-filepattern)] != -1 } {
        set files [glob -nocomplain $itk_option(-filepattern)]
        set numfiles [llength $files]
        if { $numfiles > 0 } {
            $this configure -start 0
            $this configure -end [expr $numfiles - 1]
        }
    }
}

#-------------------------------------------------------------------------------
# OPTION: -start , -end, -skip
#
# DESCRIPTION: first and last frames of movie, used to adjust slider
#-------------------------------------------------------------------------------
itcl::configbody isframes::start {
    $_slider configure -from $itk_option(-start)
    if { $_startentry_value != $itk_option(-start) } {
        set _startentry_value $itk_option(-start)
    }
}
itcl::configbody isframes::end {
    $_slider configure -to $itk_option(-end)
    if { $_endentry_value != $itk_option(-end) } {
        set _endentry_value $itk_option(-end)
    }
}
itcl::configbody isframes::skip {
    $_slider configure -resolution $itk_option(-skip)
}

#-------------------------------------------------------------------------------
# OPTION: -frame
#
# DESCRIPTION: frame number for the current sequence
#-------------------------------------------------------------------------------
itcl::configbody isframes::frame {

    if { $itk_option(-frame) == "" || $itk_option(-filepattern) == "" } {
        return
    }

    if { [$_slider get] != $itk_option(-frame) } {
        $_slider set $itk_option(-frame)
    }


    if { [string first "*" $itk_option(-filepattern)] != -1 } {
        set files [lsort -dictionary [glob -nocomplain $itk_option(-filepattern)]]
        set filename [lindex $files $itk_option(-frame)]
    } else {
        set filename [format $itk_option(-filepattern) $itk_option(-frame)]
    }
    if {$filename == ""} {
        puts "isframes: no file found for frame $itk_option(-frame) with pattern $itk_option(-filepattern)"
        return
    }

    set filetype $itk_option(-filetype)

    if { $filetype == "text" } {
        pack forget $_image
        pack $_text -fill both -expand true

        if { [file isdirectory $filename] } {
            set contents "$filename is a directory"
        } else {
            set ret [ catch {
                if { $itk_option(-dumpcommand) != "" } {
                    set fp [open "| $itk_option(-dumpcommand) $filename" "r"]
                } else {
                    set fp [open $filename "r"]
                }
                set contents [read $fp]
                close $fp
            } res ]
            
            if { $ret } {
                set contents "Error opening $filename with $itk_option(-dumpcommand)\n\n$res"
            }
        }
        set oscroll [lindex [$_text yview] 0]
        $_text clear
        $_text insert 1.0 $contents
        $_text yview moveto $oscroll
    } else {
        pack forget $_text
        pack $_image -fill both -expand true
        set imgr ::imgr_$_name
        catch "$imgr Delete"
        if { $filetype != "" } {
            vtk${filetype}Reader $imgr
        } else {
            set ext [string tolower [file extension $filename]]
            switch $ext {
                ".pnm" - ".ppm" - ".pgm" {
                    vtkPNMReader $imgr 
                }
                ".jpg" - ".jepg" {
                    vtkJPEGReader $imgr 
                }
                ".bmp" {
                    vtkBMPReader $imgr 
                }
                ".ps"  {
                    vtkPostScriptReader $imgr 
                }
                ".tif" - ".tiff" {
                    vtkTIFFReader $imgr 
                }
                ".png" {
                    vtkPNGReader $imgr 
                }
                default {
                    error "unknown image format $ext; options are .ppm, .jpg, .bmp, .ps, .tif, .png"
                }
            }
        }

        $imgr SetFileName $filename
        $imgr Update
        set dims [[$imgr GetOutput] GetDimensions]
        if { $_tkrw != "" && $_mapper != "" } {
            $_tkrw configure -width [lindex $dims 0] -height [lindex $dims 1]
            $_mapper SetInput [$imgr GetOutput]
        }
        $imgr Delete
    }
    
    $this expose
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------


itcl::body isframes::expose {} {
    if { $_tkrw != ""} {
        $_tkrw Render
    }
}


itcl::body isframes::next {} {
    
    set f [expr $itk_option(-frame) + $itk_option(-skip)]
    if { $f > $itk_option(-end) } {
        set f $itk_option(-start)
    }
    $this configure -frame $f
}

itcl::body isframes::middle {} {
    
    set middle [expr ($itk_option(-start) + $itk_option(-end)) / 2]
    $this configure -frame $middle
}

itcl::body isframes::entrycallback {} {
    
    $this configure -filepattern $_patternentry_value
    if { $_startentry_value != "" } {
        $this configure -start $_startentry_value
    }
    if { $_endentry_value != "" } {
        $this configure -end $_endentry_value
    }
}

# use this method to clean up the vtk class instances before calling
# the destructor -- this is a hack to deal with improper cleanup of the vtk
# render windows and vtkTkRenderWidget

itcl::body isframes::pre_destroy {} {

    [$_tkrw GetRenderWindow] Delete
    after idle "destroy $_tkrw"
    $_ren Delete
    $_mapper Delete
    $_actor Delete

    set _tkrw  ""
    set _ren  ""
    set _mapper ""
    set _actor ""
}

#-------------------------------------------------------------------------------
# .PROC isframes_demo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc isframes_demo { {type image} } {

    catch "destroy .isframesdemo"
    toplevel .isframesdemo
    wm title .isframesdemo "isframes demo"
    wm geometry .isframesdemo 400x700

    pack [isframes .isframesdemo.isf2] -fill both -expand true

    switch $type {
        "image" {
            .isframesdemo.isf2 configure -filepattern /tmp/slicer-%04d.png -start 1 -end 65
        }
        "text" {
            .isframesdemo.isf2 configure -filetype "text" -filepattern "$::env(SLICER_HOME)/Base/tcl/*.tcl"
        }
    }
    .isframesdemo.isf2 configure -frame 1
}


#-------------------------------------------------------------------------------
# .PROC isframes_showMovie
# Builds a window and displays a series of image files
# .ARGS
# str pattern a file pattern to determine the sequence of image files to read in
# .END
#-------------------------------------------------------------------------------
proc isframes_showMovie { pattern start end } {

    catch "destroy .isframesShowMovie"
    toplevel .isframesShowMovie
    wm title .isframesShowMovie "Show Slicer Movie"
    wm geometry .isframesShowMovie 800x850
    
    pack [isframes .isframesShowMovie.isf2] -fill both -expand true
    .isframesShowMovie.isf2 configure -filepattern $pattern -start $start -end $end
}
