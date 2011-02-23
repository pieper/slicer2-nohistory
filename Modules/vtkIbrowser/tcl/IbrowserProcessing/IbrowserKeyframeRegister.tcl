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
# FILE:        IbrowserKeyframeRegister.tcl
# PROCEDURES:  
#   IbrowserBuildKeyframeRegisterGUI
#   IbrowserBuildKeyframeRegisterKeyframesGUI
#   IbrowserUpdateKeyframeRegisterGUI
#   IbrowserUpdateKeyframeRegisterReference
#   IbrowserKeyframeClearAllKeyframes
#   IbrowserBuildKeyframeRegisterInterpolateGUI
#   IbrowserAddKeyframeToList
#   IbrowserDeleteKeyframes
#   IbrowserDeleteAllKeyframes
#   IbrowserKeyframePutReferenceInBG
#   IbrowserKeyframeShowKeyframeAndReference
#   IbrowserKeyframeLoadMatrix
#   IbrowserKeyframesMatrixSetActive
#   IbrowserKeyframesSetMatrix
#   IbrowserKeyframeInterpolateAll
#   IbrowserKeyframeUndoInterpolate
#   IbrowserKeyframeResetAllTransforms
#   IbrowserKeyframeDeleteAllTransforms
#   IbrowserHelpKeyframeRegister
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildKeyframeRegisterGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildKeyframeRegisterGUI { f master } {
    global Gui
    #---
    #--- set global variables for frame so we can raise it.
    set ::Ibrowser(fProcessKeyframeRegister) $f


    #---
    #--- set some globals for this process.
    set ::Ibrowser(Process,KeyframeRegister,volumeMatrix) None
    set ::Ibrowser(Process,KeyframeRegister,mouse) "translate"
    set ::Ibrowser(Process,KeyframeRegister,xHome) 0
    set ::Ibrowser(Process,KeyframeRegister,yHome) 0
    set ::Ibrowser(Process,KeyframeRegister,prevTranLR) 0.00
    set ::Ibrowser(Process,KeyframeRegister,prevTranPA) 0.00    
    set ::Ibrowser(Process,KeyframeRegister,prevTranIS) 0.00
    set ::Ibrowser(Process,KeyframeRegister,regTranLR) 0.00
    set ::Ibrowser(Process,KeyframeRegister,regTranPA) 0.00    
    set ::Ibrowser(Process,KeyframeRegister,regTranIS) 0.00
    set ::Ibrowser(Process,KeyframeRegister,rotAxis) "XX"
    set ::Ibrowser(Process,KeyframeRegister,regRotLR) 0.00
    set ::Ibrowser(Process,KeyframeRegister,regRotIS) 0.00
    set ::Ibrowser(Process,KeyframeRegister,regRotPA) 0.00    
    set ::Ibrowser(Process,KeyframeRegister,refCoordinate) "Pre"
    set ::Ibrowser(Process,InternalReference) $::Volume(idNone)
    set ::Ibrowser(Process,ExternalReference) $::Volume(idNone)
    set ::Ibrowser(Process,KeyframeRegister,render) All
    set ::Ibrowser(Process,Matrix,rows) {0 1 2 3}
    set ::Ibrowser(Process,Matrix,cols) {0 1 2 3}
    set ::Ibrowser(Process,KeyframeRegister,eventManager) ""

    frame $f.fOverview -bg $Gui(activeWorkspace) -bd 2 
    pack $f.fOverview -side top

    set ff $f.fOverview
    DevAddButton $ff.bHelp "?" "IbrowserHelpKeyframeRegister" 2 
    eval { label $ff.lOverview -text \
               "Specify keyframed registration." } $Gui(WLA)
    grid $ff.bHelp $ff.lOverview -pady 1 -padx 1 -sticky w

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
    $f.tsNotebook configure -height 320
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
    foreach t "Keyframes Interpolate" {
        $f.tsNotebook insert $i $t
        frame $f.tsNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        IbrowserBuildKeyframeRegister${t}GUI $f.tsNotebook.f$t
        $f.tsNotebook tab configure $t -window $f.tsNotebook.f$t  
        $f.tsNotebook tab configure $t -activebackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -selectbackground $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -background $::Gui(activeWorkspace)
        $f.tsNotebook tab configure $t -fill both -padx $::Gui(pad) -pady $::Gui(pad)
        incr i
    }


    #--- Place the KeyframeRegister GUI in the
    #--- process-specific raised GUI panel.
    place $f -in $master -relheight 1.0 -relwidth 1.0

    
}




