/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBVolumeReader.cxx,v $
  Date:      $Date: 2006/05/26 19:40:13 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
#include "vtkBVolumeReader.h"
#include "vtkObjectFactory.h"
#include "vtkShortArray.h"
#include "vtkUnsignedCharArray.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkImageData.h"
#include "vtkMatrix4x4.h"
#include "vtkPointData.h"
#include "vtkFSIO.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <ctype.h>
#ifdef _WIN32 // WINDOWS
#define S_ISREG(m)  (((m)&_S_IFMT) == _S_IFREG)
#else
#include <unistd.h>
#endif

vtkBVolumeReader* vtkBVolumeReader::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkBVolumeReader");
  if(ret)
    {
    return (vtkBVolumeReader*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkBVolumeReader;
}

vtkBVolumeReader::vtkBVolumeReader()
{
  this->DataDimensions[0] = 
    this->DataDimensions[1] = 
    this->DataDimensions[2] = 0;
  this->DataSpacing[0] = 
    this->DataSpacing[1] = 
    this->DataSpacing[2] = 0;
  this->FileName = NULL;
  this->RegistrationFileName = NULL;
  this->SliceFileNameExtension = NULL;
  this->RegistrationMatrix = NULL;
  this->Stem = NULL;
  this->ScalarType = 0;
  this->NumTimePoints = 0;
  this->CurTimePoint = 0;
  for (int i=0; i<12; i++)
  {
      this->RASMatrix[i] = 0.0;
  }
  this->TopL[0] = this->TopL[1] = this->TopL[2] = 0.0;
  this->TopR[0] = this->TopR[1] = this->TopR[2] = 0.0;
  this->BottomR[0] = this->BottomR[1] = this->BottomR[2] = 0.0;
  this->Normal[0] = this->Normal[1] = this->Normal[2] = 0.0;
  this->TE = 0.0;
  this->TR = 0.0;
  this->TI = 0.0;
  this->FlipAngle = 0.0;
}

vtkBVolumeReader::~vtkBVolumeReader()
{
  if (this->FileName) {
    delete [] this->FileName;
  }
  if (this->RegistrationFileName) {
    delete [] this->RegistrationFileName;
  }
  if (this->SliceFileNameExtension) {
    delete [] this->SliceFileNameExtension;
  }
  if (this->Stem) {
    delete [] this->Stem;
  }
  if (this->RegistrationMatrix) {
    this->RegistrationMatrix->Delete();
  }
}


void vtkBVolumeReader::ExecuteInformation()
{
    vtkDebugMacro(<<"#\n#\n#\n#\n#\n#\n#\n#\n#\n#\nExecuteInformation (all this does is re-reading the volume header)\n");
    
  vtkImageData *output = this->GetOutput();
  
  // Read the header.
  if (this->ReadVolumeHeader() == 0)
  {
      vtkErrorMacro(<<"ExecuteInformation: error reading volume header, returning.\n");
      return;
  }

  vtkDebugMacro(<<"ExecuteInformation: read header, data dimensions[2] = " << this->DataDimensions[2]);
  
  // Set some data in the output.
  output->SetWholeExtent(0, this->DataDimensions[0]-1,
             0, this->DataDimensions[1]-1,
             0, this->DataDimensions[2]-1 );
  output->SetScalarType(this->ScalarType);
  output->SetNumberOfScalarComponents(this->NumTimePoints);
  output->SetSpacing(this->DataSpacing);
  output->SetOrigin(this->DataOrigin);
}
    
    
void vtkBVolumeReader::Execute()
{
    vtkDebugMacro(<<"\n\n\nStarting Execute...\n");
    
  vtkImageData *output = this->GetOutput();

  if (output == NULL)
  {
      vtkErrorMacro(<<"vtkBVolumeReader: Execute: output is null");
  }
  
  // Read the header.
  if (this->ReadVolumeHeader() == 0)
  {
      vtkErrorMacro(<<"Execute: error reading volume header, returning.\n");
      return;
  }


  // Set some data in the output.
  output->SetWholeExtent(0, this->DataDimensions[0]-1,
             0, this->DataDimensions[1]-1,
             0, this->DataDimensions[2]-1 );
  output->SetScalarType(this->ScalarType);
  output->SetNumberOfScalarComponents(1);
  //output->SetNumberOfScalarComponents(this->NumTimePoints);
  output->SetDimensions(this->DataDimensions);
  output->SetSpacing(this->DataSpacing);
  output->SetOrigin(this->DataOrigin);

  // Get the volume values from the MGH files. If we get them, copy
  // them to the output.
  vtkDataArray *newScalars = this->ReadVolumeData();
  if ( newScalars ) 
    {
      output->GetPointData()->SetScalars(newScalars);
      newScalars->Delete();
      vtkDebugMacro(<<"Execute: number of components in output's point data = " << output->GetPointData()->GetNumberOfComponents() << ", in scalar = " << output->GetPointData()->GetScalars()->GetNumberOfComponents());
    } else {
        vtkErrorMacro(<<"vtkBVolumeReader: Execute: scalars are null");
    }
}

vtkImageData *vtkBVolumeReader::GetImage(int ImageNumber)
{
  cerr << "vtkBVolumeReader::GetImage() called. uh oh." << endl;
  return NULL;
}

vtkMatrix4x4 *vtkBVolumeReader::GetRegistrationMatrix()
{
  struct stat fileInfo;
  int error;
  FILE* fp;
  float m[4][4];
  int i;
  int j;
  
  vtkDebugMacro(<<"GetRegistrationMatrix\n");

  if( NULL == this->RegistrationFileName ) {
    vtkErrorMacro(<< "Registration file name not specified.");
    return NULL;
  } 
  
  // If we don't have the matrix, try loading it.
  if( NULL == this->RegistrationMatrix ){

    // Make sure the file is readable
    error = stat( this->RegistrationFileName, &fileInfo );
    if( !error ) {
        if( !S_ISREG( fileInfo.st_mode ) ) {
            vtkErrorMacro(<< "Registration file " << this->RegistrationFileName 
                          << " isn't valid.");
            return NULL;
        }
    }
    
    // Open the file.
    fp = fopen( this->RegistrationFileName, "r" );
    if( NULL == fp ) {
      vtkErrorMacro(<< "Couldn't open registration file " << this->RegistrationFileName );
      return NULL;
    }
    
    // Skip the first four values (name, pixel size, and intensity)
    fscanf(fp, "%*s");
    fscanf(fp, "%*f");
    fscanf(fp, "%*f");
    fscanf(fp, "%*f");
    for( j = 0; j < 4; j++ ) {
      for( i = 0; i < 4; i++ ) {
    fscanf(fp, "%f", &m[i][j]);
      }
    }
    fclose(fp);
    
    // Make a matrix and stuff it.
    this->RegistrationMatrix = vtkMatrix4x4::New();
    for( j = 0; j < 4; j++ ) {
      for( i = 0; i < 4; i++ ) {
    this->RegistrationMatrix->SetElement( i, j, (double)m[i][j] );
      }
    }
  }

  return this->RegistrationMatrix;
}

vtkDataArray *vtkBVolumeReader::ReadVolumeData()
{
  vtkDataArray          *scalars = NULL;
  vtkShortArray         *shortScalars = NULL;
  vtkFloatArray         *floatScalars = NULL;
  void* destData;
  short* short_destData;
  float* float_destData;
  char sliceFileName[1024];
  FILE *fp;
  int sliceNumber;
  int numRead;
  int numPts;
  int numPtsPerSlice;
  int totalPoints;
  int numReadTotal;
  int numReadSlice;
  int tupleNum;
  int elementSize;
  short s;
  float f;

    vtkDebugMacro(<<"\n\n\n\n\n\n\n\n\n\n***************\nvtkBvolumeReader: ReadVolumeData\n");

  // Read header first.
    if (this->ReadVolumeHeader() == 0)
    {
        vtkErrorMacro(<<"ReadVolumeData: error reading volume header.\n");
        return NULL;
    }

  // Check the prefix.
  if( NULL == this->Stem || 
      (0 == strlen( this->Stem )) ) {
    vtkErrorMacro( << "No file prefix specified" );
    return NULL;
  }

//  this->SetProgressText("Reading B volume");
  
  // Calc the number of values.
  numPts = this->DataDimensions[0] * 
    this->DataDimensions[1] * 
    this->DataDimensions[2];
  numPtsPerSlice = this->DataDimensions[0] * 
    this->DataDimensions[1] * this->NumTimePoints;
  totalPoints =  numPts*this->NumTimePoints;
  
  // Create the scalar array for the volume. Set the element size for
  // the data we will read. Get a writable pointer to the scalar data
  // so we can read data into it.
  switch ( this->ScalarType ) {
  case VTK_SHORT:
    vtkDebugMacro (<< "Creating vtkShortArray");
    shortScalars = vtkShortArray::New();
    shortScalars->SetNumberOfTuples(numPts);
    shortScalars->SetNumberOfComponents(this->NumTimePoints);    
    shortScalars->Allocate(numPts);
    destData = (void*) shortScalars->WritePointer(0, numPts);
    short_destData = (short *)destData;
    scalars = (vtkDataArray*) shortScalars;
    elementSize = sizeof( short );
    break;
  case VTK_FLOAT:
      vtkDebugMacro (<< "Creating vtkFloatArray of size " << numPts);
    floatScalars = vtkFloatArray::New();
    floatScalars->SetNumberOfTuples(numPts);
    floatScalars->SetNumberOfComponents(this->NumTimePoints);
    floatScalars->Allocate(numPts);
    destData = (void*) floatScalars->WritePointer(0, numPts);
    float_destData = (float *)destData;
    scalars = (vtkDataArray*) floatScalars;
    elementSize = sizeof( float );
    break;
  default:
      vtkErrorMacro(<< "Volume type not supported:" << this->ScalarType);
    return NULL;
  }
  if ( NULL == scalars ) {
    vtkErrorMacro(<< "Couldn't allocate scalars array.");
    return NULL;
  } 

  // For each slice..
  numReadTotal = 0;
  tupleNum = 0;
  for( sliceNumber = 0; 
       sliceNumber < this->DataDimensions[2];
       sliceNumber++ ) {

      numReadSlice = 0;
      
      // Generate the file name.
      sprintf( sliceFileName, "%s_%03d.%s", 
               this->Stem, sliceNumber, this->SliceFileNameExtension );

      // Open the file.
      fp = fopen( sliceFileName, "rb" );
      if( !fp ) {
          vtkErrorMacro(<< "Can't find/open file: " << this->FileName);
          return NULL;
      }

      vtkDebugMacro(<< "\n\n\n\n\n\n\n\n********************\nStarting to read volume data: slice " << sliceNumber << ", from file " << sliceFileName);      
      for ( this->CurTimePoint = 0; this->CurTimePoint < this->NumTimePoints; this->CurTimePoint++)
      {
          // Read in a time point. We need to do this element by element so
          // we can do byte swapping.

          vtkDebugMacro(<< "Starting to read at time point " << this->CurTimePoint);
          // << ", doing a seek past " << this->CurTimePoint * numPts);
          
          // Skip the time points we don't want.
          // this needs to take into account if it's floats or shorts that
          // we're skipping. But it shouldn't be necessary, as the reading
          // increments the file pointer
          //fseek( fp, this->CurTimePoint * numPts, SEEK_SET );

          vtkDebugMacro(<<"About to read. Max Y = " << this->DataDimensions[1] << ", Max X = " << this->DataDimensions[0]);
          tupleNum = 0;
          for( int nY = 0; nY < this->DataDimensions[1]; nY++ ) {
              for( int nX = 0; nX < this->DataDimensions[0]; nX++ ) {
                  
                  if (this->CurTimePoint == 1)
                  {
                      //vtkDebugMacro(<<"tupleNum = " << tupleNum << ", nY = " << nY << ", nX = " << nX);
                  }
                  switch ( this->ScalarType ) {
                  case VTK_SHORT:
                      numRead = vtkFSIO::ReadShort( fp, s );
                      if( 1 != numRead ) {
                          vtkErrorMacro(<< "Error reading a short slice "
                                        << sliceNumber << " x " << nX 
                                        << " y " << nY << endl);
                          return NULL;
                      }
//                      *short_destData++ = s;
                      shortScalars->InsertComponent(tupleNum,this->CurTimePoint,s);
                      break;
                  case VTK_FLOAT:
                      numRead = vtkFSIO::ReadFloat( fp, f );
                      if( 1 != numRead ) {
                          vtkErrorMacro(<< "Error reading a float slice "
                                        << sliceNumber << " x " << nX 
                                        << " y " << nY << endl);
                          return NULL;
                      } else {
                          if (this->CurTimePoint == 1)
                          {
                              //vtkDebugMacro(<<"Read a float: " << f);
                          }
                      }
//                      *float_destData++ = f;
                      floatScalars->InsertComponent(tupleNum,this->CurTimePoint,f);
                      if (this->CurTimePoint == 1)
                      {
                          //vtkDebugMacro(<<"Added float to float_destData");
                      }
                      break;
                  default:
                      vtkErrorMacro(<< "Volume type not supported:" << this->ScalarType);
                      return NULL;
                  }
                  numReadSlice += numRead;
                  numReadTotal += numRead;
                  tupleNum++;
              }
              // too frequent, slows down reading
              //this->UpdateProgress(1.0*numReadTotal/totalPoints);
          }
          
          
          vtkDebugMacro(<<"Done reading for timepoint " << this->CurTimePoint << ", numReadSlice = " << numReadSlice);
      }
      
      // Close the slice file.
      fclose(fp);
      
      if( numReadSlice != numPtsPerSlice ) {
          vtkErrorMacro(<<"Trying to read " <<numPtsPerSlice << " elements "
                        << "for slice " << sliceNumber
                        << ", but only got " << numReadSlice << " of them.");
          scalars->Delete();
          return NULL;
      }
      this->UpdateProgress(1.0*sliceNumber/this->DataDimensions[2]);
  }

  this->SetProgressText("");
  this->UpdateProgress(0.0);
  
  if( numReadTotal != totalPoints) {
    vtkErrorMacro(<<"Trying to read " << numPts*this->NumTimePoints << " elements for volume, "
          << "but only got " << numReadTotal << " of them.");
    scalars->Delete();
    return NULL;
  }

  vtkDebugMacro(<<"Read " << numReadTotal << " total points (numPts = " << numPts << ")\n");
  vtkDebugMacro(<<"Read: Done, got scalars num components = " << scalars->GetNumberOfComponents());
  // return the scalars.
  return scalars;
}

// need to test return values. 0 == failure, 1 == success
int vtkBVolumeReader::ReadVolumeHeader()
{
  FILE *fp;
  char fileName[1024];
  char headerFileName[1024];
  char input[1024];
  char* line;
  float tlr, tla, tls, trr, tra, trs, brr, bra, brs, xr, xa, xs, yr, ya, ys;
  int sliceNumber;
  int numSlices;
  int found = 0;
  int error;
  struct stat fileInfo;

      vtkDebugMacro(<<"\n###############\nReadVolumeHeader\n");

  // If we don't have a stem, file the stem from the file prefix or
  // name we have. If we still don't have one after that, return.
  if( NULL == this->Stem ) { 
    FindStemFromFilePrefixOrFileName();
    if( NULL == this->Stem ) {
      vtkErrorMacro(<< "Couldn't parse file name to find stem." );
      return 0;
    }
  }


  // Guess our scalar type and set the file name extension.
  GuessTypeFromStem();
  if( VTK_VOID == this->ScalarType ) {
    vtkErrorMacro(<< "Couldn't guess scalar type." );
    return 0;
  }
  switch( this->ScalarType ) {
  case VTK_FLOAT:
    SetSliceFileNameExtension( "bfloat" );
    break;
  case VTK_SHORT:
    SetSliceFileNameExtension( "bshort" );
    break;
  default:
      vtkErrorMacro(<< "Unrecognized scalar type: " << this->ScalarType);
    return 0;
    break;
  }


  // Look for a .bhdr file. If we get one, get information from
  // it. Otherwise just use defaults.
  sprintf( headerFileName, "%s.bhdr", this->Stem );
  vtkDebugMacro(<<"ReadVolumeHeader: trying headerFileName %s.bhdr = " << headerFileName);
  fp = fopen( headerFileName, "r" );
  if( NULL != fp ) {

      vtkDebugMacro(<<"ReadVolumeHeader: success opening " << headerFileName);
      
    while( !feof(fp) ){

        // Get a line. Strip newline and skip initial spaces.
        fgets( input, 1024, fp );
        if( input[strlen(input)-1] == '\n' ) {
            input[strlen(input)-1] = '\0';
        }
        line = input;
        while( isspace( (int)(*line) ) ) {
            line++;
        }
        
        // Parse the lines in the file. From here we'll get our x, y,
        // and z dimensions, the number of time points, the z spacing,
        // some other meta data, and information needed to calculate our
        // RASMatrix.
        if( strlen(line) > 0 ) {
            if(strncmp(line, "cols: ", 6) == 0)
                sscanf(line, "%*s %d", &this->DataDimensions[0]);
            else if(strncmp(line, "rows: ", 6) == 0)
                sscanf(line, "%*s %d", &this->DataDimensions[1]);
            else if(strncmp(line, "nslices: ", 9) == 0)
                sscanf(line, "%*s %d", &this->DataDimensions[2]);
            else if(strncmp(line, "n_time_points: ", 15) == 0)
                sscanf(line, "%*s %d", &this->NumTimePoints);
            else if(strncmp(line, "slice_thick: ", 13) == 0)
            {
                // check for a floating point
                if (strstr(line, ".") == NULL) {
                    int ds2;
                    sscanf(line, "%*s %d", &ds2);
                    this->DataSpacing[2] = (float)ds2;
                } else {
                  // To support VTK4.2/VTK4.4
                  float z;
                  sscanf(line, "%*s %f", &z);
                  this->DataSpacing[2] = z;
                }
                vtkDebugMacro(<<"vtkBVolumeReader: Read Volume Header: got slice thickness " << this->DataSpacing[2]);
            }
            else if(strncmp(line, "image_te: ", 10) == 0)
                sscanf(line, "%*s %f", &this->TE);
            else if(strncmp(line, "image_tr: ", 10) == 0)
                sscanf(line, "%*s %f", &this->TR);
            else if(strncmp(line, "image_ti: ", 10) == 0)
                sscanf(line, "%*s %f", &this->TI);
            else if(strncmp(line, "flip_angle: ", 10) == 0)
                sscanf(line, "%*s %f", &this->FlipAngle);
            else if(strncmp(line, "top_left_r: ", 12) == 0)
            {
                sscanf(line, "%*s %g", &tlr);
                this->TopL[0] = tlr;
            }
            else if(strncmp(line, "top_left_a: ", 12) == 0)
            {
                sscanf(line, "%*s %g", &tla);
                this->TopL[1] = tla;
            }
            else if(strncmp(line, "top_left_s: ", 12) == 0)
            {
                sscanf(line, "%*s %g", &tls);
                this->TopL[2] = tls;
            }
            else if(strncmp(line, "top_right_r: ", 13) == 0)
            {
                sscanf(line, "%*s %g", &trr);
                this->TopR[0] = trr;
            }
            else if(strncmp(line, "top_right_a: ", 13) == 0)
            {
                sscanf(line, "%*s %g", &tra);
                this->TopR[1] = tra;
            }
            else if(strncmp(line, "top_right_s: ", 13) == 0)
            {
                sscanf(line, "%*s %g", &trs);
                this->TopR[2] = trs;
            }
            else if(strncmp(line, "bottom_right_r: ", 16) == 0)
            {
                sscanf(line, "%*s %g", &brr);
                this->BottomR[0] = brr;
            }
            else if(strncmp(line, "bottom_right_a: ", 16) == 0)
            {
                sscanf(line, "%*s %g", &bra);
                this->BottomR[1] = bra;
            }
            else if(strncmp(line, "bottom_right_s: ", 16) == 0)
            {
                sscanf(line, "%*s %g", &brs);
                this->BottomR[2] = brs;
            }
            else if(strncmp(line, "normal_r: ", 10) == 0)
            {
                sscanf(line, "%*s %g", &this->RASMatrix[6]);
                this->Normal[0] = this->RASMatrix[6];
            }
            else if(strncmp(line, "normal_a: ", 10) == 0)
            {
                sscanf(line, "%*s %g", &this->RASMatrix[7]);
                this->Normal[1] = this->RASMatrix[7];
            }
            else if(strncmp(line, "normal_s: ", 10) == 0)
            {
                sscanf(line, "%*s %g", &this->RASMatrix[8]);
                this->Normal[2] = this->RASMatrix[8];
            }
        }
    }
    fclose( fp );

    // Use the RASMatrix information to calculate the x and y spacing.
    xr = (trr - tlr) / (float)this->DataDimensions[0];
    xa = (tra - tla) / (float)this->DataDimensions[0];
    xs = (trs - tls) / (float)this->DataDimensions[0];
    this->DataSpacing[0] = sqrt(xr*xr + xa*xa + xs*xs);
    this->RASMatrix[0] = xr / (float)this->DataSpacing[0];
    this->RASMatrix[1] = xa / (float)this->DataSpacing[0];
    this->RASMatrix[2] = xs / (float)this->DataSpacing[0];
    
    yr = (brr - trr) / (float)this->DataDimensions[1];
    ya = (bra - tra) / (float)this->DataDimensions[1];
    ys = (brs - trs) / (float)this->DataDimensions[1];
    this->DataSpacing[1] = sqrt(yr*yr + ya*ya + ys*ys);
    this->RASMatrix[3] = yr / (float)this->DataSpacing[1];
    this->RASMatrix[4] = ya / (float)this->DataSpacing[1];
    this->RASMatrix[5] = ys / (float)this->DataSpacing[1];


    // Try to open the header for slice 0. Read only the number of
    // time points out of it. This should override the value in bhdr
    // if it wants. It's in the file format spec, really.
    vtkDebugMacro(<<"Trying to open the header for slice 0.");
    
    sprintf( headerFileName, "%s_000.hdr", this->Stem );
    fp = fopen( headerFileName, "r" );
    if( NULL == fp ) {
        vtkErrorMacro(<< "Couldn't open header for slice 000:" << headerFileName );
        return 0;
    }
    fscanf(fp, "%*d %*d %d %*d", &this->NumTimePoints);
    fclose(fp);

  } else {
      // No .bhdr file, so we'll get our info from the number of slice
      // files and a .hdr file from one of the slices.
      
      // Try to open the header for slice 0. Read in the x dimension, y
      // dimension, and number of time points.

      sprintf( headerFileName, "%s_000.hdr", this->Stem );
      vtkDebugMacro(<<"\nReadVolumeHeader: no STEM.bhdr file, looking for slice hdr files, trying " << headerFileName << " first\n");
      fp = fopen( headerFileName, "r" );
      if( NULL == fp ) {
          vtkErrorMacro(<< "\nReadVolumeHeader: Couldn't open header for slice 000: " << headerFileName );
          return 0;
      }
      fscanf(fp, "%d %d %d %*d", &this->DataDimensions[0],
             &this->DataDimensions[1], &this->NumTimePoints);
      fclose(fp);
      
      // Look for all the slice files. Start at slice 000 and try to
      // open each one. Find as many as we can. This will be our z
      // dimension.
      numSlices = 0;
      sliceNumber = 0;
      while( found ) {
          found = 0;
          sprintf( fileName, "%s_%03d.%s", 
                   this->Stem, sliceNumber, this->SliceFileNameExtension );
          error = stat( fileName, &fileInfo );
          if( !error ) {
              if( S_ISREG( fileInfo.st_mode ) ) {
                  found = 1;
                  numSlices++;
                  sliceNumber++;
              }
          }
          else
          {
              vtkDebugMacro(<<"\nReadVolumeHeader: error in stating file " << fileName);
          }
      }
      this->DataDimensions[2] = numSlices;
      vtkDebugMacro(<<"\n*\n*\n*\n*\n*\n*\n*\n*\nReadVolumeHeader: got numSlices = " << numSlices << ", using it as DataDimensions[2]\nSetting Dataspacing to be 1, 1, 1\n");
      
      // We don't have any spacing information, so assign defaults.
      this->DataSpacing[0] = 1.0;
      this->DataSpacing[1] = 1.0;
      this->DataSpacing[2] = 1.0;
  }
  vtkDebugMacro(<<"*\n*\n*\nReadVolumeHeader: done\n\tData dimensions = (" << this->DataDimensions[0] << ", "   << this->DataDimensions[1] << ", " << this->DataDimensions[2] << ")\n\tData Spacing: (" << this->DataSpacing[0] << ", " << this->DataSpacing[1] << ", " << this->DataSpacing[2] << ")\n");
  
  return 1;
}

void vtkBVolumeReader::FindStemFromFilePrefixOrFileName() {

  struct stat fileInfo;
  int error;
  char *slash, *dot, *stemStart, *underscore;
  int underscoreIndex;
  int stemLength;
  char fileName[1024];
  char directory[1024];
  char stem[1024];

  vtkDebugMacro(<<"FindStemFromFilePrefixOrFileName\n");
  
  // We want to get the this->Stem, which is the 'stem' of the file
  // name. We'll look in FilePrefix and FileName. Is FilePrefix is set
  // and is a valid stem, great, use that. If we don't have a
  // FilePrefix or it's not a valid stem, try to calc the stem from
  // the FilePrefix or FileName. (FileName up until underscore in the
  // case of /path/to/data/stem_001.bfloat or
  // /path/to/data/stem_001.hdr, or FileName up until last dot in the
  // case of /path/to/data/stem.bhdr).

  if( NULL != this->FilePrefix || 
      (0 == strlen( this->FilePrefix )) ) {
    // If this is a valid stem, we can find stem_000.bfloat or
    // stem_000.bshort.
    sprintf( fileName, "%s_000.bfloat", fileName );
    error = stat( fileName, &fileInfo );
    if( !error ) {
      if( S_ISREG( fileInfo.st_mode ) ) {
    SetStem( this->FilePrefix );
    return;
      }
    }
    sprintf( fileName, "%s_000.bshort", fileName );
    error = stat( fileName, &fileInfo );
    if( !error ) {
      if( S_ISREG( fileInfo.st_mode ) ) {
    SetStem( this->FilePrefix );
    return;
      }
    }
  }

  //  Options for FileName or FilePrefix (where xxx is a number):
  //  stem_xxx.bshort  or  stem_xxx.bfloat
  //  stem_xxx
  //  stem_.bshort     or  stem_.bfloat
  //  stem_
  //  stem.bshort      or  stem.bfloat
  //  stem
  //  with or without a preceding directory.

  // Use FilePrefix, or Filename.
  if( NULL != this->FilePrefix ) {
    strcpy( fileName, this->FilePrefix );
  } else  if( NULL != this->FileName ) {
    strcpy( fileName, this->FileName );
  } else {
    vtkErrorMacro(<< "Neither FilePrefix nor FileName set");
    return;
  }

  // Find the last slash. If we get one, mark the next character as
  // the beginning of the string. Otherwise, use the first char in the
  // string.
  slash = strrchr( fileName, '/' );
  if( NULL == slash ) {

    // Copy . into the directory.
    stemStart = fileName;
    sprintf( directory, "." );

  } else {

    // Set the slash to null char. Copy everything up to there as the
    // directory.
    *slash = '\0';
    strcpy( directory, fileName );  
    stemStart = slash + 1;
  }

  // If the stem is a null char, file name is no good.
  if( *stemStart == '\0' ) {
    vtkErrorMacro(<< "Bad file name: " << this->FileName );
    return;
  }

  // Find the last dot, then look at the extension. If it's bshort or
  // bfloat, set it to a null char. This clips the stem part at the
  // end of the stem.
  dot = strrchr( fileName, '.' );
  if( NULL != dot ) {
    if( strcmp(dot, ".bshort") == 0 || strcmp(dot, ".bfloat") == 0) {
      *dot = '\0';
    }
  }

  // Find the last underscore. If we didn't get one, then just the
  // region betwen the stem start and the dot (which we set to null)
  // is the stem. If we did get it, and it's actually the underscore
  // between the stem and the dot, set it to null, then copy the stem.
  underscore = strrchr( fileName, '_' );
  if( NULL != underscore ) {

    stemLength = strlen( stemStart );
    underscoreIndex = (underscore - stemStart);
    if( underscoreIndex == stemLength - 1 || 
    underscoreIndex == stemLength - 4 ) {
      *underscore = '\0';
    }
  }

  // Copy the directory and stem into the FilePrefix.
  sprintf( stem, "%s/%s", directory, stemStart );
  SetStem( stem );
}

void vtkBVolumeReader::GuessTypeFromStem() {

  char stem[1024];
  char testFileName[1024];
  char* dot;
  struct stat fileInfo;
  int error;

    vtkDebugMacro(<<"GuessTypeFromStem\n");

  //  Options for FileName (where xxx is a number):
  //  stem_xxx.bshort  or  stem_xxx.bfloat
  //  stem_xxx
  //  stem_.bshort     or  stem_.bfloat
  //  stem_
  //  stem.bshort      or  stem.bfloat
  //  stem
  //  with or without a preceding directory.

  // Make sure have the stem.
  if( NULL == this->Stem ||
      0 == strlen( this->Stem ) ) {
    FindStemFromFilePrefixOrFileName();
    if( NULL == this->Stem ||
    0 == strlen( this->Stem ) ) {
      vtkErrorMacro(<< "Couldn't find stem.");
      this->ScalarType = VTK_VOID;
      return;
    }
  }

  strcpy( stem, this->Stem );

  // First look for a .bfloat or .bshort extension. If we find it, set
  // the type and return. If not, just go down the other line of
  // possibilities until we get a hit.
  dot = strrchr( stem, '.' );
  if( NULL != dot ) {
    if( strcmp( dot, ".bfloat" ) ) {
      this->ScalarType = VTK_FLOAT;
      return;
    } 
    if( strcmp( dot, ".bshort" ) ) {
      this->ScalarType = VTK_SHORT;
      return;
    }
  }


  // Next append a .bfloat or .bshort to the FileName and look for that.
  sprintf( testFileName, "%s.bfloat", stem );
  error = stat( testFileName, &fileInfo );
  if( !error ) {
    if( S_ISREG( fileInfo.st_mode ) ) {
      this->ScalarType = VTK_FLOAT;
      return;
    }
  }
  sprintf( testFileName, "%s.bshort", stem );
  error = stat( testFileName, &fileInfo );
  if( !error ) {
    if( S_ISREG( fileInfo.st_mode ) ) {
      this->ScalarType = VTK_SHORT;
      return;
    }
  }

  // Next append 000.bfloat and 000.bshort and look for that.
  sprintf( testFileName, "%s000.bfloat", stem );
  error = stat( testFileName, &fileInfo );
  if( !error ) {
    if( S_ISREG( fileInfo.st_mode ) ) {
      this->ScalarType = VTK_FLOAT;
      return;
    }
  }
  sprintf( testFileName, "%s000.bshort", stem );
  error = stat( testFileName, &fileInfo );
  if( !error ) {
    if( S_ISREG( fileInfo.st_mode ) ) {
      this->ScalarType = VTK_SHORT;
      return;
    }
  }

  // Finally append _000.bfloat and _000.bshort and look for that.
  sprintf( testFileName, "%s_000.bfloat", stem );
  error = stat( testFileName, &fileInfo );
  if( !error ) {
    if( S_ISREG( fileInfo.st_mode ) ) {
      this->ScalarType = VTK_FLOAT;
      return;
    }
  }
  sprintf( testFileName, "%s_000.bshort", stem );
  error = stat( testFileName, &fileInfo );
  if( !error ) {
    if( S_ISREG( fileInfo.st_mode ) ) {
      this->ScalarType = VTK_SHORT;
      return;
    }
  }

  vtkErrorMacro(<< "Couldn't find stem:" << stem);
  this->ScalarType = VTK_VOID;
}

void vtkBVolumeReader::PrintSelf(ostream& os, vtkIndent indent)
{
       vtkDebugMacro(<<"PrintSelf\n");

  vtkVolumeReader::PrintSelf( os, indent );

  if (this->FileName)
  {
      os << indent << "File Name: " << this->FileName << endl;
  }
  else
  {
      os << indent << "File Name: NULL" << endl;
  }

  if (this->RegistrationFileName)
  {
      os << indent << "Registration File Name: " << this->RegistrationFileName << endl;
  }
  else
  {
      os << indent << "Registration File Name: NULL" << endl;
  }

  if (this->SliceFileNameExtension)
  {
      os << indent << "Slice File Name Extension: " << this->SliceFileNameExtension << endl;
  }
  else
  {
      os << indent << "Slice File NameExtension: NULL" << endl;
  }
  
  if (this->Stem)
  {
      os << indent << "Stem: " << this->Stem << endl;
  }
  else
  {
      os << indent << "Stem: NULL " << endl;
  }
  
  os << indent << "Data Dimensions: (" << this->DataDimensions[0] << ", "
     << this->DataDimensions[1] << ", " << this->DataDimensions[2] << ")\n";
  os << indent << "Data Spacing: (" << this->DataSpacing[0] << ", "
     << this->DataSpacing[1] << ", " << this->DataSpacing[2] << ")\n";
  os << indent << "Scalar type: " << this->ScalarType << endl;
  os << indent << "Number of time points: " << this->NumTimePoints << endl;
  os << indent << "Current time point: " << this->CurTimePoint << endl;

  //os << indent << "RAS Matrix: " << this->RASMatrix << endl;
  os << indent << "RAS to IJK matrix: " << endl;
  os << indent << "\tx_r " << this->RASMatrix[0] << "\t\tx_a " << this->RASMatrix[1] << "\t\tx_s " << this->RASMatrix[2] << endl;
  os << indent << "\ty_r " << this->RASMatrix[3] << "\t\ty_a " << this->RASMatrix[4] << "\t\ty_s " << this->RASMatrix[5] << endl;
  os << indent << "\tz_r " << this->RASMatrix[6] << "\t\tz_a " << this->RASMatrix[7] << "\t\tz_s " << this->RASMatrix[8] << endl;
  os << indent << "\tc_r " << this->RASMatrix[9] << "\tc_a " << this->RASMatrix[10] << "\tc_s " << this->RASMatrix[11] << endl;
  
  os << indent << "Registration Matrix: " << endl;
  if (this->RegistrationMatrix)
  {
      this->RegistrationMatrix->PrintSelf(os, indent);
  }
  else
  {
      os << indent << "NULL" << endl;
  }
  
  os << indent << "Meta data: TE " << this->TE << ", TR " << this->TR << ", TI " << this->TI << ", Flip angle " << this->FlipAngle << endl;

  os << indent << "Top Left corner: " << this->TopL[0] << ", " << this->TopL[1] << ", " << this->TopL[2] << endl;
  os << indent << "Top Right corner: " << this->TopR[0] << ", " << this->TopR[1] << ", " << this->TopR[2] << endl;
  os << indent << "Bottom Right corner: " << this->BottomR[0] << ", " << this->BottomR[1] << ", " << this->BottomR[2] << endl;
  os << indent << "Normal: " << this->Normal[0] << ", " << this->Normal[1] << ", " << this->Normal[2] << endl;

  
}
