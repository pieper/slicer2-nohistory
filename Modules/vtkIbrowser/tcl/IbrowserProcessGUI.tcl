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
# FILE:        IbrowserProcessGUI.tcl
# PROCEDURES:  
#   IbrowserUpdateProcessTab
#   IbrowserBuildProcessFrame
#   IbrowserRaiseProcessingFrame
#   IbrowserProcessingSelectInternalReference
#   IbrowserProcessingSelectExternalReference
#   IbrowserResetSelectSequence
#   IbrowserResetInternalReference
#   IbrowserAddSingleTransform
#   IbrowserAddTransforms
#   IbrowserAddNonReferenceTransforms
#   IbrowserAddWholeIntervalTransform
#   IbrowserRemoveSingleTransform
#   IbrowserCleanUpEmptyTransformNodes
#   IbrowserCallOutNodes
#   IbrowserRemoveTransforms
#   IbrowserRemoveNonReferenceTransforms
#   IbrowserRemoveWholeIntervalTransform
#   IbrowserGetRasToVtkAxis
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateProcessTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateProcessTab { } {

    set ::Ibrowser(currentTab) "Process"
}



#-------------------------------------------------------------------------------
# .PROC IbrowserBuildProcessFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBuildProcessFrame { } {
    global Gui
    
    #-------------------------------------------
    #--- general processing frame
    #-------------------------------------------
    set fProcess $::Module(Ibrowser,fProcess)
    bind $::Module(Ibrowser,bProcess) <ButtonPress-1> "IbrowserUpdateProcessTab"
    set f $fProcess

    frame $f.fProcessMaster -relief groove -bg $::Gui(backdrop) -bd 3
    #--- This frame's size determines the height of all processing frames
    #--- placed within it. I'd like to have each of the placed frames have
    #--- control the size of the master frame, but can't figure out how
    #--- to do that. For now, Just set the height here when you need more room.
    frame $f.fProcessInfo -relief groove -bg $::Gui(activeWorkspace) -bd 3 -height 350
    pack $f.fProcessMaster -side top -padx 0 -pady $::Gui(pad) -fill x 
    pack $f.fProcessInfo -side top -padx 0 -pady $::Gui(pad) -fill both -expand 1 


    #-------------------------------------------
    #--- Catalog of all processing that the Ibrowser can do:
    #-------------------------------------------
    foreach process $::Ibrowser(Process,AllProcesses) {
        set ::Ibrowser(Process,Text,${process}) $process
    }

    #-------------------------------------------
    #--- ProcessInfo frame; one raised for each process.
    #--- Developers: Create new process frames here
    #--- and put the code in IbrowserProcessing subdir.
    #-------------------------------------------
    set ff $f.fProcessInfo
    foreach process $::Ibrowser(Process,AllProcesses) {
        frame $ff.f${process} -bg $::Gui(activeWorkspace)
        IbrowserBuild${process}GUI $ff.f${process} $f.fProcessInfo
    }
    raise $ff.fReorient

    #-------------------------------------------
    #--- fProcess->fProcessMaster
    #--- Build pull-down GUI for processes
    #--- inside the ProcessMaster frame
    #--- Developers: Add new processes here.
    #-------------------------------------------
    set ff $f.fProcessMaster
    eval {label $ff.lChoose -text "Select processing: " -width 15 -justify right } $::Gui(BLA)
    pack $ff.lChoose -side left -padx $::Gui(pad) -fill x -anchor w
    #--- build a menu button with a pull-down menu
    #--- of processing options
    eval { menubutton $ff.mbProcessType -text \
               $::Ibrowser(Process,Text,Reorient) \
               -relief raised -bd 2 -width 25 \
               -menu $ff.mbProcessType.m -indicatoron 1} $::Gui(WMBA)
    #--- save menu button for configuring its text later
    set ::Ibrowser(Process,ProcessSelectionButton) $ff.mbProcessType
    pack $ff.mbProcessType -side left -pady 1 -padx $::Gui(pad)
    #-------------------------------------------
    #--- make menu that pulls down from menubutton.
    #--- Developers: add your new processes in foreach list
    #-------------------------------------------
    eval { menu $ff.mbProcessType.m } $::Gui(WMA)

    foreach r $::Ibrowser(Process,AllProcesses) {
        $ff.mbProcessType.m add command -label $r \
            -command "IbrowserRaiseProcessingFrame $::Ibrowser(Process,Text,${r}) $::Ibrowser(fProcess${r})"
    }

    #--- By default, raise first frame on th process list.
    raise $::Ibrowser(fProcessReorient)
}




