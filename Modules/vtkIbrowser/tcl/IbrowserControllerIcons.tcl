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
# FILE:        IbrowserControllerIcons.tcl
# PROCEDURES:  
#   IbrowserSetupIcons
#   IbrowserInitIconImages
#   IbrowserInitIconInfo
#   IbrowserIncrementIconCount
#   IbrowserDecrementIconCount
#   IbrowserInitIconGeom
#   IbrowserMoveIcons
#   IbrowserDeleteIntervalIcons
#   IbrowserCreateIcons
#   IbrowserMakeNameIcon
#   IbrowserMakeOrderIcon
#   IbrowserMakeVisibilityIcon
#   IbrowserMakeCopyIcon
#   IbrowserToggleHoldIcon
#   IbrowserToggleVisibilityIcon
#   IbrowserMakeHoldIcon
#   IbrowserMakeDeleteIcon
#   IbrowserMakeFGIcon
#   IbrowserMakeBGIcon
#   IbrowserDeselectFGIcon
#   IbrowserGangFGandBGVisibility
#   IbrowserSelectFGIcon
#   IbrowserLeaveFGIcon
#   IbrowserDeselectBGIcon
#   IbrowserSelectBGIcon
#   IbrowseLeaveBGIcon
#   IbrowserCopyIntervalPopUp
#   IbrowserDeleteIntervalPopUp
#   IbrowserOrderPopUp
#   IbrowserSetupNewNames
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC IbrowserSetupIcons
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetupIcons { } {
    IbrowserInitIconImages
    IbrowserInitIconInfo
    IbrowserInitIconGeom
}




#-------------------------------------------------------------------------------
# .PROC IbrowserInitIconImages
# Creates all image icons and stuffs them into an array
# indexed by a name that describes what the icon shows.
#
# IF YOU WANT TO ADD A NEW ICON FOR EACH INTERVAL:
#
# You will have to touch two procs and add a new one in this file.
# FIRST: in proc IbrowserInitIconImages{}, duplicate the infrastructure
# of an existing icon to support your new icon, AND appropriately
# increment ::IbrowserController(Info,Icon,numIconsPerInterval)
# SECOND: add similar infrastructure in proc IbrowserCreateIcons{}
# which will need to call a new proc called MakeXXXXXIcon{}; and
# THIRD: define a new proc called MakeXXXXXIcon{} similar to an
# existing proc such as MakeCopyIcon{}.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitIconImages { } {
    global PACKAGE_DIR_VTKIbrowser
    
    # Current icons are:
    # intervalname, layerorder, visibility, opacity, renderstyle, compositestyle

    #--- This variable contains the module path plus some stuff
    #--- trim off the extra stuff, and add on the path to tcl files.
    set tmpstr $PACKAGE_DIR_VTKIbrowser
    set tmpstr [string trimright $tmpstr "/vtkIbrowser" ]
    set tmpstr [string trimright $tmpstr "/Tcl" ]
    set tmpstr [string trimright $tmpstr "Wrapping" ]
    set modulePath [format "%s%s" $tmpstr "tcl/"]

    #--- If more icons are added to each interval, please ajust this number.
    #--- The number should be the same for all intervals.
    set ::IbrowserController(Info,Icon,numIconsPerInterval) 8
    set ::IbrowserController(iconImageList) ""

    #--- If we should use small images for the interface...
    #--- These now just use the same 20x20 gifs that IbrowserController(UI,Big) 
    #--- uses, but will someday use some 30x30 (or some appropriate res)
    #--- versions of the images that are not yet created.
    if { $::IbrowserController(UI,Small) } {
        #--- visible
        set ::IbrowserController(Images,Icon,visIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/visible.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,visIcon)

        #--- not visible
        set ::IbrowserController(Images,Icon,invisIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/invisible.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,invisIcon)

        #--- order
        set ::IbrowserController(Images,Icon,orderIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/under-order2.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,orderIcon)
        
        #--- name
        set ::IbrowserController(Images,Icon,nameIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/under-name2.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,nameIcon)
        
        #--- hold
        set ::IbrowserController(Images,Icon,holdIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/hold.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,holdIcon)
        
        #--- don't hold
        set ::IbrowserController(Images,Icon,noholdIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/nohold.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,noholdIcon)
        
        #--- foreground
        set ::IbrowserController(Images,Icon,FGIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/FG.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,FGIcon)
        
        #--- background
        set ::IbrowserController(Images,Icon,BGIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/BG.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,BGIcon)
        
        #--- delete
        set ::IbrowserController(Images,Icon,deleteIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/delete.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,deleteIcon)        

        #--- copy
        set ::IbrowserController(Images,Icon,copyIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/copy.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,copyIcon)
        
        #--- If $::IbrowserController(UI,Big) 
    } else {
        #--- visible
        set ::IbrowserController(Images,Icon,visIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/visible.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,visIcon)

        #--- not visible
        set ::IbrowserController(Images,Icon,invisIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/invisible.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,invisIcon)

        #--- order
        set ::IbrowserController(Images,Icon,orderIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/under-order2.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,orderIcon)
        
        #--- name
        set ::IbrowserController(Images,Icon,nameIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/under-name2.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,nameIcon)
        
        #--- hold
        set ::IbrowserController(Images,Icon,holdIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/hold.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,holdIcon)
        
        #--- don't hold
        set ::IbrowserController(Images,Icon,noholdIcon) \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/nohold.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,noholdIcon)
        
        #--- foreground
        set ::IbrowserController(Images,Icon,FGIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/FG.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,FGIcon)
        
        #--- background
        set ::IbrowserController(Images,Icon,BGIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/BG.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,BGIcon)
        
        #--- delete
        set ::IbrowserController(Images,Icon,deleteIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/delete.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,deleteIcon)        

        #--- copy
        set ::IbrowserController(Images,Icon,copyIcon)  \
            [image create photo \
                 -file ${modulePath}iconPix/20x20/gifs/canvas/copy.gif]
        lappend ::IbrowserController(iconImageList) $::IbrowserController(Images,Icon,copyIcon)
    }

    #--- and create infrastructure for tagging each new interval's icons.
    #--- these lists are used for creating, moving, configuring, deleting icons.
    set ::IbrowserController(iconImageTagList) ""
    lappend ::IbrowserController(iconImageTagList) opaqIconTag
    lappend ::IbrowserController(iconImageTagList) nameIconTag
    lappend ::IbrowserController(iconImageTagList) orderIconTag
    lappend ::IbrowserController(iconImageTagList) visIconTag
    lappend ::IbrowserController(iconImageTagList) invisIconTag
    lappend ::IbrowserController(iconImageTagList) FGIconTag
    lappend ::IbrowserController(iconImageTagList) BGIconTag
    lappend ::IbrowserController(iconImageTagList) holdIconTag
    lappend ::IbrowserController(iconImageTagList) noholdIconTag
    lappend ::IbrowserController(iconImageTagList) deleteIconTag
    lappend ::IbrowserController(iconImageTagList) copyIconTag

    set ::IbrowserController(iconTextTagList) ""
    lappend ::IbrowserController(iconTextTagList) nameTXTtag
    lappend ::IbrowserController(iconTextTagList) orderTXTtag

    set ::IbrowserController(iconHilightTagList) ""
    lappend ::IbrowserController(iconHilightTagList) opaqIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) nameIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) orderIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) visIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) FGIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) BGIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) holdIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) noholdIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) deleteIconHILOtag
    lappend ::IbrowserController(iconHilightTagList) copyIconHILOtag

}




