#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Volumes.tcl,v $
#   Date:      $Date: 2006/09/01 21:16:09 $
#   Version:   $Revision: 1.139 $
# 
#===============================================================================
# FILE:        Volumes.tcl
# PROCEDURES:  
#   VolumesInit
#   VolumesBuildGUI
#   VolumesCheckForManualChanges n
#   VolumesManualSetPropertyType n
#   VolumesAutomaticSetPropertyType n
#   VolumesSetPropertyType type
#   VolumesPropsApply
#   VolumesPropsCancel
#   VolumesSetFirst
#   VolumesSetScanOrder order
#   VolumesSetScalarType type
#   VolumesSetLast
#   VolumesEnter
#   VolumesExit
#   VolumesStorePresets p
#   VolumesRecallPresets p
#   VolumesSetReformatOrientation or
#   VolumesProjectVectorOnPlane A B C D V1x V1y V1z V2x V2y V2z
#   VolumesReformatSlicePlane orientation
#   VolumesRotateSlicePlane orientation
#   VolumesReformatSave
#   VolumesAnalyzeExport
#   VolumesCORExport
#   VolumesNrrdExport
#   VolumesGenericExportSetFileType fileType
#   VolumesGenericExport
#   VolumesVtkToNrrdScalarType type
#   VolumesVtkToSlicerScalarType type
#   VolumesComputeNodeMatricesFromIjkToRasMatrix volumeNode ijkToRasMatrix dims
#   VolumesComputeNodeMatricesFromIjkToRasMatrix2 volumeNode ijkToRasMatrix dims
#   VolumesCreateNewLabelOutline v
#   VolumesComputeNodeMatricesFromRasToIjkMatrix volumeNode RasToIjkMatrix dims
#   VolumesUpdateMRML
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC VolumesInit
#
# Default proc called on program start.
# .ARGS
# .END
#------------------------------------------------------------------------------
proc VolumesInit {} {
    global Volumes Volume Module Gui Path prog

    set VolumesVtkSlicerScalarType("char")  "Char"
    set VolumesVtkSlicerScalarType("unsigned\ char")  "UnsignedChar"
    set VolumesVtkSlicerScalarType("short")  "Short"
    set VolumesVtkSlicerScalarType("unsigned\ short")  "UnsignedShort"
    set VolumesVtkSlicerScalarType("int")  "Int"
    set VolumesVtkSlicerScalarType("unsigned\ int")  "UnsignedInt"
    set VolumesVtkSlicerScalarType("long")  "Long"
    set VolumesVtkSlicerScalarType("unsigned\ long")  "UnsignedLong"
    set VolumesVtkSlicerScalarType("float")  "Float"
    set VolumesVtkSlicerScalarType("double")  "Double"

    # Define Tabs
    set m Volumes
    set Module($m,row1List) "Help Display Props" 
    set Module($m,row1Name) "{Help} {Display} {Props}"
    set Module($m,row1,tab) Display
    
    set Module($m,row2List) "Export Other" 
    set Module($m,row2Name) "{Export} {Other}"
    set Module($m,row2,tab) Export

    # Module Summary Info
    set Module($m,overview) "Load/display 3d volumes (grayscale or label) in the slicer."
    set Module($m,author) "Core"
    set Module($m,category) "IO"

    # Define Procedures
    set Module($m,procGUI)  VolumesBuildGUI
    set Module($m,procMRML)  VolumesUpdateMRML

    # For now, never display histograms to avoid bug in histWin Render
    # call in MainVolumesSetActive. (This happened when starting slicer,
    # switching to Volumes panel, switching back to Data, and then 
    # adding 2 transforms.)
    # Windows98 Version II can't render histograms
    set Volume(histogram) On

    # Define Dependencies
    set Module($m,depend) Fiducials

    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
                                  {$Revision: 1.139 $} {$Date: 2006/09/01 21:16:09 $}]

    # Props
    if { $::env(SLICER_OPTIONS_DEFAULT_FILE_FORMAT) == "nrrd"} {
        set Volume(defaultFileFormat) VolNrrd
    } else {
        set Volume(defaultFileFormat) VolBasic
    }
    set Volume(propertyType) $Volume(defaultFileFormat)

    # text for menus displayed on Volumes->Props->Header GUI
    set Volume(scalarTypeMenu) "Char UnsignedChar Short UnsignedShort\ 
    {Int} UnsignedInt Long UnsignedLong Float Double"
    set Volume(scanOrderMenu) "{Sagittal:LR} {Sagittal:RL} {Axial:SI}\
            {Axial:IS} {Coronal:AP} {Coronal:PA}"
    # corresponding values to use in Volume(scanOrder)
    set Volume(scanOrderList) "LR RL SI IS AP PA" 
    
    MainVolumesSetGUIDefaults

    set Volume(DefaultDir) ""

    #reformatting variables
    #---------------------------------------------
    vtkImageWriter Volumes(writer)
    # vtkImageReformat Volumes(reformatter)
    Volumes(writer) SetFileDimensionality 2
    Volumes(writer) AddObserver StartEvent MainStartProgress
    Volumes(writer) AddObserver ProgressEvent  "MainShowProgress Volumes(writer)"
    Volumes(writer) AddObserver EndEvent        MainEndProgress

    set Volumes(prefixSave) ""
    set Volumes(prefixCORSave) ""
    set Volumes(prefixNrrdSave) ""
    set Volumes(prefixGenericSave) ""

    set Volumes(exportFileType) Radiological
    set Volumes(exportFileTypeList) {Radiological Neurological}
    set Volumes(exportFileTypeList,tooltips) {"File contains radiological convention images" "File contains a neurological convention images"}
    set Volume(UseCompression) 1

    # Submodules for reading various volume types
    #---------------------------------------------

    # Find all tcl files in subdirectory and source them
    set dir [file join tcl-modules Volumes]

    # save the already loaded volume readers (from modules)
    set cmds [info command Vol*Init]

    set Volume(readerModules,idList) [DevSourceTclFilesInDirectory $dir]

    # get the init functions from the modules, skipping base tcl file init procedures
    foreach c $cmds {
        if {$Module(verbose) == 1} {puts "vol-init = $c"}
        if {$c != "VolumesInit" && $c != "VolumeMathInit" && $c != "VolRendInit" && $c != "VolumeTextureMappingInit"} {
            scan $c "%\[^I\]sInit" name
            lappend Volume(readerModules,idList) $name
        }
    }

    # Call each submodule's init function if it exists
    foreach m $Volume(readerModules,idList) {
        if {[info command ${m}Init] != ""} {
            ${m}Init
        }
    }

    if {0} {
        # register sub modules color functions if they exist
        foreach m $Volume(readerModules,idList) {
            if {[info exists Volume(readerModules,$m,procColor)] == 1} {
                lappend colorProcs $Volume(readerModules,$m,procColor)
            }
        }
        puts "Volumes.tcl registering colour procedures: $colorProcs"
        set Module(Volumes,procColor) $colorProcs
    }

    # Legacy things specific to submodules 
    #---------------------------------------------
    # Added by Attila Tanacs 10/18/2000
    set Module($m,procEnter) VolumesEnter
    set Module($m,procExit) VolumesExit
    lappend Module(procStorePresets) VolumesStorePresets
    lappend Module(procRecallPresets) VolumesRecallPresets
    set Volumes(eventManager) {}
    # End

}

