#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MIRIADParameters.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        MIRIADParameters.tcl
# PROCEDURES:  
#   MIRIADParametersDefaults
#   MIRIADParametersLoad filename
#   MIRIADParametersSave filename
#   MIRIADParametersPreview
#   MIRIADParametersRun
#   MIRIADParametersGrayType p
#   MIRIADParameters
#==========================================================================auto=

#
# MIRIAD Parameters - testing harness to drive the MIRIADSegment process
#


package require iSlicer


#-------------------------------------------------------------------------------
# .PROC MIRIADParametersDefaults
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADParametersDefaults {} {

    upvar #0 MIRIADParameters mp  ;# for typing simplicity and readability

    set mp(previewslice) 30

    set mp(pclasses) {
        Air
        OtherTissue
        CSF
        CorticalGrayMatter
        SubCorticalGrayMatter
        NormalWhiteMatter
        LesionedWhiteMatter
    }

    # some possibly reasonable default values
    foreach pc $mp(pclasses) {
        set mp($pc,prob) 0.2
        set mp($pc,ProbDataWeight) 1.0
        set mp($pc,InputChannelWeight,PD) 1.0
        set mp($pc,InputChannelWeight,T2) 1.0
        set mp($pc,logmeans,PD) 4.5678 
        set mp($pc,logmeans,T2) 4.2802 
        set mp($pc,logcov,PD) 7.6805 
        set mp($pc,logcov,cross) 5.0207
        set mp($pc,logcov,T2) 7.3293
    }

    set mp(Air,prob) 0.05
    set mp(Air,logmeans,PD) 2.6544 
    set mp(Air,logmeans,T2) 2.5259
    set mp(Air,logcov,PD) 0.7816
    set mp(Air,logcov,cross) 0.6958
    set mp(Air,logcov,T2) 1.1833

    set mp(OtherTissue,prob) 0.2
    set mp(OtherTissue,logmeans,PD) 6.3429 
    set mp(OtherTissue,logmeans,T2) 5.1534
    set mp(OtherTissue,logcov,PD) 0.1243
    set mp(OtherTissue,logcov,cross) 0.1911
    set mp(OtherTissue,logcov,T2) 0.3905

    set mp(CSF,prob) 0.25
    set mp(CSF,logmeans,PD) 4.5678 
    set mp(CSF,logmeans,T2) 4.2802
    set mp(CSF,logcov,PD) 7.6805
    set mp(CSF,logcov,cross) 5.0207
    set mp(CSF,logcov,T2) 7.3293
    set mp(CSF,InputChannelWeight,PD) 0.2
    set mp(CSF,InputChannelWeight,T2) 1.0

    set mp(NormalWhiteMatter,prob) 0.25
    set mp(NormalWhiteMatter,logmeans,PD) 4.5678 
    set mp(NormalWhiteMatter,logmeans,T2) 4.2802
    set mp(NormalWhiteMatter,logcov,PD) 7.6805
    set mp(NormalWhiteMatter,logcov,cross) 5.0207
    set mp(NormalWhiteMatter,logcov,T2) 7.3293
    set mp(NormalWhiteMatter,InputChannelWeight,PD) 0.2
    set mp(NormalWhiteMatter,InputChannelWeight,T2) 1.0

    set mp(LesionedWhiteMatter,prob) 0.25
    set mp(LesionedWhiteMatter,logmeans,PD) 6.3836
    set mp(LesionedWhiteMatter,logmeans,T2) 5.1253
    set mp(LesionedWhiteMatter,logcov,PD) 0.0026
    set mp(LesionedWhiteMatter,logcov,cross) 0.004
    set mp(LesionedWhiteMatter,logcov,T2) 0.0562
    set mp(LesionedWhiteMatter,InputChannelWeight,PD) 0.2
    set mp(LesionedWhiteMatter,InputChannelWeight,T2) 1.0

    return
}

#-------------------------------------------------------------------------------
# .PROC MIRIADParametersLoad
# 
# .ARGS
# path filename defaults to empty string 
# .END
#-------------------------------------------------------------------------------
proc MIRIADParametersLoad { {filename ""} } {

    if { $filename == "" } {
        set filename [tk_getOpenFile -initialdir $::env(SLICER_HOME)/Modules/vtkMIRIADSegment/data]
    }
    if { $filename == "" } return;

    set fp [open $filename r]
    array set ::MIRIADParameters [read $fp]
    close $fp
}

#-------------------------------------------------------------------------------
# .PROC MIRIADParametersSave
# 
# .ARGS
# path filename defaults to empty string 
# .END
#-------------------------------------------------------------------------------
proc MIRIADParametersSave { {filename ""} } {

    if { $filename == "" } {
        set filename [tk_getSaveFile -initialdir $::env(SLICER_HOME)/Modules/vtkMIRIADSegment/data -initialfile params-[clock format [clock seconds]]]
    }
    if { $filename == "" } return;

    set fp [open $filename w]
    puts $fp [array get ::MIRIADParameters]
    close $fp
}

