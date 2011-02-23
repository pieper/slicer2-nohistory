#=auto==========================================================================
# (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
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
# FILE:        IbrowserLoadGUI.tcl
# PROCEDURES:  
#   IbrowserUpdateNewTab
#   IbrowserBuildUIForImport
#   IbrowserBuildUIForAppend
#   IbrowserBuildUIForAssemble
#   IbrowserAssembleSequence
#   IbrowserAssembleSequenceFromFiles
#   IbrowserAssembleSequenceFromSequences
#   IbrowserUpdateMultiVolumeReader
#   IbrowserAssembleSequenceFromVolumes
#   IbrowserCancelAssembleSequence
#   IbrowserAddVolumeToSequenceList
#   IbrowserSelectVolumeForSequenceList
#   IbrowserBuildUIForLoad
#   IbrowserMultiVolumeReaderBuildGUI
#   IbrowserUpdateSequences
#   IbrowserImportSequenceFromOtherModule
#   IbrowserMultiVolumeReaderLoad
#==========================================================================auto=
#-------------------------------------------------------------------------------
proc IbrowserBuildLoadFrame { } {
    global Gui Module Volume
    

    set fNew $::Module(Ibrowser,fNew)
    bind $::Module(Ibrowser,bNew) <ButtonPress-1> "IbrowserUpdateNewTab"
    set f $fNew
    #---------------------------------------------------------------
    #--- fNew (packer)
    #---------------------------------------------------------------
    frame $f.fOption -bg $Gui(activeWorkspace) 
    frame $f.fLogos -bg $Gui(activeWorkspace) -bd 3
    grid $f.fOption -row 0 -column 0 -sticky ew
    grid $f.fLogos -row 1 -column 0 -sticky ew

    #------------------------------
    # fNew->Option frame
    #------------------------------
    set f $fNew.fOption


    #---
    #--- create notebook frames for stages of keyframe interpolation
    if { [catch "package require BLT" ] } {
        DevErrorWindow "Must have the BLT package installed to generate keyframe registration interface."
        return
    }
    
    #--- create blt notebook
    blt::tabset $f.tsNotebook -relief flat -borderwidth 0
    pack $f.tsNotebook -side top

    #--- notebook configure
    $f.tsNotebook configure -width 250
    $f.tsNotebook configure -height 340
    $f.tsNotebook configure -background $::Gui(activeWorkspace)
    $f.tsNotebook configure -activebackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -selectbackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -tabbackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -highlightbackground $::Gui(activeWorkspace)
    $f.tsNotebook configure -highlightcolor $::Gui(activeWorkspace)
    $f.tsNotebook configure -foreground black
    $f.tsNotebook configure -activeforeground black
    $f.tsNotebook configure -selectforeground black
    $f.tsNotebook configure -tabforeground black
    $f.tsNotebook configure -relief flat
    $f.tsNotebook configure -tabrelief raised

    #--- tab configure
    set i 0
    foreach t "Load Assemble" {
        $f.tsNotebook insert $i $t
        frame $f.tsNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        IbrowserBuildUIFor${t} $f.tsNotebook.f$t

        $f.tsNotebook tab configure $t -window $f.tsNotebook.f$t 
        $f.tsNotebook tab configure $t -activebackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -selectbackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -background $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -fill both -padx $::Gui(pad) -pady $::Gui(pad)
        incr i
    }

    #--- WJP comment out during development
    #set w [ Notebook:frame $f.fNotebook Append ]
    #IbrowserBuildUIForAppend $w
    #--- Import a sequence from elsewhere in Slicer
    #set w [ Notebook:frame $f.fNotebook Import ]
    #IbrowserBuildUIForImport $w

    #---------------------------------------------------------------
    #--- fNew->fLogos (packer)
    #---------------------------------------------------------------
    #--- Make the top frame for displaying
    #--- logos from BIRN, SPL and HCNR
    set f $fNew.fLogos

    set uselogo [image create photo -file $::Ibrowser(modulePath)/logos/LogosForIbrowser.gif]
    eval {label $f.lLogoImages -width 200 -height 45 \
              -image $uselogo -justify center} $Gui(BLA)
    pack $f.lLogoImages -side bottom -padx 2 -pady 1 -expand 0
}

