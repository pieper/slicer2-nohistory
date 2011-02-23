
proc LaurenThesisProbeClustersInit {} {

    global LaurenThesis Volume
    
    set LaurenThesis(tTensor2) -1

    set LaurenThesis(clusterDirectory) ""
}

proc LaurenThesisProbeClustersBuildGUI {} {

    global Gui LaurenThesis Module Volume

    #-------------------------------------------
    # ProbeClusters frame
    #-------------------------------------------
    set fProbeClusters $Module(LaurenThesis,fProbeClusters)
    set f $fProbeClusters
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # ProbeClusters->Top frame
    #-------------------------------------------
    set f $fProbeClusters.fTop
    DevAddLabel $f.lHelp "Sample tensors at all points in tract clusters."

    pack $f.lHelp -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ProbeClusters->Middle frame
    #-------------------------------------------
    set f $fProbeClusters.fMiddle
    foreach frame "Tensor Directory" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # ProbeClusters->Middle->Tensor frame
    #-------------------------------------------
    set f $fProbeClusters.fMiddle.fTensor

    # menu to select a volume: will set LaurenThesis(tTensor2)
    # works with DevUpdateNodeSelectButton in UpdateMRML
    set name tTensor2
    DevAddSelectButton  LaurenThesis $f $name "Tensor dataset:" Pack \
        "Tensor volume data to sample with clusters" \
        25

    #-------------------------------------------
    # ProbeClusters->Middle->Directory frame
    #-------------------------------------------
    set f $fProbeClusters.fMiddle.fDirectory

    eval {button $f.b -text "Cluster directory:" -width 16 \
        -command "LaurenThesisSelectDirectory"} $Gui(WBA)
    eval {entry $f.e -textvariable LaurenThesis(clusterDirectory) -width 51} $Gui(WEA)
    bind $f.e <Return> {LaurenThesisSelectDirectory}
    pack $f.b -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -fill x -expand 1

    #-------------------------------------------
    # ProbeClusters->Bottom frame
    #-------------------------------------------
    set f $fProbeClusters.fBottom

    DevAddButton $f.bApply "Apply" \
        LaurenThesisValidateParametersAndProbeClusters
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


proc LaurenThesisProbeClustersUpdateMRML {} {

    global LaurenThesis

    # Update volume selection widgets if the MRML tree has changed

    DevUpdateNodeSelectButton Tensor LaurenThesis tTensor2 tTensor2 \
        DevSelectNode 0 0 0 


}


proc LaurenThesisValidateParametersAndProbeClusters {} {
    global LaurenThesis

    LaurenThesisProbeTensorsWithClustersInDirectory $LaurenThesis(tTensor2) $LaurenThesis(clusterDirectory)

}


proc LaurenThesisProbeTensorsWithClustersInDirectory {tTensor directory} {

    # Load all models in the directory of the form
    # tract_#####.vtk (five digits in place of #####)

    set pattern "tract_\[0-9\]\[0-9\]\[0-9\]\[0-9\]\[0-9\].vtk"

    set models [lsort [glob -nocomplain -directory $directory $pattern]]

    if {$models == ""} {
        puts "ERROR: No models with filenames tract_*.vtk were found in the directory"
        return
    }

    foreach model $models {
        puts $model

        vtkPolyDataReader _reader
        _reader SetFileName $model
        _reader Update
        
        if {[_reader GetOutput] == "" } {
            puts "ERROR, file $model could not be read."
            _reader Delete
            return
        }

        set newPD [LaurenThesisProbeTensorWithPolyData \
                       $tTensor [_reader GetOutput] ]
        
        # Save new model to disk
        set filename [file root [file tail $model]]
        set filename [file join $directory ${filename}_Tensors.vtk]
        vtkPolyDataWriter _writer
        _writer SetInput [$newPD  GetOutput]
        _writer SetFileName $filename
        _writer Write
        
        $newPD Delete
        _writer Delete
        _reader Delete
    }


}


proc LaurenThesisProbeTensorWithPolyData {t polyData } {

    global Model Tensor Module

    vtkProbeFilter _probe
    
    _probe SetSource [Tensor($t,data) GetOutput]
    
    # transform model into IJK of data
    # This assumes the model is already aligned
    # with the tensors in the world coordinate system.
    vtkTransform _transform
    #_transform PreMultiply
    _transform SetMatrix [Tensor($t,node) GetWldToIjk]
    # remove scaling from matrix
    # invert it to give ijk->ras, so we can scale with i,j,k spacing
    _transform Inverse
    scan [Tensor($t,node) GetSpacing] "%g %g %g" res_x res_y res_z
    _transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
        [expr 1.0 / $res_z]
    _transform Inverse
    
    vtkTransformPolyDataFilter _transformPD
    _transformPD SetTransform _transform
    _transformPD SetInput $polyData
    _transformPD Update
    
    # probe with model in IJK
    _probe SetInput [_transformPD GetOutput]
    _probe Update
    
    # transform model back into RAS
    catch {vtkTransformPolyDataFilter _transformPD2}
    vtkTransform _transform2
    #_transform2 PreMultiply
    _transform2 SetMatrix [Tensor($t,node) GetWldToIjk]
    # remove scaling from matrix
    _transform2 Inverse
    scan [Tensor($t,node) GetSpacing] "%g %g %g" res_x res_y res_z
    _transform2 Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
        [expr 1.0 / $res_z]

    _transformPD2 SetTransform _transform2
    _transformPD2 SetInput [_probe GetOutput]
    _transformPD2 Update
    

    _probe Delete
    _transform Delete
    _transform2 Delete
    _transformPD Delete
    #_transformPD2 Delete

    return _transformPD2

}


proc LaurenThesisProbeClusters {t outputDirectory} {
    global Model Tensor Module Volume

    foreach m $Model(idList) {
        puts $m
        vtkProbeFilter _probe
        
        _probe SetSource [Tensor($t,data) GetOutput]
        #_probe SetSource [Volume(7,vol) GetOutput]
        
        # transform model into IJK of data
        # This assumes the model is already aligned
        # with the tensors in the world coordinate system.
        vtkTransform _transform
        #_transform PreMultiply
        _transform SetMatrix [Tensor($t,node) GetWldToIjk]
        # remove scaling from matrix
        # invert it to give ijk->ras, so we can scale with i,j,k spacing
        _transform Inverse
        scan [Tensor($t,node) GetSpacing] "%g %g %g" res_x res_y res_z
        _transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
            [expr 1.0 / $res_z]
        _transform Inverse

        vtkTransformPolyDataFilter _transformPD
        _transformPD SetTransform _transform
        _transformPD SetInput $Model($m,polyData) 
        _transformPD Update

        # probe with model in IJK
        _probe SetInput [_transformPD GetOutput]
        _probe Update
        
        
        # transform model back into RAS
        vtkTransformPolyDataFilter _transformPD2        
        vtkTransform _transform2
        #_transform2 PreMultiply
        _transform2 SetMatrix [Tensor($t,node) GetWldToIjk]
        # remove scaling from matrix
        _transform2 Inverse
        scan [Tensor($t,node) GetSpacing] "%g %g %g" res_x res_y res_z
        _transform2 Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
            [expr 1.0 / $res_z]

        _transformPD2 SetTransform _transform2
        _transformPD2 SetInput [_probe GetOutput]
        _transformPD2 Update
        
        # save input for testing
        #set Model($m,oldPD) $Model($m,polyData)
        
        # Replace model with new probed one
        #set Model($m,polyData) [_transformPD GetOutput]
        
        #puts [$Model($m,polyData) Print]

        #foreach r $Module(Renderers) {
        #    Model($m,mapper,$r) SetInput $Model($m,polyData)
        #}
        
        # Save new model to disk
        set filename [file join $outputDirectory Tract_${m}_Tensors.vtk]
        vtkPolyDataWriter _writer
        _writer SetInput [_transformPD2 GetOutput]
        _writer SetFileName $filename
        _writer Write
        

        _probe Delete
        _transform Delete
        _transform2 Delete
        _transformPD Delete
        _transformPD2 Delete
        _writer Delete
    }

}

