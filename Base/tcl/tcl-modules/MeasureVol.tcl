#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MeasureVol.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:59 $
#   Version:   $Revision: 1.22 $
# 
#===============================================================================
# FILE:        MeasureVol.tcl
# PROCEDURES:  
#   MeasureVolInit
#   MeasureVolBuildGUI
#   MeasureVolEnter
#   MeasureVolExit
#   MeasureVolVolume
#   MeasureVolSelectVol
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
#  This module counts voxels, converts to mL, and outputs a file.
#  If the extent for the input volume is changed by the user, only
#  measures that part of the volume.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are the variables defined by this module.
# 
#  list MeasureVol(eventManager)  list of event bindings used by this module
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC MeasureVolInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureVolInit {} {
    global MeasureVol Module Volume Model
    
    # Define Tabs
    #------------------------------------
    set m MeasureVol
    set Module($m,row1List) "Help Setup Results"
    set Module($m,row1Name) "{Help} {Measure} {Results}"
    set Module($m,row1,tab) Setup

    # Define Procedures
    #------------------------------------
    #   procGUI   = Build the graphical user interface
    #   procVTK   = Construct VTK objects
    #   procMRML  = Update after the MRML tree changes due to the creation
    #               of deletion of nodes.
    #   procEnter = Called when the user enters this module by clicking
    #               its button on the main menu
    #   procExit  = Called when the user leaves this module by clicking
    #               another modules button
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) MeasureVolBuildGUI
    set Module($m,procEnter) MeasureVolEnter
    set Module($m,procExit) MeasureVolExit

    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Measure volumes of labeled voxels."
    set Module($m,author) "Lauren O'Donnell, MIT AI Lab"
    set Module($m,category) "Measurement"

    # Define Dependencies
    #------------------------------------
    set Module($m,depend) ""
    
    # Set version info
    #------------------------------------
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.22 $} {$Date: 2006/01/06 17:56:59 $}]
    
    # Initialize module-level variables
    #------------------------------------
    set MeasureVol(fileName)  ""
    set MeasureVol(eventManager)  ""
}

