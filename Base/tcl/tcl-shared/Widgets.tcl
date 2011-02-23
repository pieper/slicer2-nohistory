#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Widgets.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:06 $
#   Version:   $Revision: 1.15 $
# 
#===============================================================================
# FILE:        Widgets.tcl
# PROCEDURES:  
#   ScrolledText f args
#   TabbedFrame arrayName buttonsFrame tabsFrame buttonsLabel tabs titles tooltips extraTopFrame firstTab
#   TabbedFrameTab frame
#   TabbedFrameInvoke containerFrame buttonName
#==========================================================================auto=

# This file contains widgets that may be useful to developers
# of Slicer modules.
#
#   ScrolledText     A text box with a scrollbar
#
#   Tabbed Frame     Makes button navigation menu and multiple frames ("tabs")


#-------------------------------------------------------------------------------
# .PROC ScrolledText
# Makes a simple scrolled text box.
# .ARGS
# windowpath f the container frame
# list args not used
# .END
#-------------------------------------------------------------------------------
proc ScrolledText { f args } {
    global Gui

    frame $f -bg $Gui(activeWorkspace)
    eval {text $f.text \
        -xscrollcommand [list $f.xscroll set] \
        -yscrollcommand [list $f.yscroll set] -bg} $Gui(normalButton)
    eval {scrollbar $f.xscroll -orient horizontal \
        -command [list $f.text xview]} $Gui(WSBA)
    eval {scrollbar $f.yscroll -orient vertical \
        -command [list $f.text yview]} $Gui(WSBA)
    grid $f.text $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1
    return $f.text
}

#-------------------------------------------------------------------------------
# .PROC TabbedFrame
# This creates a menu of buttons and the frames they tab to.  
# It saves the path to each frame and creates an indicator
# variable to tell which is the current frame, and it puts
# these things into your global array, in case they are needed.<br>
# Before calling this, you need
# to make a frame for the buttons to go into and also a frame
# for all the frames to go into, and pass these as parameters.  It is
# very important to make the frame to hold frames have height 310 or
# things won't show up inside. See MeasureVol.tcl for an example of 
# how to use this. 
# .ARGS
# str arrayName        name of the global array for your module.
# str buttonsFrame     the frame you created for the buttons
# str tabsFrame        the frame you created to hold all tabs (height =310!)
# str buttonsLabel     label to go to left of button menu
# str tabs             list of the tabs to create. no whitespace in tab names.
# str titles           list of titles corresponding to each tab.  shown on buttons.
# str tooltips         list of tooltips to appear over buttons. optional.
# int extraTopFrame    whether to make another frame at top for a module to use
# str firstTab         name of tab to raise first (defaults to first tab in list)
#
# .END
#-------------------------------------------------------------------------------
proc TabbedFrame {arrayName containerFrame buttonsLabel tabs titles \
    {tooltips ""} {extraTopFrame "0"} {firstTab ""}} {
    global Gui Widgets $arrayName

    # get the global array.
    upvar #0 $arrayName globalArray

    #-------------------------------------------
    # Container frame
    #-------------------------------------------
    set f $containerFrame

    ###### make the top frame (sunken with dark background) ####
    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fTop -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    set fTop $f.fTop

    ##### make the bottom frame (lighter colored) ######
    # height 310 needed to put the tab-to frames inside!
    frame $f.fTabbedFrame -bg $Gui(activeWorkspace) -height 310
    pack $f.fTabbedFrame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    set fBottom $f.fTabbedFrame   


    #-------------------------------------------
    # Container->Top frame
    #-------------------------------------------
    set f $fTop
    set topFrames ""
    if {$extraTopFrame == 1} {
    lappend topFrames Extra
    }
    lappend topFrames Buttons

    foreach frame $topFrames {
    frame $f.fTabbedFrame$frame -bg $Gui(backdrop)
    pack $f.fTabbedFrame$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    set f$frame $f.fTabbedFrame$frame
    }

    #-------------------------------------------
    # Container->Top->Extra frame
    #-------------------------------------------

    # With the extra frame, users can add their own things 
    # above the buttons for tabbing.
    # For example, MeasureVol puts in a Volume Select menu.
    if {$extraTopFrame == 1} {
    set globalArray(TabbedFrame,$containerFrame,extraFrame) $fExtra
    }

    #-------------------------------------------
    # Container->Top->Buttons frame
    #-------------------------------------------
    set f $fButtons

    # set button width to max word length
    set width 0
    foreach title $titles {
    if {[expr [string length $title] +2] > $width} {
        set width [expr [string length $title] +2]
    }
    }
    # label next to the buttons
    eval {label $f.l -text $buttonsLabel} $Gui(BLA)

    # make buttons for navigation btwn frames
    frame $f.f -bg $Gui(backdrop)
    foreach tab $tabs title $titles {
    eval {radiobutton $f.f.r$tab \
        -text "$title" \
        -command "TabbedFrameTab $fBottom.f$tab" \
        -variable "$arrayName\(TabbedFrame,$containerFrame,tab)" \
        -value $tab -width  $width \
        -indicatoron 0} $Gui(WRA)
    pack $f.f.r$tab -side left -padx 0
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    # add tooltips, if there's one for every tab
    if {[llength $tooltips] == [llength $tabs]} {
    foreach tab $tabs tip $tooltips {
        TooltipAdd $f.f.r$tab $tip
    }
    }

    #-------------------------------------------
    # Container->Bottom frame
    #-------------------------------------------
    set f $fBottom
    
    foreach tab $tabs {
    frame $f.f$tab -bg $Gui(activeWorkspace)
    place $f.f$tab -in $f -relheight 1.0 -relwidth 1.0
    set globalArray(TabbedFrame,$containerFrame,f$tab) $f.f$tab
    }


    ###### Make the first tab active #####
    if {$firstTab == ""} {
    set firstTab [lindex $tabs 0]
    }
    # press first button
    set globalArray(TabbedFrame,$containerFrame,tab) $firstTab
    # go to first tab
    raise $fBottom.f$firstTab
}

#-------------------------------------------------------------------------------
# .PROC TabbedFrameTab
# Raise and focus on the passed frame.
# .ARGS
# widget frame the frame to raise
# .END
#-------------------------------------------------------------------------------
proc TabbedFrameTab {frame} {

    raise $frame
    focus $frame

}

#-------------------------------------------------------------------------------
# .PROC TabbedFrameInvoke
# Invoke the radio button that changes the tabbed pane that's raised. Call after using
# the Tab proc to change the the tabbed frame, ie Tab Editor row1 Volumes, otherwise
# the tabbed pane can't be seen.
# .ARGS
# windowpath containerFrame the frame as passed into TabbedFrame
# string buttonName the name of the button to invoke, as passed as a tab to TabbedFrame
# .END
#-------------------------------------------------------------------------------
proc TabbedFrameInvoke {containerFrame buttonName} {
    ${containerFrame}.fTop.fTabbedFrameButtons.f.r${buttonName} invoke
}

