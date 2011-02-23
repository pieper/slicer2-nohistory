#=auto==========================================================================
# (c) Copyright 2005 Massachusetts Institute of Technology (MIT) All Rights Reserved.
#
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors. 
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for 
# research purposes only, provided that (1) the above copyright notice and 
# the following four paragraphs appear on all copies of this software, and 
# (2) that source code to any modifications to this software be made 
# publicly available under terms no more restrictive than those in this 
# License Agreement. Use of this software constitutes acceptance of these 
# terms and conditions.
# 
# 3D Slicer Software has not been reviewed or approved by the Food and 
# Drug Administration, and is for non-clinical, IRB-approved Research Use 
# Only.  In no event shall data or images generated through the use of 3D 
# Slicer Software be used in the provision of patient care.
# 
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
# ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
# DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
# EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
# OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
# NON-INFRINGEMENT.
# 
# THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
# 
#
#===============================================================================
# FILE:        Analyze.tcl
# PROCEDURES:  
#   AnalyzeInit
#   AnalyzeBuildGUI
#   AnalyzeBuildVTK
#   AnalyzeEnter
#   AnalyzeEnter
#   AnalyzeExit
#   AnalyzeApply 
#   AnalyzeCreateMrmlNodeForVolume the the
#   AnalyzeCreateVolumeNameFromFileName  the
#   AnalyzeLoadVolumes 
#   AnalyzeSwitchExtension  the
#   AnalyzeFlushCache 
#   AnalyzeCheckHeader 
#   AnalyzeExtractHeader 
#==========================================================================auto=
# Commenting out proc AnalyzeInit will make module Analyze invisible
# on the list of More in the main UI of 3D Slicer. The module will
# still be loaded.
set c 0 
if {$c} {
#-------------------------------------------------------------------------------
# .PROC AnalyzeInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnalyzeInit {} { 
    global Analyze Module Volume Model

    set m Analyze

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is to read Analyze image."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Haiying Liu, SPL/BWH, hliu@bwh.harvard.edu"

    #  Set the level of development that this module falls under, from the list defined in Main.tcl,
    #  Module(categories) or pick your own
    #  This is included in the Help->Module Categories menu item
    set Module($m,category) "Application"

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

    set Module($m,row1List) "Help Stuff"
    set Module($m,row1Name) "{Help} {Tons o' Stuff}"
    set Module($m,row1,tab) Stuff

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
    #   set Module($m,procVTK) AnalyzeBuildVTK
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
    set Module($m,procGUI) AnalyzeBuildGUI
    set Module($m,procVTK) AnalyzeBuildVTK
    set Module($m,procEnter) AnalyzeEnter
    set Module($m,procExit) AnalyzeExit

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
        {$Revision: 1.14 $} {$Date: 2006/01/06 17:57:14 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set Analyze(count) 0
    set Analyze(Volume1) $Volume(idNone)
    set Analyze(Model1)  $Model(idNone)
    set Analyze(FileName)  ""
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
# .PROC AnalyzeBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnalyzeBuildGUI {} {
    global Gui Analyze Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(Analyze,fStuff)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Stuff
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
    The Analyze module tends to load an Analyze image into 3D Slicer by using vtk classes.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags Analyze $help
    MainHelpBuildGUI Analyze

    #-------------------------------------------
    # Stuff frame
    #-------------------------------------------
    set fStuff $Module(Analyze,fStuff)
    set f $fStuff
    
    foreach frame "Top Middle Bottom" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # Stuff->Top frame
    #-------------------------------------------
    set f $fStuff.fTop
    
    #       grid $f.lStuff -padx $Gui(pad) -pady $Gui(pad)
    #       grid $menubutton -sticky w
    
    # Add menus that list models and volumes
    DevAddSelectButton  Analyze $f Volume1 "Ref Volume" Grid
    DevAddSelectButton  Analyze $f Model1  "Ref Model"  Grid
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbVolume1
    lappend Volume(mActiveList) $f.mbVolume1.m
    lappend Model(mbActiveList) $f.mbModel1
    lappend Model(mActiveList) $f.mbModel1.m
    
    #-------------------------------------------
    # Stuff->Middle frame
    #-------------------------------------------
    set f $fStuff.fMiddle
    
    # file browse box
    DevAddFileBrowse $f Analyze FileName "File" AnalyzeShowFile

    # confirm user's existence
    DevAddLabel $f.lfile "You entered: <no filename yet>"
    pack $f.lfile -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    set Analyze(lfile) $f.lfile

    #-------------------------------------------
    # Stuff->Bottom frame
    #-------------------------------------------
    set f $fStuff.fBottom
    # make frames inside the Bottom frame for nice layout
    foreach frame "CountDemo TextBox" {
    frame $f.f$frame -bg $Gui(activeWorkspace) 
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    $f.fTextBox config -relief groove -bd 3 

    #-------------------------------------------
    # Stuff->Bottom->CountDemo frame
    #-------------------------------------------
    set f $fStuff.fBottom.fCountDemo

    DevAddLabel $f.lStuff "You clicked 0 times."
    pack $f.lStuff -side top -padx $Gui(pad) -fill x
    set Analyze(lStuff) $f.lStuff
    
    # Here's a button with text "Count" that calls "AnalyzeCount" when
    # pressed.
    DevAddButton $f.bCount Count AnalyzeCount 
    
    # Tooltip example: Add a tooltip for the button
    TooltipAdd $f.bCount "Press this button to increment the counter."
    # entry box
    eval {entry $f.eCount -width 5 -textvariable Analyze(count) } $Gui(WEA)
    
    pack $f.bCount $f.eCount -side left -padx $Gui(pad) -pady $Gui(pad)
    

    #-------------------------------------------
    # Stuff->Bottom->TextBox frame
    #-------------------------------------------
    set f $fStuff.fBottom.fTextBox

    # this is a convenience proc from tcl-shared/Developer.tcl
    DevAddLabel $f.lBind "Bindings Demo"
    pack $f.lBind -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    # here's the text box widget from tcl-shared/Widgets.tcl
    set Analyze(textBox) [ScrolledText $f.tText]
    pack $f.tText -side top -pady $Gui(pad) -padx $Gui(pad) \
        -fill x -expand true

}
#-------------------------------------------------------------------------------
# .PROC AnalyzeBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnalyzeBuildVTK {} {

}

#-------------------------------------------------------------------------------
# .PROC AnalyzeEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC AnalyzeEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnalyzeEnter {} {
    global Analyze
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    # pushEventManager $Analyze(eventManager)

    # clear the text box and put instructions there
    $Analyze(textBox) delete 1.0 end
    $Analyze(textBox) insert end "Shift-Click anywhere!\n"

}


