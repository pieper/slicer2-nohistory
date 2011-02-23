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
# FILE:        IbrowserControllerIntervals.tcl
# PROCEDURES:  
#   IbrowserSetupIntervals
#   IbrowserIncrementIntervalCount
#   IbrowserGetIntervalCount
#   IbrowserDecrementIntervalCount
#   IbrowserInitIntervalInfo
#   IbrowserInitIntervalGeom
#   IbrowserComputeIntervalYtop
#   IbrowserComputeIntervalXleft
#   IbrowserUpdateGlobalYspan
#   IbrowserUpdateGlobalXspan
#   IbrowserIntervalRedraw
#   IbrowserCopyIntervalVolumes
#   IbrowserCopyInterval
#   IbrowserCopyInterval
#   IbrowserDeleteIntervalVolumes
#   IbrowserDeleteInterval
#   IbrowserDeleteAllIntervals
#   IbrowserUpdateMaxDrops
#   IbrowserInitNewInterval
#   IbrowserMakeNoneInterval
#   IbrowserSetActiveInterval
#   IbrowserSetFGInterval
#   IbrowserSetBGInterval
#   IbrowserMakeNewInterval
#   IbrowserGetIntervalAdaptiveUnitSpan
#   IbrowserGetIntervalAdaptiveUnitXmin
#   IbrowserGetIntervalAdaptiveUnitXmax
#   IbrowserGetIntervalFillCol
#   IbrowserGetIntervalOutlineCol
#   IbrowserGetIntervalOrderStatus
#   IbrowserGetIntervalVisStatus
#   IbrowserGetIntervalOpaqStatus
#   IbrowserSetIntervalOrder
#   IbrowserInsertIntervalAfterInterval
#   IbrowserInsertIntervalBeforeInterval
#   IbrowserReorderIntervals
#   IbrowserOrderSortIntervalList
#   IbrowserIncrementIntervalOrder
#   IbrowserDecrementIntervalOrder
#   IbrowserRenameInterval
#   IbrowserUniqueNameCheck
#   IbrowserPuffUpSpan
#   IbrowserPuffUpSpan
#   IbrowserScaleIntervals
#   IbrowserGetIntervalName
#   IbrowserGetIntervalOrder
#   IbrowserGetIntervalType
#   IbrowserCreateIntervalBar
#   IbrowserDeselectActiveInterval
#   IbrowserSelectActiveInterval
#   IbrowserLeaveIntervalBar
#   IbrowserDeleteIntervalBar
#   IbrowserGetIntervalDrop
#   IbrowserGetIntervalPixSpan
#   IbrowserGetIntervalPixYtop
#   IbrowserGetIntervalPixXstart
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC IbrowserSetupIntervals
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetupIntervals { } {

    IbrowserInitIntervalGeom
    IbrowserInitIntervalInfo
}




#-------------------------------------------------------------------------------
# .PROC IbrowserIncrementIntervalCount
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserIncrementIntervalCount { } {

    set ::IbrowserController(Info,Ival,ivalCount) [ expr $::IbrowserController(Info,Ival,ivalCount) + 1 ]
}





#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalCount
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalCount { } {

    return $::IbrowserController(Info,Ival,ivalCount)
}





#-------------------------------------------------------------------------------
# .PROC IbrowserDecrementIntervalCount
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDecrementIntervalCount { } {

    set ::IbrowserController(Info,Ival,ivalCount) [ expr $::IbrowserController(Info,Ival,ivalCount) - 1 ]
}





#-------------------------------------------------------------------------------
# .PROC IbrowserInitIntervalInfo
# IbrowserIntervalInfo holds global information shared by all intervals
# Some of this information also stored within a vtkIntervalCollection.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitIntervalInfo { } {
    
    # INIT HORIZONTAL SPAN
    # Keeps track of how many intervals there are
    # and how many units the longest one represents.
    # The global span is given in pixels
    #---------------
    set ::IbrowserController(Info,Ival,ivalCount) 0

    # Default interval flag
    #---------------    
    set ::IbrowserController(Info,Ival,firstIval) 1

    # Default units
    #---------------
    set ::IbrowserController(Info,Ival,defaultUnitSpanMin) 0.0
    set ::IbrowserController(Info,Ival,defaultUnitSpanMax) 0.0
    set ::IbrowserController(Info,Ival,defaultUnitSpan) \
        [ expr $::IbrowserController(Info,Ival,defaultUnitSpanMax) - \
              $::IbrowserController(Info,Ival,defaultUnitSpanMin) ]
    # Global units at default
    #---------------
    set ::IbrowserController(Info,Ival,globalIvalUnitSpanMax) $::IbrowserController(Info,Ival,defaultUnitSpan)
    set ::IbrowserController(Info,Ival,globalIvalUnitSpanMin) $::IbrowserController(Info,Ival,defaultUnitSpanMin)
    set ::IbrowserController(Info,Ival,globalIvalUnitSpan) $::IbrowserController(Info,Ival,defaultUnitSpan)                                                  

    # Default pixels for now
    #---------------
    set ::IbrowserController(Info,Ival,globalIvalPixSpanMax) 0
    set ::IbrowserController(Info,Ival,globalIvalPixSpanMin) 0
    set ::IbrowserController(Info,Ival,globalIvalPixSpan) \
        [ expr $::IbrowserController(Info,Ival,globalIvalPixSpanMax) - \
              $::IbrowserController(Info,Ival,globalIvalPixSpanMin) ]

    set ::IbrowserController(Info,Ival,globalIvalPixXstart) 0
    
    # INIT VERTICAL SPAN
    # How much vertical space on the canvas do
    # all intervals in the collection take up? Init
    # with the space the first (default) one takes.
    set yy $::IbrowserController(Geom,Ival,intervalYbuf)
    set space [ expr $::IbrowserController(Geom,Ival,intervalPixHit) + $::IbrowserController(Geom,Ival,intervalGap) ]
    set num $::IbrowserController(Info,Ival,ivalCount)
    set num [expr $num * $space]
    set ::IbrowserController(Info,Ival,globalIvalYPixSpan) [expr $yy + $num ]
                               
    # If you add a new kind of interval,
    # please add the type to the suite below.
    # set interval types
    # DEFINE NEW INTERVAL TYPES HERE
    #---------------
    set  ::IbrowserController(Info,Ival,imageIvalType) Image
    set  ::IbrowserController(Info,Ival,dataIvalType) Data
    set  ::IbrowserController(Info,Ival,eventIvalType) Event  
    set  ::IbrowserController(Info,Ival,geomIvalType) Geom 
    set  ::IbrowserController(Info,Ival,noteIvalType) Note     

    # different interval types are color coded
    # set interval fill colors
    # DEFINE NEW COLORS FOR INTERVAL TYPES
    #---------------
    set  ::IbrowserController(Info,Ival,fillColImage) #FFCC80
    set  ::IbrowserController(Info,Ival,fillColData) #D2DD88
    set  ::IbrowserController(Info,Ival,fillColEvent) #CFDDFF
    set  ::IbrowserController(Info,Ival,fillColGeom) #BBCCAA
    set  ::IbrowserController(Info,Ival,fillColNote) #FFFFBB

    # different interval types are color coded
    # set interval outline colors
    #---------------
    set  ::IbrowserController(Info,Ival,outlineColImage) #AA9977
    set  ::IbrowserController(Info,Ival,outlineColData)  #88AA22
    set  ::IbrowserController(Info,Ival,outlineColEvent) #8EAAB0
    set  ::IbrowserController(Info,Ival,outlineColGeom) #99AA88
    set  ::IbrowserController(Info,Ival,outlineColNote)  #BBBB66
    set ::IbrowserController(Info,Ival,outlineActive) #BC1111

    # settings determine which method is used
    # to render, and which icon is used in the UI
    # to reflect the selected rendering method 
    # ADD NEW RENDER METHODS HERE
    #---------------
    set ::IbrowserController(Info,Ival,imgRenderStyle) image
    set ::IbrowserController(Info,Ival,cmapRenderStyle) cmap
    set ::IbrowserController(Info,Ival,noteRenderStyle) note
    set ::IbrowserController(Info,Ival,eventRenderStyle) event
    
    # settings determine which visibility,
    # opacity and compositing methods
    # are used to visualize the interval's 
    # data, and which icons are used in
    # the UI to reflect those methods
    #---------------
    set ::IbrowserController(Info,Ival,isVisible) visible
    set ::IbrowserController(Info,Ival,isInvisible) invisible
    set ::IbrowserController(Info,Ival,hold) hold
    set ::IbrowserController(Info,Ival,nohold) nohold
    
}





