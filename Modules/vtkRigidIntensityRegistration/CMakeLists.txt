#
# Set the project name.
#

# MY -> RIGIDINTENSITYREGISTRATION
# my -> RigidIntensityRegistration


PROJECT (VTKRIGIDINTENSITYREGISTRATION)

#
# Assume everything is set up correctly for build.
#
# If some requirements are not met, set it to 0.
# In that case, the build won't be done.
#



#EXEC_PROGRAM(gcc-3.0 ARGS --version OUTPUT_VARIABLE CMAKE_C_COMPILER_VERSION)
#IF(CMAKE_C_COMPILER_VERSION MATCHES ".*3\\.[0-9].*")
#MESSAGE("gcc 3.x")
#ELSE(CMAKE_C_COMPILER_VERSION MATCHES ".*3\\.[0-9].*")
#MESSAGE("gcc not 3.x")
#ENDIF(CMAKE_C_COMPILER_VERSION MATCHES ".*3\\.[0-9].*")



SET (VTKRIGIDINTENSITYREGISTRATION_CAN_BUILD 1)

#
# Load CMake commands that you probably should not modify.
#

INCLUDE (${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/CMakeOptions.cmake)

#
# find the slicer version - you can either set default here, or 
# configure them with CMakeSetup/ccmake/cmake as you wish.
# If you use the cmaker.tcl script in slicer2/Scripts these
# will be filled in automatically with the correct values.
# These are used is your module relies on code in slicerbase.
#
# e.g. c:/pieper/bwh/slicer2/latest/slicer2/Base
SET (VTKSLICERBASE_SOURCE_DIR CACHE PATH
    "should end with slicer2/Base"
)
# e.g. c:/pieper/bwh/slicer2/latest/slicer2/Base/builds/Win32VC7 CACHE PATH
SET (VTKSLICERBASE_BUILD_DIR CACHE PATH
    "should end with slicer2/Base/builds/xxx where xxx is the same build name you are making here"
)
# e.g. c:/pieper/bwh/slicer2/latest/slicer2/Base/builds/Win32VC7/bin/debug/vtkSlicerBase.lib CACHE PATH
SET (VTKSLICERBASE_BUILD_LIB CACHE PATH
    "name of the vtkSlicerBase lib file (.lib or .a)"
)


#
# If everything is OK, then go into the sub directories and build.
#

IF (VTKRIGIDINTENSITYREGISTRATION_CAN_BUILD)

  #
  # Here is where you can list the sub-directories holding your local 
  # classes. Sorting classes by 'package' type like VTK does (Common, 
  # Rendering, Filtering, Imaging, IO, etc.) is a good thing and prevents 
  # numerous dependencies problems.
  #

  SUBDIRS(cxx)
  # commented out and everything is now in one library.
  #SUBDIRS(KullbackLeibler)
  #SUBDIRS(MutualInformation)

  CONFIGURE_FILE(${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/test/tcl/TestBase.tcl.in
                 ${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/test/tcl/TestBase.tcl
                 IMMEDIATE)

  #
  # You can put your include path(s) here
  #

  INCLUDE_DIRECTORIES (${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/cxx)

  #
  # Build examples too ?
  #

  OPTION(BUILD_EXAMPLES "Build examples." ON)
  IF (BUILD_EXAMPLES)
    #SUBDIRS(test/cxx)
  ENDIF (BUILD_EXAMPLES)

  #
  # Common configuration settings
  #
  # Do not worry about this one.
  #

  CONFIGURE_FILE(
    ${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/vtkRigidIntensityRegistrationConfigure.h.cin 
    ${VTKRIGIDINTENSITYREGISTRATION_BINARY_DIR}/vtkRigidIntensityRegistrationConfigure.h
  )

  INCLUDE_DIRECTORIES(
    ${VTKRIGIDINTENSITYREGISTRATION_BINARY_DIR}
    ${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/../vtkITK/cxx
    ${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/MutualInformation
    ${VTKRIGIDINTENSITYREGISTRATION_SOURCE_DIR}/KullbackLeibler
  )

ENDIF (VTKRIGIDINTENSITYREGISTRATION_CAN_BUILD)
