#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainLuts.tcl,v $
#   Date:      $Date: 2006/07/06 18:25:16 $
#   Version:   $Revision: 1.24 $
# 
#===============================================================================
# FILE:        MainLuts.tcl
# PROCEDURES:  
#   MainLutsInit
#   MainLutsInit
#   MainLutsBuildLutForFMRI 
#   MainLutsBuildLutForFMRIPosActive
#   MainLutsBuildVTK
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainLutsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainLutsInit {} {
    global Module Lut

    # Define Procedures
    lappend Module(procVTK) MainLutsBuildVTK

    # Set version info
    lappend Module(versions) [ParseCVSInfo MainLuts \
    {$Revision: 1.24 $} {$Date: 2006/07/06 18:25:16 $}]

    # Create an ID for Labels
    set Lut(idLabel) -1

    set Lut(idList) " 0 1 2 3 4 5 6 7 8 $Lut(idLabel)"

    set Lut(0,name) Gray
    set Lut(0,fileName) ""
    set Lut(0,numberOfColors) 256
    set Lut(0,hueRange) "0 0"
    set Lut(0,saturationRange) "0 0"
    set Lut(0,valueRange) "0 1"
    # set Lut(0,annoColor) = Set color for Histogram 
    set Lut(0,annoColor) "1 0 0"

    set Lut(1,name) Iron
    set Lut(1,fileName) ""
    set Lut(1,numberOfColors) 156
    set Lut(1,hueRange) "0 .15"
    set Lut(1,saturationRange) "1 1"
    set Lut(1,valueRange) "1 1"
    set Lut(1,annoColor) "1 1 1"

    set Lut(2,name) Rainbow
    set Lut(2,fileName) ""
    set Lut(2,numberOfColors) 256
    set Lut(2,hueRange) "0 .8"
    set Lut(2,saturationRange) "1 1"
    set Lut(2,valueRange) "1 1"
    set Lut(2,annoColor) "1 1 1"

    set Lut(3,name) Ocean
    set Lut(3,fileName) ""
    set Lut(3,numberOfColors) 256
    set Lut(3,hueRange) "0.666667 0.5"
    set Lut(3,saturationRange) "1 1"
    set Lut(3,valueRange) "1 1"
    set Lut(3,annoColor) "0 0 1"
    
    set Lut(4,name) Desert
    set Lut(4,fileName) ""
    set Lut(4,numberOfColors) 256
    set Lut(4,hueRange) "0 0.1"
    set Lut(4,saturationRange) "1 1"
    set Lut(4,valueRange) "1 1"
    set Lut(4,annoColor) "0 0 1"

    set Lut(5,name) InvGray
    set Lut(5,fileName) ""
    set Lut(5,numberOfColors) 256
    set Lut(5,hueRange) "0 0"
    set Lut(5,saturationRange) "0 0"
    set Lut(5,valueRange) "1 0"
    set Lut(5,annoColor) "0 1 1"

    set Lut(6,name) ReverseRainbow
    set Lut(6,fileName) ""
    set Lut(6,numberOfColors) 256
    set Lut(6,hueRange) ".8 0"
    set Lut(6,saturationRange) "1 1"
    set Lut(6,valueRange) "1 1"
    set Lut(6,annoColor) "1 1 1"

    set Lut(7,name) FMRI 
    set Lut(7,fileName) ""
    set Lut(7,numberOfColors) 256 
    set Lut(7,annoColor) "1 1 0"

    set Lut(8,name) FMRIPosActive
    set Lut(8,fileName) ""
    set Lut(8,numberOfColors) 256 
    set Lut(8,annoColor) "1 1 1"

}


#-------------------------------------------------------------------------------
# .PROC MainLutsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainLutsGetLutIDByName {lutname} {

    foreach id $::Lut(idList) {
        if { $lutname == $::Lut($id,name) } {
            return $id
        }
    }
    return ""
}


