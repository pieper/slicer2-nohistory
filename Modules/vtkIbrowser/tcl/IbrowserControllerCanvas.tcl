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
# FILE:        IbrowserControllerCanvas.tcl
# PROCEDURES:  
#   IbrowserSetInitialPixelsPerUnit
#   IbrowserUpdatePixelsPerUnit
#   IbrowserUnitSpanToPixelSpan
#   IbrowserUnitValToPixelVal
#   IbrowserPixelSpanToUnitSpan
#   IbrowserPixelValToUnitVal
#   IbrowserComputeNumUnitsThatFit
#   IbrowserInitCanvasSizeAndScrollRegion
#   IbrowserUpdateHscrollregion
#   IbrowserUpdateVscrollRegion
#   IbrowserInitCanvasGeom
#   IbrowserMakeVscrollCanvas
#   IbrowserMakeGangedHscrollCanvas
#   IbrowserBindXview
#   IbrowserCanvasSelectText
#   IbrowserCanvasDeselectText
#==========================================================================auto=



#-------------------------------------------------------------------------------
# .PROC IbrowserSetInitialPixelsPerUnit
# Called only when the first interval is created.
# Uses the interval's pixelwidth and unit span
# to return a value.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetInitialPixelsPerUnit { unitmin unitmax } {
    
    #get the default interval width in pixels
    #---------------
    set pixspan $::IbrowserController(Geom,Ival,defaultPixWid)
    
    #compute the span in units
    #---------------
    set unitspan [ expr $unitmax - $unitmin ]
    
    #do the divide and set temporarily
    #---------------
    set ppx [ expr $pixspan / $unitspan ]
    set ::IbrowserController(Geom,Icanvas,pixPerUnitX) $ppx
    set ::IbrowserController(Geom,Ccanvas,pixPerUnitX) $ppx
    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserUpdatePixelsPerUnit
# Called when pixels per unit needs to change
# because of a "zoom in" or "zoom out" op
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdatePixelsPerUnit { unitmin unitmax } {

    #compute how many pixels are in one unit after zooming...
    #right now zooming is not implemented...
    #---------------
}






#-------------------------------------------------------------------------------
# .PROC IbrowserUnitSpanToPixelSpan
#Returns the number of pixels contained
#within the input number of units 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUnitSpanToPixelSpan { ux } {

    #how many pixels is that?
    #---------------
    set ppux $::IbrowserController(Geom,Icanvas,pixPerUnitX)
    set px [ expr $ppux * $ux ]
    return $px
}







#-------------------------------------------------------------------------------
# .PROC IbrowserUnitValToPixelVal
#Returns the pixel value pixels that
#corresponds to the input unit value
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUnitValToPixelVal { ux } {


    #get some info about the canvas geometry
    #---------------
    set ppux $::IbrowserController(Geom,Icanvas,pixPerUnitX)
    set minx $::IbrowserController(Info,Ival,globalIvalUnitSpanMin)
    
    #how many units from intervals' topleft is ux?
    #---------------
    set cnormx [ expr $ux - $minx ]

    #what's that pixel value?
    #---------------
    set px [ expr $ppux * $cnormx ]
    set px [ expr $px + $::IbrowserController(Info,Ival,globalIvalPixXstart) ]
    return $px

}




#-------------------------------------------------------------------------------
# .PROC IbrowserPixelSpanToUnitSpan
# Returns the number of units contained
# within the input number of pixels 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPixelSpanToUnitSpan { px } {

    #how many units is that?
    #---------------
    set ppux $::IbrowserController(Geom,Icanvas,pixPerUnitX)
    set ux [expr $px / $ppux ]
    return $ux
}



#-------------------------------------------------------------------------------
# .PROC IbrowserPixelValToUnitVal
# Returns the unit value pixels that
# corresponds to the input pixel value
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPixelValToUnitVal { px } {
    
    #get some info about the canvas geometry
    #---------------
    set ppux $::IbrowserController(Geom,Icanvas,pixPerUnitX)
    set minx $::IbrowserController(Info,Ival,globalIvalUnitSpanMin)
    
    #how many pixels from interval's topleft is px?
    #---------------
    set cnormx [ expr $px - $::IbrowserController(Info,Ival,globalIvalPixXstart) ]

    #what's that unit value?
    #---------------
    set ux [ expr $cnormx / $ppux ]
    set ux [ expr $::IbrowserController(Info,Ival,globalIvalUnitSpanMin) + $ux ]
    return $ux
}




