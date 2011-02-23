
proc ModelInteractionPaintInit {} {
    global ModelInteraction 

    set ModelInteraction(PaintVolume) ""
}

proc ModelInteractionPaintBuildGUI {} {
    global Gui ModelInteraction Module Volume Model

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # 
    # Paint
    # 
    #-------------------------------------------

    #-------------------------------------------
    # Paint frame
    #-------------------------------------------
    set fPaint $Module(ModelInteraction,fPaint)
    set f $fPaint

    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }


    #-------------------------------------------
    # Paint->Top frame
    #-------------------------------------------
    set f $fPaint.fTop

    # menu to select a volume: will set ModelInteraction(PaintVolume)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name PaintVolume
    DevAddSelectButton  ModelInteraction $f $name "Paint Volume:" Pack \
        "Select a scan (volume) to paint the model with."  13



    #-------------------------------------------
    # Paint->Middle frame
    #-------------------------------------------
    set f $fPaint.fMiddle

    #-------------------------------------------
    # Paint->Bottom frame
    #-------------------------------------------
    set f $fPaint.fBottom


}


proc ModelInteractionPaintUpdateMRML {} {
    
    global Volume ModelInteraction
    
    DevUpdateNodeSelectButton Volume ModelInteraction \
        PaintVolume PaintVolume DevSelectNode 0 0 0 

    
}




proc ModelInteractionPaintClipboardWithVolume {v} {
    
    global ModelInteraction

    set id [ModelInteractionGetCurrentClipboardID]

    foreach m $ModelInteraction(clipboard,$id) {
        ModelInteractionPaintModelWithVolume $m $v
    }
}


proc ModelInteractionPaintModelWithVolume {m v} {
   global Volume Model Module ModelInteraction

    #set v $Volume(activeID)
    #set m $Model(activeID)
    #set m 0


    # the model is in world space, the volume data is in scaled ijk
    # to probe, we need a model in scaled ijk since we can't move
    # the volume.
    # so here we move the model from world into the scaled ijk
    # of the volume of interest.
    vtkTransformPolyDataFilter transformer
    transformer SetInput $Model($m,polyData)

    # the transform matrix object for world to ijk
    vtkTransform transform1
    transform1 SetMatrix [Volume($v,node) GetWldToIjk]
    # the data knows its spacing already so remove it from the matrix
    # (otherwise the actor would be stretched, ouch)
    #scan [Volume($v,node) GetSpacing] "%g %g %g" res_x res_y res_z
    #transform1 Scale $res_x $res_y $res_z

    transformer SetTransform transform1

    ###################  TEST
    set spacing [[Volume($v,vol) GetOutput] GetSpacing]
    set origin  [[Volume($v,vol) GetOutput] GetOrigin]
    # The spacing is accounted for in the rasToVtk transform, 
    # so we have to remove it here, or mcubes will use it.
    [Volume($v,vol) GetOutput] SetSpacing 1 1 1
    [Volume($v,vol) GetOutput] SetOrigin 0 0 0
    ###################  END TEST

    # here we probe the values on the model's surface
    vtkProbeFilter probe
    probe SetInput [transformer GetOutput]
    probe SetSource [Volume($v,vol) GetOutput]

    probe Update
    puts [[probe GetValidPoints] Print]
    puts [[probe GetOutput] Print]
    flush stdout

    # now put the output model back where the input model was
    transform1 Inverse
    #transform1 Identity
    vtkTransformPolyDataFilter transformer1
    transformer1 SetTransform transform1
    transformer1 SetInput [probe GetOutput]

    # this is necessary or the probe changes the scalars!
    probe SetInput ""
    probe Delete
    transformer1 Update

    ###################  TEST
    # this works but adjusting the matrix did not.
    eval [Volume($v,vol) GetOutput] SetSpacing $spacing
    eval [Volume($v,vol) GetOutput] SetOrigin $origin
    ###################  END TEST


    # replace old polydata with the new one.
    set id $m
    set Model($id,polyData) [transformer1 GetOutput]
    $Model($id,polyData) Update
    puts [$Model($id,polyData) Print]
    foreach r $Module(Renderers) {
        Model($id,mapper,$r) SetInput $Model($id,polyData)
    }

    # turn on display of the scalars we just probed
    MainModelsSetScalarVisibility $id 1

    # scalar range: want it the same for all models
    # that are painted from this volume. So use the
    # scalar range of the volume
    #eval {MainModelsSetScalarRange $id} [$Model($id,polyData) GetScalarRange]
    #eval {MainModelsSetScalarRange $id} [[Volume($v,vol) GetOutput] GetScalarRange]
    # use the window/level of the volume
    set win [expr [Volume($v,node) GetWindow] / 2]
    set lev [Volume($v,node) GetLevel]
    set low [expr $lev - $win]
    set high [expr $lev + $win]
    MainModelsSetScalarRange $id $low $high

    # default to grayscale:
    ModelsSetScalarsLut $id [MainLutsGetLutIDByName "Gray"]

    MainUpdateMRML
    MainModelsSetActive $id

    # old code to add a new model instead of replacing the old:
    ##try adding output model to the slicer
    ## Create the model's MRML node
    #set n [MainMrmlAddNode Model]
    #$n SetName  test
    #$n SetColor Skin
    ## Create the model
    #set id [$n GetID]
    #MainModelsCreate $id
    ## Registration
    ## in case any transforms are being applied to the original model
    ##Model($id,node) SetRasToWld [Model($m,node) GetRasToWld]
    ## polyData will survive as long as it's the input to the mapper
    #set Model($id,polyData) [transformer1 GetOutput]
    #$Model($id,polyData) Update
    #puts [$Model($id,polyData) Print]
    #foreach r $Module(Renderers) {
    #    Model($id,mapper,$r) SetInput $Model($id,polyData)
    #}
    #MainUpdateMRML
    #MainModelsSetActive $id
    ## turn on display of the scalars we just probed
    #eval {MainModelsSetScalarRange $id} [$Model($id,polyData) GetScalarRange]
    #MainModelsSetScalarVisibility $id 1

    # delete vtk objects we created in this proc
    transform1 Delete
    transformer Delete
    transformer1 Delete



}



