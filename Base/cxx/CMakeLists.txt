#
# Source files
#
# Here is where you can add the name of your local core classes.
#

SET (Base_SRCS
	vtkBoolTess.cxx vtkDCMLister.cxx vtkDCMParser.cxx 
	vtkFastCellPicker.cxx 
        vtkImageAccumulateDiscrete.cxx
	vtkImageBimodalAnalysis.cxx
	vtkImageCloseUp2D.cxx
	vtkImageConnectivity.cxx vtkImageCopy.cxx 
        vtkImageCrossHair2D.cxx 
        vtkImageDICOMReader.cxx
	vtkImageDouble2D.cxx 
        vtkImageDrawROI.cxx 
	vtkImageEditor.cxx 
        vtkImageEditorEffects.cxx 
        vtkImageErode.cxx
	vtkImageFillROI.cxx
	vtkImageFrameSource.cxx vtkImageLabelChange.cxx vtkImageLabelOutline.cxx
	vtkImageLabelVOI.cxx vtkImageLiveWire.cxx 
	vtkImageLiveWireScale.cxx vtkImageMeasureVoxels.cxx
	vtkImageLiveWireEdgeWeights.cxx
	vtkImageNeighborhoodFilter.cxx vtkImageOverlay.cxx vtkImagePlot.cxx
	vtkImageRealtimeScan.cxx vtkImageReformat.cxx vtkImageReformatIJK.cxx
	vtkImageReplaceRegion.cxx vtkImageResize.cxx vtkImageStatistics.cxx
	  vtkImageZoom2D.cxx
	vtkIndirectLookupTable.cxx vtkMathUtils.cxx vtkMrmlColorNode.cxx
	vtkMrmlCrossSectionNode.cxx vtkMrmlData.cxx vtkMrmlDataTetraMesh.cxx
	vtkMrmlDataVolume.cxx vtkMrmlEndFiducialsNode.cxx vtkMrmlEndHierarchyNode.cxx
	vtkMrmlEndModelGroupNode.cxx vtkMrmlEndPathNode.cxx vtkMrmlEndScenesNode.cxx
	vtkMrmlEndTransformNode.cxx vtkMrmlEndVolumeStateNode.cxx vtkMrmlFiducialsNode.cxx
	vtkMrmlHierarchyNode.cxx vtkMrmlLandmarkNode.cxx vtkMrmlLocatorNode.cxx
	vtkMrmlMatrixNode.cxx vtkMrmlModelGroupNode.cxx vtkMrmlModelNode.cxx
	vtkMrmlModelRefNode.cxx vtkMrmlModelStateNode.cxx vtkMrmlNode.cxx
	vtkMrmlOptionsNode.cxx vtkMrmlPathNode.cxx vtkMrmlPointNode.cxx
	vtkMrmlSceneOptionsNode.cxx vtkMrmlScenesNode.cxx vtkMrmlSlicer.cxx
	vtkMrmlTetraMeshNode.cxx vtkMrmlTransformNode.cxx vtkMrmlTree.cxx
	vtkMrmlVolumeNode.cxx vtkMrmlVolumeStateNode.cxx vtkMrmlWindowLevelNode.cxx
	vtkResliceImage.cxx vtkSurfaceProps.cxx
	vtkPolyBoolean.cxx 
        vtkImageCurveRegion.cxx vtkImageDrawObjects.cxx vtkImageGraph.cxx
        # Chand's storage of all user-defined polygons
        vtkStackOfPolygons.cxx vtkPolygonList.cxx vtkPTSWriter.cxx
	# vtkDistractorSource.cxx
	#vtkImageEuclideanDistanceTransformation.cxx 
	# more general volume reading API
	vtkMrmlDataVolumeReadWrite.cxx vtkMrmlVolumeReadWriteNode.cxx
	# volume reading for structured points
	vtkMrmlDataVolumeReadWriteStructuredPoints.cxx 
	vtkMrmlVolumeReadWriteStructuredPointsNode.cxx
	# Endoscopic Module:
	vtkImageDijkstra.cxx vtkDataSetToLabelMap.cxx
    # for the Twin module
    vtkXDisplayWindow.cxx
    vtkMrmlModuleNode.cxx
)

# vtkImageWeightedSum was added to VTK at 5.1, don't compile our copy unless it's not in VTK
IF("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" LESS 5.1)
  SET (Base_SRCS ${Base_SRCS} vtkImageWeightedSum.cxx)
  MESSAGE(STATUS "Adding vtkImageWeightedSum.cxx to source list")
ENDIF("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" LESS 5.1)

# vtkFog is not compatible with VTK 5+
IF("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" LESS 5.0)
  SET (Base_SRCS ${Base_SRCS} vtkFog.cxx)
  MESSAGE(STATUS "Adding vtkFog to source list")
ENDIF("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" LESS 5.0)

# --------------------------------------------------------------------------
# You probably do not need to modify anything below this line

#
# Create the vtkSlicerBase C++ library
#

ADD_LIBRARY (vtkSlicerBase ${Base_SRCS})

