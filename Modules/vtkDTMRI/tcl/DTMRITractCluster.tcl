#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRITractCluster.tcl,v $
#   Date:      $Date: 2006/04/21 20:26:40 $
#   Version:   $Revision: 1.20 $
# 
#===============================================================================
# FILE:        DTMRITractCluster.tcl
# PROCEDURES:  
#   DTMRITractClusterInit
#   DTMRITractClusterBuildClusterFrame
#   DTMRITractClusterApplyUserSettings
#   DTMRITractClusterComputeClusters
#   DTMRITractClusterBuildMatrixViewer
#   DTMRITractClusterSelect widget
#   DTMRITractClusterAdvancedDisplayMatrix input getOutput name
#   DTMRITractClusterAdvancedViewMatrices
#   DTMRITractClusterColorBack
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterInit {} {
    global DTMRI 

    
    # Version info for files within DTMRI module
    #------------------------------------
    set m "TractCluster"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.20 $} {$Date: 2006/04/21 20:26:40 $}]

    set DTMRI(TractCluster,NumberOfClusters) 5
    set DTMRI(TractCluster,Sigma) 20
    set DTMRI(TractCluster,HausdorffN) 15
    set DTMRI(TractCluster,ShapeFeature) MeanClosestPoint
    set DTMRI(TractCluster,ShapeFeature,menu) {MeanClosestPoint MeanAndCovariance Hausdorff EndPoints}

    set DTMRI(TractCluster,SymmetrizeMethod) Min
    set DTMRI(TractCluster,SymmetrizeMethod,menu) {Mean Min Max}

    set DTMRI(TractCluster,EmbeddingNormalization) RowSum
    set DTMRI(TractCluster,EmbeddingNormalization,menu) {RowSum LengthOne None}
    set DTMRI(TractCluster,NumberOfEigenvectors) 2

    set DTMRI(TractCluster,SettingsList,Names) {{Number of Clusters} Sigma N {Fiber Similarity} SymmetrizeMethod EmbedNormalization NumberOfEigenvectors}
    set DTMRI(TractCluster,SettingsList,Variables) {NumberOfClusters Sigma HausdorffN ShapeFeature SymmetrizeMethod EmbeddingNormalization NumberOfEigenvectors}
    set DTMRI(TractCluster,SettingsList,VariableTypes) {entry entry entry menu menu menu entry}
    set DTMRI(TractCluster,SettingsList,Tooltips) {{Number of clusters (colors) when grouping tracts} {Similarity/distance tradeoff} \
            {For Hausdorff fiber similarity, use every Nth point on the tract in computation.}\
            {How to measure tract similarity} {How to make distances symmetric from paths A to B and B to A} {How to normalize the vectors used in clustering}\
            {Advanced: related to number of clusters inherent in the data}}

    # for viewing matrices
    vtkImageMagnify DTMRI(TractCluster,vtk,imageMagnify)
    DTMRI(TractCluster,vtk,imageMagnify) InterpolateOff
    vtkImageMathematics DTMRI(TractCluster,vtk,imageMultiply)
    DTMRI(TractCluster,vtk,imageMultiply) SetOperationToMultiplyByK
    DTMRI(TractCluster,vtk,imageMultiply) SetConstantK 100
    set DTMRI(TractCluster,zoom) 3
}


