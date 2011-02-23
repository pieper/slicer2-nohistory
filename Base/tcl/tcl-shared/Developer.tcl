#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Developer.tcl,v $
#   Date:      $Date: 2007/07/30 19:25:52 $
#   Version:   $Revision: 1.57 $
# 
#===============================================================================
# FILE:        Developer.tcl
# PROCEDURES:  
#   DevYesNo message
#   DevOKCancel message
#   DevWarningWindow message
#   DevInfoWindow message
#   DevErrorWindow message
#   DevFatalErrorWindow message
#   DevAddLabel LabelName Message Color
#   DevAddEntry ArrayName Variable EntryName Width
#   DevAddButton ButtonName Message Command Width
#   DevAddSelectButton TabName f aLabel message pack tooltip width color
#   DevUpdateNodeSelectButton type ArrayName Label Name CommandSet None New LabelMap Command2Set
#   DevUpdateSelectButton ArrayName Label Name ChoiceList Command
#   DevSelectNode type id ArrayName ModelLabel ModelName
#   DevCreateNewCopiedVolume OrigId Description VolName
#   DevGetFile filename MustPop DefaultExt DefaultDir Title Action PathType
#   DevAddFileBrowse Frame ArrayName VarFileName Message Command DefaultExt DefaultDir Action Title Tooltip PathType
#   DevCreateScrollList ScrollFrame ItemCreateGui ScrollListConfigScrolledGUI: ItemList
#   DevCheckScrollLimits  args
#   DevFileExists filename
#   DevSourceTclFilesInDirectory dir verbose
#   DevPrintMrmlDataTree tagList justMatrices
#   DevPrintMatrix mat name
#   DevPrintMatrix4x4 mat name
#   DevCreateTextPopup topicWinName title x textBoxHit txt
#   DevApplyTextTags str
#   DevInsertPopupText w
#   DevTextLink w linkTag
#   DevLaunchBrowser section
#   DevLaunchBrowserURL url
#==========================================================================auto=
# This file exists specifically for user to help fast development
# of Slicer modules
#
# This is a list of useful functions:
#   DevWarningWindow message        A pop-up Warning Window
#   DevErrorWindow message          A pop-up Error   Window
#   DevFatalErrorWindow message     A pop-up Error Window and Exit
#   DevAddLabel LabelName message   Add a label to the GUI
#   DevAddButton ButtonName         Add a button to the GUI that calls a command.
#   DevAddSelectButton              Add a volume or model select button
#   DevSelect                       Called upon selection from a SelectButton.
#   DevCreateNewCopiedVolume        Create a New Volume, Copying an existing one's param
#   DevGetFile                    Looks for a file, makes a pop-up window if necessary
#   DevAddFileBrowse              Creates a File Browsing Frame
#
# Other Useful stuff:
#
# MainVolumesCopyData               Copy the image part of a volume.
# MainModelsDelete  idnum           Delete a model
# MainVolumesDelete idnum           Delete a volume
# YesNoPopup                        in tcl-main/Gui.tcl.
# DataAddTransform                  Add a transform to the Mrml Tree.
#
# Useful Variables
# $Mrml(dir)  The directory from which the slicer was run.
#


#-------------------------------------------------------------------------------
# .PROC DevYesNo
#
#  Ask the user a Yes/No question. Force the user to decide before continuing.<br>
#  Returns "yes" or "no"<br>
#  Resets the tk scaling to 1 and then returns it to the original value. 
#
# .ARGS
#  str message The question to ask.
# .END
#-------------------------------------------------------------------------------
proc DevYesNo {message} {
    set oscaling [tk scaling]

    if {$::Module(verbose)} {
        puts "DevYesNo: original scaling is $oscaling, changing it to 1 and then back"
    }
    tk scaling 1
    set retval [tk_messageBox -title Slicer -icon question -type yesno -message $message]
    tk scaling $oscaling

    return $retval
}

#-------------------------------------------------------------------------------
# .PROC DevOKCancel
#
#  Ask the user an OK/Cancel question. Force the user to decide before continuing.<br>
#  Returns "ok" or "cancel". <br>
#  Resets the tk scaling to 1 and then returns it to the original value.
# .ARGS
#  str message The message to give.
# .END
#-------------------------------------------------------------------------------
proc DevOKCancel {message} {
    set oscaling [tk scaling]
    
    if {$::Module(verbose)} {
        puts "DevOKCancel: original scaling is $oscaling, changing it to 1 and then back"
    }

    tk scaling 1
    set retval [tk_messageBox -title Slicer -icon question -type okcancel -message $message]
    tk scaling $oscaling

    return $retval
}


#-------------------------------------------------------------------------------
# .PROC DevWarningWindow
#
#  Report a Warning to the user. Force them to click OK to continue.<br>
#  Resets the tk scaling to 1 and then returns it to the original value.
#
# .ARGS
#  str message The error message. Default: \"Unknown Warning\"
# .END
#-------------------------------------------------------------------------------
proc DevWarningWindow {{message "Unknown Warning"}} {
    set oscaling [tk scaling]
    tk scaling 1
    tk_messageBox -title "Slicer" -icon warning -message $message
    tk scaling $oscaling
}

#-------------------------------------------------------------------------------
# .PROC DevInfoWindow
#
#  Report Information to the user. Force them to click OK to continue.<br>
#  Resets the tk scaling to 1 and then returns it to the original value.
#
# .ARGS
#  str message The error message. Default: \"Unknown Warning\"
# .END
#-------------------------------------------------------------------------------
proc DevInfoWindow {message} {
    set oscaling [tk scaling]
    tk scaling 1
    tk_messageBox -title "Slicer" -icon info -message $message -type ok
    tk scaling $oscaling
}

#-------------------------------------------------------------------------------
# .PROC DevErrorWindow
#
#  Report an Error to the user. Force them to click OK to continue.<br>
#  Resets the tk scaling to 1 and then returns it to the original value.
#
# .ARGS
#  str message The error message. Default: \"Unknown Error\"
# .END
#-------------------------------------------------------------------------------
proc DevErrorWindow {{message "Unknown Error"}} {
    set oscaling [tk scaling]
    tk scaling 1
    if {$::Module(verbose)} {
        puts "$message"
    }
    tk_messageBox -title Slicer -icon error -message $message -type ok
    tk scaling $oscaling
}

