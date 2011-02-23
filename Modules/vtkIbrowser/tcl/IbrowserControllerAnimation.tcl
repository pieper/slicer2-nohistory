#=auto==========================================================================
# (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors.
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for  
# research purposes only, provided that (1) the above copyright notice and 
# the following four paragraphs appear on all copies of this software, and 
# (2) that source code to any modifications to this software be made 
# publicly available under terms no more restrictive than those in this 
# License Agreement. Use of this software constitutes acceptance of these 
# terms and conditions.
# 
# 3D Slicer Software has not been reviewed or approved by the Food and 
# Drug Administration, and is for non-clinical, IRB-approved Research Use 
# Only.  In no event shall data or images generated through the use of 3D 
# Slicer Software be used in the provision of patient care.
# 
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
# ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
# DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
# EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
# OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
# NON-INFRINGEMENT.
# 
# THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
# 
# 
#===============================================================================
# FILE:        IbrowserControllerAnimation.tcl
# PROCEDURES:  
#   IbrowserSetupAnimationMenuImages
#   IbrowserMakeAnimationMenu
#   IbrowserDecrementFrame
#   IbrowserIncrementFrame
#   IbrowserGoToStartFrame
#   IbrowserGoToEndFrame
#   IbrowserPlayOnce
#   IbrowserPlayOnceReverse
#   IbrowserStopAnimation
#   IbrowserStopRecordingAnimation
#   IbrowserRecordAnimationToFile
#   IbrowserCloseRecordPopupWindow
#   IbrowserRecordPopupWindow
#   IbrowserPauseAnimation
#   IbrowserLoopAnimate
#   IbrowserPingPongAnimate
#   IbrowserZoomIn
#   IbrowserZoomOut
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserSetupAnimationMenuImages
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetupAnimationMenuImages { } {
    global PACKAGE_DIR_VTKIbrowser    

    #--- This variable contains the module path plus some stuff
    #--- trim off the extra stuff, and add on the path to tcl files.
    set tmpstr $PACKAGE_DIR_VTKIbrowser
    set tmpstr [string trimright $tmpstr "/vtkIbrowser" ]
    set tmpstr [string trimright $tmpstr "/Tcl" ]
    set tmpstr [string trimright $tmpstr "Wrapping" ]
    set modulePath [format "%s%s" $tmpstr "tcl/"]

    
    set ::IbrowserController(Images,Menu,frame-incLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/frame-incLO.gif]
    set ::IbrowserController(Images,Menu,frame-incHI) \
    [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/frame-incHI.gif]    
    set ::IbrowserController(Images,Menu,frame-decLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/frame-decLO.gif]
    set ::IbrowserController(Images,Menu,frame-decHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/frame-decHI.gif]
    set ::IbrowserController(Images,Menu,goto-startLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/goto-startLO.gif]
    set ::IbrowserController(Images,Menu,goto-startHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/goto-startHI.gif]
    set ::IbrowserController(Images,Menu,goto-endLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/goto-endLO.gif]
    set ::IbrowserController(Images,Menu,goto-endHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/goto-endHI.gif]    
    set ::IbrowserController(Images,Menu,anim-pingpongLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-pingpongLO.gif]
    set ::IbrowserController(Images,Menu,anim-pingpongHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-pingpongHI.gif]
    set ::IbrowserController(Images,Menu,anim-loopLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-loopLO.gif]
    set ::IbrowserController(Images,Menu,anim-loopHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-loopHI.gif]
    set ::IbrowserController(Images,Menu,anim-stopLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-stopLO.gif]
    set ::IbrowserController(Images,Menu,anim-stopHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-stopHI.gif]    
    set ::IbrowserController(Images,Menu,anim-recLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-recLO.gif]
    set ::IbrowserController(Images,Menu,anim-recHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-recHI.gif]
    set ::IbrowserController(Images,Menu,anim-pauseLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-pauseLO.gif]
    set ::IbrowserController(Images,Menu,anim-pauseHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-pauseHI.gif]    
    set ::IbrowserController(Images,Menu,anim-playLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-playLO.gif]
    set ::IbrowserController(Images,Menu,anim-playHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-playHI.gif]    
    set ::IbrowserController(Images,Menu,anim-rewLO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-rewLO.gif]
    set ::IbrowserController(Images,Menu,anim-rewHI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/anim-rewHI.gif]    
    set ::IbrowserController(Images,Menu,zoomIn-LO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/zoomIn-LO.gif]
    set ::IbrowserController(Images,Menu,zoomIn-HI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/zoomIn-HI.gif]
    set ::IbrowserController(Images,Menu,zoomOut-LO) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/zoomOut-LO.gif]
    set ::IbrowserController(Images,Menu,zoomOut-HI) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/controls/zoomOut-HI.gif]
}





