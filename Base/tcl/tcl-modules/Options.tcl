#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Options.tcl,v $
#   Date:      $Date: 2006/07/27 18:30:51 $
#   Version:   $Revision: 1.25 $
# 
#===============================================================================
# FILE:        Options.tcl
# PROCEDURES:  
#   OptionsInit
#   OptionsUpdateMRML
#   OptionsBuildGUI
#   OptionsSetPropertyType
#   OptionsPropsApply
#   OptionsUpdateModuleList
#   OptionsModulesApply
#   OptionsPropsCancel
#   OptionsModulesAll
#   ModulesOrderGUI
#   ModulesUp
#   ModulesDown
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC OptionsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsInit {} {
    global Options Module

    # Define Tabs
    set m Options
    set Module($m,row1List) "Help Props Modules"
        set Module($m,row1Name) "{Help} {Props} {Modules}"
    set Module($m,row1,tab) Modules

    # Define Procedures
    set Module($m,procGUI)  OptionsBuildGUI
    set Module($m,procMRML) OptionsUpdateMRML

    # Define Dependencies
    set Module($m,depend) ""
    set Module($m,author) "Core"
    set Module($m,category) "Settings"
    set Module($m,overview) "Select the Modules to load next time you start Slicer"

    # Set Version Info
    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.25 $} {$Date: 2006/07/27 18:30:51 $}]

    # Module Summary Info
    set Module($m,overview) "Save User Preferences to Options.xml file."

    # Initialize Globals
    set Options(propertyType) Basic

