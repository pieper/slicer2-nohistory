# Define the tests
SET(TEST_SRCS
  TestInstance
  TestBSplineInterpolateImageFunction
  #TestTensorImplicitFunctionToFunctionSet
  TestImageGetTensorComponents
  TestSuperquadricSource2
  TestTensorFlip
  TestTensorMask
  TestTensorMathematics
  )

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

# Add the include paths
INCLUDE_DIRECTORIES(
  #${SANDBOX_SRC_DIR}/SlicerTractClusteringImplementation/Code
  #${SANDBOX_SRC_DIR}/SpectralClustering
  )

IF(DEBUG_POLY)
  INCLUDE_DIRECTORIES(
    ${VTKSLICERBASE_SOURCE_DIR}/cxx
    ${VTKSLICERBASE_BUILD_DIR}
    )
  SET(TEST_SRCS
    ${TEST_SRCS}
    TestPoly
    )
ENDIF(DEBUG_POLY)

LINK_DIRECTORIES(
  #${SANDBOX_BUILD_DIR}
  ${TEEM_BIN_DIR} # for the libair...
  )

# FIXME for some reason ITKNumerics is needed...
CREATE_TEST_SOURCELIST(TUTests vtkTensorUtilTests.cxx ${TEST_SRCS})
ADD_EXECUTABLE(vtkTensorUtilTests ${TUTests})
TARGET_LINK_LIBRARIES(vtkTensorUtilTests vtkTensorUtil)

# FIXME
SET(VTK_TENSOR_UTIL_TESTS "${EXECUTABLE_OUTPUT_PATH}/vtkTensorUtilTests")

# Loop over files and create executables
FOREACH(name ${TEST_SRCS})
  ADD_TEST("${MODULE_NAME}.${name}" ${VTK_TENSOR_UTIL_TESTS} ${name})
ENDFOREACH(name)


