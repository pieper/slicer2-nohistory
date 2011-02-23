SET (LOCAL_LIBRARY_BASENAME vtkKullbackLeiblerRegistration)

INCLUDE (${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/KullbackLeibler/CMakeListsLocal.txt)

# --------------------------------------------------------------------------
# You probably do not need to modify anything below this line

#
# Create the vtkRigidIntensityRegistration C++ library
#
# (Doesn't work here because of a CMake bug)
# ADD_LIBRARY (vtkRigidIntensityRegistration LOCAL_MODULE_SRCS)

#
# Create the vtkRigidIntensityRegistration Tcl library
#

IF (VTK_WRAP_TCL AND VTKRIGIDINTENSITYREGISTRATION_WRAP_TCL)

  VTK_WRAP_TCL (vtkKullbackLeiblerRegistrationTCL RigidIntensityRegistrationTCL_SRCS LOCAL_MODULE_SRCS)
  ADD_LIBRARY (vtkKullbackLeiblerRegistrationTCL RigidIntensityRegistrationTCL_SRCS)
  TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationTCL 
                         vtkRigidIntensityRegistrationTCL
                         vtkIOTCL 
                         vtkGraphicsTCL 
                         vtkImagingTCL 
                         vtkFilteringTCL 
                         vtkCommonTCL
                         ${TCL_LIBRARY})
  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationTCL vtkHybridTCL)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationTCL vtkParallelTCL)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationTCL vtkPatentedTCL)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationTCL vtkRenderingTCL)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_TCL AND VTKRIGIDINTENSITYREGISTRATION_WRAP_TCL)

#
# Create the vtkKullbackLeiblerRegistration Python library
#

IF (VTK_WRAP_PYTHON AND VTKRIGIDINTENSITYREGISTRATION_WRAP_PYTHON)

  VTK_WRAP_PYTHON (vtkKullbackLeiblerRegistrationPython RigidIntensityRegistrationPython_SRCS LOCAL_MODULE_SRCS)

  IF (APPLE)
    ADD_LIBRARY (vtkKullbackLeiblerRegistrationPython MODULE RigidIntensityRegistrationPython_SRCS)
  ELSE (APPLE)
    ADD_LIBRARY (vtkKullbackLeiblerRegistrationPython SHARED RigidIntensityRegistrationPython_SRCS)
  ENDIF (APPLE)

  IF (WIN32)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationPython 
                           vtkRigidIntensityRegistrationPython
                           vtkIOPython
                           vtkGraphicsPython
                           vtkImagingPython
                           vtkFilteringPython
                           vtkCommonPython
                           debug ${PYTHON_DEBUG_LIBRARY} 
                           optimized ${PYTHON_LIBRARY})
  ELSE (WIN32)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationPython 
                           vtkIOPython
                           vtkGraphicsPython
                           vtkImagingPython
                           vtkFilteringPython
                           vtkCommonPython
                           ${PYTHON_LIBRARY})
  ENDIF (WIN32)

  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationPython vtkHybridPython)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationPython vtkParallelPython)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationPython vtkPatentedPython)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationPython vtkRenderingPython)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_PYTHON AND VTKRIGIDINTENSITYREGISTRATION_WRAP_PYTHON)

#
# Create the vtkKullbackLeiblerRegistration Java library
#

IF (VTK_WRAP_JAVA AND VTKRIGIDINTENSITYREGISTRATION_WRAP_JAVA)

  VTK_WRAP_JAVA (vtkKullbackLeiblerRegistrationJava RigidIntensityRegistrationJava_SRCS LOCAL_MODULE_SRCS)
  ADD_LIBRARY (vtkKullbackLeiblerRegistrationJava SHARED RigidIntensityRegistrationJava_SRCS)
  TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationJava 
                         vtkIOJava
                         vtkGraphicsJava
                         vtkImagingJava 
                         vtkFilteringJava
                         vtkCommonJava)
  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationJava vtkHybridJava)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationJava vtkParallelJava)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationJava vtkPatentedJava)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkKullbackLeiblerRegistrationJava vtkRenderingJava)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_JAVA AND VTKRIGIDINTENSITYREGISTRATION_WRAP_JAVA)

#
# Link to VTK and local
#

LINK_LIBRARIES (
  vtkKullbackLeiblerRegistration
  vtkRigidIntensityRegistration
  vtkIO
  vtkGraphics
  vtkImaging 
  vtkFiltering
  vtkCommon
)

IF (VTK_USE_HYBRID)
  LINK_LIBRARIES (vtkHybrid)
ENDIF (VTK_USE_HYBRID)

IF (VTK_USE_PARALLEL)
  LINK_LIBRARIES (vtkParallel)
ENDIF (VTK_USE_PARALLEL)

IF (VTK_USE_PATENTED)
  LINK_LIBRARIES (vtkPatented)
ENDIF (VTK_USE_PATENTED)

IF (VTK_USE_RENDERING)
  LINK_LIBRARIES (vtkRendering)
ENDIF (VTK_USE_RENDERING)