#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateNewTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateNewTab { } {

    set ::Ibrowser(currentTab) "New"
}




#-------------------------------------------------------------------------------
# .PROC IbrowserBuildUIForImport
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildUIForImport { parent } {
       global Gui

    frame $parent.fTop    -bg $Gui(activeWorkspace) 
    frame $parent.fMiddle -bg $Gui(activeWorkspace) 
    frame $parent.fBottom -bg $Gui(activeWorkspace) 
    pack $parent.fTop $parent.fMiddle -side top -padx $Gui(pad) 
    pack $parent.fBottom -side top -pady 15 
    
    #--- Frame for Sequence listbox
    set f $parent.fTop
    DevAddLabel $f.l "Available sequences:"
    listbox $f.lb -height 3 -bg $Gui(activeWorkspace) 
    set ::Ibrowser(seqsListBox) $f.lb
    pack $f.l $f.lb -side top -pady $Gui(pad)   

    #--- Frame for Sequence listbox buttons
    set f $parent.fMiddle
    DevAddButton $f.bImport "Import" "IbrowserImportSequenceFromOtherModule" 10 
    DevAddButton $f.bUpdate "Update" "IbrowserUpdateSequences" 10 
    pack $f.bUpdate $f.bImport -side left -expand 1 -pady $Gui(pad) -padx $Gui(pad) -fill both

    #--- Frame for previewing new sequence
    set f $parent.fBottom

    DevAddLabel $f.lVolNo "Volume:"
    eval { scale $f.sSlider \
               -orient horizontal \
               -from 0 -to $::Ibrowser(MaxDrops) \
               -resolution 1 \
               -bigincrement 10 \
               -length 130 \
               -state disabled \
               -variable ::Ibrowser(ViewDrop) } $Gui(WSA) {-showvalue 1}

    set ::Ibrowser(selectSlider) $f.sSlider
     bind $f.sSlider <ButtonPress-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $f.sSlider <ButtonRelease-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $f.sSlider <B1-Motion> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    TooltipAdd $f.sSlider \
        "Slide this scale to preview sequence of volumes."
 
    #The "sticky" option aligns items to the left (west) side
    grid $f.lVolNo -row 0 -column 0 -padx 1 -pady 1 -sticky w
    grid $f.sSlider -row 0 -column 1 -padx 1 -pady 1 -sticky w

}




#-------------------------------------------------------------------------------
# .PROC IbrowserBuildUIForAppend
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildUIForAppend { parent } {
       global Gui

    frame $parent.fTop    -bg $Gui(activeWorkspace) 
    frame $parent.fMiddle -bg $Gui(activeWorkspace) 
    frame $parent.fBottom -bg $Gui(activeWorkspace) 
    pack $parent.fTop $parent.fMiddle -side top -padx $Gui(pad) 
    pack $parent.fBottom -side top -pady 15 

    # let top hold the persistent label
    set f $parent.fTop
    set f $parent.fMiddle
    set f $parent.fBottom
}


