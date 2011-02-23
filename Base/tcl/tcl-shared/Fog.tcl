#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Fog.tcl,v $
#   Date:      $Date: 2006/05/31 21:54:38 $
#   Version:   $Revision: 1.11 $
# 
#===============================================================================
# FILE:        Fog.tcl
# PROCEDURES:  
#   FogCheckGlobal
#   FogApply the
#   FogBuildGui frame
#==========================================================================auto=

#
#
#  

#-------------------------------------------------------------------------------
# .PROC FogCheckGlobal
# 
#
#  Global variable Fog for the fog Parameters
#
#  Fog(Enabled) On  0ff
#  Fog(mode)    linear exp exp2
#  Fog(start)   start distance for linear fog in [0,1]
#  Fog(end)     end   distance for linear fog in [0,1]
#
#  the real distances are then computed
#
# .ARGS
#    
# .END
#-------------------------------------------------------------------------------
proc FogCheckGlobal {} {
#    --------------

  global Fog

  #
  # check the existence of the global variable or create them
  # with default values
  #
  if {![info exist Fog(Enabled)]}   {    set Fog(Enabled) "On"   }
  if {![info exist Fog(mode)   ]}   {    set Fog(mode)    linear }
  if {![info exist Fog(start)  ]}   {    set Fog(start)   0.5    }
  if {![info exist Fog(end)    ]}   {    set Fog(end)     1      }
  if {![info exist Fog(noSupportWarningGiven)]} { set Fog(noSupportWarningGiven) 0 }

  if {$Fog(start) < 0} { set Fog(start) 0 }
  if {$Fog(start) > 1} { set Fog(start) 1 }

  if {$Fog(end) < $Fog(start)} { set Fog(end) [expr $Fog(start)+0.1]}
  if {$Fog(end) > 2}           { set Fog(end) 2}

} 
# end FogCheckGlobal


#-------------------------------------------------------------------------------
# .PROC FogApply
# 
#
#
# .ARGS
#    ren the render
# .END
#-------------------------------------------------------------------------------
proc FogApply {renwin} {
#    --------

  global  boxActor View Fog

  if { [info command vtkFog] == "" } {
      # no fog support compiled in, skip it
      if {$Fog(Enabled) == "On" && $Fog(noSupportWarningGiven) != 1} {
          set Fog(noSupportWarningGiven) 1
          DevErrorWindow "No fog support in this version."
          
      }
      return;
  }
  #  set bounds [boxActor GetBounds]

  #
  # check the existence of the global variable or create them
  # with default values
  #
  FogCheckGlobal

  #
  #  Check the values of the parameters
  #

  if {$Fog(mode) != "linear"} {
    puts "Only linear fog supported at the moment \n"
    set Fog(mode) linear
  }


    if {$Fog(mode) == "linear"}  {

        catch "vtkFog Fog(vtk,f)"
        
        Fog(vtk,f) SetFogEnabled [expr  {$Fog(Enabled) == "On"}]
        
        set renderers [$renwin GetRenderers]
        set numRenderers [$renderers GetNumberOfItems]
        
        $renderers InitTraversal
        for {set i 0} {$i < $numRenderers} {incr i} {
            set ren  [$renderers GetNextItem]

            set fov   [expr $View(fov) ]
            set fov2  [expr $fov / 2   ]
            set dist  [[$ren GetActiveCamera] GetDistance]

            Fog(vtk,f) SetFogStart [expr $dist - $fov2 + $Fog(start) * $fov ]
            Fog(vtk,f) SetFogEnd   [expr $dist - $fov2 + $Fog(end)   * $fov ]

            Fog(vtk,f) Render  $ren
        }
      
        catch "Fog(vtk,f) Delete"
    }
} 
# end FogApply


#-------------------------------------------------------------------------------
# .PROC FogBuildGui
# 
#  Create interface for the Fog parameters
#
# .ARGS
#    f frame for building the fog interface
# .END
#-------------------------------------------------------------------------------
proc FogBuildGui {fFog} {
#    -----------

    global Gui Fog

    FogCheckGlobal ;# set defaults
    set Fog(Enabled) Off
  
    #-------------------------------------------
    # Fog frame
    #-------------------------------------------
    # Setup the fog parameters
#    set fFog $Module(View,fFog)
    set f $fFog

    frame $f.fEnabled  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fMode     -bg $Gui(activeWorkspace)
    frame $f.fLimits   -bg $Gui(activeWorkspace) -relief groove -bd 3

    eval {label $f.lLimits  -text "Limits, bounding box is \[0\,1\]:"} $Gui(WTA)

    pack $f.fEnabled $f.fMode $f.lLimits $f.fLimits \
        -side top -pady $Gui(pad) -padx $Gui(pad) -fill x

    #-------------------------------------------
    # Fog->Enabled
    #-------------------------------------------
    set f $fFog.fEnabled
    
    eval {label $f.lEnabled -text "Enable Fog: "} $Gui(WLA)
    pack $f.lEnabled -side left -padx $Gui(pad) -pady 0

    foreach value "On Off" width "4 4" {
        eval { radiobutton $f.rEnabled$value -width $width \
               -text "$value" -value "$value" -variable Fog(Enabled) \
               -indicatoron 0 -command "Render3D" \
              } $Gui(WRA)
    
        pack $f.rEnabled$value -side left -padx 2 -pady 2 -fill x
    }

    #-------------------------------------------
    # Fog->Mode
    #-------------------------------------------
    set f $fFog.fMode

    foreach value "linear exp exp2" {
        eval {radiobutton $f.r$value \
              -text "$value" -value "$value" \
          -variable Fog(mode) \
              -indicatoron 0 \
          -command "Render3D" \
          }  $Gui(WRA)
        pack $f.r$value -side left -padx 2 -pady 2 -expand 1 -fill x
    }


    #-------------------------------------------
    # Fog->Limits
    #-------------------------------------------
    set f $fFog.fLimits


    #        pack $f.lLimits  -side left -padx 0 -pady 0

    # Start Slider
    #        
    eval {label $f.lStart  -text "Start" -width 5} $Gui(WTA)

    eval {entry $f.eStart -textvariable Fog(start) -width 4} $Gui(WEA)

    eval {scale $f.sStart -from 0 -to 2        \
          -variable Fog(start) \
          -orient vertical     \
          -command "Render3D"  \
          -resolution .01      \
          } $Gui(WSA)

    bind $f.sStart <Motion> "Render3D"

    grid $f.lStart $f.eStart $f.sStart

    $f.sStart set 0.5

    # End Slider
    #        
    eval {label $f.lEnd  -text "End" -width 5} $Gui(WTA)

    eval {entry $f.eEnd -textvariable Fog(end) -width 4} $Gui(WEA)

    eval {scale $f.sEnd -from 0 -to 2        \
      -variable Fog(end) \
          -orient vertical     \
      -command "Render3D"  \
          -resolution .01      \
          } $Gui(WSA)

    bind $f.sEnd <Motion> "Render3D"

    grid $f.lEnd $f.eEnd $f.sEnd 

    $f.sEnd set 1


} 
# end FogBuildGui