#-------------------------------------------------------------------------------
# .PROC DevFatalErrorWindow
#
#  Report an Error to the user and then exit.
#
# .ARGS
#  str message The error message. Default: \"Fatal Error\"
# .END
#-------------------------------------------------------------------------------
proc DevFatalErrorWindow {{message "Fatal Error"}} {
   ErrorWindow $message
   MainExitProgram
}

#-------------------------------------------------------------------------------
# .PROC DevAddLabel
#
#  Creates a label.<br>
#  Example:  DevAddLabel $f.lmylabel \"Have a nice day\"
#
# 
# .ARGS
#  str LabelName  Name of the button (i.e. $f.stuff.lmylabel)
#  str Message    The text on the label
#  str Color      Label color and attribs from Gui.tcl (BLA or WLA). Optional
# .END
#-------------------------------------------------------------------------------
proc DevAddLabel { LabelName Message {Color WLA}} {
    global Gui
    eval {label $LabelName -text $Message} $Gui($Color)
}

#-------------------------------------------------------------------------------
# .PROC DevAddEntry
#
# Adds an entry box.<br>
# Example: DevAddEntry View parallelScale $f.eParallelScale <br>
# Example: DevAddEntry View parallelScale $f.eParallelScale 20<br>
# Adds an entry corresponding to variable View(parallelScale).
# The first one has width 10, the second has width 20
#
# .ARGS
# str ArrayName the name of the array containing the variable to update.
# str Variable the name of the varriable in the array, this is changed when the entry is updated
# str EntryName the name of the entry box, ie f.fStuff.eStuff
# int Width optional width of the entry box, defaults to 10
# .END
#-------------------------------------------------------------------------------
proc DevAddEntry { ArrayName Variable EntryName {Width 10}} {
    global Gui $ArrayName

    eval {entry $EntryName -textvariable "$ArrayName\($Variable\)" \
        -width $Width } $Gui(WEA)
}


#-------------------------------------------------------------------------------
# .PROC DevAddButton
#
#  Creates a button.<br>
#  Example:  DevAddButton $f.bmybutton \"Run me\" \"DoStuff\" 10<br>
#  Example:  DevAddButton $f.bmybutton \"Run me\" \"DoStuff\"<br>
#  The first example creates a button of width 10 that says \"Run me\",
#  and Calls procedure \"DoStuff\" when pressed.<br>
#  The second example does the same except it automatically determines 
#  the width of the button.
#
# .ARGS
#  str ButtonName Name of the button (i.e. f.stuff.bStuff)
#  str Message    The text on the button
#  str Command    The command to run
#  str Width      Optional Width. Default: width of the Message.
# .END
#-------------------------------------------------------------------------------
proc DevAddButton { ButtonName Message Command {Width 0} } {
    global Gui
    if {$Width == 0 } {
        set Width [expr [string length $Message] +2]
    }
    eval  {button $ButtonName -text $Message -width $Width \
            -command $Command } $Gui(WBA)
} 

#-------------------------------------------------------------------------------
# .PROC DevAddSelectButton
#
#  Add a Select Button to the GUI
#
#<br>  Example: DevAddSelectButton MyModule $f Volume1 "Reference Volume" Grid
#<br>    Creates a Volume select button with text "Reference Volume" to the left.
#      Grids the result.
#<br>    Creates $f.lVolume1     : The Label
#<br>    Creates $f.mbVolume1   : The Menubutton
#<br>    Creates $f.mbVolume1.m : The Menu
#<br>    Creates MyModule(mbVolume1) = $f.mbVolume1; This is for update
#       in MyModuleUpdateMrml 
#
#<br>  Example2: DevAddSelectButton MyModule $f Model1 "Model Choice" Grid
#
#<br> Note that we have not yet chosen the variable we are going to effect.
#<br> Also, we need a procedure like DevUpdate to make the update.
#
# .ARGS
#  array TabName  This is typically the name of the module.
#  widget f       Frame the button should go on
#  str   aLabel    This is the name of the button widget (i.e. MySelectVolumeButton)
#  str  message   The message label to put to the left of the Volume Select button. Default \"Select Volume\"
#  str  pack          "Pack" packs the buttons. \"Grid\" grids the buttons.
#  str tooltip    The tooltip to display over the button. Optional.
#  str width      The width to make the button. Optional
#  str color      Message label color and attribs from Gui.tcl (BLA or WLA). Optional
# .END
#-------------------------------------------------------------------------------
proc DevAddSelectButton { TabName f aLabel message pack {tooltip ""} \
    {width 13} {color WLA}} {

    global Gui Module 
    upvar 1 $TabName LocalArray

    # if the variable is not 1 procedure up, try 2 procedures up.

    if {0 == [info exists LocalArray]} {
        upvar 2 $TabName LocalArray 
    }

    if {0 == [info exists LocalArray]} {
        DevErrorWindow "Error finding $TabName in DevAddSelectButton"
        return
    }

    set Label       "$f.l$aLabel"
    set menubutton  "$f.mb$aLabel"
    set menu        "$f.mb$aLabel.m"
   
    # Kilian: Why should we create a label if we do not have a message
    if {$message != ""} {
      DevAddLabel $Label $message $color
    }

    eval {menubutton $menubutton -text "None" \
            -relief raised -bd 2 -width $width -menu $menu} $Gui(WMBA)
    eval {menu $menu} $Gui(WMA)

    if {$pack == "Pack"} {
        if {$message != ""} {pack $Label -side left -padx $Gui(pad) -pady 0} 
        pack $menubutton -side left -padx $Gui(pad) -pady $Gui(pad) 
    } else {
        if {$message != ""} { grid $Label -sticky e -padx $Gui(pad) -pady $Gui(pad)}
        grid $menubutton -sticky e -padx $Gui(pad) -pady $Gui(pad)
        grid $menubutton -sticky w
    }

    if {$tooltip != ""} {
        TooltipAdd $menubutton $tooltip
    }
    
    set LocalArray(mb$aLabel) $menubutton
    set LocalArray(m$aLabel) $menu

    # Note: for the automatic updating, we can use
    # lappend Model(mbActiveList) $f.mb$ModelLabel
    # lappend Model(mActiveList)  $f.mbActive.m
    # 
    # or we can use DevUpdateVolume in the MyModuleUpdate procedure

    # Note: for the automatic updating, we can use
    # lappend Volume(mbActiveList) $f.mb$VolLabel
    # lappend Volume(mActiveList)  $f.mbActive.m
    # 
    # or we can use DevUpdateVolume in the MyModuleUpdate procedure
}   


