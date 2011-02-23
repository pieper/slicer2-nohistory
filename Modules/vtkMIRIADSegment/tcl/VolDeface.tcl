#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: VolDeface.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:56 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        VolDeface.tcl
# PROCEDURES:  
#   VolDefaceInit
#   DefaceFindDICOM2 StartDir AddDir Pattern
#   DefaceFindDICOM StartDir Pattern
#   DefaceCreateSeriesList PatientIDName StudyUID
#   DefaceCreateFileNameList PatientIDName StudyUID SeriesUID
#   DefaceClickListStudyUIDs idsnames study seriesMask series filenames
#   DefaceFillSeriesListbox t aidx
#   DefaceResetSeriesListbox t
#   DefaceToggleButton  t idx value
#   DefaceClickListSeriesUIDs series
#   DICOMListSelectClose parent filelist
#   DefaceGetVisitId top message
#   DefaceMakeDir  dirname
#   DefaceValidateVisitId  top
#   DefaceSortBySeries  datapath PatientID VisitID StudyUID
#   DefaceInvoke  parent idsnames study series fileNames
#   DefaceProgressExec args
#   DefaceScrolledTextbox f xAlways yAlways variable labeltext args
#   DefaceListSelect parent values
#   DefaceSelectDir top
#   DefaceSelectMain start_dir
#   DICOMImageTextboxFragmentEnter w tag
#   DICOMImageTextboxFragmentLeave w tag
#   DICOMImageTextboxSelectAll
#   DICOMImageTextboxDeselectAll
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC VolDefaceInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolDefaceInit {} {
    global Volume Volumes Path Preset Module

    # Define Procedures for communicating with Volumes.tcl
    #---------------------------------------------
    set m VolDeface
    # procedure for building GUI in this module's frame
    set Volume(readerModules,$m,procGUI)  ${m}BuildGUI


    # Define Module Description to be used by Volumes.tcl
    #---------------------------------------------
    # name for menu button
    set Volume(readerModules,$m,name)  Deface

    # tooltip for help
    #set Volume(readerModules,$m,tooltip)  \
    #        "This tab displays information\n
    #for the currently selected dicom volume."


    # Global variables used inside this module
    #---------------------------------------------

    # Added by Attila Tanacs 10/18/2000
    set Volumes(DefaceStartDir) ""
    #set Volumes(FileNameSortParam) "incr"
    #set Volumes(prevIncrDecrState) "incr"
    #set Volumes(previewCount) 0

    #set Volumes(DICOMPreviewWidth) 64
    #set Volumes(DICOMPreviewHeight) 64
    #set Volumes(DICOMPreviewHighestValue) 2048

    #set Volumes(DICOMCheckVolumeList) {}
    #set Volumes(DICOMCheckPositionList) {}
    #set Volumes(DICOMCheckActiveList) {}
    #set Volumes(DICOMCheckActivePositionList) {}
    #set Volumes(DICOMCheckSliceDistanceList) {}

    #set Volumes(DICOMCheckImageLabelIdx) 0
    #set Volumes(DICOMCheckLastPosition) 0
    #set Volumes(DICOMCheckSliceDistance) 0

    set dir [file join [file join $Path(program) tcl-modules] Volumes]
    set Volumes(DICOMDataDictFile) $dir/datadict.txt

    #set Module(Volumes,presets) "DICOMStartDir='$Path(program)' FileNameSortParam='incr' \
#DICOMPreviewWidth='64' DICOMPreviewHeight='64' DICOMPreviewHighestValue='2048' \
#DICOMDataDictFile='$Volumes(DICOMDataDictFile)'"

    # End
}


