#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineModelView.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:38 $
#   Version:   $Revision: 1.27 $
# 
#===============================================================================
# FILE:        fMRIEngineModelView.tcl
# PROCEDURES:  
#   fMRIModelViewLaunchModelView toplevelName
#   fMRIModelViewCatchGenerateModel
#   fMRIModelViewGenerateModel toplevelName
#   fMRIModelViewShowMessageText
#   fMRIModelViewEraseMessageText
#   fMRIModelViewCreatePopup w title x y
#   fMRIModelViewRaisePopup w
#   fMRIModelViewShowPopup w x y
#   fMRIModelViewSetConditionOnsets r cnum clist
#   fMRIModelViewSetConditionDurations r cnum clist
#   fMRIModelViewSetConditionIntensities r cnum clist
#   fMRIModelViewSetTContrast cnum clist
#   fMRIModelViewSetEVCondition
#   fMRIModelViewSetEVSignalType r evnum signal
#   fMRIModelViewAddConditionName r cname
#   fMRIModelViewDeleteConditionName
#   fMRIModelViewSetTContrastName cnum cname
#   fMRIModelViewSetTContrastLabel cnum
#   fMRIModelViewGenerateEVName evnum r
#   fMRIModelViewGenerateEVLabel evnum
#   fMRIModelViewAddFileName fname
#   fMRIModelViewSetInitialOrthogonalityDim
#   fMRIModelViewSetElementSpacing
#   fMRIModelViewComputeCaptionBuffers
#   fMRIModelViewSetupLayout
#   fMRIModelViewDisplayModelView f
#   fMRIModelViewBuildDesignMatrix c refX refY dmatHit dmatWid borderWid
#   fMRIModelViewBuildEVData r i
#   fMRIModelViewBuildEVImages r i imgw
#   fMRIModelViewBuildModelSignals r i imghit imgwid signalType
#   fMRIModelViewFindNumCosineBasis
#   fMRIModelViewBuildDCBasis imgwid imghit r evnum freq
#   fMRIModelViewLongestEpochSpacing
#   fMRIModelViewBuildBaseline imgwid imghit r evnum
#   fMRIModelViewComputeBoxCar onset duration imgwid r i
#   fMRIModelViewComputeHalfSine onset duration imgwid r i
#   fMRIModelViewComputeHRF r
#   fMRIModelViewConvolveWithHRF imgwid imghit run evnum
#   fMRIModelViewAddDerivatives imgwid imghit r evnum
#   fMRIModelViewComputeGaussianFilter r
#   fMRIModelViewGaussianDownsampleList i r olen nlen inputList
#   fMRIModelViewRangemapList data finalRangeMax finalRangeMid
#   fMRIModelViewRangemapListForImage min max dim data finalRangeMax finalRangeMid
#   fMRIModelViewListToImage imghit imgwid rowrun lst
#   fMRIModelViewComputeDotProduct v1 v2 len
#   fMRIModelViewComputeVectorMagnitude v len
#   fMRIModelViewBuildContrastTable c refX refY dmatHit dmatWid cmatHit cmatWid borderWid
#   fMRIModelViewBufFromChars thinglist whichfont
#   fMRIModelViewScrolledCanvas f args
#   fMRIModelViewSetFonts
#   fMRIModelViewSetColors
#   fMRIModelViewSetupButtonImages c refX refY dmatHit dmatWid cmatHit cmatWid
#   fMRIModelViewSaveModelPostscript
#   fMRIModelViewSaveModelPostscriptPopup toplevelName
#   fMRIModelViewChooseDirectory
#   fMRIModelViewClosePostscriptPopup win
#   fMRIModelViewSetupOrthogonalityImage c refX refY dmatHit dmatWid cmatHit cmatWid b
#   fMRIModelViewLabelTContrasts c refX refY dmatHit cmatHit
#   fMRIModelViewLabelTContrastNames c refX refY dmatHit cmatHit
#   fMRIModelViewLabelEVs c refX refY dmatWid
#   fMRIModelViewLabelEVnames c refX refY dmatWid
#   fMRIModelViewEVnameRollover c refY evnum runNum
#   fMRIModelViewLabelFilenames c refX refY dmatHit dmatWid
#   fMRIModelViewFilenameRollover c refY dmatHit mousey
#   fMRIModelViewHideRolloverInfo c
#   fMRIModelViewFreeCanvasTags
#   fMRIModelViewFreeFonts
#   fMRIModelViewFreeColors
#   fMRIModelViewFreeModel
#   fMRIModelViewClearUserInput
#   fMRIModelViewFreeVisualLayout
#   fMRIModelViewCleanCanvas
#   fMRIModelViewCleanForRegeneration
#   fMRIModelViewCleanNoRegeneration
#   fMRIModelViewCloseAndCleanNoRegeneration
#   fMRIModelViewCloseAndClean
#   fMRIModelViewCloseAndCleanAndExit
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLaunchModelView
# 
# .ARGS
# windowpath toplevelName defaults to .wfMRIModelView
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLaunchModelView { {toplevelName .wfMRIModelView} } {
    #---
    #--- fMRIModelViewLaunchModelView gets run at button press
    #--- if the window already exists, but is iconified,
    #--- clean stuff up, empty and delete canvas;
    #--- leave nothing but toplevel win, and then
    #--- regenerate everything inside it fresh and new.
    #---
    #--- freeing everything but user input
    if { $::fMRIEngine(SignalModelDirty) } {
        fMRIModelViewCleanForRegeneration
    } else {
        fMRIModelViewCleanNoRegeneration
    }

    if { [winfo exists $toplevelName] } {
        wm deiconify $toplevelName
        set root $::fMRIModelView(modelViewWin)
    } else {
        #--- set up window
        set fMRIModelWinXpos 300
        set fMRIModelWinYpos 100
        set fMRIModelWinMinWid 200
        set fMRIModelWinMinHit 175
        set fMRIModelWinBaseWid 400
        set fMRIModelWinBaseHit 300
        set root [ toplevel $toplevelName ]
        wm title $root "design matrix and contrasts"
        wm geometry $root +$fMRIModelWinXpos+$fMRIModelWinYpos
        wm minsize $root $fMRIModelWinMinWid $fMRIModelWinMinHit
        wm protocol $root WM_DELETE_WINDOW "fMRIModelViewCloseAndCleanNoRegeneration"
    }
    #--- hardcode a name for the window.
    set ::fMRIModelView(modelViewWin) ".wfMRIModelView"
    set ::fMRIModelView(Layout,NoDisplay) 0

    #--- initialize fonts and colors
    fMRIModelViewSetFonts
    fMRIModelViewSetColors

    #--- get user's paradigm design and modeling input
    fMRIModelViewSortUserInput

    #--- if there's no model to view, nothing will happen.
    if { $::fMRIModelView(Design,numRuns) == 0 } {
        for { set r 1 } { $r < $::fMRIModelView(Design,numRuns) } { incr r } {
            if { $::fMRIModelView(Design,Run$r,numConditions) == 0 } {
                DevErrorWindow "No conditions are specified for Run $r."
                return
            }
        }
    }
    #--- autoconfigure the layout 
    fMRIModelViewSetInitialOrthogonalityDim
    fMRIModelViewSetElementSpacing
    fMRIModelViewComputeCaptionBuffers
    fMRIModelViewSetupLayout

    #--- create a frame, canvas within it, set up canvases and scrollregions.
    $root configure -background $::fMRIModelView(Colors,hexwhite)
    set fMRIModelWinScrollWid $::fMRIModelView(Layout,totalWid) 
    set fMRIModelWinScrollHit $::fMRIModelView(Layout,totalHit) 
    set fMRIModelWinBaseWid 400
    set fMRIModelWinBaseHit 300
    fMRIModelViewScrolledCanvas $root.fDesignMatrix -relief groove -borderwidth 1 \
        -bg $::fMRIModelView(Colors,bkg) \
        -width $fMRIModelWinBaseWid -height $fMRIModelWinBaseHit \
        -scrollregion "0 0 $fMRIModelWinScrollWid $fMRIModelWinScrollHit"
    pack $root.fDesignMatrix -fill both -expand true

    #--- put up little message
    $::fMRIModelView(modelViewCanvas) create text  200 20 \
        -text "....generating model and images; may take awhile...." -anchor center \
        -font $::fMRIModelView(UI,Medfont) \
        -tag $::fMRIModelView(Layout,WaitTag)
    update 
    
    #--- and build all the stuff to visualize the model.
    #--- if something fails, clean up and close window
    #--- not sure if this works!
    if { ! [fMRIModelViewDisplayModelView $root.fDesignMatrix] } {
        fMRIModelViewCloseAndClean
        return 0
    }
    return 1
}




#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCatchGenerateModel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCatchGenerateModel { } {

    if { ! [ fMRIModelViewGenerateModel ] } {
        DevErrorWindow "Error generating model: please check model specification."
    }
}



#-------------------------------------------------------------------------------
# .PROC fMRIModelViewGenerateModel
# 
# .ARGS
# windowpath toplevelName defaults to .wfMRIModelView
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewGenerateModel { {toplevelName .wfMRIModelView} } {
global Gui

    #---
    #--- fMRIModelViewGenerateModel gets run each time someone
    #--- enters a new condition, updates signal modeling on that
    #--- condition, or enters a new contrast.
    #--- if window is already up, also update the visual display
    #---
    if { ([winfo exists $toplevelName]) || ($::fMRIEngine(SignalModelDirty)) } {

        #--- wjp: added 09/19/05
        if { ! [ fMRIEngineCountEVs ] } {
            return
        }
        if {$::fMRIEngine(noOfSpecifiedRuns) == 0} {
            DevErrorWindow "No run has been specified."
            return
        }

        for {set r 1} {$r <= $::fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
            if {! [info exists ::fMRIEngine($r,noOfEVs)]} {
                DevErrorWindow "Complete signal modeling first for run$r."
                return
            }
        }
        #--- wjp: end of addition 09/19/05
        
        if { ! [ fMRIModelViewLaunchModelView ] } {
            return 0
        }

        set ::fMRIModelView(Layout,NoDisplay) 0
    } else {
        #--- otherwise, no view update is required or requested.
        #--- compute all new signal modeling without generating
        #--- visual display. This does more work than we need, 
        #--- but we'll fix that later when we have more time.
        #---
        #--- free everything but user input.
        if { $::fMRIEngine(SignalModelDirty) } {
            fMRIModelViewCleanForRegeneration
        } else {
            fMRIModelViewCleanNoRegeneration
        }

        #--- regenerate.        
        fMRIModelViewSetFonts
        fMRIModelViewSetColors
        fMRIModelViewSortUserInput
        set ::fMRIModelView(Layout,NoDisplay) 1
        fMRIModelViewSetInitialOrthogonalityDim
        fMRIModelViewSetElementSpacing
        fMRIModelViewComputeCaptionBuffers
        fMRIModelViewSetupLayout
        set imgwid $::fMRIModelView(Layout,EVBufWid) 

        if { $::fMRIEngine(SignalModelDirty) } {
            for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
                set imghit [ expr $::fMRIModelView(Design,Run$r,numTimePoints) * \
                                 $::fMRIModelView(Layout,pixelsPerTimePoint) ]
                set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                               $::fMRIModelView(Design,Run$r,numAdditionalEVs) ] 

                #--- display message...
                #set MsgID [ fMRIModelViewShowMessageText "Generating signals; may take awhile..."]
                for { set i 1 } { $i <= $cols } { incr i } {
                    set signalType $::fMRIModelView(Design,Run$r,EV$i,SignalType)
                    fMRIModelViewBuildModelSignals $r $i $imghit $imgwid $signalType 
                    set ok [ fMRIModelViewBuildEVData  $r $i ]
                    if {$ok == 0 } {
                        DevErrorWindow "Error generating model signals. Please check your inputs."
                        return 0
                    }
                }
            }
            #fMRIModelViewEraseMessageText $MsgID
        }
    }
    return 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewShowMessageText
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewShowMessageText { txt } {
    global Gui

    set ::Gui(progressText) $txt
    set MsgHeight [winfo height $::Gui(fStatus)]
    set MsgWidth [winfo width $::Gui(fStatus)]
    set MsgID [ $::Gui(fStatus).canvas create text [ expr $MsgWidth/2] \
                    [expr $MsgHeight/2] -anchor center -justify center \
                    -text "$txt" ]
    update idletasks
    return $MsgID
}




#-------------------------------------------------------------------------------
# .PROC fMRIModelViewEraseMessageText
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewEraseMessageText { id } {
    global Gui

    puts "erasing"
    if { [info exists $id ] } {
        $::Gui(fStatus).canvas delete $id
    }
    update idletasks
}




