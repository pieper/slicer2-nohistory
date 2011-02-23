#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: birnPipelineMain.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        birnPipelineMain.tcl
# PROCEDURES:  
#   MIRIADSegmentMain argc argv
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MIRIADSegmentMain
# 
# .ARGS
# int argc number of arguments
# list argv template.xml atlas-dir results-dir subject-name
# .END
#-------------------------------------------------------------------------------
proc MIRIADSegmentMain { argc argv } {

    if { $argc != 4 } {
        puts stderr "usage: $argv0 template.xml atlas-dir results-dir subject-name"
        puts stderr "e.g. $argv0 /home/me/blah.xml /home/me/results SUBJ0061"
        puts stderr "basic pathnames are set in template"
        exit 1
    }

    set BIRNseg(template) [ lindex $argv 0 ]
    set BIRNseg(atlasdir) [lindex $argv 1 ]
    set BIRNseg(resultsdir) [ lindex $argv 2 ]
    set BIRNseg(subjname) [ lindex $argv 3 ]

    cd $BIRNseg(resultsdir)


    set BIRNseg(subjresultsdir) [ file join $BIRNseg(resultsdir) \
                        $BIRNseg(subjname) ]

    set BIRNseg(subjectatlasdir) [ file join $BIRNseg(atlasdir) \
                        $BIRNseg(subjname) ]


    #### create results dir, if necessary ####

    if { ! [ file isdirectory $BIRNseg(resultsdir) ] } {
        # no top level results directory
        puts stderr "warning: creating (top-level) results directory: $BIRNseg(resultsdir) and"
        puts stderr "         subject directory $BIRNseg(subjname)"

    } elseif { [ file isdirectory $BIRNseg(subjresultsdir) ] } {
        # subject dir exists, must rename


        # try to rename to .01, .02, .03, etc.
        for { set i 1 } { $i <= 10 } { incr i } {
            set newdir [ format "%s.%2.2d" $BIRNseg(subjresultsdir) $i ]
            if { ! [ file isdirectory $newdir ] } {
                break 
            }
        }

        if { $i > 10 } {
            error "too many subject directories ${BIRNseg(subjresultsdir)}.01, .02, etc.  rename some"
        }

        if { [ catch { file rename $BIRNseg(subjresultsdir) $newdir } errmsg ] } {
            error "couldn't rename subject directory: $BIRNseg(subjresultsdir): $errmsg"
        }


    }

    # file mkdir makes several levels at a time
    if { [ catch { file mkdir $BIRNseg(subjresultsdir) } errmsg ] } {
        error "can't create results directory: $BIRNseg(subjresultsdir): $errmsg"
    }


    #### read template XML file/write new XML file ####

    set newXMLFiles [ BIRNprocessXMLTemplateFile $BIRNseg(template) $BIRNseg(resultsdir) $BIRNseg(atlasdir) $BIRNseg(subjname) ]

    EMSegmentReadXMLFile [ lindex $newXMLFiles 1 ]


    #### Normalize Atlases

    set MaxValue $EMSegment(NumberOfTrainingSamples)
    for {set i 1} {$i <= $EMSegment(VolNumber)} {incr i} {
        if {[lsearch $EMSegment(SelVolList,VolumeList) $i] == -1} {
            lappend NormList $i
        }
    }


    NormImage $MaxValue "$NormList" $BIRNseg(subjresultsdir)


    # delete old volumes so new XML file can be read in 

    for { set i 1 } { $i <= $EMSegment(VolNumber) } { incr i } { 
        Volume($i,vol) Delete
    }

    unset Volume
    unset EMSegment

    cd $BIRNseg(subjresultsdir)

    set argc 2
    set argv [ list  [ lindex $newXMLFiles 0 ] 0 ]

    source [ file join $env(SCRIPT_HOME) tcl EMSegmentBatch.tcl ]

}

