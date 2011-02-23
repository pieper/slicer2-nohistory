
#
# Slicer loadable vtk project for vtk4
# - adapted from the vtkMy example
#
# - sp 2002-04-19
# - updated based on slicer developer feedback with
# help from MH.  2002-05-02
# 
#

PROJECT (VTKSLICER)

# If some requirements are not met, set it to 0.
# In that case, the build won't be done.
#
OPTION(VTKSLICER_CAN_BUILD "Build slicer: turn off for dashboard manager" ON)

#
# If everything is OK, then go into the sub directories and build.
#

IF (VTKSLICER_CAN_BUILD)

# MH+KH - moved this line into the "CAN_BUILD" IF so that dashboard work
INCLUDE (${VTKSLICER_SOURCE_DIR}/CMakeOptions.cmake)

  #
  # Here is where you can list the sub-directories holding your local 
  # classes. Sorting classes by 'package' type like VTK does (Common, 
  # Rendering, Filtering, Imaging, IO, etc.) is a good thing and prevents 
  # numerous dependencies problems.
  #

  SUBDIRS (
    # sp - put everything in cxx for now
    cxx
  )

  #
  # You can put your include path(s) here
  #

  INCLUDE_DIRECTORIES (${VTKSLICER_SOURCE_DIR}/cxx)

  #
  # Common configuration settings
  #
  # Do not worry about this one.
  #

  CONFIGURE_FILE(
    ${VTKSLICER_SOURCE_DIR}/vtkSlicerConfigure.h.in 
    ${VTKSLICER_BINARY_DIR}/vtkSlicerConfigure.h
  )

  INCLUDE_DIRECTORIES(${VTKSLICER_BINARY_DIR})

# include a test for endianness (used to be done by default)
INCLUDE (${CMAKE_ROOT}/Modules/TestBigEndian.cmake)
TEST_BIG_ENDIAN(CMAKE_WORDS_BIGENDIAN)

ENDIF (VTKSLICER_CAN_BUILD)

SET(SLICER_EXECUTABLE "" CACHE STRING "Path to Slicer executable")

# Include the standard Dart testing module
INCLUDE (Dart)

ENABLE_TESTING()
SUBDIRS(Testing)

## Add a test to open each xml file in the TestData directory, then
## close it.  Test will fail after timeout specified in
## DartConfiguration.tcl

# Pick up xml files to test
#FILE(GLOB_RECURSE xmlfiles "${CTEST_SLICER_HOME}/Testing/TestData/*.xml")

# Pick up tcl files to test
#FILE(GLOB_RECURSE tclfiles "${CTEST_SLICER_HOME}/Modules/vtkDTMRI/Testing/Tcl/*.tcl")

# For debugging purposes
#MESSAGE("${xmlfiles}")
#MESSAGE("${tclfiles}")
#MESSAGE("${testname}")
#MESSAGE(" path is: [${CTEST_SLICER_HOME}/Testing/TestData/*.xml]")
#MESSAGE(" executable is: [${SLICER_EXECUTABLE}")
#ADD_TEST("slicer${testname}" "${SLICER_EXECUTABLE}" --agree_to_license --no-tkcon "${xmlfile}" --exec exit)

# Try to open each xml file
FOREACH(xmlfile ${xmlfiles}) 
STRING(REGEX REPLACE "/" "_" testname "${xmlfile}")
ADD_TEST("slicer-vnc${testname}" "${CTEST_SLICER_HOME}/Scripts/runvnc" "--Xvnc" "${CTEST_XVNC_EXECUTABLE}" "-d" "44" "--not-secure" "--" "${SLICER_EXECUTABLE}" "--batch" "${xmlfile}" --exec exit)
ENDFOREACH(xmlfile)

#FOREACH(tclfile ${tclfiles})
#STRING(REGEX REPLACE "/" "_" dtmritestname "${tclfile}")
#ADD_TEST("slicer-${dtmritestname}" "${SLICER_EXECUTABLE}" --agree_to_license --no-tkcon --script ${tclfile} --exec exit)
#ENDFOREACH(tclfile)

ADD_TEST("TestSlicerBase" "${SLICER_EXECUTABLE}" --agree_to_license --no-tkcon --script ${CTEST_SLICER_HOME}/Base/Testing/testSlicerBase.tcl --exec exit)

ADD_TEST("slicer-tarup" "${SLICER_EXECUTABLE}" "--agree_to_license" "--exec" "source" "${CTEST_SLICER_HOME}/Scripts/tarup.tcl" ".," "tarup" "nightly" ".," "exit")

# Setup Find/Use slicer
SET(SLICERBASE_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
SET(SLICERBASE_USE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/SlicerBaseUse.cmake")
SET(SLICERBASE_INCLUDE_DIRS "${CMAKE_CURRENT_BINARY_DIR};${CMAKE_CURRENT_SOURCE_DIR}/cxx;${CMAKE_CURRENT_BINARY_DIR}/cxx")
SET(SLICERBASE_LIBRARY_DIRS "${LIBRARY_OUTPUT_PATH}")
SET(SLICERBASE_LIBRARY_DEPENDS_FILE "${CMAKE_CURRENT_BINARY_DIR}/SlicerBaseLibraryDepends.cmake")
EXPORT_LIBRARY_DEPENDENCIES(${CMAKE_CURRENT_BINARY_DIR}/SlicerBaseLibraryDepends.cmake)
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/SlicerBaseConfig.cmake.in
               ${CMAKE_CURRENT_BINARY_DIR}/SlicerBaseConfig.cmake @ONLY IMMEDIATE)


