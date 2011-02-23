#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: SiemensMosaicReader.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:04 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        SiemensMosaicReader.tcl
# PROCEDURES:  
#   SiemensMosaicReaderInit
#   SiemensMosaicReaderLoad fileNames
#   SiemensMosaicReaderCreateVolumeFromMosaic   fileName
#   SiemensMosaicReaderDecodeHeader fName
#   SiemensMosaicReaderPredictScanOrder sliceInfo
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC SiemensMosaicReaderInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SiemensMosaicReaderInit {} { 
    global SiemensMosaicReader Module Volume Model

    set m SiemensMosaicReader

    set Module($m,overview) "This module is to load a Siemens Mosaic dicom file into slicer."
    set Module($m,author) "Haiying, Liu, Brigham and Women's Hospital, hliu@bwh.harvard.edu"
    set Module($m,category) "I/O"

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.3 $} {$Date: 2006/01/06 17:58:04 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    # set SiemensMosaicReader(count) 0
    # set SiemensMosaicReader(Volume1) $Volume(idNone)
    # set SiemensMosaicReader(Model1)  $Model(idNone)
    # set SiemensMosaicReader(FileName)  ""
}


#-------------------------------------------------------------------------------
# .PROC SiemensMosaicReaderLoad
# Loads Siemens Mosaic dicom volume(s). It returns 0 if successful; 1 otherwise.
# .ARGS
# list fileNames file names 
# .END
#-------------------------------------------------------------------------------
proc SiemensMosaicReaderLoad {fileNames} { 
    global SiemensMosaicReader Volume Model

    set fName [lindex $fileNames 0]
    set rtVal [SiemensMosaicReaderDecodeHeader $fName]
    if {$rtVal} {
        return $rtVal
    }

    set SiemensMosaicReader(MRMLid) "" 
    foreach f $fileNames {   
        MainVolumesSetActive "NEW"

        set volName [DICOMHelperCreateVolumeNameFromFileName $f]
        set Volume(name) $volName
        set load "Loading volume "
        append load $volName
        append load "..."
        puts $load 

        SiemensMosaicReaderCreateVolumeFromMosaic $f
        set volData [SiemensMosaicReader(imageAppend) GetOutput] 
        set id [DICOMHelperCreateMrmlNodeForVolume $volName $volData \
            $SiemensMosaicReader(littleEndian) $SiemensMosaicReader(sliceSpacing)]
        lappend SiemensMosaicReader(MRMLid) $id

        SiemensMosaicReader(imageAppend) Delete
        puts "...done"
    }

    set SiemensMosaicReader(volumeExtent) \
        [[Volume([lindex $SiemensMosaicReader(MRMLid) 0],vol) GetOutput] GetWholeExtent]

    # show the first volume by default
    # MainSlicesSetVolumeAll Back $VolBXH(1,id)
    # RenderAll
     
    return 0 
}


