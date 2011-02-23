#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: DTMRICalculateTensors.tcl,v $
#   Date:      $Date: 2006/07/06 17:38:17 $
#   Version:   $Revision: 1.43 $
# 
#===============================================================================
# FILE:        DTMRICalculateTensors.tcl
# PROCEDURES:  
#   DTMRICalculateTensorsInit
#   DTMRICalculateTensorsBuildGUI
#   DTMRIConvertUpdate
#   ShowPatternFrame
#   DTMRIDisplayScrollBar module tab
#   DTMRICreatePatternSlice
#   DTMRICreatePatternVolume
#   DTMRILoadPattern
#   DTMRIUpdateTipsPattern
#   DTMRIViewProps
#   ConvertVolumeToTensors
#   DTMRICreateNewNode node:
#   DTMRICreateNewNode refnode voldata name description
#   DTMRICreateNewVolume volume name desc scanOrder
#   DTMRIComputeRasToIjkFromCorners refnode volid: extent:
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC DTMRICalculateTensorsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateTensorsInit {} {

    global DTMRI Volume

    # Version info for files within DTMRI module
    #------------------------------------
    set m "CalculateTensors"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.43 $} {$Date: 2006/07/06 17:38:17 $}]

    # Initial path to search when loading files
    #------------------------------------
    set DTMRI(DefaultDir) ""

    #------------------------------------
    # handling patterns variables
    #------------------------------------

    # List with the existing patterns
    # DTMRI(patternnames)

    # List with the information of the pattern called "patternname"
    # DTMRI("patternname", parameters)

    # Variable with the name of the pattern selected in the menubutton. Used to retrieve information of the pattern when converting tensors.
    # DTMRI(selectedpattern)

    # Variables associated to entries for creating a new pattern
    set DTMRI(name,name) ""
    set DTMRI(name,numberOfGradients) ""
    set DTMRI(name,firstGradientImage) ""
    set DTMRI(name,lastGradientImage) ""
    set DTMRI(name,firstNoGradientImage) ""
    set DTMRI(name,lastNoGradienImage) ""
    set DTMRI(name,gradients) ""
    set DTMRI(name,lebihan) ""
    #This variable specifies the order of the gradients disposal (slice interleaved or volume interleaved)
    set DTMRI(name,order) ""


    #------------------------------------
    # conversion from volume to DTMRIs variables
    #------------------------------------
    set _default [DevNewInstance vtkImageDiffusionTensor _default]
    set DTMRI(convert,numberOfGradients) [$_default GetNumberOfGradients]
    set DTMRI(convert,gradients) ""
    for {set i 0} {$i < $DTMRI(convert,numberOfGradients)} {incr i} {
        $_default SelectDiffusionGradient $i
        lappend DTMRI(convert,gradients) [$_default GetSelectedDiffusionGradient]
    }
    $_default Delete
    # puts $DTMRI(convert,gradients)
    set DTMRI(convert,firstGradientImage) 1
    set DTMRI(convert,lastGradientImage) 6
    set DTMRI(convert,firstNoGradientImage) 7
    set DTMRI(convert,lastNoGradientImage) 7

    #Specific variables for Mosaic format (This should be extracted from Dicom header)
    set DTMRI(convert,mosaicTiles) 8
    set DTMRI(convert,mosaicSlices) 60

    #Variables to control the number of repetitions in the DWI volume
    set DTMRI(convert,numberOfRepetitions) 1
    set DTMRI(convert,numberOfRepetitions,min) 1
    set DTMRI(convert,numberOfRepetitions,max) 10
    set DTMRI(convert,repetition) 1
    set DTMRI(convert,averageRepetitions) 1
    set DTMRI(convert,averageRepetitionsList) {On Off}
    set DTMRI(convert,averageRepetitionsValue) {1 0}
    set DTMRI(convert,averageRepetitionsList,tooltips) [list \
                                 "Average the diffusion weighted images across repetitions."\
                 "If off having several repetitdions means that the first repetition is used to compute the tensor" \
                 ]
    set DTMRI(convert,measurementframe) {{1 0 0} {0 1 0} {0 0 1}}
    
    # New variables to hold Protocol information based on
    # NRRD key-value pairs parsing
    set DTMRI(convert,nrrd,numberOfGradients) " "
    set DTMRI(convert,nrrd,gradients) " "
    set DTMRI(convert,nrrd,bValues) " "
    set DTMRI(convert,nrrd,skip) ""
    
    # DWMRI key-value pair version supported by the slicer
    set DTMRI(convert,nrrd,version) 2
    
    set DTMRI(convert,mask,removeIslands) 0
    set DTMRI(conver,mask,omega) 0.5
    
    set DTMRI(convert,mask,omega,tooltips) [list \
                                 "Control the sharpness of the threshold in the Otsu computation."\
                 "0: lower threshold, 1: higher threhold" \
                 ]
    
    #This variable is used by Create-Pattern button and indicates weather it has to hide or show the create pattern frame. On status 0 --> show. On status 1 --> hide.
    set DTMRI(convert,show) 0

    #Volume to convert is nrrd
    set DTMRI(convert,nrrd) 0
    
    set DTMRI(convert,makeDWIasVolume) 0
    set DTMRI(convertID) $Volume(idNone)

}


#-------------------------------------------------------------------------------
# .PROC DTMRICalculateTensorsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateTensorsBuildGUI {} {
    
    global DTMRI Module Gui Volume

    #-------------------------------------------
    # Convert frame
    #-------------------------------------------
    set fConvert $Module(DTMRI,fConv)
    set f $fConvert
    
    foreach frame "Convert ShowPattern Pattern" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    }

    pack forget $f.fPattern
    $f.fConvert configure  -relief groove -bd 3 


    #-------------------------------------------
    # Convert->Convert frame
    #-------------------------------------------
    set f $fConvert.fConvert

    foreach frame "Title Select Pattern Repetitions Average  Mask Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        $f.fTitle configure -bg $Gui(backdrop)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }
    
    $f.fMask configure -relief groove -bd 1

    #-------------------------------------------
    # Convert->Convert->Title frame
    #-------------------------------------------
    set f $fConvert.fConvert.fTitle
     
    DevAddLabel $f.lWellcome "Convert Tensors"
    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
    pack $f.lWellcome -side top -padx $Gui(pad) -pady $Gui(pad)
   
    DevAddLabel $f.lOption "This tab converts gradient data\n to diffusion tensor"
    $f.lOption configure -fg White -font {helvetica 9 normal}  -bg $Gui(backdrop) -bd 0
    pack $f.lOption -side top -padx $Gui(pad) -pady 2
    

    #-------------------------------------------
    # Convert->Convert->Select frame
    #-------------------------------------------
    set f $fConvert.fConvert.fSelect
    # Lauren test
    # menu to select a volume: will set Volume(activeID)
    DevAddSelectButton  DTMRI $f convertID "Input Volume:" Pack \
            "Input Volume to create DTMRIs from." 13 BLA
    

    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    #lappend Volume(mbActiveList) $f.mbActive
    #lappend Volume(mActiveList) $f.mbActive.m


    #-------------------------------------------
    # Convert->Convert->Pattern frame
    #-------------------------------------------
    set f $fConvert.fConvert.fPattern

    DevAddLabel $f.lLabel "Protocol:"
    $f.lLabel configure -bg $Gui(backdrop) -fg white
    eval {menubutton $f.mbPattern -text "None" -relief raised -bd 2 -menu $f.mbPattern.menu -width 15} $Gui(WMBA)
    eval {menu $f.mbPattern.menu}  $Gui(WMA)
    button $f.bProp -text Prop. -width 5 -font {helvetica 8} -bg $Gui(normalButton) -fg $Gui(textDark)  -activebackground $Gui(activeButton) -activeforeground $Gui(textDark)  -bd $Gui(borderWidth) -padx 0 -pady 0 -relief raised -command {
        catch {DevInfoWindow $DTMRI($DTMRI(selectedpattern),tip)}
        catch {puts $DTMRI($DTMRI(selectedpattern),tip)}
        #DTMRIViewProps
    }

    pack $f.lLabel $f.bProp -side left -padx $Gui(pad) -pady $Gui(pad)
    DTMRILoadPattern
    TooltipAdd $f.lLabel "Choose a protocol to convert tensors.\n If desired does not exist, create one in the frame below."


    #-------------------------------------------
    # Convert->Convert->Repetitions frame
    #-------------------------------------------
    set f $fConvert.fConvert.fRepetitions
    
    DevAddLabel $f.l "Num. Repetitions:"
    $f.l configure -bg $Gui(backdrop) -fg white
    eval {entry $f.e -width 3 \
          -textvariable DTMRI(convert,numberOfRepetitions)} \
        $Gui(WEA)
    eval {scale $f.s -from $DTMRI(convert,numberOfRepetitions,min) \
                          -to $DTMRI(convert,numberOfRepetitions,max)    \
          -variable  DTMRI(convert,numberOfRepetitions)\
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)
      
     pack $f.l $f.e $f.s -side left -padx $Gui(pad) -pady $Gui(pad)
     
    #-------------------------------------------
    # Convert->Convert->Average frame
    #-------------------------------------------
    set f $fConvert.fConvert.fAverage
    
    DevAddLabel $f.l "Average Repetitions: "
    pack $f.l -side left -pady $Gui(pad) -padx $Gui(pad)  
    # Add menu items
    foreach vis $DTMRI(convert,averageRepetitionsList) val $DTMRI(convert,averageRepetitionsValue) \
            tip $DTMRI(convert,averageRepetitionsList,tooltips) {
        eval {radiobutton $f.r$vis \
              -text "$vis" \
              -value $val \
              -variable DTMRI(convert,averageRepetitions) \
              -indicatoron 0} $Gui(WCA)
        pack $f.r$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.r$vis $tip     
    }
     
