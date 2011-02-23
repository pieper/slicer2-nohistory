/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIbrowserTCLInit.cxx,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkTclUtil.h"
#include "vtkVersion.h"
#define VTK_TCL_TO_STRING(x) VTK_TCL_TO_STRING0(x)
#define VTK_TCL_TO_STRING0(x) #x
extern "C"
{
#if (TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION >= 4) && (TCL_RELEASE_LEVEL >= TCL_FINAL_RELEASE)
  typedef int (*vtkTclCommandType)(ClientData, Tcl_Interp *,int, CONST84 char *[]);
#else
  typedef int (*vtkTclCommandType)(ClientData, Tcl_Interp *,int, char *[]);
#endif
}

int vtkBVolReaderCommand(ClientData cd, Tcl_Interp *interp,
             int argc, char *argv[]);
ClientData vtkBVolReaderNewCommand();
int vtkIbrowserIOCommand(ClientData cd, Tcl_Interp *interp,
             int argc, char *argv[]);
ClientData vtkIbrowserIONewCommand();

extern Tcl_HashTable vtkInstanceLookup;
extern Tcl_HashTable vtkPointerLookup;
extern Tcl_HashTable vtkCommandLookup;
extern void vtkTclDeleteObjectFromHash(void *);
extern void vtkTclListInstances(Tcl_Interp *interp, ClientData arg);


extern "C" {int VTK_EXPORT Vtkibrowsertcl_SafeInit(Tcl_Interp *interp);}

extern "C" {int VTK_EXPORT Vtkibrowsertcl_Init(Tcl_Interp *interp);}

extern void vtkTclGenericDeleteObject(ClientData cd);


int VTK_EXPORT Vtkibrowsertcl_SafeInit(Tcl_Interp *interp)
{
  return Vtkibrowsertcl_Init(interp);
}


int VTK_EXPORT Vtkibrowsertcl_Init(Tcl_Interp *interp)
{

  vtkTclCreateNew(interp,(char *) "vtkBVolReader", vtkBVolReaderNewCommand,
                  vtkBVolReaderCommand);
  vtkTclCreateNew(interp,(char *) "vtkIbrowserIO", vtkIbrowserIONewCommand,
                  vtkIbrowserIOCommand);
  char pkgName[]="vtkIbrowserTCL";
  char pkgVers[]=VTK_TCL_TO_STRING(VTK_MAJOR_VERSION) "." VTK_TCL_TO_STRING(VTK_MINOR_VERSION);
  Tcl_PkgProvide(interp, pkgName, pkgVers);
  return TCL_OK;
}