#-------------------------------------------------------------------------------
# .PROC VolumesBuildGUI
# Builds volumes module's GUI
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesBuildGUI {} {
    global Gui Slice Volume Lut Module Volumes Fiducials Path

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Display
    # Props
    #   Top
    #     Active
    #     Type
    #   Bot
    #     Basic
    #     Header
    # Other
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
Description by tab:
<P>
<UL>
<LI><B>Display:</B> Set the volume you wish to change as the 
<B>Active Volume</B>.  Then adjust these:
<BR><B>Window/Level:</B> sets which pixel values will have the most
visible range of color values.
<BR><B>Threshold:</B> pixels that do not satisfy the threshold appear
transparent on the reformatted slices.  Use this to clip away occluding
slice planes.
<BR><B>Palette:</B> select the color scheme for the data. Overlay colored
functional data on graylevel anatomical data.
<BR><B>Interpolate:</B> indicate whether to interpolate between voxels
on the reformatted slices.
<BR><LI><B>Props:</B> set the header information
<BR><LI><B>Export:</B> export a volume as an Analyze, COR or Nrrd file
<BR><LI><B>Other:</B> The <B>Slider Range</B> for the Window/Level/Threshold
sliders is normally automatically set according to the min and max voxel 
values in the volume.  However, some applications, such as monitoring 
thermal surgery, requires setting these manually to retain the same color 
scheme as the volume's data changes over time due to realtime data
acquisition.
<BR><LI><B>Reformat:</B> this functionality has been removed from this module. Please use the Realign-Resample module to create a matrix from landmarks, and the Transform Volume module to resample a volume given a matrix and scan order.
"

    set reformathelpstring "
<BR><LI><B> Reformat: </B>
<BR> You can reformat any 3 slice in any arbitrary orientation or define a new axial,sagittal or coronal orientation.
<BR> To do that, create and select 3 fiducials that will define the new
orientation plane of the slice (To see how to create/select Fiducials, press the 'How do I create Fiducials?' button when you are in the reformat panel)
<BR>Once 3 Fiducials are selected, press the 'reformat plane' button and the active slice will now have the new orientation.
<BR> If you would like to also define a rotation around the plane normal, create and select 2 fiducials that will define the alignment of the plane and press the 'rotate plane' button.
<BR> 
<BR> If you would like to save a reformatted volume: just select a volume, select the scan order and a location and click save. What this does is it saves new volume files that were created by 'slicing' the original volume with the plane defined in the scan order menu.

"
    regsub -all "\n" $help { } help
    MainHelpApplyTags Volumes $help
    MainHelpBuildGUI  Volumes

    #-------------------------------------------
    # Display frame
    #-------------------------------------------
    set fDisplay $Module(Volumes,fDisplay)
    set f $fDisplay

    # Frames
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fWinLvl    -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fThresh    -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fHistogram -bg $Gui(activeWorkspace)
    frame $f.fInterpolate -bg $Gui(activeWorkspace)
    pack $f.fActive $f.fWinLvl $f.fThresh $f.fHistogram $f.fInterpolate \
        -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Display->Active frame
    #-------------------------------------------
    set f $fDisplay.fActive

    eval {label $f.lActive -text "Active Volume: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m


    #-------------------------------------------
    # Display->WinLvl frame
    #-------------------------------------------
    set f $fDisplay.fWinLvl

    frame $f.fAuto    -bg $Gui(activeWorkspace)
    frame $f.fSliders -bg $Gui(activeWorkspace)
    pack $f.fAuto $f.fSliders -side top -fill x -expand 1

    #-------------------------------------------
    # Display->WinLvl->Auto frame
    #-------------------------------------------
    set f $fDisplay.fWinLvl.fAuto

    DevAddLabel $f.lAuto "Window/Level:"
    frame $f.fAuto -bg $Gui(activeWorkspace)
    pack $f.lAuto $f.fAuto -side left -padx $Gui(pad)  -pady $Gui(pad) -fill x

    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable Volume(autoWindowLevel) \
            -command "MainVolumesSetParam AutoWindowLevel; MainVolumesRender"} $Gui(WCA)
        pack $f.fAuto.rAuto$value -side left -fill x
    }

    #-------------------------------------------
    # Display->WinLvl->Sliders frame
    #-------------------------------------------
    set f $fDisplay.fWinLvl.fSliders

    foreach slider "Window Level" text "Win Lev" {
        DevAddLabel $f.l${slider} "$text:"
        eval {entry $f.e${slider} -width 6 \
            -textvariable Volume([Uncap ${slider}])} $Gui(WEA)
        bind $f.e${slider} <Return>   \
            "MainVolumesSetParam ${slider}; MainVolumesRender"
        bind $f.e${slider} <FocusOut> \
            "MainVolumesSetParam ${slider}; MainVolumesRender"
        eval {scale $f.s${slider} -from 1 -to 700 -length 140\
            -variable Volume([Uncap ${slider}])  -resolution 1 \
            -command "MainVolumesSetParam ${slider}; MainVolumesRenderActive"} \
             $Gui(WSA) {-sliderlength 14}
        bind $f.s${slider} <Leave> "MainVolumesRender"
        grid $f.l${slider} $f.e${slider} $f.s${slider} -padx 2 -pady $Gui(pad) \
            -sticky news
    }
    # Append widgets to list that's refreshed in MainVolumesUpdateSliderRange
    lappend Volume(sWindowList) $f.sWindow
    lappend Volume(sLevelList)  $f.sLevel

    
    #-------------------------------------------
    # Display->Thresh frame
    #-------------------------------------------
    set f $fDisplay.fThresh

    frame $f.fAuto    -bg $Gui(activeWorkspace)
    frame $f.fSliders -bg $Gui(activeWorkspace)
    pack $f.fAuto $f.fSliders -side top  -fill x -expand 1

    #-------------------------------------------
    # Display->Thresh->Auto frame
    #-------------------------------------------
    set f $fDisplay.fThresh.fAuto

    DevAddLabel $f.lAuto "Threshold: "
    frame $f.fAuto -bg $Gui(activeWorkspace)
    pack $f.lAuto $f.fAuto -side left -pady $Gui(pad) -fill x

    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable Volume(autoThreshold) \
            -command "MainVolumesSetParam AutoThreshold; MainVolumesRender"} $Gui(WCA)
        pack $f.fAuto.rAuto$value -side left -fill x
    }
    eval {checkbutton $f.cApply \
        -text "Apply" -variable Volume(applyThreshold) \
        -command "MainVolumesSetParam ApplyThreshold; MainVolumesRender" -width 6 \
        -indicatoron 0} $Gui(WCA)
    pack $f.cApply -side left -padx $Gui(pad)

    #-------------------------------------------
    # Display->Thresh->Sliders frame
    #-------------------------------------------
    set f $fDisplay.fThresh.fSliders

    foreach slider "Lower Upper" text "Lo Hi" {
        DevAddLabel $f.l${slider} "$text:"
        eval {entry $f.e${slider} -width 6 \
            -textvariable Volume([Uncap ${slider}]Threshold)} $Gui(WEA)
            bind $f.e${slider} <Return>   \
                "MainVolumesSetParam ${slider}Threshold; MainVolumesRender"
            bind $f.e${slider} <FocusOut> \
                "MainVolumesSetParam ${slider}Threshold; MainVolumesRender"
        eval {scale $f.s${slider} -from 1 -to 700 -length 140 \
            -variable Volume([Uncap ${slider}]Threshold)  -resolution 1 \
            -command "MainVolumesSetParam ${slider}Threshold; MainVolumesRender"} \
            $Gui(WSA) {-sliderlength 14}
        grid $f.l${slider} $f.e${slider} $f.s${slider} -padx 2 -pady $Gui(pad) \
            -sticky news
    }
    # Append widgets to list that's refreshed in MainVolumesUpdateSliderRange
    lappend Volume(sLevelList) $f.sLower
    lappend Volume(sLevelList) $f.sUpper


    #-------------------------------------------
    # Display->Histogram frame
    #-------------------------------------------
    set f $fDisplay.fHistogram

    frame $f.fHistBorder -bg $Gui(activeWorkspace) -relief sunken -bd 2
    frame $f.fLut -bg $Gui(activeWorkspace)
    pack $f.fLut $f.fHistBorder -side left -padx $Gui(pad) -pady $Gui(pad)
    
    #-------------------------------------------
    # Display->Histogram->Lut frame
    #-------------------------------------------
    set f $fDisplay.fHistogram.fLut

    DevAddLabel $f.lLUT "Palette:"
    eval {menubutton $f.mbLUT \
        -text "$Lut([lindex $Lut(idList) 0],name)" \
            -relief raised -bd 2 -width 9 \
        -menu $f.mbLUT.menu} $Gui(WMBA)
        eval {menu $f.mbLUT.menu} $Gui(WMA)
        # Add menu items
        foreach l $Lut(idList) {
            $f.mbLUT.menu add command -label $Lut($l,name) \
                -command "MainVolumesSetParam LutID $l; MainVolumesRender"
        }
        set Volume(mbLUT) $f.mbLUT

    pack $f.lLUT $f.mbLUT -pady $Gui(pad) -side top

    #-------------------------------------------
    # Display->Histogram->HistBorder frame
    #-------------------------------------------
    set f $fDisplay.fHistogram.fHistBorder

    if {$Volume(histogram) == "On"} {
        MakeVTKImageWindow hist
        histMapper SetInput [Volume(0,vol) GetHistogramPlot]

        vtkTkRenderWidget $f.fHist -rw histWin \
            -width $Volume(histWidth) -height $Volume(histHeight)  
        bind $f.fHist <Expose> {ExposeTkImageViewer %W %x %y %w %h}
        pack $f.fHist
    }

    #-------------------------------------------
    # Display->Interpolate frame
    #-------------------------------------------
    set f $fDisplay.fInterpolate

    DevAddLabel $f.lInterpolate "Interpolation:"
    pack $f.lInterpolate -pady $Gui(pad) -padx $Gui(pad) -side left -fill x

    foreach value "1 0" text "On Off" width "4 4" {
        eval {radiobutton $f.rInterp$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable Volume(interpolate) \
            -command "MainVolumesSetParam Interpolate; MainVolumesRender"} $Gui(WCA)
        pack $f.rInterp$value -side left -fill x
    }


    #-------------------------------------------
    # Props frame
    #-------------------------------------------
    set fProps $Module(Volumes,fProps)
    set f $fProps

    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fBot -bg $Gui(activeWorkspace) -height 310
    pack $f.fTop $f.fBot -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Props->Bot frame
    #-------------------------------------------
    set f $fProps.fBot

    # Make a frame for each reader submodule
    foreach m $Volume(readerModules,idList) {
        frame $f.f${m} -bg $Gui(activeWorkspace)
        place $f.f${m} -in $f -relheight 1.0 -relwidth 1.0

        set Volume(f$m) $f.f${m}
    }
    # raise the default one 
    raise $Volume(f$Volume(defaultFileFormat))

    #-------------------------------------------
    # Props->Top frame
    #-------------------------------------------
    set f $fProps.fTop

    frame $f.fActive -bg $Gui(backdrop)
    frame $f.fType   -bg $Gui(backdrop)
    pack $f.fActive $f.fType -side top -fill x -pady $Gui(pad) -padx $Gui(pad)

    #-------------------------------------------
    # Props->Top->Active frame
    #-------------------------------------------
    set f $fProps.fTop.fActive

    eval {label $f.lActive -text "Active Volume: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Props->Top->Type frame
    #-------------------------------------------
    set f $fProps.fTop.fType

    # Build pulldown menu for volume properties
    eval {label $f.l -text "Properties:"} $Gui(BLA)
    frame $f.f -bg $Gui(backdrop)
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    eval {menubutton $f.mbType -text \
            $Volume(readerModules,$Volume(propertyType),name) \
            -relief raised -bd 2 -width 20 \
            -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    pack  $f.mbType -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach m $Volume(readerModules,idList)  {
        $f.mbType.m add command -label $Volume(readerModules,$m,name) \
                -command "VolumesSetPropertyType $m"
    }
    # save menubutton for config
    set Volume(gui,mbPropertyType) $f.mbType
    # put a tooltip over the menu
    TooltipAdd $f.mbType \
            "Choose the type of file information to display."

    #-------------------------------------------
    # Various Reader types frames
    #-------------------------------------------
    
    foreach m $Volume(readerModules,idList) {
        # If it has a procedure for building the GUI
        if {[info command $Volume(readerModules,$m,procGUI)] != ""} {
            # then call it
            if {$Module(verbose) == 1} {
                puts "VolumesBuildGUI calling: $Volume(readerModules,$m,procGUI)"
            }
            $Volume(readerModules,$m,procGUI) $Volume(f$m)
        }
    }
        
if {0} { 
    #-------------------------------------------
    # Reformat frame
    #-------------------------------------------
    set fReformat $Module(Volumes,fReformat)
    set f $fReformat

    # binding stuff to create a fiducials list
    
    
    
    foreach frame "Active ReOrient Save" {
        set f $fReformat.f$frame
        frame $f -bg $Gui(activeWorkspace) -relief groove -bd 3
        pack $f -side top -pady 0
    }
    
    set f $fReformat.fActive

    eval {label $f.lActive -text "Active Slice:"} $Gui(WLA)
    pack $f.lActive -side left -pady $Gui(pad) -padx $Gui(pad) -fill x
    
    foreach s $Slice(idList) text "Red Yellow Green" width "4 7 6" {
        eval {radiobutton $f.r$s -width $width -indicatoron 0\
                  -text "$text" -value "$s" -variable Slice(activeID) \
                  -command "MainSlicesSetActive"} $Gui(WCA) {-selectcolor $Gui(slice$s)}
        pack $f.r$s -side left -fill x -anchor e
    }

    set f $fReformat.fReOrient
    foreach frame "top middle1 middle2 bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace) 
        pack $f.f$frame -side top -pady 1
    }
    set f $fReformat.fReOrient.ftop


    eval {label $f.lintro -text "You can reformat the active slice by using fiducial points: " -wraplength 180} $Gui(WLA)
    eval {button $f.bintro -text "How ?" } $Gui(WBA)
    TooltipAdd $f.bintro "To reformat the volume, you need to specify which orientation you are going to re-define: ReformatAxial, ReformatSagittal, ReformatCoronal or newOrient. 

For the first three orientations (axial,sagittal,coronal), once you defined the new orientation, the other 2 orientation planes are automatically computed to be orthogonal to the plane you re-defined. 
To see the 3 slices in their Reformat orientation, select 'ReformatAxiSagCor' on the dropdown menu 'Or:' on one of the slice panel.  

The last orientation (NewOrient) does not have any effect on any other orientation and each slice can have an arbitray NewOrient orientation. 
To see the active slice in its NewOrient orientation, select 'NewOrient' on the dropdown menu of orientations for that slice.

To define a new plane orientation, you need to:
1. select the orientation that you want to redefine with the drop down menu
2. create and select 3 fiducials and then press the 'reformat plane' button
=> you have now defined a new orientation for your volume
3. to define a new RL line for the axial or coronal, or a new PA line for the sagittal or newOrient orientation, 
you need to create and select 2 fiducials and then press the 'define new axis' button"
    
    pack $f.lintro $f.bintro -side left -padx 0 -pady $Gui(pad)
    
    set f $fReformat.fReOrient.fmiddle1 
    eval {label $f.lOr -text "Redefine plane:"} $Gui(WLA)
    
    
    set Volumes(reformat,orientation) "ReformatSagittal"
    set Volumes(reformat,ReformatSagittalAxis) "PA"
    set Volumes(reformat,ReformatAxialAxis) "RL"
    set Volumes(reformat,ReformatCoronalAxis) "RL"
    set Volumes(reformat,NewOrientAxis) "PA"


    
    eval {menubutton $f.mbActive -text "CHOOSE" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    set Volumes(reformat,orMenu) $f.mbActive.m
    set Volumes(reformat,orMenuB) $f.mbActive
    pack $f.lOr  $f.mbActive -side left -padx $Gui(pad) -pady 0 
    # Append widgets to list that gets refreshed during UpdateMRML
    $Volumes(reformat,orMenu) add command -label "ReformatAxial" \
        -command "VolumesSetReformatOrientation ReformatAxial"
    $Volumes(reformat,orMenu) add command -label "ReformatSagittal" \
        -command "VolumesSetReformatOrientation ReformatSagittal"
    $Volumes(reformat,orMenu) add command -label "ReformatCoronal" \
        -command "VolumesSetReformatOrientation ReformatCoronal"
    $Volumes(reformat,orMenu) add command -label "NewOrient" \
        -command "VolumesSetReformatOrientation NewOrient"
    
   
 
    set f $fReformat.fReOrient.fmiddle2
    FiducialsAddActiveListFrame $f 7 25 reformat
    
    set f $fReformat.fReOrient.fbottom
    eval {button $f.bref -text "$Volumes(reformat,orientation) Plane" -command "VolumesReformatSlicePlane $Volumes(reformat,orientation)"} $Gui(WBA)
    eval {button $f.brot -text "Define new $Volumes(reformat,$Volumes(reformat,orientation)Axis) axis" -command "VolumesRotateSlicePlane $Volumes(reformat,orientation)"} $Gui(WBA)
    pack $f.bref $f.brot -side left -padx $Gui(pad)
    set Volumes(reformat,planeButton)  $f.bref
    set Volumes(reformat,axisButton)  $f.brot

    set f $fReformat.fSave.fChoose
    frame $f
    pack $f

    # Volume menu
    DevAddSelectButton  Volume $f VolumeSelect "Choose Volume:" Pack \
        "Volume to save." 14

    # bind menubutton to update stuff when volume changes.
    bindtags $Volume(mVolumeSelect) [list Menu \
        $Volume(mVolumeSelect) all]
    
    # Append menu and button to lists that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbVolumeSelect
    lappend Volume(mActiveList) $f.mbVolumeSelect.m
    
    

    set f $fReformat.fSave.fScanOrder
    frame $f
    pack $f
    
    eval {label $f.lOrient -text "Choose a scan order:"} $Gui(WLA)
    
    # This slice
    eval {menubutton $f.mbOrient -text CHOOSE -menu $f.mbOrient.m \
        -width 13} $Gui(WMBA)
    pack $f.lOrient $f.mbOrient -side left -pady 0 -padx 2 -fill x

    # Choose scan order to save it in
    eval {menu $f.mbOrient.m} $Gui(WMA)
    foreach item "[Slicer GetOrientList]" {
    $f.mbOrient.m add command -label $item -command \
        "set Volumes(reformat,saveOrder) $item; $f.mbOrient config -text $item"
    }
    set Volumes(reformat,saveMenu) $f.mbOrient.m 

    #-------------------------------------------
    # Volumes->TabbedFrame->File->Vol->Prefix
    #-------------------------------------------

    set f $fReformat.fSave.fPrefix
    frame $f
    pack $f
    
    eval {label $f.l -text "Filename Prefix:"} $Gui(WLA)
    eval {entry $f.e -textvariable Volume(prefixSave)} $Gui(WEA)
    TooltipAdd $f.e "To save the Volume, enter the prefix here or just click Save."
    pack $f.l -padx 3 -side left
    pack $f.e -padx 3 -side left -expand 1 -fill x
    
    #-------------------------------------------
    # Volumes->TabbedFrame->File->Vol->Btns
    #-------------------------------------------
    set f $fReformat.fSave.fSave
    frame $f
    pack $f
    
    eval {button $f.bWrite -text "Save" -width 5 \
        -command "VolumesReformatSave"} $Gui(WBA)
    TooltipAdd $f.bWrite "Save the Volume."
    pack $f.bWrite
}
# end of commenting out the reformat pane

    #-------------------------------------------
    # Export frame
    #-------------------------------------------
    set fExport $Module(Volumes,fExport)
    set f $fExport

    # Frames
    frame $f.fActive -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fCORFile -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fGenericFile -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fGenericFile.fType -bg $Gui(activeWorkspace) -relief flat
    frame $f.fGenericFile.fCompression -bg $Gui(activeWorkspace) -relief flat

    pack $f.fActive -side top -pady $Gui(pad) -padx $Gui(pad)
    pack $f.fGenericFile  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x -expand true
    pack $f.fGenericFile.fType  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x -expand true
    pack $f.fGenericFile.fCompression  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x -expand true
    pack $f.fCORFile  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x   
    eval {label $fExport.ll -text "Export COR Format\nWarning: only 1mm 256 cubed\n8 bit images supported"} $Gui(WLA)   
    pack  $fExport.ll -side top -padx $Gui(pad) 

    #-------------------------------------------
    # Export->Active frame
    #-------------------------------------------
    set f $fExport.fActive

    eval {label $f.lActive -text "Active Volume: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m


    #-------------------------------------------
    # Export->GenericFilename frame
    #-------------------------------------------

    set f $fExport.fGenericFile

    eval {button $f.bWrite -text "Save" -width 5 \
        -command "VolumesGenericExport"} $Gui(WBA)
    TooltipAdd $f.bWrite "Save the Volume."
    pack  $f.bWrite -side bottom -padx $Gui(pad)    

    set Volumes(extentionGenericSave) nhdr

    DevAddFileBrowse $f Volumes "prefixGenericSave" "Select Export File:" "" "\$Volumes(extentionGenericSave)" "\$Volume(DefaultDir)" "Save" "Browse for a Nrrd file" "Browse for a file location (will save image file and .nhdr file to directory)" "Absolute"
    ## compression option (hint)

    set f $fExport.fGenericFile.fCompression

    eval {label $f.lcomp -text "Use Compression"} $Gui(BLA)
    pack $f.lcomp -side left -padx $Gui(pad) -pady 0
    foreach value "1 0" text "On Off" width "2 3" {
        eval {radiobutton $f.rComp$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable Volume(UseCompression) \
            } $Gui(WCA)
        pack $f.rComp$value -side left -fill x
    }
    TooltipAdd $f.rComp1 \
            "Suggest to the Writer to compress the file if the format supports it."
    TooltipAdd $f.rComp0 \
            "Don't compress the file, even if the format supports it."


    set f $fExport.fGenericFile.fType
    eval {label $f.l -text "Select File Type"} $Gui(BLA)
    pack $f.l -side left -padx $Gui(pad) -pady 0

    set Volumes(extentionGenericSave) nhdr

    eval {menubutton $f.mbType -text "NRRD(.nhdr)" \
            -relief raised -bd 2 -width 20 \
            -menu $f.mbType.m} $Gui(WMBA) 
    eval {menu $f.mbType.m} $Gui(WMA)
    pack  $f.mbType -side left -padx $Gui(pad) -pady 1

   # Add menu items
   # Saving of nifti extentions .img and .img.gz doesn't work right now. For the extention .img itk defers to analyze.
   # Saving of nifti extention .img.gz is not supported yet by itk.
     foreach FileType {{hdr} {nrrd} {nhdr} {mhd} {mha} {nii} {nii.gz} {vtk}} \
        name {{"Analyze (.hdr)"} {"NRRD(.nrrd)"} {"NRRD(.nhdr)"} {"Meta (.mhd)"} {"Meta (.mha)"} {"Nifti (.nii)"} {"Nifti (.nii.gz)"} {"VTK (.vtk)"}} { 
            set Volumes($FileType) $name 
            $f.mbType.m add command -label $name \
                -command "VolumesGenericExportSetFileType $FileType"
        }
    # save menubutton for config
    set Volume(gui,mbSaveFileType) $f.mbType
    # put a tooltip over the menu
    TooltipAdd $f.mbType \
            "Choose file type."

     #-------------------------------------------   
     # Export->CORFilename frame   
     #-------------------------------------------   
    
     set f $fExport.fCORFile   
    
     eval {button $f.bWrite -text "Save" -width 5 \
         -command "VolumesCORExport"} $Gui(WBA)   
     TooltipAdd $f.bWrite "Save the Volume."   
     pack  $f.bWrite -side bottom -padx $Gui(pad)   
    
     DevAddFileBrowse $f Volumes "prefixCORSave" "COR File:" "" "info" "\$Volume(DefaultDir)" "Save" "Browse for a COR file location (will save images and COR-.info file to directory)" "Absolute"   
  

    #-------------------------------------------
    # Other frame
    #-------------------------------------------
    set fOther $Module(Volumes,fOther)
    set f $fOther

    # Frames
    frame $f.fActive -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fRange  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fLabelOutline -bg $Gui(activeWorkspace) -relief groove -bd 3

    pack $f.fActive -side top -pady $Gui(pad) -padx $Gui(pad)
    pack $f.fRange  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    pack $f.fLabelOutline  -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Other->Active frame
    #-------------------------------------------
    set f $fOther.fActive

    eval {label $f.lActive -text "Active Volume: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -pady $Gui(pad) -padx $Gui(pad)

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList)  $f.mbActive.m


    #-------------------------------------------
    # Other->Range frame
    #-------------------------------------------
    set f $fOther.fRange

    frame $f.fAuto    -bg $Gui(activeWorkspace)
    frame $f.fSliders -bg $Gui(activeWorkspace)
    pack $f.fAuto -pady $Gui(pad) -side top -fill x -expand 1
    pack $f.fSliders -side top -fill x -expand 1

    #-------------------------------------------
    # Other->Range->Auto frame
    #-------------------------------------------
    set f $fOther.fRange.fAuto

    eval {label $f.lAuto -text "Slider Range:"} $Gui(WLA)
    frame $f.fAuto -bg $Gui(activeWorkspace)
    pack $f.lAuto $f.fAuto -side left -pady $Gui(pad) -padx $Gui(pad) -fill x

    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable Volume(rangeAuto) \
            -command "MainVolumesSetParam RangeAuto; MainVolumesRender"} $Gui(WCA)
        pack $f.fAuto.rAuto$value -side left -fill x
    }

    #-------------------------------------------
    # Other->Range->Sliders frame
    #-------------------------------------------
    set f $fOther.fRange.fSliders

    foreach slider "Low High" {
        eval {label $f.l${slider} -text "${slider}:"} $Gui(WLA)
        eval {entry $f.e${slider} -width 7 \
            -textvariable Volume(range${slider})} $Gui(WEA)
        bind $f.e${slider} <Return>   \
            "MainVolumesSetParam Range${slider}; MainVolumesRender"
        bind $f.e${slider} <FocusOut> \
            "MainVolumesSetParam Range${slider}; MainVolumesRender"
        grid $f.l${slider} $f.e${slider}  -padx 2 -pady $Gui(pad) -sticky w
    }

    #-------------------------------------------
    # Other->LabelOutline frame
    #-------------------------------------------
    set f $fOther.fLabelOutline

    DevAddButton $f.bCreateLabelVolume "Create New Label Outline Volume" "VolumesCreateNewLabelOutline"
    TooltipAdd $f.bCreateLabelVolume "Copies active volume (must be a labelmap) and then filters it to outlines only"
    pack $f.bCreateLabelVolume
}

