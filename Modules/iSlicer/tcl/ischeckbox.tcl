#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ischeckbox.tcl,v $
#   Date:      $Date: 2006/05/26 19:18:43 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        ischeckbox.tcl
# PROCEDURES:  
#==========================================================================auto=
#
# Checkbox
# ----------------------------------------------------------------------
# Implements a checkbuttonbox.  Supports adding, inserting, deleting,
# selecting, and deselecting of checkbuttons by tag and index.
# Edited by N. Aucoin nicole@bwh.harvard.edu to add access to the button list:
# return them, how many, select and deselect and delete all
#
# ----------------------------------------------------------------------
#  AUTHOR: John A. Tucker                EMAIL: jatucker@spd.dsccc.com
#
# ----------------------------------------------------------------------
#            Copyright (c) 1997 DSC Technologies Corporation
# ======================================================================
# Permission to use, copy, modify, distribute and license this software 
# and its documentation for any purpose, and without fee or written 
# agreement with DSC, is hereby granted, provided that the above copyright 
# notice appears in all copies and that both the copyright notice and 
# warranty disclaimer below appear in supporting documentation, and that 
# the names of DSC Technologies Corporation or DSC Communications 
# Corporation not be used in advertising or publicity pertaining to the 
# software without specific, written prior permission.
# 
# DSC DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING 
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, AND NON-
# INFRINGEMENT. THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, AND THE
# AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE MAINTENANCE, 
# SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. IN NO EVENT SHALL 
# DSC BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR 
# ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, 
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS 
# SOFTWARE.
# ======================================================================

#########################################################
#
if {0} { ;# comment

ischeckbox - a widget for managing a list of checkboxes

# TODO : 
}
#
#########################################################

#
# Use option database to override default resources of base classes.
#
option add *ischeckbox.labelMargin    10    widgetDefault
option add *ischeckbox.labelFont     \
      "-Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-*"  widgetDefault
option add *ischeckbox.labelPos        nw    widgetDefault
option add *ischeckbox.borderWidth    2    widgetDefault
option add *ischeckbox.relief        groove    widgetDefault

#
# Usual options.
#
itk::usual ischeckbox {
    keep -background -borderwidth -cursor -foreground -labelfont
}

# ------------------------------------------------------------------
#                            ISCHECKBOX
# ------------------------------------------------------------------
if { [itcl::find class ::iwidgets::ischeckbox] == "" } {

    itcl::class iwidgets::ischeckbox {
        inherit iwidgets::Labeledframe

        constructor {args} {}

        itk_option define -orient orient Orient vertical

        public {
            method add {tag args}
            method insert {index tag args}
            method delete {{index ""}}
            method get {{index ""}}
            method getselind {}
            method index {index}
            method select {{index ""} {invokeFlag 1}}
            method deselect {{index ""}}
            method flash {index}
            method toggle {index}
            method buttonconfigure {index args}
            # additional useful methods
            method buttonrename {index newName}
            method getbuttons {}
            method getnumbuttons {}
        }
        
        private {

            method gettag {index}      ;# Get the tag of the checkbutton associated
            ;# with a numeric index
            
            variable _unique 0         ;# Unique id for choice creation.
            variable _buttons {}       ;# List of checkbutton tags.
            common buttonVar           ;# Array of checkbutton "-variables"
            variable _verbose 0        ;# Print out debugging info if 1
        }
    }
}

#
# Provide a lowercased access method for the ischeckbox class.
#
#proc ::iwidgets::ischeckbox {pathName args} {
#    uplevel ::iwidgets::ischeckbox $pathName $args
#}

# ------------------------------------------------------------------
#                        CONSTRUCTOR
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::constructor {args} {

    eval itk_initialize $args
}

