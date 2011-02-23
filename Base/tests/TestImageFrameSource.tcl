package require vtk
package require vtkSlicerBase

puts "WARNING: This script outputs two images"
puts "Make sure you grab the correct one for testing"
puts "I think the windows are named poorly for a script"
puts "And, I'm sure this filter exists somewhere in VTK"

# Test script for vtkImageFrameSource.
# -- Render a window
# -- Then Copy the Rendering into an image using vtkImageFrameSource
# -- Then Render it in a new window.

# display a cone for testing
vtkConeSource cone
  cone SetResolution 8
vtkPolyDataMapper coneMapper
  coneMapper SetInput [cone GetOutput]
vtkActor coneActor
  coneActor SetMapper coneMapper

# make the original window
vtkRenderer ren
  ren AddActor coneActor
vtkRenderWindow renWin
  renWin AddRenderer ren
vtkRenderWindowInteractor iren
  iren SetRenderWindow renWin

# enable user interface interactor
iren SetUserMethod {wm deiconify .vtkInteract}
iren Initialize

# prevent the tk window from showing up then start the event loop
wm withdraw .

# draw the original window
#renWin Render

# here's what we're testing
# copy the stuff from renWin
vtkImageFrameSource frameSource
  frameSource SetRenderWindow renWin

vtkImageMapper copyMapper
  copyMapper SetColorWindow 255
  copyMapper SetColorLevel 127.5
  copyMapper SetInput [frameSource GetOutput]

vtkActor2D copyActor
  copyActor SetMapper copyMapper

vtkRenderer copyRen
  copyRen AddActor2D copyActor

# render into a 2D image window

vtkRenderWindow copyWin
  copyWin AddRenderer copyRen
  # move the second window over a little
  copyWin SetPosition 300 300

# Render the original window so that the second one
# will not come up black the first time.
renWin Render

# Render the copy.  Bring up the interactor and paste
# the following in to render many times.
frameSource Modified
frameSource Update
#copyMapper Modified  (this line has no effect)
copyWin Render

# On Solaris, the above frameSource Update is necessary,
# else the first render will black out the image and 
# the second will draw it...
