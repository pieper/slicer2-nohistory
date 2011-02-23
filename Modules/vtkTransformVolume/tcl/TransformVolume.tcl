#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: TransformVolume.tcl,v $
#   Date:      $Date: 2007/03/13 21:36:51 $
#   Version:   $Revision: 1.31 $
# 
#===============================================================================
# FILE:        TransformVolume.tcl
# PROCEDURES:  
#   TransformVolumeInit
#   TransformVolumeBuildVTK
#   TransformVolumeEnter
#   TransformVolumeExit
#   TransformVolumeBuildGUI
#   TransformVolumeUpdateGUI
#   TransformVolumeRun
#   TransformVolumeGetVolumes transformId
#   TransformVolumeVolumeExists name
#   TransformVolumeTransform id
#   TransformVolumeDispVolume id
#   TransformVolumeRefVolume id
#   TransformVolumeOrientation orient
#   TransformVolumeResampleMode mode
#   TransformVolumeUpdateResample
#   TransformVolumeUpdatePreview
#   TransformVolumeAutoSpacing
#   AutoExtent
#   TransformVolumeInterpolationMode mode
#   TransformVolumeAutoDimensionLR
#   TransformVolumeAutoDimensionPA
#   TransformVolumeAutoDimensionIS
#   TransformVolumeResultPrefix prefix
#   TransformVolumeOutputSpacingLR spacing
#   TransformVolumeOutputSpacingPA spacing
#   TransformVolumeOutputSpacingIS spacing
#   TransformVolumeOutputDimensionLR dimension
#   TransformVolumeOutputDimensionPA dimension
#   TransformVolumeOutputDimensionIS dimension
#   TransformVolumePermuteDimensions
#   TransformVolumePermuteDimensions
#   TransformVolumePermuteSpacing
#   TransformVolumePermuteSpacing
#   TransformVolumeCreatePreview
#   TransformVolumeExitPreview
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC TransformVolumeInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeInit {} {
    global TransformVolume Module Volume Model
    
    set m TransformVolume
    
    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is an example of how to add modules to slicer."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "First name, last name, affiliation, email"
    
    #  Set the level of development that this module falls under, from the list defined in Main.tcl,
    #  Module(categories) or pick your own
    #  This is included in the Help->Module Categories menu item
    set Module($m,category) "Example"
    
    # Define Tabs
    #------------------------------------
    # Description:
    #   Each module is given a button on the Slicer's main menu.
    #   When that button is pressed a row of tabs appear, and there is a panel
    #   on the user interface for each tab.  If all the tabs do not fit on one
    #   row, then the last tab is automatically created to say "More", and 
    #   clicking it reveals a second row of tabs.
    #
    #   Define your tabs here as shown below.  The options are:
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #

    set Module($m,row1List) "Help Main Resample"
    set Module($m,row1Name) "{Help} {Main} {Resample}"
    set Module($m,row1,tab) Main
    
    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #
    #   set Module($m,procVTK) TransformVolumeBuildVTK
    #
    #   All the options are:

    #   procGUI   = Build the graphical user interface
    #   procVTK   = Construct VTK objects
    #   procMRML  = Update after the MRML tree changes due to the creation
    #               of deletion of nodes.
    #   procEnter = Called when the user enters this module by clicking
    #               its button on the main menu
    #   procExit  = Called when the user leaves this module by clicking
    #               another modules button
    #   procCameraMotion = Called right before the camera of the active 
    #                      renderer is about to move 
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) TransformVolumeBuildGUI
    set Module($m,procVTK) TransformVolumeBuildVTK
    set Module($m,procEnter) TransformVolumeEnter
    set Module($m,procExit) TransformVolumeExit
    set Module($m,procMainExit) TransformVolumeExit
    set Module($m,procMRML) TransformVolumeUpdateGUI

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) ""

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.31 $} {$Date: 2007/03/13 21:36:51 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set TransformVolume(ResultPrefix) "xformed"
    set TransformVolume(VolIDs) ""
    set TransformVolume(RefVolume) ""
    set TransformVolume(DispVolume) ""

    set TransformVolume(OutputOrientation) "LR"
    set TransformVolume(OutputSpacingLR) 1
    set TransformVolume(OutputSpacingPA) 1
    set TransformVolume(OutputSpacingIS) 1
    set TransformVolume(OutputDimensionLR) 64
    set TransformVolume(OutputDimensionPA) 64
    set TransformVolume(OutputDimensionIS) 64
    set TransformVolume(ResamplingModes) {"SourceVolume" "ReferenceVolume" "Resample"}
    set TransformVolume(ResamplingMode) 0
    set TransformVolume(InterpolationModes) {"NearestNeighbor" "Linear" "Cubic"}
    set TransformVolume(InterpolationMode) Cubic
    set TransformVolume(resampleConrols) ""
}

# NAMING CONVENTION:
#-------------------------------------------------------------------------------
#
# Use the following starting letters for names:
# t  = toplevel
# f  = frame
# mb = menubutton
# m  = menu
# b  = button
# l  = label
# s  = slider
# i  = image
# c  = checkbox
# r  = radiobutton
# e  = entry
#
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# .PROC TransformVolumeBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeBuildVTK {} {

}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeEnter {} {
    global TransformVolume Gui
}


#-------------------------------------------------------------------------------
# .PROC TransformVolumeExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeExit {} {
    global TransformVolume
    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    #popEventManager

    if { [info exists TransformVolume(OutputIsv)] && $TransformVolume(OutputIsv) != "" } {
        $TransformVolume(OutputIsv) pre_destroy
        destroy $TransformVolume(OutputIsv)
    }
    set TransformVolume(OutputIsv) ""

    TransformVolumeExitPreview
}


