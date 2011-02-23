#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: BXH.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:14 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        BXH.tcl
# PROCEDURES:  
#   VolBXHLoadVolumes 
#   VolBXHOrganizeVolumeInfo 
#   VolBXHLoadDCM 
#   VolBXHSetSliders  the
#   VolBXHLoadRegularDCMFiles 
#   VolBXHDisplayDCMSingleVolume  the the
#   VolBXHCreateVolumeFromMosaic   the
#   VolBXHIsValidSlice  the
#   VolBXHLoadSiemensMosaic 
#   VolBXHCreateVolumeNameFromFileName  the
#   VolBXHCreateMrmlNodeForVolume the the
#   VolBXHLoadAnalyze 
#   VolBXHCreateVolumeFromAnalyze   the
#   VolBXHGetScanOrder 
#   VolBXHRetrieveVolumeInfoFromBXHTree  the
#   VolBXHHandleImageDatarecElement  the
#   VolBXHHandleElementtypeElement  the
#   VolBXHPrint 
#   VolBXHHandleDimensionElement  the
#   VolBXHHandleHistoryElement  the
#   VolBXHHandleSubjectElement  the
#   VolBXHHandleAcquisitiondataElement  the
#   VolBXHHandleGenericDatarecElement  the
#==========================================================================auto=
 
#-------------------------------------------------------------------------------
# .PROC VolBXHLoadVolumes 
# Reads a BXH file. It returns 0 if successful; 1 otherwise.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHLoadVolumes {} {
    global VolBXH Gui 

    set fn $VolBXH(bxh-fileName)

    if {$fn == ""} {
        DevErrorWindow "File name field is empty."
        return 1
    }

    if {[file exists $fn] == 0} { 
        DevErrorWindow "File doesn't exist: $fn"
        return 1
    }

    # The directory the bxh file is located
    set dir [file dirname $fn]
    set VolBXH(bxh-dir) $dir
    set VolBXH(bxh-noOfImgFiles) 0

    unset -nocomplain VolBXH(bxh-dimensions)
    unset -nocomplain VolBXH(bxh-imageType)
    unset -nocomplain VolBXH(bxh-dim,outputSelect)
    if {[info exists VolBXH(lastIndex)]} {
        set i 1
        while {$i <= $VolBXH(lastIndex)} {
            unset VolBXH($i,id)
            incr i
        }

        unset VolBXH(lastIndex)
    }

    if {[info exists VolBXH(bxhparser)]} {
        $VolBXH(bxhparser) Delete
    }
    vtkBXHParser bxhParser 
    bxhParser SetFileName $fn 
    set parsed [bxhParser Parse]
    if {! $parsed} {
        DevErrorWindow "Failed to parse bxh file: $fn"
        return 1
    }
    
    set root [bxhParser GetRootElement]
    set name [$root GetName]
    if {$name != "bxh"} {
        DevErrorWindow "No bxh tag found: $fn"
        return 1
    }

    set VolBXH(bxhparser) bxhParser
    VolBXHRetrieveVolumeInfoFromBXHTree $root
    VolBXHOrganizeVolumeInfo

    # Resets bxh slider
    set sliderNum [llength $VolBXH(slider)]
    if {$sliderNum > 0} {
        set i 0
        while {$i < $sliderNum} {
            set slider [lindex $VolBXH(slider) $i]
            $slider set 0 
            $slider configure -showvalue 1 
            incr i
        }
    }

    unset -nocomplain VolBXH(MRMLid)
    unset -nocomplain VolBXH(volumeExtent)

    # Reads image or volume(s)
    switch $VolBXH(bxh-imageType) {
        "dcm" {
            VolBXHLoadDCM
        }
        "img" {
            VolBXHLoadAnalyze
        }
    }

    # Volume loading complete
    set VolBXH(name) "" 

    # If the loaded bxh file contains a single volume, go back to
    # the parent frame; otherwise stay in the bxh UI so that 
    # user can navigate the time sequence.
    if {[info exists VolBXH(bxh-dim,t,size)] == 0} {
        VolumesPropsCancel
    }

    return 0
}