#-------------------------------------------------------------------------------
# .PROC IbrowserBuildKeyframeRegisterKeyframesGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildKeyframeRegisterKeyframesGUI { nf } {
    global Gui
    
    frame $nf.fInput -bg $Gui(activeWorkspace) -bd 2 
    frame $nf.fKeyframes -bg $Gui(activeWorkspace) -bd 2 -relief groove
    frame $nf.fKeyframeList -bg $Gui(activeWorkspace) -bd 2 -relief groove
    #---
    #---CHOOSE VOLUMES FRAME
    #--- create menu buttons and associated menus...
    set ff $nf.fInput
    eval { label $ff.lChooseProcInterval -text "interval:" } $Gui(WLA)
    eval { menubutton $ff.mbIntervals -text "none" \
               -relief raised -bd 2 -width 14 \
               -menu $ff.mbIntervals.m -indicatoron 1 } $::Gui(WMBA)
    eval { menu $ff.mbIntervals.m } $::Gui(WMA)
    foreach i $::Ibrowser(idList) {
        $ff.mbIntervals.m add command -label $::Ibrowser($i,name) 
    }
    TooltipAdd $ff.mbIntervals \
        "Select the interval to keyframe register."
    set ::Ibrowser(Process,KeyframeRegister,mbIntervals) $nf.fInput.mbIntervals
    #bind $::Ibrowser(Process,KeyframeRegister,mbIntervals) <ButtonPress-1> "IbrowserUpdateKeyframeRegisterGUI"
    set ::Ibrowser(Process,KeyframeRegister,mIntervals) $nf.fInput.mbIntervals.m
    grid $ff.lChooseProcInterval -row 0 -column 0 -pady 1 -padx $::Gui(pad) -sticky e
    grid $ff.mbIntervals -row 0 -column 1 -pady 1 -padx $::Gui(pad) -sticky e

    DevAddButton $ff.bAddTransforms "add transforms" \
        "IbrowserAddTransforms" 18
    TooltipAdd $ff.bAddTransforms \
        "Creates a transform for each volume in the selected interval."
    grid $ff.bAddTransforms -row 1 -column 1 -pady 1 -padx $::Gui(pad) -sticky w
    
    eval { label $ff.lReference -text "reference:" } $Gui(WLA)
    eval { menubutton $ff.mbReference -text "none" \
               -relief raised -bd 2 -width 14 -indicatoron 1 \
               -menu $ff.mbReference.m } $::Gui(WMBA)
    eval { menu $ff.mbReference.m } $::Gui(WMA)
    foreach i $::Ibrowser(idList) {
        $ff.mbReference.m add command -label $::Ibrowser($i,name) \
    }
    TooltipAdd $ff.mbReference \
        "Select the reference volume for all keyframes."
    set ::Ibrowser(Process,KeyframeRegister,mbReference) $nf.fInput.mbReference
    #bind $::Ibrowser(Process,KeyframeRegister,mbReference) <ButtonPress-1> "IbrowserUpdateKeyframeRegisterReference"
    set ::Ibrowser(Process,KeyframeRegister,mReference) $nf.fInput.mbReference.m
    grid $ff.lReference -row 2 -column 0 -pady 1 -padx $::Gui(pad) -sticky e
    grid $ff.mbReference -row 2 -column 1 -pady 1 -padx $::Gui(pad) -sticky e

    DevAddButton $ff.bUpdateViewer "update viewer" "IbrowserKeyframePutReferenceInBG" 18
    TooltipAdd $ff.bUpdateViewer \
        "Puts reference in BG and keyframe in FG of main viewer."
    grid $ff.bUpdateViewer -row 3 -column 1 -pady 1 -padx $::Gui(pad) -sticky w
    

    #---
    #---SPECIFY KEYFRAMES FRAME 
    set ff $nf.fKeyframes

    DevAddLabel $ff.lSelect "specify keyframes:"
    eval {scale $ff.sKeyframe -orient horizontal -from 0 -to $::Ibrowser(MaxDrops) \
              -resolution 1 -bigincrement 10 -length 125 -state disabled \
              -variable ::Ibrowser(ViewDrop) } $Gui(WSA) {-showvalue 1 }
    set ::Ibrowser(keyframe1Slider) $ff.sKeyframe
    bind $ff.sKeyframe <ButtonPress-1> {
         IbrowserUpdateIndexFromGUI
         IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $ff.sKeyframe <ButtonRelease-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $ff.sKeyframe <B1-Motion> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    eval { button $ff.bAdd -text "add" -width 6 -height 1 \
               -command "IbrowserAddKeyframeToList" } $Gui(WBA)
    TooltipAdd $ff.bAdd \
        "Add selected volume to keyframe list (shown below)."
    grid $ff.lSelect -row 0 -columnspan 2 -sticky n -pady 2 -padx 4
    grid $ff.sKeyframe -row 1 -column 0 -pady 2 -padx 3 -sticky s
    grid $ff.bAdd -row 1 -column 1 -pady 4 -padx 3 -sticky s
    
    #---
    #---  KEYFRAME LIST FRAME
    set ff $nf.fKeyframeList
    DevAddLabel $ff.lSelectToDel "keyframe list:"
    pack $ff.lSelectToDel -anchor nw -pady 2 -padx $Gui(pad)
    eval { scrollbar $ff.sVolumes -command "$ff.lbVolumes yview" }
    eval { listbox $ff.lbVolumes -bg $Gui(normalButton) -font {helvetica 8 } \
               -fg $Gui(textDark) -width 18 -height 5 -yscrollcommand "$ff.sVolumes set"}
    set ::Ibrowser(Process,KeyframeRegister,lbKeyframe1) $ff.lbVolumes
    pack $ff.lbVolumes -padx 2 -pady 1 -side left
    pack $ff.sVolumes -padx 0 -side left -pady 1 -fill y 
    DevAddButton $ff.bDeleteOne "delete" "IbrowserDeleteKeyframes" 8
    DevAddButton $ff.bClearAll "clear all" "IbrowserDeleteAllKeyframes" 8
    TooltipAdd $ff.bDeleteOne \
        "Delete selected keyframe from list."
    TooltipAdd $ff.bClearAll \
        "Delete all keyframes from list."    
    pack $ff.bClearAll -side bottom -pady 1 -padx $Gui(pad)
    pack $ff.bDeleteOne -side bottom -pady 1 -padx $Gui(pad)
    
    #---
    #--- pack notebook frame
    pack $nf.fInput $nf.fKeyframes $nf.fKeyframeList -side top \
        -pady $Gui(pad) -padx $Gui(pad) -fill both        
}




