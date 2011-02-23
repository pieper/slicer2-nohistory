package require vtk
package require vtkSlicerBase

# This script allows the direct access of the vtkImageEMMarkov Filter. It is very useful for batch processing.
# Function can be called through
# setenv SLICER_HOME /home/ai2/kpohl/slicer_devel/slicer2
# setenv LD_LIBRARY_PATH ${SLICER_HOME}/Base/builds/debian_gcc/bin:${LD_LIBRARY_PATH}
# setenv TCLLIBPATH "${SLICER_HOME}/Base/Wrapping/Tcl ${SLICER_HOME}/Base/builds/debian-gcc/bin"
# /home/ai2/kpohl/slicer_devel/vtk4.0/VTK-build/bin/vtk TestImageEMMarkov.tcl

# Test the filter vtkImageEMMarkov
#-------------------------------------------------------------------------------
# 1. Step Initialize 
#-------------------------------------------------------------------------------
set EMSegment(SegmentMode) 0
set EMSegment(XMLDir)        TestImageEMSegmentData.xml
wm withdraw .

set EMSegment(debug) 0
set EMSegment(CIMList) {West North Up East South Down}

#-------------------------------------------------------------------------------
# 2. Step Define Programs 
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# .PROC EMSegmentTrainCIMField
# Traines the CIM Field with a given Image
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMSegmentTrainCIMField {} {
    global EMSegment Volume

    # Transferring Information
    vtkImageEMMarkov EMCIM    
    # EM Specific Information
    EMCIM SetNumClasses     $EMSegment(NumClasses)  
    EMCIM SetStartSlice     $EMSegment(StartSlice)
    EMCIM SetEndSlice       $EMSegment(EndSlice)

    set EMSegment(ImgTestNo) 0
    EMCIM SetImgTestNo       $EMSegment(ImgTestNo) 
    EMCIM SetImgTestDivision 1 
    EMCIM SetImgTestPixel    1 


    for {set i 0} { $i< $EMSegment(NumClasses)} {incr i} {
        EMCIM SetLabelNumber $i 1 
        if {$EMSegment(ImgTestNo) < 1} { 
            EMCIM SetLabel           $i $EMSegment(Cattrib,[expr $i+1],Label) 
        } else {     
            EMCIM SetLabel           $i [expr ($i*255)/($EMSegment(NumClasses)-1)]
        }
    }  

    # Transfer image information
    EMCIM SetInput [Volume(2,vol) GetOutput]

    set data [EMCIM GetOutput]
    # This Command calls the Thread Execute function
    $data Update

    for {set x 1} {$x <= $EMSegment(NumClasses) } {incr x} {
        set EMSegment(Cattrib,$x,Prob) [EMCIM GetProbability [expr $x-1]]
        # EMCIM traines the matrix (y=t, x=t-1) just the other way EMSegment (y=t-1, x=t) needs it - Sorry !
        for {set y 1} {$y <=  $EMSegment(NumClasses) } {incr y} {
            for {set z 0} {$z < 6} {incr z} {
              # Different order than in EMSegment bc I can ignore error that has been made in EMSegment.tcl
              set EMSegment(CIMMatrix,$x,$y,[lindex $EMSegment(CIMList) $z])  [expr round([$data GetScalarComponentAsFloat [expr $x-1] [expr $y-1] $z 0]*10000)/10000.0]        
            }
        }
    }
    # Delete instance
    EMCIM Delete 
}