#-------------------------------------------------------------------------------
# .PROC IbrowserRaiseProcessingFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRaiseProcessingFrame { menuText processFrame } {

    $::Ibrowser(Process,ProcessSelectionButton) config -text $menuText
    raise $processFrame
}





#-------------------------------------------------------------------------------
# .PROC IbrowserProcessingSelectInternalReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserProcessingSelectInternalReference { name id } {
    #---
    #--- name gives the text that goes on the menu
    #--- and id gives the MRML id of the volume in the sequence
    #--- to be used as the reference volume.
    #--- specifies a reference volume within the sequence being processed.
    set ::Ibrowser(Process,InternalReference) $id
    foreach process "MotionCorrect KeyframeRegister" {
        if { [info exists ::Ibrowser(Process,$process,mbReference)] } {
            $::Ibrowser(Process,$process,mbReference) config -text $name
        }
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserProcessingSelectExternalReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserProcessingSelectExternalReference { name id } {
    #---
    #---specifies a reference sequence outside the sequence being processed.
    set ::Ibrowser(Process,ExternalReference) $id
    foreach process "KeyframeRegister" {
        if { [info exists ::Ibrowser(Process,$process,mbReference)] } {
            $::Ibrowser(Process,$process,mbReference) config -text $name
        }
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserResetSelectSequence
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserResetSelectSequence { } {
    #---
    #--- sets the selected sequence to be "none" in all menus.
    IbrowserSetActiveInterval $::Ibrowser(idNone)
    #set ::Ibrowser(Process,SelectSequence) $::Ibrowser(idNone)
    IbrowserUpdateMRML
}



#-------------------------------------------------------------------------------
# .PROC IbrowserResetInternalReference
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserResetInternalReference { } {

    #--- Each time the user selects a new sequence,
    #--- a new reference should be specified. So, this proc
    #--- resets the reference to 'none' when the
    #--- sequence has changed. 
    set ::Ibrowser(Process,SelectIntReference) $::Volume(idNone)
    IbrowserUpdateMRML


}



#-------------------------------------------------------------------------------
# .PROC IbrowserAddSingleTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddSingleTransform { iid vid drop } {
global Volume
    
        set mid [ DataAddTransform 0 Volume($vid,node) Volume($vid,node) ]
        #--- save a way to find this matrix later.
        set ::Ibrowser($iid,$drop,matrixID) $mid
        set ::Ibrowser($iid,$drop,transformID) [ expr $::Transform(nextID) - 1 ]
}


#-------------------------------------------------------------------------------
# .PROC IbrowserAddTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddTransforms { } {
    global Data Mrml Volume

    #--- Add Transform, Matrix, and EndTransform
    #--- Transform will enclose each volume node in the active interval.

    #--- ID of selected sequence
    set id $::Ibrowser(activeInterval)
    IbrowserRaiseProgressBar
    set pcount 0
    IbrowserSayThis "Adding transforms for $::Ibrowser($id,name)..." 0
    
    #--- for each volume within the sequence:
    #--- add a new transform node for each volume
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        if { $::Ibrowser($id,numDrops)  != 0 } {
            set progress [ expr double ($pcount) / double ($::Ibrowser($id,numDrops)) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }
        
        set vid $::Ibrowser($id,$i,MRMLid)
        IbrowserAddSingleTransform $id $vid $i
        incr pcount
    }
    IbrowserEndProgressFeedback
    IbrowserSayThis "Transforms for $::Ibrowser($id,name) added." 0
    MainUpdateMRML
    IbrowserLowerProgressBar
}



#-------------------------------------------------------------------------------
# .PROC IbrowserAddNonReferenceTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddNonReferenceTransforms { } {

    #--- Add Transform, Matrix, and EndTransform
    #--- Transform will enclose each volume node in the active interval
    #--- except for the reference volume, if that's included in the interval.

    #--- ID of selected sequence
    set refvol $::Ibrowser(Process,InternalReference)
    set id $::Ibrowser(activeInterval)
    IbrowserRaiseProgressBar
    set pcount 0
    IbrowserSayThis "Adding transforms for $::Ibrowser($id,name)..." 0
    
    #--- for each volume within the sequence:
    #--- add a new transform node for each volume
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        if { $::Ibrowser($id,numDrops)  != 0 } {
            set progress [ expr double ($pcount) / double ($::Ibrowser($id,numDrops)) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }
        set vid $::Ibrowser($id,$i,MRMLid)
        #--- exclude the reference volume, which should not have a transform.
        if { $vid != $refvol } {
            IbrowserAddSingleTransform $id $vid $i
            incr pcount
        }
    }
    IbrowserEndProgressFeedback
    IbrowserSayThis "Transforms for $::Ibrowser($id,name) added." 0
    MainUpdateMRML
    IbrowserLowerProgressBar
}