#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateKeyframeRegisterGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateKeyframeRegisterGUI { } {

    if { [info exists ::Ibrowser(Process,KeyframeRegister,mIntervals) ] } {
        #--- configure interval selection menu
        set m $::Ibrowser(Process,KeyframeRegister,mIntervals)
        set mb $::Ibrowser(Process,KeyframeRegister,mbIntervals)
        set mbR $::Ibrowser(Process,KeyframeRegister,mbReference)
        $m delete 0 end
        foreach id $::Ibrowser(idList) {
            $m add command -label $::Ibrowser($id,name) -command "IbrowserSetActiveInterval $id;
                     IbrowserProcessingSelectInternalReference none $::Volume(idNone);
                     $mbR config -text none;
                     IbrowserKeyframeClearAllKeyframes"
        }
    }

}



#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateKeyframeRegisterReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateKeyframeRegisterReference { } {

    if { [info exists ::Ibrowser(Process,KeyframeRegister,mReference) ] } {    
        #--- configure reference selection menu and menubutton
        set m $::Ibrowser(Process,KeyframeRegister,mReference)
        $m delete 0 end
        set id $::Ibrowser(activeInterval)
        if { $id == $::Ibrowser(idNone) } {
            set mb $::Ibrowser(Process,KeyframeRegister,mbReference)
            $mb configure -text $::Ibrowser(${::Ibrowser(idNone)},name)
        } else {
            set mb $::Ibrowser(Process,KeyframeRegister,mbReference)
            set start $::Ibrowser($::Ibrowser(activeInterval),firstMRMLid)
            set stop $::Ibrowser($::Ibrowser(activeInterval),lastMRMLid)
            set count 0
            #---build selections; all volumes in an interval
            set vname "none"
            $m add command -label $vname \
                -command "IbrowserProcessingSelectInternalReference $vname $::Volume(idNone)"
            for { set i $start } { $i <= $stop } { incr i } {
                set vname [ ::Volume($i,node) GetName ]
                $m add command -label $vname \
                    -command "IbrowserProcessingSelectInternalReference $vname $i;
                                         $mb configure -text $vname"
                incr count
            }
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeClearAllKeyframes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeClearAllKeyframes { } {
    unset -nocomplain ::Ibrowser(Process,KeyframeRegister,keyframeIDlist)
    unset -nocomplain ::Ibrowser(Process,KeyframeRegister,keyframeNameList)
    $::Ibrowser(Process,KeyframeRegister,lbKeyframe1) delete 0 end 
    $::Ibrowser(Process,KeyframeRegister,lbKeyframe2) delete 0 end
}



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildKeyframeRegisterInterpolateGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildKeyframeRegisterInterpolateGUI { nf } {
    global Gui
    
    #---------------------------------
    # Transform frame
    #---------------------------------
    frame $nf.fSelect -bg $Gui(activeWorkspace) -bd 2 -relief groove
    pack $nf.fSelect -side top -pady $Gui(pad) -padx $Gui(pad) -fill both
    frame $nf.fSelect.fLabel -bg $Gui(activeWorkspace)
    frame $nf.fSelect.fListbox -bg $Gui(activeWorkspace)
    frame $nf.fSelect.fButton -bg $Gui(activeWorkspace)
    grid $nf.fSelect.fLabel -row 0 -sticky nw
    grid $nf.fSelect.fListbox -row 1 -sticky nw
    grid $nf.fSelect.fButton -row 2 -sticky nw
    
    set ff $nf.fSelect.fLabel
    DevAddLabel $ff.lLabel "select keyframe:"
    pack $ff.lLabel -anchor w -pady 4 -padx 0

    set ff $nf.fSelect.fListbox
    eval { scrollbar $ff.sVolumes -command "$ff.lbVolumes yview" }
    eval { listbox $ff.lbVolumes -bg $Gui(normalButton) -font {helvetica 8 } \
               -fg $Gui(textDark) -width 26 -height 3 -yscrollcommand "$ff.sVolumes set"}
    set ::Ibrowser(Process,KeyframeRegister,lbKeyframe2) $ff.lbVolumes
    pack $ff.lbVolumes -padx 2 -side left -pady 2
    pack $ff.sVolumes -padx 0 -pady 0 -side left -fill y -pady 2
    
    set ff $nf.fSelect.fButton
    DevAddButton $ff.bUpdate "show in viewer" "IbrowserKeyframeShowKeyframeAndReference" 26

    pack $ff.bUpdate -padx 3 -anchor nw 
    TooltipAdd $ff.bUpdate \
        "Puts reference in BG and keyframe in FG."
    DevAddButton $ff.bLoad "load matrix & transform" "IbrowserKeyframeLoadMatrix" 26
    pack $ff.bLoad -padx 3 -anchor nw -pady 2
    TooltipAdd $ff.bLoad \
        "Switches to Alignments module for transforming matrix."
    
    #---------------------------------
    #--- Interpolate Frame
    #---------------------------------
    frame $nf.fApply -bg $Gui(activeWorkspace) -bd 2
    set ff $nf.fApply

    DevAddButton $ff.bApply "interpolate all" "IbrowserKeyframeInterpolateAll" 18
    TooltipAdd $ff.bApply  "Apply rigid transform interpolation to sequence"    
    DevAddButton $ff.bUndo "undo interpolate" "IbrowserKeyframeUndoInterpolate" 18
    TooltipAdd $ff.bUndo  "Reset transforms for all non-keyframe volumes"
    DevAddButton $ff.bReset "reset all transforms" "IbrowserKeyframeResetAllTransforms" 18
    TooltipAdd $ff.bReset  "Reset transforms for all volumes in the sequence (including keyframes)"
    DevAddButton $ff.bDelete "delete all transforms" "IbrowserKeyframeDeleteAllTransforms" 18
    TooltipAdd $ff.bDelete  "Delete transforms for all volumes in the sequence."
    pack $ff.bApply $ff.bUndo $ff.bReset $ff.bDelete -side top \
        -pady 1 -padx $Gui(pad) 

    #--- add a scale for previewing
    eval {scale $ff.sKeyframe -orient horizontal -from 0 -to $::Ibrowser(MaxDrops) \
              -resolution 1 -bigincrement 10 -length 18 -state disabled \
              -variable ::Ibrowser(ViewDrop) } $Gui(WSA) {-showvalue 1 }
    set ::Ibrowser(keyframe2Slider) $ff.sKeyframe
    bind $ff.sKeyframe <ButtonPress-1> {
         IbrowserUpdateIndexFromGUI
         #IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $ff.sKeyframe <ButtonRelease-1> {
        IbrowserUpdateIndexFromGUI
        #IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $ff.sKeyframe <B1-Motion> {
        IbrowserUpdateIndexFromGUI
        #IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    pack $ff.sKeyframe -side top -pady 1 -padx $Gui(pad) -fill x

    #---
    #--- pack notebook frame
    pack $nf.fApply -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

}



#-------------------------------------------------------------------------------
# .PROC IbrowserAddKeyframeToList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddKeyframeToList { } {

    #--- add to keyframeList
    set id $::Ibrowser(activeInterval)
    set volnum $::Ibrowser(ViewDrop)
    set volID $::Ibrowser($id,$volnum,MRMLid)
    
    #--- if list exists, check to see if this volume is already in the list
    #--- before adding it; otherwise, just create list and add volume.
    if { [info exists ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) ] } {
        if { [lsearch $::Ibrowser(Process,KeyframeRegister,keyframeIDlist) $volID] < 0 } {
            lappend ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) $volID
            set vname [ ::Volume($volID,node) GetName ]
             lappend ::Ibrowser(Process,KeyframeRegister,keyframeNameList) $vname
            $::Ibrowser(Process,KeyframeRegister,lbKeyframe1) insert end $vname
            $::Ibrowser(Process,KeyframeRegister,lbKeyframe2) insert end $vname
        }    
    } else {
            lappend ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) $volID
            set vname [ ::Volume($volID,node) GetName ]
             lappend ::Ibrowser(Process,KeyframeRegister,keyframeNameList) $vname
            $::Ibrowser(Process,KeyframeRegister,lbKeyframe1) insert end $vname
            $::Ibrowser(Process,KeyframeRegister,lbKeyframe2) insert end $vname
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteKeyframes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteKeyframes { } {
    #--- remove from lists, and remove from listbox.
    set tokill [ $::Ibrowser(Process,KeyframeRegister,lbKeyframe1) curselection ]
    foreach s $tokill {
        set lst $::Ibrowser(Process,KeyframeRegister,keyframeNameList) 
        set ::Ibrowser(Process,KeyframeRegister,keyframeNameList) [ lreplace $lst $s $s ]

        set lst $::Ibrowser(Process,KeyframeRegister,keyframeIDlist) 
        set ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) [ lreplace $lst $s $s ]

        $::Ibrowser(Process,KeyframeRegister,lbKeyframe1) delete $s $s
        $::Ibrowser(Process,KeyframeRegister,lbKeyframe2) delete $s $s
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteAllKeyframes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteAllKeyframes { } {

    #--- delete lists of keyframes and reset the listbox.
    if { [info exists ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) ] } {
        unset -nocomplain ::Ibrowser(Process,KeyframeRegister,keyframeIDlist)
    }
    if { [info exists ::Ibrowser(Process,KeyframeRegister,keyframeNameList) ] } {
        unset -nocomplain ::Ibrowser(Process,KeyframeRegister,keyframeNameList)
    }
    $::Ibrowser(Process,KeyframeRegister,lbKeyframe1) delete 0 end
    $::Ibrowser(Process,KeyframeRegister,lbKeyframe2) delete 0 end
}

#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframePutReferenceInBG
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframePutReferenceInBG { } {

    #--- put reference in background but leave ibrowser index alone.
    set id $::Ibrowser(activeInterval)    
    IbrowserSetFGInterval $id
    IbrowserSetBGInterval $id
    MainSlicesSetVolumeAll Back $::Ibrowser(Process,InternalReference)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeShowKeyframeAndReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeShowKeyframeAndReference { } {

    set lb $::Ibrowser(Process,KeyframeRegister,lbKeyframe2)
    #--- put keyframe in foreground;
    set sel [ $lb curselection ]
    if { $sel == "" } {
        DevErrorWindow "Please select a keyframe."
        return
    }
    if { ! [ info exists ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) ] } {
        DevErrorWindow "Please specify keyframes first."
        return
    }
    if { ! [ info exists ::Ibrowser(Process,InternalReference) ] } {
        DevErrorWindow "Please specify a reference."
        return
    }
    set vid [ lindex $::Ibrowser(Process,KeyframeRegister,keyframeIDlist) $sel ]
    IbrowserSlicesSetVolumeAll Fore $vid
    #--- update the ibrowser index
    set id $::Ibrowser(activeInterval)    
    IbrowserSetFGInterval $id
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        if {$vid == $::Ibrowser($id,$i,MRMLid) } {
            set ::Ibrowser(ViewDrop) $i
            IbrowserUpdateIndexFromGUI
        }
    }

    #--- put reference in background but leave ibrowser index alone.
    IbrowserSetBGInterval $id
    MainSlicesSetVolumeAll Back $::Ibrowser(Process,InternalReference)
}



