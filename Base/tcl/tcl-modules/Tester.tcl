#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Tester.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:01 $
#   Version:   $Revision: 1.21 $
# 
#===============================================================================
# FILE:        Tester.tcl
# PROCEDURES:  
#   TesterInit
#   TesterBuildGUI
#   TesterEnter
#   TesterExit
#   TesterSourceModule Module type
#   TesterReadNewModule Filename
#==========================================================================auto=

#-------------------------------------------------------------------------------
#  Description
#  This module is an example for developers.  It shows how to add a module 
#  to the Slicer.  To find it when you run the Slicer, click on More->Tester.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Variables
#  These are the variables defined by this module.
# 
#  int Tester(count) counts the button presses for the demo 
#  list Tester(eventManager)  list of event bindings used by this module
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# .PROC TesterInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TesterInit {} {
    global Tester Module Volume Model

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
    set m Tester
    set Module($m,author) "Samson Timoner, MIT AI Lab, samson@bwh.harvard.edu"
    set Module($m,category)  "Example"

    set Module($m,row1List) "Help Source Watch"
        set Module($m,row1Name) "{Help} {Source} {Watch}"
    set Module($m,row1,tab) Source

    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Reload a module for software development testing."

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
    #   set Module($m,procVTK) TesterBuildVTK
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
    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #   procRecallPresets  = Called when the user clicks one of the Presets buttons
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI) TesterBuildGUI
    set Module($m,procEnter) TesterEnter
    set Module($m,procExit) TesterExit

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
        {$Revision: 1.21 $} {$Date: 2006/01/06 17:57:01 $}]

    # Initialize module-level variables
    #------------------------------------
    # Description:
    #   Keep a global array with the same name as the module.
    #   This is a handy method for organizing the global variables that
    #   the procedures in this module and others need to access.
    #
        set Tester(SourceFileName) ""
        set Tester(NewModuleFileName) ""
    set Tester(ModuleFileName) ""
    set Tester(MainFileName)   ""
    set Tester(SharedFileName) ""

        set Tester(MainModuleList)   $Module(mainList)
        set Tester(SharedModuleList) $Module(sharedList) 
        # Include Suppressed Modules
        set Tester(ModuleModuleList) $Module(allList)

        set Tester(Count) 0
    set Tester(eventManager)  ""
        set Tester(verbose) 1

}


#-------------------------------------------------------------------------------
# .PROC TesterBuildGUI
#
# Create the Graphical User Interface.
# .END
#-------------------------------------------------------------------------------
proc TesterBuildGUI {} {
        global Gui Tester Module Volume Model

        # A frame has already been constructed automatically for each tab.
        # A frame named "Stuff" can be referenced as follows:
        #   
        #     $Module(<Module name>,f<Tab name>)
        #
        # ie: $Module(Tester,fStuff)

        # This is a useful comment block that makes reading this easy for all:
        #-------------------------------------------
        # Frame Hierarchy:
        #-------------------------------------------
        # Help
        # Source
        #   SourceText
        #   Browse
        #   Main
        #   Module
        #   Shared
        #   NewModule
        #   Bottom
        # Watch
        #-------------------------------------------

        #-------------------------------------------
        # Help frame
        #-------------------------------------------

        # Write the "help" in the form of psuedo-html.  
        # Refer to the documentation for details on the syntax.
        #
        set help " The Tester module is for developers only.  It 
 allows the developer to source code by specifying a file name or to source modules as changes are made to them.
<BR><BR>
For modules, GUI's are re-made so
that one can easily tweak a user-interface and until the results look
nice. 
<BR><BR>
 Writing a new module? The Tester now has
the ability to setup new modules so that you need not restart the slicer.
<BR><BR>
 A good thing to add would be a \"Watch\" that allows the developer to watch the values of selected variables. But, I haven't done it yet.<p>

Note that if you re-source the Tester, the Tester windows will get screwed
up. To fix this, simply exit and enter the Tester. "
        regsub -all "\n" $help {} help
        MainHelpApplyTags Tester $help
        MainHelpBuildGUI Tester

        #-------------------------------------------
        # Source frame
        #-------------------------------------------
        set fSource $Module(Tester,fSource)
        set f $fSource

        foreach frame "Browse Main Module Shared NewModule Bottom" {
                frame $f.f$frame -bg $Gui(activeWorkspace)
                pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
        }

        #-------------------------------------------
        # Source->Browse frame
        #-------------------------------------------
        set f $fSource.fBrowse

        DevAddFileBrowse $f Tester SourceFileName "File to Source:" "source \$Tester\(SourceFileName\)" "tcl" "" "Open" "Browse for a new module" 

        #-------------------------------------------
        # Source->Main frame
        #-------------------------------------------
        set f $fSource.fMain
        DevAddLabel $f.lSource "Or, Source an existing Module:"
        pack $f.lSource -side top -padx $Gui(pad) -fill x -pady $Gui(pad)

        DevAddSelectButton Tester $f MainModules  "Main" Pack

        set f $fSource.fModule

        DevAddSelectButton Tester $f ModuleModules  "Module" Pack

        set f $fSource.fShared

        DevAddSelectButton Tester $f SharedModules  "Shared" Pack

        DevAddButton $fSource.fMain.bMain Reload \
                {TesterSourceModule Main $Tester(MainFileName)}
        DevAddButton $fSource.fModule.bModule Reload \
                {TesterSourceModule Module $Tester(ModuleFileName)}
        DevAddButton $fSource.fShared.bShared Reload \
                {TesterSourceModule Shared $Tester(SharedFileName)}

        pack $fSource.fMain.bMain -side right -padx $Gui(pad)
        pack $fSource.fModule.bModule -side right -padx $Gui(pad)
        pack $fSource.fShared.bShared -side right -padx $Gui(pad)

        #-------------------------------------------
        # Source->NewModule frame
        #-------------------------------------------

        set f $fSource.fNewModule

        DevAddLabel $f.lSource "Or, Read in a New Module:"
        pack $f.lSource -side top -padx $Gui(pad) -fill x -pady $Gui(pad)

        DevAddFileBrowse $f Tester NewModuleFileName "New Module to Source:" "TesterReadNewModule \$Tester\(NewModuleFileName\)" "tcl" "" "Open"  "Browse for a new module"

        #-------------------------------------------
        # Source->Bottom frame
        #-------------------------------------------
        set f $fSource.fBottom

        eval {label $f.lSource -text ""} $Gui(BLA)
        pack $f.lSource -side top -padx $Gui(pad) -fill x
        set Tester(lSource) $f.lSource



}

