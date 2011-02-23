SET(TCL_TESTS
  TestBSplineInterpolateImageFunction
  )

FOREACH(tclfile ${TCL_TESTS})
  ADD_TEST("${MODULE_NAME}.${tclfile}" "${SLICER_EXECUTABLE}"
    --agree_to_license
    "${CTEST_SLICER_HOME}/Scripts/ImageRegressionTest.tcl"
    "${CMAKE_CURRENT_SOURCE_DIR}/${tclfile}.tcl"
    -D "${CMAKE_CURRENT_SOURCE_DIR}"
    -V Baseline/${tclfile}.png)
ENDFOREACH(tclfile)

