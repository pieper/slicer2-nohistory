#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: RealignResample.tcl,v $
#   Date:      $Date: 2006/04/27 19:16:19 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        RealignResample.tcl
# PROCEDURES:  
#   RealignResampleInit
#   RealignResampleUpdateMRML
#   RealignResampleBuildGUI
#   RealignResampleSetACPCList v
#   RealignResampleSetACPCList v
#   RealignResampleSetVolume v
#   AutoSpacing
#   AutoExtent
#   AutoExtentLR
#   AutoExtentIS
#   AutoExtentPA
#   IsoSpacingLR
#   IsoSpacingIS
#   IsoSpacingPA
#   RealignResampleSaveAs value
#   RealignCalculate
#   Resample
#   Write
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC RealignResampleInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealignResampleInit {} {
    global RealignResample Module Volume Line Matrix

    set m RealignResample
    set Module($m,overview) "This module realigns and resamples using vtkImageReslice"
    set Module($m,author) "Jacob Albertson, SPL, jacob@bwh.harvard.edu"
    set Module($m,category) "Alpha"
    
    set Module($m,row1List) "Realign Resample Help"
    #    set Module($m,row1Name) "{Realign} {Resample} {Help}"
    set Module($m,row1Name) "{Realign} {Help}"
    set Module($m,row1,tab) Realign
    
    set Module($m,procGUI) RealignResampleBuildGUI
    set Module($m,procMRML) RealignResampleUpdateMRML
  
    # took this out for the release, as Morphometrics is removed due to instability
#    set Module($m,depend) "Morphometrics"

    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.9 $} {$Date: 2006/04/27 19:16:19 $}]

    set Matrix(volume) $Volume(idNone)
    set Matrix(RealignResampleVolumeName2) None
    set RealignResample(SaveAs) None
    set RealignResample(ACPCList) None
    set RealignResample(MidlineList) None

}