#-------------------------------------------------------------------------------
# .PROC TesterEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TesterEnter {} {
    global Tester Module
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $Tester(eventManager)

    # Refresh the Module Lists
    set Tester(MainModuleList)   $Module(mainList)
    set Tester(SharedModuleList) $Module(sharedList) 
    # Include Suppressed Modules
    set Tester(ModuleModuleList) $Module(allList)

 DevUpdateSelectButton Tester MainModules MainFileName   MainModuleList \
         "TesterSourceModule Main"
 DevUpdateSelectButton Tester ModuleModules ModuleFileName ModuleModuleList \
         "TesterSourceModule Module"
 DevUpdateSelectButton Tester SharedModules SharedFileName SharedModuleList \
         "TesterSourceModule Shared"
}

#-------------------------------------------------------------------------------
# .PROC TesterExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc TesterExit {} {

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
# .PROC TesterSourceModule
# Source a module.  Use the usual Slicer search order.
# .ARGS
# str Module  The module name
# str type    either Main, Shared, or Module
# .END
#-------------------------------------------------------------------------------
proc TesterSourceModule {type Module} {
   global Tester
    if {$Module == ""} return
    if {$type == ""} return

    ## Expand the path name of each type differently

    if {$type == "Main"} { 
        set path [GetFullPath $Module tcl tcl-main] 
        set Tester(MainFileName) $Module
    }
    if {$type == "Shared"} { 
        set path [GetFullPath $Module tcl tcl-shared]
        set Tester(SharedFileName) $Module
    }

    if {$type == "Module"} { 
      set path [GetFullPath $Module tcl tcl-modules 0]
      # New structure
      if {$path == ""} {
         set path [GetFullPath $Module tcl ../../Modules/vtk${Module}/tcl 0]
      }
      set Tester(ModuleFileName) $Module
    }
#    puts "b$path"
#    puts "b$Tester(ModuleFileName)"

    ## Source the file

    if { $path != "" } { 
        source $path 
    } else {
        DevWarningWindow "Didn't find that module!"
        $Tester(lSource) config -text ""
        return
    }

    ## Rebuild Gui on Modules

    if {$type == "Module"} { 
        # Kilian: Had to do it bc my file is call EMLocalSegment and the name of the module is EMSegment 
        if {$Module == "EMLocalSegment"} {set Module EMSegment }
        MainRebuildModuleGui $Module
        # Other Stuff that is Useful
        MainUpdateMRML
        # set Module(btn) Tester
        # $Module(rMore) config -text $m
        Tab $Module
    }

    ## Send message that we update Stuff.
    if {$Module != "Tester"} {
       $Tester(lSource) config -text "Updated $Module."
    }
}

#-------------------------------------------------------------------------------
# .PROC TesterReadNewModule
#
# This is very "clugy" in that it repeats code in MainBuildGUI.
# If changes are made to MainBuildGUI, this will not work.
#
# This module assumes the "More:" button is in use.
# 
# .ARGS
#   str Filename the filename of the module
# .END
#-------------------------------------------------------------------------------
proc TesterReadNewModule {Filename} {
    global Module

    if {$Module(more) != 1} {
        DevWarningWindow "There is no \"More:\" button! Can't add module."
        return
    }

    if {[file extension $Filename] != ".tcl"} {
        DevWarningWindow "Module names must end in .tcl"
        puts [file extension $Filename]
        return
    }

    # m is the name of the module
    set m [file rootname [file tail $Filename]]

    set Module($m,more) 0
    set Module($m,row1List) ""
    set Module($m,row1Name) ""
    set Module($m,row1,tab) ""
    set Module($m,row2List) ""
    set Module($m,row2Name) ""
    set Module($m,row2,tab) ""
    set Module($m,row) row1

    source $Filename

    if {[info command ${m}Init] != ""} {
        if {$Module(verbose) == 1} {
            puts "INIT: ${m}Init"
        }
        ${m}Init
    }

    lappend Module(idList) $m
    lappend Module(allList) $m
    set Module($m,more) 1

    set moreMenu $Module(mbMore).m
    $moreMenu add command -label $m \
            -command "set Module(btn) More; Tab $m; \
            $Module(rMore) config -text $m"

    MainBuildModuleTabs $m

    if {[info exists Module($m,procGUI)] == 1} {
        if {$Module(verbose) == 1} {
            puts "GUI: $Module($m,procGUI)"
        }
        $Module($m,procGUI)
    }
}
