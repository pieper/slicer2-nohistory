#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: Endoscopic.tcl,v $
#   Date:      $Date: 2006/01/06 17:56:58 $
#   Version:   $Revision: 1.103 $
# 
#===============================================================================
# FILE:        Endoscopic.tcl
# PROCEDURES:  
#   EndoscopicEnter
#   EndoscopicExit
#   EndoscopicInit
#   EndoscopicCreateRenderer renName
#   EndoscopicBuildVTK
#   EndoscopicCreateCamera
#   EndoscopicCameraParams size
#   EndoscopicCreateFocalPoint
#   EndoscopicCreateVTKPath id
#   EndoscopicResetPathVariables id
#   EndoscopicCreatePath id
#   EndoscopicCreateVector id
#   EndoscopicVectorParams id axislen axisrad conelen
#   EndoscopicUpdateVisibility a visibility
#   EndoscopicSetPickable a pickability
#   EndoscopicUpdateSize a
#   EndoscopicPopBindings
#   EndoscopicPushBindings
#   EndoscopicCreateBindings
#   EndoscopicBuildGUI
#   EndoscopicShowFlyThroughPopUp x y
#   EndoscopicExecutePathTab  command
#   EndoscopicBuildFlyThroughGUI
#   EndoscopicCreateLabelAndSlider f labelName labelHeight labelText sliderName orient from to length variable commandString entryWidth defaultSliderValue
#   EndoscopicCreateCheckButton ButtonName VariableName Message Command Indicatoron Width
#   EndoscopicSetVisibility a
#   EndoscopicCreateAdvancedGUI f a vis col size
#   EndoscopicSetActive a b
#   EndoscopicPopupCallback
#   EndoscopicUseGyro
#   EndoscopicGyroMotion actor angle dotprod unitX unitY unitZ
#   EndoscopicSetGyroOrientation
#   EndoscopicSetWorldPosition x y z
#   EndoscopicSetWorldOrientation rx ry rz
#   EndoscopicSetCameraPosition value
#   EndoscopicResetCameraPosition
#   EndoscopicSetCameraDirection value
#   EndoscopicResetCameraDirection
#   EndoscopicUpdateActorFromVirtualEndoscope vcam
#   EndoscopicUpdateVirtualEndoscope  vcam coordList
#   EndoscopicLightFollowEndoCamera vcam
#   EndoscopicSetCameraZoom
#   EndoscopicSetCameraViewAngle
#   EndoscopicSetCameraAxis axis
#   EndoscopicCameraMotionFromUser
#   EndoscopicSetCollision value
#   EndoscopicMoveGyroToLandmark id
#   EndoscopicUpdateVectors id
#   EndoscopicGetAvailableListName model
#   EndoscopicAddLandmarkNoDirectionSpecified x y z list
#   EndoscopicInsertLandmarkNoDirectionSpecified afterPid x y z list
#   EndoscopicAddLandmarkDirectionSpecified coords list
#   EndoscopicInsertLandmarkDirectionSpecified coords list
#   EndoscopicUpdateLandmark
#   EndoscopicBuildInterpolatedPath id
#   EndoscopicDeletePath
#   EndoscopicComputeRandomPath
#   EndoscopicShowPath
#   EndoscopicFlyThroughPath listOfCams listOfPaths
#   EndoscopicSetPathFrame listOfCams listOfPaths
#   EndoscopicStopPath
#   EndoscopicResetStopPath
#   EndoscopicResetPath listOfCams listOfPaths
#   EndoscopicSetSpeed
#   EndoscopicCheckDriver vcam
#   EndoscopicReformatSlices vcam x y z
#   EndoscopicSetSliceDriver name
#   EndoscopicFiducialsPointSelectedCallback fid pid
#   EndoscopicFiducialsPointCreatedCallback type fid pid
#   EndoscopicUpdateMRML
#   EndoscopicStartCallbackFiducialsUpdateMRML
#   EndoscopicEndCallbackFiducialsUpdateMRML
#   EndoscopicCallbackFiducialsUpdateMRML type id listOfPoints
#   EndoscopicCreateAndActivatePath name
#   EndoscopicFiducialsActivatedListCallback type name id
#   EndoscopicSelectActivePath id
#   EndoscopicDistanceBetweenTwoPoints p1x p1y p1z p2x p2y p2z
#   EndoscopicUpdateSelectionLandmarkList id
#   EndoscopicSetModelsVisibilityInside
#   EndoscopicSetSlicesVisibility
#   EndoscopicUpdateEndoscopicViewVisibility
#   EndoscopicUpdateMainViewVisibility
#   EndoscopicAddEndoscopicView
#   EndoscopicAddMainView
#   EndoscopicAddEndoscopicViewRemoveMainView
#   EndoscopicRemoveEndoscopicView
#   EndoscopicRemoveMainView
#   EndoscopicAddMainViewRemoveEndoscopicView
#   EndoscopicAutoSelectSourceSink list
#   EndoscopicSetFlatFileName
#   EndoscopicCancelFlatFile
#   EndoscopicAddFlatView
#   EndoscopicRemoveFlatView name
#   EndoscopicCreateFlatBindings widget
#   EndoscopicPopFlatBindings
#   EndoscopicBuildFlatColonLookupTable name
#   EndoscopicBuildFlatBoundary name
#   EndoscopicMouseLocation widget xcoord ycoord
#   EndoscopicStartPan widget xcoord ycoord
#   EndoscopicEndPan widget xcoord ycoord
#   EndoscopicStartZoom widget ycoord
#   EndoscopicEndZoom widget ycoord
#   EndoscopicPickFlatPoint widget xcoord ycoord
#   EndoscopicAddTargetInFlatWindow widget x y z
#   EndoscopicAddTargetFromFlatColon pointId
#   EndoscopicAddTargetFromSlices x y z
#   EndoscopicAddTargetFromWorldCoordinates sx sy sz
#   EndoscopicLoadTargets
#   EndoscopicMainFileCloseUpdated
#   EndoscopicCreateTarget
#   EndoscopicUpdateActiveTarget
#   EndoscopicDeleteActiveTarget
#   EndoscopicSelectTarget sT
#   EndoscopicSelectNextTarget
#   EndoscopicSelectPreviousTarget
#   EndoscopicUpdateTargetsInFlatWindow widget
#   EndoscopicFlatLightElevationAzimuth widget Endoscopic(flatColon,LightElev) Endoscopic(flatColon,LightAzi)
#   EndoscopicMoveCameraX widget Endoscopic(flatColon,xCamDist)
#   EndoscopicMoveCameraY widget Endoscopic(flatColon,yCamDist)
#   EndoscopicMoveCameraZ widget Endoscopic(flatColon,zCamDist)
#   EndoscopicResetFlatCameraDist widget
#   EndoscopicScrollRightFlatColon widget
#   EndoscopicScrollLeftFlatColon widget
#   EndoscopicStopFlatColon
#   EndoscopicResetFlatColon widget
#   EndoscopicResetStop
#   EndoscopicSetFlatColonScalarVisibility widget
#   EndoscopicSetFlatColonScalarRange widget
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC EndoscopicEnter
# Called when this module is entered by the user.<br>
# Effects: Pushes the event manager for this module and 
#          calls EndoscopicAddEndoscopicView. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicEnter {} {
    global Endoscopic View viewWin viewRen Fiducials Csys
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)

    # push initial bindings
    EndoscopicPushBindings
    

    # show the actors based on their visibility parameter
    #foreach a $Endoscopic(actors) {
    #EndoscopicUpdateVisibility $a
    #}
    foreach a $Endoscopic(actors) {
        viewRen AddActor $a
    EndoscopicSetPickable $a 1
    }
    set Csys(active) 1
    
    Render3D
    if {$Endoscopic(endoview,visibility) == 1} {
        EndoscopicAddEndoscopicView
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicExit
# Called when this module is exited by the user.<br>
#
# Removes the endo and/or the flat view if hide on exit flags are set.
# Pops the event manager for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicExit {} {
    global Endoscopic Csys
    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    if {$Endoscopic(endoview,hideOnExit) == 1} {
        # reset the slice driver
        EndoscopicSetSliceDriver User
        
        # set all endoscopic actors to be invisible, without changing their 
        # visibility parameters
        foreach a $Endoscopic(actors) {
            viewRen RemoveActor $a
            EndoscopicSetPickable $a 0
                    
        }
        set Csys(active) 0
    
        Render3D
        EndoscopicRemoveEndoscopicView
    }
    
    if {$Endoscopic(flatview,hideOnExit) == 1} {
        EndoscopicRemoveFlatView
    }
    EndoscopicPopBindings
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicInit
#  The "Init" procedure is called automatically by the slicer.  
#  <br>
#
#  effects: * It puts information about the module into a global array called 
#             Module. <br>
#           * It adds a renderer called Endoscopic(activeCam) to the global array 
#             View and adds the new renderer to the list of renderers in 
#             Module(renderers) <br> 
#           * It also initializes module-level variables (in the global array 
#             Endoscopic and Path) <br>
#             The global array Endoscopic contains information about the 
#             7 actors created in this module (the list is saved in Endoscopic(actors): <br>
#        regular actors: <br>
#               cam: the endoscopic camera <br>
#               fp:  the focal point of cam <br>
#               gyro: the csys to move the cam actor
#        3D glyphs:       <br>
#               cPath: the camera path <br>
#               cLand: the landmarks on the camera Path <br>
#               vector: the view vector at every point on the spline <br>
#               fPath: the focal point path <br>
#               fLand: the landmarks on the focal point Path <br>
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicInit {} {
    global Endoscopic Module Model Path Advanced View Gui Fiducials
    

    set m Endoscopic
    set Module($m,row1List) "Help Display Camera Path"
    set Module($m,row1Name) "{Help} {Display} {Camera} {Path}"
    set Module($m,row1,tab) Path    
    set Module($m,row2List) "Advanced"
    set Module($m,row2Name) "{Advanced}"
    set Module($m,row2,tab) Advanced

    set Module($m,depend) ""
    
    # module summary
    set Module($m,overview) "Position an endoscopic camera in the scene and view through the camera's lens in the second window.
                Provides correspondence between 3D Views, 2D Slices, and flattened colon View"
    set Module($m,author) "Delphine Nain, MIT, delfin@ai.mit.edu; Jeanette Meng SPL meng@bwh.harvard.edu"
    set Module($m,category) "Visualisation"
    
    lappend Module(versions) [ParseCVSInfo $m \
    {$Revision: 1.103 $} {$Date: 2006/01/06 17:56:58 $}] 
       
    # Define Procedures
    #------------------------------------
    
    set Module($m,procVTK) EndoscopicBuildVTK
    set Module($m,procGUI) EndoscopicBuildGUI
    set Module($m,procCameraMotion) EndoscopicCameraMotionFromUser
    set Module($m,procXformMotion) EndoscopicGyroMotion
    set Module($m,procEnter) EndoscopicEnter
    set Module($m,procExit) EndoscopicExit
    set Module($m,procMRML) EndoscopicUpdateMRML

    # jeanette: reset endoscopic global variables
    set Module($m,procMainFileCloseUpdateEntered) EndoscopicMainFileCloseUpdated
    
    # callbacks so that the endoscopic module knows when things happen with the
    # fiducials
    lappend Module($m,fiducialsStartUpdateMRMLCallback) EndoscopicStartCallbackFiducialsUpdateMRML
    lappend Module($m,fiducialsEndUpdateMRMLCallback) EndoscopicEndCallbackFiducialsUpdateMRML
    lappend Module($m,fiducialsCallback) EndoscopicCallbackFiducialsUpdateMRML
    lappend Module($m,fiducialsPointSelectedCallback) EndoscopicFiducialsPointSelectedCallback
    lappend Module($m,fiducialsPointCreatedCallback) EndoscopicFiducialsPointCreatedCallback
    lappend Module($m,fiducialsActivatedListCallback) EndoscopicFiducialsActivatedListCallback
    
    # give a defaultList name for endoscopic Fiducials
    set Fiducials(Endoscopic,Path,defaultList) "path"


    # create a second renderer here in Init so that it is added to the list 
    # of Renderers before MainActorAdd is called anywhere
    # That way any actor added to viewRen (the MainView's renderer) is also 
    # added to endoscopicScreen and will appear on the second window once we decide 
    # to show it
    
    # by default we only know about this renderers, so add it to 
    # the list of the endoscopic renderers we care about

    #EndoscopicCreateRenderer endoscopicScreen2     
    #lappend Module(endoscopicRenderers) endoscopicScreen2
    EndoscopicCreateRenderer endoscopicScreen 
    lappend Module(endoscopicRenderers) endoscopicScreen
    
    
    set Endoscopic(activeCam) [endoscopicScreen GetActiveCamera]
    
    # create the second renderer now so that all things are initialized for
    # it
    # only add it to the list of endoscopic renderers we care about
    # once the user pressed the button in the Sync tab

    
    ### create bindings
    EndoscopicCreateBindings
    
    # Initialize module-level variables
    #------------------------------------
    
    set Endoscopic(count) 0
    set Endoscopic(eventManager)  ""
    set Endoscopic(actors) ""
    set Endoscopic(mbPathList) ""
    set Endoscopic(mPathList) ""
    set Endoscopic(plane,offset) 0      
    set Endoscopic(selectedFiducialPoint) ""
    set Endoscopic(selectedFiducialList) ""
    
    
            # jeanette Initialize flat-view variables
#--------------------------------------------------------------------------------    

    
    # names of the views/models selected
    set Endoscopic(ModelSelect) $Model(idNone)
    set Endoscopic(FlatSelect) ""
    set Endoscopic(flatColon,name) ""
    
    # keep lists of renderers and flatwindows that will be opened
    set Endoscopic(FlatRenderers) ""    
    set Endoscopic(FlatWindows) ""
    
    set Endoscopic(default,lineCount) 0
    
    # flat viewer
    set Endoscopic(RemoveEndo) 0
    
    set Flat(mbActiveList) ""
    set Flat(mActiveList) ""
    
    set Endoscopic(targetList,name) ""
    set Endoscopic(targetList,points) ""
    
    # bounding box parameters for the flat colon
    set Endoscopic(flatColon,xMin) 0.0
    set Endoscopic(flatColon,xMax) 0.0
    set Endoscopic(flatColon,yMin) 0.0 
    set Endoscopic(flatColon,yMax) 0.0
    set Endoscopic(flatColon,zMin) 0.0
    set Endoscopic(flatColon,zMax) 0.0
    
    set Endoscopic(flatColon,zOpt) 0.0
    set Endoscopic(flatColon,yMid) 0.0
    
    set Endoscopic(flatColon,xCamDist) 0.0
    set Endoscopic(flatColon,yCamDist) 5.0
#   trace add variable Endoscopic(flatColon,yCamDist) write EndoscopicTempProc
    set Endoscopic(flatColon,zCamDist) 5.0
    
    set Endoscopic(flatColon,speed) 0.5
    set Endoscopic(flatColon,stop) 0
    
    # lights
    set Endoscopic(flatColon,LightElev) 0
    set Endoscopic(flatColon,LightAzi) 0
    
    # flatcolon scalar visibility and range
    set Endoscopic(flatColon,scalarVisibility) 0
    set Endoscopic(flatColon,scalarLow) 0
    set Endoscopic(flatColon,scalarHigh) 100
    
    # number of targets
    set Endoscopic(totalTargets) 0
    set Endoscopic(selectedTarget) 0
        
#--------------------------------------------------------------------------------    


    set Endoscopic(Cameras) ""
    # path planning
    set Endoscopic(source,exists) 0
    set Endoscopic(sourceButton,on) 0
    set Endoscopic(sinkButton,on) 0

    # Camera variables
    # don't change these default values, change Endoscopic(cam,size) instead
    
    set Endoscopic(cam,name) "Camera"
    set Endoscopic(cam,visibility) 1    
    set Endoscopic(cam,size) 1
    set Endoscopic(cam,boxlength) 30
    set Endoscopic(cam,boxheight) 20
    set Endoscopic(cam,boxwidth)  10
    set Endoscopic(cam,x) 0
    set Endoscopic(cam,y) 0
    set Endoscopic(cam,z) 0
    set Endoscopic(cam,xRotation) 0
    set Endoscopic(cam,yRotation) 0
    set Endoscopic(cam,zRotation) 0
    set Endoscopic(cam,FPdistance) 30
    set Endoscopic(cam,viewAngle) 90
    set Endoscopic(cam,AngleStr) 90
    set Endoscopic(cam,viewUpX) 0 
    set Endoscopic(cam,viewUpY) 0 
    set Endoscopic(cam,viewUpZ) 1
    set Endoscopic(cam,viewPlaneNormalX) 0
    set Endoscopic(cam,viewPlaneNormalY) 1
    set Endoscopic(cam,viewPlaneNormalZ) 0
    set Endoscopic(cam,driver) 0
    set Endoscopic(cam,PathNode) ""
    set Endoscopic(cam,EndPathNode) ""
    set Endoscopic(cam,xStr) 0
    set Endoscopic(cam,yStr) 0
    set Endoscopic(cam,zStr) 0
    set Endoscopic(cam,xStr,old) 0
    set Endoscopic(cam,yStr,old) 0
    set Endoscopic(cam,zStr,old) 0
    set Endoscopic(cam,rxStr) 0
    set Endoscopic(cam,ryStr) 0
    set Endoscopic(cam,rzStr) 0
    set Endoscopic(cam,rxStr,old) 0
    set Endoscopic(cam,ryStr,old) 0
    set Endoscopic(cam,rzStr,old) 0

    set Endoscopic(sliderx) ""
    set Endoscopic(slidery) ""
    set Endoscopic(sliderz) ""
    set Endoscopic(Box,name) "Camera Box"
    set Endoscopic(Box,color) "1 .4 .5" 

    set Endoscopic(Lens,name) "Camera Lens"
    set Endoscopic(Lens,color) ".4 .2 .6" 

    set Endoscopic(fp,name) "Focal Point"    
    set Endoscopic(fp,visibility) 1    
    set Endoscopic(fp,size) 4
    set Endoscopic(fp,color) ".2 .6 .8"
    set Endoscopic(fp,x) 0
    set Endoscopic(fp,y) 30
    set Endoscopic(fp,z) 0
    set Endoscopic(fp,driver) 0

    set Endoscopic(intersection,driver) 0    
    set Endoscopic(intersection,x) 0    
    set Endoscopic(intersection,y) 0    
    set Endoscopic(intersection,z) 0    
    # if it is absolute, the camera will move along the 
    #  RA/IS/LR axis
    # if it is relative, the camera will move along its
    #  own axis 
    set Endoscopic(cam,axis) relative
    
    # Endoscopic variables
    


    set Endoscopic(path,size) .5 
    set Endoscopic(path,color) ".4 .2 .6" 
    
    set Endoscopic(path,activeId) None
    # keeps track of all the Ids of the path that currently exist
    # on the screen
    set Endoscopic(path,activeIdList) ""
    # keeps track of all path Ids that have ever existed
    set Endoscopic(path,allIdsUsed) ""
    set Endoscopic(path,nextAvailableId) 1
    set Endoscopic(randomPath,nextAvailableId) 1
    

    set Endoscopic(vector,name) "Vectors"
    set Endoscopic(vector,size) 5 
    set Endoscopic(vector,visibility) 1    
    set Endoscopic(vector,color) ".2 .6 .8"
    set Endoscopic(vector,selectedID) 0

    set Endoscopic(gyro,name) "3D Gyro"
    set Endoscopic(gyro,visibility) 1
    set Endoscopic(gyro,size) 100
   
    set Endoscopic(gyro,use) 1
    
    #Advanced variables
    set Endoscopic(ModelsVisibilityInside) 1
    set Endoscopic(SlicesVisibility) 1
    set Endoscopic(collision) 0
    set Endoscopic(collDistLabel) ""
    set Endoscopic(collMenu) ""

    # Path variable
    set Endoscopic(path,flyDirection) "Forward"
    set Endoscopic(path,speed) 1
    set Endoscopic(path,random) 0
    set Endoscopic(path,first) 1
    set Endoscopic(path,i) 0
    set Endoscopic(path,stepStr) 0
    set Endoscopic(path,exists) 0
    set Endoscopic(path,numLandmarks) 0
    set Endoscopic(path,stop) 0
    set Endoscopic(path,vtkNodeRead) 0
    
    set Endoscopic(path,interpolationStr) 1
    # set Colors
    set Endoscopic(path,cColor) [MakeColor "0 204 255"]
    set Endoscopic(path,sColor) [MakeColor "204 255 255"]
    set Endoscopic(path,eColor) [MakeColor "255 204 204"]
    set Endoscopic(path,rColor) [MakeColor "204 153 153"]
    
    set LastX 0
    
     # viewers 
    set Endoscopic(mainview,visibility) 1
    set Endoscopic(endoview,visibility) 1
    set Endoscopic(endoview,hideOnExit) 0
    # jeanette
    set Endoscopic(flatview,hideOnExit) 0
    set Endoscopic(viewOn) 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateRenderer
# Creates the named renderer.
# .ARGS
# str renName the name to give this renderer.
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateRenderer {renName} {

    global Endoscopic $renName View Module

    vtkRenderer $renName
    lappend Module(Renderers) $renName    
    eval $renName SetBackground $View(bgColor)
    
    set cam [$renName GetActiveCamera]
    # so that the camera knows about its renderer
    
    set View($cam,renderer) $renName
    
    $cam SetViewAngle 120
    lappend Endoscopic(Cameras) $cam
    
    vtkLight View($cam,light)
    vtkLight View($cam,light2)
    
    vtkLightKit View(light3)
    View(light3) SetKeyLightIntensity 0.7
    View(light3) SetKeyToFillRatio 1.5
    View(light3) SetKeyToHeadRatio 1.75
    View(light3) SetKeyToBackRatio 3.75
    
    #puts "renderer $renName, light obj View($View($camName,cam),light"
    #View($View($camName,cam),light) SetLightTypeToCameraLight
    #View($View($camName,cam),light2) SetLightTypeToSceneLight
#test
   # $renName AddLight View($cam,light)
   # $renName AddLight View($cam,light2)
#test end    
    View(light3) AddLightsToRenderer $renName
    # initial settings. 
    # These parameters are then set in EndoscopicUpdateVirtualEndoscope
    $cam SetPosition 0 0 0
    $cam SetFocalPoint 0 30 0
    $cam SetViewUp 0 0 1
    $cam ComputeViewPlaneNormal        
    set View(endoscopicClippingRange) ".01 1000"
    eval $cam SetClippingRange $View(endoscopicClippingRange)

}

#############################################################################
#
#     PART 1: create vtk actors and parameters 
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC EndoscopicBuildVTK
#  Creates the vtk objects for this module.<br>
#  
#  Effects: calls EndoscopicCreateFocalPoint, 
#           EndoscopicCreateCamera, EndoscopicCreateLandmarks and 
#           EndoscopicCreatePath, EndoscopicCreateGyro, EndoscopicCreateVector   
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicBuildVTK {} {
    global Endoscopic Model Csys
    

    vtkCellPicker Endoscopic(picker)
    Endoscopic(picker) SetTolerance 0.0001
    vtkMath Endoscopic(path,vtkmath)
    
    # create the 3D mouse
    CsysCreate Endoscopic gyro -1 -1 -1
    lappend Endoscopic(actors) Endoscopic(gyro,actor) 
    
    # create the focal point actor
    EndoscopicCreateFocalPoint
    lappend Endoscopic(actors) Endoscopic(fp,actor) 
    
    # create the camera actor (needs to be created after the gyro
    # since it uses the gyro's matrix as its user matrix
    EndoscopicCreateCamera
    lappend Endoscopic(actors) Endoscopic(cam,actor)
    
    #update the virtual camera
    EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)
    
    # add the camera, fp, gyro actors only to viewRen, not endoscopicScreen
    # set their visibility to 0 until we enter the module
    #viewRen AddActor Endoscopic(cam,actor)
    Endoscopic(cam,actor) SetVisibility 1
    EndoscopicSetPickable Endoscopic(cam,actor) 0
    #viewRen AddActor Endoscopic(fp,actor)
    Endoscopic(fp,actor) SetVisibility 1
    EndoscopicSetPickable Endoscopic(fp,actor) 0
    #viewRen AddActor Endoscopic(gyro,actor)
    Endoscopic(gyro,actor) SetVisibility 1

     # create the vectors base look
    vtkCylinderSource tube
    vtkConeSource arrow
    vtkTransform tubeXform
    vtkTransform arrowXform
    vtkTransformPolyDataFilter tubeXformFilter
    tubeXformFilter SetInput [tube GetOutput]
    tubeXformFilter SetTransform tubeXform
    vtkTransformPolyDataFilter arrowXformFilter
    arrowXformFilter SetInput [arrow GetOutput]
    arrowXformFilter SetTransform arrowXform
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateCamera
#  Create the Camera vtk actor
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateCamera {} {
    global Endoscopic
    
    vtkCubeSource camCube
    vtkTransform CubeXform        
    vtkCubeSource camCube2
    vtkTransform CubeXform2        
    vtkCubeSource camCube3
    vtkTransform CubeXform3        
    vtkCylinderSource camCyl
    vtkTransform CylXform        
    vtkCylinderSource camCyl2
    vtkTransform CylXform2        
    
    EndoscopicCameraParams
    
    # make the actor (camera)
    
    vtkTransformPolyDataFilter CylXformFilter
    CylXformFilter SetInput [camCyl GetOutput]
    CylXformFilter SetTransform CylXform
    
    vtkTransformPolyDataFilter CylXformFilter2
    CylXformFilter2 SetInput [camCyl2 GetOutput]
    CylXformFilter2 SetTransform CylXform2
    
    vtkTransformPolyDataFilter CubeXformFilter
    CubeXformFilter SetInput [camCube GetOutput]
    CubeXformFilter SetTransform CubeXform
    
    vtkTransformPolyDataFilter CubeXformFilter2
    CubeXformFilter2 SetInput [camCube2 GetOutput]
    CubeXformFilter2 SetTransform CubeXform2
    
    vtkTransformPolyDataFilter CubeXformFilter3
    CubeXformFilter3 SetInput [camCube3 GetOutput]
    CubeXformFilter3 SetTransform CubeXform3
    
    vtkPolyDataMapper BoxMapper
    BoxMapper SetInput [CubeXformFilter GetOutput]
    
    vtkPolyDataMapper BoxMapper2
    BoxMapper2 SetInput [CubeXformFilter2 GetOutput]
    
    vtkPolyDataMapper BoxMapper3
    BoxMapper3 SetInput [CubeXformFilter3 GetOutput]
    
    vtkPolyDataMapper LensMapper
    LensMapper SetInput [CylXformFilter GetOutput]
    
    vtkPolyDataMapper LensMapper2
    LensMapper2 SetInput [CylXformFilter2 GetOutput]
    
    vtkActor Endoscopic(Box,actor)
    Endoscopic(Box,actor) SetMapper BoxMapper
    eval [Endoscopic(Box,actor) GetProperty] SetColor $Endoscopic(Box,color)
    Endoscopic(Box,actor) PickableOff
    
    vtkActor Endoscopic(Box2,actor)
    Endoscopic(Box2,actor) SetMapper BoxMapper2
    eval [Endoscopic(Box2,actor) GetProperty] SetColor $Endoscopic(Box,color) 
    Endoscopic(Box2,actor) PickableOff
    
    vtkActor Endoscopic(Box3,actor)
    Endoscopic(Box3,actor) SetMapper BoxMapper3
    eval [Endoscopic(Box3,actor) GetProperty] SetColor 0 0 0 
    Endoscopic(Box3,actor) PickableOff
    
    vtkActor Endoscopic(Lens,actor)
    Endoscopic(Lens,actor) SetMapper LensMapper
    eval [Endoscopic(Lens,actor) GetProperty] SetColor $Endoscopic(Lens,color) 
    Endoscopic(Lens,actor) PickableOff
    
    vtkActor Endoscopic(Lens2,actor)
    Endoscopic(Lens2,actor) SetMapper LensMapper2
    [Endoscopic(Lens2,actor) GetProperty] SetColor 0 0 0
    Endoscopic(Lens2,actor) PickableOff
    
    set Endoscopic(cam,actor) [vtkAssembly Endoscopic(cam,actor)]
    Endoscopic(cam,actor) AddPart Endoscopic(Box,actor)
    Endoscopic(cam,actor) AddPart Endoscopic(Box2,actor)
    Endoscopic(cam,actor) AddPart Endoscopic(Box3,actor)
    Endoscopic(cam,actor) AddPart Endoscopic(Lens,actor)
    Endoscopic(cam,actor) AddPart Endoscopic(Lens2,actor)
    Endoscopic(cam,actor) PickableOn

    # set the user matrix of the camera and focal point to be the matrix of
    # the gyro
    # the full matrix of the cam and fp is a concatenation of their matrix and
    # their user matrix
    Endoscopic(cam,actor) SetUserMatrix [Endoscopic(gyro,actor) GetMatrix]
    Endoscopic(fp,actor) SetUserMatrix [Endoscopic(gyro,actor) GetMatrix]
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCameraParams
# effects: Set the size parameters for the camera and the focal point
# .ARGS 
# int size (optional), 1 by default
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCameraParams {{size -1}} {
    global Endoscopic
    
    if { $size == -1 } { 
        set Endoscopic(cam,size) 1
    } else {
        set Endoscopic(cam,size) $size
    }
    # set parameters for cube (body) geometry and transform
    set Endoscopic(cam,boxlength) [expr $Endoscopic(cam,size) * 30]
    set Endoscopic(cam,boxheight) [expr $Endoscopic(cam,size) * 20]
    set Endoscopic(cam,boxwidth)  [expr $Endoscopic(cam,size) * 10]
    
    set unit [expr $Endoscopic(cam,size)]
    
    camCube SetXLength $Endoscopic(cam,boxlength)
    camCube SetYLength $Endoscopic(cam,boxwidth)
    camCube SetZLength $Endoscopic(cam,boxheight)
    
    CubeXform Identity
    #CubeXform RotateZ 90
    
    camCube2 SetXLength [expr $Endoscopic(cam,boxlength) /3] 
    camCube2 SetYLength $Endoscopic(cam,boxwidth)
    camCube2 SetZLength [expr $Endoscopic(cam,boxheight) /3]
    
    CubeXform2 Identity
    CubeXform2 Translate 0 0 [expr {$Endoscopic(cam,boxheight) /2}]
    
    camCube3 SetXLength [expr $Endoscopic(cam,boxlength) /6] 
    camCube3 SetYLength [expr $Endoscopic(cam,boxwidth) +$unit]
    camCube3 SetZLength [expr $Endoscopic(cam,boxheight) /6]
    
    CubeXform3 Identity
    CubeXform3 Translate 0 0 [expr {$Endoscopic(cam,boxheight) /2} + $unit]
    
    # set parameters for cylinder (lens) geometry and transform
    camCyl SetRadius [expr $Endoscopic(cam,boxlength) / 3.5]
    camCyl SetHeight [expr $Endoscopic(cam,boxwidth) * 1.5]
    camCyl SetResolution 8
    
    CylXform Identity
    CylXform Translate 0 [expr $Endoscopic(cam,boxwidth) / 2] 0
    
    camCyl2 SetRadius [expr $Endoscopic(cam,boxlength) / 5]
    camCyl2 SetHeight [expr $Endoscopic(cam,boxwidth) * 1.5]
    camCyl2 SetResolution 8
    
    CylXform2 Identity
    CylXform2 Translate 0 [expr {$Endoscopic(cam,boxwidth) / 2} + $unit] 0
    
    #also, set the size of the focal Point actor
    set Endoscopic(fp,size) [expr $Endoscopic(cam,size) * 4]
    Endoscopic(fp,source) SetRadius $Endoscopic(fp,size)
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateFocalPoint
#  Create the vtk FocalPoint actor
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateFocalPoint {} {
    
    global Endoscopic

    vtkSphereSource Endoscopic(fp,source)
    Endoscopic(fp,source) SetRadius $Endoscopic(fp,size)
    vtkPolyDataMapper Endoscopic(fp,mapper)
    Endoscopic(fp,mapper) SetInput [Endoscopic(fp,source) GetOutput]
    vtkActor Endoscopic(fp,actor)
    Endoscopic(fp,actor) SetMapper Endoscopic(fp,mapper)
    eval [Endoscopic(fp,actor) GetProperty] SetColor $Endoscopic(fp,color)
    set Endoscopic(fp,distance) [expr $Endoscopic(cam,boxwidth) *3] 
    Endoscopic(fp,actor) SetPosition 0 $Endoscopic(fp,distance) 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateVTKPath
# Calls EndoscopicCreatePath and adds the path to the view.
# .ARGS
# int id the id of the endoscopic path
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateVTKPath {id} {

    global Endoscopic
   
    #create the Path actors 
    EndoscopicCreatePath $id   
    lappend Endoscopic(actors) Endoscopic($id,path,actor)

    #create the Vector actor
    # TODO: need to change from vtkVectors etc to vtkFloatArray and it's friends
    #EndoscopicCreateVector $id
    #lappend Endoscopic(actors) Endoscopic($id,vector,actor)
    
    viewRen AddActor Endoscopic($id,path,actor)
    Endoscopic($id,path,actor) SetVisibility 1
    #viewRen AddActor Endoscopic($id,vector,actor)
    #Endoscopic($id,vector,actor) SetVisibility 1

    lappend Endoscopic(path,allIdsUsed) $id
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetPathVariables
# Remove points, and reset vtk vars.
# .ARGS
# int id path id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetPathVariables {id} {
    global Endoscopic View
    
    foreach m {c f} {
        Endoscopic($id,${m}path,Spline,x) RemoveAllPoints
        Endoscopic($id,${m}path,Spline,y) RemoveAllPoints
        Endoscopic($id,${m}path,Spline,z) RemoveAllPoints
        Endoscopic($id,${m}path,keyPoints) Reset
        Endoscopic($id,${m}path,graphicalInterpolatedPoints) Reset
        Endoscopic($id,${m}path,allInterpolatedPoints) Reset
    }
    Endoscopic($id,path,lines) Reset 
    Endoscopic($id,path,polyData) Modified
    #Endoscopic($id,vector,polyData) Modified
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreatePath
#  Create the vtk camera Path and focalPoint Path actors
# .ARGS
# int id path id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreatePath {id} {
         global Endoscopic

    
    # cpath: variables about the points along the camera path
    # fpath: variables about the points along the focal point path
    foreach m "c f" {
        vtkPoints    Endoscopic($id,${m}path,keyPoints)  
        vtkPoints    Endoscopic($id,${m}path,graphicalInterpolatedPoints)
        vtkPoints    Endoscopic($id,${m}path,allInterpolatedPoints)
        
        vtkCardinalSpline Endoscopic($id,${m}path,Spline,x)
        vtkCardinalSpline Endoscopic($id,${m}path,Spline,y)
        vtkCardinalSpline Endoscopic($id,${m}path,Spline,z)
        
        Endoscopic($id,${m}path,keyPoints)  SetDataTypeToFloat
        Endoscopic($id,${m}path,graphicalInterpolatedPoints) SetDataTypeToFloat
        Endoscopic($id,${m}path,allInterpolatedPoints) SetDataTypeToFloat
    }
    
    # path: variables for the graphical representation of the (camera) path
    # the focal point stays invisible
    
    vtkPolyData         Endoscopic($id,path,polyData)
    vtkCellArray        Endoscopic($id,path,lines)    
    vtkTubeFilter       Endoscopic($id,path,source)
    vtkPolyDataMapper   Endoscopic($id,path,mapper)    
    vtkActor            Endoscopic($id,path,actor)
    
    # set the lines input data
    Endoscopic($id,path,polyData)     SetLines  Endoscopic($id,path,lines)
    # set the tube info
    Endoscopic($id,path,source)       SetNumberOfSides 8
    Endoscopic($id,path,source)       SetInput Endoscopic($id,path,polyData)
    Endoscopic($id,path,source)       SetRadius $Endoscopic(path,size)
    Endoscopic($id,path,mapper)       SetInput [Endoscopic($id,path,source) GetOutput]
    Endoscopic($id,path,actor)        SetMapper Endoscopic($id,path,mapper)
    
    eval  [Endoscopic($id,path,actor) GetProperty] SetDiffuseColor $Endoscopic(path,color)
    [Endoscopic($id,path,actor) GetProperty] SetSpecular .3
    [Endoscopic($id,path,actor) GetProperty] SetSpecularPower 30
    # connect the path with the camera landmarks
    Endoscopic($id,path,polyData) SetPoints Endoscopic($id,cpath,graphicalInterpolatedPoints)
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateVector
#  Create the vtk vector actor
# .ARGS
# int id vector id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateVector {id} {

    global Endoscopic

   
    vtkAppendPolyData Endoscopic($id,vector,source)
    Endoscopic($id,vector,source) AddInput [tubeXformFilter GetOutput]
    Endoscopic($id,vector,source) AddInput [arrowXformFilter GetOutput]
    
    EndoscopicVectorParams $id 10
    
    vtkPolyData         Endoscopic($id,vector,polyData)
    vtkVectors          Endoscopic($id,vector,vectors)
    vtkGlyph3D          Endoscopic($id,vector,glyph)
    vtkPolyDataMapper   Endoscopic($id,vector,mapper)
    vtkActor            Endoscopic($id,vector,actor)
    vtkScalars          Endoscopic($id,vector,scalars)
    
    Endoscopic($id,vector,polyData) SetPoints Endoscopic($id,cpath,keyPoints)
    #    Endoscopic($id,vector,polyData) SetPoints Endoscopic(cLand,graphicalInterpolatedPoints)
    # set the vector glyphs
    [Endoscopic($id,vector,polyData) GetPointData] SetVectors Endoscopic($id,vector,vectors)
    [Endoscopic($id,vector,polyData) GetPointData] SetScalars Endoscopic($id,vector,scalars)
    
    Endoscopic($id,vector,glyph) SetInput Endoscopic($id,vector,polyData)
    Endoscopic($id,vector,glyph) SetSource [Endoscopic($id,vector,source) GetOutput]
    Endoscopic($id,vector,glyph) SetVectorModeToUseVector
    Endoscopic($id,vector,glyph) SetColorModeToColorByScalar
    Endoscopic($id,vector,glyph) SetScaleModeToDataScalingOff

    
    Endoscopic($id,vector,mapper) SetInput [Endoscopic($id,vector,glyph) GetOutput]
    Endoscopic($id,vector,actor) SetMapper Endoscopic($id,vector,mapper)
    
    Endoscopic($id,vector,actor) PickableOn

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicVectorParams
# Set parameters for the vector.
# .ARGS
# int id vector id
# int axislen optional, defaults to 10
# int axisrad optional, defaults to .05 times axislen
# int conelen optional, defaults to .2 times axislen
# .END
#-------------------------------------------------------------------------------
proc EndoscopicVectorParams {id {axislen -1} {axisrad -1} {conelen -1} } {
    global Endoscopic
    if { $axislen == -1 } { set axislen 10 }
    if { $axisrad == -1 } { set axisrad [expr $axislen*0.05] }
    if { $conelen == -1 } { set conelen [expr $axislen*0.2]}
    set axislen [expr $axislen-$conelen]
    
    set Endoscopic(vector,size) $axislen
    
    # set parameters for cylinder geometry and transform
    tube SetRadius $axisrad
    tube SetHeight $axislen
    tube SetCenter 0 [expr -0.5*$axislen] 0
    tube SetResolution 8
    tubeXform Identity
    tubeXform RotateZ 90
    
    # set parameters for cone geometry and transform
    arrow SetRadius [expr $axisrad * 2.5]
    arrow SetHeight $conelen
    arrow SetResolution 8
    arrowXform Identity
    arrowXform Translate $axislen 0 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateVisibility
# 
#  This procedure updates the current visibility of actor a (if specified)
#  and then set that actor to its current visibility
# 
# .ARGS
#  str a  name of the actor Endoscopic($a,actor)
#  int visibility (optional) 0 or 1 
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateVisibility {a {visibility ""}} {
    
    global Endoscopic

    if {$a == "cam"} {
        set a $Endoscopic(cam,actor)
    }
    if {$a =="fp"} {
        set a $Endoscopic(fp,actor)
    }
    if {$a =="gyro"} {
        set a $Endoscopic(gyro,actor)
    }

    if {$visibility == ""} {
        # TODO: check that visibility is a number
        
        set visibility [$a GetVisibility]
    }
    $a SetVisibility $visibility
    if {$a == "Endoscopic(cam,actor)"} {
        set Endoscopic(gyro,visibility) $visibility
        Endoscopic(gyro,actor) SetVisibility $visibility
    }
    EndoscopicSetPickable $a $visibility
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetPickable
# 
#  This procedure sets the pickability of actor a to the value specified
# 
# .ARGS
#  str a  name of the actor Endoscopic($a,actor)
#  int pickability 0 or 1 
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetPickable {a pickability} {
    
    global Endoscopic
    if {$pickability == 0} {
        set p Off
    } elseif {$pickability == 1} {
        set p On
    }
    if {$a == "Endoscopic(gyro,actor)"} {
        foreach w "X Y Z" {
            Endoscopic(gyro,${w}actor) Pickable$p
        }
    } else {
        $a Pickable$p 
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateSize
#
# This procedure updates the size of actor a according to Endoscopic(a,size)
#
# .ARGS
#  int a  name of the actor Endoscopic($a,actor)
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetSize {a} {
    global Advanced Endoscopic Path
    
    if { $a == "gyro"} {
        CsysParams Endoscopic gyro $Endoscopic($a,size)
    } elseif { $a == "cam"} {
        set Endoscopic(fp,distance) [expr $Endoscopic(cam,size) * 30]
        EndoscopicCameraParams $Endoscopic($a,size)
        EndoscopicSetCameraPosition
    } elseif { $a == "vector" } {
        EndoscopicVectorParams $Endoscopic($a,size)
    } elseif { $Endoscopic(path,exists) == 1 } {
        # a is cPath,fPath,cLand or fLand => set their radius
        #set Endoscopic($a,size) Endoscopic($a,sizeStr)
        Endoscopic($a,source) SetRadius $Endoscopic($a,size)
    }
    Render3D 
}

##############################################################################
#
#       PART 2: Build the Gui
#
##############################################################################

#-------------------------------------------------------------------------------
# .PROC EndoscopicPopBindings
# Use the Event bindings, deactiveate the slice 0-2 events.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicPopBindings {} {
    global Ev Csys
    EvDeactivateBindingSet Slice0Events
    EvDeactivateBindingSet Slice1Events
    EvDeactivateBindingSet Slice2Events
    
#    EvDeactivateBindingSet 3DEvents
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicPushBindings
# Use the Event bindings, activate the slice 0-2 events.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicPushBindings {} {
    global Ev Csys

    # push onto the event stack a new event manager that deals with
    # events when the Endoscopic module is active
    EvActivateBindingSet Slice0Events
    EvActivateBindingSet Slice1Events
    EvActivateBindingSet Slice2Events
    
#    EvActivateBindingSet 3DEvents
#  puts "binding pushed"       
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateBindings
# Create event handlers for keys m and t
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateBindings {} {
    global Gui Ev
    
    # Creates events sets we'll  need for this module
    # create the event manager for the ability to move the gyro
     
# endoscopic events for slice windows (in addition to already existing events)

#  <KeyPress-m> allows the user to move the endoscope quickly to a 3D location defined by the mouse, without using the gyro      
   EvDeclareEventHandler EndoKeyMoveSlicesEvents <KeyPress-m> { if { [SelectPick2D %W %x %y] != 0 } \
   {eval EndoscopicSetWorldPosition [lindex $Select(xyz) 0] [lindex $Select(xyz) 1] [lindex $Select(xyz) 2]; Render3D} }

# <KeyPress-t> allows the user to select a target on the 3D colon, and in the 2D slices
   EvDeclareEventHandler EndoKeySelectSlicesEvents <KeyPress-t> { if {[SelectPick2D %W %x %y] != 0} \
   {eval EndoscopicAddTargetFromSlices [lindex $Select(xyz) 0] [lindex $Select(xyz) 1] [lindex $Select(xyz) 2]} }

   EvAddWidgetToBindingSet Slice0Events $Gui(fSl0Win) {{EndoKeySelectSlicesEvents} {EndoKeyMoveSlicesEvents}}
   EvAddWidgetToBindingSet Slice1Events $Gui(fSl1Win) {{EndoKeySelectSlicesEvents} {EndoKeyMoveSlicesEvents}}
   EvAddWidgetToBindingSet Slice2Events $Gui(fSl2Win) {{EndoKeySelectSlicesEvents} {EndoKeyMoveSlicesEvents}}

#  Activated in TkInteractor
#   EvDeclareEventHandler EndoKeySelect3DEvents <KeyPress-t> { if { [SelectPick Endoscopic(picker) %W %x %y] != 0 } \
    { eval EndoscopicAddTargetFromWorldCoordinates [lindex $Select(xyz) 0] [lindex $Select(xyz) 1] [lindex $Select(xyz) 2] $Select(cellId) }}
    
#   EvAddWidgetToBindingSet 3DEvents $Gui(fViewWin) {EndoKeySelect3DEvents}
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicBuildGUI
# Create the Graphical User Interface.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicBuildGUI {} {
    global Gui Module Model View Advanced Endoscopic Path PathPlanning Label Mrml Fiducials
    
    
    set LposTexts "{L<->R} {P<->A} {I<->S}"
    set RposTexts "{Pitch  } {Roll  } {Yaw  }"
    set posAxi "x y z"

    set dirTexts "{X} {Y} {Z}"
    set dirAxi "rx ry rz"

    # first add the Endoscopic label to the View menu in the main Gui
    $Gui(mView) add separator
    $Gui(mView) add command -label "Add Endoscopic View" -command "EndoscopicAddEndoscopicView; Render3D"
    $Gui(mView) add command -label "Remove Endoscopic View" -command "EndoscopicRemoveEndoscopicView; Render3D"
    
  #jeanette: add Flatwindow label to the view menu in the main Gui
  #  $Gui(mView) add command -label "Add Flat Colon View" -command "MainMenu File Import"
  #  $Gui(mView) add command -label "Remove Flat Colon View" -command "EndoscopicRemoveFlatView"

    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(Endoscopic,fStuff)
    # This is a useful comment block that makes reading this easy for all:
        #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Advanced
    #   Top
    #     Vis
    #     Title
    #     Pos
    #   Mid
    #     Vis
    #     Title
    #     Pos
    #   Bot
    #     Vis
    #     Title
    #     Pos
    # Camera    
    #-------------------------------------------

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    set help "
    This module allows you to position an endoscopic camera in the scene and 
    view through the camera's lens in the second window.
    You can also create a fly-through trajectory and save it in the MRML file by selecting File -> 'Save Scene As'.

    <P>Tab content descriptions:<BR>
    <UL>
    <LI><B>Display</B> 
    <BR> This Tab permits you to set display parameters. It also allows you to open a separate window to view the flattened colon (if you plan to navigate along the flattened colon)
    <BR> 
    <UL>
    <LI><B>Camera</B> 
    <BR>This tab contains controls to navigate the camera and create landmarks.
    <P><B>To move and rotate the camera</B>:
    <BR>- select absolute mode (to move along the world's axis) or relative mode (to move along the camera's axis)
    <BR>- to move the camera with precision, use the sliders or type a world coordinate in the text box, next to the sliders. For the orientation of the camera, the number displayed is the angle of rotation in degrees.
    <BR>- to move the camera intuitively, use the 3D Gyro (read instructions on the tab). 
    <BR>- you can also move the camera by combining the shift or control key with mouse button press and motion. For example: Shift+moving the mouse with left button pressed down controls the camera's 'Pitch'. Shift + middle or right mouse button motion controls the camera's 'Roll' and 'Yaw' respectively. Control + Left, middle, or right mouse button press and motion controls the camera's 'L<->R', 'I<->S', and 'P<->A'. The precise amount of camera motion, as you use the key + mouse motion, can be read off from the sliders in the camera tab.
    <P>
    <BR><B>To create a path</B>:
    <BR><B>Automatically:</B>
    <BR> -If you have a closed 3D model, you can create a path automatically by clicking the button <I>AutoExtractCenterLine</I>. A begin and end point will be automatically selected, and a path generated in between.
    <BR><B>Manually</B>:
    <BR> You have 2 options: you can pick a landmark position on a 2D slice or in the 3D world:
    <BR> * <B>IN 3D</B>
    <BR>- Position the camera where desired
    <BR>- Click the button <I>AddLandmark</I>: this will add a landmark (a sphere) at the current camera position and another landmark at<BR> the current focal point position 
    <BR>- Two paths will automatically be created: one that links all the camera landmarks and another one that links all the focal point landmarks
    <BR> * <B>IN 2D</B>
    <BR> - You need to have greyscale images loaded along with the model, otherwise this option won't work
    <BR> - position the mouse in the slice window of your choice until the cross hair is on top of the region where you want to add a landmark
    <BR> - press the <B>m</B> key, and the endoscope will jump to the corresponding location in 3D. You can then Click the button <I>AddLandmark</I>.
    <BR> - by default, both a camera and focal point landmark will be added at this position
    <BR><B>To constrain the camera on the path</B>:
    <BR> -After a path or centerline is created, you can manually insert visible fiducials on the model while constrain the camera along the path.
    <BR> -Point the cursor on the 3D model or on the 2D slices below, and press the key 't', the endoscope will jump to the closet point along the path, aim at the selected location, and create a visible target. If you have the flattened colon open, just press shift + double click left mouse button on the intended location, and the endoscope will perform the same task. You can also set the camera location and orientation manually and press <I>CreateTarget</I> to insert a visible fiducial point on the 3D model.
    <BR><B>To select a landmark</B>:
    <BR> - Click on the landmark position in the scrollable text area, the line will be highlighted in red and the camera will jump to that landmark in the 3D view.
    <BR> - or Point the mouse at a landmark in the 3D view and press 'p'.
    <BR><B> To update a landmark position/orientation</B>:
    <BR> Select a landmark as described above, then reposition and reorient the camera then press the 'Update' button.
    <BR><B>To delete a camera landmark</B>:
    <BR>- Select the landmark a described above 
    <BR>- Click the <I>Delete</I> button
    <BR><B> To Delete the whole path</B>:
    <BR>- Click the <I>Delete All</I> button
    <BR><B> To save a path </B>
    <BR>- Go to File -> Save Scene As
    <BR>- Next time you open that scene, the path will appear as well.
    <BR><B> To Fly-Through on the path</B>:  
    <BR>- Go to the Path Tab
    <P>
    <LI><B>Path</B>
    <BR>This Tab contains controls to fly-through on the path
    <BR><B>Command buttons</B>: 
    <BR>- <I>Fly-Through</I>: moves the camera along the path and orient its focal point along the focal point path
    <BR><I>- Reset</I>: stops the motion of the camera and repositions it at the beginning of the path
    <BR><I>- Stop</I>: stops the motion of the camera
    <BR><B>FastForward or Backward</B>:
    <BR> -If you have a series of targets along the path that you would look at, you can click the FastForward or Backward button to jump between the targets.
    <BR><B>Command sliders</B>:
    <BR><I>- Frame</I>: positions the camera on any part of the path
    <BR><I>- Speed</I>: controls the speed of the camera's motion along the path (the number corresponds to the number of frames to skip)
    <BR><I>- No of Interpolated Points </I>: this will recompute the path with approximately the number of interpolated points per mm specified in between key points (landmarks).
    <BR><B>To drive the slices</B>:
    <BR> Select which driver you want: 
    <BR> - <B>User</B>: the user selects the slice position and orientation with the user interface
    <BR> - <B>Camera</B>: the slices in the orientation 'InPlane', 'Perp', 'InPlane90' are reformatted to intersect at the camera position and be oriented along the 3 axes of the camera.
    <BR> - <B>Focal Point</B>: same as above with the focal point instead of the camera.
    <BR> - <B>Intersection</B>: the intersection is the point on the surface of the model in the center of the endoscopic screen. It is the intersection between a 'ray' shot from the camera straight ahead and any triangulated surface that is first intersected.
    <BR><B> Random Path </B>
    <BR><I>- Compute Path</I>: creates a new random path at every click
    <BR><I>- Delete Path</I>: deletes the random path (or any path previously created)
    <BR>
    <BR> The functionality of creating/deleting a random path is there for you to play around with difference fly-through options without having to create a path. If you feel like having a bit of fun, click on <I> Show Path </I> and then set the <I> RollerCoaster</I> option before doing a fly-through. <B>Enjoy the ride! </B>
    
    <P>
    <LI><B>Advanced</B>
    <BR>This Tab allows you to change color and size parameters for the camera, focal point, landmarks and path. You can also change the virtual camera's lens angle for a wider view.
    "
    regsub -all "\n" $help { } help
    MainHelpApplyTags Endoscopic $help
    MainHelpBuildGUI Endoscopic

    #-------------------------------------------
    # Display frame
    #-------------------------------------------
    set fDisplay $Module(Endoscopic,fDisplay)
    set f $fDisplay
        
    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    frame $f.fMain -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $f.fEndo -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $f.fTitle2 -bg $Gui(activeWorkspace)
    frame $f.fFlat -bg $Gui(activeWorkspace) 
    # -relief groove -bd 2
    pack $f.fTitle $f.fBtns $f.fMain $f.fEndo $f.fTitle2 $f.fFlat \
    -side top -pady 2 -fill x
    
    
    eval {label $f.fTitle.lTitle -text "
    If your screen allows, you can change 
    the width of the view screen to have 
    a better Endoscopic view:"} $Gui(WLA)
    pack $f.fTitle.lTitle -side left -padx $Gui(pad) -pady 0
    
    eval {label $f.fBtns.lW -text "Width:"} $Gui(WLA)
    eval {entry $f.fBtns.eWidth -width 5 -textvariable View(viewerWidth)} $Gui(WEA)
    bind $f.fBtns.eWidth  <Return> {MainViewerSetMode}
    eval {menubutton $f.fMBtns -text "choose" -menu $f.fMBtns.fMenu} $Gui(WMBA)
    TooltipAdd $f.fMBtns "Choose from the following sizes"
    eval {menu $f.fMBtns.fMenu} $Gui(WMA)
    $f.fMBtns.fMenu add command -label 1000 -command {set View(viewerWidth) 1000; MainViewerSetMode}
    $f.fMBtns.fMenu add command -label 768 -command {set View(viewerWidth) 768; MainViewerSetMode}
    
    grid $f.fBtns.lW $f.fBtns.eWidth $f.fMBtns -padx $Gui(pad)

    set f $fDisplay.fMain
    eval {label $f.fexpl -text "Main (Global) View parameter:"} $Gui(WLA)
    eval {checkbutton $f.cMainView -variable Endoscopic(mainview,visibility) -text "Show Main (Global) View" -command "EndoscopicUpdateMainViewVisibility" -indicatoron 0} $Gui(WCA)    

    pack $f.fexpl $f.cMainView -pady 2
    

    set f $fDisplay.fEndo
    eval {label $f.fexpl -text "Endoscopic View parameters:"} $Gui(WLA)
    
    eval {checkbutton $f.cEndoView -variable Endoscopic(endoview,visibility) -text "Show Endoscopic View" -command "EndoscopicUpdateEndoscopicViewVisibility" -indicatoron 0} $Gui(WCA)    
    
    eval {checkbutton $f.cslices -variable Endoscopic(SlicesVisibility) -text "Show 2D Slices" -command "EndoscopicSetSlicesVisibility" -indicatoron 0} $Gui(WCA)
    
    eval {checkbutton $f.cExitEndoView -variable Endoscopic(endoview,hideOnExit) -text "Hide Endoscopic View on Exit" -indicatoron 0} $Gui(WCA)
    
    pack $f.fexpl -side top -pady 2
    pack $f.cEndoView  -side top -padx $Gui(pad) -pady 0
    pack $f.cslices -side top -pady 5
    pack $f.cExitEndoView -side top -padx $Gui(pad) -pady 7

 # Fix later: Ask user if they like the parameters and then proceed to either Camera or Path
    # The following 5 lines appears un-finished by Delphine;
    set f $fDisplay
    set text "
    To start, go to the Camera tab 
    If you need help, go to the Help tab"
    eval {label $f.fTitle2.lTitle -text $text} $Gui(WLA)
        
    
    set f $fDisplay.fFlat
    
    eval {label $f.fexpl -text "Flat View parameters:"} $Gui(WLA)
    
  # Fix later: Need some checking mechanism 
      # (1) to see if the flat file comes with the xml
    # (2) to make sure the flat file matches the right model

  
    eval {label $f.fSelectLabel -text "Select a Flattened Colon File (.vtk), click -Apply-"} $Gui(WLA)
    pack $f.fexpl $f.fSelectLabel -pady 2
    
    set f $fDisplay.fFlat 
    DevAddFileBrowse $f Endoscopic FlatSelect "" "EndoscopicSetFlatFileName" "vtk"
    
    set f $fDisplay.fFlat
    DevAddButton $f.bChoose "Apply" "EndoscopicAddFlatView"
    DevAddButton $f.bCancel "Cancel" "EndoscopicCancelFlatFile"
    pack $f.bChoose -side left -padx 30
    pack $f.bCancel -side right -padx 30
    
    set f $fDisplay
    eval {checkbutton $f.cExitFlatView -variable Endoscopic(flatview,hideOnExit) -text "Hide Flat View on Exit" -indicatoron 0} $Gui(WCA)
    pack $f.cExitFlatView -side bottom -pady 2
    # eval {checkbutton $f.cFlatView -variable Endoscopic(flatview,visibility) -text "Show Flat View" -command "EndoscopicUpdateFlatViewVisibility" -indicatoron 0} $Gui(WCA)    
    
    
    
    
    #-------------------------------------------
    # Camera frame
    #-------------------------------------------
    set fCamera $Module(Endoscopic,fCamera)
    set f $fCamera
    
    frame $f.fTop -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fMid -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fBot -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fTop $f.fMid $f.fBot -side top -pady 0.5 -padx 0 -fill x
    
    
    #-------------------------------------------
    # Camera->Top frame
    #-------------------------------------------
    set f $fCamera.fTop
    
    frame $f.fGyro   -bg $Gui(activeWorkspace)
    frame $f.fGyro2   -bg $Gui(activeWorkspace)
    frame $f.fInfo     -bg $Gui(activeWorkspace)
    frame $f.fInfo2     -bg $Gui(activeWorkspace)
    pack  $f.fGyro $f.fGyro2 $f.fInfo $f.fInfo2 -side top 
    
    
    #-------------------------------------------
    # Camera->Top->Title frame
    #-------------------------------------------
    
    set f $fCamera.fTop.fGyro
    
    eval {checkbutton $f.cgyro -variable Endoscopic(gyro,use) -text "Use the 3D Gyro" -command "EndoscopicUseGyro; Render3D" -indicatoron 0 } $Gui(WBA)

    set Endoscopic(gyro,image,absolute) [image create photo -file \
        [ExpandPath [file join gui endoabsolute.gif]]]
    
    set Endoscopic(gyro,image,relative) [image create photo -file \
        [ExpandPath [file join gui endorelative.gif]]]

    
    set Endoscopic(imageButton) $fCamera.fTop.fGyro.cb
    
    eval {checkbutton $Endoscopic(imageButton)  -image $Endoscopic(gyro,image,relative) -variable Endoscopic(cam,navigation,relative) -width 70 -indicatoron 0 -height 70} $Gui(WBA)
 
    eval {button $f.bhow -text "How ?"} $Gui(WBA)
    TooltipAdd $f.bhow "Select an axis by clicking on it with the mouse.
Translate the axis by pressing the left mouse button and moving the mouse.
Rotate the axis by pressing the right mouse button and moving the mouse."

    pack $f.cb  $f.cgyro $f.bhow -side left -pady 3 -padx 2

    set f $fCamera.fTop.fGyro2
    eval {label $f.lgyroOr -text "Orientation"} $Gui(WTA)
    foreach item "absolute relative" {    
        eval {radiobutton $f.f$item -variable Endoscopic(cam,axis) -text $item -value $item -command "$Endoscopic(imageButton) configure -image $Endoscopic(gyro,image,${item}); EndoscopicSetGyroOrientation; EndoscopicSetCameraAxis $item; Render3D"} $Gui(WBA)
        pack $f.lgyroOr $f.f$item -side left -padx 2 -pady 2
    }
    
    #-------------------------------------------
    # Camera->Mid frame
    #-------------------------------------------
    set f $fCamera.fMid

    frame $f.fPosTitle   -bg $Gui(activeWorkspace)
    frame $f.fPos   -bg $Gui(activeWorkspace)
    pack $f.fPosTitle $f.fPos -side top
    frame $f.fRotTitle     -bg $Gui(activeWorkspace)
    frame $f.fRot     -bg $Gui(activeWorkspace)
    frame $f.fZoom    -bg $Gui(activeWorkspace)
    pack $f.fRotTitle $f.fRot -side top 
    #    pack $f.fZoom -side top


    set f $fCamera.fMid.fPosTitle
    
    eval {label $f.l -height 1 -text "Camera Position"} $Gui(WTA)
    eval {button $f.r \
        -text "reset" -width 10 -command "EndoscopicResetCameraPosition; Render3D"} $Gui(WBA)            
    pack $f.l $f.r -padx 1 -pady 1 -side left
    
    set f $fCamera.fMid.fPos

    #Position Sliders
    foreach slider $posAxi Ltext $LposTexts Rtext $RposTexts orient "horizontal horizontal vertical" {
        EndoscopicCreateLabelAndSlider $f l$slider 0 "$Ltext" $slider $orient -400 400 110 Endoscopic(cam,${slider}Str) "EndoscopicSetCameraPosition $slider" 5 0
        set Endoscopic(slider$slider) $f.s$slider
        set Endoscopic(label$slider) $f.l$slider
    }

    

    #-------------------------------------------
    # Camera->Mid->Title frame
    #-------------------------------------------

    set f $fCamera.fMid.fRotTitle

    eval {label $f.l -height 1 -text "Camera Orientation"} $Gui(WTA)
    eval {button $f.r \
        -text "reset" -width 10 -command "EndoscopicResetCameraDirection; Render3D"} $Gui(WBA)            
    grid $f.l $f.r -padx 1 -pady 1

    #-------------------------------------------
    # Camera->Mid->Dir frame
    #-------------------------------------------
    set f $fCamera.fMid.fRot

    # Rotation Sliders
    foreach slider $dirAxi Rtext $RposTexts orient "horizontal horizontal vertical" {

        EndoscopicCreateLabelAndSlider $f l$slider 0 "$Rtext" $slider $orient -360 360 110 Endoscopic(cam,${slider}Str) "EndoscopicSetCameraDirection $slider" 5 0
        set Endoscopic(slider$slider) $f.s$slider
        set Endoscopic(label$slider) $f.l$slider
    }

    #-------------------------------------------
    # Camera->Mid->Zoom frame
    #-------------------------------------------
    set f $fCamera.fMid.fZoom

    # Position Sliders

    eval {label $f.l2 -height 2 -text "Camera Zoom"} $Gui(WTA)
    grid $f.l2
    
    EndoscopicCreateLabelAndSlider $f lzoom 0 "In<->Out" $slider horizontal 1 500 110 Endoscopic(cam,zoomStr) "EndoscopicSetCameraZoom" 5 30


   
   
    
    
    
    #-------------------------------------------
    # Path frame
    #-------------------------------------------
    set fPath $Module(Endoscopic,fPath)

    frame $fPath.fTop   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $fPath.fBot   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $fPath.fTop $fPath.fBot -side top -pady 2 -expand yes -fill both

    set f $fPath.fBot
    FiducialsAddActiveListFrame $f 275 10  
    
    set f $fPath.fTop
    set PathMenu {Manual Automatic Advanced}
    
    EndoscopicBuildFlyThroughGUI
    #-------------------------------------------
    # Path Frame: Menu Selection      
    #-------------------------------------------
    TabbedFrame Endoscopic $f "" $PathMenu $PathMenu \
        {"Create a Fly-Through Path Manually" \
         "Create a Fly-Through Path Automatically with the CPP Algorithm"\
         "Advanced Option for the CPP Algorithm"}\
     0 Manual 
    
    foreach i $PathMenu {
        $f.fTop.fTabbedFrameButtons.f.r$i configure -command "EndoscopicExecutePathTab $i"
    }
    set Endoscopic(pathTab) $f

    set f $f.fTabbedFrame

    set Endoscopic(tabbedFrame) $f
    
    #-------------------------------------------
    # Path Frame: Manual
    #-------------------------------------------
    set f $Endoscopic(tabbedFrame).fManual

    frame $f.fTitle   -bg $Gui(activeWorkspace)
    frame $f.fStep1   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep2   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep3   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep4   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep5   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep6   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fTitle $f.fStep1 $f.fStep2 $f.fStep3 $f.fStep4 $f.fStep5 $f.fStep6 -side top -pady 2 
    
    set f $Endoscopic(tabbedFrame).fManual.fTitle
    eval {label $f.lTitle -text "Modify Landmarks & Targets"} $Gui(WTA)
    eval {button $f.fbhow -text "How?"} $Gui(WBA)
    TooltipAdd $f.fbhow "--Landmarks are small spheres that are usually connected by a path. The camera travels along
    the path and passes through each landmark in a tipical fly through animation.
    --Targets are fiducial points on the surface of a 3D model that you would like to exam while travelling along the path.
    You can selectively modify either the landmarks along a path or the targets through the following steps"
    pack $f.lTitle $f.fbhow -side left -padx $Gui(pad) -pady 0 


    set f $Endoscopic(tabbedFrame).fManual.fStep1
    eval {label $f.lActive1 -text "Step 1:"} $Gui(WTA)
    eval {label $f.lActive2 -text "Select 3D Model:"} $Gui(WLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 13 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)   
    pack $f.lActive1 $f.lActive2 $f.mbActive -side left -pady 2
    
# Append widgets to list that gets refreshed during UpdateMRML
    lappend Model(mbActiveList) $f.mbActive
    lappend Model(mActiveList)  $f.mbActive.m
    
    
    set f $Endoscopic(tabbedFrame).fManual.fStep2
    frame $f.fStep2-1   -bg $Gui(activeWorkspace) 
    frame $f.fStep2-2   -bg $Gui(activeWorkspace)
    pack  $f.fStep2-1 $f.fStep2-2 -side top -pady 2

    set f $Endoscopic(tabbedFrame).fManual.fStep2.fStep2-1
    eval {label $f.lTitle -text "Step 2:"} $Gui(WTA)
    eval {label $f.lInfo1 -text "Select a Path:"} $Gui(WLA)
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 13 \
          -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    lappend Endoscopic(mbPathList) $f.mbActive
    lappend Endoscopic(mPathList) $f.mbActive.m
    TooltipAdd $f.mbActive "If you would like to automatically create a Centerline, go to the 'Automatic' tab"
    pack $f.lTitle $f.lInfo1 $f.mbActive -side left 
       
    set f $Endoscopic(tabbedFrame).fManual.fStep2.fStep2-2
    eval {label $f.lCreateList -text "or Create New Path:"} $Gui(WLA)
    eval {entry $f.eCreateList -width 13 -textvariable Fiducials(newListName) } $Gui(WEA)
    
    bind $f.eCreateList <Return> {EndoscopicCreateAndActivatePath $Fiducials(newListName)}  
    pack $f.lCreateList $f.eCreateList -side left -padx $Gui(pad) -pady 1
    
    
    set f $Endoscopic(tabbedFrame).fManual.fStep3
    eval {label $f.fstep -text "Step 3:"} $Gui(WTA)
    eval {label $f.fSelectLabel -text "Open a Flattened Colon "} $Gui(WLA)
    eval {button $f.bHow -text " ? "} $Gui(WBA)
    TooltipAdd $f.bHow "You can open a new window to examine the flattened colon in the 'Display' tab"
    pack $f.fstep $f.fSelectLabel $f.bHow -side left -padx 2
 
     
    set f $Endoscopic(tabbedFrame).fManual.fStep4
    frame $f.fStep4-1   -bg $Gui(activeWorkspace) 
    frame $f.fStep4-2   -bg $Gui(activeWorkspace)
    frame $f.fStep4-3   -bg $Gui(activeWorkspace)
    pack  $f.fStep4-1 $f.fStep4-2 $f.fStep4-3 -side top
    
    set f $Endoscopic(tabbedFrame).fManual.fStep4.fStep4-1
    eval {label $f.lTitle -text "Step 4:"} $Gui(WTA)
    eval {label $f.lTitle2 -text "Modify Path Landmarks "} $Gui(WLA)
    eval {button $f.bHow -text " ? "} $Gui(WBA)
    TooltipAdd $f.bHow "Use the functions in this step to modify the landmarks that belong to a selected path.
    
    --Create Landmark: Move and aim the endoscope to any location in space, when you click 'Create Landmark',
    a small spherecal landmark will appear at the location of the endoscope. Repeat the above procedure and create
    a series of landmarks, which will all be connected with a path
    
    --Insert Landmark: Select a Landmark in the 3D screen by pointing at it with the mouse and press 'q'. Adjust the endoscope 
    to the desired position and orientation and click the 'Insert' button. A new landmark on the path is inserted after the selected one. 
   
    --Update: Select a Landmark in the 3D screen by pointing at it with the mouse and press 'q'. The endoscope jumps to that landmark and 
    positions itself along the vector of view. Re-orient or move the endoscope and click the 'Update' button to apply the new information
    
    --Delete: You can delete a landmark by selecting it in the 3D screen first and then pressing the 'd' key,
    or by selecting it in the scrolltext and right-click to get a menu."
    pack $f.lTitle $f.lTitle2 $f.bHow -side left -padx 2

    set f $Endoscopic(tabbedFrame).fManual.fStep4.fStep4-2
    eval {button $f.bAdd -text "Create Landmark" \
        -command "EndoscopicAddLandmarkDirectionSpecified; MainUpdateMRML; Render3D"} $Gui(WBA)
    eval {button $f.bInsert -text "Insert Landmark" \
        -command "EndoscopicInsertLandmarkDirectionSpecified; MainUpdateMRML; Render3D"} $Gui(WBA)
     pack $f.bAdd $f.bInsert -side left -padx 2 -pady 2

    set f $Endoscopic(tabbedFrame).fManual.fStep4.fStep4-3
    eval {button $f.bUpdate -text "Update" -width 7 \
        -command "EndoscopicUpdateLandmark; Render3D"} $Gui(WBA)
    eval {button $f.bDel -text "Delete" -width 7} $Gui(WBA)
    pack  $f.bUpdate $f.bDel -side left -padx 2 -pady 2


    set f $Endoscopic(tabbedFrame).fManual.fStep5
    frame $f.fStep5-1   -bg $Gui(activeWorkspace) 
    frame $f.fStep5-2   -bg $Gui(activeWorkspace)
    frame $f.fStep5-3   -bg $Gui(activeWorkspace)
    pack  $f.fStep5-1 $f.fStep5-2 $f.fStep5-3 -side top
    
    set f $Endoscopic(tabbedFrame).fManual.fStep5.fStep5-1
    eval {label $f.lTitle -text "Step 5:"} $Gui(WTA)
    eval {label $f.lTitle2 -text "Modify Targets"} $Gui(WLA)
    eval {button $f.bHow -text " ? "} $Gui(WBA)
    TooltipAdd $f.bHow "Use the functions in this step to modify the targets to examine while travelling along a selected path
    
    --Load Targets: If you have previously created and saved targets along a path, click 'Load Targets',
    and the endoscope will jump to the first target with respect to the path you have selected in Step 2.
    
    --Create Targets: Point the cursor on the 3D models or on the 2D slices below, and press the key 't',
    the endoscope will jump to the closest landmark on the path, aim itself at the selected location, 
    and create a fiducial point on the surface of the 3D model.
    If you have the flattened colon open, just press Shift+Double Click left mouse button on the location, 
    and the endoscope will perform the same task.
    
    You can also manually adjust the endoscope's location or oriention as wish. When you are ready, click 'Create Target',
    a fiducial point will be added on the surface of the 3D model. Repeat this procedure and create a series of targets.
    Click the fast forward '>>>' and backward '<<<' button to jump between targets.
    
    --Update: Re-orient or move the endoscope and click the 'Update' button to apply the new information 
    
    -- Delete: Click 'Delete' to remove the active target. "
    eval {button $f.bLoad -text "Load Targets" -command "EndoscopicLoadTargets"} $Gui(WBA)
    pack $f.lTitle $f.lTitle2 $f.bHow $f.bLoad -side left -padx 1
        
    set f $Endoscopic(tabbedFrame).fManual.fStep5.fStep5-2
    eval {button $f.bInsert -text "Create Targets" \
        -command "EndoscopicCreateTargets; Render3D;"} $Gui(WBA)
    eval {label $f.lTar -text "Target#"} $Gui(WLA)
    eval {entry $f.lTarNum \
        -textvariable Endoscopic(selectedTarget) -width 2} $Gui(WEA) {-bg $Endoscopic(path,sColor)}
    bind $f.lTarNum <Return> {EndoscopicSelectTarget $Endoscopic(selectedTarget)}
    eval {button $f.next -text ">>>" -command "EndoscopicSelectNextTarget"} $Gui(WMBA) 
    eval {button $f.prev -text "<<<" -command "EndoscopicSelectPreviousTarget"} $Gui(WMBA)
    pack $f.bInsert $f.prev $f.lTar $f.lTarNum $f.next -side left -padx 2 -pady 2

    set f $Endoscopic(tabbedFrame).fManual.fStep5.fStep5-3
    eval {button $f.bUpdate -text "Update" -width 7 \
        -command "EndoscopicUpdateActiveTarget; Render3D"} $Gui(WBA)
    eval {button $f.bDel -text "Delete" -width 7 \
        -command "EndoscopicDeleteActiveTarget; Render3D" } $Gui(WBA)
    pack  $f.bUpdate $f.bDel -side left -padx 2 -pady 2


    set f $Endoscopic(tabbedFrame).fManual.fStep6
    eval {label $f.lTitle -text "Step 6:"} $Gui(WTA)
    eval {button $f.bpop -text "Show Fly Through Panel" -command "EndoscopicShowFlyThroughPopUp"} $Gui(WBA)
    pack $f.lTitle $f.bpop -side left -padx 2 -pady 2


    #-------------------------------------------
    # Path Frame: Automatic
    #-------------------------------------------
    set f $Endoscopic(tabbedFrame).fAutomatic
    frame $f.fTitle   -bg $Gui(activeWorkspace) 
    frame $f.fStep1   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep21   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep22   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep3   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fTitle $f.fStep1 $f.fStep21 $f.fStep22 $f.fStep3 -side top -pady 2     

    set f $Endoscopic(tabbedFrame).fAutomatic.fTitle
    eval {label $f.lTitle -text "Automatic Path Creation"} $Gui(WTA)
    eval {button $f.fbhow -text " How? "} $Gui(WBA)
    TooltipAdd $f.fbhow "Always choose a model first (Step I). There are 2 options to generate a centerline 
    Option I. Just by clicking the 'AutoExtractCenterLine' button, 2 random start and end point
    as well as the centerline will be generated for you. 
    Option II. Manually create or select the fiducial points to be your beginning and ending points, 
    and then click the 'Extract Centerline' button. If you need information on how to create and select fiducials,
    scroll to the bottom of this page, or go to the Fiducial Module.
    Generally, following the steps should take you through this process 
    (for more info, see references on www.slicer.org)."
    pack $f.lTitle $f.fbhow -side left -padx $Gui(pad) -pady 0 



    set f $Endoscopic(tabbedFrame).fAutomatic.fStep1
    frame $f.fRow1 -bg $Gui(activeWorkspace) 
    frame $f.fRow2  -bg $Gui(activeWorkspace)
    pack  $f.fRow1 $f.fRow2 -side top -pady 2

    set f $Endoscopic(tabbedFrame).fAutomatic.fStep1.fRow1
    eval {label $f.lActive1 -text "Step I. "} $Gui(WTA)
    eval {label $f.lActive2 -text "Choose an Active 3D Model: "} $Gui(WLA)
    pack $f.lActive1 $f.lActive2 -side left
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep1.fRow2
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.mbActive -side top
    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Model(mbActiveList) $f.mbActive
    lappend Model(mActiveList)  $f.mbActive.m
    
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep21
    frame $f.fRow1 -bg $Gui(activeWorkspace) 
    frame $f.fRow2  -bg $Gui(activeWorkspace)
    pack  $f.fRow1 $f.fRow2 -side top -pady 2

    set f $Endoscopic(tabbedFrame).fAutomatic.fStep21.fRow1
    eval {label $f.lActive -text "Step II - Option 1"} $Gui(WTA)
    pack $f.lActive -side top
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep21.fRow2
    eval {button $f.ssauto -text "AutoExtractCenterLine" -command "EndoscopicAutoSelectSourceSink; PathPlanningExtractCenterline"} $Gui(WBA)
    pack $f.ssauto -side top
    
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22
    frame $f.fRow1 -bg $Gui(activeWorkspace) 
    frame $f.fRow2  -bg $Gui(activeWorkspace)
    frame $f.fRow3 -bg $Gui(activeWorkspace) 
    frame $f.fRow4  -bg $Gui(activeWorkspace)
    frame $f.fRow5 -bg $Gui(activeWorkspace) 
    frame $f.fRow6  -bg $Gui(activeWorkspace)
    pack  $f.fRow1 $f.fRow2 $f.fRow3 $f.fRow4 $f.fRow5 $f.fRow6 -side top -pady 2

    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22.fRow1
    eval {label $f.lTitle -text "Step II - Option 2."} $Gui(WTA)
    pack $f.lTitle -side top
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22.fRow2
    eval {label $f.lTitle -text "(A): Create 2 Fiducials and go to (C) "} $Gui(WLA)
    pack $f.lTitle -side top
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22.fRow3
    eval {label $f.lTitle -text "or (B): To use existing Fiducials, 
    press the 'Select fiducial' button,
    then select the start point.
    Repeat for the end point,
    then go to (C)."} $Gui(WLA)
    pack $f.lTitle -side top 
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22.fRow4
    eval {label $f.lsource -text "start point: "} $Gui(WLA)
    eval {label $f.lsource2 -text " None "} $Gui(WLA)
    eval {checkbutton $f.lsourceSel -text "Select fiducial" -variable Endoscopic(sourceButton,on) -indicatoron 0 } $Gui(WBA)
    TooltipAdd $f.lsourceSel "You can select an existing fiducial by pressing this
    button and then selecting the fiducial by pointing at it 
    and pressing the 'q' key."
    set Endoscopic(sourceLabel) $f.lsource2
    pack $f.lsource $f.lsource2 $f.lsourceSel -side left 
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22.fRow5
    eval {label $f.lsink -text "end point: "} $Gui(WLA)
    eval {label $f.lsink2 -text " None "} $Gui(WLA)
    eval {checkbutton $f.lsinkSel -text "Select fiducial" -variable Endoscopic(sinkButton,on) -indicatoron 0 } $Gui(WBA)
    TooltipAdd  $f.lsinkSel "You can select an existing fiducial by pressing this
    button and then selecting the fiducial by pointing at it 
    and pressing the 'q' key."
    set Endoscopic(sinkLabel) $f.lsink2
    pack $f.lsink $f.lsink2 $f.lsinkSel -side left 
    set f $Endoscopic(tabbedFrame).fAutomatic.fStep22.fRow6
    eval {label $f.lTitle -text "(C):"} $Gui(WLA)
    DevAddButton $f.bauto "Extract Centerline" PathPlanningExtractCenterline
    pack $f.lTitle $f.bauto -side left -padx 2


    set f $Endoscopic(tabbedFrame).fAutomatic.fStep3
    eval {label $f.lTitle -text "Step III. "} $Gui(WTA)
    eval {button $f.bpop -text "Show Fly Through Panel" -command "EndoscopicShowFlyThroughPopUp"} $Gui(WBA)
    pack $f.lTitle $f.bpop -side left -padx 2





    #-------------------------------------------
    # Path Frame: Advanced
    #-------------------------------------------
    set f $Endoscopic(tabbedFrame).fAdvanced
    set f $Endoscopic(tabbedFrame).fAdvanced
    frame $f.fTitle   -bg $Gui(activeWorkspace) 
    frame $f.fStep1   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep2   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep3   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep4   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fTitle $f.fStep1 $f.fStep2 $f.fStep3 $f.fStep4  -side top -pady 2     

    set f $Endoscopic(tabbedFrame).fAdvanced.fTitle
    set text "Distance Map parameters:"
    DevAddLabel $f.linfo $text WLA
    pack $f.linfo -side top

    set f $Endoscopic(tabbedFrame).fAdvanced.fStep1
    set PathPlanning(voxelSize) 1
    eval {label $f.lvs -text "VoxelSize: $PathPlanning(voxelSize)"} $Gui(WLA)
    eval {entry $f.vsWidth -width 5 -textvariable PathPlanning(voxelSize)} $Gui(WEA)
    bind $f.vsWidth <Return>   "PathPlanningSetVoxelSize"

    pack $f.lvs $f.vsWidth -side top -padx 5 -pady 5

    set f $Endoscopic(tabbedFrame).fAdvanced.fStep2
    set PathPlanning(dist,maxDistance) 5000
    eval {label $f.lmd -text "Max Dist: $PathPlanning(dist,maxDistance)"} $Gui(WLA)
    eval {entry $f.emd -width 5 -textvariable PathPlanning(dist,maxDistance)} $Gui(WEA)
    bind  $f.emd <Return>   "PathPlanningSetMaximumDistance"
    pack $f.lmd $f.emd -side top -padx 5 -pady 5

    set f $Endoscopic(tabbedFrame).fAdvanced.fStep3

    set text "Visualization plane offset:"
    DevAddLabel $f.lintro $text WLA
    pack $f.lintro -side top

    eval {entry $f.eOffset -width 4 -textvariable Endoscopic(planeoffset)} $Gui(WEA)
    bind $f.eOffset <Return>   "PathPlanningSetPlaneOffset"
    bind $f.eOffset <FocusOut> "PathPlanningSetPlaneOffset"

    eval {scale $f.sOffset -from 0 -to 1000 \
        -variable Endoscopic(planeoffset) -length 160 -resolution 1.0 -command \
        "PathPlanningSetPlaneOffset"} $Gui(WSA) 

    pack $f.sOffset $f.eOffset -side right -anchor w -padx 2 -pady 0

    set f $Endoscopic(tabbedFrame).fAdvanced.fStep4

    eval {button $f.bvisVol -text "Visualize LabelMap" -command "PathPlanningVisualizeMaps labelMapFilter"} $Gui(WBA)
    eval {button $f.bvisDist -text "Visualize DistanceMap" -command "PathPlanningVisualizeMaps dist"} $Gui(WBA)

    eval {button $f.bexp -text "Use exponential decrease" -command "set PathPlanning(useLinear) 0; set PathPlanning(useExponential) 1; set PathPlanning(useSquared) 0"} $Gui(WBA)
    eval {button $f.bsq -text "Use squared decrease" -command "set PathPlanning(useLinear) 0; set PathPlanning(useExponential) 0; set PathPlanning(useSquared) 1"} $Gui(WBA)
    eval {button $f.blin -text "Use linear decrease" -command "set PathPlanning(useLinear) 1; set PathPlanning(useSquared) 0; set PathPlanning(useExponential) 0"} $Gui(WBA)
    pack $f.bexp $f.bsq $f.blin $f.bvisVol $f.bvisDist -side top

    #set f $Endoscopic(tabbedFrame).fAdvanced.fStep4
    #eval {button $f.bpop -text "Show Fly Through Panel" -command "EndoscopicShowFlyThroughPopUp"} $Gui(WBA)
    #pack $f.bpop



    #-------------------------------------------
    # Path->Bot->Vis frame
    #-------------------------------------------
    #set f $fPath.fBot.fVis

    # Compute path
#        eval {label $f.lTitle -text "You can create a Random Path to \n play with Fly-Thru options:"} $Gui(WTA)
 #       grid $f.lTitle -padx 1 -pady 1 -columnspan 2

#    eval {button $f.cRandPath \
 #       -text "New random path" -width 16 -command "EndoscopicComputeRandomPath; Render3D"} $Gui(WBA) {-bg $Endoscopic(path,rColor)}           

  #  eval {button $f.dRandPath \
   #     -text "Delete path" -width 14 -command "EndoscopicDeletePath; Render3D"} $Gui(WBA) {-bg $Endoscopic(path,rColor)}           
    
 #   eval {checkbutton $f.rPath \
  #      -text "RollerCoaster" -variable Endoscopic(path,rollerCoaster) -width 12 -indicatoron 0 -command "Render3D"} $Gui(WBA) {-bg $Endoscopic(path,rColor)}             
    
 #   eval {checkbutton $f.sPath \
  #      -text "Show Path" -variable Endoscopic(path,showPath) -width 12 -indicatoron 0 -command "EndoscopicShowPath; Render3D"} $Gui(WBA) {-bg $Endoscopic(path,rColor)}             
  #  grid $f.cRandPath $f.dRandPath -padx 0 -pady $Gui(pad)
   # #grid $f.rPath $f.sPath -padx 0 -pady $Gui(pad)
  #  grid $f.sPath -padx 0 -pady $Gui(pad)


    #-------------------------------------------
    # Advanced frame
    #-------------------------------------------
    set fAdvanced $Module(Endoscopic,fAdvanced)
    set f $fAdvanced

    frame $f.fTop -bg $Gui(activeWorkspace) 
    frame $f.fMid -bg $Gui(activeWorkspace) 
        pack $f.fTop $f.fMid -side top -pady 0 -padx 0 -fill x

    #-------------------------------------------
    # Advanced->Top frame
    #-------------------------------------------
    set f $fAdvanced.fTop

    frame $f.fVis     -bg $Gui(activeWorkspace)
    frame $f.fTitle   -bg $Gui(activeWorkspace)
    frame $f.fPos     -bg $Gui(activeWorkspace)
    pack $f.fVis $f.fTitle $f.fPos \
        -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Advanced->Top->Vis frame
    #-------------------------------------------
    set f $fAdvanced.fTop.fVis

    eval {label $f.lV -text Visibility} $Gui(WLA)
    eval {label $f.lO -text Color} $Gui(WLA)
        eval {label $f.lS -text "  Size"} $Gui(WLA)
    
    grid $f.lV $f.lO $f.lS -pady 2 -padx 2

    # Done in EndoscopicCreateAdvancedGUI

    EndoscopicCreateAdvancedGUI $f cam   visible   noColor size
    EndoscopicCreateAdvancedGUI $f Lens  notvisible color
    EndoscopicCreateAdvancedGUI $f Box   notvisible color
    EndoscopicCreateAdvancedGUI $f fp    visible    color
    EndoscopicCreateAdvancedGUI $f gyro    visible   noColor size

    #-------------------------------------------
    # Advanced->Mid frame
    #-------------------------------------------
    set f $fAdvanced.fMid

    frame $f.fAngle    -bg $Gui(activeWorkspace)
    frame $f.fTitle     -bg $Gui(activeWorkspace)
    frame $f.fToggle     -bg $Gui(activeWorkspace)
    frame $f.fVis     -bg $Gui(activeWorkspace)
    
    pack $f.fAngle $f.fToggle $f.fVis  -side top -padx 1 -pady 1
    
    #-------------------------------------------
    # Advanced->Mid->Angle frame
    #-------------------------------------------
    set f $fAdvanced.fMid.fAngle

    EndoscopicCreateLabelAndSlider $f l2 2 "Lens Angle" "Angle" horizontal 0 360 110 Endoscopic(cam,AngleStr) "EndoscopicSetCameraViewAngle" 5 90


    #-------------------------------------------
    # Advanced->Mid->Vis frame
    #-------------------------------------------
    
    set f $fAdvanced.fMid.fVis
    
    EndoscopicCreateCheckButton $f.cmodels Endoscopic(ModelsVisibilityInside) "Show Inside Models"  "EndoscopicSetModelsVisibilityInside"

    
    pack $f.cmodels

    # reinstating the show path toggle button
    EndoscopicCreateCheckButton $f.cPath Endoscopic(path,showPath) "Show Path" "EndoscopicShowPath; Render3D"
    pack $f.cPath

    # The following GUI commands are commented out because collision detection has not
    # been tested since the upgrade from slicer1 to slicer2 and the sunchronized fly-through
    # code is for internal research only at this point.

    #-------------------------------------------
    # Advanced->Mid->Toggle frame
    #-------------------------------------------

    #set f $fAdvanced.fMid.fToggle
    

    
    #eval {label $f.l -height 2 -text "Collision Detection:"} $Gui(WTA)
    #eval {menubutton $f.fMBtns -text "off" -menu $f.fMBtns.fMenu} $Gui(WMBA)  
    #eval {menu $f.fMBtns.fMenu} $Gui(WMA) 
    
    #$f.fMBtns.fMenu add command -label "off" -command {EndoscopicSetCollision 0;}
    #$f.fMBtns.fMenu add command -label "on" -command {EndoscopicSetCollision 1}
    
    #eval {label $f.l2 -height 2 -text "distance: 0"} $Gui(WTA)
    #set Endoscopic(collMenu) $f.fMBtns
    #set Endoscopic(collDistLabel) $f.l2
    #grid $f.l $f.fMBtns $f.l2 -padx 1 -pady 1
    


    #-------------------------------------------
    # Sync frame
    #-------------------------------------------
    #set fSync $Module(Endoscopic,fSync)
    #set f $fSync
    
    #frame $f.fTop -bg $Gui(activeWorkspace) 
    #frame $f.fBot -bg $Gui(activeWorkspace) 
    #    pack $f.fTop $f.fBot -side top -pady 0 -padx 0 -fill x

    #-------------------------------------------
    # Advanced->Top frame
    #-------------------------------------------
    #set f $fSync.fTop
    #eval {checkbutton $f.bcreate -text "Create sync window" -variable Endoscopic(syncOn) -indicatoron 0 -command "EndoscopicAddSyncScreen; Render3D"} $Gui(WCA)
    #eval {button $f.fly -text "Synchronized Fly-through" -command "EndoscopicFlyThroughPath $Module(endoscopicRenderers) {0 1}"} $Gui(WBA)
    #eval {button $f.reset -text "Reset Fly-through" -command "EndoscopicFlyThroughPath $Module(endoscopicRenderers) {0 1}"} $Gui(WBA)
    
    #pack $f.bcreate $f.fly $f.reset
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicShowFlyThroughPopUp
# Build, if necessary, and display the flythrough popup.
# .ARGS
# int x horizontal position of popup, defaults to 100
# int y vertical position of popup, defaults to 100
# .END
#-------------------------------------------------------------------------------
proc EndoscopicShowFlyThroughPopUp {{x 100} {y 100}} {
    global Gui Endoscopic 
    
    # Recreate popup if user killed it
    if {[winfo exists $Gui(wEndoscopic)] == 0} {
        EndoscopicBuildFlyThroughGUI
    }
    ShowPopup $Gui(wEndoscopic) $x $y
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicExecutePathTab 
# Executes command that is selected in Path Menu Selection
# .ARGS
# str command the command to execute
# .END
#-------------------------------------------------------------------------------
proc EndoscopicExecutePathTab {command} {
    global Endoscopic
    raise $Endoscopic(tabbedFrame).f$command
    focus $Endoscopic(tabbedFrame).f$command
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicBuildFlyThroughGUI
# Build the fly through gui window, .wEndoFlyThrough
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicBuildFlyThroughGUI {} {
    global Gui Endoscopic
    
    # in case 
    set Endoscopic(activeCam) [endoscopicScreen GetActiveCamera]

    #-------------------------------------------
    # Labels Popup Window
    #-------------------------------------------
    set w .wEndoFlyThrough
    set Gui(wEndoscopic) $w
    toplevel $w -class Dialog -bg $Gui(inactiveWorkspace)
    wm title $w "Endoscopic Module: Fly-Through Panel"
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW "wm withdraw $w"
    if {$Gui(pc) == "0"} {
        wm transient $w .
    }
    wm withdraw $w

    # Frames
    frame $w.fTop -bg $Gui(activeWorkspace) -bd 2 -relief raised
    frame $w.fClose -bg $Gui(inactiveWorkspace)
    pack $w.fTop $w.fClose \
        -side top -pady $Gui(pad) -padx $Gui(pad)

    #-------------------------------------------
    # Endoscopic->Close frame
    #-------------------------------------------
    set f $w.fClose
    
    eval {button $f.bCancel -text "Close Window"  \
        -command "wm withdraw $w"} $Gui(WBA)
    
    pack $f.bCancel -side left -padx $Gui(pad)
    
    #-------------------------------------------
    # Labels->Top frame
    #-------------------------------------------
    set f $w.fTop

    frame $f.fSelect     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fFly     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fJump     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fSpeed     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fInterp     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fSli     -bg $Gui(activeWorkspace) -relief groove -bd 2
    
    pack  $f.fSelect $f.fFly $f.fJump $f.fStep $f.fSpeed $f.fInterp $f.fSli \
        -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Path->Top->Select frame
    #-------------------------------------------
    
    set f $w.fTop.fSelect
    # menu to select an active path
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.mbActive -side top -padx $Gui(pad) -pady 0 

    set Endoscopic(mbPath4Fly) $f.mbActive
    lappend Endoscopic(mPath4Fly) $f.mbActive.m
    
    #-------------------------------------------
    # Path->Top->Fly frame
    #-------------------------------------------
    set f $w.fTop.fFly
    # Compute path
    eval {button $f.fPath \
        -text "Fly-Thru"  -width 8 -command {EndoscopicFlyThroughPath $Endoscopic(activeCam) $Endoscopic(path,activeId); Render3D}} $Gui(WMBA) {-bg $Endoscopic(path,sColor)}   

    eval {button $f.fReset \
        -text "Reset"  -width 8  -command {EndoscopicResetPath $Endoscopic(activeCam) $Endoscopic(path,activeId); Render3D}} $Gui(WMBA) {-bg $Endoscopic(path,sColor)}   

    eval {button $f.fStop \
        -text "Stop" -width 6 -command "EndoscopicStopPath; Render3D"} $Gui(WMBA) {-bg $Endoscopic(path,sColor)}   

    #foreach value "Forward Backward" width "9 11" {
    #    eval {radiobutton $f.r$value -width $width \
    #        -text "$value" -value "$value" -variable Endoscopic(flyDirection)\
    #        -indicatoron 0 -command "EndoscopicSetFlyDirection $value; Render3D"} $Gui(WMBA) {-bg $Endoscopic(path,sColor)} {-selectcolor $Endoscopic(path,cColor)}  
    #}       
    #$f.rForward select

    grid $f.fPath $f.fReset $f.fStop -padx $Gui(pad) -pady $Gui(pad)
    #grid $f.rForward $f.rBackward -padx $Gui(pad) -pady $Gui(pad)
 
    #-------------------------------------------
    # Path->Top->Jump frame
    #-------------------------------------------
    set f $w.fTop.fJump
    
    eval {label $f.ljump -text "Target#"} $Gui(WLA)

    eval {entry $f.ejump \
        -textvariable Endoscopic(selectedTarget) -width 4} $Gui(WEA) {-bg $Endoscopic(path,sColor)}
    bind $f.ejump <Return> {EndoscopicSelectTarget $Endoscopic(selectedTarget)}
    
    eval {button $f.fjump -text " >>> " -width 6  -command "EndoscopicSelectNextTarget"} $Gui(WMBA)
    
    eval {button $f.bjump -text " <<< " -width 6  -command "EndoscopicSelectPreviousTarget"} $Gui(WMBA)
    
    pack $f.bjump $f.ljump $f.ejump $f.fjump -side left -padx $Gui(pad) -pady $Gui(pad)

                           
    #-------------------------------------------
    # Path->Top->Step frame
    #-------------------------------------------
    set f $w.fTop.fStep

    # Position Sliders

    eval {label $f.lstep -text "Frame:"} $Gui(WLA)

    eval {entry $f.estep \
        -textvariable Endoscopic(path,stepStr) -width 4} $Gui(WEA) {-bg $Endoscopic(path,sColor)}
    bind $f.estep <Return> \
        {EndoscopicSetPathFrame $Endoscopic(activeCam) $Endoscopic(path,activeId); Render3D}
    
    eval {scale $f.sstep -from 0 -to 400 -length 100 \
            -variable Endoscopic(path,stepStr) \
        -command {EndoscopicSetPathFrame $Endoscopic(activeCam) $Endoscopic(path,activeId); Render3D}\
            -resolution 1} $Gui(WSA) {-troughcolor $Endoscopic(path,sColor)}

    set Endoscopic(path,stepScale) $f.sstep
    
    # default value
    $f.sstep set 0
    
    # Grid
    grid $f.lstep $f.estep $f.sstep -padx $Gui(pad) -pady $Gui(pad)
        grid $f.lstep -sticky e

    #-------------------------------------------
    # Path->Top->Speed frame
    #-------------------------------------------
    
    set f $w.fTop.fSpeed

    # Position Sliders

    eval {label $f.lspeed -text "Speed:"} $Gui(WLA)

    eval {entry $f.espeed \
        -textvariable Endoscopic(path,speedStr) -width 4} $Gui(WEA) {-bg $Endoscopic(path,sColor)}
    bind $f.espeed <Return> \
        "EndoscopicSetSpeed; Render3D"
    
    eval {scale $f.sspeed -from 1 -to 20 -length 100 \
            -variable Endoscopic(path,speedStr) \
            -command "EndoscopicSetSpeed; Render3D"\
            -resolution 1} $Gui(WSA) {-troughcolor $Endoscopic(path,sColor)}

    set Endoscopic(path,speedScale) $f.sspeed
    
    # default color values for the lens sliders
    $f.sspeed set 1

# Grid
    grid $f.lspeed $f.espeed $f.sspeed 
    grid $f.lspeed -sticky e

    #-------------------------------------------
    # Path->Top->Interp frame
    #-------------------------------------------
    set f $w.fTop.fInterp
    
    eval {label $f.linterp -text "You can change the number of \n interpolated points per mm \n (a higher number of points per mm means \n that the speed will be decreased):"} $Gui(WLA)
    eval {entry $f.einterp \
        -textvariable Endoscopic(path,interpolationStr) -width 4} $Gui(WEA) {-bg $Endoscopic(path,sColor)}
    bind $f.einterp <Return> \
        {MainUpdateMRML; Render3D}
    pack $f.linterp $f.einterp -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Path->Bot->Sli frame
    #-------------------------------------------
    set f  $w.fTop.fSli

    # set the camera or focal point to be the slice driver
    
    eval {label $f.lTitle -text "The Camera or Focal Point can Drive \n the Slices"} $Gui(WTA)
    grid $f.lTitle -padx 1 -pady 1 -columnspan 2

    eval {label $f.lDriver -text "Driver:"} $Gui(WTA)

    eval {menubutton $f.mbDriver -text "User" \
            -menu $f.mbDriver.m -width 12 -relief raised \
            -bd 2} $Gui(WMBA) {-bg $Endoscopic(path,eColor)}
    set Endoscopic(mDriver) $f.mbDriver.m
    set Endoscopic(mbDriver) $f.mbDriver
    eval {menu $f.mbDriver.m} $Gui(WMA) {-bg $Endoscopic(path,eColor)}
    foreach item "User Camera FocalPoint Intersection" {
            $Endoscopic(mDriver) add command -label $item \
                -command "EndoscopicSetSliceDriver $item"
    }

    grid $f.lDriver $f.mbDriver -padx $Gui(pad) -pady $Gui(pad)    
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateLabelAndSlider
# Create a label and slider on the given parent frame.
# 
# .ARGS
# framepath f 
# str labelName 
# int labelHeight 
# str labelText 
# str sliderName 
# str orient 
# int from 
# int to 
# int length 
# str variable 
# str commandString 
# int entryWidth 
# int defaultSliderValue
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateLabelAndSlider {f labelName labelHeight labelText sliderName orient from to length variable commandString entryWidth defaultSliderValue} {

    global Gui Model
    eval {label $f.$labelName -height $labelHeight -text $labelText} $Gui(WTA)

    # Sliders        
    eval {scale $f.s$sliderName -from $from -to $to -length $length \
        -variable $variable -orient vertical\
        -command "$commandString; Render3D" \
        -resolution .1} $Gui(WSA)

    eval {entry $f.e$sliderName \
        -textvariable $variable -width $entryWidth} $Gui(WEA)
    bind $f.e$sliderName <Return> \
        "$commandString; Render3D"
    #bind $f.e$sliderName <FocusOut> \
    #    "$commandString; Render3D"
    
    # Grid
    grid $f.$labelName $f.e$sliderName $f.s$sliderName -padx 0 -pady 0
    
    # default value for the slider
    $f.s$sliderName set $defaultSliderValue
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateCheckButton
# Create a check button.
# 
# .ARGS
# str ButtonName 
# str VariableName 
# str Message 
# str Command 
# int Indicatoron optional, defaults to 0
# int Width optional, defaults to length of Message
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateCheckButton {ButtonName VariableName Message Command {Indicatoron 0} {Width 0} } {
    global Gui
    if {$Width == 0 } {
        set Width [expr [string length $Message]]
    }
    eval  {checkbutton $ButtonName -variable $VariableName -text \
    $Message -width $Width -indicatoron $Indicatoron -command $Command } $Gui(WCA)
} 

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetVisibility
# Set the visibility of endoscopic actors.
# .ARGS
# str a either gyro or the actor id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetVisibility {a} {

    global Endoscopic

    if {$a == "gyro"} {
        set Endoscopic(gyro,use) $Endoscopic($a,visibility)
        EndoscopicUseGyro 
    } else {
        Endoscopic($a,actor) SetVisibility $Endoscopic($a,visibility)
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateAdvancedGUI
# Create the advanced gui tab.
# .ARGS
# windowpath f where to create elements
# int a endosopic id
# str vis if visible add a visibility button, optional, defaults to empty string
# str col color, optional, defaults to empty string
# str size optional, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateAdvancedGUI {f a {vis ""} {col ""} {size ""}} {
    global Gui Endoscopic Color Advanced

    
    # Name / Visible only if vis is not empty
    if {$vis == "visible"} {
        eval {checkbutton $f.c$a \
            -text $Endoscopic($a,name) -wraplength 65 -variable Endoscopic($a,visibility) \
            -width 11 -indicatoron 0\
            -command "EndoscopicSetVisibility $a; Render3D"} $Gui(WCA)
    } else {
        eval {label $f.c$a -text $Endoscopic($a,name)} $Gui(WLA)
    }

    # Change colors
    if {$col == "color"} {
        eval {button $f.b$a \
            -width 1 -command "EndoscopicSetActive $a $f.b$a; ShowColors EndoscopicPopupCallback; Render3D" \
            -background [MakeColorNormalized $Endoscopic($a,color)]}
    } else {
        eval {label $f.b$a -text " " } $Gui(WLA)
    }
    
    if {$size == "size"} {
    
        eval {entry $f.e$a -textvariable Endoscopic($a,size) -width 3} $Gui(WEA)
        bind $f.e$a  <Return> "EndoscopicSetSize $a"
        eval {scale $f.s$a -from 0.0 -to $Endoscopic($a,size) -length 70 \
            -variable Endoscopic($a,size) \
            -command "EndoscopicSetSize $a; Render3D" \
            -resolution 0.01} $Gui(WSA) {-sliderlength 10 }    
        grid $f.c$a $f.b$a $f.e$a $f.s$a -pady 0 -padx 0        
    } else {
        grid $f.c$a $f.b$a -pady 0 -padx 0        
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetActive
# Set the active actor and button.
# .ARGS
# int a actor id
# int b button id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetActive {a b} {

    global Advanced

    set Advanced(ActiveActor) $a
    set Advanced(ActiveButton) $b 
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicPopupCallback
# Get the active actor and set it's properties.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicPopupCallback {} {
    global Label Endoscopic Color Gui Advanced

    set name $Label(name) 

    set a $Advanced(ActiveActor)

    # Use second color by default
    set color [lindex $Color(idList) 1]

    foreach c $Color(idList) {
        if {[Color($c,node) GetName] == $name} {
            set color $c
        }
    }

    [Endoscopic($a,actor) GetProperty] SetAmbient    [Color($color,node) GetAmbient]
    [Endoscopic($a,actor) GetProperty] SetDiffuse    [Color($color,node) GetDiffuse]
    [Endoscopic($a,actor) GetProperty] SetSpecular   [Color($color,node) GetSpecular]
    [Endoscopic($a,actor) GetProperty] SetSpecularPower [Color($color,node) GetPower]
    eval [Endoscopic($a,actor) GetProperty] SetColor    [Color($color,node) GetDiffuseColor]

    set Endoscopic($a,color) [Color($color,node) GetDiffuseColor]

    # change the color of the button on the Advanced GUI
    $Advanced(ActiveButton) configure -background [MakeColorNormalized [[Endoscopic($a,actor) GetProperty] GetColor]]

    if {$Advanced(ActiveActor) == "Box"} {
        
        [Endoscopic(Box2,actor) GetProperty] SetAmbient    [Color($color,node) GetAmbient]
        [Endoscopic(Box2,actor) GetProperty] SetDiffuse    [Color($color,node) GetDiffuse]
        [Endoscopic(Box2,actor) GetProperty] SetSpecular   [Color($color,node) GetSpecular]
        [Endoscopic(Box2,actor) GetProperty] SetSpecularPower [Color($color,node) GetPower]
        eval [Endoscopic(Box2,actor) GetProperty] SetColor    [Color($color,node) GetDiffuseColor]

    }
    Render3D
}

##############################################################################
#
#        PART 3: Selection of actors through key/mouse
#
#############################################################################

#-------------------------------------------------------------------------------
# .PROC EndoscopicUseGyro
# If using it, set opacity to 1, otherwise 0, and rerender
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUseGyro {} {
    global Endoscopic
    
    if { $Endoscopic(gyro,use) == 1} {
        foreach XX "X Y Z" {
            [Endoscopic(gyro,${XX}actor) GetProperty] SetOpacity 1
        }
        EndoscopicSetPickable Endoscopic(gyro,actor) 1
    } else {
        foreach XX "X Y Z" {
            [Endoscopic(gyro,${XX}actor) GetProperty] SetOpacity 0
        }
        EndoscopicSetPickable Endoscopic(gyro,actor) 0
    }
    Render3D
}


#############################################################################
#
#      PART 4 : Endoscope movement
#
#############################################################################

#-------------------------------------------------------------------------------
# .PROC EndoscopicGyroMotion
# Get the locatin and orientatin of the gyro and set sliders
# .ARGS
# str actor name of actor
# float angle 
# float dotprod 
# float unitX 
# float unitY 
# float unitZ
# .END
#-------------------------------------------------------------------------------
proc EndoscopicGyroMotion {actor angle dotprod unitX unitY unitZ} {
    
    global Endoscopic
    if {$actor == "Endoscopic(gyro,actor)"} {
        # get the position of the gyro and set the sliders
        set cam_mat [Endoscopic(cam,actor) GetMatrix]   
        set Endoscopic(cam,xStr,old) [$cam_mat GetElement 0 3] 
        set Endoscopic(cam,yStr,old) [$cam_mat GetElement 1 3] 
        set Endoscopic(cam,zStr,old) [$cam_mat GetElement 2 3] 
        set Endoscopic(cam,xStr) [$cam_mat GetElement 0 3] 
        set Endoscopic(cam,yStr) [$cam_mat GetElement 1 3] 
        set Endoscopic(cam,zStr) [$cam_mat GetElement 2 3] 

        # get the orientation of the gyro and set the sliders 
        set or [Endoscopic(gyro,actor) GetOrientation]
        set Endoscopic(cam,rxStr,old) [lindex $or 0]
        set Endoscopic(cam,ryStr,old) [lindex $or 1]
        set Endoscopic(cam,rzStr,old) [lindex $or 2]
        set Endoscopic(cam,rxStr) [lindex $or 0]
        set Endoscopic(cam,ryStr) [lindex $or 1]
        set Endoscopic(cam,rzStr) [lindex $or 2]

        EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)
        EndoscopicCheckDriver $Endoscopic(activeCam)
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetGyroOrientation
# Set the gyro orientation
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetGyroOrientation {} {
    global Endoscopic
    if {$Endoscopic(cam,axis) == "relative"} {
        vtkTransform tmp
        tmp SetMatrix [Endoscopic(cam,actor) GetMatrix] 
        eval Endoscopic(gyro,actor) SetOrientation [tmp GetOrientation]
        tmp Delete
        Endoscopic(cam,actor) SetOrientation 0 0 0
    } elseif {$Endoscopic(cam,axis) == "absolute"} {
        set or [Endoscopic(gyro,actor) GetOrientation]
        Endoscopic(gyro,actor) SetOrientation 0 0 0
        eval Endoscopic(cam,actor) SetOrientation $or
    }       
}
    
#-------------------------------------------------------------------------------
# .PROC EndoscopicSetWorldPosition
# Set the position of the gyro actor, and sliders
# .ARGS
# float x new x position for the gyro actor
# float y new y position for the gyro actor
# float z new z position for the gyro actor
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetWorldPosition {x y z} {
    global Endoscopic

    # reset the sliders
    set Endoscopic(cam,xStr) $x
    set Endoscopic(cam,yStr) $y
    set Endoscopic(cam,zStr) $z
    set Endoscopic(cam,xStr,old) $x
    set Endoscopic(cam,yStr,old) $y
    set Endoscopic(cam,zStr,old) $z
    Endoscopic(gyro,actor) SetPosition $x $y $z
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetWorldOrientation
# Set the orientation of the gyro actor
# .ARGS
# float rx
# float ry
# float rz
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetWorldOrientation {rx ry rz} {
    global Endoscopic


    # reset the sliders
    set Endoscopic(cam,rxStr) $rx
    set Endoscopic(cam,ryStr) $ry
    set Endoscopic(cam,rzStr) $rz
    set Endoscopic(cam,rxStr,old) $rx
    set Endoscopic(cam,ryStr,old) $ry
    set Endoscopic(cam,rzStr,old) $rz
    Endoscopic(gyro,actor) SetOrientation $rx $ry $rz
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetCameraPosition
#  This is called when the position sliders are updated. We use the values
#  stored in the slider variables to update the position of the endoscope 
# .ARGS
# str value optional, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetCameraPosition {{value ""}} {
    global Endoscopic View Endoscopic
    
    set collision 0
    
    # get the View plane of the virtual camera because we want to move 
    # in and out along that plane
    set l [$Endoscopic(activeCam) GetViewPlaneNormal]
    set IO(x) [expr -[lindex $l 0]]
    set IO(y) [expr -[lindex $l 1]] 
    set IO(z) [expr -[lindex $l 2]]
    
    
    # get the View up of the virtual camera because we want to move up
    # and down along that plane (and reverse it)
    set l [$Endoscopic(activeCam) GetViewUp]
    set Up(x) [lindex $l 0]
    set Up(y) [lindex $l 1]
    set Up(z) [lindex $l 2]
    
    
    # cross Up and IO to get the vector LR (to slide left and right)
    # LR = Up x IO

    #Cross LR Up IO 
    Cross LR IO Up 
    Normalize LR

    
    # if we want to go along the camera's own axis (Relative mode)
    # Endoscopic(cam,XXStr) is set by the slider
    # Endoscopic(cam,XXStr,old) is saved at the end of this proc
    
    # for the next time 
    if { $Endoscopic(cam,axis) == "relative" } {
        
        # this matrix tells us the current position of the cam actor
        set cam_mat [Endoscopic(cam,actor) GetMatrix]   
        # stepXX is the amount to move along axis XX
        set stepX [expr $Endoscopic(cam,xStr,old) - $Endoscopic(cam,xStr)]
        set stepY [expr $Endoscopic(cam,yStr,old) - $Endoscopic(cam,yStr)]
        set stepZ [expr $Endoscopic(cam,zStr,old) - $Endoscopic(cam,zStr)]
        
        set Endoscopic(cam,x) [expr [$cam_mat GetElement 0 3] + \
            $stepX*$LR(x) + $stepY * $IO(x) + $stepZ * $Up(x)] 
        set Endoscopic(cam,y) [expr  [$cam_mat GetElement 1 3] + \
            $stepX * $LR(y) + $stepY * $IO(y) + $stepZ * $Up(y)] 
        set Endoscopic(cam,z) [expr  [$cam_mat GetElement 2 3] + \
            $stepX * $LR(z) +  $stepY * $IO(z) +  $stepZ * $Up(z)] 
    
    } elseif { $Endoscopic(cam,axis) == "absolute" } {
        set Endoscopic(cam,x) $Endoscopic(cam,xStr)
        set Endoscopic(cam,y) $Endoscopic(cam,yStr)
        set Endoscopic(cam,z) $Endoscopic(cam,zStr)
    }
    
    # store current slider
    set Endoscopic(cam,xStr,old) $Endoscopic(cam,xStr)
    set Endoscopic(cam,yStr,old) $Endoscopic(cam,yStr)
    set Endoscopic(cam,zStr,old) $Endoscopic(cam,zStr)

    # set position of actor gyro (that will in turn set the position
    # of the camera and fp actor since their user matrix is linked to
    # the matrix of the gyro
    Endoscopic(gyro,actor) SetPosition $Endoscopic(cam,x) $Endoscopic(cam,y) $Endoscopic(cam,z)
    
    #################################
    # should not be needed anymore
    #Endoscopic(cam,actor) SetPosition $Endoscopic(cam,x) $Endoscopic(cam,y) $Endoscopic(cam,z)
    #Endoscopic(fp,actor) SetPosition $Endoscopic(fp,x) $Endoscopic(fp,y) $Endoscopic(fp,z)
    ##################################
    # set position of virtual camera
    EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)

    #*******************************************************************
    #
    # STEP 3: if the user decided to have the camera drive the slice, 
    #         then do it!
    #
    #*******************************************************************
    EndoscopicCheckDriver $Endoscopic(activeCam)

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetCameraPosition
# Reset the endoscopic camera to the origin
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetCameraPosition {} {
    global Endoscopic

    EndoscopicSetWorldPosition 0 0 0
    # in case the camera's model matrix is not the identity
    Endoscopic(cam,actor) SetPosition 0 0 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetCameraDirection
# Set the endoscopic camera direction.
# .ARGS
# str value one of rx, ry, rz, optional, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetCameraDirection {{value ""}} {
    global Endoscopic View Model

    if {$Endoscopic(cam,axis) == "absolute"} {
    
    #Endoscopic(gyro,actor) SetOrientation $Endoscopic(cam,rxStr) $Endoscopic(cam,ryStr) $Endoscopic(cam,rzStr) 
    if {$value == "rx"} {
        set temprx [expr $Endoscopic(cam,rxStr) - $Endoscopic(cam,rxStr,old)]
        set Endoscopic(cam,rxStr,old) $Endoscopic(cam,rxStr)
        Endoscopic(gyro,actor) RotateWXYZ $temprx 1 0 0
    } elseif {$value == "ry"} {
        set tempry [expr $Endoscopic(cam,ryStr) - $Endoscopic(cam,ryStr,old)]
        set Endoscopic(cam,ryStr,old) $Endoscopic(cam,ryStr)
        Endoscopic(gyro,actor) RotateWXYZ $tempry 0 1 0
        #$Endoscopic(activeCam) Roll $tempry
    } elseif {$value == "rz"} {
        set temprz [expr $Endoscopic(cam,rzStr) - $Endoscopic(cam,rzStr,old)]
        set Endoscopic(cam,rzStr,old) $Endoscopic(cam,rzStr)
        Endoscopic(gyro,actor) RotateWXYZ $temprz 0 0 1
    }
    #eval Endoscopic(gyro,actor) SetOrientation [Endoscopic(gyro,actor) GetOrientation]        
    
    } elseif {$Endoscopic(cam,axis) == "relative"} {
        if {$value == "rx"} {
            set temprx [expr $Endoscopic(cam,rxStr) - $Endoscopic(cam,rxStr,old)]
            set Endoscopic(cam,rxStr,old) $Endoscopic(cam,rxStr)
            Endoscopic(gyro,actor) RotateX $temprx
        } elseif {$value == "ry"} {
            set tempry [expr $Endoscopic(cam,ryStr) - $Endoscopic(cam,ryStr,old)]
            set Endoscopic(cam,ryStr,old) $Endoscopic(cam,ryStr)
            Endoscopic(gyro,actor) RotateY $tempry
        } elseif {$value == "rz"} {
            set temprz [expr $Endoscopic(cam,rzStr) - $Endoscopic(cam,rzStr,old)]
            set Endoscopic(cam,rzStr,old) $Endoscopic(cam,rzStr)
            Endoscopic(gyro,actor) RotateZ $temprz
        }
    }
    
    #*******************************************************************
    #
    # if the user decided to have the camera drive the slice, 
    #         then do it!
    #
    #*******************************************************************
    EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)
    EndoscopicCheckDriver $Endoscopic(activeCam)  

   
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetCameraDirection
# Reset the endo camera to default rotation and view.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetCameraDirection {} {
    global Endoscopic 

    # we reset the rotation around the absolute y axis
    set Endoscopic(cam,yRotation) 0
    set Endoscopic(cam,viewUpX) 0
    set Endoscopic(cam,viewUpY) 0
    set Endoscopic(cam,viewUpZ) 1

    EndoscopicSetWorldOrientation 0 0 0 
    # in case the camera's model matrix is not the identity
    Endoscopic(cam,actor) SetOrientation 0 0 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateActorFromVirtualEndoscope
#  First, set the gyro matrix's orientation based on the virtual camera's matrix.
# Then if the user decided to have the camera drive the slice, do so.
# .ARGS
# str vcam virtual endoscope name
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateActorFromVirtualEndoscope {vcam} {
    global Endoscopic View Path Model
        
    #*********************************************************************
    #
    # STEP 1: set the gyro matrix's orientation based on the virtual
    #         camera's matrix
    #         
    #*********************************************************************
    
    # this doesn't work because the virtual camera is rotated -90 degrees on 
    # the y axis originally, so the overall matrix is not correct (off by 90 degrees)
    #eval Endoscopic(gyro,actor) SetOrientation [$Endoscopic(activeCam) GetOrientation]
    #eval Endoscopic(gyro,actor) SetPosition [$Endoscopic(activeCam) GetPosition]

    # so build the matrix ourselves instead, that way we are sure about it
    vtkMatrix4x4 matrix
   
    set vu [$vcam GetViewUp]
    set vpn [$vcam GetViewPlaneNormal]

    # Uy = ViewPlaneNormal
    set Uy(x) [expr - [lindex $vpn 0]]
    set Uy(y) [expr - [lindex $vpn 1]]
    set Uy(z) [expr - [lindex $vpn 2]]
    # Uz = ViewUp
    set Uz(x) [lindex $vu 0]
    set Uz(y) [lindex $vu 1]
    set Uz(z) [lindex $vu 2]
    # Ux = Uy x Uz
    set Ux(x) [expr $Uy(y)*$Uz(z) - $Uz(y)*$Uy(z)]
    set Ux(y) [expr $Uz(x)*$Uy(z) - $Uy(x)*$Uz(z)]
    set Ux(z) [expr $Uy(x)*$Uz(y) - $Uz(x)*$Uy(y)]
    
    #Ux
    matrix SetElement 0 0 $Ux(x)
    matrix SetElement 1 0 $Ux(y)
    matrix SetElement 2 0 $Ux(z)
    matrix SetElement 3 0 0
    # Uy
    matrix SetElement 0 1 $Uy(x)
    matrix SetElement 1 1 $Uy(y)
    matrix SetElement 2 1 $Uy(z)
    matrix SetElement 3 1 0
    # Uz
    matrix SetElement 0 2 $Uz(x)
    matrix SetElement 1 2 $Uz(y)
    matrix SetElement 2 2 $Uz(z)
    matrix SetElement 3 2 0
    # Right column (position)
    matrix SetElement 0 3 0
    matrix SetElement 1 3 0
    matrix SetElement 2 3 0
    matrix SetElement 3 3 1

    vtkTransform endoscopicTransform
    endoscopicTransform SetMatrix matrix
    set orientation [endoscopicTransform GetOrientation]
    set position [$Endoscopic(activeCam) GetPosition]
    eval Endoscopic(gyro,actor) SetOrientation $orientation
    eval Endoscopic(gyro,actor) SetPosition $position
    endoscopicTransform Delete
    matrix Delete

    # set the sliders
    set Endoscopic(cam,xStr) [lindex $position 0]
    set Endoscopic(cam,yStr) [lindex $position 1]
    set Endoscopic(cam,zStr) [lindex $position 2]
    set Endoscopic(cam,xStr,old) [lindex $position 0]
    set Endoscopic(cam,yStr,old) [lindex $position 1]
    set Endoscopic(cam,zStr,old) [lindex $position 2]

    set Endoscopic(cam,rxStr) [lindex $orientation 0]
    set Endoscopic(cam,ryStr) [lindex $orientation 1]
    set Endoscopic(cam,rzStr) [lindex $orientation 2]
    set Endoscopic(cam,rxStr,old) [lindex $orientation 0]
    set Endoscopic(cam,ryStr,old) [lindex $orientation 1]
    set Endoscopic(cam,rzStr,old) [lindex $orientation 2]
    
    #*******************************************************************
    #
    # STEP 2: if the user decided to have the camera drive the slice, 
    #         then do it!
    #
    #*******************************************************************

    EndoscopicCheckDriver $vcam

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateVirtualEndoscope 
#       Updates the virtual camera's position, orientation and view angle.<br>
#       Calls EndoscopicLightFollowsEndoCamera
# .ARGS
# str vcam name of the virtual endoscope
# str coordList optional, defaults to empty list
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateVirtualEndoscope {vcam {coordList ""}} {
    global Endoscopic Model View Path
    
    #puts "vcam $vcam"
    
    if {$coordList != "" && [llength $coordList] == 6} {
        #puts "in first case"
        # COORDLIST IS NOT EMPTY IF WE WANT TO SET THE VIRTUAL CAMERA ONLY
        # BASED ON INFORMATION ABOUT THE POSITION OF THE ACTOR CAMERA AND
        # ACTOR FOCAL POINT
        # we only have information about the position of the camera and the 
        # focal point. Extrapolate the additional information from that 
        $vcam SetPosition [lindex $coordList 0] [lindex $coordList 1] [expr [lindex $coordList 2] +2]
        $vcam SetFocalPoint [lindex $coordList 3] [lindex $coordList 4] [lindex $coordList 5] 
        # use prior information to prevent the View from flipping at undefined
        # boundary points (i.e when the viewUp and the viewPlaneNormal are 
        # parallel, OrthogonalizeViewUp sometimes produces a viewUp that 
        # flips direction 

        # weird boundary case if user the fp/cam vector is parallel to old
        # view up -- check for that with the dot product

        $vcam SetViewUp $Endoscopic(cam,viewUpX) $Endoscopic(cam,viewUpY) $Endoscopic(cam,viewUpZ)    
        
    } elseif {$coordList == ""} {
        # COORDLIST IS EMPTY IF WE JUST WANT THE VIRTUAL CAMERA TO MIMICK
        # THE CURRENT ACTOR CAMERA
        # we want the virtual camera to be in the same position/orientation 
        # than the endoscope and we have all the information we need
        # so set the position, focal point, and view up (the z unit vector of 
        # the camera actor's orientation [the 3rd column of its world matrix])
        set cam_mat [Endoscopic(cam,actor) GetMatrix]   
        $vcam SetPosition [$cam_mat GetElement 0 3] [$cam_mat GetElement 1 3] [expr [$cam_mat GetElement 2 3] +2]     
        set fp_mat [Endoscopic(fp,actor) GetMatrix]
        $vcam SetFocalPoint [$fp_mat GetElement 0 3] [$fp_mat GetElement 1 3] [$fp_mat GetElement 2 3] 
        $vcam SetViewUp [$cam_mat GetElement 0 2] [$cam_mat GetElement 1 2] [$cam_mat GetElement 2 2] 
    }
    $vcam ComputeViewPlaneNormal        
    $vcam OrthogonalizeViewUp
    # save the current view Up
    set l [$Endoscopic(activeCam) GetViewUp]
    set Endoscopic(cam,viewUpX) [expr [lindex $l 0]]
    set Endoscopic(cam,viewUpY) [expr [lindex $l 1]] 
    set Endoscopic(cam,viewUpZ) [expr [lindex $l 2]]

    # save the current view Plane
    set l [$Endoscopic(activeCam) GetViewPlaneNormal]
    set Endoscopic(cam,viewPlaneNormalX) [expr -[lindex $l 0]]
    set Endoscopic(cam,viewPlaneNormalY) [expr -[lindex $l 1]] 
    set Endoscopic(cam,viewPlaneNormalZ) [expr -[lindex $l 2]]
    
    EndoscopicSetCameraViewAngle
    eval $vcam SetClippingRange $View(endoscopicClippingRange)    
    EndoscopicLightFollowEndoCamera $vcam
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicLightFollowEndoCamera
# Adjust the light to follow the camera.
# .ARGS
# str vcam virtual endoscope name
# .END
#-------------------------------------------------------------------------------
proc EndoscopicLightFollowEndoCamera {vcam} {
    global View Endoscopic
    
    # 3D Viewer
    
    set endoCurrentLight View($vcam,light)
    
    eval $endoCurrentLight SetPosition [$vcam GetPosition]
    eval $endoCurrentLight SetIntensity 1
    eval $endoCurrentLight SetFocalPoint [$vcam GetFocalPoint]
    
    set endoCurrentLight View($vcam,light2)
    eval $endoCurrentLight SetFocalPoint [$Endoscopic(activeCam) GetPosition]
    eval $endoCurrentLight SetIntensity 1
    eval $endoCurrentLight SetConeAngle 180    
    eval $endoCurrentLight SetPosition [$Endoscopic(activeCam) GetFocalPoint]
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetCameraZoom
# Set the endoscopic camera's zoom.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetCameraZoom {} {
    global Endoscopic Model View
    
    # get the View plane of the virtual camera because we want to move 
    # in and out along that plane
    set l [$Endoscopic(activeCam) GetViewPlaneNormal]
    set IO(x) [expr -[lindex $l 0]]
    set IO(y) [expr -[lindex $l 1]] 
    set IO(z) [expr -[lindex $l 2]]

    set Endoscopic(fp,distance) $Endoscopic(cam,zoomStr)

    # now move the fp a percentage of its distance to the camera
    set Endoscopic(cam,x) [expr $Endoscopic(fp,x) - $IO(x) * $Endoscopic(fp,distance)]
    set Endoscopic(cam,y) [expr $Endoscopic(fp,y) - $IO(y) * $Endoscopic(fp,distance)]
    set Endoscopic(cam,z) [expr $Endoscopic(fp,z) - $IO(z) * $Endoscopic(fp,distance)]
    
    Endoscopic(cam,actor) SetPosition $Endoscopic(cam,x) $Endoscopic(cam,y) $Endoscopic(cam,z)
    Endoscopic(gyro,actor) SetPosition $Endoscopic(cam,x) $Endoscopic(cam,y) $Endoscopic(cam,z)
    EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetCameraViewAngle
# Set the Endoscopic camera's view angle.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetCameraViewAngle {} {
    global Endoscopic Model View

    set Endoscopic(cam,viewAngle) $Endoscopic(cam,AngleStr)
    $Endoscopic(activeCam) SetViewAngle $Endoscopic(cam,viewAngle)
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetCameraAxis
# Set the Endoscopic camera's axis.
# .ARGS
# str axis absolute or relative, optional, defaults to empty string to do nothing
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetCameraAxis {{axis ""}} {
    global Endoscopic Model
    
    if {$axis != ""} {
        if {$axis == "absolute" || $axis == "relative"} {
            set Endoscopic(cam,axis) $axis
            
            # Change button text
            #$Endoscopic(axis) config -text $axis

            
            # update the actual camera position for the slider

            if {$axis == "relative"} {
                $Endoscopic(labelx) configure -text "Left/Right"
                $Endoscopic(labely) configure -text "Forw/Back"
                $Endoscopic(labelz) configure -text "Up/Down"        

            } elseif {$axis == "absolute"} {
                $Endoscopic(labelx) configure -text "L<->R "
                $Endoscopic(labely) configure -text "P<->A "
                $Endoscopic(labelz) configure -text "I<->S "
            }
            set l [$Endoscopic(gyro,actor) GetPosition]
            set Endoscopic(cam,xStr) [expr [lindex $l 0]]
            set Endoscopic(cam,yStr) [expr [lindex $l 1]]
            set Endoscopic(cam,zStr) [expr [lindex $l 2]]
            
            set Endoscopic(cam,xStr,old) [expr [lindex $l 0]]
            set Endoscopic(cam,yStr,old) [expr [lindex $l 1]]
            set Endoscopic(cam,zStr,old) [expr [lindex $l 2]]
            
            $Endoscopic(sliderx) set $Endoscopic(cam,xStr)
            $Endoscopic(slidery) set $Endoscopic(cam,yStr)
            $Endoscopic(sliderz) set $Endoscopic(cam,zStr)
            
            
            vtkTransform tmp
            tmp SetMatrix [$Endoscopic(gyro,actor) GetMatrix] 
            set l [tmp GetOrientation]
            tmp Delete
            set Endoscopic(cam,rxStr) [expr [lindex $l 0]]
            set Endoscopic(cam,ryStr) [expr [lindex $l 1]]
            set Endoscopic(cam,rzStr) [expr [lindex $l 2]]
            
            set Endoscopic(cam,rxStr,old) [expr [lindex $l 0]]
            set Endoscopic(cam,ryStr,old) [expr [lindex $l 1]]
            set Endoscopic(cam,rzStr,old) [expr [lindex $l 2]]
            
            $Endoscopic(sliderrx) set $Endoscopic(cam,rxStr)
            $Endoscopic(sliderry) set $Endoscopic(cam,ryStr)
            $Endoscopic(sliderrz) set $Endoscopic(cam,rzStr)
        
        } else {
            return
        }   
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCameraMotionFromUser
#
# Called whenever the active camera is moved. This routine syncs the position of
# the graphical endoscopic camera with the virtual endoscopic camera
# (i.e if the user changes the view of the endoscopic window with the mouse,
#  we want to change the position of the graphical camera)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCameraMotionFromUser {} {
    
    global View Endoscopic
    global CurrentCamera 
    
    #puts "$CurrentCamera"
    if {$CurrentCamera == $Endoscopic(activeCam)} {
        EndoscopicUpdateActorFromVirtualEndoscope $Endoscopic(activeCam)
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetCollision
# Set Endoscopic array's collision entry and configure the collision gui element.
# .ARGS
# int value 0 for collision detection off, 1 for on
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetCollision {value} {
    global Endoscopic

    set Endoscopic(collision) $value
    if { $value == 0 } {
        $Endoscopic(collMenu) config -text "off"
    } else {
        $Endoscopic(collMenu) config -text "on"
    }
}


############################################################################
#
#       PART 5: Vector Operation
#
###########################################################################

#-------------------------------------------------------------------------------
# .PROC EndoscopicMoveGyroToLandmark
# Get the point's location and orientatin and move the gyro there.
# .ARGS
# int id landmark point id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicMoveGyroToLandmark {id} {
    
    global Endoscopic 
    set xyz [Endoscopic(cLand,keyPoints) GetPoint $id]
    set rxyz [Endoscopic(fLand,keyPoints) GetPoint $id]
    
    EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam) "[lindex $xyz 0] [lindex $xyz 1] [lindex $xyz 2] [lindex $rxyz 0] [lindex $rxyz 1] [lindex $rxyz 2]" 
    EndoscopicUpdateActorFromVirtualEndoscope $Endoscopic(activeCam)
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateVectors
# Update the vectors.
# .ARGS
# int id endoscopic id for path
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateVectors {id} {
        
    global Endoscopic
    set numPoints [Endoscopic($id,cpath,keyPoints) GetNumberOfPoints]
    for {set i 0} {$i < $numPoints} {incr i} {
        set cp [Endoscopic($id,cpath,keyPoints) GetPoint $i]
        set fp [Endoscopic($id,cpath,keyPoints) GetPoint $i]
        
        set cpX [lindex $cp 0]
        set cpY [lindex $cp 1]
        set cpZ [lindex $cp 2]
        
        set fpX [lindex $fp 0]
        set fpY [lindex $fp 1]
        set fpZ [lindex $fp 2]
        
        Endoscopic($id,vector,vectors) InsertVector $i [expr $fpX - $cpX] [expr $fpY - $cpY] [expr $fpZ - $cpZ]
        
        Endoscopic($id,vector,scalars) InsertScalar $i .5 
        Endoscopic($id,vector,polyData) Modified
    }
}

#############################################################################
#
#     PART 6: Landmark Operations
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC EndoscopicGetAvailableListName
# Returns the next available list name
# .ARGS
# string model name of the path
# .END
#-------------------------------------------------------------------------------
proc EndoscopicGetAvailableListName {model} {
    global Endoscopic

    if {[info exists Endoscopic(${model}Path,nextAvailableId)] == 0} {
        set Endoscopic(${model}Path,nextAvailableId) 1
    }
    set numList $Endoscopic(${model}Path,nextAvailableId)
    set list ${model}$numList
    incr Endoscopic(${model}Path,nextAvailableId)
    return $list
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddLandmarkNoDirectionSpecified
#
# This procedure is called when the user adds a landmark at position i 
# on a slice or on a model and we don't know yet what direction of view we 
# should save along with the landmark. There are 2 cases:<br>
#  i = 1 => the direction vector is [0 1 0]<br>
#  i > 1 => The direction vector is tangential to the curve <br>
# [(position of landmark i - 1) - (position of last interpolated point on the path]<br>
# 
# The user can then change the direction vector interactively through the 
# user interface.
# .ARGS
# float x
# float y
# float z
# str list
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddLandmarkNoDirectionSpecified {x y z {list ""}} {
    global Endoscopic Point Fiducials
    
    
    ########### GET THE RIGHT LIST TO ADD THE POINT TO ############
    # if the list is not of type endoscopic, create a new endoscopic list
    if { $list == "" } {
        # add point to active path otherwise use the default path
        if { $Endoscopic(path,activeId) == "None" } {
            set numList $Endoscopic(path,nextAvailableId)
            set list Path${numList}_
        EndoscopicCreateAndActivatePath $Path${numList}_
        incr Endoscopic(path,nextAvailableId)
        } else {
        set id $Endoscopic(path,activeId)
        set list $Endoscopic($id,path,name)
    }
    } else {
    if {[info exists Fiducials($list,fid)] == 0} {    
        # if the list doesn't exist, create it
        EndoscopicCreateAndActivatePath $list
    }
    }
    # make that list active
    FiducialsSetActiveList $list

    set pid [FiducialsCreatePointFromWorldXYZ "endoscopic" $x $y $z $list]
    
    # this is now the direction of the vector
    # if i = 0, give it the default direction 0 1 0
    # else if i > 0, give it the tangential direction
    if { $pid == 0 } {
        Point($pid,node) SetFXYZ $x [expr $y + 1]  $z
    } else {
    
        set prev [expr $pid - 1]
        set prevList [Point($prev,node) GetXYZ]
        
        set d(x) [expr ($x - [lindex $prevList 0])]
        set d(y) [expr ($y - [lindex $prevList 1])]
        set d(z) [expr ($z - [lindex $prevList 2])]
        
        Normalize d
        Point($pid,node) SetFXYZ [expr $x + $d(x)] [expr $y + $d(y)] [expr $z + $d(z)]
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicInsertLandmarkNoDirectionSpecified
#
# This procedure is called when the user adds a landmark after the landmark with id "previousPid" 
# on a slice or on a model and we don't know yet what direction of view we 
# should save along with the landmark. There are 2 cases:<br>
#  i = 1 => the direction vector is [0 1 0]<br>
#  i > 1 => The direction vector is tangential to the curve <br>
# [(position of landmark i - 1) - (position of last interpolated point on the path]<br>
# 
# The user can then change the direction vector interactively through the 
# user interface.
# .ARGS
# int afterPid id of the point to add this one after
# float x x position of new landmark
# float y y position of new landmark
# float z z position of new landmark
# str list optional, if empty, add to active path
# .END
#-------------------------------------------------------------------------------
proc EndoscopicInsertLandmarkNoDirectionSpecified {afterPid x y z {list ""}} {
    global Endoscopic Point Fiducials
    
    
    ########### GET THE RIGHT LIST TO ADD THE POINT TO ############
    # if the list is not of type endoscopic, create a new endoscopic list
    if { $list == "" } {
        # add point to active path otherwise use the default path
        if { $Endoscopic(path,activeId) == "None" } {
            set numList $Endoscopic(path,nextAvailableId)
            set list Path${numList}_
        EndoscopicCreateAndActivatePath $Path${numList}_
        incr Endoscopic(path,nextAvailableId)
        } else {
        set id $Endoscopic(path,activeId)
        set list $Endoscopic($id,path,name)
    }
    } else {
    if {[info exists Fiducials($list,fid)] == 0} {    
        # if the list doesn't exist, create it
        EndoscopicCreateAndActivatePath $list
    }
    }
    # make that list active
    FiducialsSetActiveList $list

    set pid [FiducialsInsertPointFromWorldXYZ "endoscopic" $afterPid $x $y $z $list]
    
    # this is now the direction of the vector
    # if i = 0, give it the default direction 0 1 0
    # else if i > 0, give it the tangential direction
    if { $pid == 0 } {
        Point($pid,node) SetFXYZ $x [expr $y + 1]  $z
    } else {
    
        set prev [expr $pid - 1]
        set prevList [Point($prev,node) GetXYZ]
        
        set d(x) [expr ($x - [lindex $prevList 0])]
        set d(y) [expr ($y - [lindex $prevList 1])]
        set d(z) [expr ($z - [lindex $prevList 2])]
        
        Normalize d
        Point($pid,node) SetFXYZ [expr $x + $d(x)] [expr $y + $d(y)] [expr $z + $d(z)]
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddLandmarkDirectionSpecified
#
# This procedure is called when we want to add a landmark at position i and 
# we know that the direction of view to save along with the landmark is the
# current view direction of the endoscope
# 
# .ARGS
# str coords optional, if empty, get from the endo camera
# str list optional, path name, if empty, use the active path
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddLandmarkDirectionSpecified {{coords ""} {list ""}} {

    global Endoscopic Point Fiducials 
    
 ########### GET THE RIGHT LIST TO ADD THE POINT TO ############
    # if the list is not of type endoscopic, create a new endoscopic list
    if { $list == "" } {
        # add point to active path otherwise use the default path
        if { $Endoscopic(path,activeId) == "None" } {
            set numList $Endoscopic(path,nextAvailableId)
            set list Path${numList}_
            EndoscopicCreateAndActivatePath $list
            incr Endoscopic(path,nextAvailableId)
        } else {
            set id $Endoscopic(path,activeId)
            set list $Endoscopic($id,path,name)
        }
    } else {
        if {[info exists Fiducials($list,fid)] == 0} {    
            # if the list doesn't exist, create it
            EndoscopicCreateAndActivatePath $list
        }
    }
    # make that list active
    FiducialsSetActiveList $list
    
    ########## GET THE COORDINATES ################
    if { $coords == "" } {
        set cam_mat [Endoscopic(cam,actor) GetMatrix]   
        set fp_mat [Endoscopic(fp,actor) GetMatrix]   
        set x [$cam_mat GetElement 0 3]
        set y [$cam_mat GetElement 1 3]
        set z [$cam_mat GetElement 2 3]
        set fx [$fp_mat GetElement 0 3]
        set fy [$fp_mat GetElement 1 3]
        set fz [$fp_mat GetElement 2 3]
    } else {
        set x [lindex $coords 0]
        set y [lindex $coords 1]
        set z [lindex $coords 2]
        set fx [lindex $coords 3]
        set fy [lindex $coords 4]
        set fz [lindex $coords 5]
    }

    set pid [FiducialsCreatePointFromWorldXYZ "endoscopic" $x $y $z $list]
    if { $pid != "" } {
        Point($pid,node) SetFXYZ $fx $fy $fz
    }

}


#-------------------------------------------------------------------------------
# .PROC EndoscopicInsertLandmarkDirectionSpecified
#
# This procedure is called when we want to insert a landmark at position after the currently selected landmark and 
# we know that the direction of view to save along with the landmark is the
# current view direction of the endoscope
# 
# .ARGS
# str coords optional, if empty string, get it from the endoscopic camera
# str list optional, the list to insert into
# .END
#-------------------------------------------------------------------------------
proc EndoscopicInsertLandmarkDirectionSpecified {{coords ""} {list ""}} {

     global Endoscopic Point Fiducials 
    
    # get the ids of the selected fiducial
    set afterPid $Endoscopic(selectedFiducialPoint) 
    set fid $Endoscopic(selectedFiducialList) 
    

    if { $afterPid == "" } {
        EndoscopicAddLandmarkDirectionSpecified
        tk_messageBox -message "No Landmark selected. Choosing the last landmark on the path by default "
    } elseif { $fid == "" } {
        EndoscopicAddLandmarkDirectionSpecified
        tk_messageBox -message "No Landmark selected. Choosing the last landmark on the path by default "
    } else {
        set list $Fiducials($fid,name) 
        # make that list active
        FiducialsSetActiveList $list
    
    ########## GET THE COORDINATES ################
    if { $coords == "" } {
        set cam_mat [Endoscopic(cam,actor) GetMatrix]   
        set fp_mat [Endoscopic(fp,actor) GetMatrix]   
        set x [$cam_mat GetElement 0 3]
        set y [$cam_mat GetElement 1 3]
        set z [$cam_mat GetElement 2 3]
        set fx [$fp_mat GetElement 0 3]
        set fy [$fp_mat GetElement 1 3]
        set fz [$fp_mat GetElement 2 3]
    } else {
        set x [lindex $coords 0]
        set y [lindex $coords 1]
        set z [lindex $coords 2]
        set fx [lindex $coords 3]
        set fy [lindex $coords 4]
        set fz [lindex $coords 5]
    }

    set pid [FiducialsInsertPointFromWorldXYZ "endoscopic" $afterPid $x $y $z $list]
    if { $pid != "" } {
        Point($pid,node) SetFXYZ $fx $fy $fz
    }
  }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateLandmark
#
# This procedure is called when we want to update the current selected  landmark to 
# the current position and orientation of the camera actor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateLandmark {} {

    global Endoscopic

    # get the current coordinates of the camera and focal point
    set cam_mat [Endoscopic(cam,actor) GetMatrix]  
    set fp_mat [Endoscopic(fp,actor) GetMatrix]   

    # update the selected pid
    set pid $Endoscopic(selectedFiducialPoint) 
    if {$pid != ""} {
    Point($pid,node) SetXYZ [$cam_mat GetElement 0 3] [$cam_mat GetElement 1 3] [$cam_mat GetElement 2 3]
    Point($pid,node) SetFXYZ [$fp_mat GetElement 0 3] [$fp_mat GetElement 1 3] [$fp_mat GetElement 2 3]
    MainUpdateMRML
    }
}

#############################################################################
#
#    PART 7: Path Operation
#
############################################################################

#-------------------------------------------------------------------------------
# .PROC EndoscopicBuildInterpolatedPath
#
# This procedure creates a new path model by:<br>
# creating a path containing all landmarks <br>
#    from i = 0 to i = # of points added with EndoscopicAddLandmark*<br>
#
# It is much faster to create a path by iteratively calling <br>
# EndoscopicAddLandmark* for each new landmark -> EndoscopicBuildInterpolatedPath<br>
# 
# Then by iteratively calling<br>
# (EndoscopicAddLandmark* -> EndoscopicBuildInterpolatedPath) for each new landmark<br>
#
# But the advantage of the latter is that the user can see the path being<br>
# created iteratively (the former is used when loading mrml paths).
#
# .ARGS
# int id endoscopic path id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicBuildInterpolatedPath {id} {
    
    global Endoscopic Fiducials 
    
    # create vtk variables
    set numLandmarks [Endoscopic($id,cpath,keyPoints) GetNumberOfPoints]
    set i $numLandmarks
    
    # only build the path if there are at least 2 landmarks
    if { $numLandmarks > 1 } {

        set numberOfkeyPoints [Endoscopic($id,cpath,keyPoints) GetNumberOfPoints]

        #evaluate the first point of the spline (0)    

        Endoscopic($id,cpath,graphicalInterpolatedPoints) InsertPoint 0 \
                [Endoscopic($id,cpath,Spline,x) Evaluate 0] \
                [Endoscopic($id,cpath,Spline,y) Evaluate 0] \
                [Endoscopic($id,cpath,Spline,z) Evaluate 0]
        
        Endoscopic($id,cpath,allInterpolatedPoints) InsertPoint 0 \
                [Endoscopic($id,cpath,Spline,x) Evaluate 0] \
                [Endoscopic($id,cpath,Spline,y) Evaluate 0] \
                [Endoscopic($id,cpath,Spline,z) Evaluate 0]
        
        Endoscopic($id,fpath,allInterpolatedPoints) InsertPoint 0 \
                [Endoscopic($id,fpath,Spline,x) Evaluate 0] \
                [Endoscopic($id,fpath,Spline,y) Evaluate 0] \
                [Endoscopic($id,fpath,Spline,z) Evaluate 0]

        
        # now build the rest of the spline
        for {set i 0} {$i< [expr $numberOfkeyPoints - 1]} {incr i 1} {
            
            set pci [Endoscopic($id,cpath,keyPoints) GetPoint $i]
            set pcni [Endoscopic($id,cpath,keyPoints) GetPoint [expr $i+1]]
            set pfi [Endoscopic($id,fpath,keyPoints) GetPoint $i]
            set pfni [Endoscopic($id,fpath,keyPoints) GetPoint [expr $i+1]]
            
            # calculate the distance di between key point i and i+1 for both 
            # the camera path and fp path, keep the highest one
            
            set Endoscopic($id,cpath,dist,$i) [eval EndoscopicDistanceBetweenTwoPoints $pci $pcni]
            set Endoscopic($id,fpath,dist,$i) [eval EndoscopicDistanceBetweenTwoPoints $pfi $pfni]
            
            
            
            if {$Endoscopic($id,cpath,dist,$i) >= $Endoscopic($id,fpath,dist,$i)} {
                set di $Endoscopic($id,cpath,dist,$i)
            } else {
                set di $Endoscopic($id,fpath,dist,$i)
            }
            # take into account the interpolation factor
        # di is the distance between 2 control points in mm
            # step is the number of interpolated landmarks between each 
        # control point
        # interpolationStr is the number of landmarks per mm
            # i.e if interpolationStr = 1, and di = 10mm, 
        # this means we have a step of 1/10 
            # if interpolation = 2, and di = 10mm
        # this means that we have a step of 1/20
        # (note that the distance between interpolated landmarks is given 
        # by interpolationStr * di).

            if { $di <.1 } {
                set step 0
            } else {
                set step [expr 1/($Endoscopic(path,interpolationStr) * $di)]
            }

            # if no interpolation wanted or distance is too small, only
            # do one iteration
            if {$step == 0} {
                set step 1
            }

            # evaluate the spline di times start after i, finish at i+1
            for {set j $step} {$j <= 1} {set j [expr $j + $step]} {
                set t [expr $i + $j]
                
                # add the points for the graphical lines
                if {$Endoscopic($id,cpath,dist,$i) !=0} {
                    set numPoints [Endoscopic($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
                    
                    Endoscopic($id,cpath,graphicalInterpolatedPoints) InsertPoint [expr $numPoints] [Endoscopic($id,cpath,Spline,x) Evaluate $t] [Endoscopic($id,cpath,Spline,y) Evaluate $t] [Endoscopic($id,cpath,Spline,z) Evaluate $t]
                }

                foreach m "c f" {
                    # add the points for the landmark record
                    set numPoints [Endoscopic($id,${m}path,allInterpolatedPoints) GetNumberOfPoints]
                    Endoscopic($id,${m}path,allInterpolatedPoints) InsertPoint [expr $numPoints] [Endoscopic($id,${m}path,Spline,x) Evaluate $t] [Endoscopic($id,${m}path,Spline,y) Evaluate $t] [Endoscopic($id,${m}path,Spline,z) Evaluate $t]
                }
            }
        }
        
        set numberOfOutputPoints [Endoscopic($id,cpath,allInterpolatedPoints) GetNumberOfPoints]
        set Endoscopic(path,exists) 1
        
        # since that is where the camera is
        # add cell data
        
        set numberOfOutputPoints [Endoscopic($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
        Endoscopic($id,path,lines) InsertNextCell $numberOfOutputPoints
        for {set i 0} {$i< $numberOfOutputPoints} {incr i 1} {
            Endoscopic($id,path,lines) InsertCellPoint $i
        }    

        Endoscopic($id,path,source) Modified
        # now update the vectors
        #EndoscopicUpdateVectors $id
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicDeletePath
# Delete the active fiducials list.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicDeletePath {} {
    global Endoscopic Fiducials

    FiducialsDeleteList $Fiducials(activeList)
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicComputeRandomPath
# Create 20 random points in a path.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicComputeRandomPath {} {
    global Endoscopic Fiducials
    
    for {set i 0} {$i<20} {incr i 1} {
        set x  [expr [Endoscopic(path,vtkmath) Random -1 1] * 100]
        set y  [expr [Endoscopic(path,vtkmath) Random -1 1] * 100]
        set z  [expr [Endoscopic(path,vtkmath) Random -1 1] * 100] 
        EndoscopicAddLandmarkNoDirectionSpecified $x $y $z "random$Endoscopic(randomPath,nextAvailableId)"
    }
    incr Endoscopic(randomPath,nextAvailableId)
    MainUpdateMRML
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicShowPath
# Add or remove actors from the endoscopicScreen, if showPath is 1 or not.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicShowPath {} {
    global Path Endoscopic

    if {$Endoscopic(path,exists) == 1} {
        #jeanette    
        set id $Endoscopic(path,activeId)
        
        if {$Endoscopic(path,showPath) == 1} {
            endoscopicScreen AddActor Endoscopic($id,path,actor)
        } else {
            endoscopicScreen RemoveActor Endoscopic($id,path,actor)
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicFlyThroughPath
# Move through the path.
# .ARGS
# str listOfCams
# str listOfPaths
# .END
#-------------------------------------------------------------------------------
proc EndoscopicFlyThroughPath {listOfCams listOfPaths} {
    global Endoscopic Model View Path Module 
    
    
    if {[lindex $listOfPaths 0] == "None"} {
        return
    }
    
    # for now assume they have as many points, so get it from the first
    # path on the list 
    set id [lindex $listOfPaths 0]
    
    set numPoints [Endoscopic($id,cpath,allInterpolatedPoints) GetNumberOfPoints]
    for {set Endoscopic(path,i) $Endoscopic(path,stepStr)} {$Endoscopic(path,i)< $numPoints} {incr Endoscopic(path,i) $Endoscopic(path,speed)} { 
        if {$Endoscopic(path,stop) == "0"} {
            set Endoscopic(path,stepStr) $Endoscopic(path,i)
            
            EndoscopicSetPathFrame $listOfCams $listOfPaths
            
            update            
            Render3D    
        } else {    
            EndoscopicResetStopPath
            break
        }    
    }

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetPathFrame
# Update the actors from the virtual endoscope.
# .ARGS
# str listOfCams
# str listOfPaths
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetPathFrame {listOfCams listOfPaths} {
    global Endoscopic Model View Path 


    if {[lindex $listOfPaths 0] == "None"} {
        return
    }
    
    foreach cam $listOfCams id $listOfPaths {
        
        set Endoscopic(path,i) $Endoscopic(path,stepStr)
        set l [Endoscopic($id,cpath,allInterpolatedPoints) GetPoint $Endoscopic(path,i)] 
        set l2 [Endoscopic($id,fpath,allInterpolatedPoints) GetPoint $Endoscopic(path,i)]
        
        EndoscopicUpdateVirtualEndoscope $cam "[lindex $l 0] [lindex $l 1] [lindex $l 2] [lindex $l2 0] [lindex $l2 1] [lindex $l2 2]"
        EndoscopicUpdateActorFromVirtualEndoscope $cam 
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicStopPath
# Stop fly through.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicStopPath {} {
    global Path Endoscopic
        
    set Endoscopic(path,stop) 1
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetStopPath
# Resume fly through.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetStopPath {} {
    global Endoscopic
        
    set Endoscopic(path,stop) 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetPath
# Stop the flythrough and reset the camera view.
# .ARGS
# str listOfCams
# str listOfPaths
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetPath {listOfCams listOfPaths} {
    global Endoscopic Path 


    if {[lindex $listOfPaths 0] == "None"} {
        return
    }
        
    set Endoscopic(cam,viewUpX) 0
    set Endoscopic(cam,viewUpY) 0
    set Endoscopic(cam,viewUpZ) 1
    EndoscopicStopPath
    
    set Endoscopic(path,stepStr) 0
    EndoscopicSetPathFrame $listOfCams $listOfPaths
    EndoscopicResetStopPath
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetSpeed
# Set the speed of the fly through.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetSpeed {} {
    global Endoscopic Path
    
    set Endoscopic(path,speed) $Endoscopic(path,speedStr)
}


#############################################################################
#
#     PART 8:  Slice driver operations
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC EndoscopicCheckDriver
# This procedure is called once the position of the endoscope is updated. <br>
# It checks to see if there is a driver for the slices and calls EndoscopicReformatSlices 
# with the right argument to update the position of the slices.
# .ARGS
# str vcam the name of the virtual endoscope
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCheckDriver {vcam} {

    global Endoscopic View Slice MainAnno Anno Module


    if { $Endoscopic(fp,driver) == 1 } {
        eval EndoscopicReformatSlices $vcam [$vcam GetFocalPoint]

    } elseif { $Endoscopic(cam,driver) == 1 } {
        eval EndoscopicReformatSlices $vcam [$vcam GetPosition]
    } elseif { $Endoscopic(intersection,driver) == 1 } {
        set l [$View($vcam,renderer) GetCenter]
        set l0 [expr [lindex $l 0]]
        set l1 [expr [lindex $l 1]]
        if { [llength $l] > 2 } {
            set l2 [expr [lindex $l 2]]
        } else {
            set l2 0
        }
        set p [Endoscopic(picker) Pick $l0 $l1 $l2 endoscopicScreen]
        if { $p == 1} {
            set selPt [Endoscopic(picker) GetPickPosition]
            set x [expr [lindex $selPt 0]]
            set y [expr [lindex $selPt 1]]
            set z [expr [lindex $selPt 2]]
            EndoscopicReformatSlices $vcam $x $y $z
        
        set Anno(cross) 1
            set Anno(crossIntersect) 1
        
        MainAnnoSetVisibility
        MainAnnoUpdateFocalPoint $x $y $z
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicReformatSlices
# Get the endo camera's view up and plane normal then recomput the reformat matrix by 
# calling Slicer's SetDirectNTP
# .ARGS
# str vcam the name of the endoscopic camera
# float x in call to SetDirectNTP, this is P's x value
# float y in call to SetDirectNTP, this is P's y value
# float z in call to SetDirectNTP, this is P's z value
# .END
#-------------------------------------------------------------------------------
proc EndoscopicReformatSlices {vcam x y z} {
    global Endoscopic View Slice
    
    set vu [$vcam GetViewUp]
    set vpn [$vcam GetViewPlaneNormal]
    # Force recomputation of the reformat matrix
    Slicer SetDirectNTP \
        [lindex $vu 0] [lindex $vu 1] [lindex $vu 2] \
        [expr -[lindex $vpn 0]] [expr -[lindex $vpn 1]] [expr -[lindex $vpn 2]]  \
        $x $y $z
    RenderSlices
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetSliceDriver
# Set who's driving which slices are being currently displayed
# .ARGS
# str name who's driving now? User, Camera, FocalPoint, Intersection
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetSliceDriver {name} {
    global Endoscopic Model View Slice


    # Change button text
    $Endoscopic(mbDriver) config -text $name
    
    
    if { $name == "User" } {
        foreach s $Slice(idList) {
            Slicer SetDriver $s 0
        }
        set Endoscopic(fp,driver) 0
        set Endoscopic(cam,driver) 0
        set Endoscopic(intersection,driver) 0
    } else {
        foreach s $Slice(idList) {
            Slicer SetDriver $s 1
        }
        if { $name == "Camera"} {
            set m cam
            set Endoscopic(fp,driver) 0
            set Endoscopic(cam,driver) 1
            set Endoscopic(intersection,driver) 0
        } elseif { $name == "FocalPoint"} {
            set m fp 
            set Endoscopic(fp,driver) 1
            set Endoscopic(cam,driver) 0
            set Endoscopic(intersection,driver) 0
        } elseif { $name == "Intersection"} {
            set m intersection 
            set Endoscopic(fp,driver) 0
            set Endoscopic(cam,driver) 0
            set Endoscopic(intersection,driver) 1
        }
        
        MainSlicesSetOrientAll "Orthogonal"
        EndoscopicCheckDriver $Endoscopic(activeCam)
        RenderSlices
    }    
}


#############################################################################
#
#     PART 9: Fiducials operations
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC EndoscopicFiducialsPointSelectedCallback
# Select this point in the endo module, reset the camera if necessary to look at it,
# does not call Render3D, as that should be called by the proc firing off the callbacks.
# .ARGS
# int fid id of the fiducials list
# int pid point id on the list
# .END
#-------------------------------------------------------------------------------
proc EndoscopicFiducialsPointSelectedCallback {fid pid} {
    
    global Endoscopic Fiducials Select Module Model Point

    if {$::Module(verbose)} {
        puts "EndoscopicFiducialsPointSelectedCallback fid = $fid, pid = $pid, active list id = $Fiducials(activeListID)"
    }

    set Endoscopic(selectedFiducialPoint) $pid
    set Endoscopic(selectedFiducialList) $fid
    # only reset the active list if it's changed
    if {$Fiducials(activeListID) != $Endoscopic(selectedFiducialList)} {
        FiducialsSetActiveList $Fiducials($fid,name)
        if {$::Module(verbose)} {
            puts "EndoscopicFiducialsPointSelectedCallback: after fid set active list to $fid"
        }
    }

    # if the source or sink button are on, then make that point the 
    if { $Endoscopic(sourceButton,on) == 1 } {
        PathPlanningSetSource $fid $pid
        # get the selected actor, make it active
        if {$Select(actor) != ""} {
            foreach ren $Module(Renderers) {
                foreach id $Model(idList) {
                    if { [$Select(actor) GetProperty] == [Model($id,actor,$ren) GetProperty]} {
                        MainModelsSetActive $id
                    }
                }
            }
        }
        $Endoscopic(sourceLabel) configure -text "[Point($pid,node) GetName]"
        set Endoscopic(source,exists) 1    
        set Endoscopic(sourceButton,on) 0
    } elseif { $Endoscopic(sinkButton,on) == 1 } {
        PathPlanningSetSink $fid $pid
        # get the selected actor, make it active
        if {$Select(actor) != ""} {
            foreach ren $Module(Renderers) {
                foreach id $Model(idList) {
                    if { [$Select(actor) GetProperty] == [Model($id,actor,$ren) GetProperty]} {
                        MainModelsSetActive $id
                    }
                }
            }
        }
        $Endoscopic(sinkLabel) configure -text "[Point($pid,node) GetName]"
        set Endoscopic(sink,exists) 1    
        set Endoscopic(sinkButton,on) 0
    }


    # if the point is of type endoscopic, use the actual xyz and fxyz info
    if {[info command Fiducials($fid,node)] != ""} {
        if {[Fiducials($fid,node) GetType] == "endoscopic" } {
            EndoscopicResetCameraDirection    
            EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam) [concat [Point($pid,node) GetXYZ] [Point($pid,node) GetFXYZ]]
            
            #set test [Point($pid,node) GetFXYZ]
            #puts $test
            
        } else {
            # look at the point instead
            EndoscopicResetCameraDirection    
            EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam) [concat [Point($pid,node) GetFXYZ] [Point($pid,node) GetXYZ]]
        }
    } else {
        DevErrorWindow "EndoscopicFiducialsPointSelectedCallback: Fiducials($fid,node) does not exist"
    }
    EndoscopicUpdateActorFromVirtualEndoscope $Endoscopic(activeCam)
    # Render will get called in the proc going through the callback functions
#    Render3D
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicFiducialsPointCreatedCallback
# This procedures is a callback procedule called when a Fiducial Point is
# created.<br>
# If the Point is part of the "reformat" Fiducial list, then the procedure 
# selects the right number of fiducials as they are created based on which 
# step we are in
# .ARGS 
# str type counts if it's endoscopic
# int fid fiducials list id
# int pid point id 
# .END
#-------------------------------------------------------------------------------
proc EndoscopicFiducialsPointCreatedCallback {type fid pid} {

    global Endoscopic Fiducials Select Module Model
    if {$::Module(verbose)} {
        puts "EndoscopicFiducialsPointCreatedCallback - is it red?"
        # after 2000
    }

    # jump to that point only if it is not an endoscopic point
    if { $type != "endoscopic" } {
        EndoscopicFiducialsPointSelectedCallback $fid $pid
    }

    # if the point is added to the reformat list and the Volumes/Reformat Tab 
    # is currently active, then select the last 2 or 3 points (depending on what step we're in)

    
    set module $Module(activeID) 
    set row $Module($module,row) 
    set tab $Module($module,$row,tab) 

    if { $module == "Endoscopic" && $tab == "Path"} {
        if { $Fiducials($fid,name) == "path" } {
            # select the point
            FiducialsSelectionUpdate $fid $pid 1 
            # toggle between the source and the sink
            if {$Endoscopic(source,exists) == 0} {
                PathPlanningSetSource $fid $pid
                # get the selected actor, make it active
                if {$Select(actor) != ""} {
                    foreach ren $Module(Renderers) {
                        foreach id $Model(idList) {
                            if { [$Select(actor) GetProperty] == [Model($id,actor,$ren) GetProperty]} {
                                MainModelsSetActive $id
                            }
                        }
   
                    }
                }
                $Endoscopic(sourceLabel) configure -text "[Point($pid,node) GetName]"
                set Endoscopic(source,exists) 1
            } else {
                FiducialsSelectionUpdate $fid $pid 1
                PathPlanningSetSink $fid $pid
                $Endoscopic(sinkLabel) configure -text "[Point($pid,node) GetName]"
                set Endoscopic(source,exists) 0
            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateMRML
# Called to update the Endo module's nodes in the mrml tree, turns off backface culling,
# and calls Render3D (which won't do anything if we're in a MainUpdateMRML session).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateMRML {} {

    global Models Model Endoscopic

    if {$::Module(verbose)} {
        puts "EndoscopicUpdateMRML"
    }

    # turn off backface culling for models in endoscopicScreen
    foreach m $Model(idList) {
        $Model($m,prop,endoscopicScreen) SetBackfaceCulling 0
    }
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicStartCallbackFiducialsUpdateMRML
# Called at the beginning of FiducialsUpdateMRML, reset the path variables and
# menu
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicStartCallbackFiducialsUpdateMRML {} {

    global Endoscopic

    if {$::Module(verbose)} {
        puts "EndoscopicStartCallbackFiducialsUpdateMRML"
    }

    # reset the variables for all the paths we know about
    foreach id $Endoscopic(path,activeIdList) {
        EndoscopicResetPathVariables $id
    }
    
    # keep a list of currently existing path so make it empty for now
    set Endoscopic(path,activeIdList) ""
    
    #reset the menu
    foreach m $Endoscopic(mPathList) {
        $m delete 0 end
    }
    $Endoscopic(mPath4Fly) delete 0 end
    # FIXME?
    #set Endoscopic(path,activeId) None
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicEndCallbackFiducialsUpdateMRML
# Called at the end, does nothing. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicEndCallbackFiducialsUpdateMRML {} {
    
    global Endoscopic
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCallbackFiducialsUpdateMRML
#
# Called when Updated Fiducials are of type endoscopic
# .ARGS
# str type the type of the fiducial, if not endoscopic, return.
# int id id of the path
# list listOfPoints points in the path.
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCallbackFiducialsUpdateMRML {type id listOfPoints} {
    global Mrml Path Endoscopic
    
    if { $type != "endoscopic"} {
        return
    }

    if {$::Module(verbose)} {
        puts "EndoscopicCallbackFiducialsUpdateMRML"
    }

    # if we never heard about this Id, then this is a new path
    if {[lsearch $Endoscopic(path,allIdsUsed) $id] == -1} {
        EndoscopicCreateVTKPath $id 
        set Endoscopic($id,path,name) [Fiducials($id,node) GetName]
    }
    lappend Endoscopic(path,activeIdList) $id

    # update the name field (different paths in time will have the same id)
    set Endoscopic($id,path,name) [Fiducials($id,node) GetName]
    
    set i -1

    foreach lid $listOfPoints {
        # path position
        set i [expr $i + 1]
        set l [Point($lid,node) GetXYZ]
        set cx [lindex $l 0]
        set cy [lindex $l 1]
        set cz [lindex $l 2]
        set f [Point($lid,node) GetFXYZ]
        set fx [lindex $f 0]
        set fy [lindex $f 1]
        set fz [lindex $f 2]
        
        # update vtk
        # FIXME find a more elegant solution ??
        if {$cx == $fx && $cy == $fy && $cz == $fz} {
            set fx [expr $fx + 1]
        }
        Endoscopic($id,cpath,Spline,x) AddPoint $i $cx
        Endoscopic($id,cpath,Spline,y) AddPoint $i $cy
        Endoscopic($id,cpath,Spline,z) AddPoint $i $cz
        Endoscopic($id,cpath,keyPoints) InsertPoint $i $cx $cy $cz
            
        Endoscopic($id,fpath,Spline,x) AddPoint $i $fx
        Endoscopic($id,fpath,Spline,y) AddPoint $i $fy
        Endoscopic($id,fpath,Spline,z) AddPoint $i $fz
        Endoscopic($id,fpath,keyPoints) InsertPoint $i $fx $fy $fz
    }
    EndoscopicBuildInterpolatedPath $id   
    
    # update the menus
    set name $Endoscopic($id,path,name)
    
    foreach m $Endoscopic(mPathList) {
        $m add command -label $name -command "EndoscopicSelectActivePath $id" 
    }
    # only add to the fly-through menu if the path has more than one point
    if {[Endoscopic($id,cpath,keyPoints) GetNumberOfPoints] > 1} {
        $Endoscopic(mPath4Fly) add command -label $name -command "EndoscopicSelectActivePath $id; EndoscopicResetPath $Endoscopic(activeCam) $id" 
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateAndActivatePath
# Calls FiducialsCreateFiducialsList and makes it active.
# .ARGS
# str name the name of the fiducial list to create
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateAndActivatePath {name} {
    global Endoscopic Fiducials
    
    set id [FiducialsCreateFiducialsList "endoscopic" $name]
    # check to see if that exists already
    set ext 1
    while {$id == -1} {
        set id [FiducialsCreateFiducialsList "endoscopic" ${name}($ext)]
        set ext [expr $ext + 1]
    }
    set name [Fiducials($id,node) GetName]
    set type [Fiducials($id,node) GetType]
    FiducialsSetActiveList $name
    EndoscopicFiducialsActivatedListCallback "endoscopic" $name $id
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicFiducialsActivatedListCallback
# This is a callback from the fiducials module telling us which list
# is active.<br>
# We update the path menus only if the active list is an endoscopic
# one.
# .ARGS
# str type the type of the fiducial, if not endoscopic, return.
# str name name of the list
# int id id of the path to be set active
# .END
#-------------------------------------------------------------------------------
proc EndoscopicFiducialsActivatedListCallback {type name id} {
    global Endoscopic Fiducials

    # if an endoscopic list is activated, tell all the menus in the 
    # endoscopic displays
    if {$type == "endoscopic" } {
    
        set Endoscopic(path,activeId) $id
    
        # change the text on menu buttons
        foreach mb $Endoscopic(mbPathList) {
            $mb config -text $Endoscopic($id,path,name) 
        }
        if {[Endoscopic($id,cpath,keyPoints) GetNumberOfPoints] > 1} {
            $Endoscopic(mbPath4Fly) config -text $Endoscopic($id,path,name) 
            # configure the scale
            set Endoscopic(path,stepStr) 0
            set numberOfOutputPoints [Endoscopic($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
            $Endoscopic(path,stepScale) config -to [expr $numberOfOutputPoints - 1]
    
       } else {
           set Endoscopic(path,activeId) "None"
           # change the text on menu buttons
           foreach mb $Endoscopic(mbPathList) {
               $mb config -text "None"
           }
           $Endoscopic(mbPath4Fly) config -text "None"
       }
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSelectActivePath
# Set the active list, change the text on the menu buttons
# .ARGS
# int id path id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSelectActivePath {id} {
    
    global Endoscopic Fiducials
    set Endoscopic(path,activeId) $id
    # make that list active
    FiducialsSetActiveList $Endoscopic($id,path,name)
    

    # change the text on menu buttons
    foreach mb $Endoscopic(mbPathList) {
        $mb config -text $Endoscopic($id,path,name) 
    }
    if {[Endoscopic($id,cpath,keyPoints) GetNumberOfPoints] > 1} {
        $Endoscopic(mbPath4Fly) config -text $Endoscopic($id,path,name) 
        # configure the scale
        set Endoscopic(path,stepStr) 0
        set numberOfOutputPoints [Endoscopic($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
        $Endoscopic(path,stepScale) config -to [expr $numberOfOutputPoints - 1]
    }
        
}

############################################################################
#
#  PART 10: Helper functions     
#
############################################################################

#-------------------------------------------------------------------------------
# .PROC EndoscopicDistanceBetweenTwoPoints
# Returns the distance between two points.
# .ARGS
# float p1x first point x
# float p1y first point y
# float p1z first point z
# float p2x second point x
# float p2y second point y
# float p2z second point z
# .END
#-------------------------------------------------------------------------------
proc EndoscopicDistanceBetweenTwoPoints {p1x p1y p1z p2x p2y p2z} {

    return [expr sqrt((($p2x - $p1x) * ($p2x - $p1x)) + (($p2y - $p1y) * ($p2y - $p1y)) + (($p2z - $p1z) * ($p2z - $p1z)))]
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateSelectionLandmarkList
# Update the landmark list by selecting just this point.
# .ARGS
# int id path id
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateSelectionLandmarkList {id} {
    
    global Endoscopic
    set sel [$Endoscopic(path,fLandmarkList) curselection] 
    if {$sel != ""} {
        $Endoscopic(path,fLandmarkList) selection clear $sel $sel
    }
    $Endoscopic(path,fLandmarkList) selection set $id
    $Endoscopic(path,fLandmarkList) see $id
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetModelsVisibilityInside
# Check the value of Endoscopic(ModelsVisibilityInside) and call MainModelsSetCulling 
# for each model.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetModelsVisibilityInside {} {
    global View Model Endoscopic

    if { $Endoscopic(ModelsVisibilityInside) == 0 } {
        set value 1
    } else {
        set value 0
    }
    
    foreach m $Model(idList) {
        MainModelsSetCulling $m $value
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetSlicesVisibility
# Add or remove slice actors from the endoscopic renderers depending on the value
# of Endoscopic(SlicesVisibility).
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetSlicesVisibility {} {
    global View Endoscopic Module
    
    if { $Endoscopic(SlicesVisibility) == 0 } {
        foreach s "0 1 2" {
            foreach ren $Module(endoscopicRenderers) {
                $ren RemoveActor Slice($s,outlineActor)
                $ren RemoveActor Slice($s,planeActor)
            }
        }
    } else {
        foreach s "0 1 2" {
            foreach ren $Module(endoscopicRenderers) {
                $ren AddActor Slice($s,outlineActor)
                $ren AddActor Slice($s,planeActor)
            }
        }
    }
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateEndoscopicViewVisibility
#  Makes the endoscopic view appear or disappear based on the variable 
# Endoscopic(mainview,visibility) <br> Note: there is a check to make sure that the 
# endoscopic view cannot disappear if the main view is not visible.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateEndoscopicViewVisibility {} {
    global View viewWin Gui Endoscopic

    if {$Endoscopic(endoview,visibility) == 1 && $Endoscopic(mainview,visibility) == 1} {
        EndoscopicAddEndoscopicView
    } elseif {$Endoscopic(endoview,visibility) == 0 && $Endoscopic(mainview,visibility) == 1} {
        EndoscopicRemoveEndoscopicView
    } elseif {$Endoscopic(endoview,visibility) == 1 && $Endoscopic(mainview,visibility) == 0} {
        EndoscopicAddEndoscopicView
        EndoscopicRemoveMainView
    }
    Render3D
    # for the rest do nothing
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateMainViewVisibility
# Makes the main view appear or disappear based on the variable 
# Endoscopic(mainview,visibility) <br> Note: there is a check to make sure that the 
# main view cannot disappear if the endoscopic view is not visible.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateMainViewVisibility {} {
    global View viewWin Gui Endoscopic

    if {$Endoscopic(mainview,visibility) == 1 && $Endoscopic(endoview,visibility) == 1} {
        EndoscopicAddMainView
    } elseif {$Endoscopic(mainview,visibility) == 0 && $Endoscopic(endoview,visibility) == 1} {
        EndoscopicRemoveMainView
    } elseif {$Endoscopic(mainview,visibility) == 1 && $Endoscopic(endoview,visibility) == 0} {
        EndoscopicAddMainView
        EndoscopicRemoveEndoscopicView
    }
    Render3D
    # for the rest do nothing
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddEndoscopicView
#  Add the endoscopic renderer to the right of the main view 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddEndoscopicView {} {
    global View viewWin Gui Endoscopic

    if {$Endoscopic(viewOn) == 0} {

        EndoscopicSetSliceDriver User
        # set the endoscopic actors' visibility according to their prior visibility
            
        EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)
            $viewWin AddRenderer endoscopicScreen    
        viewRen SetViewport 0 0 .5 1
            endoscopicScreen SetViewport .5 0 1 1
            MainViewerSetSecondViewOn
            MainViewerSetMode $View(mode) 
        set Endoscopic(viewOn) 1
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddMainView
#  Add the main view to the left of the endoscopic view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddMainView {} {
    global View viewWin Gui Endoscopic

    $viewWin AddRenderer viewRen    
    viewRen SetViewport 0 0 .5 1
    endoscopicScreen SetViewport .5 0 1 1
    MainViewerSetSecondViewOn
    set Endoscopic(viewOn) 1
    MainViewerSetMode $View(mode) 
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddEndoscopicViewRemoveMainView
#  Makes the main view invisible/the endoscopic view visible
#  (so switch between the 2 views)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddEndoscopicViewRemoveMainView {} {
    global View viewWin Gui Endoscopic
    
    if {$Endoscopic(viewOn) == 0} {

        EndoscopicSetSliceDriver Camera
        # set the endoscopic actors' visibility according to their prior visibility
        
        foreach a $Endoscopic(actors) {
            EndoscopicUpdateVisibility $a
        }
        Render3D
        EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam)
        $viewWin AddRenderer endoscopicScreen
        $viewWin RemoveRenderer viewRen
        endoscopicScreen SetViewport 0 0 1 1
        MainViewerSetSecondViewOn
        set Endoscopic(viewOn) 1
        MainViewerSetMode $View(mode) 
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicRemoveEndoscopicView
#  Remove the endoscopic view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicRemoveEndoscopicView {} {
    global Endoscopic View viewWin Gui

    if { $Endoscopic(viewOn) == 1} {


        $viewWin RemoveRenderer endoscopicScreen    
        viewRen SetViewport 0 0 1 1
        MainViewerSetSecondViewOff
        set Endoscopic(viewOn) 0
        MainViewerSetMode $View(mode) 
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicRemoveMainView
#  Remove the main view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicRemoveMainView {} {
    global Endoscopic View viewWin viewRen endoscopicScreen
    
    $viewWin RemoveRenderer viewRen    
    endoscopicScreen SetViewport 0 0 1 1
    MainViewerSetSecondViewOn
    set Endoscopic(viewOn) 1
    MainViewerSetMode $View(mode) 

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddMainViewRemoveEndoscopicView
#  Makes the main view visible/the endoscopic view invisible
#  (so switch between the 2 views)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddMainViewRemoveEndoscopicView {} {
    global Endoscopic View viewWin Gui

    if { $Endoscopic(viewOn) == 1} {

        # reset the slice driver
        EndoscopicSetSliceDriver User

        # set all endoscopic actors to be invisible, without changing their visibility 
        # parameters
        foreach a $Endoscopic(actors) {
            Endoscopic($a,actor) SetVisibility 0
            EndoscopicSetPickable $a 0
        }
        Render3D
        $viewWin AddRenderer viewRen
        $viewWin RemoveRenderer endoscopicScreen    
        viewRen SetViewport 0 0 1 1
        MainViewerSetSecondViewOff
        set Endoscopic(viewOn) 0
        MainViewerSetMode $View(mode) 
    }
}


##########################################################################

### SYNCHRONIZED

##########################################################################


#-------------------------------------------------------------------------------
#  .PROC EndoscopicAutoSelectSourceSink
# Automatically set PathPlanningSetSource and PathPlanningSetSink
# .ARGS
# str list name of the list, defaults to an empty string
# .END 
#-------------------------------------------------------------------------------
proc EndoscopicAutoSelectSourceSink {{list ""}} {
    global Point Fiducials Select Endoscopic Model PathPlanning

   set model $Model(activeID)
   if {$model != ""} {
  
       # the reason to use Select(actor) is because the Fiducial call back 
       # below checks for it in the begining.
       # the actor info is then passed on to orient the direction of the camera.
    
       set Select(actor) Model($model,actor,viewRen)
  
       set polyData $Model($model,polyData)

       set cellNum [$polyData GetNumberOfCells]
       set randId  [expr round( [expr [expr rand()]*1000])]
       set minId $randId
       set maxId [expr [expr $cellNum -1] - $randId] 
       
       set Select(cellId) $minId
       
       set cell [$polyData GetCell $minId]
       set points [$cell GetPoints]
       set point2 [$points GetPoint 1]
       
       set x [lindex $point2 0]
       set y [lindex $point2 1]
       set z [lindex $point2 2]
       
       set pid [FiducialsCreatePointFromWorldXYZ "default" $x $y $z $list]
       if { $pid != "" } {
           set fid $Fiducials($Fiducials(activeList),fid)
           
           Fiducials($fid,node) SetTextSize 0.0
           Fiducials($fid,node) SetSymbolSize 1.0
           
           PathPlanningSetSource $fid $pid
       }
       
       # MainUpdateMRML
       # just update the models, don't care about anything else
       MainModelsUpdateMRML

       # don't need to call this twice
       if {$::Module(verbose)} {
           puts "EndoscopicAutoSelectSourceSink: skipping first render call"
       }
       # Render3D
       
       set Select(cellId) $maxId
       
       set cell [$polyData GetCell $maxId]
       set points [$cell GetPoints]
       set point2 [$points GetPoint 1]
       
       set x [lindex $point2 0]
       set y [lindex $point2 1]
       set z [lindex $point2 2]
       
       set pid [FiducialsCreatePointFromWorldXYZ "default" $x $y $z $list]
       if { $pid != "" } {
           set fid $Fiducials($Fiducials(activeList),fid)
           PathPlanningSetSink $fid $pid
       }
       
       MainUpdateMRML
       Render3D
       
   }
}


#=========================================================================
#  Part 11  Procedures related to displaying the flattened colon
#=========================================================================

#-------------------------------------------------------------------------------
# .PROC  EndoscopicSetFlatFileName
# Set file name from Endoscopic(FlatSelect)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetFlatFileName {} {
    global Endoscopic

    # do nothing if the user cancelled in the browser box
    if {$Endoscopic(FlatSelect) == ""} {
        set Endoscopic(flatColon,name) ""
        set Endoscopic(FlatSelect) ""
        
        return
    }

    # name the flattened view based on the entered file name.
    set Endoscopic(flatColon,filePath) [file root $Endoscopic(FlatSelect)]
    #puts "file path is $root"
    set Endoscopic(flatColon,name) [file root [file tail $Endoscopic(FlatSelect)]]
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCancelFlatFile
# Remove file name and reset variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCancelFlatFile {} {
   global Endoscopic

   set Endoscopic(FlatSelect) ""
   set Endoscopic(flatColon,name) ""
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddFlatView
# Open a separate render window to display the flattened colon.<br>
# Simple Gui are also written here with parameters tailored to the size of the flatttened colon.<br>
# Bindings are pushed here.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddFlatView {} {
    global Gui Endoscopic View viewWin MainViewer Slice Module

    # deny if the user clicks 'Choose' when the selection box is empty
    if {$Endoscopic(FlatSelect) == ""} {
        DevWarningWindow "Please select a file to display."
        return
    }

    set name $Endoscopic(flatColon,name)

    # deny if user tries to display an already displayed file
    if {[lsearch -exact $Endoscopic(FlatWindows) $name] != -1} {
        DevWarningWindow "Please select a file that is not already displayed."
        return
    }
    
    # add the new window to the list of open windows
    lappend Endoscopic(FlatWindows) $name
    
    # package require vtkinteraction
    
    # create new toplevel for the flattened image
    toplevel .t$name -visual best
    wm title .t$name $name
    wm geometry .t$name -0+0
    wm protocol .t$name WM_DELETE_WINDOW "EndoscopicRemoveFlatView $name"
    wm withdraw .
 
    # view frame
    frame .t$name.fView
    set f .t$name.fView    

    # create a vtkTkRenderWidget to draw the flattened image into
    vtkRenderWindow Endoscopic(flatColon,renWin,$name)
    set Endoscopic(flatColon,renWidget,$name) [vtkTkRenderWidget $f.flatRenderWidget$name -width 600 -height $View(viewerHeightNormal) -rw Endoscopic(flatColon,renWin,$name)]
    
    set Endoscopic($f.flatRenderWidget$name,name) $name
    
    # control frames
    frame .t$name.controls
   
    # x frame: Scroll, Stop, Reset, Progress, Speed, and Close Flat Colon
    set xfrm [frame .t$name.controls.xfrm]
    
    set playfrm [frame .t$name.controls.xfrm.playfrm]
    set scrLbut [button $playfrm.scrLbut -text "<<" -font {helvetica 10 bold} \
    -command "EndoscopicScrollLeftFlatColon $f.flatRenderWidget$name"]
    set stpbut [button $playfrm.stpbut -text "Stop" -font {helvetica 10 bold} \
    -command "EndoscopicStopFlatColon"]
    set scrRbut [button $playfrm.scrRbut -text ">>" -font {helvetica 10 bold} \
    -command "EndoscopicScrollRightFlatColon $f.flatRenderWidget$name"]
    set resbut [button $playfrm.resbut -text "Reset" -font {helvetica 10 bold} \
    -command "EndoscopicResetFlatColon $f.flatRenderWidget$name"]
    pack $scrLbut -side left -padx 2 -expand yes -fill x
    pack $stpbut -side left -padx 2 -expand yes -fill x
    pack $scrRbut -side left -padx 2 -expand yes -fill x
    pack $resbut -side left -padx 2 -expand yes -fill x
    
    
    set progfrm [frame .t$name.controls.xfrm.progfrm]
    set proglbl [label $progfrm.lbl -text "Progress:  " -font {helvetica 10 bold} ]
    set Endoscopic(flatScale,progress) [scale $progfrm.progress -from 0 -to 250 -res 0.5 -orient horizontal \
                                     -variable Endoscopic(flatColon,xCamDist)  -bg $Endoscopic(path,sColor) ]
    pack $proglbl -side left
    pack $Endoscopic(flatScale,progress) -side right
    
    
    set speedfrm [frame .t$name.controls.xfrm.speedfrm]
    set speedlbl [label $speedfrm.lbl -text "Speed:      " -font {helvetica 10 bold} ]
    set Endoscopic(flatScale,speed) [scale $speedfrm.speed -from 0.1 -to 5 -res 0.1 -orient horizontal \
                                     -variable Endoscopic(flatColon,speed)  -bg $Endoscopic(path,sColor) ]
    pack $speedlbl -side left
    pack $Endoscopic(flatScale,speed) -side right
    
    
    set updatefrm [frame .t$name.controls.xfrm.updatefrm]
    set updatebut [button $updatefrm.updatebut -text "Update Targets on Flat Colon" -font {helvetica 10 bold} \
    -command "EndoscopicUpdateTargetsInFlatWindow $f.flatRenderWidget$name"]
    pack $updatebut -side left -padx 2 -expand yes


    #pack xfrm
    pack $playfrm -side top -pady 4 -expand yes
    pack $progfrm -side top -pady 4 -expand yes
    pack $speedfrm -side top -pady 4 -expand yes
    pack $updatefrm -side top -pady 4 -expand yes
    
 
    
    # y frame: Zoom, Center Viewpoint, and Close Flat Colon
    set yfrm [frame .t$name.controls.yfrm]
    
    set zoomfrm [frame .t$name.controls.yfrm.zoomfrm]        
    set camZoomlbl [label $zoomfrm.lbl -text "Zoom In<-->Zoom Out" -font {helvetica 10}]
    set Endoscopic(flatScale,camZoom) [scale $zoomfrm.camZoom -from 0 -to 100 -res 0.5 -orient horizontal  -variable Endoscopic(flatColon,zCamDist)]
    pack $camZoomlbl -side top
    pack $Endoscopic(flatScale,camZoom) -side top
    
      
    set optzfrm [frame $yfrm.optzfrm]
    set optzbut [button $optzfrm.optzbut -text "Center Viewpoint" -font {helvetica 10 bold} \
    -command "EndoscopicResetFlatCameraDist $f.flatRenderWidget$name"]
    pack $optzbut -side top -pady 4 -expand yes -fill x
    
    
    set scalarOnOfffrm [frame $yfrm.scalarOnOfffrm]
    set scaOnOfflbl [label $scalarOnOfffrm.lbl -text "Curvature Analysis:" -font {helvetica 10 bold}]
    pack $scaOnOfflbl -side left -padx 2
    
    foreach text "{On} {Off}" \
            value "1 0" \
            width "4 4" {
        eval {radiobutton $scalarOnOfffrm.$value -width $width \
            -font {helvetica 10 bold}\
                -text "$text" -value "$value" -variable Endoscopic(flatColon,scalarVisibility) \
                -command "EndoscopicSetFlatColonScalarVisibility $f.flatRenderWidget$name" \
                -indicatoron 0}
        pack $scalarOnOfffrm.$value -side left -padx 2
    }

    
    
    set scalarRangefrm [frame $yfrm.scalarRangefrm]
    set scaRangelbl [label $scalarRangefrm.lbl -text "Scalar Range:" -font {helvetica 10 bold}]
    eval {entry $scalarRangefrm.eLo -width 6 -textvariable Endoscopic(flatColon,scalarLow) }
    bind $scalarRangefrm.eLo <Return> "EndoscopicSetFlatColonScalarRange $f.flatRenderWidget$name"
    bind $scalarRangefrm.eLo <FocusOut> "EndoscopicSetFlatColonScalarRange $f.flatRenderWidget$name"
    eval {entry $scalarRangefrm.eHi -width 6 -textvariable Endoscopic(flatColon,scalarHigh) }
    bind $scalarRangefrm.eHi <Return> "EndoscopicSetFlatColonScalarRange $f.flatRenderWidget$name"
    bind $scalarRangefrm.eHi <FocusOut> "EndoscopicSetFlatColonScalarRange $f.flatRenderWidget$name"
    pack $scaRangelbl $scalarRangefrm.eLo $scalarRangefrm.eHi -side left -padx 2

    


    #pack yfrm
    pack $zoomfrm -side top -pady 2 -expand yes
    pack $optzfrm -side top -pady 2 -expand yes
    pack $scalarOnOfffrm -side top -pady 2 -expand yes
    pack $scalarRangefrm -side top -pady 2 -expand yes
   

    # the following scale is left un-packed, because it will be removed eventually
    set udlbl [label $yfrm.lbl -text "Up/Down" -font {helvetica 10} ]
    set Endoscopic(flatScale,panud) [scale $yfrm.updown -from -10 -to 10 -res 0.5 -orient vertical -variable Endoscopic(flatColon,yCamDist)]
    #pack $udlbl $Endoscopic(flatScale,panud) -side top -pady 4 -expand yes

   

    # light frame: change the light positions, elevation and azimuth
    set lfrm [frame .t$name.controls.lfrm]
    
    set elefrm [frame .t$name.controls.lfrm.elefrm]
    set elelbl [label $elefrm.lbl -text "-90<- Elevation ->90" -font {helvetica 10}]

    set Endoscopic(flatScale,elevation) [scale $elefrm.elevation -from -90 -to 90 -res 5.0 -orient horizontal  -variable Endoscopic(flatColon,LightElev) ]
    pack $elelbl -side top
    pack $Endoscopic(flatScale,elevation) -side top
    
 
    set azifrm [frame .t$name.controls.lfrm.azifrm]        
    set azilbl [label $azifrm.lbl -text "-90<- Azimuth ->90" -font {helvetica 10}]
    set Endoscopic(flatScale,azimuth) [scale $azifrm.azimuth -from -90 -to 90 -res 5.0 -orient horizontal  -variable Endoscopic(flatColon,LightAzi)]
    pack $azilbl -side top
    pack $Endoscopic(flatScale,azimuth) -side top
    
    
    set quitfrm [frame .t$name.controls.lfrm.quitfrm]
    set quitbut [button $quitfrm.quitbut -text "Close Flat Colon" -font {helvetica 10 bold} \
    -command "EndoscopicRemoveFlatView $name"]
    pack $quitbut -side bottom -pady 4 -expand yes -fill x
    
    
    #the following is left unpacked, since the test function will be removed eventually
    #set coordfrm [frame .t$name.controls.lfrm.coordfrm]
    #set coordlbl [label $coordfrm.lbl -text "x: 0 y: "]
    #pack $coordlbl -side top
    #pack $coordfrm -side top -pady 4 -expand yes


    pack $elefrm -side top -pady 2 -expand yes
    pack $azifrm -side top -pady 2 -expand yes
    pack $quitfrm -side top -pady 2 -expand yes
    
    
    # pack control frames
    pack .t$name.controls.xfrm -side left  -padx 1 -anchor n -expand yes
    pack .t$name.controls.yfrm -side left -padx 1 -anchor n -expand yes
    pack .t$name.controls.lfrm -side right -padx 1 -anchor n -expand yes
    
    # pack render widget and controls    
    pack $f.flatRenderWidget$name -side left -padx 3 -pady 3 -fill both -expand t
    pack $f -fill both -expand t
    pack .t$name.controls -pady 4 -fill both -expand t

   
    # add a vtkRenderer to the vtkRenderWindow   
    vtkRenderer Endoscopic($name,renderer)
    Endoscopic($name,renderer) SetBackground 0.5 0.5 0.5
    Endoscopic(flatColon,renWin,$name) AddRenderer Endoscopic($name,renderer)
    
    lappend $Endoscopic(FlatRenderers) Endoscopic($name,renderer)
    
    #activate interactor
#    vtkRenderWindowInteractor iren
#    iren SetRenderWindow [$f.flatRenderWidget$name GetRenderWindow]


    # set and activate event bindings for this widget
     EndoscopicCreateFlatBindings $f.flatRenderWidget$name
     
    # create lookup table for mapping scalars representing the curvature analysis
     EndoscopicBuildFlatColonLookupTable $name
    
    # Update targets (Fiducials) that were saved in the MRML Tree
 #   $updatebut config -command "EndoscopicUpdateTargetsInFlatWindow $f.flatRenderWidget$name"

    # create a vtkPolyDataReader
    vtkPolyDataReader TempPolyReader   
    TempPolyReader SetFileName $Endoscopic(FlatSelect)

    # create a vtkPolyDataMapper
    vtkPolyDataMapper Endoscopic($name,FlatColonMapper)
    Endoscopic($name,FlatColonMapper) SetInput [TempPolyReader GetOutput]
#    Endoscopic($name,FlatColonMapper) ScalarVisibilityOn
#    Endoscopic($name,FlatColonMapper) SetScalarRange 0 100
    Endoscopic($name,FlatColonMapper) ScalarVisibilityOff
#    Endoscopic($name,FlatColonMapper) SetScalarMaterialModeToAmbientAndDiffuse
        
    # save the polydata where we can find it later
    set Endoscopic($name,polyData) [TempPolyReader GetOutput]
    $Endoscopic($name,polyData) UpdateData
      
    # create a vtkActor for the flatcolon, and set its properties
    vtkActor Endoscopic($name,FlatColonActor)
   [Endoscopic($name,FlatColonActor) GetProperty] SetInterpolationToPhong
   [Endoscopic($name,FlatColonActor) GetProperty] SetColor 1.0 0.8 0.7
   [Endoscopic($name,FlatColonActor) GetProperty] SetAmbient 0.55
   [Endoscopic($name,FlatColonActor) GetProperty] SetDiffuse 0.4
   [Endoscopic($name,FlatColonActor) GetProperty] SetSpecular 0.5
   [Endoscopic($name,FlatColonActor) GetProperty] SetSpecularPower 100
   
   [Endoscopic($name,FlatColonActor) GetProperty] BackfaceCullingOff
    
    Endoscopic($name,FlatColonActor) SetMapper Endoscopic($name,FlatColonMapper)
    Endoscopic($name,renderer) AddActor Endoscopic($name,FlatColonActor)
    
    # create 2 vtkActors for the boundary of the flatcolon, since the flat colon we loaded above has overlap
    EndoscopicBuildFlatBoundary $name
#    Endoscopic($name,renderer) AddActor Endoscopic(flatColon,$name,aPolyLineActor1)
    
    
    #create Outline
    vtkOutlineFilter colonOutline
      colonOutline SetInput [TempPolyReader GetOutput]
    vtkPolyDataMapper outlineMapper
      outlineMapper SetInput [colonOutline GetOutput]
    vtkActor Endoscopic($name,outlineActor)
      Endoscopic($name,outlineActor) SetMapper outlineMapper
      
  #    Endoscopic($name,outlineActor) SetScale 1.0 1. 1.0
  #    Endoscopic($name,outlineActor) SetPosition 0.0 0.0 0.0
      
      [Endoscopic($name,outlineActor) GetProperty] SetColor 0 0 0
    Endoscopic($name,renderer) AddActor Endoscopic($name,outlineActor)
    
    set size [Endoscopic($name,renderer) GetSize]
        
    set outline [$Endoscopic($name,polyData) GetBounds]
    set Endoscopic(flatColon,xMin) [lindex $outline 0]
    set Endoscopic(flatColon,xMax) [lindex $outline 1]
    set Endoscopic(flatColon,yMin) [lindex $outline 2]
    set Endoscopic(flatColon,yMax) [lindex $outline 3]
    set Endoscopic(flatColon,zMin) [lindex $outline 4]
    set Endoscopic(flatColon,zMax) [lindex $outline 5]  

    # normalize the initial camera position   
    set y [expr $Endoscopic(flatColon,yMax) - $Endoscopic(flatColon,yMin)]
    set y [expr abs($y)]
    set Endoscopic(flatColon,zOpt) [expr [expr 5*$y]/8]
    
    set Endoscopic(flatColon,yMid) [expr [expr $Endoscopic(flatColon,yMin) + $Endoscopic(flatColon,yMax)]/2]

    # re-config the scale according to the size of the flat colon        
    $Endoscopic(flatScale,progress) config -from [expr [expr floor($Endoscopic(flatColon,xMin))]-1] -to [expr ceil($Endoscopic(flatColon,xMax))]
    $Endoscopic(flatScale,panud) config -from [expr [expr ceil($Endoscopic(flatColon,yMin))]-2] -to [expr [expr ceil($Endoscopic(flatColon,yMax))]+2]
    $Endoscopic(flatScale,camZoom) config -from 0 -to [expr [expr ceil($Endoscopic(flatColon,zOpt))] + 300]

    # set initial camera position   
    set Endoscopic(flatColon,xCamDist) [expr [expr floor($Endoscopic(flatColon,xMin))]-1]
    $Endoscopic(flatScale,progress) set $Endoscopic(flatColon,xCamDist)
    
    set Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,yMid)
    $Endoscopic(flatScale,panud) set $Endoscopic(flatColon,yCamDist)
    
    set Endoscopic(flatColon,zCamDist) $Endoscopic(flatColon,zOpt) 
    $Endoscopic(flatScale,camZoom) set $Endoscopic(flatColon,zCamDist)
    
    set Endoscopic($name,camera) [Endoscopic($name,renderer) GetActiveCamera]
    $Endoscopic($name,camera) SetClippingRange 0.01 4000
    $Endoscopic($name,camera) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zMin)
    $Endoscopic($name,camera) SetPosition $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
    $Endoscopic($name,camera) SetViewAngle 90
    # $Navigator($name,camera) Zoom 1
  
    # add command for moving the colon in x y directions and zooming.  
    $Endoscopic(flatScale,progress) config -command "EndoscopicMoveCameraX $f.flatRenderWidget$name"
    $Endoscopic(flatScale,panud) config -command "EndoscopicMoveCameraY $f.flatRenderWidget$name" 
    $Endoscopic(flatScale,camZoom) config -command "EndoscopicMoveCameraZ $f.flatRenderWidget$name"
    
     # lightKit
     
     set Endoscopic(flatColon,LightElev) 0
     set Endoscopic(flatColon,LightAzi) -45

     vtkLightKit Endoscopic($name,lightKit)
     Endoscopic($name,lightKit) SetKeyLightWarmth 0.5
     Endoscopic($name,lightKit) SetHeadlightWarmth 0.5
     Endoscopic($name,lightKit) SetKeyLightIntensity 0.7
     Endoscopic($name,lightKit) SetKeyLightElevation $Endoscopic(flatColon,LightElev)
     Endoscopic($name,lightKit) SetKeyLightAzimuth $Endoscopic(flatColon,LightAzi)
#     Endoscopic($name,lightKit) SetKeyLightAngle 30 -30
     Endoscopic($name,lightKit) SetKeyToFillRatio 5
     Endoscopic($name,lightKit) AddLightsToRenderer Endoscopic($name,renderer)
     
     #light
#     vtkLight Endoscopic($name,light)
#     Endoscopic($name,light) SetIntensity 0.3
#     Endoscopic($name,light) SetPosition [expr $Endoscopic(flatColon,xCamDist)-10] $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
#     Endoscopic($name,light) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zMin)
#     Endoscopic($name,light) SetDirectionAngle 0 0
#     Endoscopic($name,renderer) AddLight Endoscopic($name,light)
     
     # add command for changing the light's elevation and azimuth
     $Endoscopic(flatScale,elevation) config -command "EndoscopicFlatLightElevationAzimuth $f.flatRenderWidget$name"
     $Endoscopic(flatScale,azimuth) config -command "EndoscopicFlatLightElevationAzimuth $f.flatRenderWidget$name"
  
    # initialize and reinitialize
    set Endoscopic($name,lineCount) 0
    #set Endoscopic(FlatSelect) ""
    
    set Endoscopic(flatColon,speed) 3.0

    #Render
    #[$f.flatRenderWidget$name GetRenderWindow] Render  
    Endoscopic(flatColon,renWin,$name) Render

    TempPolyReader Delete
#    TempMapper Delete
    colonOutline Delete
    outlineMapper Delete

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicRemoveFlatView
# Remove the flattened colon window and everything related to it.<br>
# Pop Bindings here
# .ARGS
# string name defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicRemoveFlatView {{name ""}} {
    global Module Endoscopic View

    # if clicked 'Quit' button
    if {$name != ""} {
    
        set f .t$name.fView
    
        # destroy all parts of the flat view
        #puts "window close $name"    
        Endoscopic($name,FlatColonActor) Delete
        Endoscopic($name,FlatColonMapper) Delete
        
        Endoscopic(flatColon,lookupTable,$name) Delete
        
        # actor for flattened image
        Endoscopic($name,outlineActor) Delete
        Endoscopic($name,lightKit) Delete
        #    Endoscopic($name,light) Delete
        
        Endoscopic(flatColon,$name,Line1Actor) Delete
        Endoscopic(flatColon,$name,Line2Actor) Delete
        
    
        for {set linecount 0} {$linecount < $Endoscopic($name,lineCount)} {incr linecount} {
            Endoscopic($name,aLineActor,$linecount) Delete
        }
        set $Endoscopic($name,lineCount) 0
    
        set index [lsearch -exact $Endoscopic(FlatWindows) $name]
        set Endoscopic(FlatWindows) [lreplace $Endoscopic(FlatWindows) $index $index]
        set Endoscopic(FlatRenderers) [lreplace $Endoscopic(FlatRenderers) $index $index]
        
        Endoscopic($name,renderer) Delete
        Endoscopic(flatColon,renWin,$name) Delete
        # Endoscopic(flatColon,renWidget,$name) Delete
        
        
        destroy .t$name
        
    } else {
        
        #        if ending all
        
        foreach frame $Endoscopic(FlatWindows) {
            destroy .t$frame
            #puts "frame close $frame"      
            Endoscopic($frame,renderer) Delete
            Endoscopic($frame,FlatColonActor) Delete
            Endoscopic($frame,outlineActor) Delete
            Endoscopic($frame,lightKit) Delete
            Endoscopic($frame,light) Delete
        }
        
        set index [lsearch -exact $Endoscopic(FlatWindows) $name]
        set Endoscopic(FlatWindows) [lreplace $Endoscopic(FlatWindows) $index $index]
        set Endoscopic(FlatRenderers) [lreplace $Endoscopic(FlatRenderers) $index $index]
        
    }
    
   
    set Endoscopic(FlatSelect) ""
    set Endoscopic(flatColon,name) ""
    
    set Endoscopic(flatColon,scalarVisibility) 0
    set Endoscopic(flatColon,scalarLow) 0    
    set Endoscopic(flatColon,scalarHigh) 100
        
    # de-activate bindings for the flat window   
    EndoscopicPopFlatBindings
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateFlatBindings
# Create and Activate binding sets that allow the user to double click at a location on the flattened colon,
# move the endoscope to the corresponding location in 3D, and sychronize the 2D slices as well
# .ARGS
# windowelement widget the window to add the bindings to
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateFlatBindings {widget} {
    global Endoscopic Ev

 # the following 2 lines are for testing the bindings the old fashioned way.
 #    bind $widget <ButtonRelease-1> {puts Button}
 #    bind $widget <KeyPress-c> {EndoscopicPickFlatPoint %W %x %y}
 
# FlatWindow Expose Pan and Zoom bindings
    EvDeclareEventHandler FlatWindowExpose <Expose> {%W Render}
    EvDeclareEventHandler FlatWindowStartPan <ButtonPress-2> {EndoscopicStartPan %W %x %y}
    EvDeclareEventHandler FlatWindowB2Motion <B2-Motion> {EndoscopicEndPan %W %x %y}
    EvDeclareEventHandler FlatWindowEndPan <ButtonRelease-2> {EndoscopicEndPan %W %x %y}
    EvDeclareEventHandler FlatWindowStartZoom <ButtonPress-3> {EndoscopicStartZoom %W %y}
    EvDeclareEventHandler FlatWindowB3Motion <B3-Motion> {EndoscopicEndZoom %W %y}
    EvDeclareEventHandler FlatWindowEndZoom <ButtonRelease-3> {EndoscopicEndZoom %W %y}

#FlatWindow Pick target binding    
    EvDeclareEventHandler FlatWindowEvents <Shift-Double-1> {EndoscopicPickFlatPoint %W %x %y}

#test binding to track mouse position
#    EvDeclareEventHandler FlatMotionEvents <Motion> {EndoscopicMouseLocation %W %x %y}

    #add various events to the binding set for the flat window
    EvAddWidgetToBindingSet bindFlatWindowEvents $widget {{FlatWindowEvents} {FlatWindowExpose} \
    {FlatWindowStartPan} {FlatWindowB2Motion} {FlatWindowEndPan}}
    
# the zoom function with B3 is temporarily disabled, pending feed back from user
# to activate: append the following 3 bindings to  EvAddWidgetToBindingSet  
#     {FlatWindowStartZoom} {FlatWindowB3Motion} {FlatWindowEndZoom}

    #activate the binding set for the flat window
    EvActivateBindingSet bindFlatWindowEvents
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicPopFlatBindings
# Deactivate binding sets when the user closes the flat colon view.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicPopFlatBindings {} {
    global Ev Csys Endoscopic
   
    EvDeactivateBindingSet bindFlatWindowEvents
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicBuildFlatColonLookupTable
# Builds a colour look up talbe for the flat colon view
# .ARGS
# string name partial name for the colour table, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicBuildFlatColonLookupTable {{name ""}} {
    global Endoscopic
     
    vtkLookupTable Endoscopic(flatColon,lookupTable,$name)
    #actual values are from 0 to 255
    Endoscopic(flatColon,lookupTable,$name) SetNumberOfColors 256
    Endoscopic(flatColon,lookupTable,$name) Build
     
    set colon 64
    set polyp 64
    set transL $colon
    set transH [expr [expr 256 - $polyp] + 1]
    
    # for the first 64 slots in the table, set the color to be the same as the colon (skin rgb: 1.0 0.8 0.7)
    for {set i 0} {$i < $colon} {incr i} {
        eval Endoscopic(flatColon,lookupTable,$name) SetTableValue $i 1.0 0.8 0.7 1
    }
    
    # for the next 128 slots in the table, set the color to be in transition from skin to green
    # i.e., green value increases to 1, and both the red and the blue values decrease to 0
    for {set i $transL} {$i < $transH} {incr i} {
        
        set numSteps [expr [expr $transH - $transL] + 1]
        
        set redDecr [expr 1.0 / $numSteps]
        set greenIncr [expr [expr 1.0 - 0.8] / $numSteps]
        set blueDecr [expr 0.7 / $numSteps]
        
        set red [expr 1.0 - [expr [expr $i - $transL] * $redDecr]]
        set green [expr 0.8 + [expr [expr $i - $transL] * $greenIncr]]
        set blue [expr 0.7 - [expr [expr $i - $transL] * $blueDecr]]
        
        eval Endoscopic(flatColon,lookupTable,$name) SetTableValue $i $red $green $blue 0.9
    }
    
    # for the last 64 slots in the table, set the color to be green (rgb: 0 1 0)
    for {set i $transH} {$i < 256} {incr i} {
        eval Endoscopic(flatColon,lookupTable,$name) SetTableValue $i 0.0 1.0 0.0 1
    }   
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicBuildFlatBoundary
# Create the boundary line around the flat view.
# .ARGS
# string name name of the line actor, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicBuildFlatBoundary {{name ""}} {

     global Endoscopic
     
     set line1name $Endoscopic(flatColon,filePath)
     set line2name $Endoscopic(flatColon,filePath)
     append line1name _Line1.txt
     append line2name _Line2.txt
     # Create the 1st boundary line     
     set fp1 [open $line1name r]
     set data1 [read $fp1]
     set line1s [split [string trim $data1] "\n"]
     
     set line1numP [lindex $line1s 0]
#     puts "line1 number of points: $line1numP"
     
     vtkPoints Line1Points
     Line1Points SetNumberOfPoints $line1numP
     for {set i 1} {$i <= $line1numP} {incr i} {
         set point [lindex $line1s $i]
     
         set x [lindex $point 0]
         set y [lindex $point 1]
         set z [lindex $point 2]
         
         Line1Points InsertPoint $i $x $y $z
     }
     
     vtkCellArray Line1Cells
     Line1Cells InsertNextCell $line1numP
     
     for {set i 1} {$i <= $line1numP} {incr i} {
         Line1Cells InsertCellPoint $i
     }
     
     vtkPolyData Line1
     Line1 SetPoints Line1Points
     Line1 SetLines Line1Cells
     
     
     vtkPolyDataMapper Line1Mapper
     Line1Mapper SetInput Line1
     
     vtkActor Endoscopic(flatColon,$name,Line1Actor)
     Endoscopic(flatColon,$name,Line1Actor) SetMapper Line1Mapper
     
     [Endoscopic(flatColon,$name,Line1Actor) GetProperty] SetColor 0 0 0
     
     Endoscopic($name,renderer) AddActor Endoscopic(flatColon,$name,Line1Actor)
     
     Line1Points Delete
     Line1Cells Delete
     Line1 Delete
     Line1Mapper Delete
     
     # Create the 2nd boundary line
     
     set fp2 [open $line2name r]
     set data2 [read $fp2]
     set line2s [split [string trim $data2] "\n"]
     
     set line2numP [lindex $line2s 0]
     #     puts "line2 number of points: $line2numP"
     
     vtkPoints Line2Points
     Line2Points SetNumberOfPoints $line2numP
     for {set i 1} {$i <= $line2numP} {incr i} {
         set point [lindex $line2s $i]
         
         set x [lindex $point 0]
         set y [lindex $point 1]
         set z [lindex $point 2]
         
         Line2Points InsertPoint $i $x $y $z
     }
     
     vtkCellArray Line2Cells
     Line2Cells InsertNextCell $line2numP
     
     for {set i 1} {$i <= $line2numP} {incr i} {
         Line2Cells InsertCellPoint $i
     }
     
     vtkPolyData Line2
     Line2 SetPoints Line2Points
     Line2 SetLines Line2Cells
     
     
     vtkPolyDataMapper Line2Mapper
     Line2Mapper SetInput Line2
     
     vtkActor Endoscopic(flatColon,$name,Line2Actor)
     Endoscopic(flatColon,$name,Line2Actor) SetMapper Line2Mapper
     
     [Endoscopic(flatColon,$name,Line2Actor) GetProperty] SetColor 0 0 0
     
     Endoscopic($name,renderer) AddActor Endoscopic(flatColon,$name,Line2Actor)
     
     Line2Points Delete
     Line2Cells Delete
     Line2 Delete
     Line2Mapper Delete     
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicMouseLocation
# Test proc to track mouse location in the flat window
# .ARGS
# windowelement widget the flat window
# int xcoord mouse location in x
# int ycoord mouse location in y
# .END
#-------------------------------------------------------------------------------
proc EndoscopicMouseLocation {widget xcoord ycoord} {
    global Endoscopic
    
    set name $Endoscopic($widget,name)
    .t$name.controls.lfrm.coordfrm.lbl configure -text "x: $xcoord  y: $ycoord"

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicStartPan
# Set the x and y start points for panning.
# .ARGS
# windowelement widget flat window
# int xcoord start panning here in x
# int ycoord start panning here in y
# .END
#-------------------------------------------------------------------------------
proc EndoscopicStartPan {widget xcoord ycoord} {
     global Endoscopic

    set name $Endoscopic($widget,name)

    set Endoscopic($name,pan,xstart) $xcoord
    set Endoscopic($name,pan,ystart) $ycoord     
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicEndPan
# End panning through the flat view
# .ARGS
# windowelement widget flat window
# int xcoord x point for panning
# int ycoord y point for panning
# .END
#-------------------------------------------------------------------------------
proc EndoscopicEndPan {widget xcoord ycoord} {
     global Endoscopic
     
    set name $Endoscopic($widget,name)

    set xstart $Endoscopic($name,pan,xstart)
    set ystart $Endoscopic($name,pan,ystart)

    set dx [expr $xcoord - $xstart]
    set dy [expr $ycoord - $ystart]

    set position [$Endoscopic($name,camera) GetPosition]
    set x1 [lindex $position 0]
    set y1 [lindex $position 1]
    set z1 [lindex $position 2]

    set x2 [expr $x1 - [expr $dx * .01]]
    set y2 [expr $y1 + [expr $dy * .01]]
    
    if {$x2 < [expr ceil($Endoscopic(flatColon,xMax))] } {
    
        $Endoscopic($name,camera) SetFocalPoint $x2 $y2 0
        $Endoscopic($name,camera) SetPosition $x2 $y2 $z1
    
        set Endoscopic(flatColon,xCamDist) $x2
        set Endoscopic(flatColon,yCamDist) $y2
        
        [$widget GetRenderWindow] Render
    
    } elseif {$x2 < [expr [expr floor($Endoscopic(flatColon,xMin))]-0.5] } {
        set Endoscopic(flatColon,xCamDist) [expr floor($Endoscopic(flatColon,xMin))]
    } else {
        set Endoscopic(flatColon,xCamDist) [expr ceil($Endoscopic(flatColon,xMax))]
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicStartZoom
# Set the zoom y start position.
# .ARGS
# windowelement widget flat window
# int ycoord zoom's y start position
# .END
#-------------------------------------------------------------------------------
proc EndoscopicStartZoom {widget ycoord} {
     global Endoscopic
    
    set name $Endoscopic($widget,name)
    set Endoscopic($name,zoom,ystart) $ycoord     
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicEndZoom
# End zooming in flat window.
# .ARGS
# windowelement widget flat window
# int ycoord zoom y start position
# .END
#-------------------------------------------------------------------------------
proc EndoscopicEndZoom {widget ycoord} {
    global Endoscopic

    set name $Endoscopic($widget,name)

    set ystart $Endoscopic($name,zoom,ystart)
    set dy [expr $ycoord - $ystart]
    
    # log base b of x = log(x) / log(b)
    set b      1.02
    set zPrev  1.5
    set dyPrev [expr log($zPrev) / log($b)]

    set zoom [expr pow($b, ($dy + $dyPrev))]
    if {$zoom < 0.01} {
        set zoom 0.01
    }
    set z [format "%.2f" $zoom]

    $Endoscopic($name,camera) Zoom $z
    
    set position [$Endoscopic($name,camera) GetPosition]
    set Endoscopic(flatColon,zCamDist) [lindex $position 2]
    
    [$widget GetRenderWindow] Render     
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicPickFlatPoint
# Use vtkCellPicker to identify the cell Id and location of interest.
# .ARGS
# windowelement widget flat window
# int xcoord picked x location
# int ycoord picked y location
# .END
#-------------------------------------------------------------------------------
proc EndoscopicPickFlatPoint {widget xcoord ycoord} {
    global Select Endoscopic Model Fiducials
    
     set model $Model(activeID)
     if {$model != ""} {
         set polyData3D $Model($model,polyData)
     }
     
    set numP [$polyData3D GetNumberOfPoints]
    
    #puts "start pick: clock format [clock seconds]"
    set name $Endoscopic($widget,name)
    
    vtkCellPicker TempCellPicker
    TempCellPicker SetTolerance 0.001
    
    
    #get the target coordinates in the flat window to draw a crosshair
    if {[SelectPick TempCellPicker $widget $xcoord $ycoord] != 0} {
    
        set fx [lindex $Select(xyz) 0]
        set fy [lindex $Select(xyz) 1]
        set fz [lindex $Select(xyz) 2]
        
        #puts "end pick : clock format [clock seconds]"
        
        
        #get the picked pointId from the picker, and pass the pointId to the 3D model in slicer
        
        set name $Endoscopic(flatColon,name)  
        set polyData $Endoscopic($name,polyData)
        
        #reduce point number by half
        #    set numP [$polyData GetNumberOfPoints]
        # puts "nump for the doubled model is: $numP"
        #    set numP  [expr $numP/2] 
        # puts "nump for the single model is: $numP"    
        #puts "start locate point: clock format [clock seconds]"     
        vtkPointLocator tempPointLocator
        tempPointLocator SetDataSet $polyData
        
        #    set x [lindex $Select(xyz) 0]
        #    set y [lindex $Select(xyz) 1]
        #    set z [lindex $Select(xyz) 2]
        
        set pointId [tempPointLocator FindClosestPoint $fx $fy $fz]
        # puts "picked pointId from the double model is $pointId"
        #puts "end locate point: clock format [clock seconds]"    
        # check if the pointId is larger than numP
        if {$pointId > $numP} {
            set pointId [expr $pointId - $numP]
        }
        
        # puts "picked pointId from the single model is $pointId"   
        
        
        EndoscopicAddTargetInFlatWindow $widget $fx $fy $fz
        
        
        EndoscopicAddTargetFromFlatColon $pointId
        
    } else {
        return
    }
   
    TempCellPicker Delete
    tempPointLocator Delete
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddTargetInFlatWindow
# Draw a vertical red line behind the flattened colon at locations of interest selected by the user.
# .ARGS
# windowelement widget flat window
# int x x of selected point
# int y y of selected point
# int z z of selected point
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddTargetInFlatWindow {widget x y z} {

    global Select Endoscopic
#puts  "start draw in flatwindow: clock format [clock seconds]"
    set name $Endoscopic($widget,name)
    set renderer [[[$widget GetRenderWindow] GetRenderers] GetItemAsObject 0]
    set count $Endoscopic($name,lineCount)

# make top verticle line of the cursor
    vtkLineSource aLineT
    
    aLineT SetPoint1 $x [expr $y - 20]  [expr $z + 0.01]
    aLineT SetPoint2 $x [expr $y - 10]  [expr $z + 0.01]

    aLineT SetResolution 20
    vtkPolyDataMapper aLineTMapper
    aLineTMapper SetInput [aLineT GetOutput]

    vtkActor Endoscopic($name,aLineActor,$count)
    Endoscopic($name,aLineActor,$count) SetMapper aLineTMapper 
    [Endoscopic($name,aLineActor,$count) GetProperty] SetColor 1 0 0    
    
    $renderer AddActor Endoscopic($name,aLineActor,$count)

    set Endoscopic($name,lineCount) [expr $Endoscopic($name,lineCount) + 1]
    
    aLineT Delete
    aLineTMapper Delete
    
# make bottom verticle line of the cursor   
    
    set count $Endoscopic($name,lineCount)
    vtkLineSource aLineB

    aLineB SetPoint1 $x [expr $y + 10]  [expr $z + 0.01]
    aLineB SetPoint2 $x [expr $y + 20]  [expr $z + 0.01]  

    aLineB SetResolution 20
    vtkPolyDataMapper aLineBMapper
    aLineBMapper SetInput [aLineB GetOutput]

    vtkActor Endoscopic($name,aLineActor,$count)
    Endoscopic($name,aLineActor,$count) SetMapper aLineBMapper 
    [Endoscopic($name,aLineActor,$count) GetProperty] SetColor 1 0 0    
    
    $renderer AddActor Endoscopic($name,aLineActor,$count)

    set Endoscopic($name,lineCount) [expr $Endoscopic($name,lineCount) + 1]
    
    aLineB Delete
    aLineBMapper Delete
    
# make left horizontal line of the cursor   
    
    set count $Endoscopic($name,lineCount)
    vtkLineSource aLineL

    aLineL SetPoint1 [expr $x - 20] $y [expr $z + 0.01]
    aLineL SetPoint2 [expr $x - 10] $y [expr $z + 0.01]  

    aLineL SetResolution 20
    vtkPolyDataMapper aLineLMapper
    aLineLMapper SetInput [aLineL GetOutput]

    vtkActor Endoscopic($name,aLineActor,$count)
    Endoscopic($name,aLineActor,$count) SetMapper aLineLMapper 
    [Endoscopic($name,aLineActor,$count) GetProperty] SetColor 1 0 0    
    
    $renderer AddActor Endoscopic($name,aLineActor,$count)

    set Endoscopic($name,lineCount) [expr $Endoscopic($name,lineCount) + 1]
    
    aLineL Delete
    aLineLMapper Delete

# make right horizontal line of the cursor   
    
    set count $Endoscopic($name,lineCount)
    vtkLineSource aLineR

    aLineR SetPoint1 [expr $x + 10] $y [expr $z + 0.01]
    aLineR SetPoint2 [expr $x + 20] $y [expr $z + 0.01]  

    aLineR SetResolution 20
    vtkPolyDataMapper aLineRMapper
    aLineRMapper SetInput [aLineR GetOutput]

    vtkActor Endoscopic($name,aLineActor,$count)
    Endoscopic($name,aLineActor,$count) SetMapper aLineRMapper 
    [Endoscopic($name,aLineActor,$count) GetProperty] SetColor 1 0 0    
    
    $renderer AddActor Endoscopic($name,aLineActor,$count)
    [$widget GetRenderWindow] Render

    set Endoscopic($name,lineCount) [expr $Endoscopic($name,lineCount) + 1]
    
    aLineR Delete
    aLineRMapper Delete
#puts "end draw in flatwindow: clock format [clock seconds]"
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddTargetFromFlatColon
# Find and sychronize the corresponing location in 3D colon and 2D slices that 
# corresponds to the location selected on the flattened colon
# .ARGS
# int pointId the id of the fiducial point
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddTargetFromFlatColon {pointId} {

    global Endoscopic Point Fiducials Select Model View Path Slice Volume Volumes
    
#  If no path selected, do nothing.

    if {$Endoscopic(path,activeId) == "None"} {
        return
    }    
    
    set pointId $pointId

# puts "pointId from FlatColon is $pointId"

# get the xyz coordinates of the point (picked from the flat colon) in the 3D colon.  
       set model $Model(activeID)
       if {$model != ""} {

           set polyData $Model($model,polyData)
       
           set point(xyz) [$polyData GetPoint $pointId]

           set actor Model($model,actor,viewRen)

       }

#  active list (should be the default path just created from the automatic tab)
    set fid $Fiducials($Fiducials(activeList),fid)
    set listName $Fiducials(activeList)

    FiducialsGetPointIdListFromName $listName
    
    set list $Fiducials($fid,pointIdList)
    set numP [llength $list]

    set numP [expr $numP - 1]

# compute the distance between the selected point and each point on the path.
    for {set i 0} {$i <= $numP} {incr i} {
    set pid [lindex $list $i]
    set pidCoord [FiducialsGetPointCoordinates $pid]
    set dist 0
      for {set ii 0} {$ii<3} {incr ii} {
      set diff [expr [lindex $point(xyz) $ii] - [lindex $pidCoord $ii]]
      set diff [expr $diff * $diff]
      set dist [expr $dist + $diff]
      }
    set dist [expr sqrt( $dist )]
    lappend distlist $dist    
    }

# findout the pid of the point that has the shortest distance to the selected point
    set oldlist $distlist
    set newlist [lsort -real -increasing $oldlist]
    set mindist [lindex $newlist 0]

    set minDistIndex [lsearch -exact $oldlist $mindist]
    set closestPid [lindex $list $minDistIndex]

# change the FXYZ of the closestPid to the coordinates of point(xyz) obtained from the picked point.
    set fx [lindex $point(xyz) 0]
    set fy [lindex $point(xyz) 1]
    set fz [lindex $point(xyz) 2]

    Point($closestPid,node) SetFXYZ $fx $fy $fz
# use the SetDescription to store and save $pointId information.
    Point($closestPid,node) SetDescription $pointId
#puts "start 1st mrml update: clock format [clock seconds]"
#    MainUpdateMRML
#puts "end 1st mrml update: clock format [clock seconds]"   
    EndoscopicFiducialsPointSelectedCallback $fid $closestPid
    
# set the original axial slice to that location
    #set driver User
    #EndoscopicSetSliceDriver $driver

    MainSlicesSetOrientAll Slices
    set vol $Volume(activeID)
    set oriSlice [[Volume($vol,node) GetRasToIjk] MultiplyPoint $fx $fy $fz 1]
    set scanOrder [Volume($vol,node) GetScanOrder]
    set dim [Volume($vol,node) GetDimensions]
    
    if {$scanOrder == "IS" } {
    MainSlicesSetOffset 0 [expr round([lindex $oriSlice 2])]
    MainSlicesSetOffset 1 [expr round([expr [lindex $dim 0] - [lindex $oriSlice 0]])]
    MainSlicesSetOffset 2 [expr round([lindex $oriSlice 1])]

    } 
        
    RenderAll
    
# create targets   
    EndoscopicCreateTargets
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddTargetFromSlices
#  When a user selects a location on the 2D slices, the Endoscope in 3D jumps to the corresponding location
# .ARGS
# int x User selected x
# int y User selected y
# int z User selected z
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddTargetFromSlices {x y z} {

    global Endoscopic Point Fiducials Select Model View Slice Volume Volumes
    
#  If no path selected, do nothing.

    if {$Endoscopic(path,activeId) == "None"} {

        return
    }

# get the pointId from the 3D model    
    if {[info exists Select(actor)] != 0} {
        set actor $Select(actor)
    } else {
        set actor ""
    }

     set model $Model(activeID)
     if {$model != ""} {
     set polyData $Model($model,polyData)
     }
   
     vtkPointLocator tempPointLocator
     tempPointLocator SetDataSet $polyData

     set pointId [tempPointLocator FindClosestPoint $x $y $z]
     set point(xyz) [$polyData GetPoint $pointId]

#puts "pointId from Slices is: $pointId"

#  active list (should be the default path just created from the automatic tab)
    set fid $Fiducials($Fiducials(activeList),fid)
    set listName $Fiducials(activeList)
    
    FiducialsGetPointIdListFromName $listName

    set list $Fiducials($fid,pointIdList)
    set numP [llength $list]
    set numP [expr $numP - 1]

# compute the distance between the selected point and each point on the path.
    for {set i 0} {$i <= $numP} {incr i} {
    set pid [lindex $list $i]
    set pidCoord [FiducialsGetPointCoordinates $pid]
    set dist 0
      for {set ii 0} {$ii<3} {incr ii} {
      set diff [expr [lindex $point(xyz) $ii] - [lindex $pidCoord $ii]]
      set diff [expr $diff * $diff]
      set dist [expr $dist + $diff]
      }
    set dist [expr sqrt( $dist )]
    lappend distlist $dist    
    }

# findout the pid of the point that has the shortest dist to the selected point
    set oldlist $distlist
    set newlist [lsort -real -increasing $oldlist]
    set mindist [lindex $newlist 0]

    set minDistIndex [lsearch -exact $oldlist $mindist]
    set closestPid [lindex $list $minDistIndex]
    
# change the FXYZ of the closestPid to the coordinates of point(xyz) obtained from the picked point.
    set fx [lindex $point(xyz) 0]
    set fy [lindex $point(xyz) 1]
    set fz [lindex $point(xyz) 2]

    Point($closestPid,node) SetFXYZ $fx $fy $fz
# use the SetDescription to store and save $pointId information.
    Point($closestPid,node) SetDescription $pointId
    
#    MainUpdateMRML
    
    EndoscopicFiducialsPointSelectedCallback $fid $closestPid
    
tempPointLocator Delete

# set the original axial slice to that location
    #set driver User
    #EndoscopicSetSliceDriver $driver

    MainSlicesSetOrientAll Slices
    set vol $Volume(activeID)
    set oriSlice [[Volume($vol,node) GetRasToIjk] MultiplyPoint $fx $fy $fz 1]
    set scanOrder [Volume($vol,node) GetScanOrder]
    set dim [Volume($vol,node) GetDimensions]
    
    if {$scanOrder == "IS" } {
    MainSlicesSetOffset 0 [expr round([lindex $oriSlice 2])]
    MainSlicesSetOffset 1 [expr round([expr [lindex $dim 0] - [lindex $oriSlice 0]])]
    MainSlicesSetOffset 2 [expr round([lindex $oriSlice 1])]

    } 
        
    RenderAll
    

# Create Targets    
    EndoscopicCreateTargets
    
# update targets in the flat window
    if {$Endoscopic(FlatWindows) != ""} {

# Fix later: as of now I am assuming the user are working with the first flat model
# if the user want to work with several flat models at the same time, they either has to be really careful or
# insert some checking mechanism to prevent them from adding or selecting targets in the wrong flat window.    
    set name [lindex $Endoscopic(FlatWindows) 0]
    
    set widget .t$name.fView.flatRenderWidget$name
    EndoscopicUpdateTargetsInFlatWindow $widget
    }
 
  
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicAddTargetFromWorldCoordinates
#  When a user selects a location on the 3D model, the 2D slices sychronises.
# .ARGS
# int sx world x
# int sy world y
# int sz world z
# .END
#-------------------------------------------------------------------------------
proc EndoscopicAddTargetFromWorldCoordinates {sx sy sz} {
     global Endoscopic Point Fiducials Select Model View Slice Volume Volumes

#  If no path selected, do nothing.

    if {$Endoscopic(path,activeId) == "None"} {

    return
    }

           
     if {[info exists Select(actor)] != 0} {
        set actor $Select(actor)
        #set cellId $cellId
    } else {
        set actor ""
        #set cellId ""
    }

     set Select(xyz) [list $sx $sy $sz]
      
     set model $Model(activeID)
     if {$model != ""} {
     set polyData $Model($model,polyData)
     }
   
     vtkPointLocator tempPointLocator
     tempPointLocator SetDataSet $polyData

     set pointId [tempPointLocator FindClosestPoint $sx $sy $sz]
     set point(xyz) [$polyData GetPoint $pointId]

#puts "pointId from 3D colon is: $pointId"

      tempPointLocator Delete
      
# get active path-fiducial list
      set fid $Fiducials($Fiducials(activeList),fid)
      set listName $Fiducials(activeList)

      FiducialsGetPointIdListFromName $listName

      set list $Fiducials($fid,pointIdList)
      set numP [llength $list]
      set numP [expr $numP - 1]

# compute the distance between the selected point and each point on the path.
     for {set i 0} {$i <= $numP} {incr i} {
        set pid [lindex $list $i]
        set pidCoord [FiducialsGetPointCoordinates $pid]
        set dist 0
        for {set ii 0} {$ii<3} {incr ii} {
        set diff [expr [lindex $point(xyz) $ii] - [lindex $pidCoord $ii]]
        set diff [expr $diff * $diff]
        set dist [expr $dist + $diff]
     }
    set dist [expr sqrt( $dist )]
    lappend distlist $dist    
    }

# findout the pid of the point that has the shortest dist to the selected point
    set oldlist $distlist
    set newlist [lsort -real -increasing $oldlist]
    set mindist [lindex $newlist 0]

    set minDistIndex [lsearch -exact $oldlist $mindist]
    set closestPid [lindex $list $minDistIndex]

# change the FXYZ of the closestPid to the coordinates of point(xyz) obtained from the picked point.
    set fx [lindex $point(xyz) 0]
    set fy [lindex $point(xyz) 1]
    set fz [lindex $point(xyz) 2]

    Point($closestPid,node) SetFXYZ $fx $fy $fz    
# use the SetDescription to store and save $pointId information.
    Point($closestPid,node) SetDescription $pointId
    
#    MainUpdateMRML

    EndoscopicFiducialsPointSelectedCallback $fid $closestPid

# set the original axial slice to that location
    #set driver User
    #EndoscopicSetSliceDriver $driver

    MainSlicesSetOrientAll Slices
    set vol $Volume(activeID)
    set oriSlice [[Volume($vol,node) GetRasToIjk] MultiplyPoint $fx $fy $fz 1]
    set scanOrder [Volume($vol,node) GetScanOrder]
    set dim [Volume($vol,node) GetDimensions]
    
    if {$scanOrder == "IS" } {
    MainSlicesSetOffset 0 [expr round([lindex $oriSlice 2])]
    MainSlicesSetOffset 1 [expr round([expr [lindex $dim 0] - [lindex $oriSlice 0]])]
    MainSlicesSetOffset 2 [expr round([lindex $oriSlice 1])]

    } 
        
    RenderAll
    
    
# Create Targets    
    EndoscopicCreateTargets
#puts "target created??"    
# update targets in the flat window
    if {$Endoscopic(FlatWindows) != ""} {

# Fix later: as of now I am assuming the user are working with the first flat model
# if the user want to work with several flat models at the same time, they either has to be really careful or
# insert some checking mechanism to prevent them from adding or selecting targets in the wrong flat window.    
    set name [lindex $Endoscopic(FlatWindows) 0]
    
    set widget .t$name.fView.flatRenderWidget$name
    EndoscopicUpdateTargetsInFlatWindow $widget
    }
 
  
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicLoadTargets
# Given a particular path, this allows the user to reload reviously saved targets in the MRML tree.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicLoadTargets { }  {

     global Endoscopic Fiducials
     
     if {$Endoscopic(path,activeId) == "None"} {
       tk_messageBox -type ok -message "Please select a path that corresponds to the existing targets"

     } else {
 
#check to see if the path comes with a targetlist
      set id $Endoscopic(path,activeId)
      set targetlistname $Endoscopic($id,path,name)
      append targetlistname -targets
    
         if {[lsearch $Fiducials(listOfNames) $targetlistname] != -1} {
        
         set targetlist [FiducialsGetPointIdListFromName $targetlistname]
         set num [llength $targetlist] 
         set Endoscopic(selectedTarget) 1
     
         EndoscopicSelectTarget $Endoscopic(selectedTarget)
     
         set Endoscopic(totalTargets) $num
     
                if {$Endoscopic(FlatWindows) != ""} {

# Fix later: as of now I am assuming the user are working with the first flat model
# if the user want to work with several flat models at the same time, they either has to be really careful or
# insert some checking mechanism to prevent them from adding or selecting targets in the wrong flat window.    
                 set name [lindex $Endoscopic(FlatWindows) 0]
    
                 set widget .t$name.fView.flatRenderWidget$name
                 EndoscopicUpdateTargetsInFlatWindow $widget
   
                 } else {
                 return
                 }
       }
      }

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicMainFileCloseUpdated
# Reset variables when one closes a scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicMainFileCloseUpdated {}  {
     global Endoscopic Model Module
     
     if {$Endoscopic(totalTargets) != 0} {
     
         set Endoscopic(totalTargets) 0
         set Endoscopic(selectedTarget) 0
         
         set Endoscopic(path,activeId) "None"
         # change the text on menu buttons
         foreach mb $Endoscopic(mbPathList) {
             $mb config -text "None"
         }
         $Endoscopic(mbPath4Fly) config -text "None"
     }
     
     set Endoscopic(flatColon,scalarVisibility) 0
     set Endoscopic(flatColon,scalarLow) 0
     set Endoscopic(flatColon,scalarHigh) 100

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicCreateTarget
# Create a target fiducial at the look at point, the look from point is located at the endoscopic camera
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicCreateTargets {} {

    global Endoscopic Point Fiducials Module
#puts "start create target: clock format [clock seconds]"
# get the ids of the selected fiducial
    set pid $Endoscopic(selectedFiducialPoint) 
    set fid $Endoscopic(selectedFiducialList)
   
# save its XYZ FXYZ (Note: Camera fp_actor location is not always the same as the FXYZ of the Point)
    set savedFXYZ [Point($pid,node) GetFXYZ] 
    set savedXYZ [Point($pid,node) GetXYZ]
# save its pointId
    set pointId [Point($pid,node) GetDescription]
   
# append the listname with "-targets"
    set listname $Fiducials($fid,name)
    append listname -targets

# check if that name exists, if not, create new list
    if {[lsearch $Fiducials(listOfNames) $listname] == -1} {

    set targetfid [[MainMrmlAddNode Fiducials] GetID]

    Fiducials($targetfid,node) SetType "default"
    Fiducials($targetfid,node) SetName $listname
    Fiducials($targetfid,node) SetTextSize 0.0
    Fiducials($targetfid,node) SetSymbolSize 4.0
                                
    MainMrmlAddNode EndFiducials
    MainUpdateMRML
    } else {

    set targetfid $Fiducials($listname,fid)
    }


########## GET THE COORDINATES ################
     set cam_mat [Endoscopic(cam,actor) GetMatrix]   
     set fp_mat [Endoscopic(fp,actor) GetMatrix]
   
     set x [$cam_mat GetElement 0 3]
     set y [$cam_mat GetElement 1 3]
     set z [$cam_mat GetElement 2 3]
     set fx [lindex $savedFXYZ 0]
     set fy [lindex $savedFXYZ 1]
     set fz [lindex $savedFXYZ 2]

########## Make the Fiducial Point ###################

    set index [llength $Fiducials($targetfid,pointIdList)]
  
    set targetpid [[MainMrmlInsertBeforeNode EndFiducials($targetfid,node) Point] GetID]
   
    Point($targetpid,node) SetXYZ $fx $fy $fz
    Point($targetpid,node) SetFXYZ $x $y $z
    Point($targetpid,node) SetIndex $index
   
    set index [expr $index + 1]
    Point($targetpid,node) SetName [concat $Fiducials($targetfid,name) $index]
# use the SetDescription to store and save $pointId information.
    Point($targetpid,node) SetDescription $pointId
    
#puts "start 2nd mrml update: clock format [clock seconds]"
    MainUpdateMRML
#puts "end 2nd mrml update: clock format [clock seconds]"

########## Get Number of Targets ################

    set Endoscopic(totalTargets) [llength $Fiducials($targetfid,pointIdList)]
    set Endoscopic(selectedTarget) $index

#puts " Target $index, pointId is $pointId"

#puts "end create target: clock format [clock seconds]"
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateActiveTarget
# This is called when the user modifies the endoscope's position and orientation to look at an existing fiducial point.<br>
# i.e., the user can adjust the ideal view point for a particular polyp, and then save that information.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateActiveTarget {} {
    global Fiducials Endoscopic Point

# get the pid of the selected target
    if {$Endoscopic(path,activeId) == "None"} {
        return
    }

    set index $Endoscopic(selectedTarget)
    set cT $Endoscopic(selectedTarget)
    
    set id $Endoscopic(path,activeId)
    set listname $Endoscopic($id,path,name)
    append listname -targets
    set list [FiducialsGetPointIdListFromName $listname]

    set index [expr $index - 1]
    set pid [lindex $list $index]
    set fid $Fiducials($listname,fid)
    
# get the new current camera position, i.e. the user set an ideal view point for looking at the selected target.
     set cam_mat [Endoscopic(cam,actor) GetMatrix]   
   
     set x [$cam_mat GetElement 0 3]
     set y [$cam_mat GetElement 1 3]
     set z [$cam_mat GetElement 2 3]

   
#    Point($targetpid,node) SetXYZ $fx $fy $fz
     Point($pid,node) SetFXYZ $x $y $z

     MainUpdateMRML
     
     set Endoscopic(selectedTarget) $cT
     EndoscopicSelectTarget $Endoscopic(selectedTarget)

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicDeleteActiveTarget
# Delete an existing target from the fiducial list.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicDeleteActiveTarget {} {
    global Fiducials Endoscopic Point
    
    if {$Endoscopic(path,activeId) == "None"} {

        return
    }

    set index $Endoscopic(selectedTarget)
    set pT $Endoscopic(selectedTarget)
    
# if the user want to delete the first target on the list, and there are more than 2 targets on this list
    if {$pT == 1 && $Endoscopic(totalTargets) >= 2 } {
         set pT 1
         set Endoscopic(totalTargets) [expr $Endoscopic(totalTargets)-1]
     
    } elseif { $pT == 1 && $Endoscopic(totalTargets) < 2 } { 

# if there is only 1 target on the list, and the user decides to delete it
         set pT 0
         set Endoscopic(selectedTarget) 0
         set Endoscopic(totalTargets) 0
    } elseif {$pT > 1} {

# any other situations, the endoscope will jump to the previous target
         set pT [expr $Endoscopic(selectedTarget)-1]
         set Endoscopic(totalTargets) [expr $Endoscopic(totalTargets)-1]
    }
    
    
    if {$Endoscopic(totalTargets) != 0} {
    
        set id $Endoscopic(path,activeId)
        set listname $Endoscopic($id,path,name)
        append listname -targets
        set list [FiducialsGetPointIdListFromName $listname]

        set index [expr $index - 1]
        set pid [lindex $list $index]
        set fid $Fiducials($listname,fid)
    
# the following 3 lines are a kludge
        set cellId [Point($pid,node) GetDescription]  
        set Point($pid,cellId) $cellId
        set Point($pid,actor) dummyactor
   
        FiducialsDeletePoint $fid $pid
    
        set list [FiducialsGetPointIdListFromName $listname]
        set Endoscopic(totalTargets) [llength $list] 
    
        set Endoscopic(selectedTarget) $pT
    EndoscopicSelectTarget $Endoscopic(selectedTarget)
    
    } else {
    
# procede to delete the fiducial list all together
         set id $Endoscopic(path,activeId)
         set listname $Endoscopic($id,path,name)
         append listname -targets
         FiducialsDeleteList $listname
    }
    
# delete the corresponding target in the flat window
    if {$Endoscopic(FlatWindows) != ""} {

# Fix later: as of now I am assuming the user are working with the first flat model
# if the user want to work with several flat models at the same time, they either has to be really careful or
# insert some checking mechanism to prevent them from adding or selecting targets in the wrong flat window.    
    set name [lindex $Endoscopic(FlatWindows) 0]
    
    set widget .t$name.fView.flatRenderWidget$name
    EndoscopicUpdateTargetsInFlatWindow $widget
   
    }

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSelectTarget
# When a target is selected, the endoscope jumps to the optimum location 
# (decided by the user) and aims itself at the target.
# .ARGS
# int sT selected target
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSelectTarget {sT} {

    global Fiducials Endoscopic Point Volume Volumes

# select target in 3D
    if {$Endoscopic(path,activeId) == "None"} {
        return
    }

    set $Endoscopic(selectedTarget) $sT
    set index $Endoscopic(selectedTarget)

    if {$index > 0} {

    set id $Endoscopic(path,activeId)
    set listname $Endoscopic($id,path,name)
    append listname -targets
    set list [FiducialsGetPointIdListFromName $listname]

    set index [expr $index - 1]
    set pid [lindex $list $index]
  
    set point(xyz) [Point($pid,node) GetXYZ]
    set fx [lindex $point(xyz) 0]
    set fy [lindex $point(xyz) 1]
    set fz [lindex $point(xyz) 2]

#test
    set pointId [Point($pid,node) GetDescription]
#puts "the id of the verticie is $pointId"
#test end        


    EndoscopicResetCameraDirection    
    EndoscopicUpdateVirtualEndoscope $Endoscopic(activeCam) [concat [Point($pid,node) GetFXYZ] [Point($pid,node) GetXYZ]]
   
    EndoscopicUpdateActorFromVirtualEndoscope $Endoscopic(activeCam)
#    Render3D
    
# set the original axial slice to that location
    #set driver User
    #EndoscopicSetSliceDriver $driver

    MainSlicesSetOrientAll Slices
    set vol $Volume(activeID)
    set oriSlice [[Volume($vol,node) GetRasToIjk] MultiplyPoint $fx $fy $fz 1]
    set scanOrder [Volume($vol,node) GetScanOrder]
    set dim [Volume($vol,node) GetDimensions]
    
    if {$scanOrder == "IS" } {
    MainSlicesSetOffset 0 [expr round([lindex $oriSlice 2])]
    MainSlicesSetOffset 1 [expr round([expr [lindex $dim 0] - [lindex $oriSlice 0]])]
    MainSlicesSetOffset 2 [expr round([lindex $oriSlice 1])]

    } 
        
    RenderAll
    


# select the corresponding target in the flat window
    if {$Endoscopic(FlatWindows) != ""} {

# Fix later: as of now I am assuming the user are working with the first flat model
# if the user want to work with several flat models at the same time, they either has to be really careful or
# insert some checking mechanism to prevent them from adding or selecting targets in the wrong flat window.    
    set name [lindex $Endoscopic(FlatWindows) 0]
    
    set widget .t$name.fView.flatRenderWidget$name
   
    set pointId [Point($pid,node) GetDescription]
    
    set polyData $Endoscopic($name,polyData)
    set point(xyz) [$polyData GetPoint $pointId]

    set camx [lindex $point(xyz) 0]

    set position [$Endoscopic($name,camera) GetPosition]
  
    set Endoscopic(flatColon,xCamDist) $camx
    set Endoscopic(flatColon,yCamDist) [lindex $position 1]
    set Endoscopic(flatColon,zCamDist) [lindex $position 2]
   
    $Endoscopic($name,camera) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) 0
    $Endoscopic($name,camera) SetPosition $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
  
    $Endoscopic(flatScale,progress) set $Endoscopic(flatColon,xCamDist)
    $Endoscopic(flatScale,panud) set $Endoscopic(flatColon,yCamDist)
    $Endoscopic(flatScale,camZoom) set $Endoscopic(flatColon,zCamDist)
 
    [$widget GetRenderWindow] Render

    } else {

    return
    }
    } else {
    EndoscopicResetPath $Endoscopic(activeCam) $Endoscopic(path,activeId)
    }
    
} 

#-------------------------------------------------------------------------------
# .PROC EndoscopicSelectNextTarget
# select the next target
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSelectNextTarget {} {

    global Endoscopic

    if {$Endoscopic(path,activeId) == "None"} {
        return
    }

    if {$Endoscopic(selectedTarget) < $Endoscopic(totalTargets)} {

        set Endoscopic(selectedTarget) [expr $Endoscopic(selectedTarget) + 1]

        EndoscopicSelectTarget $Endoscopic(selectedTarget)
        
    } else {
        #   tk_messageBox -message "No More Targets"
        return
    }
}  

#-------------------------------------------------------------------------------
# .PROC EndoscopicSelectPreviousTarget
# Select the previous target.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSelectPreviousTarget {} {

    global Endoscopic
    
    if {$Endoscopic(path,activeId) == "None"} {
        return
    }

    if {$Endoscopic(selectedTarget) > 1} {

        set Endoscopic(selectedTarget) [expr $Endoscopic(selectedTarget) - 1]

        EndoscopicSelectTarget $Endoscopic(selectedTarget)
    
    } else {
        return
        # tk_messageBox -message "No More Targets"
    }

}  

#-------------------------------------------------------------------------------
# .PROC EndoscopicUpdateTargetsInFlatWindow
# This is called from the update button in the flat colon window to load 
# the targets from the MRML tree into the flat colon window 
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicUpdateTargetsInFlatWindow {widget} {

    global Endoscopic Fiducials Point Model
    
     set model $Model(activeID)
     if {$model != ""} {
         set polyData3D $Model($model,polyData)
     }
     
     set numP3D [$polyData3D GetNumberOfPoints]
    

    set name $Endoscopic($widget,name)

    # delete all the lines that's already in the flat window
    for {set linecount 0} {$linecount < $Endoscopic($name,lineCount)} {incr linecount} {
        set renderer [[[$widget GetRenderWindow] GetRenderers] GetItemAsObject 0]
        $renderer RemoveActor Endoscopic($name,aLineActor,$linecount)
        Endoscopic($name,aLineActor,$linecount) Delete
    }
    
    set Endoscopic($name,lineCount) 0
    
    [$widget GetRenderWindow] Render

    #get the active path name, and find the corresponding target list
    if {$Endoscopic(path,activeId) != "None"} {
    
           set fid $Fiducials($Fiducials(activeList),fid)
           set listname $Fiducials($fid,name)
           append listname -targets
    
           # if there is no list, then the user have not inserted any targets
           # else get the cellid from the target pid, and make the line in the flat window.
           # note to myself: the cellId is stored by Point($pid,node) SetDescription when the target was inserted
           
         if {[lsearch $Fiducials(listOfNames) $listname] == -1} {
             return
             #  tk_messageBox -message "You have not inserted any target along this path"
    
         } else {

             set targetfid $Fiducials($listname,fid)
             set list $Fiducials($targetfid,pointIdList)
             set numP [llength $list]
             
             for {set i 0} {$i < $numP} {incr i} {
                 set pid [lindex $list $i]
                 set pointIdT1 [Point($pid,node) GetDescription]
                 # puts "p was $pointIdT1"     
                 set pointIdT2 [expr $pointIdT1 + $numP3D]
                 # puts "p is $pointIdT2"
                 set polyData $Endoscopic($name,polyData)
                 set pointT1(xyz) [$polyData GetPoint $pointIdT1]
                 set pointT2(xyz) [$polyData GetPoint $pointIdT2]
                 
                 # find the position of the 2 points in both copies of the flat colon
                 
                 set x1 [lindex $pointT1(xyz) 0]
                 set y1 [lindex $pointT1(xyz) 1]
                 set z1 [lindex $pointT1(xyz) 2]
                 
                 set x2 [lindex $pointT2(xyz) 0]
                 set y2 [lindex $pointT2(xyz) 1]
                 set z2 [lindex $pointT2(xyz) 2]
                 
                 # compare the y position of the 2 points with the center of the flat colon \
                     assume that the point is within the boundary when the diff is smaller for that point \
                     draw target hashes around that point
                 
                 set diff1 [expr abs([expr $y1 - $Endoscopic(flatColon,yMid)])]
                 set diff2 [expr abs([expr $y2 - $Endoscopic(flatColon,yMid)])]
                 
                 if {$diff1 <= $diff2} {
                     EndoscopicAddTargetInFlatWindow $widget $x1 $y1 $z1
                 } else {
                     EndoscopicAddTargetInFlatWindow $widget $x2 $y2 $z2
                 }
                 
             }
         }
           
       } else {
           
           tk_messageBox -message "Please select a path first"
       }
    
    if {$Endoscopic(selectedTarget) == 0} {
        EndoscopicLoadTargets
    } else {
        EndoscopicSelectTarget $Endoscopic(selectedTarget)
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicFlatLightElevationAzimuth
# Set the light key light eleveation and azimuth from the inputs
# .ARGS
# windowelement widget the flat window
# string Endoscopic(flatColon,LightElev) light elevation, defaults to empty string
# string Endoscopic(flatColon,LightAzi) light azimuth, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicFlatLightElevationAzimuth {widget {Endoscopic(flatColon,LightElev)"" Endoscopic(flatColon,LightAzi)""}} {
     global Endoscopic
     
     set name $Endoscopic($widget,name)
     
     Endoscopic($name,lightKit) SetKeyLightElevation $Endoscopic(flatColon,LightElev) 
     Endoscopic($name,lightKit) SetKeyLightAzimuth $Endoscopic(flatColon,LightAzi)
     
     [$widget GetRenderWindow] Render

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicMoveCameraX
# Move the camera in the flat colon window along the x axis
# .ARGS
# windowelement widget 
# string Endoscopic(flatColon,xCamDist) distance to move the camera, defaults to emtpy string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicMoveCameraX {widget {Endoscopic(flatColon,xCamDist)""}} {
    global Endoscopic
 
    set name $Endoscopic($widget,name)
 
    set position [$Endoscopic($name,camera) GetPosition]
  
    set Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,xCamDist)
    set Endoscopic(flatColon,yCamDist) [lindex $position 1]
    set Endoscopic(flatColon,zCamDist) [lindex $position 2]
  
     $Endoscopic($name,camera) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) 0
     $Endoscopic($name,camera) SetPosition $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
 
    [$widget GetRenderWindow] Render
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicMoveCameraY
# Move the camera in the flat colon window along the y axis
# .ARGS
# windowelement widget  the flat window
# string Endoscopic(flatColon,yCamDist) distance to move the camera, defaults to emtpy string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicMoveCameraY {widget {Endoscopic(flatColon,yCamDist)""}} {
    global Endoscopic
 
    set name $Endoscopic($widget,name)

    set position [$Endoscopic($name,camera) GetPosition]
    
    set Endoscopic(flatColon,xCamDist) [lindex $position 0]
    set Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,yCamDist)
    set Endoscopic(flatColon,zCamDist) [lindex $position 2]
    
    $Endoscopic($name,camera) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) 0
    $Endoscopic($name,camera) SetPosition $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
    
    [$widget GetRenderWindow] Render
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicMoveCameraZ
# Zoom the camera in the flat colon window along the z axis (in and out of the screen)
# .ARGS
# windowelement widget the flat window
# string Endoscopic(flatColon,zCamDist) distance to move the camera, defaults to empty string
# .END
#-------------------------------------------------------------------------------
proc EndoscopicMoveCameraZ {widget {Endoscopic(flatColon,zCamDist)""}} {
    global Endoscopic
 
    set name $Endoscopic($widget,name)
    set position [$Endoscopic($name,camera) GetPosition]
    
    set Endoscopic(flatColon,xCamDist) [lindex $position 0]
    set Endoscopic(flatColon,yCamDist) [lindex $position 1]
    set Endoscopic(flatColon,zCamDist) $Endoscopic(flatColon,zCamDist)
    
    $Endoscopic($name,camera) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) 0
    $Endoscopic($name,camera) SetPosition $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
    
    [$widget GetRenderWindow] Render
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetFlatCameraDist
# Reset the camera in the flat colon window to an optimum location along the z axis based on the size of the colon
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetFlatCameraDist {widget} {

    global Endoscopic
    
    set name $Endoscopic($widget,name)
    set position [$Endoscopic($name,camera) GetPosition]
    
    set Endoscopic(flatColon,xCamDist) [lindex $position 0]
    set Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,yMid)
    set Endoscopic(flatColon,zCamDist) $Endoscopic(flatColon,zOpt)
    
    $Endoscopic($name,camera) SetFocalPoint $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) 0
    $Endoscopic($name,camera) SetPosition $Endoscopic(flatColon,xCamDist) $Endoscopic(flatColon,yCamDist) $Endoscopic(flatColon,zCamDist)
    
    $Endoscopic(flatScale,progress) set $Endoscopic(flatColon,xCamDist)
    $Endoscopic(flatScale,panud) set $Endoscopic(flatColon,yCamDist)
    $Endoscopic(flatScale,camZoom) set $Endoscopic(flatColon,zCamDist)
    
    [$widget GetRenderWindow] Render
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicScrollRightFlatColon
# Scroll the flat colon window to the right.
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicScrollRightFlatColon {widget} {

    global Endoscopic

    set name $Endoscopic($widget,name)
    set position [$Endoscopic($name,camera) GetPosition]
    
    set Endoscopic(flatColon,xCamDist) [lindex $position 0]
    
    while {$Endoscopic(flatColon,xCamDist) < $Endoscopic(flatColon,xMax)} {
        
        if {$Endoscopic(flatColon,stop) == "0"} {
            
            set  Endoscopic(flatColon,xCamDist) [expr  $Endoscopic(flatColon,xCamDist) + $Endoscopic(flatColon,speed)]
            
            EndoscopicMoveCameraX  $widget $Endoscopic(flatColon,xCamDist)
            
            update
            
        } else {
            
            EndoscopicResetStop
            
            break
            
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicScrollLeftFlatColon
# Scroll the flat window to the left
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicScrollLeftFlatColon {widget} {

    global Endoscopic

   
    set name $Endoscopic($widget,name)
    set position [$Endoscopic($name,camera) GetPosition]
    
    set Endoscopic(flatColon,xCamDist) [lindex $position 0]
    
    while {$Endoscopic(flatColon,xCamDist) > $Endoscopic(flatColon,xMin)} {
        
        if {$Endoscopic(flatColon,stop) == "0"} {
            
            set  Endoscopic(flatColon,xCamDist) [expr  $Endoscopic(flatColon,xCamDist) - $Endoscopic(flatColon,speed)]
            
            EndoscopicMoveCameraX  $widget $Endoscopic(flatColon,xCamDist)
            
            update
            
        } else {
            
            EndoscopicResetStop
            
            break
            
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicStopFlatColon
# Sets Endoscopic(flatColon,stop) to one
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicStopFlatColon {} {

    global Endoscopic
    
    set Endoscopic(flatColon,stop) 1

}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetFlatColon
# Resets Endoscopic(flatColon,xCamDist) to minimum x value
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetFlatColon {widget} {

    global Endoscopic
    
    set Endoscopic(flatColon,xCamDist) [expr [expr floor($Endoscopic(flatColon,xMin))]-1] 
    
    EndoscopicMoveCameraX  $widget $Endoscopic(flatColon,xCamDist)
    
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicResetStop
# Sets  Endoscopic(flatColon,stop) to zero
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EndoscopicResetStop {} {

     global Endoscopic
     
     set Endoscopic(flatColon,stop) 0
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetFlatColonScalarVisibility
# Sets the scalar visibility in the flat window according to the value of
# Endoscopic(flatColon,scalarVisibility).
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetFlatColonScalarVisibility {widget} {
     
     global Endoscopic
     
     set name $Endoscopic($widget,name)
     
     if {$Endoscopic(flatColon,scalarVisibility) == 0} {
     
         Endoscopic($name,FlatColonMapper) ScalarVisibilityOff
         Endoscopic($name,lightKit) SetKeyLightIntensity 0.7
         [Endoscopic($name,FlatColonActor) GetProperty] SetAmbient 0.55
         [Endoscopic($name,FlatColonActor) GetProperty] SetDiffuse 0.4
         [Endoscopic($name,FlatColonActor) GetProperty] SetSpecular 0.5
         [Endoscopic($name,FlatColonActor) GetProperty] SetSpecularPower 100
     
     } else {
     
         [Endoscopic($name,FlatColonActor) GetProperty] SetAmbient 0.2
         [Endoscopic($name,FlatColonActor) GetProperty] SetDiffuse 1.0
         [Endoscopic($name,FlatColonActor) GetProperty] SetSpecular 0.5
         [Endoscopic($name,FlatColonActor) GetProperty] SetSpecularPower 100
         Endoscopic($name,lightKit) SetKeyLightIntensity 0.6
         Endoscopic($name,FlatColonMapper) ScalarVisibilityOn
         
         #     Endoscopic($name,FlatColonMapper) SetScalarMaterialModeToAmbientAndDiffuse
         
         Endoscopic($name,FlatColonMapper) SetLookupTable Endoscopic(flatColon,lookupTable,$name)
         Endoscopic($name,FlatColonMapper) SetScalarRange $Endoscopic(flatColon,scalarLow) $Endoscopic(flatColon,scalarHigh)
     }
     
     
    [$widget GetRenderWindow] Render
}

#-------------------------------------------------------------------------------
# .PROC EndoscopicSetFlatColonScalarRange
# If scalars are visible, set the properties of the flat colon actor, lookup table and scalar range.
# Otherwise make them visible.
# .ARGS
# windowelement widget the flat window
# .END
#-------------------------------------------------------------------------------
proc EndoscopicSetFlatColonScalarRange {widget} {
     
     global Endoscopic
     
     set name $Endoscopic($widget,name)
     
     if {$Endoscopic(flatColon,scalarVisibility) == 1} {
     
         [Endoscopic($name,FlatColonActor) GetProperty] SetAmbient 0.2
         [Endoscopic($name,FlatColonActor) GetProperty] SetDiffuse 1.0
         [Endoscopic($name,FlatColonActor) GetProperty] SetSpecular 0.5
         [Endoscopic($name,FlatColonActor) GetProperty] SetSpecularPower 100
         Endoscopic($name,lightKit) SetKeyLightIntensity 0.6

         Endoscopic($name,FlatColonMapper) ScalarVisibilityOn
         
         #     Endoscopic($name,FlatColonMapper) SetScalarMaterialModeToAmbientAndDiffuse
         
         Endoscopic($name,FlatColonMapper) SetLookupTable Endoscopic(flatColon,lookupTable,$name)
         Endoscopic($name,FlatColonMapper) SetScalarRange $Endoscopic(flatColon,scalarLow) $Endoscopic(flatColon,scalarHigh)
         
     } else {
         
         set Endoscopic(flatColon,scalarVisibility) 1
         EndoscopicSetFlatColonScalarVisibility $widget
         #     Endoscopic($name,FlatColonMapper) ScalarVisibilityOn
         #     Endoscopic($name,FlatColonMapper) SetScalarRange $Endoscopic(flatColon,scalarLow) $Endoscopic(flatColon,scalarHigh)
     }
     
     [$widget GetRenderWindow] Render
}