#-------------------------------------------------------------------------------
# .PROC RealignResampleUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealignResampleUpdateMRML {} {
    global Matrix Volume Fiducials RealignResample

    # See if the volume for each menu actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
    if {[lsearch $Volume(idList) $Matrix(volume) ] == -1} {
        RealignResampleSetVolume2 $n
    }

    # Menu of Volumes 
    # ------------------------------------
    set m $Matrix(mbVolume2).m
    $m delete 0 end
    foreach v $Volume(idList) {
        if {$v != $Volume(idNone)} {
            $m add command -label "[Volume($v,node) GetName]" -command "RealignResampleSetVolume2 $v"
        }
    }
    # Menu ACPC
    # ------------------------------------
    set m $RealignResample(mbACPC).m
    $m delete 0 end
    $m add command -label "None" -command "RealignResampleSetACPCList None"
    foreach v $Fiducials(listOfNames) {
    $m add command -label "$v" -command "RealignResampleSetACPCList $v"
    }
    # Menu Midline
    # ------------------------------------
    set m $RealignResample(mbMidline).m
    $m delete 0 end
    $m add command -label "None" -command "RealignResampleSetMidlineList None"
    foreach v $Fiducials(listOfNames) {
    $m add command -label "$v" -command "RealignResampleSetMidlineList $v"
    }
}
# NAMING CONVENTION:
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
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC RealignResampleBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealignResampleBuildGUI {} {
    global Gui RealignResample Module Volume Line Matrix Fiducials
    
    set help "
    The RealignResample module realigns a volume based on a transformation matrix. It can also resample the volume by changing the extent and spacing. Finally it can make a transform using a list of fiducials. The source code is in slicer2/Modules/vtkRealignResample/tcl/RealignResample.tcl.
       "
    regsub -all "\n" $help {} help
    MainHelpApplyTags RealignResample $help
    MainHelpBuildGUI RealignResample

    #-------------------------------------------
    # Realign frame
    #-------------------------------------------
    set fRealign $Module(RealignResample,fRealign)
    set f $fRealign
    
    foreach frame "Matrix Midline ACPC Calculate" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    $f.fCalculate config -relief groove -bd 3 
    #-------------------------------------------
    # Realign->Matrix
    #-------------------------------------------
    set f $fRealign.fMatrix

    DevAddLabel $f.lActive "Matrix: " 
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20  -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) -pady $Gui(pad)
    lappend Matrix(mbActiveList) $f.mbActive
    lappend Matrix(mActiveList)  $f.mbActive.m
    
    #-------------------------------------------
    # Realign->Midline
    #-------------------------------------------   
    set f $fRealign.fMidline
    
    DevAddLabel $f.lMidline "Midline List (>3):"
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20  -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    lappend Fiducials(mbActiveList) $f.mbActive
    lappend Fiducials(mActiveList)  $f.mbActive.m
    pack $f.lMidline $f.mbActive -side left -padx $Gui(pad) 
    set RealignResample(mbMidline) $f.mbActive

     
    #-------------------------------------------
    # Realign->ACPC
    #-------------------------------------------   
    set f $fRealign.fACPC
    
    DevAddLabel $f.lACPC "ACPC List (2):"
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20  -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    lappend Fiducials(mbActiveList) $f.mbActive
    lappend Fiducials(mActiveList)  $f.mbActive.m
    pack $f.lACPC $f.mbActive -side left -padx $Gui(pad) 
    set RealignResample(mbACPC) $f.mbActive
        
    #-------------------------------------------
    # Realign->Calculate
    #-------------------------------------------
    set f $fRealign.fCalculate
  
    DevAddButton $f.bCalculate "Calculate Transform"  RealignCalculate 
    pack $f.bCalculate  -side top -padx $Gui(pad) -pady $Gui(pad)
    
    #kquintus: commented Resample Tag: In future module "Transform Volume" should be used for resampling
    #-------------------------------------------
    # Resample
    #-------------------------------------------

         set fResample $Module(RealignResample,fResample)
         set f $fResample

         foreach frame "Volume Matrix NewVolume OutputSpacing AutoSpacing ImageSize SetExtent AutoExtent InterpolationMode BeginResample SaveAs BeginSave" {
         frame $f.f$frame -bg $Gui(activeWorkspace)
    #    pack $f.f$frame -side top -padx 0 -pady 0 -fill x
        }

    #-------------------------------------------
    # Resample->Volume
    #-------------------------------------------
      set f $fResample.fVolume
    
         DevAddLabel $f.lVolume "Volume: "
         eval {menubutton $f.mbVolume -text "None" -relief raised -bd 2 -width 20 -menu $f.mbVolume.m} $Gui(WMBA)
         eval {menu $f.mbVolume.m} $Gui(WMA)
    
     #    pack $f.lVolume $f.mbVolume -side left -padx $Gui(pad) -pady $Gui(pad)
         set Matrix(mbVolume2) $f.mbVolume 

    #-------------------------------------------
    # Resample->Matrix
    #-------------------------------------------
     set f $fResample.fMatrix
         DevAddLabel $f.lActive "Matrix: " 
        eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20  -menu $f.mbActive.m} $Gui(WMBA)
         eval {menu $f.mbActive.m} $Gui(WMA)
      #   pack $f.lActive $f.mbActive -side left -padx $Gui(pad) -pady $Gui(pad)
        lappend Matrix(mbActiveList) $f.mbActive
         lappend Matrix(mActiveList)  $f.mbActive.m
    

    #-------------------------------------------
    # Resample->NewVolume
    #-------------------------------------------
     set f $fResample.fNewVolume
   
         DevAddLabel $f.lNewVolume "New Volume: "
         eval {entry $f.eNewVolume -width 30 -textvariable RealignResample(NewVolume) } $Gui(WEA)
         #set the new name to the oldname + _realign
        set RealignResample(NewVolume) "[Volume($Matrix(volume),node) GetName]_realign"
       #  pack $f.lNewVolume $f.eNewVolume -side left -padx $Gui(pad) -pady $Gui(pad)
    

    #-------------------------------------------
    # Resample->Pixel Size
    #-------------------------------------------   
       set f $fResample.fOutputSpacing
         eval {label $f.lOutputSpacing -text "New Spacing"} $Gui(WLA)
        # pack $f.lOutputSpacing -side top -padx $Gui(pad) -pady $Gui(pad)
         eval {label $f.lOutputSpacingLR -text "LR:"} $Gui(WLA)
         eval {entry $f.eOutputSpacingLR -width 6 -textvariable RealignResample(OutputSpacingLR) } $Gui(WEA)
         eval {label $f.lOutputSpacingPA -text "PA:"} $Gui(WLA)
        eval {entry $f.eOutputSpacingPA -width 6 -textvariable RealignResample(OutputSpacingPA) } $Gui(WEA)
         eval {label $f.lOutputSpacingIS -text "IS:"} $Gui(WLA)
         eval {entry $f.eOutputSpacingIS -width 6 -textvariable RealignResample(OutputSpacingIS) } $Gui(WEA)
        # pack $f.lOutputSpacingLR $f.eOutputSpacingLR $f.lOutputSpacingPA $f.eOutputSpacingPA $f.lOutputSpacingIS $f.eOutputSpacingIS -side left -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Resample->Auto Spacing
    #-------------------------------------------   
       set f $fResample.fAutoSpacing
         DevAddButton $f.bAutoSpacing "Original Spacing"  AutoSpacing
         #pack $f.bAutoSpacing -side left -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Resample->Output Extent
    #-------------------------------------------   
     set f $fResample.fImageSize 

         eval {label $f.lOutputExtent -text "New Dimensions"} $Gui(WLA)
        # pack $f.lOutputExtent -side top -padx $Gui(pad) -pady $Gui(pad)
         eval {label $f.lOutputExtentLR -text "LR:"} $Gui(WLA)
         eval {entry $f.eOutputExtentLR -width 6 -textvariable RealignResample(OutputExtentLR) } $Gui(WEA)
         eval {label $f.lOutputExtentPA -text "PA:"} $Gui(WLA)
         eval {entry $f.eOutputExtentPA -width 6 -textvariable RealignResample(OutputExtentPA) } $Gui(WEA)
        eval {label $f.lOutputExtentIS -text "IS:"} $Gui(WLA)
        eval {entry $f.eOutputExtentIS -width 6 -textvariable RealignResample(OutputExtentIS) } $Gui(WEA)
         #pack $f.lOutputExtentLR $f.eOutputExtentLR $f.lOutputExtentPA $f.eOutputExtentPA $f.lOutputExtentIS $f.eOutputExtentIS -side left -padx $Gui(pad) -pady $Gui(pad)
    
    #------------------------------------------
    # Resample->Set Extent
    #-------------------------------------------   
         set f $fResample.fSetExtent
         DevAddButton $f.bIsoExtentLR " Auto LR "  AutoExtentLR
         DevAddButton $f.bIsoExtentPA " Auto PA "  AutoExtentPA
         DevAddButton $f.bIsoExtentIS " Auto IS "  AutoExtentIS
         #pack $f.bIsoExtentLR  $f.bIsoExtentPA $f.bIsoExtentIS -side left -padx $Gui(pad)
    
    #-------------------------------------------
    # Resample->Auto Extent
    #-------------------------------------------   
         set f $fResample.fAutoExtent
         DevAddButton $f.bAutoExtent "Auto Dimension"  AutoExtent
        #pack $f.bAutoExtent -side left -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Resample->Interpolation Mode
    #-------------------------------------------
         set f $fResample.fInterpolationMode
         eval {label $f.lInterpolationMode -text "Interpolation Mode:"} $Gui(WLA)
    
         #Create label foreach type of interpolation
         foreach label {"NearestNeighbor" "Linear" "Cubic"} text {"Nearest Neighbor" "Linear" "Cubic"} {
            eval {radiobutton $f.rb$label -text $text -variable RealignResample(InterpolationMode) -value $label} $Gui(WLA)
         }
         set RealignResample(InterpolationMode) Cubic
         #pack $f.lInterpolationMode -side top -padx $Gui(pad) -pady $Gui(pad)
         #pack $f.rbNearestNeighbor $f.rbLinear $f.rbCubic -side left -anchor w -padx 1 -pady $Gui(pad)

    #-------------------------------------------
    # Resample->Begin Resample
    #-------------------------------------------
       set f $fResample.fBeginResample
    
         DevAddButton $f.bBeginResample "Resample"  Resample

         #pack $f.bBeginResample -side top -padx $Gui(pad) -pady $Gui(pad)
    
         RealignResampleUpdateMRML

    #-------------------------------------------
    # Resample->BeginSave
    #-------------------------------------------
        set f $fResample.fBeginSave
    
         DevAddButton $f.bBeginSave "Save"  Write

   #      pack $f.bBeginSave -side top -padx $Gui(pad) -pady $Gui(pad)
    
         RealignResampleUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC RealignResampleSetACPCList
