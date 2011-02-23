FIND_PACKAGE(ITK)
IF(ITK_FOUND)
        INCLUDE(${ITK_USE_FILE})
ELSE(ITK_FOUND)
        MESSAGE(FATAL_ERROR "Could not find ITK")
ENDIF(ITK_FOUND)

FIND_PACKAGE(VTK)
IF(VTK_FOUND)
        INCLUDE(${VTK_USE_FILE})
ELSE(VTK_FOUND)
        MESSAGE(FATAL_ERROR "Could not find VTK")
ENDIF(VTK_FOUND)

INCLUDE_DIRECTORIES( 
   ${SANDBOX_SRC_DIR}/SlicerTractClusteringImplementation/Code 
   ${SANDBOX_SRC_DIR}/SpectralClustering
)

LINK_DIRECTORIES( 
   ${SANDBOX_BUILD_DIR}
   ${TEEM_BIN_DIR}
)

FOREACH(test testCluster)
  ADD_EXECUTABLE("${MODULE_NAME}.${test}" "${test}.cxx")
  TARGET_LINK_LIBRARIES(${MODULE_NAME}.${test} 
                        vtkDTMRI 
                        ITKNumerics 
                        ten
                        vtkDTMRITCL 
                        vtkIOTCL 
                        vtkGraphicsTCL 
                        vtkImagingTCL 
                        vtkFilteringTCL 
                        vtkCommonTCL
                        ${TCL_LIBRARY}
    )
  ADD_TEST("${MODULE_NAME}.${test}"
    "${SLICER_EXECUTABLE}" --agree_to_license
    "${CTEST_SLICER_HOME}/Scripts/runCxxTest.tcl"
    "${EXECUTABLE_OUTPUT_PATH}/${MODULE_NAME}.${test}")
ENDFOREACH(test)




