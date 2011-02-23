#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolDicom.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:04 $
#   Version:   $Revision: 1.28 $
# 
#===============================================================================
# FILE:        VolDicom.tcl
# PROCEDURES:  
#   VolDicomInit
#   VolDicomBuildGUI
#   DICOMLoadStudy
#   AddListUnique
#   DICOMFileNameTextBoxVisibleButton
#   DICOMPreviewImageClick
#   DICOMFillFileNameTextbox
#   DICOMIncrDecrButton
#   DICOMScrolledTextbox
#   FindDICOM2
#   FindDICOM
#   CreateStudyList
#   CreateSeriesList
#   CreateFileNameList
#   ClickListIDsNames
#   ClickListStudyUIDs
#   ClickListSeriesUIDs
#   DICOMListSelectClose
#   DICOMListSelect
#   ChangeDir
#   ClickDirList
#   DICOMHelp
#   DICOMSelectDirHelp
#   DICOMSelectDir
#   DICOMSelectMain
#   HandleExtractHeader
#   DICOMReadHeaderValues
#   DICOMPredictScanOrder
#   DICOMPreviewAllButton
#   DICOMListHeadersButton
#   DICOMListHeader
#   DICOMPreviewFile
#   DICOMCheckFiles
#   DICOMCheckVolumeInit
#   DICOMCheckFile
#   DICOMShowPreviewSettings
#   DICOMHidePreviewSettings
#   DICOMShowDataDictSettings
#   DICOMHideDataDictSettings
#   DICOMHideAllSettings
#   DICOMSelectFragment
#   DICOMImageTextboxFragmentEnter
#   DICOMImageTextboxFragmentLeave
#   DICOMImageTextboxSelectAll
#   DICOMImageTextboxDeselectAll
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC VolDicomInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolDicomInit {} {
    global Volume Volumes Path Preset Module

    # Define Procedures for communicating with Volumes.tcl
    #---------------------------------------------
    set m VolDicom
    # procedure for building GUI in this module's frame
    set Volume(readerModules,$m,procGUI)  ${m}BuildGUI


    # Define Module Description to be used by Volumes.tcl
    #---------------------------------------------
    # name for menu button
    set Volume(readerModules,$m,name)  Dicom

    # tooltip for help
    set Volume(readerModules,$m,tooltip)  \
            "This tab displays information\n
    for the currently selected dicom volume."


    # Global variables used inside this module
    #---------------------------------------------

    # Added by Attila Tanacs 10/18/2000
    set Volumes(DICOMStartDir) ""
    set Volumes(FileNameSortParam) "incr"
    set Volumes(prevIncrDecrState) "incr"
    set Volumes(previewCount) 0

    set Volumes(DICOMPreviewWidth) 64
    set Volumes(DICOMPreviewHeight) 64
    set Volumes(DICOMPreviewHighestValue) 256 ;# set default for MRI rather than CT

    set Volumes(DICOMCheckVolumeList) {}
    set Volumes(DICOMCheckPositionList) {}
    set Volumes(DICOMCheckActiveList) {}
    set Volumes(DICOMCheckActivePositionList) {}
    set Volumes(DICOMCheckSliceDistanceList) {}

    set Volumes(DICOMCheckImageLabelIdx) 0
    set Volumes(DICOMCheckLastPosition) 0
    set Volumes(DICOMCheckSliceDistance) 0

    set dir [file join [file join $Path(program) tcl-modules] Volumes]
    set Volumes(DICOMDataDictFile) $dir/datadict.txt

    set Module(Volumes,presets) "DICOMStartDir='[pwd]' FileNameSortParam='incr' \
DICOMPreviewWidth='64' DICOMPreviewHeight='64' DICOMPreviewHighestValue='256' \
DICOMDataDictFile='$Volumes(DICOMDataDictFile)'"

    # flag to search in subdirectories when parsing dicom filenames
    set ::DICOMrecurse "true"

    # End
}

#-------------------------------------------------------------------------------
# .PROC VolDicomBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolDicomBuildGUI {parentFrame} {
    global Gui Volume 

    # Added by Attila Tanacs 10/6/2000 
    
    #-------------------------------------------
    # Props->Bot->DICOM frame
    #-------------------------------------------
    

    if {[catch {package require Iwidgets} err] != 1} {
        iwidgets::scrolledframe $parentFrame.sfVolDicom \
            -vscrollmode dynamic -hscrollmode dynamic \
            -background $Gui(activeWorkspace)  -activebackground $Gui(activeButton) \
            -troughcolor $Gui(normalButton)  -highlightthickness 0 \
            -relief flat -sbwidth 10
        pack $parentFrame.sfVolDicom -expand 1 -fill both
        set f [$parentFrame.sfVolDicom childsite]
        # this is to make the rest of the proc think nothing's changed
        set parentFrame [$parentFrame.sfVolDicom childsite]
    }

    set f $parentFrame

    frame $f.fVolume  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fVolume $f.fApply \
            -side top -fill x -pady $Gui(pad)
    
    #-------------------------------------------
    # Props->Bot->DICOM->fVolume frame
    #-------------------------------------------
    
    set f $parentFrame.fVolume
    
    #DevAddFileBrowse $f Volume firstFile "First Image File:" "VolumesSetFirst" "" ""  "Browse for the first Image file"
    #bind $f.efile <Tab> "VolumesSetLast"
    
    frame $f.fSelect -bg $Gui(activeWorkspace)
    #frame $f.fLast     -bg $Gui(activeWorkspace)
    #frame $f.fHeaders  -bg $Gui(activeWorkspace)
    #frame $f.fLabelMap -bg $Gui(activeWorkspace)
    set fileNameListbox [ScrolledListbox $f.fFiles 0 0 -height 5 -bg $Gui(activeWorkspace)]
    # make the scroll bars a bit skinnier when they appear
    $f.fFiles.xscroll configure -width 10
    $f.fFiles.yscroll configure -width 10
    set Volume(dICOMFileListbox) $fileNameListbox
    #frame $f.fFiles -bg $Gui(activeWorkspace)
    frame $f.fOptions  -bg $Gui(activeWorkspace)
    frame $f.fDesc     -bg $Gui(activeWorkspace)
    
    pack $f.fSelect $f.fFiles $f.fOptions \
            $f.fDesc -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    # Load, Select, or Extract
    DevAddButton $f.fSelect.bLoad "Load DICOM Study" {VolumesPropsCancel; update; DICOMLoadStudy "choose"}
    TooltipAdd $f.fSelect.bLoad "Select directory containing hierarchy of dicom files.\nEach series will be loaded as a Volume."

    DevAddButton $f.fSelect.bSelect "Select DICOM Volume" [list DICOMSelectMain $fileNameListbox]
    TooltipAdd $f.fSelect.bSelect "Select directory containing hierarchy of dicom files.\nA dialog will let you select the series to load."
    DevAddButton $f.fSelect.bExtractHeader "Extract Header" { HandleExtractHeader }
    pack $f.fSelect.bLoad $f.fSelect.bSelect $f.fSelect.bExtractHeader -padx $Gui(pad) -pady $Gui(pad)
    
    # Files
    
    $fileNameListbox delete 0 end

    # Options
    set f $parentFrame.fVolume.fOptions
    
    eval {label $f.lName -text "Name:"} $Gui(WLA)
    eval {entry $f.eName -textvariable Volume(name) -width 13} $Gui(WEA)
    pack  $f.lName -side left -padx $Gui(pad)
    pack $f.eName -side left -padx $Gui(pad) -expand 1 -fill x
    pack $f.lName -side left -padx $Gui(pad)
    
    # Desc row
    set f $parentFrame.fVolume.fDesc
    
    eval {label $f.lDesc -text "Optional Description:"} $Gui(WLA)
    eval {entry $f.eDesc -textvariable Volume(desc)} $Gui(WEA)
    pack $f.lDesc -side left -padx $Gui(pad)
    pack $f.eDesc -side left -padx $Gui(pad) -expand 1 -fill x
    
    
    #-------------------------------------------
    # Props->Bot->Basic->Apply frame
    #-------------------------------------------
    set f $parentFrame.fApply
    
    DevAddButton $f.bApply "Header" "VolumesSetPropertyType VolHeader" 8
    DevAddButton $f.bCancel "Cancel" "VolumesPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad)
    
    # End

}

