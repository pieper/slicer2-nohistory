#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Anno.tcl,v $
#   Date:      $Date: 2006/03/06 22:29:17 $
#   Version:   $Revision: 1.27 $
# 
#===============================================================================
# FILE:        Anno.tcl
# PROCEDURES:  
#   AnnoInit
#   AnnoBuildGUI
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC AnnoInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnnoInit {} {
    global Anno Module

    # Define Tabs
    set m Anno
    set Module($m,row1List) "Help Visibility Mode"
    set Module($m,row1Name) "Help Visibility Mode"
    set Module($m,row1,tab) Visibility

    # Module Summary Info
    set Module($m,overview) "Show/hide/change slice window text and 3d box."
    set Module($m,author) "Dave Gering, MIT, gering@ai.mit.edu"
    set Module($m,category) "Settings"

    # Define Procedures
    set Module($m,procGUI) AnnoBuildGUI

    # Define Dependencies
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.27 $} {$Date: 2006/03/06 22:29:17 $}]

    set Anno(hashGap) [$::Interactor(activeSlicer) GetCursorHashGap]
    set Anno(hashLen) [$::Interactor(activeSlicer) GetCursorHashLength]
    set Anno(hashNum) [$::Interactor(activeSlicer) GetNumHashes]
}

#-------------------------------------------------------------------------------
# .PROC AnnoBuildGUI
#
# Set up 2 frames: The Info frame and the frame to set visibility of 
# annotations.
# .END
#-------------------------------------------------------------------------------
proc AnnoBuildGUI {} {
    global Module Gui Anno View Slice

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Visibility
    #   Vis
    #      cBox
    #     cAxes
    #     cLetters
    #     cOutline
    #     cCross
    #     cHashes
    #     cMouse
    # Mode
    #   Coords
    #   Follow
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
This module allows the user to control the text displayed on the slices
and in 3D, as well as the 3D box, etc.

<BR>
The <B>Visibility</B> tab allows you to turn off and on the annotation.
Press a button in to make its corresponding type of annotation visible.
Note that there is 3D annotation and 2D annotation for the slice windows.

<BR> The <B>Mode</B> tab controls the type of coordinates and pixel
values displayed on the 2D slices, as well as the 3D behavior of the
cube and axes.  
"
    regsub -all "\n" $help { } help
    MainHelpApplyTags Anno $help
    MainHelpBuildGUI Anno

    #-------------------------------------------
    # Visibility frame
    #-------------------------------------------
    set fVisibility $Module(Anno,fVisibility)
    set f $fVisibility

    # Frames
    frame $f.fVis -bg $Gui(activeWorkspace)
    pack $f.fVis -side top 

    #-------------------------------------------
    # Anno->Vis frame
    #-------------------------------------------
    set f $fVisibility.fVis

    eval {label $f.lTitle -text "Visibility"} $Gui(WTA)
    pack $f.lTitle -side top -padx $Gui(pad) -pady $Gui(pad)

    # 3D
    # For "Box Axes Letters Outline", Set the Visibility of the 3D actor
    # and then re-render the 3D scene.

    foreach anno "Box Axes Letters Outline" \
        name "{3D Cube} {3D Axes} {3D Letters} {3D Outline around slices}" {

        eval {checkbutton $f.c${anno} -text "$name" \
            -variable Anno([Uncap $anno]) -indicatoron 0 \
            -command "MainAnnoSetVisibility; Render3D"} $Gui(WCA)
             
        pack $f.c${anno} -side top -fill x -padx $Gui(pad) -pady $Gui(pad) 
    } 

    # 2D
    # For "Crosshairs Hashes and Mouse",
    # Set the Visibility of the 2D actor
    # and then re-render the 2D scene.

    foreach anno "Cross Hashes Mouse" \
        name "{Crosshair} {Hash marks} {Slice window text}" {

        eval {checkbutton $f.c${anno} -text "$name" \
            -variable Anno([Uncap $anno]) -indicatoron 0 \
            -command "MainAnnoSetVisibility; RenderSlices"} $Gui(WCA)
             
        pack $f.c${anno} -side top -fill x -padx $Gui(pad) -pady $Gui(pad) 
    }

    # add a radio button to toggle closing the cross hairs
    eval {checkbutton $f.cCrossIntersect -text "Intersect Crosshairs" \
              -variable Anno(crossIntersect) -indicatoron 0 \
              -command "MainAnnoSetCrossIntersect; RenderSlices"} $Gui(WCA)
    pack $f.cCrossIntersect -side top -fill x -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Mode frame
    #-------------------------------------------
    set fMode $Module(Anno,fMode)
    set f $fMode

    # Frames
    frame $f.fCoords -bg $Gui(activeWorkspace)
    frame $f.fPrecision -bg $Gui(activeWorkspace)
    frame $f.fHashGap -bg $Gui(activeWorkspace)
    frame $f.fHashLen -bg $Gui(activeWorkspace)
    frame $f.fHashNum -bg $Gui(activeWorkspace)
    frame $f.fFollow -bg $Gui(activeWorkspace)
    pack $f.fCoords $f.fPrecision $f.fHashGap $f.fHashLen $f.fHashNum $f.fFollow -side top -pady $Gui(pad)

    #-------------------------------------------
    # Mode->Coords frame
    #-------------------------------------------
    set f $fMode.fCoords

    set tip1 "Display of coordinates on 2D slices:\n"
    eval {label $f.l -text "Slice Cursor:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    foreach mode "RAS IJK XY" \
        tip {"RAS coordinates" "array indices into volume" \
        "2D slice coordinates"} {
        eval {radiobutton $f.f.r$mode -width 4 \
            -text "$mode" -variable Anno(cursorMode) -value $mode \
            -indicatoron 0} $Gui(WCA)
        pack $f.f.r$mode -side left -padx 0 -pady 0
        TooltipAdd $f.f.r$mode "$tip1 $tip"
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Mode->Precision frame
    #-------------------------------------------
    set f $fMode.fPrecision

    set tip1 "Display of pixel values on 2D slices:\n"
    eval {label $f.l -text "Pixel Display:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    foreach button "int flt full" \
        mode "%.f %6.2f %f" \
        text "1 1.00 full" \
        tip {"integer display" "floating point" \
        "full: all decimal places shown"} \
        {
        eval {radiobutton $f.f.r$button -width 4 \
            -text "$text" -variable Anno(pixelDispFormat) \
            -value $mode \
            -indicatoron 0} $Gui(WCA)
        pack $f.f.r$button -side left -padx 0 -pady 0
        TooltipAdd $f.f.r$button "$tip1 $tip"
        
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Mode->HashGap frame
    #-------------------------------------------
    set f $fMode.fHashGap
    set tip1 "Adjust the gap between hashes on the crosshair. Central opening = 2 x gap."
    eval {label $f.l -text "Hash Gap:"} $Gui(WLA)
    eval {entry $f.e -width 10 -textvariable Anno(hashGap)} $Gui(WEA)
    TooltipAdd $f.e $tip1
    bind $f.e <Return> "AnnoSetHashGap"
    pack $f.l $f.e -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Mode->HashLen frame
    #-------------------------------------------
    set f $fMode.fHashLen
    set tip1 "Adjust the length of the hashes on the crosshair."
    eval {label $f.l -text "Hash Length:"} $Gui(WLA)
    eval {entry $f.e -width 10 -textvariable Anno(hashLen)} $Gui(WEA)
    TooltipAdd $f.e $tip1
    bind $f.e <Return> "AnnoSetHashLen"
    pack $f.l $f.e -side left -padx $Gui(pad) -fill x -anchor w
    
    #-------------------------------------------
    # Mode->HashNum frame
    #-------------------------------------------
    set f $fMode.fHashNum
    set tip1 "Adjust the number of the hashes on an arm of the crosshair."
    eval {label $f.l -text "Number of Hash Marks:"} $Gui(WLA)
    eval {entry $f.e -width 10 -textvariable Anno(hashNum)} $Gui(WEA)
    TooltipAdd $f.e $tip1
    bind $f.e <Return> "AnnoSetHashNum"
    pack $f.l $f.e -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Mode->Follow frame
    #-------------------------------------------
    set f $fMode.fFollow

    eval {label $f.lTitle -text "Position"} $Gui(WTA)
    pack $f.lTitle -side top -padx $Gui(pad) -pady $Gui(pad)

    eval {checkbutton $f.cAxes -text "Axes follow focal point" \
        -variable Anno(axesFollowFocalPoint) -indicatoron 0 -width 24 \
        -command "MainAnnoUpdateFocalPoint; Render3D"} $Gui(WCA)
    eval {checkbutton $f.cBox -text "Cube follows focal point" \
        -variable Anno(boxFollowFocalPoint) -indicatoron 0 -width 24 \
        -command "MainAnnoUpdateFocalPoint; Render3D"} $Gui(WCA)
    eval {checkbutton $f.cCrossHair -text "Axes follow cross hairs" \
              -variable Anno(axesFollowCrossHairs) -indicatoron 0 -width 24 \
              -command "MainAnnoUpdateAxesPosition; Render3D"} $Gui(WCA)
    eval {checkbutton $f.cMouseCrossHair -text "Cross hairs follow mouse" \
              -variable ::Interactor(crosshairFollowsMouse)  -indicatoron 0 -width 24} $Gui(WCA)
    TooltipAdd $f.cMouseCrossHair "Cross hairs will follow mouse at all times if selected, otherwise only if shift key is pressed"
              
    pack $f.cAxes $f.cCrossHair $f.cMouseCrossHair $f.cBox \
        -side top -fill x -padx $Gui(pad) -pady $Gui(pad) 

}

#-------------------------------------------------------------------------------
# .PROC AnnoSetHashGap
#
# Sets the cursor gap between the cross hair hash marks for the currently active slicer, 
# then renders the slices.
# .END
#-------------------------------------------------------------------------------
proc AnnoSetHashGap {} {
    global Interactor Anno
    $Interactor(activeSlicer) SetCursorHashGap $Anno(hashGap)
    RenderSlices
}

#-------------------------------------------------------------------------------
# .PROC AnnoSetHashLen
#
# Sets the length of cross hair hash marks for the currently active slicer, 
# then renders the slices.
# .END
#-------------------------------------------------------------------------------
proc AnnoSetHashLen {} {
    global Interactor Anno
    $Interactor(activeSlicer) SetCursorHashLength $Anno(hashLen)
    RenderSlices
}

#-------------------------------------------------------------------------------
# .PROC AnnoSetHashNum
#
# Sets the number of cross hair hash marks per arm for the currently active slicer, 
# then renders the slices.
# .END
#-------------------------------------------------------------------------------
proc AnnoSetHashNum {} {
    global Interactor Anno
    $Interactor(activeSlicer) SetNumHashes $Anno(hashNum)
    RenderSlices
}