#-------------------------------------------------------------------------------
# .PROC IbrowserInitIntervalGeom
# this array IbrowserIntervalGeom holds global geometry information
# shared by all intervals.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitIntervalGeom { } {

    # Here, the geometry is specified in actual pixel values.
    # Reasonable geometries are specified for different UI sizes.
    #---------------
    if { $::IbrowserController(UI,Small) } {
        # Initial default values
        #---------------
        set ::IbrowserController(Geom,Ival,defaultPixWid) 400
        set ::IbrowserController(Geom,Ival,intervalPixHit) 19

        # This is the small buffer around the perimeter
        # of the canvas where nothing is drawn, and
        # the gap between intervals
        #---------------
        set ::IbrowserController(Geom,Ival,intervalXbuf) 3
        set ::IbrowserController(Geom,Ival,intervalYbuf) 3
        set ::IbrowserController(Geom,Ival,intervalGap) 5
        set ::IbrowserController(Geom,Ival,scrollBuf) 15
        
    } elseif {$::IbrowserController(UI,Big)} {
        set ::IbrowserController(Geom,Ival,defaultPixWid) 400
        set ::IbrowserController(Geom,Ival,intervalPixHit) 19
        set ::IbrowserController(Geom,Ival,intervalXbuf) 3
        set ::IbrowserController(Geom,Ival,intervalYbuf) 3
        set ::IbrowserController(Geom,Ival,intervalGap) 5        
        set ::IbrowserController(Geom,Ival,scrollBuf) 15
    } else {
        set ::IbrowserController(Geom,Ival,defaultPixWid) 400
        set ::IbrowserController(Geom,Ival,intervalPixHit) 19
        set ::IbrowserController(Geom,Ival,intervalXbuf) 3
        set ::IbrowserController(Geom,Ival,intervalYbuf) 3
        set ::IbrowserController(Geom,Ival,intervalGap) 5
        set ::IbrowserController(Geom,Ival,scrollBuf) 15
    }
}





#-------------------------------------------------------------------------------
# .PROC IbrowserComputeIntervalYtop
# Computes the y value, in pixels, of the top of an interval to
# be drawn, based on the number of intervals.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserComputeIntervalYtop { num } {
    
    set numIntervals [expr $num - 1]
    set buf $::IbrowserController(Geom,Ival,intervalYbuf)
    set ivalspace [ expr $::IbrowserController(Geom,Ival,intervalPixHit) * $numIntervals ]
    set ivalgaps  [ expr  $::IbrowserController(Geom,Ival,intervalGap) * $numIntervals ]
    set buf [ expr $buf + $ivalspace + $ivalgaps ]
    return $buf
}



#-------------------------------------------------------------------------------
# .PROC IbrowserComputeIntervalXleft
# Computes the x value, in pixels, of the left of the rect
# representing the interval.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserComputeIntervalXleft { } {

    #start where the leftmost icon in the interval begins.
    #---------------
    set xx $::IbrowserController(Geom,Icon,iconStart)

    #add in the number of small icons and number of gaps betwn
    #---------------
    set N [ expr $::IbrowserController(Info,Icon,numIconsPerInterval) - 1 ]
    set chunk1 [ expr $::IbrowserController(Geom,Icon,iconWid) + $::IbrowserController(Geom,Icon,iconGap) ]
    set chunk1 [ expr $chunk1 * $N ]

    #add in the size of nameIcon and one gap
    #---------------
    set chunk2 [ expr $::IbrowserController(Geom,Icon,nameIconWid) + $::IbrowserController(Geom,Icon,iconGap) ]

    #---INTERVAL START...need to add one more gap; i don't know why...
    set chunk2 [ expr $chunk2 + $::IbrowserController(Geom,Icon,iconGap) ]
    
    #add both chunks plus the margin
    #---------------
    set wholechunk [expr $::IbrowserController(Geom,Icon,iconXstart) + $chunk1 + $chunk2 ]
    return $wholechunk
}





#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateGlobalYspan
# This proc checks and resets the interval's global yspan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateGlobalYspan { } {

    # how many intervals,
    # multiplied by the space they take up.
    #---------------
    set num $::IbrowserController(Info,Ival,ivalCount)
    set sum [ expr $::IbrowserController(Geom,Ival,intervalPixHit) + $::IbrowserController(Geom,Ival,intervalGap) ]
    set buf [ expr $num * $sum ]
    set ::IbrowserController(Info,Ival,globalIvalYPixSpan) $buf
}





