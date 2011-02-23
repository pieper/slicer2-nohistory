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
# FILE:        IbrowserDisplayGUI.tcl
# PROCEDURES:  
#   IbrowserUpdateDisplayTab
#   IbrowserBuildDisplayFrame
#   IbrowserUpdateMainViewer
#   IbrowserSlicesSetVolumeAll
#   IbrowserSetIntervalParam
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateDisplayTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateDisplayTab { } {

    set ::Ibrowser(currentTab) "Display"
}


#-------------------------------------------------------------------------------
# .PROC IbrowserBuildDisplayFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildDisplayFrame { } {
    global Gui Module Volume

    set fDisplay $::Module(Ibrowser,fDisplay)
    bind $::Module(Ibrowser,bDisplay) <ButtonPress-1> "IbrowserUpdateDisplayTab"
    #--- initialize to save values that Volumes module starts with.
    
    set w $fDisplay

    #--- Frames: use packer to put them in place.
    frame $w.fSelect -bg $Gui(activeWorkspace) -bd 2 -relief groove
    frame $w.fWinLvl -bg $Gui(activeWorkspace) -bd 2 -relief groove
    frame $w.fThresh -bg $Gui(activeWorkspace) -bd 2 -relief groove
    frame $w.fHistogram -bg $Gui(activeWorkspace) -bd 2 -relief groove
    frame $w.fInterpolate -bg $Gui(activeWorkspace) 
    pack $w.fSelect $w.fWinLvl $w.fThresh $w.fHistogram $w.fInterpolate \
        -side top -pady $Gui(pad) -padx $Gui(pad) -fill x


    #-------------------------------------------
    # Select volume frame
    #-------------------------------------------
    set f $w.fSelect
    DevAddLabel $f.lSelect "Volume:"
    eval { scale $f.index -orient horizontal \
               -from 0 -to $::Ibrowser(MaxDrops) -resolution 1 \
               -bigincrement 10 -length 150 -state disabled -showvalue 1 \
               -variable ::Ibrowser(ViewDrop) } \
               $Gui(WSA) { -showvalue 1 }

    #--- Save a ref to the scale so we can find it later
    #--- Update the main viewer based on slider motion
    #--- and update the IbrowserController slider too.
    set ::Ibrowser(displaySlider) $f.index
    bind $f.index <ButtonPress-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $f.index <ButtonRelease-1> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    bind $f.index <B1-Motion> {
        IbrowserUpdateIndexFromGUI
        IbrowserUpdateMainViewer $::Ibrowser(ViewDrop)
    }
    grid $f.lSelect $f.index -pady $Gui(pad) -padx $Gui(pad) -sticky e


    #-------------------------------------------
    # WinLvl frame
    #-------------------------------------------
    set f $w.fWinLvl

    #-------------------------------------------
    # Auto W/L
    #-------------------------------------------
    eval {label $f.lAuto -text "  Win/Lev:"} $Gui(WLA)
    frame $f.fAuto -bg $Gui(activeWorkspace) 
    grid $f.lAuto $f.fAuto -pady $Gui(pad)  -padx $Gui(pad) -sticky e
    grid $f.fAuto -columnspan 2 -sticky w

    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable ::Volume(autoWindowLevel) \
                  -command "IbrowserSetIntervalParam AutoWindowLevel" \
            } $Gui(WCA)
        pack $f.fAuto.rAuto$value -side left -fill x
    }

    #-------------------------------------------
    # W/L Sliders
    #-------------------------------------------
    foreach slider "Window Level" text "Win Lev" {
        DevAddLabel $f.l${slider} "$text:"
        eval {entry $f.e${slider} -width 6 \
                  -textvariable ::Volume([Uncap ${slider}]) } $Gui(WEA)
       bind $f.e${slider} <Return>   \
            "IbrowserSetIntervalParam ${slider}"
        bind $f.e${slider} <FocusOut> \
            "IbrowserSetIntervalParam ${slider}"
        eval {scale $f.s${slider} -from 1 -to 700 -length 90 \
            -variable ::Volume([Uncap ${slider}]) -resolution 1 \
                  -command "MainVolumesSetParam ${slider}; MainVolumesRender" \
              } $Gui(WSA) {-sliderlength 14}
        bind $f.s${slider} <ButtonRelease-1> "IbrowserSetIntervalParam ${slider}"
        grid $f.l${slider} $f.e${slider} $f.s${slider} -padx 2 -pady $Gui(pad) -sticky news
        set ::Ibrowser(s$slider) $f.s$slider
    }
    # Append widgets to list that's refreshed in MainVolumesUpdateSliderRange
    lappend Volume(sWindowList) $f.sWindow
    lappend Volume(sLevelList) $f.sLevel

    #-------------------------------------------
    # Display->Threshold frame
    #-------------------------------------------
    set f $w.fThresh
    frame $f.fAuto -bg $Gui(activeWorkspace)
    frame $f.fSliders -bg $Gui(activeWorkspace)
    pack $f.fAuto $f.fSliders -side top -fill x -expand 1
    
    #-------------------------------------------
    # Display->Threshold->Auto Threshold
    #-------------------------------------------
    set f $w.fThresh.fAuto
    
    DevAddLabel $f.lAuto "Threshold: "
    frame $f.fAuto -bg $Gui(activeWorkspace)
    pack $f.lAuto $f.fAuto -side left -pady $Gui(pad) -fill x
    
    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable ::Volume(autoThreshold) \
                  -command "IbrowserSetIntervalParam AutoThreshold;"} $Gui(WCA)
        pack $f.fAuto.rAuto$value -side left -fill x
    }
    eval {checkbutton $f.cApply \
        -text "Apply" -variable ::Volume(applyThreshold) \
              -command "IbrowserSetIntervalParam ApplyThreshold" -width 6 \
        -indicatoron 0} $Gui(WCA)
    pack $f.cApply -side left -padx $Gui(pad)

    #-------------------------------------------
    # Display->Threshold-> Sliders Frame
    #-------------------------------------------
    set f $w.fThresh.fSliders
    
    foreach slider "Lower Upper" text "Lo Hi" {
        DevAddLabel $f.l${slider} "$text:"
        eval {entry $f.e${slider} -width 5 \
            -textvariable ::Volume([Uncap ${slider}]Threshold)} $Gui(WEA)
            bind $f.e${slider} <Return>   \
            "IbrowserSetIntervalParam ${slider}Threshold"
            bind $f.e${slider} <FocusOut> \
            "IbrowserSetIntervalParam ${slider}Threshold"
        eval {scale $f.s${slider} -from 1 -to 700 -length 90 \
            -variable ::Volume([Uncap ${slider}]Threshold) -resolution 1 \
                  -command "MainVolumesSetParam ${slider}Threshold; MainVolumesRender" \
              } $Gui(WSA) {-sliderlength 14}
        bind $f.s${slider} <ButtonRelease-1> "IbrowserSetIntervalParam ${slider}Threshold"
        #bind $f.s${slider} <Leave> "IbrowserSetIntervalParam ${slider}Threshold"
        grid $f.l${slider} $f.e${slider} $f.s${slider} -padx 2 -pady $Gui(pad) -sticky news
        set ::Ibrowser(s$slider) $f.s$slider
    }
    # Append widgets to list that's refreshed in MainVolumesUpdateSliderRange
    lappend Volume(sLevelList) $f.sLower
    lappend Volume(sLevelList) $f.sUpper

    #-------------------------------------------
    # Histogram frame
    #-------------------------------------------
    set f $w.fHistogram

    frame $f.fHistBorder -bg $Gui(activeWorkspace) -relief sunken -bd 2
    frame $f.fLut -bg $Gui(activeWorkspace)
    pack $f.fLut $f.fHistBorder -side left -padx $Gui(pad) -pady $Gui(pad)
    
    #-------------------------------------------
    # 
    # Display->Histogram->LUT frame
    #-------------------------------------------
    set f $w.fHistogram.fLut

    DevAddLabel $f.lLUT "Palette:"
    eval {menubutton $f.mbLUT \
        -text "$::Lut([lindex $::Lut(idList) 0],name)" \
            -relief raised -bd 2 -width 9 \
        -menu $f.mbLUT.menu} $Gui(WMBA)
    set ::Ibrowser(mbLUT) $f.mbLUT
    eval {menu $f.mbLUT.menu} $Gui(WMA)
    # Add menu items
    foreach l $::Lut(idList) {
        $f.mbLUT.menu add command -label $::Lut($l,name) \
            -command  "$::Ibrowser(mbLUT) config -text $::Lut($l,name); IbrowserSetIntervalParam LutID $l"
    }
   
    pack $f.lLUT $f.mbLUT -pady $Gui(pad) -side top

    #-------------------------------------------
    # Display->Histogram->HistBorder frame
    #-------------------------------------------
    set f $w.fHistogram.fHistBorder

    if {$::Volume(histogram) == "On"} {
        MakeVTKImageWindow histIB
        histIBMapper SetInput [::Volume(0,vol) GetHistogramPlot]

        set wid [expr $Volume(histWidth) - 8]
        
        vtkTkRenderWidget $f.fHistIB -rw histIBWin \
            -width $wid -height $::Volume(histHeight)  
        bind $f.fHistIB <Expose> {ExposeTkImageViewer %W %x %y %w %h}
        pack $f.fHistIB
    }

    #-------------------------------------------
    # Display->Interpolate frame
    #-------------------------------------------
    set f $w.fInterpolate

    DevAddLabel $f.lInterpolate "Interpolation:"
    pack $f.lInterpolate -pady $Gui(pad) -padx $Gui(pad) -side left -fill x

    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.rInterp$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable ::Volume(interpolate) \
            -command "IbrowserSetIntervalParam Interpolate"} $Gui(WCA)
        pack $f.rInterp$value -side left -fill x
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateMainViewer
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateMainViewer { n } {
    
    #--- If the requested drop number to view is appropriate for the 
    #--- selectedInterval, update the main viewer to display this drop.
    #--- check here to see if the none interval is in the FG or BG or if
    #--- the Slice window menus have been used to set the FG & BG instead.
    if { [ info exists ::Ibrowser(FGInterval) ] && [ info exists ::Ibrowser(BGInterval)]} {

        set inumFG $::Ibrowser(FGInterval)
        set inumBG $::Ibrowser(BGInterval)
        set inumActive $::Ibrowser(activeInterval)

        #--- update the slices window if the interval is a valid FG interval
        if { $inumFG != $::Ibrowser(NoInterval) && $inumFG != $::Ibrowser(none,intervalID) } {
            if { $::Ibrowser($inumFG,numDrops) > $n } {
                #--- What's active in the foreground?
                IbrowserSlicesSetVolumeAll Fore $::Ibrowser($inumFG,$n,MRMLid)
                
                if { $inumFG == $inumActive } {
                    MainVolumesSetActive $::Ibrowser($inumFG,$n,MRMLid)
                }
            } else {
                if { $::Ibrowser($inumFG,holdStatus) == $::IbrowserController(Info,Ival,nohold) } {
                    IbrowserSlicesSetVolumeAll Fore "None"
                    if { $inumFG == $inumActive } {
                        MainVolumesSetActive $::Volume(idNone)
                    }
                } else {
                    IbrowserSlicesSetVolumeAll Fore $::Ibrowser($inumFG,lastMRMLid)
                    if { $inumFG == $inumActive } {
                        MainVolumesSetActive $::Ibrowser($inumFG,lastMRMLid)
                    }
                }
            }
        }

        #--- update the slices window if the interval is a valid BG interval
        if { $inumBG != $::Ibrowser(NoInterval) && $inumBG != $::Ibrowser(none,intervalID) } {

            if { $::Ibrowser($inumBG,numDrops) > $n } {
                #--- What's active in the background?
                IbrowserSlicesSetVolumeAll Back $::Ibrowser($inumBG,$n,MRMLid)
                if { $inumBG == $inumActive } {
                    MainVolumesSetActive $::Ibrowser($inumBG,$n,MRMLid)
                }
            } else {
                if { $::Ibrowser($inumBG,holdStatus) == $::IbrowserController(Info,Ival,nohold) } {
                    IbrowserSlicesSetVolumeAll Back "None"
                    if { $inumBG == $inumActive } {
                        MainVolumesSetActive $::Volume(idNone)
                    }
                } else {
                    IbrowserSlicesSetVolumeAll Back $::Ibrowser($inumBG,lastMRMLid)
                    if { $inumBG == $inumActive } {
                        MainVolumesSetActive $::Ibrowser($inumBG,lastMRMLid)
                    }
                }
            }
        }
        RenderAll
    }
}





