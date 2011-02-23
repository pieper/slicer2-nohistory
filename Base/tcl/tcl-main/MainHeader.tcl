#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainHeader.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:54 $
#   Version:   $Revision: 1.39 $
# 
#===============================================================================
# FILE:        MainHeader.tcl
# PROCEDURES:  
#   ReadHeaderTcl  filname stdout aHeader
#   ReadHeader
#   ParsePrintHeader
#   ParseM3list
#   DumpHeader
#   GetHeaderInfo img1 num2 node tk
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC ReadHeaderTcl 
#
#  Opens an Image with a header and sets
#  Header(xDim yDim xSpacing ySpacing sliceThick sliceSpace  
#        littleEndian scalarSize rC aC sC rTL aTL sTL rTR aTR sTR rBR aBR sBR)
#
#  This corresponds to 
#     x_resolution y_resolution pixel_xsize pixel_ysize thick
#     space byte_order bytes_per_pixel coord_center_r coord_center_a
#     coord_center_s coord_r_top_left coord_a_top_left coord_s_top_left
#     coord_r_top_right coord_a_top_right coord_s_top_right
#     coord_r_bottom_right coord_a_bottom_right coord_s_bottom_right
#
#
# I've heard a rumor this might only work for MR, not CT
# This is only called on a linux based system.
#
#
# read the header info
# Only Need xDim, yDim
# xSpacing ySpacing zSpacing(sliceThick + sliceSpace)
# rC aC sC rTL aTL sTL rTR aTR rTR aTR sTR rBR aBR sBR
#
# need to have error message for no header
# only handles signa and genesis
# returns 1 on success 0 on failure
#
# .ARGS
# str filname   the name of the file
# num stdout    if 1, prints the information to standard output
# array aHeader The name of the array in which to put the information
# .END
#-------------------------------------------------------------------------------
proc ReadHeaderTcl { filename stdout aHeader} {
    global tcl_platform ReadHeader

    upvar $aHeader Header
        
    set f [open $filename r]
    
    ## Tcl doesn't handle floats well in binary strings.
    ## Need to know if we need to swapbytes

    if {$tcl_platform(byteOrder) == "littleEndian"} {
        set ReadHeader(SwapBytes) 1
    } else {
        set ReadHeader(SwapBytes) 0
    }

    set ReadHeader(stdout) $stdout

    ## decide whether or not to print
    proc PrintVar {name var} {
        global ReadHeader
        if {$ReadHeader(stdout) == 1} {
            puts "$name = $var"
        }
    }

    ## takes in a 4 byte string and swaps the order
    proc SwapBytesStr { str } {
        binary scan $str c1c1c1c1 b1 b2 b3 b4
        return [binary format c1c1c1c1 "$b4" "$b3" "$b2" "$b1" ]
    }

    proc getvar_from_file {filehandle offset length {ScanString ""}} {
        global ReadHeader
        seek $filehandle $offset start
        set var [read $filehandle $length]
        # Might Need to swap bytes for a float
        if {($ScanString == "f")&&($ReadHeader(SwapBytes) == 1)} {
            set var [SwapBytesStr $var]
        }
        
        if {[string length $ScanString] != 0} {
            binary scan $var $ScanString var2
            return $var2
        } else {
            return $var
        }
    }
    
    # define some header offsets
    set ihsize 156
    set p_suite 124
    set p_suite2 [expr $p_suite + 2]
    
    set SU_HDR_LEN 114
    set EX_HDR_LEN 1024
    set SE_HDR_LEN 1020
    set IM_HDR_LEN 1022
    
    set SU_HDR_START 0
    set EX_HDR_START $SU_HDR_LEN
    set SE_HDR_START [expr $EX_HDR_START+$EX_HDR_LEN]
    set IM_HDR_START [expr $SE_HDR_START+$SE_HDR_LEN]
    set IMG_HDR_START 0
    
    # define some variable-specific offsets
    
    set EX_ex_no 8
    set EX_patname 97
    set EX_patid 84
    set EX_ex_typ 305
    set EX_patage 122
    set EX_patsex 126
    set EX_hospname  10
    set EX_ex_desc 282
    
    set SE_se_actual_dt 16
    
    set SE_se_desc 20
    
    set MR_slthick 26

   # these two are misleading, they are NOT the NumX, NumY you would expect.
    set MR_dim_X 42
    set MR_dim_Y 46

    set MR_pixsize_X 50
    set MR_pixsize_Y 54
    set MR_dfov 34
    set MR_scanspacing 116
    set MR_loc 126
    
    # coordinate info
    
    set MR_ctr_R 130
    set MR_ctr_A 134
    set MR_ctr_S 138
    set MR_norm_R 142
    set MR_norm_A 146
    set MR_norm_S 150
    set MR_tlhc_R 154
    set MR_tlhc_A 158
    set MR_tlhc_S 162
    set MR_trhc_R 166
    set MR_trhc_A 170
    set MR_trhc_S 174
    set MR_brhc_R 178
    set MR_brhc_A 182
    set MR_brhc_S 186
    
    
    set t [read $f 4]
    if {[string compare $t "IMGF"] == 0} {
        puts "image_type_text = genesis"
    } else {
        puts "image_type_text = signa"
        return 0
    }

    # Genesis Data is always big Endian
    set Header(littleEndian) 0

    set variable_header_count [getvar_from_file $f $p_suite2 2 S*]

    set exam_offset  [expr $variable_header_count + $EX_HDR_START]
    set series_offset  [expr $variable_header_count + $SE_HDR_START]
    set image_offset [expr $variable_header_count + $IM_HDR_START]
    
    #patient name
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_patname] 25]
    PrintVar "patient_name" "$var"
    
    # patient id
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_patid]  13]
    PrintVar "patient_id" "$var"
    
    # exam number
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_ex_no] 2 S ]
    PrintVar "exam_number" "$var"
    
    #hospital
    
    set hn2 [getvar_from_file $f [expr $exam_offset+$EX_hospname] 33 a33 ]
    PrintVar "hospital_name" "$var"
    
    #exam description
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_ex_desc]  23 a23 ]
    PrintVar "exam_description" "$var"
    
    #series description
    
    set var [getvar_from_file $f [expr $series_offset+$SE_se_desc]  30 a30 ]
    PrintVar "series_description" "$var"
    
    # patient age
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_patage]  2 S]
    PrintVar "patient_age" "$var"
    
    # patient sex
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_patsex]  2 s ]
    if {$t == 2} {  PrintVar "patient_sex" "female" }
    if {$t == 1} {  PrintVar "patient_sex" "male"   }
    
    #date 
    set var [getvar_from_file $f [expr $series_offset+$SE_se_actual_dt]  4 I ]
    set tm [clock format $var]
    PrintVar "Clock" $tm
    
    #modality
    
    set var [getvar_from_file $f [expr $exam_offset+$EX_ex_typ]  3]
    PrintVar "modality" "$var"
    
    # slice thickness
    
    set var [getvar_from_file $f [expr $image_offset+$MR_slthick]  4 f ]
    PrintVar "thickness" "$var"
    set Header(sliceThick) $var    
    
    # spacing
    
    set var [getvar_from_file $f [expr $image_offset+$MR_scanspacing]  4 f]
    PrintVar "spacing" "$var"
    set Header(sliceSpace) $var    
    
    set Header(zSpacing) [expr $Header(sliceThick) + $Header(sliceSpace)]

     # number of x pixels

    set var [getvar_from_file $f  8  4 I]
    PrintVar "x_resolution" "$var"
    set Header(xDim) $var

    # number of y pixels

    set var [getvar_from_file $f  12  4 I]
    PrintVar "y_resolution" "$var"
    set Header(yDim) $var
    
    # pxel_X_size
    
    set var [getvar_from_file $f [expr $image_offset+$MR_pixsize_X]  4 f]
    PrintVar "pixel_x_size" "$var"
    set Header(xSpacing) $var
    
    # pixel_Y_size
    
    set var [getvar_from_file $f [expr $image_offset+$MR_pixsize_Y]  4 f]
    PrintVar "pixel_y_size" "$var"
    set Header(ySpacing) $var
    
    # fov
    
    set var [getvar_from_file $f [expr $image_offset+$MR_dfov]  4 f ]
    PrintVar "" "$var"
    
    # location
    
    set var [getvar_from_file $f [expr $image_offset+$MR_loc]  4 f]
    PrintVar "image_location" "$var"
    
    # coordinate info
    
    set var [getvar_from_file $f [expr $image_offset+$MR_ctr_R]  4 f ]
    PrintVar "coord_center_r" "$var"
    set Header(rC) $var

    set var [getvar_from_file $f [expr $image_offset+$MR_ctr_A]  4 f]
    PrintVar "coord_center_a" "$var"
    set Header(aC) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_ctr_S]  4 f]
    PrintVar "coord_center_s" "$var"
    set Header(sC) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_norm_R]  4 f]
    PrintVar "coord_normal_r" "$var"

    set var [getvar_from_file $f [expr $image_offset+$MR_norm_A]  4 f]
    PrintVar "coord_normal_a " "$var"
    
    set var [getvar_from_file $f [expr $image_offset+$MR_norm_S]  4 f]
    PrintVar "coord_normal_s " "$var"
    
    set var [getvar_from_file $f [expr $image_offset+$MR_tlhc_R]  4 f ]
    PrintVar "coord_r_top_left " "$var"
    set Header(rTL) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_tlhc_A]  4 f]
    PrintVar "coord_a_top_left " "$var"
    set Header(aTL) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_tlhc_S]  4 f]
    PrintVar "coord_s_top_left " "$var"
    set Header(sTL) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_trhc_R]  4 f]
    PrintVar "coord_r_top_right " "$var"
    set Header(rTR) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_trhc_A]  4 f]
    PrintVar "coord_a_top_right " "$var"
    set Header(aTR) $var

    set var [getvar_from_file $f [expr $image_offset+$MR_trhc_S] 4 f]
    PrintVar "coord_s_top_right " "$var"
    set Header(sTR) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_brhc_R] 4 f ]
    PrintVar "coord_r_bottom_right " "$var"
    set Header(rBR) $var

    set var [getvar_from_file $f [expr $image_offset+$MR_brhc_A]  4 f]
    PrintVar "coord_a_bottom_right " "$var"
    set Header(aBR) $var
    
    set var [getvar_from_file $f [expr $image_offset+$MR_brhc_S]  4 f]
    PrintVar "coord_s_bottom_right " "$var"
    set Header(sBR) $var

    close $f
    return 1
}
#-------------------------------------------------------------------------------
# .PROC ReadHeader
#
# Calls the print_header program.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ReadHeader {image run utility tk} {
    global Gui
    # Run a header reading utility
    if {$run == 1} {
        if {[file exists $utility] == 0 } {
            puts "ReadHeader: print_header ($utility) program not found."
            return ""
        }
        if {[catch {set hdr [exec $utility $image]} errmsg] == 1} {
            # correct return val is in errmsg on unix; on pc it's an error.
            if {$Gui(pc) == 1} {
            puts $errmsg
            if {$tk == 1} {
                tk_messageBox -icon error -message $errmsg
            }
            return ""
            } else {
            set hdr $errmsg
                        #puts $errmsg
            }
        }
    } else {
        set fid [open $utility]
        set hdr [read $fid]
        if {[catch {close $fid} errorMessage]} {
                    tk_messageBox -type ok -message "The following error occurred saving a file: ${errorMessage}"
                 puts "Aborting due to: ${errorMessage}"
                 exit 1
            }
    }
    return $hdr
}

