# Load this script in slicer - it will pop up to windows and show two graphs - a one dimensional and a 2D Graph
package require vtkSlicerBase

source [file join $env(SLICER_HOME) Base/tcl/tcl-shared/Graph.tcl]
source [file join $env(SLICER_HOME) Base/tcl/tcl-shared/Tooltips.tcl]
source [file join $env(SLICER_HOME) Base/tcl/tcl-shared/Developer.tcl]
source [file join $env(SLICER_HOME) Base/tcl/tcl-main/Gui.tcl]

proc ParseCVSInfo {blub blubb lbubbb } { }
proc ::vtk::get_widget_variable_value {b c } { return 0 }
proc ::vtk::set_widget_variable_value {b c d} { }
set SLICER(version) 0
GuiInit
wm withdraw .


set Dimension 1
set Xlen 370
set Xmin 10 
set Xmax 100 
set Xsca 20

set Ylen 200
set Ymin 0  
set Ymax 1 
set Ysca 0.5 
set Yfor "%0.2f"
set Blub(blubber) 1


# Display value
set w .blub 
toplevel $w -class Dialog
wm title $w "Display Class Distribution"
wm iconname $w Dialog
# if {$Gui(pc) == "0"} { wm transient $w . }

GraphCreate Blub $w $Xlen $Ylen "" "0 0" 0 $Dimension 1 "" $Xmin  $Xmax $Xsca "%d" $Ymin $Ymax $Ysca $Yfor 1
GraphCreateGaussianCurveRegion Blub($w) 3 1.0 1.0 2 $Dimension $Xmin $Xmax $Xlen $Ymin $Ymax $Ylen 
GraphAddCurveRegion Blub $w [Blub($w) GetOutput]  [GraphHexToRGB 00ff00] 0 0

# Change value 
Blub($w) SetMean 4.0 0 
Blub($w) SetCovariance 0.1 0 0 
Blub($w) Update
GraphRender Blub $w 

# 2 Dimesions 
set w .blub2 
set Dimension 2
set Yfor "%3.0f"

toplevel $w -class Dialog
wm title $w "Display Class Distribution2"
wm iconname $w Dialog
# if {$Gui(pc) == "0"} { wm transient $w . }
GraphCreate Blub $w $Xlen $Xlen "" "0 0" 0 $Dimension 1 "" $Xmin  $Xmax $Xsca "%d" $Xmin $Xmax $Xsca $Yfor 1
GraphCreateGaussianCurveRegion Blub($w) "4 3.7"  "0.1 0 0 0.2" 1.0 2 $Dimension $Xmin $Xmax $Xlen $Xmin $Xmax $Xlen 
GraphAddCurveRegion Blub $w [Blub($w) GetOutput] [GraphHexToRGB 00ff00] 0 0

# 3 Histogram  
  set w .blub3 
  set Dimension 1
  set Yfor "%4.0f"
  
  toplevel $w -class Dialog
  wm title $w "Histogram"
  wm iconname $w Dialog
  
  vtkImageReader Volume(1,vol)
    Volume(1,vol) ReleaseDataFlagOff
    Volume(1,vol) SetDataScalarTypeToShort 
    Volume(1,vol) SetDataSpacing 0.9375 0.9375 1.5
    Volume(1,vol) SetFilePattern %s.%03d 
    Volume(1,vol) SetFilePrefix  $env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/Tests/TestImageEMAtlasSPGR 
    eval Volume(1,vol) SetDataExtent 0 255 0 255 1 3
    Volume(1,vol) SetNumberOfScalarComponents 1 
    Volume(1,vol) SetDataByteOrderToLittleEndian
  Volume(1,vol) Update

  set Xmax 200
  set Hist(blub) 1
  GraphCreate Hist $w $Xlen $Ylen "" "0 0" 0 $Dimension 1 "" $Xmin  $Xmax $Xsca "%d" $Ymin $Ymax $Ysca $Yfor 1
  GraphCreateHistogramCurve  Hist($w) [Volume(1,vol) GetOutput]  $Xmin $Xmax $Xlen
  set Hist(ID) [GraphAddCurveRegion Hist $w [Hist($w) GetOutput] [GraphHexToRGB 00ff00] 0 0]

proc HistGraphXAxisUpdate {path Xmin Xmax Xsca} {
    global Hist Graph

    set dist [expr $Xmax - $Xmin]
    Hist($path)Accu SetComponentOrigin $Xmin 0.0 0.0   
    Hist($path)Accu SetComponentExtent 0 [expr int($dist - 1)] 0 0 0 0  
    Hist($path)Accu UpdateWholeExtent 
    Hist($path)Accu Update

    # I have to redrap it bc vtkImageResample does not update wholextent correctly once  MathGraph($path,Curve,$i)Accu  has changed 
    # - I do not know hy but wasted a lot of time
    # Hist($path) SetAxisMagnificationFactor 0  $Hist(Graph,$path,XInvUnit)
    # Hist($path) Update 
    # set Hist(Graph,$path,XInvUnit)    [GraphAdjustResampledCurve Hist($path) $XInvUnit $Hist(Graph,$path,Xlen)]

    GraphRemoveCurve Hist $path $Hist(ID)
    GraphCreateResampledCurve Hist($path)  [Hist($path)Accu GetOutput]  $Hist(Graph,$path,XInvUnit) 
    set Hist(Graph,$path,XInvUnit)     [GraphAdjustResampledCurve  Hist($path)  $Hist(Graph,$path,XInvUnit) $::Xlen]

    set Hist(ID) [GraphAddCurveRegion Hist $path [Hist($path) GetOutput] [GraphHexToRGB 00ff00] 0 0]

    # So we can make sure that the y values are properly updated
    set Graph(Ymin) [lindex [Hist($path)Accu GetMin] 0]
    set Graph(Ymax) [lindex [Hist($path)Accu GetMax] 0]  
    set Graph(Ysca) [expr int(($Graph(Ymax) - $Graph(Ymin))/2.0)]
    GraphUpdateValues Hist $path

    # Update y axis 
}



proc BlubGraphXAxisUpdate {path Xmin Xmax Xsca} {
    global Blub Graph
    Blub($path) SetXmin $Xmin
    Blub($path) SetXmax $Xmax
    Blub($path) Update
    if {$Blub(Graph,$path,Dimension) == 1 } {
    set Graph(Ymin) [Blub($path) GetFctMin] 
    set Graph(Ymax) [Blub($path) GetFctMax] 
    if {$Graph(Ymin) != $Graph(Ymax)} {
        set Graph(Ysca) [expr ($Graph(Ymax) - $Graph(Ymin))/2.0 *0.99 ]
    }
    GraphUpdateValues Blub $path
    }
}

proc BlubGraphYAxisUpdate {path Ymin Ymax Ysca} {
    global Blub
    Blub($path) SetYmin  $Ymin
    Blub($path) SetYmax $Ymax
    Blub($path) Update
}
