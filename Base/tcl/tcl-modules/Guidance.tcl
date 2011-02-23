#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Guidance.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:59 $
#   Version:   $Revision: 1.22 $
# 
#===============================================================================
# FILE:        Guidance.tcl
# PROCEDURES:  
#   Distance3D
#   GuidanceInit
#   GuidanceBuildVTK
#   GuidanceBuildGUI
#   GuidanceSetFocalPointToTarget
#   GuidanceSetTargetVisibility
#   GuidanceSetActiveTarget
#   GuidanceViewTrajectory
#==========================================================================auto=
# Guidance.tcl


#-------------------------------------------------------------------------------
# .PROC Distance3D
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Distance3D {x1 y1 z1 x2 y2 z2} {
    set dx [expr $x2 - $x1]
    set dy [expr $y2 - $y1]
    set dz [expr $z2 - $z1]
    return [expr sqrt($dx*$dx + $dy*$dy + $dz*$dz)]
}

#-------------------------------------------------------------------------------
# .PROC GuidanceInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceInit {} {
    global Guidance Target Module

    # Define Tabs
    set m Guidance
    set Module($m,row1List) "Help Target"
    set Module($m,row1Name) "Help Target"
    set Module($m,row1,tab) Target

   # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Surgical planning: slice reformatting along trajectories."
    set Module($m,author) "David Gering, MIT AI Lab"
    set Module($m,category) "Application"

    # Define Procedures
    set Module($m,procGUI) GuidanceBuildGUI
    set Module($m,procVTK) GuidanceBuildVTK

    # Define Dependencies
    set Module($m,depend) ""

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.22 $} {$Date: 2006/01/06 17:56:59 $}]

    # Target
    set Target(idList) "0 1"

    set Target(0,name) Red
    set Target(0,diffuseColor) "1 .5 .5"
    set Target(0,x) 0
    set Target(0,y) 0
    set Target(0,z) 0
    set Target(0,visibility) 0 
    set Target(0,radius) 4
    set Target(0,focalPoint) 0

    set Target(1,name) Yellow
    set Target(1,diffuseColor) "1 1 .5"
    set Target(1,x) 0
    set Target(1,y) 0
    set Target(1,z) 0
    set Target(1,visibility) 0 
    set Target(1,radius) 4
    set Target(1,focalPoint) 0

    set Target(active0) 1
    set Target(active1) 0
    set Target(focalPoint) 0
    set Target(visibility) 0
    set Target(xStr) ""
    set Target(yStr) ""
    set Target(zStr) ""

}

#-------------------------------------------------------------------------------
# .PROC GuidanceBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceBuildVTK {} {
    global Target

    #---------------------#
    # Target
    #---------------------#
    set Target(activeID) [lindex $Target(idList) 0]

    foreach t $Target(idList) {
        MakeVTKObject Sphere target$t
        target${t}Source SetRadius $Target($t,radius)
        eval [target${t}Actor GetProperty] SetColor $Target($t,diffuseColor)
        target${t}Actor SetVisibility $Target($t,visibility)
    }        
}

