#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Save.tcl,v $
#   Date:      $Date: 2006/04/18 22:05:06 $
#   Version:   $Revision: 1.19 $
# 
#===============================================================================
# FILE:        Save.tcl
# PROCEDURES:  
#   SaveInit
#   SaveInit
#   SaveInitTables
#   SaveWindowToFile directory filename imageType window
#   SaveWindowToFile
#   SaveRendererToFile directory filename imageType mag window
#   SaveImageToFile directory filename imageType image
#   SaveGetFilename directory filename imageType
#   SaveGetExtensionForImageType imageType
#   SaveGetExtensionForImageType
#   SaveGetImageType imageType
#   SaveGetImageType
#   SaveGetSupportedImageTypes
#   SaveGetSupportedExtensions
#   SaveGetAllSupportedExtensions
#   SaveChooseDirectory
#   SaveDisplayOptionsWindow
#   SaveModeIsMovie
#   SaveModeIsMovie
#   SaveModeIsStereo
#   SaveModeIsSingleView
#   SaveGetFileBase
#   SaveGetFileBase
#   SaveIncrementFrameCounter
#   Save3DImage
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC SaveInit
# 
# Register the module with slicer and set up.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SaveInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveInit {} {
    global Save
    set m "Save"

    set Module($m,depend) ""
    set Module($m,overview) "Image and Window file saving routines"
    set Module($m,author) "Michael Halle, SPL"

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
            {$Revision: 1.19 $} {$Date: 2006/04/18 22:05:06 $}]

    SaveInitTables

    set Save(imageDirectory) "/tmp"
    set Save(imageFilePrefix) "slicer-"
    set Save(imageFrameCounter) 1
    set Save(imageFileType) PNG
    set Save(imageSaveMode) "Single view"
    set Save(imageOutputZoom) 1
    set Save(imageIncludeSlices) 0
    set Save(stereoDisparityFactor) 1.0

    set Save(movieDirectory) "/tmp"
    set Save(moviePattern) "slicer-*.png"
    set Save(movieStartFrame) 1
    set Save(movieEndFrame) 1
    
}

#-------------------------------------------------------------------------------
# .PROC SaveInitTables
#  Initialize the type tables.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveInitTables {} {
    upvar \#0  SaveExtensionToImageTypeMap imtype

    set imtype(ps)   "Postscript"
    set imtype(eps)  "Postscript"
    set imtype(prn)  "PostScript"
    set imtype(tif)  "TIFF"
    set imtype(tiff) "TIFF"
    set imtype(ppm)  "PNM"
    set imtype(pnm)  "PNM"
    set imtype(png)  "PNG"
    set imtype(bmp)  "BMP"
    set imtype(jpg)  "JPEG"
    set imtype(jpeg) "JPEG"

    upvar \#0 SaveImageTypeToExtensionMap ext

    # list of supported extensions, with preferred extension first.
    set ext(BMP)  "bmp"
    set ext(JPEG) {"jpg" "jpeg"}
    set ext(PNG)  "png"
    set ext(PNM)  {"ppm" "pnm"}
    set ext(PostScript) {"ps" "eps" "prn"}
    set ext(TIFF) {"tif" "tiff"}

}
#-------------------------------------------------------------------------------
# .PROC SaveWindowToFile
# 
# Saves a given window to a file of the given name.  The filename 
# should not include an image type;  the appropriate type for the
# files imageType will be appended.  If no window is given, the main
# 3D window will be saved.  
#
#
# .ARGS
# str directory Directory containing file;  if empty no directory is added.
# str filename Filename to save image to (see SaveGetFilename).
# str imageType Type of image to save (see SaveGetFilename).
# str window Name of window to save, defaults to viewWin.
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SaveWindowToFile
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveWindowToFile {directory filename imageType {window ""}} {
    global viewWin
    if {"$window" == ""} {
        set window $viewWin
    }

    vtkWindowToImageFilter saveFilter
    saveFilter SetInput $window
    SaveImageToFile $directory $filename $imageType [saveFilter GetOutput]
    saveFilter Delete
}