#-------------------------------------------------------------------------------
# .PROC AnalyzeExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnalyzeExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeSetVolumeNamePrefix 
# Sets a prefix for volume name 
# .END
#-------------------------------------------------------------------------------
proc AnalyzeSetVolumeNamePrefix {prefix} {
    global AnalyzeCache 
    
    set AnalyzeCache(volumeNamePrefix) $prefix
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeApply 
#  Starts to load Analyze volume(s). It returns 0 if successful; 1 otherwise.
# .END
#-------------------------------------------------------------------------------
proc AnalyzeApply {} {
    global Volume AnalyzeCache 

    # Checks file 
    if {![info exists AnalyzeCache(fileName)]} {
        DevErrorWindow "Analyze file is not available."
        return 1
    }

    set fileName [string trim $AnalyzeCache(fileName)]
    if {![file exists $fileName]} {
        DevErrorWindow "Analyze file is not available: $fileName."
        return 1
    }

    # Checks header info
    set ready [AnalyzeCheckHeader]
    if {!$ready} {
        set b [AnalyzeExtractHeader]
        if {!$b} {
            DevErrorWindow "Failed to extract header info."
            return 1
        }
    }

    # Switches file extension if needed.
    if {[file extension $AnalyzeCache(fileName)] == ".hdr"} {
        set name [AnalyzeSwitchExtension $AnalyzeCache(fileName)]
        set AnalyzeCache(fileName) $name
    }

    if {! [info exists AnalyzeCache(volumeNamePrefix)]} {
        set AnalyzeCache(volumeNamePrefix) ""
    }

    # Loads volumes in .img file 
    AnalyzeLoadVolumes

    # Flushes AnalyzeCache
    AnalyzeFlushCache

    return 0
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeCreateMrmlNodeForVolume
# Creates a mrml node for a vtkImageData object 
# .ARGS
# volName the volume name
# volData the vtkImageData object
# .END
#-------------------------------------------------------------------------------
proc AnalyzeCreateMrmlNodeForVolume {volName volData} {
    global AnalyzeCache Volume Mrml

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i

    # set the name and description of the volume
    $n SetName $volName 
    $n SetDescription $volName 

    Volume($i,node) SetScanOrder {SI} 
    # Volume($i,node) SetScanOrder {IS} 
    Volume($i,node) SetLittleEndian $AnalyzeCache(byteOrder) 

    $volData Update 

    set spc [$volData GetSpacing]
    set pixelWidth [lindex $spc 0]
    set pixelHeight [lindex $spc 1]
    set sliceThickness [lindex $spc 2]
    set sliceSpacing 0
    set zSpacing [expr $sliceThickness + $sliceSpacing]

    eval Volume($i,node) SetSpacing $pixelWidth $pixelHeight $zSpacing 
    Volume($i,node) SetNumScalars [$volData GetNumberOfScalarComponents]
    set ext [$volData GetWholeExtent]
    Volume($i,node) SetImageRange [expr 1 + [lindex $ext 4]] [expr 1 + [lindex $ext 5]]

    Volume($i,node) SetScalarType [$volData GetScalarType]
    Volume($i,node) SetDimensions [lindex [$volData GetDimensions] 0] \
        [lindex [$volData GetDimensions] 1]
    Volume($i,node) ComputeRasToIjkFromScanOrder [Volume($i,node) GetScanOrder]

    Volume($i,vol) SetImageData $volData
    # Make sure to keep the following order for these two commands; You will not
    # see the right updates in the Volumes gui.

    MainVolumesSetActive $i

    return $i
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeCreateVolumeNameFromFileName 
# Creates a volume name from the file name 
# .ARGS
# fileName the file name
# .END
#-------------------------------------------------------------------------------
proc AnalyzeCreateVolumeNameFromFileName {fileName} {

    set tail [file tail $fileName]
    set dot [string last "." $tail]
#    set name [string replace $tail $dot $dot "_"] 
    set name [string range $tail 0 [expr $dot-1]] 

    return $name
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeLoadVolumes 
#  Loads Analyze .img file.
# .ARGS 
# .END
#-------------------------------------------------------------------------------
proc AnalyzeLoadVolumes {} {
    global AnalyzeCache Volume 

    vtkImageReader ir

    # Here is the coordinate system
    # x axis
    # ^
    # |------------------------------------| 
    # |          |          |              |
    # | slice #1 | slice #2 |  ......      |
    # |          |          |              |
    # -------------------------------------------->
    #                    y axis
    #
    set x [lindex $AnalyzeCache(imageDim) 0]
    set y [lindex $AnalyzeCache(imageDim) 1]
    set z [lindex $AnalyzeCache(imageDim) 2]
    set n [lindex $AnalyzeCache(imageDim) 3]

    set minX 0
    set maxX [expr $x -1] 
    set minY 0
    set maxY [expr $y*$z*$n-1] 

    ir SetFileName $AnalyzeCache(fileName)
    ir SetDataByteOrder $AnalyzeCache(byteOrder) 
    ir SetDataScalarType $AnalyzeCache(dataType)
 
    # Spacing
    set pixDims $AnalyzeCache(pixDim)
    set xx [lindex $pixDims 0]
    set yy [lindex $pixDims 1]
    set zz [lindex $pixDims 2]

    ir SetDataSpacing $xx $yy $zz 
    ir ReleaseDataFlagOff
    ir SetDataExtent $minX $maxX $minY $maxY 0 0 

    set volName [AnalyzeCreateVolumeNameFromFileName \
        $AnalyzeCache(fileName)]
    set underscore "_"

    set x1 0 
    set x2 $maxX 
    set i 1
    set j 1
    while {$j <= $n} {

        # If you want to create a volue from a series of XY images, 
        # then you should set the AppendAxis to 2 (Z axis).
        vtkImageAppend imageAppend 
        imageAppend SetAppendAxis 2 
        
        if {$n > 1} {
            set vName $AnalyzeCache(volumeNamePrefix)$volName$underscore$j
        } else {
            set vName $AnalyzeCache(volumeNamePrefix)$volName
        }
        set load "Loading volume:\n"
        append load $vName
        puts "Loading volume $vName..."

        set yBase [expr $y*$z*($j-1)]
        while {$i <= $z} {

            vtkExtractVOI extract
            extract SetInput [ir GetOutput]
            extract SetSampleRate 1 1 1 

            vtkImageData vol
            set y1 [expr ($i-1)*$y+$yBase]
            set y2 [expr $i*$y-1+$yBase]

            extract SetVOI $x1 $x2 $y1 $y2 0 0 
            extract Update

            set d [extract GetOutput]
            # Setting directly the extent of extract's output does not 
            # change its extent. That's why DeepCopy is here.
            vol DeepCopy $d
            vol SetExtent 0 [expr $x - 1] 0 [expr $y - 1] 0 0 

            # flip the image to get right orientation
            vtkImageFlip flipX
            flipX SetInput vol 
            flipX SetFilteredAxis 0
            flipX Update

            vtkImageFlip flipY
            flipY SetInput [flipX GetOutput] 
            flipY SetFilteredAxis 1 
            flipY Update

            vtkImageFlip flipZ
            flipZ SetInput [flipY GetOutput] 
            flipZ SetFilteredAxis 2 
            flipZ Update

            imageAppend AddInput [flipZ GetOutput] 

            extract Delete
            vol Delete
            flipX Delete
            flipY Delete
            flipZ Delete

            incr i
        }

        set volData [imageAppend GetOutput] 
        set id [AnalyzeCreateMrmlNodeForVolume $vName $volData]
        lappend AnalyzeCache(MRMLid) $id 
        set Volume(name) $vName
        puts "...done"

        imageAppend Delete

        incr j
        set i 1
    }

    set AnalyzeCache(volumeExtent) \
        [[Volume([lindex $AnalyzeCache(MRMLid) 0],vol) GetOutput] GetWholeExtent]

    ir Delete
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeSwitchExtension 
#  Switches extension between .img and .hdr given a file name.
# .ARGS 
# fileName the file name to switch
# .END
#-------------------------------------------------------------------------------
proc AnalyzeSwitchExtension {fileName} {

    set img ".img"
    set hdr ".hdr"
    set name [string trim $fileName]
    set ext [file extension $name]

    set newExt [expr {$ext == $img ? $hdr : $img}]
    set first [expr [string length $name]-4]
    set last [expr [string length $name]-1]
    set name [string replace $name $first $last $newExt] 

    return $name
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeFlushCache 
# Flushes the cache. 
# .END
#-------------------------------------------------------------------------------
proc AnalyzeFlushCache {} {
    global AnalyzeCache 

    unset -nocomplain AnalyzeCache(byteOrder)  
    unset -nocomplain AnalyzeCache(fileName)  
    unset -nocomplain nalyzeCache(dataType)   
    unset -nocomplain AnalyzeCache(orient)     
    unset -nocomplain AnalyzeCache(fileFormat)
    unset -nocomplain AnalyzeCache(bitsPix)  
    unset -nocomplain AnalyzeCache(imageDim)
    unset -nocomplain AnalyzeCache(pixDim) 
    unset -nocomplain AnalyzeCache(pixRange)
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeCheckHeader 
#  Checks if header info is ready.
# .END
#-------------------------------------------------------------------------------
proc AnalyzeCheckHeader {} {
    global AnalyzeCache 

    set a [info exists AnalyzeCache(byteOrder)]  
    set b [info exists AnalyzeCache(dataType)]   
    set c [info exists AnalyzeCache(orient)]     
    set d [info exists AnalyzeCache(fileFormat)]
    set e [info exists AnalyzeCache(bitsPix)]  
    set f [info exists AnalyzeCache(imageDim)]
    set g [info exists AnalyzeCache(pixDim)] 
    set h [info exists AnalyzeCache(pixRange)]

    return [expr {$a && $b && $c && $d && $e && $f && $g && $h}] 
}


#-------------------------------------------------------------------------------
# .PROC AnalyzeExtractHeader 
#  Extracts header info from .hdr file.
# .END
#-------------------------------------------------------------------------------
proc AnalyzeExtractHeader {} {
    global AnalyzeCache 

    set fileName $AnalyzeCache(fileName)

    # Switches file extension if needed.
    if {[file extension $fileName] == ".img"} {
        set fileName [AnalyzeSwitchExtension $fileName]
    }

    if {![file exists $fileName]} {
        return 0
    }

    # Reads header
    vtkAnalyzeHeaderExtractor r
    r SetFileName $fileName 
    r Read

    # Sets params into AnalyzeCache
    set AnalyzeCache(dataType)   [r GetDataType]
    set AnalyzeCache(orient)     [r GetOrient]
    set AnalyzeCache(fileFormat) [r GetFileFormat]
    set AnalyzeCache(bitsPix)    [r GetBitsPix]
    set AnalyzeCache(imageDim)   [r GetImageDim]
    set AnalyzeCache(pixDim)     [r GetPixDim]
    set AnalyzeCache(pixRange)   [r GetPixRange]
    set AnalyzeCache(byteOrder)  [r IsLittleEndian]

    r Delete

    return 1 
}



