#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: dup_deidentify.tcl,v $
#   Date:      $Date: 2006/03/17 22:00:53 $
#   Version:   $Revision: 1.16 $
# 
#===============================================================================
# FILE:        dup_deidentify.tcl
# PROCEDURES:  
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

#########################################################
#
if {0} { ;# comment

dup_deidentify - the deidentify pane of the birndup interface

# TODO : 
    * make an about_dialog
    * the "view" method currently copies to temp dir - should fix the dicom
    loader that accepts a list of filenames
}
#
#########################################################

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class dup_deidentify] == "" } {

    itcl::class dup_deidentify {
        inherit iwidgets::Labeledwidget

        public variable parent ""

        variable _name
        variable _frame ""
        variable _return_code ""
        variable _result ""

        constructor {args} {}
        destructor {}

        method refresh {} {}
        method execute {cmd} {}
        method finish_execute {ret res} {}
        method runall {} {}
        method run {dir} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body dup_deidentify::constructor {args} {
    global env

    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name


    set cs [$this childsite]

    set f $cs.frame
    pack [iwidgets::scrolledframe $f -hscrollmode dynamic -vscrollmode dynamic] -fill both -expand true -pady 15
    set _frame $f

    eval itk_initialize $args
}


itcl::body dup_deidentify::destructor {} {
}

itcl::body dup_deidentify::refresh {} {

    foreach w [winfo children $_frame] {
        destroy $w
    }

    set b 0
    foreach s [$parent studies] {
        if { ![file exists $s/deidentify_operations] } {
            tk_messageBox -message "Warning: no deidentify_operations for $s"
            continue
        }
        if { [file exists $s/ready_for_review] } {
            continue
        }
        set birnid [lindex [file split $s] end-3] 
        set bb $_frame.b$b 
        pack [button $bb -text "Deidentify $birnid" -command "$this run $s"]
        dup_TooltipAdd $bb "$s"
        incr b
    }

    if { $b == 0 } {
        pack [label $_frame.l -text "Nothing to deidentify"]
    } else {
        pack [button $_frame.bspace -text "" -relief flat ]
        pack [button $_frame.ball -text "Deidentify All" -command "$this runall"]
    }
}

itcl::body dup_deidentify::runall {} {

    foreach s [$parent studies] {
        $this run $s
    }
}


itcl::body dup_deidentify::run {dir} {

    if { [catch "package require iSlicer"] } {
        error "iSlicer package required to run"
    }

    set fp [open $dir/deidentify_operations "r"]
    set ops [read $fp]
    close $fp

    set resp [dup_DevOKCancel "Click Ok to run deidentification"]

    if { $resp == "ok" } {

        $parent log "starting deidentify of $dir"
        set dcanon_dir [$parent cget -birndup_dir]/dcanon
        set mri_dir [$parent cget -birndup_dir]/bin
        set birnd_up_dir [$parent cget -birndup_dir]
        set atlas_dir [$parent cget -birndup_dir]/atlas
        set ::env(DCANON_DIR) $dcanon_dir
        set ::env(MRI_DIR) $mri_dir
        set ::env(BIN_DIR) $mri_dir
        set ::env(BIRND_UP_DIR) $birnd_up_dir
        set ::env(ATLAS_DIR) $atlas_dir
        foreach op $ops {
            puts "executing $op"
            $parent log "executing $op"

            set res [eval $this execute $birnd_up_dir/$op]
            if { $_return_code } {
                puts stderr "$op failed with error:\n$_result\nresult: \n$res"
                $parent log "$op failed with error:\n$_result\nresult: \n$res"
            } else {
                puts "$op succeeded: \n$res"
                $parent log "$op succeeded: \n$res"
            }
        }
        $parent log "finished deidentify of $dir"

        $parent log "starting rendering of $dir"
        foreach ser [glob -nocomplain $dir/*-anon] {
            puts "rendering $ser"
            $parent log "rendering $ser"

            # this avoids warning messages when slicer starts
            set ::env(SLICER_CUSTOM_CONFIG) "true"

            set steps 15 ;# face 24 degrees per frame
            set skip 3 ;# slices show every 3 mm
            set res [$this execute $::env(SLICER_HOME)/slicer2-linux-x86 --agree_to_license --all-info --no-tkcon --load-dicom $ser --script $::env(SLICER_HOME)/Modules/iSlicer/tcl/evaluation-movies.tcl --exec eval_movies $ser/Deface $steps $skip ., exit]
            if { $_return_code } {
                puts stderr "rendering failed with error:\n$_result\nresult: \n$res"
                $parent log "rendering failed with error:\n$_result\nresult: \n$res"
            } else {
                puts "$op succeeded: \n$res"
                $parent log "$op succeeded: \n$res"
            }

        }
        $parent log "finished deidentify of $dir"

        close [open $dir/ready_for_review "w"]
        $parent refresh review
        $parent refresh deidentify

    } else {
        $parent log "bypassed deidentify of $dir"
    }

}

itcl::body dup_deidentify::execute {args} {

    set ::_dup_execute_wait_var_$_name 0

    if { [catch "package require iSlicer"] } {
        error "iSlicer package required but not available"
    }

    set isp $_frame.isp

    if { [winfo exists $isp] } {
        destroy $isp
    }

    isprocess $isp -commandline $args \
        -finishcommand "$this finish_execute"

    pack $isp -side bottom -fill both -expand true

    [$isp task] on
    [[$isp task] onoffbutton] configure -state disabled 


    if { [set ::_dup_execute_wait_var_${_name}] == 0 } {
        # no error from the open command, so wait for eof or error
        grab [[$isp task] onoffbutton]
        vwait ::_dup_execute_wait_var_$_name
    }

    set result [$isp get]
    destroy $isp
    return $result

}

itcl::body dup_deidentify::finish_execute {ret res} {
    set _return_code $ret 
    set _result $res 
    set ::_dup_execute_wait_var_$_name 1
}
