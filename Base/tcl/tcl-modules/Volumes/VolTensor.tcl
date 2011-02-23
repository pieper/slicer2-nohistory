#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolTensor.tcl,v $
#   Date:      $Date: 2006/05/12 22:50:46 $
#   Version:   $Revision: 1.13 $
# 
#===============================================================================
# FILE:        VolTensor.tcl
# PROCEDURES:  
#   VolTensorInit
#   VolTensorBuildGui
#   VolTensorSetFileName
#   VolTensorApply
#   VolTensorCreateTensors
#   VolTensorMake9ComponentTensorVolIntoTensors
#   VolTensorMake6ComponentScalarVolIntoTensors
#   VolTensorMakeNComponentScalarVolIntoODF
#   VolTensorMakeTendVTKIntoTensors
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC VolTensorInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorInit {} {
    global Volume

    # Define Procedures for communicating with Volumes.tcl
    #---------------------------------------------
    set m VolTensor
    
    # procedure for building GUI in this module's frame
    set Volume(readerModules,$m,procGUI)  ${m}BuildGUI

    # callback for when 'Tensor' FileType is found in Mrml Volume Node
    set ::Module(Volumes,readerProc,Tensor) VolTensorReaderProc

    # Define Module Description to be used by Volumes.tcl
    #---------------------------------------------

    # name for menu button
    set Volume(readerModules,$m,name)  Tensor

    # tooltip for help
    set Volume(readerModules,$m,tooltip)  \
            "This tab displays information\n
    for the currently selected diffusion tensor volume."

    # Global variables used inside this module
    #---------------------------------------------
    set Volume(tensors,pfSwap) 0
    set Volume(tensors,DTIdata) 0  
    set Volume(VolTensor,FileType) Tensor9
    set Volume(VolTensor,FileTypeList) {Tensor9 Scalar6 ODF tend}
    set Volume(VolTensor,FileTypeList,tooltips) {"File contains TENSORS field with 9 components" "File contains SCALARS field with 6 components" "ODF" ".vtk files created with 'tend estim'" }
    set Volume(VolTensor,YAxis) vtk
    set Volume(VolTensor,YAxisList) {vtk non-vtk}
    set Volume(VolTensor,YAxisList,tooltips) {"VTK coordinate system used to create tensors (-y axis) " "Non-VTK coordinate system (+y axis)"}

}

#-------------------------------------------------------------------------------
# .PROC VolTensorBuildGui
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorBuildGUI {parentFrame} {
    global Gui Volume

    #-------------------------------------------
    # f
    #-------------------------------------------
    set f $parentFrame

    frame $f.fVolume  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fFileType   -bg $Gui(activeWorkspace)
    frame $f.fYAxis   -bg $Gui(activeWorkspace)
    frame $f.fScanOrder -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fVolume $f.fFileType $f.fYAxis $f.fScanOrder $f.fApply \
        -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # f->Volume
    #-------------------------------------------
    set f $parentFrame.fVolume
    DevAddFileBrowse $f Volume "VolTensor,FileName" "Structured Points File (.vtk)" "VolTensorSetFileName" "vtk" "\$Volume(DefaultDir)" "Open" "Browse for a Volume" 
    #-------------------------------------------
    # f->FileType
    #-------------------------------------------
    set f $parentFrame.fFileType

    DevAddLabel $f.l "File Type: "
    pack $f.l -side left -padx $Gui(pad) -pady 0
    #set gridList $f.l

    foreach type $Volume(VolTensor,FileTypeList) tip $Volume(VolTensor,FileTypeList,tooltips) {
        eval {radiobutton $f.rMode$type \
                  -text "$type" -value "$type" \
                -variable Volume(VolTensor,FileType) \
                -indicatoron 0} $Gui(WCA) 
        pack $f.rMode$type -side left -padx $Gui(pad) -pady 0
        #lappend gridList $f.rMode$type 
        TooltipAdd  $f.rMode$type $tip
    }   
    
    #eval {grid} $gridList {-padx} $Gui(pad)

    #-------------------------------------------
    # f->YAxis
    #-------------------------------------------
    set f $parentFrame.fYAxis

    DevAddLabel $f.l "Y axis: "
    pack $f.l -side left -padx $Gui(pad) -pady 0
    #set gridList $f.l

    foreach type $Volume(VolTensor,YAxisList) tip $Volume(VolTensor,YAxisList,tooltips) {
        eval {radiobutton $f.rMode$type \
                  -text "$type" -value "$type" \
                -variable Volume(VolTensor,YAxis) \
                -indicatoron 0} $Gui(WCA) 
        pack $f.rMode$type -side left -padx $Gui(pad) -pady 0
        #lappend gridList $f.rMode$type 
        TooltipAdd  $f.rMode$type $tip
    }   

    #eval {grid} $gridList {-padx} $Gui(pad)

   #--------------------------------------------
   # f->ScanOrder
   #--------------------------------------------
   set f $parentFrame.fScanOrder
   
   eval {label $f.lscanOrder -text "Scan Order:"} $Gui(WLA)
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


    #-------------------------------------------
    # f->Apply
    #-------------------------------------------
    
    set f $parentFrame.fApply
    
    # just go back to header page when done here
    #DevAddButton $f.bApply "Header" "VolumesSetPropertyType VolHeader" 8
    DevAddButton $f.bApply "Apply" "VolTensorApply" 
    DevAddButton $f.bCancel "Cancel" "VolumesPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad)

}