#-------------------------------------------------------------------------------
# .PROC ParsePrintHeader
# Parses result from the print_header program
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ParsePrintHeader {text aHeader} {
    
    upvar $aHeader Header
    set text "$text\n"

    # These are comments
    # 'text' was read from the file
    # This routine parses 'text' to set variables in the Header array.
    # For each key, find it in the 'text', and set the corresponding
    # value in the array.
    #
    # fKey = the key in the file (text)
    # aKey = the key in the Header array

    set errmsg ""
    foreach  \
        fKey "x_resolution y_resolution pixel_xsize pixel_ysize thick space \
        byte_order bytes_per_pixel \
        coord_center_r coord_center_a coord_center_s \
        coord_r_top_left coord_a_top_left coord_s_top_left \
        coord_r_top_right coord_a_top_right coord_s_top_right \
        coord_r_bottom_right coord_a_bottom_right coord_s_bottom_right" \
        \
        aKey "xDim yDim xSpacing ySpacing sliceThick sliceSpace \
        littleEndian scalarSize \
        rC aC sC rTL aTL sTL rTR aTR sTR rBR aBR sBR" \
        {
        if {[regexp "$fKey \*= \*\(\[\^ \]\*\)\n" $text match item] == 1} {
            set Header($aKey) $item
        } else {
            set errmsg "$errmsg $fKey"
        }
    }
    if {$errmsg != ""} {
        set errmsg "Error reading header. Can't find:\n$errmsg"
        return $errmsg
    }

    set errmsg ""

    if {[catch { set Header(zSpacing) [expr $Header(sliceThick) + $Header(sliceSpace)] } errmsgTmp]} {
        lappend errmsg $errmsgTmp
    }

    # Not in print_header
    if {[catch { set Header(scalarType) Short } errmsgTmp]} {
        lappend errmsg $errmsgTmp
    }
    if {[catch { set Header(numScalars) 1 } errmsgTmp]} {
        lappend errmsg $errmsgTmp
    }
    if {[catch { set Header(sliceTilt) 0 } errmsgTmp]} {
        lappend errmsg $errmsgTmp
    }
    if {[catch { set Header(order) "" } errmsgTmp]} {
        lappend errmsg $errmsgTmp
    }


    if {$errmsg != ""} {
        set errmsg "Error reading header, missing a field:\n$errmsg"
    }
    return $errmsg
}