#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeLoadMatrix
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeLoadMatrix { } {
    #---
    #--- finds the matrix associated with keyframe,
    set sel [ $::Ibrowser(Process,KeyframeRegister,lbKeyframe2) curselection ]
    if { $sel == "" } {
        DevErrorWindow "No keyframe is currently selected."
        return
    }

    if { ! [ info exists ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) ] } {
        DevErrorWindow "No keyframes are specified."
        return
    }

    set vid [ lindex $::Ibrowser(Process,KeyframeRegister,keyframeIDlist) $sel ]
    #--- get matrix associated with this keyframe
    set id $::Ibrowser(activeInterval)
    set  tid -1
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        #--- if the drop's mrmlID matches the keyframe's mrmlID, get the transform.
        if {$vid == $::Ibrowser($id,$i,MRMLid) } {
            set tid $::Ibrowser($id,$i,matrixID)
            break
        }
    }
    #--- if we've found the transform, load into matrix entry widget.
    if { $tid < 0 } {
        DevErrorWindow "Couldn't find matrix associated with keyframe."
        return
    } 

    #--- make active and update the GUI
    set name [::Matrix($tid,node) GetName ]
    IbrowserKeyframesMatrixSetActive $tid
    #--- trigger switch to the Alignments module
    if {[IsModule Alignments] == 1} {
        Tab Alignments row1 Manual
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframesMatrixSetActive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframesMatrixSetActive { t } {
    set ::Ibrowser(activeMatrix) $t
    MainAlignmentsSetActive $t
}





#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframesSetMatrix
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframesSetMatrix { str } {
    #---
    #--- sets all the globals that show up in matrix GUI
    set count 0
    foreach i $::Ibrowser(Process,Matrix,rows) {
        foreach j $::Ibrowser(Process,Matrix,cols) {
            set ::Matrix(matrix,$i,$j) [ lindex $str $count]
            incr count
        }
    }
}





#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeInterpolateAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeInterpolateAll { } {

    #---
    if { ! [ info exists ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) ] } {
        DevErrorWindow "Please specify keyframes."
        return
    } elseif { $::Ibrowser(Process,InternalReference) == $::Volume(idNone) } {
        DevErrorWindow "A volume within the interval must be specified as a reference."
        return
    }

    #---
    #--- CHECK to see if keyframes are appropriately specified:
    #--- first and last volumes must be keyframes...
    set id $::Ibrowser(activeInterval)
    set start $::Ibrowser($id,firstMRMLid)
    set stop $::Ibrowser($id,lastMRMLid)
    set rid $::Ibrowser(Process,InternalReference)

    #--- make a list to use for interpolation that includes referenceID
    if { [info exists ::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) ] } {
        unset -nocomplain ::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist)
    }
    foreach KFid $::Ibrowser(Process,KeyframeRegister,keyframeIDlist) {
        lappend ::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $KFid
    }

    #--- if reference is not a specified keyframe, then add it.
    if { [ lsearch $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $rid ] < 0 } {
        #lappend ::Ibrowser(Process,KeyframeRegister,keyframeIDlist) $rid
        #set vname [ ::Volume($rid,node) GetName ]
        #lappend ::Ibrowser(Process,KeyframeRegister,keyframeNameList) $vname
        lappend ::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $rid
        set vname [ ::Volume($rid,node) GetName ]
        lappend ::Ibrowser(Process,KeyframeRegister,sortedkeyframeNameList) $vname
    }
    if { [ lsearch $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $start ] < 0 } {
        DevErrorWindow "First and last volume within the interval must be either keyframes or reference."
        return        
    }
    if { [ lsearch $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $stop ] < 0 } {
        DevErrorWindow "First and last volume within the interval must be either keyframes or reference."
        return        
    }    

    #--- create interpolator
    catch "rti Delete"
    vtkRigidTransformInterpolate rti
    catch "rtt Delete"
    vtkTransform rt
    rt Identity
    
    #--- initialize interpolation
    set numKFs [ llength $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) ]
    set numRanges [ expr $numKFs - 1 ]

    #--- sort keyframeIDs and names so they're in order from lowest mrmlIDs to highest.
    set ::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) [lsort -integer \
                                                            $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist)]

    #--- interpolate all volumes between each pair of keyframes.
    IbrowserRaiseProgressBar
    set pcount 0
    
    set index 0
    set KeyframeID [ lindex $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $index ]
    for { set n 0 } { $n < $numRanges } { incr n } {

        if { $numRanges != 0 } {
            set progress [ expr double ($pcount) / double ($numRanges) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }
        
    #-- get two keyframes and interpolate between.
        set lastindex $index
        set lastKeyframeID  $KeyframeID 
        
        set index [ expr $index + 1 ]
        set KeyframeID [ lindex $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $index ]

        #--- this is clumsy, but right now need to find this way.
        #--- need to know which drops these are to get matrix mrmlids
        #--- which drops are these keyframes?
        set drop0 -1
        set drop1 -1
        for {set m 0 } { $m < $::Ibrowser($id,numDrops) } { incr m } {
            if { $lastKeyframeID == $::Ibrowser($id,$m,MRMLid) } {
                set drop0 $m
            } elseif { $KeyframeID == $::Ibrowser($id,$m,MRMLid) } {
                set drop1 $m
            }
        }
        if { $drop0 < 0 || $drop1 < 0 } {
            DevErrorWindow "Keyframes are incorrectly specified"
            IbrowserEndProgressFeedback
            IbrowserLowerProgressBar
            return
        }
        #--- get matrices for these keyframes
        set tid0 $::Ibrowser($id,$drop0,matrixID)
        rti SetM0 [[::Matrix($tid0,node) GetTransform]  GetMatrix ]

        set tid1 $::Ibrowser($id,$drop1,matrixID)
        rti SetM1 [[::Matrix($tid1,node) GetTransform]  GetMatrix ]


        #--- for each volume node between keyframes
        set inc [ expr 1.0 / double($KeyframeID - $lastKeyframeID) ]
        set t 0
        for { set i $lastKeyframeID } { $i <= $KeyframeID } { incr i } {


            #--- find the corresponding drop; grab its matrix
            for {set drop 0 } { $drop < $::Ibrowser($id,numDrops) } { incr drop } {
                if { $i == $::Ibrowser($id,$drop,MRMLid) } {
                    set tid $::Ibrowser($id,$drop,matrixID)
                    #rti SetMT [[::Matrix($tid,node) GetTransform ] GetMatrix ]
                    rti SetMT [ rt GetMatrix ]
                    break
                }
            }

            #--- interpolate and set new matrix.
            rti SetT $t
            rti Interpolate

            set tid $::Ibrowser($id,$drop,matrixID)
            [::Matrix($tid,node) GetTransform] SetMatrix [rti GetMT]
            set t [ expr $t + $inc]
        }
        incr pcount
    }
    IbrowserEndProgressFeedback
    rti Delete
    rt Delete
    MainUpdateMRML
    RenderAll
    IbrowserSayThis "Keyframe interpolated transforms for $::Ibrowser($id,name)" 0
    IbrowserLowerProgressBar
}





