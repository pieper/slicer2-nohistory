/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMGHReader.cxx,v $
  Date:      $Date: 2006/05/26 19:40:15 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/

#include "vtkMGHReader.h"
#include "vtkShortArray.h"
#include "vtkUnsignedCharArray.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkObjectFactory.h"
#include "vtkFSIO.h"
#include "vtkImageData.h"
#include "vtkPointData.h"

vtkMGHReader* vtkMGHReader::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMGHReader");
  if(ret)
    {
    return (vtkMGHReader*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkMGHReader;
}

vtkMGHReader::vtkMGHReader()
{
  this->DataDimensions[0] = 
    this->DataDimensions[1] = 
    this->DataDimensions[2] = 0;
  this->FileName = NULL;
  this->ScalarType = 0;
  this->NumFrames = 0;
  this->CurFrame = 0;

}

vtkMGHReader::~vtkMGHReader()
{
  if (this->FileName) {
    delete [] this->FileName;
  }
}


void vtkMGHReader::ExecuteInformation()
{
  vtkDebugMacro(<< "vtkMGHReader: ExecuteInformation");
    
  vtkImageData *output = this->GetOutput();
  if (!output)
  {
      vtkErrorMacro(<< "vtkMGHReader::ExecuteInformation: output is null");
      cerr << "vtkMGHReader::ExecuteInformation: output is null";
      return;
  }
  // Read the header.
  this->ReadVolumeHeader();


  // Set some data in the output.
  output->SetWholeExtent(0, this->DataDimensions[0]-1,
             0, this->DataDimensions[1]-1,
             0, this->DataDimensions[2]-1 );
  output->SetScalarType(this->ScalarType);
  output->SetNumberOfScalarComponents(1);
  output->SetSpacing(this->DataSpacing);
  output->SetOrigin(this->DataOrigin);
}
    

void vtkMGHReader::SetOutput()
{
    vtkDebugMacro(<< "vtkMGHReader: SetOutput, calling Execute\n");
    this->Execute();
}

void vtkMGHReader::Execute()
{
    vtkDebugMacro(<< "vtkMGHReader: Execute");
    
  vtkImageData *output = this->GetOutput();

  if (output == NULL)
  {
      vtkErrorMacro(<<"vtkMGHReader: Execute: output is null");
      cout <<"vtkMGHReader: Execute: output is null";
      return;
  }
  // Read the header.
  this->ReadVolumeHeader();


  // Set some data in the output.
  output->SetWholeExtent(0, this->DataDimensions[0]-1,
             0, this->DataDimensions[1]-1,
             0, this->DataDimensions[2]-1 );
  output->SetScalarType(this->ScalarType);
  output->SetNumberOfScalarComponents(1);
  output->SetDimensions(this->DataDimensions);
  output->SetSpacing(this->DataSpacing);
  output->SetOrigin(this->DataOrigin);

  // Get the volume values from the MGH files. If we get them, copy
  // them to the output.
  vtkDataArray *newScalars = this->ReadVolumeData();
  if ( newScalars ) 
  {
      if (output->GetPointData() == NULL)
      {
          vtkErrorMacro(<<"vtkMGHReader: Execute: point data is null.");
          cout <<"vtkMGHReader: Execute: point data is null.";
      }
      else
      {
          output->GetPointData()->SetScalars(newScalars);
      }
      newScalars->Delete();
  }
  else
  {
      vtkErrorMacro(<<"vtkMGHReader: Execute: scalars are null");
      cout <<"vtkMGHReader: Execute: scalars are null";
  }
}

vtkImageData *vtkMGHReader::GetImage(int ImageNumber)
{
  cerr << "vtkMGHReader::GetImage() called. uh oh." << endl;
  return NULL;
}

vtkDataArray *vtkMGHReader::ReadVolumeData()
{
  vtkDataArray          *scalars = NULL;
  vtkUnsignedCharArray  *ucharScalars = NULL;
  vtkShortArray         *shortScalars = NULL;
  vtkIntArray           *intScalars = NULL;
  vtkFloatArray         *floatScalars = NULL;
  void* destData;
  short* short_destData;
  int* int_destData;
  float* float_destData;
  //FILE *fp;
  // using zlib to read the file, it will work on uncompressed files as well
  gzFile fp;
  int numRead;
  int numPts;
  int elementSize;
  short s;
  int i;
  float f;
  
  // Check the file name.
  if( NULL == this->FileName || 
      (0 == strlen( this->FileName )) ) {
    vtkErrorMacro( << "No file name specified" );
    cout << "ReadVolumeData: No file name specified" ;
    return NULL;
  }
  vtkDebugMacro(<< "vtkMGHReader: ReadVolumeData for file " << this->FileName << ", scalartype = " << this->ScalarType << "\n");
  
  // Read header first.
  this->ReadVolumeHeader();

  // Calc the number of values.
  numPts = this->DataDimensions[0] * 
    this->DataDimensions[1] * 
    this->DataDimensions[2];

  // Create the scalar array for the volume. Set the element size for
  // the data we will read. Get a writable pointer to the scalar data
  // so we can read data into it.
  switch ( this->ScalarType ) {
  case VTK_UNSIGNED_CHAR:
    vtkDebugMacro (<< "Creating vtkUnsignedCharArray");
    ucharScalars = vtkUnsignedCharArray::New();
    ucharScalars->Allocate(numPts);
    destData = (void*) ucharScalars->WritePointer(0, numPts);
    scalars = (vtkDataArray*) ucharScalars;
    elementSize = sizeof( char );
    break;
  case VTK_SHORT:
    vtkDebugMacro (<< "Creating vtkShortArray");
    shortScalars = vtkShortArray::New();
    shortScalars->Allocate(numPts);
    destData = (void*) shortScalars->WritePointer(0, numPts);
    scalars = (vtkDataArray*) shortScalars;
    elementSize = sizeof( short );
    break;
  case VTK_INT:
    vtkDebugMacro (<< "Creating vtkIntArray");
    intScalars = vtkIntArray::New();
    intScalars->Allocate(numPts);
    destData = (void*) intScalars->WritePointer(0, numPts);
    scalars = (vtkDataArray*) intScalars;
    elementSize = sizeof( int );
    break;
  case VTK_FLOAT:
    vtkDebugMacro (<< "Creating vtkFloatArray");
    floatScalars = vtkFloatArray::New();
    floatScalars->Allocate(numPts);
    destData = (void*) floatScalars->WritePointer(0, numPts);
    scalars = (vtkDataArray*) floatScalars;
    elementSize = sizeof( float );
    break;
  default:
    vtkDebugMacro(<< "Volume type not supported.");
    cout <<  "Volume type not supported.";
    return NULL;
  }
  if ( NULL == scalars ) {
    vtkErrorMacro(<< "Couldn't allocate scalars array.");
    cout << "Couldn't allocate scalars array.";
    return NULL;
  } 
  

  // Open the file.
  //fp = fopen( this->FileName, "rb" );
  fp = gzopen(this->FileName, "rb");
  if( !fp ) {
    vtkErrorMacro(<< "Can't find/open file: " << this->FileName);
    cout << "Can't find/open file: " << this->FileName;
    return NULL;
  }

  // Skip all the header information and the frames we don't want.
  gzseek( fp, FS_WHOLE_HEADER_SIZE + (this->CurFrame * numPts), SEEK_SET );

  // Read in a frame. We need to do this element by element so we can
  // do byte swapping, except for the uchars because they don't need
  // it.
  vtkDebugMacro(<< "vtkMGHReader: ReadVolumeData: starting to read, numpts=" << numPts << " of scalarType " << this->ScalarType << endl);
  if( VTK_UNSIGNED_CHAR == this->ScalarType ) {
    //numRead = fread( destData, elementSize, numPts, fp );
    numRead = gzread(fp, destData, elementSize*numPts);
      if ( numRead != numPts ) {
          vtkErrorMacro(<<"Trying to read " << numPts << " elements, "
                        "but only got " << numRead << " of them.");
          cout <<"Trying to read " << numPts << " elements, "
              "but only got " << numRead << " of them.";
          scalars->Delete();
          return NULL;
      }
  } else {
      short_destData = (short *)destData;
      int_destData = (int *)destData;
      float_destData = (float *)destData;
      for( int nZ = 0; nZ < this->DataDimensions[2]; nZ++ ) {
          for( int nY = 0; nY < this->DataDimensions[1]; nY++ ) {
              for( int nX = 0; nX < this->DataDimensions[0]; nX++ ) {
                  switch ( this->ScalarType ) {
                  case VTK_SHORT:
                      vtkFSIO::ReadShortZ( fp, s );
                      *short_destData++ = s;
                      break;
                  case VTK_INT:
                      vtkFSIO::ReadIntZ( fp, i );
                      *int_destData++ = i;
                      break;
                  case VTK_FLOAT:
                      vtkFSIO::ReadFloatZ( fp, f );
                      *float_destData++ = f;
                      break;
                  default:
                      vtkErrorMacro(<< "Volume type not supported.");
                      cout << "Volume type not supported.";
                      return NULL;
                  }
              }
          }
          this->UpdateProgress(1.0*nZ/this->DataDimensions[2]);
      }
  }

  // Close the file.
  //  fclose(fp);
  gzclose(fp);

  this->SetProgressText("");
  this->UpdateProgress(0.0);
  
  // return the scalars.
  return scalars;
}

/*
From http://www.nmr.mgh.harvard.edu/~tosa/#coords:
To go from freesurfer voxel coordinates to RAS coordinates, they use:
translation:  t_r, t_a, t_s is defined using c_r, c_a, c_s centre voxel position in RAS
rotation: direction cosines x_(r,a,s), y_(r,a,s), z_(r,a,s)
voxel size for scale: s_x, s_y, s_z

 [ x_r y_r z_r t_r][s_x  0   0  0]
 [ x_a y_a z_a t_a][0   s_y  0  0]
 [ x_s y_s z_s t_s][0    0  s_z 0]
 [  0   0   0   1 ][0    0   0  1]
Voxel center is a column matrix, multipled from the right
[v_x]
[v_y]
[v_z]
[ 1 ]

In the MGH header, they hold:
 x_r x_a x_s
 y_r y_a y_s
 z_r z_a z_s
 c_r c_a c_s
*/
void vtkMGHReader::ReadVolumeHeader()
{
  //  FILE *fp;
  gzFile fp;
  int version;
  int type;
  int dof;
  short RASgood;
  int useCompressor = 0;
  
  // Check the file name.
  if( NULL == this->FileName || 
      (0 == strlen( this->FileName )) )
  {
    vtkErrorMacro( << "No file name specified" );
    cout << "ReadVolumeHeader: No file name specified";
    return;
  }
  vtkDebugMacro(<< "vtkMGHReader: ReadVolumeHeader for file " << this->FileName << "\n");

  // is the file compressed?
  if (strstr(this->FileName,"mgz") != NULL ||
      strstr(this->FileName,"gz") != NULL)
  {
      useCompressor = 1;
      vtkDebugMacro(<<"ReadVolumeHeader " << this->FileName << " is compressed\n");
  } else {
    vtkDebugMacro(<<"ReadVolumeHeader " << this->FileName << " is NOT compressed\n");
  }

  // Open the file, gzopen will work on uncompressed files as well
  fp = gzopen(this->FileName, "rb");
  // fp = fopen( this->FileName, "rb" );

  if( !fp ) {
    vtkErrorMacro(<< "Can't find/open file: " << this->FileName);
    cout << "ReadVolumeHeader: Can't find/open file: " << this->FileName;
    return;
  }

  // Read in dimension information.
  /*
  vtkFSIO::ReadInt( fp, version );
  vtkFSIO::ReadInt( fp, this->DataDimensions[0] );
  vtkFSIO::ReadInt( fp, this->DataDimensions[1] );
  vtkFSIO::ReadInt( fp, this->DataDimensions[2] );
  vtkFSIO::ReadInt( fp, this->NumFrames );
  vtkFSIO::ReadInt( fp, type );
  vtkFSIO::ReadInt( fp, dof );
  */
    vtkFSIO::ReadIntZ( fp, version);
    vtkFSIO::ReadIntZ( fp, this->DataDimensions[0] );
    vtkFSIO::ReadIntZ( fp, this->DataDimensions[1] );
    vtkFSIO::ReadIntZ( fp, this->DataDimensions[2] );
    vtkFSIO::ReadIntZ( fp, this->NumFrames );
    vtkFSIO::ReadIntZ( fp, type );
    vtkFSIO::ReadIntZ( fp, dof );

  // Convert the type to a VTK scalar type.
  switch( type ) {
  case MRI_UCHAR: this->ScalarType = VTK_UNSIGNED_CHAR; break;
  case MRI_INT: this->ScalarType = VTK_INT; break;
  case MRI_FLOAT: this->ScalarType = VTK_FLOAT; break;
  case MRI_SHORT: this->ScalarType = VTK_SHORT; break;
  default:
    cerr << "Using float by default" << endl;
    this->ScalarType = VTK_FLOAT;
  }

  // The next short is says whether the RAS registration information
  // is good. If so, read in the voxel size and then the matrix.
  //vtkFSIO::ReadShort( fp, RASgood );
  vtkFSIO::ReadShortZ( fp, RASgood);
  float spacing[3];
  if( RASgood ) {

    for( int nSpacing = 0; nSpacing < 3; nSpacing++ ) {
      vtkFSIO::ReadFloatZ( fp, spacing[nSpacing] );
      this->DataSpacing[nSpacing] = spacing[nSpacing];
    }

    // x_r x_a x_s
    // y_r y_a y_s
    // z_r z_a z_s
    // c_r c_a c_s
    for( int nMatrix = 0; nMatrix < 12; nMatrix++ ) {
      vtkFSIO::ReadFloatZ( fp, this->RASMatrix[nMatrix] );
      vtkDebugMacro(<<"RASMatrix[" << nMatrix << "] = " << this->RASMatrix[nMatrix] << ".");
    }
  }

  //  fclose(fp);
  gzclose(fp);
}

void vtkMGHReader::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkVolumeReader::PrintSelf( os, indent );

  os << indent << "Data Dimensions: (" << this->DataDimensions[0] << ", "
     << this->DataDimensions[1] << ", " << this->DataDimensions[2] << ")\n";
  os << indent << "Data Spacing: (" << this->DataSpacing[0] << ", "
     << this->DataSpacing[1] << ", " << this->DataSpacing[2] << ")\n";
  os << indent << "Scalar type: " << this->ScalarType << endl;
  os << indent << "Number of Frames: " << this->NumFrames << endl;
  os << indent << "Current Frame: " << this->CurFrame << endl;
  if (this->FileName)
  {
      os << indent << "File name: " << this->FileName << endl;
  }
  else
  {
      os << indent << "File name: NULL" << endl;
  }
  os << indent << "RAS to IJK matrix: " << endl;
  os << indent << "\tx_r " << this->RASMatrix[0] << "\t\tx_a " << this->RASMatrix[1] << "\t\tx_s " << this->RASMatrix[2] << endl;
  os << indent << "\ty_r " << this->RASMatrix[3] << "\t\ty_a " << this->RASMatrix[4] << "\t\ty_s " << this->RASMatrix[5] << endl;
  os << indent << "\tz_r " << this->RASMatrix[6] << "\t\tz_a " << this->RASMatrix[7] << "\t\tz_s " << this->RASMatrix[8] << endl;
  os << indent << "\tc_r " << this->RASMatrix[9] << "\tc_a " << this->RASMatrix[10] << "\tc_s " << this->RASMatrix[11] << endl;
}