#-------------------------------------------------------------------------------
# .PROC VolBXHOrganizeVolumeInfo 
# Organizes the volume info read from bxh file 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHOrganizeVolumeInfo {} {
    global VolBXH

    # Scan order
    set VolBXH(bxh-scanOrder) [VolBXHGetScanOrder]

    # z spacing
    set zSpacing 0
    foreach m $VolBXH(bxh-dimensions) {
        if {[expr {$m == "z" || $m == "z-split2"}]} {
        
            set sliceThickness $VolBXH(bxh-dim,$m,spacing)
            set sliceGap $VolBXH(bxh-dim,$m,gap)
        }
    }
    set VolBXH(bxh-sliceThickness) $sliceThickness
    set VolBXH(bxh-sliceGap) $sliceGap
} 


#-------------------------------------------------------------------------------
# .PROC VolBXHLoadDCM 
# Loads DCM files 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHLoadDCM {} {
    global VolBXH Volume Mrml

    set m 1
    set num [llength $VolBXH(bxh-dimensions)]
    if {$num == 3} {
        # A single volume by multiple dcm files, each of which is a slice image
        VolBXHLoadRegularDCMFiles 
    } elseif {$num == 4 || $num == 5} {
        # num = 4; A single volume by a Siemens mosaic file 

        # num = 5; A time series by multiple files, each of which is a volume
        # (Siemens mosaic format)
        set m $VolBXH(bxh-noOfImgFiles)
        VolBXHLoadSiemensMosaic
    } else {
        puts "No support for this dicom format yet."
        return
    }

    VolBXHSetSliders $m
}