#-------------------------------------------------------------------------------
# .PROC VolTensorSetFileName
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorSetFileName {} {
    global Volume

    puts $Volume(VolTensor,FileName)

}

#
# Patch -- sp - 2005-01-16  allows mrml volume nodes with fileType='Tensor' to
# trigger automatic loading so that canned data files can be created and 
# users don't need to re-run the conversion step each time.
# TODO: 1) process creates new volumes, when it should overwrite node v
#       2) the Tensor volume type should be added to mrml file when conversion is run
#
proc VolTensorReaderProc {v} {

    set ::Volume(activeID) "NEW"
    set ::Volume(VolTensor,FileName) [Volume($v,node) GetFullPrefix]
    set ::Volume(scanOrder) [Volume($v,node) GetScanOrder]
    VolTensorApply
}

#-------------------------------------------------------------------------------
# .PROC VolTensorApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorApply {} {
    global Volume Module
    
    
    set m $Volume(activeID)
    if {$m == ""} {
       DevErrorWindow "VolTensorApply: no active volume"
       return
    }
    
     # first file
    if {[file exists $Volume(VolTensor,FileName)] == 0} {
        tk_messageBox -message "The vtk file $Volume(VolTensor,FileName) does not exist."
        return
    }
    
    set Volume(name) [lindex [file split $Volume(VolTensor,FileName)] end]
    
    # if the volume is NEW we may read it in...
    if {$m == "NEW"} {
        
        # add a MRML node for this volume (so that in UpdateMRML
        # we can read it in according to the path, etc. in the node)
        set n [MainMrmlAddNode Volume]
        set i [$n GetID]

        ############# NOTE this should be fixed !!!!!!!! ##############
        # NOTE:
        # this normally happens in MainVolumes.tcl
        # this is needed here to set up structured points reading
        # this should be fixed (the node should handle this somehow
        # so that MRML can be read in with just a node and this will
        # work)
        MainVolumesCreate $i
        $n SetScanOrder $Volume(scanOrder)       

        # set up structured points reading using sub-node 
        # NOTE: we should do it by setting this up 
        #vtkMrmlDataVolumeReadWriteStructuredPointsNode 
        # but for now we do:
        vtkMrmlDataVolumeReadWriteStructuredPoints Volume($i,vol,rw)
        Volume($i,vol)  SetReadWrite Volume($i,vol,rw)
        puts "set read write"
        Volume($i,vol,rw) SetFileName $Volume(VolTensor,FileName)
        Volume($i,vol) Read
        puts "read test.vtk"
        ################### END of should be fixed ###################

        # slicer assumes the origin is at 0 0 0
        # when creating ras to ijk matrices, etc.  this is 
        # necessary to have tensors in the expected location in 3D
        # for hyperstreamlines to work
        #puts "setting origin to 0 0 0"
        #[Volume($i,vol) GetOutput] SetOrigin 0 0 0

        ### this stuff is from the no-header GUI, but use it here too
        ### NOTE: should let users know this happens somehow
        $n SetName $Volume(name)
        $n SetDescription $Volume(desc)
        $n SetLabelMap $Volume(labelMap)
        # get the pixel size, etc. from the data and set it in the node
        
        MainUpdateMRML
        # If failed, then it's no longer in the idList
        if {[lsearch $Volume(idList) $i] == -1} {
            return
        }
 

        puts "[Volume($i,vol) GetOutput] Print"
        # use this as a structured points file (normal volume)
        # set active volume on all menus
        MainVolumesSetActive $i
        
        # allow use of other module GUIs
        #set Volume(freeze) 0

        #######

        # if we are successful set the FOV for correct display of this volume
        set dim     [lindex [Volume($i,node) GetDimensions] 0]
        set spacing [lindex [Volume($i,node) GetSpacing] 0]
        set fov     [expr $dim*$spacing]
#        set View(fov) $fov
        MainViewSetFov "default" $fov
        
        # display the new volume in the background of all slices
        # don't do this in case there are no scalars
        #MainSlicesSetVolumeAll Back $i

        # turn the volume into a tensor volume now
        VolTensorCreateTensors $i
        
        # check if we have normal scalars and keep this. 
        set scalars [[[Volume($i,vol) GetOutput] GetPointData] GetScalars]
        if { [$scalars GetNumberOfComponents] == 1 } {
          
           set newvol [MainMrmlAddNode Volume]
           set v [$newvol GetID]

           $newvol Copy Volume($i,node)
           $newvol SetDescription "tensor volume"
           $newvol SetName "[Volume($i,node) GetName] - Scalar"
           MainVolumesCreate $v
           $newvol SetScanOrder $Volume(scanOrder)
           #Turn off Copy Tensors
           [[Volume($i,vol) GetOutput] GetPointData] CopyTensorsOff
           #[[Volume($v,vol) GetOutput] GetPointData] CopyTensorsOff
           [Volume($v,vol) GetOutput] DeepCopy [Volume($i,vol) GetOutput]
           
           [[Volume($v,vol) GetOutput] GetPointData] SetTensors ""
                      
           # If failed, then it's no longer in the idList
           if {[lsearch $Volume(idList) $v] == -1} {
              puts "node doesn't exist, should unfreeze and fix volumes.tcl too"
           } else {
           # Activate the new data object
            MainVolumesSetActive $v
            MainSlicesSetVolumeAll Back $v
            RenderAll
           }
    
        }
    
    if {$Volume(VolTensor,FileType) == "ODF"} {
    } else {
    #Delete Reader node and vtkMrmlReadWrite
        MainMrmlDeleteNode Volume $i
        }
    Volume($i,vol,rw) Delete
        
        MainUpdateMRML
        
        # allow use of other module GUIs
        set Volume(freeze) 0
        
        # If tabs are frozen, then 
        if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
       }
 
    }
}


