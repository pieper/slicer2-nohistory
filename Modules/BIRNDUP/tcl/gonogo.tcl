#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: gonogo.tcl,v $
#   Date:      $Date: 2006/04/13 17:24:57 $
#   Version:   $Revision: 1.15 $
# 
#===============================================================================
# FILE:        gonogo.tcl
# PROCEDURES:  
#   createImages
#   getDone upload_file defer_file
#   getSeriesApproval series_path
#   getStudyApproval study_path
#   mpClose view
#   mpCloseAll
#   mpForward view
#   mpOpen view
#   mpTogglePause view
#   viewSlicer series_path
#==========================================================================auto=
#===============================================================================
# gonogo.tcl
#
# Description
# ----------------
# This is the deface postprocessing script for verification of face removal.
#
#
#
# Procs
# ----------------
# createImages
# getSeriesApproval
# getStudyApproval
# mpClose
# mpCloseAll
# mpForward
# mpOpen
# mpTogglePause
# getDone
# viewSlicer
# main
#
#
#===============================================================================

global MP ROOT VIEW_LIST
set VIEW_LIST "face slices-axial slices-coronal slices-sagittal"

set GONOGO_VERSION "0.9"

# TODO - fix mplayer
##set MP $env(MP_PATH)

#-------------------------------------------------------------------------------
# .PROC createImages
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc createImages {} {
    global play pause forward

    set bitmapdata(play) {
    #define play_width 24
    #define play_height 16
    static char play_bits[] = {
    0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x06, 0x00, 0x00, 0x0e, 0x00,
    0x00, 0x1e, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x7e, 0x00, 0x00, 0xfe, 0x00,
    0x00, 0x7e, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x0e, 0x00,
    0x00, 0x06, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    }

    set bitmapdata(pause) {
    #define pause_width 24
    #define pause_height 16
    static char pause_bits[] = {
    0x00, 0x00, 0x00, 0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03,
    0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03,
    0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03,
    0xc0, 0xc3, 0x03, 0xc0, 0xc3, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    }

    set bitmapdata(forward) {
    #define forward_width 24
    #define forward_height 16
    static char forward_bits[] = {
    0x00, 0x00, 0x00, 0x20, 0x70, 0x00, 0x60, 0x70, 0x00, 0xe0, 0x70, 0x00,
    0xe0, 0x71, 0x00, 0xe0, 0x73, 0x00, 0xe0, 0x77, 0x00, 0xe0, 0x7f, 0x00,
    0xe0, 0x77, 0x00, 0xe0, 0x73, 0x00, 0xe0, 0x71, 0x00, 0xe0, 0x70, 0x00,
    0x60, 0x70, 0x00, 0x20, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    }

   image create bitmap pause -data $bitmapdata(pause)
   image create bitmap play -data $bitmapdata(play)
   image create bitmap forward -data $bitmapdata(forward)
}

#-------------------------------------------------------------------------------
# .PROC getDone
# 
# .ARGS
# path upload_file contains the list of series that were approved for upload
# path defer_file contains the list of deferred series
# .END
#-------------------------------------------------------------------------------
proc getDone {upload_file defer_file} {
    global ROOT

    set msg "UPLOAD FILE=\n$upload_file\nDEFER FILE=\n$defer_file\n\nDEFER FILE contains the list of deferred series.\nUPLOAD FILE contains the list of series that were approved for upload, used as the basis for file uploads."

    catch {destroy $ROOT.done}
    toplevel $ROOT.done -class Dialog
    wm title $ROOT.done "Go/No-Go Complete"
    wm iconname $ROOT.done "Go/No-Go Complete"

    eval frame $ROOT.done.top -relief raised -bd 1
    pack $ROOT.done.top -side top -fill both -expand 1
    eval frame $ROOT.done.bot -relief raised -bd 1
    pack $ROOT.done.bot -side bottom -fill both -expand 1

    eval message $ROOT.done.top.msg -justify center -font [list "Arial 14 bold"] -text [list "Go/No-Go session is complete"] -width 500
    pack $ROOT.done.top.msg -expand 1 -padx 2
    eval message $ROOT.done.msg -text [list "$msg"] -justify left -font [list "Arial 12"] -width 500
    pack $ROOT.done.msg -side left -padx 5m -pady 3m
    eval button $ROOT.done.bot.ok -text OK -command [list "set done_value 1"]
    pack $ROOT.done.bot.ok -expand 1 -pady 3m

    wm withdraw $ROOT.done
    update idletasks
    set x [expr {([winfo screenwidth .] - [winfo reqwidth $ROOT.done])/2}]
    set y [expr {([winfo screenheight .] - [winfo reqheight $ROOT.done])/2}]
    if {$x<0} {set x 0}
    if {$y<0} {set y 0}
    wm geom $ROOT.done +$x+$y
    wm deiconify $ROOT.done


    # Wait on click of ok button, then return
    #-------------------------------------------------------------------
    tkwait variable done_value
    wm withdraw $ROOT.done
    destroy $ROOT.done
}

#-------------------------------------------------------------------------------
# .PROC getSeriesApproval
# 
# .ARGS
# path series_path Path to the files in the series
# .END
#-------------------------------------------------------------------------------
proc getSeriesApproval {series_path} {
    global ROOT VIEW_LIST mp_file ser_rvalue series_approval series_reviewal mp_out mp_paused bitmapdata pause play forward

    wm withdraw $ROOT.gonogo
    set ser_rvalue 1

    foreach view $VIEW_LIST {
        #set mp_file($view) "$series_path/Deface/$view.mpg"
        # sp: changed to frame rendering
        set mp_file(series_path) "$series_path"
        set mp_file($view) "$series_path/Deface/$view-0000.png"
        set mp_file($view,pattern) "$series_path/Deface/$view*"
        set mp_out($view) ""
        set mp_paused($view) 0
    }

    #option add *[tk appname]*background [option get . background background] 90
    #option add *[tk appname]*HighlightThickness 0 90

    catch {destroy $ROOT.mp}
    toplevel $ROOT.mp -class Dialog
    wm title $ROOT.mp "Series Go/No-Go"
    wm iconname $ROOT.mp "Series Go/No-Go"

    eval frame $ROOT.mp.top -relief raised -bd 1
    pack $ROOT.mp.top -side top -fill both -expand 1
    eval frame $ROOT.mp.bot -relief raised -bd 1
    pack $ROOT.mp.bot -side bottom -fill both -expand 1
    eval label $ROOT.mp.msg -justify left -text [list "Verifying series: [file tail $series_path]"]
    pack $ROOT.mp.msg -in $ROOT.mp.top -fill both -expand 1 -padx 1m -pady 3m

    button $ROOT.mp.headers -text "View Headers" -command "mpOpenHeaders"
    pack $ROOT.mp.headers -in $ROOT.mp.top -fill both -expand 1 -padx 1m -pady 3m

    createImages

    foreach view $VIEW_LIST {
        eval frame $ROOT.mp.$view -relief sunken
        pack $ROOT.mp.$view -fill both -pady 5
        eval label $ROOT.mp.$view.ptext -text "$view:" -width 15
        pack $ROOT.mp.$view.ptext -side left

        puts "looking for $series_path/Deface/$view.mpg"
        if {[file exists $mp_file($view)] == 1} {
            eval button $ROOT.mp.$view.open -text Open -command [list "mpOpen $view"]
            pack $ROOT.mp.$view.open -side left -fill y
            eval button $ROOT.mp.$view.play -text Pause -command [list "mpTogglePause $view"] -image pause
            pack $ROOT.mp.$view.play -side left -fill y
            eval button $ROOT.mp.$view.forward -text Forward -command [list "mpForward $view"] -image forward
            pack $ROOT.mp.$view.forward -side left -fill y
            $ROOT.mp.$view.play config -state disabled
            $ROOT.mp.$view.forward config -state disabled
        } else {
            eval label $ROOT.mp.$view.notfound -text [list "File Not Found"]
            pack $ROOT.mp.$view.notfound -side left
        }
    }


    eval button $ROOT.mp.bot.upload -relief raised -text Upload -command [list "set ser_rvalue 1"]
    pack $ROOT.mp.bot.upload -side left -expand 1 -padx 3m -pady 5m
    eval button $ROOT.mp.bot.defer -relief raised -text Defer -command [list "set ser_rvalue 0"]
    pack $ROOT.mp.bot.defer -side left -expand 1 -padx 3m -pady 5m
    eval button $ROOT.mp.bot.slicer -relief raised -text [list "View in Slicer"] -command [list "viewSlicer $series_path"]
    pack $ROOT.mp.bot.slicer -side left -expand 1 -padx 3m -pady 5m

    wm withdraw $ROOT.mp
    update idletasks
    set y [expr {([winfo screenheight .] - [winfo reqheight $ROOT.mp])/2}]
    set x 0
    if {$y<0} {set y 0}
    wm geom $ROOT.mp +$x+$y
    wm deiconify $ROOT.mp

    wm protocol $ROOT.mp WM_DELETE_WINDOW "set ser_rvalue -1"

    # Wait on click of defer or upload button
    #-------------------------------------------------------------------
    tkwait variable ser_rvalue
    mpCloseAll
    wm withdraw $ROOT.mp
    destroy $ROOT.mp
    wm deiconify $ROOT.gonogo
    set series [string map {. ""} [file tail $series_path]]

    set series_reviewal($series_path) 1
    set all_reviewed 1
    foreach s [array names series_reviewal] {
        if {$series_reviewal($s) == 0} {
            set all_reviewed 0
        }
    }
    if {$all_reviewed == 1} {
        $ROOT.gonogo.ok configure -state normal
    } else {
        $ROOT.gonogo.ok configure -state disabled
    }

    if {$ser_rvalue == 1} {
         $ROOT.gonogo.f$series.lstatus config -text Approved -fg DarkOliveGreen
         set series_approval($series_path) 1
    } else {
         $ROOT.gonogo.f$series.lstatus config -text Deferred -fg red
         set series_approval($series_path) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC getStudyApproval
# 
# .ARGS
# path study_path 
# .END
#-------------------------------------------------------------------------------
proc getStudyApproval {study_path} {
    global ROOT MP series_approval rvalue series_reviewal upload_series_list defer_series_list

    set rvalue 1
    set my_title "Study Go/No Go"

    # Create the top-level window and divide it into top and bottom parts
    #--------------------------------------------------
    catch {destroy $ROOT.gonogo}
    toplevel $ROOT.gonogo -class Dialog
    wm title $ROOT.gonogo $my_title
    wm iconname $ROOT.gonogo $my_title

    eval frame $ROOT.gonogo.bot -relief raised -bd 1
    pack $ROOT.gonogo.bot -side bottom -fill both -expand 1
    eval frame $ROOT.gonogo.top -relief raised -bd 1
    pack $ROOT.gonogo.top -side top -fill both -expand 1
    eval label $ROOT.gonogo.msg -justify left -text [list "Verifying study:\n$study_path"]
    pack $ROOT.gonogo.msg -in $ROOT.gonogo.top -fill both -expand 1 -padx 1m -pady 3m

    # Create a frame for each series, each frame contains a label with the series
    # name, a button to review the mpeg files for the series, and
    # label that tells the status of review
    # - sp: only look at the -anon directories
    #----------------------------------------------------------------------------
    set series_list [lsort [glob -nocomplain $study_path/*-anon] ]
    foreach series_path $series_list {
        set series [string map {. ""} [file tail $series_path]]
        set series_approval($series_path) 0
        set series_reviewal($series_path) 0
        eval frame $ROOT.gonogo.f$series -bd 1 -relief sunken
        pack $ROOT.gonogo.f$series  -fill both -expand 1
        eval label $ROOT.gonogo.f$series.lname -text [file tail $series_path]
        pack $ROOT.gonogo.f$series.lname -side left -padx 5m -pady 3m
        eval button $ROOT.gonogo.f$series.breview -text Review -command [list "getSeriesApproval $series_path"]
        pack $ROOT.gonogo.f$series.breview -side left -padx 5m -pady 3m
        eval label $ROOT.gonogo.f$series.lstatus -text [list "Not Reviewed"]
        pack $ROOT.gonogo.f$series.lstatus -side left -padx 5m -pady 3m
    }

    # Create button for ok, it is disabled until all series are reviewed
    #------------------------------------------------------------------
    eval button $ROOT.gonogo.ok -relief raised -text OK -state disabled -command [list "set rvalue 1"]
    eval button $ROOT.gonogo.cancel -relief raised -text Cancel -command [list "set rvalue -1"]
    pack $ROOT.gonogo.ok $ROOT.gonogo.cancel -in $ROOT.gonogo.bot -side left -expand 1 -padx 5m -pady 5m

    # Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it
    #-----------------------------------------------------------------
    wm withdraw $ROOT.gonogo
    update idletasks
    set y [expr {([winfo screenheight .] - [winfo reqheight $ROOT.gonogo])/2}]
    set x 0
    if {$y<0} {set y 0}
    wm geom $ROOT.gonogo +$x+$y
    wm deiconify $ROOT.gonogo

    wm protocol $ROOT.gonogo WM_DELETE_WINDOW "set rvalue -1"

    # Wait on click of ok button, then return
    #-------------------------------------------------------------------
    tkwait variable rvalue
    wm withdraw $ROOT.gonogo
    destroy $ROOT.gonogo

    if { $rvalue == -1 } {
        exit -1 
    }

    foreach s [array names series_approval] {
        if {$series_approval($s) == 1} {
            lappend upload_series_list $s
        } else {
            lappend defer_series_list $s
        }
    }
    return 0
}

#-------------------------------------------------------------------------------
# .PROC mpClose
# 
# .ARGS
# int view 
# .END
#-------------------------------------------------------------------------------
proc mpClose {view} {
    global ROOT mp_out VIEW_LIST mp_paused mp_file


    [$mp_file($view,w).isf task] off
    $mp_file($view,w).isf pre_destroy
    update idletasks
    catch "destroy $mp_file($view,w)"

    if {0} {
        if { $mp_paused($view) == 1} {
            mpTogglePause $view
        }

        puts $mp_out($view) "quit"
        flush $mp_out($view)
        catch "close $mp_out($view)" err
        set mp_out($view) ""
    }

    $ROOT.mp.$view.play config -state disabled
    $ROOT.mp.$view.forward config -state disabled
    eval $ROOT.mp.$view.open config -text Open -command [list "mpOpen $view"]
}

#-------------------------------------------------------------------------------
# .PROC mpCloseAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc mpCloseAll {} {
    global VIEW_LIST mp_out

    foreach view $VIEW_LIST {
        catch "mpClose $view"
    }
}

#-------------------------------------------------------------------------------
# .PROC mpForward
# 
# .ARGS
# int view
# .END
#-------------------------------------------------------------------------------
proc mpForward {view} {
    global mp_out mp_paused mp_file

    if { $mp_paused($view) == 0} {
        mpTogglePause $view
    } else {
        $mp_file($view,w).isf next

        #puts $mp_out($view) "seek 1"
        #flush $mp_out($view)
        #puts $mp_out($view) "pause"
        #flush $mp_out($view)
    }
}

#-------------------------------------------------------------------------------
# .PROC mpOpen
# 
# .ARGS
# int view name of the view window
# str pattern optional file pattern, unix command line style
# .END
#-------------------------------------------------------------------------------
proc mpOpen {view {pattern ""}} {
    global ROOT MP mp_file mp_out


    set w .$view
    set mp_file($view,w) $w
    catch "destroy $w"
    toplevel $w
    wm geometry $w 650x700
    
    if {$pattern == ""} {
        set pattern  $mp_file($view,pattern)
    }

    pack [isframes $w.isf -filepattern $pattern] -fill both -expand true
    [$w.isf task] on
    wm protocol $w WM_DELETE_WINDOW "mpClose $view"

    if {[info command $ROOT.mp.$view.play] != ""} {
        $ROOT.mp.$view.play config -state normal
    }
    if {[info command  $ROOT.mp.$view.forward] != ""} {
        $ROOT.mp.$view.forward config -state normal
    }
    if {[info command $ROOT.mp.$view.open] != ""} {
        eval $ROOT.mp.$view.open config -text Close -command [list "mpClose $view"]
    }

}

#-------------------------------------------------------------------------------
# .PROC mpOpenHeaders
# show the dicom headers for the current series 
# .ARGS
# 
# .END
#-------------------------------------------------------------------------------
proc mpOpenHeaders {} {
    global ROOT MP mp_file mp_out


    set w .headers
    catch "destroy $w"
    toplevel $w
    wm geometry $w 850x400

    pack [isframes $w.isf -filetype "text" -dumpcommand "$::env(SLICER_HOME)/../birndup/bin/dcmdump" -filepattern $mp_file(series_path)/*] -fill both -expand true
    [$w.isf task] on
}

#-------------------------------------------------------------------------------
# .PROC mpTogglePause
# 
# .ARGS
# int view
# .END
#-------------------------------------------------------------------------------
proc mpTogglePause {view} {
    global ROOT mp_out mp_file mp_paused pause play

    if { $mp_paused($view) == 1} {
        $ROOT.mp.$view.play config -image pause
        set mp_paused($view) 0
        [$mp_file($view,w).isf task] on
    } else {
        $ROOT.mp.$view.play config -image play
        set mp_paused($view) 1
        [$mp_file($view,w).isf task] off
    }

    #puts $mp_out($view) "pause"
    #flush $mp_out($view)
}

#-------------------------------------------------------------------------------
# .PROC viewSlicer
# 
# .ARGS
# path series_path
# .END
#-------------------------------------------------------------------------------
proc viewSlicer {series_path} {

    # TODO - this is linux specific
    set pid_slicer [exec $::env(SLICER_HOME)/slicer2-linux-x86 --all-info --load-dicom $series_path &]
}

#-------------------------------------------------------------------------------
#
# main
#
#-------------------------------------------------------------------------------
proc main {} {
    global ROOT MP upload_series_list defer_series_list

    if { [catch "package require iSlicer"] } {
        dup_DevErrorWindow "Need iSlicer Module to run this program.  Please update Slicer"
        exit 1
    }

    if { [catch "package require BIRNDUP"] } {
        dup_DevErrorWindow "Need BIRNDUP Module to run this program. Please update Slicer"
        exit 1
    }

    dup_AllInfo $::argv $::GONOGO_VERSION

    set ROOT ""

    package require Tk
    wm withdraw .

    if { $::argc == 0 } {
        set indir [tk_chooseDirectory -mustexist true -title "Choose Subject Root Directory"]
    } else {
        set indir [lindex $::argv 0]
    }

    if { $indir == "" } {
        # No directory specified, go ahead and quit
        exit 0
    }

    set upload_series_list ""
    set defer_series_list ""
    set in_study_list ""

    # Directory structure should be:
    # subj/visit/study/Raw_Data/series/Deident/slices.mpg, */deface.mpg
    # - note: indir on the command line is now a studydir (sp 2004-02-23)
    #------------------------------------------------------------------
    set in_study_list $indir

    foreach study $in_study_list {
        getStudyApproval $study
    }

    # Upload/Defer - write one file with paths to upload series and
    # another file with paths to deferred series, the file with series to
    # upload is used for input to the upload perl script
    #----------------------------------------------------------------------
    set upload_file "$indir/upload_list.txt"
    set defer_file "$indir/defer_list.txt"
    set upload_out [open $upload_file w]
    set defer_out [open $defer_file w]

    foreach defer_ser $defer_series_list {
        puts $defer_out [string trimright $defer_ser "/"]
    }
    foreach upload_ser $upload_series_list {
        puts $upload_out [string trimright $upload_ser "/"]
    }
    puts $defer_out ""
    puts $upload_out ""
    close $defer_out 
    close $upload_out 

    getDone $upload_file $defer_file

    exit 0
}


# Execute main
#--------------------------------------------------------------------------
main

# end
##########################################
