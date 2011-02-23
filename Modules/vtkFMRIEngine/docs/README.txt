This file describes the functionality of vtkFMRIEngine module.

--------
Help Tab
--------

This is general help text for the module.

------------
Sequence Tab
------------

Click the Sequence tab and you should see Select and Load sub-tabs.
The Load tab is used to load a new sequence of volumes while Select 
tab is used to select a sequence which is already loaded into memory from vtkIbrowser
module or within vtkFMRIEngine itself.

Currently you can load one of the followings: 
a. A single volume by a pair of 3D Analyze files (hdr/img) 
b. A list of 3D Analyze pair files in the same directory. Each pair is a volume.
c. A single pair of 4D Analyze files (hdr/img)
d. A single bxh file which can represent a single volume or a list of 
   volumes in one of the following format: 3D Analyze and dicom 

----------
Set Up Tab
----------

We are currently supporting Linear Modeling to detect fMRI activation. 

The Set Up process consits of four steps (click the pulldown menu):
- Specify paradigm
- Model signal
- Estimate (fit model)
- Make contrast(s)

The specified paradigm can be saved in a text file and read in later. Conditions 
after signal modeling may be viewed graphically. The beta volume out of estimation
can also be saved and loaded at a later time.

----------
Detect Tab
----------

All contrasts made before should be visible in the list box. Slicer will compute
one volume for each selected contrast and display the last one on the list in the 
view window.

----------
View Tab
----------

Three sub-tabs are visible:
Choose: If any, choose, one at a time, a volume for display.
Thrshld: Threshold the activation volume at different p values (corrected or uncorrected).
Plot: Dynamically plot voxel time course for different conditions. 

----------
ROI Tab
----------

Steps to perform Region of Interest (ROI) analysis:
- Compute an activation map
- Threshold it for getting your activation blobs
- Load or create a region map (see RegionMap tab)
- Perform and view region statistics (see Stats tab)


