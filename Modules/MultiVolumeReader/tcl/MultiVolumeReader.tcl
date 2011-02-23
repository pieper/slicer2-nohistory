#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MultiVolumeReader.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:07 $
#   Version:   $Revision: 1.24 $
# 
#===============================================================================
# FILE:        MultiVolumeReader.tcl
# PROCEDURES:  
#   MultiVolumeReaderInit
#   MultiVolumeReaderBuildGUI  parent status
#   fMRIEngineHelpLoadSequence
#   MultiVolumeReaderUpdateVolume volumeNo
#   MultiVolumeReaderSetWindowLevelThresholds 
#   MultiVolumeReaderSetFileFilter 
#   MultiVolumeReaderLoad  status
#   MultiVolumeReaderGetFilelistFromFilter  extension
#   MultiVolumeReaderLoadAnalyze 
#   MultiVolumeReaderLoadBXH 
#   MultiVolumeReaderLoadDICOM 
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderInit {} { 
    global MultiVolumeReader Module Volume Model env
    
    set m MultiVolumeReader

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is to load a sequence of volumes into slicer."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Liu, Haiying, SPL, Brigham and Women's Hospital, hliu@bwh.harvard.edu"
    #  Set the level of development that this module falls under, from the list defined in Main.tcl,
    #  Module(categories) or pick your own
    #  This is included in the Help->Module Categories menu item
    set Module($m,category) "IO"

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
#    set Module($m,row1List) "Help Stuff"
#    set Module($m,row1Name) "{Help} {Tons o' Stuff}"
#    set Module($m,row1,tab) Stuff

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
    #   set Module($m,procVTK) MultiVolumeReaderBuildVTK
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
#    set Module($m,procGUI) MultiVolumeReaderBuildGUI
#    set Module($m,procVTK) MultiVolumeReaderBuildVTK
#    set Module($m,procEnter) MultiVolumeReaderEnter
#    set Module($m,procExit) MultiVolumeReaderExit

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
#    set Module($m,depend) "Analyze BXH"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.24 $} {$Date: 2006/01/06 17:57:07 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
#    set MultiVolumeReader(count) 0
#    set MultiVolumeReader(Volume1) $Volume(idNone)
#    set MultiVolumeReader(Model1)  $Model(idNone)
#    set MultiVolumeReader(FileName)  ""

    set MultiVolumeReader(modulePath) "$env(SLICER_HOME)/Modules/MultiVolumeReader"

    # Source all appropriate tcl files here. 
    source "$MultiVolumeReader(modulePath)/tcl/DICOMHelper.tcl"
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
# .PROC MultiVolumeReaderBuildGUI 
# Creates UI for for user input 
# .ARGS
# frame parent the parent frame 
# binary status whether you want to turn on (1) or off (0) the status message
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderBuildGUI {parent {status 0}} {
    global Gui MultiVolumeReader Module Volume Model
   
    frame $parent.fReaderConfig -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $parent.fVolumeNav -bg $Gui(activeWorkspace) 
    pack $parent.fReaderConfig $parent.fVolumeNav -side top -pady 3 

    #-------------------------------------------
    # Reader configuration 
    #-------------------------------------------
    set f $parent.fReaderConfig
    frame $f.fLabel   -bg $Gui(activeWorkspace)
    frame $f.fFile    -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $f.fApply   -bg $Gui(activeWorkspace)
    frame $f.fStatus  -bg $Gui(activeWorkspace) 
    pack $f.fLabel $f.fFile $f.fApply $f.fStatus \
        -side top -pady 1 

    set f $parent.fReaderConfig.fLabel
    DevAddLabel $f.lLabel "Configure the multi-volume reader:"
    pack $f.lLabel -side top -pady 2 

    set f $parent.fReaderConfig.fFile
    # set MultiVolumeReader(fileTypes) {bxh .dcm .hdr}
    DevAddFileBrowse $f MultiVolumeReader "fileName" "File Name:" \
        "MultiVolumeReaderSetFileFilter" "bxh .dcm .hdr" \
        "\$Volume(DefaultDir)" "Open" "Browse for a volume file" "" "Absolute"

    frame $f.fSingle    -bg $Gui(activeWorkspace)
    frame $f.fMultiple  -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $f.fName      -bg $Gui(activeWorkspace) 
    pack $f.fSingle $f.fMultiple $f.fName -side top -pady 1 

    set f $parent.fReaderConfig.fFile.fSingle
    DevAddButton $f.bHelp "?" "fMRIEngineHelpLoadSequence" 2 
    eval {radiobutton $f.r1 -width 23 -text {Load a single file} \
        -variable MultiVolumeReader(fileChoice) -value single \
        -relief flat -offrelief flat -overrelief raised \
        -selectcolor white} $Gui(WEA)
    grid $f.bHelp $f.r1  -padx 1 -pady 2 -sticky w

    set f $parent.fReaderConfig.fFile.fMultiple
    eval {radiobutton $f.r2 -width 27 -text {Load multiple files} \
        -variable MultiVolumeReader(fileChoice) -value multiple \
        -relief flat -offrelief flat -overrelief raised \
        -selectcolor white} $Gui(WEA)

    DevAddLabel $f.lFilter " Filter:"
    eval {entry $f.eFilter -width 24 \
        -textvariable MultiVolumeReader(filter)} $Gui(WEA)

    #The "sticky" option aligns items to the left (west) side
    grid $f.r2 -row 0 -column 0 -columnspan 2 -padx 5 -pady 2 -sticky w
    grid $f.lFilter -row 1 -column 0 -padx 1 -pady 1 -sticky w
    grid $f.eFilter -row 1 -column 1 -padx 1 -pady 2 -sticky w

    set MultiVolumeReader(fileChoice) multiple 
    set MultiVolumeReader(singleRadiobutton) $f.r1
    set MultiVolumeReader(multipleRadiobutton) $f.r2
    set MultiVolumeReader(filterEntry) $f.eFilter

    if {$status == 1} {
        set f $parent.fReaderConfig.fFile.fName
        DevAddLabel $f.lName "Sequence name:"
        eval {entry $f.eName -width 16 \
            -textvariable MultiVolumeReader(sequenceName)} $Gui(WEA)
        bind $f.eName <Return> "MultiVolumeReaderLoad $status" 
        grid $f.lName $f.eName  -padx 3 -pady 2 -sticky w
    }

    set f $parent.fReaderConfig.fApply
    DevAddButton $f.bApply "Apply" "MultiVolumeReaderLoad $status" 12 
    pack $f.bApply -side top -pady 3 

    set f $parent.fReaderConfig.fStatus
    DevAddLabel $f.lVName "Load status (latest loaded volume):"

    eval {entry $f.eVName -width 30 \
        -state normal \
        -textvariable Volume(name)} $Gui(WEA)
    pack $f.lVName $f.eVName -side top -padx $Gui(pad) -pady 2 
    
    #-------------------------------------------
    # Volume navigation 
    #-------------------------------------------
    set f $parent.fVolumeNav

    DevAddLabel $f.lVolNo "Vol Index:"
    eval {scale $f.sSlider \
        -orient horizontal \
        -from 0 -to 0 \
        -resolution 1 \
        -bigincrement 10 \
        -length 130 \
        -state active \
        -command {MultiVolumeReaderUpdateVolume}} \
        $Gui(WSA) {-showvalue 1}
    set MultiVolumeReader(slider) $f.sSlider
 
    #The "sticky" option aligns items to the left (west) side
    grid $f.lVolNo -row 1 -column 0 -padx 1 -pady 1 -sticky w
    grid $f.sSlider -row 1 -column 1 -padx 1 -pady 1 -sticky w
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineHelpLoadSequence
# Populate and pop up a window giving help about loading sequences.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineHelpLoadSequence { } {
    #--- Sequence->Load
    #--- loading sequences
    set i [ fMRIEngineGetHelpWinID ]
    set txt "<H3>Loading sequences</H3>
 <P> A single file may be loaded by selecting the <I> single file </I> radio button within the Load GUI, and either typing the filename (including its complete path) or using the <I> Browse </I> button to select the file.
<P> A sequence of files may be loaded by selecting the <I> multiple files </I> radio button and specifying an appropriate file filter in the Load GUI, and then using the <I> Browse </I> button to select one of the files.
<P><B>Supported file formats</B>
<P> Currently the fMRIEngine supports the loading of Analyze, DICOM and BXH single- and multi-volume sequences."
    DevCreateTextPopup infowin$i "fMRIEngine information" 100 100 18 $txt
}


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderUpdateVolume
# Updates image volume as user moves the slider 
# .ARGS
# int volumeNo the volume number
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderUpdateVolume {volumeNo} {
    global MultiVolumeReader 

    if {$volumeNo == 0} {
        return
    }

    set v [expr $volumeNo-1]
    set id [expr $MultiVolumeReader(firstMRMLid)+$v]

    MainSlicesSetVolumeAll Back $id 
    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderSetWindowLevelThresholds 
# Sets window, level and thresholds for the entire sequence using the values
# of the first volume
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderSetWindowLevelThresholds {} {
    global MultiVolumeReader Volume

    if {! [info exists MultiVolumeReader(noOfVolumes)]} {
        return
    }

    set low [Volume($MultiVolumeReader(firstMRMLid),node) GetLowerThreshold]
    set win [Volume($MultiVolumeReader(firstMRMLid),node) GetWindow]
    set level [Volume($MultiVolumeReader(firstMRMLid),node) GetLevel]
    set MultiVolumeReader(lowerThreshold) $low

    set i $MultiVolumeReader(firstMRMLid)
    while {$i <= $MultiVolumeReader(lastMRMLid)} {
        # If AutoWindowLevel is ON, 
        # we can't set new values for window and level.
        Volume($i,node) AutoWindowLevelOff
        Volume($i,node) SetWindow $win 
        Volume($i,node) SetLevel $level 
 
        Volume($i,node) AutoThresholdOff
        Volume($i,node) ApplyThresholdOn
        Volume($i,node) SetLowerThreshold $low 
        incr i
    }
}


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderSetFileFilter 
# Sets the file filter depending on file type 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderSetFileFilter {} {
    global MultiVolumeReader

    set fileName $MultiVolumeReader(fileName)
    set fileName [string trim $fileName]
    if {$fileName == ""} {
        return
    }

    if {! [file exists $fileName]} {
        return
    }

    set MultiVolumeReader(fileName) $fileName
    set MultiVolumeReader(fileExtension) [file extension $fileName]
    switch $MultiVolumeReader(fileExtension) {
        ".hdr" {
            $MultiVolumeReader(multipleRadiobutton) configure -state active 
            $MultiVolumeReader(filterEntry) configure -state normal 
        }
        ".dcm" {
            $MultiVolumeReader(multipleRadiobutton) configure -state active 
            $MultiVolumeReader(filterEntry) configure -state normal 
        }
        ".bxh" {
            set MultiVolumeReader(fileChoice) single
            $MultiVolumeReader(multipleRadiobutton) configure -state disabled 
            $MultiVolumeReader(filterEntry) configure -state disabled 
        }
        default {
        }
    }
}   


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderLoad 
# Loads volumes 
# .ARGS
# int status whether the status message is on(1) or off(0)
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderLoad {{status 0}} {
    global MultiVolumeReader Volume

    set fileName $MultiVolumeReader(fileName)
    set fileName [string trim $fileName]
    if {$fileName == ""} {
        DevErrorWindow "File name is empty."
        return 1
    }

    if {! [file exists $fileName]} {
        DevErrorWindow "File doesn't exist: $fileName."
        set MultiVolumeReader(fileName) ""
        return 1
    }

    if {$status} {
        set sequenceName $MultiVolumeReader(sequenceName)
        set sequenceName [string trim $sequenceName]
        if {$sequenceName == ""} {
            if {[info exists MultiVolumeReader(defaultSequenceName)]} {
                set name [incr MultiVolumeReader(defaultSequenceName)]
            } else {
                set name 1
                set MultiVolumeReader(defaultSequenceName) $name
            }
            set sequenceName "multiVol$name" 
        }
        if {[info exists MultiVolumeReader(sequenceNames)]} {
            set found [lsearch -exact $MultiVolumeReader(sequenceNames) $sequenceName]
            if {$found >= 0} {
                DevErrorWindow "The following sequence name has already been used: $sequenceName. Please choose another one."
                return 1
            }
        }
    }

    unset -nocomplain MultiVolumeReader(noOfVolumes)
    unset -nocomplain MultiVolumeReader(firstMRMLid)
    unset -nocomplain MultiVolumeReader(lastMRMLid)
    unset -nocomplain MultiVolumeReader(volumeExtent)

    switch $MultiVolumeReader(fileExtension) {
        ".hdr" {
            set val [MultiVolumeReaderLoadAnalyze]
        }
        ".bxh" {
            set val [MultiVolumeReaderLoadBXH]
        }
        ".dcm" {
            set val [MultiVolumeReaderLoadDICOM]
        }
        default {
            DevErrorWindow "Can't read this file (the file format is not supported): $fileName."
            set val 1
        }
    }

    set MultiVolumeReader(fileName) ""

    if {$val == 1} {
        return 1
    }
 
    # Sets range for the volume slider
    if {[info exists MultiVolumeReader(slider)]} {
        $MultiVolumeReader(slider) configure -from 1 -to $MultiVolumeReader(noOfVolumes)
    }
    # Sets the first volume in the sequence as the active volume
    MainVolumesSetActive $MultiVolumeReader(firstMRMLid)

    if {$status} {
        # Info for a loaded sequence
        lappend MultiVolumeReader(sequenceNames) $sequenceName
        set MultiVolumeReader($sequenceName,noOfVolumes) $MultiVolumeReader(noOfVolumes)
        set MultiVolumeReader($sequenceName,firstMRMLid) $MultiVolumeReader(firstMRMLid)
        set MultiVolumeReader($sequenceName,lastMRMLid) $MultiVolumeReader(lastMRMLid)
        set MultiVolumeReader($sequenceName,volumeExtent) $MultiVolumeReader(volumeExtent)
        set MultiVolumeReader(sequenceName) ""
    }

    set MultiVolumeReader(filter) ""
    set Volume(name) ""

    return 0
}   


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderGetFilelistFromFilter 
# Returns a list of file names that match the user's filter. 
# .ARGS
# string extension the image file extension such as .hdr, .dcm, or .bxh
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderGetFilelistFromFilter {extension} {
    global MultiVolumeReader 

    set path [file dirname $MultiVolumeReader(fileName)]
    set name [file tail $MultiVolumeReader(fileName)]

    set filter $MultiVolumeReader(filter)
    string trim $filter
    set len [string length $filter]
    if {$len == 0} {
        set filter "*.*" 
    } 

    set ext [file extension $filter]

    if {$ext == ".*"} {
        set len [string length $filter]
        set filter [string replace $filter [expr $len-2] end $extension] 
    } elseif {$ext == $extension} {
    } else {
        set filter $filter$extension
    }

    set pattern [file join $path $filter]
    set fileList [glob -nocomplain $pattern]
    if {$fileList == ""} {
        DevErrorWindow "No image file is matched through your filter: $filter"
        return "" 
    }

    return [lsort -dictionary $fileList]
}


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderLoadAnalyze 
# Loads Analyze volumes. It returns 0 if successful; 1 otherwise. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderLoadAnalyze {} {
    global MultiVolumeReader AnalyzeCache Volume Mrml

    unset -nocomplain AnalyzeCache(MRMLid)

    set fileName $MultiVolumeReader(fileName)
    set analyzeFiles [list $fileName]
 
    # file filter
    if {$MultiVolumeReader(fileChoice) == "multiple"} {
        set analyzeFiles [MultiVolumeReaderGetFilelistFromFilter ".hdr"]
        set len [llength $analyzeFiles]
    }

    foreach f $analyzeFiles { 
        # VolAnalyzeApply without argument is for Cindy's data (IS scan order) 
        # VolAnalyzeApply "PA" is for Chandlee's data (PA scan order) 
        # set id [VolAnalyzeApply "PA"]
        # lappend mrmlIds [VolAnalyzeApply]
        set AnalyzeCache(fileName) $f 
        set val [AnalyzeApply]
        if {$val == 1} {
            return $val
        }
    }

    set MultiVolumeReader(firstMRMLid) [lindex $AnalyzeCache(MRMLid) 0] 
    set MultiVolumeReader(lastMRMLid) [lindex $AnalyzeCache(MRMLid) end] 
    set MultiVolumeReader(noOfVolumes) [llength $AnalyzeCache(MRMLid)] 
    set MultiVolumeReader(volumeExtent) $AnalyzeCache(volumeExtent) 

    MainUpdateMRML

    # show the first volume by default
    MainSlicesSetVolumeAll Back $MultiVolumeReader(firstMRMLid)
    RenderAll

    return 0
}


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderLoadBXH 
# Loads BXH volumes. It returns 0 if successful; 1 otherwise. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderLoadBXH {} {
    global MultiVolumeReader VolBXH 

    set VolBXH(bxh-fileName) $MultiVolumeReader(fileName)
    set val [VolBXHLoadVolumes]
    if {$val == 1} {
        return $val
    }

    set MultiVolumeReader(firstMRMLid) [lindex $VolBXH(MRMLid) 0] 
    set MultiVolumeReader(lastMRMLid) [lindex $VolBXH(MRMLid) end] 
    set MultiVolumeReader(noOfVolumes) [llength $VolBXH(MRMLid)] 
    set MultiVolumeReader(volumeExtent) $VolBXH(volumeExtent) 

    MainUpdateMRML

    # show the first volume by default
    MainSlicesSetVolumeAll Back $MultiVolumeReader(firstMRMLid)
    RenderAll

    return 0
}