#-------------------------------------------------------------------------------
# .PROC IbrowserInitIconInfo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitIconInfo { } {
    

    set ::IbrowserController(Info,Icon,iconCount) 0

    # These are different states that various
    # icons can have; depending on its state,
    # the icon may be represented with a different
    # image. If you add a new icon and it has
    # different visual states, include them here,
    # and in intervals.tcl where their string
    # values are defined.
    #---------------    
    set ::IbrowserController(Info,Icon,isVisible) $::IbrowserController(Info,Ival,isVisible)
    set ::IbrowserController(Info,Icon,isInvisible) $::IbrowserController(Info,Ival,isInvisible)
    set ::IbrowserController(Info,Icon,hold) $::IbrowserController(Info,Ival,hold)
}




#-------------------------------------------------------------------------------
# .PROC IbrowserIncrementIconCount
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserIncrementIconCount { } {

    set ::IbrowserController(Info,Icon,iconCount) \
        [expr $::IbrowserController(Info,Icon,iconCount) + 1 ]
}




#-------------------------------------------------------------------------------
# .PROC IbrowserDecrementIconCount
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDecrementIconCount { } {

    set ::IbrowserController(Info,Icon,iconCount) \
        [expr $::IbrowserController(Info,Icon,iconCount) - 1 ]
}





#-------------------------------------------------------------------------------
# .PROC IbrowserInitIconGeom
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitIconGeom { } {
    
    # There are currently $::IbrowserController(Info,Icon,numIconsPerInterval) icons shown
    # leftward of the interval in the UI. UI element render position and
    # inter-element spacings are based on this number; if more icons are
    # added, make sure to change the number. Note: all icons are the
    # same size but for the intervalname icon, which is assigned the width
    # of all other icons combined in the UIsetup proc. The current icons are:
    # intervalname, layerorder, visibility, opacity, renderstyle, compositestyle
    # Here, the geometry is specified in actual pixel values.
    #---------------
    if { $::IbrowserController(UI,Small) } {
        set ::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Ival,intervalXbuf)
        set ::IbrowserController(Geom,Icon,iconYstart) $::IbrowserController(Geom,Ival,intervalYbuf)
        # both x and y:
        set ::IbrowserController(Geom,Icon,iconStart) $::IbrowserController(Geom,Ival,intervalXbuf)

        set ::IbrowserController(Geom,Icon,iconWid) 20
        # Name icon is six times the width of small icons
        #---------------
        set ::IbrowserController(Geom,Icon,nameIconMultiple) 6

        # Name icon is six times the width of small icons
        set jigger [ expr $::IbrowserController(Geom,Icon,iconWid) * \
                         $::IbrowserController(Geom,Icon,nameIconMultiple) ]
        set ::IbrowserController(Geom,Icon,nameIconWid) $jigger 
        set ::IbrowserController(Geom,Icon,iconHit) 20
        set ::IbrowserController(Geom,Icon,iconGap) 2

    } elseif { $::IbrowserController(UI,Big) } {
        set ::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Ival,intervalXbuf)
        set ::IbrowserController(Geom,Icon,iconYstart) $::IbrowserController(Geom,Ival,intervalYbuf)
        # both x and y:
        set ::IbrowserController(Geom,Icon,iconStart) $::IbrowserController(Geom,Ival,intervalXbuf)
        
        set ::IbrowserController(Geom,Icon,iconWid) 20
        # Name icon is six times the width of small icons
        #---------------
        set ::IbrowserController(Geom,Icon,nameIconMultiple) 6

        # this maneuver should make the name icon
        # twice the size as all small icons combined.
        set jigger [ expr $::IbrowserController(Geom,Icon,iconWid) \
                         * $::IbrowserController(Geom,Icon,nameIconMultiple) ]
        set ::IbrowserController(Geom,Icon,nameIconWid) $jigger 
        set ::IbrowserController(Geom,Icon,iconHit) 20
        set ::IbrowserController(Geom,Icon,iconGap) 2

    } else {
        set ::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Ival,intervalXbuf)
        set ::IbrowserController(Geom,Icon,iconYstart) $::IbrowserController(Geom,Ival,intervalYbuf)
        # both x and y:
        set ::IbrowserController(Geom,Icon,iconStart) $::IbrowserController(Geom,Ival,intervalXbuf)

        set ::IbrowserController(Geom,Icon,iconWid) 20
        # Name icon is six times the width of small icons
        #---------------
        set ::IbrowserController(Geom,Icon,nameIconMultiple) 6

        # Name icon is six times the width of small icons
        set jigger [ expr $::IbrowserController(Geom,Icon,iconWid) \
                         * $::IbrowserController(Geom,Icon,nameIconMultiple) ]
        set ::IbrowserController(Geom,Icon,nameIconWid)  $jigger 
        set ::IbrowserController(Geom,Icon,iconHit) 20
        set ::IbrowserController(Geom,Icon,iconGap) 2
    }
    set xx [ expr $::IbrowserController(Geom,Icon,iconWid) + $::IbrowserController(Geom,Icon,iconGap) ]
    set xx [ expr $xx * $::IbrowserController(Info,Icon,numIconsPerInterval) ]
    set xx [ expr $xx + $::IbrowserController(Geom,Icon,iconXstart) ]
    set ::IbrowserController(Geom,Icon,iconTotalXspan) $xx
    set ::IbrowserController(Geom,Ival,intervalXstart) $xx

}


