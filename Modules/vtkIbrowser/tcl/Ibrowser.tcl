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
# FILE:        Ibrowser.tcl
# PROCEDURES:  
#   IbrowserInit
#   IbrowserInit
#   IbrowserBuildGUI
#   IbrowserEnter
#   IbrowserExit
#   IbrowserPushBindings
#   IbrowserPopBindings
#   IbrowserCreateBindings  
#   IbrowserProcessMouseEvent
#   IbrowserSetDirectory
#   IbrowserGetIntervalNameFromID
#   IbrowserGetIntervalIDFromName
#   IbrowserBuildVTK
#   IbrowserUpdateMRML
#   IbrowserGetHelpWinID
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC IbrowserInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#  LANGUAGE: 'Intervals' are containers for 'Sequences'. 'Sequences' are
#  composed of individual 'Drops'. 'Drops' are image, volume, model,
#  data, command, note, or event data objects. A 'Study' is a collection of
#  intervals.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC IbrowserInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInit {} {
    global Ibrowser Module Volume Model IbrowserController
    global PACKAGE_DIR_VTKIbrowser 

    set m Ibrowser

    
    #---Module summary info
    set Module($m,overview) "GUI-controller and framework for manipulating sequences of image data."
    set Module($m,author) "Wendy Plesniak, SPL & HCNR, wjp@bwh.harvard.edu"

    #---Define tabs
    set Module($m,row1List) "Help New Display Process Inspect"
    #set Module($m,row1Name) "{help} {new} {display} {process} {view} {save}"
    set Module($m,row1Name) "{help} {new} {display} {process} {inspect}"
    set Module($m,row1,tab) New

    #---Procedure definitions
    set Module($m,procGUI) IbrowserBuildGUI
    set Module($m,procEnter) IbrowserEnter
    set Module($m,procExit) IbrowserExit    
    set Module($m,procMRML) IbrowserUpdateMRML
    
    #---Dependencies
    set Module($m,depend) "MultiVolumeReader"

    #---Set category and version info
    set Module($m,category) "Alpha"
       lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.15 $} {$Date: 2006/01/06 17:57:51 $}]

    #---Initialize module-level variables
    #---Global array with the same name as the module. Ibrowser()
    #---contains just the highest-level framework. IbrowserController(Info,Ival,xx)
    #---and ${intervalName}() contain much more elaborate state about
    #---intervals, both as a group and individually, respectively.

    #--- Just some default values to start.
    set Ibrowser(currentTab) "New"
    set Ibrowser(idList) ""
    set Ibrowser(dir) ""
    set Ibrowser(numSequences) 0
    set Ibrowser(uniqueNum) 0
    set Ibrowser(ViewDrop) 0
    set Ibrowser(MaxDrops) 1
    set Ibrowser(0,firstMRMLid) 0
    set Ibrowser(0,lastMRMLid) 0
    set Ibrowser(0,0,MRMLid) 0
    set Ibrowser(idNone) 0
    set Ibrowser(NoInterval) -1
    set Ibrowser(${Ibrowser(idNone)},name) "none"
    set Ibrowser(activeInterval) $::Ibrowser(idNone)
    #--- Manage what's in Slicer Viewer's FG and BG.
    #set Ibrowser(FGInterval) $Ibrowser(idNone)
    #set Ibrowser(BGInterval) $Ibrowser(idNone)
    set Ibrowser(FGInterval) $Ibrowser(NoInterval)
    set Ibrowser(BGInterval) $Ibrowser(NoInterval)

    #--- Here, 20.0 is chosen to be the number of units wide to make
    #--- the none interval. This arbitrary number makes certain the
    #--- subsequent populated intervals don't have overlapping
    #--- volume icons in them.
    set Ibrowser(initIntervalWid) 20.0
    set Ibrowser(MaxDrops) 0
    set Ibrowser(opacity) 1.0
    
    #--- Animation global variables.
    set Ibrowser(AnimationInterrupt) 0
    set Ibrowser(AnimationPaused) 0
    set Ibrowser(AnimationWas) ""
    set Ibrowser(AnimationFrameDelay) 0
    set Ibrowser(AnimationDirection) 1
    set Ibrowser(currFrametag) "curr_frame_textbox"
    set Ibrowser(AnimationForw) 0
    set Ibrowser(AnimationRew) 0
    set Ibrowser(AnimationLoop) 0    
    set Ibrowser(AnimationPPong) 0
    set Ibrowser(AnimationRecording) 0
    
    #--- set initial values for GUI radio buttons.
    #--- assembleChoice [0=files, 1=sequences, 2=volumes]
    set Ibrowser(New,assembleChoice) 2
    set Ibrowser(New,selectedVolumeID) ""
    set Ibrowser(New,assembleList) ""

    #--- for Plotting...
    set ::Ibrowser(plot,NumReferences) 0
    set ::Ibrowser(plot,plotTitle) ""
    set ::Ibrowser(plot,plotWidth) 500
    set ::Ibrowser(plot,plotHeight) 250
    set ::Ibrowser(plot,plotGeometry) "+335+200"

        #--- Zooming references
    set IbrowserController(zoomfactor) 0
    #--- Location of popup windows
    set IbrowserController(popupX) 375
    set IbrowserController(popupY) 753
    #--- progress indicator
    set IbrowserController(ProgressBarTxt) ""
    
    #--- This variable contains the module path plus some stuff
    #--- trim off the extra stuff, and add on the path to tcl files.
    set tmpstr $PACKAGE_DIR_VTKIbrowser
    set tmpstr [string trimright $tmpstr "/vtkIbrowser" ]
    set tmpstr [string trimright $tmpstr "/Tcl" ]
    set tmpstr [string trimright $tmpstr "Wrapping" ]
    set modulePath [format "%s%s" $tmpstr "tcl/"]
    set Ibrowser(modulePath) $modulePath
    

    source ${modulePath}IbrowserDisplayGUI.tcl
    source ${modulePath}IbrowserLoadGUI.tcl
    source ${modulePath}IbrowserProcessGUI.tcl
    source ${modulePath}IbrowserSaveGUI.tcl
    source ${modulePath}IbrowserViewGUI.tcl
    source ${modulePath}IbrowserHelpGUI.tcl    
    source ${modulePath}IbrowserInspectGUI.tcl
    
    #--- Developers: ADD NEW PROCESSES TO THIS GLOBAL LIST
    set ::Ibrowser(Process,AllProcesses) "Reorient Smooth Reassemble KeyframeRegister"
    #--- These contain extra procs for
    #--- IO / processing / visualization
    foreach process $::Ibrowser(Process,AllProcesses) {
        source ${modulePath}IbrowserProcessing/Ibrowser${process}.tcl
    }
    
    #--- These contain tcl code for the interval controller
    #--- which is launched in proc IbrowserEnter().
    source ${modulePath}IbrowserControllerMain.tcl
    source ${modulePath}IbrowserControllerAnimation.tcl
    source ${modulePath}IbrowserControllerViewPopup.tcl
    source ${modulePath}IbrowserControllerGUIbase.tcl
    source ${modulePath}IbrowserControllerArrayList.tcl
    source ${modulePath}IbrowserControllerIcons.tcl
    source ${modulePath}IbrowserControllerIntervals.tcl
    source ${modulePath}IbrowserControllerCanvas.tcl
    source ${modulePath}IbrowserControllerUtils.tcl
    source ${modulePath}IbrowserControllerSlider.tcl
    source ${modulePath}IbrowserControllerDrops.tcl
    source ${modulePath}IbrowserControllerProgressBar.tcl

    source ${modulePath}IbrowserPlot.tcl
    
    #--- Create a new Interval Collection
    #--- set its id, its number of intervals to 0
    #--- set its name to "Collection_0"
    #--- set the number of intervals it contains.
    
    set Ibrowser(numIcollections) 1
    set Ibrowser(IcollectionID) 0
    set i $Ibrowser(IcollectionID)
    #vtkIntervalCollection Ibrowser($i,Icollection)
    #Ibrowser($i,Icollection) SetCollectionID $i
    #Ibrowser($i,Icollection) SetName "Collection_0"
    #Ibrowser($i,Icollection) SetnumIntervals 0

    #--- For processing....
    #set ::Ibrowser(Process,SelectSequence) $Ibrowser(idNone)
    set ::Ibrowser(Process,reassembleAxis) ""
    set ::VolumeGroupCollection(numCollections) 0

    #--- For plotting...
    IbrowserCreateBindings
}



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
#--- Builds the external control panel
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC IbrowserBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildGUI {} {

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------

    IbrowserBuildHelpFrame
    IbrowserBuildLoadFrame
    IbrowserBuildProcessFrame
    IbrowserBuildDisplayFrame
    IbrowserBuildInspectFrame
    #IbrowserBuildSaveFrame
}




