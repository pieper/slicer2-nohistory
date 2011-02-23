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
# FILE:        IbrowserInspectGUI.tcl
# PROCEDURES:  
#   IbrowserUpdateInspectTab
#   IbrowserBuildInspectFrame
#   IbrowserPlotConfigPlotType
#   IbrowserPlotCheckReferenceOnsets
#   IbrowserPlotCheckReferenceHeight
#   IbrowserPlotCheckReferenceSpan
#   IbrowserPlotCheckReferenceSpan
#   IbrowserPlotResetReferenceEntries
#   IbrowserPlotAddReference
#   IbrowserPlotDeleteReference
#   IbrowserPlotDeleteAllReferences
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateInspectTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateInspectTab { } {

    set ::Ibrowser(currentTab) "Inspect"
}



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildInspectFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildInspectFrame { } {
    global Gui Ibrowser Module Volume

    
    # error if no private segment
    if { [ catch "package require BLT" ] } {
        DevErrorWindow "Must have the BLT extension for the Tk toolkit installed to support plotting."
        return
    }
    #-------------------------------------------
    #--- Inspect frame: add buttons and pack
    #-------------------------------------------
    set fInspect $::Module(Ibrowser,fInspect)
    bind $::Module(Ibrowser,bInspect) <ButtonPress-1> "IbrowserUpdateInspectTab"
    set f $fInspect

    #--- Frames: use packer to put them in place
    #--- plot frame
    frame $f.fSigPlot -bg $::Gui(activeWorkspace) -bd 2 -relief groove
    pack $f.fSigPlot -side top -padx 0 -pady 1
    #--- add referenc wave frame
    frame $f.fAddRef -bg $::Gui(activeWorkspace) -bd 2 -relief groove
    pack $f.fAddRef -side top -padx 0 -pady 1
    #--- defined reference waves frame
    frame $f.fRefList -bg $::Gui(activeWorkspace) -bd 2 -relief groove
    pack $f.fRefList -side top -padx 0 -pady 1
 
    #---
    #--- fInspect-->fSigPlot
    #---
    #--- SIGNAL plotting 
    set f $fInspect.fSigPlot
    DevAddLabel $f.lPlotting "Select plot type:"
    pack $f.lPlotting -pady $::Gui(pad)

    #--- initialize pulldown menu with reference signals
    #--- make the menubutton
    set ::Ibrowser(plot,TypeVvvn) "scalar value vs. voxel number"
    set ::Ibrowser(plot,TypeHistogram) "scalar value histogram"
    set ::Ibrowser(plot,TypeROIAvg) "ROI average vs. volume number"
    set ::Ibrowser(plot,PlotType) $::Ibrowser(plot,TypeVvvn)
    eval {menubutton $f.mbSig \
          -text $::Ibrowser(plot,PlotType) -indicatoron 1 -relief raised -bd 2 -width 34 -menu $f.mbSig.menu } $Gui(WMBA)
    TooltipAdd $f.mbSig "Choose a plot type."
    eval { menu $f.mbSig.menu } $Gui(WMA)
    set ::Ibrowser(plot,Plotmb) $f.mbSig

   #--- make the menu
    foreach l "{$::Ibrowser(plot,TypeVvvn)}" {
        $f.mbSig.menu add command -label $l \
            -command "IbrowserPlotConfigPlotType {$l}"
    }
    pack $f.mbSig -pady $Gui(pad) -padx $::Gui(pad) -side top

    #--- turn detrending on or off...
    if { 0 } {
        DevAddLabel $f.lFiltering "Detrending:"
        set ::Ibrowser(plot,Detrending) 0
        pack $f.lFiltering -side left -pady $::Gui(pad) -padx 5
        eval { radiobutton $f.rDetrendON \
                   -text "on" -value 1 -variable ::Ibrowser(plot,Detrending) \
                   -indicatoron 0 } $::Gui(WCA)
        pack $f.rDetrendON -side left -padx 0 -pady 0
        TooltipAdd $f.rDetrendON "Highpass filters the samples to remove slow-varying trends."
        eval { radiobutton $f.rDetrendOFF \
                   -text "off" -value 0 -variable ::Ibrowser(plot,Detrending) \
                   -indicatoron 0 } $::Gui(WCA)
        pack $f.rDetrendOFF -side left -padx 0 -pady 0
        TooltipAdd $f.rDetrendOFF "Turns off highpass filtering."
    }

    #---
    #--- fInspect-->fAddRef
    #---
    #--- REFERENCE description 
    set f $fInspect.fAddRef
    DevAddLabel $f.lRefPlot "Specify reference waves:"
    pack $f.lRefPlot -pady $::Gui(pad)
    #--- initialize pulldown menu with reference signals
    #--- make the menubutton
    set ::Ibrowser(plot,boxcar) "boxcar"
    set ::Ibrowser(plot,impulse) "impulse"
    set ::Ibrowser(plot,halfsine) "halfsine"
    set ::Ibrowser(plot,HRF) "HRF"
    set ::Ibrowser(plot,RefType) $::Ibrowser(plot,boxcar)
    eval {menubutton $f.mbRef \
          -text $::Ibrowser(plot,RefType) -relief raised -indicatoron 1 -bd 2 -width 34 -menu $f.mbRef.menu } $Gui(WMBA)
    TooltipAdd $f.mbRef "Choose a reference signal kernal to configure and plot."
    eval { menu $f.mbRef.menu } $Gui(WMA)
    set ::Ibrowser(plot,Refmb) $f.mbRef

    #--- make the menu    
    #--- add other useful reference functions in here...
    foreach l "boxcar impulse halfsine HRF" {
    $f.mbRef.menu add command -label $::Ibrowser(plot,$l) \
        -command "$::Ibrowser(plot,Refmb) config -text $::Ibrowser(plot,$l); set ::Ibrowser(plot,RefType) $::Ibrowser(plot,$l)"
    }
    pack $f.mbRef -pady $Gui(pad) -padx $::Gui(pad) -side top

    #--- make new frame to qualify kernel
    #---
    #--- fInspect->fAddRef-->RefParams
    #---
    frame $f.fRefParams -bg $::Gui(activeWorkspace) -bd 2 -relief flat
    pack $f.fRefParams -pady $Gui(pad) -side top
    set f $f.fRefParams
    
    #--- kernel name
    if { [info exists ::Ibrowser(plotRefNameList) ] } {
        unset ::Ibrowser(plotRefNameList)
    }
    set ::Ibrowser(plot,RefCounter) 1
    set ::Ibrowser(plot,ReferenceNameEntry) "ref$::Ibrowser(plot,RefCounter)"
    DevAddLabel $f.lName "name: "    
    eval { entry $f.eName -width 20 \
           -textvariable ::Ibrowser(plot,ReferenceNameEntry) } $Gui(WEA)
    TooltipAdd $f.eName "Enter a unique name for this reference signal"
    bind $f.eName <Return> {
        IbrowserPlotCheckReferenceName
    }
    bind $f.eName <FocusOut> {
        IbrowserPlotCheckReferenceName
    }
    grid $f.lName $f.eName -sticky w -row 0 -columnspan 2 -pady 2 -padx 1

    #--- kernel color
    if { [info exists ::Ibrowser(plotRefColorList) ] } {
        unset ::Ibrowser(plotRefColorList)
    }
    DevAddLabel $f.lColor "color: "    
    #--- popup panel for color selection.
    scan $::Label(diffuse) "%f %f %f" r g b
    set r [ expr round($r * 255) ]
    set g [ expr round($g * 255) ]
    set b [ expr round($b * 255) ]
    set ::Ibrowser(plot,ReferenceColor) [ format \#%02X%02X%02X $r $g $b ]
    eval { button $f.bColorSelection -width 10 -textvariable ::Label(name) \
               -command "ShowColors" -bg $::Gui(activeWorkspace) -fg black}
    TooltipAdd $f.bColorSelection "Choose a color with which to plot the reference signal."
    grid $f.lColor $f.bColorSelection -sticky w -row 1 -columnspan 2 -pady 2 -padx 1
    lappend ::Label(colorWidgetList) $f.bColorSelection
    
    #--- vector of onsets for each kernel
    set ::Ibrowser(plot,ReferenceOnsets) "0"
    DevAddLabel $f.lOnsets "onsets (vol no.): "
    eval { entry $f.eOnsets -width 20 \
           -textvariable ::Ibrowser(plot,ReferenceOnsets) } $Gui(WEA)
    TooltipAdd $f.eOnsets "Enter a vector of volume numbers at which onsets of the reference kernel should occur."
    bind $f.eOnsets <Return> {
        IbrowserPlotCheckReferenceOnsets
    }
    bind $f.eOnsets <FocusOut> {
        IbrowserPlotCheckReferenceOnsets
    }
    grid $f.lOnsets $f.eOnsets -sticky w -row 2 -columnspan 2 -pady 2 -padx 1
    
    #--- kernel height scale
    set ::Ibrowser(plot,ReferenceHeight) 100
    DevAddLabel $f.lHeight "height (%): "
    eval { entry $f.eHeight -width 20 \
           -textvariable ::Ibrowser(plot,ReferenceHeight) } $Gui(WEA)
    TooltipAdd $f.eHeight "Enter the height of the reference signal as a percentage of the voxel signal."
    bind $f.eHeight <Return> {
        IbrowserPlotCheckReferenceHeight
    }
    bind $f.eHeight <FocusOut> {
        IbrowserPlotCheckReferenceHeight
    }
    grid $f.lHeight $f.eHeight -sticky w -row 3 -columnspan 2 -pady 2  -padx 1
    
    #--- kernel width scale (number of volumes)
    set ::Ibrowser(plot,ReferenceSpan) 3
    DevAddLabel $f.lSpan "span (no. vols): "
    eval { entry $f.eSpan -width 20 \
           -textvariable ::Ibrowser(plot,ReferenceSpan) } $Gui(WEA)
    TooltipAdd $f.eSpan "Specify the number of volumes that each instance of the reference kernel should span."
    bind $f.eSpan <Return> {
        IbrowserPlotCheckReferenceSpan
    }
    bind $f.eSpan <FocusOut> {
        IbrowserPlotCheckReferenceSpan
    }
    grid $f.lSpan $f.eSpan -sticky w -row 4 -columnspan 2 -pady 2 -padx 1


    #--- add the reference to plot
    DevAddButton $f.bAdd "add" "IbrowserPlotAddReference" "5"
    TooltipAdd $f.bAdd "Add the configured reference signal to a list to be plotted."
    grid $f.bAdd -sticky w -row 5 -column 2  -pady 5

    #---
    #--- fInspect-->fRefList
    #---
    #--- REFERENCE list 
    set f $fInspect.fRefList
    DevAddLabel $f.lDefRefs "Defined reference waves (optional):"
    pack $f.lDefRefs -pady $::Gui(pad)
    eval { scrollbar $f.sRefs -command "$f.lbRefs yview" }
    eval { listbox $f.lbRefs -bg $Gui(normalButton) -font {helvetica 8} -selectmode single \
               -listvariable ::Ibrowser(plot,RefNameList) -fg $Gui(textDark) -width 25 -height 3 \
               -yscrollcommand "$f.sRefs set" }
    set ::Ibrowser(plot,lbRefs) $f.lbRefs
    pack $f.lbRefs -padx $::Gui(pad) -pady 1 -side left
    pack $f.sRefs -padx 0 -side left -pady 1 -fill y
    DevAddButton $f.bDeleteOne "delete" "IbrowserPlotDeleteReference" 8
    DevAddButton $f.bClearAll "clear" "IbrowserPlotDeleteAllReferences" 8
    TooltipAdd $f.bDeleteOne \
        "Delete selected reference waveform from list"
    TooltipAdd $f.bClearAll \
        "Delete all reference waveforms from list"
    pack $f.bClearAll -side bottom -pady 1 -padx $::Gui(pad)
    pack $f.bDeleteOne -side bottom -pady 1 -padx $::Gui(pad)

}




#-------------------------------------------------------------------------------
# .PROC IbrowserPlotConfigPlotType
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotConfigPlotType { txt } {

    $::Ibrowser(plot,Plotmb) config -text $txt
    set ::Ibrowser(plot,PlotType) $txt
}




#-------------------------------------------------------------------------------
# .PROC IbrowserPlotCheckReferenceOnsets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotCheckReferenceOnsets { } {
    #--- check:
    #--- trim any leading or trailing white spaces
    set onsets [ string trim $::Ibrowser(plot,ReferenceOnsets) ]
    #--- replace multiple spaces in the middle of the string
    #--- that the user entered by just one space.
    regsub -all {( )+} $onsets " " onsets
    #--- are the values in the vector reasonable ones?
    #--- each value should be between 0 and numDrops-1.
    set id $::Ibrowser(activeInterval)
    set upper [ expr $::Ibrowser($id,numDrops) - 1 ]
    set lower 0
    set error 0
    set len [ llength $onsets]
    for { set i 0 } { $i < $len } { incr i } {
        set val [ lindex $onsets $i ]
        if { ($val < $lower) || ($val > $upper) } {
            set error 1
        }
    }
    set ::Ibrowser(plot,ReferenceOnsets) $onsets
    if { $error } {
        DevErrorWindow "Onsets: each onset must be a valid volume number in the selected interval."
        return 0
    } 
    return 1
}