#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCreatePopup
# 
# .ARGS
# windowpath w
# string title
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCreatePopup { w title x y } {
    #---
    toplevel $w -class Dialog -background ::fMRIModelView(Colors,hexwhite)
    wm title $w $title
    wm iconname $w Dialog
    wm geometry $w +$x+$y
    focus $w
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewRaisePopup
# 
# .ARGS
# windowpath w
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewRaisePopup { w } {
    #---
    if {[winfo exists $w] != 0} {
        raise $w
        focus $w
        wm deiconify $w
        return 1
    }
    return 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewShowPopup
# 
# .ARGS
# windowpath w
# int x
# int y
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewShowPopup { w x y } {
    #---
    wm deiconify $w
    update idletasks
    set wWin [winfo width  $w]
    set hWin [winfo height $w]
    set wScr [winfo screenwidth  .]
    set hScr [winfo screenheight .]
    
    set xErr [expr $wScr - 30 - ($x + $wWin)]
    if {$xErr < 0} {
        set x [expr $x + $xErr]
    }
    set yErr [expr $hScr - 30 - ($y + $hWin)]
    if {$yErr < 0} {
        set y [expr $y + $yErr]
    }
    
    raise $w
    wm geometry $w +$x+$y
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetConditionOnsets
# 
# .ARGS
# int r
# int cnum
# list clist
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetConditionOnsets { r cnum clist } {
    #---
    set ::fMRIModelView(Design,Run$r,Condition$cnum,Onsets) $clist
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetConditionDurations
# 
# .ARGS
# int r
# int cnum
# list clist
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetConditionDurations { r cnum clist } {
    #---
    set ::fMRIModelView(Design,Run$r,Condition$cnum,Durations) $clist
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetConditionIntensities
# 
# .ARGS
# int r
# int cnum
# list clist
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetConditionIntensities { r cnum clist } {
    #---
    set ::fMRIModelView(Design,Run$r,Condition$cnum,Intensities) $clist
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetTContrast
# 
# .ARGS
# int cnum
# list clist
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetTContrast { cnum clist } {
    #---
    set ::fMRIModelView(Design,TContrast$cnum,Vector) $clist
}




#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetEVCondition
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetEVCondition { r evnum myCondition } {
    #--- if an ev (like a derivative signal) maps to a condition
    #--- number, record it here. "none" means no condition
    #--- We do this because, in order to construct the signal for this
    #--- EV, having access to the condition's onsets and durations
    #--- will be necessary.
    set ::fMRIModelView(Design,Run$r,EV$evnum,myCondition) $myCondition

}



#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetEVSignalType
# 
# .ARGS
# int r
# int evnum
# string signal
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetEVSignalType { r evnum signal } {
    #---
    set ::fMRIModelView(Design,Run$r,EV$evnum,SignalType) $signal
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewAddConditionName
# 
# .ARGS
# int r
# string cname
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewAddConditionName { r cname } {
    #---
    lappend ::fMRIModelView(Design,Run$r,ConditionNames) $cname
}



#-------------------------------------------------------------------------------
# .PROC fMRIModelViewDeleteConditionName
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewDeleteConditionName  { r cname } {

    #---
    set i [ lsearch -exact $::fMRIModelView(Design,Run$r,ConditionNames) $cname ]
    set ::fMRIModelView(Design,Run$r,ConditionNames) [ lreplace $::fMRIModelView(Design,Run$r,ConditionNames) $i $i ]

}

#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetTContrastName
# 
# .ARGS
# int cnum
# string cname
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetTContrastName {cnum cname } {
    #---
    lappend ::fMRIModelView(Design,TContrastNames) $cname
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetTContrastLabel
# 
# .ARGS
# int cnum
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetTContrastLabel { cnum } {
    #---
    # Haiying's change
    # lappend ::fMRIModelView(Design,TContrasts) "c$cnum"
    lappend ::fMRIModelView(Design,TContrasts) ""
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewGenerateEVName
#    
#     The name for ev1 derives from name of condition1;
#     condition1 name is the zero-th element in conditionnames list.
#     add to condition name some indication of signal modeling
#     that produced the EV.
#    
# .ARGS
# int evnum
# int r
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewGenerateEVName { evnum r } {
 
    #--- WJP changed 09/19/05 get the EV's condition:
    set i $::fMRIModelView(Design,Run$r,EV$evnum,myCondition)
    if { $i != "none" } {
        set i [ expr $i - 1 ]
        set basename [ lindex $::fMRIModelView(Design,Run$r,ConditionNames) $i ]
    } else {
        set basename ""
    }

    set type $::fMRIModelView(Design,Run$r,EV$evnum,SignalType)
    if { $type == "boxcar" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.boxcar"
    } elseif { $type == "boxcar_dt1" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.boxcar.dt1"
    } elseif { $type == "boxcar_dt2" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.boxcar.dt2"        
    } elseif { $type == "boxcar_cHRF" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.boxcar.HRF"
    } elseif { $type == "boxcar_cHRF_dt1" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.boxcar.HRF.dt1"
    } elseif { $type == "boxcar_cHRF_dt2" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.boxcar.HRF.dt2"
    } elseif { $type == "halfsine" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.halfsine"
    } elseif { $type == "halfsine_dt1" } {        
        lappend ::fMRIModelView(Design,evNames) "$basename.halfsine.dt1"
    } elseif { $type == "halfsine_dt2" } {        
        lappend ::fMRIModelView(Design,evNames) "$basename.halfsine.dt2"
    } elseif { $type == "halfsine_cHRF" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.halfsine.HRF"
    } elseif { $type == "halfsine_cHRF_dt1" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.halfsine.HRF.dt1"
    } elseif { $type == "halfsine_cHRF_dt2" } {
        lappend ::fMRIModelView(Design,evNames) "$basename.halfsine.HRF.dt2"
    } elseif { $type == "baseline" } {
        lappend ::fMRIModelView(Design,evNames) "baseline"
    } elseif { $type == "DCbasis0" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    } elseif { $type == "DCbasis1" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    } elseif { $type == "DCbasis2" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    } elseif { $type == "DCbasis3" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    } elseif { $type == "DCbasis4" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    } elseif { $type == "DCbasis5" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    } elseif { $type == "DCbasis6" } {
        lappend ::fMRIModelView(Design,evNames) "DCbasis"
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewGenerateEVLabel
# stick all explanatory variable lables in one list
# .ARGS
# int evnum
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewGenerateEVLabel { evnum } {
    lappend ::fMRIModelView(Design,evs) "v$evnum"
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewAddFileName
# stick all filenames in one long list
# .ARGS
# string fname
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewAddFileName { fname } {
    lappend ::fMRIModelView(Design,fileNames) $fname
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetInitialOrthogonalityDim
# optimal dimensions of the design orthogonality matrix
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetInitialOrthogonalityDim { } {
    set ::fMRIModelView(Layout,OrthogonalityDim) 120
    set ::fMRIModelView(Layout,OrthogonalityCellDim) 14
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetElementSpacing
# some little space buffers for the canvas
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetElementSpacing { } {
    set ::fMRIModelView(Layout,VSpace) 6
    set ::fMRIModelView(Layout,HSpace) 6
    set ::fMRIModelView(Layout,moreVSpace) 8
    set ::fMRIModelView(Layout,moreHSpace) 8
    set ::fMRIModelView(Layout,bigVSpace) 12
    set ::fMRIModelView(Layout,bigHSpace) 12   
    set ::fMRIModelView(Layout,hugeVSpace) 18
    set ::fMRIModelView(Layout,hugeHSpace) 18   
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeCaptionBuffers
# configure regions for captions. compute buffer requirements
# based on width of names of EVs, contrasts, and filenames
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeCaptionBuffers { } {

    #--- top buffer height is arbitrarily set; enough room for
    #--- the name of any EV to appear on rollover and a
    #--- good looking whitespace above.
    #--- buffer on top for explanatory variable name labels
    set fnt $::fMRIModelView(UI,Medfont)
    set ::fMRIModelView(Layout,EVnameBufHit) 30
    set buf [ fMRIModelViewBufFromChars $::fMRIModelView(Design,evNames) $fnt ]
    set ::fMRIModelView(Layout,EVnameBufWid) [ expr $buf + $::fMRIModelView(Layout,HSpace) ]

    #--- buffer on top for explanatory variable labels
    #--- make enough space to label ev's atop Design matrix.
    #--- give equal vertical and horizontal space for the characters.
    set fnt $::fMRIModelView(UI,Smallfont)
    set buf [ fMRIModelViewBufFromChars $::fMRIModelView(Design,evs) $fnt ]
    set ::fMRIModelView(Layout,EVBufHit) [ expr $buf + $::fMRIModelView(Layout,bigHSpace) ]
    set ::fMRIModelView(Layout,EVBufWid) [ expr $buf + $::fMRIModelView(Layout,HSpace) ]
    
    #--- buffer on the right for filenames
    set fnt $::fMRIModelView(UI,Medfont)
    set buf [ fMRIModelViewBufFromChars $::fMRIModelView(Design,fileNames) $fnt ]
    set ::fMRIModelView(Layout,FilenameBufWid) [ expr $buf + $::fMRIModelView(Layout,HSpace) ]
    
    #--- make sure buffer is at least as big as the Design Orthogonality Matrix dimension
    if { $::fMRIModelView(Layout,FilenameBufWid) < $::fMRIModelView(Layout,OrthogonalityDim) } {
        set ::fMRIModelView(Layout,FilenameBufWid) $::fMRIModelView(Layout,OrthogonalityDim) 
    }

    if { $::fMRIModelView(Design,numTContrasts) > 0 } {
        #--- buffer on the left for contrast name labels
        set buf [ fMRIModelViewBufFromChars $::fMRIModelView(Design,TContrastNames) $fnt ]
        set ::fMRIModelView(Layout,ContrastNameBufWid) [ expr $buf + $::fMRIModelView(Layout,HSpace) ]

        #--- buffer on the left for contrast labels
        set buf [ fMRIModelViewBufFromChars $::fMRIModelView(Design,TContrasts) $fnt ]
        set ::fMRIModelView(Layout,ContrastBufWid) [ expr $buf + $::fMRIModelView(Layout,HSpace) ]
    } else {
        set ::fMRIModelView(Layout,ContrastNameBufWid) $::fMRIModelView(Layout,HSpace)
        set ::fMRIModelView(Layout,ContrastBufWid) $::fMRIModelView(Layout,HSpace)
    }
    
    #--- now adjust rightmost and leftmost buffers if necessary
    #--- to ensure that explanatory variable name label fits, as
    #--- it will be centered above each column in the design matrix.
    set halfwid [ expr $::fMRIModelView(Layout,EVnameBufWid) / 2 ]
    if { $::fMRIModelView(Layout,ContrastNameBufWid) < $halfwid }  {
        set ::fMRIModelView(Layout,ContrastNameBufWid) $halfwid
    }
    if { $::fMRIModelView(Layout,FilenameBufWid) < $halfwid } {
        set ::fMRIModelView(Layout,FilenameBufWid) $halfwid
    }

}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetupLayout
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetupLayout { } {
    #---    
    #--- dimensions, in pixels, of image of each timepoint
    #--- adjust it to fit the available space.
    #---
    if { $::fMRIModelView(Design,totalTimePoints) < 150 } {
        set ::fMRIModelView(Layout,pixelsPerTimePoint) 2
    } else {
        set ::fMRIModelView(Layout,pixelsPerTimePoint) 1
    }
    #--- pixels allocated to little lines that point to
    #--- user-specified EVnames upon mouse rollover.
    set ::fMRIModelView(Layout,evLineBufHit) 4
    set ::fMRIModelView(Layout,TContrastWid) $::fMRIModelView(Layout,EVBufWid)
    set ::fMRIModelView(Layout,TContrastHit) 16
    #--- dim of save and close buttons
    set numbuttons 3
    set ::fMRIModelView(Layout,ButtonWid) 60
    set ::fMRIModelView(Layout,ButtonHit) 20
    #--- buffer below the contrast table.
    set ::fMRIModelView(Layout,botBufHit) [ expr $::fMRIModelView(Layout,OrthogonalityDim) + \
                  $::fMRIModelView(Layout,bigVSpace) ]
    
    #--- configure window size, pos, scrollregions based on content
    set ::fMRIModelView(Layout,totalWid) [ expr $::fMRIModelView(Layout,ContrastNameBufWid) + \
                                               $::fMRIModelView(Layout,ContrastBufWid) + \
                                               ($::fMRIModelView(Design,totalEVs) * \
                                                    $::fMRIModelView(Layout,EVBufWid) ) + \
                                               $::fMRIModelView(Layout,FilenameBufWid) ]
    set dmatHit [ expr $::fMRIModelView(Design,totalTimePoints) * \
                      $::fMRIModelView(Layout,pixelsPerTimePoint) ]
    set ::fMRIModelView(Layout,totalHit) [ expr $::fMRIModelView(Layout,EVnameBufHit) + \
                                               $::fMRIModelView(Layout,EVBufHit) + \
                                               $dmatHit + \
                                               ($::fMRIModelView(Design,numTContrasts) * \
                                               $::fMRIModelView(Layout,VSpace)) + \
                                               ($::fMRIModelView(Design,numTContrasts) * \
                                               $::fMRIModelView(Layout,TContrastHit)) +\
                                               $::fMRIModelView(Layout,botBufHit) ]
    set ::fMRIModelView(Layout,SaveRectTag) "fMRIModelView_saveHILO"
    set ::fMRIModelView(Layout,SaveTag) "fMRIModelView_save"
    set ::fMRIModelView(Layout,UpdateRectTag) "fMRIModelView_updateHILO"
    set ::fMRIModelView(Layout,UpdateTag) "fMRIModelView_update"
    set ::fMRIModelView(Layout,CloseRectTag) "fMRIModelView_closeHILO"
    set ::fMRIModelView(Layout,CloseTag) "fMRIModelView_close"
    set ::fMRIModelView(Layout,WaitTag) "fMRIModelView_wait"
    set totalcols $::fMRIModelView(Design,totalEVs)

    #--- make a tag for every column of the design matrix.
    #--- these will be used to trigger the display of user-specified
    #--- evnames associated with each column of the design matrix
    #--- on mouse rollover.
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set evs [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                     $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $evs } { incr i } {
            set ::fMRIModelView(Layout,EVnameTag,Run$r,$i) "fMRIModelView_evname$i$r"
            set ::fMRIModelView(Layout,dmColumnTag,Run$r,$i) "fMRIModelView_designmatCol$i$r"
        }
    }
    #--- make a tag for every filename loaded in the study.
    #--- These will be used to trigger the display of a filename
    #--- associated with a timepoint on mouse rollover.
    for { set i 0 } { $i < $::fMRIModelView(Design,totalTimePoints) } { incr i } {
        set ::fMRIModelView(Layout,FilenameTag$i) "fMRIModelView_filename$i"
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewDisplayModelView
# 
# .ARGS
# int f
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewDisplayModelView { f } {
    #---
    set c $::fMRIModelView(modelViewCanvas) 

    #--- compute layout parameters 
    set refX [ expr $::fMRIModelView(Layout,ContrastNameBufWid) + \
                   $::fMRIModelView(Layout,ContrastBufWid) ]
    set refY [ expr $::fMRIModelView(Layout,EVnameBufHit) + \
                   $::fMRIModelView(Layout,evLineBufHit) + \
                   $::fMRIModelView(Layout,EVBufHit) ]
    set dmatHit [ expr $::fMRIModelView(Layout,pixelsPerTimePoint) * \
                      $::fMRIModelView(Design,totalTimePoints) ]
    set dmatWid [ expr  ($::fMRIModelView(Design,totalEVs) * \
                             $::fMRIModelView(Layout,EVBufWid) ) ]
    set cmatHit [ expr $::fMRIModelView(Design,numTContrasts) * \
                      ($::fMRIModelView(Layout,TContrastHit) + \
                           $::fMRIModelView(Layout,VSpace)) ]
    set cmatWid $dmatWid
    set borderWid 1

    #--- draw design matrix; if model fails, bail out.
    if { ! [fMRIModelViewBuildDesignMatrix $c $refX $refY $dmatHit $dmatWid $borderWid ] } {
        return 0
    }

    #--- draw table of contrasts if there are contrasts...
    if { $::fMRIModelView(Design,numTContrasts) > 0 } {
        fMRIModelViewBuildContrastTable $c $refX $refY \
            $dmatHit $dmatWid $cmatHit $cmatWid $borderWid
    }
    fMRIModelViewSetupOrthogonalityImage $c $refX $refY \
        $dmatHit $dmatWid $cmatHit $cmatWid $borderWid

    #--- label EVs and contrasts
    fMRIModelViewLabelEVs $c $refX $refY $dmatWid
    fMRIModelViewLabelEVnames  $c $refX $refY $dmatWid 
    if { $::fMRIModelView(Design,numTContrasts) > 0 } {    
        fMRIModelViewLabelTContrasts $c $refX $refY $dmatHit $cmatHit
        fMRIModelViewLabelTContrastNames $c $refX $refY $dmatHit $cmatHit
    }
    
    #--- buttons
    fMRIModelViewSetupButtonImages $c $refX $refY \
        $dmatHit $dmatWid $cmatHit $cmatWid
    #--- make filenames surfable.
    fMRIModelViewLabelFilenames $c $refX $refY $dmatHit $dmatWid
    return 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBuildDesignMatrix
#  For each column of the design matrix, compute an 
# image that represents the EV, a list that will
# hold the signal for modeling, and a list containing
# EV data for computation.
# .ARGS
# int c
# int refX
# int refY
# int dmatHit
# int dmatWid
# int borderWid
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildDesignMatrix { c refX refY dmatHit dmatWid borderWid } {
   
    #--- Fill all matrix columns with zerogrey (which represents
    #--- signal zero, and then blit in the images at the appropriate
    #--- height in the correct design matrix column.
    #--- draw zerogrey columns with no outline.

    set x1 $refX 
    set y1 $refY 
    set y2 [expr $refY + $dmatHit ]
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                       $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $cols } { incr i } {
            set x2 [expr $x1 + $::fMRIModelView(Layout,EVBufWid) ]
            $c create rect $x1 $y1 $x2 $y2 -width 0 -fill $::fMRIModelView(Colors,hexwhite) \
                -tags "$::fMRIModelView(Layout,dmColumnTag,Run$r,$i) zeroGreyTag"
            #--- and bind.
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Enter> \
                "fMRIModelViewEVnameRollover $c $refY $i $r"
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Motion> \
                "fMRIModelViewFilenameRollover $c  $refY $dmatHit %y"
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Leave> \
                "fMRIModelViewHideRolloverInfo $c"
            #--- increment draw position
            set x1 [ expr $x1 + $::fMRIModelView(Layout,EVBufWid) ]
        }
    }
    #---
    #--- Now, compute signals, images and EVData for activation detection.
    set x1 $refX
    set y1 $refY
    set imghit [ expr $dmatHit / $::fMRIModelView(Design,numRuns) ]
    set imgwid $::fMRIModelView(Layout,EVBufWid) 

    #--- display message
    if { $::fMRIEngine(SignalModelDirty) } {
        set msgtxt "Generating model signals; may take awhile..."
        #set MsgID [ fMRIModelViewShowMessageText $msgtxt ]
    }
    
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                       $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $cols } { incr i } {
            if  { $::fMRIEngine(SignalModelDirty) } {
                set signalType $::fMRIModelView(Design,Run$r,EV$i,SignalType)
                fMRIModelViewBuildModelSignals $r $i $imghit $imgwid $signalType
                set ok [ fMRIModelViewBuildEVData  $r $i ]
                if {$ok == 0 } {
                    DevErrorWindow "Error: no model generated. Please check your inputs."
                    return 0
                }
                if { $::fMRIModelView(Layout,NoDisplay) == 0 } {
                    fMRIModelViewBuildEVImages $r $i $imgwid
                }
            }
            $c create image $x1 $y1 \
                -image $::fMRIModelView(Images,Run$r,EV$i,Image) \
                -anchor nw -tag $::fMRIModelView(Layout,dmColumnTag,Run$r,$i)
            #--- and bind.
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Enter> \
                "fMRIModelViewEVnameRollover $c $refY $i $r"
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Motion> \
                "fMRIModelViewFilenameRollover $c $refY $dmatHit %y"
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Leave> \
                "fMRIModelViewHideRolloverInfo $c"
            set x1 [ expr $x1 + $::fMRIModelView(Layout,EVBufWid) ]
        }
        set y1 [ expr $y1 + $imghit ]
    }
    if { $::fMRIEngine(SignalModelDirty) } {
        #fMRIModelViewEraseMessageText $MsgID
        set ::fMRIEngine(SignalModelDirty) 0
    }
    
    #--- kept the signal columns white during computation' now let signal zero=grey
    $c itemconfig "zeroGreyTag" -fill $::fMRIModelView(Colors,hexzeroGrey) 

    #--- delete little wait message.
    $::fMRIModelView(modelViewCanvas) delete $::fMRIModelView(Layout,WaitTag)
    update idletasks
    
    #--- draw matrix outlines
    set x1 $refX 
    set y1 $refY 
    set y2 [expr $refY + $dmatHit ]
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                       $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $cols } { incr i } {
            set x2 [expr $x1 + $::fMRIModelView(Layout,EVBufWid) ]
            $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,hexblack) \
                -width $borderWid -tag $::fMRIModelView(Layout,dmColumnTag,Run$r,$i)
            #--- and bind.
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Enter> \
                "fMRIModelViewEVnameRollover $c $refY $i $r"
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Motion> \
                "fMRIModelViewFilenameRollover $c  $refY $dmatHit %y"
            $c bind $::fMRIModelView(Layout,dmColumnTag,Run$r,$i) <Leave> \
                "fMRIModelViewHideRolloverInfo $c"
            #--- increment draw position
            set x1 [ expr $x1 + $::fMRIModelView(Layout,EVBufWid) ]
        }
    }
    return 1
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBuildEVData
# Return 1 if successful; 0 if no model can be generated.
# Create an EVdata list, filled with zeros, for computation.
# $::fMRIModelView(Design,Run$r,numTimePoints) samples in this list
# .ARGS
# int r
# int i
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildEVData { r i } {

    if { ($::fMRIModelView(Design,identicalRuns)) && ($r > 1) } {
        #--- just reuse data first Run.
        set ::fMRIModelView(Data,Run$r,EV$i,EVData) $::fMRIModelView(Data,Run1,EV$i,EVData)
        return 1
    } else {
        #--- compute new...
        set timepoints $::fMRIModelView(Design,Run$r,numTimePoints)
        #--- If there are too few timepoints, the signal processing code will break.
        #--- so let's set an adhoc minimum number of timepoints that
        #--- are required in order to generate a model and carry out an
        #--- analysis.
        if { $timepoints < 4 } {
            DevErrorWindow "An fMRI dataset must have at least 6 timepoints to be analyzed."
            return 0
        }
        for { set t 0 } { $t < $timepoints } { incr t } {
            lappend ::fMRIModelView(Data,Run$r,EV$i,EVData) 0.0
        }
        #--- see if signal exists
        set siglen [ llength $::fMRIModelView(Data,Run$r,EV$i,Signal) ]
        if { $siglen == 0 } {
            return 0
        } 
        #---
        #--- generate EVData directly when using analytic functions in model,
        #--- or by downsampling hi-res convolved, derivative signals
        set signalType $::fMRIModelView(Design,Run$r,EV$i,SignalType)
        # Gaussian downsampling for all signal types. Don't analytically generate
        # due to rounding errors for non-integer onsets and durations.
        if {0} {
            if { $signalType == "boxcar" } {
            #--- generate this analytic functions directly.
                if { [ info exists ::fMRIModelView(Design,Run$r,Condition$i,Onsets) ] } {
                    set indx 0
                    foreach onset $::fMRIModelView(Design,Run$r,Condition$i,Onsets) {
                        set duration [lindex $::fMRIModelView(Design,Run$r,Condition$i,Durations) $indx ]
                        set start $onset 
                        set len $duration
                        for { set t $start } { $t < [ expr $start + $len ] } { incr t } {
                            set ::fMRIModelView(Data,Run$r,EV$i,EVData) \
                                [ lreplace $::fMRIModelView(Data,Run$r,EV$i,EVData) $t $t 1.0 ]
                        }
                        incr indx
                    }
                } 
            } elseif { $signalType == "baseline" } {
            #--- generate this analytic functions directly.
                for { set t 0 } { $t < $timepoints } { incr t } {
                    set ::fMRIModelView(Data,Run$r,EV$i,EVData) \
                        [ lreplace $::fMRIModelView(Data,Run$r,EV$i,EVData) $t $t 1.0 ]
                }
            } elseif { $signalType == "halfsine" } {
            #--- generate this analytic functions directly.
                if { [ info exists ::fMRIModelView(Design,Run$r,Condition$i,Onsets) ] } {
                    set PI 3.14159265
                    set indx 0
                    foreach onset $::fMRIModelView(Design,Run$r,Condition$i,Onsets) {
                        set duration [lindex $::fMRIModelView(Design,Run$r,Condition$i,Durations) $indx ]
                        set start $onset 
                        set len $duration
                        set period [ expr 2 * $len ]
                        set m [ expr 2 * $PI / $period ]
                        set tau 0
                        for { set t $start } { $t < [ expr $start + $len ] } { incr t } {
                            set sineVal [ expr sin ($m * $tau) ]
                            set ::fMRIModelView(Data,Run$r,EV$i,EVData) \
                                [ lreplace $::fMRIModelView(Data,Run$r,EV$i,EVData) $t $t $sineVal ]
                            incr tau
                        }
                        incr indx
                    }
                }
            }
        } elseif { $signalType == "baseline" } {
            #--- generate this analytic functions directly.
            for { set t 0 } { $t < $timepoints } { incr t } {
                set ::fMRIModelView(Data,Run$r,EV$i,EVData) \
                    [ lreplace $::fMRIModelView(Data,Run$r,EV$i,EVData) $t $t 1.0 ]
            }
        } else {
            #--- gaussian subsample signal to make evData.
            set evlen [ expr double($::fMRIModelView(Design,Run$r,numTimePoints)) ]
            set ::fMRIModelView(Data,Run$r,EV$i,EVData) [ fMRIModelViewGaussianDownsampleList \
                $i $r $siglen $evlen $::fMRIModelView(Data,Run$r,EV$i,Signal) ]
        }
        #---
        #--- rescales range of evData to [-1.0 and 1.0]
        #---
        set max -1000000.0
        set min 100000.0
        set evlen [ llength $::fMRIModelView(Data,Run$r,EV$i,EVData) ]
        for { set t 0 } { $t < $evlen } { incr t } {
            set v [ lindex $::fMRIModelView(Data,Run$r,EV$i,EVData) $t ]
            if { $v > $max } {
                set max $v
            }
            if { $v < $min } {
                set min $v
            }
        }
        set ::fMRIModelView(Data,Run$r,EV$i,EVData) [ fMRIModelViewRangemapList  \
            $::fMRIModelView(Data,Run$r,EV$i,EVData) 1.0 0.0 ]
        return 1
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBuildEVImages
# Compute Image samples from EVData; store in a list, convert to image.
# .ARGS
# int r
# int i
# int imgw
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildEVImages { r i imgwid } {
        #--- 
        #--- Compute Image samples from EVData; store in a list, convert to image.
        #--- $::fMRIModelView(Design,Run$r,numTimePoints) samples in list.
        #--- $::fMRIModelView(Design,Run$r,numTimePoints) *
        #--- $::fMRIModelView(Layout,pixelsPerTimePoint) samples in image,
        #--- each sample in list is repeated xx(Layout,pixelsPerTimePoint) times.
        #--- 
          if { ($::fMRIModelView(Design,identicalRuns)) && ($r > 1) } {
            #--- just reuse image from first Run.
              set ::fMRIModelView(Images,Run$r,EV$i,Image) $::fMRIModelView(Images,Run1,EV$i,Image)
              #set ::fMRIModelView(Images,Run$r,EV$i,Image) [image create photo ]
              #$::fMRIModelView(Images,Run$r,EV$i,Image) copy $::fMRIModelView(Images,Run1,EV$i,Image)
          } else {
              #--- generate fresh images.
              set ::fMRIModelView(Images,Run$r,EV$i,Image) [image create photo ]
              set max -1000000.0
              set min 100000.0

              set timepoints $::fMRIModelView(Design,Run$r,numTimePoints)
              set ppt $::fMRIModelView(Layout,pixelsPerTimePoint)
              #--- create imglist from EVData; repeat each sample ppt times.
              for { set p 0 } { $p < $timepoints } { incr p } {
                  set v [ lindex $::fMRIModelView(Data,Run$r,EV$i,EVData) $p ]
                  if { $v > $max } {
                      set max $v
                  }
                  if { $v < $min } {
                      set min $v
                  }
                  for { set pp 0 } { $pp < $ppt } { incr pp } {
                      lappend imglist $v
                  }
              }
              #--- make image
              set zerogrey $::fMRIModelView(Colors,zeroGrey)
              set ilen [ expr $ppt * $timepoints ]
              #--- range map the list
              set imglist [ fMRIModelViewRangemapListForImage $min $max $ilen $imglist 255 $zerogrey  ]
              #--- generate image data
              set imagedata [ fMRIModelViewListToImage $ilen $imgwid 1 $imglist ]
              $::fMRIModelView(Images,Run$r,EV$i,Image) put $imagedata -to 0 0
              unset imglist
              unset imagedata
            }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBuildModelSignals
# Calls procs to generate appropriate signal for
# a given explanatory variable. Also creates image
# for the model viewer, if appropriate, and creates
# a list  fMRIModelView(Data,Run$r,EV$i,EVData,
# which contains the explanatory variable sampled
# at each timepoint for activation detection.
# .ARGS
# int r
# int i
# int imghit
# int imgwid
# string signalType
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildModelSignals { r i imghit imgwid signalType } {

    if { ($::fMRIModelView(Design,identicalRuns)) && ($r > 1) } {
        #--- just reuse signal from first Run.
        set ::fMRIModelView(Data,Run$r,EV$i,Signal) $::fMRIModelView(Data,Run1,EV$i,Signal)
    } else {
        #---
        #--- signal
        #--- and create a corresponding Signal list filled with zeros for actual modeling;
        #--- list has a value for each sec in the sequence, rather than only at scan timepoints.
        #--- usually this will have more samples in it than the image does.
        set samples  [ expr ($::fMRIModelView(Design,Run$r,numTimePoints) * \
                                 $::fMRIModelView(Design,Run$r,TR))  / \
                           $::fMRIModelView(Design,Run$r,TimeIncrement) ]
        #--- first zero it out.
        for { set t 0 } { $t < $samples } { incr t } {
            lappend ::fMRIModelView(Data,Run$r,EV$i,Signal) 0.0
        }
        
        #--- if this EV is associated with a user-specified condition, then insert
        #--- requested or default signal footprints into the image and signal 
        #--- where appropriate. First, find the condition it's associated with.
        set listIndex 0
        if { [ info exists ::fMRIModelView(Design,Run$r,EV$i,myCondition) ] } {
            set myCondition $::fMRIModelView(Design,Run$r,EV$i,myCondition)             
        } else {
            set myCondition "none"
        }
        #--- now, if that's a valid condition, use its duration and onsets to build basic wave
        if { [ info exists ::fMRIModelView(Design,Run$r,Condition$myCondition,Onsets) ] } {
            foreach onset $::fMRIModelView(Design,Run$r,Condition$myCondition,Onsets) {
                set duration [lindex $::fMRIModelView(Design,Run$r,Condition$myCondition,Durations) $listIndex ]
                #--- compute footprint for each event or epoch;
                #--- depending on the signal type, and insert into signal at each onset.
                set useBox [ string first "boxcar" $signalType ]
                if { $useBox >= 0 } {
                    fMRIModelViewComputeBoxCar $onset $duration $imgwid $r $i
                }
                set useSine [ string first "halfsine" $signalType ] 
                if { $useSine >= 0 } {
                    fMRIModelViewComputeHalfSine $onset $duration $imgwid $r $i
                }
                incr listIndex
            }
        }
        
        #--- Convolve with HRF if requested:
        #--- I'm computing convolution of the signal
        #--- (sampled at every time increment)
        #--- and the HRF (also sampled at every time increment),
        #--- and then downsampling the result to
        #--- generate the images (for visualizing the
        #--- model) and the lists of EVdata (sampled at
        #--- every timepoint) for now. 
        set useConv [ string first "HRF" $signalType ]
        if { $useConv >= 0 } {
            fMRIModelViewConvolveWithHRF $imgwid $imghit $r $i 
        }

        #--- Add in temporal derivatives if requested:
        #--- Here, I'm computing the derivative of
        #--- signal (sampled at every time increment)
        #--- and downsampling the result to generate
        #--- the images (for visualizing the model) and
        #--- the lists of EVdata (sampled at every
        #--- timepoint) for now.
        #--- add first derivative as an EV if requested.
        set useDerivs [ string first "dt" $signalType ]
        if { $useDerivs >= 0 } {
            fMRIModelViewAddDerivatives $imgwid $imghit $r $i            
        }
        #--- add second derivative as an EV if requested.
        set useDeriv2 [ string first "dt2" $signalType ]
        if { ($useDeriv2 >= 0) } {
            fMRIModelViewAddDerivatives $imgwid $imghit $r $i            
        }
        
        #--- add constant baseline image, signal and evdata by default?
        if { $signalType == "baseline" } {
            fMRIModelViewBuildBaseline $imgwid $imghit $r $i
        }

        #--- add DCT images, signals and evdata if requested.
        set useDCBasis [ string first "DCbasis" $signalType ]
        if { $useDCBasis == 0 } {
            set numBases $::fMRIEngine(Design,Run$r,numCosines)
            set fcutoff [ expr 1.0 / $::fMRIEngine(Design,Run$r,HighpassCutoff) ]
            set ::fMRIModelView(Design,Run$r,CosineBasisIncrement) [ expr $fcutoff / $numBases ]
            #--- a little error checking...
            if { $fcutoff <= 0 } {
                DevErrorWindow "Trend modeling cutoff frequency is invalid; model is bad."
                #--- return
            }
            set basisCount 0
            while { $basisCount < $numBases } {
                set sigName "DCbasis$basisCount"
                if { $signalType == $sigName } {
                    fMRIModelViewBuildDCBasis $imgwid $imghit $r $i [ expr $basisCount + 1 ]
                }
                incr basisCount
            }
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFindNumCosineBasis
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFindNumCosineBasis { run } {

    if { $::fMRIModelView(Design,Run$run,UseDCBasis) == 1 } {
        set N $::fMRIModelView(Design,Run$run,numTimePoints)
        set TR $::fMRIModelView(Design,Run$run,TR)
        set TC $::fMRIEngine(Design,Run$run,HighpassCutoff)
        set fc [ expr ( 1.0 / $TC ) ]
        #--- think this is right...
        #--- have cos (PI*u(2t+1) / 2N) as the basic basis functions ...
        #--- Tcutoff/TR is the cutoff period in samples.
        #--- 2PI TR / Tcutoff is max cutoff omega;
        #--- so to find out how many basis functions we need,
        #--- take (PI*u(2t+1)/2N) and pull out omega,
        #--- set it equal to cutoff omega, and solve for u.
        #--- u is the number of frequencies (basis functions) we need.
        #--- get something like this.
        set k [ expr floor ( 2.0 * $TR * $N / $TC)  ]
        #--- because we don't want the DC term (baseline models this...)
        set k [expr $k - 1]
        set ::fMRIEngine(Design,Run$run,numCosines) $k
    } else {
        set ::fMRIEngine(Design,Run$run,numCosines) 0
    }
}

    

#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBuildDCBasis
# Discrete Cosine basis functions to capture drift
# .ARGS
# int imgwid
# int imghit
# int r
# int evnum
# int freq
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildDCBasis { imgwid imghit r evnum k } {


    #--- cos ( (PI t / 2N) * (2k + 1) where k is the cos.
    set  siglen [ llength $::fMRIModelView(Data,Run$r,EV$evnum,Signal) ]
    set inc $::fMRIModelView(Design,Run$r,TimeIncrement)
    set N [ expr $::fMRIModelView(Design,Run$r,numTimePoints) * \
                $::fMRIModelView(Design,Run$r,TR) ]
    set t 0.0
    for { set y 0 } { $y < $siglen} { incr y } {
        set v [ expr cos ( (3.14159 * (2.0 * $t + 1.0) * $k / (2.0 * $N)) ) ]

        if { $t == 0.0 } {
            set v [ expr $v / sqrt (2.0) ]
        }
        set ::fMRIModelView(Data,Run$r,EV$evnum,Signal) \
            [ lreplace $::fMRIModelView(Data,Run$r,EV$evnum,Signal) $y $y $v ]
        set t [ expr $t + $inc ]
    }

}





#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLongestEpochSpacing
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLongestEpochSpacing { r } {

    #---
    set T 0.0
    #--- wjp 10/17/05 compute longest epoch in this run.
    if { ( [ info exists ::fMRIModelView(Design,numRuns) ] ) &&
         ( [ info exists ::fMRIModelView(Design,Run$r,numConditions) ] ) &&
         ( [ info exists ::fMRIModelView(Design,Run$r,Condition1,Onsets) ] ) &&
         ( [ info exists ::fMRIModelView(Design,Run$r,TR) ] ) } {

        for { set c 1 } { $c <= $::fMRIModelView(Design,Run$r,numConditions) } { incr c } {
            #--- compute interval between epochs in seconds
            set lastOnset 0
            set i 0
            foreach onset $::fMRIModelView(Design,Run$r,Condition$c,Onsets) {
                set thisOnset [ lindex $::fMRIModelView(Design,Run$r,Condition$c,Onsets) $i ]
                set diff [ expr $::fMRIModelView(Design,Run$r,TR) * ($thisOnset - $lastOnset) ]
                if { $diff > $T } {
                    set T $diff
                }
                set lastOnset $thisOnset
                incr i
            }
        }
        set ::fMRIModelView(Design,Run$r,longestEpoch) $T
        return 1
    } else {
        DevErrorWindow "Specify run(s) and condition(s) before modeling."
        return 0
    }

}







#-------------------------------------------------------------------------------

# .PROC fMRIModelViewBuildBaseline
# build a constant basis function to capture baseline.
# signal first
# .ARGS
# int imgwid
# int imghit
# int r
# int evnum
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildBaseline { imgwid imghit r evnum } {
    #---
    set min 0.0
    set max 1.0
    set signaldim [ expr ($::fMRIModelView(Design,Run$r,numTimePoints) * \
                        $::fMRIModelView(Design,Run$r,TR)) / \
                        $::fMRIModelView(Design,Run$r,TimeIncrement) ]

    #--- build a constant basis function to capture baseline.
    #--- signal first
    for { set y 0 } { $y < $signaldim } { incr y } {
        lappend ::fMRIModelView(Data,Run$r,EV$evnum,Signal) 1.0
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeBoxCar
# what row of the image should this footprint begin on?
# and how many rows of the image should this footprint span?
# .ARGS
# int onset
# int duration
# int imgwid
# int r
# int i
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeBoxCar { onset duration imgwid r i } {
    #---
    #--- what row of the image should this footprint begin on?
    #--- and how many rows of the image should this footprint span?
    #---
    set ystart [ expr $onset * $::fMRIModelView(Layout,pixelsPerTimePoint) ]
    set imghit [ expr $duration * $::fMRIModelView(Layout,pixelsPerTimePoint) ]

    #--- what second of the signal should this footprint begin on?
    #--- andhow many seconds should the signal footprintspan?
    set sigstart  [ expr ($onset * $::fMRIModelView(Design,Run$r,TR)) / \
                       $::fMRIModelView(Design,Run$r,TimeIncrement) ]
    set sigLen [ expr ($duration * $::fMRIModelView(Design,Run$r,TR)) / \
                     $::fMRIModelView(Design,Run$r,TimeIncrement) ]
    
    #--- compute a boxcar signal footprint and insert into signal list
    #--- boxcar signal goes from 0.0 to 1.0
    #--- if event-related or mixed design, footprint might be delta function.
    #--- In that case, we molde duration as one TimeIncrement.
    set sigstart [ expr round($sigstart) ]
    if { $sigLen == 0.0 } {
        set sigLen 1.0
    } else {
        set sigLen [ expr round ($sigLen) ]
    }

    for { set t $sigstart } { $t < [ expr $sigstart + $sigLen ] } { incr t } {
        set ::fMRIModelView(Data,Run$r,EV$i,Signal) [ lreplace $::fMRIModelView(Data,Run$r,EV$i,Signal) $t $t 1.0 ]
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeHalfSine
# what row of the image should this footprint begin on?
# and how many rows of the image should this footprint span?
# .ARGS
# int onset
# int duration
# int imgwid
# int r
# int i
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeHalfSine { onset duration imgwid r i } {

    set ystart [ expr $onset * $::fMRIModelView(Layout,pixelsPerTimePoint) ]
    set imghit [ expr $duration * $::fMRIModelView(Layout,pixelsPerTimePoint) ]

    #--- what second of the signal should this footprint begin on?
    #--- andhow many seconds should the signal footprintspan?
    set sigstart  [ expr ($onset * $::fMRIModelView(Design,Run$r,TR)) / \
                       $::fMRIModelView(Design,Run$r,TimeIncrement) ]
    set sigLen [ expr ($duration * $::fMRIModelView(Design,Run$r,TR)) / \
                    $::fMRIModelView(Design,Run$r,TimeIncrement) ]
    set PI 3.14159265
    set period [ expr 2 * $sigLen ]
    #--- if period is zero, then duration is zero. Just return the signal
    #--- filled with zeros.
    if { $period != 0.0 } {
        set m [ expr 2 * $PI / $period ]
        set tau 0
        #--- signal:
        #--- compute a half-sine signal footprint and insert into signal list
        #--- signal values vary between 0.0 and 1.0
        #--- if event-related or mixed design, footprint might be delta function.
        #--- In that case, we molde duration as one TimeIncrement.
        set sigstart [ expr round($sigstart) ]
        if { $sigLen == 0.0 } {
            set sigLen 1.0
        } else {
            set sigLen [ expr round ($sigLen) ]
        }
        for { set t $sigstart } { $t < [ expr $sigstart + $sigLen ] } { incr t } {
            set v [ expr sin ($m * $tau ) ]
            set ::fMRIModelView(Data,Run$r,EV$i,Signal) [ lreplace $::fMRIModelView(Data,Run$r,EV$i,Signal) $t $t $v ]
            set tau [ expr $tau + $::fMRIModelView(Design,Run$r,TimeIncrement) ]
        }
    } else {

    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeHRF
# computes a single HRF for each run.
# compute HRF as difference of two gammas,
# .ARGS
# int r
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeHRF { r } {
    #---
    #--- computes a single HRF for each run.
    #--- compute HRF as difference of two gammas,
    #--- as recommended in:  G.H. Glover, "Deconvolultion
    #--- of impulse response in event-related BOLD fMRI",
    #--- Neuroimage 9, 416-29. (using parameters below).
    #--- Sample function $HRFsamps times from t=0 to 30secs.
    #--- 30 seconds seems to make the gammas come to peak,
    #--- dip below zero and then come back to baseline.
    #---
    if { ! [info exists ::fMRIModelView(Design,Run$r,HRF) ] } {
        set tinc $::fMRIModelView(Design,Run$r,TimeIncrement) 
        set seemsEnough [ expr 30.0 / $tinc ]
        set HRFsamps [ expr round ($seemsEnough) ]
        set a1 6
        set a2 12
        set b1 0.9
        set b2 0.9
        set c 0.35
        set d1 [ expr $a1 * $b1 ]
        set d2 [ expr $a2 * $b2 ]
        
        #--- compute first gamma function g1
        set t 0
        for { set x 0 } { $x < $HRFsamps } { incr x } {
            set v [ expr pow( ($t / $d1), $d1) * exp( -($t-$d1) / $b1 ) ]
            lappend g1 $v
            set t [ expr $t + $tinc ]
        }

        #--- compute second gamma function g2
        set t 0
        for { set x 0 } { $x < $HRFsamps } { incr x } {
            set v [ expr pow( ($t / $d2), $d2) * exp( -($t-$d2) / $b2 ) ]
            lappend g2 $v
            set t [ expr $t + $tinc ]
        }

        #--- set h as difference of g1 and g2
        set max -100000.0
        set min 100000.0
        for { set x 0 } { $x < $HRFsamps } { incr x } {
            set v1 [ lindex $g1 $x ] 
            set v2 [ lindex $g2 $x ]
            set v [ expr $v1 - ($c * $v2) ]
            if { $v > $max } {
                set max $v
            }
            if {$v < $min } {
                set min $v
            }
            lappend HRF $v
        }    

        unset g1
        unset g2

        # flip HRF for convolution
        set end [ expr $HRFsamps - 1 ]
        for { set x $end } { $x >= 0 } { set x [ expr $x - 1] } {
            set v [ lindex $HRF $x ]
            lappend flipHRF $v
        }
        unset HRF

        set ::fMRIModelView(Design,Run$r,HRF) $flipHRF
    }
    return $::fMRIModelView(Design,Run$r,HRF)
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewConvolveWithHRF
# Convolve image with canonical hemodynamic response
# .ARGS
# int imgwid
# int imghit
# int run
# int evnum
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewConvolveWithHRF { imgwid imghit run evnum } {
    #---
    #--- Convolve image with canonical hemodynamic response
    #--- HRF swings between -1.0 and 1.0
    #--- want to convolve this with the signal
    #--- which also swings from -1.0 to 1.0.
    #--- Do this in the following way:
    #--- 1. get or compute the flipped HRF
    #--- 2. use the signal list, which contains a
    #---     sample for every time increment,
    #---     as does the HRF.
    #--- 3. zeropad signal on both ends for convolution
    #--- 4. convolve HRF with data
    #--- 5. save signal 
    #---    
    #--- 1: compute or get flipped HRF
    set HRF [ fMRIModelViewComputeHRF $run ]
    set HRFsamps [ llength $HRF ]

    #--- 2&3: make zeropadded signal list
    set negvals 0
    set posvals $HRFsamps    
    set len [ llength $::fMRIModelView(Data,Run$run,EV$evnum,Signal) ]
    for { set t 0 } { $t < $posvals } { incr t } {
        #--- zero pad
        lappend data 0.0
    }
    for { set t 0 } { $t < $len } { incr t } {
        #--- data from image
        set v [ lindex $::fMRIModelView(Data,Run$run,EV$evnum,Signal) $t ]
        lappend data $v
    }
    for { set t 0 } { $t < $negvals } { incr t } {
        #--- zero pad
        lappend data 0.0
    }

    #--- 4: convolve
    #--- start at first samp of $data; shift $HRF;
    #--- compute imghit + $posvals shifts and function mults;
    #--- append each function multiply to $convResult.
    set shift 0
    for { set y $posvals } { $y < [ expr $len + $posvals ] } { incr y } {
        set sum 0
        for { set s 0 } { $s < $HRFsamps } { incr s } {
            set sval [ lindex $data [ expr $s + $shift ] ]                            
            set hval [ lindex $HRF $s ]
            set sum [ expr $sum + ($sval * $hval) ]
        }
        lappend convResult $sum
        incr shift
    }
    unset data

    #--- 5: save signal
    set ::fMRIModelView(Data,Run$run,EV$evnum,Signal) $convResult
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewAddDerivatives
# computes derivative of Signal
# and downsamples to generate image
# compute new Signal from the Signal List
# .ARGS
# int imgwid
# int imghit
# int r
# int evnum
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewAddDerivatives { imgwid imghit r evnum } {
    #---    
    #--- computes derivative of Signal
    #--- and downsamples to generate image
    #--- compute new Signal from the Signal List
    #---
    set dt $::fMRIModelView(Design,Run$r,TimeIncrement)
    set sigLen [ expr ($::fMRIModelView(Design,Run$r,numTimePoints) * \
                     $::fMRIModelView(Design,Run$r,TR)) / \
                     $::fMRIModelView(Design,Run$r,TimeIncrement) ]

    #--- march thru the signal;
    #--- sample it, compute derivative, and
    #--- and create a new signal. 
    for { set y 0 } { $y < $sigLen } { incr y } {
        #--- last timepoint
        if { $y == 0 } {
            set lastsamp 0.0
        } else {
            set ylast [ expr $y - 1 ]
            set lastsamp [ lindex $::fMRIModelView(Data,Run$r,EV$evnum,Signal) $ylast ]        
        }        
        #--- current timepoint
        set thissamp [ lindex $::fMRIModelView(Data,Run$r,EV$evnum,Signal) $y ]        
        #--- next timepoint
        if { $y == [ expr $sigLen - 1 ] } {
            set nextsamp 0.0
        } else {
            set ynext [ expr $y + 1]
            set nextsamp [ lindex $::fMRIModelView(Data,Run$r,EV$evnum,Signal) $ynext ]        
        }
        #--- compute derivative 
        set deriv [ expr ( ($thissamp - $lastsamp) + ($nextsamp - $thissamp)) / $dt ]
        #--- use this value for newval if need to add
        #--- the derivative to the waveform to create EV.
        #set newval [ expr  $thissamp - $deriv ]
        #--- use this value for newval if need to use
        #--- the derivatives directly in the design matrix.
        set newval $deriv
        lappend derivData $newval
    }

    #--- fill the Signal List
    set ::fMRIModelView(Data,Run$r,EV$evnum,Signal) $derivData
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeGaussianFilter
# Computes a gaussian kernel for convolution
# .ARGS
# int r
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeGaussianFilter { r } {
    #---
    #--- Computes a gaussian kernel for convolution
    #--- Define the filter's cutoff frequency fmax = 1/2*TR,
    #--- or to be more careful, 1/2.01*TR,
    #--- and wmax = 2pi * fmax = numsigmas*sigma.
    #--- where numsigmas = 2.0 or 3.0,
    #--- and numsigmas * sigma defines the half-band
    #--- in the frequency domain.
    #---
    #--- use g(t) = 1/(sqrt(2pi)sigma) * exp ( -t^2 / 2sigma^2)
    #--- sigma = 2pi * fmax / numsigmas.
    #--- sigma = 2pi / (2.01*TR*numsigmas).
    #---
    #--- Assumes that all explanatory variables within a run
    #--- have the same TR.
    #---
    #--- wjp 11/21/05
    #--- The signal we're filtering has sampling freq = fs = 1/0.1sec
    #--- downsampling to a signal with sampling freq 1/TRsec.
    #--- to signal with fmax = 1/2*TRsec

    set nyquistbuffer 2.001
    if { ! [ info exists ::fMRIModelView(Design,Run$r,GaussianFilter) ] } {
        set TR $::fMRIModelView(Design,Run$r,TR)
        set PI 3.14159265
        set fmax [ expr ( 1.0 / ($nyquistbuffer * $TR)) ]
        #--- use 3 sigmas out for the kernel size (cutoff) now, 
        #--- where gaussian approaches zero...
        set numsigmas 3.0
        #--- try setting 2PI fmax = FWHM of the gaussian.
        #--- so sigma = FWHM/(2*sqrt(2ln(2)))
        set numsigmas 2.3548
        set sigma [ expr 2.0 * $PI * $fmax / $numsigmas ]
        
        #--- how many samples of the time-domain kernel do
        #--- we need? 
        set inc $::fMRIModelView(Design,Run$r,TimeIncrement)
        set numsamps  [ expr $TR + $inc ]

        #--- now compute the gaussian to convolve with.

        set twoSigmaSq [ expr $sigma * $sigma * 2.0]
        set twoPI [ expr $PI * $PI]
        set sqrtTwoPI [ expr (sqrt ($twoPI) ) ]

        for {set t -$numsamps } { $t <= $numsamps } { set t [ expr $t + $inc] } {
            set v [ expr ( (1.0 / ($sigma * $sqrtTwoPI)) * (exp (-($t*$t) / $twoSigmaSq))) ]
            lappend kernel $v
        }

        #--- save the filter we used for downsampling this run
        set ::fMRIModelView(Design,Run$r,GaussianFilter) $kernel
    }
    return $::fMRIModelView(Design,Run$r,GaussianFilter) 
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewGaussianDownsampleList
# takes a list in, subsamples it to a new length
# and returns the new list.
# .ARGS
# int i
# int r
# int olen
# int nlen
# list inputList
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewGaussianDownsampleList { i r olen nlen inputList } {
    #---
    #--- takes a list in, subsamples it to a new length
    #--- and returns the new list.
    #---
    #--- get or generate filter and find out its length
    #--- *notice we are expecting inc to be an integer!
    #--- so we never land between pixels when downsampling.
    set Gkernel [ fMRIModelViewComputeGaussianFilter $r ]
    set numsamps [ llength $Gkernel ]
    set half [ expr floor ($numsamps / 2) ]
    set inc [ expr $olen / $nlen ]

    #--- what if no downsampling is required!
    if { $inc == 1.0 } {
        return $inputList
    }

    #---filter and subsample
    for { set t 0 } { $t < $olen } { set t [ expr $t + $inc] } {
        if { $t < $half  } {
            set start [ expr $half - $t ]
            set stop [ expr $numsamps - 1 ]
        } elseif { $t > [expr $olen - ($half + 1) ] } {
            set start 0
            set stop [ expr $half + ($olen - 1 - $t ) ]
        } else {
            set start 0
            set stop [ expr $numsamps - 1 ]
        }
        set sum 0.0
        for { set j $start } { $j <= $stop } { incr j } {
            set k [ expr  round ( $t - $half + $j ) ]
            set j [ expr round ($j) ]
            set v1 [ lindex $inputList $k ]
            set v2 [ lindex $Gkernel $j ]
            set sum [ expr $sum + ($v1 * $v2) ]
        }
        lappend evlist [ expr $sum / double ($numsamps) ]
    }
    return $evlist
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewRangemapList
# compute $data's positive range (>0)
# and $data's negative range (<0)
# see which range is bigger;
# normalize to the size of bigger range
# so output list ranges between [-1.0 to 1.0]
# .ARGS
# list data
# float finalRangeMax
# float finalRangeMid
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewRangemapList { data  finalRangeMax finalRangeMid } {
   
    set max -1000000.0
    set min 100000.0
    set dim [ llength $data ]
    for { set t 0 } { $t < $dim } { incr t } {
        set v [ lindex $data $t ]
        if { $v > $max } {
            set max $v
        }
        if { $v < $min } {
            set min $v
        }
    }

    set min [ expr double($min) ]
    set max [ expr double($max) ]
    if { $max >= 0.0 } {
        set posrange $max
    } else {
        set posrange 0.0
    }
    if { $min <= 0.0 } {
        set negrange $min
    } else {
        set negrange 0.0
    }
    set absprange [ expr abs ($posrange) ]
    set absnrange [ expr abs ($negrange) ]
    
    if { $absprange > $absnrange } {
        #--- normalize to positive half
        set range $absprange
    } elseif { $absnrange > $absprange } {
        #--- normalize to negative half
        set range $absnrange
    } elseif {$absnrange == $absprange } {
        #--- either value will work
        set range $absprange
    }

    #--- normalize
    for { set i 0 } { $i < $dim } { incr i } {
        set v [ lindex $data $i ]
        if { $range != 0.0 } {
            set nv [ expr $v/$range ]
        } else {
            set nv 0.0
        }
        set data [ lreplace $data $i $i $nv ]
    }
    return $data
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewRangemapListForImage
# In the image, we need zerogrey to correspond to signal zero.
# Input list varies between [ -1.0 to 1.0 ]
# Output list should vary between [0.0 to 255.0] with 
# $finalRangeMid corresponding to input zero.
# .ARGS
# float min
# float max
# int dim
# list data
# float finalRangeMax
# float finalRangeMid
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewRangemapListForImage { min max dim data  finalRangeMax finalRangeMid } {

    set halfrange [ expr ($finalRangeMax - $finalRangeMid) - 1.0 ]
    for { set i 0 } { $i < $dim } { incr i } {
        set v [ lindex $data $i ]
        set nv [ expr ($v * $halfrange) + $halfrange ]
        set data [ lreplace $data $i $i $nv ]
    }
    return $data
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewListToImage
# converts a list of values from [ 0 to 255] into an image
# by replicating each list element along a new row.
# .ARGS
# int imghit
# int imgwid
# int rowrun
# list lst
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewListToImage { imghit imgwid rowrun lst } {

    for { set y 0 } { $y < [ expr $imghit / $rowrun ] } { incr y } {
        set v [ lindex $lst $y ]
        set v [ expr round ($v) ]
        set hexval [ format "#%02x%02x%02x" $v $v $v ]
        #--- add to image.
        for { set row 0 } { $row < $rowrun } { incr row } {
            if { [info exists rowdata ] } { unset rowdata } 
            for { set x 0 } { $x < $imgwid } { incr x } {
                lappend rowdata $hexval
            }
            lappend newimage $rowdata
        }
    }
    unset rowdata
    return $newimage
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeDotProduct
# takes dot product of two vectors of equal len
# .ARGS
# list v1
# list v2
# int len
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeDotProduct { v1 v2 len } {

    set dot 0.0
    for { set i 0 } { $i < $len } { incr i } {
        set a [ lindex $v1 $i ]
        set b [ lindex $v2 $i ]
        set dot [ expr $dot + ( $a * $b) ]
    }
    return $dot
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewComputeVectorMagnitude
#  computes magnitude of vector in a list
# .ARGS
# list v
# int len
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewComputeVectorMagnitude { v len } {

    set mag 0.0
    for { set i 0 } { $i < $len } { incr i } {
        set a [ lindex $v $i ]
        set mag [ expr $mag + ($a * $a) ]
    }
    set mag [ expr double ($mag) ]
    set mag [ expr sqrt ($mag) ]
    return $mag
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBuildContrastTable
# For each contrast, populate the
# contrast area of canvas.
# draw grid AND zero-line thru center of each region.
# .ARGS
# int c 
# int refX
# int refY 
# int dmatHit 
# int dmatWid 
# int cmatHit 
# int cmatWid 
# int borderWid 
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBuildContrastTable { c refX refY dmatHit dmatWid cmatHit cmatWid borderWid } {
    
    #--- ...first compactify a little
    #---
    set v $::fMRIModelView(Layout,VSpace)
    set cH $::fMRIModelView(Layout,TContrastHit)
    set cW $::fMRIModelView(Layout,TContrastWid)
    set hit [ expr $cH + $v ]
    set halfhit [ expr round ($hit / 2.0) ]
    set halfcH [ expr round ($cH / 2.0) ]

    set cols $::fMRIModelView(Design,totalEVs)
    #--- draw T-contrast blocks
    for { set i 1 } { $i <= $::fMRIModelView(Design,numTContrasts) } { incr i } {
        for { set index 0 } { $index < $cols } { incr index } {
            set val [ lindex $::fMRIModelView(Design,TContrast$i,Vector) $index ]
            #--- val is either 1, -1 or zero.
            set x1 [ expr $refX + ( $index * $cW) ]
            set x2 [ expr $x1 + $cW ]
            set y1 [ expr $refY + $dmatHit + $v + ( ($i-1) * $hit ) + $halfhit ]
            set y2 [ expr $y1 + ( -$val * $halfcH ) ]
            $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,liteGrey) \
                -width 0 -fill $::fMRIModelView(Colors,contrastRect)
        }
    }
    
    #--- draw horizontal axes:
    set x1 $refX
    set x2 [ expr $x1 + $cmatWid ]
    set y1 [ expr $refY + $dmatHit +  $v ]
    set y2 [ expr $y1 + $cmatHit ]
    for { set i 0 } { $i < $::fMRIModelView(Design,numTContrasts) } { incr i } {
        set y [ expr $y1 + ( $i * $hit ) + $halfhit ]
        $c create line $x1 $y $x2 $y -width 1 -fill $::fMRIModelView(Colors,contrastRect) 
    }

    #--- draw vertical grid markers
    for { set i 0} { $i < $cols } { incr i } {
        set x1 [expr $refX + $i * $cW ]
        $c create line $x1 $y1 $x1 $y2 -width 1 -fill $::fMRIModelView(Colors,liteGrey) 
    }

    #--- draw horizonal demarcations between contrasts
    set x1 $refX
    for { set i 0 } { $i < $::fMRIModelView(Design,numTContrasts) } { incr i } {
        set y [ expr $y1 + ( $i * $hit) ]
        $c create line $x1 $y $x2 $y -width 1 -fill $::fMRIModelView(Colors,hexblack) 
    }

    #--- draw surrounding rect:
    $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,hexblack) \
        -width $borderWid 
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewBufFromChars
# This routine takes in a list of strings and a fontsize
# and figures out how big the pixel buffer should be
# to display it. Used in auto-configuration of a canvas.
# .ARGS
# list thinglist
# string whichfont
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewBufFromChars { thinglist whichfont } {

    set maxchars 0
    set length [ llength $thinglist ]
    
    for { set i 0 } { $i < $length } { incr i } {
        set thing [ lindex $thinglist $i ]
        set numchars [ string length $thing ]
        if { $numchars > $maxchars } {
            set maxchars $numchars
        }
    }

    #--- determine a pixelspace that will
    #--- accommodate the characters.
    #--- I am guessing about the number of pixels
    #--- to allocate for each character.
    #--- is there a better way to do this?
    #--- one point (printer's point) should = 1/72 inch.
    #--- is there a way to determine display size and
    #--- pixel res, and convert xpoints = 1/72" * pixels/inch?
    if { $whichfont == $::fMRIModelView(UI,Bigfont) } {
        set pix 6
        set buf [ expr $maxchars * $pix + $::fMRIModelView(Layout,HSpace) ]
    } elseif { $whichfont == $::fMRIModelView(UI,Medfont) } {
        set pix 5
        set buf [ expr $maxchars * $pix + $::fMRIModelView(Layout,HSpace) ]
    } elseif { $whichfont == $::fMRIModelView(UI,Smallfont) } {
        set pix 4
        set buf [ expr $maxchars * $pix + $::fMRIModelView(Layout,HSpace) ]
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewScrolledCanvas
# 
# .ARGS
# windowpath f
# list args
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewScrolledCanvas { f args } {
    #---
    frame $f
    $f configure -background $::fMRIModelView(Colors,hexwhite)
    eval { canvas $f.cDesignMatrix \
               -highlightbackground $::fMRIModelView(Colors,activeBkg) \
               -highlightcolor $::fMRIModelView(Colors,activeBkg) \
               -yscrollcommand [list $f.yscroll set ] \
               -xscrollcommand [list  $f.xscroll set ] } $args
    scrollbar $f.yscroll -orient vertical -highlightthickness 0 \
        -borderwidth 0 -elementborderwidth 1 -command [ list $f.cDesignMatrix yview ] \
        -background $::fMRIModelView(Colors,activeBkg) \
        -activebackground $::fMRIModelView(Colors,activeBkg) 
    scrollbar $f.xscroll -orient horizontal -highlightthickness 0 \
        -borderwidth 0 -elementborderwidth 1 -command [ list $f.cDesignMatrix xview ] \
        -background $::fMRIModelView(Colors,activeBkg) \
        -activebackground $::fMRIModelView(Colors,activeBkg) \

    grid $f.cDesignMatrix $f.yscroll -sticky news
    grid $f.xscroll -sticky ew
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1
    
    set ::fMRIModelView(modelViewFrame) $f
    set ::fMRIModelView(modelViewCanvas) $f.cDesignMatrix
    return $f.cDesignMatrix
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetFonts
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetFonts { } {
    # Haiying's change ---
    # option add "*font" "-Adobe-Helvetica-Bold-R-Normal-*-12-*-*-*-*-*-*-*"
    # option add "*font" "-Adobe-Helvetica-Bold-R-Normal-*-10-*-*-*-*-*-*-*"
    # option add "*font" "-Adobe-Helvetica-Bold-R-Normal-*-8-*-*-*-*-*-*-*"
    set ::fMRIModelView(UI,Bigfont) "-Adobe-Helvetica-Bold-R-Normal-*-12-*-*-*-*-*-*-*"
    set ::fMRIModelView(UI,Medfont) "-Adobe-Helvetica-Bold-R-Normal-*-10-*-*-*-*-*-*-*"
    set ::fMRIModelView(UI,Smallfont) "-Adobe-Helvetica-Bold-R-Normal-*-8-*-*-*-*-*-*-*"      
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetColors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetColors { } {
    #---
    set ::fMRIModelView(Colors,bkg) #FFFFFF
    set ::fMRIModelView(Colors,activeBkg) #DDDDDD
    set ::fMRIModelView(Colors,black) 0
    set ::fMRIModelView(Colors,hexblack) #000000
    set ::fMRIModelView(Colors,white) 255
    set ::fMRIModelView(Colors,hexwhite) #FFFFFF
    set ::fMRIModelView(Colors,liteGrey) #AAAAAA
    set ::fMRIModelView(Colors,darkGrey) #333333
    set ::fMRIModelView(Colors,zeroGrey) 127
    set ::fMRIModelView(Colors,hexzeroGrey) #7F7F7F
    set ::fMRIModelView(Colors,contrastRect) #77BB44
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetupButtonImages
# xy dimensions:
# leave one button-height worth of space between
# buttons and the table of contrasts.
# .ARGS
# int c 
# int refX 
# int refY 
# int dmatHit 
# int dmatWid 
# int cmatHit 
# int cmatWid 
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetupButtonImages { c refX refY dmatHit dmatWid cmatHit cmatWid }  {

    set x2 [ expr $refX + $dmatWid ]
    set y1 [ expr $refY +  $dmatHit + $cmatHit + $::fMRIModelView(Layout,ButtonHit) ]
    set $::fMRIModelView(Layout,ButtonWid) $::fMRIModelView(Layout,OrthogonalityDim)
    set x1 [ expr $x2 - $::fMRIModelView(Layout,ButtonWid) ]
    set y2 [ expr $y1 + $::fMRIModelView(Layout,ButtonHit) ]
    set xtext [ expr $x1 + ($::fMRIModelView(Layout,ButtonWid) / 2 ) ]
    set ytext [ expr $y1 + ( $::fMRIModelView(Layout,ButtonHit) / 2 ) ]
    
    #--- draw surrounding SAVE rect and text; tag...
    $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,liteGrey) \
        -width 1 -fill $::fMRIModelView(Colors,hexwhite) \
        -tag $::fMRIModelView(Layout,UpdateRectTag)
    $c create text  $xtext $ytext -text "refresh" -anchor center \
        -font $::fMRIModelView(UI,Smallfont) \
        -tag $::fMRIModelView(Layout,UpdateTag)
    #--- and bind.
    $c bind $::fMRIModelView(Layout,UpdateTag) <Enter> \
        "%W itemconfig $::fMRIModelView(Layout,UpdateRectTag) -outline $::fMRIModelView(Colors,hexblack) "
    $c bind $::fMRIModelView(Layout,UpdateTag) <Leave> \
        "%W itemconfig $::fMRIModelView(Layout,UpdateRectTag) -outline $::fMRIModelView(Colors,liteGrey) "
    $c bind $::fMRIModelView(Layout,UpdateTag) <Button-1> "fMRIModelViewCatchGenerateModel" 

    $c bind $::fMRIModelView(Layout,UpdateRectTag) <Enter> \
        "%W itemconfig $::fMRIModelView(Layout,UpdateRectTag) -outline $::fMRIModelView(Colors,hexblack) "
    $c bind $::fMRIModelView(Layout,UpdateRectTag) <Leave> \
        "%W itemconfig $::fMRIModelView(Layout,UpdateRectTag) -outline $::fMRIModelView(Colors,liteGrey) "
    $c bind $::fMRIModelView(Layout,UpdateRectTag) <Button-1> "fMRIModelViewCatchGenerateModel" 

    #--- draw surrounding CLOSE rect and text; tag...
    set y1 [ expr $y2 + $::fMRIModelView(Layout,VSpace) ]
    set y2 [ expr $y1 + $::fMRIModelView(Layout,ButtonHit) ]
    set ytext [ expr $y1 + ( $::fMRIModelView(Layout,ButtonHit) / 2 ) ]
    $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,liteGrey) \
        -width 1 -fill $::fMRIModelView(Colors,hexwhite) \
        -tag $::fMRIModelView(Layout,SaveRectTag)
    $c create text  $xtext $ytext -text "save ps" -anchor center \
        -font $::fMRIModelView(UI,Smallfont) \
        -tag $::fMRIModelView(Layout,SaveTag)
    #--- and bind.
    $c bind $::fMRIModelView(Layout,SaveTag) <Enter> \
        "%W itemconfig $::fMRIModelView(Layout,SaveRectTag) -outline $::fMRIModelView(Colors,hexblack) "
    $c bind $::fMRIModelView(Layout,SaveTag) <Leave> \
        "%W itemconfig $::fMRIModelView(Layout,SaveRectTag) -outline $::fMRIModelView(Colors,liteGrey) "
    #--- WJP changed 4/13/05
    $c bind $::fMRIModelView(Layout,SaveTag) <Button-1> "fMRIModelViewSaveModelPostscriptPopup"

    $c bind $::fMRIModelView(Layout,SaveRectTag) <Enter> \
        "%W itemconfig $::fMRIModelView(Layout,SaveRectTag) -outline $::fMRIModelView(Colors,hexblack) "
    $c bind $::fMRIModelView(Layout,SaveRectTag) <Leave> \
        "%W itemconfig $::fMRIModelView(Layout,SaveRectTag) -outline $::fMRIModelView(Colors,liteGrey) "
    #--- WJP changed 4/13/05
    $c bind $::fMRIModelView(Layout,SaveRectTag) <Button-1> "fMRIModelViewSaveModelPostscriptPopup"

    #--- draw surrounding CLOSE rect and text; tag...
    set y1 [ expr $y2 + $::fMRIModelView(Layout,VSpace) ]
    set y2 [ expr $y1 + $::fMRIModelView(Layout,ButtonHit) ]
    set ytext [ expr $y1 + ( $::fMRIModelView(Layout,ButtonHit) / 2 ) ]
    $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,liteGrey) \
        -width 1 -fill $::fMRIModelView(Colors,hexwhite) \
        -tag $::fMRIModelView(Layout,CloseRectTag)
    $c create text  $xtext $ytext -text "close" -anchor center \
        -font $::fMRIModelView(UI,Smallfont) \
        -tag $::fMRIModelView(Layout,CloseTag)
    #--- and bind.
    $c bind $::fMRIModelView(Layout,CloseTag) <Enter> \
        "%W itemconfig $::fMRIModelView(Layout,CloseRectTag) -outline $::fMRIModelView(Colors,hexblack) "
    $c bind $::fMRIModelView(Layout,CloseTag) <Leave> \
        "%W itemconfig $::fMRIModelView(Layout,CloseRectTag) -outline $::fMRIModelView(Colors,liteGrey) "
    $c bind $::fMRIModelView(Layout,CloseTag) <Button-1> "fMRIModelViewCloseAndCleanNoRegeneration"

    $c bind $::fMRIModelView(Layout,CloseRectTag) <Enter> \
        "%W itemconfig $::fMRIModelView(Layout,CloseRectTag) -outline $::fMRIModelView(Colors,hexblack) "
    $c bind $::fMRIModelView(Layout,CloseRectTag) <Leave> \
        "%W itemconfig $::fMRIModelView(Layout,CloseRectTag) -outline $::fMRIModelView(Colors,liteGrey) "
    $c bind $::fMRIModelView(Layout,CloseRectTag) <Button-1> "fMRIModelViewCloseAndCleanNoRegeneration"

}



#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSaveModelPostscript
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSaveModelPostscript { } {
    #--- WJP change 4/13/05
    set c $::fMRIModelView(modelViewCanvas) 
    set fn [ file join $::fMRIModelView(psDirectory) $::fMRIModelView(psFile)]
    $c postscript -file $fn -colormode color -pageheight 9.0i -pagewidth 7.0i
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSaveModelPostscriptPopup
# 
# .ARGS
# windowpath toplevelName defaults to .fMRIModelViewSavePS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSaveModelPostscriptPopup { { toplevelName .fMRIModelViewSavePS} } {
    global Gui
    
    #--- WJP added proc 4/13/05
    if {[winfo exists $toplevelName]} {
        wm deiconify $toplevelName
        raise $toplevelName
        return
    }
    puts "$toplevelName"
    set root [toplevel $toplevelName]
    wm title $root "fMRIEngine save model postscript"
    wm protocol $root WM_DELETE_WINDOW "fMRIModelViewCloseModelPostscriptPopup $root"

    set ::fMRIModelView(psDirectory) "$::fMRIEngine(modulePath)"
    set ::fMRIModelView(psFilePrefix) "designmatrix.ps"

    frame $root.fSaveOptions -relief flat -border 2 -bg #FFFFFF
    set f $root.fSaveOptions

    button $f.bChooseDir -text "browse..." -command fMRIModelViewChooseDirectory -bg #DDDDDD -fg #000000
    grid $f.bChooseDir -sticky w -row 0 -column 1 -pady $Gui(pad)
    
    label $f.lDir -text "directory:" -bg #FFFFFF -fg #000000
    entry $f.eDir -width 35 -textvariable ::fMRIModelView(psDirectory) -bg #DDDDDD -fg #000000
    grid $f.lDir -sticky w -row 1 -column 0
    grid $f.eDir -sticky w -row 1 -column 1

    label $f.lFilename -text "filename.ps:" -bg #FFFFFF -fg #000000
    entry $f.eFilename -width 35 -textvariable ::fMRIModelView(psFile) -bg #DDDDDD -fg #000000
    grid $f.lFilename  -sticky w  -pady $Gui(pad) -row 2 -column 0
    grid $f.eFilename -sticky w  -pady $Gui(pad) -row 2 -column 1

    frame $root.fApply -relief flat -border 2 -padx 3 -bg #FFFFFF 
    set f $root.fApply
    
    button $f.bCloseWindow -text "close" -command "fMRIModelViewClosePostscriptPopup $root" -bg #DDDDDD -fg #000000
    button $f.bSaveNow     -text "save" -command "fMRIModelViewSaveModelPostscript " -bg #DDDDDD -fg #000000
    grid $f.bCloseWindow -sticky e -padx $Gui(pad) -pady 5 -ipadx 2 -ipady 2 -row 0 -column 0
    grid $f.bSaveNow -sticky e -padx $Gui(pad) -pady 5 -ipadx 2 -ipady 2 -row 0 -column 1

    pack $root.fSaveOptions $root.fApply -fill x
    return $root
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewChooseDirectory
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewChooseDirectory { } {
    #--- WJP added proc 4/13/05
    set newdir [ tk_chooseDirectory -initialdir $::fMRIModelView(psDirectory)]
    puts "$newdir"
    if { "$newdir" != "" } {
        set ::fMRIModelView(psDirectory) $newdir
    }
}

#-------------------------------------------------------------------------------
# .PROC fMRIModelViewClosePostscriptPopup
# 
# .ARGS
# windowpath win
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewClosePostscriptPopup { win } {
    #--- WJP added proc 4/13/05
    destroy $win
}





#-------------------------------------------------------------------------------
# .PROC fMRIModelViewSetupOrthogonalityImage
# computes and visualizes design orthogonality matrix.
# .ARGS
# int c 
# int refX 
# int refY 
# int dmatHit 
# int dmatWid 
# int cmatHit 
# int cmatWid 
# int b 
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewSetupOrthogonalityImage { c refX refY dmatHit dmatWid cmatHit cmatWid b } {

    set ybuf $::fMRIModelView(Layout,EVnameBufHit)
    set xbuf $::fMRIModelView(Layout,FilenameBufWid) 

    #--- if the same conditions exist for all runs, 
    #--- (assuming conditions are the same in each run)
    #--- compute design orthogonality; otherwise, draw nothing.
    #--- only consider condition-related explanatory variables.
    set n $::fMRIModelView(Design,Run1,numConditionEVs)
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set lastn $n
        set n $::fMRIModelView(Design,Run$r,numConditionEVs)
        if { $lastn != $n || $n <= 1 } {
            #--- not computable; draw nothing.
            return
        }
    }

    #--- adjust dimension of nxn orthogonality matrix if necessary.
    set totaldim [ expr $n * $::fMRIModelView(Layout,OrthogonalityCellDim) ]
    if { $totaldim <= $::fMRIModelView(Layout,OrthogonalityDim) } {
        set dim $::fMRIModelView(Layout,OrthogonalityCellDim)
        #set dim $idealdim
    } else {
        set newdim [ expr $::fMRIModelView(Layout,OrthogonalityDim) / $n ]
        #--- too small; draw nothing.
        if { $n < 3 } {
            return
        }
        set dim $newdim
    }

    #--- xy dimensions:
    set x1 [ expr $refX + $dmatWid + $::fMRIModelView(Layout,HSpace) ]
    set x2 [ expr $x1 + ($dim * $n) ]
    set y1 [ expr $refY +  $dmatHit + $cmatHit + $::fMRIModelView(Layout,ButtonHit) ]
    set y2 [ expr $y1 + ($dim * $n) ]
    set run1EVs [ expr $::fMRIModelView(Design,Run1,numConditionEVs) + \
                     $::fMRIModelView(Design,Run1,numAdditionalEVs) ]

    #-- fix in progress: replace that with this...
    #--- Compute and fill elements of orthogonality matrix.
    #--- Only want to compute orthogonality for condition EVs here;
    #--- (not include derivatives or baselines or discrete cosine filter functions etc.)
    #--- So screen out those unwanted EVs, and use condition-related ones.. 
    #--- assume all runs have identical EVs, so just use Run 1
    set i 1
    set vcount 0
    while { $i <= $run1EVs } {
        #--- screen out unwanted EVs; just pick out conditionEVs
        set deriv1 [ string first "_dt" $::fMRIModelView(Design,Run1,EV$i,SignalType) ]
        set bline1 [ string first "baseline" $::fMRIModelView(Design,Run1,EV$i,SignalType) ]
        set basis1 [ string first "DCbasis"  $::fMRIModelView(Design,Run1,EV$i,SignalType) ]
        if { ($deriv1 < 0) && ($bline1 < 0) && ($basis1 < 0) } {
            set v1 $::fMRIModelView(Data,Run1,EV$i,EVData)
            set len1 [ llength $v1 ]
            set magv1 [ fMRIModelViewComputeVectorMagnitude $v1 $len1 ]
            #--- some rectangle draw y coords
            set b1 [ expr $y1 + ($dim * $vcount) ]
            set b2 [ expr $b1 + $dim ]
            incr vcount
            set hcount 0
            set j 1
            
            while { $j <=  $run1EVs } {
                #--- screen out unwanted EVs; just pick out conditionEVs
                set deriv2 [ string first "_dt" $::fMRIModelView(Design,Run1,EV$j,SignalType) ]
                set bline2 [ string first "baseline" $::fMRIModelView(Design,Run1,EV$j,SignalType) ]
                set basis2 [ string first "DCbasis"  $::fMRIModelView(Design,Run1,EV$j,SignalType) ]
                if { ($deriv2 < 0) && ($bline2 < 0) && ($basis2 < 0) } {
                    #-- compute vector dot product and vector magnitude.
                    set v2 $::fMRIModelView(Data,Run1,EV$j,EVData) 
                    set len2 [ llength $v2 ]
                    set vdot [ fMRIModelViewComputeDotProduct $v1 $v2 $len2]
                    set vdot [ expr abs ( $vdot ) ]
                    set magv2 [ fMRIModelViewComputeVectorMagnitude $v2 $len2 ]
                    #--- let zero mean correlated; 1 mean uncorrelated
                    if {$magv1 == 0.0 || $magv2 == 0.0} {
                        set val 0.0
                    } else {
                        set val [ expr 1.0 - ($vdot / ( $magv1 * $magv2)) ]
                    }
                    #--- convert range from [ 0 to 1 ] to [ 0 to 255 ]
                    set fillval [ expr round ($val * 255) ]
                    set hexval [ format "#%02x%02x%02x" $fillval $fillval $fillval ]
                    #--- draw a filled rect
                    set a1 [ expr $x1 + ($dim *  $hcount) ]
                    set a2 [ expr $a1 + $dim ]
                    $c create rect $a1 $b1 $a2 $b2 -outline $hexval -width 1 -fill $hexval
                    incr hcount
                }
                incr j
            }
        }
        incr i
    }

    #--- draw columns.
    for { set x $x1 } { $x < $x2 } { set x [ expr $x + $dim ] } {
        $c create line $x $y1 $x $y2 -width 1 -fill $::fMRIModelView(Colors,darkGrey)         
    }
    #--- draw rows
    for { set y $y1 } { $y < $y2 } { set y [ expr $y + $dim ] } {
        $c create line $x1 $y $x2 $y -width 1 -fill $::fMRIModelView(Colors,darkGrey)         
    }
    #--- draw surrounding rect:
    $c create rect $x1 $y1 $x2 $y2 -outline $::fMRIModelView(Colors,hexblack) \
        -width $b

}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLabelTContrasts
# 
# .ARGS
# int c
# int refX
# int refY
# int dmatHit
# int cmatHit
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLabelTContrasts { c refX refY dmatHit cmatHit } {
    #---
    #--- xy start positions and increment
    set inc [ expr $cmatHit / $::fMRIModelView(Design,numTContrasts) ]
    set y1 [ expr $refY + $dmatHit + $::fMRIModelView(Layout,VSpace) + ($inc / 2) ]
    set x1 [ expr $refX -  $::fMRIModelView(Layout,bigHSpace) ]

    for { set i 0 } { $i < $::fMRIModelView(Design,numTContrasts) } { incr i } {
        set name [ lindex $::fMRIModelView(Design,TContrasts) $i ]
        $c create text  $x1 $y1 -text $name -anchor center \
            -font $::fMRIModelView(UI,Medfont) -fill $::fMRIModelView(Colors,hexblack)
        set y1 [ expr $y1 + $inc ]
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLabelTContrastNames
# 
# .ARGS
# int c
# int refX
# int refY
# int dmatHit
# int cmatHit
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLabelTContrastNames { c refX refY dmatHit cmatHit } {
    #---
    #--- xy start positions and increment
    set inc [ expr $cmatHit / $::fMRIModelView(Design,numTContrasts) ]
    set y1 [ expr $refY + $dmatHit + $::fMRIModelView(Layout,VSpace) + ($inc / 2) ]
    set pixelsPerChar 4
    
    for { set i 0 } { $i < $::fMRIModelView(Design,numTContrasts) } { incr i } {
        set name [ lindex $::fMRIModelView(Design,TContrastNames) $i ]
        set numchars [ string length $name ]
        set x1 [ expr $refX -  ($numchars * $pixelsPerChar) - \
                     ( $::fMRIModelView(Layout,HSpace)) ]
        # Haiying's change
        #$c create text  $x1 $y1 -text "$name - " -anchor center 
        #$c create text  $x1 $y1 -text "$name" -anchor center 
        #--- WJP change
        set x1 [ expr $refX - $::fMRIModelView(Layout,HSpace) ]
        $c create text  $x1 $y1 -text "$name - " -anchor e \
            -font $::fMRIModelView(UI,Smallfont) -fill $::fMRIModelView(Colors,hexblack)
        set y1 [ expr $y1 + $inc ]
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLabelEVs
# 
# .ARGS
# int c
# int refX
# int refY
# int dmatWid
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLabelEVs { c refX refY dmatWid } {
    #---
    #--- xy start positions and increment
    set m $::fMRIModelView(Design,totalEVs)
    set inc [ expr $dmatWid / $m ]
    set x1 [ expr $refX + ($inc / 2) ]
    set y1 [ expr $refY -  $::fMRIModelView(Layout,moreHSpace) ]

    #--- make text labels for all explanatory varibles.
    #--- all names are stuffed into one long list.
    set indx 0
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                      $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $cols } { incr i } {
            set name [ lindex $::fMRIModelView(Design,evs) $indx ]
            $c create text  $x1 $y1 -text $name -anchor center \
                -font $::fMRIModelView(UI,Smallfont) -fill $::fMRIModelView(Colors,hexblack)
            set x1 [ expr $x1 + $inc ]
            incr indx
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLabelEVnames
# make little lines pointing up from columns
# these encroach a little on EVBufHit, but
# probably there's room, fontwilling.
# .ARGS
# int c
# int refX
# int refY
# int dmatWid
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLabelEVnames { c refX refY dmatWid  } {
    
    set yoffset $::fMRIModelView(Layout,hugeVSpace) 
    set inc [ expr $dmatWid / $::fMRIModelView(Design,totalEVs) ]
    set x1 [ expr $refX + ($inc / 2) ]
    set y1 [ expr $refY - $::fMRIModelView(Layout,EVBufHit) + \
                 $::fMRIModelView(Layout,moreVSpace) ]
    set y2 [ expr $y1 - $::fMRIModelView(Layout,evLineBufHit) ]
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {    
        set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                      $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $cols } { incr i } {
            $c create line $x1 $y1 $x1 $y2 -width 1 -fill $::fMRIModelView(Colors,hexblack) \
                -tag $::fMRIModelView(Layout,EVnameTag,Run$r,$i) 
            set x1 [ expr $x1 + $inc ]
        }
    }

    #--- make labels for all explanatory variable names
    set x1 [ expr $refX + ($inc / 2) ]
    set y1 [ expr $refY - $::fMRIModelView(Layout,EVBufHit) - \
                 $::fMRIModelView(Layout,evLineBufHit) ]
    set indx 0
    for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
        set cols [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                      $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $cols } { incr i } {
            set name [ lindex $::fMRIModelView(Design,evNames)  $indx ]
            $c create text $x1 $y1 -text "$name" -anchor center \
                -font $::fMRIModelView(UI,Smallfont) \
                -fill $::fMRIModelView(Colors,hexblack) \
                -tag $::fMRIModelView(Layout,EVnameTag,Run$r,$i)             
            set x1 [ expr $x1 + $inc ]
            incr indx
        }
    }

    #--- make a rect that covers up the pile of names;
    #--- raise each upon design matrix column rollover.
    set x1 0
    set x2 [ expr $refX + $dmatWid + $::fMRIModelView(Layout,FilenameBufWid) ]
    set y1 0
    set y2 [ expr $refY - $::fMRIModelView(Layout,EVBufHit) + \
                 $::fMRIModelView(Layout,moreVSpace) + 1 ]
    set ::fMRIModelView(EVnameCover) [ $c create rect $x1 $y1 $x2 $y2 \
                                       -fill $::fMRIModelView(Colors,hexwhite) -width 1 \
                                           -outline $::fMRIModelView(Colors,hexwhite) ]
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewEVnameRollover
# 
# .ARGS
# int c
# int refY
# int evnum
# int runNum
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewEVnameRollover { c refY evnum runNum } {
    #---
    if { [info exists ::fMRIModelView(EVnameCover)] } {
        $c raise $::fMRIModelView(EVnameCover)
    }
    $c raise $::fMRIModelView(Layout,EVnameTag,Run$runNum,$evnum)

}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewLabelFilenames
# 
# .ARGS
# int c
# int refX
# int refY
# int dmatHit
# int dmatWid
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewLabelFilenames { c refX refY dmatHit dmatWid } {
    #---
    #--- position of first filename
    set x1 [ expr $refX + $dmatWid + $::fMRIModelView(Layout,HSpace) ]
    set y $refY
    #--- increment between files.
    set numFiles $::fMRIModelView(Design,totalTimePoints) 
    set inc [ expr $dmatHit / double($numFiles) ]
    
    #--- make all filenames in their place.
    for { set i 0 } { $i < $numFiles } { incr i } {
        set name [ lindex $::fMRIModelView(Design,fileNames) $i ]
        $c create text  $x1 $y -text " - $name" -anchor w \
            -font $::fMRIModelView(UI,Smallfont) \
            -fill $::fMRIModelView(Colors,hexblack) \
            -tag $::fMRIModelView(Layout,FilenameTag$i) 
        set y [ expr $y + $inc ]
        #set y [ expr round ($y) ]
    }
        
    #--- make a rect and set it atop all filenames to cover.
    set y1 [ expr $refY - $::fMRIModelView(Layout,VSpace) ]
    set y2 [ expr $refY + $dmatHit + $::fMRIModelView(Layout,VSpace) ]
    set x2 [ expr $x1 + $::fMRIModelView(Layout,FilenameBufWid) ]
    set ::fMRIModelView(filenameCover) [ $c create rect $x1 $y1 $x2 $y2 \
                                       -fill $::fMRIModelView(Colors,hexwhite) -width 1 \
                                            -outline $::fMRIModelView(Colors,hexwhite) ]
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFilenameRollover
# 
# .ARGS
# int c
# int refY
# int dmatHit
# int mousey
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFilenameRollover { c  refY dmatHit mousey} {
    #---
    #--- map mousey to filenames
    set ytop $refY
    set yend [ expr $ytop + $dmatHit ]
    set numFiles [ expr $::fMRIModelView(Design,totalTimePoints) ]
    set binsize [ expr $dmatHit / double( $numFiles ) ]

    #--- correct for canvas scrolling
    set adjusty [ $c canvasy $mousey ]
    #--- what bin does $mousey fall into
    #--- fix xlates due to scrolling here...
    set absy [ expr $adjusty - $ytop ]
    set binnum [ expr $absy / $binsize ]
    set binnum [ expr round($binnum) ]

    #--- expose corresponding filename
    if { [info exists ::fMRIModelView(filenameCover) ] } {
        $c raise $::fMRIModelView(filenameCover)
    }
    if { $binnum < $numFiles && $binnum >= 0 } {
        $c raise $::fMRIModelView(Layout,FilenameTag$binnum)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewHideRolloverInfo
# 
# .ARGS
# int c
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewHideRolloverInfo { c } {
    #---
    #--- cover up filenames and EVnames
    if { [info exists ::fMRIModelView(filenameCover)] } {
        $c raise $::fMRIModelView(filenameCover)
    }
    if { [info exists ::fMRIModelView(EVnameCover)] } {
        $c raise $::fMRIModelView(EVnameCover)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFreeCanvasTags
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFreeCanvasTags { } {
    #---
    #--- unset tags
    unset -nocomplain ::fMRIModelView(Layout,SaveRectTag)
    unset -nocomplain ::fMRIModelView(Layout,SaveTag)
    unset -nocomplain ::fMRIModelView(Layout,UpdateRectTag)
    unset -nocomplain ::fMRIModelView(Layout,UpdateTag)
    unset -nocomplain ::fMRIModelView(Layout,CloseRectTag)
    unset -nocomplain ::fMRIModelView(Layout,CloseTag)

    if { [ info exists ::fMRIModelView(Design,totalTimePoints) ] } {
        set totFiles [ expr $::fMRIModelView(Design,totalTimePoints) ]
        for { set i 0 } { $i < $totFiles } { incr i } {
            unset -nocomplain ::fMRIModelView(Layout,FilenameTag$i) 
        }
        unset -nocomplain ::fMRIModelView(filenameCover)
    }

    if { [info exists ::fMRIModelView(Design,numRuns) ] } {
        for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
            set evs [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                          $::fMRIModelView(Design,Run$r,numAdditionalEVs) ] 
            for { set i 1 } { $i <= $evs } { incr i } {
                unset -nocomplain ::fMRIModelView(Layout,EVnameTag,Run$r,$i) 
                unset -nocomplain ::fMRIModelView(Layout,dmColumnTag,Run$r,$i)
            }
        }
        unset -nocomplain ::fMRIModelView(EVnameCover)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFreeFonts
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFreeFonts { } {
    #---
    #--- unset fonts
    unset -nocomplain ::fMRIModelView(UI,Bigfont)
    unset -nocomplain ::fMRIModelView(UI,Medfont)    
    unset -nocomplain ::fMRIModelView(UI,Smallfont)
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFreeColors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFreeColors { } {
    #---
    #--- unset colors
    unset -nocomplain ::fMRIModelView(Colors,bkg)
    unset -nocomplain ::fMRIModelView(Colors,activeBkg)
    unset -nocomplain ::fMRIModelView(Colors,black)
    unset -nocomplain ::fMRIModelView(Colors,hexblack)
    unset -nocomplain ::fMRIModelView(Colors,white)
    unset -nocomplain ::fMRIModelView(Colors,hexwhite)
    unset -nocomplain ::fMRIModelView(Colors,liteGrey)
    unset -nocomplain ::fMRIModelView(Colors,darkGrey)
    unset -nocomplain ::fMRIModelView(Colors,zeroGrey)
    unset -nocomplain ::fMRIModelView(Colors,contrastRect)
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFreeModel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFreeModel { } {
    #---
    #--- clears all modeling derived from user input
    #--- and from additionally requested explanatory variables.
    #--- if all runs are identical, then first run's data is used for
    #--- all runs, and only need to free it.
    #--- otherwise, free all runs' data.
    if { [info exists ::fMRIModelView(Design,numRuns) ] } {
        for { set r 1 } { $r <= $::fMRIModelView(Design,numRuns) } { incr r } {
            set evs [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
                          $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
            for { set i 1 } { $i <= $evs } { incr i } {
                unset -nocomplain ::fMRIModelView(Images,Run$r,EV$i,Image)
                unset -nocomplain ::fMRIModelView(Data,Run$r,EV$i,EVData)
                unset -nocomplain ::fMRIModelView(Data,Run$r,EV$i,Signal)
            }
            unset -nocomplain ::fMRIModelView(Design,Run$r,GaussianFilter) 
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewClearUserInput
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewClearUserInput { } {
    #---
    #--- unset all user input 
    if {[info exists ::fMRIModelView(Design,numRuns)]} {
        for { set r 1 } { $r < $::fMRIModelView(Design,numRuns) } { incr r } {
            unset -nocomplain ::fMRIModelView(Design,Run$r,Type)
        }

        #--- unset ev signal configuration
        set evs [ expr $::fMRIModelView(Design,Run$r,numConditionEVs) + \
            $::fMRIModelView(Design,Run$r,numAdditionalEVs) ]
        for { set i 1 } { $i <= $evs } { incr i } {
            unset -nocomplain ::fMRIModelView(Design,Run$r,EV$i,SignalType)
            unset -nocomplain ::fMRIModelView(Design,Run$r,EV$i,myCondition)
        }

        for { set r 1 } { $r < $::fMRIModelView(Design,numRuns) } { incr r } {
            for { set i 1 } { $i < $::fMRIModelView(Design,Run$r,numConditions) } { incr i } {
                unset -nocomplain ::fMRIModelView(Design,Run$r,Condition$i,Onsets)
                unset -nocomplain ::fMRIModelView(Design,Run$r,Condition$i,Durations)
                unset -nocomplain ::fMRIModelView(Design,Run$r,Condition$i,Intensities) 
            }
            unset -nocomplain ::fMRIModelView(Design,Run$r,numConditions)
        }

        for { set i 1 } { $i < $::fMRIModelView(Design,numTContrasts) } { incr i } {
            unset -nocomplain ::fMRIModelView(Design,TContrast$i,Vector)
        }    
        unset -nocomplain ::fMRIModelView(Design,numTContrasts)
        unset -nocomplain ::fMRIModelView(Design,TContrastNames)
        unset -nocomplain ::fMRIModelView(Design,TContrasts)

        for { set r 1 } { $r < $::fMRIModelView(Design,numRuns) } { incr r } {
            unset -nocomplain ::fMRIModelView(Design,Run$r,numConditionEVs)
            unset -nocomplain ::fMRIModelView(Design,Run$r,numAdditionalEVs)
            unset -nocomplain ::fMRIModelView(Design,Run$r,UseDCBasis) 
            unset -nocomplain ::fMRIModelView(Design,Run$r,UsePolyBasis)
            unset -nocomplain ::fMRIModelView(Design,Run$r,UseSplineBasis)
            unset -nocomplain ::fMRIModelView(Design,Run$r,UseExploratoryBasis)
            unset -nocomplain ::fMRIModelView(Design,Run$r,UseBaseline) 
            unset -nocomplain ::fMRIModelView(Design,Run$r,HRF)
            unset -nocomplain ::fMRIModelView(Design,Run$r,TR)        
            unset -nocomplain ::fMRIModelView(Design,Run$r,TimeIncrement)        
            unset -nocomplain ::fMRIModelView(Design,Run$r,numTimePoints)        
        }
        unset -nocomplain ::fMRIModelView(Design,numRuns)
        unset -nocomplain ::fMRIModelView(Design,totalEVs)
        unset -nocomplain ::fMRIModelView(Design,evNames)
        unset -nocomplain ::fMRIModelView(Design,evs)
        unset -nocomplain ::fMRIModelView(Design,fileNames)
        unset -nocomplain ::fMRIModelView(Design,totalTimePoints) 
        unset -nocomplain ::fMRIModelView(Layout,NoDisplay)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewFreeVisualLayout
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewFreeVisualLayout { } {
    #---
    #--- unset drawing and layout things
    unset -nocomplain ::fMRIModelView(Layout,OrthogonalityDim)
    unset -nocomplain ::fMRIModelView(Layout,VSpace)
    unset -nocomplain ::fMRIModelView(Layout,HSpace)
    unset -nocomplain ::fMRIModelView(Layout,moreVSpace) 
    unset -nocomplain ::fMRIModelView(Layout,moreHSpace) 
    unset -nocomplain ::fMRIModelView(Layout,bigVSpace) 
    unset -nocomplain ::fMRIModelView(Layout,bigHSpace)    
    unset -nocomplain ::fMRIModelView(Layout,hugeVSpace)
    unset -nocomplain ::fMRIModelView(Layout,hugeHSpace)   

    unset -nocomplain ::fMRIModelView(Layout,EVBufHit)
    unset -nocomplain ::fMRIModelView(Layout,EVBufWid)
    unset -nocomplain ::fMRIModelView(Layout,evLineBufHit)
    unset -nocomplain ::fMRIModelView(Layout,FilenameBufWid)
    unset -nocomplain ::fMRIModelView(Layout,EVnameBufHit)
    unset -nocomplain ::fMRIModelView(Layout,EVnameBufWid)
    unset -nocomplain ::fMRIModelView(Layout,ContrastNameBufWid)
    unset -nocomplain ::fMRIModelView(Layout,ContrastBufWid)
    unset -nocomplain ::fMRIModelView(Layout,pixelsPerTimePoint)
    unset -nocomplain ::fMRIModelView(Layout,TContrastWid)
    unset -nocomplain ::fMRIModelView(Layout,TContrastHit)
    unset -nocomplain ::fMRIModelView(Layout,ButtonWid)
    unset -nocomplain ::fMRIModelView(Layout,ButtonHit)
    unset -nocomplain ::fMRIModelView(Layout,botBufHit)
    unset -nocomplain ::fMRIModelView(Layout,totalWid)
    unset -nocomplain ::fMRIModelView(Layout,totalHit)
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCleanCanvas
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCleanCanvas { } { 
    #---
    #--- deletes all canvas elements, the
    #--- pile of globals used to create display
    #--- and the canvas and its frame

    if { [ info exists ::fMRIModelView(modelViewCanvas) ] } {
        $::fMRIModelView(modelViewCanvas) delete all
        destroy $::fMRIModelView(modelViewCanvas)
        unset -nocomplain ::fMRIModelView(modelViewCanvas)
    }
    if { [ info exists ::fMRIModelView(modelViewFrame) ] } {
        destroy $::fMRIModelView(modelViewFrame)
        unset -nocomplain ::fMRIModelView(modelViewFrame)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCleanForRegeneration
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCleanForRegeneration { } {
    #---
    #--- freeing everything but user input
    #---
    fMRIModelViewFreeCanvasTags
    fMRIModelViewFreeFonts
    fMRIModelViewFreeColors
    fMRIModelViewFreeModel
    fMRIModelViewFreeVisualLayout
    fMRIModelViewCleanCanvas

}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCleanNoRegeneration
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCleanNoRegeneration { } {
    #---
    #--- freeing everything but user input and signals
    #---
    fMRIModelViewFreeCanvasTags
    fMRIModelViewFreeFonts
    fMRIModelViewFreeColors
    fMRIModelViewFreeVisualLayout
    fMRIModelViewCleanCanvas
}




#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCloseAndCleanNoRegeneration
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCloseAndCleanNoRegeneration { } {
    #---
    #--- freeing everything but user input
    #--- deletes toplevel win
    #---
    set ::fMRIModelView(Layout,NoDisplay) 1
    fMRIModelViewCleanNoRegeneration
    if { [ info exists ::fMRIModelView(modelViewWin) ] } {
        destroy $::fMRIModelView(modelViewWin)
        unset -nocomplain ::fMRIModelView(modelViewWin)
    }
}




#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCloseAndClean
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCloseAndClean { } {
    #---
    #--- freeing everything but user input
    #--- deletes toplevel win
    #---
    set ::fMRIModelView(Layout,NoDisplay) 1
    fMRIModelViewCleanForRegeneration
    if { [ info exists ::fMRIModelView(modelViewWin) ] } {
        destroy $::fMRIModelView(modelViewWin)
        unset -nocomplain ::fMRIModelView(modelViewWin)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIModelViewCloseAndCleanAndExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIModelViewCloseAndCleanAndExit { } {
    #---
    #--- unset all globals, canvas,
    #--- deletes toplevel win
    #--- unsets user input.
    #---
    if { 0 } {
        fMRIModelViewFreeCanvasTags
        fMRIModelViewFreeFonts
        fMRIModelViewFreeColors
        fMRIModelViewFreeModel  
        fMRIModelViewClearUserInput  
        fMRIModelViewFreeVisualLayout
        fMRIModelViewCleanCanvas
        if { [ info exists ::fMRIModelView(modelViewWin) ] } {
            destroy $::fMRIModelView(modelViewWin)
            unset -nocomplain ::fMRIModelView(modelViewWin)
        }
    }
    fMRIModelViewCloseAndClean
    fMRIModelViewClearUserInput
}