#-------------------------------------------------------------------------------
# .PROC IbrowserMoveIcons
# This routine gets called when an intervals' order has changed;
# and the vertical positions of its icons within the canvas must be
# updated.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMoveIcons { Iname oldy newy } {
    
    #move icons by yy.
    #---------------
    set yy [ expr $newy - $oldy ]

    #get id from name
    set id $::Ibrowser($Iname,intervalID)
    
    #--- delete icon image tags
    foreach imgTag $::IbrowserController(iconImageTagList) {
        $::IbrowserController(Icanvas) move $::IbrowserController($id,$imgTag) 0.0 $yy
    }
    #--- delete icon text tags
    foreach txtTag $::IbrowserController(iconTextTagList) {
          $::IbrowserController(Icanvas) move $::IbrowserController($id,$txtTag) 0.0 $yy
    }
    #--- delete icon highlight tags
    foreach hiloTag $::IbrowserController(iconHilightTagList) {
        $::IbrowserController(Icanvas) move $::IbrowserController($id,$hiloTag) 0.0 $yy
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteIntervalIcons
# Deletes icons after an interval has been deleted.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteIntervalIcons { ivalName } {

    #--- get id from name
    set id $::Ibrowser($ivalName,intervalID)

    #--- delete icon image tags
    foreach imgTag $::IbrowserController(iconImageTagList) {
        $::IbrowserController(Icanvas) delete $::IbrowserController($id,$imgTag) 
    }
    #--- delete icon text tags
    foreach txtTag $::IbrowserController(iconTextTagList) {
          $::IbrowserController(Icanvas) delete $::IbrowserController($id,$txtTag) 
    }
    #--- delete icon highlight tags
    foreach hiloTag $::IbrowserController(iconHilightTagList) {
        $::IbrowserController(Icanvas) delete $::IbrowserController($id,$hiloTag) 
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserCreateIcons
# This routine is called when a new interval is created.
# It creates the icons that go with each interval.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateIcons { ivalName } {

    #--- get id from name
    set id $::Ibrowser($ivalName,intervalID)

    # make an interval's icons.
    #name
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconStart)
    set y2 [ expr $::IbrowserController(Geom,Icon,iconYstart) \
                 + $::IbrowserController(Geom,Icon,iconHit) ]
    set x2 [expr $::IbrowserController(Geom,Icon,iconXstart) \
                + $::IbrowserController(Geom,Icon,nameIconWid) ]
    IbrowserMakeNameIcon $id $::IbrowserController(Geom,Icon,iconXstart) \
        $::IbrowserController(Geom,Icon,iconYstart) \
        $x2 $y2 $::IbrowserController(UI,Medfont)

    #order
    #---------------
    set dx [ expr $::IbrowserController(Geom,Icon,iconGap) + $::IbrowserController(Geom,Icon,iconWid) ]
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $x2 ]
    IbrowserMakeOrderIcon  $id $::Ibrowser($id,orderStatus) \
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] \
        $y2 $::IbrowserController(UI,Medfont)

     #visibility
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $dx ]    
    IbrowserMakeVisibilityIcon  $id $::IbrowserController(Info,Icon,isVisible) \
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] $y2

    #copy
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $dx ]    
    IbrowserMakeCopyIcon  $id \
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] $y2

    #delete
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $dx ]    
    IbrowserMakeDeleteIcon  $id \
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] $y2
    

    #hold
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $dx ]    
    IbrowserMakeHoldIcon  $id $::IbrowserController(Info,Icon,hold)\
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] $y2

    #FG
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $dx ]    
    IbrowserMakeFGIcon  $id \
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] $y2

    #BG
    #---------------
    set ::IbrowserController(Geom,Icon,iconXstart) [expr $::IbrowserController(Geom,Icon,iconXstart) + $dx ]    
    IbrowserMakeBGIcon  $id \
        $::IbrowserController(Geom,Icon,iconXstart) $::IbrowserController(Geom,Icon,iconYstart) \
        [expr $::IbrowserController(Geom,Icon,iconXstart) + $::IbrowserController(Geom,Icon,iconWid)] $y2
    
    
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeNameIcon
# This routine is called each time a new interval is
# created. It creates a name icon indicating the interval's
# given or default name, and returns the icon's ID value.
# FOR NOW, ID these and capture clicks with tags???????
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeNameIcon { id x1 y1 x2 y2 fnt } {
    
    # Create background image for interval's name
    # Create text for name, and rectangle around it,
    # drawn in LO or HI color as mouse rolls over
    # or selects.
    #---------------

    set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                -image $::IbrowserController(Images,Icon,nameIcon) \
                -anchor nw -tag "$::IbrowserController($id,nameIconTag)" ]
    set namejigger 2
    set xx [ expr $x1 + $namejigger ]
    set yy [ expr $y2 - $y1 ]
    set yy [ expr $yy / 4]
    set yy [ expr $yy + $y1 ]
    $::IbrowserController(Icanvas) create text  $xx  $yy  -anchor nw \
        -text $::Ibrowser($id,name) -font $fnt -tag "$::IbrowserController($id,nameTXTtag)"
    $::IbrowserController(Icanvas) create rect $x1 $y1 \
        [ expr $x1 + $::IbrowserController(Geom,Icon,nameIconWid) -1 ]  \
        [ expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] \
        -tags "iconbox" -outline $::IbrowserController(Colors,lolite) \
        -tag "$::IbrowserController($id,nameIconHILOtag)"

    # rectangle hilights during mouse-over of text
    #---------------
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Enter> \
        "%W itemconfig $::IbrowserController($id,nameIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Leave> \
        "%W itemconfig $::IbrowserController($id,nameIconHILOtag) -outline $::IbrowserController(Colors,lolite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Button-1> \
        "IbrowserCanvasSelectText $id $::IbrowserController($id,nameTXTtag)"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Delete> \
        "IbrowserCanvasDelete $::IbrowserController($id,nameTXTtag)"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <BackSpace> \
        "IbrowserCanvasBackSpace"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Return> \
        "IbrowserCanvasFinishEdit $id"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Any-Key> \
        "IbrowserCanvasInsert %A"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Key-Right> \
        "IbrowserCanvasMoveRight"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Key-Left> \
        "IbrowserCanvasMoveLeft"

#    $::IbrowserController(Icanvas) config -cursor xterm

    # rectangle hilights during mouse-over of rect too
    #---------------
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameIconTag) <Enter> \
        "%W itemconfig $::IbrowserController($id,nameIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameIconTag) <Leave> \
        "%W itemconfig $::IbrowserController($id,nameIconHILOtag) -outline $::IbrowserController(Colors,lolite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameIconTag) <Button-1> \
        "IbrowserCanvasSelectText $id $::IbrowserController($id,nameTXTtag)"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Delete> \
        "IbrowserCanvasDelete $::IbrowserController($id,nameTXTtag)"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <BackSpace> \
        "IbrowserCanvasBackSpace"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Return> \
        "IbrowserCanvasFinishEdit $id"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Any-Key> \
        "IbrowserCanvasInsert %A"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Key-Right> \
        "IbrowserCanvasMoveRight"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,nameTXTtag) <Key-Left> \
        "IbrowserCanvasMoveLeft"

    IbrowserIncrementIconCount
             
}




