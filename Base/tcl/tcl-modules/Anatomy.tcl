#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Anatomy.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:57 $
#   Version:   $Revision: 1.13 $
# 
#===============================================================================
# FILE:        Anatomy.tcl
# PROCEDURES:  
#   AnatomyInit
#   AnatomyBuildGUI
#   AnatomyEnter
#   AnatomyGenerate
#   AnatomyInitalizeViewList
#   AnatomyAddView
#   AnatomyAddCustomView
#   AnatomyAddCustomViewOk
#   AnatomyDeleteView
#   AnatomyDeleteView
#   AnatomyWriteHTML
#   AnatomyFindViewDims
#   AnatomyWriteHierarchyTemplate
#   AnatomyWriteHR
#   AnatomySaveViews
#   AnatomyGenIntensityImages
#   AnatomyGenDepthImages
#   AnatomyGenPartInt
#   AnatomyGenPartDepth
#   AnatomySetCameraPosition
#   AnatomyInitCamera
#   AnatomyFindBounds
#   AnatomySaveColors
#   AnatomyGetModelActors
#   AnatomyGenerateLabelMaps
#   AnatomyShrinkWindow
#   AnatomyRestoreWindow
#   AnatomySelectVolume
#   AnatomySelectLabelMap
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC AnatomyInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnatomyInit {} {
    global Anatomy Module Volume Model
    
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
    #   
    #   row1List = list of ID's for tabs. (ID's must be unique single words)
    #   row1Name = list of Names for tabs. (Names appear on the user interface
    #              and can be non-unique with multiple words.)
    #   row1,tab = ID of initial tab
    #   row2List = an optional second row of tabs if the first row is too small
    #   row2Name = like row1
    #   row2,tab = like row1 
    #
    set m Anatomy
    set Module($m,row1List) "Help Anatomy"
    set Module($m,row1Name) "{Help} {Anatomy}"
    set Module($m,row1,tab) Anatomy

    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Export scenes to Anatomy Browser (SPL program)"
    set Module($m,author) "Arne Hans, SPL, ahans@bwh.harvard.edu"
    set Module($m,category) "IO"

    # Define Procedures
    #------------------------------------
    # Description:
    #   The Slicer sources all *.tcl files, and then it calls the Init
    #   functions of each module, followed by the VTK functions, and finally
    #   the GUI functions. A MRML function is called whenever the MRML tree
    #   changes due to the creation/deletion of nodes.
    #   
    #   While the Init procedure is required for each module, the other 
    #   procedures are optional.  If they exist, then their name (which
    #   can be anything) is registered with a line like this:
    #
    #   set Module($m,procVTK) AnatomyBuildVTK
    #
    #   All the options are:
    #
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
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) AnatomyBuildGUI
    set Module($m,procEnter) AnatomyEnter

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
        {$Revision: 1.13 $} {$Date: 2006/01/06 17:56:57 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
    set Anatomy(actors) 0

    
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
# .PROC AnatomyBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc AnatomyBuildGUI {} {
    global Gui Anatomy Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Anatomy" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(Anatomy,fAnatomy)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Anatomy
    #   Bottom
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The Anatomy module allows you to create files for the SPL Anatomy Browser
    directly out of your Slicer scene. You have to enter a name for the scene that
    will be created, and you also have to supply and output and a temporary directory.<BR>
    The temporary directory will be filled with lots of data, but you can delete its
    contents after you have created your scene.<BR>
    The volume and label map selectors give you the possibility to choose the volume and
    the label map that Anatomy Browser should display.<BR>
    If you use a label map you HAVE TO make sure that your labels match the model order
    inside the MRML file and that you have consecutive label numbers! Otherwise your
    scene won't load in Anatomy Browser.<BR>
    The \"Shrink!\" and \"Restore window\" buttons offer an easy way to change the
    3D window size to the 384x384 pixels standard of Anatomy Browser.
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags Anatomy $help
    MainHelpBuildGUI Anatomy
    
    #-------------------------------------------
    # Anatomy frame
    #-------------------------------------------
    set fAnatomy $Module(Anatomy,fAnatomy)
    set f $fAnatomy
    
    frame $f.fBottom -bg $Gui(activeWorkspace)
    pack $f.fBottom -side top -padx 0 -pady $Gui(pad) -fill x

    
    #-------------------------------------------
    # Anatomy->Bottom frame
    #-------------------------------------------
    set f $fAnatomy.fBottom
    
    frame $f.f1 -bg $Gui(activeWorkspace)
    frame $f.f2 -bg $Gui(activeWorkspace)
    frame $f.f3 -bg $Gui(activeWorkspace)
    frame $f.f4 -bg $Gui(activeWorkspace)
    
    pack $f.f1 $f.f2 $f.f3 $f.f4 -fill x -expand true
         
    eval {label $f.f1.lName -text "Scene name:"} $Gui(WLA)
    eval {entry $f.f1.eName} $Gui(WEA)
    eval {label $f.f1.lHtml -text "Output directory:"} $Gui(WLA)
    eval {entry $f.f1.eHtml} $Gui(WEA)
    $f.f1.eHtml insert 1 "/"
    eval {label $f.f1.lTemp -text "Directory for temporary files:"} $Gui(WLA)
    eval {entry $f.f1.eTemp} $Gui(WEA)
    $f.f1.eTemp insert 1 "/"
    eval {label $f.f2.lVolume -text "Volume:"} $Gui(WLA)
    eval {menubutton $f.f2.mbVolume -text "Select" -menu $f.f2.mbVolume.m} $Gui(WMBA)
    eval {menu $f.f2.mbVolume.m} $Gui(WMA)
    eval {label $f.f2.lLabelMap -text "Label map:"} $Gui(WLA)
    eval {menubutton $f.f2.mbLabel -text "Select" -menu $f.f2.mbLabel.m} $Gui(WMBA)
    eval {menu $f.f2.mbLabel.m} $Gui(WMA)
    set Anatomy(fList) [ScrolledListbox $f.f4.fList 0 0 -height 6 -selectmode extended]
    bind $Anatomy(fList) <Double-1> {AnatomyChangeView}
    
    DevAddButton $f.f4.bGenerate "Go!" AnatomyGenerate
    DevAddButton $f.f4.bAdd "Add" AnatomyAddCustomView
    DevAddButton $f.f4.bDelete "Delete" AnatomyDeleteView
    DevAddButton $f.f3.bShrink "Shrink" AnatomyShrinkWindow
    DevAddButton $f.f3.bRestore "Restore window" AnatomyRestoreWindow
        
    pack $f.f1.lName $f.f1.eName $f.f1.lHtml $f.f1.eHtml $f.f1.lTemp $f.f1.eTemp -side top -fill x -expand true -padx $Gui(pad) -pady $Gui(pad)
    pack $f.f2.lVolume $f.f2.mbVolume $f.f2.lLabelMap $f.f2.mbLabel -side left -padx $Gui(pad) -pady $Gui(pad)
    pack $f.f3.bShrink $f.f3.bRestore -side left -padx $Gui(pad) -pady $Gui(pad)
    pack $f.f4.fList -padx $Gui(pad) -pady $Gui(pad)
    pack $f.f4.bAdd $f.f4.bDelete $f.f4.bGenerate -side left -padx $Gui(pad) -pady $Gui(pad)
    
    set Anatomy(fMain) $f
    set Anatomy(volumeID) 0
    set Anatomy(labelID) 0
}