#
# .ARGS
# list v defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc RealignResampleSetACPCList {{v ""}} {
    global Matrix Volume RealignResample

    set RealignResample(ACPCList) "$v"
    $RealignResample(mbACPC) config -text "$v"
    if {$::Module(verbose)} { puts "ACPC List: $v" }
}

#-------------------------------------------------------------------------------
# .PROC RealignResampleSetACPCList
#
# .ARGS
# list v defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc RealignResampleSetMidlineList {{v ""}} {
    global Matrix Volume RealignResample

    set RealignResample(MidlineList) "$v"
    $RealignResample(mbMidline) config -text "$v"
    if {$::Module(verbose)} {  puts "Midline List: $v" }
}

#-------------------------------------------------------------------------------
# .PROC RealignResampleSetVolume
#
# .ARGS
# list v defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc RealignResampleSetVolume2 {{v ""}} {
    global Matrix Volume RealignResample

    if {$v == ""} {
        set v $Matrix(volume)
    } else {
        set Matrix(volume) $v
    }
    catch "ModelRasToVtk Delete"
    vtkMatrix4x4 ModelRasToVtk
    set position [Volume($Matrix(volume),node) GetPositionMatrix]
    if {$::Module(verbose)} { puts "$position" }
    ModelRasToVtk Identity
    set ii 0
    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            # Put the element from the position string
            ModelRasToVtk SetElement $i $j [lindex $position $ii]
            incr ii
        }
    # Remove the translation elements
    ModelRasToVtk SetElement $i 3 0
    }
    # add a 1 at the for  M(4,4)
    ModelRasToVtk SetElement 3 3 1
    # Matrix now is
    # a b c 0
    # d e f 0
    # g h i 0 
    # 0 0 0 1
    # a -> i is either -1 0 or 1 depending on 
    # the original orientation of the volume

    set spacing [split [[Volume($Matrix(volume),vol) GetOutput] GetSpacing]]     
    set point  [ModelRasToVtk MultiplyPoint [lindex $spacing 0] [lindex $spacing 1] [lindex $spacing 2] 1 ]
    if {$::Module(verbose)} {  puts "LR PA IS $point"} 
    set RealignResample(OutputSpacingLR) [expr abs([lindex $point 0])]
    set RealignResample(OutputSpacingPA) [expr abs([lindex $point 1])]
    set RealignResample(OutputSpacingIS) [expr abs([lindex $point 2])]
    
    set extent [split [[Volume($Matrix(volume),vol) GetOutput] GetWholeExtent]]     
    if {$::Module(verbose)} { puts $extent }
    set dimension  [ModelRasToVtk MultiplyPoint [lindex $extent 1] [lindex $extent 3] [lindex $extent 5] 1 ]
    set RealignResample(OutputExtentLR) [expr round(abs([lindex $dimension 0])) + 1]
    set RealignResample(OutputExtentPA) [expr round(abs([lindex $dimension 1])) + 1]
    set RealignResample(OutputExtentIS) [expr round(abs([lindex $dimension 2])) + 1]
    
    ModelRasToVtk Delete
    set RealignResample(NewVolume) "[Volume($v,node) GetName]_realign"

    #Display what the user picked from the menu as the Volume to move
    $Matrix(mbVolume2) config -text "[Volume($v,node) GetName]"

    #Set Matrix(FidAlignVolumeName) to be the name of the volume to move
    set Matrix(RealignResampleVolumeName2) "[Volume($v,node) GetName]"

    #Print out what the user has set as the volume to move
    if {$::Module(verbose)} {
        puts "RealignResampleSetVolume2: this is the VolumeName: $Matrix(RealignResampleVolumeName2)"   
    }
}
#-------------------------------------------------------------------------------
# .PROC AutoSpacing
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AutoSpacing {} {
    global Matrix Volume RealignResample

    catch "ModelRasToVtk Delete"
    vtkMatrix4x4 ModelRasToVtk
    set position [Volume($Matrix(volume),node) GetPositionMatrix]
    if {$::Module(verbose)} { puts "$position" }
    ModelRasToVtk Identity
    set ii 0
    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            # Put the element from the position string
            ModelRasToVtk SetElement $i $j [lindex $position $ii]
            incr ii
        }
    # Remove the translation elements
    ModelRasToVtk SetElement $i 3 0
    }
    # add a 1 at the for  M(4,4)
    ModelRasToVtk SetElement 3 3 1
    # Matrix now is
    # a b c 0
    # d e f 0
    # g h i 0 
    # 0 0 0 1
    # a -> i is either -1 0 or 1 depending on 
    # the original orientation of the volume

    set spacing [split [[Volume($Matrix(volume),vol) GetOutput] GetSpacing]]     
    set point  [ModelRasToVtk MultiplyPoint [lindex $spacing 0] [lindex $spacing 1] [lindex $spacing 2] 1 ]
    if {$::Module(verbose)} {  puts "LR PA IS $point" }
    set RealignResample(OutputSpacingLR) [expr abs([lindex $point 0])]
    set RealignResample(OutputSpacingPA) [expr abs([lindex $point 1])]
    set RealignResample(OutputSpacingIS) [expr abs([lindex $point 2])]
    ModelRasToVtk Delete
}