#-------------------------------------------------------------------------------
# .PROC LoadFile 
#  Loads all the paramter necessary to start the segmentation process
#  Put together from parse.tcl - MainMrmlReadVersion2.x {fileName} 
#  and MainMrml.tcl - MainMrmlBuildTreesVersion2.0
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LoadFile {fileName} {
    global EMSegment Volume
    # Returns list of tags on success else 0

    # Read file
    if {[catch {set fid [open $fileName r]} errmsg] == 1} {
        puts $errmsg
        return -1 
    }
    set mrml [read $fid]
    if {[catch {close $fid} errorMessage]} {
    puts "Aborting due to : ${errorMessage}"
    exit 1
    }

    # accepts all versions from MRML 2.0 to 2.5
    if {[regexp {<!DOCTYPE MRML SYSTEM ['"]mrml2[0-5].dtd['"]>} $mrml match] == 0} {
        puts "The file \"$fileName\" is NOT MRML version 2.x"
        return -1
    }

    # Strip off everything but the body
    if {[regexp {<MRML>(.*)</MRML>} $mrml match mrml] == 0} {
        puts "There's no content in the file"
        return -1
    }

    # Strip leading white space
    regsub "^\[\n\t \]*" $mrml "" mrml

    set tags1 ""
    while {$mrml != ""} {

        # Find next tag
        if {[regexp {^<([^ >]*)([^>]*)>([^<]*)} $mrml match tag attr stuffing] == 0} {
        #([^/>]*)
                set errmsg "Invalid MRML file. Can't parse tags:\n$mrml"
            puts "$errmsg"
            tk_messageBox -message "$errmsg"
            return 0
        }

        # Strip off this tag, so we can continue.
        if {[lsearch "Transform /Transform" $tag] != -1 || \
            [lsearch "Fiducials /Fiducials" $tag] != -1 || \
            [lsearch "Hierarchy /Hierarchy" $tag] != -1 || \
            [lsearch "ModelGroup /ModelGroup" $tag] != -1 || \
            [lsearch "Scenes /Scenes" $tag] != -1 || \
            [lsearch "VolumeState /VolumeState" $tag] != -1 || \
            [lsearch "Path /Path" $tag] != -1 || \
            [lsearch "Segmenter /Segmenter" $tag] != -1 } {
            # set str "<$tag>" doesn't work with tags which have attributes
            set str ">"
        } else {
            set str "</$tag>"
            set str2 " />"
        }
        set str2_used 0
        set i [string first $str $mrml]
        if {($i<=0) && ([info exists str2])} {
            set i [string first $str2 $mrml]
            set str2_used 1
        }
        if {!$str2_used} {
            set mrml [string range $mrml [expr $i + [string length $str]] end]
        } else {
            set mrml [string range $mrml [expr $i + [string length $str2]] end]
        }

        # Give the EndTransform tag a name
        if {$tag == "/Transform"} {
            set tag EndTransform
        }

        # Give the EndFiducials tag a name
        if {$tag == "/Fiducials"} {
            set tag EndFiducials
        }

        # Give the EndPath tag a name
        if {$tag == "/Path"} {
            set tag EndPath
        }

        # Give the EndHierarchy tag a name
        if {$tag == "/Hierarchy"} {
            set tag EndHierarchy
        }
        
        # Give the EndModelGroup tag a name
        if {$tag == "/ModelGroup"} {
            set tag EndModelGroup
        }
        
        # Give the EndScenes tag a name
        if {$tag == "/Scenes"} {
            set tag EndScenes
        }

        # Give the EndVolumeState tag a name
        if {$tag == "/VolumeState"} {
            set tag EndVolumeState
        }
        # Give the EndSegmenter tag a name
        if {$tag == "/Segmenter"} {
            set tag EndSegmenter
        }

        # Append to List of tags1
        lappend tags1 "$tag {$attr} {$stuffing}"

        # Strip leading white space
        regsub "^\[\n\t \]*" $mrml "" mrml
    }

    # Parse the attribute list for each tag
    set tags ""
    foreach pair $tags1 {
        set tag [lindex $pair 0]
        set attr [lindex $pair 1]
        set stuffing [lindex $pair 2]
        
        # Add the options (the "stuffing" from inside the start and end tags)
        set attrList ""
        lappend attrList "options $stuffing"

        # Strip leading white space
        regsub "^\[\n\t \]*" "$attr $stuffing" "" attr

        while {$attr != ""} {
        
            # Find the next key=value pair (and also strip it off... all in one step!)
            if {([regexp "^(\[^=\]*)\[\n\t \]*=\[\n\t \]*\['\"\](\[^'\"\]*)\['\"\](.*)$" \
                $attr match key value attr] == 0) && ([string equal -length 1 $attr "/"] == 0)} {
                set errmsg "Invalid MRML file. Can't parse attributes:\n$attr"
                puts "$errmsg"
                return 0
            }
            if {[string equal -length 1 $attr "/"] == 0} {
                lappend attrList "$key $value"
            } else {
                # Strip the / at then end of an XML tag
                regsub "/" $attr "" attr
            }

            # Strip leading white space
            regsub "^\[\n\t \]*" $attr "" attr
        }

        # Add this tag
        lappend tags "$tag $attrList"
    }
    # -------------------------------------------------------
    # Finished loading # we could just use parse for that 
    # For the following part we cannot just use the MainMrml file
    # ------------------------------------------------------
    set EMSegment(VolNumber)   0
    set NumClassesDef 0
    set EMSegment(SelVolList,VolumeList) ""
    set EMSegment(NumInputChannel) 0
    foreach pair $tags {
        set tag  [lindex $pair 0]
        set attr [lreplace $pair 0 0]

        switch $tag {
        
        "Volume" {
        incr EMSegment(VolNumber)
        set num $EMSegment(VolNumber)
        set Volume($num,Name) ""
        set DataDimension "0.9375 0.9375 1.5"
        set DataSpacing 0.0
        vtkImageReader Volume($num,vol)
        # Default
        Volume($num,vol) ReleaseDataFlagOff
        Volume($num,vol) SetDataScalarTypeToShort
        Volume($num,vol) SetDataExtent 0 255 0 255 1 124 
        foreach a $attr {
            set key [lindex $a 0]
            set val [lreplace $a 0 0]
            switch [string tolower $key] {
            "name"            {set Volume($num,Name) $val}
            "filepattern"     {Volume($num,vol) SetFilePattern    $val}
            "fileprefix"      {set Volume($num,FilePrefix) $val; Volume($num,vol) SetFilePrefix $val}
            "imagerange"      {set Volume($num,ImageRange) $val; eval Volume($num,vol) SetDataExtent 0 255 0 255 $val}
            "spacing"         {set DataSpacing $val}
            "dimensions"      {set DataDimensions $val}
            "scalartype"      {Volume($num,vol) SetDataScalarTypeTo$val}
            "numscalars"      {Volume($num,vol) SetNumberOfScalarComponents $val}
            "littleendian" {
                if {$val == "yes" || $val == "true"} {
                Volume($num,vol) SetDataByteOrderToLittleEndian
                } else {
                Volume($num,vol) SetDataByteOrderToBigEndian
                }
            }
            }
            set DataDim3 [lindex $DataDimension 2]
            set DataDimension [lreplace $DataDimension 2 2 [expr $DataSpacing +$DataDim3]]  
            eval Volume($num,vol) SetDataSpacing $DataDimension
        }
        puts "===================== Volume $Volume($num,Name) defined ====================="
        if {$EMSegment(debug)} {puts "[Volume($num,vol) Print]"}    
        }
        "Segmenter" {
        set EMSegment(NumClasses) 0 
        set EMSegment(MaxInputChannelDef) 0
        set EMSegment(EMiteration) 0 
        set EMSegment(MFAiteration) 0
        set EMSegment(Alpha) 0
        set EMSegment(SmWidth) 0
        set EMSegment(SmSigma) 0
        set EMSegment(PrintIntermediateResults) 0
        set EMSegment(PrintIntermediateSlice) -1 
        set EMSegment(PrintIntermediateFrequency) -1 
        set EMSegment(StartSlice) 0 
        set EMSegment(EndSlice) 0 
        set EMSegment(NumberOfTrainingSamples) 0 
        foreach a $attr {
            set key [lindex $a 0]
            set val [lreplace $a 0 0]
            switch [string tolower $key] {
            "numclasses"         {set EMSegment(NumClasses) $val}
            "maxinputchanneldef" {set EMSegment(MaxInputChannelDef) $val}
            "emiteration"        {set EMSegment(EMiteration) $val}
            "mfaiteration"       {set EMSegment(MFAiteration) $val}
            "alpha"              {set EMSegment(Alpha) $val}
            "smwidth"            {set EMSegment(SmWidth) $val}
            "smsigma"            {set EMSegment(SmSigma) $val}
            "printintermediateresults"   {set EMSegment(PrintIntermediateResults) $val}
            "printintermediateslice"     {set EMSegment(PrintIntermediateSlice) $val}
            "printintermediatefrequency" {set EMSegment(PrintIntermediateFrequency) $val}
            "startslice"                 {set EMSegment(StartSlice) $val}
            "endslice"                   {set EMSegment(EndSlice) $val}
            "numberoftrainingsamples"    {set EMSegment(NumberOfTrainingSamples) $val}
            }
        }
        puts "===================== EM Segmenter Parameters  ====================="
        if {$EMSegment(debug)} {puts "[array get EMSegment]"}
        # Define default Class Parameters
        for {set i 1} { $i <= $EMSegment(NumClasses)} {incr i} {
            set EMSegment(Cattrib,$i,Name) ""
            set EMSegment(Cattrib,$i,ProbabilityData) 0
            for {set y 0} {$y < $EMSegment(MaxInputChannelDef)} {incr y} {
            set EMSegment(Cattrib,$i,LogMean,$y) 0.0
            for {set x 0} {$x < $EMSegment(MaxInputChannelDef)} {incr x} {
                set EMSegment(Cattrib,$i,LogCovariance,$y,$x)  0.0     
            }
            }
            set EMSegment(Cattrib,$i,Label) 0
            set EMSegment(Cattrib,$i,Prob) 0.0
        }
        foreach Name $EMSegment(CIMList) {
            for {set y 1} { $y<= $EMSegment(NumClasses)} {incr y} {
            for {set x 1} { $x<= $EMSegment(NumClasses)} {incr x} {
                set EMSegment(CIMMatrix,$x,$y,$Name) 0.0
            }
            }
        }
        }    
        "SegmenterInput" {
        foreach a $attr {
            set key [lindex $a 0]
            set val [lreplace $a 0 0]
            switch [string tolower $key] {
            "name"        {set Name $val}
            "fileprefix"  {set FilePrefix $val}
            "filename"    {set FileName $val}
            "imagerange"  {set ImageRange  $val}
            }
        }
        for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
            if {$FilePrefix == $Volume($i,FilePrefix) && $FileName == $Volume($i,Name) && $ImageRange == $Volume($i,ImageRange)} { 
            incr EMSegment(NumInputChannel)
            lappend EMSegment(SelVolList,VolumeList) $i
            puts "===================== EM Segmenter Input Channel $Name  ====================="
            break
            }
        }    
        }
        "SegmenterClass" {
        incr NumClassesDef 
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
            }
        }
        set index 0
        for {set y 0} {$y < $EMSegment(MaxInputChannelDef)} {incr y} {
            set EMSegment(Cattrib,$NumClassesDef,LogMean,$y) [lindex $LogMean $y]
            for {set x 0} {$x < $EMSegment(MaxInputChannelDef)} {incr x} {
            set EMSegment(Cattrib,$NumClassesDef,LogCovariance,$y,$x)  [lindex $LogCovariance $index]
            incr index
            }
            incr index
        }
        for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
            if {$LocalPriorPrefix == $Volume($i,FilePrefix) && $LocalPriorName == $Volume($i,Name) && $LocalPriorRange == $Volume($i,ImageRange)} { 
            set EMSegment(Cattrib,$NumClassesDef,ProbabilityData) $i
            break
            }
        }
        puts "===================== EM Segmenter Class $EMSegment(Cattrib,$NumClassesDef,Name) ========================"
        if {$EMSegment(debug)} {puts "[array get EMSegment Cattrib,$NumClassesDef,*]"}
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
            for {set y 1} { $y<= $EMSegment(NumClasses)} {incr y} {
            for {set x 1} { $x<= $EMSegment(NumClasses)} {incr x} {
                set EMSegment(CIMMatrix,$x,$y,$Name) [lindex $CIMMatrix $i]
                incr i
            }
            incr i
            }
            puts "===================== EM Segmenter CIM $Name  ========================"
            if {$EMSegment(debug)} {puts "[array get EMSegment CIMMatrix,*,*,$Name]"}
        }
        }
    }
    }
    return 1
}