#-------------------------------------------------------------------------------
# .PROC IbrowserBuildUIForAssemble
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildUIForAssemble { parent } {
       global Gui

    frame $parent.fChoose -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $parent.fAssembleFrom -bg $Gui(activeWorkspace) -relief groove -bd 2 -height 70
    frame $parent.fApply -bg $Gui(activeWorkspace) 
    pack $parent.fChoose -side top -padx $Gui(pad) -fill x
    pack $parent.fAssembleFrom -side top -padx $Gui(pad) -fill x
    pack $parent.fApply -side top -pady 5 -fill x

    #----------------- CHOOSE ---------------------------------
    #--- Create the persistent label and radiobutton select menu
    #--- in the top fChoose frame
    set f $parent.fChoose
    DevAddLabel $f.lNote "Assemble new sequence from:             "
    pack $f.lNote -side top -pady 2 -padx 10 -anchor w
    eval {radiobutton $f.r1 -width 27 -text {selected files on disk} \
              -variable ::Ibrowser(New,assembleChoice) -value 0 \
              -relief flat -offrelief flat -overrelief raised -state disabled\
              -command "raise $parent.fAssembleFrom.fFiles" \
              -selectcolor white} $Gui(WEA)
    pack $f.r1 -side top -pady 2 -padx 10 -anchor w

    eval {radiobutton $f.r2 -width 27 -text {selected Slicer sequences} \
              -variable ::Ibrowser(New,assembleChoice) -value 1 \
              -relief flat -offrelief flat -overrelief raised -state disabled \
              -command "raise $parent.fAssembleFrom.fSequences" \
              -selectcolor white} $Gui(WEA)
    pack $f.r2 -side top -pady 2 -padx 10 -anchor w

    eval {radiobutton $f.r3 -width 27 -text {selected Slicer volumes} \
              -variable ::Ibrowser(New,assembleChoice) -value 2 \
              -relief flat -offrelief flat -overrelief raised \
              -command "raise $parent.fAssembleFrom.fVolumes" \
        -selectcolor white} $Gui(WEA)
    pack $f.r3 -side top -pady 2 -padx 10 -anchor w

    #----------------- ASSEMBLE FROM ------------------------
    #--- Create sequence assembly frames that all
    #--- load into the same master frame, depending on
    #--- the chosen type of assembly.
    set f $parent.fAssembleFrom
    frame $f.fFiles -bg $Gui(activeWorkspace)
    frame $f.fSequences -bg $Gui(activeWorkspace)
    frame $f.fVolumes -bg $Gui(activeWorkspace) 
    
    #--- Populate the assembly frames.
    #--- Assemble from selected files on disk:
    #------------------------------------------------------------------------
    set f $parent.fAssembleFrom.fFiles
    DevAddLabel $f.lNote "(option not yet supported)"
    pack $f.lNote -side top -pady 2 -padx 10
    frame $f.fSelectFiles -bg $Gui(activeWorkspace)
    pack $f.fSelectFiles -side top -pady 2 -anchor w
    #--- put things in the frame: select volume button, add button, and listbox.
    set f $f.fSelectFiles
    DevAddButton $f.bFiles "file browse" "" 20 
    DevAddButton $f.bAdd "add" "" 7
    pack $f.bFiles -pady 2 -padx 2 -side left -anchor n 
    pack $f.bAdd -side left -padx 5 -pady 2 -anchor n
    raise $f

    #------------------------------------------------------------------------
    
    
    #--- Assemble from selected Slicer sequences:
    #------------------------------------------------------------------------
    set f $parent.fAssembleFrom.fSequences
    DevAddLabel $f.lNote "(option not yet supported)"
    pack $f.lNote -side top -pady 2 -padx 10
    frame $f.fSelectSequences -bg $Gui(activeWorkspace)
    pack $f.fSelectSequences -side top -pady 2 -anchor w
    #--- put things in the frame: select volume button, add button, and listbox.
    set f $f.fSelectSequences
    eval { menubutton $f.mbSequences -text "select sequence" -width 20 -relief raised \
               -height 1 -menu $f.mbSequences.m -bg $Gui(activeWorkspace) -indicatoron 1 } $Gui(WBA)
    eval { menu $f.mbSequences.m } $Gui(WMA)
    foreach id $::Ibrowser(idList) {
        if { $id != 0 } {
            $f.mbSequences.m add command -label $::Ibrowser($id,name)  \
                -command ""
        }
    }
    set ::Ibrowser(New,mbAssembleSequences) $f.mbSequences
    set ::Ibrowser(New,mAssembleSequences) $f.mbSequences.m
    eval { button $f.bAdd -text "add" -width 7 -height 1 \
              -command "" } $Gui(WBA)
    pack $f.mbSequences -pady 2 -padx 2 -side left -anchor n -ipady 1
    pack $f.bAdd -side left -padx 5 -pady 2 -anchor n

    #------------------------------------------------------------------------

    
    #--- Assemble from selected Slicer volumes:
    #------------------------------------------------------------------------
    set f $parent.fAssembleFrom.fVolumes
    DevAddLabel $f.lNote "(select volume, add, & repeat until done)"
    pack $f.lNote -side top -pady 2 -padx 10
    frame $f.fSelectVolumes -bg $Gui(activeWorkspace)
    pack $f.fSelectVolumes -side top -pady 2 -anchor w
    #--- put things in the frame: select volume button, add button, and listbox.
    set f $f.fSelectVolumes
    eval { menubutton $f.mbVolumes -text "select volume" -width 20 -relief raised \
               -height 1 -menu $f.mbVolumes.m -bg $Gui(activeWorkspace) -indicatoron 1 } $Gui(WBA)
    TooltipAdd $f.mbVolumes "Select a volume from a list."
    eval { menu $f.mbVolumes.m } $Gui(WMA)
    foreach v $::Volume(idList) {
        if { $v != 0 } {
            $f.mbVolumes.m add command -label [::Volume($v,node) GetName ] \
                -command "IbrowserSelectVolumeForSequenceList $v"
        }
    }
    set ::Ibrowser(New,mbAssembleVolume) $f.mbVolumes
    set ::Ibrowser(New,mAssembleVolume) $f.mbVolumes.m
    eval { button $f.bAdd -text "add" -width 7 -height 1 \
              -command "IbrowserAddVolumeToSequenceList" } $Gui(WBA)
    TooltipAdd $f.bAdd "Add selected volume to the list of volumes for the interval."
    pack $f.mbVolumes -pady 2 -padx 2 -side left -anchor n -ipady 1
    pack $f.bAdd -side left -padx 5 -pady 2 -anchor n

    #------------------------------------------------------------------------
    #--- Place all assembly frames in the same master frame.
    #--- assembleFrom has a height of 70.
    set f $parent.fAssembleFrom
    place $f.fFiles -in $f -relwidth 1.0 -relheight 1.0
    place $f.fSequences -in $f -relwidth 1.0 -relheight 1.0    
    place $f.fVolumes -in $f -relwidth 1.0 -relheight 1.0


    #-------------------- APPLY ---------------------------------
    #--- whether we're selecting volumes, sequences or files
    #--- list them in this box as they're added, and provide
    #--- apply and cancel buttons.
    
    set f $parent.fApply
    frame $f.fListBox -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    pack $f.fListBox -side left -padx 2
    pack $f.fButtons -side left -padx 2

    set f $parent.fApply.fListBox
    eval { scrollbar $f.scroll -command "$f.lbVolumes yview" }
    eval { listbox $f.lbVolumes -bg $Gui(normalButton) -font {helvetica 8 } \
               -fg $Gui(textDark) -width 25 -yscrollcommand "$f.scroll set"}
    set ::Ibrowser(New,lbAssemble) $f.lbVolumes
    pack $f.lbVolumes -padx 2 -side left
    pack $f.scroll -padx 0 -side right -fill y

    set f $parent.fApply.fButtons
    DevAddButton $f.bApply "apply" "IbrowserAssembleSequence" 7
    TooltipAdd $f.bApply "Create a new interval containing these volumes, in designated order."
    DevAddButton $f.bCancel "cancel" "IbrowserCancelAssembleSequence" 7
    TooltipAdd $f.bCancel "Cancel the creation of a new interval using the selected volumes."
    pack $f.bApply -side top -anchor nw -pady 2
    pack $f.bCancel -side top -anchor nw -pady 2

}