#    #-------------------------------------------
#    # Convert->Convert->Mask frame
#    #-------------------------------------------         
      set fMask $fConvert.fConvert.fMask
      
      foreach frame "Title Omega RemoveIsland" {
        frame $fMask.f$frame -bg $Gui(activeWorkspace)
        pack $fMask.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
      }
      
      set f $fMask.fTitle
      DevAddLabel $f.l "Automatic Mask Extraction" 
      pack $f.l
      
      set f $fMask.fOmega
      DevAddLabel $f.l "Weight:"
       $f.l configure -bg $Gui(backdrop) -fg white
       eval {entry $f.e -width 3 \
          -textvariable DTMRI(convert,mask,omega)} \
        $Gui(WEA)
       eval {scale $f.s -from 0 \
                          -to 1    \
          -variable  DTMRI(convert,mask,omega)\
          -orient vertical     \
          -resolution .1      \
          } $Gui(WSA)      
      pack $f.l $f.e $f.s -side left -padx $Gui(pad) -pady $Gui(pad)
      
      TooltipAdd  $f.l $DTMRI(convert,mask,omega,tooltips)     
      TooltipAdd  $f.e $DTMRI(convert,mask,omega,tooltips) 
      TooltipAdd  $f.s $DTMRI(convert,mask,omega,tooltips)        

      set f $fMask.fRemoveIsland
      eval {checkbutton $f.r \
               -text "Remove Island" -variable DTMRI(convert,mask,removeIslands) -indicatoron 0 \
               -width 12} $Gui(WCA)
      pack $f.r -side left -padx $Gui(pad) -pady $Gui(pad)         

#    #-------------------------------------------
#    # Convert->Convert->Apply frame
#    #-------------------------------------------
    set f $fConvert.fConvert.fApply
    DevAddButton $f.bTest "Convert Volume" ConvertVolumeToTensors 20
    pack $f.bTest -side top -padx 0 -pady $Gui(pad) -fill x -padx $Gui(pad)


    #-------------------------------------------
    # Convert->ShowPattern frame
    #-------------------------------------------
    set f $fConvert.fShowPattern
    
    DevAddLabel $f.lLabel "Create a new protocol if your data\n does not fit the predefined ones"

    button $f.bShow -text "Create New Protocol" -bg $Gui(backdrop) -fg white -font {helvetica 9 bold} -command {
        ShowPatternFrame 
        after 250 DTMRIDisplayScrollBar DTMRI Conv}
    TooltipAdd $f.bShow "Press this button to enter Create-Protocol Frame"
    pack $f.lLabel $f.bShow -side top -pady 2 -fill x




    #-------------------------------------------
    # Convert->Pattern->Gradients Title frame
    #-------------------------------------------

#    set f $fConvert.fPattern
#    frame $f.fTitle -bg $Gui(backdrop)
#    pack $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

#    set f $fConvert.fPattern.fTitle
#    set f $Page.fTitle
   
#    DevAddLabel $f.lWellcome "Create New Protocol"
#    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
#    pack $f.lWellcome -side top -padx $Gui(pad) -pady 0
   


    #-------------------------------------------
    # Convert->Pattern frame (create tabs)
    #-------------------------------------------
    set f $fConvert.fPattern
    DevAddLabel $f.lIni "Gradient Ordering scheme:"
    pack $f.lIni -side top -pady 2

    if { [catch "package require BLT" ] } {
        DevErrorWindow "Must have the BLT package to create GUI."
        return
    }

    #--- create blt notebook
    blt::tabset $f.fNotebook -relief flat -borderwidth 0
    pack $f.fNotebook -fill both -expand 1

    #--- notebook configure
    $f.fNotebook configure -width 250
    $f.fNotebook configure -height 335
    $f.fNotebook configure -background $::Gui(activeWorkspace)
    $f.fNotebook configure -activebackground $::Gui(activeWorkspace)
    $f.fNotebook configure -selectbackground $::Gui(activeWorkspace)
    $f.fNotebook configure -tabbackground $::Gui(activeWorkspace)
    $f.fNotebook configure -foreground black
    $f.fNotebook configure -activeforeground black
    $f.fNotebook configure -selectforeground black
    $f.fNotebook configure -tabforeground black
    $f.fNotebook configure -relief flat
    $f.fNotebook configure -tabrelief raised     
    $f.fNotebook configure -highlightbackground $::Gui(activeWorkspace)
    $f.fNotebook configure -highlightcolor $::Gui(activeWorkspace) 
        #--- tab configure
    set i 0
    foreach name "{Slice Interleav.} {Volume Interleav.}" t "SliceInterleav VolumeInterleav" {
        $f.fNotebook insert $i $name
        frame $f.fNotebook.f$t -bg $Gui(activeWorkspace) -bd 2
        $f.fNotebook tab configure $name -window $f.fNotebook.f$t  \
            -fill both -padx $::Gui(pad) -pady $::Gui(pad)
        incr i
    } 


    set f $fConvert.fPattern.fNotebook

    set FrameCont $f.fSliceInterleav 
    set FrameInter $f.fVolumeInterleav

    foreach Page "$FrameCont $FrameInter" {   

        #-------------------------------------------
        # Convert->Pattern frame
        #-------------------------------------------
    #    set f $fConvert.fPattern
        set f $Page

        foreach frame "Name Disposal GradientNum GradientImages NoGradientImages Gradients Parameter Create" {
            frame $f.f$frame -bg $Gui(activeWorkspace)
            pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
        }

        $f configure  -relief sunken -bd 3 

        #-------------------------------------------
        # Convert->Pattern->Gradients Title frame
        #-------------------------------------------

    #    set f $fConvert.fPattern
    #    frame $f.fTitle -bg $Gui(backdrop)
    #    pack $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

        set f $fConvert.fPattern.fTitle
    #    set f $Page.fTitle
       
    #    DevAddLabel $f.lWellcome "Create New Protocol"
    #    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
    #    pack $f.lWellcome -side top -padx $Gui(pad) -pady $Gui(pad)
       

        #-------------------------------------------
        # Convert->Pattern->Gradients Name frame
        #-------------------------------------------

    #    set f $fConvert.fPattern.fName
        set f $Page.fName

        $f configure -relief raised -padx 2 -pady 2
        DevAddLabel $f.lTitle "Protocol Name:"
    #   $f.lTitle configure -relief sunken -background gray -bd 2
        DevAddEntry DTMRI name,name $f.eName 15
        pack $f.lTitle $f.eName -side left -padx $Gui(pad) -pady 4 -fill x


     
        #-------------------------------------------
        # Convert->Pattern->Gradients Disposal frame
        #-------------------------------------------

    #    set f $fConvert.fPattern.fDisposal
        set f $Page.fDisposal

        $f configure -relief raised -padx 2 -pady 2
        DevAddLabel $f.lTitle "Gradients/Baselines disposal in Volume:"
        $f.lTitle configure -relief sunken -background gray -bd 2
        pack $f.lTitle -side top -padx $Gui(pad) -pady 4 -fill x
     
        #-------------------------------------------
        # Convert->Pattern->GradientNum frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fGradientNum
        set f $Page.fGradientNum
        
        DevAddLabel $f.l "Number of Gradient Directions:"
        eval {entry $f.eEntry \
            -textvariable DTMRI(name,numberOfGradients) \
            -width 5} $Gui(WEA)
        pack $f.l $f.eEntry -side left -padx $Gui(pad) -pady 0 -fill x

        #-------------------------------------------
        # Convert->Pattern->GradientImages frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fGradientImages
        set f $Page.fGradientImages

        DevAddLabel $f.l "Gradient:"
        eval {entry $f.eEntry1 \
              -textvariable DTMRI(name,firstGradientImage) \
              -width 5} $Gui(WEA)
        eval {entry $f.eEntry2 \
              -textvariable DTMRI(name,lastGradientImage) \
              -width 5} $Gui(WEA)
        pack $f.l $f.eEntry1 $f.eEntry2 -side left -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.eEntry1 \
            "First gradient (diffusion-weighted)\nimage number at first slice location"
        TooltipAdd $f.eEntry2 \
            "Last gradient (diffusion-weighted)\niimage number at first slice location"

        #-------------------------------------------
        # Convert->Pattern->NoGradientImages frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fNoGradientImages
        set f $Page.fNoGradientImages


        DevAddLabel $f.l "Baseline:"
        eval {entry $f.eEntry1 \
              -textvariable DTMRI(name,firstNoGradientImage) \
              -width 5} $Gui(WEA)
        eval {entry $f.eEntry2 \
              -textvariable DTMRI(name,lastNoGradientImage) \
              -width 5} $Gui(WEA)
        pack $f.l $f.eEntry1 $f.eEntry2 -side left -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.eEntry1 \
            "First NO gradient (not diffusion-weighted)\nimage number at first slice location"
        TooltipAdd $f.eEntry2 \
            "Last NO gradient (not diffusion-weighted)\n image number at first slice location"


        #-------------------------------------------
        # Convert->Pattern->Gradients frame
        #-------------------------------------------
        #    set f $fConvert.fPattern.fGradients
        set f $Page.fGradients


        DevAddLabel $f.lLabel "Directions:"
        frame $f.fEntry -bg $Gui(activeWorkspace)
        eval {entry $f.fEntry.eEntry \
            -textvariable DTMRI(name,gradients) \
            -width 25 -xscrollcommand [list $f.fEntry.sx set]} $Gui(WEA)
            scrollbar $f.fEntry.sx -orient horizontal -command [list $f.fEntry.eEntry xview] -bg $Gui(normalButton) -width 10 -troughcolor $Gui(normalButton) 
        pack $f.fEntry.eEntry $f.fEntry.sx -side top -padx 0 -pady 0 -fill x
        pack $f.lLabel $f.fEntry -side left -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor n
        #pack $f.sx -side top -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.fEntry.eEntry "List of diffusion gradient directions"

        #-------------------------------------------
        # Convert->Pattern->Parameters frame
        #-------------------------------------------




    # This frame is supposed to hold the entries for needed parameters in tensors conversion.

    #    set f $fConvert.fPattern.fParameter
        set f $Page.fParameter

        $f configure -relief raised -padx 2 -pady 2
        DevAddLabel $f.lTitle "Conversion Parameters:"
        $f.lTitle configure -relief sunken -background gray -bd 2
        pack $f.lTitle -side top -padx $Gui(pad) -pady 4 -fill x
        DevAddLabel $f.lLeBihan "LeBihan factor (b):"
        eval {entry $f.eEntrylebihan \
            -textvariable DTMRI(name,lebihan)  \
            -width 4} $Gui(WEA)
        eval {scale $f.slebihan -from 100 -to 5000 -variable DTMRI(name,lebihan) -orient vertical -resolution 10 -width 10} $Gui(WSA)
        pack $f.lLeBihan $f.eEntrylebihan $f.slebihan  -side left -padx $Gui(pad) -pady 0 -fill x -padx $Gui(pad)
        TooltipAdd $f.eEntrylebihan "Diffusion weighting factor, introduced and defined by LeBihan et al.(1986)"
      
    }

    #-------------------------------------------
    # Convert->Pattern->FrameCont-->Create frame
    #-------------------------------------------

    set f $FrameCont.fCreate
    DevAddButton $f.bCreate "Create New Protocol" DTMRICreatePatternSlice 8
    pack $f.bCreate -side top -pady $Gui(pad) -fill x
    TooltipAdd $f.bCreate "Click this button to create a new protocol after filling in parameters entries"
    

    #-------------------------------------------
    # Convert->Pattern->FrameInter-->Create frame
    #-------------------------------------------

    set f $FrameInter.fCreate
    DevAddButton $f.bCreate "Create New Protocol" DTMRICreatePatternVolume 8
    pack $f.bCreate -side top -pady $Gui(pad) -fill x
    TooltipAdd $f.bCreate "Click this button to create a new protocol after filling in parameters entries"



}