#-------------------------------------------------------------------------------
# 3. Step Execute 
#-------------------------------------------------------------------------------
puts "Load File TestImageEMSegmentData.xml"
if {[LoadFile TestImageEMSegmentData.xml] < 1} {
  puts "Error:: Could not load the file TestImageEMSegmentData.xml"
  exit 1 
}

EMSegmentTrainCIMField 

#-------------------------------------------------------------------------------
# 4. Display result 
#-------------------------------------------------------------------------------
set correct(West)  " 0.899 0.039 0.000\n 0.100 0.901 0.027\n 0.001 0.060 0.973"
set correct(North) " 0.891 0.042 0.000\n 0.107 0.901 0.026\n 0.002 0.058 0.974" 
set correct(Up)    " 0.845 0.059 0.000\n 0.150 0.873 0.035\n 0.005 0.068 0.965"
set correct(East)  " 0.899 0.039 0.000\n 0.100 0.901 0.027\n 0.001 0.060 0.973"
set correct(South) " 0.891 0.041 0.000\n 0.108 0.901 0.026\n 0.001 0.058 0.974" 
set correct(Down)  " 0.845 0.058 0.001\n 0.153 0.864 0.030\n 0.002 0.078 0.969"

set flag 1
foreach dir $EMSegment(CIMList) {
  set result($dir) ""
  for {set x 1} {$x <= $EMSegment(NumClasses)} {incr x} {
     for {set y 1} {$y <= $EMSegment(NumClasses)} {incr y} {
          set result($dir) "$result($dir) [format %6.4f $EMSegment(CIMMatrix,$x,$y,$dir)]"
     }
     if {$x < $EMSegment(NumClasses)} {set result($dir) "$result($dir)\n"}
  }
  if {$result($dir) != $correct($dir)} {set flag 0; puts "$dir incorrect";}
} 

puts "The outcome is :"
if {$flag} {
 puts "CIM Matric Calculation passed test successfully"
} else {
  puts " ===================== ERROR =============="
  puts " Error in CIM Matrix Calculation"
  puts " =========================================="

  foreach dir $EMSegment(CIMList) {
    puts  "=========== $dir ================"
    puts "The outcome should be :"
    puts $correct($dir)
    puts "The result of the Test is:"
    puts $result($dir)
  }
}

set correct(prob) "0.106893 0.275955 0.617152 "
set result(prob) ""
for {set x 1} {$x <= $EMSegment(NumClasses)} {incr x} { set result(prob) "$result(prob)$EMSegment(Cattrib,$x,Prob) "}
if {$correct(prob) == $result(prob)} {
  puts "Class Probability Calculation passed test successfully"
} else {
  puts " ===================== ERROR =============="
  puts " Error in Class Probability Calculation"
  puts " =========================== =============="
  puts "The outcome should be : "
  puts $correct(prob)
  puts "The result of the Test is:"
  puts $result(prob)
}

#-------------------------------------------------------------------------------
# 6. Delete all the old instances 
#-------------------------------------------------------------------------------
for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
  Volume($i,vol) Delete
}  
exit 0







