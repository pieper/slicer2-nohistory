/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlVolumeNode.cxx,v $
  Date:      $Date: 2006/03/06 19:02:27 $
  Version:   $Revision: 1.66 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlVolumeNode.h"
#include "vtkMath.h"
#include "vtkObjectFactory.h"

// Initialize static member that controls resampling -- 
  // old comment: "This offset will be changed to 0.5 from 0.0 per 2/8/2002 Slicer 
  // development meeting, to move ijk coordinates to voxel centers."
static float vtkMrmlVolumeNodeGlobalVoxelOffset = 0.5;


//------------------------------------------------------------------------------
vtkMrmlVolumeNode* vtkMrmlVolumeNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlVolumeNode");
  if(ret)
  {
    return (vtkMrmlVolumeNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlVolumeNode;
}

//----------------------------------------------------------------------------
vtkMrmlVolumeNode::vtkMrmlVolumeNode()
{
  // Strings
  this->VolumeID = NULL;
  this->FilePattern = NULL;
  this->FilePrefix = NULL;
  this->FileType = NULL;
  this->RasToIjkMatrix = NULL;
  this->RasToVtkMatrix = NULL;
  this->PositionMatrix = NULL;
  this->LUTName = NULL;
  this->FullPrefix = NULL;
  this->ScanOrder = NULL;

  // Numbers
  this->ScalarType = VTK_SHORT;
  this->NumScalars = 1;
  this->LabelMap = 0;
  this->Interpolate = 1;
  this->LittleEndian = 0;
  this->Tilt = 0.0;
  this->AutoWindowLevel = 1;
  this->Window = 256;
  this->Level = 128;
  this->AutoThreshold = 0;
  this->ApplyThreshold = 0;
  this->LowerThreshold = VTK_SHORT_MIN;
  this->UpperThreshold = VTK_SHORT_MAX;
  this->UseRasToVtkMatrix = 1;

  // odonnell.  Fixes for diffusion tensor image data
  this->FrequencyPhaseSwap = 0;

  // Arrays
  memset(this->ImageRange,0,2*sizeof(int));
  memset(this->Dimensions,0,2*sizeof(int));
  memset(this->Spacing,0,3*sizeof(vtkFloatingPointType));

  // ScanOrder can never be NULL
  this->ScanOrder = new char[3];
  strcpy(this->ScanOrder, "LR");

  // Matrices
  this->WldToIjk = vtkMatrix4x4::New();
  this->RasToWld = vtkMatrix4x4::New();
  this->RasToIjk = vtkMatrix4x4::New();
  this->Position = vtkMatrix4x4::New();

  // Initialize 
  this->SetImageRange(1, 1);
  this->SetDimensions(256, 256);
  this->SetSpacing(0.9375, 0.9375, 1.5);
  this->ComputeRasToIjkFromScanOrder(this->ScanOrder);

  // Added by Attila Tanacs 10/10/2000 1/4/02

  // DICOMFileNames
  this->DICOMFiles = 0;
  this->DICOMFileList = new char *[DICOM_FILE_LIMIT];
  for(int i=0; i<DICOM_FILE_LIMIT; i++)
    DICOMFileList[i] = NULL;

  this->DICOMMultiFrameOffsets = 0;
  this->DICOMMultiFrameOffsetList = new int [DICOM_FILE_LIMIT];

  //AddDICOMFileName("first.dcm");
  //AddDICOMFileName("second.dcm");
  
  // Ends

  // odonnell, 07/2002
  // this->ReadWriteNode = vtkMrmlVolumeReadWriteNode::New();
  // this should be set by tcl code when user indicates volume type
  this->ReadWriteNode = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlVolumeNode::~vtkMrmlVolumeNode()
{
  this->WldToIjk->Delete();
  this->RasToWld->Delete();
  this->RasToIjk->Delete();
  this->Position->Delete();

  if (this->VolumeID)
  {
    delete [] this->VolumeID;
    this->VolumeID = NULL;
  }
  if (this->FilePattern)
  {
    delete [] this->FilePattern;
    this->FilePattern = NULL;
  }
  if (this->FilePrefix)
  {
    delete [] this->FilePrefix;
    this->FilePrefix = NULL;
  }
  if (this->FileType)
  {
    delete [] this->FileType;
    this->FileType = NULL;
  }
  if (this->RasToVtkMatrix)
  {
    delete [] this->RasToVtkMatrix;
    this->RasToVtkMatrix = NULL;
  }
  if (this->RasToIjkMatrix)
  {
    delete [] this->RasToIjkMatrix;
    this->RasToIjkMatrix = NULL;
  }
  if (this->PositionMatrix)
  {
    delete [] this->PositionMatrix;
    this->PositionMatrix = NULL;
  }
  if (this->LUTName)
  {
    delete [] this->LUTName;
    this->LUTName = NULL;
  }
  if (this->FullPrefix)
  {
    delete [] this->FullPrefix;
    this->FullPrefix = NULL;
  }
  if (this->ScanOrder)
  {
    delete [] this->ScanOrder;
    this->ScanOrder = NULL;
  }

  // Added by Attila Tanacs 10/10/2000 1/4/02

  for(int i=0; i<DICOM_FILE_LIMIT; i++)
    delete [] DICOMFileList[i];

  delete [] DICOMMultiFrameOffsetList;
  // End
}


// control static variable for all volumes
void vtkMrmlVolumeNode::SetGlobalVoxelOffset(float offset)
{
  vtkMrmlVolumeNodeGlobalVoxelOffset = offset;
}

float vtkMrmlVolumeNode::GetGlobalVoxelOffset()
{
  return vtkMrmlVolumeNodeGlobalVoxelOffset;
}

//----------------------------------------------------------------------------
const char* vtkMrmlVolumeNode::GetScalarTypeAsString()
{
  switch (this->ScalarType)
  {
  case VTK_VOID:           return "Void"; break;
  case VTK_BIT:            return "Bit"; break;
  case VTK_CHAR:           return "Char"; break;
  case VTK_UNSIGNED_CHAR:  return "UnsignedChar"; break;
  case VTK_SHORT:          return "Short"; break;
  case VTK_UNSIGNED_SHORT: return "UnsignedShort"; break;
  case VTK_INT:            return "Int"; break;
  case VTK_UNSIGNED_INT:   return "UnsignedInt"; break;
  case VTK_LONG:           return "Long"; break;
  case VTK_UNSIGNED_LONG:  return "UnsignedLong"; break;
  case VTK_FLOAT:          return "Float"; break;
  case VTK_DOUBLE:         return "Double"; break;
  }
  return "Short";
}

//----------------------------------------------------------------------------
void vtkMrmlVolumeNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  // If the description is blank, set it to the scan order
  if (this->Description && (strcmp(this->Description, "") == 0))
  {
    delete [] this->Description;
    this->Description = NULL;
  }
  if (this->Description == NULL)
  {
    this->Description = new char[3];
    strcpy(this->Description, this->ScanOrder);
  }

  if (this->FilePattern == NULL)
  { this->FilePattern = new char[10];
    strcpy(this->FilePattern, "%s.%03d");
  }
  if (this->FullPrefix == NULL)
  { this->FullPrefix = new char[10];
    strcpy(this->FullPrefix, "");
  }
    

  char CheckVolumeFile[1000];
  if(this->GetNumberOfDICOMFiles() == 0)
  {
      CheckVolumeFile[0] = '\0';
      sprintf(CheckVolumeFile,this->FilePattern,this->FullPrefix,this->ImageRange[0]);
      vtkDebugMacro(<< "vtkMrmlVolumeNode: checking for existence of first volume file:\n " << CheckVolumeFile << "\n\tfile prefix = " << this->FilePrefix << "\n\tfull prefix = " << this->FullPrefix << endl);
      
      if ( *CheckVolumeFile == '\0' ) 
      {
          cerr << "No filename information for " << this->Name << endl;
          return;
      }

      FILE *file = fopen(CheckVolumeFile,"r"); 
      if ( file == NULL) {
          cerr << "Could not open \"" << CheckVolumeFile << "\"! "<< endl;
          cerr << "Volume node will not be saved. Might not have read access to the file !" << endl;
          return;
      }
      fclose(file);
  }
  else
  {
      sprintf(CheckVolumeFile,this->GetDICOMFileName(0));
      vtkDebugMacro(<<  "vtkMrmlVolumeNode:\n NOT checking for existence of first DICOM volume file:\n" << CheckVolumeFile);
  }
  vtkIndent i1(nIndent);
  of << i1 << "<Volume";

  // Strings
  if (this->VolumeID && strcmp(this->VolumeID,""))
  {
    of << " id='" << this->VolumeID << "'";
  }
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->FilePattern && strcmp(this->FilePattern, "")) 
  {
    of << " filePattern='" << this->FilePattern << "'";
  }
  if (this->FilePrefix && strcmp(this->FilePrefix, "")) 
  {
    of << " filePrefix='" << this->FilePrefix << "'";
  }
  if (this->FileType && strcmp(this->FileType, "")) 
  {
    of << " fileType='" << this->FileType << "'";
  }

  // >> AT 4/2/01

  if(this->GetNumberOfDICOMFiles() > 0)
  {
      of << " dicomFileNameList='";
      int i;
      int num = GetNumberOfDICOMFiles();
      for(i = 0; i < num; i++)
      {
          if(i > 0)
              of << " ";
          // check for a space in the file name, if there, enclose the
          // filename as an atom, otherwise print normally
          if (strstr(GetDICOMFileName(i), " ") != NULL)
          {
              of << "{" << GetDICOMFileName(i) << "}";
          }
          else
          {
              of << GetDICOMFileName(i);
          }
      }
      of << "'";
  }

  // << AT 4/2/01

  // >> AT 1/4/02

  if(this->GetNumberOfDICOMMultiFrameOffsets() > 0)
  {
      of << " dicomMultiFrameOffsetList='";
      int i;
      int num = GetNumberOfDICOMMultiFrameOffsets();
      for(i = 0; i < num; i++)
      {
          if(i > 0)
              of << " ";
          of << GetDICOMMultiFrameOffset(i);
      }
      of << "'";
  }

  // << AT 1/4/02

  if (this->RasToIjkMatrix && strcmp(this->RasToIjkMatrix, "")) 
  {
    of << " rasToIjkMatrix='" << this->RasToIjkMatrix << "'";
  }
  if (this->RasToVtkMatrix && strcmp(this->RasToVtkMatrix, "")) 
  {
    of << " rasToVtkMatrix='" << this->RasToVtkMatrix << "'";
  }
  if (this->PositionMatrix && strcmp(this->PositionMatrix, "")) 
  {
    of << " positionMatrix='" << this->PositionMatrix << "'";
  }
  if (this->ScanOrder && strcmp(this->ScanOrder, "LR")) 
  {
    of << " scanOrder='" << this->ScanOrder << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }
  if (this->LUTName && strcmp(this->LUTName, "")) 
  {
    of << " colorLUT='" << this->LUTName << "'";
  }
  if (this->FullPrefix && strcmp(this->FullPrefix, "")) 
  {
    of << " fullPrefix='" << this->FullPrefix << "'";
  }
  // Numbers
  const char *scalarType = this->GetScalarTypeAsString();
  if (strcmp(scalarType, "Short")) 
  {
    of << " scalarType='" << scalarType << "'";
  }
  if (this->NumScalars != 1)
  {
    of << " numScalars='" << this->NumScalars << "'";
  }
  if (this->LabelMap != 0)
  {
    of << " labelMap='" << (this->LabelMap ? "true" : "false") << "'";
  }
  if (this->Interpolate != 1)
  {
    of << " interpolate='" << (this->Interpolate ? "true" : "false") << "'";
  }
  if (this->LittleEndian != 0)
  {
    of << " littleEndian='" << (this->LittleEndian ? "true" : "false") << "'";
  }
  if (this->Tilt != 0.0)
  {
    of << " tilt='" << this->Tilt << "'";
  }
  if (this->AutoWindowLevel != 1)
  {
    of << " autoWindowLevel='" << (this->AutoWindowLevel ? "true" : "false") << "'";
  }
  if (this->Window != 256)
  {
    of << " window='" << this->Window << "'";
  }
  if (this->Level != 128)
  {
    of << " level='" << this->Level << "'";
  }
  if (this->AutoThreshold != 0)
  {
    of << " autoThreshold='" << (this->AutoThreshold ? "true" : "false") << "'";
  }
  if (this->ApplyThreshold != 0)
  {
    of << " applyThreshold='" << (this->ApplyThreshold ? "true" : "false") << "'";
  }
  if (this->LowerThreshold != VTK_SHORT_MIN)
  {
    of << " lowerThreshold='" << this->LowerThreshold << "'";
  }
  if (this->UpperThreshold != VTK_SHORT_MAX)
  {
    of << " upperThreshold='" << this->UpperThreshold << "'";
  }

  // Arrays
  if (this->ImageRange[0] != 1 || this->ImageRange[1] != 1)
  {
    of << " imageRange='" << this->ImageRange[0] << " "
       << this->ImageRange[1] << "'";
  }
  if (this->Dimensions[0] != 256 || this->Dimensions[1] != 256)
  {
    of << " dimensions='" << this->Dimensions[0] << " "
       << this->Dimensions[1] << "'";
  }
  if (this->Spacing[0] != 0.9375 || this->Spacing[1] != 0.9375 ||
      this->Spacing[2] != 1.5)
  {
    of << " spacing='" << this->Spacing[0] << " "
       << this->Spacing[1] << " " << this->Spacing[2] << "'";
  }

  // odonnell, diffusion tensor data
  // note this should be in a sub node!
  if (this->FrequencyPhaseSwap)
  {
    of << " frequencyPhaseSwap='true'";
  }  


  of << ">";

  // odonnell 07/2002 
  // Middle section for sub-nodes
  if (this->ReadWriteNode != NULL) 
    {
      this->ReadWriteNode->Write(of,nIndent);
    }

  //End
  of << "</Volume>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name, VolumeID
void vtkMrmlVolumeNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode *) anode;

  // Strings
  this->SetFilePattern(node->FilePattern);
  this->SetFileType(node->FileType);
  this->SetRasToIjkMatrix(node->RasToIjkMatrix);
  this->SetRasToVtkMatrix(node->RasToVtkMatrix);
  this->SetPositionMatrix(node->PositionMatrix);
  this->SetLUTName(node->LUTName);
  this->SetScanOrder(node->ScanOrder);

  // Vectors
  this->SetSpacing(node->Spacing);
  this->SetImageRange(node->ImageRange);
  this->SetDimensions(node->Dimensions);
  
  // Numbers
  this->SetTilt(node->Tilt);
    this->SetLabelMap(node->LabelMap);
    this->SetLittleEndian(node->LittleEndian);
    this->SetScalarType(node->ScalarType);
    this->SetNumScalars(node->NumScalars);
    this->SetAutoWindowLevel(node->AutoWindowLevel);
    this->SetWindow(node->Window);
    this->SetLevel(node->Level);
    this->SetAutoThreshold(node->AutoThreshold);
    this->SetApplyThreshold(node->ApplyThreshold);
    this->SetUpperThreshold(node->UpperThreshold);
    this->SetLowerThreshold(node->LowerThreshold);
    this->SetInterpolate(node->Interpolate);

  // Matrices
  this->RasToIjk->DeepCopy(node->RasToIjk);
  this->RasToWld->DeepCopy(node->RasToWld);
  this->WldToIjk->DeepCopy(node->WldToIjk);
  this->Position->DeepCopy(node->Position);

  // odonnell.  Fixes for diffusion tensor image data
  this->SetFrequencyPhaseSwap(node->FrequencyPhaseSwap);
}