#-------------------------------------------------------------------------------
# .PROC MeasureVolBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc MeasureVolBuildGUI {} {
    global Gui MeasureVol Module Volume Model
    
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Setup
    #   Top
    #     Choices 
    #       SelectVolume
    #       Tabs *
    #   Bottom
    #     Basic *
    #       File
    #       Measure
    #     Advanced *
    #       Extents
    # Results
    #   Volume
    #   Output
    #     Label
    #     TextBox
    #     
    # Note: items marked with a * were built as
    # part of a TabbedFrame (see tcl-shared/Widgets.tcl)
    #-------------------------------------------
    
    #-------------------------------------------
    # Help frame
    #-------------------------------------------

    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The <B>MeasureVol</B> module measures the volume of segmented structures in a labelmap.  
    It outputs a file containing the total volume in milliliters for each label value.
    <P>
    Description by tab:
    <BR>
    <UL>
    <LI><B>Measure:</B> First enter a filename.  Then click the 'Measure' button
    to measure the volumes and output your file. 
    <LI><B>Results:</B> Go to 'Results' to see the output file.
    <BR>
    <BR>
    <B>Note for advanced users:</B> 
    The 'Advanced' Settings (under 'Measure') 
    let you measure only part of a volume.  
    The numbers are the number of voxels that will be measured along each axis.
    Normally these numbers will be set automatically to measure the entire volume.
    <BR>
    <B>Example:</B> To measure only slice number 10 (counting from 0 like 
    the numbers above the slices do), set the numbers to 0 255, 0 255, and 
    10 10.  
    The first four numbers say to measure entire (256x256) slices, 
    and the last two numbers say to just measure the 10th slice.
    "
    regsub -all "\n" $help {} help
    # remove emacs indentation
    regsub -all "   " $help {} help
    MainHelpApplyTags MeasureVol $help
    MainHelpBuildGUI MeasureVol
    
    ##########################################################
    #             Setup
    ##########################################################

    #-------------------------------------------
    # Setup frame
    #-------------------------------------------
    set fSetup $Module(MeasureVol,fSetup)
    set f $fSetup

    # this makes the navigation menu (buttons) and the tabs (frames).
    TabbedFrame MeasureVol $f "Settings:"\
        {Basic Advanced} {"Basic" "Advanced"} \
        {"Basic Settings" "Advanced Settings: Measure only part of the volume."}\
        1

    #-------------------------------------------
    # Setup->Top->Choices->SelectVolume frame
    #-------------------------------------------

    # Lauren fix this!!!
    set f $fSetup.fTop.fTabbedFrameExtra

    # Add menus that list volumes
    # The selected volume will become $Volume(activeID)
    DevAddSelectButton  MeasureVol $f VolumeSelect "Volume:" Pack \
        "Volume to measure segmented regions of." 20 BLA

    # bind menubutton to update the extents.
    bind $MeasureVol(mVolumeSelect) <ButtonRelease-1> \
        "MeasureVolSelectVol" 
    # have this binding execute after menu updates active volume
    bindtags $MeasureVol(mVolumeSelect) [list Menu \
        $MeasureVol(mVolumeSelect) all]

    # Append menus and buttons to lists that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbVolumeSelect
    lappend Volume(mActiveList) $f.mbVolumeSelect.m


    #-------------------------------------------
    # Setup->TabbedFrame frame
    #-------------------------------------------
    set f $fSetup.fTabbedFrame
    
    # the frames inside this one were made with the TabbedFrame command above.

    #-------------------------------------------
    # Setup->TabbedFrame->Basic frame
    #-------------------------------------------
    set f $fSetup.fTabbedFrame.fBasic

    foreach frame "File Measure" {
    frame $f.f$frame -bg $Gui(activeWorkspace)
    pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Setup->TabbedFrame->Basic->File frame
    #-------------------------------------------
    set f $fSetup.fTabbedFrame.fBasic.fFile
    
    DevAddFileBrowse $f MeasureVol fileName "Output File:" [] "txt" [] \
        "Save" "Output File" "Choose the file where the output will be written." "Absolute"

    #-------------------------------------------
    # Setup->TabbedFrame->Basic->Measure frame
    #-------------------------------------------
    set f $fSetup.fTabbedFrame.fBasic.fMeasure
    
    # Measure button
    DevAddButton $f.bMeasure "Measure Volume" MeasureVolVolume 
    
    TooltipAdd $f.bMeasure "Measure segmented regions in a volume and write the output to a file."
    
    pack $f.bMeasure -side top -padx $Gui(pad) -pady $Gui(pad)
    

    #-------------------------------------------
    # Setup->TabbedFrame->Advanced frame
    #-------------------------------------------
    set f $fSetup.fTabbedFrame.fAdvanced

    foreach frame "Extents" {
        frame $f.f$frame -bg $Gui(activeWorkspace) -relief groove -bd 3
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # Setup->TabbedFrame->Advanced->Extents frame
    #-------------------------------------------
    set f $fSetup.fTabbedFrame.fAdvanced.fExtents
    
    frame $f.fLabel -bg $Gui(activeWorkspace)
    pack $f.fLabel -side top -padx $Gui(pad) -pady $Gui(pad)
    eval {label $f.lExtents -text "Extent of volume to measure:"} $Gui(WLA)
    pack $f.lExtents -side top -padx $Gui(pad)  -pady $Gui(pad)

    # the 6 IJK extent entry boxes.
    foreach {label n1 n2} {I 1 2   J 3 4   K 5 6} {
        frame $f.fExt$n1 -bg $Gui(activeWorkspace)
        pack $f.fExt$n1 -side top -padx 0 -pady $Gui(pad)

        DevAddLabel $f.fExt$n1.lE$n1 "$label:"
        pack $f.fExt$n1.lE$n1 -side left -padx $Gui(pad)  -pady $Gui(pad)

        # add entry box for variable MeasureVol(Extent1), etc.
        DevAddEntry MeasureVol Extent$n1 $f.fExt$n1.eE$n1
        pack $f.fExt$n1.eE$n1 -side left -padx $Gui(pad)  -pady $Gui(pad)

        DevAddEntry MeasureVol Extent$n2 $f.fExt$n1.eE$n2
        pack $f.fExt$n1.eE$n2 -side left -padx $Gui(pad)  -pady $Gui(pad)
    }


    ##########################################################
    #             Results
    ##########################################################

    #-------------------------------------------
    # Results frame
    #-------------------------------------------
    set fResults $Module(MeasureVol,fResults)
    set f $fResults

    frame $f.fVolume -bg $Gui(activeWorkspace) 
    pack $f.fVolume -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $f.fOutput -bg $Gui(activeWorkspace) -relief groove -bd 3   
    pack $f.fOutput -side top -padx $Gui(pad) -pady $Gui(pad) -fill x 

    #-------------------------------------------
    # Results->Volume frame
    #-------------------------------------------
    set f $fResults.fVolume

    DevAddLabel $f.lResultVol ""
    pack $f.lResultVol -side top -padx $Gui(pad)  -pady $Gui(pad) -fill x
    set MeasureVol(lResultVol)  $f.lResultVol

    
    #-------------------------------------------
    # Results->Output frame
    #-------------------------------------------
    set f $fResults.fOutput

    foreach frame "Label  TextBox" {
        frame $f.f$frame -bg $Gui(activeWorkspace) 
        pack $f.f$frame -side top -padx $Gui(pad) -pady 0 -fill x
    }

    #-------------------------------------------
    # Results->Output->Label frame
    #-------------------------------------------
    set f $fResults.fOutput.fLabel

    DevAddLabel $f.lTextBox "  Label\t\tVolume in mL"
    pack $f.lTextBox -side left -padx $Gui(pad)  -pady $Gui(pad)
    set MeasureVol(lTextBox) $f.lTextBox

    #-------------------------------------------
    # Results->Output->TextBox frame
    #-------------------------------------------
    set f $fResults.fOutput.fTextBox
    set MeasureVol(textBox) [ScrolledText $f.tText -width 40 -height 8]
    pack $f.tText -side top -fill both -expand true
    
}

#-------------------------------------------------------------------------------
# .PROC MeasureVolEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. Also displays extents.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureVolEnter {} {
    global MeasureVol
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $MeasureVol(eventManager)

    MeasureVolSelectVol
}