## 
## I left this code here as an example of how to update Volumes alone.
## The code is slightly less complicated then my implementation for
## both Volumes and Models.
##
#proc DevUpdateVolume {ArrayName VolumeLabel VolumeName { CommandSetVolume DevSetVolume} { None 1 }  { New 0 } { LabelMap 1 }  } {
#
#        global Volume 
#        upvar $ArrayName LocalArray
#
#        # See if the selected volume for each menu actually exists.
#        # If not, use the first volume in the list
#       if {[lsearch $Volume(idList) $LocalArray($VolumeName) ] == -1} {
#           $CommandSetVolume [lindex $Volume(idList) 0] $ArrayName $VolumeLabel $VolumeName
#        }
#
#        # Menu of Volumes
#        # ------------------------------------
#        set m $LocalArray(mb$VolumeLabel).m
#        $m delete 0 end
#        # All volumes except none
#        foreach v $Volume(idList) {
#            set test 1
#            # Show Volume(idNone)?
#            if {$None==0}      { set test [expr $v != $Volume(idNone)] }
#
#            # Show LabelMaps?
#            if {$LabelMap==0 && $test }  {
#                set test Expr[ [Volume($v,node) GetLabelMap] == 0]}
#
#            if $test {
#                $m add command -label "[Volume($v,node) GetName]" \
#                -command "$CommandSetVolume $v $ArrayName $VolumeLabel $VolumeName"
#                }
#        }
#        if {$New} {
#            $m add command -label "Create New" \
#           -command "$CommandSetVolume -5 $ArrayName $VolumeLabel $VolumeName"
#        }
#}   

#-------------------------------------------------------------------------------
# .PROC DevUpdateNodeSelectButton
#
#  Call this routine from MyModuleUpdateDev or its eqivalent.
#<br>  Example: DevUpdateSelectButton Volume MyModule Volume1 Volume1 DevSelect
#<br>     Updates the menubutton Volume List for the button with label Volume1.
#<br>     Updates the menubutton Face text  for the button with label Volume1.
#<br>     Sets the Command to call to set the Volume to be DevSelect.
#
#<br> Example2: DevUpdateSelectButton Model MyModule Model1 Model1 DevSelect
#
#<br> Note that ArrayName(Name) must exist.
#
# .ARGS
#  str type Either \"Model\" or \"Volume\".
#  array ArrayName The array name containing the Volume Choice. Usually the module name.
#  str Label This is the label of the bottons.
#  str Name  The Volume or Model choice is stored in ArrayName(Name)
#  str CommandSet This is the command to run to set the volume or model name. The default is DevSelectNode.  Arguments sent to it are type, the volume id and then ArrayName VolumeLabel VolumeName. Note that if you decide to make your own SetVolume command which requires other arguments, you can do this by setting CommandSetVolume to \"YourCommand arg1 arg2\" You must be able to deal with a \"\" id.
#  bool None 1/0 means do/don't include the None NodeType. 1 is the default
#  bool New 1/0 means do/don't include the New NodeType. 0 is the default
#  bool LabelMap 1/0 means do/don't include LabelMaps. For Volumes Only. 0 is the defaulte
#  str Command2Set a second CommandSet, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc DevUpdateNodeSelectButton { type ArrayName Label Name { CommandSet "DevSelectNode" } { None 1 } { New 0 } { LabelMap 1 } {Command2Set ""} } {

    global Volume Model Tensor
    upvar $ArrayName LocalArray
    upvar 0 $type NodeType

    # See if the NodeType for each menu actually exists.
    # If not, use the None NodeType
    set v $NodeType(idNone)

    if {[lsearch $NodeType(idList) $LocalArray($Name) ] == -1} {
            $CommandSet $type [lindex $NodeType(idList) 0]  $ArrayName $Label $Name
    }

    # Menu of NodeTypes
    # ------------------------------------
    set m $LocalArray(mb$Label).m
    $m delete 0 end
    # All volumes except none

    foreach v $NodeType(idList) {
            set test 1
            # Show NodeType(idNone)?
            if {$None==0}      { set test [expr $v != $NodeType(idNone)] }

            # Show LabelMaps?
            if {($LabelMap==0) && ($type=="Volume") && $test }  {
                if { [${type}($v,node) GetLabelMap] != 0 } {
                    set test 0
                }
            }

 

            if $test {
                set colbreak [MainVolumesBreakVolumeMenu $m] 
                $m add command -label [${type}($v,node) GetName] \
                    -command "$CommandSet $type $v $ArrayName $Label $Name; $Command2Set" \
                    -columnbreak $colbreak
        }
    }

    set colbreak [MainVolumesBreakVolumeMenu $m] 
    if {$New} {
        $m add command -label "Create New" \
            -command "$CommandSet $type -5 $ArrayName $Label $Name" \
            -columnbreak $colbreak
    }
}

#-------------------------------------------------------------------------------
# .PROC DevUpdateSelectButton
#
# Updates a Simple Select Button.<br>
# Note that ArrayName(Name) and ArrayName(ChoiceList) must exist.
#
# .ARGS
#  array ArrayName The array name containing the Volume Choice. Usually the module name.
#  str Label This is the label of the buttons.
#  str Name  The Current choice is stored in ArrayName(Name)
#  array ChoiceList The possible choices are ArrayName(ChoiceList)
#  str Command  The command to run. The default is no command. (Though, in both cases, the Button display is updated).  Arguments sent to it are the selected choice. Note that if the command requires other arguments, you can do this by setting Command to \"YourCommand arg1 arg2\" You should be able to deal with a \"\" selection. 
# .END
#-------------------------------------------------------------------------------
proc DevUpdateSelectButton { ArrayName Label Name ChoiceList {Command ""} } {

        upvar $ArrayName LocalArray

    # Delete all the current options and create the new ones
    # ------------------------------------
    set m $LocalArray(mb$Label).m
    $m delete 0 end

    foreach v $LocalArray($ChoiceList) {
            if {$Command != ""} {
                $m add command -label $v -command "$LocalArray(mb$Label) config -text $v; $Command $v"
            } else {
                $m add command -label $v -command "$LocalArray(mb$Label) config -text $v"
            }
        }
    }

