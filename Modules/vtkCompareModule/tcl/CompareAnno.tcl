#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CompareAnno.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:22 $
#   Version:   $Revision: 1.2 $
# 
#===============================================================================
# FILE:        CompareAnno.tcl
# PROCEDURES:  
#   CompareAnnoInit
#   CompareAnnoBuildGUI
#   CompareAnnoSetVisibility
#   CompareAnnoSetCrossVisibility
#   CompareAnnoSetCrossIntersect
#   CompareAnnoSetHashesVisibility
#   CompareAnnoStorePresets
#   CompareAnnoRecallPresets
#==========================================================================auto=

# TODO : manage presets

#-------------------------------------------------------------------------------
# .PROC CompareAnnoInit
# Set CompareAnno array to the proper initial values
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoInit {} {
    global Module CompareAnno Gui

    # Define Procedures
    #lappend Module(procStorePresets) CompareAnnoStorePresets
    #lappend Module(procRecallPresets) CompareAnnoRecallPresets
    # Preset Defaults
    #set Module(CompareAnno,presets) "cross='1' crossIntersect='1' hashes='0'"

    # Cursor display
    #---------------------------------------------
    set CompareAnno(cross) 1
    set CompareAnno(crossIntersect) 0
    set CompareAnno(hashes) 1
    set CompareAnno(cursorMode) RAS

    # Cursor anno: pixel display fromat
    #---------------------------------------------
    set CompareAnno(pixelDispFormat) %.f
    # The display format of pixel for background and foreground
    # could be different.
    set CompareAnno(backPixelDispFormat) $CompareAnno(pixelDispFormat)
    set CompareAnno(forePixelDispFormat) $CompareAnno(pixelDispFormat)

    # Anno: font and color
    #---------------------------------------------
    if {$Gui(smallFont) == 0} {
        set CompareAnno(fontSize) 16
    } else {
        set CompareAnno(fontSize) 14
    }
    set CompareAnno(color) "1 1 0.5"

    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    set CompareAnno(mouseList) "cur1 cur2 cur3 msg curBack curFore"
    set CompareAnno(y256) "237 219 201 40 22 4"
    set CompareAnno(y512) "472 454 436 40 22 4"

    # Orient anno: top bot left right
    #---------------------------------------------
    set CompareAnno(orientList) "top bot right left"
    set CompareAnno(orient,x256) "130 130 240 1"
    set CompareAnno(orient,x512) "258 258 496 1"
    set CompareAnno(orient,y256) "240 4 131 131"
    set CompareAnno(orient,y512) "495 4 259 259"
}

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
# CompareAnno(cross)               : display cursor or not (value is 0 or 1).
# CompareAnno(crossIntersect)      : intersect cursor or not (value is 0 or 1).
# CompareAnno(hashes)              : display cursor hashes or not (value is 0 or 1).
# CompareAnno(cursorMode)          : set display coordinates (RAS, IJK or XY)
# CompareAnno(pixelDispFormat)     : pixel display format (rounded, .00 or full)
# CompareAnno(backPixelDispFormat) : pixel display format for background pixels
# CompareAnno(forePixelDispFormat) : pixel display format for foreground pixels
# CompareAnno(fontSize)            : annotations font size
# CompareAnno(mouseList)           : pixel coordinates and value mappers id
# CompareAnno(y256)                : y coordinates for mappers listed in CompareAnno(mouseList)
#                                     when slices size is 256*256
# CompareAnno(y512)                : y coordinates for mappers listed in CompareAnno(mouseList)
#                                     when slices size is 512*512
# CompareAnno(orientList)          : orientation mappers id
# CompareAnno(orient,x256)         : x coordinates for mappers listed in CompareAnno(orientList)
#                                     when slices size is 256*256
# CompareAnno(orient,x512)         : x coordinates for mappers listed in CompareAnno(orientList)
#                                     when slices size is 512*512
# CompareAnno(orient,y256)         : y coordinates for mappers listed in CompareAnno(orientList)
#                                     when slices size is 256*256
# CompareAnno(orient,y512)         : y coordinates for mappers listed in CompareAnno(orientList)
#                                     when slices size is 512*512