#-------------------------------------------------------------------------------
# .PROC IbrowserAssembleSequence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAssembleSequence { } {

    if { $::Ibrowser(New,assembleChoice) == 0 } {
        IbrowserAssembleSequenceFromFiles
    } elseif { $::Ibrowser(New,assembleChoice) == 1 } {
        IbrowserAssembleSequenceFromSequences
    } elseif { $::Ibrowser(New,assembleChoice) == 2 } {
        IbrowserAssembleSequenceFromVolumes
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserAssembleSequenceFromFiles
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAssembleSequenceFromFiles { } {
}

#-------------------------------------------------------------------------------
# .PROC IbrowserAssembleSequenceFromSequences
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAssembleSequenceFromSequences { } {
}



#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateMultiVolumeReader
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateMultiVolumeReader { iname iid } {

    #--- register the sequence with the MultiVolumeReader so fMRIEngine can see the sequence
    lappend ::MultiVolumeReader(sequenceNames) $iname
    set ::MultiVolumeReader($iname,noOfVolumes) $::Ibrowser($iid,numDrops)
    set ::MultiVolumeReader($iname,firstMRMLid) $::Ibrowser($iid,firstMRMLid)
    set ::MultiVolumeReader($iname,lastMRMLid) $::Ibrowser($iid,lastMRMLid)
    set id $::Ibrowser($iid,firstMRMLid)
    #--- assuming that all volumes in the interval contain the same extent.
    set ::MultiVolumeReader($iname,volumeExtent) [ [ ::Volume($id,vol) GetOutput ] GetExtent ]
    set ::MultiVolumeReader(sequenceName) ""
    set ::MultiVolumeReader(filter) ""
    set ::Volume(name) ""
    
}




#-------------------------------------------------------------------------------
# .PROC IbrowserAssembleSequenceFromVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAssembleSequenceFromVolumes { } {
    IbrowserRaiseProgressBar

    if { $::Ibrowser(New,assembleList) == "" } {
        DevErrorWindow "No volumes have been selected."
        return
    }

    #--- register this with the multiVolumeReader so fMRIEngine can see sequence
    set ivalID $::Ibrowser(uniqueNum)
    if { [info exists ::MultiVolumeReader(defaultSequenceName)] } {
        incr ::MultiVolumeReader(defaultSequenceName)
    } else {
        set ::MultiVolumeReader(defaultSequenceName) 1
    }

    #--- get the interval started
    set mmID $::MultiVolumeReader(defaultSequenceName)
    set ::Ibrowser(loadVol,name) [format "multiVol%d" $mmID]
    set iname $::Ibrowser(loadVol,name)
    set ::Ibrowser($ivalID,name) $iname
    set ::Ibrowser($iname,intervalID) $ivalID

    #--- get the list of volumeIDs
    #--- how many entries are in the list?
    if { [info exists ::Ibrowser(New,assembleList) ] } {
        set numVols [ llength $::Ibrowser(New,assembleList) ]
        #--- create $numVols new MRMLVolumenodes
        for {set i 0} { $i < $numVols } { incr i } {
            set node [MainMrmlAddNode Volume ]
            lappend tmpList  $node 
        }

        #--- copy one selected volume into each new node
        set i 0
        foreach sID $::Ibrowser(New,assembleList) {
            #--- destin: get new MRMLid out of tmpIDList 
            #--- source: get Volume from list of selected
            #--- copy source to destination.
            set newvol [ lindex $tmpList $i ]
            set dstID [$newvol GetID ]
            $newvol Copy Volume($sID,node)
            MainVolumesCreate $dstID
            MainVolumesCopyData $dstID $sID Off
            #--- create a volume name.
            $newvol SetName ${iname}_${i}
            #--- add new mrml volume id to interval's idlist
            set ::Ibrowser($ivalID,$i,MRMLid) $dstID
            incr i
        }

        #--- set first and last MRMLids in the interval
        #--- and make a new Interval to hold volumes
        set ::Ibrowser($ivalID,firstMRMLid) [ [lindex $tmpList 0] GetID ]
        set ::Ibrowser($ivalID,lastMRMLid) [ [lindex $tmpList end] GetID ]
        set spanmax [ expr $numVols - 1 ]
        IbrowserMakeNewInterval $iname $::IbrowserController(Info,Ival,imageIvalType) \
            0.0 $spanmax $numVols

        #--- update multivolumereader to reflect this multi-volume sequence
        IbrowserUpdateMultiVolumeReader $iname $ivalID
    }

    #--- empty assembleList
    set ::Ibrowser(New,assembleList) ""
    #--- configure assembleListbox
    $::Ibrowser(New,lbAssemble) delete 0 end
    #--- reset queued volume
    set ::Ibrowser(New,selectedVolumeID) ""
    #--- reset select menubutton
    $::Ibrowser(New,mbAssembleVolume) config -text "select volume"

    IbrowserLowerProgressBar

}