#-------------------------------------------------------------------------------
# .PROC VolumesCheckForManualChanges
# 
# This Procedure is called to see if any important properties
# were changed that might require re-reading the volume.
#
# .ARGS
#  int n is id of the vtkMrmlVolumeNode to edit.
# .END
#-------------------------------------------------------------------------------
proc VolumesCheckForManualChanges {n} {
    global Lut Volume Label Module Mrml

    if { !$Volume(isDICOM)} {
        if {[$n GetFilePrefix] != [file root $Volume(firstFile)] } { 
            return 1 
        }
        set firstNum [MainFileFindImageNumber First [file join $Mrml(dir) $Volume(firstFile)]]
        if {[lindex [$n GetImageRange] 0 ]  != $firstNum }  { return 1 }
        if {[lindex [$n GetImageRange] 1 ]  != $Volume(lastNum) } { return 1 }
        if {[$n GetLabelMap] != $Volume(labelMap)} { return 1 }
        if {[$n GetFilePattern] != $Volume(filePattern) } { return 1 }
        if {[lindex [$n GetDimensions] 1 ]  != $Volume(height) } { return 1 }
        if {[lindex [$n GetDimensions] 0 ]  != $Volume(width) } { return 1 }
        if {[$n GetScanOrder] != $Volume(scanOrder)} { return 1 }
        if {[$n GetScalarTypeAsString] != $Volume(scalarType)} { return 1 }
        if {[$n GetNumScalars] != $Volume(numScalars)} { return 1 }
        if {[$n GetLittleEndian] != $Volume(littleEndian)} { return 1 }
        if {[lindex [$n GetSpacing] 0 ]  != $Volume(pixelWidth) } { return 1 }
        if {[lindex [$n GetSpacing] 1 ]  != $Volume(pixelHeight) } { return 1 }
        if {[lindex [$n GetSpacing] 2 ]  != $Volume(sliceThickness) } { return 1 }
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC VolumesManualSetPropertyType
# 
# Sets all necessary info into a vtkMrmlVolumeNode.<br>
#
# This procedure is called when manually setting the properties
# to read in a volume.
#
# .ARGS
#  int n is id of the vtkMrmlVolumeNode to edit.
# .END
#-------------------------------------------------------------------------------
proc VolumesManualSetPropertyType {n} {
    global Lut Volume Label Module Mrml

    # These get set down below, but we need them before MainUpdateMRML
    # parse out the filename
    set parsing [MainFileParseImageFile $Volume(firstFile) 0]

    #    $n SetFilePrefix [file root $Volume(firstFile)]
    if {$::Module(verbose)} {
        puts "Volumes.tcl: VolumesManualSetPropertyType: setting file prefix to [lindex $parsing 1]"
        DevInfoWindow "Volumes.tcl: VolumesManualSetPropertyType: setting file prefix to [lindex $parsing 1]"
    }
    $n SetFilePrefix [lindex $parsing 1]

    # this check should be obsolete now
    if {[$n GetFilePrefix] == $Volume(firstFile)} {
        # file root didn't work in this case, trim the right hand numerals
        set tmpPrefix [string trimright $Volume(firstFile) 0123456789]
        # now take the assumed single separater character off of the end as well (works with more than one instance, ie if have --)
        if {$Module(verbose)} {
            puts "Volumes.tcl: VolumesManualSetPropertyType: setting file prefix to  [string trimright $tmpPrefix [string index $tmpPrefix end]]"
        }
        $n SetFilePrefix [string trimright $tmpPrefix [string index $tmpPrefix end]]
    }
    #    $n SetFilePattern $Volume(filePattern)
    $n SetFilePattern [lindex $parsing 0]

    if {$::Module(verbose)} {
        puts "VolumesManualSetPropertyType: setting full prefix from mrml dir ($Mrml(dir)) and file prefix ([$n GetFilePrefix]) to [file join $Mrml(dir) [$n GetFilePrefix]]"
    }

    # Generic reader uses FilePrefix so don't reset it
    if {[$n GetFileType] != "Generic"} {
        $n SetFullPrefix [file join $Mrml(dir) [$n GetFilePrefix]]
    }
    if { !$Volume(isDICOM) } {
        set firstNum [MainFileFindImageNumber First [file join $Mrml(dir) $Volume(firstFile)]]
        if {$firstNum ==""} {
            set firstNum 1
        }
    } else {
        set firstNum 1
    }
    # can get this from the parsed out file name
    #    set firstNum [lindex $parsing 2]
    set filePostfix [lindex $parsing 3]

    $n SetImageRange $firstNum $Volume(lastNum)
    $n SetDimensions $Volume(width) $Volume(height)
    eval $n SetSpacing $Volume(pixelWidth) $Volume(pixelHeight) \
        [expr $Volume(sliceSpacing) + $Volume(sliceThickness)]
    $n SetScalarTypeTo$Volume(scalarType)
    $n SetNumScalars $Volume(numScalars)
    $n SetLittleEndian $Volume(littleEndian)
    $n SetTilt $Volume(gantryDetectorTilt)
    $n ComputeRasToIjkFromScanOrder $Volume(scanOrder)

}


#-------------------------------------------------------------------------------
# .PROC VolumesAutomaticSetPropertyType
# 
# Sets all necessary info into a vtkMrmlVolumeNode.<br>
#
# This procedure is called when reading the header of a volume
# to get the header information. Returns 1 on success.
#
# .ARGS
#  int n is the id of the vtkMrmlVolumeNode to edit.
# .END
#-------------------------------------------------------------------------------
proc VolumesAutomaticSetPropertyType {n} {
    global Lut Volume Label Module Mrml

    set errmsg [GetHeaderInfo [file join $Mrml(dir) $Volume(firstFile)] \
                    $Volume(lastNum) $n 1]
    if {$errmsg == "-1"} {
        set msg "No header information found. Please enter header info manually."
        puts $msg
        DevErrorWindow $msg
        # set readHeaders to manual
        set Volume(readHeaders) 0
        # switch to vols->props->header frame
        VolumesSetPropertyType VolHeader
        # Remove node
        MainMrmlUndoAddNode Volume $n
        return 0
    } elseif {$errmsg != ""} {
        # File not found, most likely
        puts $errmsg
        DevErrorWindow $errmsg
        # Remove node
        MainMrmlUndoAddNode Volume $n
        return 0
    }
    return 1
}

#-------------------------------------------------------------------------------
# .PROC VolumesSetPropertyType
# Switch the visible volumes->props GUI.  Either
# Basic, Header, or DICOM
# .ARGS
# str type Basic, Header, or DICOM
# .END
#-------------------------------------------------------------------------------
proc VolumesSetPropertyType {type} {
    global Volume
    
    set Volume(propertyType) $type

    # configure menubutton
    set name $Volume(readerModules,$Volume(propertyType),name)
    $Volume(gui,mbPropertyType) config -text $name

    raise $Volume(f$Volume(propertyType))
    focus $Volume(f$Volume(propertyType))
}

#-------------------------------------------------------------------------------
# .PROC VolumesPropsApply
# Called from Volumes->Props GUI's apply button.<br>
# Updates volume properties and calls update MRML.<br>
# If volume is NEW, causes volume to be read in.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesPropsApply {} {
    global Lut Volume Label Module Mrml View

    set m $Volume(activeID)
    if {$m == ""} {
        DevErrorWindow "VolumesPropsApply: no active volume"
        return
    }
    if {$::Module(verbose)} {
        puts "VolumesPropsApply: active id = $m"
    }

    set Volume(isDICOM) [expr [llength $Volume(dICOMFileList)] > 0]
    
    # Validate name
    if {$Volume(name) == ""} {
        DevErrorWindow "Please enter a name that will allow you to distinguish this volume."
        return
    }
    if {[ValidateName $Volume(name)] == 0} {
        DevErrorWindow "The name can consist of letters, digits, dashes, or underscores.\nName \"$Volume(name)\" not valid."
        return
    }

    # first file
    # Generic reader does not need first file, it uses FilePrefix 
    if {[file exists $Volume(firstFile)] == 0 &&  $m != "NEW" && [Volume($m,node) GetFileType] != "Generic" } {
        DevErrorWindow "The first file $Volume(firstFile) must exist, if you haven't saved a newly created volume, please press cancel and then go to the Editor Module, Volumes tab, Save button"
        return
    }

    # lastNum
    if { $Volume(isDICOM) == 0 } {
        if {[ValidateInt $Volume(lastNum)] == 0} {
            DevErrorWindow "The last number must be an integer."
            return
        }
    }
    # resolution
    if {[ValidateInt $Volume(width)] == 0} {
        DevErrorWindow "The width must be an integer."
        return
    }
    if {[ValidateInt $Volume(height)] == 0} {
        DevErrorWindow "The height must be an integer."
        return
    }
    # pixel size
    if {[ValidateFloat $Volume(pixelWidth)] == 0} {
        DevErrorWindow "The pixel size must be a number."
        return
    }
    if {[ValidateFloat $Volume(pixelHeight)] == 0} {
        DevErrorWindow "The pixel size must be a number."
        return
    }

    # slice thickness
    if {[ValidateFloat $Volume(sliceThickness)] == 0} {
        DevErrorWindow "The slice thickness must be a number."
        return
    }
    # slice spacing
    if {[ValidateFloat $Volume(sliceSpacing)] == 0} {
        DevErrorWindow "The slice spacing must be a number."
        return
    }
    # tilt
    if {[ValidateFloat $Volume(gantryDetectorTilt)] == 0} {
        DevErrorWindow "The tilt must be a number."
        return
    }
    # num scalars
    if {[ValidateInt $Volume(numScalars)] == 0} {
        DevErrorWindow "The number of scalars must be an integer."
        return
    }

    if { $Volume(isDICOM) } {
        set Volume(readHeaders) 0
    }

    # Manual headers
    if {$Volume(readHeaders) == "0"} {
        # if on basic frame, switch to header frame.
        if {$Volume(propertyType) != "VolHeader"} {
            VolumesSetPropertyType VolHeader
            return
        }
    }

    # if the volume is NEW we may read it in...
    if {$m == "NEW"} {

        # add a MRML node for this volume (so that in UpdateMRML we can read it in according to the path, etc. in the node)
        set n [MainMrmlAddNode Volume]
        set newID [$n GetID]

        # determine file type
        if {[info exists Volume(fileType)]} {
            Volume($newID,node) SetFileType $Volume(fileType)
        }

        # Added by Attila Tanacs 10/11/2000 1/4/02

        $n DeleteDICOMFileNames
        $n DeleteDICOMMultiFrameOffsets
        for  {set j 0} {$j < [llength $Volume(dICOMFileList)]} {incr j} {
            $n AddDICOMFileName [$Volume(dICOMFileListbox) get $j]
        }
        
        if { $Volume(isDICOM) } {
            #$Volume(dICOMFileListbox) insert 0 [$n GetNumberOfDICOMFiles];
            set firstNum 1
            if {$Volume(DICOMMultiFrameFile) == "0"} {
                set Volume(lastNum) [llength $Volume(dICOMFileList)]
            } else {
                set Volume(lastNum) $Volume(DICOMMultiFrameFile)
                for {set j 0} {$j < $Volume(lastNum)} {incr j} {
                    $n AddDICOMMultiFrameOffset [lindex $Volume(DICOMSliceOffsets) $j]
                }
            }
        }        

        # End of Part added by Attila Tanacs

        # Fill in header information for reading the volume
        # Manual headers
        if {$Volume(readHeaders) == "0"} {
            # These setting are set down below, 
            # but we need them before MainUpdateMRML
            
            VolumesManualSetPropertyType $n
        } else {
            # Read headers
            if {[VolumesAutomaticSetPropertyType $n] == 0} {
                return
            }
        }
        # end Read Headers

        $n SetName $Volume(name)
        $n SetDescription $Volume(desc)
        $n SetLabelMap $Volume(labelMap)

        MainUpdateMRML
        # If failed, then it's no longer in the idList
        if {[lsearch $Volume(idList) $newID] == -1} {
            return
        }

        # allow use of other module GUIs
        set Volume(freeze) 0

        # set active volume on all menus
        MainVolumesSetActive $newID

        # save the ID for later in this proc
        set m $newID

        # if we are successful set the FOV for correct display of this volume
        # (check all dimensions and pix max - special cases for z for dicom, 
        # but since GE files haven't been parsed yet, no way to know their 
        # z extent yet.  TODO: fix GE z extent parsing)
        set fov 0
        for {set i 0} {$i < 2} {incr i} {
            set dim     [lindex [Volume($newID,node) GetDimensions] $i]
            set spacing [lindex [Volume($newID,node) GetSpacing] $i]
            set newfov     [expr $dim * $spacing]
            if { $newfov > $fov } {
                set fov $newfov
            }
        }
        set dim [llength $Volume(dICOMFileList)]
        if { $dim == 0 } {
            # do nothing for non-dicom because size isn't known yet
        } else {
            set spacing [lindex [Volume($newID,node) GetSpacing] 2]
            set newfov [expr $dim * $spacing]
            if { $newfov > $fov } {
                set fov $newfov
            }
        }
        # set View(fov) $fov
        MainViewSetFov "default" $fov

        # display the new volume in the background of all slices
        MainSlicesSetVolumeAll Back $newID
    } else {
        # End   if the Volume is NEW
        ## Maybe we would like to do a reread of the file?
        if {$m != $Volume(idNone) } {
            if {[VolumesCheckForManualChanges Volume($m,node)] == 1} {
                set ReRead [ DevYesNo "Reread the Image?" ]
                puts "ReRead"
                if {$ReRead == "yes"} {
                    set Volume(readHeaders) 0
                    if {$Volume(readHeaders) == "0"} {
                        # These setting are set down below, 
                        # but we need them before MainUpdateMRML

                        VolumesManualSetPropertyType  Volume($m,node)
                    } else {
                        # Read headers
                        if {[VolumesAutomaticSetPropertyType Volume($m,node)] == 0} {
                            return
                        }
                    }
                    if {[MainVolumesRead $m]<0 } {
                        DevErrorWindow "Error reading volume!"
                        return 0
                    }
                }
                # end if they chose to reread
            }
            # end if they should be asked to reread
        }
        # end if the volume id is not none.
    }
    # End thinking about rereading.


    # Update all fields that the user changed (not stuff that would 
    # need a file reread)
    
    Volume($m,node) SetName $Volume(name)
    Volume($m,node) SetDescription $Volume(desc)
    Volume($m,node) SetLabelMap $Volume(labelMap)
    eval Volume($m,node) SetSpacing $Volume(pixelWidth) $Volume(pixelHeight) \
        [expr $Volume(sliceSpacing) + $Volume(sliceThickness)]
    Volume($m,node) SetTilt $Volume(gantryDetectorTilt)
    
    # This line can't be allowed to overwrite a RasToIjk matrix made
    # from headers when the volume is first created.
    #
    if {$Volume(readHeaders) == "0"} {
        Volume($m,node) ComputeRasToIjkFromScanOrder $Volume(scanOrder)
    }

    # If tabs are frozen, then 
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
    
    # Update pipeline
    MainVolumesUpdate $m

    # Update MRML: this reads in new volumes, among other things
    MainUpdateMRML

    return $m
}

#-------------------------------------------------------------------------------
# .PROC VolumesPropsCancel
# Cancel: do not read in a new volume if in progress.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesPropsCancel {} {
    global Volume Module

    # Reset props
    set m $Volume(activeID)
    if {$m == "NEW"} {
        set m [lindex $Volume(idList) 0]
    }
    set Volume(freeze) 0
    MainVolumesSetActive $m

    # Unfreeze
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
}

