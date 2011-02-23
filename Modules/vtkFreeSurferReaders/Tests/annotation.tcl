# #! /projects/birn/nicole/slicer2/Lib/solaris8/vtk/VTK-build/bin/vtk

# /usr/local/bin/vtk

# first we load in the standard vtk packages into tcl
# package require vtk
# package require vtkinteraction

package require vtkFreeSurferReaders
# if trying to run with DUMA, need to load instead of pkg require
#load  ../builds/linux-x86/bin/libvtkFreeSurferReadersTCL.so
#load ../../../Lib/linux-x86/VTK-build/bin/libvtkCommonTCL.so
#puts "done loading"

proc TestAnnot { annotFileName { colorTableFileName "" } } {

    vtkIntArray labels
    vtkLookupTable colors
puts "annotation.tcl: creating ar"
    vtkFSSurfaceAnnotationReader ar
ar DebugOn
puts "annotation.tcl: created ar"

    # Try to load an annotation file, first by using an embedded color table.
    ar SetFileName $annotFileName
    ar SetOutput labels
    ar SetColorTableOutput colors
    if {$colorTableFileName == ""} {
    ar UseExternalColorTableFileOff
    } else {
    ar SetColorTableFileName $colorTableFileName
    ar UseExternalColorTableFileOn
    }

    puts "annotation.tcl: About to read file $annotFileName (use ext colour table = [ar GetUseExternalColorTableFile] )"
    set err [ar ReadFSAnnotation] 
 puts "annotation.tcl: return from ReadFSAnnotation:"
puts "err = $err"
    if { $err == 6 } {

        puts "annotation.tcl: got err = 6"
        # Here you might ask the user to choose a color
        # table. Alternatively, use a 'known' good color table.  Set the
        # color table name, tell the reader to use an external table,
        # and try reading again
        ar SetColorTableFileName $colorTableFileName
        ar UseExternalColorTableFileOn
        
        puts "annotation.tcl: About to read in file using external colour table $colorTableFileName"
        set err [ar ReadFSAnnotation]
        puts "annotation.tcl: Done reading in file using external colour table $colorTableFileName"
    }
    
    # Handle errors or warnings. These error code constants are in
    # vtkFSSurfaceAnnotationReader.h
    if { $err } {
        puts "annotation.tcl: Got an error $err"
        switch $err {
            1 {
                puts "annotation.tcl: Error: Couldn't load external color table."
                exit
            }
            2 {
                puts "annotation.tcl: Error: Couldn't load annotation file."
                exit
            }
            3 {
                puts "annotation.tcl: Error: Couldn't parse external color table."
                exit
            }
            4 {
                puts "annotation.tcl: Error: Couldn't parse annotation file."
                exit
            }
            5 {
                puts "annotation.tcl: Warning: some annotation label values did not have corresponding entries in the color table."
            }
        }
    }
    
    # check some values
    puts "annotation.tcl: Labels:"
    set lRange [labels GetRange]
    puts "annotation.tcl: Length: [labels GetNumberOfTuples]"
    puts "annotation.tcl: Range: [lindex $lRange 0] -> [lindex $lRange 1]"

    puts "annotation.tcl: Colors:"
    puts "annotation.tcl: Length: [colors GetNumberOfTableValues]"

    set Names [ar GetColorTableNames]
    puts "annotation.tcl: Names:"
    array set aNames $Names
    # puts $aNames(4)
    parray aNames

    labels Delete
    colors Delete
    ar Delete
}


#puts "annotation.tcl: old style with external table"
# TestAnnot /home/kteich/subjects/anders/label/lh.annot   /home/kteich/freesurfer/surface_labels.txt
#TestAnnot /projects/birn/nicole/slicer2/Modules/vtkFreeSurferReaders/Tests/lh.annot /projects/birn/nicole/slicer2/Modules/vtkFreeSurferReaders/Tests/surface_labels.txt
# test with HJPark's
# TestAnnot /d/bigsur/slicerdata/freesurferTract/label/lh_aparc.annot  /projects/birn/nicole/slicer2/Modules/vtkFreeSurferReaders/Tests/surface_labels.txt


puts "\n\nannotation.tcl: "
# puts "annotation.tcl: new style with embedded table"
# puts "annotation.tcl: none yet"
# TestAnnot /home/kteich/test_data/surface_annotation/lh.aparc.annot

# TestAnnot /projects/birn/freesurfer/data/BIRN/MGH-Siemens15-JJ/label/rh.cma_aparc.annot
#TestAnnot /projects/birn/nicole/slicer2/Modules/vtkFreeSurferReaders/Tests/lh.aparc.annot

TestAnnot /home/pieper/data/MGH-Siemens15-SP.1-uw/label/rh.aparc.annot /home/nicole/slicer2/Modules/vtkFreeSurferReaders/tcl/Simple_surface_labels2002.txt


# for standalone testing
# exit
