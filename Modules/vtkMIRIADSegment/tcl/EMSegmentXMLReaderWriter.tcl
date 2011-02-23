#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EMSegmentXMLReaderWriter.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        EMSegmentXMLReaderWriter.tcl
# PROCEDURES:  
#   EMSegmentXMLInit
#   EMSegmentCreateSuperClass SuperClass NumClasses StartIndex
#   DefineParamters VolumeStartNumber tags
#   EMSegmentReadXMLFile XMLFile VolumeStartNumber
#   EMSegmentWriteXMLFileSuperClass SuperClass Ident fid
#   EMSegmentWriteXMLFile XMLFile
#   IncrFileNumber index FilePrefix
#   DeleteVolumes
#==========================================================================auto=
#=auto==========================================================================
# (c) Copyright 2002 Massachusetts Institute of Technology
#
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for any purpose, 
# provided that the above copyright notice and the following three paragraphs 
# appear on all copies of this software.  Use of this software constitutes 
# acceptance of these terms and conditions.
#
# IN NO EVENT SHALL MIT BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE 
# AND ITS DOCUMENTATION, EVEN IF MIT HAS BEEN ADVISED OF THE POSSIBILITY OF 
# SUCH DAMAGE.
#
# MIT SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES INCLUDING, 
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
# A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
#
# THE SOFTWARE IS PROVIDED "AS IS."  MIT HAS NO OBLIGATION TO PROVIDE 
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 
#
#===============================================================================


# This tcl file reads or writes to an XML file
# To execute
# source EMSegmentXMLReaderWriter.tcl
# EMSegmentReadXMLFile <XMLFile> 
# or
# EMSegmentWriteXMLFile <XMLFile> 
# or 
# IncrFileNumber <index> < FilePrefix> := IncrFileNumber increases the file number of the whole written back volume <index> (error in vtk start with 000 instead of 001 ! 
# or 
# DeleteVolumes                        := Deletes the old volumes created by EMSegmentReadXMLFile 
#
# Class will store results in EMSegment and Volume()
# Do not forget to delete the Volumes at the end and to define SLICER_HOME !!!

#-------------------------------------------------------------------------------
# .PROC EMSegmentXMLInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMSegmentXMLInit {} {
    set ::EMSegment(debug) 0
    set ::EMSegment(CIMList) {West North Up East South Down}
    set ::EMSegment(ImgTestNo) -1
    set ::EMSegment(ImgTestDivision) 0
    set ::EMSegment(ImgTestPixel) 0
    set ::Volume(idNone) 0
    set ::EMSegment(GlobalClassList) ""
}

