#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Editor.tcl,v $
#   Date:      $Date: 2006/08/31 20:27:30 $
#   Version:   $Revision: 1.91 $
# 
#===============================================================================
# FILE:        Editor.tcl
# PROCEDURES:  
#   EditorInit
#   EditorBuildVTK
#   EditorUpdateMRML
#   EditorBuildGUI
#   EditorEnter
#   EditorExit
#   EditorMakeModel
#   EditorMotion
#   EditorB1
#   EditorIdleProc
#   EditorInsertPoint point
#   EditorB1Motion
#   EditorB1Release
#   EditorChangeInputLabel
#   EditorSetOriginal
#   EditorSetWorking
#   EditorSetComposite
#   EditorUpdateEffect
#   EditorSameExtents
#   EditorCopyNode
#   EditorGetOriginalID
#   EditorGetWorkingID
#   EditorGetCompositeID
#   EditorResetDisplay
#   EditorToggleWorking
#   EditorHideWorking
#   EditorShowWorking
#   EditorSetEffect
#   EditorExitEffect
#   EditorGetInputID
#   EditorActivateUndo
#   EditorUpdateAfterUndo
#   EditorUndo
#   EdBuildScopeGUI
#   EdBuildMultiGUI
#   EdBuildInputGUI
#   EdBuildInteractGUI
#   EdBuildRenderGUI
#   EdIsNativeSlice
#   EdSetupBeforeApplyEffect
#   EdUpdateAfterApplyEffect
#   EditorWrite
#   EditorSetSaveVolume
#   EditorWriteVolume
#   EditorRead
#   EditorClear
#   EditorMerge
#   EditorLog
#   EditorIncrementAndLogEvent
#   EditorLogEventOnce
#   EditorReplaceAndLogEvent
#   EditorStartTiming name
#   EditorStopTiming name
#   EditorControlB1
#   EditorControlB1Motion
#   EditorControlB1Release
#   EditorClampToOriginalBounds
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EditorInit
# Sets up tabs and global variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorInit {} {
    global Editor Ed Gui Volume Module env Path
    
    # Define Tabs
    set m Editor
    set Module($m,row1List) "Help Volumes Effects Details"
    set Module($m,row1Name) "{Help} {Volumes} {Effects} {Details}"
    set Module($m,row1,tab) Volumes

    # Module Summary Info
    set Module($m,overview) "Segmentation: manual, semi-automatic, and morphological."
    set Module($m,author) "Core"
    set Module($m,category) "Segmentation"

    # Define Procedures
    set Module($m,procGUI)   EditorBuildGUI
    set Module($m,procMRML)  EditorUpdateMRML
    set Module($m,procVTK)   EditorBuildVTK
    set Module($m,procEnter) EditorEnter
    set Module($m,procExit) EditorExit
    # logging
    set Module($m,procSessionLog) EditorLog

    # Define Dependencies
    set Module($m,depend) "Labels"
    
    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.91 $} {$Date: 2006/08/31 20:27:30 $}]
    
    # Initialize globals
    set Editor(idOriginal)  $Volume(idNone)
    set Editor(idWorking)   NEW
    set Editor(idComposite) NEW
    set Editor(undoActive)  0
    set Editor(effectMore)  0
    set Editor(activeID)    TBD
    set Editor(firstReset)  0
    set Editor(prefixComposite) ""
    set Editor(prefixWorking) ""
    set Editor(fgName) Working
    set Editor(bgName) Composite
    set Editor(nameWorking) Working
    set Editor(nameComposite) Composite
    set Editor(eventManager)  {  }
    set Editor(fileformat) nhdr
    
    # add display settings for editor here: 
    # whether to keep the label layer visible at all times
    set Editor(display,labelOn) 1
    
    # Look for Editor effects and form an array, Ed, for them.
    # Each effect has a *.tcl file in the tcl-modules/Editor directory.
    set Ed(idList) ""

    set local [file join tcl-modules Editor]
    set prog $Path(program)
    set central  [file join [file join $prog tcl-modules] Editor]
    set names ""

    # save the already loaded editor commands (from modules)
    set cmds [info command Ed*Init]

    # Look locally
    foreach fullname [glob -nocomplain $local/*] {
        if {[regexp "$local/(\.*).tcl$" $fullname match name] == 1} {
            lappend names $name
        }
    }
    # Look centrally
    foreach fullname [glob -nocomplain $central/*] {
        if {[regexp "$central/(\.*).tcl$" $fullname match name] == 1} {
            if {[lsearch $names $name] == -1} {
                lappend names $name
            }
        }
    }

    # source them
    set found ""
    foreach name $names {
        
        set path [GetFullPath $name tcl $local]
        if {$path != ""} {
            #puts "source $path"

            # If there's an error, print the fullname:
            if {[catch {source $path} errmsg] == 1} {
                puts "ERROR in $path:\n $errmsg"
            }

            lappend Ed(idList) $name
        } 
    }

    foreach c $cmds {
        if { $c != "EditorInit" } {
            scan $c "%\[^I\]sInit" name
            lappend Ed(idList) $name
        }
    }

    # Initialize effects
    if {$Module(verbose) == 1} {
        puts Editor-Init:
    }
    foreach m $Ed(idList) {
        if {[info command ${m}Init] != ""} {
            if {$Module(verbose) == 1} {
                puts ${m}Init
            }
            ${m}Init
        }
    }
    
    # Order effects by increasing rank
    set pairs ""
    foreach m $Ed(idList) {
        lappend pairs "$m $Ed($m,rank)"
    }
    set pairs [lsort -index 1 -integer -increasing $pairs]
    set Ed(idList) ""
    foreach p $pairs {
        lappend Ed(idList) [lindex $p 0]
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorBuildVTK
# Calls BuildVTK procs for files in Editor subdirectory. <br>
# Makes VTK objects vtkImageEditorEffects Ed(editor) and 
# vtkMrmlVolumeNode Editor(undoNode).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorBuildVTK {} {
    global Editor Ed Module

    vtkImageEditorEffects Ed(editor)
    Ed(editor) AddObserver StartEvent     MainStartProgress
    Ed(editor) AddObserver ProgressEvent "MainShowProgress Ed(editor)"
    Ed(editor) AddObserver EndEvent       MainEndProgress

    # Initialize effects
    if {$Module(verbose) == 1} {
        puts Editor-VTK:
    }
    foreach e $Ed(idList) {
        if {[info exists Ed($e,procVTK)] == 1} {
            if {$Module(verbose) == 1} {
                puts $Ed($e,procVTK)
            }
            $Ed($e,procVTK)
        }
    }

    # Node to store for undo
    vtkMrmlVolumeNode Editor(undoNode)
}

#-------------------------------------------------------------------------------
# .PROC EditorUpdateMRML
# Redoes the menus for picking volumes to edit (since these may have changed with
# a change in MRML).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorUpdateMRML {} {
    global Volume Editor

    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $Editor(idOriginal)] == -1} {
        EditorSetOriginal $n
    }
    if {$Editor(idWorking) != "NEW" && \
            [lsearch $Volume(idList) $Editor(idWorking)] == -1} {
        EditorSetWorking NEW
    }
    if {$Editor(idComposite) != "NEW" && \
            [lsearch $Volume(idList) $Editor(idComposite)] == -1} {
        EditorSetComposite NEW
    }

    # Original Volume menu
    #---------------------------------------------------------------------------
    set m $Editor(mOriginal)
    $m delete 0 end

    set volumeList ""
    set labelList ""
    # make two lists of volumes, so can have the grey scales or the label maps first 
    # in the Original and Working Labelmap lists, as appropriate.
    foreach v $Volume(idList) {
        if {[Volume($v,node) GetLabelMap] == 1} {
            lappend labelList $v
        } else {
            lappend volumeList $v
        }
    }
    if {$::Module(verbose)} {
        puts "EditorUpdateMRML: built greyscale volume list: $volumeList, and label list: $labelList" 
    }
    # greyscales first
    set greysFirst $volumeList
    lappend greysFirst $labelList
    set greysFirst [join $greysFirst]

    # labels first
    set labelsFirst $labelList
    lappend labelsFirst $volumeList
    set labelsFirst [join $labelsFirst]

    foreach v $greysFirst {
        set colbreak [MainVolumesBreakVolumeMenu $m] 
        $m add command -label [Volume($v,node) GetName] \
            -command "EditorSetOriginal $v; RenderAll" \
            -columnbreak $colbreak
    }

    # Working Volume menu
    #---------------------------------------------------------------------------
    set m $Editor(mWorking)
    $m delete 0 end
    set idWorking ""
    foreach v $labelsFirst {
        if {$v != $Volume(idNone) && $v != $Editor(idComposite)} {
            set colbreak [MainVolumesBreakVolumeMenu $m] 
            $m add command -label [Volume($v,node) GetName] \
                -command "EditorSetWorking $v; RenderAll" \
                -columnbreak $colbreak
        }
    }

    # Always add a NEW option
    $m add command -label NEW -command "EditorSetWorking NEW; RenderAll"

    # Set the working volume
    EditorSetWorking $Editor(idWorking)

    # Working Volume name field  (name for the NEW volume to be created)
    #---------------------------------------------------------------------------
    set v $Editor(idWorking)
    if {$v != "NEW"} {
        set Editor(nameWorking) [Volume($v,node) GetName]
    } else {
        set Editor(nameWorking) Working
    }

    # Composite Volume menu
    #---------------------------------------------------------------------------
    set m $Editor(mComposite)
    $m delete 0 end
    set idComposite ""
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone) && $v != $Editor(idWorking)} {
            $m add command -label [Volume($v,node) GetName] -command \
                "EditorSetComposite $v; RenderAll"
        }
        if {[Volume($v,node) GetName] == "Composite"} {
            set idComposite $v
        }
    }
    # If there is composite, then select it, else add a NEW option
    if {$idComposite != ""} {
        EditorSetComposite $idComposite
    } else {
        $m add command -label NEW -command "EditorSetComposite NEW; RenderAll"
    }

    # Composite Volume name field 
    #---------------------------------------------------------------------------
    set v $Editor(idComposite)
    if {$v != "NEW"} {
        set Editor(nameComposite) [Volume($v,node) GetName]
    } else {
        set Editor(nameComposite) Composite
    }

}

#-------------------------------------------------------------------------------
# .PROC EditorBuildGUI
# Builds the GUI for the Editor tab.  
# Calls the BuildGUI proc for each file in the Editor subdirectory, and gives each
# one a frame inside the Details->Effect frame.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorBuildGUI {} {
    global Gui Volume Editor Ed Module Slice Path

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Volumes
    #   TabbedFrame
    #     Setup
    #     Merge
    #     Undo
    #     File
    # Effects
    #   Effects
    #     Btns
    #     More
    #     Undo
    #   Original
    #   Working
    #   Active
    #   Time
    #   Display
    #   Model 
    # Details
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
    The Editor module allows editing volumes to create labelmaps, where a unique
    number, or label, is assigned to each tissue type.
    <P>
    Description by Tab:
    <UL>
    <LI><B>Volumes Tab:</B> 

    <BR><BR><B>  o  Setup:</B> Set the <B>Original Grayscale</B> to the volume you wish
    to construct the labelmap from, and then click the <B>Start Editing</B>
    button.     
    <BR><B> TIP:</B> Also fill in the <B>Descriptive Name</B> box.  This
    name will be the default filename later when you save the labelmap.
    <BR><B>TIP:</B> If you started editing earlier, and now wish to continue where
    you left off, then select the <B>Working Volume</B> from before.
    
    <BR><BR><B>  o  Merge:</B> Combine two labelmaps, one over the other. 
    The <B>Composite</B> labelmap is a handy volume to combine others into.
    
    <BR><BR><B>  o  Undo:</B> Remove all the editing you have done in a labelmap,
    either by clearing it or re-reading it from a file.
    <BR><B> TIP:</B> To undo a smaller amount of editing, use the <B>Undo</B> 
    button under the <B>Editor->Effects</B> tab.
    
    <BR><BR><B>  o  Save:</B> Save a labelmap, and also a MRML file with the same
    name as the labelmap.  This MRML file contains the <B>header information</B> 
    from the original scan.

    <BR><LI><B>Effects Tab:</B> Editing is performed by applying a series of effects
    to the data.  Effects can be applied to the entire volume, each slice one at
    a time, or to just one slice.  Set this by changing the <B>Scope</B> of the effect.

    <BR><LI><B>Details Tab:</B> This tab contains the detailed parameters for each
    effect. 
    <BR><B> TIP:</B> When changing from one effect to another, you can avoid the
    extra work of clicking the <B>Effects</B> tab by clicking on the 2-letter
    abreviation for the effect at the top of the <B>Details</B> tab.
    </UL>
    <P>
    "
    regsub -all "\n" $help { } help
    # rm emacs-style indentation
    regsub -all "    " $help { } help
    MainHelpApplyTags Editor $help
    MainHelpBuildGUI Editor


    ############################################################################
    #                                 Volumes
    ############################################################################

    #-------------------------------------------
    # Volumes frame
    #-------------------------------------------
    set fVolumes $Module(Editor,fVolumes)
    set f $fVolumes
    
    # this makes the navigation menu (buttons) and the tabs.
    TabbedFrame MeasureVol $f ""\
        {Setup Merge Undo File} {"Setup" "Merge" "Undo" "Save"} \
        {"Choose volumes before editing." \
             "Merge two labelmaps." "Clear or re-read a labelmap from disk." \
             "Save a labelmap."}

    #-------------------------------------------
    # Volumes->TabbedFrame->Setup frame
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup

    frame $f.fHelp      -bg $Gui(activeWorkspace)
    frame $f.fOriginal  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fWorking   -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fStart   -bg $Gui(activeWorkspace) 

    pack  $f.fHelp $f.fOriginal  $f.fWorking $f.fStart\
        -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Help
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fHelp
    
    eval {label $f.l -text \
              "First choose the volumes to edit.\n Type a name for any NEW labelmap.\nThen click `Start Editing'."} \
        $Gui(WLA)
    pack $f.l

    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Original
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fOriginal
    
    frame $f.fMenu -bg $Gui(activeWorkspace)
    
    pack $f.fMenu -side top -pady $Gui(pad) -fill x

    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Original->Menu
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fOriginal.fMenu
    
    # Volume menu
    eval {label $f.lOriginal -text "Original Grayscale:"} $Gui(WTA)
    
    eval {menubutton $f.mbOriginal -text "None" -relief raised -bd 2 -width 18 \
              -menu $f.mbOriginal.m} $Gui(WMBA)
    eval {menu $f.mbOriginal.m} $Gui(WMA)
    TooltipAdd $f.mbOriginal "Choose the input grayscale volume for editing."
    pack $f.lOriginal -padx $Gui(pad) -side left -anchor e
    pack $f.mbOriginal -padx $Gui(pad) -side left -anchor w
    
    # Save widgets for changing
    set Editor(mbOriginal) $f.mbOriginal
    set Editor(mOriginal)  $f.mbOriginal.m
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Working
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fWorking
    
    frame $f.fMenu -bg $Gui(activeWorkspace)
    frame $f.fName -bg $Gui(activeWorkspace)
    
    pack $f.fMenu -side top -pady $Gui(pad)
    pack $f.fName -side top -pady $Gui(pad) -fill x

    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Working->Menu
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fWorking.fMenu
    
    # Volume menu
    eval {label $f.lWorking -text "Working Labelmap:"} $Gui(WTA)
    
    eval {menubutton $f.mbWorking -text "NEW" -relief raised -bd 2 -width 18 \
              -menu $f.mbWorking.m} $Gui(WMBA)
    eval {menu $f.mbWorking.m} $Gui(WMA)
    TooltipAdd $f.mbWorking "Choose a labelmap to edit, or NEW for a new one."
    pack $f.lWorking $f.mbWorking -padx $Gui(pad) -side left
    
    # Save widgets for changing
    set Editor(mbWorking) $f.mbWorking
    set Editor(mWorking)  $f.mbWorking.m
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Working->Name
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fWorking.fName
    
    eval {label $f.l -text "Descriptive Name:"} $Gui(WLA)
    eval {entry $f.e -textvariable Editor(nameWorking)} $Gui(WEA)
    TooltipAdd $f.e "Nickname your NEW volume."
    pack $f.l -padx 3 -side left
    pack $f.e -padx 3 -side left -expand 1 -fill x
    
    # Save widget for disabling name field if not NEW volume
    set Editor(eNameWorking) $f.e

    
    #-------------------------------------------
    # Volumes->TabbedFrame->Setup->Start
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fSetup.fStart
    
    DevAddButton $f.bStart "Start Editing" "Tab Editor row1 Effects"
    TooltipAdd $f.bStart "Go go go!"  
    pack $f.bStart -side top -padx $Gui(pad) -pady $Gui(pad)
    
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Merge frame
    #-------------------------------------------
    set f  $fVolumes.fTabbedFrame.fMerge
    
    frame $f.fHelp      -bg $Gui(activeWorkspace)
    frame $f.fComposite -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fMerge     -bg $Gui(activeWorkspace) -relief groove -bd 3
    
    pack $f.fHelp $f.fComposite $f.fMerge \
        -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Merge->Help
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fMerge.fHelp
    
    eval {label $f.l -text "Merge two label maps:\nthe first will be copied onto the second.\nSet Original and Working in the\nEditor->Volumes->Setup pane."} $Gui(WLA)
    pack $f.l
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Merge->Composite
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fMerge.fComposite
    
    frame $f.fMenu   -bg $Gui(activeWorkspace)
    frame $f.fName -bg $Gui(activeWorkspace)
    pack $f.fMenu -side top -pady $Gui(pad)
    pack $f.fName -side top -pady $Gui(pad) -fill x
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Merge->Composite->Menu
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fMerge.fComposite.fMenu

    # Volume menu
    eval {label $f.lComposite -text "Composite Labelmap:"} $Gui(WTA)
    
    eval {menubutton $f.mbComposite -text "NEW" -relief raised -bd 2 -width 18 \
              -menu $f.mbComposite.m} $Gui(WMBA)
    eval {menu $f.mbComposite.m} $Gui(WMA)
    TooltipAdd $f.mbComposite "Choose a labelmap, or NEW for a new one."
    pack $f.lComposite $f.mbComposite -padx $Gui(pad) -side left
    
    # Save widgets for changing
    set Editor(mbComposite) $f.mbComposite
    set Editor(mComposite)  $f.mbComposite.m
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Merge->Composite->Name
    #-------------------------------------------    
    set f $fVolumes.fTabbedFrame.fMerge.fComposite.fName

    eval {label $f.l -text "Descriptive Name:"} $Gui(WLA)
    eval {entry $f.e -textvariable Editor(nameComposite)} $Gui(WEA)
    TooltipAdd $f.e "Nickname your NEW volume."
    pack $f.l -padx 3 -side left
    pack $f.e -padx 3 -side left -expand 1 -fill x

    # Save widget for disabling name field if not NEW volume
    set Editor(eNameComposite) $f.e
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Merge->Merge
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fMerge.fMerge
    
    eval {label $f.lTitle -text "Combine 2 Label Maps"} $Gui(WTA)
    frame $f.f  -bg $Gui(activeWorkspace)
    eval {button $f.b -text "Merge" -width 6 \
              -command "EditorMerge merge 0; RenderAll"} $Gui(WBA)
    pack $f.lTitle $f.f $f.b -pady $Gui(pad) -side top

    TooltipAdd $f.b "Merge the labelmaps."
    
    set f $fVolumes.fTabbedFrame.fMerge.fMerge.f
    
    eval {label $f.l1 -text "Write"} $Gui(WLA)
    
    eval {menubutton $f.mbFore -text "$Editor(fgName)" -relief raised -bd 2 -width 9 \
              -menu $f.mbFore.m} $Gui(WMBA)
    eval {menu $f.mbFore.m} $Gui(WMA)
    set Editor(mbFore) $f.mbFore
    set m $Editor(mbFore).m
    foreach v "Working Composite Original" {
        $m add command -label $v -command "EditorMerge Fore $v"
    }
    
    eval {label $f.l2 -text "over"} $Gui(WLA)
    
    eval {menubutton $f.mbBack -text "$Editor(bgName)" -relief raised -bd 2 -width 9 \
              -menu $f.mbBack.m} $Gui(WMBA)
    eval {menu $f.mbBack.m} $Gui(WMA)
    set Editor(mbBack) $f.mbBack
    set m $Editor(mbBack).m
    foreach v "Working Composite" {
        $m add command -label $v -command "EditorMerge Back $v"
    }

    TooltipAdd $f.mbFore "Choose a labelmap to go on top."
    TooltipAdd $f.mbBack "Choose a labelmap to go underneath."
    
    pack $f.mbFore $f.l2 $f.mbBack -padx $Gui(pad) -side left -anchor w

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo frame
    #-------------------------------------------
    set f  $fVolumes.fTabbedFrame.fUndo
    
    frame $f.fHelp      -bg $Gui(activeWorkspace)
    frame $f.fWorking   -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fComposite -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack $f.fHelp $f.fWorking $f.fComposite  \
        -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Help
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fHelp
    
    eval {label $f.l -text "Undo all edits in a labelmap:\nEither re-read the labelmap from disk\nor clear it to all zeros."} $Gui(WLA)
    pack $f.l

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Working
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fWorking

    frame $f.fLabel   -bg $Gui(activeWorkspace)
    frame $f.fBtns   -bg $Gui(activeWorkspace)
    pack $f.fLabel -side top -pady $Gui(pad)
    pack $f.fBtns -side top -pady $Gui(pad)

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Working->Label
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fWorking.fLabel
    
    eval {label $f.l -text "Working Labelmap:"} $Gui(WLA)
    pack $f.l -side top

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Working->Btns
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fWorking.fBtns

    eval {button $f.bClear -text "Clear to 0's" -width 12 \
              -command "EditorClear Working; RenderAll"} $Gui(WBA)
    TooltipAdd $f.bClear "Clear the Working Volume."
    eval {button $f.bRead -text "Re-read" -width 7 \
              -command "EditorRead Working; RenderAll"} $Gui(WBA)
    TooltipAdd $f.bRead "Re-read the Working Volume from disk."
    pack  $f.bRead $f.bClear -side left -padx $Gui(pad)    

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Composite
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fComposite

    frame $f.fLabel   -bg $Gui(activeWorkspace)
    frame $f.fBtns   -bg $Gui(activeWorkspace)
    pack $f.fLabel -side top -pady $Gui(pad)
    pack $f.fBtns -side top -pady $Gui(pad)

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Composite->Label
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fComposite.fLabel
    
    eval {label $f.l -text "Composite Labelmap:"} $Gui(WLA)
    pack $f.l -side top

    #-------------------------------------------
    # Volumes->TabbedFrame->Undo->Composite->Btns
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fUndo.fComposite.fBtns

    eval {button $f.bClear -text "Clear to 0's" -width 12 \
              -command "EditorClear Composite; RenderAll"} $Gui(WBA)
    TooltipAdd $f.bClear "Clear the Composite Volume."
    eval {button $f.bRead -text "Re-read" -width 7 \
              -command "EditorRead Composite; RenderAll"} $Gui(WBA)
    TooltipAdd $f.bRead "Re-read the Composite Volume from disk."
    pack  $f.bRead $f.bClear -side left -padx $Gui(pad)    
    
    #-------------------------------------------
    # Volumes->TabbedFrame->File frame
    #-------------------------------------------
    set f  $fVolumes.fTabbedFrame.fFile

    frame $f.fHelp      -bg $Gui(activeWorkspace)    
    frame $f.fVol   -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack $f.fHelp $f.fVol \
        -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    #-------------------------------------------
    # Volumes->TabbedFrame->File->Help
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fFile.fHelp
    
    eval {label $f.l -text "Save a labelmap volume."} $Gui(WLA)
    pack $f.l

    #-------------------------------------------
    # Volumes->TabbedFrame->File->Vol frame
    #-------------------------------------------
    set f $fVolumes.fTabbedFrame.fFile.fVol
    
    frame $f.fMenu -bg $Gui(activeWorkspace)
    frame $f.fPrefix -bg $Gui(activeWorkspace)
    frame $f.fBtns   -bg $Gui(activeWorkspace)
    
    pack $f.fMenu -side top -pady $Gui(pad)
    pack $f.fPrefix -side top -pady $Gui(pad) -fill x
    pack $f.fBtns -side top -pady $Gui(pad)

    

    #-------------------------------------------
    # Volumes->TabbedFrame->File->Vol->Menu
    #-------------------------------------------
    
    set f $fVolumes.fTabbedFrame.fFile.fVol.fMenu
    
    # Volume menu
    DevAddSelectButton Editor $f VolumeSelect "Volume to save:" Pack \
        "Volume to save." 14

    # bind menubutton to update stuff when volume changes.
    bind $Editor(mVolumeSelect) <ButtonRelease-1> \
        "EditorSetSaveVolume" 
    # have this binding execute after the menu updates
    bindtags $Editor(mVolumeSelect) [list Menu \
                                         $Editor(mVolumeSelect) all]

    # Append menu and button to lists that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbVolumeSelect
    lappend Volume(mActiveList) $f.mbVolumeSelect.m
    
    
    #-------------------------------------------
    # Volumes->TabbedFrame->File->Vol->Prefix
    #-------------------------------------------
    frame $fVolumes.fTabbedFrame.fFile.fVol.fSave -bg $Gui(activeWorkspace)
    pack $fVolumes.fTabbedFrame.fFile.fVol.fSave -side top -padx 0 -pady $Gui(pad)

    set f $fVolumes.fTabbedFrame.fFile.fVol.fSave
    foreach frame "Left Right" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side left -padx 0 
        #-pady $Gui(pad)
    }
    DevAddLabel $f.fLeft.lPrefix "     Filename Prefix:" 
    pack $f.fLeft.lPrefix -side top -padx 3 -pady 3 -anchor w
    eval {entry $f.fRight.ePrefix -textvariable Editor(prefixSave)} $Gui(WEA)
    TooltipAdd $f.fRight.ePrefix "To save the Volume, enter the prefix here or just click Save."
    pack $f.fRight.ePrefix -side top -pady 3 -padx 5 -anchor w

    #-------------------------------------------
    # Volumes->TabbedFrame->File->Vol->Btns
    #-------------------------------------------
    eval {label $f.fLeft.lFormat -text "         Pick Format:"} $Gui(WLA)
    pack $f.fLeft.lFormat -side top -padx $Gui(pad) -pady 2  -anchor w
    
    eval {menubutton $f.fRight.mbFormat -text "NRRD(.nhdr)" -relief raised \
              -bd 2 -width 12 -menu $f.fRight.mbFormat.m} $Gui(WMBA)
    eval {menu $f.fRight.mbFormat.m} $Gui(WMA)
    set Editor(formatMenu) $f.fRight.mbFormat     
    
    #  Add menu items
    # Saving of nifti extentions .img and .img.gz doesn't work right now. For the extention .img itk defers to analyze.
    # Saving of nifti extention .img.gz is not supported yet by itk.
    foreach FileType {{Standard} {.pts} {hdr} {nrrd} {nhdr} {mhd} {mha} {nii} {nii.gz} {vtk}} \
        name {{Headerless} {.pts} {Analyze (.hdr)} {NRRD(.nrrd)} {NRRD(.nhdr)} \
                  {Meta (.mhd)} {Meta (.mha)} {Nifti (.nii)} {Nifti (.nii.gz)} {VTK (.vtk)}} { 
                      set Editor($FileType) $name
                      $f.fRight.mbFormat.m add command -label $name \
                          -command "EditorExportSetFileType $FileType"
                  }  
   
    pack $f.fRight.mbFormat -side top -padx 0 -pady 2  -anchor w
    EditorExportSetFileType nhdr 
    eval {label $f.fLeft.lComp -text "       Compression:"} $Gui(WLA)
    pack $f.fLeft.lComp -side top -padx $Gui(pad) -pady 2  -anchor w
    frame $f.fRight.fComp -bg $Gui(activeWorkspace)
    pack $f.fRight.fComp -side top -padx 0 -pady 2  -anchor w   
    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.fRight.fComp.rComp$value -width $width -indicatoron 0\
                  -text "$text" -value "$value" -variable Volume(UseCompression) \
              } $Gui(WCA)
        pack $f.fRight.fComp.rComp$value -side left -fill x
    }
    TooltipAdd $f.fRight.fComp.rComp1 \
        "Suggest to the Writer to compress the file if the format supports it."
    TooltipAdd $f.fRight.fComp.rComp0 \
        "Don't compress the file, even if the format supports it."
    
    frame $fVolumes.fTabbedFrame.fFile.fVol.fSaveButton -bg $Gui(activeWorkspace)
    pack $fVolumes.fTabbedFrame.fFile.fVol.fSaveButton -side top -padx 0 -pady 3
    
    eval {button $fVolumes.fTabbedFrame.fFile.fVol.fSaveButton.bWrite -text "Save" -width 5 \
              -command "EditorWriteVolume"} $Gui(WBA)
    TooltipAdd $fVolumes.fTabbedFrame.fFile.fVol.fSaveButton.bWrite "Save the Volume."
    pack $fVolumes.fTabbedFrame.fFile.fVol.fSaveButton.bWrite -side top -padx 2 -pady 2     
    
    ############################################################################
    #                                 Effects
    ############################################################################
    
    #-------------------------------------------
    # Effects frame
    #-------------------------------------------
    set fEffects $Module(Editor,fEffects)
    set f $fEffects
    
    frame $f.fEffects   -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fActive    -bg $Gui(activeWorkspace)
    frame $f.fTime      -bg $Gui(activeWorkspace)
    frame $f.fModel    -bg $Gui(activeWorkspace)
    frame $f.fDisplay    -bg $Gui(activeWorkspace)
    pack $f.fEffects $f.fActive $f.fTime $f.fDisplay $f.fModel \
        -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    #-------------------------------------------
    # Effects->Active frame
    #-------------------------------------------
    set f $fEffects.fActive
    
    eval {label $f.l -text "Active Slice:"} $Gui(WLA)
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    foreach s $Slice(idList) text "Red Yellow Green" width "4 7 6" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
                  -text "$text" -value "$s" -variable Slice(activeID) \
                  -command "MainSlicesSetActive"} $Gui(WCA) {-selectcolor $Gui(slice$s)}
        pack $f.r$s -side left -fill x -anchor e
    }
    
    #-------------------------------------------
    # Effects->Time frame
    #-------------------------------------------
    set f $fEffects.fTime
    
    eval {label $f.lRun -text "Run time:"} $Gui(WLA)
    eval {label $f.lRunTime -text "0 sec,"} $Gui(WLA)
    eval {label $f.lTotal -text "Total:"} $Gui(WLA)
    eval {label $f.lTotalTime -text "0 sec"} $Gui(WLA)
    pack $f.lRun $f.lRunTime $f.lTotal $f.lTotalTime \
        -side left -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    set Editor(lRunTime) $f.lRunTime
    set Editor(lTotalTime) $f.lTotalTime
    
    #-------------------------------------------
    # Effects->Display frame
    #-------------------------------------------
    set f $fEffects.fDisplay

    # put things that affect the way editor displays volumes here
    eval {label $f.lDisplay -text "Display Settings:"} $Gui(WLA)
    pack $f.lDisplay -side left -pady $Gui(pad) -padx $Gui(pad)
    
    eval {checkbutton $f.cEditorDisplayLabel \
        -text  "Outline Labelmap" -variable Editor(display,labelOn) \
              -width 21 -indicatoron 0 -command "EditorResetDisplay; RenderSlices"} $Gui(WCA)

    pack $f.cEditorDisplayLabel -side right -pady $Gui(pad) -padx $Gui(pad)
    TooltipAdd $f.cEditorDisplayLabel "Press to show/hide the label layer (the outline around your labelmap)."

    #-------------------------------------------
    # Effects->Model frame
    #-------------------------------------------
    set f $fEffects.fModel
    
    if {[IsModule ModelMaker] == 1} {
        eval {button $f.b -text "Make Model" -command "EditorMakeModel"} $Gui(WBA)
        pack $f.b
    }

    #-------------------------------------------
    # Effects->Effects
    #-------------------------------------------
    set f $fEffects.fEffects
    
    frame $f.fBtns -bg $Gui(backdrop)
    frame $f.fMore -bg $Gui(backdrop)
    frame $f.fUndo -bg $Gui(backdrop)
    pack $f.fBtns $f.fMore $f.fUndo -side top -pady $Gui(pad)
    
    #-------------------------------------------
    # Effects->Effects->More frame
    #-------------------------------------------
    set f $fEffects.fEffects.fMore
    
    # Have 10 effects visible, and hide the rest under "More"
    set cnt 0
    foreach e $Ed(idList) {
        set Ed($e,more) 0
        if {$cnt > [expr 10 - 1]} {
            set Ed($e,more) 1
        }
        incr cnt
    }        
    
    # Don't make the more button unless we'll use it
    set Editor(more) 0
    foreach e $Ed(idList) {
        if {$Ed($e,more) == 1} {set Editor(more) 1}
    }
    if {$Editor(more) == 1} {
        eval {menubutton $f.mbMore -text "More:" -relief raised -bd 2 \
                  -width 6 -menu $f.mbMore.m} $Gui(WMBA)
        eval {menu $f.mbMore.m} $Gui(WMA)
        eval {radiobutton $f.rMore -width 13 \
                  -text "None" -variable Editor(moreBtn) -value 1 \
                  -command "EditorSetEffect Menu" -indicatoron 0} $Gui(WCA)
        pack $f.mbMore $f.rMore -side left -padx $Gui(pad) -pady 0 
        
        set Editor(mbMore) $f.mbMore
        set Editor(rMore)  $f.rMore
    }
    
    #-------------------------------------------
    # Effects->Effects->Btns frame
    #-------------------------------------------
    set f $fEffects.fEffects.fBtns
    
    set row 0
    if {$Editor(more) == 1} {
        set moreMenu $Editor(mbMore).m
        $moreMenu delete 0 end
        set firstMore ""
    }
    # Display up to 2 effect buttons (e1,e2) on each row 
    foreach {e1 e2} $Ed(idList) {
        frame $f.$row -bg $Gui(inactiveWorkspace)
        
        foreach e "$e1 $e2" {
            # Either make a button for it, or add it to the "more" menu
            if {$Ed($e,more) == 0} {
                eval {radiobutton $f.$row.r$e -width 13 \
                          -text "$Ed($e,name)" -variable Editor(btn) -value $e \
                          -command "EditorSetEffect $e" -indicatoron 0} $Gui(WCA)
                pack $f.$row.r$e -side left -padx 0 -pady 0
            } else {
                if {$firstMore == ""} {
                    set firstMore $e
                }
                $moreMenu add command -label $Ed($e,name) \
                    -command "EditorSetEffect $e"
            }
        }
        pack $f.$row -side top -padx 0 -pady 0
        
        incr row
    }
    if {$Editor(more) == 1} {
        $Editor(rMore) config -text "$firstMore"
    }
    
    #-------------------------------------------
    # Effects->Effects->Undo frame
    #-------------------------------------------
    set f $fEffects.fEffects.fUndo
    
    eval {button $f.bUndo -text "Undo last effect" -width 17 \
              -command "EditorUndo; RenderAll"} $Gui(WBA) {-state disabled}
    pack $f.bUndo -side left -padx $Gui(pad) -pady 0
    
    set Editor(bUndo) $f.bUndo


    ############################################################################
    #                                 Details
    ############################################################################
    
    #-------------------------------------------
    # Details frame
    #-------------------------------------------
    set fDetails $Module(Editor,fDetails)
    set f $fDetails
    
    frame $f.fTitle  -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fEffect -height 338 -bg $Gui(activeWorkspace)
    pack $f.fTitle -side top -pady 5 -padx 2 -fill x
    pack $f.fEffect -side top -pady 0 -padx 2 -fill both -expand 1
    
    #-------------------------------------------
    # Details->Title frame
    #-------------------------------------------
    set f $fDetails.fTitle
    
    frame $f.fBar -bg $Gui(activeWorkspace)
    frame $f.fHelp -bg $Gui(activeWorkspace)
    pack $f.fBar $f.fHelp -side top -pady 2
    
    # List top 8 effects on a button bar across the top
    set f $fDetails.fTitle.fBar
    foreach e [lrange $Ed(idList) 0 7] {
        eval {radiobutton $f.r$e -width 2 -indicatoron 0\
                  -text $Ed($e,initials) -value $e -variable Editor(btn) \
                  -command "EditorSetEffect $e"} $Gui(WCA)
        TooltipAdd $f.r$e $Ed($e,name)
        pack $f.r$e -side left -fill x -anchor e
    }
    # Add an Undo button
    eval {button $f.bUndo -width 2 -text Un -command "EditorUndo; RenderAll"} \
        $Gui(WBA) {-state disabled}
    TooltipAdd $f.bUndo "Undo last effect applied"
    pack $f.bUndo -side left -fill x -anchor e
    set Editor(bUndo2) $f.bUndo
    
    set f $fDetails.fTitle.fHelp
    eval {label $f.lName -text "None"} $Gui(BLA)
    eval {label $f.lDesc -text "Does nothing."} $Gui(BLA)
    pack $f.lDesc

    set Editor(lEffectName) $f.lName
    set Editor(lEffectDesc) $f.lDesc
    
    #-------------------------------------------
    # Details->Effect frame
    #-------------------------------------------
    set f $fDetails.fEffect
    
    foreach e $Ed(idList) {
        frame $f.f$e -bg $Gui(activeWorkspace)
        place $f.f$e -in $f -relheight 1.0 -relwidth 1.0
        set Ed($e,frame) $f.f$e
    }

    
    ############################################################################
    #                                 Effects
    ############################################################################
    
    if {$Module(verbose) == 1} {
        puts Editor-GUI:
    }
    foreach e $Ed(idList) {
        if {[info exists Ed($e,procGUI)] == 1} {
            if {$Module(verbose) == 1} {
                puts $Ed($e,procGUI)
            }
            $Ed($e,procGUI)
        }
    }
    
    # Initialize to the first effect
    EditorSetEffect EdNone
}

#-------------------------------------------------------------------------------
# .PROC EditorEnter
# Called when the Editor panel is entered by the user. 
# If no "Original" volume has been selected, tries to set it to the one being 
# displayed as background.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorEnter {} {
    global Editor Volume Slice Module Ed

    # logging
    EditorStartTiming "Editor"

    # If the Original is None, then select what's being displayed,
    # otherwise the first volume in the mrml tree.

    if {[EditorGetOriginalID] == $Volume(idNone)} {
        set v [[[Slicer GetBackVolume $Slice(activeID)] GetMrmlNode] GetID]
        if {$v == $Volume(idNone)} {
            set v [lindex $Volume(idList) 0]
        }
        if {$v != $Volume(idNone)} {
            EditorSetOriginal $v
        }
    }

    # use the bindings stack for adding new bindings.
    pushEventManager $Editor(eventManager)

    # update GUI
    EditorSetSaveVolume

}


#-------------------------------------------------------------------------------
# .PROC EditorExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorExit {} {
    global Editor Ed Module

    # undo any new bindings we may have added
    popEventManager

    set e $Editor(activeID)

    # now the active effect is None (this exits from current effect, too)
    EditorSetEffect EdNone
    # start out at the volumes tab next (and every) time
    set Module(Editor,row1,tab) Volumes

    # logging
    EditorStopTiming "Editor"
}

#-------------------------------------------------------------------------------
# .PROC EditorMakeModel
# Sets the active volume (to the first one of Composite, Working, or Original 
# that has been defined by the user).  Then tabs to ModelMaker panel. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorMakeModel {} {
    global Editor

    if {$Editor(idComposite) == "NEW"} {
        if {$Editor(idWorking) == "NEW"} {
            MainVolumesSetActive [EditorGetOriginalID]
        } else {
            MainVolumesSetActive [EditorGetWorkingID]
        }
    } else {
        MainVolumesSetActive [EditorGetCompositeID]
    }
    Tab ModelMaker row1 Create
}

################################################################################
#                             Event Bindings
################################################################################

#-------------------------------------------------------------------------------
# .PROC EditorMotion
# Effect-specific response to mouse motion. 
# Currently only used for LiveWire.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorMotion {x y} {
    global Ed Editor 

    switch $Editor(activeID) {
        "EdDraw2" {
            switch $Ed(EdDraw2,mode) {
                "Draw" {
                    # Do nothing
                }
                "Select" {
                    set inside [Slicer DrawIsNearSelected $x $y]
                    if {$inside == 1} {
                        set Ed(EdDraw2,mode) Move
                    }
                }
                "Move" {
                    set inside [Slicer DrawIsNearSelected $x $y]
                    if {$inside == 0} {
                        set Ed(EdDraw2,mode) Select
                    }
                }
            }
            EditorIncrementAndLogEvent "motion"
        }
        "EdDraw" {
            # do nothing
        }
        "EdLiveWire" {
            EdLiveWireMotion $x $y
            # log this event since it's used by the module
            EditorIncrementAndLogEvent "motion"    
        }
        "EdPhaseWire" {
            EdPhaseWireMotion $x $y
            # log this event since it's used by the module
            EditorIncrementAndLogEvent "motion"    
        }
        "EdPaint" {
            EdPaintMotion $x $y
        }
    }
    
}

#-------------------------------------------------------------------------------
# .PROC EditorB1
# Effect-specific response to B1 mouse click.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorB1 {x y} {
    global Ed Editor 

    EditorIncrementAndLogEvent "b1click"
    
    switch $Editor(activeID) {
        "EdDraw2" {
            # Mark point for moving
            Slicer DrawMoveInit $x $y
            
            # Act depending on the draw mode:
            #  - Draw:   Insert a point
            #  - Select: Select/deselect a point
            #  - Insert: Insert a point between two points (CTJ)
            #
            #set coords [EditorClampToOriginalBounds $x $y]
            #set x [lindex $coords 0]
            #set y [lindex $coords 1]
            switch $Ed(EdDraw2,mode) {
                "Draw" {
                    Slicer DrawInsertPoint $x $y
                    #EditorInsertPoint $x $y
                }
                "Select" {
                    Slicer DrawDeselectAll
                    Slicer DrawStartSelectBox $x $y
                }
                "Insert" {
                    Slicer DrawInsert $x $y
                }
            }
        }
        "EdDraw" {
            # Mark point for moving
            Slicer DrawMoveInit $x $y
            
            # Act depending on the draw mode:
            #  - Draw:   Insert a point
            #  - Select: Select/deselect a point
            #
            switch $Ed(EdDraw,mode) {
                "Draw" {
                    Slicer DrawInsertPoint $x $y
                }
                "Select" {
                    Slicer DrawStartSelectBox $x $y
                }
            }

            if { $::Editor(toggleAutoSample) } {
                if { [[Slicer DrawGetPoints] GetNumberOfPoints] == "1" } {
                    # if this is the first point clicked and you are in Auto mode, 
                    # then update the color to be the current foreground color
                    EdDrawUpdate "CurrentSample"
                }
            }
        }
        "EdPaint" {
            EdPaintB1 $x $y
        }
        "EdLiveWire" {
            EdLiveWireB1 $x $y
        }
        "EdPhaseWire" {
            EdPhaseWireB1 $x $y
        }
        "EdChangeIsland" {
            EditorChangeInputLabel $x $y
        }
        "EdMeasureIsland" {
            EditorChangeInputLabel $x $y
        }
        "EdSaveIsland" {
            EditorChangeInputLabel $x $y
        }
        "EdChangeLabel" {
            EditorChangeInputLabel $x $y
        }
        "EdRemoveIslands" {
            EditorChangeInputLabel $x $y
        }
        "EdIdentifyIslands" {
            EditorChangeInputLabel $x $y
        }
        "EdLabelVOI" {
            EdLabelVOIB1 $x $y
        }
        default {
            # the default case handles editor effects loaded as modules
            # - in the future we may need a way to register custom
            #   actions

        }
    }
}


#-------------------------------------------------------------------------------
# .PROC EditorIdleProc
# Something to do when all events are idle (e.g. for draw update)
# Currently only used for Draw.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorIdleProc { cmd {respawn 1} } {
    global Ed Editor Slice Interactor

    set s $Slice(activeID)

    switch $Editor(activeID) {
        "EdDraw" {
            # Act depending on the draw mode:
            #  - Move:   nothing
            #  - Draw:   show current state of effect
            #  - Select: nothing
            #
            switch $Ed(EdDraw,mode) {
                "Draw" {
                    switch $cmd {
                        "start" {
                            set Ed(EdDraw,lastIdlePointCount) 0
                            if {![info exists Ed(EdDraw,afterID)] || $Ed(EdDraw,afterID) == ""} {
                                set Ed(EdDraw,afterID) [after idle "EditorIdleProc apply $respawn"]
                            }
                        }
                        "apply" {
                            set p __EditorIdleProc_Points
                            catch "$p Delete"
                            vtkPoints $p
                            $p DeepCopy [Slicer DrawGetPoints]
                            set pts [$p GetNumberOfPoints]
                            if {$Ed(EdDraw,lastIdlePointCount) != $pts} {
                                set Ed(EdDraw,lastIdlePointCount) $pts
                                EdDrawApply
                                EditorUndo false
                                for {set i 0} {$i < $pts} {incr i} {

                                    eval Slicer DrawInsertPoint [lrange [$p GetPoint $i] 0 1]
                                }
                            }
                            $p Delete
                            if {$respawn && [info exists Ed(EdDraw,afterID)] && $Ed(EdDraw,afterID) != ""} {
                                set Ed(EdDraw,afterID) [after idle "EditorIdleProc apply"]
                            }
                        }
                        "cancel" {
                            catch {after cancel $Ed(EdDraw,afterID)}
                            set Ed(EdDraw,afterID) ""
                            set Ed(EdDraw,lastIdlePointCount) 0
                        }
                    }
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorInsertPoint
# wrapper around Slicer DrawInsertPoint to allow apply and undo
# .ARGS
# xy point to insert, or "update" to refresh (eg. after delete)
# .END
#-------------------------------------------------------------------------------
proc EditorInsertPoint {{x "update"} {y "update"}} {
    global Ed Editor Slice Interactor

    if {$x != "update"} {
        Slicer DrawInsertPoint $x $y
    }

    set p __EditorPending_Points

    if { [info command $p] == "" } {
        # no pending points means first mouse down after apply, 
        # so just save the point
        vtkPoints $p
        $p DeepCopy [Slicer DrawGetPoints]
    } else {

        set pts [[Slicer DrawGetPoints] GetNumberOfPoints]
        # - save the current points in $p
        # - undo the effect from before
        # - reapply the effect with the new points

        $p DeepCopy [Slicer DrawGetPoints]
        EditorUndo false ;# don't redraw
        EdDrawApply false ;# don't delete pending
        for {set i 0} {$i < $pts} {incr i} {
            eval Slicer DrawInsertPoint [lrange [$p GetPoint $i] 0 1]
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorB1Motion
# Effect-specific response to B1 mouse motion. 
# Currently only used for Draw.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorB1Motion {x y} {
    global Ed Editor Slice Interactor

    EditorIncrementAndLogEvent "b1motion"

    set s $Slice(activeID)

    switch $Editor(activeID) {
        "EdDraw2" {
            # Act depending on the draw mode:
            #  - Move:   move points
            #  - Draw:   Insert a point
            #  - Select: draw the "select" box
            #
            switch $Ed(EdDraw2,mode) {
                "Draw" {
                    #set coords [EditorClampToOriginalBounds $x $y]
                    #set x [lindex $coords 0]
                    #set y [lindex $coords 1]
                    if {1} {
                        # this way just inserts the point normally
                        # (CTJ) to disable click and drag, comment this line:
                        Slicer DrawInsertPoint $x $y
                    } else {
                        # this way applies to show the rasterized labelmap
                        # and stores the points to support delete
                        # (this way isn't fully debugged)
                        EditorInsertPoint $x $y
                    }


                    # Lauren this would be better:
                    
                    # DAVE: allow drawing on non-native slices someday
                    #            Slicer SetReformatPoint $s $x $y
                    #            scan [Slicer GetIjkPoint] "%g %g %g" i j k
                    #            puts "Slicer DrawInsertPoint $x $y ijk=$i $j $k s=$s"
                }
                "Select" {
                    #set coords [EditorClampToOriginalBounds $x $y]
                    #set x [lindex $coords 0]
                    #set y [lindex $coords 1]
                    Slicer DrawDragSelectBox $x $y
                }
                "Move" {
                    Slicer DrawMove $x $y
                }
            }
        }
        "EdDraw" {
            # Act depending on the draw mode:
            #  - Move:   move points
            #  - Draw:   Insert a point
            #  - Select: draw the "select" box
            #
            switch $Ed(EdDraw,mode) {
                "Draw" {
                    if {1} {
                        # this way just inserts the point normally
                        Slicer DrawInsertPoint $x $y
                    } else {
                        # this way applies to show the rasterized labelmap
                        # and stores the points to support delete
                        # (this way isn't fully debugged)
                        EditorInsertPoint $x $y
                    }


                    # Lauren this would be better:
                    
                    # DAVE: allow drawing on non-native slices someday
                    #            Slicer SetReformatPoint $s $x $y
                    #            scan [Slicer GetIjkPoint] "%g %g %g" i j k
                    #            puts "Slicer DrawInsertPoint $x $y ijk=$i $j $k s=$s"
                }
                "Select" {
                    Slicer DrawDragSelectBox $x $y
                }
                "Move" {
                    Slicer DrawMove $x $y
                }
            }
        }
        "EdPaint" {
            EdPaintB1Motion $x $y
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorB1Release
# Effect-specific response to B1 mousebutton release.
# Currently only used for Draw.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorB1Release {x y} {
    global Ed Editor
    
    switch $Editor(activeID) {
        "EdDraw2" {
            # Act depending on the draw mode:
            #  - Select: stop drawing the "select" box
            #
            #set coords [EditorClampToOriginalBounds $x $y]
            #set x [lindex $coords 0]
            #set y [lindex $coords 1]
            switch $Ed(EdDraw2,mode) {
                "Select" {
                    Slicer DrawEndSelectBox $x $y
                }
                "Draw" {
                    #EditorIdleProc cancel
                    #EditorIdleProc start 0
                }
            }
        }
        "EdDraw" {
            # Act depending on the draw mode:
            #  - Select: stop drawing the "select" box
            #
            switch $Ed(EdDraw,mode) {
                "Select" {
                    Slicer DrawEndSelectBox $x $y
                }
                "Draw" {
                    #EditorIdleProc cancel
                    #EditorIdleProc start 0
                }
            }
        }
        "EdPaint" {
            EdPaintB1Release $x $y
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorChangeInputLabel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorChangeInputLabel {x y} {
    global Ed Editor Label
    
    set e $Editor(activeID)
    
    # Determine the input label
    set s [Slicer GetActiveSlice]
    if {[info exists Ed($e,input)] == 1 && $Ed($e,input) == "Original"} {
        set Ed($e,inputLabel) [Slicer GetBackPixel $s $x $y]
    } else {
        set Ed($e,inputLabel) [Slicer GetForePixel $s $x $y]
    }
    
    # Get the seed
    set s [Slicer GetActiveSlice]
    Slicer SetReformatPoint $s $x $y
    if {$Ed($e,scope) == "Single"} {
        scan [Slicer GetSeed2D] "%d %d %d" xSeed ySeed zSeed
    } else {
        scan [Slicer GetSeed] "%d %d %d" xSeed ySeed zSeed
    }
    set Ed($e,xSeed) $xSeed
    set Ed($e,ySeed) $ySeed
    set Ed($e,zSeed) $zSeed

    # Apply the effect
    ${e}Apply
}


################################################################################
#                             EFFECTS
################################################################################


#-------------------------------------------------------------------------------
# .PROC EditorSetOriginal
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorSetOriginal {v} {
    global Editor Volume
    
    if {$v == $Editor(idWorking)} {
        DevErrorWindow "The Original and Working volumes must differ."
        return
    }

    if { $v != $Volume(idNone)
         && [[Volume($v,vol) GetOutput] GetNumberOfScalarComponents] != 1 } {
        DevErrorWindow "Original (background) volume must have 1 scalar component.\n\nTry editing with a different volume and changing the background using the Bg button on the slice views."
        return
    }
    set Editor(idOriginal) $v
    
    # Change button text
    $Editor(mbOriginal) config -text [Volume($v,node) GetName]
    
    # Update the display and the effect.
    if {$Editor(activeID) != "EdNone"} {
        # Display the original in the background layer of the slices
        EditorResetDisplay
        
        # Refresh the effect, if it's an interactive one
        EditorUpdateEffect
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorSetWorking
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorSetWorking {v} {
    global Editor Volume Gui
    
    if {$v == [EditorGetOriginalID]} {
        tk_messageBox -message "The Original and Working volumes must differ."
        return
    }
    if {$v == $Editor(idComposite) && $v != "NEW"} {
        tk_messageBox -message "The Composite and Working volumes must differ."
        return
    }
    set Editor(idWorking) $v
    
    # Change button text, show name and file prefix
    if {$v == "NEW"} {
        $Editor(mbWorking) config -text $v
        set Editor(prefixWorking) ""
        set Editor(nameWorking) Working
        eval {$Editor(eNameWorking) configure -state normal}  $Gui(WEA)
    } else {
        $Editor(mbWorking) config -text [Volume($v,node) GetName]
        set Editor(prefixWorking) [MainFileGetRelativePrefix \
                                       [Volume($v,node) GetFilePrefix]]
        set Editor(nameWorking) [Volume($v,node) GetName]
        # Disable name entry field if not NEW volume
        eval {$Editor(eNameWorking) configure -state disabled} $Gui(WEDA)
    }
    
    # Refresh the effect, if it's an interactive one
    EditorUpdateEffect
}

#-------------------------------------------------------------------------------
# .PROC EditorSetComposite
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorSetComposite {v} {
    global Editor Volume Gui

    if {$v == [EditorGetOriginalID]} {
        tk_messageBox -message "The Original and Composite volumes must differ."
        return
    }
    if {$v == $Editor(idWorking) && $v != "NEW"} {
        tk_messageBox -message "The Working and Composite volumes must differ."
        return
    }
    set Editor(idComposite) $v
    
    # Change button text, and show file prefix
    if {$v == "NEW"} {
        $Editor(mbComposite) config -text $v
        set Editor(prefixComposite) ""
        set Editor(nameComposite) Composite
        eval {$Editor(eNameComposite) configure -state normal}  $Gui(WEA)
    } else {
        $Editor(mbComposite) config -text [Volume($v,node) GetName]
        set Editor(prefixComposite) [MainFileGetRelativePrefix \
                                         [Volume($v,node) GetFilePrefix]]
        set Editor(nameComposite) [Volume($v,node) GetName]
        # Disable name entry field if not NEW volume
        eval {$Editor(eNameComposite) configure -state disabled} $Gui(WEDA)
    }
    
    # Refresh the effect, if it's an interactive one
    EditorUpdateEffect
}

#-------------------------------------------------------------------------------
# .PROC EditorUpdateEffect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorUpdateEffect {} {
    global Editor Ed
    
    # logging
    # this is the only place where procEnters are called, so:
    EditorStartTiming $Editor(activeID)

    # Call the Enter procedure of the active effect
    set e $Editor(activeID)
    if {[info exists Ed($e,procEnter)] == 1} {
        $Ed($e,procEnter)
    }

}

#-------------------------------------------------------------------------------
# .PROC EditorSameExtents
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorSameExtents {dst src} {
    set dstExt [[Volume($dst,vol) GetOutput] GetExtent]
    set srcExt [[Volume($src,vol) GetOutput] GetExtent]
    if {$dstExt == $srcExt} {
        return 1
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC EditorCopyNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorCopyNode {dst src} {
    global Volume Lut

    Volume($dst,vol) CopyNode Volume($src,vol)
    Volume($dst,node) InterpolateOff
    Volume($dst,node) LabelMapOn
    Volume($dst,node) SetLUTName $Lut(idLabel)

    # all label maps must be of type Short to work with the imaging algorithms,
    # even if the original volume is float
    Volume($dst,node) SetScalarType 4
}

#-------------------------------------------------------------------------------
# .PROC EditorGetOriginalID
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorGetOriginalID {} {
    global Editor
    
    return $Editor(idOriginal)
}

#-------------------------------------------------------------------------------
# .PROC EditorGetWorkingID
#
# Returns the working volume's ID.
# If there is no working volume (Editor(idWorking)==NEW), then it creates one.
# .END
#-------------------------------------------------------------------------------
proc EditorGetWorkingID {} {
    global Editor Volume Lut

    # If there is no Working volume, then create one
    if {$Editor(idWorking) != "NEW"} {
        return $Editor(idWorking)
    }
    
    # Create the node
    set n [MainMrmlAddNode Volume]
    set v [$n GetID]

    $n SetDescription "Working Volume=$v"
    $n SetLUTName     $Lut(idLabel)
    $n InterpolateOff
    $n LabelMapOn
    
    # Make sure the name entered is okay, else use default
    if {[ValidateName $Editor(nameWorking)] == 0} {
        tk_messageBox -message "The Descriptive Name can consist of letters, digits, dashes, or underscores only. Using default name Working"
        $n SetName Working
    } else {
        $n SetName $Editor(nameWorking)   
    }
    
    # Create the volume
    MainVolumesCreate $v
    Volume($v,vol) UseLabelIndirectLUTOn

    EditorSetWorking $v

    # This updates all the buttons to say that the
    # Volume List has changed.
    MainUpdateMRML

    return $v
}

#-------------------------------------------------------------------------------
# .PROC EditorGetCompositeID
#
# Returns the composite volume's ID.
# If there is no composite volume (Editor(idComposite)==NEW), then it creates one.
# .END
#-------------------------------------------------------------------------------
proc EditorGetCompositeID {} {
    global Editor Dag Volume Lut

    # If there is no Composite volume, then create one
    if {$Editor(idComposite) != "NEW"} {
        return $Editor(idComposite)
    }
    
    # Create the node
    set n [MainMrmlAddNode Volume]
    set v [$n GetID]
    $n SetDescription "Composite Volume=$v"
    $n SetName        "Composite"
    $n SetLUTName     $Lut(idLabel)
    $n InterpolateOff
    $n LabelMapOn

    # Make sure the name entered is okay, else use default
    if {[ValidateName $Editor(nameComposite)] == 0} {
        tk_messageBox -message "The Descriptive Name can consist of letters, digits, dashes, or underscores only. Using default name Composite"
        $n SetName Composite
    } else {
        $n SetName $Editor(nameComposite)   
    }

    # Create the volume
    MainVolumesCreate $v
    Volume($v,vol) UseLabelIndirectLUTOn
    
    EditorSetComposite $v
    
    MainUpdateMRML

    return $v
}


#-------------------------------------------------------------------------------
# .PROC EditorResetDisplay
# This procedure sets up the slice orientations, the volumes,
# and the other things you notice when you enter an effect.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorResetDisplay {} {
    global Slice Editor Volume
    
    # Set slice orientations (unless already done)
    set s0 [Slicer GetOrientString 0]
    set s1 [Slicer GetOrientString 1]
    set s2 [Slicer GetOrientString 2]
    if {$s0 != "AxiSlice" || $s1 != "SagSlice" || $s2 != "CorSlice"} {
        MainSlicesSetOrientAll Slices
    }

    # Set slice volumes
    set o [EditorGetOriginalID]
    set oldid $Editor(idWorking)
    set w [EditorGetWorkingID]

    # put the new working volume inside the same transform as the Original volume
    if { $oldid == "NEW" } {
        set nitems [Mrml(dataTree) GetNumberOfItems]
        for {set widx 0} {$widx < $nitems} {incr widx} {
            if { [Mrml(dataTree) GetNthItem $widx] == "Volume($w,node)" } {
                break
            }
        }
        if { $widx < $nitems } {
            Mrml(dataTree) RemoveItem $widx
            Mrml(dataTree) InsertAfterItem Volume($o,node) Volume($w,node)
            MainUpdateMRML
        }
    }


    # display label layer only if the user wants it shown
    if {$Editor(display,labelOn) == 1} {
        set lab $w
    } else {
        set lab $Volume(idNone)
    }

    set ok 1
    foreach s $Slice(idList) {
        set b [[[Slicer GetBackVolume  $s] GetMrmlNode] GetID]
        set f [[[Slicer GetForeVolume  $s] GetMrmlNode] GetID]
        set l [[[Slicer GetLabelVolume $s] GetMrmlNode] GetID]
        if {$b != $o} {set ok 0}
        if {$f != $w} {set ok 0}
        if {$l != $lab} {set ok 0}
    }
    if {$ok == 0} {
        MainSlicesSetVolumeAll Back  $o
        MainSlicesSetVolumeAll Fore  $w
        MainSlicesSetVolumeAll Label $lab    
    }

    # Do these things only once
    if {$Editor(firstReset) == 0} {
        set Editor(firstReset) 1
        
        # Slice opacity
        MainSlicesSetOpacityAll 0.3
        MainSlicesSetFadeAll 0
        
        # Cursor
        MainAnnoSetHashesVisibility slices 0
        
        # Show all slices in 3D
        MainSlicesSetVisibilityAll 1
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorToggleWorking
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorToggleWorking {} {
    global Editor
    
    if {$Editor(toggleWorking) == 1} {
        EditorHideWorking
    } else {
        EditorShowWorking
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorHideWorking
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorHideWorking {} {
    global Volume
    
    MainSlicesSetVolumeAll Fore  $Volume(idNone)
    MainSlicesSetVolumeAll Label $Volume(idNone)
    
    RenderSlices
}

#-------------------------------------------------------------------------------
# .PROC EditorShowWorking
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorShowWorking {} {
    global Editor Volume
    
    set w [EditorGetWorkingID]    
    MainSlicesSetVolumeAll Fore  $w
    if {$Editor(display,labelOn) == 1} {
        MainSlicesSetVolumeAll Label $w
    } else {
        MainSlicesSetVolumeAll Label $Volume(idNone)
    }
    
    RenderSlices
}

#-------------------------------------------------------------------------------
# .PROC EditorSetEffect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorSetEffect {e} {
    global Editor Gui Ed Volume
    
    # If "menu" then use currently selected menu item
    if {$e == "Menu"} {
        set name [$Editor(rMore) cget -text]
        foreach ee $Ed(idList) {
            if {$Ed($ee,name) == $name} {
                set e $ee
            }
        }
    }
    
    # Remember prev
    set prevID $Editor(activeID)
    
    # Set new
    set Editor(activeID) $e
    set Editor(btn) $e

    # Toggle more radio button
    if {$Ed($e,more) == 1} {
        set Editor(moreBtn) 1
        $Editor(rMore) config -text $Ed($e,name)    
    } else {
        set Editor(moreBtn) 0
    }
    
    # Reset Display
    if {$e != "EdNone"} {
        EditorResetDisplay
        RenderAll
    }
    
    # Describe effect atop the "Details" frame
    $Editor(lEffectName) config -text $Ed($e,name)
    $Editor(lEffectDesc) config -text $Ed($e,desc)
    
    # Jump there
    if {$e != "EdNone"} {
        Tab Editor row1 Details
    }

    # Execute Exit procedure (if one exists for the prevID module)
    # and the Enter procedure of the new module.
    # But don't do this if there's no change.
    #
    if {$e != $prevID} {
        EditorExitEffect $prevID

        # Show "Details" frame (GUI for the new effect)
        raise $Ed($e,frame)

        # execute enter procedure
        EditorUpdateEffect
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorExitEffect
# Calls the exit procedure of the effect, if one exists
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorExitEffect {effect} {
    global Ed

    if {[info exists Ed($effect,procExit)] == 1} {
        $Ed($effect,procExit)
    }

    # logging
    # this is the only place where procExits are called, so:
    EditorStopTiming $effect
}

#-------------------------------------------------------------------------------
# .PROC EditorGetInputID
#
# Returns the original volume's ID if input="Original", else the working volume
# .END
#-------------------------------------------------------------------------------
proc EditorGetInputID {input} {
    global Editor

    if {$input == "Original"} {
        set v [EditorGetOriginalID]
    } else {
        set v [EditorGetWorkingID]
    }
    return $v
}

#-------------------------------------------------------------------------------
# .PROC EditorActivateUndo
#
# Sets Editor(undoActive) to active.
# Disable/Enables Editor(bUndo).
# .END
#-------------------------------------------------------------------------------
proc EditorActivateUndo {active} {
    global Editor

    set Editor(undoActive) $active
    if {$Editor(undoActive) == 0} {
        $Editor(bUndo) config -state disabled
        $Editor(bUndo2) config -state disabled
    } else {
        $Editor(bUndo) config -state normal
        $Editor(bUndo2) config -state normal
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorUpdateAfterUndo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorUpdateAfterUndo { {render "true"} } {
    global Ed Editor Volume Slice
    
    set w [EditorGetWorkingID]
    set e $Editor(activeID)

    # Get output from editor
    Volume($w,vol) SetImageData [Ed(editor) GetOutput]
    EditorActivateUndo [Ed(editor) GetUndoable]

    # Restore MrmlNode
    Volume($w,node) Copy Editor(undoNode)

    # Update pipeline and GUI
    MainVolumesUpdate $w

    # Update the effect panel GUI by re-running it's Enter procedure
    EditorUpdateEffect
    
    # Mark the volume as changed
    set Volume($w,dirty) 1
    
    if {$render == "true"} {
        RenderAll
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorUndo
#
# Undo the last effect
# Disable the Undo button
# .END
#-------------------------------------------------------------------------------
proc EditorUndo { {render "true"} } {
    global Volume Ed
    
    # Undo the working volume
    Ed(editor) Undo
    EditorUpdateAfterUndo $render
}


################################################################################
#                         DETAILS 
################################################################################

# These are helper functions for the Effects files to call.
# No procedures in this section are called by anything other than Effects files.

#-------------------------------------------------------------------------------
# .PROC EdBuildScopeGUI
#
# not = [Single | Multi | 3D]
# .END
#-------------------------------------------------------------------------------
proc EdBuildScopeGUI {f var {not ""}} {
    global Gui
    
    switch $not {
        Single {
            set modes "Multi 3D"
            set names "{Multi Slice} {3D}"
            set tips "{Apply effect to each slice} {Apply effect in 3D}"
        }
        Multi {
            set modes "Single 3D"
            set names "{1 Slice} {3D}"
            set tips "{Apply effect to one slice only} {Apply effect in 3D}"
        }
        3D {
            set modes "Single Multi"
            set names "{1 Slice} {Multi Slice}"
            set tips "{Apply effect to one slice only} {Apply effect to each slice}"
        }
        default {
            set modes "Single Multi 3D"
            set names "{1 Slice} {Multi Slice} {3D}"
            set tips "{Apply effect to one slice only} {Apply effect to each slice} {Apply effect in 3D}"
        }
    }
    eval {label $f.l -text "Scope:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    foreach mode $modes name $names tip $tips {
        eval {radiobutton $f.f.r$mode -width [expr [string length $name]+1]\
                  -text "$name" -variable $var -value $mode \
                  -indicatoron 0} $Gui(WCA)
        pack $f.f.r$mode -side left -padx 0 -pady 0
        TooltipAdd $f.f.r$mode $tip
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w
}

#-------------------------------------------------------------------------------
# .PROC EdBuildMultiGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdBuildMultiGUI {f var} {
    global Gui
    
    eval {label $f.l -text "Multi-Slice Orient:"} $Gui(WLA)
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    foreach s "Native Active" text "Native Active" width "7 7" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
                  -text "$text" -value "$s" -variable $var} $Gui(WCA)
        pack $f.r$s -side left -fill x -anchor e
    }
}

#-------------------------------------------------------------------------------
# .PROC EdBuildInputGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdBuildInputGUI {f var {options ""}} {
    global Gui
    
    eval {label $f.l -text "Input Volume:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    set tips "{Apply effect to Original volume} \
        {Apply effect to Working labelmap}"

    foreach input "Original Working" tip $tips {
        eval {radiobutton $f.f.r$input \
                  -text "$input" -variable $var -value $input -width 8 \
                  -indicatoron 0} $options $Gui(WCA)
        pack $f.f.r$input -side left -padx 0
        TooltipAdd $f.f.r$input $tip
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w
}

#-------------------------------------------------------------------------------
# .PROC EdBuildInteractGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdBuildInteractGUI {f var {options ""}} {
    global Gui
    
    set modes "Active Slices All"
    set names "{1 Slice} {3 Slices} {3D}"
    set tips "{Render (re-draw) one slice when you change settings} \
        {Render (re-draw) all three slices when you change settings} \
        {Render (re-draw) all slices and 3D window when you change settings}"
    
    eval {label $f.l -text "Interact:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    foreach mode $modes name $names tip $tips {
        eval {radiobutton $f.f.r$mode -width [expr [string length $name]+1]\
                  -text "$name" -variable $var -value $mode \
                  -indicatoron 0} $options $Gui(WCA)
        pack $f.f.r$mode -side left -padx 0 -pady 0
        TooltipAdd $f.f.r$mode $tip
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w
}

#-------------------------------------------------------------------------------
# .PROC EdBuildRenderGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdBuildRenderGUI {f var {options ""}} {
    global Gui
    
    set modes "Active Slices All"
    set names "{1 Slice} {3 Slices} {3D}"
    set tips "{Render (re-draw) one slice when you apply} \
        {Render (re-draw) all three slices when you apply} \
        {Render (re-draw) all slices and 3D window when you apply}"

    eval {label $f.l -text "Render:"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    foreach mode $modes name $names tip $tips {
        eval {radiobutton $f.f.r$mode -width [expr [string length $name]+1]\
                  -text "$name" -variable $var -value $mode \
                  -indicatoron 0} $options $Gui(WCA)
        pack $f.f.r$mode -side left -padx 0 -pady 0
        TooltipAdd $f.f.r$mode $tip
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w
}

#-------------------------------------------------------------------------------
# .PROC EdIsNativeSlice
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdIsNativeSlice {} {
    global Ed
    
    set outOrder [Ed(editor) GetOutputSliceOrder]
    set inOrder  [Ed(editor) GetInputSliceOrder]
    
    # Output order is one of IS, LR, PA
    if {$inOrder == "RL"} {set inOrder LR}
    if {$inOrder == "AP"} {set inOrder PA}
    if {$inOrder == "SI"} {set inOrder IS}

    if {$outOrder != $inOrder} {
        if {$inOrder == "LR"} {
            set native SagSlice
        }
        if {$inOrder == "PA"} {
            set native CorSlice
        }
        if {$inOrder == "IS"} {
            set native AxiSlice
        }
        return $native
    }
    return ""
}

#-------------------------------------------------------------------------------
# .PROC EdSetupBeforeApplyEffect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdSetupBeforeApplyEffect {v scope multi} {
    global Volume Ed Editor Gui
    
    set o [EditorGetOriginalID]
    set w [EditorGetWorkingID]
    
    if {[EditorSameExtents $w $o] != 1} {
        EditorCopyNode $w $o
        MainVolumesCopyData $w $o On

        # force the working volume to be of type short
        set workvol [Volume($w,vol) GetOutput]
        set worktype [$workvol GetScalarType]
        # 4 is the ID of short in VTK
        if {$worktype != "4"} {
            $workvol SetScalarType 4
            $workvol AllocateScalars

            # we should then make sure this volume is initalized to 0
            EditorClear Working
        }
    }
    
    # Set the editor's input & output
    Ed(editor) SetInput [Volume($o,vol) GetOutput]
    if {$v == $w} {
        Ed(editor) SetOutput [Volume($w,vol) GetOutput]
        Ed(editor) UseInputOff
    } else {
        Ed(editor) UseInputOn
    }
    
    Ed(editor) SetDimensionTo$scope
    
    # Set the slice orientation and number
    # (not used for 3D)
    
    set s      [Slicer GetActiveSlice]
    set orient [Slicer GetOrientString $s]
    set slice  [Slicer GetOffset $s]
    
    if {[lsearch "AxiSlice CorSlice SagSlice" $orient] == -1} {
        tk_messageBox -icon warning -title $Gui(title) -message \
            "The orientation of the active slice\n\
            must be one of: AxiSlice, CorSlice, SagSlice"
        return
    }
    switch $orient {
        "AxiSlice" {
            set order IS
        }
        "SagSlice" {
            set order LR
        }
        "CorSlice" {
            set order PA
        }
    }
    
    # Does the user want the orien of the active slice or native slices?
    if {$scope == "Multi" && $multi == "Native"} {
        set order [Volume($o,node) GetScanOrder]
    }
    switch $order {
        "SI" {
            set order IS
        }
        "RL" {
            set order LR
        }
        "AP" {
            set order PA
        }
    }
    
    Ed(editor) SetOutputSliceOrder $order
    Ed(editor) SetInputSliceOrder [Volume($v,node) GetScanOrder]
    Ed(editor) SetSlice $slice
}

#-------------------------------------------------------------------------------
# .PROC EdUpdateAfterApplyEffect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdUpdateAfterApplyEffect {v {render All}} {
    global Ed Volume Lut Editor Slice
    
    set o [EditorGetOriginalID]
    set w [EditorGetWorkingID]
    
    # Get output from editor
    Volume($w,vol) SetImageData [Ed(editor) GetOutput]
    EditorActivateUndo [Ed(editor) GetUndoable]
    
    # w copies o's MrmlNode if the Input was the Original
    if {$v == $o} {
        EditorCopyNode $w $o
    }
    
    # Keep a copy for undo
    Editor(undoNode) Copy Volume($w,node)
    
    # Update pipeline and GUI
    MainVolumesUpdate $w
    
    # Render
    Render$render
    
    # Mark the volume as changed
    set Volume($w,dirty) 1
    
    $Editor(lRunTime)   config -text \
        "[format "%.2f" [Ed(editor) GetRunTime]] sec,"
    $Editor(lTotalTime) config -text \
        "[format "%.2f" [Ed(editor) GetTotalTime]] sec"
}


################################################################################
#                           OUTPUT
################################################################################

#-------------------------------------------------------------------------------
# .PROC EditorWrite
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorWrite {data} {
    global Volume Editor
    
    # If the volume doesn't exist yet, then don't write it, duh!
    if {$Editor(id$data) == "NEW"} {
        tk_messageBox -message "Nothing to write."
        return
    }
    
    switch $data {
        Composite {set v [EditorGetCompositeID]}
        Working   {set v [EditorGetWorkingID]}
    }
    
    # Show user a File dialog box
    set Editor(prefix$data) [MainFileSaveVolume $v $Editor(prefix$data)]
    if {$Editor(prefix$data) == ""} {return}
    
    # Write
    MainVolumesWrite $v $Editor(prefix$data)
    
    # Prefix changed, so update the Volumes->Props tab
    MainVolumesSetActive $v
}


#-------------------------------------------------------------------------------
# .PROC EditorSetSaveVolume
# Called when the user chooses a volume from the Save menu.
# Just sets the right filename prefix in the entry box now.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorSetSaveVolume {} {
    global Volume Editor

    # get the chosen volume
    set v $Volume(activeID)

    # update File (Save) GUI
    set Editor(prefixSave) [MainFileGetRelativePrefix \
                                [Volume($v,node) GetFilePrefix]]
}

#-------------------------------------------------------------------------------
# .PROC EditorExportSetFileType
# Set Editor(fileformat) and update the save file type menu.
# .ARGS
# str fileType the type for the file
# .END
#-------------------------------------------------------------------------------
proc EditorExportSetFileType {fileType} {
    global Editor Volumes    
    
    set Editor(fileformat) $fileType
    $Editor(formatMenu) config -text $Editor($fileType)
}

#-------------------------------------------------------------------------------
# .PROC EditorWriteVolume
# Saves the volume chosen in Editor->Volumes->Save.
# This is the active volume, since the menu is set up that way.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorWriteVolume {} {
    global Volume Editor

    # Lauren this can become the general Volumes->Save that people want
    # get the chosen volume
    set v $Volume(activeID)

    # set initial directory to dir where vol last opened if unset
    if {$Editor(prefixSave) == ""} {
        set Editor(prefixSave) \
            [file join $Volume(DefaultDir) [Volume($v,node) GetName]]
    }
    
    # Show user a File dialog box
    set Editor(prefixSave) [MainFileSaveVolume $v $Editor(prefixSave)]
    if {$Editor(prefixSave) == ""} {return}
    # Write
    MainVolumesWrite $v $Editor(prefixSave)
    # Prefix changed, so update the Volumes->Props tab
    MainVolumesSetActive $v

    # if we just saved Working or Composite, keep track for re-reading
    if {$v == $Editor(idWorking)} {
        set Editor(prefixWorking) $Editor(prefixSave)
    } else {
        if {$v == $Editor(idComposite)} {
            set Editor(prefixComposite) $Editor(prefixSave)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorRead
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorRead {data} {
    global Volume Editor Mrml
    
    # If the volume doesn't exist yet, then don't read it, duh!
    if {$Editor(id$data) == "NEW"} {
        tk_messageBox -message "Nothing to read."
        return
    }
    
    switch $data {
        Composite {set v $Editor(idComposite)}
        Working   {set v $Editor(idWorking)}
    }
    
    # Show user a File dialog box
    set Editor(prefix$data) [MainFileOpenVolume $v $Editor(prefix$data)]
    if {$Editor(prefix$data) == ""} {return}
    
    # Read
    Volume($v,node) SetFilePrefix $Editor(prefix$data)
    Volume($v,node) SetFullPrefix \
        [file join $Mrml(dir) [Volume($v,node) GetFilePrefix]]
    if {[MainVolumesRead $v] < 0} {
        return
    }
    
    # Update pipeline and GUI
    MainVolumesUpdate $v
    
    # Prefix changed, so update the Models->Props tab
    MainVolumesSetActive $v
}

#-------------------------------------------------------------------------------
# .PROC EditorClear
#
# Clear either the Working or Composite data to all zeros.
# .END
#-------------------------------------------------------------------------------
proc EditorClear {data} {
    global Volume Editor Slice
    
    # If the volume doesn't exist yet, then don't write it, duh!
    if {$Editor(id$data) == "NEW"} {
        tk_messageBox -message "Nothing to clear."
        return
    }
    
    switch $data {
        Composite {set v $Editor(idComposite)}
        Working   {set v $Editor(idWorking)}
    }
    
    vtkImageCopy copy
    copy ClearOn
    copy SetInput [Volume($v,vol) GetOutput]
    copy Update
    copy SetInput ""
    Volume($v,vol) SetImageData [copy GetOutput]
    copy SetOutput ""
    copy Delete
    
    # Mark the volume as changed
    set Volume($v,dirty) 1
    
    MainVolumesUpdate $v
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC EditorMerge
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorMerge {op arg} {
    global Ed Volume Gui Lut Slice Editor
    
    if {$op == "Fore"} {
        set Editor(fgName) $arg
        $Editor(mbFore) config -text $Editor(fgName)
        return
    } elseif {$op == "Back"} {
        set Editor(bgName) $arg
        $Editor(mbBack) config -text $Editor(bgName)
        return
    }
    
    # bg = back (overwritten), fg = foreground (merged in)
    
    switch $Editor(fgName) {
        Original  {set fg [EditorGetOriginalID]}
        Working   {set fg [EditorGetWorkingID]}
        Composite {set fg [EditorGetCompositeID]}
        default   {tk_messageBox \
                       -message "Merge the Original, Working, or Composite, not '$fgName'";\
                       return}
    }
    switch $Editor(bgName) {
        Working   {set bg [EditorGetWorkingID]}
        Composite {set bg [EditorGetCompositeID]}
        default   {tk_messageBox \
                       -message "Merge with the Working or Composite, not '$bgName'";\
                       return}
    }
    
    # Do nothing if fg=bg
    if {$fg == $bg} {
        return
    }
    
    # Disable Undo if we're overwriting working
    if {$bg == [EditorGetWorkingID]} {
        Ed(editor) SetUndoable 0
        EditorActivateUndo 0
    }
    
    # If extents are equal, then overlay, else copy.
    # If we copy the data, then we also have to copy the nodes.
    
    if {[EditorSameExtents $bg $fg] != 1} {
        # copy node from fg to bg
        EditorCopyNode $bg $fg
        
        # copy data
        MainVolumesCopyData $bg $fg Off
    } else {
        vtkImageOverlay over
        over SetInput 0 [Volume($bg,vol) GetOutput]
        over SetInput 1 [Volume($fg,vol) GetOutput]
        over SetOpacity 1 1.0
        over Update
        over SetInput 0 ""
        over SetInput 1 ""
        Volume($bg,vol) SetImageData [over GetOutput]
        over SetOutput ""
        over Delete
    }
    
    # Mark the volume as changed
    set Volume($bg,dirty) 1
    
    # Update pipeline and gui
    MainVolumesUpdate $bg
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC EditorLog
# returns the whole log string: everything this module has logged.
# It is called by SessionLog module when it is time to write the log file
# or display the current log info.
# This proc actually calls SessionLogGenericLog to do most of the work.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorLog {} {
    global Editor Volume

    # log any final items from this module:
    # list all volumes in the slicer
    # the syntax is complicated b/c first item in the description
    # pairs is the name of the database column (which will be auto generated)
    foreach v $Volume(idList) {
        set name [Volume($v,node) GetName]
        set file [Volume($v,node) GetFullPrefix]
        set datatype "{info,volume}"
        set id "{volumeid,$v}"
        set infotype "{infotype,name}"
        set var "\{$datatype,$id,$infotype\}"
        set Editor(log,$var) $name
        set infotype "{infotype,filename}"
        set var "\{$datatype,$id,$infotype\}"
        set Editor(log,$var) $file
    }

    # use the generic logging procedure 
    # which grabs everything in $Editor(log,*)
    return [SessionLogGenericLog Editor]
}

#-------------------------------------------------------------------------------
# .PROC EditorIncrementAndLogEvent
# record an event in the Editor(log,*) subarray
# (will be written to log file later)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorIncrementAndLogEvent {event} {
    global Editor Volume Label Slice

    # key-value pairs describing the event
    set datatype "{event,$event}"
    set module "{module,Editor}"
    set submodule "{submodule,$Editor(activeID)}"
    set workingid "{workingid,$Editor(idWorking)}"
    set originalid "{originalid,$Editor(idOriginal)}"
    set label "{label,$Label(label)}"
    set slice  "{slice,$Slice(activeID)}"
    #set eventinfo "{eventinfo,}"

    # variable name is a (comma-separated) list describing the exact event
    set var "\{$datatype,$module,$submodule,$workingid,$originalid,$label,$slice\}"
    # initialize the count of these events
    if {[info exists Editor(log,$var)] == 0} {
        set Editor(log,$var) 0
    }
    # increment number of events
    # (if this overflows, it will wrap negative, not give an error)
    incr Editor(log,$var)
    #puts "$var: $Editor(log,$var)"
}

#-------------------------------------------------------------------------------
# .PROC EditorLogEventOnce
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorLogEventOnce {event value {info ""}} {
    global Editor Volume Label Slice

    # key-value pairs describing the event
    set datatype "{event,$event}"

    # variable name is a list describing the exact event
    set var "\{$datatype,$info\}"

    # log only if event has not happened already
    if {[info exists Editor(log,$var)] == 0} {
        set Editor(log,$var) $value
        #puts "$var: $Editor(log,$var)"
    }

}

#-------------------------------------------------------------------------------
# .PROC EditorReplaceAndLogEvent
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorReplaceAndLogEvent {event value {info ""}} {
    global Editor Volume Label Slice

    # key-value pairs describing the event
    set datatype "{event,$event}"

    # variable name is a list describing the exact event
    set var "\{$datatype,$info\}"

    # write over previous record of event if any
    set Editor(log,$var) $value
    #puts "$var: $Editor(log,$var)"

}

#-------------------------------------------------------------------------------
# .PROC EditorStartTiming
# grab clock value now
# .ARGS
# m name of the module we are timing
# .END
#-------------------------------------------------------------------------------
proc EditorStartTiming {m} {
    global Editor

    set Editor(logInfo,$m,startTime) [clock seconds]
}

#-------------------------------------------------------------------------------
# .PROC EditorStopTiming
# add to the total time in editor (or submodule) so far
# .ARGS
# m name of the module we are timing
# .END
#-------------------------------------------------------------------------------
proc EditorStopTiming {m} {
    global Editor

    # can't stop if we never started
    if {[info exists Editor(logInfo,$m,startTime)] == 0} {
        return
    }

    set Editor(logInfo,$m,endTime) [clock seconds]
    set elapsed \
        [expr $Editor(logInfo,$m,endTime) - $Editor(logInfo,$m,startTime)]
    
    # variable name is a list describing the exact event
    # the first thing is datatype: time is the database table
    # it should go in, and elapsed describes the type of time...
    set var "\{{time,elapsed},{module,Editor},{submodule,$m}\}"

    # initialize the variable if needed
    if {[info exists Editor(log,$var)] == 0} {
        set Editor(log,$var) 0
    }
    
    # increment total time
    set total [expr $elapsed + $Editor(log,$var)]
    set Editor(log,$var) $total    
}

#-------------------------------------------------------------------------------
# .PROC EditorControlB1
# Effect-specific response to B1 mouse click while control is pressed.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorControlB1 {x y} {
    global Ed Editor 

    EditorIncrementAndLogEvent "controlb1click"
    
    switch $Editor(activeID) {
        "EdDraw2" {
            # Mark point for moving
            Slicer DrawMoveInit $x $y
            
            # Act depending on the draw mode:
            #  - Draw:   Insert a point
            #  - Select: Select/deselect a point
            #  - Insert: Insert a point between two points (CTJ)
            #
            #set coords [EditorClampToOriginalBounds $x $y]
            #set x [lindex $coords 0]
            #set y [lindex $coords 1]
            switch $Ed(EdDraw2,mode) {
                "Draw" {
                    if {1} {
                        Slicer DrawInsertPoint $x $y
                    } else {
                        EditorInsertPoint $x $y
                        #EditorIdleProc start
                    }
                }
                "Select" {
                    Slicer DrawStartSelectBox $x $y
                }
                "Move" {
                    set Ed(EdDraw2,mode) Select
                    Slicer DrawStartSelectBox $x $y
                }
                "Insert" {
                    Slicer DrawInsert $x $y
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorControlB1Motion
# Effect-specific response to B1 mouse motion while control is pressed.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorControlB1Motion {x y} {
    global Ed Editor Slice Interactor

    EditorIncrementAndLogEvent "controlb1motion"

    set s $Slice(activeID)

    switch $Editor(activeID) {
        "EdDraw2" {
            # Act depending on the draw mode:
            #  - Draw:   Insert a point
            #  - Select: draw the "select" box
            #
            #set coords [EditorClampToOriginalBounds $x $y]
            #set x [lindex $coords 0]
            #set y [lindex $coords 1]
            switch $Ed(EdDraw2,mode) {
                "Draw" {
                    if {1} {
                        # this way just inserts the point normally
                        # (CTJ) to disable click and drag, comment this line:
                        Slicer DrawInsertPoint $x $y
                    } else {
                        # this way applies to show the rasterized labelmap
                        # and stores the points to support delete
                        # (this way isn't fully debugged)
                        EditorInsertPoint $x $y
                    }
                }
                "Select" {
                    Slicer DrawDragSelectBox $x $y
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorControlB1Release
# Effect-specific response to B1 mouse release while control is pressed.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorControlB1Release {x y} {
    global Ed Editor
    
    switch $Editor(activeID) {
        "EdDraw2" {
            # Act depending on the draw mode:
            #  - Select: stop drawing the "select" box
            #
            #set coords [EditorClampToOriginalBounds $x $y]
            #set x [lindex $coords 0]
            #set y [lindex $coords 1]
            switch $Ed(EdDraw2,mode) {
                "Select" {
                    Slicer DrawEndSelectBox $x $y
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EditorClampToOriginalBounds
# Clamps x, y into boundaries of the original data volume.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EditorClampToOriginalBounds {x y} {
    set id [EditorGetOriginalID]
    set ext [[Volume($id,vol) GetOutput] GetExtent]
    set xmin [lindex $ext 0]
    set xmax [lindex $ext 1]
    set ymin [lindex $ext 2]
    set ymax [lindex $ext 3]
    if {$x < $xmin} {set x $xmin}
    if {$x > $xmax} {set x $xmax}
    if {$y < $ymin} {set y $ymin}
    if {$y > $ymax} {set y $ymax}
    return [list $x $y]
}