#-------------------------------------------------------------------------------
# .PROC AutoExtent
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AutoExtent {} {
    global RealignResample Module Matrix Volume
    
    #Set default values
    # Make a RAS to VTK matrix for realign resample
    # based on the position matrix
    catch "ModelRasToVtk Delete"
    vtkMatrix4x4 ModelRasToVtk
    set position [Volume($Matrix(volume),node) GetPositionMatrix]

    ModelRasToVtk Identity
    set ii 0
    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            # Put the element from the position string
            ModelRasToVtk SetElement $i $j [lindex $position $ii]
            incr ii
        }
    # Remove the translation elements
    ModelRasToVtk SetElement $i 3 0
    }
    # add a 1 at the for  M(4,4)
    ModelRasToVtk SetElement 3 3 1

    # Now we can build the Vtk1ToVtk2 matrix based on
    # ModelRasToVtk and ras1toras2
    # vtk1tovtk2 = inverse(rastovtk) ras1toras2 rastovtk
    # RasToVtk
    catch "RasToVtk Delete"
    vtkMatrix4x4 RasToVtk
    RasToVtk DeepCopy ModelRasToVtk    
    # Inverse Matrix RasToVtk
    catch "InvRasToVtk Delete"
    vtkMatrix4x4 InvRasToVtk
    InvRasToVtk DeepCopy ModelRasToVtk
    InvRasToVtk Invert
    # Ras1toRas2 given by the slicer MRML tree
    catch "Ras1ToRas2 Delete"    
    vtkMatrix4x4 Ras1ToRas2
    Ras1ToRas2 DeepCopy [[Matrix($Matrix(activeID),node) GetTransform] GetMatrix]
    # Now build Vtk1ToVtk2
    catch "Vtk1ToVtk2 Delete"    
    vtkMatrix4x4 Vtk1ToVtk2
    Vtk1ToVtk2 Identity
    Vtk1ToVtk2 Multiply4x4 Ras1ToRas2 RasToVtk  Vtk1ToVtk2
    Vtk1ToVtk2 Multiply4x4 InvRasToVtk  Vtk1ToVtk2 Vtk1ToVtk2
    
    # Get the origin, spacing and extent of the input volume
    catch "InVolume Delete"
    vtkImageData InVolume
    InVolume DeepCopy [Volume($Matrix(volume),vol) GetOutput]
    catch "ici Delete"    
    vtkImageChangeInformation ici
    ici CenterImageOn
    ici SetInput InVolume
    ici Update
    set volume [ici GetOutput]
    set inorigin [split [$volume GetOrigin]]
    set inwholeExtent [split [$volume GetWholeExtent]]
    set inspacing [split [$volume GetSpacing]]

    # Transforms the corners of the extent according to Vtk1ToVtk2
    # and finds the min/max coordinates in each dimension
    for {set i 0} {$i < 3} {incr i} {
    set bounds([expr 2 * $i]) 10000000
    set bounds([expr 2*$i+1])  -10000000
    }
    for {set i 0} {$i < 8} {incr i} {
    # setup the bounding box with origin and spacing
    set point(0) [expr [lindex $inorigin 0] + [expr [lindex $inwholeExtent [expr $i %  2]] * [lindex $inspacing 0] ]]
    set point(1) [expr [lindex $inorigin 1] + [expr [lindex $inwholeExtent [expr 2 + ($i / 2) % 2]] * [lindex $inspacing 1]]]
    set point(2) [expr [lindex $inorigin 2] + [expr [lindex $inwholeExtent [expr 4 + ($i / 4) % 2]] * [lindex $inspacing 2]]]
    # applies the transform 
    set newpoint [Vtk1ToVtk2 MultiplyPoint $point(0) $point(1) $point(2) 1]
    set point(0) [lindex $newpoint 0]
    set point(1) [lindex $newpoint 1]
    set point(2) [lindex $newpoint 2]
    # finds max/min in each dimension
    for {set j 0}  {$j < 3} {incr j} {
        if {$point($j) > $bounds([expr 2*$j+1])} {
        set bounds([expr 2*$j+1]) $point($j)
        }
        if {$point($j) < $bounds([expr 2*$j])} {
        set bounds([expr 2*$j]) $point($j)
        }
    }
    }
    
    # Transforms in RAS space
    set outspacing [InvRasToVtk MultiplyPoint $RealignResample(OutputSpacingLR) $RealignResample(OutputSpacingPA) $RealignResample(OutputSpacingIS) 1]
    set spacing(0) [expr abs([lindex $outspacing 0])]
    set spacing(1) [expr abs([lindex $outspacing 1])]
    set spacing(2) [expr abs([lindex $outspacing 2])]
    # Compute the new extent
    for {set i 0} {$i < 3} {incr i} {
    set outExt($i) [expr round (( $bounds([expr 2*$i+1])- $bounds([expr 2 * $i])) / $spacing($i))] 
    }
    # Go back in RAS space 
    set outExtRAS [RasToVtk MultiplyPoint $outExt(0) $outExt(1) $outExt(2) 1]
    set RealignResample(OutputExtentLR) [expr 1 + round(abs([lindex $outExtRAS 0]))]
    set RealignResample(OutputExtentPA) [expr 1 + round(abs([lindex $outExtRAS 1]))]
    set RealignResample(OutputExtentIS) [expr 1 + round(abs([lindex $outExtRAS 2]))]
               
    InVolume Delete
    ici Delete
    ModelRasToVtk Delete
    Ras1ToRas2 Delete
    RasToVtk Delete
    InvRasToVtk Delete
    Vtk1ToVtk2 Delete
    RenderAll
}
#-------------------------------------------------------------------------------
# .PROC AutoExtentLR
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AutoExtentLR {} {
    global RealignResample
    set tmpZ $RealignResample(OutputExtentPA)
    set tmpY $RealignResample(OutputExtentIS)
    AutoExtent
    set RealignResample(OutputExtentPA) $tmpZ
    set RealignResample(OutputExtentIS) $tmpY

}  
#-------------------------------------------------------------------------------
# .PROC AutoExtentIS
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AutoExtentIS {} {
    global RealignResample
    set tmpZ $RealignResample(OutputExtentPA)
    set tmpX $RealignResample(OutputExtentLR)
    AutoExtent
    set RealignResample(OutputExtentPA) $tmpZ
    set RealignResample(OutputExtentLR) $tmpX
} 
#-------------------------------------------------------------------------------
# .PROC AutoExtentPA
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AutoExtentPA {} {
    global RealignResample
    set tmpY $RealignResample(OutputExtentIS)
    set tmpX $RealignResample(OutputExtentLR)
    AutoExtent
    set RealignResample(OutputExtentIS) $tmpY
    set RealignResample(OutputExtentLR) $tmpX
} 

