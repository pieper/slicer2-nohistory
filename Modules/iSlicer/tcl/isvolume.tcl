#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: isvolume.tcl,v $
#   Date:      $Date: 2006/05/16 22:11:18 $
#   Version:   $Revision: 1.42 $
# 
#===============================================================================
# FILE:        isvolume.tcl
# PROCEDURES:  
#   isvolume_demo
#   iSlicerUpdateMRML
#   isvolume_transform_test
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Iwidgets

if { [info command ::iwidgets::collapsablewidget] == "" } {
    # TODO - add this to the iSlicer package so it comes in with package require
    # - must be done up here to avoid being defined in isvolume namespace
    global env
    source $env(SLICER_HOME)/Modules/iSlicer/tcl/collapsablewidget.itk
}

#########################################################
#
if {0} { ;# comment

isvolume - a widget for looking at Slicer volumes 

# TODO : 
    - built-in pan-zoom through reslice
    - export reslice output for use with MI
    - reslice sag, cor
    - default key and mouse bindings
    - overlay/label options
    - split controls to different widget class
    - it is not a good idea to access volumes by Name
      because names are not unique. By Id number is appropriate.    

}
#
#########################################################

#
# Default resources
# - sets the default colors for the widget components
#
option add *isvolume.background #000000 widgetDefault
option add *isvolume.orientation Axial(IS) widgetDefault
option add *isvolume.volume "None" widgetDefault
option add *isvolume.warpvolume "None" widgetDefault
option add *isvolume.slice 128 widgetDefault
option add *isvolume.interpolation linear widgetDefault
option add *isvolume.resolution 256 widgetDefault
option add *isvolume.transform "" widgetDefault
option add *isvolume.tensor "false" widgetDefault