//----------------------------------------------------------------------------
void vtkMrmlVolumeNode::SetScanOrder(const char *s)
{
  if (s == NULL)
  {
    vtkErrorMacro(<< "SetScanOrder: order string cannot be NULL");
    return;
  }
  if (!strcmp(s,"SI") || !strcmp(s,"IS") || !strcmp(s,"LR") || 
      !strcmp(s,"RL") || !strcmp(s,"AP") || !strcmp(s,"PA")) 
  { 
    if (this->ScanOrder)
    {
        if (strlen(this->ScanOrder) != strlen(s))
        {
            // only delete if it's a different size, so can
            // make a copy of a volume in place w/o losing
            // the scan order
            delete [] this->ScanOrder;
            this->ScanOrder = new char[strlen(s)+1];
        }
    }
    else
    {
        this->ScanOrder = new char[strlen(s)+1];
    }
    strcpy(this->ScanOrder, s);
    this->Modified();
  }
  else
  {
    vtkErrorMacro(<< "SetScanOrder: must be SI,IS,LR,RL,AP,or PA");
  }
}


// This function solves the 4x4 matrix equation
// A*B=C for the unknown matrix B, given matrices A and C.
// While this is equivalent to B=Inverse(A)*C, this function uses
// faster and more accurate methods (LU factorization) than finding a 
// matrix inverse and multiplying.  Returns 0 on failure.
//----------------------------------------------------------------------------
int vtkMrmlVolumeNode::SolveABeqCforB(vtkMatrix4x4 * A,  vtkMatrix4x4 * B,
                      vtkMatrix4x4 * C)
{
  double *a[4],*ct[4];
  double ina[16],inct[16];
  int ret,i,j,index[4];
  for(i=0;i<4;i++)
  {
    a[i]=ina+4*i;
    ct[i]=inct+4*i;
    for(j=0;j<4;j++) 
    {
      a[i][j]=A->GetElement(i,j);
      ct[i][j]=C->GetElement(j,i);
    }
  }
  ret=vtkMath::LUFactorLinearSystem(a,index,4);
  if (ret)
  {
    for(i=0;i<4;i++)
      vtkMath::LUSolveLinearSystem(a,index,ct[i],4);
    for(i=0;i<4;i++)
      for(j=0;j<4;j++)
        B->SetElement(i,j,floor(ct[j][i]*1e10+0.5)*(1e-10));
  }
  return(ret);
}


