#
# Set the project name.
#

# MY -> VOLUMETEXTUREMAPPING
# my -> VolumeTextureMapping


PROJECT (VTKVOLUMETEXTUREMAPPING)


#
# Load CMake commands that you probably should not modify.
#

INCLUDE (${VTKVOLUMETEXTUREMAPPING_SOURCE_DIR}/CMakeOptions.cmake)

#
# Assume everything is set up correctly for build.
#
# If some requirements are not met, set it to 0.
# In that case, the build won't be done.
#

IF("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" GREATER 4.9)
  # If using VTK 5.0 and above do not built this module
  SET (VTKVOLUMETEXTUREMAPPING_CAN_BUILD 0)
ELSE("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" GREATER 4.9)
  SET (VTKVOLUMETEXTUREMAPPING_CAN_BUILD 1)
ENDIF("${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}" GREATER 4.9)


#
# If everything is OK, then go into the sub directories and build.
#

IF (VTKVOLUMETEXTUREMAPPING_CAN_BUILD)

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

  INCLUDE_DIRECTORIES (${VTKVOLUMETEXTUREMAPPING_SOURCE_DIR}/cxx)

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
    ${VTKVOLUMETEXTUREMAPPING_SOURCE_DIR}/vtkVolumeTextureMappingConfigure.h.cin 
    ${VTKVOLUMETEXTUREMAPPING_BINARY_DIR}/vtkVolumeTextureMappingConfigure.h
  )

  INCLUDE_DIRECTORIES(${VTKVOLUMETEXTUREMAPPING_BINARY_DIR})

ENDIF (VTKVOLUMETEXTUREMAPPING_CAN_BUILD)