#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class isvolume] == "" } {
    
    itcl::class isvolume {
        inherit iwidgets::Labeledwidget
        
        constructor {args} {}
        destructor {}
        
        #
        # itk_options for widget options that may need to be
        # inherited or composed as part of other widgets
        # or become part of the option database
        #
        itk_option define -background background Background {}
        itk_option define -orientation orientation Orientation {Axial(IS)}
        itk_option define -volume volume Volume "None"
        itk_option define -warpvolume warpvolume Refvolume "None"
        itk_option define -slice slice Slice 0
        itk_option define -interpolation interpolation Interpolation {linear}
        itk_option define -resolution resolution Resolution {256}
        itk_option define -transform transform Transform {}
        itk_option define -tensor tensor Tensor {false}
        
        # widgets for the control area
        variable _controls
        variable _slider
        variable _orientmenu
        variable _resmenu
        variable _volmenu
        
        # vtk objects in the slice render
        variable _name
        variable _tkrw
        variable _renwin
        variable _ren
        variable _mapper
        variable _actor
        variable _None_ImageData
        
        # vtk objects for reslicing
        variable _ijkmatrix
        variable _reslice
        variable _resliceST
        variable _xform
        variable _changeinfo
        variable _spacing
        variable _dimensions
        
        # internal state variables
        variable _warpVolId 0
        variable _VolIdMap
        variable _volume_serial 0
        variable _render_pending 0 ;# manages render event compaction
        
        # methods
        method render {}   {}
        method expose {}   {}
        method actor  {}   {return $_actor}
        method mapper {}   {return $_mapper}
        method reslice {}  {return $_reslice}
        method resliceST {}  {return $_resliceST}
        method ren    {}   {return $_ren}
        method tkrw   {}   {return $_tkrw}
        method controls {} {return $_controls}
        method rw     {}   {return [$_tkrw GetRenderWindow]}
        method spacing{}   {return $_spacing}
        method dimensions{}   {return $_dimensions}
        
        # Note: use SetUpdateExtent to get full volume in the imagedata
        method imagedata {} {
            if { $itk_option(-tensor) == "true" } {
                return [$_resliceST GetOutput]
            } else {
                return [$_reslice GetOutput]
            }
        }
        
        method screensave { filename {imagetype "PNM"} } {} ;# TODO should be moved to superclass
        method volmenu_update {} {}
        method transform_update {} {}
        method slicer_volume { {name ""} {label_map "false"} } {}
        method slicer_tensor { {name ""} } {}
        method set_spacing  {spacingI spacingJ spacingK} {}
        method set_dimensions  {dimensionI dimensionJ dimensionK} {}
        method scanorder{} {}

        method pre_destroy {} {}

    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body isvolume::constructor {args} {
    component hull configure -borderwidth 0


    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name

    #
    # build the controls
    # - TODO - split this into separate class as it gets more complex
    #

    set _controls $itk_interior.controls_$_name
    ::iwidgets::collapsablewidget $_controls -labeltext "Slice Controls"
    pack $_controls -side top -expand false -fill x
    set cs [$_controls childsite]

    set _slider $cs.slider
    scale $_slider -orient horizontal 
    $_slider set 128
    $_slider configure -command "$this configure -slice "
    pack $_slider -side top -expand true -fill x

    set _orientmenu $cs.orientmenu
    iwidgets::optionmenu $_orientmenu -labeltext "Or:" -labelpos w \
        -command "$this configure -orientation \[$_orientmenu get\]"
    $cs.orientmenu insert end "Axial(IS)"
    $cs.orientmenu insert end "Axial(SI)"
    $cs.orientmenu insert end "Sagittal(RL)"
    $cs.orientmenu insert end "Sagittal(LR)"
    $cs.orientmenu insert end "Coronal(PA)"
    $cs.orientmenu insert end "Coronal(AP)"
    $cs.orientmenu insert end "RAS (VTK - Y/A up)"
    $cs.orientmenu insert end "RAS (ITK - Y/A down)"

    set _resmenu $cs.resmenu
    iwidgets::optionmenu $_resmenu -labeltext "Res:" -labelpos w
    $cs.resmenu insert end "64"
    $cs.resmenu insert end "128"
    $cs.resmenu insert end "256"
    $cs.resmenu insert end "512"
    $cs.resmenu insert end "1024"
    $cs.resmenu select 2 ;# can't access itk_option from in constructor to get default? :(
    $_resmenu configure -command "$this configure -resolution \[$_resmenu get\]"

    set _volmenu $cs._volmenu
    iwidgets::optionmenu $_volmenu -labeltext "Bg:" -labelpos w \
        -command "$this configure -volume \[$_volmenu get\]"

    $this volmenu_update

    pack $_orientmenu $_resmenu $_volmenu -side top -expand true -fill x
    ::iwidgets::Labeledwidget::alignlabels $_orientmenu $_resmenu $_volmenu
    
    #
    # build the vtk image viewer
    #
    iwidgets::scrolledframe $itk_interior.sframe \
        -hscrollmode dynamic -vscrollmode dynamic -width 300 -height 300
    pack $itk_interior.sframe -fill both -expand true
    set cs [$itk_interior.sframe childsite]
    set _tkrw $cs.tkrw
    if { $::tcl_platform(platform) != "windows" } {
        set _renwin ::renwin_$_name
        catch "$_renwin Delete"
        vtkRenderWindow $_renwin
        vtkTkRenderWidget $_tkrw -width 256 -height 256 -rw $_renwin
    } else {
        vtkTkRenderWidget $_tkrw -width 256 -height 256 
        set _renwin [$this rw]
    }

    pack $_tkrw -expand true -fill both
    bind $_tkrw <Expose> "$this expose"

    set _ren ::ren_$_name
    set _mapper ::mapper_$_name
    set _actor ::actor_$_name
    set _None_ImageData ::imagedata_$_name
    catch "$_ren Delete"
    catch "$_mapper Delete"
    catch "$_actor Delete"
    catch "$_None_ImageData Delete"

    # put some default data into the None volume
    vtkImageData $_None_ImageData 
    set esrc ::tmpesource_$_name 
    vtkImageEllipsoidSource $esrc
    $esrc SetRadius 20 40 10
    $esrc SetCenter 64 64 64
    $esrc SetInValue 100
    $esrc SetWholeExtent 0 127 0 127 0 127
    $esrc SetOutput $_None_ImageData
    $esrc Update
    $esrc SetOutput ""
    $esrc Delete
    $_None_ImageData SetSpacing 2 2 2
    set _spacing {2 2 2}
    set _dimensions {128 128 128}


    vtkRenderer $_ren
    [$this rw] AddRenderer $_ren
    vtkImageMapper $_mapper
    $_mapper SetInput $_None_ImageData 
    vtkActor2D $_actor
    $_actor SetMapper $_mapper
    $_ren AddActor2D $_actor

    # for reslicing
    set _ijkmatrix ::ijkmatrix_$_name
    set _reslice ::reslice_$_name
    set _resliceST ::resliceST_$_name
    set _xform ::xform_$_name
    set _changeinfo ::changeinfo_$_name
    catch "$_ijkmatrix Delete"
    catch "$_reslice Delete"
    catch "$_resliceST Delete"
    catch "$_xform Delete"
    catch "$_changeinfo Delete"

    vtkMatrix4x4 $_ijkmatrix
    if { [info command vtkImageResliceST] == "" } {
        # if no ST, try regular reslice
        vtkImageReslice $_resliceST
    } else {
        vtkImageResliceST $_resliceST
    }
    vtkImageReslice $_reslice
      $_reslice SetInterpolationModeToLinear
      $_resliceST SetInterpolationModeToLinear
    vtkGeneralTransform $_xform
    vtkImageChangeInformation $_changeinfo
      $_changeinfo SetInput $_None_ImageData
      $_changeinfo CenterImageOn

    $_reslice SetInput [$_changeinfo GetOutput]
    $_resliceST SetInput [$_changeinfo GetOutput]

    #
    # Initialize the widget based on the command line options.
    #
    eval itk_initialize $args
}


itcl::body isvolume::destructor {} {
    catch "$this pre_destroy"
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# OPTION: -background
#
# DESCRIPTION: background color of the image viewer
#-------------------------------------------------------------------------------
itcl::configbody isvolume::background {

  if {$itk_option(-background) == ""} {
    return
  }

  set scanned [scan $itk_option(-background) "#%02x%02x%02x" r g b]

  if { $scanned == 3 } {
      $_ren SetBackground [expr ($r/255.)] [expr ($g/255.)] [expr ($b/255.)]
      $this expose
  }

}

#-------------------------------------------------------------------------------
# OPTION: -slice
#
# DESCRIPTION: slice number for the current volume
#-------------------------------------------------------------------------------
itcl::configbody isvolume::slice {

    if {$itk_option(-slice) == ""} {
        return
    }
    $_mapper SetZSlice $itk_option(-slice)
    $_slider set $itk_option(-slice)
    $this expose
}

#-------------------------------------------------------------------------------
# OPTION: -volume
#
# DESCRIPTION: which slicer volume to display in this isvolume
# The argument can be the volume name or the volume Id. The volume
# Id is strongly prefered because it is unique.
#-------------------------------------------------------------------------------
itcl::configbody isvolume::volume {

    set volname $itk_option(-volume)

    if { $volname == "" } {
        set volname "None"
    }

    #
    # check to see if the volume is a vtkImageData, and if so, use it
    #
    if { [info command $volname] != "" } {
        catch "$volname GetClassName" res
        if { $res == "vtkImageData" } {
            $_changeinfo SetInput $volname

            $volname Update
            foreach "min max" [$volname GetScalarRange] {}
            $_mapper SetColorWindow [expr $max - $min]
            $_mapper SetColorLevel [expr ($max + $min) / 2.]

            $this configure -slice [expr $itk_option(-resolution) / 2]
            $this configure -orientation Axial(IS)
            $this transform_update
        }
        $this expose
        return
    }

    # 
    # otherwise, assume this is the name or id of a slicer volume
    #

    # but if slicer's variables aren't present, set to none
    if { ![info exists ::Volume] } {
        $_changeinfo SetInput $_None_ImageData 
        return
    }

    set id $_VolIdMap($volname)

    if { ![info exists _VolIdMap($id)] } {
        error "bad volume id $id for $volname"
    }

    if { $id == "None" || $id == $::Volume(idNone)} {
        $_changeinfo SetInput $_None_ImageData 
    } else {
        $_changeinfo SetInput [::Volume($id,vol) GetOutput]
    }


    $_mapper SetInput [$_reslice GetOutput]
    $_mapper SetColorWindow [::Volume($id,node) GetWindow]
    $_mapper SetColorLevel [::Volume($id,node) GetLevel]

    $this transform_update
    if {$volname != "None" && $volname != ""} {
        #$_volmenu select $volname
    }
    $this expose
}

#-------------------------------------------------------------------------------
# OPTION: -warpvolume
#
# DESCRIPTION: which slicer volume to use as a reference for metadata:
# spacing dimensions and scan order
# The argument can be the volume name or the volume Id. The volume
# Id is strongly prefered because it is unique.
#-------------------------------------------------------------------------------
itcl::configbody isvolume::warpvolume {
    set volname $itk_option(-warpvolume)

    if { $volname == "" || $volname == $::Volume(idNone) } {
        set volname "None"
    }

    if { [info exists ::Volume] } {
        set _warpVolId $_VolIdMap($volname)

        if { ![info exists _VolIdMap($_warpVolId)] } {
            set _warpVolId 0
            error "bad volume id $_warpVolId for $volname"
        }
    }
    $this transform_update
}


#-------------------------------------------------------------------------------
# OPTION: -orientation
#
# DESCRIPTION: which slicer volume to display in this isvolume
#-------------------------------------------------------------------------------
itcl::configbody isvolume::orientation {

    # don't change the orientation of the None volume
    # also allow for an empty orientation option
    if { $itk_option(-orientation) == "" || 
            $itk_option(-volume) == "" || $itk_option(-volume) == "None" } {
        return
    } else {
        $_mapper SetInput [$_reslice GetOutput]
    }

    $this transform_update
    $this configure -resolution $itk_option(-resolution)

    switch $itk_option(-orientation) {
        "IS" -
        "axial" -
        "Axial" -
        "axial(IS)" -
        "Axial(IS)" {
            set orient "Axial(IS)"
        }
        "SI" -
        "axial(SI)" -
        "Axial(SI)" {
            set orient "Axial(SI)" 
        }
        "RL" -
        "sagittal" -
        "Sagittal" - 
        "sagittal(RL)" -
        "Sagittal(RL)" {
            set orient "Sagittal(RL)" 

        }
        "LR" -
        "sagittal(LR)" -
        "Sagittal(LR)" {
            set orient "Sagittal(LR)"
        }
        "PA" -
        "coronal" -
        "Coronal" -
        "coronal(PA)" -
        "Coronal(PA)" {
            set orient "Coronal(PA)" 
        }
        "AP" - 
        "coronal(AP)" -
        "Coronal(AP)" {
            set orient "Coronal(AP)" 
        }
        "RAS (VTK - Y/A up)" -
        "RAS-VTK" -
        "RAS" {
            set orient "RAS (VTK - Y/A up)"
        }
        "RAS (ITK - Y/A down)" -
        "RAS-ITK" {
            set orient "RAS (ITK - Y/A down)"
        }
        "AxiSlice" -
        "SagSlice" -
        "CorSlice" -
        default {
            tk_messageBox -message "Unknown orientation: $itk_option(-orientation)"
        }
    }

    $_orientmenu select $orient
}

# ------------------------------------------------------------------
itcl::configbody isvolume::interpolation {
    switch $itk_option(-interpolation) {
        "Linear" -
        "linear" { set mode Linear }
        "Cubic" -
        "cubic" { set mode Cubic }
        "Nearest Neighbor" -
        "NearestNeighbor" -
        "nearest" -
        "nearestneighbor" { set mode NearestNeighbor }
        default {
            error "must be nearest, linear, or cubic"
        }
    }
    $_reslice SetInterpolationModeTo$mode
    $_resliceST SetInterpolationModeTo$mode
    $this expose
}

# ------------------------------------------------------------------
itcl::configbody isvolume::resolution {

    set res $itk_option(-resolution)

    set opos [expr ([$this cget -slice] * 1.0) / [$_slider cget -to] ]
    if { [info exists ::View(fov)] } {
        set fov $::View(fov)
    } else {
        set fov 256
    }
    set spacing [expr $fov / (1.0 * $res)]

    set _spacing {$spacing $spacing $spacing}

    $_reslice SetOutputSpacing $spacing $spacing $spacing 
    $_resliceST SetOutputSpacing $spacing $spacing $spacing 
    set ext [expr $res -1]

    set _dimensions {$res $res $res}

    $_reslice SetOutputExtent 0 $ext 0 $ext 0 $ext
    $_resliceST SetOutputExtent 0 $ext 0 $ext 0 $ext

    $this transform_update

    # the "*" is there to avoid having the resolution number interpreted
    # as a numerical index - it's a pattern match instead
    if { $res != [$_resmenu get] } {
        $_resmenu select "*$itk_option(-resolution)" 
    }

    $_slider configure -from 0
    $_slider configure -to $res
    $_tkrw configure -width $res -height $res
    $this configure -slice [expr round( $opos * $res )]

}

# ------------------------------------------------------------------
itcl::configbody isvolume::transform {

    $this transform_update
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------


itcl::body isvolume::render {} {
    $_tkrw Render
    set _render_pending 0
}

itcl::body isvolume::expose {} {
    if { $_render_pending == 0 } {
        after idle "$this render"
        set _render_pending 1
    } 
}

# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# METHOD: volmenu_update
#
# DESCRIPTION: create the array of volume names and ids
# - use the id to form a unique name in the menu
# - id map can be accessed by name, id, or name__id
#-------------------------------------------------------------------------------
itcl::body isvolume::volmenu_update {} {

    if { [info exists itk_option(-volume)] && $itk_option(-volume) != "" } {
        set v $itk_option(-volume)
        if { [info exists _VolIdMap($v)] } {
            set current_id $_VolIdMap($v)
        } else {
            set current_id -1
        }
    } else {
        set current_id -1
    }

    array unset _VolIdMap
    array set _VolIdMap ""

    if { [info exists ::Volume(idList) ] } {
        foreach id $::Volume(idList) {
            set name [::Volume($id,node) GetName]
            set _VolIdMap($name)  $id
            set _VolIdMap($id)    $id
            set _VolIdMap(${name}__$id)  $id 
        }

        set ocmd [$_volmenu cget -command]
        $_volmenu configure -command ""
        $_volmenu delete 0 end
        foreach id $::Volume(idList) {
            set name [::Volume($id,node) GetName]
            $_volmenu insert end  ${name}__$id
        }
        $_volmenu configure -command $ocmd

        set idindex [lsearch $::Volume(idList) $current_id]
        if { $idindex == -1 } {
            $_volmenu select end
        } else {
            $_volmenu select $idindex
        }
    }
}


#-------------------------------------------------------------------------------
# METHOD: transform_update
#
# DESCRIPTION: recalculate the transform parameters
#             
#            
#           
#-------------------------------------------------------------------------------
itcl::body isvolume::transform_update {} {

    if { ![info exists itk_option(-volume)] || $itk_option(-volume) == "" } {
        return
    }

    set volname $itk_option(-volume)

    if { [info command $volname] != "" } {
        catch "$volname GetClassName" res
        if { $res == "vtkImageData" } {
            set ScanOrder "IS"
            set RasToWld "1 0 0 0  0 1 0 0  0 0 1 0  0 0 0 1"
            set RasToIJK "1 0 0 0  0 1 0 0  0 0 1 0  0 0 0 1"
        } else {
            # can't do anything with a class that's not a vtkImageData
            return
        }
    } else {
        if { [info exists _VolIdMap($volname)] } {
            set id $_VolIdMap($itk_option(-volume))
            set ScanOrder [::Volume($id,node) GetScanOrder]
            set RasToWld [::Volume($id,node) GetRasToWld]
            set RasToIJK [::Volume($id,node) GetRasToIjkMatrix]
        } else {
            # can't do anything - the volume isn't a vtkImageData or the 
            # index of a slicer Volume node
            return
        }
    }

    # Existing volume scan order and orientation
    # first, make the transform to put the images
    # into axial RAS space.  Center the volume resliced output
    # around the origin of RAS space
    # - size of RAS space is cube of size fov
    # - output extent of RAS is a to-be-defined resolution
    # - a to-be-defined pan-zoom transform will map to the screen
    #

    catch "ijk_to_ras Delete"
    vtkMatrix4x4 ijk_to_ras
    ijk_to_ras Identity

    for {set i 0} {$i < 3} {incr i} {
        set x [lindex $RasToIJK [expr $i*4]]
        set y [lindex $RasToIJK [expr $i*4+1]]
        set z [lindex $RasToIJK [expr $i*4+2]]
        set l [expr sqrt($x*$x + $y*$y + $z*$z)]
        ijk_to_ras SetElement 0 $i [expr $x/$l]
        ijk_to_ras SetElement 1 $i [expr $y/$l]
        ijk_to_ras SetElement 2 $i [expr $z/$l]
    }

    ijk_to_ras Invert

    # desired orenation
    catch "ras_to_orient Delete"
    vtkMatrix4x4 ras_to_orient

    switch $itk_option(-orientation) {
        "IS" -
        "axial" -
        "Axial" -
        "Axial(IS)" -
        "axial(IS)" {
            ras_to_orient DeepCopy \
               -1  0  0  0 \
                0 -1  0  0 \
                0  0  1  0 \
                0  0  0  1    
        }
        "SI" -
        "Axial(SI)" -
        "axial(SI)" {
            ras_to_orient DeepCopy \
               -1  0  0  0 \
                0 -1  0  0 \
                0  0 -1  0 \
                0  0  0  1    
        }
        "RL" -
        "sagittal" -
        "Sagittal" - 
        "sagittal(RL)" -
        "Sagittal(RL)" {
            ras_to_orient DeepCopy \
                0  0 -1  0 \
               -1  0  0  0 \
                0 -1  0  0 \
                0  0  0  1    
        }
        "sagittal(LR)" -
        "Sagittal(LR)" -
        "LR" {
            ras_to_orient DeepCopy \
                0  0  1  0 \
               -1  0  0  0 \
                0 -1  0  0 \
                0  0  0  1    
        }
        "PA" -
        "coronal" -
        "Coronal" -
        "coronal(PA)" -
        "Coronal(PA)" {
            ras_to_orient DeepCopy \
               -1  0  0  0 \
                0  0  1  0 \
                0 -1  0  0 \
                0  0  0  1    
        }
        "coronal(AP)" -
        "Coronal(AP)" -
        "AP" {
            ras_to_orient DeepCopy \
               -1  0  0  0 \
                0  0 -1  0 \
                0 -1  0  0 \
                0  0  0  1    
        }
        "RAS (VTK - Y/A up)" -
        "RAS-VTK" -
        "RAS" {
            ras_to_orient DeepCopy \
                1  0  0  0 \
                0  1  0  0 \
                0  0  1  0 \
                0  0  0  1    
        }
        "RAS (ITK - Y/A down)" -
        "RAS-ITK" {
            ras_to_orient DeepCopy \
                1  0  0  0 \
                0 -1  0  0 \
                0  0  1  0 \
                0  0  0  1    
        }
        "AxiSlice" -
        "SagSlice" -
        "CorSlice" {
            # nothing yet
        }
    }

    #
    # make a matrix of the supplied transform - positions the volume
    # in RAS space (inverted for use with ImageReslice)
    # - use the config option transform if supplied, otherwise get from node
    #
    catch "transformmatrix Delete"
    vtkMatrix4x4 transformmatrix

    if { $itk_option(-transform) != ""} {
        switch [$itk_option(-transform) GetClassName] {
            "vtkTransform" {
                eval transformmatrix DeepCopy [$itk_option(-transform) GetMatrix]
            }
            "vtkMatrix4x4" {
                eval transformmatrix DeepCopy $itk_option(-transform)
            }
        }
    } else {
        eval transformmatrix DeepCopy $RasToWld
    }

    transformmatrix Invert

    #
    # now combine the matrices
    # - _ijkmatrix goes from image voxels to RAS
    # - transformmatrix moves the volume in RAS space
    # - ras_to_orient picks an orientation to reslice RAS space
    #

    #ijk_to_ras Multiply4x4 ijk_to_ras transformmatrix ijk_to_ras
    #ijk_to_ras Multiply4x4 ijk_to_ras ras_to_orient ijk_to_ras

    $_xform Identity

    catch "flip Delete"
    vtkMatrix4x4 flip
    flip SetElement 1 1 -1
    $_xform Concatenate flip

    $_xform Concatenate ijk_to_ras

    $_xform Concatenate transformmatrix

    # concatenate with displacement field transform
    if { [info exists ::Volume] } {
        if {$_warpVolId != "" && $_warpVolId != $::Volume(idNone)} {
            catch "centerImage Delete"
            vtkImageChangeInformation centerImage
            centerImage SetInput [::Volume($_warpVolId,vol) GetOutput]
            centerImage CenterImageOn
            centerImage Update

            catch "dispXform Delete"
            vtkGridTransform dispXform 
            dispXform SetDisplacementGrid [centerImage GetOutput]
            
            #$_xform PostMultiply 
            #dispXform Inverse
            $_xform Concatenate dispXform
            dispXform Delete
        }
    }

    $_xform Concatenate ras_to_orient

    catch "flip2 Delete"
    vtkMatrix4x4 flip2
    flip2 SetElement 1 1 -1
    $_xform Concatenate flip2

    if {0} {
        puts "isvolume SCAN_ORDER = $ScanOrder"
        puts "isvolume ORIENT =  $itk_option(-orientation)"
        puts "isvolume::ijk_to_ras [ijk_to_ras Print]"
        puts "isvolume::transformmatrix [transformmatrix Print]"
        puts "isvolume::ras_to_orient [ras_to_orient Print]"
        puts "isvolume::_xform [$_xform Print]"
    }

    ijk_to_ras Delete
    transformmatrix Delete
    ras_to_orient Delete
    flip Delete
    flip2 Delete

    $_reslice SetResliceTransform $_xform 
    $_resliceST SetResliceTransform $_xform 
    
}


# ------------------------------------------------------------------

itcl::body isvolume::screensave { filename {imagetype "PNM"} } {
# TODO should be moved to superclass

    set wif ::wif_$_name
    set imgw ::imgw_$_name
    catch "$wif Delete"
    catch "$imgw Delete"

    vtkWindowToImageFilter $wif 
    $wif SetInput [[$this tkrw] GetRenderWindow]

    switch $imagetype {
        "PNM" - "PPM" {
            vtkPNMWriter $imgw 
        }
        "JPG" - "JPEG" {
            vtkJPEGWriter $imgw 
        }
        "BMP" {
            vtkBMPWriter $imgw 
        }
        "PS" - "PostScript" - "postscript" {
            vtkPostScriptWriter $imgw 
        }
        "TIF" - "TIFF" {
            vtkTIFFWriter $imgw 
        }
        "PNG" {
            vtkPNGWriter $imgw 
        }
        default {
            error "unknown image format $imagetype; options are PNM, JPG, BMP, PS, TIFF, PNG"
        }
    }
        
    $imgw SetInput [$wif GetOutput]
    $imgw SetFileName $filename
    $imgw Write

    $imgw Delete
    $wif Delete
} 

# ------------------------------------------------------------------

itcl::body isvolume::slicer_volume { {name ""} {label_map "false"} } {

    if { [info command MainMrmlAddNode] == "" } {
        error "cannot create slicer volume outside of slicer"
    }

    if { $itk_option(-tensor) == "true" } {
        return [$this slicer_tensor $name]
    }

    # add a mrml node
    set n [MainMrmlAddNode Volume]
    set i [$n GetID]
    MainVolumesCreate $i
    
    # find a name for the image data that hasn't been taken yet
    while {1} {
        set id id_$_name$_volume_serial
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
    # need to construct a volume from the slicer output
    # - make sagittal so we can flip the X axis by specifying
    #   RL instead of LR
    # - then copy the image data
    # - then set up the volume node parameters and make it visible in slicer
    #
    
    $this transform_update
    $_reslice Update

    vtkImageData $id
    eval [$this imagedata] SetUpdateExtent [[$this imagedata] GetWholeExtent]
    [$this imagedata] Update
    $id DeepCopy [$this imagedata]

    ::Volume($i,node) SetNumScalars 1
    ::Volume($i,node) SetScalarType [$id GetScalarType]

    eval ::Volume($i,node) SetSpacing [$id GetSpacing]
    
    ::Volume($i,node) SetScanOrder $itk_option(-orientation)
    ::Volume($i,node) SetDimensions [lindex [$id GetDimensions] 0] [lindex [$id GetDimensions] 1]
    ::Volume($i,node) SetImageRange 1 [lindex $_dimensions 2]

    if { $label_map != "false" } {
        ::Volume($i,node) SetLabelMap 1
    }

    
    ::Volume($i,node) ComputeRasToIjkFromScanOrder [::Volume($i,node) GetScanOrder]
    Volume($i,vol) SetImageData $id
    MainUpdateMRML

    Slicer SetOffset 0 0
    MainSlicesSetVolumeAll Back $i
    RenderAll

    return $i


}

itcl::body isvolume::slicer_tensor { {name ""} } {

    if { [info command MainMrmlAddNode] == "" } {
        error "cannot create slicer volume outside of slicer"
    }

    # find a name for the image data that hasn't been taken yet
    while {1} {
        set id id_$_name$_volume_serial
        if { [info command $id] == "" } {
            break ;# found a free name
        } else {
            incr _volume_serial ;# need to try again
        }
    }

    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol SetDescription "transformed DTMRI volume"
    $newvol SetName $name
    set t2 [$newvol GetID]
    
    TensorCreateNew $t2 

    # set the name and description of the volume
    if { $name == "" } { 
        $newvol SetName isvolume-$_volume_serial
    } else {
        $newvol SetName $name
    }
    $newvol SetDescription "Resampled volume"
    incr _volume_serial

    $this transform_update
    $_reslice Update

    vtkImageData $id
    eval [$this imagedata] SetUpdateExtent [[$this imagedata] GetWholeExtent]
    [$this imagedata] Update
    $id DeepCopy [$this imagedata]

    $newvol SetNumScalars 1
    $newvol SetScalarType [$id GetScalarType]

    eval $newvol SetSpacing [$id GetSpacing]
    
    $newvol SetScanOrder $itk_option(-orientation)
    $newvol SetDimensions [lindex [$id GetDimensions] 0] [lindex [$id GetDimensions] 1]
    $newvol SetImageRange 1 [lindex $_dimensions 2]

    $newvol SetLabelMap 0
    
    Tensor($t2,data) SetImageData $id

    MainUpdateMRML
    DTMRISetActive $t2

    return $t2


}

# ------------------------------------------------------------------

itcl::body isvolume::set_spacing  {spacingI spacingJ spacingK} {
    set _spacing [list $spacingI $spacingJ $spacingK]

    $_reslice SetOutputSpacing $spacingI $spacingJ $spacingK
}

# ------------------------------------------------------------------
itcl::body isvolume::set_dimensions  {dimensionI dimensionJ dimensionK} {
    set _dimensions [list $dimensionI $dimensionJ $dimensionK]

    set opos [expr ([$this cget -slice] * 1.0) / [$_slider cget -to] ]

    $_reslice SetOutputExtent 0 [expr $dimensionI - 1]\
        0 [expr $dimensionJ - 1]\
        0 [expr $dimensionK - 1] 

    $_slider configure -from 0
    $_slider configure -to $dimensionK
    $this configure -slice [expr round( $opos * $dimensionK)]
    $_tkrw configure -width $dimensionI -height $dimensionJ
}

# ------------------------------------------------------------------
# use this method to clean up the vtk class instances before calling
# the destructor -- this is a hack to deal with improper cleanup of the vtk
# render windows and vtkTkRenderWidget

itcl::body isvolume::pre_destroy {} {
    if { $::tcl_platform(platform) != "windows" } {
        $_renwin Delete
    }
    destroy $_tkrw 
    $_ren Delete
    $_mapper Delete
    $_actor Delete

    set _renwin ""
    set _tkrw  ""
    set _ren  ""
    set _mapper ""
    set _actor ""
}


#-------------------------------------------------------------------------------
# .PROC isvolume_demo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc isvolume_demo {} {

    catch "destroy .isvolumedemo"
    toplevel .isvolumedemo
    wm title .isvolumedemo "isvolume demo"
    #wm geometry .isvolumedemo 400x700

    pack [isvolume .isvolumedemo.isv] -fill both -expand true
    [.isvolumedemo.isv controls] toggle

    if { [lsearch $::Module(idList) iSlicer] == -1 } {
        lappend ::Module(idList) iSlicer
        set ::Module(iSlicer,procMRML) iSlicerUpdateMRML
    }
}

#-------------------------------------------------------------------------------
# .PROC iSlicerUpdateMRML
# Call volmenu_update for each isvolume instance.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc iSlicerUpdateMRML {} {
    
    foreach isv [itcl::find objects -class isvolume] {
        $isv transform_update
        $isv volmenu_update
        $isv expose
    }
}

#-------------------------------------------------------------------------------
# .PROC isvolume_transform_test
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc isvolume_transform_test {} {

    lappend ::Module(idList) iSlicer
    set ::Module(iSlicer,procMRML) iSlicerUpdateMRML
}