#-------------------------------------------------------------------------------
# .PROC VolBXHSetSliders 
# Sets right value for all volume sliders  
# .ARGS
# max the max value of sliders
# .END
#-------------------------------------------------------------------------------
proc VolBXHSetSliders {max} {
    global VolBXH 

    set sliderNum [llength $VolBXH(slider)]
    if {$sliderNum > 0} {
        set i 0
        while {$i < $sliderNum} {
            set slider [lindex $VolBXH(slider) $i]
            $slider configure -from 1 -to $max
            $slider configure -state active
            $slider configure -showvalue 1 
            incr i
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC VolBXHLoadRegularDCMFiles 
# Loads a single volume by regular dcm files  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHLoadRegularDCMFiles {} {
    global VolBXH Volume 

    set maxX [expr $VolBXH(bxh-dim,x,size) - 1]
    set maxY [expr $VolBXH(bxh-dim,y,size) - 1]

    vtkImageAppend ip

    # If you want to create a volue from a series of XY images, then you should
    # set the AppendAxis to 2 (Z axis).
    ip SetAppendAxis 2 

    set i 1 
    while {$i <= $VolBXH(bxh-noOfImgFiles)} {

        set f $VolBXH(bxh-img,$i,name)
        puts "reading $f"

        vtkImageReader ir$i
        ir$i SetFileName $f
        ir$i ReleaseDataFlagOff
        ir$i SetDataSpacing $VolBXH(bxh-dim,x,spacing) \
            $VolBXH(bxh-dim,y,spacing) $VolBXH(bxh-sliceThickness)
        ir$i SetDataByteOrder $VolBXH(bxh-littleEndian)
        ir$i SetDataExtent 0 $maxX 0 $maxY 0 0 
        
        ip AddInput [ir$i GetOutput] 

        incr i
    }

    set volData [ip GetOutput]
    VolBXHDisplayDCMSingleVolume $f $volData 

    set i 1
    while {$i <= $VolBXH(bxh-noOfImgFiles)} {

        ir$i Delete 
        incr i
    }
    ip Delete
}


#-------------------------------------------------------------------------------
# .PROC VolBXHDisplayDCMSingleVolume 
# Displays a single DCM volume   
# .ARGS
# fileName the file name
# volData the volume to be displayed
# .END
#-------------------------------------------------------------------------------
proc VolBXHDisplayDCMSingleVolume {fileName volData} {
    global VolBXH Volume Mrml

    MainVolumesSetActive "NEW"
    
    set volName [VolBXHCreateVolumeNameFromFileName $fileName]
    set Volume(name) $volName
    set load "Loading volume:\n"
    append load $volName
    set VolBXH(name) $load 

    set id [VolBXHCreateMrmlNodeForVolume $volName $volData]
    set VolBXH(1,id) $id
    set VolBXH(lastIndex) 1

    lappend VolBXH(MRMLid) $id
    set VolBXH(volumeExtent) \
        [[Volume($id,vol) GetOutput] GetWholeExtent]
}


#-------------------------------------------------------------------------------
# .PROC VolBXHCreateVolumeFromMosaic  
# Creates a vtkImageData object from a Siemens dicom mosaic file  
# .ARGS
# fileName the mosaic file name
# .END
#-------------------------------------------------------------------------------
proc VolBXHCreateVolumeFromMosaic {fileName} {
    global VolBXH 

    puts "reading $fileName"

    vtkImageReader ir

    # Here is the coordinate system
    # y axis
    # ^
    # |------------------------
    # |  0  |  1  |  2  |  3  |
    # |-----------------------| 
    # |...   mosaic image     |
    # |                       |
    # |                       |
    # ------------------------->
    #                    x axis
    #
    set x $VolBXH(bxh-dim,x,size) 
    set z1 $VolBXH(bxh-dim,z-split1,size) 
    set y $VolBXH(bxh-dim,y,size) 
    set z2 $VolBXH(bxh-dim,z-split2,size) 
    set maxX [expr $x * $z1 - 1] 
    set maxY [expr $y * $z2 - 1] 

    ir SetFileName $fileName
    ir SetDataByteOrder $VolBXH(bxh-littleEndian) 
    ir SetDataSpacing $VolBXH(bxh-dim,x,spacing) \
        $VolBXH(bxh-dim,y,spacing) $VolBXH(bxh-sliceThickness)
    ir ReleaseDataFlagOff
    ir SetDataExtent 0 $maxX 0 $maxY 0 0 

    # If you want to create a volue from a series of XY images, 
    # then you should set the AppendAxis to 2 (Z axis).
    vtkImageAppend VolBXH(imageAppend) 
    VolBXH(imageAppend) SetAppendAxis 2 

    set count 0
    set i 1
    set j $z2 
    while {$j > 0} {
        while {$i <= $z1} {

            # If this slice no is not valid, go to next one
            if {[VolBXHIsValidSlice $count]} {

                vtkExtractVOI extract
                extract SetInput [ir GetOutput]
                extract SetSampleRate 1 1 1 

                vtkImageData vol

                set x1 [expr ($i - 1) * $x]
                set x2 [expr $i * $x - 1]
                set y1 [expr ($j - 1) * $y]
                set y2 [expr $j * $y - 1]

                extract SetVOI $x1 $x2 $y1 $y2 0 0 
                extract Update

                set d [extract GetOutput]
                # Setting directly the extent of extract's output does not 
                # change its extent. That's why DeepCopy is here.
                vol DeepCopy $d
                vol SetExtent 0 [expr $x - 1] 0 [expr $y - 1] 0 0 

                VolBXH(imageAppend) AddInput vol 
                extract Delete
                vol Delete
            }
            incr i
            incr count
        }
        set j [expr $j - 1]
        set i 1
    }

    ir Delete
}


#-------------------------------------------------------------------------------
# .PROC VolBXHIsValidSlice 
# Checks if a slice should be added into the volume from the Siemens mosaic 
# .ARGS
# sliceNo the slice number to be checked
# .END
#-------------------------------------------------------------------------------
proc VolBXHIsValidSlice {sliceNo} {
    global VolBXH 

    set out $VolBXH(bxh-dim,outputSelect) 
    set result [lsearch -inline -integer $out $sliceNo]
    set result [expr {$result == "" ? 0 : 1}]

    return $result
}


#-------------------------------------------------------------------------------
# .PROC VolBXHLoadSiemensMosaic 
# Loads Siemens mosaic file(s) 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHLoadSiemensMosaic {} {
    global VolBXH Volume 

    set i 1 
    while {$i <= $VolBXH(bxh-noOfImgFiles)} {   

        set f $VolBXH(bxh-img,$i,name)

        MainVolumesSetActive "NEW"

        set volName [VolBXHCreateVolumeNameFromFileName $f]
        set Volume(name) $volName
        set load "Loading volume:\n"
        append load $volName
        set VolBXH(name) $load 

        VolBXHCreateVolumeFromMosaic $f
        set volData [VolBXH(imageAppend) GetOutput] 
        set id [VolBXHCreateMrmlNodeForVolume $volName $volData]
        set VolBXH($i,id) $id
        lappend VolBXH(MRMLid) $id

        incr i
        VolBXH(imageAppend) Delete
    }

    set VolBXH(lastIndex) $VolBXH(bxh-noOfImgFiles)

    set VolBXH(volumeExtent) \
        [[Volume([lindex $VolBXH(MRMLid) 0],vol) GetOutput] GetWholeExtent]
}


#-------------------------------------------------------------------------------
# .PROC VolBXHCreateVolumeNameFromFileName 
# Creates a volume name from the file name 
# .ARGS
# fileName the file name
# .END
#-------------------------------------------------------------------------------
proc VolBXHCreateVolumeNameFromFileName {fileName} {

    set tail [file tail $fileName]
    set dot [string last "." $tail]
    set name [string replace $tail $dot $dot "-"] 

    return $name
}
 

#-------------------------------------------------------------------------------
# .PROC VolBXHCreateMrmlNodeForVolume
# Creates a mrml node for a vtkImageData object 
# .ARGS
# volName the volume name
# volData the vtkImageData object
# .END
#-------------------------------------------------------------------------------
proc VolBXHCreateMrmlNodeForVolume {volName volData} {
    global VolBXH Volume Mrml

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i

    # set the name and description of the volume
    $n SetName $volName 
    $n SetDescription $volName 

    Volume($i,node) SetScanOrder $VolBXH(bxh-scanOrder)
    Volume($i,node) SetLittleEndian $VolBXH(bxh-littleEndian) 

# puts "bxh scan order = $VolBXH(bxh-scanOrder)"
# puts "bxh little endian = $VolBXH(bxh-littleEndian)"

    $volData Update 

    set spc [$volData GetSpacing]
    set pixelWidth [lindex $spc 0]
    set pixelHeight [lindex $spc 1]
    set sliceThickness [lindex $spc 2]
    set zSpacing [expr $sliceThickness + $VolBXH(bxh-sliceGap)]

# puts "bxh pixelWidth = $pixelWidth"
# puts "bxh pixelHeight = $pixelHeight"
# puts "bxh sliceThickness = $sliceThickness"
# puts "bxh zSpacing = $zSpacing"

    eval Volume($i,node) SetSpacing $pixelWidth $pixelHeight $zSpacing 
    Volume($i,node) SetNumScalars [$volData GetNumberOfScalarComponents]
    set ext [$volData GetWholeExtent]
    Volume($i,node) SetImageRange [expr 1 + [lindex $ext 4]] [expr 1 + [lindex $ext 5]]
    Volume($i,node) SetScalarType [$volData GetScalarType]
    Volume($i,node) SetDimensions [lindex [$volData GetDimensions] 0] \
        [lindex [$volData GetDimensions] 1]
    Volume($i,node) ComputeRasToIjkFromScanOrder [Volume($i,node) GetScanOrder]

#    MainUpdateMRML
    Volume($i,vol) SetImageData $volData
    MainVolumesSetActive $i

    return $i
}


#-------------------------------------------------------------------------------
# .PROC VolBXHLoadAnalyze 
# Loads Analyze file(s) 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHLoadAnalyze {} {
    global VolBXH Volume Mrml
    
    set i 1 
    while {$i <= $VolBXH(bxh-noOfImgFiles)} {   

        set f $VolBXH(bxh-img,$i,name)

        MainVolumesSetActive "NEW"

        set volName [VolBXHCreateVolumeNameFromFileName $f]
        set Volume(name) $volName
        set load "Loading volume:\n"
        append load $volName
        set VolBXH(name) $load 

        VolBXHCreateVolumeFromAnalyze $f
        set volData [VolBXH(imageAppend) GetOutput] 
        set id [VolBXHCreateMrmlNodeForVolume $volName $volData]
        set VolBXH($i,id) $id
        lappend VolBXH(MRMLid) $id

        incr i
        VolBXH(imageAppend) Delete
    }

    set VolBXH(lastIndex) $VolBXH(bxh-noOfImgFiles)
    set VolBXH(volumeExtent) \
        [[Volume([lindex $VolBXH(MRMLid) 0],vol) GetOutput] GetWholeExtent]

    set m [expr $i-1]
    VolBXHSetSliders $m
}