#-------------------------------------------------------------------------------
# .PROC VolTensorCreateTensors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorCreateTensors {v} {
    global Volume

    switch $Volume(VolTensor,FileType) {
        "Scalar6" {
            VolTensorMake6ComponentScalarVolIntoTensors $v
        }
        "Tensor9" {
            VolTensorMake9ComponentTensorVolIntoTensors $v
        }
        "ODF" {
            VolTensorMakeNComponentScalarVolIntoODF $v
        }
        "tend" {
            VolTensorMakeTendVTKIntoTensors $v
        }
    }

}

#-------------------------------------------------------------------------------
# .PROC VolTensorMake9ComponentTensorVolIntoTensors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorMake9ComponentTensorVolIntoTensors {v} {
    global Volume Tensor

    # all we need to do here is put it on the tensor
    # id list and do MRML things

    # put output into a tensor volume
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol Copy Volume($v,node)
    $newvol SetDescription "tensor volume"
    $newvol SetName "[Volume($v,node) GetName] - Tensor"
    set n [$newvol GetID]
    TensorCreateNew $n 

    # put the image data into the object for slicer use
    Tensor($n,data) SetImageData [Volume($v,vol) GetOutput]

    
    # test by printing to terminal
    puts [[Tensor($n,data) GetOutput] Print]

    # This updates all the buttons to say that the
    # Tensor ID List has changed.
    MainUpdateMRML
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        puts "node doesn't exist, should unfreeze and fix volumes.tcl too"
    } else {
        # Activate the new data object
        DTMRISetActive $n
    }

    # DAN if the volume read in does not have scalars, only
    # tensors, it should be removed from the slicer
    # (Volume(id,vol) and Volume(id,node) should go away
    # however they are deleted like in Data.tcl )

}


