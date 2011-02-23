#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: dup.tcl,v $
#   Date:      $Date: 2006/11/17 14:50:44 $
#   Version:   $Revision: 1.22 $
# 
#===============================================================================
# FILE:        dup.tcl
# PROCEDURES:  
#   dup_demo
#   dup_main
#   BIRNDUPInterface
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

#########################################################
#
if {0} { ;# comment

dup - the interface to the birn deidentification and 
upload pipeline (birndup)

# TODO : 
    about_dialog
    help
}
#
#########################################################

#
# Default resources
# 
option add *dup.appname "BIRN Deidentification and Upload Pipeline" widgetDefault
option add *dup.exitonclose "false" widgetDefault
option add *dup.birndup_dir "." widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class dup] == "" } {

    itcl::class dup {
        inherit iwidgets::Mainwindow

        itk_option define -appname appname Appname {}
        itk_option define -exitonclose exitonclose Exitonclose {}
        itk_option define -birndup_dir birndup_dir Birndup_dir {}

        constructor {args} {}
        destructor {}

        variable _prefs ;# array of preferences
        variable _save_prefs ;# for the prefui dialog box

        variable _sort
        variable _deidentify
        variable _review
        variable _upload

        variable _w


        method menus {} {}
        method about_dialog {} {}
        method help {} {}
        method pref { {KEY ""} } {}
        method prefs {} {}
        method prefui {} {}
        method pref_save {} {}
        method pref_restore {} {}
        method studies {} {}
        method log {message} {}

        method load_example { {dir "choose"} } {}
        method fill { {dir "choose"} } {}
        method refresh { {pane "all"} } {}

        method statusvar {} { return [itcl::scope _statusVar($this)] }
        method w {} {return $_w}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body dup::constructor {args} {

    $itk_component(status) configure -anchor w

    set cs [$this childsite]

    pack [iwidgets::panedwindow $cs.panes -orient vertical] -fill both -expand true

    foreach p {sort deidentify review upload} {
        $cs.panes add $p
        set _w [$cs.panes childsite $p]
        set _$p $_w.$p
        label $_w.l -text [string totitle $p] -bg white
        pack $_w.l -side top -fill x
        pack [dup_$p [set _$p]] -fill both -expand true
    }


    # put the app name and logo at the bottom
    set im [image create photo -file $::PACKAGE_DIR_BIRNDUP/../../../images/new-birn.ppm]
    pack [label $cs.logo -image $im -bg white] -fill x -anchor s

    $this menus
    $this configure -title "BIRN Deidentification and Upload Pipeline - Evaluation Use Only"

    eval itk_initialize $args

    if { [$this prefs] != "okay" } {
        return
    }

    foreach p {sort deidentify review upload} {
        [set _$p] configure -parent $this
    }

    after idle "$this refresh"
}


itcl::body dup::destructor {} {
    if { $itk_option(-exitonclose) } {
        exit
    }
}


itcl::body dup::menus {} {
    $this menubar config \
        -font {{MS Sans Serif} 12} \
        -menubuttons {
            menubutton file -text "File" -menu {
                options -tearoff false
                command newstud -label "New Directory..." \
                    -helpstr "Open a New Source Directory for Deidentification" \
                    -command "$this fill"
                separator sep1
                command pref -label "Preferences..." \
                    -helpstr "Application preference settings." \
                    -command "$this prefui"
                separator sepexample
                command reviewexampe -label "Load Review Example..." \
                    -helpstr "Copy an example of data to review." \
                    -command "$this load_example"
                separator sep2
                command exit -label "Close" -command "destroy [namespace tail $this]" \
                    -helpstr "Close BIRNDUP"
            menubutton help -text "Help" -menu {
                options -tearoff false
                command about -label "About..." \
                    -helpstr "About BIRNDUP" \
                    -command {$this about_dialog}
                command help -label "Help..." \
                    -helpstr "Help window" \
                    -command {$this help}
            }
        }
    }
}

itcl::body dup::about_dialog {} {
    
    dup_DevInfoWindow "Biomedical Informatics Research Network\nDeidentification and Upload Pipeline.\n\nwww.nbirn.net\n\nFor Evaluation Use Only."

}

itcl::body dup::help {} {

    dup_DevInfoWindow "For information about this software, see: http://www.na-mic.org/Wiki/index.php/MBIRN:BIRNDUP:Distribution"
}

itcl::body dup::fill { {dir "choose"} } {

    catch "destroy $_sort"
    pack [dup_sort $_sort -parent $this] -fill both -expand true
    
    if { $dir == "choose" } {
        set dir [tk_chooseDirectory]
    }
    if { $dir != "" } { 
        $_sort fill $dir
    }
}

itcl::body dup::load_example { {dir "choose"} } {

    if { $dir == "choose" } {
        set dir [tk_chooseDirectory \
                    -initialdir [$this pref DEFACE_DIR]/../example-data/Project_x \
                    -title "Select Example Project Review Directory" ]
    }
    
    if { $dir != "" } {
        set target [$this pref DEFACE_DIR]/[file tail $dir]
        if { [file exists $target] } {
            set ret [dup_DevOKCancel "Directory $target already exists - delete it?"]
            if { $ret == "ok" } {
                file delete -force $target
            } else {
                return
            }
        }
        file copy -force $dir [$this pref DEFACE_DIR]
    }

    $this refresh
}

itcl::body dup::refresh { {pane "all"} } {
    switch $pane {
        "deidentify" {
            $_deidentify refresh
        }
        "review" {
            $_review refresh
        }
        "upload" {
            $_upload refresh
        }
        "all" {
            $_deidentify refresh
            $_review refresh
            $_upload refresh
        }
    }
}

itcl::body dup::studies {} {

    set defacedir [$this pref DEFACE_DIR]
    return [glob -nocomplain $defacedir/Project_*/*/Visit_*/Study_*/Raw_Data]
}

itcl::body dup::log { message } {
    set fp [open $::env(HOME)/.birndup/log "a"]
    puts $fp "\{$::env(USER) [clock format [clock seconds]]\} \{$message\}"
    close $fp
}

itcl::body dup::pref { {KEY ""} } {
    if { $KEY == "" } {
        return [parray _prefs]
    }
    if { [info exists _prefs($KEY)] } {
        return $_prefs($KEY)
    } else {
        return ""
    }
}

itcl::body dup::prefs { } {

    #
    # put all preference defaults here - in case the older pref
    # file didn't contain all the entries
    #
    set BIRN [file normalize $::env(SLICER_HOME)/..]
    set _prefs(INSTITUTION) BWH
    set _prefs(INSTITUTION,help) "Prefix for BIRN ID - 3 or 4 character, e.g. BWH"
    set _prefs(LINKTABLE) $BIRN/deface/linktable
    set _prefs(LINKTABLE,help) "Link table for storing the map between clinical ID and BIRN ID"
    set _prefs(DEFACE_DIR) $BIRN/deface
    set _prefs(DEFACE_DIR,help) "Staging directory for files to upload"

    # create a pref file if needed and let user fill in blanks
    set preffile $::env(HOME)/.birndup/prefs
    if { ![file exists $::env(HOME)/.birndup/prefs] } {
        set resp [tk_messageBox -type okcancel -message "A preferences file will be created for you in $preffile.\n\nClick OK to continue or Cancel to exit"]
        if { $resp == "cancel" } {
            itcl::delete object $this
            return ""
        }

        file mkdir $::env(HOME)/.birndup    
        $this pref_save
        
        $this prefui
    }

    set fp [open $preffile r]
    array set userprefs [read $fp]
    close $fp


    foreach n [array names _prefs] {
        if { [string match *,help $n] } { continue }
        if { ![info exists userprefs($n)] } {
            dup_DevInfoWindow "New preference field in updated software: $n will be set to $_prefs($n).  Use File->Preferences... to customize."
            set userprefs($n) $_prefs($n)
            set userprefs($n,help) $_prefs($n,help)
        }
    }

    # these pref fields were retired with the new directory layout
    set old_prefs {DCANON_DIR UPLOAD2_DIR}

    foreach n $old_prefs {
        if { [info exists userprefs($n)] } {
            dup_DevInfoWindow "Old preference field \"$n\" not needed in updated software."
            unset userprefs($n)
            unset userprefs($n,help)
        }
    }

    array set _prefs [array get userprefs]
    $this pref_save

    return "okay"
}

itcl::body dup::pref_save { } {
    if { [catch "file mkdir $::env(HOME)/.birndup"] } {
        dup_DevErrorWindow "Cannot create .birndup directory - preferences not saved"
        return
    }
    if { ![file writable $::env(HOME)/.birndup] } {
        dup_DevErrorWindow "$preffile file not writable - preferences not saved"
        return
    }
    set preffile $::env(HOME)/.birndup/prefs
    set fp [open $preffile w]
    foreach n [lsort -dictionary [array names _prefs]] {
        puts $fp "$n \"$_prefs($n)\""
    }
    close $fp
}


itcl::body dup::pref_restore { } {
    array set _prefs [array get _save_prefs]
}

itcl::body dup::prefui { } {

    set d $this.dup_prefui

    if { [info command $d] == "" } {
        ::iwidgets::dialog $d
        $d configure -title "BIRNDUP Preferencnes"
        set cs [$d childsite]

        set preffile $::env(HOME)/.birndup/prefs
        label $cs.linfo -text "Stored in $preffile"
        pack $cs.linfo -fill x -expand true

        array set _save_prefs [array get _prefs]

        set efields ""
        foreach n [lsort -dictionary [array names _prefs]] {
            if { [string match *,help $n] } { continue }
            lappend efiles $cs.e$n
            ::iwidgets::entryfield $cs.e$n -labeltext $n -labelpos w -width 50 -textvariable [::itcl::scope _prefs($n)]
            dup_TooltipAdd $cs.e$n $_prefs($n,help)
            pack $cs.e$n -fill x -expand true
        }
        eval ::iwidgets::Labeledwidget::alignlabels $efields

        $d hide 1
        $d hide 3
    }

    $d buttonconfigure OK -command "$this pref_save; $d deactivate 0"
    $d buttonconfigure Cancel -command "$this pref_restore; $d deactivate 1"

    $d center
    $d activate
}

#-------------------------------------------------------------------------------
# .PROC BIRNDUPInterface
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc BIRNDUPInterface { {exitonclose "false"} } {

    set module_dir $::PACKAGE_DIR_BIRNDUP/../../..
    set slicer_dir $module_dir/../..
    set birndup_dir $slicer_dir/../birndup
    foreach c { "" _sort _deidentify _review _upload } {
        catch "itcl::delete class dup$c"
        source $module_dir/tcl/dup$c.tcl;
    }

    dup .dup -exitonclose $exitonclose \
        -birndup_dir $birndup_dir

    if { [info command .dup] != "" } {
        # if the user didn't cancel, keep going...
        wm geometry .dup 900x700+50+50
        .dup activate
    }
}

#-------------------------------------------------------------------------------
# .PROC dup_demo
# 
# Stub for old entry point (renamed dup_main)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_demo {} {

    dup_main "false"
}

#-------------------------------------------------------------------------------
# .PROC dup_main
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc dup_main { {exitonclose "true"} } {
    package require vtkSlicerBase
    package require BIRNDUP
    if { ![info exists ::Module(versbose)] } {
        set ::Module(verbose) 0
    }
    wm withdraw .
    BIRNDUPInterface $exitonclose
}

