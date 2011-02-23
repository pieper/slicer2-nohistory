#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: NestedList.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:05 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        NestedList.tcl
# PROCEDURES:  
#   ::NestedList::getValue v selector defaultVal
#   ::NestedList::getValue
#   ::NestedList::hasKey v selector
#   ::NestedList::hasKey
#   ::NestedList::getOptions v selector
#   ::NestedList::getOptions
#   ::NestedList::setValue v selector selectedValue
#   ::NestedList::setValue
#   ::NestedList::_example
#==========================================================================auto=

# NestedLists are a hierarchical data structure in Tcl, made up of
# ordinary lists.   NestedLists consist of  key/value pairs, where 
# values may be lists of other lists.  For example, here's a NestedList:
#
# one {
#       two 2
#       three 3
#       four {
#             five five-five
#       }
#
# The functions here provide access to elements of NestedLists.  Selectors
# are just paths to elements.  For example, the selector {one two} identifies
# the value "2" in the above list, while the selector {one four} 
# selects {five five-five}.
# 
# getValue returns the value identified by a selector (or defaultVal if
# the list doesn't have the selector's path).
#
# hasKey is like getValue, but returns 1 if the selected path is valid
# (points to a value), and 0 if it doesn't.
#
# getOptions is similar to getValue, but returns a list of keys just below
# the selected path.  For instance, the selector {one} would yield the
# options {two three four} for the list above.
#
# setValue returns a new NestedList with the selected path and value replaced
# or inserted.  For example, setting the value of path {one three} to "wow"
# would return a new NestedList with 3 being replaced by "wow".  setValue
# will always succeed;  if any part of a path doesn't exist it will be
# created.  The values of a setValue call can, of course, themselves be
# NestedLists.  This allows lists to be built up incrementally.
#
# Michael Halle
# mhalle@bwh.harvard.edu
# version 1.0 - October 27, 2002
#

package provide NestedList 1.0

namespace eval ::NestedList {
    namespace export getValue getOptions setValue hasKey
}

#-------------------------------------------------------------------------------
# .PROC ::NestedList::getValue

# Get the value of a path from a NestedList.  If the path is invalid,
# the defaultVal is returned.
# .ARGS
# list v NestedList to search
# list selector path to traverse
# str defaultVal if the path is invalid, return this value instead
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC ::NestedList::getValue
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ::NestedList::getValue {v {selector {}} {defaultVal ""}} {
    if {[llength $selector] == 0} {
        return $v
    } else {
        # look for a match for the first arg in $selector in v
        set a [lindex $selector 0]
        if {$a == ""} {
            return $v
        }
        foreach {key value} $v {
            if {"$key" == "$a"} {
                return [::NestedList::getValue $value [lrange $selector 1 end] $defaultVal]
            }
        }
        return $defaultVal
    }
}
#-------------------------------------------------------------------------------
# .PROC ::NestedList::hasKey

# Check to see if the selector path is valid (points to a value).
# Returns 1 if it does, 0 if it doesn't.
# .ARGS
# list v NestedList to search
# list selector path to traverse
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC ::NestedList::hasKey
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ::NestedList::hasKey {v {selector {}}} {
    if {[llength $selector] == 0} {
        return 1
    } else {
        # look for a match for the first arg in $selector in v
        set a [lindex $selector 0]
        if {$a == ""} {
            return 1
        }
        foreach {key value} $v {
            if {"$key" == "$a"} {
                return [::NestedList::getValue $value [lrange $selector 1 end]]
            }
        }
        return 0
    }
}

#-------------------------------------------------------------------------------
# .PROC ::NestedList::getOptions
#
# Returns the list keys available below a path, or an empty list if the
# path isn't valid.
#
# .ARGS
# list v NestedList to search
# list selector path to traverse
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC ::NestedList::getOptions
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ::NestedList::getOptions {v {selector {}}} {
    if {[llength $selector] == 0} {
        set ret {}
        foreach {key value} $v {
            lappend ret $key
        }
        return $ret
    } else {
        # look for a match for the first arg in $selector in v
        set a [lindex $selector 0]
        if {$a == {}} {
            return $v
        }
        foreach {key value} $v {
            if {"$key" == "$a"} {
                return [::NestedList::getOptions $value [lrange $selector 1 end]]
            }
        }
        return {}
    }
}

#-------------------------------------------------------------------------------
# .PROC ::NestedList::setValue
#
#  Returns a new NestedList with a new value (selectedValue) replaced or
#  added at the path selected by the selector.  If needed, new levels of
#  hierarchy will be added to the NestedList.
# .ARGS
# list v NestedList to search
# list selector path to traverse
# str selectedValue the value to place in the new list at the selected path
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC ::NestedList::setValue
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ::NestedList::setValue {v selector selectedValue} {
    if {[llength $selector] == 0} {
        return $selectedValue
    } else {
        # look for a match for the first arg in $selector in v
        set a [lindex $selector 0]
        if {$a == ""} {
            return $selectedValue
        }
        set gotmatch 0
        set newv {}
        foreach {key value} $v {
            if {"$key" == "$a"} {
                set value [::NestedList::setValue $value \
                               [lrange $selector 1 end] $selectedValue]
                set gotmatch 1
                
            }
           lappend newv $key $value
        }
        if {! $gotmatch} {
            lappend newv $a [::NestedList::setValue {} \
                                 [lrange $selector 1 end] $selectedValue]
        }
        return $newv
    }
}

#-------------------------------------------------------------------------------
# .PROC ::NestedList::_example
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ::NestedList::_example {} {
    set nl { 
        one {
            two 2
            three 3
            four {
                five five-five
            }
        }
    }

    puts [::NestedList::getValue $nl {one two}]
    # 2

    puts [::NestedList::getValue $nl {one four}]
    # {five five-five}

    puts [::NestedList::getOptions $nl one]
    # {two three four}

    puts [::NestedList::hasKey $nl two]
    # 0 (since there's no key named "two" at the top level of the list)

    puts [::NestedList::setValue $nl {one three} three]
    # {one { two 2 three three four {five five-five}}}

}
