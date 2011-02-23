#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: dup_sort.tcl,v $
#   Date:      $Date: 2006/11/17 14:51:18 $
#   Version:   $Revision: 1.24 $
# 
#===============================================================================
# FILE:        dup_sort.tcl
# PROCEDURES:  
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

#########################################################
#
if {0} { ;# comment

dup_sort - the sort pane of the birndup interface

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
if { [itcl::find class dup_sort] == "" } {

    itcl::class dup_sort {
        inherit iwidgets::Labeledframe

        public variable parent ""
        public variable sourcedir ""

        variable _name

        variable _defacedir ""
        variable _study
        variable _series
        variable _DICOMFiles 

        constructor {args} {}
        destructor {}

        method refresh {} {}
        method series_temp_dir {id} {}
        method view {id} {}
        method headers {id} {}
        method setdeident {id method} {}
        method fill {dir} {}
        method sort {} {}
        method make_broken_link {linkname targetdir} {}
        method version {} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body dup_sort::constructor {args} {
    global env

    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name


    set _study(project) ""
    set _study(visit) ""
    set _study(study) ""
    set _study(birnid) ""

    set cs [$this childsite]

    #
    # the sorting interface is created here in three frames, but they
    # are not packed until the directory is filled in (fill method)
    #
    set f $cs.info
    iwidgets::labeledframe $f -labeltext "Study Info" -labelpos nw
    set fcs [$f childsite]
    pack [iwidgets::entryfield $fcs.sourcedir -labeltext "Source Dir: " -state readonly] -fill x
    pack [iwidgets::entryfield $fcs.project -labeltext "Project #: " -textvariable [itcl::scope _study(project)]] -fill x
    pack [iwidgets::entryfield $fcs.visit -labeltext "Visit #: " -textvariable [itcl::scope _study(visit)]] -fill x
    pack [iwidgets::entryfield $fcs.study -labeltext "Study #: " -textvariable [itcl::scope _study(study)]] -fill x
    pack [iwidgets::entryfield $fcs.birnid -labeltext "BIRN ID: " -textvariable [itcl::scope _study(birnid)]]  -fill x
    ::iwidgets::Labeledwidget::alignlabels $fcs.sourcedir $fcs.project $fcs.visit $fcs.study $fcs.birnid
    set f $cs.series
    ::iwidgets::scrolledframe $f -hscrollmode dynamic -vscrollmode dynamic

    set f $cs.buttons
    frame $f
    pack [button $f.sort -text "Sort" -command "$this sort"]


    #
    # a button to be packed when the sort interface isn't
    #
    pack [button $cs.new -text "Select new study to process..." -command "$this fill choose"]

    eval itk_initialize $args
}


itcl::body dup_sort::destructor {} {
}

itcl::configbody dup_sort::parent {
    
    if { $parent != "" } {
        set _defacedir [$parent pref DEFACE_DIR]
    }
}

itcl::body dup_sort::fill {dir} {

    if { $dir == "choose" } {
        $parent fill choose
        return
    }

    set cs [$this childsite]
    set infocs [$cs.info childsite]

    $infocs.sourcedir configure -state normal
    $infocs.sourcedir delete 0 end
    $infocs.sourcedir insert end $dir
    $infocs.sourcedir configure -state readonly

    if { $dir == "" } {
        foreach w [winfo children [[$this childsite].series childsite]] {
            destroy $w
        }
        pack forget $cs.info
        pack forget $cs.buttons
        pack forget $cs.series
        pack $cs.new 
        return
    } 

    pack forget $cs.new 
    pack $cs.info -fill x -pady 5
    pack $cs.series -fill both -expand true
    pack $cs.buttons -fill x  -pady 5

    set ::DICOMrecurse "true"
    set aborted [dup_DefaceFindDICOM $dir *]

    if { $aborted == "true" } {
        $parent fill choose
        return
    }

    if {$::FindDICOMCounter <= 0} {
        dup_DevErrorWindow "No DICOM files found"
        $parent fill choose
        return
    }

    # save a local copy
    array set _DICOMFiles [array get ::DICOMFiles]

    array unset _series
    set _series(ids) ""
    set study $_DICOMFiles(0,StudyInstanceUID)
    set patient $_DICOMFiles(0,PatientID)

    for  {set i 0} {$i < $::FindDICOMCounter} {incr i} {
        if { $study != $_DICOMFiles($i,StudyInstanceUID) ||
                $patient != $_DICOMFiles(0,PatientID) } {
            dup_DevErrorWindow "Multiple patients and/or studies in source directory\n\n$_DICOMFiles(0,FileName)\nand\n$_DICOMFiles($i,FileName)\nThis must be corrected before you can run the files through this pipeline."
            return
        }
        set id $_DICOMFiles($i,SeriesInstanceUID)
        if { [lsearch $_series(ids) $id] == -1 } {
            lappend _series(ids) $id
            set _series($id,list) $i
            set _series($id,SeriesInstanceUID) $_DICOMFiles($i,SeriesInstanceUID)
            set _series($id,FlipAngle) $_DICOMFiles($i,FlipAngle)
        } else {
            lappend _series($id,list) $i
        }
    }

    #
    # set the BIRN ID for this subject
    # - first be sure that the entry exists for this birn id
    # - then pull the value from the table
    #
    set birnid_manager [file normalize [$parent cget -birndup_dir]/birnid_gen/bin/birnid_gen.sh]
    puts $birnid_manager
    set linktable [$parent pref LINKTABLE]
    set inst [$parent pref INSTITUTION]

    if { ![file exists [file dirname $linktable]] } {
        set ret [dup_DevOKCancel "Linktable directory [file dirname $linktable] does not exist.  Okay to create?"]
        if { $ret == "ok" } {
            file mkdir [file dirname $linktable]
        } else {
            return
        }
    }

    if { [catch "exec $birnid_manager --all-info -create -p $inst -l $linktable -c $patient" resp] } {
        dup_DevErrorWindow "Cannot execute BIRN ID manager.  Ensure that Java is installed on your machine.\n\n$resp"
    } else {
        puts $resp
        if { [catch "exec $birnid_manager --all-info -find -l $linktable -c $patient" resp] } {
            dup_DevErrorWindow "Cannot execute BIRN ID manager to access BIRN ID.  Ensure that LINKTABLE preference is correct.\n\n$resp"
            set birnid ""
        } else {
            puts $resp
            set birnid ""
            #scan $resp {Birn ID=%[^,]s} birnid
            set retval [regexp {Birn ID=([a-zA-Z]+[0-9]+)} $resp matchVar birnid]
            if { $retval == 0 || $birnid == "" } {
                dup_DevErrorWindow "Cannot parse BIRN ID.  Response is: \n$resp"
                puts stderr "Cannot parse BIRN ID.  Response is: \n$resp"
            }

            set _study(birnid) $birnid
            $infocs.birnid configure -state normal
            $infocs.birnid delete 0 end
            $infocs.birnid insert end $birnid
            $infocs.birnid configure -state readonly
        }
    }


    #
    # create the facial deidentification options
    #
    set sf [[$this childsite].series childsite]
    set _series(master) ""
    grid [iwidgets::entryfield $sf.lmaster -labeltext "Mask Master:" -textvariable [itcl::scope _series(master)] -state readonly] -columnspan 4

    set row 1
    foreach id $_series(ids) {
        label $sf.l$id -text "Ser $id, Flip $_series($id,FlipAngle)" -anchor w -justify left
        radiobutton $sf.cb$id -value $id -variable [itcl::scope _series(master)]
        iwidgets::optionmenu $sf.om$id -command "$this setdeident $id \[$sf.om$id get\]"
        $sf.om$id insert end "Mask" "Deface" "Header Only" "As Is" "Do Not Upload"
        $this setdeident $id "Mask"
        button $sf.b$id -text "View" -command "$this view $id"
        button $sf.h$id -text "Headers" -command "$this headers $id"
        grid $sf.l$id $sf.cb$id $sf.om$id $sf.b$id $sf.h$id -row $row -sticky ew
        incr row
    }
}

itcl::body dup_sort::sort {} {
    # create the needed entries for each series

    if { $_study(project) == "" } {
        dup_DevErrorWindow "Please set Project #"
        return
    }
    if { $_study(visit) == "" } {
        dup_DevErrorWindow "Please set Visit #"
        return
    }
    if { $_study(study) == "" } {
        dup_DevErrorWindow "Please set Study #"
        return
    }
    if { $_study(birnid) == "" } {
        dup_DevErrorWindow "Please set BIRN ID"
        return
    }
    if { $_defacedir == "" } {
        dup_DevErrorWindow "Please set Destination Directory (temp area for deface processing) using the preferences dialog."
        return
    }

    set has_mask "no"
    foreach id $_series(ids) {
        if { $_series($id,deident_method) == "Mask" } {
            set has_mask "yes"
        }
    }

    if { $has_mask == "yes" && $_series(master) == "" } {
        dup_DevErrorWindow "Please select master series for masking"
        return
    }
    if { $has_mask == "no" && $_series(master) != "" } {
        dup_DevWarningWindow "No series selected for masking - Mask Master ignored."
    }

    if { $_series(master) != "" && ($_series($_series(master),deident_method) != "Deface") } {
        dup_DevErrorWindow "Master series must be set to deface to be used as a mask.  Leave Mask Master blank if no masking is needed."
        set _series(master) ""
        return
    }

    set studypath $_defacedir/Project_$_study(project)/$_study(birnid)/Visit_$_study(visit)/Study_$_study(study)/Raw_Data

    if { [glob -nocomplain $studypath] != "" } {
        if { [dup_DevOKCancel "$studypath is not empty - okay to delete?"] != "ok" } {
            return
        } 
        file delete -force $studypath
    }

    foreach id $_series(ids) {
        set dir $studypath/$id
        file delete -force $dir
        file mkdir $dir
        set _series($id,destdir) $dir
    }

    for  {set i 0} {$i < $::FindDICOMCounter} {incr i} {
        set id $_DICOMFiles($i,SeriesInstanceUID)
        set inum $_DICOMFiles($i,ImageNumber)
        file copy $_DICOMFiles($i,FileName) $_series($id,destdir)/$inum.dcm
    }

    set deident_operations ""
    set mask_series ""
    foreach id $_series(ids) {
        if { $id == $_series(master) } {
            continue
        }
        switch $_series($id,deident_method) {
            "Deface" {
                # deface this on independently - not part of the MaskGroup
                lappend deident_operations "dcanon/dcanon --all-info -radius $_series($id,radius) -deface $_series($id,destdir)"
            }
            "Mask" {
                lappend mask_series "$_series($id,destdir)"
            }
            "Header Only" {
                lappend deident_operations "dcanon/dcanon --all-info -convert $_series($id,destdir)"
            }
            "As Is" {
                lappend deident_operations "dcanon/dcanon --all-info -noanon -convert $_series($id,destdir)"
            }
            "Do Not Upload" {
                # nothing
            }
            default {
                puts stderr "unknown deidentification method  $_series($id,deident_method)"
            }
        }
    }
    $this fill ""

    if { [llength $mask_series] > 0 &&  $_series(master) == "" } {
        error "cannot mask any series without a deface master series"
    }

    if { $_series(master) != "" } {
        set scan 1
        set cmd "scripts/birnd_up --all-info -radius $_series($_series(master),radius) -i $_series($_series(master),destdir)"
        $this make_broken_link $_series($_series(master),destdir)-anon MaskGroup/scan_$scan
        incr scan
        foreach m $mask_series {
            set cmd "$cmd $m"
            $this make_broken_link $m-anon MaskGroup/scan_$scan
            incr scan
        }
        set cmd "$cmd -o $studypath -subjid MaskGroup"
        lappend deident_operations $cmd
    }

    set fp [open "$studypath/source_directory" w]
    puts $fp $sourcedir
    close $fp

    set fp [open "$studypath/deidentify_operations" w]
    puts $fp $deident_operations
    close $fp

    $parent log "sort operation complete for $sourcedir to $studypath"

    tk_messageBox -message "Directory sorted"
    $parent refresh 
}

itcl::body dup_sort::setdeident {id method} {

    set _series($id,deident_method) $method

    if { $method == "Deface" } {
        if { ![info exists _series($id,radius)] } {
            set _series($id,radius) 7 ;# TODO: this is the default for all defacing
        }
        set d .radiusd_$_name
        catch "destroy $d"
        iwidgets::dialogshell $d
        set cs [$d childsite]
        pack [iwidgets::spinint $cs.radius -labeltext "Radius: " -range {1 20}  -width 5] -fill both -expand true 
        $cs.radius delete 0 end
        $cs.radius insert end $_series($id,radius) 
        $cs.radius configure -textvariable [itcl::scope _series($id,radius)] 
        $d add ok -text "OK" -command "set _series($id,radius) \[$cs.radius get\]; destroy $d"
        $d add cancel -text "Cancel" -command "set _series($id,radius) $_series($id,radius); destroy $d"
        $d default ok
        $d activate
        update
        grab $d
        tkwait window $d
        grab release $d

        puts $_series($id,radius)
    }
}


itcl::body dup_sort::series_temp_dir {id} {
    if { ![info exists _series(ids)] } {
        error "no series loaded"
    }
    if { [lsearch $_series(ids) $id] == -1 } {
        error "series $id not loaded"
    }
    if { [info command dup_tempdir] == "" } {
        error "no temp dir command available"
    }
    if { [catch "package require iSlicer"] } {
        error "the iSlicer package is not available"
    }

    set viewdir [dup_tempdir]/$id.[pid]
    file delete -force $viewdir
    file mkdir $viewdir

    foreach i $_series($id,list) {
        file copy $_DICOMFiles($i,FileName) $viewdir/
    }

    return $viewdir
} 


itcl::body dup_sort::view {id} {

    set viewdir [$this series_temp_dir $id]

    catch "destroy .dup_sort_view"
    toplevel .dup_sort_view
    wm geometry .dup_sort_view 400x600
    pack [isframes .dup_sort_view.isf] -fill both -expand true
    .dup_sort_view.isf configure -filepattern $viewdir/* -filetype DICOMImage
    .dup_sort_view.isf middle

}

itcl::body dup_sort::headers {id} {

    set viewdir [$this series_temp_dir $id]

    catch "destroy .dup_sort_headers"
    toplevel .dup_sort_headers
    wm geometry .dup_sort_headers 400x600
    pack [isframes .dup_sort_headers.isf] -fill both -expand true
    .dup_sort_headers.isf configure -filepattern $viewdir/* -filetype text -dumpcommand "$::env(SLICER_HOME)/../birndup/bin/dcmdump" 
}

itcl::body dup_sort::make_broken_link {linkname targetdir} {
    # need to make a relative symbolic link to target that will be made later, but
    # need to make the target directory exists 
    # or link will fail
    # - this is in a new directory, so destdir shouldn't exist yet
    # - NB: this is not cross-platform
    # - remove the directory so that birnd_up can create it later
    # TODO: I don't think this can be done using the tcl file link command
    # since it creates an absolute path for the target

    set cwd [pwd]
    cd [file dirname $linkname]
puts "making link in [pwd]"
puts "exec ln -s $targetdir [file tail $linkname]"
    if { ![file exists $targetdir] } {
        file mkdir $targetdir
        exec ln -s $targetdir [file tail $linkname]
        file delete $targetdir
    } else {
        exec ln -s $targetdir [file tail $linkname]
    }
    cd $cwd
}

itcl::body dup_sort::version {} {
    # print out version information
    
}