#-------------------------------------------------------------------------------
# .PROC SaveRendererToFile
# 
# Saves a given renderer's image to a file of the given name.  The filename 
# should not include an image type;  the appropriate type for the
# files imageType will be appended.  If no window is given, the main
# 3D window will be saved.  The image can be magnified when output
# to produce a larger, higher-quality image for publication.
#
#
# .ARGS
# str directory Directory containing file;  if empty no directory is added.
# str filename Filename to save image to (see SaveGetFilename).
# str imageType Type of image to save (see SaveGetFilename).
# int mag Magnification of the image (uses vtkRenderLargeImage).
# str window Name of window to save, defaults to viewWin.
# .END
#-------------------------------------------------------------------------------
proc SaveRendererToFile {directory filename imageType {mag 1} {renderer ""}} {
    global viewWin
    if {"$renderer" == ""} {
        set renderer viewRen
    }

    set renwin [$renderer GetRenderWindow]

    if {$mag == 1} {
        # one-to-one magnification, simplify
        SaveWindowToFile $directory $filename $imageType $renwin
    } else {
        set magImage [SaveGetMagnifiedImage $renderer $mag]
        SaveImageToFile $directory $filename $imageType $magImage

        # re-render scene in normal mode
        $renwin Render
    }
}


#-------------------------------------------------------------------------------
# .PROC SaveGetMagnifiedImage
# Return an image rendered from the renderer at the specified magnification
# .ARGS
# vtkRenderer ren the renderer
# int mag magnification
# .END
#-------------------------------------------------------------------------------
proc SaveGetMagnifiedImage {ren mag} {
    # render image in pieces using vtkRenderLargeImage

    if {[info command saveLargeImage] != ""} {
        catch "saveLargeImage Delete"
    }
    vtkRenderLargeImage saveLargeImage
    saveLargeImage SetMagnification $mag
    saveLargeImage SetInput $ren
    return [saveLargeImage GetOutput]
}

#-------------------------------------------------------------------------------
# .PROC SaveImageToFile
# 
# Saves a given image to a file of the given name.  The filename 
# should not include an image type;  the appropriate type for the
# files imageType will be appended.  
#
#
# .ARGS
# str directory Directory containing file;  if empty no directory is added.
# str filename Filename to save image to (see SaveGetFilename).
# str imageType Type of image to save (see SaveGetFilename).
# str image The image to save.
# .END
#-------------------------------------------------------------------------------
proc SaveImageToFile {directory filename imageType image} {
    if {$imageType == ""} {
        set newImageType [SaveGetImageType $filename]
    } else {
        set newImageType [SaveGetImageType $imageType]  
    }

    if {"$newImageType" == ""} {
        error "unknown type for image $imageType"
    }
    set imageType $newImageType

    set filename [SaveGetFilename $directory $filename $imageType]
    vtk${imageType}Writer saveWriter
    if {"$imageType" == "JPEG"} {
        # if progressive is on, solaris xv can't read the jpg file
        saveWriter ProgressiveOff
    }
    saveWriter SetInput $image
    saveWriter SetFileName $filename
    saveWriter Write
    saveWriter Delete
}

#-------------------------------------------------------------------------------
# .PROC SaveGetFilename
# 
# Returns the complete path+filebase+extension for a given filename.
#
#
# .ARGS
# str directory Directory containing file;  if empty no directory is added.
# str filename Filename to save image to.  If it has no extension, an appropriate one will be added.

# str imageType Type of image to save (BMP, JPEG, PNG, PNM, PostScript, TIFF). If empty, image type will be determined from the filename
# .END
#-------------------------------------------------------------------------------
proc SaveGetFilename {directory filename {imageType ""}} {
    global SaveImageTypeToExtensionMap SaveExtensionToImageTypeMap

    if {$imageType == ""} {
        set newImageType [SaveGetImageType $filename]
        if {"$newImageType" == ""} {
            error "unknown type for image $imageType"
        }
        set imageType $newImageType
    } else {
        #explicit image type, add extension (if different)
        set imageType [SaveGetImageType $imageType]
        set ext [lindex $SaveImageTypeToExtensionMap($imageType) 0]
        set curExt [string tolower [string range [file extension $filename] 1 end]]
        if {"$ext" != "$curExt"} {
            set filename [format "%s.%s" $filename $ext]
        }
    }
    
    if {"$directory" != ""} {
        set filename [file join $directory $filename]
    }

    return $filename
}

