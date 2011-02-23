#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: SubVolume.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:04 $
#   Version:   $Revision: 1.10 $
# 
#===============================================================================
# FILE:        SubVolume.tcl
# PROCEDURES:  
#   SubVolumeInit
#   SubVolumeBuildGUI
#   SubVolume3DOpacity opacity
#   SubVolumeApply
#   SubVolumeAddMrmlImage volID resname
#   SubVolumeBuildVTK
#   SubVolumeEnter
#   SubVolumeExit
#   SubVolumeUpdateGUI
#   SubVolumeGetInitParams
#   SubVolumePick3D type
#   SubVolumeUpdate3DScales notUsed
#   SubVolumeCreate3DCube
#   SubVolumeDelete3DCube
#   SubVolumeRenderCube
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC SubVolumeInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeInit {} {
    global SubVolume Module Volume Model

    set m SubVolume

    # Module Summary Info
    #------------------------------------
    # Description:
    #  Give a brief overview of what your module does, for inclusion in the 
    #  Help->Module Summaries menu item.
    set Module($m,overview) "This module is an example of how to add modules to slicer."
    #  Provide your name, affiliation and contact information so you can be 
    #  reached for any questions people may have regarding your module. 
    #  This is included in the  Help->Module Credits menu item.
    set Module($m,author) "Karl Krissian and Raul San Jose Estepar, LMI {karl,rjosest}@bwh.harvard.edu"

    #  Set the level of development that this module falls under, from the list defined in Main.tcl,
    #  Module(categories) or pick your own
    #  This is included in the Help->Module Categories menu item
    set Module($m,category) "Segmentation"

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

    set Module($m,row1List) "Help Extract Merge"
    set Module($m,row1Name) "{Help} {Extract} {Merge}"
    set Module($m,row1,tab) Extract

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
    #   set Module($m,procVTK) SubVolumeBuildVTK
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
    set Module($m,procGUI) SubVolumeBuildGUI
    set Module($m,procVTK) SubVolumeBuildVTK
    set Module($m,procEnter) SubVolumeEnter
    set Module($m,procExit) SubVolumeExit
    set Module($m,procMRML) SubVolumeUpdateGUI

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
        {$Revision: 1.10 $} {$Date: 2006/01/06 17:58:04 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set SubVolume(VolumeIn) $Volume(idNone)
    set SubVolume(OutputName) "roi"
    
    set SubVolume(mbVolumeIn) ""
    set SubVolume(mbVolumeOut) ""
 
    set SubVolume(eventManager) ""
    
    
    set SubVolume(InOrigin) "0 0 0"
    set SubVolume(InExtent) "0 0 0 0 0 0"
    set SubVolume(InSpacing) "0 0 0"
    
    set SubVolume(FileName)  ""

    #2D case variables
    set SubVolume(Ext2D,TypeList) "Ax Sag Cor"
    set SubVolume(Ext2D,Type) "All"
    set SubVolume(Ext2D,Ax,init) 0
    set SubVolume(Ext2D,Ax,end) 1
    set SubVolume(Ext2D,Sag,init) 1
    set SubVolume(Ext2D,Sag,end) 2
    set SubVolume(Ext2D,Cor,init) 2
    set SubVolume(Ext2D,Cor,end) 3

    #3D case variable
    foreach type "AxMin AxMax SagMin SagMax CorMin CorMax" {
      set SubVolume(Ext3D,$type) 0
      set SubVolume(Ext3D,$type,min) 0
      set SubVolume(Ext3D,$type,max) 0
    }
    
    set SubVolume(Ext3D,volId) $Volume(idNone)
    set SubVolume(Ext3D,AxMin,title) "Ax Min (I):"
    set SubVolume(Ext3D,AxMax,title) "Ax Max (S):"
    set SubVolume(Ext3D,SagMin,title) "Sag Min (L):"
    set SubVolume(Ext3D,SagMax,title) "Sag Max (R):"
    set SubVolume(Ext3D,CorMin,title) "Cor Min (P):"
    set SubVolume(Ext3D,CorMax,title) "Cor Max (A):"
    
    set SubVolume(Ext3D,AxMin,Id) 0 
    set SubVolume(Ext3D,AxMax,Id) 0
    set SubVolume(Ext3D,SagMin,Id) 1
    set SubVolume(Ext3D,SagMax,Id) 1
    set SubVolume(Ext3D,CorMin,Id) 2
    set SubVolume(Ext3D,CorMax,Id) 2
    
    
    set SubVolume(Ext3D,CubeColor) "1 0 0"
    set SubVolume(Ext3D,CubeOpacity) 0.5
    set SubVolume(Ext3D,OutlineColor) "0 0 1"
    set SubVolume(Ext3D,OutlineOpacity) 1
    set SubVolume(Ext3D,RenderCube) 1
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
# .PROC SubVolumeBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeBuildGUI {} {
    global Gui SubVolume Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(SubVolume,fStuff)
    
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
    The SubVolume module allows to extract a subvolume of interest for further processing
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Extract:</B> Extract a subvolume from an input volume. The extent of the region is chosen.
    <LI><B>Merge:</B> Merge a subvolume into a input volume.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags SubVolume $help
    MainHelpBuildGUI SubVolume

    #-------------------------------------------
    # Extract frame
    #-------------------------------------------
    set fExtract $Module(SubVolume,fExtract)
    set f $fExtract
    
    foreach frame "IO 3D Apply Render" {
    frame $f.f$frame -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
     #-------------------------------------------
    # Extract->I/O frame
    #-------------------------------------------   
    set f $fExtract.fIO
    
    foreach frame "Input Output" {
      frame $f.f$frame -bg $Gui(activeWorkspace)
      pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    set f $fExtract.fIO.fInput
    
    DevAddSelectButton SubVolume $f VolumeIn "Input:"   Grid "Input Volume"
    
    set f $fExtract.fIO.fOutput
    
    DevAddLabel $f.l "Output Name:"      
    eval {entry $f.e -justify right -width 10 \
          -textvariable  SubVolume(OutputName)  } $Gui(WEA)
    pack $f.l $f.e -side left -padx $Gui(pad) -pady 0
    
    #DevAddSelectButton SubVolume $f VolumeOut "Output:" Grid "Output SubVolume"
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    #lappend Volume(mbActiveList) $f.mbVolumeIn
    #lappend Volume(mbActiveList) $f.mbVolumeOut
    #lappend Volume(mActiveList) $f.mbVolumeIn.m
    #lappend Volume(mbActiveList) $f.mbVolumeOut.m

    #-------------------------------------------
    # Extract->2D frame
    #-------------------------------------------
    #set f $fExtract.f2D
    #frame $f.fLabel  -bg $Gui(activeWorkspace) -relief groove -bd 3
    #frame $f.fControl -bg $Gui(activeWorkspace) -bd 3
    #pack  \
    #      $f.fLabel \
    #      $f.fControl \
    #  -side top -padx 0 -pady 1 -fill x
    
    #set f $fExtract.f2D.fLabel
    
    #eval {label $f.l2D -text "2D"} $Gui(WLA)
    #pack $f.l2D -side left -padx $Gui(pad) -pady 0
    
    #set f $fExtract.f2D.fControl
    #grid $f.l3D -pady 2 -padx $Gui(pad)
    
    #foreach value $SubVolume(Ext2D,TypeList) width "5 5 5" {
    #    eval {radiobutton $f.r$value              \
    #      -width $width                   \
    #      -text "$value"                  \
    #      -value "$value"                 \
    #      -variable SubVolume(Ext2D,Type)  \
    #      -indicatoron 0                  \
    #      -bg $Gui(activeWorkspace)       \
    #      -fg $Gui(textDark)              \
    #      -activebackground               \
    #      $Gui(activeButton)              \
    #      -highlightthickness 0           \
    #      -bd $Gui(borderWidth)           \
    #      -selectcolor $Gui(activeButton)
        
    #    pack $f.r$value -side left -padx 2 -pady 2 -fill x
    #    }
    #}
    
    #-------------------------------------------
    # Extract->3D
    #-------------------------------------------
    set f $fExtract.f3D
    
    frame $f.fLabel  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fControl -bg $Gui(activeWorkspace) -bd 3
    pack  \
          $f.fLabel \
          $f.fControl \
      -side top -padx 0 -pady 1 -fill x
    
    set f $fExtract.f3D.fLabel
    
    eval {label $f.l3D -text "3D"} $Gui(WLA)
    pack $f.l3D -side left -padx $Gui(pad) -pady 0
    
    set fControl $fExtract.f3D.fControl
    
   #--------------------------------------------------
   foreach type "AxMin AxMax SagMin SagMax CorMin CorMax" {
     frame $fControl.f$type -bg $Gui(activeWorkspace)
   }
   pack $fControl.fAxMin $fControl.fAxMax $fControl.fSagMin $fControl.fSagMax $fControl.fCorMin $fControl.fCorMax \
        -side top -padx 0 -pady 1 -fill x
   
   foreach type "AxMin AxMax SagMin SagMax CorMin CorMax" {
     set f $fControl.f$type 
     eval {label $f.l$type -text $SubVolume(Ext3D,$type,title) -width 10 } $Gui(WLA)
   }  
   
   set f $fControl.fAxMin
   eval {button $f.bAxMin -text "Pick" -width 4 -command {SubVolumePick3D AxMin} } $Gui(WBA)
   TooltipAdd $f.bAxMin "Choose the current Axial slice"
   set f $fControl.fAxMax
   eval {button $f.bAxMax -text "Pick" -width 4 -command {SubVolumePick3D AxMax} } $Gui(WBA)
   TooltipAdd $f.bAxMax "Choose the current Axial slice"
   set f $fControl.fSagMin
   eval {button $f.bSagMin -text "Pick" -width 4 -command {SubVolumePick3D SagMin} } $Gui(WBA)
   TooltipAdd $f.bSagMin "Choose the current Sagittal slice"
   set f $fControl.fSagMax
   eval {button $f.bSagMax -text "Pick" -width 4 -command {SubVolumePick3D SagMax} } $Gui(WBA)
   TooltipAdd $f.bSagMax "Choose the current Sagittal slice"
   set f $fControl.fCorMin
   eval {button $f.bCorMin -text "Pick" -width 4 -command {SubVolumePick3D CorMin} } $Gui(WBA)
   TooltipAdd $f.bCorMin "Choose the current Coronal slice"
   set f $fControl.fCorMax
   eval {button $f.bCorMax -text "Pick" -width 4 -command {SubVolumePick3D CorMax} } $Gui(WBA)
   TooltipAdd $f.bCorMax "Choose the current Coronal slice"
        
   foreach type "AxMin AxMax SagMin SagMax CorMin CorMax" {  
     set f $fControl.f$type
     eval {entry $f.e$type -justify right -width 4 \
          -textvariable  SubVolume(Ext3D,$type)  } $Gui(WEA)

     eval {scale $f.s$type -from $SubVolume(Ext3D,$type,min) -to $SubVolume(Ext3D,$type,max)        \
          -variable  SubVolume(Ext3D,$type) -command SubVolumeUpdate3DScales \
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)

     
     #grid $f.l$type $f.b$type $f.e$type $f.s$type  -sticky w -pady 0 -padx 0    
     pack $f.l$type $f.b$type $f.e$type $f.s$type -side left -padx 0 -pady 0 -fill x
   } 
   
   #-------------------------------------------
   # Extract->Apply
   #-------------------------------------------
   set f $fExtract.fApply
    
   DevAddButton $f.bApply Apply SubVolumeApply
    
    # Tooltip example: Add a tooltip for the button
    TooltipAdd $f.bApply "Apply the subvolume extraction"

    pack $f.bApply -side top -pady $Gui(pad) -padx $Gui(pad) \
        -fill x -expand true
    
   #-------------------------------------------
   # Extract->Render
   #-------------------------------------------
   set f $fExtract.fRender
   
   eval {checkbutton $f.c3D -text "Render 3D Bounding Box" -variable SubVolume(Ext3D,RenderCube) -indicatoron 1 -command SubVolumeRenderCube} $Gui(WCA)
   pack $f.c3D -side top -pady 2 -padx 1
   
   eval {label $f.lOpacity -text "Opacity:"\
          -width 11 -justify right } $Gui(WTA)

    eval {entry $f.eOpacity -justify right -width 4 \
          -textvariable SubVolume(Ext3D,CubeOpacity)  } $Gui(WEA)

    eval {scale $f.sOpacity -from 0 -to 1     \
          -variable  SubVolume(Ext3D,CubeOpacity)\
          -orient vertical     \
          -resolution 0.1      \
      -command { SubVolume3DOpacity } \
          } $Gui(WSA)
     
     pack  $f.lOpacity $f.eOpacity $f.sOpacity -side left -padx 3 -pady 2 -expand 0
      


}

#-------------------------------------------------------------------------------
# .PROC SubVolume3DOpacity
# 
# .ARGS
# float opacity
# .END
#-------------------------------------------------------------------------------
proc SubVolume3DOpacity {opacity} {
 global SubVolume
 
 if { [info command SubVolume(Ext3D,CubeActor)] != "" } {
     eval [SubVolume(Ext3D,CubeActor) GetProperty] SetOpacity $opacity
     Render3D
 }
}

#----------------------------------------------------------------------
# .PROC SubVolumeApply
#
# .ARGS
# .END
#----------------------------------------------------------------------
proc SubVolumeApply {} {

    global SubVolume Volume
    
    set volID $SubVolume(VolumeIn)

    set x1 [expr round([lindex $SubVolume(Ext3D,Ijk) 0])]
    set x2 [expr round([lindex $SubVolume(Ext3D,Ijk) 1])]
    set y1 [expr round([lindex $SubVolume(Ext3D,Ijk) 2])]
    set y2 [expr round([lindex $SubVolume(Ext3D,Ijk) 3])]
    set z1 [expr round([lindex $SubVolume(Ext3D,Ijk) 4])]
    set z2 [expr round([lindex $SubVolume(Ext3D,Ijk) 5])]
    
  vtkExtractVOI op
  op SetInput [Volume($volID,vol) GetOutput]
  op SetVOI $x1 $x2 $y1 $y2 $z1 $z2
  op Update
 
  set newvol [SubVolumeAddMrmlImage $volID $SubVolume(OutputName)]
  set res [op GetOutput]


  $res SetExtent 0 [expr $x2-$x1] 0 [expr $y2-$y1] 0 [expr $z2-$z1]
  Volume($newvol,vol) SetImageData  $res
  # DISCONNECT the VTK PIPELINE !!!!....
  op SetOutput ""
  op Delete


    if {$::Module(verbose) == 1} {
        puts [[Volume($newvol,vol) GetOutput] GetExtent]
    }
  #Reseting the Extent so goes from 0.
  [Volume($newvol,vol) GetOutput] SetExtent 0 [expr $x2-$x1] 0 [expr $y2-$y1] 0 [expr $z2-$z1]
    if {$::Module(verbose) == 1} {
        puts [[Volume($newvol,vol) GetOutput] GetExtent]
    }

  # Set  new dimensions
  set dim [Volume($volID,node) GetDimensions]
  Volume($newvol,node) SetDimensions [expr $x2-$x1+1]  [expr $y2-$y1+1]

  # Set  new range
  set range   [Volume($volID,node) GetImageRange]
  Volume($newvol,node) SetImageRange $z1 $z2


  MainUpdateMRML
  MainVolumesUpdate $newvol

  # update matrices
  Volume($newvol,node) ComputeRasToIjkFromScanOrder [Volume($volID,node) GetScanOrder]

  # Set the RasToWld matrix
  # Ras2ToWld = Ras2ToIjk2 x Ijk2ToIjk1 x Ijk1ToRas1 x Ras1ToWld
    if {$::Module(verbose) == 1} {
        puts "Set the RasToWld matrix\n"
    }
  set ras1wld1 [Volume($volID,node)   GetRasToWld]

  # It's weird ... : I need to call SetRasToWld in order to update RasToIjk !!!
  Volume($newvol,node) SetRasToWld $ras1wld1

  MainVolumesUpdate $newvol

  MainMrmlUpdateMRML
  #
  # Add a Transform 
  #

  set tid [DataAddTransform 0 Volume($newvol,node) Volume($newvol,node)]

  #
  # Set the Transform
  #
  set n Matrix($tid,node)

  set Dx  [lindex  [Volume($volID,node) GetDimensions] 0]
  set Dy  [lindex  [Volume($volID,node) GetDimensions] 1]
  set Dz1 [lindex  [Volume($volID,node) GetImageRange] 0]
  set Dz2 [lindex  [Volume($volID,node) GetImageRange] 1]

  set dx  [lindex  [Volume($newvol,node) GetDimensions] 0]
  set dy  [lindex  [Volume($newvol,node) GetDimensions] 1]
  set dz1 [lindex  [Volume($newvol,node) GetImageRange] 0]
  set dz2 [lindex  [Volume($newvol,node) GetImageRange] 1]

  set ras2ijk2 [Volume($newvol,node) GetRasToIjk]

  vtkMatrix4x4 ijk2ijk1
  ijk2ijk1 Identity
  ijk2ijk1 SetElement 0 3 $x1
  ijk2ijk1 SetElement 1 3 $y1
  ijk2ijk1 SetElement 2 3 $z1

  vtkMatrix4x4 ijk1ras1 
  ijk1ras1 DeepCopy [Volume($volID,node) GetRasToIjk]
  ijk1ras1 Invert

  vtkMatrix4x4 ras2ras1
  ras2ras1 Identity
  ras2ras1 Multiply4x4 ijk2ijk1  $ras2ijk2  ras2ras1
  ras2ras1 Multiply4x4 ijk1ras1  ras2ras1   ras2ras1

  vtkTransform transf
  transf SetMatrix ras2ras1
  $n SetTransform transf

  MainMrmlUpdateMRML

  ijk2ijk1    Delete
  ijk1ras1    Delete
  ras2ras1    Delete
  transf      Delete
  
  return $newvol

}

#-------------------------------------------------------------------------------
# .PROC SubVolumeAddMrmlImage
# Build any vtk objects you wish here
# .ARGS
# int volID
# string resname
# .END
#-------------------------------------------------------------------------------
proc SubVolumeAddMrmlImage {volID resname } {

  global SubVolume Volume

  set newvol [DevCreateNewCopiedVolume $volID ""  $resname ]
  set node [Volume($newvol,vol) GetMrmlNode]
  Mrml(dataTree) RemoveItem $node 
  set nodeBefore [Volume($volID,vol) GetMrmlNode]
  Mrml(dataTree) InsertAfterItem $nodeBefore $node
  MainUpdateMRML

  return $newvol
}

#-------------------------------------------------------------------------------
# .PROC SubVolumeBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeBuildVTK {} {
    global SubVolume

    vtkMatrix4x4 SubVolume(tmpMatrix)
    vtkMatrix4x4 SubVolume(tmp2Matrix)

}

#-------------------------------------------------------------------------------
# .PROC SubVolumeEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeEnter {} {
    global SubVolume
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $SubVolume(eventManager)
    
    #Set all slicer windows to have slices orientation
    #MainSlicesSetOrientAll Slices
    
    #Create 3D cube
    SubVolumeCreate3DCube

    #Change welcome logo if it exits under ./image
    set modulepath $::PACKAGE_DIR_VTKSubVolume/../../../images
    if {[file exist [ExpandPath [file join \
                     $modulepath "welcome.ppm"]]]} {
        image create photo iWelcome \
        -file [ExpandPath [file join $modulepath "welcome.ppm"]]
    }    


}


#-------------------------------------------------------------------------------
# .PROC SubVolumeExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
    
    #Remove 3D Cube
    SubVolumeDelete3DCube

    #Restore standard slicer logo
    image create photo iWelcome \
        -file [ExpandPath [file join gui "welcome.ppm"]]
}

