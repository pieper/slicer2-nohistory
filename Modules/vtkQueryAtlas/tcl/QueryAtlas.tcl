#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: QueryAtlas.tcl,v $
#   Date:      $Date: 2006/01/06 17:58:01 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        QueryAtlas.tcl
# PROCEDURES:  
#   QueryAtlasInit
#   QueryAtlasBIRNButtonZoom level
#   QueryAtlasBIRNZoom level
#   QueryAtlasBIRNSliderZoom level
#   BIRNAnimateZoom
#   QueryAtlasBIRNSetcardZoom zoom
#   QueryAtlasBIRNEnter
#   QueryAtlasBIRNExit
#   QueryAtlasBuildGUI
#   QueryAtlasBuildVTK
#   QueryAtlasEnter
#   QueryAtlasExit
#==========================================================================auto=



#=== INITIALISATION ===========================================================================================================================================


#-------------------------------------------------------------------------------
# .PROC QueryAtlasInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasInit {} {
   global QueryAtlas Module Volume Model Locator

   set m QueryAtlas

   # Module Summary Info
   #------------------------------------
   # Description:
   #  Give a brief overview of what your module does, for inclusion in the 
   #  Help->Module Summaries menu item.
   set Module($m,overview) "Module for TextureText, Cards, and other QueryAtlas elements."

   #  Provide your name, affiliation and contact information so you can be 
   #  reached for any questions people may have regarding your module. 
   #  This is included in the  Help->Module Credits menu item.
   set Module($m,author) "Steve Pieper and Mike McKenna, Isomics/BWH/Small Design Firm, pieper@bwh.harvard.edu"
   set Module($m,category) "Application"

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


   set Module($m,row1List) "Help Query BIRN"
   set Module($m,row1Name) "{Help} {Query} {BIRN}"
   set Module($m,row1,tab) "Query"
   set Module($m,row2List) ""
   set Module($m,row2Name) ""
   set Module($m,row2,tab) ""


   #
   # set the tab behavior on enter or exit 
   #

   set Module($m,BIRN,procEnter) QueryAtlasBIRNEnter
   set Module($m,BIRN,procExit) QueryAtlasBIRNExit
    

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
   #   set Module($m,procVTK) QueryAtlasBuildVTK
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
   set Module($m,procGUI) QueryAtlasBuildGUI
   set Module($m,procVTK) QueryAtlasBuildVTK
   set Module($m,procEnter) QueryAtlasEnter
   set Module($m,procExit) QueryAtlasExit

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
       {$Revision: 1.6 $} {$Date: 2006/01/06 17:58:01 $}]

   # Initialize module-level variables
   #------------------------------------
   # Description:
   #   Keep a global array with the same name as the module.
   #   This is a handy method for organizing the global variables that
   #   the procedures in this module and others need to access.
   #
   
   # BIRN temporary stuff
   set QueryAtlas(BIRN,CurrentZoom) 0
   set QueryAtlas(BIRN,Loaded) 0
   set QueryAtlas(BIRN,BIRNCardManager) 0
   set QueryAtlas(BIRN,AnimateZoomTarget) 0
   set QueryAtlas(BIRN,AnimateZoom) 0
   set QueryAtlas(BIRN,AnimateZoomMs) 5
   

   vtkTextureFontManager dummyFontManager
   dummyFontManager SetDefaultFreetypeDirectory \
      [file normalize $::PACKAGE_DIR_VTKQueryAtlas/../../../data/fonts]
   set dummy [dummyFontManager GetDefaultFreetypeDirectory]
   #puts "Default font dir for dummyFont = $dummy"


    #
    # start the slicer daemon by default on the default port 
    # -- the user will be asked to approve any connection requests
    #

    slicerd_start
   
}



#=== BIRN =====================================================================================================================================================


#-------------------------------------------------------------------------------
# .PROC QueryAtlasBIRNButtonZoom
# from icon button press - setup to start an animated zoom
# .ARGS
# int level 
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBIRNButtonZoom {level} {
    global QueryAtlas
    
    #puts "QueryAtlasBIRNButtonZoom $level"
    
    set QueryAtlas(BIRN,AnimateZoom) 1
    set QueryAtlas(BIRN,AnimateZoomTarget) $level
    
    BIRNAnimateZoom
}    


#-------------------------------------------------------------------------------
# .PROC QueryAtlasBIRNZoom
# old icon button press - jump right to new level - unused?
# .ARGS
# int level 
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBIRNZoom {level} {
    #puts "QueryAtlasBIRNZoom $level"
        
    # also set var to set slider - can't do it in QueryAtlasBIRNSetCardZoom or we'll loop
    set ::QueryAtlas(BIRN,CurrentZoom) $level
    
    QueryAtlasBIRNSetCardZoom $level
}


