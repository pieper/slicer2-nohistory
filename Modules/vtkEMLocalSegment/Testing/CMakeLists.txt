FILE(GLOB_RECURSE tclfiles "${CMAKE_CURRENT_SOURCE_DIR}/Tcl/*.tcl")
FOREACH(tclfile ${tclfiles})
  STRING(REGEX REPLACE ".*/" "" testname "${tclfile}")
  STRING(REGEX REPLACE ".*\\\\" "" testname "${testname}")
  ADD_TEST("${MODULE_NAME}.${testname}" "${SLICER_EXECUTABLE}"
    --batch
    "${tclfile}")
ENDFOREACH(tclfile)