#-------------------------------------------------------------------------------
# .PROC IbrowserSlicesSetVolumeAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSlicesSetVolumeAll { Layer v } {
        global Slice Volume

    # Check if volume exists and use the None if not
    if {[lsearch $Volume(idList) $v] == -1} {
        set v $Volume(idNone)
    }
    
    # Fields in the Slice array are uncapitalized
    set layer [Uncap $Layer]

    # Set the volume in the Slicer
    Slicer Set${Layer}Volume Volume($v,vol)
    Slicer Update

    foreach s $Slice(idList) {
        set Slice($s,${layer}VolID) $v

        # Change button text
        if {$Layer == "Back"} {
            MainSlicesConfigGui $s fOrient.mb${Layer}Volume$s \
                "-text \"[Volume($v,node) GetName]\""
        } else {
            MainSlicesConfigGui $s fVolume.mb${Layer}Volume$s \
                "-text \"[Volume($v,node) GetName]\""
        }
        # Always update Slider Range when change volume or orient
        MainSlicesSetSliderRange $s
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserSetIntervalParam
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetIntervalParam { setThis { myparam -10} } {
    global Volume Lut
    
    #---sets display parameters for all volumes in the active interval
    set activeVol $::Volume(activeID)
    set activeIval $::Ibrowser(activeInterval)
    set start $::Ibrowser($activeIval,firstMRMLid)
    set stop $::Ibrowser($activeIval,lastMRMLid)
    
    set pcount 0
    set numvols [ expr $stop - $start ]
    IbrowserRaiseProgressBar

    #for each mrml volume, set "setThis"
    if { $activeIval != $::Ibrowser(idNone) } {
        for { set i $start } { $i <= $stop } { incr i } {
            #--- set up the progress bar
            if { $numvols != 0 } {
                set progress [ expr double ($pcount) / double ($numvols) ]
                IbrowserUpdateProgressBar $progress "::"
            }
            #--- without something to make the application idle,
            #--- tk will not handle the drawing of progress bar.
            #--- Instead of calling update, which could cause
            #--- some unstable event loop, we just print some
            #--- '.'s to the tkcon. Slows things down a little,
            #--- but not terribly much. Better ideas are welcome.
            IbrowserPrintProgressFeedback

            #--- temporarily set this drop to be active so its params are set
            set ::Volume(activeID) $i
            if { $myparam == -10 } {
                MainVolumesSetParam $setThis
            } else {
                MainVolumesSetParam $setThis $myparam
            }
            incr pcount
        }
        IbrowserEndProgressFeedback
        #--- set the active volume back to what it originally was.
        set ::Volume(activeID) $activeVol
        MainVolumesRender
        #IbrowserUpdateMainViewer $::Ibrowser($activeIval,$::Ibrowser(ViewDrop),MRMLid)

        set tt "Set $setThis for all volumes in $::Ibrowser($activeIval,name)"
        IbrowserSayThis $tt 0
    }        
    IbrowserLowerProgressBar
}