#-------------------------------------------------------------------------------
# .PROC IbrowserComputeNumUnitsThatFit
# Figures out how many units can be represented
# within an interval,  given current canvas and scrollwid
# dimensions. Used to determine whether scrollregion
# should be increased to accommodate a new larger
# interval.

# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserComputeNumUnitsThatFit { } {

    #find pixel value where interval starts
    #---------------
    set thing1  $::IbrowserController(Info,Ival,globalIvalPixXstart)

    #find pixel width of whole canvas +
    #(leave a buffer of blankspace at right)
    #---------------
    set thing2  [expr $::IbrowserController(Geom,Icanvas,scrollregionH) - \
                     $::IbrowserController(Geom,Icanvas,scrollregionBlankBuf) ]
    
    #and how many pixels wide is the potential
    #room for growing an interval
    #---------------    
    set pixwid [ expr $thing2 - $thing1 ]

    #divide this number of pixels by pixelsPerUnit
    #---------------
    set numunits [ expr $pixwid / $::IbrowserController(Geom,Icanvas,pixPerUnitX) ]

    #and return num units that fit
    #---------------
    return $numunits

}





#-------------------------------------------------------------------------------
# .PROC IbrowserInitCanvasSizeAndScrollRegion
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitCanvasSizeAndScrollRegion { } {
    
    set ::IbrowserController(Geom,Icanvas,scrollregionH) 100
    set ::IbrowserController(Geom,Ccanvas,scrollregionH) 100
    set ::IbrowserController(Geom,Icanvas,scrollregionV) 200

    set ::IbrowserController(Geom,Icanvas,pixWid) 400
    set ::IbrowserController(Geom,Icanvas,pixHit) 100
    set ::IbrowserController(Geom,Ccanvas,pixWid) 400
    set ::IbrowserController(Geom,Ccanvas,pixHit) 50

    $::IbrowserController(Icanvas) config -width $::IbrowserController(Geom,Icanvas,pixWid)
    $::IbrowserController(Icanvas) config -height $::IbrowserController(Geom,Icanvas,pixHit)
    $::IbrowserController(Icanvas) config -scrollregion \
        "0 0 $::IbrowserController(Geom,Icanvas,scrollregionH) $::IbrowserController(Geom,Icanvas,scrollregionV) "
    $::IbrowserController(Ccanvas) config -width $::IbrowserController(Geom,Ccanvas,pixWid)
    $::IbrowserController(Ccanvas) config -height $::IbrowserController(Geom,Ccanvas,pixHit)
}