#-------------------------------------------------------------------------------
# .PROC DevSelectNode
#
# Usually called when a Select button has been
# clicked on. Sets the text to put on the button as well as setting
# the variable to the volume id chosen.
# 
# .ARGS
# str type \"Volume\" or \"Model\"
# int id the id of the selected volume
# array ArrayName The name of the array whose variables will be changed.
# str ModelLabel The name of the menubutton, without the \"mb\"
# str ModelName  The name of the variable to set.
# .END
#-------------------------------------------------------------------------------
proc DevSelectNode { type id ArrayName ModelLabel ModelName} {
    global Model Volume
    upvar $ArrayName LocalArray

    if {0 == [info exists LocalArray]} {
        upvar 2 $ArrayName LocalArray 
    }

    if {0 == [info exists LocalArray]} {
        DevErrorWindow "Error finding $ArrayName in DevAddSelectButton"
        return
    }
    if {$id == ""} {
            $LocalArray(mb$ModelLabel) config -text "None"
    } elseif {$id == -5} {
            set LocalArray($ModelName) $id
            $LocalArray(mb$ModelLabel) config -text \
                    "Create New"
        } else {
           set LocalArray($ModelName) $id
            $LocalArray(mb$ModelLabel) config -text \
                    "[${type}($id,node) GetName]"
    }
}

#-------------------------------------------------------------------------------
# .PROC DevCreateNewCopiedVolume
# 
# Returns the id number of the new Volume.<br>
# Note: does not copy the volume data. Use MainVolumesCopyData to do that.
#
# .ARGS
# int OrigId  The id of the volume to copy.
# str Description The Description of the new Volume. Default if empty string: Copy VolumeId's Description.
# str VolName     The Name of the new Volume. Default if empty string: copy the VolumeId's Name.
# .END
#-------------------------------------------------------------------------------
proc DevCreateNewCopiedVolume { OrigId {Description ""} { VolName ""} } {
    global Volume Lut

    # Create the new node
    # newvol is now a vtkMrmlVolumeNode, a subclass of vtkMrmlNode. 
    # How about that?
    set newvol [MainMrmlAddNode Volume]

    # Copies all the important stuff of the vtkMrmlVolumeNode
    # Copy the node's attributes to this object: strings, numbers, vectors, matricies..
    # Does NOT copy: ID, FilePrefix, Name
    # This copy does not include the data. (Lauren is that right?)

    $newvol Copy Volume($OrigId,node)

#    # Let's say you want to create a new Volume and only copy the minimum amount of
#    # stuff. As far as I can tell, this is how to do it. Just get rid of the "Copy"
#    # line and use this stuff.
#
#    # Largely copied from EditorGetWorkingID on Feb 25,2000
#    # Also from  EditorCopyNode
#    #  by Samson Timoner
#
#    # Copies everything in the vtkMrmlNode except the id.
#    # As I write this, CopyNode only copies the description
#    # and a few "options" which aren't necessary. However,
#    # this function should be kept for future compatibility
#    # in case the function actually does something important
#    # someday.
#    # Note that vtkMrmlNode is part of vtkMrmlVolume. So,
#    # we have yet to update most of vtkMrmlVolume.
#
#    $newvol CopyNode Volume($OrigId,vol)
#
#    # Copy the lookup table from the given volume
#                                     
#    $newvol SetLUTName     $Lut($OrigId)
#    $newvol SetInterpolate [$Volume($OrigId,vol) GetInterpolate]
#    $newvol SetLabelMap    [$Volume($OrigId,vol) GetLabelMap]
#

    # Set the Description and Name
    if {$Description != ""} {
        $newvol SetDescription $Description 
    }
    if {$VolName != ""} {
        $newvol SetName $VolName
    }

    # Create the volume
    set n [$newvol GetID]
    MainVolumesCreate $n
#    Volume($n,vol) UseLabelIndirectLUTOn

    # This updates all the buttons to say that the
    # Volume List has changed.
    MainUpdateMRML

    return $n
}

#-------------------------------------------------------------------------------
# .PROC DevGetFile
# 
# If a file with filename exists, simply return it.<br>
# Otherwise pops up a window to find a filename.<br>
# Default directory to start searching in is the one Slicer was called from
#
# .ARGS
# str filename The name of the file entered so far
# int MustPop  1 means that we will pop up a window even if \"filename\" exists. Default is 0.
# str DefaultExt The name of the extension for the type of file: Default \"\"
# str DefaultDir The name of the default directory to choose from: Default is the directory Slicer was started from.
# str Title      The title of the window to display.  Optional, defaults to \"Choose File\"
# str Action     Whether to Open (file must exist) or Save.  Default is \"Open\".
# str PathType   Relative or Absolute, defaults to Relative
# .END
#-------------------------------------------------------------------------------
proc DevGetFile { filename { MustPop 0} { DefaultExt "" } { DefaultDir "" } {Title "Choose File"} {Action "Open"} {PathType "Relative"}} {
    global Mrml

    # Default Directory Choice
    if {$DefaultDir == ""} {
            set DefaultDir $Mrml(dir);
    }

    ############################################################
    ######  Check if the filename exists
    ######  Check with/without DefaulExt, and with or without
    ######  Default dir.
    ######  Do this only if the filename is not "" and is not a dir.
    ############################################################
    if {$::Module(verbose)} {
        puts "DevGetFile: filename = $filename, pathtype = $PathType"
    }
    if {$filename != "" && ![file isdir $filename] && !$MustPop} {
        if [file exists $filename]  {
            return [MainFileGetRelativePrefix $filename][file \
                                                             extension $filename]
        }
        if [file exists "$filename.$DefaultExt"] {
            return [MainFileGetRelativePrefix $filename].$DefaultExt
        }
        set filename [file join $DefaultDir $filename]
        if [file exists $filename]  {
            return [MainFileGetRelativePrefix $filename][file \
                                                             extension $filename]
        }
        if [file exists "$filename.$DefaultExt"] {
            return [MainFileGetRelativePrefix $filename].$DefaultExt
        }
    }
    
    ############################################################
    ######  Didn't find it, now set up filter for files
    ######  If an extension is provided, use it.
    ############################################################
    
    if { $DefaultExt != ""} {
        set ext_list ""
        foreach ext $DefaultExt {
            if { ![string match .* $ext] } {
                lappend ext_list .$ext
            } else {
                lappend ext_list $ext
            }
        }
        set typelist [list [list Files $ext_list]]
        append typelist " \{\"All Files\" \{\*\}\}"
    } else {
        set typelist {{"All Files" {*}}}
    }
    
    ############################################################
    ######  Browse for the file
    ############################################################
    
    set dir [file dirname $filename]
    if { $filename == "" && $DefaultDir != "" } { set dir $DefaultDir }
    if { [file isdir $filename] } { set dir $filename }

    set filename [file tail $filename]
    
    # if we are saving, the file doesn't have to exist yet.
        
    if {$Action == "Save"} {
        set filename [tk_getSaveFile -title $Title \
                          -filetypes $typelist -initialdir "$dir" -initialfile $filename]
    } else {
        set filename [tk_getOpenFile -title $Title -filetypes $typelist -initialdir "$dir" -initialfile "$filename"]                
    }
    
    
    ############################################################
    ######  Return Nothing is nothing was selected
    ######  Return the file relative to the current path otherwise
    ############################################################
    
    # Return nothing if the user cancelled
    if {$filename == ""} {return "" }
    
    # if the file will be Saved (not Opened) make sure it has an extension
    if {$Action == "Save"} {
        if {[file extension $filename] == ""} {
            set filename "$filename.$DefaultExt"
        }   
    }
    
    # If the file is not to be stored relative to the Mrml dir.
    if {$PathType == "Absolute"} {
        return $filename
    }
    
    # Store first image file as a relative filename to the root 
    # Return the relative Directory Path
    return [MainFileGetRelativePrefix $filename][file \
                                                     extension $filename]
}   

