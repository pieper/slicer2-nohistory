#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Download.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:04 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        Download.tcl
# PROCEDURES:  
#   DownloadInit
#   DownloadFile urlAdress outputFile
#   DownloadFile
#   Download_UrlToFile url file chunk
#   Download_UrlToFile
#   Download_ProgressStart
#   Download_Progress token total current
#   Download_Progress
#   Download_ProgressComplete
#   Download_ValidUrl token
#   Download_PrintProtocol maxTabLength token
#   Download_ErrorMsg
#==========================================================================auto=
#=auto==========================================================================
# (c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.
#
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors. 
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for 
# research purposes only, provided that (1) the above copyright notice and 
# the following four paragraphs appear on all copies of this software, and 
# (2) that source code to any modifications to this software be made 
# publicly available under terms no more restrictive than those in this 
# License Agreement. Use of this software constitutes acceptance of these 
# terms and conditions.
# 
# 3D Slicer Software has not been reviewed or approved by the Food and 
# Drug Administration, and is for non-clinical, IRB-approved Research Use 
# Only.  In no event shall data or images generated through the use of 3D 
# Slicer Software be used in the provision of patient care.
# 
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
# ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
# DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
# EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
# OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
# NON-INFRINGEMENT.
# 
# THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
# 
#
#===============================================================================
# Used for downloading files from the internet 
# Example 
# source $env(SLICER_HOME)/Base/tcl/tcl-shared/Download.tcl
# DownloadInit
# DownloadFile http://www.na-mic.org/Wiki/images/6/6b/WestinNAMIC-Dec10-2004.pdf blubber.pdf

#-------------------------------------------------------------------------------
# .PROC DownloadInit
# Init Download procedure 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DownloadInit {} {
  global Gui 
  set Gui(wDownload) ""
  package require http
}


#-------------------------------------------------------------------------------
# .PROC DownloadFile
# Downloads a file from the web. Returns 1 if successfull and otherwise 0 or if file was empty
# .ARGS
# str    urlAdress      http address of the File to download (e.g http://www.blubber.com/blubber.pdf)
# str    outputFile     Location where the file should be downloaded to (e.g. ~/temp/blubber.pdf)
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC DownloadFile
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DownloadFile {urlAdress outputFile} {
    Download_ProgressStart $urlAdress $outputFile 
    set Token [Download_UrlToFile $urlAdress $outputFile] 
    Download_ProgressCompleted $Token

    if {$Token ==""} { return 0 } 
    Download_FinishedDownloading $Token
    return 1
}

#-------------------------------------------------------------------------------
# .PROC Download_UrlToFile
# Only for Experienced users:
# Downloads a file from the web. Returns a token of the completed transactions if successfull. 
# If the transaction was not successfull returns the empty string 
# 
# .ARGS
# str    url            http address of the File to download (e.g http://www.blubber.com/blubber.pdf)
# str    file           Location where the file should be downloaded to (e.g. ~/temp/blubber.pdf)
# int    chunk          Maximum Bytsize to download at once (optional) 
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC Download_UrlToFile
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Download_UrlToFile { url file {chunk 4096} } {
     # 1.) Download File
     if {[catch {set out [open $file w]} errormsg]} {
     Download_ErrorMsg "$errormsg" 
     return ""
     }  
     set token [http::geturl $url -channel $out -progress Download_Progress -blocksize $chunk]
  
     # 2.) Finish Download
     close $out

     # 3.) Handle URL redirects
     upvar #0 $token state
     foreach {name value} $state(meta) {
       if {[regexp -nocase ^location$ $name]} {
         Download_ErrorMsg "Redirect Download to Location:$value"
     http::cleanup $token
         return [Download_UrlToFile [string trim $value] $file $chunk]
       }
     }

     # 4.) Check if URL is valid 
     if {[Download_ValidUrl $token] == 0} {
    Download_ErrorMsg "Address $url is was not valid URL or file was empty!"
    http::cleanup $token 
    return ""
     }

     # 5.) Return Token 
     return $token
}


