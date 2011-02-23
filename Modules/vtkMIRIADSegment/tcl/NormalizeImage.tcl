#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: NormalizeImage.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        NormalizeImage.tcl
# PROCEDURES:  
#   NormImage1
#   NormImage MaxValue NormList resultsDir
#   NormImage2
#==========================================================================auto=

# -----------------------------------------------------------------------------
# This script normalizes the images so that the maximum in the image is the given value 
# MaxValue = 0 => it will automatically only normalize the Propabilbity Maps to value EMSegment(NumberOfTrainingSamples) 
# setenv SLICER_HOME /home/ai2/kpohl/slicer_devel/slicer
# setenv LD_LIBRARY_PATH /home/ai2/kpohl/slicer_devel/pkg/lib:${LD_LIBRARY_PATH}
# /home/ai2/kpohl/slicer_devel/pkg/bin/vtk $SLICER_HOME/program/tcl-modules/EMSegment/NormalizeImage.tcl <Mrml File Defining Segmentation> <MaxValue>
# ------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC NormImage1
# 1. Step Initialize and check Parameters 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NormImage1 {} {
    if {[info exists env(SCRIPT_HOME)] != 0} {
        set Script_Home $env(SCRIPT_HOME)
    } else {
        if {[info exists env(SLICER_HOME)] == 0 || $env(SLICER_HOME) == ""} {
        set Script_Home ""
        } else { 
        set Script_Home $env(SLICER_HOME)
        }
    }

    source [file join $Script_Home tcl/EMSegmentXMLReaderWriter.tcl] 

    # If $argc == 3 => it is sourced from another program 
    if {$argc < 2} {
        puts "Input for NormailzeImage has to be :"
        puts "NormalizeImage <Mrml File Defining Segmentation> <MaxValue>"
        puts "<MaxValue> : 0 = it will automatically only normalize the Propabilbity Maps to value EMSegment(NumberOfTrainingSamples)  "
        exit 1
    }
}

#-------------------------------------------------------------------------------
# .PROC NormImage
# 
# .ARGS
# float MaxValue
# list NormList
# path resultsDir
# .END
#-------------------------------------------------------------------------------
proc NormImage {MaxValue NormList resultsDir} { 
  global Volume tcl_precision
  vtkImageAccumulate Accu
  foreach index $NormList {
    Accu SetInput [Volume($index,vol) GetOutput]
    Accu Update
    set MaxImage [lindex [Accu GetMax] 0]
    set VolumeFilePrefix [Volume($index,vol) GetFilePrefix]
    if {$MaxImage !=  $MaxValue} {
    puts "Normalize $Volume($index,Name): max Volume Value = $MaxImage, max Predefined Value = $MaxValue"  
    # Only do something if the max values are different - larger or smaller
    # I got this from ~/slicer_devel/vtk4.0/VTK/Imaging/Testing/Tcl/TestAllMathematics.tcl
       
    # 1. Normailze Image
    vtkImageMathematics NormImg
    NormImg SetInput1 [Volume($index,vol) GetOutput]
    NormImg SetOperationToMultiplyByK
    set value [expr $MaxValue / double($MaxImage)]
    # 1. find out last digit
    set i 0
    while {[expr (double(int($value / pow(10.0,$i)))) > 0] } {
        incr i
    }
    # 2. Add to value - have to do it otherwise rounding error produce value MaxValue -1
    set i [expr -1*($tcl_precision - $i)]
    while {[expr $value*$MaxImage] <=  $MaxValue} {
        set value [expr $value + pow(10.0,$i)]
    }
    NormImg SetConstantK [expr $value]
    
    vtkImageWriter WriteResult 
    WriteResult SetInput [NormImg GetOutput] 
    NormImg Update  
    
    # 2. Write File back to disk
        set FileDir [ file join $resultsDir $Volume($index,Name) ]
    puts "Result will be written to $FileDir"
        file mkdir ${FileDir}
    # set FilePrefix [file join $FileDir [file tail $Volume($index,FilePrefix)]]
    # WriteResult  SetFilePrefix [Volume($index,vol) GetFilePrefix]  $Volume($index,FilePrefix)
    WriteResult  SetFilePrefix ${FileDir}/$Volume($index,Name)
    WriteResult  SetFilePattern %s.%03d 
    puts "Writing ${FileDir}..."
    WriteResult  Write
    puts " ...done."
    
    IncrFileNumber $index ${FileDir}/$Volume($index,Name)
    
    # 3. Delete old instances 
    WriteResult Delete
    NormImg Delete
    } else {
    puts "Volume $Volume($index,Name) is OK"
    }
  }
  Accu Delete
}

#-------------------------------------------------------------------------------
# .PROC NormImage2
# 2. Start program if it is called from a different function
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc NormImage2 {} {
    if {$argc == 2} {
        puts "============================ Start NormalizeImage ======================="
        set XMLFile  [lindex $argv 0] 
        set MaxValue [lindex $argv 1]
        EMSegmentReadXMLFile $XMLFile
        set NormList ""
        if {$MaxValue} {
            for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
                lappend NormList $i
            } 
        } else {
            if {$EMSegment(NumberOfTrainingSamples) == 0} {
                puts "NormailzeImage:Error:"
                puts "Cannot normailze image because MaxValue == 0 and EMSegment(NumberOfTrainingSamples) == 0 "
                exit 1
            }
            set MaxValue $EMSegment(NumberOfTrainingSamples)
            for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
                if {[lsearch $EMSegment(SelVolList,VolumeList) $i] == -1} {
                    lappend NormList $i
                }
            } 
        }
        
        # Now rounding errors for later when doing maximum 
        # set tcl_precision 17
        #-------------------------------------------------------------------------------
        # 3. Normilze images if necessary 
        #-------------------------------------------------------------------------------
        NormImage $MaxValue "$NormList"
        #-------------------------------------------------------------------------------
        # 4. Delete all Volumes 
        #-------------------------------------------------------------------------------
        DeleteVolumes 
        puts "============================ End NormalizeImage ======================="
    }
}