#-------------------------------------------------------------------------------
# .PROC SubVolumeUpdateGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeUpdateGUI {} {
    global SubVolume Volume

    #Hanifa
    #I changed the following line so that the GUI picks up the initial extent origin and spacing
    #values as soon as they are selected on the menu. This also required a change in Developer.tcl
    DevUpdateNodeSelectButton Volume SubVolume VolumeIn VolumeIn DevSelectNode 1 0 1 SubVolumeGetInitParams
    #DevUpdateNodeSelectButton Volume SubVolume VolumeOut VolumeOut DevSelectNode 0 1 1
}

#-------------------------------------------------------------------------------
# .PROC SubVolumeGetInitParams
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeGetInitParams {} {
    global SubVolume Volume Module    
    
    set volID $SubVolume(VolumeIn)

    set SubVolume(InOrigin) [[Volume($volID,vol) GetOutput] GetOrigin]
    set SubVolume(InSpacing) [[Volume($volID,vol) GetOutput] GetSpacing]
    set SubVolume(InExtent) [[Volume($volID,vol) GetOutput] GetExtent] 
    
    set SubVolume(OutputName) "[Volume($volID,node) GetName]_roi"
    
    set Ext $SubVolume(InExtent)
    
    SubVolume(tmpMatrix) DeepCopy [Volume($volID,node) GetWldToIjk]
    
    
    SubVolume(tmpMatrix) Invert SubVolume(tmpMatrix) SubVolume(tmpMatrix)    
    
    set IJKtoRASmin [SubVolume(tmpMatrix) MultiplyPoint [lindex $Ext 0] [lindex $Ext 2] [lindex $Ext 4] 1]
    set IJKtoRASmax [SubVolume(tmpMatrix) MultiplyPoint [lindex $Ext 1] [lindex $Ext 3] [lindex $Ext 5] 1] 
    

    if {$::Module(verbose) == 1} {
        puts $IJKtoRASmin

        puts $IJKtoRASmax
    }
            
    
    #Resort values
    foreach e "0 1 2" {
        if {[lindex $IJKtoRASmin $e] <= [lindex $IJKtoRASmax $e]} {
           lappend RASmin [lindex $IJKtoRASmin $e]
           lappend RASmax [lindex $IJKtoRASmax $e]
        } else {
           lappend RASmax [lindex $IJKtoRASmin $e]
           lappend RASmin [lindex $IJKtoRASmax $e]
        }      
   }
   
    if {$::Module(verbose) == 1} {
        puts $RASmin
        puts $RASmax 
    }

    set fExtract $Module(SubVolume,fExtract)
    
    if {$volID == $SubVolume(Ext3D,volId)} {
       #Nothing to do, same volume
    } else { 
    
       set SubVolume(Ext3D,AxMin,min) [lindex $RASmin 2]
       set SubVolume(Ext3D,AxMin,max) [lindex $RASmax 2]
       
       set SubVolume(Ext3D,AxMax,min) [lindex $RASmin 2]
       set SubVolume(Ext3D,AxMax,max) [lindex $RASmax 2]
       
       set SubVolume(Ext3D,SagMin,min) [lindex $RASmin 0]
       set SubVolume(Ext3D,SagMin,max) [lindex $RASmax 0]
       
       set SubVolume(Ext3D,SagMax,min) [lindex $RASmin 0]
       set SubVolume(Ext3D,SagMax,max) [lindex $RASmax 0]
       
       set SubVolume(Ext3D,CorMin,min) [lindex $RASmin 1]
       set SubVolume(Ext3D,CorMin,max) [lindex $RASmax 1]
       
       set SubVolume(Ext3D,CorMax,min) [lindex $RASmin 1]
       set SubVolume(Ext3D,CorMax,max) [lindex $RASmax 1] 
    
       set SubVolume(Ext3D,volId) $volID
       
       foreach type "AxMin AxMax SagMin SagMax CorMin CorMax" {
         $fExtract.f3D.fControl.f$type.s$type configure -from $SubVolume(Ext3D,$type,min) -to $SubVolume(Ext3D,$type,max)
       }
       
       set SubVolume(Ext3D,AxMin) [lindex $RASmin 2]
       set SubVolume(Ext3D,AxMax) [lindex $RASmax 2]
       set SubVolume(Ext3D,SagMax) [lindex $RASmax 0]
       set SubVolume(Ext3D,SagMin) [lindex $RASmin 0]
       set SubVolume(Ext3D,CorMin) [lindex $RASmin 1]
       set SubVolume(Ext3D,CorMax) [lindex $RASmax 1]
    }

 SubVolumeRenderCube  

}