#-------------------------------------------------------------------------------
# .PROC VolumesSetFirst
# 
# Called after the User Selects the first file of the volume.<br>
# Finds the filename, directory, and last image number.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesSetFirst {} {
    global Volume Mrml

    if {$::Module(verbose)} {
        puts "VolumesSetFirst: firstFile = $Volume(firstFile), Mrml(dir) = $Mrml(dir),\n calling  MainFileFindImageNumber Last with [file join $Mrml(dir) $Volume(firstFile)]"
    }
    # check to see if user cancelled and set filename to empty string
    if {$Volume(firstFile) == {} || $Volume(firstFile) == ""} {
        if { $::Module(verbose) } {
            puts "VolumesSetFirst: firstFile not set"
        }
        return
    }
    # check to see if user entered a non existant first file
    if {[file exists $Volume(firstFile)] == 0} {
        puts "VolumesSetFirst: first file does not exist: $Volume(firstFile)"
        DevErrorWindow "VolumesSetFirst: first file does not exist: $Volume(firstFile).\nSave the volume via Editor->Volumes->Save."
        return
    }
    set Volume(name)  [file root [file tail $Volume(firstFile)]]
    set Volume(DefaultDir) [file dirname [file join $Mrml(dir) $Volume(firstFile)]]
    # lastNum is an image number
    if { $::Volume(propertyType) == "VolBasic" } {
        set Volume(lastNum)  [MainFileFindImageNumber Last \
                                  [file join $Mrml(dir) $Volume(firstFile)]]
    }
}