#-------------------------------------------------------------------------------
# .PROC VolTensorMake6ComponentScalarVolIntoTensors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorMake6ComponentScalarVolIntoTensors {v} {
    global Volume Tensor

    # put output into a tensor volume
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol Copy Volume($v,node)
    $newvol SetDescription "tensor volume"
    $newvol SetName "[Volume($v,node) GetName] - Tensor"
    set n [$newvol GetID]
    TensorCreateNew $n 

    # actually put the correct data inside the thing
    # need to go from 6-component data to 9-component
    # and then set these as the tensors
    # input scalars are in the order of [Txx Txy Txz Tyy Tyz Tzz]

    # this will be the last filter in the pipeline
    vtkAssignAttribute aa

    # if we do not need to flip the y axis
    if {$Volume(VolTensor,YAxis) == "vtk"} {
       vtkImageAppendComponents ap1
       vtkImageAppendComponents ap2
       # [Txx Txy Txz Txy Tyy Tyz Txz Tyz Tzz]
       # [0   1   2   1   3   4   2   4   5] (indices into input scalars)
       for {set i 0} {$i < 3} {incr i} {
           vtkImageExtractComponents ex$i
           ex$i SetInput [Volume($v,vol) GetOutput]
       }
       ex0 SetComponents 0 1 2
       ex1 SetComponents 1 3 4
       ex2 SetComponents 2 4 5
#        ap1 SetInput1 [ex0 GetOutput]
       ap1 AddInput [ex0 GetOutput]
#        ap1 SetInput2 [ex1 GetOutput]
       ap1 AddInput [ex1 GetOutput]
#        ap2 SetInput1 [ap1 GetOutput]
       ap2 AddInput [ap1 GetOutput]
#        ap2 SetInput2 [ex2 GetOutput]
       ap2 AddInput [ex2 GetOutput]
       ap2 Update

       # set input to aa to be the output of the last filter above
       aa SetInput [ap2 GetOutput]

       # Delete all temporary vtk objects
       for {set i 0} {$i < 3} {incr i} {
           ex$i Delete
       }
       ap1 Delete
       ap2 Delete



    } else {
        # DAN, this part is not yet implemented

        # we do need to flip the y axis
        # so grab the y components separately and multiply by -1
        # [Txx Txy Txz Txy Tyy Tyz Txz Tyz Tzz]
        # [0   1   2   1   3   4   2   4   5] (indices into input scalars)
        set ind {0   1   2   1   3   4   2   4   5}
        for {set i 0} {$i < 6} {incr i} {
            # grab ith component
            vtkImageExtractComponents ex$i
            ex$i SetInput [Volume($v,vol) GetOutput]
            ex$i SetComponents $i
            #cout " [lindex $i $ind]"        
        }
        
        # try multiplying the T*y and Ty* by -1
        # you can use vtkImageMathematics filters
        #[-Txy -Tyz]
        vtkImageMathematics minusex1
        minusex1 SetOperationToMultiplyByK
        minusex1 SetConstantK -1
        minusex1 SetInput 0 [ex1 GetOutput]
        
        vtkImageMathematics minusex4
        minusex4 SetOperationToMultiplyByK
        minusex4 SetConstantK -1
        minusex4 SetInput 0 [ex4 GetOutput]
        
        vtkImageAppendComponents ap1
        ap1 AddInput [ex0 GetOutput]
        ap1 AddInput [minusex1 GetOutput]
        ap1 AddInput [ex2 GetOutput]
        ap1 AddInput [minusex1 GetOutput]
        ap1 AddInput [ex3 GetOutput]
        ap1 AddInput [minusex4 GetOutput]
        ap1 AddInput [ex2 GetOutput]
        ap1 AddInput [minusex4 GetOutput]
        ap1 AddInput [ex5 GetOutput]
        
        aa SetInput [ap1 GetOutput]
        aa Update
        
        for {set i 0} {$i < 6} {incr i} {
            ex$i Delete
        }
        minusex1 Delete
        minusex4 Delete
        ap1 Delete
    }
    
    # aa contains output of chosen pipeline above
    # make the active scalars also the active tensors
    aa Assign SCALARS TENSORS POINT_DATA
    aa Update

    # put the image data (now with tensors and scalars) 
    # into the object for slicer use
    Tensor($n,data) SetImageData [aa GetOutput]

    # test by printing to terminal
    puts [[Tensor($n,data) GetOutput] Print]

    # This updates all the buttons to say that the
    # Tensor ID List has changed.
    MainUpdateMRML
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        puts "node doesn't exist, should unfreeze and fix volumes.tcl too"
    } else {
        # Activate the new data object
        DTMRISetActive $n
    }

    # Delete all temporary vtk objects
    aa Delete
}