#-------------------------------------------------------------------------------
# .PROC SubVolumePick3D
# 
# .ARGS
# string type
# .END
#-------------------------------------------------------------------------------
proc SubVolumePick3D { type } {

  global SubVolume 
  set SubVolume(Ext3D,$type) [Slicer GetOffset $SubVolume(Ext3D,$type,Id)]
  SubVolumeUpdate3DScales 0
}  

#-------------------------------------------------------------------------------
# .PROC SubVolumeUpdate3DScales
# 
# .ARGS
# string notUsed not used
# .END
#-------------------------------------------------------------------------------
proc SubVolumeUpdate3DScales { notUsed } {

  global SubVolume Interactor
  
  set Ext $SubVolume(InExtent)
  
  set volID $SubVolume(VolumeIn)
  
  #Convert RAS ext to ijk ext
  
  SubVolume(tmpMatrix) DeepCopy [Volume($volID,node) GetWldToIjk]
    
  #   set val [Volume($volID,node) GetRasToVtkMatrix]
  #  foreach r "0 1 2 3" {
  #     foreach c "0 1 2 3" {
  #       SubVolume(tmpMatrix) SetElement $r $c [lindex $val [expr 4*$r + $c]]
  #      }
  #  }    
  
  set RAStoIJKmin [SubVolume(tmpMatrix) MultiplyPoint $SubVolume(Ext3D,SagMin) $SubVolume(Ext3D,CorMin) $SubVolume(Ext3D,AxMin) 1]
  set RAStoIJKmax [SubVolume(tmpMatrix) MultiplyPoint $SubVolume(Ext3D,SagMax) $SubVolume(Ext3D,CorMax) $SubVolume(Ext3D,AxMax) 1]
  
  
  
  foreach e "0 1 2" {
        if {[lindex $RAStoIJKmin $e] <= [lindex $RAStoIJKmax $e]} {
           lappend IJKmin [lindex $RAStoIJKmin $e]
           lappend IJKmax [lindex $RAStoIJKmax $e]
        } else {
           lappend IJKmax [lindex $RAStoIJKmin $e]
           lappend IJKmin [lindex $RAStoIJKmax $e]
        }      
   }
   
  set SubVolume(Ext3D,Ijk) "[lindex $IJKmin 0] [lindex $IJKmax 0] [lindex $IJKmin 1] [lindex $IJKmax 1] [lindex $IJKmin 2] [lindex $IJKmax 2]"

    if {$::Module(verbose) == 1} {
        puts $SubVolume(Ext3D,Ijk)
    }
  
    if { [info command SubVolume(Ext3D,CubeActor)] == "" } {
        return
    }

  
  if {$SubVolume(Ext3D,RenderCube) == 1} {
                           #[expr [lindex $Ext 1] - $SubVolume(Ext3D,SagMax)] \
               #[expr [lindex $Ext 1] - $SubVolume(Ext3D,SagMin)] \

    SubVolume(Ext3D,Cube) SetBounds \
               $SubVolume(Ext3D,SagMin) $SubVolume(Ext3D,SagMax) \
               $SubVolume(Ext3D,CorMin) $SubVolume(Ext3D,CorMax) \
               $SubVolume(Ext3D,AxMin) $SubVolume(Ext3D,AxMax)
                 
    #SubVolume(Ext3D,CubeXform) SetMatrix [[$Interactor(activeSlicer) GetBackReformat 0] GetWldToIjkMatrix]
    #vtkMatrix4x4 tmp
    #tmp DeepCopy [Volume($SubVolume(VolumeIn),node) GetWldToIjk]
    #Flip y
    #tmp SetElement 0 0 [expr -1.0 * [tmp GetElement 0 0]]
    #vtkMatrix4x4 tmp2
    #tmp2 Identity
    #tmp2 SetElement 1 1 1
    
    #tmp2 Multiply4x4 tmp2 tmp tmp2
    #tmp Delete
    #tmp2 Delete
    
    SubVolume(tmp2Matrix) Identity
    
    SubVolume(Ext3D,CubeXform) SetMatrix SubVolume(tmp2Matrix)
    SubVolume(Ext3D,CubeXform) Inverse
    
    SubVolume(Ext3D,XformFilter) SetTransform SubVolume(Ext3D,CubeXform)
  
    SubVolume(Ext3D,CubeMapper) Update
    SubVolume(Ext3D,OutlineMapper) Update
  
    eval [SubVolume(Ext3D,CubeActor) GetProperty] SetColor $SubVolume(Ext3D,CubeColor)
    eval [SubVolume(Ext3D,CubeActor) GetProperty] SetOpacity $SubVolume(Ext3D,CubeOpacity)
    
    eval [SubVolume(Ext3D,OutlineActor) GetProperty] SetColor $SubVolume(Ext3D,OutlineColor)
    eval [SubVolume(Ext3D,OutlineActor) GetProperty] SetOpacity $SubVolume(Ext3D,OutlineOpacity)  
  
  } else {
    eval [SubVolume(Ext3D,CubeActor) GetProperty] SetOpacity 0
    eval [SubVolume(Ext3D,OutlineActor) GetProperty] SetOpacity 0
  }  
  Render3D 

}



