#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Ev.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:04 $
#   Version:   $Revision: 1.7 $
# 
#===============================================================================
# FILE:        Ev.tcl
# PROCEDURES:  
#   EvInit
#   EvDeclareEventHandler eSet event handler
#   EvClearEventHandler eSet event
#   EvClearEventHandler
#   EvAddWidgetToBindingSet bindingSet widget eglist
#   EvRemoveWidgetFromBindingSet bindingSet widget
#   EvActivateBindingSet bindingSet widgetList
#   EvDeactivateBindingSet bindingSet widgetList
#   EvDestroyBindingSet bindingSet
#   EvCullDeadWidgetsFromBindingSet bindingSet widgetList
#   EvGetBindingStack widget
#   EvClearWidgetBindings widget
#   EvBindtagsToEventSet bt
#   EvEventSetToBindtags bindingSet eventList rest
#   EvFormatBinding e
#   EvReplaceWidgetBindings widget newBindingSet newBindings
#   EvSimpleExample
#==========================================================================auto=

# Ev Documentation.
#
# created Mar 24, 2002, Michael Halle
#
# The Ev module is designed to simplify the task of handling groups of
# events over multiple widgets in various modules.  Let me explain
# some terminology here to get you going.  Ev uses two types of data:
# event sets and binding sets.  An event set is an association of a
# name (which could be a single string or a list of strings) and a set
# of Tk event / callback handler pairs.  Event sets are the named
# collections you use to tie together these different events and
# handlers.  For every event you want to handle in your module, you
# should declare it in an event set. 
#
# If you're writing a simple module, you might only have one event set
# (perhaps with a name that's the same as your module).  On the other
# hand, you might be able to logically classify the kinds of events
# your module handles into different groups.  For example, you might
# have bindings for different kinds of widgets in your module's
# implementation.  Or perhaps your module has different modes that
# require different bindings.  That's where an event set name that's a
# list might come in handy: your set could be called {Editor
# keyEvents} or {Endoscopic globalViewNavigation} or whatever you'd
# like. You might even be able to use bindings from other modules to
# avoid reimplementing functionality: someone else has already done
# the work, why not use it?
#
# Part of the beauty of event sets is that they don't bind directly to
# widgets; instead they bind to an intermediate name (the event set
# name).  (In fact, you can initialize them before you even have
# widgets, which means that a module can set up behavior for other
# modules to use.)  That means in order to do anything, event sets
# have to be bound to widgets.  Binding sets provide this service.
# Where event sets are a named collection of event / handler pairs,
# binding sets are a named collection of widget and event sets
# associations.  To a binding set, you bind the set name to the
# behaviors (event bindings) you want each widget in your module to
# have.  Then, with one command, you can activate those behaviors
# for all of your widgets at once (or, similarly, restore the bindings
# that existed before your module became active).
#
# When you add a widget to a binding set, you supply the event sets
# that implement the behavior you want the widget to have.  Notice
# that the sentence about says "event sets," not "event set."  You can
# supply multiple event sets in the binding in order to compose
# different behaviors.  Let's say that I'm writing an image editing
# module that has two modes: viewing and editing.  Some behavior is
# common in the two modes (maybe I want the "m" key to pull up a
# magnifier for either viewing or editing).  Other behavior is
# mode-specific: a button click might start a line drawing in editor
# mode, but only print the coordinate in viewing mode.
#
# A collection of event sets can implement this functionality.  One
# event set (say, {Editor base}) includes all the bindings for the
# common functionality of the two modes.  Two other sets 
# ({Editor editMode} and {Editor viewMode}) implement mode-specific
# functionality.  When a widget is bound into a binding set, the
# different modes can be composed:
#
# EvAddWidgetToBindingSet MyBindings $widget {{Editor editMode} {Editor base}}
#
# In this case, when the binding set MyBindings is activated, an
# incoming event is first matched to the Editor's editMode bindings,
# then the Editor's base bindings.  (Things get a bit complicated
# when several event sets have matching event bindings for one event.
# By default, each matching handler will be called, but you can
# write your handlers to terminate the traversal early.  This
# behavior is part of Tk's event model;  check the Tk documentation
# for details).
#
# As explained previously, activating a binding set causes all the
# the widgets in the set to be bound to their respective event sets.
# For example:
#
# EvActivateBindingSet MyBindings
#
# This one small command controls the behavior of a potentially large
# number of widgets.  Similarly, you can remove that behavior with
# the deactivate command:
#
# EvDeactivateBindingSet MyBindings
#
# These two functions actually manipulate a stack of binding sets.  
# The Activate command pushes a binding set onto the stack, the
# Deactivate command pops it off and restores whatever binding set
# was previously active.  There are a few exceptions to this behavior.
# If you activate an already active binding set, nothing happens.
# If you deactivate a binding set that isn't active, nothing happens.
#
# The activate and deactivate functions normally work on the all the
# widgets bound to the binding set.  If you need to, you can use them
# on a subset of those widgets by passing in a list of widgets as
# arguments.  You might choose to do so if you add a new widget to
# a binding set after that set is already active, and you just want
# that widget to pick up the right behavior.
#
# One more little complexity.  You are free to change event sets while
# a binding set is active; it works fine and the change takes place
# immediately.  However, if you use EvAddWidgetToBindingSet to change
# the events sets that a widget is bound to while the binding set is
# active, the changes won't take place until you call
# EvActivateBindingSet.  Since you can call the activation function
# repeatedly without harm, that's okay, you just have to remember to
# do it. 
#
# If you're looking for a simple example of Ev at work, please look
# at the bottom of the file for the EvSimpleExample function.
#
#-------------------------------------------------------------------------------
# .PROC EvInit
#  The "Init" procedure is called automatically by the slicer.  It
# puts information about the module into a global array called Module,
# and it also initializes module-level variables.  Note that the state
# of this module is stored in an array called EvState, since Ev is
# convenient for typing but is risky for name clashes.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EvInit {} {
    set m Ev

    # "Ev" seems too likely to provoke name clashes, so I 
    # buck with tradition here.
    global EvState Module
    
    # Define Dependencies
    set Module($m,depend) ""
    set Module($m,overview) "Flexible Tk event set handling"
    set Module($m,author) "Michael Halle, SPL"
    
    # Set version info
    lappend Module(versions) [ParseCVSInfo $m \
            {$Revision: 1.7 $} {$Date: 2006/01/06 17:57:04 $}]
}