#-------------------------------------------------------------------------------
# .PROC CompareAnnoBuildGUI
# Build the annotations to be displayed in the slice windows.
# Those annotations are including pixels coordinates, pixels values
# (background and foreground) and the slice orientation/
# This procedure is called once during 3D Slicer initialization.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoBuildGUI {} {
    global CompareAnno CompareSlice CompareMosaik

    # define a new list including multiple slices and mosaik index
    set toUpdate [concat $CompareSlice(idList) $CompareMosaik(mosaikIndex)]

    #---------------------------------------------
    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    foreach name $CompareAnno(mouseList) y256 $CompareAnno(y256) y512 $CompareAnno(y512) {
        foreach s $toUpdate {
            vtkTextMapper CompareAnno($s,$name,mapper)
                CompareAnno($s,$name,mapper) SetInput ""
            if {[info commands vtkTextProperty] != ""} {
               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontSize $CompareAnno(fontSize)
               [CompareAnno($s,$name,mapper) GetTextProperty] BoldOn
               [CompareAnno($s,$name,mapper) GetTextProperty] ShadowOn
            } else {
                CompareAnno($s,$name,mapper) SetFontFamilyToTimes
                CompareAnno($s,$name,mapper) SetFontSize $CompareAnno(fontSize)
                CompareAnno($s,$name,mapper) BoldOn
                CompareAnno($s,$name,mapper) ShadowOn
            }
            vtkActor2D CompareAnno($s,$name,actor)
                CompareAnno($s,$name,actor) SetMapper \
                    CompareAnno($s,$name,mapper)
                CompareAnno($s,$name,actor) SetLayerNumber 1
                eval [CompareAnno($s,$name,actor) GetProperty] \
                    SetColor $CompareAnno(color)
                CompareAnno($s,$name,actor) SetVisibility 0
            slCompare${s}Imager AddActor2D CompareAnno($s,$name,actor)

            [CompareAnno($s,$name,actor) GetPositionCoordinate] \
                SetValue 1 $y256
        }
        set CompareAnno($name,rect256) "1 $y256 40 [expr $y256+18]"
        set CompareAnno($name,rect512) "1 $y512 40 [expr $y512+18]"
    }

    #---------------------------------------------
    # Orient anno: top bot left right
    #---------------------------------------------
    foreach name $CompareAnno(orientList) \
        x256 $CompareAnno(orient,x256) y256 "$CompareAnno(orient,y256)" {

        foreach s $toUpdate {
            vtkTextMapper CompareAnno($s,$name,mapper)
                CompareAnno($s,$name,mapper) SetInput ""
            if {[info commands vtkTextProperty] != ""} {
               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
               [CompareAnno($s,$name,mapper) GetTextProperty] SetFontSize $CompareAnno(fontSize)
               [CompareAnno($s,$name,mapper) GetTextProperty] BoldOn
               [CompareAnno($s,$name,mapper) GetTextProperty] ShadowOn
            } else {
                CompareAnno($s,$name,mapper) SetFontFamilyToTimes
                CompareAnno($s,$name,mapper) SetFontSize $CompareAnno(fontSize)
                CompareAnno($s,$name,mapper) BoldOn
                CompareAnno($s,$name,mapper) ShadowOn
            }
            vtkActor2D CompareAnno($s,$name,actor)
                CompareAnno($s,$name,actor) SetMapper \
                    CompareAnno($s,$name,mapper)
                CompareAnno($s,$name,actor) SetLayerNumber 1
                eval [CompareAnno($s,$name,actor) GetProperty] \
                    SetColor $CompareAnno(color)
                CompareAnno($s,$name,actor) SetVisibility 1
            slCompare${s}Imager AddActor2D CompareAnno($s,$name,actor)
            [CompareAnno($s,$name,actor) GetPositionCoordinate] \
                SetValue $x256 $y256
        }
    }

}

#-------------------------------------------------------------------------------
# .PROC CompareAnnoSetVisibility
#
# Checks the CompareAnno Array and sets visibility of the following objects
# in the 2D slices
#   - the Cross Hairs
#   - the Hash Marks on the Cross Hairs
#
# Sets if the Cross Hairs are intersected
#
# usage: CompareAnnoSetVisibility
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetVisibility {} {
    global CompareSlice CompareAnno CompareMosaik

    CompareAnnoSetCrossVisibility  $CompareAnno(cross)
    CompareAnnoSetHashesVisibility $CompareAnno(hashes)
    CompareAnnoSetCrossIntersect $CompareAnno(crossIntersect)
}

#-------------------------------------------------------------------------------
# .PROC CompareAnnoSetCrossVisibility
# Sets Cross Hairs visibility
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetCrossVisibility {vis} {
    global MultiSlicer

    MultiSlicer SetShowCursor $vis
}

#-------------------------------------------------------------------------------
# .PROC CompareAnnoSetCrossIntersect
# Sets if Cross Hairs are intersected
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetCrossIntersect {vis} {
    global MultiSlicer

    MultiSlicer SetCursorIntersect $vis
}

#-------------------------------------------------------------------------------
# .PROC CompareAnnoSetHashesVisibility
# Sets visibility of the Hash Marks on the Cross Hairs
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CompareAnnoSetHashesVisibility {vis} {
    global MultiSlicer

    if {$vis == 1} {
        set vis 5
    }
    MultiSlicer SetNumHashes $vis
}


#-------------------------------------------------------------------------------
# .PROC CompareAnnoStorePresets
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# TODO : manage presets in the future
#proc CompareAnnoStorePresets {p} {
#    global Preset CompareAnno
#
#    foreach key $Preset(Anno,keys) {
#        set Preset(CompareAnno,$p,$key) $CompareAnno($key)
#    }
#}

#-------------------------------------------------------------------------------
# .PROC CompareAnnoRecallPresets
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
# TODO : manage presets in the future
#proc CompareAnnoRecallPresets {p} {
#    global Preset CompareAnno
#
#    foreach key $Preset(Anno,keys) {
#        Compareset Anno($key) $Preset(CompareAnno,$p,$key)
#    }
#    CompareAnnoSetVisibility
#}

