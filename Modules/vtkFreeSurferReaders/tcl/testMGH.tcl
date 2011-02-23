#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: testMGH.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:42 $
#   Version:   $Revision: 1.8 $
# 
#===============================================================================
# FILE:        testMGH.tcl
# PROCEDURES:  
#==========================================================================auto=
# test script for mgh reader
#
 
package require vtkFreeSurferReaders
package require vtk
package require vtkinteraction
vtkRenderer ren1
vtkRenderWindow renWin
vtkRenderWindowInteractor iren
iren SetRenderWindow renWin
vtkMGHReader reader
reader SetFileName "/projects/birn/freesurfer/recon/MGH-GE15-JJ/mri/flash/flash20.mgh"

    # Create transfer functions for opacity and color
    vtkPiecewiseFunction VolRend(opacityTransferFunction)
    vtkColorTransferFunction VolRend(colorTransferFunction)
    vtkPiecewiseFunction VolRend(GradientOpacityTRansferFunction)

    # Create properties, mappers, volume actors, and ray cast function
    vtkVolumeProperty VolRend(volumeProperty)
    VolRend(volumeProperty) SetColor VolRend(colorTransferFunction)
    VolRend(volumeProperty) SetScalarOpacity VolRend(opacityTransferFunction)
    VolRend(volumeProperty) SetGradientOpacity VolRend(GradientOpacityTRansferFunction)

    vtkVolumeRayCastCompositeFunction  VolRend(compositeFunction)
    vtkVolumeRayCastMIPFunction VolRend(mipFunction)
    vtkVolumeRayCastIsosurfaceFunction VolRend(isosurfaceFunction)

    vtkVolumeRayCastMapper VolRend(raycastvolumeMapper)
    vtkVolumeTextureMapper2D VolRend(texturevolumeMapper)

    # output of the mgh vol
#    VolRend(volumeMapper) SetInput [reader GetOutput]

    VolRend(raycastvolumeMapper) SetVolumeRayCastFunction VolRend(compositeFunction)

    vtkVolume VolRend(volume)
#    VolRend(volume) SetMapper VolRend(volumeMapper)
    VolRend(volume) SetProperty VolRend(volumeProperty)

    vtkImageCast VolRend(imageCast)


ren1 AddVolume VolRend(volume)
ren1 SetBackground 1 1 1
renWin SetSize 600 600
renWin Render
    
proc TkCheckAbort {} {
  set foo [renWin GetEventPending]
  if {$foo != 0} {renWin SetAbortRender 1}
}
renWin AddObserver AbortCheckEvent {TkCheckAbort}

iren AddObserver UserEvent {wm deiconify .vtkInteract}
iren Initialize

wm withdraw .