#-------------------------------------------------------------------------------
# .PROC DTMRIConvertUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIConvertUpdate {} {
  global DTMRI Volume Module
  
  set id $DTMRI(convertID)
  
  #Check if DTMRI headerKeys exists
  set headerkey [array names Volume "$id,headerKeys,modality"]
  
  set f $Module(DTMRI,fConv).fConvert
  if {$headerkey == ""} {
    #Active protocol frame
    $f.fPattern.mbPattern configure -state normal
    $f.fRepetitions.e configure -state normal
    $f.fRepetitions.s configure -state normal
    foreach vis $DTMRI(convert,averageRepetitionsList) {
      $f.fAverage.r$vis configure -state normal
    }
    
    set DTMRI(convert,nrrd) 0
    set DTMRI(convert,nrrd,skip) ""  
    return
  }
  
  if {[string trimright [string trimleft $Volume($headerkey)]] \
      != "DWMRI"} {
    # Prompt advise
    DevErrorWindow "Selected volume is not a proper nrrd DWI volume"
    return
  }     
  
  
  set headerkeys [array names Volume "$id,headerKeys,DW*"]
  
  if {$headerkeys == ""} {
     #Active protocols frame
     DevErrorWindow "There is not protocol info. Nrrd header might be corrupted.\n \
                     You should choose a protocol."
     return
  }
  
  #At this point with are dealing with a Nrrd DWI volume.
  
  #Disable protocol frame
  $f.fPattern.mbPattern configure -state disable
  $f.fRepetitions.e configure -state disable
  $f.fRepetitions.s configure -state disable
  foreach vis $DTMRI(convert,averageRepetitionsList) {
      $f.fAverage.r$vis configure -state disable
  }  

  #Build protocol from headerKeys
  set key DWMRI_b-value
  set DTMRI(convert,lebihan) [string trimleft [string trimright $Volume($id,headerKeys,$key)]] 
  #Find baseline
  set DTMRI(convert,gradients) ""
  set gradientkeys [array names Volume "$id,headerKeys,DWMRI_gradient_*" ]
  
  set DTMRI(convert,numberOfGradients) 0
  set DTMRI(convert,nrrd,skip) ""
  
  set baselinepos 1
  set keyprefix "$id,headerKeys"
  set gradprefix "$keyprefix,DWMRI_gradient_"
  set nexprefix "$keyprefix,DWMRI_NEX_"
  set skipprefix "$keyprefix,DWMRI_skip_"
  
  set idx 0
  set findfirstbaseline 0
  set findfirstgradient 0

  while {1} {
    set grad [format %04d $idx]
    set key "$gradprefix$grad"
        
    if {![info exists Volume($key)]} {
      break
    }

    #Check if we have to skip this gradient
    set keyskip "$skipprefix$grad"
    set skip 0
    if {[info exists Volume($keyskip)]} {
        if {[string tolower [string trimright [string trimleft $Volume($keyskip)]]] == "true"} {
            set skip 1
        } else {
            set skip 0
        }
    }
          
    if {[string tolower [string trimright [string trimleft $Volume($key)]]] == "n/a"} {
        set skip 1
    }
    
    #Error checking: gradient should be a number if it is not skipped
    if {$skip == 0 && [regexp {[\s.\d]*} $Volume($key)] != 1} {
        DevErrorWindow "Gradient $grad := $Volume($key) is not a valid vector"
        return
    }
    
    #Check for baseline
    set val [string trimright [string trimleft $Volume($key)]]
    if {[lindex $val 0] == 0 && \
        [lindex $val 1] == 0 && \
        [lindex $val 2] == 0} {
            #Check for NEX
            set keynex "$nexprefix$grad"
            if {[info exists Volume($keynex)]} {
                set nex [string trimright [string trimleft $Volume($keynex)]]
            } else {
                set nex 1
            }
      
            if {$findfirstbaseline == 0} {
                set DTMRI(convert,firstNoGradientImage) [expr $idx + 1]
                set findfirstbaseline 1
            }
            set DTMRI(convert,lastNoGradientImage) [expr $idx + $nex]

            for {set nidx 0} {$nidx < $nex} {incr nidx} {
                if {$skip ==1 } {
                    lappend DTMRI(convert,nrrd,skip) $idx
                }
                incr idx
            }
            #set idx [expr $idx + $nex]
     } else {
            set keynex "$nexprefix$grad"
            if {[info exists Volume($keynex)]} {
                set nex [string trimright [string trimleft $Volume($keynex)]]
            } else {
                set nex 1
            }
      
            if {$findfirstgradient == 0} {
                set DTMRI(convert,firstGradientImage) [expr $idx + 1]
                set findfirstgradient 1 
            } 
            
            for {set nidx 0} {$nidx < $nex} {incr nidx} {
                lappend DTMRI(convert,gradients) [string trimright [string trimleft $Volume($key)]]
                incr DTMRI(convert,numberOfGradients)
                if {$skip == 1} {
                    lappend DTMRI(convert,nrrd,skip) $idx
                }    
                incr idx
            }
            #set idx [expr $idx + $nex]    
    }
    
  }
  
  set DTMRI(convert,lastGradientImage) [expr $DTMRI(convert,numberOfGradients) + $DTMRI(convert,firstGradientImage) - 1]   
  
         
  #Nrrd by default is VOLUME-Interslice
  set DTMRI(convert,order) "VOLUME"
     
  #Measure frame: In VolNRRD we have converted measurement frame
  # from an attribute to an header key. This is a temporary solution
  # to accomodate somehow until this information is incorporated in
  # vtkMrmrlVolumeNode.
  set key "measurementframe"
  set DTMRI(convert,measurementframe) $Volume($id,headerKeys,$key)
  
  #Set nrrd flag
  set DTMRI(convert,nrrd) 1
  
  #Do a second parsing for the new gradient specification based directly on nrrd header
  DTMRIParseNrrdKeyValuePairs
       
  #Disable protocols

}