// This function solves the 4x4 matrix equation
// A*B=C for the unknown matrix A, given matrices B and C.
// While this is equivalent to A=C*Inverse(B), this function uses
// faster and more accurate methods (LU factorization) than finding a 
// matrix inverse and multiplying.  Returns 0 on failure.
//----------------------------------------------------------------------------
int vtkMrmlVolumeNode::SolveABeqCforA(vtkMatrix4x4 * A,  vtkMatrix4x4 * B,
                      vtkMatrix4x4 * C)
{
  double *a[4],*ct[4];
  double ina[16],inct[16];
  int ret,i,j,index[4];
  for(i=0;i<4;i++)
  {
    a[i]=ina+4*i;
    ct[i]=inct+4*i;
    for(j=0;j<4;j++) 
    {
      a[i][j]=B->GetElement(j,i);
      ct[i][j]=C->GetElement(i,j);
    }
  }
  ret=vtkMath::LUFactorLinearSystem(a,index,4);
  if (ret)
  {
    for(i=0;i<4;i++)
      vtkMath::LUSolveLinearSystem(a,index,ct[i],4);
    for(i=0;i<4;i++)
      for(j=0;j<4;j++)
        A->SetElement(i,j,floor(ct[i][j]*1e10+0.5)*(1e-10)); 
  }
  return(ret);
}

