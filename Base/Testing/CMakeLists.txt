# Test
SET(TESTS_BASE_SRCS
  testSlicerBase
  TestPlot
  TestImageCCA
  #TestPolyBoolean
  )

FOREACH(test ${TESTS_BASE_SRCS})
  ADD_TEST("SLICERBASE.${test}" "${CTEST_SLICER_HOME}/Scripts/runvnc" "--Xvnc"
  "${CTEST_XVNC_EXECUTABLE}" "-d" "44" "--"
  "${SLICER_EXECUTABLE}" "--batch"
  "${CTEST_SLICER_HOME}/Scripts/ImageRegressionTest.tcl"
  "${CTEST_SLICER_HOME}/Base/Testing/${test}.tcl"
  "-D" "${CMAKE_CURRENT_SOURCE_DIR}"
  "-V" "Baseline/${test}.png")
  SET_TESTS_PROPERTIES("SLICERBASE.${test}" PROPERTIES FAIL_REGULAR_EXPRESSION "ERROR;FAIL;Test failed")
  SET_TESTS_PROPERTIES("SLICERBASE.${test}" PROPERTIES PASS_REGULAR_EXPRESSION "Test passed")
ENDFOREACH(test)

SET(TCL_TESTS   
  TestMaskStat
  TestMeasureVol
  testDataProvenance
   )                    

FOREACH(tclfile ${TCL_TESTS})
  ADD_TEST("SLICERBASE.${tclfile}" "${CTEST_SLICER_HOME}/Scripts/runvnc" "--Xvnc"
  "${CTEST_XVNC_EXECUTABLE}" "-d" "44" "--"
  "${SLICER_EXECUTABLE}" "--batch"
  "${CTEST_SLICER_HOME}/Scripts/ImageRegressionTest.tcl"
  "${CTEST_SLICER_HOME}/Base/Testing/${tclfile}.tcl"     
  "-D" "${CMAKE_CURRENT_SOURCE_DIR}")
  SET_TESTS_PROPERTIES("SLICERBASE.${tclfile}" PROPERTIES FAIL_REGULAR_EXPRESSION "ERROR;FAIL;Test failed")
  SET_TESTS_PROPERTIES("SLICERBASE.${tclfile}" PROPERTIES PASS_REGULAR_EXPRESSION "Test passed")
ENDFOREACH(tclfile)