proc DTMRIParseNrrdKeyValuePairs {} {
  
  global DTMRI Volume
  
  set id $DTMRI(convertID)
  
  #Check if DTMRI headerKeys exists
  set headerkey [array names Volume "$id,headerKeys,modality"]
    
  if {[string trimright [string trimleft $Volume($headerkey)]] != "DWMRI"} {
    # Prompt advise
    DevErrorWindow "Selected volume is not a proper nrrd DWI volume"
    return
  }     
  
  
  set headerkeys [array names Volume "$id,headerKeys,DW*"]
  
  if {$headerkeys == ""} {
     #Active protocols frame
     DevErrorWindow "There is not protocol info. Nrrd header might be corrupted.\n \
                    If you feel conformtable, choose a protocol"
     return
  }
  
  set gradientkeys [array names Volume "$id,headerKeys,DWMRI_gradient_*" ]
  
  set DTMRI(convert,nrrd,numberOfGradients) 0
  set DTMRI(convert,nrrd,gradients) ""
  set DTMRI(convert,nrrd,bValues) ""
  
  set keyprefix "$id,headerKeys"
  set gradprefix "$keyprefix,DWMRI_gradient_"
  set nexprefix "$keyprefix,DWMRI_NEX_"
  set skipprefix "$keyprefix,DWMRI_skip_"

  set keybValue DWMRI_b-value
  set bValueBase [string trimright [string trimleft $Volume($id,headerKeys,$keybValue)]] 
  set maxfactor 0
  set factorList " "
  set idx 0
  while {1} {
    set grad [format %04d $idx]
    set key "$gradprefix$grad"
      
    if {![info exists Volume($key)]} {
      break
    }
    
    #Check if we have to skip this gradient
    set keyskip "$skipprefix$grad"
    set skip 0
    if {[info exists Volume($keyskip)]} {
        if {[string tolower [string trimright [string trimleft $Volume($keyskip)]]] == "true"} {
            set skip 1
        } else {
            set skip 0
        }
    }
          
    if {[string tolower [string trimright [string trimleft $Volume($key)]]] == "n/a"} {
        set skip 1
    }

    #Error checking: gradient should be a number if not skip
    if {$skip == 0 && [regexp {[\s.\d]*} $Volume($key)] != 1} {
        DevErrorWindow "Gradient $grad := $Volume($key) is not a valid vector"
        return
    }    
    
    set keynex "$nexprefix$grad"
    if {[info exists Volume($keynex)]} {
        set nex [string trimleft [string trimright $Volume($keynex)]]
    } else {
        set nex 1
    }
    
    for {set nidx 0} {$nidx < $nex} {incr nidx} {
        if {$skip == 0} {
            set factor [::tclVectorUtils::VLen $Volume($key)]
        } else {
            set factor 1
        }
        lappend factorList $factor
        if {$factor > $maxfactor} {
            set maxfactor $factor
        }
        lappend DTMRI(convert,nrrd,gradients) \
           [string trimleft [string trimright $Volume($key)]]
        incr DTMRI(convert,nrrd,numberOfGradients)
    }
    set idx [expr $idx + $nex]
  }
  
  #Compute list from b Value from factor List and max factor extracted from
  # gradient vector norms.
  foreach factor $factorList {
    lappend DTMRI(convert,nrrd,bValues) [expr $bValueBase * ($factor / $maxfactor)]
  }
        
}

#-------------------------------------------------------------------------------
# .PROC ShowPatternFrame
#  Show and hide Create-Pattern Frame from the Convert Tab.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
    proc ShowPatternFrame {} {
    
    global DTMRI Volume Mrml Module Gui

    set fConvert $Module(DTMRI,fConv)
    set f $fConvert

    if { $DTMRI(convert,show) == 1} {
        pack forget $f.fPattern
        set DTMRI(convert,show) 0
        return
    }

    if { $DTMRI(convert,show) == 0 } {
        pack $f.fPattern -padx $Gui(pad) -pady $Gui(pad)
    
        set DTMRI(convert,show) 1
        return
    }

}

#-------------------------------------------------------------------------------
# .PROC DTMRIDisplayScrollBar
#  If the size of a workframe changes, display the scrollbar if necessary.
#  
# .ARGS
# string module
# string tab
# .END
#-------------------------------------------------------------------------------
proc DTMRIDisplayScrollBar {module tab} {
    global Module

    set reqHeight [winfo reqheight $Module($module,f$tab)]
    # puts $reqHeight 
    # puts $Module(.tMain.fControls,scrolledHeight)
    MainSetScrollbarHeight $reqHeight
    if {$reqHeight > $Module(.tMain.fControls,scrolledHeight)} { 
        MainSetScrollbarVisibility 1
    } else {
        MainSetScrollbarVisibility 0
    }

}


#-------------------------------------------------------------------------------
# .PROC DTMRICreatePatternSlice
# Write new patterns defined by user in $env(HOME)/PatternData and update patterns selectbutton
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICreatePatternSlice {} {
        global Module Gui Volume DTMRI Mrml env

        set DTMRI(patternpar) ""

        # check if name field is filled in
        if {$DTMRI(name,name) != ""} {

            # check if all fields are filled in
            foreach par {numberOfGradients firstGradientImage lastGradientImage firstNoGradientImage lastNoGradientImage lebihan gradients} {
       
                if {$DTMRI(name,$par) != ""} {

                    # put information of the entries of create pattern frame in a list in order to write this information in a file
                    lappend DTMRI(patternpar) $DTMRI(name,$par)

                } else {

                    puts "You must fill in $par entry"
                    break

                }

            }

            lappend DTMRI(patternpar) "SLICE"

        } else {

            puts "You must fill in name entry"
        return

        }



        if {[file exists $env(HOME)/PatternsData/] != 1} then {

            file mkdir $env(HOME)/PatternsData/

        }

        if {$DTMRI(name,name) != ""} {
    
            if {[file exists $env(HOME)/PatternsData/$DTMRI(name,name)] != 0} then {

                puts "You are modifying an existing file"

            }
    
            set filelist [open $env(HOME)/PatternsData/$DTMRI(name,name) {RDWR CREAT}]
            puts  $filelist "# This line is the label that tells the code that this is a pattern file"
            puts  $filelist "vtkDTMRIprotocol"
            puts  $filelist "\n "
            puts  $filelist "# Enter a new pattern in the following order\n"
            #seek $filelist -0 end
            puts  $filelist "# Name NoOfGradients FirstGradient LastGradient FirstBaseLine LastBaseLine Lebihan GradientDirections\n"
            #seek $filelist -0 end
            puts  $filelist "\n "
            #seek $filelist -0 end
            puts $filelist $DTMRI(patternpar)    
            close $filelist
        
            DTMRILoadPattern

        }
 
}


#-------------------------------------------------------------------------------
# .PROC DTMRICreatePatternVolume
# Write new patterns defined by user in $env(HOME)/PatternData and update patterns selectbutton
#  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICreatePatternVolume {} {
      global Module Gui Volume DTMRI Mrml env

      set DTMRI(patternpar) ""

      # check if name field is filled in
      if {$DTMRI(name,name) != ""} {

        # check if all fields are filled in
        foreach par {numberOfGradients firstGradientImage lastGradientImage firstNoGradientImage lastNoGradientImage lebihan gradients} {
       
          if {$DTMRI(name,$par) != ""} {

              # put information of the entries of create pattern frame in a list in order to write this information in a file
              lappend DTMRI(patternpar) $DTMRI(name,$par)

          } else {

              puts "You must fill in $par entry"
              break

          }

        }

        lappend DTMRI(patternpar) "VOLUME"

      } else {

        puts "You must fill in name entry"
        return

      }




      if {[file exists $env(HOME)/PatternsData/] != 1} then {

          file mkdir $env(HOME)/PatternsData/

      }
    
      if {$DTMRI(name,name) != ""} {

          if {[file exists $env(HOME)/PatternsData/$DTMRI(name,name)] != 0} then {

              puts "You are modifying an existing file"

          }

          set filelist [open $env(HOME)/PatternsData/$DTMRI(name,name) {RDWR CREAT}]
          puts  $filelist "# This line is the label that tells the code that this is a pattern file"
          puts  $filelist "vtkDTMRIprotocol"
          puts  $filelist "\n "
          puts  $filelist "# Enter a new pattern in the following order\n"
          #seek $filelist -0 end
          puts  $filelist "# Name NoOfGradients FirstGradient LastGradient FirstBaseLine LastBaseLine Lebihan GradientDirections\n"
          #seek $filelist -0 end
          puts  $filelist "\n "
          #seek $filelist -0 end
          puts $filelist $DTMRI(patternpar)    
          close $filelist

          DTMRILoadPattern

      }
} 



