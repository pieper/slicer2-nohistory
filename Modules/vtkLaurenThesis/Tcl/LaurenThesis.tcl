#=auto==========================================================================
#   Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: LaurenThesis.tcl,v $
#   Date:      $Date: 2008/03/14 19:18:02 $
#   Version:   $Revision: 1.3 $
# 
#===============================================================================
# FILE:        LaurenThesis.tcl
# PROCEDURES:  
#   LaurenThesisInit
#   LaurenThesisBuildGUI
#   PrintVolumeNamesAndIDs
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC LaurenThesisInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisInit {} {
    global LaurenThesis Module Volume Model

    set m LaurenThesis

    set Module($m,overview) "Temporary module with code for users for Lauren O'Donnell's thesis"
    set Module($m,author) "Lauren O'Donnell MIT CSAIL"

    set Module($m,category) "Example"

    set Module($m,row1List) "Help SeedBrain ProbeClusters ColorROI ROISelect TractInfo"
    set Module($m,row1Name) "Help SeedBrain ProbeClusters ColorROI ROISelect TractInfo"

    set Module($m,row1,tab) SeedBrain

    set Module($m,procMRML) LaurenThesisUpdateMRML

    set Module($m,procGUI) LaurenThesisBuildGUI

    set Module($m,procEnter) LaurenThesisEnter


    set Module($m,depend) ""


    lappend Module(versions) [ParseCVSInfo $m \
                                  {$Revision: 1.3 $} {$Date: 2008/03/14 19:18:02 $}]

    # Initialize module-level variables
    #------------------------------------
    set LaurenThesis(submodules) {Help SeedBrain ProbeClusters ColorROI ROISelect TractInfo}

    foreach submodule $LaurenThesis(submodules) {
        source "$::env(SLICER_HOME)/Modules/vtkLaurenThesis/Tcl/LaurenThesis$submodule.tcl"

        # call initialization procedure if it exists
        catch {LaurenThesis${submodule}Init}
    }
}


#-------------------------------------------------------------------------------
# .PROC LaurenThesisBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc LaurenThesisBuildGUI {} {
    global Gui LaurenThesis Module Volume Model
    
    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # SeedBrain
    # ProbeClusterss
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    
    LaurenThesisHelpBuildGUI

    #-------------------------------------------
    # SeedBrain frame
    #-------------------------------------------
    
    LaurenThesisSeedBrainBuildGUI

    #-------------------------------------------
    # ProbeClusters frame
    #-------------------------------------------
    
    LaurenThesisProbeClustersBuildGUI

    #-------------------------------------------
    # ColorROI frame
    #-------------------------------------------
    
    LaurenThesisColorROIBuildGUI

    #-------------------------------------------
    # ROISelect frame
    #-------------------------------------------
    
    LaurenThesisROISelectBuildGUI

    #-------------------------------------------
    # TractInfo frame
    #-------------------------------------------
    
    LaurenThesisTractInfoBuildGUI
    
}




proc LaurenThesisUpdateMRML {} {
    
    global LaurenThesis

    foreach submodule $LaurenThesis(submodules) {

        if {$::Module(verbose)} {
            puts "LaurenThesisUpdateMRML: calling LaurenThesis${submodule}UpdateMRML"
        } 

        catch LaurenThesis${submodule}UpdateMRML

    }
}

proc LaurenThesisEnter {} {
    
    global LaurenThesis

    foreach submodule $LaurenThesis(submodules) {

        catch LaurenThesis${submodule}Enter

    }
}


#-------------------------------------------------------------------------------
# .PROC PrintVolumeNamesAndIDs
# Convenient, prints info to the tkcon.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc PrintVolumeNamesAndIDs {}  {
    
    global Volume Tensor

    puts "----- VOLUMES ----"
    foreach  v $Volume(idList) {
        puts "$v: [Volume($v,node) GetName]"
    }

    puts "----- TENSORS ----"
    foreach  t $Tensor(idList) {
        puts "$t: [Tensor($t,node) GetName]"
    }
}

