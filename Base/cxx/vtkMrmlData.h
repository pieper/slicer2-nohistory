/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlData.h,v $
  Date:      $Date: 2006/03/06 19:02:26 $
  Version:   $Revision: 1.17 $

=========================================================================auto=*/
// .NAME vtkMrmlData - Abstract Object used in the slicer to perform
// everything related to the access and display of data.
// .SECTION Description
// Used in conjunction with a vtkMrmlNode (which neatly describes
// display settings, file locations, etc.).  Essentially, the MRML 
// node gives the high level description of what this class should 
// actually do with the data
// 

// NEED TO:
// make vtkMrmlNode.h:: Copy constructor to be virtual.
//                   :: Destructor needs to be virtual.
// 
// GetMTime to be virtual

#ifndef __vtkMrmlData_h
#define __vtkMrmlData_h

//#include <fstream.h>
#include <stdlib.h>
//#include <iostream.h>

#include "vtkProcessObject.h"
#include "vtkIndirectLookupTable.h"
#include "vtkMrmlNode.h"
#include "vtkLookupTable.h"
#include "vtkImageData.h"
#include "vtkSlicer.h"

class vtkCallbackCommand;

//----------------------------------------------------------------------------
class VTK_SLICER_BASE_EXPORT vtkMrmlData : public vtkProcessObject {
  public:
    static vtkMrmlData *New();

  vtkTypeMacro(vtkMrmlData,vtkProcessObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // 
  // Dealing With Mrml Data
  //

  // Description:
  // Set/Get the MRML info
  vtkSetObjectMacro(MrmlNode, vtkMrmlNode);
  vtkGetObjectMacro(MrmlNode, vtkMrmlNode);
  
  // Description:
  // Copy another MmrlData's MrmlNode to this one
  // This does not need to be virtual 
  void CopyNode(vtkMrmlData *Data);

  //
  // Making sure the filters are UpToDate
  //

  // Description:
  // Provides opportunity to insure internal consistency before access.
  // Transfers all ivars from MrmlNode to internal VTK objects
  //
  // All subclasses MUST call vtkMRMLData::Update and vtkMRMLData::GetMTime
  virtual void Update();
  virtual unsigned long int GetMTime();
//  virtual vtkObject* GetOutput();
  vtkDataObject *GetOutput();

  //
  // Read/Write filters
  //

  // Description:
  // Read/Write the data
  // Return 1 on success, 0 on failure.
  virtual int Read() = 0;
  virtual int Write() = 0;

  // Description:
  // Has the object been changed in a way that one would want to write
  // it to disk? (to replace IsDirty...)
  vtkSetMacro(NeedToWrite, int);
  vtkGetMacro(NeedToWrite, int);
  vtkBooleanMacro(NeedToWrite, int);

  //
  // Display functions
  //

  // Description:
  // Get the indirect LUT (LookupTable).
  // If UseLabelLUT is on, then returns the LabelLUT, otherwise
  // the volume's own IndirectLookupTable.
  vtkIndirectLookupTable *GetIndirectLUT();

  // Description:
  // Set Label IndirectLookupTable
  vtkGetMacro(UseLabelIndirectLUT, int);
  vtkSetMacro(UseLabelIndirectLUT, int);
  vtkBooleanMacro(UseLabelIndirectLUT, int);
  vtkSetObjectMacro(LabelIndirectLUT, vtkIndirectLookupTable);
  vtkGetObjectMacro(LabelIndirectLUT, vtkIndirectLookupTable);

  // Description:
  // Set LookupTable
  void SetLookupTable(vtkLookupTable *lut) {
      this->IndirectLUT->SetLookupTable(lut);};
  vtkLookupTable *GetLookupTable() {
    return this->IndirectLUT->GetLookupTable();};

  // Description:
  // For internal use during Read/Write
//BTX
#if (VTK_MAJOR_VERSION >= 5)
  vtkGetObjectMacro(ProcessObject, vtkAlgorithm);
#else
  vtkGetObjectMacro(ProcessObject, vtkProcessObject);
#endif
//ETX

  // Description:
  // Enable or disable FMRI mapping 
  void EnableFMRIMapping(int yes) {
      this->IndirectLUT->SetFMRIMapping(yes);};


protected:
  vtkMrmlData();
  // The virtual descructor is critical!!
  virtual ~vtkMrmlData();

  vtkMrmlData(const vtkMrmlData&);
  void operator=(const vtkMrmlData&);


  // Description: 
  // MUST be implemented by lower functions
  // If MrmlNode is None, create it.
  virtual void CheckMrmlNode();

  vtkMrmlNode *MrmlNode;
  void CheckLabelIndirectLUT();

  int UseLabelIndirectLUT;
  vtkIndirectLookupTable *IndirectLUT;
  vtkIndirectLookupTable *LabelIndirectLUT;

  int NeedToWrite;
#if (VTK_MAJOR_VERSION >= 5)
  vtkAlgorithm *ProcessObject;
#else
  vtkProcessObject *ProcessObject;
#endif
  
  // Callback registered with the ProgressObserver.
  static void ProgressCallbackFunction(vtkObject*, unsigned long, void*,
                                       void*);
  // The observer to report progress from the internal writer.
  vtkCallbackCommand* ProgressObserver;  
};

#endif