#-------------------------------------------------------------------------------
# .PROC IsoSpacingLR
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IsoSpacingLR {} {
    global RealignResample
    set RealignResample(OutputSpacingPA) $RealignResample(OutputSpacingLR)
    set RealignResample(OutputSpacingIS) $RealignResample(OutputSpacingLR)
}  
#-------------------------------------------------------------------------------
# .PROC IsoSpacingIS
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IsoSpacingIS {} {
    global RealignResample
    set RealignResample(OutputSpacingLR) $RealignResample(OutputSpacingIS)
    set RealignResample(OutputSpacingPA) $RealignResample(OutputSpacingIS)
} 
#-------------------------------------------------------------------------------
# .PROC IsoSpacingPA
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IsoSpacingPA {} {
    global RealignResample
    set RealignResample(OutputSpacingLR) $RealignResample(OutputSpacingPA)
    set RealignResample(OutputSpacingIS) $RealignResample(OutputSpacingPA)
} 
  
#-------------------------------------------------------------------------------
# .PROC RealignResampleSaveAs
#
# .ARGS
# string value 
# .END
#-------------------------------------------------------------------------------
proc RealignResampleSaveAs {value} {
    global Matrix RealignResample

    $Matrix(SaveAs) config -text "$value"

    #Set Matrix(FidAlignVolumeName) to be the name of the volume to move
    set RealignResample(SaveAs) "$value"

    #Print out what the user has set as the volume to move
    if {$::Module(verbose)} {  puts "Save As: $value"    }
}

