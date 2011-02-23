#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: MainTetraMesh.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:55 $
#   Version:   $Revision: 1.13 $
# 
#===============================================================================
# FILE:        MainTetraMesh.tcl
# PROCEDURES:  
#   MainTetraMeshInit
#   MainTetraMeshUpdateMRML
#   MainTetraMeshCopyData dst src
#   MainTetraMeshCreate
#   MainTetraMeshRead
#   MainTetraMeshWrite v prefix
#   MainTetraMeshDelete
#   MainTetraMeshBuildGUI
#   MainTetraMeshUpdate
#   MainTetraMeshRender
#   MainTetraMeshRenderActive
#   MainTetraMeshSetActive v
#   MainTetraMeshVtkDataToTclData VtkMrmlTetraMeshNode
#   MainTetraMeshTclDataToVtkData
#   MainTetraMeshProcessMrml attr
#   MainTetraMeshSetParam
#   MainTetraMeshUpdateSliderRange
#   MainTetraMeshSetGUIDefaults 
#   MainTetraMeshVisualize
#==========================================================================auto=

## Todo: MainTetraMeshInit: defaultoptions
## line 114: setting lookup tables.
## MainTetraMeshCopyData
## MainTetraMeshCreate : The Lookup table.
## MainTetraMeshWrite  : I think I'm done.
## MainTetraMeshRender
## MainTetraMeshRenderActive
## MainTetraMeshBuildGUI
## MainTetraMeshSetParam
#-------------------------------------------------------------------------------
# .PROC MainTetraMeshInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshInit {} {
    global Module TetraMesh

        set m MainTetraMesh

        # Set version info
        lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.13 $} {$Date: 2006/01/06 17:56:55 $}]

    set TetraMesh(defaultOptions) "interpolate 1 autoThreshold 0  lowerThreshold -32768 upperThreshold 32767 showAbove -32768 showBelow 32767 edit None lutID 0 rangeAuto 1 rangeLow -1 rangeHigh 1001"

    set TetraMesh(idNone) -1
    set TetraMesh(activeID)  ""
    set TetraMesh(freeze) ""

    # Append widgets to list that gets refreshed during UpdateMRML
    set TetraMesh(mbActiveList) ""
    set TetraMesh(mActiveList)  ""

}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshUpdateMRML
# 
# The first thing to do is to check if their are any unbuilt TetraMesh.
# This is typically a TetraMesh read in from a MRML file that is only
# now going to be read in.
#
# Then, check if any TetraMesh are supposed to be deleted and delete
# them. This functionality is not used.
#
# If we deleted the active TetraMesh, select a new active TetraMesh
#
# Then, update all the menus that are on the list to be updated if
# the TetraMesh data changes.
#
# Finally, call MainTetraMeshUpdate.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshUpdateMRML {} {
    global TetraMesh Lut Gui

    # Build any new TetraMesh
    #--------------------------------------------------------
    foreach v $TetraMesh(idList) {
        if {[MainTetraMeshCreate $v] > 0} {
            # Mark it as not being created on the fly 
            # since it was added from the Data module or read in from MRML
            set TetraMesh($v,fly) 0

            if {[MainTetraMeshRead $v] < 0} {
                # Let the user know about the error
                tk_messageBox -message "Could not read TetraMesh [TetraMesh($v,node) GetFileName]."
                # Failed, so axe it
                MainMrmlDeleteNodeDuringUpdate TetraMesh $v
            } else {
                            MainTetraMeshVisualize $v
                        }
        }
    }  

    # Delete any old TetraMesh
    #--------------------------------------------------------
    foreach v $TetraMesh(idListDelete) {
        MainTetraMeshDelete $v
    }

    # Did we delete the active TetraMesh?
    if {[lsearch $TetraMesh(idList) $TetraMesh(activeID)] == -1} {
        MainTetraMeshSetActive [lindex $TetraMesh(idList) 0]
    }

    # Set the lut to use for label maps in each MrmlTetraMesh
    #--------------------------------------------------------
    foreach v $TetraMesh(idList) {
        TetraMesh($v,data) SetLabelIndirectLUT Lut($Lut(idLabel),indirectLUT)
    }

    # Form the menus
    #--------------------------------------------------------
    # Active TetraMesh menu
    foreach m $TetraMesh(mActiveList) {
        $m delete 0 end
        foreach v $TetraMesh(idList) {
            $m add command -label [TetraMesh($v,node) GetName] \
                -command "MainTetraMeshSetActive $v"
        }
    }

    # Registration
    foreach v $TetraMesh(idList) {
        if {$v != $TetraMesh(idList)} {
            MainTetraMeshUpdate $v
        }
    }

    MainTetraMeshSetActive $TetraMesh(activeID)
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshCopyData
# 
# .ARGS
# int dst   The destination TetraMesh id.
# int src   The source TetraMesh id.
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshCopyData {dst src } {
    global TetraMesh Lut

        puts "TETRAMESH COPY DOES NOT WORK!!!!"
#    vtkImageCopy copy
#    copy SetInput [TetraMesh($src,data) GetOutput]
#    copy Update
#    copy SetInput ""
#    TetraMesh($dst,data) SetImageData [copy GetOutput]
#    copy SetOutput ""
#    copy Delete
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshCreate
#
# Creates vtkMrmlDataTetraMesh as TetraMesh($v,data) 
# if it does not already exist.
#
#
# Returns:
#  1 - success
#  0 - already built this TetraMesh data
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshCreate {v} {
    global View TetraMesh Gui Dag Lut

    # If we've already built this TetraMesh, then do nothing
    if {[info command TetraMesh($v,data)] != ""} {
        return 0
    }

    # If no LUT name, use first LUT in the list
#        if {[TetraMesh($v,node) GetLUTName] == ""} {
#                TetraMesh($v,node) SetLUTName [lindex $Lut(idList) 0]
#        }

    # Create vtkMrmlDataTetraMesh
    vtkMrmlDataTetraMesh TetraMesh($v,data)
    TetraMesh($v,data) SetMrmlNode          TetraMesh($v,node)
#        TetraMesh($v,data) SetLabelIndirectLUT  Lut($Lut(idLabel),indirectLUT)
#        TetraMesh($v,data) SetLookupTable       Lut([TetraMesh($v,node) GetLUTName],lut)
    TetraMesh($v,data) SetStartMethod       MainStartProgress
    TetraMesh($v,data) SetProgressMethod   "MainShowProgress TetraMesh($v,data)"
    TetraMesh($v,data) SetEndMethod         MainEndProgress

    # Mark it as unsaved and created on the fly.
        # If it isn't being created on the fly, then mark it that way
        # in the procedure that calls this one.
    # MainTetraMeshUpdateMRML procedure.
    set TetraMesh($v,dirty) 1
    set TetraMesh($v,fly) 1

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshRead
#
#
# Returns:
#  1 - success
# -1 - failed to read files
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshRead {v} {
    global TetraMesh Gui

    # Check that all files exist
    if {[CheckFileExists [TetraMesh($v,node) GetFileName]] == 0} {
        return -1
    }
    
    if {[TetraMesh($v,node) GetName] == ""} {
     TetraMesh($v,node) SetName [ file root [file tail \
             [TetraMesh($v,node) GetFileName]]]
    }
    
    set Gui(progressText) "Reading [TetraMesh($v,node) GetName]"

    puts "Reading TetraMesh: [TetraMesh($v,node) GetName]..."
    TetraMesh($v,data) Read
    TetraMesh($v,data) Update
    puts "...finished reading [TetraMesh($v,node) GetName]"

    # Mark this TetraMesh as saved
    set TetraMesh($v,dirty) 0

    return 1
}
#-------------------------------------------------------------------------------
# .PROC MainTetraMeshWrite
# Writes out a TetraMesh created in the Slicer and an accompanying mrml file
# (the "Working.xml" file).
# 
# .ARGS
# int v ID number of the TetraMesh to write
# str prefix file prefix where the TetraMesh will be written
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshWrite {v prefix} {
    global TetraMesh Gui Mrml tcl_platform

    if {$v == ""} {
        return
    }
    if {$prefix == ""} {
        tk_messageBox -message "Please provide a file name."
        return
    }

    # So don't write it if it's not dirty.
    if {$TetraMesh($v,dirty) == 0} {
        set answer [tk_messageBox -type yesno -message \
                "This TetraMesh should not be saved\nbecause it has not been changed\n\
 since the last time it was saved.\nDo you really want to save it?"]
        if {$answer == "no"} {
        return
        }
    }
    
        set fileFull $prefix

    # Check that it's a prefix, not a directory
    if {[file isdirectory $fileFull] == 1} {
        tk_messageBox -icon error -title $Gui(title) \
            -message "Please enter a file name, not a directory,\n\
            for the $data TetraMesh."
        return 0
    }

    # Check that the directory exists
    set dir [file dirname $fileFull]
    if {[file isdirectory $dir] == 0} {
        if {$dir != ""} {
            file mkdir $dir
        }
        if {[file isdirectory $dir] == 0} {
            tk_messageBox -icon info -type ok -title $Gui(title) \
            -message "Failed to make '$dir', so using current directory."
            set dir ""
        }
    }

    # the MRML file will go in the directory where the TetraMesh was saved.
    # So the relative file prefix is just the name of the file.
    set name [file root [file tail $fileFull]]
    TetraMesh($v,node) SetFileName $name

    # Write TetraMesh data
    set Gui(progressText) "Writing [TetraMesh($v,node) GetName]"
    puts "Writing '$fileFull' ..."
    TetraMesh($v,data) Write
    puts " ...done."

    # put MRML file in dir where TetraMesh was saved, name it after the TetraMesh
    set filename [file join [file dirname $fileFull] $name.xml]

    # Write MRML file
    vtkMrmlTree tree
    tree AddItem TetraMesh($v,node)
    tree Write $filename
    if {[tree GetErrorCode] != 0} {
        puts "ERROR: MainTetraMeshWrite: unable to write MRML file $filename"
        tree RemoveAllItems
        tree Delete
        return
    }
    tree RemoveAllItems
    tree Delete
    puts "Saved MRML file: $filename"

    # Reset the pathnames to be relative to Mrml(dir)
    TetraMesh($v,node) SetFilePrefix $filePrefix
    TetraMesh($v,node) SetFullPrefix $fileFull

    # Wrote it, so not dirty (changed since read/wrote)
    set TetraMesh($v,dirty) 0
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshDelete
#
# DAVE fix
# Returns:
#  1 - success
#  0 - already deleted this TetraMesh
# .ARG
#   int m the id number of the TetraMesh to be deleted.
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshDelete {v} {
    global TetraMesh

    # If we've already deleted this TetraMesh, then return 0
    if {[info command TetraMesh($v,data)] == ""} {
        return 0
    }

    # Delete VTK objects (and remove commands from TCL namespace)
    TetraMesh($v,data)  Delete

    # Delete all TCL variables of the form: TetraMesh($v,<whatever>)
    foreach name [array names TetraMesh] {
        if {[string first "$v," $name] == 0} {
            unset TetraMesh($name)
        }
    }

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshBuildGUI {} {
    global fSlicesGUI Gui Model Slice TetraMesh Lut

    #-------------------------------------------
    # TetraMesh Popup Window
    #-------------------------------------------
    set w .wTetraMesh
    set Gui(wTetraMesh) $w
    toplevel $w -bg $Gui(inactiveWorkspace) -class Dialog
    wm title $w "TetraMesh"
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW "wm withdraw $w"
    if {$Gui(pc) == "0"} {
        wm transient $w .
    }
    wm withdraw $w
    set f $w

    # Close button
    eval {button $f.bClose -text "Close" -command "wm withdraw $w"} $Gui(WBA)

    # Frames
    frame $f.fActive -bg $Gui(inactiveWorkspace)
    frame $f.fWinLvl -bg $Gui(activeWorkspace) -bd 2 -relief raised
    frame $f.fThresh -bg $Gui(activeWorkspace) -bd 2 -relief raised
    pack $f.fActive -side top -pady $Gui(pad) -padx $Gui(pad)
    pack $f.fWinLvl $f.fThresh -side top -pady $Gui(pad) -padx $Gui(pad) -fill x
    pack $f.bClose -side top -pady $Gui(pad)

    #-------------------------------------------
    # Popup->Active frame
    #-------------------------------------------
    set f $w.fActive

    eval {label $f.lActive -text "Active TetraMesh: "} $Gui(WLA)\
        {-bg $Gui(inactiveWorkspace)}
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.lActive $f.mbActive -side left -padx $Gui(pad) -pady 0 

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend TetraMesh(mbActiveList) $f.mbActive
    lappend TetraMesh(mActiveList)  $f.mbActive.m

    #-------------------------------------------
    # Popup->WinLvl frame
    #-------------------------------------------
    set f $w.fWinLvl

    #-------------------------------------------
    # Auto W/L
    #-------------------------------------------
    eval {label $f.lAuto -text "Window/Level:"} $Gui(WLA)
    frame $f.fAuto -bg $Gui(activeWorkspace)
    grid $f.lAuto $f.fAuto -pady $Gui(pad)  -padx $Gui(pad) -sticky e
    grid $f.fAuto -columnspan 2 -sticky w

    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable TetraMesh(autoWindowLevel) \
            -command "MainTetraMeshSetParam AutoWindowLevel; MainTetraMeshRender" \
            } $Gui(WCA)
        pack $f.fAuto.rAuto$value -side left -fill x
    }

    #-------------------------------------------
    # W/L Sliders
    #-------------------------------------------
    foreach slider "Window Level" {
        eval {label $f.l${slider} -text "${slider}:"} $Gui(WLA)
        eval {entry $f.e${slider} -width 7 \
            -textvariable TetraMesh([Uncap ${slider}])} $Gui(WEA)
        bind $f.e${slider} <Return>   \
            "MainTetraMeshSetParam ${slider}; MainTetraMeshRender"
        bind $f.e${slider} <FocusOut> \
            "MainTetraMeshSetParam ${slider}; MainTetraMeshRender"
        eval {scale $f.s${slider} -from 1 -to 1024 \
            -variable TetraMesh([Uncap ${slider}]) -length 200 -resolution 1 \
            -command "MainTetraMeshSetParam ${slider}; MainTetraMeshRenderActive"\
             } $Gui(WSA)
        bind $f.s${slider} <Leave> "MainTetraMeshRender"
        grid $f.l${slider} $f.e${slider} $f.s${slider} \
            -pady $Gui(pad) -padx $Gui(pad)
        grid $f.l$slider -sticky e
        grid $f.s$slider -sticky w
        set TetraMesh(s$slider) $f.s$slider
    }
    # Append widgets to list that's refreshed in MainTetraMeshUpdateSliderRange
    lappend TetraMesh(sWindowList) $f.sWindow
    lappend TetraMesh(sLevelList) $f.sLevel

    #-------------------------------------------
    # Popup->Thresh frame
    #-------------------------------------------
    set f $w.fThresh

    #-------------------------------------------
    # Auto Threshold
    #-------------------------------------------
    eval {label $f.lAuto -text "Threshold:"} $Gui(WLA)
    frame $f.fAuto -bg $Gui(activeWorkspace)
    grid $f.lAuto $f.fAuto -pady $Gui(pad) -padx $Gui(pad) -sticky e
    grid $f.fAuto -columnspan 2 -sticky w

    foreach value "1 0" text "Auto Manual" width "5 7" {
        eval {radiobutton $f.fAuto.rAuto$value -width $width -indicatoron 0\
            -text "$text" -value "$value" -variable TetraMesh(autoThreshold) \
            -command "MainTetraMeshSetParam AutoThreshold; MainTetraMeshRender"} $Gui(WCA)
    }
    eval {checkbutton $f.cApply \
        -text "Apply" -variable TetraMesh(applyThreshold) \
        -command "MainTetraMeshSetParam ApplyThreshold; MainTetraMeshRender" -width 6 \
        -indicatoron 0} $Gui(WCA)
    
    grid $f.fAuto.rAuto1 $f.fAuto.rAuto0 $f.cApply
    grid $f.cApply -padx $Gui(pad)

    #-------------------------------------------
    # Threshold Sliders
    #-------------------------------------------
    foreach slider "Lower Upper" {
        eval {label $f.l${slider} -text "${slider}:"} $Gui(WLA)
        eval {entry $f.e${slider} -width 7 \
            -textvariable TetraMesh([Uncap ${slider}]Threshold)} $Gui(WEA)
            bind $f.e${slider} <Return>   \
                "MainTetraMeshSetParam ${slider}Threshold; MainTetraMeshRender"
            bind $f.e${slider} <FocusOut> \
                "MainTetraMeshSetParam ${slider}Threshold; MainTetraMeshRender"
        eval {scale $f.s${slider} -from 1 -to 1024 \
            -variable TetraMesh([Uncap ${slider}]Threshold) -length 200 -resolution 1 \
            -command "MainTetraMeshSetParam ${slider}Threshold; MainTetraMeshRender"\
             } $Gui(WSA)
        grid $f.l${slider} $f.e${slider} $f.s${slider} \
             -padx $Gui(pad) -pady $Gui(pad)
        grid $f.l$slider -sticky e
        grid $f.s$slider -sticky w
        set TetraMesh(s$slider) $f.s$slider
    }
    # Append widgets to list that's refreshed in MainTetraMeshUpdateSliderRange
    lappend TetraMesh(sLevelList) $f.sLower
    lappend TetraMesh(sLevelList) $f.sUpper

}



#-------------------------------------------------------------------------------
# .PROC MainTetraMeshUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshUpdate {v} {
    global TetraMesh Slice 

    # Update pipeline
    TetraMesh($v,data) Update

    # Update GUI
    if {$v == $TetraMesh(activeID)} {
        # Refresh TetraMesh GUI with active TetraMesh's parameters
        MainTetraMeshSetActive $v
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshRender
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshRender {{scale ""}} {
    global TetraMesh Slice 

    # Update slice that has this TetraMesh as input
    set v $TetraMesh(activeID)

    set hit 0
    foreach s $Slice(idList) {
         if {$v == $Slice($s,backVolID) || $v == $Slice($s,foreVolID)} {
            set hit 1
            TetraMesh($v,data) Update
            RenderSlice $s
        }
    }
    if {$hit == 1} {
        Render3D
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshRenderActive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshRenderActive {{scale ""}} {
    global TetraMesh Slice 

    # Update slice that has this TetraMesh as input
    set v $TetraMesh(activeID)

    set s $Slice(activeID)
     if {$v == $Slice($s,backVolID) || $v == $Slice($s,foreVolID)} {
        TetraMesh($v,data) Update
        RenderSlice $s
    } else {
        MainTetraMeshRender
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshSetActive
# 
# .ARGS
# int v The id of the TetraMesh to set active 
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshSetActive {v} {
    global TetraMesh Lut Slice

    if {$TetraMesh(freeze) == 1} {return}
    
    set TetraMesh(activeID) $v
    if {$v == ""} {
        foreach mb $TetraMesh(mbActiveList) {
            $mb config -text "None"
        }
        MainTetraMeshSetGUIDefaults
    } elseif {$v == "NEW"} {
        
        # Change button text
        foreach mb $TetraMesh(mbActiveList) {
            $mb config -text "NEW"
        }

        MainTetraMeshSetGUIDefaults
    } else {
        # Change button text
        foreach mb $TetraMesh(mbActiveList) {
            $mb config -text [TetraMesh($v,node) GetName]
        }
        MainTetraMeshVtkDataToTclData TetraMesh($v,node)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshVtkDataToTclData
# 
# Grab all the VTKMrmlNode Data and put it in TetraMesh(...)
#
# .ARGS
#  mrmlnode VtkMrmlTetraMeshNode
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshVtkDataToTclData {mrmlnode} {
    global TetraMesh

    foreach item     "Name FileName Description Opacity \
            Clipping  DisplaySurfaces SurfacesUseCellData \
            SurfacesSmoothNormals DisplayEdges    \
            DisplayNodes    NodeScaling NodeSkip      \
            DisplayScalars  ScalarScaling  ScalarSkip \
            DisplayVectors  VectorScaling  VectorSkip" {
        set TetraMesh($item) [$mrmlnode Get$item]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshTclDataToVtkData
# 
# Grab all the VTKMrmlNode Data and put it in TetraMesh(...)
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshTclDataToVtkData {mrmlnode} {
    global TetraMesh

    foreach item     "Name FileName Description Opacity \
            Clipping  DisplaySurfaces SurfacesUseCellData \
            SurfacesSmoothNormals DisplayEdges    \
            Clipping        DisplaySurfaces DisplayEdges  \
            DisplayNodes    NodeScaling     NodeSkip \
            DisplayScalars  ScalarScaling   ScalarSkip \
            DisplayVectors  VectorScaling   VectorSkip" {
        $mrmlnode Set$item $TetraMesh($item)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshProcessMrml
# 
# The Mrml file has been parsed. These are the keyword pairs found for
# a TetraMesh. Take them and create a new TetraMeshMrmlNode
#
# Note that this function should assume a user edited the file so that
# the keywords may not have the correct case. It is best to deal with 
# everything in all lower case. Also, don't forget that a TetraMeshMrmlNode
# is a TetraMeshNode, so it must parse the mrml node functionality.
#
# .ARGS
# array attr is a list of keyword pairs.
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshProcessMrml {attr} {
    global Mrml 
    set n [MainMrmlAddNode TetraMesh]
    foreach a $attr {
        set key [lindex $a 0]
        set lowkey [string tolower $key]
        set val [lreplace $a 0 0]
        switch $lowkey {
            "id"           {$n SetID           $val}
            "desc"             {$n SetDescription  $val}
            "name"             {$n SetName         $val}
            "filename"         {$n SetFileName     $val}
            "opacity"          {$n SetOpacity      $val}
            "clipping" {
                if {$val == "yes" || $val == "true"} {
                    $n SetClipping 1
                } else {
                    $n SetClipping 0
                }
            }
            "nodescaling"      {$n SetNodeScaling   $val}
            "nodeskip"         {$n SetNodeSkip      $val}
            "scalarscaling"    {$n SetScalarScaling $val}
            "scalarskip"       {$n SetScalarSkip    $val}
            "vectorscaling"    {$n SetVectorScaling $val}
            "vectorskip"       {$n SetVectorSkip    $val}
        }
        foreach item "Clipping SurfacesUseCellData SurfacesSmoothNormals" {
            if {[string tolower $item] == $lowkey} {
                if {$val == "yes" || $val == "true"} {
                    $n Set$item 1
                } else {
                    $n Set$item 0
                }
            }
        }

        foreach item "Surfaces Nodes Edges Scalars Vectors" {
            if {[string tolower "Display$item"] == $lowkey} {
                if {$val == "yes" || $val == "true"} {
                    $n SetDisplay$item 1
                } else {
                    $n SetDisplay$item 0
                }
            }
        }
        
    }
    # Compute full path name relative to the MRML file
    $n SetFileName [file join $Mrml(dir) [$n GetFileName]]
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshSetParam
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshSetParam {Param {value ""}} {
    global TetraMesh Slice Lut

    # Initialize param, v, value
    set param [Uncap $Param]
    set v $TetraMesh(activeID)
    if {$value == ""} {
        set value $TetraMesh($param)
    } else {
        set TetraMesh($param) $value
    }

    #
    # Window/Level/Threshold
    #
    if {[lsearch "AutoWindowLevel Level Window UpperThreshold LowerThreshold \
        AutoThreshold ApplyThreshold" $Param] != -1} {

        # If no change, return
        if {$value == [TetraMesh($v,node) Get$Param]} {return}

        # Update value
        TetraMesh($v,node) Set$Param $value

        # If changing window/level, then turn off AutoWindowLevel
        if {[lsearch "Level Window" $Param] != -1} {
            set TetraMesh(autoWindowLevel) 0
            TetraMesh($v,node) SetAutoWindowLevel $TetraMesh(autoWindowLevel)
        }

        # If AutoWindowLevel, get the resulting window/level
        if {$Param == "AutoWindowLevel" && $value == 1} {
            TetraMesh($v,data) Update
            set TetraMesh(window) [TetraMesh($v,node) GetWindow]
            set TetraMesh(level)  [TetraMesh($v,node) GetLevel]
        }

        # If changing threshold, then turn off AutoThreshold
        if {[lsearch "UpperThreshold LowerThreshold" $Param] != -1} {
            set TetraMesh(autoThreshold) 0
            TetraMesh($v,node) SetAutoThreshold $TetraMesh(autoThreshold)
        }

        # If changing threshold, then turn on ApplyThreshold
        if {[lsearch "UpperThreshold LowerThreshold AutoThreshold" $Param] != -1} {
            set TetraMesh(applyThreshold) 1
            TetraMesh($v,node) SetApplyThreshold $TetraMesh(applyThreshold)
        }

        # If AutoThreshold, get the resulting upper/lower threshold
        if {$Param == "AutoThreshold"} {
            TetraMesh($v,data) Update
            set TetraMesh(lowerThreshold) [TetraMesh($v,node) GetLowerThreshold]
            set TetraMesh(upperThreshold) [TetraMesh($v,node) GetUpperThreshold]
        }

        if {$Param == "ApplyoThreshold"} {
            TetraMesh($v,data) Update
        }

    #
    # Range
    #
    } elseif {[lsearch "RangeAuto RangeLow RangeHigh" $Param] != -1} {

        # If no change, return
        if {$value == [TetraMesh($v,data) Get$Param]} {return}

        # Update value
        TetraMesh($v,data) Set$Param $value

        # If changing range, then turn off RangeAuto
        if {[lsearch "RangeLow RangeHigh" $Param] != -1} {
            set TetraMesh(rangeAuto) 0
            TetraMesh($v,data) SetRangeAuto $TetraMesh(rangeAuto)
        }

        # Clip window/level/threshold with the range
        TetraMesh($v,data) Update
        foreach item "Window Level UpperThreshold LowerThreshold" {
            set TetraMesh([Uncap $item]) [TetraMesh($v,node) Get$item]
        }

        # If RangeAuto, get the resulting range
        if {$Param == "RangeAuto" && $value == 1} {
            set TetraMesh(rangeLow)  [TetraMesh($v,data) GetRangeLow]
            set TetraMesh(rangeHigh) [TetraMesh($v,data) GetRangeHigh]
            MainTetraMeshUpdateSliderRange        

            # Refresh window/level/threshold
            set TetraMesh(window) [TetraMesh($v,node) GetWindow]
            set TetraMesh(level)  [TetraMesh($v,node) GetLevel]
            if {$TetraMesh(autoThreshold) == "-1"} {
                TetraMesh($v,node) SetLowerThreshold [TetraMesh($v,data) GetRangeLow]
                TetraMesh($v,node) SetUpperThreshold [TetraMesh($v,data) GetRangeHigh]
            }
            set TetraMesh(lowerThreshold) [TetraMesh($v,node) GetLowerThreshold]
            set TetraMesh(upperThreshold) [TetraMesh($v,node) GetUpperThreshold]
        } else {
            MainTetraMeshUpdateSliderRange        
        }
    #
    # LUT
    #
    } elseif {$Param == "LutID"} {

        # Label 
        if {$value == $Lut(idLabel)} {
            TetraMesh($v,data) UseLabelIndirectLUTOn
        } else {
            TetraMesh($v,data) UseLabelIndirectLUTOff
            TetraMesh($v,data) SetLookupTable Lut($value,lut)
        }
        TetraMesh($v,data) Update

        TetraMesh($v,node) SetLUTName $value
    
        if {[IsModule TetraMesh] == 1} {
            $TetraMesh(mbLUT) config -text $Lut($value,name)
        }

        # Color of line in histogram
        eval TetraMesh($v,data) SetHistogramColor $Lut($value,annoColor)

        # Set LUT in mappers
        Slicer ReformatModified
        Slicer Update

    # 
    # Interpolate
    #
    } elseif {$Param == "Interpolate"} {
        TetraMesh($v,node) SetInterpolate $value

        # Notify the Slicer that it needs to refresh the reformat portion
        # of the imaging pipeline
        Slicer ReformatModified
        Slicer Update

        TetraMesh($v,data) Update

    # 
    # Booboo
    #
     } else {
        puts "MainTetraMeshSetParam: Unknown param=$param"
        return
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshUpdateSliderRange
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshUpdateSliderRange {} {
    global TetraMesh

    # Change GUI
    # width = hi - lo + 1 = (hi+1) - (lo-1) - 1
    set width [expr $TetraMesh(rangeHigh) - $TetraMesh(rangeLow) - 1]
    if {$width < 1} {set width 1}

    foreach s $TetraMesh(sLevelList) {
        $s config -from $TetraMesh(rangeLow) -to $TetraMesh(rangeHigh)
    }
    foreach s $TetraMesh(sWindowList) {
        $s config -from 1 -to $width
    }
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshSetGUIDefaults 
#
# Set defaults for the TetraMesh-> Props GUI.# 
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshSetGUIDefaults {} {
    global TetraMesh

    # Get defaults from VTK 
    vtkMrmlTetraMeshNode default

    MainTetraMeshVtkDataToTclData default
    default Delete
}

#-------------------------------------------------------------------------------
# .PROC MainTetraMeshVisualize
#
# For a particular vtkTetraMesh node, 
# Visualize the results
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainTetraMeshVisualize { v } {
    global TetraMesh Volume

    MainTetraMeshVtkDataToTclData TetraMesh($v,node)
    set TetraMesh(modelbasename) \
            [ file root [file tail $TetraMesh(FileName)]]

    ## Is there a volume with which to align already
    set vmax $Volume(idNone)
    foreach vv $Volume(idList) {
        if {$vv > $vmax} { 
            set vmax  $vv 
        }
    }
    if {$vmax > $Volume(idNone) } {
      set Volume(activeID) $vmax
    }

#    puts "Volume $vmax : $Volume(idList)"

    set TetraMesh(ProcessMesh) [TetraMesh($v,data) GetOutput]
    foreach item "Surfaces Nodes Edges Scalars Vectors" {
        if {$TetraMesh(Display$item) == "1"} {
             set newmodels  [ TetraMeshProcess$item ]
            foreach a $newmodels {
#                puts $a
                Mrml(dataTree) RemoveItem Model($a,node)
                Mrml(dataTree) InsertAfterItem TetraMesh($v,node) Model($a,node)
            }
        }
    }
#    Opacity 
#    Clipping
}
