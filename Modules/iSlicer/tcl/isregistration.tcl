#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: isregistration.tcl,v $
#   Date:      $Date: 2006/01/17 20:36:05 $
#   Version:   $Revision: 1.35 $
# 
#===============================================================================
# FILE:        isregistration.tcl
# PROCEDURES:  
#   isregistration_demo
#==========================================================================auto=
# TODO - won't be needed once iSlicer is a package
package require Iwidgets

if { [info command ::isvolume] == "" } {
    global env
    source $env(SLICER_HOME)/Modules/iSlicer/tcl/isvolume.tcl
}

if { [info command ::istask] == "" } {
    global env
    source $env(SLICER_HOME)/Modules/iSlicer/tcl/istask.tcl
}

if { [info command ::isprogress] == "" } {
    global env
    source $env(SLICER_HOME)/Modules/iSlicer/tcl/isprogress.tcl
}


#########################################################
#
if {0} { ;# comment

isregistration - a widget for running image registrations

  source : the moving volume
  target : the stationary volume.

# TODO : 
    -- pre-programmed sequence for multires registration
    -- convergence
}

#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
option add *isregistration.target            "" widgetDefault
option add *isregistration.source            "" widgetDefault
option add *isregistration.transform         "" widgetDefault
option add *isregistration.resolution       128 widgetDefault
option add *isregistration.target_shrink {1 1 1} widgetDefault
option add *isregistration.source_shrink {1 1 1} widgetDefault
option add *isregistration.vtk_itk_reg   "vtkITKVersorMattesMiVersorRegistrationFilter" \
                                                 widgetDefault
