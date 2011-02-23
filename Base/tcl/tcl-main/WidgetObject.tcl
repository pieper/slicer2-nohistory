#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: WidgetObject.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:56 $
#   Version:   $Revision: 1.13 $
# 
#===============================================================================
# FILE:        WidgetObject.tcl
# PROCEDURES:  
#==========================================================================auto=
# These procs allow widgets to behave like objects with their own
# state variables of processing objects.


# generate a "unique" name for a widget variable
proc GenerateWidgetVariable {widget varName} {
   regsub -all {\.} $widget "_" base

   return "$varName$base"
}

# returns an object which will be associated with a widget
# no error checking
proc NewWidgetObject {widget type varName} {
   set var [GenerateWidgetVariable $widget $varName]
   # create the vtk object
   $type $var

   return $var
}

# returns the name of an object previously created by NewWidgetObject
proc GetWidgetObject {widget varName} {
   return [GenerateWidgetVariable $widget $varName]
}

# sets the value of a widget variable
proc SetWidgetVariableValue {widget varName value} {
   set var [GenerateWidgetVariable $widget $varName]
   global $var
   set $var $value
}

# This proc has alway eluded me.
proc GetWidgetVariableValue {widget varName} {
   set var [GenerateWidgetVariable $widget $varName]
   global $var
   set temp ""
   catch {eval "set temp [format {$%s} $var]"}

   return $temp
}