#-------------------------------------------------------------------------------
# .PROC MultiVolumeReaderLoadDICOM 
# Loads DICOM volume(s). It returns 0 if successful; 1 otherwise. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MultiVolumeReaderLoadDICOM {} {
    global MultiVolumeReader DICOMHelper Volume Mrml

    set fileName $MultiVolumeReader(fileName)
    set dcmFiles [list $fileName]
 
    # file filter
    if {$MultiVolumeReader(fileChoice) == "multiple"} {
        set dcmFiles [MultiVolumeReaderGetFilelistFromFilter ".dcm"]
    }

    set val [DICOMHelperLoad $dcmFiles]
    if {$val == 1} {
        return 1
    }

    set MultiVolumeReader(firstMRMLid) [lindex $DICOMHelper(MRMLid) 0] 
    set MultiVolumeReader(lastMRMLid) [lindex $DICOMHelper(MRMLid) end] 
    set MultiVolumeReader(noOfVolumes) [llength $DICOMHelper(MRMLid)] 
    set MultiVolumeReader(volumeExtent) $DICOMHelper(volumeExtent) 

    MainUpdateMRML

    # show the first volume by default
    MainSlicesSetVolumeAll Back $MultiVolumeReader(firstMRMLid)
    RenderAll

    return 0
}
