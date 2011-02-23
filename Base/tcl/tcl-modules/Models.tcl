#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Models.tcl,v $
#   Date:      $Date: 2006/03/29 21:19:51 $
#   Version:   $Revision: 1.71 $
# 
#===============================================================================
# FILE:        Models.tcl
# PROCEDURES:  
#   ModelsInit
#   ModelsUpdateMRML
#   ModelsBuildGUI
#   ModelsConfigScrolledGUI canvasScrolledGUI fScrolledGUI
#   ModelsSetPropertyType
#   ModelsSetFileName
#   ModelsPropsApplyButNotToNew
#   ModelsPropsApply
#   ModelsPropsCancel
#   ModelsSmoothNormals
#   ModelsPickScalars  parentButton
#   ModelsPickScalarsCallback mid ptdata scalars
#   ModelsPickScalarsLut parentButton
#   ModelsSetScalarsLut mid lutid setDefault
#   ModelsAddScalars  scalarfile
#   ModelsMeter
#   commify num sep
#   ModelsFreeSurferPropsApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC ModelsInit
# Initialises global variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsInit {} {
    global Model Module

    # Define Tabs
    set m Models
    set Module($m,row1List) "Help Display Props Clip Meter"
    set Module($m,row1Name) "{Help} {Display} {Props} {Clip} {Meter}"
    set Module($m,row1,tab) Display
    # Use these lines to add a second row of tabs
    #    set Module($m,row2List) "Meter"
    #    set Module($m,row2Name) "{Meter}"
    #    set Module($m,row2,tab) Meter

    # Module Summary Info
    set Module($m,overview) "3D surface models."
    set Module($m,author) "Core"
    # could be put in IO
    set Module($m,category) "Visualisation"

    # Define Procedures
    set Module($m,procGUI) ModelsBuildGUI
    set Module($m,procMRML) ModelsUpdateMRML

    # Define Dependencies
    set Module($m,depend) "Labels"

    # Set Version Info
    lappend Module(versions) [ParseCVSInfo $m \
            {$Revision: 1.71 $} {$Date: 2006/03/29 21:19:51 $}]

    # Props
    set Model(propertyType) Basic

    # Meter
    set Model(meter,first) 1

    set Model(DefaultDir) "";

    # Scroll Bar Interation
}