#-------------------------------------------------------------------------------
# .PROC IbrowserCancelAssembleSequence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCancelAssembleSequence { } {

    #--- empty assembleList
    set ::Ibrowser(New,assembleList) ""
    #--- configure assembleListbox
    $::Ibrowser(New,lbAssemble) delete 0 end
    #--- reset queued volume
    set ::Ibrowser(New,selectedVolumeID) ""
    #--- reset select menubutton
    $::Ibrowser(New,mbAssembleVolume) config -text "select volume"

}


#-------------------------------------------------------------------------------
# .PROC IbrowserAddVolumeToSequenceList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddVolumeToSequenceList { } {

    if { $::Ibrowser(New,selectedVolumeID) != ""} {
        #--- get id and name
        set id $::Ibrowser(New,selectedVolumeID)
        set vname  [ ::Volume($id,node) GetName ] 

        #--- add ID to assembleList
        lappend ::Ibrowser(New,assembleList) $id
        #--- add name to assembleListbox
        $::Ibrowser(New,lbAssemble) insert end $vname

        #--- reset queued volume
        set ::Ibrowser(New,selectedVolumeID) ""
        #--- reset select menubutton
        $::Ibrowser(New,mbAssembleVolume) config -text "select volume"
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserSelectVolumeForSequenceList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSelectVolumeForSequenceList { id } {

    #--- modify menu button
    set vname  [ ::Volume($id,node) GetName ] 
    $::Ibrowser(New,mbAssembleVolume) config -text $vname
    #--- queue the volume for adding 
    set ::Ibrowser(New,selectedVolumeID) $id

}


#-------------------------------------------------------------------------------
# .PROC IbrowserBuildUIForLoad
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildUIForLoad { parent } {
        global Gui

    frame $parent.fTop -bg $Gui(activeWorkspace)
    pack $parent.fTop -side top 
 
    set f $parent.fTop

    # error if no private segment
    if {[catch "package require MultiVolumeReader"]} {
        DevAddLabel $f.lError \
            "Loading function is disabled\n\
            due to the unavailability\n\
            of module MultiVolumeReader." 
        pack $f.lError -side top -pady 30
        return
    }
    #--- This is slightly different from MultiVolumeReader's GUI
    IbrowserMultiVolumeReaderBuildGUI $f 1
    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMultiVolumeReaderBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMultiVolumeReaderBuildGUI {parent {status 0}} {
    global Gui MultiVolumeReader Module Volume Model


    frame $parent.fReaderConfig -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $parent.fVolumeNav -bg $Gui(activeWorkspace)
    pack $parent.fReaderConfig $parent.fVolumeNav -side top -pady 3
    
    #--- reader configuration
    set f $parent.fReaderConfig
    frame $f.fLabel -bg $Gui(activeWorkspace)
    frame $f.fFile -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fApply -bg $Gui(activeWorkspace) -bd 3
    frame $f.fStatus -bg $Gui(activeWorkspace) -bd 3
    pack $f.fLabel $f.fFile $f.fApply $f.fStatus -side top -pady 1

    set f $parent.fReaderConfig.fLabel
    DevAddLabel $f.lLabel "Configure the multi-volume reader:"
    pack $f.lLabel -side top -pady 2
    
    set f $parent.fReaderConfig.fFile
    DevAddFileBrowse $f MultiVolumeReader "fileName" "File from load dir:" \
        "MultiVolumeReaderSetFileFilter" "bxh .dcm .hdr" \
        "\$Volume(DefaultDir)" "Open" "Browse for a volume file" "" "Absolute"
    frame $f.fSingle -bg $Gui(activeWorkspace)
    frame $f.fMultiple -bg $Gui(activeWorkspace) -relief groove -bd 1
    frame $f.fName -bg $Gui(activeWorkspace)
    pack $f.fSingle $f.fMultiple $f.fName -side top -pady 1

   set f $parent.fReaderConfig.fFile.fSingle
    eval {radiobutton $f.r1 -width 27 -text {Load a single file} \
        -variable MultiVolumeReader(fileChoice) -value single \
        -relief flat -offrelief flat -overrelief raised \
        -selectcolor white} $Gui(WEA)
    grid $f.r1  -padx 1 -pady 3 -sticky w

    set f $parent.fReaderConfig.fFile.fMultiple
    eval {radiobutton $f.r2 -width 27 -text {Load multiple files} \
        -variable MultiVolumeReader(fileChoice) -value multiple \
        -relief flat -offrelief flat -overrelief raised \
        -selectcolor white} $Gui(WEA)

    DevAddLabel $f.lFilter " Filter:"
    eval {entry $f.eFilter -width 25 \
        -textvariable MultiVolumeReader(filter)} $Gui(WEA)

    #The "sticky" option aligns items to the left (west) side
    grid $f.r2 -row 0 -column 0 -columnspan 2 -padx 5 -pady 3 -sticky w
    grid $f.lFilter -row 1 -column 0 -padx 1 -pady 3 -sticky w
    grid $f.eFilter -row 1 -column 1 -padx 1 -pady 3 -sticky w

    set MultiVolumeReader(filterChoice) single
    set MultiVolumeReader(singleRadiobutton) $f.r1
    set MultiVolumeReader(multipleRadiobutton) $f.r2
    set MultiVolumeReader(filterEntry) $f.eFilter

    if {$status == 1} {
        set f $parent.fReaderConfig.fFile.fName
        DevAddLabel $f.lName "Sequence name:"
        eval { entry $f.eName -width 16 \
                   -textvariable MultiVolumeReader(sequenceName)} $Gui(WEA)
        bind $f.eName <Return> "IbrowserMultiVolumeReaderLoad $status"
        grid $f.lName $f.eName -padx 3 -pady 3 -sticky w
    }

    set f $parent.fReaderConfig.fApply
    DevAddButton $f.bApply "Apply" "IbrowserMultiVolumeReaderLoad $status" 12 
    pack $f.bApply -side top -pady 5 

    set f $parent.fReaderConfig.fStatus
    frame $f.fVName -bg $Gui(activeWorkspace)
    pack $f.fVName  -pady 5
    set f $f.fVName 
    DevAddLabel $f.lVName1 "volume:"

    set Volume(name) ""
    eval {label $f.lVName2 -width 30 -relief flat \
        -textvariable Volume(name) } $Gui(WEA)

    pack $f.lVName1 $f.lVName2 -side left -padx $Gui(pad) -pady 0 

    # The Navigate frame
    set f $parent.fVolumeNav

    #--- for now; need to create MultiVolumeReader(slider) but don't
    #--- want to do anything with it.
    DevAddLabel $f.lVolNo "Volume index:"
    eval { scale $f.sSlider \
               -orient horizontal \
               -from 0 -to $::Ibrowser(MaxDrops) \
               -resolution 1 \
               -bigincrement 10 \
               -length 130 \
               -state disabled \
               -variable ::Ibrowser(ViewDrop) } $Gui(WSA) {-showvalue 1}
    set ::Ibrowser(loadSlider) $f.sSlider
    bind $f.sSlider <ButtonPress-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $f.sSlider <ButtonRelease-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $f.sSlider <B1-Motion> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    TooltipAdd $f.sSlider \
        "Slide this scale to navigate multi-volume sequence."
 
    #The "sticky" option aligns items to the left (west) side
    grid $f.lVolNo -row 0 -column 0 -padx 1 -pady 0 -sticky w
    grid $f.sSlider -row 0 -column 1 -padx 1 -pady 0 -sticky w
}




#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateSequences
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateSequences { } {
    global MultiVolumeReader 

    # clears the listbox
    set size [$::Ibrowser(seqsListBox) size]
    $::Ibrowser(seqsListBox) delete 0 [expr $size - 1]
 
    # lists all sequence loaded from Ibrowser
    set b1 [info exists ::Ibrowser(idList)]
    set n1 [expr {$b1 == 0 ? 0 : [llength $::Ibrowser(idList)]}]
    # lists all sequences loaded from other modules
    set b2 0
    set n2 0
    
    set n [expr $n1 + $n2 ]
    if {$n > 1} {
        set i 1 
        while {$i < $n1} {
            set id [lindex $::Ibrowser(idList) $i]
            $::Ibrowser(seqsListBox) insert end "$::Ibrowser($id,name)" 
            incr i
        }
        if {$n2 > 1} {
            $::Ibrowser(seqsListBox) insert end "Elsewhere-in-Slicer" 
        }
    } else {
        $::Ibrowser(seqsListBox) insert end none 
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserImportSequenceFromOtherModule
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserImportSequenceFromOtherModule { } {
    global MultiVolumeReader

    set ci [$::Ibrowser(seqsListBox) cursel]
    set size [$::Ibrowser(seqsListBox) size]

    if {[string length $ci] == 0} {
        if {$size > 1} {
            DevErrorWindow "Please select a sequence."
            return
        } else {
            set ci 0 
        }
    }

    set cc [$::Ibrowser(seqsListBox) get $ci]
    set l [string trim $cc]

    if {$l == "none"} {
        DevErrorWindow "No sequence available."
        return
    } else {
        #--- for now, just bring this interval to the BG and make active.
        #--- make this the active interval.
        #--- display the first volume
        #--- make it the active volume
        #--- and put it in the background
        #--- as is the loading convention.
        set id $::Ibrowser($l,intervalID)
        IbrowserDeselectActiveInterval $::IbrowserController(Icanvas)
        IbrowserDeselectFGIcon $::IbrowserController(Icanvas)

        IbrowserSetActiveInterval $id
        IbrowserSlicesSetVolumeAll Back $::Ibrowser($id,0,MRMLid) 

        #--- let Ibrowser set viewer background layer.
        set ::Ibrowser(BGInterval) $id
        IbrowserSelectBGIcon $id $::IbrowserController(Icanvas)

        MainVolumesSetActive $::Ibrowser($id,0,MRMLid)
        #MainSlicesSetVisibilityAll 1
        RenderAll
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserMultiVolumeReaderLoad
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMultiVolumeReaderLoad { status } {

    set readfailure [ MultiVolumeReaderLoad $status ]
    if { $readfailure } {
        return
    }

    set id $::Ibrowser(uniqueNum)
    set first $::MultiVolumeReader(firstMRMLid)
    set last $::MultiVolumeReader(lastMRMLid)

    set mmID $::MultiVolumeReader(defaultSequenceName)
    set ::Ibrowser(loadVol,name) [format "multiVol%d" $mmID]
    set iname $::Ibrowser(loadVol,name)
    
    set vcount 0
    #--- give ibrowser a way to refer to each vol
    #--- and rename each volume...
    set new $iname
    for {set i $first } { $i <= $last } { incr i } {
        set ::Ibrowser($id,$vcount,MRMLid) $i
        set old [ ::Volume($i,node) GetName ]
        ::Volume($i,node) SetName ${old}_${iname}
        incr vcount
    }

    #--- set first and last MRML ids in the interval,
    #--- and create new interval in the controller.
    set ::Ibrowser($id,firstMRMLid) $first
    set ::Ibrowser($id,lastMRMLid) $last
    set m $::MultiVolumeReader(noOfVolumes)
    set spanmax [ expr $m - 1 ]
    IbrowserMakeNewInterval $iname $::IbrowserController(Info,Ival,imageIvalType) 0.0 $spanmax $m
        #--- for feeback...
    set ::Volume(name) ""
    set ::Volume(VolAnalyze,FileName) ""
    IbrowserUpdateMRML
    set ::Ibrowser(BGInterval) $id
    IbrowserSelectBGIcon $id $::IbrowserController(Icanvas)
}