# ------------------------------------------------------------------
#                            OPTIONS
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# OPTION: -orient
#
# Allows the user to orient the checkbuttons either horizontally
# or vertically.  Added by Chad Smith (csmith@adc.com) 3/10/00.
# ------------------------------------------------------------------
itcl::configbody iwidgets::ischeckbox::orient {
  if {$itk_option(-orient) == "horizontal"} {
    foreach tag $_buttons {
      pack $itk_component($tag) -side left -anchor nw -padx 4 -expand 1
    }
  } elseif {$itk_option(-orient) == "vertical"} {
    foreach tag $_buttons {
      pack $itk_component($tag) -side top -anchor w -padx 4 -expand 0
    }
  } else {
    error "Bad orientation: $itk_option(-orient).  Should be\
      \"horizontal\" or \"vertical\"."
  }
}


# ------------------------------------------------------------------
#                            METHODS
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# METHOD: index index
#
# Searches the checkbutton tags in the checkbox for the one with the
# requested tag, numerical index, or keyword "end".  Returns the 
# choices's numerical index if found, otherwise -1.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::index {index} {
    if {[llength $_buttons] > 0} {
        if {[regexp {(^[0-9]+$)} $index]} {
            if {$index < [llength $_buttons]} {
                return $index
            } else {
                if {$_verbose} {puts "ischeckbox index \"$index\" is out of range"}
                return -1
            }

        } elseif {$index == "end"} {
            return [expr {[llength $_buttons] - 1}]

        } else {
            if {[set idx [lsearch $_buttons $index]] != -1} {
                return $idx
            }

            # error "bad ischeckbox index \"$index\": must be number, end, or pattern"
            return -1
        }

    } else {
        # error "ischeckbox \"$itk_component(hull)\" has no checkbuttons"
        return -1
    }
}

# ------------------------------------------------------------------
# METHOD: add tag ?option value option value ...?
#
# Add a new tagged checkbutton to the checkbox at the end.  The method 
# takes additional options which are passed on to the checkbutton
# constructor.  These include most of the typical checkbutton 
# options.  The tag is returned. The checkbox is selected by default
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::add {tag args} {
    if {$_verbose} { puts "ischeckbox add tag = $tag"}

    if {[lsearch $_buttons $tag] != -1} {
        if {$_verbose} { puts "ischeckbox::add: $tag already added"}
        return $tag
    } 
    itk_component add "$tag" {
        set _u [incr _unique]
        
        if {[info command $itk_component(childsite).cb${_u}] == ""} {
            if {$_verbose} { puts "ischeckbox add : adding a checkbutton with $_u, args = $args"}
            eval checkbutton $itk_component(childsite).cb${_u} \
                -variable [list [itcl::scope buttonVar($this,"$tag")]] \
                -anchor w \
                -justify left \
                -highlightthickness 0 \
                $args
        } else {
            puts "ischeckbox::add: error, trying to add a duplicate checkbox:\n$itk_component(childsite).cb${_u}"
            return ""
        }
    } { 
      usual
      keep -command -disabledforeground -selectcolor -state
      ignore -highlightthickness -highlightcolor
      rename -font -labelfont labelFont Font
    }

    # Redraw the buttons with the proper orientation.
    if {$itk_option(-orient) == "vertical"} {
      pack $itk_component($tag) -side top -anchor w -padx 4 -expand 0
    } else {
      pack $itk_component($tag) -side left -anchor nw -expand 1
    }
    if {$_verbose} { puts  "ischeckbutton add: done with the itk comp bit. setting the var"}
    set [itcl::scope buttonVar($this,"$tag")] 1
    
    if {$_verbose} { puts  "ischeckbutton add: adding $tag to _buttons list"}
    lappend _buttons $tag
    if {$_verbose} { puts  "\t_buttons  = $_buttons"}

    return $tag
}