#-------------------------------------------------------------------------------
# .PROC IbrowserAddWholeIntervalTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddWholeIntervalTransform { iid } {
    global Data Mrml Volume

    #--- Add Transform, Matrix, and EndTransform
    #--- Transform will enclose all volumes in the active interval.
    
    IbrowserSayThis "Adding transform node around interval $::Ibrowser($iid,name)..." 0
    set firstvol $::Ibrowser($iid,firstMRMLid)
    set lastvol $::Ibrowser($iid,lastMRMLid)
    
    set mid [ DataAddTransform 0 Volume($firstvol,node) Volume($lastvol,node) ]
    set ::Ibrowser($iid,matrixID) $mid
    set ::Ibrowser($iid,transformID) [ expr $::Transform(nextID) - 1 ]
    
    IbrowserSayThis "Transform for $::Ibrowser($iid,name) added." 0
    MainUpdateMRML
}






#-------------------------------------------------------------------------------
# .PROC IbrowserRemoveSingleTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRemoveSingleTransform { iid drop } {

    set deleteFailed 0
    if { [ info exists ::Ibrowser($iid,$drop,transformID) ] } {
        set tID $::Ibrowser($iid,$drop,transformID)
        #---traverse the mrml tree to search for it
        set gotnode 0
        ::Mrml(dataTree) InitTraversal
        #--- what element is it in the Mrml tree?
        set whichNode 0
        set tstnode [ Mrml(dataTree) GetNextItem ]

        while { $tstnode != "" } {
            if { [string compare -length 9 $tstnode "Transform"] == 0 } {
                if { [$tstnode GetID ] == $tID } {
                    #--- found target transform node
                    set gotnode 1
                    break
                }
            }
            set tstnode [ Mrml(dataTree) GetNextItem ]                
            incr whichNode
        }

        #--- if we got the node, remove the node, end node
        #--- and the matrix node too using the Data module's procs.
        #--- if we've not found the transform node, but it's
        #--- supposed to be there, then report an error. 
        if { $gotnode } {
            $::Data(fNodeList) selection set $whichNode $whichNode
            DataDeleteNode
            unset -nocomplain ::Ibrowser($iid,$drop,transformID)
            unset -nocomplain ::Ibrowser($iid,$drop,matrixID)
        } else {
            set deleteFailed 1
        }
        $::Data(fNodeList) selection clear $whichNode $whichNode
    }
    if { $deleteFailed } {
        return 1
    } else {
        return 0
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserCleanUpEmptyTransformNodes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCleanUpEmptyTransformNodes { } {

    set clean 0

    while { $clean == 0 } {
        set del 0
        set N 0
        ::Mrml(dataTree) InitTraversal
        set tstnode [ ::Mrml(dataTree) GetNthItem $N ]

        while { $tstnode != "" } {
            #puts "tstnode = $tstnode"
            if { [string compare -length 9 $tstnode "Transform" ] == 0 } {
                #--- Found a transform node.
                #--- Check to see if next node is matrix node AND
                #--- next-next node is endTransform node. If so,
                #--- we've found an empty one, and we delete it.
                set testM [ ::Mrml(dataTree) GetNthItem [expr $N+1] ]
                if { $testM != "" } {
                    #puts "testM = $testM"
                    set testE [ ::Mrml(dataTree) GetNthItem [expr $N+2] ]
                    if { $testE != "" } {
                        #puts "testE = $testE"
                        if { ([string compare -length 6 $testM "Matrix"] == 0) &&
                             ([string compare -length 12 $testE "EndTransform"] == 0) } {
                            #--- Found an empty transform node. Delete it.
                            $::Data(fNodeList) selection set $N $N
                            DataDeleteNode
                            $::Data(fNodeList) selection clear $N $N
                            #puts "N=$N Deleting Transform node $tstnode"
                            set del 1
                            break
                        }
                    } else {
                        #--- Found Transform with no closed EndTransform. Delete.
                        $::Data(fNodeList) selection set $N $N
                        DataDeleteNode
                        $::Data(fNodeList) selection clear $N $N
                        #puts "N=$N Deleting Unclosed Transform node $tstnode"
                        set del 1
                        break
                    }
                } else {
                    #--- Found Transform with no closed EndTransform. Delete.
                    $::Data(fNodeList) selection set $N $N
                    DataDeleteNode
                    $::Data(fNodeList) selection clear $N $N
                    #puts "N=$N Deleting Unclosed Transform node $tstnode"
                    set del 1
                    break
                }
            }
            incr N
            set tstnode [ ::Mrml(dataTree) GetNthItem $N ]            
        }
        #while
       #--- if we have arrived here, then we know tree is clean
        if { $del == 0 } {
            set clean 1
            #puts "Mrml tree clean."
        }
    }
    #while
}





#-------------------------------------------------------------------------------
# .PROC IbrowserCallOutNodes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCallOutNodes { } {

    ::Mrml(dataTree) InitTraversal
    set N 0
    set tstnode [ ::Mrml(dataTree) GetNthItem $N ]
    while { $tstnode != "" } {
        puts "N=$N $tstnode"
        incr N
        set tstnode [ ::Mrml(dataTree) GetNthItem $N ]
    }
    

}