#-------------------------------------------------------------------------------
# .PROC SaveGetExtensionForImageType
# 
# Returns the appropriate file extension (no ".") for a given image type.
#
# .ARGS
# str imageType Type of image.
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SaveGetExtensionForImageType
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveGetExtensionForImageType {imageType} {
    global SaveExtensionToImageTypeMap
    if {[info exists SaveImageTypeToExtensionMap($imageType)]} {
        return [lindex $SaveImageTypeToExtensionMap($imageType) 0]
    }
    return ""
}
#-------------------------------------------------------------------------------
# .PROC SaveGetImageType
# 
# Returns the canonical image type given a filename, file extension,
# or image type.  Only supported image types are returned; if an image
# type isn't supported, the empty string is returned.
#
# .ARGS
# str imageType the image type, filename, or file extension (with or without .)
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SaveGetImageType
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveGetImageType {imageTypeOrExt} {
    global SaveImageTypeToExtensionMap SaveExtensionToImageTypeMap
    # try the most straightforward map

    if {[info exists SaveImageTypeToExtensionMap($imageTypeOrExt)]} {
        return $imageTypeOrExt
    }

    # if not, see if we were handed an extension (or filename w/extension) instead
    set ext [file extension $imageTypeOrExt]
    
    if {"$ext" == ""} {
        # could be the extension, no "."
        set ext $imageTypeOrExt
    } else {
        set ext [string tolower [string range  $ext 1 end]]
    }

    if {[info exists SaveExtensionToImageTypeMap($ext)]} { 
        return $SaveExtensionToImageTypeMap($ext)
    }

    # no luck
    return ""
}

#-------------------------------------------------------------------------------
# .PROC SaveGetSupportedImageTypes
# 
#  Return a list of supported image types for saving.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveGetSupportedImageTypes {} {
    global SaveImageTypeToExtensionMap
    return [lsort [array names SaveImageTypeToExtensionMap]]
}

#-------------------------------------------------------------------------------
# .PROC SaveGetSupportedExtensions
# 
#  Return a list of primary extensions that correspond to supported image types
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveGetSupportedExtensions {} {
    global SaveExtensionToImageTypeMap SaveImageTypeToExtensionMap

    foreach i [array names SaveImageTypeToExtensionMap] {
        lappend e [lindex $SaveImageTypeToExtensionMap($i) 0]
    }
    return [lsort $e]
}

#-------------------------------------------------------------------------------
# .PROC SaveGetAllSupportedExtensions
# 
#  Return a list of all extensions that correspond to supported image types
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveGetAllSupportedExtensions {} {
    global SaveExtensionToImageTypeMap
    return [lsort [array names SaveExtensionToImageTypeMap]]
}

#-------------------------------------------------------------------------------
# .PROC SaveChooseDirectory
# 
#  Internal function used to select the Save directory.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveChooseDirectory {} {
    global View Save
    set newdir [tk_chooseDirectory -initialdir $Save(imageDirectory)]
    puts "$newdir"
    if {"$newdir" != ""} {
        set Save(imageDirectory) $newdir
    }
}