#-------------------------------------------------------------------------------
# .PROC AnatomyEnter
# 
# .END
#-------------------------------------------------------------------------------
proc AnatomyEnter {} {
    global Anatomy Volume View
    
    # refresh volume und labelmap selection boxes
    $Anatomy(fMain).f2.mbVolume.m delete 0 last
    $Anatomy(fMain).f2.mbLabel.m delete 0 last

    foreach v $Volume(idList) {
        $Anatomy(fMain).f2.mbVolume.m add command -label "[Volume($v,node) GetName]" -command "AnatomySelectVolume $v"
        $Anatomy(fMain).f2.mbLabel.m add command -label "[Volume($v,node) GetName]" -command "AnatomySelectLabelMap $v"
    }
    
    $Anatomy(fList) delete 0 end
    set Anatomy(initFocal) [$View(viewCam) GetFocalPoint]
    AnatomyGetModelActors
    AnatomyInitializeViewList
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGenerate
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyGenerate {} {
    global Anatomy View Path Volume
    
    set Anatomy(modelName) [$Anatomy(fMain).f1.eName get]
    set Anatomy(startIndex) 0
    set Anatomy(initFocal) [$View(viewCam) GetFocalPoint]
    set Anatomy(htmlDir) [$Anatomy(fMain).f1.eHtml get]
    set Anatomy(tmpDir) [$Anatomy(fMain).f1.eTemp get]
    set Anatomy(hrTemplate) "$Anatomy(tmpDir)/$Anatomy(modelName).hierarchy"

    puts "--- START ---"
    
    AnatomyGetModelActors
    #AnatomyInitializeViewList
    AnatomyWriteHierarchyTemplate
    AnatomyWriteHR

    # generate slices (if needed)
    
    if {($Anatomy(volumeID) != 0) && ($Anatomy(volumeID) != $Volume(idNone))} {
        puts "Generating slices..."
            
        # find out the header size
        scan [Volume($Anatomy(volumeID),node) GetDimensions] "%d %d" x y
        set filePattern [Volume($Anatomy(volumeID),node) GetFilePattern]
        set filePrefix [Volume($Anatomy(volumeID),node) GetFullPrefix]
        set imageRange [Volume($Anatomy(volumeID),node) GetImageRange]
        set filename [format $filePattern $filePrefix [lindex $imageRange 0]]
        set headerSize [expr [file size $filename] - ($x * $y * 2)]
        
        set sliceCount [eval exec ./bin/resample_volume \
            "[Volume($Anatomy(volumeID),node) GetFullPrefix]" \
            "$Anatomy(htmlDir)/slices/$Anatomy(modelName)" \
            $headerSize 2 [Volume($Anatomy(volumeID),node) GetLittleEndian] \
            "[Volume($Anatomy(volumeID),node) GetFilePattern]" \
            [Volume($Anatomy(volumeID),node) GetScanOrder] \
            [Volume($Anatomy(volumeID),node) GetDimensions] \
            $imageRange \
            [Volume($Anatomy(volumeID),node) GetSpacing] \
            [Volume($Anatomy(volumeID),node) GetWindow] [Volume($Anatomy(volumeID),node) GetLevel]]
        scan $sliceCount "%d %d %d %d %d %d %d %d %d" \
            Anatomy(corWidth) Anatomy(corHeight) Anatomy(corSlices) \
            Anatomy(sagWidth) Anatomy(sagHeight) Anatomy(sagSlices) \
            Anatomy(axWidth) Anatomy(axHeight) Anatomy(axSlices)
    
        puts "Converting slices..."
    
        eval exec ./bin/convert_slices "$Anatomy(htmlDir)/slices/$Anatomy(modelName)" >/dev/null 2>/dev/null
        
        # generate label maps (if possible)
        
        if {($Anatomy(labelID) != 0) && ($Anatomy(labelID) != $Volume(idNone))} {
            puts "Generating label maps..."
            # find out the header size
            scan [Volume($Anatomy(labelID),node) GetDimensions] "%d %d" x y
            set filePattern [Volume($Anatomy(labelID),node) GetFilePattern]
            set filePrefix [Volume($Anatomy(labelID),node) GetFullPrefix]
            set imageRange [Volume($Anatomy(labelID),node) GetImageRange]
            set filename [format $filePattern $filePrefix [lindex $imageRange 0]]
            set headerSize [expr [file size $filename] - ($x * $y * 2)]
            
            puts [eval exec ./bin/resample_volume \
                "[Volume($Anatomy(labelID),node) GetFullPrefix]" \
                "$Anatomy(htmlDir)/slices/$Anatomy(modelName)" \
                $headerSize 2 [Volume($Anatomy(labelID),node) GetLittleEndian] \
                "[Volume($Anatomy(labelID),node) GetFilePattern]" \
                [Volume($Anatomy(labelID),node) GetScanOrder] \
                [Volume($Anatomy(labelID),node) GetDimensions] \
                $imageRange \
                [Volume($Anatomy(labelID),node) GetSpacing] \
                "labelmaps"]
        } else {
            puts "No label map selected. Generating blank label maps..."
            AnatomyGenerateLabelMaps $Anatomy(htmlDir)/slices/$Anatomy(modelName) $Anatomy(volumeID)
        }
    } else {
        puts "No grayscale images created..."
    }
    
    # start saving the models
    
    set tmp_size [viewRen GetSize]
    set Anatomy(imageWidth) [lindex $tmp_size 0]
    set Anatomy(imageHeight) [lindex $tmp_size 1]
      
      RenderAll

      # do all the images...
      puts "Generating intensity images..."
      AnatomyGenIntensityImages $Anatomy(tmpDir)/$Anatomy(modelName)
      puts "Generating depth images..."
      AnatomyGenDepthImages $Anatomy(tmpDir)/$Anatomy(modelName)
    
      set nameList ""
      for {set i 0}  {$i < [llength $Anatomy(viewList)]} {incr i} {
            set nameList "$nameList [lindex [lindex $Anatomy(viewList) $i] 3]"
      }
  
      puts "Generating 3D images..."
        #eval exec $Path(program)/bin/make3d \
            $Anatomy(modelName) $Anatomy(modelName) \
            [[viewRen GetActors] GetNumberOfItems] $nameList
        eval exec ./bin/make3d \
            "$Anatomy(tmpDir)/$Anatomy(modelName)" "$Anatomy(htmlDir)/models/$Anatomy(modelName)" \
            [AnatomyActors GetNumberOfItems] $nameList
  
      AnatomyWriteHTML $Anatomy(tmpDir)/$Anatomy(modelName).log

      puts "3D view generation complete."
      
      greylut Delete
      
      MainUpdateMRML
      AnatomyInitCamera
      RenderAll
      
      puts "--- STOP ---"
}


#-------------------------------------------------------------------------------
# .PROC AnatomyInitalizeViewList
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyInitializeViewList {} {
    global View Anatomy_editCamera Anatomy
    
    set Anatomy(initPosition) [$View(viewCam) GetPosition]
    set Anatomy(initScale) [$View(viewCam) GetParallelScale]
    set Anatomy(viewList) [list]
    set Anatomy(visList) [list]
    
    # front
    array set Anatomy_editCamera [list 0 0 1 0 2 0 3 0]
    set Anatomy(newViewName) "FRONT"
    AnatomyAddView
    
    # back
    array set Anatomy_editCamera [list 0 180 1 0 2 0 3 0]
    AnatomySetCameraPosition -1
    set Anatomy(newViewName) "BACK"
    AnatomyAddView
    
    # left
    array set Anatomy_editCamera [list 0 90 1 0 2 0 3 0]
    AnatomySetCameraPosition -1
    set Anatomy(newViewName) "LEFT"
    AnatomyAddView
    
    # right
    array set Anatomy_editCamera [list 0 -90 1 0 2 0 3 0]
    AnatomySetCameraPosition -1
    set Anatomy(newViewName) "RIGHT"
    AnatomyAddView
    
    # top
    array set Anatomy_editCamera [list 0 0 1 90 2 180 3 0]
    AnatomySetCameraPosition -1
    set Anatomy(newViewName) "TOP"
    AnatomyAddView
    
    # bottom
    array set Anatomy_editCamera [list 0 0 1 -90 2 0 3 0]
    AnatomySetCameraPosition -1
    set Anatomy(newViewName) "BOTTOM"
    AnatomyAddView
    
    array set Anatomy_editCamera [list 0 0 1 0 2 0 3 0]
    AnatomySetCameraPosition -1
}    


#-------------------------------------------------------------------------------
# .PROC AnatomyAddView
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyAddView {} {
    #global Anatomy_editCamera Anatomy
    global View Anatomy
    
    #set tmp [list $Anatomy_editCamera(0) $Anatomy_editCamera(1) $Anatomy_editCamera(2) $Anatomy_editCamera(3) $Anatomy(newViewName)]
    set tmp [list [$View(viewCam) GetPosition] [$View(viewCam) GetFocalPoint] [$View(viewCam) GetViewUp] $Anatomy(newViewName)]
    lappend Anatomy(viewList) $tmp
    
    set tmp [list]
    AnatomyActors InitTraversal
    for {set i 0} {$i<[AnatomyActors GetNumberOfItems]} {incr i} {
        lappend tmp [[AnatomyActors GetNextItem] GetVisibility]
    }
    
    lappend Anatomy(visList) $tmp
    $Anatomy(fList) insert end $Anatomy(newViewName)
}


#-------------------------------------------------------------------------------
# .PROC AnatomyAddCustomView
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyAddCustomView {} {
    global Gui

    if {[winfo exists .askforname] == 0} {
        toplevel .askforname -class Dialog -bg $Gui(activeWorkspace)
        wm title .askforname "New view"
        eval {label .askforname.l1 -text "Enter the name of the new view:"} $Gui(WLA)
        eval {entry .askforname.e1} $Gui(WEA)
        eval {button .askforname.bOk -text "Ok" -width 8 -command "AnatomyAddCustomViewOk"} $Gui(WBA)
        eval {button .askforname.bCancel -text "Cancel" -width 8 -command "destroy .askforname"} $Gui(WBA)
        grid .askforname.l1
        grid .askforname.e1
        grid .askforname.bOk .askforname.bCancel -padx 5 -pady 3
        
        # make the dialog modal
        update idle
        grab set .askforname
        tkwait window .askforname
        grab release .askforname
    }
}


#-------------------------------------------------------------------------------
# .PROC AnatomyAddCustomViewOk
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AnatomyAddCustomViewOk {} {
    global Anatomy Anatomy_editCamera
    
    set Anatomy(newViewName) [.askforname.e1 get]
    destroy .askforname
    
    AnatomyAddView
}


#-------------------------------------------------------------------------------
# .PROC AnatomyDeleteView
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyDeleteView {} {
      global Anatomy

      set viewSelected [$Anatomy(fList) curselection]
      
      if {$viewSelected == ""} {
          DevErrorWindow "No view selected."
          return
      }

      for {set i 0} {$i < [llength $viewSelected]} {incr i} {
            set k [lindex $viewSelected $i]
            set Anatomy(viewList) [lreplace $Anatomy(viewList) $k $k]
            set Anatomy(visList) [lreplace $Anatomy(visList) $k $k]
            $Anatomy(fList) delete $k $k
  }
}


#-------------------------------------------------------------------------------
# .PROC AnatomyDeleteView
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyChangeView {} {
    global Anatomy View
    
    set viewSelected [$Anatomy(fList) curselection]
    
    if {$viewSelected == ""} {
        DevErrorWindow "No view selected."
        return
    }
    
    if {[llength $viewSelected] > 1} {
        DevErrorWindow "Please select only one view."
        return
    }
    
          set tmp [lindex $Anatomy(viewList) [lindex $viewSelected 0]]
          set camList [list]
          for {set k 0} {$k < 4} {incr k} { 
         lappend camList $k
         lappend camList [lindex $tmp $k]
          }

          array set Anatomy_editCamera $camList
          array set Anatomy_editCameraPrev $camList
          set camPos $Anatomy_editCamera(0)
          set camFP $Anatomy_editCamera(1)
          set camVU $Anatomy_editCamera(2)
          $View(viewCam) SetPosition [lindex $camPos 0] [lindex $camPos 1] [lindex $camPos 2]
          $View(viewCam) SetFocalPoint [lindex $camFP 0] [lindex $camFP 1] [lindex $camFP 2]
          $View(viewCam) SetViewUp [lindex $camVU 0] [lindex $camVU 1] [lindex $camVU 2]
          
          Render3D
}


#-------------------------------------------------------------------------------
# .PROC AnatomyWriteHTML
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyWriteHTML {{filename ""}} {
    global Anatomy Volume
    
    puts "....HTML...."
    set id [open $Anatomy(htmlDir)/$Anatomy(modelName).html w]
    
    puts $id "<html>\n<head>\n<title>SPL Anatomy Browser</title>\n</head>"
    puts $id "<body>\n<center>"
    puts $id "<h1>SPL/NSL Anatomy Browser</h1>"
    puts $id "<applet code=\"BB.class\" archive=\"AnatomyBrowser.jar\" width=1024 height=900>"

    puts $id "\n\t<!-- Hierarchy text file -->"
    puts $id "\t\t<param name=\"HFILE\" value=\"$Anatomy(modelName).hr\">"

    puts $id "\n\t<!-- 3D images -->"
    puts $id "\t\t<param name=\"IMAGENAME\" value=\"models/$Anatomy(modelName)\">"
    
    puts -nonewline $id "\t\t<param name=\"VIEWNAMES\" value=\""
    for {set i 0} {$i<[llength $Anatomy(viewList)]} {incr i} {
        puts -nonewline $id "[lindex [lindex $Anatomy(viewList) $i] 3] "
    }
    puts $id "\">"
    
    puts $id "\t\t<param name=\"IMAGEWIDTH\" value=\"$Anatomy(imageWidth)\">"
    puts $id "\t\t<param name=\"IMAGEHEIGHT\" value=\"$Anatomy(imageHeight)\">"
    
    puts $id "\n\t<!-- Slices -->"
    puts $id "\t\t<param name=\"SLICENAME\" value=\"slices/$Anatomy(modelName)\">"
    puts $id "\t\t<param name=\"SLICEORDER\" value=\"$Volume(scanOrder)\">"
    puts $id "\t\t<param name=\"SLICEWIDTH\" value=\"$Volume(width)\">"
    puts $id "\t\t<param name=\"SLICEHEIGHT\" value=\"$Volume(height)\">"
    puts $id "\t\t<!-- total number of slices in acquisition -->"
    puts $id "\t\t<param name=\"NUMBERSLICES\" value=\"$Volume(lastNum)\">"
    puts $id "\t\t<!-- in-slice pixel dimensions -->"
    puts $id "\t\t<param name=\"PIXELWIDTH\" value=\"$Volume(pixelWidth)\">"
    puts $id "\t\t<param name=\"PIXELHEIGHT\" value=\"$Volume(pixelHeight)\">"
    puts $id "\t\t<!-- slice spacing -->"
    puts $id "\t\t<param name=\"PIXELZ\" value=\"[expr $Volume(sliceThickness)+$Volume(sliceSpacing)]\">"
    
    puts $id "\n\t<!-- World coordinates of the generated views -->"
    puts $id "\t\t<param name=\"VIEW_WIDTH\" value=\"[lindex [AnatomyFindViewDims] 0]\">"
    puts $id "\t\t<param name=\"VIEW_HEIGHT\" value=\"[lindex [AnatomyFindViewDims] 1]\">"
    puts $id "\t\t<param name=\"FOCALX\" value=\"[expr -[lindex $Anatomy(initFocal) 0]]\">"
    puts $id "\t\t<param name=\"FOCALY\" value=\"[expr -[lindex $Anatomy(initFocal) 2]]\">"
    puts $id "\t\t<param name=\"FOCALZ\" value=\"[expr -[lindex $Anatomy(initFocal) 1]]\">"
    
    if {[string compare $filename ""] != 0} {
        set logId [open $filename r]
        set str [gets $logId]
        close $logId
        puts $id "\t\t<param name=\"3D_FILE_SIZE\" value=\"$str\">"
    }
    
       puts $id "\t\t<param name=\"PART_COUNT\" value=\"[AnatomyActors GetNumberOfItems]\">"
    puts $id "\t\t<param name=\"MODEL_RADIUS\" value=\"$Anatomy(modelRadius)\">"
   
       puts $id "\t\t<param name=\"VIEW_VECTOR\" value=\"$Anatomy(viewVector)\">"
       puts $id "\t\t<param name=\"UP_VECTOR\" value=\"$Anatomy(upVector)\">"
       puts $id "\t\t<param name=\"IMAGE_SCALE\" value=\"$Anatomy(imageScale)\">"
   
       puts $id "\n</applet>\n</center>\n</body>\n</html>"

       close $id
}


#-------------------------------------------------------------------------------
# .PROC AnatomyFindViewDims
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyFindViewDims {} {

    RenderAll
    viewRen SetDisplayPoint 0 0 0
    viewRen DisplayToWorld
    set temp [viewRen GetWorldPoint]
    set vleft [lindex $temp 0]
    set vbottom [lindex $temp 2]
    set imageDims [[viewRen GetRenderWindow] GetSize]

    viewRen SetDisplayPoint [lindex $imageDims 0] [lindex $imageDims 1]  0
    viewRen DisplayToWorld
    set temp [viewRen GetWorldPoint]
    set vright [lindex $temp 0]
    set vtop [lindex $temp 2]

    return [list [expr $vleft - $vright] [expr $vtop - $vbottom]]
}


#-------------------------------------------------------------------------------
# .PROC AnatomyWriteHierarchyTemplate
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyWriteHierarchyTemplate {} {
    global Anatomy Color
    
    set id [open $Anatomy(hrTemplate) w]
    Mrml(dataTree) InitTraversal
    set write_groups ""
    
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        if {[string equal -length 10 $node "ModelGroup"] == 1} {
            lappend write_groups $node
        }
        set node [Mrml(dataTree) GetNextItem]
    }
    
    foreach node $write_groups {
        puts -nonewline $id "\["
        regsub -all " " [$node GetName] "_" name
        puts -nonewline $id $name
        puts -nonewline $id "\] "
        set color_name [$node GetColor]
    
        set colorid 1
        foreach c $Color(idList) {
            if {[Color($c,node) GetName] == $color_name} {
                set colorid $c
            }
        }
        set color [Color($colorid,node) GetDiffuseColor]
        puts $id "[lindex $color 0] [lindex $color 1] [lindex $color 2]"
        
        SharedGetModelGroupsInGroup [$node GetID] modelgroups
        foreach mg $modelgroups {
            regsub -all " " [ModelGroup($mg,node) GetName] "_" name
            puts $id "? $name"
        }
        SharedGetModelsInGroupOnly [$node GetID] models
        foreach m $models {
            regsub -all " " [Model($m,node) GetName] "_" name
            puts $id "x $name"
        }
        puts $id ""
    }
    close $id
}