#-------------------------------------------------------------------------------
# .PROC IbrowserEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserEnter {{toplevelName .controllerGUI} } {
# Called when this module is entered by a user. 

    set ::Volume(name) ""

    #pushEventManager $Ibrowser(eventManager)

    #--- Create or Raise the Ibrowser Controller
    #--- and push all event bindings onto the stack.
    IbrowserControllerLaunch

    
    #--- activate bindings to trap plot events
    IbrowserPushBindings

    #--- These are Ibrowser windows.
    set ::IbrowserController(topLevel) $toplevelName
    set ::IbrowserController(View,multiVolView) ".controllerMultiVolViewMOCKUP"
    set ::IbrowserController(View,VoxTimecourse) ".controllerVoxelTimecourseMOCKUP"

    #--- If you want to iconify controller; 
    if { 0 } {
        if {[winfo exists $toplevelName]} {
            lower $toplevelName
            wm iconify $toplevelName
        }
    }

}



#-------------------------------------------------------------------------------
# .PROC IbrowserExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserExit {{toplevelName .controllerGUI}} {
# Called when this module is exited by a user. 

    # popEventManager
    #--- deactivate bindings to trap plot events
     IbrowserPopBindings

    #--- Lower and iconify the Ibrowser Controller
    if {[winfo exists $toplevelName]} {
        lower $toplevelName
        wm iconify $toplevelName
    }


}