//----------------------------------------------------------------------------
void vtkMrmlVolumeNode::SetRasToWld(vtkMatrix4x4 *rasToWld)
{

    vtkIndent indent;
    if (this->Debug)
    {
        vtkDebugMacro(<<"\n\n\n\n*************************************\n***\t\t\t\t\t***\n***\t\t\t\t\t***\nmrml volume node, starting set ras to world, volume " << this->ID << "\n ");
        vtkDebugMacro(<<"Original rasToWld: ");
        this->RasToWld->PrintSelf(cerr, indent);

        vtkDebugMacro(<<"Original rasToIkj: ");
        this->RasToIjk->PrintSelf(cerr,indent);
        vtkDebugMacro(<<"Input rasToWld: ");
        rasToWld->PrintSelf(cerr, indent);
    }
    
  // Store RasToWld for posterity and because modern computer systems
  // have lots of memory.
  this->RasToWld->DeepCopy(rasToWld);
  
    vtkDebugMacro(<<"UseRasToVtkMatrix: " << this->UseRasToVtkMatrix);
  // Convert RasToIjk from string to matrix form
  if (this->UseRasToVtkMatrix)
  {
      vtkDebugMacro(<<"Setting RasToIjk using ras to vtk matrix:\n" << this->RasToVtkMatrix << endl);
    SetMatrixToString(this->RasToIjk, this->RasToVtkMatrix);
  }
  else 
  {
      vtkDebugMacro(<<"Setting RasToIjk using ras to ijk matrix:\n" << this->RasToIjkMatrix << endl);
    SetMatrixToString(this->RasToIjk, this->RasToIjkMatrix);
  }
  vtkDebugMacro(<<"Setting Position from Position Matrix:\n" << this->PositionMatrix << endl);
  SetMatrixToString(this->Position, this->PositionMatrix);

  // Form WldToIjk matrix to pass to reformatter, by
  // solving WldToIjk*RasToWld=RasToIjk for WldToIjk
  // -----------------------------------------------
  SolveABeqCforA(this->WldToIjk,rasToWld,this->RasToIjk);
  
  // This line is necessary to force reformatters to update.
  this->WldToIjk->Modified();
  if (this->Debug)
  {
      vtkDebugMacro(<<"mrml volume node, done set ras to world, WldToIjk: ");
      this->WldToIjk->PrintSelf(cerr,indent);
  }
}

