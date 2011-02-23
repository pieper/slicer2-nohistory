#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolHeader.tcl,v $
#   Date:      $Date: 2006/07/11 03:50:27 $
#   Version:   $Revision: 1.7 $
# 
#===============================================================================
# FILE:        VolHeader.tcl
# PROCEDURES:  
#   VolHeaderInit
#   VolHeaderBuildGUI
#   VolHeaderUpdateGUI
#   VolHeaderCopyParameters
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC VolHeaderInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolHeaderInit {} {
    global Volume Module


    # Define Procedures for communicating with Volumes.tcl
    #---------------------------------------------
    set m VolHeader

    set Volume($m,copyFrom) $Volume(idNone)
       
    # procedure for building GUI in this module's frame
    set Volume(readerModules,$m,procGUI)  ${m}BuildGUI
    set Module(readerModules,$m,procMRML)  ${m}UpdateGUI

    # Define Module Description to be used by Volumes.tcl
    #---------------------------------------------
    # name for menu button
    set Volume(readerModules,$m,name)  Header

    # tooltip for help
    set Volume(readerModules,$m,tooltip)  \
            "This tab displays header information\n
    for the currently selected volume."
}

#-------------------------------------------------------------------------------
# .PROC VolHeaderBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolHeaderBuildGUI {parentFrame} {
    global Gui Volume

    #-------------------------------------------
    # Props->Bot->Header frame
    #-------------------------------------------
    set f $parentFrame

    frame $f.fEntry   -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fEntry $f.fApply \
        -side top -fill x -pady 2

    #-------------------------------------------
    # Props->Bot->Header->Entry frame
    #-------------------------------------------

    #
    ## popup volume selector to copy parameters from existing volume
    #

    DevAddSelectButton Volume $f VolHeader,copyFrom "Copy From:" Pack "Copy header fields from existing volume" 

    #
    # #
    #
        # Entry fields (the loop makes a frame for each variable)
        foreach param "filePattern" name "{File Pattern}" {

            set f $parentFrame.fEntry
            frame $f.f$param   -bg $Gui(activeWorkspace)
            pack $f.f$param -side top -fill x -pady 2

            set f $f.f$param
            eval {label $f.l$param -text "$name:"} $Gui(WLA)
            eval {entry $f.e$param -width 10 -textvariable Volume($param)} $Gui(WEA)
            pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
            pack $f.e$param -side left -padx $Gui(pad) -expand 1 -fill x
        }

        set Volume(entryBoxWidth) 7

        # two entry boxes per line to save space
        # Change: 05/06/03 NA: pack it left to right, width height so 
        # that when tabbing through the boxes the next box will follow 
        # in a left to right manner
        foreach params "{width height} {pixelWidth pixelHeight } "\
                name "{Image Size} {Pixel Size}" \
                tip1 "{width height } {width height }" \
                tip "{units are pixels} {units are mm}" {

            set f $parentFrame.fEntry
            set param [lindex $params 0]
            frame $f.f$param   -bg $Gui(activeWorkspace)
            pack $f.f$param -side top -fill x -pady 2 

            # name label
            set f $f.f$param
            eval {label $f.l$param -text "$name:"} $Gui(WLA)
            pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w

            # value entry boxes with tool tips
            foreach param $params t $tip1 {
                eval {entry $f.e$param -width $Volume(entryBoxWidth) \
                        -textvariable Volume($param)} $Gui(WEA)
                pack $f.e$param -side left -padx $Gui(pad) -fill x -expand yes 
                TooltipAdd $f.e$param "$t: $tip"
            }
        }

        # now back to one box per line
        foreach param "sliceThickness sliceSpacing" \
                name "{Slice Thickness} {Slice Spacing}" {

            set f $parentFrame.fEntry
            frame $f.f$param   -bg $Gui(activeWorkspace)
            pack $f.f$param -side top -fill x -pady 2

            set f $f.f$param
            eval {label $f.l$param -text "$name:"} $Gui(WLA)
            eval {entry $f.e$param -width $Volume(entryBoxWidth)\
                    -textvariable Volume($param)} $Gui(WEA)
            pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
            pack $f.e$param -side left -padx $Gui(pad) -expand 1 -fill x
        }

    # Scan Order Menu
    set f $parentFrame.fEntry
    frame $f.fscanOrder -bg $Gui(activeWorkspace)
    pack $f.fscanOrder -side top -fill x -pady 2
    
    set f $f.fscanOrder
    eval {label $f.lscanOrder -text "Scan Order:"} $Gui(WLA)
    # button text corresponds to default scan order value Volume(scanOrder)
    eval {menubutton $f.mbscanOrder -relief raised -bd 2 \
        -text [lindex $Volume(scanOrderMenu)\
        [lsearch $Volume(scanOrderList) $Volume(scanOrder)]] \
        -width 10 -menu $f.mbscanOrder.menu} $Gui(WMBA)
    lappend Volume(mbscanOrder) $f.mbscanOrder
    eval {menu $f.mbscanOrder.menu} $Gui(WMA)
    
    set m $f.mbscanOrder.menu
    foreach label $Volume(scanOrderMenu) value $Volume(scanOrderList) {
        $m add command -label $label -command "VolumesSetScanOrder $value"
    }
    pack $f.lscanOrder -side left -padx $Gui(pad) -fill x -anchor w
    pack $f.mbscanOrder -side left -padx $Gui(pad) -expand 1 -fill x 

    
    # Scalar Type Menu
    set f $parentFrame.fEntry
    frame $f.fscalarType -bg $Gui(activeWorkspace)
    pack $f.fscalarType -side top -fill x -pady 2
    
    set f $f.fscalarType
    eval {label $f.lscalarType -text "Scalar Type:"} $Gui(WLA)
    eval {menubutton $f.mbscalarType -relief raised -bd 2 \
        -text $Volume(scalarType)\
        -width 10 -menu $f.mbscalarType.menu} $Gui(WMBA)
    set Volume(mbscalarType) $f.mbscalarType
    eval {menu $f.mbscalarType.menu} $Gui(WMA)
    
    set m $f.mbscalarType.menu
    foreach type $Volume(scalarTypeMenu) {
        $m add command -label $type -command "VolumesSetScalarType $type"
    }
    pack $f.lscalarType -side left -padx $Gui(pad) -fill x -anchor w
    pack $f.mbscalarType -side left -padx $Gui(pad) -expand 1 -fill x 
    
    # more Entry fields (the loop makes a frame for each variable)
    foreach param "    gantryDetectorTilt numScalars" \
        name "{Slice Tilt} {Num Scalars}" {

        set f $parentFrame.fEntry
        frame $f.f$param -bg $Gui(activeWorkspace)
        pack $f.f$param -side top -fill x -pady 2

        set f $f.f$param
        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 10 -textvariable Volume($param)} $Gui(WEA)
        pack $f.l$param -side left -padx $Gui(pad) -fill x -anchor w
        pack $f.e$param -side left -padx $Gui(pad) -expand 1 -fill x
    }

    # byte order
    set f $parentFrame.fEntry
    frame $f.fEndian -bg $Gui(activeWorkspace)
    pack $f.fEndian -side top -fill x -pady 2
    set f $f.fEndian

    eval {label $f.l -text "Little Endian (PC,SGI):"} $Gui(WLA)
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.l $f.f -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach value "1 0" text "Yes No" width "4 3" {
        eval {radiobutton $f.f.r$value -width $width \
                        -indicatoron 0 -text $text -value $value \
                        -variable Volume(littleEndian) } $Gui(WCA)
        pack $f.f.r$value -side left -fill x
    }

    #-------------------------------------------
    # Props->Bot->Header->Apply frame
    #-------------------------------------------
    set f $parentFrame.fApply

        DevAddButton $f.bApply "Apply" "VolumesPropsApply; RenderAll" 8
        DevAddButton $f.bCancel "Cancel" "VolumesPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad)

}

