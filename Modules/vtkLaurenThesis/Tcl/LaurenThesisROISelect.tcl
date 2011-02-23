proc LaurenThesisROISelectInit {} {

    global LaurenThesis Volume
    
    # labelmap ID numbers
    set LaurenThesis(vROIA) -1
    set LaurenThesis(vROIB) -1
    set LaurenThesis(vROIC) -1
    set LaurenThesis(vROID) -1
    
    # directory where the vtk tract models are
    set LaurenThesis(clusterDirectory) ""
    set LaurenThesis(ROISelectOutputDirectory) ""
    set LaurenThesis(outputFilename) "ClusterROISelect.vtk"
}

proc LaurenThesisROISelectBuildGUI {} {

    global Gui LaurenThesis Module Volume

    #-------------------------------------------
    # ROISelect frame
    #-------------------------------------------
    set fROISelect $Module(LaurenThesis,fROISelect)
    set f $fROISelect
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # ROISelect->Top frame
    #-------------------------------------------
    set f $fROISelect.fTop
    DevAddLabel $f.lHelp "Select tracts based on ROIs."

    pack $f.lHelp -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ROISelect->Middle frame
    #-------------------------------------------
    set f $fROISelect.fMiddle
    foreach frame "ROIA ROIB ROIC ROID Directory OutputDirectory" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # ROISelect->Middle->ROIA frame
    #-------------------------------------------
    set f $fROISelect.fMiddle.fROIA

    # menu to select a volume: will set LaurenThesis(vROI)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name vROIA
    DevAddSelectButton  LaurenThesis $f $name "ROI A:" Pack \
        "ROIA" \
        25

    #-------------------------------------------
    # ROISelect->Middle->ROIB frame
    #-------------------------------------------
    set f $fROISelect.fMiddle.fROIB

    # menu to select a volume: will set LaurenThesis(vROI)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name vROIB
    DevAddSelectButton  LaurenThesis $f $name "ROI B:" Pack \
        "ROIB" \
        25

    #-------------------------------------------
    # ROISelect->Middle->ROIA frame
    #-------------------------------------------
    set f $fROISelect.fMiddle.fROIC

    # menu to select a volume: will set LaurenThesis(vROI)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name vROIC
    DevAddSelectButton  LaurenThesis $f $name "ROI C:" Pack \
        "ROIC" \
        25

    #-------------------------------------------
    # ROISelect->Middle->ROIB frame
    #-------------------------------------------
    set f $fROISelect.fMiddle.fROID

    # menu to select a volume: will set LaurenThesis(vROI)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name vROID
    DevAddSelectButton  LaurenThesis $f $name "ROI D:" Pack \
        "ROID" \
        25
    #-------------------------------------------
    # ROISelect->Middle->Directory frame
    #-------------------------------------------
    set f $fROISelect.fMiddle.fDirectory

    eval {button $f.b -text "Tract directory:" -width 16 \
        -command "LaurenThesisSelectDirectory"} $Gui(WBA)
    eval {entry $f.e -textvariable LaurenThesis(clusterDirectory) -width 51} $Gui(WEA)
    bind $f.e <Return> {LaurenThesisSelectDirectory}
    pack $f.b -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -fill x -expand 1

    #-------------------------------------------
    # ROISelect->Middle->Output Directory frame
    #-------------------------------------------
    set f $fROISelect.fMiddle.fOutputDirectory

    eval {button $f.b -text "Output file:" -width 16 \
        -command "LaurenThesisSelectOutputDirectory"} $Gui(WBA)
    eval {entry $f.e -textvariable LaurenThesis(ROISelectOutputDirectory) -width 51} $Gui(WEA)
    bind $f.e <Return> {LaurenThesisSelectOutputDirectory}
    pack $f.b -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -fill x -expand 1
    #-------------------------------------------
    # ROISelect->Bottom frame
    #-------------------------------------------
    set f $fROISelect.fBottom

    DevAddButton $f.bApply "Apply" \
        LaurenThesisValidateParametersAndSelectTracts
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Sample tensors at all points in the tract cluster models. Save new models."

}

proc LaurenThesisSelectDirectory {} {
    global LaurenThesis

    set dir $LaurenThesis(clusterDirectory)

    if {[catch {set filename [tk_chooseDirectory -title "Cluster Directory" \
                                  -initialdir "$dir"]} errMsg] == 1} {
        DevErrorWindow "LaurenThesisSelectDirectory: error selecting cluster directory:\n$errMsg"
        return ""
    }

    set LaurenThesis(clusterDirectory) $filename
}

proc LaurenThesisSelectOutputDirectory {} {
    global LaurenThesis

    set dir $LaurenThesis(clusterDirectory)

    if {[catch {set filename [tk_getSaveFile -title "Output file" -defaultextension ".vtk"\
                                  -initialdir "$dir" -initialfile $LaurenThesis(outputFilename)]} errMsg] == 1} {
        DevErrorWindow "LaurenThesisSelectOutputDirectory: error selecting output directory:\n$errMsg"
        return ""
    }

  #  if {[catch {set filename [tk_chooseDirectory -title "Output Directory" \
  #                                -initialdir "$dir"]} errMsg] == 1} {
  #      DevErrorWindow "LaurenThesisSelectOutputDirectory: error selecting output directory:\n$errMsg"
  #      return ""
  #  }

    set LaurenThesis(ROISelectOutputDirectory) $filename
}