#-------------------------------------------------------------------------------
# .PROC VolumesSetScanOrder
# Set scan order for active volume, configure menubutton.
# .ARGS
# str order a valid scan order
# .END
#-------------------------------------------------------------------------------
proc VolumesSetScanOrder {order} {
    global Volume

    set Volume(scanOrder) $order

    # set the button text to the matching order from the scanOrderMenu
    #raul (04/08/04): scanOrder is also set up in VolTensor.tcl. VolHeader.tcl 
    # and VolTensor have menubutton that share the same variables.
    foreach mbscanOrder $Volume(mbscanOrder) {
        $mbscanOrder config -text [lindex $Volume(scanOrderMenu)\
                                       [lsearch $Volume(scanOrderList) $order]]
    }
}

#-------------------------------------------------------------------------------
# .PROC VolumesSetScalarType
# Set scalar type and config menubutton to match.
# .ARGS
# str type a valid scalar type.
# .END
#-------------------------------------------------------------------------------
proc VolumesSetScalarType {type} {
    global Volume

    set Volume(scalarType) $type

    # update the button text
    $Volume(mbscalarType) config -text $type
}

#-------------------------------------------------------------------------------
# .PROC VolumesSetLast
# Sets last number and filename.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesSetLast {} {
    global Mrml Volume

    set Volume(lastNum) [MainFileFindImageNumber Last\
                             [file join $Mrml(dir) $Volume(firstFile)]]
    set Volume(name) [file root [file tail $Volume(firstFile)]]
}

#-------------------------------------------------------------------------------
# .PROC VolumesEnter
# Called when module is entered.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesEnter {} {
    global Volumes Fiducials
    # push the Fiducials event manager onto the events stack so that user 
    # can add Fiducials with keys/mouse
    pushEventManager $Fiducials(eventManager)
    pushEventManager $Volumes(eventManager)

    DataExit
    bind Listbox <Control-Button-1> {tkListboxBeginToggle %W [%W index @%x,%y]}
    #tk_messageBox -type ok -message "VolumesEnter" -title "Title" -icon  info
    #    $Volumes(reformat,orMenu) invoke "ReformatSagittal"
    #    $Volumes(reformat,saveMenu) invoke "ReformatCoronal"
}

#-------------------------------------------------------------------------------
# .PROC VolumesExit
# Called when module is exited.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesExit {} {
    global Volumes

    popEventManager
    #tk_messageBox -type ok -message "VolumesExit" -title "Title" -icon  info
}

# >> Presets

#-------------------------------------------------------------------------------
# .PROC VolumesStorePresets
# Store preset values for this module into global array
# .ARGS
# int p preset id
# .END
#-------------------------------------------------------------------------------
proc VolumesStorePresets {p} {
    global Preset Volumes

    set Preset(Volumes,$p,DICOMStartDir) $Volumes(DICOMStartDir)
    set Preset(Volumes,$p,FileNameSortParam) $Volumes(FileNameSortParam)
    set Preset(Volumes,$p,DICOMPreviewWidth) $Volumes(DICOMPreviewWidth)
    set Preset(Volumes,$p,DICOMPreviewHeight) $Volumes(DICOMPreviewHeight)
    set Preset(Volumes,$p,DICOMPreviewHighestValue) $Volumes(DICOMPreviewHighestValue)
    set Preset(Volumes,$p,DICOMDataDictFile) $Volumes(DICOMDataDictFile)
}

#-------------------------------------------------------------------------------
# .PROC VolumesRecallPresets
# Set preset values for this module from global array
# 
# .ARGS
# int p preset id
# .END
#-------------------------------------------------------------------------------
proc VolumesRecallPresets {p} {
    global Preset Volumes

    set Volumes(DICOMStartDir) $Preset(Volumes,$p,DICOMStartDir)
    set Volumes(FileNameSortParam) $Preset(Volumes,$p,FileNameSortParam)
    set Volumes(DICOMPreviewWidth) $Preset(Volumes,$p,DICOMPreviewWidth)
    set Volumes(DICOMPreviewHeight) $Preset(Volumes,$p,DICOMPreviewHeight)
    set Volumes(DICOMPreviewHighestValue) $Preset(Volumes,$p,DICOMPreviewHighestValue)
    set Volumes(DICOMDataDictFile) $Preset(Volumes,$p,DICOMDataDictFile)
}

#-------------------------------------------------------------------------------
# .PROC VolumesSetReformatOrientation
# This procedures changes the text of the buttons on the reformat panel based on the 
# current reformat orientation chosen by the user.
#
# .ARGS 
# str or the orientation string: either ReformatAxial, ReformatSagittal, ReformatCoronal, or NewOrient
# .END
#-------------------------------------------------------------------------------
proc VolumesSetReformatOrientation {or} {
    global Volumes 

    set Volumes(reformat,orientation) $or
    $Volumes(reformat,orMenuB) config -text $or
    $Volumes(reformat,planeButton) configure -text "$Volumes(reformat,orientation) Plane"
    $Volumes(reformat,axisButton) configure -text "Define new $Volumes(reformat,$Volumes(reformat,orientation)Axis) axis"

}

#-------------------------------------------------------------------------------
# .PROC VolumesProjectVectorOnPlane
# Given a Vector V defined by V1{xyz} and V2{xyz} and a plane defined by its
# coefficients {A,B,C,D}, return a vector P that is the projection of V onto the plane
# .ARGS 
# float A plane coefficient
# float B plane coefficient
# float C plane coefficient
# float D plane coefficient
# float V1x x coord of first vector
# float V1y y coord of first vector
# float V1z z coord of first vector
# float V2x x coord of second vector
# float V2y y coord of second vector
# float V2z z coord of second vector
# .END
#-------------------------------------------------------------------------------
proc VolumesProjectVectorOnPlane {A B C D V1x V1y V1z V2x V2y V2z} {

    global Volumes P1 P2

    # tang is in the direction of p2-p1
    
    set evaluateP1 [expr $P1(x)*$A + $P1(y)*$B + $P1(z)*$C + $D]
    set evaluateP2 [expr $P2(x)*$A + $P2(y)*$B + $P2(z)*$C + $D]
    set Norm [expr sqrt($A*$A + $B*$B + $C*$C)]
    
    # in case p2 and p1 are not on the plane
    set distp1 [expr abs($evaluateP1/$Norm)]
    set distp2 [expr abs($evaluateP2/$Norm)]
    
    # now define the unit normal to this plane
    set n(x) $A
    set n(y) $B
    set n(z) $C
    Normalize n

    # see if the point is under or over the plane to know which direction
    # to project it in
    set multiplier 1
    if {$evaluateP1 < 0} {
        set multiplier -1 
    } 
    set p1projx [expr $P1(x)  - ($multiplier * $distp1 * $n(x))] 
    set p1projy [expr $P1(y)  - ($multiplier * $distp1 * $n(y))]
    set p1projz [expr $P1(z) - ($multiplier * $distp1 * $n(z))]
    
    set multiplier 1
    if {$evaluateP2 < 0} {
        set multiplier -1 
    } 
    set p2projx [expr $P2(x)  - ($multiplier * $distp2 * $n(x))] 
    set p2projy [expr $P2(y)  - ($multiplier * $distp2 * $n(y))]
    set p2projz [expr $P2(z)  - ($multiplier * $distp2 * $n(z))]
    
    
    set Projection(x) [expr $p2projx - $p1projx]
    set Projection(y) [expr $p2projy - $p1projy]
    set Projection(z) [expr $p2projz - $p1projz]
    Normalize Projection
    return "$Projection(x) $Projection(y) $Projection(z)"    
}