#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateHscrollregion
# Used to determine whether a the horizontal scrollregion
# should be increased to accommodate a new interval,
# or shrunken to accommodate a smaller global span.
# or one with changing span.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateHscrollregion { } {

    # how many units fit in the existing 
    # space for intervals?
    #---------------
    set n [ IbrowserComputeNumUnitsThatFit ]
    set newspan $::IbrowserController(Info,Ival,globalIvalUnitSpan)
    
    # if we need more space,
    # extend the scrollregion
    #---------------
    if { $n < $newspan } {
        #OK: how many pix do you need?
        #---------------
        set needpix [ IbrowserUnitSpanToPixelSpan $newspan ]
        
        #how much space do you aready have?
        #---------------        
        set havepix [ expr $::IbrowserController(Geom,Icanvas,scrollregionH) - \
                          $::IbrowserController(Info,Ival,globalIvalPixXstart) ]
        set havepix [ expr $havepix - $::IbrowserController(Geom,Icanvas,scrollregionBlankBuf)]

        #what size should scrolled canvas be?
        #---------------
        set addpix [ expr $needpix - $havepix ]
        
        #compute a reasonable scrollregion given the interval span
        #---------------
        set scrH [ expr $::IbrowserController(Geom,Icanvas,scrollregionH) + $addpix ]
        
        #and set.
        #---------------
        if { $scrH > 0 } {
            set ::IbrowserController(Geom,Icanvas,scrollregionH) $scrH
            set ::IbrowserController(Geom,Ccanvas,scrollregionH) $::IbrowserController(Geom,Icanvas,scrollregionH)
            $::IbrowserController(Icanvas) config -scrollregion \
                " 0 0 $scrH $::IbrowserController(Geom,Icanvas,scrollregionV) "
            $::IbrowserController(Ccanvas) config -scrollregion " 0 0 $scrH 0 "            
        }
    } elseif { $n > $newspan } {
        # we don't need all this space, so
        # shrink the scroll region
        #---------------
        #OK: how many pix do you need?
        #---------------
        set needpix [ IbrowserUnitSpanToPixelSpan $newspan ]
        
        #how much space do you aready have?
        #---------------        
        set havepix [ expr $::IbrowserController(Geom,Icanvas,scrollregionH) - \
                          $::IbrowserController(Info,Ival,globalIvalPixXstart) ]
        set havepix [ expr $havepix - $::IbrowserController(Geom,Icanvas,scrollregionBlankBuf)]

        #what size should scrolled canvas be?
        #---------------
        set subpix [ expr $havepix - $needpix ]

        #compute a reasonable scrollregion given the interval span
        #---------------
        set scrH [ expr $::IbrowserController(Geom,Icanvas,scrollregionH) - $subpix ]
        
        #and set.
        #---------------
        if { $scrH > 0 } {
            set ::IbrowserController(Geom,Icanvas,scrollregionH) $scrH
            set ::IbrowserController(Geom,Ccanvas,scrollregionH) $::IbrowserController(Geom,Icanvas,scrollregionH)
            $::IbrowserController(Icanvas) config -scrollregion \
                " 0 0 $scrH $::IbrowserController(Geom,Icanvas,scrollregionV) "
            $::IbrowserController(Ccanvas) config -scrollregion " 0 0 $scrH 0 "            
        }
        
    }

}




#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateVscrollRegion
# If enough intervals have been created that they don't fit
# within the vertical extent of the IbrowserIcanvas, then we need to
# extend the vertical scrollregion of the canvas. This proc
# checks and resets the interval's global yspan and the
# IbrowserIcanvas's scrollregion if necessary.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateVscrollRegion { } {
    
    # see what the yextent of the collection
    # of intervals is:
    #---------------
    set ypixmax 0
 
    # for each interval in the interval list,
    # recompute Ibrowser(id,pixytop).
    # and compute amount of vertical space they require.
    #---------------
    foreach id $::Ibrowser(idList) {
        set tmpmax $::IbrowserController($id,pixytop)
        set namey $::Ibrowser($id,name)
        if { $tmpmax > $ypixmax} {
            set ypixmax $tmpmax
        }
    }

    # compute the new yextent of the
    # whole collection of intervals.
    #---------------
    set num [ expr $::IbrowserController(Geom,Ival,intervalPixHit) + \
                  $::IbrowserController(Geom,Ival,intervalGap)  ]
    set yy [ expr $ypixmax + $num  ]

    # how much space do we currently
    # have to contain them?
    #---------------
    set scr $::IbrowserController(Geom,Icanvas,scrollregionV)
    set hit $::IbrowserController(Geom,Icanvas,pixHit)
    set oldhit [ expr $scr + $hit ]
    
    # will all the interval's fit?
    #---------------
    if { $yy > $oldhit } {
        # extend the IbrowserIcanvas's vertical
        # scroll region to accommodate
        # new intervals. Make enough
        # new room to fig another interval.
        #---------------
        set newscroll [ expr $::IbrowserController(Geom,Icanvas,scrollregionV) + \
                            $::IbrowserController(Geom,Ival,intervalPixHit) + \
                            $::IbrowserController(Geom,Ival,intervalGap) ]
        set ::IbrowserController(Geom,Icanvas,scrollregionV) $newscroll
        $::IbrowserController(Icanvas) config -scrollregion "0 0 $::IbrowserController(Geom,Icanvas,scrollregionH) $yy"
    }

}