#-------------------------------------------------------------------------------
# .PROC MIRIADParametersPreview
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADParametersPreview { } {

    MIRIADSegmentSetEMParameters 
    MIRIADSegmentRunEM "preview"
    for {set s 0} {$s < 3} {incr s} {
        set ::Slice($s,offset) $::MIRIADParameters(previewslice)
        MainSlicesSetOffset $s
        RenderSlice $s
    }
}

#-------------------------------------------------------------------------------
# .PROC MIRIADParametersRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADParametersRun { } {

    MIRIADSegmentSetEMParameters 
    MIRIADSegmentRunEM

}

#-------------------------------------------------------------------------------
# .PROC MIRIADParametersGrayType
# 
# .ARGS
# string p
# .END
#-------------------------------------------------------------------------------
proc MIRIADParametersGrayType { p } {

    switch $p {
        "OtherGray" -
        "LAnteriorInsulaCortex" - 
        "RAnteriorInsulaCortex" -
        "LInferiorTemporalGyrus" -
        "RInferiorTemporalGyrus" -
        "LMiddleTemporalGyrus" -
        "RMiddleTemporalGyrus" -
        "LPosteriorInsulaCortex" -
        "RPosteriorInsulaCortex" -
        "LSuperiorTemporalGyrus" - 
        "RSuperiorTemporalGyrus" -
        "LTemporalLobe" -
        "RTemporalLobe" {
            return "cortical"
        }
        "LThalamus" -
        "RThalamus" -
        "LAmygdala" -
        "RAmygdala" -
        "LHippocampus" -
        "RHippocampus" -
        "LParahippocampus" -
        "RParahippocampus" {
            return "subcortical"
        }
        default {
            error "unknown gray matter parcel $p"
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC MIRIADParameters
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MIRIADParameters {} {

    if { ![info exists ::MIRIADParameters] } {
        MIRIADParametersDefaults
    }
    upvar #0 MIRIADParameters mp  ;# for typing simplicity and readability

    catch "destroy .mp"
    toplevel .mp
    wm title .mp "MIRIAD Parameters"
    wm geometry .mp 750x610+50+20

    pack [::iwidgets::scrolledframe .mp.f -hscrollmode dynamic -vscrollmode dynamic] -fill both -expand true

    set cs [.mp.f childsite]

    set i 0
    foreach pc $mp(pclasses) {

        set f [::iwidgets::labeledframe $cs.f$i -labeltext $pc -labelpos nw]
        pack $f -fill both -expand true

        set fcs [$f childsite]
        ::iwidgets::spinfloat $fcs.prob \
            -textvariable ::MIRIADParameters($pc,prob) -range "0 1" -width 7 \
            -labeltext "Prob" -labelpos nw
        ::iwidgets::spinfloat $fcs.logmeanpd \
            -textvariable ::MIRIADParameters($pc,logmeans,PD)  -width 7 \
            -labeltext "PDlmean" -labelpos nw
        ::iwidgets::spinfloat $fcs.logmeant2 \
            -textvariable ::MIRIADParameters($pc,logmeans,T2)  -width 7 \
            -labeltext "T2lmean" -labelpos nw
        ::iwidgets::spinfloat $fcs.logcovpd \
            -textvariable ::MIRIADParameters($pc,logcov,PD)  -width 7 \
            -labeltext "PDlcov" -labelpos nw
        ::iwidgets::spinfloat $fcs.logcovcross \
            -textvariable ::MIRIADParameters($pc,logcov,cross)  -width 7 \
            -labeltext "cross cov" -labelpos nw
        ::iwidgets::spinfloat $fcs.logcovt2 \
            -textvariable ::MIRIADParameters($pc,logcov,T2)  -width 7 \
            -labeltext "T2lcov" -labelpos nw
        ::iwidgets::spinfloat $fcs.probweight \
            -textvariable ::MIRIADParameters($pc,ProbDataWeight) -range "0 1"  -width 7 \
            -labeltext "Pweight" -labelpos nw
        ::iwidgets::spinfloat $fcs.weightpd \
            -textvariable ::MIRIADParameters($pc,InputChannelWeight,PD) -range "0 1" -width 7 \
            -labeltext "PDweight" -labelpos nw
        ::iwidgets::spinfloat $fcs.weightt2 \
            -textvariable ::MIRIADParameters($pc,InputChannelWeight,T2) -range "0 1" -width 7 \
            -labeltext "T2weight" -labelpos nw

        pack $fcs.prob $fcs.logmeanpd $fcs.logmeant2 $fcs.logcovpd $fcs.logcovcross $fcs.logcovt2 $fcs.probweight $fcs.weightpd $fcs.weightt2 -side left -padx 2

        incr i
    }

    

    set f [frame $cs.fbuttons]  

    pack [iwidgets::spinint $f.prevsl -labeltext "Preview" -textvariable MIRIADParameters(previewslice) -width 3] -side left
    pack [button $f.load -text "Load..." -command MIRIADParametersLoad] -side left
    pack [button $f.save -text "Save..." -command MIRIADParametersSave] -side left
    pack [button $f.xfer -text "Transfer" -command MIRIADSegmentSetEMParameters ] -side left
    pack [button $f.preview -text "Preview" -command MIRIADParametersPreview] -side left
    pack [button $f.run -text "Run" -command MIRIADParametersRun] -side left
    pack $f 
}