#    set Options(moduleTypes) {ordered suppressed ignored}

    foreach m $Module(idList) {
        set Module($m,visibility) 1
    }
    foreach m $Module(supList) {
        set Module($m,visibility) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC OptionsUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsUpdateMRML {} {

}

#-------------------------------------------------------------------------------
# .PROC OptionsBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsBuildGUI {} {
    global Gui Options Module

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Props
    #   Top
    #     Active
    #     Type
    #   Bot
    #     Basic
    #     Advanced
    # Modules
    #   
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
The next time you start the Slicer, it will load only the 
modules that have their buttons pressed in on the <B>Order</B> tab.
<P>
The order of modules will be determined by their order on 
the tab.  Click the <B>Up</B> and <B>Down</B> buttons to 
organize them.
"
    regsub -all "\n" $help { } help
    MainHelpApplyTags Options $help
    MainHelpBuildGUI Options


    #-------------------------------------------
    # Props frame
    #-------------------------------------------
    set fProps $Module(Options,fProps)
    set f $fProps

    frame $f.fTop -bg $Gui(backdrop) -relief sunken -bd 2
    frame $f.fBot -bg $Gui(activeWorkspace) -height 300
    pack $f.fTop $f.fBot -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Props->Bot frame
    #-------------------------------------------
    set f $fProps.fBot

    foreach type "Basic Advanced" {
        frame $f.f${type} -bg $Gui(activeWorkspace)
        place $f.f${type} -in $f -relheight 1.0 -relwidth 1.0
        set Options(f${type}) $f.f${type}
    }
    raise $Options(fBasic)

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

    eval {label $f.lActive -text "Active Option: "} $Gui(BLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Options(mbActiveList) $f.mbActive
    lappend Options(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Props->Top->Type frame
    #-------------------------------------------
    set f $fProps.fTop.fType

    eval {label $f.l -text "Properties:"} $Gui(BLA)
    frame $f.f -bg $Gui(backdrop)
    foreach p "Basic Advanced" {
        eval {radiobutton $f.f.r$p \
            -text "$p" -command "OptionsSetPropertyType" \
            -variable Options(propertyType) -value $p -width 8 \
            -indicatoron 0} $Gui(WCA)
        pack $f.f.r$p -side left -padx 0
    }
    pack $f.l $f.f -side left -padx $Gui(pad) -fill x -anchor w

    #-------------------------------------------
    # Props->Bot->Basic frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic

    frame $f.fProgram  -bg $Gui(activeWorkspace)
    frame $f.fContents -bg $Gui(activeWorkspace)
    frame $f.fApply    -bg $Gui(activeWorkspace)
    pack $f.fProgram $f.fContents $f.fApply \
        -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced

    frame $f.fApply    -bg $Gui(activeWorkspace)
    pack $f.fApply \
        -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Basic->Program frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fProgram

    eval {label $f.l -text "Program:" } $Gui(WLA)
    eval {entry $f.e -textvariable Options(program)} $Gui(WEA)
    pack $f.l -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -expand 1 -fill x

    #-------------------------------------------
    # Props->Bot->Basic->Contents frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fContents

    eval {label $f.l -text "Contents:" } $Gui(WLA)
    eval {entry $f.e -textvariable Options(contents)} $Gui(WEA)
    pack $f.l -side left -padx $Gui(pad)
    pack $f.e -side left -padx $Gui(pad) -expand 1 -fill x

    #-------------------------------------------
    # Props->Bot->Basic->Apply frame
    #-------------------------------------------
    set f $fProps.fBot.fBasic.fApply

    eval {button $f.bApply -text "Apply" \
        -command "OptionsPropsApply; RenderAll"} $Gui(WBA) {-width 8}
    eval {button $f.bCancel -text "Cancel" \
        -command "OptionsPropsCancel"} $Gui(WBA) {-width 8}
    grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Props->Bot->Advanced->Apply frame
    #-------------------------------------------
    set f $fProps.fBot.fAdvanced.fApply

    eval {button $f.bApply -text "Apply" \
        -command "OptionsPropsApply; RenderAll"} $Gui(WBA) {-width 8}
    eval {button $f.bCancel -text "Cancel" \
        -command "OptionsPropsCancel"} $Gui(WBA) {-width 8}
    grid $f.bApply $f.bCancel -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Modules frame
    #-------------------------------------------
    set fModules $Module(Options,fModules)
    set f $fModules

    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fApply -bg $Gui(activeWorkspace)
    frame $f.fGrid -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fApply -side top -pady $Gui(pad)
        pack $f.fGrid -side bottom -pady $Gui(pad) -fill y -expand true
    #-------------------------------------------
    # Modules->Title frame
    #-------------------------------------------
    set f $fModules.fTitle

    eval {label $f.lTitle -text "\
Leave a button unpressed (out) for the 
Slicer to ignore that module the next 
time it runs."} \
        $Gui(WLA)
    pack $f.lTitle

    #-------------------------------------------
    # Modules->Apply frame
    #-------------------------------------------
    set f $fModules.fApply

    eval {button $f.bApply -text "Apply" \
        -command "OptionsModulesApply"} $Gui(WBA)
    eval {button $f.bAll -text "Load ALL Modules" \
        -command "OptionsModulesAll"} $Gui(WBA)
    pack $f.bApply $f.bAll -side left -padx $Gui(pad)
    set Options(bModulesApply) $f.bApply
    set Options(bModulesAll) $f.bAll

    #-------------------------------------------
    # Modules->Grid frame
    #-------------------------------------------
    set f $fModules.fGrid
    set Options(fModules) $f

    OptionsModulesGUI

}

#-------------------------------------------------------------------------------
# .PROC OptionsSetPropertyType
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsSetPropertyType {} {
    global Options
    
    raise $Options(f$Options(propertyType))
}


#-------------------------------------------------------------------------------
# .PROC OptionsPropsApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsPropsApply {} {
    global Options Module Mrml

    # for now, disable creation of options in this way.  (Can save in MRML file or in Options.xml)
    return

    # Validate program
    if {$Options(program) == ""} {
        tk_messageBox -message "Please enter a program that will recognize this option."
        return
    }
    if {[ValidateName $Options(program)] == 0} {
        tk_messageBox -message "The program can consist of letters, digits, dashes, or underscores"
        return
    }

    # Validate contents
    if {$Options(contents) == ""} {
        tk_messageBox -message "Please enter the contents of this option."
        return
    }
    if {[ValidateName $Options(contents)] == 0} {
        tk_messageBox -message "The contents can consist of letters, digits, dashes, or underscores"
        return
    }

    set m $Options(activeID)
    if {$m == ""} {return}

    if {$m == "NEW"} {
        # Ensure prefix not blank
        if {$Options(prefix) == ""} {
            tk_messageBox -message "Please enter a file prefix."
            return
        }
        set i $Options(nextID)
        incr Options(nextID)
        lappend Options(idList) $i
        vtkMrmlOptionsNode Options($i,node)
        set n Options($i,node)
        $n SetID               $i

        # These get set down below, but we need them before MainUpdateMRML
        $n SetProgram  $Options(program)
        $n SetContents $Options(contents)
#        $n SetOptions  $Options(options)

        Mrml(dataTree) AddItem $n
        MainUpdateMRML

        # If failed, then it's no longer in the idList
        if {[lsearch $Options(idList) $i] == -1} {
            return
        }
        set Options(freeze) 0
        MainOptionsSetActive $i
        set m $i
    }

    Options($m,node) SetProgram  $Options(program)
    Options($m,node) SetContents $Options(contents)
#    Options($m,node) SetOptions  $Options(options)

    # If tabs are frozen, then return to the "freezer"
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
    
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC OptionsUpdateModuleList
# The Options(moduleList) is saved out in the Options.xml file, built up from the ordered
# and suppressed lists. It has to be updated before writing.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsUpdateModuleList {} {
    global Module Options

    set ordered "ordered='"
    set suppressed "suppressed='"
    set ignored "ignored='$Module(ignoredList)'"

    foreach m $Module(allList) {
        if {$Module($m,visibility) == 1} {
            set ordered "$ordered $m"
        } else {
            set suppressed "$suppressed $m"
        }
    }

    set Options(moduleList) "$ordered'\n$suppressed'\n$ignored\n"

    if {$::Module(verbose)} { puts "OptionsUpdateModuleList: Options(moduleList) $Options(moduleList)" }

}

#-------------------------------------------------------------------------------
# .PROC OptionsModulesApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsModulesApply {} {

    global Module Options

    OptionsUpdateModuleList
    
    MainFileSaveOptions
    return

}

#-------------------------------------------------------------------------------
# .PROC OptionsPropsCancel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsPropsCancel {} {
    global Options Module

    # Reset props
    set m $Options(activeID)
    if {$m == "NEW"} {
        set m [lindex $Options(idList) 0]
    }
    set Options(freeze) 0
    MainOptionsSetActive $m

    # Unfreeze
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
}