#-------------------------------------------------------------------------------
# .PROC DevAddFileBrowse
#
# Calls DevGetFile, so defaults for Optional Arguments are set there.<br>
# ArrayName(VarFileName) must exist already!<br>
# 
# Make a typical button for browsing for files.<br>
#  Example:  DevAddFileBrowse $f.fPrefix Custom Prefix \"File\"<br>
#  Example:  DevAddFileBrowse $f.fPrefix Custom Prefix \"vtk File\" \"vtk\" \"\" \"Browse for a model\"<br>
#  Example: DevAddFileBrowse $f Volume firstFile "First Image File:" "VolumesSetFirst" "" "\$Volume(DefaultDir)"  "Browse for the first Image file" <br>
#
# In the last example, the trick using "\$Volume(DefaultDir)" allows you
# to change the default directory later.<br>
#
# .ARGS
# str Frame      The name of the existing frame to modify.
# array ArrayName The name of the array whose variables will be changed.
# str VarFileName The name of the file name variable within the array.
# str Message     The message to display near the "Browse" button.
# str Command     A command to run when a file name is entered AND the file entered exists (unless Action is Save, when the file need not exist yet). Optional, defaults to empty string.
# str DefaultExt The name of the extension for the type of file. Optional, defaults to empty string.
# str DefaultDir The name of the default directory to choose from. Optional, defaults to emtpy string
# str Action     Whether this is \"Open\" or \"Save\".  Optional, defaults to emtpy string
# str Title      The title of the window to display. Optional, defaults to emtpy string
# str Tooltip    The tooltip to display over the button. Optional, defaults to emtpy string
# str PathType   Default is filename is relative to Mrml(dir).  Use "Absolute" for absolute pathnames
# .END
#-------------------------------------------------------------------------------
proc DevAddFileBrowse {Frame ArrayName VarFileName Message { Command ""} { DefaultExt "" } { DefaultDir "" } {Action ""} {Title ""} {Tooltip ""} {PathType ""}} {

    global Gui $ArrayName Model
    
    if {$::Module(verbose)} {
        # puts "\nDevAddFileBrowse:\n\t frame $Frame \n\t arrayname $ArrayName \n\t varfilename $VarFileName \n\t  message $Message \n\t command $Command \n\t defaultext $DefaultExt\n\t defaultdir $DefaultDir \n\t action $Action \n\t title $Title \n\t tooltip $Tooltip \n\t pathtype $PathType"
    }
    if {$Action != "" && $Action != "Open" && $Action != "Save"} {
        DevErrorWindow "DevAddFileBrowse: Action should be Open or Save, \"$Action\" is not valid\nFrame: $Frame"
    }
    set f $Frame
    $f configure  -relief groove -bd 3 -bg $Gui(activeWorkspace)
    
    frame $f.f -bg $Gui(activeWorkspace)
    pack $f.f -side top -padx $Gui(pad) -pady $Gui(pad)
    
    ## Need to make the string that will become the command.
    # this pops up file browser when the button is pressed.
    set SetVarString  "set $ArrayName\($VarFileName\) \[ DevGetFile \"\$$ArrayName\($VarFileName\)\" 1  \"$DefaultExt\" \"$DefaultDir\" \"$Title\"  \"$Action\" \"$PathType\" \]; if \{\[DevFileExists \$$ArrayName\($VarFileName\)\] || \"$Action\" == \"Save\"\}  \{ $Command \}"
    #$Action == Save
    #        puts $SetVarString
    
    DevAddLabel  $f.f.l $Message
    DevAddButton $f.f.b "Browse..." $SetVarString
    
    pack $f.f.l $f.f.b -side left -padx $Gui(pad)
    
    # tooltip over the button.
    if {$Tooltip != ""} {
        TooltipAdd $f.f.b $Tooltip
    }
    
    # this pops up file browser when return is hit.
    set SetVarString  "set $ArrayName\($VarFileName\) \[ DevGetFile \"\$$ArrayName\($VarFileName\)\" 0  \"$DefaultExt\" \"$DefaultDir\" \"$Title\" \"$Action\" \"$PathType\" \]; if \{\[DevFileExists \$$ArrayName\($VarFileName\)\] || \"$Action\" == \"Save\"\}  \{ $Command \}"
    
    eval {entry $f.efile -textvariable "$ArrayName\($VarFileName\)" -width 50} $Gui(WEA)
    bind $f.efile <Return> $SetVarString
    
    pack $f.efile -side top -pady $Gui(pad) -padx $Gui(pad) \
        -expand 1 -fill x
}