proc LaurenThesisROISelectUpdateMRML {} {

    global LaurenThesis

    # Update volume selection widgets if the MRML tree has changed

    DevUpdateNodeSelectButton Volume LaurenThesis vROIA vROIA \
        DevSelectNode 1 0 1 

    DevUpdateNodeSelectButton Volume LaurenThesis vROIB vROIB \
        DevSelectNode 1 0 1 
 
    DevUpdateNodeSelectButton Volume LaurenThesis vROIC vROIC \
        DevSelectNode 1 0 1 

    DevUpdateNodeSelectButton Volume LaurenThesis vROID vROID \
        DevSelectNode 1 0 1 

}

# this gets called when the user hits Apply
proc LaurenThesisValidateParametersAndSelectTracts {} {
    global LaurenThesis

    # check that the user entered parameters are okay
    # fill this in if needed
    
    puts "This is ROI a: $LaurenThesis(vROIA)"
    puts "This is ROI b:$LaurenThesis(vROIB)"
    puts "This is ROI c:$LaurenThesis(vROIC)"
    puts "This is ROI d:$LaurenThesis(vROID)"
    
    # check if an output file has been selected
    if {($LaurenThesis(ROISelectOutputDirectory) == "") || [file exists [file dirname $LaurenThesis(ROISelectOutputDirectory)]] ==0 } {
        DevErrorWindow "LaurenThesisValidateParametersAndSelectTracts: No output direcoty selected or selected direcoty does not exist: [file dirname $LaurenThesis(ROISelectOutputDirectory)]"
        return ""
    }
        
    # call the code that does something
    LaurenThesisSelectTracts $LaurenThesis(vROIA) $LaurenThesis(vROIB) $LaurenThesis(vROIC) $LaurenThesis(vROID) $LaurenThesis(clusterDirectory)

}

# this actually reads in all the models in the directory
proc LaurenThesisSelectTracts {vROIA vROIB vROIC vROID directory} {

    global LaurenThesis

    # Load all models in the directory of the form $pattern
    # for now look at all vtk models in the directory
    # perhaps make this match the case name
    set pattern "*_*.vtk"

    set models [lsort [glob -nocomplain -directory $directory $pattern]]

    # test we found models
    if {$models == ""} {
        puts "ERROR: No models with filenames *_*.vtk were found in the directory"
        return
    }

    catch {appender Delete}
    vtkAppendPolyData appender

    # go through all model filenames
    foreach model $models {
        puts $model

        # read in the model as polydata
        catch {_reader Delete}
        vtkPolyDataReader _reader
        _reader SetFileName $model
        _reader Update

        # error check
        if {[_reader GetOutput] == "" } {
            puts "ERROR, file $model could not be read."
            _reader Delete
            return
        } else {
            puts "Read model $model "
        }

        # call the code to see if this model intersects the ROI
        set intersectROI [LaurenThesisTestTractIntersectsROI \
                              $vROIA $vROIB $vROIC $vROID [_reader GetOutput]]

        # if it passes
        # append to vtkAppendPolyData
        if { $intersectROI == 1} {
            puts "This fiber passes all the ROIs: $model"
            appender AddInput [_reader GetOutput]
        }

        # delete the reader
        _reader Delete
    }

    # write out the tracts that passed the ROI test
    catch {_writer Delete}
    vtkPolyDataWriter _writer
    # get output from the vtkAppendPolyData
    _writer SetInput [appender GetOutput]
    _writer SetFileName $LaurenThesis(ROISelectOutputDirectory)
    _writer Write
    
    _writer Delete
    appender Delete
}

# arguments: ID number of the labelmaps and the polydata object
# return 1 when model passes the test, otherwise return 0
proc LaurenThesisTestTractIntersectsROI {vROIA vROIB vROIC vROID polyData } {
    global Model Tensor Module

    set select_this_fiber 1

    foreach labelmap "$vROIA $vROIB $vROIC $vROID" {
        # check if labelmap equals the none volume
        if {$labelmap != 0} {  
            
            catch {_probe Delete}
            vtkProbeFilter _probe
            _probe SetSource [Volume($labelmap,vol) GetOutput]
            
              # transform model into IJK of data
            # This assumes the model is already aligned
            # with the tensors in the world coordinate system.
            catch {_transform Delete}
            vtkTransform _transform
            #_transform PreMultiply
            _transform SetMatrix [Volume($labelmap,node) GetWldToIjk]
            # remove scaling from matrix
            # invert it to give ijk->ras, so we can scale with i,j,k spacing
            _transform Inverse
            scan [Volume($labelmap,node) GetSpacing] "%g %g %g" res_x res_y res_z
            _transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
                [expr 1.0 / $res_z]
            _transform Inverse
            
            catch {_transformPD Delete}
            vtkTransformPolyDataFilter _transformPD
            _transformPD SetTransform _transform
            _transformPD SetInput $polyData
            _transformPD Update

            # probe with model in IJK
            _probe SetInput [_transformPD GetOutput]
            _probe Update
            
            set pd [_probe GetOutput] 
            #puts "Number of points for this tract:[$pd GetNumberOfPoints]"
            
            set scalars [[$pd GetPointData] GetScalars]
            set scalar_range [[[$pd GetPointData] GetScalars] GetRange]
            #puts "Range: $scalar_range"

            _probe Delete
            _transform Delete
            _transformPD Delete
            
            if { ([lindex $scalar_range 1] == 0) } {
                # in this case this fiber doesn't run through one of the ROIs
                return 0
            }
        }
    }
    # if proc has not retuned 0 up to this point the fiber runs through all labelmaps    
    return 1
}

