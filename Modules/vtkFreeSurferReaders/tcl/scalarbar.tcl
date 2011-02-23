#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: scalarbar.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:42 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        scalarbar.tcl
# PROCEDURES:  
#   uniqueCommandName
#   addScalarBar vlt ren1 renderWindow
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC uniqueCommandName
# Returns a string made up from a standard string (name) followed by a time stamp
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc uniqueCommandName {} {
    return name.[clock clicks]
}

#-------------------------------------------------------------------------------
# .PROC addScalarBar
# Adds a scalar bar to a render window.
# .ARGS
# LUT vlt look up table
# renderer ren1 renderer to add the scalar bar to
# window renderWindow the window the renderer displays in
# .END
#-------------------------------------------------------------------------------
proc addScalarBar { vlt ren1 renderWindow } {
  set scalarBar [uniqueCommandName]
  vtkScalarBarActor $scalarBar
  $scalarBar SetLookupTable $vlt
  $scalarBar SetMaximumNumberOfColors [$vlt GetNumberOfColors]
  $scalarBar SetOrientationToVertical
#  $ren1 SetBackground 0 0 0
  set numlabels [expr [$vlt GetNumberOfColors] + 1]
  if {$numlabels > 11} {
    set numlabels 11
  }
  $scalarBar SetNumberOfLabels $numlabels
  $scalarBar SetTitle "(mm)"

  $scalarBar SetPosition 0.1 0.1
  $scalarBar SetWidth 0.1
  $scalarBar SetHeight 0.8

  $ren1 AddActor2D $scalarBar
  $renderWindow Render

  puts "scalarBar is $scalarBar, ren1 is $ren1, renderWindow is $renderWindow"

}