#-------------------------------------------------------------------------------
# .PROC VolumesReformatSlicePlane
#  This procedure changes the reformat matrix of either the ReformatAxial, 
# ReformatSagittal,ReformatCoronal orientation or NewOrient. The new 
# orientation is the plane defined by the 3 selected Fiducials.<br>
# If the reformat orientation is either ReformatAxial, ReformatSagittal or 
# ReformatCoronal, then and the other 2 orthogonal orientations are also 
# calculated. This means that if the user decides to redefine the 
# ReformatAxial orientation, then the ReformatSagittal and ReformatCoronal 
# are automatically computed so that the 3 orientations are orthogonal.<br>
#
# If the reformat orientation is NewOrient, then it doesn't affect any other
# slice orientations.<br>
#
#  If there are more or less than 3 selected Fiducials, this procedure tells 
#  the user and is a no-op.
# .ARGS 
# str orientation has to be either reformatAxial, reformatSagittal, reformatCoronal or NewOrient
# .END
#-------------------------------------------------------------------------------
proc VolumesReformatSlicePlane {orientation} {
    global Volumes Fiducials Slice Slices P1 P2


    # first check that we are reading the right orientation
    if {$orientation != "ReformatAxial" && $orientation != "ReformatSagittal" && $orientation != "ReformatCoronal" && $orientation != "NewOrient"} {
        DevErrorWindow "The orientation $orientation is not a valid one"
        return;
    }
    
    # next check to see that only 3 fiducials are selected
    set list [FiducialsGetAllSelectedPointIdList]
    if { [llength $list] < 3 } {
        # give warning and exit
        DevErrorWindow "You have to create (p) and select (q) 3 fiducials.\nSelected fiducials are red."
        return
    } elseif { [llength $list] > 3 } {
        # give warning and exit
        DevErrorWindow "Please select only 3 fiducials"
        return
    } else {
        # get the 3 selected fiducial points coordinates
        set count 1
        foreach pid $list {
            set xyz [Point($pid,node) GetXYZ]
            set p${count}x [lindex $xyz 0]
            set p${count}y [lindex $xyz 1]
            set p${count}z [lindex $xyz 2]
            incr count
        }

        # 3D plane equation
        set N(x) [expr $p1y * ($p2z - $p3z) + $p2y * ($p3z-$p1z) + $p3y * ($p1z-$p2z)]
        set N(y) [expr $p1z * ($p2x - $p3x) + $p2z * ($p3x-$p1x) + $p3z * ($p1x-$p2x)]
        set N(z) [expr $p1x * ($p2y-$p3y) + $p2x * ($p3y - $p1y) + $p3x * ($p1y - $p2y)]
        set coef [expr -($p1x * (($p2y* $p3z) - ($p3y* $p2z)) + $p2x * (($p3y * $p1z) - ($p1y * $p3z)) + $p3x * (($p1y*$p2z) - ($p2y *$p1z)))]

        
        # save the reformat plane equation coefficients
        set s $Slice(activeID)
        set Slice($s,reformatPlaneCoeff,A) $N(x)
        set Slice($s,reformatPlaneCoeff,B) $N(y)
        set Slice($s,reformatPlaneCoeff,C) $N(z)
        set Slice($s,reformatPlaneCoeff,D) $coef
        
        Normalize N

        ######################################################################
        ##################### CASE AXIAL, SAGITTAL, CORONAL ##################
        ######################################################################
        
        if {$orientation != "NewOrient" } {
            # Step 1, make sure the normal is oriented the right way by taking its dot product with the original normal


            if {$orientation == "ReformatSagittal" } {
                set originalN(x) -1
                set originalN(y) 0
                set originalN(z) 0
                set P1(x) 0
                set P1(y) 1
                set P1(z) 0
                set P2(x) 0
                set P2(y) 0
                set P2(z) 0
            } elseif { $orientation == "ReformatAxial" } {
                set originalN(x) 0
                set originalN(y) 0
                set originalN(z) -1
                set P1(x) 1
                set P1(y) 0
                set P1(z) 0
                set P2(x) 0
                set P2(y) 0
                set P2(z) 0
            } elseif { $orientation == "ReformatCoronal" } {
                set originalN(x) 0
                set originalN(y) 1
                set originalN(z) 0
                set P1(x) 1
                set P1(y) 0
                set P1(z) 0
                set P2(x) 0
                set P2(y) 0
                set P2(z) 0
            }
            
            if {[expr $N(x)*$originalN(x) +  $N(y)*$originalN(y) +  $N(z)*$originalN(z)] <0 } {
                
                set N(x) [expr -$N(x)]
                set N(y) [expr -$N(y)]
                set N(z) [expr -$N(z)]
                set Slice($s,reformatPlaneCoeff,A) [expr -$Slice($s,reformatPlaneCoeff,A)]
                set Slice($s,reformatPlaneCoeff,B) [expr -$Slice($s,reformatPlaneCoeff,B)]
                set Slice($s,reformatPlaneCoeff,C) [expr -$Slice($s,reformatPlaneCoeff,C)]
                set Slice($s,reformatPlaneCoeff,D) [expr -$Slice($s,reformatPlaneCoeff,D)]
            }
            
            # get the distance from 0,0,0 to the plane
            set dist [expr -$Slice($s,reformatPlaneCoeff,D)/ sqrt($Slice($s,reformatPlaneCoeff,A)*$Slice($s,reformatPlaneCoeff,A)+ $Slice($s,reformatPlaneCoeff,B)*$Slice($s,reformatPlaneCoeff,B) + $Slice($s,reformatPlaneCoeff,C)*$Slice($s,reformatPlaneCoeff,C))]
            

            # Step 2, project the original tangent onto the plane
            set proj [VolumesProjectVectorOnPlane $Slice($s,reformatPlaneCoeff,A) $Slice($s,reformatPlaneCoeff,B) $Slice($s,reformatPlaneCoeff,C) $Slice($s,reformatPlaneCoeff,D) $P1(x) $P1(y) P1(z) $P2(x) $P2(y) $P2(z)]
            set T(x) [lindex $proj 0]
            set T(y) [lindex $proj 1]
            set T(z) [lindex $proj 2]
            
            
            # set the reformat matrix of the active slice, make the origin 0 by default.
            Slicer SetReformatNTP $orientation $N(x) $N(y) $N(z) $T(x) $T(y) $T(z) 0 0 0
            MainSlicesSetOrientAll "ReformatAxiSagCor"
        } else {
            
            ###################################################################
            ############################CASE NEW ORIENT  ######################
            ###################################################################
            # we are less smart about things, just take the 0 -1 0 vector and
            # project it onto the new plane to get a tangent 
            # 
            

            set P1(x) 0
            set P1(y) 1
            set P1(z) 0
            set P2(x) 0
            set P2(y) 0
            set P2(z) 0
            set T(x) [lindex $proj 0]
            set T(y) [lindex $proj 1]
            set T(z) [lindex $proj 2]
            Slicer SetNewOrientNTP $Slice(activeID) $N(x) $N(y) $N(z) $T(x) $T(y) $T(z) 0 0 0
            MainSlices SetOrient $Slice(activeID) "NewOrient"
        }
        # make all 3 slices show the new Reformat orientation

        MainSlicesSetOffset $Slice(activeID) $dist
        RenderAll
    }
}

#-------------------------------------------------------------------------------
# .PROC VolumesRotateSlicePlane
# Rotate the slice plane to line up with the plane formed by two selected fiducials.
# .ARGS
# str orientation has to be either reformatAxial, reformatSagittal, reformatCoronal or NewOrient
# .END
#-------------------------------------------------------------------------------
proc VolumesRotateSlicePlane {orientation} {
    global Volumes Slices Slice P1 P2
    
    # the tangent is in the direction of the selected 2 fiducials
    
    # first check to see that only 2 fiducials are selected
    set list [FiducialsGetAllSelectedPointIdList]
    if { [llength $list] < 2 } {
        # give warning and exit
        DevErrorWindow "You have to create and select 2 fiducials (they do not necessarily have to be on the reformated plane)"        
        return
    } elseif { [llength $list] > 2 } {
        # give warning and exit
        DevErrorWindow "Please select only 2 fiducials"
        return
    } else {
        # get the 2 points coordinates
        set count 1
        foreach pid $list {
            set xyz [Point($pid,node) GetXYZ]
            set temp${count}(x) [lindex $xyz 0]
            set temp${count}(y) [lindex $xyz 1]
            set temp${count}(z) [lindex $xyz 2]
            incr count
        }

        # if we want to define a new "RL" axis for the reformatted axial,
        # the first point needs to be the one closest to R, so with the 
        # highest x coordinate
        
        if {$orientation == "ReformatAxial" || $orientation == "ReformatCoronal"} {
            if {$temp1(x) < $temp2(x)} {
                set P1(x) $temp2(x)
                set P1(y) $temp2(y)
                set P1(z) $temp2(z)
                set P2(x) $temp1(x)
                set P2(y) $temp1(y)
                set P2(z) $temp1(z)
            } else {
                set P1(x) $temp1(x)
                set P1(y) $temp1(y)
                set P1(z) $temp1(z)
                set P2(x) $temp2(x)
                set P2(y) $temp2(y)
                set P2(z) $temp2(z)
            }
        } 

        # if we want to define a new "PA" axis for the reformatted axial,
        # the first point needs to be the one closest to R, so with the 
        # highest y coordinate

        if {$orientation == "ReformatSagittal" || $orientation == "NewOrient" } {
            if {$temp1(y) < $temp2(y)} {
                set P1(x) $temp2(x)
                set P1(y) $temp2(y)
                set P1(z) $temp2(z)
                set P2(x) $temp1(x)
                set P2(y) $temp1(y)
                set P2(z) $temp1(z)
            } else {
                set P1(x) $temp1(x)
                set P1(y) $temp1(y)
                set P1(z) $temp1(z)
                set P2(x) $temp2(x)
                set P2(y) $temp2(y)
                set P2(z) $temp2(z)
            }
        } 
        set s $Slice(activeID)
        # check that Slice($s,reformatPlaneCoeff,?) values have been set by VolumesReformatSlicePlane.
        if {[info exists Slice($s,reformatPlaneCoeff,A)] == 0 ||
            [info exists Slice($s,reformatPlaneCoeff,B)] == 0 || 
            [info exists Slice($s,reformatPlaneCoeff,C)] == 0 ||
            [info exists Slice($s,reformatPlaneCoeff,D)] == 0} {
            DevErrorWindow "Error: reformat plane coefficients haven't been set, Reformat Saggital Plane first"
            return
        }
        set A $Slice($s,reformatPlaneCoeff,A) 
        set B $Slice($s,reformatPlaneCoeff,B) 
        set C $Slice($s,reformatPlaneCoeff,C) 
        set D $Slice($s,reformatPlaneCoeff,D) 

        set proj [VolumesProjectVectorOnPlane $A $B $C $D $P1(x) $P1(y) P1(z) $P2(x) $P2(y) $P2(z) ]
        set T(x) [lindex $proj 0]
        set T(y) [lindex $proj 1]
        set T(z) [lindex $proj 2]
        
        set N(x) $A
        set N(y) $B
        set N(z) $C
        Normalize N
        
        # set the reformat matrix of the active slice
        Slicer SetReformatNTP $orientation $N(x) $N(y) $N(z) $T(x) $T(y) $T(z) 0 0 0

        MainSlicesSetOrientAll "ReformatAxiSagCor"
        RenderBoth $Slice(activeID)    
    }

}

#-------------------------------------------------------------------------------
# .PROC VolumesReformatSave
#  Save the Active Volume slice by slice with the reformat matrix of the 
#  chosen slice orientation in $Volumes(reformat,scanOrder).<br>
#  Turn into smart image writer.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesReformatSave {} {
    
    global Slices Slice Volume Gui Volumes
    
    # get the chosen volume
    set v $Volume(activeID)
    
    # set initial directory to dir where vol last opened if unset
    if {$Volumes(prefixSave) == ""} {
        set Volumes(prefixSave) \
            [file join $Volume(DefaultDir) [Volume($v,node) GetName]]
    }
    
    if {$Gui(pc) == 1} {
        # this is a hack to get a full path for the save directory - sp
        global Mrml savedir
        set savedir $Mrml(dir) 
        set Mrml(dir) ""
    }
    # Show user a File dialog box
    set Volumes(prefixSave) [MainFileSaveVolume $v $Volumes(prefixSave)]
    if {$Gui(pc) == 1} {
        global Mrml savedir
        set Mrml(dir) $savedir
    }
    if {$Volumes(prefixSave) == ""} {
        DevErrorWindow "Set a file prefix to save the volume"
        return
    }
    
    # the idea is to slide the volume from the low to the high offset and
    # save a slice each time
    set s $Slice(activeID)
    # make the slice the right orientation to get the right reformat
    # matrix
    # check to make sure that the saveOrder was set
    if {[info exists Volumes(reformat,saveOrder)] == 0} {
        DevErrorWindow "Please choose a scan order"
        return
    }
    MainSlicesSetOrient $s $Volumes(reformat,saveOrder)

    scan [Volume($Volume(activeID),node) GetImageRange] "%d %d" lo hi
    
    set num [expr ($hi - $lo) + 1]
    set slo [Slicer GetOffsetRangeLow  $s]
    set shi [Slicer GetOffsetRangeHigh $s]
    
    set extra [expr $shi - int($num/2)]
    
    set lo [expr $slo + $extra]
    set hi [expr $shi - $extra]
    
    Volumes(reformatter) SetInput [Volume($Volume(activeID),vol) GetOutput]
    Volumes(reformatter) SetWldToIjkMatrix [[Volume($Volume(activeID),vol) GetMrmlNode] GetWldToIjk]
    Volumes(reformatter) SetInterpolate 1
    set resolution [lindex [Volume($Volume(activeID),node) GetDimensions] 0]
    Volumes(reformatter) SetResolution $resolution
    # Volumes(reformatter) SetFieldOfView [expr [lindex [Volume($Volume(activeID),node) GetDimensions] 0] * [lindex [Volume($Volume(activeID),node) GetSpacing] 0]]
    set maxfov 0
    for {set i 0} {$i < 2} {incr i} {
        set dim [lindex [Volume($Volume(activeID),node) GetDimensions] $i] 
        set space [lindex [Volume($Volume(activeID),node) GetSpacing] $i]
        set fov [expr $dim * $space]
        if {$fov > $maxfov} {
            set maxfov $fov
        }
    }
    set space [lindex [Volume($Volume(activeID),node) GetSpacing] 2]
    set fov [expr $num * $space]
    if {$fov > $maxfov} {
        set maxfov $fov
    }


    Volumes(reformatter) SetFieldOfView $maxfov
    
    set ref [Slicer GetReformatMatrix $s]
    
    # need the slices to be written out as 1-n, instead of 0-(n-1)
    # set ii 0
    set ii 1
    if {$::Module(verbose)} {
        puts "VolumesReformatSave: starting file names from $ii"
    }
    set lo [expr -1 * round ($maxfov / 2.)]
    set hi [expr -1 * $lo]
    for {set i $lo} {$i<= $hi} {set i [expr $i + 1]} {
        
        MainSlicesSetOffset $s $i
        Volumes(reformatter) SetReformatMatrix $ref
        Volumes(reformatter) Modified
        Volumes(reformatter) Update
        #RenderBoth $s
        Volumes(writer) SetInput [Volumes(reformatter) GetOutput]
        set ext [expr $i + $hi]
        set iii [format %03d $ii]
        Volumes(writer) SetFileName "$Volumes(prefixSave).$iii"
        set Gui(progressText) "Writing slice $ext"
        if {[catch {Volumes(writer) Write} errMsg] == 1} {
            DevErrorWindow "VolumesReformatSave: error writing [Volumes(writer) GetFileName]:\n$errMsg"
        }
        incr ii
    }
    set Gui(progressText) "Done!"
    Volumes(writer) UpdateProgress 0

    set spacing [expr $maxfov / (1. * $resolution)]
    DevInfoWindow "Reformat complete: pixel spacing is $spacing x $spacing x 1.0 mm"
    
}

