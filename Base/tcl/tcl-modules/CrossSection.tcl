#=auto==========================================================================
#   Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.
# 
#   See Doc/copyright/copyright.txt
#   or http://www.slicer.org/copyright/copyright.txt for details.
# 
#   Program:   3D Slicer
#   Module:    $RCSfile: CrossSection.tcl,v $
#   Date:      $Date: 2006/03/02 13:32:18 $
#   Version:   $Revision: 1.9 $
# 
#===============================================================================
# FILE:        CrossSection.tcl
# PROCEDURES:  
#   CrossSectionEnter
#   CrossSectionDeleteCutterModel
#   CrossSectionEnter
#   CrossSectionExit
#   CrossSectionInit
#   CrossSectionCreateRenderer
#   CrossSectionBuildVTK
#   CrossSectionCreateCamera
#   CrossSectionCameraParams
#   CrossSectionCreateFocalPoint
#   CrossSectionCreateVTKPath
#   CrossSectionResetPathVariables
#   CrossSectionCreatePath
#   CrossSectionCreateVector
#   CrossSectionVectorParams
#   CrossSectionUpdateVisibility name (optional)
#   CrossSectionSetPickable name 0
#   CrossSectionUpdateSize name
#   CrossSectionPopBindings
#   CrossSectionPushBindings
#   CrossSectionCreateBindings
#   CrossSectionBuildGUI
#   CrossSectionShowFlyThroughPopUp
#   CrossSectionExecutePathTab 
#   CrossSectionBuildFlyThroughGUI
#   CrossSectionCreateLabelAndSlider
#   CrossSectionCreateCheckButton
#   CrossSectionSetVisibility
#   CrossSectionCreateAdvancedGUI
#   CrossSectionSetActive
#   CrossSectionPopupCallback
#   CrossSectionUseGyro
#   CrossSectionSelectActor
#   CrossSectionVectorSelected
#   CrossSectionLandmarkSelected
#   CrossSectionGyroMotion
#   CrossSectionSetGyroOrientation
#   CrossSectionSetWorldPosition
#   CrossSectionSetWorldOrientation
#   CrossSectionSetCameraPosition
#   CrossSectionResetCameraPosition
#   CrossSectionSetCameraDirection
#   CrossSectionResetCameraDirection
#   CrossSectionUpdateActorFromVirtualEndoscope
#   CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
#   CrossSectionLightFollowEndoCamera
#   CrossSectionSetCameraZoom
#   CrossSectionSetCameraViewAngle
#   CrossSectionSetCameraAxis
#   CrossSectionCameraMotionFromUser
#   CrossSectionSetCollision
#   CrossSectionMoveGyroToLandmark
#   CrossSectionUpdateVectors
#   CrossSectionGetAvailableListName
#   CrossSectionAddLandmarkNoDirectionSpecified
#   CrossSectionAddLandmarkNoDirectionSpecified
#   CrossSectionAddLandmarkDirectionSpecified
#   CrossSectionUpdateLandmark
#   CrossSectionBuildInterpolatedPath
#   CrossSectionDeletePath
#   CrossSectionComputeRandomPath
#   CrossSectionShowPath
#   CrossSectionFlyThroughPath
#   CrossSectionSetPathFrame
#   CrossSectionStopPath
#   CrossSectionResetStopPath
#   CrossSectionResetPath
#   CrossSectionSetFlyDirection
#   CrossSectionSetSpeed
#   CrossSectionCheckDriver
#   CrossSectionReformatSlices
#   CrossSectionSetSliceDriver
#   CrossSectionFiducialsPointSelectedCallback
#   CrossSectionFiducialsPointCreatedCallback
#   CrossSectionUpdateMRML
#   CrossSectionStartCallbackFiducialUpdateMRML
#   CrossSectionStartCallbackFiducialsUpdateMRML
#   CrossSectionEndCallbackFiducialUpdateMRML
#   CrossSectionEndCallbackFiducialsUpdateMRML
#   CrossSectionCallbackFiducialUpdateMRML
#   CrossSectionCallbackFiducialsUpdateMRML
#   CrossSectionCreateAndActivatePath
#   CrossSectionSelectActivePath
#   CrossSectionDistanceBetweenTwoPoints
#   CrossSectionUpdateSelectionLandmarkList
#   CrossSectionSetModelsVisibilityInside
#   CrossSectionSetSlicesVisibility
#   CrossSectionUpdateCrossSectionViewVisibility
#   CrossSectionUpdateMainViewVisibility
#   CrossSectionAddCrossSectionView
#   CrossSectionAddMainView
#   CrossSectionAddCrossSectionViewRemoveMainView
#   CrossSectionRemoveCrossSectionView
#   CrossSectionRemoveMainView
#   CrossSectionAddMainViewRemoveCrossSectionView
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC CrossSectionEnter
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateCutterModel {} {
    global CrossSection viewRen Model Mrml

    vtkCylinderSource CScutterCylinder
    vtkTransform CSCylinderXform        
    CScutterCylinder SetRadius 50
    CScutterCylinder SetResolution 100
    CScutterCylinder SetHeight 1
    
    # make the actor (camera)
    vtkTransformPolyDataFilter CSCylinderXformFilter
    CSCylinderXformFilter SetInput [CScutterCylinder GetOutput]
    CSCylinderXformFilter SetTransform CSCylinderXform
    
    vtkPolyDataMapper CSCylinderMapper
    CSCylinderMapper SetInput [CSCylinderXformFilter GetOutput]

    set CrossSection(cutter,node) [MainMrmlAddNode Model]
    $CrossSection(cutter,node) SetName  "CrossSectionCutter"
    set CrossSection(cutter,model) [$CrossSection(cutter,node) GetID]
    $CrossSection(cutter,node) SetModelID M$CrossSection(cutter,model)
    MainModelsCreate $CrossSection(cutter,model)
    Model($CrossSection(cutter,model),actor,viewRen) SetMapper CSCylinderMapper
    Model($CrossSection(cutter,model),actor,viewRen) SetUserMatrix [CrossSection(gyro,actor) GetMatrix]
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionDeleteCutterModel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionDeleteCutterModel {} {
    global CrossSection viewRen Model Mrml
    
    CScutterCylinder Delete
    CSCylinderXform Delete
    CSCylinderXformFilter Delete
    CSCylinderMapper Delete
    
    MainMrmlDeleteNode Model [$CrossSection(cutter,node) GetID] 
    
    set w .wCrossSectionFlyThrough
    wm withdraw $w
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionEnter
# Called when this module is entered by the user.  

# effects: Pushes the event manager for this module and 
#          calls CrossSectionAddCrossSectionView. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionEnter {} {
    global CrossSection View viewWin viewRen Fiducials Csys Model Mrml
    
    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)

    # push initial bindings
    CrossSectionPushBindings
    
##    $n SetName  $ModelMaker("camera")
#    set m [$n GetID]
#    MainModelsCreate $m

    # show the actors based on their visibility parameter
    #foreach a $CrossSection(actors) {
    #CrossSectionUpdateVisibility $a
    #}
    foreach a $CrossSection(actors) {
        viewRen AddActor $a
    CrossSectionSetPickable $a 1
    }
    set Csys(active) 1
    Render3D
#    if {$CrossSection(endoview,visibility) == 1} {
#        CrossSectionAddCrossSectionView
#    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionExit
# Called when this module is exited by the user.  
#
# effects: Pops the event manager for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionExit {} {
    global CrossSection Csys
    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    if {$CrossSection(endoview,hideOnExit) == 1} {
        # reset the slice driver
        CrossSectionSetSliceDriver User
        
        # set all endoscopic actors to be invisible, without changing their 
        # visibility parameters
        foreach a $CrossSection(actors) {
            viewRen RemoveActor $a
            CrossSectionSetPickable $a 0
                    
        }
        set Csys(active) 0
        Render3D
        CrossSectionRemoveCrossSectionView
    }
    CrossSectionPopBindings
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionInit
#  The "Init" procedure is called automatically by the slicer.  
#  <br>
#
#  effects: * It puts information about the module into a global array called 
#             Module. <br>
#           * It adds a renderer called CrossSection(activeCam) to the global array 
#             View and adds the new renderer to the list of renderers in 
#             Module(renderers) <br> 
#           * It also initializes module-level variables (in the global array 
#             CrossSection and Path) <br>
#             The global array CrossSection contains information about the 
#             7 actors created in this module (the list is saved in CrossSection(actors): <br>
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
proc CrossSectionInit {} {
    global CrossSection Module Model Path Advanced View Gui Fiducials
    

    set m CrossSection
    set Module($m,row1List) "Help Display Path Advanced"
    set Module($m,row1Name) "{Help} {Display} {Path} {Advanced}"
    set Module($m,row1,tab) Path    
#    set Module($m,row1List) "Advanced"
#    set Module($m,row1Name) "{Advanced}"
#    set Module($m,row1,tab) Advanced

    set Module($m,depend) ""

    set Module($m,author) "Sylvain Bouix, SPL, sylvain@bwh.harvard.edu"
    set Module($m,overview) "Used to measure structure cross sections"
    set Module($m,category) "Visualisation"

    # Define Procedures
    #------------------------------------
    
    set Module($m,procVTK) CrossSectionBuildVTK
    set Module($m,procGUI) CrossSectionBuildGUI
    set Module($m,procCameraMotion) CrossSectionCameraMotionFromUser
    set Module($m,procXformMotion) CrossSectionGyroMotion
    set Module($m,procEnter) CrossSectionEnter
    set Module($m,procExit) CrossSectionExit
    set Module($m,procMRML) CrossSectionUpdateMRML
    # callbacks so that the endoscopic module knows when things happen with the
    # fiducials
    lappend Module($m,fiducialsStartUpdateMRMLCallback) CrossSectionStartCallbackFiducialsUpdateMRML
    lappend Module($m,fiducialsEndUpdateMRMLCallback) CrossSectionEndCallbackFiducialsUpdateMRML
    lappend Module($m,fiducialsCallback) CrossSectionCallbackFiducialsUpdateMRML
    lappend Module($m,fiducialsPointSelectedCallback) CrossSectionFiducialsPointSelectedCallback
    lappend Module($m,fiducialsPointCreatedCallback) CrossSectionFiducialsPointCreatedCallback
    lappend Module($m,fiducialsActivatedListCallback) CrossSectionFiducialsActivatedListCallback
    
    # give a defaultList name for endoscopic Fiducials
    set Fiducials(CrossSection,Path,defaultList) "path"


    # create a second renderer here in Init so that it is added to the list 
    # of Renderers before MainActorAdd is called anywhere
    # That way any actor added to viewRen (the MainView's renderer) is also 
    # added to endoscopicScreen and will appear on the second window once we decide 
    # to show it
    
    # by default we only know about this renderers, so add it to 
    # the list of the endoscopic renderers we care about

    #CrossSectionCreateRenderer crosssectionScreen2     
    #lappend Module(endoscopicRenderers) crosssectionScreen2
    CrossSectionCreateRenderer crosssectionScreen 
    lappend Module(endoscopicRenderers) crosssectionScreen
    
    
    set CrossSection(activeCam) [crosssectionScreen GetActiveCamera]
    
    # create the second renderer now so that all things are initialized for
    # it
    # only add it to the list of endoscopic renderers we care about
    # once the user pressed the button in the Sync tab

    
    ### create bindings
    CrossSectionCreateBindings
    
    # Initialize module-level variables
    #------------------------------------
    
    set CrossSection(count) 0
    set CrossSection(eventManager)  ""
    set CrossSection(actors) ""
    set CrossSection(mbPathList) ""
    set CrossSection(mPathList) ""
    set CrossSection(plane,offset) 0      
    set CrossSection(selectedFiducialPoint) ""
    set CrossSection(selectedFiducialList) ""
    
    set CrossSection(Cameras) ""
    # path planning
    set CrossSection(source,exists) 0
    set CrossSection(sourceButton,on) 0
    set CrossSection(sinkButton,on) 0

    # Camera variables
    # don't change these default values, change CrossSection(cam,size) instead
    
    set CrossSection(cam,name) "Camera"
    set CrossSection(cam,visibility) 1    
    set CrossSection(cam,size) 10
    set CrossSection(cam,boxlength) 30
    set CrossSection(cam,boxheight) 30
    set CrossSection(cam,boxwidth)  1
    set CrossSection(cam,x) 0
    set CrossSection(cam,y) 0
    set CrossSection(cam,z) 0
    set CrossSection(cam,xRotation) 0
    set CrossSection(cam,yRotation) 0
    set CrossSection(cam,zRotation) 0
    set CrossSection(cam,FPdistance) 30
    set CrossSection(cam,viewAngle) 90
    set CrossSection(cam,AngleStr) 90
    set CrossSection(cam,viewUpX) 0 
    set CrossSection(cam,viewUpY) 0 
    set CrossSection(cam,viewUpZ) 1
    set CrossSection(cam,viewPlaneNormalX) 0
    set CrossSection(cam,viewPlaneNormalY) 1
    set CrossSection(cam,viewPlaneNormalZ) 0
    set CrossSection(cam,driver) 0
    set CrossSection(cam,PathNode) ""
    set CrossSection(cam,EndPathNode) ""
    set CrossSection(cam,xStr) 0
    set CrossSection(cam,yStr) 0
    set CrossSection(cam,zStr) 0
    set CrossSection(cam,xStr,old) 0
    set CrossSection(cam,yStr,old) 0
    set CrossSection(cam,zStr,old) 0
    set CrossSection(cam,rxStr) 0
    set CrossSection(cam,ryStr) 0
    set CrossSection(cam,rzStr) 0
    set CrossSection(cam,rxStr,old) 0
    set CrossSection(cam,ryStr,old) 0
    set CrossSection(cam,rzStr,old) 0

    set CrossSection(sliderx) ""
    set CrossSection(slidery) ""
    set CrossSection(sliderz) ""
    set CrossSection(Box,name) "Camera Box"
    set CrossSection(Box,color) "1 .4 .5" 

#    set CrossSection(Lens,name) "Camera Lens"
#    set CrossSection(Lens,color) ".4 .2 .6" 

    set CrossSection(fp,name) "Focal Point"    
    set CrossSection(fp,visibility) 0    
    set CrossSection(fp,size) 4
    set CrossSection(fp,color) ".2 .6 .8"
    set CrossSection(fp,x) 0
    set CrossSection(fp,y) 30
    set CrossSection(fp,z) 0
    set CrossSection(fp,driver) 0

    set CrossSection(intersection,driver) 0    
    set CrossSection(intersection,x) 0    
    set CrossSection(intersection,y) 0    
    set CrossSection(intersection,z) 0    
    # if it is absolute, the camera will move along the 
    #  RA/IS/LR axis
    # if it is relative, the camera will move along its
    #  own axis 
    set CrossSection(cam,axis) relative
    
    # CrossSection variables
    


    set CrossSection(path,size) .5 
    set CrossSection(path,color) ".4 .2 .6" 
    
    set CrossSection(path,activeId) None
    # keeps track of all the Ids of the path that currently exist
    # on the screen
    set CrossSection(path,activeIdList) ""
    # keeps track of all path Ids that have ever existed
    set CrossSection(path,allIdsUsed) ""
    set CrossSection(path,nextAvailableId) 1
    set CrossSection(randomPath,nextAvailableId) 1
    

    set CrossSection(vector,name) "Vectors"
    set CrossSection(vector,size) 5 
    set CrossSection(vector,visibility) 1    
    set CrossSection(vector,color) ".2 .6 .8"
    set CrossSection(vector,selectedID) 0

    set CrossSection(gyro,name) "3D Gyro"
    set CrossSection(gyro,visibility) 0
    set CrossSection(gyro,size) 100
   
    set CrossSection(gyro,use) 1
    
    #Advanced variables
    set CrossSection(ModelsVisibilityInside) 1
    set CrossSection(SlicesVisibility) 1
    set CrossSection(collision) 0
    set CrossSection(collDistLabel) ""
    set CrossSection(collMenu) ""

    # Path variable
    set CrossSection(path,flyDirection) "Forward"
    set CrossSection(path,speed) 1
    set CrossSection(path,random) 0
    set CrossSection(path,first) 1
    set CrossSection(path,i) 0
    set CrossSection(path,stepStr) 0
    set CrossSection(path,exists) 0
    set CrossSection(path,numLandmarks) 0
    set CrossSection(path,stop) 0
    set CrossSection(path,vtkNodeRead) 0
    
    set CrossSection(path,interpolationStr) 1
    # set Colors
    set CrossSection(path,cColor) [MakeColor "0 204 255"]
    set CrossSection(path,sColor) [MakeColor "204 255 255"]
    set CrossSection(path,eColor) [MakeColor "255 204 204"]
    set CrossSection(path,rColor) [MakeColor "204 153 153"]
    
    set LastX 0
    
     # viewers 
    set CrossSection(mainview,visibility) 1
    set CrossSection(endoview,visibility) 0
    set CrossSection(endoview,hideOnExit) 0
    set CrossSection(viewOn) 0
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateRenderer
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateRenderer {renName} {

    global CrossSection $renName View Module Mrml

    vtkRenderer $renName
    lappend Module(Renderers) $renName    
    eval $renName SetBackground $View(bgColor)
    
    set cam [$renName GetActiveCamera]
    # so that the camera knows about its renderer
    
    set View($cam,renderer) $renName
    
    $cam SetViewAngle 120
    lappend CrossSection(Cameras) $cam
    
    vtkLight View($cam,light)
    vtkLight View($cam,light2)


    $renName AddLight View($cam,light)
    $renName AddLight View($cam,light2)

    # initial settings. 
    # These parameters are then set in CrossSectionUpdateVirtualEndoscope
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
# .PROC CrossSectionBuildVTK
#  Creates the vtk objects for this module
#  
#  effects: calls CrossSectionCreateFocalPoint, 
#           CrossSectionCreateCamera, CrossSectionCreateLandmarks and 
#           CrossSectionCreatePath, CrossSectionCreateGyro, CrossSectionCreateVector   
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionBuildVTK {} {
    global CrossSection Model Csys
    

    vtkCellPicker CrossSection(picker)
    CrossSection(picker) SetTolerance 0.001
    vtkMath CrossSection(path,vtkmath)
    
    # create the 3D mouse
    CsysCreate CrossSection gyro -1 -1 -1
    lappend CrossSection(actors) CrossSection(gyro,actor) 
    
    # create the focal point actor
    CrossSectionCreateFocalPoint
    lappend CrossSection(actors) CrossSection(fp,actor) 
    
    # create the camera actor (needs to be created after the gyro
    # since it uses the gyro's matrix as its user matrix
    CrossSectionCreateCamera
    lappend CrossSection(actors) CrossSection(cam,actor)
    
    #update the virtual camera
    CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
    
    # add the camera, fp, gyro actors only to viewRen, not crosssectionScreen
    # set their visibility to 0 until we enter the module
    #viewRen AddActor CrossSection(cam,actor)
    CrossSection(cam,actor) SetVisibility 0
    CrossSectionSetPickable CrossSection(cam,actor) 0
    #viewRen AddActor CrossSection(fp,actor)
    CrossSection(fp,actor) SetVisibility 0
    CrossSectionSetPickable CrossSection(fp,actor) 0
    #viewRen AddActor CrossSection(gyro,actor)
    CrossSection(gyro,actor) SetVisibility 1

     # create the vectors base look
    vtkCylinderSource CStube
    vtkConeSource CSarrow
    vtkTransform CStubeXform
    vtkTransform CSarrowXform
    vtkTransformPolyDataFilter CStubeXformFilter
    CStubeXformFilter SetInput [CStube GetOutput]
    CStubeXformFilter SetTransform CStubeXform
    vtkTransformPolyDataFilter CSarrowXformFilter
    CSarrowXformFilter SetInput [CSarrow GetOutput]
    CSarrowXformFilter SetTransform CSarrowXform
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateCamera
#  Create the Camera vtk actor
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateCamera {} {
    global CrossSection
    

##
 
    vtkCubeSource CScamCube
    vtkTransform CSCubeXform        
    CrossSectionCameraParams
    
    # make the actor (camera)
    vtkTransformPolyDataFilter CSCubeXformFilter
    CSCubeXformFilter SetInput [CScamCube GetOutput]
    CSCubeXformFilter SetTransform CSCubeXform
    
    vtkPolyDataMapper CSBoxMapper
    CSBoxMapper SetInput [CSCubeXformFilter GetOutput]
    
    vtkActor CrossSection(Box,actor)
    CrossSection(Box,actor) SetMapper CSBoxMapper
    eval [CrossSection(Box,actor) GetProperty] SetColor $CrossSection(Box,color)
    CrossSection(Box,actor) PickableOff
    
    set CrossSection(cam,actor) [vtkAssembly CrossSection(cam,actor)]
    CrossSection(cam,actor) AddPart CrossSection(Box,actor)
    CrossSection(cam,actor) PickableOn

    # set the user matrix of the camera and focal point to be the matrix of
    # the gyro
    # the full matrix of the cam and fp is a concatenation of their matrix and
    # their user matrix
    CrossSection(cam,actor) SetUserMatrix [CrossSection(gyro,actor) GetMatrix]
    CrossSection(fp,actor) SetUserMatrix [CrossSection(gyro,actor) GetMatrix]
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionCameraParams
# effects: Set the size parameters for the camera and the focal point
# .ARGS int size (optional), 30 by default
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCameraParams {{size -1}} {
    global CrossSection
    
    if { $size == -1 } { 
        set CrossSection(cam,size) 1
    } else {
        set CrossSection(cam,size) $size
    }
    # set parameters for cube (body) geometry and transform
    set CrossSection(cam,boxlength) [expr $CrossSection(cam,size) * 30]
    set CrossSection(cam,boxheight) [expr $CrossSection(cam,size) * 30]
    set CrossSection(cam,boxwidth) 1

    set unit [expr $CrossSection(cam,size)]
    
    CScamCube SetXLength $CrossSection(cam,boxlength)
    CScamCube SetYLength $CrossSection(cam,boxwidth)
    CScamCube SetZLength $CrossSection(cam,boxheight)
    
    CSCubeXform Identity

    set CrossSection(fp,size) [expr $CrossSection(cam,size) * 4]
    CrossSection(fp,source) SetRadius $CrossSection(fp,size)
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateFocalPoint
#  Create the vtk FocalPoint actor
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateFocalPoint {} {
    
    global CrossSection

    vtkSphereSource CrossSection(fp,source)
    CrossSection(fp,source) SetRadius $CrossSection(fp,size)
    vtkPolyDataMapper CrossSection(fp,mapper)
    CrossSection(fp,mapper) SetInput [CrossSection(fp,source) GetOutput]
    vtkActor CrossSection(fp,actor)
    CrossSection(fp,actor) SetMapper CrossSection(fp,mapper)
    eval [CrossSection(fp,actor) GetProperty] SetColor $CrossSection(fp,color)
    set CrossSection(fp,distance) [expr $CrossSection(cam,boxwidth) *3] 
    CrossSection(fp,actor) SetPosition 0 $CrossSection(fp,distance) 0
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateVTKPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateVTKPath {id} {

    global CrossSection
   
    #create the Path actors 
    CrossSectionCreatePath $id   
    lappend CrossSection(actors) CrossSection($id,path,actor)

    #create the Vector actor
    # TODO: need to change from vtkVectors etc to vtkFloatArray and it's friends
    #CrossSectionCreateVector $id
    #lappend CrossSection(actors) CrossSection($id,vector,actor)
    
    viewRen AddActor CrossSection($id,path,actor)
    CrossSection($id,path,actor) SetVisibility 1
    #viewRen AddActor CrossSection($id,vector,actor)
    #CrossSection($id,vector,actor) SetVisibility 1

    lappend CrossSection(path,allIdsUsed) $id
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionResetPathVariables
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionResetPathVariables {id} {
    global CrossSection View
    
    foreach m {c f} {
        CrossSection($id,${m}path,Spline,x) RemoveAllPoints
        CrossSection($id,${m}path,Spline,y) RemoveAllPoints
        CrossSection($id,${m}path,Spline,z) RemoveAllPoints
        CrossSection($id,${m}path,keyPoints) Reset
        CrossSection($id,${m}path,graphicalInterpolatedPoints) Reset
        CrossSection($id,${m}path,allInterpolatedPoints) Reset
    }
    CrossSection($id,path,lines) Reset 
    CrossSection($id,path,polyData) Modified
    #CrossSection($id,vector,polyData) Modified
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionCreatePath
#  Create the vtk camera Path and focalPoint Path actors
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreatePath {id} {
         global CrossSection

    
    # cpath: variables about the points along the camera path
    # fpath: variables about the points along the focal point path
    foreach m "c f" {
        vtkPoints    CrossSection($id,${m}path,keyPoints)  
        vtkPoints    CrossSection($id,${m}path,graphicalInterpolatedPoints)
        vtkPoints    CrossSection($id,${m}path,allInterpolatedPoints)
        
        vtkCardinalSpline CrossSection($id,${m}path,Spline,x)
        vtkCardinalSpline CrossSection($id,${m}path,Spline,y)
        vtkCardinalSpline CrossSection($id,${m}path,Spline,z)
        
        CrossSection($id,${m}path,keyPoints)  SetDataTypeToFloat
        CrossSection($id,${m}path,graphicalInterpolatedPoints) SetDataTypeToFloat
        CrossSection($id,${m}path,allInterpolatedPoints) SetDataTypeToFloat
    }
    
    # path: variables for the graphical representation of the (camera) path
    # the focal point stays invisible
    
    vtkPolyData         CrossSection($id,path,polyData)
    vtkCellArray        CrossSection($id,path,lines)    
    vtkTubeFilter       CrossSection($id,path,source)
    vtkPolyDataMapper   CrossSection($id,path,mapper)    
    vtkActor            CrossSection($id,path,actor)
    
    # set the lines input data
    CrossSection($id,path,polyData)     SetLines  CrossSection($id,path,lines)
    # set the tube info
    CrossSection($id,path,source)       SetNumberOfSides 8
    CrossSection($id,path,source)       SetInput CrossSection($id,path,polyData)
    CrossSection($id,path,source)       SetRadius $CrossSection(path,size)
    CrossSection($id,path,mapper)       SetInput [CrossSection($id,path,source) GetOutput]
    CrossSection($id,path,actor)        SetMapper CrossSection($id,path,mapper)
    
    eval  [CrossSection($id,path,actor) GetProperty] SetDiffuseColor $CrossSection(path,color)
    [CrossSection($id,path,actor) GetProperty] SetSpecular .3
    [CrossSection($id,path,actor) GetProperty] SetSpecularPower 30
    # connect the path with the camera landmarks
    CrossSection($id,path,polyData) SetPoints CrossSection($id,cpath,graphicalInterpolatedPoints)
    
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateVector
#  Create the vtk vector actor
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateVector {id} {

    global CrossSection

   
    vtkAppendPolyData CrossSection($id,vector,source)
    CrossSection($id,vector,source) AddInput [CStubeXformFilter GetOutput]
    CrossSection($id,vector,source) AddInput [CSarrowXformFilter GetOutput]
    
    CrossSectionVectorParams $id 10
    
    vtkPolyData         CrossSection($id,vector,polyData)
    vtkVectors          CrossSection($id,vector,vectors)
    vtkGlyph3D          CrossSection($id,vector,glyph)
    vtkPolyDataMapper   CrossSection($id,vector,mapper)
    vtkActor            CrossSection($id,vector,actor)
    vtkScalars          CrossSection($id,vector,scalars)
    
    CrossSection($id,vector,polyData) SetPoints CrossSection($id,cpath,keyPoints)
    #    CrossSection($id,vector,polyData) SetPoints CrossSection(cLand,graphicalInterpolatedPoints)
    # set the vector glyphs
    [CrossSection($id,vector,polyData) GetPointData] SetVectors CrossSection($id,vector,vectors)
    [CrossSection($id,vector,polyData) GetPointData] SetScalars CrossSection($id,vector,scalars)
    
    CrossSection($id,vector,glyph) SetInput CrossSection($id,vector,polyData)
    CrossSection($id,vector,glyph) SetSource [CrossSection($id,vector,source) GetOutput]
    CrossSection($id,vector,glyph) SetVectorModeToUseVector
    CrossSection($id,vector,glyph) SetColorModeToColorByScalar
    CrossSection($id,vector,glyph) SetScaleModeToDataScalingOff

    
    CrossSection($id,vector,mapper) SetInput [CrossSection($id,vector,glyph) GetOutput]
    CrossSection($id,vector,actor) SetMapper CrossSection($id,vector,mapper)
    
    CrossSection($id,vector,actor) PickableOn

}


#-------------------------------------------------------------------------------
# .PROC CrossSectionVectorParams
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionVectorParams {id {axislen -1} {axisrad -1} {conelen -1} } {
    global CrossSection
    if { $axislen == -1 } { set axislen 10 }
    if { $axisrad == -1 } { set axisrad [expr $axislen*0.05] }
    if { $conelen == -1 } { set conelen [expr $axislen*0.2]}
    set axislen [expr $axislen-$conelen]
    
    set CrossSection(vector,size) $axislen
    
    # set parameters for cylinder geometry and transform
    CStube SetRadius $axisrad
    CStube SetHeight $axislen
    CStube SetCenter 0 [expr -0.5*$axislen] 0
    CStube SetResolution 8
    CStubeXform Identity
    CStubeXform RotateZ 90
    
    # set parameters for cone geometry and transform
    CSarrow SetRadius [expr $axisrad * 2.5]
    CSarrow SetHeight $conelen
    CSarrow SetResolution 8
    CSarrowXform Identity
    CSarrowXform Translate $axislen 0 0
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateVisibility
# 
#  This procedure updates the current visibility of actor a (if specified)
#  and then set that actor to its current visibility 
# 
# .ARGS
#  a  name of the actor CrossSection($a,actor)
#  visibility (optional) 0 or 1 
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateVisibility {a {visibility ""}} {
    
    global CrossSection

    if {$a == "cam"} {
        set a $CrossSection(cam,actor)
    }
    if {$a =="fp"} {
        set a $CrossSection(fp,actor)
    }
    if {$a =="gyro"} {
        set a $CrossSection(gyro,actor)
    }

    if {$visibility == ""} {
        # TODO: check that visibility is a number
        
        set visibility [$a GetVisibility]
    }
    $a SetVisibility $visibility
    if {$a == "CrossSection(cam,actor)"} {
        set CrossSection(gyro,visibility) $visibility
        CrossSection(gyro,actor) SetVisibility $visibility
    }
    CrossSectionSetPickable $a $visibility
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionSetPickable
# 
#  This procedure sets the pickability of actor a to the value specified
# 
# .ARGS
#  a  name of the actor CrossSection($a,actor)
#  pickability 0 or 1 
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetPickable {a pickability} {
    
    global CrossSection
    if {$pickability == 0} {
        set p Off
    } elseif {$pickability == 1} {
        set p On
    }
    if {$a == "CrossSection(gyro,actor)"} {
        foreach w "X Y Z" {
            CrossSection(gyro,${w}actor) Pickable$p
        }
    } else {
        $a Pickable$p 
    }
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateSize
#
# This procedure updates the size of actor a according to CrossSection(a,size)
#
# .ARGS
#  a  name of the actor CrossSection($a,actor)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetSize {a} {
    global Advanced CrossSection Path
    
    if { $a == "gyro"} {
        CsysParams CrossSection gyro $CrossSection($a,size)
    } elseif { $a == "cam"} {
        set CrossSection(fp,distance) [expr $CrossSection(cam,size) * 30]
        CrossSectionCameraParams $CrossSection($a,size)
    CScutterCylinder SetRadius [expr $CrossSection(cam,size) * 50]
        CrossSectionSetCameraPosition
    } elseif { $a == "vector" } {
        CrossSectionVectorParams $CrossSection($a,size)
    } elseif { $CrossSection(path,exists) == 1 } {
        # a is cPath,fPath,cLand or fLand => set their radius
        #set CrossSection($a,size) CrossSection($a,sizeStr)
        CrossSection($a,source) SetRadius $CrossSection($a,size)
    }
    Render3D 
}

##############################################################################
#
#       PART 2: Build the Gui
#
##############################################################################

#-------------------------------------------------------------------------------
# .PROC CrossSectionPopBindings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionPopBindings {} {
    global Ev Csys
    EvDeactivateBindingSet CrossSectionSlice0Events
    EvDeactivateBindingSet CrossSectionSlice1Events
    EvDeactivateBindingSet CrossSectionSlice2Events
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionPushBindings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionPushBindings {} {
    global Ev Csys

    # push onto the event stack a new event manager that deals with
    # events when the CrossSection module is active
    EvActivateBindingSet CrossSectionSlice0Events
    EvActivateBindingSet CrossSectionSlice1Events
    EvActivateBindingSet CrossSectionSlice2Events
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateBindings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateBindings {} {
    global Gui Ev 
    
    # Creates events sets we'll  need for this module
    # create the event manager for the ability to move the gyro
   
    EvDeclareEventHandler CrossSection(Events) <Double-Any-ButtonPress> { if { [SelectPick CrossSection(picker) %W %x %y] != 0 }\
    {eval CrossSectionSetWorldPosition [lindex $Select(xyz) 0] [lindex $Select(xyz) 1] [lindex $Select(xyz) 2];Render3D }}   
    
    # endoscopic events for slice windows (in addition to already existing events)

    EvDeclareEventHandler CrossSectionKeySlicesEvents <KeyPress-c> { if { [SelectPick2D %W %x %y] != 0 } { eval CrossSectionSetWorldPosition $Select(xyz);Render3D }} 
    
    EvAddWidgetToBindingSet CrossSectionSlice0Events $Gui(fSl0Win) {CrossSectionKeySlicesEvents}
    EvAddWidgetToBindingSet CrossSectionSlice1Events $Gui(fSl1Win) {CrossSectionKeySlicesEvents}
    EvAddWidgetToBindingSet CrossSectionSlice2Events $Gui(fSl2Win) {CrossSectionKeySlicesEvents}

}


#-------------------------------------------------------------------------------
# .PROC CrossSectionBuildGUI
# Create the Graphical User Interface.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionBuildGUI {} {
    global Gui Module Model View Advanced CrossSection Path PathPlanning
    
    # A frame has already been constructed automatically for each tab.
    # A frame named "Stuff" can be referenced as follows:
    #   
    #     $Module(<Module name>,f<Tab name>)
    #
    # ie: $Module(CrossSection,fStuff)
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
    set help "This module is used to measure cross sections of structures such as vessels. 
<BR>This module adds a \"cutter\" (a very thin vtk cylinder) at the
camera location on the endoscopy path. You then place the cutter at
the location you want the measurement made, resize it so it does not
go through several sections of the object under study and use the
Measure module to get the volume of the intersection between the
cutter and the model of the object.
<P>
Description by tabs:
    <LI><B>Display</B>
<BR> This Tab permits you to set display parameters.
    <LI><B>Path</B>
<BR> This Tab allows you to create a path. 
    <BR><B>Automatically:</B>
<BR>You can select a closed model, a start and end point on the model, and hit Extract Centerline and a path will be generated between the points of the model.
<BR><B>Advanced:</B>
<BR>This option allows you to use a distance map for a more manual mode.
    <LI><B>Advanced</B>
    <BR>This Tab allows you to change visibility, color and size parameters for the camera, focal point, landmarks and path. You can also change the virtual camera's lens angle for a wider view.
    "
    regsub -all "\n" $help { } help
    MainHelpApplyTags CrossSection $help
    MainHelpBuildGUI CrossSection

    #-------------------------------------------
    # Display frame
    #-------------------------------------------
    set fDisplay $Module(CrossSection,fDisplay)
    set f $fDisplay
        
    frame $f.fTitle -bg $Gui(activeWorkspace)
    frame $f.fBtns -bg $Gui(activeWorkspace)
    frame $f.fMain -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $f.fEndo -bg $Gui(activeWorkspace) -relief groove -bd 2 
    frame $f.fTitle2 -bg $Gui(activeWorkspace)
    pack $f.fTitle $f.fBtns $f.fMain $f.fEndo $f.fTitle2 -side top -pady 5 -fill x
    
    
    eval {label $f.fTitle.lTitle -text "
    If your screen allows, you can change 
    the width of the view screen to have 
    a better CrossSection view:"} $Gui(WLA)
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
    eval {label $f.fexpl -text "Main View parameter:"} $Gui(WLA)
    eval {checkbutton $f.cMainView -variable CrossSection(mainview,visibility) -text "Show Main View" -command "CrossSectionUpdateMainViewVisibility" -indicatoron 0} $Gui(WCA)    

    pack $f.fexpl $f.cMainView -pady 2
    

    set f $fDisplay.fEndo
    eval {label $f.fexpl -text "CrossSection View parameters:"} $Gui(WLA)
    
    eval {checkbutton $f.cEndoView -variable CrossSection(endoview,visibility) -text "Show CrossSection View" -command "CrossSectionUpdateCrossSectionViewVisibility" -indicatoron 0} $Gui(WCA)    
    
    
    eval {checkbutton $f.cslices -variable CrossSection(SlicesVisibility) -text "Show 2D Slices" -command "CrossSectionSetSlicesVisibility" -indicatoron 0} $Gui(WCA)
    pack $f.fexpl -side top -pady 2
    pack $f.cEndoView  -side top -padx $Gui(pad) -pady 0
    pack $f.cslices -side top -pady 5

    set f $fDisplay

    eval {checkbutton $f.cExitEndoView -variable CrossSection(endoview,hideOnExit) -text "Hide CrossSection View on Exit" -indicatoron 0} $Gui(WCA)   

    set text "
    To start, go to the Camera tab 
    If you need help, go to the Help tab"

    
    eval {label $f.fTitle2.lTitle -text $text} $Gui(WLA)
    pack $f.cExitEndoView -side top -padx $Gui(pad) -pady 7
    
    #-------------------------------------------
    # Path frame
    #-------------------------------------------
    set fPath $Module(CrossSection,fPath)

    frame $fPath.fTop   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $fPath.fBot   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $fPath.fTop $fPath.fBot -side top -pady 2 

    set f $fPath.fBot
    FiducialsAddActiveListFrame $f 15 25  
    
    set f $fPath.fTop
#    set PathMenu {Manual Automatic Advanced}
    set PathMenu {Automatic Advanced}

    CrossSectionBuildFlyThroughGUI
    #-------------------------------------------
    # Path Frame: Menu Selection      
    #-------------------------------------------
    TabbedFrame CrossSection $f "" $PathMenu $PathMenu \
        {"Create a Fly-Through Path Manually" \
         "Create a Fly-Through Path Automatically with the CPP Algorithm"\
         "Advanced Option for the CPP Algorithm"}\
     0 Automatic 
    
    foreach i $PathMenu {
        $f.fTop.fTabbedFrameButtons.f.r$i configure -command "CrossSectionExecutePathTab $i"
    }
    set CrossSection(pathTab) $f

    set f $f.fTabbedFrame

    set CrossSection(tabbedFrame) $f
    
    #-------------------------------------------
    # Path Frame: Automatic
    #-------------------------------------------
    set f $CrossSection(tabbedFrame).fAutomatic
    frame $f.fTitle   -bg $Gui(activeWorkspace) 
    frame $f.fStep1   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep2   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep3   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep4   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fTitle $f.fStep1 $f.fStep2 $f.fStep3 $f.fStep4  -side top -pady 2     

    set f $CrossSection(tabbedFrame).fAutomatic.fTitle
    eval {label $f.lTitle -text "Automatic Path Creation"} $Gui(WTA)
    eval {button $f.fbhow -text " ? "} $Gui(WBA)
    TooltipAdd $f.fbhow "You can create an endoscopic path automatically
by specifying two points on a model and running the automatic centerline
extraction algorithm (for more info, see references on www.slicer.org)"
    pack $f.lTitle $f.fbhow -side left -padx $Gui(pad) -pady 0 



    set f $CrossSection(tabbedFrame).fAutomatic.fStep1
    frame $f.fRow1 -bg $Gui(activeWorkspace) 
    frame $f.fRow2  -bg $Gui(activeWorkspace)
    pack  $f.fRow1 $f.fRow2 -side top -pady 2

    set f $CrossSection(tabbedFrame).fAutomatic.fStep1.fRow1
    eval {label $f.lActive1 -text "Step 1. "} $Gui(WTA)
    eval {label $f.lActive2 -text "Choose an Active Model: "} $Gui(WLA)
    pack $f.lActive1 $f.lActive2 -side left

    set f $CrossSection(tabbedFrame).fAutomatic.fStep1.fRow2
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.mbActive -side top

    # Append widgets to list that gets refreshed during UpdateMRML
    lappend Model(mbActiveList) $f.mbActive
    lappend Model(mActiveList)  $f.mbActive.m

    set f $CrossSection(tabbedFrame).fAutomatic.fStep2
    frame $f.fExplain   -bg $Gui(activeWorkspace) 
    frame $f.fSource  -bg $Gui(activeWorkspace)
    frame $f.fSink  -bg $Gui(activeWorkspace)
    pack  $f.fExplain $f.fSource $f.fSink -side top -pady 2 

    set f $CrossSection(tabbedFrame).fAutomatic.fStep2.fExplain
    eval {label $f.lTitle -text "Step 2. "} $Gui(WTA)
    eval {label $f.lTitle2 -text "Select a start point 
    by pointing on the model 
    and press the 'p' key. 
    Repeat for the end point."} $Gui(WLA)
   
    pack $f.lTitle $f.lTitle2 -side left -padx 0 -pady 0 


    set f $CrossSection(tabbedFrame).fAutomatic.fStep2.fSource
    eval {label $f.lsource -text "start point: "} $Gui(WLA)
    eval {label $f.lsource2 -text " None "} $Gui(WLA)
    eval {checkbutton $f.lsourceSel -text "Select another point" -variable CrossSection(sourceButton,on) -indicatoron 0 } $Gui(WBA)
    TooltipAdd $f.lsourceSel "You can select an existing fiducial by pressing this
    button and then selecting the fiducial by pointing at it 
    and pressing the 'q' key." 
 
    set CrossSection(sourceLabel) $f.lsource2
    pack $f.lsource $f.lsource2 $f.lsourceSel -side left 

    set f $CrossSection(tabbedFrame).fAutomatic.fStep2.fSink
    eval {label $f.lsink -text "end point: "} $Gui(WLA)
    eval {label $f.lsink2 -text " None "} $Gui(WLA)
    eval {checkbutton $f.lsinkSel -text "Select another point" -variable CrossSection(sinkButton,on) -indicatoron 0 } $Gui(WBA)
TooltipAdd  $f.lsinkSel "You can select an existing fiducial by pressing this
button and then selecting the fiducial by pointing at it 
and pressing the 'q' key." 

    set CrossSection(sinkLabel) $f.lsink2
    pack $f.lsink $f.lsink2 $f.lsinkSel -side left 


    set f $CrossSection(tabbedFrame).fAutomatic.fStep3
eval {label $f.lTitle -text "Step 3. "} $Gui(WTA)
    DevAddButton $f.bauto "Extract Centerline" PathPlanningExtractCenterline
    pack $f.lTitle $f.bauto -side left -padx 2


    set f $CrossSection(tabbedFrame).fAutomatic.fStep4
eval {label $f.lTitle -text "Step 4. "} $Gui(WTA)
    eval {button $f.bpop -text "Show Fly Through Panel" -command "CrossSectionShowFlyThroughPopUp"} $Gui(WBA)
    pack $f.lTitle $f.bpop -side left -padx 2


    #-------------------------------------------
    # Path Frame: Advanced
    #-------------------------------------------
    set f $CrossSection(tabbedFrame).fAdvanced
    set f $CrossSection(tabbedFrame).fAdvanced
    frame $f.fTitle   -bg $Gui(activeWorkspace) 
    frame $f.fStep1   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep2   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep3   -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep4   -bg $Gui(activeWorkspace) -relief groove -bd 2
    pack $f.fTitle $f.fStep1 $f.fStep2 $f.fStep3 $f.fStep4  -side top -pady 2     

    set f $CrossSection(tabbedFrame).fAdvanced.fTitle
    set text "Distance Map parameters:"
    DevAddLabel $f.linfo $text WLA
    pack $f.linfo -side top

    set f $CrossSection(tabbedFrame).fAdvanced.fStep1
    set PathPlanning(voxelSize) 1
    eval {label $f.lvs -text "VoxelSize: $PathPlanning(voxelSize)"} $Gui(WLA)
    eval {entry $f.vsWidth -width 5 -textvariable PathPlanning(voxelSize)} $Gui(WEA)
    bind $f.vsWidth <Return>   "PathPlanningSetVoxelSize"

    pack $f.lvs $f.vsWidth -side top -padx 5 -pady 5

    set f $CrossSection(tabbedFrame).fAdvanced.fStep2
    set PathPlanning(dist,maxDistance) 5000
    eval {label $f.lmd -text "Max Dist: $PathPlanning(dist,maxDistance)"} $Gui(WLA)
    eval {entry $f.emd -width 5 -textvariable PathPlanning(dist,maxDistance)} $Gui(WEA)
    bind  $f.emd <Return>   "PathPlanningSetMaximumDistance"
    pack $f.lmd $f.emd -side top -padx 5 -pady 5

    set f $CrossSection(tabbedFrame).fAdvanced.fStep3

    set text "Visualization plane offset:"
    DevAddLabel $f.lintro $text WLA
    pack $f.lintro -side top

    eval {entry $f.eOffset -width 4 -textvariable CrossSection(planeoffset)} $Gui(WEA)
    bind $f.eOffset <Return>   "PathPlanningSetPlaneOffset"
    bind $f.eOffset <FocusOut> "PathPlanningSetPlaneOffset"

    eval {scale $f.sOffset -from 0 -to 1000 \
        -variable CrossSection(planeoffset) -length 160 -resolution 1.0 -command \
        "PathPlanningSetPlaneOffset"} $Gui(WSA) 

    pack $f.sOffset $f.eOffset -side right -anchor w -padx 2 -pady 0

    set f $CrossSection(tabbedFrame).fAdvanced.fStep4

    eval {button $f.bvisVol -text "Visualize LabelMap" -command "PathPlanningVisualizeMaps labelMapFilter"} $Gui(WBA)
    eval {button $f.bvisDist -text "Visualize DistanceMap" -command "PathPlanningVisualizeMaps dist"} $Gui(WBA)

    eval {button $f.bexp -text "Use exponential decrease" -command "set PathPlanning(useLinear) 0; set PathPlanning(useExponential) 1; set PathPlanning(useSquared) 0"} $Gui(WBA)
    eval {button $f.bsq -text "Use squared decrease" -command "set PathPlanning(useLinear) 0; set PathPlanning(useExponential) 0; set PathPlanning(useSquared) 1"} $Gui(WBA)
    eval {button $f.blin -text "Use linear decrease" -command "set PathPlanning(useLinear) 1; set PathPlanning(useSquared) 0; set PathPlanning(useExponential) 0"} $Gui(WBA)
    pack $f.bexp $f.bsq $f.blin $f.bvisVol $f.bvisDist -side top

    #set f $CrossSection(tabbedFrame).fAdvanced.fStep4
    #eval {button $f.bpop -text "Show Fly Through Panel" -command "CrossSectionShowFlyThroughPopUp"} $Gui(WBA)
    #pack $f.bpop



    #-------------------------------------------
    # Path->Bot->Vis frame
    #-------------------------------------------
    #set f $fPath.fBot.fVis

    # Compute path
#        eval {label $f.lTitle -text "You can create a Random Path to \n play with Fly-Thru options:"} $Gui(WTA)
 #       grid $f.lTitle -padx 1 -pady 1 -columnspan 2

#    eval {button $f.cRandPath \
 #       -text "New random path" -width 16 -command "CrossSectionComputeRandomPath; Render3D"} $Gui(WBA) {-bg $CrossSection(path,rColor)}           

  #  eval {button $f.dRandPath \
   #     -text "Delete path" -width 14 -command "CrossSectionDeletePath; Render3D"} $Gui(WBA) {-bg $CrossSection(path,rColor)}           
    
 #   eval {checkbutton $f.rPath \
  #      -text "RollerCoaster" -variable CrossSection(path,rollerCoaster) -width 12 -indicatoron 0 -command "Render3D"} $Gui(WBA) {-bg $CrossSection(path,rColor)}             
    
 #   eval {checkbutton $f.sPath \
  #      -text "Show Path" -variable CrossSection(path,showPath) -width 12 -indicatoron 0 -command "CrossSectionShowPath; Render3D"} $Gui(WBA) {-bg $CrossSection(path,rColor)}             
  #  grid $f.cRandPath $f.dRandPath -padx 0 -pady $Gui(pad)
   # #grid $f.rPath $f.sPath -padx 0 -pady $Gui(pad)
  #  grid $f.sPath -padx 0 -pady $Gui(pad)


    #-------------------------------------------
    # Advanced frame
    #-------------------------------------------
    set fAdvanced $Module(CrossSection,fAdvanced)
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

    # Done in CrossSectionCreateAdvancedGUI

#    CrossSectionCreateAdvancedGUI $f cam   visible   noColor size
#    CrossSectionCreateAdvancedGUI $f Lens  notvisible color
#    CrossSectionCreateAdvancedGUI $f Box   notvisible color
#    CrossSectionCreateAdvancedGUI $f fp    visible    color
    CrossSectionCreateAdvancedGUI $f gyro    visible   noColor size

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

    CrossSectionCreateLabelAndSlider $f l2 2 "Lens Angle" "Angle" horizontal 0 360 110 CrossSection(cam,AngleStr) "CrossSectionSetCameraViewAngle" 5 90


    #-------------------------------------------
    # Advanced->Mid->Vis frame
    #-------------------------------------------
    
#    set f $fAdvanced.fMid.fVis
    
#    CrossSectionCreateCheckButton $f.cmodels CrossSection(ModelsVisibilityInside) "Show Inside Models"  "CrossSectionSetModelsVisibilityInside"

    
#   pack $f.cmodels

    # reinstating the show path toggle button
 #   CrossSectionCreateCheckButton $f.cPath CrossSection(path,showPath) "Show Path" "CrossSectionShowPath; Render3D"
#    pack $f.cPath

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
    
    #$f.fMBtns.fMenu add command -label "off" -command {CrossSectionSetCollision 0;}
    #$f.fMBtns.fMenu add command -label "on" -command {CrossSectionSetCollision 1}
    
    #eval {label $f.l2 -height 2 -text "distance: 0"} $Gui(WTA)
    #set CrossSection(collMenu) $f.fMBtns
    #set CrossSection(collDistLabel) $f.l2
    #grid $f.l $f.fMBtns $f.l2 -padx 1 -pady 1
    


    #-------------------------------------------
    # Sync frame
    #-------------------------------------------
    #set fSync $Module(CrossSection,fSync)
    #set f $fSync
    
    #frame $f.fTop -bg $Gui(activeWorkspace) 
    #frame $f.fBot -bg $Gui(activeWorkspace) 
    #    pack $f.fTop $f.fBot -side top -pady 0 -padx 0 -fill x

    #-------------------------------------------
    # Advanced->Top frame
    #-------------------------------------------
    #set f $fSync.fTop
    #eval {checkbutton $f.bcreate -text "Create sync window" -variable CrossSection(syncOn) -indicatoron 0 -command "CrossSectionAddSyncScreen; Render3D"} $Gui(WCA)
    #eval {button $f.fly -text "Synchronized Fly-through" -command "CrossSectionFlyThroughPath $Module(endoscopicRenderers) {0 1}"} $Gui(WBA)
    #eval {button $f.reset -text "Reset Fly-through" -command "CrossSectionFlyThroughPath $Module(endoscopicRenderers) {0 1}"} $Gui(WBA)
    
    #pack $f.bcreate $f.fly $f.reset
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionShowFlyThroughPopUp
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionShowFlyThroughPopUp {{x 100} {y 100}} {
    global Gui CrossSection 
    
    CrossSectionCreateCutterModel
    # Recreate popup if user killed it
    if {[winfo exists $Gui(wCrossSection)] == 0} {
        CrossSectionBuildFlyThroughGUI
    }
    ShowPopup $Gui(wCrossSection) $x $y
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionExecutePathTab 
# Executes command that is selected in Path Menu Selection
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionExecutePathTab {command} {
    global CrossSection
    raise $CrossSection(tabbedFrame).f$command
    focus $CrossSection(tabbedFrame).f$command
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionBuildFlyThroughGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionBuildFlyThroughGUI {} {
    global Gui CrossSection
    
    # in case 
    set CrossSection(activeCam) [crosssectionScreen GetActiveCamera]

    #-------------------------------------------
    # Labels Popup Window
    #-------------------------------------------
    set w .wCrossSectionFlyThrough
    set Gui(wCrossSection) $w
    toplevel $w -class Dialog -bg $Gui(inactiveWorkspace)
    wm title $w "CrossSection Module: Fly-Through Panel"
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
    # CrossSection->Close frame
    #-------------------------------------------
    set f $w.fClose
    
    eval {button $f.bCancel -text "Close Window" -command "CrossSectionDeleteCutterModel"} $Gui(WBA)

#    eval {button $f.bCancel -text "Close Window"  \
#        -command "wm withdraw $w"} $Gui(WBA)
    
    pack $f.bCancel -side left -padx $Gui(pad)
    
    #-------------------------------------------
    # Labels->Top frame
    #-------------------------------------------
    set f $w.fTop

    frame $f.fTool     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fSelect     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fFly     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fStep     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fSpeed     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fInterp     -bg $Gui(activeWorkspace) -relief groove -bd 2
    frame $f.fSli     -bg $Gui(activeWorkspace) -relief groove -bd 2
    
    pack  $f.fTool $f.fSelect $f.fFly $f.fStep $f.fSpeed $f.fInterp $f.fSli \
        -side top -padx $Gui(pad) -pady $Gui(pad)

    
    #-------------------------------------------
    # Path->Top->Create Cutting Tool
    #-------------------------------------------
#    CrossSectionCreateAdvancedGUI $f cam   visible   noColor size
    set f $w.fTop.fTool
    
    eval {label $f.lstep -text "Cutter Size:"} $Gui(WLA)
#    pack $f.bpop -side top -padx $Gui(pad) -pady 0 

    eval {scale $f.stool -from 0.0 -to $CrossSection(cam,size) -length 70 -variable CrossSection(cam,size) -command "CrossSectionSetSize cam; Render3D" -resolution 0.01} $Gui(WSA) {-sliderlength 10 }    
#    grid $f.sTool -pady 0 -padx 0        
     pack $f.lstep $f.stool -side left -padx $Gui(pad) -pady $Gui(pad)
     
    #-------------------------------------------
    # Path->Top->Select frame
    #-------------------------------------------
    
    set f $w.fTop.fSelect
    # menu to select an active path
    eval {menubutton $f.mbActive -text "None" -relief raised -bd 2 -width 20 \
        -menu $f.mbActive.m} $Gui(WMBA)
    eval {menu $f.mbActive.m} $Gui(WMA)
    pack $f.mbActive -side top -padx $Gui(pad) -pady 0 

    set CrossSection(mbPath4Fly) $f.mbActive
    lappend CrossSection(mPath4Fly) $f.mbActive.m
    
    #-------------------------------------------
    # Path->Top->Fly frame
    #-------------------------------------------
    set f $w.fTop.fFly
    # Compute path
    eval {button $f.fPath \
        -text "Fly-Thru"  -width 8 -command {CrossSectionFlyThroughPath $CrossSection(activeCam) $CrossSection(path,activeId); Render3D}} $Gui(WMBA) {-bg $CrossSection(path,sColor)}   

    eval {button $f.fReset \
        -text "Reset"  -width 8  -command {CrossSectionResetPath $CrossSection(activeCam) $CrossSection(path,activeId); Render3D}} $Gui(WMBA) {-bg $CrossSection(path,sColor)}   

    eval {button $f.fStop \
        -text "Stop" -width 6 -command "CrossSectionStopPath; Render3D"} $Gui(WMBA) {-bg $CrossSection(path,sColor)}   

    #foreach value "Forward Backward" width "9 11" {
    #    eval {radiobutton $f.r$value -width $width \
    #        -text "$value" -value "$value" -variable CrossSection(flyDirection)\
    #        -indicatoron 0 -command "CrossSectionSetFlyDirection $value; Render3D"} $Gui(WMBA) {-bg $CrossSection(path,sColor)} {-selectcolor $CrossSection(path,cColor)}  
    #}       
    #$f.rForward select

    grid $f.fPath $f.fReset $f.fStop -padx $Gui(pad) -pady $Gui(pad)
    #grid $f.rForward $f.rBackward -padx $Gui(pad) -pady $Gui(pad)
    
    #-------------------------------------------
    # Path->Top->Step frame
    #-------------------------------------------
    set f $w.fTop.fStep

    # Position Sliders

    eval {label $f.lstep -text "Frame:"} $Gui(WLA)

    eval {entry $f.estep \
        -textvariable CrossSection(path,stepStr) -width 4} $Gui(WEA) {-bg $CrossSection(path,sColor)}
    bind $f.estep <Return> \
        {CrossSectionSetPathFrame $CrossSection(activeCam) $CrossSection(path,activeId); Render3D}
    
    eval {scale $f.sstep -from 0 -to 400 -length 100 \
            -variable CrossSection(path,stepStr) \
        -command {CrossSectionSetPathFrame $CrossSection(activeCam) $CrossSection(path,activeId); Render3D}\
            -resolution 1} $Gui(WSA) {-troughcolor $CrossSection(path,sColor)}

    set CrossSection(path,stepScale) $f.sstep
    
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
        -textvariable CrossSection(path,speedStr) -width 4} $Gui(WEA) {-bg $CrossSection(path,sColor)}
    bind $f.espeed <Return> \
        "CrossSectionSetSpeed; Render3D"
    
    eval {scale $f.sspeed -from 1 -to 20 -length 100 \
            -variable CrossSection(path,speedStr) \
            -command "CrossSectionSetSpeed; Render3D"\
            -resolution 1} $Gui(WSA) {-troughcolor $CrossSection(path,sColor)}

    set CrossSection(path,speedScale) $f.sspeed
    
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
        -textvariable CrossSection(path,interpolationStr) -width 4} $Gui(WEA) {-bg $CrossSection(path,sColor)}
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
            -bd 2} $Gui(WMBA) {-bg $CrossSection(path,eColor)}
    set CrossSection(mDriver) $f.mbDriver.m
    set CrossSection(mbDriver) $f.mbDriver
    eval {menu $f.mbDriver.m} $Gui(WMA) {-bg $CrossSection(path,eColor)}
    foreach item "User Camera FocalPoint Intersection" {
            $CrossSection(mDriver) add command -label $item \
                -command "CrossSectionSetSliceDriver $item"
    }

    grid $f.lDriver $f.mbDriver -padx $Gui(pad) -pady $Gui(pad)    
    
}

   
#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateLabelAndSlider
# 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateLabelAndSlider {f labelName labelHeight labelText sliderName orient from to length variable commandString entryWidth defaultSliderValue} {

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
# .PROC CrossSectionCreateCheckButton
# 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateCheckButton {ButtonName VariableName Message Command {Indicatoron 0} {Width 0} } {
    global Gui
    if {$Width == 0 } {
        set Width [expr [string length $Message]]
    }
    eval  {checkbutton $ButtonName -variable $VariableName -text \
    $Message -width $Width -indicatoron $Indicatoron -command $Command } $Gui(WCA)
} 


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetVisibility {a} {

    global CrossSection

    if {$a == "gyro"} {
        set CrossSection(gyro,use) $CrossSection($a,visibility)
        CrossSectionUseGyro 
    } else {
        CrossSection($a,actor) SetVisibility $CrossSection($a,visibility)
    }
}
#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateAdvancedGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateAdvancedGUI {f a {vis ""} {col ""} {size ""}} {
    global Gui CrossSection Color Advanced

    
    # Name / Visible only if vis is not empty
    if {$vis == "visible"} {
        eval {checkbutton $f.c$a \
            -text $CrossSection($a,name) -wraplength 65 -variable CrossSection($a,visibility) \
            -width 11 -indicatoron 0\
            -command "CrossSectionSetVisibility $a; Render3D"} $Gui(WCA)
    } else {
        eval {label $f.c$a -text $CrossSection($a,name)} $Gui(WLA)
    }

    # Change colors
    if {$col == "color"} {
        eval {button $f.b$a \
            -width 1 -command "CrossSectionSetActive $a $f.b$a; ShowColors CrossSectionPopupCallback; Render3D" \
            -background [MakeColorNormalized $CrossSection($a,color)]}
    } else {
        eval {label $f.b$a -text " " } $Gui(WLA)
    }
    
    if {$size == "size"} {
    
        eval {entry $f.e$a -textvariable CrossSection($a,size) -width 3} $Gui(WEA)
        bind $f.e$a  <Return> "CrossSectionSetSize $a"
        eval {scale $f.s$a -from 0.0 -to $CrossSection($a,size) -length 70 \
            -variable CrossSection($a,size) \
            -command "CrossSectionSetSize $a; Render3D" \
            -resolution 0.01} $Gui(WSA) {-sliderlength 10 }    
        grid $f.c$a $f.b$a $f.e$a $f.s$a -pady 0 -padx 0        
    } else {
        grid $f.c$a $f.b$a -pady 0 -padx 0        
    }
}

    
#-------------------------------------------------------------------------------
# .PROC CrossSectionSetActive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetActive {a b} {

    global Advanced

    set Advanced(ActiveActor) $a
    set Advanced(ActiveButton) $b 
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionPopupCallback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionPopupCallback {} {
    global Label CrossSection Color Gui Advanced

    set name $Label(name) 

    set a $Advanced(ActiveActor)

    # Use second color by default
    set color [lindex $Color(idList) 1]

    foreach c $Color(idList) {
        if {[Color($c,node) GetName] == $name} {
            set color $c
        }
    }

    [CrossSection($a,actor) GetProperty] SetAmbient    [Color($color,node) GetAmbient]
    [CrossSection($a,actor) GetProperty] SetDiffuse    [Color($color,node) GetDiffuse]
    [CrossSection($a,actor) GetProperty] SetSpecular   [Color($color,node) GetSpecular]
    [CrossSection($a,actor) GetProperty] SetSpecularPower [Color($color,node) GetPower]
    eval [CrossSection($a,actor) GetProperty] SetColor    [Color($color,node) GetDiffuseColor]

    set CrossSection($a,color) [Color($color,node) GetDiffuseColor]

    # change the color of the button on the Advanced GUI
    $Advanced(ActiveButton) configure -background [MakeColorNormalized [[CrossSection($a,actor) GetProperty] GetColor]]

#     if {$Advanced(ActiveActor) == "Box"} {
        
#         [CrossSection(Box2,actor) GetProperty] SetAmbient    [Color($color,node) GetAmbient]
#         [CrossSection(Box2,actor) GetProperty] SetDiffuse    [Color($color,node) GetDiffuse]
#         [CrossSection(Box2,actor) GetProperty] SetSpecular   [Color($color,node) GetSpecular]
#         [CrossSection(Box2,actor) GetProperty] SetSpecularPower [Color($color,node) GetPower]
#         eval [CrossSection(Box2,actor) GetProperty] SetColor    [Color($color,node) GetDiffuseColor]

#     }
    Render3D
}


##############################################################################
#
#        PART 3: Selection of actors through key/mouse
#
#############################################################################

#-------------------------------------------------------------------------------
# .PROC CrossSectionUseGyro
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUseGyro {} {
    global CrossSection
    
    if { $CrossSection(gyro,use) == 1} {
        foreach XX "X Y Z" {
            [CrossSection(gyro,${XX}actor) GetProperty] SetOpacity 1
        }
        CrossSectionSetPickable CrossSection(gyro,actor) 1
    } else {
        foreach XX "X Y Z" {
            [CrossSection(gyro,${XX}actor) GetProperty] SetOpacity 0
        }
        CrossSectionSetPickable CrossSection(gyro,actor) 0
    }
    Render3D
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionSelectActor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc CrossSectionSelectActor {actor} {
#    
#    global CrossSection Ev Csys
#    
#    if { [$actor GetProperty] == [CrossSection(vector,actor) GetProperty] } {
#        set numCells [[CrossSection(vector,source) GetOutput] GetNumberOfCells]
#        
#        set cid [Csys(picker) GetCellId]
#        # see which vector we have selected
#        set id [expr $cid/$numCells]
#        CrossSectionVectorSelected $id
#        return 1
#    } else{ 
#    foreach id $CrossSection(path,activeIdList) {
#    # go through our list of paths that we know are on the screen
#    # and try to see which landmark was selected
#
#        if { [$actor GetProperty] == [CrossSection($id,path,actor) GetProperty] } {
#        set numCells [[CrossSection($id,path,source) GetOutput] GetNumberOfCells]
#        
#        set cid [Csys(picker) GetCellId]
#        # see which landmark we have selected
#        set id [expr $cid/$numCells]
#        CrossSectionLandmarkSelected $id
#    return 1
#    } else {
#    return 0
#    }
#}


#-------------------------------------------------------------------------------
# .PROC CrossSectionVectorSelected
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc CrossSectionVectorSelected {id} {

#    global CrossSection

#    CrossSection(vector,scalars) SetScalar $CrossSection(vector,selectedID) 0.5
#    CrossSection(vector,scalars) SetScalar $id 0
#    CrossSection(vector,polyData) Modified
#    set CrossSection(vector,selectedID) $id    
  #  CrossSectionMoveGyroToVector $id
#    CrossSectionMoveGyroToLandmark $id
#    Render3D
#}

#-------------------------------------------------------------------------------
# .PROC CrossSectionLandmarkSelected
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc CrossSectionLandmarkSelected {{id ""}} {
#
#    global CrossSection
#
#    if {$id == ""} {
#    # this was called when the user selected a landmark in the text box,
#    # so find out the id
#    set id [$CrossSection(path,fLandmarkList) curselection]
#    }
#    
#    CrossSection(cLand,scalars) SetScalar $CrossSection(cLand,selectedID) 0.2 
#    CrossSection(cLand,scalars) SetScalar $id 0 
#    CrossSection(cLand,polyData) Modified
#    set CrossSection(cLand,selectedID) $id    
#    CrossSectionUpdateSelectionLandmarkList $id
#    CrossSectionMoveGyroToLandmark  $id
#    Render3D
#}


#############################################################################
#
#      PART 4 : Endoscope movement
#
#############################################################################

#-------------------------------------------------------------------------------
# .PROC CrossSectionGyroMotion
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionGyroMotion {actor angle dotprod unitX unitY unitZ} {
    
    global CrossSection
    if {$actor == "CrossSection(gyro,actor)"} {
        # get the position of the gyro and set the sliders
        set cam_mat [CrossSection(cam,actor) GetMatrix]   
        set CrossSection(cam,xStr,old) [$cam_mat GetElement 0 3] 
        set CrossSection(cam,yStr,old) [$cam_mat GetElement 1 3] 
        set CrossSection(cam,zStr,old) [$cam_mat GetElement 2 3] 
        set CrossSection(cam,xStr) [$cam_mat GetElement 0 3] 
        set CrossSection(cam,yStr) [$cam_mat GetElement 1 3] 
        set CrossSection(cam,zStr) [$cam_mat GetElement 2 3] 

        # get the orientation of the gyro and set the sliders 
        set or [CrossSection(gyro,actor) GetOrientation]
        set CrossSection(cam,rxStr,old) [lindex $or 0]
        set CrossSection(cam,ryStr,old) [lindex $or 1]
        set CrossSection(cam,rzStr,old) [lindex $or 2]
        set CrossSection(cam,rxStr) [lindex $or 0]
        set CrossSection(cam,ryStr) [lindex $or 1]
        set CrossSection(cam,rzStr) [lindex $or 2]

        CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
        CrossSectionCheckDriver $CrossSection(activeCam)
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionSetGyroOrientation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetGyroOrientation {} {
    global CrossSection
    if {$CrossSection(cam,axis) == "relative"} {
        vtkTransform tmp
        tmp SetMatrix [CrossSection(cam,actor) GetMatrix] 
        eval CrossSection(gyro,actor) SetOrientation [tmp GetOrientation]
        tmp Delete
        CrossSection(cam,actor) SetOrientation 0 0 0
    } elseif {$CrossSection(cam,axis) == "absolute"} {
        set or [CrossSection(gyro,actor) GetOrientation]
        CrossSection(gyro,actor) SetOrientation 0 0 0
        eval CrossSection(cam,actor) SetOrientation $or
    }       
}
    
#-------------------------------------------------------------------------------
# .PROC CrossSectionSetWorldPosition
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetWorldPosition {x y z} {
    global CrossSection


    # reset the sliders
    set CrossSection(cam,xStr) $x
    set CrossSection(cam,yStr) $y
    set CrossSection(cam,zStr) $z
    set CrossSection(cam,xStr,old) $x
    set CrossSection(cam,yStr,old) $y
    set CrossSection(cam,zStr,old) $z
    CrossSection(gyro,actor) SetPosition $x $y $z
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetWorldOrientation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetWorldOrientation {rx ry rz} {
    global CrossSection


    # reset the sliders
    set CrossSection(cam,rxStr) $rx
    set CrossSection(cam,ryStr) $ry
    set CrossSection(cam,rzStr) $rz
    set CrossSection(cam,rxStr,old) $rx
    set CrossSection(cam,ryStr,old) $ry
    set CrossSection(cam,rzStr,old) $rz
    CrossSection(gyro,actor) SetOrientation $rx $ry $rz
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionSetCameraPosition
#  This is called when the position sliders are updated. We use the values
#  stored in the slider variables to update the position of the endoscope 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetCameraPosition {{value ""}} {
    global CrossSection View CrossSection
    
    set collision 0
    
    # get the View plane of the virtual camera because we want to move 
    # in and out along that plane
    set l [$CrossSection(activeCam) GetViewPlaneNormal]
    set IO(x) [expr -[lindex $l 0]]
    set IO(y) [expr -[lindex $l 1]] 
    set IO(z) [expr -[lindex $l 2]]
    
    
    # get the View up of the virtual camera because we want to move up
    # and down along that plane (and reverse it)
    set l [$CrossSection(activeCam) GetViewUp]
    set Up(x) [lindex $l 0]
    set Up(y) [lindex $l 1]
    set Up(z) [lindex $l 2]
    
    
    # cross Up and IO to get the vector LR (to slide left and right)
    # LR = Up x IO

    #Cross LR Up IO 
    Cross LR IO Up 
    Normalize LR

    
    # if we want to go along the camera's own axis (Relative mode)
    # CrossSection(cam,XXStr) is set by the slider
    # CrossSection(cam,XXStr,old) is saved at the end of this proc
    
    # for the next time 
    if { $CrossSection(cam,axis) == "relative" } {
        
        # this matrix tells us the current position of the cam actor
        set cam_mat [CrossSection(cam,actor) GetMatrix]   
        # stepXX is the amount to move along axis XX
        set stepX [expr $CrossSection(cam,xStr,old) - $CrossSection(cam,xStr)]
        set stepY [expr $CrossSection(cam,yStr,old) - $CrossSection(cam,yStr)]
        set stepZ [expr $CrossSection(cam,zStr,old) - $CrossSection(cam,zStr)]
        
        set CrossSection(cam,x) [expr [$cam_mat GetElement 0 3] + \
            $stepX*$LR(x) + $stepY * $IO(x) + $stepZ * $Up(x)] 
        set CrossSection(cam,y) [expr  [$cam_mat GetElement 1 3] + \
            $stepX * $LR(y) + $stepY * $IO(y) + $stepZ * $Up(y)] 
        set CrossSection(cam,z) [expr  [$cam_mat GetElement 2 3] + \
            $stepX * $LR(z) +  $stepY * $IO(z) +  $stepZ * $Up(z)] 
    
    } elseif { $CrossSection(cam,axis) == "absolute" } {
        set CrossSection(cam,x) $CrossSection(cam,xStr)
        set CrossSection(cam,y) $CrossSection(cam,yStr)
        set CrossSection(cam,z) $CrossSection(cam,zStr)
    }
    
    # store current slider
    set CrossSection(cam,xStr,old) $CrossSection(cam,xStr)
    set CrossSection(cam,yStr,old) $CrossSection(cam,yStr)
    set CrossSection(cam,zStr,old) $CrossSection(cam,zStr)

    # set position of actor gyro (that will in turn set the position
    # of the camera and fp actor since their user matrix is linked to
    # the matrix of the gyro
    CrossSection(gyro,actor) SetPosition $CrossSection(cam,x) $CrossSection(cam,y) $CrossSection(cam,z)
    
    #################################
    # should not be needed anymore
    #CrossSection(cam,actor) SetPosition $CrossSection(cam,x) $CrossSection(cam,y) $CrossSection(cam,z)
    #CrossSection(fp,actor) SetPosition $CrossSection(fp,x) $CrossSection(fp,y) $CrossSection(fp,z)
    ##################################
    # set position of virtual camera
    CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)

    #*******************************************************************
    #
    # STEP 3: if the user decided to have the camera drive the slice, 
    #         then do it!
    #
    #*******************************************************************
    CrossSectionCheckDriver $CrossSection(activeCam)

    Render3D
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionResetCameraPosition
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionResetCameraPosition {} {
    global CrossSection

    CrossSectionSetWorldPosition 0 0 0
    # in case the camera's model matrix is not the identity
    CrossSection(cam,actor) SetPosition 0 0 0
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionSetCameraDirection
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetCameraDirection {{value ""}} {
    global CrossSection View Model

    if {$CrossSection(cam,axis) == "absolute"} {
    
    #CrossSection(gyro,actor) SetOrientation $CrossSection(cam,rxStr) $CrossSection(cam,ryStr) $CrossSection(cam,rzStr) 
    if {$value == "rx"} {
        set temprx [expr $CrossSection(cam,rxStr) - $CrossSection(cam,rxStr,old)]
        set CrossSection(cam,rxStr,old) $CrossSection(cam,rxStr)
        CrossSection(gyro,actor) RotateWXYZ $temprx 1 0 0
    } elseif {$value == "ry"} {
        set tempry [expr $CrossSection(cam,ryStr) - $CrossSection(cam,ryStr,old)]
        set CrossSection(cam,ryStr,old) $CrossSection(cam,ryStr)
        CrossSection(gyro,actor) RotateWXYZ $tempry 0 1 0
        #$CrossSection(activeCam) Roll $tempry
    } elseif {$value == "rz"} {
        set temprz [expr $CrossSection(cam,rzStr) - $CrossSection(cam,rzStr,old)]
        set CrossSection(cam,rzStr,old) $CrossSection(cam,rzStr)
        CrossSection(gyro,actor) RotateWXYZ $temprz 0 0 1
    }
    #eval CrossSection(gyro,actor) SetOrientation [CrossSection(gyro,actor) GetOrientation]        
    
    } elseif {$CrossSection(cam,axis) == "relative"} {
        if {$value == "rx"} {
            set temprx [expr $CrossSection(cam,rxStr) - $CrossSection(cam,rxStr,old)]
            set CrossSection(cam,rxStr,old) $CrossSection(cam,rxStr)
            CrossSection(gyro,actor) RotateX $temprx
        } elseif {$value == "ry"} {
            set tempry [expr $CrossSection(cam,ryStr) - $CrossSection(cam,ryStr,old)]
            set CrossSection(cam,ryStr,old) $CrossSection(cam,ryStr)
            CrossSection(gyro,actor) RotateY $tempry
        } elseif {$value == "rz"} {
            set temprz [expr $CrossSection(cam,rzStr) - $CrossSection(cam,rzStr,old)]
            set CrossSection(cam,rzStr,old) $CrossSection(cam,rzStr)
            CrossSection(gyro,actor) RotateZ $temprz
        }
    }
    
    #*******************************************************************
    #
    # if the user decided to have the camera drive the slice, 
    #         then do it!
    #
    #*******************************************************************
    CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
    CrossSectionCheckDriver $CrossSection(activeCam)  

   
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionResetCameraDirection
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionResetCameraDirection {} {
    global CrossSection 

    # we reset the rotation around the absolute y axis
    set CrossSection(cam,yRotation) 0
    set CrossSection(cam,viewUpX) 0
    set CrossSection(cam,viewUpY) 0
    set CrossSection(cam,viewUpZ) 1

    CrossSectionSetWorldOrientation 0 0 0 
    # in case the camera's model matrix is not the identity
    CrossSection(cam,actor) SetOrientation 0 0 0
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateActorFromVirtualEndoscope
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateActorFromVirtualEndoscope {vcam} {
    global CrossSection View Path Model
        
    #*********************************************************************
    #
    # STEP 1: set the gyro matrix's orientation based on the virtual
    #         camera's matrix
    #         
    #*********************************************************************
    
    # this doesn't work because the virtual camera is rotated -90 degrees on 
    # the y axis originally, so the overall matrix is not correct (off by 90 degrees)
    #eval CrossSection(gyro,actor) SetOrientation [$CrossSection(activeCam) GetOrientation]
    #eval CrossSection(gyro,actor) SetPosition [$CrossSection(activeCam) GetPosition]

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
    set position [$CrossSection(activeCam) GetPosition]
    eval CrossSection(gyro,actor) SetOrientation $orientation
    eval CrossSection(gyro,actor) SetPosition $position
    endoscopicTransform Delete
    matrix Delete

    # set the sliders
    set CrossSection(cam,xStr) [lindex $position 0]
    set CrossSection(cam,yStr) [lindex $position 1]
    set CrossSection(cam,zStr) [lindex $position 2]
    set CrossSection(cam,xStr,old) [lindex $position 0]
    set CrossSection(cam,yStr,old) [lindex $position 1]
    set CrossSection(cam,zStr,old) [lindex $position 2]

    set CrossSection(cam,rxStr) [lindex $orientation 0]
    set CrossSection(cam,ryStr) [lindex $orientation 1]
    set CrossSection(cam,rzStr) [lindex $orientation 2]
    set CrossSection(cam,rxStr,old) [lindex $orientation 0]
    set CrossSection(cam,ryStr,old) [lindex $orientation 1]
    set CrossSection(cam,rzStr,old) [lindex $orientation 2]
    
    #*******************************************************************
    #
    # STEP 2: if the user decided to have the camera drive the slice, 
    #         then do it!
    #
    #*******************************************************************

    CrossSectionCheckDriver $vcam

}

#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
#       Updates the virtual camera's position, orientation and view angle
#       Calls CrossSectionLightFollowsEndoCamera
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateVirtualEndoscope {vcam {coordList ""}} {
    global CrossSection Model View Path
    
    #puts "vcam $vcam"
    
    if {$coordList != "" && [llength $coordList] == 6} {
        #puts "in first case"
        # COORDLIST IS NOT EMPTY IF WE WANT TO SET THE VIRTUAL CAMERA ONLY
        # BASED ON INFORMATION ABOUT THE POSITION OF THE ACTOR CAMERA AND
        # ACTOR FOCAL POINT
        # we only have information about the position of the camera and the 
        # focal point. Extrapolate the additional information from that 
        $vcam SetPosition [lindex $coordList 0] [lindex $coordList 1] [lindex $coordList 2]
        $vcam SetFocalPoint [lindex $coordList 3] [lindex $coordList 4] [lindex $coordList 5] 
        # use prior information to prevent the View from flipping at undefined
        # boundary points (i.e when the viewUp and the viewPlaneNormal are 
        # parallel, OrthogonalizeViewUp sometimes produces a viewUp that 
        # flips direction 

        # weird boundary case if user the fp/cam vector is parallel to old
        # view up -- check for that with the dot product

        $vcam SetViewUp $CrossSection(cam,viewUpX) $CrossSection(cam,viewUpY) $CrossSection(cam,viewUpZ)    
        
    } elseif {$coordList == ""} {
        # COORDLIST IS EMPTY IF WE JUST WANT THE VIRTUAL CAMERA TO MIMICK
        # THE CURRENT ACTOR CAMERA
        # we want the virtual camera to be in the same position/orientation 
        # than the endoscope and we have all the information we need
        # so set the position, focal point, and view up (the z unit vector of 
        # the camera actor's orientation [the 3rd column of its world matrix])
        set cam_mat [CrossSection(cam,actor) GetMatrix]   
        $vcam SetPosition [$cam_mat GetElement 0 3] [$cam_mat GetElement 1 3] [$cam_mat GetElement 2 3]     
        set fp_mat [CrossSection(fp,actor) GetMatrix]
        $vcam SetFocalPoint [$fp_mat GetElement 0 3] [$fp_mat GetElement 1 3] [$fp_mat GetElement 2 3] 
        $vcam SetViewUp [$cam_mat GetElement 0 2] [$cam_mat GetElement 1 2] [$cam_mat GetElement 2 2] 
    }
    $vcam ComputeViewPlaneNormal        
    $vcam OrthogonalizeViewUp
    # save the current view Up
    set l [$CrossSection(activeCam) GetViewUp]
    set CrossSection(cam,viewUpX) [expr [lindex $l 0]]
    set CrossSection(cam,viewUpY) [expr [lindex $l 1]] 
    set CrossSection(cam,viewUpZ) [expr [lindex $l 2]]

    # save the current view Plane
    set l [$CrossSection(activeCam) GetViewPlaneNormal]
    set CrossSection(cam,viewPlaneNormalX) [expr -[lindex $l 0]]
    set CrossSection(cam,viewPlaneNormalY) [expr -[lindex $l 1]] 
    set CrossSection(cam,viewPlaneNormalZ) [expr -[lindex $l 2]]
    
    CrossSectionSetCameraViewAngle
    eval $vcam SetClippingRange $View(endoscopicClippingRange)    
    CrossSectionLightFollowEndoCamera $vcam
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionLightFollowEndoCamera
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionLightFollowEndoCamera {vcam} {
    global View CrossSection
    
    # 3D Viewer
    
    set endoCurrentLight View($vcam,light)
    
    eval $endoCurrentLight SetPosition [$vcam GetPosition]
    eval $endoCurrentLight SetIntensity 1
    eval $endoCurrentLight SetFocalPoint [$vcam GetFocalPoint]
    
    set endoCurrentLight View($vcam,light2)
    eval $endoCurrentLight SetFocalPoint [$CrossSection(activeCam) GetPosition]
    eval $endoCurrentLight SetIntensity 1
    eval $endoCurrentLight SetConeAngle 180    
    eval $endoCurrentLight SetPosition [$CrossSection(activeCam) GetFocalPoint]
}
    
    
#-------------------------------------------------------------------------------
# .PROC CrossSectionSetCameraZoom
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetCameraZoom {} {
    global CrossSection Model View
    
    # get the View plane of the virtual camera because we want to move 
    # in and out along that plane
    set l [$CrossSection(activeCam) GetViewPlaneNormal]
    set IO(x) [expr -[lindex $l 0]]
    set IO(y) [expr -[lindex $l 1]] 
    set IO(z) [expr -[lindex $l 2]]

    set CrossSection(fp,distance) $CrossSection(cam,zoomStr)

    # now move the fp a percentage of its distance to the camera
    set CrossSection(cam,x) [expr $CrossSection(fp,x) - $IO(x) * $CrossSection(fp,distance)]
    set CrossSection(cam,y) [expr $CrossSection(fp,y) - $IO(y) * $CrossSection(fp,distance)]
    set CrossSection(cam,z) [expr $CrossSection(fp,z) - $IO(z) * $CrossSection(fp,distance)]
    
    CrossSection(cam,actor) SetPosition $CrossSection(cam,x) $CrossSection(cam,y) $CrossSection(cam,z)
    CrossSection(gyro,actor) SetPosition $CrossSection(cam,x) $CrossSection(cam,y) $CrossSection(cam,z)
    CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetCameraViewAngle
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetCameraViewAngle {} {
    global CrossSection Model View

    set CrossSection(cam,viewAngle) $CrossSection(cam,AngleStr)
    $CrossSection(activeCam) SetViewAngle $CrossSection(cam,viewAngle)
    
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetCameraAxis
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetCameraAxis {{axis ""}} {
    global CrossSection Model
    
    if {$axis != ""} {
        if {$axis == "absolute" || $axis == "relative"} {
            set CrossSection(cam,axis) $axis
            
            # Change button text
            #$CrossSection(axis) config -text $axis

            
            # update the actual camera position for the slider

            if {$axis == "relative"} {
                $CrossSection(labelx) configure -text "Left/Right"
                $CrossSection(labely) configure -text "Forw/Back"
                $CrossSection(labelz) configure -text "Up/Down"        

            } elseif {$axis == "absolute"} {
                $CrossSection(labelx) configure -text "L<->R "
                $CrossSection(labely) configure -text "P<->A "
                $CrossSection(labelz) configure -text "I<->S "
            }
            set l [$CrossSection(gyro,actor) GetPosition]
            set CrossSection(cam,xStr) [expr [lindex $l 0]]
            set CrossSection(cam,yStr) [expr [lindex $l 1]]
            set CrossSection(cam,zStr) [expr [lindex $l 2]]
            
            set CrossSection(cam,xStr,old) [expr [lindex $l 0]]
            set CrossSection(cam,yStr,old) [expr [lindex $l 1]]
            set CrossSection(cam,zStr,old) [expr [lindex $l 2]]
            
            $CrossSection(sliderx) set $CrossSection(cam,xStr)
            $CrossSection(slidery) set $CrossSection(cam,yStr)
            $CrossSection(sliderz) set $CrossSection(cam,zStr)
            
            
            vtkTransform tmp
            tmp SetMatrix [$CrossSection(gyro,actor) GetMatrix] 
            set l [tmp GetOrientation]
            tmp Delete
            set CrossSection(cam,rxStr) [expr [lindex $l 0]]
            set CrossSection(cam,ryStr) [expr [lindex $l 1]]
            set CrossSection(cam,rzStr) [expr [lindex $l 2]]
            
            set CrossSection(cam,rxStr,old) [expr [lindex $l 0]]
            set CrossSection(cam,ryStr,old) [expr [lindex $l 1]]
            set CrossSection(cam,rzStr,old) [expr [lindex $l 2]]
            
            $CrossSection(sliderrx) set $CrossSection(cam,rxStr)
            $CrossSection(sliderry) set $CrossSection(cam,ryStr)
            $CrossSection(sliderrz) set $CrossSection(cam,rzStr)
        
        } else {
            return
        }   
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionCameraMotionFromUser
#
# called whenever the active camera is moved. This routine syncs the position of
# the graphical endoscopic camera with the virtual endoscopic camera
# (i.e if the user changes the view of the endoscopic window with the mouse,
#  we want to change the position of the graphical camera)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCameraMotionFromUser {} {
    
    global View CrossSection
    global CurrentCamera 
    
    #puts "$CurrentCamera"
    if {$CurrentCamera == $CrossSection(activeCam)} {
        CrossSectionUpdateActorFromVirtualEndoscope $CrossSection(activeCam)
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionSetCollision
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetCollision {value} {
    global CrossSection

    set CrossSection(collision) $value
    if { $value == 0 } {
        $CrossSection(collMenu) config -text "off"
    } else {
        $CrossSection(collMenu) config -text "on"
    }
}


############################################################################
#
#       PART 5: Vector Operation
#
###########################################################################

#proc CrossSectionMoveGyroToVector {id} {
#    
#    global CrossSection 
#    set xyz [CrossSection(cLand,graphicalInterpolatedPoints) GetPoint $id]
#    set CrossSection(cam,xStr) [lindex $xyz 0]
#    set CrossSection(cam,yStr) [lindex $xyz 1]
#    set CrossSection(cam,zStr) [lindex $xyz 2]
#    CrossSectionSetCameraPosition
#}

#-------------------------------------------------------------------------------
# .PROC CrossSectionMoveGyroToLandmark
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionMoveGyroToLandmark {id} {
    
    global CrossSection 
    set xyz [CrossSection(cLand,keyPoints) GetPoint $id]
    set rxyz [CrossSection(fLand,keyPoints) GetPoint $id]
    
    CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam) "[lindex $xyz 0] [lindex $xyz 1] [lindex $xyz 2] [lindex $rxyz 0] [lindex $rxyz 1] [lindex $rxyz 2]" 
    CrossSectionUpdateActorFromVirtualEndoscope $CrossSection(activeCam)
}

#proc CrossSectionRotateVector {} {
#    global CrossSection 
    
    # change the vector direction based on the current camera orientation

#   set rxyz [CrossSection(cam,actor) GetOrientation]
#    CrossSection(vector,vectors) SetVector $CrossSection(vector,selectedID) [lindex $rxyz 0] [lindex $rxyz 1] [lindex $rxyz 2] 
#    CrossSection(vector,polyData) Modified
#    Render3D
#}

#proc CrossSectionRotateVector {} {
#
#    global CurrentCamera 
#    global LastX 
#    global RendererFound
#    global View Module CrossSection
#
#    set axis $CrossSection(cam,movementAxis)
#    
#    if { $axis != "" } {
#    
#    if { ! $RendererFound } { return }
#    if {[info exists Module(CrossSection,procEnter)] == 1} {
#        
#        set CrossSection(cam,r${axis}Str) [expr $tmp + ($LastX - $x)]
#        CrossSectionSetCameraDirection "r${axis}"
#        set list [CrossSection(cam,actor) GetOrientation]
#        CrossSection(gyro,actor) SetOrientation [lindex $list 0] [lindex $list 1] [lindex $list 2]
#        Render3D
#        set LastX $x
#        }
#    } else {
#    tk_messageBox -message "No axis selected. Please select an axis with the mouse and press the key 's' "
#    }
#}



#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateVectors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateVectors {id} {
        
    global CrossSection
    set numPoints [CrossSection($id,cpath,keyPoints) GetNumberOfPoints]
    for {set i 0} {$i < $numPoints} {incr i} {
        set cp [CrossSection($id,cpath,keyPoints) GetPoint $i]
        set fp [CrossSection($id,cpath,keyPoints) GetPoint $i]
        
        set cpX [lindex $cp 0]
        set cpY [lindex $cp 1]
        set cpZ [lindex $cp 2]
        
        set fpX [lindex $fp 0]
        set fpY [lindex $fp 1]
        set fpZ [lindex $fp 2]
        
        CrossSection($id,vector,vectors) InsertVector $i [expr $fpX - $cpX] [expr $fpY - $cpY] [expr $fpZ - $cpZ]
        
        CrossSection($id,vector,scalars) InsertScalar $i .5 
        CrossSection($id,vector,polyData) Modified
    }
}

#############################################################################
#
#     PART 6: Landmark Operations
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC CrossSectionGetAvailableListName
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionGetAvailableListName {model} {
    global CrossSection

    if {[info exists CrossSection(${model}Path,nextAvailableId)] == 0} {
        set CrossSection(${model}Path,nextAvailableId) 1
    }
    set numList $CrossSection(${model}Path,nextAvailableId)
    set list ${model}$numList
    incr CrossSection(${model}Path,nextAvailableId)
    return $list
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionAddLandmarkNoDirectionSpecified
#
# this procedure is called when the user adds a landmark at position i 
# on a slice or on a model and we don't know yet what direction of view we 
# should save along with the landmark. There are 2 cases:
#  i = 1 => the direction vector is [0 1 0]
#  i > 1 => The direction vector is tangential to the curve 
# [(position of landmark i - 1) - (position of last interpolated point on the path]
# 
# The user can then change the direction vector interactively through the 
# user interface.
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC CrossSectionAddLandmarkNoDirectionSpecified
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionAddLandmarkNoDirectionSpecified {x y z {list ""}} {
    global CrossSection Point Fiducials
    
    
    ########### GET THE RIGHT LIST TO ADD THE POINT TO ############
    # if the list is not of type endoscopic, create a new endoscopic list
    if { $list == "" } {
        # add point to active path otherwise use the default path
        if { $CrossSection(path,activeId) == "None" } {
            set numList $CrossSection(path,nextAvailableId)
            set list Path${numList}_
        CrossSectionCreateAndActivatePath $Path${numList}_
        incr CrossSection(path,nextAvailableId)
        } else {
        set id $CrossSection(path,activeId)
        set list $CrossSection($id,path,name)
    }
    } else {
    if {[info exists Fiducials($list,fid)] == 0} {    
        # if the list doesn't exist, create it
        CrossSectionCreateAndActivatePath $list
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
# .PROC CrossSectionAddLandmarkDirectionSpecified
#
# This procedure is called when we want to add a landmark at position i and 
# we know that the direction of view to save along with the landmark is the
# current view direction of the endoscope
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionAddLandmarkDirectionSpecified {{coords ""} {list ""}} {

    global CrossSection Point Fiducials 
    
 ########### GET THE RIGHT LIST TO ADD THE POINT TO ############
    # if the list is not of type endoscopic, create a new endoscopic list
    if { $list == "" } {
        # add point to active path otherwise use the default path
        if { $CrossSection(path,activeId) == "None" } {
            set numList $CrossSection(path,nextAvailableId)
            set list Path${numList}_
        CrossSectionCreateAndActivatePath $list
        incr CrossSection(path,nextAvailableId)
        } else {
        set id $CrossSection(path,activeId)
        set list $CrossSection($id,path,name)
    }
    } else {
    if {[info exists Fiducials($list,fid)] == 0} {    
        # if the list doesn't exist, create it
        CrossSectionCreateAndActivatePath $list
    }
    }
    # make that list active
    FiducialsSetActiveList $list
    
    ########## GET THE COORDINATES ################
    if { $coords == "" } {
        set cam_mat [CrossSection(cam,actor) GetMatrix]   
        set fp_mat [CrossSection(fp,actor) GetMatrix]   
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
# .PROC CrossSectionUpdateLandmark
#
# This procedure is called when we want to update the current selected  landmark to the current position and orientation of the camera actor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateLandmark {} {

    global CrossSection

    # get the current coordinates of the camera and focal point
    set cam_mat [CrossSection(cam,actor) GetMatrix]  
    set fp_mat [CrossSection(fp,actor) GetMatrix]   

    # update the selected pid
    set pid $CrossSection(selectedFiducialPoint) 
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
# .PROC CrossSectionBuildInterpolatedPath
#
# This procedure creates a new path model by:
# creating a path containing all landmarks 
#    from i = 0 to i = # of points added with CrossSectionAddLandmark*
#
# It is much faster to create a path by iteratively calling 
# CrossSectionAddLandmark* for each new landmark -> CrossSectionBuildInterpolatedPath
# 
# then by iteratively calling
# (CrossSectionAddLandmark* -> CrossSectionBuildInterpolatedPath) for each new landmark
#
# but the advantage of the latter is that the user can see the path being
# created iteratively (the former is used when loading mrml paths).
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionBuildInterpolatedPath {id} {
    
    global CrossSection Fiducials 
    
    # create vtk variables
    set numLandmarks [CrossSection($id,cpath,keyPoints) GetNumberOfPoints]
    set i $numLandmarks
    
    # only build the path if there are at least 2 landmarks
    if { $numLandmarks > 1 } {

        set numberOfkeyPoints [CrossSection($id,cpath,keyPoints) GetNumberOfPoints]

        #evaluate the first point of the spline (0)    

        CrossSection($id,cpath,graphicalInterpolatedPoints) InsertPoint 0 \
                [CrossSection($id,cpath,Spline,x) Evaluate 0] \
                [CrossSection($id,cpath,Spline,y) Evaluate 0] \
                [CrossSection($id,cpath,Spline,z) Evaluate 0]
        
        CrossSection($id,cpath,allInterpolatedPoints) InsertPoint 0 \
                [CrossSection($id,cpath,Spline,x) Evaluate 0] \
                [CrossSection($id,cpath,Spline,y) Evaluate 0] \
                [CrossSection($id,cpath,Spline,z) Evaluate 0]
        
        CrossSection($id,fpath,allInterpolatedPoints) InsertPoint 0 \
                [CrossSection($id,fpath,Spline,x) Evaluate 0] \
                [CrossSection($id,fpath,Spline,y) Evaluate 0] \
                [CrossSection($id,fpath,Spline,z) Evaluate 0]

        
        # now build the rest of the spline
        for {set i 0} {$i< [expr $numberOfkeyPoints - 1]} {incr i 1} {
            
            set pci [CrossSection($id,cpath,keyPoints) GetPoint $i]
            set pcni [CrossSection($id,cpath,keyPoints) GetPoint [expr $i+1]]
            set pfi [CrossSection($id,fpath,keyPoints) GetPoint $i]
            set pfni [CrossSection($id,fpath,keyPoints) GetPoint [expr $i+1]]
            
            # calculate the distance di between key point i and i+1 for both 
            # the camera path and fp path, keep the highest one
            
            set CrossSection($id,cpath,dist,$i) [eval CrossSectionDistanceBetweenTwoPoints $pci $pcni]
            set CrossSection($id,fpath,dist,$i) [eval CrossSectionDistanceBetweenTwoPoints $pfi $pfni]
            
            
            
            if {$CrossSection($id,cpath,dist,$i) >= $CrossSection($id,fpath,dist,$i)} {
                set di $CrossSection($id,cpath,dist,$i)
            } else {
                set di $CrossSection($id,fpath,dist,$i)
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
                set step [expr 1/($CrossSection(path,interpolationStr) * $di)]
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
                if {$CrossSection($id,cpath,dist,$i) !=0} {
                    set numPoints [CrossSection($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
                    
                    CrossSection($id,cpath,graphicalInterpolatedPoints) InsertPoint [expr $numPoints] [CrossSection($id,cpath,Spline,x) Evaluate $t] [CrossSection($id,cpath,Spline,y) Evaluate $t] [CrossSection($id,cpath,Spline,z) Evaluate $t]
                }

                foreach m "c f" {
                    # add the points for the landmark record
                    set numPoints [CrossSection($id,${m}path,allInterpolatedPoints) GetNumberOfPoints]
                    CrossSection($id,${m}path,allInterpolatedPoints) InsertPoint [expr $numPoints] [CrossSection($id,${m}path,Spline,x) Evaluate $t] [CrossSection($id,${m}path,Spline,y) Evaluate $t] [CrossSection($id,${m}path,Spline,z) Evaluate $t]
                }
            }
        }
        
        set numberOfOutputPoints [CrossSection($id,cpath,allInterpolatedPoints) GetNumberOfPoints]
        set CrossSection(path,exists) 1
        
        # since that is where the camera is
        # add cell data
        
        set numberOfOutputPoints [CrossSection($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
        CrossSection($id,path,lines) InsertNextCell $numberOfOutputPoints
        for {set i 0} {$i< $numberOfOutputPoints} {incr i 1} {
            CrossSection($id,path,lines) InsertCellPoint $i
        }    

        CrossSection($id,path,source) Modified
        # now update the vectors
        #CrossSectionUpdateVectors $id
    }
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionDeletePath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionDeletePath {} {
    global CrossSection Fiducials

    FiducialsDeleteList $Fiducials(activeList)
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionComputeRandomPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionComputeRandomPath {} {
    global CrossSection Fiducials
    
    for {set i 0} {$i<20} {incr i 1} {
        set x  [expr [CrossSection(path,vtkmath) Random -1 1] * 100]
        set y  [expr [CrossSection(path,vtkmath) Random -1 1] * 100]
        set z  [expr [CrossSection(path,vtkmath) Random -1 1] * 100] 
        CrossSectionAddLandmarkNoDirectionSpecified $x $y $z "random$CrossSection(randomPath,nextAvailableId)"
    }
    incr CrossSection(randomPath,nextAvailableId)
    MainUpdateMRML
    Render3D
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionShowPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionShowPath {} {
    global Path CrossSection
    puts "TEMPORARILY DISABLED - pending bugfix"
    if {0} {
    if {$CrossSection(path,exists) == 1} {
        if {$CrossSection(path,showPath) == 1} {
            
            foreach m {c f} {
                crosssectionScreen AddActor CrossSection(${m}Land,actor)
                crosssectionScreen AddActor CrossSection(${m}Path,actor)
            }
        } else {
            foreach m {c f} {
                crosssectionScreen RemoveActor CrossSection(${m}Land,actor)
                crosssectionScreen RemoveActor CrossSection(${m}Path,actor)
            }
        }
    }
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionFlyThroughPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionFlyThroughPath {listOfCams listOfPaths} {
    global CrossSection Model View Path Module 
    
    
    if {[lindex $listOfPaths 0] == "None"} {
        return
    }
    
    # for now assume they have as many points, so get it from the first
    # path on the list 
    set id [lindex $listOfPaths 0]
    
    set numPoints [CrossSection($id,cpath,allInterpolatedPoints) GetNumberOfPoints]
    for {set CrossSection(path,i) $CrossSection(path,stepStr)} {$CrossSection(path,i)< $numPoints} {incr CrossSection(path,i) $CrossSection(path,speed)} { 
        if {$CrossSection(path,stop) == "0"} {
            set CrossSection(path,stepStr) $CrossSection(path,i)
            
            CrossSectionSetPathFrame $listOfCams $listOfPaths
            
            update            
            Render3D    
        } else {    
            CrossSectionResetStopPath
            break
        }    
    }

}


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetPathFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetPathFrame {listOfCams listOfPaths} {
    global CrossSection Model View Path 


    if {[lindex $listOfPaths 0] == "None"} {
        return
    }
    
    foreach cam $listOfCams id $listOfPaths {
        
        set CrossSection(path,i) $CrossSection(path,stepStr)
        set l [CrossSection($id,cpath,allInterpolatedPoints) GetPoint $CrossSection(path,i)] 
        set l2 [CrossSection($id,fpath,allInterpolatedPoints) GetPoint $CrossSection(path,i)]
        
        CrossSectionUpdateVirtualEndoscope $cam "[lindex $l 0] [lindex $l 1] [lindex $l 2] [lindex $l2 0] [lindex $l2 1] [lindex $l2 2]"
        CrossSectionUpdateActorFromVirtualEndoscope $cam 
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionStopPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionStopPath {} {
    global Path CrossSection
        
    set CrossSection(path,stop) 1
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionResetStopPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionResetStopPath {} {
    global CrossSection
        
    set CrossSection(path,stop) 0
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionResetPath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionResetPath {listOfCams listOfPaths} {
    global CrossSection Path 


    if {[lindex $listOfPaths 0] == "None"} {
        return
    }
        
    set CrossSection(cam,viewUpX) 0
    set CrossSection(cam,viewUpY) 0
    set CrossSection(cam,viewUpZ) 1
    CrossSectionStopPath
    
    set CrossSection(path,stepStr) 0
    CrossSectionSetPathFrame $listOfCams $listOfPaths
    CrossSectionResetStopPath
}





#-------------------------------------------------------------------------------
# .PROC CrossSectionSetFlyDirection
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
#proc CrossSectionSetFlyDirection {{dir ""}} {
#    global CrossSection Path
#    
#    if {$dir != ""} {
#    if {$dir == "Forward" || $dir == "Backward"} {
#        set CrossSection(path,flyDirection) $dir
#    } else {
#        return
#    }   
#    }
#}


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetSpeed
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetSpeed {} {
    global CrossSection Path
    
    set CrossSection(path,speed) $CrossSection(path,speedStr)
}


#############################################################################
#
#     PART 8:  Slice driver operations
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC CrossSectionCheckDriver
# This procedure is called once the position of the endoscope is updated. It checks to see if there is a driver for the slices and calls CrossSectionReformatSlices with the right argument to update the position of the slices.

# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCheckDriver {vcam} {

global CrossSection View


    if { $CrossSection(fp,driver) == 1 } {
        eval CrossSectionReformatSlices $vcam [$vcam GetFocalPoint]

    } elseif { $CrossSection(cam,driver) == 1 } {
        eval CrossSectionReformatSlices $vcam [$vcam GetPosition]
    } elseif { $CrossSection(intersection,driver) == 1 } {
        set l [$View($vcam,renderer) GetCenter]
        set l0 [expr [lindex $l 0]]
        set l1 [expr [lindex $l 1]]
        if { [llength $l] > 2 } {
            set l2 [expr [lindex $l 2]]
        } else {
            set l2 0
        }
        set p [CrossSection(picker) Pick $l0 $l1 $l2 crosssectionScreen]
        if { $p == 1} {
            set selPt [CrossSection(picker) GetPickPosition]
            set x [expr [lindex $selPt 0]]
            set y [expr [lindex $selPt 1]]
            set z [expr [lindex $selPt 2]]
            CrossSectionReformatSlices $vcam $x $y $z
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionReformatSlices
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionReformatSlices {vcam x y z} {
    global CrossSection View Slice
    
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
# .PROC CrossSectionSetSliceDriver
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetSliceDriver {name} {
    global CrossSection Model View Slice


    # Change button text
    $CrossSection(mbDriver) config -text $name
    
    
    if { $name == "User" } {
        foreach s $Slice(idList) {
            Slicer SetDriver $s 0
        }
        set CrossSection(fp,driver) 0
        set CrossSection(cam,driver) 0
        set CrossSection(intersection,driver) 0
    } else {
        foreach s $Slice(idList) {
            Slicer SetDriver $s 1
        }
        if { $name == "Camera"} {
            set m cam
            set CrossSection(fp,driver) 0
            set CrossSection(cam,driver) 1
            set CrossSection(intersection,driver) 0
        } elseif { $name == "FocalPoint"} {
            set m fp 
            set CrossSection(fp,driver) 1
            set CrossSection(cam,driver) 0
            set CrossSection(intersection,driver) 0
        } elseif { $name == "Intersection"} {
            set m intersection 
            set CrossSection(fp,driver) 0
            set CrossSection(cam,driver) 0
            set CrossSection(intersection,driver) 1
        }
        
        MainSlicesSetOrientAll "Orthogonal"
        CrossSectionCheckDriver $CrossSection(activeCam)
        Render3D
    }    
}


#############################################################################
#
#     PART 9: Fiducials operations
#
#############################################################################


#-------------------------------------------------------------------------------
# .PROC CrossSectionFiducialsPointSelectedCallback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionFiducialsPointSelectedCallback {fid pid} {
    
    global CrossSection Fiducials Select Module Model

    set CrossSection(selectedFiducialPoint) $pid
    set CrossSection(selectedFiducialList) $fid
    FiducialsSetActiveList $Fiducials($fid,name)

    # if the source or sink button are on, then make that point the 
    if { $CrossSection(sourceButton,on) == 1 } {
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
        $CrossSection(sourceLabel) configure -text "[Point($pid,node) GetName]"
        set CrossSection(source,exists) 1    
        set CrossSection(sourceButton,on) 0
    } elseif { $CrossSection(sinkButton,on) == 1 } {
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
        $CrossSection(sinkLabel) configure -text "[Point($pid,node) GetName]"
        set CrossSection(sink,exists) 1    
        set CrossSection(sinkButton,on) 0
    }


    # if it is of type endoscopic, use the actual xyz and fxyz info
    if {[Fiducials($fid,node) GetType] == "endoscopic" } {
        CrossSectionResetCameraDirection    
        CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam) [concat [Point($pid,node) GetXYZ] [Point($pid,node) GetFXYZ]]
    } else {
     # look at the point instead
     CrossSectionResetCameraDirection    
     CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam) [concat [Point($pid,node) GetFXYZ] [Point($pid,node) GetXYZ]]
    }
    CrossSectionUpdateActorFromVirtualEndoscope $CrossSection(activeCam)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionFiducialsPointCreatedCallback
# This procedures is a callback procedule called when a Fiducial Point is
# created
# If the Point is part of the "reformat" Fiducial list, then the procedure 
# selects the right number of fiducials as they are created based on which 
# step we are in
# .ARGS 
# .END
#-------------------------------------------------------------------------------
proc CrossSectionFiducialsPointCreatedCallback {type fid pid} {

    global CrossSection Fiducials Select Module Model
    # jump to that point only if it is not an endoscopic point
    if { $type != "endoscopic" } {
    CrossSectionFiducialsPointSelectedCallback $fid $pid
    }

    # if the point is added to the reformat list and the Volumes/Reformat Tab 
    # is currently active, then select the last 2 or 3 points (depending on what step we're in)

    
    set module $Module(activeID) 
    set row $Module($module,row) 
    set tab $Module($module,$row,tab) 

    if { $module == "CrossSection" && $tab == "Path"} {
        if { $Fiducials($fid,name) == "path" } {
            # select the point
            FiducialsSelectionUpdate $fid $pid 1 
            # toggle between the source and the sink
            if {$CrossSection(source,exists) == 0} {
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
                $CrossSection(sourceLabel) configure -text "[Point($pid,node) GetName]"
                set CrossSection(source,exists) 1
            } else {
                FiducialsSelectionUpdate $fid $pid 1
                PathPlanningSetSink $fid $pid
                $CrossSection(sinkLabel) configure -text "[Point($pid,node) GetName]"
                set CrossSection(source,exists) 0
            }
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateMRML {} {

    global Models Model CrossSection

    # turn off backface culling for models in crosssectionScreen
    foreach m $Model(idList) {
        $Model($m,prop,crosssectionScreen) SetBackfaceCulling 0
    }
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionStartCallbackFiducialUpdateMRML
#
# Called at the beginning of FiducialsUpdateMRML
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC CrossSectionStartCallbackFiducialsUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionStartCallbackFiducialsUpdateMRML {} {

    global CrossSection

    # reset the variables for all the paths we know about
    foreach id $CrossSection(path,activeIdList) {
        CrossSectionResetPathVariables $id
    }
    
    # keep a list of currently existing path so make it empty for now
    set CrossSection(path,activeIdList) ""
    
    #reset the menu
    foreach m $CrossSection(mPathList) {
        $m delete 0 end
    }
    $CrossSection(mPath4Fly) delete 0 end
    # FIXME?
    #set CrossSection(path,activeId) None
    
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionEndCallbackFiducialUpdateMRML
#
# Called at the end
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC CrossSectionEndCallbackFiducialsUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionEndCallbackFiducialsUpdateMRML {} {
    
    global CrossSection
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionCallbackFiducialUpdateMRML
#
# Called when Updated Fiducials are of type endoscopic
# .ARGS
# .END
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC CrossSectionCallbackFiducialsUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCallbackFiducialsUpdateMRML {type id listOfPoints} {
    global Mrml Path CrossSection
    
    if { $type != "endoscopic"} {
        return
    }

    # if we never heard about this Id, then this is a new path
    if {[lsearch $CrossSection(path,allIdsUsed) $id] == -1} {
        CrossSectionCreateVTKPath $id 
        set CrossSection($id,path,name) [Fiducials($id,node) GetName]
    }
    lappend CrossSection(path,activeIdList) $id

    # update the name field (different paths in time will have the same id)
    set CrossSection($id,path,name) [Fiducials($id,node) GetName]
    
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
        CrossSection($id,cpath,Spline,x) AddPoint $i $cx
        CrossSection($id,cpath,Spline,y) AddPoint $i $cy
        CrossSection($id,cpath,Spline,z) AddPoint $i $cz
        CrossSection($id,cpath,keyPoints) InsertPoint $i $cx $cy $cz
            
        CrossSection($id,fpath,Spline,x) AddPoint $i $fx
        CrossSection($id,fpath,Spline,y) AddPoint $i $fy
        CrossSection($id,fpath,Spline,z) AddPoint $i $fz
        CrossSection($id,fpath,keyPoints) InsertPoint $i $fx $fy $fz
    }
    CrossSectionBuildInterpolatedPath $id   
    
    # update the menus
    set name $CrossSection($id,path,name)
    
    foreach m $CrossSection(mPathList) {
        $m add command -label $name -command "CrossSectionSelectActivePath $id" 
    }
    # only add to the fly-through menu if the path has more than one point
    if {[CrossSection($id,cpath,keyPoints) GetNumberOfPoints] > 1} {
        $CrossSection(mPath4Fly) add command -label $name -command "CrossSectionSelectActivePath $id; CrossSectionResetPath $CrossSection(activeCam) $id" 
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionCreateAndActivatePath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionCreateAndActivatePath {name} {
    global CrossSection Fiducials
    
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
    CrossSectionFiducialsActivatedListCallback "endoscopic" $name $id
}

# this is a callback from the fiducials module telling us which list
# is active
# we update the path menus only if the active list in an endoscopic
# one
proc CrossSectionFiducialsActivatedListCallback {type name id} {
    global CrossSection

    # if an endoscopic list is activated, tell all the menus in the 
    # endoscopic displays
    if {$type == "endoscopic" } {
    
        set CrossSection(path,activeId) $id
        
        # change the text on menu buttons
        foreach mb $CrossSection(mbPathList) {
            $mb config -text $CrossSection($id,path,name) 
        }
        if {[CrossSection($id,cpath,keyPoints) GetNumberOfPoints] > 1} {
            $CrossSection(mbPath4Fly) config -text $CrossSection($id,path,name) 
            # configure the scale
            set CrossSection(path,stepStr) 0
            set numberOfOutputPoints [CrossSection($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
            $CrossSection(path,stepScale) config -to [expr $numberOfOutputPoints - 1]
        }
    } else {
    set CrossSection(path,activeId) "None"
    # change the text on menu buttons
        foreach mb $CrossSection(mbPathList) {
            $mb config -text "None"
        }
    $CrossSection(mbPath4Fly) config -text "None"
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionSelectActivePath
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSelectActivePath {id} {
    
    global CrossSection
    set CrossSection(path,activeId) $id
    # make that list active
    FiducialsSetActiveList $CrossSection($id,path,name)
    # change the text on menu buttons
    foreach mb $CrossSection(mbPathList) {
        $mb config -text $CrossSection($id,path,name) 
    }
    if {[CrossSection($id,cpath,keyPoints) GetNumberOfPoints] > 1} {
        $CrossSection(mbPath4Fly) config -text $CrossSection($id,path,name) 
        # configure the scale
        set CrossSection(path,stepStr) 0
        set numberOfOutputPoints [CrossSection($id,cpath,graphicalInterpolatedPoints) GetNumberOfPoints]
        $CrossSection(path,stepScale) config -to [expr $numberOfOutputPoints - 1]
    }
}

############################################################################
#
#  PART 10: Helper functions     
#
############################################################################

#-------------------------------------------------------------------------------
# .PROC CrossSectionDistanceBetweenTwoPoints
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionDistanceBetweenTwoPoints {p1x p1y p1z p2x p2y p2z} {

    return [expr sqrt((($p2x - $p1x) * ($p2x - $p1x)) + (($p2y - $p1y) * ($p2y - $p1y)) + (($p2z - $p1z) * ($p2z - $p1z)))]
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateSelectionLandmarkList
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateSelectionLandmarkList {id} {
    
    global CrossSection
    set sel [$CrossSection(path,fLandmarkList) curselection] 
    if {$sel != ""} {
        $CrossSection(path,fLandmarkList) selection clear $sel $sel
    }
    $CrossSection(path,fLandmarkList) selection set $id $id
    $CrossSection(path,fLandmarkList) see $id
}



#-------------------------------------------------------------------------------
# .PROC CrossSectionSetModelsVisibilityInside
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetModelsVisibilityInside {} {
    global View Model CrossSection

    if { $CrossSection(ModelsVisibilityInside) == 0 } {
        set value 1
    } else {
        set value 0
    }
    
    foreach m $Model(idList) {
        MainModelsSetCulling $m $value
    }
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionSetSlicesVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionSetSlicesVisibility {} {
    global View CrossSection Module
    
    if { $CrossSection(SlicesVisibility) == 0 } {
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
# .PROC CrossSectionUpdateCrossSectionViewVisibility
#  Makes the endoscopic view appear or disappear based on the variable CrossSection(mainview,visibility) [note: there is a check to make sure that the endoscopic view cannot disappear if the main view is not visible)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateCrossSectionViewVisibility {} {
    global View viewWin Gui CrossSection

    if {$CrossSection(endoview,visibility) == 1 && $CrossSection(mainview,visibility) == 1} {
        CrossSectionAddCrossSectionView
    } elseif {$CrossSection(endoview,visibility) == 0 && $CrossSection(mainview,visibility) == 1} {
        CrossSectionRemoveCrossSectionView
    } elseif {$CrossSection(endoview,visibility) == 1 && $CrossSection(mainview,visibility) == 0} {
        CrossSectionAddCrossSectionView
        CrossSectionRemoveMainView
    }
    Render3D
    # for the rest do nothing
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionUpdateMainViewVisibility
# Makes the main view appear or disappear based on the variable CrossSection(mainview,visibility) [note: there is a check to make sure that the main view cannot disappear if the endoscopic view is not visible)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionUpdateMainViewVisibility {} {
    global View viewWin Gui CrossSection

    if {$CrossSection(mainview,visibility) == 1 && $CrossSection(endoview,visibility) == 1} {
        CrossSectionAddMainView
    } elseif {$CrossSection(mainview,visibility) == 0 && $CrossSection(endoview,visibility) == 1} {
        CrossSectionRemoveMainView
    } elseif {$CrossSection(mainview,visibility) == 1 && $CrossSection(endoview,visibility) == 0} {
        CrossSectionAddMainView
        CrossSectionRemoveCrossSectionView
    }
    Render3D
    # for the rest do nothing
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionAddCrossSectionView
#  Add the endoscopic renderer to the right of the main view 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionAddCrossSectionView {} {
    global View viewWin Gui CrossSection

    if {$CrossSection(viewOn) == 0} {

        CrossSectionSetSliceDriver User
        # set the endoscopic actors' visibility according to their prior visibility
            
        CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
            $viewWin AddRenderer crosssectionScreen    
        viewRen SetViewport 0 0 .5 1
            crosssectionScreen SetViewport .5 0 1 1
            MainViewerSetSecondViewOn
            MainViewerSetMode $View(mode) 
        set CrossSection(viewOn) 1
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionAddMainView
#  Add the main view to the left of the endoscopic view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionAddMainView {} {
    global View viewWin Gui CrossSection

    $viewWin AddRenderer viewRen    
    viewRen SetViewport 0 0 .5 1
    crosssectionScreen SetViewport .5 0 1 1
    MainViewerSetSecondViewOn
    set CrossSection(viewOn) 1
    MainViewerSetMode $View(mode) 
    
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionAddCrossSectionViewRemoveMainView
#  Makes the main view invisible/the endoscopic view visible
#  (so switch between the 2 views)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionAddCrossSectionViewRemoveMainView {} {
    global View viewWin Gui CrossSection
    
    if {$CrossSection(viewOn) == 0} {

        CrossSectionSetSliceDriver Camera
        # set the endoscopic actors' visibility according to their prior visibility
        
        foreach a $CrossSection(actors) {
            CrossSectionUpdateVisibility $a
        }
        Render3D
        CrossSectionUpdateVirtualEndoscope $CrossSection(activeCam)
        $viewWin AddRenderer crosssectionScreen
        $viewWin RemoveRenderer viewRen
        crosssectionScreen SetViewport 0 0 1 1
        MainViewerSetSecondViewOn
        set CrossSection(viewOn) 1
        MainViewerSetMode $View(mode) 
    }
}

#-------------------------------------------------------------------------------
# .PROC CrossSectionRemoveCrossSectionView
#  Remove the endoscopic view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionRemoveCrossSectionView {} {
    global CrossSection View viewWin Gui

    if { $CrossSection(viewOn) == 1} {


        $viewWin RemoveRenderer crosssectionScreen    
        viewRen SetViewport 0 0 1 1
        MainViewerSetSecondViewOff
        set CrossSection(viewOn) 0
        MainViewerSetMode $View(mode) 
    }
}


#-------------------------------------------------------------------------------
# .PROC CrossSectionRemoveMainView
#  Remove the main view
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionRemoveMainView {} {
    global CrossSection View viewWin viewRen crosssectionScreen
    
    $viewWin RemoveRenderer viewRen    
    crosssectionScreen SetViewport 0 0 1 1
    MainViewerSetSecondViewOn
    set CrossSection(viewOn) 1
    MainViewerSetMode $View(mode) 

}

#-------------------------------------------------------------------------------
# .PROC CrossSectionAddMainViewRemoveCrossSectionView
#  Makes the main view visible/the endoscopic view invisible
#  (so switch between the 2 views)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc CrossSectionAddMainViewRemoveCrossSectionView {} {
    global CrossSection View viewWin Gui

    if { $CrossSection(viewOn) == 1} {

        # reset the slice driver
        CrossSectionSetSliceDriver User

        # set all endoscopic actors to be invisible, without changing their visibility 
        # parameters
        foreach a $CrossSection(actors) {
            CrossSection($a,actor) SetVisibility 0
            CrossSectionSetPickable $a 0
        }
        Render3D
        $viewWin AddRenderer viewRen
        $viewWin RemoveRenderer crosssectionScreen    
        viewRen SetViewport 0 0 1 1
        MainViewerSetSecondViewOff
        set CrossSection(viewOn) 0
        MainViewerSetMode $View(mode) 
    }
}


##########################################################################

### SYNCHRONIZED

##########################################################################


#proc CrossSectionAddSyncScreen {} {

#    global CrossSection viewWin
#    
#    $viewWin AddRenderer crosssectionScreen2
#    viewRen SetViewport 0 0 0.5 0.5
#    crosssectionScreen SetViewport 0 0.5 0.5 1
#    crosssectionScreen2 SetViewport 0.5 0.5 1 1
#    Render3D
#}


#proc CrossSectionUpdateSyncWindow {} {

#global CrossSection


#if {$CrossSection(syncOn)} {
    
#    lappend Module(endoscopicRenderers) crosssectionScreen2
#    CrossSectionUpdateEndosopicViewVisibility
    
#} else {
    
#    set index [lsearch $Module(endoscopicRenderers) crosssectionScreen2]
#    if { $index != -1 } {
#    # remove the renderer from the list
#    set Module(endoscopicRenderers) [lreplace $Module(endoscopicRenderers) $index $index]
#    }
#    
#    CrossSectionUpdateEndosopicViewVisibility
#}


#}