proc ModelInteractionPaintVolumeWithModel {v m} {
   global Volume Model Module ModelInteraction

    puts "transforming data into ijk coords"

    # the model is in world space, the volume data is in scaled ijk
    # to probe, we need a model in scaled ijk since we can't move
    # the volume.
    # so here we move the model from world into the scaled ijk
    # of the volume of interest.
    vtkTransformPolyDataFilter transformer
    transformer SetInput $Model($m,polyData)

    # the transform matrix object for world to ijk
    vtkTransform transform1
    transform1 SetMatrix [Volume($v,node) GetWldToIjk]
    # the data knows its spacing already so remove it from the matrix
    # (otherwise the actor would be stretched, ouch)
    #scan [Volume($v,node) GetSpacing] "%g %g %g" res_x res_y res_z
    #transform1 Scale $res_x $res_y $res_z

    transformer SetTransform transform1

    ###################  TEST
    set spacing [[Volume($v,vol) GetOutput] GetSpacing]
    set origin  [[Volume($v,vol) GetOutput] GetOrigin]
    # The spacing is accounted for in the rasToVtk transform, 
    # so we have to remove it here, or mcubes will use it.
    [Volume($v,vol) GetOutput] SetSpacing 1 1 1
    [Volume($v,vol) GetOutput] SetOrigin 0 0 0
    ###################  END TEST


    puts "creating stencil from model"
    vtkPolyDataToImageStencil dataToStencil
    dataToStencil SetInput [transformer GetOutput]
    dataToStencil SetTolerance 0.0005

    puts "applying stencil to image"
    vtkImageStencil stencil
    stencil SetInput [Volume($v,vol) GetOutput]
    stencil SetStencil [dataToStencil GetOutput]
    stencil ReverseStencilOn
    stencil SetBackgroundValue 0

    stencil Update

    puts [[stencil GetOutput] Print]

    puts [[stencil GetOutput] GetScalarRange]

    Volume($v,vol) SetImageData [stencil GetOutput]
    MainSlicesSetVolumeAll Fore $v

    ###################  TEST
    # this works but adjusting the matrix did not.
    eval [Volume($v,vol) GetOutput] SetSpacing $spacing
    eval [Volume($v,vol) GetOutput] SetOrigin $origin
    ###################  END TEST

    puts "exporting result to slicer MRML"
    MainUpdateMRML
    RenderAll

    stencil Delete
    dataToStencil Delete
    transform1 Delete
    transformer Delete

}

