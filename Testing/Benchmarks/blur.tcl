



proc blur_run { id } {

    catch "blur_igs Delete"

    vtkImageGaussianSmooth blur_igs
    blur_igs SetInput $id
    [blur_igs GetOutput] SetUpdateExtentToWholeExtent

    puts "blur updating ..."; update
    [blur_igs GetOutput] Update
    set memory_used [[blur_igs GetOutput] GetActualMemorySize]
    puts "blur done on $memory_used"; update

    catch "blur_igs Delete"

    return 0
}
