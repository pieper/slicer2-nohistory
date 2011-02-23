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
# FILE:        IbrowserControllerDrops.tcl
# PROCEDURES:  
#   IbrowserSetupDropImages
#   IbrowserCreateImageDrops
#   IbrowserCreateDataDrops
#   IbrowserCreateEventDrops
#   IbrowserCreateCommandDrops
#   IbrowserCreateGeometryDrops
#   IbrowserCreateNoteDrops
#   IbrowserMoveIntervalDrops
#   IbrowserDeleteIntervalDrops
#   IbrowserRedrawDrops
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC IbrowserSetupDropImages
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetupDropImages { } {
    global PACKAGE_DIR_VTKIbrowser

    #--- This variable contains the module path plus some stuff
    #--- trim off the extra stuff, and add on the path to tcl files.
    set tmpstr $PACKAGE_DIR_VTKIbrowser
    set tmpstr [string trimright $tmpstr "/vtkIbrowser" ]
    set tmpstr [string trimright $tmpstr "/Tcl" ]
    set tmpstr [string trimright $tmpstr "Wrapping" ]
    set modulePath [format "%s%s" $tmpstr "tcl/"]

    set ::IbrowserController(Images,Drop,imageDrop) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/canvas/drop.gif]
    set ::IbrowserController(Images,Drop,geomDrop) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/canvas/drop.gif]    
    set ::IbrowserController(Images,Drop,dataDrop) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/canvas/drop.gif]    
    set ::IbrowserController(Images,Drop,eventDrop) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/canvas/drop.gif]    
    set ::IbrowserController(Images,Drop,noteDrop) \
        [image create photo -file ${modulePath}iconPix/20x20/gifs/canvas/drop.gif]    
}


#-------------------------------------------------------------------------------
# .PROC IbrowserCreateImageDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateImageDrops { ivalName posArray numDrops } {
    
    set id $::Ibrowser($ivalName,intervalID)
    upvar $posArray unitpos
   
    #What we want to do, is to indicate each
    #sample's position in the intervalRect.
    #Use ::IbrowserController($id,pixytop) to verticallyposition the Drop
    #and use posArray to position it horizontally.
    #---------------
    for { set i 0} {$i < $numDrops } { incr i } {
        set pixpos [ IbrowserUnitValToPixelVal $unitpos($i) ]
        set ::Ibrowser($id,$i,pos) $pixpos

        set ycenter [ expr $::IbrowserController(Geom,Ival,intervalPixHit) / 2.0 ]
        set ypos [ expr $::IbrowserController($id,pixytop) + $ycenter ]
        
        set ::IbrowserController($id,$i,dropTAG) ${id}_${i}_dropTAG
        set itemtag $::IbrowserController($id,$i,dropTAG)
        #Tag each individual drop, the group of interval drops, and all Interval drops.
        #---------------
        $::IbrowserController(Icanvas) create image $pixpos $ypos \
            -image $::IbrowserController(Images,Drop,imageDrop) \
            -anchor c -tags "$itemtag $::IbrowserController($id,allDROPtag) IbrowserDropTags"

        #And make sure they draw atop the interval rect
        #---------------
        $::IbrowserController(Icanvas) raise IbrowserDropTags
    }

}



#-------------------------------------------------------------------------------
# .PROC IbrowserCreateDataDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateDataDrops { ivalName posArray numDrops} {
}

#-------------------------------------------------------------------------------
# .PROC IbrowserCreateEventDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateEventDrops { ivalName posArray numDrops} {
}

#-------------------------------------------------------------------------------
# .PROC IbrowserCreateCommandDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateCommandDrops { ivalName posArray numDrops} {
}

#-------------------------------------------------------------------------------
# .PROC IbrowserCreateGeometryDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateGeometryDrops { ivalName posArray numDrops} {
}

#-------------------------------------------------------------------------------
# .PROC IbrowserCreateNoteDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateNoteDrops { ivalName posArray numDrops} {
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMoveIntervalDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMoveIntervalDrops { ivalName oldy newy } {
    
    set id $::Ibrowser($ivalName,intervalID)
    
    set numdrops $::Ibrowser($id,numDrops)
    if { $::Ibrowser($id,numDrops) == 0 } {
        return
    }

    #move an interval's drops by yy
    #---------------
    set yy [ expr $newy - $oldy ]
    if {$yy != 0} {
        $::IbrowserController(Icanvas) move $::IbrowserController($id,allDROPtag) 0 $yy
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteIntervalDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteIntervalDrops { ivalName } {
    
    set id $::Ibrowser($ivalName,intervalID)
    
    #delete the GUI representation of the drops
    #---------------
    $::IbrowserController(Icanvas) delete $::IbrowserController($id,allDROPtag) 

    #delete an interval's Drops
    #---------------
    for { set i 0} {$i < $::Ibrowser($id,numDrops) } { incr i } {
        if { [info exists ::Ibrowser($id,$i,data) ] } {
            #--- delete the ImageData and the MrmlNodes...
            unset -nocomplain ::Ibrowser($id,$i,matrixID)
            unset -nocomplain ::Ibrowser($id,$i,transformID)
            unset ::Ibrowser($id,$i,data)
        }
     }
    set ::Ibrowser($id,numDrops) 0

}




#-------------------------------------------------------------------------------
# .PROC IbrowserRedrawDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRedrawDrops { } {

}