#-------------------------------------------------------------------------------
# .PROC DevCreateScrollList
#
# Creates a Scrolled List. The programmer can pass a procedure on how
# to create each line in the list. <br>
# Note: Checks if the list already exists and deletes it if it does.<br>
#
# Creates $ScrollFrame.cGrid which is the canvas.<br>
# Creates $ScrollFrame.cGrid.fListItems which is the item frame<br>
#
# Example Usage : See Models.tcl<br>
#   frame $f.fScroll -bg $Gui(activeWorkspace)<br>
#   pack  .... $f.fScroll -side top -pady 1<br>
#
#   DevCreateScrollList $Module(Models,fDisplay).fScroll MainModelsCreateGUI \<br>
#                       ModelsConfigScrolledGUI "$Model(idList)"<br>
#
#
# 
# .ARGS
#   frame ScrollFrame
#   list  ItemCreateGui 2 args: the frame for the Item list and the item. 
#   list  ScrollListConfigScrolledGUI: 2 args: canvas and item frame.
#   list  ItemList list of items
# .END
#-------------------------------------------------------------------------------
proc DevCreateScrollList {ScrollFrame ItemCreateGui ScrollListConfigScrolledGUI ItemList} {
    global Mrml Gui Module

    #################################
    # Delete everything from last time, if there was a last time.
    #################################
    set f $ScrollFrame
    set canvas $f.cGrid
    catch {destroy $canvas}
    set sy $f.syGrid
    set sx $f.sxGrid
    catch {destroy $sy}
    catch {destroy $sx}

    #################################
    # Create the new canvas
    #################################
    canvas $canvas -yscrollcommand "$sy set" \
                   -xscrollcommand "$sx set" -bg $Gui(activeWorkspace)
    eval "scrollbar $sy -command \"DevCheckScrollLimits $canvas yview\" \
            $Gui(WSBA)"
    eval "scrollbar $sx -command \"$canvas xview\" \
            -orient horizontal $Gui(WSBA)"

    pack $sy -side right -fill y
    pack $sx -side bottom -fill x
    pack $canvas -side top  -fill both -expand true

    set f $canvas.fListItems
    frame $f -bd 0 -bg $Gui(activeWorkspace)
    
    # put the frame inside the canvas (so it can scroll)
    $canvas create window 0 0 -anchor nw -window $f

    foreach m $ItemList {
        $ItemCreateGui $f $m
    }

    $ScrollListConfigScrolledGUI $canvas $f
}

#-------------------------------------------------------------------------------
# .PROC DevCheckScrollLimits 
# 
# This procedure allows scrolling only if the entire frame is not visible
#
# .ARGS
# list args a list containing the canvas, and view
# .END
#-------------------------------------------------------------------------------
proc DevCheckScrollLimits {args} {

    set canvas [lindex $args 0]
    set view   [lindex $args 1]
    set fracs [$canvas $view]

    if {double([lindex $fracs 0]) == 0.0 && \
        double([lindex $fracs 1]) == 1.0} {
        return
    }
    eval $args
}

#-------------------------------------------------------------------------------
# .PROC DevFileExists
# 
# Returns 1 if file exists, either relative to mrml directory or not.
# .ARGS
# str filename the file the check
# .END
#-------------------------------------------------------------------------------
proc DevFileExists {filename} {
    global Mrml

    if {[file exists $filename]} {
        return 1
    }

    if {[file exists [file join $Mrml(dir) $filename]]} {
        return 1
    }

    return 0
}

#-------------------------------------------------------------------------------
# .PROC DevSourceTclFilesInDirectory
#
# Source all tcl files found in directory dir.  Returns a list of
# the files (without the leading path or file extension).
# .ARGS
# path dir location of the files
# int verbose optional, defaults to 0, whether to puts the filenames
# .END
#-------------------------------------------------------------------------------
proc DevSourceTclFilesInDirectory {dir {verbose "0"}} {

    # from Go.tcl.  Looks locally and centrally.
    set found [FindNames $dir]
    if {$verbose == 1} {puts $found}

    set sourced ""

    # If it's a tcl file source it and save its name on a list
    foreach name $found {
        # from Go.tcl.  Finds local or central full path of tcl file
        set path [GetFullPath $name tcl $dir]
        # If a tcl file exists source it and save name
        if {$path != ""} {
            if {$verbose == 1} {puts "source $path"}
            source $path
            lappend sourced $name
        } 
    }

    # return the list of sourced files
    return $sourced
}

#-------------------------------------------------------------------------------
# .PROC DevPrintMrmlDataTree
# A helper proc to print out bits of the mrml data tree for debugging volumes and transforms.
# .ARGS 
# array tagList class names to match, optional, defaults to Volume
# int justMatrices if 1, just print the matrices in the volume
# .END
#-------------------------------------------------------------------------------
proc DevPrintMrmlDataTree { { tagList "Volume" } { justMatrices 1 } } {
    global Module Mrml

    if {$::Module(verbose)} {
        puts "DevPrintMrmlDataTree: tagList = $tagList, justMatrices = $justMatrices"
    }
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        set class [$node GetClassName]
        set name [$node GetName]
        if {$::Module(verbose)} {
            puts "\t${name}: class = $class"
        }
        if {$class == "vtkMrmlScenesNode"} {
            puts "Scene: [$node GetName]"
        }
        foreach tag $tagList {
            if {$class == "vtkMrml${tag}Node"} {
                if {$tag == "Volume"} {
                    if {$justMatrices} {
                        puts "$class [$node GetID] $name"
                        DevPrintMatrix4x4 [$node GetPosition] "Position"
                        DevPrintMatrix4x4 [$node GetRasToIjk] "RAS -> IJK"
                        if {[$node GetUseRasToVtkMatrix] == 1} {
                            if {[info command "$node GetRasToVtk"] == ""} {
                                # try getting the matrix
                                DevPrintMatrix [$node GetRasToVtkMatrix] "RAS -> VTK"
                            } else {
                                DevPrintMatrix4x4 [$node GetRasToVtk] "RAS -> VTK"
                            }
                        }
                        DevPrintMatrix4x4 [$node GetRasToWld] "RAS -> WLD"
                        DevPrintMatrix4x4 [$node GetWldToIjk] "WLD -> IJK"
                    } else {
                        $node Print
                    }
                }
                if {$tag == "Matrix"} {
                    puts "$class [$node GetID]"
                    DevPrintMatrix [$node GetMatrix] "Matrix"
                }
                if {$tag == "Model"} {
                    puts "Model [$node GetID] [$node GetName]" 
                    DevPrintMatrix4x4 [$node GetRasToWld] "RAS -> WLD"
                }
                if {$tag == "Module"} {
                    puts "Module node $node [$node GetModuleRefID]"
                    puts "\tName = [$node GetName]"
                    puts "\tValues = "
                    set keys [$node GetKeys]
                    foreach k $keys {
                        puts "\t\t$k = [$node GetValue $k]"
                    }
                }
            }
        }
        set node [Mrml(dataTree) GetNextItem]   
    }

}