#-------------------------------------------------------------------------------
# .PROC VolBXHCreateVolumeFromAnalyze  
# Creates a vtkImageData object from an Analyze img file  
# .ARGS
# fileName the Analyze img file name
# .END
#-------------------------------------------------------------------------------
proc VolBXHCreateVolumeFromAnalyze {fileName} {
    global VolBXH 

    puts "reading $fileName"

    vtkImageReader ir

    # Here is the coordinate system
    # x axis
    # ^
    # |------------------------------------| 
    # |          |          |              |
    # | slice #1 | slice #2 |  ......      |
    # |          |          |              |
    # -------------------------------------------->
    #                    y axis
    #
    set x $VolBXH(bxh-dim,x,size) 
    set y $VolBXH(bxh-dim,y,size) 
    set z $VolBXH(bxh-dim,z,size) 
    set maxX [expr $x - 1] 
    set maxY [expr $y * $z - 1] 

# puts "bxh x = $x"
# puts "bxh y = $y"
# puts "bxh z = $z"

# puts "bxh littleEndian = $VolBXH(bxh-littleEndian)"
# puts "bxh VolBXH(bxh-dim,x,spacing) = $VolBXH(bxh-dim,x,spacing)"  
# puts "bxh VolBXH(bxh-dim,y,spacing) = $VolBXH(bxh-dim,y,spacing)"  
# puts "bxh VolBXH(bxh-sliceThickness) = $VolBXH(bxh-sliceThickness)"

    ir SetFileName $fileName
    ir SetDataScalarTypeToShort
    ir SetDataByteOrder $VolBXH(bxh-littleEndian) 
    ir SetDataSpacing $VolBXH(bxh-dim,x,spacing) \
        $VolBXH(bxh-dim,y,spacing) $VolBXH(bxh-sliceThickness)
    ir ReleaseDataFlagOff
    ir SetDataExtent 0 $maxX 0 $maxY 0 0 

    # If you want to create a volue from a series of XY images, 
    # then you should set the AppendAxis to 2 (Z axis).
    vtkImageAppend VolBXH(imageAppend) 
    VolBXH(imageAppend) SetAppendAxis 2 

    set x1 0 
    set x2 $maxX 
    set count 0
    set i 1
    while {$i <= $z} {

        vtkExtractVOI extract
        extract SetInput [ir GetOutput]
        extract SetSampleRate 1 1 1 

        vtkImageData vol
        set y1 [expr ($i - 1) * $y]
        set y2 [expr $i * $y - 1]

        extract SetVOI $x1 $x2 $y1 $y2 0 0 
        extract Update

        set d [extract GetOutput]
        # Setting directly the extent of extract's output does not 
        # change its extent. That's why DeepCopy is here.
        vol DeepCopy $d
        vol SetExtent 0 [expr $x - 1] 0 [expr $y - 1] 0 0 

        VolBXH(imageAppend) AddInput vol 
        extract Delete
        vol Delete
        
        incr i
        incr count
    }

    ir Delete
}