#-------------------------------------------------------------------------------
# .PROC AnatomyWriteHR
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyWriteHR {} {
    global Anatomy Path
    
    set colorName $Anatomy(tmpDir)/color.model
      AnatomySaveColors $colorName

      if {$Anatomy(hrTemplate) == ""} {
              exec ./bin/write_hr $colorName \
              [AnatomyActors GetNumberOfItems] \
              $Anatomy(htmlDir)/$Anatomy(modelName).hr
      } else {
            exec ./bin/write_hr $colorName \
            [AnatomyActors GetNumberOfItems] \
            $Anatomy(htmlDir)/$Anatomy(modelName).hr $Anatomy(hrTemplate)
      }
}


#-------------------------------------------------------------------------------
# .PROC AnatomySaveViews
#
# .END
#-------------------------------------------------------------------------------
proc AnatomySaveViews { name procedure } {
      global Anatomy Anatomy_editCamera Anatomy_editCameraPrev View

      set Anatomy(viewVector) [list]
      set Anatomy(upVector) [list]
      set Anatomy(imageScale) [list]
      for {set i 0} {$i < [llength $Anatomy(viewList)]} {incr i} {
              set tmp [lindex $Anatomy(viewList) $i]
              set camList [list]
              for {set k 0} {$k < 4} {incr k} {
             lappend camList $k
             lappend camList [lindex $tmp $k]
              }

              array set Anatomy_editCamera $camList
              array set Anatomy_editCameraPrev $camList
              set camPos $Anatomy_editCamera(0)
              set camFP $Anatomy_editCamera(1)
              set camVU $Anatomy_editCamera(2)
              $View(viewCam) SetPosition [lindex $camPos 0] [lindex $camPos 1] [lindex $camPos 2]
              $View(viewCam) SetFocalPoint [lindex $camFP 0] [lindex $camFP 1] [lindex $camFP 2]
              $View(viewCam) SetViewUp [lindex $camVU 0] [lindex $camVU 1] [lindex $camVU 2]
              #AnatomySetCameraPosition -1
              set viewName [lindex $tmp 3]
              puts -nonewline "$viewName..."
              flush stdout
              set tmpV [$View(viewCam) GetViewPlaneNormal]
              lappend Anatomy(viewVector) [lindex $tmpV 0] [lindex $tmpV 2] [lindex $tmpV 1]
      
              set tmpV [$View(viewCam) GetViewUp]
              lappend Anatomy(upVector) [lindex $tmpV 0] [lindex $tmpV 2] [lindex $tmpV 1]
 
              lappend Anatomy(imageScale) [$View(viewCam) GetParallelScale]
              $procedure $name $viewName [lindex $Anatomy(visList) $i]
      }
      lappend Anatomy(imageScale) $Anatomy(initScale)
      puts ""
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGenIntensityImages
# 
# Generate the intensity files
# .END
#-------------------------------------------------------------------------------
proc AnatomyGenIntensityImages {name} {

      # first, set all actor colors to white 
      AnatomyActors InitTraversal
      set num [AnatomyActors GetNumberOfItems]
      for {set i 0} {$i < $num} {incr i} {
            set temp [AnatomyActors GetNextItem]
            [$temp GetProperty] SetColor 1 1 1
            [$temp GetProperty] SetOpacity 1
            $temp PickableOn
      }
      AnatomySaveViews $name AnatomyGenPartInt
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGenDepthImages
#
# Generate the depth files
# .END
#-------------------------------------------------------------------------------
proc AnatomyGenDepthImages {name} {
      global Anatomy Model
  
      vtkLookupTable greylut
      for {set i 0} {$i<256} {incr i} {
          set col [expr $i/256.0]
          greylut SetTableValue $i $col $col $col 1.0
      }
      
      # first, turn off all lights
      #set lights [viewRen GetLights]
      #$lights InitTraversal
      #for {set i 0} {$i < [$lights GetNumberOfItems]} {incr i} {
        #    [$lights GetNextItem] SetColor 0 0 0
      #}

      # next set only ambient reflection for all actors
      set num [AnatomyActors GetNumberOfItems]
      AnatomyActors InitTraversal
      for {set i 0} {$i < $num} {incr i} {
            set act [AnatomyActors GetNextItem]
            set temp [$act GetProperty]
            $temp SetAmbient 1
            $temp SetDiffuse 0
            $temp SetSpecular 0
            $temp SetSpecularPower 0
            $temp SetOpacity 1
            $temp SetColor 1 1 1
                  
            # Get the actual model data by using another variable...
            # This is kind of tricky, but I haven't found any other
            # possibility to do it
            regsub ",actor,viewRen" $act ",polyData" act_data
            
            vtkElevationFilter elvfilter$act
              elvfilter$act SetInput [set [set act_data]]

            set temp_mapper$act [$act GetMapper]
            
            vtkDataSetMapper elvmapper$act
              elvmapper$act SetLookupTable greylut
              elvmapper$act SetInput [elvfilter$act GetOutput]
            
            $act SetMapper elvmapper$act
      }

      set modelBounds [AnatomyFindBounds viewRen]
      set boundX [expr [lindex $modelBounds 1]-[lindex $modelBounds 0]]
      set boundY [expr [lindex $modelBounds 3]-[lindex $modelBounds 2]]
      set boundZ [expr [lindex $modelBounds 5]-[lindex $modelBounds 4]]
      set Anatomy(modelRadius) [expr 0.5 * \
             sqrt($boundX*$boundX+$boundY*$boundY+$boundZ*$boundZ)]

      AnatomySaveViews $name AnatomyGenPartDepth
      
      # reset mappers and delete mappers/filters
      AnatomyActors InitTraversal
      for {set i 0} {$i<$num} {incr i} {
          set act [AnatomyActors GetNextItem]
          $act SetMapper [set temp_mapper$act]
          elvmapper$act Delete
          elvfilter$act Delete
      }
      
      # turn on lights
      #$lights InitTraversal
      #for {set i 0} {$i<[$lights GetNumberOfItems]} {incr i} {
      #    [$lights GetNextItem] SetColor 1 1 1
      #}
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGenPartInt
#
# Generates intensity info for each part
# .END
#-------------------------------------------------------------------------------
proc AnatomyGenPartInt {name view visList} {
      global Anatomy viewWin

      set num [AnatomyActors GetNumberOfItems]

      for {set i 0} {$i < $num} {incr i} {

            # Switch the current actor on, the rest is off.
            AnatomyActors InitTraversal
            for { set k 0} { $k < $num} {incr k} {
                  set currentActor [AnatomyActors GetNextItem]
                  if { $k == $i } {
                    $currentActor SetVisibility [lindex $visList $i]
                  } else {
                    $currentActor SetVisibility 0
            }
            }

            set index [expr $Anatomy(startIndex) + $i]
            set filename $name.$view.intens.$index.ppm
    
            Render3D
            $viewWin SetFileName $filename
            $viewWin SaveImageAsPPM
        
            AnatomyActors InitTraversal
            for {set k 0} {$k < $num} {incr k} {
                 [AnatomyActors GetNextItem] SetVisibility 1
            }
      }
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGenPartDepth
#
# Generate depth info for each part
# .END
#-------------------------------------------------------------------------------
proc AnatomyGenPartDepth {name view visList} {
      global viewWin Anatomy
    
      set vec [[viewRen GetActiveCamera] GetViewPlaneNormal]
      set vecl [expr sqrt([lindex $vec 0]*[lindex $vec 0]+ \
                      [lindex $vec 1]*[lindex $vec 1]+ \
                      [lindex $vec 2]*[lindex $vec 2])]
      set coef [expr $Anatomy(modelRadius)/$vecl]
      set low [list [expr [lindex $Anatomy(initFocal) 0] + $coef*[lindex $vec 0]] \
                [expr [lindex $Anatomy(initFocal) 1] + $coef*[lindex $vec 1]] \
                [expr [lindex $Anatomy(initFocal) 2] + $coef*[lindex $vec 2]]]

      set high [list [expr [lindex $Anatomy(initFocal) 0] - $coef*[lindex $vec 0]] \
                 [expr [lindex $Anatomy(initFocal) 1] - $coef*[lindex $vec 1]] \
                 [expr [lindex $Anatomy(initFocal) 2] - $coef*[lindex $vec 2]]]

      set num [AnatomyActors GetNumberOfItems]

      # set actors to display scalar elevation values using greyscale LUT
      AnatomyActors InitTraversal
      for {set i 0} {$i < $num} {incr i} {
            set act [AnatomyActors GetNextItem]
            
            elvfilter$act SetLowPoint [lindex $low 0] [lindex $low 1] [lindex $low 2]
            elvfilter$act SetHighPoint [lindex $high 0] [lindex $high 1] [lindex $high 2]
            elvfilter$act SetScalarRange 0 1
      }

      for {set i 0} {$i < $num} {incr i} {
            AnatomyActors InitTraversal
            for { set k 0} { $k < $num} {incr k} {
                set currentActor [AnatomyActors GetNextItem]
                  if { $k == $i } {
                    $currentActor SetVisibility [lindex $visList $i]
                  } else {
                    $currentActor SetVisibility 0
                }
            }
        
            set index [expr $Anatomy(startIndex) + $i]
            set filename $name.$view.depth.$index.ppm
    
            Render3D
            $viewWin SetFileName $filename
            $viewWin SaveImageAsPPM

            AnatomyActors InitTraversal
            for {set k 0} {$k < $num} {incr k} {
                  [AnatomyActors GetNextItem] SetVisibility 1
            }
      }
}


#-------------------------------------------------------------------------------
# .PROC AnatomySetCameraPosition
#
# .END
#-------------------------------------------------------------------------------
proc AnatomySetCameraPosition {which} {
    global Anatomy View
        global Anatomy_editCamera Anatomy_editCameraPrev

        if {$which >= 0} {
              if {$Anatomy(cameraCallCount) < 4} {
              incr Anatomy(cameraCallCount)
              return
              }
              if {$Anatomy_editCamera($which) == $Anatomy_editCameraPrev($which)} {
             return
              }
              array set Anatomy_editCameraPrev [list $which $Anatomy_editCamera($which)]
        }
    
        AnatomyInitCamera

        $View(viewCam) Azimuth $Anatomy_editCamera(0)
        $View(viewCam) Elevation $Anatomy_editCamera(1)
        $View(viewCam) OrthogonalizeViewUp
        $View(viewCam) Roll $Anatomy_editCamera(2)

        if { $Anatomy_editCamera(3) == 0 } then {
            $View(viewCam) SetParallelScale $Anatomy(initScale)
        } elseif { $editCamera(3) < 0 } {
            $View(viewCam) SetParallelScale [expr $Anatomy(initScale)*(1.0-$Anatomy_editCamera(3)/10.0)]
        } else {
            $View(viewCam) SetParallelScale [expr $Anatomy(initScale)/(1.0+$Anatomy_editCamera(3)/10.0)]
        }

        RenderAll
}


#-------------------------------------------------------------------------------
# .PROC AnatomyInitCamera
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyInitCamera {} {
      global Anatomy View

      $View(viewCam) SetPosition [lindex $Anatomy(initPosition) 0] \
                    [lindex $Anatomy(initPosition) 1] [lindex $Anatomy(initPosition) 2]
      $View(viewCam) SetFocalPoint [lindex $Anatomy(initFocal) 0] \
                    [lindex $Anatomy(initFocal) 1] [lindex $Anatomy(initFocal) 2]
      $View(viewCam) SetViewUp 0 0 1

      $View(viewCam) SetParallelScale $Anatomy(initScale)
}


#-------------------------------------------------------------------------------
# .PROC AnatomyFindBounds
#
# Find a bounding box for all actors associated with a renderer
# .END
#-------------------------------------------------------------------------------
proc AnatomyFindBounds {theRen} {

    set num [AnatomyActors GetNumberOfItems]
    AnatomyActors InitTraversal
      set bounds [[AnatomyActors GetNextItem] GetBounds]
      for {set i 1} {$i < $num} {incr i} {
            set temp [[AnatomyActors GetNextItem] GetBounds]

            #xmin
            if {[lindex $temp 0] < [lindex $bounds 0]} then {
                  set bounds [lreplace $bounds 0 0 [lindex $temp 0]]
            }

            # ymin
            if {[lindex $temp 2] < [lindex $bounds 2]} then {
                  set bounds [lreplace $bounds 2 2 [lindex $temp 2]]
            }

            # zmin
            if {[lindex $temp 4] < [lindex $bounds 4]} then {
                  set bounds [lreplace $bounds 4 4 [lindex $temp 4]]
            }

            # xmax
            if {[lindex $temp 1] > [lindex $bounds 1]} then {
                  set bounds [lreplace $bounds 1 1 [lindex $temp 1]]
            }

            # ymax
            if {[lindex $temp 3] > [lindex $bounds 3]} then {
                  set bounds [lreplace $bounds 3 3 [lindex $temp 3]]
            }

            # zmax
            if {[lindex $temp 5] > [lindex $bounds 5]} then {
                  set bounds [lreplace $bounds 5 5 [lindex $temp 5]]
            }
      }

      return $bounds
}


#-------------------------------------------------------------------------------
# .PROC AnatomySaveColors
#
# .END
#-------------------------------------------------------------------------------
proc AnatomySaveColors {name} {
    global Model

      AnatomyGetModelActors
      set actorsCount [AnatomyActors GetNumberOfItems]

      AnatomyActors InitTraversal
      set id [open $name w]
      for {set j 0} {$j < $actorsCount} {incr j} {
            
            set act [AnatomyActors GetNextItem]
            regsub ",actor,viewRen" $act ",node" model_node
            regsub -all " " [$model_node GetName] "_" name
            set pr [$act GetProperty]
            set color [$pr GetColor]
            
            #find out the label id
            set color_id $Model([$model_node GetID],colorID)
            set label_str [Color($color_id,node) GetLabels]
            set pos [string first " " $label_str]
            if {$pos != -1} {
                set label_str [string range $label_str 0 [expr $pos-1]]
            }
            if {$label_str == ""} {
            set label_str "1"
        }
        
            puts -nonewline $id "$name [lindex $color 0] [lindex $color 1] [lindex $color 2] "
            # puts -nonewline $id "[$pr GetAmbient] [$pr GetDiffuse] [$pr GetSpecular] [$pr GetSpecularPower] "
            puts $id $label_str
      }
      close $id
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGetModelActors
# Generates a list of all actors which are models
# .END
#-------------------------------------------------------------------------------
proc AnatomyGetModelActors {} {
    global Anatomy
    
    set actors [viewRen GetActors]
    
    if {$Anatomy(actors) == 0} {
        vtkActorCollection AnatomyActors
        set Anatomy(actors) 1
    } else {
        AnatomyActors Delete
        vtkActorCollection AnatomyActors
    }
    
    set actorsCount [$actors GetNumberOfItems]
    $actors InitTraversal
    
    for {set j 0} {$j<$actorsCount} {incr j} {
        set act [$actors GetNextItem]
        if {[string equal -length 5 $act "Model"]} {
            AnatomyActors AddItem $act
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC AnatomyGenerateLabelMaps
# Generates blank label maps
# .END
#-------------------------------------------------------------------------------
proc AnatomyGenerateLabelMaps {file_prefix act_volume} {    
    global Anatomy
    
    foreach dir {ax cor sag} {
        switch $dir {
            ax {
                set img_end $Anatomy(axSlices)
                set img_width $Anatomy(axWidth)
                set img_height $Anatomy(axHeight)
            }
            cor {
                set img_end $Anatomy(corSlices)
                set img_width $Anatomy(corWidth)
                set img_height $Anatomy(corHeight)
            }
            sag {
                set img_end $Anatomy(sagSlices)
                set img_width $Anatomy(sagWidth)
                set img_height $Anatomy(sagHeight)
            }
        }
        for {set j 0} {$j<$img_end} {incr j} {
    
            set output [open $file_prefix.$dir.$j.label w]
            fconfigure $output -translation binary

            # write image dimensions and the unused 'numparts'
            puts -nonewline $output [binary format "S" $img_width]
            puts -nonewline $output [binary format "S" $img_height]
            puts -nonewline $output [binary format "S" 0]
            for {set i 0} {$i<$img_height} {incr i} {
                set x1 $img_width
                set x2 0
                while {$x1 > 255} {
                    incr x2
                    set x1 [expr $x1-255]
                }
                for {set k 0} {$k<$x2} {incr k} {
                    puts -nonewline $output [binary format "c" 0]
                    puts -nonewline $output [binary format "c" 255]
                }
                puts -nonewline $output [binary format "c" 0]
                puts -nonewline $output [binary format "c" $x1]
            }
            puts -nonewline $output [binary format "S" 0]
            close $output
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC AnatomyShrinkWindow
#
# .END
#-------------------------------------------------------------------------------
proc AnatomyShrinkWindow {} {
    global Gui Anatomy
    
    #save window size
    set Anatomy(old_height) [winfo height .tViewer]
    set Anatomy(old_width) [winfo width .tViewer]
    
    # switch to 3D only and change window size to 384x384
    MainMenu View 3D
    wm geometry .tViewer 384x384
}


#-------------------------------------------------------------------------------
# .PROC AnatomyRestoreWindow
# 
# .END
#-------------------------------------------------------------------------------
proc AnatomyRestoreWindow {} {
    global Anatomy
    
    wm geometry .tViewer [set Anatomy(old_width)]x[set Anatomy(old_height)]
}


#-------------------------------------------------------------------------------
# .PROC AnatomySelectVolume
# 
# .END
#-------------------------------------------------------------------------------
proc AnatomySelectVolume {v} {
    global Anatomy

    set Anatomy(volumeID) $v
    $Anatomy(fMain).f2.mbVolume config -text "[Volume($v,node) GetName]"
}


#-------------------------------------------------------------------------------
# .PROC AnatomySelectLabelMap
# 
# .END
#-------------------------------------------------------------------------------
proc AnatomySelectLabelMap {v} {
    global Anatomy
    
    set Anatomy(labelID) $v
    $Anatomy(fMain).f2.mbLabel config -text "[Volume($v,node) GetName]"
}