#-------------------------------------------------------------------------------
# .PROC Download_ProgressStart
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Download_ProgressStart {UrlAdress FileLocation} {
    global Gui
    puts "Start downloading from the web .... " 
    set w .wDownload
    set Gui(wDownload) $w

    if {[winfo exists $Gui(wDownload)]} { destroy  $Gui(wDownload) }

    toplevel $w -class Dialog -bg $Gui(activeWorkspace)
    wm title $w "Download Window"
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW "wm withdraw $w"
    if {$Gui(pc) == "0"} { wm transient $w . }
    # wm withdraw $w
    set f $w

    eval {label $f.lTitle -text "Download from Web" } $Gui(WTA)
    pack $f.lTitle -side top -padx 4 -pady 4   
    eval {label $f.lAddress  -text "Url Adress:    $UrlAdress"    } $Gui(WTA)
    eval {label $f.lLocation -text "File Location: $FileLocation" } $Gui(WTA)
    frame $f.fProgress -bg $Gui(activeWorkspace)
    eval {label $f.lStatus   -text "Status:           Loading" } $Gui(WTA)
    pack $f.lAddress $f.lLocation $f.fProgress $f.lStatus -side top -padx 2 -pady 2 -anchor w  

    eval {button $f.bExit -text "OK" -width 8 -command "destroy $w" -state disabled} $Gui(WBA) 
    pack $f.bExit -side top -padx 2 -pady 2 
 
    eval {label $f.fProgress.lText -text "Completed:    "} $Gui(WTA)
    eval {label $f.fProgress.lPercent -text "  0% of 0 Bytes"} $Gui(WTA)
    pack  $f.fProgress.lText $f.fProgress.lPercent -side left   
}


#-------------------------------------------------------------------------------
# .PROC Download_Progress
# Displays the current download progress -> called insided of Download_UrlToFile
# 
# .ARGS
# str    token          Token of the download process 
# int    total          Number of total bytes to download
# int    current        Current number of bytes downloaded 
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC Download_Progress
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Download_Progress {token total current} {
    upvar #0 $token state
    global Gui
    if {[winfo exists $Gui(wDownload)]} {
      if {$total} {
      $Gui(wDownload).fProgress.lPercent configure -text "[format %3d [expr int(double($current)/double($total)*100)]]% of $total Bytes"
      }
    } else {
      puts "Progress:  $current of $total bytes"    
    }
}

#-------------------------------------------------------------------------------
# .PROC Download_ProgressComplete
# Progress display is shut down 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Download_ProgressCompleted {token} {
    global Gui
    if {[winfo exists $Gui(wDownload)]} {
    if {$token != ""} {$Gui(wDownload).lStatus configure   -text "Status:           Finshed" }
    $Gui(wDownload).bExit configure -state normal 
    }
}

#-------------------------------------------------------------------------------
# .PROC Download_ValidUrl
# Checks if the url was valid or the downloaded file was empty 
# .ARGS
# str    token          Token of the download process 
# .END
#-------------------------------------------------------------------------------
proc Download_ValidUrl {token} {
    upvar #0 $token state
    if {$state(totalsize)} {return 1}
    return 0
}

#-------------------------------------------------------------------------------
# .PROC Download_PrintProtocol
# Prints out all relavent Protocol information from the transaction 
# .ARGS
# int    maxTabLength   Maximum  First Colum Width in table  
# str    token          Token of the download process 
# .END
#-------------------------------------------------------------------------------
proc Download_PrintProtocol {maxTabLength token} {
     upvar #0 $token state
     foreach {name value} $state(meta) {
        puts [format "%-*s %s" $maxTabLength $name: $value]
     }
}

# Cleans up memory after you comppleted down
proc Download_FinishedDownloading {token} {
  puts "... finshed downloading" 
  http::cleanup $token 
}

#-------------------------------------------------------------------------------
# .PROC Download_ErrorMsg
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc Download_ErrorMsg {msg} {
    global Gui 
    if {[winfo exists $Gui(wDownload)]} {$Gui(wDownload).lStatus configure -fg red -text "Status:           $msg" 
    } else { puts "ERROR:Download: $msg" }
} 