#-------------------------------------------------------------------------------
# .PROC DevPrintMatrix
# Print out a string as a 4 by 4 matrix.
# .ARGS
# varname mat the matrix string to print
# str name optional describtive string, defaults to \"matrix\"
# .END
#-------------------------------------------------------------------------------
proc DevPrintMatrix { mat {name "matrix"} } { 
    puts "$name:"
    # puts $mat
    set i 0
    while {$i < [llength $mat]} {
        puts -nonewline [format "% 3.05f" [lindex $mat $i]]
        if {[expr fmod([expr $i + 1],4)] == 0.0} {
            puts -nonewline "\n"
        } else {
            puts -nonewline "\t"
        }
        incr i
    }
}

#-------------------------------------------------------------------------------
# .PROC DevPrintMatrix4x4
# Prints out a vtk 4x4 matrix.
# .ARGS
# varname mat the matrix string to print
# str name optional describtive string, defaults to \"matrix\"
# .END
#-------------------------------------------------------------------------------
proc DevPrintMatrix4x4 { mat { name "matrix"} } {
    puts "$name:"
    for {set i 0} { $i < 4} { incr i} {
        for { set j 0} { $j < 4} { incr j} {
            puts -nonewline [format "% 3.05f\t" [$mat GetElement $i $j]]
        }
        puts -nonewline "\n"
    }
}