#-------------------------------------------------------------------------------
# .PROC EvDeclareEventHandler
#
# Associate an event and handler with an event set.  An event set is a
# collection of events and handlers that can be bound to a widget or
# widgets.  Event sets are either strings or lists of strings.  A
# simple event set for a module could just be named after the module
# (eg, "Endoscopic").  More complex modules might have several
# different event to be used at different times or for different
# widgets in the user interface.  These modules could use the list
# form of event sets (e.g, "{Viewer editing}" and "{Viewer viewing}").
#
# To unbind an event handler for an event set, pass {}
# as the event handler, or use EvClearEventHandler.
#
# .ARGS
#  list eSet the event set with which to associate the event and handler
#  event event the Tk event that will trigger the handler
#  str handler the code to call when event is received
# .END
#-------------------------------------------------------------------------------
proc EvDeclareEventHandler {eSet event handler} {
    
    bind [EvFormatBinding $eSet] $event $handler
}

#-------------------------------------------------------------------------------
# .PROC EvClearEventHandler
# 
# Clear all event handlers in an event set.  If event is event,
# the handler for that event is clear.  If no event is given,
# all handlers are cleared.
#
# .ARGS
# list eSet an event set name.
# str event event to clear handlers for, if not given all events are cleared.
# .END

#-------------------------------------------------------------------------------
# .PROC EvClearEventHandler
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EvClearEventHandler {eSet {event {}}} {
    set es [EvFormatBinding $eSet]
    if {[length $event] == 0} {
        set event [bind $es]
    }

    for b in $event {
        bind $es $b {}
    }
}
#-------------------------------------------------------------------------------
# .PROC EvAddWidgetToBindingSet
# 
# Associate a widget and a list of event sets with a binding set.
# Binding sets represent a set of event bindings across a set of
# widgets.  When a binding set is activated, the widgets in the set
# get bound to their event sets.  If a widget is bound to more than
# one event set (ie, if the eglist parameter is a list of sets), an
# event is processed by each event set from left to right.  This
# process allows the composition, specialization, and override of
# different event handling behavior.
# 
# .ARGS
# str bindingSet the name of the binding set to which to add this widget.  Don't use commas or spaces in the name.
# str widget the name of the widget to bind
# list eglist an event set or list of event sets
# .END
#-------------------------------------------------------------------------------
proc EvAddWidgetToBindingSet {bindingSet widget eglist} {
    upvar \#0 EvState(widgets,$bindingSet) widgetList
    upvar \#0 EvState(binding,$bindingSet,$widget) binding

    if {! [info exists widgetList] ||
        [lsearch -exact $widgetList $widget] == -1} {
        # widget not in list, or there is no list
        lappend widgetList $widget
    }
    set binding $eglist
}