#-------------------------------------------------------------------------------
# .PROC SubVolumeCreate3DCube
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeCreate3DCube {} {

  global SubVolume
  
  vtkCubeSource SubVolume(Ext3D,Cube)
  vtkOutlineFilter SubVolume(Ext3D,Outline)
  vtkTubeFilter SubVolume(Ext3D,Tube)
  vtkTransform  SubVolume(Ext3D,CubeXform)
  vtkTransformPolyDataFilter SubVolume(Ext3D,XformFilter)
  vtkPolyDataMapper SubVolume(Ext3D,CubeMapper)
  vtkPolyDataMapper SubVolume(Ext3D,OutlineMapper)
  vtkActor SubVolume(Ext3D,CubeActor)
  vtkActor SubVolume(Ext3D,OutlineActor)
  #Create Pipeline
  
  SubVolume(Ext3D,XformFilter) SetTransform SubVolume(Ext3D,CubeXform)
  SubVolume(Ext3D,XformFilter) SetInput [SubVolume(Ext3D,Cube) GetOutput]
  SubVolume(Ext3D,Outline) SetInput [SubVolume(Ext3D,XformFilter) GetOutput]
  SubVolume(Ext3D,Tube) SetInput [SubVolume(Ext3D,Outline) GetOutput]
  SubVolume(Ext3D,Tube) SetRadius 0.1
  SubVolume(Ext3D,CubeMapper) SetInput [SubVolume(Ext3D,XformFilter) GetOutput]
  SubVolume(Ext3D,CubeActor) SetMapper SubVolume(Ext3D,CubeMapper)
  SubVolume(Ext3D,OutlineMapper) SetInput [SubVolume(Ext3D,Tube) GetOutput]
  SubVolume(Ext3D,OutlineActor) SetMapper SubVolume(Ext3D,OutlineMapper)
  #Set up default Actor properties
  eval "[SubVolume(Ext3D,CubeActor) GetProperty] SetColor" $SubVolume(Ext3D,CubeColor)
  eval "[SubVolume(Ext3D,CubeActor) GetProperty] SetOpacity" 0
  SubVolume(Ext3D,CubeActor) PickableOff
  eval "[SubVolume(Ext3D,OutlineActor) GetProperty] SetColor" $SubVolume(Ext3D,OutlineColor)
  eval "[SubVolume(Ext3D,OutlineActor) GetProperty] SetOpacity" 0
  SubVolume(Ext3D,OutlineActor) PickableOff
  
  
  #Add to the renderer
  MainAddActor SubVolume(Ext3D,CubeActor)
  MainAddActor SubVolume(Ext3D,OutlineActor)

}

