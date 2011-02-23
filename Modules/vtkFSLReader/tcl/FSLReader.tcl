#=auto==========================================================================
# (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
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
# FILE:        FSLReader.tcl
# PROCEDURES:  
#   FSLReaderInit
#   FSLReaderBuildGUI
#   FSLReaderBrowse
#   FSLReaderUpdateTimeSeriesMenu
#   FSLReaderApply
#   FSLReaderLoadVolumes
#   FSLReaderUpdateOverlayVolumes
#   FSLReaderSelectOverlayVolume
#   FSLReaderUpdateBackgroundVolumes
#   FSLReaderSelectBackgroundVolume
#   FSLReaderUpdateVoxelWisePlotButton
#   FSLReaderUpdateEnableTimecourseButton-back
#   FSLReaderDisplayVolume
#   FSLReaderSetPlottingOption option
#   FSLReaderUpdateOverlays
#   FSLReaderSetFSLDir option pathName
#   FSLReaderLaunchBrowser
#   FSLReaderBuildVTK
#   FSLReaderEnter
#   FSLReaderExit
#   FSLReaderPushBindings 
#   FSLReaderPopBindings 
#   FSLReaderCreateBindings  
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC FSLReaderInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderInit {} {
    global FSLReader Module Volume Model env

    set m FSLReader

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is to display the output of FSL from  University of Oxford, UK."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Haiying, Liu, BWH SPL, hliu@bwh.harvard.edu"

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

    set Module($m,row1List) "Help Setup Stats Report"
    set Module($m,row1Name) "{Help} {Set Up} {Stats} {Report} "
    set Module($m,row1,tab) Setup 

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
    #   set Module($m,procVTK) FSLReaderBuildVTK
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
    set Module($m,procGUI) FSLReaderBuildGUI
    set Module($m,procVTK) FSLReaderBuildVTK
    set Module($m,procEnter) FSLReaderEnter
    set Module($m,procExit) FSLReaderExit


    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) "Analyze"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m  {$Revision: 1.11 $} {$Date: 2006/01/06 17:57:39 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set FSLReader(count) 0
    set FSLReader(Volume1) $Volume(idNone)
    set FSLReader(Model1)  $Model(idNone)
    set FSLReader(FileName)  ""

    # Creates bindings
    FSLReaderCreateBindings 

    set FSLReader(modulePath) "$env(SLICER_HOME)/Modules/vtkFSLReader"

    # Source all appropriate tcl files here. 
    source "$FSLReader(modulePath)/tcl/FSLReaderPlot.tcl"

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
# .PROC FSLReaderBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderBuildGUI {} {
    global Gui FSLReader Module Volume Model
    
    # error if no private segment
    if { [catch "package require BLT"] } {
        DevErrorWindow "Must have the BLT package for building FSLReader UI \
        and plotting time course."
        return
    }

    # A frame has already been constructed automatically for each tab.
    # A frame named "Display" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(FSLReader,fDisplay)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Display
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
    The FSLReader module is intended to view Feat output. Feat is a model-based \
    FMRI analysis tool within the FSL package, a comprehensive library of image \
    analysis and statistical tools for FMRI, MRI and DTI brain imaging data. \
    FSL is written mainly by members of the Analysis Group, FMRIB, Oxford, UK.  
    <P>
    As the first step, the user needs to choose the FEAT output directory \
    on the <B>Set Up</B> tab, where volumes and other data are going to be \
    viewed in Slicer.
    <P>
    On <B>Stats</B> tab, volumes are loaded in by clicking Apply button; \
    filtered_func_data.hdr, the 4D FMRI data after all filtering has been carried \
    out, may be opted out and in by toggling the checkbutton. 
    <BR> 
    Upon completion of loading, standard.hdr and example_func.hdr become background \
    images and all stat maps form the overlay volume menu. For a different \
    background or overlay in the Viewer window, just choose one from their own menu \
    in the GUI. 
    <BR>
    There are two ways for plotting time series; however, the first one, Voxel wise, \
    will be disabled if filtered_func_data.hdr is opted out during volume loading. \
    FSL native list all static graphs in tsplot directory, which can be viewed one \
    at a time. Voxel wise is an extra feature; time course can be dynamically viewed \
    by clicking any voxel in one of the three slice windows.
    <P>
    The <B>Report</B> tab allows the user to read the html report by specifying \
    a web browser available.

    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags FSLReader $help
    MainHelpBuildGUI FSLReader

    #-------------------------------------------
    # Setup frame
    #-------------------------------------------
    set fSetup $Module(FSLReader,fSetup)
    set f $fSetup
    
    foreach frame "Upper Lower" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        $f.f$frame configure -relief groove -bd 3  -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    set f $fSetup.fUpper
    
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.f -side top -padx $Gui(pad) -pady $Gui(pad)
   
    DevAddLabel  $f.f.l "Where is the Feat output?" 
    DevAddButton $f.f.b "Browse..." "FSLReaderBrowse" 
    pack $f.f.l $f.f.b -side left -padx $Gui(pad)

    eval {entry $f.efile -textvariable FSLReader(featDir) -width 50} $Gui(WEA)
    pack $f.efile -side top -pady $Gui(pad) -padx $Gui(pad)  -expand 1 -fill x    

    #-------------------------------------------
    # Report frame
    #-------------------------------------------
    set fReport $Module(FSLReader,fReport)
    set f $fReport
    
    foreach frame "Upper Lower" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        $f.f$frame configure -relief groove -bd 3  -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    set f $fReport.fLower
    DevAddFileBrowse $f FSLReader "htmlFile" "Html File:"  "" "html" \
        "\$FSLReader(featDir)"  "Open" "Browse for an html file" "" "Absolute"

    frame $f.fView -bg $Gui(activeWorkspace)
    pack $f.fView -side top  
    set f $f.fView
    DevAddLabel $f.label2 "Browser:"
    set FSLReader(browser) "mozilla"
    eval {entry $f.entry -width 10  -textvariable FSLReader(browser)} $Gui(WEA)
    bind $f.entry <Return> FSLReaderLaunchBrowser

    # make a button that pops up the report 
    DevAddButton $f.bWeb "Read..." FSLReaderLaunchBrowser
    
    pack $f.label2 $f.entry $f.bWeb -side left -padx $Gui(pad) -pady $Gui(pad)  

    #-------------------------------------------
    # Stats frame
    #-------------------------------------------
    set fStats $Module(FSLReader,fStats)
    set f $fStats

    frame $f.fTop  -bg $Gui(activeWorkspace)  -relief groove -bd 3  
    frame $f.fMid  -bg $Gui(activeWorkspace)  -relief groove -bd 3
    frame $f.fBot  -bg $Gui(activeWorkspace)  -relief groove -bd 3 
    pack $f.fTop $f.fMid $f.fBot -side top -fill x -pady 5 -padx 2 

    # top frame
    # ---------------------
    set f $fStats.fTop
    frame $f.f1  -bg $Gui(activeWorkspace)
    frame $f.f2  -bg $Gui(activeWorkspace)  -relief groove -bd 1 
    frame $f.f3  -bg $Gui(activeWorkspace)
    pack $f.f1 $f.f2 $f.f3 -side top -fill x -pady 1 -padx 2 

    set f $fStats.fTop.f1
    DevAddLabel $f.lTitle "Load volumes: " 
    pack $f.lTitle -side top -pady $Gui(pad) -fill x

    set f $fStats.fTop.f2
    DevAddLabel $f.lVol1 "1. standard brain"
    DevAddLabel $f.lVol2 "2. example_func"
    DevAddLabel $f.lVol3 "3. All stats maps in both\nstats/ and reg_standard/stats/"
    pack $f.lVol1 $f.lVol2 $f.lVol3 -side top -fill x -pady 2 -padx 2 

    set f $fStats.fTop.f3
    eval {checkbutton $f.cbTimecourse \
        -variable FSLReader(timeCourse) \
        -text "4. filtered_func_data"} $Gui(WEA) 
    $f.cbTimecourse select 

    pack $f.cbTimecourse -side top -fill x -pady 5 -padx 2 

    DevAddButton $f.bApply "Apply" "FSLReaderApply" 
    pack $f.bApply -side top -pady $Gui(pad)

    # middle frame
    # ---------------------
    set f $fStats.fMid
    frame $f.fTitle      -bg $Gui(activeWorkspace)
    frame $f.fVols       -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fVols -side top -fill x -pady 5 -padx 2 

    set f $fStats.fMid.fTitle
    DevAddLabel $f.lTitle "Volume overlay:" 
    pack $f.lTitle -side top -pady 1 -fill x
   
    # Build pulldown menu for background volumes 
    set f $fStats.fMid.fVols
    DevAddLabel $f.lBack "Background:"

    set backList [list {none}]
    set df [lindex $backList 0] 
    eval {menubutton $f.mbType \
        -text $df \
        -relief raised -bd 2 \
        -width 25  \
        -indicatoron 1  \
        -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    foreach m $backList  {
        $f.mbType.m add command -label $m  -command "FSLReaderSelectBackground $m"
    }

    # Save menubutton for config
    set FSLReader(gui,backMenuButton) $f.mbType
    set FSLReader(gui,backMenu) $f.mbType.m

    # Build pulldown menu for background volumes 
    DevAddLabel $f.lOverlay "Stats map:"

    set actList [list {none}]
    set df [lindex $actList 0] 
    eval {menubutton $f.mbType2 -text $df \
        -relief raised -bd 2 \
        -width 25  \
        -indicatoron 1  \
        -menu $f.mbType2.m} $Gui(WMBA)
    eval {menu $f.mbType2.m} $Gui(WMA)
    foreach m $actList  {
        $f.mbType2.m add command -label $m  -command "FSLReaderSelectOverlay $m"
    }

    # Save menubutton for config
    set FSLReader(gui,overlayMenuButton) $f.mbType2
    set FSLReader(gui,overlayMenu) $f.mbType2.m

    blt::table $f \
        0,0 $f.lBack -padx 1 -pady 2 \
        0,1 $f.mbType -fill x -padx 1 -pady 2 \
        1,0 $f.lOverlay -padx 1 -pady 2 \
        1,1 $f.mbType2 -fill x -padx 1 -pady 2 

    # bottom frame
    # ---------------------
    set f $fStats.fBot
    frame $f.fTitle  -bg $Gui(activeWorkspace)
    frame $f.fFSL    -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $f.fAdd    -bg $Gui(activeWorkspace)
    pack $f.fTitle -side top -fill x -padx 2 -pady 1 
    pack $f.fAdd -side top -fill x -padx 2 -pady 1 
    pack $f.fFSL -side top -padx 2 -pady 1 

    set f $fStats.fBot.fTitle
    DevAddLabel $f.lLabel "Time series plotting:"

    grid $f.lLabel -padx 1 -pady 5 

    set f $fStats.fBot.fFSL
    eval {radiobutton $f.rFSL -width 6 -text "FSL native" \
        -variable FSLReader(tcPlotOption) -value fsl \
        -relief raised -offrelief raised -overrelief raised \
        -selectcolor white} $Gui(WEA)
    set FSLReader(gui,fslNativeButton) $f.rFSL
    bind $f.rFSL <1> "FSLReaderEnableNativeTimeSeriesMenu 1" 
    $f.rFSL config -state disabled

    set gifList [list {none}]
    set df [lindex $gifList 0] 
    eval {menubutton $f.mbType -text $df \
          -relief raised -bd 2 -width 40 \
          -indicatoron 1 \
          -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    foreach m $gifList  {
        $f.mbType.m add command -label $m \
            -command ""
    }

    blt::table $f \
        0,0 $f.rFSL -padx 2 -pady 2 -fill x \
        1,0 $f.mbType -padx 2 -pady 2 -fill x

    $f.mbType config -state disabled

    # Save menubutton for config
    set FSLReader(gui,gifMenuButton) $f.mbType
    set FSLReader(gui,gifMenu) $f.mbType.m

    set f $fStats.fBot.fAdd
    eval {radiobutton $f.rAdd -width 30 -text "Voxel wise" \
            -variable FSLReader(tcPlotOption) -value add \
            -relief raised -offrelief raised -overrelief raised \
            -selectcolor white} $Gui(WEA)
    pack $f.rAdd -side top -pady 2 -padx 2 -fill x 

    $f.rAdd config -state disabled
    set FSLReader(gui,voxelWiseButton) $f.rAdd

    set FSLReader(tcPlotOption) "" 
    bind $f.rAdd <1> "FSLReaderEnableNativeTimeSeriesMenu 0" 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderBrowse
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderBrowse {} {
    global FSLReader

    unset -nocomplain FSLReader(statsVolumeNames)
    unset -nocomplain FSLReader(stdStatsVolumeNames)
    unset -nocomplain FSLReader(noOfFuncVolumes)
    unset -nocomplain FSLReader(backgroundVolumeNames)

    FSLReaderSetFSLDir 1
    FSLReaderUpdateTimeSeriesMenu 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderUpdateTimeSeriesMenu
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderUpdateTimeSeriesMenu {} {
    global FSLReader

    set featDir [string trim $FSLReader(featDir)]

    if {$featDir == ""} {
        DevErrorWindow "Set up the Feat output directory first."
        return 0
    }

    set tsplot [file join $featDir tsplot] 
    if {! [file exists $tsplot]} {
        DevErrorWindow "Feat output directory doesn't exist: $tsplot."
        return 0
    }

    # glob needs the trailing / for its -path option
    set tsplot $tsplot/
    set gifFiles [glob -nocomplain -tails -path $tsplot *.gif] 

    $FSLReader(gui,gifMenu) delete 0 end
    $FSLReader(gui,gifMenu) add command -label none \
        -command "FSLReaderSelectTimeSeriesGraph none"

    # sort the list for display in the menu in order
    set gifFiles [lsort $gifFiles]
    if {[llength $gifFiles] > 0} {
        set gifNum 0
        foreach f $gifFiles { 
            set colbreak 0
            incr gifNum
            # every 15 entries, start a new column in the gif list
            if {[expr fmod($gifNum,15)] == 0} {
                set colbreak 1
            }

            $FSLReader(gui,gifMenu) add command -label $f \
                -command "FSLReaderSelectTimeSeriesGraph $f" \
                -columnbreak $colbreak 
        }
    }

    FSLReaderSelectTimeSeriesGraph none
    $FSLReader(gui,gifMenuButton) config -state disabled  
    $FSLReader(gui,fslNativeButton) deselect 
    $FSLReader(gui,fslNativeButton) config -state normal 
}

 
proc FSLReaderEnableNativeTimeSeriesMenu {true} {
    global FSLReader

    if {$true == 1 &&
        [$FSLReader(gui,fslNativeButton) cget -state] != "disabled"} {  
        $FSLReader(gui,gifMenuButton) config -state normal  
    } elseif {$true == 0 &&
        [$FSLReader(gui,voxelWiseButton) cget -state] != "disabled"} {  
        FSLReaderSelectTimeSeriesGraph none
        $FSLReader(gui,gifMenuButton) config -state disabled  
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderApply {} {
    global FSLReader 

    set a [info exists FSLReader(statsVolumeNames)]
    set b [info exists FSLReader(stdStatsVolumeNames)]
    set c [info exists FSLReader(backgroundVolumeNames)]
    set d [info exists FSLReader(noOfFuncVolumes)]

    set e [expr {$FSLReader(timeCourse) == 1 ? ($a && $b && $c && $d) : ($a && $b && $c)}]
    if {$e} {
        DevErrorWindow "Volumes have been loaded."
        return 
    }

    FSLReaderLoadVolumes
    FSLReaderUpdateBackgroundVolumes
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderLoadVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderLoadVolumes {} {
    global Volume FSLReader AnalyzeCache

    set featDir [string trim $FSLReader(featDir)]

    if {$featDir == ""} {
        DevErrorWindow "Set up the Feat output directory first."
        set FSLReader(loadVolumesError) 1
        return  
    }

    if {! [file exists $featDir]} {
        DevErrorWindow "Feat output directory doesn't exist: $featDir."
        set FSLReader(loadVolumesError) 1
        return  
    }

    set pat "*.hdr"

    # Load stats files 
    # ---------------------
    if {! [info exists FSLReader(statsVolumeNames)]} {
        set statsPath [file join $featDir stats]
        unset -nocomplain FSLReader(statsVolumeNames)

        if {! [file exists $statsPath]} {
            DevErrorWindow "stats directory doesn't exist: $statsPath."
            set FSLReader(statsVolumeNames) ""
        } else {
            set statsPat [file join $featDir stats $pat] 
            set statsFiles [glob -nocomplain $statsPat]

            AnalyzeSetVolumeNamePrefix "stats/" 
            unset -nocomplain AnalyzeCache(MRMLid)
            unset -nocomplain FSLReader(statsVolumeNames)
            foreach f $statsFiles { 
                # VolAnalyzeApply without argument is for Cindy's data (IS scan order) 
                # VolAnalyzeApply "PA" is for Chandlee's data (PA scan order) 
                # set id [VolAnalyzeApply "PA"]
                # lappend mrmlIds [VolAnalyzeApply]
                set AnalyzeCache(fileName) $f 
                set val [AnalyzeApply]
                if {$val == 1} {
                    set FSLReader(loadVolumesError) $val 
                    return 
                }
                lappend FSLReader(statsVolumeNames) $Volume(name)
            }
        }
    }

    # Load reg_standard/stats files 
    # ---------------------
    if {! [info exists FSLReader(stdStatsVolumeNames)]} {
        set regPath [file join $featDir reg_standard stats]
        unset -nocomplain FSLReader(stdStatsVolumeNames)

        if {! [file exists $regPath]} {
            DevErrorWindow "reg_standard stats directory doesn't exist: $regPath."
            set FSLReader(stdStatsVolumeNames) ""
        } else {
            set regPat [file join $featDir reg_standard stats $pat] 
            set regFiles [glob -nocomplain $regPat]

            AnalyzeSetVolumeNamePrefix "reg_std/stats/" 
            unset -nocomplain AnalyzeCache(MRMLid)
            foreach f $regFiles { 
                set AnalyzeCache(fileName) $f 
                set val [AnalyzeApply]
                if {$val == 1} {
                    set FSLReader(loadVolumesError) $val 
                    return 
                }
                lappend FSLReader(stdStatsVolumeNames) $Volume(name)
            }
        }
    }

    # Load functional images 
    # ---------------------
    if {$FSLReader(timeCourse) && (! [info exists FSLReader(noOfFuncVolumes)])} {
        set FSLReader(noOfFuncVolumes) 0
        set func_data [file join $featDir "filtered_func_data.hdr"] 

        if {! [file exists $func_data]} {
            DevErrorWindow "filtered_func_data image doesn't exist: $func_data."
        } else {
            lappend funcFiles $func_data 

            AnalyzeSetVolumeNamePrefix "" 
            unset -nocomplain AnalyzeCache(MRMLid)
            if {[info commands FSLReader(timecourseExtractor)] != ""} {
                FSLReader(timecourseExtractor) Delete
                unset -nocomplain FSLReader(timecourseExtractor)
            }
            vtkTimecourseExtractor FSLReader(timecourseExtractor)

            foreach f $funcFiles { 
                set AnalyzeCache(fileName) $f 
                set val [AnalyzeApply]
                if {$val == 1} {
                    set FSLReader(loadVolumesError) $val 
                    return 
                }
            }

            set FSLReader(noOfFuncVolumes) [llength $AnalyzeCache(MRMLid)]
            foreach id $AnalyzeCache(MRMLid) { 
                Volume($id,vol) Update
                FSLReader(timecourseExtractor) AddInput [Volume($id,vol) GetOutput]
            }
        }
    }

    # Load background images 
    # ---------------------
    if {! [info exists FSLReader(backgroundVolumeNames)]} {
        set backFiles ""
        set standard [file join $featDir "standard.hdr"] 
        if {[file exists $standard]} {
            set type [file type $standard]
            if {$type == "link"} {
                set link [file readlink $standard]
                set standard $link
            }
            lappend backFiles $standard 
        } else {
            DevErrorWindow "Standard image doesn't exist."
        }

        set example_func [file join $featDir "example_func.hdr"] 
        if {[file exists $example_func]} {
            lappend backFiles $example_func 
        } else {
            DevErrorWindow "example_func image doesn't exist."
        }

        if {[llength $backFiles] > 0} {
            AnalyzeSetVolumeNamePrefix "" 
            unset -nocomplain AnalyzeCache(MRMLid)
            unset -nocomplain FSLReader(backgroundVolumeNames)
            foreach f $backFiles { 
                set AnalyzeCache(fileName) $f 
                set val [AnalyzeApply]
                if {$val == 1} {
                    set FSLReader(loadVolumesError) $val 
                    return 
                }
                lappend FSLReader(backgroundVolumeNames) $Volume(name)
            }
        }
    }

    set firstMRMLid [lindex $AnalyzeCache(MRMLid) 0] 
    MainUpdateMRML

    # show the first volume by default
    MainSlicesSetVolumeAll Back $firstMRMLid
 
    RenderAll
    set FSLReader(loadVolumesError) 0 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderUpdateOverlayVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderUpdateOverlayVolumes {} {
    global FSLReader 

    if {! [info exists  FSLReader(statsVolumeNames)]} {
        return
    }
 
    set bvName $FSLReader(currentBackgroundVolumeName)
    if {$bvName == "none"} {
        set volNames [concat $FSLReader(statsVolumeNames) \
            $FSLReader(stdStatsVolumeNames)]
    } elseif {$bvName == "example_func"} {
        set volNames $FSLReader(statsVolumeNames)
    } else {
        set volNames $FSLReader(stdStatsVolumeNames)
    }

    $FSLReader(gui,overlayMenu) delete 0 end
    if {[llength $volNames] > 0} {
        set volnum 0
        foreach name $volNames {
            set colbreak 0
            incr volnum
            # every 20 entries, start a new column in the volumes list
            if {[expr fmod($volnum,20)] == 0} {
                set colbreak 1
            }

            $FSLReader(gui,overlayMenu) add command -label $name \
                -command "FSLReaderSelectOverlayVolume $name" \
                -columnbreak $colbreak 
        }
        FSLReaderSelectOverlayVolume $name
    } else {
        $FSLReader(gui,overlayMenu) add command -label none \
            -command "FSLReaderSelectOverlayVolume none"
        FSLReaderSelectOverlayVolume none
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderSelectOverlayVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderSelectOverlayVolume {overlay} {
    global FSLReader 

    # configure menubutton
    $FSLReader(gui,overlayMenuButton) config -text $overlay 
    set FSLReader(currentOverlayVolumeName) $overlay 

    FSLReaderUpdateVoxelWisePlotButton
    FSLReaderDisplayVolume Fore $overlay 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderUpdateBackgroundVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderUpdateBackgroundVolumes {} {
    global FSLReader 

    if {$FSLReader(loadVolumesError)} {
        return
    }

    $FSLReader(gui,backMenu) delete 0 end

    if {[info exists FSLReader(backgroundVolumeNames)]} {
        foreach name $FSLReader(backgroundVolumeNames) {
            $FSLReader(gui,backMenu) add command -label $name \
                -command "FSLReaderSelectBackgroundVolume $name"
        }
        FSLReaderSelectBackgroundVolume $name
    } else {
        $FSLReader(gui,backMenu) add command -label none \
            -command "FSLReaderSelectOverlayVolume none"
        FSLReaderSelectBackgroundVolume none
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderSelectBackgroundVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderSelectBackgroundVolume {back} {
    global FSLReader 

    # configure menubutton
    $FSLReader(gui,backMenuButton) config -text $back 
    set FSLReader(currentBackgroundVolumeName) $back 

    FSLReaderUpdateVoxelWisePlotButton
    FSLReaderUpdateOverlayVolumes
    FSLReaderDisplayVolume Back $back 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderUpdateVoxelWisePlotButton
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderUpdateVoxelWisePlotButton {} {
    global FSLReader 

    # functional images loaded
    set a [info exists FSLReader(noOfFuncVolumes)] 
   
    # the background is volume "example_func"
    set b [expr {[info exists FSLReader(currentBackgroundVolumeName)] &&
        $FSLReader(currentBackgroundVolumeName) == "example_func"}]
       
    # we have timecourse plotting only for the following volumes as 
    # the overlay: zfstat*, zstat*
    set c [expr {[info exists FSLReader(currentOverlayVolumeName)] &&
        [string first z $FSLReader(currentOverlayVolumeName) 0] != -1}] 

    if {$a && $b && $c} {
        $FSLReader(gui,voxelWiseButton) config -state normal 
    } else {
        $FSLReader(gui,voxelWiseButton) config -state disabled 
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderUpdateEnableTimecourseButton-back
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderUpdateEnableTimecourseButton-back {} {
    global FSLReader 

    # At this point, the checkbutton has been updated in interface
    # but FSLReader(timeCourse) still holds old value, which will be updated 
    # when this function is done.

    set v $FSLReader(timeCourse)
    set v [expr {$v == 1 ? 0 : 1}]
    if {$v == 1} {
        $FSLReader(gui,enableTimecourseButton) config -state normal 
    } else {
        $FSLReader(gui,enableTimecourseButton) config -state disabled 
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderDisplayVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderDisplayVolume {where volName} {
    global FSLReader Volume

    if {$volName != "none"} {
        set id [MIRIADSegmentGetVolumeByName $volName] 

        # set the lower threshold to 1
        Volume($id,node) AutoThresholdOff
        Volume($id,node) ApplyThresholdOn
        Volume($id,node) SetLowerThreshold 1
    } else {
        set id $Volume(idNone)
    }

    MainSlicesSetVolumeAll $where $id
    MainVolumesSetActive $id
    MainVolumesRender
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderSetPlottingOption
# Switches time series plotting options 
# .ARGS
# string option the option to be set 
# .END
#-------------------------------------------------------------------------------
proc FSLReaderSetPlottingOption {option} {
    global Volume FSLReader 

    # If a time series has been loaded
    if {$option == "Yes" &&
        ! ([info exists FSLReader(firstMRMLid)] && 
           [info exists FSLReader(lastMRMLid)])} {
 
        DevErrorWindow "Please load a time series first."
        return
    }

    # configure menubutton
    $FSLReader(gui,mbPlottingOption) config -text $option
    set FSLReader(tcPlottingOption) $option
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderUpdateOverlays
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderUpdateOverlays {} {
    global FSLReader 

    $fMRIEngine(gui,conditionsMenuForSignal) delete 0 end 
    set start 1
    set end $fMRIEngine(noOfSpecifiedRuns)

    set firstCondition ""
    set i $start
    while {$i <= $end} {
        if {[info exists fMRIEngine($i,conditionList)]} {  
            set len [llength $fMRIEngine($i,conditionList)]
            set count 0
            while {$count < $len} {
                set title [lindex $fMRIEngine($i,conditionList) $count]
                set l "r$i:$title"
                $fMRIEngine(gui,conditionsMenuForSignal) add command -label $l  \
                    -command "fMRIEngineSelectConditionForSignalModeling $l"
                if {$firstCondition == ""} {
                    set firstCondition $l
                }

                incr count
            }
        }

        incr i 
    }

    if {$firstCondition == ""} {
        set firstCondition "none"
        $fMRIEngine(gui,conditionsMenuForSignal) add command -label "none"  \
            -command "fMRIEngineSelectConditionForSignalModeling none"
    }

    fMRIEngineSelectConditionForSignalModeling $firstCondition 
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderSetFSLDir
# Sets FSL output directory 
# .ARGS
# string option where to call
# path pathName the input where the FSL output directory to be derived
# .END
#-------------------------------------------------------------------------------
proc FSLReaderSetFSLDir {option {pathName ""}} {
    global FSLReader Volume
   
    if {$option == "1"} {
        set FSLReader(featDir) \
            [tk_chooseDirectory -initialdir $Volume(DefaultDir)]
    } else {
        if {! [file exists $pathName]} {
            set dir ""
            return
        } else {
            set dir [file dirname $pathName] 
        }
        set FSLReader(featDir) $dir
    }

    if {$FSLReader(featDir) == ""} {

        set FSLReader(htmlFile) "" 
        set FSLReader(tcFileName) "" 
        set FSLReader(fgFileName) "" 
        set FSLReader(bgFileName) "" 
    } else {
        set FSLReader(htmlFile) [file join $FSLReader(featDir) report.html]
        set FSLReader(tcFileName) [file join $FSLReader(featDir) \
            filtered_func_data.hdr]
    }
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderLaunchBrowser
# Launch a specified browser to view html doc 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderLaunchBrowser {} {
    global FSLReader

    if {! [info exists FSLReader(htmlFile)]} {
        DevErrorWindow "Input the report file."
        return
    }
    if {[string trim $FSLReader(htmlFile)] == ""} {
        DevErrorWindow "Input the report file."
        return
    }
    if {[file exists $FSLReader(htmlFile)] == 0} {
        DevErrorWindow "Report doesn't exist: $FSLReader(htmlFile)."
        return
    }

    set protocol "file://"
    set browserUrl $protocol$FSLReader(htmlFile)
    set browser [string trim $FSLReader(browser)] 
    if {$browser == ""} {
        DevErrorWindow "Input your valid web browser name (e.g. mozilla) on your platform."
        return
    }

    catch {exec $browser $browserUrl &}
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderBuildVTK {} {

}


#-------------------------------------------------------------------------------
# .PROC FSLReaderEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderEnter {} {
    global FSLReader
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    # pushEventManager $FSLReader(eventManager)

    # clear the text box and put instructions there
    # $FSLReader(textBox) delete 1.0 end
    # $FSLReader(textBox) insert end "Shift-Click anywhere!\n"

    FSLReaderPushBindings
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    # popEventManager
    FSLReaderPopBindings
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderPushBindings 
# Pushes onto the event stack a new event manager that
# deals with events when the FSLReader module is active
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderPushBindings {} {
   global Ev Csys

    EvActivateBindingSet FSLSlice0Events
    EvActivateBindingSet FSLSlice1Events
    EvActivateBindingSet FSLSlice2Events
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderPopBindings 
# Removes bindings when FSLReader module is inactive
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderPopBindings {} {
    global Ev Csys

    EvDeactivateBindingSet FSLSlice0Events
    EvDeactivateBindingSet FSLSlice1Events
    EvDeactivateBindingSet FSLSlice2Events
}


#-------------------------------------------------------------------------------
# .PROC FSLReaderCreateBindings  
# Creates FSLReader event bindings for the three slice windows 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FSLReaderCreateBindings {} {
    global Gui Ev

    EvDeclareEventHandler FSLReaderSlicesEvents <1> \
        {FSLReaderPopUpPlot %x %y}
            
    EvAddWidgetToBindingSet FSLSlice0Events $Gui(fSl0Win) {FSLReaderSlicesEvents}
    EvAddWidgetToBindingSet FSLSlice1Events $Gui(fSl1Win) {FSLReaderSlicesEvents}
    EvAddWidgetToBindingSet FSLSlice2Events $Gui(fSl2Win) {FSLReaderSlicesEvents}    
}