#-------------------------------------------------------------------------------
# .PROC MeasureVolExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureVolExit {} {

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
# .PROC MeasureVolVolume
# Measures the volume in mL using a vtkImageMeasureVoxels object 
# which writes an output file.  Reads in and displays the output 
# on the Results tab.  (Also can measure a subvolume if the extent
# values are changed on the Setup->Advanced tab.)
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureVolVolume { {view_prompt "yes"} } {
    global MeasureVol Volume Module
    
    # validate input from Basic tab
    if {$MeasureVol(fileName) == ""} {
        DevErrorWindow "Please enter a filename first."
        return
    }
    if {[file extension $MeasureVol(fileName)] != ".txt"} {
        set MeasureVol(fileName) "$MeasureVol(fileName).txt"
    }

    # validate input from Advanced tab
    set okay 1
    for {set i 1} {$i < 7} {incr i} {
        if {[ValidateInt $MeasureVol(Extent$i)] == 0} {
            set okay 0
        }    
    }
    if {$okay == 0} {
        tk_messageBox -message \
            "The extent numbers (under the Advanced Settings tab) must be integers."
        return
    }    

    # clear the text box.
    $MeasureVol(textBox) delete 1.0 end

    # currently selected volume
    set v $Volume(activeID)
    
    # if the user has changed the full extent in the entry
    # boxes, clip and only measure part of the volume.
    vtkImageClip clip
    clip SetInput [Volume($v,vol) GetOutput]
    clip SetOutputWholeExtent  $MeasureVol(Extent1) \
        $MeasureVol(Extent2)  $MeasureVol(Extent3) \
        $MeasureVol(Extent4)  $MeasureVol(Extent5) \
        $MeasureVol(Extent6)
    clip ClipDataOn
    clip ReleaseDataFlagOff

    # pipeline
    vtkImageMeasureVoxels measure
    #measure SetInput [Volume($v,vol) GetOutput]
    measure SetInput [clip GetOutput]
    measure SetFileName $MeasureVol(fileName)
    measure Update

    # delete objects we created
    measure Delete
    clip Delete

    # display the output that was written to the file.
    set in [open $MeasureVol(fileName)]
    $MeasureVol(textBox) insert end [read $in]
    close $in

    # label output in Results frame
    $MeasureVol(lResultVol) configure -text \
        "Results for [Volume($v,node) GetName] volume:"

    # tab to Results frame if desired
    if { $view_prompt == "yes" } {
        YesNoPopup test1 100 100 \
            "Done measuring volume [Volume($v,node) GetName].\nView output file?" \
            {Tab MeasureVol row1 Results}
    }

}

#-------------------------------------------------------------------------------
# .PROC MeasureVolSelectVol
# Called when the 
# module is entered and when a new volume is selected from the 
# menu.
# Sets the filename to be the current volume's name_hist.txt.
# Displays the extent values for the currently active Volume in 
# the entry boxes on the Setup->Advanced tab.  
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MeasureVolSelectVol {} {

    global MeasureVol Volume

    # currently selected volume
    set v $Volume(activeID)

    set name [Volume($v,node) GetName]
    set default "_hist.txt"
    set MeasureVol(fileName) $name$default

    # set extent to that of the current volume.
    # this sets the entry boxes too.
    scan [[Volume($v,vol) GetOutput] GetWholeExtent] \
        "%d %d %d %d %d %d" \
        MeasureVol(Extent1) MeasureVol(Extent2) MeasureVol(Extent3) \
        MeasureVol(Extent4) MeasureVol(Extent5) MeasureVol(Extent6)
}