#-------------------------------------------------------------------------------
# .PROC SaveDisplayOptionsWindow
# 
#  Displays a floating dialog box that allows image saving parameters to
#  be modified.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveDisplayOptionsWindow {{toplevelName .saveOptions}} {
    global Save Gui
    if {[winfo exists $toplevelName]} {
        wm deiconify $toplevelName
        raise $toplevelName
        return
    }
    set root [toplevel $toplevelName]
    wm title $root "Save 3D View Options"

    set f [frame $root.fSaveOptions -relief flat -border 2]
    pack $f -fill both -expand true
    GuiApplyStyle WFA $f

    grid [tkSpace $f.space20 -height 5] -columnspan 2

    label $f.lSaveMode -text "Save Mode:"
    eval tk_optionMenu $f.mbSaveMode Save(imageSaveMode) {"Single view" "Stereo pair" "Movie"}
    GuiApplyStyle WMBA $f.mbSaveMode
    $f.mbSaveMode config -pady 3
    GuiApplyStyle WMA $f.mbSaveMode.menu


    grid $f.lSaveMode $f.mbSaveMode -sticky w
    grid $f.lSaveMode -sticky e -padx $Gui(pad)
    GuiApplyStyle WLA $f.lSaveMode

    #
    # File Options
    #

    grid [tkHorizontalLine $f.line0] -columnspan 2 -pady 5 -sticky we

    label $f.lFileOptionsTitle -text "File Options"
    GuiApplyStyle WTA $f.lFileOptionsTitle
    grid $f.lFileOptionsTitle -sticky w -columnspan 2
    grid [tkSpace $f.space0 -height 5] -columnspan 2

    label $f.lDir -text "Directory:"
    GuiApplyStyle WLA $f.lDir

    entry $f.eDir -width 16 -textvariable Save(imageDirectory)
    GuiApplyStyle WEA $f.eDir

    grid $f.lDir $f.eDir -sticky w
    grid config $f.lDir -sticky e -padx $Gui(pad)

    button $f.bChooseDir -text "Browse..." -command SaveChooseDirectory
    GuiApplyStyle WBA $f.bChooseDir
    grid [tkSpace $f.space3] $f.bChooseDir -sticky w 

    grid [tkSpace $f.space4 -height 5] -columnspan 2

    label $f.lPrefix -text "File prefix:"
    GuiApplyStyle WLA $f.lPrefix
    entry $f.ePrefix -width 16 -textvariable Save(imageFilePrefix)
    GuiApplyStyle WEA $f.ePrefix

    grid $f.lPrefix $f.ePrefix -sticky w  -pady $Gui(pad)
    grid config $f.lPrefix -sticky e  -padx $Gui(pad)

    label $f.lFrame -text "Next frame #:"
    GuiApplyStyle WLA $f.lFrame
    entry $f.eFrame -width 6 -textvariable Save(imageFrameCounter)
    GuiApplyStyle WEA $f.eFrame

    grid $f.lFrame $f.eFrame -sticky w  -pady $Gui(pad)

    grid config $f.lFrame -sticky e  -padx $Gui(pad)

    label $f.lFileType -text "File type:"
    GuiApplyStyle WLA $f.lFileType
    eval tk_optionMenu $f.mbFileType Save(imageFileType) [SaveGetSupportedImageTypes]
    GuiApplyStyle WMBA $f.mbFileType
    $f.mbFileType config -pady 3
    GuiApplyStyle WMA $f.mbFileType.menu

    grid $f.lFileType $f.mbFileType -sticky w  -pady $Gui(pad)
    grid config $f.lFileType -sticky e  -padx $Gui(pad)

    #
    # Save Options
    #

    grid [tkHorizontalLine $f.line1] -columnspan 2 -pady 5 -sticky we

    label $f.lSaveTitle -text "Save Options" -anchor w
    grid $f.lSaveTitle -sticky news -columnspan 1
    GuiApplyStyle WTA $f.lSaveTitle

    label $f.lScale -text "Output zoom:"
    GuiApplyStyle WLA $f.lScale
    $f.lScale config -anchor sw

    eval scale $f.sScale -from 1 -to 8 -orient horizontal \
        -variable Save(imageOutputZoom) $Gui(WSA) -showvalue true

    TooltipAdd $f.sScale "Renders the image in multiple pieces toproduce a higher resolution image (useful for publication)." 
    grid $f.lScale $f.sScale -sticky w 
    grid $f.lScale -sticky sne -ipady 10  -padx $Gui(pad)

    label $f.lStereo -text "Stereo disparity:"
    GuiApplyStyle WLA $f.lStereo
    entry $f.eStereo -width 6 -textvariable Save(stereoDisparityFactor)
    GuiApplyStyle WEA $f.eStereo

    TooltipAdd $f.eStereo "Changes the disparity (apparent depth) of the stereo image by this scale factor."

    grid $f.lStereo $f.eStereo -sticky w   -pady $Gui(pad)
    grid $f.lScale $f.lStereo -sticky e  -padx $Gui(pad)

    checkbutton $f.cIncludeSlices -text "Include slice windows" -indicatoron 1 -variable Save(imageIncludeSlices)
    GuiApplyStyle WCA $f.cIncludeSlices
    grid $f.cIncludeSlices -sticky we -columnspan 2

    #
    # Review a saved movie
    #
    grid [tkHorizontalLine $f.line2] -columnspan 2 -pady 5 -sticky we

    label $f.lMovieTitle -text "View Movie Options" -anchor w
    GuiApplyStyle WTA $f.lMovieTitle
    grid $f.lMovieTitle -sticky news -columnspan 1
    grid [tkSpace $f.spacem0 -height 5] -columnspan 2


    label $f.lMovieDir  -text "Directory:"
    GuiApplyStyle WLA $f.lMovieDir
    entry $f.eMovieDir  -width 16 -textvariable Save(movieDirectory)
    GuiApplyStyle WEA $f.eMovieDir
    grid $f.lMovieDir $f.eMovieDir -sticky w
    grid config $f.lMovieDir -sticky e -padx $Gui(pad)

    button $f.bChooseMovieDir -text "Browse..." -command SaveMovieDirectory
    GuiApplyStyle WBA $f.bChooseMovieDir
    grid [tkSpace $f.spaceMovieDir] $f.bChooseMovieDir -sticky w 
    grid [tkSpace $f.spaceAfterMovieDir -height 5] -columnspan 2

    label $f.lMoviePattern -text "File pattern:"
    GuiApplyStyle WLA $f.lMoviePattern
    TooltipAdd $f.lMoviePattern "A regular expression describing the files to view"

    entry $f.eMoviePattern -width 16 -textvariable Save(moviePattern)
    GuiApplyStyle WEA $f.eMoviePattern

    grid $f.lMoviePattern $f.eMoviePattern -sticky w
    grid config $f.lMoviePattern -sticky e -padx $Gui(pad)


    label $f.lMovieStartFrame -text "Start frame:"
    GuiApplyStyle WLA $f.lMovieStartFrame
    entry $f.eMovieStartFrame -width 6 -textvariable Save(movieStartFrame)
    GuiApplyStyle WEA $f.eMovieStartFrame
    grid $f.lMovieStartFrame $f.eMovieStartFrame -sticky w
    grid config $f.lMovieStartFrame -sticky e -padx $Gui(pad)
    TooltipAdd $f.lMovieStartFrame "Number in the file name on which to start playback"

    label $f.lMovieEndFrame -text "End frame:"
    GuiApplyStyle WLA $f.lMovieEndFrame
    entry $f.eMovieEndFrame -width 6 -textvariable Save(movieEndFrame)
    GuiApplyStyle WEA $f.eMovieEndFrame
    grid $f.lMovieEndFrame $f.eMovieEndFrame -sticky w
    grid config $f.lMovieEndFrame -sticky e -padx $Gui(pad)
    TooltipAdd $f.lMovieEndFrame "Number in the file name on which to end playback"

    button $f.bMovieReview -text "View" -command "SaveMovieReview"
    GuiApplyStyle WBA $f.bMovieReview
    grid $f.bMovieReview -sticky we -padx $Gui(pad) -pady $Gui(pad) -ipadx 2 -ipady 5

    #
    # Buttons
    # 
    grid [tkHorizontalLine $f.line10] -columnspan 2 -pady 5 -sticky we
    grid [tkSpace $f.space2 -height 10] -columnspan 2
    button $f.bCloseWindow -text "Close" -command "destroy $root"
    button $f.bSaveNow     -text "Save View Now" -command "Save3DImage"
    GuiApplyStyle WBA $f.bSaveNow $f.bCloseWindow
    grid $f.bCloseWindow $f.bSaveNow -sticky we -padx $Gui(pad) -pady $Gui(pad) -ipadx 2 -ipady 5

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 1
    grid columnconfigure $f 2 -weight 1

    return $root
}