#-------------------------------------------------------------------------------
# .PROC DefaceFindDICOM2
# 
# .ARGS
# path StartDir
# path AddDir
# string Pattern
# .END
#-------------------------------------------------------------------------------
proc DefaceFindDICOM2 { StartDir AddDir Pattern } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames DICOMPatientIDs 

    set pwd [pwd]
    if [expr [string length $AddDir] > 0] {
        if [catch {cd $AddDir} err] {
            puts stderr $err
            return
        }
    }
    
    vtkDCMParser parser
    foreach match [glob -nocomplain -- $Pattern] {
        #puts stdout [file join $StartDir $match]
        if {[file isdirectory $match]} {
            continue
        }
        set FileName [file join $StartDir $AddDir $match]
        set found [parser OpenFile $match]
        if {[string compare $found "0"] == 0} {
            puts stderr "Can't open file [file join $StartDir $AddDir $match]"
        } else {
            set found [parser FindElement 0x7fe0 0x0010]
            if {[string compare $found "1"] == 0} {
                #
                # image data is available
                #
                
                set DICOMFiles($FindDICOMCounter,FileName) $FileName
                
                if [expr [parser FindElement 0x0010 0x0010] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set PatientName [parser ReadText $Length]
                    if {$PatientName == ""} {
                        set PatientName "noname"
                    }
                } else  {
                    set PatientName 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,PatientName) $PatientName
                AddListUnique DICOMPatientNames $PatientName
                
                if [expr [parser FindElement 0x0010 0x0020] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set PatientID [string trim [parser ReadText $Length]]
                    if {$PatientID == ""} {
                        set PatientID "noid"
                    }
                } else  {
                    set PatientID 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,PatientID) $PatientID
                AddListUnique DICOMPatientIDs $PatientID
                set add {}
                append add "<" $PatientID "><" $PatientName ">"
                AddListUnique DICOMPatientIDsNames $add
                set DICOMFiles($FindDICOMCounter,PatientIDName) $add
                #DYW change to studyID if [expr [parser FindElement 0x0020 0x000d] == "1"] 
                if [expr [parser FindElement 0x0020 0x0010] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set StudyInstanceUID [string trim [parser ReadText $Length]]
                    set zeros [string length $StudyInstanceUID]
                    if { $zeros > 4 } {
                       set StudyInstanceUID [string range $StudyInstanceUID [expr $zeros - 4] end]
                    } else {
                       set zeros [expr 4 - $zeros]
                       for {set lloop $zeros} {$lloop > 0} {inrc lloop -1} {
                          set StudyInstanceUID "0$StudyInstanceUID"
                       }
                    }             
                } else  {
                    set StudyInstanceUID 9999
                }
                set DICOMFiles($FindDICOMCounter,StudyInstanceUID) $StudyInstanceUID
                #DYW change to seriesID if [expr [parser FindElement 0x0020 0x000e] == "1"] 
                if [expr [parser FindElement 0x0020 0x0011] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set SeriesInstanceUID [string trim [parser ReadText $Length]]
                    set zeros [string length $SeriesInstanceUID ]
                    if { $zeros > 3 } {
                       set SeriesInstanceUID [string range $SeriesInstanceUID [expr $zeros - 3] end]
                    } else {
                       set zeros [expr 3 - $zeros]
                       for {set lloop 0} {$lloop < $zeros} {incr lloop } {
                          set SeriesInstanceUID "0$SeriesInstanceUID"
                       }
                    }             
                } else  {
                    set SeriesInstanceUID 999
                }
                set DICOMFiles($FindDICOMCounter,SeriesInstanceUID) $SeriesInstanceUID


                if [expr [parser FindElement 0x0020 0x0020] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set ProjectID [string trim [parser ReadText $Length]]
                    set zeros [string length $ProjectID ]
                    if { $zeros > 4 } {
                       set ProjectID [string range $ProjectID [expr $zeros - 4] end]
                    } else {
                       set zeros [expr 4 - $zeros]
                       for {set lloop 0} {$lloop < $zeros} {incr lloop } {
                          set ProjectID "0$ProjectID"
                       }
                    }             
                } else  {
                    set ProjectID  9999
                }
                set DICOMFiles($FindDICOMCounter,ProjectID) $ProjectID


                if [expr [parser FindElement 0x0020 0x0040] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set SubjectID [string trim [parser ReadText $Length]]
                    
                } else  {
                    set SubjectID 99999999
                }
                set DICOMFiles($FindDICOMCounter,SubjectID) $SubjectID


                if [expr [parser FindElement 0x0018 0x1314] == "1"] {
                    set Length [lindex [split [parser ReadElement]] 3]
                    set FlipAngle [string trim [parser ReadText $Length]]
                } else  {
                    set FlipAngle 'unknown'
                }
                set DICOMFiles($FindDICOMCounter,FlipAngle) $FlipAngle

                
        #set ImageNumber ""
        #if [expr [parser FindElement 0x0020 0x1041] == "1"] {
        #    set NextBlock [lindex [split [parser ReadElement]] 4]
        #    set ImageNumber [parser ReadFloatAsciiNumeric $NextBlock]
        #} 
        #if { $ImageNumber == "" } {
            if [expr [parser FindElement 0x0020 0x0013] == "1"] {
            #set Length [lindex [split [parser ReadElement]] 3]
            #set ImageNumber [parser ReadText $Length]
            #scan [parser ReadText $length] "%d" ImageNumber
            
            set NextBlock [lindex [split [parser ReadElement]] 4]
            set ImageNumber [parser ReadIntAsciiNumeric $NextBlock]
            } else  {
            set ImageNumber 1
            }
        #}
                
                    set zeros [string length $ImageNumber  ]
                    if { $zeros > 3 } {
                       set SeriesInstanceUID [string range $ImageNumber [expr $zeros - 3] end]
                    } else {
                       set zeros [expr 3 - $zeros]
                       for {set lloop 0} {$lloop < $zeros} {incr lloop } {
                          set ImageNumber "0$ImageNumber"
                       }
                    }             
                set DICOMFiles($FindDICOMCounter,ImageNumber) $ImageNumber
                
                incr FindDICOMCounter
                #puts [file join $StartDir $AddDir $match]
            } else {
                #set dim 256
            }
            parser CloseFile
        }
    }
    parser Delete
    
    foreach file [glob -nocomplain *] {
        if [file isdirectory $file] {
            DefaceFindDICOM2 [file join $StartDir $AddDir] $file $Pattern
        }
    }
    cd $pwd
}