option add *isregistration.set_metric_option  "" widgetDefault
option add *isregistration.set_optimizer_option  "" widgetDefault
option add *isregistration.resample        1 widgetDefault
option add *isregistration.normalize        1 widgetDefault
## for debugging
option add *isregistration.verbose         1 widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class isregistration] == "" } {

    itcl::class isregistration {
        inherit iwidgets::Labeledwidget

        constructor {args} {}
        destructor {}

        #
        # itk_options for widget options that may need to be
        # inherited or composed as part of other widgets
        # or become part of the option database
        #

        itk_option define -target target Target {0}
        itk_option define -source source Source {0}
        itk_option define -resample resample Resample 0
        itk_option define -normalize normalize Normalize 1
        itk_option define -transform transform Transform {}
        itk_option define -resolution resolution Resolution 128
        itk_option define -target_shrink target_shrink Target_shrink {1 1 1}
        itk_option define -source_shrink source_shrink Source_shrink {1 1 1}

        itk_option define -verbose verbose Verbose 0
        itk_option define -update_procedure updateprocedure UpdateProcedure ""
        itk_option define -stop_procedure stopprocedure StopProcedure ""
        itk_option define -auto_repeat auto_repeat Auto_repeat 1

        itk_option define -vtk_itk_reg vtk_itk_reg  Vtk_Itk_Reg vtkITKMutualInformationTransform 

        itk_option define -set_metric_option set_metric_option Set_metric_option 1
        itk_option define -set_optimizer_option set_optimizer_option Set_optimizer_option 1
        itk_option define -samples samples Samples 50
        itk_option define -target_standarddev target_stardarddev Target_standarddev 1
        itk_option define -source_standarddev source_stardarddev Source_standarddev 1
    

        variable _name ""
        variable _volume_serial 0
        # is this the first time we are iterating
        variable _firsttime 1
        variable _abort 0

        # the m_time of matrix being altered
        # keep track so we can see if it was changed
        variable _mat_m_time  -1

        ### procedure to call if there are problems.
        variable _updateprocedure ""

        # widgets
        variable _controls ""
        variable _task ""
        variable _targetvol ""
        variable _sourcevol ""
        variable _p1 ""
        variable _p2 ""

        # vtk instances
        variable _reg ""
        variable _matrix ""
        variable _targetchangeinfo ""
        variable _targetcast ""
        variable _targetnorm ""
        variable _sourcechangeinfo ""
        variable _sourcecast ""
        variable _sourcenorm ""

        method step {} {}
        method is_abort {} { return $_abort }
        method StringMatrix { mat4x4 } {}
        method StringToMatrix { mat4x4 str} {}
        method GetSimilarityMatrix { s2 mat s1 } {}
        method getP1 {} {}
        method getP2 {} {}
        method update_slicer_mat {} {}
        method set_init_mat {} {}
        method get_last_metric_value {} {}
        method start {} {$_task on;}
        method stop  {} {$_task off }
        method pre_delete  {} {
            $_sourcevol pre_delete
            $_targetvol pre_delete
        }
        method get_dimensions {v} {}
        method get_spacing {v} {}
        method set_resample_parameters {} {}
        method deformation_volume { {name ""} } {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body isregistration::constructor {args} {
    component hull configure -borderwidth 0

    global Volume

    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name

    #######
    ### make the subwidgets
    ### - isvolumes for target and source volumes
    ### - control area
    ### - note that the volumes are initialized using the -target
    ### -      and -source volumes
    #######

    ### create the two isvolumes, but do not give them any information.
    set _targetvol    [isvolume $itk_interior.target]
    set _sourcevol    [isvolume $itk_interior.source]

    pack $_targetvol -fill both -expand true
    pack $_sourcevol -fill both -expand true
    
    set _controls [iwidgets::scrolledframe $itk_interior.controls]
    pack $_controls -fill both -expand true

    set cs [$_controls childsite]
    set _task $cs.task
    istask $_task -taskcommand "$this step" -labeltext "Registration: " \
      -taskdelay 100
    pack $_task

    set _resmenu $cs.resmenu
    iwidgets::optionmenu $_resmenu -labeltext "Resolution: " -labelpos w \
        -command "$this configure -resolution \[$_resmenu get\]"
    set resolutions { 8 16 32 64 128 256 512 }
    foreach r $resolutions {
        $_resmenu insert end $r
    }
    $_resmenu select [lsearch $resolutions "128"]
    pack $_resmenu 

    # align the control labels
    ::iwidgets::Labeledwidget::alignlabels $_task $_resmenu 

    ######
    ### set up the vtk pipeline
    ### - matrix that tie to slicer's matrix
    ### - image normalizers to prep volumes
    ### - the registration itself
    ######

    set _matrix ::matrix_$_name
    catch "$_matrix Delete"
    vtkMatrix4x4 $_matrix
    $_matrix Identity

    ######
    ##
    ## Cast target image to float and normalize
    ##
    ######
    global Matrix

    set _targetcast ::targetcast_$_name
    set _targetnorm ::targetnorm_$_name
    set _targetchangeinfo ::targetchangeinfo_$_name
    catch "$_targetcast Delete"
    catch "$_targetnorm Delete"
    catch "$_targetchangeinfo Delete"

    vtkImageChangeInformation $_targetchangeinfo
    $_targetchangeinfo CenterImageOn
    $_targetchangeinfo SetInput [$_targetvol imagedata]
    $_targetchangeinfo SetInput [Volume($Volume(idNone),vol) GetOutput]

    vtkImageCast $_targetcast
    $_targetcast SetOutputScalarTypeToFloat
    $_targetcast SetInput [$_targetchangeinfo GetOutput]

    vtkITKNormalizeImageFilter $_targetnorm
    $_targetnorm SetInput [$_targetcast GetOutput]

    ##
    ## Cast source image to float and normalize
    ##

    set _sourcecast ::sourcecast_$_name
    set _sourcenorm ::sourcenorm_$_name
    set _sourcechangeinfo ::sourcechangeinfo_$_name
    catch "$_sourcecast Delete"
    catch "$_sourcenorm Delete"
    catch "$_sourcechangeinfo Delete"

    vtkImageChangeInformation $_sourcechangeinfo
    $_sourcechangeinfo CenterImageOn
    $_sourcechangeinfo SetInput [$_sourcevol imagedata]
    $_sourcechangeinfo SetInput [Volume($Volume(idNone),vol) GetOutput]

    vtkImageCast $_sourcecast
    $_sourcecast SetOutputScalarTypeToFloat
    $_sourcecast SetInput [$_sourcechangeinfo GetOutput]

    vtkITKNormalizeImageFilter $_sourcenorm
    $_sourcenorm SetInput [$_sourcecast GetOutput]

    eval itk_initialize $args
}

itcl::body isregistration::destructor {} {
        catch "_reg Delete"
        catch "_matrix Delete"
        catch "_targetcast Delete"
        catch "_targetnorm Delete"
        catch "_sourcecast Delete"
        catch "_sourcenorm Delete"
}

#-------------------------------------------------------------------------------
# OPTION: -vtk_itk_reg
#
# DESCRIPTION: the registration type: i.e. vtkITKMutualInformationTransform
# - name of a slicer volume
#-------------------------------------------------------------------------------
itcl::configbody isregistration::vtk_itk_reg {

    #######
    ## Create the Registration instance 
    #######

    if {$itk_option(-vtk_itk_reg) == ""} {
        return
    }

    ### The name is something like ::reg__mi_reg Print
    set _reg ::reg_$_name
    catch "$_reg Delete"
    $itk_option(-vtk_itk_reg) $_reg

    $_reg Initialize $_matrix
    puts "vtk_itk_reg INIT MATRIX"
    puts [$_matrix Print]
 
    # need to explicitly call update with vtk 4.4 -- TODO figure out why...

    if {$itk_option(-normalize) != 0} {
        [$_targetnorm GetOutput] Update
        [$_sourcenorm GetOutput] Update

        $_reg SetTargetImage [$_targetnorm GetOutput]
        $_reg SetSourceImage [$_sourcenorm GetOutput]
    } else {
        [$_targetcast GetOutput] Update
        [$_sourcecast GetOutput] Update
        
        $_reg SetTargetImage [$_targetcast GetOutput]
        $_reg SetSourceImage [$_sourcecast GetOutput]
    }
}


#-------------------------------------------------------------------------------
# OPTION: -target
#
# DESCRIPTION: the stationary target volume 
# - name of a slicer volume
#-------------------------------------------------------------------------------
itcl::configbody isregistration::target {

    # TODO - this should be handled by passing the option through using the 
    # itk hide and related stuff

    if {$itk_option(-target) == ""} {
        return
    }
    $_targetvol volmenu_update 
    $_targetvol configure -volume $itk_option(-target)
    $_targetvol configure -orientation RAS

    if {$itk_option(-resample) != 0} {
        set dimension [get_dimensions $itk_option(-target)]
        set spacing [get_spacing $itk_option(-target)]

        $_targetvol set_dimensions [lindex $dimension 0] [lindex $dimension 1] [lindex $dimension 2]
        $_targetvol set_spacing [lindex $spacing 0] [lindex $spacing 1] [lindex $spacing 2]

        catch "xform Delete"
        vtkMatrix4x4 xform
        xform Identity
        $_targetvol configure -transform xform
        [$_targetvol imagedata] SetUpdateExtentToWholeExtent
        [$_targetvol imagedata] Update

        $_targetchangeinfo SetInput [$_targetvol imagedata]

    } else {
        $_targetchangeinfo SetInput [Volume($itk_option(-target),vol) GetOutput]
    }
}

#-------------------------------------------------------------------------------
# OPTION: -source
#
# DESCRIPTION: the source volume that the matrix applies to
# - name of a slicer volume
#-------------------------------------------------------------------------------
itcl::configbody isregistration::source {

    # TODO - this should be handled by passing the option through using the 
    # itk hide and related stuff

    if {$itk_option(-source) == ""} {
        return
    }
    $_sourcevol volmenu_update 
    $_sourcevol configure -volume $itk_option(-source)
    $_sourcevol configure -resolution $itk_option(-resolution)
    $_sourcevol configure -orientation RAS

    if {$itk_option(-resample) != 0} {
        set dimension [get_dimensions $itk_option(-source)]
        set spacing [get_spacing $itk_option(-source)]

        $_sourcevol set_dimensions [lindex $dimension 0] [lindex $dimension 1] [lindex $dimension 2]
        $_sourcevol set_spacing [lindex $spacing 0] [lindex $spacing 1] [lindex $spacing 2]

        catch "xform Delete"
        vtkMatrix4x4 xform
        xform Identity
        $_sourcevol configure -transform xform
        [$_sourcevol imagedata] SetUpdateExtentToWholeExtent
        [$_sourcevol imagedata] Update
        
        $_sourcechangeinfo SetInput [$_sourcevol imagedata]
    } else {
        $_sourcechangeinfo SetInput [Volume($itk_option(-source),vol) GetOutput]
    }
}

#-------------------------------------------------------------------------------
# OPTION: -resolution
#
# DESCRIPTION: set the resolution of the calculation
#  this is not used at all
#-------------------------------------------------------------------------------
itcl::configbody isregistration::resolution {

    if {$itk_option(-source) != ""} {
        $_sourcevol configure -resolution $itk_option(-resolution)

        $_sourcevol configure -orientation coronal ;# TODO extra config due to isvolume bug
        $_sourcevol configure -orientation RAS
    }
    if {$itk_option(-target) != ""} {
        $_targetvol configure -resolution $itk_option(-resolution)

        $_targetvol configure -orientation coronal ;# TODO extra config due to isvolume bug
        $_targetvol configure -orientation RAS
    }
}

#-------------------------------------------------------------------------------
# METHOD: step
#
# DESCRIPTION: run an interation of the registration
#-------------------------------------------------------------------------------

itcl::body isregistration::step {} {
    global Matrix

    ## update any parameters
    $itk_option(-update_procedure) $this

    if {$itk_option(-auto_repeat) == 0} {
        set _abort 0
         isprogress .regprogress \
          -title "Rigid Registration" -geometry 300x100+100+100  \
          -cancel_text "Stop Registration" \
          -progress_text "Registering" \
          -abort_command "$_reg SetAbort 1" \
          -use_main_progress 1 \
          -vtk_process_object [$_reg GetProcessObject]
        update
    }

    #######
    ## set the default values
    #######

    set i [lindex $itk_option(-source_shrink) 0 ]
    set j [lindex $itk_option(-source_shrink) 1 ]
    set k [lindex $itk_option(-source_shrink) 2 ]
    if {$itk_option(-verbose)} {
        puts "$i $j $k $itk_option(-source_shrink)"
    }
    catch {$_reg SetSourceShrinkFactors $i $j $k}

    set i [lindex $itk_option(-target_shrink) 0 ]
    set j [lindex $itk_option(-target_shrink) 1 ]
    set k [lindex $itk_option(-target_shrink) 2 ]
    if {$itk_option(-verbose)} {
        puts "$i $j $k $itk_option(-target_shrink)"
    }

    catch {$_reg SetTargetShrinkFactors $i $j $k}

    $itk_option(-set_metric_option) $_reg;

    $itk_option(-set_optimizer_option) $_reg;

    if {$itk_option(-resample) != 0} {
        set_resample_parameters
    }

    ##########
    # Get the current matrix - if it's different from the
    # the last matrix we set, copy it in and re-init reg 
    ##########

    set t $itk_option(-transform)

    $this set_init_mat

    $_reg Modified
    
    #$_sourcecast Update
    #$_targetcast Update

    $_sourcenorm Update
    $_targetnorm Update

    $_reg Update

    if {$itk_option(-verbose)} {
        $_reg Print
        puts "Metric [$_reg GetMetricValue]"
    }

    if {[$_reg GetError] > 0} {
        DevErrorWindow "Registration Algorithm returned an error!\n Are you sure the images overlap?"
        $itk_option(-stop_procedure);
        stop
        return
    }

    $this update_slicer_mat

    # Update MRML and display
    MainUpdateMRML
    RenderAll

    # the next iteration will not be the first iter...
    set _firsttime 0;
    
    if {$itk_option(-auto_repeat) == 0} {
        set _abort [ .regprogress is_abort ]
        destroy .regprogress
        $itk_option(-stop_procedure);
        stop
    }
}

#-------------------------------------------------------------------------------
# METHOD: update_slicer_mat
#
# DESCRIPTION: set the slicer matrix appropriately
#
# The matrix M returned by the registration takes vectors r1 from a space 
# centered on the center of the image, in mm space, and maps it to space r2
# centered on the center of the target image, in mm space
#
#  r2 <- M r1
#
# We want a matrix M' from Ras to Ras space. This is simply the Position Matrix
# P1 and P2 (for each volume)
#
#  R2 <- M' R1,  R1 = P1 r1, R2 = P2 r2
#  P2 r2 <- M' P1 r1
# So we conclude
#  M = P2^-1 M'P1
#
# or M' = P2 M P1^-1
#
#-------------------------------------------------------------------------------

itcl::body isregistration::update_slicer_mat {} {

    set t $itk_option(-transform)

    ## Call the matrix command

    set mat ::tmpmatrix_$_name
    catch "$mat Delete"
    vtkMatrix4x4 $mat

    $mat DeepCopy [$_reg GetOutputMatrix]

    puts "GetOutputMatrix"
    puts [$mat Print]

    if {$itk_option(-verbose)} {
      puts "The real mat output by the registration algorithm"
      puts [$this StringMatrix $mat]
    }

#   0.968893 0.247481 5.18321e-05 -18.2546 
#   -0.247481 0.968893 0.000201605 -25.8306 
#   -3.26387e-07 -0.000208161 1 0.0294268 
#   0 0 0 1

#
# General Rot
# 0.979268 0.132425 0.153287 
# 7.96021 -0.153178 0.979264 
# 0.132584 -6.05893 -0.132551 
# -0.153316 0.979247 0.952764 
# 0 0 0 1

# rot z
#
# 0.968908 0.247421 0.000125456 -18.2419 -0.247421 0.968908 0.00015346 -25.8546 -8.35858e-05 -0.000179729 1 -0.0039064 0 0 0 1
#
#    $mat Zero
#    $mat SetElement 0 0 0.9689
#    $mat SetElement 1 1 0.9689
#    $mat SetElement 2 2 1
#    $mat SetElement 3 3 1
#    $mat SetElement 0 1  0.2474
#    $mat SetElement 1 0 -0.2474
#    $mat SetElement 0 3 -18.28
#    $mat SetElement 1 3 -25.872

# rot y
# 0.968786 8.79436e-05 0.2479 29.5348 -5.47718e-05 1 -0.000140708 -0.00208282 -0.2479 0.000122738 0.968786 -31.8745 0 0 0 1
#
#    $mat Zero
#    $mat SetElement 0 0 0.9689
#    $mat SetElement 1 1  1
#    $mat SetElement 2 2  0.9689
#    $mat SetElement 3 3  1
#    $mat SetElement 0 2  0.2479
#    $mat SetElement 2 0 -0.2479
#    $mat SetElement 0 3 29.5348
#    $mat SetElement 2 3 -31.8745

# rotx
#1 -4.74651e-05 -5.65028e-05 14.999 5.99604e-05 0.968959 0.24722 21.9452 4.30146e-05 -0.24722 0.968959 27.2486 0 0 0 1
#    $mat SetElement 0 0 1
#    $mat SetElement 1 1 0.9689
#    $mat SetElement 2 2 0.9689
#    $mat SetElement 3 3  1
#    $mat SetElement 1 2  0.2479
#    $mat SetElement 2 1 -0.2479
#    $mat SetElement 0 3 15
#    $mat SetElement 1 3 27.2486
#    $mat SetElement 2 3 -31.8745


# pieper data
#1 -4.74651e-05 -5.65028e-05 14.999 5.99604e-05 0.968959 0.24722 21.9452 4.30146e-05 -0.24722 0.968959 27.2486 0 0 0 1
#    $mat SetElement 0 0 1
#    $mat SetElement 1 1 0.9689
#    $mat SetElement 2 2 0.9689
#    $mat SetElement 3 3  1
#    $mat SetElement 1 2  0.2479
#    $mat SetElement 2 1 -0.2479
#    $mat SetElement 0 3 15
#    $mat SetElement 1 3 27.2486
#    $mat SetElement 2 3 -31.8745

## Pieper data
# 0.998666 -0.0111754 -0.0504106 -22.8 
# 0.00955995 0.999436 -0.0321874 -11.1 
# 0.0507421 0.0316625 0.99821 -4 
# 0 0 0 1 

    if {$itk_option(-verbose)} {
        puts "Starting slicer updated matrix"
        puts "The mat"
        puts [$this StringMatrix $mat]
        puts "P1"
        puts [$this StringMatrix [$this getP1]]
        puts "P2"
        puts [$this StringMatrix [$this getP2]]
    }
## (p1^-1 mat p2)^-1 = p2^-1 mat^-1 p1
## So, both of these are identical.
    if {0} {
        set p2mat [$this getP1]
        $p2mat Invert
        $this GetSimilarityMatrix $p2mat $mat [$this getP2]
        $mat Invert
        puts "SHOULD NOT BE HERE"
    } else {
        if {$itk_option(-resample) == 0} {
            set p2mat [$this getP2]
            $p2mat Invert
            $mat Invert
            $this GetSimilarityMatrix $p2mat $mat [$this getP1]
            puts "NO RESAMPLING"
        }
    }

    Matrix($t,node) SetMatrix [$this StringMatrix $mat]
    
    puts "RESULTING MATRIX"
    puts [$mat Print]
    
    if {$itk_option(-verbose)} {
        set results_mat [$this StringMatrix [$_reg GetOutputMatrix] ]
        puts "resulting mat: $results_mat"
        set tmp_mat [Matrix($t,node) GetMatrix]
        puts "actually set $tmp_mat"
    }
    
    #$tmpnode Delete
    $mat Delete
    
    set _mat_m_time [[Matrix($t,node) GetTransform] GetMTime]
}

#-------------------------------------------------------------------------------
# METHOD: set_init_mat
#
# DESCRIPTION: set the matrix from the slicer matrix
#
# Using the logic from update_slicer_mat, M = P2^-1 M'P1
#
#
#-------------------------------------------------------------------------------

itcl::body isregistration::set_init_mat {} {
    
    #
    # Get the current matrix - if this is the first time through
    # OR someone has edited it since the last iteration
    #
    
    set t $itk_option(-transform)
    
    if { $_firsttime == 1 || [[Matrix($t,node) GetTransform] GetMTime] != $_mat_m_time } {
    set mat ::tmpmatrix_$_name
    catch "$mat Delete"
    vtkMatrix4x4 $mat

    if {$itk_option(-verbose)} {
       $mat DeepCopy [[Matrix($t,node) GetTransform] GetMatrix]
       puts "Initting Matrix: The Mat"
       puts [$this StringMatrix $mat]
       puts "P1"
       puts [$this StringMatrix [$this getP1]]
       puts "P2"
       puts [$this StringMatrix [$this getP2]]
    }

## p1 mat^-1 p2^-1. We need to invert the mat because
## it is a RasToWld matrix and we need WldToRas
## Note (p2 mat p1^-1)^-1 = p1 mat^-1 p2^-1
## So, both of these are identical.

    if {0} {
        ### works
        ## switch p1,p2 invert mat before
        $mat DeepCopy [[Matrix($t,node) GetTransform] GetMatrix]
        set p1mat [$this getP2]
        $p1mat Invert
        $mat Invert
        $this GetSimilarityMatrix [$this getP1] $mat $p1mat
        if {$itk_option(-verbose)} {
            puts "switch, before--"
            puts [$this StringMatrix $mat]
        }
    } else {
        #### works
        ## normal p1,p2, invert mat after
        $mat DeepCopy [[Matrix($t,node) GetTransform] GetMatrix]
        if {$itk_option(-resample) == 0} {
            set p1mat [$this getP1]
            $p1mat Invert
            $this GetSimilarityMatrix [$this getP2] $mat $p1mat
            $mat Invert
        }
        if {$itk_option(-verbose)} {
            puts "normal, after--"
            puts [$this StringMatrix $mat]
        }
    }

#### does not work
##    ## normal p1,p2 invert mat before
##    $mat DeepCopy [[Matrix($t,node) GetTransform] GetMatrix]
##    set p1mat [$this getP1]
##    $p1mat Invert
##    $mat Invert
##    $this GetSimilarityMatrix [$this getP2] $mat $p1mat
##    puts "normal, before"
##    puts [$this StringMatrix $mat]
#
#### no works
##    # swith p1,p2 invert Mat after
##    $mat DeepCopy [[Matrix($t,node) GetTransform] GetMatrix]
##    set p1mat [$this getP2]
##    $p1mat Invert
##    $this GetSimilarityMatrix [$this getP1] $mat $p1mat
##    $mat Invert
##    puts "switch, after"
##    puts [$this StringMatrix $mat]

    $_matrix DeepCopy $mat
    $mat Delete

    if {$itk_option(-verbose)} {
        puts "Determinant"
        puts [$_matrix Determinant]
    }
    $_reg Initialize $_matrix
    puts "INITIAL MATRIX"
    puts [$_matrix Print]

    if {$itk_option(-verbose)} {
        set matstring [Matrix($t,node) GetMatrix]
        puts "input matrix $matstring"
        set matstring [$this StringMatrix $_matrix ]
        puts "transformed input matrix $matstring"
#        set matstring [$this StringMatrix [$_reg GetOutputMatrix ]]
#        puts "transformed input matrix $matstring"
        }
    
    ## keep track of MTime just in case user updates that transform...
    set _mat_m_time [[Matrix($t,node) GetTransform] GetMTime]
    } else {
        if {$itk_option(-verbose)} {
            puts "Not re-Initting matrix"
        }
    }
}

#-------------------------------------------------------------------------------
# METHOD: GetSimilarityMatrix
#
# DESCRIPTION: Updates a Matrix with a similarity transform
#
# 
# s2 * mat * s1. Result updates mat
#
#-------------------------------------------------------------------------------

itcl::body isregistration::GetSimilarityMatrix { s2 mat s1 } {
    $mat Multiply4x4 $mat $s1 $mat
    $mat Multiply4x4 $s2 $mat $mat
}

#-------------------------------------------------------------------------------
# METHOD: getP1
#
# DESCRIPTION: return a matrix for ...
#-------------------------------------------------------------------------------

itcl::body isregistration::getP1 {  } {

    set _p1 ::matrixp1_$_name
    catch  "$_p1 Delete"
    vtkMatrix4x4 $_p1

    GetSlicerRASToItkMatrix Volume($itk_option(-source),node) $_p1
    if {$itk_option(-verbose)} {
         puts [$this StringMatrix $_p1]
    }
    return $_p1
}


#-------------------------------------------------------------------------------
# METHOD: getP2
#
# DESCRIPTION: return a matrix for ...
#-------------------------------------------------------------------------------

itcl::body isregistration::getP2 {  } {

    set _p2 ::matrixp2_$_name
    catch  "$_p2 Delete"
    vtkMatrix4x4 $_p2

    GetSlicerRASToItkMatrix Volume($itk_option(-target),node) $_p2
    if {$itk_option(-verbose)} {
        puts [$this StringMatrix $_p2]
    }
    return $_p2
}


#-------------------------------------------------------------------------------
# METHOD: StringMatrix
#
# DESCRIPTION: return a matrix as 16 floats in a string
#-------------------------------------------------------------------------------

itcl::body isregistration::StringMatrix { mat4x4 } {

    set mat ""
    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            set mat "$mat [$mat4x4 GetElement $i $j]"
        }
    }
    return [string trimleft $mat " "]
}


#-------------------------------------------------------------------------------
# METHOD: StringToMatrix
#
# DESCRIPTION: fills in a matrix with a string
#-------------------------------------------------------------------------------

itcl::body isregistration::StringToMatrix { mat4x4 str} {

    for {set i 0} {$i < 4} {incr i} {
        for {set j 0} {$j < 4} {incr j} {
            $mat4x4 SetElement $i $j [lindex $str [expr $i*4+$j]
        }
    }
}

#-------------------------------------------------------------------------------
# METHOD: get_last_metric_value
#
# DESCRIPTION: Gets the last metric value
#-------------------------------------------------------------------------------

itcl::body isregistration::get_last_metric_value { } {

 return [$_reg GetMetricValue]
}

#-------------------------------------------------------------------------------
# METHOD: set_dimensions for a  volume
# based on resample option that represents the downsample scale
#
# DESCRIPTION: 
#-------------------------------------------------------------------------------
itcl::body isregistration::get_dimensions { vId } {
    set order [Volume($vId,node) GetScanOrder]

    set dimension [split [[Volume($vId,vol) GetOutput] GetDimensions]] 
        
    set scale $itk_option(-resample)
    if {$scale <= 0} {
        set scale 1
    }

    set dimI [expr round(abs([lindex $dimension 0] - 1)/ $scale + 1)]
    set dimJ [expr round(abs([lindex $dimension 1] - 1)/ $scale + 1)]
    set dimK [expr round(abs([lindex $dimension 2] - 1)/ $scale + 1)]

    switch $order {
        "RL" -
        "LR" {
            set odimI $dimK
            set odimJ $dimI
            set odimK $dimJ
        }
        "PA" -
        "AP" {
            set odimI $dimI
            set odimJ $dimK
            set odimK $dimJ
        }
        "SI" -
        "IS" {
            set odimI $dimI
            set odimJ $dimJ
            set odimK $dimK
        }
        default {
            tk_messageBox -message "isregistration: Unknown target orientation: $order"
        }
    }
    return [list $odimI $odimJ $odimK]
}


#-------------------------------------------------------------------------------
# METHOD: set_spacing for a volume
# based on resample option that represents the downsample scale
# DESCRIPTION: 
#-------------------------------------------------------------------------------
itcl::body isregistration::get_spacing { vId } {
    set order [Volume($vId,node) GetScanOrder]

    set spacing [split [[Volume($vId,vol) GetOutput] GetSpacing]] 

    set scale $itk_option(-resample)
    if {$scale <= 0} {
        set scale 1
    }
    set spacingI [expr [lindex $spacing 0] * $scale]
    set spacingJ [expr [lindex $spacing 1] * $scale]
    set spacingK [expr [lindex $spacing 2] * $scale]

    switch $order {
        "RL" -
        "LR" {
            set ospacingI $spacingK
            set ospacingJ $spacingI
            set ospacingK $spacingJ
        }
        "PA" -
        "AP" {
            set ospacingI $spacingI
            set ospacingJ $spacingK
            set ospacingK $spacingJ
        }
        "SI" -
        "IS" {
            set ospacingI $spacingI
            set ospacingJ $spacingJ
            set ospacingK $spacingK
        }
        default {
            tk_messageBox -message "isregistration: Unknown source orientation: $order"
        }
    }
    return [list $ospacingI $ospacingJ $ospacingK]
}
#-------------------------------------------------------------------------------
# METHOD: set_resample_parameters set spacing and dimension for target and source volumes
# based maximum dimension of both
# DESCRIPTION: 
#-------------------------------------------------------------------------------
itcl::body isregistration::set_resample_parameters {} {

    set source_dim [get_dimensions $itk_option(-source)]
    set target_dim [get_dimensions $itk_option(-target)]

    set source_spacing [get_spacing $itk_option(-source)]
    set target_spacing [get_spacing $itk_option(-target)]

    set s_dimension {}
    set t_dimension {}
    set s_spacing {}
    set t_spacing {}

    for {set x 0} {$x<3} {incr x} {
        set s_dim [lindex $source_dim $x]
        set t_dim [lindex $target_dim $x]
        if {$t_dim >= $s_dim} {
            lappend t_dimension $t_dim 
            lappend s_dimension $t_dim 
            lappend t_spacing [lindex $target_spacing $x]
            if {$t_dim > 1} {
                lappend s_spacing [expr [lindex $source_spacing $x] * ($s_dim - 1.0)/($t_dim - 1.0)]
            } else {
                lappend s_spacing 0
            }
        } else {
            lappend t_dimension $s_dim 
            lappend s_dimension $s_dim 
            lappend s_spacing [lindex $source_spacing $x]
            if {$s_dim > 1} {
                lappend t_spacing [expr [lindex $target_spacing $x] * ($t_dim - 1.0)/($s_dim - 1.0)]
            } else {
                lappend s_spacing 0
            }
        }

    }

    puts "isregistration:: source dimensions = $s_dimension"
    puts "isregistration:: source spcaing = $s_spacing"
    puts "isregistration:: target dimensions = $t_dimension"
    puts "isregistration:: target spcaing = $t_spacing"

    $_sourcevol set_dimensions [lindex $s_dimension 0] [lindex $s_dimension 1] [lindex $s_dimension 2]
    $_sourcevol set_spacing [lindex $s_spacing 0] [lindex $s_spacing 1] [lindex $s_spacing 2]
    $_targetvol set_dimensions [lindex $t_dimension 0] [lindex $t_dimension 1] [lindex $t_dimension 2]
    $_targetvol set_spacing [lindex $t_spacing 0] [lindex $t_spacing 1] [lindex $t_spacing 2]

}


# ------------------------------------------------------------------

itcl::body isregistration::deformation_volume { {name ""} } {
    if {[$_reg GetAbortExecute] != 0 } {
        return
    }

    if { [info command MainMrmlAddNode] == "" } {
        error "cannot create slicer volume outside of slicer"
    }

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i
    
    # find a name for the image data that hasn't been taken yet
    while {1} {
        set id deform_vol_$_name$_volume_serial
        if { [info command $id] == "" } {
            break ;# found a free name
        } else {
            incr _volume_serial ;# need to try again
        }
    }

    # set the name and description of the volume
    if { $name == "" } { 
        $n SetName isvolume-$_volume_serial
    } else {
        $n SetName $name
    }
    $n SetDescription "Resampled volume"
    incr _volume_serial

    #
    # need to construct a deformation volume from the reg output
    # - make sagittal so we can flip the X axis by specifying
    #   RL instead of LR
    # - then copy the image data
    # - then set up the volume node parameters and make it visible in slicer
    #

    #$_reg Update
    
    vtkImageData $id
    eval [$_reg GetOutputDisplacement] SetUpdateExtent [[$_reg GetOutputDisplacement] GetWholeExtent]
    [$_reg GetOutputDisplacement] Update
    $id DeepCopy [$_reg GetOutputDisplacement]
    
    ::Volume($i,node) SetNumScalars 3
    ::Volume($i,node) SetScalarType [$id GetScalarType]
    
    eval ::Volume($i,node) SetSpacing [$id GetSpacing]
    
    ::Volume($i,node) SetScanOrder IS
    ::Volume($i,node) SetDimensions [lindex [$id GetDimensions] 0] [lindex [$id GetDimensions] 1]
    ::Volume($i,node) SetImageRange 1 [lindex [$id GetDimensions] 2]
    
    set extents [$id GetWholeExtent]
    set dims "[expr [lindex $extents 1] - [lindex $extents 0] + 1] \
              [expr [lindex $extents 3] - [lindex $extents 2] + 1] \
              [expr [lindex $extents 5] - [lindex $extents 4] + 1]"
    set spacing [$id GetSpacing]

    catch "rasToIjkMatrix Delete"
    vtkMatrix4x4 rasToIjkMatrix
    rasToIjkMatrix Identity
    rasToIjkMatrix SetElement 0 0 [expr -1/[lindex $spacing 0]]
    rasToIjkMatrix SetElement 1 1 [expr -1/[lindex $spacing 1]]
    rasToIjkMatrix SetElement 2 2 [expr 1/[lindex $spacing 2]]

    puts "[rasToIjkMatrix Print]"
    VolumesComputeNodeMatricesFromRasToIjkMatrix Volume($i,node) rasToIjkMatrix $dims

    ::Volume($i,vol) SetImageData $id
    MainUpdateMRML

    #Slicer SetOffset 0 0
    #MainSlicesSetVolumeAll Back $i
    #RenderAll


}


#-------------------------------------------------------------------------------
# .PROC isregistration_demo
# A demo written by Steve Pieper.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc isregistration_demo {} {

    catch "destroy .isregistrationdemo"
    toplevel .isregistrationdemo
    wm title .isregistrationdemo "isregistrationdemo"

    pack [isregistration .isregistrationdemo.isr] -fill both -expand true
}
