




proc axflip_run { id } {

    catch "ir Delete"

    vtkImageReslice ir
    # 45 degree rotate in Z, followed by 45 degree around X
    ir SetResliceAxesDirectionCosines .707 -0.5 0.5  .707 0.5 -0.5  0 .707 .707 
    ir SetInterpolationModeToCubic
    ir SetInput $id
    [ir GetOutput] SetUpdateExtentToWholeExtent

    puts "reslice updating..."; update
    [ir GetOutput] Update
    set memory_used [[ir GetOutput] GetActualMemorySize]
    puts "reslice done on $memory_used"; update

    catch "ir Delete"

    return 0
}