#-------------------------------------------------------------------------------
# .PROC IbrowserMakeOrderIcon
# This routine is called each time a new interval is
# created. It creates a layerOrder icon indicating the interval's
# default layer number, and returns the icon's ID value.
# FOR NOW, ID these and capture clicks with tags???????
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeOrderIcon { id order x1 y1 x2 y2 fnt} {

    set name $::Ibrowser($id,name)
    
    #---------------
    set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                -image $::IbrowserController(Images,Icon,orderIcon) \
                -anchor nw -tag "$::IbrowserController($id,orderIconTag)" ]
    set xx [ expr $x2 - $x1 ]
    set xx [ expr $xx / 2 ]
    set yy [ expr $y2 - $y1 ]
    set yy [ expr $yy / 4 ]

    #---------------
    set txt [ format "%d" $order]
    $::IbrowserController(Icanvas) create text  [expr $x1 +  $xx ]  [expr $y1 + $yy ] \
        -anchor n -text $txt -font $fnt -tag "$::IbrowserController($id,orderTXTtag)"
    $::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
        [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) \
        -tag "$::IbrowserController($id,orderIconHILOtag)"

    #---------------
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,orderIconTag) <Enter> \
        "%W itemconfig $::IbrowserController($id,orderIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,orderIconTag) <Leave> \
        "%W itemconfig $::IbrowserController($id,orderIconHILOtag) -outline $::IbrowserController(Colors,lolite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,orderIconTag) <Button-1> \
        " IbrowserOrderPopUp orderpopup $id $::IbrowserController(popupX) $::IbrowserController(popupY)"
    
    #---------------
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,orderTXTtag) <Enter> \
        "%W itemconfig $::IbrowserController($id,orderIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,orderTXTtag) <Leave> \
        "%W itemconfig $::IbrowserController($id,orderIconHILOtag) -outline $::IbrowserController(Colors,lolite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,orderTXTtag) <Button-1> \
        " IbrowserOrderPopUp orderpopup $id $::IbrowserController(popupX) $::IbrowserController(popupY)"
    
    IbrowserIncrementIconCount
}