#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateGlobalXspan
# Check to see whether we need to readjust
# room on left or right to accommodate span
# of a new interval. If so, compute, and then
# update global values.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateGlobalXspan { } {

    # First, the global interval may have shrunk because a
    # big interval was deleted. So look at the true (but
    # puffedup) span of each interval and determine the
    # max true span.
    #---------------
    set tmp 0
    foreach id $::Ibrowser(idList) {
        if { $::IbrowserController($id,myUnitSpan) > $tmp } {
            set tmp $::IbrowserController($id,myUnitSpan)
            set keepid $id
        }
    }

    # if the max true span is less than the globalspan
    # shrink the global span. Otherwise, reset to default values.
    # and then test to see if we need to grow it. Increase it
    # if appropriate.
    #---------------
    if { $tmp < $::IbrowserController(Info,Ival,globalIvalUnitSpan) } {
        #---------------
        # SHRINKING SPAN
        #---------------
        set ::IbrowserController(Info,Ival,globalIvalUnitSpanMin) $::IbrowserController($keepid,myUnitSpanMin)
        set ::IbrowserController(Info,Ival,globalIvalUnitSpanMax) $::IbrowserController($keepid,myUnitSpanMax)
        #globalIvalPixSpanMin is always pegged here.
        set ::IbrowserController(Info,Ival,globalIvalPixSpanMin) $::IbrowserController(Info,Ival,globalIvalPixXstart)
        #compute global unit span and pixel span
        set gspan [ expr $::IbrowserController(Info,Ival,globalIvalUnitSpanMax) - \
                        $::IbrowserController(Info,Ival,globalIvalUnitSpanMin) ]

        if  { $gspan != $::IbrowserController(Info,Ival,globalIvalUnitSpan) } {
            set ::IbrowserController(Info,Ival,globalIvalUnitSpan) $gspan
            set ::IbrowserController(Info,Ival,globalIvalPixSpan) [ IbrowserUnitSpanToPixelSpan $gspan ]
            set thing [ expr $::IbrowserController(Info,Ival,globalIvalPixXstart) + \
                            $::IbrowserController(Info,Ival,globalIvalPixSpan) ]
            set ::IbrowserController(Info,Ival,globalIvalPixSpanMax) $thing
        }

    } else {
        #---------------
        # GROWINING SPAN
        #---------------
        #reset global unit span to its default value.
        set ::IbrowserController(Info,Ival,globalIvalUnitSpanMin) $::IbrowserController(Info,Ival,defaultUnitSpanMin)
        set ::IbrowserController(Info,Ival,globalIvalUnitSpanMax) $::IbrowserController(Info,Ival,defaultUnitSpanMax)
        set ::IbrowserController(Info,Ival,globalIvalUnitSpan) $::IbrowserController(Info,Ival,defaultUnitSpan)                                                  

        # if a new interval is bigger than the
        # existing global span, then we want
        # to increase the global span 
        #---------------        
        foreach id $::Ibrowser(idList) {

            # find the min span
            #---------------
            if { $::IbrowserController($id,adaptiveUnitSpanMin) < $::IbrowserController(Info,Ival,globalIvalUnitSpanMin) } {
                set ::IbrowserController(Info,Ival,globalIvalUnitSpanMin) $::IbrowserController($id,adaptiveUnitSpanMin)
            } 

            # find the max span
            #---------------
            if { $::IbrowserController($id,adaptiveUnitSpanMax) > $::IbrowserController(Info,Ival,globalIvalUnitSpanMax) } {
                set ::IbrowserController(Info,Ival,globalIvalUnitSpanMax) $::IbrowserController($id,adaptiveUnitSpanMax)
            }

            #globalIvalPixSpanMin is always pegged here.
            set ::IbrowserController(Info,Ival,globalIvalPixSpanMin) $::IbrowserController(Info,Ival,globalIvalPixXstart)
            #compute global unit span and pixel span
            #---------------
            set gspan [ expr $::IbrowserController(Info,Ival,globalIvalUnitSpanMax) - \
                            $::IbrowserController(Info,Ival,globalIvalUnitSpanMin) ]

            if  { $gspan > $::IbrowserController(Info,Ival,globalIvalUnitSpan) } {
                set ::IbrowserController(Info,Ival,globalIvalUnitSpan) $gspan
                set ::IbrowserController(Info,Ival,globalIvalPixSpan) [ IbrowserUnitSpanToPixelSpan $gspan ]
                set thing [ expr $::IbrowserController(Info,Ival,globalIvalPixXstart) + \
                                $::IbrowserController(Info,Ival,globalIvalPixSpan) ]
                set ::IbrowserController(Info,Ival,globalIvalPixSpanMax) $thing

            }
        }
    }
}







#-------------------------------------------------------------------------------
# .PROC IbrowserIntervalRedraw
# Seems that someone has updated an interval's order.
# This proc redraws the text indicating the order value. 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserIntervalRedraw { } {

    set count 1

    #update all intervals
    foreach id $::Ibrowser(idList) {

        #recompute ::IbrowserController($id,$ytop) which is a function of order
        set oldytop $::IbrowserController($id,pixytop)
        set ::IbrowserController($id,pixytop) [ IbrowserComputeIntervalYtop $count]

        #redraw intervals, move their icons, and
        #update icon text where necessary.
        set txt [ format %d  $::Ibrowser($id,order) ]
        $::IbrowserController(Icanvas) itemconfig $::IbrowserController($id,orderTXTtag) -text $txt
        IbrowserMoveIntervalRect $::Ibrowser($id,name) $oldytop $::IbrowserController($id,pixytop)
        IbrowserMoveIcons $::Ibrowser($id,name) $oldytop $::IbrowserController($id,pixytop)
        IbrowserMoveIntervalDrops $::Ibrowser($id,name) $oldytop $::IbrowserController($id,pixytop)
        incr count
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserCopyIntervalVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCopyIntervalVolumes { sourceName copyName numVols } {
    global Volume
    
    set sourceID $::Ibrowser($sourceName,intervalID)
    set id $::Ibrowser($copyName,intervalID)

    set start $::Ibrowser($sourceID,firstMRMLid)
    set stop $::Ibrowser($sourceID,lastMRMLid)

    #--- create many new volumes...and copy
    #--- contents of source volumes into them.
    IbrowserRaiseProgressBar
    set sid $start
    set top [ expr $numVols - 1 ]
    for { set i 0 } { $i <= $top } { incr i } {
        if { $top != 0 } {
            set progress [ expr double( $i ) / double ( $top ) ]        
            IbrowserUpdateProgressBar $progress "::"
        }

        #--- create a new MrmlVolumeNode
        #--- and the vtkMrmlDataVolume Volume($vid,vol)
        set newvol [ MainMrmlAddNode Volume ]
        set vid [$newvol GetID]
        MainVolumesCreate $vid
        
        #--- note first and last MRML IDs in the interval.
        if { $i == 0 } {
            set ::Ibrowser($id,firstMRMLid) $vid
        }
        if { $i == $top } {
            set ::Ibrowser($id,lastMRMLid) $vid
        }

        #--- copy the node data and imagedata... 
        #--- and the node data.
        $newvol Copy Volume($sid,node)
        $newvol SetName ${copyName}_${i}
        MainVolumesCopyData $vid $sid Off
        set ::Ibrowser($id,$i,MRMLid) $vid
        incr sid
    }
    IbrowserLowerProgressBar
}




#-------------------------------------------------------------------------------
# .PROC IbrowserCopyInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCopyInterval { sourceName copyName } {

    set sourceID $::Ibrowser($sourceName,intervalID)
    set m $::Ibrowser($sourceID,numDrops)
    set spanmax [ expr $m - 1 ]

    set id [ IbrowserInitNewInterval $copyName ]

    #--- copy reference drops.
    IbrowserCopyIntervalVolumes $sourceName $copyName $m
    
    #--- create interval to contain the volumes.
    IbrowserMakeNewInterval $copyName $::IbrowserController(Info,Ival,imageIvalType) 0.0 $spanmax $m
    
    #--- update multivolumereader to reflect this multi-volume sequence
    set id $::Ibrowser($copyName,intervalID)
    IbrowserUpdateMultiVolumeReader $copyName $id
    
    #--- report in Ibrowser's message panel"
    set tt "Copied $sourceName to $copyName."
    IbrowserSayThis $tt 0

}