#-------------------------------------------------------------------------------
# .PROC OptionsModulesAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc OptionsModulesAll {} {
    global Options Module

    foreach m $Module(allList) {
    set Module($m,visibility) 1
    }
    OptionsModulesGUI

    OptionsModulesApply

#    $Options(bModulesApply) config -state disabled
#    $Options(bModulesAll) config -state disabled
}

#-------------------------------------------------------------------------------
# .PROC ModulesOrderGUI
# .END
#-------------------------------------------------------------------------------
proc OptionsModulesGUI {} {
    global Module Gui Options
    
    set f $Options(fModules)

        # Delete everything from last time
        set canvas $f.cGrid
        catch {destroy $canvas}
        set s $f.sGrid
        catch {destroy $s}

        canvas $canvas -yscrollcommand "$s set" -bg $Gui(activeWorkspace)
        eval "scrollbar $s -command \"CheckScrollLimits $canvas yview\"    \
        $Gui(WSBA)"
        pack $s -side right -fill y
        pack $canvas -side top -fill both -expand true

        set f $canvas.fModules
        frame $f -bd 0 -bg $Gui(activeWorkspace)
    
        # put the frame inside the canvas (so it can scroll)
        $canvas create window 0 0 -anchor nw -window $f

        # y spacing important for calculation of frame height for scrolling
        set pady 2

    if {$::Module(verbose)} { puts "OptionsModulesGUI: Module(allList) = $Module(allList)" }

    # calculate the length of the longest string, for the visibility button
    set maxButtonLen 0
    foreach m $Module(allList) {
        if {[string length $m] > $maxButtonLen} {
            set maxButtonLen [string length $m]
        }
    }
    if {$Module(verbose)} { puts "From Module(allList), got max button length = $maxButtonLen" }

    foreach m $Module(allList) {
        
        # Name / Visible
        eval {checkbutton $f.c$m \
            -text $m -variable Module($m,visibility) -width $maxButtonLen \
            -indicatoron 0} $Gui(WCA)

        # Move buttons
        eval {button $f.bUp$m -text "Up" -width 2 \
            -command "OptionsModulesUp $m"} $Gui(WBA)
        eval {button $f.bDown$m -text "Down" -width 4\
            -command "OptionsModulesDown $m"} $Gui(WBA)
        
        grid $f.c$m $f.bUp$m $f.bDown$m -pady $pady -padx 2
    }

    if {[info exists m] == 1} {
        # Find the height of a single button
        set lastButton $f.bUp$m
        # Find how many modules (lines) in the frame
        set numLines [llength $Module(allList)]
        # Find the height of a line
        set incr [expr {[winfo reqheight $lastButton] + 2*$pady}]
        # Find the total height that should scroll
        set height [expr {$numLines * $incr}]

        $canvas config -scrollregion "0 0 1 $height"
        $canvas config -yscrollincrement $incr -confine true
    }
}