#-------------------------------------------------------------------------------
# .PROC IbrowserMakeVisibilityIcon
# This routine is called each time a new interval is
# created. It creates a visibility icon indicating the interval's
# default state=visible, and returns the icon's ID value.
# If there's a bogus transparency setting, then return 0.
# FOR NOW, ID these and capture clicks with tags???????
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeVisibilityIcon { id state x1 y1 x2 y2 } {
    
    
    if { $state == $::IbrowserController(Info,Icon,isVisible) } {
        set q [ $::IbrowserController(Icanvas) create image $x1 $y1  \
                    -image $::IbrowserController(Images,Icon,visIcon) \
                    -anchor nw -tag "$::IbrowserController($id,visIconTag)" ]

        #hilite rect on mouseover
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,visIconTag)  <Enter> \
            "%W itemconfig $::IbrowserController($id,visIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,visIconTag)  <Leave> \
            "%W itemconfig $::IbrowserController($id,visIconHILOtag) -outline $::IbrowserController(Colors,lolite) "

        #toggle image on rightclick
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,visIconTag) <Button-1> \
            "IbrowserToggleVisibilityIcon $id"

        #post help on leftclick
        #---------------
        
    } elseif { $state ==  $::IbrowserController(Info,Icon,isInvisible) } {
        set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                    -image $::IbrowserController(Images,Icon,invisIcon) \
                    -anchor nw -tag "$::IbrowserController($id,invisIconTag)" ]
        
        #hilite rect on mouseover
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,invisIconTag) <Enter> \
            "%W itemconfig $::IbrowserController($id,visIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,invisIconTag) <Leave> \
            "%W itemconfig $::IbrowserController($id,visIconHILOtag) -outline $::IbrowserController(Colors,lolite) "

        #toggle image on rightclick
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,invisIconTag) <Button-1> \
            "IbrowserToggleVisibilityIcon $id"

        #post help on leftclick
        #---------------
    }
    
    # this is the hilight around the icon that lights up, and goes down
        #---------------
    eval "$::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
                [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) -tag $::IbrowserController($id,visIconHILOtag)"

    IbrowserIncrementIconCount

}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeCopyIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeCopyIcon { id x1 y1 x2 y2 } {

    #--- when user clicks an interval's copy icon, they are prompted for
    #--- the name of the new interval they want to contain a copy of
    #--- the selected interval's contents.
    set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                -image $::IbrowserController(Images,Icon,copyIcon) \
                -anchor nw -tag "$::IbrowserController($id,copyIconTag)" ]
    $::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
        [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) \
        -tag "$::IbrowserController($id,copyIconHILOtag)"

    $::IbrowserController(Icanvas) bind $::IbrowserController($id,copyIconTag) <Enter> \
        "%W itemconfig $::IbrowserController($id,copyIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,copyIconTag) <Leave> \
        "%W itemconfig $::IbrowserController($id,copyIconHILOtag) -outline $::IbrowserController(Colors,lolite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,copyIconTag) <Button-1> \
        "IbrowserCopyIntervalPopUp copypopup $id $::IbrowserController(popupX) $::IbrowserController(popupY)"
    
    IbrowserIncrementIconCount



}

