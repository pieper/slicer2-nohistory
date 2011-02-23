#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Alignments.tcl,v $
#   Date:      $Date: 2006/02/15 21:31:44 $
#   Version:   $Revision: 1.37 $
# 
#===============================================================================
# FILE:        Alignments.tcl
# PROCEDURES:  
#   AlignmentsInit
#   AlignmentsUpdateMRML
#   AlignmentsBuildGUI
#   AlignmentsBuildVTK
#   AlignmentsSetVolumeMatrix The
#   AlignmentsIdentity
#   AlignmentsInvert
#   AlignmentsSetReferenceCoordinates 
#   AlignmentsSetReferenceCoordinates
#   AlignmentsSetPropertyType
#   AlignmentsPropsApply
#   AlignmentsPropsCancel
#   AlignmentsManualTranslate
#   AlignmentsManualTranslateDual
#   AlignmentsManualRotate
#   AlignmentsSetRefVolume v
#   AlignmentsSetVolume
#   AlignmentsB1
#   AlignmentsB1Motion
#   AlignmentsB3Motion x y
#   AlignmentsInteractorZoom
#   AlignmentsSlicesSetZoom
#   AlignmentsB1Release
#   AlignmentsSetRegistrationMode
#   AlignmentsBuildMinimizedSliceControls
#   AlignmentsBuildMinimizedSliceThumbControls
#   AlignmentsBuildActiveVolSelectControls
#   AlignmentsConfigSliceGUI
#   AlignmentsUnpackFidAlignScreenControls
#   AlignmentsFidAlignGo
#   AlignmentsFidAlignApply
#   AlignmentsFidAlignCancel
#   AlignmentsFidAlignResetVars
#   AlignmentsSplitVolumes
#   AlignmentsPick2D
#   AlignmentsLandTrans
#   AlignmentsSetViewMenuState
#   AlignmentsAddLetterActors
#   AlignmentsMatRenUpdateCamera
#   AlignmentsUpdateFidAlignViewVisibility
#   AlignmentsUpdateMainViewVisibility
#   AlignmentsAddMainView
#   AlignmentsAddFidAlignView
#   AlignmentsRemoveFidAlignView
#   AlignmentsRemoveMainView
#   AlignmentsGetCurrentView
#   AlignmentsSetActiveScreen
#   AlignmentsFiducialsUpdated
#   AlignmentsNewFidListChosen -
#   AlignmentsSetRefVolList
#   AlignmentsSetVolumeList
#   AlignmentsRemoveBoxes
#   AlignmentsRebuildBoxes
#   AlignmentsSlicesSetOrientAll
#   AlignmentsSlicesSetOrient
#   AlignmentsSlicesOffsetUpdated
#   AlignmentsSlicesSetSliderRange int
#   AlignmentsSlicesSetOffsetIncrement int float
#   AlignmentsSlicesSetOffset
#   AlignmentsSlicesSetOffsetInit
#   AlignmentsSlicesSetVisibilityAll
#   AlignmentsSlicesSetVisibility
#   AlignmentsSlicesRefreshClip int
#   AlignmentsSetSliceWindows
#   AlignmentsSetActiveSlicer
#   AlignmentsFidAlignViewUpdate
#   AlignmentsShowSliceControls
#   AlignmentsHideSliceControls
#   AlignmentsSetRegTabState
#   AlignmentsSetColorCorrespondence
#   AlignmentsSetColorCorrespondence
#   AlignmentsMainFileCloseUpdated
#   AlignmentsExit
#   AlignmentsEnter
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC AlignmentsInit
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsInit {} {
    global Matrix Module Volume View Slice

    # Define Tabs
    set m Alignments
    set Module($m,row1List) "Help Props Manual Auto"
    set Module($m,row1Name) "{Help} {Props} {Manual} {Auto}"
    set Module($m,row1,tab) Manual

    # Module Summary Info
    set Module($m,overview) "Edit transformation matrices to move volumes/models.\n\t\tUse the Auto tab to perform registrations using embedded algorithms. \n\t\tSelect the FidAlign option to select corresponding points on two volumes so as to \n\t\t get a coarse alignment of the two volumes. Use the Intensity option \n\t\tto perform registration fully automatically."
    set Module($m,author) "Hanifa Dostmohamed, BWH, hanifa@bwh.harvard.edu"
    set Module($m,category) "Registration"

    # Define Procedures
    set Module($m,procGUI)   AlignmentsBuildGUI
    set Module($m,procMRML)  AlignmentsUpdateMRML
    set Module($m,procVTK)   AlignmentsBuildVTK
    set Module($m,procEnter) AlignmentsEnter

    # Callbacks from other modules
    set Module($m,procViewerUpdate) AlignmentsFidAlignViewUpdate
    set Module($m,procMainFileCloseUpdateEntered) AlignmentsMainFileCloseUpdated
    set Module($m,fiducialsStartCallback) AlignmentsFiducialsUpdated

    # Define Dependencies
    ## No Dependency, simply uses RigidIntensityRegistration if available
    #set Module($m,depend) "RigidIntensityRegistration"

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
            {$Revision: 1.37 $} {$Date: 2006/02/15 21:31:44 $}]

    # Props
    set Matrix(propertyType) Basic
    set Matrix(volumeMatrix) None
    set Matrix(render)     All
    set Matrix(pid) ""
    set Matrix(mouse) Translate
    set Matrix(xHome) 0
    set Matrix(yHome) 0
    set Matrix(prevTranLR) 0.00
    set Matrix(prevTranPA) 0.00
    set Matrix(prevTranIS) 0.00
    set Matrix(rotAxis) "XX"
    set Matrix(regRotLR) 0.00
    set Matrix(regRotIS) 0.00
    set Matrix(regRotPA) 0.00
    set Matrix(refCoordinate) "Pre"

    #Event Bindings
    set Matrix(eventManager) ""
    lappend Matrix(eventManager) { $Gui(fViewWin) <Motion> { AlignmentsGetCurrentView %W %x %y } }

    #Auto, FidAlign and TPS Registration Vars

    set Matrix(regMode) ""

    set Matrix(tAuto) ""
    set Matrix(volume) $Volume(idNone)
    set Matrix(refVolume) $Volume(idNone)

    set Matrix(activeSlicer) Slicer
    set Matrix(currentDataList) ""
    set Matrix(FidAlignRefVolumeName) None
    set Matrix(FidAlignVolumeName) None
    set Matrix(fidSelectViewOn) 0
    set Matrix(splitScreen) 0
    set Matrix(FidAlignEntered) 0
    #Fiducial Lists used for FidAlign
    set Matrix(FidAlignRefVolumeList) ""
    set Matrix(FidAlignVolumeList) ""
    #Renderer visibility settings
    set Matrix(mainview,visibility) 1
    set Matrix(matricesview,visibility) 0
    #Slice visibility settings
    #The slice actors that go in the viewRen renderer
    set Slice(0,MatSlicer,visibility) 0
    set Slice(1,MatSlicer,visibility) 0
    set Slice(2,MatSlicer,visibility) 0
    #The slice actors that go in the matRen renderer
    set Slice(0,Slicer,visibility) 0
    set Slice(1,Slicer,visibility) 0
    set Slice(2,Slicer,visibility) 0
    #Hanifa - I started working on incorporating Thin Plate Spline into this module.
    #Currently only the interface for TPS is here, but I have commented out everything that
    #deals with TPS since the code has not yet been plugged in.
    #set Matrix(TPSVolumeName) None
    #set Matrix(TPSRefVolumeName) None
    #MATREN
    #Create a new renderer in order to display the split view showing two volumes
    vtkRenderer matRen
    lappend Module(Renderers) matRen
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsUpdateMRML
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsUpdateMRML {} {
    global Matrix Volume Fiducials

    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $Matrix(refVolume) ] == -1} {
        AlignmentsSetRefVolume $n
    }
    if {[lsearch $Volume(idList) $Matrix(volume) ] == -1} {
        AlignmentsSetVolume $n
    }

    # Menu of Volumes
    # ------------------------------------
    set m $Matrix(mbVolume).m
    $m delete 0 end
    # All volumes except none
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone) && [Volume($v,node) GetLabelMap] == "0"} {
            $m add command -label "[Volume($v,node) GetName]" \
                    -command "AlignmentsSetVolume $v"
        }
    }

    # Menu of Reference Volumes
    # ------------------------------------
    set m $Matrix(mbRefVolume).m
    $m delete 0 end
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone) && [Volume($v,node) GetLabelMap] == "0"} {
            $m add command -label "[Volume($v,node) GetName]" \
                    -command "AlignmentsSetRefVolume $v"
        }
    }

    # Menu of Fiducial Lists for FidAlign for the Reference Volume
    # ------------------------------------------------------------
    set m $Matrix(mbFidRefVolume).m.sub
    $m delete 0 end
    #rebuild the boxes if the user selected a different list.
    #reset the "old list"
    foreach v $Fiducials(idList) {
        $m add command -label [Fiducials($v,node) GetName] \
            -command "AlignmentsSetRefVolList [Fiducials($v,node) GetName]; AlignmentsNewFidListChosen RefVolume"
    }

    # Menu of Fiducial Lists for FidAlign for the Volume
    # --------------------------------------------------
    set m $Matrix(mbFidVolume).m.sub
    $m delete 0 end
    foreach v $Fiducials(idList) {
        $m add command -label [Fiducials($v,node) GetName] \
            -command "AlignmentsSetVolumeList [Fiducials($v,node) GetName]; AlignmentsNewFidListChosen Volume"
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsBuildGUI
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsBuildGUI {} {
    global Gui Matrix Module Volume Fiducials Slice

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Props
    #   Top
    #     Active
    #     Type
    #   Bot
    #     Basic
    #     Advanced
    # Manual
    # Auto
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
    Description by tab:<BR>
    <UL>
    <LI><B>Props:
    </B> Directly set the matrix. The line of 16 numbers are in order of the first row, second row, etc. Click <B>Advanced</B> to copy one of the matrices derived from the header of a volume.

    <BR>
    <LI><B>Manual:
    </B> Set the matrix using manual rigid registration with 6 degrees of freedom (3 translation, 3 rotation). Either move the sliders, or click the left mouse button on a slice window and drag it.  The <B>Mouse Action</B> buttons indicate whether to translate or rotate the volume in the Slice windows.

    <BR><BR><B>TIP:</B> The <B>Render</B> buttons indicate which windows to render as you move the sliders or mouse.  Rendering just one slice is much faster.

    <BR>
    <LI><B>Auto:
    </B> Automatic and semi-automatic registration mechanisms. 
       <UL> 
          <LI> The <B>FidAlign</B> tab allows selection of corresponding fiducial points on the volume to move and the reference volume. Once this button is pressed, the screen is split into half and the volume to move is displayed in the screen on the right while the reference volume is displayed on the left. The screen color indicates which screen is the active one (yellow) and which one is the inactive one (blue). The active screen is set either by the motion of the mouse or the radio buttons found on the control panel. It is important to note that only the control panel for the active volume is shown. In the FidAlign mode, pick at least three corresponding points on each of the volumes and click the apply button to obtain a coarse registration of the two volumes. Click the cancel button to exit the fiducial selection mode. The matrix is set to the transformation matrix that was used to coarsly align the volume to move with the reference volume. This matrix can be set as the active matrix for <B>Intensity</B> registration or the matrix can be manually adjusted using the sliders on the manual tab. 
          <LI> The <B>Intensity</B> button performs automatic registration.. This will set the matrix to the transformation matrix needed to align the <B>Volume to Move</B> with the <B>Reference Vol.</B>.<BR><B>TIP:</B> Set the <B>Run Speed</B> to <I>Fast</I> if the 2 volumes are already roughly aligned. Click on the <I>View color correspondence between the two overlayed images</I> button to visually assess the quality of registration. When the reference volume(red) and the volume to move(blue) overlap, they form a pink color.
       </UL>
    </UL>"
# <LI> The <B>TPS</B> button will be used to access registration using the thin plate spline method in the future. It is currently not available in this version. 
    regsub -all "\n" $help { } help
    MainHelpApplyTags Alignments $help
    MainHelpBuildGUI  Alignments

    #-------------------------------------------
    # Props frame
    #-------------------------------------------
    set fProps $Module(Alignments,fProps)
    set f $fProps

    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fBot -bg $Gui(activeWorkspace) -height 300
    pack $f.fTop $f.fBot -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Props->Bot frame
    #-------------------------------------------
    set f $fProps.fBot

    foreach type "Basic Advanced" {
        frame $f.f${type} -bg $Gui(activeWorkspace)
        place $f.f${type} -in $f -relheight 1.0 -relwidth 1.0
        set Matrix(f${type}) $f.f${type}
    }
    raise $Matrix(fBasic)

    #-------------------------------------------
    # Props->Top frame
    #-------------------------------------------
    set f $fProps.fTop

    frame $f.fActive -bg $Gui(backdrop)
    frame $f.fType   -bg $Gui(backdrop)
    pack $f.fActive $f.fType -side top -fill x -pady $Gui(pad) -padx $Gui(pad)

    #-------------------------------------------
    # Props->Top->Active frame
    #-------------------------------------------
    set f $fProps.fTop.fActive

    eval {label $f.lActive -text "Active Matrix: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
            -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Matrix(mbActiveList) $f.mbActive
    lappend Matrix(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Props->Top->Type frame
    #-------------------------------------------
    set f $fProps.fTop.fType

    eval {label $f.l -text "Properties:"} $Gui(BLA)
    frame $f.f -bg $Gui(backdrop)
    foreach p "Basic Advanced" {
        eval {radiobutton $f.f.r$p \
                -text "$p" -command "AlignmentsSetPropertyType" \
                -variable Matrix(propertyType) -value $p -width 8 \
                -indicatoron 0} $Gui(WRA)
        pack $f.f.r$p -side left -padx 0
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Props->Bot->Basic frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic

    frame $f.fName    -bg $Gui(activeWorkspace)
    frame $f.fMatrix  -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fName $f.fMatrix $f.fApply \
            -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced

    frame $f.fDesc    -bg $Gui(activeWorkspace)
    frame $f.fVolume  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fDesc $f.fVolume $f.fApply \
            -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Basic->Name frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fName

    eval {label $f.l -text "Name:" } $Gui(WLA)
    eval {entry $f.e -textvariable Matrix(name)} $Gui(WEA)
    pack $f.l -side top -padx $Gui(pad) -anchor w
    pack $f.e -side top -padx $Gui(pad) -anchor w -expand 1 -fill x

    #-------------------------------------------
    # Props->Bot->Basic->Matrix frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fMatrix

    eval {label $f.l -text "Matrix:" } $Gui(WLA)
    pack $f.l -side top -padx $Gui(pad) -anchor w

    foreach row $Matrix(rows) {
        set f $fProps.fBot.fBasic.fMatrix
        frame $f.f$row -bg $Gui(activeWorkspace)
        pack $f.f$row -side top -padx $Gui(pad) -pady $Gui(pad)
        set f $f.f$row
        foreach col $Matrix(cols) {
            eval {entry $f.e$col -width 5 \
                    -textvariable \
                    Matrix(matrix,$row,$col) \
                } $Gui(WEA)
            pack $f.e$col -side left -padx $Gui(pad) -pady 2
        }
    }
    #-------------------------------------------
    # Props->Bot->Basic->Apply frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fApply

    eval {button $f.bApply -text "Apply" \
            -command "AlignmentsPropsApply; RenderAll"} $Gui(WBA) {-width 8}
    eval {button $f.bCancel -text "Cancel" \
            -command "AlignmentsPropsCancel"} $Gui(WBA) {-width 8}
    grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced->Desc frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fDesc

    eval {label $f.l -text "Optional Description:"} $Gui(WLA)
    eval {entry $f.e -textvariable Matrix(desc)} $Gui(WEA)
    pack $f.l -side top -padx $Gui(pad) -fill x -anchor w
    pack $f.e -side top -padx $Gui(pad) -expand 1 -fill x

    #-------------------------------------------
    # Props->Bot->Advanced->Volume frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fVolume

    eval {label $f.l -text "Get Matrix from Volume"} $Gui(WTA)
    frame $f.fVolume  -bg $Gui(activeWorkspace)
    frame $f.fMatrix  -bg $Gui(activeWorkspace)
    pack $f.l $f.fVolume $f.fMatrix \
            -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced->Volume->Volume frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fVolume.fVolume

    eval {label $f.lActive -text "Volume: "} $Gui(WLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
            -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Props->Bot->Advanced->Volume->Matrix frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fVolume.fMatrix

    # Menu of Alignments
    # ------------------------------------
    eval {label $f.l -text "Type of Matrix: "} $Gui(WLA)
    eval {menubutton $f.mb -text "$Matrix(volumeMatrix)" -relief raised -bd 2 -width 20 \
            -menu $f.mb.m} $Gui(WMBA)
    set Matrix(mbVolumeMatrix) $f.mb
    eval {menu $f.mb.m} $Gui(WMA)
    pack $f.l $f.mb -side left -pady $Gui(pad) -padx $Gui(pad)

    foreach v "None ScaledIJK->RAS RAS->IJK RAS->VTK" {
        $f.mb.m add command -label "$v" -command "AlignmentsSetVolumeMatrix $v"
    }

    #-------------------------------------------
    # Props->Bot->Advanced->Apply frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fApply

    eval {button $f.bApply -text "Apply" \
            -command "AlignmentsPropsApply; RenderAll"} $Gui(WBA) {-width 8}
    eval {button $f.bCancel -text "Cancel" \
            -command "AlignmentsPropsCancel"} $Gui(WBA) {-width 8}
    grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Manual frame
    #-------------------------------------------
    set fManual $Module(Alignments,fManual)
    set f $fManual

    # Frames
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fRender    -bg $Gui(activeWorkspace)
    frame $f.fTranslate -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fRotate    -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fBtns      -bg $Gui(activeWorkspace)
    frame $f.fMouse    -bg $Gui(activeWorkspace)
    frame $f.fGlobalLocal    -bg $Gui(activeWorkspace)
    pack $f.fActive $f.fRender $f.fGlobalLocal $f.fTranslate $f.fRotate $f.fBtns \
        $f.fMouse -side top -pady 2 -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Manual->Btns frame
    #-------------------------------------------
    set f $fManual.fBtns

    eval {button $f.bIdentity -text "Identity" \
            -command "AlignmentsIdentity; RenderAll"} $Gui(WBA) {-width 8}
    eval {button $f.bInvert -text "Invert" \
            -command "AlignmentsInvert; RenderAll"} $Gui(WBA) {-width 8}
    grid $f.bIdentity $f.bInvert -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Manual->Active frame
    #-------------------------------------------
    set f $fManual.fActive

    eval {label $f.lActive -text "Active Matrix: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
            -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Matrix(mbActiveList) $f.mbActive
    lappend Matrix(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Manual->Render frame
    #-------------------------------------------
    set f $fManual.fRender

    set modes "Active Slices All"
    set names "{1 Slice} {3 Slices} {3D}"

    eval {label $f.l -text "Render:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    foreach mode $modes name $names {
        eval {radiobutton $f.f.r$mode -width [expr [string length $name]+1]\
                -text "$name" -variable Matrix(render) -value $mode \
                -indicatoron 0} $Gui(WRA)
        pack $f.f.r$mode -side left -padx 0 -pady 0
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Manual->Translate frame
    #-------------------------------------------
    set f $fManual.fTranslate

    eval {label $f.lTitle -text "Translation (mm)"} $Gui(WLA)
    grid $f.lTitle -columnspan 3 -pady $Gui(pad) -padx 1

    foreach slider "LR PA IS" {

        eval {label $f.l${slider} -text "${slider} : "} $Gui(WLA)

        eval {entry $f.e${slider} -textvariable Matrix(regTran${slider}) \
                -width 7} $Gui(WEA)
          bind $f.e${slider} <Return> \
                "AlignmentsManualTranslate regTran${slider}"
        bind $f.e${slider} <FocusOut> \
                "AlignmentsManualTranslate regTran${slider}"

        eval {scale $f.s${slider} -from -240 -to 240 -length 120 \
                -command "AlignmentsManualTranslate regTran${slider}" \
                -variable Matrix(regTran${slider}) -resolution 0.1 -digits 5} $Gui(WSA)
        bind $f.s${slider} <Leave> "AlignmentsManualTranslate regTran$slider"

        grid $f.l${slider} $f.e${slider} $f.s${slider} -pady 2
    }

    #-------------------------------------------
    # Manual->Rotate frame
    #-------------------------------------------
    set f $fManual.fRotate

    eval {label $f.lTitle -text "Rotation (deg)"} $Gui(WLA)
    grid $f.lTitle -columnspan 3 -pady $Gui(pad) -padx 1

    foreach slider "LR PA IS" {

        eval {label $f.l${slider} -text "${slider} : "} $Gui(WLA)

        eval {entry $f.e${slider} -textvariable Matrix(regRot${slider}) \
                -width 7} $Gui(WEA)
        bind $f.e${slider} <Return> \
                "AlignmentsManualRotate regRot${slider}"
        bind $f.e${slider} <FocusOut> \
                "AlignmentsManualRotate regRot${slider}"

        eval {scale $f.s${slider} -from -180 -to 180 -length 120 \
                -command "AlignmentsManualRotate regRot${slider}" \
                -variable Matrix(regRot${slider}) -resolution 0.1 -digits 5} $Gui(WSA)

        grid $f.l${slider} $f.e${slider} $f.s${slider} -pady 2
    }

    #-------------------------------------------
    # Manual->Global/Local Frame
    #-------------------------------------------
    set f $fManual.fGlobalLocal

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side left -pady $Gui(pad) -padx 1

    eval {label $f.fTitle.l -text "Move Reference: "} $Gui(WLA)
    pack $f.fTitle.l

    foreach text "Global Local" value "Post Pre" \
            width "6 6" {
        eval {radiobutton $f.fBtns.rSpeed$value -width $width \
                -text "$text" -value $value -variable Matrix(refCoordinate) \
                -command "AlignmentsSetReferenceCoordinates $value" \
                -indicatoron 0} $Gui(WRA)
        pack $f.fBtns.rSpeed$value -side left -padx 0 -pady 0
        TooltipAdd  $f.fBtns.rSpeed$value  \
                "Translations and Rotations sliders apply with respect to $text coordinates."

    }

    #-------------------------------------------
    # Manual->Mouse Frame
    #-------------------------------------------
    set f $fManual.fMouse

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side left -pady $Gui(pad) -padx 1

    eval {label $f.fTitle.l -text "Mouse Action: "} $Gui(WLA)
    pack $f.fTitle.l

    foreach text "Translate Rotate" value "Translate Rotate" \
            width "10 7" {
        eval {radiobutton $f.fBtns.rSpeed$value -width $width \
                -text "$text" -value "$value" -variable Matrix(mouse) \
                -indicatoron 0} $Gui(WRA)
        pack $f.fBtns.rSpeed$value -side left -padx 0 -pady 0
        TooltipAdd  $f.fBtns.rSpeed$value  \
                "$value volumes in the Slice Window"

    }

    #-------------------------------------------
    # Auto frame
    #-------------------------------------------
    set fAuto $Module(Alignments,fAuto)
    set f $fAuto

    #Frames
    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fMid -bg $Gui(activeWorkspace) -relief sunken -bd 2
    frame $f.fBot  -bg $Gui(activeWorkspace) -height 1000
    pack $f.fTop $f.fMid $f.fBot -side top -pady $Gui(pad) -padx $Gui(pad) -fill x -expand 1

    #-------------------------------------------
    # Auto->Bot frame
    #-------------------------------------------
    set f $fAuto.fBot

    #Frames for FidAlign, TPS and Intensity and a "choose alignment" screen
    # took out TPS
    foreach type "AlignBegin FidAlign Intensity" {
        frame $f.f${type} -bg $Gui(activeWorkspace)
        place $f.f${type} -in $f -relheight 1.0 -relwidth 1.0
        set Matrix(f${type}) $f.f${type}
    }
    raise $Matrix(fAlignBegin)

    #-------------------------------------------
    # Auto->Top frame
    #-------------------------------------------
    set f $fAuto.fTop

    frame $f.fActive -bg $Gui(backdrop)
    frame $f.fVolumes -bg $Gui(backdrop)
    pack $f.fActive $f.fVolumes -side top -padx $Gui(pad) -pady 2 -expand 1 -fill x

    #-------------------------------------------
    # Auto->Top->Active frame
    #-------------------------------------------
    set f $fAuto.fTop.fActive

    eval {label $f.lActive -text "Active Matrix: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Matrix(mbActiveList) $f.mbActive
    lappend Matrix(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Auto->Volumes frame
    #-------------------------------------------
    set f $fAuto.fTop.fVolumes

    eval {label $f.lVolume -text "Volume to Move:"} $Gui(BLA)
    eval {menubutton $f.mbVolume -text "None" \
            -relief raised -bd 2 -width 15 -menu $f.mbVolume.m} $Gui(WMBA)
    eval {menu $f.mbVolume.m} $Gui(WMA)

    eval {label $f.lRefVolume -text "Reference Volume:"} $Gui(BLA)
    eval {menubutton $f.mbRefVolume -text "None" \
            -relief raised -bd 2 -width 15 -menu $f.mbRefVolume.m} $Gui(WMBA)
    eval {menu $f.mbRefVolume.m} $Gui(WMA)

    grid $f.lVolume $f.mbVolume -sticky e -padx $Gui(pad) -pady $Gui(pad)
    grid $f.mbVolume -sticky e

    grid $f.lRefVolume $f.mbRefVolume -sticky e -padx $Gui(pad) -pady $Gui(pad)
    grid $f.mbRefVolume -sticky e

    # Append widgets to list that gets refreshed during UpdateMRML
    set Matrix(mbVolume) $f.mbVolume
    set Matrix(mbRefVolume) $f.mbRefVolume

    #-------------------------------------------
    # Auto->Mid frame
    #------------------------------------------
    set f $fAuto.fMid

    frame $f.fType -bg $Gui(activeWorkspace) -bg $Gui(backdrop) -relief sunken
    pack $f.fType -side top -fill x -expand 1

    #-------------------------------------------
    # Auto->Mid->Type frame
    #-------------------------------------------
    set f $fAuto.fMid.fType

    eval {label $f.l -text "Registration Mode:"} $Gui(BLA)
    frame $f.fmodes -bg $Gui(backdrop)
    # took out TPS
    foreach mode "FidAlign Intensity" text "Fiducials Intensity" {
        eval {radiobutton $f.fmodes.r$mode \
            -text "$text" -command "AlignmentsSetRegistrationMode" \
            -variable Matrix(regMode) -value $mode -width 10 \
            -indicatoron 0} $Gui(WRA)
        set Matrix(r${mode}) $f.fmodes.r$mode
        pack $f.fmodes.r$mode -side left -padx $Gui(pad) -fill x -expand 1
    }
    pack $f.l -side top -fill x -expand 1
    pack $f.fmodes -side left -padx $Gui(pad) -fill x -anchor w -expand 1

    #-------------------------------------------
    # Auto->Bot->AlignBegin Frame
    #-------------------------------------------
    set f $fAuto.fBot.fAlignBegin

    eval {label $f.fTitle -text "Select a Registration mode\n\ using the buttons above"} $Gui(WLA)
    pack $f.fTitle -pady 60

    frame $f.fColorCorresp -bg $Gui(activeWorkspace) -bd 2
    pack $f.fColorCorresp -fill x -side top -padx 0 -pady 0 -expand 1
    set f $f.fColorCorresp

    eval {checkbutton $f.cColorCorresp -variable Matrix(colorCorresp) \
          -text "View Color Correspondence" -command "AlignmentsSetColorCorrespondence" \
          -indicatoron 0} $Gui(WCA)

    #If in the future "Ocean" and "Desert" LUT names change, then change this tooltip
    TooltipAdd $f.cColorCorresp "
    Press this button to turn on or off the colors that are applied to the reference volume and the volume to move.

    When the button is on, the reference volume is colored blue and the volume to move is colored red. Pink indicates the amount of convergence between the two volumes when they are overlayed.

    When the button is off, the reference volume and the volume to move are returned to greyscale."

    pack $f.cColorCorresp -pady 20

    #-------------------------------------------
    # Auto->Bot->FidAlign Frame
    #-------------------------------------------
    set f $fAuto.fBot.fFidAlign

    frame $f.fFidViewParams -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fFidLists -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fApply -bg $Gui(activeWorkspace)

    pack $f.fFidViewParams $f.fFidLists $f.fApply \
        -side top -fill x -pady $Gui(pad) -expand 1

    #-------------------------------------------
    # Auto->Bot->FidViewParams Frame
    #-------------------------------------------
    set f $fAuto.fBot.fFidAlign.fFidViewParams

    eval {label $f.fTitle -text "Viewing Parameters: "} $Gui(WLA)

    eval {checkbutton $f.cLeftView -variable Matrix(mainview,visibility) \
          -text "None" -command "AlignmentsUpdateMainViewVisibility; AlignmentsFidAlignViewUpdate" \
          -indicatoron 1} $Gui(WCA)

    eval {checkbutton $f.cRightView -variable Matrix(matricesview,visibility) \
          -text "None" -command "AlignmentsUpdateFidAlignViewVisibility; AlignmentsFidAlignViewUpdate" \
          -indicatoron 1} $Gui(WCA)

    grid $f.fTitle -pady 2
    grid $f.cLeftView $f.cRightView -sticky w

    set Matrix(viewRefVol) $f.cLeftView
    set Matrix(viewVolToMove) $f.cRightView

    #-------------------------------------------
    # Auto->Bot->FidLists Frame
    #-------------------------------------------
    set f $fAuto.fBot.fFidAlign.fFidLists

    eval {label $f.l -text "Fiducial XYZ Coordinates"} $Gui(WTA)
    eval {button $f.bhow -width 38 -text "How To Add Fiducials"} $Gui(WBA)

    TooltipAdd $f.bhow "$Fiducials(howto)"

    frame $f.fListMenus -bg $Gui(activeWorkspace)
    set f $f.fListMenus

    eval {menubutton $f.mbFidRefVolume -text $Matrix(FidAlignRefVolumeName) \
              -relief raised -bd 2 -width 16 -menu $f.mbFidRefVolume.m} $Gui(WMBA)
    eval {menu $f.mbFidRefVolume.m} $Gui(WMA)
    $f.mbFidRefVolume.m add cascade -label "Load Fiducials List.." -menu $f.mbFidRefVolume.m.sub
    menu $f.mbFidRefVolume.m.sub -tearoff 0

    eval {menubutton $f.mbFidVolume -text $Matrix(FidAlignVolumeName) \
              -relief raised -bd 2 -width 16 -menu $f.mbFidVolume.m} $Gui(WMBA)
    eval {menu $f.mbFidVolume.m} $Gui(WMA)
    $f.mbFidVolume.m add cascade -label "Load Fiducials List.." -menu $f.mbFidVolume.m.sub
    menu $f.mbFidVolume.m.sub -tearoff 0

    set f $fAuto.fBot.fFidAlign.fFidLists
    pack $f.l $f.bhow $f.fListMenus -side top -pady 2 -padx $Gui(pad)

    set f $f.fListMenus
    grid $f.mbFidRefVolume $f.mbFidVolume

    #Save paths so that the names of the buttons can be configured when the volumes are chosen
    set Matrix(mbFidVolume) $f.mbFidVolume
    set Matrix(mbFidRefVolume) $f.mbFidRefVolume

    set f $fAuto.fBot.fFidAlign.fFidLists
    #The frames in which the point boxes listing the fiducial coordinates will be displayed
    frame $f.fPointBoxes -bg $Gui(activeWorkspace)
    pack $f.fPointBoxes -side top -pady 2
    set Matrix(FidPointBoxes) $f.fPointBoxes
    frame $Matrix(FidPointBoxes).fRefVolumePoints -bg $Gui(activeWorkspace)
    frame $Matrix(FidPointBoxes).fVolumePoints -bg $Gui(activeWorkspace)
    grid $Matrix(FidPointBoxes).fRefVolumePoints $Matrix(FidPointBoxes).fVolumePoints

    #Save the paths to the frames so we can add/remove the boxes to them when fiducials are updated
    set Matrix(FidRefVolPointBoxes) $Matrix(FidPointBoxes).fRefVolumePoints
    set Matrix(FidVolPointBoxes) $Matrix(FidPointBoxes).fVolumePoints

    #-------------------------------------------
    # Auto->Bot->FidLists->Apply frame
    #-------------------------------------------
    set f $fAuto.fBot.fFidAlign.fApply

    #Align the Datasets based on the fiducial sets chosen
    DevAddButton $f.bApply "Apply" "AlignmentsFidAlignApply" 8

    #Clear the Fiducial lists
    DevAddButton $f.bCancel "Cancel" "AlignmentsFidAlignCancel" 8

    grid $f.bApply $f.bCancel -padx $Gui(pad)

    if {0} {
        # don't build the frame contents, put it back in when it works
    #-------------------------------------------
    # Auto->Bot->TPS Frame
    #-------------------------------------------
    set f $fAuto.fBot.fTPS

    frame $f.fTPSNotAvail -bg $Gui(activeWorkspace) -relief groove
    #frame $f.fTPSFidPoints -bg $Gui(activeWorkspace) -relief groove -bd 2
    #frame $f.fTPSVolume -bg $Gui(activeWorkspace) -relief groove -bd 2
    #frame $f.fTPSOptions -bg $Gui(activeWorkspace) -relief groove -bd 2 
    #frame $f.fTPSOutputSliceRange -bg $Gui(activeWorkspace) -relief groove -bd 2
    #frame $f.fTPSWarp -bg $Gui(activeWorkspace)
    #frame $f.fTPSSaveVolume -bg $Gui(activeWorkspace)

    pack $f.fTPSNotAvail -pady 80
    #pack $f.fTPSFidPoints $f.fTPSVolume $f.fTPSOptions $f.fTPSOutputSliceRange \n
    # $f.fTPSWarp $f.fTPSSaveVolume #-side top -pady 2 -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Auto->Bot->TPS->Not Available Currently
    #-------------------------------------------
    set f $fAuto.fBot.fTPS.fTPSNotAvail
    eval {label $f.lTPSNotAvail -text "TPS is currently not\n\ available in this\n\ version"} $Gui(WLA)

    pack $f.lTPSNotAvail

    #-------------------------------------------
    # Auto->Bot->TPS->Volume frame
    #-------------------------------------------
    #set f $fAuto.fBot.fTPS.fTPSVolume

    #Allow the user to create a new volume to store the warped volume.
    #frame $f.fTPSNewVolume -bg $Gui(activeWorkspace)
    #pack $f.fTPSNewVolume -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w

    #eval {label $f.fTPSNewVolume.lLabel -text "Generate New Volume Using TPS:"} $Gui(WLA) -foreground blue
    #pack  $f.fTPSNewVolume.lLabel -pady 2 -anchor w

    #eval {label $f.fTPSNewVolume.lName -text "Name: "} $Gui(WLA)
    #eval {entry $f.fTPSNewVolume.eName -textvariable $Matrix(TPSVolumeName) -width 13} $Gui(WEA)
    #pack $f.fTPSNewVolume.lName -side left -pady $Gui(pad)
    #pack $f.fTPSNewVolume.eName -side left -padx $Gui(pad) -expand 1 -fill x


    #Allow the user to pick a target volume in which to save the warped volume.
    #frame $f.fTPSTargetVolume -bg $Gui(activeWorkspace)

    #In the callback command make sure you add this to menubutton "target volume"
    #eval {label $f.fTPSTargetVolume.lTargetVolume -text "Target Volume: "} $Gui(WLA)
    #eval {menubutton $f.fTPSTargetVolume.mbTargetVolume -text "Matrix(TpsTargetVolume)" \
    #      -relief raised -bd 2 -width 20 \
    #     -menu $f.fTPSTargetVolume.mbTargetVolume.m} $Gui(WMBA)
    #eval {menu $f.fTPSTargetVolume.mbTargetVolume.m} $Gui(WMA)

    #pack $f.fTPSTargetVolume -side top -pady $Gui(pad) -padx $Gui(pad)
    #pack $f.fTPSTargetVolume.lTargetVolume $f.fTPSTargetVolume.mbTargetVolume -side left -padx 1

    #-------------------------------------------
    # TPS->TPS Options frame
    #-------------------------------------------
    #set f  $fAuto.fBot.fTPS.fTPSOptions

    #eval {label $f.lTitle -text "TPS Parameters:"} $Gui(WLA) -foreground blue
    #pack $f.lTitle -padx $Gui(pad) -pady 4 -anchor w
    #set Matrix(gui,test) $f.lTitle

    ###Basis###
    #frame $f.fBasisMode -bg $Gui(activeWorkspace)
    #eval {label $f.fBasisMode.lBasisMode -text "Basis Function: "} $Gui(WLA)
    #eval {menubutton $f.fBasisMode.mbBasisMode -text "Matrix(TpsBasisMode)" \
    #      -relief raised -bd 2 -width 20 \
    #     -menu $f.fBasisMode.mbBasisMode.m} $Gui(WMBA)
    #eval {menu $f.fBasisMode.mbBasisMode.m} $Gui(WMA)

    #pack $f.fBasisMode -side top -pady $Gui(pad) -padx $Gui(pad)
    #pack $f.fBasisMode.lBasisMode $f.fBasisMode.mbBasisMode -side left -padx 1

    # Add menu items
    #foreach mode {r r*r} {
    #$f.fBasisMode.mbBasisMode.m add command -label $mode \
    #    -command "AlignmentsWhichCommand; set Matrix(TpsBasisMode) $mode; $f.fBasisMode.mbBasisMode config -text $mode "
    #}

    # save menubutton for config
    # set Matrix(gui,mbBasisMode) $f.mbBasisMode

    ###Fidelity###
    #frame $f.fFidelity -bg $Gui(activeWorkspace)
    #eval {label $f.fFidelity.lFidelity -text "Fidelity: "} $Gui(WLA)
    #eval {entry $f.fFidelity.eFidelity -textvariable Matrix(TpsFidelity) \
    #-width 7} $Gui(WEA)
    #bind $f.fFidelity.eFidelity <Return> "AlignmentsWhichCommand"
    #bind $f.fFidelity.eFidelity <FocusOut> "AlignmentsWhichCommand"

    #eval {scale $f.fFidelity.sFidelity -from 0 -to 1 -length 100 \
    #      -command "AlignmentsWhichCommand" \
    #     -variable Matrix(TpsFidelity) -resolution 0.01 -digits 3} $Gui(WSA)

    #pack $f.fFidelity -side top -pady 2 -padx $Gui(pad)
    #grid $f.fFidelity.lFidelity $f.fFidelity.eFidelity $f.fFidelity.sFidelity -padx 1 -pady 2

    #-------------------------------------------
    # Auto->Bot->TPS->TPSOutputSliceRange frame
    #-------------------------------------------
    #set f  $fAuto.fBot.fTPS.fTPSOutputSliceRange
    #Output slice range

    #eval {label $f.lRange -text "Output Slice Range: "} $Gui(WLA) -foreground blue
    #pack $f.lRange -padx $Gui(pad) -pady $Gui(pad) -anchor w

    #Beginning of Range
    #frame $f.fFirstSlice -bg $Gui(activeWorkspace)
    #eval {label $f.fFirstSlice.lStartRange -text "First Slice: "} $Gui(WLA)

    #eval {entry $f.fFirstSlice.eOutputRange -textvariable Matrix(TpsStartSliceRange) \
    #     -width 4} $Gui(WEA)
    #bind $f.fFirstSlice.eOutputRange <Return> "AlignmentsWhichCommand"
    #bind $f.fFirstSlice.eOutputRange <FocusOut> "AlignmentsWhichCommand"

    #TBD:change the range to be what the range is for the volume
    #eval {scale $f.fFirstSlice.sOutputRange -from 0 -to 100 -length 100 \
    #      -command "AlignmentsWhichCommand" \
    #     -variable Matrix(TpsStartSliceRange) -resolution 1} $Gui(WSA)
    #pack $f.fFirstSlice -side top -padx $Gui(pad) -anchor w
    #grid $f.fFirstSlice.lStartRange $f.fFirstSlice.eOutputRange \
    #$f.fFirstSlice.sOutputRange -padx 1 -pady 1

    #End of Range
    #frame $f.fLastSlice -bg $Gui(activeWorkspace)
    #eval {label $f.fLastSlice.lEndRange -text "Last Slice: "} $Gui(WLA)

    #eval {entry $f.fLastSlice.eOutputRange -textvariable Matrix(TpsEndSliceRange) \
    #     -width 4} $Gui(WEA)
    #bind $f.fLastSlice.eOutputRange <Return> "AlignmentsWhichCommand"
    #bind $f.fLastSlice.eOutputRange <FocusOut> "AlignmentsWhichCommand"

    #TBD:change the range
    #eval {scale $f.fLastSlice.sOutputRange -from 0 -to 100 -length 100 \
    #      -command "AlignmentsWhichCommand" \
    #     -variable Matrix(TpsEndSliceRange) -resolution 1} $Gui(WSA)
    #pack $f.fLastSlice -padx $Gui(pad) -anchor w
    #grid $f.fLastSlice.lEndRange $f.fLastSlice.eOutputRange \
    #$f.fLastSlice.sOutputRange -padx 1

    #-------------------------------------------
    # Auto->Bot->TPS->TPSFidPointsFrame
    #-------------------------------------------
    #These are separate from the Points on the FidAlign Screen
    #since the two methods are independent of one another

    #set f $fAuto.fBot.fTPS.fTPSFidPoints

    #eval {label $f.l -text "Fiducial XYZ Coordinates for TPS:"} $Gui(WTA) -foreground blue
    #eval {button $f.bhow -width 38 -text "How To Add Fiducials"} $Gui(WBA)

    #frame $f.fListMenus -bg $Gui(activeWorkspace)
    #I made these buttons just because they looked nicer
    #eval {button $f.fListMenus.bFidRefVolume -text $Matrix(FidAlignRefVolumeName) \
    #         -relief raised -bd 2 -width 14} $Gui(WMBA)

    #eval {button $f.fListMenus.bFidVolume -text $Matrix(FidAlignVolumeName) \
     #         -relief raised -bd 2 -width 14} $Gui(WMBA)

    #pack $f.l $f.bhow $f.fListMenus -side top -pady 2 -padx $Gui(pad)
    #grid $f.fListMenus.bFidRefVolume $f.fListMenus.bFidVolume

    #Save paths for later
    #set Matrix(bTPSVolume) $f.fListMenus.bFidVolume
    #set Matrix(bTPSRefVolume) $f.fListMenus.bFidRefVolume

    #TooltipAdd $f.bhow "$Fiducials(howto)"

    #frame $f.fPointBoxes -bg $Gui(activeWorkspace)
    #pack $f.fPointBoxes -side top -pady 2 -padx $Gui(pad)

    #set Matrix(TPSPointBoxes) $f.fPointBoxes
    #frame $Matrix(TPSPointBoxes).fRefVolumePoints -bg $Gui(activeWorkspace)
    #frame $Matrix(TPSPointBoxes).fVolumePoints -bg $Gui(activeWorkspace)
    #grid $Matrix(TPSPointBoxes).fRefVolumePoints $Matrix(TPSPointBoxes).fVolumePoints

    #set Matrix(TPSRefVolPointBoxes) $Matrix(TPSPointBoxes).fRefVolumePoints
    #set Matrix(TPSVolPointBoxes) $Matrix(TPSPointBoxes).fVolumePoints

    #-------------------------------------------
    # Auto->Bot->TPS->TPSWarp Frame
    #-------------------------------------------
    #set f   $fAuto.fBot.fTPS.fTPSWarp

    #eval {button $f.bWarp -text "Warp" \
    #      -command "AlignmentsWhichCommand"} $Gui(WBA) {-width 10}
    #eval {button $f.bCancel -text "Cancel" \
    #      -command "AlignmentsFidAlignCancel"} $Gui(WBA) {-width 10}
    #grid $f.bWarp $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Auto->Bot->TPS->TPSSaveVolume Frame
    #-------------------------------------------
    #set f $fAuto.fBot.fTPS.fTPSSaveVolume

    #TBD:should you have something here that says "as target volume?"
    #TBD:Include an error that pops up if the user has not selected the fiducial points
    #eval {button $f.bSave -text "Save Warped Volume" \
     #  -command "AlignmentsWhichCommand"} $Gui(WBA) {-width 20}
    #pack $f.bSave -padx $Gui(pad) -pady $Gui(pad)
}

    #-------------------------------------------
    # Auto->Bot->Intensity Frame
    #-------------------------------------------
    set f $fAuto.fBot.fIntensity

    ##
    ## If the MutualInfoReg Module exists, use it
    ##
    ## Otherwise, don't use it.

    set ret [catch "package require vtkRigidIntensityRegistration" res]

    if { $ret } {
        DevAddLabel $f.lbadnews "I'm sorry but the \n RigidIntensityRegistration Module\n is not loaded so that Automatic \nRegistration is not available."
        pack $f.lbadnews -pady $Gui(pad)
    } else {
        RigidIntensityRegistrationBuildSubGui $f
    }

    #-------------------------------------------
    # Minimized Slice Controls used to switch
    # between volumes when the screen is split
    # for FidAlign.
    #-------------------------------------------
    frame $Gui(fViewer).fMatMid -bg $Gui(backdrop)

    # Minimized Slice Controls displayed in Normal view
    set Gui(fMatMid) $Gui(fViewer).fMatMid
    set f $Gui(fMatMid)
    foreach s $Slice(idList) {
        frame $f.fMatMidSlice$s -bg $Gui(activeWorkspace)
        pack $f.fMatMidSlice$s -side left -expand 1 -fill both
        AlignmentsBuildMinimizedSliceControls $s $f.fMatMidSlice$s
    }
    # Minimized Thumb Slice Controls for the 4x512 views etc.
    AlignmentsBuildMinimizedSliceThumbControls

    # Active Volume Select buttons displayed on Mimimized Slice Controls
    frame $Gui(fViewer).fMatVol -bg $Gui(backdrop)
    set Gui(fMatVol) $Gui(fViewer).fMatVol
    AlignmentsBuildActiveVolSelectControls
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsBuildVTK
#
# The following vtk objects needed to be created in order to display the volumes
# separately in two different renderers when wanting to align two datasets using
# corresponding fiducial points (aka. FidAlign). When the user enters FidAlign,
# the fore layer of vtkMrmlSlicer object "Slicer" is set to what the user chose
# as the reference volume and the "back" layer of the vtkMrmlSlicer object Slicer
# is set to what the user chose as the volume to register. A new vtkMrmlSlicer
# object created here (called MatSlicer) is then set to be the exact replica of
# the Slicer object at this point. The reason for creating these separate
# vtkMrmlSlicer objects was so that the user could interact with the
# datasets independently of one another. If the same slicer object was displayed
# in both of the renderers, then there occurred the problem that the data was
# being reformatted using the same matrix. This caused a problem when wanting to
# change the Slice information (offsets/orientations) of one volume but not the
# other in FidAlign.
# So the output of the vtkMrmlSlicer Slicer object is then texture mapped onto
# the three new slice actors (which are created here) and the output of the
# vtkMrmlSlicer object matSlicer is texture mapped onto separate three
# new slice actors (which are also created here). The Slicer object slice actors
# are displayed in the viewRen (the renderer on the left side when the screen
# is split) and the MatSlicer object slice actors are displayed in the MatRen
# (the renderer on the right hand side when the screen is split).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsBuildVTK {} {
    global Matrix Slice View Volume

    #VTKMRMLSLICER
    #Create a new vtkMrmlSlicer object so that two volumes can be interacted with
    #independent of one another. The active Slicer is initially Slicer and only
    #set to be any other slicer when the fiducial selection mode is entered
    vtkMrmlSlicer MatSlicer

    #MATREN
    #I moved this to MatricesInit because Im using the same bounding box in the
    #3d view as for the viewRen (to avoid duplication of more code) and so if
    #creating this renderer here then the bounding box doesnt get added to the
    #new renderer.
    #Create a new renderer in order to display the split view showing two volumes
    #vtkRenderer matRen
    #lappend Module(Renderers) matRen
    #Camera for the new Renderer
    set View(MatCam) [matRen GetActiveCamera]
    #add the R A S L P I actors to the new renderer
    AlignmentsAddLetterActors

    #SLICEACTORS
    foreach slicer "Slicer MatSlicer" {
        foreach s $Slice(idList) {
            MainSlicesBuildVTKForSliceActor $s,$slicer
            Slice($s,$slicer,planeActor) SetUserMatrix [$slicer GetReformatMatrix $s]
            Slice($s,$slicer,planeMapper) SetInput [Slice($s,$slicer,planeSource) GetOutput]
            Slice($s,$slicer,planeActor) SetTexture Slice($s,$slicer,texture)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetVolumeMatrix
#
# Copy one of the matrices derived from the header of a volume
# .ARGS
# type The type of matrix to be copied - ie. RAS->IJK, RAS->VTK, ScaledIJK->RAS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetVolumeMatrix {type} {
    global Matrix

    set Matrix(volumeMatrix) $type

    # update the button text
    $Matrix(mbVolumeMatrix) config -text $type
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsIdentity
#
#  Resets the transformation to the identity, i.e. to the transform with
#  no effect.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsIdentity {} {
    global Matrix

    set m $Matrix(activeID)
    if {$m == ""} {return}

    [Matrix($m,node) GetTransform] Identity
    set Matrix(rotAxis) "XX"
    set Matrix(regRotLR) 0.00
    set Matrix(regRotIS) 0.00
    set Matrix(regRotPA) 0.00
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsInvert
#
# Replaces the current transform with its inverse.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsInvert {} {
    global Matrix

    set m $Matrix(activeID)
    if {$m == ""} {return}

    [Matrix($m,node) GetTransform] Inverse
    set Matrix(rotAxis) "XX"
    set Matrix(regRotLR) 0.00
    set Matrix(regRotIS) 0.00
    set Matrix(regRotPA) 0.00
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetReferenceCoordinates 
#
# Set transform to either premultiply or postmultiply
#
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetReferenceCoordinates
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetReferenceCoordinates { {prepost ""} } {
    global Matrix

    if { $prepost == "" } {
        set prepost $Matrix(refCoordinate) 
    } else {
        set Matrix(refCoordinate) $prepost
    }

    if { $Matrix(activeID) != "" } {
        set t $Matrix(activeID)
        set tran [Matrix($t,node) GetTransform]
        $tran ${prepost}Multiply
    }
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsSetPropertyType
#
# Display the basic or advanced frame depending on user selection
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetPropertyType {} {
    global Matrix

    raise $Matrix(f$Matrix(propertyType))
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsPropsApply
#
# Apply the Transform
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsPropsApply {} {
    global Matrix Label Module Mrml Volume

    # none?
    if {$Matrix(activeID) != "NEW" && $Matrix(idList) == ""} {
        tk_messageBox -message "Please create a matrix first from the Data panel"
        Tab Data row1 List
    }

    # Validate Input
    AlignmentsValidateMatrix

    # Validate name
    if {$Matrix(name) == ""} {
        tk_messageBox -message "Please enter a name that will allow you to distinguish this matrix."
        return
    }
    if {[ValidateName $Matrix(name)] == 0} {
        tk_messageBox -message "The name can consist of letters, digits, dashes, or underscores"
        return
    }

    set m $Matrix(activeID)
    if {$m == ""} {return}

    if {$m == "NEW"} {
        set i $Matrix(nextID)
        incr Matrix(nextID)
        lappend Matrix(idList) $i
        vtkMrmlMatrixNode Matrix($i,node)
        set n Matrix($i,node)
        $n SetID $i

        # These get set down below, but we need them before MainUpdateMRML
        $n SetName $Matrix(name)

        Mrml(dataTree) AddItem $n
        MainUpdateMRML
        set Matrix(freeze) 0
        MainAlignmentsSetActive $i
        set m $i
    }

    # If user wants to use the matrix from a volume, set it here
    set v $Volume(activeID)
    switch $Matrix(volumeMatrix) {
        "None" {}
        "ScaledIJK->RAS" {
            AlignmentsSetMatrix [Volume($v,node) GetPositionMatrix]
        }
        "RAS->IJK" {
            AlignmentsSetMatrix [Volume($v,node) GetRasToIjkMatrix]
        }
        "RAS->VTK" {
            AlignmentsSetMatrix [Volume($v,node) GetRasToVtkMatrix]
        }
    }

    Matrix($m,node) SetName $Matrix(name)
    AlignmentsSetMatrixIntoNode $m

    # Return to Basic
    if {$Matrix(propertyType) == "Advanced"} {
        set Matrix(propertyType) Basic
        AlignmentsSetPropertyType
    }

    # If tabs are frozen, then
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }

    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsPropsCancel
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsPropsCancel {} {
    global Matrix Module

    # Reset props
    set m $Matrix(activeID)
    if {$m == "NEW"} {
        set m [lindex $Matrix(idList) 0]
    }
    set Matrix(freeze) 0
    MainAlignmentsSetActive $m

    # Return to Basic
    if {$Matrix(propertyType) == "Advanced"} {
        set Matrix(propertyType) Basic
        AlignmentsSetPropertyType
    }

    # Unfreeze
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsManualTranslate
#
# Adjusts the "translation part" of the transformation matrix.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsManualTranslate {param {value ""}} {
    global Matrix

    # Value is blank if used entry field instead of slider
    if {$value == ""} {
        set value $Matrix($param)
    } else {
        set Matrix($param) $value
    }

    # Validate input
    if {[ValidateFloat $value] == 0} {
        tk_messageBox -message "$value must be a floating point number"
        return
    }

    # If there is no active transform, then do nothing
    set t $Matrix(activeID)
    if {$t == "" || $t == "NEW"} {return}

    # Transfer values from GUI to active transform
    set tran [Matrix($t,node) GetTransform]
    set mat  [$tran GetMatrix]

    switch $param {
        "regTranLR" {
            set oldVal [$mat GetElement 0 3]
        }
        "regTranPA" {
            set oldVal [$mat GetElement 1 3]
        }
        "regTranIS" {
            set oldVal [$mat GetElement 2 3]
        }
    }

    # Update all MRML only if the values changed
    if {$oldVal != $value} {
        set delta [expr $value - $oldVal]
        switch $param {
            "regTranLR" {
                $tran Translate $delta 0 0
            }
            "regTranPA" {
                $tran Translate 0 $delta 0
            }
            "regTranIS" {
                $tran Translate 0 0 $delta
            }
        }
        set Matrix(rotAxis) "XX"
        set Matrix(regRotLR) 0
        set Matrix(regRotIS) 0
        set Matrix(regRotPA) 0
        MainUpdateMRML
        Render$Matrix(render)
    }

}

#-------------------------------------------------------------------------------
# .PROC AlignmentsManualTranslateDual
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsManualTranslateDual {param1 value1 param2 value2} {
    global Matrix

    # Validate input
    if {[ValidateFloat $value1] == 0} {
        tk_messageBox -message "$value1 must be a floating point number"
        return
    }
    if {[ValidateFloat $value2] == 0} {
        tk_messageBox -message "$value2 must be a floating point number"
        return
    }


    # Value is blank if used entry field instead of slider
    set Matrix($param1) $value1
    set Matrix($param2) $value2

    # If there is no active transform, then do nothing
    set t $Matrix(activeID)
    if {$t == "" || $t == "NEW"} {return}

    # Transfer values from GUI to active transform
    set tran [Matrix($t,node) GetTransform]
    set mat  [$tran GetMatrix]

    switch $param1 {
        "regTranLR" {
            set oldVal1 [$mat GetElement 0 3]
        }
        "regTranPA" {
            set oldVal1 [$mat GetElement 1 3]
        }
        "regTranIS" {
            set oldVal1 [$mat GetElement 2 3]
        }
    }
    switch $param2 {
        "regTranLR" {
            set oldVal2 [$mat GetElement 0 3]
        }
        "regTranPA" {
            set oldVal2 [$mat GetElement 1 3]
        }
        "regTranIS" {
            set oldVal2 [$mat GetElement 2 3]
        }
    }

    # Update all MRML only if the values changed
    if {$oldVal1 != $value1} {
        set delta [expr $value1 - $oldVal1]
        switch $param1 {
            "regTranLR" {
                $tran Translate $delta 0 0
            }
            "regTranPA" {
                $tran Translate 0 $delta 0
            }
            "regTranIS" {
                $tran Translate 0 0 $delta
            }
        }
    }
    if {$oldVal2 != $value2} {
        set delta [expr $value2 - $oldVal2]
        switch $param2 {
            "regTranLR" {
                $tran Translate $delta 0 0
            }
            "regTranPA" {
                $tran Translate 0 $delta 0
            }
            "regTranIS" {
                $tran Translate 0 0 $delta
            }
        }
    }

    if {$oldVal2 != $value2 || $oldVal1 != $value1} {
        set Matrix(rotAxis) "XX"
        set Matrix(regRotLR) 0
        set Matrix(regRotIS) 0
        set Matrix(regRotPA) 0
        MainUpdateMRML
        if {$Matrix(render) == "All"} {
            Render3D
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsManualRotate
#
# Adjusts the "rotation part" of the transformation matrix.
# If the previous manual adjustment to the transform was a rotation
# about the same axis as the current adjustment, then only the change
# in the degrees specified is applied.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsManualRotate {param {value ""} {mouse 0}} {
    global Matrix

    #
    # catch a callback loop caused when updating the scale and entry
    # widgets for the rotation - set the inManualRotate flag here
    # and reset it at the end of the proc
    #
    if { ![info exists Matrix(inManualRotate)] } {
        set Matrix(inManualRotate) 0
    } 
    if { $Matrix(inManualRotate) } {
        if { $::Module(verbose) } {
            puts "********************** already in manual rotate - returning"
        }
        return
    } 
    set Matrix(inManualRotate) 1


    # "value" is blank if used entry field instead of slider
    if {$value == ""} {
        set value $Matrix($param)
    } else {
        set Matrix($param) $value
    }

    # Validate input
    if {[ValidateFloat $value] == 0} {
        tk_messageBox -message "$value must be a floating point number"
        set Matrix(inManualRotate) 0
        return
    }

    # If there is no active transform, then do nothing
    set t $Matrix(activeID)
    if {$t == "" || $t == "NEW"} {
        set Matrix(inManualRotate) 0
        return
    }

    # If this is a different axis of rotation than last time,
    # then store the current transform in "Matrix(rotMatrix)"
    # so that the user's rotation can be concatenated with this matrix.
    # This way, this routine can be called with angles of 35, 40, 45,
    # and the second rotation will produce a visible change of
    # 5 degrees instead of 40.
    #
    set axis [string range $param 6 7]
    if {$axis != $Matrix(rotAxis)} {
        [Matrix($t,node) GetTransform] GetMatrix Matrix(rotMatrix)
        set Matrix(rotAxis) $axis
        # O-out the rotation in the other 2 axes
        switch $axis {
            "LR" {
                set Matrix(regRotPA) 0
                set Matrix(regRotIS) 0
            }
            "PA" {
                set Matrix(regRotLR) 0
                set Matrix(regRotIS) 0
            }
            "IS" {
                set Matrix(regRotPA) 0
                set Matrix(regRotLR) 0
            }
        }
    }

    # Now, concatenate the rotation with the stored transform
    set tran [Matrix($t,node) GetTransform]
    $tran SetMatrix Matrix(rotMatrix)
    switch $param {
        "regRotLR" {
            $tran RotateX $value
        }
        "regRotPA" {
            $tran RotateY $value
        }
        "regRotIS" {
            $tran RotateZ $value
        }
    }

    # Only UpdateMRML if the transform changed
    # check first that the transform exists
    if {[info command Matrix($t,transform)] == ""} {
        set differ 1
        if {$::Module(verbose)} {
            DevErrorWindow "Alignments.tcl: WARNING: Matrix($t,transform) does not exist, skipping comparison of matrices"
        }
        puts "Alignments.tcl: WARNING: Matrix($t,transform) does not exist, skipping comparison of matrices"
    } else {
        set mat1 [Matrix($t,transform) GetMatrix]
        set mat2 [[Matrix($t,node) GetTransform] GetMatrix]
        set differ 0
        for {set i 0} {$i < 4} {incr i} {
            for {set j 0} {$j < 4} {incr j} {
                if {[$mat1 GetElement $i $j] != [$mat2 GetElement $i $j]} {
                    set differ 1
                }
            }
        }
    }
    if {$differ == 1} {
        [Matrix($t,node) GetTransform] DeepCopy $tran
        MainUpdateMRML
        if {$mouse == 1} {
            if {$Matrix(render) == "All"} {
                Render3D
            }
        } else {
            Render$Matrix(render)
        }
    }
    set Matrix(inManualRotate) 0
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetRefVolume
#
# .ARGS
# vtkMrmlVolumeNode v is the vtkMrmlVolumeNode to set or get
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetRefVolume {{v ""}} {
    global Matrix Volume

    if {$v == ""} {
        set v $Matrix(refVolume)
    } else {
        set Matrix(refVolume) $v
    }

    #Display what the user picked from the menu as the reference volume
    $Matrix(mbRefVolume) config -text "[Volume($v,node) GetName]"

    #Set Matrix(FidAlignRefVolumeName) to be the name of the reference volume
    set Matrix(FidAlignRefVolumeName) "[Volume($v,node) GetName]"

    #In the FidAlign frame, label the menu button (menu of fiducial Lists)
    #the name of the reference volume
    $Matrix(mbFidRefVolume) config -text "[Volume($v,node) GetName]"

    #In the TPS frame, set the label on the button above the fiducial
    #list for the reference volume
    #$Matrix(bTPSRefVolume) config -text "[Volume($v,node) GetName]"

    #Set the label for the checkbutton that sets the view parameters in FidAlign frame
    $Matrix(viewRefVol) config -text "[Volume($v,node) GetName]"

    #Set the label for the radio button on the minimized slice control panel
    $Matrix(rFidScActivateRefVolume) config  -text "[Volume($v,node) GetName]"

    #Print out what the user has set as the reference volume
    if {$::Module(verbose)} {
        puts "AlignmentsSetRefVolume: this is the refVolumeName: $Matrix(FidAlignRefVolumeName)"
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetVolume
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetVolume {{v ""}} {
    global Matrix Volume

    if {$v == ""} {
        set v $Matrix(volume)
    } else {
        set Matrix(volume) $v
    }

    #Display what the user picked from the menu as the Volume to move
    $Matrix(mbVolume) config -text "[Volume($v,node) GetName]"

    #Set Matrix(FidAlignVolumeName) to be the name of the volume to move
    set Matrix(FidAlignVolumeName) "[Volume($v,node) GetName]"

    #In the FidAlign frame, label the menu button (menu of fiducial Lists)
    #the name of the volume to register
    $Matrix(mbFidVolume) config -text "[Volume($v,node) GetName]"

    #In the TPS frame, set the label on the button above the fiducial list
    #for the reference volume
    #$Matrix(bTPSVolume) config -text "[Volume($v,node) GetName]"

    #Set the label for the checkbutton that sets the view parameters in FidAlign frame
    $Matrix(viewVolToMove) config -text "[Volume($v,node) GetName]"

    #Set the label for the radio button on the minimized slice control panel
    $Matrix(rFidScActivateVolume) config  -text "[Volume($v,node) GetName]"

    #Print out what the user has set as the volume to move
    if {$::Module(verbose)} {
        puts "AlignmentsSetVolume: this is the FidAlignVolumeName: $Matrix(FidAlignVolumeName)"   
    }
}

################################################################################
#                             Event Bindings
################################################################################

#-------------------------------------------------------------------------------
# .PROC AlignmentsB1
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsB1 {x y} {
    global Matrix Slice

    if {$Matrix(FidAlignEntered) != 1} {
        set s $Slice(activeID)
        set orient [Slicer GetOrientString $s]
        if {[lsearch "Axial Sagittal Coronal" $orient] == -1} {
            tk_messageBox -message \
                    "Set 'Orient' to Axial, Sagittal, or Coronal."
            return
        }
        set Matrix(xHome) $x
        set Matrix(yHome) $y

        # Translate
        if {$Matrix(mouse) == "Translate"} {

            Anno($s,msg,mapper) SetInput "0 mm"
            Anno($s,r1,actor)  SetVisibility 1
            Anno($s,r1,source) SetPoint1 $x $y 0
            Anno($s,r1,source) SetPoint2 $x [expr $y+1] 0

            # To make this translation add to the current translation amount,
            # store the current amount.
            set Matrix(prevTranLR) $Matrix(regTranLR)
            set Matrix(prevTranPA) $Matrix(regTranPA)
            set Matrix(prevTranIS) $Matrix(regTranIS)
        }
        # Rotate
        if {$Matrix(mouse) == "Rotate"} {

            Anno($s,msg,mapper) SetInput "0 deg"
            Anno($s,r1,actor)  SetVisibility 1
            Anno($s,r1,source) SetPoint1 128 128 0
            Anno($s,r1,source) SetPoint2 $x $y 0
            Anno($s,r2,actor)  SetVisibility 1
            Anno($s,r2,source) SetPoint1 128 128 0
            Anno($s,r2,source) SetPoint2 $x $y 0
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsB1Motion
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsB1Motion {x y} {
    global Matrix Slice Interactor View Anno

    #If Fiducial selection has been entered then do not allow the user to be able to
    #set the matrix by dragging the mouse over the 2D screens
    if {$Matrix(FidAlignEntered) != 1} {
        # This only works on orthogonal slices
        set s $Slice(activeID)
        set orient [Slicer GetOrientString $s]
        if {[lsearch "Axial Sagittal Coronal" $orient] == -1} {
            return
        }

        # always move in global coordinates when dragging in the slice windows
        set t $Matrix(activeID)
        set tran [Matrix($t,node) GetTransform]
        $tran PostMultiply

        # Translate
        if {$Matrix(mouse) == "Translate"} {

            set xPixels [expr $x - $Matrix(xHome)]
            set yPixels [expr $y - $Matrix(yHome)]
            set xMm [PixelsToMm $xPixels $View(fov) 256 $Slice($s,zoom)]
            set yMm [PixelsToMm $yPixels $View(fov) 256 $Slice($s,zoom)]

            Anno($s,r1,source) SetPoint2 $x $y 0

            switch $orient {
                Axial {
                    # X:R->L, Y:P->A
                    set xMm [expr -$xMm]
                    set text "LR: $xMm, PA: $yMm mm"
                    Anno($s,msg,mapper)  SetInput $text
                    AlignmentsManualTranslateDual \
                            regTranLR [expr $xMm + $Matrix(prevTranLR)] \
                            regTranPA [expr $yMm + $Matrix(prevTranPA)]
                }
                Sagittal {
                    # X:A->P, Y:I->S
                    set xMm [expr -$xMm]
                    set text "PA: $xMm, IS: $yMm mm"
                    Anno($s,msg,mapper)  SetInput $text
                    AlignmentsManualTranslateDual \
                            regTranPA [expr $xMm + $Matrix(prevTranPA)] \
                            regTranIS [expr $yMm + $Matrix(prevTranIS)]
                }
                Coronal {
                    # X:R->L, Y:I->S
                    set xMm [expr -$xMm]
                    set text "LR: $xMm, IS: $yMm mm"
                    Anno($s,msg,mapper)  SetInput $text
                    AlignmentsManualTranslateDual \
                            regTranLR [expr $xMm + $Matrix(prevTranLR)] \
                            regTranIS [expr $yMm + $Matrix(prevTranIS)]
                }
            }
        }

        # Rotate
        if {$Matrix(mouse) == "Rotate"} {

            set degrees [Angle2D 128 128 $Matrix(xHome) $Matrix(yHome) \
                    128 128 $x $y]
            set degrees [expr int($degrees)]
            Anno($s,r2,source) SetPoint2 $x $y 0

            switch $orient {
                Axial {
                    # IS-axis
                    set text "IS-axis: $degrees deg"
                    Anno($s,msg,mapper)  SetInput $text
                    AlignmentsManualRotate regRotIS $degrees 1
                }
                Sagittal {
                    # LR-axis
                    set text "LR-axis: $degrees deg"
                    Anno($s,msg,mapper)  SetInput $text
                    AlignmentsManualRotate regRotLR $degrees 1
                }
                Coronal {
                    # PA-axis
                    set degrees [expr -$degrees]
                    set text "PA-axis: $degrees deg"
                    Anno($s,msg,mapper)  SetInput $text
                    AlignmentsManualRotate regRotPA $degrees 1
                }
            }
        }
        AlignmentsSetReferenceCoordinates 
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsB3Motion
#
# Zooms the 2D slice windows.
# This exists here because the bindings in the original zoom function
# do not allow zooming of the 2d slices for the volume in the matRen when fiducial
# selection is on. This procedure should probably be replaced with pushing and
# popping bindings.
#
# .ARGS
# float x the x position of the mouse cursor where zooming begins
# float y the y position of the mouse cursor where zooming stops
# .END
#-------------------------------------------------------------------------------
proc AlignmentsB3Motion {widget x y} {
    global Interactor View Matrix

#This should work, however the y axis seems to be flipped
#so I am not calling it for now until the problem is fixed
#Therefore you cannot zoom the volume in the MatRen for now
    set s $Interactor(s)
    scan [MainInteractorXY $s $x $y] "%d %d %d %d" xs ys x y

    MatricesInteractorZoom $s $xs $ys $Interactor(xsLast) $Interactor(ysLast)

    # Cursor
    MainInteractorCursor $s $xs $ys $x $y

    set Interactor(xLast)  $x
    set Interactor(yLast)  $y
    set Interactor(xsLast) $xs
    set Interactor(ysLast) $ys

    # Render this slice
    MainInteractorRender
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsInteractorZoom
# This would be called if AlignmentsB3Motion was working
# (see why in AlignmentsSlicesSetZoom)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsInteractorZoom {s x y xLast yLast} {
    global View Interactor Anno

    set dy [expr $yLast - $y]
    # log base b of x = log(x) / log(b)
    set b      1.02

    set zPrev [[$Interactor(activeSlicer) GetBackReformat $s] GetZoom]   
    set dyPrev [expr log($zPrev) / log($b)]

    set zoom [expr pow($b, ($dy + $dyPrev))]
    if {$zoom < 0.01} {
    set zoom 0.01
    }
    set z [format "%.2f" $zoom]

    Anno($s,msg,mapper)  SetInput "ZOOM: x $z"

    AlignmentsSlicesSetZoom $s $z
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetZoom
# Checks to see which vtkMrmlSlicer object is active and sets the zoom factor
# for the slices belonging to that object only.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetZoom {s {zoom}} {
    global Matrix Slice

    # if user-entered zoom is okay then do the rest of the procedure
    if {$Matrix(activeSlicer) == "Slicer"} {
        # if called without a zoom arg it's from user entry
        if {$zoom == ""} {
            if {[ValidateFloat $Slice($s,zoom)] == 0} {
                tk_messageBox -message "The zoom must be a number."

                # reset the zoom
                set Slice($s,zoom) [Slicer GetZoom $s]
                return
            }
            # if user-entered zoom is okay then do the rest of the procedure
            set zoom $Slice($s,zoom)
        }
        # Change Slice's Zoom variable
        set Slice($s,zoom) $zoom
        # Use Attila's new zooming code
        Slicer SetZoomNew $s $zoom
        Slicer Update
    } else {
        # if called without a zoom arg it's from user entry
        if {$zoom == ""} {
            if {[ValidateFloat $Matrix($s,zoom)] == 0} {
                tk_messageBox -message "The zoom must be a number."

                # reset the zoom
                set Matrix($s,zoom) [MatSlicer GetZoom $s]
                return
            }
            # if user-entered zoom is okay then do the rest of the procedure
            set zoom $Matrix($s,zoom)
        }
        # Change Slice's Zoom variable
        set Matrix($s,zoom) $zoom
        # Use Attila's new zooming code
        MatSlicer SetZoomNew $s $zoom
        MatSlicer Update
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsB1Release
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsB1Release {x y} {
    global Matrix Slice

    #If Fiducial selection has been entered then do not allow the user to be able to
    #set the matrix by dragging the mouse over the 2D screens
    if {$Matrix(FidAlignEntered) != 1} {
        set s $Slice(activeID)
        set orient [Slicer GetOrientString $s]
        if {[lsearch "Axial Sagittal Coronal" $orient] == -1} {
            return
        }

        # Translate
        if {$Matrix(mouse) == "Translate"} {
            Anno($s,msg,mapper) SetInput ""
            Anno($s,r1,actor)  SetVisibility 0
        }

        # Rotate
        if {$Matrix(mouse) == "Rotate"} {
            Anno($s,msg,mapper) SetInput ""
            Anno($s,r1,actor)  SetVisibility 0
            Anno($s,r2,actor)  SetVisibility 0
        }
    }
}


################################################################################
# Procedures added to handle split screens for "Registration/Alignment using
# Fiducials" (aka FidAlign)
###############################################################################
# Notes: Some of the Procs below (the ones that start with AlignmentsSlices)
# were modified from MainSlices so that two renderers and two vtkMrmlSlicer
# objects could be handled independently for the purposes of FidAlign. At the
# time FidAlign was developed, Slicer did not have the capability to handle this
# in a better way. Hopefully this can be fixed with incrTcl in the future.
# Known bugs: The zooming currently does not work for the 2D slices of MatSlicer.
# I have modified some slicer procedures for zooming slices below however there
# is a small glitch that I was not able to find. The y axis seems to be flipped
# when the user wants to zoom the 2D slices of MatSlicer so currently I have
# disabled zoom for this slicer as I did not want to affect the rest of Slicer.

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetRegistrationMode
#
# Set the registration mechanism depending on which button the user selected in
# the Auto tab.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetRegistrationMode {} {
    global Matrix

    if {$Matrix(f$Matrix(regMode)) == "$Matrix(fFidAlign)"} {
        if {$::Module(verbose)} {
            puts "you are in the fiducial alignment mode"
        }
        AlignmentsFidAlignGo
        return
    } elseif {$Matrix(f$Matrix(regMode)) == "$Matrix(fIntensity)"} {
        if {$::Module(verbose)} {
            puts "you are in the registration by itensity mode"
        }
        raise $Matrix(f$Matrix(regMode))
        focus $Matrix(f$Matrix(regMode))
    } 

    # elseif {$Matrix(f$Matrix(regMode)) == "$Matrix(fTPS)"} {
    #    if {$::Module(verbose)} {
    #        puts "you are in the Thin plate spline registration mode"
    # }
    #    #TPS is not currently implemented in this version.
    #    raise $Matrix(f$Matrix(regMode))
    #    return
    # }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsBuildMinimizedSliceControls
# Builds the minimized slice controls for when the user is in FidAlign mode.
# The controls are minimizes in that the user cannot change the bg/fg/label
# volumes when in FidAlign and also certain items in the drop down menu
# on the V(visibility) button have been removed. These controls were made to
# increase user-friendliness of FidAlign and also to avoid duplication of code
# for functions that are unneccessary/confusing when in FidAlign mode. These
# slice controls are configured to display the slice information (slice offsets,
# visibilities, orientations) for only the dataset which the user is interacting
# with. The interaction is detected by the mouse(x,y) coordinates in the viewer
# (See AlignmentsGetCurrentView).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsBuildMinimizedSliceControls {s F} {
    global Gui View Slice Matrix

    frame $F.fOffset -bg $Gui(activeWorkspace)
    frame $F.fOrient -bg $Gui(activeWorkspace)
    pack $F.fOffset $F.fOrient -fill x -side top -padx 0 -pady 3

    # Offset
    #-------------------------------------------
    set f $F.fOffset
    set fov2 [expr $View(fov) / 2]

    #The offset entry box
    eval {entry $f.eOffset -width 4 -textvariable Slice(s,offset)} $Gui(WEA)
    bind $f.eOffset <Return>   "AlignmentsSlicesOffsetUpdated $s"
    bind $f.eOffset <FocusOut> "AlignmentsSlicesOffsetUpdated $s"

    # tooltip for entry box
    set tip "Current slice: in mm or slice increments,\n \
        depending on the slice orientation you have chosen.\n \
        The default (AxiSagCor orientation) is in mm. \n \
        When editing (Slices orientation), slice numbers are shown.\n\
        To change the distance between slices from the default\n\
        1 mm, right-click on the V button."

    TooltipAdd $f.eOffset $tip
    eval {scale $f.sOffset -from -$fov2 -to $fov2 \
          -variable Slice($s,offset) -length 160 -resolution 1.0 \
          -command "AlignmentsSlicesSetOffsetInit $s $f.sOffset Slicer"} $Gui(WSA) \
        {-troughcolor $Gui(slice$s)}

    pack $f.sOffset $f.eOffset -side left -anchor w -padx 2 -pady 0

    # Visibility
    #-------------------------------------------
    # This Slice
    # These are only build for one vtkMrmlSlicer object (Slicer) here, but thats
    # OK because they will be configured later to deal with one or the other vtkMrmlSlicer
    # see AlignmentsConfigSliceGui
    eval {checkbutton $f.cVisibility${s} \
          -variable Matrix($s,Slicer,visibility) -indicatoron 0 -text "V" -width 2 \
          -command "AlignmentsSlicesSetVisibility $s; RenderBoth $s"} $Gui(WCA) \
    {-selectcolor $Gui(slice$s)}

    # tooltip for Visibility checkbutton
    TooltipAdd $f.cVisibility${s} "Click to make this slice visible.\n \
        Right-click for menu: \nzoom, slice increments, \
        volume display."

    pack $f.cVisibility${s} -side left -padx 2

    # Menu on the Visibility checkbutton
    # Ron said menu items not impt in this view so I have only left the first 2 to
    # avoid code duplication from MainSlices.tcl
    eval {menu $f.cVisibility${s}.men} $Gui(WMA)
    set men $f.cVisibility${s}.men
    $men add command -label "All Visible" \
        -command "AlignmentsSlicesSetVisibilityAll 1; Render3D"
    $men add command -label "All Invisible" \
        -command "AlignmentsSlicesSetVisibilityAll 0; Render3D"
    $men add command -label "-- Close Menu --" -command "$men unpost"
    bind $f.cVisibility${s} <Button-3> "$men post %X %Y"

    # Orientation
    #-------------------------------------------
    set f $F.fOrient

    # All Slices
    eval {menubutton $f.mbOrient -text "Or:" -width 3 -menu $f.mbOrient.m} \
        $Gui(WMBA) {-anchor e}
    pack $f.mbOrient -side left -pady 0 -padx 2 -fill x
    # tooltip for orientation menu
    TooltipAdd $f.mbOrient "Set Orientation of all slices."

    eval {menu $f.mbOrient.m} $Gui(WMA)
    foreach item "AxiSagCor Orthogonal Slices ReformatAxiSagCor" {
        $f.mbOrient.m add command -label $item -command \
            "AlignmentsSlicesSetOrientAll $item; RenderAll"
    }

    # This slice
    eval {menubutton $f.mbOrient${s} -text INIT -menu $f.mbOrient${s}.m \
        -width 13} $Gui(WMBA) {-bg $Gui(slice$s)}
    pack $f.mbOrient${s} -side left -pady 0 -padx 2 -fill x

    # tooltip for orientation menu for slice
    TooltipAdd $f.mbOrient${s} "Set Orientation of just this slice."

    eval {menu $f.mbOrient${s}.m} $Gui(WMA)
    set Slice($s,menu) $f.mbOrient${s}.m
    foreach item "[Slicer GetOrientList]" {
        $f.mbOrient${s}.m add command -label $item -command \
            "AlignmentsSlicesSetOrient ${s} $item; RenderBoth $s"
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsBuildMinimizedSliceThumbControls
# Builds the minimized slice thumb controls that are displayed in 4x512 view etc.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsBuildMinimizedSliceThumbControls {} {
    global Gui View viewWin Slice Module

    foreach s $Slice(idList) {

        set f $Gui(fSlice$s)

        frame $f.fThumbMat    -bg $Gui(activeWorkspace)
        frame $f.fControlsMat -bg $Gui(activeWorkspace)

        # Raise this window to the front when the mouse passes over it.
        place $f.fControlsMat -in $f -relx 1.0 -rely 0.0 -anchor ne
        bind $f.fControlsMat <Leave> "AlignmentsHideSliceControls"

        # Raise this window to the front when view mode is Quad256 or Quad512
        place $f.fThumbMat -in $f -relx 1.0 -rely 0.0 -anchor ne

        #-------------------------------------------
        # Slice$s->Thumb frame
        #-------------------------------------------
        set f $Gui(fSlice$s).fThumbMat

        frame $f.fOrientMat -bg $Gui(slice$s)
        pack $f.fOrientMat -side top

        # Orientation
        #-------------------------------------------
        set f $Gui(fSlice$s).fThumbMat.fOrientMat

        eval {label $f.lOrientMat -text "INIT" -width 12} \
            $Gui(WLA) {-bg $Gui(slice$s)}
        pack $f.lOrientMat

        #lower $f.lOrientMat

        # Show the full controls when the mouse enters the thumbnail
        bind $f.lOrientMat <Enter>  "AlignmentsShowSliceControls $s"

        #-------------------------------------------
        # Slice$s->Controls frame
        #-------------------------------------------
        set f $Gui(fSlice$s).fControlsMat

        AlignmentsBuildMinimizedSliceControls $s $f
        lower $Gui(fSlice$s).fControlsMat
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsBuildActiveVolSelectControls
#
# Builds the radio buttons on the minimized slice control panel that allow the
# user to toggle which of the two data sets is active in FidAlign.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsBuildActiveVolSelectControls {} {
    global Gui Matrix

    #The volume Selection frame
    set f $Gui(fMatVol)
    frame $f.fActiveVol -bg $Gui(activeWorkspace) -bd 3
    pack $f.fActiveVol -fill x -side top -padx 0 -pady 0

    set f $f.fActiveVol
    eval {label $f.fTitle -text "Active Slices: "} $Gui(WLA)

    frame $f.f -bg $Gui(backdrop)
    foreach slicer "Slicer MatSlicer" \
    text "$Matrix(FidAlignRefVolumeName) $Matrix(FidAlignVolumeName)" {
        eval {radiobutton $f.f.r$slicer \
              -text "$text" -value "$slicer"\
              -variable Matrix(activeSlicer)\
              -indicatoron 1 -command "AlignmentsSetActiveSlicer $slicer; \
                    AlignmentsSetActiveScreen; AlignmentsConfigSliceGUI; \
                    AlignmentsSetSliceWindows $slicer;"} $Gui(WCA)

        pack $f.f.r$slicer -side left -padx 0 -ipadx 15
    }
    pack $f.fTitle $f.f -side left -padx $Gui(pad) -fill x -anchor w

  #save the path to the radio buttons
  set Matrix(rFidScActivateRefVolume) $f.f.rSlicer
  set Matrix(rFidScActivateVolume) $f.f.rMatSlicer
}


#----------------------------------------------------------------------------------
# .PROC AlignmentsConfigSliceGUI
#  Configures the minimized slice control panel to reflect only the slice
# information (offsets, visibilities, orientation) for the dataset with which
# the user is interacting.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsConfigSliceGUI {} {
    global Matrix Slice Gui

    foreach s $Slice(idList) {
        if {$Matrix(activeSlicer) == "Slicer"} {
            set Matrix($s,Slicer,visibility) [Slice($s,Slicer,planeActor) GetVisibility]
            set offset Slice($s,offset)
            set visibility Matrix($s,Slicer,visibility)
            set orient $Slice($s,orient)
        } else {
            set Matrix($s,MatSlicer,visibility) [Slice($s,MatSlicer,planeActor) GetVisibility]
            set offset Matrix($s,offset)
            set visibility Matrix($s,MatSlicer,visibility)
            set orient $Matrix($s,orient)
        }

         #offset entry boxes
        .tViewer.fMatMid.fMatMidSlice$s.fOffset.eOffset configure -textvariable $offset
        $Gui(fSlice$s).fControlsMat.fOffset.eOffset configure -textvariable $offset

        #offset sliders
        .tViewer.fMatMid.fMatMidSlice$s.fOffset.sOffset configure -variable $offset
        $Gui(fSlice$s).fControlsMat.fOffset.sOffset configure -variable $offset

        #visibility buttons
        .tViewer.fMatMid.fMatMidSlice$s.fOffset.cVisibility$s configure -variable $visibility
        $Gui(fSlice$s).fControlsMat.fOffset.cVisibility$s configure -variable $visibility

        #orientation buttons
        .tViewer.fMatMid.fMatMidSlice$s.fOrient.mbOrient$s configure -text $orient
        $Gui(fSlice$s).fControlsMat.fOrient.mbOrient$s configure -text $orient
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsUnpackFidAlignScreenControls
# Unpack the minimized slice controls for FidAlign and repacks the normally seen
# slice control panel.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsUnpackFidAlignScreenControls {} {
    global Gui Slice

    set f $Gui(fViewer)
    pack forget $Gui(fTop) $Gui(fMatVol) $Gui(fMatMid) $Gui(fBot)
    #Repack the original stuff
    pack $Gui(fTop) -side top
    pack $Gui(fMid) -side top -expand 1 -fill x
    pack $Gui(fBot) -side top
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsFidAlignGo
# Enter FidAlign
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsFidAlignGo {} {
    global Matrix Module Volume Slice Gui View Fiducials Select

    if {[IsModule Alignments] == 1} {

        #Do not allow entry into the Fiducial tab unless there is a volume to move
        #and a reference volume selected.
        if {$Matrix(volume) == $Volume(idNone) || $Matrix(refVolume) == $Volume(idNone)} {
            tk_messageBox -icon error -message "Either the reference volume or the volume to move has not yet been set"
            set Matrix(regMode) ""
            raise $Matrix(fAlignBegin)
            return
        }

        # v = ID of volume to register
        # r = ID of reference volume
        set v $Matrix(volume)
        set r $Matrix(refVolume)
        # Store which transform we're editing
        # If the user has not selected a tranform, then create a new one by default
        # and append it to the volume to move
        #t = the transform
        set t $Matrix(activeID)
        set Matrix(tAuto) $t
        if {$t == ""} {
            DataAddTransform append Volume($v,node) Volume($v,node)
        }
 
        #Freeze the Auto tab
        set Alignments(freeze) 1
        Tab Alignments row1 Auto
        set Module(freezer) "Alignments row1 Auto"
        raise $Matrix(f$Matrix(regMode))

        #Set the fade opacity slider to be disabled and change the tooltip
        #to indicate to the users that it is disabled in this mode
        #We dont want the fore fade opacity slider to be active here because
        #we want them to see the volumes as two separate entities.
        #The slider is set back to normal when the user exits the fiducial
        #selection mode (which occurs when the press cancel or apply or
        #when the exit the scene altogether).
        set f .tMain.fDisplay.fRight
        $f.sOpacity configure -state disabled
        MainSlicesSetOpacityAll 1
        TooltipAdd $f.sOpacity "The opacity slider is diabled in this mode"

        #Update the camera in the matRen
        AlignmentsMatRenUpdateCamera

        #Depending on what the user selected as the volume to move and the reference volume
        #Put the "Reference Volume" in the viewRen renderer and put the "Volume to Move"
        #in the matRen renderer.
        MainSlicesSetVolumeAll Fore $r
        AlignmentsSplitVolumes $r viewRen Fore
        #put the volume to move in the right renderer
        MainSlicesSetVolumeAll Back $v
        AlignmentsSplitVolumes $v matRen Back

        #Create new fiducials lists here that the user can use for FidAlign'ing.
        #These will be the default lists if the user does not choose a "premade" one
        #from the drop down menu
        #Reference volume
        set index 0
        set Matrix(FidAlignRefVolumeList) ${Matrix(FidAlignRefVolumeName)}
        while { [lsearch $Fiducials(listOfNames) $Matrix(FidAlignRefVolumeList)] != -1} {
            set Matrix(FidAlignRefVolumeList) ${Matrix(FidAlignRefVolumeName)}${index}
            incr index
        }
        if { [lsearch $Fiducials(listOfNames) $Matrix(FidAlignRefVolumeList)] == -1} {
            FiducialsCreateFiducialsList "Alignments" $Matrix(FidAlignRefVolumeList)
            set Matrix(oldDataList,$Matrix(FidAlignRefVolumeList)) ""
            set Matrix(textBox,currentID,$Matrix(FidAlignRefVolumeList)) -1
        }
        #Volume to register
        set index 0
        set Matrix(FidAlignVolumeList) ${Matrix(FidAlignVolumeName)}
        while {[lsearch $Fiducials(listOfNames) $Matrix(FidAlignVolumeList)] != -1} {
            set Matrix(FidAlignVolumeList) ${Matrix(FidAlignVolumeName)}${index}
            incr index
        }
        if { [lsearch $Fiducials(listOfNames) $Matrix(FidAlignVolumeList)] == -1} {
            FiducialsCreateFiducialsList "Alignments" $Matrix(FidAlignVolumeList)
            set Matrix(oldDataList,$Matrix(FidAlignVolumeList)) ""
            set Matrix(textBox,currentID,$Matrix(FidAlignVolumeList)) -1
        }

        set Matrix(FidAlignEntered) 1
        set Matrix(currentDataList) $Matrix(FidAlignVolumeList)
        #Disable the other registration mode buttons
        AlignmentsSetRegTabState disabled
        #Show matRen
        set Matrix(matricesview,visibility) 1
        #If the user was in 4x512 or any other view mode then keep them at this view mode
        AlignmentsUpdateFidAlignViewVisibility
        #Display the minimized slice control panel
        AlignmentsFidAlignViewUpdate
        #Track the users mouse poition
        pushEventManager $Matrix(eventManager)

        # TEMP - Need to put a push/pop bindings someplace
        set widgets "$Gui(fSl0Win) $Gui(fSl1Win) $Gui(fSl2Win)"
        foreach widget $widgets {
            bind $widget <KeyPress-p> {
                # like SelectPick2D, sets right coords in Alignments(xyz)
                # returns 0 if nothing picked
                if { [AlignmentsPick2D %W %x %y] != 0 } \
                {   eval FiducialsCreatePointFromWorldXYZ "default" $Matrix(xyz) ; MainUpdateMRML; Render3D}
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsFidAlignApply
# Get the Transform that maps the volume to register onto the reference volume
# based on the fiducial points that the user has selected.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsFidAlignApply {} {
    global Matrix Module Label Slice

    # If tabs are frozen, then
    if {$Module(freezer) != ""} {

        #Validate the input

        #There must be a minimum of Three points selected for EACH dataset
        if {[llength [FiducialsGetPointIdListFromName $Matrix(FidAlignRefVolumeList)]] < 2} {
            tk_messageBox -icon error -message "You must select at least THREE fiducial points for alignment using fiducials"
            return
        }

        if {[llength [FiducialsGetPointIdListFromName $Matrix(FidAlignVolumeList)]] < 2} {
            tk_messageBox -icon error -message "You must select at least THREE fiducial points for alignment using fiducials"
            return
        }

        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd

        #Apply vtkLandmarkTransform
        AlignmentsLandTrans

        AlignmentsFidAlignResetVars
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsFidAlignCancel
# Ejects the users from FidAlign mode
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsFidAlignCancel {} {
    global Matrix Module

    #unfreeze
    set Matrix(freeze) 0

    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }

    AlignmentsFidAlignResetVars
}
#-------------------------------------------------------------------------------
# .PROC AlignmentsFidAlignResetVars
# Resets the FidAlign vars if the user Clicks Apply or Cancel from FidAlign frame
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsFidAlignResetVars {} {
    global Matrix Slice View Fiducials Select Gui

    set Matrix(currentDataList) ""

    #Remove matRen and display only viewRen now
    set Matrix(matricesview,visibility) 0
    set Matrix(mainview,visibility) 1
    AlignmentsUpdateMainViewVisibility

    #Unpack the Slice controls that are specific to the fiducials selection tab
    AlignmentsUnpackFidAlignScreenControls

    #Set the visibilities for the original slice actors to the same value
    #as what the user had in FidAlign
    foreach s $Slice(idList) {
        set Slice($s,visibility) $Matrix($s,Slicer,visibility)
        Slice($s,planeActor) SetVisibility $Matrix($s,Slicer,visibility)
    }

    #Change the background color to be light blue (normal color)
    set View(bgColor) "0.7 0.7 0.9"
    eval viewRen SetBackground $View(bgColor)

    AlignmentsSetActiveSlicer Slicer

    #Remove the slice actors used in the FidAlign to show the volumes separately
    foreach s $Slice(idList) {
        viewRen RemoveActor Slice($s,MatSlicer,planeActor)
        viewRen RemoveActor Slice($s,Slicer,planeActor)
        viewRen AddActor Slice($s,planeActor)
        AlignmentsSetSliceWindows $Matrix(activeSlicer)
    }

    set Matrix(FidAlignEntered) 0

    #Delete text boxes from the fidAlign Gui
    AlignmentsRemoveBoxes $Matrix(FidAlignRefVolumeList) $Matrix(FidRefVolPointBoxes)
    AlignmentsRemoveBoxes $Matrix(FidAlignVolumeList) $Matrix(FidVolPointBoxes)

    #Enable the fade opacity slider and change the tooltip back
    set f .tMain.fDisplay.fRight
    $f.sOpacity configure -state normal
    TooltipAdd $f.sOpacity "Slice overlay slider: Fade from\n\
        the Foreground to the Background slice."

    #Overlay the reference volume and the volume to move
    MainSlicesSetVolumeAll Fore $Matrix(refVolume)
    MainSlicesSetVolumeAll Back $Matrix(volume)

    #Go back to the "Select registration mode" frame
    set Matrix(regMode) ""
    raise $Matrix(fAlignBegin)
    AlignmentsSetRegTabState normal

    #Set the mode back to the normal view
    MainViewerSetMode

    #Set the slice orientations to axisagcor
    MainSlicesSetOrientAll AxiSagCor

    #Set the fiducials visibility to be 0
    foreach list $Fiducials(listOfNames) {
        FiducialsSetFiducialsVisibility $list 0 viewRen
        FiducialsSetFiducialsVisibility $list 0 matRen
    }

    # TEMP - Need to put a push bindings someplace
    #Reset the bindings here
    set widgets "$Gui(fSl0Win) $Gui(fSl1Win) $Gui(fSl2Win)"
    foreach widget $widgets {
         bind $widget <KeyPress-p> {
             # like SelectPick2D, sets right coords in Alignments(xyz)
             # returns 0 if nothing picked
             if { [SelectPick2D %W %x %y] != 0 } \
             { eval FiducialsCreatePointFromWorldXYZ "default" $Select(xyz) ; MainUpdateMRML; Render3D}
         }
    }

}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSplitVolumes
# Display the output of Slicer (back layer = reference volume, fore layer = None)
# on the three new slice actors in the viewRen and the output of MatSlicer
# (back layer = Volume to register, fore layer = None) on the three new slice
# actors in matRen. When the Screen is first split for FidAlign, MatSlicer is
# exactly the same as Slicer (except for its back and fore volumes).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSplitVolumes {v ren layer} {
    global Volume Slice View Matrix Lut Anno Gui

    MainSlicesSetVolumeAll Fore $Matrix(refVolume)
    MainSlicesSetVolumeAll Back $Matrix(volume)

    #Set MatSlicer to be the duplicate of Slicer at this point so that the
    #states of all the variables are the same when entering FidAlign
    MatSlicer DeepCopy Slicer
    MatSlicer SetLabelIndirectLUT Lut($Lut(idLabel),indirectLUT)
    MatSlicer SetForeOpacity 0

    foreach s $Slice(idList) {
        set Matrix($s,orient) $Slice($s,orient)
        set Matrix($s,zoom) $Slice($s,zoom)
        set Matrix($s,offsetIncrement) $Slice($s,offsetIncrement)
        AlignmentsSlicesSetSliderRange $s
        set Matrix($s,offset) $Slice($s,offset)
    }
    #Setting the back layer of Slicer to be the reference volume
    MainSlicesSetVolumeAll Back $Matrix(refVolume)
    #Setting the fore layer of Slicer to be none
    MainSlicesSetVolumeAll Fore 0

    #Setting the back layer of MatSlicer to be the volume to register
    MatSlicer SetBackVolume Volume($Matrix(volume),vol)
    #Setting fore layer of MatSlicer to be none
    MatSlicer SetForeVolume Volume(0,vol)

    foreach s $Slice(idList) {
        #Texture map the output of Slicer onto the Slice($s,Slicer,planeActor) actors
        Slice($s,Slicer,texture) SetInput [Slicer GetOutput $s]
        #Texture map the output of MatSlicer onto the Slice($s,MatSlicer,planeActor) actors
        Slice($s,MatSlicer,texture) SetInput [MatSlicer GetOutput $s]

        #This is for the viewRen/Slicer/Fore
        viewRen RemoveActor Slice($s,planeActor)
        eval Slice($s,Slicer,planeActor) SetScale [Slice($s,planeActor) GetScale]
        viewRen AddActor Slice($s,Slicer,planeActor)
        set Matrix($s,Slicer,visibility) $Slice($s,visibility)
        Slice($s,Slicer,planeActor) SetVisibility [Slice($s,planeActor) GetVisibility]

        #This is for the matRen/MatSlicer/Back
        matRen RemoveActor Slice($s,planeActor)
        eval Slice($s,MatSlicer,planeActor) SetScale [Slice($s,planeActor) GetScale]
        matRen AddActor Slice($s,MatSlicer,planeActor)
        set Matrix($s,MatSlicer,visibility) $Slice($s,visibility)
        Slice($s,MatSlicer,planeActor) SetVisibility [Slice($s,planeActor) GetVisibility]
    }

    #set the initial orientation to be AxiSagCor
    AlignmentsSlicesSetOrientAll AxiSagCor

    Slicer Update
    MatSlicer Update
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsPick2D
# Gets the RAS values for whichever slicer object the user is interacting with
# (detected by mouse motion)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsPick2D { widget x y } {
    global Select Interactor Matrix
    set s $Interactor(s)
    if { $s != "" } {
        scan [MainInteractorXY $s $x $y] "%d %d %d %d" xs yz x y
        $Matrix(activeSlicer) SetReformatPoint $s $x $y
        scan [$Matrix(activeSlicer) GetWldPoint] "%g %g %g" xRas yRas zRas
        set Matrix(xyz) "$xRas $yRas $zRas"
        return 1
    } else {
        return 0
    }
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsLandTrans
# Find the transform that best maps the volume to register to the reference volume
# based on the fiducial points selected in FidAlign. Set the active transform
# picked by the user to the resulting transform that is obtained.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsLandTrans {} {
    global Matrix Volume Fiducials View

    set t $Matrix(activeID)

    # Compute the landmark based transform
    vtkLandmarkTransform landTrans
    landTrans SetModeToRigidBody

    #set the Source landmarks
    set id $Fiducials($Matrix(FidAlignVolumeList),fid)
    landTrans SetSourceLandmarks Fiducials($id,points)

    #set the Target landmarks
    set id $Fiducials($Matrix(FidAlignRefVolumeList),fid)
    landTrans SetTargetLandmarks Fiducials($id,points)

    # Transfer values from landmark to active transform
    set tran [Matrix($t,node) GetTransform]
    $tran SetMatrix [landTrans GetMatrix]

    # Update all MRML
    MainUpdateMRML
    Render$Matrix(render)
    landTrans Delete
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetViewMenuState
# Disable Endocopic Ren on/off from the menu when in FidAlign mode
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetViewMenuState {mode} {
    global Gui

    #Disable/enable the ability to add the endoscopic ren when in this mode
    #Should be disabled when we are in the split screen mode
    $Gui(mView) entryconfigure 11 -state $mode
    $Gui(mView) entryconfigure 12 -state $mode
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsAddLetterActors
# Adds the R A S L P I letters to the matRen Renderer.
# The letters follow the View(matCam) instead of View(viewCam) as in viewRen
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsAddLetterActors {} {
    global Anno View

    set fov2 [expr $View(fov) / 2]
    set scale [expr $View(fov) * $Anno(letterSize) ]

    foreach axis "R A S L P I" {

        vtkVectorText ${axis}TextMatRen
        ${axis}TextMatRen SetText "${axis}"
        vtkPolyDataMapper  ${axis}MapperMatRen
        ${axis}MapperMatRen SetInput [${axis}TextMatRen GetOutput]
        vtkFollower ${axis}ActorMatRen
        ${axis}ActorMatRen SetMapper ${axis}MapperMatRen
        ${axis}ActorMatRen SetScale  $scale $scale $scale
        ${axis}ActorMatRen SetPickable 0

        matRen AddActor ${axis}ActorMatRen
        ${axis}ActorMatRen SetCamera $View(MatCam)
    }

    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActorMatRen SetPosition $pos 0.0  0.0
    AActorMatRen SetPosition 0.0  $pos 0.0
    SActorMatRen SetPosition 0.0  0.0  $pos
    LActorMatRen SetPosition $neg 0.0  0.0
    PActorMatRen SetPosition 0.0  $neg 0.0
    IActorMatRen SetPosition 0.0  0.0  $neg
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsMatRenUpdateCamera
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsMatRenUpdateCamera {} {
    global View Anno

    eval $View(MatCam) SetClippingRange [$View(viewCam) GetClippingRange]
    eval $View(MatCam) SetPosition [$View(viewCam) GetPosition]
    eval $View(MatCam) SetFocalPoint [$View(viewCam) GetFocalPoint]
    eval $View(MatCam) SetViewUp [$View(viewCam) GetViewUp]
    $View(MatCam) ComputeViewPlaneNormal

    #Set the scale for the letter actors in the new renderer
    set scale [expr $View(fov) * $Anno(letterSize) ]
    foreach axis "R A S L P I" {
        ${axis}ActorMatRen SetScale  $scale $scale $scale
    }

    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActorMatRen SetPosition $pos 0.0  0.0
    AActorMatRen SetPosition 0.0  $pos 0.0
    SActorMatRen SetPosition 0.0  0.0  $pos
    LActorMatRen SetPosition $neg 0.0  0.0
    PActorMatRen SetPosition 0.0  $neg 0.0
    IActorMatRen SetPosition 0.0  0.0  $neg
}



#-------------------------------------------------------------------------------
# .PROC AlignmentsUpdateFidAlignViewVisibility
#  Called by the checkbuttons in the Fiducials tab. Turns on/off a renderer.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsUpdateFidAlignViewVisibility {} {
    global View viewWin Matrix

    if {$Matrix(matricesview,visibility) == 1 && $Matrix(mainview,visibility) == 1} {
        AlignmentsAddFidAlignView
    } elseif {$Matrix(matricesview,visibility) == 0 && $Matrix(mainview,visibility) == 1} {
        AlignmentsRemoveFidAlignView
        AlignmentsSetActiveSlicer Slicer
        AlignmentsSetSliceWindows Slicer
    } elseif {$Matrix(matricesview,visibility) == 1 && $Matrix(mainview,visibility) == 0} {
        AlignmentsAddFidAlignView
        AlignmentsRemoveMainView
        AlignmentsSetActiveSlicer MatSlicer
        AlignmentsSetSliceWindows MatSlicer
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsUpdateMainViewVisibility
#  Called by the checkbuttons in the Fiducials tab. Determine which renderer to
#  display
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsUpdateMainViewVisibility {} {
    global View viewWin Matrix

    if {$Matrix(mainview,visibility) == 1 && $Matrix(matricesview,visibility) == 1} {
        AlignmentsAddMainView
    } elseif {$Matrix(mainview,visibility) == 0 && $Matrix(matricesview,visibility) == 1} {
        AlignmentsRemoveMainView
        AlignmentsSetActiveSlicer MatSlicer
        AlignmentsSetSliceWindows MatSlicer
    } elseif {$Matrix(mainview,visibility) == 1 && $Matrix(matricesview,visibility) == 0} {
        AlignmentsAddMainView
        AlignmentsRemoveFidAlignView
        AlignmentsSetActiveSlicer Slicer
        AlignmentsSetSliceWindows Slicer
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsAddMainView
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsAddMainView {} {
    global View viewWin Matrix

    $viewWin AddRenderer viewRen
    viewRen SetViewport 0 0 0.5 1
    matRen SetViewport 0.5 0 1 1
    MainViewerSetSecondViewOn
    MainViewerSetMode $View(mode)
    set Matrix(fidSelectViewOn) 1
    set Matrix(splitScreen) 1
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsAddFidAlignView
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsAddFidAlignView {} {
     global View viewWin Matrix

    if {$Matrix(fidSelectViewOn) == 0} {
        $viewWin AddRenderer matRen
        viewRen SetViewport 0 0 0.5 1
        matRen SetViewport 0.5 0 1 1
        MainViewerSetSecondViewOn
        MainViewerSetMode $View(mode)
        set Matrix(fidSelectViewOn) 1
        set Matrix(splitScreen) 1
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsRemoveFidAlignView
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsRemoveFidAlignView {} {
    global View viewWin Matrix

    if {$Matrix(fidSelectViewOn) == 1} {
        $viewWin RemoveRenderer matRen
        viewRen SetViewport 0 0 1 1
        MainViewerSetSecondViewOff
        MainViewerSetMode $View(mode)
        set Matrix(fidSelectViewOn) 0
        set Matrix(splitScreen) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsRemoveMainView
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsRemoveMainView {} {
   global View viewWin Matrix

    $viewWin RemoveRenderer viewRen
    matRen SetViewport 0 0 1 1
    MainViewerSetSecondViewOn
    MainViewerSetMode $View(mode)
    set Matrix(fidSelectViewOn) 1
    set Matrix(splitScreen) 0
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsGetCurrentView
# Set the current window based on the mouse interaction. Highlights the active
# renderer yellow. Set the current dataset so that AlignementsFiducialsUpdated
# knows which list to add the fiducial points to.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsGetCurrentView {widget x y} {
    global Gui View Matrix Fiducials

    #check if you are in the fiducial pick screen and if the
    if {$Matrix(FidAlignEntered) == 1 && $Matrix(splitScreen) == 1} {
        set View(bgColor) "0.7 0.7 0.9"
        set width [expr [lindex [[$Gui(fViewWin) GetRenderWindow] GetSize] 0] /2]
        #The viewRen renderer
        if {$x < $width} {
            AlignmentsSetActiveSlicer Slicer
            FiducialsSetActiveList $Matrix(FidAlignRefVolumeList)
            set Matrix(currentDataList) $Matrix(FidAlignRefVolumeList)
            set Matrix(currentTextFrame) $Matrix(FidRefVolPointBoxes)
            #Change the color of the renderer to indicate that it is the active one
            eval matRen SetBackground $View(bgColor)
            set View(bgColor) "0.9 0.9 0.1"
            eval viewRen SetBackground $View(bgColor)

            #The matRen renderer
        } else {
            AlignmentsSetActiveSlicer MatSlicer
            FiducialsSetActiveList $Matrix(FidAlignVolumeList)
            set Matrix(currentDataList) $Matrix(FidAlignVolumeList)
            set Matrix(currentTextFrame) $Matrix(FidVolPointBoxes)
            #Change the color of the renderer to indicate that it is the active one
            eval viewRen SetBackground $View(bgColor)
            set View(bgColor) "0.9 0.9 0.1"
            eval matRen SetBackground $View(bgColor)
        }
        #2D Slice Windows
        AlignmentsSetSliceWindows $Matrix(activeSlicer)

        #Display slice information for only the dataset the user is interacting with
        AlignmentsConfigSliceGUI

        RenderSlices
        Render3D
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetActiveScreen
#
# Called by the radio buttons on the slicer controls.
# Sets which screen is the active one based on the button pressed
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetActiveScreen {} {
    global Matrix View

    set View(bgColor) "0.7 0.7 0.9"

    if {$Matrix(activeSlicer) == "Slicer"} {
        eval matRen SetBackground $View(bgColor)
        set View(bgColor) "0.9 0.9 0.1"
        eval viewRen SetBackground $View(bgColor)
    } else {
        eval viewRen SetBackground $View(bgColor)
        set View(bgColor) "0.9 0.9 0.1"
        eval matRen SetBackground $View(bgColor)
    }

    Render3D
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsFiducialsUpdated
# Called whenever a fiducial point is updated (ie. added or deleted) by the user
# clicking on the 3d viewer
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsFiducialsUpdated {} {
    global Matrix Fiducials

    if {$Matrix(FidAlignEntered) == 1 && $Matrix(currentDataList) != ""} {
        AlignmentsRemoveBoxes $Matrix(currentDataList) $Matrix(currentTextFrame)
        AlignmentsRebuildBoxes $Matrix(currentDataList) $Matrix(currentTextFrame)
    }
    #If the lists do not exist then do nothing
    if { [lsearch $Fiducials(listOfNames) $Matrix(FidAlignVolumeList)] == -1 ||
         [lsearch $Fiducials(listOfNames) $Matrix(FidAlignRefVolumeList)] == -1} {
        return
    } else {
     
        #Visibilities of fiducials
        #set the visibilties of every other fiducial list to be 0
        foreach list $Fiducials(listOfNames) {
            FiducialsSetFiducialsVisibility $list 0 viewRen
            FiducialsSetFiducialsVisibility $list 0 matRen
        }
        #set the visibilities of only the fiducials that will be used for fidalign
        FiducialsSetFiducialsVisibility $Matrix(FidAlignRefVolumeList) 1 viewRen
        FiducialsSetFiducialsVisibility $Matrix(FidAlignVolumeList) 1 matRen
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsNewFidListChosen
# Called when the user wants to load an existing fiducials list from the drop
# down menu for either the reference volume or the volume to register
# .ARGS
# whichvolume - string - the volume for which the user picks a new list
# .END
#-------------------------------------------------------------------------------
proc AlignmentsNewFidListChosen {whichvolume} {
    global Matrix Fiducials Gui Point

    puts "a new fid list was chosen for the $whichvolume"
    puts "this is now the new list: $Matrix(FidAlign${whichvolume}List)"

    #Create an "old data list for the newly selected fid list if it doesnt exist"
    if {[info exists Matrix(oldDataList,$Matrix(FidAlign${whichvolume}List))] == 0} {
        set Matrix(oldDataList,$Matrix(FidAlign${whichvolume}List)) ""
    }

    #Using the current data list in this case doesnt work because sometimes the user will
    #want to load a fid list for a volume that may not be "active"
    if {$whichvolume == "RefVolume"} {
        AlignmentsRemoveBoxes $Matrix(oldFidAlign${whichvolume}List) $Matrix(FidRefVolPointBoxes)
        AlignmentsRebuildBoxes $Matrix(FidAlign${whichvolume}List)  $Matrix(FidRefVolPointBoxes)
   } else {
        AlignmentsRemoveBoxes $Matrix(oldFidAlign${whichvolume}List) $Matrix(FidVolPointBoxes)
        AlignmentsRebuildBoxes $Matrix(FidAlign${whichvolume}List) $Matrix(FidVolPointBoxes)
    }
 
    #Visibilities of fiducials
    #set the visibilties of every other fiducial list to be 0
    foreach list $Fiducials(listOfNames) {
        FiducialsSetFiducialsVisibility $list 0 viewRen
        FiducialsSetFiducialsVisibility $list 0 matRen
    }
    #set the visibilities of only the fiducials that will be used for fidalign
    FiducialsSetFiducialsVisibility $Matrix(FidAlignRefVolumeList) 1 viewRen
    FiducialsSetFiducialsVisibility $Matrix(FidAlignVolumeList) 1 matRen

    #Color the active fiducial list in the menu of fiducial lists red
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetRefVolList
# Sets the fiducials list that will be used in FidAlign for the reference volume
# Called if the user loads a new fiducial list from the drop down menu for the
# reference volume
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetRefVolList {name} {
    global Matrix

    #Save the name of the list that is currently displayed for cleanup of the
    #point boxes that are currently displayed
    set Matrix(oldFidAlignRefVolumeList) $Matrix(FidAlignRefVolumeList)
    #Set the fiducials list for the reference volume to be the one that
    #the user picked from the menu
    set Matrix(FidAlignRefVolumeList) $name
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetVolumeList
# Sets the fiducials list that will be used in FidAlign for the volume to move
# Called if the user loads a new fiducial list from the drop down menu for the
# volume to register
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetVolumeList {name} {
    global Matrix

    #Save the name of the list that is currently displayed for cleanup of the
    #point boxes that are currently displayed
    set Matrix(oldFidAlignVolumeList) $Matrix(FidAlignVolumeList)
    #Set the fiducials list for the volume to move to be the one that
    #the user picked from the menu
    set Matrix(FidAlignVolumeList) $name
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsRemoveBoxes
# Deletes the textboxes that hold the fiducial point coordinate values for FidAlign
# This is done so that the boxes are not there if the user enters fidalign again or
# if they want to load new fiducial lists then the point boxes corresponding to the
# old fiducials list can be deleted.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsRemoveBoxes {ListName frameName} {
    global Matrix Fiducials

    #Check if the lists already exist
    if { [lsearch $Fiducials(listOfNames) $ListName] == -1} {
       return
    } else {
        #Delete the textboxes associated with the List
        if {[llength $Matrix(oldDataList,$ListName)] > 0} {
            foreach pid $Matrix(oldDataList,$ListName) {
                #clear the text boxes
                $frameName.entry$pid delete 0 end
                #remove the labels
                destroy $frameName.lEntry$pid
                #remove the boxes
                destroy $frameName.entry$pid
            }
       }
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsRebuildBoxes
# Rebuilds the boxes that hold the fiducial point coordinates for FidAlign.
# .ARGS
#
# .END
#-------------------------------------------------------------------------------
proc AlignmentsRebuildBoxes {ListName frameName} {
    global Matrix Fiducials Gui Point

    set dataList [FiducialsGetPointIdListFromName $ListName]
    #Build the textboxes again for all the points in the current list

    set count 0
    foreach pid $dataList {
        eval {label $frameName.lEntry$pid -text "Pt:$count"} $Gui(BLA)
        eval {entry $frameName.entry$pid -justify right -width 10} $Gui(WEA)
        set count [expr $count + 1]
    }

    foreach pid $dataList {
        grid $frameName.lEntry$pid $frameName.entry$pid
        #save the path to the textbox so we can access it later
        set Matrix(textBox,$pid,ListName) $frameName.entry$pid
    }

    foreach pid $dataList {
        set xyz [FiducialsGetPointCoordinates $pid]
        $frameName.entry$pid config -state normal
        $frameName.entry$pid insert 0 $xyz
        $frameName.entry$pid config -state disabled
    }

    #set this new list to be the old list for next time
    set Matrix(oldDataList,$ListName) $dataList
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetOrientAll
#  Change orientation of all slices for the active slicer object
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetOrientAll {orient} {
    global Slice View Matrix Gui

    if {$Matrix(activeSlicer) == "Slicer"} {
        set cam $View(viewCam)
    } else {
        set cam $View(MatCam)
    }


    foreach s $Slice(idList) {
        if {$Matrix(activeSlicer) == "Slicer"} {
            set sliceorient Slice($s,orient)
            set sliceoffset Slice($s,offset)
        } else {
            set sliceorient Matrix($s,orient)
            set sliceoffset Matrix($s,offset)
        }

        set orient [$Matrix(activeSlicer) GetOrientString $s]
        set $sliceorient $orient

        # Always update Slider Range when change Back volume or orient
        AlignmentsSlicesSetSliderRange $s

        # Set slider increments
        #MainSlicesSetOffsetIncrement $s

        # Set slider to the last used offset for this orient
        eval set $sliceoffset [$Matrix(activeSlicer) GetOffset $s]

        # Change text on menu button
        set f .tViewer.fMatMid.fMatMidSlice$s.fOrient
        eval $f.mbOrient$s configure -text $$sliceorient
        eval $Gui(fSlice$s).fThumbMat.fOrientMat.lOrientMat configure -text $$sliceorient

        MainSlicesSetAnno $s $orient
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetOrient
# Change orientation of selected slice for the active slicer object
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetOrient {s orient} {
    global Slice Volume View Module Matrix Gui

    if {$Matrix(activeSlicer) == "Slicer"} {
        set cam View(viewCam)
        set sliceorient Slice($s,orient)
        set sliceoffset Slice($s,offset)
    } else {
        set cam View(MatCam)
        set sliceorient Matrix($s,orient)
        set sliceoffset Matrix($s,offset)
    }

    eval $Matrix(activeSlicer) ComputeNTPFromCamera $$cam

    $Matrix(activeSlicer) SetOrientString $s $orient

    set $sliceorient [$Matrix(activeSlicer) GetOrientString $s]

    # Always update Slider Range when change Back volume or orient
    AlignmentsSlicesSetSliderRange $s

    # Set slider increments
    #AlignmentsSlicesSetOffsetIncrement $s

    #Set slider to the last used offset for this orient
    set $sliceoffset [$Matrix(activeSlicer) GetOffset $s]

    # Change text on menu button
    set f .tViewer.fMatMid.fMatMidSlice$s.fOrient
    eval $f.mbOrient$s configure -text $orient
    eval $Gui(fSlice$s).fThumbMat.fOrientMat.lOrientMat configure -text $$sliceorient

    # Anno
    MainSlicesSetAnno $s $orient
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesOffsetUpdated
# Configures the sliders and corresponding entry boxes when the slice offsets
# have changed for one of the datasets in FidAlign mode.
#
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesOffsetUpdated {s} {
    global Matrix Slice Gui

    set f .tViewer.fMatMid.fMatMidSlice$s.fOffset.sOffset

    if {$Matrix(activeSlicer) == "Slicer"} {

        #configure the slider's entry box
        AlignmentsSlicesSetOffset $s Slicer

        .tViewer.fMatMid.fMatMidSlice$s.fOffset.eOffset \
        configure -textvariable Slice($s,offset)

        #configure the slider bar
        AlignmentsSlicesSetOffsetInit $s $f Slicer
        .tViewer.fMatMid.fMatMidSlice$s.fOffset.sOffset \
            configure -variable Slice($s,offset)

    } else {
        #configure the slider's entry box
        AlignmentsSlicesSetOffset $s MatSlicer

        .tViewer.fMatMid.fMatMidSlice$s.fOffset.eOffset \
        configure -textvariable Matrix($s,offset)

        #configure the slider
        AlignmentsSlicesSetOffsetInit $s $f MatSlicer

        .tViewer.fMatMid.fMatMidSlice$s.fOffset.sOffset \
            configure -variable Matrix($s,offset)
    }
    RenderBoth $s
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetSliderRange
# Set the max and min values reachable with the slice selection slider.
# Called when the volume in the background changes
# (in case num slices, resolution have changed)
# .ARGS
# s int slice window (0,1,2)
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetSliderRange {s} {
    global Slice Matrix Gui

    if {$Matrix(activeSlicer) == "Slicer"} {
        set offset Slice($s,offset)
    } else {
        set offset Matrix($s,offset)
    }

    set lo [Slicer GetOffsetRangeLow  $s]
    set hi [Slicer GetOffsetRangeHigh $s]

    eval .tViewer.fMatMid.fMatMidSlice$s.fOffset.sOffset configure -from $lo -to $hi
    #Thumbnails
    eval $Gui(fSlice$s).fControlsMat.fOffset.sOffset configure -from $lo -to $hi

    # Update Offset
    eval set $$offset [$Matrix(activeSlicer) GetOffset $s]
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetOffsetIncrement
# Set the increment by which the slice slider should move.
# The default in the slicer is 1, which is 1 mm.
# Note this procedure will force increment to 1 if in any
# of the Slices orientations which just grab original data from the array.
# In this case the increment would mean 1 slice instead of 1 mm.
# .ARGS
# s int slice number (0,1,2)
# incr float increment slider should move by. is empty str if called from GUI
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetOffsetIncrement {s {incr ""}} {
    global Slice Matrix

    if {$Matrix(activeSlicer) == "Slicer"} {
        set offsetIncr Slice($s,offsetIncrement)
    } else {
        set offsetIncr Matrix($s,offsetIncrement)
    }

    # set slider increments to 1 if in original orientation
    set orient [$Matrix(activeSlicer) GetOrientString $s]
    if {$orient == "AxiSlice" || $orient == "CorSlice" \
        || $orient == "SagSlice" || $orient == "OrigSlice" } {
        set incr 1
    }

    # if called without an incr arg it's from user entry
    if {$incr == ""} {

    if { [ValidateFloat $$offsetIncr] == 0} {
        tk_messageBox -message "The increment must be a number."

        #reset the incr
        eval set $$offsetIncr 1
        return
    }

    # if user-entered incr is okay then do the rest of the procedure
    eval set incr $$offsetIncr
    }

    # Change Slice's offset increment variable
    eval set $$offsetIncr $incr

    # Make the slider allow this resolution
    .tViewer.fMatMid.fMatMidSlice$s.fOffset.sOffset configure -resolution $incr

}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetOffset
# Set the slice offset
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetOffset {s whichSlicer {value ""}} {
    global Slice Matrix

    if {$Matrix(activeSlicer) == "Slicer"} {
        set offsetval $Slice($s,offset)
    } else {
        set offsetval $Matrix($s,offset)
    }

    if {$value == ""} {
        set value $offsetval
    } elseif {$value == "Prev"} {
        set value [expr $offsetval - 1]

    } elseif {$value == "Next"} {
        set value [expr $offsetval + 1]
    }

    if {[ValidateFloat $value] == 0}  {
        set value [$Matrix(activeSlicer) GetOffset $s]
    }

    if {$Matrix(activeSlicer) == "Slicer"} {
        set Slice($s,offset) $value
        Slicer SetOffset $s $value
        AlignmentsSlicesRefreshClip $s Slicer
    } else {
        set Matrix($s,offset) $value
        MatSlicer SetOffset $s $value
        AlignmentsSlicesRefreshClip $s MatSlicer
    }

    Render3D
    RenderSlices
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetOffsetInit
# wrapper around MainSlicesSetOffset. Also calls RenderBoth
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetOffsetInit {s widget whichSlicer {value ""}} {

    # This prevents Tk from calling RenderBoth when it first creates
    # the slider, but before a user uses it.
    $widget config -command "AlignmentsSlicesSetOffset $s $whichSlicer; RenderBoth $s"
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetVisibilityAll
#
# Callback for the V button on the Slice controls frame of the split screen.
# Sets the visibility to be on or off for all the slices for the dataset selected
#
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetVisibilityAll {{value ""}} {
    global Matrix Slice Matrix

    if {$value != ""} {
        set Matrix(visibilityAll,$Matrix(activeSlicer)) $value
    }

    foreach s $Slice(idList) {
        set Matrix($s,$Matrix(activeSlicer),visibility) $Matrix(visibilityAll,$Matrix(activeSlicer))
        Slice($s,$Matrix(activeSlicer),planeActor) SetVisibility $Matrix($s,$Matrix(activeSlicer),visibility)
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesSetVisibility
# Callback for the V button on the Slice controls frame of the split screen.
# Sets the visibility to be on or off for the indicated slice of the dataset
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesSetVisibility {s} {
    global Slice Matrix

    Slice($s,$Matrix(activeSlicer),planeActor) SetVisibility $Matrix($s,$Matrix(activeSlicer),visibility)

    # If any slice is invisible, then Slice(visibilityAll) should be 0
    set Matrix(visibilityAll,$Matrix(activeSlicer)) 1
    foreach s $Slice(idList) {
        if {$Matrix($s,$Matrix(activeSlicer),visibility) == 0} {
            set Matrix(visibilityAll,$Matrix(activeSlicer)) 0
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsSlicesRefreshClip
# Update clipping.
# Set normal and origin of clip plane using current
# info from vtkMrmlSlicer's reformat matrix.
# .ARGS
# s int slice id (0,1,2)
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSlicesRefreshClip {s whichSlicer} {
    global Slice

    # Set normal and orient of slice
    if {$Slice($s,clipState) == "1"} {
        set sign 1
    } elseif {$Slice($s,clipState) == "2"} {
        set sign -1
    } else {
        return
    }
    set mat [$whichSlicer GetReformatMatrix $s]

    set origin "[$mat GetElement 0 3] \
        [$mat GetElement 1 3] [$mat GetElement 2 3]"

    set normal "[expr $sign*[$mat GetElement 0 2]] \
        [expr $sign*[$mat GetElement 1 2]] \
        [expr $sign*[$mat GetElement 2 2]]"

    # WARNING: objects may not exist yet!
    if {[info command Slice($s,clipPlane)] != ""} {
        eval Slice($s,clipPlane) SetOrigin  $origin
        eval Slice($s,clipPlane) SetNormal $normal
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetSliceWindows
#
# Sets all the 2D slice windows to show the output of the active slicer
#
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetSliceWindows {whichSlicer} {
    global Slice Volume Matrix

    foreach s $Slice(idList) {
       sl${s}Mapper SetInput [$whichSlicer GetCursor $s]
    }
    RenderSlices
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsSetActiveSlicer
# Sets the active vtkMrmlSlicer object
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetActiveSlicer {whichSlicer} {
    global Matrix Interactor
    set Matrix(activeSlicer) $whichSlicer
    set Interactor(activeSlicer) $whichSlicer
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsFidAlignViewUpdate
# Called when the user changes the view mode (ie. Normal to 4x512) from
# the main menu. Handles the packing or unpacking of the slice controls that
# were built for the fiducial selection alignment mode. Also sets the
# size and cursor position for the 2D slices corresponding to MatSlicer.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsFidAlignViewUpdate {} {
    global Module View Gui Slice Matrix

    # Check to see if we are in the alignments module
    # and that the fiducial selection mode has been entered.
    if {$Module(activeID) != "Alignments" || $Matrix(FidAlignEntered) != 1} {
        return
    }

    switch $View(mode) {
        "Normal" {
            #Pack forget the 3D view, the slice controls (the normal ones as well
            #as the slice controls that were build for fiducial selection mode
            #if they exist) and the 2d slice windows
            pack forget $Gui(fTop) $Gui(fMid) $Gui(fBot)
            pack forget $Gui(fTop) $Gui(fMatVol) $Gui(fMatMid) $Gui(fBot)
            #Repack the GUI with the slice controls for fiducial selection mode
            pack $Gui(fTop) -side top
            pack $Gui(fMatVol) -side top -expand 0 -fill x
            pack $Gui(fMatMid) -side top -expand 1 -fill x
            pack $Gui(fBot) -side top
            #These are the settings that normally occur for the vtkMrmlSlicer object.
            #We need to do the same steps for MatSlicer In order to keep the display the same
            foreach s $Slice(idList) {
                MatSlicer SetDouble $s 0
                MatSlicer SetCursorPosition $s 128 128
            }
        }
        "3D" {
            #unpack the slice controls for the fiducial selection mode
            pack forget $Gui(fMatVol) $Gui(fMatMid)
        }
        "Quad256" {
            #unpack the controls for the fiducial selection mode
            pack forget $Gui(fMatVol) $Gui(fMatMid)
            foreach s $Slice(idList) {
                MatSlicer SetDouble $s 0
                MatSlicer SetCursorPosition $s 128 128
            }
        }
        "Quad512" {
            #unpack the controls for the fiducial selection mode
            pack forget $Gui(fMatVol) $Gui(fMatMid)
            foreach s $Slice(idList) {
                MatSlicer SetDouble $s 1
                MatSlicer SetCursorPosition $s 256 256
            }
        }
        "Single512" {
            #unpack the controls for the fiducial selection mode
            pack forget $Gui(fMatVol) $Gui(fMatMid)
            foreach s $Slice(idList) {
                MatSlicer SetDouble $s 0
                MatSlicer SetCursorPosition $s 128 128
            }
            set s 0
            MatSlicer SetDouble $s 1
            MatSlicer SetCursorPosition $s 256 256
        }
    }
    if {$View(mode) == "Quad256" || $View(mode) == "Quad512" || $View(mode) == "Single512" } {
        # Make the thumbnails for the fiducial selection mode pop up when
        # mouse goes over Orient thumbnail instead of the original slicer controls.
        foreach s $Slice(idList) {
            lower $Gui(fSlice$s).fThumb
            raise $Gui(fSlice$s).fThumbMat
        }
    }
    MatSlicer Update
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsShowSliceControls
# Show the minimized slice controls
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsShowSliceControls {s} {
    global Gui Matrix

    if {$Matrix(FidAlignEntered) == 1} {
        raise $Gui(fSlice$s).fControlsMat
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsHideSliceControls
# Hide the minimized slice controls
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsHideSliceControls {} {
    global Gui Matrix

    if {$Matrix(FidAlignEntered) == 1} {
        lower $Gui(fSlice0).fControlsMat $Gui(fSlice0).fImage
        lower $Gui(fSlice1).fControlsMat $Gui(fSlice1).fImage
        lower $Gui(fSlice2).fControlsMat $Gui(fSlice2).fImage
    }
}


#-------------------------------------------------------------------------------
# .PROC AlignmentsSetRegTabState
# Set the Registration mode tabs to be either active or inactive.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetRegTabState {mode} {
    global Matrix

    if {[info exists Matrix(regMode)] == 0} {
        DevErrorWindow "Alignments: Set the registration mode first."
        return
    }

    #These only affect TPS and FidAlign because of the split view
    switch $Matrix(regMode) {
        "FidAlign" {
            if {[info exists Matrix(rTPS)] == 1} {
                $Matrix(rTPS) config -state $mode
            }
            if {[info exists Matrix(rIntensity)] == 1} {
                $Matrix(rIntensity) config -state $mode
            }
        }
        "TPS" {
            if {[info exists Matrix(rFidAlign)] == 1} {
                $Matrix(rFidAlign) config -state $mode
            }
            if {[info exists Matrix(rIntensity)] == 1} {
                $Matrix(rIntensity) config -state $mode
            }
        }
        default {
            if {[info exists Matrix(rFidAlign)] == 1} {
                $Matrix(rFidAlign) config -state $mode
            }
            if {[info exists Matrix(rTPS)] == 1} {
                $Matrix(rTPS) config -state $mode
            }
            if {[info exists Matrix(rIntensity)] == 1} {
                $Matrix(rIntensity) config -state $mode
            }
        }
    }
    #set the volume buttons
    $Matrix(mbVolume) config -state $mode
    $Matrix(mbRefVolume) config -state $mode
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetColorCorrespondence
#
# Shows the amount of convergence given two volumes, reference volume and the
# volume to move. Colors the reference volume red and the volume to move blue.
#
# NOTE: Im setting the correspondence colors to be "desert" and "ocean"
# if these names change, then this needs to be changed too
#
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC AlignmentsSetColorCorrespondence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsSetColorCorrespondence {} {
    global Matrix Lut Volume

    #Check to see that the volume to move and the reference volume are set.
    if {$Matrix(volume) == $Volume(idNone) || $Matrix(refVolume) == $Volume(idNone)} {
        tk_messageBox -icon error -message "Either the reference volume or the volume to move has not yet been set"
        set Matrix(regMode) ""
        raise $Matrix(fAlignBegin)
        return
    }

    if {$Matrix(colorCorresp) == 1} {

        MainSlicesSetVolumeAll Fore $Matrix(refVolume)
        MainSlicesSetVolumeAll Back $Matrix(volume)

        #set the reference volume to be red
        set Volume(activeID) $Matrix(refVolume)
        foreach v $Lut(idList) {
            if {$Lut($v,name) == "Desert"} {
                MainVolumesSetParam LutID $v
                MainVolumesSetParam AutoThreshold 1
            }
        }

        #set the volume to move to be blue
        set Volume(activeID) $Matrix(volume)
        foreach v $Lut(idList) {
            if {$Lut($v,name) == "Ocean"} {
                MainVolumesSetParam LutID $v
                MainVolumesSetParam AutoThreshold 1
            }
        }

    #if the color correspondence button is set to off then set both volumes to grey
    } elseif {$Matrix(colorCorresp) == 0} {
        foreach v $Lut(idList) {
            if {$Lut($v,name) == "Gray"} {
                set Volume(activeID) $Matrix(refVolume)
                MainVolumesSetParam LutID $v
                MainVolumesSetParam AutoThreshold
                set Volume(activeID) $Matrix(volume)
                MainVolumesSetParam LutID $v
                MainVolumesSetParam AutoThreshold
            }
        }
    }
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsMainFileCloseUpdated
# Called when File close is seleceted from the main menu.
# Added this because the new slice actors allowing the viewing of the split
# view were not being deleted when the file was closed.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsMainFileCloseUpdated {} {
    global Matrix Slice

    if { $Matrix(FidAlignEntered) == 1} {
       AlignmentsFidAlignCancel
    }
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsExit
# Called when the Alignments module is exit, NOT CALLED
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsExit {} {
    global Matrix

    popEventManager
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC AlignmentsEnter
# Called when the Alignments module is enter
# Set the volumes chosen automatically if they are not already chosen.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AlignmentsEnter {} {
    global Matrix Volume Slice

    if {$Matrix(volume) == $Volume(idNone) } {
       AlignmentsSetVolume $Slice(0,foreVolID)
    }
    if {$Matrix(refVolume) == $Volume(idNone) } {
       AlignmentsSetRefVolume $Slice(0,backVolID)
    }

    popEventManager
    Render3D
}