#-------------------------------------------------------------------------------
# .PROC IbrowserPlotCheckReferenceHeight
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotCheckReferenceHeight { } {
    #--- check height and set Ibrowser(plot,RefHeight)
     set height $::Ibrowser(plot,ReferenceHeight)
     if { ($height < 0.0) || ($height > 100.0) } {
         DevErrorWindow "Height: specify a percentage (0-100) of the timecourse height."
         return 0
     }
     return 1

}



#-------------------------------------------------------------------------------
# .PROC IbrowserPlotCheckReferenceSpan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotCheckReferenceSpan { } {

    #--- How many volumes in this interval;
    #--- and so how many samples will be in
    #--- the voxel timecourse? Use the active interval.
    set id $::Ibrowser(activeInterval)
    set numSamples $::Ibrowser($id,numDrops)
    set span $::Ibrowser(plot,ReferenceSpan)
    if { $numSamples < 1 } {
        DevErrorWindow "Span: selected interval is empty; nothing to plot."
        return 0
    }
    if { ($span < 1) || ($span >  $numSamples) } {
        DevErrorWindow "Span: a valid span for this interval is between 1 and $numSamples."
        return 0
    }
         return 1
}



#-------------------------------------------------------------------------------
# .PROC 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc  IbrowserPlotCheckReferenceName { } {

    #--- Need to append the name of the reference waveform.
    #--- if the list exists, check to see if the name is already
    #--- in the list before adding it; otherwise, just create list
    #--- and add the name.
    set name $::Ibrowser(plot,ReferenceNameEntry)
    if { [info exists ::Ibrowser(plot,RefNameList) ] } {
        if { [lsearch $::Ibrowser(plot,RefNameList) $name]  >= 0 } {
            DevErrorWindow "Name: a reference waveform named $name already exists."
            return 0
        }
        return 1
    }
    return 0
}