#-------------------------------------------------------------------------------
# .PROC IbrowserRemoveTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRemoveTransforms { } {

    #--- ID of selected sequence
    set id $::Ibrowser(activeInterval)

    #--- For each volume within the interval, delete the last
    #--- transform applied to it.
    IbrowserSayThis "Removing transforms for $::Ibrowser($id,name)..." 0
    IbrowserRaiseProgressBar
    set pcount 0
    set deleteFailed 0

    #--- look at each volume in the interval
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        if { $::Ibrowser($id,numDrops) != 0 } {
            set progress [ expr double ($pcount) / double ($::Ibrowser($id,numDrops)) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }
        #--- if a volume has a saved transform id,
        #--- Find the transform in the mrml tree,
        #--- determine which element in the tree it is,
        #--- and use procs in data.tcl to remove it and matrix nodes inside.
        set deleteFailed [ IbrowserRemoveSingleTransform $id $i ]
        incr pcount
    }
    if { $deleteFailed } {
        DevErrorWindow "Some transforms may not have been properly deleted."
        IbrowserSayThis "Problem deleting transforms for $::Ibrowser($id,name)." 0
    } else {
        IbrowserSayThis "Transforms for $::Ibrowser($id,name) deleted." 0
    }
    MainUpdateMRML
    IbrowserEndProgressFeedback
    #IbrowserResetSelectSequence
    IbrowserResetInternalReference
    IbrowserLowerProgressBar
}






#-------------------------------------------------------------------------------
# .PROC IbrowserRemoveNonReferenceTransforms
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRemoveNonReferenceTransforms { } {

    set refvol $::Ibrowser(Process,InternalReference)
    #--- ID of selected sequence
    set id $::Ibrowser(activeInterval)

    if { $id == $::Ibrowser(none,intervalID) } {
        return
    }
    
    #--- For each volume within the interval (except for the
    #--- reference volume, if it is inside the interval), delete 
    #--- the last transform applied to it.
    IbrowserSayThis "Removing transforms for $::Ibrowser($id,name)..." 0
    IbrowserRaiseProgressBar
    set pcount 0
    set deleteFailed 0

    #--- Look at each volume node in the sequence:
    for { set i 0 } { $i < $::Ibrowser($id,numDrops) } { incr i } {
        if { $::Ibrowser($id,numDrops) != 0 } {
            set progress [ expr double ($pcount) / double ($::Ibrowser($id,numDrops)) ]
            IbrowserUpdateProgressBar $progress "::"
            IbrowserPrintProgressFeedback
        }
        
        set vid $::Ibrowser($id,$i,MRMLid)
        #--- exclude the reference volume 
        if {$vid != $refvol } {
            #--- if a volume has a saved transform id,
            #--- Find the transform in the mrml tree,
            #--- determine which element in the tree it is,
            #--- and use procs in data.tcl to remove it and matrix nodes inside.
            set deleteFailed [ IbrowserRemoveSingleTransform $id $i ]
            incr pcount
        }
    }
    if { $deleteFailed } {
        DevErrorWindow "Some transforms may not have been properly deleted."
        IbrowserSayThis "Problem deleting transforms for $::Ibrowser($id,name)." 0
    } else {
        IbrowserSayThis "Transforms for $::Ibrowser($id,name) deleted." 0
    }
    IbrowserEndProgressFeedback
    #IbrowserResetSelectSequence
    IbrowserResetInternalReference
    IbrowserLowerProgressBar
    MainUpdateMRML
}