#-------------------------------------------------------------------------------
# .PROC SaveModeIsMovie
# 
#  Returns 1 if the current save mode is movie mode, 0 otherwise.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SaveModeIsMovie
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveModeIsMovie {} {
    global Save
    return [expr {"$Save(imageSaveMode)" == "Movie"}]
}

#-------------------------------------------------------------------------------
# .PROC SaveModeIsStereo
# 
#  Returns 1 if the current save mode is stereo pair mode, 0 otherwise.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveModeIsStereo {} {
    global Save
    return [expr {"$Save(imageSaveMode)" == "Stereo pair"}]
}

#-------------------------------------------------------------------------------
# .PROC SaveModeIsSingleView
# 
#  Returns 1 if the current save mode is single view mode, 0 otherwise.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveModeIsSingleView {} {
    global Save
    return [expr {"$Save(imageSaveMode)" == "Single view"}]
}

#-------------------------------------------------------------------------------
# .PROC SaveGetFileBase
# 
#  Returns the image file base name, checking to see if the frame number
#  is really a number.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC SaveGetFileBase
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveGetFileBase {} {
    global Save
    if {! [ValidateInt $Save(imageFrameCounter)]} {
        return $Save(imageFilePrefix)
    } else {
        return [format "%s%04d" $Save(imageFilePrefix) $Save(imageFrameCounter)]
    }
}

