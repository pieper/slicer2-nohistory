# Load this script in slicer - it will pop up to windows and show two graphs - a one dimensional and a 2D Graph
set w .blub 
toplevel $w -class Dialog
wm title $w "Display Class Distribution"
wm iconname $w Dialog
# if {$Gui(pc) == "0"} { wm transient $w . }

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
GraphCreate Blub $w $Xlen $Ylen "" "0 0" 0 $Dimension 1 "" $Xmin  $Xmax $Xsca "%d" $Ymin $Ymax $Ysca $Yfor 1
GraphCreateGaussianCurveRegion BlubCurve 3 1.0 1.0 2 $Dimension $Xmin $Xmax $Xlen $Ymin $Ymax $Ylen 
GraphAddCurveRegion Blub $w [BlubCurve GetOutput] [GraphHexToRGB 00ff00] 0 0

# Change value 
BlubCurve SetMean 4.0 0 
BlubCurve SetCovariance 0.1 0 0 
BlubCurve Update
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
GraphCreateGaussianCurveRegion BlubCurve2 "4 3.7"  "0.1 0 0 0.2" 1.0 2 $Dimension $Xmin $Xmax $Xlen $Xmin $Xmax $Xlen 
GraphAddCurveRegion Blub $w [BlubCurve2 GetOutput][GraphHexToRGB 00ff00] 0 0


