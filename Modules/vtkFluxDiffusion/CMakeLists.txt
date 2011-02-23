#
# Set the project name.
#

# MY -> FLUXDIFFUSION
# my -> FluxDiffusion


PROJECT (VTKFLUXDIFFUSION)

#
# Assume everything is set up correctly for build.
#
# If some requirements are not met, set it to 0.
# In that case, the build won't be done.
#

SET (VTKFLUXDIFFUSION_CAN_BUILD 1)

#
# Load CMake commands that you probably should not modify.
#

INCLUDE (${VTKFLUXDIFFUSION_SOURCE_DIR}/CMakeOptions.cmake)

#
# If everything is OK, then go into the sub directories and build.
#

IF (VTKFLUXDIFFUSION_CAN_BUILD)

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

  INCLUDE_DIRECTORIES (${VTKFLUXDIFFUSION_SOURCE_DIR}/cxx)

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
    ${VTKFLUXDIFFUSION_SOURCE_DIR}/vtkFluxDiffusionConfigure.h.cin 
    ${VTKFLUXDIFFUSION_BINARY_DIR}/vtkFluxDiffusionConfigure.h
  )

  INCLUDE_DIRECTORIES(${VTKFLUXDIFFUSION_BINARY_DIR})

ENDIF (VTKFLUXDIFFUSION_CAN_BUILD)
