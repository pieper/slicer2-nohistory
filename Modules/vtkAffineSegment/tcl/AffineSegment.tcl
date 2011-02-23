#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: AffineSegment.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:13 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        AffineSegment.tcl
# PROCEDURES:  
#   EdAffineSegmentInit
#   EdAffineSegmentBuildGUI
#   ConversiontomL Voxels
#   ConversiontoVoxels mL
#   EdAffineSegmentUserExpand zero Inflation
#   EdAffineSegmentExpand
#   EdAffineSegmentInitialSize zero SphereSize
#   EdAffineSegmentContract
#   EdAffineSegmentReset
#   EdAffineSegmentEnter
#   EdAffineSegmentLabel
#   EdAffineSegmentLabel
#   EdAffineSegmentApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentInit {} {
    global Ed Gui EdAffineSegment Volume Slice Fiducials

    set e EdAffineSegment
    set Ed($e,name)      "Affine Segment"
    set Ed($e,initials)  "AS"
    set Ed($e,desc)      "Affine Segmentation: 3D segmentation"
    set Ed($e,rank)      14;
    set Ed($e,procGUI)   EdAffineSegmentBuildGUI
    set Ed($e,procEnter) EdAffineSegmentEnter
    set Ed($e,procExit)  EdAffineSegmentExit

    # Define Dependencies
    set Ed($e,depend) Fiducials 
    set EdAffineSegment(fastMarchingInitialized) 0

    # Required
    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active

    set EdAffineSegment(nExpand) 10
    set EdAffineSegment(nContract) 5
    set EdAffineSegment(Inflation) 50
    set EdAffineSegment(SphereSize) 1000
    set EdAffineSegment(totalExpand) 0

    set EdAffineSegment(majorVersionTCL) 3
    set EdAffineSegment(minorVersionTCL) 1
    set EdAffineSegment(dateVersionTCL) "2003-1-27/20:00EST"

    set EdAffineSegment(versionTCL) "$EdAffineSegment(majorVersionTCL).$EdAffineSegment(minorVersionTCL) \t($EdAffineSegment(dateVersionTCL))"

    set EdAffineSegment(shouldDisplayWarningVersion) 1

}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentBuildGUI {} {
    global Ed Gui Label Volume EdAffineSegment Fiducials Help

    set e EdAffineSegment
    #-------------------------------------------
    # AffineEvolve frame
    #-------------------------------------------

    set f $Ed(EdAffineSegment,frame)

    #copied from EdPhaseWireBuildGUI

    set label ""
    set subframes {Help Basic Advanced}
    set buttonText {"Help" "Basic" "Advanced"}
    set tooltips { "Help: We all need it sometimes." \
        "Basic: For Users" \
        "Advanced: For Developers"}
    set extraFrame 0
    set firstTab Basic

    TabbedFrame EdAffineSegment $f $label $subframes $buttonText \
        $tooltips $extraFrame $firstTab

    #-------------------------------------------
    # TabbedFrame->Help frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fHelp

    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true

    set Ed(EdAffineSegment,helpWidget) [HelpWidget $f.fWidget]

    set help "DISCLAIMER: this module is for development only!
    Yogesh Rathi <gtg136q@mail.gatech.edu>


3D segmentation using Affine Invariant Surface Flow.

To segment a volume :

- Define a label for the segmented data : by clicking on the 'Label' button. 

- Define some seed points : by creating some fiducials inside (not on the border of) the region of interest. Fiducials can be created by moving the pointer to the desired region and pressing the 'p' key.  See the Fiducial module documentation for more on using fiducials.

- Choose the value of Inflationary term. If you dont know what to choose, just leave the default value

- Choose the initial Size of the starting sphere. You might want to start with a reasonable size of the sphere so that you are not outside the
  surface to start with nor is the starting sphere very very small (this will lead to making a lot of iterations to expand to reach the boundary)
  If you are not satisfied with the region covered by the initial sphere, press 'Reset' and you can start all over again

- Start expansion of the surface : by clicking on the 'Expand' button.  The volume of the surface will be expanded by the value right of the expand button.  Increase this value to segment a bigger object.
  (Typically, 100 iterations is good number to start with, if the target region is not very big)

If the expansion did not go far enough,  press 'Expand' again. Continue untill you have all of the region covered. Dont bother about leaks.

Once you have finished with expansion, now press 'AffineContract'. This will smooth out the surface and will contract where required.

Typically, 5-10 iterations are enough for this part.

When satisfied with the segmentation use other editing modules on the labelmap (morphological operations...) and/or create a model.

Note: If the region of interest (target) is a very big region, start with many fiducials and then expand. this will slow down the algorithm
but it is a good strategy to start.

If you want to start afresh, click the 'Reset' button"

    eval $Ed(EdAffineSegment,helpWidget) tag configure normal   $Help(tagNormal)

    $Ed(EdAffineSegment,helpWidget) insert insert "$help" normal

    #-------------------------------------------
    # TabbedFrame->Basic frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic
 
    frame $f.fLogo     -bg $Gui(activeWorkspace)
    frame $f.fGrid     -bg $Gui(activeWorkspace)
    frame $f.fExpand   -bg $Gui(activeWorkspace)
    frame $f.fSphere   -bg $Gui(activeWorkspace)
    frame $f.fUserExpand   -bg $Gui(activeWorkspace)
    frame $f.fContract -bg $Gui(activeWorkspace)
    frame $f.fReset    -bg $Gui(activeWorkspace)

    pack $f.fLogo $f.fGrid $f.fSphere $f.fUserExpand $f.fExpand $f.fContract $f.fReset\
    -side top -fill x 

    #-------------------------------------------
    # AffineEvolve->Logo Frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fLogo
    if { [file exists $::env(SLICER_HOME)/Modules/vtkFastMarching/images/gatech.ppm] } {
        set im [image create photo -file $::PACKAGE_DIR_VTKFASTMARCHING/../../../images/gatech.ppm]
        pack [label $f.logo -image $im]
    } else {
        pack [label $f.logo -text "Georgia Tech"]
    }

    #-------------------------------------------
    # AffineEvolve->Grid frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fGrid

    # Output label
    eval {button $f.bOutput -text "Label:" \
          -command "ShowLabels EdAffineSegmentLabel"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdAffineSegmentLabel"
    bind $f.eOutput <FocusOut> "EdAffineSegmentLabel"
    eval {entry $f.eName -width 14 -textvariable Label(name)} $Gui(WEA) \
    {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w

    lappend Label(colorWidgetList) $f.eName

    #-------------------------------------------
    #AffineEvolve->Initial size Frame
    #------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fSphere

    eval {scale $f.sInitial -from 400.0 -to 30000.0 \
            -length 220 -variable EdAffineSegment(SphereSize) -resolution 10 -orient horizontal -label "Volume of Initial Sphere (in pixels)" \
            -command "EdAffineSegmentInitialSize $EdAffineSegment(SphereSize)"} \
            $Gui(WSA) -showvalue true -digits 5 -resolution 40 {-sliderlength 22}

    grid $f.sInitial -sticky w

    #-------------------------------------------
    # AffineEvolve->Expand frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fExpand

    # Output label
    eval {button $f.bExpand -text "EXPAND" \
          -command "EdAffineSegmentExpand"} $Gui(WBA)
   

    eval {entry $f.eExpand -width 6 -textvariable EdAffineSegment(nExpand)} $Gui(WEA)

    eval {label $f.lTextUnit -text "# of Iterations"} $Gui(WLA)

    grid $f.bExpand $f.eExpand $f.lTextUnit -padx 4 -pady $Gui(pad)

    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fUserExpand

    eval {scale $f.sExpand -from 10.0 -to 30000.0 \
            -length 220 -variable EdAffineSegment(Inflation) -resolution 10 -orient horizontal -label "Inflationary Term is" \
            -command "EdAffineSegmentUserExpand $EdAffineSegment(Inflation)"} \
            $Gui(WSA) -showvalue true -digits 5 -resolution 20 {-sliderlength 22}
    
    grid $f.sExpand -sticky w
    
    
    #-------------------------------------------
    # AffineEvolve->Contract frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fContract

    eval {button $f.bContract -text "AffineContract" \
          -command "EdAffineSegmentContract"} $Gui(WBA)
    eval {entry $f.eContract -width 6 -textvariable EdAffineSegment(nContract)} $Gui(WEA)

    eval {label $f.lText -text "# of Iterations"} $Gui(WLA)

    grid $f.bContract $f.eContract $f.lText -padx 4 -pady $Gui(pad)


    #-------------------------------------------
    # AffineEvolve->Reset frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fReset

    eval {button $f.bReset -text "RESET" \
          -command "EdAffineSegmentReset"} $Gui(WBA)
    grid $f.bReset -padx 6 -pady $Gui(pad)

    #-------------------------------------------
    # TabbedFrame->Advanced frame
    #-------------------------------------------
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fAdvanced

    frame $f.fVersion     -bg $Gui(activeWorkspace)

    pack $f.fVersion -side top -fill x 

    #-------------------------------------------
    # TabbedFrame->Advanced->version frame
    #-------------------------------------------

    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fAdvanced.fVersion

    eval {label $f.lTextCXX -text "CXX version: "} $Gui(WLA)
    eval {label $f.lCXX -textvariable EdAffineSegment(versionCXX) } $Gui(WLA)
    grid $f.lTextCXX $f.lCXX -padx 2
 
    eval {label $f.lTextTCL -text "TCL version: " } $Gui(WLA)
    eval {label $f.lTCL -textvariable EdAffineSegment(versionTCL) } $Gui(WLA)
    grid $f.lTextTCL $f.lTCL -padx 2 -pady $Gui(pad)
}

#-------------------------------------------------------------------------------
# .PROC ConversiontomL
# 
# .ARGS
# int Voxels number of voxels
# .END
#-------------------------------------------------------------------------------
proc ConversiontomL {Voxels} {
    global EdAffineSegment Ed

    set e EdAffineSegment
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
# int mL millilitres
# .END
#-------------------------------------------------------------------------------
proc ConversiontoVoxels {mL} {
    global EdAffineSegment Ed

    set e EdAffineSegment
    set v [EditorGetInputID $Ed($e,input)]
     
    scan [Volume($v,node) GetSpacing] "%f %f %f" dx dy dz
    set voxelvolume [expr $dx * $dy * $dz]
    set conversion 1000
      
    set voxelamount [expr $mL / $voxelvolume]
    set Voxels [expr round($voxelamount) * $conversion]

    return $Voxels
}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentUserExpand
# 
# .ARGS
# int zero not used
# int Inflation not used
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentUserExpand {zero Inflation} {
    global EdAffineSegment

    if {$EdAffineSegment(fastMarchingInitialized) != 0} {
        set e EdAffineSegment

        set Ed($e,scope)  3D 
        set Ed($e,input)  Original
        set Ed($e,interact) Active   

        set v [EditorGetInputID $Ed($e,input)]

        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
        Ed(editor)  UseInputOn
        
        EdAffineSegment(AffineEvolve) show

        EdAffineSegment(AffineEvolve) Modified
        EdAffineSegment(AffineEvolve) Update

        set w [EditorGetWorkingID]

        MainVolumesUpdate $w
    }
}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentExpand
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentExpand {} {
    global Ed EdAffineSegment

    if {[ValidateFloat $EdAffineSegment(nExpand)] == 0} {
        tk_messageBox -message "Expansion is not a valid number !"
        return
    } 
  
    if { $EdAffineSegment(nExpand) <= 0 } {
        tk_messageBox -message "Expansion is not positive !"
        return
    }      

    EdAffineSegmentSegment
    
    set f $Ed(EdAffineSegment,frame).fTabbedFrame.fBasic.fUserExpand
    
    EdAffineSegmentUserExpand 0 $EdAffineSegment(Inflation)
}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentInitialSize
# Does nothing
# .ARGS
# int zero
# int SphereSize
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentInitialSize {zero SphereSize} {
     global EdAffineSegment
}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentContract
# We need to do the Affine flow now
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentContract {} {
  global EdAffineSegment
  
  EdAffineSegment(AffineEvolve) OutputReset
  EdAffineSegment(AffineEvolve) AffineContract
  EdAffineSegment(AffineEvolve) SetNumberOfContractions $EdAffineSegment(nContract)
  EdAffineSegmentSegment
  EdAffineSegmentUserExpand 0 $EdAffineSegment(nContract)

 
}


#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentReset
# Reset the output 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentReset {} {
  global EdAffineSegment Ed

  EdAffineSegment(AffineEvolve) Reset
  EdAffineSegment(AffineEvolve) Modified
  
  set l [FiducialsGetPointIdListFromName "FastMarching-seeds"]

    foreach s $l {
        FiducialsDeletePoint $EdAffineSegment(fidFiducialList) $s
    }


   RenderAll
}


#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentEnter
# Called whenever we enter the AffineEvolve tab
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentEnter {} {
    global Ed Label Slice EdAffineSegment Fiducials Gui Volumes

    if {$EdAffineSegment(fastMarchingInitialized) == 0} {

        set e EdAffineSegment

        set EdAffineSegment(label) -1

        EdAffineSegmentLabel         

        # Make sure we're colored
        LabelsColorWidgets

        set v [EditorGetInputID $Ed($e,input)]
        set depth [Volume($v,vol) GetRangeHigh]

        set dim [[Volume($v,vol) GetOutput] GetWholeExtent]
        scan [Volume($v,node) GetSpacing] "%f %f %f" dx dy dz

        # create the vtk object 
        vtkAffineSegment EdAffineSegment(AffineEvolve) 

        vtkImageCast EdAffineSegment(castToShort)
        EdAffineSegment(castToShort) SetOutputScalarTypeToShort
        EdAffineSegment(AffineEvolve) SetInput [EdAffineSegment(castToShort) GetOutput] 

        set EdAffineSegment(majorVersionCXX) [EdAffineSegment(AffineEvolve) cxxMajorVersion]
        set EdAffineSegment(versionCXX) [EdAffineSegment(AffineEvolve) cxxVersionString]

        if $EdAffineSegment(majorVersionTCL)==$EdAffineSegment(majorVersionCXX) {
            set EdAffineSegment(shouldDisplayWarningVersion) 0
        }

        if $EdAffineSegment(shouldDisplayWarningVersion)==1 {
        tk_messageBox -message "The module binaries are outdated, you should probably recompile them.\n\n You can have a look at the 'advanced' tab for more info and at the on-line tutorial (URL given in the 'help' tab) to learn more about re-compiling the module."
        set EdAffineSegment(shouldDisplayWarningVersion) 0
        }

        # initialize the object
        EdAffineSegment(AffineEvolve) init \
            [expr [lindex $dim 1] + 1] [expr [lindex $dim 3] + 1] [expr [lindex $dim 5] + 1] $depth $dx $dy $dz

        EdAffineSegment(AffineEvolve) SetEvolve 0

        set EdAffineSegment(fastMarchingInitialized) 1

        set EdAffineSegment(fidFiducialList) \
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

        set Gui(progressText) "AffineEvolve: initializing"

        

        # insert a cast to SHORT before the editor
        # note: no effect if data already SHORT
        EdAffineSegment(castToShort) SetInput [Ed(editor) GetInput]
        Ed(editor)  SetInput [EdAffineSegment(castToShort) GetOutput]

        EdAffineSegment(AffineEvolve) Modified

    #note: that would work too but would screw up the progress bar
    #Ed(editor) Apply EdAffineSegment(castToShort) EdAffineSegment(AffineEvolve)

################### try that
set o [EditorGetOriginalID]
set w [EditorGetWorkingID]

set vtkImageDataOriginal [Volume($o,vol) GetOutput]
set vtkImageDataWorking [Volume($w,vol) GetOutput]

EdAffineSegment(castToShort) SetInput $vtkImageDataOriginal

EdAffineSegment(AffineEvolve) SetInput [EdAffineSegment(castToShort) GetOutput]
EdAffineSegment(AffineEvolve) SetOutput $vtkImageDataWorking

     EdAffineSegment(AffineEvolve) AddObserver StartEvent     MainStartProgress
     EdAffineSegment(AffineEvolve) AddObserver ProgressEvent  "MainShowProgress EdAffineSegment(AffineEvolve)"
     EdAffineSegment(AffineEvolve) AddObserver EndEvent       MainEndProgress
#MainShowProgress EdAffineSegment(AffineEvolve)
MainStartProgress

EdAffineSegment(AffineEvolve) Modified
EdAffineSegment(AffineEvolve) Update


#$vtkImageDataWorking Update
###################



        Ed(editor) Apply  EdAffineSegment(AffineEvolve) EdAffineSegment(AffineEvolve)

        # necessary for init
        EdAffineSegmentLabel 
        # Make sure we're colored
        LabelsColorWidgets

        MainEndProgress

        Ed(editor)  SetInput ""
        Ed(editor)  UseInputOff

        EdUpdateAfterApplyEffect $v
    }    
    FiducialsSetActiveList "FastMarching-seeds"

    
}


#called whenever we exit the AffineEvolve tab
proc EdAffineSegmentExit {} {
    global Ed EdAffineSegment

    EdAffineSegment(AffineEvolve) unInit

    #delete the object
    EdAffineSegment(AffineEvolve) Delete
    EdAffineSegment(castToShort) Delete

    FiducialsDeleteList "FastMarching-seeds"

    set EdAffineSegment(fastMarchingInitialized) 0

    Slicer BackFilterOff
    Slicer ForeFilterOff
    Slicer ReformatModified
    Slicer Update
}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentLabel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentLabel {} {
    global Ed Label EdAffineSegment

    LabelsFindLabel
    if $Label(label)!=$EdAffineSegment(label) {
    if {$EdAffineSegment(fastMarchingInitialized) == 1} {

        set EdAffineSegment(label) $Label(label)

        EdAffineSegment(AffineEvolve) setActiveLabel $Label(label)
 
        FiducialsDeleteList "FastMarching-seeds"
        
        set EdAffineSegment(fidFiducialList) \
        [ FiducialsCreateFiducialsList "default" "FastMarching-seeds" 0 3 ]
        
        #EdAffineSegment(AffineEvolve) initNewExpansion
        #set EdAffineSegment(Inflation) 0
    }
    }

}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentLabel
# Where the job gets done
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentSegment {} {
    global Label Fiducials EdAffineSegment Volume Ed Gui

    if {[ValidateInt $Label(label)] == 0} {
        tk_messageBox -message "Output label is not an integer !"
        return
    }

    if {[ValidateInt $Label(label)] <= 0} {
        tk_messageBox -message "Output label is not positive !"
        return
    }
    
    if {[ValidateFloat $EdAffineSegment(nExpand)] == 0} {
        tk_messageBox -message "Expansion is not a valid number !"
        return
    } 
    
    if { $EdAffineSegment(nExpand) <= 0 } {
        tk_messageBox -message "Expansion is not positive !"
        return
    }   
    
    
    # note: we should probably use GetRasToIjkMatrix here but it does not
    # seem to work (?)
    set e EdAffineSegment
    set Ed($e,scope)  3D 
    set Ed($e,input)  Original
    set Ed($e,interact) Active   
    
    set v [EditorGetInputID $Ed($e,input)]
    
    scan [Volume($v,node) GetRasToVtkMatrix] \
        "%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f" \
        m11 m12 m13 m14 \
        m21 m22 m23 m24 \
        m31 m32 m33 m34 \
        m41 m42 m43 m44;
    
    EdAffineSegment(AffineEvolve) setRAStoIJKmatrix $m11 $m12 $m13 $m14 $m21 $m22 $m23 $m24 $m31 $m32 $m33 $m34 $m41 $m42 $m43 $m44
    
    if { [EdAffineSegment(AffineEvolve) nValidSeeds]<=0 } {
        
        set l [FiducialsGetPointIdListFromName "FastMarching-seeds"]
        
        foreach s $l {
            
            set coord [FiducialsGetPointCoordinates $s]
            
            set cr [lindex $coord 0]
            set ca [lindex $coord 1]
            set cs [lindex $coord 2]
            
            if { [EdAffineSegment(AffineEvolve) addSeed $cr $ca $cs]==0 } {
                FiducialsDeletePoint $EdAffineSegment(fidFiducialList) $s
                tk_messageBox -message "Seed $s is outside of the volume.\nIt has therefore been removed."
            }
            
        }
        
        
        set l [FiducialsGetPointIdListFromName "FastMarching-seeds"]
        
        EdSetupBeforeApplyEffect $v $Ed($e,scope) Native
        Ed(editor)  UseInputOn
        
        if { [EdAffineSegment(AffineEvolve) nValidSeeds]<=0 } {
            tk_messageBox -message "No seeds defined !\n(see help section)"
            return
        }
        
    }
    if { [EdAffineSegment(AffineEvolve) nValidSeeds]>0 } {
        EdAffineSegment(AffineEvolve) OutputReset
    }
    set Gui(progressText) "AffineSegmentation"
    
    # insert a cast to SHORT before the editor
    # note: no effect if data already SHORT
    EdAffineSegment(castToShort) SetInput [Ed(editor) GetInput]
    Ed(editor)  SetInput [EdAffineSegment(castToShort) GetOutput]
    
    EdAffineSegment(AffineEvolve) Modified
    
    
    EdAffineSegment(AffineEvolve) SetNumberOfIterations $EdAffineSegment(nExpand)
    EdAffineSegment(AffineEvolve) SetInflation $EdAffineSegment(Inflation)
    EdAffineSegment(AffineEvolve) SetInitialSize $EdAffineSegment(SphereSize)
    
    #EdAffineSegment(castToShort) SetInput $vtkImageDataOriginal
    
    
    EdAffineSegment(AffineEvolve) SetInput [EdAffineSegment(castToShort) GetOutput]
    
    
    EdAffineSegment(AffineEvolve) AddObserver StartEvent     MainStartProgress
    EdAffineSegment(AffineEvolve) AddObserver ProgressEvent  "MainShowProgress EdAffineSegment(AffineEvolve)"
    EdAffineSegment(AffineEvolve) AddObserver EndEvent       MainEndProgress
    
    
#set outdat [EdAffineSegment(AffineEvolve) GetOutput]
    
    #RenderAll
    
    EdAffineSegment(AffineEvolve) Modified
    EdAffineSegment(AffineEvolve) Update
    ################### try that
    set o [EditorGetOriginalID]
    set w [EditorGetWorkingID]

    set vtkImageDataOriginal [Volume($o,vol) GetOutput]
    set vtkImageDataWorking [Volume($w,vol) GetOutput]
    EdAffineSegment(AffineEvolve) SetOutput $vtkImageDataWorking
    
    
    Ed(editor)  SetInput ""
    Ed(editor)  UseInputOff
    
    EdAffineSegment(AffineEvolve) SetEvolve 0
    RenderAll
    
}

#-------------------------------------------------------------------------------
# .PROC EdAffineSegmentApply
# this is called when the user clicks on the active slice
# we don't want to do anything special in this case
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdAffineSegmentApply {} {}
