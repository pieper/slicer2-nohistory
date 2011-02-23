#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: ismodel.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:08 $
#   Version:   $Revision: 1.4 $
# 
#===============================================================================
# FILE:        ismodel.tcl
# PROCEDURES:  
#==========================================================================auto=

# TODO - won't be needed once iSlicer is a package
package require Itcl


#########################################################
#
if {0} { ;# comment

ismodel - a class for managing a model (includes polydata, 
    mapper, texture, and actor)

note: this isn't a widget

# TODO : 
    - almost everything

}
#
#########################################################


#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class ismodel] == "" } {

    itcl::class ismodel {

      constructor {args} {}
      destructor {}

      # configure options
      public variable color ".5 .5 .5" 

      variable _name

      # vtk objects for the model
      variable _polydata
      variable _texture
      variable _mapper
      variable _actor

      ### methods

      # accessors
      method actor {} {return $_actor}
      method texture {} {return $_texture}
      method mapper {} {return $_mapper}
      method polydata {} {return $_polydata}

      # manipulators

      # polydata loaders
      method sphere {} {}
      method cylinder { {center "0 0 0"} {radius 0.5} } {}
      method plane { {cx 0} {cy 0} {size 1} {aspect ""} } {}
      method subplane { {cx 0.5} {cy 0.5} {w 0.5} {h 0.5} } {}
      method loadvtk { vtkfile } {}
      method loadobj { objfile } {}

      # texture loaders
      method loadbmp { bmpfile } {}
      method loadppm { ppmfile } {}
      method loadphoto { filename } {}

      # polydata saver
      method savevtk { vtkfile } {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body ismodel::constructor {args} {

    # make a unique name associated with this object
    set _name [namespace tail $this]
    # remove dots from name so it can be used in widget names
    regsub -all {\.} $_name "_" _name


    set _polydata ::polydata_$_name
    set _texture ::texture_$_name
    set _mapper ::mapper_$_name
    set _actor ::actor_$_name
    catch "$_polydata Delete"
    catch "$_texture Delete"
    catch "$_mapper Delete"
    catch "$_actor Delete"

    vtkPolyData $_polydata
    vtkTexture $_texture
    vtkPolyDataMapper $_mapper
    vtkActor $_actor

    $_mapper SetInput $_polydata
    $_actor SetMapper $_mapper
    $_actor SetTexture $_texture
    $_texture SetInterpolate 1

}


itcl::body ismodel::destructor {} {
    catch "$_polydata Delete"
    catch "$_texture Delete"
    catch "$_mapper Delete"
    catch "$_actor Delete"
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# OPTION: -color
#
# DESCRIPTION: diffuse color of the actor
#-------------------------------------------------------------------------------
itcl::configbody ismodel::color {

    if { [llength $color] != 3 } {
        error "bad color spec $color"
        set color ".5 .5 .5"
    }

    [$_actor GetProperty] SetDiffuseColor [lindex $color 0] [lindex $color 1] [lindex $color 2]
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------


# fill the polydata with a cylinder
itcl::body ismodel::cylinder { {center "0 0 0"} {radius 0.5} } {

    set c ::cyl_$_name
    catch "$c Delete"

    vtkCylinderSource $c
    $c SetRadius $radius
    eval $c SetCenter $center
    $c SetOutput $_polydata
    $c Update
    $c SetOutput ""
    $c Delete
} 

# fill the polydata with a sphere
itcl::body ismodel::sphere { } {

    set s ::sphere_$_name
    catch "$s Delete"

    vtkSphereSource $s
    $s SetOutput $_polydata
    $s Update
    $s SetOutput ""
    $s Delete
} 

# fill the polydata with a plane - use texture dimensions if loaded
# - offset position to cx,cy
# - make the plane width be of size 
#
itcl::body ismodel::plane { {cx 0} {cy 0} {size 1} {aspect ""} } {

    set p ::plane_$_name
    catch "$p Delete"

    vtkPlaneSource $p
    set id [$_texture GetInput]
    if { $id != "" } {
        $id Update
        if { $aspect == "" } {
            foreach "xx yy zz" [$id GetDimensions] {}
            set aspect [expr (1.0 * $xx) / $yy]
        }
        set halfwidth [expr 0.5 * $size]
        set halfheight [expr $halfwidth / $aspect]
        $p SetOrigin [expr $cx + $halfwidth] [expr $cy - $halfheight] 0
        $p SetPoint1 [expr $cx - $halfwidth] [expr $cy - $halfheight] 0
        $p SetPoint2 [expr $cx + $halfwidth] [expr $cy + $halfheight] 0
    }

    $p SetOutput $_polydata
    $p Update
    $p SetOutput ""
    $p Delete
    return $aspect
} 

# 
# set the texture coordinates to look at just a subplane of the texture image
# center at cx,cy from 0 to 1 and of normalized dimenions w x h
#
itcl::body ismodel::subplane { {cx 0.5} {cy 0.5} {w 0.5} {h 0.5} } {

    if { [$_polydata GetNumberOfPoints] != 4 } {
        error "bad polydata"
        return
    }
    set pd [$_polydata GetPointData]
    set tc [$pd GetTCoords]

    $tc SetTuple2 0 [expr $cx - 0.5 * $w] [expr $cy - 0.5 * $h]
    $tc SetTuple2 1 [expr $cx + 0.5 * $w] [expr $cy - 0.5 * $h]
    $tc SetTuple2 2 [expr $cx - 0.5 * $w] [expr $cy + 0.5 * $h]
    $tc SetTuple2 3 [expr $cx + 0.5 * $w] [expr $cy + 0.5 * $h]

    $_polydata Modified
} 

itcl::body ismodel::loadvtk { vtkfile } {

    set r ::prd_$_name
    catch "$r Delete"

    vtkPolyDataReader $r
    $r SetFileName $vtkfile
    $r SetOutput $_polydata
    $r Update
    $r SetOutput ""
    $r Delete
} 


itcl::body ismodel::loadobj { objfile } {

    #
    # need to read in two passes
    # - first to count verts and faces
    # - second to fill in data structures
    #
    set fpo [open $objfile "r"]
    set vcount 0
    set fcount 0
    # keep track of smallest face index along the way
    set minindex 999999
    while {![eof $fpo]} {
        gets $fpo line
        switch -glob $line {
            "v *" {
                incr vcount
            }
            "f*" {
                incr fcount 

                set ll [string trimleft $line "f "]
                foreach v $ll {
                    scan $v "%d" i
                    if { $i < $minindex } {
                        set minindex $i
                    }
                }
            }
        }
    }
    close $fpo

    set fpo [open $objfile "r"]
    puts "found $vcount verts and $fcount faces"

    set t ::tcoords_$_name
    catch "$t Delete"
    vtkFloatArray  $t
    $t Initialize
    $t SetNumberOfComponents 2

    set pts ::pts_$_name
    catch "$pts Delete"
    vtkPoints  $pts
    $pts Initialize

    set polys ::polys_$_name
    catch "$polys Delete"
    vtkCellArray $polys
    $polys Initialize

    while {![eof $fpo]} {
        gets $fpo line
        switch -glob $line {
            "v *" {
                set ll [string trimleft $line "v "]
                eval $pts InsertNextPoint $ll
            }
            "vt *" {
                set ll [string trimleft $line "vt "]
                set ll [lrange $ll 0 1]
                eval $t InsertNextTuple2 $ll
            }
            "f*" {
                set ll [string trimleft $line "f "]
                $polys InsertNextCell [llength $ll]
                foreach v $ll {
                    scan $v "%d" i
                    $polys InsertCellPoint [expr $i - $minindex]
                }
            }
        }
    }
    close $fpo

    $pts Modified
    $polys Modified

    $_polydata SetPoints $pts
    $_polydata SetPolys $polys
    [$_polydata GetPointData] SetTCoords $t
    catch "$t Delete"
    catch "$pts Delete"
    catch "$polys Delete"
} 

itcl::body ismodel::loadbmp { bmpfile } {
    
    set bmpr ::bmpr_$_name
    catch "$bmpr Delete"
    vtkBMPReader  $bmpr
    $bmpr SetFileName $bmpfile
    
    $_texture SetInput [$bmpr GetOutput]
    $bmpr Update
    $bmpr SetOutput ""
    $bmpr Delete
} 

itcl::body ismodel::loadppm { ppmfile } {
    
    set ppmr ::ppmr_$_name
    catch "$ppmr Delete"
    vtkPNMReader  $ppmr
    $ppmr SetFileName $ppmfile
    
    $_texture SetInput [$ppmr GetOutput]
    $ppmr Update
    $ppmr SetOutput ""
    $ppmr Delete
} 

itcl::body ismodel::loadphoto { filename } {
    
    set ireader ::ireader_$_name
    catch "$ireader Delete"

    catch "$ireader Delete"
    switch [string toupper [file extension $filename]] {
        ".PNM" - ".PPM" {
            vtkPNMReader $ireader
        }
        ".JPG" - ".JPEG" {
            vtkJPEGReader $ireader
        }
        ".BMP" {
            vtkBMPReader $ireader
        }
        ".PS" - ".POSTSCRIPt" {
            vtkPostScriptReader $ireader
        }
        ".TIF" - ".TIFF" {
            vtkTIFFReader $ireader
        }
        ".PNG" {
            vtkPNGReader $ireader
        }
        default {
            error "unknown image format for $filename: options are PNM, JPG, BMP, PS, TIFF, PNG"
        }
    }

    $ireader SetFileName $filename
    
    $_texture SetInput [$ireader GetOutput]
    $ireader Update
    $ireader SetOutput ""
    $ireader Delete
} 

itcl::body ismodel::savevtk { vtkfile } {

    set w ::prw_$_name
    catch "$w Delete"

    vtkPolyDataWriter $w
    $w SetFileName $vtkfile
    $w SetInput $_polydata
    $w Write
    $w SetInput ""
    $w Delete
} 