#-------------------------------------------------------------------------------
# .PROC EMSegmentCreateSuperClass
# 
# .ARGS
# string SuperClass 
# int NumClasses 
# int StartIndex
# .END
#-------------------------------------------------------------------------------
proc EMSegmentCreateSuperClass {SuperClass NumClasses StartIndex} {
    global EMSegment Volume
    set max  [expr  $NumClasses + $StartIndex]
    set EMSegment(Cattrib,$SuperClass,IsSuperClass) 1
    set EMSegment(Cattrib,$SuperClass,ClassList) {} 
    lappend EMSegment(GlobalClassList) $SuperClass
    puts "DEBUGGING: creating superclass $SuperClass"
    for {set i $StartIndex} { $i < $max} {incr i} {
        lappend EMSegment(Cattrib,$SuperClass,ClassList) $i
        puts "DEBUGGING: ClassList is $EMSegment(Cattrib,$SuperClass,ClassList)"

        set EMSegment(Cattrib,$i,IsSuperClass) 0
        set EMSegment(Cattrib,$i,ClassList) ""

        set EMSegment(Cattrib,$i,Name) ""
        set EMSegment(Cattrib,$i,ProbabilityData) $Volume(idNone)
        for {set y 0} {$y < $EMSegment(MaxInputChannelDef)} {incr y} {
            set EMSegment(Cattrib,$i,LogMean,$y) 0.0
            for {set x 0} {$x < $EMSegment(MaxInputChannelDef)} {incr x} {
               set EMSegment(Cattrib,$i,LogCovariance,$y,$x)  0.0     
            }
        }
        set EMSegment(Cattrib,$i,Label) 0
        set EMSegment(Cattrib,$i,Prob) 0.0
        set EMSegment(Cattrib,$i,ShapeParameter) 0.0

        foreach Name $EMSegment(CIMList) {
            for {set y $StartIndex} { $y < $max} {incr y} {
                set EMSegment(Cattrib,$SuperClass,CIMMatrix,$i,$y,$Name) 0.0
            }
            set EMSegment(Cattrib,$SuperClass,CIMMatrix,$i,$i,$Name) 1.0
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC DefineParamters
#  Loads all the paramter necessary to start the segmentation process
#  Short Version of MainMrml.tcl - MainMrmlBuildTreesVersion2.0
# .ARGS
# int VolumeStartNumber
# list tags
# .END
#-------------------------------------------------------------------------------
proc EMSegmentBatchDefineParameters {VolumeStartNumber tags} {
    global EMSegment Volume

    set EMSegment(VolNumber) $VolumeStartNumber 
    set NumClassesDef 0
    set EMSegment(SelVolList,VolumeList) ""
    set EMSegment(NumInputChannel) 0
    set EMSegment(GraphNum)        0
    set EMSegment(EMShapeIter)     1
    set EMSegment(GlobalSuperClassList) ""
    set indent ""
    foreach pair $tags {
        set tag  [lindex $pair 0]
        set attr [lreplace $pair 0 0]

        switch $tag {
            
            "Volume" {
                incr EMSegment(VolNumber)
                set num $EMSegment(VolNumber)
                set Volume($num,Name) ""
                set spacing "0.9375 0.9375 1.5" 
                set dimensions "256 256"
                set imageRange "1 124"
                vtkImageReader Volume($num,vol)
                # Default
                Volume($num,vol) ReleaseDataFlagOff
                Volume($num,vol) SetDataScalarTypeToShort
                Volume($num,vol) SetDataByteOrderToBigEndian
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch -- [string tolower $key] {
                        "name"            {set Volume($num,Name) $val}
                        "filepattern"     {set Volume($num,FilePattern) $val; Volume($num,vol) SetFilePattern    $val}
                        "fileprefix"      {set Volume($num,FilePrefix) $val; Volume($num,vol) SetFilePrefix $val}
                        "rastoijkmatrix"  {set Volume($num,rasToIjkMatrix) $val}
                        "rastovtkmatrix"  {set Volume($num,rasToVtkMatrix) $val}
                        "positionmatrix"  {set Volume($num,positionMatrix) $val}
                        "scanorder"       {set Volume($num,scanOrder) $val}
                        "description"     {set Volume($num,description) $val}
                        "colorlut"        {set Volume($num,colorLUT) $val}
                        "imagerange"      {set Volume($num,imageRange) $val; set imageRange $val}
                        "spacing"         {set Volume($num,spacing) $val; set spacing $val}
                        "dimensions"      {set Volume($num,dimensions) $val;set dimensions $val}
                        "scalartype"      {Volume($num,vol) SetDataScalarTypeTo$val; set Volume($num,scalarType) $val}
                        "numscalars"      {Volume($num,vol) SetNumberOfScalarComponents $val; set Volume($num,numScalars) $val}
                        "littleendian" {
                            set Volume($num,littleEndian) $val
                            if {$val == "yes" || $val == "true"} {
                                Volume($num,vol) SetDataByteOrderToLittleEndian
                            } else {
                                Volume($num,vol) SetDataByteOrderToBigEndian
                            }
                        }
                        "window"          {set Volume($num,window) $val;}
                        "level"           {set Volume($num,level) $val;}
                        "lowerthreshold"  {set Volume($num,lowerThreshold) $val;}
                        "upperthreshold"  {set Volume($num,upperThreshold) $val;}
                    }
                }
                eval Volume($num,vol) SetDataSpacing $spacing
                eval Volume($num,vol) SetDataExtent 0 [expr [lindex $dimensions 0]-1] \
                                                    0 [expr [lindex $dimensions 1]-1] $imageRange
                        
                puts "===================== Volume $Volume($num,Name) defined ====================="
                if {$EMSegment(debug)} {puts "[Volume($num,vol) Print]"}    
            }
            
            "Segmenter" {
                set NumClasses 0 
                set EMSegment(MaxInputChannelDef) 0
                set EMSegment(EMiteration) 0 
                set EMSegment(MFAiteration) 0
                set EMSegment(Alpha) 0
                set EMSegment(SmWidth) 0
                set EMSegment(SmSigma) 0
                set EMSegment(PrintIntermediateResults) 0
                set EMSegment(PrintIntermediateSlice) -1 
                set EMSegment(PrintIntermediateFrequency) -1
                set EMSegment(PrintIntermediateDir) "."
                set EMSegment(BiasPrint) 0
                set EMSegment(StartSlice) 0 
                set EMSegment(EndSlice) 0 
                set EMSegment(NumberOfTrainingSamples) 0 
                set EMSegment(IntensityAvgClass) -1
                lappend EMSegment(GlobalSuperClassList) 0
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "numclasses"         {set NumClasses $val}
                        "maxinputchanneldef" {set EMSegment(MaxInputChannelDef) $val}
                        "emshapeiter"        {set EMSegment(EMShapeIter) $val}
                        "emiteration"        {set EMSegment(EMiteration) $val}
                        "mfaiteration"       {set EMSegment(MFAiteration) $val}
                        "alpha"              {set EMSegment(Alpha) $val}
                        "smwidth"            {set EMSegment(SmWidth) $val}
                        "smsigma"            {set EMSegment(SmSigma) $val}
                        "printintermediateresults"   {set EMSegment(PrintIntermediateResults) $val}
                        "printintermediateslice"     {set EMSegment(PrintIntermediateSlice) $val}
                        "printintermediatefrequency" {set EMSegment(PrintIntermediateFrequency) $val}
                        "printintermediatedir"       {set EMSegment(PrintIntermediateDir) $val} 
                        "biasprint"                  {set EMSegment(BiasPrint) $val}  
                        "startslice"                 {set EMSegment(StartSlice) $val}
                        "endslice"                   {set EMSegment(EndSlice) $val}
                        "numberoftrainingsamples"    {set EMSegment(NumberOfTrainingSamples) $val}
                        "displayprob"        {set EMSegment(DisplayProb) $val}
                        "intensityavgclass"  {set EMSegment(IntensityAvgClass) $val}
                    }
                }
                puts "===================== EM Segmenter Parameters  ====================="
                if {$EMSegment(debug)} {puts "[array get EMSegment]"}
                # Define default Class Parameters
                set EMSegment(SuperClass) 0
                set EMSegment(Cattrib,0,Name) "Head"
                set EMSegment(Cattrib,0,Prob) 0.0 
                set EMSegment(Cattrib,0,ProbabilityData) $Volume(idNone)
                
                EMSegmentCreateSuperClass 0 $NumClasses 1
                set StartIndex [expr $NumClasses+1]
                set CurrentClassList $EMSegment(Cattrib,0,ClassList)  
                set indent "  "
            }

            "SegmenterInput" {
                set intensity -1.0
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "name"        {set Name $val}
                        "fileprefix"  {set FilePrefix $val}
                        "filename"    {set FileName $val}
                        "imagerange"  {set imageRange  $val}
                        "intensityavgvaluepredef" {set intensity $val}
                    }
                }
                          
                for {set i [expr $VolumeStartNumber + 1]} {$i <= $EMSegment(VolNumber)} {incr i} {
                    ### NIW -- FilePrefix test doesn't work anymore
                    ### rely only on Filename and ImageRange (not sure
                    ### why latter is interesting, tho)
                    if {$FileName == $Volume($i,Name) && $imageRange == $Volume($i,imageRange)} { 
                        incr EMSegment(NumInputChannel)
                        set EMSegment(IntensityAvgValue,$i) $intensity 
                        lappend EMSegment(SelVolList,VolumeList) $i
                        puts "${indent}===================== EM Segmenter Input Channel $Name  ====================="
                        break
                    }
                }    
                if {$i > $EMSegment(VolNumber)} {puts "${indent}Warning: Channel $Name could not be assigned to any input volume !"}

            }

            "SegmenterSuperClass" {
              set NumClass [lindex $CurrentClassList 0]
              lappend EMSegment(GlobalSuperClassList) $NumClass
              set CurrentClassList [lrange $CurrentClassList 1 end]
              set NumClasses 0
              if {$NumClass == ""} { puts "Error in XML File : Super class $EMSegment(SuperClass)  has not a sub-classes defined" }
              foreach a $attr {
                set key [lindex $a 0]
                set val [lreplace $a 0 0]
                switch [string tolower $key] {
                    "numclasses" {set NumClasses $val}
                    "name"       {set EMSegment(Cattrib,$NumClass,Name) $val}
                    "prob"       {set EMSegment(Cattrib,$NumClass,Prob) $val}
                }
              }
              lappend SclassMemory [list "$EMSegment(SuperClass)" "$CurrentClassList"]
              set EMSegment(SuperClass) $NumClass
              EMSegmentCreateSuperClass $NumClass $NumClasses $StartIndex

              incr StartIndex $NumClasses

              set CurrentClassList $EMSegment(Cattrib,$NumClass,ClassList)
              puts "${indent}===================== EM Segmenter SuperClass $EMSegment(Cattrib,$NumClass,Name) ========================"
              set indent "$indent  " 
              if {$EMSegment(debug)} {puts "[array get EMSegment Cattrib,$EMSegment(SuperClass),*]"}
            }

            "EndSegmenterSuperClass" {
              # Pop the last parent from the Stack
              set temp [lindex $SclassMemory end]
              set SclassMemory [lreplace $SclassMemory end end]
              set CurrentClassList [lindex $temp 1] 
              set EMSegment(SuperClass) [lindex $temp 0]
              set indent [string range $indent 0 [expr [string length $indent] -2]]
              puts "${indent}===================== EM Segmenter EndSuperClass  ========================"

            }

            "SegmenterClass" {
                set NumClassesDef [lindex $CurrentClassList 0]
                set CurrentClassList [lrange $CurrentClassList 1 end]  

                set LocalPriorPrefix ""
                set LocalPriorName   ""
                set LocalPriorRange  ""
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "name"              {set EMSegment(Cattrib,$NumClassesDef,Name) $val}
                        "localpriorprefix"  {set LocalPriorPrefix $val}
                        "localpriorname"    {set LocalPriorName $val}
                        "localpriorrange"   {set LocalPriorRange  $val}
                        "logmean"           {set LogMean $val}
                        "logcovariance"     {set LogCovariance $val}
                        "label"             {set EMSegment(Cattrib,$NumClassesDef,Label) $val}
                        "prob"              {set EMSegment(Cattrib,$NumClassesDef,Prob) $val}
                        "shapeparameter"    {set EMSegment(Cattrib,$NumClassesDef,ShapeParameter) $val}
                    }
                }
                puts "${indent}===================== EM Segmenter Class $EMSegment(Cattrib,$NumClassesDef,Name) ========================"
                set index 0
                for {set y 0} {$y < $EMSegment(MaxInputChannelDef)} {incr y} {
                    set EMSegment(Cattrib,$NumClassesDef,LogMean,$y) [lindex $LogMean $y]
                    for {set x 0} {$x < $EMSegment(MaxInputChannelDef)} {incr x} {
                        set EMSegment(Cattrib,$NumClassesDef,LogCovariance,$y,$x)  [lindex $LogCovariance $index]
                        incr index
                    }
                    incr index
                }
                puts -nonewline "${indent}  Local Prob Map: " 
                set flag 0
                for {set i [expr $VolumeStartNumber + 1]} {$i <= $EMSegment(VolNumber)} {incr i} {
                    if {$LocalPriorName == $Volume($i,Name) && $LocalPriorRange == $Volume($i,imageRange)} { 
                        set EMSegment(Cattrib,$NumClassesDef,ProbabilityData) $i
                        puts "Enabled"
                        set flag 1
                        break
                    } 
                }
                if {$flag == 0 } {puts "Disabled"}
                if {$EMSegment(debug)} {puts "[array get EMSegment Cattrib,$NumClassesDef,*]"}
            }

            "SegmenterGraph" {
                incr EMSegment(GraphNum)
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "name" {set EMSegment(Graph,$EMSegment(GraphNum),name) $val}
                        "xmin" {set EMSegment(Graph,$EMSegment(GraphNum),Xmin) $val}
                        "xmax" {set EMSegment(Graph,$EMSegment(GraphNum),Xmax) $val}
                        "xsca" {set EMSegment(Graph,$EMSegment(GraphNum),Xsca) $val}
                    }
                }
            } 

            "SegmenterCIM" {
                set Name ""
                set CIMMatrix ""
                foreach a $attr {
                    set key [lindex $a 0]
                    set val [lreplace $a 0 0]
                    switch [string tolower $key] {
                        "name"       {set Name $val}
                        "cimmatrix"  {set CIMMatrix $val}
                    }
                }
                if {[lsearch $EMSegment(CIMList) $Name] > -1} { 
                  set i 0
                  foreach y $EMSegment(Cattrib,$EMSegment(SuperClass),ClassList) {
                     foreach x $EMSegment(Cattrib,$EMSegment(SuperClass),ClassList) {
                       set EMSegment(Cattrib,$EMSegment(SuperClass),CIMMatrix,$x,$y,$Name) [lindex $CIMMatrix $i]
                       incr i
                     }
                     incr i
                  }
                  puts "${indent}===================== EM Segmenter CIM $Name for $EMSegment(SuperClass)  ========================"
                  if {$EMSegment(debug)} {puts "[array get EMSegment CIMMatrix,*,*,$Name]"}
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EMSegmentReadXMLFile
# 
# .ARGS
# path XMLFile
# int VolumeStartNumber  default is 0
# .END
#-------------------------------------------------------------------------------
proc EMSegmentReadXMLFile {XMLFile {VolumeStartNumber 0}} {
    global EMSegment

    puts "============================ Start EMSegmentXMLReader ======================="
    puts "Load File $XMLFile"
    # Check File for correctness .We have to do it otherwise warning window will pop up in 
    # Parse.tcl
    if {[catch {set fid [open $XMLFile r]} errmsg] == 1} {
        puts $errmsg
        return
    }
    set mrml [read $fid]
    if {[catch {close $fid} errorMessage]} {
        puts "Aborting due to : ${errorMessage}"
        return
    }

    # accepts all versions from MRML 2.0 to 2.5
    if {[regexp {<!DOCTYPE MRML SYSTEM ['"]mrml2[0-5].dtd['"]>} $mrml match] == 0} {
        puts "The file \"$fileName\" is NOT MRML version 2.x"
        return
    }

    # Strip off everything but the body
    if {[regexp {<MRML>(.*)</MRML>} $mrml match mrml] == 0} {
        puts "There's no content in the file"
        return
    }

    # Load and Define Paramters
    EMSegmentBatchDefineParameters $VolumeStartNumber [MainMrmlReadVersion2.x $XMLFile]
    puts "============================ End EMSegmentXMLReader ======================="
}

#-------------------------------------------------------------------------------
# .PROC EMSegmentWriteXMLFileSuperClass
# 
# .ARGS
# string SuperClass 
# int Ident 
# int fid
# .END
#-------------------------------------------------------------------------------
proc EMSegmentWriteXMLFileSuperClass  {SuperClass Ident fid} { 
  global EMSegment Volume
  foreach ID $EMSegment(Cattrib,$SuperClass,ClassList) {
      if {[llength $EMSegment(Cattrib,$ID,ClassList)]} {
        puts $fid "${Ident}<SegmenterSuperClass name ='$EMSegment(Cattrib,$ID,Name)'  NumClasses ='[llength $EMSegment(Cattrib,$ID,ClassList)]' Prob='$EMSegment(Cattrib,$ID,Prob)'>"
        EMSegmentWriteXMLFileSuperClass $ID "$Ident  " $fid
        puts  $fid "${Ident}</SegmenterSuperClass>"
      } else {
         if {[info exists EMSegment(Cattrib,$ID,Name)]} { set name $EMSegment(Cattrib,$ID,Name)
         } else { set name $EMSegment(Cattrib,$ID,Label)}
         puts -nonewline $fid "${Ident}<SegmenterClass name ='$name' Label='$EMSegment(Cattrib,$ID,Label)' Prob='$EMSegment(Cattrib,$ID,Prob)' ShapeParameter='$EMSegment(Cattrib,$ID,ShapeParameter)' "
         set pid $EMSegment(Cattrib,$ID,ProbabilityData)  
         if {$pid } {
            puts -nonewline $fid "LocalPriorPrefix='$Volume($pid,FilePrefix)' LocalPriorName='$Volume($pid,Name)' LocalPriorRange='$Volume($pid,imageRange)' "
         } 
         puts -nonewline $fid "LogMean='" 
         for {set y 0} {$y < $EMSegment(MaxInputChannelDef)} {incr y} { puts -nonewline $fid "$EMSegment(Cattrib,$ID,LogMean,$y) " }
         puts -nonewline $fid "' LogCovariance='"
         for {set y 0} {$y < $EMSegment(MaxInputChannelDef)} {incr y} {
           if {$y} {puts -nonewline $fid "| " }
           for {set x 0} {$x < $EMSegment(MaxInputChannelDef)} {incr x} {
               puts -nonewline $fid "$EMSegment(Cattrib,$ID,LogCovariance,$y,$x) "
           }
         }
         puts $fid "'></SegmenterClass>"
     } 
 }
 set len [llength $EMSegment(Cattrib,$SuperClass,ClassList)]
 set index [lindex $EMSegment(Cattrib,$SuperClass,ClassList) 0]

 foreach direct $EMSegment(CIMList) {
    puts -nonewline $fid "${Ident}<SegmenterCIM name ='$direct' CIMMatrix='"
    # Kilian - check here so it works with other Writenewxmlfile
    if {[info exists EMSegment(Cattrib,$SuperClass,CIMMatrix,$index,$index,$direct)]} {
       set flag 0
       puts "Using Predefined CIMMatrix"
       foreach y $EMSegment(Cattrib,$SuperClass,ClassList) {
           if {$flag} {puts -nonewline $fid "| " 
           } else {set flag 1}
           foreach x $EMSegment(Cattrib,$SuperClass,ClassList) {
               puts -nonewline $fid "$EMSegment(Cattrib,$SuperClass,CIMMatrix,$x,$y,$direct) "
           }
       }
     } else {
        for {set y 1} { $y<= $len} {incr y} {
           if {$y > 1} {puts -nonewline $fid "| " }
            for {set x 1} { $x<= $len} {incr x} {
                if {$x == $y} {
                    puts -nonewline $fid "1.0 "
                } else { puts -nonewline $fid "0.0 "}
            }
        }
     }
     puts $fid "'></SegmenterCIM>"
  }
  # puts "Kilian Debug CIM"
  # puts $fid "${Ident}<SegmenterCIM name ='Down' CIMMatrix='0.972 0.0 0.052 0.092 0.008 0.0 0.0 | 0.0 0.904 0.024 0.001 0.1 0.007 0.019 | 0.005 0.001 0.711 0.008 0.07 0.005 0.02 | 0.02 0.001 0.007 0.893 0.005 0.0 0.0 | 0.002 0.084 0.205 0.005 0.816 0.01 0.033 | 0.0 0.004 0.001 0.0 0.001 0.978 0.0 | 0.0 0.005 0.0 0.0 0.0 0.0 0.927'></SegmenterCIM>"
  # puts $fid "${Ident}<SegmenterCIM name ='South' CIMMatrix='0.974 0.001 0.056 0.081 0.014 0.0 0.0 | 0.0 0.907 0.003 0.0 0.087 0.064 0.051 | 0.005 0.006 0.735 0.003 0.063 0.002 0.011 | 0.02 0.002 0.021 0.913 0.008 0.0 0.0 | 0.002 0.081 0.178 0.003 0.826 0.006 0.019 | 0.0 0.001 0.004 0.0 0.001 0.928 0.0 | 0.0 0.003 0.003 0.0 0.002 0.0 0.919'></SegmenterCIM>"
  # puts $fid "${Ident}<SegmenterCIM name ='East' CIMMatrix='0.973 0.0 0.06 0.084 0.015 0.0 0.0 | 0.0 0.916 0.005 0.001 0.079 0.068 0.021 | 0.004 0.002 0.764 0.003 0.062 0.004 0.026 | 0.022 0.001 0.013 0.909 0.005 0.0 0.0 | 0.002 0.076 0.152 0.003 0.837 0.004 0.032 | 0.0 0.001 0.005 0.0 0.002 0.925 0.001 | 0.0 0.005 0.0 0.0 0.0 0.0 0.92'></SegmenterCIM>"
  # puts $fid "${Ident}<SegmenterCIM name ='Up' CIMMatrix='0.972 0.0 0.087 0.081 0.017 0.0 0.0 | 0.0 0.892 0.003 0.001 0.086 0.059 0.079 | 0.003 0.009 0.704 0.002 0.083 0.004 0.0 | 0.024 0.002 0.032 0.914 0.01 0.0 0.0 | 0.001 0.095 0.169 0.003 0.802 0.008 0.006 | 0.0 0.0 0.001 0.0 0.001 0.928 0.0 | 0.0 0.001 0.003 0.0 0.002 0.001 0.915'></SegmenterCIM>"
  # puts $fid "${Ident}<SegmenterCIM name ='North' CIMMatrix='0.974 0.0 0.084 0.077 0.011 0.0 0.0 | 0.0 0.907 0.014 0.001 0.084 0.023 0.038 | 0.003 0.001 0.735 0.005 0.073 0.027 0.018 | 0.021 0.001 0.011 0.913 0.005 0.0 0.0 | 0.002 0.084 0.153 0.005 0.826 0.022 0.025 | 0.0 0.004 0.0 0.0 0.0 0.928 0.0 | 0.0 0.003 0.002 0.0 0.001 0.0 0.919'></SegmenterCIM>"
  # puts $fid "${Ident}<SegmenterCIM name ='West' CIMMatrix='0.973 0.0 0.061 0.085 0.014 0.0 0.0 | 0.0 0.916 0.006 0.001 0.078 0.013 0.073 | 0.004 0.002 0.764 0.003 0.062 0.033 0.002 | 0.022 0.001 0.012 0.909 0.006 0.0 0.0 | 0.002 0.076 0.152 0.003 0.837 0.028 0.005 | 0.0 0.004 0.001 0.0 0.0 0.925 0.0 | 0.0 0.001 0.004 0.0 0.002 0.001 0.92'></SegmenterCIM>" 
}

#-------------------------------------------------------------------------------
# .PROC EMSegmentWriteXMLFile
# 
# .ARGS
# string XMLFile
# .END
#-------------------------------------------------------------------------------
proc EMSegmentWriteXMLFile {XMLFile} { 
    global EMSegment Volume
    puts "============================ Start EMSegmentXMLWriter ======================="
    puts "Warning: This might not work a hundred percent: e.g right now only for Data Type Short"

    if {[catch {set fid [open $XMLFile w]} errmsg] == 1} {
    puts $errmsg
    puts "============================ End EMSegmentXMLWriter ======================="
    exit 1 
    }
    puts "Writing file $XMLFile"
    puts $fid "<?xml version=\"1.0\" standalone='no'?>"
    puts $fid "<!DOCTYPE MRML SYSTEM \"mrml20.dtd\">"
    puts $fid "<MRML>"
    for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
    puts -nonewline $fid "<Volume " 
    puts -nonewline $fid "name='$Volume($i,Name)' " 
    puts -nonewline $fid "filepattern='$Volume($i,FilePattern)' "
    puts -nonewline $fid "filePrefix='$Volume($i,FilePrefix)' "
    puts -nonewline $fid "rasToIjkMatrix='$Volume($i,rasToIjkMatrix)' "
    puts -nonewline $fid "rasToVtkMatrix='$Volume($i,rasToVtkMatrix)' "
    puts -nonewline $fid "positionMatrix='$Volume($i,positionMatrix)' "
    if {[info exists Volume($i,scanOrder)]} {
        puts -nonewline $fid "scanOrder='$Volume($i,scanOrder)' "
    }
    puts -nonewline $fid "description='$Volume($i,description)' "
    puts -nonewline $fid "colorLUT='$Volume($i,colorLUT)' "
    if {[info exists Volume($i,littleEndian)]} {
        puts -nonewline $fid "littleEndian='$Volume($i,littleEndian)' "
    }
    puts -nonewline $fid "window='$Volume($i,window)' "
    puts -nonewline $fid "level='$Volume($i,level)' "
    puts -nonewline $fid "lowerThreshold='$Volume($i,lowerThreshold)' "
    puts -nonewline $fid "upperThreshold='$Volume($i,upperThreshold)' "
    if {[info exists Volume($i,imageRange)]} {
        puts -nonewline $fid "imageRange='$Volume($i,imageRange)' "
    }
    if {[info exists Volume($i,dimensions)]} {
        puts -nonewline $fid "dimensions='$Volume($i,dimensions)' "
    }
    if {[info exists Volume($i,spacing)]} {
        puts -nonewline $fid "spacing='$Volume($i,spacing)' "
    }
    puts $fid "></Volume>"
    }
    puts -nonewline $fid "<Segmenter NumClasses ='[llength $EMSegment(Cattrib,0,ClassList)]' MaxInputChannelDef ='$EMSegment(MaxInputChannelDef)' EMShapeIter='$EMSegment(EMShapeIter)' EMiteration ='$EMSegment(EMiteration)' MFAiteration ='$EMSegment(MFAiteration)' Alpha ='$EMSegment(Alpha)' SmWidth ='$EMSegment(SmWidth)' SmSigma ='$EMSegment(SmSigma)' PrintIntermediateResults ='$EMSegment(PrintIntermediateResults)' PrintIntermediateSlice ='$EMSegment(PrintIntermediateSlice)' PrintIntermediateFrequency ='$EMSegment(PrintIntermediateFrequency)' StartSlice ='$EMSegment(StartSlice)' EndSlice ='$EMSegment(EndSlice)' DisplayProb  ='$EMSegment(DisplayProb)' NumberOfTrainingSamples ='$EMSegment(NumberOfTrainingSamples)' IntensityAvgClass ='$EMSegment(IntensityAvgClass)' BiasPrint = '$EMSegment(BiasPrint)'"
    if {$EMSegment(PrintIntermediateDir)!= "."} {
        puts $fid " PrintIntermediateDir = '$EMSegment(PrintIntermediateDir)' >"
    } else {
        puts $fid ">" 
    }

    for {set i 1} {$i <= $EMSegment(GraphNum)} {incr i} {    
      puts $fid "  <SegmenterGraph name ='$EMSegment(Graph,$i,name)' Xmin ='$EMSegment(Graph,$i,Xmin)' Xmax ='$EMSegment(Graph,$i,Xmax)' Xsca ='$EMSegment(Graph,$i,Xsca)'></SegmenterGraph>"
    }
    set i 0
    foreach chan $EMSegment(SelVolList,VolumeList) {
       puts $fid "  <SegmenterInput name ='Channel$i' FilePrefix='$Volume($chan,FilePrefix)' FileName='$Volume($chan,Name)' ImageRange='$Volume($chan,imageRange)' IntensityAvgValuePreDef ='$EMSegment(IntensityAvgValue,$chan)'></SegmenterInput>"
       incr i
    }
    EMSegmentWriteXMLFileSuperClass 0 "   "  $fid
    puts $fid "</Segmenter>"
    puts $fid "</MRML>"
    close $fid 
    puts "============================ End EMSegmentXMLReaderWriter ======================="
}

#-------------------------------------------------------------------------------
# .PROC IncrFileNumber
# Increases the file number of the whole written back volume <index> (error in vtk start with 000 instead of 001 ! 
# .ARGS
# int index
# string FilePrefix
# .END
#-------------------------------------------------------------------------------
proc IncrFileNumber {index FilePrefix} { 
    global Volume
    set Max [lindex $Volume($index,imageRange) 1] 
    set Min [lindex $Volume($index,imageRange) 0] 
    for {set i $Max} {$i >= $Min} {incr i -1} {
        set targetFile $FilePrefix.[format %03d $i]
        if {[file exists $targetFile]} {file delete $targetFile}    
        file rename $FilePrefix.[format %03d [expr $i-$Min]] $targetFile
    }    
}

#-------------------------------------------------------------------------------
# .PROC DeleteVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DeleteVolumes {} {
    global EMSegment Volume
    for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
        Volume($i,vol) Delete
    } 
}