#-------------------------------------------------------------------------------
# .PROC IbrowserPlotResetReferenceEntries
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotResetReferenceEntries { } {
    #--- reset the entry default onsets
    #set ::Ibrowser(plot,ReferenceOnsets) 0
    #--- reset the entry default height
    #set ::Ibrowser(plot,ReferenceHeight) 100
    #--- reset the entry default span
    #set ::Ibrowser(plot,ReferenceSpan) 2
    #--- update the entry default name
    set ::Ibrowser(plot,ReferenceNameEntry)  "ref$::Ibrowser(plot,RefCounter)"
}





#-------------------------------------------------------------------------------
# .PROC IbrowserPlotAddReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotAddReference { } {

    #--- add valid reference to lists.
    set error 0
    if { [ IbrowserPlotCheckReferenceOnsets ] ==0 } {
        set error 1
    }
    if { [ IbrowserPlotCheckReferenceHeight ] == 0 } {
        set error 1
    }
    if { [ IbrowserPlotCheckReferenceSpan ] == 0 } {
        set error 1
    }
    if { [ IbrowserPlotCheckReferenceName ] == 0 } {
        set error 1
    }

    if { $error == 0 } {
        #--- get current label color, which sets reference wave color
        scan $::Label(diffuse) "%f %f %f" r g b
        set r [ expr round($r * 255) ]
        set g [ expr round($g * 255) ]
        set b [ expr round($b * 255) ]
        set ::Ibrowser(plot,ReferenceColor) [ format \#%02X%02X%02X $r $g $b ]
        lappend ::Ibrowser(plot,RefNameList) $::Ibrowser(plot,ReferenceNameEntry)
        lappend ::Ibrowser(plot,RefOnsetList) $::Ibrowser(plot,ReferenceOnsets)
        lappend ::Ibrowser(plot,RefHeightList) $::Ibrowser(plot,ReferenceHeight)
        lappend ::Ibrowser(plot,RefTypeList) $::Ibrowser(plot,RefType)
        lappend ::Ibrowser(plot,RefSpanList) $::Ibrowser(plot,ReferenceSpan)
        lappend ::Ibrowser(plot,RefColorList) $::Ibrowser(plot,ReferenceColor)
        #--- this gets used to generate a default unique name
        incr ::Ibrowser(plot,NumReferences)
        #--- this gets used to generate a default unique name
        incr ::Ibrowser(plot,RefCounter)
        IbrowserPlotResetReferenceEntries
    } else {
        DevErrorWindow "Reference not added. Offending entry value."
    }
}