#
# Create the vtkSlicerBase Tcl library
#

IF (VTK_WRAP_TCL AND VTKSLICER_WRAP_TCL)


  VTK_WRAP_TCL (vtkSlicerBaseTCL BaseTCL_SRCS ${Base_SRCS})
  IF (APPLE)
    ADD_LIBRARY (vtkSlicerBaseTCL SHARED vtkOSXSlicerBaseTclInit.c ${BaseTCL_SRCS})
  ELSE (APPLE)
    ADD_LIBRARY (vtkSlicerBaseTCL SHARED ${BaseTCL_SRCS})
  ENDIF(APPLE)
  TARGET_LINK_LIBRARIES (vtkSlicerBaseTCL
                         vtkSlicerBase
                         vtkCommonTCL
                         vtkIOTCL 
                         vtkGraphicsTCL 
                         vtkImagingTCL 
                         vtkFilteringTCL 
                         ${TCL_LIBRARY})
  IF (APPLE)
    SET_TARGET_PROPERTIES(vtkSlicerBaseTCL PROPERTIES LINK_FLAGS "-init _oft_initSlicerBaseOSXInit")
  ENDIF(APPLE)


  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseTCL vtkHybridTCL)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseTCL vtkParallelTCL)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseTCL vtkPatentedTCL)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseTCL vtkRenderingTCL)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_TCL AND VTKSLICER_WRAP_TCL)

#
# Create the vtkSlicerBase Python library
#

IF (VTK_WRAP_PYTHON AND VTKSLICER_WRAP_PYTHON)

  VTK_WRAP_PYTHON (vtkSlicerBasePython BasePython_SRCS ${Base_SRCS})

  IF (APPLE)
    ADD_LIBRARY (vtkSlicerBasePython MODULE ${BasePython_SRCS})
  ELSE (APPLE)
    ADD_LIBRARY (vtkSlicerBasePython SHARED ${BasePython_SRCS})
  ENDIF (APPLE)

  IF (WIN32)
    TARGET_LINK_LIBRARIES (vtkSlicerBasePython 
                           vtkSlicerBase
                           vtkCommonPython
                           vtkIOPython
                           vtkGraphicsPython
                           vtkImagingPython
                           vtkFilteringPython
                           debug ${PYTHON_DEBUG_LIBRARY} 
                           optimized ${PYTHON_LIBRARY})
  ELSE (WIN32)
    TARGET_LINK_LIBRARIES (vtkSlicerBasePython 
                           vtkSlicerBase
                           vtkCommonPython
                           vtkIOPython
                           vtkGraphicsPython
                           vtkImagingPython
                           vtkFilteringPython
                           ${PYTHON_LIBRARY})
  ENDIF (WIN32)

  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkSlicerBasePython vtkHybridPython)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkSlicerBasePython vtkParallelPython)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkSlicerBasePython vtkPatentedPython)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkSlicerBasePython vtkRenderingPython)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_PYTHON AND VTKSLICER_WRAP_PYTHON)

#
# Create the vtkSlicerBase Java library
#

IF (VTK_WRAP_JAVA AND VTKSLICER_WRAP_JAVA)

  VTK_WRAP_JAVA (vtkSlicerBaseJava BaseJava_SRCS ${Base_SRCS})
  ADD_LIBRARY (vtkSlicerBaseJava SHARED ${BaseJava_SRCS})
  TARGET_LINK_LIBRARIES (vtkSlicerBaseJava
                         vtkSlicerBase
                         vtkCommonJava 
                         vtkIOJava
                         vtkGraphicsJava
                         vtkImagingJava 
                         vtkFilteringJava)
                         
  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseJava vtkHybridJava)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseJava vtkParallelJava)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseJava vtkPatentedJava)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkSlicerBaseJava vtkRenderingJava)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_JAVA AND VTKSLICER_WRAP_JAVA)

#
# Link to VTK and local
#

TARGET_LINK_LIBRARIES (
  vtkSlicerBase
  vtkCommon
  vtkIO
  vtkGraphics
  vtkImaging 
  vtkFiltering
)
  IF (APPLE)
    SET_TARGET_PROPERTIES(vtkSlicerBase PROPERTIES LINK_FLAGS "-init _oft_initSlicerBase")
  ENDIF(APPLE)

IF (VTK_USE_HYBRID)
  TARGET_LINK_LIBRARIES (vtkSlicerBase vtkHybrid)
ENDIF (VTK_USE_HYBRID)

IF (VTK_USE_PARALLEL)
  TARGET_LINK_LIBRARIES (vtkSlicerBase vtkParallel)
ENDIF (VTK_USE_PARALLEL)

IF (VTK_USE_PATENTED)
  TARGET_LINK_LIBRARIES (vtkSlicerBase vtkPatented)
ENDIF (VTK_USE_PATENTED)

IF (VTK_USE_RENDERING)
  TARGET_LINK_LIBRARIES (vtkSlicerBase vtkRendering)
ENDIF (VTK_USE_RENDERING)