#-------------------------------------------------------------------------------
# .PROC IbrowserInitCanvasGeom
# Initializes the metrics of the interval canvas and
# control canvas. Takes: wid hit scrollwid scrollhit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitCanvasGeom { iw ih cw ch sw sh} {
    
    #set canvas pixel width
    #---------------
    set ::IbrowserController(Geom,Icanvas,pixWid) $iw
    set ::IbrowserController(Geom,Icanvas,pixHit) $ih

    #Add iconspan, intervalspan, and rightmargin;
    #compute an initial scrollregion appropriate to fit
    #all the stuff.
    #---------------
    set xx [ expr $::IbrowserController(Geom,Ival,defaultPixWid) + \
                 $::IbrowserController(Geom,Icon,iconTotalXspan) ]
    set scr [ expr $::IbrowserController(Geom,Icanvas,pixWid) - $xx]
    
    #choose some random nice scroll buffer size
    #---------------
    if { $scr >= 50 } {
        set ::IbrowserController(Geom,Icanvas,scrollregionH) $scr
    } else {
        set ::IbrowserController(Geom,Icanvas,scrollregionH) $sw
    }
    set ::IbrowserController(Geom,Icanvas,scrollregionV) $sh
    set ::IbrowserController(Geom,Icanvas,scrollAmount) 0

    # How many pixels should be blank
    # at the end of an interval span?
    #---------------    
    set ::IbrowserController(Geom,Icanvas,scrollregionBlankBuf) 20

    #configure the control canvas to share same values
    #---------------
    set ::IbrowserController(Geom,Ccanvas,pixWid) $cw
    set ::IbrowserController(Geom,Ccanvas,pixHit) $ch
    set ::IbrowserController(Geom,Ccanvas,scrollregionH) $::IbrowserController(Geom,Icanvas,scrollregionH)
    set ::IbrowserController(Geom,Ccanvas,scrollAmount) 0
}




#-------------------------------------------------------------------------------
# .PROC IbrowserMakeVscrollCanvas
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeVscrollCanvas {c c2 args } {

    frame $c
    $c configure -background white
    eval { canvas $c.canvas \
               -highlightbackground #DDDDDD \
               -highlightcolor #DDDDDD \
              -yscrollcommand [list $c.yscroll set ] \
               -xscrollcommand [list  $c2.xscroll set ] } $args 

    set sb $::IbrowserController(Geom,Ival,scrollBuf)
    scrollbar $c.yscroll -orient vertical -width $sb -highlightthickness 0 \
        -borderwidth 0 -elementborderwidth 1 -command [list $c.canvas yview] \
        -background #DDDDDD \
        -activebackground #DDDDDD

    #set ::IbrowserController(ScrollWidth) [ c.yscroll cget -width ]
    grid $c.canvas $c.yscroll -sticky news 
    grid columnconfigure $c 0 -weight 1
    grid rowconfigure $c 0 -weight 1
    return $c.canvas
}





#-------------------------------------------------------------------------------
# .PROC IbrowserMakeGangedHscrollCanvas
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeGangedHscrollCanvas { c c2 args } {
    
    frame $c
    $c configure -background white
    eval { canvas $c.canvas \
               -highlightbackground #DDDDDD \
               -highlightcolor #DDDDDD \
              -xscrollcommand [list $c.xscroll set ] } $args

    set sb $::IbrowserController(Geom,Ival,scrollBuf)

    label $c.lspacer1 -bg white -width 2
    label $c.lspacer2 -bg white -width 2

    scrollbar $c.xscroll -orient horizontal -borderwidth 0 -elementborderwidth 1 -highlightthickness 0 \
      -command [ list IbrowserBindXview [ list $c.canvas $c2.canvas ] ] \
      -background #DDDDDD \
      -activebackground #DDDDDD
    grid $c.canvas $c.lspacer1 -sticky news 
    grid $c.xscroll $c.lspacer2 -sticky ew 

    grid rowconfigure $c 0 -weight 1
    grid columnconfigure $c 0 -weight 1
    return $c.canvas
}




