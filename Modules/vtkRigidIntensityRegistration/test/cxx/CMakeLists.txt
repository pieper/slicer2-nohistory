SET (LOCAL_LIBRARY_BASENAME vtkRigidIntensityRegistration)

INCLUDE (${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/test/cxx/CMakeListsLocal.txt)

# --------------------------------------------------------------------------
# You probably do not need to modify anything below this line

#
# Create the vtkMutualInformationRegistration C++ library
#
# (Doesn't work here because of a CMake bug)
# ADD_LIBRARY (vtkMutualInformationRegistration LOCAL_MODULE_SRCS)

#
# Create the vtkMutualInformationRegistration Tcl library
#

#IF (VTK_WRAP_TCL AND VTKRIGIDREGISTRATIONREGISTRATION_WRAP_TCL)
#
#  VTK_WRAP_TCL (vtkMutualInformationRegistrationTCL MutualInformationRegistrationTCL_SRCS LOCAL_MODULE_SRCS)
#  ADD_LIBRARY (vtkMutualInformationRegistrationTCL MutualInformationRegistrationTCL_SRCS)

LINK_LIBRARIES (
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
