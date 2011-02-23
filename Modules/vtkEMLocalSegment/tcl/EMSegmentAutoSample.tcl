#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EMSegmentAutoSample.tcl,v $
#   Date:      $Date: 2006/05/11 22:03:54 $
#   Version:   $Revision: 1.8 $
# 
#===============================================================================
# FILE:        EMSegmentAutoSample.tcl
# PROCEDURES:  
#   EMSegmentCutOutRegion ThreshInstance MathInstance ResultVolume ProbVolume CutOffProb volDataType flag
#   EMSegmentGaussCurveCalculation CutOffProbability LogGaussFlag MRIVolumeList ProbVolume VolDataType
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EMSegmentCutOutRegion
# .ARGS
# vtk ThreshInstance
# vtk MathInstance 
# vtk ResultVolume 
# vtk ProbVolume
# float CutOffProb
# string volDataType 
# int flag
# .END
#-------------------------------------------------------------------------------
proc EMSegmentCutOutRegion {ThreshInstance MathInstance ResultVolume ProbVolume CutOffProb volDataType flag} {
   # 1. Define cut out area 
    $ThreshInstance SetInput [$ProbVolume GetOutput] 
    if {$flag} {$ThreshInstance ThresholdByUpper $CutOffProb
    } else {$ThreshInstance ThresholdBetween $CutOffProb $CutOffProb}
    $ThreshInstance SetInValue 1.0
    $ThreshInstance SetOutValue 0.0
    $ThreshInstance SetOutputScalarTypeTo$volDataType 
    $ThreshInstance Update
    # 2. Cut out region from normal image
    $MathInstance SetOperationToMultiply
    $MathInstance SetInput 1 [$ResultVolume GetOutput]
    $MathInstance SetInput 0 [$ThreshInstance GetOutput]
    $MathInstance Update
}

