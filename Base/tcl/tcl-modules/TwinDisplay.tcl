#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: TwinDisplay.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:01 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        TwinDisplay.tcl
# PROCEDURES:  
#   TwinDisplayInit
#   TwinDisplayBuildVTK
#   TwinDisplayBuildGUI
#   TwinDisplayApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC TwinDisplayInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TwinDisplayInit {} {
    global TwinDisplay Module

    # Define Tabs
    set m TwinDisplay
    set Module($m,row1List) "Help TwinDisplay"
    set Module($m,row1Name) "Help TwinDisplay"
    set Module($m,row1,tab) TwinDisplay

    # Module Summary Info
    set Module($m,overview) "Display another 3D window on a different (MRT) monitor."
    set Module($m,author) "Dave Gering, MIT, gering@ai.mit.edu"
    set Module($m,category) "Visualisation"

    # Define Procedures
    set Module($m,procGUI) TwinDisplayBuildGUI
    set Module($m,procVTK) TwinDisplayBuildVTK

    set TwinDisplay(mode) Off
    set TwinDisplay(xPos) 0
    set TwinDisplay(yPos) 0
    set TwinDisplay(width) 400
    set TwinDisplay(height) 300
    set TwinDisplay(screen) 0

    # Define Dependencies
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.3 $} {$Date: 2006/01/06 17:57:01 $}]
}

#-------------------------------------------------------------------------------
# .PROC TwinDisplayBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TwinDisplayBuildVTK {} {
    global TwinDisplay viewWin twinWin

    vtkXDisplayWindow TwinDisplay(display)

    vtkRenderer twinRen

    vtkImageFrameSource TwinDisplay(src)
    TwinDisplay(src) SetExtent 0 [expr $TwinDisplay(width)-1] 0 [expr $TwinDisplay(height)-1]
    TwinDisplay(src) SetRenderWindow $viewWin
        
    vtkImageMapper TwinDisplay(mapper)
    TwinDisplay(mapper) SetColorWindow 255
    TwinDisplay(mapper) SetColorLevel 127.5
    TwinDisplay(mapper) SetInput [TwinDisplay(src) GetOutput]
    
    vtkActor2D TwinDisplay(actor)
    TwinDisplay(actor) SetMapper TwinDisplay(mapper)
    twinRen AddActor2D TwinDisplay(actor)
}

#-------------------------------------------------------------------------------
# .PROC TwinDisplayBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TwinDisplayBuildGUI {} {
    global Gui TwinDisplay Module

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # TwinDisplay
    #   Grid
    #   Mode 
    #
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
The TwinDisplay window mirrors the 3D view, and can be set to appear on a different
screen number on UNIX systems.  If you have 2 graphics cards in your computer,
then they are numbered 0 and 1.  To change the screen of the TwinDisplay window,
you need to change the number on the interface, AND toggle the TwinDisplay window
off and on."
    regsub -all "\n" $help { } help

    MainHelpApplyTags TwinDisplay $help
    MainHelpBuildGUI TwinDisplay

    #-------------------------------------------
    # TwinDisplay frame
    #-------------------------------------------
    set fTwinDisplay $Module(TwinDisplay,fTwinDisplay)
    set f $fTwinDisplay

    frame $f.fGrid -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fMode -bg $Gui(activeWorkspace)
    pack $f.fMode $f.fGrid \
        -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # TwinDisplay->Mode Frame
    #-------------------------------------------
    set f $fTwinDisplay.fMode
    
    eval {label $f.l -text "Mode: "} $Gui(WLA)
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach value "On Pause Off" width "3 6 4" {
        eval {radiobutton $f.r$value -width $width \
            -text "$value" -value "$value" -variable TwinDisplay(mode) \
            -indicatoron 0 -command "TwinDisplayApply"} $Gui(WCA)
        pack $f.r$value -side left -padx 0 -pady 0
    }
    #-------------------------------------------
    # TwinDisplay->Grid Frame
    #-------------------------------------------
    set f $fTwinDisplay.fGrid
    
    # Entry fields (the loop makes a frame for each variable)
    foreach param "xPos yPos width height screen" \
        name "{X Position} {Y Position} {Width} {Height} {Screen Number}" {

        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 5 -textvariable TwinDisplay($param)} $Gui(WEA)

        grid $f.l$param $f.e$param -padx $Gui(pad) -pady $Gui(pad) -sticky e
        grid $f.e$param -sticky w
    }
    eval {button $f.b -text "Apply" -command "TwinDisplayApply"} $Gui(WBA)
    grid $f.b -columnspan 2 -padx $Gui(pad) -pady $Gui(pad) 

}

#-------------------------------------------------------------------------------
# .PROC TwinDisplayApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TwinDisplayApply {} {
    global TwinDisplay twinWin

    if {$TwinDisplay(mode) == "On"} {
        # If window does not exist, create it
        if {[info exists twinWin] == 0 || [info command $twinWin] == ""} {
            set twinWin [TwinDisplay(display) GetRenderWindow $TwinDisplay(screen)]
            $twinWin AddRenderer twinRen
            $twinWin DoubleBufferOn

        }
        $twinWin SetPosition $TwinDisplay(xPos) $TwinDisplay(yPos)
        $twinWin SetSize $TwinDisplay(width) $TwinDisplay(height)
        TwinDisplay(src) SetExtent 0 [expr $TwinDisplay(width)-1] 0 [expr $TwinDisplay(height)-1]
        Render3D

    } elseif {$TwinDisplay(mode) == "Off"} {
        # If window exists, delete it
        if {[info exists twinWin] == 1 && [info command $twinWin] != ""} {
            $twinWin Delete
        }
    }
}