#-------------------------------------------------------------------------------
# .PROC TransformVolumeBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeBuildGUI {} {
    global Gui TransformVolume Module Volume 
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Main" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(TransformVolume,fMain)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Main
    #-------------------------------------------
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The TransformVolume module transforms all volumes inside a slected Transformation node using trasformation matrices inside the Transformation node and a specified deformable transformation defined by a selected displacement volume containing 2 or 3 components displacement vectors.  The resulting volumes have the same spacing and orientation as specified reference volume. The source code is in slicer2/Modules/vtkTransformVolume/tcl/TransformVolume.tcl.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags TransformVolume $help
    MainHelpBuildGUI TransformVolume
    
    #-------------------------------------------
    # Main frame
    #-------------------------------------------
    set fMain $Module(TransformVolume,fMain)

    set f $fMain.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    
    set f $fMain  
    
    # Transform node
    istransformoption  $f.matopt -labeltext "Transform Node" -labelpos w \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} -labelmargin 5 \
        -command TransformVolumeTransform

    set TransformVolume(transform) $f.matopt
    
    $TransformVolume(transform) allowNone 0
    
    # Displacement volume
    isvolumeoption  $f.volopt -labeltext "Deformation Volume" -labelpos w \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} -labelmargin 5 \
        -command TransformVolumeDispVolume
    set TransformVolume(displacementVol) $f.volopt
    
    $TransformVolume(displacementVol) numScalars 3
    $TransformVolume(displacementVol) allowNone 1
   
    # Reference volume
    isvolumeoption  $f.volref -labeltext "Reference(like) Volume" -labelpos w \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} -labelmargin 5 \
        -command TransformVolumeRefVolume

    set TransformVolume(referenceVol) $f.volref

    $TransformVolume(referenceVol) allowNone 1

    # Main->ReasmpleMode
    iwidgets::radiobox $f.rbresample -labeltext "Resample Mode" -labelpos n \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} -orient vertical \
        -command TransformVolumeResampleMode

    foreach or $TransformVolume(ResamplingModes) {
        $f.rbresample add $or -text $or
    }
    set TransformVolume(resampleMode) $f.rbresample
    $TransformVolume(resampleMode) select $TransformVolume(ResamplingMode)

    # Main->Interpolation Mode
    iwidgets::radiobox $f.rbinterpmode -labeltext "Interpolation Mode" -labelpos n \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} -orient horizontal \
        -command TransformVolumeInterpolationMode

    foreach or $TransformVolume(InterpolationModes) {
        $f.rbinterpmode add $or -text $or
    }
    set TransformVolume(interpolationMode) $f.rbinterpmode
    $TransformVolume(interpolationMode) select $TransformVolume(InterpolationMode)

    # Main- Result prefix
    iwidgets::entryfield $f.ePrefix -labeltext "Result Prefix:" -labelpos w \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(ResultPrefix) \
        -command TransformVolumeResultPrefix

    set TransformVolume(resultPrefix) $f.ePrefix

    # Main->Preview
    iwidgets::pushbutton  $f.bPreview \
        -text "Show Preview" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -command TransformVolumeCreatePreview

    # Transform button
    iwidgets::pushbutton  $f.brun \
        -text "Do Transform" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -command TransformVolumeRun

    set TransformVolume(brun) $f.brun

    iwidgets::Labeledwidget::alignlabels $f.matopt $f.volopt $f.volref $f.ePrefix 

    pack $f.matopt $f.volopt $f.volref $f.rbresample $f.rbinterpmode $f.ePrefix $f.bPreview $f.brun \
        -side top -padx $Gui(pad) -pady $Gui(pad) \
        -fill x \
        -expand yes


    #-------------------------------------------
    # Resample frame
    #-------------------------------------------
    set fResample $Module(TransformVolume,fResample)
    
    set f $fResample.fTitle
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    
    set f $fResample  

    # Reasmple->Orientation
    iwidgets::radiobox $f.rborient -labeltext "New Orientation" -labelpos n \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} -orient horizontal \
        -command TransformVolumeOrientation

    foreach or {"LR" "RL" "PA" "AP" "IS" "SI"} {
        $f.rborient add $or -text $or
    }
    pack $f.rborient -side top -padx $Gui(pad) -pady $Gui(pad)
    set TransformVolume(orientation) $f.rborient

    lappend TransformVolume(resampleConrols) $f.rborient

    # Resample->Spacing
    set f $fResample.fOutputSpacing
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx 0 -pady $Gui(pad) -fill x

    set f $fResample.fOutputSpacing
    eval {label $f.lOutputSpacing -text "New Spacing"} $Gui(WLA)
    pack $f.lOutputSpacing -side top -padx $Gui(pad) -pady $Gui(pad)

    iwidgets::entryfield $f.eOutputSpacingLR -labeltext "LR:" -labelpos w \
        -width 6 \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(OutputSpacingLR) \
        -command TransformVolumeOutputSpacingLR

    iwidgets::entryfield $f.eOutputSpacingPA -labeltext "PA:" -labelpos w \
        -width 6 \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(OutputSpacingPA) \
        -command TransformVolumeOutputSpacingPA

    iwidgets::entryfield $f.eOutputSpacingIS -labeltext "IS:" -labelpos w \
        -width 6 \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(OutputSpacingIS) \
        -command TransformVolumeOutputSpacingIS

    pack $f.eOutputSpacingLR $f.eOutputSpacingPA $f.eOutputSpacingIS -side left -padx $Gui(pad) -pady $Gui(pad)
    
    lappend TransformVolume(resampleConrols) $f.eOutputSpacingLR $f.eOutputSpacingPA $f.eOutputSpacingIS

    # Resample->Auto Spacing
    set f $fResample  
    iwidgets::pushbutton  $f.bAutoSpacing \
        -text "Original Spacing" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -command TransformVolumeAutoSpacing

    pack $f.bAutoSpacing -side top -padx $Gui(pad) -pady $Gui(pad)

    lappend TransformVolume(resampleConrols) $f.bAutoSpacing

    # Resample->Dimenisons
    set f $fResample.fOutputDimension
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx 0 -pady $Gui(pad) -fill x

    set f $fResample.fOutputDimension
    eval {label $f.lOutputDimension -text "New Dimensions"} $Gui(WLA)
    pack $f.lOutputDimension -side top -padx $Gui(pad) -pady $Gui(pad)

    iwidgets::entryfield $f.eOutputDimensionLR -labeltext "LR:" -labelpos w \
        -width 6 \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(OutputDimensionLR) \
        -command TransformVolumeOutputDimensionLR

    iwidgets::entryfield $f.eOutputDimensionPA -labeltext "PA:" -labelpos w \
        -width 6 \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(OutputDimensionPA) \
        -command TransformVolumeOutputDimensionPA

    iwidgets::entryfield $f.eOutputDimensionIS -labeltext "IS:" -labelpos w \
        -width 6 \
        -background "#e2cdba" -foreground "#000000" \
        -labelfont {helvetica 8} \
        -textvariable TransformVolume(OutputDimensionIS) \
        -command TransformVolumeOutputDimensionIS

    pack $f.eOutputDimensionLR $f.eOutputDimensionPA $f.eOutputDimensionIS -side left -padx $Gui(pad) -pady $Gui(pad)
    
    lappend TransformVolume(resampleConrols) $f.eOutputDimensionLR $f.eOutputDimensionPA $f.eOutputDimensionIS

    # Resample->Set Extent
    set f $fResample.fSetExtent
    frame $f -bg $Gui(activeWorkspace)
    pack $f -side top -padx 0 -pady $Gui(pad) -fill x
  
    set f $fResample.fSetExtent
    iwidgets::pushbutton  $f.bIsoExtentI \
        -text "Auto LR" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -width 70 \
        -command TransformVolumeAutoDimensionLR

    set f $fResample.fSetExtent
    iwidgets::pushbutton  $f.bIsoExtentJ \
        -text "Auto PA" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -width 70 \
        -command TransformVolumeAutoDimensionPA

    set f $fResample.fSetExtent
    iwidgets::pushbutton  $f.bIsoExtentK \
        -text "Auto IS" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -width 70 \
        -command TransformVolumeAutoDimensionIS

    pack $f.bIsoExtentI  $f.bIsoExtentJ $f.bIsoExtentK -side left -padx $Gui(pad)
    lappend TransformVolume(resampleConrols) $f.bIsoExtentI  $f.bIsoExtentJ $f.bIsoExtentK

    # Resample->Auto Extent
    set f $fResample  
    iwidgets::pushbutton  $f.bAutoDimension \
        -text "Auto Dimension" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -command TransformVolumeAutoDimension

    pack $f.bAutoDimension -side top -padx $Gui(pad) -pady $Gui(pad)
    lappend TransformVolume(resampleConrols) $f.bAutoDimension 

    set TransformVolume(fResample) $fResample

    # Resample->Preview
    set f $fResample  
    iwidgets::pushbutton  $f.bPreview \
        -text "Show Preview" \
        -background "#e2cdba" -foreground "#000000" \
        -font {helvetica 8} \
        -height 32 \
        -command TransformVolumeCreatePreview

    pack $f.bPreview -side top -padx $Gui(pad) -pady $Gui(pad)

    TransformVolumeResampleMode
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeUpdateGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeUpdateGUI {} {
    global TransformVolume
    $TransformVolume(displacementVol) initSelection
    $TransformVolume(referenceVol) initSelection
    $TransformVolume(transform) initSelection
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeRun {} {
    global TransformVolume Volume
    
    $TransformVolume(brun) configure -state disabled
    #-- accumulate newly created volume nodes
    set localIDs ""

    # get displacement volume
    set TransformVolume(DispVolume) [$TransformVolume(displacementVol) selectedID]
    set vDisp $TransformVolume(DispVolume)
    
    if {![info exists TransformVolume(OutputIsv)] || $TransformVolume(OutputIsv) == ""} {
        catch ".isv pre_destroy"
        catch "destroy .isv"
        isvolume .isv
        set  TransformVolume(OutputIsv) .isv
    } 
    set isv $TransformVolume(OutputIsv)
    
    $isv volmenu_update

    set TransformVolume(VolIDs) [TransformVolumeGetVolumes [$TransformVolume(transform) selectedID]]
    set nodes [TransformVolumeGetVolumesAndTensors [$TransformVolume(transform) selectedID]]
    foreach n $nodes {
        
        puts " TransformVolume : transforming volume [$n GetName]"
        
        # create result name
        set id [$n GetID]
        set resVolName $TransformVolume(ResultPrefix)


        # check for Tensor
        if { [string match "Tensor*" $n] } {
            append resVolName "_" [Tensor($id,node) GetName]
            $isv configure -volume [Tensor($id,data) GetOutput] -tensor "true"
            $isv configure -interpolation $TransformVolume(InterpolationMode)
            set label_map "false"
        } else {
            $isv configure -volume [Volume($id,node) GetID] -tensor "false"
            if {[Volume($id,node) GetInterpolate] != 0} {
                $isv configure -interpolation $TransformVolume(InterpolationMode)
            } else {
                $isv configure -interpolation "NearestNeighbor"
            }
            if {[Volume($id,node) GetLabelMap] != 0} {
                set label_map "true"
            } else {
                set label_map "false"
            }
            append resVolName "_" [Volume($id,node) GetName]
        }

        $isv configure -orientation $TransformVolume(OutputOrientation)

        TransformVolumePermuteDimensions
        TransformVolumePermuteSpacing

        $isv set_spacing $TransformVolume(OutputSpacingI) \
            $TransformVolume(OutputSpacingJ) \
            $TransformVolume(OutputSpacingK)
        $isv set_dimensions $TransformVolume(OutputDimensionI) \
            $TransformVolume(OutputDimensionJ) \
            $TransformVolume(OutputDimensionK)
        
        if {$vDisp != "" && $vDisp != $Volume(idNone)} {
            puts " TransformVolume : displacement volume [Volume($vDisp,node) GetName]"
            $isv configure -warpvolume [Volume($vDisp,node) GetName]
        } else {
            $isv configure -warpvolume $Volume(idNone)
        }
        
        
        # check if the result name exists already
        set exists [TransformVolumeVolumeExists $resVolName]
        if {$exists == "1"} {
            set count 0
            while {1} {
                set name $resVolName
                append name $count
                set exists [TransformVolumeVolumeExists $name]
                if {$exists == "0"} {
                    set resVolName $name
                    break
                }
                incr count
            }
        }

        # get the volume
        set newID [$isv slicer_volume $resVolName $label_map]
        lappend localIDs $newID
    }

    $TransformVolume(brun) configure -state normal
    return $localIDs

}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeGetVolumes
# 
# .ARGS
# int transformId
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeGetVolumes {transformId} {
    global Data Mrml Transform EndTransform
    
    set volIDs ""

    if {$transformId != ""} {
        set tree Mrml(dataTree)
        $tree InitTraversal
        set node [$tree GetNextItem]
        
        set insideTransform 0
        set done 0
        set inside 0
        while {$node != ""} {
            
            set nodeClass [$node GetClassName]
            
            switch $nodeClass {
                "vtkMrmlVolumeNode" {
                    if {$inside} {
                        set id [DataGetIdFromNode $node]
                        lappend volIDs $id
                    }
                }
                "vtkMrmlTransformNode" {
                    if {[$node GetName] == [Transform($transformId,node) GetName]} {
                        incr insideTransform
                        set inside 1
                    }
                }
                "vtkMrmlEndTransformNode" {
                    if {$inside } {
                        incr insideTransform -1
                        if {$insideTransform == 0} {
                            set done 1
                        }
                    }
                }
            }
            if {$done} {
                break
            }
            set node [$tree GetNextItem]
        }
    }
    return $volIDs
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeGetVolumesAndTensors
# 
# .ARGS
# int transformId
# Returns - list of volume and tensor nodes
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeGetVolumesAndTensors {transformId} {
    global Data Mrml Transform EndTransform
    
    set nodes ""

    if {$transformId != ""} {
        set tree Mrml(dataTree)
        $tree InitTraversal
        set node [$tree GetNextItem]
        
        set insideTransform 0
        set done 0
        set inside 0
        while {$node != ""} {
            
            set nodeClass [$node GetClassName]
            
            switch $nodeClass {
                "vtkMrmlVolumeNode" {
                    if {$inside} {
                        lappend nodes $node
                    }
                }
                "vtkMrmlTransformNode" {
                    if {[$node GetName] == [Transform($transformId,node) GetName]} {
                        incr insideTransform
                        set inside 1
                    }
                }
                "vtkMrmlEndTransformNode" {
                    if {$inside } {
                        incr insideTransform -1
                        if {$insideTransform == 0} {
                            set done 1
                        }
                    }
                }
            }
            if {$done} {
                break
            }
            set node [$tree GetNextItem]
        }
    }
    return $nodes
}
#-----------------------------

#-------------------------------------------------------------------------------
# .PROC TransformVolumeVolumeExists
# 
# .ARGS
# string name
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeVolumeExists {name} {
    global Volume
    foreach v $Volume(idList) {
        set index [lsearch -exact $name [Volume($v,node) GetName]]
        if {$index > -1} {
            # name exists
            return 1
        }
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeTransform
# 
# .ARGS
# list id defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeTransform {{id ""}} {
    global TransformVolume
    
    if {$id != ""} {
        set TransformVolume(VolIDs) [TransformVolumeGetVolumes $id]
    } else {
        set TransformVolume(VolIDs) [TransformVolumeGetVolumes [$TransformVolume(transform) selectedID]]
    }
    TransformVolumeUpdateResample
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeDispVolume
# 
# .ARGS
# list id defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeDispVolume {{id ""}} {
    global TransformVolume
    
    if {$id != ""} {
        set TransformVolume(DispVolume) $id
    } else {
        set TransformVolume(DispVolume) [$TransformVolume(displacementVol) selectedID]
    }
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeRefVolume
# 
# .ARGS
# list id defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeRefVolume {{id ""}} {
    global TransformVolume
    
    if {$id != ""} {
        set TransformVolume(RefVolume) $id
    } else {
        set TransformVolume(RefVolume) [$TransformVolume(referenceVol) selectedID]
    }
    
    TransformVolumeUpdateResample
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeOrientation
# 
# .ARGS
# string orient defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOrientation {{orient ""}} {
    global TransformVolume
    
    if {$orient != "" } {
        set TransformVolume(OutputOrientation) $orient
    } else {
        set TransformVolume(OutputOrientation) [$TransformVolume(orientation) get]
    }
    
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeResampleMode
# 
# .ARGS
# string mode defaults to emtpy string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeResampleMode {{mode ""}} {
    global TransformVolume
    
    if {$mode != "" } {
        set TransformVolume(ResamplingMode) $mode
    } else {
        set mode [$TransformVolume(resampleMode) get]
        set TransformVolume(ResamplingMode) [lsearch $TransformVolume(ResamplingModes) $mode]
    }
    
    $TransformVolume(resampleMode) select $mode
    
    switch $TransformVolume(ResamplingMode) {
        "0" {
            foreach c $TransformVolume(resampleConrols) {
                $c configure -state disabled
            }
            $TransformVolume(referenceVol) configure -state disabled
        }
        "1" {
            foreach c $TransformVolume(resampleConrols) {
                $c configure -state disabled
            }
            $TransformVolume(referenceVol) configure -state normal
        }
        "2" {
            foreach c $TransformVolume(resampleConrols) {
                $c configure -state normal
            }
            $TransformVolume(referenceVol) configure -state disabled
        }
    }
    TransformVolumeRefVolume
    TransformVolumeUpdateResample
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeUpdateResample
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeUpdateResample {} {
    global TransformVolume Volume
    
    # set reference volume
    set TransformVolume(RefVolume) [$TransformVolume(referenceVol) selectedID]
    set vRef $TransformVolume(RefVolume)
    
    # get volumes to transform under a transform node
    set TransformVolume(VolIDs) [TransformVolumeGetVolumes [$TransformVolume(transform) selectedID]]
    set volIDs $TransformVolume(VolIDs)
    
    set v $Volume(idNone)
    
    if {$TransformVolume(ResamplingMode) == 0} {
        # use source as reference
        if {[llength $volIDs] != 0} {
            set v [lindex $volIDs 0]
        }
    } else {
        if {$TransformVolume(ResamplingMode) == 1} {
            set v $vRef
        }
    }

    if {$v != $Volume(idNone) && $v != ""} {
        set spacing [split [[Volume($v,vol) GetOutput] GetSpacing]] 

        set TransformVolume(OutputSpacingI) [lindex $spacing 0] 
        set TransformVolume(OutputSpacingJ) [lindex $spacing 1] 
        set TransformVolume(OutputSpacingK) [lindex $spacing 2] 

        set dimension [split [[Volume($v,vol) GetOutput] GetDimensions]] 
        
        set TransformVolume(OutputDimensionI) [expr round(abs([lindex $dimension 0]))]
        set TransformVolume(OutputDimensionJ) [expr round(abs([lindex $dimension 1]))]
        set TransformVolume(OutputDimensionK) [expr round(abs([lindex $dimension 2]))]

        set TransformVolume(OutputOrientation) [Volume($v,node) GetScanOrder]

        TransformVolumePermuteIjkDimensions
        TransformVolumePermuteIjkSpacing
    }

    if {[info exists TransformVolume(OutputOrientation)] && [info exists TransformVolume(orientation)]} {
        $TransformVolume(orientation) select $TransformVolume(OutputOrientation)
    }
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeUpdatePreview
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeUpdatePreview {} {
    global TransformVolume Volume

    # get volumes to transform under a transform node
    set TransformVolume(VolIDs) [TransformVolumeGetVolumes [$TransformVolume(transform) selectedID]]
    set volIDs $TransformVolume(VolIDs)
        
    set v $Volume(idNone)

    if {[llength $volIDs] != 0} {
        set v [lindex $volIDs 0]
    }
    
    # get displacement volume
    set TransformVolume(DispVolume) [$TransformVolume(displacementVol) selectedID]
    set vDisp $TransformVolume(DispVolume)
    
    if {$v != $Volume(idNone) && [info exists TransformVolume(isv)] && $TransformVolume(isv) != ""} {
        
        set isv $TransformVolume(isv)

        $isv volmenu_update

        $isv configure -volume [Volume($v,node) GetID]

        if {[info exists TransformVolume(OutputOrientation)]} {
            $isv configure -orientation $TransformVolume(OutputOrientation)
        }

        if {[Volume($v,node) GetInterpolate] != 0} {
            $isv configure -interpolation $TransformVolume(InterpolationMode)
        } else {
            $isv configure -interpolation "NearestNeighbor"
        }

        TransformVolumePermuteDimensions
        TransformVolumePermuteSpacing

        $isv set_spacing $TransformVolume(OutputSpacingI) \
            $TransformVolume(OutputSpacingJ) \
            $TransformVolume(OutputSpacingK)
        $isv set_dimensions $TransformVolume(OutputDimensionI) \
            $TransformVolume(OutputDimensionJ) \
            $TransformVolume(OutputDimensionK)
        
        puts "Preview: dispalcement volume is $vDisp"
        if {$vDisp != "" && $vDisp != $Volume(idNone)} {
            $isv configure -warpvolume [Volume($vDisp,node) GetName]
        } else {
            $isv configure -warpvolume $Volume(idNone)
        }
        
        $isv configure -slice [expr int(0.5*$TransformVolume(OutputDimensionK))]

        $isv expose
    }
        
}


#-------------------------------------------------------------------------------
# .PROC TransformVolumeAutoSpacing
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeAutoSpacing {} {
    global Matrix Volume TransformVolume

    # get volumes to transform under a transform node
    set TransformVolume(VolIDs) [TransformVolumeGetVolumes [$TransformVolume(transform) selectedID]]   
    set volIDs $TransformVolume(VolIDs)
        
    set v $Volume(idNone)

    if {[llength $volIDs] != 0} {
        set v [lindex $volIDs 0]
    }
    
    if {$v != $Volume(idNone)} {
        catch "ModelRasToVtk Delete"
        vtkMatrix4x4 ModelRasToVtk
        set position [Volume($v,node) GetPositionMatrix]
        if {$::Module(verbose)} { puts "$position" }
        ModelRasToVtk Identity
        set ii 0
        for {set i 0} {$i < 4} {incr i} {
            for {set j 0} {$j < 4} {incr j} {
                # Put the element from the position string
                ModelRasToVtk SetElement $i $j [lindex $position $ii]
                incr ii
            }
            # Remove the translation elements
            ModelRasToVtk SetElement $i 3 0
        }
        # add a 1 at the for  M(4,4)
        ModelRasToVtk SetElement 3 3 1
        # Matrix now is
        # a b c 0
        # d e f 0
        # g h i 0 
        # 0 0 0 1
        # a -> i is either -1 0 or 1 depending on 
        # the original orientation of the volume
        
        set spacing [split [[Volume($v,vol) GetOutput] GetSpacing]]     
        set point  [ModelRasToVtk MultiplyPoint [lindex $spacing 0] [lindex $spacing 1] [lindex $spacing 2] 1 ]
        if {$::Module(verbose)} {  puts "LR PA IS $point" }
        set TransformVolume(OutputSpacingLR) [expr abs([lindex $point 0])]
        set TransformVolume(OutputSpacingPA) [expr abs([lindex $point 1])]
        set TransformVolume(OutputSpacingIS) [expr abs([lindex $point 2])]
        ModelRasToVtk Delete
    }
}


#-------------------------------------------------------------------------------
# .PROC AutoExtent
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeAutoDimension {} {
    global TransformVolume Module Matrix Volume

    set TransformVolume(VolIDs) [TransformVolumeGetVolumes [$TransformVolume(transform) selectedID]]
    set volIDs $TransformVolume(VolIDs)   

    set v $Volume(idNone)

    if {[llength $volIDs] != 0} {
        set v [lindex $volIDs 0]
    }
    if {$v != $Volume(idNone)} {
        
        #Set default values
        # Make a RAS to VTK matrix for realign resample
        # based on the position matrix
        catch "ModelRasToVtk Delete"
        vtkMatrix4x4 ModelRasToVtk
        set position [Volume($v,node) GetPositionMatrix]
        
        ModelRasToVtk Identity
        set ii 0
        for {set i 0} {$i < 4} {incr i} {
            for {set j 0} {$j < 4} {incr j} {
                # Put the element from the position string
                ModelRasToVtk SetElement $i $j [lindex $position $ii]
                incr ii
            }
            # Remove the translation elements
            ModelRasToVtk SetElement $i 3 0
        }
        # add a 1 at the for  M(4,4)
        ModelRasToVtk SetElement 3 3 1
        
        # Now we can build the Vtk1ToVtk2 matrix based on
        # ModelRasToVtk and ras1toras2
        # vtk1tovtk2 = inverse(rastovtk) ras1toras2 rastovtk
        # RasToVtk
        catch "RasToVtk Delete"
        vtkMatrix4x4 RasToVtk
        RasToVtk DeepCopy ModelRasToVtk    
        # Inverse Matrix RasToVtk
        catch "InvRasToVtk Delete"
        vtkMatrix4x4 InvRasToVtk
        InvRasToVtk DeepCopy ModelRasToVtk
        InvRasToVtk Invert
        # Ras1toRas2 given by the slicer MRML tree
        catch "Ras1ToRas2 Delete"    
        vtkMatrix4x4 Ras1ToRas2
        #Ras1ToRas2 DeepCopy [[Matrix($Matrix(activeID),node) GetTransform] GetMatrix]
        Ras1ToRas2 DeepCopy [Volume($v,node) GetRasToWld]
        # Now build Vtk1ToVtk2
        catch "Vtk1ToVtk2 Delete"    
        vtkMatrix4x4 Vtk1ToVtk2
        Vtk1ToVtk2 Identity
        Vtk1ToVtk2 Multiply4x4 Ras1ToRas2 RasToVtk  Vtk1ToVtk2
        Vtk1ToVtk2 Multiply4x4 InvRasToVtk  Vtk1ToVtk2 Vtk1ToVtk2
        
        # Get the origin, spacing and extent of the input volume
        catch "InVolume Delete"
        vtkImageData InVolume
        InVolume DeepCopy [Volume($v,vol) GetOutput]
        catch "ici Delete"    
        vtkImageChangeInformation ici
        ici CenterImageOn
        ici SetInput InVolume
        ici Update
        set volume [ici GetOutput]
        set inorigin [split [$volume GetOrigin]]
        set inwholeExtent [split [$volume GetWholeExtent]]
        set inspacing [split [$volume GetSpacing]]
        
        # Transforms the corners of the extent according to Vtk1ToVtk2
        # and finds the min/max coordinates in each dimension
        for {set i 0} {$i < 3} {incr i} {
            set bounds([expr 2 * $i]) 10000000
            set bounds([expr 2*$i+1])  -10000000
        }
        for {set i 0} {$i < 8} {incr i} {
            # setup the bounding box with origin and spacing
            set point(0) [expr [lindex $inorigin 0] + [expr [lindex $inwholeExtent [expr $i %  2]] * [lindex $inspacing 0] ]]
            set point(1) [expr [lindex $inorigin 1] + [expr [lindex $inwholeExtent [expr 2 + ($i / 2) % 2]] * [lindex $inspacing 1]]]
            set point(2) [expr [lindex $inorigin 2] + [expr [lindex $inwholeExtent [expr 4 + ($i / 4) % 2]] * [lindex $inspacing 2]]]
            # applies the transform 
            set newpoint [Vtk1ToVtk2 MultiplyPoint $point(0) $point(1) $point(2) 1]
            set point(0) [lindex $newpoint 0]
            set point(1) [lindex $newpoint 1]
            set point(2) [lindex $newpoint 2]
            # finds max/min in each dimension
            for {set j 0}  {$j < 3} {incr j} {
                if {$point($j) > $bounds([expr 2*$j+1])} {
                    set bounds([expr 2*$j+1]) $point($j)
                }
                if {$point($j) < $bounds([expr 2*$j])} {
                    set bounds([expr 2*$j]) $point($j)
                }
            }
        }
        
        # Transforms in RAS space
        set outspacing [InvRasToVtk MultiplyPoint $TransformVolume(OutputSpacingLR) $TransformVolume(OutputSpacingPA) $TransformVolume(OutputSpacingIS) 1]
        set spacing(0) [expr abs([lindex $outspacing 0])]
        set spacing(1) [expr abs([lindex $outspacing 1])]
        set spacing(2) [expr abs([lindex $outspacing 2])]
        # Compute the new extent
        for {set i 0} {$i < 3} {incr i} {
            set outExt($i) [expr round (( $bounds([expr 2*$i+1])- $bounds([expr 2 * $i])) / $spacing($i))] 
        }
        # Go back in RAS space 
        set outExtRAS [RasToVtk MultiplyPoint $outExt(0) $outExt(1) $outExt(2) 1]
        set TransformVolume(OutputDimensionLR) [expr 1 + round(abs([lindex $outExtRAS 0]))]
        set TransformVolume(OutputDimensionPA) [expr 1 + round(abs([lindex $outExtRAS 1]))]
        set TransformVolume(OutputDimensionIS) [expr 1 + round(abs([lindex $outExtRAS 2]))]
        
        InVolume Delete
        ici Delete
        ModelRasToVtk Delete
        Ras1ToRas2 Delete
        RasToVtk Delete
        InvRasToVtk Delete
        Vtk1ToVtk2 Delete

    }
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeInterpolationMode
# 
# .ARGS
# string mode defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeInterpolationMode {{mode ""}} {
    global TransformVolume

    if {$mode != ""} {
        set TransformVolume(InterpolationMode) $mode
    } else {
        set TransformVolume(InterpolationMode) [$TransformVolume(interpolationMode) get]
    }
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeAutoDimensionLR
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeAutoDimensionLR {} {
    global TransformVolume
    set tmpZ $TransformVolume(OutputDimensionPA)
    set tmpY $TransformVolume(OutputDimensionIS)
    TransformVolumeAutoDimension
    set TransformVolume(OutputDimensionPA) $tmpZ
    set TransformVolume(OutputDimensionIS) $tmpY
    TransformVolumeUpdatePreview
}  

#-------------------------------------------------------------------------------
# .PROC TransformVolumeAutoDimensionPA
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeAutoDimensionPA {} {
    global TransformVolume
    set tmpY $TransformVolume(OutputDimensionIS)
    set tmpX $TransformVolume(OutputDimensionLR)
    TransformVolumeAutoDimension
    set TransformVolume(OutputDimensionIS) $tmpY
    set TransformVolume(OutputDimensionLR) $tmpX
    TransformVolumeUpdatePreview
} 

#-------------------------------------------------------------------------------
# .PROC TransformVolumeAutoDimensionIS
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeAutoDimensionIS {} {
    global TransformVolume
    set tmpZ $TransformVolume(OutputDimensionPA)
    set tmpX $TransformVolume(OutputDimensionLR)
    TransformVolumeAutoDimension
    set TransformVolume(OutputDimensionPA) $tmpZ
    set TransformVolume(OutputDimensionLR) $tmpX
    TransformVolumeUpdatePreview   
} 

#-------------------------------------------------------------------------------
# .PROC TransformVolumeResultPrefix
#
# .ARGS
# string prefix defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeResultPrefix {{prefix ""}} {
    global TransformVolume
    if {$prefix != ""} {
        set TransformVolume(ResultPrefix) $prefix
    } else {
        set TransformVolume(ResultPrefix) [$TransformVolume(resultPrefix) get]
    }
}


#-------------------------------------------------------------------------------
# .PROC TransformVolumeOutputSpacingLR
#
# .ARGS
# float spacing defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOutputSpacingLR {{spacing ""} } {
    global TransformVolume
    
    if {$spacing != ""} {
        set TransformVolume(OutputSpacingLR) $spacing
    }
    
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeOutputSpacingPA
#
# .ARGS
# float spacing defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOutputSpacingPA {{spacing ""}} {
    global TransformVolume
    
    if {$spacing != ""} {
        set TransformVolume(OutputSpacingPA) $spacing
    }
    
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeOutputSpacingIS
#
# .ARGS
# float spacing defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOutputSpacingIS {{spacing ""} } {
    global TransformVolume

    if {$spacing != ""} {
        set TransformVolume(OutputSpacingIS) $spacing
    }
    
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeOutputDimensionLR
#
# .ARGS
# string dimension defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOutputDimensionLR {{dimension ""} } {
    global TransformVolume
    
    if {$dimension != ""} {
        set TransformVolume(OutputDimensionLR) $dimension
    }
    
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeOutputDimensionPA
#
# .ARGS
# string dimension defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOutputDimensionPA {{dimension ""}} {
    global TransformVolume
    
    if {$dimension != ""} {
        set TransformVolume(OutputDimensionPA) $dimension
    }
    
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeOutputDimensionIS
#
# .ARGS
# string dimension defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeOutputDimensionIS {{dimension ""} } {
    global TransformVolume

    if {$dimension != ""} {
        set TransformVolume(OutputDimensionIS) $dimension
    }
    
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumePermuteDimensions
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumePermuteDimensions {} {
    global TransformVolume

    switch $TransformVolume(OutputOrientation) {
        "RL" -
        "LR" {
            set dimI $TransformVolume(OutputDimensionPA)
            set dimJ $TransformVolume(OutputDimensionIS)
            set dimK $TransformVolume(OutputDimensionLR)
        }
        "PA" -
        "AP" {
            set dimI $TransformVolume(OutputDimensionLR)
            set dimJ $TransformVolume(OutputDimensionIS)
            set dimK $TransformVolume(OutputDimensionPA)
        }
        "SI" -
        "IS" {
            set dimI $TransformVolume(OutputDimensionLR)
            set dimJ $TransformVolume(OutputDimensionPA)
            set dimK $TransformVolume(OutputDimensionIS)
        }
        default {
            tk_messageBox -message "Unknown orientation: $TransformVolume(OutputOrientation)"
        }
    }
    set TransformVolume(OutputDimensionI) $dimI
    set TransformVolume(OutputDimensionJ) $dimJ
    set TransformVolume(OutputDimensionK) $dimK
}


#-------------------------------------------------------------------------------
# .PROC TransformVolumePermuteDimensions
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumePermuteIjkDimensions {} {
    global TransformVolume

    switch $TransformVolume(OutputOrientation) {
        "RL" -
        "LR" {
            set dimLR $TransformVolume(OutputDimensionK)
            set dimPA $TransformVolume(OutputDimensionI)
            set dimIS $TransformVolume(OutputDimensionJ)
        }
        "PA" -
        "AP" {
            set dimLR $TransformVolume(OutputDimensionI)
            set dimPA $TransformVolume(OutputDimensionK)
            set dimIS $TransformVolume(OutputDimensionJ)
        }
        "SI" -
        "IS" {
            set dimLR $TransformVolume(OutputDimensionI)
            set dimPA $TransformVolume(OutputDimensionJ)
            set dimIS $TransformVolume(OutputDimensionK)
        }
        default {
            tk_messageBox -message "Unknown orientation: $TransformVolume(OutputOrientation)"
        }
    }
    set TransformVolume(OutputDimensionLR) $dimLR
    set TransformVolume(OutputDimensionPA) $dimPA
    set TransformVolume(OutputDimensionIS) $dimIS
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumePermuteSpacing
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumePermuteSpacing {} {
    global TransformVolume

    switch $TransformVolume(OutputOrientation) {
        "RL" -
        "LR" {
            set spacingI $TransformVolume(OutputSpacingPA)
            set spacingJ $TransformVolume(OutputSpacingIS)
            set spacingK $TransformVolume(OutputSpacingLR)
        }
        "PA" -
        "AP" {
            set spacingI $TransformVolume(OutputSpacingLR)
            set spacingJ $TransformVolume(OutputSpacingIS)
            set spacingK $TransformVolume(OutputSpacingPA)
        }
        "SI" -
        "IS" {
            set spacingI $TransformVolume(OutputSpacingLR)
            set spacingJ $TransformVolume(OutputSpacingPA)
            set spacingK $TransformVolume(OutputSpacingIS)
        }
        default {
            tk_messageBox -message "Unknown orientation: $TransformVolume(OutputOrientation)"
        }
    }
    set TransformVolume(OutputSpacingI) $spacingI
    set TransformVolume(OutputSpacingJ) $spacingJ
    set TransformVolume(OutputSpacingK) $spacingK
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumePermuteSpacing
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumePermuteIjkSpacing {} {
    global TransformVolume

    switch $TransformVolume(OutputOrientation) {
        "RL" -
        "LR" {
            set spacingLR $TransformVolume(OutputSpacingK)
            set spacingPA $TransformVolume(OutputSpacingI)
            set spacingIS $TransformVolume(OutputSpacingJ)
        }
        "PA" -
        "AP" {
            set spacingLR $TransformVolume(OutputSpacingI)
            set spacingPA $TransformVolume(OutputSpacingK)
            set spacingIS $TransformVolume(OutputSpacingJ)
        }
        "SI" -
        "IS" {
            set spacingLR $TransformVolume(OutputSpacingI)
            set spacingPA $TransformVolume(OutputSpacingJ)
            set spacingIS $TransformVolume(OutputSpacingK)
        }
        default {
            tk_messageBox -message "Unknown orientation: $TransformVolume(OutputOrientation)"
        }
    }
    set TransformVolume(OutputSpacingLR) $spacingLR
    set TransformVolume(OutputSpacingPA) $spacingPA
    set TransformVolume(OutputSpacingIS) $spacingIS
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeCreatePreview
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeCreatePreview {} {
    global TransformVolume Gui

    catch ".isvolumepreview.isv pre_destroy"
    catch "destroy .isvolumepreview"
    
    set f .isvolumepreview
    toplevel $f
    wm title $f "isvolume preview"
    wm protocol $f WM_DELETE_WINDOW "TransformVolumeExitPreview"

    pack [isvolume .isvolumepreview.isv] -fill both -expand true
    
    set TransformVolume(isv) .isvolumepreview.isv
    set TransformVolume(wisv) $f
        
    TransformVolumeUpdatePreview
}

#-------------------------------------------------------------------------------
# .PROC TransformVolumeExitPreview
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TransformVolumeExitPreview {} {
    global TransformVolume Gui

    catch {$TransformVolume(isv) pre_destroy}
    catch {destroy $TransformVolume(wisv)}
    set TransformVolume(isv) ""
    set TransformVolume(wisv) ""
}

