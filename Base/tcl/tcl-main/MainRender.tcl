#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainRender.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:55 $
#   Version:   $Revision: 1.41 $
# 
#===============================================================================
# FILE:        MainRender.tcl
# PROCEDURES:  
#   Render3D
#   RenderSlice
#   RenderActive
#   RenderSlices
#   RenderAll
#   RenderBoth
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC Render3D
# 
# If $View(movie) > 0, saves the frame for a movie
#
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Render3D {{scale ""}} {
    global Video viewWin TwinDisplay twinWin Save View Slice

    # don't render when starting/stopping the program
    # or when certain modules need to do a lot of work w/o updates
    # or if in mainupdatemrml
    if { $View(render_on) == 0 } {
        return
    }

    if {$::Module(InMainUpdateMRML) == 1} {
        if {$::Module(verbose)} { puts "skipping render3d in main update mrml" }
        # set a flag to call this again at the end
        set ::Module(RenderFlagForMainUpdateMRML) 1
        return
    }

    # Apply the fog parameters to all the renderers of viewWin
    FogApply $viewWin

    
    set rens [$viewWin GetRenderers]
    set rencount [$rens GetNumberOfItems] 
    for {set r 0} {$r < $rencount} {incr r} {
        set ren [$rens GetItemAsObject $r]
        # don't reset clipping planes for the endoscopic
        # screen, otherwise it does not look good when
        # the endoscope is inside a model
        if {$ren != "endoscopicScreen"} {
             # wrap this in global flag to avoid possible render loop
             if {$View(resetCameraClippingRange) == 1} {
                 $ren ResetCameraClippingRange    
             }
         }  
    }

    # the Sorter makes sure that transparent objects are rendered
    # back to front - works for vtkCard and vtkTextureText
    # (used in Fiducials and QueryAtlas
    ## TODO - this should be made a module callback
    if {[info command vtkSorter] != ""} {
        foreach sorter [vtkSorter ListInstances] {
            $sorter DepthSort
        }
    }

    $viewWin Render
    
    if {[IsModule TwinDisplay] == 1 && $TwinDisplay(mode) == "On"} {
        TwinDisplay(src) Modified
        TwinDisplay(src) Update
        TwinDisplay(mapper) Modified
        $twinWin Render
    }

    if {[IsModule Video] == 1 && $Video(record) == "On"} {
        VideoSave
    }

    if { [SaveModeIsMovie] } {
        Save3DImage
    }
}

#-------------------------------------------------------------------------------
# .PROC RenderSlice
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RenderSlice {s {scale ""}} {
    global Slice View Interactor

    sl${s}Win Render

    if {$s == $Interactor(s)} {
        if {$View(createMagWin) == "Yes" && $View(closeupVisibility) == "On"
                && [info command magWin] != "" } {
            magWin Render
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC RenderActive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RenderActive {{scale ""}} {
    global Slice 

    RenderSlice $Slice(activeID)
}

#-------------------------------------------------------------------------------
# .PROC RenderSlices
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RenderSlices {{scale ""}} {
    global Slice 

    foreach s $Slice(idList) {
        RenderSlice $s
    }
}

#-------------------------------------------------------------------------------
# .PROC RenderAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RenderAll { {scale ""}} {
    global Slice

    foreach s $Slice(idList) {
        RenderSlice $s
    }
    # render3d last in case we want the newly rendered slices in the movie
    Render3D
    
}
 
#-------------------------------------------------------------------------------
# .PROC RenderBoth
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RenderBoth {s {scale ""}} {

    RenderSlice $s
    # render3d last in case we want the newly rendered slices in the movie
    Render3D
}