#-------------------------------------------------------------------------------
# .PROC EMSegmentGaussCurveCalculation
# Extracts the Gauss curve from the given histogram. The histogram is defined by the probability map (ROI) and Grey value image 
# [llength $MRIVolumeList] = 1 => results in a 1D Histogram;  [llength $MRIVolumeList] = 2 => results in a 2D Histogram  
# result will be returned in EMSegment(GaussCurveCalc,Mean,x), EMSegment(GaussCurveCalc,Covariance,y,x),  
# EMSegment(GaussCurveCalc,Sum), EMSegment(GaussCurveCalc,LogGaussFlag), EMSegment(GaussCurveCalc,CutOffAbsolut), 
# EMSegment(GaussCurveCalc,CutOffPercent), EMSegment(GaussCurveCalc,MaxProb),  EMSegment(GaussCurveCalc,GreyMin,x), 
# and EMSegment(GaussCurveCalc,GreyMax,x)
# .ARGS
# float CutOffProbability 
# int LogGaussFlag
# list MRIVolumeList
# vtk ProbVolume
# string VolDataType is the type of the volumes in MRIVolumeList
# .END
#-------------------------------------------------------------------------------
proc EMSegmentGaussCurveCalculation {CutOffProbability LogGaussFlag MRIVolumeList ProbVolume VolDataType} {
    global EMSegment
     # Initialize values 
    set NumInputChannel [llength $MRIVolumeList] 
    for {set y 1} {$y <= $NumInputChannel} {incr y} {
    if {$LogGaussFlag} {set EMSegment(GaussCurveCalc,Mean,$y) 0.0 
        } else {set EMSegment(GaussCurveCalc,Mean,$y) 0}
        set EMSegment(GaussCurveCalc,GreyMin,$y) -1
        set EMSegment(GaussCurveCalc,GreyMax,$y) -1
    for {set x 1} {$x <= $NumInputChannel} {incr x} {
          set EMSegment(GaussCurveCalc,Covariance,$y,$x) 0.0
    }
    }
    set EMSegment(GaussCurveCalc,Sum)  0
    set EMSegment(GaussCurveCalc,LogGaussFlag) $LogGaussFlag
    set EMSegment(GaussCurveCalc,CutOffAbsolut) 0 
    set EMSegment(GaussCurveCalc,CutOffPercent) 0.0
    set EMSegment(GaussCurveCalc,MaxProb) 0


    if { [info command MathImg] != ""} {
        MathImg Delete
    }
    vtkImageAccumulate MathImg
    MathImg SetInput [$ProbVolume GetOutput]
    MathImg Update
    set Min [lindex [MathImg GetMin] 0]
    set EMSegment(GaussCurveCalc,MaxProb) [lindex [MathImg GetMax] 0] 
    if {$Min == 0} {incr Min}
    if {($Min <0) && $EMSegment(GaussCurveCalc,LogGaussFlag)} {
       puts "Probability Volume $ProbVolume has negative values (ValueRange $Min $EMSegment(GaussCurveCalc,MaxProb)), which is not possible for log gaussian ! Probably little endian set incorrectly"
       MathImg Delete
       exit 1
    }
    set index  [expr $EMSegment(GaussCurveCalc,MaxProb) - $Min]
    MathImg SetComponentExtent 0 $index 0 0 0 0
    MathImg SetComponentOrigin $Min 0.0 0.0 
    MathImg Update 
    
    set data   [MathImg GetOutput]
    set ROIVoxel 0   
    for {set i 0} {$i <= $index} {incr i} { incr ROIVoxel [expr int([$data GetScalarComponentAsFloat $i 0 0 0])] }
    if  {$ROIVoxel == 0} {
        MathImg   Delete
        return
    }
    set CutOffVoxel [expr $ROIVoxel*(1.0 - $CutOffProbability)]
    # Add instructions so if border is to high you can set a flag so that the the highest probability will be stilll sampled  
    for {set i  $index} {$i > -1} {incr i -1} {
        incr EMSegment(GaussCurveCalc,Sum) [expr int ([$data GetScalarComponentAsFloat $i 0 0 0])]
        # puts "$i [expr int ([$data $::getScalarComponentAs $i 0 0 0])]"
        if {$EMSegment(GaussCurveCalc,Sum) > $CutOffVoxel} { 
          if {$i == $index } {
            puts "Warning: CutOffProbabiliyt ($CutOffProbability) is set to low ! No samples could be taken => We redefine to [expr 100 - int(double($EMSegment(GaussCurveCalc,Sum))/double($ROIVoxel)*1000)/10.0] % !"
            set CutOffVoxel $EMSegment(GaussCurveCalc,Sum)
          } else {
            set EMSegment(GaussCurveCalc,CutOffAbsolut) [expr $i+$Min +1] 
            set EMSegment(GaussCurveCalc,Sum) [expr $EMSegment(GaussCurveCalc,Sum) - int([$data GetScalarComponentAsFloat $i 0 0 0])]
            break
          }
        }
    }
    # If it went through all of it you have to set it to $min !
    if  {$EMSegment(GaussCurveCalc,CutOffAbsolut) == 0 } {set EMSegment(GaussCurveCalc,CutOffAbsolut) $Min}
        set EMSegment(GaussCurveCalc,CutOffPercent) [expr 100 - int(double($EMSegment(GaussCurveCalc,Sum))/double($ROIVoxel)*1000)/10.0]
    if {$EMSegment(GaussCurveCalc,Sum) == 0} { 
      MathImg   Delete
    return
    }
    if { [info command gaussCurveCalcThreshold] != ""} {
        gaussCurveCalcThreshold Delete
    }
    vtkImageThreshold gaussCurveCalcThreshold
    if { [info command MathMulti] != ""} {
        MathMulti Delete
    }
    vtkImageMathematics MathMulti
    # Calculate the mean for each image
    for {set i 1} {$i <= $NumInputChannel} {incr i} {
      EMSegmentCutOutRegion gaussCurveCalcThreshold MathMulti [lindex $MRIVolumeList [expr $i-1]] $ProbVolume $EMSegment(GaussCurveCalc,CutOffAbsolut) $VolDataType 1
    
      # puts "Multiplying"
      # Now value To it so we can differnetiate between real 0 and not
        if { [info command MathAdd($i)] != ""} {
            MathAdd($i) Delete
        }
      vtkImageMathematics MathAdd($i)
      MathAdd($i) SetOperationToAdd
      MathAdd($i) SetInput 1 [MathMulti GetOutput]
      MathAdd($i) SetInput 0 [gaussCurveCalcThreshold GetOutput]
      MathAdd($i) Update
      # if {$i ==-1} {
      #    set data [MathAdd($i) GetOutput]
      #    for {set x 0} {$x < 256} {incr x} {
      #    for {set y 0} {$y < 256} {incr y} {
      #        if {([$data $::getScalarComponentAs $x $y 0 0] > 103) && ([$data $::getScalarComponentAs $x $y 0 0] < 107)} {
      #        puts "Jey Hey $x $y [$data $::getScalarComponentAs $x $y 0 0]"
      #        }
      #    }
      #    }
      # }
      # 3. Generate Histogram in 1D
      MathImg SetInput [MathAdd($i) GetOutput]   
      MathImg Update            
      set min($i)    [lindex [MathImg GetMin] 0]
      set max($i)    [lindex [MathImg GetMax] 0] 
      if {$min($i) == 0} {incr min($i)
        } else { 
        if { $min($i) < 0} {
             # Please note: only the input volume is corrupt, because the probility volume was checked before !
             # (MathMulti is the cut out form from the input volume i) 
             puts "Error: INPUT VOLUME $i has values below 0! Probably the LittleEndian is set wrong!" 
             set ErrorVolume  [lindex $MRIVolumeList [expr $i-1]]
             puts "       Run ./mathImage -fc his -pr [$ErrorVolume GetFilePrefix] -le [expr [$ErrorVolume GetDataByteOrder] ? yes : no]"
             exit 1
        } 
    } 
    set Index($i)  [expr $max($i) - $min($i)]
    
    MathImg SetComponentExtent 0 $Index($i) 0 0 0 0
    MathImg SetComponentOrigin $min($i) 0.0 0.0 
    MathImg Update
    # Calculate the mean for every image 
    set data   [MathImg GetOutput]
    set MinBorder($i) $max($i)
    set MaxBorder($i) $min($i)
    set Xindex  $Index($i)
    # If you get an error message here 
    for {set x $max($i)} {$x >= $min($i)} {incr x -1} {
        set temp [$data GetScalarComponentAsFloat $Xindex 0 0 0]
        # if {($x > 103) && ($x < 107)} {
        #        puts "Du $x [$data $::getScalarComponentAs $Xindex 0 0 0]"
        #        }
        incr Xindex -1
        if {$temp} {
        set MinBorder($i) $x
        if {$x > $MaxBorder($i)} {set MaxBorder($i) $x }
        if {$EMSegment(GaussCurveCalc,LogGaussFlag)} {
            set EMSegment(GaussCurveCalc,Mean,$i) [expr $EMSegment(GaussCurveCalc,Mean,$i) + log($x) * double($temp)]
        } else {
            # puts "$EMSegment(GaussCurveCalc,Mean,$i) expr ($x+1) * int($temp)"
            incr EMSegment(GaussCurveCalc,Mean,$i) [expr ($x+1) * int($temp)]}
        }
    }
    set EMSegment(GaussCurveCalc,Mean,$i) [expr double($EMSegment(GaussCurveCalc,Mean,$i))/ double($EMSegment(GaussCurveCalc,Sum))]
    # Calculate Variance for the two images
    set Xindex [expr $MinBorder($i) - $min($i)]
        set EMSegment(GaussCurveCalc,GreyMin,$i) $MinBorder($i)
        set EMSegment(GaussCurveCalc,GreyMax,$i) $MaxBorder($i)

    for {set x $MinBorder($i)} {$x <= $MaxBorder($i)} {incr x} {
        if {$EMSegment(GaussCurveCalc,LogGaussFlag)} { set  temp [expr log($x) - $EMSegment(GaussCurveCalc,Mean,$i)]
        } else {set  temp [expr $x - 1 - $EMSegment(GaussCurveCalc,Mean,$i)]}
        set EMSegment(GaussCurveCalc,Covariance,$i,$i) [expr $EMSegment(GaussCurveCalc,Covariance,$i,$i) + $temp*$temp * [$data GetScalarComponentAsFloat $Xindex 0 0 0]]
        incr Xindex
    }
    set min($i) $MinBorder($i)
    if {$MinBorder($i) <  $MaxBorder($i)} {
        set max($i)  $MaxBorder($i)
        set Index($i)  [expr $max($i) - $min($i)]
    }
    }
    if {($EMSegment(GaussCurveCalc,Sum) > 1) && ($NumInputChannel > 1)} {
    vtkImageAppendComponents imageAppend
    imageAppend AddInput [MathAdd(1) GetOutput]
    imageAppend AddInput [MathAdd(2) GetOutput]
    imageAppend Update
    MathImg SetInput [imageAppend GetOutput]
    MathImg SetComponentExtent 0 $Index(1) 0 $Index(2) 0 0
    MathImg SetComponentOrigin $min(1) $min(2) 0.0 
    MathImg Update
    set data   [MathImg GetOutput]
    
    # You can cut of images to make them the same length
    # vtkImageClip clip
    # clip SetInput [imageAppend GetOutput]
    # clip SetOutputWholeExtent 0 255 0 255 20 22
    # Now figure out the variance 
    # 4. Calculate Covariance 
    
    # Covariance = (Sum(Sample(x,i) - mean(x))*(Sample(y,i) - mean(y)))/(n-1)

    set Yindex [expr $MinBorder(1) - $min(1)]
    for {set y $min(1)} {$y <= $max(1)} {incr y} {
        if {$EMSegment(GaussCurveCalc,LogGaussFlag)} { set Ytemp [expr log($y) - $EMSegment(GaussCurveCalc,Mean,1)]
        } else {set Ytemp [expr $y - 1 - $EMSegment(GaussCurveCalc,Mean,1)]}
        set Xindex [expr $min(2) - $min(2)]
        for {set x $min(2)} {$x <= $max(2)} {incr x} {
        if {$EMSegment(GaussCurveCalc,LogGaussFlag)} { set  Xtemp [expr log($x) - $EMSegment(GaussCurveCalc,Mean,2)]
            } else {set  Xtemp [expr $x - 1 - $EMSegment(GaussCurveCalc,Mean,2)]}
        set EMSegment(GaussCurveCalc,Covariance,1,2) [expr $EMSegment(GaussCurveCalc,Covariance,1,2) + $Xtemp*$Ytemp * [$data GetScalarComponentAsFloat $Yindex $Xindex 0 0]]
        # if {[$data $::getScalarComponentAs $Yindex $Xindex 0 0]} {
            # puts " $Yindex $Xindex [$data $::getScalarComponentAs $Yindex $Xindex 0 0]"
            # }
            incr Xindex
        }
        incr Yindex
        }
        set EMSegment(GaussCurveCalc,Covariance,2,1) $EMSegment(GaussCurveCalc,Covariance,1,2)
        for {set y 1} {$y < 3} {incr y} {
        for {set x 1} {$x < 3} {incr x} {
            set EMSegment(GaussCurveCalc,Covariance,$y,$x) [expr $EMSegment(GaussCurveCalc,Covariance,$y,$x) / double($EMSegment(GaussCurveCalc,Sum) - 1)]
        }
        }
    } else { 
        if {$NumInputChannel > 1} {
                 set EMSegment(GaussCurveCalc,Covariance,1,2) 1.0
         set EMSegment(GaussCurveCalc,Covariance,2,1) $EMSegment(GaussCurveCalc,Covariance,1,2)
        } else {
        if { $EMSegment(GaussCurveCalc,Sum) > 1 } { set EMSegment(GaussCurveCalc,Covariance,1,1)  [expr $EMSegment(GaussCurveCalc,Covariance,1,1)/ double($EMSegment(GaussCurveCalc,Sum) - 1)] } 
        }
    }
    # Clean Up
    if {$NumInputChannel > 1} {
        imageAppend Delete
        MathAdd(2) Delete
    }
    MathAdd(1) Delete
    gaussCurveCalcThreshold Delete
    MathMulti Delete
    MathImg Delete
}