#-------------------------------------------------------------------------------
# .PROC EvRemoveWidgetFromBindingSet
#
# Disassociates the widget from the binding set.  Events handlers 
# will no longer be activated on this widget when the binding set 
# is activated.  If the binding set is active, it is deactivated
# for this widget first.
#
# .ARGS
# str bindingSet
# str widget
# .END
#-------------------------------------------------------------------------------
proc EvRemoveWidgetFromBindingSet {bindingSet widget} {

    if {![winfo exists $widget]} {
        EvCullDeadWidgetsFromBindingSet $bindingSet $widget
        return
    }

    upvar \#0 EvState(widgets,$bindingSet) widgetList
    upvar \#0 EvState(binding,$bindingSet,$widget) binding

    if {[info exists widgetList]} {
        set where [lsearch -exact $widgetList $widget]
        if {$where != -1} {
            # just in case, make sure that the binding isn't active
            EvDeactivateBindingSet $bindingSet $widget

            set widgetList [lreplace $widgetList $where $where]
        }
    }
    if {[info exists binding]} {
        unset binding
    }
}

#-------------------------------------------------------------------------------
# .PROC EvActivateBindingSet
#
# Activate the bindings associated with this binding set on a list of
# widgets, or by default all the widgets that are associated with this
# binding set.  If the widgetList is empty, all widgets are activated.
# If the binding set is already activated, activation just freshens
# the event list definitions of the active widgets.  
#
# Activation causes the name of the binding set to be pushed onto a
# per-widget stack to allow previous bindings to be reactivated at a
# later time.  Under no circumstances, however, will a binding set be
# pushed onto the stack twice in a row: a second activation without
# deactivation is effectively a no-op with regard to the stack.
#
# .ARGS
# str bindingSet name of binding set to activate
# list widgetList list of widgets to apply the binding set to. By default, all widgets are activated.
# .END
#-------------------------------------------------------------------------------
proc EvActivateBindingSet {bindingSet {widgetList {}}} {
    if {[llength $widgetList] == 0} {
        upvar \#0 EvState(widgets,$bindingSet) allWidgets
        if {! [info exists allWidgets] } {
            set allWidgets {}
        }
        set widgetList $allWidgets
    }

    EvCullDeadWidgetsFromBindingSet $bindingSet $widgetList

    foreach w $widgetList {
        if {![winfo exists $w]} {
            continue
        }
        upvar \#0 EvState(binding,$bindingSet,$w) binding
        if {! [info exists binding]} {
            continue
        }
        upvar \#0 EvState(stack,$w) bindingStack
        if {![info exists bindingStack]} {
            # widget has never been bound before
            set bindingStack $bindingSet
        } elseif {[lindex $bindingStack 0] != $bindingSet} {
            # push new event label onto stack
            set bindingStack [linsert $bindingStack 0 $bindingSet]
        }
        EvReplaceWidgetBindings $w $bindingSet $binding
    }
}