#-------------------------------------------------------------------------------
# .PROC GuidanceBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceBuildGUI {} {
    global Gui Target Guidance Module

    set texts "LR PA IS"
    set axi "X Y Z"


    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Target
    #   Top
    #     Active
    #    Bottom
    #     Vis
    #     Title
    #     Pos
    #     Buttons
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
This module allows you to position 2 spherical targets (red and yellow) 
in the 3D view window.
<P>Button descriptions:<BR>
<UL>
<LI><B>Show Target</B> Set the visibility of the active target.
<BR><LI><B>Use as Focal Point</B> Move the focal point (the center of
rotation in the 3D window) to the position of the active target).
Use this to examine an off-center model more easily.
<BR><LI><B>View Trajectory</B> Set the reformatted slices to be oriented
along, and perpendicular to, the trajectory between the 2 targets.
<BR><B>TIP:</B> Perform surgical planning by setting one target to the
desired entry point into the patient, and the other on the target tissue,
and click the <B>View Trajectory</B> button.
</UL>
"
    regsub -all "\n" $help { } help
    MainHelpApplyTags Guidance $help
    MainHelpBuildGUI Guidance

    #-------------------------------------------
    # Target frame
    #-------------------------------------------
    set fTarget $Module(Guidance,fTarget)
    set f $fTarget

    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fBot -bg $Gui(activeWorkspace) -height 300
    pack $f.fTop $f.fBot -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Target->Top frame
    #-------------------------------------------
    set f $fTarget.fTop

    frame $f.fActive -bg $Gui(backdrop)
    pack $f.fActive -side top -pady $Gui(pad)

    #-------------------------------------------
    # Target->Top->Active frame
    #-------------------------------------------
    set f $fTarget.fTop.fActive

    eval {label $f.lActive -text "Active Target:"} $Gui(BLA)
    frame $f.fActive -bg $Gui(activeWorkspace)
    foreach mode "0 1" name "Red Yellow" {
        eval {checkbutton $f.fActive.c$mode \
            -text "$name" -variable Target(active$mode) -width 7 \
            -indicatoron 0 -command "GuidanceSetActiveTarget $mode; Render3D"} $Gui(WCA)
        pack $f.fActive.c$mode -side left -padx 0
    }
    pack $f.lActive $f.fActive -side left -padx $Gui(pad)


    #-------------------------------------------
    # Target->Bot frame
    #-------------------------------------------
    set f $fTarget.fBot

    frame $f.fVis     -bg $Gui(activeWorkspace)
    frame $f.fTitle   -bg $Gui(activeWorkspace)
    frame $f.fPos     -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    pack $f.fVis $f.fTitle $f.fPos $f.fButtons \
        -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Target->Bot->Vis frame
    #-------------------------------------------
    set f $fTarget.fBot.fVis

    # Visibility
    eval {checkbutton $f.cTarget \
        -text "Show Target" -variable Target(visibility) -width 18 \
        -indicatoron 0 -command "GuidanceSetTargetVisibility; Render3D"} $Gui(WCA)            
    pack $f.cTarget
    
    #-------------------------------------------
    # Target->Bot->Title frame
    #-------------------------------------------
    set f $fTarget.fBot.fTitle

    eval {label $f.l -text "Target Position"} $Gui(WTA)
    pack $f.l

    #-------------------------------------------
    # Target->Bot->Pos frame
    #-------------------------------------------
    set f $fTarget.fBot.fPos

    # Position Sliders
    foreach slider $axi text $texts {
        eval {label $f.l${slider} -text "$text:"} $Gui(WLA)

        eval {entry $f.e${slider} \
            -textvariable Target([Uncap ${slider}]Str) -width 7} $Gui(WEA)
            bind $f.e${slider} <Return> \
                "GuidanceSetTargetPosition $slider; Render3D"
            bind $f.e${slider} <FocusOut> \
                "GuidanceSetTargetPosition $slider; Render3D"

        eval {scale $f.s${slider} -from -180 -to 180 -length 120 \
            -variable Target([Uncap ${slider}]Str) \
            -command "GuidanceSetTargetPosition $slider; Render3D" \
            -resolution 1} $Gui(WSA)
    }

    # Grid
    grid $f.lX $f.eX $f.sX  -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lX -sticky e
    grid $f.lY $f.eY $f.sY -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lY -sticky e
    grid $f.lZ $f.eZ $f.sZ  -padx $Gui(pad) -pady $Gui(pad)
    grid $f.lZ -sticky e

    #-------------------------------------------
    # Target->Bot->Buttons frame
    #-------------------------------------------
    set f $fTarget.fBot.fButtons

    eval {button $f.bFocus -text "Use as Focal Point" -width 18 \
        -command "GuidanceSetFocalPointToTarget; RenderAll"} $Gui(WBA)
    eval {button $f.cTrajectory -text "View Trajectory" -width 18 \
        -command "GuidanceViewTrajectory; RenderAll"} $Gui(WBA)

    pack $f.bFocus $f.cTrajectory \
        -side top -pady $Gui(pad) -padx 0

}