#-------------------------------------------------------------------------------
# .PROC VolBXHGetScanOrder 
# Computes the scan order 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHGetScanOrder {} {
    global VolBXH

    # BXH uses RAS system
    # +X = R
    # +Y = A
    # +Z = S
 
    set direction ""
    foreach m $VolBXH(bxh-dimensions) {
        if {[expr {$m == "z" || $m == "z-split2"}] && \
            [info exists VolBXH(bxh-dim,$m,direction)]} {
            set direction $VolBXH(bxh-dim,$m,direction)
        }
    }

    set so {IS}

    # Replaces multiple spaces by one
    regsub -all {\s+} $direction " " direction

    # Trims spaces on both sides
    set direction [string trim $direction " "]

    set xyz [split $direction]
    set len [llength $xyz]
    if {$len != 3} {
        return
    }
    
    # Handles "-0", "+0" and "+1"
    set i 0
    while {$i < $len} {
        set value [lindex $xyz $i]
        if {$value == "+0" || $value == "-0"} {
            set xyz [lreplace $xyz $i $i "0"]
        }
        if {$value == "+1"} {
            set xyz [lreplace $xyz $i $i "1"]
        }
        incr i
    }

    set x [lindex $xyz 0]
    set y [lindex $xyz 1]
    set z [lindex $xyz 2]

    # Gets scan order
    if {$x == 0 && $y == 0 && $z == 1} {
        set so {IS}
    } elseif {$x == 0 && $y == 0 && $z == -1} {
        set so {SI}
    } elseif {$x == 1 && $y == 0 && $z == 0} {
        set so {LR}
    } elseif {$x == -1 && $y == 0 && $z == 0} {
        set so {RL}
    } elseif {$x == 0 && $y == 1 && $z == 0} {
        set so {PA}
    } elseif {$x == 0 && $y == -1 && $z == 0} {
        set so {AP}
    } else {
        set so {IS}
    }

    return $so
}  