#-------------------------------------------------------------------------------
# .PROC QueryAtlasBIRNSliderZoom
# from slider press - setup to start an animated zoom
# .ARGS
# int level 
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBIRNSliderZoom {level} {
    global QueryAtlas
    
    #puts "QueryAtlasBIRNSliderZoom $level"
    
    # stop an animated zoom if one is running
    set QueryAtlas(BIRN,AnimateZoom) 0
    
    # not really needed, but set future target to new current value
    set QueryAtlas(BIRN,AnimateZoomTarget) $level
    
    # don't need to set the value, the slider already set it w -variable
    QueryAtlasBIRNSetCardZoom $level
}    


#-------------------------------------------------------------------------------
# .PROC BIRNAnimateZoom
#
# Transition to a different BIRN zoom level over time.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc BIRNAnimateZoom {} {
    global QueryAtlas

    if {$QueryAtlas(BIRN,AnimateZoom) == 1} {
        #set p [expr (1.0 * $View(rockCount)) / $View(rockLength)]
        #set amt [expr 1.5 * cos ( 2.0 * 3.1415926 * ($p - floor($p)) ) ]
        #incr View(rockCount)

        set amt [expr $QueryAtlas(BIRN,AnimateZoomTarget) - $QueryAtlas(BIRN,CurrentZoom) ]
        
        #puts "BIRNAnimateZoom amt: $amt  =  AnimateZoomTarget: $QueryAtlas(BIRN,AnimateZoomTarget)  -  CurrentZoom: $QueryAtlas(BIRN,CurrentZoom)"
        
        if {$amt > 0.1} {set amt 0.1} else {
            if {$amt < -0.1} {set amt -0.1} else {
                # after this step, we've reached the goal, turn off animate
                set QueryAtlas(BIRN,AnimateZoom) 0
            }
        }
        
        set amt2 [expr $amt + $QueryAtlas(BIRN,CurrentZoom)]
        
        #puts "BIRNAnimateZoom amt2: $amt2"
                
        # both set CurrentZoom, and call SetCardZoom
        
        set ::QueryAtlas(BIRN,CurrentZoom) $amt2
        QueryAtlasBIRNSetCardZoom $amt2
        
        # render happens in QueryAtlasBIRNSetCardZoom
        #Render3D

        update idletasks
        after $QueryAtlas(BIRN,AnimateZoomMs) BIRNAnimateZoom
    }
}


#-------------------------------------------------------------------------------
# .PROC QueryAtlasBIRNSetcardZoom
#
#  Actually update the BIRN Card models to the new zoom level.
#
# .ARGS
# int zoom
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBIRNSetCardZoom {zoom} {
   global QueryAtlas
   
   #puts "QueryAtlasBIRNSetCardZoom $zoom"

    # no - will cause loop w/ slider
    #set ::QueryAtlas(BIRN,CurrentZoom) $zoom

    if {$QueryAtlas(BIRN,Loaded)} {
      QueryAtlas(BIRN,BIRNCardManager) SetCardZoom $zoom
      
      # PEND - is this Render3D really needed here??
      Render3D
   } else {
       # silently ignore - this case happens in startup
   }
}


#-------------------------------------------------------------------------------
# .PROC QueryAtlasBIRNEnter
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBIRNEnter {} {
   global QueryAtlas Module
   

   # only load if not already done
   if {$QueryAtlas(BIRN,Loaded) == 0} {
      # setup DIR path to the BIRN card data
      set birnDir [file normalize \
         [file join $::PACKAGE_DIR_VTKQueryAtlas ".." ".." ".." data BIRN]]
      #puts "birnDir = $birnDir"

      vtkBIRNCardManager QueryAtlas(BIRN,BIRNCardManager)

      QueryAtlas(BIRN,BIRNCardManager) SetDirBase $birnDir
      
      QueryAtlas(BIRN,BIRNCardManager) SetRenderer [lindex $Module(Renderers) 0]
 
      #QueryAtlas(BIRN,BIRNCardManager) SetScaleCards 8   
      QueryAtlas(BIRN,BIRNCardManager) SetScaleCards 14 
      
      #QueryAtlas(BIRN,BIRNCardManager) SetScaleDownFlag 1
      
      QueryAtlas(BIRN,BIRNCardManager) SetCardSpacing 150
     
      
      # it doesn't really make much sense to sort these cards, but turn this on to do so.
      #vtkSorter sort
      #sort SetRenderer [lindex $Module(Renderers) 0]
      #QueryAtlas(BIRN,BIRNCardManager) SetSorter sort
      
     
      QueryAtlas(BIRN,BIRNCardManager) LoadSet
      set QueryAtlas(BIRN,Loaded) 1
   }
      
   # cards will automatically be shown w/ QueryAtlasBIRNSetCardZoom (in case they were hidden in QueryAtlasBIRNExit)

   # PEND - setup the initial camera
   
   # set card # to 0
   QueryAtlasBIRNSetCardZoom 0
}