//----------------------------------------------------------------------------
void vtkMrmlVolumeNode::PrintSelf(ostream& os, vtkIndent indent)
{
  int idx;
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "VolumeID: " <<
    (this->VolumeID ? this->VolumeID : "(none)") << "\n";
  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
  os << indent << "FilePattern: " <<
    (this->FilePattern ? this->FilePattern : "(none)") << "\n";
  os << indent << "FilePrefix: " <<
    (this->FilePrefix ? this->FilePrefix : "(none)") << "\n";
  os << indent << "FileType: " <<
    (this->FileType ? this->FileType : "(none)") << "\n";
  os << indent << "RasToIjkMatrix: " <<
    (this->RasToIjkMatrix ? this->RasToIjkMatrix : "(none)") << "\n";
  os << indent << "RasToVtkMatrix: " <<
    (this->RasToVtkMatrix ? this->RasToVtkMatrix : "(none)") << "\n";
  os << indent << "PositionMatrix: " <<
    (this->PositionMatrix ? this->PositionMatrix : "(none)") << "\n";
  os << indent << "ScanOrder: " <<
    (this->ScanOrder ? this->ScanOrder : "(none)") << "\n";
  os << indent << "LUTName: " <<
    (this->LUTName ? this->LUTName : "(none)") << "\n";
  os << indent << "FullPrefix: " <<
    (this->FullPrefix ? this->FullPrefix : "(none)") << "\n";


  os << indent << "LabelMap:          " << this->LabelMap << "\n";
  os << indent << "LittleEndian:      " << this->LittleEndian << "\n";
  os << indent << "ScalarType:        " << this->ScalarType << "\n";
  os << indent << "NumScalars:        " << this->NumScalars << "\n";
  os << indent << "Tilt:              " << this->Tilt << "\n";
  os << indent << "AutoWindowLevel:   " << this->AutoWindowLevel << "\n";
  os << indent << "Window:            " << this->Window << "\n";
  os << indent << "Level:             " << this->Level << "\n";
  os << indent << "AutoThreshold:     " << this->AutoThreshold << "\n";
  os << indent << "ApplyThreshold:    " << this->ApplyThreshold << "\n";
  os << indent << "UpperThreshold:    " << this->UpperThreshold << "\n";
  os << indent << "LowerThreshold:    " << this->LowerThreshold << "\n";
  os << indent << "Interpolate:       " << this->Interpolate << "\n";
  os << indent << "UseRasToVtkMatrix: " << this->UseRasToVtkMatrix << "\n";

  os << "Spacing:\n";
  for (idx = 0; idx < 3; ++idx)
  {
    os << indent << ", " << this->Spacing[idx];
  }
  os << ")\n";

  os << "ImageRange:\n";
  for (idx = 0; idx < 2; ++idx)
  {
    os << indent << ", " << this->ImageRange[idx];
  }
  os << ")\n";

  os << "Dimensions:\n";
  for (idx = 0; idx < 2; ++idx)
  {
    os << indent << ", " << this->Dimensions[idx];
  }
  os << ")\n";

  // Matrices
  os << indent << "RasToWld:\n";
    this->RasToWld->PrintSelf(os, indent.GetNextIndent());  
  os << indent << "RasToIjk:\n";
    this->RasToIjk->PrintSelf(os, indent.GetNextIndent());  
  os << indent << "WldToIjk:\n";
    this->WldToIjk->PrintSelf(os, indent.GetNextIndent());  
  os << indent << "Position:\n";
  this->Position->PrintSelf(os, indent.GetNextIndent());  
  
  // Added by Attila Tanacs 10/10/2000
  os << indent << "Number of DICOM Files: " << GetNumberOfDICOMFiles() << "\n";
  for(idx = 0; idx < DICOMFiles; idx++)
    os << indent << DICOMFileList[idx] << "\n";
  
  // odonnell, diffusion tensor data
  os << indent << "FrequencyPhaseSwap: " << this->FrequencyPhaseSwap<< "\n";
  // End
}