#-------------------------------------------------------------------------------
# .PROC 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc  IbrowserDeleteIntervalArray { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    set name $ivalName

    #--- remove reference to sequence if loaded in MultiVolumeReader
    if { [ info exists ::MultiVolumeReader(sequenceNames) ] } {
        set i [ lsearch $::MultiVolumeReader(sequenceNames) $ivalName ]
        set ::MultiVolumeReader(sequenceNames) \
            [ lreplace $::MultiVolumeReader(sequenceNames) $i $i ]
    }

    #--- delete interval info
    unset -nocomplain ::Ibrowser($id,name)
    unset -nocomplain ::Ibrowser($id,type)
    unset -nocomplain ::Ibrowser($id,opacity)
    unset -nocomplain ::Ibrowser($id,order)
    unset -nocomplain ::Ibrowser($id,transformID)
    unset -nocomplain ::Ibrowser($id,matrixID)
    
    for {set v 0 } { $v < $::Ibrowser($id,numDrops) } { incr v } {
        unset -nocomplain ::Ibrowser($id,v,pos)
        unset -nocomplain ::Ibrowser($id,v,dropTAG)
    }
    unset -nocomplain ::Ibrowser($id,numDrops)
    unset -nocomplain ::Ibrowser($ivalName,intervalID)
    #--- delete state variables
    unset -nocomplain ::Ibrowser($id,orderStatus)
    unset -nocomplain ::Ibrowser($id,visStatus)
    unset -nocomplain ::Ibrowser($id,opaqStatus)
    unset -nocomplain ::Ibrowser($id,holdStatus)
    unset -nocomplain ::Ibrowser($id,isEmpty)
    unset -nocomplain ::IbrowserController($id,nametextSelected)
    unset -nocomplain ::IbrowserController($id,nametextEditing)
    #--- delete drawing parameters
    unset -nocomplain ::IbrowserController($id,adaptiveUnitSpanMin)
    unset -nocomplain ::IbrowserController($id,adaptiveUnitSpanMax)        
    unset -nocomplain ::IbrowserController($id,adaptiveUnitSpan)
    unset -nocomplain ::IbrowserController($id,myUnitSpanMin)
    unset -nocomplain ::IbrowserController($id,myUnitSpanMax)    
    unset -nocomplain ::IbrowserController($id,myUnitSpan)
    unset -nocomplain ::IbrowserController($id,pixspan)
    unset -nocomplain ::IbrowserController($id,pixytop)
    unset -nocomplain ::IbrowserController($id,pixxstart)
    unset -nocomplain ::IbrowserController($id,fillCol)    
    unset -nocomplain ::IbrowserController($id,outlineCol)
    #--- delete icon image tags
    foreach imgTag $::IbrowserController(iconImageTagList) {
        unset -nocomplain ::IbrowserController($id,$imgTag) 
    }
    #--- delete icon text tags
    foreach txtTag $::IbrowserController(iconTextTagList) {
        unset -nocomplain ::IbrowserController($id,$txtTag) 
    }
    #--- delete icon highlight tags
    foreach hiloTag $::IbrowserController(iconHilightTagList) {
        unset -nocomplain ::IbrowserController($id,$hiloTag) 
    }
    #--- delete interval and drop tags
    unset -nocomplain ::IbrowserController($id,intervalHILOtag)
    unset -nocomplain ::IbrowserController($id,allDROPtag)

}



#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteIntervalVolumes
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteIntervalVolumes { id } {
    global Volume
    
    #--- id of interval to be deleted comes in.
    #--- must find the id of each volume in the interval
    #--- and delete it.
    if { $id == $::Ibrowser(FGInterval) } {
        set ::Ibrowser(FGInterval) $::Ibrowser(none,intervalID)
    } elseif { $id == $::Ibrowser(BGInterval) } {
        set ::Ibrowser(BGInterval) $::Ibrowser(none,intervalID)
    }
    if { $id == $::Ibrowser(activeInterval) } {
        IbrowserSetActiveInterval $::Ibrowser(none,intervalID)
    }
    IbrowserRaiseProgressBar
    #--- delete the MRMLVolumeNodes and MRMLDataVolumes
    for { set drop 0} { $drop < $::Ibrowser($id,numDrops) } { incr drop } {
        set i $::Ibrowser($id,$drop,MRMLid)
        MainMrmlDeleteNodeDuringUpdate "Volume" $i
        #--- volume data will get flagged for deletion when volume 
        #--- node is deleted, and then will be deleted during update.
        if { $::Ibrowser($id,numDrops) != 0 } {
            set progress [ expr double( $drop ) / double ( $::Ibrowser($id,numDrops) ) ]
            IbrowserUpdateProgressBar $progress "::"
        }
    }
    MainMrmlClearList
    MainUpdateMRML
    RenderAll
    IbrowserLowerProgressBar
}






#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteInterval { ivalName } {
    
    set id $::Ibrowser($ivalName,intervalID)
    
    #    delete the interval's icons and bar.
    #---------------
    IbrowserDeleteIntervalIcons $::Ibrowser($id,name)
    IbrowserDeleteIntervalBar $::Ibrowser($id,name)
    
    #    delete corresponding array, remove from list, delete drops
    #---------------
    #--- delete from Ibrowser's list of intervals
    IbrowserDeleteFromList $::Ibrowser($id,name) 
    IbrowserDecrementIntervalCount
    #--- delete the data
    IbrowserDeleteIntervalVolumes $id
    IbrowserDeleteIntervalDrops $::Ibrowser($id,name)
    IbrowserDeleteIntervalArray $::Ibrowser($id,name)

    #    find new global span
    #---------------    
    IbrowserUpdateGlobalXspan

    #    adjust global yspan parameters
    #---------------
    IbrowserUpdateGlobalYspan
    IbrowserUpdateVscrollRegion

    #    readjust intervals' scale
    #    to fit new global scale
    #---------------    
    IbrowserScaleIntervals $ivalName
    IbrowserUpdateHscrollregion


    #    determine the maximum number
    #    of drops in the set of remaining
    #    intervals...
    #---------------    
    IbrowserUpdateMaxDrops

    #    reorder all remaining intervals
    #---------------    
    IbrowserReorderIntervals
    IbrowserIntervalRedraw

    # update the image slider if global span has changed
    #---------------    
    IbrowserUpdateIndexAndSliderBox
    IbrowserUpdateIndexAndSliderMarker 

    #--- adjust the multivolume reader
    set cnt 0
    set del -1
    foreach name $::MultiVolumeReader(sequenceNames) {
        if { $ivalName == $name } {
            set del $cnt
        }
        incr cnt
    }
    if { $del >= 0 } {
        set ::MultiVolumeReader(sequenceNames) [ lreplace $::MultiVolumeReader(sequenceNames) $del $del ]
        unset -nocomplain ::MultiVolumeReader($ivalName,firstMRMLid)
        unset -nocomplain ::MultiVolumeReader($ivalName,lastMRMLid)        
        unset -nocomplain ::MultiVolumeReader($ivalName,volumeExtent)
        unset -nocomplain ::MultiVolumeReader($ivalName,noOfVolumes)
    }

    
    #--- report in Ibrowser's message panel"
    set tt "Deleted interval $ivalName."
    IbrowserSayThis $tt 0
    
    #--- if just the none interval is left,
    #--- reconfigure all sliders
    if { $::IbrowserController(Info,Ival,ivalCount) == 1 } {
        IbrowserSynchronizeAllSliders "disabled"
    }

    IbrowserCleanUpEmptyTransformNodes
    MainUpdateMRML
}




#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteAllIntervals
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteAllIntervals { } {
    
    foreach id $::Ibrowser(idList) {
        IbrowserDeleteInterval $::Ibrowser($id,name)
    }
    
    IbrowserInitCanvasSizeAndScrollRegion
    set ::IbrowserController(Info,Ival,firstIval) 1

    #--- if number if intervals is 0,
    #--- reconfigure all sliders
    IbrowserSynchronizeAllSliders "disabled"
}





#-------------------------------------------------------------------------------
# .PROC IbrowserUpdateMaxDrops
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUpdateMaxDrops { } {

    #--- first, search thru all intervals and see who has most drops
    set ::Ibrowser(MaxDrops) 0
    foreach id $::Ibrowser(idList) {
        set name $::Ibrowser($id,name)
        if { $::Ibrowser(MaxDrops) < $::Ibrowser($id,numDrops) } {
            set ::Ibrowser(MaxDrops) $::Ibrowser($id,numDrops)
        }
    }

    #--- if maxdrops has decreased below value of current viewdrop,
    #--- reset the current viewdrop to zero.
    #--- (if MaxDrops is N, ViewDrop goes from 0 to N-1)
    if { [ expr $::Ibrowser(ViewDrop) + 1] > $::Ibrowser(MaxDrops) } {
        #--- change the index to fit new intervals
        set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
        set ::Ibrowser(ViewDrop) 0
    } 
    
    #--- update the active range of all sliders
    set top [ expr $::Ibrowser(MaxDrops) - 1 ]
    IbrowserSynchronizeAllSliders $top
}