#-------------------------------------------------------------------------------
# .PROC VolBXHRetrieveVolumeInfoFromBXHTree 
# Retrieves image header from the bxh tree 
# .ARGS
# root the root node (element) of the bxh tree
# .END
#-------------------------------------------------------------------------------
proc VolBXHRetrieveVolumeInfoFromBXHTree {root} {

    set numOfNestedEle [$root GetNumberOfNestedElements]
    if {$numOfNestedEle > 0} {
        set i 0
        while {$i < $numOfNestedEle} { 
            set next [$root GetNestedElement $i]
            set name [$next GetName]
            switch $name {
                "history" {
                    VolBXHHandleHistoryElement $next 
                }
                "subject" {
                    VolBXHHandleSubjectElement $next
                }
                "acquisitiondata" {
                    VolBXHHandleHistoryElement $next 
                }
                "datarec" {
                    set attr [$next GetAttribute "type"]
                    if {$attr == "image"} {
                        VolBXHHandleImageDatarecElement $next
                    } else {
                        VolBXHHandleGenericDatarecElement $next
                    }
                } 
            }
            incr i
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleImageDatarecElement 
# Handles image Datarec element in the bxh tree 
# .ARGS
# imgdatarec the image datarec element to be handled
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleImageDatarecElement {imgdatarec} {
    global VolBXH 

    set numOfNestedEle [$imgdatarec GetNumberOfNestedElements]
    if {$numOfNestedEle > 0} {
        set ii 0
        while {$ii < $numOfNestedEle} { 
            set next [$imgdatarec GetNestedElement $ii]
            set name [$next GetName]
            if {$name == "dimension"} {
                VolBXHHandleDimensionElement $next
            } else {
                set value [$VolBXH(bxhparser) ReadElementValue $next]
                switch $name {
                    "byteorder" {
                        set opt [expr {$value == "lsbfirst" ? 1 : 0}]
                        set VolBXH(bxh-littleEndian) $opt 
                    }
                    "elementtype" {
                        VolBXHHandleElementtypeElement $value 
                    }
                    "filename" {
                        # Checks image type
                        if {! [info exists VolBXH(bxh-imageType)]} {
                            set i [string last "." $value]
                            set start [expr $i + 1]
                            set end [expr $start + 3]
                            set ext [string range $value $start $end]
                            set VolBXH(bxh-imageType) $ext
                        }

                        set index [expr $VolBXH(bxh-noOfImgFiles) + 1]
                        set pathName [file join $VolBXH(bxh-dir) $value]
                        set VolBXH(bxh-img,$index,name) $pathName
                        set VolBXH(bxh-noOfImgFiles) $index
                    }                    
                    "fileoffset" {
                        set i $VolBXH(bxh-noOfImgFiles)
                        set VolBXH(bxh-img,$i,offset) $value
                    }                    
                    "filerecordsize" {
                        set i $VolBXH(bxh-noOfImgFiles)
                        set VolBXH(bxh-img,$i,recordsize) $value
                    }                    
                }
            }
            incr ii
        }
 
        # VolBXHPrint
    } else {
        puts "This image datarec element is empty!" 
    }
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleElementtypeElement 
# Handles Elementtype element in the bxh tree 
# .ARGS
# type the value of the elementtype element 
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleElementtypeElement {type} {
    global VolBXH 

    switch $type {
        "int8" {
            set opt VTK_CHAR 
        }
        "uint8" {
            set opt VTK_UNSIGNED_CHAR 
        }
        "int16" {
            set opt VTK_SHORT 
        }
        "uint16" {
            set opt VTK_UNSIGNED_SHORT 
        }
        "int32" {
            set opt VTK_INT 
        }
        "uint32" {
            set opt VTK_UNSIGNED_INT 
        }
        "int64" {
            set opt VTK_LONG 
        }
        "uint64" {
            set opt VTK_UNSIGNED_LONG 
        }
        "float32" {
            set opt VTK_FLOAT 
        }
        "float64" {
            set opt VTK_DOUBLE 
        }
        "ascii" {
            set opt VTK_VOID 
        }
    }

    set VolBXH(bxh-scalarType) $opt 
}


#-------------------------------------------------------------------------------
# .PROC VolBXHPrint 
# Prints all parsed values 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolBXHPrint {} {
    global VolBXH 

    puts "\nbxh/datarec (img)/little endian: $VolBXH(bxh-littleEndian)"
    puts "bxh/datarec (img)/scalar type: $VolBXH(bxh-scalarType)"
    puts "bxh/datarec (img)/bxh directory: $VolBXH(bxh-dir)"
    puts "bxh/datarec (img)/total no of img files: $VolBXH(bxh-noOfImgFiles)\n"
 
    # Dimension info
    foreach m $VolBXH(bxh-dimensions) {
        if {[info exists VolBXH(bxh-dim,$m,units)]} {
            puts "Dimension $m (units): $VolBXH(bxh-dim,$m,units)"
        }
        if {[info exists VolBXH(bxh-dim,$m,size)]} {
            puts "Dimension $m (size): $VolBXH(bxh-dim,$m,size)"
        }
        if {[info exists VolBXH(bxh-dim,$m,origin)]} {
            puts "Dimension $m (origin): $VolBXH(bxh-dim,$m,origin)"
        }
        if {[info exists VolBXH(bxh-dim,$m,gap)]} {
            puts "Dimension $m (gap): $VolBXH(bxh-dim,$m,gap)"
        }
        if {[info exists VolBXH(bxh-dim,$m,spacing)]} {
            puts "Dimension $m (spacing): $VolBXH(bxh-dim,$m,spacing)"
        }
        if {[info exists VolBXH(bxh-dim,$m,direction)]} {
            puts "Dimension $m (direction): $VolBXH(bxh-dim,$m,direction)"
        }
        puts "\n"
    }

    # Image files
    set i 1 
    while {$i <= $VolBXH(bxh-noOfImgFiles)} {
        puts "Image file $i (file name): $VolBXH(bxh-img,$i,name)"
        # puts "Image file $i (file offset): $VolBXH(bxh-img,$i,offset)"
        # puts "Image file $i (file recordsize): $VolBXH(bxh-img,$i,recordsize)"
        incr i
    }
    puts "\n"
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleDimensionElement 
# Handles Dimension element in the bxh tree 
# .ARGS
# dimension the dimension element to be handled
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleDimensionElement {dimension} {
    global VolBXH 

    set type [$dimension GetAttribute "type"]
    if {$type == "z-split2"} {
        set outputSelect [$dimension GetAttribute "outputselect"]
        set outputList [split $outputSelect]
        set VolBXH(bxh-dim,outputSelect) $outputList
    }
    set numOfNestedEle [$dimension GetNumberOfNestedElements]
    if {$numOfNestedEle > 0} {
        set ii 0
        while {$ii < $numOfNestedEle} { 
            set next [$dimension GetNestedElement $ii]
            set name [$next GetName]
            set value [$VolBXH(bxhparser) ReadElementValue $next]
            set VolBXH(bxh-dim,$type,$name) $value
            incr ii
        }
 
        lappend VolBXH(bxh-dimensions) $type
     }
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleHistoryElement 
# Handles History element in the bxh tree 
# .ARGS
# history the history element to be handled
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleHistoryElement {history} {
    global VolBXH 

    # To be implemented
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleSubjectElement 
# Handles Subject element in the bxh tree 
# .ARGS
# subject the subject element to be handled
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleSubjectElement {subject} {
    global VolBXH 

    # To be implemented
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleAcquisitiondataElement 
# Handles Acquisitiondata element in the bxh tree 
# .ARGS
# acdata the acquisitiondata element to be handled
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleAcquisitiondataElement {acdata} {
    global VolBXH 

    # To be implemented
}


#-------------------------------------------------------------------------------
# .PROC VolBXHHandleGenericDatarecElement 
# Handles generic Datarec element in the bxh tree 
# .ARGS
# gcdatarec the generic datarec element to be handled
# .END
#-------------------------------------------------------------------------------
proc VolBXHHandleGenericDatarecElement {gcdatarec} {
    global VolBXH 

    # To be implemented
}