//----------------------------------------------------------------------------
void vtkMrmlVolumeNode::ComputeRasToIjkFromScanOrder(const char *order)
{
  int nx, ny, nz;
  vtkFloatingPointType crn[4][4],*ftl,*ftr,*fbr,*ltl,ctr[3];
  int i,j;

  // All we do here is figure out the corners and call 
  // ComputeRasToIjkFromCorners.
  // x direction is across the top of a slice
  // y direction is down the side of a slice
  // z direction is scan direction

  nx = this->Dimensions[0];
  ny = this->Dimensions[1];
  nz = this->ImageRange[1] - this->ImageRange[0] + 1;

  // Make sure we have a slice with some thickness
  if ((this->Spacing[2] <= 0.0) || (nz == 0))
  {
    vtkErrorMacro(<< "ComputeRasToIjkFromScanOrder: Neither slice spacing nor slice count can be 0");
    return;
  }
  
  // Figure out corners.
  // Here crn[][] = crn[ftl,ftr,fbr,ltl][x,y,z,1]
  ftl=crn[0];  // first slice, top left corner
  ftr=crn[1];  // first slice, top right corner
  fbr=crn[2];  // first slice, bottom right corner
  ltl=crn[3];  // last slice, top left corner
  for(i=0;i<4;i++) 
  {
    for(j=0;j<3;j++) crn[i][j]=0.0;
    crn[i][3]=1.0;
  }

  // Spacing
  ftr[0]=fbr[0]=((vtkFloatingPointType)nx)*this->Spacing[0];
  fbr[1]=((vtkFloatingPointType)ny)*this->Spacing[1];
  ltl[2]=((vtkFloatingPointType)(nz-1))*this->Spacing[2];  // tricky, it's not (nz-0)

  // Gantry tilt shifts the y coordinate of ltl
  ltl[1]=-ltl[2]*tan(this->Tilt * 3.1415927410125732421875f / 180.0f);

  // Direction of slice acquisition
  if (!strcmp(order,"SI") || !strcmp(order,"RL") || !strcmp(order,"AP"))
    ltl[2]=-ltl[2];

  // Centering.  Center is midway between opposite corners
  for(i=0;i<3;i++) ctr[i]=(fbr[i]+ltl[i])/2.0;
  for (i=0;i<4;i++) for (j=0;j<3;j++) crn[i][j]-=ctr[j];

  // Handle the case where frequency and phase encoding
  // directions have been swapped in the image.
  // Added by odonnell and haker, 4/2002, for 
  // diffusion tensor data
  if (this->FrequencyPhaseSwap)
    {// This is what we are going for:
      // axial RotateZ(90)
      // sagittal do nothing
      // coronal RotateZ(270)

      double tmp;
      if (!strcmp(order,"SI") || !strcmp(order,"IS"))
        {
          // axial
          for(i=0;i<4;i++)
            {
              // Normally, x is across, y is down.
              // Here though, the image is rotated 90 deg cw, so
              // set x=y and y=-x
              tmp=crn[i][0]; crn[i][0]=crn[i][1]; crn[i][1]=-tmp;
            }
        }
      else
        {
          if (!strcmp(order,"RL") || !strcmp(order,"LR"))  
            {
              // sagittal, do nothing
            }
          else
            {
              // coronal
              for(i=0;i<4;i++)
                {
                  // Normally, x is across, y is down.
                  // Here though, the image is rotated 90 deg cc, so
                  // set x=-y and y=x
                  tmp=crn[i][0]; crn[i][0]=-crn[i][1]; crn[i][1]=tmp;
                }             
            }
        }
    }

  // Map (x,y,z) to (r,a,s) by scan order
  if (!strcmp(order,"SI") || !strcmp(order,"IS"))
  {
    // axial, so (r,a,s)=(-x,-y,z)
    for (i=0;i<4;i++) for (j=0;j<2;j++) crn[i][j]=-crn[i][j];
  }
  else
  {
    if (!strcmp(order,"RL") || !strcmp(order,"LR"))  
    {
      // sagittal, so (r,a,s)=(z,-x,-y)
      for(i=0;i<4;i++) crn[i][3]= crn[i][0]; // send  x to col 3
      for(i=0;i<4;i++) crn[i][0]= crn[i][2]; // send  z to col 0
      for(i=0;i<4;i++) crn[i][2]=-crn[i][1]; // send -y to col 2
      for(i=0;i<4;i++) crn[i][1]=-crn[i][3]; // send -x to col 1
      for(i=0;i<4;i++) crn[i][3]=1.0; // reset col 3 
    }
    else
    {
      // coronal, so (r,a,s)=(-x,z,-y)
      for(i=0;i<4;i++) crn[i][0]=-crn[i][0]; // replace x with -x
      for(i=0;i<4;i++) crn[i][3]= crn[i][2]; // send  z to col 3
      for(i=0;i<4;i++) crn[i][2]=-crn[i][1]; // send -y to col 2
      for(i=0;i<4;i++) crn[i][1]= crn[i][3]; // send  z to col 1
      for(i=0;i<4;i++) crn[i][3]=1.0; // reset col 3
    }
  }

  // Now compute transforms based on corners
  this->ComputeRasToIjkFromCorners(NULL,ftl,ftr,fbr,NULL,ltl);
}