#-------------------------------------------------------------------------------
# .PROC IbrowserBindXview
# This routine binds one horizontal scrollbar to multiple canvases
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserBindXview { lists args } {

    foreach l $lists {
        eval { $l xview } $args
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserCanvasSelectText
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCanvasSelectText {clickid texttag } {

    #--- first toggle the selection of the clicked name (can't change "none")
    #--- Behavior is: clicking once selects the name, clicking twice deselects it.
    #--- now deselect any other name that might have been selected.

    foreach id $::Ibrowser(idList) {
        if { ( $id != $clickid ) && ( $::IbrowserController($id,nametextSelected) ) } {
            set finished [ IbrowserCanvasFinishEdit $id ]
            if { $finished == 0 } {
                return
            }
        }
    }
    if { $::Ibrowser($clickid,name) != "none" } {
        if { $::IbrowserController($clickid,nametextSelected) == 0 } {
            set c $::IbrowserController(Icanvas)
            $c select clear
            #---gives focus to the canvas
            #---then gives focus to the clicked nametext
            focus $c
            $c focus $texttag
            #---selects all the characters in nametext
            $c select from $texttag 0
            $c select to $texttag end
            $c icursor $texttag end
            set ::IbrowserController($clickid,nametextSelected) 1
            set ::IbrowserController($clickid,nametextEditing) 1
        } else {
            set finished [ IbrowserCanvasFinishEdit $clickid ]
            if { $finished == 0 } {
                return
            }
        }
    }
}




 proc IbrowserCanvasFinishEdit { clickid }  {

     set finished 0
     set c $::IbrowserController(Icanvas)
     set newname [ $c itemcget $::IbrowserController($clickid,nameTXTtag) -text ]

     if { $newname == "" } {
         #--- if the specified name is empty,
         #--- then keep this text label selected.
         return $finished
     } elseif { $newname == $::Ibrowser($clickid,name) } {
         #--- no new text has been entered... so leave as is.
         IbrowserCanvasDeselectText 
         set ::IbrowserController($clickid,nametextSelected) 0     
         set ::IbrowserController($clickid,nametextEditing) 0
         set finished 1
         return $finished
     } else {
         #--- ok, *something* new has been typed in to name label;
         #--- check to see if the name is unique.
         set goodname [ IbrowserUniqueNameCheck $newname ]
         if { $goodname } {
             IbrowserRenameInterval $::Ibrowser($clickid,name) $newname
         } else {
             #--- reset the text to original name and prompt for a unique one.
             $c itemconfig $::IbrowserController($clickid,nameTXTtag) -text $::Ibrowser($clickid,name)
             IbrowserSayThis "This interval name is already in use. Please specify again." 1
             DevErrorWindow "Please specify a unique interval name."
         }
     }
     #--- presumably all is well; so finish editing and deselect the interval.
     IbrowserCanvasDeselectText 
     set ::IbrowserController($clickid,nametextSelected) 0     
     set ::IbrowserController($clickid,nametextEditing) 0
     set finished 1
     return $finished
 }





#-------------------------------------------------------------------------------
# .PROC IbrowserCanvasDeselectText
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCanvasDeselectText { } {

    set c $::IbrowserController(Icanvas)
    $c focus ""
    $c select clear
    focus $::IbrowserController(topLevel)

}



 proc IbrowserCanvasDelete { texttag } {

    set c $::IbrowserController(Icanvas)
    #--- if something is selected and has focus...
    #--- (this should only be nametext)
    #--- then delete all the text.
    if { ( [ $c focus ] != {} ) && ( [ $c select item ] != {} ) } {
        $c dchars $texttag 0 end
        $c icursor $texttag 0
     }

 }




 proc IbrowserCanvasTextDrag {c x y} {
     $c select to current @$x,$y
 }





 proc IbrowserCanvasDelChar {c} {
     if {[$c focus] ne {}} {
         $c dchars [$c focus] insert
     }
 }




 proc IbrowserCanvasBackSpace { } {

     set c $::IbrowserController(Icanvas)
     if { [ $c focus ] != {} } {
         set _t  [ $c focus ]
         $c icursor $_t  [ expr { [ $c index $_t insert ] -1} ]
         $c dchars $_t insert 
     }
 }




 proc IbrowserCanvasInsert { char }  {
     set c $::IbrowserController(Icanvas)
     $c insert [$c focus] insert $char
 }




 proc IbrowserCanvasMoveRight { } {
     set c $::IbrowserController(Icanvas)
     $c icursor [$c focus] [expr [$c index current insert]+1]
 }




 proc IbrowserCanvasMoveLeft { } {
     set c $::IbrowserController(Icanvas)
     $c icursor [$c focus] [expr [$c index current insert]-1]
 }