#-------------------------------------------------------------------------------
# .PROC IbrowserToggleHoldIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserToggleHoldIcon { win  id } {

    if { $::Ibrowser($id,name) != "none" } {
        if { $::Ibrowser($id,holdStatus) == $::IbrowserController(Info,Ival,hold) } {
            set thing [$win get current ]
            set thing [ IbrowserNameFromCurrent [$win get current] ]
            $win itemconfig $thing -image $::IbrowserController(Images,Icon,noholdIcon)
            set ::Ibrowser($id,holdStatus) $::IbrowserController(Info,Ival,nohold)
        } else {
            set thing [$win get current ]
            set thing [ IbrowserNameFromCurrent [$win get current] ]
            $win itemconfig  current -image $::IbrowserController(Images,Icon,holdIcon)
            set ::Ibrowser($id,holdStatus) $::IbrowserController(Info,Ival,hold)
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserToggleVisibilityIcon
# This routine is bound to the visibilityIcon so that
# the visibility status of an interval toggles when
# the icon is clicked. Visibile/Invisible. Nowthen.
# Foreground and Background intervals have their
# visibility ganged together. So, if the visibility is
# changed in either the FG or the BG interval, the
# same visibility state is applied to the ganged interval
# as well.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserToggleVisibilityIcon { id } {

    #--- get id from name
    
    set name $::Ibrowser($id,name)

    set win $::IbrowserController(Icanvas)
    
    #--- If the interval is currently visible,
    #--- set its status to invisible and changs the icon state.
    if { $::Ibrowser($id,visStatus) == $::IbrowserController(Info,Ival,isVisible) } {
        set thing "$::IbrowserController($id,visIconTag)"
        $win itemconfig  $thing -image $::IbrowserController(Images,Icon,invisIcon)
        set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isInvisible)

        if {$id == $::Ibrowser(FGInterval) } {
            #--- If the interval is the foreground interval,
            #--- must update the visibility status of the
            #--- background interval to match.
            set bgID $::Ibrowser(BGInterval)
            if { $bgID != $::Ibrowser(NoInterval) } {
                set otherthing "$::IbrowserController($bgID,visIconTag)"
                $win itemconfig $otherthing -image $::IbrowserController(Images,Icon,invisIcon)
                set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isInvisible)
            }
            #--- Then, update the MainViewer
            MainSlicesSetVisibilityAll 0
            RenderAll
        
        } elseif { $id == $::Ibrowser(BGInterval) } {
            #--- If the interval is the background interval,
            #--- must update the visibility status of the
            #--- foreground interval to match.
            set fgID $::Ibrowser(FGInterval)
            if { $fgID != $::Ibrowser(NoInterval) } {
                set otherthing "$::IbrowserController($fgID,visIconTag)"
                $win itemconfig $otherthing -image $::IbrowserController(Images,Icon,invisIcon)
                set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isInvisible)
            }            
            #--- Then, update the MainViewer
            MainSlicesSetVisibilityAll 0
            RenderAll
        }
        
    } else {
        #--- If the interval is currently invisible,
        #--- set its status to visible and changes the icon state.
        set thing "$::IbrowserController($id,visIconTag)"
        $win itemconfig  $thing -image $::IbrowserController(Images,Icon,visIcon)
        set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isVisible)

        if {$id == $::Ibrowser(FGInterval) } {
            #--- If the interval is the foreground interval,
            #--- must update the visibility status of the
            #--- background interval to match.
            #--- If the interval is the foreground interval,
            #--- must update the visibility status of the
            #--- background interval to match.
            set bgID $::Ibrowser(BGInterval)
            if { $bgID != $::Ibrowser(NoInterval) } {
                set otherthing "$::IbrowserController($bgID,visIconTag)"
                $win itemconfig $otherthing -image $::IbrowserController(Images,Icon,visIcon)
                set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isVisible)
            }

            #--- Then, update the MainViewer
            MainSlicesSetVisibilityAll 1
            RenderAll
            
        } elseif { $id == $::Ibrowser(BGInterval) } {
            #--- If the interval is the background interval,
            #--- must update the visibility status of the
            #--- foreground interval to match.
            set fgID $::Ibrowser(FGInterval)
            if { $fgID != $::Ibrowser(NoInterval) } {
                set otherthing "$::IbrowserController($fgID,visIconTag)"
                $win itemconfig $otherthing -image $::IbrowserController(Images,Icon,visIcon)
                set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isVisible)
            }

            #--- Then, update the MainViewer
            MainSlicesSetVisibilityAll 1
            RenderAll
        }
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserMakeHoldIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeHoldIcon { id state x1 y1 x2 y2 } {

    
    if { $state == $::IbrowserController(Info,Icon,hold) } {
        set q [ $::IbrowserController(Icanvas) create image $x1 $y1  \
                    -image $::IbrowserController(Images,Icon,holdIcon) \
                    -anchor nw -tag "$::IbrowserController($id,holdIconTag)" ]

        #hilite rect on mouseover
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,holdIconTag)  <Enter> \
            "%W itemconfig $::IbrowserController($id,holdIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,holdIconTag)  <Leave> \
            "%W itemconfig $::IbrowserController($id,holdIconHILOtag) -outline $::IbrowserController(Colors,lolite) "

        #toggle image on rightclick
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,holdIconTag) <Button-1> \
            " IbrowserToggleHoldIcon %W $id "

        #post help on leftclick
        #---------------
        
    } elseif { $state ==  $::IbrowserController(Info,Icon,nohold) } {
        set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                    -image $::IbrowserController(Images,Icon,noholdIcon) \
                    -anchor nw -tag "$::IbrowserController($id,noholdIconTag)" ]
        
        #hilite rect on mouseover
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,noholdIconTag) <Enter> \
            "%W itemconfig $::IbrowserController($id,noholdHILOtag)  -outline $::IbrowserController(Colors,hilite) "
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,noholdIconTag) <Leave> \
            "%W itemconfig $::IbrowserController($id,noholdHILOtag) -outline $::IbrowserController(Colors,lolite) "

        #toggle image on rightclick
        #---------------
        $::IbrowserController(Icanvas) bind $::IbrowserController($id,noholdIconTag) <Button-1> \
            " IbrowserToggleHoldIcon %W $id "

        #post help on leftclick
        #---------------
    }
    
    # this is the hilight around the icon that lights up, and goes down
    #---------------
    eval "$::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
                [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) \
                -tag $::IbrowserController($id,holdIconHILOtag)"

    IbrowserIncrementIconCount
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeDeleteIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeDeleteIcon { id x1 y1 x2 y2 } {

    #--- when user clicks delete icon, they are prompted for
    #--- whether they truly want to delete the interval and
    #--- its contents. If yes, all are deleted.
    set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                -image $::IbrowserController(Images,Icon,deleteIcon) \
                -anchor nw -tag "$::IbrowserController($id,deleteIconTag)" ]
    $::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
        [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) \
        -tag "$::IbrowserController($id,deleteIconHILOtag)"

    $::IbrowserController(Icanvas) bind $::IbrowserController($id,deleteIconTag) <Enter> \
        "%W itemconfig $::IbrowserController($id,deleteIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,deleteIconTag) <Leave> \
        "%W itemconfig $::IbrowserController($id,deleteIconHILOtag) -outline $::IbrowserController(Colors,lolite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,deleteIconTag) <Button-1> \
        "IbrowserDeleteIntervalPopUp deletepopup $id $::IbrowserController(popupX) $::IbrowserController(popupY)"
    
    IbrowserIncrementIconCount

}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeFGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeFGIcon { id x1 y1 x2 y2 } {


    #--- when user clicks FG icon, this moves all the interval's volumes
    #--- to the foreground and makes them active.
    set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                -image $::IbrowserController(Images,Icon,FGIcon) \
                -anchor nw -tag "$::IbrowserController($id,FGIconTag)" ]
    $::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
        [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) \
        -tag "$::IbrowserController($id,FGIconHILOtag)"

    $::IbrowserController(Icanvas) bind $::IbrowserController($id,FGIconTag) <Enter> \
        "%W itemconfig $::IbrowserController($id,FGIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,FGIconTag) <Leave> \
        "IbrowserLeaveFGIcon $id %W"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,FGIconTag) <Button-1> \
         "IbrowserDeselectFGIcon %W;
         IbrowserSlicesSetVolumeAll Fore $::Ibrowser($id,$::Ibrowser(ViewDrop),MRMLid);
         set ::Ibrowser(FGInterval) $id;
         IbrowserSelectFGIcon $id %W;
         IbrowserGangFGandBGVisibility;
         RenderAll"
    
    IbrowserIncrementIconCount

}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeBGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeBGIcon { id x1 y1 x2 y2 } {
    
    
    #--- when user clicks BG icon, this moves all the interval's volumes
    #--- to the background but does not make them active.
    set q [ $::IbrowserController(Icanvas) create image $x1 $y1 \
                -image $::IbrowserController(Images,Icon,BGIcon) \
                -anchor nw -tag "$::IbrowserController($id,BGIconTag)" ]
    $::IbrowserController(Icanvas) create rect $x1 $y1  [expr $x1 + $::IbrowserController(Geom,Icon,iconWid) -1 ] \
        [expr $y1 + $::IbrowserController(Geom,Icon,iconHit) -1 ] -outline $::IbrowserController(Colors,lolite) \
        -tag "$::IbrowserController($id,BGIconHILOtag)"

    $::IbrowserController(Icanvas) bind $::IbrowserController($id,BGIconTag) <Enter> \
        "%W itemconfig $::IbrowserController($id,BGIconHILOtag) -outline $::IbrowserController(Colors,hilite) "
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,BGIconTag) <Leave> \
        "IbrowserLeaveBGIcon $id %W"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,BGIconTag) <Button-1> \
        "IbrowserDeselectBGIcon %W;
          IbrowserSlicesSetVolumeAll Back $::Ibrowser($id,$::Ibrowser(ViewDrop),MRMLid) ;
          set ::Ibrowser(BGInterval) $id;
          IbrowserSelectBGIcon $id %W;
          IbrowserGangFGandBGVisibility;
          RenderAll"
    
    IbrowserIncrementIconCount
}