//----------------------------------------------------------------------------
int vtkMrmlVolumeNode::ComputeRasToIjkFromCorners(
  vtkFloatingPointType *fc, vtkFloatingPointType *ftl, vtkFloatingPointType *ftr, vtkFloatingPointType *fbr,
  vtkFloatingPointType *lc, vtkFloatingPointType *ltl, vtkFloatingPointType zoffset)
{
  // Note: fc and lc are not used.

  // The strategy here is as follows.  We create a 4x4 matrix called Ras,
  // which has in its columns the homogeneous RAS coordinates of four
  // corners of the data volume.  We then create another matrix called
  // Ijk, which has in its columns the IJK coordinates of those same four
  // corners.  We then solve for RasToIjk in the equation RasToIjk*Ras=Ijk.

  vtkFloatingPointType ScanDir[3],XDir[3],YDir[3],Corners[3][4],tmp,offset;
  int i,j,nx,ny,nz;
  vtkMatrix4x4 *Ijk_ = vtkMatrix4x4::New();
  vtkMatrix4x4 *Vtk_; // Just a pointer, no Delete() required.
  vtkMatrix4x4 *Ras_ = vtkMatrix4x4::New();
  vtkMatrix4x4 *RasToIjk_ = vtkMatrix4x4::New();
  vtkMatrix4x4 *RasToVtk_ = vtkMatrix4x4::New();
  vtkMatrix4x4 *InvScale_ = vtkMatrix4x4::New();
  vtkMatrix4x4 *Position_ = vtkMatrix4x4::New();

  nx = this->Dimensions[0];  // pixel columns in an image (x direction)
  ny = this->Dimensions[1];  // pixel rows in an image (y direction)
  nz = this->ImageRange[1] - this->ImageRange[0] + 1;  // number of slices

  // Check if there are no corner points in header
  if (ftl[0] == 0 && ftl[1] == 0 && ftl[2] == 1 &&
      ftr[0] == 0 && ftr[1] == 0 && ftr[2] == 0 && 
      fbr[0] == 1 && fbr[1] == 0 && fbr[2] == 0)
  {
    // (We probably have read a no-header image)
    // Clean up
    Ijk_->Delete();
    Ras_->Delete();
    RasToIjk_->Delete();
    RasToVtk_->Delete();
    InvScale_->Delete();
    Position_->Delete();
    return(-1);
  }

  // Get scan direction vectors
  for(i=0;i<3;i++) 
  {
    XDir[i]=ftr[i]-ftl[i];  // corner to corner across top of an image
    YDir[i]=fbr[i]-ftr[i];  // corner to corner down side of an image
    // ScanDir is across slices, but _NOT_ corner to corner.
    // Rather, it's the center of the first scan plane to center of last.
    ScanDir[i]=ltl[i]-ftl[i];
  }

  // Pack volume corners into Corners[][]
  for(i=0;i<3;i++)
  {
    Corners[i][0]=ftl[i];  // first slice, top left
    Corners[i][1]=ftr[i];  // first slice, top right
    Corners[i][2]=fbr[i];  // first slice, bottom right
    Corners[i][3]=ltl[i];  // last slice, top left
  }

  // Special handling for a volume that's a single slice.
  // If nz==1 or ltl==ftl, assume a single image.  If so, set ScanDir
  // to cross product of XDir and YDir, alter Corners[][3] to fake
  // two slices, using thickness.
  if ((nz==1)||((ScanDir[0]==0.0) && (ScanDir[1]==0.0) && 
      (ScanDir[2]==0.0)))
  {
    // Zero slice thickness is a failure
    if (this->Spacing[2]<=0.0)
    {
      // Clean up
      Ijk_->Delete();
      Ras_->Delete();
      RasToIjk_->Delete();
      RasToVtk_->Delete();
      InvScale_->Delete();
      Position_->Delete();
      return(-1);
    }

    // For single slice, set scan direction perpendicular to image.
    vtkMath::Cross(XDir,YDir,ScanDir);
    vtkMath::Normalize(ScanDir);
    for (i=0;i<3;i++)
      {
      ScanDir[i]*=this->Spacing[2];
      // mock up ltl[] using ftl[] and ScanDir
      Corners[i][3]=Corners[i][0]+ScanDir[i];
      }
    // Pretend it's two slices when calculating transforms.
    // Calculations below will then be correct.
    nz=2; 
  }

  // Figure out scan direction description. 
  // If oblique, take best approximation.
  if (  (fabs(ScanDir[0])>=fabs(ScanDir[1]))&&
        (fabs(ScanDir[0])>=fabs(ScanDir[2])))
  { // Sagittal
    if (ScanDir[0]>=0.0) this->SetScanOrder("LR");
    else this->SetScanOrder("RL");
  }
  else
  {
    if ( (fabs(ScanDir[1])>=fabs(ScanDir[0]))&&
         (fabs(ScanDir[1])>=fabs(ScanDir[2])))
    { // Coronal
      if (ScanDir[1]>=0.0) this->SetScanOrder("PA");
      else this->SetScanOrder("AP");
    }
    else
    { // Axial
      if (ScanDir[2]>=0.0) this->SetScanOrder("IS");
      else this->SetScanOrder("SI");      
    }
  }

  // Create Ijk matrix with volume "Corner points" as columns.
  // Slicer's ijk coordinate origin is at a corner of the volume 
  // parallelepiped, not the center of the imaged voxel.

  // This offset will be changed to 0.5 from 0.0 per 2/8/2002 Slicer 
  // development meeting, to move ijk coordinates to voxel centers.
  // -- default is set above, and can be modified through methods for this class
  //offset=0.0;
  offset= vtkMrmlVolumeNodeGlobalVoxelOffset; // default set above, can 

  Ijk_->Zero();
  // ftl in Ijk coordinates
  Ijk_->SetElement(0,0,0.0-offset);
  Ijk_->SetElement(1,0,0.0-offset);  
  Ijk_->SetElement(2,0,zoffset-offset);  // Not 0.0
  Ijk_->SetElement(3,0,1.0);  
  // ftr in Ijk coordinates
  Ijk_->SetElement(0,1,(vtkFloatingPointType)nx-offset);  
  Ijk_->SetElement(1,1,0.0-offset);  
  Ijk_->SetElement(2,1,zoffset-offset);  // Not 0.0
  Ijk_->SetElement(3,1,1.0);  
  // fbr in Ijk coordinates
  Ijk_->SetElement(0,2,(vtkFloatingPointType)nx-offset);  
  Ijk_->SetElement(1,2,(vtkFloatingPointType)ny-offset);  
  Ijk_->SetElement(2,2,zoffset-offset);  // Not 0.0
  Ijk_->SetElement(3,2,1.0);  
  // ltl in Ijk coordinates
  Ijk_->SetElement(0,3,0.0-offset);  
  Ijk_->SetElement(1,3,0.0-offset);  
  Ijk_->SetElement(2,3,(vtkFloatingPointType)(nz-1)+zoffset-offset); // Not nz-1
  Ijk_->SetElement(3,3,1.0);  

  // Pack Ras matrix with "Corner Points"
  Ras_->Zero();
  for(j=0;j<4;j++)
  {
    for(i=0;i<3;i++) Ras_->SetElement(i,j,Corners[i][j]);
    Ras_->SetElement(3,j,1.0);
  }
  Ras_->SetElement(3,3,1.0);

  // Solve RasToIjk*Ras=Ijk for RasToIjk.
  SolveABeqCforA(RasToIjk_,Ras_,Ijk_);

  // Vtk coordinates differ from Ijk in the direction
  // of the j axis, i.e. Vtk=(i,ny-1-j,k)
  Vtk_=Ijk_;  // Vtk was not created with New()
  Vtk_->SetElement(1,0,(vtkFloatingPointType)ny-offset);  // ftl
  Vtk_->SetElement(1,1,(vtkFloatingPointType)ny-offset);  // ftr
  Vtk_->SetElement(1,2,0.0-offset);        // fbr
  Vtk_->SetElement(1,3,(vtkFloatingPointType)ny-offset);  // ltl
  
  // Solve RasToVtk*Ras=Vtk for RasToVtk.
  SolveABeqCforA(RasToVtk_,Ras_,Vtk_);  

  // Figure out the "Position Matrix" which converts
  // from scaled Vtk coordinates to Ras coordinates.
  // Formula: Position = VtkToRas*Inverse(ScaleMat)
  //        or  RasToVtk*Position=Inverse(ScaleMat)
  // where ScaleMat is a diagonal scaling matrix with diagonal
  // elements equal to the pixel size and slice thickness.
  InvScale_->Identity();
  for (i=0;i<3;i++) 
  {
    tmp=this->Spacing[i];
    tmp=(tmp<=0.0)?(1.0):(1.0/tmp);
    InvScale_->SetElement(i,i,tmp);
  }
  // Solve RasToVtk*Position=InvScale for Position.
  SolveABeqCforB(RasToVtk_,Position_,InvScale_);

  // Convert matrices to strings
  this->SetRasToIjkMatrix(GetMatrixToString(RasToIjk_));
  this->SetRasToVtkMatrix(GetMatrixToString(RasToVtk_));
  this->SetPositionMatrix(GetMatrixToString(Position_));

  // Clean up
  Ijk_->Delete();
  // Vtk->Delete();  We shouldn't have a Delete() for Vtk
  Ras_->Delete();
  RasToIjk_->Delete();
  RasToVtk_->Delete();
  InvScale_->Delete();
  Position_->Delete();

  return(0);
}

