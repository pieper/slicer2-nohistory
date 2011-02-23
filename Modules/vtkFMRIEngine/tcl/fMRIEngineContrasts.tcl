#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineContrasts.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:37 $
#   Version:   $Revision: 1.10 $
# 
#===============================================================================
# FILE:        fMRIEngineContrasts.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForContrasts  the
#   fMRIEngineAddOrEditContrast
#   fMRIEngineDeleteContrast
#   fMRIEngineShowContrastToEdit
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForContrasts 
# Creates UI for task "Contrasts" 
# .ARGS
# parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForContrasts {parent} {
    global fMRIEngine Gui

    frame $parent.fTop    -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fMiddle -bg $Gui(activeWorkspace) -relief groove -bd 1
    # frame $parent.fBot    -bg $Gui(activeWorkspace) -relief groove -bd 1
    pack $parent.fTop $parent.fMiddle \
        -side top -fill x -pady 2 -padx 1 

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    frame $f.fTitle    -bg $Gui(activeWorkspace)
    frame $f.fTypes    -bg $Gui(activeWorkspace)
    frame $f.fComp     -bg $Gui(activeWorkspace)
    frame $f.fActions  -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fTypes $f.fComp \
        -side top -fill x -pady 1 -padx 1 
    pack $f.fActions -side top -fill x -pady 1 -padx 1 

    set f $parent.fTop.fTitle
    DevAddLabel $f.l "Compose a contrast:"
    grid $f.l -padx 1 -pady 3

    #-----------------------
    # Type of contrast 
    #-----------------------
    set f $parent.fTop.fTypes
    DevAddLabel $f.l "Type: "
    foreach param "t f" \
        name "{t test} {F test}" {
        eval {radiobutton $f.r$param -width 10 -text $name \
            -variable fMRIEngine(contrastOption) -value $param \
            -relief raised -offrelief raised -overrelief raised \
            -selectcolor white} $Gui(WEA)
    } 
    $f.rt select
    $f.rf configure -state disabled
    grid $f.l $f.rt $f.rf -padx 1 -pady 1 -sticky e

    #-----------------------
    # Compose a contrast 
    #-----------------------
    set f $parent.fTop.fComp
    DevAddLabel $f.lName "Contrast Name:"
    eval {entry $f.eName -width 16 -textvariable fMRIEngine(entry,contrastName)} $Gui(WEA)
    TooltipAdd $f.eName "Input a unique name for this contrast."
    grid $f.lName $f.eName -padx 1 -pady 1 -sticky e

    DevAddLabel $f.lVolName "Volume Name:"
    eval {entry $f.eVolName -width 16 -textvariable fMRIEngine(entry,contrastVolName)} $Gui(WEA)
    TooltipAdd $f.eVolName "Input a unique name for the activation volume \nassociated with this contrast."
    grid $f.lVolName $f.eVolName -padx 1 -pady 1 -sticky e

    DevAddLabel $f.lExp "Vector:"
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetupContrasts" 2
    eval {entry $f.eExp -width 16 -textvariable fMRIEngine(entry,contrastVector)} $Gui(WEA)
    # TooltipAdd $f.eExp "Input a vector for this contrast."
    grid $f.lExp $f.eExp $f.bHelp -padx 1 -pady 1 -sticky e

    #-----------------------
    # Action panel 
    #-----------------------
    set f $parent.fTop.fActions
    DevAddButton $f.bOK "OK" "fMRIEngineAddOrEditContrast" 6 
    grid $f.bOK -padx 2 -pady 2 

    #-------------------------------------------
    # Middle frame 
    #-------------------------------------------
    #-----------------------
    # Contrast list 
    #-----------------------
    set f $parent.fMiddle
    frame $f.fUp      -bg $Gui(activeWorkspace)
    frame $f.fMiddle  -bg $Gui(activeWorkspace)
    frame $f.fDown    -bg $Gui(activeWorkspace)
    pack $f.fUp $f.fMiddle $f.fDown -side top -fill x -pady 1 -padx 2 

    set f $parent.fMiddle.fUp
    DevAddLabel $f.l "Specified contrasts:"
    grid $f.l -padx 1 -pady 2 

    set f $parent.fMiddle.fMiddle
    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    scrollbar $f.hs -orient horizontal -bg $Gui(activeWorkspace)
    set fMRIEngine(contrastsVerScroll) $f.vs
    set fMRIEngine(contrastsHorScroll) $f.hs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -yscrollcommand {$::fMRIEngine(contrastsVerScroll) set} \
        -xscrollcommand {$::fMRIEngine(contrastsHorScroll) set}
    set fMRIEngine(contrastsListBox) $f.lb
    $fMRIEngine(contrastsVerScroll) configure -command {$fMRIEngine(contrastsListBox) yview}
    $fMRIEngine(contrastsHorScroll) configure -command {$fMRIEngine(contrastsListBox) xview}

    blt::table $f \
        0,0 $fMRIEngine(contrastsListBox) -padx 1 -pady 1 \
        1,0 $fMRIEngine(contrastsHorScroll) -fill x -padx 1 -pady 1 \
        0,1 $fMRIEngine(contrastsVerScroll) -cspan 2 -fill y -padx 1 -pady 1

    #-----------------------
    # Action  
    #-----------------------
    set f $parent.fMiddle.fDown
    DevAddButton $f.bEdit "Edit" "fMRIEngineShowContrastToEdit" 6 
    DevAddButton $f.bDelete "Delete" "fMRIEngineDeleteContrast" 6 
    grid $f.bEdit $f.bDelete -padx 2 -pady 3 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddOrEditContrast
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddOrEditContrast {} {
    global fMRIEngine 

    # Error checking
    set name [string trim $fMRIEngine(entry,contrastName)]
    if {$name == ""} {
        DevErrorWindow "Input a unique name for this contrast."
        return
    }

    set vec [string trim $fMRIEngine(entry,contrastVector)]
    if {$vec == ""} {
        DevErrorWindow "Input the contrast vector."
        return
    }

    set vname [string trim $fMRIEngine(entry,contrastVolName)]
    if {$vname == ""} {
        set vname "ActVol"
    }

    # replace multiple spaces in the middle of the string by one space  
    regsub -all {( )+} $vec " " vec 
    set vecList [split $vec " "]     
    set len [llength $vecList]
    foreach i $vecList { 
        set v [string trim $i]
        set b [string is integer -strict $v]
        if {$b == 0} {
            DevErrorWindow "Input a valid contrast vector." 
            return
        }
    }

    set key "$name-$vname"
    if {! [info exists fMRIEngine($key,contrastName)]} {
        set curs [$fMRIEngine(contrastsListBox) curselection]
        if {$curs != ""} {
            fMRIEngineDeleteContrast
        }
        $fMRIEngine(contrastsListBox) insert end $key 
    } else {
        if {$name == $fMRIEngine($key,contrastName)     &&
            $vname == $fMRIEngine($key,contrastVolName) &&
            $vec == $fMRIEngine($key,contrastVector)} {
            DevErrorWindow "This contrast already exists:\nName: $name\nVol Name: $vname\nVector: $vec"
            return
        }
    }

    set fMRIEngine($key,contrastName) $name
    set fMRIEngine($key,contrastVolName) $vname
    set fMRIEngine($key,contrastVector) $vec
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineDeleteContrast
# Deletes a contrast 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineDeleteContrast {} {
    global fMRIEngine 

    set curs [$fMRIEngine(contrastsListBox) curselection]
    if {$curs != ""} {
        set name [$fMRIEngine(contrastsListBox) get $curs] 
        if {$name != ""} {
            unset -nocomplain fMRIEngine($name,contrastName) 
            unset -nocomplain fMRIEngine($name,contrastVolName) 
            unset -nocomplain fMRIEngine($name,contrastVector)
        }

        $fMRIEngine(contrastsListBox) delete $curs 
    } else {
        DevErrorWindow "Select a contrast to delete."
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowContrastToEdit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowContrastToEdit {} {
    global fMRIEngine 

    set curs [$fMRIEngine(contrastsListBox) curselection]
    if {$curs != ""} {
        set key [$fMRIEngine(contrastsListBox) get $curs] 
        if {$key != ""} {
            set fMRIEngine(entry,contrastName) $fMRIEngine($key,contrastName)
            set fMRIEngine(entry,contrastVolName) $fMRIEngine($key,contrastVolName)
            set fMRIEngine(entry,contrastVector) $fMRIEngine($key,contrastVector)
        }
    } else {
        DevErrorWindow "Select a contrast to edit."
    }
}


 
