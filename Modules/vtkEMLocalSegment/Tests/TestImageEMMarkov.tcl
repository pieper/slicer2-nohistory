package require vtk
package require vtkSlicerBase

# This script allows the direct access of the vtkImageEMMarkov Filter. It is very useful for batch processing.
# Function can be called through
# setenv SLICER_HOME /home/ai2/kpohl/slicer_devel/slicer2
# setenv LD_LIBRARY_PATH ${SLICER_HOME}/Base/builds/debian_gcc/bin:${LD_LIBRARY_PATH}
# setenv TCLLIBPATH "${SLICER_HOME}/Base/Wrapping/Tcl/vtkSlicerBase ${SLICER_HOME}/Base/builds/debian-gcc/bin"
# /home/ai2/kpohl/slicer_devel/vtk4.0/VTK-build/bin/vtk TestImageEMMarkovV2.tcl

# This version is shorter and includes subclasses 


#-------------------------------------------------------------------------------
# 1. Step Init Data 
#-------------------------------------------------------------------------------
# To the power of 2 ! => 3 => 2^3 grids
# For CheckerBoard
# Do not Change 
set TestGridNumber 4
# Do not Change 
set TestMaxValue 255

set TestDivStart 5
set ImageIncr [expr int(($TestMaxValue+1)/($TestGridNumber - 1))]
set ImageDimAxis 255
set EMSegment(StartSlice) 1
set EMSegment(EndSlice) 4
set ImageExtend "0 $ImageDimAxis 0 $ImageDimAxis [expr $EMSegment(StartSlice)-1] [expr $EMSegment(EndSlice)-1]"

set EMSegment(GlobalSuperClassList) "0 3 6"
set EMSegment(Cattrib,0,ClassList) "1 2 3" 
set EMSegment(Cattrib,3,ClassList) "4 5 6" 
set EMSegment(Cattrib,6,ClassList) "" 
set MaxClass 6

set Label 0
for {set i 1} {$i <= $MaxClass} {incr i} {
    if {[expr $i%3] == 0} {
       set EMSegment(Cattrib,$i,IsSuperClass) 1
    } else {
       set EMSegment(Cattrib,$i,IsSuperClass) 0
       set EMSegment(Cattrib,$i,Label) $Label
       incr Label $ImageIncr 
    }
}

set EMSegment(debug) 0
set EMSegment(CIMList) {West North Up East South Down}

#-------------------------------------------------------------------------------
# 2. Step Generate Image (Checlerboard)
#-------------------------------------------------------------------------------
proc TestGrid {Number Div} {
    set index 0
    set NumberBefore [expr  $Number*2]
    for {set i 0 } {$i < $Number} {incr i} {
    vtkImageCheckerboard checkers${Number}.$i
        # Do it to flip also in Z direction - first level is different in any of the 6 directions 
        if {$i ==0 && $Number == 1} {
           vtkImageFlip flipX
           flipX SetInput [checkers${NumberBefore}.$index GetOutput] 
           flipX SetFilteredAxis 1
           checkers${Number}.$i SetInput 0 [flipX GetOutput]
           flipX Delete
    } else {
      checkers${Number}.$i SetInput 0 [checkers${NumberBefore}.$index GetOutput]
    }
    incr index
    checkers${Number}.$i SetInput 1 [checkers${NumberBefore}.$index GetOutput]
    incr index 
    checkers${Number}.$i SetNumberOfDivisions [expr $Div+$i] [expr $Div+$i+1] 3 
    }
    if {$Number == 1} {return}
    TestGrid [expr $Number/2] [expr $Div*2]
}

# a. Generate blank Image
vtkImageNoiseSource plainPicture
eval plainPicture SetWholeExtent $ImageExtend
plainPicture SetMinimum 0.0
plainPicture SetMaximum 0.0
plainPicture ReleaseDataFlagOff

# b. Generate blank Images with different values
set ImageValue 0
set ImageIncrBig  [expr $ImageIncr*int($TestGridNumber / 2)]