#-------------------------------------------------------------------------------
# .PROC DevCreateTextPopup
#
#  Creates a popup scrolled text window  of specified text height and position,
#  that displays formatted text specified in a string. Includes a button
#  that dismisses the window.
#
# .ARGS
#  string topicWinName unique window name
#  string title window title
#  int x y position of window
#  int textBoxHit number of textlines that set initial window height
#  str txt formatted text string to display
# .END
#-------------------------------------------------------------------------------
proc DevCreateTextPopup { topicWinName title x y textBoxHit txt  } {
    set w .w$topicWinName
    #--- if .w$topicWinName exists,
    #--- destroy it, and create a new one
    #--- containing new requested text.
    if { [info exists $w] } {
        -command "destroy $w"
    }
    
    #--- format text.
    regsub -all "\n" $txt {} txt
    DevApplyTextTags $txt
    if { ![info exists ::Dev(TextFormat,tagList)] } {
        set ::Dev(TextFormat,tagList) ""
    }
    
    #--- create popup window and configure
    toplevel $w -class Dialog -background #FFFFFF
    wm title $w $title
    wm iconname $w Dialog
    wm geometry $w +$x+$y
    focus $w

    set dismissButtonHit 4
    set minWinHit [ expr $textBoxHit + $dismissButtonHit ]
    wm minsize $w 30 $minWinHit
    frame $w.fMsg -background #FFFFFF
    frame $w.fButton -background #FFFFFF
    pack $w.fMsg -fill both -expand true
    pack $w.fButton -side top -pady 4 -padx 4

    #--- make scrolled text widget to contain text
    set f $w.fMsg
    set helpt [ text $f.tMessage -height $textBoxHit -width 35 -setgrid true -wrap word \
                -yscrollcommand "$f.sy set" -cursor arrow -insertontime 0 -bg #FFFFFF ]
    scrollbar $f.sy -orient vert -command "$f.tMessage yview" -background #DDDDDD \
                    -activebackground #DDDDDD
    pack $f.sy -side right -anchor e -fill y
    pack $f.tMessage -side left -fill both -expand true -padx 4 -pady 4
    
    #--- make button to dismiss the window
    set f $w.fButton
    button $f.bDismiss -text "close" -width 6 -bg #DDDDDD \
        -command "destroy $w"
    pack $f.bDismiss -padx 4 -pady 4 -side bottom
    
    #--- set the font to be 10 point helvetica
    $f.bDismiss config -font "-Adobe-Helvetica-Normal-R-Normal-*-10-*-*-*-*-*-*-*"

    #--- insert the text and raise window.
    DevInsertPopupText $helpt
#    DevRaisePopup $w
}

#-------------------------------------------------------------------------------
# .PROC DevApplyTextTags
#
#  Processes tagged string and sets some
#  global variables Dev(*) to contain formatting info
#  and text string to display.
#
# .ARGS
#  string str string that includes formatting
# .END
#-------------------------------------------------------------------------------
proc DevApplyTextTags { str } {

    set Dev(TextFormat,hypertext) $str

    # Routines adapted from those in MainHelp.tcl
    # Replace some tags with text or nothing
    #--------------------------------------------------
    foreach tag "<P> <LI> </LI> <BR> <UL> </UL> <HR> &nbsp; &gt; &lt; &amp;" \
        sub {"\n\n" "\n<G>doc/bullet.gif</G>" "" "\n" "" "" "" " " ">" "<" "&" \
        } {
        set i [string first $tag $str]
        while {$i != -1} {
            set str "[string range $str 0 [expr $i-1]]$sub\
            [string range $str [expr $i+[string length $tag]] end]"
            set i [string first $tag $str]
        }
    }

    # Put sub before tag
    #--------------------------------------------------
    foreach tag "<H3> <H4> <H5>" sub {"\n\n" "\n\n"} {
        set i [string first $tag $str]
        set rest $str
        set str ""
        while {$i != -1} {
            set str "${str}[string range $rest 0 [expr $i-1]]$sub$tag"
            set rest [string range $rest [expr $i+[string length $tag]] end]
            set i [string first $tag $rest]
        }
        set str "$str$rest"
    }
    
    # Find tags
    #--------------------------------------------------
    set tag 0
    set tagList ""
    set type normal
    set text $str
    set tokens "B I H3 H4 H5 A G"
    set names "bold italic heading3 heading4 heading5 link image"

    set a [string length $str]
    set type -1
    foreach token $tokens name $names {
        set d [string first <$token> $str]
        if {$d != "-1" && $d < $a} {
            set a $d
            set type $name
            set symbol $token
        }
    }
        while {$type != -1} {

        set text [string range $str 0 [expr $a-1]]
        if {[string length $text] > 0} {
            set ::Dev(TextFormat,$tag,type) normal
            set ::Dev(TextFormat,$tag,text) $text
            lappend tagList $tag
            incr tag
        }

        set rest [string range $str [expr $a+2+[string length $symbol]] end]
        set b [string first </$symbol> $rest]
        set text [string range $rest 0 [expr $b-1]]

        set ::Dev(TextFormat,$tag,type) $type
        set ::Dev(TextFormat,$tag,text) $text
        lappend tagList $tag
        incr tag
        set str [string range $rest [expr $b+3+[string length $symbol]] end]

        set a [string length $str]
        set type -1
        foreach token $tokens name $names {
            set d [string first <$token> $str]
            if {$d != "-1" && $d < $a} {
                set a $d
                set type $name
                set symbol $token
            }
        }
    }

    set text $str
    if {[string length $text] > 0} {
        set ::Dev(TextFormat,$tag,type) normal
        set ::Dev(TextFormat,$tag,text) $text
        lappend tagList $tag
        incr tag
    }
    set ::Dev(TextFormat,tagList) $tagList

}

#-------------------------------------------------------------------------------
# .PROC DevInsertPopupText
#
#  Configures text widget
#
# .ARGS
#  string w text widget name in which to insert text
# .END
#-------------------------------------------------------------------------------
proc DevInsertPopupText { w } {

    #--- configure text tags 
    #--- I'm borrowing this from Help module, but
    #--- changing it a little bit.
    eval $w tag configure normal   "-font {helvetica 9}"
    eval $w tag configure italic   "-font {helvetica 9 italic}"
    eval $w tag configure bold    "-font {helvetica 9 bold}"
    eval $w tag configure link "-font {helvetica 9} -underline true -foreground blue"
    eval $w tag configure heading3 "-font {helvetica 10 bold}"
    eval $w tag configure heading4 "-font {helvetica 11 bold italic}"
    eval $w tag configure heading5 "-font {helvetica 12 bold}"

    foreach tag $::Dev(TextFormat,tagList) {
        set type $::Dev(TextFormat,$tag,type)
        set text $::Dev(TextFormat,$tag,text)

        if {$type == "heading3"} {
            set ::Dev(TextFormat,$tag,index) [$w index insert]
        }
        
        if {$type == "link"} {
            set type link$tag
            eval $w tag configure $type $::Dev(tagLink)
        }

        if {$type == "image"} {
            set img [image create photo -file [ExpandPath "$text"]]
            $w image create insert -image $img
        } else {
            $w insert insert "$text" $type
        }
    }

    foreach tag $::Dev(TextFormat,tagList) {
        set type $::Dev(TextFormat,$tag,type)
        if {$type == "link"} {
            $w tag bind link$tag <ButtonPress> "DevTextLink $w $tag"
            $w tag bind link$tag <Enter> "$w config -cursor hand2"
            $w tag bind link$tag <Leave> "$w config -cursor arrow"
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC DevTextLink
# Format a text string.
# .ARGS
# widget w the name of the text widget
# str linkTag helps find the text 
# .END
#-------------------------------------------------------------------------------
proc DevTextLink {w linkTag} {

    set linkText $::Dev(TextFormat,$linkTag,text)

    foreach tag $::Dev(TextFormat,tagList) {
        set type $::Dev(TextFormat,$tag,type)
        set text $::Dev(TextFormat,$tag,text)

        if {$type == "heading3"} {
            if {$text == $linkText} {
                $w see $::Dev(TextFormat,$tag,index)
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC DevLaunchBrowser
# Gets the browserUrl from the Path array and calls DevLaunchBrowserURL.
# .ARGS
# str section optional name tag in the page, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc DevLaunchBrowser {{section ""}} {

    if {$section == ""} {
        set url "$::Path(browserUrl)"
    } else {
        set url "$::Path(browserUrl)#$section"
    }
    DevLaunchBrowserURL $url
}

#-------------------------------------------------------------------------------
# .PROC DevLaunchBrowserURL
# Tries to launch the default browser in Path(browserPath) with the given url
# as the starting page.
# .ARGS
# str url the url to open in the browser
# .END
#-------------------------------------------------------------------------------
proc DevLaunchBrowserURL { url } {

    if { $::Path(browserPath) != "unknown" } {
        set ret [catch "exec $::Path(browserPath) $url &" res]
        if { $ret } {
            DevErrorWindow "Could not launch browser.\n\n$res"
        }
    } else {
        DevWarningWindow "Could not detect your default browser.\n\nYou may need to set your BROWSER environment variable.\n\nPlease open $url manually."
    }
}


#-------------------------------------------------------------------------------
# .PROC DevNewInstance
# create a uniquely named vtk class instances
# .ARGS
# class - the vtk class
# prefix - optional name 
# .END
#-------------------------------------------------------------------------------
proc DevNewInstance { class {prefix ""} } {

    if { $prefix == "" } {
        set prefix $class
    }
    set serial 1
    while { [info command ${prefix}_$serial] != "" } {
        incr serial
    }
    return [$class ${prefix}_$serial]
    
}

#-------------------------------------------------------------------------------
# .PROC DevPrintTrace
# Use when setting a trace on a global variable, to print out the value:<br>
# trace variable varname wru DevPrintTrace
# .ARGS
# str name the array name
# str el the element in the array
# str opt w if the variable was written, r if it was read, u if unset
# .END
#-------------------------------------------------------------------------------
proc DevPrintTrace { name el opt} {
    global $name
    puts "$opt ${name}(${el}) = [subst $${name}(${el})]"
}
