IF(WIN32)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/AllowContinuous.bat.in 
               ${VTKSLICER_BINARY_DIR}/AllowContinuous.bat)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/AllowContinuous.bat.in 
               ${VTKSLICER_BINARY_DIR}/AllowContinuous.bat)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/PreventContinuous.bat.in 
               ${VTKSLICER_BINARY_DIR}/PreventContinuous.bat)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/BuildContinuous.bat.in 
               ${VTKSLICER_BINARY_DIR}/BuildContinuous.bat)
ENDIF(WIN32)
IF(UNIX)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/BuildContinuous.sh.in 
               ${VTKSLICER_BINARY_DIR}/BuildContinuous.sh
               @ONLY IMMEDIATE)
EXEC_PROGRAM(chmod ARGS 755 ${VTKSLICER_BINARY_DIR}/BuildContinuous.sh)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/AllowContinuous.sh.in 
               ${VTKSLICER_BINARY_DIR}/AllowContinuous.sh
               @ONLY IMMEDIATE)
EXEC_PROGRAM(chmod ARGS 755 ${VTKSLICER_BINARY_DIR}/AllowContinuous.sh)
CONFIGURE_FILE(${VTKSLICER_SOURCE_DIR}/Testing/PreventContinuous.sh.in 
               ${VTKSLICER_BINARY_DIR}/PreventContinuous.sh
               @ONLY IMMEDIATE)
EXEC_PROGRAM(chmod ARGS 755 ${VTKSLICER_BINARY_DIR}/PreventContinuous.sh)
ENDIF(UNIX)