#-------------------------------------------------------------------------------
# .PROC RealignCalculate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RealignCalculate {} {
    global RealignResample Module Matrix Volume Fiducials Point
    if {$::Module(verbose)} { 
        puts $RealignResample(MidlineList)
        puts $RealignResample(ACPCList)
    }
    catch "trans Delete"
    vtkTransform trans
    trans Identity
    trans PostMultiply
    if {$RealignResample(MidlineList) != "None" } {
        if {$::Module(verbose)} {  puts "Doing Midline..." }
    set fids $Fiducials($Fiducials($RealignResample(MidlineList),fid),pointIdList) 
    catch "math Delete"
    vtkMath math
    set x 0
    foreach fid $fids {
        set list($x) [split [FiducialsGetPointCoordinates $fid] " "]
        if {$::Module(verbose)} {  puts "Point $x: $list($x)" }
        incr x
    }
    catch "polydata Delete"
    vtkPolyData polydata
    catch "output Delete"
    vtkPolyData output
    catch "points Delete"
    vtkPoints points
        if {$::Module(verbose)} { puts "Total Number of Points: $x" }
    points SetNumberOfPoints $x
    for {set i 0} {$i < $x} {incr i} {
        points SetPoint $i [lindex $list($i) 0] [lindex $list($i) 1] [lindex $list($i) 2]
    }
    polydata SetPoints points
        if {$::Module(verbose)} { puts "Calling vtkPrincipalAxesAlign" } 
    catch "pa Delete"
    vtkPrincipalAxesAlign pa
    if {$::Module(verbose)} { 
        puts "Making vtkPoints"
        puts "Set Input to PrincipalAxesAlign"
    }
    pa SetInput polydata
        if {$::Module(verbose)} { puts "Executing PrincipalAxesAlign" } 
    pa Update
    set normal [pa GetZAxis]
    set nx [lindex $normal 0 ]
    set ny [lindex $normal 1 ]
    set nz [lindex $normal 2 ]
        if {$::Module(verbose)} { puts "$nx $ny $nz"} 
    
    set Max $nx
    if {[expr $ny*$ny] > [expr $Max*$Max]} {
        set Max $ny
    }
    if {[expr $nz*$nz] > [expr $Max*$Max]} {
        set Max $nz
    }
    set sign 1
    if {$Max < 0} {
        set sign -1
    }
    
    # Prepares the rotation matrix
    catch "mat Delete"
    vtkMatrix4x4 mat
    mat Identity
    set i 0
    foreach point [pa GetZAxis] {
        mat SetElement $i 0 [expr $sign * $point]
        incr i
    }    
    set oneAndAlpha [expr 1 + [mat GetElement 0 0]]    
    mat SetElement 0 1 [expr -1 * [mat GetElement 1 0]]    
    mat SetElement 0 2 [expr -1 * [mat GetElement 2 0]] 
    mat SetElement 2 1 [expr -1 * [mat GetElement 1 0] * [mat GetElement 2 0] / $oneAndAlpha]
    mat SetElement 1 2 [expr -1 * [mat GetElement 1 0] * [mat GetElement 2 0] / $oneAndAlpha]
    mat SetElement 1 1 [expr 1  - [mat GetElement 1 0] * [mat GetElement 1 0] / $oneAndAlpha]
    mat SetElement 2 2 [expr 1  - [mat GetElement 2 0] * [mat GetElement 2 0] / $oneAndAlpha]
    # Check the sign of the determinant    
    set det [mat Determinant]
        if {$::Module(verbose)} { puts "Determinant $det"} 
    
    catch "matInverse Delete"
    vtkMatrix4x4 matInverse
    matInverse DeepCopy mat
    matInverse Invert
    trans SetMatrix matInverse
    mat Delete
    matInverse Delete
    pa Delete
    points Delete
    polydata Delete
    output Delete
    math Delete
    }

    if {$RealignResample(ACPCList) != "None"} {
        if {$::Module(verbose)} { puts "Doing ACPC..." } 
    set acpc $Fiducials($Fiducials($RealignResample(ACPCList),fid),pointIdList) 
    set y 0
    foreach fid $acpc {
        if { $y < 2 } {
        set ACPCpoints($y) [split [FiducialsGetPointCoordinates $fid] " "]
            if {$::Module(verbose)} { puts "ACPC Point $y: $ACPCpoints($y)" }
        incr y
        }
    }
    set top [expr [lindex $ACPCpoints(0) 2] - [lindex $ACPCpoints(1) 2]]
    set bot [expr [lindex $ACPCpoints(0) 1] - [lindex $ACPCpoints(1) 1]]
    set tangent [expr atan( $top / $bot) * (180.0/(4.0*atan(1.0)))]
        if {$::Module(verbose)} { puts $tangent } 
    trans RotateX [expr $tangent * -1]
    }
    set det [[trans GetMatrix] Determinant]
    if {$::Module(verbose)} { puts "Determinant $det" }
    [Matrix($Matrix(activeID),node) GetTransform] SetMatrix [trans GetMatrix]
    MainUpdateMRML
    RenderAll
    trans Delete
    puts "Done"
}