for {set i 0 } {$i < $TestGridNumber} {incr i} {
  vtkImageThreshold checkers${TestGridNumber}.$i  
  checkers${TestGridNumber}.$i SetInput [plainPicture GetOutput]
  checkers${TestGridNumber}.$i ThresholdByLower 1.0
  checkers${TestGridNumber}.$i SetInValue $ImageValue
  checkers${TestGridNumber}.$i SetOutValue $ImageValue
  checkers${TestGridNumber}.$i SetOutputScalarTypeToShort
  # So they are in the right order 
  if {[expr $i%2]} {set ImageValue [expr int($ImageIncr*($i+1)/2)]
  } else {incr ImageValue $ImageIncrBig}
}
# c. Generate Grid 
TestGrid [expr $TestGridNumber/2] $TestDivStart

#-------------------------------------------------------------------------------
# 3. Step Start Program 
#-------------------------------------------------------------------------------
proc EMSegmentSuperClassChildrenLabel {SuperClass} {
    global EMSegment
    if {$EMSegment(Cattrib,$SuperClass,IsSuperClass) == 0} {
    return     $EMSegment(Cattrib,$SuperClass,Label)
    }
    set result ""
    foreach i $EMSegment(Cattrib,$SuperClass,ClassList) {
    if {$EMSegment(Cattrib,$i,IsSuperClass)} {
           # it is defined as SetType<TYPE> <ID>  
       set result "$result [EMSegmentSuperClassChildrenLabel $i]" 
    } else {
        lappend result $EMSegment(Cattrib,$i,Label)  
    }
     } 
     return $result
}


proc EMSegmentTrainCIMField {} {
    global EMSegment Volume
    # Transferring Information
    puts "========================== Start Training ======================="
    foreach i $EMSegment(GlobalSuperClassList) {
        puts "Train for Super Class $i"
        if {$i ==3} {puts "In the next line it should display 98332 missfits"}
    vtkImageEMMarkov EMCIM    
    # EM Specific Information
    set NumClasses [llength $EMSegment(Cattrib,$i,ClassList)]
        EMCIM SetNumClasses     $NumClasses  
    EMCIM SetStartSlice     $EMSegment(StartSlice)
    EMCIM SetEndSlice       $EMSegment(EndSlice)

        # Kilian : Get rid of those 
    EMCIM SetImgTestNo       -1 
    EMCIM SetImgTestDivision  0 
    EMCIM SetImgTestPixel     0 
        set index 0
        foreach j $EMSegment(Cattrib,$i,ClassList) {
        set LabelList [EMSegmentSuperClassChildrenLabel $j]
        EMCIM SetLabelNumber $index [llength $LabelList]
        foreach l $LabelList {
        EMCIM SetLabel $index $l
        }
            incr index
    }

    # Transfer image information
    EMCIM SetInput [checkers1.0 GetOutput]
    set data [EMCIM GetOutput]
    # This Command calls the Thread Execute function
    $data Update
    set xindex 0 
    foreach x $EMSegment(Cattrib,$i,ClassList) {
        set EMSegment(Cattrib,$x,Prob) [EMCIM GetProbability $xindex]
        set yindex 0
        # EMCIM traines the matrix (y=t, x=t-1) just the other way EMSegment (y=t-1, x=t) needs it - Sorry !
        foreach y $EMSegment(Cattrib,$i,ClassList) {
        for {set z 0} {$z < 6} {incr z} {
            # Error made in x,y coordinates in EMSegment - I checked everything - it workes in XML and CIM Display in correct order - so do not worry - it is just a little bit strange - but strange things happen
            set EMSegment(Cattrib,$i,CIMMatrix,$x,$y,[lindex $EMSegment(CIMList) $z]) [expr round([$data GetScalarComponentAsFloat $yindex $xindex  $z 0]*100000)/100000.0]        
        }
        incr yindex
        }
        incr xindex
    }
    # Delete instance
    EMCIM Delete
    }
    puts "=========================== End Training ========================"
}

EMSegmentTrainCIMField 

#-------------------------------------------------------------------------------
# 4. Display result 
#-------------------------------------------------------------------------------