#-------------------------------------------------------------------------------
# .PROC SubVolumeDelete3DCube
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeDelete3DCube {} {
  
  MainRemoveActor SubVolume(Ext3D,CubeActor)
  MainRemoveActor SubVolume(Ext3D,OutlineActor)
  Render3D
  
  #Delete Objects
  SubVolume(Ext3D,Cube) Delete
  SubVolume(Ext3D,Outline) Delete
  SubVolume(Ext3D,Tube) Delete
  SubVolume(Ext3D,CubeXform) Delete
  SubVolume(Ext3D,XformFilter) Delete
  SubVolume(Ext3D,CubeMapper) Delete
  SubVolume(Ext3D,CubeActor) Delete
  SubVolume(Ext3D,OutlineMapper) Delete
  SubVolume(Ext3D,OutlineActor) Delete
}  

#-------------------------------------------------------------------------------
# .PROC SubVolumeRenderCube
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc SubVolumeRenderCube { } {

  global SubVolume
  
  if { $SubVolume(Ext3D,RenderCube) == 1} {
    SubVolumeUpdate3DScales 0
  } else {
    eval [SubVolume(Ext3D,CubeActor) GetProperty] SetOpacity 0
    eval [SubVolume(Ext3D,OutlineActor) GetProperty] SetOpacity 0
    Render3D  
  }
}
