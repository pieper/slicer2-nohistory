#=auto==========================================================================
#   Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Csys.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:04 $
#   Version:   $Revision: 1.14 $
# 
#===============================================================================
# FILE:        Csys.tcl
# PROCEDURES:  
#   CsysInit
#   CsysActorSelected
#   CsysParams
#   CsysResize
#   CsysCreate
#==========================================================================auto=
############################################################################
#
#      YOU SHOULD NOT NEED TO MODIFY THIS FILE IF YOU JUST WANT TO USE
#      A CSYS IN YOUR MODULE. FOR THAT, PLEASE READ tcl-modules/CustomCsys.tcl
#      IT WILL SHOW YOU HOW TO DO IT.
#
#      THIS FILE DEFINES GENERAL OPERATIONS TO CREATE/INTERACT with a CSYS
#
#      By the way, Csys means Coordinate-SYStem and it was originally created
#      by Peter Everett and generalized by Delphine Nain.
#      
#
############################################################################

#-------------------------------------------------------------------------------
# .PROC CsysInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CsysInit {} {
    
    global Csys

    vtkCellPicker Csys(picker)
    Csys(picker) SetTolerance 0.001
    
    set Csys(xactor,selectedColor) "1.0 0 0"
    set Csys(yactor,selectedColor) "0 1.0 0"
    set Csys(zactor,selectedColor) "0 0 1.0"
    
    set Csys(xactor,color) "1.0 0.4 0.4"
    set Csys(yactor,color) "0.4 1.0 0.4"
    set Csys(zactor,color) "0.4 0.4 1.0"
    
    # store a list of modules that have Csys actors
    set Csys(modules) ""

}


########################################################################
#
#
#          BINDINGS
#
#
#########################################################################


#-------------------------------------------------------------------------------
# .PROC CsysActorSelected
#  This is called when any mouse button is pressed (in tcl-main/TkInteractor.tcl)
#  * If the selected actor is a csys of the active module, then call XformAxisStart with the appropriate arguments and return 1 to override the regular tk interaction events
#  * Otherwise return 0 so that the regular tk interaction events are used (so the user can navigate in the 3D scene )
#    
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CsysActorSelected {widget x y} {

    global Csys Ev 

    if { ![info exists Csys(active)] } {
        # in case we get a motion callback before the module is initialized...
        return
    }

    if { $Csys(active) > 0 } {
        if { [SelectPick Csys(picker) $widget $x $y] != 0 } {
        
            # get the path of actors selected by the picker
            set assemblyPath [Csys(picker) GetPath]
            $assemblyPath InitTraversal
            set assemblyNode [$assemblyPath GetLastNode]
            set pickactor [$assemblyNode GetProp]

            # shouldn't happen, but defensive programming can't hurt
            if {$pickactor == ""} {
                # problem here, just go back to the regular interaction mode
               return 0
            }
            
            foreach module $Csys(modules) {
                foreach actor $Csys($module,actors) {
                    
                    if { [$pickactor GetProperty] == [${module}($actor,Xactor) GetProperty] } {
                    
                        eval [${module}($actor,Xactor) GetProperty] SetColor \
                            $Csys(xactor,selectedColor)
                        eval [${module}($actor,Yactor) GetProperty] SetColor \
                            $Csys(yactor,color)
                        eval [${module}($actor,Zactor) GetProperty] SetColor \
                            $Csys(zactor,color)
                        Render3D
                        XformAxisStart $module $actor $widget 0 $x $y
                        return 1
                    } elseif { [$pickactor GetProperty] == [${module}($actor,Yactor) GetProperty] } {
                        eval [${module}($actor,Xactor) GetProperty] SetColor \
                            $Csys(xactor,color) 
                        eval [${module}($actor,Yactor) GetProperty] SetColor \
                            $Csys(yactor,selectedColor)
                        eval [${module}($actor,Zactor) GetProperty] SetColor \
                            $Csys(zactor,color)
                        Render3D 
                        XformAxisStart $module $actor $widget 1 $x $y
                        return 1
                    } elseif { [$pickactor GetProperty]  == [${module}($actor,Zactor) GetProperty] } {
                        eval [${module}($actor,Xactor) GetProperty] SetColor \
                            $Csys(xactor,color) 
                        eval [${module}($actor,Yactor) GetProperty] SetColor \
                            $Csys(yactor,color) 
                        eval [${module}($actor,Zactor) GetProperty] SetColor \
                            $Csys(zactor,selectedColor)
                        Render3D
                        XformAxisStart $module $actor $widget 2 $x $y
                        return 1
                    }
                }
            }
        }
        # if we got to this point, no csys got selected
        return 0
    }
    return 0
}

##################################################################
#
#             VTK ACTOR CREATION
#
#
#################################################################

