#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: fMRIEngineSaveAndLoadParadigm.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:38 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        fMRIEngineSaveAndLoadParadigm.tcl
# PROCEDURES:  
#   fMRIEngineSaveParadigm
#   fMRIEngineLoadParadigm
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineSaveParadigm
# Saves the current paradigm 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSaveParadigm {} {
    global fMRIEngine

    if {! [info exists fMRIEngine(1,designType)]} {
        DevErrorWindow "The paradigm is not ready to save."
        return
    }

    # write data to file
    set fileType {{"Text" *.txt}}
    set fileName [tk_getSaveFile -filetypes $fileType -parent .]
    if {[string length $fileName]} {
        set txt ".txt"
        set ext [file extension $fileName]
        if {$ext != $txt} {
            set fileName "$fileName$txt"
        }
        set fHandle [open $fileName w]
        set comment "# This text file saves the paradigm (Set Up -> Paradigm). Do not edit it. \n"
        puts $fHandle $comment

        set comment "# number of runs"
        puts $fHandle $comment
        set str "set fMRIEngine(noOfRuns) $fMRIEngine(noOfRuns) \n"
        puts $fHandle $str

        for {set r 1} {$r <= $fMRIEngine(noOfRuns)} {incr r} {
            set comment "\n# information for run $r"
            puts $fHandle $comment
            set comment "# --------------------- \n"
            puts $fHandle $comment

            set comment "# design type of run $r"
            puts $fHandle $comment
            set str "set fMRIEngine($r,designType) $fMRIEngine($r,designType) \n"
            puts $fHandle $str

            set comment "# blocked, event-related, or mixed?"
            puts $fHandle $comment
            set str "set fMRIEngine(paradigmDesignType) $fMRIEngine(paradigmDesignType) \n"
            puts $fHandle $str

            set comment "# tr of run $r"
            puts $fHandle $comment
            set str "set fMRIEngine($r,tr) $fMRIEngine($r,tr) \n"
            puts $fHandle $str

            set comment "# start volume number of of run $r"
            puts $fHandle $comment
            set str "set fMRIEngine($r,startVol) $fMRIEngine($r,startVol) \n"  
            puts $fHandle $str

            set comment "# condition list of run $r"
            puts $fHandle $comment
            set str "set fMRIEngine($r,conditionList) \[list $fMRIEngine($r,conditionList)\] \n"
            puts $fHandle $str

            foreach title $fMRIEngine($r,conditionList) {
                set comment "# condition name in run $r"
                puts $fHandle $comment
                set str "set fMRIEngine($r,$title,title) $title \n"
                puts $fHandle $str

                set comment "# add condition name into model view"
                puts $fHandle $comment
                set str "fMRIModelViewAddConditionName $r $title \n"  
                puts $fHandle $str

                set comment "# onsets of condition \'$title\' in run $r"
                puts $fHandle $comment
                set str "set fMRIEngine($r,$title,onsets) \"$fMRIEngine($r,$title,onsets)\" \n"  
                puts $fHandle $str

                set comment "# durations of condition \'$title\' in run $r"
                puts $fHandle $comment
                set str "set fMRIEngine($r,$title,durations) \"$fMRIEngine($r,$title,durations)\" \n"  
                puts $fHandle $str
            }
        }

        set comment "# fill tr for the current run"
        puts $fHandle $comment
        set str "set fMRIEngine(entry,tr) \$fMRIEngine(\$fMRIEngine(curRunForConditionConfig),tr) \n"
        puts $fHandle $str

        set comment "# fill start volume number for the current run"
        puts $fHandle $comment
        set str "set fMRIEngine(entry,startVol) \$fMRIEngine(\$fMRIEngine(curRunForConditionConfig),startVol) \n"
        puts $fHandle $str

        close $fHandle
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineLoadParadigm
# Loads paradigm from file 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineLoadParadigm {} {
    global fMRIEngine
 
    # read data from file
    set fileType {{"Text" *.txt}}
    set fileName [tk_getOpenFile -filetypes $fileType -parent .]

    # if user just wanted to cancel
    if {[string length $fileName] <= 0} {
        return
    }
    
    set fHandle [open $fileName r]
    set data [read $fHandle]
    set lines [split $data "\n"]
    foreach line $lines {
        set line [string trim $line]
        eval $line
    }
    close $fHandle

    # show all conditions for first run
    if {$fMRIEngine(noOfRuns) > 0} {
        fMRIEngineUpdateRunsForConditionShow 
        fMRIEngineSelectRunForConditionShow 1 
    }

    set ::fMRIEngine(SignalModelDirty) 1
    # update the condition list in signal modeling tab
    fMRIEngineUpdateConditionsForSignalModeling
}