#-------------------------------------------------------------------------------
# .PROC IbrowserPlotDeleteReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotDeleteReference { } {

    #--- get the selection
    set kx [ $::Ibrowser(plot,lbRefs) curselection ]
    if { $kx == ""} {
        return
    }
    #--- remove elements from all reference lists at this index.
    set ::Ibrowser(plot,RefNameList) [ lreplace $::Ibrowser(plot,RefNameList) $kx $kx ]
    set ::Ibrowser(plot,RefOnsetList) [ lreplace $::Ibrowser(plot,RefOnsetList) $kx $kx]
    set ::Ibrowser(plot,RefHeightList) [ lreplace $::Ibrowser(plot,RefHeightList) $kx $kx ]
    set ::Ibrowser(plot,RefSpanList) [ lreplace $::Ibrowser(plot,RefSpanList) $kx $kx ]
    set ::Ibrowser(plot,RefTypeList) [ lreplace $::Ibrowser(plot,RefTypeList) $kx $kx ]
    set ::Ibrowser(plot,RefColorList) [ lreplace $::Ibrowser(plot,RefColorList) $kx $kx ]
    set ::Ibrowser(plot,NumReferences) [expr $::Ibrowser(plot,NumReferences) - 1 ]
}




#-------------------------------------------------------------------------------
# .PROC IbrowserPlotDeleteAllReferences
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlotDeleteAllReferences { } {
    #--- all reference waveforms are being deleted,
    #--- so delete all lists that describe those defined.
    if { [ info exists ::Ibrowser(plot,RefTypeList) ] } {
        set ::Ibrowser(plot,RefTypeList) ""
    }
    if { [ info exists ::Ibrowser(plot,RefOnsetList) ] } {
        set ::Ibrowser(plot,RefOnsetList) ""
    }
    if { [ info exists ::Ibrowser(plot,RefHeightList) ] } {
        set ::Ibrowser(plot,RefHeightList) ""
    }    
    if { [ info exists ::Ibrowser(plot,RefSpanList) ] } {
        set ::Ibrowser(plot,RefSpanList) ""
    }
    if { [ info exists ::Ibrowser(plot,RefColorList) ] } {
        set ::Ibrowser(plot,RefColorList) ""
    }    
    if { [info exists ::Ibrowser(plot,RefNameList)] } {
        set ::Ibrowser(plot,RefNameList) ""
    }
    if { [ info exists ::Ibrowser(plot,NumReferences) ] } {
        set ::Ibrowser(plot,NumReferences) 0
    }
    set ::Ibrowser(plot,RefCounter) 1
    IbrowserPlotResetReferenceEntries
}

