proc makeDisplVolume {volId name dx dy dz} {
    global Volume
    if { [info command MainMrmlAddNode] == "" } {
        error "cannot create slicer volume outside of slicer"
    }

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i
    

    # check if the result name exists already
    if {[VolumeExists $name] == "1"} {
        set count 0
        while {1} {
            set curName $name
            append curName $count
            if {[VolumeExists $curName] == "0"} {
                set name $curName
                break
            }
            incr count
        }
    }
    puts "NAME = $name"

    catch "sph1 Delete"
    vtkImageEllipsoidSource sph1
    sph1 SetCenter 10 10 10
    sph1 SetRadius 0 0 0
    sph1 SetInValue 0.0
    sph1 SetOutValue $dx
    sph1 SetOutputScalarTypeToFloat
    sph1 SetWholeExtent 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 1] 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 3] 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 5]


    catch "sph2 Delete"
    vtkImageEllipsoidSource sph2
    sph2 SetCenter 10 10 10
    sph2 SetRadius 0 0 0
    sph2 SetInValue 0.0
    sph2 SetOutValue $dy
    sph2 SetOutputScalarTypeToFloat
    sph2 SetWholeExtent 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 1] 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 3] 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 5]

    catch "sph3 Delete"
    vtkImageEllipsoidSource sph3
    sph3 SetCenter 10 10 10
    sph3 SetRadius 0 0 0
    sph3 SetInValue 0.0
    sph3 SetOutValue $dz
    sph3 SetOutputScalarTypeToFloat
    sph3 SetWholeExtent 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 1] 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 3] 0 [lindex [[Volume($volId,vol) GetOutput] GetWholeExtent] 5]

    catch "app1 Delete"
    vtkImageAppendComponents app1
    app1 SetInput 0 [sph1 GetOutput]
    app1 SetInput 1 [sph2 GetOutput]
    app1 Update

    catch "app2 Delete"
    vtkImageAppendComponents app2
    app2 SetInput 0 [app1 GetOutput]
    app2 SetInput 1 [sph3 GetOutput]
    app2 Update

    set id id_$name
    puts "id is $id"

    vtkImageData $id
    $id DeepCopy [app2 GetOutput]

    ::Volume($i,node) SetName $name
    ::Volume($i,node) SetNumScalars 3
    ::Volume($i,node) SetScalarType [Volume($volId,node) GetScalarType]

    eval ::Volume($i,node) SetSpacing [Volume($volId,node) GetSpacing]
    
    ::Volume($i,node) SetScanOrder [Volume($volId,node) GetScanOrder]
    ::Volume($i,node) SetDimensions [lindex [Volume($volId,node) GetDimensions] 0] [lindex [Volume($volId,node) GetDimensions] 1]
    ::Volume($i,node) SetImageRange 1 [lindex [Volume($volId,node) GetImageRange] 1]
    
    ::Volume($i,node) ComputeRasToIjkFromScanOrder [::Volume($i,node) GetScanOrder]
    Volume($i,vol) SetImageData $id
    MainUpdateMRML

   # Slicer SetOffset 0 0
   # MainSlicesSetVolumeAll Back $i
   # RenderAll

}

proc VolumeExists {name} {
    global Volume
    foreach v $Volume(idList) {
        set index [lsearch -exact $name [Volume($v,node) GetName]]
        if {$index > -1} {
            # name exists
            return 1
        }
    }
    return 0
}
