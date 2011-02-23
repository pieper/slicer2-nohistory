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
# FILE:        IbrowserControllerArrayList.tcl
# PROCEDURES:  
#   IbrowserAddToList
#   IbrowserOrderCompare
#   IbrowserDeleteFromList
#==========================================================================auto=





#-------------------------------------------------------------------------------
# .PROC IbrowserAddToList
# Adds an element to a list.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserAddToList { Aname } {

    #--- move to this list
    set id $::Ibrowser($Aname,intervalID)
    lappend ::Ibrowser(idList) $id

}




#-------------------------------------------------------------------------------
# .PROC IbrowserOrderCompare
# Used to sort the list of interval names
# based on their orders; from lowest to highest.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserOrderCompare { a b } {
    
    set idA $a
    set idB $b

    if { ( [info exists ::Ibrowser($idA,order) ] ) && ( [ info exists ::Ibrowser($idB,order) ] ) } {
        set q $::Ibrowser($idA,order)
        set qq $::Ibrowser($idB,order)

        if { $q > $qq } {
            return 1
        } else {
            return -1
        }
    } else {
        return -1
    }

}





#-------------------------------------------------------------------------------
# .PROC IbrowserDeleteFromList
# Deletes arrayname from list, and
# then deletes the array too
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc IbrowserDeleteFromList { ival } {
    
    set id $::Ibrowser($ival,intervalID)
    
    # find the list item
    set ix [ lsearch -exact $::Ibrowser(idList) $id ]

    #delete it; otherwise, return orig list
    if { $ix >= 0 } {
        set ::Ibrowser(idList) [ lreplace $::Ibrowser(idList) $ix $ix ]
    } else {
        set tt "IbrowserDeleteFromList: can't find $ival in interval list. Not deleted."
    }

}