set correct(0,West)  "0.941 0.018 0.040 \n0.018 0.937 0.044 \n0.020 0.022 0.957"
set correct(0,North) "0.937 0.021 0.041 \n0.022 0.929 0.049 \n0.020 0.025 0.955"
set correct(0,Up)    "0.000 0.512 0.488 \n0.493 0.000 0.507 \n0.253 0.243 0.504"
set correct(0,East)  "0.941 0.018 0.041 \n0.018 0.937 0.045 \n0.020 0.022 0.958"
set correct(0,South) "0.937 0.022 0.041 \n0.021 0.929 0.049 \n0.021 0.024 0.955"
set correct(0,Down)  "0.000 0.494 0.506 \n0.513 0.000 0.487 \n0.244 0.253 0.503"

set correct(3,West)  "0.981 0.019 0.000 \n0.019 0.981 0.000 \n0.000 0.000 1.000"
set correct(3,North) "0.977 0.023 0.000 \n0.023 0.977 0.000 \n0.000 0.000 1.000"
set correct(3,Up)    "0.000 1.000 0.000 \n1.000 0.000 0.000 \n0.000 0.000 1.000"
set correct(3,East)  "0.981 0.019 0.000 \n0.019 0.981 0.000 \n0.000 0.000 1.000"
set correct(3,South) "0.978 0.022 0.000 \n0.023 0.977 0.000 \n0.000 0.000 1.000"
set correct(3,Down)  "0.000 1.000 0.000 \n1.000 0.000 0.000 \n0.000 0.000 1.000"

set correct(6,West)  ""
set correct(6,North) "" 
set correct(6,Up)    ""
set correct(6,East)  ""
set correct(6,South) "" 
set correct(6,Down)  ""

set correct(0,prob) "0.25 0.249725 0.500275 " 
set correct(3,prob) "0.499725 0.500275 0 "
set correct(6,prob) ""

foreach i $EMSegment(GlobalSuperClassList) {
    set ClassLength [llength $EMSegment(Cattrib,$i,ClassList)]
    set flag 1
    puts ""
    puts "================================ Super Class $i ======================="
    foreach dir $EMSegment(CIMList) {
    set result($dir) ""
    foreach x $EMSegment(Cattrib,$i,ClassList) {
        foreach y $EMSegment(Cattrib,$i,ClassList) {
        set result($dir) "$result($dir)[format %5.3f $EMSegment(Cattrib,$i,CIMMatrix,$x,$y,$dir)] "
        }
        set result($dir) "$result($dir)\n"
    }
        set len [string length $result($dir)]
        set result($dir) [string range $result($dir) 0 [expr $len-3]]
    if {$result($dir) != $correct($i,$dir)} {set flag 0; puts "$dir incorrect"}
    }
    if {$flag} {
    puts "CIM Matric Calculation passed test successfully for Super Class $i"
    } else {
    puts " ========================= ERROR ================="
    puts " Error in CIM Matrix Calculation for SuperClass $i"
    puts " ================================================="
    
    foreach dir $EMSegment(CIMList) {
        puts  "=========== $dir ================"
        puts "The outcome should be :"
        puts $correct($i,$dir)
        puts "The result of the Test is:"
        puts $result($dir)
    }
    }
    set result(prob) ""
    foreach x $EMSegment(Cattrib,$i,ClassList) { set result(prob) "$result(prob)$EMSegment(Cattrib,$x,Prob) "}
    if {$correct($i,prob) == $result(prob)} {
    puts "Class Probability Calculation passed test successfully for Super Class $i"
    } else {
    puts " ===================== ERROR =============="
    puts " Error in Class Probability Calculation"
    puts " =========================== =============="
    puts "The outcome should be : "
    puts $correct($i,prob)
    puts "The result of the Test is:"
    puts $result(prob)
    }
}
#vtkImageViewer viewer
#viewer SetInput [checkers1.0 GetOutput]
#viewer SetZSlice 2
#viewer SetColorWindow $TestMaxValue
#viewer SetColorLevel [expr $TestMaxValue / 2.0]

#viewer Render

wm withdraw .
exit 0