#-------------------------------------------------------------------------------
# .PROC CsysParams
#  set length, width, height parameters 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CsysParams { module actor {axislen -1} {axisrad -1} {conelen -1} } {
    global Csys ${module}
        
    if { $axislen == -1 } { set axislen 150 }
    if { $axisrad == -1 } { set axisrad [expr $axislen*0.015] }
    if { $conelen == -1 } { set conelen [expr $axislen*0.15] }
    set axislen [expr $axislen-$conelen]

    set ${module}($actor,size) $axislen
    
    # set parameters for cylinder geometry and transform
    ${module}($actor,AxisCyl) SetRadius $axisrad
    ${module}($actor,AxisCyl) SetHeight $axislen
    ${module}($actor,AxisCyl) SetCenter 0 [expr -0.5*$axislen] 0
    ${module}($actor,AxisCyl) SetResolution 8
    ${module}($actor,CylXform) Identity
    ${module}($actor,CylXform) RotateZ 90
    
    # set parameters for cone geometry and transform
    ${module}($actor,AxisCone) SetRadius [expr $axisrad * 2.5]
    ${module}($actor,AxisCone) SetHeight $conelen
    ${module}($actor,AxisCone) SetResolution 8
    ${module}($actor,ConeXform) Identity
    ${module}($actor,ConeXform) Translate $axislen 0 0
    # pce_debug_msg [concat "Csys params: axislen=" $axislen " axisrad=" \
        #         $axisrad " conelen=" $conelen]
}

#-------------------------------------------------------------------------------
# .PROC CsysResize
#  Set the size of the csys 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CsysResize { module actor size } {
    global ${module}
    CsysParams ${module} $actor $size
    Render3D
}

# procedure culminates with creation of "Csys" Assembly Actor
# with a Red X-Axis, a Green Y-Axis, and a Blue Z-Axis

#-------------------------------------------------------------------------------
# .PROC CsysCreate
#  create the Csys vtk actor $module($actor,actor)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CsysCreate { module actor axislen axisrad conelen  } {
    global Csys ${module}

    if { $axislen == -1 } { set axislen 150 }

    vtkCylinderSource ${module}($actor,AxisCyl)
    vtkConeSource ${module}($actor,AxisCone)
    vtkTransform ${module}($actor,CylXform)
    vtkTransform ${module}($actor,ConeXform)
    vtkTransformPolyDataFilter ${module}($actor,ConeXformFilter)
    ${module}($actor,ConeXformFilter) SetInput [${module}($actor,AxisCone) GetOutput]
    ${module}($actor,ConeXformFilter) SetTransform ${module}($actor,ConeXform)
    vtkTransformPolyDataFilter ${module}($actor,CylXformFilter)
    ${module}($actor,CylXformFilter) SetInput [${module}($actor,AxisCyl) GetOutput]
     ${module}($actor,CylXformFilter) SetTransform ${module}($actor,CylXform)
    vtkAppendPolyData ${module}($actor,Axis)
    ${module}($actor,Axis) AddInput [${module}($actor,CylXformFilter) GetOutput]
    ${module}($actor,Axis) AddInput [${module}($actor,ConeXformFilter) GetOutput]
    vtkPolyDataMapper ${module}($actor,AxisMapper)
    ${module}($actor,AxisMapper) SetInput [${module}($actor,Axis) GetOutput]
    vtkActor ${module}($actor,Xactor)
    ${module}($actor,Xactor) SetMapper ${module}($actor,AxisMapper)
    eval [${module}($actor,Xactor) GetProperty] SetColor $Csys(xactor,color) 
    ${module}($actor,Xactor) PickableOn
    # translate the arrow a bit
    ${module}($actor,Xactor) SetPosition [expr -$axislen *0.4] 0 0
    
    vtkActor ${module}($actor,Yactor)
    ${module}($actor,Yactor) SetMapper ${module}($actor,AxisMapper)
    eval [${module}($actor,Yactor) GetProperty] SetColor $Csys(yactor,color) 
    ${module}($actor,Yactor) RotateZ 90
    ${module}($actor,Yactor) PickableOn
    # translate the arrow a bit
    ${module}($actor,Yactor) SetPosition 0 [expr -$axislen *0.4] 0

    vtkActor ${module}($actor,Zactor)
    ${module}($actor,Zactor) SetMapper ${module}($actor,AxisMapper)
    eval [${module}($actor,Zactor) GetProperty] SetColor $Csys(zactor,color) 
    ${module}($actor,Zactor) RotateY -90
    ${module}($actor,Zactor) PickableOn
    # translate the arrow a bit
    ${module}($actor,Zactor) SetPosition 0 0 [expr -$axislen *0.4]

    CsysParams $module $actor $axislen $axisrad $conelen
    set ${module}($actor,actor) [vtkAssembly ${module}($actor,actor)]
    ${module}($actor,actor) AddPart ${module}($actor,Xactor)
    ${module}($actor,actor) AddPart ${module}($actor,Yactor)
    ${module}($actor,actor) AddPart ${module}($actor,Zactor)
    ${module}($actor,actor) PickableOff
    vtkMatrix4x4 ${module}($actor,matrix)
    vtkTransform ${module}($actor,xform)
    vtkTransform ${module}($actor,actXform)
    vtkMatrix4x4 ${module}($actor,inverse)
    vtkTransform ${module}($actor,rasToWldTransform)
    ${module}($actor,actor) SetUserMatrix [${module}($actor,rasToWldTransform) GetMatrix]

    #store all the modules that have a csys actor

    lappend Csys(modules) $module
    
    # store all the csys actors by module
    if {[info exists Csys($module,actors)] == 0 } {
        set Csys($module,actors) $actor
    } else {
        lappend Csys($module,actors) $actor
    }
}