#-------------------------------------------------------------------------------
# .PROC IbrowserDeselectFGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeselectFGIcon { w } {

    #deselect old FG interval in the Controller panel
    foreach id $::Ibrowser(idList) {
        if { $id == $::Ibrowser(FGInterval) && $id != $::Ibrowser(NoInterval) } {
            $w itemconfig $::IbrowserController($id,FGIconHILOtag) \
                -outline $::IbrowserController(Colors,lolite)
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserGangFGandBGVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGangFGandBGVisibility { } {

    #--- check the foreground's visibility status.
    #--- check the background's visibility status.
    #--- if they don't match, change the background's
    #--- to match the foreground

    set fgID $::Ibrowser(FGInterval)
    set bgID $::Ibrowser(BGInterval)
    if { $fgID != $::Ibrowser(NoInterval) && $bgID != $::Ibrowser(NoInterval) } {
        set fgstatus $::Ibrowser($fgID,visStatus)
        set bgstatus $::Ibrowser($bgID,visStatus)
        if { $fgstatus != $bgstatus } {
            IbrowserToggleVisibilityIcon $bgID
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserSelectFGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSelectFGIcon { id w } {

    #hilight FG interval in the Controller panel
    $w itemconfig $::IbrowserController($id,FGIconHILOtag) \
        -outline $::IbrowserController(Colors,hilite)

    #--- update the Slices windows to reflect the foreground
    #--- interval's visibility.
    if { $::Ibrowser($id,visStatus) == $::IbrowserController(Info,Ival,isVisible) } {
        MainSlicesSetVisibilityAll 1
    } else {
        MainSlicesSetVisibilityAll 0
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserLeaveFGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserLeaveFGIcon { id w } {

    #leave FG interval in the proper state

    if { $id != $::Ibrowser(FGInterval) } {
        $w itemconfig $::IbrowserController($id,FGIconHILOtag) \
            -outline $::IbrowserController(Colors,lolite)
    } else {
        $w itemconfig $::IbrowserController($id,FGIconHILOtag) \
            -outline $::IbrowserController(Colors,hilite)
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserDeselectBGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeselectBGIcon { w } {

    #deselect old BG interval in the Controller panel
    foreach id $::Ibrowser(idList) {
        if { $id == $::Ibrowser(BGInterval) && $id != $::Ibrowser(NoInterval) } {
            $w itemconfig $::IbrowserController($id,BGIconHILOtag) \
                -outline $::IbrowserController(Colors,lolite)
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserSelectBGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSelectBGIcon { id w } {

    #hilight BG interval in the Controller panel
    $w itemconfig $::IbrowserController($id,BGIconHILOtag) \
        -outline $::IbrowserController(Colors,hilite)

}


#-------------------------------------------------------------------------------
# .PROC IbrowseLeaveBGIcon
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserLeaveBGIcon { id w } {

    #leave BG interval in the proper state

    if { $id != $::Ibrowser(BGInterval) } {
        $w itemconfig $::IbrowserController($id,BGIconHILOtag) \
            -outline $::IbrowserController(Colors,lolite)
    } else {
        $w itemconfig $::IbrowserController($id,BGIconHILOtag) \
            -outline $::IbrowserController(Colors,hilite)
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserCopyIntervalPopUp
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCopyIntervalPopUp { win id x y } {

    set noneID $::Ibrowser(none,intervalID)
    
    if { $id != $noneID } {
        set w .w$win
        if { [IbrowserRaisePopup $w] == 1} {return}

        set title "Copy interval"
        IbrowserCreatePopup $w $title $x $y 

        set f $w
        frame $f.fMsg  -background #FFFFFF 
        frame $f.fName -background #FFFFFF
        frame $f.fButtons -background #FFFFFF
        pack $f.fMsg $f.fName $f.fButtons -side top -pady 4 -padx 4 
        
        set f $w.fMsg
        eval {label $f.l -text "Name a copy of $::Ibrowser($id,name)." \
                -font $::IbrowserController(UI,Medfont) -background #FFFFFF \
                -foreground #000000 \
              }
        pack $f.l -padx 5 -pady 5

        set f $w.fName
        set ::Ibrowser(thisName) $::Ibrowser($id,name)
        #set ::Ibrowser(afterName) $::Ibrowser($id,name)-copy
        if { [ info exists ::MultiVolumeReader(defaultSequenceName)] } {
            incr ::MultiVolumeReader(defaultSequenceName)
        } else {
            set ::MultiVolumeReader(defaultSequenceName) 1
        }
        set mmID $::MultiVolumeReader(defaultSequenceName)
        set ::Ibrowser(afterName) [format "multiVol%d" $mmID]

        eval { label $f.l -text "new interval: " -background #FFFFFF \
                -font $::IbrowserController(UI,Medfont) -foreground #000000 }
        eval { entry $f.e -width 20 -relief sunken -textvariable ::Ibrowser(afterName) }
        pack $f.l $f.e -side left -padx 4 -pady 4

        #dismiss
        #---------------
        set f $w.fButtons
        button $f.bApply -text "Apply" -width 4 -bg #DDDDDD \
            -command {
                set goodname [ IbrowserUniqueNameCheck $::Ibrowser(afterName) ]
                if { $goodname } {
                    IbrowserCopyInterval $::Ibrowser(thisName) $::Ibrowser(afterName)
                    destroy .wcopypopup
                } else {
                    IbrowserSayThis "This interval name is already in use. Please specify again." 1
                    DevErrorWindow "Please specify a unique interval name."
                }
            }
        $f.bApply config -font $::IbrowserController(UI,Medfont) 

        button $f.bCancel -text "Cancel" -width 4 -bg #DDDDDD \
            -command "destroy $w"
        $f.bCancel config -font $::IbrowserController(UI,Medfont)
        
        pack $f.bApply $f.bCancel -side left  -ipadx 3 -ipady 3 -padx 4
        IbrowserRaisePopup $w
    }
}





#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteIntervalPopUp
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteIntervalPopUp { win id x y } {

    set noneID $::Ibrowser(none,intervalID)

    if { $id != $noneID } {
        set w .w$win
        if { [IbrowserRaisePopup $w] == 1} {return}

        set title "Delete interval"
        IbrowserCreatePopup $w $title $x $y 

        set f $w
        frame $f.fMsg  -background #FFFFFF 
        frame $f.fClose -background #FFFFFF 
        pack $f.fMsg $f.fClose -side top -pady 4 -padx 4 
        
        set f $w.fMsg
        eval {label $f.l -text "Delete interval $::Ibrowser($id,name) and its contents?" \
                -font $::IbrowserController(UI,Medfont) -background #FFFFFF \
                -foreground #000000 }
        pack $f.l -padx 5 -pady 5

        set ::Ibrowser(thisName) $::Ibrowser($id,name)

        #dismiss
        #---------------
        set f $w.fClose
        button $f.bDelete -text "Delete" -width 4 -bg #DDDDDD \
            -command {
                    IbrowserDeleteInterval $::Ibrowser(thisName)
                    destroy .wdeletepopup
            }
        $f.bDelete config -font $::IbrowserController(UI,Medfont) 

        button $f.bCancel -text "Cancel" -width 4 -bg #DDDDDD \
            -command "destroy $w"
        $f.bCancel config -font $::IbrowserController(UI,Medfont)
        
        pack $f.bDelete $f.bCancel -side left  -ipadx 3 -ipady 3 -padx 4
        IbrowserRaisePopup $w
    }

}


#-------------------------------------------------------------------------------
# .PROC IbrowserOrderPopUp
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserOrderPopUp { win id x y } {
    
    set noneID $::Ibrowser(none,intervalID)
    if { $id != $noneID } {
        set w .w$win
        if { [IbrowserRaisePopup $w] == 1} {return}

        set title "Reorder intervals"
        IbrowserCreatePopup $w $title $x $y 
        set ::Ibrowser(afterName) "none"
        set ::Ibrowser(thisName) $::Ibrowser($id,name)

        set f $w
        frame $f.fMsg  -background #FFFFFF 
        frame $f.fBtns 
        frame $f.fClose -background #FFFFFF 
        pack $f.fMsg $f.fBtns $f.fClose -side top -pady 4 -padx 4 
        
        set f $w.fMsg
        eval {label $f.l -text "move $::Ibrowser($id,name) after: " \
                -font $::IbrowserController(UI,Medfont) -background #FFFFFF \
                -foreground #000000 }
        pack $f.l -padx 5 -pady 5 

        #--- menubutton with pulldown menu
        set f $w.fBtns
        eval { menubutton $f.mbIvalOrder -text \
                   $::Ibrowser(afterName) \
                   -relief raised -bd 2 -width 25 \
                   -background #DDDDDD \
                   -menu $f.mbIvalOrder.m }
        pack $f.mbIvalOrder -side top -pady 1 -padx 1
        set ::Ibrowser(guiOrderMenuButton) $f.mbIvalOrder

        #--- menu and commands
        eval { menu $f.mbIvalOrder.m -background #FFFFFF \
                -foreground #000000 }
        foreach ivalID $::Ibrowser(idList) {
            set name $::Ibrowser($ivalID,name)
            if { $name != $::Ibrowser($id,name) } {
                $f.mbIvalOrder.m add command -label $name \
                    -command "IbrowserSetupNewNames $::Ibrowser($id,name) $name"
            }
        }
        
        #dismiss
        #---------------
        set f $w.fClose
        button $f.bApply -text "Apply" -width 4 -bg #DDDDDD \
            -command {
                if { $::Ibrowser(afterName) != "" } {
                    IbrowserInsertIntervalAfterInterval $::Ibrowser(thisName) $::Ibrowser(afterName)
                    destroy .worderpopup
                }
            }
        $f.bApply config -font $::IbrowserController(UI,Medfont) 

        button $f.bCancel -text "Cancel" -width 4 -bg #DDDDDD \
            -command "destroy $w"
        $f.bCancel config -font $::IbrowserController(UI,Medfont)
        
        pack $f.bApply $f.bCancel -side left  -ipadx 3 -ipady 3 -padx 4
        IbrowserRaisePopup $w
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserSetupNewNames
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetupNewNames { this after } {

    set ::Ibrowser(thisName) $this
    set ::Ibrowser(afterName) $after
    $::Ibrowser(guiOrderMenuButton) config -text $::Ibrowser(afterName)
}