#-------------------------------------------------------------------------------
# .PROC ParseM3list
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ParseM3list {text aHeader} {

    upvar $aHeader Header

    # Little endian:
    # within a given 16- or 32-bit word, bytes at lower addresses have
    # lower significance (the word is stored `little-end-first').  The
    # PDP-11 and VAX families of computers and Intel microprocessors and
    # a lot of communications and networking hardware are little-endian
    if {[regexp {High Bit[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*([0-9\.-]*)[ ]*} \
        $text match x] == 1} {
        if {$x > 7} {
            set Header(littleEndian) 1
        } else {
            set Header(littleEndian) 0
        }
    }
    # Columns
    if {[regexp {Columns[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*([0-9\.-]*)[ ]*} \
        $text match x] == 1} {
        set Header(xDim) $x
    }
    # Rows
    if {[regexp {Rows[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*([0-9\.-]*)[ ]*} \
        $text match x] == 1} {
        set Header(yDim) $x
        set res $x
    }
    # Slice Thickness
    if {[regexp {Slice Thickness[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\[[ ]*([0-9\.-]*)[ ]*\]} \
        $text match x] == 1} {
        set Header(sliceThick) $x
    }
    # Space Btwn Slices
    # Note: CT does not have that
    if {[regexp {Space Btwn Slices[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\[[ ]*([0-9\.-]*)[ ]*\]} \
        $text match x] == 1} {
        set Header(sliceSpace) $x
    } else {
        set Header(sliceSpace) 0
    }
    # Pixel Size
    if {[regexp {Pixel Size[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\[[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)[ ]*\]} \
        $text match x y] == 1} {
        set Header(xSpacing) $x
        set Header(ySpacing) $y
        set pixel $x
    }
    # Orien(Patient)
    if {[regexp {Orien\(Patient\)[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\[[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)[ ]*\]} \
        $text match ir ia is jr ja js] == 1} {
    }
    # Image Pos(Patient)
    if {[regexp {Image Pos\(Patient\)[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\[[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)\\[ ]*([0-9\.-]*)[ ]*\]} \
        $text match or oa os] == 1} {
    }

    # Compute Corner points
    set fov [expr $pixel * $res * 1.0]
    set cr [expr 1.0*$or + ($ir + $jr) * $fov/2]
    set ca [expr 1.0*$oa + ($ia + $ja) * $fov/2]
    set cs [expr 1.0*$os + ($is + $js) * $fov/2]

    # center
    set Header(rC) $cr
    set Header(aC) $ca
    set Header(sC) $cs

    # top left
    set Header(rTL) $or
    set Header(aTL) $oa
    set Header(sTL) $os

    # top right
    set Header(rTR) [expr $or + $ir * $fov]
    set Header(aTR) [expr $oa + $ia * $fov]
    set Header(sTR) [expr $os + $is * $fov]

    # bottom right
    set Header(rBL) [expr $or + ($ir + $jr) * $fov]
    set Header(aBL) [expr $oa + ($ia + $ja) * $fov]
    set Header(sBL) [expr $os + ($is + $js) * $fov]

    set Header(zSpacing) [expr $Header(sliceThick) + $Header(sliceSpace)]

    # Not in print_header
    set Header(scalarType) Short
    set Header(numScalars) 1
    set Header(sliceTilt) 0
    set Header(order) ""

    return

    # dump for debugging
    puts "fov=$fov"
    puts "position = $or $oa $os"
    puts "orientation = $ir $ia $is, $jr $ja $js"
    puts "CENTER: $cr $ca $cs"
    puts "TOP-LEFT: $or $oa $os"
    puts "TOP-RIGHT: \
        [expr $or + $ir * $fov] \
        [expr $oa + $ia * $fov] \
        [expr $os + $is * $fov]"
    puts "BOT-RIGHT: \
        [expr $or + ($ir + $jr) * $fov] \
        [expr $oa + ($ia + $ja) * $fov] \
        [expr $os + ($is + $js) * $fov]"
}

#-------------------------------------------------------------------------------
# .PROC DumpHeader
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DumpHeader {aHeader} {
    upvar $aHeader Header
    foreach item [lsort [array names Header]] {
        puts "$item = '$Header($item)'"
    }
}

#-------------------------------------------------------------------------------
# .PROC GetHeaderInfo
# Return an error message if files don't exist, else empty list.
# .ARGS
# str img1 filename of an image
# int num2 the last image number in the volume
# vtkMrmlVolumeNode node the node in which to set the information
# int tk  if 1, an error message will popup a tk error window.
# .END
#-------------------------------------------------------------------------------
proc GetHeaderInfo {img1 num2 node tk} {
    global Mrml Path tcl_platform

    if {[CheckFileExists $img1 0] == 0} {
        return "Cannot open '$img1'."
    }

    # parse out the filename pattern etc from the image name, no afterstuff in pattern
    set parsing [MainFileParseImageFile $img1 0]
    if {$::Module(verbose) == 1} { 
        puts "GetHeaderInfo return from MainFileParseImageFile $parsing"
    }
    set filePattern    [lindex $parsing 0]
    set prefix [lindex $parsing 1]
    set num1   [lindex $parsing 2]

    if {$::Module(verbose) == 1} { 
        puts "GetHeaderInfo: filePattern $filePattern prefix $prefix num2 $num2"
    }

    # Compute the full path of the last image in the volume
    set img2 [format $filePattern $prefix $num2]
    if {[CheckFileExists $img2 0] == 0} {
        return "Cannot open '$img2'."
    } 
        
    # note the Zero in the line below - don't follow the
    # ReadHeaderTcl path, since it doesn't seem to work right
    # and we now have a linux version of print_header...
    if { 0 && $tcl_platform(os) == "Linux"} {
        
        if { [ReadHeaderTcl $img1 1 Header1] != 1} {
            DevErrorWindow "Error reading header in linux. Can only read Genesis Headers."
            return -1
        }
        if { [ReadHeaderTcl $img2 0 Header2] != 1} {
            DevErrorWindow "Error reading header in linux. Can only read Genesis Headers."
            return -1
        }
        
        ## numbers not in the header right now...
        ## we can get gantry tilt...
        set Header1(scalarType) Short
        set Header1(numScalars) 1
        set Header1(sliceTilt) 0
        set Header1(order) ""
        
    } else {
        # Read headers
        set hdr1 [ReadHeader $img1 1 $Path(printHeader) $tk]
        set hdr2 [ReadHeader $img2 1 $Path(printHeader) $tk]
        
        # exit if failed to read
        if {$hdr1 == ""} {
            return "-1"
        }
        
        # Parse headers
        set errmsg [ParsePrintHeader $hdr1 Header1]
        if {$::Module(verbose) == 1} { 
            puts "ParsePrintHeader 1 errors = $errmsg"
        }
        if {$errmsg != ""} {
            return $errmsg
        }
        set errmsg [ParsePrintHeader $hdr2 Header2]
        if {$::Module(verbose) == 1} { 
            puts "ParsePrintHeader 2 errors = $errmsg"
        }
        if {$errmsg != ""} {
            return $errmsg
        }
    }
    
    # Set the volume node's attributes using header info
    $node SetFilePrefix $prefix
    if {$::Module(verbose)} {
        puts "GetHeaderInfo: setting full prefix from mrml dir ($Mrml(dir)) and file prefix ([$node GetFilePrefix]) to [file join $Mrml(dir) [$node GetFilePrefix]]"
    }
    $node SetFullPrefix [file join $Mrml(dir) [$node GetFilePrefix]]
    $node SetFilePattern $filePattern
    $node SetImageRange $num1 $num2
    $node SetDimensions $Header1(xDim) $Header1(yDim)
    $node SetSpacing $Header1(xSpacing) $Header1(ySpacing) $Header1(zSpacing)
    $node SetScalarTypeTo$Header1(scalarType)
    $node SetNumScalars $Header1(numScalars)
    $node SetLittleEndian $Header1(littleEndian)
    $node SetTilt $Header1(sliceTilt)
    set result [$node ComputeRasToIjkFromCorners \
        $Header1(rC)  $Header1(aC)  $Header1(sC) \
        $Header1(rTL) $Header1(aTL) $Header1(sTL) \
        $Header1(rTR) $Header1(aTR) $Header1(sTR) \
        $Header1(rBR) $Header1(aBR) $Header1(sBR) \
        $Header2(rC)  $Header2(aC)  $Header2(sC) \
        $Header2(rTL) $Header2(aTL) $Header2(sTL)]
    # result should be -1 if header info bad/nonexistent

    # If description field is empty, then write the scan order
    if {[$node GetDescription] == ""} {
        $node SetDescription [$node GetScanOrder]
    }
    if {$result == 0} {
        return ""
    } else {
        return $result
    }
}