#-------------------------------------------------------------------------------
# .PROC IbrowserMakeAnimationMenu
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeAnimationMenu { root } {

    #---DECREMENT FRAME
    frame $root.fibAnimControl -relief flat -background white -height 80 -pady 10 
    label $root.fibAnimControl.lframe_dec -background white \
        -image $::IbrowserController(Images,Menu,frame-decLO) -relief flat
    bind $root.fibAnimControl.lframe_dec <Enter> {
        %W config -image $::IbrowserController(Images,Menu,frame-decHI) }
    bind $root.fibAnimControl.lframe_dec <Leave> {
        %W config -image $::IbrowserController(Images,Menu,frame-decLO) }
    bind $root.fibAnimControl.lframe_dec <Button-1> {
        IbrowserDecrementFrame }
    
    label $root.fibAnimControl.lframe_curr -background white \
        -textvariable ::Ibrowser(ViewDrop) -width 10 -relief groove 

    #---INCREMENT FRAME
    label $root.fibAnimControl.lframe_inc -background white \
        -image $::IbrowserController(Images,Menu,frame-incLO) -relief flat
    bind $root.fibAnimControl.lframe_inc <Enter> {
        %W config -image $::IbrowserController(Images,Menu,frame-incHI) }
    bind $root.fibAnimControl.lframe_inc <Leave> {
        %W config -image $::IbrowserController(Images,Menu,frame-incLO) }
    bind $root.fibAnimControl.lframe_inc <Button-1> {
        IbrowserIncrementFrame }

    #---GO TO FIRST FRAME
    label $root.fibAnimControl.lgoto_start -background white \
        -image $::IbrowserController(Images,Menu,goto-startLO) -relief flat
    bind $root.fibAnimControl.lgoto_start <Enter> {
        %W config -image $::IbrowserController(Images,Menu,goto-startHI) }
    bind $root.fibAnimControl.lgoto_start <Leave> {
        %W config -image $::IbrowserController(Images,Menu,goto-startLO) }
    bind $root.fibAnimControl.lgoto_start <Button-1> {
        IbrowserGoToStartFrame }    

    #---PLAY ONCE IN REVERSE
    label $root.fibAnimControl.lanim_rew -background white \
        -image $::IbrowserController(Images,Menu,anim-rewLO) -relief flat
    set ::Ibrowser(AnimButtonRew) $root.fibAnimControl.lanim_rew    
    bind $root.fibAnimControl.lanim_rew <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-rewHI) }
    bind $root.fibAnimControl.lanim_rew <Leave> {
        if { $::Ibrowser(AnimationRew) == 0 } {
            %W config -image $::IbrowserController(Images,Menu,anim-rewLO)
        }
    }
    bind $root.fibAnimControl.lanim_rew <Button-1> {
        IbrowserPlayOnceReverse }    
    
    #---RECORD AN ANIMATION
    label $root.fibAnimControl.lanim_rec -background white \
    -image $::IbrowserController(Images,Menu,anim-recLO) -relief flat
    set ::Ibrowser(AnimButtonRec) $root.fibAnimControl.lanim_rec
    bind $root.fibAnimControl.lanim_rec <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-recHI) }
    bind $root.fibAnimControl.lanim_rec <Leave> {
        if { $::Ibrowser(AnimationRecording) == 0 } {
            %W config -image $::IbrowserController(Images,Menu,anim-recLO)
        }
    }
    bind $root.fibAnimControl.lanim_rec <Button-1> {
        IbrowserRecordPopupWindow }

    #---PAUSE AN ANIMATION
    label $root.fibAnimControl.lanim_pause -background white \
        -image $::IbrowserController(Images,Menu,anim-pauseLO) -relief flat            
    set ::Ibrowser(AnimButtonPause) $root.fibAnimControl.lanim_pause
    bind $root.fibAnimControl.lanim_pause <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-pauseHI) }
    bind $root.fibAnimControl.lanim_pause <Leave> {
        if { $::Ibrowser(AnimationPaused) == 0 } {
            %W config -image $::IbrowserController(Images,Menu,anim-pauseLO)
        }
    }
    bind $root.fibAnimControl.lanim_pause <Button-1> {
        IbrowserPauseAnimation }    
    
    #---PLAY AN ANIMATION ONCE
    label $root.fibAnimControl.lanim_play -background white \
        -image $::IbrowserController(Images,Menu,anim-playLO) -relief flat
    set ::Ibrowser(AnimButtonPlay) $root.fibAnimControl.lanim_play
    bind $root.fibAnimControl.lanim_play <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-playHI) }
    bind $root.fibAnimControl.lanim_play <Leave> {
        if { $::Ibrowser(AnimationForw) == 0 } {
            %W config -image $::IbrowserController(Images,Menu,anim-playLO)
        }
    }
    bind $root.fibAnimControl.lanim_play <Button-1> {
        IbrowserPlayOnce }
    
    #---GO TO LAST FRAME
    label $root.fibAnimControl.lgoto_end -background white \
        -image $::IbrowserController(Images,Menu,goto-endLO) -relief flat                
    bind $root.fibAnimControl.lgoto_end <Enter> {
        %W config -image $::IbrowserController(Images,Menu,goto-endHI) }
    bind $root.fibAnimControl.lgoto_end <Leave> {
        %W config -image $::IbrowserController(Images,Menu,goto-endLO) }
    bind $root.fibAnimControl.lgoto_end <Button-1> {
        IbrowserGoToEndFrame }
    
    #---ANIMATE IN CONTINUOUS LOOP
    label $root.fibAnimControl.lanim_loop -background white \
        -image $::IbrowserController(Images,Menu,anim-loopLO) -relief flat
    set ::Ibrowser(AnimButtonLoop) $root.fibAnimControl.lanim_loop    
    bind $root.fibAnimControl.lanim_loop <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-loopHI) }
    bind $root.fibAnimControl.lanim_loop <Leave> {
        if { $::Ibrowser(AnimationLoop) == 0 } {
            %W config -image $::IbrowserController(Images,Menu,anim-loopLO)
        }
    }
    bind $root.fibAnimControl.lanim_loop <Button-1> {
        set ::Ibrowser(AnimationInterrupt) 0
        IbrowserLoopAnimate }
    
    #---ANIMATE IN CONTINUOUS PINGPONG
    label $root.fibAnimControl.lanim_pingpong -background white \
        -image $::IbrowserController(Images,Menu,anim-pingpongLO) -relief flat
    set ::Ibrowser(AnimButtonPPong) $root.fibAnimControl.lanim_pingpong    
    bind $root.fibAnimControl.lanim_pingpong <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-pingpongHI) }
    bind $root.fibAnimControl.lanim_pingpong <Leave> {
        if { $::Ibrowser(AnimationPPong) == 0  } {
            %W config -image $::IbrowserController(Images,Menu,anim-pingpongLO)
        }
    }
    bind $root.fibAnimControl.lanim_pingpong <Button-1> {
        set ::Ibrowser(AnimationInterrupt) 0
        IbrowserPingPongAnimate }
    
    #---STOP ANIMATION
    label $root.fibAnimControl.lanim_stop -background white \
        -image $::IbrowserController(Images,Menu,anim-stopLO) -relief flat
    bind $root.fibAnimControl.lanim_stop <Enter> {
        %W config -image $::IbrowserController(Images,Menu,anim-stopHI) }
    bind $root.fibAnimControl.lanim_stop <Leave> {
        %W config -image $::IbrowserController(Images,Menu,anim-stopLO) }
    bind $root.fibAnimControl.lanim_stop <Button-1> {
        $::Ibrowser(AnimButtonLoop) config \
            -image $::IbrowserController(Images,Menu,anim-loopLO) 
        $::Ibrowser(AnimButtonPlay) config \
            -image $::IbrowserController(Images,Menu,anim-playLO) 
        $::Ibrowser(AnimButtonPause) config \
            -image $::IbrowserController(Images,Menu,anim-pauseLO) 
        $::Ibrowser(AnimButtonRew) config \
            -image $::IbrowserController(Images,Menu,anim-rewLO) 
        $::Ibrowser(AnimButtonRec) config \
            -image $::IbrowserController(Images,Menu,anim-recLO) 
        $::Ibrowser(AnimButtonPPong) config \
            -image $::IbrowserController(Images,Menu,anim-pingpongLO)         
        IbrowserStopAnimation }

    #---ZOOM IN ON INTERVALS
    label $root.fibAnimControl.lzoomIn -background white \
        -image $::IbrowserController(Images,Menu,zoomIn-LO) -relief flat
    bind $root.fibAnimControl.lzoomIn <Enter> {
        %W config -image $::IbrowserController(Images,Menu,zoomIn-HI) }
    bind $root.fibAnimControl.lzoomIn <Leave> {
        %W config -image $::IbrowserController(Images,Menu,zoomIn-LO) }
    bind $root.fibAnimControl.lzoomIn <Button-1> {
        IbrowserZoomIn }

    #---ZOOM OUT ON INTERVALS
    label $root.fibAnimControl.lzoomOut -background white \
        -image $::IbrowserController(Images,Menu,zoomOut-LO) -relief flat
    bind $root.fibAnimControl.lzoomOut <Enter> {
        %W config -image $::IbrowserController(Images,Menu,zoomOut-HI) }
    bind $root.fibAnimControl.lzoomOut <Leave> {
        %W config -image $::IbrowserController(Images,Menu,zoomOut-LO) }
    bind $root.fibAnimControl.lzoomOut <Button-1> {
        IbrowserZoomOut }

    #---PROGRESS BAR
    label $root.fibAnimControl.lProgressBarblank -background white \
     -width 1 -relief flat -padx 0
    
    label $root.fibAnimControl.lProgressBar -background white \
        -textvariable ::IbrowserController(ProgressBarTxt) -width 20 \
        -relief flat -padx 0 -font $::IbrowserController(UI,Medfont) \
        -highlightcolor #FFFFFF -highlightbackground #FFFFFF -foreground #FFFFFF

    #--- we can configure this later to have grooved or flat relief
    #--- which makes it effectively invisible or visible.
    set ::IbrowserController(ProgressBar) $root.fibAnimControl.lProgressBar
    IbrowserLowerProgressBar
    
    pack $root.fibAnimControl.lframe_dec -side left -padx 0 
    pack $root.fibAnimControl.lframe_curr -side left -padx 0
    pack $root.fibAnimControl.lframe_inc -side left -padx 0 
    pack $root.fibAnimControl.lzoomIn -side left -padx 0 
    pack $root.fibAnimControl.lzoomOut -side left -padx 0
    pack $root.fibAnimControl.lgoto_start -side left -padx 0
    pack $root.fibAnimControl.lanim_rew -side left -padx 0 
    pack $root.fibAnimControl.lanim_stop -side left -padx 0
    pack $root.fibAnimControl.lanim_rec -side left -padx 0 
    pack $root.fibAnimControl.lanim_pause -side left -padx 0
    pack $root.fibAnimControl.lanim_play -side left -padx 0 
    pack $root.fibAnimControl.lgoto_end -side left -padx 0 
    pack $root.fibAnimControl.lanim_loop -side left -padx 0
    pack $root.fibAnimControl.lanim_pingpong -side left -padx 0 
    pack $root.fibAnimControl.lProgressBarblank -side left 
    pack $root.fibAnimControl.lProgressBar -side left 
    pack $root.fibAnimControl -side top -fill x -expand false

    #--- return frame for other use.
    return $root.fibAnimControl

}