# ------------------------------------------------------------------
# METHOD: insert index tag ?option value option value ...?
#
# Insert the tagged checkbutton in the checkbox just before the 
# one given by index.  Any additional options are passed on to the
# checkbutton constructor.  These include the typical checkbutton
# options.  The tag is returned.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::insert {index tag args} {
    itk_component add "$tag" {
        eval checkbutton $itk_component(childsite).cb[incr _unique] \
            -variable [list [itcl::scope buttonVar($this,"$tag")]] \
            -anchor w \
            -justify left \
            -highlightthickness 0 \
            $args
    }  { 
      usual
      ignore -highlightthickness -highlightcolor
      rename -font -labelfont labelFont Font
    }

    set index [index $index]
    set before [lindex $_buttons $index]
    set _buttons [linsert $_buttons $index $tag]

    pack $itk_component($tag) -anchor w -padx 4 -before $itk_component($before)

    return $tag
}

# ------------------------------------------------------------------
# METHOD: delete index
#
# Delete the specified checkbutton. If none specified, delete all.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::delete {{index ""}} {

    if {$_verbose} { puts  "ischeckbox delete index = $index"}

    if {$index != ""} {
        set tag [gettag $index]
        if {$_verbose} { puts  "ischeckbox delete delete tag = $tag"}
        if {$tag != ""} {
            
            set index [index $index]
            if {$_verbose} { puts  "ischeckbox delete, new index = $index. calling destroy"}
            destroy $itk_component($tag)
            if {$_verbose} { puts  "ischeckbox delete, done destory on $tag"}
            if {$index == -1} {
                DevErrorWindow "EEEP! index is -1"
            } else {
                set _buttons [lreplace $_buttons $index $index]
                if {$_verbose} { puts  "ischeckbox delete, new buttons list = $_buttons"}
            }
            if { [info exists buttonVar($this,"$tag")] == 1 } {
                unset buttonVar($this,"$tag")
                if {$_verbose} { puts  "ischeckbox delete: unset the button var for $tag"}
            }
        }
    } else {
        # delete them all
        foreach tag $_buttons {
            if {$_verbose} { puts  "ischeckbox delete: deleting all, now on $tag"}
            destroy $itk_component($tag)
            if {[info exists buttonVar($this,"$tag")] == 1} {
                unset buttonVar($this,"$tag")
            }
        }
        set _buttons ""
    }    
}

# ------------------------------------------------------------------
# METHOD: select index
#
# Select the specified checkbutton. If none specified, select all.
# If the invokeFlag is 0, don't invoke the checkbox's callback, just select it.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::select {{index ""} {invokeFlag 1}} {

    if {$index != ""} {

        set tag [gettag "$index"]
        #-----------------------------------------------------------
        # BUG FIX: csmith (Chad Smith: csmith@adc.com), 3/30/99
        #-----------------------------------------------------------
        # This method should only invoke the checkbutton if it's not
        # already selected.  Check its associated variable, and if
        # it's set, then just ignore and return.
        #-----------------------------------------------------------
        if {$tag != ""} {
            if {$_verbose} { puts  "ischeckbox:select:  index = $index, tag = $tag"}
            if {[set [itcl::scope buttonVar($this,"$tag")]] == 
                [[component "$tag"] cget -onvalue]} {
                return
            }
            if {$invokeFlag} {
                $itk_component($tag) invoke
            } else {
                $itk_component($tag) select
            }
        }
    } else {
        foreach tag $_buttons {
            if {[set [itcl::scope buttonVar($this,"$tag")]] == 
                [[component "$tag"] cget -onvalue]} {
                # skip it
            } else {
                if {$invokeFlag} {
                    $itk_component($tag) invoke
                } else {
                    $itk_component($tag) select
                }
            }
        }
    }
}

# ------------------------------------------------------------------
# METHOD: toggle index
#
# Toggle a specified checkbutton between selected and unselected
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::toggle {index} {
    set tag [gettag $index]
    if {$tag != ""} {
        $itk_component($tag) toggle
    }
}

# ------------------------------------------------------------------
# METHOD: get
#
# Return the value of the checkbutton with the given index, or a
# list of all checkbutton values in increasing order by index.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::get {{index ""}} {
    set result {}

    if {$index == ""} {
        foreach tag $_buttons {
            if {$buttonVar($this,"$tag")} {
                lappend result $tag
            }
        }
    } else {
        set tag [gettag $index]
        if {$tag != ""} {
            set result $buttonVar($this,"$tag")
        }
    }
    if {$_verbose} { puts  "ischeckbox::get index = $index, returning $result"}
    return $result
}

