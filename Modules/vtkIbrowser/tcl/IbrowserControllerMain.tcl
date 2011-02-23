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
# FILE:        IbrowserControllerMain.tcl
# PROCEDURES:  
#   IbrowserControllerLaunch
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserControllerLaunch
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserControllerLaunch {{toplevelName .controllerGUI} } {
    global Ibrowser Gui 

    if {[winfo exists $toplevelName]} {
        wm deiconify $toplevelName
        raise $toplevelName
        return
    }

    #------------------------------------------------------
    #fMRIModelViewLaunchModelView
    #------------------------------------------------------

    set root [toplevel $toplevelName]

    #--- setup the Ibrowser
    #---------------
    set ::IbrowserController(UI,MinWinWid) $::View(viewerWidth)
    set ::IbrowserController(UI,MinWinHit) 375
    wm title $root "Ibrowser controller"
    wm geometry $root +244+753
    wm minsize $root $::IbrowserController(UI,MinWinWid) $::IbrowserController(UI,MinWinHit)

    IbrowserSetUIsize
    IbrowserSetUIfonts
    IbrowserSetUIcolors
    IbrowserSetupIntervals
    IbrowserSetupIcons
    IbrowserSetupAnimationMenuImages 
    IbrowserSetupViewPopupImages
    IbrowserSetupDropImages
    
    #--- init canvas stuff
    #---------------
    # set the interval and control canvas' size and scroll regions to 
    # fit default interval; figure out pixels to units conversions.
    # send: wid hit of both canvases, and ganged scrollwid, scrollhit
    set iCwid 500
    set iChit 80
    set cCwid 500
    set cChit 50
    set Hscroll 100
    set Vscroll 100
    set Hscroll [ expr $::IbrowserController(UI,MinWinWid) + $Hscroll ]
    IbrowserInitCanvasGeom $iCwid $iChit $cCwid $cChit $Hscroll $Vscroll
    $root configure -background $::IbrowserController(Colors,background_color)    

    #--- make top buffer to hold some spacers, image and text labels
    #---------------
    set fr [ IbrowserMakeAnimationMenu $root ]
    IbrowserMakeViewMenu $fr
    
    #--- make the ibrowser frame to hold the canvases and a scrollbar...
    #---------------
    frame $root.fIbrowser
    set ::IbrowserController(Icanvas) \
        [IbrowserMakeVscrollCanvas $root.fIbrowser.intcanv $root.fIbrowser.cntcanv \
                     -relief groove -borderwidth 1 -bg $::IbrowserController(Colors,interval_canvas_color) \
                     -width $iCwid -height $iChit  -scrollregion " 0 0 $Hscroll $Vscroll" ]

    set ::IbrowserController(Ccanvas) \
        [IbrowserMakeGangedHscrollCanvas $root.fIbrowser.cntcanv $root.fIbrowser.intcanv \
                     -relief groove -borderwidth 1 -bg $::IbrowserController(Colors,interval_canvas_color) \
                     -width $iCwid -height $cChit -scrollregion " 0 0 $Hscroll 0"]
    IbrowserInitCanvasSizeAndScrollRegion
    
    #note: index slider and sliderbar are
    #deleted (if they exist) and re-created fresh
    #after each interval is created.
    #---------------
    frame $root.fIbrowser.fsideblank -width 10 -height 20 -bg white   
    
    #pack up the canvases
    #---------------
    $root.fIbrowser configure -background white
    pack $root.fIbrowser -side top -fill both -expand true 
    pack $root.fIbrowser.fsideblank -side left
    pack $root.fIbrowser.intcanv -side top -fill both -expand true
    pack $root.fIbrowser.cntcanv -side top -fill x -expand false


    #make a little scrolling bottom buffer to hold messages,
    #with some space around it.
    #---------------
    frame $root.fibBlank2 -relief flat -bg $::IbrowserController(Colors,interval_canvas_color) \
        -height 30 -width $cCwid
    frame $root.fibBlank3 -relief flat -bg $::IbrowserController(Colors,interval_canvas_color) \
        -height 40 -width $cCwid
    frame $root.fsideBlank -width 10 -height 20 -bg white
    frame $root.fibMessageBox -relief flat -bg $::IbrowserController(Colors,interval_canvas_color) \
        -height 150 
    set wid $cCwid
    set hit 15
    set ::IbrowserController(UI,SaySo) [ IbrowserMakeMessagePanel $root.fibMessageBox -width 100 -height 7  ]

    set tt "Use this controller to keep track of sequences or collections \
of data that you have loaded. Controls at the top can be used to step \
through the data and to automatically play an animation once or in a loop.\
Selecting an interval's name icon, its order, visibility or opacity icon allows \
you to change these properties for all of the data within that interval. \
Clicking and dragging the red marker lets you index the study manually. \
All intervals represented within the study are functions of the same \
variable, and are registered to a global inclusive interval."
    IbrowserSayThis $tt 0

    set tt "In this panel, system messages and help messages will \
be displayed throughout your session."
    IbrowserSayThis $tt 0

    set tt "Warning and error messages will appear in red."
    IbrowserSayThis $tt 1

    pack $root.fsideBlank -side left
    pack $root.fibBlank2 -side top
    pack $root.fibBlank3 -side bottom
    pack $root.fibMessageBox -side left -fill both -expand false


    #SET UP
    #---------------
    set ::IbrowserController(Info,Ival,firstIval) 1
    set ::IbrowserController(Info,Ival,globalIvalPixXstart) [ IbrowserComputeIntervalXleft ]

    #--- Assume no collections have been loaded yet.
    #--- Set VolumeGroupCollection(numCollections) to 0
    set ::VolumeGroupCollection(numCollections) 0
    
    #--- Create the 'none' interval for emptying BG or FG
    IbrowserMakeNoneInterval
}