#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeUndoInterpolate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeUndoInterpolate { } {

    if { ![info exists ::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist)] } {
        DevErrorWindow "Can't undo! No information about last interpolation."
        return
    }

    if { [info exists ::Ibrowser(Process,KeyframeRegister,KeyframeIDlist)] } {
        if { [ llength $::Ibrowser(Process,KeyframeRegister,keyframeIDlist)] == 0 } {
            DevErrorWindow "Can't undo! No information about last interpolation."
            return
        }
    }

    
    #--- make note of existing active matrix.
    set id $::Ibrowser(activeInterval)
    if { ! [info exists ::Ibrowser($id,$i,matrixID)] } {
        DevErrorWindow "No transforms for this interval! (check current active interval)."
        return
    }

    set oldtid $::Ibrowser(activeMatrix)

    set start $::Ibrowser($id,firstMRMLid)
    set stop $::Ibrowser($id,lastMRMLid)
    set did $start

    IbrowserRaiseProgressBar
    set pcount 0
    
    #--- sets all non-keyframe matrices to identity matrix.
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        #--- is this volume in the keyframe list? if not, reset matrix.
        if { $::Ibrowser($id,numDrops) != 0 } {
            set progress [ expr double ($pcount) / double ($::Ibrowser($id,numDrops)) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }
        
        set tst [ lsearch $::Ibrowser(Process,KeyframeRegister,useKeyframeIDlist) $did ]
        if { $tst < 0 } {
            set tid $::Ibrowser($id,$i,matrixID)
            MainAlignmentsSetActive $tid
            AlignmentsIdentity
        }
        incr did
        incr pcount
    }

    #--- set back to original active matrix.
    IbrowserEndProgressFeedback
    IbrowserKeyframesMatrixSetActive $oldtid
    IbrowserSayThis "Set non-keyframe transforms in $::Ibrowser($id,name) to identity matrix." 0
    IbrowserLowerProgressBar

}