#-------------------------------------------------------------------------------
# .PROC MainLutsBuildLutForFMRI 
# Creates a colormap for fMRI t volume. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainLutsBuildLutForFMRI {l} {
    global Lut

    # Use different numbers of table values for neg and pos
    # to make sure -1 is represented by blue

    # From green to blue 
    vtkLookupTable neg 
    neg SetNumberOfTableValues 23 
    neg SetHueRange 0.5 0.66667
    neg SetSaturationRange 1 1
    neg SetValueRange 1 1
    neg SetRampToLinear
    neg Build

    # From red to yellow
    vtkLookupTable pos 
    pos SetNumberOfTableValues 20 
    pos SetHueRange  0 0.16667
    pos SetSaturationRange 1 1
    pos SetValueRange 1 1
    pos SetRampToLinear
    pos Build

    Lut($l,lut) SetNumberOfTableValues 43 
    Lut($l,lut) SetRampToLinear
    Lut($l,lut) Build

    for {set i 0} {$i < 23} {incr i} {
        set c1 [neg GetTableValue $i] 
        Lut($l,lut) SetTableValue $i \
            [lindex $c1 0] [lindex $c1 1] [lindex $c1 2] [lindex $c1 3] 
    }
    for {set i 0} {$i < 20} {incr i} {
        set c2 [pos GetTableValue $i] 
        Lut($l,lut) SetTableValue [expr $i + 23] \
            [lindex $c2 0] [lindex $c2 1] [lindex $c2 2] [lindex $c2 3] 
    }
}



#-------------------------------------------------------------------------------
# .PROC MainLutsBuildLutForFMRIPosActive
# Creates a colormap for fMRI t volume showing postive activation. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainLutsBuildLutForFMRIPosActive {l} {
    global Lut

    # Use different numbers of table values for neg and pos
    # to make sure -1 is represented by blue

    # From red to yellow for positive values only
    vtkLookupTable posact
    posact SetNumberOfTableValues 20 
    posact SetHueRange  0 0.16667
    posact SetSaturationRange 1 1
    posact SetValueRange 1 1
    posact SetRampToLinear
    posact Build

    Lut($l,lut) SetNumberOfTableValues 20
    Lut($l,lut) SetRampToLinear
    Lut($l,lut) Build

    for {set i 0} {$i < 20} {incr i} {
        set c2 [posact GetTableValue $i] 
        Lut($l,lut) SetTableValue [expr $i ] \
            [lindex $c2 0] [lindex $c2 1] [lindex $c2 2] [lindex $c2 3] 
    }
}

 
#-------------------------------------------------------------------------------
# .PROC MainLutsBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainLutsBuildVTK {} {
    global Volume Lut Dag

    foreach l $Lut(idList) {
        if {$l >= 0} {
            # Hue, Saturation, Intensity
            if {$Lut($l,fileName) == ""} {
            
                vtkLookupTable Lut($l,lut)
                if { $l < 7 } {
                    foreach param "NumberOfColors HueRange SaturationRange ValueRange" {
                        eval Lut($l,lut) Set${param} $Lut($l,[Uncap ${param}])
                    }
                    # sp - 2002-11-11 changed default SCurve to Linear to improve
                    # fidelity of image display
                    Lut($l,lut) SetRampToLinear
                    Lut($l,lut) Build
                }
                if { $l == 7 } {
                    MainLutsBuildLutForFMRI $l
                }
                if { $l == 8 } {
                    MainLutsBuildLutForFMRIPosActive $l
                }
            
            # File
            } else {
                vtkLookupTable Lut($l,lut)

                # Open palette file
                set filename $Lut($l,fileName)
                if {[CheckFileExists $filename] == 0} {
                    puts "Cannot open file '$filename'"
                    return
                }
                set fid [open $filename r]

                # Read colors represented by 3 numbers (RGB) on a line
                set numColors 0
                gets $fid line
                while {[eof $fid] == "0"} {
                    if {[llength $line] == 3} {
                        set colors($numColors) $line
                        incr numColors
                    }
                    gets $fid line
                }
                if {[catch {close $fid} errorMessage]} {
                    tk_messageBox -type ok -message "The following error occurred saving a file: ${errorMessage}" 
                    puts "Aborting due to : ${errorMessage}"
                    exit 1
                }

                # Set colors into the Lut
                set Lut($l,numberOfColors) $numColors
                Lut($l,lut) SetNumberOfTableValues $Lut($l,numberOfColors)
                Lut($l,lut) SetNumberOfColors $Lut($l,numberOfColors)
                for {set n 0} {$n < $numColors} {incr n} {
                    eval Lut($l,lut) SetTableValue $n $colors($n) 1
                }
            }
        }
    }

    # Add a lut for Labels
    #--------------------------------------

    # Give it a name
    set l $Lut(idLabel)
    set Lut($l,name) "Label"
    set Lut($l,annoColor) "1.0 1.0 0.5"

    # Make a LookupTable, vtkIndirectLookupTable
    vtkLookupTable Lut($l,lut)

    vtkIndirectLookupTable Lut($l,indirectLUT)
    Lut($l,indirectLUT) DirectOn
    Lut($l,indirectLUT) SetLowerThreshold 1
    Lut($l,indirectLUT) SetLookupTable Lut($l,lut)
}
