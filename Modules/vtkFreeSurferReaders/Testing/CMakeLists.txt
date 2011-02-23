FILE(GLOB_RECURSE tclfiles "${CMAKE_CURRENT_SOURCE_DIR}/Tcl/*.tcl")
FOREACH(tclfile ${tclfiles})
  STRING(REGEX REPLACE ".*/" "" fsrtestname "${tclfile}")
  STRING(REGEX REPLACE ".*\\\\" "" fsrtestname "${fsrtestname}")
  ADD_TEST("${MODULE_NAME}.${fsrtestname}" "${SLICER_EXECUTABLE}"
    --batch
    "${CTEST_SLICER_HOME}/Scripts/ImageRegressionTest.tcl"
    "${tclfile}"
    -D "${CMAKE_CURRENT_SOURCE_DIR}"
    -V Baseline/${fsrtestname}.png)
ENDFOREACH(tclfile)

