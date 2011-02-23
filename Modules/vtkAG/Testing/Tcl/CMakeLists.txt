SET(TCL_TESTS
  TestRigidRegistration   
   )

FOREACH(tclfile ${TCL_TESTS})
  ADD_TEST("VTKAG.${tclfile}"
  "${CTEST_SLICER_HOME}/Scripts/runvnc" "--Xvnc"
  "${CTEST_XVNC_EXECUTABLE}" "-d" "44" "--" 
  "${SLICER_EXECUTABLE}" "--batch"
  "${CTEST_SLICER_HOME}/Scripts/ImageRegressionTest.tcl" "${CMAKE_CURRENT_SOURCE_DIR}/${tclfile}.tcl"
   "-D" "${CMAKE_CURRENT_SOURCE_DIR}")
   SET_TESTS_PROPERTIES("VTKAG.${tclfile}" PROPERTIES FAIL_REGULAR_EXPRESSION "ERROR;FAIL;Test failed")
   SET_TESTS_PROPERTIES("VTKAG.${tclfile}" PROPERTIES PASS_REGULAR_EXPRESSION "Test passed")
ENDFOREACH(tclfile)