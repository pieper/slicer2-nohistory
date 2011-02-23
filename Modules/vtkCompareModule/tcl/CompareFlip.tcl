#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareFlip.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:23 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareFlip.tcl
# PROCEDURES:  
#   CompareModuleInit
#   CompareFlipUpdateMRML
#   CompareFlipSetVolume
#   CompareFlipApply string
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC CompareModuleInit
# Set CompareFlip array to the proper initial values.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareFlipInit {} {
    global CompareFlip Module

    # The id of the volume to flip
    set CompareFlip(VolID) 0

    lappend Module(procMRML) CompareFlipUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC CompareFlipUpdateMRML
# Update volume list on the GUI flip tab
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareFlipUpdateMRML {} {
    global Volume Module CompareFlip

    # See if the volume actually exists.
    # If not, use the None volume
    #
    set n $Volume(idNone)
       if {[lsearch $Volume(idList) $CompareFlip(VolID)] == -1} {
           CompareFlipSetVolume $n
       }

    set m $Module(CompareModule,fFlip).fVolume.mbVolume.m
    $m delete 0 end
    foreach v $Volume(idList) {
        set colbreak [MainVolumesBreakVolumeMenu $m]
        $m add command -label [Volume($v,node) GetName] \
        -command "CompareFlipSetVolume $v" \
        -columnbreak $colbreak
    }
}

#-------------------------------------------------------------------------------
# .PROC CompareFlipSetVolume
# Set the volume to be flipped
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareFlipSetVolume {v} {
    global CompareFlip Volume Module

    # Check if volume exists and use the None if not
    if {[lsearch $Volume(idList) $v] == -1} {
        set v $Volume(idNone)
    }

    # If no change, return
    if {$v == $CompareFlip(VolID)} {return}
    set CompareFlip(VolID) $v

    # Change button text
    set mVolume ${Module(CompareModule,fFlip)}.fVolume.mbVolume
    set conf  "-text [Volume($v,node) GetName]"
    eval $mVolume configure $conf
}

#-------------------------------------------------------------------------------
# .PROC CompareFlipApply
# Flip the selected volume following one of the main 3 axis
# .ARGS
# axis string The axis used as flip reference
# .END
#-------------------------------------------------------------------------------
proc CompareFlipApply {axis} {
  global MultiSlicer CompareFlip Volume

  set v $CompareFlip(VolID)

  set newvec [ IbrowserGetRasToVtkAxis $axis ::Volume($v,node) ]
  foreach { x y z } $newvec { }

  vtkImageFlip flip
  flip SetInput [ ::Volume($v,vol) GetOutput ]

  # now set the flip axis in VTK space
  if { ($x == 1) || ($x == -1) } {
  flip SetFilteredAxis 0
  } elseif { ($y == 1) || ( $y == -1) } {
  flip SetFilteredAxis 1
  } elseif { ($z == 1) || ($z == -1) } {
  flip SetFilteredAxis 2
  }

  ::Volume($v,vol) SetImageData [ flip GetOutput ]
  MainVolumesUpdate $v
  RenderAll

  flip Delete

  MultiSlicer ReformatModified
  MultiSlicer Update
  CompareRenderSlices
}
