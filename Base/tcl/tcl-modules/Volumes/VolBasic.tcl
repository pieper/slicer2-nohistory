#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolBasic.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:04 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        VolBasic.tcl
# PROCEDURES:  
#   VolBasicInit
#   VolBasicBuildGUI
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC VolBasicInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBasicInit {} {
    global Volume


    # Define Procedures for communicating with Volumes.tcl
    #---------------------------------------------
    set m VolBasic
    # procedure for building GUI in this module's frame
    set Volume(readerModules,$m,procGUI)  ${m}BuildGUI

    
    # Define Module Description to be used by Volumes.tcl
    #---------------------------------------------

    # name for menu button
    set Volume(readerModules,$m,name)  Basic

    # tooltip for help
    set Volume(readerModules,$m,tooltip)  \
            "This tab displays basic information\n
    for the currently selected volume."
}

#-------------------------------------------------------------------------------
# .PROC VolBasicBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBasicBuildGUI {parentFrame} {
    global Gui Volume

    #-------------------------------------------
    # Props->Bot->Basic frame
    #-------------------------------------------
    set f $parentFrame

    frame $f.fVolume  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fVolume $f.fApply \
        -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Basic->fVolume frame
    #-------------------------------------------

    set f $parentFrame.fVolume

    #DevAddFileBrowse $f Volume firstFile "First Image File:" "VolumesSetFirst" "" ""  "Browse for the first Image file" 
    # Open this file as an absolute, due to getting errors if opening a volume in a sub dir of the mrml dir
    DevAddFileBrowse $f Volume firstFile "First Image File:" "VolumesSetFirst" "" "\$Volume(DefaultDir)" "Open" "Browse for the first Image file" "Browse to the first file in the volume" "Absolute"

    bind $f.efile <Tab> "VolumesSetLast"

    frame $f.fLast     -bg $Gui(activeWorkspace)
    frame $f.fHeaders  -bg $Gui(activeWorkspace)
    frame $f.fLabelMap -bg $Gui(activeWorkspace)
    frame $f.fOptions  -bg $Gui(activeWorkspace)
    frame $f.fDesc     -bg $Gui(activeWorkspace)

    pack $f.fLast $f.fHeaders $f.fLabelMap $f.fOptions \
        $f.fDesc -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    # Last
    set f $parentFrame.fVolume.fLast

    DevAddLabel $f.lLast "Number of Last Image:"
    eval {entry $f.eLast -textvariable Volume(lastNum)} $Gui(WEA)
    pack $f.lLast -side left -padx $Gui(pad)
    pack $f.eLast -side left -padx $Gui(pad) -expand 1 -fill x

    # Headers
    set f $parentFrame.fVolume.fHeaders

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns -side left -pady 5

    DevAddLabel $f.fTitle.l "Image Headers:"
    pack $f.fTitle.l -side left -padx $Gui(pad) -pady 0

    foreach text "Auto Manual" \
        value "1 0" \
        width "5 7" {
        eval {radiobutton $f.fBtns.rMode$value -width $width \
            -text "$text" -value "$value" -variable Volume(readHeaders) \
            -indicatoron 0} $Gui(WCA)
        pack $f.fBtns.rMode$value -side left -padx 0 -pady 0
    }

    # LabelMap
    set f $parentFrame.fVolume.fLabelMap

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
       pack $f.fTitle $f.fBtns -side left -pady 5

    DevAddLabel $f.fTitle.l "Image Data:"
    pack $f.fTitle.l -side left -padx $Gui(pad) -pady 0

    foreach text "{Grayscale} {Label Map}" \
        value "0 1" \
        width "9 9 " {
        eval {radiobutton $f.fBtns.rMode$value -width $width \
            -text "$text" -value "$value" -variable Volume(labelMap) \
            -indicatoron 0 } $Gui(WCA)
        pack $f.fBtns.rMode$value -side left -padx 0 -pady 0
    }

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

        DevAddButton $f.bApply "Apply" "VolumesPropsApply; RenderAll" 8
        DevAddButton $f.bCancel "Cancel" "VolumesPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad)

}
