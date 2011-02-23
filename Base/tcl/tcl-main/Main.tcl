#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Main.tcl,v $
#   Date:      $Date: 2006/07/27 18:30:00 $
#   Version:   $Revision: 1.133 $
# 
#===============================================================================
# FILE:        Main.tcl
# PROCEDURES:  
#   BootSlicer mrmlFile
#   MainInit
#   MainBuildVTK
#   MainBuildGUI
#   MainRebuildModuleGui ModuleName
#   MainBuildModuleTabs ModuleName
#   MainCheckScrollLimits args
#   MainUpdateMRML
#   MainAddActor a
#   MainAddModelActor m
#   MainRemoveActor a
#   MainRemoveModelActor m
#   MainSetup sceneNum
#   IsModule m
#   Tab m row tab
#   MainSetScrollbarHeight reqHeight
#   MainSetScrollbarVisibility vis
#   MainResizeDisplayFrame
#   MainStartProgress
#   MainShowProgress filter
#   MainEndProgress
#   MainMenu menu command
#   MainExitQuery
#   MainSaveMRMLQuery 
#   MainExitProgram code
#   Distance aArray bArray
#   Normalize aArray
#   Cross aArray bArray cArray
#   ParseCVSInfo module args
#   FormatCVSInfo versions
#   FormatModuleInfo
#   FormatModuleCredits
#   FormatModuleCategories
#   MainBuildCategoryIDLists
#   MainBuildCategoryMenu
#==========================================================================auto=


#-------------------------------------------------------------------------------
# IMPORTANT VARIABLES and Classes
#
# Please add to this list as you find them.
#-------------------------------------------------------------------------------
#  Slicer is a vtkMrmlSlicer Class.
#  Magwin refers to the close-up window in the toolbox.
#  Volume(id,vol) is a Volume Class
#  Volume(id,??) is an array of tons of useful variables for each Volume.
#  Slice(id,??) information about the 3 slice viewing windows. See Slice.tcl


