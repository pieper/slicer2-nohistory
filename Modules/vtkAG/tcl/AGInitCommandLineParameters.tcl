#=auto==========================================================================
#   Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: AGInitCommandLineParameters.tcl,v $
#   Date:      $Date: 2006/03/20 12:26:18 $
#   Version:   $Revision: 1.1 $
# 
#===============================================================================
# FILE:        AGInitCommandLineParameters.tcl
# PROCEDURES:  
#   AGInitCommandLineParameters
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC AGInitCommandLineParameters
# Set the parameters for the AG-registration module, when called from
# command-line.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc AGInitCommandLineParameters {} {
  global AG Volume

    set AG(TestReadingWriting) 0   
    set AG(CountNewResults) 1
    set AG(InputVolSource2) $Volume(idNone)
    set AG(InputVolTarget2) $Volume(idNone)

    set AG(InputVolSource)  $Volume(idNone)
    set AG(InputVolTarget)  $Volume(idNone)
    set AG(InputVolMask)    $Volume(idNone)
    set AG(ResultVol)       -5
    set AG(ResultVol2)      $Volume(idNone)
    set AG(CoregVol)        $Volume(idNone)

    #General options

# set AG(DEBUG) to 1 to display more information.
    set AG(Debug) 1
   
    set AG(Linear)    "1"
    set AG(Warp)      "1"
    set AG(Verbose)  "2"
    set AG(Scale)    "-1"
    set AG(2D)        "0"
    
    #GCR options
    set AG(Linear_group)  "2"
    set AG(Gcr_criterion) "1"
   
    # Initial Transform options
    set AG(Initial_tfm) "0"
    set AG(Initial_lin)  "0"
    set AG(Initial_grid) "0"
    set AG(Initial_prev) "0"
    set AG(Initial_lintxt) "Off"
    set AG(Initial_gridtxt) "Off"
    set AG(Initial_prevtxt) "Off"

    #Demons options
    set AG(Tensors)  "0"
    set AG(Interpolation) "1"
    set AG(Iteration_min) "15"
    set AG(Iteration_max)  "50"
    set AG(Level_min)  "-1"
    set AG(Level_max)  "-1"
    set AG(Epsilon)    "1e-4"
    set AG(Stddev_min) "0.85"
    # [expr sqrt(-1./(2.*log(.5)))] = 0.85
    set AG(Stddev_max) "1"
    set AG(SSD)    "1" 

   #Intensity correction

    set AG(Intensity_tfm) "mono-functional"   
    set AG(Force)   "1"
    set AG(Degree)   1
    set AG(Ratio)    1
    set AG(Nb_of_functions)  1
    set AG(Nb_of_pieces)    {}
    set AG(Use_bias)        0
    set AG(Boundaries)      {}
}