#-------------------------------------------------------------------------------
# .PROC VolTensorMakeNComponentScalarVolIntoODF
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorMakeNComponentScalarVolIntoODF {v} {
    global Volume Tensor

    # all we need to do here is put it on the tensor
    # id list and do MRML thing

}

#-------------------------------------------------------------------------------
# .PROC VolTensorMakeTendVTKIntoTensors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorMakeTendVTKIntoTensors {v} {
    global Volume Tensor

    # all we need to do here is put it on the tensor
    # id list and do MRML things
    # after flipping Y and negating the x cross terms in tensors

    if { [Volume($v,node) GetScanOrder] != "IS" } {
        DevWarningWindow "Warning: Tensor import from the tend program has only been tested for Axial IS volumes"
    }


    # put output into a tensor volume
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol Copy Volume($v,node)
    $newvol SetDescription "tensor volume"
    $newvol SetName "[Volume($v,node) GetName] - Tensor"
    set n [$newvol GetID]
    TensorCreateNew $n 

    if { [info command vtkTensorFlip] == "" } {
        DevErrorWindow "Tensor flipping not available in this version of slicer"

        # put the image data into the object for slicer use
        Tensor($n,data) SetImageData [Volume($v,vol) GetOutput]
    } else {
        catch "TendVTK_flip Delete"
        vtkTensorFlip TendVTK_flip 
        TendVTK_flip SetInput [Volume($v,vol) GetOutput]

        # put the image data into the object for slicer use
        puts "flipping tensor components"
        [TendVTK_flip GetOutput] Update
        Tensor($n,data) SetImageData [TendVTK_flip GetOutput]
        TendVTK_flip Delete
    }
    
    # test by printing to terminal
    puts [[Tensor($n,data) GetOutput] Print]

    # This updates all the buttons to say that the
    # Tensor ID List has changed.
    MainUpdateMRML
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        puts "node doesn't exist, should unfreeze and fix volumes.tcl too"
    } else {
        # Activate the new data object
        DTMRISetActive $n
    }

    # DAN if the volume read in does not have scalars, only
    # tensors, it should be removed from the slicer
    # (Volume(id,vol) and Volume(id,node) should go away
    # however they are deleted like in Data.tcl )

}

