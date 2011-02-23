#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ModelMaker.tcl,v $
#   Date:      $Date: 2006/03/06 19:24:23 $
#   Version:   $Revision: 1.63 $
# 
#===============================================================================
# FILE:        ModelMaker.tcl
# PROCEDURES:  
#   ModelMakerInit
#   ModelMakerUpdateMRML
#   ModelMakerBuildGUI
#   ModelMakerTransform volume
#   ModelMakerWrite
#   ModelMakerWriteAll
#   ModelMakerRead
#   ModelMakerEnter
#   ModelMakerSetVolume v
#   ModelMakerCreate
#   ModelMakerCreateAll
#   ModelMakerLabelCallback
#   ModelMakerMultipleLabelCallback which
#   ModelMakerSmoothWrapper m
#   ModelMakerSmooth m iterations
#   ModelMakerReverseNormals m
#   ModelMakerMarch m v decimateIterations smoothIterations
#   ModelMakerSetJointSmooth
#   ModelMakerSetStartLabelButtonCallback
#   ModelMakerSetStartLabelReturnCallback
#   ModelMakerSetEndLabelButtonCallback
#   ModelMakerSetEndLabelReturnCallback
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC ModelMakerInit
# Set the global vars for this module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerInit {} {
    global ModelMaker Module Volume

    set m ModelMaker

    # Module Summary Info
    set Module($m,overview) "Make 3D surface models from segmented data."
    set Module($m,author) "Core"
    set Module($m,category) "Application"

      # Define Tabs
    set Module($m,row1List) "Help Create Multiple Edit Save"
    set Module($m,row1Name) "{Help} {Create} {Create Multiple} {Edit} {Save} "
    set Module($m,row1,tab) Create

    # Define Procedures
    set Module($m,procGUI) ModelMakerBuildGUI
    set Module($m,procMRML) ModelMakerUpdateMRML
    set Module($m,procEnter) ModelMakerEnter

    # Define Dependencies
    set Module($m,depend) "Labels"

    # Set Version Info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.63 $} {$Date: 2006/03/06 19:24:23 $}]

    # Create
    set ModelMaker(idVolume) $Volume(idNone)
    set ModelMaker(name) skin
    set ModelMaker(smooth) 20
    set ModelMaker(decimate) 1
    set ModelMaker(marching) 0
    set ModelMaker(label2) 0
    set ModelMaker(UseSinc) 1

    # Create Multiple Modles
    set ModelMaker(startName) ""
    set ModelMaker(endName) ""
    set ModelMaker(startLabel) -1
    set ModelMaker(endLabel) -1
    set ModelMaker(jointSmooth) 0

    # Edit
    set ModelMaker(edit,smooth) 20
    set ModelMaker(prefix) ""


    #### Splits normals at sharp points by point duplication
    ## Can be "Off" or "On"
    set ModelMaker(SplitNormals) On

    #### Calculates the Point Normals
    ## Can be "Off" or "On"
    set ModelMaker(PointNormals) On
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerUpdateMRML
# Set the active volume.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerUpdateMRML {} {
    global ModelMaker Volume

    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $ModelMaker(idVolume)] == -1} {
        ModelMakerSetVolume $n
    }

    # Volume menu
    #---------------------------------------------------------------------------
    foreach m $ModelMaker(mVolume) {
        $m delete 0 end
        foreach v $Volume(idList) {
            $m add command -label [Volume($v,node) GetName] -command \
                "ModelMakerSetVolume $v"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerBuildGUI
# Build the gui for this module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerBuildGUI {} {
    global Gui ModelMaker Model Module Label Matrix Volume

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Display
    #   Title
    #   All
    #   Grid
    # Properties
    # Clip
    #   Help
    #   Grid
    # Create
    # Edit
    #   
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "Description by Tab:<BR>
<UL>
<LI><B>Create:</B><BR>Set the <B>Volume</B> to the labelmap you wish to
create a surface model from.  When you press the <B>Create</B> button
a surface will be created that bounds all voxels with value equal to
<B>Label</B>. Use the <B>Edit</B> tab to apply additional smoothing,
or change the model's position.  The new model will not be written to 
hard disk until you save it using the <B>Save</B> tab.
<B>Filter Type</B> controls the type of smoothing done after the model is
built.  <B>Sinc</B> with 20 smoothing steps is the default as of January 2003; the 
smoothing in earlier version of Slicer used <B>Laplacian</B> with 5 smoothing
steps.
<BR><LI><B>Create Multiple:</B><BR> Create multiple models from a <B>Volume</B> labelmap.
Uses the Smooth, Decimate, Split Normals values from the Create tab, will use the 
Filter Type from the Create tab if Joint Smoothing is not on. Joint Smoothing results
in the created models interlocking exactly (before decimation), otherwise they are smoothed after creation.
<BR><LI><B>Edit:</B><BR> Select the model you wish to edit as <B>Active Model</B>
and then apply one of the effects listed. To transform the polygon points
by a transform, select a <B>Matrix</B> that already exists.  If you need to
create one first, go to the <B>Data</B> module, and press the <B>Add Transform</B>
button.<BR>
<B>TIP</B> If you created a model using the voxel size, but no other header
information, such as the volume's position and orientation in space, then
transform the model to align with the volume under the <B>Transform from 
ScaledIJK to RAS</B> section.
<BR><LI><B>Save:</B> Write the model's polygon (*.vtk) file to disk. Also save your MRML file by selecting <B>Save</B> from the <B>File</B> menu.</UL>"

    regsub -all "\n" $help { } help
    MainHelpApplyTags ModelMaker $help
    MainHelpBuildGUI ModelMaker

    #-------------------------------------------
    # Create frame
    #-------------------------------------------
    set fCreate $Module(ModelMaker,fCreate)
    set f $fCreate

    foreach frm " Volume Label Grid Apply Results Advanced Filter" {
        frame $f.f$frm -bg $Gui(activeWorkspace)
        pack  $f.f$frm -side top -pady $Gui(pad)
    }

    #-------------------------------------------
    # Create->Volume frame
    #-------------------------------------------
    set f $fCreate.fVolume

    # Volume menu
    eval {label $f.lVolume -text "Volume:"} $Gui(WLA)

    eval {menubutton $f.mbVolume -text "None" -relief raised -bd 2 -width 18 \
        -menu $f.mbVolume.m} $Gui(WMBA)
    eval {menu $f.mbVolume.m} $Gui(WMA)
    pack $f.lVolume -padx $Gui(pad) -side left -anchor e
    pack $f.mbVolume -padx $Gui(pad) -side left -anchor w

    # Save widgets for changing
    set ModelMaker(mbVolume) $f.mbVolume
    set ModelMaker(mVolume)  $f.mbVolume.m

    #-------------------------------------------
    # Create->Label frame
    #-------------------------------------------
    set f $fCreate.fLabel

    eval {button $f.bLabel -text "Label:" \
        -command "ShowLabels ModelMakerLabelCallback"} $Gui(WBA)
    eval {entry $f.eLabel -width 6 -textvariable Label(label)} $Gui(WEA)
    eval {entry $f.eLabel2 -width 6 -textvariable ModelMaker(label2)} $Gui(WEA)
    bind $f.eLabel <Return>   "LabelsFindLabel; ModelMakerLabelCallback"
    bind $f.eLabel <FocusOut> "LabelsFindLabel; ModelMakerLabelCallback"
    eval {entry $f.eName -width 10 \
        -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bLabel $f.eLabel $f.eName \
        -padx $Gui(pad) -pady $Gui(pad) -sticky e

    lappend Label(colorWidgetList) $f.eName

    #-------------------------------------------
    # Create->Advanced frame
    #-------------------------------------------
    set f $fCreate.fAdvanced

    foreach frame "Title Choice" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    set f $fCreate.fAdvanced.fTitle

    eval {label $f.l -text "Advanced Options"} $Gui(WLA)
    eval {label $f.l2 -justify left -text "\nSplitting Normals is useful for visualizing \nsharp features. However, it creates holes\n in surfaces which affects measurements."} $Gui(WLA)
    pack $f.l $f.l2 -side top -pady 1

    set f $fCreate.fAdvanced.fChoice
    DevAddLabel $f.f "Split Normals:"
    pack $f.f -side left -padx $Gui(pad) 

    # frame $f.f -bg $Gui(activeWorkspace)
    foreach p "On Off" {
        eval {radiobutton $f.fr$p \
                -text "$p" \
                -variable ModelMaker(SplitNormals) -value $p -width 5 \
                -indicatoron 0} $Gui(WCA)
        pack $f.fr$p -side left -padx 0
    }

    
    

    #-------------------------------------------
    # Create->Grid frame
    #-------------------------------------------
    set f $fCreate.fGrid

    foreach Param "Name Smooth Decimate" width "13 7 7" {
        eval {label $f.l$Param -text "$Param:"} $Gui(WLA)
        eval {entry $f.e$Param -width $width \
            -textvariable ModelMaker([Uncap $Param])} $Gui(WEA)
        grid $f.l$Param $f.e$Param  -padx $Gui(pad) -pady $Gui(pad) -sticky e
        grid $f.e$Param -sticky w
    }

    # In LabelsSelectLabel, Label(name) is set, let it know that it needs to set
    # ModelMaker(name) as well
    lappend ::Label(nameList) ::ModelMaker(name)

    #-------------------------------------------
    # Create->Filter frame
    #-------------------------------------------
    set f $fCreate.fFilter

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side left -padx 5

    eval {label $f.fTitle.lFilter -text "Filter Type:"} $Gui(WLA)
    pack $f.fTitle.lFilter

    foreach text "Sinc Laplacian" value "1 0" \
        width "6 8" {
        eval {radiobutton $f.fBtns.rFilter$value -width $width \
            -text "$text" -value "$value" -variable ModelMaker(UseSinc) \
            -indicatoron 0} $Gui(WCA)
        pack $f.fBtns.rFilter$value -side left -pady 2
    }

    #-------------------------------------------
    # Create->Apply frame
    #-------------------------------------------
    set f $fCreate.fApply

    eval {button $f.bCreate -text "Create" -width 7 \
        -command "ModelMakerCreate; Render3D"} $Gui(WBA)
    pack $f.bCreate -side top -pady $Gui(pad)
    set ModelMaker(bCreate) $f.bCreate

    #-------------------------------------------
    # Create->Results frame
    #-------------------------------------------
    set f $fCreate.fResults

    eval {label $f.l -justify left -text ""} $Gui(WLA)
    pack $f.l -side top -pady 1
    set ModelMaker(msg) $f.l



    #-------------------------------------------
    # Multiple frame
    #-------------------------------------------
    set fMultiple $Module(ModelMaker,fMultiple)
    set f $fMultiple

    foreach fr "Volume Label Apply" {
        frame $f.f$fr -bg $Gui(activeWorkspace)
        pack $f.f$fr -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Multiple->Volume frame
    #-------------------------------------------
    set f $fMultiple.fVolume
    eval {label $f.lVolume -text "Volume:"} $Gui(WLA)

    eval {menubutton $f.mbVolume -text "None" -relief raised -bd 2 -width 18 \
        -menu $f.mbVolume.m} $Gui(WMBA)
    eval {menu $f.mbVolume.m} $Gui(WMA)
    pack $f.lVolume -padx $Gui(pad) -side left -anchor e
    pack $f.mbVolume -padx $Gui(pad) -side left -anchor w

    # Save widgets for changing
    lappend ModelMaker(mbVolume) $f.mbVolume
    lappend ModelMaker(mVolume)  $f.mbVolume.m

    #-------------------------------------------
    # Multiple->Label frame
    #-------------------------------------------
    set f $fMultiple.fLabel

    # label to start making models from
    eval {button $f.bStartLabel -text "Starting Label:" \
        -command "ModelMakerSetStartLabelButtonCallback"} $Gui(WBA)
    eval {entry $f.eStartLabel -width 6 -textvariable ModelMaker(startLabel)} $Gui(WEA)
    eval {entry $f.eStartName -width 20 -textvariable ModelMaker(startName)} $Gui(WEA)
    bind $f.eStartLabel <Return>   {ModelMakerSetStartLabelReturnCallback}
    grid $f.bStartLabel $f.eStartLabel $f.eStartName \
         -padx $Gui(pad) -pady $Gui(pad) -sticky e

    # label to end making models from
    eval {button $f.bEndLabel -text "Ending Label:" \
        -command "ModelMakerSetEndLabelButtonCallback"} $Gui(WBA)
    eval {entry $f.eEndLabel -width 6 -textvariable ModelMaker(endLabel)} $Gui(WEA)
    eval {entry $f.eEndName -width 20 -textvariable ModelMaker(endName)} $Gui(WEA)
    bind $f.eEndLabel <Return> {ModelMakerSetEndLabelReturnCallback}
    grid $f.bEndLabel $f.eEndLabel $f.eEndName \
         -padx $Gui(pad) -pady $Gui(pad) -sticky e



    #-------------------------------------------
    # Multiple->Apply frame
    #-------------------------------------------
    set f $fMultiple.fApply

    eval {checkbutton $f.cJointSmooth \
       -text "Do joint smoothing" -variable ModelMaker(jointSmooth) -width 19 \
       -indicatoron 0 -command ModelMakerSetJointSmooth} $Gui(WCA)
    TooltipAdd $f.cJointSmooth "Select to turn on option to create fully interlocking models, otherwise they will be smoothed separately"
    pack $f.cJointSmooth -side top -padx 0

    eval {button $f.bAll -text "Create All" -width 15 -command "ModelMakerCreateAll; Render3D"} $Gui(WBA)
    TooltipAdd $f.bAll "Create models from all non zero labels in the active volume, between start and end labels. Uses settings from the Create tab."
    set ModelMaker(bCreateAll) $f.bAll

if {0} {
    eval {button $f.bAllJointSmooth -text "Create Joined" -width 15 -command "ModelMakerCreateAll 1; Render3D"} $Gui(WBA)
    TooltipAdd $f.bAllJointSmooth "Create smoothly joined models from all non zero labels in the active volume, between start and end labels. Can be very slow."
    set ModelMaker(bCreateAllJoint) $f.bAllJointSmooth
}
    pack $f.bAll -side top -pady $Gui(pad)
    

 


    #-------------------------------------------
    # Edit frame
    #-------------------------------------------
    set fEdit $Module(ModelMaker,fEdit)
    set f $fEdit

    frame $f.fActive   -bg $Gui(activeWorkspace)
    frame $f.fGrid     -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fPosition -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fVolume   -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack  $f.fActive $f.fGrid $f.fPosition $f.fVolume \
        -side top -padx $Gui(pad) -pady 10 -fill x

    #-------------------------------------------
    # Edit->Active frame
    #-------------------------------------------
    set f $fEdit.fActive

    eval {label $f.lActive -text "Active Model: "} $Gui(WLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) -pady 0 

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Model(mbActiveList) $f.mbActive
    lappend Model(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Edit->Grid frame
    #-------------------------------------------
    set f $fEdit.fGrid

    eval {label $f.lTitle -text "Apply an Effect"} $Gui(WTA)
    frame $f.fSmooth  -bg $Gui(activeWorkspace)
    frame $f.fReverse -bg $Gui(activeWorkspace)
    # BUG: Reverse doesn't seem to be working yet, so I've stripped it.
    pack $f.lTitle $f.fSmooth -side top -pady $Gui(pad)

    set Param Smooth
    set ff $f.fSmooth
    eval {label $ff.l$Param -text "$Param:"} $Gui(WLA)
    eval {entry $ff.e$Param -width 7 \
        -textvariable ModelMaker(edit,[Uncap $Param])} $Gui(WEA)
    eval {button $ff.b$Param -text "$Param" -width 7 \
        -command "ModelMakerSmoothWrapper; Render3D"} $Gui(WBA)
    grid $ff.l$Param $ff.e$Param $ff.b$Param \
        -padx $Gui(pad) -pady $Gui(pad) -sticky e
    grid $ff.e$Param -sticky w


    set Param Reverse
    set ff $f.fReverse
    eval {label $ff.l$Param -text "Reverse Normals:"} $Gui(WLA)
    eval {button $ff.b$Param -text "$Param" -width 8 \
        -command "ModelMakerReverseNormals; Render3D"} $Gui(WBA)
    grid $ff.l$Param $ff.b$Param \
        -padx $Gui(pad) -pady $Gui(pad) -sticky e

        #-------------------------------------------
        # Edit->Grid->Filter frame  (added inside the Smooth frame)
        #-------------------------------------------
    set f $fEdit.fGrid.fSmooth.fFilter
    frame $f -bg $Gui(activeWorkspace)
    grid $f -columnspan 3

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side left -padx 5

    eval {label $f.fTitle.lFilter -text "Filter Type:"} $Gui(WLA)
    pack $f.fTitle.lFilter

    foreach text "Sinc Laplacian" value "1 0" \
        width "6 8" {
        eval {radiobutton $f.fBtns.rFilter$value -width $width \
            -text "$text" -value "$value" -variable ModelMaker(UseSinc) \
            -indicatoron 0} $Gui(WCA)
        pack $f.fBtns.rFilter$value -side left -padx 4 -pady 2
    }

    #-------------------------------------------
    # Edit->Position frame
    #-------------------------------------------
    set f $fEdit.fPosition

    eval {label $f.l -text "Transform by Any Matrix"} $Gui(WTA)
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side top -pady $Gui(pad)

    eval {label $f.f.l -text "Matrix: "} $Gui(WLA)
    eval {menubutton $f.f.mb -text "None" -relief raised -bd 2 -width 13 \
        -menu $f.f.mb.m} $Gui(WMBA)
    eval {menu $f.f.mb.m} $Gui(WMA)
    eval {button $f.f.b -text "Apply" -width 6 \
        -command "ModelMakerTransform 0; Render3D"} $Gui(WBA)
    pack $f.f.l $f.f.mb $f.f.b -side left -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Matrix(mbActiveList) $f.f.mb
    lappend Matrix(mActiveList)  $f.f.mb.m

    #-------------------------------------------
    # Edit->Volume frame
    #-------------------------------------------
    set f $fEdit.fVolume

    eval {label $f.l -text "Transform from ScaledIJK to RAS"} $Gui(WTA)
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side top -pady $Gui(pad)

    eval {label $f.f.l -text "Volume: "} $Gui(WLA)
    eval {menubutton $f.f.mb -text "None" -relief raised -bd 2 -width 13 \
        -menu $f.f.mb.m} $Gui(WMBA)
    eval {menu $f.f.mb.m} $Gui(WMA)
    eval {button $f.f.b -text "Apply" -width 6 \
        -command "ModelMakerTransform 1; Render3D"} $Gui(WBA)
    pack $f.f.l $f.f.mb $f.f.b -side left -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.f.mb
    lappend Volume(mActiveList)  $f.f.mb.m

    #-------------------------------------------
    # Save frame
    #-------------------------------------------
    set fSave $Module(ModelMaker,fSave)
    set f $fSave

    frame $f.fActive -bg $Gui(activeWorkspace)
    frame $f.fWrite  -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack  $f.fActive $f.fWrite \
        -side top -padx $Gui(pad) -pady 10 -fill x

    #-------------------------------------------
    # Save->Active frame
    #-------------------------------------------
    set f $fSave.fActive

    eval {label $f.lActive -text "Active Model: "} $Gui(WLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) -pady 0 

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Model(mbActiveList) $f.mbActive
    lappend Model(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Save->Write frame
    #-------------------------------------------
    set f $fSave.fWrite

    eval {label $f.l1 -text "Save model as a VTK file"} $Gui(WTA)
    eval {label $f.l2 -text "File Prefix (without .vtk):"} $Gui(WLA)
    eval {entry $f.e -textvariable ModelMaker(prefix) -width 50} $Gui(WEA)
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l1 -side top -pady $Gui(pad) -padx $Gui(pad)
    pack $f.l2 -side top -pady $Gui(pad) -padx $Gui(pad) -anchor w
    pack $f.e -side top -pady $Gui(pad) -padx $Gui(pad) -expand 1 -fill x
    pack $f.f -side top -pady $Gui(pad) -padx $Gui(pad)

    eval {button $f.f.bSave -text "Save" -width 5 \
        -command "ModelMakerWrite; Render3D"} $Gui(WBA)
    eval {button $f.f.bSaveAll -text "Save All" -width 8 \
        -command "ModelMakerWriteAll; Render3D"} $Gui(WBA)
    TooltipAdd $f.f.bSaveAll "Save all unsaved models with automatic filename generation, in the directory you choose"
    eval {button $f.f.bRead -text "Read" -width 5 \
        -command "ModelMakerRead; Render3D"} $Gui(WBA)
    pack $f.f.bSave $f.f.bSaveAll $f.f.bRead -side left -padx $Gui(pad)
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerTransform
# Transform a model.
# .ARGS
# int volume volume id
# .END
#-------------------------------------------------------------------------------
proc ModelMakerTransform {volume} {
    global ModelMaker Model Volume Matrix Module
    
    if {$volume == 1} {
        # See if the volume exists
        if {[lsearch $Volume(idList) $Volume(activeID)] == -1} {
            tk_messageBox -message "Please select a volume first."
            return
        }

        set m $Model(activeID)
        set v $Volume(activeID)
    
        set mat [Volume($v,node) GetPosition]
    } else {
        # See if the matrix exists
        if {[lsearch $Matrix(idList) $Matrix(activeID)] == -1} {
            tk_messageBox -message "Please select a matrix first."
            return
        }
        set m $Model(activeID)
        set v $Matrix(activeID)
    
        set mat [[Matrix($v,node) GetTransform] GetMatrix]
    }

    vtkTransform tran
    # special trick to avoid vtk 4.2 legacy hack message 
    # (adds a concatenated identity transform to the transform)
    if { [info commands __dummy_transform] == "" } {
        vtkTransform __dummy_transform
    }
    tran SetInput __dummy_transform
    tran Concatenate $mat

    vtkTransformPolyDataFilter transformer
    transformer SetInput $Model($m,polyData)
    transformer SetTransform tran
    [transformer GetOutput] ReleaseDataFlagOn
    transformer Update
    
    set p normals
    vtkPolyDataNormals $p
    $p ComputePointNormals$ModelMaker(PointNormals)
    $p SetInput [transformer GetOutput]
    $p SetFeatureAngle 60
    $p Splitting$ModelMaker(SplitNormals)
    [$p GetOutput] ReleaseDataFlagOn

    set p stripper
    vtkStripper $p
    $p SetInput [normals GetOutput]
    [$p GetOutput] ReleaseDataFlagOff

    # polyData will survive as long as it's the input to the mapper
    set Model($m,polyData) [$p GetOutput]
    $Model($m,polyData) Update
    foreach r $Module(Renderers) {
        Model($m,mapper,$r) SetInput $Model($m,polyData)
    }
    stripper SetOutput ""
    foreach p "transformer normals stripper" {
        $p SetInput ""
        $p Delete
    }
    tran Delete

    # Mark this model as unsaved
    set Model($m,dirty) 1
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerWrite
# Write out the active model using MainModelsWrite.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerWrite {} {
    global ModelMaker Model

    # Show user a File dialog box
    set m $Model(activeID)
    set ModelMaker(prefix) [MainFileSaveModel $m $ModelMaker(prefix)]
    if {$ModelMaker(prefix) == ""} {
        if {$::Module(verbose)} { 
            puts "ModelMakerWrite: empty prefix for model $m" 
        }
        return
    }

    # Write
    MainModelsWrite $m $ModelMaker(prefix)

    # Prefix changed, so update the Models->Props tab
    MainModelsSetActive $m
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerWriteAll
# Save all models, picking a directory first and then saving with a file name made 
# up of the model name and the node number.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerWriteAll { {prefix ""} } {
    global ModelMaker Model

    if {$::Module(verbose)} {
        puts "ModelMakerWriteAll: idList = $Model(idList)"
    }
    # set the prefix, will append the model name to it
    # set ModelMaker(prefix) [MainFileSaveModel $m $ModelMaker(prefix)]
    if {$prefix != "" } {
    set ModelMaker(prefix) $prefix
    } else {
    set ModelMaker(prefix) [tk_chooseDirectory \
                                -initialdir $::env(SLICER_HOME) \
                                -mustexist true \
                                -title "Select Directory In Which To Save Model Files" \
                                -parent .tMain ]
    }
    if {$ModelMaker(prefix) == ""} {
        if {$::Module(verbose)} { puts "ModelMakeWrite: empty prefix for model $m" }
        return
    }

    foreach m $Model(idList) {
        # don't need to check the dirty flag, it will be done further down
        if {$::Module(verbose)} {
            puts "Saving with prefix ${ModelMaker(prefix)}"
        }
        # Write
        MainModelsWrite $m [file join ${ModelMaker(prefix)} [Model($m,node) GetName]$m]
        
        # Prefix changed, so update the Models->Props tab
        MainModelsSetActive $m
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerRead
# Prompt the user for a file, and then read it in. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerRead {} {
    global ModelMaker Model Mrml

    
    # Show user a File dialog box
    set m $Model(activeID)
    set ModelMaker(prefix) [MainFileOpenModel $m $ModelMaker(prefix)]
    if {$ModelMaker(prefix) == ""} {
        if {$::Module(verbose)} { puts "ModelMakerRead: empty prefix for model $m" }
        return
    }

    if {$::Module(verbose)} {
        puts "ModelMakerRead, active model = $m, prefix = $ModelMaker(prefix)"
    }

    # Read
    Model($m,node) SetFileName $ModelMaker(prefix).vtk
    Model($m,node) SetFullFileName \
        [file join $Mrml(dir) [Model($m,node) GetFileName]]
    if {[MainModelsRead $m] < 0} {
        return
    }

    # Prefix changed, so update the Models->Props tab
    MainModelsSetActive $m
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerEnter
# Resets the values to those set from the current active volume.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerEnter {} {
    global Volume
    
    ModelMakerSetVolume $Volume(activeID)
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSetVolume
# Initialise the labels, taken as high and low values in the current volume label map.<br>
# Only change things if it's a new volume, and if the new volume is a label map.
# .ARGS
# int v volume id
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSetVolume {v} {
    global ModelMaker Volume Label

    if {$::Module(verbose)} {
        puts "\nModelMakerSetVolume, Label(label) = $Label(label). New vol = $v, old vol = $ModelMaker(idVolume)"
    }

    if {$ModelMaker(idVolume) == $v} {
        if {$::Module(verbose)} {
            puts "ModelMakerSetVolume: not doing anything, it's the same volume."
        }
        return
    }

    if {[Volume($v,node) GetName] != "None" &&
        [Volume($v,node) GetLabelMap] == 0} {
        DevWarningWindow "WARNING: active volume '[Volume($v,node) GetName]' is not a label map. Please select a different volume."
    }

    set ModelMaker(idVolume) $v
    
    # Change button text
    foreach m $ModelMaker(mbVolume) {
        $m config -text [Volume($v,node) GetName]
    }

    # init multiple model start to the lowest value in the volume (or 1 if zero)
    set Label(label) [Volume($v,vol) GetRangeLow]
    if {$Label(label) == 0} {
        set Label(label) 1
    }

    # find the name for this label
    LabelsFindLabel
    # then set it
    ModelMakerMultipleLabelCallback start


    # now set up the single one, since it uses the high end of the range

    # Initialize the label to the highest value in the volume
    set Label(label) [Volume($v,vol) GetRangeHigh]
    LabelsFindLabel
    ModelMakerLabelCallback
    set ModelMaker(label2) [Volume($v,vol) GetRangeLow]

    # For the create multiple models tab - the end is already set up
    ModelMakerMultipleLabelCallback end

}

#-------------------------------------------------------------------------------
# .PROC ModelMakerCreate
# Create a model from the voxels in the ModelMaker(idVolume) volume with the label Label(label). <br>
# Will turn off the jointSmoothing option before calling ModelMakerMarch, and then 
# return it to it's prior value.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerCreate {} {
    global Model ModelMaker Label

    # Validate name
    if {$ModelMaker(name) == ""} {
        tk_messageBox -message "Please enter a name that will allow you to distinguish this model."
        return
    }
    if {[ValidateName $ModelMaker(name)] == 0} {
        tk_messageBox -message "The name can consist of letters, digits, dashes, or underscores"
        return
    }

    # Validate smooth
    if {[ValidateInt $ModelMaker(smooth)] == 0} {
        tk_messageBox -message "The number of smoothing iterations must be an integer."
        return
    }

    # Validate decimate
    if {[ValidateInt $ModelMaker(decimate)] == 0} {
        tk_messageBox -message "The number of decimate iterations must be an integer."
        return
    }

    # Disable button to prevent another
    $ModelMaker(bCreate) config -state disabled

    # Create the model's MRML node
    set n [MainMrmlAddNode Model]
    $n SetName  $ModelMaker(name)
    $n SetColor $Label(name)

    # Guess the prefix
    set ModelMaker(prefix) $ModelMaker(name)

    # Create the model
    set m [$n GetID]
    if {$::Module(verbose)} {
        puts "ModelMakerCreate m = $m"
    }
    MainModelsCreate $m

    # Registration
    set v $ModelMaker(idVolume)
    Model($m,node) SetRasToWld [Volume($v,node) GetRasToWld]

    # adding a special case due to possibility of building multiple models through
    # successive calls to ModelMakerMarch _ reset jointSmooth to 0, and then reset it
    set jointSmooth $ModelMaker(jointSmooth)
    set ModelMaker(jointSmooth) 0

    if {[ModelMakerMarch $m $v $ModelMaker(decimate) $ModelMaker(smooth)] != 0} {
        MainModelsDelete $m
        set ModelMaker(jointSmooth) $jointSmooth
        $ModelMaker(bCreate) config -state normal
        if {$::Module(verbose)} {
            puts "ERROR: ModelMakerMarch failed, deleted model $m, model id list = $::Model(idList), Model(idListDelete) = $Model(idListDelete)"
        }
        return
    }

    # and reset it to the old value
    set ModelMaker(jointSmooth) $jointSmooth

    $ModelMaker(msg) config -text "\
Marching cubes: $ModelMaker(t,mcubes) sec.\n\
Decimate: $ModelMaker(t,decimator) sec.\n\
Smooth: $ModelMaker(t,smoother) sec.\n\
$ModelMaker(n,mcubes) polygons reduced to $ModelMaker(n,decimator)."

    if {$::Module(verbose)} {
        puts "After marching cubes:"
        DevPrintMatrix4x4 [Model($m,node) GetRasToWld] "Model $m RAS -> WLD"
    }

    # put the model inside the same transform as the source volume
    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set midx 0} {$midx < $nitems} {incr midx} {
        if { [Mrml(dataTree) GetNthItem $midx] == "Model($m,node)" } {
            break
        }
    }
    if { $midx < $nitems } {
        Mrml(dataTree) RemoveItem $midx
        Mrml(dataTree) InsertAfterItem Volume($v,node) Model($m,node)
        MainUpdateMRML
        if {$::Module(verbose)} {
            puts "Model($m,node) placed after item Volume($v,node) in mrml data tree"
        }
    }

    

    MainUpdateMRML

    if {$::Module(verbose)} {
        puts "After main mrml update:"
        DevPrintMatrix4x4 [Model($m,node) GetRasToWld] "Model $m RAS -> WLD"
    }

    MainModelsSetActive $m
    $ModelMaker(bCreate) config -state normal


    set name [Model($m,node) GetName]
    # tk_messageBox -message "The model '$name' has been created."

    return $m
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerCreateAll
# Create all models from the selected range of labels. <br>
# Refers to the ModelMaker(jointSmooth) flag, which is set to 1 if wish to do 
# preliminary smoothing so all models fit together like a jigsaw, 0 if wish to smooth models independently
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerCreateAll {{AskSureFlag 1}} {
    global Model ModelMaker Label Module Gui

    set numModels 0
    set skippedModels ""
    set madeModels ""
    # set this model id to an invalid number as no models might be made
    set m -1

    # Validate smooth
    if {[ValidateInt $ModelMaker(smooth)] == 0} {
        tk_messageBox -message "The number of smoothing iterations must be an integer."
        return
    }

    # Validate decimate
    if {[ValidateInt $ModelMaker(decimate)] == 0} {
        tk_messageBox -message "The number of decimate iterations must be an integer."
        return
    }

    # Disable button to prevent another
    $ModelMaker(bCreateAll) config -state disabled
    
    # get the volume id that holds the labels
    set volid $ModelMaker(idVolume)

    # get the range of values in the volume
    set imdata [Volume($volid,vol) GetOutput]

    set startLabel $ModelMaker(startLabel)
    if {$startLabel < 1} {
        set startLabel 1
    }
    
    set scalarType [$imdata GetScalarType]
    if {$scalarType == 3} {
        if {$startLabel > 255} {
            puts "WARNING: data scalar type is char, using start label of 255 instead of $startLabel"
            set startLabel 255
        }
        if {$ModelMaker(endLabel) < 255} {
            set lastLabel $ModelMaker(endLabel)
        } else {
            set lastLabel 255
        }
    }  else {
        set lastLabel $ModelMaker(endLabel)
    }

    if {$AskSureFlag} { 
    set sure [tk_messageBox -type yesno -message "About to create models from labels $startLabel to $lastLabel out of volume $volid, are you sure?"]
    if {$sure == "no"} {
        DevInfoWindow "Aborting model creation..."
        $ModelMaker(bCreateAll) config -state normal
        return
    }
    }

    # calculate the histogram, how many of each label
    if {$::Module(verbose)} {
        puts "ModelMakerCreateAll: calculating histogram on image data for vol $volid"
    }
    catch "histo${volid} Delete"
    vtkImageAccumulate histo${volid}
      histo${volid} SetInput $imdata
      histo${volid} SetComponentExtent 0 1023 0 0 0 0
      histo${volid} SetComponentOrigin 0 0 0
      histo${volid} SetComponentSpacing 1 1 1
      set Gui(progressText) "Calculating histogram for v=$volid"
      histo${volid} AddObserver StartEvent MainStartProgress
      histo${volid} AddObserver ProgressEvent "MainShowProgress histo${volid}"
      histo${volid} AddObserver EndEvent MainEndProgress

    if {$::Module(verbose)} {
        puts "About to call marching cubes, creating ModelMaker(cubes,$volid)"
    }
    catch "ModelMaker(cubes,$volid) Delete"
    vtkDiscreteMarchingCubes ModelMaker(cubes,$volid)

    # The spacing is accounted for in the rasToVtk transform, 
    # so we have to remove it here, or mcubes will use it.
    set spacing [$imdata GetSpacing]
    set origin  [$imdata GetOrigin]
    $imdata SetSpacing 1 1 1
    $imdata SetOrigin 0 0 0
      ModelMaker(cubes,$volid) SetInput $imdata
      set Gui(progressText) "Discrete Marching Cubes for v=$volid"
      ModelMaker(cubes,$volid) AddObserver StartEvent MainStartProgress
      ModelMaker(cubes,$volid) AddObserver ProgressEvent "MainShowProgress ModelMaker(cubes,$volid)"
      ModelMaker(cubes,$volid) AddObserver EndEvent MainEndProgress
    set iterations $ModelMaker(smooth)
    
    ModelMaker(cubes,$volid) GenerateValues [expr $lastLabel - $startLabel + 1] $startLabel $lastLabel
      ModelMaker(cubes,$volid) Update 
    

    if {$ModelMaker(jointSmooth) == 1} {
        set passBand 0.001
        if {$::Module(verbose)} {
            puts "Starting joint smoothing, $iterations iterations"
        }
        catch "smoother${volid} Delete"
        vtkWindowedSincPolyDataFilter smoother${volid}
        # save it for use in modelmakermarch
        set ModelMaker(jointSmoother,$volid) smoother${volid}

        set Gui(progressText) "Jointly smoothing models"
        smoother${volid} AddObserver StartEvent MainStartProgress
        smoother${volid} AddObserver ProgressEvent "MainShowProgress smoother${volid}"
        smoother${volid} AddObserver EndEvent MainEndProgress

        smoother${volid} SetInput [ModelMaker(cubes,$volid) GetOutput]
        smoother${volid} SetNumberOfIterations $iterations
        smoother${volid} BoundarySmoothingOff
        smoother${volid} FeatureEdgeSmoothingOff
        smoother${volid} SetFeatureAngle 120
        smoother${volid} SetPassBand $passBand
        smoother${volid} NonManifoldSmoothingOn
        smoother${volid} NormalizeCoordinatesOn
        # smoother${volid} AddObserver EndEvent "puts \"Smoothing complete\""
        smoother${volid} Update
    }

    # now make nodes for all of them
    if {$::Module(verbose)} {
        puts "Making model nodes"
    }
    
    histo${volid} Update
    for {set i $startLabel} {$i <= $lastLabel} {incr i} {
        set freq [[[[histo${volid} GetOutput] GetPointData] GetScalars] GetTuple1 $i]
        if { $freq == 0 } {
            if {$::Module(verbose)} { 
                puts "Skipping $i = $freq"
            }
            lappend skippedModels $i
            continue
        } else {
            if {$::Module(verbose)} { 
                puts "Working on $i = $freq"
            }
            lappend madeModels $i
        }

        
        
        set labelid [MainColorsGetColorFromLabel $i]
        if { $labelid != "" } {
            set labelName [Color($labelid,node) GetName]
        } else {
            set labelName "unknown_$i"
        }

        if { $labelName != "unknown" } {
          
            if {$::Module(verbose)} {
                puts "Creating label $i named $labelName"
            }


            # set up the global vars that ModelMakerMarch needs
        
            # taking the relevant bits from ModelMakerCreate
            set ModelMaker(name) $labelName
            set Label(name) $labelName
            set Label(label) $i

            set n [MainMrmlAddNode Model]
            $n SetName  $ModelMaker(name)
            $n SetColor $Label(name)

            # Guess the prefix
            set ModelMaker(prefix) $ModelMaker(name)

            # Create the model
            set m [$n GetID]
            MainModelsCreate $m

            set v $volid
            Model($m,node) SetRasToWld [Volume($v,node) GetRasToWld]

            # Make the model!
            eval $imdata SetSpacing $spacing
            eval $imdata SetOrigin $origin
            if {[ModelMakerMarch $m $v $ModelMaker(decimate) $ModelMaker(smooth)] != 0} {
                MainModelsDelete $m
                $ModelMaker(bCreateAll) config -state normal
                DevErrorWindow "Problem in ModelMakerMarch for creating all models for vol $v"
                return
            }

            # mark the model as unsaved
            set Model($m,dirty) 1

            # put the model inside the same transform as the source volume
            set nitems [Mrml(dataTree) GetNumberOfItems]
            for {set midx 0} {$midx < $nitems} {incr midx} {
                if { [Mrml(dataTree) GetNthItem $midx] == "Model($m,node)" } {
                    break
                }
            }
            if { $midx < $nitems } {
                Mrml(dataTree) RemoveItem $midx
                Mrml(dataTree) InsertAfterItem Volume($v,node) Model($m,node)
                MainUpdateMRML
                if {$::Module(verbose)} {
                    puts "Model($m,node) placed after item Volume($v,node) in mrml data tree"
                }
            }
            incr numModels
        }
    }
    MainUpdateMRML
    
    # set the last one to be active
    if {$numModels > 0} {
        MainModelsSetActive $m
    }

    # update the gui so all entry boxes are okay - Label(label) gets lost before get here, reset it
    set Label(label) $ModelMaker(endLabel)
    if {$::Module(verbose)} {
        puts "Done creating, resetting stuff: Label(label) = $Label(label), Label(name) = $Label(name)"
    }
    ModelMakerLabelCallback

    $ModelMaker(bCreateAll) config -state normal
    
    set msg "Finished creating models for volume $volid."
    if {[llength $madeModels] != 0} {
        append msg "\nCreated $numModels models: $madeModels."
    } else {
        append msg "\nCreated no models"
    }
    if {[llength $skippedModels] != 0} {
        append msg "\nSkipped these labels, as no voxels were present: $skippedModels"
    } else {
        append msg "\nNo labels skipped."
    }
    DevInfoWindow $msg

    return $m
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerLabelCallback
# Set the model maker name and label from the Label tcl array.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerLabelCallback {} {
    global Label ModelMaker

    if {$::Module(verbose)} {
        puts "ModelMakerLabelCallback, Label(callback) = $Label(callback)"
    }

    set ModelMaker(name)   $Label(name)

    set ModelMaker(label2) $Label(label)
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerMultipleLabelCallback
# Sets either the start or end label variables, for creating multiple models
# .ARGS
# string which one of start or end, otherwise does nothing
# .END
#-------------------------------------------------------------------------------
proc ModelMakerMultipleLabelCallback { which } {
    global Label ModelMaker Module
    
    if {$which == "start"} {
        if {$::Module(verbose)} {
            puts "ModelMakerMultipleLabelCallback: $which, setting startName to $Label(name) and startLabel to $Label(label)"
        }
        set ModelMaker(startName) $Label(name)
        set ModelMaker(startLabel) $Label(label)
        # colour the label name box
        set w $::Module(ModelMaker,fMultiple).fLabel.eStartName
        set c [MainColorsGetColorFromLabel $ModelMaker(startLabel)]
        if {$c != ""} {
            $w config -bg [MakeColorNormalized [Color($c,node) GetDiffuseColor]] -state normal
        }
    } 
    if {$which == "end"} {
        if {$::Module(verbose)} {
            puts "ModelMakerMultipleLabelCallback: $which, setting endName to $Label(name) and endLabel to $Label(label)"
        }
        set ModelMaker(endName) $Label(name)
        set ModelMaker(endLabel) $Label(label)
        # colour the label name box
        set w $::Module(ModelMaker,fMultiple).fLabel.eEndName
        set c [MainColorsGetColorFromLabel $ModelMaker(endLabel)]
        if {$c != ""} {
            $w config -bg [MakeColorNormalized [Color($c,node) GetDiffuseColor]] -state normal
        }
    }
    # if the Label(callback) is left as ModelMakerMultipleLabelCallback, setting the values via
    # the entry boxes won't work
    if {$::Module(verbose)} {
        puts "ModelMakerMultipleLabelCallback: Setting Label(callback) to empty"
    }
    set ::Label(callback) ""
}
#-------------------------------------------------------------------------------
# .PROC ModelMakerSmoothWrapper
# Get the model id and call ModelMakerSmooth.
# .ARGS
# int m model id, optional, defaults to empty string. If empty, use the active model id
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSmoothWrapper {{m ""}} {
    global Model ModelMaker

    if {$m == ""} {
        set m $Model(activeID)
    }
    if {$m == ""} {return}

    # Validate smooth
    if {[ValidateInt $ModelMaker(edit,smooth)] == 0} {
        tk_messageBox -message "The number of smoothing iterations must be an integer."
        return
    }

    ModelMakerSmooth $m $ModelMaker(edit,smooth)
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSmooth
# Smooth a model and mark it as unsaved.
# .ARGS
# int m model id
# int iterations number of iterations of smoothing
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSmooth {m iterations} {
    global Model Gui ModelMaker Module

    set name [Model($m,node) GetName]

    set p smoother
    if { $ModelMaker(UseSinc) == 1} {
        vtkWindowedSincPolyDataFilter $p
        $p SetPassBand .1
    } else {
        # Laplacian
        vtkSmoothPolyDataFilter $p
        # This next line massively rounds corners
        $p SetRelaxationFactor .33
        $p SetFeatureAngle 60
        $p SetConvergence 0
    }
    
    $p SetInput $Model($m,polyData)
    $p SetNumberOfIterations $iterations
    $p FeatureEdgeSmoothingOff
    $p BoundarySmoothingOff
    [$p GetOutput] ReleaseDataFlagOn
    set Gui(progressText) "Smoothing $name"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress
    set ModelMaker(t,$p) [expr [lindex [time {$p Update}] 0]/1000000.0]
    set ModelMaker(n,$p) [[$p GetOutput] GetNumberOfPolys]
    set ModelMaker($m,nPolys) $ModelMaker(n,$p)

    set p normals
    vtkPolyDataNormals $p
    $p ComputePointNormals$ModelMaker(PointNormals)
    $p SetInput [smoother GetOutput]
    $p SetFeatureAngle 60
    $p Splitting$ModelMaker(SplitNormals)
    [$p GetOutput] ReleaseDataFlagOn

    set p stripper
    vtkStripper $p
    $p SetInput [normals GetOutput]
    [$p GetOutput] ReleaseDataFlagOff

    # polyData will survive as long as it's the input to the mapper
    set Model($m,polyData) [$p GetOutput]
    $Model($m,polyData) Update
    foreach r $Module(Renderers) {
    Model($m,mapper,$r) SetInput $Model($m,polyData)
    }
    stripper SetOutput ""
    foreach p "smoother normals stripper" {
        $p SetInput ""
        $p Delete
    }

    # Mark this model as unsaved
    set Model($m,dirty) 1
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerReverseNormals
# Reverse the normals for a model, and set it to unsaved.
# .ARGS
# int m optional model id, defaults to empty string, use the active model id if empty
# .END
#-------------------------------------------------------------------------------
proc ModelMakerReverseNormals {{m ""}} {
    global Model Gui ModelMaker Module

    if {$m == ""} {
        set m $Model(activeID)
    }
    if {$m == ""} {return}

    set name [Model($m,node) GetName]

    set p reverser
    vtkReverseSense $p
    $p SetInput $Model($m,polyData)
    $p ReverseNormalsOn
    [$p GetOutput] ReleaseDataFlagOn
    set Gui(progressText) "Reversing $name"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress

    set p stripper
    vtkStripper $p
    $p SetInput [reverser GetOutput]
    [$p GetOutput] ReleaseDataFlagOff

    # polyData will survive as long as it's the input to the mapper
    set Model($m,polyData) [$p GetOutput]
    $Model($m,polyData) Update
    foreach r $Module(Renderers) {
        Model($m,mapper,$r) SetInput $Model($m,polyData)
    }
    stripper SetOutput ""
    foreach p "reverser stripper" {
        $p SetInput ""
        $p Delete
    }

    # Mark this model as unsaved
    set Model($m,dirty) 1
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerMarch
# Marching cubes.<br>
# Polina Goland (polina@ai.mit.edu) helped create this routine.  The example
# on Bill Lorensen's web site was adapted to exploit our vtkToRasMatrix.
# .ARGS
# int m model id
# int v volume id
# int decimateIterations number of times to decimate.
# int smoothIterations number of times to smooth
# .END
#-------------------------------------------------------------------------------
proc ModelMakerMarch {m v decimateIterations smoothIterations} {
    global Model ModelMaker Gui Label Module
    
    if {$ModelMaker(marching) == 1} {
        puts "already marching"
        return -1
    }

    set ModelMaker(marching) 1
    set name [Model($m,node) GetName]

    # Marching cubes cannot run on data of dimension less than 3
    set dim [[Volume($v,vol) GetOutput] GetExtent]
    if {[lindex $dim 0] == [lindex $dim 1] ||
        [lindex $dim 2] == [lindex $dim 3] ||
        [lindex $dim 4] == [lindex $dim 5]} {
        puts "extent=$dim"
        tk_messageBox -message "The volume '[Volume($v,node) GetName]' is not 3D"
        set ModelMaker(marching) 0
        return -1
    }

    set spacing [[Volume($v,vol) GetOutput] GetSpacing]
    set origin  [[Volume($v,vol) GetOutput] GetOrigin]
    # The spacing is accounted for in the rasToVtk transform, 
    # so we have to remove it here, or mcubes will use it.
    [Volume($v,vol) GetOutput] SetSpacing 1 1 1
    [Volume($v,vol) GetOutput] SetOrigin 0 0 0
    
    # Read orientation matrix and permute the images if necessary.
    catch "rot Delete"
    vtkTransform rot

    # special trick to avoid vtk 4.2 legacy hack message 
    # (adds a concatenated identity transform to the transform)
    if { [info commands __dummy_transform] == "" } {
        vtkTransform __dummy_transform
    }
    rot SetInput __dummy_transform

    set matrixList [Volume($v,node) GetRasToVtkMatrix]
    eval rot SetMatrix $matrixList
    eval rot Inverse

    # Threshold so the only values are the desired label.
    # But do this only for label maps
# BUG crashes:    $p ThresholdBetween $Label(label) $ModelMaker(label2)
    set p thresh
    catch "$p Delete"
    
    if {$ModelMaker(jointSmooth) == 0} {
        vtkImageThreshold $p
        $p SetInput [Volume($v,vol) GetOutput]
        $p SetReplaceIn 1
        $p SetReplaceOut 1
        $p SetInValue 200
        $p SetOutValue 0
    } else {
        vtkThreshold $p
        # use the output of the smoother
        $p SetInput [$ModelMaker(jointSmoother,$v) GetOutput]
        $p SetAttributeModeToUseCellData
    }
    
    if {$::Module(verbose)} {
        puts "Thresholding to $Label(label)"
    }

    $p ThresholdBetween $Label(label) $Label(label)
    [$p GetOutput] ReleaseDataFlagOn
    set Gui(progressText) "Threshold $name to $Label(label)"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress


    catch "to Delete"
    if {$ModelMaker(jointSmooth) == 0} {
        vtkImageToStructuredPoints to
        to SetInput [thresh GetOutput]
        to Update
    } else {
        vtkGeometryFilter to
        to SetInput [thresh GetOutput]
    }
    
    
    if {$::ModelMaker(jointSmooth) == 0} {
        set p mcubes
        catch "$p Delete"
        vtkMarchingCubes $p
        $p SetInput [to GetOutput]
        $p SetValue 0 100.5
        $p ComputeScalarsOff
        $p ComputeGradientsOff
        $p ComputeNormalsOff
        [$p GetOutput] ReleaseDataFlagOn
        set Gui(progressText) "Marching $name"
        $p AddObserver StartEvent     MainStartProgress
        $p AddObserver ProgressEvent "MainShowProgress $p"
        $p AddObserver EndEvent       MainEndProgress
        set ModelMaker(t,$p) [expr [lindex [time {$p Update}] 0]/1000000.0]
   

        set ModelMaker(n,$p) [[$p GetOutput] GetNumberOfPolys]
        
        # If there are no polygons, then the smoother gets mad, so stop.
        if {$ModelMaker(n,$p) == 0} {
            tk_messageBox -message "Cannot create a model from label $Label(label).\nNo polygons can be created,\nthere may be no voxels with this label in the volume."
            thresh SetInput ""
            to SetInput ""
            if {$ModelMaker(jointSmooth) == 0} {
                mcubes SetInput ""
            }
            rot Delete
            thresh Delete
            to Delete
            if {$ModelMaker(jointSmooth) == 0} {
                mcubes Delete
            }
            set ModelMaker(marching) 0
            eval [Volume($v,vol) GetOutput] SetSpacing $spacing
            eval [Volume($v,vol) GetOutput] SetOrigin $origin
            return -1
        }
    } else {
        if {$::Module(verbose)} { puts "Skipping marching cubes..."}
#        set p ModelMaker(cubes,$v)
    }

    set p decimator
    catch "$p Delete"
    vtkDecimate $p
    if {$ModelMaker(jointSmooth) == 0} {
        $p SetInput [mcubes GetOutput]
    } else {
#        $p SetInput [ModelMaker(cubes,$v) GetOutput]
        $p SetInput [to GetOutput]
    }

    $p SetInitialFeatureAngle 60
    $p SetMaximumIterations $decimateIterations
    $p SetMaximumSubIterations 0
    $p PreserveEdgesOn
    $p SetMaximumError 1
    $p SetTargetReduction 1
    $p SetInitialError .0002
    $p SetErrorIncrement .0002
    [$p GetOutput] ReleaseDataFlagOn
    set Gui(progressText) "Decimating $name"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress
    set ModelMaker(t,$p) [expr [lindex [time {$p Update}] 0]/1000000.0]
    set ModelMaker(n,$p) [[$p GetOutput] GetNumberOfPolys]
    
    catch "reverser Delete"
    vtkReverseSense reverser

    # Do normals need reversing?
    set mm [rot GetMatrix] 
    if {[$mm Determinant] < 0} {

        #      
        # History: In a note to Samson Timoner, Dave Gering wrote:
        # With some scan orders (AP PA LR RL IS SI), the normals need to be reversed
        # for proper surface rendering. I meant to one day validate that this was
        # happening correctly, but I never got around to making a model from every
        # type of scan order. The popup was to aid my testing, and it certainly
        # shouldn't still be in there!!
        #
        #    tk_messageBox -message Reverse
        set p reverser
        $p SetInput [decimator GetOutput]
        $p ReverseNormalsOn
        [$p GetOutput] ReleaseDataFlagOn
        set Gui(progressText) "Reversing $name"
        $p AddObserver StartEvent     MainStartProgress
        $p AddObserver ProgressEvent "MainShowProgress $p"
        $p AddObserver EndEvent       MainEndProgress
    }

    if {$::ModelMaker(jointSmooth) == 0} {   
        catch "smoother Delete"
        if { $ModelMaker(UseSinc) == 1} {
            vtkWindowedSincPolyDataFilter smoother
            smoother SetPassBand .1
            if { $smoothIterations == 1 } {
                DevWarningWindow "Smoothing value of 1 not allowed for Sinc filter.  Using 2 smoothing iterations."
                set smoothIterations 2
            }
        } else {
            vtkSmoothPolyDataFilter smoother
            # This next line massively rounds corners
            smoother SetRelaxationFactor .33
            smoother SetFeatureAngle 60
            smoother SetConvergence 0
        }
        smoother SetInput [$p GetOutput]
        set p smoother
        $p SetNumberOfIterations $smoothIterations
        # This next line massively rounds corners
        $p FeatureEdgeSmoothingOff
        $p BoundarySmoothingOff
        [$p GetOutput] ReleaseDataFlagOn
        set Gui(progressText) "Smoothing $name"
        $p AddObserver StartEvent     MainStartProgress
        $p AddObserver ProgressEvent "MainShowProgress $p"
        $p AddObserver EndEvent       MainEndProgress
        set ModelMaker(t,$p) [expr [lindex [time {$p Update}] 0]/1000000.0]
    } else {
        # don't reset p
    }
    set ModelMaker(n,$p) [[$p GetOutput] GetNumberOfPolys]
    set ModelMaker($m,nPolys) $ModelMaker(n,$p)

    set p transformer
    catch "$p Delete"
    vtkTransformPolyDataFilter $p
    if {$ModelMaker(jointSmooth) == 0} {
        $p SetInput [smoother GetOutput]
    } else {
        if {[$mm Determinant] < 0} {
            if {$::Module(verbose)} { puts "Using reverser instead of smoother" }
            $p SetInput [reverser GetOutput]
        } else {
            if {$::Module(verbose)} { puts "Using decimator instead of smoother" }
            $p SetInput  [decimator GetOutput]
        }
    }
    $p SetTransform rot
    set Gui(progressText) "Transforming $name"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress
    [$p GetOutput] ReleaseDataFlagOn

    set p normals
    catch "$p Delete"
    vtkPolyDataNormals $p
    $p ComputePointNormals$ModelMaker(PointNormals)
    $p SetInput [transformer GetOutput]
    $p SetFeatureAngle 60
    $p Splitting$ModelMaker(SplitNormals)
    set Gui(progressText) "Normals $name"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress
    [$p GetOutput] ReleaseDataFlagOn

    set p stripper
    catch "$p Delete"
    vtkStripper $p
    $p SetInput [normals GetOutput]
    set Gui(progressText) "Stripping $name"
    $p AddObserver StartEvent     MainStartProgress
    $p AddObserver ProgressEvent "MainShowProgress $p"
    $p AddObserver EndEvent       MainEndProgress
    [$p GetOutput] ReleaseDataFlagOff

    # polyData will survive as long as it's the input to the mapper
    set Model($m,polyData) [$p GetOutput]
    $Model($m,polyData) Update
    foreach r $Module(Renderers) {
        Model($m,mapper,$r) SetInput $Model($m,polyData)
    }
    stripper SetOutput ""
    foreach p "to thresh mcubes decimator reverser transformer smoother normals stripper" {
        if {[info command $p] != ""} {
            $p SetInput ""
            $p Delete
        }
    }
    rot Delete

    # Restore spacing
    eval [Volume($v,vol) GetOutput] SetSpacing $spacing
    eval [Volume($v,vol) GetOutput] SetOrigin $origin

    set ModelMaker(marching) 0
    return 0
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSetJointSmooth
# The value of ModelMaker(jointSmooth) is set elsewhere, it's a flag that
# determines if when multiple models are created, if they will be smoothly joined 
# so that they are interlocking exactly, or if the models will be smoothed separately.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSetJointSmooth {} {
    if {$::Module(verbose)} {
        puts $::ModelMaker(jointSmooth)
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSetStartLabelButtonCallback
# Called when select the button to set the start label. Calls ShowLabels with the 
# multiple model maker callback with the start flag.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSetStartLabelButtonCallback {} {
    if {$::Module(verbose)} { 
        puts "ModelMakerSetStartLabelButtonCallback: calling ShowLabels with start mult calback"
    }
    ShowLabels "ModelMakerMultipleLabelCallback start"
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSetStartLabelReturnCallback
# Called when hit return in the start label entry box. 
# Sets Label(label) from entry, calls LabelsFindLabel, then the model maker multiple 
# call back with the start flag.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSetStartLabelReturnCallback {} {

    set ::Label(label) $::ModelMaker(startLabel)

    if {$::Module(verbose)} { 
        puts "ModelMakerSetStartLabelReturnCallback: Label(label) = $::Label(label). Calling LabelsFindLabel."
    }
    LabelsFindLabel

    if {$::Module(verbose)} { 
        puts "ModelMakerSetStartLabelReturnCallback: now about to call ModelMakerMultipleLabelCallback start"
    }

    ModelMakerMultipleLabelCallback start
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSetEndLabelButtonCallback
# Called when select the button to set the end label. Calls ShowLabels with the 
# multiple model maker callback with the end flag.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSetEndLabelButtonCallback {} {
    if {$::Module(verbose)} { 
        puts "ModelMakerSetEndLabelButtonCallback calling mult callback with end"
    }
    ShowLabels "ModelMakerMultipleLabelCallback end" 

    
}

#-------------------------------------------------------------------------------
# .PROC ModelMakerSetEndLabelReturnCallback
# Called when hit return in the end label entry box. 
# Sets Label(label) from entry, calls LabelsFindLabel, then the model maker multiple 
# call back with the end flag.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelMakerSetEndLabelReturnCallback {} {
    if {$::Module(verbose)} { 
        puts "ModelMakerSetEndLabelReturnCallback: setting label to $::ModelMaker(endLabel)"
    }
    set ::Label(label) $::ModelMaker(endLabel)
    LabelsFindLabel

    ModelMakerMultipleLabelCallback end
}