#-------------------------------------------------------------------------------
# .PROC DICOMLoadStudy
# sp 2003-07-10 support for loading directories full of dicom
# images via the --load-dicom command line argument
# .ARGS dir - start dir for loading
# .END
#-------------------------------------------------------------------------------
proc DICOMLoadStudy { dir {Pattern "*"} } {
    #
    # read dicom volume(s), e.g. specified on command line
    # - if it's a dir full of files, load that dir as a volume
    # - if it's a dir full of dirs, load each dir as a volume
    #

    if { $dir == "choose" } {
        if { $::Volumes(DICOMStartDir) == "" } {
            set ::Volumes(DICOMStartDir) [pwd]
        }
        set dir [tk_chooseDirectory \
            -initialdir $::Volumes(DICOMStartDir) \
            -mustexist true \
            -title "Select Directory Containing DICOM Files" \
            -parent .tMain ]
    }

    set return_ids ""
    if { $dir != "" } {
        set files [lsort -dictionary [glob -nocomplain $dir/*]]
        set dirs [list $dir]
        foreach f $files {
            if { [file isdirectory $f] } {
                lappend dirs $f
            } 
        }

        foreach d $dirs { 
            if { ![file isdirectory $d] } {
                continue
            }
            VolumesSetPropertyType VolDicom
            MainVolumesSetActive NEW
            Tab Volumes row1 Props
            set ::Volumes(DICOMStartDir) $d
            if { $d == $dir } {
                # if this is the top level dir, then only look for
                # files at this level to avoid duplicate loading
                set ::DICOMrecurse "false"
            } else {
                set ::DICOMrecurse "true"
            }
            DICOMSelectMain $::Volume(dICOMFileListbox) "autoload" $Pattern

            if { $::FindDICOMCounter != 0 } {
                VolumesSetPropertyType VolHeader
                if { [info exists ::Volume(seriesDesc)] &&
                        $::Volume(seriesDesc) != "" } {
                    set seriestag $::Volume(seriesDesc)
                } else {
                    set seriestag [file tail $d]
                }
                if { [info exists ::Volume(seriesNum)] } {
                    set seriestag "$::Volume(seriesNum)_$seriestag"
                } 
                regsub -all " " $seriestag "_" seriestag
                set ::Volume(name) ${seriestag}_$::Volume(name)
                lappend return_ids [VolumesPropsApply]
            }
            RenderAll
            Tab Data
            set ::Volume(dICOMFileList) ""
        }
    }
    return $return_ids
}

#-------------------------------------------------------------------------------
# DICOM related procedures
# Added by Attila Tanacs
# October 2000
# (C) ERC for CISST, Johns Hopkins University, Baltimore
# Any comments? tanacs@cs.jhu.edu
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC AddListUnique
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AddListUnique { list arg } {
    upvar $list list2
    if { [expr [lsearch -exact $list2 $arg] == -1] } {
        lappend list2 $arg
    }
}

#-------------------------------------------------------------------------------
# .PROC DICOMFileNameTextBoxVisibleButton
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMFileNameTextBoxVisibleButton {t idx value} {
    global DICOMFileNameSelected

    #tk_messageBox -message "ButtonPress $idx"
    set DICOMFileNameSelected [lreplace $DICOMFileNameSelected $idx $idx $value]
    DICOMFillFileNameTextbox $t
    #$t see $idx.0
}

#-------------------------------------------------------------------------------
# .PROC DICOMPreviewImageClick
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMPreviewImageClick {w idx} {
    global Volumes DICOMFileNameSelected

    set v [lindex $DICOMFileNameSelected $idx]
    if {$v == "0"} {
        $w configure -background green
        DICOMFileNameTextBoxVisibleButton $Volumes(DICOMFileNameTextbox) $idx "1"
    } else {
        $w configure -background red
        DICOMFileNameTextBoxVisibleButton $Volumes(DICOMFileNameTextbox) $idx "0"
    }
}

#-------------------------------------------------------------------------------
# .PROC DICOMFillFileNameTextbox
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMFillFileNameTextbox {t} {
    global DICOMFileNameList DICOMFileNameSelected

    $t configure -state normal
    set yviewfr [lindex [$t yview] 0]
    $t delete 1.0 end

    $t insert insert " "
    $t insert insert "  Select All  " selectall
    $t insert insert "  "
    $t insert insert "  Deselect All  " deselectall
    $t insert insert "\n"
    $t tag add menu 1.0 1.end

    $t tag config selectall -background gray -relief groove -borderwidth 2 -font {helvetica 12 bold}
    $t tag bind selectall <ButtonRelease-1> "DICOMImageTextboxSelectAll"
    $t tag config deselectall -background gray -relief groove -borderwidth 2 -font {helvetica 12 bold}
    $t tag bind deselectall <ButtonRelease-1> "DICOMImageTextboxDeselectAll"
    $t tag config menu -justify center
        
    set num [llength $DICOMFileNameList]
    for {set idx 0} {$idx < $num} {incr idx} {
        set firstpos [$t index insert]
        $t insert insert "\#[expr $idx + 1] "
        if {[lindex $DICOMFileNameSelected $idx] == "1"} {
            $t insert insert " S " vis$idx
            $t tag config vis$idx -background green -relief groove -borderwidth 2
            #$t tag bind vis$idx <Button-1> "DICOMFileNameTextBoxVisibleButton $t $idx 0"
            set value 0
        } else {
            $t insert insert " N " vis$idx
            $t tag config vis$idx -background red -relief groove -borderwidth 2
            #$t tag bind vis$idx <Button-1> "DICOMFileNameTextBoxVisibleButton $t $idx 1"
            set value 1
        }
        $t insert insert " "
        $t insert insert [lindex $DICOMFileNameList $idx]
        $t insert insert "\n"
        $t tag add line$idx $firstpos [$t index insert]
        $t tag bind line$idx <Button-1> "DICOMFileNameTextBoxVisibleButton $t $idx $value"
    }
    $t yview moveto $yviewfr
    $t configure -state disabled
}

#-------------------------------------------------------------------------------
# .PROC DICOMIncrDecrButton
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMIncrDecrButton {filenames} {
    global Volumes DICOMFileNameList DICOMFileNameSelected

    if {$Volumes(prevIncrDecrState) != $Volumes(FileNameSortParam)} {
        set temp1 {}
        set temp2 {}
        set num [llength $DICOMFileNameList]
        for {set i [expr $num - 1]} {$i >= 0} {incr i -1} {
            lappend temp1 [lindex $DICOMFileNameList $i]
            lappend temp2 [lindex $DICOMFileNameSelected $i]
        }
        set DICOMFileNameList $temp1
        set DICOMFileNameSelected $temp2
        DICOMFillFileNameTextbox $filenames
        set Volumes(prevIncrDecrState) $Volumes(FileNameSortParam)
    }
}

#-------------------------------------------------------------------------------
# DICOMScrolledListbox modified version of ScrolledListbox
#
# xAlways is 1 if the x scrollbar should be always visible
#-------------------------------------------------------------------------------
proc DICOMScrolledListbox {f xAlways yAlways variable {labeltext "labeltext"} {args ""}} {
    global Gui
    
    set fmain $f
    frame $fmain -bg $Gui(activeWorkspace)
    eval { label $fmain.head -text $labeltext } $Gui(WLA)
    eval { label $fmain.selected -textvariable $variable } $Gui(WLA)

    frame $fmain.f -bg $Gui(activeWorkspace)
    set f $fmain.f
    if {$xAlways == 1 && $yAlways == 1} { 
        listbox $f.list -selectmode single \
            -xscrollcommand "$f.xscroll set" \
            -yscrollcommand "$f.yscroll set"
    
    } elseif {$xAlways == 1 && $yAlways == 0} { 
        listbox $f.list -selectmode single \
            -xscrollcommand "$f.xscroll set" \
            -yscrollcommand [list ScrollSet $f.yscroll \
                [list grid $f.yscroll -row 0 -column 1 -sticky ns]]

    } elseif {$xAlways == 0 && $yAlways == 1} { 
        listbox $f.list -selectmode single \
            -xscrollcommand [list ScrollSet $f.xscroll \
                [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
            -yscrollcommand "$f.yscroll set"

    } else {
        listbox $f.list -selectmode single \
            -xscrollcommand [list ScrollSet $f.xscroll \
                [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
            -yscrollcommand [list ScrollSet $f.yscroll \
                [list grid $f.yscroll -row 0 -column 1 -sticky ns]]
    }

    if {$Gui(smallFont) == 1} {
        eval {$f.list configure \
            -font {helvetica 10 bold} \
            -bg $Gui(normalButton) -fg $Gui(textDark) \
            -selectbackground $Gui(activeButton) \
            -selectforeground $Gui(textDark) \
            -highlightthickness 0 -bd $Gui(borderWidth) \
            -relief sunken -selectborderwidth $Gui(borderWidth)}
    } else {
        eval {$f.list configure \
            -font {helvetica 12 bold} \
            -bg $Gui(normalButton) -fg $Gui(textDark) \
            -selectbackground $Gui(activeButton) \
            -selectforeground $Gui(textDark) \
            -highlightthickness 0 -bd $Gui(borderWidth) \
            -relief sunken -selectborderwidth $Gui(borderWidth)}
    }

    if {$args != ""} {
        eval {$f.list configure} $args
    }

    scrollbar $f.xscroll -orient horizontal \
        -command [list $f.list xview] \
        -bg $Gui(activeWorkspace) \
        -activebackground $Gui(activeButton) -troughcolor $Gui(normalButton) \
        -highlightthickness 0 -bd $Gui(borderWidth)
    scrollbar $f.yscroll -orient vertical \
        -command [list $f.list yview] \
        -bg $Gui(activeWorkspace) \
        -activebackground $Gui(activeButton) -troughcolor $Gui(normalButton) \
        -highlightthickness 0 -bd $Gui(borderWidth)

    grid $f.list $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    pack $fmain.head $fmain.selected -anchor nw -pady 5
    pack $fmain.f -fill both -expand true
    pack $fmain -fill both -expand true 

    return $fmain.f.list
}

#-------------------------------------------------------------------------------
# .PROC DICOMScrolledTextbox
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMScrolledTextbox {f xAlways yAlways variable {labeltext "labeltext"} {args ""}} {
    global Gui
    
    set fmain $f
    frame $fmain -bg $Gui(activeWorkspace)
    eval { label $fmain.head -text $labeltext } $Gui(WLA)
    eval { label $fmain.selected -textvariable $variable } $Gui(WLA)

    frame $fmain.f -bg $Gui(activeWorkspace)
    set f $fmain.f
    if {$xAlways == 1 && $yAlways == 1} { 
        text $f.list \
            -xscrollcommand "$f.xscroll set" \
            -yscrollcommand "$f.yscroll set"
    
    } elseif {$xAlways == 1 && $yAlways == 0} { 
        text $f.list \
            -xscrollcommand "$f.xscroll set" \
            -yscrollcommand [list ScrollSet $f.yscroll \
                [list grid $f.yscroll -row 0 -column 1 -sticky ns]]

    } elseif {$xAlways == 0 && $yAlways == 1} { 
        text $f.list \
            -xscrollcommand [list ScrollSet $f.xscroll \
                [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
            -yscrollcommand "$f.yscroll set"

    } else {
        text $f.list \
            -xscrollcommand [list ScrollSet $f.xscroll \
                [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
            -yscrollcommand [list ScrollSet $f.yscroll \
                [list grid $f.yscroll -row 0 -column 1 -sticky ns]]
    }

    if {$Gui(smallFont) == 1} {
        eval {$f.list configure \
            -font {helvetica 10 bold} \
            -bg $Gui(normalButton) -fg $Gui(textDark) \
            -selectbackground $Gui(activeButton) \
            -selectforeground $Gui(textDark) \
            -highlightthickness 0 -bd $Gui(borderWidth) \
            -relief sunken -selectborderwidth $Gui(borderWidth)}
    } else {
        eval {$f.list configure \
            -font {helvetica 12 bold} \
            -bg $Gui(normalButton) -fg $Gui(textDark) \
            -selectbackground $Gui(activeButton) \
            -selectforeground $Gui(textDark) \
            -highlightthickness 0 -bd $Gui(borderWidth) \
            -relief sunken -selectborderwidth $Gui(borderWidth)}
    }

    if {$args != ""} {
        eval {$f.list configure} $args
    }

    scrollbar $f.xscroll -orient horizontal \
        -command [list $f.list xview] \
        -bg $Gui(activeWorkspace) \
        -activebackground $Gui(activeButton) -troughcolor $Gui(normalButton) \
        -highlightthickness 0 -bd $Gui(borderWidth)
    scrollbar $f.yscroll -orient vertical \
        -command [list $f.list yview] \
        -bg $Gui(activeWorkspace) \
        -activebackground $Gui(activeButton) -troughcolor $Gui(normalButton) \
        -highlightthickness 0 -bd $Gui(borderWidth)

    grid $f.list $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    pack $fmain.head $fmain.selected -anchor nw -pady 5
    pack $fmain.f -fill both -expand true
    pack $fmain -fill both -expand true 

    return $fmain.f.list
}

#-------------------------------------------------------------------------------
# .PROC FindDICOM2
# Note - this is a recursive directory search that parses the dicom 
# files as it goes.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FindDICOM2 { StartDir AddDir Pattern } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames

    # bail out early 
    if { [info exists ::DICOMabort] && $::DICOMabort == "true" } {
        return
    }

    set pwd [pwd]
    if [expr [string length $AddDir] > 0] {
        if [catch {cd $AddDir} err] {
            puts stderr $err
            return
        }
    }

    # add progress indicator
    set w .dicomprogress
    set ::DICOMabort "false"
    if { ![winfo exists $w] } {
        toplevel $w
        wm title $w "Collecting DICOM Files..."
        wm geometry $w 400x150
        set ::DICOMlabel "working..."
        pack [label $w.label -textvariable ::DICOMlabel] 
        pack [button $w.cancel -text "Stop Looking" -command {set ::DICOMabort "true"} ]

        update ;# make sure the window exists before grabbing events
        #catch "grab -global $w" ;# this stop everything on the machine, not just slicer
        catch "grab $w" ;# this one just stops slicer from responding
    }
    
    vtkDCMParser parser
    foreach match [lsort -dictionary [glob -nocomplain -- $Pattern]] {
        wm title $w "Searching [pwd]"
        set ::DICOMlabel "\n\nExamining $match\n\n$::FindDICOMCounter DICOM files so far.\n"
        update
        if { $::DICOMabort == "true" } {
            break
        } 
        #puts stdout [file join $StartDir $match]
        if {[file isdirectory $match]} {
            continue
        }
        set FileName [file join $StartDir $AddDir $match]
        set found [parser OpenFile $match]
        if {[string compare $found "0"] == 0} {
            puts stderr "Can't open file [file join $StartDir $AddDir $match]"
        } else {
            set found [parser FindElement 0x7fe0 0x0010]
            if {[string compare $found "1"] == 0} {
                #
                # image data is available
                #
                
                set DICOMFiles($FindDICOMCounter,FileName) $FileName
                
                if [expr [parser FindElement 0x0010 0x0010] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set PatientName [parser ReadText $Length]
                    if {$PatientName == ""} {
                        set PatientName "noname"
                    }
                } else  {
                    set PatientName 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,PatientName) $PatientName
                AddListUnique DICOMPatientNames $PatientName
                
                if [expr [parser FindElement 0x0010 0x0020] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set PatientID [parser ReadText $Length]
                    if {$PatientID == ""} {
                        set PatientID "noid"
                    }
                } else  {
                    set PatientID 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,PatientID) $PatientID
                set add {}
                append add "<" $PatientID "><" $PatientName ">"
                AddListUnique DICOMPatientIDsNames $add
                set DICOMFiles($FindDICOMCounter,PatientIDName) $add

                # changed from UID to StudyID - sp 2002-12-05
                # UID -  0x0020 0x000d
                if [expr [parser FindElement 0x0020 0x0010] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set StudyInstanceUID [parser ReadText $Length]
                } else  {
                    set StudyInstanceUID 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,StudyInstanceUID) $StudyInstanceUID
                
                # changed from UID to SeriesNumber - sp 2002-12-05
                # UID -  0x0020 0x000e
                if [expr [parser FindElement 0x0020 0x0011] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set SeriesInstanceUID [parser ReadText $Length]
                } else  {
                    set SeriesInstanceUID 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,SeriesInstanceUID) $SeriesInstanceUID
                
                set ImageNumber ""
                if [expr [parser FindElement 0x0020 0x1041] == "1"] {
                    set NextBlock [lindex [split [parser ReadElement]] 4]
                    set ImageNumber [parser ReadFloatAsciiNumeric $NextBlock]
                } 
                if { $ImageNumber == "" } {
                    if [expr [parser FindElement 0x0020 0x0013] == "1"] {
                        #set Length [lindex [split [parser ReadElement]] 3]
                        #set ImageNumber [parser ReadText $Length]
                        #scan [parser ReadText $length] "%d" ImageNumber
                        
                        set NextBlock [lindex [split [parser ReadElement]] 4]
                        set ImageNumber [parser ReadIntAsciiNumeric $NextBlock]
                    } else  {
                        set ImageNumber 1
                    }
                }
                set DICOMFiles($FindDICOMCounter,ImageNumber) $ImageNumber
                
                incr FindDICOMCounter
                #puts [file join $StartDir $AddDir $match]
            } else {
                #set dim 256
            }
            parser CloseFile
        }
    }
    parser Delete
    
    if { $::DICOMabort != "true" && $::DICOMrecurse == "true" } {
        foreach file [lsort -dictionary [glob -nocomplain *]] {
            if [file isdirectory $file] {
                FindDICOM2 [file join $StartDir $AddDir] $file $Pattern
            }
        }
    }
    cd $pwd
}

#-------------------------------------------------------------------------------
# .PROC FindDICOM
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc FindDICOM { StartDir Pattern } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMStudyInstanceUIDList
    global DICOMSeriesInstanceUIDList
    global DICOMFileNameArray
    global DICOMFileNameList DICOMFileNameSelected
    
    if [array exists DICOMFiles] {
        unset DICOMFiles
    }
    if [array exists DICOMFileNameArray] {
        unset DICOMFileNameArray
    }
    set pwd [pwd]
    set FindDICOMCounter 0
    set DICOMPatientNames {}
    set DICOMPatientIDsNames {}
    set DICOMStudyList {}
    set DICOMSeriesList {}
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    
    if [catch {cd $StartDir} err] {
        puts stderr $err
        cd $pwd
        return
    }
    FindDICOM2 $StartDir "" $Pattern
    catch "grab relase .dicomprogress"
    catch "destroy .dicomprogress"
    catch "unset ::DICOMabort"
    cd $pwd
}

#-------------------------------------------------------------------------------
# .PROC CreateStudyList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CreateStudyList { PatientIDName } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMStudyList
    
    set DICOMStudyList {}
    for  {set i 0} {$i < $FindDICOMCounter} {incr i} {
        if {[string compare $DICOMFiles($i,PatientIDName) $PatientIDName] == 0} {
            AddListUnique DICOMStudyList $DICOMFiles($i,StudyInstanceUID)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC CreateSeriesList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CreateSeriesList { PatientIDName StudyUID } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMSeriesList
    
    set DICOMSeriesList {}
    for  {set i 0} {$i < $FindDICOMCounter} {incr i} {
        if {[string compare $DICOMFiles($i,PatientIDName) $PatientIDName] == 0} {
            if {[string compare $DICOMFiles($i,StudyInstanceUID) $StudyUID] == 0} {
                AddListUnique DICOMSeriesList $DICOMFiles($i,SeriesInstanceUID)
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC CreateFileNameList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CreateFileNameList { PatientIDName StudyUID SeriesUID} {
    global Volumes
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMFileNameArray
    global DICOMFileNameList DICOMFileNameSelected
    
    catch {unset DICOMFileNameArray}
    set count 0
    for  {set i 0} {$i < $FindDICOMCounter} {incr i} {
        if {[string compare $DICOMFiles($i,PatientIDName) $PatientIDName] == 0} {
            if {[string compare $DICOMFiles($i,StudyInstanceUID) $StudyUID] == 0} {
                if {[string compare $DICOMFiles($i,SeriesInstanceUID) $SeriesUID] == 0} {
                    #set id [format "%04d_%04d" $DICOMFiles($i,ImageNumber) $count]
                    #set id [format "%010.4f_%04d" $DICOMFiles($i,ImageNumber) $count]
                    set id [format "%012.4f_%04d" [expr 10000.0 + $DICOMFiles($i,ImageNumber)] $count]
                    incr count
                    set DICOMFileNameArray($id) $DICOMFiles($i,FileName)
                }
            }
        }
    }
    #set idx [lsort -decreasing [array name DICOMFileNameArray]]
    #set idx [lsort [array name DICOMFileNameArray]]
    if {$Volumes(FileNameSortParam) == "incr"} {
        set idx [lsort -increasing [array name DICOMFileNameArray]]
    } else {
        set idx [lsort -decreasing [array name DICOMFileNameArray]]
    }
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    foreach i $idx {
        lappend DICOMFileNameList $DICOMFileNameArray($i)
        lappend DICOMFileNameSelected "1"
    }
}

#-------------------------------------------------------------------------------
# .PROC ClickListIDsNames
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ClickListIDsNames { idsnames study series filenames } {
    global DICOMPatientIDsNames
    global DICOMStudyList
    global DICOMListSelectPatientName
    global DICOMListSelectStudyUID
    global DICOMListSelectSeriesUID

    set nameidx [$idsnames curselection]
    set name [lindex $DICOMPatientIDsNames $nameidx]
    set DICOMListSelectPatientName $name
    CreateStudyList $name
    $study delete 0 end
    eval {$study insert end} $DICOMStudyList
    $series delete 0 end
    #$filenames delete 0 end
    $filenames delete 1.0 end
    set DICOMListSelectStudyUID "none selected"
    set DICOMListSelectSeriesUID "none selected"
}

#-------------------------------------------------------------------------------
# .PROC ClickListStudyUIDs
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ClickListStudyUIDs { idsnames study series filenames } {
    global DICOMPatientIDsNames
    global DICOMStudyList
    global DICOMSeriesList
    global DICOMListSelectStudyUID
    global DICOMListSelectSeriesUID
    
    set nameidx [$idsnames index active]
    set name [lindex $DICOMPatientIDsNames $nameidx]
    set studyididx [$study curselection]
    set studyid [lindex $DICOMStudyList $studyididx]
    set DICOMListSelectStudyUID $studyid
    CreateSeriesList $name $studyid
    $series delete 0 end
    eval {$series insert end} $DICOMSeriesList
    #$filenames delete 0 end
    $filenames delete 1.0 end
    set DICOMListSelectSeriesUID "none selected"
}

#-------------------------------------------------------------------------------
# .PROC ClickListSeriesUIDs
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ClickListSeriesUIDs { idsnames study series filenames } {
    global DICOMPatientIDsNames
    global DICOMStudyList
    global DICOMSeriesList
    global DICOMFileNameList
    global DICOMListSelectSeriesUID
    
    set nameidx [$idsnames index active]
    set name [lindex $DICOMPatientIDsNames $nameidx]
    set studyididx [$study index active]
    set studyid [lindex $DICOMStudyList $studyididx]
    set seriesididx [$series curselection]
    
    if {$seriesididx == ""} {
        return
    }
    
    set seriesid [lindex $DICOMSeriesList $seriesididx]
    set DICOMListSelectSeriesUID $seriesid
    CreateFileNameList $name $studyid $seriesid
    DICOMFillFileNameTextbox $filenames
}

#-------------------------------------------------------------------------------
# .PROC DICOMListSelectClose
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMListSelectClose { parent filelist } {
    global DICOMFileNameList DICOMFileNameSelected
    global Pressed
    
#     set list2 $DICOMFileNameList
#     set DICOMFileNameList {}
#     set num [llength $DICOMFileNameSelected]
#     for {set i 0} {$i < $num} {incr i} {
#     if {[lindex $DICOMFileNameSelected $i] == "1"} {
#         lappend DICOMFileNameList [lindex $list2 $i]
#     }
#     }
    
    set Pressed OK
    destroy $parent
}

#-------------------------------------------------------------------------------
# .PROC DICOMListSelect
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMListSelect { parent values } {
#
# It's a bit messy, but it was my very first Tcl/Tk program.
#
    global DICOMListSelectPatientName
    global DICOMListSelectStudyUID
    global DICOMListSelectSeriesUID
    global DICOMListSelectFiles
    global Gui
    global Pressed
    global Volumes

    set DICOMListSelectFiles ""

    toplevel $parent -bg $Gui(activeWorkspace)
    wm title $parent "List of DICOM studies"
    wm minsize $parent 640 480

    frame $parent.f1 -bg $Gui(activeWorkspace)
    frame $parent.f2 -bg $Gui(activeWorkspace)
    frame $parent.f3 -bg $Gui(activeWorkspace)
    pack $parent.f1 $parent.f2 -fill x
    pack $parent.f3

    set iDsNames [DICOMScrolledListbox $parent.f1.iDsNames 0 1 DICOMListSelectPatientName "Patient <ID><Name>" -width 50 -height 5]
    TooltipAdd $iDsNames "Select a patient"
    set studyUIDs [DICOMScrolledListbox $parent.f1.studyUIDs 0 1 DICOMListSelectStudyUID "Study ID" -width 50 -height 5]
    TooltipAdd $studyUIDs "Select a study of the selected patient"
    pack $parent.f1.iDsNames $parent.f1.studyUIDs -side left -expand true -fill both

    set seriesUIDs [DICOMScrolledListbox $parent.f2.seriesUIDs 0 1 DICOMListSelectSeriesUID "Series Number" -width 50 -height 5]
    TooltipAdd $seriesUIDs "Select a series of the selected study"
    set fileNames [DICOMScrolledTextbox $parent.f2.fileNames 0 1 DICOMListSelectFiles "Files" -width 50 -height 5 -wrap none -cursor hand1 -state disabled]
    set Volumes(DICOMFileNameTextbox) $fileNames
    TooltipAdd $fileNames "Select files of the selected series"
    pack $parent.f2.seriesUIDs $parent.f2.fileNames -side left -expand true -fill both

    eval {button $parent.f3.close -text "OK" -command [list DICOMListSelectClose $parent $fileNames]} $Gui(WBA)
    eval {button $parent.f3.cancel -text "Cancel" -command "set Pressed Cancel; destroy $parent"} $Gui(WBA)
    pack $parent.f3.close $parent.f3.cancel -padx 10 -pady 10 -side left

    frame $parent.f2.fileNames.fIncrDecr -bg $Gui(activeWorkspace)
    pack $parent.f2.fileNames.fIncrDecr

    set f2 $parent.f2.fileNames.fIncrDecr
    eval {radiobutton $f2.rIncr \
          -text "Increasing" -command "DICOMIncrDecrButton $fileNames" \
          -variable Volumes(FileNameSortParam) -value "incr" -width 12 \
          -indicatoron 0} $Gui(WCA)
    eval {radiobutton $f2.rDecr \
          -text "Decreasing" -command "DICOMIncrDecrButton $fileNames" \
          -variable Volumes(FileNameSortParam) -value "decr" -width 12 \
          -indicatoron 0} $Gui(WCA)
    eval {button $f2.bPreviewAll -text "Preview" -command "DICOMPreviewAllButton"} $Gui(WBA)
    eval {button $f2.bListHeaders -text "List Headers" -command "DICOMListHeadersButton"} $Gui(WBA)
    eval {button $f2.bCheck -text "Check" -command "DICOMCheckFiles"} $Gui(WBA)

    pack $parent.f2.fileNames.fIncrDecr.rIncr $parent.f2.fileNames.fIncrDecr.rDecr $parent.f2.fileNames.fIncrDecr.bPreviewAll $parent.f2.fileNames.fIncrDecr.bListHeaders $parent.f2.fileNames.fIncrDecr.bCheck -side left -pady 2 -padx 0

    # ImageTextbox frame
    set Volumes(ImageTextbox) [ScrolledText $parent.f4]
    $Volumes(ImageTextbox) configure -height 8 -width 10
    pack $parent.f4 -fill both -expand true

    # DICOM Preview Settings Frame
    frame $parent.f4.fSettings -bg $Gui(activeWorkspace) -relief sunken -bd 2
    place $parent.f4.fSettings -relx 0.8 -rely 0.0 -anchor ne
    set f $parent.f4.fSettings
    set Volumes(DICOMPreviewSettingsFrame) $f

    frame $f.f1 -bg $Gui(activeWorkspace)
    pack $f.f1
    eval {label $f.f1.lWidth -text "Preview Width:" -width 15} $Gui(WLA)
    eval {entry $f.f1.ePreviewWidth -width 6 \
          -textvariable Volumes(DICOMPreviewWidth)} $Gui(WEA)
    pack $f.f1.lWidth $f.f1.ePreviewWidth -side left -padx 5 -pady 2

    frame $f.f2 -bg $Gui(activeWorkspace)
    pack $f.f2
    eval {label $f.f2.lHeight -text "Preview Height:" -width 15} $Gui(WLA)
    eval {entry $f.f2.ePreviewHeight -width 6 \
          -textvariable Volumes(DICOMPreviewHeight)} $Gui(WEA)
    pack $f.f2.lHeight $f.f2.ePreviewHeight -side left -padx 5 -pady 2

    frame $f.f3 -bg $Gui(activeWorkspace)
    pack $f.f3
    eval {label $f.f3.lHighest -text "Highest Value:" -width 15} $Gui(WLA)
    eval {entry $f.f3.eHighest -width 6 \
          -textvariable Volumes(DICOMPreviewHighestValue)} $Gui(WEA)
    pack $f.f3.lHighest $f.f3.eHighest -side left -padx 5 -pady 2

    eval {button $parent.f4.fSettings.bPreviewAll -text "Preview" -command "DICOMPreviewAllButton"} $Gui(WBA)
    pack $parent.f4.fSettings.bPreviewAll -padx 2 -pady 2

    # DICOMDataDict
    frame $parent.f4.fDataDict -bg $Gui(activeWorkspace) -relief sunken -bd 2
    place $parent.f4.fDataDict -relx 0.9 -rely 0.0 -anchor ne
    set f $parent.f4.fDataDict
    set Volumes(DICOMDataDictSettingsFrame) $f
    DevAddFileBrowse $f Volumes DICOMDataDictFile "DICOM Data Dictionary File" ""

    # >> Bindings

    bind $parent.f2.fileNames.fIncrDecr.bPreviewAll <Enter> "DICOMShowPreviewSettings"
    bind $parent.f4.fSettings <Leave> "DICOMHidePreviewSettings"

    bind $parent.f2.fileNames.fIncrDecr.bListHeaders <Enter> "DICOMShowDataDictSettings"
    bind $parent.f4.fDataDict <Leave> "DICOMHideDataDictSettings"

    bind $iDsNames <ButtonRelease-1> [list ClickListIDsNames %W $studyUIDs $seriesUIDs $fileNames]
    #bind $iDsNames <Double-1> [list ClickListIDsNames %W $studyUIDs $seriesUIDs $fileNames]
    bind $studyUIDs <ButtonRelease-1> [list ClickListStudyUIDs $iDsNames %W $seriesUIDs $fileNames]
    bind $seriesUIDs <ButtonRelease-1> [list ClickListSeriesUIDs $iDsNames $studyUIDs %W $fileNames]

    # << Bindings
    
    foreach x $values {
        $iDsNames insert end $x
    }
    
    $iDsNames selection set 0
    ClickListIDsNames $iDsNames $studyUIDs $seriesUIDs $fileNames
    $studyUIDs selection set 0
    ClickListStudyUIDs $iDsNames $studyUIDs $seriesUIDs $fileNames
    $seriesUIDs selection set 0
    ClickListSeriesUIDs $iDsNames $studyUIDs $seriesUIDs $fileNames

    DICOMHideAllSettings
}

#
#
#

#-------------------------------------------------------------------------------
# .PROC ChangeDir
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ChangeDir { dirlist } {
    global DICOMStartDir
    
    catch {cd $DICOMStartDir}
    set DICOMStartDir [pwd]
    
    $dirlist delete 0 end
    $dirlist insert end "../"
    foreach match [lsort -dictionary [glob -nocomplain *]] {
        if {[file isdirectory $match]} {
            $dirlist insert end $match/
        } else  {
            $dirlist insert end $match
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC ClickDirList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ClickDirList { dirlist } {
    global DICOMStartDir
    set diridx [$dirlist curselection]
    if  { $diridx != "" } {
        set dir [$dirlist get $diridx]
        set DICOMStartDir [file join $DICOMStartDir $dir]
        ChangeDir $dirlist
    }
}

#-------------------------------------------------------------------------------
# .PROC DICOMHelp
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMHelp { parent msg {textparams {}}} {
    global Gui

    toplevel $parent -bg $Gui(activeWorkspace)
    wm title $parent "DICOM Help"
    #wm minsize $parent 600 300

    frame $parent.f -bg $Gui(activeWorkspace)
    frame $parent.b -bg $Gui(activeWorkspace)
    pack $parent.f $parent.b -side top -fill both -expand true
    set t [eval {text $parent.f.t -setgrid true -wrap word -yscrollcommand "$parent.f.sy set"} $textparams]
    scrollbar $parent.f.sy -orient vert -command "$parent.f.t yview"
    pack $parent.f.sy -side right -fill y
    pack $parent.f.t -side left -fill both -expand true
    $parent.f.t insert end $msg

    eval { button $parent.b.close -text "Close" -command "destroy $parent" } $Gui(WBA)
    pack $parent.b.close -padx 10 -pady 10
}

#-------------------------------------------------------------------------------
# .PROC DICOMSelectDirHelp
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMSelectDirHelp {} {
    set msg "Select the start directory of DICOM studies either clicking \
the directory names in the listbox or typing the exact name and pressing Enter (or \
clicking the 'Change To' button).
Clicking ordinary files has no effect.
After pressing 'OK', the whole subdirectory will be traversed recursively and all DICOM \
files will be collected into a list."

    DICOMHelp .help $msg [list -width 60 -height 14]
    
    focus .help
    grab .help
    tkwait window .help
#    tk_messageBox -type ok -message "Help" -title "Title" -icon  info
}

#-------------------------------------------------------------------------------
# .PROC DICOMSelectDir
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMSelectDir {} {
    global DICOMStartDir
    global Pressed
    global Gui

    # sp-2003-05-06 simplified for slicer2.1

    set DICOMStartDir [tk_chooseDirectory \
        -initialdir $DICOMStartDir \
        -mustexist true \
        -title "Select Directory Containing DICOM Files" \
        -parent .tMain ]
    return

    
    toplevel $top -bg $Gui(activeWorkspace)
    wm minsize $top 100 100
    wm title $top "Select Start Directory"

    set f1 [frame $top.f1 -bg $Gui(activeWorkspace)]
    set f2 [frame $top.f2 -bg $Gui(activeWorkspace)]
    set f3 [frame $top.f3 -bg $Gui(activeWorkspace)]
    
    set dirlist [ScrolledListbox $f2.dirlist 1  1 -width 30 -height 15]
    TooltipAdd $dirlist "Select start directory for search"
    
    eval { button $f1.changeto -text "Change To:" -command  [list ChangeDir $dirlist]} $Gui(WBA)
    eval { entry $f1.dirname -textvariable DICOMStartDir } $Gui(WEA)
    
    eval {button $f3.ok -text "OK" -command "set Pressed OK; destroy $top"} $Gui(WBA)
    eval {button $f3.cancel -text "Cancel" -command "set Pressed Cancel; destroy $top"} $Gui(WBA)
    eval {button $f3.help -text "Help" -command "DICOMSelectDirHelp"} $Gui(WBA)

    pack $f1.changeto $f1.dirname -side left -padx 10 -pady 10
    pack $f2.dirlist -fill both -expand true
    pack $f3.ok $f3.cancel $f3.help -side left -padx 10 -pady 10 -anchor center
    pack $f1
    pack $f2 -fill both -expand true
    pack $f3
    #pack $window
    

    set pwd [pwd]
    catch {cd $DICOMStartDir}

    if {$DICOMStartDir == ""} {
      set DICOMStartDir [pwd]
    }
    
    ChangeDir $dirlist
    #$dirlist delete 0 end
    #$dirlist insert end ".."
    #foreach match [glob -nocomplain *] {
    #    if {[file isdirectory $match]} {
    #        $dirlist insert end $match
    #        #puts $dir
    #    }
    #}
    
#    bind $dirlist <ButtonRelease-1> [list ClickDirList %W]
    bind $dirlist <Double-1> [list ClickDirList %W]
    bind $f1.dirname <KeyRelease-Return> [list $f1.changeto invoke]
    
}

#-------------------------------------------------------------------------------
# .PROC DICOMSelectMain
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMSelectMain { fileNameListbox {autoload "noautoload"} {Pattern "*"} } {
    global DICOMStartDir
    global Pressed
    global DICOMPatientIDsNames
    global DICOMFileNameList DICOMFileNameSelected
    global Volume Volumes
    
    if {$Volume(activeID) != "NEW"} {
        return
    }

    set DICOMStartDir $Volumes(DICOMStartDir)
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    set Volume(dICOMFileList) {}
    if { $autoload != "autoload" } {
        DICOMSelectDir 
    }
    
    FindDICOM $DICOMStartDir $Pattern
    
    if { $::FindDICOMCounter == 0 } {
        destroy .list
        return
    }

    DICOMListSelect .list $DICOMPatientIDsNames
    
    if { $autoload != "autoload" } {
        focus .list
        grab .list
        tkwait window .list
    } else {
        destroy .list
        set Pressed "OK"
    }


    # >> AT 1/4/02
      if { $Pressed == "OK" } {
          #puts $DICOMFileNameList
          $fileNameListbox delete 0 end
          set Volume(dICOMFileList) {}
          foreach name $DICOMFileNameList selected $DICOMFileNameSelected {
              if {$selected == "1"} {
                  $fileNameListbox insert end $name
                  lappend Volume(dICOMFileList) $name
              }
          }
          #set Volume(dICOMFileList) $DICOMFileNameList

          set Volume(DICOMMultiFrameFile) 0
          DICOMReadHeaderValues [lindex $Volume(dICOMFileList) 0]
          if {[llength $Volume(dICOMFileList)] == "1"} {
      #        set file [lindex $Volume(dICOMFileList) 0]

              vtkDCMParser Volumes(parser)
              Volumes(parser) OpenFile [lindex $DICOMFileNameList 0]
              set numberofslices 1
              if { [Volumes(parser) FindElement 0x0054 0x0081] == "1" } {
                  Volumes(parser) ReadElement
                  set numberofslices [Volumes(parser) ReadUINT16]
              }

              set Volume(DICOMMultiFrameFile) 0
              if {$numberofslices > 1} {
                  set Volume(DICOMMultiFrameFile) $numberofslices

                  set height 0
                  if { [Volumes(parser) FindElement 0x0028 0x0010] == "1" } {
                      Volumes(parser) ReadElement
                      set height [Volumes(parser) ReadUINT16]
                  }

                  set width 0
                  if { [Volumes(parser) FindElement 0x0028 0x0011] == "1" } {
                      Volumes(parser) ReadElement
                      set width [Volumes(parser) ReadUINT16]
                  }

                  set bitsallocated 16
                  if { [Volumes(parser) FindElement 0x0028 0x0100] == "1" } {
                      Volumes(parser) ReadElement
                      set bitsallocated [Volumes(parser) ReadUINT16]
                  }
                  set bytesallocated [expr 1 + int(($bitsallocated - 1) / 8)]
                  set slicesize [expr $width * $height * $bytesallocated]


                  set Volume(DICOMSliceNumbers) {}
                  if { [Volumes(parser) FindElement 0x0054 0x0080] == "1" } {
      #            set NextBlock [lindex [split [Volumes(parser) ReadElement]] 4]
                  Volumes(parser) ReadElement
                  for {set j 0} {$j < $numberofslices} {incr j} {
                      set ImageNumber [Volumes(parser) ReadUINT16]
                      lappend Volume(DICOMSliceOffsets) [expr ($ImageNumber - 1) * $slicesize]
      #                $fileNameListbox insert end [expr ($ImageNumber - 1) * $slicesize]
                  }
                  } else {
                    for {set j 0} {$j < $numberofslices} {incr j} {
                        lappend Volume(DICOMSliceOffsets) [expr $j * $slicesize]
        #                $fileNameListbox insert end $j
                    }
                  }
              }
              
              Volumes(parser) CloseFile
              Volumes(parser) Delete

              # TODO: predict scan order
              VolumesSetScanOrder "IS"
          } else {
            # use the second and the third
            # set file1 [lindex $DICOMFileNameList 1]
            # set file2 [lindex $DICOMFileNameList 2]
            # DICOMReadHeaderValues [lindex $DICOMFileNameList 0]
            set file1 [lindex $Volume(dICOMFileList) 1]
            set file2 [lindex $Volume(dICOMFileList) 2]
            DICOMPredictScanOrder $file1 $file2
          }
          
          set Volumes(DICOMStartDir) $DICOMStartDir
      }
    # << AT 1/4/02
}

#-------------------------------------------------------------------------------
# .PROC HandleExtractHeader
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc HandleExtractHeader {} {
    global Volume

    if {$Volume(activeID) != "NEW"} {
        return
    }

    set fileidx [$Volume(dICOMFileListbox) index active]
    set filename [lindex $Volume(dICOMFileList) $fileidx]
    DICOMReadHeaderValues $filename

    VolumesSetPropertyType VolHeader
}

#-------------------------------------------------------------------------------
# .PROC DICOMReadHeaderValues
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMReadHeaderValues { filename } {
    global Volume

    if {$filename == ""} {
        return
    } else {
        if {$::Module(verbose)} {
            puts "DICOMReadHeaderValues: filename = $filename"
        }
    }
   
    vtkDCMParser parser
    set found [parser OpenFile $filename]
    if {[string compare $found "0"] == 0} {
        puts stderr "Can't open file $filename\n"
        parser Delete
        return
    } else {
        # sp 2003-07-09 - capture the series description to name volume
        set seriesdesc ""
        if { [parser FindElement 0x0008 0x103e] == "1" } {
            set len [lindex [split [parser ReadElement]] 3]
            set seriesdesc [parser ReadText $len]
        }
        regsub -all {[^a-zA-Z0-9]} $seriesdesc "_" Volume(seriesDesc)
        if {$::Module(verbose)} { puts "got seriesdesc $::Volume(seriesDesc)"} 

        # sp 2005-03-16 - capture the series number also for the volume name
        if { [parser FindElement 0x0020 0x0011] == "1" } {
            set len [lindex [split [parser ReadElement]] 3]
            set ::Volume(seriesNum) [parser ReadText $len]
        }
        if {$::Module(verbose)} { puts "got seriesnum $::Volume(seriesNum)"} 

        if { [parser FindElement 0x0010 0x0010] == "1" } {
            set Length [lindex [split [parser ReadElement]] 3]
            set PatientName [parser ReadText $Length]
            if {$PatientName == ""} {
                set PatientName "noname"
            }
        } else  {
            set PatientName 'unknown'
        }
        #regsub -all {\ |\t|\n} $PatientName "_" Volume(name)
        regsub -all {[^a-zA-Z0-9]} $PatientName "_" Volume(name)
        
        if { [parser FindElement 0x0028 0x0010] == "1" } {
            #set Length [lindex [split [parser ReadElement]] 3]
            parser ReadElement
            set Volume(height) [parser ReadUINT16]
        } else  {
            set Volume(height) "unknown"
        }

        if { [parser FindElement 0x0028 0x0011] == "1" } {
            #set Length [lindex [split [parser ReadElement]] 3]
            parser ReadElement
            set Volume(width) [parser ReadUINT16]
        } else  {
            set Volume(width) "unknown"
        }

        if { [parser FindElement 0x0028 0x0030] == "1" } {
            set NextBlock [lindex [split [parser ReadElement]] 4]
            set Volume(pixelWidth) [parser ReadFloatAsciiNumeric $NextBlock]
            set Volume(pixelHeight) [parser ReadFloatAsciiNumeric $NextBlock]

        } else  {
            set Volume(pixelWidth) 1.0
            set Volume(pixelHeight) 1.0
            puts stderr "No PixelSize found - using 1.0 ($filename)"
        }

        if { [parser FindElement 0x0018 0x1120] == "1" } {
            set NextBlock [lindex [split [parser ReadElement]] 4]
            set Volume(gantryDetectorTilt) [parser ReadFloatAsciiNumeric $NextBlock]
        } else  {
            set Volume(gantryDetectorTilt) 0
        }
        if { [parser FindElement 0x0018 0x5100] == "1" } {
            set Length [lindex [split [parser ReadElement]] 3]
            set str [parser ReadText $Length]
            if {[string compare -nocase [string trim $str] "HFP"] == "0"} {
            set Volume(gantryDetectorTilt) [expr -1.0 * $Volume(gantryDetectorTilt)]
            }
        }

        if { [parser FindElement 0x0008 0x0060] == "1" } {
            set Length [lindex [split [parser ReadElement]] 3]
            set Volume(desc) [parser ReadText $Length]
        } else  {
            set Volume(desc) "unknown modality"
        }

        set tfs [parser GetTransferSyntax] 
        if { $tfs == "3" || $tfs == "4" } {
            set Volume(littleEndian) 0
        } else {
            set Volume(littleEndian) 1
        }

        if { [parser FindElement 0x0018 0x0050] == "1" } {
            set NextBlock [lindex [split [parser ReadElement]] 4]
            set readThickness [parser ReadFloatAsciiNumeric $NextBlock]
        } else  {
            set readThickness 1.0
            puts stderr "No SliceThickness found - using 1.0 ($filename)"
        }
        # check to see if the sliceThickness was already set, and not to the default

        # from MainVolumes.tcl, getting the default thickness for a volume
        vtkMrmlVolumeNode voldicomDefaultVol
        set defspacing [voldicomDefaultVol GetSpacing]
        set defthickness [lindex $defspacing 2]
        voldicomDefaultVol Delete

        if {$Volume(sliceThickness) != $defthickness && $Volume(sliceThickness) != $readThickness} {
            set answer [tk_messageBox -message "Slice thickness is already set to $Volume(sliceThickness). The value in the file header is $readThickness.\nWould you like to use the value from the header ($readThickness)?" \
                    -type yesno -icon question -title "Slice thickness question."]
            if {$answer == "yes"} {
                set Volume(sliceThickness) $readThickness
            }
        } else {
            # just use the read value
            set Volume(sliceThickness) $readThickness
        }


        # Number of Scalars and ScalarType 

        if { [parser FindElement 0x0028 0x0002] == "1" } {
            parser ReadElement
            set Volume(numScalars) [parser ReadUINT16]
        } else  {
            set Volume(numScalars) "unknown"
        }
        
        if { [parser FindElement 0x0028 0x0103] == "1" } {
            parser ReadElement
            set PixelRepresentation [parser ReadUINT16]
        } else  {
            set PixelRepresentation 1
        }
        
        if { [parser FindElement 0x0028 0x0100] == "1" } {
            parser ReadElement
            set BitsAllocated [parser ReadUINT16]
            if { $BitsAllocated == "16" } {
                if { $PixelRepresentation == "0" } {
                    #VolumesSetScalarType "UnsignedShort"
                    VolumesSetScalarType "Short"
                } else {
                    VolumesSetScalarType "Short"
                }
            }

            if { $BitsAllocated == "8" } {
                if { $PixelRepresentation == "0" } {
                    VolumesSetScalarType "UnsignedChar"
                } else {
                    VolumesSetScalarType "Char"
                }
            }
        } else  {
            # do nothing
        }

    }

    parser Delete
    
    # set the file pattern and firstFile here
    set Volume(firstFile) $filename
    set Volume(filePattern) [lindex [MainFileParseImageFile $Volume(firstFile)] 0]
    set Volume(readHeaders) 0
}

#-------------------------------------------------------------------------------
# .PROC DICOMPredictScanOrder
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMPredictScanOrder { file1 file2 } {
    global Volume

    # set default
    VolumesSetScanOrder "IS"

    if { ($file1 == "") || ($file2 == "") } {
        return
    }

    catch "parser Delete"
    vtkDCMParser parser

    set found [parser OpenFile $file1]
    if {[string compare $found "0"] == 0} {
        puts stderr "Can't open file $file1\n"
        parser Delete
        return
    }

    if { [parser FindElement 0x0020 0x0032] == "1" } {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set x1 [parser ReadFloatAsciiNumeric $NextBlock]
        set y1 [parser ReadFloatAsciiNumeric $NextBlock]
        set z1 [parser ReadFloatAsciiNumeric $NextBlock]
    } else  {
        parser Delete
        return
    }

    set SlicePosition1 ""
    if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SlicePosition1 [parser ReadFloatAsciiNumeric $NextBlock]
    }

    parser CloseFile

    set found [parser OpenFile $file2]
    if {[string compare $found "0"] == 0} {
        puts stderr "Can't open file $file2\n"
        parser Delete
        return
    }

    if { [parser FindElement 0x0020 0x0032] == "1" } {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set x2 [parser ReadFloatAsciiNumeric $NextBlock]
        set y2 [parser ReadFloatAsciiNumeric $NextBlock]
        set z2 [parser ReadFloatAsciiNumeric $NextBlock]
    } else  {
        parser Delete
        return
    }

    set SlicePosition2 ""
    if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SlicePosition2 [parser ReadFloatAsciiNumeric $NextBlock]
    }

    #set Volume(filePattern) [format "%.2f %.2f %.2f" $x1 $y1 $z1]

    # Predict scan order

    set dx [expr $x2 - $x1]
    set dy [expr $y2 - $y1]
    set dz [expr $z2 - $z1]

    if { abs($dx) > abs($dy) } {
        if { abs($dx) > abs($dz) } {
            # sagittal
            if { $dx > 0 } {
                VolumesSetScanOrder "RL"
            } else {
                VolumesSetScanOrder "LR"
            }
        } else {
            if { $dz > 0 } {
                # axial IS
                VolumesSetScanOrder "IS"
            } else {
                # axial SI
                VolumesSetScanOrder "SI"
            }
        }
    } else {
    if { abs ($dy) > abs($dz) } {
        # coronal
        if { $dy > 0 } {
            VolumesSetScanOrder "AP"
        } else {
            VolumesSetScanOrder "PA"
        }
    } else {
        if { $dz > 0 } {
            # axial IS
            VolumesSetScanOrder "IS"
        } else {
            # axial SI
            VolumesSetScanOrder "SI"
        }
    }
    }

    # Calculate Slice Distance

    if {($SlicePosition1 != "") && ($SlicePosition2 != "")} {
        set diff [expr abs($SlicePosition2 - $SlicePosition1)]
    } else {
        set diff [expr sqrt($dx * $dx + $dy * $dy + $dz *$dz)]
    }

    scan $Volume(gantryDetectorTilt) "%f" gantrytilt
    if {$gantrytilt != ""} {
        set thickness [expr $diff * cos([expr $gantrytilt * acos(-1.0) / 180.0])]
    } else {
        set thickness $diff
    }

    if {$Volume(sliceThickness) != "unknown"} {
        # don't ever use a calculated thickness of zero, but if there's a 
        # significant difference between expected and actual, give a choice
        if { $thickness > 0 && 
                [expr abs($thickness - $Volume(sliceThickness))] > 0.05} {
            set answer [tk_messageBox -message "Slice thickness is $Volume(sliceThickness) in the header, but $thickness when calculated from Slice Positions.\nWould you like to use the calculated one ($thickness)?" \
                    -type yesno -icon question -title "Slice thickness question."]
            if {$answer == "yes"} {
                set Volume(sliceThickness) $thickness
            }
        }
    }

    parser CloseFile
    parser Delete
}

#-------------------------------------------------------------------------------
# .PROC DICOMPreviewAllButton
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMPreviewAllButton {} {
    global Volumes DICOMFileNameList DICOMFileNameSelected

    DICOMHideAllSettings
    $Volumes(ImageTextbox) delete 1.0 end

    # >> AT 1/4/02 multiframe modification

    vtkDCMParser Volumes(PABparser)
    set found [Volumes(PABparser) OpenFile [lindex $DICOMFileNameList 0]]
    if {$found == "0"} {
        puts stderr "Can't open file $file\n"
        Volumes(PABparser) Delete
        return
    }
    
    set numberofslices 1
    if { [Volumes(PABparser) FindElement 0x0054 0x0081] == "1" } {
        Volumes(PABparser) ReadElement
        set numberofslices [Volumes(PABparser) ReadUINT16]
    }
    Volumes(PABparser) CloseFile
    Volumes(PABparser) Delete
    
    if {$numberofslices > 1} {
        for {set i 0} {$i < $numberofslices} {incr i} {
            set img [image create photo -width $Volumes(DICOMPreviewWidth) -height $Volumes(DICOMPreviewHeight) -palette 256]
            DICOMPreviewFile [lindex $DICOMFileNameList 0] $img $i
            if {[lindex $DICOMFileNameSelected 0] == "1"} {
                set color green
            } else {
                set color red
            }
            label $Volumes(ImageTextbox).l$i -image $img -background $color -cursor hand1
    #        bind $Volumes(ImageTextbox).l$i <ButtonRelease-1> "DICOMPreviewImageClick $Volumes(ImageTextbox).l$i $i"
    #        #label $Volumes(ImageTextbox).l$i -image $img -background green
            $Volumes(ImageTextbox) window create insert -window $Volumes(ImageTextbox).l$i
            #$Volumes(ImageTextbox) insert insert " "
            update idletasks
        }
    } else {
        for {set i 0} {$i < [llength $DICOMFileNameList]} {incr i} {
            set img [image create photo -width $Volumes(DICOMPreviewWidth) -height $Volumes(DICOMPreviewHeight) -palette 256]
            DICOMPreviewFile [lindex $DICOMFileNameList $i] $img 0
            if {[lindex $DICOMFileNameSelected $i] == "1"} {
                set color green
            } else {
                set color red
            }
            label $Volumes(ImageTextbox).l$i -image $img -background $color -cursor hand1
            bind $Volumes(ImageTextbox).l$i <ButtonRelease-1> "DICOMPreviewImageClick $Volumes(ImageTextbox).l$i $i"
            #label $Volumes(ImageTextbox).l$i -image $img -background green
            $Volumes(ImageTextbox) window create insert -window $Volumes(ImageTextbox).l$i
            #$Volumes(ImageTextbox) insert insert " "
            update idletasks
        }
    }

    # << AT 1/4/02 multiframe modification
}

#-------------------------------------------------------------------------------
# .PROC DICOMListHeadersButton
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMListHeadersButton {} {
    global Volumes DICOMFileNameList DICOMFileNameSelected

    DICOMHideAllSettings
    $Volumes(ImageTextbox) delete 1.0 end

    vtkDCMLister Volumes(lister)
    Volumes(lister) ReadList $Volumes(DICOMDataDictFile)
    Volumes(lister) SetListAll 0

    for {set i 0} {$i < [llength $DICOMFileNameList]} {incr i} {
        if {[lindex $DICOMFileNameSelected $i] == "0"} {
            continue
        }

        set img [image create photo -width $Volumes(DICOMPreviewWidth) -height $Volumes(DICOMPreviewHeight) -palette 256]
        set filename [lindex $DICOMFileNameList $i]
        DICOMPreviewFile $filename $img
        label $Volumes(ImageTextbox).l$i -image $img
        $Volumes(ImageTextbox) window create insert -window $Volumes(ImageTextbox).l$i
        $Volumes(ImageTextbox) insert insert " $filename\n"
        DICOMListHeader $filename
        $Volumes(ImageTextbox) insert insert "\n"
        update idletasks
    #    break
    }

    Volumes(lister) Delete
}

#-------------------------------------------------------------------------------
# .PROC DICOMListHeader
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMListHeader {filename} {
    global Volumes

    set ret [Volumes(lister) OpenFile $filename]
    if {$ret == "0"} {
        return
    }
    
    #Volumes(lister) ReadList $Volumes(DICOMDataDictFile)
    #Volumes(lister) SetListAll 0

    while {[Volumes(lister) IsStatusOK] == "1"} {
      set ret [Volumes(lister) ReadElement]
      if {[Volumes(lister) IsStatusOK] == "0"} {
          break
      }
      set group [lindex $ret 1]
      set element [lindex $ret 2]
      set length [lindex $ret 3]
      set vr [lindex $ret 0]
      set msg [Volumes(lister) callback $group $element $length $vr]
      if {$msg != "Empty."} {
          $Volumes(ImageTextbox) insert insert $msg
          #$Volumes(ImageTextbox) insert insert "\n"
          $Volumes(ImageTextbox) see end
          update idletasks
      }
    }

    Volumes(lister) CloseFile
}

#-------------------------------------------------------------------------------
# .PROC DICOMPreviewFile
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMPreviewFile {file img {slicenumber 0}} {
    global Volumes Volume

    vtkDCMLister parser

    set found [parser OpenFile $file]
    if {$found == "0"} {
      puts stderr "Can't open file $file\n"
      parser Delete
      return
    }

    if { [parser FindElement 0x0028 0x0010] == "1" } {
      parser ReadElement
      set height [parser ReadUINT16]
    } else  {
      parser Delete
      return
    }

    if { [parser FindElement 0x0028 0x0011] == "1" } {
      parser ReadElement
      set width [parser ReadUINT16]
    } else  {
      parser Delete
      return
    }

    # >> AT 1/4/02 multiframe modification

    set bitsallocated 16
    if { [parser FindElement 0x0028 0x0100] == "1" } {
      parser ReadElement
      set bitsallocated [parser ReadUINT16]
    }
    set bytesallocated [expr 1 + int(($bitsallocated - 1) / 8)]
    set slicesize [expr $width * $height * $bytesallocated]
    
#    set SkipColumn [expr int(($width - 1) / $Volumes(DICOMPreviewWidth)) * 2]
#    set SkipRow [expr int(($height - 1) / $Volumes(DICOMPreviewHeight)) * $width * 2]
#    set WidthInBytes [expr $width * 2]

    set SkipColumn [expr int(($width - 1) / $Volumes(DICOMPreviewWidth)) * $bytesallocated]
    set SkipRow [expr int(($height - 1) / $Volumes(DICOMPreviewHeight)) * $width * $bytesallocated]
    set WidthInBytes [expr $width * $bytesallocated]

    # << AT 1/4/02 multiframe modification

    if { [parser FindElement 0x7fe0 0x0010] == "1" } {
        parser ReadElement

        if {$slicenumber != "0"} {
            set offset [parser GetFilePosition]
            set offset [expr $offset + $slicenumber * $slicesize]
            parser SetFilePosition $offset
        }

        for {set i 0} {$i < $Volumes(DICOMPreviewHeight)} {incr i} {
            set row {}
            
            set FilePos [parser GetFilePosition]
            $img put [list [parser GetTCLPreviewRow $Volumes(DICOMPreviewWidth) $SkipColumn $Volumes(DICOMPreviewHighestValue)]] -to 0 $i
            parser SetFilePosition [expr $FilePos + $WidthInBytes]
            parser Skip $SkipRow
        }
    }

    parser CloseFile
    parser Delete
}

#-------------------------------------------------------------------------------
# .PROC DICOMCheckFiles
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMCheckFiles {} {
    global Volumes Volume DICOMFileNameList DICOMFileNameSelected

    set t $Volumes(ImageTextbox)
    $t delete 1.0 end

    set num 0
    foreach selected $DICOMFileNameSelected {
        # It is assumed that the possible values of selected
        # are 0 and 1 only.
        incr num $selected
    }
    if {$num < 2} {
        $t insert insert "Single file - no need to check.\n"
        return
    }

    set num [llength $DICOMFileNameSelected]
    set localDICOMFileNameList {}
    set localIndex {}
    for {set i 0} {$i < $num} {incr i} {
        if {[lindex $DICOMFileNameSelected $i] == "1"} {
            lappend localDICOMFileNameList [lindex $DICOMFileNameList $i]
            lappend localIndex $i
        }
    }

    set file1 [lindex $localDICOMFileNameList 0]
    set file2 [lindex $localDICOMFileNameList 1]
    set ret [DICOMCheckVolumeInit $file1 $file2 [lindex $localIndex 0]]
    if {$ret == "1"} {
        set max [llength $localDICOMFileNameList]
        for {set i 1} {$i < $max} {incr i} {
            set file [lindex $localDICOMFileNameList $i]
            set msg "Checking $file\n"
            $t insert insert $msg
            $t see end
            update idletasks
            DICOMCheckFile $file [lindex $localIndex $i] [lindex $localIndex [expr $i - 1]]
        }
    }
    lappend Volumes(DICOMCheckVolumeList) $Volumes(DICOMCheckActiveList)
    lappend Volumes(DICOMCheckPositionList) $Volumes(DICOMCheckActivePositionList)
    lappend Volumes(DICOMCheckSliceDistanceList) $Volumes(DICOMCheckSliceDistance)

    $t insert insert "Volume checking finished.\n"

    $t insert insert $Volumes(DICOMCheckVolumeList)
    $t insert insert "\n"
    $t insert insert $Volumes(DICOMCheckPositionList)
    $t insert insert "\n"
    $t insert insert $Volumes(DICOMCheckSliceDistanceList)
    $t insert insert "\n"

    set len [llength $Volumes(DICOMCheckSliceDistanceList)]
    if {$len == "1"} {
        if {[llength [lindex $Volumes(DICOMCheckVolumeList) 0]] > 0} {
            $t insert insert "The volume seems to be OK.\n"
            $t see end
        }
        return
    }

    set msg "$len fragments detected.\n"
    $t insert insert $msg

    set Volumes(DICOMCheckImageLabelIdx) 0
    for {set i 0} {$i < $len} {incr i} {
        set firstpos [$t index insert]
        set dist [lindex $Volumes(DICOMCheckSliceDistanceList) $i]
        set activeList [lindex $Volumes(DICOMCheckVolumeList) $i]
        set activeLength [llength $activeList]
        set activePositionList [lindex $Volumes(DICOMCheckPositionList) $i]
        $t insert insert "Fragment \#[expr $i + 1], $activeLength slices, slice distance is $dist:\n"
        $t insert insert "Positions: "
        $t insert insert $activePositionList
        $t insert insert "\n"

        for {set j 0} {$j < $activeLength} {incr j} {
            set idx [lindex $activeList $j]
            set file [lindex $DICOMFileNameList $idx]
            set img [image create photo -width $Volumes(DICOMPreviewWidth) -height $Volumes(DICOMPreviewHeight) -palette 256]
            DICOMPreviewFile $file $img
            set labelIdx $Volumes(DICOMCheckImageLabelIdx)
            label $Volumes(ImageTextbox).l$Volumes(DICOMCheckImageLabelIdx) -image $img -cursor hand1
            bind $Volumes(ImageTextbox).l$Volumes(DICOMCheckImageLabelIdx) <ButtonRelease-1> "DICOMSelectFragment $i"
            bind $Volumes(ImageTextbox).l$Volumes(DICOMCheckImageLabelIdx) <Enter> "DICOMImageTextboxFragmentEnter %W fragm${i}"
            bind  $Volumes(ImageTextbox).l$Volumes(DICOMCheckImageLabelIdx) <Leave> "DICOMImageTextboxFragmentLeave %W fragm${i}"
            $Volumes(ImageTextbox) window create insert -window $Volumes(ImageTextbox).l$Volumes(DICOMCheckImageLabelIdx)
            incr Volumes(DICOMCheckImageLabelIdx)
        }
        $t insert insert "\n\n"
        $t tag add fragm${i} $firstpos [$t index insert]
        $t tag bind fragm${i} <ButtonRelease-1> "DICOMSelectFragment $i"
        $t tag bind fragm${i} <Enter> "DICOMImageTextboxFragmentEnter %W fragm${i}"
        $t tag bind fragm${i} <Leave> "DICOMImageTextboxFragmentLeave %W fragm${i}"

        $t see end
        update idletasks
    }
}

#-------------------------------------------------------------------------------
# .PROC DICOMCheckVolumeInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMCheckVolumeInit {file1 file2 file1idx} {
    global Volumes Volume

    vtkDCMParser parser
    set t $Volumes(ImageTextbox)

    set Volumes(DICOMCheckVolumeList) {}
    set Volumes(DICOMCheckPositionList) {}
    set Volumes(DICOMCheckActiveList) {}
    set Volumes(DICOMCheckActivePositionList) {}
    set Volumes(DICOMCheckSliceDistanceList) {}

    set found [parser OpenFile $file1]
    if {$found == "0"} {
        $t insert insert "Can't open file $file1\n"
        parser Delete
        return 0
    }

    set SlicePosition1 ""
    if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SlicePosition1 [parser ReadFloatAsciiNumeric $NextBlock]
    } 
    if { $SlicePosition1 == "" } {
        $t insert insert "Image Position (0020,1041) not found in file $file1.\n"
        parser Delete
        return 0
    }
    
    $t insert insert "Detected slice position in $file1: $SlicePosition1\n"

    parser CloseFile

    set found [parser OpenFile $file2]
    if {$found == "0"} {
        $t insert insert "Can't open file $file2\n"
        parser Delete
        return 0
    }

    set SlicePosition2 ""
    if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SlicePosition2 [parser ReadFloatAsciiNumeric $NextBlock]
    } 
    if { $SlicePosition2 == "" } {
        $t insert insert "Image Position (0020,1041) not found in file $file2.\n"
        parser Delete
        return 0
    }
    
    $t insert insert "Detected slice position in $file2: $SlicePosition2\n"

    set Volumes(DICOMCheckLastPosition) $SlicePosition1
    set Volumes(DICOMCheckSliceDistance) [expr $SlicePosition2 - $SlicePosition1]
    $t insert insert "Detected slice distance: $Volumes(DICOMCheckSliceDistance)\n"

    lappend Volumes(DICOMCheckActiveList) $file1idx
    lappend Volumes(DICOMCheckActivePositionList) $SlicePosition1

    parser CloseFile
    parser Delete
    return 1
}

#-------------------------------------------------------------------------------
# .PROC DICOMCheckFile
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMCheckFile {file idx previdx} {
    global Volumes Volume

    vtkDCMParser parser
    set t $Volumes(ImageTextbox)

    set found [parser OpenFile $file]
    if {$found == "0"} {
        $t insert insert "Can't open file $file\n"
        parser Delete
        return 0
    }

    set SlicePosition ""
    if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SlicePosition [parser ReadFloatAsciiNumeric $NextBlock]
    } 
    if { $SlicePosition == "" } {
        $t insert insert "Image Position (0020,1041) not found in file $file. Skipping.\n"
        parser Delete
        return 0
    }
    
    $t insert insert "Detected slice position in $file: $SlicePosition\n"
    set dist [expr $SlicePosition - $Volumes(DICOMCheckLastPosition)]
    set diff [expr abs($dist - $Volumes(DICOMCheckSliceDistance))]
    if {$diff < 0.1} {
        lappend Volumes(DICOMCheckActiveList) $idx
        lappend Volumes(DICOMCheckActivePositionList) $SlicePosition
    } else {
        lappend Volumes(DICOMCheckVolumeList) $Volumes(DICOMCheckActiveList)
        lappend Volumes(DICOMCheckPositionList) $Volumes(DICOMCheckActivePositionList)
        lappend Volumes(DICOMCheckSliceDistanceList) $Volumes(DICOMCheckSliceDistance)
        set Volumes(DICOMCheckActiveList) [list $previdx $idx]
        set Volumes(DICOMCheckActivePositionList) {}
        lappend Volumes(DICOMCheckActivePositionList) $Volumes(DICOMCheckLastPosition)
        lappend Volumes(DICOMCheckActivePositionList) $SlicePosition
        $t insert insert "Slice Position discrepancy. New distance: $dist\n"
        set Volumes(DICOMCheckSliceDistance) $dist
    }

    set Volumes(DICOMCheckLastPosition) $SlicePosition

    parser CloseFile
    parser Delete

    return 1
}

#-------------------------------------------------------------------------------
# .PROC DICOMShowPreviewSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMShowPreviewSettings {} {
    global Volumes

    raise $Volumes(DICOMPreviewSettingsFrame)
    DICOMHideDataDictSettings
}

#-------------------------------------------------------------------------------
# .PROC DICOMHidePreviewSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMHidePreviewSettings {} {
    global Volumes

    lower $Volumes(DICOMPreviewSettingsFrame) $Volumes(ImageTextbox)
}

#-------------------------------------------------------------------------------
# .PROC DICOMShowDataDictSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMShowDataDictSettings {} {
    global Volumes

    raise $Volumes(DICOMDataDictSettingsFrame)
    DICOMHidePreviewSettings
}

#-------------------------------------------------------------------------------
# .PROC DICOMHideDataDictSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMHideDataDictSettings {} {
    global Volumes

    lower $Volumes(DICOMDataDictSettingsFrame) $Volumes(ImageTextbox)
}

#-------------------------------------------------------------------------------
# .PROC DICOMHideAllSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMHideAllSettings {} {
    global Volumes

    DICOMHidePreviewSettings
    DICOMHideDataDictSettings
}

#-------------------------------------------------------------------------------
# .PROC DICOMSelectFragment
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMSelectFragment {fragment} {
    global Volumes DICOMFileNameList DICOMFileNameSelected

    set activeList [lindex $Volumes(DICOMCheckVolumeList) $fragment]
    set activeLength [llength $activeList]
    set activePositionList [lindex $Volumes(DICOMCheckPositionList) $fragment]

    set DICOMFileNameSelected {}
    set num [llength $DICOMFileNameList]
    for {set j 0} {$j < $num} {incr j} {
        lappend DICOMFileNameSelected "0"
    }

    for {set j 0} {$j < $activeLength} {incr j} {
        set idx [lindex $activeList $j]
        set DICOMFileNameSelected [lreplace $DICOMFileNameSelected $idx $idx "1"]
    }
    $Volumes(DICOMFileNameTextbox) see [lindex $activeList 0].0
    DICOMFillFileNameTextbox $Volumes(DICOMFileNameTextbox)
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxFragmentEnter
#   Changes the cursor over the PointTextbox to a cross
#   and stores the old one.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxFragmentEnter {w tag} {
    global Volumes

    set f2 $Volumes(ImageTextbox)
    #set Volumes(ImageTextboxOldCursor) [$f2 cget -cursor]
    set Volumes(ImageTextboxOldCursor) [$w cget -cursor]
    #$f2 configure -cursor pencil
    $w configure -cursor hand1
    $f2 tag configure $tag -background #43ce80 -relief raised -borderwidth 1
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxFragmentLeave
#   Changes back the original cursor after leaving
#   the PointTextbox.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxFragmentLeave {w tag} {
    global Volumes

    set f2 $Volumes(ImageTextbox)
    #$f2 configure -cursor $Volumes(ImageTextboxOldCursor)
    $w configure -cursor $Volumes(ImageTextboxOldCursor)
    $f2 tag configure $tag -background {} -relief flat
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxSelectAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxSelectAll {} {
    global Volumes DICOMFileNameSelected

    set num [llength $DICOMFileNameSelected]
    set DICOMFileNameSelected {}
    for {set i 0} {$i < $num} {incr i} {
        lappend DICOMFileNameSelected "1"
    }
    DICOMFillFileNameTextbox $Volumes(DICOMFileNameTextbox)    
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxDeselectAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxDeselectAll {} {
    global Volumes DICOMFileNameSelected

    set num [llength $DICOMFileNameSelected]
    set DICOMFileNameSelected {}
    for {set i 0} {$i < $num} {incr i} {
        lappend DICOMFileNameSelected "0"
    }
    DICOMFillFileNameTextbox $Volumes(DICOMFileNameTextbox)    
}


########################################################################
# End of DICOM procedures
########################################################################