#-------------------------------------------------------------------------------
# .PROC EvDeactivateBindingSet
# 
# Deactivate the named binding set for a list of widgets or, 
# by default, all widgets associated with the binding set.
# Deactivation reactivates previously active events through
# the per-widget binding stack.
#
# .ARGS
# str bindingSet
# list widgetList  list of widgets to deactivate, if empty all widgets are deactivated.
# .END
#-------------------------------------------------------------------------------
proc EvDeactivateBindingSet {bindingSet {widgetList {}}} {
    if {[llength $widgetList] == 0} {
        # special case: we were not given a widget list,
        # so remove binding set from all widgets using the 
        # binding set.

        upvar \#0 EvState(widgets,$bindingSet) allWidgets
        if {! [info exists allWidgets] } {
            set allWidgets {}
        }
        set widgetList $allWidgets
    }

    EvCullDeadWidgetsFromBindingSet $bindingSet $widgetList

    foreach w $widgetList {
        if {![winfo exists $w]} {
            continue
        }
        upvar \#0 EvState(stack,$w) bindingStack
        if {![info exists bindingStack]} {
            # widget has never been bound before
            continue
        } elseif {[lindex $bindingStack 0] != $bindingSet} {
            # we aren't on the top of the binding stack
            continue
        }
        set bindingStack [lreplace $bindingStack 0 0]
        set newBindingSet [lindex $bindingStack 0]
        set newBinding {}
        if {$newBindingSet != ""} {
            # get the event sets to which we are bound
            upvar \#0 EvState(binding,$newBindingSet,$w) binding
            if {[info exists binding]} {
                set newBinding $binding
            }
        }
        EvReplaceWidgetBindings $w $newBindingSet $newBinding
    }
}

#-------------------------------------------------------------------------------
# .PROC EvDestroyBindingSet
# 
# Destroy the named binding set.  The set's bindings are deactivated.
#
# .ARGS
# str bindingSet
# .END
#-------------------------------------------------------------------------------
proc EvDestroyBindingSet {bindingSet} {
    EvCullDeadWidgetsFromBindingSet $bindingSet

    EvDeactivateBindingSet $bindingSet

    upvar \#0 EvState(widgets,$bindingSet) allWidgets
    if {! [info exists allWidgets] } {
        set allWidgets {}
    }

    foreach w $allWidgets {
        upvar \#0 EvState(stack,$w) bindingStack
        if {![info exists bindingStack]} {
            continue
        } 

        while {1} {
            set where [lsearch -exact $bindingStack $bindingSet]
            if {$where == -1} {
                break
            }
            set bindingStack [lreplace $bindingStack $where $where]
        }

        if {[llength $bindingStack] == 0} {
            unset bindingStack
        }

        upvar \#0 EvState(binding,$bindingSet,$w) binding
        if {[info exists binding]} {
            unset binding
        }
    }
    unset allWidgets
}

