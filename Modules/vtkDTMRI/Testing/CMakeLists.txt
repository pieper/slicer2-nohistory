FILE(GLOB_RECURSE tclfiles "${CMAKE_CURRENT_SOURCE_DIR}/Tcl/*.tcl")
FOREACH(tclfile ${tclfiles})
  STRING(REGEX REPLACE ".*/" "" dtmritestname "${tclfile}")
  STRING(REGEX REPLACE ".*\\\\" "" dtmritestname "${dtmritestname}")
  ADD_TEST("${MODULE_NAME}.${dtmritestname}" "${SLICER_EXECUTABLE}"
    --batch
    "${CTEST_SLICER_HOME}/Scripts/ImageRegressionTest.tcl"
    "${tclfile}"
    -D "${CMAKE_CURRENT_SOURCE_DIR}"
    -V Baseline/${dtmritestname}.png)
ENDFOREACH(tclfile)

SUBDIRS (
  Cxx
  )
