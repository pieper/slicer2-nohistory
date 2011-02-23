proc testVolGeneric {} {
    global Volume Volumes
    set Volume(firstFile) Testing/TestData/imagetest/nrrd/fixed.nrrd
    VolGenericApply
    
    set Volume(activeID) 1
    VolumesGenericExportSetFileType nhdr
    set Volumes(prefixGenericSave) fixed.nrrd
    VolumesGenericExport

    if {[tdiff Testing/TestData/imagetest/nrrd/fixed.nrrd fixed.nrrd]} {
        exit 1
    } else {
        exit 0
    }
    file delete -force fixed.nrrd
}

proc tdiff {fn1 fn2} {
    set f1 [open [lindex $fn1] r]
    set size [file size $fn1]
    set data1 [read $f1 $size]

    set f2 [open [lindex $fn2] r]
    set size [file size $fn2]
    set data2 [read $f2 $size]

    if {$data1 == $data2} {
        return 0
    } else {
        return 1
    }
}