#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeResetAllTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeResetAllTransforms { } {

    #--- make note of existing active matrix.
    set id $::Ibrowser(activeInterval)
    set oldtid -1
    if { [info exists ::Ibrowser(activeMatrix) ] } {
        set oldtid $::Ibrowser(activeMatrix)
    }
    IbrowserRaiseProgressBar
    set pcount 0
    
    #--- sets all volume transforms to identity matrix.
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        if { $::Ibrowser($id,numDrops) != 0 } {
            set progress [ expr double ($pcount) / double ($::Ibrowser($id,numDrops)) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }

        if {[info exists ::Ibrowser($id,$i,matrixID)] } {
            set tid $::Ibrowser($id,$i,matrixID)
            MainAlignmentsSetActive $tid
            AlignmentsIdentity
        } else {
            DevErrorWindow "No transforms in interval $::Ibrowser($id,name)."
            IbrowserEndProgressFeedback
            IbrowserLowerProgressBar
            return
        }
        incr pcount
    }
    IbrowserEndProgressFeedback
    #--- set back to original active matrix.
    if { $oldtid >= 0 } {
        IbrowserKeyframesMatrixSetActive $oldtid
    }
    IbrowserSayThis "Set all transforms in $::Ibrowser($id,name) to identity matrix." 0
    IbrowserLowerProgressBar
}




