#=auto==========================================================================
# (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
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
# FILE:        IbrowserControllerGUIbase.tcl
# PROCEDURES:  
#   IbrowserSetUIfonts
#   IbrowserSetUIcolors
#   IbrowserMakeMessagePanel
#   IbrowserSayThis
#   IbrowserPrintProgressFeedback
#   IbrowserEndProgressFeedback
#   IbrowserCreatePopup
#   IbrowserRaisePopup
#   IbrowserShowPopup
#==========================================================================auto=
proc IbrowserSetUIsize { } {
    
    if { [winfo screenwidth .] < 805 || [winfo screenheight .] < 605 } {
        # use smaller icons and intervals or they'll be giant on the screen
        set ::IbrowserController(UI,Small) 1
        set ::IbrowserController(UI,Big) 0

    } elseif {[winfo screenwidth .] > 3005 || [winfo screenheight .] < 2005} {
        # use bigger icons and intervals or they'll be microscopic on the screen
        set ::IbrowserController(UI,Big) 1
        set ::IbrowserController(UI,Small) 0

    } else {
        # medium sized UI; where we mostly expect to be.
        set ::IbrowserController(UI,Small) 0
        set ::IbrowserController(UI,Big) 0
    }
    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserSetUIfonts
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetUIfonts { } {
    
    #option add "*font" "-Adobe-Helvetica-Bold-R-Normal-*-12-*-*-*-*-*-*-*"
    #option add "*font" "-Adobe-Helvetica-Bold-R-Normal-*-10-*-*-*-*-*-*-*"
    #option add "*font" "-Adobe-Helvetica-Bold-R-Normal-*-8-*-*-*-*-*-*-*"
    set ::IbrowserController(UI,Bigfont) "-Adobe-Helvetica-Bold-R-Normal-*-12-*-*-*-*-*-*-*"
    set ::IbrowserController(UI,Medfont) "-Adobe-Helvetica-Bold-R-Normal-*-10-*-*-*-*-*-*-*"
    set ::IbrowserController(UI,Smallfont) "-Adobe-Helvetica-Bold-R-Normal-*-8-*-*-*-*-*-*-*"        
}




#-------------------------------------------------------------------------------
# .PROC IbrowserSetUIcolors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetUIcolors { } {

    set ::IbrowserController(Colors,interval_canvas_color) #FFFFFF
    set ::IbrowserController(Colors,index_canvas_color) #FFFFFF
    set ::IbrowserController(Colors,background_color) #FFFFFF
    set ::IbrowserController(Colors,lolite) #AAAAAA
    set ::IbrowserController(Colors,hilite) #000000
    set ::IbrowserController(Colors,text_default) #000000
    set ::IbrowserController(Colors,menu_default) #000000
    set ::IbrowserController(Colors,menu_hilite) #114488
    set ::IbrowserController(Colors,error_color) #BA2020
    set ::IbrowserController(Colors,indexMarker) #BA2020
    set ::IbrowserController(Colors,activeInterval) #BA2020
    set ::IbrowserController(Colors,indexRule) #888888
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeMessagePanel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeMessagePanel { f args } {
    
    eval { text $f.text -wrap word -bg $::IbrowserController(Colors,interval_canvas_color) \
               -relief groove -font $::IbrowserController(UI,Medfont) \
               -yscrollcommand [ list $f.yscroll set ] } $args
    
    scrollbar $f.yscroll -orient vertical -borderwidth 1 -highlightthickness 0 \
            -command [list $f.text yview] \
            -background #DDDDDD \
            -activebackground #DDDDDD            
    grid $f.text $f.yscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1

    $f.text tag configure ::IbrowserController(Tags,Prompt) -foreground $::IbrowserController(Colors,menu_default)
    $f.text tag configure ::IbrowserController(Tags,Message) -foreground $::IbrowserController(Colors,menu_hilite)
    $f.text tag configure ::IbrowserController(Tags,Error) -foreground $::IbrowserController(Colors,error_color)

    return $f.text

}




#-------------------------------------------------------------------------------
# .PROC IbrowserSayThis
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSayThis { thisText isError } {

    $::IbrowserController(UI,SaySo) insert end "Interval Browser>> " {::IbrowserController(Tags,Prompt)}
    if { $isError } {
        $::IbrowserController(UI,SaySo) insert end "$thisText \n\n" {::IbrowserController(Tags,Error)}
    } else {
        $::IbrowserController(UI,SaySo) insert end "$thisText \n\n" {::IbrowserController(Tags,Message)}
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserPrintProgressFeedback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPrintProgressFeedback {  } {
    puts -nonewline "."
}

#-------------------------------------------------------------------------------
# .PROC IbrowserEndProgressFeedback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserEndProgressFeedback { } {
    puts ""
}

#-------------------------------------------------------------------------------
# .PROC IbrowserCreatePopup
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreatePopup { w title x y } {

    toplevel $w -class Dialog -background #FFFFFF
    wm title $w $title
    wm iconname $w Dialog
    wm geometry $w +$x+$y
    focus $w
}


#-------------------------------------------------------------------------------
# .PROC IbrowserRaisePopup
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRaisePopup { w } {

    if {[winfo exists $w] != 0} {
        raise $w
        focus $w
        wm deiconify $w
        return 1
    }
    return 0
}


#-------------------------------------------------------------------------------
# .PROC IbrowserShowPopup
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserShowPopup { w x y } {

    wm deiconify $w
    update idletasks
    set wWin [winfo width  $w]
    set hWin [winfo height $w]
    set wScr [winfo screenwidth  .]
    set hScr [winfo screenheight .]
    
    set xErr [expr $wScr - 30 - ($x + $wWin)]
    if {$xErr < 0} {
        set x [expr $x + $xErr]
    }
    set yErr [expr $hScr - 30 - ($y + $hWin)]
    if {$yErr < 0} {
        set y [expr $y + $yErr]
    }
    
    raise $w
    wm geometry $w +$x+$y
}