#-------------------------------------------------------------------------------
# .PROC ModelsUpdateMRML
# Handle all GUI-related things needed when MRML updates.
# Creates the GUI for any new models (that were read in 
# in MainUpdateMRML or made through ModelMaker).
# Refreshes the GUI in case colors changed.  Also reconfigures the sliders.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsUpdateMRML {} {

    global Gui Model Slice Module Color Volume Label
    global ModelGroup

    # Create the GUI for any new models
    set gui 0

    # We want to create the GUI for the hierarchy and put all other
    # models from the ID list at the end
    
    set hierarchyModelList ""


    set hlevel 0; # hierarchy level
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    set success 0
    while {$node != ""} {
        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            incr hlevel
            

            # Set some ModelGroup properties
            set ModelGroup([$node GetID],visibility) [$node GetVisibility]
            set ModelGroup([$node GetID],opacity) [format %#.1f [$node GetOpacity]]
            set ModelGroup([$node GetID],expansion) [$node GetExpansion]
            set colorname [$node GetColor]
            foreach c $Color(idList) {
                if {[Color($c,node) GetName] == $colorname} {
                    set ModelGroup([$node GetID],colorID) $c
                }
            }
            
            set gui [expr $gui + [MainModelGroupsCreateGUI $Model(fScrolledGUI) [$node GetID] [expr $hlevel-1]]]
        }
        
        if {[string compare -length 13 $node "EndModelGroup"] == 0} {
            incr hlevel -1
        }
        
        if {[string compare -length 8 $node "ModelRef"] == 0} {
            set success 1
            set CurrentModelID [SharedModelLookup [$node GetModelRefID]]
            if {$CurrentModelID != -1} {
                set gui [expr $gui + [MainModelsCreateGUI $Model(fScrolledGUI) $CurrentModelID $hlevel]]
                # remember we put this one on the list.
                # hopefully if it is on multiple times this is okay
                lappend hierarchyModelList $CurrentModelID

            }
        }
        set node [Mrml(dataTree) GetNextItem]
    }

    # Now build GUI for any models not in hierarchies
    foreach m $Model(idList) {
        if {[lsearch $hierarchyModelList $m] == -1} {
            set gui [expr $gui + [MainModelsCreateGUI $Model(fScrolledGUI) $m]]
        }
    }

    # Delete the GUI for any old models
    foreach m $Model(idListDelete) {
        set gui [expr $gui + [MainModelsDeleteGUI $Model(fScrolledGUI) $m]]
    }

    # Tell the scrollbar to update if the gui height changed
    if {$gui > 0} {
        ModelsConfigScrolledGUI $Model(canvasScrolledGUI) \
                $Model(fScrolledGUI)
    }

    # Refresh  GUIs (in case color changed)
    #--------------------------------------------------------
    
    foreach m $Model(idList) {
        set c $Model($m,colorID)
        MainModelsRefreshGUI $m $c
    }
    
    foreach mg $ModelGroup(idList) {
        # catch is important here, because the GUI variables for
        # model groups may have not been initialized yet
        catch {set c $ModelGroup($mg,colorID)}
        MainModelGroupsRefreshGUI $mg $c
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelsBuildGUI
# Build the models gui.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsBuildGUI {} {
    global Gui Model Slice Module Label

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Display
    #   Title
    #   All
    #   Grid
    # Props
    #   Top
    #     Active
    #     Type
    #   Bot
    #     Basic
    #     Advanced
    #     Adv2
    # Clip
    #   Help
    #   Grid
    # Meter
    #   
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
    Description by tab:<BR>
    <UL>
    <LI><B>Display:</B> Click the button with the model's name to
    set its visibility, and move the slider to affect its opacity.
    For a menu of additional options, click the button with the
    <B>Right</B> mouse button.<BR>
    <LI><B>Props:</B> Another way of setting the model's properties
    than via the menu on the <B>Display</B> tab. You must click the
    <B>Apply</B> button for your changes to take effect.<BR>

    <LI><B>Clip:</B> The slice planes can act as clipping planes to give
    you vision inside the model. Select whether each plane should not
    clip, or clip the portion of the model lying on the its positive or
    its negative side. You may change the effect of clipping with multiple
    planes. <BR>

    Note that to clip a particular model, you must turn clipping on for that model.
    Do that in the Props:Advanced section.

    <BR><B>TIP</B> Clip the skin to see the other models inside the
    body while still retaining the skin as a landmark.<BR>
    <LI><B>Meter:</B> Click the <B>Measure Performance</B> button
    to display the number of polygons in each model and the time
    to render them all.

    <LI><B>Other Notes:</B><BR>
    If <B>Backface Culling</B> is on, you will see nothing when looking inside a clipped model. If Backface Culling is off, you will the inside of the model when looking inside a clipped model.


    "
    regsub -all "\n" $help { } help
    MainHelpApplyTags Models $help
    MainHelpBuildGUI Models

    #-------------------------------------------
    # Display frame
    #-------------------------------------------
    set fDisplay $Module(Models,fDisplay)
    set f $fDisplay

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fAll -bg $Gui(activeWorkspace)
    frame $f.fRend -bg $Gui(activeWorkspace)
    frame $f.fGrid -bg $Gui(activeWorkspace)
    frame $f.fScroll -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fAll $f.fRend -side top -pady $Gui(pad)
    pack $f.fGrid $f.fScroll -side top -pady 1

    #-------------------------------------------
    # fDisplay->Title frame
    #-------------------------------------------
    set f $fDisplay.fTitle

    eval {label $f.lTitle -justify left -text \
            "Click the right mouse button on\nthe name of a model for options."} $Gui(WLA)
    pack $f.lTitle
    
    #-------------------------------------------
    # fDisplay->Rend frame
    #-------------------------------------------
    
    set f $fDisplay.fRend

    eval {label $f.label -text "Choose a screen:"} $Gui(WLA)
    eval {menubutton $f.fMenuB -text "viewRen" -menu $f.fMenuB.menu} $Gui(WMBA)
    TooltipAdd $f.fMenuB "Choose in which screen you want to change the options of a model"
    eval {menu $f.fMenuB.menu} $Gui(WMA)
    foreach rend $Module(Renderers) {
        $f.fMenuB.menu add command -label $rend -command "$f.fMenuB configure -text $rend; MainModelsSetRenderer $rend"
    }
    
    pack $f.label $f.fMenuB  -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # fDisplay->All frame
    #-------------------------------------------
    set f $fDisplay.fAll

    DevAddButton $f.bAll "Show All" \
            "MainModelsSetVisibility All; Render3D" 10 
    DevAddButton $f.bNone "Show None" \
            "MainModelsSetVisibility None; Render3D" 10 
    pack $f.bAll $f.bNone -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # fDisplay->Grid frame
    #-------------------------------------------
    set f $Module(Models,fDisplay).fGrid
    DevAddLabel $f.lV "Visibility"
    DevAddLabel $f.lO "Opacity" 
    grid $f.lV $f.lO -pady 0 -padx 12
    grid $f.lO -columnspan 2

    # Done in MainModelsCreateGUI

    #-------------------------------------------
    # Props frame
    #-------------------------------------------
    set fProps $Module(Models,fProps)
    set f $fProps

    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fBot -bg $Gui(activeWorkspace) -height 300
    pack $f.fTop -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    pack $f.fBot -side top -pady $Gui(pad) -padx $Gui(pad) -fill both -expand true

    #-------------------------------------------
    # Props->Bot frame
    #-------------------------------------------
    set f $fProps.fBot

    # add FreeSurfer
    foreach type "Basic Advanced Adv2" {
        frame $f.f${type} -bg $Gui(activeWorkspace)
        place $f.f${type} -in $f -relheight 1.0 -relwidth 1.0
        set Model(f${type}) $f.f${type}
    }
    raise $Model(fBasic)

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

    eval {label $f.lActive -text "Active Model: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
            -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Model(mbActiveList) $f.mbActive
    lappend Model(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Props->Top->Type frame
    #-------------------------------------------
    set f $fProps.fTop.fType

    eval {label $f.l -text "Properties:"} $Gui(BLA)
    frame $f.f -bg $Gui(backdrop)
    # add FreeSurfer
    foreach p "Basic Advanced Adv2" {
        eval {radiobutton $f.f.r$p \
                -text "$p" -command "ModelsSetPropertyType" \
                -variable Model(propertyType) -value $p -width 8 \
                -indicatoron 0} $Gui(WCA)
        pack $f.f.r$p -side left -padx 0
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Props->Bot->Basic frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic

    frame $f.fFileName -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fName    -bg $Gui(activeWorkspace)
    frame $f.fColor   -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fFileName $f.fName $f.fColor $f.fGrid $f.fApply \
            -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced

    frame $f.fClipping -bg $Gui(activeWorkspace)
    frame $f.fCulling -bg $Gui(activeWorkspace)
    frame $f.fScalars -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fDesc    -bg $Gui(activeWorkspace)
    # Got rid of the Apply frame, it is unnecessary.
    #    frame $f.fApply   -bg $Gui(activeWorkspace)
    #    pack $f.fClipping $f.fCulling $f.fScalars $f.fDesc $f.fApply \
            #        -side top -fill x -pady $Gui(pad)
    pack $f.fClipping $f.fCulling $f.fScalars $f.fDesc  \
            -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Adv2 frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2

    frame $f.fVectors -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fTensors -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack $f.fVectors $f.fTensors \
            -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Basic->Name frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fName

    DevAddLabel $f.l "Name:" 
    eval {entry $f.e -textvariable Model(name)} $Gui(WEA)
    pack $f.l -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -expand 1 -fill x

    #-------------------------------------------
    # Props->Bot->Basic->FileName frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fFileName

    DevAddFileBrowse $f Model FileName "Model File (.vtk)" "ModelsSetFileName" "vtk" "\$Model(DefaultDir)" "Open"  "Browse for a Model" "Absolute"

    #-------------------------------------------
    # Props->Bot->Basic->Color frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fColor

    DevAddButton $f.b "Color:" "ShowColors"
    eval {entry $f.e -width 20 \
            -textvariable Label(name)} $Gui(WEA) \
            {-bg $Gui(activeWorkspace) -state disabled}
    pack $f.b $f.e -side left -padx $Gui(pad) -pady $Gui(pad) -fill x

    lappend Label(colorWidgetList) $f.e

    #-------------------------------------------
    # Props->Bot->Basic->Grid frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fGrid

    # Visible
    DevAddLabel $f.lV "Visible:"
    eval {checkbutton $f.c \
            -variable Model(visibility) -indicatoron 1} $Gui(WCA)

    # Opacity
    DevAddLabel $f.lO "Opacity:"
    eval {entry $f.e -textvariable Model(opacity) \
            -width 3} $Gui(WEA)
    eval {scale $f.s -from 0.0 -to 1.0 -length 50 \
            -variable Model(opacity) \
            -resolution 0.1} $Gui(WSA) {-sliderlength 14}

    grid $f.lV $f.c $f.lO $f.e $f.s

    #-------------------------------------------
    # Props->Bot->Basic->Apply frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fApply

    DevAddButton $f.bApply "Apply" "ModelsPropsApply; Render3D" 8
    DevAddButton $f.bCancel "Cancel" "ModelsPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    if {0} {
    #-------------------------------------------
    # Props->Bot->FreeSurfer frame
    #-------------------------------------------
    set f $fProps.fBot.fFreeSurfer

    frame $f.fFileName -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fName    -bg $Gui(activeWorkspace)
    frame $f.fGrid    -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fFileName $f.fName $f.fGrid $f.fApply \
        -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->FreeSurfer->FileName frame
    #-------------------------------------------
    set f $fProps.fBot.fFreeSurfer.fFileName
    DevAddFileBrowse $f Model FileName "Model File (.inflated)" "ModelsSetFileName" "inflated" "\$Model(DefaultDir)"  "Browse for a Free Surfer Model" 

    #-------------------------------------------
    # Props->Bot->FreeSurfer->Name frame
    #-------------------------------------------
    set f $fProps.fBot.fFreeSurfer.fName

    DevAddLabel $f.l "Name:" 
    eval {entry $f.e -textvariable Model(name)} $Gui(WEA)
    pack $f.l -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -expand 1 -fill x

    #-------------------------------------------
    # Props->Bot->FreeSurfer->Grid frame
    #-------------------------------------------
    set f $fProps.fBot.fFreeSurfer.fGrid

    # Visible
    DevAddLabel $f.lV "Visible:"
    eval {checkbutton $f.c \
         -variable Model(visibility) -indicatoron 1} $Gui(WCA)

    # Opacity
    DevAddLabel $f.lO "Opacity:"
    eval {entry $f.e -textvariable Model(opacity) \
        -width 3} $Gui(WEA)
    eval {scale $f.s -from 0.0 -to 1.0 -length 50 \
        -variable Model(opacity) \
        -resolution 0.1} $Gui(WSA) {-sliderlength 14}

    grid $f.lV $f.c $f.lO $f.e $f.s

    #-------------------------------------------
    # Props->Bot->FreeSurfer->Apply frame
    #-------------------------------------------
    set f $fProps.fBot.fFreeSurfer.fApply

    DevAddButton $f.bApply "Apply" "ModelsPropsApply; Render3D" 8
    DevAddButton $f.bCancel "Cancel" "ModelsPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

} 
    #-------------------------------------------
    # Props->Bot->Advanced->Clipping frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fClipping

    # Visible
    DevAddLabel $f.l "Clipping:"
    eval {checkbutton $f.c \
            -variable Model(clipping) -indicatoron 1 \
            -command "ModelsPropsApplyButNotToNew; Render3D"} $Gui(WCA)

    DevAddButton $f.bSmooth "Smooth Normals" "ModelsSmoothNormals; Render3D" 13

    pack $f.l $f.c $f.bSmooth -side left -padx $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced->Culling frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fCulling

    DevAddLabel $f.l "Backface Culling:"
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -padx $Gui(pad)

    foreach text "{Yes} {No}" \
            value "1 0" \
            width "4 4" {
        eval {radiobutton $f.f.rMode$value -width $width \
                -text "$text" -value "$value" -variable Model(culling)\
                -command "ModelsPropsApplyButNotToNew; Render3D" \
                -indicatoron 0} $Gui(WCA)
        pack $f.f.rMode$value -side left -padx 0 -pady 0
    }

    #-------------------------------------------
    # Props->Bot->Advanced->Scalars frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fScalars

    DevAddButton $f.bPick "Pick Scalars" "ModelsPickScalars $f.bPick; Render3D" 12
    DevAddButton $f.bPickLut "Pick Palette" "ModelsPickScalarsLut $f.bPickLut; Render3D" 12
    frame $f.fVisible -bg $Gui(activeWorkspace)
    frame $f.fAutoRange   -bg $Gui(activeWorkspace)
    frame $f.fRange   -bg $Gui(activeWorkspace)
    pack $f.bPick $f.fVisible $f.fAutoRange $f.fRange $f.bPickLut -side top -pady $Gui(pad)
    set fVisible $f.fVisible
    set fRange $f.fRange
    set fAutoRange $f.fAutoRange

    # fVisible
    set f $fVisible

    DevAddLabel $f.l "Scalars Visible:"
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -padx $Gui(pad) -pady 0

    foreach text "{Yes} {No}" \
            value "1 0" \
            width "4 4" {
        eval {radiobutton $f.f.rMode$value -width $width \
                -text "$text" -value "$value" -variable Model(scalarVisibility) \
                -command "ModelsPropsApplyButNotToNew; Render3D" \
                -indicatoron 0} $Gui(WCA)
        pack $f.f.rMode$value -side left
    }

    # fAutoRange
    set f $fAutoRange

    DevAddLabel $f.l "Scalar Range:"
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -padx $Gui(pad) -pady 0

    foreach text "{Auto} {Manual}" \
            value "1 0" {
        eval {radiobutton $f.f.rMode$value \
                -text "$text" -value "$value" \
                -variable Model(scalarVisibilityAuto) \
                -command "ModelsPropsApplyButNotToNew; Render3D" \
                -indicatoron 0} $Gui(WCA)
        pack $f.f.rMode$value -side left
    }

    # fRange
    set f $fRange

    DevAddLabel $f.l "Scalar Range:"
    eval {entry $f.eLo -width 6 -textvariable Model(scalarLo) } $Gui(WEA)
    bind $f.eLo <Return> "ModelsPropsApplyButNotToNew; Render3D"
    bind $f.eLo <FocusOut> "ModelsPropsApplyButNotToNew; Render3D"
    eval {entry $f.eHi -width 6 -textvariable Model(scalarHi) } $Gui(WEA)
    bind $f.eHi <Return> "ModelsPropsApplyButNotToNew; Render3D"
    bind $f.eHi <FocusOut> "ModelsPropsApplyButNotToNew; Render3D"
    pack $f.l $f.eLo $f.eHi -side left -padx $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced->Desc frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fDesc

    DevAddLabel $f.l "Optional Description:"
    eval {entry $f.e -textvariable Model(desc)} $Gui(WEA)
    bind $f.e <Return> "ModelsPropsApplyButNotToNew"
    bind $f.e <FocusOut> "ModelsPropsApplyButNotToNew"
    pack $f.l -side top -padx $Gui(pad) -fill x -anchor w
    pack $f.e -side top -padx $Gui(pad) -expand 1 -fill x

    # Unnecessary
    #        #-------------------------------------------
    #        # Props->Bot->Advanced->Apply frame
    #        #-------------------------------------------
    #        set f $fProps.fBot.fAdvanced.fApply
    #
    #        DevAddButton $f.bApply "Apply" "ModelsPropsApply; Render3D" 8
    #        DevAddButton $f.bCancel "Cancel" "ModelsPropsCancel" 8
    #        grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Props->Bot->Adv2->Vectors frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2.fVectors
    frame $f.fVisible -bg $Gui(activeWorkspace)
    pack $f.fVisible -side top -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Adv2->Vectors->Visible frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2.fVectors.fVisible

    DevAddLabel $f.l "Vectors Visible:"
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -padx $Gui(pad) -pady 0
    foreach text "{Yes} {No}" \
            value "1 0" \
            width "4 4" {
        eval {radiobutton $f.f.rMode$value -width $width \
                -text "$text" -value "$value" -variable Model(vectorVisibility) \
                -command "ModelsPropsApplyButNotToNew; Render3D" \
                -indicatoron 0} $Gui(WCA)
        pack $f.f.rMode$value -side left
    }

    #-------------------------------------------
    # Props->Bot->Adv2->Tensors frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2.fTensors
    frame $f.fVisible -bg $Gui(activeWorkspace)
    frame $f.fScaleFactor   -bg $Gui(activeWorkspace)
    frame $f.fColor  -bg $Gui(activeWorkspace)
    pack $f.fVisible $f.fScaleFactor $f.fColor -side top -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Adv2->Tensors->Visible frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2.fTensors.fVisible

    DevAddLabel $f.l "Tensors Visible:"
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -padx $Gui(pad) -pady 0
    foreach text "{Yes} {No}" \
            value "1 0" \
            width "4 4" {
        eval {radiobutton $f.f.rMode$value -width $width \
                -text "$text" -value "$value" -variable Model(tensorVisibility) \
                -command "ModelsPropsApplyButNotToNew; Render3D" \
                -indicatoron 0} $Gui(WCA)
        pack $f.f.rMode$value -side left
    }

    #-------------------------------------------
    # Props->Bot->Adv2->Tensors->ScaleFactor frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2.fTensors.fScaleFactor

    DevAddLabel $f.l "Scale Factor:"
    eval {entry $f.e -textvariable Model(tensorScaleFactor) \
            -width 4} $Gui(WEA)
    bind $f.e <Return> "ModelsPropsApplyButNotToNew"
    pack $f.l $f.e -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # Props->Bot->Adv2->Tensors->Color frame
    #-------------------------------------------
    set f $fProps.fBot.fAdv2.fTensors.fColor

    DevAddLabel $f.lVis "Color By:"
    eval {menubutton $f.mbVis -text $Model(tensorGlyphColor) \
          -relief raised -bd 2 -width 22 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    set visList "SolidColor LinearMeasure PlanarMeasure SphericalMeasure RelativeAnisotropy FractionalAnisotropy"
    foreach vis $visList {
        $f.mbVis.m add command -label $vis \
        -command "set Model(tensorGlyphColor) $vis; MainModelsSetTensorColor; Render3D"
    }
    # save menubutton for config
    set Model(mbTensorGlyphColor) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis "Select tensor shape measure to color tensors by."

    #-------------------------------------------
    # Clip frame
    #-------------------------------------------
    set fClip $Module(Models,fClip)
    set f $fClip

    frame $f.fHelp -bg $Gui(activeWorkspace)
    frame $f.fGrid -bg $Gui(activeWorkspace)
    frame $f.fClipType -bg $Gui(activeWorkspace)
    pack $f.fHelp $f.fGrid $f.fClipType -side top -pady $Gui(pad)

    #-------------------------------------------
    # fClip->Grid frame
    #-------------------------------------------
    set f $fClip.fHelp

    eval {label $f.l  -justify left -text "The slices clip all models that\n\
            have clipping turned on.\n\n\
            To turn clipping on for a model,\n\
            click with the right mouse button\n\
            on the model's name on the Props:\n\
            Advanced page, and select 'Clipping'."} $Gui(WLA)
    pack $f.l

    #-------------------------------------------
    # fClip->Grid frame
    #-------------------------------------------
    set f $fClip.fGrid
    
    foreach s $Slice(idList) name "Red Yellow Green" {

        eval {label $f.l$s -text "$name Slice: "} $Gui(WLA)
        
        frame $f.f$s -bg $Gui(activeWorkspace)
        foreach text "Off + -" value "0 1 2" width "4 2 2" {
            eval {radiobutton $f.f$s.r$value -width $width \
                    -text "$text" -value "$value" -variable Slice($s,clipState) \
                    -indicatoron 0 \
                    -command "MainSlicesSetClipState $s; MainModelsRefreshClipping; Render3D" \
                } $Gui(WCA) {-bg $Gui(slice$s)}
            pack $f.f$s.r$value -side left -padx 0 -pady 0
        }
        grid $f.l$s $f.f$s -pady $Gui(pad)
    }

    #-------------------------------------------
    # fClip->ClipType frame
    #-------------------------------------------
    set f $fClip.fClipType

    eval {label $f.l  -justify left -text \
            "Clipping can either be done as Intersection\n\
            or Union. Intersection clips all regions that\n\
            satisfy the constraints of all clipping planes.\n\
            Union clips all regions that satisfy the\n\
            constrains of at least one clipping plane.\n"} $Gui(WLA)

    grid $f.l

    foreach p "Union Intersection" {
        eval {radiobutton $f.r$p -width 10 \
                -text "$p" -value "$p" \
                -variable Slice(clipType) \
                -command "MainSlicesSetClipType $p; Render3D"\
                -indicatoron 0 \
            } $Gui(WCA) 
        grid $f.r$p -padx 0 -pady 0
    }

    #-------------------------------------------
    # Meter frame
    #-------------------------------------------
    set fMeter $Module(Models,fMeter)
    set f $fMeter

    foreach frm "Apply Results" {
        frame $f.f$frm -bg $Gui(activeWorkspace)
        pack  $f.f$frm -side top -pady $Gui(pad) -expand true -fill both
    }

    #-------------------------------------------
    # Meter->Apply frame
    #-------------------------------------------
    set f $fMeter.fApply

    set text "Measure Performance"
    DevAddButton $f.bMeasure $text "ModelsMeter" \
            [expr [string length $text] + 1]
    pack $f.bMeasure

    #-------------------------------------------
    # Meter->Results frame
    #-------------------------------------------
    set f $fMeter.fResults

    frame $f.fTop -bg $Gui(activeWorkspace)
    # frame $f.fBot -bg $Gui(activeWorkspace)
    # pack $f.fTop $f.fBot -side top -pady $Gui(pad)
    pack $f.fTop -side top -pady $Gui(pad) -fill both -expand true
    pack [::iwidgets::scrolledframe $f.sfBot -hscrollmode dynamic -vscrollmode dynamic -background $Gui(activeWorkspace)] -fill both -expand true

    set f $fMeter.fResults.fTop
    eval {label $f.l -justify left -text ""} $Gui(WLA)
    pack $f.l
    set Model(meter,msgTop) $f.l

    set f [$fMeter.fResults.sfBot childsite]
    eval {label $f.lL -justify left -text ""} $Gui(WLA)
    eval {label $f.lR -justify right -text ""} $Gui(WLA)
    pack $f.lL $f.lR -side left -padx $Gui(pad)
    set Model(meter,msgLeft) $f.lL
    set Model(meter,msgRight) $f.lR

    set Model(canvasScrolledGUI)  $Module(Models,fDisplay).fScroll.cGrid
    set Model(fScrolledGUI)       $Model(canvasScrolledGUI).fListItems
    DevCreateScrollList $Module(Models,fDisplay).fScroll \
            MainModelsCreateGUI \
            ModelsConfigScrolledGUI \
            "$Model(idList)"
}

#-------------------------------------------------------------------------------
# .PROC ModelsConfigScrolledGUI
# 
# Set the dimensions of the scrolledGUI
#
# .ARGS
# frame  canvasScrolledGUI  The canvas around the scrolled frame
# frame  fScrolledGUI       The frame with the item list of models
# .END   
#-------------------------------------------------------------------------------
proc ModelsConfigScrolledGUI {canvasScrolledGUI fScrolledGUI} {
    global Model ModelGroup RemovedModels

    set f      $fScrolledGUI
    set canvas $canvasScrolledGUI
    set m [lindex $Model(idList) 0]

    if {$::Module(verbose)} {
        puts "ModelsConfigScrolledGUI: $canvas $f"
    }

    # y spacing important for calculation of frame height for scrolling
    set pady 2

    if {$m != ""} {
        # Find the height of a single button
        # Must use $f.s$m since the scrollbar ("s") fields are tallest
        set lastButton $f.s$m
        if {[winfo exists $lastButton] == 0} {
            puts "ModelsConfigScrolledGUI: missing a button $lastButton, not building scrolled gui!"
            return
        }

        # Find how many modules (lines) in the frame
        set numLines 0
        foreach m $Model(idList) {
            if {$RemovedModels($m) == 0} {
                incr numLines
            }
        }
        incr numLines [llength $ModelGroup(idList)]
        #set numLines [expr [llength $Model(idList)] + [llength $ModelGroup(idList)]]
        # Find the height of a line
        set incr [expr {[winfo reqheight $lastButton] + 2*$pady}]
        # Find the total height that should scroll
        set height [expr {$numLines * $incr}]
        # Find the width of the scrolling region
        update;     # wait for some stuff to be done before requesting
        # window positions
        set last_x [winfo x $lastButton]
        set width [expr $last_x + [winfo reqwidth $lastButton]]
        $canvas config -scrollregion "0 0 $width $height"
        $canvas config -yscrollincrement $incr -confine true
        $canvas config -xscrollincrement 1 -confine true
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelsSetPropertyType
# Raise the frame with the Model(propertyType).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsSetPropertyType {} {
    global Model
    
    raise $Model(f$Model(propertyType))
}

#-------------------------------------------------------------------------------
# .PROC ModelsSetFileName
# 
# Called after a user selects a Model file.
# Model(FileName) is set by the Browse button.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsSetFileName {} {
    global Model Mrml Color

    # Do nothing if the user cancelled
    if {$Model(FileName) == ""} {return}

    # check for special characters
    set illegalCharacters {'`\u0100-\uffff}
    if {[regexp "\[$illegalCharacters\]" $Model(FileName)] == 1} {
        DevWarningWindow "Illegal character in model filename: $Model(FileName)\nRename the file and re-select it."
    }

    # Update the Default Directory
    set Model(DefaultDir) [file dirname $Model(FileName)]

    # Name the model based on the entered file.
    set Model(name) [ file root [file tail $Model(FileName)]]

    # Guess the color
    set name [string tolower $Model(name)]
    set guess ""
    set activeID ""
    if { $Color(activeID) != "" } {
        set guess [Color($Color(activeID),node) GetName]
        set activeID $Color(activeID)
    }
    foreach c $Color(idList) {
        set n [string tolower [Color($c,node) GetName]]
        if {[string first $name $n] != -1} {
            set guess [Color($c,node) GetName]
            set activeID $c
        }
    }

    if { $guess != "" } {
        LabelsSetColor $guess
        if {$activeID != ""} {
            set ::Color(activeID) $activeID
            if {$::Module(verbose)} {
                puts "ModelsSetFileName: active colour id = $::Color(activeID), after setting guess to $guess $activeID"
            }
        }
    } 
}

#-------------------------------------------------------------------------------
# .PROC ModelsPropsApplyButNotToNew
#
# Calls ModelsPropsApply if the Model is not a new one.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsPropsApplyButNotToNew {} {
    global Model 

    set m $Model(activeID)
    if {$m == "NEW"} {return}
    ModelsPropsApply

}

#-------------------------------------------------------------------------------
# .PROC ModelsPropsApply
# 
# This either updates the information about the model or it creates
# a new model if the model is new.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsPropsApply {} {
    global Model Label Module Mrml

    set m $Model(activeID)
    if {$m == ""} {
        DevWarningWindow "ModelsPropsApply: Model active id is empty."
        return
    }

    # Validate name
    if {$Model(name) == ""} {
        DevWarningWindow "Please enter a name that will allow you to distinguish this model."
        return
    }
    if {[ValidateName $Model(name)] == 0} {
        DevWarningWindow "The name can consist of letters, digits, dashes, or underscores"
        return
    }

    # compute scalar range if Auto is requested by user
    # if NEW, there's no polydata yet so can't get its range
    if {$Model(scalarVisibilityAuto) == "1" && $m != "NEW"} {
        set range [$Model($m,polyData) GetScalarRange]
        set Model(scalarLo) [lindex $range 0]
        set Model(scalarHi) [lindex $range 1]
    }

    # Validate scalar range
    if {[ValidateFloat $Model(scalarLo)] == 0} {
        DevWarningWindow "The scalar range must be numbers"
        return
    }
    if {[ValidateFloat $Model(scalarHi)] == 0} {
        DevWarningWindow "The scalar range must be numbers"
        return
    }


    if {$m == "NEW"} {
        # Ensure FileName not blank
        if {$Model(FileName) == ""} {
            DevWarningWindow "Please enter a model file name."
            return
        }
        set n [MainMrmlAddNode Model]
        set i [$n GetID]
        $n SetModelID M$i
        $n SetOpacity          1.0
        $n SetVisibility       1
        $n SetClipping         0

        # These get set down below, but we need them before MainUpdateMRML
        $n SetName $Model(name)
        $n SetFileName "$Model(FileName)"
        $n SetFullFileName [file join $Mrml(dir) [$n GetFileName]]
        $n SetColor $Label(name)

        MainUpdateMRML

        # If failed, then it's no longer in the idList
        if {[lsearch $Model(idList) $i] == -1} {
            return
        }
        set Model(freeze) 0
        set m $i
    }

    Model($m,node) SetName $Model(name)
    Model($m,node) SetFileName "$Model(FileName)"
    Model($m,node) SetFullFileName [file join $Mrml(dir) [Model($m,node) GetFileName]]
    Model($m,node) SetDescription $Model(desc)
    MainModelsSetClipping $m $Model(clipping)
    MainModelsSetVisibility $m $Model(visibility)
    MainModelsSetOpacity $m $Model(opacity)
    MainModelsSetCulling $m $Model(culling)
    MainModelsSetScalarVisibility $m $Model(scalarVisibility)
    MainModelsSetScalarRange $m $Model(scalarLo) $Model(scalarHi)
    MainModelsSetVectorVisibility $m $Model(vectorVisibility)
    MainModelsSetVectorScaleFactor $m $Model(vectorScaleFactor)
    MainModelsSetTensorVisibility $m $Model(tensorVisibility)
    MainModelsSetTensorScaleFactor $m $Model(tensorScaleFactor)
    MainModelsSetColor $m $Label(name)

    # If tabs are frozen, then return to the "freezer"
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
    
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC ModelsPropsCancel
# Cancel out of a setting model properties.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsPropsCancel {} {
    global Model Module

    # Reset props
    set m $Model(activeID)
    if {$m == "NEW"} {
        set m [lindex $Model(idList) 0]
    }
    set Model(freeze) 0
    MainModelsSetActive $m

    # Unfreeze
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelsSmoothNormals
# 
#  Smooth the normals of the models if they haven't been smoothed already.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsSmoothNormals {} {
    global Model Module

    set m $Model(activeID)

    if {[info exists Model($m,Smoothed)] == 0} {
        set Model($m,Smoothed) 1
        vtkPolyDataNormals ModelNormals
        ModelNormals SetInput $Model($m,polyData)
        ModelNormals SetFeatureAngle 60
        [ModelNormals GetOutput] ReleaseDataFlagOn
        ModelNormals Update

        set Model($m,polyData) [ModelNormals GetOutput]

        foreach r $Module(Renderers) {
            Model($m,mapper,$r) SetInput $Model($m,polyData)
        }

        foreach p "ModelNormals" {
            #            $p SetInput ""
            $p Delete
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelsPickScalars 
# 
#  Pick which scalars should be visible for this model.
#
# .ARGS
# windowpath parentButton the parent of the pop up menu
# .END
#-------------------------------------------------------------------------------
proc ModelsPickScalars { parentButton } {
    global Gui Model 

    set m $Model(activeID)

    # if no polydata error and return
    if {$m == "" || [info command $Model($m,polyData)] == ""} {
        DevErrorWindow "No active model!"
        return
    }

    set ptdata [$Model($m,polyData) GetPointData]
    if { [$ptdata GetScalars] != "" } {
        set currscalars [[$ptdata GetScalars] GetName]
    } else {
        set currscalars ""
    }
    set narrays [$ptdata GetNumberOfArrays]

    set scalararrays ""
    set scalararraynames ""
    for {set i 0} {$i < $narrays} {incr i} {
        set arr [$ptdata GetArray $i]
        if { [$arr GetNumberOfComponents] == 1 } {
            lappend scalararrays $i
            lappend scalararraynames [$arr GetName]
        }
    }

    catch "destroy .mpickscalars"
    eval menu .mpickscalars $Gui(WMA)
    foreach s $scalararraynames {
        if { $s == $currscalars } {
            set ll "* $s *"
        } else {
            set ll $s
        }
        .mpickscalars insert end command -command "ModelsPickScalarsCallback $m $ptdata \"$s\"" -label $ll
    }
    .mpickscalars insert end separator
    .mpickscalars insert end command -command ModelsAddScalars -label "Add New..."

    set x [expr [winfo rootx $parentButton] + 10]
    set y [expr [winfo rooty $parentButton] + 10]
    
    .mpickscalars post $x $y
}

#-------------------------------------------------------------------------------
# .PROC ModelsPickScalarsCallback
# 
#  set the appropriate scalars and scalar range with defaults if needed
#
# TODO - this has hardcoded special case for freesurfer labels
# .ARGS
# int mid model id for which scalars are changing
# string ptdata the name of the point data variable who's scalars are changing
# string scalars name of the scalars to set active for this model
# .END
#-------------------------------------------------------------------------------
proc ModelsPickScalarsCallback { mid ptdata scalars } {

    $ptdata SetActiveScalars $scalars

    if { $scalars == "labels" } {
        # "Freesurfer"
        set lutid [MainLutsGetLutIDByName "Label"]
        if { $lutid != "" } {
            ModelsSetScalarsLut $mid $lutid "false"
        } else {
            puts "WARNING: ModelsPickScalarsCallback $mid : failed to find lut id for Label"
        }
    } else {
        ModelsSetScalarsLut $mid "" "false" ;# tells it to use the default
    }

    if { $::Model(scalarVisibilityAuto) == "1" } {
        ModelsPropsApplyButNotToNew
    }

    Render3D
} 


#-------------------------------------------------------------------------------
# .PROC ModelsPickScalarsLut
# 
#  Pick which color lookup table to use with model
#
# TODO - this lut and scalars need to be added to mrml
#
# .ARGS
# windowpath parentButton the button to hang the pop up off of
# .END
#-------------------------------------------------------------------------------
proc ModelsPickScalarsLut { parentButton } {
    global Gui

    set m $::Model(activeID)
    if {$m == ""} { return }
    
    catch "destroy .mpickscalarslut"
    eval menu .mpickscalarslut $Gui(WMA)

    set ren [lindex $::Module(Renderers) 0]
    set currlut [Model($m,mapper,$ren) GetLookupTable]

    foreach l $::Lut(idList) {
        if { "Lut($l,lut)" == $currlut } {
            set labeltext "* $::Lut($l,name) *"
        } else {
            set labeltext "$::Lut($l,name)"
        }
        .mpickscalarslut insert end command -label $labeltext \
            -command "ModelsSetScalarsLut $m $l \; Render3D"
    }
    
    set x [expr [winfo rootx $parentButton] + 10]
    set y [expr [winfo rooty $parentButton] + 10]
    
    .mpickscalarslut post $x $y
}

#-------------------------------------------------------------------------------
# .PROC ModelsSetScalarsLut
# 1 set a default for this model if one hasn't been set yet<br>
# 2 if no id specified, use default<br>
# 3 if setDefault specified, save the value<br>
# 4 set all luts for all the renderers<br>
# .ARGS
# int mid model id
# int lutid the id of the look up table
# bool setDefault if true, use this lut as the default, defaults to true
# .END
#-------------------------------------------------------------------------------
proc ModelsSetScalarsLut { mid lutid {setDefault "true"} } {
    if {$::Module(verbose)} {
        puts "ModelsSetScalarsLut model = $mid, lut = $lutid"
    }

    if { ![info exists ::Models($mid,defaultLut)] } {
        set ::Models($mid,defaultLut) 0
    }

    if { $lutid == "" } {
        set lutid $::Models($mid,defaultLut)
    } 

    if { $setDefault == "true" } {
        set ::Models($mid,defaultLut) $lutid
    }

    if {[info command Lut($lutid,lut)] == ""} {
        DevWarningWindow "ModelsSetScalarsLut: no look up table for id $lutid!"
        return
    }

    foreach r $::Module(Renderers) {
        if {$::Module(verbose)} {
            puts "ModelsSetScalarsLut: setting lookup table for model $mid mapper $r to Lut($lutid,lut) (exists = [info command Lut($lutid,lut)]"
        }
        Model($mid,mapper,$r) SetLookupTable Lut($lutid,lut)
    }
    if {$::Module(verbose)} {
        puts "ModelsSetScalarsLut: done setting lookup table for all renderers, saving the lut name in the model node now: \"$lutid\", model exists = [info command Model($mid,node)]"
    }
    # save the lut id in the node
    Model($mid,node) SetLUTName $lutid

    if {$::Module(verbose)} {
        puts "ModelsSetScalarsLut: returning"
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelsAddScalars 
# 
#  Pick a .vtk .anno file that has scalars for this model
#
# .ARGS
# filename scalarfile optional, if empty, get the file name from the user
# .END
#-------------------------------------------------------------------------------
proc ModelsAddScalars { {scalarfile ""} } {
    global Model 

    set m $Model(activeID)
    if {$m == ""} { return }
    set mnpts [$Model($m,polyData) GetNumberOfPoints]
    set mptdata [$Model($m,polyData) GetPointData]

    if { $scalarfile == "" } {
        set scalarfile [tk_getOpenFile \
            -initialdir [file dirname [Model($m,node) GetFileName]] \
            -title "Select Scalar File" ]
    }
    
    if { $scalarfile == "" } { return }

    switch [file extension $scalarfile] {
        ".annot" {
            if { [catch "package require vtkFreeSurferReaders"] } {
                DevErrorWindow ".annot files not readable without vtkFreeSurferReaders Module"
                return
            }
            set s annotation
            catch "Model($m,intArray$s) Delete"
            vtkIntArray Model($m,intArray$s)
            catch "Model($m,colorTable$s) Delete"
            vtkLookupTable Model($m,colorTable$s)
            Model($m,intArray$s) SetName $s

            set fssar fssar_ModelSetScalars
            catch "$fssar Delete"
            vtkFSSurfaceAnnotationReader $fssar
            $fssar SetFileName $scalarfile
            $fssar SetOutput Model($m,intArray$s)
            $fssar SetColorTableOutput Model($m,colorTable$s)
            $fssar ReadFSAnnotation
            if { [Model($m,intArray$s) GetNumberOfTuples] != $mnpts } {
                DevErrorWindow "No valid scalar arrays in $scalarfile"
            } else {
                $mptdata AddArray Model($m,intArray$s)
                $mptdata SetActiveScalars "labels"
            }
            catch "$fssar Delete"
        }
        ".vtk" {
            catch "scalars_spr Delete"
            vtkStructuredPointsReader scalars_spr
            scalars_spr SetFileName $scalarfile
            scalars_spr Update
            set sp [scalars_spr GetOutput]

            set ptdata [$sp GetPointData]
            set narrays [$ptdata GetNumberOfArrays]
            set scalararrays ""
            set scalararraynames ""
            for {set i 0} {$i < $narrays} {incr i} {
                set arr [$ptdata GetArray $i]
                if { [$arr GetNumberOfComponents] == 1 &&
                        [$arr GetNumberOfTuples] == $mnpts } {
                    lappend scalararrays $arr
                    $mptdata AddArray $arr
                    $arr SetName "[$arr GetName] ([file rootname [file tail $scalarfile]])"
                    $mptdata SetActiveScalars [$arr GetName]
                }
            }
            if { $scalararrays == "" } {
                DevErrorWindow "No valid scalar arrays in $scalarfile"
            } 
            scalars_spr Delete
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ModelsMeter
# Count the polygons in each model, measure how long it takes to render them.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsMeter {} {
    global Model Module

    # Count the polygons in each model
    set total 0
    set msgLeft ""
    set msgRight ""
    foreach m $Model(idList) {

        if {[info exists Model($m,nPolys)] == 0} {

            vtkTriangleFilter triangle
            triangle SetInput $Model($m,polyData)
            [triangle GetOutput] ReleaseDataFlagOn
            triangle Update
            set Model($m,nPolys) [[triangle GetOutput] GetNumberOfPolys]

            vtkStripper stripper
            stripper SetInput [triangle GetOutput]
            [stripper GetOutput] ReleaseDataFlagOff

            # polyData will survive as long as it's the input to the mapper
            set Model($m,polyData) [stripper GetOutput]
            $Model($m,polyData) Update

            foreach r $Module(Renderers) {
                Model($m,mapper,$r) SetInput $Model($m,polyData)
            }

            stripper SetOutput ""
            foreach p "triangle stripper" {
                $p SetInput ""
                $p Delete
            }
        }
        #        puts "m=$m: ref=[$Model($m,polyData) GetReferenceCount]"

        set n $Model($m,nPolys)
        if {[Model($m,node) GetVisibility] == 1} {
            set total [expr $total + $n]
        }
        set msgLeft "$msgLeft\n[Model($m,node) GetName]"
        set msgRight "$msgRight\n[commify $n]"
    }


    # Compute rate
    set t [lindex [time {Render3D; update}] 0]
    if {$t > 0} {
        set rate [expr $total / ($t/1000000.0)]
    } else {
        set rate 0
    }

    set msgTop "\
            Total visible polygons: [commify $total]\n\
            Render time: [format "%.3f" [expr $t/1000000.0]]\n\
            Polygons/sec rendered: [commify [format "%.0f" $rate]]"

    $Model(meter,msgTop) config -text $msgTop
    $Model(meter,msgLeft) config -text $msgLeft
    $Model(meter,msgRight) config -text $msgRight

    if {$Model(meter,first) == 1} {
        set Model(meter,first) 0
        ModelsMeter
    }
}

#-------------------------------------------------------------------------------
# .PROC commify
# 
# Utility routine borrowed from http://aspn.activestate.com/ASPN/Cookbook/Tcl/Recipe/146220
# <br>
# commify --
#   puts commas into a decimal number
# <br>
# Returns:
#   number with commas in the appropriate place
#
# .ARGS
# int num number in acceptable decimal format
# char sep  separator char, defaults to English format comma
# .END
#-------------------------------------------------------------------------------
proc commify {num {sep ,}} {
    while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1$sep\\2" num]} {}
    return $num
}

#-------------------------------------------------------------------------------
# .PROC ModelsFreeSurferPropsApply
# 
# This either updates the information about the model or it creates
# a new model if the model is new.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ModelsFreeSurferPropsApply {} {
    global Model Label Module Mrml


    DevInfoWindow "ModelsFreeSurferPropsApply: Calling VolFreeSurferReadersModelApply instead..."
    VolFreeSurferReadersModelApply
}