#-------------------------------------------------------------------------------
# .PROC IbrowserRemoveWholeIntervalTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRemoveWholeIntervalTransform { iid } {
    global Data Mrml Volume


    set deleteFailed 0
    #--- find the transform node and the matrix mode.
    #--- see if the node has a transform node wrapped around it.

    if { [ info exists ::Ibrowser($iid,transformID) ] } {
        set tID $::Ibrowser($iid,transformID)
        #---traverse the mrml tree to search for it
        set gotnode 0
        ::Mrml(dataTree) InitTraversal
        #--- what element is it in the Mrml tree?
        set whichNode 0
        set tstnode [ Mrml(dataTree) GetNextItem ]

        while { $tstnode != "" } {
            if { [string compare -length 9 $tstnode "Transform"] == 0 } {
                if { [$tstnode GetID ] == $tID } {
                    #--- found target transform node
                    set gotnode 1
                    break
                }
            }
            set tstnode [ Mrml(dataTree) GetNextItem ]                
            incr whichNode
        }

        #--- if we got the node, remove the node, end node
        #--- and the matrix node too using the Data module's procs.
        #--- if we've not found the transform node, but it's
        #--- supposed to be there, then report an error. 
        if { $gotnode } {
            $::Data(fNodeList) selection set $whichNode $whichNode
            DataDeleteNode
            unset -nocomplain ::Ibrowser($iid,transformID)
            unset -nocomplain ::Ibrowser($iid,matrixID)
        } else {
            set deleteFailed 1
        }
        $::Data(fNodeList) selection clear $whichNode $whichNode
    }

    if { $deleteFailed } {
        DevErrorWindow "Interval transform may not have been properly deleted."
        IbrowserSayThis "Problem deleting transform for $::Ibrowser($iid,name)." 0
    } else {
        IbrowserSayThis "Transform for $::Ibrowser($iid,name) deleted." 0
    }
    MainUpdateMRML
    #IbrowserResetSelectSequence
    IbrowserResetInternalReference
    IbrowserSayThis "Transform for $::Ibrowser($iid,name) deleted." 0

}




#-------------------------------------------------------------------------------
# .PROC IbrowserGetRasToVtkAxis
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetRasToVtkAxis { axis vnode } {
    #
    #--- Given an axis in RAS space, we want
    #--- to find the axis that corresponds in VTK 
    #--- space (which describes the vtkImageData
    #--- represented by a vtkMrmlVolumeNode.)
    #
    #--- create a vtkTransform
    vtkTransform T
    #--- get the transform matrix in string form
    #--- and set it to be the transform's matrix.
    set m [ $vnode GetRasToVtkMatrix ]
    eval T SetMatrix $m

    #--- axis along which to flip in VTK space
    if { $axis == "RL" } {
        #--- if Flipping along R-L
        #puts "RAS axis 1 0 0"
        set newvec [ T TransformFloatVectorAtPoint 0 0 0 -1 0 0 ]
    } elseif { $axis == "AP" } {
        #--- if flipping along A-P
        #puts "RAS axis 0 1 0"
        set newvec [ T TransformFloatVectorAtPoint 0 0 0 0 -1 0 ]
    } elseif { $axis == "SI" } {
        #--- if flipping along S-I
        #puts "RAS axis 0 0 1"
        set newvec [ T TransformFloatVectorAtPoint 0 0 0 0 0 -1 ]
    }
    foreach { x y z } $newvec { }
    #puts "VTK axis: $x $y $z"
    #--- because of scale, newvec might not be unit
    if { $x != 0 } {
        set newvec [ lreplace $newvec 0 0 1 ]
    }
    if { $y != 0 } {
        set newvec [ lreplace $newvec 1 1 1 ]
    }
    if { $z != 0 } {
        set newvec [ lreplace $newvec 2 2 1 ]
    }
    
    #--- clean up
    T Delete
    #--- return the new axis as a vector.
    return $newvec
}

