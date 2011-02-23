#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ValidationView.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:35 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        ValidationView.tcl
# PROCEDURES:  
#   ValidationLoadSubject
#   ValidationLoadXML
#   ValidationSetView
#   ValidationSelectWindow
#==========================================================================auto=
# This scripte generates the right view for the validation of Birn Data 
# ./slicer2-linux-x86 --exec ValidationSelectWindow
set ::Validation(SubjectFolder) /nas/nas0/miriad/subjects
set ::Validation(Subject) ""
set ::Validation(XMLPrefix) Visit_001/Study_0001/DerivedData/SPL/EM-reg_LONIbAb__params_params-sp-duke-2004-02-19_ic/Validation.xml


set Validation(PreSelectedSubjectList) "000300742113 000303985208 000304856067 000305619085 000307120185 000307356304 000308257133 000314718325 000317154938 000318468632 000326206804 000329531884 000330850754 000334951552 000337129879 000338221247 000338715174 000342712406 000349481087 000350391081 000353106219 000354708511 000358323055 000359838929 000362037702 000362391770 000364087376 000370767640 000371631918 000375528332 000380582348 000382166785 000386884553 000389545720 000390978520 000393911440 000397921927"

#-------------------------------------------------------------------------------
# .PROC ValidationLoadSubject
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ValidationLoadSubject {} {
    if { $::Validation(Subject) != "" } { 
    set ::Mrml(dir) [file join $::Validation(SubjectFolder) $::Validation(Subject)] 
    set ::File(filePrefix) $::Validation(XMLPrefix)
    ValidationLoadXML 
    ValidationSetView
    } else {
    DevWarningWindow "No Subject selected"
    }
}

#-------------------------------------------------------------------------------
# .PROC ValidationLoadXML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ValidationLoadXML { } {
    MainMrmlRead [file join $::Mrml(dir) $::File(filePrefix)] 
    MainUpdateMRML
    MainOptionsRetrievePresetValues
    MainSetup
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC ValidationSetView
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ValidationSetView {} {
    puts "==== Start Setup Validation View "

    # Image for the  Background - later put here segmentation 
    set id [MIRIADSegmentGetVolumeByName EMSegResult1]
    MainSlicesSetVolumeAll Fore $id 

    # Image for the Background
    set id [MIRIADSegmentGetVolumeByName PD]
    MainSlicesSetVolumeAll Back $id  
    # 3D View 
    MainMenu View Quad512

    # Show 2 D Slices in 3D View 
    foreach s $::Slice(idList) {
    set ::Slice($s,visibility) 1
    MainSlicesSetVisibility ${s} 
    MainViewerHideSliceControls
    Render3D
    }

    # Set view to Slices 
    MainSlicesSetOrientAll Slices
    MainViewerHideSliceControls
    RenderAll

    puts "==== End Setup Validation View "
}

#-------------------------------------------------------------------------------
# .PROC ValidationSelectWindow
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ValidationSelectWindow {} {
    global Gui
    set w .wValidation 
    set ::Gui(wValidation) $w

    if {[winfo exists $::Gui(wValidation)]} {destroy  $::Gui(wValidation)}
    #-------------------------------------------
    # Popup Window
    #-------------------------------------------
    toplevel $w  -bg $::Gui(activeWorkspace)
    wm title $w "Load Subject"
    wm geometry $w +[expr [winfo screenwidth $w]/2-250]+[expr [winfo screenheight $w]/2-200]
    set f $w
    
    frame $f.fSelect -bg $::Gui(activeWorkspace)
    pack $f.fSelect -side top -padx 4 -pady 4
    eval {label $f.fSelect.lText -text "Select Subject:  " } $::Gui(WTA)
    eval {menubutton $f.fSelect.mbSubject -text "None"  -menu $f.fSelect.mbSubject.m -width 13} $::Gui(WMBA) 
    pack $f.fSelect.lText  $f.fSelect.mbSubject -side left
    if {$::Validation(PreSelectedSubjectList) == "" } { 
    if {[catch { set SubjectList [glob $::Validation(SubjectFolder)/* ] } ErrorMessage] } {
        DevErrorWindow "No subjects in $::Validation(SubjectFolder) ErrorMessage: $ErrorMessage" 
        return
    }
    } else {
    set SubjectList $::Validation(PreSelectedSubjectList)
    }
    set NewSubjectList ""
    foreach SUBJECT $SubjectList {
    set SUBJECT [file tail $SUBJECT]
    # puts "$SUBJECT [string first "0003" $SUBJECT] [file exists [file join $::Validation(SubjectFolder) $SUBJECT $::Validation(XMLPrefix)]]
    if {([string first "0003" $SUBJECT] == 0) && [file exists [file join $::Validation(SubjectFolder) $SUBJECT $::Validation(XMLPrefix)]]} {
        lappend NewSubjectList $SUBJECT
    }
    } 
    if {$NewSubjectList == "" } {
    DevErrorWindow "No proper subjects found in $::Validation(SubjectFolder) where the following file exists $::Validation(XMLPrefix)" 
    return 
    } else {
    set SubjectList $NewSubjectList
    } 

    TooltipAdd  $f.fSelect.mbSubject "Select Subject to be validated"

    # Define Menu selection 

    eval {menu $f.fSelect.mbSubject.m} $::Gui(WMA)
    # Add Selection entry
    set MenuMaxLength 25 
    set NumCasecade [expr [llength $SubjectList] / $MenuMaxLength + 1]
    for {set i 0} {$i < $NumCasecade} { incr i } {
    set Min [expr $i*$MenuMaxLength +1 ]
    set Max [expr ($i+1)*$MenuMaxLength]
        $f.fSelect.mbSubject.m add cascade -label "Subjects $Min - $Max" \
        -menu $f.fSelect.mbSubject.m.m$i
    menu $f.fSelect.mbSubject.m.m$i
    incr Min -1 
    incr Max -1
    set SelectedSubjectList  [lrange $SubjectList $Min $Max] 
    set index 0
    foreach SUBJECT  $SelectedSubjectList {
        $f.fSelect.mbSubject.m.m$i add command -label $SUBJECT -command "set ::Validation(Subject) $SUBJECT; $f.fSelect.mbSubject configure -text $SUBJECT"
        incr index
    }
    }

    eval {button $f.bLoad -text "Load Subject" -width 16 -command "ValidationLoadSubject"} $::Gui(WBA)  
    eval {label $f.lText -text "Do not close the window otherwise you \nhave to restart slicer to load a subject !" } $::Gui(WTA)   
    pack $f.bLoad $f.lText -side top -padx 4 -pady 4
}


#puts "=== Start Setup Validation View ==="
# ValidationSelectWindow
# puts "=== Finished Setup Validation View ==="