#-------------------------------------------------------------------------------
# .PROC IbrowserInitNewInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInitNewInterval { newname } {

    set id $::Ibrowser(uniqueNum)
    #--- get the new interval started.
    set ::Ibrowser($id,name) $newname
    set ::Ibrowser($newname,intervalID) $id
    return $id
    
}




#-------------------------------------------------------------------------------
# .PROC IbrowserMakeNoneInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeNoneInterval { } {
    set ival "none"
    set ival $::Ibrowser(${::Ibrowser(idNone)},name)
    set w $::Ibrowser(initIntervalWid)
    if { [ IbrowserUniqueNameCheck $ival ] } {
        IbrowserMakeNewInterval $ival $::IbrowserController(Info,Ival,imageIvalType) 0.0 $w 0
    }

    #--- if none volume is in Foreground in all slice windows
    #--- set the none interval to be the FGInterval
    set tst 1
    foreach s $::Slice(idList) {
        if {$::Slice($s,foreVolID) != $::Volume(idNone) } { set tst 0 }
    }
    if { $tst } {IbrowserSetFGInterval $::Ibrowser(idNone) }
    
    #--- if none volume is in Background in all slice windows
    #--- set the none interval to be the BGInterval
    set tst 1
    foreach s $::Slice(idList) {
        if {$::Slice($s,backVolID) != $::Volume(idNone) } { set tst 0 }
    }
    if { $tst } {IbrowserSetBGInterval $::Ibrowser(idNone) }
}





#-------------------------------------------------------------------------------
# .PROC IbrowserSetActiveInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetActiveInterval { id } {
    
    IbrowserDeselectActiveInterval $::IbrowserController(Icanvas)
    set ::Ibrowser(activeInterval) $id
    IbrowserSelectActiveInterval $id $::IbrowserController(Icanvas)
    IbrowserUpdateMRML

}



#-------------------------------------------------------------------------------
# .PROC IbrowserSetFGInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetFGInterval { id } {

    IbrowserDeselectFGIcon $::IbrowserController(Icanvas)
    #if { $id != $::Ibrowser(NoInterval) } 
        IbrowserSlicesSetVolumeAll Fore $::Ibrowser($id,$::Ibrowser(ViewDrop),MRMLid)
        IbrowserSelectFGIcon $id $::IbrowserController(Icanvas)
    # end if
    set ::Ibrowser(FGInterval) $id
}



#-------------------------------------------------------------------------------
# .PROC IbrowserSetBGInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetBGInterval { id } {

    IbrowserDeselectBGIcon $::IbrowserController(Icanvas)
   # if { $id != $::Ibrowser(NoInterval)} 
        IbrowserSlicesSetVolumeAll Back $::Ibrowser($id,$::Ibrowser(ViewDrop),MRMLid)
        IbrowserSelectBGIcon $id $::IbrowserController(Icanvas)
        #IbrowserGangFGandBGVisibility
    # end if
    set ::Ibrowser(BGInterval) $id
}