#-------------------------------------------------------------------------------
# .PROC DTMRILoadPattern
# Looks for files with information of patterns and adds this information in the menubutton of the create pattern frame
#nowworking2
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRILoadPattern {} {
    global Module Gui Volume DTMRI Mrml env PACKAGE_DIR_VTKDTMRI

    # if DTMRI(patternames) already exists, initialize it and its information
   
    if {[info exists DTMRI(patternnames)]} {
        foreach a $DTMRI(patternnames) {
            set DTMRI($a,parameters) ""
        }
        set DTMRI(patternnames) ""
    } else {
        set DTMRI(patternnames) ""
    }

    if {[info exists DTMRI(patternnamesdef)]} {
        foreach a $DTMRI(patternnamesdef) {
            set DTMRI($a,parameters) ""
        }
        set DTMRI(patternnamesdef) ""
    }

    # look for a file containing pattern information, if it exists, put this information in variable lists

    set DTMRI(patternFiles) ""
    set home [file normalize $env(HOME)]
    if { [file isdirectory $home/PatternsData/] } {
        eval lappend DTMRI(patternFiles) [glob $home/PatternsData/*]
    }

    if { [file isdirectory $PACKAGE_DIR_VTKDTMRI/../../../data/] } {
        eval lappend DTMRI(patternFiles) [glob $PACKAGE_DIR_VTKDTMRI/../../../data/*]
    }

    # put pattern information into modules variables
    foreach pfile $DTMRI(patternFiles) {
        set pattern [file tail $pfile]
        set pfile_valid 0
        if { [file readable $pfile] && [file isfile $pfile] } {
            set fp [open $pfile]
            while { ![eof $fp] } {

                set line [gets $fp]

                if {[lindex $line 0] == "vtkDTMRIprotocol"} {
                    set pfile_valid 1
                    continue
                }

                if { $line == "" || [string match "#*" $line] } {
                    continue
                }

                # only non-blank, non-comment, non-magic line is list of parameters
                set DTMRI($pattern,parameters) $line 
            }
            close $fp 

            if { $pfile_valid } {
                lappend DTMRI(patternnames) $pattern
            } else {
                unset -nocomplain DTMRI($pattern,parameters)
            }
        }
    }

    destroy $Module(DTMRI,fConv).fConvert.fPattern.mbPattern.menu
    eval {menu $Module(DTMRI,fConv).fConvert.fPattern.mbPattern.menu}  $Gui(WMA)

    # load existing patterns in the menu of the menubutton
    foreach z $DTMRI(patternnames) {
        set DTMRI(patt) $z
        pack forget $Module(DTMRI,fConv).fConvert.fPattern.mbPattern      
        $Module(DTMRI,fConv).fConvert.fPattern.mbPattern.menu add command -label $z -command "
        set DTMRI(selectedpattern) $DTMRI(patt)
        $Module(DTMRI,fConv).fConvert.fPattern.mbPattern config -text $DTMRI(patt) 
        set DTMRI($DTMRI(patt),tip) {Selected Protocol:\n $DTMRI(patt) \n Number of gradients:\n [lindex $DTMRI($DTMRI(patt),parameters) 0] \n First Gradient in Slice:\n [lindex $DTMRI($DTMRI(patt),parameters) 1] \n Last Gradient in Slice:\n [lindex $DTMRI($DTMRI(patt),parameters) 2] \n Baselines:\n from [lindex $DTMRI($DTMRI(patt),parameters) 3] to [lindex $DTMRI($DTMRI(patt),parameters) 4] \n B-value:\n [lindex $DTMRI($DTMRI(patt),parameters) 5] \n Gradients Directions:\n [lindex $DTMRI($DTMRI(patt),parameters) 6] \n The gradient order is:\n [lindex $DTMRI($DTMRI(patt),parameters) 7] interleaved}
     
        "

    }  

    pack  $Module(DTMRI,fConv).fConvert.fPattern.mbPattern -side left -padx $Gui(pad) -pady $Gui(pad) -after $Module(DTMRI,fConv).fConvert.fPattern.lLabel
}

 

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTipsPattern
#  Commented out
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc DTMRIUpdateTipsPattern {} {

#tkwait variable $DTMRI(selectedpattern)
#after 1000
#puts "Reading Module"

#catch {TooltipAdd $Module(DTMRI,fConv).fConvert.fPattern.mbPattern $DTMRI($DTMRI(selectedpattern),tip)}

#puts $DTMRI($DTMRI(selectedpattern),tip)

#}

  

#-------------------------------------------------------------------------------
# .PROC DTMRIViewProps
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIViewProps {} {
    puts $DTMRI(selectedpattern)

    if { [info exists DTMRI(selectedpattern)] } {
        DevInfoWindow $DTMRI($DTMRI(selectedpattern),tip)
    }

}
                                         

################################################################
# procedures for converting volumes into DTMRIs.
# TODO: this should happen automatically and be in MRML
################################################################

#-------------------------------------------------------------------------------
# .PROC ConvertVolumeToTensors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ConvertVolumeToTensors {} {
    global DTMRI Volume Tensor

    set v $DTMRI(convertID)
    if {$v == "" || $v == $Volume(idNone)} {
        puts "Can't create DTMRIs from None volume"
        return
    }

    # DTMRI creation filter
    catch "vtkImageDiffusionTensor DTMRI"
    
    if {$DTMRI(convert,nrrd) == 0} {
    puts "Loading pattern"
    if {[info exists DTMRI(selectedpattern)]} {
        
        set DTMRI(convert,numberOfGradients) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 0]
        set DTMRI(convert,firstGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 1]
        set DTMRI(convert,lastGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 2]
        set DTMRI(convert,firstNoGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 3]
        set DTMRI(convert,lastNoGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 4]
        set DTMRI(convert,lebihan) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 5]
        set DTMRI(convert,gradients) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 6]
        set DTMRI(convert,order) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 7]
        
        
    } else {
        DevErrorWindow "Please select a protocol"
        DTMRI Delete
        return
        
    }
    
    }   
    #Set b-factor
    DTMRI SetB $DTMRI(convert,lebihan)

# define if the conversion is volume interleaved or slice interleaved depending on the pattern


    # setup - these are now globals linked with GUI
    #set slicePeriod 8
    #set offsetsGradient "0 1 2 3 4 5"
    #set offsetsNoGradient "6 7"
    #set numberOfGradientImages 6
    #set numberOfNoGradientImages 2
    set count 0
    for {set i $DTMRI(convert,firstGradientImage)} \
            {$i  <= $DTMRI(convert,lastGradientImage) } \
            {incr i} {
        # 0-based offsets, so subtract 1
        lappend offsetsGradient [expr $i -1]
        incr count
    }
    puts $offsetsGradient
    set numberOfGradientImages $count
    set count 0
    for {set i $DTMRI(convert,firstNoGradientImage)} \
            {$i  <= $DTMRI(convert,lastNoGradientImage) } \
            {incr i} {
        # 0-based offsets, so subtract 1
        lappend offsetsNoGradient [expr $i -1]
        incr count
    }
    puts $offsetsNoGradient
    set numberOfNoGradientImages $count
    
    set slicePeriod \
    [expr $numberOfGradientImages+$numberOfNoGradientImages]
    
    puts "Slice period: $slicePeriod, Num No grad:$numberOfNoGradientImages" 
    
    set numberOfGradientImages $DTMRI(convert,numberOfGradients) 

    # Compute skip tables
    foreach val $offsetsGradient {
        set skipTableGradient($val) 0
    }
    foreach val $offsetsNoGradient {
        set skipTableNoGradient($val) 0
    }
    set skipGradient 0
    set skipNoGradient 0        
    foreach val $DTMRI(convert,nrrd,skip) {
        if {[info exists skipTableGradient($val)]} {
            set skipTableGradient($val) 1
            incr skipGradient
        } else {
            set skipTableNoGradient($val) 1
            incr skipNoGradient
        }
    }    


    if {$skipNoGradient == $numberOfNoGradientImages} {
       DevErrorWindow "Tensor cannot be computed without a baseline image.\n \
                        All baseline images are skipped."
       DTMRI Delete
       return
    }
    

    DTMRI SetNumberOfGradients [expr $numberOfGradientImages - $skipGradient]
        
    #puts $offsetsGradient 
    #puts $offsetsNoGradient
    
    set idx 0
    foreach val $offsetsGradient grad $DTMRI(convert,gradients) {
        if {$skipTableGradient($val) == 0} {
            eval {DTMRI SetDiffusionGradient $idx} $grad
            incr idx
        }
    }

    # volume we use for input
    set input [Volume($v,vol) GetOutput]

    # transform gradient directions to make DTMRIs in ijk
    catch "vtkTransform trans"    
    # special trick to avoid obnoxious windows warnings about legacy hack
    # for vtkTransform
    trans AddObserver WarningEvent ""

    puts "If not phase-freq flipped, swapping x and y in gradient directions"
    set swap [Volume($v,node) GetFrequencyPhaseSwap]
    set scanorder [Volume($v,node) GetScanOrder]
    
    
    #Two options: measurement frame known or not known.
        
    if {$DTMRI(convert,nrrd)} {
    
      #Get RAS To vtk Matrix
      catch "vtkMatrix4x4 _RasToVtk"
      eval "_RasToVtk DeepCopy" [Volume($v,node) GetRasToVtkMatrix]
      #Ignore translation
      _RasToVtk SetElement 0 3 0
      _RasToVtk SetElement 1 3 0
      _RasToVtk SetElement 2 3 0
      
      catch "vtkMatrix4x4 _Scale"
      set sp [[Volume($v,vol) GetOutput] GetSpacing]
      _Scale SetElement 0 0 [lindex $sp 0]
      _Scale SetElement 1 1 [lindex $sp 1]
      _Scale SetElement 2 2 [lindex $sp 2]
      
      #Set measurement frame matrix
      catch "vtkMatrix4x4 _MF"
      _MF Identity
      foreach axis "0 1 2" {
        set axdir [lindex $DTMRI(convert,measurementframe) $axis]
        foreach c "0 1 2" {
          _MF SetElement $c $axis [lindex $axdir $c]
        }
      }
            
      trans PostMultiply
      trans SetMatrix _MF
      trans Concatenate _RasToVtk
      trans Concatenate _Scale
      trans Update
      
      _RasToVtk Delete
      _Scale Delete
      _MF Delete
      
    } else {         
      
      if {$swap == 0} {    
        # Gunnar Farneback, April 6, 2004
        #
        # Apparently nobody understands all the involved coordinate
        # systems well enough to actually know how the gradient
        # directions should be transformed. This piece of code is
        # based on the hypothesis that the transformation matrices
        # only need to depend on the scan order and that the values
        # can be determined experimentally. It is perfectly possible
        # that this may break from changes elsewhere.
        #
        # If somebody reading this does know how to properly do these
        # transforms, please replace this code with something better.
        #
        # So far IS and PA have been experimentally verified.
        # SI is hypothesized to be the same as IS.
        # AP is hypothesized to be the same as PA.

        puts $scanorder
        switch $scanorder {
            "SI" -
            "IS" {
            set elements "\
                                    {0 1 0 0}  \
                                    {1 0 0 0}  \
                                    {0 0 -1 0}  \
                                    {0 0 0 1}  "
            }
            "AP" -
            "PA" {
            set elements "\
                                    {0 1 0 0}  \
                                    {-1 0 0 0}  \
                                    {0 0 -1 0}  \
                                    {0 0 0 1}  "
            }
            default {
            set elements "\
                                    {0 1 0 0}  \
                                    {1 0 0 0}  \
                                    {0 0 1 0}  \
                                    {0 0 0 1}  "
            }
        }

        set rows {0 1 2 3}
        set cols {0 1 2 3}    
        foreach row $rows {
            foreach col $cols {
                [trans GetMatrix] SetElement $row $col \
                    [lindex [lindex $elements $row] $col]
            }
        }    
    } else { 
        puts "Creating DTMRIs with -y for vtk compliance"
        trans Scale 1 -1 1
    }
    
    }

    #Hardcode specific parameters for MOSAIC. Experimental.
    if {$DTMRI(convert,order) == "MOSAIC"} {
      DTMRI SetAlpha 50
      set scanorder "IS"
      trans Identity
      trans Scale 1 1 -1
      foreach plane {0 1 2} {
        $DTMRI(mode,glyphsObject$plane) SetScaleFactor 2000
      }
    }
    
    DTMRI SetTransform trans
    trans Delete

    #check if input correct

    set dimz [lindex [$input GetDimensions] 2]
    set rest [expr $dimz%$slicePeriod]
    puts "Rest: $rest, Dimz: $dimz, slice Period: $slicePeriod"
   if {$rest != 0 && $DTMRI(convert,order) == "VOLUME"} {
       DevErrorWindow "Check your Input Data.\n Not enough number of slices"
       DTMRI Delete
       return
   }

  if {$DTMRI(convert,order) == "MOSAIC"} {
    #Build list of DICOM files
    set numFiles [Volume($v,node) GetNumberOfDICOMFiles]
    for {set k 0} {$k < $numFiles} {incr k} {
      lappend filesList [Volume($v,node) GetDICOMFileName $k]
    }
    set sortList [lsort -dictionary $filesList]
    
    set numElements [expr $numberOfNoGradientImages + $numberOfGradientImages]
    
    for {set k 0} {$k < $numElements} {incr k} {
      lappend mosaicIndx [lsearch -dictionary $filesList [lindex $sortList $k ]]
    }
    
    puts "$numberOfNoGradientImages"
    puts "$numberOfNoGradientImages"
    puts "Num Elements: $numElements"
    puts "Mosaic Indx: $mosaicIndx"
    
    
  }


    # produce input vols for DTMRI creation
    set inputNum 0
    set DTMRI(recalculate,gradientVolumes) ""
    foreach slice $offsetsGradient {
        catch "extract$slice Delete"
        vtkImageExtractSlices extract$slice
        extract$slice SetInput $input
        extract$slice SetModeTo$DTMRI(convert,order)
        extract$slice SetSliceOffset $slice
        extract$slice SetSlicePeriod $slicePeriod
        extract$slice SetNumberOfRepetitions $DTMRI(convert,numberOfRepetitions)
        extract$slice SetAverageRepetitions $DTMRI(convert,averageRepetitions)
        
        if {$DTMRI(convert,order) == "MOSAIC"} {
          extract$slice SetSliceOffset [lindex $mosaicIndx $slice]   
          extract$slice SetMosaicTiles $DTMRI(convert,mosaicTiles)
          extract$slice SetMosaicSlices $DTMRI(convert,mosaicSlices)
        }

        #puts "----------- slice $slice update --------"    
        extract$slice Update

        # pass along in pipeline
        if {$skipTableGradient($slice) == 0} {
            DTMRI SetDiffusionImage \
                $inputNum [extract$slice GetOutput]
            incr inputNum
        }
        
        # put the filter output into a slicer volume
        # Lauren this should be optional
        # make a MRMLVolume for this output
        if {[expr $slice % 5] == 0 && $DTMRI(convert,makeDWIasVolume)==1} {
          set name [Volume($v,node) GetName]
          set description "$slice gradient volume derived from volume $name"
          set name "gradient${slice}_$name"
          set id [DTMRICreateNewNode Volume($v,node) [extract$slice GetOutput] $name $description]
          # save id in case we recalculate the DTMRIs
          lappend DTMRI(recalculate,gradientVolumes) $id
          puts "created volume $id"
 
       }
        
    }
    # save ids in case we recalculate the DTMRIs
    set DTMRI(recalculate,noGradientVolumes) ""
    foreach slice $offsetsNoGradient {
        vtkImageExtractSlices extract$slice
        extract$slice SetInput $input
        extract$slice SetModeTo$DTMRI(convert,order)
        extract$slice SetSliceOffset $slice
        extract$slice SetSlicePeriod $slicePeriod
        extract$slice SetNumberOfRepetitions $DTMRI(convert,numberOfRepetitions)
        extract$slice SetAverageRepetitions $DTMRI(convert,averageRepetitions)
        
        
        if {$DTMRI(convert,order) == "MOSAIC"} {
          puts "[lindex $mosaicIndx $slice]"
          eval "extract$slice SetSliceOffset" [lindex $mosaicIndx $slice]     
          extract$slice SetMosaicTiles $DTMRI(convert,mosaicTiles)
          extract$slice SetMosaicSlices $DTMRI(convert,mosaicSlices)
        }
        #puts "----------- slice $slice update --------"    
        extract$slice Update


        # put the filter output into a slicer volume
        # Lauren this should be optional
        # make a MRMLVolume for this output
        if {[expr $slice % 2] == 0 && $DTMRI(convert,makeDWIasVolume)==1} {
          set name [Volume($v,node) GetName]
          set name noGradient${slice}_$name
          set description "$slice no gradient volume derived from volume $name"
          set id [DTMRICreateNewNode Volume($v,node) [extract$slice GetOutput] $name $description]
          # display this volume so the user knows something happened
          MainSlicesSetVolumeAll Back $id
        }
    }

 
    if {$numberOfNoGradientImages > 1} {
      catch "_math Delete"
      vtkImageMathematics _math
      _math SetOperationToAdd

      catch "_cast Delete"
      vtkImageCast _cast
      catch "slicebase Delete"
      vtkImageData slicebase 
      slicebase DeepCopy [_cast GetOutput]
      
      set firsthit 0
      foreach k $offsetsNoGradient {
        if {$skipTableNoGradient($k) == 0} {
            _cast SetInput [extract$k GetOutput]
            _cast SetOutputScalarTypeToFloat
            _cast Update
            if {$firsthit == 0} {
                set firsthit 1
                slicebase DeepCopy [_cast GetOutput]
                continue
            }
            set slicechange [_cast GetOutput]
            _math SetInput 0 slicebase
            _math SetInput 1 $slicechange
            _math Update
            slicebase DeepCopy [_math GetOutput]
        }
      }
      slicebase Delete
      catch "_math2 Delete"
      vtkImageMathematics _math2
      _math2 SetOperationToMultiplyByK
      _math2 SetConstantK [expr 1.0 / $numberOfNoGradientImages]
      _math2 SetInput 0 [_math GetOutput]
      _math2 SetInput 1 ""
      _math2 Update
      
      catch "_cast Delete"
      vtkImageCast _cast
      _cast SetInput [_math2 GetOutput]
      _cast SetOutputScalarType [[extract[lindex $offsetsNoGradient 0] GetOutput] GetScalarType]
      _cast Update
      # set the no diffusion input
      DTMRI SetNoDiffusionImage [_cast GetOutput]
      set baseline [_cast GetOutput]
       
    } else {
      set slice [lindex $offsetsNoGradient 0]
      DTMRI SetNoDiffusionImage [extract$slice GetOutput]
      set baseline [extract$slice GetOutput]
    }
    
    #Make a MRML node with BaseLine
     set name [Volume($v,node) GetName]
     set description "Baseline from volume $name"
     set name ${name}_Baseline
     set id [DTMRICreateNewNode Volume($v,node) $baseline $name $description]
     
      # average gradient images for display and checking mechanism. 
      catch "vtkImageMathematics math_g"
      math_g SetOperationToAdd
      
      catch "_cast_g Delete"      
      vtkImageCast _cast_g
      _cast_g SetInput [extract[lindex $offsetsGradient 0] GetOutput]
      _cast_g SetOutputScalarTypeToFloat
      _cast_g Update
      
      catch "slicebase Delete"
      vtkImageData slicebase
      slicebase DeepCopy [_cast_g GetOutput]
      
      for {set k 1} {$k < $numberOfGradientImages} {incr k} {
        _cast_g SetInput [extract[lindex $offsetsGradient $k] GetOutput]
        _cast_g SetOutputScalarTypeToFloat
        _cast_g Update
    
        set slicechange [_cast_g GetOutput]
        math_g SetInput 0 slicebase
        math_g SetInput 1 $slicechange
        math_g Update
        slicebase DeepCopy [math_g GetOutput]
      }
      slicebase Delete
      catch "math2_g Delete"
      vtkImageMathematics math2_g
      math2_g SetOperationToMultiplyByK
      math2_g SetConstantK [expr 1.0 / $numberOfGradientImages]
      math2_g SetInput 0 [math_g GetOutput]
      math2_g SetInput 1 ""
      math2_g Update
      
      catch "_cast_g Delete"
      vtkImageCast _cast_g
      _cast_g SetInput [math2_g GetOutput]
      _cast_g SetOutputScalarType [[extract[lindex $offsetsGradient 0] GetOutput] GetScalarType]
      _cast_g Update
      
      set baseline [_cast_g GetOutput]
 
     #Make a MRML node with Average Gradient
     set name [Volume($v,node) GetName]
     set description "Average gradient from volume $name"
     set name ${name}_AvGradient
     set id [DTMRICreateNewNode Volume($v,node) $baseline $name $description]

    #kill objects used for baseline and average gradient images
    if {$numberOfNoGradientImages > 1} {
        #_math SetOutput ""
        #_math2 SetOutput ""
        #_cast SetOutput ""
        _math Delete
        _math2 Delete
        _cast Delete
    }
    
    #math_g SetOutput ""
    #math2_g SetOutput ""
    math_g Delete
    math2_g Delete
    #_cast_g SetOutput ""
    _cast_g Delete


    #Perform Tensor Estimation
    puts "----------- DTMRI update --------"
    #DTMRI DebugOn
    DTMRI Update
    puts "----------- after DTMRI update --------"

    # kill DWI objects
    foreach slice $offsetsGradient {
        #extract$slice SetOutput ""
        extract$slice Delete
    }
    foreach slice $offsetsNoGradient {
        #extract$slice SetOutput ""
        extract$slice Delete
    }

    # put output into a Tensor volume
    # Lauren if volumes and tensos are the same
    # this should be done like the above
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    #Take the baseline as node to copy
    $newvol Copy Volume($id,node)
    $newvol SetDescription "DTMRI volume"
    $newvol SetName "[Volume($v,node) GetName]_Tensor"
    set n [$newvol GetID]

    #puts "SPACING [$newvol GetSpacing] DIMS [$newvol GetDimensions] MAT [$newvol GetRasToIjkMatrix]"
    # fix the image range in the node (less slices than the original)
    set extent [[Volume($id,vol) GetOutput] GetExtent]
    set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
    eval {$newvol SetImageRange} $range
    # recompute the matrices using this offset to center vol in the cube
    set order [$newvol GetScanOrder]
            
    puts "SPACING [$newvol GetSpacing] DIMS [$newvol GetDimensions] MAT [$newvol GetRasToIjkMatrix]"
    TensorCreateNew $n 
       
    # Set the slicer object's image data to what we created
    DTMRI Update

    Tensor($n,data) SetImageData [DTMRI GetOutput]
    
     #Set Tensor matrices
     set spacing [Tensor($n,node) GetSpacing]
     DTMRIComputeRasToIjkFromCorners Volume($v,node) Tensor($n,node) [[Tensor($n,data) GetOutput] GetExtent] $spacing
    
    # Registration
    # put the new tensor volume inside the same transform as the Original volume
    # by inserting it right after that volume in the mrml file
    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set widx 0} {$widx < $nitems} {incr widx} {
        if { [Mrml(dataTree) GetNthItem $widx] == "Tensor($n,node)" } {
            break
        }
    }
    if { $widx < $nitems } {
        Mrml(dataTree) RemoveItem $widx
        Mrml(dataTree) InsertAfterItem Volume($v,node) Tensor($n,node)
        MainUpdateMRML
    }
    
    
    
    #Compute Mask: Try to extract an rough mask for whitematter
    set mid [DTMRIComputeTensorMask Volume($id,node)]
    
    #Save in a table the relation between mask and associated tensor
    set DTMRI(maskTable,$n) $mid
    
    
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        DevWarningWindow "Tensor node has not been created. Error in the conversion process."
    } else {
        # Activate the new data object
        DTMRISetActive $n
    }
    
    DTMRI SetOutput ""
    DTMRI Delete

    # This updates all the buttons to say that the
    # Volume List has changed.
    MainUpdateMRML

    # display volume so the user knows something happened
    MainSlicesSetVolumeAll Back $id

    # display the new volume in the slices
    RenderSlices

}

proc DTMRIConvertDWIToTensorNRRD {} {

    global DTMRI Volume Tensor

    set v $DTMRI(convertID)
    if {$v == "" || $v == $Volume(idNone)} {
        puts "Can't create DTMRIs from None volume"
        return
    }
    
    # volume we use for input
    set input [Volume($v,vol) GetOutput]

    # DTMRI creation filter
    set _tensorEstim [DevNewInstance vtkEstimateDiffusionTensor _tensorEstim]
    
    set numGradients $DTMRI(convert,nrrd,numberOfGradients)
    
    # Appender in a multicomponent image
    set _appender [DevNewInstance vtkImageAppendComponents _appender]
    
    # Extract all the volumes
    for {set slice 0} { $slice < $numGradients } {incr slice} {
        catch "extract$slice Delete"
        vtkImageExtractSlices extract$slice
        extract$slice SetInput $input
        extract$slice SetModeToVOLUME
        extract$slice SetSliceOffset $slice
        extract$slice SetSlicePeriod $numGradients
        $_appender AddInput [extract$slice GetOutput]
    }
    
    $_appender Update
    
    #Delete extractors
    for {set slice 0} { $slice < $numGradients } { incr slice} {
       extract$slice Delete
    }   
    
    
    # Compute a transformation to bring gradients to Ijk frame
    set _trans [DevNewInstance vtkTransform _trans]
    DTMRIComputeGradientTransformation $input $_trans

    $_tensorEstim SetInput 0 [$_appender GetOutput]
    $_tensorEstim SetNumberOfGradients $numGradients
    $_tensorEstim SetTransform $_trans
    
    # Get flat gradients: We need to do some parsing from
    # the raw key value pairs
    for {set grad 0} { $grad < $numGradients } {incr grad} {
       eval "$_tensorEstim SetDiffusionGradient $grad" \
            [lindex $DTMRI(convert,nrrd,gradients) $grad] 
       $_tensorEstim SetB $grad [lindex $DTMRI(convert,nrrd,bValues) $grad]
    }
    
    #Perform tensor Estimation
    $_tensorEstim Update
    
    
    #Get gradient image and baseline and make mrml nodes
    #Make a MRML node with BaseLine
    set name [Volume($v,node) GetName]
    set description "Baseline from volume $name"
    set name ${name}_Baseline
    set id [DTMRICreateNewNode Volume($v,node) [$_tensorEstim GetOutput] $name $description]
     
    
    #Mrml node for tensor output  
    set newvol [MainMrmlAddNode Volume Tensor]
    #Take the baseline as node to copy
    $newvol Copy Volume($id,node)
    $newvol SetDescription "DTMRI volume"
    $newvol SetName "[Volume($v,node) GetName]_Tensor"
    set n [$newvol GetID]

    #puts "SPACING [$newvol GetSpacing] DIMS [$newvol GetDimensions] MAT [$newvol GetRasToIjkMatrix]"
    # fix the image range in the node (less slices than the original)
    set extent [[Volume($id,vol) GetOutput] GetExtent]
    set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
    eval {$newvol SetImageRange} $range
    # recompute the matrices using this offset to center vol in the cube
    set order [$newvol GetScanOrder]
            
    puts "SPACING [$newvol GetSpacing] DIMS [$newvol GetDimensions] MAT [$newvol GetRasToIjkMatrix]"
    TensorCreateNew $n     
    
    Tensor($n,data) SetImageData [$_tensorEstim GetOutput]
    
    #Set Tensor matrices
    set spacing [Tensor($n,node) GetSpacing]
    DTMRIComputeRasToIjkFromCorners Volume($v,node) Tensor($n,node) [[Tensor($n,data) GetOutput] GetExtent] $spacing
    
    # Registration
    # put the new tensor volume inside the same transform as the Original volume
    # by inserting it right after that volume in the mrml file
    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set widx 0} {$widx < $nitems} {incr widx} {
        if { [Mrml(dataTree) GetNthItem $widx] == "Tensor($n,node)" } {
            break
        }
    }
    if { $widx < $nitems } {
        Mrml(dataTree) RemoveItem $widx
        Mrml(dataTree) InsertAfterItem Volume($v,node) Tensor($n,node)
        MainUpdateMRML
    }
    
    #Compute tensor Mask
    #I need Baseline Image
    # Not done yet: DTMRIComputeTensorMask
    
    #Delete objects
    $_appender Delete
    $_trans Delete
    $_tensorEstim Delete
}


proc DTMRIComputeGradientTransformation { v trans } {

   global DTMRI Volume

   set v $DTMRI(convertID)
   
   #Get RAS To vtk Matrix
   set _RasToVtk [DevNewInstance vtkMatrix4x4 _RasToVTk] 
   eval "$_RasToVtk DeepCopy" [Volume($v,node) GetRasToVtkMatrix]
   #Ignore translation
   $_RasToVtk SetElement 0 3 0
   $_RasToVtk SetElement 1 3 0
   $_RasToVtk SetElement 2 3 0
   
   set _Scale [DevNewInstance vtkMatrix4x4 _Scale]
   set sp [[Volume($v,vol) GetOutput] GetSpacing]
   $_Scale SetElement 0 0 [lindex $sp 0]
   $_Scale SetElement 1 1 [lindex $sp 1]
   $_Scale SetElement 2 2 [lindex $sp 2]
   
   #Set measurement frame matrix
   set _MF [DevNewInstance vtkMatrix4x4 _MF]
   $_MF Identity
   foreach axis "0 1 2" {
     set axdir [lindex $DTMRI(convert,measurementframe) $axis]
     foreach c "0 1 2" {
       $_MF SetElement $c $axis [lindex $axdir $c]
     }
   }
         
   $trans PostMultiply
   $trans SetMatrix $_MF
   $trans Concatenate $_RasToVtk
   $trans Concatenate $_Scale
   $trans Update
      
   $_RasToVtk Delete
   $_Scale Delete
   $_MF Delete
}

#-------------------------------------------------------------------------------
# .PROC DTMRICreateNewNode
# 
# .ARGS
# vtkMrmlVolumeNode node: volume node to be used for thresholding
# .END
#-------------------------------------------------------------------------------
proc DTMRIComputeTensorMask {node} {
    global DTMRI
    
    if {[info command  vtkITKNewOtsuThresholdImageFilter] == ""} { 
        #Mask cannot be computed
        return;
    }
    
    set id [$node GetID]
     #Create mask based on thersholding of DWI
    catch "_otsu Delete"
    vtkITKNewOtsuThresholdImageFilter _otsu
    _otsu SetInput [Volume($id,vol) GetOutput]
    _otsu SetOmega [expr 1 + $DTMRI(convert,mask,omega)]
    _otsu SetOutsideValue 1
    _otsu SetInsideValue 0
    _otsu Update
    
    puts "Threshold: [_otsu GetThreshold]"
    #Grab otsu output: avoid bug with vtkITK pipeline output release
    catch "_mask Delete"
    vtkImageData _mask
    _mask DeepCopy [_otsu GetOutput]
    
    #Free space
    _otsu Delete
     
    set dims [_mask GetDimensions]
    set px [expr round([lindex $dims 0]/2)]
    set py [expr round([lindex $dims 1]/2)]
    set pz [expr round([lindex $dims 2]/2)]
       
    catch "_cast Delete"
    vtkImageCast _cast
     _cast SetInput _mask
     _cast SetOutputScalarTypeToUnsignedChar
     _cast Update    
       
     _mask Delete  
     #Connected components
     catch "_con Delete"
     vtkImageSeedConnectivity _con
     _con SetInput [_cast GetOutput]
     _con SetInputConnectValue 1
     _con SetOutputConnectedValue 1
     _con SetOutputUnconnectedValue 0
     _con AddSeed $px $py $pz
     _con Update

     _cast Delete
   
     catch "_cast Delete"
     vtkImageCast _cast
     _cast SetInput [_con GetOutput]
     _cast SetOutputScalarTypeToShort
     _cast Update
       
     _con Delete

   if { $DTMRI(convert,mask,removeIslands) } {

      catch "_conn Delete"
      vtkImageConnectivity _conn
      _conn SetBackground 1
      _conn SetMinForeground -32768
      _conn SetMaxForeground 32767
      _conn SetFunctionToRemoveIslands
      _conn SetMinSize 10000
      _conn SliceBySliceOn
      _conn SetInput [_cast GetOutput]
   
      _conn Update 

    }
    
     #Free space
 
     #Grab Output           
    set source_name [$node GetName]
    set name "Tensor_mask-$source_name "
    set description "Mask for volume $name"            
    
    if {$DTMRI(convert,mask,removeIslands) == 1} {
        set mid [DTMRICreateNewNode $node [_conn GetOutput] $name $description]
        _conn Delete
    } else {
       set mid [DTMRICreateNewNode $node [_cast GetOutput] $name $description]
    }
    
    #Set labelmap
    # -1 is id for Label lookup table
    Volume($mid,node) LabelMapOn
    Volume($mid,node) SetLUTName -1
    
    #Clean objects
    _cast Delete
    
    #Return mask id
    return $mid
    
}

#-------------------------------------------------------------------------------
# .PROC DTMRICreateNewNode
# 
# .ARGS
# vtkMrmlVolumeNode refnode
# vtkImageData voldata
# string name
# string description
# .END
#-------------------------------------------------------------------------------
proc DTMRICreateNewNode {refnode voldata name description} {
    global Volume
    
        
    set scanorder [$refnode GetScanOrder]
    set id [DTMRICreateNewVolume $voldata $name $description \
                                 $scanorder]

     # fix the image range in the node (less slices than the original)
     set extent [[Volume($id,vol) GetOutput] GetExtent]
     set spacing [Volume($id,node) GetSpacing]
     set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
     eval {Volume($id,node) SetImageRange} $range

     #eval {$globalArray($id,node) SetSpacing} [$voldata GetSpacing]

     #Compute node matrices based on the refnode
     DTMRIComputeRasToIjkFromCorners $refnode Volume($id,node) $extent $spacing
 
     # update slicer internals
     MainVolumesUpdate $id

     # Registration
     # put the new volume inside the same transform as the Original volume
     # by inserting it right after that volume in the mrml file
     set nitems [Mrml(dataTree) GetNumberOfItems]
     for {set widx 0} {$widx < $nitems} {incr widx} {
       if { [Mrml(dataTree) GetNthItem $widx] == "Volume($id,node)" } {
             break
         }
       }
       if { $widx < $nitems } {
         Mrml(dataTree) RemoveItem $widx         
         Mrml(dataTree) InsertAfterItem $refnode Volume($id,node)
         MainUpdateMRML
      }
      
      return $id
}

#-------------------------------------------------------------------------------
# .PROC DTMRICreateNewVolume
# 
# .ARGS
# string volume
# string name
# string desc
# string scanOrder
# .END
#-------------------------------------------------------------------------------
proc DTMRICreateNewVolume {volume name desc scanOrder} {
  global Volume View
   
  set n [MainMrmlAddNode Volume]
  set id [$n GetID]
  MainVolumesCreate $id
  $n SetScanOrder $scanOrder     
  $n SetName $name
  $n SetDescription $desc
  set dim [$volume GetDimensions]
  eval "$n SetDimensions" [lindex $dim 0] [lindex $dim 1]
  eval "$n SetSpacing" [$volume GetSpacing]
  set extent [$volume GetExtent]
  set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
  eval {$n SetImageRange} $range
  $n ComputeRasToIjkFromScanOrder $scanOrder
  
  # get the pixel size, etc. from the data and set it in the node
  #[Volume($id,vol) GetOutput] DeepCopy $volume
  Volume($id,vol) SetImageData $volume
  MainUpdateMRML
  MainVolumesSetActive $id
  
  
  set fov 0
  for {set i 0} {$i < 2} {incr i} {
    set dim     [lindex [Volume($id,node) GetDimensions] $i]
    set spacing [lindex [Volume($id,node) GetSpacing] $i]
    set newfov     [expr $dim * $spacing]
    if { $newfov > $fov } {
       set fov $newfov
     }
  }
  set View(fov) $fov
  MainViewSetFov
  
  return $id

}

#-------------------------------------------------------------------------------
# .PROC DTMRIComputeRasToIjkFromCorners
# 
# .ARGS
# vtkMrmlNode refnode
# vtkMrmlNode volid: id of the Mrml node to compute the transform.
# array extent: extent of the volume. Needed to compute center
# .END
#-------------------------------------------------------------------------------
proc DTMRIComputeRasToIjkFromCorners {refnode node extent {spacing ""}} {

  #Get Ras to Ijk Matrix from reference volume
  catch "_Ras Delete"
  vtkMatrix4x4 _Ras
  eval "_Ras DeepCopy" [$refnode GetRasToIjkMatrix]
  
  
  catch "_norm Delete"
  vtkMath _norm
  
  #Fix the spacing in case the refnode came with other spacing that 
  # the one that we want
  
  
  if {$spacing != ""} {
  
    #Invert to get IjkToRas
    _Ras Invert
  
    foreach ax "0 1 2" {
        set x ""
        foreach c "0 1 2" {
            lappend x [_Ras GetElement $c $ax]  
        }
        set norm [eval "_norm Norm" $x]
        set scaling [expr (1.0/$norm) * [lindex $spacing $ax]]
        foreach c "0 1 2" {
          _Ras SetElement $c $ax  [expr [lindex $x $c] * $scaling]
        }
    }
   
     #Invert back to get RasToIjk with correct spacing
    _Ras Invert       
   
    _norm Delete
  }


  #Set Translation to center of the output volume.
  
  #If refnode volume is centered, set to center
  #otherwise, use the origin given by refnode
  
  #Check if refnode is centered
  regexp {[A-Za-z]*} $refnode nodetype
  set v [$refnode GetID]
  if {$nodetype == "Tensor"} {
    set refvol "${nodetype}($v,data)"
  } else {
    set refvol "${nodetype}($v,vol)"
  }
  set refextent [[$refvol GetOutput] GetExtent]
  set reforiginx [expr ([lindex $refextent 1] - [lindex $refextent 0])/2.0]
  set reforiginy [expr ([lindex $refextent 3] - [lindex $refextent 2])/2.0]
  set reforiginz [expr ([lindex $refextent 5] - [lindex $refextent 4])/2.0]
  
  if { [_Ras GetElement 0 3] == $reforiginx && \
       [_Ras GetElement 1 3] == $reforiginy && \
       [_Ras GetElement 2 3] == $reforiginz } {
    #This is a particular thing of the slicer: all volumes are centered in their centroid.
    _Ras SetElement 0 3 [expr ([lindex $extent 1] - [lindex $extent 0])/2.0]
    _Ras SetElement 1 3 [expr ([lindex $extent 3] - [lindex $extent 2])/2.0]
    _Ras SetElement 2 3 [expr ([lindex $extent 5] - [lindex $extent 4])/2.0]
  }
      
  set dims "[expr [lindex $extent 1] - [lindex $extent 0] + 1] \
              [expr [lindex $extent 3] - [lindex $extent 2] + 1] \
              [expr [lindex $extent 5] - [lindex $extent 4] + 1]"           

  VolumesComputeNodeMatricesFromRasToIjkMatrix $node _Ras $dims

  _Ras Delete
  MainUpdateMRML

}
