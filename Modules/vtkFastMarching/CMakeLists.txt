#
# Set the project name.
#

# MY -> FASTMARCHING
# my -> FastMarching


PROJECT (VTKFASTMARCHING)

#
# Assume everything is set up correctly for build.
#
# If some requirements are not met, set it to 0.
# In that case, the build won't be done.
#

SET (VTKFASTMARCHING_CAN_BUILD 1)

#
# Load CMake commands that you probably should not modify.
#

INCLUDE (${VTKFASTMARCHING_SOURCE_DIR}/CMakeOptions.cmake)

#
# If everything is OK, then go into the sub directories and build.
#

IF (VTKFASTMARCHING_CAN_BUILD)

  #
  # Here is where you can list the sub-directories holding your local 
  # classes. Sorting classes by 'package' type like VTK does (Common, 
  # Rendering, Filtering, Imaging, IO, etc.) is a good thing and prevents 
  # numerous dependencies problems.
  #

  SUBDIRS (
    cxx
  )

  #
  # You can put your include path(s) here
  #

  INCLUDE_DIRECTORIES (${VTKFASTMARCHING_SOURCE_DIR}/cxx)

  #
  # Build examples too ?
  #

#  OPTION(BUILD_EXAMPLES "Build examples." ON)
#  IF (BUILD_EXAMPLES)
#    SUBDIRS(Examples)
#  ENDIF (BUILD_EXAMPLES)


  #
  # Common configuration settings
  #
  # Do not worry about this one.
  #

  CONFIGURE_FILE(
    ${VTKFASTMARCHING_SOURCE_DIR}/vtkFastMarchingConfigure.h.cin 
    ${VTKFASTMARCHING_BINARY_DIR}/vtkFastMarchingConfigure.h
  )

  INCLUDE_DIRECTORIES(${VTKFASTMARCHING_BINARY_DIR})

ENDIF (VTKFASTMARCHING_CAN_BUILD)
