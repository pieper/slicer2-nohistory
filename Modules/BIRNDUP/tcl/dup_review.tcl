#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: dup_review.tcl,v $
#   Date:      $Date: 2006/03/17 15:45:43 $
#   Version:   $Revision: 1.13 $
# 
#===============================================================================
# FILE:        dup_review.tcl
# PROCEDURES:  
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

#########################################################
#
if {0} { ;# comment

dup_review - the review pane of the birndup interface

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
if { [itcl::find class dup_review] == "" } {

    itcl::class dup_review {
        inherit iwidgets::Labeledwidget

        public variable parent ""

        variable _frame ""

        constructor {args} {}
        destructor {}

        method refresh {} {}
        method run {studydir} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body dup_review::constructor {args} {
    global env

    set cs [$this childsite]

    set f $cs.frame
    pack [iwidgets::scrolledframe $f -hscrollmode dynamic -vscrollmode dynamic] -fill both -expand true -pady 15
    set _frame $f

    eval itk_initialize $args
}


itcl::body dup_review::destructor {} {
}

itcl::body dup_review::refresh {} {

    foreach w [winfo children $_frame] {
        destroy $w
    }

    set defacedir [$parent pref DEFACE_DIR]
    set studies [$parent studies]
    

    set b 0
    foreach s $studies {
        if { [file exists $s/ready_for_upload] } {
            continue
        }
        if { ![file exists $s/ready_for_review] } {
            continue
        }
        set birnid [lindex [file split $s] end-3] 
        set bb $_frame.b$b 
        pack [button $bb -text "Review $birnid" -command "$this run $s"]
        dup_TooltipAdd $bb "$s"
        incr b
    }

    if { $b == 0 } {
        pack [label $_frame.l -text "Nothing to review"]
        return
    }
}

itcl::body dup_review::run {studydir} {

    $parent log "starting review of $studydir"

    # TODO - this avoids warning messages when slicer starts
    set ::env(SLICER_CUSTOM_CONFIG) "true"
    # TODO - this is linux only
    set ret [catch "exec $::env(SLICER_HOME)/slicer2-$::env(BUILD) --agree_to_license $::PACKAGE_DIR_BIRNDUP/../../../tcl/gonogo.tcl $studydir" res]

    if { $ret && $::errorCode != "NONE" } {
        dup_DevErrorWindow "Could not launch the review process.  Please file a bug report with the following information.\n\n$res"
    }

    if { ![file exists $studydir/upload_list.txt] } {
        # user cancelled
        return
    }

    set to_upload [::dup_review::cat $studydir/upload_list.txt]
    set to_defer [::dup_review::cat $studydir/defer_list.txt]
    
    set defercount [llength $to_defer]
    if { $defercount > 0 } {
        set resp [dup_DevOKCancel "The Study contains $defercount series that did not pass review.\n\nClick Ok to upload only the approved series or cancel to defer the entire study."]
        if { $resp != "ok" } {
            set sourcedir [::dup_review::cat $studydir/source_directory] 
            dup_DevErrorWindow "The study in $sourcedir did not pass review.  Manual defacing must be used."
            file delete -force $studydir
            $parent log "manual defacing needed for $studydir"
            $parent refresh 
            return
        }
    }
    close [open $studydir/ready_for_upload "w"]


    $parent log "finished review of $studydir"
    $parent refresh 
}

proc dup_review::cat {filename} {
    set fp [open $filename r]
    set data [read $fp]
    close $fp
    return $data
}