#-------------------------------------------------------------------------------
# .PROC SaveIncrementFrameCounter
# 
#  If the frame counter is an int, increment it.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveIncrementFrameCounter {} {
    global Save
    if {[ValidateInt $Save(imageFrameCounter)]} {
        incr Save(imageFrameCounter)
    }
}

#-------------------------------------------------------------------------------
# .PROC Save3DImage
# 
#  Save the main viewer window using the current Save image options.
#  This function will be called automatically in movie mode, when the
#  "Save View Now" button is pressed, or when "Control-s" is pressed
#  over the view window.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Save3DImage {} {
    global Save Slice viewWin Gui

    set filebase [SaveGetFileBase]
    set filename [SaveGetFilename $Save(imageDirectory) \
                      $filebase $Save(imageFileType)]

    $Gui(fViewer) config -cursor watch
    if { [SaveModeIsSingleView] || [SaveModeIsMovie] } {

        if { $Save(imageIncludeSlices) == 0} {
            # no slices, just 3D image
            SaveRendererToFile $Save(imageDirectory) $filebase \
                $Save(imageFileType) $Save(imageOutputZoom) viewRen
            
        } else { 
            # save slices too

            # zoomed slices only works after vtk version 5.0
            if {$::SLICER(VTK_VERSION) < 5.0} {
                set imageOutputZoom 1
                if {$Save(imageOutputZoom) > 1} {
                    puts "WARNING: zooming of slice windows doesn't work, needs VTK 5+. Saving view unzoomed with slice windows."
                }
            } else {
                set imageOutputZoom $Save(imageOutputZoom)
            }

            # first append the 3 slices horizontally

            vtkImageAppend imAppendSl
            imAppendSl SetAppendAxis 0
            foreach s $Slice(idList) {
                if {$imageOutputZoom == 1} {
                    vtkWindowToImageFilter IFSl$s
                    IFSl$s SetInput sl${s}Win
                    imAppendSl AddInput [IFSl$s GetOutput]
                    set sliceWindowWidth 256
                } else {
                    imAppendSl AddInput [SaveGetMagnifiedImage sl${s}Imager $imageOutputZoom]
                    set sliceWindowWidth [expr 256 * $imageOutputZoom]
                }
            }
            
            set w [expr [winfo width .tViewer] * $imageOutputZoom]
            # translate if viewer width is bigger
            vtkImageTranslateExtent imTrans
            imTrans SetTranslation [expr ($w - 768*$imageOutputZoom)/2] 0 0
            imTrans SetInput [imAppendSl GetOutput]
            #pad them with the width of the viewer
            vtkImageConstantPad imPad
            imPad SetInput [imTrans GetOutput]
            imPad SetOutputWholeExtent 0 $w 0 $sliceWindowWidth 0 0
            
            
            # then append the image of the 3 slices to the viewWin screen
            # vertically
            vtkImageAppend imAppendAll
            imAppendAll SetAppendAxis 1
            if {$imageOutputZoom == 1} {
                vtkWindowToImageFilter IFVW
                IFVW SetInput $viewWin
                imAppendAll AddInput [imPad GetOutput]
                imAppendAll AddInput [IFVW GetOutput]
            } else {
                set zoomedViewerWindow [SaveGetMagnifiedImage viewRen $imageOutputZoom]
                imAppendAll AddInput [imPad GetOutput]
                imAppendAll AddInput $zoomedViewerWindow
            }

            SaveImageToFile $Save(imageDirectory) $filebase \
                $Save(imageFileType) [imAppendAll GetOutput]

            imAppendSl Delete
            imAppendAll Delete
            if {$imageOutputZoom == 1} {
                IFVW Delete
                IFSl0 Delete
                IFSl1 Delete
                IFSl2 Delete
            }
            imPad Delete
            imTrans Delete
        }
    } elseif { [SaveModeIsStereo] } {
        global viewWin

        catch {stereoPairImage Delete}
        catch {stereoImage_left Delete}
        catch {stereoImage_right Delete}

        set renderer viewRen
        set window   $viewWin

        set cam [$renderer GetActiveCamera]
        set savecam [::SimpleStereo::formatCameraParams $cam]
    
        set views {right left}

        vtkImageAppend stereoPairImage
        stereoPairImage SetAppendAxis 0

        set disparity [expr {30.0/$Save(stereoDisparityFactor)}]
        set magnification $Save(imageOutputZoom)
        foreach v $views {
            ::SimpleStereo::moveCameraToView viewRen $v $disparity
            set image stereoImage_${v}
            
            if {$magnification == 1} {
                Render3D
                vtkWindowToImageFilter $image
                $image SetInput $window
            } else {
                vtkRenderLargeImage $image
                $image SetMagnification $magnification
                $image SetInput $renderer
            }
            $image Update
            stereoPairImage AddInput [$image GetOutput]
            ::SimpleStereo::restoreCameraParams $cam $savecam
        }

        SaveImageToFile $Save(imageDirectory) $filebase \
            $Save(imageFileType) [stereoPairImage GetOutput]

        Render3D
        stereoPairImage Delete
        stereoImage_left Delete
        stereoImage_right Delete
    }

    after idle "puts \"Saved $filename.\""
    $Gui(fViewer) config -cursor {}
    SaveIncrementFrameCounter
}

#-------------------------------------------------------------------------------
# .PROC SaveMovieDirectory
# 
#  Internal function used to select the movie review directory, that contains files
# that make up frames of a movie.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveMovieDirectory {} {
    global View Save
    set newdir [tk_chooseDirectory -initialdir $Save(movieDirectory)]
    if {"$newdir" != ""} {
        set Save(movieDirectory) $newdir
    }
}

#-------------------------------------------------------------------------------
# .PROC SaveMovieReview
# 
#  Pop up an isframes window to render the saved frames.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SaveMovieReview {} {
    global Save
    if { [catch "package require iSlicer"] } {
        DevErrorWindow "Cannot review movies without the iSlicer module, use QuickTime Pro to concatenate your files into a movie."
        return
    }
    if {$::Module(verbose)} {
        puts "Sending file pattern: [file join $Save(movieDirectory) $Save(moviePattern)]"
    }
    # subtract one from the input frames to get the 0-(n-1) range that isframes expects
    isframes_showMovie [file join $Save(movieDirectory) $Save(moviePattern)] [expr $Save(movieStartFrame) - 1] [expr $Save(movieEndFrame) - 1]
}