#-------------------------------------------------------------------------------
# .PROC IbrowserPushBindings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPushBindings { } {
    #push onto the even stack a new event manager that
    #deals with events when the Ibrowser module is active
    global Ev Csys
    EvActivateBindingSet IbrowserSlice0Events
    EvActivateBindingSet IbrowserSlice1Events
    EvActivateBindingSet IbrowserSlice2Events
    
}




#-------------------------------------------------------------------------------
# .PROC IbrowserPopBindings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPopBindings { } {
    #remove bindings when Ibrowser module is inactive
    global Ev Csys
    EvDeactivateBindingSet IbrowserSlice0Events
    EvDeactivateBindingSet IbrowserSlice1Events
    EvDeactivateBindingSet IbrowserSlice2Events

}


#-------------------------------------------------------------------------------
# .PROC IbrowserCreateBindings  
# Creates Ibrowser event bindings for the three slice windows 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateBindings { } {
    global Gui Ev

    EvDeclareEventHandler IbrowserSlicesEvents <1> \
        { set xc %x; set yc %y; IbrowserProcessMouseEvent $xc $yc }
           
    EvAddWidgetToBindingSet IbrowserSlice0Events $Gui(fSl0Win) {IbrowserSlicesEvents}
    EvAddWidgetToBindingSet IbrowserSlice1Events $Gui(fSl1Win) {IbrowserSlicesEvents}
    EvAddWidgetToBindingSet IbrowserSlice2Events $Gui(fSl2Win) {IbrowserSlicesEvents}    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserProcessMouseEvent
# Creates Ibrowser event bindings for the three slice windows 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserProcessMouseEvent { x y } {

    if { $::Ibrowser(currentTab) == "Inspect" } {
        IbrowserPopUpPlot $x $y
    } 

}


#-------------------------------------------------------------------------------
# .PROC IbrowserSetDirectory
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetDirectory { } {
    if { $dir == ""} {
        set dir [tk_chooseDirectory]
    }
     if { ![file isdirectory $dir/deformed_template] } {
        DevErrorWindow "$dir doesn't appear to be an FMRI directory"
        return
    }
    set ::Ibrowser(dir) $dir
}





#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalNameFromID
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalNameFromID { num } {

    set iname $::Ibrowser($num,name)
    return $iname
}




#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalIDFromName
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalIDFromName { name } {

    set inum $::Ibrowser($name,intervalID)
    return $inum
}





#-------------------------------------------------------------------------------
# .PROC IbrowserBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildVTK {} {
}





#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateMRML { } {
    global Matrix Volume

    #--- This routine configures all pulldown interval menus to include 
    #--- names of new intervals as they are added by a user.

    #--- update menu buttons.
    foreach process $::Ibrowser(Process,AllProcesses) {
        if { [info exists ::Ibrowser(Process,$process,mbIntervals) ] } {
            set name $::Ibrowser(${::Ibrowser(activeInterval)},name)
            $::Ibrowser(Process,$process,mbIntervals) config -text $name
        }
    }
    
    if { [info exists ::Ibrowser(New,mAssembleVolume) ] } {
        set m $::Ibrowser(New,mAssembleVolume)
        $m delete 0 end
        foreach v $::Volume(idList) {
            if { $v != 0 } {
                $m add command -label [::Volume($v,node) GetName ] \
                    -command "IbrowserSelectVolumeForSequenceList $v"
            }
        }
    }
    
    #--- not yet implemented
    if { [info exists ::Ibrowser(New,mAssembleSequences) ] } {
        set m $::Ibrowser(New,mAssembleSequences)
        $m delete 0 end
        foreach id $::Ibrowser(idList) {
            if { $id != 0 } {
                $m add command -label $::Ibrowser($id,name)  \
                    -command ""
            }
        }
    }


    #--- infrastructure to manage the KeyframeRegister menubuttons and menus
    #--- is also in IbrowserKeyframeRegister.tcl, but it doesn't seem to work
    #--- there; so it's here for now. May have something to do with notebook
    #--- in which it's contained...? Every other process manages its own GUI
    #--- from inside it's own tcl file.
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
# .PROC IbrowserGetHelpWinID
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetHelpWinID { } {

    if { ![info exists ::Ibrowser(winID) ] } {
        set ::Ibrowser(winID) 0
    }
    incr ::Ibrowser(winID)
    return $::Ibrowser(winID)

}
