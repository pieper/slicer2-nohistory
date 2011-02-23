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
# FILE:        IbrowserControllerViewPopup.tcl
# PROCEDURES:  
#   IbrowserSetupViewPopupImages
#   IbrowserMakeViewMenu
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserSetupViewPopupImages
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetupViewPopupImages { } {
    global PACKAGE_DIR_VTKIbrowser
    
    set tmpstr $PACKAGE_DIR_VTKIbrowser
    set tmpstr [string trimright $tmpstr "/vtkIbrowser" ]
    set tmpstr [string trimright $tmpstr "/Tcl" ]
    set tmpstr [string trimright $tmpstr "Wrapping" ]
    set modulePath [format "%s%s" $tmpstr "tcl/"]

    set ::IbrowserController(Images,Menu,sliceOneVolLO) \
        [ image creat photo -file ${modulePath}iconPix/20x20/gifs/controls/singleVolSliceLO.gif ]
    set ::IbrowserController(Images,Menu,sliceOneVolHI) \
        [ image creat photo -file ${modulePath}iconPix/20x20/gifs/controls/singleVolSliceHI.gif ]
    set ::IbrowserController(Images,Menu,sliceMultiVolLO) \
        [ image creat photo -file ${modulePath}iconPix/20x20/gifs/controls/multiVolSliceLO.gif ]
    set ::IbrowserController(Images,Menu,sliceMultiVolHI) \
        [ image creat photo -file ${modulePath}iconPix/20x20/gifs/controls/multiVolSliceHI.gif ]
    set ::IbrowserController(Images,Menu,MultiVolVoxLO) \
        [ image creat photo -file ${modulePath}iconPix/20x20/gifs/controls/multiVolVoxelLO.gif ]
    set ::IbrowserController(Images,Menu,MultiVolVoxHI) \
        [ image creat photo -file ${modulePath}iconPix/20x20/gifs/controls/multiVolVoxelHI.gif ]

}

#-------------------------------------------------------------------------------
# .PROC IbrowserMakeViewMenu
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeViewMenu { fr } {

    #pack all labels in the same frame that Animation Menu is in.
    #named .fibAnimControl
    label $fr.lviewMultiVox -background white \
        -image $::IbrowserController(Images,Menu,MultiVolVoxLO) -relief flat
    bind $fr.lviewMultiVox  <Enter> {
        %W config -image $::IbrowserController(Images,Menu,MultiVolVoxHI) }
    bind $fr.lviewMultiVox <Leave> {
        %W config -image $::IbrowserController(Images,Menu,MultiVolVoxLO) }    

    label $fr.lviewMatrixOneVol -background white \
        -image $::IbrowserController(Images,Menu,sliceOneVolLO) -relief flat
    bind $fr.lviewMatrixOneVol <Enter> {
        %W config -image $::IbrowserController(Images,Menu,sliceOneVolHI) }
    bind $fr.lviewMatrixOneVol <Leave> {
        %W config -image $::IbrowserController(Images,Menu,sliceOneVolLO) }    

    label $fr.lviewMatrixMultiVol -background white \
        -image $::IbrowserController(Images,Menu,sliceMultiVolLO) -relief flat
    bind $fr.lviewMatrixMultiVol <Enter> {
        %W config -image $::IbrowserController(Images,Menu,sliceMultiVolHI) }
    bind $fr.lviewMatrixMultiVol <Leave> {
        %W config -image $::IbrowserController(Images,Menu,sliceMultiVolLO) }    

    pack $fr.lviewMultiVox -side right
    pack $fr.lviewMatrixOneVol -side right
    pack $fr.lviewMatrixMultiVol -side right
}