#-------------------------------------------------------------------------------
# .PROC IbrowserKeyframeDeleteAllTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserKeyframeDeleteAllTransforms { } {

    set id $::Ibrowser(activeInterval)
    #--- if this interval appears to have transforms the ibrowser put there...
    #--- delete them.
    if {[info exists ::Ibrowser($id,0,matrixID)] } {
        for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
            unset -nocomplain ::Ibrowser($id,$i,matrixID)
        }
        IbrowserRemoveTransforms
    } else {
        DevErrorWindow "No transforms in interval $::Ibrowser($id,name)."
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserHelpKeyframeRegister
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserHelpKeyframeRegister { } {

    set i [ IbrowserGetHelpWinID ]
    set txt "<H3>Keyframed Registration</H3>
 <P> This tool is an option for volumes of image data which may be difficult to register with automated intensity registration tools. The process uses a combination of manually specified and linearly interpolated transforms to register the volumes in a selected interval. Results will vary depending on the keyframes chosen and the quality of the manual registrations specified at each. The workflow is as follows:
<P>1. In the Keyframes tab, select an interval to be registered using one of its volumes as the reference;
<P>2. Add transform nodes to each volume in the interval;
<P>3. Choose a reference volume from the sequence;
<P>4. Select keyframes, for which manual transforms will be specified;
<P>5. In the Interpolate tab, select a keyframe;
<P>6. Load the keyframe in the viewer, (keyframe is loaded into the FG, with reference in the BG);
<P>7. (the keyframe's matrix is loaded and the user is automatically moved to the alignments module for manual transforming);
<P>8. when the transform is acceptable, move back to the Ibrowser module to repeat for the next keyframe.
<P>9. When all keyframes are specified, interpolate all transforms between the keyframes.
<P>10. Undo the interpolation if the results indicate that keyframes need to be edited;
<P>11. Reset all transforms if you want to start fresh.
<P>12. Delete all transforms if you want to abort and clean up.
<P> Undoing the interpolation removes the transforms that have been generated, but not those which have been manually specified; resetting all transforms sets all volume's transforms back to the identity matrix. Deleting all transforms removes the transform nodes that affect the selected interval's volumes."
    DevCreateTextPopup infowin$i "Ibrowser information" 100 100 18 $txt
}