#-------------------------------------------------------------------------------
# .PROC IbrowserDecrementFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDecrementFrame { } {

    set ::Ibrowser(AnimationInterrupt) 1
    set ::Ibrowser(AnimationPaused) 0
    #--- what is current frame?
    set curDrop $::Ibrowser(ViewDrop)

    #--- how many drops in this interval?
    set id $::Ibrowser(activeInterval)
    set name $::Ibrowser($id,name)
    set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]

    #--- update if appropriate.
    set newDrop [ expr $curDrop - 1 ]
    if { $newDrop >= 0 } {
        set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
        set ::Ibrowser(ViewDrop) $newDrop
        IbrowserUpdateIndexFromAnimControls
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserIncrementFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserIncrementFrame { } {

    set ::Ibrowser(AnimationInterrupt) 1
    set ::Ibrowser(AnimationPaused) 0
    #--- what is current frame?
    set curDrop $::Ibrowser(ViewDrop)

    #--- how many drops in this interval?
    set id $::Ibrowser(activeInterval)
    set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]
    set newDrop [ expr $curDrop + 1 ]
    if { $newDrop <= $numdrops } {
        set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
        set ::Ibrowser(ViewDrop) $newDrop
        IbrowserUpdateIndexFromAnimControls
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserGoToStartFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGoToStartFrame { } {

    set ::Ibrowser(AnimationInterrupt) 1
    set ::Ibrowser(AnimationPaused) 0
    set id $::Ibrowser(activeInterval)
    set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
    set ::Ibrowser(ViewDrop) 0
    IbrowserUpdateIndexFromAnimControls
    IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    set ::Ibrowser(AnimationInterrupt) 0
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGoToEndFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGoToEndFrame { } {

    set ::Ibrowser(AnimationInterrupt) 1
    set ::Ibrowser(AnimationPaused) 0
    #--- how many drops in this interval?
    set id $::Ibrowser(activeInterval)
    set name $::Ibrowser($id,name)
    set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]
    set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
    set ::Ibrowser(ViewDrop) $numdrops
    IbrowserUpdateIndexFromAnimControls
    IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    set ::Ibrowser(AnimationInterrupt) 0
}

#-------------------------------------------------------------------------------
# .PROC IbrowserPlayOnce
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlayOnce { } {

    if { $::Ibrowser(AnimationInterrupt) == 0 && $::Ibrowser(AnimationPaused) == 0 } {
        set done 0
        set curDrop $::Ibrowser(ViewDrop)
        set ::Ibrowser(AnimationWas) "forw"
        set ::Ibrowser(AnimationForw) 1
        #--- how many drops in this interval?
        set id $::Ibrowser(activeInterval)
        set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]

        if { $curDrop < $numdrops } {
            set newDrop [ expr $curDrop + 1 ]
            set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
            set ::Ibrowser(ViewDrop) $newDrop
            IbrowserUpdateIndexFromAnimControls
            IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
        } else {
            set done 1
            set ::Ibrowser(AnimationForw) 0
            set ::Ibrowser(AnimationPaused) 0
            set ::Ibrowser(AnimationInterrupt) 0            
            #---lolite the icons
            $::Ibrowser(AnimButtonPlay) config -image \
                $::IbrowserController(Images,Menu,anim-playLO) 
            $::Ibrowser(AnimButtonPause) config -image \
                $::IbrowserController(Images,Menu,anim-pauseLO) 
        }
        if { $done == 0 } {
            update
            after $::Ibrowser(AnimationFrameDelay) IbrowserPlayOnce
        }
    } else {
        set ::Ibrowser(AnimationInterrupt) 0
    }
                      
}



    

#-------------------------------------------------------------------------------
# .PROC IbrowserPlayOnceReverse
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPlayOnceReverse { } {

    if { $::Ibrowser(AnimationInterrupt) == 0 && $::Ibrowser(AnimationPaused) == 0 } {
        set done 0
        set curDrop $::Ibrowser(ViewDrop)    
        set ::Ibrowser(AnimationWas) "rew" 
        set ::Ibrowser(AnimationRew) 1
        #--- how many drops in this interval?
        set id $::Ibrowser(activeInterval)
        set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]

        if { $curDrop > 0 } {
            set newDrop [ expr $curDrop - 1 ]
            set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
            set ::Ibrowser(ViewDrop) $newDrop
            IbrowserUpdateIndexFromAnimControls
            IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
        } else {
            set done 1
            set ::Ibrowser(AnimateRew) 0
            set ::Ibrowser(AnimationPaused) 0
            set ::Ibrowser(AnimationInterrupt) 0
            #--- lolite the icons
            $::Ibrowser(AnimButtonRew) config -image \
                $::IbrowserController(Images,Menu,anim-rewLO) 
            $::Ibrowser(AnimButtonPause) config -image \
                $::IbrowserController(Images,Menu,anim-pauseLO) 
        }
        if { $done == 0 } {
            update
            after $::Ibrowser(AnimationFrameDelay) IbrowserPlayOnceReverse
        }
    } else {
        set ::Ibrowser(AnimationInterrupt) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserStopAnimation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserStopAnimation { } {

    set ::Ibrowser(AnimationInterrupt) 1
    set ::Ibrowser(AnimationPaused) 0
    set ::Ibrowser(AnimationForw) 0
    set ::Ibrowser(AnimationRew) 0
    set ::Ibrowser(AnimationLoop) 0
    set ::Ibrowser(AnimationPPong) 0
    if { $::Ibrowser(AnimationRecording) } {
        IbrowserStopRecordingAnimation
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserStopRecordingAnimation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserStopRecordingAnimation { } {
    if { $::Ibrowser(AnimationRecording) } {
        puts "exiting record mode"
        set ::Save(imageSaveMode) "Single view"
        #--- change state of button in RecordPopupWindow
        set ::Ibrowser(AnimationRecording) 0
        if  { [info exists ::Ibrowser(AnimationRecordbutton)] } {
            $::Ibrowser(AnimationRecordbutton) configure -text "Go"
        } 
        #$::Ibrowser(AnimButtonRec) config -image \
         #   $::IbrowserController(Images,Menu,anim-recLO)        
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserRecordAnimationToFile
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRecordAnimationToFile { } {
    #--- if we're recording, stop; and
    #--- if we're not recording, start
    #---
    if { $::Ibrowser(AnimationRecording) } {
        puts "exiting record mode"
        set ::Save(imageSaveMode) "Single view"
        set ::Ibrowser(AnimationRecording) 0
        #--- change state of rec button in IbrowserController
        $::Ibrowser(AnimButtonRec) config \
            -image $::IbrowserController(Images,Menu,anim-recLO) 
        #--- change state of button in RecordPopupWindow
        if  { [info exists ::Ibrowser(AnimationRecordbutton)] } {
            $::Ibrowser(AnimationRecordbutton) configure -text "Go"
        }
    } else {
        puts "entering record mode"
        set ::Ibrowser(AnimationInterrupt) 1
        set ::Ibrowser(AnimationRecording) 1
        #set ::Ibrowser(AnimationPaused) 0    
        set ::Save(imageSaveMode) "Movie"
        #Save3DImage
        #--- change state of rec button in IbrowserController
        $::Ibrowser(AnimButtonRec) config \
            -image $::IbrowserController(Images,Menu,anim-recHI) 
        #--- change state of button in RecordPopupWindow
        if  { [info exists ::Ibrowser(AnimationRecordbutton)] } {
            $::Ibrowser(AnimationRecordbutton) configure -text "Stop"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserCloseRecordPopupWindow
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCloseRecordPopupWindow { root } {
    unset ::Ibrowser(AnimationRecordbutton)
    destroy $root    
}


#-------------------------------------------------------------------------------
# .PROC IbrowserRecordPopupWindow
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRecordPopupWindow { {toplevelName .ibrowserRecord} } {
    global Gui
    
    if {[winfo exists $toplevelName]} {
        wm deiconify $toplevelName
        raise $toplevelName
        return
    }
    set root [toplevel $toplevelName]
    wm title $root "Ibrowser save movie"
    wm protocol $root WM_DELETE_WINDOW "IbrowserCloseRecordPopupWindow $root"

    set f [ frame $root.fRecordOptions -relief flat -border 2 -bg #FFFFFF ]
    pack $f 

    #--- set some file options
    label $f.lFileOptionsTitle -text "File Options" -bg #FFFFFF -fg #000000
    grid $f.lFileOptionsTitle -sticky w -columnspan 2
    grid [tkSpace $f.space0 -height 5] -columnspan 2

    label $f.lDir -text "Directory:" -bg #FFFFFF -fg #000000

    entry $f.eDir -width 16 -textvariable Save(imageDirectory) -bg #DDDDDD -fg #000000

    grid $f.lDir $f.eDir -sticky w
    grid config $f.lDir -sticky e -padx $Gui(pad)

    button $f.bChooseDir -text "Browse..." -command SaveChooseDirectory -bg #DDDDDD -fg #000000
    grid [tkSpace $f.space3] $f.bChooseDir -sticky w 

    grid [tkSpace $f.space4 -height 5] -columnspan 2

    label $f.lPrefix -text "File prefix:" -bg #FFFFFF -fg #000000
    entry $f.ePrefix -width 16 -textvariable Save(imageFilePrefix) -bg #DDDDDD -fg #000000
    grid $f.lPrefix $f.ePrefix -sticky w  -pady $Gui(pad)
    grid config $f.lPrefix -sticky e  -padx $Gui(pad)

    label $f.lFrame -text "Next frame #:"  -bg #FFFFFF -fg #000000
    entry $f.eFrame -width 6 -textvariable Save(imageFrameCounter) -bg #DDDDDD -fg #000000
    grid $f.lFrame $f.eFrame -sticky w  -pady $Gui(pad)
    grid config $f.lFrame -sticky e  -padx $Gui(pad)

    label $f.lFileType -text "File type:"  -bg #FFFFFF -fg #000000
    eval tk_optionMenu $f.mbFileType Save(imageFileType) [SaveGetSupportedImageTypes] 
    $f.mbFileType config -pady 3 -bg #DDDDDD -fg #000000
    grid $f.lFileType $f.mbFileType -sticky w  -pady $Gui(pad)
    grid config $f.lFileType -sticky e  -padx $Gui(pad)

    grid [tkHorizontalLine $f.line1] -columnspan 2 -pady 5 -sticky we

    #--- set some save options
    label $f.lSaveTitle -text "Save Options" -anchor w -bg #FFFFFF -fg #000000
    grid $f.lSaveTitle -sticky news -columnspan 1

    label $f.lScale -text "Output zoom:" -bg #FFFFFF -fg #000000 -activebackground #DDDDDD
    $f.lScale config -anchor sw 

    eval scale $f.sScale -from 1 -to 8 -orient horizontal \
        -variable Save(imageOutputZoom) $Gui(WSA) -showvalue true \
        -bg #FFFFFF -fg #000000

    TooltipAdd $f.sScale "Renders the image in multiple pieces toproduce a higher resolution image (useful for publication)." 
    grid $f.lScale $f.sScale -sticky w 
    grid $f.lScale -sticky sne -ipady 10  -padx $Gui(pad)

    #label $f.lStereo -text "Stereo disparity:"
    #GuiApplyStyle WLA $f.lStereo
    #entry $f.eStereo -width 6 -textvariable Save(stereoDisparityFactor)
    #GuiApplyStyle WEA $f.eStereo
    #TooltipAdd $f.eStereo "Changes the disparity (apparent depth) of the stereo image by this scale factor."

    #grid $f.lStereo $f.eStereo -sticky w   -pady $Gui(pad)
    #grid $f.lScale $f.lStereo -sticky e  -padx $Gui(pad)
    grid $f.lScale -sticky e  -padx $Gui(pad)

    checkbutton $f.cIncludeSlices -text "Include slice windows" -indicatoron 1 -variable Save(imageIncludeSlices)\
            -fg #000000 -bg #FFFFFF -activebackground #FFFFFF -relief flat
    #GuiApplyStyle WCA $f.cIncludeSlices
    grid $f.cIncludeSlices -sticky we -columnspan 2

    grid [tkHorizontalLine $f.line10] -columnspan 2 -pady 5 -sticky we
    grid [tkSpace $f.space2 -height 10] -columnspan 2
    button $f.bCloseWindow -text "Close" -command "IbrowserCloseRecordPopupWindow $root" -bg #DDDDDD -fg #000000
    button $f.bSaveNow     -text "Go" -command "IbrowserRecordAnimationToFile" -bg #DDDDDD -fg #000000
    set ::Ibrowser(AnimationRecordbutton) $f.bSaveNow
    TooltipAdd $f.bSaveNow "Begin saving a frame each time the Viewer is updated. Stop with Ibrowser's stop button."
    
    #GuiApplyStyle WBA $f.bSaveNow $f.bCloseWindow
    grid $f.bCloseWindow $f.bSaveNow -sticky we -padx $Gui(pad) -pady $Gui(pad) -ipadx 2 -ipady 5

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 1
    grid columnconfigure $f 2 -weight 1

    return $root
}



#-------------------------------------------------------------------------------
# .PROC IbrowserPauseAnimation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPauseAnimation { } {

    if { $::Ibrowser(AnimationPaused) == 0 } {
        set ::Ibrowser(AnimationPaused) 1
        set ::Ibrowser(AnimationInterrupt) 1
    } else {
        #--- resume what we were doing.
        set ::Ibrowser(AnimationPaused) 0
        set ::Ibrowser(AnimationInterrupt) 0
        if { $::Ibrowser(AnimationWas) == "forw" } {
            IbrowserPlayOnce
        } elseif { $::Ibrowser(AnimationWas) == "rew" } {
            IbrowserPlayOnceReverse
        } elseif { $::Ibrowser(AnimationWas) == "loop" } {
            IbrowserLoopAnimate
        } elseif { $::Ibrowser(AnimationWas) == "ppong" } {
            IbrowserPingPongAnimate
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserLoopAnimate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserLoopAnimate { } {

    if { $::Ibrowser(AnimationInterrupt) == 0  && $::Ibrowser(AnimationPaused) == 0 } {
        set curDrop $::Ibrowser(ViewDrop)    
        set ::Ibrowser(AnimationWas) "loop" 
        set ::Ibrowser(AnimationLoop) 1
        #--- how many drops in this interval?
        set id $::Ibrowser(activeInterval)
        set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]
        
        if { $curDrop < $numdrops } {
            set newDrop [ expr $curDrop + 1 ]
            set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
            set ::Ibrowser(ViewDrop) $newDrop
            IbrowserUpdateIndexFromAnimControls
            IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
            update
            after $::Ibrowser(AnimationFrameDelay) IbrowserLoopAnimate
        } else {
            set newDrop 0
            set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
            set ::Ibrowser(ViewDrop) $newDrop
            IbrowserUpdateIndexFromAnimControls
            IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
            update
            after $::Ibrowser(AnimationFrameDelay) IbrowserLoopAnimate            
        }
    }

}

#-------------------------------------------------------------------------------
# .PROC IbrowserPingPongAnimate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPingPongAnimate { } {

    if { $::Ibrowser(AnimationInterrupt) == 0 && $::Ibrowser(AnimationPaused) == 0 } {
        #--- get the current frame
        set curDrop $::Ibrowser(ViewDrop)    
        set ::Ibrowser(AnimationWas) "ppong" 
        set ::Ibrowser(AnimationPPong) 1
        #--- how many drops in this interval?
        set id $::Ibrowser(activeInterval)
        set numdrops [ expr $::Ibrowser($id,lastMRMLid) - $::Ibrowser($id,firstMRMLid) ]
        #--- forward direction...
        if { $::Ibrowser(AnimationDirection) == 1 } {
            if { $curDrop < $numdrops } {
                set newDrop [ expr $curDrop + 1 ]
                set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
                set ::Ibrowser(ViewDrop) $newDrop
                IbrowserUpdateIndexFromAnimControls
                IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
                update
                after $::Ibrowser(AnimationFrameDelay) IbrowserPingPongAnimate
            } else {
                set ::Ibrowser(AnimationDirection) -1
                update
                after $::Ibrowser(AnimationFrameDelay) IbrowserPingPongAnimate
            }
        } else {
            if { $curDrop > 0 } {
                set newDrop [ expr $curDrop - 1 ]
                set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
                set ::Ibrowser(ViewDrop) $newDrop
                IbrowserUpdateIndexFromAnimControls
                IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
                update
                after $::Ibrowser(AnimationFrameDelay) IbrowserPingPongAnimate
            } else {
                set ::Ibrowser(AnimationDirection) 1
                update
                after $::Ibrowser(AnimationFrameDelay) IbrowserPingPongAnimate
            }
        }
    }
    
}

#-------------------------------------------------------------------------------
# .PROC IbrowserZoomIn
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserZoomIn { } {

    if { 0 } {
        if { $::IbrowserController(zoomfactor) < 4 } {
            $::IbrowserController(Icanvas) scale all 0 0 1.1 1.1
            $::IbrowserController(Ccanvas) scale all 0 0 1.1 1.1
            incr ::IbrowserController(zoomfactor)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC IbrowserZoomOut
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserZoomOut { } {

    if { 0 } {
        if { $::IbrowserController(zoomfactor) > 0 } {
            $::IbrowserController(Icanvas) scale all 0 0 0.9 0.9
            $::IbrowserController(Ccanvas) scale all 0 0 0.9 0.9
            set ::IbrowserController(zoomfactor) [ expr $::IbrowserController(zoomfactor) - 1 ]
        }
    }
}