#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterBuildClusterFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterBuildGUI {} {

    global Gui Module Volume Tensor DTMRI Matrix
    
    #-------------------------------------------
    # TractCluster frame
    #-------------------------------------------
    set fCluster $Module(DTMRI,fTC)
    set f $fCluster

    foreach frame "Top Bottom" {
        frame $f.f$frame -bg  $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # TractCluster->Top frame
    #-------------------------------------------

    set f $fCluster.fTop
    
    frame $f.fLabel -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fLabel -side top -padx $Gui(pad) -pady $Gui(pad) -fill x


    #-------------------------------------------
    # TractCluster->Top->Label frame
    #-------------------------------------------
    set f $fCluster.fTop.fLabel

    DevAddLabel $f.lInfo "Tract Clustering and Coloring"
    eval {$f.lInfo configure} $Gui(BLA)
    pack $f.lInfo -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # TractCluster->Bottom frame
    #-------------------------------------------

    set f $fCluster.fBottom

    frame $f.fSettings -bg  $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fSettings -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    foreach frame "Apply" {
        frame $f.f$frame -bg  $Gui(activeWorkspace) 
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # TractCluster->Bottom->Settings frame
    #-------------------------------------------

    foreach var $DTMRI(TractCluster,SettingsList,Variables) \
        tip $DTMRI(TractCluster,SettingsList,Tooltips) \
        text $DTMRI(TractCluster,SettingsList,Names) \
        type $DTMRI(TractCluster,SettingsList,VariableTypes) {

            set f $fCluster.fBottom.fSettings

            frame $f.f$var -bg  $Gui(activeWorkspace)
            pack $f.f$var -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

            set f $fCluster.fBottom.fSettings.f$var

            DevAddLabel $f.l$var $text
            pack $f.l$var -side left  -padx $Gui(pad) -pady 0

            if {$type == "entry"} {
                eval {entry $f.e$var -width 6 \
                          -textvariable DTMRI(TractCluster,$var)} $Gui(WEA)
                pack $f.e$var -side right -padx $Gui(pad) -pady 0
                TooltipAdd  $f.e$var $tip
            } elseif {$type == "menu"} {
                eval {menubutton $f.mb$var -text "$DTMRI(TractCluster,$var)" \
                          -relief raised -bd 2 -width 20 \
                          -menu $f.mb$var.m} $Gui(WMBA)
                eval {menu $f.mb$var.m} $Gui(WMA)
                pack $f.l$var $f.mb$var -side left -pady $Gui(pad) -padx $Gui(pad)

                # save menubutton for config
                set DTMRI(TractCluster,gui,mb$var) $f.mb$var
                # Add a tooltip
                TooltipAdd $f.mb$var $tip

                # add menu items
                foreach item $DTMRI(TractCluster,$var,menu) {
                    $f.mb$var.m add command \
                        -label $item \
                        -command "set DTMRI(TractCluster,$var) $item; \
                    $f.mb$var config -text $item"
                }
            }
        }

    #-------------------------------------------
    # TractCluster->Bottom->Apply frame
    #-------------------------------------------

    set f $fCluster.fBottom.fApply
    DevAddButton $f.b "Cluster" {DTMRITractClusterComputeClusters}
    pack $f.b -side top -padx $Gui(pad) -pady $Gui(pad)

    TooltipAdd  $f.b "Apply above settings and cluster tracts.\nEach cluster will get a unique color."



}

#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterApplyUserSettings
# Apply all settings from GUI into the vtk objects
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterApplyUserSettings {} {
    global DTMRI 

    # vtk object that encapsulates the clustering pipeline
    set clusterer [DTMRI(vtk,streamlineControl) GetTractClusterer]

    # parameters that get passed down into itk clusterer
    $clusterer SetNumberOfClusters $DTMRI(TractCluster,NumberOfClusters)
    $clusterer SetEmbeddingNormalizationTo$DTMRI(TractCluster,EmbeddingNormalization)
    $clusterer SetNumberOfEigenvectors $DTMRI(TractCluster,NumberOfEigenvectors)

    $clusterer DebugOn

    # parameters of the object that computes the affinity matrix
    set features [$clusterer GetTractAffinityCalculator]
    $features SetSigma $DTMRI(TractCluster,Sigma)
    $features SetHausdorffN $DTMRI(TractCluster,HausdorffN)
    $features SetFeatureTypeTo$DTMRI(TractCluster,ShapeFeature)
    $features SetSymmetrizeMethodTo$DTMRI(TractCluster,SymmetrizeMethod)

}

#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterComputeClusters
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterComputeClusters {} {
    global DTMRI 

    DTMRITractClusterApplyUserSettings

    puts "[DTMRI(vtk,streamlineControl) GetNumberOfStreamlines] streamlines"
    puts "Running clustering..."
    #DTMRI(vtk,streamlineControl) ClusterTracts
    DTMRI(vtk,streamlineControl) ClusterTracts 1
    puts "Done clustering."

    Render3D

}

#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterBuildMatrixViewer
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterBuildMatrixViewer {} {
    global DTMRI Gui

    set w .dtmritractcluster1

    # if already created, raise and return
    if {[winfo exists $w] != 0} {
        raise $w
        # find the name of the viewer to set its input later
        #set tmp [$DTMRI(TractCluster,vtkTkImageViewerWidget) configure -iv]
        #set DTMRI(TractCluster,vtk,viewer) [lindex $tmp end]
        return
    }

    toplevel $w
    wm title $w "Display Matrices"

    # Create the vtkTkImageViewerWidget

    frame $w.f1 

    set dim 50
    set DTMRI(TractCluster,vtkTkImageViewerWidget) \
        [vtkTkImageViewerWidget $w.f1.r1 \
             -width $dim  -height $dim ]

    set widget $DTMRI(TractCluster,vtkTkImageViewerWidget) 

    # Set up some Tk bindings, a generic renwin interactor and VTK observers 
    # for that widget

    ::vtk::bind_tk_imageviewer_widget \
        $widget 

    set iren [[[$widget GetImageViewer] GetRenderWindow] GetInteractor]
    # Add our PickEvent 
    set istyle [$iren GetInteractorStyle]
    #$istyle RemoveObservers PickEvent
    $istyle AddObserver PickEvent \
        [list DTMRITractClusterSelect $widget]
    # add our bindings
    #bind $w.f1 <ButtonPress> {DTMRITractClusterSelect %x %y}

    # find the name of the viewer to set its input later
    set tmp [$widget configure -iv]
    set DTMRI(TractCluster,vtk,viewer) [lindex $tmp end]

    # Set the window manager (wm command) so that it registers a
    # command to handle the WM_DELETE_WINDOW protocal request. This
    # request is triggered when the widget is closed using the standard
    # window manager icons or buttons. In this case the exit callback
    # will be called and it will free objects associated with the window.

    wm protocol $w WM_DELETE_WINDOW "$DTMRI(TractCluster,vtk,viewer) Delete; destroy $w"

    #    bind $widget \
        #        <ButtonPress> "puts %x"
    #        ButtonPress "DTMRITractClusterSelect %x %y"

    pack $widget \
        -side left -anchor n \
        -padx 3 -pady 3 \
        -fill x -expand f

    pack $w.f1 \
        -fill both -expand t

    # create a menu for changing viewer's input
    set f $w.f1
    eval {label $f.lVis -text "Matrix: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text "Choose..." \
              -relief raised -bd 2 -width 15 \
              -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady $Gui(pad) -padx $Gui(pad)

    # save menubutton for config
    set DTMRI(TractCluster,gui,mbMatrixViewer) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis "Select the tract-comparison matrix to view."

    # add a label area below the menu
    eval {label $f.lMat -text ""} $Gui(WLA)
    pack $f.lMat  -side bottom -pady $Gui(pad) -padx $Gui(pad)
    # save label for config
    set DTMRI(TractCluster,gui,lMatrixInfo) $f.lMat
}

#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterSelect
# 
# .ARGS
# windowpath widget
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterSelect {widget} {
    global DTMRI 

    set pos [[[[$widget GetImageViewer] GetRenderWindow] GetInteractor] GetEventPosition]
    set x [lindex $pos 0]
    set y [lindex $pos 1]
    puts "$x $y"

    # y is the row of interest. 
    # select the tract that corresponds to this row.
    # flip y axis, un-zoom, check bounds
    set maxY [lindex [lindex [$widget configure ] 0] end]
    
    if {$y < 0 | $y > $maxY} {
        return
    }
    set y [expr $maxY-$y]

    set y [expr $y/$DTMRI(TractCluster,zoom)]

    # now make that tract highlight yellow twice
    set tracts [DTMRI(vtk,streamlineControl) GetActors]
    set actor [$tracts GetItemAsObject $y]
    if {$actor != ""} {

        set color [[$actor GetProperty] GetColor]
        [$actor GetProperty] SetColor 255 255 0
        Render3D
        eval {[$actor GetProperty] SetColor} $color
        Render3D
        [$actor GetProperty] SetColor 255 255 0
        Render3D
        eval {[$actor GetProperty] SetColor} $color
        Render3D
    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterAdvancedDisplayMatrix
# 
# .ARGS
# string input
# string getOutput
# string name
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterAdvancedDisplayMatrix {input getOutput name} {
    global DTMRI 

    set imageData [$input $getOutput]

    DTMRI(TractCluster,vtk,imageMultiply) SetInput1 $imageData

    DTMRI(TractCluster,vtk,imageMagnify) SetMagnificationFactors \
        $DTMRI(TractCluster,zoom) $DTMRI(TractCluster,zoom) 1
    DTMRI(TractCluster,vtk,imageMagnify) SetInput \
        [DTMRI(TractCluster,vtk,imageMultiply) GetOutput]

    # update so scalar range is right below
    DTMRI(TractCluster,vtk,imageMagnify) Update     

    $DTMRI(TractCluster,vtk,viewer) SetInput \
        [DTMRI(TractCluster,vtk,imageMagnify) GetOutput]
    ${DTMRI(TractCluster,gui,mbMatrixViewer)} config -text $name

    set range [[DTMRI(TractCluster,vtk,imageMagnify) GetOutput] GetScalarRange]
    $DTMRI(TractCluster,gui,lMatrixInfo) config -text $range

    set len [expr [lindex $range 1] - [lindex $range 0]]
    set l [expr [lindex $range 0] + $len/2]
    set w [expr $len + 1]
    $DTMRI(TractCluster,vtk,viewer) SetColorWindow $w
    $DTMRI(TractCluster,vtk,viewer) SetColorLevel $l
    #puts "$w $l"

    # configure widgets to current data
    set dim [DTMRI(vtk,streamlineControl) GetNumberOfStreamlines]
    set dim [expr $dim*$DTMRI(TractCluster,zoom)]
    $DTMRI(TractCluster,vtkTkImageViewerWidget) configure \
        -width $dim -height $dim

    # highlight the last picked streamline
    puts "Active streamline $DTMRI(activeStreamlineID)"

    $DTMRI(TractCluster,vtk,viewer) Render
}

#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterAdvancedViewMatrices
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterAdvancedViewMatrices {} {
    global DTMRI 

    # show/build pop-up window to view output images from computation
    DTMRITractClusterBuildMatrixViewer

    # Add menu items for viewing various images
    set clusterer [DTMRI(vtk,streamlineControl) GetTractClusterer]
    set classifier [$clusterer GetNormalizedCuts]
    set features [$clusterer GetTractShapeFeatures]

    set inputList "$features $features $classifier $classifier"
    set getOutputList "GetInterTractDistanceMatrixImage GetInterTractSimilarityMatrixImage GetNormalizedWeightMatrixImage GetEigenvectorsImage"
    set inputNames "Distance Weights NormWeights Eigenvectors"

    foreach input $inputList name $inputNames get $getOutputList {
        ${DTMRI(TractCluster,gui,mbMatrixViewer)}.m add command \
            -label $name \
            -command "DTMRITractClusterAdvancedDisplayMatrix $input $get $name"

    }

}

#-------------------------------------------------------------------------------
# .PROC DTMRITractClusterColorBack
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRITractClusterColorBack {vol} {
    global DTMRI Volume

    DTMRI(vtk,streamlineControl) SetInputROIForColoring [Volume($vol,vol) GetOutput]
    DTMRI(vtk,streamlineControl) ColorROIFromStreamlines

    set output [DTMRI(vtk,streamlineControl) GetOutputROIForColoring]

    # export output to the slicer environment:
    # slicer MRML volume creation and display
    set v [DevCreateNewCopiedVolume $vol "Color back from clusters" "TractColors_$vol"]
    Volume($v,vol) SetImageData $output
    MainVolumesUpdate $v
    # tell the node what type of data so MRML file will be okay
    Volume($v,node) SetScalarType [$output GetScalarType]
    # display this volume so the user knows something happened
    MainSlicesSetVolumeAll Back $v
    RenderAll

}