#-------------------------------------------------------------------------------
# .PROC EvCullDeadWidgetsFromBindingSet
# 
# Look for widges that don't exist, and clear them out of the 
# data structures
#
# .ARGS
# str bindingSet
# list widgetList  list of widgets to look for deadness, if empty all widgets checked.
# .END
#-------------------------------------------------------------------------------
proc EvCullDeadWidgetsFromBindingSet {bindingSet {widgetList {}}} {
    upvar \#0 EvState(widgets,$bindingSet) allWidgets
    if {! [info exists allWidgets] } {
        set allWidgets {}
    }

    if {[llength $widgetList] == 0} {
        # special case: we were not given a widget list,
        # so remove binding set from all widgets using the 
        # binding set.

        set widgetList $allWidgets
    }

    foreach w $widgetList {
        if {[winfo exists $w] } {
            # not dead yet
            continue
        }
        upvar \#0 EvState(stack,$w) bindingStack
        if {[info exists bindingStack]} {
            unset bindingStack
        }

        upvar \#0 EvState(binding,$bindingSet,$w) binding
        if {[info exists binding]} {
            set newBinding $binding
        }

        set where [lsearch -exact $allWidgets $w]
        if {$where != -1} {
            # just in case, make sure that the binding isn't active
            set allWidgets [lreplace $allWidgets $where $where]
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EvGetBindingStack
# 
# Return the binding stack for a widget. 
# When a binding set is activated, the binding set name is 
# pushed onto a per-widget stack and the widget-specific
# event sets are activated.  Conversely, when the 
# binding set is deactivated, the stack is popped and the
# previous bindings are applied.  This function permits
# inspection of this stack.
#
# .ARGS
# str widget 
# .END
#-------------------------------------------------------------------------------
proc EvGetBindingStack {widget} {
    upvar \#0 EvState(stack,$widget) bindingStack
    if {![info exists bindingStack]} {
        return {}
    }
    return $bindingStack
}

#-------------------------------------------------------------------------------
# .PROC EvClearWidgetBindings
#
# Clear all Ev-related bindings from a widget, leaving other bindings
# intact.  The binding set stack for the widget is also cleared.  It's
# probably best that the widget be removed from any binding sets that
# it is bound to, since that doesn't happen automatically.
#
# .ARGS
# str widget
# .END
#-------------------------------------------------------------------------------
proc EvClearWidgetBindings {widget} {
    if {[winfo exists $widget]} {
        EvReplaceWidgetBindings $widget "" {}
    }

    upvar \#0 EvState(stack,$widget) bindingStack
    if {[info exists bindingStack]} {
        unset bindingStack
    }
}
#-------------------------------------------------------------------------------
# .PROC EvBindtagsToEventSet
#
# Convert Tk event format bindtags to event set syntax. Returns the
# active binding set, the list of  active event sets, and the rest of the
# binding list.
# 
# End users should not be calling this function.
#
# .ARGS
# list bt a bindtags list
# .END
#-------------------------------------------------------------------------------
proc EvBindtagsToEventSet {bt} {
    # look for start and end tokens
    set startIdx [lsearch $bt "Slicer,_Start,*"]
    set endIdx   [lsearch $bt "Slicer,_End"]

    if {$startIdx == -1 || $endIdx == -1} {
        # not present, return what we can
        return [list {} {} $bt]
    }

    # look at the start tag, and the name of the active binding set
    set activeBindingSet [lindex [split [lindex $bt $startIdx] ,] 2]
    
    set tags {}
    # in between start and end tags, extract and unformat event binding tags
    foreach t [lrange $bt [expr {$startIdx + 1}] [expr {$endIdx - 1}]] {
        lappend tags [lrange [split $t ,] 1 end]
    }
    # return binding set name, event binding list, and other misc bindings
    return [list $activeBindingSet $tags [lrange $bt [expr {$endIdx + 1}] end]]
}

#-------------------------------------------------------------------------------
# .PROC EvEventSetToBindtags
#
# Converts event set list format to bindtags. 
#
# End users should not be calling this function.
#
# .ARGS
# str bindingSet name of active binding set 
# list eventList  a list of event sets to format
# list rest   additional bindings to put on the end of the binding list
# .END
#-------------------------------------------------------------------------------
proc EvEventSetToBindtags {bindingSet eventList {rest {}}} {

    if {[llength $eventList] == 0 || $bindingSet == ""} {
        # effectively removing bindings from list
        return $rest
    }

    # mark beginning of our binding tags
    set bt "Slicer,_Start,$bindingSet"
    
    foreach e $eventList {
        # format event binding list and add
        lappend bt [EvFormatBinding $e]
    }

    # tack on end token
    lappend bt [EvFormatBinding "_End"]
    return [concat $bt $rest]
}

#------------------------------------------------------------------------------
# .PROC EvFormatBinding
# 
# Format a binding. Internal use only.
#
# .ARGS
# str e a name.
# .END
#------------------------------------------------------------------------------
proc EvFormatBinding {e} {
    return [format "%s,%s" "Slicer" [join $e ","]]
}

#------------------------------------------------------------------------------
# .PROC EvReplaceWidgetBindings
# 
# Modify a widget's current bindings.  This function is the only point
# where Ev interacts with Tk, through the bindtags command.  The old
# list of bindings is removed and the new one is activated.
#
# End users should not be calling this function.
#
# .ARGS
# str widget Tk widget to bind to
# str newBindingSet name of new binding set
# list newBindings  event set list
# .END
#------------------------------------------------------------------------------
proc EvReplaceWidgetBindings {widget newBindingSet newBindings} {
    # get current binding on widget
    set cur [EvBindtagsToEventSet [bindtags $widget]]

    # bind the new events in.  Keep rest of bindings intact.
    # we could optimize by checking to see if our bindings are 
    # already installed, but what if the event sets have changed?
    bindtags $widget \
        [EvEventSetToBindtags $newBindingSet $newBindings [lindex $cur 2]]
}

#-------------------------------------------------------------------------------
# .PROC EvSimpleExample
# 
# A simple example of the Ev package in use.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EvSimpleExample {} {
    set root ""

    # create two frames for events
    set f1 [frame $root.f1 -width 200 -height 200]
    pack $f1

    set f2 [frame $root.f2 -width 200 -height 200 -bg red]
    pack $f2

    # associate some events with event sets
    # event sets can be simple names:
    EvDeclareEventHandler Endosc <ButtonPress-1> { puts "CLICK: %x %y" }


    # ...or they can be lists of names for categorization:
    EvDeclareEventHandler {Endo motion} <Motion> { puts "motion: %x %y" }


    # event sets can have many events in them:
    EvDeclareEventHandler {Endo click} <ButtonPress-1> { puts "CLICK1: %x %y" }
    EvDeclareEventHandler {Endo click} <ButtonPress-2> { puts "CLICK2: %x %y" }
    EvDeclareEventHandler {Endo click} <ButtonPress-3> { puts "CLICK3: %x %y" }


    # now create binding sets.  When a binding set becomes active,
    # all the widgets in it are bound to the event sets listed here.
    # When more than one event set is listed, events are processed by
    # each, left to right.  Listing two or more sets allows composition
    # of events handlers.
    EvAddWidgetToBindingSet Endoscopic $f1 {{Endo motion} {Endo click}}
    EvAddWidgetToBindingSet Endoscopic $f2 Endosc


    # we can create another binding set, applying different behaviors
    # to the same widgets:
    EvAddWidgetToBindingSet Endoscopic2 $f1 {{Endo click}}
    EvAddWidgetToBindingSet Endoscopic2 $f2 {{Endo motion} {Endo click}}
 

    # binding set activation makes active all the binds in a binding set.
    # the following line makes all the Endoscopic bindings active:
    EvActivateBindingSet Endoscopic
    puts "f1 bindings: [EvGetBindingStack $f1]"
    puts "f2 bindings: [EvGetBindingStack $f2]"

    # ...and this line makes Endoscopic2 bindings active:
    EvActivateBindingSet Endoscopic2   
    puts "f1 bindings: [EvGetBindingStack $f1]"
    puts "f2 bindings: [EvGetBindingStack $f2]"

    # binding sets are stored on a per-widget stack.  
    # Deactivation of a binding set automatically reactivates 
    # the binding that was active before this set:
    EvDeactivateBindingSet Endoscopic2 ; # Endoscopic bindings active again

    puts "f1 bindings: [EvGetBindingStack $f1]"
    puts "f2 bindings: [EvGetBindingStack $f2]"
}