#-------------------------------------------------------------------------------
# .PROC VolumesAnalyzeExport
# Export the active volume to Analyze Format 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesAnalyzeExport {} {
    
    global Volume Volumes
    
    # get the chosen volume
    set v $Volume(activeID)

    if { $v == 0 } {
        DevInfoWindow "VolumesAnalyzeExport: Please select a volume to export."
        return
    }

    
    # set initial directory to dir where vol last opened if unset
    if {$Volumes(prefixSave) == ""} {
        set Volumes(prefixSave) \
            [file join $Volume(DefaultDir) [Volume($v,node) GetName]]
    }

    if { [catch "package require vtkCISGFile"] } {
        DevErrorWindow "VolumesAnalyzeExport: vtkCISGFile Module is missing.  Cannot export Analyze format."
        return;
    }

    if { [file extension $Volumes(prefixSave)] != ".hdr" } {
        set Volumes(prefixSave) ${Volumes(prefixSave)}.hdr
    }
    
    if { [catch "package require iSlicer"] } {
        DevErrorWindow "VolumesAnalyzeExport: iSlicer Module missing.  Cannot export Analyze format."
        return;
    }

    set width [lindex [Volume($v,node) GetDimensions] 0]
    set height [lindex [Volume($v,node) GetDimensions] 1]
    if { $width > $height } {set max $width} else {set max $height}

    if { [Volume($v,node) GetInterpolate] == 1 } {
        set interpolation linear
    } else {
        set interpolation nearest
    }

    set w .volumesexport
    catch "destroy $w"
    toplevel $w
    wm geometry $w [expr 20+ $width]x[expr 40 + $height]

    # pack [isvolume $w.isv] -fill both -expand true
    wm withdraw $w
    isvolume $w.isv

    $w.isv configure -volume $v -resolution $max -interpolation $interpolation
    $w.isv configure -orientation coronal
    $w.isv configure -orientation axial

    eval [$w.isv imagedata] SetUpdateExtent [[$w.isv imagedata] GetWholeExtent]

    catch "export_flipY Delete"
    vtkImageFlip export_flipY
    export_flipY SetInput [$w.isv imagedata]
    export_flipY SetFilteredAxis 1

    catch "export_flipX Delete"
    vtkImageFlip export_flipX
    export_flipX SetInput [export_flipY GetOutput]
    export_flipX SetFilteredAxis 0
    
    catch "export_aw Delete"
    vtkCISGAnalyzeWriter export_aw 
    export_aw SetFileName $Volumes(prefixSave)
    if { $::Volumes(exportFileType) == "Neurological" } {
        export_aw SetInput [export_flipY GetOutput]
    } else {
        export_aw SetInput [export_flipX GetOutput]
    }
    export_aw Update

    export_aw Delete
    export_flipX Delete
    export_flipY Delete
    $w.isv pre_destroy
    catch "destroy $w"
}

#-------------------------------------------------------------------------------
# .PROC VolumesCORExport
# Export the active volume to COR Format 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesCORExport {} {
    
    global Volume Volumes
    
    # get the chosen volume
    set v $Volume(activeID)

    if { $v == 0 } {
        DevInfoWindow "VolumesCORExport: Please select a volume to export."
        return
    }
    
    if { $Volumes(prefixCORSave) == "" } {
        DevInfoWindow "VolumesCORExport: Please select an export directory."
        return
    }

    if { ![file isdirectory $Volumes(prefixCORSave)] } {
        set Volumes(prefixCORSave) [file dirname $Volumes(prefixCORSave)]
    }

    # check if need to cast to UnsignedChar
    if {[Volume($v,node) GetScalarTypeAsString] != "UnsignedChar"} { 
        if {$::Module(verbose)} {
            DevInfoWindow "VolumesCORExport: converting volume $v to unsigned char before saving"
        }
        if {[info command vtkFreeSurferReadersCast] == "vtkFreeSurferReadersCast"} {
            set vCast [vtkFreeSurferReadersCast $v UnsignedChar]
            if {$vCast != -1} {
                # write out the new volume
                set v $vCast
                DevInfoWindow "VolumesCORExport: created UnsignedChar volume for export"
            }
        } else {
            DevInfoWindow "VolumesCORExport: vtkFreeSurferReaders module needed to cast volume before export"
        }
    }


    catch "export_iwriter Delete"
    vtkImageWriter export_iwriter 
    export_iwriter SetInput [Volume($v,vol) GetOutput]
    export_iwriter SetFilePattern $Volumes(prefixCORSave)/COR-%03d
    export_iwriter SetFileDimensionality 2
    export_iwriter Write
    export_iwriter Delete

    # rename the files to go from 1-256 rather than 0-255
    for {set i 255} {$i >= 0} {incr i -1} {
        set ii [format %03d $i]
        set newii [format %03d [expr 1 + $i]]
        file rename -force $Volumes(prefixCORSave)/COR-$ii $Volumes(prefixCORSave)/COR-$newii  
    }

    set Volumes(prefixCORSave) $Volumes(prefixCORSave)/COR-.info
    set fp [open $Volumes(prefixCORSave) "w"]
    puts $fp "imnr0 1
imnr1 256
ptype 2
x 256
y 256
fov 0.256
thick 0.001
psiz 0.001
locatn 0
strtx -0.128
endx 0.128
strty -0.128
endy 0.128
strtz -0.128
endz 0.128
tr 0.000000
te 0.000000
ti 0.000000
flip angle 0.000000
ras_good_flag 1
x_ras -1.000000 0.000000 0.000000
y_ras 0.000000 0.000000 -1.000000
z_ras 0.000000 1.000000 0.000000
c_ras 0.000000 0.000000 0.000000"
    close $fp

    # set the volume node's filename for writing to mrml later on
    if {$::Module(verbose)} {
        puts "VolumesCORExport: saving $Volumes(prefixCORSave) as file prefix and full prefix in volume node $v [Volume($v,node) GetName]" 
    }
    Volume($v,node) SetFilePrefix $Volumes(prefixCORSave)
    Volume($v,node) SetFullPrefix $Volumes(prefixCORSave)
    Volume($v,node) SetFileType "COR"
}

#-------------------------------------------------------------------------------
# .PROC VolumesNrrdExport
# Export the active volume to Nrrd Format 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesNrrdExport {} {
    
    global Volume Volumes
    
    # get the chosen volume
    set v $Volume(activeID)

    if { $v == 0 } {
        DevInfoWindow "VolumesNrrdExport: Please select a volume to export."
        return
    }
    
    if { $Volumes(prefixNrrdSave) == "" } {
        DevInfoWindow "VolumesNrrdExport: Please select a filename."
        return
    }

    set ext [file extension $Volumes(prefixNrrdSave)] 
    if { [file extension $Volumes(prefixNrrdSave)] == ".nhdr" ||
         [file extension $Volumes(prefixNrrdSave)] == ".nrrd" ||
         [file extension $Volumes(prefixNrrdSave)] == ".img" } {
        set Volumes(prefixNrrdSave) [file root $Volumes(prefixNrrdSave)] 
    }


    catch "export_iwriter Delete"
    vtkImageWriter export_iwriter 
    export_iwriter SetInput [Volume($v,vol) GetOutput]
    export_iwriter SetFileName $Volumes(prefixNrrdSave).img
    export_iwriter SetFileDimensionality 3
    export_iwriter Write
    export_iwriter Delete

    catch "export_matrix Delete"
    vtkMatrix4x4 export_matrix
    eval export_matrix DeepCopy [Volume($v,node) GetRasToVtkMatrix]

    export_matrix Invert
    export_matrix Transpose
    set space_directions [format "(%g, %g, %g) (%g, %g, %g) (%g, %g, %g)" \
                              [export_matrix GetElement 0 0]\
                              [export_matrix GetElement 0 1]\
                              [export_matrix GetElement 0 2]\
                              [expr -1. * [export_matrix GetElement 1 0]]\
                              [expr -1. * [export_matrix GetElement 1 1]]\
                              [expr -1. * [export_matrix GetElement 1 2]]\
                              [export_matrix GetElement 2 0]\
                              [export_matrix GetElement 2 1]\
                              [export_matrix GetElement 2 2] ]
    export_matrix Delete

    set fp [open $Volumes(prefixNrrdSave).nhdr "w"]

    puts $fp "NRRD0001"
    puts $fp "type: [[Volume($v,vol) GetOutput] GetScalarTypeAsString]"
    puts $fp "dimension: 3"
    puts $fp "space: right-anterior-superior"
    foreach "w h d" [[Volume($v,vol) GetOutput] GetDimensions] {}
    puts $fp "sizes: $w $h $d"
    puts $fp "space directions: $space_directions"
    puts $fp "centerings: cell cell cell"
    puts $fp "kinds: space space space"
    if { $::tcl_platform(byteOrder) == "littleEndian" } {
        puts $fp "endian: little"
    } else {
        puts $fp "endian: big"
    }
    puts $fp "space units: \"mm\" \"mm\" \"mm\""
    puts $fp "encoding: raw"
    puts $fp "data file: [file tail $Volumes(prefixNrrdSave)].img"

    close $fp

}

#-------------------------------------------------------------------------------
# .PROC VolumesGenericExportSetFileType
# Set Volumes(extentionGenericSave) and update the save file type menu.
# .ARGS
# str fileType the type for the file
# .END
#-------------------------------------------------------------------------------
proc VolumesGenericExportSetFileType {fileType} {
    global Volume Volumes
    set Volumes(extentionGenericSave) $fileType

    $Volume(gui,mbSaveFileType) config -text $Volumes($fileType)
}

#-------------------------------------------------------------------------------
# .PROC VolumesGenericExport
# Export the active volume to any format 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesGenericExport {} {
    
    global Volume Volumes
    
    # get the chosen volume
    set v $Volume(activeID)

    if { $v == 0 } {
        DevInfoWindow "VolumesGenericExport: Please select a volume to export."
        return
    }
    
    if { $Volumes(prefixGenericSave) == "" } {
        DevInfoWindow "VolumesGenericExport: Please select a filename."
        return
    }
      
    # check if file name has the right extention according to $Volumes(prefixGenericSave)
    if { [string match *.$Volumes(extentionGenericSave) $Volumes(prefixGenericSave)] == 0} {
        DevInfoWindow "VolumesGenericExport: File name: $Volumes(prefixGenericSave) does not match the type that you selected: $Volumes(extentionGenericSave)"
        return
    }
  
    catch "export_matrix Delete"
    vtkMatrix4x4 export_matrix
    eval export_matrix DeepCopy [Volume($v,node) GetRasToIjkMatrix]

    catch "export_iwriter Delete"
    vtkITKImageWriter export_iwriter 
    export_iwriter SetInput [Volume($v,vol) GetOutput]
    export_iwriter SetFileName $Volumes(prefixGenericSave)
    export_iwriter SetRasToIJKMatrix export_matrix
    export_iwriter SetUseCompression $Volume(UseCompression)
    export_iwriter Write

    export_iwriter Delete
    export_matrix Delete
}

