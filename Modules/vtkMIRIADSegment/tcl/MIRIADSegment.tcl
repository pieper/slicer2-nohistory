#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MIRIADSegment.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.34 $
# 
#===============================================================================
# FILE:        MIRIADSegment.tcl
# PROCEDURES:  
#   MIRIADSegmentInit
#   MIRIADSegmentBuildGUI
#   MIRIADSegmentEnter
#   MIRIADSegmentExit
#   MIRIADSegmentProcessStudy archive BIRNID visit atlas
#   MIRIADSegmentLoadStudy archive BIRNID visit atlas
#   MIRIADSegmentSaveResults
#   MIRIADSegmentLoadDukeStudy  imtype
#   MIRIADSegmentLoadAtlas  dir
#   MIRIADSegmentCreateSPLWarpedAtlas 
#   MIRIADSegmentLoadSPLWarpedAtlas 
#   MIRIADSegmentLoadLONIWarpedAtlas  atlas labels
#   MIRIADSegmentSubTreeClassDefinition SuperClass
#   MIRIADSegmentSetEMParameters
#   MIRIADSegmentRunEM mode
#   MIRIADSegmentSamplesFromSegmentation class SEGid label
#   MIRIADSegmentClassPDFFromSegmentation
#   MIRIADSegmentGetVolumeByName  name
#   MIRIADSegmentGetVolumesByNamePattern pattern
#   MIRIADSegmentDeleteVolumeByName  name
#   MIRIADSegmentNormalizeImage  volid MaxValue
#   MIRIADSegmentLoadJHUAtlas
#   MIRIADSegmentBELLTest
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
# This module support BIRN MIRIAD project segmentations
# To find it when you run the Slicer, click on More->MIRIADSegment.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentInit {} {
    global MIRIADSegment Module Volume Model

    set m MIRIADSegment
    
    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "Perform Deidentification and Upload."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Steve Pieper, SPL, pieper@bwh.harvard.edu"
    set Module($m,category) "Segmentation"

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
    #   
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #
    set Module($m,row1List) "Help MIRIADSegment"
    set Module($m,row1Name) "{Help} {MIRIADSegment}"
    set Module($m,row1,tab) MIRIADSegment



    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources all *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #
    #   set Module($m,procVTK) MIRIADSegmentBuildVTK
    #
    #   All the options are:
    #
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
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) MIRIADSegmentBuildGUI
    set Module($m,procEnter) MIRIADSegmentEnter
    set Module($m,procExit) MIRIADSegmentExit

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
        {$Revision: 1.34 $} {$Date: 2006/01/06 17:57:56 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #

    set MIRIADSegment(status)  "okay"
    set MIRIADSegment(archive)  "gpop.bwh.harvard.edu:/nas/nas0/pieper/data/MIRIAD/Project_0002"
    set MIRIADSegment(subject_dir)  ""

    set tmpdirs {/state/partition1/pieper /usr/tmp /tmp}
    foreach tmpdir $tmpdirs {
        if { [file exists $tmpdir] } {
            set MIRIADSegment(tmpdir) $tmpdir
            break
        }
    }

    if { [file exists /usr/bin/rsync] } {
        set MIRIADSegment(rsync) /usr/bin/rsync
    } else {
        set MIRIADSegment(rsync) $::env(HOME)/birn/bin/rsync
    }

    if { [file exists $::env(HOME)/birn/data/atlas] } {
        set ::MIRIADSegment(splatlas) $::env(HOME)/birn/data/atlas
    } else {
        set ::MIRIADSegment(splatlas) $::env(HOME)/data/atlas
    }
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
# .PROC MIRIADSegmentBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentBuildGUI {} {
    global Gui MIRIADSegment Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "LDMM" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(MIRIADSegment,fLDMM)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # LDMM
    #   Top
    #   Middle
    #   Bottom
    #     FileLabel
    #     CountDemo
    #     TextBox
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The MIRIADSegment Module is used to invoke the EMSegment algoritm on MIRIAD data.
    <BR>
    <LI><B>CREDIT:</B> Steve Pieper, Neil Weisenfeld, Kilian Pohl and the Morphometry BIRN
    <BR>
    <LI><B>CREDIT:</B> See www.nbirn.net for BIRN details.
    <P>
    Description by tab:  This module has scripts that are primarily used in batch mode.
    <BR>
    <UL>
    <LI><B>MIRIADSegment:</B> 
    <BR>
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags MIRIADSegment $help
    MainHelpBuildGUI MIRIADSegment
    
# DDD1
    #-------------------------------------------
    # Deface frame
    #-------------------------------------------
    set fDeface $Module(MIRIADSegment,fMIRIADSegment)
    set f $fDeface
    # Frames
    frame $f.fActive -bg $Gui(backdrop) -relief sunken -bd 2 -height 20
    frame $f.fRange  -bg $Gui(activeWorkspace) -relief flat -bd 3

    pack $f.fActive -side top -pady $Gui(pad) -padx $Gui(pad)
    pack $f.fRange  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x



    #-------------------------------------------
    # Deface->Active frame
    #-------------------------------------------
    set f $fDeface.fActive

    eval {label $f.lActive -text "Active Volume: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Deface->Range frame
    #-------------------------------------------
    set f $fDeface.fRange

    eval {button $f.select -text "Load Atlas" -width 20 -command "MIRIADSegmentLoadSPLAtlas"} $Gui(WBA)
    
    pack $f.select -pady $Gui(pad) -side top -fill y -expand 1

# DDD2 
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentEnter
# Called when this module is entered by the user.  Place holder.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentEnter {} {
    global MIRIADSegment
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentExit
# Called when this module is exited by the user.   Place holder.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentExit {} {
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentProcessStudy
# 
# Main entry point for the Module
# Read the dicom data and the atlas for a subject, runs the segmentation and saves results
# .ARGS
# string archive defaults to default
# int BIRNID defaults to 000397921927
# int visit defaults to 001
# string atlas defaults to spl
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentProcessStudy { {archive "default"} {BIRNID "000397921927"} {visit 001} {atlas "spl"} } {

    set ::MIRIADSegment(version) reg_LONIbAb__params_params-sp-duke-2004-02-19_ic

    MIRIADSegmentLoadStudy $archive $BIRNID $visit $atlas

    if { $::MIRIADSegment(status) != "okay" } {
        puts "MIRIADSegment Failed"
        return
    }

    MIRIADParametersDefaults
    MIRIADParametersLoad $::env(SLICER_HOME)/Modules/vtkMIRIADSegment/data/params-sp-duke-2004-02-19

    MIRIADSegmentSetEMParameters
    MIRIADSegmentRunEM 

    if { $::MIRIADSegment(status) != "okay" } {
        puts "MIRIADSegment Failed"
        return
    }

    MIRIADSegmentSaveResults 

    if { $::MIRIADSegment(status) != "okay" } {
        puts "MIRIADSegment Failed"
        return
    }
    
    puts "MIRIADSegment Finished"
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentLoadStudy
# Read the dicom data and the atlas for a subject, runs the segmentation and saves results
# .ARGS
# string archive defaults to default
# int BIRNID defaults to 000397921927
# int visit defaults to 001
# string atlas defaults to spl
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentLoadStudy { {archive "default"} {BIRNID "000397921927"} {visit 001} {atlas "spl"} } {

    MainFileClose 

    if { $archive != "default" } {
        set ::MIRIADSegment(archive) $archive
    }

    #
    # first, make the local directory for the data if needed or use local dir
    # - a ":" in the archive string means it is a remote archive that needs to be rsync'd
    #
    if { [string first ":" $::MIRIADSegment(archive)] == -1 } {
        set ::MIRIADSegment(subject_dir) $::MIRIADSegment(archive)/$BIRNID/Visit_$visit/Study_0001
    } else {
        set ::MIRIADSegment(subject_dir) $::MIRIADSegment(tmpdir)/$BIRNID/Visit_$visit/Study_0001
        file mkdir $::MIRIADSegment(subject_dir)
        set ::MIRIADSegment(archive_dir) $::MIRIADSegment(archive)/${BIRNID}/Visit_$visit/Study_0001

        #
        # then, bring over the data with rsync 
        #
        puts "rsyncing..." ; update
        exec $::MIRIADSegment(rsync) -rz --rsh=ssh $::MIRIADSegment(archive_dir)/ $::MIRIADSegment(subject_dir)/
    }

    #
    # load up the data...
    #
    puts "loading raw..." ; update
    MIRIADSegmentLoadDukeStudy "corrected"

    #
    # either read the existing warped atlas, or create it
    #
    puts "loading atlas $atlas..." ; update
    switch $atlas {
        "loni" {
            MIRIADSegmentLoadLONIWarpedAtlas "bseANDbet" "full"
        }
        "spl" {
            if { [MIRIADSegmentLoadSPLWarpedAtlas] } {
                puts "creating atlas..." ; update
                MIRIADSegmentLoadSPLAtlas $::MIRIADSegment(splatlas) 
                MIRIADSegmentCreateSPLWarpedAtlas 
            }
        }
    }
    puts "done" ; update

}


#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentSaveResults
# Save the EM results
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentSaveResults { } {

    #
    # Save the label map, then the scene, then the volume by tissue class
    # Then copy results back to archive if needed
    #

    set SEGid [MIRIADSegmentGetVolumeByName "EMSegResult1"]
    set resultdir $::MIRIADSegment(subject_dir)/DerivedData/SPL/EM-$::MIRIADSegment(version)
    file mkdir $resultdir
    Volume($SEGid,node) SetFileType "Headerless"
    Volume($SEGid,node) SetFilePattern "%s.%d"
    MainVolumesWrite $SEGid $resultdir/EMSegResult

    set ::Mrml(dir) $resultdir 
    set ::File(filePrefix) AtlasAndSegmentation
    MainFileSaveAsApply

    MainVolumesSetActive $SEGid
    MeasureVolSelectVol
    set ::MeasureVol(fileName) $::MIRIADSegment(subject_dir)/DerivedData/SPL/EM-$::MIRIADSegment(version)/tissue_volumes.txt
    MeasureVolVolume "no_prompt"

    if { [string first ":" $::MIRIADSegment(archive)] != -1 } {
        puts "saving results to archive..." ; update
        exec $::MIRIADSegment(rsync) -rz --rsh=ssh $::MIRIADSegment(subject_dir)/ $::MIRIADSegment(archive_dir)/
    }

}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentLoadDukeStudy 
# Reads the bwh probability atlas
# .ARGS
# string imtype defaults to raw
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentLoadDukeStudy { {imtype "raw"} {subject_dir ""} } {

    MIRIADSegmentDeleteVolumeByName "T2"
    MIRIADSegmentDeleteVolumeByName "PD"

    if { $subject_dir == "" } {
        set subject_dir $::MIRIADSegment(subject_dir)
    }

    if { $imtype == "raw" } {
        set dir $subject_dir/RawData/001.ser
        set T2id [DICOMLoadStudy $dir *\[02468\].dcm]
        set PDid [DICOMLoadStudy $dir *\[13579\].dcm]
        Volume($T2id,node) SetName "T2"
        Volume($PDid,node) SetName "PD"
    } else {
        set dir $subject_dir/DerivedData/SPL/mri/kld/norm_rcon_1
        set ::Volume(VolAnalyze,FileName) $dir/t2_ic_ch1.hdr
        set ::Volume(name) "T2"
        VolAnalyzeApply
        set ::Volume(VolAnalyze,FileName) $dir/pd_ic_ch0.hdr
        set ::Volume(name) "PD"
        VolAnalyzeApply
    }

    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentLoadAtlas 
# Reads the bwh probability atlas
# .ARGS
# path dir defaults to choose
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentLoadSPLAtlas { {dir "choose"} } {

    if { $dir == "choose"} {
        set dir [tk_chooseDirectory]
        if { $dir == "" } {
            return
        }
    }

    set vols {
        case2/spgr/case2.001
        case2/t2w/case2.001
        sumbackground/I.001
        sumcsf/I.001
        sumgreymatter/I.001
        sumwhitematter/I.001
    }
        
    foreach vol $vols {
        set name atlas-[file tail [file dir $vol]]
        regsub -all "\\." $name "" name
        MIRIADSegmentDeleteVolumeByName $name
        MainUpdateMRML

        MainVolumesSetActive "NEW"
        set ::Volume(name) $name
        set ::Volume(desc) "SPL Atlas $vol"
        set ::Volume(firstFile) $dir/$vol
        set ::Volume(lastNum) 124
        set ::Volume(isDICOM) 0
        set ::Volume(width) 256
        set ::Volume(height) 256
        set ::Volume(pixelWidth) .9375
        set ::Volume(pixelHeight) .9375
        set ::Volume(sliceThickness) 1.5
        set ::Volume(sliceSpacing) 0
        set ::Volume(gantryDetectorTilt) 0
        set ::Volume(numScalars) 1
        set ::Volume(readHeaders) 0
        set ::Volume(labelMap) 0
        set ::Volume(scanOrder) "PA"
        set ::Volume(scalarType) "Short"
        VolumesPropsApply 
    }
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentCreateSPLWarpedAtlas 
# Make a bwh probability atlas as warped by vtkAG
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentCreateSPLWarpedAtlas {} {

    # 
    # require that duke data and bwh atlas are already loaded
    #
    set ::AG(InputVolTarget) [MIRIADSegmentGetVolumeByName "T2"]
    set ::AG(InputVolTarget2) [MIRIADSegmentGetVolumeByName "PD"]
    set ::AG(InputVolSource) [MIRIADSegmentGetVolumeByName "atlas-t2w"]
    set ::AG(InputVolSource2) [MIRIADSegmentGetVolumeByName "atlas-spgr"]
    # special flag to Create New output volume
    set ::AG(ResultVol) -5
    set ::AG(ResultVol2) -5

    #
    # perform the registration
    #
    RunAG

    #
    # apply the transform to each of the atlas volumes and save them
    #
    foreach vol [MIRIADSegmentGetVolumesByNamePattern atlas-sum*] {
        AGTransformOneVolume $vol $::AG(InputVolTarget)
    }
    
    # save the atlas and the warped image data
    set vols [MIRIADSegmentGetVolumesByNamePattern AGResult*]
    set vols [concat $vols [MIRIADSegmentGetVolumesByNamePattern resample_atlas*]]
    foreach vol $vols {
        set name [Volume($vol,node) GetName]
        set resultdir $::MIRIADSegment(subject_dir)/DerivedData/SPL/mri/atlases/bwh_prob/AG
        file mkdir $resultdir
        MainVolumesWrite $vol $resultdir/$name
    }
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentLoadSPLWarpedAtlas 
# Reads the bwh probability atlas as warped by SPL
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentLoadSPLWarpedAtlas { } {

    # TODO - don't load the atlas now - just create a new one
    return -1


    set resultsdir $::MIRIADSegment(subject_dir)/DerivedData/SPL/mri/atlases/bwh_prob/AG
    if { ![file exists $resultsdir] } {
        return -1
    }

    set all_vols {
        sumbackground.xml sumcsf.xml sumforeground.xml 
        sumgraymatter_amygdala.xml sumgraymatter_hippocampus.xml 
        sumgraymatter_parrahipp_normed.xml sumgraymatter_stg_normed.xml 
        sumgraymatter_substr.xml sumgreymatter_all.xml sumgreymatter.xml 
        sumlamygdala.xml sumlamygdala_normed.xml sumlAnterInsulaCortex.xml 
        sumlhippocampus.xml sumlhippocampus_normed.xml sumlInferiorTG.xml 
        sumlMiddleTG.xml sumlparrahipp.xml sumlparrahipp_normed.xml 
        sumlPostInsulaCortex.xml sumlstg.xml sumlstg_normed.xml 
        sumlTempLobe.xml sumlThalamus.xml sumramygdala.xml 
        sumramygdala_normed.xml sumrAnterInsulaCortex.xml 
        sumrhippocampus.xml sumrhippocampus_normed.xml 
        sumrInferiorTG.xml sumrMiddleTG.xml sumrparrahipp.xml 
        sumrparrahipp_normed.xml sumrPostInsulaCortex.xml sumrstg.xml 
        sumrstg_normed.xml sumrTempLobe.xml sumrThalamus.xml 
        sumwhitematter.xml
    }
    set four_vols {
        sumbackground.xml sumcsf.xml 
        sumwhitematter.xml sumgreymatter.xml 
    }
        
    foreach vol $four_vols {
        MainMrmlImport $resultsdir/$vol
    }
    RenderAll
    return 0
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentLoadLONIWarpedAtlas 
# Reads the bwh probability atlas as warped by LONI
# .ARGS
# string atlas defaults to bseANDbet
# string labels defaults to full
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentLoadLONIWarpedAtlas { { atlas "bseANDbet" } {labels "full"} } {


    switch $atlas {
        "bseANDbet" {
            set dir $::MIRIADSegment(subject_dir)/DerivedData/LONI/mri/atlases/bwh_prob/bseANDbet/air_252p
        }
        default {
            set dir $::MIRIADSegment(subject_dir)/DerivedData/LONI/mri/atlases/bwh_prob/air_252p
        }
    }

    set all_vols {
        sumbackground.hdr sumcsf.hdr sumforeground.hdr 
        sumgraymatter_amygdala.hdr sumgraymatter_hippocampus.hdr 
        sumgraymatter_parrahipp_normed.hdr sumgraymatter_stg_normed.hdr 
        sumgraymatter_substr.hdr sumgreymatter_all.hdr sumgreymatter.hdr 
        sumlamygdala.hdr sumlamygdala_normed.hdr sumlAnterInsulaCortex.hdr 
        sumlhippocampus.hdr sumlhippocampus_normed.hdr sumlInferiorTG.hdr 
        sumlMiddleTG.hdr sumlparrahipp.hdr sumlparrahipp_normed.hdr 
        sumlPostInsulaCortex.hdr sumlstg.hdr sumlstg_normed.hdr 
        sumlTempLobe.hdr sumlThalamus.hdr sumramygdala.hdr 
        sumramygdala_normed.hdr sumrAnterInsulaCortex.hdr 
        sumrhippocampus.hdr sumrhippocampus_normed.hdr 
        sumrInferiorTG.hdr sumrMiddleTG.hdr sumrparrahipp.hdr 
        sumrparrahipp_normed.hdr sumrPostInsulaCortex.hdr sumrstg.hdr 
        sumrstg_normed.hdr sumrTempLobe.hdr sumrThalamus.hdr 
        sumwhitematter.hdr
    }
    set full_vols {
        sumbackground.hdr 
        sumcsf.hdr 
        sumgreymatter_all.hdr 
        sumwhitematter.hdr
        
        sumlamygdala.hdr 
        sumlAnterInsulaCortex.hdr 
        sumlhippocampus.hdr 
        sumlInferiorTG.hdr 
        sumlMiddleTG.hdr 
        sumlparrahipp.hdr 
        sumlPostInsulaCortex.hdr 
        sumlstg.hdr 
        sumlTempLobe.hdr 
        sumlThalamus.hdr 

        sumramygdala.hdr 
        sumrAnterInsulaCortex.hdr 
        sumrhippocampus.hdr 
        sumrInferiorTG.hdr 
        sumrMiddleTG.hdr 
        sumrparrahipp.hdr 
        sumrPostInsulaCortex.hdr 
        sumrstg.hdr 
        sumrTempLobe.hdr 
        sumrThalamus.hdr 

    }
    set four_vols {
        sumbackground.hdr sumcsf.hdr 
        sumwhitematter.hdr sumgreymatter.hdr 
    }

    switch $labels {
        "full" {
            set vols $full_vols
        }
        "four" {
            set vols $four_vols
        }
        default {
            set ::MIRIADSegment(status) "error: bad number of labels $labels"
            return -1
        }
    }

    if { ! [file exists $dir/[lindex $vols 0]] } {
        puts "LONI atlas doesn't exist for $dir"
        set ::MIRIADSegment(status) "error: LONI atlas doesn't exist for $dir"
        return -1
    }
        
    foreach vol $vols {
        set name resample_atlas-[file root $vol]
        MIRIADSegmentDeleteVolumeByName $name
        MainVolumesSetActive "NEW"
        set ::Volume(VolAnalyze,FileName) $dir/$vol
        set ::Volume(name) $name
        set i [VolAnalyzeApply]
        MIRIADSegmentNormalizeImage $i 82
    }
    RenderAll
    return 0
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentSubTreeClassDefinition
# Recursive proc to setup subtrees based on globally set parameters 
# .ARGS
# string SuperClass
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentSubTreeClassDefinition {SuperClass} {

    EMSegmentChangeSuperClass $SuperClass 0  ;# select this superclass

    # set values for each of the subclasses using info from global arrays
    foreach \
        class $::EMSegment(Cattrib,$::EMSegment(SuperClass),ClassList) \
        probvol $::MIRIADSegment(probvols,$SuperClass) \
        lmean $::MIRIADSegment(logmeans,$SuperClass) \
        lcov $::MIRIADSegment(logcovs,$SuperClass) {
            EMSegmentChangeClass $class
            if {$::EMSegment(Cattrib,$class,IsSuperClass)} { 
                # set dummy values so we pass the error check
                for {set y 0} {$y < $::EMSegment(NumInputChannel)} {incr y} {
                    set ::EMSegment(Cattrib,$class,LogMean,$y) 1
                    for {set x 0} {$x < $::EMSegment(NumInputChannel)} {incr x} {
                        if { $x == $y } {
                            set ::EMSegment(Cattrib,$class,LogCovariance,$y,$x)  1
                        } else {
                            set ::EMSegment(Cattrib,$class,LogCovariance,$y,$x)  0
                        }
                    }
                }
                # define the real values through the subclass
                MIRIADSegmentSubTreeClassDefinition $class ;# recursive call to this proc
            } else {
                if { $probvol != "none" } {
                    set ::EMSegment(ProbVolumeSelect) [MIRIADSegmentGetVolumeByName $probvol]   
                    EMSegmentProbVolumeSelectNode \
                        Volume [MIRIADSegmentGetVolumeByName $probvol] \
                        EMSegment EM-ProbVolumeSelect ProbVolumeSelect
                }

                set index 0
                for {set y 0} {$y < $::EMSegment(NumInputChannel)} {incr y} {
                    set ::EMSegment(Cattrib,$class,LogMean,$y) [lindex $lmean $y]
                    for {set x 0} {$x < $::EMSegment(NumInputChannel)} {incr x} {
                        set ::EMSegment(Cattrib,$class,LogCovariance,$y,$x)  [lindex $lcov $index]
                        incr index
                    }
                }
            }
    }
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentSetEMParameters
# Define the parameters for the segmentation
# - this method interacts a bit with the GUI -- this ensures that 
# all the right variables get set by the callbacks
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentSetEMParameters { } {

    # error if no private segment
    if { [catch "package require vtkEMPrivateSegment"] } {
        DevErrorWindow "Must have the Private Segment module"
        return
    }

    upvar #0 MIRIADParameters mp  ;# for typing simplicity and readability


    set ::EMSegment(DebugVolume) 1

    #
    # pick the PD and T2 volumes as the seg channels
    #
    $::EMSegment(fAllVolList) selection clear 0 end
    for {set i 0} {$i < [$::EMSegment(fAllVolList) size]} {incr i} {
        if { [$::EMSegment(fAllVolList) get $i] == "PD" } {
            $::EMSegment(fAllVolList) selection set $i
            set ::EMSegment(AllVolList,ActiveID) $i
            EMSegmentTransfereVolume All
            break
        }
    }
    $::EMSegment(fAllVolList) selection clear 0 end
    for {set i 0} {$i < [$::EMSegment(fAllVolList) size]} {incr i} {
        if { [$::EMSegment(fAllVolList) get $i] == "T2" } {
            $::EMSegment(fAllVolList) selection set $i
            set ::EMSegment(AllVolList,ActiveID) $i
            EMSegmentTransfereVolume All
            break
        }
    }

    #
    # set the global parameters
    #
    # Tree is HEAD (0)
    #         |-> AIR (1)
    #         |-> Tissue (2) (non brain, so skull, muscles, fat...)
    #         |-> BRAIN (3)
    #             |-> CSF (4)
    #             |-> Gray (5)
    #                 |-> OtherGray (9)
    #                 |-> lr Amygdala (10,11)
    #                 |-> lr AnteriorInsulaCortex (12 13)
    #                 |-> lr Hippocampus (14 15)
    #                 |-> lr InferiorTemporalGyrus (16 17)
    #                 |-> lr MiddleTemporalGyrus (18 19)
    #                 |-> lr Parahippocampus (20 21)
    #                 |-> lr PosteriorInsulaCortex (22 23)
    #                 |-> lr SuperiorTemporalGyrus (24 25)
    #                 |-> lr TemporalLobe (26 27)
    #                 |-> lr Thalamus (28 29)
    #             |-> White (6)
    #                 |-> WMNormal (7)
    #                 |-> WMLesion (8)


    # -------------------------------
    # SUPERCLASS: HEAD
    EMSegmentChangeClass 0
    set ::EMSegment(NumClassesNew) 3
    EMSegmentCreateDeleteClasses 1 1 0
    EMSegmentClickLabel 0 1 0 ""
    # class Air 
    set ::EMSegment(Cattrib,1,Name) Air 
    set ::EMSegment(Cattrib,1,Prob) $mp(Air,prob)
    set ::EMSegment(Cattrib,1,LocalPriorWeight) $mp(Air,ProbDataWeight)
    set ::EMSegment(Cattrib,1,InputChannelWeights,0) $mp(Air,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,1,InputChannelWeights,1) $mp(Air,InputChannelWeight,T2)
    EMSegmentClickLabel 1 1 1 ""
    # class Tissue
    set ::EMSegment(Cattrib,2,Name) Tissue 
    set ::EMSegment(Cattrib,2,Prob) $mp(OtherTissue,prob)
    set ::EMSegment(Cattrib,2,LocalPriorWeight) $mp(OtherTissue,ProbDataWeight)
    set ::EMSegment(Cattrib,2,InputChannelWeights,0) $mp(OtherTissue,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,2,InputChannelWeights,1) $mp(OtherTissue,InputChannelWeight,T2)
    EMSegmentClickLabel 2 1 2 ""

    # -------------------------------
    # SUPERCLASS: BRAIN
    # a.) Define general parameter
    set ::EMSegment(Cattrib,3,Name) BRAIN 
    set ::EMSegment(Cattrib,3,Prob) .50
    EMSegmentClickLabel 3 1 3 ""
    EMSegmentSumGlobalUpdate                  ;# Update SuperClass before it is set to BRAIN

    # b.) Define SuperClass parameters
    EMSegmentChangeClass 3                    ;# Set Active Class
    set ::EMSegment(Cattrib,3,IsSuperClass) 1
    EMSegmentTransfereClassType 1 1           ;# Transfer ClassType to Superclass
    # c.) Create subclasses 
    set ::EMSegment(NumClassesNew) 3      
    EMSegmentCreateDeleteClasses 1 1 0          ;# 1. Parameter = ChangeGui; 
                                              ;# 2. Parameter =  DeleteNode  
    # d.) Define CIM if necessary
    # foreach Name $EMSegment(CIMList) {
    #    set EMSegment(Cattrib,3,CIMMatrix,$i,$y,$Name) 0.0
    # }


    # -------------------------------

    # CSF
    set ::EMSegment(Cattrib,4,Name) CSF 
    set ::EMSegment(Cattrib,4,Prob) $mp(CSF,prob)
    set ::EMSegment(Cattrib,4,LocalPriorWeight) $mp(CSF,ProbDataWeight)
    set ::EMSegment(Cattrib,4,InputChannelWeights,0) $mp(CSF,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,4,InputChannelWeights,1) $mp(CSF,InputChannelWeight,T2)
    EMSegmentClickLabel 4 1 4 ""
    # GM 
    set ::EMSegment(Cattrib,5,Name) GrayMatter 
    EMSegmentClickLabel 5 1 5 ""

    # -------------------------------
    # SUPERCLASS: WM
    set ::EMSegment(Cattrib,6,Name) WhiteMatter 
    EMSegmentClickLabel 6 1 6 ""

    EMSegmentSumGlobalUpdate                  
    # b.) Define SuperClass parameters
    EMSegmentChangeClass 6                    ;# Set Active Class
    set ::EMSegment(Cattrib,6,IsSuperClass) 1
    EMSegmentTransfereClassType 1 1           ;# Transfer ClassType to Superclass
    set ::EMSegment(Cattrib,6,Prob) $mp(NormalWhiteMatter,prob)
    set ::EMSegment(Cattrib,6,LocalPriorWeight) $mp(NormalWhiteMatter,ProbDataWeight)
    set ::EMSegment(Cattrib,6,InputChannelWeights,0) $mp(NormalWhiteMatter,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,6,InputChannelWeights,1) $mp(NormalWhiteMatter,InputChannelWeight,T2)
    # c.) Create subclasses 
    set ::EMSegment(NumClassesNew) 2      
    EMSegmentCreateDeleteClasses 1 1   0        ;# 1. Parameter = ChangeGui; 
                                              ;# 2. Parameter =  DeleteNode  
    
    # WMNormal 
    set ::EMSegment(Cattrib,7,Name) WMNormal 
    set ::EMSegment(Cattrib,7,Prob) $mp(NormalWhiteMatter,prob)
    set ::EMSegment(Cattrib,7,LocalPriorWeight) $mp(NormalWhiteMatter,ProbDataWeight)
    set ::EMSegment(Cattrib,7,InputChannelWeights,0) $mp(NormalWhiteMatter,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,7,InputChannelWeights,1) $mp(NormalWhiteMatter,InputChannelWeight,T2)
    EMSegmentClickLabel 7 1 7 ""
    # WMLesion 
    set ::EMSegment(Cattrib,8,Name) WMLesion 
    set ::EMSegment(Cattrib,8,Prob) $mp(LesionedWhiteMatter,prob)
    set ::EMSegment(Cattrib,8,LocalPriorWeight) $mp(LesionedWhiteMatter,ProbDataWeight)
    set ::EMSegment(Cattrib,8,InputChannelWeights,0) $mp(LesionedWhiteMatter,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,8,InputChannelWeights,1) $mp(LesionedWhiteMatter,InputChannelWeight,T2)
    EMSegmentClickLabel 8 1 8 ""


    ## GM subclasses
    EMSegmentSumGlobalUpdate                  
    # b.) Define SuperClass parameters
    EMSegmentChangeClass 5                    ;# Set Active Class
    set ::EMSegment(Cattrib,5,IsSuperClass) 1
    EMSegmentTransfereClassType 1 1           ;# Transfer ClassType to Superclass
    set ::EMSegment(Cattrib,5,Prob) $mp(CorticalGrayMatter,prob)
    set ::EMSegment(Cattrib,5,LocalPriorWeight) 0.05 ;# $mp(CorticalGrayMatter,ProbDataWeight)
    set ::EMSegment(Cattrib,5,InputChannelWeights,0) $mp(CorticalGrayMatter,InputChannelWeight,PD)
    set ::EMSegment(Cattrib,5,InputChannelWeights,1) $mp(CorticalGrayMatter,InputChannelWeight,T2)


    # c.) Create subclasses 
    set ::EMSegment(NumClassesNew) 21
    EMSegmentCreateDeleteClasses 1 1  0         ;# 1. Parameter = ChangeGui; 

    set grayparcels {
        OtherGray 
        LAmygdala RAmygdala 
        LAnteriorInsulaCortex RAnteriorInsulaCortex
        LHippocampus RHippocampus
        LInferiorTemporalGyrus RInferiorTemporalGyrus
        LMiddleTemporalGyrus RMiddleTemporalGyrus
        LParahippocampus RParahippocampus
        LPosteriorInsulaCortex RPosteriorInsulaCortex
        LSuperiorTemporalGyrus RSuperiorTemporalGyrus
        LTemporalLobe RTemporalLobe
        LThalamus RThalamus
    }
    set cortprob [expr $mp(CorticalGrayMatter,prob) / 13.]
    set subcortprob [expr $mp(SubCorticalGrayMatter,prob) / 8.]
    set l 9
    foreach gp $grayparcels {
        set ::EMSegment(Cattrib,$l,Name) $gp
        if { [MIRIADParametersGrayType $gp] == "cortical" } {
            set ::EMSegment(Cattrib,$l,Prob) $cortprob
            set ::EMSegment(Cattrib,$l,LocalPriorWeight) $mp(CorticalGrayMatter,ProbDataWeight)
            set ::EMSegment(Cattrib,$l,InputChannelWeights,0) $mp(CorticalGrayMatter,InputChannelWeight,PD)
            set ::EMSegment(Cattrib,$l,InputChannelWeights,1) $mp(CorticalGrayMatter,InputChannelWeight,T2)
        } else {
            set ::EMSegment(Cattrib,$l,Prob) $subcortprob
            set ::EMSegment(Cattrib,$l,LocalPriorWeight) $mp(SubCorticalGrayMatter,ProbDataWeight)
            set ::EMSegment(Cattrib,$l,InputChannelWeights,0) $mp(SubCorticalGrayMatter,InputChannelWeight,PD)
            set ::EMSegment(Cattrib,$l,InputChannelWeights,1) $mp(SubCorticalGrayMatter,InputChannelWeight,T2)
        }
        EMSegmentClickLabel $l 1 $l ""
        incr l
    }


    #
    # set the per-class parameters: class, atlas vol, mean, and covariance
    #

    # ---------------------------------------------------------------------------------
    # Define parameters for children of HEAD
    # Air, Tissue, Brain
    set ::MIRIADSegment(probvols,0) "resample_atlas-sumbackground resample_atlas-sumbackground none" 

    set ::MIRIADSegment(logmeans,0) [list \
        "$mp(Air,logmeans,PD) $mp(Air,logmeans,T2)" \
        "$mp(OtherTissue,logmeans,PD) $mp(OtherTissue,logmeans,T2)" \
        {"not used"} ]
    set ::MIRIADSegment(logcovs,0) [list \
        "$mp(Air,logcov,PD) $mp(Air,logcov,cross) $mp(Air,logcov,cross) $mp(Air,logcov,T2)" \
        "$mp(OtherTissue,logcov,PD) $mp(OtherTissue,logcov,cross) $mp(OtherTissue,logcov,cross) $mp(OtherTissue,logcov,T2)" \
        {"not used"} ]

    # ---------------------------------------------------------------------------------
    # Define parameters for children of BRAIN
    # CSF WM GM
    set ::MIRIADSegment(probvols,3) "resample_atlas-sumcsf resample_atlas-sumgreymatter_all resample_atlas-sumwhitematter"

    set ::MIRIADSegment(logmeans,3) [list \
        "$mp(CSF,logmeans,PD) $mp(CSF,logmeans,T2)" \
        "$mp(NormalWhiteMatter,logmeans,PD) $mp(NormalWhiteMatter,logmeans,T2)" \
        "$mp(CorticalGrayMatter,logmeans,PD) $mp(CorticalGrayMatter,logmeans,T2)" ]
    set ::MIRIADSegment(logcovs,3) [list \
        "$mp(CSF,logcov,PD) $mp(CSF,logcov,cross) $mp(CSF,logcov,cross) $mp(CSF,logcov,T2)" \
        "$mp(NormalWhiteMatter,logcov,PD) $mp(NormalWhiteMatter,logcov,cross) $mp(NormalWhiteMatter,logcov,cross) $mp(NormalWhiteMatter,logcov,T2)" \
        "$mp(CorticalGrayMatter,logcov,PD) $mp(CorticalGrayMatter,logcov,cross) $mp(CorticalGrayMatter,logcov,cross) $mp(CorticalGrayMatter,logcov,T2)" ]

    # ---------------------------------------------------------------------------------
    # Define parameters for children of GM
    # OtherGray, LAmygdala...
    set ::MIRIADSegment(probvols,5) {
        resample_atlas-sumgreymatter_all
        resample_atlas-sumlamygdala
        resample_atlas-sumramygdala
        resample_atlas-sumlAnterInsulaCortex
        resample_atlas-sumrAnterInsulaCortex
        resample_atlas-sumlhippocampus
        resample_atlas-sumrhippocampus
        resample_atlas-sumlInferiorTG
        resample_atlas-sumrInferiorTG
        resample_atlas-sumlMiddleTG
        resample_atlas-sumrMiddleTG
        resample_atlas-sumlparrahipp
        resample_atlas-sumrparrahipp
        resample_atlas-sumlPostInsulaCortex
        resample_atlas-sumrPostInsulaCortex
        resample_atlas-sumlstg
        resample_atlas-sumrstg
        resample_atlas-sumlTempLobe
        resample_atlas-sumrTempLobe
        resample_atlas-sumlThalamus
        resample_atlas-sumrThalamus
    }

    # TODO - get all the intensity values correct
    set ::MIRIADSegment(logmeans,5) {}
    set ::MIRIADSegment(logcovs,5) {}
    # loop through the gray parcels -- they are in the same order as the probvol list
    foreach gp $grayparcels { 
        if { [MIRIADParametersGrayType $gp] == "cortical" } {
            lappend ::MIRIADSegment(logmeans,5) "$mp(CorticalGrayMatter,logmeans,PD) $mp(CorticalGrayMatter,logmeans,T2)"
            lappend ::MIRIADSegment(logcovs,5) "$mp(CorticalGrayMatter,logcov,PD) $mp(CorticalGrayMatter,logcov,cross) $mp(CorticalGrayMatter,logcov,cross) $mp(CorticalGrayMatter,logcov,T2)"
        } else {
            lappend ::MIRIADSegment(logmeans,5) "$mp(SubCorticalGrayMatter,logmeans,PD) $mp(SubCorticalGrayMatter,logmeans,T2)"
            lappend ::MIRIADSegment(logcovs,5) "$mp(SubCorticalGrayMatter,logcov,PD) $mp(SubCorticalGrayMatter,logcov,cross) $mp(SubCorticalGrayMatter,logcov,cross) $mp(SubCorticalGrayMatter,logcov,T2)"
        }
    }

    # ---------------------------------------------------------------------------------
    # Define parameters for children of WM
    # WMNormal WMLesion
    set ::MIRIADSegment(probvols,6) "resample_atlas-sumwhitematter resample_atlas-sumwhitematter"
    set ::MIRIADSegment(logmeans,6) [list \
        "$mp(NormalWhiteMatter,logmeans,PD) $mp(NormalWhiteMatter,logmeans,T2)" \
        "$mp(LesionedWhiteMatter,logmeans,PD) $mp(LesionedWhiteMatter,logmeans,T2)" ]
    set ::MIRIADSegment(logcovs,6) [list \
        "$mp(NormalWhiteMatter,logcov,PD) $mp(NormalWhiteMatter,logcov,cross) $mp(NormalWhiteMatter,logcov,cross) $mp(NormalWhiteMatter,logcov,T2)" \
        "$mp(LesionedWhiteMatter,logcov,PD) $mp(LesionedWhiteMatter,logcov,cross) $mp(LesionedWhiteMatter,logcov,cross) $mp(LesionedWhiteMatter,logcov,T2)" ]

    EMSegmentChangeSuperClass 0 1 ;# change gui to show HEAD node

    MIRIADSegmentSubTreeClassDefinition 0 ;# call the recursive operation to set values
    

}



#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentRunEM
# Run the EM algorithm on the loaded data
# - mimic user actions
# .ARGS
# string mode defaults to full
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentRunEM { {mode "full"} } {

    if { $mode == "full" } {
        set ::EMSegment(SegmentationBoundaryMin,0) 1
        set ::EMSegment(SegmentationBoundaryMin,1) 1
        set ::EMSegment(SegmentationBoundaryMin,2) 1
        set ::EMSegment(SegmentationBoundaryMax,0) 256
        set ::EMSegment(SegmentationBoundaryMax,1) 256
        set t2 [MIRIADSegmentGetVolumeByName "T2"]
        set end [lindex [Volume($t2,node) GetImageRange] 1]
        set ::EMSegment(SegmentationBoundaryMax,2) $end
        set ::EMSegment(EMiteration) 5
        set ::EMSegment(MFAiteration) 2
    } else {
        # preview mode
        upvar #0 MIRIADParameters mp  ;# for typing simplicity and readability
        set ::EMSegment(SegmentationBoundaryMin,0) 1
        set ::EMSegment(SegmentationBoundaryMin,1) 1
        set ::EMSegment(SegmentationBoundaryMin,2) [expr 1+$mp(previewslice)]
        set ::EMSegment(SegmentationBoundaryMax,0) 128
        set ::EMSegment(SegmentationBoundaryMax,1) 256
        set ::EMSegment(SegmentationBoundaryMax,2) [expr 1+$mp(previewslice)]
        set ::EMSegment(EMiteration) 5
        set ::EMSegment(MFAiteration) 2
    }


    set ::EMSegment(Alpha) 0.5


    EMSegmentSumGlobalUpdate

    EMSegmentExecute "EM" "Run" "do_not_save"

    puts "[clock format [clock seconds]] done"
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentSamplesFromSegmentation
# Use a segmentation volume to define the samples for the EM starting point
# .ARGS
# string class
# int SEGid
# string label
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentSamplesFromSegmentation {class SEGid label} {

    set T2id [MIRIADSegmentGetVolumeByName "T2"]
    set PDid [MIRIADSegmentGetVolumeByName "PD"]
    set T2image [Volume($T2id,vol) GetOutput]
    set PDimage [Volume($PDid,vol) GetOutput]
    set SEGimage [Volume($SEGid,vol) GetOutput]

    set ::EMSegment(Cattrib,$class,$T2id,Sample) ""
    set ::EMSegment(Cattrib,$class,$PDid,Sample) ""

    set dims [[Volume($T2id,vol) GetOutput] GetDimensions]
    set xsize [lindex $dims 0]
    set ysize [lindex $dims 1]
    set zsize [lindex $dims 2]

    for {set z 0} {$z < $zsize} {incr z} {
        set z 30
        for {set y 0} {$y < $ysize} {incr y} {
            set y 128
            for {set x 0} {$x < $xsize} {incr x} {
                if { $label == [$SEGimage $::getScalarComponentAs $x $y $z 0] } {
                    set sample [$T2image $::getScalarComponentAs $x $y $z 0]
                    lappend ::EMSegment(Cattrib,$class,$T2id,Sample) [list $x $y $z $sample]
                    set sample [$PDimage $::getScalarComponentAs $x $y $z 0]
                    lappend ::EMSegment(Cattrib,$class,$PDid,Sample) [list $x $y $z $sample]
                }
            }
            return
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentClassPDFFromSegmentation
# Recalculate class Mean and Covariance from segmentations
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentClassPDFFromSegmentation {} {


    MIRIADSegmentSamplesFromSegmentation  1 [MIRIADSegmentGetVolumeByName handsef] 0
    MIRIADSegmentSamplesFromSegmentation  4 [MIRIADSegmentGetVolumeByName handsef] 4
    MIRIADSegmentSamplesFromSegmentation  5 [MIRIADSegmentGetVolumeByName handsef] 5
    MIRIADSegmentSamplesFromSegmentation  6 [MIRIADSegmentGetVolumeByName handsef] 6



    set classes "1 4 5 6" 
    set logmeans ""
    set logcovs ""
    foreach class $classes {
        set lmean ""
        set lcov ""
        
        EMSegmentChangeClass $class                    ;# Set Active Class
        set ::EMSegment(UseSamples) 1
        EMSegmentUseSamples 1
        for {set y 0} {$y < $::EMSegment(NumInputChannel)} {incr y} {
            lappend lmean $::EMSegment(Cattrib,$class,LogMean,$y) 
            for {set x 0} {$x < $::EMSegment(NumInputChannel)} {incr x} {
                lappend lcov $::EMSegment(Cattrib,$class,LogCovariance,$y,$x)
            }
        }
        lappend logmeans $lmean
        lappend logcovs $lcov
        set ::EMSegment(UseSamples) 0
        EMSegmentUseSamples 1
    }

    puts "set logmeans $logmeans"
    puts "set logcovs $logcovs"
}


#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentGetVolumeByName 
# returns the id of first match for a name
# .ARGS
# string name
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentGetVolumeByName {name} {

    set nvols [Mrml(dataTree) GetNumberOfVolumes]
    for {set vv 0} {$vv < $nvols} {incr vv} {
        set n [Mrml(dataTree) GetNthVolume $vv]
        if { $name == [$n GetName] } {
            return [DataGetIdFromNode $n]
        }
    }
    # Steve Change it - otherwise I get errors bc there is no volume with ID -1 but ID = 0 => none Volume  
    # return -1
    return $::Volume(idNone)
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentGetVolumesByNamePattern
# returns a list of IDs for a given pattern
# .ARGS
# string pattern
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentGetVolumesByNamePattern {pattern} {

    set ids ""
    set nvols [Mrml(dataTree) GetNumberOfVolumes]
    for {set vv 0} {$vv < $nvols} {incr vv} {
        set n [Mrml(dataTree) GetNthVolume $vv]
        if { [string match $pattern [$n GetName]] } {
            lappend ids [DataGetIdFromNode $n]
        }
    }
    return $ids
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentDeleteVolumeByName 
# clean up volumes before reloading them
# .ARGS
# string name
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentDeleteVolumeByName {name} {

    set nvols [Mrml(dataTree) GetNumberOfVolumes]
    for {set vv 0} {$vv < $nvols} {incr vv} {
        set n [Mrml(dataTree) GetNthVolume $vv]
        if { $name == [$n GetName] } {
            set id [DataGetIdFromNode $n]
            global Volume
            MainMrmlDeleteNode Volume $id
            break
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentNormalizeImage 
# Rescale the image data to the correct atlas range
# (assumes that the max value actually occurs in the image somewhere)
# .ARGS
# int volid
# float MaxValue
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentNormalizeImage {volid MaxValue} { 
    catch "Accu Delete"
    catch "NormImg Delete"
    vtkImageAccumulate Accu
    Accu SetInput [Volume($volid,vol) GetOutput]
    Accu Update
    set MaxImage [lindex [Accu GetMax] 0]
    puts "Normalize [Volume($volid,node) GetName]: max Volume Value = $MaxImage, max Predefined Value = $MaxValue"  
    if {$MaxImage ==  $MaxValue} {
        return
    }

    # 1. Normailze Image
    vtkImageMathematics NormImg
    NormImg SetInput1 [Volume($volid,vol) GetOutput]
    NormImg SetOperationToMultiplyByK
    set value [expr $MaxValue / double($MaxImage)]
    # 1. find out last digit
    set i 0
    while {[expr (double(int($value / pow(10.0,$i)))) > 0] } {
        incr i
    }
    # 2. Add to value 
    # - have to do it otherwise rounding error produce value MaxValue -1
    set i [expr -1*($::tcl_precision - $i)]
    while {[expr $value*$MaxImage] <=  $MaxValue} {
        set value [expr $value + pow(10.0,$i)]
    }
    NormImg SetConstantK $value
    NormImg SetInput1 [Volume($volid,vol) GetOutput]
    NormImg Update  
    set imdata [[NormImg GetOutput] NewInstance]
    $imdata DeepCopy [NormImg GetOutput]
    Volume($volid,vol) SetImageData $imdata

    NormImg Delete
    Accu Delete
}

#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentLoadJHUAtlas
# Load the JHU white matter atlas 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentLoadJHUAtlas {} { 

    MIRIADSegmentDeleteVolumeByName "JHU-atlas-MPRAGE"
    set ::Volume(labelMap) 0
    set ::Volume(name) "JHU-atlas-MPRAGE"
    set ::Volume(VolNrrd,FileName) $::env(HOME)/data/susumu-dti/atlas/JHU_mprage55.nhdr
    VolNrrdApply

    MIRIADSegmentDeleteVolumeByName "JHU-atlas-labels"
    set ::Volume(labelMap) 1
    set ::Volume(name) "JHU-atlas-labels"
    set ::Volume(VolNrrd,FileName) $::env(HOME)/data/susumu-dti/atlas/JHUWhiteMatterSeg.nhdr
    VolNrrdApply

}


#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentBELLTest
# Test for BIRN Effort to Localize Lesions
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentBELLTest {} { 

    MIRIADSegmentLoadJHUAtlas 

    MIRIADSegmentLoadSPLAtlas $::env(HOME)/bwh/data/atlas

    MIRIADSegmentLoadDukeStudy "raw" $::env(HOME)/data/MIRIAD/Project_0002/000362391770/Visit_001/Study_0001/



}