# return the index into the buttons list of all selected buttons
itcl::body iwidgets::ischeckbox::getselind {} {
    set result {}
    if {$_verbose} { puts  "ischeckbox getselind all buttons = $_buttons"}
    foreach tag $_buttons {
        if {$buttonVar($this,"$tag")} {
            lappend result [lsearch $_buttons $tag]
        }
    }
    if {$_verbose} { puts  "ischeckbox getseldind, sel buttons =  $result"}
    return $result
}

# ------------------------------------------------------------------
# METHOD: deselect index
#
# Deselect the specified checkbutton. If index is an empty string,
# deselect all the checkbuttons. 
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::deselect {{index ""} } {
    if {$index != ""} {
        set tag [gettag $index]
        if {$tag != ""} {
            $itk_component($tag) deselect
        }
    } else {
        foreach tag $_buttons {
            $itk_component($tag) deselect
        }
    }
}

# ------------------------------------------------------------------
# METHOD: flash index
#
# Flash the specified checkbutton.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::flash {index} {
    set tag [gettag $index]
    if {$tag != ""} {
        $itk_component($tag) flash  
    }
}

# ------------------------------------------------------------------
# METHOD: buttonconfigure index ?option? ?value option value ...?
#
# Configure a specified checkbutton.  This method allows configuration 
# of checkbuttons from the ischeckbox level.  The options may have any 
# of the values accepted by the add method.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::buttonconfigure {index args} { 
    set tag [gettag $index]
    if {$tag != ""} {
        eval $itk_component($tag) configure $args
    }
}

# ------------------------------------------------------------------
# METHOD: buttonrename index newName
#
# Configure the specified checkbutton so that the text, tag and variable
# use the new name.  This method allows configuration 
# of checkbuttons from the ischeckbox level. 
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::buttonrename {index newName} {
    set tag [gettag $index]
    if {$_verbose} {
        puts "buttonrename at index $index to $newName" 
        puts "buttonrename: tag = $tag"
        puts "buttonrename: deleting and adding a new one"
    }

    if {$tag == ""} {
        puts "buttonrename: ERROR: no tag for button index $index, cannot rename to $newName"
        return
    }
    if { [info exists buttonVar($this,"$tag")] == 1 } {
        set savedval $buttonVar($this,"$tag")
    }
    set savedcmd [$itk_component($tag) cget -command]

    delete $index

    if {$_verbose} {
        puts "buttonrename: inserting $newName at $index with saved command $savedcmd"
        puts "\tlength of list = [llength $_buttons]"
    }
    # make sure that its' nto the last one, if so, need to use add instead
    if {$index < [llength $_buttons]} {
        insert $index "$newName" -text "$newName" -command $savedcmd
    } else {
        # add it to the end
        add "$newName" -text "$newName" -command $savedcmd
    }
    if { [info exists buttonVar($this,"$newName")] == 1 } {
        if {$_verbose} {
            puts "buttonrename: resetting the buttonvar to saved value $savedval"
        }
        set buttonVar($this,"$newName") $savedval
    }
}


# ------------------------------------------------------------------
# METHOD: gettag index
#
# Return the tag of the checkbutton associated with a specified
# numeric index
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::gettag {index} {
    return [lindex $_buttons [index $index]]
}

# ------------------------------------------------------------------
# METHOD: getbuttons
#
# Return the list of checkbutton names.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::getbuttons {} {
    return $_buttons
}

# ------------------------------------------------------------------
# METHOD: getnumbuttons
#
# Return the number of checkbutton names.
# ------------------------------------------------------------------
itcl::body iwidgets::ischeckbox::getnumbuttons {} {
    return [llength $_buttons]
}