#-------------------------------------------------------------------------------
# .PROC IbrowserMakeNewInterval
# Called to create the default startup interval, or whenever
# a user has requested a new one be created.  This proc is
# passed the new name of the interval, the type of interval
# requested, the layer order, and the min and max values
# of its span *in pixels*. If a user hasn't specified these
# parameters, default values are assigned and passed in.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserMakeNewInterval { intval ikind spanmin spanmax numDrops } {
    
    # For first interval, need to set up some
    # conversion factors for redrawing the canvas
    #---------------
    if { $::IbrowserController(Info,Ival,firstIval) } {
        IbrowserSetInitialPixelsPerUnit $spanmin $spanmax
        set ::IbrowserController(Info,Ival,firstIval) 0
    }

    #------------------ GLOBAL BOOKKEEPING ------------------------------
    # First, add the newly named interval to
    # the global list of intervals
    #---------------
    #--- update name and idList
    set id $::Ibrowser(uniqueNum)
    incr ::Ibrowser(uniqueNum)
    #--- for getting id from name and name from id.
    set ::Ibrowser($intval,intervalID) $id
    set ::Ibrowser($id,name) $intval

    IbrowserAddToList $intval

    # Fill toplevel array with with the interval's properties.
    # First set interval's basic info and default status
    # The first interval has order #0.
    #---------------    
    set ::Ibrowser($id,name) $intval
    set ::Ibrowser($id,type) $ikind
    set ::Ibrowser($id,opacity) 1.0
    set ::Ibrowser($id,order) $::IbrowserController(Info,Ival,ivalCount) 
    
    # and increment the interval Count.
    #---------------
    IbrowserIncrementIntervalCount

    #------------------ CANVAS MANAGEMENT -----------------------------
    # Compute interval's span in user-specified units
    # increase the span a bit so all samples
    # fit inside. adaptiveUnitSpanMax, adaptiveUnitSpanMin, and adaptiveUnitSpan
    # will get scaled when the global interval grows.
    #---------------        
    set vlist [ IbrowserPuffUpSpan $spanmin $spanmax ]
    set ::IbrowserController($id,adaptiveUnitSpanMin) [ lindex $vlist 0 ]
    set ::IbrowserController($id,adaptiveUnitSpanMax) [ lindex $vlist 1 ]
    set ::IbrowserController($id,adaptiveUnitSpan) [ lindex $vlist 2 ]
   
    # myUnitSpanMin, myUnitSpanMax and myUnitSpan are 
    # each interval's remembered actual unit span, which are 
    # used to scale the intervals back down when global
    # span shrinks.
    #---------------        
    set ::IbrowserController($id,myUnitSpanMin) [ lindex $vlist 0 ]
    set ::IbrowserController($id,myUnitSpanMax) [ lindex $vlist 1 ]
    set ::IbrowserController($id,myUnitSpan) [ lindex $vlist 2 ]

    set ::Ibrowser($id,numDrops) 0
    set myspan [ expr $::IbrowserController($id,adaptiveUnitSpanMax) - $::IbrowserController($id,adaptiveUnitSpanMin) ]

    # Update global span (across all intervals)
    #---------------        
    IbrowserUpdateGlobalXspan 

    # Now convert to pixels
    # and save pixel span.
    #---------------
    set mypixspan [ IbrowserUnitSpanToPixelSpan $myspan ]
    set ::IbrowserController($id,pixspan) $mypixspan

    # Compute interval's drawing params
    # (in actual pixel values)
    #---------------        
    set ::IbrowserController($id,pixxstart)  $::IbrowserController(Info,Ival,globalIvalPixXstart)
    set ::IbrowserController($id,fillCol) [ IbrowserGetIntervalFillCol $ikind ]
    set ::IbrowserController($id,outlineCol) [ IbrowserGetIntervalOutlineCol $ikind ]
    set oCount [ IbrowserGetIntervalCount ]
    set ::IbrowserController($id,pixytop) [ IbrowserComputeIntervalYtop $oCount]
    set ::IbrowserController(Geom,Icon,iconYstart) $::IbrowserController($id,pixytop)

    # Reconfigure vertical scrollregion if required
    #---------------        
    IbrowserUpdateGlobalYspan 
    IbrowserUpdateVscrollRegion    

    # Initialize interval's state (relflected also by icons)
    #---------------        
    set ::Ibrowser($id,orderStatus) $::Ibrowser($id,order)
    #--- check to see Slice window settings first. Visible or not?
    
    set ::Ibrowser($id,visStatus) $::IbrowserController(Info,Ival,isVisible)
    set ::Ibrowser($id,holdStatus) $::IbrowserController(Info,Ival,hold)
    set ::Ibrowser($id,isEmpty) 1 
    set ::IbrowserController($id,ivalRECTtag) ${id}_IvalRECT

    #--- Tag all icon images, icon text and icon highlights.
    #--- (so we can manipulate or reconfigure them on canvas.)
    foreach imgTag $::IbrowserController(iconImageTagList) {
        set ::IbrowserController($id,$imgTag) ${id}_${imgTag}
    }
    foreach txtTag $::IbrowserController(iconTextTagList) {
        set ::IbrowserController($id,$txtTag) ${id}_${txtTag}
    }
    foreach hiloTag $::IbrowserController(iconHilightTagList) {
        set ::IbrowserController($id,$hiloTag) ${id}_${hiloTag}
    }

    # Tag the drops within an interval and the interval itself.
    #--- (so we can manipulate or reconfigure them on canvas.)
    #---------------
    set ::IbrowserController($id,allDROPtag) ${id}_dropTAG
    set ::IbrowserController($id,intervalHILOtag)      ${id}_HILO
    
    #---what drop are we currently indexing and
    #---looking at in the MainViewer?
    #---------------    
    set ::Ibrowser(LastViewDrop) $::Ibrowser(ViewDrop)
    set ::Ibrowser(ViewDrop) 0

    #size, draw the interval, its icons and hitlite outline
    #---------------    
    IbrowserCreateIcons $::Ibrowser($id,name)
    IbrowserCreateIntervalBar $::Ibrowser($id,name)

    IbrowserScaleIntervals $::Ibrowser($id,name)
    IbrowserUpdateHscrollregion

    #---sets flag which controls editable nametext in the icon.
    #---and flag that marks whether text is currently being edited.
    set ::IbrowserController($id,nametextSelected) 0
    set ::IbrowserController($id,nametextEditing) 0
    
    # create or update the image slider if global span has changed
    #---------------    
    IbrowserUpdateIndexAndSliderBox 
    IbrowserUpdateIndexAndSliderMarker 


    #---------------- ADD DROPS ---------------------------------------
    #--- For now, fill a position array with the
    #--- time point that each drop represents.
    #--- Assume the interval is m units long.
    #--- how many files do we have?
    set ::Ibrowser($id,numDrops) $numDrops
    if { $numDrops > 0 } {
        for {set zz 0} {$zz < $numDrops} { incr zz} {
            set posVec($zz) $zz
        }
        IbrowserCreateImageDrops $::Ibrowser($id,name) posVec $::Ibrowser($id,numDrops)
    
        #--- reconfigure all Sliders
        IbrowserUpdateMaxDrops
        IbrowserSynchronizeAllSliders "active"

        #--- display the first volume
        #--- make it the active volume
        #--- and put it in the background
        #--- as is the loading convention.
        #------------------ UPDATE & RENDER ---------------------------------
        IbrowserDeselectBGIcon $::IbrowserController(Icanvas)        
        IbrowserSlicesSetVolumeAll Back $::Ibrowser($id,0,MRMLid)
        MainVolumesSetActive $::Ibrowser($id,0,MRMLid)
        MainUpdateMRML
        RenderAll
        IbrowserSetActiveInterval $id
        set ::Ibrowser(BGInterval) $id
        IbrowserSelectBGIcon $id $::IbrowserController(Icanvas)
        puts ""
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalAdaptiveUnitSpan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalAdaptiveUnitSpan { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::IbrowserController($id,adaptiveUnitSpan)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalAdaptiveUnitXmin
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalAdaptiveUnitXmin { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::IbrowserController($id,adaptiveUnitSpanMin)

}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalAdaptiveUnitXmax
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalAdaptiveUnitXmax { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::IbrowserController($id,adaptiveUnitSpanMax)

}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalFillCol
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalFillCol { type } {
    
    return $::IbrowserController(Info,Ival,fillCol${type})
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalOutlineCol
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalOutlineCol { type } {
    
    return $::IbrowserController(Info,Ival,outlineCol${type})
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalOrderStatus
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalOrderStatus { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::Ibrowser($id,orderStatus)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalVisStatus
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalVisStatus { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::Ibrowser($id,visStatus)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalOpaqStatus
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalOpaqStatus { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::Ibrowser($id,opaqStatus)
}




#-------------------------------------------------------------------------------
# .PROC IbrowserSetIntervalOrder
#Called when someone changes an interval's order.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSetIntervalOrder { ivalName order } {

    set id $::Ibrowser($ivalName,intervalID)
    set ::Ibrowser($id,order) $order
}



#-------------------------------------------------------------------------------
# .PROC IbrowserInsertIntervalAfterInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInsertIntervalAfterInterval { putThis afterThis } {
    
    set thisID $::Ibrowser($putThis,intervalID)
    set afterID $::Ibrowser($afterThis,intervalID)

    # If you couldn't find one of those intervals,
    # mark an error; otherwise, reorder.
    #---------------
    # Then, find the order we want to reassign
    # this interval
    #---------------
    set thisOrder  $::Ibrowser($thisID,order)
    set afterOrder $::Ibrowser($afterID,order)

    #If we are moving an interval's order up in value,
    #all intervals between this and after will have
    #their orders decreased by one.
    #---------------    
    if { $thisOrder < $afterOrder } {
        foreach id $::Ibrowser(idList) {
            # all intervals between this and after
            # get their order value decremented.
            #---------------    
            if { ($::Ibrowser($id,order) > $thisOrder) &&  ($::Ibrowser($id,order) <= $afterOrder) } {
                IbrowserDecrementIntervalOrder $::Ibrowser($id,name)
            }
        }
        #Finally, change its order
        #---------------    
        IbrowserSetIntervalOrder $::Ibrowser($thisID,name) $afterOrder
        
        #If we are moving an interval's order down in
        #value, all intervals between this and after will 
        #have their orders increased by one.
        #---------------    
    } elseif { $thisOrder > $afterOrder } {
        foreach id $::Ibrowser(idList) {
            # all intervals between this and after
            # get their order value incremented.
            #---------------    
            if { ($::Ibrowser($id,order) > $afterOrder) &&  ($::Ibrowser($id,order) < $thisOrder) } {
                IbrowserIncrementIntervalOrder $::Ibrowser($id,name)
            }
        }
        #Finally, change its order
        #---------------    
        IbrowserSetIntervalOrder $::Ibrowser($thisID,name) [expr $afterOrder + 1 ]
    }

    #Resort the Ibrowser(idList) and redraw
    #---------------
    IbrowserOrderSortIntervalList
    IbrowserIntervalRedraw

}






#-------------------------------------------------------------------------------
# .PROC IbrowserInsertIntervalBeforeInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserInsertIntervalBeforeInterval { putThis beforeThis } {
    
    set thisID $::Ibrowser($putThis,intervalID)
    set beforeID $::Ibrowser($beforeThis,intervalID)

    # If you couldn't find one of those intervals,
    # mark an error; otherwise, reorder.
    #---------------
    # Then, find the order we want to reassign
    # this interval
    #---------------
    set thisOrder  $::Ibrowser($thisID,order)
    set beforeOrder $::Ibrowser($beforeID,order)

    #If we are moving an interval's order up in value,
    #all intervals between this and before will have
    #their orders decreased by one.
    #---------------    
    if { $thisOrder < $beforeOrder } {
        foreach id $::Ibrowser(idList) {
            # all intervals between this and before
            # get their order value decremented.
            #---------------    
            if { ($::Ibrowser($id,order) > $thisOrder) &&  ($::Ibrowser($id,order) < $beforeOrder) } {
                IbrowserDecrementIntervalOrder $::Ibrowser($id,name)
            }
        }
        #Finally, change its order
        #---------------    
        IbrowserSetIntervalOrder $::Ibrowser($thisID,name) [ expr $beforeOrder - 1 ]
        
        #If we are moving an interval's order down in
        #value, all intervals between this and before will 
        #have their orders increased by one.
        #---------------    
    } elseif { $thisOrder > $beforeOrder } {
        foreach id $::Ibrowser(idList) {
            # all intervals between this and before
            # get their order value incremented.
            #---------------    
            if { ($::Ibrowser($id,order) >= $beforeOrder) &&  ($::Ibrowser($id,order) < $thisOrder) } {
                IbrowserIncrementIntervalOrder $::Ibrowser($id,name)
            }
        }
        #Finally, change its order
        #---------------    
        IbrowserSetIntervalOrder $::Ibrowser($thisID,name) $beforeOrder
    }

    #Resort the Ibrowser(idList) and redraw
    #---------------
    IbrowserOrderSortIntervalList
    IbrowserIntervalRedraw
}




#-------------------------------------------------------------------------------
# .PROC IbrowserReorderIntervals
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserReorderIntervals { } {

    IbrowserOrderSortIntervalList

    set count 0
    foreach id $::Ibrowser(idList) {
        set ::Ibrowser($id,order) $count
        set ::Ibrowser($id,orderStatus) $count
        incr count
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserOrderSortIntervalList
# Sorts the list of interval names based on the interval's
# order, putting interval with order=1 first.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserOrderSortIntervalList { } {

    if { [ info exists ::Ibrowser(idList) ] } {
        set ::Ibrowser(idList) [ lsort -command IbrowserOrderCompare $::Ibrowser(idList) ]
    }
}




#-------------------------------------------------------------------------------
# .PROC IbrowserIncrementIntervalOrder
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserIncrementIntervalOrder { iName } {
    
    set id $::Ibrowser($iName,intervalID)
    
    set ::Ibrowser($id,order) [ expr $::Ibrowser($id,order) + 1 ]
    #used for text in the interval's icon
    set ::Ibrowser($id,orderStatus) $::Ibrowser($id,order)
}




#-------------------------------------------------------------------------------
# .PROC IbrowserDecrementIntervalOrder
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDecrementIntervalOrder { iName } {
    
    set id $::Ibrowser($iName,intervalID)
    
    set ::Ibrowser($id,order) [ expr $::Ibrowser($id,order) - 1 ]
    #used for text in the interval's icon
    set ::Ibrowser($id,orderStatus) $::Ibrowser($id,order)
}






#-------------------------------------------------------------------------------
# .PROC IbrowserRenameInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserRenameInterval { old new } {

    #--- rename all the stuff that refers to this interval
    #--- according to its new name...
    set id $::Ibrowser($old,intervalID)
    set ::Ibrowser($id,name) $new
    #--- and rename the array element that
    #--- derives the intervalID from the name
    unset ::Ibrowser($old,intervalID)
    set ::Ibrowser($new,intervalID) $id

    #--- rename all the volumes in interval.
    set first $::Ibrowser($id,firstMRMLid)
    set last $::Ibrowser($id,lastMRMLid)
    set i 0

    for { set vid $first } { $vid <= $last } { incr vid} {
        #::Volume($vid,node) SetName ${new}_${i}_${old}
        #::Volume($vid,node) SetName ${old}_${new}
        set vname [ ::Volume($vid,node) GetName]
        set cc [ string last $old $vname]
        #--- trim off the underbar and replace, if name is found.
        if { $cc > 0 } {
            set cc [ expr $cc - 2 ]
            set vname [ string range $vname 0 $cc ]
            ::Volume($vid,node) SetName ${vname}_${new}
        }
        incr i
    }

    #--- adjust the multivolume reader where all sequences
    #--- are stored and referred to by other modules (fmriengine)
    set cnt 0
    set change -1
    foreach name $::MultiVolumeReader(sequenceNames) {
        if { $old == $name } {
            set change $cnt
        }
        incr cnt
    }
    #--- replace 
    if { $change >= 0 } {
        set ::MultiVolumeReader(sequenceNames) [ lreplace $::MultiVolumeReader(sequenceNames) \
                                                     $change $change $new ]
        set ::MultiVolumeReader($new,noOfVolumes) $::MultiVolumeReader($old,noOfVolumes)
        unset -nocomplain ::MultiVolumeReader($old,noOfVolumes)
        set ::MultiVolumeReader($new,firstMRMLid) $::MultiVolumeReader($old,firstMRMLid)
        unset -nocomplain ::MultiVolumeReader($old,firstMRMLid)
        set ::MultiVolumeReader($new,lastMRMLid) $::MultiVolumeReader($old,lastMRMLid)
        unset -nocomplain ::MultiVolumeReader($old,lastMRMLid)    
        set ::MultiVolumeReader($new,volumeExtent) $::MultiVolumeReader($old,volumeExtent)
        unset -nocomplain ::MultiVolumeReader($old,volumeExtent)
    }
    
    MainUpdateMRML
}



#-------------------------------------------------------------------------------
# .PROC IbrowserUniqueNameCheck
# Each new interval must have a unique name..
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserUniqueNameCheck { iName } {
    
    set check [ info exists ::Ibrowser(idList) ]

    if {  $check   } {
        # Search thru interval list for interval
        # with the same name already....
        #---------------
        foreach id $::Ibrowser(idList) {
            if { $::Ibrowser($id,name) == $iName } {
                # woops; name's already in use in Ibrowser.
                set tt "$iName is already in use. Please try another name!"
                IbrowserSayThis $tt 1
                return 0
            }
        }
        # Search global namespace to
        # see if interval name conflicts....
        #---------------
        if { [ info exists ::$iName ] } {
            # woops; name's in the global namespace
            set tt "$iName is used internally by Slicer. Please try another name!"
            IbrowserSayThis $tt 1
            return 0
        }
        # Good! name is unique.
        #---------------
        return 1
    } else {
        return 1
    }
}


#-------------------------------------------------------------------------------
# .PROC IbrowserPuffUpSpan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserPuffUpSpan { unitmin unitmax } {
    
    #now grow the interval span slightly so that
    #its first and last samples don't sit right
    #on the edge of the bar that represents it in
    #the interface -- so there's room to draw the
    #first and last interval Drops.
    #We leave an icon-width of room.
    #---------------
    set dropWidth $::IbrowserController(Geom,Icon,iconWid)
    set ppx $::IbrowserController(Geom,Icanvas,pixPerUnitX)
    set extraBuf [expr $dropWidth / $ppx ]
    set umin [expr $unitmin - $extraBuf ]
    set umax [expr $unitmax + $extraBuf ]
    set unitspan [ expr $umax - $umin ]

    if { 0 } {
        #reset canvas pixels per unit -- maybe not?
        #---------------
        set ppx [ expr $::IbrowserController(Geom,Ival,defaultPixWid) / $unitspan ]
        set ::IbrowserController(Geom,Icanvas,pixPerUnitX) $ppx
        set ::IbrowserController(Geom,Ccanvas,pixPerUnitX) $ppx
    }

    set vlist " $umin $umax $unitspan "
    return $vlist


}


#-------------------------------------------------------------------------------
# .PROC 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc  IbrowserMoveIntervalRect { Iname oldy newy} {
    
    set id $::Ibrowser($Iname,intervalID)
    
    #move interval by yy
    #---------------    
    set yy [ expr $newy - $oldy ]
    if { $yy != 0 } {
        set ivalrect  ${id}_IvalRECT
       $::IbrowserController(Icanvas) move $ivalrect 0 $yy
    }
}







#-------------------------------------------------------------------------------
# .PROC IbrowserScaleIntervals
# This routine gets called whenever globalIvalPixSpan changes
# because a larger new interval has just been created or deleted.
# resizeIntervals looks at the new globalIvalPixSpan and either
# scales all intervals' GUIs onscreen to span the horizontal space.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserScaleIntervals { newName } {

    # Find new global pixspan 
    #---------------
    set gspan $::IbrowserController(Info,Ival,globalIvalPixSpan)
    
    # half of that global pixspan?
    #---------------
    set halfgspan [ expr $gspan / 2.0 ]
    
    # Find the absolute pixel value of
    # half of the new global pixspan
    # This should be the scaling origin.
    #---------------
    set gcenter [ expr $::IbrowserController(Info,Ival,globalIvalPixXstart) + $halfgspan ]

    #Check all in the list of interval names
    #to see who needs resizing.
    #---------------
    foreach id $::Ibrowser(idList) {

        # find this interval's pixel span
        #---------------        
        set ppu $::IbrowserController(Geom,Icanvas,pixPerUnitX)
        set uspan $::IbrowserController($id,adaptiveUnitSpan)
        set thisspan [ expr $uspan * $ppu ]

        # if this interval's pixspan is smaller
        # than the global span set by the new
        # interval, then resize this interval's track.
        # Don't compare the new interval to itself.
        #---------------                
        if { $thisspan != $gspan } {
            # find half of this interval's pixspan
            #---------------
            set halfthisspan [ expr $thisspan / 2.0 ]
            
            # find how much to scale this interval
            #---------------
            set scalefactor [ expr $gspan / $thisspan ]
            
            # find how much to move this interval
            # prior to scale
            #---------------
            set centeroffset [ expr $halfgspan - $halfthisspan ]
            set ivalrect  $::IbrowserController($id,ivalRECTtag)
            
            # Align center of this interval to center
            # of global span
            #---------------
            $::IbrowserController(Icanvas) move  $ivalrect $centeroffset 0.0

            # scale this interval to match global span
            #---------------
            $::IbrowserController(Icanvas) scale $ivalrect $gcenter 0.0 $scalefactor 1.0
            
            # UPdate this interval's AdaptiveUnitSpan and
            # adaptiveUnitSpanMin and adaptiveUnitSpanMax
            #---------------
            set ::IbrowserController($id,adaptiveUnitSpan) $::IbrowserController(Info,Ival,globalIvalUnitSpan)
            set ::IbrowserController($id,adaptiveUnitSpanMin) $::IbrowserController(Info,Ival,globalIvalUnitSpanMin)
            set ::IbrowserController($id,adaptiveUnitSpanMax) $::IbrowserController(Info,Ival,globalIvalUnitSpanMax)
            set ::IbrowserController($id,pixspan) [ IbrowserUnitSpanToPixelSpan $::IbrowserController($id,adaptiveUnitSpan) ]
        }
    }
}