void 
vtkMrmlVolumeNode::ComputePositionMatrixFromRasToVtk(vtkMatrix4x4* RasToVtkMatrix)
{
  // Figure out the "Position Matrix" which converts
  // from scaled Vtk coordinates to Ras coordinates.
  // Formula: Position = VtkToRas*Inverse(ScaleMat)
  //        or  RasToVtk*Position=Inverse(ScaleMat)
  // where ScaleMat is a diagonal scaling matrix with diagonal
  // elements equal to the pixel size and slice thickness.
  vtkFloatingPointType tmp;
  vtkMatrix4x4 *InvScale_ = vtkMatrix4x4::New();
  vtkMatrix4x4 *Position_ = vtkMatrix4x4::New();

  InvScale_->Identity();
  Position_->Identity();

  for (int i=0;i<3;i++) 
  {
    tmp=this->Spacing[i];
    tmp=(tmp<=0.0)?(1.0):(1.0/tmp);
    InvScale_->SetElement(i,i,tmp);
  }
  // Solve RasToVtk*Position=InvScale for Position.
  SolveABeqCforB(RasToVtkMatrix, Position_, InvScale_);

  // Convert matrices to strings
  this->SetPositionMatrix(GetMatrixToString(Position_));

  // Clean up
  InvScale_->Delete();
  Position_->Delete();
}


// Added by Attila Tanacs 10/10/2000 1/4/02

// DICOMFileList
void vtkMrmlVolumeNode::AddDICOMFileName(const char *str)
{
  if (DICOMFiles >= DICOM_FILE_LIMIT)
  {
    vtkErrorMacro(<< "AddDICOMFileName: Reached hard coded limit on number of files in a directory (" << DICOM_FILE_LIMIT << ")." );
    return;
  }
  DICOMFileList[DICOMFiles] = new char [strlen(str) + 1];
  strcpy(DICOMFileList[DICOMFiles], str);
  DICOMFiles++;
}

const char *vtkMrmlVolumeNode::GetDICOMFileName(int idx)
{
  return DICOMFileList[idx];
}

void vtkMrmlVolumeNode::SetDICOMFileName(int idx, const char *str)
{
  delete [] DICOMFileList[idx];
  DICOMFileList[idx] = new char [strlen(str) + 1];
  strcpy(DICOMFileList[idx], str);
}

void vtkMrmlVolumeNode::DeleteDICOMFileNames()
{
    int i;
    for(i=0; i<DICOM_FILE_LIMIT; i++)
        if(DICOMFileList[i] != NULL)
        {
            delete [] DICOMFileList[i];
            DICOMFileList[i] = NULL;
        }

    DICOMFiles = 0;
}

void vtkMrmlVolumeNode::AddDICOMMultiFrameOffset(int offset)
{
  DICOMMultiFrameOffsetList[DICOMMultiFrameOffsets] = offset;
  DICOMMultiFrameOffsets++;
}

int vtkMrmlVolumeNode::GetDICOMMultiFrameOffset(int idx)
{
  return DICOMMultiFrameOffsetList[idx];
}

void vtkMrmlVolumeNode::DeleteDICOMMultiFrameOffsets()
{
  DICOMMultiFrameOffsets = 0;
}

const char* vtkMrmlVolumeNode::ComputeScanOrderFromRasToIjk(vtkMatrix4x4 *RasToIjk)
{
  vtkMatrix4x4 *IjkToRas = vtkMatrix4x4::New();
  vtkMatrix4x4::Invert(RasToIjk, IjkToRas);

  vtkFloatingPointType dir[4]={0,0,1,0};
  vtkFloatingPointType kvec[4];
 
  IjkToRas->MultiplyPoint(dir,kvec);
  int max_comp = 0;
  double max = fabs(kvec[0]);
  
  for (int i=1; i<3; i++) {
    if (fabs(kvec[i]) > max) {
        max = fabs(kvec[i]);
        max_comp=i;
     }   
  }
  
  switch(max_comp) {
     case 0:
        if (kvec[max_comp] > 0 ) {
           return "LR";
        } else {
           return "RL";
        }
           break;
      case 1:     
         if (kvec[max_comp] > 0 ) {
            return "PA";
         } else {
            return "AP";
         }
         break;
      case 2:
         if (kvec[max_comp] > 0 ) {
            return "IS";
         } else {
            return "SI";
         }
         break;
  default:
      cerr << "vtkMrmlVolumeNode::ComputeScanOrderFromRasToIjk:\n\tMax components "<< max_comp << " not in valid range 0,1,2\n";
      return "";
   }        
 
}

// End