#-------------------------------------------------------------------------------
# GuidanceSetTargetPosition
#
# 'value' comes from the sliders, but is unused here.
#-------------------------------------------------------------------------------
proc GuidanceSetTargetPosition {{value ""}} {
    global Target

    if {[ValidateFloat $Target(xStr)] == 0} {
        tk_messageBox -message "LR is not a floating point number."
        return
    }
    if {[ValidateFloat $Target(yStr)] == 0} {
        tk_messageBox -message "PA is not a floating point number."
        return
    }
    if {[ValidateFloat $Target(zStr)] == 0} {
        tk_messageBox -message "IS is not a floating point number."
        return
    }

    set t $Target(activeID)
    set Target($t,x) $Target(xStr)
    set Target($t,y) $Target(yStr)
    set Target($t,z) $Target(zStr)

    target${t}Actor SetPosition $Target($t,x) $Target($t,y) $Target($t,z)
}

#-------------------------------------------------------------------------------
# .PROC GuidanceSetFocalPointToTarget
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceSetFocalPointToTarget {} {
    global Slice View Target

    set t $Target(activeID)
    MainViewSetFocalPoint $Target($t,x) $Target($t,y) $Target($t,z)
}

#-------------------------------------------------------------------------------
# .PROC GuidanceSetTargetVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceSetTargetVisibility {} {
    global Target

    set t $Target(activeID)
    set Target($t,visibility) $Target(visibility)

    target${t}Actor SetVisibility $Target($t,visibility)
}

#-------------------------------------------------------------------------------
# .PROC GuidanceSetActiveTarget
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceSetActiveTarget {{t ""}} {
    global Target

    if {$t == ""} {
        set t $Target(activeID)
    } else {
        set Target(activeID) $t
    }

   # Change button status
     set Target(active0) 0
    set Target(active1) 0
    set Target(active$t) 1

    foreach param "visibility focalPoint" {
        set Target($param) $Target($t,$param)
    }
    foreach param "x y z" {
        set Target(${param}Str) [format "%.2f" $Target($t,$param)]
    }
}

#-------------------------------------------------------------------------------
# .PROC GuidanceViewTrajectory
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc GuidanceViewTrajectory {} {
    global Target View Slice

    set t1 [lindex $Target(idList) 0]
    set t2 [lindex $Target(idList) 1]

    set dx [expr $Target($t2,x) - $Target($t1,x)]
    set dy [expr $Target($t2,y) - $Target($t1,y)]
    set dz [expr $Target($t2,z) - $Target($t1,z)]
    set d [expr sqrt($dx*$dx + $dy*$dy + $dz*$dz)]
    if {$d == 0} {
        tk_messageBox -message "The targets should be in different locations."
        return
    }

    set fpx [expr ($Target($t1,x) + $Target($t2,x))/2.0]
    set fpy [expr ($Target($t1,y) + $Target($t2,y))/2.0]
    set fpz [expr ($Target($t1,z) + $Target($t2,z))/2.0]
    scan [$View(viewCam) GetPosition] "%f %f %f" vpx vpy vpz
    set a [Distance3D $fpx $fpy $fpz $vpx $vpy $vpz]

    set vpx [expr $fpx + 1.0*$dx*$a/$d]    
    set vpy [expr $fpy + 1.0*$dy*$a/$d]    
    set vpz [expr $fpz + 1.0*$dz*$a/$d]    

    $View(viewCam) SetFocalPoint $fpx $fpy $fpz
    $View(viewCam) SetPosition   $vpx $vpy $vpz
    $View(viewCam) SetViewUp 0 1 0
    eval $View(viewCam) SetClippingRange $View(baselineClippingRange)
    $View(viewCam) ComputeViewPlaneNormal
    $View(viewCam) OrthogonalizeViewUp

    MainViewLightFollowCamera

    set Slice(visibilityAll) 1
    MainSlicesSetVisibilityAll
    MainSlicesSetOrientAll Orthogonal
}