#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalName
# Ok, so this is a little redundant, but...
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalName { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $Ibrowser($id,name)
}



#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalOrder
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalOrder { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::Ibrowser($id,order)
}



#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalType
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalType { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::Ibrowser($id,type)
}



#-------------------------------------------------------------------------------
# .PROC IbrowserCreateIntervalBar
#  Creates the rect that demarcates the interval;
#  Clicking on the rect makes that interval active.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserCreateIntervalBar { ivalname } {

    set id $::Ibrowser($ivalname,intervalID)
    
    #draw the interval and hitlite outline
    #---------------    
    set ix $::IbrowserController($id,pixxstart) 
    set iy $::IbrowserController($id,pixytop) 
    set sp $::IbrowserController($id,pixspan)
    if { $ivalname == "none" } {
        set fc #CCCCCC
    } else {
        set fc $::IbrowserController($id,fillCol) 
    }
    #--- configure color to indicate active or inactive interval
    if { $id == $::Ibrowser(activeInterval) } {
        set oc $::IbrowserController(Info,Ival,outlineActive) 
    } else {
        set oc $::IbrowserController($id,outlineCol)
    }

    set iID [ $::IbrowserController(Icanvas) create rect  $ix $iy  [expr $ix + $sp] \
                  [ expr $iy + $::IbrowserController(Geom,Ival,intervalPixHit) ] \
                  -fill $fc -outline $oc \
                  -tags "ival $::IbrowserController($id,ivalRECTtag)" ]
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,ivalRECTtag) <Enter> \
        "set ::IbrowserController(IcanvasWindow) %W;
             %W itemconfig $::IbrowserController($id,ivalRECTtag) -outline $::IbrowserController(Colors,hilite)"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,ivalRECTtag) <Leave> \
        " IbrowserLeaveIntervalBar $id %W"
    $::IbrowserController(Icanvas) bind $::IbrowserController($id,ivalRECTtag) <Button-1> \
        "IbrowserDeselectActiveInterval %W;
             IbrowserSetActiveInterval $id;
             MainVolumesSetActive $::Ibrowser($id,$::Ibrowser(ViewDrop),MRMLid)"
}




