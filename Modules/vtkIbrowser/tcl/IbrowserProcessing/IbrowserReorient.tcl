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
# FILE:        IbrowserReorient.tcl
# PROCEDURES:  
#   IbrowserBuildReorientGUI
#   IbrowserUpdateReorientGUI
#   IbrowserFlipVolumeSequence
#   IbrowserFlipVolumeSequenceLR
#   IbrowserFlipVolumeSequenceAP
#   IbrowserFlipVolumeSequenceIS
#   IbrowserHelpReorient
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildReorientGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildReorientGUI { f master } {
    global Gui
    #--- This GUI allows a volume to be flipped from
    #--- left to right, up to down in display space.
    #--- set a global variable for frame so we can raise it.
    set ::Ibrowser(fProcessReorient) $f
    
    #--- create menu buttons and associated menus...
    frame $f.fOverview -bg $Gui(activeWorkspace) -bd 2 
    pack $f.fOverview -side top

    set ff $f.fOverview
    DevAddButton $ff.bHelp "?" "IbrowserHelpReorient" 2 
    eval { label $ff.lOverview -text \
               "Flip selected volume along major axis." } $Gui(WLA)
    grid $ff.bHelp $ff.lOverview -pady 1 -padx 1 -sticky w

    frame $f.fSpace -bg $::Gui(activeWorkspace) -bd 2 
    eval { label $f.fSpace.lSpace -text "       " } $Gui(WLA)
    pack $f.fSpace -side top 
    pack $f.fSpace.lSpace -side top -pady 4 -padx 20 -anchor w -fill x
    
    #--- frame to specify the interval to be processed.
    frame $f.fSelectInterval -bg $::Gui(activeWorkspace) -bd 2
    pack $f.fSelectInterval -side top -anchor w -fill x
    eval { label $f.fSelectInterval.lText -text "interval to process:" } $Gui(WLA)    
    eval { menubutton $f.fSelectInterval.mbIntervals -text "none" -width 18 -relief raised \
               -height 1 -menu $f.fSelectInterval.mbIntervals.m -bg $::Gui(activeWorkspace) \
               -indicatoron 1 } $Gui(WBA)
    eval { menu $f.fSelectInterval.mbIntervals.m } $Gui(WMA)
    foreach i $::Ibrowser(idList) {
        #puts "adding $::Ibrowser($i,name)"
        $f.mbVolumes.m add command -label $::Ibrowser($i,name) \
            -command "IbrowserSetActiveInterval $i"
    }
    set ::Ibrowser(Process,Reorient,mbIntervals) $f.fSelectInterval.mbIntervals
    bind $::Ibrowser(Process,Reorient,mbIntervals) <ButtonPress-1> "IbrowserUpdateReorientGUI"
    set ::Ibrowser(Process,Reorient,mIntervals) $f.fSelectInterval.mbIntervals.m
    pack $f.fSelectInterval.lText -pady 2 -padx 2 -anchor w
    pack $f.fSelectInterval.mbIntervals -pady 2 -padx 2 -anchor w
    
    #--- frame to configure and drive the reorienting
    frame $f.fConfiguration -bg $Gui(activeWorkspace) -bd 2 -relief groove
    pack $f.fConfiguration -side top -anchor w -padx 2 -pady 5 -fill x
    DevAddLabel $f.fConfiguration.lText "reorient volumes:"
    DevAddButton $f.fConfiguration.bFlipRL "flip R/L" "IbrowserFlipVolumeSequence RL" 20
    DevAddButton $f.fConfiguration.bFlipAP "flip A/P" "IbrowserFlipVolumeSequence AP" 20
    DevAddButton $f.fConfiguration.bFlipSI "flip S/I" "IbrowserFlipVolumeSequence SI" 20

    grid $f.fConfiguration.lText 
    grid $f.fConfiguration.lText -padx 3 -ipady 5
    
    grid $f.fConfiguration.bFlipRL
    grid $f.fConfiguration.bFlipRL -padx 3 -ipady 3

    grid $f.fConfiguration.bFlipAP
    grid $f.fConfiguration.bFlipAP -padx 3 -ipady 3

    grid $f.fConfiguration.bFlipSI
    grid $f.fConfiguration.bFlipSI -padx 3 -ipady 3

    place $f -in $master -relwidth 1.0 -relheight 1.0 -y 0

    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateReorientGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateReorientGUI { } {

    if { [info exists ::Ibrowser(Process,Reorient,mIntervals) ] } {
        set m $::Ibrowser(Process,Reorient,mIntervals)
        $m delete 0 end
        foreach id $::Ibrowser(idList) {
            $m add command -label $::Ibrowser($id,name)  \
                -command "IbrowserSetActiveInterval $id"
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserFlipVolumeSequence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserFlipVolumeSequence { axis } {

    #--- Flips a volume around axis.
    #--- Flipped vtkImageData replaces its source
    set iid $::Ibrowser(activeInterval)

    set firstID $::Ibrowser($iid,firstMRMLid)
    set lastID $::Ibrowser($iid,lastMRMLid)
    IbrowserRaiseProgressBar
    set pcount 0
    set numvols $::Ibrowser($iid,numDrops)
    
    #--- process each volume in the interval $iid.
    for { set v $firstID } { $v <= $lastID } { incr v } {
        if { $numvols != 0 } {
            set progress [ expr double ( $pcount ) / double ( $numvols ) ]
            IbrowserUpdateProgressBar $progress "::"
            #--- without something to make the application idle,
            #--- tk will not handle the drawing of progress bar.
            #--- Instead of calling update, which could cause
            #--- some unstable event loop, we just print some
            #--- '.'s to the tkcon. Slows things down a little,
            #--- but not terribly much. Better ideas are welcome.
            IbrowserPrintProgressFeedback
        }

        #--- get the corresponding axis in Vtk space.
        set newvec [ IbrowserGetRasToVtkAxis $axis ::Volume($v,node) ]
        #--- unpack the vector into x, y and z
        foreach { x y z } $newvec { }
        #puts "Final axis: $x $y $z"
        vtkImageFlip flip
        flip SetInput [ ::Volume($v,vol) GetOutput ]
        #--- now set the flip axis in VTK space
        if { ($x == 1) || ($x == -1) } {
            flip SetFilteredAxis 0
        } elseif { ($y == 1) || ( $y == -1) } {
            flip SetFilteredAxis 1
        } elseif { ($z == 1) || ($z == -1) } {
            flip SetFilteredAxis 2
        }
        ::Volume($v,vol) SetImageData [ flip GetOutput ]
        
        MainVolumesUpdate $v
        flip Delete
        incr pcount
    }
    IbrowserEndProgressFeedback
    RenderAll
    set tt "Flipped volumes in $::Ibrowser($iid,name) along $axis."
    IbrowserSayThis $tt 0
    IbrowserLowerProgressBar
    
}





#-------------------------------------------------------------------------------
# .PROC IbrowserFlipVolumeSequenceLR
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserFlipVolumeSequenceLR { } {
global Volume
    
    #--- Flips a volume around the vertical axis,
    #--- from left to right, around center.
    #--- Flipped vtkImageData replaces its source


    
    set iid $::Ibrowser(activeInterval)
    set firstID $::Ibrowser($iid,firstMRMLid)
    set lastID $::Ibrowser($iid,lastMRMLid)

    IbrowserRaiseProgressBar
    set pcount 0
    set numvols $::Ibrowser($iid,numDrops)
    
    for { set v $firstID } { $v <= $lastID } { incr v } {
        if { $numvols != 0 } {
            set progress [ expr double ( $pcount ) / double ( $numvols ) ]
            IbrowserUpdateProgressBar $progress "::"
            #--- without something to make the application idle,
            #--- tk will not handle the drawing of progress bar.
            #--- Instead of calling update, which could cause
            #--- some unstable event loop, we just print some
            #--- '.'s to the tkcon. Slows things down a little,
            #--- but not terribly much. Better ideas are welcome.
            IbrowserPrintProgressFeedback
        }

        vtkImageFlip flipLR
        flipLR SetInput [ ::Volume($v,vol) GetOutput ]

        #--- translate the flipaxis to VTK space
        set newvec [ IbrowserGetRasToVtkAxis RL ::Volume($vid,node) ]
        #--- unpack the vector into x, y and z
        foreach { x y z } $newvec { }
        #--- set the appropriate parameters
        if { ($x == 1) || ($x == -1) } {
            flipLR SetFilteredAxis 0
        } elseif { ($y == 1) || ( $y == -1) } {
            flipLR SetFilteredAxis 1
        } elseif { ($z == 1) || ($z == -1) } {
            flipLR SetFilteredAxis 2
        }

        #flipLR SetFilteredAxis 0
        ::Volume($v,vol) SetImageData [ flipLR GetOutput ]
        
        MainVolumesUpdate $v
        flipLR Delete
        incr pcount
    }
    IbrowserEndProgressFeedback
    RenderAll
    set tt "Flipped volumes in $::Ibrowser($iid,name) from L to R."
    IbrowserSayThis $tt 0
    IbrowserLowerProgressBar
    
    #--- keeps track of whether the volume is LR flipped
    if { $::Ibrowser($iid,LRFlip) == 1 } {
        set ::Ibrowser($iid,LRFlip) 0
    } else {
        set ::Ibrowser($iid,LRFlip) 1
    }


}

#-------------------------------------------------------------------------------
# .PROC IbrowserFlipVolumeSequenceAP
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserFlipVolumeSequenceAP { } {
global Volume
    
    #--- Flips a volume from anterior to posterior.
    #--- Flipped vtkImageData replaces its source

    set iid $::Ibrowser(activeInterval)
    set firstID $::Ibrowser($iid,firstMRMLid)
    set lastID $::Ibrowser($iid,lastMRMLid)

    IbrowserRaiseProgressBar
    set pcount 0
    set numvols $::Ibrowser($iid,numDrops)
    
    for { set v $firstID } { $v <= $lastID } { incr v } {
        if { $numvols != 0 } {
            set progress [ expr double ( $pcount ) / double ( $numvols ) ]
            IbrowserUpdateProgressBar $progress "::"
            #--- without something to make the application idle,
            #--- tk will not handle the drawing of progress bar.
            #--- Instead of calling update, which could cause
            #--- some unstable event loop, we just print some
            #--- '.'s to the tkcon. Slows things down a little,
            #--- but not terribly much. Better ideas are welcome.
            IbrowserPrintProgressFeedback
        }

        vtkImageFlip flipAP
        flipAP SetInput [ ::Volume($v,vol) GetOutput ]

        #--- translate the flipaxis to VTK space
        set newvec [ IbrowserGetRasToVtkAxis RL ::Volume($vid,node) ]
        #--- unpack the vector into x, y and z
        foreach { x y z } $newvec { }
        #--- set the appropriate parameters
        if { ($x == 1) || ($x == -1) } {
            flipAP SetFilteredAxis 0
        } elseif { ($y == 1) || ( $y == -1) } {
            flipAP SetFilteredAxis 1
        } elseif { ($z == 1) || ($z == -1) } {
            flipAP SetFilteredAxis 2
        }

        #flipAP SetFilteredAxis 1
        ::Volume($v,vol) SetImageData [ flipAP GetOutput ]
        
        MainVolumesUpdate $v
        flipAP Delete
        incr pcount
    }
    IbrowserEndProgressFeedback
    RenderAll
    set tt "Flipped volumes in $::Ibrowser($iid,name) from A to P"
    IbrowserSayThis $tt 0
    IbrowserLowerProgressBar
    
    #--- keeps track of whether the volume is LR flipped
    if { $::Ibrowser($iid,APFlip) == 1 } {
        set ::Ibrowser($iid,APFlip) 0
    } else {
        set ::Ibrowser($iid,APFlip) 1
    }


}




#-------------------------------------------------------------------------------
# .PROC IbrowserFlipVolumeSequenceIS
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserFlipVolumeSequenceIS { } {
global Volume

    #--- Flips a volume around the horizontal axis,
    #--- from up to down, around center.
    #--- Flipped vtkImageData replaces its source    

    set iid $::Ibrowser(activeInterval)
    set firstID $::Ibrowser($iid,firstMRMLid)
    set lastID $::Ibrowser($iid,lastMRMLid)

    IbrowserRaiseProgressBar
    set pcount 0
    set numvols $::Ibrowser($iid,numDrops)

    for { set v $firstID } { $v <= $lastID } { incr v } {
        if { $numvols != 0 } {
            set progress [ expr double ( $pcount ) / double ( $numvols ) ]
            IbrowserUpdateProgressBar $progress "::"
            #--- without something to make the application idle,
            #--- tk will not handle the drawing of progress bar.
            #--- Instead of calling update, which could cause
            #--- some unstable event loop, we just print some
            #--- '.'s to the tkcon. Slows things down a little,
            #--- but not terribly much. Better ideas are welcome.
            IbrowserPrintProgressFeedback
        }
        
        vtkImageFlip flipIS
        flipIS SetInput [ ::Volume($v,vol) GetOutput ]

        #--- translate the flipaxis to VTK space
        set newvec [ IbrowserGetRasToVtkAxis RL ::Volume($vid,node) ]
        #--- unpack the vector into x, y and z
        foreach { x y z } $newvec { }
        #--- set the appropriate parameters
        if { ($x == 1) || ($x == -1) } {
            flipIS SetFilteredAxis 0
        } elseif { ($y == 1) || ( $y == -1) } {
            flipIS SetFilteredAxis 1
        } elseif { ($z == 1) || ($z == -1) } {
            flipIS SetFilteredAxis 2
        }

        #flipIS SetFilteredAxis 2
        ::Volume($v,vol) SetImageData [ flipIS GetOutput ]
        
        MainVolumesUpdate $v
        flipIS Delete
        incr pcount
    }
    IbrowserEndProgressFeedback
    RenderAll
    set tt "Flipped volumes in $::Ibrowser($iid,name) from I to S."
    IbrowserSayThis $tt 0

    IbrowserLowerProgressBar

    #--- keeps track of whether the volume is IS flipped
    if { $::Ibrowser($iid,ISFlip) == 1 } {
        set ::Ibrowser($iid,ISFlip) 0
    } else {
        set ::Ibrowser($iid,ISFlip) 1
    }

}


#-------------------------------------------------------------------------------
# .PROC IbrowserHelpReorient
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserHelpReorient { } {

    set i [ IbrowserGetHelpWinID ]
    set txt "<H3>Reorient</H3>
 <P> This tool reorients all volumes in a selected interval by flipping them along a specified axis:
<P>   Right to Left (R/L),
<P>   Anterior to Posterior (A/P), or
<P>   Superior to Inferior (S/I)."
    DevCreateTextPopup infowin$i "Ibrowser information" 100 100 18 $txt
}