# this function loads labelmap_files 1 to 4 (if stated) and calls LaurenThesisSelectTracts
proc LaurenThesis_ROISelect_Batch {clusterDir outputFile {labelmap_file1 ""} {labelmap_file2 ""} {labelmap_file3 ""} {labelmap_file4 ""}} {
    
    global LaurenThesis Volumes Volume
    
    # directory where the vtk tract models are
    if {![file exists $clusterDir]} { 
        DevErrorWindow "LaurenThesis_ROISelect_Batch: Directory $clusterDir does not exist\n"
        return ""
    } 
    if {![file exists [file dirname $outputFile]]} {
        DevErrorWindow "LaurenThesis_ROISelect_Batch: File $outputFile does not exist\n"
        return ""
    } 

    set LaurenThesis(clusterDirectory) $clusterDir
    puts "Cluster directory set to $LaurenThesis(clusterDirectory)"
    set LaurenThesis(ROISelectOutputDirectory) $outputFile
    puts "Output file set to $LaurenThesis(ROISelectOutputDirectory)"

    # labelmap ID numbers
    set LaurenThesis(vROIA) -1
    set LaurenThesis(vROIB) -1
    set LaurenThesis(vROIC) -1
    set LaurenThesis(vROID) -1
    
    if {$labelmap_file1 != ""} {
        if {[file exists $labelmap_file1]} {
            # load labelmap
            puts "Load labelmap $labelmap_file1 ..."
            set Volume(labelMap) 1
            set Volume(VolNrrd,FileName) $labelmap_file1
            VolNrrdSetFileName
            set LaurenThesis(vROIA) [VolNrrdApply]
            puts "This is now LaurenThesis(vROIA): $LaurenThesis(vROIA) "
        } else {
            DevErrorWindow "LaurenThesis_ROISelect_Batch: Labelmap file $labelmap_file1 does not exist\n"
            return ""
        } 
    }
    if {$labelmap_file2 != ""} {
         if {[file exists $labelmap_file2]} {
             # load labelmap
             puts "Load labelmap $labelmap_file2 ..."
             set Volume(labelMap) 1
             set Volume(VolNrrd,FileName) $labelmap_file2
             VolNrrdSetFileName
             set LaurenThesis(vROIB) [VolNrrdApply]
             puts "This is now LaurenThesis(vROIB): $LaurenThesis(vROIB) "
         } else {
             DevErrorWindow "LaurenThesis_ROISelect_Batch: Labelmap file $labelmap_file2 does not exist\n"
             return ""
         } 

     }
    if {$labelmap_file3 != ""} {
         if {[file exists $labelmap_file3]} {
             # load labelmap
             puts "Load labelmap $labelmap_file3 ..."
             set Volume(labelMap) 1
             set Volume(VolNrrd,FileName) $labelmap_file3
             VolNrrdSetFileName
             set LaurenThesis(vROIC) [VolNrrdApply]
         } else {
             DevErrorWindow "LaurenThesis_ROISelect_Batch: Labelmap file $labelmap_file3 does not exist\n"
             return ""
         } 
    }
    if {$labelmap_file4 != ""} {
        if {[file exists $labelmap_file4]} {
             # load labelmap
             puts "Load labelmap $labelmap_file4 ..."
             set Volume(labelMap) 1
             set Volume(VolNrrd,FileName) $labelmap_file4
             VolNrrdSetFileName
             set LaurenThesis(vROID) [VolNrrdApply]
         } else {
             DevErrorWindow "LaurenThesis_ROISelect_Batch: Labelmap file $labelmap_file4 does not exist\n"
             return ""
         } 

     }

    puts ""    
    puts "This is ROI a: $LaurenThesis(vROIA)"
    puts "This is ROI b: $LaurenThesis(vROIB)"
    puts "This is ROI c: $LaurenThesis(vROIC)"
    puts "This is ROI d: $LaurenThesis(vROID)"
    
    LaurenThesisSelectTracts $LaurenThesis(vROIA) $LaurenThesis(vROIB) $LaurenThesis(vROIC) $LaurenThesis(vROID) $LaurenThesis(clusterDirectory)
                                                                                          
}