#-------------------------------------------------------------------------------
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
# Abrieviations:
# ren  renderer
# dir  direction
# nav  navigation
# win  window
# mag  magnification
# cmd  command
# vol  volume
# id   identification number
# cam  camera
# obj  object
# perp perpendicular
# grnd ground
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC BootSlicer
# 
#  Boots the slicer: the first procedure called.
#  <ul>
#  <li>Hides the TK Window
#  <li>Inits global variables
#  <li>Builds VTK Graphics
#  <li>Builds the GUI
#  </ul>
# .ARGS
# str mrmlFile optional name of a MRML file to load 
# .END
#-------------------------------------------------------------------------------
proc MainBoot {{mrmlFile ""}} {
    global Module Gui Anno View Slice viewWin verbose

    set mrmlFile [file normalize $mrmlFile] ;# remove backslashes on windows

    # See which module prevents a slice window from rendering
    set checkSliceRender 0

    # Hide default TK window
    wm withdraw .

    #-------------------------------------------
    # Initialize global variables
    #-------------------------------------------
    MainInit

    # Build the Viewer window before doing anything else to see if that helps
    # with the apparent OpenGL bug on Windows98 version 2

    vtkMrmlSlicer Slicer

    Slicer SetFieldOfView $View(fov)

    vtkRenderer viewRen
    lappend Module(Renderers) viewRen
    set View(viewCam) [viewRen GetActiveCamera]

    MainViewerBuildGUI

    # Module Init
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info command ${m}Init] != ""} {
            if {$Module(verbose) == 1} {
                puts "INIT: ${m}Init"
            }
            ${m}Init
        }
    }

    #-------------------------------------------
    # Check module dependencies.
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,depend)] == 1} {
            foreach d $Module($m,depend) {
                if {[lsearch "$Module(idList) $Module(sharedList)" $d] == -1} {
                    tk_messageBox -message "\
The '$m' module depends on the '$d' module, which is not present.\n\
Unexpected behaviour may occur."
# Slicer will exit so the problem can be corrected."
                    # exit
                }
            }
        }
    }

    #-------------------------------------------
    # Record default presets
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,presets)] == 1} {
            MainOptionsParseDefaults $m
        }
    }

    #-------------------------------------------
    # Build VTK Graphics and Imaging Pipelines
    #-------------------------------------------
    MainBuildVTK

    # Module VTK 
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,procVTK)] == 1} {
            if {$Module(verbose) == 1} {
                puts "VTK: $m"
            }
            $Module($m,procVTK)
        }
    }

    #-------------------------------------------
    # Build GUI
    #-------------------------------------------
    MainBuildGUI
    
    foreach p "MainViewBuildGUI MainModelsBuildGUI $Module(procGUI)" {
        if {$Module(verbose) == 1} {
            puts "GUI: $p"
        }
        $p
    }
    MainViewSetFov


    # Debuging the slice rendering (no longer necessary)
    if {$checkSliceRender == 1} {
        Anno(0,curBack,actor) SetVisibility 1
        set i 0
    }

    # Module GUI
    #-------------------------------------------
    foreach m $Module(idList) {
        # See if the module has a GUI callback procedure
        if {[info exists Module($m,procGUI)] == 1} {
            if {$Module(verbose) == 1} {
                puts "GUI: $Module($m,procGUI)"
            }
            $Module($m,procGUI)
        }
        if {$checkSliceRender == 1} {
            incr i
            Anno(0,curBack,mapper) SetInput $i
            RenderAll
            tk_messageBox -message "$i $m"
        }
    }

    
    #-------------------------------------------
    # Read user options from Options.xml
    #-------------------------------------------
    set fileName [ExpandPath "Options.xml"]
    if {[CheckFileExists $fileName 0] == "1"} {
        puts "MainBoot: Reading $fileName"
        set tags [MainMrmlReadVersion2.0 $fileName]
        if {$tags != "0"} {
            # Apply the presets immediately rather than 
            # putting them on the tree.
            foreach pair $tags {
                set tag  [lindex $pair 0]
                set attr [lreplace $pair 0 0]
                if {$tag == "Options"} {
                    foreach a $attr {
                        set key [lindex $a 0]
                        set val [lreplace $a 0 0]
                        switch $key {
                            "options"      {set options $val}
                            "program"      {set program $val}
                            "contents"     {set contents $val}
                        }
                    }
                    if {$program == "slicer" && $contents == "presets"} {
                        MainOptionsParsePresets $attr
                    }
                }
            }
        }
    }
    if {$verbose} {
        puts "Done Reading $fileName"; update
    }

    # detect an archive as an argment
    # - unpack it to a tmp directory and open an xml file in it

    set tmpdir ""
    if { [string match "*.zip" $mrmlFile] } {
        # unzip to temp directory, 
        if { [catch "package require vfs"] } {
            DevWarningWindow "Zipfile archive on command line not supported."
        } else {
            # need to source -- package require zipvfs broken in ActiveTcl8.4.1
            global env
            source $env(TCL_LIB_DIR)/vfs1.0/zipvfs.tcl
            ::vfs::zip::Mount $mrmlFile zipfile
            
            if { [info exists env(TMP)] } { set tmpdir [file normalize $env(TMP)] }
            if { [info exists env(TEMP)] } { set tmpdir [file normalize $env(TEMP)] }
            if { $tmpdir == "" } { 
                DevErrorWindow "No TMP or TEMP environment variable.  Can't open zip archive."
                exit
            } 
            if { [catch "file mkdir $tmpdir/slicer.[pid]"] } {
                DevErrorWindow "Can't make tmp dir.  Can't open zip archive."
                exit
            } 
            if {$verbose} {
                puts "Copying from $mrmlFile to $tmpdir/slicer.[pid]"
            }
            if { [catch "file copy zipfile $tmpdir/slicer.[pid]" res] } {
                DevErrorWindow "Can't copy to tmp dir.  $res."
                exit
            } 
            # made it here, must be okay
            set mrmlFile $tmpdir/slicer.[pid]/zipfile

            # look for a single directory in the zip archive, if so, use it
            set listing [glob -nocomplain $mrmlFile/*]
            if { [llength $listing] == 1 } {
                set mrmlFile [lindex $listing 0]
            }

            # should be:
            # ::vfs::zip::Mount $mrmlFile zipfile
            # but this works instead:
            ::vfs::filesystem unmount zipfile
        }
    }

    #-------------------------------------------
    # Load MRML data
    # - if a file, load it
    # - if a dir, load single xml file if it exists
    #             else save the dir and try to load dicom files from it
    # - if nothing, set some defaults
    #-------------------------------------------    
    update ;# draw the UI before loading the file
    if { [file isdirectory $mrmlFile] } {
        set mrmlfiles [glob -nocomplain -directory $mrmlFile *.xml]
        if { [llength $mrmlfiles] == 1 } {
            if { $verbose } {
                puts "Found [lindex $mrmlfiles 0] in $mrmlFile"
            }
            set mrmlFile [lindex $mrmlfiles 0]
        } else {
            set ::SLICER(load-dicom) $mrmlFile
            set mrmlFile ""
        }
    }
    if {$verbose} {
        puts "Initializing MRML..."; update
    }
    MainMrmlRead $mrmlFile
    MainUpdateMRML
    MainOptionsRetrievePresetValues

    if { $tmpdir != "" } {
        # clean up data extracted from archive
        if { $verbose } {
            puts "Removing $tmpdir/slicer.[pid]"
        }
        file delete -force $tmpdir/slicer.[pid]
    }

    #-------------------------------------------
    # Initialize the Program State
    #-------------------------------------------
    if {$verbose} {
        puts "MainSetup..."; update
        set sceneOptions [vtkMrmlSceneOptionsNode ListInstances]
        puts "MainBoot: scene options nodes = $sceneOptions\n\tscene options list = $::SceneOptions(idList)\n\tcurrent scene = $::Scenes(currentScene)\n\tCalling MainSetup now with current scene"
    }
    MainSetup $::Scenes(currentScene)
    if {$verbose} {
        puts "RenderAll..."; update
    }
    RenderAll

    #-------------------------------------------
    # Initial tab
    #-------------------------------------------
    $Gui(lBoot) config -text ""

    
    if {$Module(activeID) == ""} {
        Tab [lindex $Module(idList) 0]
    }
    bind .tViewer <Configure> "MainViewerUserResize"
    puts "Ready"

}
    
#-------------------------------------------------------------------------------
# .PROC MainInit
#
# Sets path names.
# Calls the GuiInit.
# Calls all the Init of the Tabs.
# .END
#-------------------------------------------------------------------------------
proc MainInit {} {
    global Module Gui env Path View Anno Mrml
    
    set Path(tmpDir) tmp 
    set Path(printHeaderPath) bin/print_header
    set Path(printHeaderFirstWord) print_header
    set Path(remoteHost) forest

    # Set the Mrml(dir) only if the user hasn't done this already
    # (like in the startup script)
    if {[info exists Mrml(dir)] == 0} {
        set Mrml(dir) [pwd]
    }

    GuiInit
    puts "Launching $Gui(title)..."

    # If paths are relative, then make them rooted to Slicer's home
    set Path(printHeaderPath) \
        [file join $Path(program) $Path(printHeaderPath)]
    set Path(tmpDir) \
        [file join $Path(program) $Path(tmpDir)]

    # Initialize Module info
    #-------------------------------------------
    set Module(activeID) ""
    set Module(freezer) ""

    # In each module's Init procedure, set Module(moduleName,category) to one of these strings.
    # If you use lindex, larger indices will indicate less tested modules.
    # set Module(categories) {Core Beta Experimental Example Unfiled}
    set Module(categories) {Favourites Settings IO Application Filtering Segmentation Registration Measurement Visualisation Example Unfiled All}
    # set Module(categories) {Data Processing Settings Other Unfiled}
    foreach m $Module(idList) {
        set Module($m,more) 0
        set Module($m,row1List) ""
        set Module($m,row1Name) ""
        set Module($m,row1,tab) ""
        set Module($m,row2List) ""
        set Module($m,row2Name) ""
        set Module($m,row2,tab) ""
        set Module($m,row) row1
    }
    set Module(procInit) ""
    set Module(procGUI)  ""
    set Module(procVTK)  ""
    set Module(procMRML) ""
    set Module(procStorePresets) ""
    set Module(procRecallPresets) ""
    # for recording user actions during segmentation trials
    set Module(procSessionLog) ""
    set Module(Renderers) ""

    set Module(.tMain.fControls,height) 420
    # the minimum height of all frames contained in .tMain.fControls
    set Module(.tMain.fControls,scrolledHeight) 396
    set Module(.tMain.fControls,winsMinWidth) 239
    set Module(scrollIncr) 10

        # Set version info
    lappend Module(versions) [ParseCVSInfo Main \
        {$Revision: 1.133 $} {$Date: 2006/07/27 18:30:00 $}]

    # Call each "Init" routine that's not part of a module
    #-------------------------------------------
    foreach m "$Module(mainList) $Module(sharedList)" {
        if {[info command ${m}Init] != "" && $m != "Main"} {
            if {$Module(verbose) == 1} {
                puts "INIT: ${m}Init"
            }
            ${m}Init
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainBuildVTK
#
# Creaters the instance of vtkMrmlSlicer: Slicer. 
# Inits the Slicer: FieldofView, NoneVolume and LabelWL (a lookup table).
# Creates the vtk Renderer.
# Puts purple sphere at origin of 3D window.
# Calls each Tab's BuildVTK: The VTK Pipeline.
# .END
#-------------------------------------------------------------------------------
proc MainBuildVTK {} {
    global Module View Gui Lut

    # Call each "BuildVTK" routine that's not part of a module
    #-------------------------------------------
    foreach p $Module(procVTK) {
        if {$Module(verbose) == 1} {
            puts "VTK: $p"
        }
        $p
    }
    if {$Module(verbose) == 1} {
        puts MainAnnoBuildVTK
    }
    MainAnnoBuildVTK
    
    # Now that the MainLut non-module has built the indirectLUT,
    # I can set it in the Slicer object.
    Slicer SetLabelIndirectLUT Lut($Lut(idLabel),indirectLUT)
}

#-------------------------------------------------------------------------------
# .PROC MainBuildGUI
#
# This is the Main GUI. 
# It Creates all tabs and packs them appropriately.
# .END
#-------------------------------------------------------------------------------
proc MainBuildGUI {} {
    global Gui fViewBtns viewWin Module Slice View
    
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Main Window
    #   Modules
    #   Controls
    #     Tabs
    #     Workspace
    #   Display
    #         Right
    #         Left
    #           Image
    #             MagBorder
    #             Nav
    #   Status
    #-------------------------------------------

    #-------------------------------------------
    # Main Window
    #-------------------------------------------
    set f .tMain

    toplevel     $f -bg $Gui(backdrop)
    wm title     $f $Gui(title) 
    wm resizable $f  1 1
    wm geometry  $f +0+0
    wm protocol $f WM_DELETE_WINDOW "MainExitQuery"

    # Status bar dimensions

    frame $f.fModules  -bd $Gui(borderWidth) -bg $Gui(backdrop)
    frame $f.fControls -bd $Gui(borderWidth) -bg $Gui(backdrop) -height $Module(.tMain.fControls,height)
    frame $f.fDisplay  -bd $Gui(borderWidth) -bg $Gui(backdrop)
    frame $f.fStatus   -bd $Gui(borderWidth) -bg $Gui(inactiveWorkspace) \
        -relief sunken

    # When the mouse enters the display area, show the View controls
    # instead of the welcome image
    bind .tMain.fDisplay <Enter>  "MainViewSetWelcome Controls"

    bind .tMain.fModules  <Enter>  "MainViewSetWelcome Welcome"
    bind .tMain.fControls <Enter>  "MainViewSetWelcome Welcome"
    bind .tMain.fStatus   <Enter>  "MainViewSetWelcome Welcome"

    pack $f.fModules  -side top -expand 1 -fill both -padx 0 -pady 3
    pack $f.fControls -side top -expand 1 -fill both -padx 0 -pady 0
    pack $f.fDisplay  -side top -expand 1 -fill both -padx 0 -pady 0
    pack $f.fStatus   -side top -expand 1 -fill both -padx 0 -pady 0
    pack propagate $f.fControls  false

    #-------------------------------------------
    # System Menu
    #-------------------------------------------
    set f .tMain

    menu .menubar
    # attach it to the main window
    $f config -menu .menubar
    # Create more cascade menus
    foreach m {File View Help} {
        eval {menu .menubar.m$m} $Gui(SMA)
        set Gui(m$m) .menubar.m$m
        .menubar add cascade -label $m -menu .menubar.m$m
    }

    if {$::Module(verbose)} {
        set m Modules
        eval {menu .menubar.m$m} $Gui(SMA)
        set Gui(m$m) .menubar.m$m
        .menubar add cascade -label $m -menu .menubar.m$m
    }

    # File menu
    $Gui(mFile) add command -label "Open Scene..." -command \
        "MainMenu File Open"
    $Gui(mFile) add command -label "Import Scene..." -command \
        "MainMenu File Import"
    $Gui(mFile) add command -label "Save Scene" -command \
        "MainMenu File Save"
    $Gui(mFile) add command -label "Save Scene As..." -command \
        "MainMenu File SaveAs"
    $Gui(mFile) add command -label "Save Scene With Options" -command \
        "MainMenu File SaveWithOptions"
    $Gui(mFile) add separator
    $Gui(mFile) add command -label "Save Current Options" -command \
        "MainMenu File SaveOptions"
    $Gui(mFile) add separator
    $Gui(mFile) add command -label "Save 3D View" -command \
        "MainMenu File Save3D"
    $Gui(mFile) add command -label "Set Save 3D View Parameters..." -command \
        "MainMenu File Save3DSetParams"
    $Gui(mFile) add command -label "Save Active Slice" -command \
        "MainMenu File SaveSlice"
    $Gui(mFile) add command -label "Save Active Slice As..." -command \
        "MainMenu File SaveSliceAs"
    $Gui(mFile) add separator
    $Gui(mFile) add command -label "Close" -command \
        "MainMenu File Close"
    $Gui(mFile) add command -label "Exit" -command MainExitQuery

    # View Menu
    $Gui(mView) add command -label "Normal" -command \
        "MainMenu View Normal"
    $Gui(mView) add command -label "3D" -command \
        "MainMenu View 3D"
    $Gui(mView) add command -label "4x512" -command \
        "MainMenu View Quad512"
    $Gui(mView) add command -label "1x512" -command \
        "MainMenu View Single512"
    $Gui(mView) add command -label "1x512 COR" -command \
        "MainMenu View Single512COR"
    $Gui(mView) add command -label "1x512 SAG" -command \
        "MainMenu View Single512SAG"
    $Gui(mView) add command -label "4x256" -command \
        "MainMenu View Quad256"
    $Gui(mView) add command -label "MRT big SagCor" -command \
        "MainMenu View MRT"
    $Gui(mView) add command -label "MRT small" -command \
       "MainMenu View MRT640x480"
    $Gui(mView) add separator
    $Gui(mView) add command -label "Large Image..." -command \
        "MainMenu View LargeImage"
    $Gui(mView) add separator
    $Gui(mView) add command -label "Black" -command \
        "MainViewSetBackgroundColor Black; Render3D"
    $Gui(mView) add command -label "Blue" -command \
        "MainViewSetBackgroundColor Blue; Render3D"
    $Gui(mView) add command -label "Midnight" -command \
        "MainViewSetBackgroundColor Midnight; Render3D"
    $Gui(mView) add command -label "White" -command \
        "MainViewSetBackgroundColor White; Render3D"

    # Help menu
    $Gui(mHelp) add command -label "Show Splash Screen" -command \
        "SplashShow cancel; after 5000 SplashKill" ;# stay up for 5 seconds
    $Gui(mHelp) add command -label "About..." -command \
        "MainMenu Help About"
    $Gui(mHelp) add command -label "Documentation..." -command \
        "MainMenu Help Documentation"
    $Gui(mHelp) add command -label "Copyright..." -command \
        "MainMenu Help Copyright"
    $Gui(mHelp) add command -label "Version Info..." -command \
        "MainMenu Help Version"
    $Gui(mHelp) add command -label "Module Summaries..." -command \
        "MainMenu Help Modules"
    $Gui(mHelp) add command -label "Module Credits..." -command \
        "MainMenu Help Credits"
    $Gui(mHelp) add command -label "Module Categories..." -command \
        "MainMenu Help Categories"
    $Gui(mHelp) add command -label "Turn Tooltips Off/On" -command \
        "TooltipToggle"
    
    #-------------------------------------------
    # Main->Module Frame
    #-------------------------------------------
    set f .tMain.fModules

    frame $f.fBtns -bg $Gui(backdrop)
    frame $f.fMore -bg $Gui(backdrop)
    pack $f.fBtns $f.fMore -side top -pady 1

    #-------------------------------------------
    # Main->Modules->More frame
    #-------------------------------------------
    set f .tMain.fModules.fMore

    # Have some buttons visible, and hide the rest under "More", if necessary
    set cnt 0
    set maxVisibleButtons 6
    set maxMoreButtonStringLength 10
    set Module(more) 0
    foreach m $Module(idList) {
        set Module($m,more) 0
        if {$cnt >= $maxVisibleButtons} {
            set Module($m,more) 1
            # set the flag to create the More button
            set Module(more) 1
            if {[string length $m] > $maxMoreButtonStringLength} {
                set maxMoreButtonStringLength [string length $m]
            }
        }
        incr cnt
    }        

    if {$Module(more) == 1} {
        eval {menubutton $f.mbMore -text "More:" -relief raised -bd 2 \
                  -width 6 -menu $f.mbMore.m} $Gui(WMBA)
        eval {menu $f.mbMore.m} $Gui(WMA)
        set Module(mbMore) $f.mbMore
        TooltipAdd $f.mbMore "More module menu"
        eval {radiobutton $f.rMore -width $maxMoreButtonStringLength \
            -text "None" -variable Module(moreBtn) -value 1 \
            -command "Tab Menu" -indicatoron 0} $Gui(WCA)
        set Module(rMore) $f.rMore
        pack $f.mbMore $f.rMore -side left -padx $Gui(pad) -pady 0 

        set Module(mbMore) $f.mbMore
        set Module(rMore)  $f.rMore
    }


    # Modules Menu - delayed till here, for now, so that can change the text on Module(rMore) 
    MainBuildCategoryIDLists
    MainBuildCategoryMenu
        


    # Add the arrow image (the one that makes the scrollbar appear) 
    # at the end of the row 
    set Module(scrollbar,image) [image create photo -file \
        [ExpandPath [file join gui moduleArrows.gif]]]
    
    set Module(scrollbar,visible) 0
    eval {checkbutton $f.bDn -image $Module(scrollbar,image) -variable Module(scrollbar,visible) -width 10 -indicatoron 0 -command "MainSetScrollbarVisibility" -height 20} $Gui(WBA)
    
    # Tooltip example: Add a tooltip for the image checkbutton
    TooltipAdd $f.bDn "Press this button to show a scrollbar for the panel below. \n The scrollbar automatically adjusts to the height of the panel. "

    pack $f.bDn -side right -padx 15
    
    #-------------------------------------------
    # Main->Modules->Btns frame
    #-------------------------------------------
    set f .tMain.fModules.fBtns

    set row 0
    if {$Module(more) == 1} {
        set moreMenu $Module(mbMore).m
        $moreMenu delete 0 end
        set firstMore ""
    }


    # Display up to 3 module buttons (m1,m2,m3) on each row 
    foreach {m1 m2 m3} $Module(idList) {
        frame $f.$row -bg $Gui(inactiveWorkspace)

        foreach m "$m1 $m2 $m3" {
            # Either make a button for it, or add it to the "more" menu
            if {$Module($m,more) == 0} {
                eval {radiobutton $f.$row.r$m -width 10 \
                    -text "$m" -variable Module(btn) -value $m \
                    -command "Tab $m" -indicatoron 0} $Gui(WRA)
                pack $f.$row.r$m -side left -padx 0 -pady 0

                # if {$::Module(verbose)} {
                  #  if {[info exists Module($m,overview)]} {
                  #      TooltipAdd  $f.$row.r$m $Module($m,overview)
                  #  }
                # }
            } else {
                if {$firstMore == ""} {
                    set firstMore $m
                }
                if { [info exists Module($m,procGUI)] } {
                    # only add module to menu if it has a GUI
                    $moreMenu add command -label $m \
                        -command "set Module(btn) More; Tab $m; \
                        $Module(rMore) config -text $m"
                    
                }
            }
        }
        pack $f.$row -side top -padx 0 -pady 0

        incr row
    }
    if {$Module(more) == 1} {
        $Module(rMore) config -text "$firstMore"
    }


    #-------------------------------------------
    # Main->Controls Frame
    #-------------------------------------------
    set f .tMain.fControls
    
    frame $f.fTabs -bg $Gui(inactiveWorkspace) -height 20
    set Module(canvas) $f.fWorkspace
    set s $f.fWorkspace.fScroll
        canvas $Module(canvas) -yscrollcommand "$s set" -bg $Gui(activeWorkspace)
        eval { scrollbar $s -command "MainCheckScrollLimits $Module(canvas) yview" } $Gui(WSBA)
    
    # default scroll
        $Module(canvas) config -scrollregion "0 0 1 $Module(.tMain.fControls,scrolledHeight)"
    $Module(canvas) config -yscrollincrement $Module(scrollIncr) -confine true
    
    pack $f.fTabs -side top -fill x        
    pack $s -side right -fill y
    lower $s 
    set Module(scrollbar,widget) $s
    pack $Module(canvas) -expand true -side top -fill both
    
    set Gui(fTabs) $f.fTabs

    #-------------------------------------------
    # Main->Controls->Tabs Frame
    #-------------------------------------------
    set fWork .tMain.fControls.fWorkspace
    set f .tMain.fControls.fTabs


    foreach m $Module(idList) {
            MainBuildModuleTabs $m
    }

    # Blank page to show during boot 

    frame $fWork.fBoot -bg $Gui(activeWorkspace)
    eval {label $fWork.fBoot.l -width 232 -height 396 -text "Loading data..." -justify center} $Gui(WLA)
    set Gui(lBoot) $fWork.fBoot.l
    pack $fWork.fBoot.l 
    place $fWork.fBoot -in $fWork -relheight 1.0 -relwidth 1.0

    
    #-------------------------------------------
    # Main->Display Frame
    #-------------------------------------------
    set f .tMain.fDisplay

    frame $f.fLeft  -bg $Gui(backdrop)
    frame $f.fRight -bg $Gui(backdrop)
    pack $f.fRight $f.fLeft -side left -padx 2 -expand 1 -fill both

    #-------------------------------------------
    # Main->Display->Left Frame
    #-------------------------------------------
    set f .tMain.fDisplay.fLeft

    frame $f.fImage -bg $Gui(inactiveWorkspace) -width 179 -height 179
    pack $f.fImage -side top -padx 3 -pady 3 

    #-------------------------------------------
    # Main->Display->Left->Image Frame
    #-------------------------------------------
    set f .tMain.fDisplay.fLeft.fImage

    foreach name "MagBorder Nav Welcome" {
        frame $f.f$name -bg $Gui(inactiveWorkspace) -bd $Gui(borderWidth) \
            -relief sunken
        set Gui(f$name) $f.f$name
        place $f.f$name -in $f -relwidth 1.0 -relheight 1.0
    }
    raise $Gui(fWelcome)

    #-------------------------------------------
    # Main->Display->Left->Image->Welcome Frame
    #-------------------------------------------
    set f .tMain.fDisplay.fLeft.fImage.fWelcome

    image create photo iWelcome \
        -file [ExpandPath [file join gui "welcome.ppm"]]
    eval {label $f.lWelcome -image iWelcome  \
        -width $Gui(magDim) -height $Gui(magDim) -anchor w} $Gui(WLA)
    pack $f.lWelcome

    #-------------------------------------------
    # Main->Display->Left->Image->MagBorder Frame
    #-------------------------------------------
    set f .tMain.fDisplay.fLeft.fImage.fMagBorder

    if {$View(createMagWin) == "Yes"} {
        MakeVTKImageWindow mag 

        vtkTkRenderWidget $f.fMag -rw magWin \
            -width $Gui(magDim) -height $Gui(magDim)  
        bind $f.fMag <Expose> {ExposeTkImageViewer %W %x %y %w %h}
        pack $f.fMag
    }

    #-------------------------------------------
    # Main->Display->Left->Image->Nav Frame
    #-------------------------------------------
    set f .tMain.fDisplay.fLeft.fImage.fNav

    # This is constructed in MainView.tcl

    #-------------------------------------------
    # Main->Display->Right frame
    #-------------------------------------------
    set f .tMain.fDisplay.fRight
    
    
    # Exit button
    #-------------------------------------------
    eval {button $f.bExit -text Exit -width 5 \
        -command "MainExitQuery"} $Gui(WBA)
    set Gui(bExit) $f.bExit

    # Opacity Slider
    #-------------------------------------------
    eval {scale $f.sOpacity -from 1.0 -to 0.0 -variable Slice(opacity) \
        -command "MainSlicesSetOpacityAll; RenderAll" \
        -length 80 -resolution 0.1} $Gui(BSA) {-sliderlength 30  \
        -troughcolor [MakeColorNormalized ".7 .7 .9"]}

    TooltipAdd $f.sOpacity "Slice overlay slider: Fade from\n\
        the Foreground to the Background slice."

    # Toggle button
    #-------------------------------------------
    eval {button $f.bToggle -text Toggle -width 6 \
        -command "MainSlicesSetOpacityToggle; RenderAll"} $Gui(WBA)

    # Fade button
    #-------------------------------------------
    eval {checkbutton $f.cFade \
        -text Fade -variable Slice(fade) \
        -width 5 -indicatoron 0 \
        -command "MainSlicesSetFadeAll; RenderAll"} $Gui(WCA)

    pack $f.bExit $f.sOpacity $f.bToggle $f.cFade -side top -pady $Gui(pad)

    #-------------------------------------------
    # Main->Status Frame
    #-------------------------------------------
    set f .tMain.fStatus
    

    # Add the arrow image (the one that makes the scrollbar appear) 
    # at the end of the row 
    set Module(scrollbar,image) [image create photo -file \
        [ExpandPath [file join gui moduleArrows.gif]]]
    
    eval {checkbutton $f.bDn -image $Module(scrollbar,image) -variable Module(display,lowered) -width 10 -indicatoron 0 -command "MainResizeDisplayFrame" -height 20} $Gui(WBA)
    
    # Tooltip example: Add a tooltip for the image checkbutton
    TooltipAdd $f.bDn "Press this button to lower or raise the frame above"

    set Gui(fStatus) $f
    canvas $f.canvas -borderwidth 0 -highlightthickness 0 \
        -width 222 -height 20
    pack $f.bDn -side left
    pack $f.canvas -side left -expand 1 -fill both

    foreach p "MainAnnoBuildGUI " {
        if {$Module(verbose) == 1} {
            puts "GUI: $p"
        }
        $p
    }
}

#-------------------------------------------------------------------------------
# .PROC MainRebuildModuleGui
# 
# Erase the old Gui for a module and build a new one.
# Should call MainUpdateMRML when done so that the Module
# has the correct Volumes, Models, etc. listed.
#
# This primarily exists for the tester.
#
# .ARGS
# str ModuleName The name of the module
# .END
#-------------------------------------------------------------------------------
proc MainRebuildModuleGui {ModuleName} {
    global Module Gui

    if {[info exists Module($ModuleName,row1List)] == 1} {
        foreach frame $Module($ModuleName,row1List) {
            set f $Module($ModuleName,f$frame)
            catch {destroy $f}
        }
    }

    if {[info exists Module($ModuleName,row1List)] == 1} {
        foreach frame $Module($ModuleName,row2List) {
            set f $Module($ModuleName,f$frame)
            catch {destroy $f}
        }
    }

    set m $ModuleName
    set fWork .tMain.fControls.fWorkspace
    set f .tMain.fControls.fTabs

    catch {destroy $f.f${m}row1}
    catch {destroy $f.f${m}row2}
    MainBuildModuleTabs $ModuleName
    $Module($ModuleName,procGUI)
}

#-------------------------------------------------------------------------------
# .PROC MainBuildModuleTabs
# 
# Builds the Tabs for a Module.
#
# .ARGS
# str ModuleName the name of the Module.
# .END
#-------------------------------------------------------------------------------
proc MainBuildModuleTabs {ModuleName}  {
    global Module Gui

    set m $ModuleName
    set fWork .tMain.fControls.fWorkspace
    set f .tMain.fControls.fTabs

    # Make page frames for each tab
    foreach tab "$Module($m,row1List) $Module($m,row2List)" {
        # create the frame for that module/tab, but don't pack it yet, 
        # it is done in MainPackModuleTabs called at the end of MainBoot 
        # once we know their required height
        frame $fWork.f${m}${tab} -bg $Gui(activeWorkspace)
        $fWork create window 0 0 -anchor nw -width $Module(.tMain.fControls,winsMinWidth) -window $fWork.f${m}${tab}     
        set Module($m,f${tab}) $fWork.f${m}${tab}
    }
    
    foreach row "row1 row2" {
        # Make tab-row frame for each row
        frame $f.f${m}${row} -bg $Gui(activeWorkspace)
        place $f.f${m}${row} -in $f -relheight 1.0 -relwidth 1.0
        set Module($m,f$row) $f.f${m}${row}
        
        foreach tab $Module($m,${row}List) name $Module($m,${row}Name) {
            set Module($m,b$tab) $Module($m,f$row).b$tab
            eval {button $Module($m,b$tab) -text "$name" \
                    -command "Tab $m $row $tab" \
                    -width [expr [string length "$name"] + 1]} $Gui(TA)
            pack $Module($m,b$tab) -side left -expand 1 -fill both
        }

        # "More..." if more than one row exists
        if {$Module($m,row2List) != ""} {
            eval {button $Module($m,f$row).bMore -text "More..." \
                    -command "Tab More"} $Gui(TA)
            pack $Module($m,f$row).bMore -side left -expand 1 -fill both
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainCheckScrollLimits
# This procedure allows scrolling only if the entire frame is not visible
# .ARGS
# list args a list containing the canvas and the view.
# .END
#-------------------------------------------------------------------------------
proc MainCheckScrollLimits {args} {
    
    set canvas [lindex $args 0]
    set view   [lindex $args 1]
    set fracs [$canvas $view]

    if {double([lindex $fracs 0]) == 0.0 && \
        double([lindex $fracs 1]) == 1.0} {
    return
    }
    eval $args
}


#-------------------------------------------------------------------------------
# .PROC MainUpdateMRML
# Call each "MRML" routine that's not part of a module, then each module's MRML routine.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainUpdateMRML {} {
    global Module Label
    
    set verbose $Module(verbose)
    set runTime 0
    set runList {}
    # use this as a flag to avoid multiple calls to Render3D, check it in that proc
    set Module(InMainUpdateMRML) 1
    # if Render3D was called, this will get reset and can call it at the end
    set Module(RenderFlagForMainUpdateMRML) 0

    # Call each "MRML" routine that's not part of a module
    #-------------------------------------------
    set runTime [time MainMrmlUpdateMRML]
    # if {$verbose == 1} {puts "MRML: MainMrml (time = $runTime)"}
    lappend runList "[format "%08d" [lindex $runTime 0]] MainMrml"

    set runTime [time MainColorsUpdateMRML]
    # if {$verbose == 1} {puts "MRML: MainColors (time = $runTime)"}
    lappend runList "[format "%08d" [lindex $runTime 0]] MainColors"

    set runTime [time MainVolumesUpdateMRML]
    # if {$verbose == 1} {puts "MRML: MainVolumes (time = $runTime)"}
    lappend runList "[format "%08d" [lindex $runTime 0]] MainVolumes"

    set runTime [time MainModelsUpdateMRML]
    # if {$verbose == 1} {puts "MRML: MainModels (time = $runTime)"}
    lappend runList "[format "%08d" [lindex $runTime 0]] MainModels"

    set runTime [time MainTetraMeshUpdateMRML]
    # if {$verbose == 1} {puts "MRML: MainTetraMesh (time = $runTime)"}
    lappend runList "[format "%08d" [lindex $runTime 0]] MainTetraMesh"

    set runTime [time MainAlignmentsUpdateMRML]
    # if {$verbose == 1} {puts "MRML: MainAlignments (time = $runTime)"}
    lappend runList "[format "%08d" [lindex $runTime 0]] MainAlignments"

    foreach p $Module(procMRML) {
        set runTime [time $p]
        # if {$verbose == 1} {puts "MRML: $p (time = $runTime)"}
        lappend runList "[format "%08d" [lindex $runTime 0]] $p"
    }

    # Call each Module's "MRML" routine
    #-------------------------------------------
    foreach m $Module(idList) {
        if {[info exists Module($m,procMRML)] == 1} {
            set runTime [time $Module($m,procMRML)]
            # if {$verbose == 1} {puts "MRML: $m (time = $runTime)"}
            lappend runList "[format "%08d" [lindex $runTime 0]] $m"
        }
    }

    set Module(InMainUpdateMRML) 0
    if {$Module(RenderFlagForMainUpdateMRML)} {
        if {$::Module(verbose)} {
            puts "Render3d got flagged, calling it now."
        }
        set runTime [time Render3D]
        lappend runList "[format "%08d" [lindex $runTime 0]] Render3D"
    }

    
    if {$::Module(verbose)} {
        set runList [lsort -decreasing $runList]
        puts "MainUpdateMRML: Top 10 longest ops:"
        for {set r 0} {$r < 10 && $r < [llength $runList]} {incr r} {
            puts "[lindex $runList $r]" 
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC MainAddActor
#  Use this method if you want to add an actor that IS NOT A MODEL.
#  If your actor is a model, use MainAddModelActor.
#
#  With this procedure, the actor is added  to all existing Renderers.
#  If you want to add your actor to a specific renderer, for example viewRen,
#  use the vtk call:
#          viewRen AddActor $actor
# .ARGS
# actor a the actor you want to add
# .END
#-------------------------------------------------------------------------------
proc MainAddActor { a } {
    global Module 
    
    foreach r $Module(Renderers) {
        $r AddActor $a
    }   
}


#-------------------------------------------------------------------------------
# .PROC MainAddModelActor
#
#  Use this method if you want to add an actor that is a model.
#  
#  With this procedure, a different actor for the same model is added to each 
#  existing Renderer. 
#  This allows each renderer to display the same models with different 
#  properties (ie we want the bladder to be visible in the Endoscopic
#  View, but not the MainView).
# .ARGS
# int m the id of the model whose actor you want to add
# .END
#-------------------------------------------------------------------------------
proc MainAddModelActor { m } {
    global Module 
    
    foreach r $Module(Renderers) {
        $r AddActor Model($m,actor,$r)
    }   
}


#-------------------------------------------------------------------------------
# .PROC MainRemoveActor
#  With this procedure, the actor is removed from all existing Renderers
# .ARGS
# actor a the actor you want to remove
# .END
#-------------------------------------------------------------------------------
proc MainRemoveActor { a } {
    global Module 

    foreach m $Module(Renderers) {
        $m RemoveActor $a
    }
}



#-------------------------------------------------------------------------------
# .PROC MainRemoveModelActor
#  With this procedure, every actor for the model is removed from all existing Renderers
# .ARGS
# int m the id of the model whose actor you want to add
# .END
#-------------------------------------------------------------------------------
proc MainRemoveModelActor { m } {
    global Module 

    foreach r $Module(Renderers) {
        $r RemoveActor Model($m,actor,$r)
    }
}


#-------------------------------------------------------------------------------
# .PROC MainSetup
# Set many settings to their saved values.
# Called when a scene (mrml file) is opened or closed, and when the
# program starts.
# .ARGS
# int sceneNum which preset set of values to restore to, 0 should be user prefs, default are system prefs
# .END
#-------------------------------------------------------------------------------
proc MainSetup { {sceneNum "default"}} {
    global Module Gui Volume Slice View Model Color Matrix Options Preset
        global TetraMesh 

    # Set current values to preset 0 (user preferences)
    # Change: preset 0 is over written by opening a mrml file, reset to system default if no scene is passed in
    if {$::Module(verbose)} { puts "MainSetup: setting to scene $sceneNum" }
    # MainOptionsRecallPresets $Preset(userOptions)
    MainOptionsRecallPresets $sceneNum

    # Set active volume
    set v [lindex $Volume(idList) 0]
    MainVolumesSetActive $v
        
    # Set FOV - is done in MainViewRecallPresets, called from MainOptionsRecallPresets
    if {0} {
        set dim     [lindex [Volume($v,node) GetDimensions] 0]
        set spacing [lindex [Volume($v,node) GetSpacing] 0]
        set fov     [expr $dim*$spacing]
        set View(fov) $fov
        # this call will reset the camera via a call to MainViewNavReset, pass it the sceneNum so it can flag that out
        if {$::Module(verbose)} { puts "Calling MainViewSetFov with $sceneNum" }
        MainViewSetFov $sceneNum
    }

    # If no volume set in all slices' background, set the active one
    set doit 1 
    foreach s $Slice(idList) {
        if {$Slice($s,backVolID) != 0} { 
            set doit 0 
        }
    }
    if {$doit == 1} {
        if {$::Module(verbose)} {
            puts "MainSetup: no back volume set, using $Volume(activeID)"
        }

        if {$sceneNum != "default"} {
            if {$::Module(verbose)} {
                puts "MainSetup: calling MainSlicesSetVolumeAll but telling it not to update the slice offsets"
            }
            MainSlicesSetVolumeAll Back $Volume(activeID) 0
        } else {
            if {$::Module(verbose)} {
                puts "MainSetup: calling MainSlicesSetVolumeAll but allowing it to update the slice offsets"
            }
            MainSlicesSetVolumeAll Back $Volume(activeID) 
        }
    }

    # Initialize Slice orientations - already done in MainSlicesRecallPresets
    if {0} {
        MainSlicesSetOrientAll AxiSagCor
    }
    # already done in MainAnnoRecallPresets
    if {0} {
        MainAnnoSetVisibility
    }

    # Active model
    set m [lindex $Model(idList) 0]
    if {$m != ""} {  
        if {$::Module(verbose)} {
            puts "MainSetup: calling MainModelsSetActive "
        }
        MainModelsSetActive $m
    }

    # Active TetraMesh
    set m [lindex $TetraMesh(idList) 0]
    if {$m != ""} {    
        MainTetraMeshSetActive $m
    }

    # Active transform
    set m [lindex $Matrix(idList) 0]
    if {$m != ""} {    
        MainAlignmentsSetActive $m
    }

    # Active color
    MainColorsSetActive [lindex $Color(idList) 1]

    # Active option
    if {$::Module(verbose)} {
        puts "MainSetup: calling MainOptionsSetActive"
    }
    MainOptionsSetActive [lindex $Options(idList) 0]
}

#-------------------------------------------------------------------------------
# .PROC IsModule
# Checks for the input module id number in the Module(idList), returns 1 if found, 0 otherwise.
# .ARGS
# int m module id
# .END
#-------------------------------------------------------------------------------
proc IsModule {m} {
    global Module

    if {[lsearch $Module(idList) $m] != "-1"} {
        return 1
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC Tab
# 
# Command for switching to a new Row or Tab.
# Checks to see if we might be frozen -- i.e. not supposed to switch to
# a new frame.
#
# .ARGS
# int m module id
# int row row id
# int tab  tab id
# .END
#-------------------------------------------------------------------------------
proc Tab {m {row ""} {tab ""}} {
    global Module Gui View
   
    # Frozen?
    if {$Module(freezer) != ""} {
        set Module(btn) $Module(activeID)
        set Module(moreBtn) 0
        tk_messageBox -message "Please press the Apply or Cancel button."
        return
    }
    
    # No modules?
    if {$m == ""} {return}
    
    # If "More" then switch rows
    if {$m == "More"} {
        set m $Module(activeID)
        set row $Module($m,row)
        switch $row {
            row1 {
                set row row2
                set tab $Module($m,$row,tab)
            }
            row2 {
                set row row1
                set tab $Module($m,$row,tab)
            }
        }
    }
    
    # If "menu" then use currently selected menu item
    if {$m == "Menu"} {
        set m [$Module(rMore) cget -text]
    }
    
    # Remember prev
    set prevID $Module(activeID)
    if {$prevID != ""} {
        set prevRow $Module($prevID,row)
        set prevTab $Module($prevID,$prevRow,tab)
    }
    
    # If no change, do nichts
    if {$m == $prevID} {
        if {$row == $prevRow} {
            if {$tab == $prevTab } {
                return
            }
        }
    }
    
    # Reset previous tab button
    if {$prevID != ""} {
        $Gui(fTabs).f${prevID}${prevRow}.b${prevTab} config \
            -bg $Gui(backdrop) -fg $Gui(textLight) \
            -activebackground $Gui(backdrop) -activeforeground $Gui(textLight)
    }
    
    # If no row specified, then use default
    if {$row == ""} {
        set row $Module($m,row)
    }
    
    # If no btn specified, then use default
    if {$tab == ""} {
        set tab $Module($m,$row,tab)
    }
    
    # Set new
    set Module(activeID) $m
    set Module($m,row) $row
    set Module($m,$row,tab) $tab
    
    
    # Show row
    raise $Module($m,f${row})
    
    # Shrink names of inactive tabs.
    foreach long $Module($m,${row}List) name $Module($m,${row}Name) {
        $Module($m,b$long) config -text "$name" -width \
            [expr [string length "$name"] + 1]
    }
    
    # Expand name of active tab (only if "name" is shorter)
    set idx [lsearch $Module($m,${row}List) $tab]
    set name [lindex $Module($m,${row}Name) $idx]
    if {[string length $name] < [string length $tab]} {
        set name $tab
    } else {
        set name $name
    }
    $Module($m,b$tab) config -text $name \
        -width [expr [string length $name] + 1]
    
    # Activate active tab button    
    $Module($m,b$tab) config -bg $Gui(activeWorkspace) -fg $Gui(textDark) \
        -activebackground $Gui(activeWorkspace) \
        -activeforeground $Gui(textDark)
    
    # Execute Exit procedure (if one exists for the prevID module)
    if {$prevID != $m} {
        if {[info exists Module($prevID,procExit)] == 1} {
            $Module($prevID,procExit)
        }
    }
    
    # Raise the default screen first to hide the previous module tab
    # (if the old module tab is bigger than the new one, some of it will show 
    # in the canvas since there is no -expand true type of command)
    raise .tMain.fControls.fWorkspace.fBoot
    # Show panel
    raise $Module($m,f$tab)
    
    # Show scrollbar (if the height of the panel is higher than the height 
    # of the container frame and we are not in a Help panel)
    # and reconfigure its height based on the height required by 
    # the current panel
    
    if {$tab == "Help"} {
        set Module(scrollbar,helpTabActive) 1
        # don't need to call MainSetScrollbarVisibility to lower the scrollbar 
        # since the panel is raised above it already

    } else {
        set Module(scrollbar,helpTabActive) 0
        set reqHeight [winfo reqheight $Module($m,f$tab)] 
        MainSetScrollbarHeight $reqHeight
        if {$reqHeight > [winfo height .tMain.fControls.fWorkspace]} { 
            MainSetScrollbarVisibility 1
        } else {
            MainSetScrollbarVisibility 0
        }
    }
    
    set Module(btn) $m
    
    # Give tab the focus.  
    # (make sure entry boxes from other tabs don't keep focus!)
    focus $Module($m,f$tab)
    
    # Execute Entrance procedure
    if {$prevID != $m} {
        if {[info exists Module($m,procEnter)] == 1} {
            $Module($m,procEnter)
        }
    }
    
    # Toggle more radio button
    if {$Module($m,more) == 1} {
        set Module(moreBtn) 1
    } else {
        set Module(moreBtn) 0
    }

    #
    # Execute Tab Exit and Entrance procedures
    # (we only get here if the tab has changed, so these are
    # the right procs to call)
    #
    if {$prevID != ""} {
        if { [info exists Module($m,$prevTab,procExit)] } {
            $Module($m,$prevTab,procExit)
        }
    }
    if { [info exists Module($m,$tab,procEnter)] } {
        $Module($m,$tab,procEnter)
    }
}


#-------------------------------------------------------------------------------
# .PROC MainSetScrollbarHeight
#
# This procedure reconfigures the height of the scrollbar based on the 
# height required by the active panel
#
# .ARGS
#  int reqHeight height required by the active panel
# .END
#-------------------------------------------------------------------------------
proc MainSetScrollbarHeight {reqHeight} {
    
    global Module
    # Make the scrollbar slightly smaller so that we don't see the bottom of
    # previous frames
    set reqHeight [expr $reqHeight - 5]
    set canvasHeight  [winfo height .tMain.fControls.fWorkspace]
    
    $Module(canvas) config -scrollregion "0 0 1 $reqHeight"

}

#-------------------------------------------------------------------------------
# .PROC MainSetScrollbarVisibility
#
# If the scrollbar is visible and we are not in a help panel =>
# raise the scrollbar so that the user can scroll down the panel.
# 
# Otherwise => lower the scrollbar
# .ARGS
# bool vis optional argument, defaults to empty string, if 0 or 1 is used to set scrollbar visibility flag
# .END
#-------------------------------------------------------------------------------
proc MainSetScrollbarVisibility {{vis ""}} {
    
    global Module
        
    # if the user has specified a visibility, change Module(scrollbar,visible)
    if { $vis == 1 || $vis == 0} {
        set Module(scrollbar,visible) $vis
    }
    # otherwise leave Module(scrollbar,visible) the way it is
    
    if { $Module(scrollbar,visible) == 1 && $Module(scrollbar,helpTabActive) == 0} {
        raise $Module(scrollbar,widget)
    } else {
        lower $Module(scrollbar,widget)
    }
    
}

#-------------------------------------------------------------------------------
# .PROC MainResizeDisplayFrame
# Resizes the display frame, trying to be intelligent about it.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainResizeDisplayFrame {} {

    global Module

    set displayHeight [winfo reqheight .tMain.fDisplay]

    if {$Module(display,lowered) == 1} {
        pack forget .tMain.fDisplay 
        set Module(.tMain.fControls,height) [expr $Module(.tMain.fControls,height) + $displayHeight]
        set Module(.tMain.fControls,scrolledHeight) [expr $Module(.tMain.fControls,scrolledHeight) + $displayHeight]
        .tMain.fControls configure -height $Module(.tMain.fControls,height)
    } else {
        pack .tMain.fDisplay -before .tMain.fStatus -expand 1 -fill both -padx 0 -pady 0
        set Module(.tMain.fControls,height) [expr $Module(.tMain.fControls,height) - $displayHeight]
        set Module(.tMain.fControls,scrolledHeight) [expr $Module(.tMain.fControls,scrolledHeight) - $displayHeight]
        .tMain.fControls configure -height $Module(.tMain.fControls,height)
    }   

    # update the scrollbar

    set m $Module(activeID)
    set r $Module($m,row)
    set tab $Module($m,$r,tab)

    set reqHeight [winfo reqheight $Module($m,f$tab)] 
    MainSetScrollbarHeight $reqHeight

    if {$reqHeight > $Module(.tMain.fControls,scrolledHeight)} { 
        MainSetScrollbarVisibility 1
    } else {
        MainSetScrollbarVisibility 0
    }

}

#-------------------------------------------------------------------------------
# .PROC MainStartProgress
#
# Does Nothing
#
# .END
#-------------------------------------------------------------------------------
proc MainStartProgress {} {
    global BarId TextId Gui

}

#-------------------------------------------------------------------------------
# .PROC MainShowProgress
#
# Displays progress bar (for when reading off disk, making models, etc.)
# .ARGS
# string filter the name of the vtk variable that will provide progress updates, via a call to GetProgress.
# .END
#-------------------------------------------------------------------------------
proc MainShowProgress {filter} {
    global BarId TextId Gui

    set progress [$filter GetProgress]
    set height   [winfo height $Gui(fStatus)]
    set width    [winfo width $Gui(fStatus)]

    if {[info exists BarId] == 1} {
        $Gui(fStatus).canvas delete $BarId
    }
    if {[info exists TextId] == 1} {
        $Gui(fStatus).canvas delete $TextId
    }
       
    set BarId [$Gui(fStatus).canvas create rect 0 0 [expr $progress*$width] \
        $height -fill [MakeColorNormalized ".5 .5 1.0"]]
 
    set TextId [$Gui(fStatus).canvas create text [expr $width/2] \
        [expr $height/3] -anchor center -justify center -text \
        "$Gui(progressText)"]
 
    update idletasks
}

#-------------------------------------------------------------------------------
# .PROC MainEndProgress
#
# Clears the progress bar (for when done reading off disk, etc.)
# 
# .END
#-------------------------------------------------------------------------------
proc MainEndProgress {} {
    global BarId TextId Gui
    
    if {[info exists BarId] == 1} {
        $Gui(fStatus).canvas delete $BarId
    }
    if {[info exists TextId] == 1} {
        $Gui(fStatus).canvas delete $TextId
    }
    set height   [winfo height $Gui(fStatus)]
    set width    [winfo width $Gui(fStatus)]
    set BarId [$Gui(fStatus).canvas create rect 0 0 $width \
        $height -fill [MakeColorNormalized ".7 .7 .7"]]
    update idletasks
}

#-------------------------------------------------------------------------------
# .PROC MainMenu
# 
# .ARGS
# string menu which menu was chosen: File, Help, View
# string command the element from the menu that was clicked on
# .END
#-------------------------------------------------------------------------------
proc MainMenu {menu cmd} {
    global Gui Module

    set x 50
    set y 50
    
    switch $menu {
    
    "File" {
        switch $cmd {
            "Open" {
                MainFileOpenPopup "" 50 50
            }
            "Import" {
                set typelist {
                    {"XML Files" {.xml}}
                    {"MRML Files" {.mrml}}
                    {"All Files" {*}}
                }
                set file [tk_getOpenFile -title "Import File" -defaultextension ".xml" \
                        -filetypes $typelist -initialdir $::Mrml(dir)]
                if { $file != "" } {
                    MainMrmlImport $file    
                }
            }
            "Save" {
                MainFileSave
            }
            "SaveAs" {
                MainFileSaveAsPopup "" 50 50
            }
            "SaveWithOptions" {
                MainFileSaveWithOptions
            }
            "SaveOptions" {
                MainFileSaveOptions
            }
            "Save3D" {
                Save3DImage
            }
            "SaveSlice" {
                MainSlicesSave
            }
            "Save3DSetParams" {
                SaveDisplayOptionsWindow
            }
            "SaveSliceAs" {
                MainSlicesSavePopup
            }
            "Close" {
                MainFileClose
            }
        }
    }
    
    "Help" {
        switch $cmd {
            "About" {
                global SLICER tcl_patchLevel
                catch "__version Delete"
                vtkVersion __version
                if {[info command vtkITKVersion] == ""} {
                    set itkMsg "ITK not used" 
                } else {
                    vtkITKVersion __itkversion
                    set itkMsg "ITK Version [__itkversion GetITKVersion]
http://www.itk.org"
                }
                set msg "Slicer Version $SLICER(version)
http://www.slicer.org

Tcl/Tk Version $tcl_patchLevel
http://www.tcl.tk

VTK Version [__version GetVTKVersion]
http://www.vtk.org

$itkMsg"
                catch "__version Delete"
                catch "__itkversion Delete"
                MsgPopup Version $x $y $msg {About Slicer}
            }
            "Copyright" {
                if {[info exist ::Comment(copyright)] == 1} {
                    if {$::Module(verbose)} { puts "using Comment(copyright)" }
                    MsgPopup Copyright $x $y $::Comment(copyright)
                } else {
                    MsgPopup Copyright $x $y "\
(c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

This software (\"3D Slicer\") is provided by The Brigham and Women's 
Hospital, Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for  
research purposes only, provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software, and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration, and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS 
IS.\" THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
                }
            }
            "Documentation" {
                MsgPopup Documentation $x $y "\
For the latest documentation, visit:

http://www.slicer.org"
            }
            "Version" {
                set msg [FormatCVSInfo $Module(versions)]
                MsgPopup Version $x $y $msg {Module Version Info}
            }
            "Modules" {
                set msg [FormatModuleInfo]
                MsgPopup ModuleInfo $x $y $msg {Module Summaries}
            }
            "Credits" {
                set msg [FormatModuleCredits]
                MsgPopup ModuleCredits $x $y $msg {Module Credits}
            }
            "Categories" {
                set msg [FormatModuleCategories]
                MsgPopup ModuleCategories $x $y $msg {Module Categories}
            }
        }
    }
    "View" {
        switch $cmd {
            "LargeImage" {
                MainViewerSetLargeImageOn
            }
            default {
                MainViewerSetMode $cmd
            }
        }  
    }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainExitQuery
#
# Does the user really want to exit?
# .END
#-------------------------------------------------------------------------------
proc MainExitQuery { } {
    global Gui Volume Model TetraMesh

    set msg ""

    # See if any models or volumes are unsaved
    set volumes ""
    foreach v $Volume(idList) {
        if {[info exists Volume($v,dirty)] == 1} {
            if {$Volume($v,dirty) == 1} {
                if {$volumes == ""} {
                    set volumes "[Volume($v,node) GetName]"
                } else {
                    set volumes "${volumes}, [Volume($v,node) GetName]"
                }
            }
        }
    }
    if {$volumes != ""} {
         set msg "\
The image data for the following volumes are unsaved:\n\
$volumes\n\nDo you wish to exit anyway?\n"
        set retval [DevYesNo $msg]
        if {$retval == "no"} {
            Tab Editor row1 Volumes
            TabbedFrameInvoke $::Module(Editor,fVolumes) File
            return
        }
    }

    set models ""
    foreach v $Model(idList) {
        if {[info exists Model($v,dirty)] == 1} {
            if {$Model($v,dirty) == 1} {
                if {$models == ""} {
                    set models "[Model($v,node) GetName]"
                } else {
                    set models "${models}, [Model($v,node) GetName]"
                }
            }
        }
    }

    if {$models != ""} {
         set msg "\
The polygon data for the following surface models are unsaved:\n\
$models\n\nDo you wish to exit anyway?"
        set retval [DevYesNo $msg]
        if {$retval == "no"} {
            Tab ModelMaker row1 Save
            return
        }
    }


    set tetmesh ""
    foreach v $TetraMesh(idList) {
        if {[info exists TetraMesh($v,dirty)] == 1} {
            if {$TetraMesh($v,dirty) == 1} {
                if {$tetmesh == ""} {
                    set tetmesh "[TetraMesh($v,node) GetName]"
                } else {
                    set tetmesh "${tetmesh}, [TetraMesh($v,node) GetName]"
                }
            }
        }
    }
    if {$tetmesh != ""} {
       set msg "\
The Volume Meshes for the following tetrahedral mesh are unsaved:\n\
$tetmesh\n\nDo you wish to exit anyway?" 
        set retval [DevYesNo $msg]
        if {$retval == "no"} {
            Tab TetraMesh row1 Read
            return
        }
    }

    MainExitProgram
}

#-------------------------------------------------------------------------------
# .PROC MainSaveMRMLQuery 
#
#
# Save the Mrml File?
# THIS IS CURRENTLY NOT USED
# .END
#-------------------------------------------------------------------------------
proc MainSaveMRMLQuery { } {
    global Gui
    
    # See if Dag is unsaved
    if {$Gui(unsavedDag) != 0} {
        # set x [expr [winfo rootx $Gui(bExit)] - 60]
        # set y [expr [winfo rooty $Gui(bExit)] - 85]
        set x 0
        set y 0
        YesNoPopup SaveMRML $x $y \
            "Do you want to save changes\n\
             made to the MRML file?" \
            "FileSaveDag; MainExitProgram" MainExitProgram
    } else {
        MainExitProgram
    }
}

#-------------------------------------------------------------------------------
# .PROC MainExitProgram
#
#  Exit the Program with cleanup
# .ARGS
# int code optional exit code, defaults to 0
# .END
#-------------------------------------------------------------------------------
proc MainExitProgram { "code 0" } {
    global Module View

    set View(render_on) 0
    
    # logging
    if {[IsModule SessionLog] == 1} {
        # Execute Exit procedure (if one exists for the prevID module)
        # This is so that it can log anything final it should log.
        set prevID $Module(activeID)
        if {[info exists Module($prevID,procExit)] == 1} {
            $Module($prevID,procExit)
        }

        # write out the log file if we are logging
        SessionLogEndSession
    }
    # end logging

    # give the modules a chance to clean up if needed
    foreach m $Module(idList) {
        if {[info exists Module($m,procMainExit)] == 1} {
            $Module($m,procMainExit)
        }
    }

#### Turn these lines on if you want to see what classes have not yet been
#### deleted. This is vtk3.2 only. it also requires special compilation 
#### of vtkObjectFactory and vtkObject
#### see: http://www.kitware.com/vtkhtml/vtkdata/html/class_vtkdebugleaks.html
#    vtkDebugLeaks DebugLeaks
#    DebugLeaks PrintCurrentLeaks

    #
    # as of vtk4, you want to close all your vtk/tk windows before
    # exiting to avoid a crash
    #
    # unfortunate hack - need to turn off warning about widget deletion order
    catch "__exit_object Delete"
    vtkObject __exit_object 
    __exit_object SetGlobalWarningDisplay 0

    foreach w [info commands .*] {
        if { ![catch "winfo class $w"] } {
            if {[winfo class $w] == "vtkTkRenderWidget"} {
                set renwin [$w GetRenderWindow]
                if { [info command $renwin] != "" } {
                    $renwin Delete
                }
                catch "destroy $w"
            } elseif {[winfo class $w] == "vtkTkImageViewerWidget"} {
                set renwin [$w GetImageViewer]
                if { [info command $renwin] != "" } {
                    $renwin Delete
                }
                catch "destroy $w"
            }
        }
    }

    # tcl_exit is the original "exit" built in call, but renamed so we can shut down nicely
    # - if it hasn't been defined yet, call regular exit (e.g. during startup)
    if { [info command tcl_exit] != "" } {
        tcl_exit $code
    } else {
        exit $code
    }
}

#-------------------------------------------------------------------------------
# .PROC Distance
# Returns the distance between two 3D points.
# .ARGS
# string aArray name of the first three element array
# string bArray name of the second three element array
# .END
#-------------------------------------------------------------------------------
proc Distance {aArray bArray} {

    upvar $aArray a
    upvar $bArray b

    set x [expr $a(r) - $b(r)]
    set y [expr $a(a) - $b(a)]
    set z [expr $a(s) - $b(s)]
    
    return [expr sqrt($x*$x + $y*$y + $z*$z)]
}

#-------------------------------------------------------------------------------
# .PROC Normalize
# a = |a|
# .ARGS
# string aArray name of the 3 element vector to normalize
# .END
#-------------------------------------------------------------------------------
proc Normalize {aArray} {
    upvar $aArray a

    set d [expr sqrt($a(x)*$a(x) + $a(y)*$a(y) + $a(z)*$a(z))]

    if {$d == 0} {
        return
    }
    set a(x) [expr $a(x) / $d]
    set a(y) [expr $a(y) / $d]
    set a(z) [expr $a(z) / $d]
}

#-------------------------------------------------------------------------------
# .PROC Cross
# a = b x c 
# .ARGS
# string aArray result vector
# string bArray first vector in cross product
# string cArray second vector in cross product
# .END
#-------------------------------------------------------------------------------
proc Cross {aArray bArray cArray} {
    upvar $aArray a
    upvar $bArray b
    upvar $cArray c

    set a(x) [expr $b(y)*$c(z) - $c(y)*$b(z)]
    set a(y) [expr $c(x)*$b(z) - $b(x)*$c(z)]
    set a(z) [expr $b(x)*$c(y) - $c(x)*$b(y)]
}

#-------------------------------------------------------------------------------
# .PROC ParseCVSInfo
# Remove $ and spaces from CVS version info
# .ARGS
# string module name of the module
# string args list of elements to parse
# .END
#-------------------------------------------------------------------------------
proc ParseCVSInfo {module args} {
    set l $module 
    foreach a $args {
        lappend l [string trim $a {$ \t}]
    }
    return $l
}

#-------------------------------------------------------------------------------
# .PROC FormatCVSInfo
# Format module version info string for display from help on main menu
# .ARGS
# string versions list of cvs version strings
# .END
#-------------------------------------------------------------------------------
proc FormatCVSInfo {versions} {
    set s ""
    foreach v "$versions" {
        set s [format "%s%-30s" $s "[lindex $v 0]:"]
        set s "${s}\t[lindex $v 1]\t\t[lindex $v 2]\n"
    }
    return $s
}

#-------------------------------------------------------------------------------
# .PROC FormatModuleInfo
# Format module overview info string for display from help on main menu
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FormatModuleInfo {} {
    global Module

    set s "" 
    foreach m $Module(idList) {
        if {[info exists Module($m,overview)]} {
            set s [format "%s%-30s" $s "$m:"]
            set s "${s}\t$Module($m,overview)\n"
        } else {
            set s "$s$m: \n"
        }
    }

    return $s
}

#-------------------------------------------------------------------------------
# .PROC FormatModuleCredits
# Format the module credits for display from Help menu
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FormatModuleCredits {} {
    global Module

    set s "" 
    foreach m $Module(idList) {
        if {[info exists Module($m,author)]} {
            set s [format "%s%-30s" $s "$m:"]
            set s "${s}\t$Module($m,author)\n"
        } else {
            set s "$s$m: \n"
        }
    }

    return $s
}

#-------------------------------------------------------------------------------
# .PROC FormatModuleCategories
# Returns a formatted string with the categories of the modules.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FormatModuleCategories {} {
    global Module

    set s "" 
    foreach m $Module(idList) {
        if {[info exists Module($m,category)]} {
            set s [format "%s%-30s" $s "$m:"]            
            set s "${s}\t$Module($m,category)\n"
        } else {
            set s "$s$m: \n"
        }
    }

    return $s
}

#-------------------------------------------------------------------------------
# .PROC MainBuildCategoryIDLists
# Takes module ids from the Module(idList), checks to see if they have a category defined in
# the variable Module($module,category), and if so, adds the module id to the list being built in
# Module(idList,$category). Also appends Module(categories) with any missing categories.
# Also alphabetises the modules lists, except for the Core one.
# Also builds a sorted list of all modules in the All category.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainBuildCategoryIDLists {} {
    global Module

    # reset the unfiled list
    set Module(idList,Unfiled) {}

    # Grab all the modules and put them in categories,
    # add them to the category list if they're not there yet
    foreach mod $Module(idList) {
        if {[info exists Module($mod,category)]} {
            set cat $Module($mod,category)
            lappend Module(idList,$cat) $mod
            if {[lsearch $Module(categories) $cat] == -1} {
                # not in the list of categories, add it
                lappend Module(categories) $cat
            }
        } else {
            lappend Module(idList,Unfiled) $mod
        }
        lappend Module(idList,All) $mod
    }
    
    # build a list of current categories
    if {$::Module(verbose)} {
        puts "MainBuildCategoryIDLists: Categories:  $Module(categories)"
    }

    # put all but the core modules in alpha order (there may not be any Unfiled ones)
    foreach cat  $Module(categories) {
        if {$cat != "Core" &&
            [info exists Module(idList,$cat)]} {
            set tempList [lsort -dictionary $Module(idList,$cat)]
            set Module(idList,$cat) $tempList
        } else {
            if {$Module(verbose)} { puts "Not sorting module list, category = $cat"}
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainBuildCategoryMenu
# Deletes any entries from the Module menu, and then adds cascades for each 
# category and populates them. Each entry will call Tab with the module name.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainBuildCategoryMenu {} {
    global Module Gui

    if {[info exists Gui(mModules)] == 0} {
        # build the menu
        eval {menu .menubar.mModules} $Gui(SMA)
        set Gui(mModules) .menubar.mModules
        .menubar add cascade -label Modules -menu .menubar.mModules
    } else {
        # remove any current entries
        $Gui(mModules) delete 0 end
    } 

    foreach category $Module(categories) {
        if {[info exists Module(idList,$category)]} {
            # create a cascade menu for it
            eval {menu $Gui(mModules).m$category} $Gui(SMA)
            $Gui(mModules) add cascade -label "$category" -menu $Gui(mModules).m$category
            # then add it's modules
            foreach module $Module(idList,$category) {
                # for now, just switch to the tab for this module, if it has a gui
                if { [info exists Module($module,procGUI)] } {
                    # are there too many entries, so we should have a column break?
                    set colbreak [MainVolumesBreakVolumeMenu $Gui(mModules).m$category]
                    if {$Module(more) == 1} {
                        $Gui(mModules).m$category add command -label "$module" \
                            -command "set Module(btn) More; Tab $module; $Module(rMore) config -text $module" \
                            -columnbreak $colbreak
                    } else {
                        # just tab to the module, don't have to reset the Module(rMore) text 
                        # because no More button exists
                        $Gui(mModules).m$category add command -label "$module" \
                            -command "Tab $module" \
                            -columnbreak $colbreak
                    }
                }
            }
            # check to see if any of the modules in this category had gui's
            # if not, remove the menu for it
            if {[$Gui(mModules).m$category index end] == "none"} {
                if {$::Module(verbose)} { puts "Category $category has no entries with guis" }
                $Gui(mModules) delete [$Gui(mModules) index $category]
            }
        } else {
            if {$::Module(verbose)} {
                puts "Modules Menu: no modules in ID list for $category"
            }
        }
    }
}
