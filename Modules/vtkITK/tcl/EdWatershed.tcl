#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdWatershed.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:49 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        EdWatershed.tcl
# PROCEDURES:  
#   EdWatershedInit
#   EdWatershedBuildGUI
#   EdWatershedLevel val
#   EdWatershedEnter
#   EdWatershedEnter
#   EdWatershedSegment
#   EdWatershedApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdWatershedInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdWatershedInit {} {
    global Ed Gui EdWatershed Volume Slice Fiducials

    set e EdWatershed
    set Ed($e,name)      "Watershed"
    set Ed($e,initials)  "Ws"
    set Ed($e,desc)      "ITK-Based Watershed: 3D segmentation"
    set Ed($e,rank)      14;
    set Ed($e,procGUI)   EdWatershedBuildGUI
    set Ed($e,procEnter) EdWatershedEnter
    set Ed($e,procExit)  EdWatershedExit

    # Define Dependencies
    set Ed($e,depend) Fiducials 
    set EdWatershed(watershedInitialized) 0

    # Required
    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active

    set EdWatershed(level) 40

    set EdWatershed(majorVersionTCL) 1
    set EdWatershed(minorVersionTCL) 0
    set EdWatershed(dateVersionTCL) "2003-02-23/20:00EST"

    set EdWatershed(versionTCL) "$EdWatershed(majorVersionTCL).$EdWatershed(minorVersionTCL) \t($EdWatershed(dateVersionTCL))"

    set EdWatershed(shouldDisplayWarningVersion) 1

}

#-------------------------------------------------------------------------------
# .PROC EdWatershedBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdWatershedBuildGUI {} {
    global Ed Gui Label Volume EdWatershed Fiducials Help

    set e EdWatershed
    #-------------------------------------------
    # Watershed frame
    #-------------------------------------------

    set f $Ed(EdWatershed,frame)

    #copied from EdPhaseWireBuildGUI

    set label ""
    set subframes {Help Basic }
    set buttonText {"Help" "Basic"}
    set tooltips { "Help: We all need it sometimes." \
        "Basic: For Users" }
    set extraFrame 0
    set firstTab Basic

    TabbedFrame EdWatershed $f $label $subframes $buttonText \
        $tooltips $extraFrame $firstTab

    #-------------------------------------------
    # TabbedFrame->Help frame
    #-------------------------------------------
    set f $Ed(EdWatershed,frame).fTabbedFrame.fHelp

    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true

    set Ed(EdWatershed,helpWidget) [HelpWidget $f.fWidget]

    set help "DISCLAIMER: this module is for development only!
Implementation of ITK Watershed calculation as slicer editor effect.
See www.itk.org for description of algorithm.
"
    eval $Ed(EdWatershed,helpWidget) tag configure normal   $Help(tagNormal)

    $Ed(EdWatershed,helpWidget) insert insert "$help" normal

    #-------------------------------------------
    # TabbedFrame->Basic frame
    #-------------------------------------------
    set f $Ed(EdWatershed,frame).fTabbedFrame.fBasic
 
    eval {button $f.bSegment -text "Segment" \
          -command "EdWatershedSegment"} $Gui(WBA)

    grid $f.bSegment -padx 2 -pady $Gui(pad)

    eval {scale $f.sLevel -from 1 -to 100 \
            -length 220 -variable EdWatershed(level) -resolution 1 \
            -command "EdWatershedLevel "} \
            $Gui(WSA) {-sliderlength 22}

    grid $f.sLevel -sticky w

}


#-------------------------------------------------------------------------------
# .PROC EdWatershedLevel
# 
# .ARGS
# float val
# .END
#-------------------------------------------------------------------------------
proc EdWatershedLevel {val} {
    global EdWatershed 

    if { $EdWatershed(watershedInitialized) } {
        ws_watershed SetLevel [expr $val / 100.]
    }
}


#-------------------------------------------------------------------------------
# .PROC EdWatershedEnter
# called whenever we enter the Watershed tab
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdWatershedEnter {} {
    global Ed Label Slice EdWatershed Fiducials Gui Volumes

    set e EdWatershed

    if {$EdWatershed(watershedInitialized) == 0} {

        catch "ws_cast Delete"
        catch "ws_diffusion Delete"
        catch "ws_magnitude Delete"
        catch "ws_watershed Delete"
        catch "ws_labelcast Delete"

        set v [EditorGetInputID $Ed($e,input)]

        vtkImageCast ws_cast
        ws_cast SetOutputScalarTypeToFloat
        ws_cast SetInput [Volume($v,vol) GetOutput]
  
        vtkITKCurvatureAnisotropicDiffusionImageFilter ws_diffusion 
        ws_diffusion SetTimeStep 0.0625
        ws_diffusion SetNumberOfIterations 5
        ws_diffusion SetConductanceParameter 1
        ws_diffusion SetInput [ws_cast GetOutput]
        
        vtkITKGradientMagnitudeImageFilter ws_magnitude
        ws_magnitude SetInput [ws_diffusion GetOutput]

        vtkITKWatershedImageFilter ws_watershed
        ws_watershed SetThreshold .05
        ws_watershed SetLevel $EdWatershed(level)
        ws_watershed SetInput [ws_magnitude GetOutput]

        vtkImageCast ws_labelcast
        ws_labelcast SetOutputScalarTypeToShort
        ws_labelcast SetInput [ws_watershed GetOutput]

        set EdWatershed(watershedInitialized) 1

        # Required
        set Ed($e,scope)  3D 
        set Ed($e,input)  Original
        set Ed($e,interact) Active

        EditorActivateUndo 0
        
        EditorClear Working
        
        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
        Ed(editor)  UseInputOn

        set Gui(progressText) "Watershed: initializing"

        MainStartProgress

        Ed(editor) Apply  ws_cast ws_labelcast

        MainEndProgress

        Ed(editor)  SetInput ""
        Ed(editor)  UseInputOff

        EdUpdateAfterApplyEffect $v
    }    
}


#-------------------------------------------------------------------------------
# .PROC EdWatershedEnter
# called whenever we exit the Watershed tab
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdWatershedExit {} {
    global Ed EdWatershed

    #catch "ws_cast Delete"
    #catch "ws_diffusion Delete"
    #catch "ws_magnitude Delete"
    #catch "ws_watershed Delete"
    #catch "ws_labelcast Delete"

    set EdWatershed(watershedInitialized) 0

    Slicer BackFilterOff
    Slicer ForeFilterOff
    Slicer ReformatModified
    Slicer Update
}

#-------------------------------------------------------------------------------
# .PROC EdWatershedSegment
#
# Where the job gets done
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdWatershedSegment {} {
    global Label Fiducials EdWatershed Volume Ed Gui

    set e EdWatershed

    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active   

    set v [EditorGetInputID $Ed($e,input)]

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
    Ed(editor)  UseInputOn

    set Gui(progressText) "Watershed"

    MainStartProgress

    Ed(editor) Apply  ws_cast ws_labelcast

    MainEndProgress

    Ed(editor)  SetInput ""
    Ed(editor)  UseInputOff

    EdUpdateAfterApplyEffect $v
}

#-------------------------------------------------------------------------------
# .PROC EdWatershedApply
# this is called when the user clicks on the active slice
# we don't want to do anything special in this case
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdWatershedApply {} {}