#-------------------------------------------------------------------------------
# .PROC QueryAtlasBIRNExit
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBIRNExit {} {
   global QueryAtlas

   # hide cards
   if {$QueryAtlas(BIRN,Loaded)} {
      QueryAtlas(BIRN,BIRNCardManager) SetVisibility 0
      Render3D
   }
}


#=== USER INTERFACE ===========================================================================================================================================

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
# .PROC QueryAtlasBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBuildGUI {} {
    global Gui QueryAtlas Module Volume Model
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(QueryAtlas,fStuff)
    
    # This is a useful comment block that makes reading this easy for all:
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Server
    # Help
    # Joints
    # Display
    # Plan
    # Perform
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    The QueryAtlas represents data from multiple text, image, and 3D sources
    integrated with the 3D environment.
    <p>
    description by tab:
    <br>
    <ul>
    <li><b>Help:</b> Shows the help tab.
    <li><b>BIRN:</b> Displays Prototype BIRN QueryAtlas interface.
    </ul>
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags QueryAtlas $help
    MainHelpBuildGUI QueryAtlas

    #-------------------------------------------
    # Query frame
    #-------------------------------------------
    set fQuery $Module(QueryAtlas,fQuery)
    set f $fQuery

    DevAddButton $f.bQueryAtlasmDemo "Morphometry Demo" "QueryAtlas_mdemo"
    DevAddButton $f.bQueryAtlasfDemo "Function Demo" "QueryAtlas_fdemo"

    pack $f.bQueryAtlasmDemo -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    pack $f.bQueryAtlasfDemo -side top -padx $Gui(pad) -pady $Gui(pad) -fill x


    #-------------------------------------------
    # BIRN frame
    #-------------------------------------------
    set fBIRN $Module(QueryAtlas,fBIRN)
    set f $fBIRN


    # BIRN ZOOM WIDGET FRAME - use sub-frame to layout a label next to the slider

    frame $f.fZoom -bg $Gui(activeWorkspace)
    pack $f.fZoom -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    set fz $f.fZoom
    
    
    # LABEL "Zoom"   

    eval {label $fz.lZoom -text Zoom -width 5} $Gui(WLA)
    pack $fz.lZoom -padx 3 -side left


    # SLIDER
    
    # PEND - make the slider go from 1 - vtkBIRNCard::sNumCards
    #   this matches the visual display - the software actually goes from 
    #   0 - (vtkBIRNCard::sNumCards - 1)
   
    scale $fz.sZoom -orient vertical \
        -command QueryAtlasBIRNSliderZoom \
        -from 0 -to 9 -variable ::QueryAtlas(BIRN,CurrentZoom)
    $fz.sZoom configure \
        -font {helvetica 8}\
        -bg $::Gui(activeWorkspace) -fg $::Gui(textDark) \
        -activebackground $::Gui(activeButton) -troughcolor $::Gui(normalButton) \
        -highlightthickness 0 -showvalue 1 \
        -bd $::Gui(borderWidth) -relief flat -resolution 0.1 -length 360
    #pack $fz.sZoom -padx 3 -side left
    pack $fz.sZoom -padx 0 -side left

        

    # LOAD ICONS / BUTTONS for different levels  
         
    # sub-frame to layout the icon-buttons
    frame $fz.fIcons -bg $Gui(activeWorkspace)
    set fi $fz.fIcons
    pack $fi -padx 3 -side left

    foreach i "0 1 2 3 4 5 6 7 8 9" {
        #frame $fi.fIcon$i -bg $Gui(activeWorkspace)
        #set fii $fi.fIcon$i

        set iconFile [file normalize [file join $::PACKAGE_DIR_VTKQueryAtlas ".." ".." ".." data BIRN icons "level$i.gif"]]
        if {[file exists $iconFile]} {
            image create photo iIcon$i -file $iconFile -width 32 -height 32
            eval {button $fi.bIcon$i -image iIcon$i -command "QueryAtlasBIRNButtonZoom $i"} $Gui(WBA)
        } else {
            eval {button $fi.bIcon$i -text "Level $i"  -command "QueryAtlasBIRNButtonZoom $i"} $Gui(WBA)
        }
        #pack $fi.bIcon$i -padx 3 -side left
        pack $fi.bIcon$i
    #    grid $fii.bIcon$i -pady 1 -padx 3 -sticky e
    }
}



#-------------------------------------------------------------------------------
# .PROC QueryAtlasBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasBuildVTK {} {
    global QueryAtlas

}



#-------------------------------------------------------------------------------
# .PROC QueryAtlasEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. When entering the QueryAtlas Slicer tabs, setup the 
# view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasEnter {} {
    global QueryAtlas
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)

    # not yet defined:Fbirnen
    
    #pushEventManager $QueryAtlas(eventManager)
}


#-------------------------------------------------------------------------------
# .PROC QueryAtlasExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  Cleanup the view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc QueryAtlasExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager

    QueryAtlasBIRNExit 
}
