#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: iscomm.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:08 $
#   Version:   $Revision: 1.5 $
# 
#===============================================================================
# FILE:        iscomm.tcl
# PROCEDURES:  
#   iscomm_demo
#==========================================================================auto=



#########################################################
#
if {0} { ;# comment

iscomm - a class for sending vtk objects between slicer instances

note: this isn't a widget

Uses vtkTclHelper, currently compiled in vtkQueryAtlas package

# TODO : 

}
#
#########################################################


#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class iscomm] == "" } {

    itcl::class iscomm {

      constructor {args} {}
      destructor {}

      # configure options
      public variable port 18943  ;# an arbitrary, but "well known" (to iscomm) starting port
      public variable local 1  ;# do (0) or don't (1) accept remote connections

      variable _name
      variable _tcl
      variable _channel ""

      # client methods
      method GetImageData { remotename localname } {}
      method SendImageDataScalars { name } {}
      method RecvImageDataScalars { name } {}

      # server methods
      method accept {chan fid addr remport} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body iscomm::constructor {args} {

    # uses the comm package that is part of the tcllib
    if { [catch "package require comm"] } {
        error "iscomm doesn't work without the tcllib comm package"
    }

    if { [catch "package require vtkQueryAtlas"] } {
        error "iscomm doesn't work without the tcllib vtkQueryAtlas package"
    }

    # make a unique name associated with this object
    set _name [namespace tail $this]

    # create a tcl helper that will copy vtk binary data into 
    # tcl variables and channels
    set _tcl ::tcl_$_name
    vtkTclHelper $_tcl

    # special trick to let the tcl helper know what interp to use
    set tag [$_tcl AddObserver ModifiedEvent ""]
    $_tcl SetInterpFromCommand $tag


    # create a listening channel for the server
    if { [lindex $args 0] == "server" } {
        set _channel [::comm::comm new ::channel_$_name -port $port -local $local -listen 1]
        ::comm::comm hook incoming "$this accept \$chan \$fid \$addr \$remport"
    }
}


itcl::body iscomm::destructor {} {
    
    catch "$_tcl Delete"
    if { $_channel != "" } {
        $_channel destroy
    }
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# OPTION: -port
#
# DESCRIPTION: set the port for this connection
#-------------------------------------------------------------------------------
itcl::configbody iscomm::port {
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------


itcl::body iscomm::GetImageData { remotename localname } {

    vtkImageData $localname
    eval $localname SetDimensions [::comm::comm send $port "$remotename GetDimensions"]
    eval $localname SetScalarType [::comm::comm send $port "$remotename GetScalarType"]
    eval $localname SetNumberOfScalarComponents [::comm::comm send $port "$remotename GetNumberOfScalarComponents"]
    $localname AllocateScalars
    ::comm::comm send $port "c SendImageDataScalars $remotename"
    $this RecvImageDataScalars $localname

    ::comm::comm send $port "puts hoot"
} 

itcl::body iscomm::SendImageDataScalars { name } {
    set sock [::comm::comm configure -socket]
    $_tcl SetImageData $name
    $_tcl SendImageDataScalars $sock 
} 

itcl::body iscomm::RecvImageDataScalars { name } {
    set sock [::comm::comm configure -socket]
    $_tcl SetImageData $name
    $_tcl RecvImageDataScalars $sock 
} 

itcl::body iscomm::accept { chan fid addr remport } {
    
    puts "accept $chan $fid $addr $remport"
}

# ------------------------------------------------------------------
#                             DEMOS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC iscomm_demo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc iscomm_demo { {mode "server"} } {

    # create an iscomm instance named 'c'
    catch {itcl::delete object c }
    iscomm c $mode

    switch $mode {
        "server" {
            # we are sitting waiting for requests

            # create a simple image data that the client can ask for
            catch "e Delete"
            vtkImageData e
            catch "es Delete"
            vtkImageEllipsoidSource es
            es SetOutput e
            e Update
        }
        "client" {
            catch "es Delete"
            c GetImageData e ecopy

            puts "Got ecopy"
            puts [ecopy Print]
        }
    }
} 