# This procedure allows scrolling only if the entire frame is not visible
proc CheckScrollLimits {args} {

    set canvas [lindex $args 0]
    set view   [lindex $args 1]
    set fracs [$canvas $view]

    if {double([lindex $fracs 0]) == 0.0 && \
        double([lindex $fracs 1]) == 1.0} {
    return
    }
    eval $args
}

#-------------------------------------------------------------------------------
# .PROC ModulesUp
# .END
#-------------------------------------------------------------------------------
proc OptionsModulesUp {m} {
    global Module

    set j [lsearch $Module(allList) $m]
    if {$j == 0} {return}
    set i [expr $j - 1]
    set n [lindex $Module(allList) $i]
    set Module(allList) [lreplace $Module(allList) $i $j $n]
    set Module(allList) [linsert  $Module(allList) $i $m]

    OptionsModulesGUI

    # move the module up in the ordered list
    set j [lsearch $Module(idList) $m]
    if {$::Module(verbose)} { puts "OptionsModuleUp: got $j in idList" }
    if {$j == 0} { return }
    set i [expr $j - 1]
    set n [lindex $Module(idList) $i]
    set Module(idList) [lreplace $Module(idList) $i $j $n]
    set Module(idList) [linsert  $Module(idList) $i $m]

}

#-------------------------------------------------------------------------------
# .PROC OptionsModulesDown
# .ARGS
# str m module name
# .END
#-------------------------------------------------------------------------------
proc OptionsModulesDown {m} {
    global Module

    set i [lsearch $Module(allList) $m]
    if {$i == [expr [llength $Module(allList)] - 1]} {return}
    set j [expr $i + 1]
    set n [lindex $Module(allList) $j]
    set Module(allList) [lreplace $Module(allList) $i $j $m]
    set Module(allList) [linsert  $Module(allList) $i $n]

    OptionsModulesGUI

    # move the module down in the ordered list
    set i [lsearch $Module(idList) $m]
    if {$i == [expr [llength $Module(idList)] - 1]} {return}
    set j [expr $i + 1]
    set n [lindex $Module(idList) $j]
    set Module(idList) [lreplace $Module(idList) $i $j $m]
    set Module(idList) [linsert  $Module(idList) $i $n]

}