#-------------------------------------------------------------------------------
# .PROC SiemensMosaicReaderCreateVolumeFromMosaic  
# Creates a vtkImageData object from a Siemens dicom mosaic file  
# .ARGS
# path fileName the mosaic file name
# .END
#-------------------------------------------------------------------------------
proc SiemensMosaicReaderCreateVolumeFromMosaic {fileName} {
    global SiemensMosaicReader 

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
    set x $SiemensMosaicReader(sliceWidth)
    set z1 [expr $SiemensMosaicReader(mosaicWidth) / $SiemensMosaicReader(sliceWidth)]
    set y $SiemensMosaicReader(sliceHeight)
    set z2 [expr $SiemensMosaicReader(mosaicHeight) / $SiemensMosaicReader(sliceHeight)]

    set maxX [expr $x * $z1 - 1] 
    set maxY [expr $y * $z2 - 1] 

    ir SetFileName $fileName
    ir SetDataByteOrder $SiemensMosaicReader(littleEndian) 
 
    ir SetDataSpacing $SiemensMosaicReader(pixelSpacingX) \
        $SiemensMosaicReader(pixelSpacingY) $SiemensMosaicReader(sliceThickness)
    ir ReleaseDataFlagOff
    ir SetDataExtent 0 $maxX 0 $maxY 0 0 

    # If you want to create a volue from a series of XY images, 
    # then you should set the AppendAxis to 2 (Z axis).
    vtkImageAppend SiemensMosaicReader(imageAppend) 
    SiemensMosaicReader(imageAppend) SetAppendAxis 2 

    set count 0
    set i 1
    set j $z2 
    while {$j > 0} {
        while {$i <= $z1} {

            # If this slice no is not valid, go to next one
            if {$count < $SiemensMosaicReader(noOfSlices)} {

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

                SiemensMosaicReader(imageAppend) AddInput vol 
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
# .PROC SiemensMosaicReaderDecodeHeader
# Decodes Siemens Mosaic dicom file header. It returns 0 if successful; 1 otherwise.
# .ARGS
# path fName file name 
# .END
#-------------------------------------------------------------------------------
proc SiemensMosaicReaderDecodeHeader {fName} { 
    global SiemensMosaicReader 

    # Reads the file
    if [catch {open $fName r} fileId] {
        puts stderr "Cannot open $fName: $fileId."
        return 1
    } else {
        fconfigure $fileId -translation binary
        set data [read $fileId]
        close $fileId
    }

    binary scan $data a* contents 
    set start [string first "sSliceArray.asSlice" $contents 0]
    set end1 [string last "sSliceArray.asSlice" $contents end]
    set end2 [string first "\n" $contents $end1]
    set sliceInfo [string range $contents $start $end2]

    # No of slices in a mosaic file
    set start [string last "\[" $sliceInfo end]
    set start [expr $start + 1]
    set end [string last "\]" $sliceInfo end]
    set end [expr $end - 1]
    set SiemensMosaicReader(noOfSlices) \
        [expr [string range $sliceInfo $start $end] + 1]
    if {$SiemensMosaicReader(noOfSlices) < 2} {
        puts stderr "Cannot creat a volume from the existing $SiemensMosaicReader slices."
        return 1
    }

    # Predicts scan order
    SiemensMosaicReaderPredictScanOrder $sliceInfo

    vtkDCMParser parser
    set found [parser OpenFile $fName]
    if {[string compare $found "0"] == 0} {
        puts stderr "Can't open file $fName."
        parser Delete
        return 1
    }

    # Mosaic dimension: width and height of the big image containing slices
    set error 0
    if { [parser FindElement 0x0028 0x0010] == "1" } {
        parser ReadElement
        set SiemensMosaicReader(mosaicHeight) [parser ReadUINT16]
    } else  {
        set SiemensMosaicReader(mosaicHeight) "unknown" 
        puts stderr "Mosaic height unknown."
        set error 1
    }

    if { [parser FindElement 0x0028 0x0011] == "1" } {
        #set Length [lindex [split [parser ReadElement]] 3]
        parser ReadElement
        set SiemensMosaicReader(mosaicWidth) [parser ReadUINT16]
    } else  {
        set SiemensMosaicReader(mosaicWidth) "unknown" 
        puts stderr "Mosaic width unknown."
        set error 1
    }

    # Slice thickness
    if { [parser FindElement 0x0018 0x0050] == "1" } {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SiemensMosaicReader(sliceThickness) [parser ReadFloatAsciiNumeric $NextBlock]
    } else  {
        set SiemensMosaicReader(sliceThickness) "unknown" 
        puts stderr "Slice thickness unknown."
        set error 1
    }

    # Spacing between slices 
    if { [parser FindElement 0x0018 0x0088] == "1" } {
        set NextBlock [lindex [split [parser ReadElement]] 4]
        set SiemensMosaicReader(sliceSpacing) [parser ReadFloatAsciiNumeric $NextBlock]
    } else  {
        set SiemensMosaicReader(sliceSpacing) "unknown" 
        puts stderr "Spacing between slices unknown."
        set error 1
    }

    # Pixel spacing
    if { [parser FindElement 0x0028 0x0030] == "1" } {
        set Length [lindex [split [parser ReadElement]] 3]
        set pixelSpacing [parser ReadText $Length]
        set spacing [split $pixelSpacing "\\"]
        set SiemensMosaicReader(pixelSpacingX) [lindex $spacing 0]
        set SiemensMosaicReader(pixelSpacingY) [lindex $spacing 1]
    } else  {
        set SiemensMosaicReader(pixelSpacingX) "unknown"
        set SiemensMosaicReader(pixelSpacingY) "unknown"
        puts stderr "Pixel spacing unknown."
        set error 1
    }

    # byte order
    set tfs [parser GetTransferSyntax] 
    if { $tfs == "3" || $tfs == "4" } {
        set SiemensMosaicReader(littleEndian) 0
    } else {
        set SiemensMosaicReader(littleEndian) 1 
    }

    parser Delete
    if {$error} {
        return 1
    }

    for {set dim 0} {[expr $dim * $dim] <= $SiemensMosaicReader(noOfSlices) } {incr dim} { }
    set SiemensMosaicReader(sliceHeight) [expr $SiemensMosaicReader(mosaicHeight) / $dim]
    set SiemensMosaicReader(sliceWidth) [expr $SiemensMosaicReader(mosaicWidth) / $dim]
 
    return 0
}


#-------------------------------------------------------------------------------
# .PROC SiemensMosaicReaderPredictScanOrder
# Predicts scan order in a Siemens Mosaic dicom file
# .ARGS
# string sliceInfo slice layout info in a mosaic 
# .END
#-------------------------------------------------------------------------------
proc SiemensMosaicReaderPredictScanOrder {sliceInfo} { 
    global SiemensMosaicReader 

    set index [string first "\[2\]" $sliceInfo]
    if {$index != -1} {
        set sliceInfo [string range $sliceInfo 0 $index]
    }
    
    set strings [split $sliceInfo "\n"]
    set sags ""
    set cors ""
    set tras ""
    foreach s $strings {
        set found [string first sPosition.dSag $s 0]
        if {$found != -1} {
            set pair [split $s "="]
            lappend sags [lindex $pair 1]
        }
        set found [string first sPosition.dCor $s 0]
        if {$found != -1} {
            set pair [split $s "="]
            lappend cors [lindex $pair 1]
        }
        set found [string first sPosition.dTra $s 0]
        if {$found != -1} {
            set pair [split $s "="]
            lappend tras [lindex $pair 1]
        }
    }

    set deltaSags 0 
    set deltaCors 0 
    set deltaTras 0 
    if {[llength $sags] == 2} {
        set deltaSags [expr [lindex $sags 1] - [lindex $sags 0]]
    }
    if {[llength $cors] == 2} {
        set deltaCors [expr [lindex $cors 1] - [lindex $cors 0]]
    }
    if {[llength $tras] == 2} {
        set deltaTras [expr [lindex $tras 1] - [lindex $tras 0]]
    }

    set SiemensMosaicReader(scanOrder) "IS"
    if {$deltaSags > 0} {
        set SiemensMosaicReader(scanOrder) "LR"
    }
    if {$deltaSags < 0} {
        set SiemensMosaicReader(scanOrder) "RL"
    }
    if {$deltaCors > 0} {
        set SiemensMosaicReader(scanOrder) "PA"
    }
    if {$deltaCors < 0} {
        set SiemensMosaicReader(scanOrder) "AP"
    }
    if {$deltaTras > 0} {
        set SiemensMosaicReader(scanOrder) "IS"
    }
    if {$deltaTras < 0} {
        set SiemensMosaicReader(scanOrder) "SI"
    }
} 