#-------------------------------------------------------------------------------
# .PROC VolHeaderUpdateGUI
# Update the node select buttons for this module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolHeaderUpdateGUI {} {
    global VolHeader Volume

    DevUpdateNodeSelectButton Volume Volume VolHeader,copyFrom VolHeader,copyFrom DevSelectNode 1 0 1 VolHeaderCopyParameters
}

#-------------------------------------------------------------------------------
# .PROC VolHeaderCopyParameters
#  Copy header values from selected volume into the fields
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolHeaderCopyParameters {} {
    global VolHeader Volume

    set fromID $Volume(VolHeader,copyFrom)

    set dims [Volume($fromID,node) GetDimensions]
    set Volume(width) [lindex $dims 0]
    set Volume(height) [lindex $dims 1]

    set spacing [Volume($fromID,node) GetSpacing]
    set Volume(pixelWidth) [lindex $spacing 0]
    set Volume(pixelHeight) [lindex $spacing 1]
    set Volume(sliceThickness) [lindex $spacing 2]

    VolumesSetScanOrder [Volume($fromID,node) GetScanOrder]
    VolumesSetScalarType [Volume($fromID,node) GetScalarTypeAsString]

    set Volume(gantryDetectorTilt) [Volume($fromID,node) GetTilt]
    set Volume(numScalars) [Volume($fromID,node) GetNumScalars]
    set Volume(littleEndian) [Volume($fromID,node) GetLittleEndian]
    
}
