#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ITKFilters.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:49 $
#   Version:   $Revision: 1.8 $
# 
#===============================================================================
# FILE:        ITKFilters.tcl
# PROCEDURES:  
#   ITKFiltersInit
#   ITKFiltersUpdateGUI
#   ITKFiltersBuildGUI
#   ITKFiltersBuildVTK
#   vtkITKGUIFilter filter
#   ITKFiltersEnter
#   ITKFiltersExit
#   ITKFiltersApply
#   ITKFiltersBeforeUpdate
#   ITKFiltersAfterUpdate
#   ITKFiltersSpatialObjectsApply
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC ITKFiltersInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersInit {} {
    global ITKFilters Module Volume Model

    set m ITKFilters

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is an example of how to add modules to slicer."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Raul San Jose, LMI"

    #  Set the level of development that this module falls under, from the list defined in Main.tcl,
    #  Module(categories) or pick your own
    #  This is included in the Help->Module Categories menu item
    set Module($m,category) "Example"

    # Define Tabs
    #------------------------------------
    # Description:
    #   Each module is given a button on the Slicer's main menu.
    #   When that button is pressed a row of tabs appear, and there is a panel
    #   on the user interface for each tab.  If all the tabs do not fit on one
    #   row, then the last tab is automatically created to say "More", and 
    #   clicking it reveals a second row of tabs.
    #
    #   Define your tabs here as shown below.  The options are:
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #

    set Module($m,row1List) "Help Main SpatialObjects"
    set Module($m,row1Name) "{Help} {Main} {SpatialObjects}"
    set Module($m,row1,tab) Main

    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #
    #   set Module($m,procVTK) ITKFiltersBuildVTK
    #
    #   All the options are:

    #   procGUI   = Build the graphical user interface
    #   procVTK   = Construct VTK objects
    #   procMRML  = Update after the MRML tree changes due to the creation
    #               of deletion of nodes.
    #   procEnter = Called when the user enters this module by clicking
    #               its button on the main menu
    #   procExit  = Called when the user leaves this module by clicking
    #               another modules button
    #   procCameraMotion = Called right before the camera of the active 
    #                      renderer is about to move 
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) ITKFiltersBuildGUI
    set Module($m,procVTK) ITKFiltersBuildVTK
    set Module($m,procMRML) ITKFiltersUpdateGUI
    set Module($m,procEnter) ITKFiltersEnter
    set Module($m,procExit) ITKFiltersExit

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    set Module($m,depend) ""

    # Set version info
    #------------------------------------
    # Description:
    #   Record the version number for display under Help->Version Info.
    #   The strings with the $ symbol tell CVS to automatically insert the
    #   appropriate revision number and date when the module is checked in.
    #   
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.8 $} {$Date: 2006/01/06 17:57:49 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
   
    set ITKFilters(inVolume) $Volume(idNone)
    set ITKFilters(outVolume) $Volume(idNone)
    #set ITKFilters(Model1)  $Model(idNone)
    #set ITKFilters(FileName)  ""

    set ITKFilters(filters) "   GradientAnisotropicDiffusionImageFilter \
                                CurvatureAnisotropicDiffusionImageFilter \
                                GradientMagnitudeImageFilter \
                                TobogganImageFilter \
                                DanielssonDistanceMapImageFilter \
                                DiscreteGaussianImageFilter \
                                MRIBiasFieldCorrectionImageFilter"
     
    set ITKFilters(filter) GradientAnisotropicDiffusionImageFilter
    set filter $ITKFilters(filter)
    set ITKFilters($filter,params) "SetConductanceParameter SetNumberOfIterations \
                                     SetTimeStep"
    
    set param SetConductanceParameter
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Conductance"
    set ITKFilters($filter,$param,maxmin) "1 10"
    set ITKFilters($filter,$param,res) 0.1
    set ITKFilters($filter,$param,widget) "scale"
    set param SetNumberOfIterations
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Num. Iterations"
    set ITKFilters($filter,$param,maxmin) "1 15"
    set ITKFilters($filter,$param,res) 1
    set ITKFilters($filter,$param,widget) "scale"                             
    set param SetTimeStep
    set ITKFilters($filter,$param) 0.1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Time Step"
    set ITKFilters($filter,$param,maxmin) "0.1 1"
    set ITKFilters($filter,$param,res) 0.1
    set ITKFilters($filter,$param,widget) "scale" 
                                
    set ITKFilters(filter) CurvatureAnisotropicDiffusionImageFilter
    
    set filter $ITKFilters(filter)
    set ITKFilters($filter,params) SetConductanceParameter
    set param SetConductanceParameter
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Conductance"
    set ITKFilters($filter,$param,maxmin) "1 10"
    set ITKFilters($filter,$param,res) 1
    set ITKFilters($filter,$param,widget) "scale"

    set filter "GradientMagnitudeImageFilter"
    set ITKFilters($filter,params) ""
    if {0} {
    set ITKFilters($filter,params) SetUseImageSpacing
    set param SetUseImageSpacing
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,maxmin) "1 0"
    set ITKFilters($filter,$param,text) "Use Image Spacing"
    set ITKFilters($filter,$param,widget) "boolean"
    }
    set filter "TobogganImageFilter"
    set ITKFilters($filter,params) ""

    set filter "DanielssonDistanceMapImageFilter"
    set ITKFilters($filter,params) "SetSquaredDistance"
    set param SetSquaredDistance
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,maxmin) "1 0"
    set ITKFilters($filter,$param,text) "Square Distance"
    set ITKFilters($filter,$param,widget) "boolean"

    set filter "DiscreteGaussianImageFilter"
    set ITKFilters($filter,params) "SetVariance SetUseImageSpacing"
    set param SetVariance
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,maxmin) "0.7 10"
    set ITKFilters($filter,$param,res) 0.1
    set ITKFilters($filter,$param,text) "Variance"
    set ITKFilters($filter,$param,widget) "scale" 
    set param SetUseImageSpacing
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,maxmin) "1 0"
    set ITKFilters($filter,$param,text) "Use Image Spacing"
    set ITKFilters($filter,$param,widget) "boolean"
    
    set filter "MRIBiasFieldCorrectionImageFilter"
    set ITKFilters($filter,params) "SetTissueClassMeans \
                                    SetTissueClassSigmas \
                                    SetUsingSlabIdentification \
                                    SetUsingInterSliceIntensityCorrection \
                                    SetVolumeCorrectionMaximumIteration \
                                    SetInterSliceCorrectionMaximumIteration \
                                    SetBiasFieldDegree \
                                    SetSlabNumberOfSamples \
                                    SetSlicingDirection \
                                    SetSlabBackgroundMinimumThreshold \
                                    SetOptimizerGrowthFactor \
                                    SetOptimizerInitialRadius \
                                    SetSlabTolerance" 

    set param SetTissueClassMeans
    set ITKFilters($filter,$param) 100
    set ITKFilters($filter,$param,type) "darray"
    set ITKFilters($filter,$param,text) "Tissue Class Means"
    set ITKFilters($filter,$param,widget) "entry" 
    set param SetTissueClassSigmas
    set ITKFilters($filter,$param) 10
    set ITKFilters($filter,$param,type) "darray"
    set ITKFilters($filter,$param,text) "Tissue Class Sigmas"
    set ITKFilters($filter,$param,widget) "entry" 
    set param SetUsingSlabIdentification
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,maxmin) "1 0"
    set ITKFilters($filter,$param,text) "Use Slab Identification"
    set ITKFilters($filter,$param,widget) "boolean"
    set param SetUsingInterSliceIntensityCorrection
    set ITKFilters($filter,$param) 1
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,maxmin) "1 0"
    set ITKFilters($filter,$param,text) "Use Inter-Slice Intensity Correction"
    set ITKFilters($filter,$param,widget) "boolean"
    set param SetVolumeCorrectionMaximumIteration
    set ITKFilters($filter,$param) 100
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Volume Correction Maximum Iteration"
    set ITKFilters($filter,$param,maxmin) "0 1000"
    set ITKFilters($filter,$param,res) 100
    set ITKFilters($filter,$param,widget) "scale"
    set param SetInterSliceCorrectionMaximumIteration
    set ITKFilters($filter,$param) 100
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Inter-Slice Correction Maximum Iteration"
    set ITKFilters($filter,$param,maxmin) "0 1000"
    set ITKFilters($filter,$param,res) 100
    set ITKFilters($filter,$param,widget) "scale"
    set param SetBiasFieldDegree
    set ITKFilters($filter,$param) 3
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Bias Field Degree"
    set ITKFilters($filter,$param,maxmin) "1 10"
    set ITKFilters($filter,$param,res) 1
    set ITKFilters($filter,$param,widget) "scale"
    set param SetSlabNumberOfSamples
    set ITKFilters($filter,$param) 10
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Slab Number Of Samples"
    set ITKFilters($filter,$param,maxmin) "1 100"
    set ITKFilters($filter,$param,res) 1
    set ITKFilters($filter,$param,widget) "scale"
    set param SetSlicingDirection
    set ITKFilters($filter,$param) 2
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Slicing Direction"
    set ITKFilters($filter,$param,maxmin) "1 3"
    set ITKFilters($filter,$param,res) 1
    set ITKFilters($filter,$param,widget) "scale"
    set param SetSlabBackgroundMinimumThreshold
    set ITKFilters($filter,$param) 0
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Slab Background Minimum Threshold"
    set ITKFilters($filter,$param,maxmin) "0 100"
    set ITKFilters($filter,$param,res) 1
    set ITKFilters($filter,$param,widget) "scale"
    set param SetOptimizerGrowthFactor
    set ITKFilters($filter,$param) 1.01
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "ptimizer Growth Factor"
    set ITKFilters($filter,$param,maxmin) "1 2"
    set ITKFilters($filter,$param,res) 0.01
    set ITKFilters($filter,$param,widget) "scale"
    set param SetOptimizerInitialRadius
    set ITKFilters($filter,$param) 0.02
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Optimizer Initial Radius"
    set ITKFilters($filter,$param,maxmin) "0 1"
    set ITKFilters($filter,$param,res) 0.01
    set ITKFilters($filter,$param,widget) "scale"
    set param SetSlabTolerance
    set ITKFilters($filter,$param) 0
    set ITKFilters($filter,$param,type) "scalar"
    set ITKFilters($filter,$param,text) "Slab Tolerance"
    set ITKFilters($filter,$param,maxmin) "0 10"
    set ITKFilters($filter,$param,res) 0.1
    set ITKFilters($filter,$param,widget) "scale"
}


