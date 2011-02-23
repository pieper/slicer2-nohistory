#
# Set the project name.
#

# MY -> FREESURFERREADERS
# my -> FreeSurferReaders

SET(MODULE_NAME VTKFREESURFERREADERS)

PROJECT (VTKFREESURFERREADERS)

#
# Assume everything is set up correctly for build.
#
# If some requirements are not met, set it to 0.
# In that case, the build won't be done.
#

SET (VTKFREESURFERREADERS_CAN_BUILD 1)
ENABLE_TESTING()

#
# Load CMake commands that you probably should not modify.
#

INCLUDE (${VTKFREESURFERREADERS_SOURCE_DIR}/CMakeOptions.cmake)

#
# If everything is OK, then go into the sub directories and build.
#

IF (VTKFREESURFERREADERS_CAN_BUILD)

  #
  # Here is where you can list the sub-directories holding your local 
  # classes. Sorting classes by 'package' type like VTK does (Common, 
  # Rendering, Filtering, Imaging, IO, etc.) is a good thing and prevents 
  # numerous dependencies problems.
  #

  SUBDIRS (
    cxx
    Testing
  )

  #
  # You can put your include path(s) here
  #

  INCLUDE_DIRECTORIES (${VTKFREESURFERREADERS_SOURCE_DIR}/cxx)

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
    ${VTKFREESURFERREADERS_SOURCE_DIR}/vtkFreeSurferReadersConfigure.h.cin 
    ${VTKFREESURFERREADERS_BINARY_DIR}/vtkFreeSurferReadersConfigure.h
  )

  INCLUDE_DIRECTORIES(${VTKFREESURFERREADERS_BINARY_DIR})

ENDIF (VTKFREESURFERREADERS_CAN_BUILD)
