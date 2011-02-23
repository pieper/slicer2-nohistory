#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: EdPhaseWire.tcl,v $
#   Date:      $Date: 2006/04/11 21:32:03 $
#   Version:   $Revision: 1.33 $
# 
#===============================================================================
# FILE:        EdPhaseWire.tcl
# PROCEDURES:  
#   EdPhaseWireInit
#   EdPhaseWireSetOmega
#   EdPhaseWireBuildVTK
#   EdPhaseWireBuildGUI
#   EdPhaseUseWindowLevel
#   EdPhaseConvertToRadians
#   EdPhaseConvertToDegrees
#   EdPhaseWirePrettyPicture
#   EdPhaseWireRaiseEdgeImageWin
#   EdPhaseWireUpdateEdgeImageWin viewerWidget edgeNum
#   EdPhaseWireWriteEdgeImage
#   EdPhaseWireStartPipeline
#   EdPhaseWireStopPipeline
#   EdPhaseWireEnter
#   EdPhaseWireExit
#   EdPhaseWireUpdate
#   EdPhaseWireB1
#   EdPhaseWireMotion
#   EdPhaseWireRenderInteractive
#   EdPhaseWireClickLabel
#   EdPhaseWireLabel
#   EdPhaseWireClearCurrentSlice
#   EdLiveWireResetPhaseDefaults
#   EdPhaseWireClearLastSegment
#   EdPhaseWireResetSlice s
#   EdPhaseWireApply
#   EdPhaseWireStartProgress
#   EdPhaseWireShowProgress
#   EdPhaseWireEndProgress
#   EdPhaseWireUseDistanceFromPreviousContour
#   EdPhaseWireFindInputPhaseVolumes
#   EdPhaseWireUsePhasePipeline
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireInit
# Automatically called init procedure
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireInit {} {
    global Ed Gui Volume
    
    set e EdPhaseWire
    set Ed($e,name)      "PhaseWire"
    set Ed($e,initials)  "Pw"
    set Ed($e,desc)      "PhaseWire: quick 2D segmentation."
    # order this editor module will appear in the list
    set Ed($e,rank)      9
    set Ed($e,procGUI)   EdPhaseWireBuildGUI
    set Ed($e,procVTK)   EdPhaseWireBuildVTK
    set Ed($e,procEnter) EdPhaseWireEnter
    set Ed($e,procExit)  EdPhaseWireExit

    # Required
    set Ed($e,scope)  Single
    # Original volume is input to our filters.
    set Ed($e,input)  Original
    
    # drawing vars
    set Ed($e,radius) 0;        # thickness of lines
    set Ed($e,shape)  Polygon;  # shape to draw when apply
    set Ed($e,render) Active;   # render all 3 or just 1 slice when apply
    
    # settings for combining phase and cert info
    set Ed(EdPhaseWire,phaseWeight) 1
    set Ed(EdPhaseWire,certWeight) 1
    set Ed(EdPhaseWire,gradWeight) 0
    set Ed(EdPhaseWire,certLowerCutoff) 0
    set Ed(EdPhaseWire,certUpperCutoff) 150

    # phase offset slider
    set Ed($e,phaseOffsetLow) 0
    set Ed($e,phaseOffsetHigh) 180

    # default offset is 90 degrees == perfect edge in phase image
    set Ed(EdPhaseWire,defaultPhaseOffset) 90
    set Ed(EdPhaseWire,phaseOffset) $Ed(EdPhaseWire,defaultPhaseOffset)

    # phase and certainty volumes we are using
    set Ed(EdPhaseWire,phaseVol) $Volume(idNone)
    set Ed(EdPhaseWire,certVol) $Volume(idNone)

    # whether the user's click defines the value 
    # of the phase contour we follow
    set Ed(EdPhaseWire,clickSetsPhase) 0

    # ignore mouse movement until we have a start point
    set Ed(EdPhaseWire,pipelineActiveAndContourStarted) 0

    # center frequency controls sensitivity to different size image features
    # choices for omega (these should be chosen more carefully)
    # note that the mult by cos^2 kills high freq parts of filter and 
    # means we need higher freqs. here than we were using before, 
    # in order to get good results w/ small structures
    # (unless this is caused by something else -- like larger 
    # kernel size?)
    set Ed(EdPhaseWire,omega,idList) {Pi PiOverSqrtTwo PiOverTwo }
    set Ed(EdPhaseWire,omega,nameList) {"small" "medium" "large"}
    # current omega
    set Ed(EdPhaseWire,omega,id) PiOverSqrtTwo
    set Ed(EdPhaseWire,omega,name) "medium"

    # whether to w/l before computing phase
    set Ed($e,useWindowLevel) 1

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireSetOmega
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireSetOmega {omega} {
    global Ed Volume Path

    set e EdPhaseWire

    # decide what size (256 or 512 now) kernel to use
    # all reformatting is done at 256 resolution currently,
    # unless we use attila's cool feature.  so for now,
    # ignore the following checks
    #-------------------------------------------
    #set extent [[Volume([EditorGetWorkingID],vol) GetOutput] GetExtent]
    #set width [lindex $extent 1]
    #set height [lindex $extent 3]

    #puts "$width $height"
    
    #if {$width != $height} {
    #puts "Can't work on non-square images now!"
    #return 1
    #}

    #if {$width != "255"} {
    #puts "Only 256x256 images supported!"
    #return 1
    #}
    
    #set width1 [expr $width + 1]

    set width 255
    set width1 256

    # file name: look locally and then centrally
    #-------------------------------------------
    set local [file join tcl-modules Editor EdPhaseWire]
    set central  [file join $Path(program) $local]

    # read in kernel 
    #-------------------------------------------
    # Lauren should be created in slicer soon
    foreach o $Ed($e,phaseOrientions,idList) {

        set prefix [file join kernel$width1 omega$omega kernel]
        # try local
        set fullpath [file join $local $prefix]
        if {[file exists $fullpath.001] != "1"} {
            # go central
            set fullpath [file join $central $prefix]
        }

        Ed($e,phase,reader$o) SetFilePattern "%s.%03d"
        Ed($e,phase,reader$o) SetDataByteOrderToBigEndian
        Ed($e,phase,reader$o) SetDataExtent 0 $width 0 $width $o $o
        Ed($e,phase,reader$o) SetFilePrefix $fullpath
        #reader SetDataScalarTypeToFloat
        
        # cast to double to match output of fft of image
        #Ed($e,phase,cast$o) SetOutputScalarTypeToFloat
        Ed($e,phase,cast$o) SetOutputScalarTypeToDouble
        Ed($e,phase,cast$o) SetInput [Ed($e,phase,reader$o) GetOutput]
        
        # since we are using regular multiply
        # make both components the same (so real part
        # will multiply both real and imag parts
        # of the fft of the image this way)
        #-------------------------------------------
            
        foreach input {0 1} {
            if {[VTK_AT_LEAST 5] == 0} {
                Ed($e,phase,kernel$o) SetInput $input [ Ed($e,phase,cast$o) GetOutput]
            } else {
                Ed($e,phase,kernel$o) AddInputConnection 0 [ Ed($e,phase,cast$o) GetOutputPort]
            }
        }
        
    }

    set Ed($e,omega,id) $omega
    set idx [lsearch $Ed($e,omega,idList) $omega]
    set Ed($e,omega,name) [lindex $Ed($e,omega,nameList) $idx]

    # config menu on GUI
    $Ed(EdPhaseWire,omega,menubutton) config -text $Ed($e,omega,name)

    return 0

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireBuildVTK
# build vtk objects used in this module
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireBuildVTK {} {
    global Ed Volume Slice

    # removed threading change here - now can be set by
    # passing --no-threads to the Go.tcl script - sp 2002-11-26
    if {0} {
        ### This is a fix so that reformatting the extra volumes will work
        vtkMultiThreader temp
        #set normalthreads [temp GetGlobalDefaultNumberOfThreads]
        temp SetGlobalDefaultNumberOfThreads 1
        temp Delete
        # now only one thread will be used for our reformatting
        # when the reformatter objects are created by slicer object below
        # NOTE this affects all objects created from now on - should reset
        ### end fix
    }
    
    set e EdPhaseWire

    #-------------------------------------------
    # Lauren the phase computation should be a vtk class
    #-------------------------------------------

    
    # ids for directions we are computing phase in
    #-------------------------------------------
    set Ed($e,phaseOrientions,idList) {1 2 3 4}


    # objects for reading in filter kernels
    # these will go away when kernels are computed
    # in a vtk class
    #-------------------------------------------
    foreach o $Ed($e,phaseOrientions,idList) {
        vtkImageReader Ed($e,phase,reader$o)
        vtkImageCast  Ed($e,phase,cast$o)
        vtkImageAppendComponents Ed($e,phase,kernel$o)
    }

    #-------------------------------------------
    # Create objects for computing phase.
    #-------------------------------------------

    # We don't need to duplicate these objects for all 
    # 3 slices: just use the same ones.

    # if we are applying current window/level
    # before phase computation
    #
    # this filter is the beginning of the pipeline
    # and its input is current (active) slice from 
    # Slicer object (vtkMrmlSlicer)
    #-------------------------------------------
    # Lauren this is in vtk3.2 only!
    vtkImageMapToWindowLevelColors Ed($e,phase,windowLevel)
    Ed($e,phase,windowLevel) SetOutputFormatToRGB 

    # get only the first component 
    # (r=g=b == grayscale window/leveled value we want)
    # Lauren: note that this copies data and for 
    # speed one simple window level filter would be better
    #-------------------------------------------
    vtkImageExtractComponents Ed($e,phase,wlComp)
    Ed($e,phase,wlComp) SetComponents 1
    Ed($e,phase,wlComp) SetInput [Ed($e,phase,windowLevel) GetOutput]

    # fft of original image.
    #-------------------------------------------
    vtkImageFFT Ed($e,phase,fftSlice)
    # input is either from window/level pipeline above or directly
    # from reformatted slice from slicer object
    #Ed($e,phase,fftSlice) SetInput [Ed($e,phase,wlComp)  GetOutput]
    vtkImageData Ed($e,phase,dummyinput)
    Ed($e,phase,fftSlice) SetInput Ed($e,phase,dummyinput)


    
    # objects we need for each of 4 filter pairs
    #-------------------------------------------
    foreach o $Ed($e,phaseOrientions,idList) {
        
        # for filtering in fourier domain 
        #-------------------------------------------
        vtkImageMathematics Ed($e,phase,mult$o)
        Ed($e,phase,mult$o) SetOperationToMultiply
        Ed($e,phase,mult$o) SetInput 0 [Ed($e,phase,fftSlice) GetOutput]
        Ed($e,phase,mult$o) SetInput 1 [Ed($e,phase,kernel$o) GetOutput]

        # reverse fft: back to spatial domain
        #-------------------------------------------
        vtkImageRFFT Ed($e,phase,rfft$o)
        Ed($e,phase,rfft$o) SetDimensionality 2
        Ed($e,phase,rfft$o) SetInput [Ed($e,phase,mult$o) GetOutput]
        
        # separate odd, even filter responses in spatial domain
        #-------------------------------------------
        vtkImageExtractComponents Ed($e,phase,even$o)
        Ed($e,phase,even$o) SetComponents 0
        Ed($e,phase,even$o) SetInput [Ed($e,phase,rfft$o) GetOutput]
        
        vtkImageExtractComponents Ed($e,phase,odd$o)
        Ed($e,phase,odd$o) SetComponents 1
        Ed($e,phase,odd$o) SetInput [Ed($e,phase,rfft$o) GetOutput]
    }
    
    # Now combine the quadrature filter outputs to create 
    # 'phase' and 'cert' images
    
    # add the real (even) responses
    #------------------------------------------------------
    vtkImageMathematics Ed($e,phase,rsum1)
    Ed($e,phase,rsum1) SetOperationToAdd
    Ed($e,phase,rsum1) SetInput 0 [Ed($e,phase,even1) GetOutput]
    Ed($e,phase,rsum1) SetInput 1 [Ed($e,phase,even2) GetOutput]
    vtkImageMathematics Ed($e,phase,rsum2)
    Ed($e,phase,rsum2) SetOperationToAdd
    Ed($e,phase,rsum2) SetInput 0 [Ed($e,phase,even3) GetOutput]
    Ed($e,phase,rsum2) SetInput 1 [Ed($e,phase,even4) GetOutput]
    vtkImageMathematics Ed($e,phase,realSum)
    Ed($e,phase,realSum) SetInput 0 [Ed($e,phase,rsum1) GetOutput]
    Ed($e,phase,realSum) SetInput 1 [Ed($e,phase,rsum2) GetOutput]
    
    
    # get the abs value of all imaginary (odd) responses
    #------------------------------------------------------
    foreach o $Ed($e,phaseOrientions,idList) {
        vtkImageMathematics Ed($e,phase,iabs$o)
        Ed($e,phase,iabs$o) SetOperationToAbsoluteValue
        Ed($e,phase,iabs$o) SetInput 0 [Ed($e,phase,odd$o) GetOutput]
    }
    
    # add the abs imaginary responses
    #------------------------------------------------------
    vtkImageMathematics Ed($e,phase,isum1)
    Ed($e,phase,isum1) SetOperationToAdd
    Ed($e,phase,isum1) SetInput 0 [Ed($e,phase,iabs1) GetOutput]
    Ed($e,phase,isum1) SetInput 1 [Ed($e,phase,iabs2) GetOutput]
    vtkImageMathematics Ed($e,phase,isum2)
    Ed($e,phase,isum2) SetOperationToAdd
    Ed($e,phase,isum2) SetInput 0 [Ed($e,phase,iabs3) GetOutput]
    Ed($e,phase,isum2) SetInput 1 [Ed($e,phase,iabs4) GetOutput]
    vtkImageMathematics Ed($e,phase,imagSum)
    Ed($e,phase,imagSum) SetInput 0 [Ed($e,phase,isum1) GetOutput]
    Ed($e,phase,imagSum) SetInput 1 [Ed($e,phase,isum2) GetOutput]
    
    #------------------------------------------------------
    # PHASE:
    # res.edgephase = angle(res.phase);
    #
    # so we use the angle as the phase, 
    # double atan2( double y, double x );
    #------------------------------------------------------
    vtkImageMathematics Ed($e,phase,phaseAngle)
    Ed($e,phase,phaseAngle) SetOperationToATAN2 
    Ed($e,phase,phaseAngle) SetInput 0 [Ed($e,phase,imagSum) GetOutput]
    Ed($e,phase,phaseAngle) SetInput 1 [Ed($e,phase,realSum) GetOutput]
    
    # Lauren all this scaling (phase and cert) may be unnecessary...
    # just here now for consistency with before

    # shift and scale outputs  DON'T DO THE SHIFT HERE NOW
    vtkImageShiftScale Ed($e,phase,phase)
    #Ed($e,phase,phaseScale) SetShift -1.5707963 ; # -pi/2
    Ed($e,phase,phase) SetScale 1000
    Ed($e,phase,phase) SetInput [Ed($e,phase,phaseAngle) GetOutput]    
    
    # abs value of phase
    #vtkImageMathematics Ed($e,phase,phaseAbs)
    #Ed($e,phase,phaseAbs) SetOperationToAbsoluteValue
    #Ed($e,phase,phaseAbs) SetInput 0 [phase GetOutput]    
      
    #------------------------------------------------------
    # CERT:
    # res.edgecert = abs(imag(res.q{1}))  + abs(imag(res.q{2}))  
    # +  abs(imag(res.q{3}))  + abs(imag(res.q{4}));
    # 
    # this is the same as the imaginary part used to get phase, above:
    #  =>   sum of absolute value of all imaginary parts
    #
    #------------------------------------------------------
    
    vtkImageShiftScale Ed($e,phase,cert)
    # factor of 1000 is in kernel!!!!!
    # want factor of 10 => 10/1000 = .01
    #cert SetScale 10
    # Lauren this scaling should go away when kernels computed in vtk
    Ed($e,phase,cert) SetScale .01
    Ed($e,phase,cert) SetInput [Ed($e,phase,imagSum) GetOutput]
    
    

    foreach s $Slice(idList) {
        #-------------------------------------------
        # Create objects for computing shortest paths.
        #-------------------------------------------

        # maybe not used: for training, though
        # currently this is the filter that the slicer
        # gets to start off our pipeline
        #vtkImageGradientMagnitude Ed($e,gradMag$s)
        
        # for combining phase, cert, and any other inputs
        vtkImageWeightedSum Ed($e,imageSumFilter$s)
        
        # for normalization of the phase and cert inputs
        vtkImageLiveWireScale Ed($e,phaseNorm$s)
        vtkImageLiveWireScale Ed($e,certNorm$s)
        #vtkImageLiveWireScale Ed($e,gradNorm$s)

        # for shifting the phase image to find edges at different grayscales
        vtkImageShiftScale Ed($e,phaseScale$s)
        Ed($e,phaseScale$s) SetShift [EdPhaseConvertToRadians $Ed($e,phaseOffset)]
        Ed($e,phaseScale$s) SetScale 1

        # for abs value of phase image
        vtkImageMathematics Ed($e,phaseAbs$s)
        Ed($e,phaseAbs$s) SetOperationToAbsoluteValue
        Ed($e,phaseAbs$s) SetInput 0 [Ed($e,phaseScale$s) GetOutput]

        Ed($e,phaseNorm$s) SetInput [Ed($e,phaseAbs$s) GetOutput]

        # pipeline (rest done in EdPhaseWireEnter)
        #Ed($e,gradNorm$s)  SetInput [Ed($e,gradMag$s) GetOutput]
        
        # transformation functions to emphasize desired features of the
        # phase and cert inputs
        #certNorm SetTransformationFunctionToOneOverX
        Ed($e,certNorm$s) SetTransformationFunctionToInverseLinearRamp
        #Ed($e,gradNorm$s) SetTransformationFunctionToOneOverX
        
        # weighted sum of all inputs
        set sum Ed(EdPhaseWire,imageSumFilter$s)
        # pipeline
        $sum SetInput 0 [Ed($e,phaseNorm$s) GetOutput]
        $sum SetInput 1 [Ed($e,certNorm$s) GetOutput]
        #$sum SetInput 2 [Ed($e,gradNorm$s) GetOutput]
        
        # this filter finds short paths in the image and draws the wire
        vtkImageLiveWire Ed(EdPhaseWire,lwPath$s)
        # we want our path to be able to go to diagonal pixel neighbors
        Ed(EdPhaseWire,lwPath$s) SetNumberOfNeighbors 8
        # debug
        Ed(EdPhaseWire,lwPath$s) SetVerbose 0

        # for looking at the input to the livewire filter
        vtkImageViewer Ed(EdPhaseWire,viewer$s)
        Ed(EdPhaseWire,viewer$s) SetInput \
            [Ed(EdPhaseWire,lwPath$s) GetInput 0]
        Ed(EdPhaseWire,viewer$s) SetColorWindow 256
        Ed(EdPhaseWire,viewer$s) SetColorLevel 127.5
        [Ed(EdPhaseWire,viewer$s) GetRenderWindow] DoubleBufferOn
        
        # pipeline
        set totalInputs 9
        for {set i 0} {$i < $totalInputs} {incr i} {   
            
            # set all lw inputs (for all 8 directions) 
            # to be from phase info
            Ed(EdPhaseWire,lwPath$s) SetInput $i [$sum GetOutput]
        }
        
        # figure out what the max value is that the filters can output
        # this is needed for shortest path computation
        set scale [Ed(EdPhaseWire,lwPath$s) GetMaxEdgeCost]
        # make sure this is max val output by these filters:
        Ed($e,phaseNorm$s) SetScaleFactor $scale
        Ed($e,certNorm$s) SetScaleFactor  $scale
        #Ed($e,gradNorm$s) SetScaleFactor  $scale
    
    }

    #-------------------------------------------
    # hook up phase computation to path computation
    #-------------------------------------------
    foreach s $Slice(idList) {
        Ed($e,phaseScale$s)  SetInput [Ed($e,phase,phase) GetOutput]
        Ed($e,certNorm$s)  SetInput [Ed($e,phase,cert) GetOutput]
    }

}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireBuildGUI
# build GUI of module
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireBuildGUI {} {
    global Ed Gui Label Volume Help

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # TabbedFrame
    #   Basic
    #     Grid
    #     Render
    #     Contour
    #     Reset
    #     PhaseMenu
    #     Apply
    #   Advanced
    #     Settings
    #       InputImages
    #       Phase
    #-------------------------------------------

    set f $Ed(EdPhaseWire,frame)

    # this makes the navigation menu (buttons) and the tabs (frames).
    set label ""
    set subframes {Help Basic Advanced}
    set buttonText {"Help" "Basic" "Advanced"}
    set tooltips { "Help: We all need it sometimes." \
        "Basic: For Users" \
        "Advanced: Current PhaseWire Settings and Stuff for Developers"}
    set extraFrame 0
    set firstTab Basic

    TabbedFrame EdPhaseWire $f $label $subframes $buttonText \
        $tooltips $extraFrame $firstTab

    #-------------------------------------------
    # TabbedFrame->Help frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fHelp

    frame $f.fWidget -bg $Gui(activeWorkspace)
    pack $f.fWidget -side top -padx 2 -fill both -expand true
    
    set Ed(EdPhaseWire,helpWidget) [HelpWidget $f.fWidget]

    set help "For interactive image segmentation, just click on the desired border and as you move the mouse, the program will draw a contour for you.\n\nTo freeze the contour segment, click again.\n\n  More clicks are useful in difficult regions, fewer clicks should be needed where the boundary is clear.\n\nHit the Apply button when you are satisfied with the segmentation (don't worry, the moving tail will not be drawn into the image)."

    eval $Ed(EdPhaseWire,helpWidget) tag configure normal   $Help(tagNormal)
    
    $Ed(EdPhaseWire,helpWidget) insert insert "$help" normal

    #-------------------------------------------
    # TabbedFrame->Basic frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic
    
    # Standard stuff
    frame $f.fRender  -bg $Gui(activeWorkspace)
    frame $f.fGrid      -bg $Gui(activeWorkspace)
    frame $f.fContour   -bg $Gui(activeWorkspace)
    frame $f.fReset   -bg $Gui(activeWorkspace)
    frame $f.fPhaseMenu     -bg $Gui(activeWorkspace)
    frame $f.fApply     -bg $Gui(activeWorkspace)
    frame $f.fSettings     -bg $Gui(activeWorkspace)
    pack $f.fGrid $f.fRender $f.fContour $f.fReset  \
        $f.fSettings $f.fPhaseMenu $f.fApply \
        -side top -pady $Gui(pad)

    # Standard Editor interface buttons
    EdBuildRenderGUI $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic.fRender Ed(EdPhaseWire,render)
    
    #-------------------------------------------
    # TabbedFrame->Basic->Grid frame (output color)
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic.fGrid
    
    # Output label
    eval {button $f.bOutput -text "Output:" \
        -command "ShowLabels EdPhaseWireLabel"} $Gui(WBA)
    TooltipAdd $f.bOutput \
        "Choose output label value to draw on the slice"
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdPhaseWireLabel"
    bind $f.eOutput <FocusOut> "EdPhaseWireLabel"
    eval {entry $f.eName -width 14 -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    
    lappend Label(colorWidgetList) $f.eName


    #-------------------------------------------
    # TabbedFrame->Basic->Contour frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic.fContour
    eval {button $f.bContour -text "Stay near last slice's contour" \
        -command {puts "this feature is coming soon."}} $Gui(WBA)
    # Lauren implement this!
    #pack $f.bContour
    #TooltipAdd $f.bContour \
        "Keep the PhaseWire near the contour you drew on the previous slice."

    #-------------------------------------------
    # TabbedFrame->Basic->Reset Frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic.fReset
    eval {button $f.bReset -text "Clear Contour" \
        -command "EdPhaseWireClearCurrentSlice"} $Gui(WBA)
    TooltipAdd $f.bReset \
        "Reset the PhaseWire for this slice."

    eval {button $f.bResetSeg -text "Undo Last Click" \
        -command "EdPhaseWireClearLastSegment"} $Gui(WBA)
        TooltipAdd $f.bResetSeg \
        "Clear the latest part of the PhaseWire."

    pack $f.bReset $f.bResetSeg -side left -pady $Gui(pad) -padx $Gui(pad)


    #-------------------------------------------
    # TabbedFrame->Basic->PhaseMenu frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic.fPhaseMenu
    set label       "$f.l"
    set menubutton  "$f.mb"
    set menu        "$f.mb.m"
    
    eval {label $label -text "Image Feature Size"} $Gui(WLA)

    eval {menubutton $menubutton -text  $Ed(EdPhaseWire,omega,name) \
            -relief raised -bd 2 -menu $menu} $Gui(WMBA)
    eval {menu $menu} $Gui(WMA)

    TooltipAdd $menubutton \
        "Choose the size of the structure you are segmenting."

    foreach id $Ed(EdPhaseWire,omega,idList) name $Ed(EdPhaseWire,omega,nameList) {
        $menu add command -label $name -command "EdPhaseWireSetOmega $id"
    }
    grid $label $menubutton -padx $Gui(pad)
    # save menu to configure later
    set Ed(EdPhaseWire,omega,menu) $menu
    set Ed(EdPhaseWire,omega,menubutton) $menubutton

    #-------------------------------------------
    # TabbedFrame->Basic->Apply frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fBasic.fApply
    
    # frame for shape control
    frame $f.f -bg $Gui(activeWorkspace)
    eval {label $f.f.l -text "Shape:"} $Gui(WLA)
    pack $f.f.l -side left -padx $Gui(pad)

    # "Line" drawing button really draws our wire of points
    foreach shape "Polygon Lines" draw "Polygon Points" {
    eval {radiobutton $f.f.r$shape -width [expr [string length $shape]+1] \
            -text "$shape" -variable Ed(EdPhaseWire,shape) -value $draw \
            -command "EdPhaseWireUpdate SetShape" \
            -indicatoron 0} $Gui(WCA)
        pack $f.f.r$shape -side left 
    }
    
    # Apply
    eval {button $f.bApply -text "Apply" \
        -command "EdPhaseWireApply"} $Gui(WBA) {-width 8}
    TooltipAdd $f.bApply \
        "Apply the PhaseWire contour you have drawn."
    
    
    pack $f.f $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # TabbedFrame->Advanced frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced

    frame $f.fSettings   -bg $Gui(activeWorkspace)
    pack $f.fSettings -side top -fill x

    frame $f.fTrainingFile   -bg $Gui(activeWorkspace)
    pack $f.fTrainingFile -side top -pady $Gui(pad) -fill x

    #-------------------------------------------
    # TabbedFrame->Advanced->Settings frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced.fSettings

    frame $f.fSlider   -bg $Gui(activeWorkspace)
    pack $f.fSlider -side top  -pady $Gui(pad) -fill x

    frame $f.fInputImages   -bg $Gui(activeWorkspace)
    pack $f.fInputImages -side top  -pady $Gui(pad) -fill x

    frame $f.fPhase   -bg $Gui(activeWorkspace)
    pack $f.fPhase -side top  -pady $Gui(pad) -fill x

    frame $f.fWL   -bg $Gui(activeWorkspace)
    pack $f.fWL -side top  -pady $Gui(pad) -fill x

    frame $f.fGrid   -bg $Gui(activeWorkspace)
    pack $f.fGrid -side top  -pady $Gui(pad) -fill x


    #-------------------------------------------
    # TabbedFrame->Advanced->Settings->Grid frame 
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced.fSettings.fGrid
    
    # Output label
    eval {button $f.bOutput -text "Click Color:" \
        -command "ShowLabels EdPhaseWireClickLabel"} $Gui(WBA)
    TooltipAdd $f.bOutput \
        "Choose output label value to draw on the slice"
    eval {entry $f.eOutput -width 6 -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "EdPhaseWireClickLabel"
    bind $f.eOutput <FocusOut> "EdPhaseWireClickLabel"
    eval {entry $f.eName -width 14 -textvariable Label(name)} $Gui(WEA) \
        {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    
    lappend Label(colorWidgetList) $f.eName

    #-------------------------------------------
    # TabbedFrame->Advanced->Settings->Slider Frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced.fSettings.fSlider

    foreach slider "PhaseOffset" text "phase" {
    eval {label $f.l$slider -text "$text:"} $Gui(WLA)
    eval {entry $f.e$slider -width 4 \
        -textvariable Ed(EdPhaseWire,[Uncap $slider])} $Gui(WEA)
    bind $f.e$slider <Return>   "EdPhaseWireUpdate $slider"
    bind $f.e$slider <FocusOut> "EdPhaseWireUpdate $slider"
    eval {scale $f.s$slider -from $Ed(EdPhaseWire,[Uncap $slider]Low) \
        -to $Ed(EdPhaseWire,[Uncap $slider]High) \
        -length 50 -variable Ed(EdPhaseWire,[Uncap $slider])  \
        -resolution 1 \
        -command "EdPhaseWireUpdate $slider"} \
        $Gui(WSA) {-sliderlength 22}

    pack $f.l$slider $f.s$slider $f.e$slider \
        -side left -pady $Gui(pad) -padx $Gui(pad)
    #grid $f.l$slider $f.e$slider -padx 2 -pady 2 -sticky w
    #grid $f.l$slider -sticky e
    #grid $f.s$slider -columnspan 2 -pady 2 
    
    set Ed(EdPhaseWire,slider$slider) $f.s$slider
    }

    set tooltip \
        "Phase value to follow in the phase image. \n \
        This controls whether to segment towards lighter or darker pixels.\n \
        Or you may use the Pick button to select a phase value \n \
        on the desired contour."

    TooltipAdd $Ed(EdPhaseWire,sliderPhaseOffset) $tooltip
    TooltipAdd $f.ePhaseOffset $tooltip

    eval {checkbutton $f.cClickPhase -text "Pick" \
        -variable Ed(EdPhaseWire,clickSetsPhase) \
        -indicatoron 0  } $Gui(WCA)
    TooltipAdd $f.cClickPhase \
        "Use to segment darker or lighter pixels.  \n \
        Press button, then click on image to train. \n \
        (When button is pressed, your next click on the slice \n \
        will set the phase value to follow in the image.)"

    pack $f.cClickPhase -side left -pady $Gui(pad) -padx $Gui(pad)
    
    eval {button $f.bResetPhase -text "Reset" \
        -command "EdLiveWireResetPhaseDefaults"} $Gui(WBA)
        TooltipAdd $f.bResetPhase \
        "Reset the phase setting to the default value"

    pack $f.bResetPhase -side left -pady $Gui(pad) -padx $Gui(pad)


    #-------------------------------------------
    # TabbedFrame->Advanced->Settings->InputImages frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced.fSettings.fInputImages

    eval {button $f.bPopup -text "View Edges" \
        -command "EdPhaseWireRaiseEdgeImageWin"} $Gui(WBA) {-width 12}
    pack $f.bPopup -side top -pady $Gui(pad) 
    TooltipAdd $f.bPopup \
        "View input weighted graph to PhaseWire.\nImages should emphasize desired features as low costs, or dark areas."


    #-------------------------------------------
    # TabbedFrame->Advanced->Settings->Phase frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced.fSettings.fPhase

    # PHASE
    eval {button $f.bClr -text " invisible PhaseWire tail " \
        -command "EdPhaseWirePrettyPicture"} $Gui(WBA)
    pack $f.bClr -side top -pady $Gui(pad)
    TooltipAdd $f.bClr \
        "Don't show the tail of the PhaseWire, for screen shots"
   
    eval {label $f.lPW -text "P:"} $Gui(WLA)
    eval {label $f.lCW -text "C:"} $Gui(WLA)
    eval {label $f.lGW -text "T:"} $Gui(WLA)
    eval {label $f.lCU -text "CU:"} $Gui(WLA)
    eval {label $f.lCL -text "CL:"} $Gui(WLA)
    eval {entry $f.ePW -width 2 -textvariable Ed(EdPhaseWire,phaseWeight)} $Gui(WEA)
    eval {entry $f.eCW -width 2 -textvariable Ed(EdPhaseWire,certWeight)} $Gui(WEA)
    eval {entry $f.eGW -width 2 -textvariable Ed(EdPhaseWire,gradWeight)} $Gui(WEA)
    eval {entry $f.eCU -width 6 -textvariable Ed(EdPhaseWire,certUpperCutoff)} $Gui(WEA)
    eval {entry $f.eCL -width 6 -textvariable Ed(EdPhaseWire,certLowerCutoff)} $Gui(WEA)
    pack $f.lPW $f.ePW $f.lCW $f.eCW  $f.lGW $f.eGW $f.lCL $f.eCL $f.lCU $f.eCU -side left

    #-------------------------------------------
    # TabbedFrame->Advanced->Settings->WL Frame
    #-------------------------------------------
    set f $Ed(EdPhaseWire,frame).fTabbedFrame.fAdvanced.fSettings.fWL

    eval {checkbutton $f.cWindowLevel \
        -text "Window Level Image Before Phase Comp." \
        -variable Ed(EdPhaseWire,useWindowLevel) \
        -indicatoron 0 -command "EdPhaseUseWindowLevel"} $Gui(WCA)
    pack $f.cWindowLevel -side left -padx 2 
    TooltipAdd $f.cWindowLevel "Toggle window leveling of data before phase computation"

    # read default filter kernel at startup to avoid update
    # of vtk classes that don't have their inputs yet
    EdPhaseWireSetOmega $Ed(EdPhaseWire,omega,id)


}

#-------------------------------------------------------------------------------
# .PROC EdPhaseUseWindowLevel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseUseWindowLevel {} {
    global Lut Ed Slice

    set e EdPhaseWire

    if $Ed($e,useWindowLevel) {
    puts "USING WL"
    # get original volume and its current w/l
    #-------------------------------------------
    set v [EditorGetOriginalID]
    set window [Volume($v,node) GetWindow]
    set level  [Volume($v,node) GetLevel]
    
    # imitate this display in our pipeline
    #-------------------------------------------
    Ed($e,phase,windowLevel) SetWindow $window
    Ed($e,phase,windowLevel) SetLevel $level
    # get the lookup table we are using already for this volume
    Ed($e,phase,windowLevel) SetLookupTable Lut([Volume($v,node) GetLUTName],lut)
    
    # set up pipeline
    #-------------------------------------------
    foreach s $Slice(idList) {
        Ed($e,phase,fftSlice) SetInput [Ed($e,phase,wlComp)  GetOutput]
        Slicer SetFirstFilter $s Ed($e,phase,windowLevel)
    }
    puts "win: $window lev: $level"
    
    } else {
    puts "NO WL"
    foreach s $Slice(idList) {
        Slicer SetFirstFilter $s Ed($e,phase,fftSlice) 
    }
    }
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseConvertToRadians
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseConvertToRadians {degrees} {
    
    # we want radians scaled by 1000, since that is how the
    # phase image is scaled
    # we also want to subtract this offset, so make it negative

    # this is equivalent to:
    #set rad [expr $degrees * 3.14159 / 180]
    #return [expr -1 * $rad * 1000]        
    return [expr $degrees * -17.453278]
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseConvertToDegrees
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseConvertToDegrees {radians} {

    # this is equivalent to:
    #set deg [expr [expr $radians / 1000] * 180 / 3.14159]]
    # note the hidden 1000 scaling to match phase data scaling
    return [expr $radians * 0.057295828]
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWirePrettyPicture
# Turn off display of the livewire "tail" so that saving current slice
# image looks nice.  Don't forget to turn the "tail" back on...
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWirePrettyPicture {}  {
    global Slice

    set s $Slice(activeID)

    set invis [Ed(EdPhaseWire,lwPath$s) GetInvisibleLastSegment]
    if {$invis == 1} {
    puts "turning invis off"
    set invis 0
    } else {
    puts "turning invis on"
    set invis 1
    }

    Ed(EdPhaseWire,lwPath$s) SetInvisibleLastSegment $invis

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireRaiseEdgeImageWin
# Displays "edge image," which shows edge weights (costs)
# that are derived from the image.
# Boundaries of interest should be enhanced in these images.
# This proc creates the window with GUI and sets inputs for display.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireRaiseEdgeImageWin {} {
    global Slice Ed

    set s $Slice(activeID)
    set w .phaseWireEdgeWin$s

    # if already created, raise and return
    if {[winfo exists $w] != 0} {
    raise $w
    return
    }

    # make the pop up window
    toplevel $w

    # top frame
    frame $w.fTop
    pack $w.fTop -side top

    # bottom (controls) frame
    frame $w.fBottom
    pack $w.fBottom -side top -fill both
    
    # left-hand frame
    frame $w.fTop.fLeft
    pack $w.fTop.fLeft -side left

    # right-hand frame
    frame $w.fTop.fRight
    pack $w.fTop.fRight -side left

    #-------------------------------------------
    # Left frame
    #-------------------------------------------

    # put image viewer in it
    #frame $w.fTop
    set f $w.fTop.fLeft
    vtkTkImageViewerWidget $f.v$s -width 256 -height 256 \
        -iv Ed(EdPhaseWire,viewer$s)
    pack $f.v$s -side left -fill both
    bind $f.v$s <Expose> {ExposeTkImageViewer %W %x %y %w %h}
    set viewerWidget $f.v$s

    #-------------------------------------------
    # Right frame
    #-------------------------------------------
    set f $w.fTop.fRight

    # histogram
    ##source /scratch/src/slicer/program/vtkHistogramWidget.tcl
    #source vtkHistogramWidget.tcl
    #set hist [vtkHistogramWidget $f.hist]
    #scan [[Ed(EdPhaseWire,viewer$s) GetInput] GetExtent] "%d %d %d %d %d %d" x1 x2 y1 y2 z1 z2
    ## this should match the first image displayed
    #HistogramWidgetSetInput $hist [Ed(EdPhaseWire,viewer$s) GetInput]
    #HistogramWidgetSetExtent $hist $x1 $x2 $y1 $y2 $z1 $z2
    #pack $hist -side left -padx 3 -pady 3 -fill both -expand t
    #HistogramWidgetBind $f.hist

    # save vars 
    #set Ed(EdPhaseWire,edgeHistWidget$s) $hist

    #-------------------------------------------
    # Bottom frame
    #-------------------------------------------

    # window/level controls   
    set win [Ed(EdPhaseWire,viewer$s) GetColorWindow]
    set lev [Ed(EdPhaseWire,viewer$s) GetColorLevel]
    set Ed(EdPhaseWire,viewerWindow$s) $win
    set Ed(EdPhaseWire,viewerLevel$s) $lev

    frame $w.fBottom.fwinlevel
    set f $w.fBottom.fwinlevel
    frame $f.f1
    label $f.f1.windowLabel -text "Window"
    scale $f.f1.window -from 1 -to [expr $win * 2]  \
        -variable Ed(EdPhaseWire,viewerWindow$s) \
        -orient horizontal \
        -command "Ed(EdPhaseWire,viewer$s) SetColorWindow"
    frame $f.f2
    label $f.f2.levelLabel -text "Level"
    scale $f.f2.level -from [expr $lev - $win] -to [expr $lev + $win] \
        -variable Ed(EdPhaseWire,viewerLevel$s) \
        -orient horizontal \
        -command "Ed(EdPhaseWire,viewer$s) SetColorLevel"
    pack $f -side top
    pack $f.f1 $f.f2 -side top
    pack $f.f1.windowLabel $f.f1.window -side left
    pack $f.f2.levelLabel $f.f2.level -side left
    
    # radiobuttons switch between edge images
    frame $w.fBottom.fedgeBtns
    set f $w.fBottom.fedgeBtns
    label $f.lradio -text "Edge Direction"
    pack $f.lradio -side left

    # hard-code the number of inputs to grab from livewire for now:
    set edges {0 1 2 3 4 5 6 7}
    set Ed(EdPhaseWire,edge$s) 0
    foreach edge $edges text $edges {
    radiobutton $f.r$edge -width 2 -indicatoron 0\
        -text "$text" -value "$edge" \
        -variable Ed(EdPhaseWire,edge$s) \
        -command "EdPhaseWireUpdateEdgeImageWin $viewerWidget $edge"
    pack $f.r$edge -side left -fill x -anchor e
    }
    pack $f -side top

    # make save image button
    frame $w.fBottom.fSave
    set f $w.fBottom.fSave
    button $f.b -text "Save Edge Image" -command EdPhaseWireWriteEdgeImage
    pack $f -side top
    pack $f.b -side top -fill x

    # make close button
    frame $w.fBottom.fcloseBtn
    set f $w.fBottom.fcloseBtn
    button $f.b -text Close -command "lower $w"
    pack $f -side top
    pack $f.b -side top -fill x

}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireUpdateEdgeImageWin
# For viewing the inputs to the livewire: displays the edge image inputs
# to the livewire filter of the active slice.
# (up, down, left, or right edges can be shown).
# .ARGS
# widget viewerWidget what to render
# int edgeNum number of the edge direction
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireUpdateEdgeImageWin {viewerWidget edgeNum} {
    global Slice Ed
    
    set s $Slice(activeID)
    
    # test inputs to sum filter here like this
    #Ed(EdPhaseWire,viewer$s) SetInput [Ed(EdPhaseWire,imageSumFilter) GetInput $edgeNum]
    # get input from livewire and show image
    set inputNum [expr $edgeNum + 1]
    Ed(EdPhaseWire,viewer$s) SetInput [Ed(EdPhaseWire,lwPath$s) GetInput $inputNum]

    $viewerWidget Render

    # histogram
    #HistogramWidgetSetInput $Ed(EdPhaseWire,edgeHistWidget$s) \
#        [Ed(EdPhaseWire,viewer$s) GetInput]
    #scan [[Ed(EdPhaseWire,viewer$s) GetInput] GetExtent] \
    #    "%d %d %d %d %d %d" x1 x2 y1 y2 z1 z2
    #HistogramWidgetSetExtent $Ed(EdPhaseWire,edgeHistWidget$s) \
    #    $x1 $x2 $y1 $y2 $z1 $z2
    #HistogramWidgetRender $Ed(EdPhaseWire,edgeHistWidget$s)
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireWriteEdgeImage
# Dump edge image to a file (ppm).
# Uses default filename edgeImageX.001, where X = edge number.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireWriteEdgeImage {} {
    global Ed Slice
    
    set s $Slice(activeID)
    # currently chosen edge dir on GUI
    set edge $Ed(EdPhaseWire,edge$s)
    if {$edge == ""} {
    set edge 0
    }
    # get filename
    set filename "edgeImage${edge}.001"
    

    # save it  (ppm default now)
    vtkImageCast cast
    #cast SetInput [Ed(EdPhaseWire,imageSumFilter) GetInput $edge]
    cast SetInput [Ed(EdPhaseWire,lwPath$s) GetInput $edge]
    #cast SetInput [Ed(EdPhaseWire,lwSetup$s) GetEdgeImage $edge]

    cast SetOutputScalarTypeToUnsignedChar

    vtkPNMWriter writer
    writer SetInput [cast GetOutput]
    writer SetFileName $filename
    writer Write

    cast Delete
    writer Delete
    tk_messageBox -message \
        "Saved image as $filename in dir where slicer was run.\nOpen image as unsigned char to view in slicer."

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireStartPipeline
# Sets up filters to get input from Slicer (vtkMrmlSlicer) object.
# Updates the pipeline.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireStartPipeline {} {
    global Ed Slice Gui Volume

    set Gui(progressText) "PhaseWire Initialization"    

    set e EdPhaseWire

    # tell the slicer to overlay our filter output on the fore layer
    # (the Working volume)
    Slicer FilterOverlayOn
    
    # Layers: Back=Original, Fore=Working
    # The original volume needs to be the filter input
    Slicer BackFilterOn
    Slicer ForeFilterOff

    # only apply filters to active slice
    Slicer FilterActiveOn

    # set up the phase/cert inputs and pipeline
    EdPhaseWireUsePhasePipeline

    # force upper slicer pipeline to execute
    Slicer ReformatModified
    # update slicer object (this gives the 3 main reformatted slices...)
    Slicer Update
}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireStopPipeline
# Shuts down the pipeline that hooks into the slicer object.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireStopPipeline {} {
    global Ed Volume

    Slicer FilterOverlayOff
    Slicer BackFilterOff
    Slicer ForeFilterOff
    Slicer ReformatModified
    Slicer Update

    # Stop reformatting phase and cert volumes
    Slicer RemoveAllVolumesToReformat
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireEnter
# Called upon entering module.
# Forces pipeline to update initially.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireEnter {} {
    global Ed Label Slice Editor


    # Create filter kernels
    #-------------------------------------------
    if {[EdPhaseWireSetOmega $Ed(EdPhaseWire,omega,id)] == 1} {
    puts "Unable to create filter kernels"
    # give up the ghost
    return
    }
    
    # make sure we've got phase
    #if {[EdPhaseWireFindInputPhaseVolumes] == "" } {
    #    tk_messageBox -message "Cannot find phase and cert volumes"
    # Lauren don't let the user enter this effect.
    
    #    return
    #    }
    
    # we are drawing in the label layer, so it had
    # better be visible
    if {$Editor(display,labelOn) == 0} {
    MainSlicesSetVolumeAll Label [EditorGetWorkingID]
    # Lauren then variable is wrong?
    }

    # ignore mouse movement until we have a start point
    set Ed(EdPhaseWire,pipelineActiveAndContourStarted) 0

    # keep track of active slice to reset contour if slice changes
    set Ed(EdPhaseWire,activeSlice) $Slice(activeID)

    # set up Slicer pipeline
    EdPhaseWireStartPipeline

    # Make sure we're colored
    LabelsColorWidgets

    # ensure label to draw with is set at least to default
    # otherwise the label is the empty string
    #LabelsFindLabel
    if {$Label(label) == ""} {
        set Label(label) 2
    }

    # make sure we're drawing the right color
    foreach s $Slice(idList) {
    Ed(EdPhaseWire,lwPath$s) SetLabel $Label(label)
    }

    # use slicer object to draw (like in EdDraw)
    set e EdPhaseWire
    Slicer DrawSetRadius $Ed($e,radius)
    Slicer DrawSetShapeTo$Ed($e,shape)
    if {$Label(activeID) != ""} {
    set color [Color($Label(activeID),node) GetDiffuseColor]
    eval Slicer DrawSetColor $color
    } else {
    Slicer DrawSetColor 0 0 0
    }
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireExit
# 
# Called upon leaving module.  Shuts down filter pipeline
# that was displaying the interactive PhaseWire over images.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireExit {} {
    global Ed Slice

    # reset PhaseWire drawing
    foreach s $Slice(idList) {
    EdPhaseWireResetSlice $s
    }

    # no more filter pipeline
    EdPhaseWireStopPipeline

    EdPhaseWireRenderInteractive
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireUpdate
# Update after user changes parameters in Basic GUI.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireUpdate {type {param ""}} {
    global Ed Label Slice
    
    set e EdPhaseWire
    
    switch $type {
    SetShape {
        Slicer DrawSetShapeTo$Ed($e,shape)
        set Ed($e,shape) [Slicer GetShapeString]
    }
    PhaseOffset {
        foreach s $Slice(idList) {
        Ed($e,phaseScale$s) SetShift \
            [EdPhaseConvertToRadians $Ed($e,phaseOffset)]
        Ed($e,phaseScale$s) Update

        # clear the cached information in livewire
        Ed(EdPhaseWire,lwPath$s) ClearContourTail        
        }
    }
    }

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireB1
# When mouse is clicked, pass location to live wire filter.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireB1 {x y} {
    global Ed Slice

    set s $Slice(activeID)

    set Ed(EdPhaseWire,pipelineActiveAndContourStarted) 1
    
    # if we just changed to this slice
    if {$Ed(EdPhaseWire,activeSlice) != $s} {
    set Ed(EdPhaseWire,activeSlice) $s
    }

    # tell the livewire filter its new start point
    Ed(EdPhaseWire,lwPath$s) SetStartPoint $x $y
    
    # set new value of phase offset if needed
    if {$Ed(EdPhaseWire,clickSetsPhase) == 1} {
    puts "Lauren implement clicking!"
    return
    # we are not using the slicer reformatting anymore:

    # grab phase (grayscale value of pixel) at this point
    set v Volume($Ed(EdPhaseWire,phaseVol),vol)
    set data [Slicer GetReformatOutputFromVolume $v]
    # turn off display of error if we click outside of the image
    $data GlobalWarningDisplayOff
    # phase value:
    set pixel [$data GetScalarComponentAsFloat $x $y 0 0]
    $data GlobalWarningDisplayOn
    puts $pixel
    
    # follow this value phase isocontour now. 
    # (0 means we clicked out of image, and we won't follow that value)
    if {$pixel != 0} {
        set Ed(EdPhaseWire,phaseOffset) [EdPhaseConvertToDegrees $pixel]
    }
    EdPhaseWireUpdate PhaseOffset
    }

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireMotion
# When mouse moves over slice, if we already have a start click, 
# pass end point (current mouse location) to live wire filter.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireMotion {x y} {
    global Ed Slice

    set s $Slice(activeID)
    
    # if no first click to begin contour, do nothing
    if {$Ed(EdPhaseWire,pipelineActiveAndContourStarted) == 0} {
    return
    }
        
    Ed(EdPhaseWire,lwPath$s) SetEndPoint $x $y
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireRenderInteractive
# Render whatever the user has asked to render (on GUI: either 1 slice
# 3 slices, or 3D...)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireRenderInteractive {} {
    global Ed
    
    Render$Ed(EdPhaseWire,render)
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireClickLabel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireClickLabel {{label ""} } {
    global Label Slice

    if {$label == ""} {
    set label $Label(label)    
    }
    # set the label for the clicked-on points
    foreach s $Slice(idList) {
    Ed(EdPhaseWire,lwPath$s) SetClickLabel  $label
    }
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireLabel
# Called when label changes. Gives right label number to livewire and 
# slicer objects
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireLabel {} {
    global Color Label Slice
    
    LabelsFindLabel
    
    if {$Label(activeID) != ""} {
    set color [Color($Label(activeID),node) GetDiffuseColor]
    eval Slicer DrawSetColor $color
    } else {
    Slicer DrawSetColor 0 0 0
    }

    # update filter stuff    
    foreach s $Slice(idList) {
    Ed(EdPhaseWire,lwPath$s) SetLabel $Label(label)    
    }

    # render whatever we are supposed to (slice, 3slice, or 3D)
    EdPhaseWireRenderInteractive
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireClearCurrentSlice
# Clears contour from filters and makes slice redraw.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireClearCurrentSlice {} {
    global Slice
    
    set s $Slice(activeID)
    EdPhaseWireResetSlice $s
    Slicer Update
    RenderSlice $s
}


#-------------------------------------------------------------------------------
# .PROC EdLiveWireResetPhaseDefaults
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdLiveWireResetPhaseDefaults {} {
    global Ed

    # default is 90 degrees for an edge
    set Ed(EdPhaseWire,phaseOffset) $Ed(EdPhaseWire,defaultPhaseOffset)
    EdPhaseWireUpdate PhaseOffset

}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireClearLastSegment
# Clear the latest part of the livewire: start over from the previous click.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireClearLastSegment {} {
    global Slice
    
    set s $Slice(activeID)
    # reset latest contour points
    Ed(EdPhaseWire,lwPath$s) ClearLastContourSegment

    Slicer Update
    RenderSlice $s
}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireResetSlice
# Clear the previous contour to start over with new start point.
# After, must do Slicer Update  and  RenderSlice $s
# to clear the slice (just call EdPhaseWireClearCurrentSlice to do it all)
# .ARGS
# int s number of the slice
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireResetSlice {s} {
    global Ed

    # reset contour points
    Ed(EdPhaseWire,lwPath$s) ClearContour
    # ignore mouse motion until user clicks a slice
    set Ed(EdPhaseWire,pipelineActiveAndContourStarted) 0
}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireApply
# Actually draw the polygon, line, whatever, into the volume.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireApply {} {
    global Ed Volume Label Gui Slice

    set s $Slice(activeID)

    # if there are no points, do nothing
    set rasPoints [Ed(EdPhaseWire,lwPath$s) GetContourPixels]
    if {[$rasPoints GetNumberOfPoints] == 0} {
    puts "no points to apply!"
    return
    }
    
    set e EdPhaseWire

    # the working volume is editor input (where we want to draw)
    # (though the original vol is input to the PhaseWire filters.)
    set v [EditorGetInputID Working]

    # Validate input    
    if {[ValidateInt $Label(label)] == 0} {
    tk_messageBox -message "Output label is not an integer."
    return
    }
    if {[ValidateInt $Ed($e,radius)] == 0} {
    tk_messageBox -message "Point Radius is not an integer."
    return
    }

    # standard editor function must be called
    EdSetupBeforeApplyEffect $v $Ed($e,scope) Active

    # text over blue progress bar
    set Gui(progressText) "PhaseWire [Volume($v,node) GetName]"    

    # attributes of region to draw
    set label    $Label(label)
    set radius   $Ed($e,radius)
    set shape    $Ed($e,shape)

    # Give points to slicer object to convert to ijk
    set numPoints [$rasPoints GetNumberOfPoints]
    for {set p 0} {$p < $numPoints} {incr p} {
    scan [$rasPoints GetPoint $p] "%d %d %d" x y z
    Slicer DrawInsertPoint $x $y
    }
    Slicer DrawComputeIjkPoints
    set points [Slicer GetDrawIjkPoints]

    # give ijk points to editor object to actually draw them into the volume
    Ed(editor)   Draw $label $points $radius $shape
    
    # clear points that livewire object was storing
    EdPhaseWireResetSlice $s

    # reset editor object
    Ed(editor)     SetInput ""
    Ed(editor)     UseInputOff

    # standard editor function must be called
    EdUpdateAfterApplyEffect $v $Ed($e,render)

    # always delete points 
    Slicer DrawDeleteAll
}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireStartProgress
#
#  Wrapper around MainStartProgress (Does Nothing)
#
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireStartProgress {} {
    global Gui

    puts -nonewline $Gui(progressText)
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireShowProgress
# Progress method callback for vtk filters.
# Wrapper around MainShowProgress, which shows the blue bar.
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireShowProgress {filter} {

    puts -nonewline "."

}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireEndProgress
#
# Wrapper around MainEndProgress.
# 
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireEndProgress {} {
    global Ed

    puts ""
    
}

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireUseDistanceFromPreviousContour
#  not finished.  This will make a distance map for input to PhaseWire
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireUseDistanceFromPreviousContour {} {
    global Ed Slice
    
    set s $Slice(activeID)

    # image we need is the previous one from the Working
    # volume (the last slice a contour was drawn on)
    # Lauren: may need to add OR subtract 1, depending!
    set offset [expr $Slice($s,offset) - 1]
    puts "offset: $offset"
    
    EdPhaseWireGetContourSlice $offset

    # test image is okay
    Ed(EdPhaseWire,viewer$s) SetColorWindow 15
    Ed(EdPhaseWire,viewer$s) SetColorLevel 5
    Ed(EdPhaseWire,viewer$s) SetInput $Ed(EdPhaseWire,contourSlice)

}


# Since we don't want this in progress dumb comment on the website:
# Figures out which volumes to use as phase and cert inputs to livewire.
# Currently they must be named phase and cert.  In future, they should
# be dynamically created during segmentation and not read in.

#-------------------------------------------------------------------------------
# .PROC EdPhaseWireFindInputPhaseVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireFindInputPhaseVolumes {} {
    global Ed Volume

    # figure out which volumes to use for the phase and cert
    # inputs.  Now this code just expects they will be 
    # named phase and cert.

    # numbers of the volumes
    set phaseVol ""
    set certVol ""

    # names we expect the volumes to have
    set phase "phase"
    set cert "cert"

    foreach v $Volume(idList) {
    set n Volume($v,node)
    set name [$n GetName]
    #puts $name
    if {$name == $phase} {
        set phaseVol $v
    }
    if {$name == $cert} {
        set certVol $v
    }
    }
    
    if {$phaseVol == "" || $certVol == ""} {
    puts "can't find phase and cert volumes named $phase and $cert"
    return ""
    }

    set Ed(EdPhaseWire,phaseVol) $phaseVol
    set Ed(EdPhaseWire,certVol) $certVol

    return 0
}


#-------------------------------------------------------------------------------
# .PROC EdPhaseWireUsePhasePipeline
# Set up the part of the pipeline that processes the phase and cert images.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EdPhaseWireUsePhasePipeline {} {
    global Ed Slice

    set e EdPhaseWire

    foreach s $Slice(idList) {
    

    # get input grayscale images from Slicer object
    # (grab reformatted image to compute its phase)
    #-------------------------------------------    
    if $Ed($e,useWindowLevel) {
        Ed($e,phase,fftSlice) SetInput [Ed($e,phase,wlComp)  GetOutput]
        Slicer SetFirstFilter $s Ed($e,phase,windowLevel)
    } else {
        Slicer SetFirstFilter $s Ed($e,phase,fftSlice) 
    }

    # put our output over the slice (so the wire is visible)
    Slicer SetLastFilter  $s Ed(EdPhaseWire,lwPath$s)  

    # test this: all input vals > 1000 will be set to 1000.
    Ed($e,certNorm$s) SetLowerCutoff $Ed(EdPhaseWire,certLowerCutoff)
    Ed($e,certNorm$s) SetUpperCutoff $Ed(EdPhaseWire,certUpperCutoff)

    # use current settings from Advanced GUI for combining images
    set sum Ed($e,imageSumFilter$s)
    $sum SetWeightForInput 0 $Ed($e,phaseWeight)
    $sum SetWeightForInput 1 $Ed($e,certWeight)
    $sum SetWeightForInput 2 $Ed($e,gradWeight)

    } 
    
    # get current w/l and use in our pipeline
    if {$Ed($e,useWindowLevel) == "1"} {
    EdPhaseUseWindowLevel
    }

    # update slicer
    Slicer ReformatModified
    Slicer Update
}