#-------------------------------------------------------------------------------
# .PROC ITKFiltersUpdateGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersUpdateGUI {} {
    global ITKFilters Volume
    
    DevUpdateNodeSelectButton Volume ITKFilters inVolume   inVolume   DevSelectNode
    DevUpdateNodeSelectButton Volume ITKFilters outVolume  outVolume  DevSelectNode 0 1 1
}


# NAMING CONVENTION:
#-------------------------------------------------------------------------------
#
# Use the following starting letters for names:
# t  = toplevel
# f  = frame
# mb = menubutton
# m  = menu
# b  = button
# l  = label
# s  = slider
# i  = image
# c  = checkbox
# r  = radiobutton
# e  = entry
#
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC ITKFiltersBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersBuildGUI {} {
    global Gui ITKFilters Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(ITKFilters,fStuff)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Stuff
    #   Top
    #   Middle
    #   Bottom
    #     FileLabel
    #     CountDemo
    #     TextBox
    #-------------------------------------------
   #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The ITKFilters module is an example for developers.  It shows how to add a itk Filter
    to the Slicer through ITK wrapping..
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Tons o' Stuff:</B> This tab is a demo for developers.
    "
    regsub -all "\n" $help {} help

    MainHelpApplyTags ITKFilters $help
    MainHelpBuildGUI ITKFilters

    #-------------------------------------------
    # Stuff frame
    #-------------------------------------------
    set fMain $Module(ITKFilters,fMain)
    set f $fMain
    
    foreach frame "Top Middle Bottom Floating" {
        frame $f.f$frame -bg $Gui(activeWorkspace)

        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # Stuff->Top frame
    #-------------------------------------------
    set f $fMain.fTop
    
    #       grid $f.lStuff -padx $Gui(pad) -pady $Gui(pad)
    #       grid $menubutton -sticky w
    
    # Add menus that list models and volumes
    DevAddSelectButton  ITKFilters $f inVolume "Input Volume" Grid
    DevAddSelectButton  ITKFilters $f outVolume  "Output Model"  Grid
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbinVolume
    lappend Volume(mActiveList) $f.mbinVolume.m
    lappend Model(mbActiveList) $f.mboutVolume
    lappend Model(mActiveList) $f.mboutVolume.m

    #-----    
    #Main->Floating frame
    #-----
    #Create only the frames
    

    
    #-------------------------------------------
    # Main->Middle frame
    #-------------------------------------------
    set f $fMain.fMiddle

    proc ITKFiltersSelectFilter {} {
        global Module ITKFilters
        set fFloating $Module(ITKFilters,fMain).fFloating
        set ITKFilters(filter) [$Module(ITKFilters,fMain).fMiddle.filters get]
        raise $fFloating.f$ITKFilters(filter)
        focus $fFloating.f$ITKFilters(filter)
    }    
        
    iwidgets::optionmenu $f.filters \
        -labeltext "Filters:" \
        -command ITKFiltersSelectFilter \
        -background "#e2cdba" -foreground "#000000" 

    pack $f.filters -side top 
    
    foreach filter $ITKFilters(filters) {
        $f.filters insert end $filter
    }

 
    #-----    
    #Main->Floating frame
    #-----
    #Create widgets and pack
    
    set f $fMain.fFloating
    set f $fMain.fFloating
    $f config -height 500
    foreach filter $ITKFilters(filters) {
        frame $f.f$filter -bg $Gui(activeWorkspace)
        #for raising one frame at a time
        place $f.f$filter -in $f -relheight 1.0 -relwidth 1.0
    }
    
    raise $fMain.fFloating.f$ITKFilters(filter)
 
    foreach filter $ITKFilters(filters) {
        vtkITKGUIFilter $filter
    }

    #-------------------------------------------
    # Main->Bottom frame
    #-------------------------------------------
    set f $fMain.fBottom

    DevAddButton $f.bApply "Apply"  "ITKFiltersApply"

    TooltipAdd $f.bApply "Apply a filter"
    pack $f.bApply 
   
    #-------------------------------------------
    # SpatialObjects frame
    #-------------------------------------------
    set fSpatialObjects $Module(ITKFilters,fSpatialObjects)
    set f $fSpatialObjects

    DevAddFileBrowse $f ITKFilters SpatialObjects,filename "SpatialObject File" "" "" "" "Open" "Select SpatialObject File" "Pick file to add to scene"

    DevAddButton $f.bApply "Apply"  "ITKFiltersSpatialObjectsApply"

    TooltipAdd $f.bApply "Load the spatial object file and add contents to the view"
    pack $f.bApply 

}
#-------------------------------------------------------------------------------
# .PROC ITKFiltersBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersBuildVTK {} {

}