#-------------------------------------------------------------------------------
# .PROC VolumesVtkToNrrdScalarType
#  Convert VTK scalar type (like "unsigned char") into
#  Nrrd type string like "uchar"
# .ARGS
#  str type is vtk scalar type
# .END
#-------------------------------------------------------------------------------
proc VolumesVtkToNrrdScalarType {type} {
    
    switch $type {
        "char" {
            return "char"
        }
        "unsigned char" {
            return "uchar"
        }
        "short" {
            return "short"
        }
        "unsigned short" {
            return "ushort"
        }
        "int" {
            return "int"
        }
        "unsigned int" {
            return "uint"
        }
        "long" {
            return "long"
        }
        "unsigned long" {
            return "ulong"
        }
        "float" {
            return "float"
        }
        "double" {
            return "double"
        }
    }
    return ""
}

#-------------------------------------------------------------------------------
# .PROC VolumesVtkToSlicerScalarType
#  Convert VTK scalar type (like "unsigned char") into
#  Slicer type string like "UnsignedChar"
# .ARGS
#  str type is vtk scalar type
# .END
#-------------------------------------------------------------------------------
proc VolumesVtkToSlicerScalarType {type} {
    
    switch $type {
        "char" {
            return "Char"
        }
        "unsigned char" {
            return "UnsignedChar"
        }
        "short" {
            return "Short"
        }
        "unsigned short" {
            return "UnsignedShort"
        }
        "int" {
            return "Int"
        }
        "unsigned int" {
            return "UnsignedInt"
        }
        "long" {
            return "Long"
        }
        "unsigned long" {
            return "UnsignedLong"
        }
        "float" {
            return "Float"
        }
        "double" {
            return "Double"
        }
    }
    return ""
}

#-------------------------------------------------------------------------------
# .PROC VolumesComputeNodeMatricesFromIjkToRasMatrix
#  Compute node matrices from IJK to RAS matrix.
# .ARGS
# int volumeNode node id
# vtkMatrix4x4 ijkToRasMatrix
# list dims dimensions list
# .END
#-------------------------------------------------------------------------------
proc VolumesComputeNodeMatricesFromIjkToRasMatrix {volumeNode ijkToRasMatrix dims} {

    # first top left - start at zero, and add origin to all later
    set ftl "0 0 0"

    # first top right = width * row vector
    set ftr [lrange [$ijkToRasMatrix MultiplyPoint [expr [lindex $dims 0]] 0 0 0] 0 2]

    # first bottom right = ftr + height * column vector
    set column_vec [lrange [$ijkToRasMatrix MultiplyPoint 0 [expr [lindex $dims 1]] 0 0] 0 2]
    set fbr ""
    foreach ftr_e $ftr column_vec_e $column_vec {
        lappend fbr [expr $ftr_e + $column_vec_e]
    }

    # last top left = ftl + slice vector  (and ftl is zero)
    set ltl [lrange [$ijkToRasMatrix MultiplyPoint 0 0 [expr [lindex $dims 2]] 0] 0 2]

    puts "ftl ftr fbr ltl"
    puts "$ftl   $ftr   $fbr   $ltl"

    # add the origin offset 
    set origin [lrange [$ijkToRasMatrix MultiplyPoint 0 0 0 1] 0 2]
    foreach corner "ftl ftr fbr ltl" {
        set new_corner ""
        foreach corner_e [set $corner] origin_e $origin {
            lappend new_corner [expr $corner_e + $origin_e]
        }
        set $corner $new_corner
    }

    puts "ftl ftr fbr ltl"
    puts "$ftl   $ftr   $fbr   $ltl"
    eval ::Volume($volumeNode,node) ComputeRasToIjkFromCorners "0 0 0" $ftl $ftr $fbr "0 0 0" $ltl 0
}

#-------------------------------------------------------------------------------
# .PROC VolumesComputeNodeMatricesFromIjkToRasMatrix2
#  Compute mode matrices from IJK to RAS matrix.<br>
# Columns of IjkToRasMatrix are space direction vectors and space origin.<br>
# The matrix includes spacing.
# .ARGS
# int volumeNode node id
# vtkMatrix4x4 ijkToRasMatrix
# list dims dimensions list
# .END
#-------------------------------------------------------------------------------
proc VolumesComputeNodeMatricesFromIjkToRasMatrix2 {volumeNode ijkToRasMatrix dims} {

    catch "RasToIjk Delete"
    catch "VtkToRas Delete"
    catch "RasToVtk Delete"
    catch "Spacing Delete"
    catch "Position Delete"
    vtkMatrix4x4 RasToIjk
    vtkMatrix4x4 VtkToRas
    vtkMatrix4x4 RasToVtk
    vtkMatrix4x4 Spacing
    vtkMatrix4x4 Position

    puts "ijkToRasMatrix" 
    puts [$ijkToRasMatrix Print]

    # RasToIjk is simply the inverse of ijkToRas
    RasToIjk DeepCopy $ijkToRasMatrix
    RasToIjk Invert
    set strRasToIjk [Volume($volumeNode,node) GetMatrixToString RasToIjk]
    Volume($volumeNode,node) SetRasToIjkMatrix $strRasToIjk

    # VtkToRas is maps vtk pixel coords to Ras
    # - y is at the bottom
    # -- second space direction is negated
    # -- y origin is moved to other end of image along y
    VtkToRas DeepCopy $ijkToRasMatrix
    for {set row 0} {$row < 3} {incr row} {
        VtkToRas SetElement $row 1 [expr -1 * [VtkToRas GetElement $row 1]]
    }
    set yext [expr [lindex $dims 1] - 1]
    set vtkOrigin [$ijkToRasMatrix MultiplyPoint 0 $yext 0 1]
    puts "vtkOrigin" 
    puts $vtkOrigin 
    for {set row 0} {$row < 3} {incr row} {
        VtkToRas SetElement $row 3 [lindex $vtkOrigin $row]
    }
    # RasToVtk is inverse of VtkToRas
    RasToVtk DeepCopy VtkToRas
    RasToVtk Invert
    set strRasToVtk [Volume($volumeNode,node) GetMatrixToString RasToVtk]
    Volume($volumeNode,node) SetRasToVtkMatrix $strRasToVtk

    puts "VtkToRas" 
    puts [VtkToRas Print]

    puts "RasToVtk" 
    puts [RasToVtk Print]

    # calculate the PositionMatrix
    # VtkToRas = Position * Spacing
    # VtkToRas * Spacing(-1) = Position 
    # - spacing is diagonal matrix with the pixel spacings 
    Spacing Identity
    set spacing [Volume($volumeNode,node) GetSpacing]
    for {set row 0} {$row < 3} {incr row} {
        Spacing SetElement $row $row [lindex $spacing $row]
    }
    Spacing Invert
    # A * B -> C    
    VtkToRas Multiply4x4  VtkToRas Spacing  Position
    set strPosition [Volume($volumeNode,node) GetMatrixToString Position]
    Volume($volumeNode,node) SetPositionMatrix $strPosition

    puts "Spacing" 
    puts [Spacing Print]

    puts "Position" 
    puts [Position Print]

    RasToIjk Delete
    VtkToRas Delete
    RasToVtk Delete
    Spacing Delete
    Position Delete
}

#-------------------------------------------------------------------------------
# .PROC VolumesCreateNewLabelOutline
# Add a new volume to the mrml tree, that just has the outline
# .ARGS 
# int v optional volume id, uses Volume(activeID) if empty string
# .END
#-------------------------------------------------------------------------------
proc VolumesCreateNewLabelOutline { {v ""} } {

    global Volume

    if {$v == ""} {
        # get the chosen volume
        set v $Volume(activeID)
    }

    # is it a label map?
    if {[Volume($v,node) GetLabelMap] != 1} {
        DevErrorWindow "Label outline only works for volumes which are label maps, choose a different active volume"
        return
    }

    # add a node to the mrml tree
    set name "[Volume($v,node) GetName]-outline"
    set outlineID [DevCreateNewCopiedVolume $v "" $name]
    set node  [Volume($outlineID,vol) GetMrmlNode]
    Mrml(dataTree) RemoveItem $node 
    set nodeBefore [Volume($v,vol) GetMrmlNode]
    Mrml(dataTree) InsertAfterItem $nodeBefore $node
    MainUpdateMRML

    catch "labelOutline Delete"
    vtkImageLabelOutline labelOutline
    # defaults should be okay
    
    labelOutline AddObserver StartEvent MainStartProgress
    labelOutline AddObserver ProgressEvent "MainShowProgress labelOutline"
    labelOutline AddObserver EndEvent MainEndProgress
    set ::Gui(progressText) "Creating label outline"

    labelOutline SetInput [Volume($v,vol) GetOutput]
    labelOutline Update

    # now save it back into the tree
    Volume($outlineID,vol) SetImageData [labelOutline GetOutput]
    MainVolumesUpdate $outlineID
}

#-------------------------------------------------------------------------------
# .PROC VolumesComputeNodeMatricesFromRasToIjkMatrix
# Compute Node Matrices From RasToIjkMatrix.<br>
# The matrix includes spacing.<br>
# Also compute the closest fit to the scanorder.
# .ARGS
# int volumeNode the volume node id
# vtkMatrix4x4 RasToIjkMatrix the input RAS to IJK matrix
# list dims contains the extents along the x, y, z axes. Only y is used.
# .END
#-------------------------------------------------------------------------------
proc VolumesComputeNodeMatricesFromRasToIjkMatrix {mrmlNode RasToIjkMatrix dims} {
    
    catch "IjkToRasMatrix Delete"
    vtkMatrix4x4 IjkToRasMatrix
    IjkToRasMatrix DeepCopy $RasToIjkMatrix
    IjkToRasMatrix Invert
    
    catch "RasToVtkMatrix Delete"
    vtkMatrix4x4 RasToVtkMatrix
    RasToVtkMatrix DeepCopy IjkToRasMatrix
    
    for {set row 0} {$row < 3} {incr row} {
        RasToVtkMatrix SetElement $row 1 [expr -1 * [RasToVtkMatrix GetElement $row 1]]
    }
    
    set yext [expr [lindex $dims 1] - 1]
    set vtkOrigin [IjkToRasMatrix MultiplyPoint 0 $yext 0 1]

    for {set row 0} {$row < 3} {incr row} {
        RasToVtkMatrix SetElement $row 3 [lindex $vtkOrigin $row]
    }
    
    RasToVtkMatrix Invert
    
    $mrmlNode SetRasToIjkMatrix [$mrmlNode GetMatrixToString $RasToIjkMatrix]
    $mrmlNode SetRasToVtkMatrix [$mrmlNode GetMatrixToString RasToVtkMatrix]
    $mrmlNode ComputePositionMatrixFromRasToVtk RasToVtkMatrix
    
    RasToVtkMatrix Delete

    #
    # compute scan order by looking at the vector for the 'k' direction (slice direction)
    # and then saying that the largest
    
    set k_vec [IjkToRasMatrix MultiplyPoint 0 0 1 0]
    set max_comp 0
    set max [expr abs([lindex $k_vec 0])]
    for {set i 1} {$i < 3} {incr i} {
        if { [expr abs([lindex $k_vec $i])] > $max } {
            set max [expr abs([lindex $k_vec $i])]
            set max_comp $i
        }
    }
    
    switch $max_comp {
        0 {
            if { [lindex $k_vec 0] > 0 } {
                set scan_order "LR"
            } else {
                set scan_order "RL"
            }
        }
        1 {
            if { [lindex $k_vec 1] > 0 } {
                set scan_order "PA"
            } else {
                set scan_order "AP"
            }
        }
        2 {
            if { [lindex $k_vec 2] > 0 } {
                set scan_order "IS"
            } else {
                set scan_order "SI"
            }
        }
    }
    
    $mrmlNode SetScanOrder $scan_order

    IjkToRasMatrix Delete
}


#-------------------------------------------------------------------------------
# .PROC VolumesUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolumesUpdateMRML {} {
    global Volume Module

    # Call each Module's "MRML" routine
    #-------------------------------------------
    foreach m $Volume(readerModules,idList) {
        if {[info exists Module(readerModules,$m,procMRML)] == 1} {
            eval $Module(readerModules,$m,procMRML)
        }
    }
}
