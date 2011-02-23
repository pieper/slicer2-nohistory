#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: tclVectorUtils.tcl,v $
#   Date:      $Date: 2006/01/06 17:57:06 $
#   Version:   $Revision: 1.6 $
# 
#===============================================================================
# FILE:        tclVectorUtils.tcl
# PROCEDURES:  
#==========================================================================auto=
package provide tclVectorUtils 1.0

namespace eval tclVectorUtils {
    proc VCross {a b} {
        foreach {a0 a1 a2} $a {}
        foreach {b0 b1 b2} $b {}

        return [list [expr {$a1*$b2 - $a2*$b1}] \
               [expr {$a2*$b0 - $a0*$b2}] \
               [expr {$a0*$b1 - $a1*$b0}]]
    }

    proc VDist {a b} {
        foreach {a0 a1 a2} $a {}
        foreach {b0 b1 b2} $b {}
        return [expr {sqrt(pow($a0-$b0,2) + pow($a1-$b1,2) + pow($a2-$b2,2))}]
    }

    proc VScale {s v} {
        foreach {v0 v1 v2} $v {}
        return [list [expr {$s*$v0}] [expr {$s*$v1}] [expr {$s*$v2}]]
    }

    proc VAdd {a b} {
        foreach {a0 a1 a2} $a {}
        foreach {b0 b1 b2} $b {}

        return [list [expr {$a0+$b0}] [expr {$a1+$b1}] [expr {$a2+$b2}]]
    }

    proc VLen {a} {
        foreach {a0 a1 a2} $a {}

        # length is caculated by sqrt(vx*vx + vy*vy + vz*vz), the following
        # line squares the vector elements a second time by using pow
        # return [expr {sqrt(pow($a0*$a0,2) + pow($a1*$a1,2) + pow($a2*$a2,2))}]
        return [expr {sqrt($a0*$a0 + $a1*$a1 + $a2*$a2)}]
    }

    proc VSub {a b} {
        foreach {a0 a1 a2} $a {}
        foreach {b0 b1 b2} $b {}

        return [list [expr {$a0-$b0}] [expr {$a1-$b1}] [expr {$a2-$b2}]]
    }

    proc VNorm {a} {
        set len [VLen $a]
        return [VScale [expr {1.0/$len}] $a]
    }

    namespace export VAdd VSub VScale VCross VNorm
}