#-------------------------------------------------------------------------------
# .PROC vtkITKGUIFilter
# 
# .ARGS
# string filter
# .END
#-------------------------------------------------------------------------------
proc vtkITKGUIFilter { filter } {
    global Module ITKFilters Gui

    set f $Module(ITKFilters,fMain).fFloating.f$filter
   
    #puts "Making GUI filter: $filter"

    foreach param $ITKFilters($filter,params) {
        frame $f.f$param
        pack $f.f$param -side top -padx 0 -pady $Gui(pad) -fill both
        set fwidget $f.f$param
     
        switch -exact -- $ITKFilters($filter,$param,widget) {
            "scale" {
                eval {label $fwidget.l$param -text $ITKFilters($filter,$param,text)\
                    -width 12 -justify right } $Gui(WLA)

                eval {entry $fwidget.e$param -justify right -width 4 \
                    -textvariable ITKFilters($filter,$param)  } $Gui(WEA)

                eval {scale $fwidget.s$param -from [lindex $ITKFilters($filter,$param,maxmin) 0] \
                    -to [lindex $ITKFilters($filter,$param,maxmin) 1]    \
                    -variable  ITKFilters($filter,$param)\
                    -orient vertical     \
                    -resolution $ITKFilters($filter,$param,res)      \
                } $Gui(WSA)

                pack $fwidget.l$param $fwidget.e$param $fwidget.s$param \
                    -side left -padx $Gui(pad) -pady 0
            }
            "entry" {
                eval {label $fwidget.l$param -text $ITKFilters($filter,$param,text)\
                    -width 12 -justify right } $Gui(WLA)

                eval {entry $fwidget.e$param -justify right -width 40 \
                    -textvariable ITKFilters($filter,$param)  } $Gui(WEA)

                pack $fwidget.l$param $fwidget.e$param \
                    -side left -padx $Gui(pad) -pady 0
            }
            "boolean" {
                DevAddLabel $fwidget.l$param $ITKFilters($filter,$param,text)

                foreach val $ITKFilters($filter,$param,maxmin) text "On Off" {

                    eval {radiobutton $fwidget.r$param$val \
                        -text "$text" \
                        -value "$val" \
                        -variable ITKFilters($filter,$param) \
                        -indicatoron 0} $Gui(WCA) \
                        {-width 3}
                    pack $fwidget.l$param $fwidget.r$param$val -side left -padx 0 -pady 0

                }
            }
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC ITKFiltersEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersEnter {} {
    global ITKFilters
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    #pushEventManager $ITKFilters(eventManager)

    # clear the text box and put instructions there
    #$ITKFilters(textBox) delete 1.0 end
    #$ITKFilters(textBox) insert end "Shift-Click anywhere!\n"

}


#-------------------------------------------------------------------------------
# .PROC ITKFiltersExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
}


#-------------------------------------------------------------------------------
# .PROC ITKFiltersApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersApply {} {
    global ITKFilters Volume

    set filter $ITKFilters(filter)
    set v1 $ITKFilters(inVolume)
    set v2 $ITKFilters(outVolume)
    #puts $v2
    if {$v2 == -5} {
        set name [Volume($v1,node) GetName]
        set v2 [DevCreateNewCopiedVolume $v1 ""  ${name}_filter ]
        set node [Volume($v2,vol) GetMrmlNode]
        Mrml(dataTree) RemoveItem $node 
        set nodeBefore [Volume($v1,vol) GetMrmlNode]
        Mrml(dataTree) InsertAfterItem $nodeBefore $node
        MainUpdateMRML
    } else {

        set v2name  [Volume($v2,node) GetName]
        set continue [DevOKCancel "Overwrite $v2name?"]
        if {$continue == "cancel"} { return 1 }
        # They say it is OK, so overwrite!
        Volume($v2,node) Copy Volume($v1,node)
    }

    #Caster 
    vtkImageCast _cast
    _cast SetOutputScalarTypeToFloat
    _cast SetInput [Volume($v1,vol) GetOutput]
    _cast Update
    #Create Object

    catch "_filter Delete"
    vtkITK$filter _filter

    foreach param $ITKFilters($filter,params) {
        switch -exact -- $ITKFilters($filter,$param,type) {
            "scalar" {
                _filter $param $ITKFilters($filter,$param)
            }
            "darray" {
                catch "vals Delete"
                vtkDoubleArray vals
                foreach val $ITKFilters($filter,$param) {
                    vals InsertNextValue $val
                }
                _filter $param vals
                vals Delete
            }
        }
    }
    _filter SetInput [_cast GetOutput]


    ITKFiltersBeforeUpdate

    _filter AddObserver StartEvent MainStartProgress
    _filter AddObserver EndEvent MainEndProgress
    _filter AddObserver ProgressEvent "MainShowProgress _filter"
    _filter Update

    ITKFiltersAfterUpdate

    #Assign output
    [Volume($v2,vol) GetOutput] DeepCopy [_filter GetOutput]

    #Disconnect pipeline

    _cast Delete
    _filter SetOutput ""
    _filter Delete
}

#-------------------------------------------------------------------------------
# .PROC ITKFiltersBeforeUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersBeforeUpdate { } {

    global ITKFilters

    switch -exact -- $ITKFilters(filter) {

        "GrayscaleGeodesicErodeImageFilter" {
            _filter SetMaskMarkerImage [_filter GetInput]
        }
    }  
}

#-------------------------------------------------------------------------------
# .PROC ITKFiltersAfterUpdate
# Does nothing.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersAfterUpdate { } { 

}

#-------------------------------------------------------------------------------
# .PROC ITKFiltersSpatialObjectsApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ITKFiltersSpatialObjectsApply {} {

    if { [info command vtkITKSceneSpatialObjectViewer] == "" } {
        DevWarningWindow "SpatialObjects not available in this version of vtkITK"
        return
    }

    catch "ssov Delete"
    vtkITKSceneSpatialObjectViewer ssov
    ssov SetRenderer viewRen
    ssov SetFileName $::ITKFilters(SpatialObjects,filename)
    ssov AddActors
}
