#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdFastMarching.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:39 $
#   Version:   $Revision: 1.26 $
# 
#===============================================================================
# FILE:        EdFastMarching.tcl
# PROCEDURES:  
#   EdFastMarchingInit
#   EdFastMarchingBuildGUI
#   ConversiontomL Voxels
#   ConversiontoVoxels mL
#   EdFastMarchingUserExpand zero userExpand
#   EdFastMarchingExpand
#   Called whenever we enter the FastMarching tab
#   EdFastMarchingExit
#   EdFastMarchingLabel
#   EdFastMarchingSegment
#   EdFastMarchingApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingInit {} {
    global Ed Gui EdFastMarching Volume Slice Fiducials

    set e EdFastMarching
    set Ed($e,name)      "Fast Marching"
    set Ed($e,initials)  "Fm"
    set Ed($e,desc)      "Fast Marching: 3D segmentation"
    set Ed($e,rank)      14;
    set Ed($e,procGUI)   EdFastMarchingBuildGUI
    set Ed($e,procEnter) EdFastMarchingEnter
    set Ed($e,procExit)  EdFastMarchingExit

    # Define Dependencies
    set Ed($e,depend) Fiducials 
    set EdFastMarching(fastMarchingInitialized) 0

    # Required
    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active

    set EdFastMarching(nExpand) 10
    set EdFastMarching(userExpand) 0
    set EdFastMarching(totalExpand) 0

    set EdFastMarching(majorVersionTCL) 3
    set EdFastMarching(minorVersionTCL) 1
    set EdFastMarching(dateVersionTCL) "2003-1-27/20:00EST"

    set EdFastMarching(versionTCL) "$EdFastMarching(majorVersionTCL).$EdFastMarching(minorVersionTCL) \t($EdFastMarching(dateVersionTCL))"

    set EdFastMarching(shouldDisplayWarningVersion) 1

}

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingBuildGUI {} {
    global Ed Gui Label Volume EdFastMarching Fiducials Help

    set e EdFastMarching
    #-------------------------------------------
    # FastMarching frame
    #-------------------------------------------

    set f $Ed(EdFastMarching,frame)

    #copied from EdPhaseWireBuildGUI

    set label ""
    set subframes {Help Basic Advanced}
    set buttonText {"Help" "Basic" "Advanced"}
    set tooltips { "Help: We all need it sometimes." \
        "Basic: For Users" \
        "Advanced: For Developers"}
    set extraFrame 0
    set firstTab Basic

    TabbedFrame EdFastMarching $f $label $subframes $buttonText \
        $tooltips $extraFrame $firstTab

    #-------------------------------------------
    # TabbedFrame->Help frame
    #-------------------------------------------
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fHelp

    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true

    set Ed(EdFastMarching,helpWidget) [HelpWidget $f.fWidget]

    set help "DISCLAIMER: this module is for development only!
Eric Pichon <eric@ece.gatech.edu>

Online tutorial available at:
http://users.ece.gatech.edu/~eric/research/slicer

3D segmentation using Partial Differential Equations.

To segment a volume :

- Define a label for the segmented data : by clicking on the 'Label' button. 

- Define some seed points : by creating some fiducials inside (not on the border of) the region of interest. Fiducials can be created by moving the pointer to the desired region and pressing the 'p' key.  See the Fiducial module documentation for more on using fiducials.

- Start expansion of the surface : by clicking on the 'Expand' button.  The volume of the surface will be expanded by the value right of the expand button.  Increase this value to segment a bigger object.


If the expansion did not go far enough. add new seeds in the regions that were not reached and/or press 'Expand' again.

If the expansion went too far ('leaked' out of the region of interest), use the slider to reverse the last expansion to the point before leaking occurred.

When satisfied with the segmentation use other editing modules on the labelmap (morphological operations...) and/or create a model.
"
    eval $Ed(EdFastMarching,helpWidget) tag configure normal   $Help(tagNormal)

    $Ed(EdFastMarching,helpWidget) insert insert "$help" normal

    #-------------------------------------------
    # TabbedFrame->Basic frame
    #-------------------------------------------
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fBasic
 
    frame $f.fLogo     -bg $Gui(activeWorkspace)
    frame $f.fGrid     -bg $Gui(activeWorkspace)
    frame $f.fExpand   -bg $Gui(activeWorkspace)
    frame $f.fUserExpand   -bg $Gui(activeWorkspace)

    pack $f.fLogo $f.fGrid $f.fExpand $f.fUserExpand \
        -side top -fill x 

    #-------------------------------------------
    # FastMarching->Logo Frame
    #-------------------------------------------
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fBasic.fLogo
    if { [file exists $::env(SLICER_HOME)/Modules/vtkFastMarching/images/gatech.ppm] } {
        set im [image create photo -file $::PACKAGE_DIR_VTKFASTMARCHING/../../../images/gatech.ppm]
        pack [label $f.logo -image $im]
    } else {
        pack [label $f.logo -text "Georgia Tech"]
    }

    #-------------------------------------------
    # FastMarching->Grid frame
    #-------------------------------------------
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fBasic.fGrid

    # Output label
    eval {button $f.bOutput -text "Label:" \
          -command "ShowLabels EdFastMarchingLabel"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdFastMarchingLabel"
    bind $f.eOutput <FocusOut> "EdFastMarchingLabel"
    eval {entry $f.eName -width 14 -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w

    lappend Label(colorWidgetList) $f.eName

    #-------------------------------------------
    # FastMarching->Expand frame
    #-------------------------------------------
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fBasic.fExpand

    # Output label
    eval {button $f.bExpand -text "EXPAND" \
          -command "EdFastMarchingExpand"} $Gui(WBA)
    eval {entry $f.eExpand -width 6 -textvariable EdFastMarching(nExpand)} $Gui(WEA)

    eval {label $f.lTextUnit -text "mL"} $Gui(WLA)

    grid $f.bExpand $f.eExpand $f.lTextUnit -padx 2 -pady $Gui(pad)

    set f $Ed(EdFastMarching,frame).fTabbedFrame.fBasic.fUserExpand

    eval {scale $f.sExpand -from 0.0 -to 1.0 \
            -length 220 -variable EdFastMarching(userExpand) -resolution 1 -orient horizontal \
            -command "EdFastMarchingUserExpand $EdFastMarching(userExpand)"} \
            $Gui(WSA) -showvalue true -digits 4 -resolution .01 {-sliderlength 22}
    
    $f.sExpand configure -to $EdFastMarching(totalExpand) 
    grid $f.sExpand -sticky w
    #-------------------------------------------
    # TabbedFrame->Advanced frame
    #-------------------------------------------
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fAdvanced

    frame $f.fVersion     -bg $Gui(activeWorkspace)

    pack $f.fVersion -side top -fill x 

    #-------------------------------------------
    # TabbedFrame->Advanced->version frame
    #-------------------------------------------

    set f $Ed(EdFastMarching,frame).fTabbedFrame.fAdvanced.fVersion

    eval {label $f.lTextCXX -text "CXX version: "} $Gui(WLA)
    eval {label $f.lCXX -textvariable EdFastMarching(versionCXX) } $Gui(WLA)
    grid $f.lTextCXX $f.lCXX -padx 2
 
    eval {label $f.lTextTCL -text "TCL version: " } $Gui(WLA)
    eval {label $f.lTCL -textvariable EdFastMarching(versionTCL) } $Gui(WLA)
    grid $f.lTextTCL $f.lTCL -padx 2 -pady $Gui(pad)
}

#-------------------------------------------------------------------------------
# .PROC ConversiontomL
# 
# .ARGS
# int Voxels
# .END
#-------------------------------------------------------------------------------
proc ConversiontomL {Voxels} {
    global EdFastMarching Ed

    set e EdFastMarching
    set v [EditorGetInputID $Ed($e,input)]
     
    scan [Volume($v,node) GetSpacing] "%f %f %f" dx dy dz
    set voxelvolume [expr $dx * $dy * $dz]
    set conversion 1000
      
    set voxelamount [expr $Voxels * $voxelvolume]
    set mL [expr round($voxelamount) / $conversion]

    return $mL
}

#-------------------------------------------------------------------------------
# .PROC ConversiontoVoxels
# 
# .ARGS
# float mL
# .END
#-------------------------------------------------------------------------------
proc ConversiontoVoxels {mL} {
    global EdFastMarching Ed

    set e EdFastMarching
    set v [EditorGetInputID $Ed($e,input)]
     
    scan [Volume($v,node) GetSpacing] "%f %f %f" dx dy dz
    set voxelvolume [expr $dx * $dy * $dz]
    set conversion 1000
      
    set voxelamount [expr $mL / $voxelvolume]
    set Voxels [expr round($voxelamount) * $conversion]

    return $Voxels
}

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingUserExpand
# 
# .ARGS
# string zero Not used
# string userExpand
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingUserExpand {zero userExpand} {
    global EdFastMarching

    if {$EdFastMarching(fastMarchingInitialized) != 0} {
        set e EdFastMarching

        set Ed($e,scope)  3D 
        set Ed($e,input)  Original
        set Ed($e,interact) Active   

        set v [EditorGetInputID $Ed($e,input)]

        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
        Ed(editor)  UseInputOn
        
        if {$EdFastMarching(totalExpand) > 0} {
            EdFastMarching(FastMarching) show [expr $userExpand/$EdFastMarching(totalExpand)]


            # the progress bar should not be updated
            #     EdFastMarching(FastMarching) SetStartMethod     ""
            #     EdFastMarching(FastMarching) SetProgressMethod  ""
            #     EdFastMarching(FastMarching) SetEndMethod       ""

            EdFastMarching(FastMarching) Modified
            EdFastMarching(FastMarching) Update

            set w [EditorGetWorkingID]

            MainVolumesUpdate $w

            # Update the effect panel GUI by re-running it's Enter procedure
            #EditorUpdateEffect
            
            # Mark the volume as changed
            set Volume($w,dirty) 1
            
            RenderAll


            #[Volume($w,vol) GetOutput] Modified
            #[Volume($w,vol) GetOutput] Update

            #set Volume($w,dirty) 1

            #MainVolumesUpdate $w
            #RenderAll

            #RenderActive
            #MainInteractorRender
            #EdUpdateAfterApplyEffect $w Active

            #        EditorResetDisplay
                    
                    # Refresh the effect, if it's an interactive one
            #        EditorUpdateEffect

            #RenderSlices


        }
#        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native

#        Ed(editor)  SetInput ""
#        Ed(editor)  UseInputOff

#        EdUpdateAfterApplyEffect $v
    }
}

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingExpand
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingExpand {} {
    global Ed EdFastMarching

    if {[ValidateFloat $EdFastMarching(nExpand)] == 0} {
        tk_messageBox -message "Expansion is not a valid number !"
        return
    } 
  
    if { $EdFastMarching(nExpand) <= 0 } {
        tk_messageBox -message "Expansion is not positive !"
        return
    }      

    set voxelnumber [ConversiontoVoxels $EdFastMarching(nExpand)] 
    EdFastMarching(FastMarching) setNPointsEvolution $voxelnumber

    EdFastMarchingSegment
    
    set f $Ed(EdFastMarching,frame).fTabbedFrame.fBasic.fUserExpand
    
    set EdFastMarching(totalExpand) [expr $EdFastMarching(nExpand) + $EdFastMarching(userExpand)]
    $f.sExpand configure -to $EdFastMarching(totalExpand)
    set EdFastMarching(userExpand) [expr $EdFastMarching(totalExpand)] 
    EdFastMarchingUserExpand 0 $EdFastMarching(userExpand)
}



#-------------------------------------------------------------------------------
# .PROC 
# Called whenever we enter the FastMarching tab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingEnter {} {
    global Ed Label Slice EdFastMarching Fiducials Gui Volumes

    if {$EdFastMarching(fastMarchingInitialized) == 0} {

        set e EdFastMarching

        set EdFastMarching(label) -1

        EdFastMarchingLabel         

        # Make sure we're colored
        LabelsColorWidgets

        set v [EditorGetInputID $Ed($e,input)]
        set depth [Volume($v,vol) GetRangeHigh]

        set dim [[Volume($v,vol) GetOutput] GetWholeExtent]
        scan [Volume($v,node) GetSpacing] "%f %f %f" dx dy dz

        # create the vtk object 
        vtkFastMarching EdFastMarching(FastMarching) 

        vtkImageCast EdFastMarching(castToShort)
        EdFastMarching(castToShort) SetOutputScalarTypeToShort
        EdFastMarching(FastMarching) SetInput [EdFastMarching(castToShort) GetOutput]

        set EdFastMarching(majorVersionCXX) [EdFastMarching(FastMarching) cxxMajorVersion]
        set EdFastMarching(versionCXX) [EdFastMarching(FastMarching) cxxVersionString]

        if $EdFastMarching(majorVersionTCL)==$EdFastMarching(majorVersionCXX) {
            set EdFastMarching(shouldDisplayWarningVersion) 0
        }

        if $EdFastMarching(shouldDisplayWarningVersion)==1 {
        tk_messageBox -message "The module binaries are outdated, you should probably recompile them.\n\n You can have a look at the 'advanced' tab for more info and at the on-line tutorial (URL given in the 'help' tab) to learn more about re-compiling the module."
        set EdFastMarching(shouldDisplayWarningVersion) 0
        }

        # initialize the object
        EdFastMarching(FastMarching) init \
            [expr [lindex $dim 1] + 1] [expr [lindex $dim 3] + 1] [expr [lindex $dim 5] + 1] $depth $dx $dy $dz

        set EdFastMarching(fastMarchingInitialized) 1

        set EdFastMarching(fidFiducialList) \
            [ FiducialsCreateFiducialsList "default" "FastMarching-seeds" 0 3 ]

        # Required
        set Ed($e,scope)  3D 
        set Ed($e,input)  Original
        set Ed($e,interact) Active

        EditorActivateUndo 0
        
#        EditorClear Working
        
        set v [EditorGetInputID $Ed($e,input)]

        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
        Ed(editor)  UseInputOn

        set Gui(progressText) "FastMarching: initializing"

        

        # insert a cast to SHORT before the editor
        # note: no effect if data already SHORT
        EdFastMarching(castToShort) SetInput [Ed(editor) GetInput]
        Ed(editor)  SetInput [EdFastMarching(castToShort) GetOutput]

        EdFastMarching(FastMarching) Modified

        #note: that would work too but would screw up the progress bar
        #Ed(editor) Apply EdFastMarching(castToShort) EdFastMarching(FastMarching)

################### try that
        set o [EditorGetOriginalID]
        set w [EditorGetWorkingID]

        set vtkImageDataOriginal [Volume($o,vol) GetOutput]
        set vtkImageDataWorking [Volume($w,vol) GetOutput]

        EdFastMarching(castToShort) SetInput $vtkImageDataOriginal

        EdFastMarching(FastMarching) SetInput [EdFastMarching(castToShort) GetOutput]
        EdFastMarching(FastMarching) SetOutput $vtkImageDataWorking

            EdFastMarching(FastMarching) AddObserver StartEvent MainStartProgress
            EdFastMarching(FastMarching) AddObserver ProgressEvent "MainShowProgress EdFastMarching(FastMarching)"
            EdFastMarching(FastMarching) AddObserver EndEvent MainEndProgress
        MainStartProgress

        EdFastMarching(FastMarching) Modified
        EdFastMarching(FastMarching) Update


#$vtkImageDataWorking Update
###################



#        Ed(editor) Apply  EdFastMarching(FastMarching) EdFastMarching(FastMarching)

        # necessary for init
        EdFastMarchingLabel 
        # Make sure we're colored
        LabelsColorWidgets

        MainEndProgress

        Ed(editor)  SetInput ""
        Ed(editor)  UseInputOff

        EdUpdateAfterApplyEffect $v
    }    
    FiducialsSetActiveList "FastMarching-seeds"
}

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingExit
# called whenever we exit the FastMarching tab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingExit {} {
    global Ed EdFastMarching

    EdFastMarching(FastMarching) unInit

    #delete the object
    EdFastMarching(FastMarching) Delete
    EdFastMarching(castToShort) Delete

    FiducialsDeleteList "FastMarching-seeds"

    set EdFastMarching(fastMarchingInitialized) 0

    Slicer BackFilterOff
    Slicer ForeFilterOff
    Slicer ReformatModified
    Slicer Update
}

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingLabel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingLabel {} {
    global Ed Label EdFastMarching

    LabelsFindLabel
    if {$Label(label) != $EdFastMarching(label)} {
        if {$EdFastMarching(fastMarchingInitialized) == 1} {

            set EdFastMarching(label) $Label(label)

            EdFastMarching(FastMarching) setActiveLabel $Label(label)
     
            FiducialsDeleteList "FastMarching-seeds"
            
            set EdFastMarching(fidFiducialList) \
                [ FiducialsCreateFiducialsList "default" "FastMarching-seeds" 0 3 ]
            
            EdFastMarching(FastMarching) initNewExpansion
            set EdFastMarching(userExpand) 0
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdFastMarchingSegment
#
# Where the job gets done
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingSegment {} {
    global Label Fiducials EdFastMarching Volume Ed Gui

    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Output label is not an integer !"
        return
    }

    if {[ValidateInt $Label(label)] <= 0} {
        tk_messageBox -message "Output label is not positive !"
        return
    }
   
    if {[ValidateFloat $EdFastMarching(nExpand)] == 0} {
        tk_messageBox -message "Expansion is not a valid number !"
        return
    } 
  
    if { $EdFastMarching(nExpand) <= 0 } {
        tk_messageBox -message "Expansion is not positive !"
        return
    }   

    set e EdFastMarching

    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active   

    set v [EditorGetInputID $Ed($e,input)]

    # note: we should probably use GetRasToIjkMatrix here but it does not
    # seem to work (?)

    scan [Volume($v,node) GetRasToVtkMatrix] \
    "%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f" \
    m11 m12 m13 m14 \
    m21 m22 m23 m24 \
    m31 m32 m33 m34 \
    m41 m42 m43 m44;

    EdFastMarching(FastMarching) setRAStoIJKmatrix $m11 $m12 $m13 $m14 $m21 $m22 $m23 $m24 $m31 $m32 $m33 $m34 $m41 $m42 $m43 $m44

    set l [FiducialsGetPointIdListFromName "FastMarching-seeds"]

    foreach s $l {

        set coord [FiducialsGetPointCoordinates $s]

        set cr [lindex $coord 0]
        set ca [lindex $coord 1]
        set cs [lindex $coord 2]

        if { [EdFastMarching(FastMarching) addSeed $cr $ca $cs]==0 } {
            FiducialsDeletePoint $EdFastMarching(fidFiducialList) $s
            tk_messageBox -message "Seed $s is outside of the volume.\nIt has therefore been removed."
        }

    }

    set l [FiducialsGetPointIdListFromName "FastMarching-seeds"]

    EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
    Ed(editor)  UseInputOn

    if { [EdFastMarching(FastMarching) nValidSeeds]<=0 } {
        tk_messageBox -message "No seeds defined !\n(see help section)"
        return
    }

    set Gui(progressText) "FastMarching"

    # insert a cast to SHORT before the editor
    # note: no effect if data already SHORT
    EdFastMarching(castToShort) SetInput [Ed(editor) GetInput]
    Ed(editor)  SetInput [EdFastMarching(castToShort) GetOutput]

    EdFastMarching(FastMarching) Modified

    #note: that would work too but would screw up the progress bar
    #Ed(editor) Apply EdFastMarching(castToShort) EdFastMarching(FastMarching)

################### try that
    set o [EditorGetOriginalID]
    set w [EditorGetWorkingID]

    set vtkImageDataOriginal [Volume($o,vol) GetOutput]
    set vtkImageDataWorking [Volume($w,vol) GetOutput]

    EdFastMarching(castToShort) SetInput $vtkImageDataOriginal

    EdFastMarching(FastMarching) SetInput [EdFastMarching(castToShort) GetOutput]
    EdFastMarching(FastMarching) SetOutput $vtkImageDataWorking

    #MainShowProgress EdFastMarching(FastMarching)
    #MainStartProgress

    EdFastMarching(FastMarching) AddObserver StartEvent MainStartProgress
    EdFastMarching(FastMarching) AddObserver ProgressEvent "MainShowProgress EdFastMarching(FastMarching)"
    EdFastMarching(FastMarching) AddObserver EndEvent MainEndProgress


    EdFastMarching(FastMarching) Modified
    EdFastMarching(FastMarching) Update

    #$vtkImageDataWorking Update
###################

#    Ed(editor) Apply  EdFastMarching(FastMarching) EdFastMarching(FastMarching)

#    MainEndProgress

    Ed(editor)  SetInput ""
    Ed(editor)  UseInputOff

#    EdUpdateAfterApplyEffect $v
}

# this is called when the user clicks on the active slice
#-------------------------------------------------------------------------------
# .PROC EdFastMarchingApply
#
#  we don't want to do anything special in this case
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdFastMarchingApply {} {}