#-------------------------------------------------------------------------------
# .PROC IbrowserDeselectActiveInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeselectActiveInterval { w } {

    #deselect old active interval
    foreach id $::Ibrowser(idList) {
        if { $id == $::Ibrowser(activeInterval) } {
            $w itemconfig $::IbrowserController($id,ivalRECTtag) \
                -outline $::IbrowserController($id,outlineCol)
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC IbrowserSelectActiveInterval
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserSelectActiveInterval { id w } {

    #--- note: "none" is active by default at startup.
    $w itemconfig $::IbrowserController($id,ivalRECTtag) \
        -outline $::IbrowserController(Info,Ival,outlineActive)
}




#-------------------------------------------------------------------------------
# .PROC IbrowserLeaveIntervalBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserLeaveIntervalBar { id w } {


    set name $::Ibrowser($id,name)
    upvar #0 $name ival

    #--- if not active, or if 'none' is active, reset normal color.
    #--- otherwise, highlight as active.
    if { $id != $::Ibrowser(activeInterval) } {
        $w itemconfig $::IbrowserController($id,ivalRECTtag) \
            -outline $::IbrowserController($id,outlineCol)
    } else {
        $w itemconfig $::IbrowserController($id,ivalRECTtag) \
            -outline $::IbrowserController(Info,Ival,outlineActive) 
    }

}


#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteIntervalBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteIntervalBar { ivalname } {

    set id $::Ibrowser($ivalname,intervalID)
    $::IbrowserController(Icanvas) delete $::IbrowserController($id,ivalRECTtag)
}





#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalDrop
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalDrop { ivalName whichDrop } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::Ibrowser($id,drop,$whichDrop)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalPixSpan
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalPixSpan { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)    
    return $::IbrowserController($id,pixspan)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalPixYtop
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalPixYtop { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)    
    return $::IbrowserController($id,pixytop)
}


#-------------------------------------------------------------------------------
# .PROC IbrowserGetIntervalPixXstart
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserGetIntervalPixXstart { ivalName } {

    set id $::Ibrowser($ivalName,intervalID)
    return $::IbrowserController($id,pixxstart)
}