#-------------------------------------------------------------------------------
# .PROC DefaceFindDICOM
# 
# .ARGS
# path StartDir
# string Pattern
# .END
#-------------------------------------------------------------------------------
proc DefaceFindDICOM { StartDir Pattern } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames DICOMPatientIDs 
    global DICOMStudyInstanceUIDList
    global DICOMSeriesInstanceUIDList
    global DICOMFileNameArray
    global DICOMFileNameList DICOMFileNameSelected
    
    if [array exists DICOMFiles] {
        unset DICOMFiles
    }
    if [array exists DICOMFileNameArray] {
        unset DICOMFileNameArray
    }
    set pwd [pwd]
    set FindDICOMCounter 0
    set DICOMPatientNames {}
    set DICOMPatientIDsNames {}
    set DICOMPatientIDs {}
    set DICOMStudyList {}
    set DICOMSeriesList {}
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    
    if [catch {cd $StartDir} err] {
        puts stderr $err
        cd $pwd
        return
    }
    DefaceFindDICOM2 $StartDir "" $Pattern
    cd $pwd
}


#-------------------------------------------------------------------------------
# .PROC DefaceCreateSeriesList
# 
# .ARGS
# string PatientIDName
# int StudyUID
# .END
#-------------------------------------------------------------------------------
proc DefaceCreateSeriesList { PatientIDName StudyUID } {
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMSeriesList
    
    set DICOMSeriesList {}
    for  {set i 0} {$i < $FindDICOMCounter} {incr i} {
        if {[string compare $DICOMFiles($i,PatientIDName) $PatientIDName] == 0} {
            if {[string compare $DICOMFiles($i,StudyInstanceUID) $StudyUID] == 0} {
                # AddListUnique DICOMSeriesList $DICOMFiles($i,SeriesInstanceUID)
                set SeriesIDFlipAngle "$DICOMFiles($i,SeriesInstanceUID)___"
                set SeriesIDFlipAngle "$SeriesIDFlipAngle$DICOMFiles($i,FlipAngle)"
                AddListUnique DICOMSeriesList [string trim $SeriesIDFlipAngle] 
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC DefaceCreateFileNameList
# 
# .ARGS
# string PatientIDName
# int StudyUID
# int SeriesUID
# .END
#-------------------------------------------------------------------------------
proc DefaceCreateFileNameList { PatientIDName StudyUID SeriesUID} {
    global Volumes
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMFileNameArray
    global DICOMFileNameList DICOMFileNameSelected
    
    catch {unset DICOMFileNameArray}
    set count 0
    for  {set i 0} {$i < $FindDICOMCounter} {incr i} {
        if {[string compare $DICOMFiles($i,PatientIDName) $PatientIDName] == 0} {
            if {[string compare $DICOMFiles($i,StudyInstanceUID) $StudyUID] == 0} {
                if {[regexp $DICOMFiles($i,SeriesInstanceUID) $SeriesUID] == 1} {
                    #set id [format "%04d_%04d" $DICOMFiles($i,ImageNumber) $count]
            #set id [format "%010.4f_%04d" $DICOMFiles($i,ImageNumber) $count]
            #set id [format "%012.4f_%04d" [expr 10000.0 + $DICOMFiles($i,ImageNumber)] $count]
                    set id [format "%04d" $count]
                    incr count
                    set DICOMFileNameArray($id) $DICOMFiles($i,FileName)
                }
            }
        }
    }
    #set idx [lsort -decreasing [array name DICOMFileNameArray]]
    #set idx [lsort [array name DICOMFileNameArray]]
    if {$Volumes(FileNameSortParam) == "incr"} {
    set idx [lsort -increasing [array name DICOMFileNameArray]]
    } else {
    set idx [lsort -decreasing [array name DICOMFileNameArray]]
    }
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    foreach i $idx {
        lappend DICOMFileNameList $DICOMFileNameArray($i)
    lappend DICOMFileNameSelected "1"
    }
}


#-------------------------------------------------------------------------------
# .PROC DefaceClickListStudyUIDs
# 
# .ARGS
# list idsnames 
# string study 
# string seriesMask 
# string series 
# list filenames
# .END
#-------------------------------------------------------------------------------
proc DefaceClickListStudyUIDs { idsnames study seriesMask series filenames } {
    global DICOMPatientIDsNames
    global DICOMStudyList
    global DICOMSeriesList
    global DICOMListSelectStudyUID
    global DICOMListSelectSeriesUID
    
    set nameidx [$idsnames index active]
    set name [lindex $DICOMPatientIDsNames $nameidx]
    set studyididx [$study curselection]
    set studyid [lindex $DICOMStudyList $studyididx]
    set DICOMListSelectStudyUID $studyid
    DefaceCreateSeriesList $name $studyid
    $series delete 0 end
    DefaceResetSeriesListbox $seriesMask
    eval {$series insert end} $DICOMSeriesList
    #$filenames delete 0 end
    $filenames delete 1.0 end
    set DICOMListSelectSeriesUID "none selected"
}

#-------------------------------------------------------------------------------
# .PROC DefaceFillSeriesListbox
# 
# .ARGS
# windowpath t
# int aidx
# .END
#-------------------------------------------------------------------------------
proc DefaceFillSeriesListbox {t aidx} {
    global DICOMSeriesList DefaceMask 

    $t configure -state normal
    set yviewfr [lindex [$t yview] 0]
    $t delete 1.0 end
        
    set num [llength $DICOMSeriesList ]
    for {set idx 0} {$idx < $num} {incr idx} {
       set firstpos [$t index insert]
       set dMask [lindex $DefaceMask $idx]
       if { $idx == $aidx } {
          set lrelief raised
       } else {
          set lrelief flat
       }

       switch $dMask {
          "M" {
              $t insert insert " M " vis$idx 
         
              $t tag config vis$idx -background green -relief groove -borderwidth 2
              set value "U"
          } 
          "U" {
              $t insert insert " U " vis$idx 
              $t tag config vis$idx -background yellow -relief groove -borderwidth 2
              set value "N"
          }
          "N" {
              $t insert insert " N " vis$idx 
              $t tag config vis$idx -background white -relief groove -borderwidth 2
              set value "D"
          }
          "D" {
              $t insert insert " D " vis$idx 
              $t tag config vis$idx -background red -relief groove -borderwidth 2
              set value "M"
          }
       }
       $t insert insert " [lindex $DICOMSeriesList $idx]\n"
       $t tag add line$idx $firstpos [$t index insert] 
       $t tag config line$idx -relief $lrelief -borderwidth 2
       $t tag bind line$idx <Button-1> "DefaceToggleButton $t $idx $value"
    }
    $t yview moveto $yviewfr
    $t configure -state disabled
}

#-------------------------------------------------------------------------------
# .PROC DefaceResetSeriesListbox
# 
# .ARGS
# windowpath t
# .END
#-------------------------------------------------------------------------------
proc DefaceResetSeriesListbox {t} {
    global DICOMSeriesList DICOMListSelectSeriesUID DefaceMask 
 
    set DefaceMask {}
    set num [llength $DICOMSeriesList ]
    for {set idx 0} {$idx < $num} {incr idx} {
       lappend DefaceMask "M"
    }
    DefaceFillSeriesListbox $t 0
    
}


#-------------------------------------------------------------------------------
# .PROC DefaceToggleButton 
# 
# .ARGS
# windowpath t
# int idx
# string value
# .END
#-------------------------------------------------------------------------------
proc DefaceToggleButton {t idx value} {
    global DICOMSeriesList DICOMListSelectSeriesUID DefaceMask
    set DefaceMask [lreplace $DefaceMask $idx $idx $value ]
    DefaceFillSeriesListbox $t $idx
    DefaceClickListSeriesUIDs $idx
}

#-------------------------------------------------------------------------------
# .PROC DefaceClickListSeriesUIDs
# idsnames study series filenames 
# .ARGS
# list series
# .END
#-------------------------------------------------------------------------------
proc DefaceClickListSeriesUIDs {series} {
    global DICOMPatientIDsNames
    global DICOMStudyList
    global DICOMSeriesList
    global DICOMFileNameList
    global DICOMListSelectSeriesUID
    global Volumes
    
    #set nameidx [$idsnames index active]
    set nameidx [$Volumes(DICOMIDs) index active]
    set name [lindex $DICOMPatientIDsNames $nameidx]
    #set studyididx [$study index active]
    set studyididx [$Volumes(DICOMStudyID) index active]
    set studyid [lindex $DICOMStudyList $studyididx]
    #set seriesididx [$series curselection]
    set seriesididx $series
    
    if {$seriesididx == ""} {
        return
    }
    
    set seriesid [lindex $DICOMSeriesList $seriesididx]
    set DICOMListSelectSeriesUID $seriesid
    DefaceCreateFileNameList $name $studyid $seriesid
    DICOMFillFileNameTextbox $Volumes(DICOMFileNameTextbox)
}

#-------------------------------------------------------------------------------
# .PROC DICOMListSelectClose
# 
# .ARGS
# windowpath parent
# list filelist
# .END
#-------------------------------------------------------------------------------
proc DICOMListSelectClose { parent filelist } {
    global DICOMFileNameList DICOMFileNameSelected
    global Pressed
    
#     set list2 $DICOMFileNameList
#     set DICOMFileNameList {}
#     set num [llength $DICOMFileNameSelected]
#     for {set i 0} {$i < $num} {incr i} {
#     if {[lindex $DICOMFileNameSelected $i] == "1"} {
#         lappend DICOMFileNameList [lindex $list2 $i]
#     }
#     }
    
    set Pressed OK
    destroy $parent
}


#-------------------------------------------------------------------------------
# .PROC DefaceGetVisitId
# 
# .ARGS
# windowpath top
# string message
# .END
#-------------------------------------------------------------------------------
proc DefaceGetVisitId { top message} {
    global Pressed
    global Gui
    global VisitID 

    set Pressed Cancel
    set VisitID 000
    
    toplevel $top -bg $Gui(activeWorkspace)
    wm minsize $top 100 100
    wm title $top " Get Visit ID"

    set f1 [frame $top.f1 -bg $Gui(activeWorkspace)]
    set f3 [frame $top.f3 -bg $Gui(activeWorkspace)]
    
    eval { label $f1.label -text "$message"} $Gui(WLA)
    eval { entry $f1.visitid -textvariable VisitID } $Gui(WEA)
    eval {button $f3.ok -text "OK" -command "DefaceValidateVisitId $top"} $Gui(WBA)
    eval {button $f3.cancel -text "Cancel" -command "destroy $top"} $Gui(WBA)

    pack $f1.label $f1.visitid -side top -padx 10 -pady 10
    pack $f3.ok $f3.cancel -side left -padx 10 -pady 10 -anchor center
    pack $f1
    pack $f3 

    bind $f1.visitid <Key-Return> "DefaceValidateVisitId $top"       
}

#-------------------------------------------------------------------------------
# .PROC DefaceMakeDir 
# 
# .ARGS
# string dirname
# .END
#-------------------------------------------------------------------------------
proc DefaceMakeDir { dirname } {
    file mkdir $dirname
    return $dirname
}

#-------------------------------------------------------------------------------
# .PROC DefaceValidateVisitId 
# 
# .ARGS
# windowpath top
# .END
#-------------------------------------------------------------------------------
proc DefaceValidateVisitId { top } {
   global VisitID 
   global Pressed

   if {$VisitID == "" } {
       tk_messageBox -message "Please input a three digit visit id!"
       focus $top.f1.visitid 
       return
   }
   if {[regexp {[^0-9]} $VisitID ] == 1 } {
       tk_messageBox -message "Please input a three-digit visit id!"
       focus $top
       grab $top
       return 
   }

   set VisitID Visit_$VisitID
   set Pressed OK; 
   destroy $top  
}

#-------------------------------------------------------------------------------
# .PROC DefaceSortBySeries 
# 
# .ARGS
# path datapath 
# int PatientID 
# int VisitID 
# int StudyUID
# .END
#-------------------------------------------------------------------------------
proc DefaceSortBySeries { datapath PatientID VisitID StudyUID} {

    global Volumes
    global DICOMFiles
    global FindDICOMCounter
    global DICOMPatientNames
    global DICOMPatientIDsNames
    global DICOMFileNameArray DICOMSeriesList 
    global DICOMFileNameList DICOMFileNameSelected
    global DefaceDir DefaceMaskDirList DefaceMask 

    set DefaceMaskDirList {}
    set count 0
    for  {set i 0} {$i < $FindDICOMCounter} {incr i} {
        if {[string compare $DICOMFiles($i,PatientID) $PatientID] == 0} {
            if {[string compare $DICOMFiles($i,StudyInstanceUID) $StudyUID] == 0} {
                set pDir Project_
                append pDir $DICOMFiles($i,ProjectID) 
                set subjectDir BIRN_
                append subjectDir $DICOMFiles($i,SubjectID) 
                set path [file join $datapath $pDir $subjectDir $VisitID Study_$StudyUID "Raw_Data"]
                
                set num [llength $DICOMSeriesList ]
                for {set idx 0} {$idx < $num} {incr idx} {
                   set dMask [lindex $DefaceMask $idx]
                   set s [lindex $DICOMSeriesList $idx]
                   if {[regexp $DICOMFiles($i,SeriesInstanceUID) $s] == 1} {
                       set sDir $DICOMFiles($i,SeriesInstanceUID).ser
                       set path [ file join $path $sDir]
                       switch $dMask {
                          "M" {
                              AddListUnique DefaceMaskDirList $path
                          }
                          "D" {
                              set DefaceDir $path
                          }
                       } 
                       DefaceMakeDir $path                       
                       set path [file join $path $DICOMFiles($i,ImageNumber).dcm] 
                       if {[catch {file copy -- $DICOMFiles($i,FileName) $path} msg] } {
                          tk_messageBox -message "coping error: \n $msg"
                          return -1
                       }
                    }
                }
            }
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC DefaceInvoke 
# 
# .ARGS
# windowpath parent 
# list idsnames 
# string study 
# string series 
# list fileNames
# .END
#-------------------------------------------------------------------------------
proc DefaceInvoke { parent idsnames study series fileNames } {
    global DICOMFileNameList DICOMFileNameSelected
    global Pressed VisitID
    global DICOMPatientIDsNames DICOMPatientIDs
    global DICOMStudyList
    global DICOMSeriesList DefaceMask 
    global DICOMFileNameList
    global DICOMListSelectSeriesUID
    global DefaceDir DefaceMaskDirList 
    global env

    if { ![info exists env(DEFACE_DATA)] || ![file isdirectory $env(DEFACE_DATA)] } {
        set msg "Please set environmental variable DEFACE_DATA as"
        set msg "$msg the root directory of defaced data files.\n"
        set msg "$msg\nClick Ok to browse for directory."
        if { [tk_messageBox -message $msg -type "okcancel"] == "cancel" } {
            return 0
        }
        set env(DEFACE_DATA) [tk_chooseDirectory -title DEFACE_DATA]
        if { $env(DEFACE_DATA) == "" } {
            return 0
        }
    }
    puts "DEFACE_DATA: $env(DEFACE_DATA)" 

    if { ![info exists env(DCANON)] || ![file executable $env(DCANON)] } {
        set msg "Please set environmental variable DCANON as"
        set msg "$msg the executable of the dcanon program.\n"
        set msg "$msg\nClick Ok to browse for file."
        if { [tk_messageBox -message $msg -type "okcancel"] == "cancel" } {
            return 0
        }
        set env(DCANON) [tk_getOpenFile -title DCANON]
        if { $env(DCANON) == "" } {
            return 0
        }
    }
    puts "DCANON: $env(DCANON)" 
  
    set num [llength $DefaceMask]
    set ll_count 0
    for {set idx 0} {$idx < $num} {incr idx} {
       if { [regexp [lindex $DefaceMask $idx] D] == 1 } {
          incr ll_count
       }
    }

    if {$ll_count != 1 } {
        set msg {Please make sure that one and only one series is marked as "D" to deface!}
        tk_messageBox -message "$msg" -title "Information" -type ok
        return 0
    }
    
    set seriesid $DICOMListSelectSeriesUID ; #[lindex $DICOMSeriesList $seriesididx]    
    set nameidx [$idsnames index active]
    set name [lindex $DICOMPatientIDsNames $nameidx]
    set patientid [lindex $DICOMPatientIDs $nameidx]
    set studyididx [$study index active]
    set studyid [lindex $DICOMStudyList $studyididx]

    set msg "Please input a three-digit visit_id:"    
    DefaceGetVisitId .select $msg
    focus .select.f1.visitid 
    grab .select
    tkwait window .select
    
    if { $Pressed != "OK" } {
        return 0
    } 

    #set dataPath [file join $env(DEFACE_DATA) $patientid $VisitID $studyid]
    set dataPath $env(DEFACE_DATA)
    
    DefaceSortBySeries $dataPath $patientid $VisitID $studyid
  
    puts "running dcanon --deface with series in ${DefaceDir} .... "; update
    DefaceProgressExec $env(DCANON) -deface ${DefaceDir}
    foreach s $DefaceMaskDirList {
       puts "running dcanon --mask with series in $s  .... "; update
       DefaceProgressExec $env(DCANON) -mask $s ${DefaceDir}-anon
    }
}

#-------------------------------------------------------------------------------
# .PROC DefaceProgressExec
# 
# .ARGS
# list args
# .END
#-------------------------------------------------------------------------------
proc DefaceProgressExec {args} {
    set fp [open "| /bin/csh -c \"$args\" |& cat" r]
    while { ![catch "pid $fp"] && ![eof $fp] } {
        puts [gets $fp]; update
    }
}

#-------------------------------------------------------------------------------
# .PROC DefaceScrolledTextbox
# 
# .ARGS
# windowpath f 
# boolean xAlways 
# boolean yAlways 
# string variable 
# string labeltext defaults to labeltext
# list args defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc DefaceScrolledTextbox {f xAlways yAlways variable {labeltext "labeltext"} {args ""}} {
    global Gui
    
    set fmain $f
    frame $fmain -bg $Gui(activeWorkspace)
    eval { label $fmain.head -text $labeltext } $Gui(WLA)
    eval { label $fmain.selected -textvariable $variable } $Gui(WLA)

    frame $fmain.f -bg $Gui(activeWorkspace)
    set f $fmain.f
    if {$xAlways == 1 && $yAlways == 1} { 
        text $f.list \
            -xscrollcommand "$f.xscroll set" \
            -yscrollcommand "$f.yscroll set"
    
    } elseif {$xAlways == 1 && $yAlways == 0} { 
        text $f.list \
            -xscrollcommand "$f.xscroll set" \
            -yscrollcommand [list ScrollSet $f.yscroll \
                [list grid $f.yscroll -row 0 -column 1 -sticky ns]]

    } elseif {$xAlways == 0 && $yAlways == 1} { 
        text $f.list \
            -xscrollcommand [list ScrollSet $f.xscroll \
                [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
            -yscrollcommand "$f.yscroll set"

    } else {
        text $f.list \
            -xscrollcommand [list ScrollSet $f.xscroll \
                [list grid $f.xscroll -row 1 -column 0 -sticky we]] \
            -yscrollcommand [list ScrollSet $f.yscroll \
                [list grid $f.yscroll -row 0 -column 1 -sticky ns]]
    }

            eval {$f.list configure \
            -font {helvetica 7 bold} \
            -bg $Gui(normalButton) -fg $Gui(textDark) \
            -selectbackground $Gui(activeButton) \
            -selectforeground $Gui(textDark) \
            -highlightthickness 0 -bd $Gui(borderWidth) \
            -relief sunken -selectborderwidth $Gui(borderWidth)}
   
    if {$args != ""} {
        eval {$f.list configure} $args
    }

    scrollbar $f.xscroll -orient horizontal \
        -command [list $f.list xview] \
        -bg $Gui(activeWorkspace) \
        -activebackground $Gui(activeButton) -troughcolor $Gui(normalButton) \
        -highlightthickness 0 -bd $Gui(borderWidth)
    scrollbar $f.yscroll -orient vertical \
        -command [list $f.list yview] \
        -bg $Gui(activeWorkspace) \
        -activebackground $Gui(activeButton) -troughcolor $Gui(normalButton) \
        -highlightthickness 0 -bd $Gui(borderWidth)

    grid $f.list $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    pack $fmain.head $fmain.selected -anchor nw -pady 5
    pack $fmain.f -fill both -expand true
    pack $fmain -fill both -expand true 

    return $fmain.f.list
}
#-------------------------------------------------------------------------------
# .PROC DefaceListSelect
# 
# .ARGS
# windowpath parent
# lsit values
# .END
#-------------------------------------------------------------------------------
proc DefaceListSelect { parent values } {

    global DICOMListSelectPatientName
    global DICOMListSelectStudyUID
    global DICOMListSelectSeriesUID
    global DICOMListSelectFiles
    global Gui
    global Pressed
    global Volumes

    set DICOMListSelectFiles ""
    set defaceMask ""

    toplevel $parent -bg $Gui(activeWorkspace)
    wm title $parent "List of DICOM studies"
    wm minsize $parent 640 480

    frame $parent.f1 -bg $Gui(activeWorkspace)
    frame $parent.f2 -bg $Gui(activeWorkspace)
    frame $parent.f3 -bg $Gui(activeWorkspace)
    frame $parent.f4 -bg $Gui(activeWorkspace)
    pack $parent.f1 $parent.f2 -fill x
    pack $parent.f3

    set iDsNames [DICOMScrolledListbox $parent.f1.iDsNames 0 1 DICOMListSelectPatientName "Patient <ID><Name>" -width 50 -height 5]
    TooltipAdd $iDsNames "Select a patient"
    set studyUIDs [DICOMScrolledListbox $parent.f1.studyUIDs 0 1 DICOMListSelectStudyUID "Study UID" -width 50 -height 5]
    TooltipAdd $studyUIDs "Select a study of the selected patient"
    pack $parent.f1.iDsNames $parent.f1.studyUIDs -side left -expand true -fill both
    set seriesMask [DefaceScrolledTextbox $parent.f2.seriesMask 0 0 DICOMListSelectSeriesUID "Series UID___Flip Angle" -width 25 -height 15 -spacing1 0.026i -spacing3 0.0265i  -wrap none -cursor hand1 -state disabled]
    TooltipAdd $seriesMask "Click on a series to toggle among D for mri_deface, M for mri_mask, U for upload only and N for N/A"    
    set seriesUIDs [DICOMScrolledListbox $parent.f4.seriesUIDs 0 1 DICOMListSelectSeriesUID "Series UID___Flip Angle" -width 25 -height 15]
    #TooltipAdd $seriesUIDs "Select a series of the selected study"    
    set fileNames [DICOMScrolledTextbox $parent.f2.fileNames 0 1 DICOMListSelectFiles "Files" -width 50 -height 15 -wrap none -cursor hand1 -state disabled]
    set Volumes(DICOMIDs) $iDsNames 
    set Volumes(DICOMStudyID) $studyUIDs 
    set Volumes(DICOMSeriersID) $seriesUIDs 
    set Volumes(DICOMFileNameTextbox) $fileNames
    TooltipAdd $fileNames "Select files of the selected series"
    pack $parent.f2.seriesMask $parent.f2.fileNames -side left -expand true -fill both

    eval {button $parent.f3.deface -text "Deface" -command [list DefaceInvoke $parent $iDsNames $studyUIDs $seriesUIDs $fileNames]} $Gui(WBA)
    eval {button $parent.f3.close -text "Reset Series" -command [list DefaceResetSeriesListbox $seriesMask]} $Gui(WBA)
    eval {button $parent.f3.cancel -text "Cancel" -command "set Pressed Cancel; destroy $parent"} $Gui(WBA)
    pack $parent.f3.deface $parent.f3.close $parent.f3.cancel -padx 10 -pady 10 -side left

    # >> Bindings

    bind $iDsNames <ButtonRelease-1> [list ClickListIDsNames %W $studyUIDs $seriesUIDs $fileNames]
    #bind $iDsNames <Double-1> [list ClickListIDsNames %W $studyUIDs $seriesUIDs $fileNames]
    bind $studyUIDs <ButtonRelease-1> [list DefaceClickListStudyUIDs $iDsNames %W $seriesMask $seriesUIDs $fileNames]
    #bind $seriesUIDs <ButtonRelease-1> [list DefaceClickListSeriesUIDs $iDsNames $studyUIDs %W $fileNames]
    #bind $seriesMask <ButtonRelease-1> [list DefaceClickListSeriesUIDs $iDsNames $studyUIDs %W $fileNames]


    # << Bindings
    
    foreach x $values {
        $iDsNames insert end $x
    }
    
    $iDsNames selection set 0
    ClickListIDsNames $iDsNames $studyUIDs $seriesUIDs $fileNames
    $studyUIDs selection set 0
    DefaceClickListStudyUIDs $iDsNames $studyUIDs $seriesMask $seriesUIDs $fileNames
    $seriesUIDs selection set 0
    #DefaceClickListSeriesUIDs $iDsNames $studyUIDs $seriesUIDs $fileNames
    DefaceClickListSeriesUIDs 0
}

#-------------------------------------------------------------------------------
# .PROC DefaceSelectDir
# 
# .ARGS
# windowpath top
# .END
#-------------------------------------------------------------------------------
proc DefaceSelectDir { top } {
    global DICOMStartDir
    global Pressed
    global Gui
    toplevel $top -bg $Gui(activeWorkspace)
    wm minsize $top 100 100
    wm title $top "Select Start Directory"

    set f1 [frame $top.f1 -bg $Gui(activeWorkspace)]
    set f2 [frame $top.f2 -bg $Gui(activeWorkspace)]
    set f3 [frame $top.f3 -bg $Gui(activeWorkspace)]
    
    set dirlist [ScrolledListbox $f2.dirlist 1  1 -width 30 -height 15]
    TooltipAdd $dirlist "Select start directory for search"
    
    eval { button $f1.changeto -text "Change To:" -command  [list ChangeDir $dirlist]} $Gui(WBA)
    eval { entry $f1.dirname -textvariable DICOMStartDir } $Gui(WEA)
    
    eval {button $f3.ok -text "OK" -command "set Pressed OK; destroy $top"} $Gui(WBA)
    eval {button $f3.cancel -text "Cancel" -command "set Pressed Cancel; destroy $top"} $Gui(WBA)
    eval {button $f3.help -text "Help" -command "DICOMSelectDirHelp"} $Gui(WBA)

    pack $f1.changeto $f1.dirname -side left -padx 10 -pady 10
    pack $f2.dirlist -fill both -expand true
    pack $f3.ok $f3.cancel $f3.help -side left -padx 10 -pady 10 -anchor center
    pack $f1
    pack $f2 -fill both -expand true
    pack $f3
    #pack $window
    

    set pwd [pwd]
    catch {cd $DICOMStartDir}

    if {$DICOMStartDir == ""} {
      set DICOMStartDir {C:\slicer} ; #DYW [pwd]
    }
    
    ChangeDir $dirlist
    #$dirlist delete 0 end
    #$dirlist insert end ".."
    #foreach match [glob -nocomplain *] {
    #    if {[file isdirectory $match]} {
    #        $dirlist insert end $match
    #        #puts $dir
    #    }
    #}
    
#    bind $dirlist <ButtonRelease-1> [list ClickDirList %W]
    bind $dirlist <Double-1> [list ClickDirList %W]
    bind $f1.dirname <KeyRelease-Return> [list $f1.changeto invoke]
    
}

#-------------------------------------------------------------------------------
# .PROC DefaceSelectMain
# 
# .ARGS
# path start_dir defaults to emtpy string
# .END
#-------------------------------------------------------------------------------
proc DefaceSelectMain { {start_dir ""} } {
    global DICOMStartDir
    global Pressed
    global DICOMPatientIDsNames
    global DICOMFileNameList DICOMFileNameSelected
    global Volume Volumes
    
    set Pressed Cancel
    set pwd [pwd]
    if { $start_dir == "" } {
        set start_dir $Volumes(DICOMStartDir)
    }
    set DICOMStartDir $start_dir
    set DICOMFileNameList {}
    set DICOMFileNameSelected {}
    set Volume(dICOMFileList) {}
    DefaceSelectDir .select
    
    focus .select
    grab .select
    tkwait window .select
    
    if { $Pressed == "OK" } {
        DefaceFindDICOM $DICOMStartDir *
        DefaceListSelect .list $DICOMPatientIDsNames
        
        focus .list
        grab .list
        tkwait window .list

      if { $Pressed == "OK" } {
      }
    }
    cd $pwd
}



#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxFragmentEnter
#   Changes the cursor over the PointTextbox to a cross
#   and stores the old one.
# .ARGS
# windowpath w
# string tag
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxFragmentEnter {w tag} {
    global Volumes

    set f2 $Volumes(ImageTextbox)
    #set Volumes(ImageTextboxOldCursor) [$f2 cget -cursor]
    set Volumes(ImageTextboxOldCursor) [$w cget -cursor]
    #$f2 configure -cursor pencil
    $w configure -cursor hand1
    $f2 tag configure $tag -background #43ce80 -relief raised -borderwidth 1
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxFragmentLeave
#   Changes back the original cursor after leaving
#   the PointTextbox.
# .ARGS
# windowpath w
# string tag
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxFragmentLeave {w tag} {
    global Volumes

    set f2 $Volumes(ImageTextbox)
    #$f2 configure -cursor $Volumes(ImageTextboxOldCursor)
    $w configure -cursor $Volumes(ImageTextboxOldCursor)
    $f2 tag configure $tag -background {} -relief flat
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxSelectAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxSelectAll {} {
    global Volumes DICOMFileNameSelected

    set num [llength $DICOMFileNameSelected]
    set DICOMFileNameSelected {}
    for {set i 0} {$i < $num} {incr i} {
    lappend DICOMFileNameSelected "1"
    }
    DICOMFillFileNameTextbox $Volumes(DICOMFileNameTextbox)    
}

#-------------------------------------------------------------------------------
# .PROC DICOMImageTextboxDeselectAll
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DICOMImageTextboxDeselectAll {} {
    global Volumes DICOMFileNameSelected

    set num [llength $DICOMFileNameSelected]
    set DICOMFileNameSelected {}
    for {set i 0} {$i < $num} {incr i} {
    lappend DICOMFileNameSelected "0"
    }
    DICOMFillFileNameTextbox $Volumes(DICOMFileNameTextbox)    
}


########################################################################
# End of DICOM procedures
########################################################################