#-------------------------------------------------------------------------------
# .PROC Resample
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Resample {} {
    global RealignResample Module Matrix Volume
       
    if {$Matrix(activeID) == ""} {
        DevErrorWindow "You must set an active matrix first..."
        return
    }
    # Create a new Volume node
    set newvol [DevCreateNewCopiedVolume  $Matrix(volume) "" "$RealignResample(NewVolume)"]
    set Matrix(NewVolume) $newvol
    set node [Volume($newvol,vol) GetMrmlNode]
    Mrml(dataTree) RemoveItem $node
    Mrml(dataTree) AddItem $node
    
    # Create a new vtkImageData
    catch "Target Delete"
    vtkImageData Target
    Target DeepCopy [Volume($Matrix(volume),vol) GetOutput]
    Volume($newvol,vol) SetImageData Target

    MainUpdateMRML
    MainVolumesUpdate $newvol

    # Make a RAS to VTK matrix for realign resample
    # based on the position matrix
    catch "ModelRasToVtk Delete"
    vtkMatrix4x4 ModelRasToVtk
    set position [Volume($Matrix(volume),node) GetPositionMatrix]
    ModelRasToVtk Identity
    set ii 0
    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            # Put the element from the position string
            ModelRasToVtk SetElement $i $j [lindex $position $ii]
            incr ii
        }
    # Remove the translation elements
    ModelRasToVtk SetElement $i 3 0
    }
    # add a 1 at the for  M(4,4)
    ModelRasToVtk SetElement 3 3 1
    # Matrix now is
    # a b c 0
    # d e f 0
    # g h i 0 
    # 0 0 0 1
    # a -> i is either -1 0 or 1 depending on 
    # the original orientation of the volume
 

    # Now we can build the Vtk1ToVtk2 matrix based on
    # ModelRasToVtk and ras1toras2
    # vtk1tovtk2 = inverse(rastovtk) ras1toras2 rastovtk
    # RasToVtk
    catch "RasToVtk Delete"
    vtkMatrix4x4 RasToVtk
    RasToVtk DeepCopy ModelRasToVtk    
    # Inverse Matrix RasToVtk
    catch "InvRasToVtk Delete"
    vtkMatrix4x4 InvRasToVtk
    InvRasToVtk DeepCopy ModelRasToVtk
    InvRasToVtk Invert
    # Ras1toRas2 given by the slicer MRML tree
    catch "Ras1ToRas2 Delete"
    vtkMatrix4x4 Ras1ToRas2
    Ras1ToRas2 DeepCopy [[Matrix($Matrix(activeID),node) GetTransform] GetMatrix]
    # Now build Vtk1ToVtk2
    catch "Vtk1ToVtk2 Delete"
    vtkMatrix4x4 Vtk1ToVtk2
    Vtk1ToVtk2 Identity
    Vtk1ToVtk2 Multiply4x4 Ras1ToRas2 RasToVtk  Vtk1ToVtk2
    Vtk1ToVtk2 Multiply4x4 InvRasToVtk  Vtk1ToVtk2 Vtk1ToVtk2

    # Setting up for vtkImageReslice
    # Invert the matrix (because we resample the grid not the object)
    Vtk1ToVtk2 Invert
    catch "trans Delete"
    vtkTransform trans
    trans SetMatrix Vtk1ToVtk2 
    # Center the input image
    catch "ici Delete"
    vtkImageChangeInformation ici
    ici CenterImageOn
    ici SetInput Target
    # Set the input of the vtkImageReslice
    catch "reslice Delete"
    vtkImageReslice reslice
    reslice SetInput [ici GetOutput]
    reslice SetResliceTransform trans
    # Set the output spacing to user entered values
    set spacing [InvRasToVtk MultiplyPoint $RealignResample(OutputSpacingLR) $RealignResample(OutputSpacingPA) $RealignResample(OutputSpacingIS) 1]
    set spacex [expr abs([lindex $spacing 0])]
    set spacey [expr abs([lindex $spacing 1])]
    set spacez [expr abs([lindex $spacing 2])]
    reslice SetOutputSpacing $spacex $spacey $spacez

    # Set the extent to user or calculated values
    if {$::Module(verbose)} { puts "Extent: 0 $RealignResample(OutputExtentLR) 0 $RealignResample(OutputExtentPA) 0 $RealignResample(OutputExtentIS)" }
    set dimension [InvRasToVtk MultiplyPoint $RealignResample(OutputExtentLR) $RealignResample(OutputExtentPA) $RealignResample(OutputExtentIS) 1]
    if {$::Module(verbose)} { puts "Extent: $dimension" }
    set extentx [expr round(abs([lindex $dimension 0]))]
    set extenty [expr round(abs([lindex $dimension 1]))]
    set extentz [expr round(abs([lindex $dimension 2]))]
    reslice SetOutputExtent  0 [expr $extentx - 1]\
                         0 [expr $extenty - 1]\
                         0 [expr $extentz - 1] 
    # Set the interpolation mode 
    if {$::Module(verbose)} {  puts "SetInterpolationModeTo$RealignResample(InterpolationMode)" }
    reslice SetInterpolationModeTo$RealignResample(InterpolationMode)
    # Reslice!
    reslice Update
    
    # Store output in the MRML tree
    # and update its properties
    Volume($newvol,vol) SetImageData [reslice GetOutput]
    eval [Volume($newvol,node) SetSpacing  $spacex $spacey $spacez]
    eval [Volume($newvol,node) SetImageRange 1 $extentz]
    eval [Volume($newvol,node) SetDimensions  $extentx $extenty]
    Volume($newvol,node) ComputeRasToIjkFromScanOrder [Volume($newvol,node) GetScanOrder]
    
    MainUpdateMRML
    MainVolumesUpdate $newvol
   
    reslice Delete
    ici Delete
    ModelRasToVtk Delete
    Target Delete
    trans Delete
    Ras1ToRas2 Delete
    RasToVtk Delete
    InvRasToVtk Delete
    Vtk1ToVtk2 Delete
     
    RenderAll
    puts "Done."
     
} 

#-------------------------------------------------------------------------------
# .PROC Write
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Write {} {
    global RealignResample Volume Matrix
    set RealignResample(prefixSave) [file join $Volume(DefaultDir) [Volume($Matrix(NewVolume),node) GetName]]
    set RealignResample(prefixSave) [MainFileSaveVolume $Matrix(NewVolume) $RealignResample(prefixSave)]
      
    MainVolumesWrite $Matrix(NewVolume) $RealignResample(prefixSave)
    MainVolumesSetActive $Matrix(NewVolume)
}
