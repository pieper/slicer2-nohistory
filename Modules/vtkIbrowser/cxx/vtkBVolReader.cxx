/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBVolReader.cxx,v $
  Date:      $Date: 2006/05/26 19:41:32 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include <sys/types.h>
#include <sys/stat.h>
#include <ctype.h>
#ifdef _WIN32 // WINDOWS
#define S_ISREG(m)  (((m)&_S_IFMT) == _S_IFREG)
#else
#include <unistd.h>
#endif
#include "vtkBVolReader.h"
#include "vtkShortArray.h"
#include "vtkUnsignedCharArray.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkObjectFactory.h"
#include "vtkIbrowserIO.h"

//--------------------------------------------------------------------------------------
vtkBVolReader* vtkBVolReader::New()
{
    // First try to create the object from the vtkObjectFactory
    vtkObject* ret = vtkObjectFactory::CreateInstance("vtkBVolReader");
    if(ret)
        {
            return (vtkBVolReader*)ret;
        }
    // If the factory was unable to create the object, then create it here.
    return new vtkBVolReader;
}


//--------------------------------------------------------------------------------------
vtkBVolReader::vtkBVolReader()
{
    this->DataDimensions[0] = 
        this->DataDimensions[1] = 
        this->DataDimensions[2] = 0;
    this->FileName = NULL;
    this->DirName = NULL;
    this->Stem = NULL;
    this->RegistrationFileName = NULL;
    this->SliceFileNameExtension = NULL;
    this->RegistrationMatrix = NULL;
    this->ScalarType = 0;
    this->NumTimePoints = 0;
    this->CurTimePoint = 0;
}


//--------------------------------------------------------------------------------------
vtkBVolReader::~vtkBVolReader()
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
    if (NULL == this->RegistrationMatrix) {
        this->RegistrationMatrix->Delete();
    }
}


//--------------------------------------------------------------------------------------
void vtkBVolReader::ExecuteInformation()
{
    vtkImageData *output = this->GetOutput();
  
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
    
    
//--------------------------------------------------------------------------------------
void vtkBVolReader::Execute()
{
    vtkImageData *output = this->GetOutput();

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
            output->GetPointData()->SetScalars(newScalars);
            newScalars->Delete();
        }
}



//--------------------------------------------------------------------------------------
vtkImageData *vtkBVolReader::GetImage(int ImageNumber)
{
    cerr << "vtkBVolReader::GetImage() called. uh oh." << endl;
    return NULL;
}



//--------------------------------------------------------------------------------------
vtkMatrix4x4 *vtkBVolReader::GetRegistrationMatrix()
{
    struct stat fileInfo;
    int error;
    FILE* fp;
    float m[4][4];
    int i;
    int j;

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
            vtkErrorMacro(<< "Coudn't open file " << this->RegistrationFileName );
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


//--------------------------------------------------------------------------------------
vtkDataArray *vtkBVolReader::ReadVolumeData()
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
    int numReadTotal;
    int numReadSlice;
    int elementSize;
    short s;
    float f;

    // Read header first.
    this->ReadVolumeHeader();

    // Check the prefix.
    if( NULL == this->Stem || 
        (0 == strlen( this->Stem )) ) {
        vtkErrorMacro( << "No file prefix specified" );
        return NULL;
    }

    // Calc the number of values.
    numPts = this->DataDimensions[0] * 
        this->DataDimensions[1] * 
        this->DataDimensions[2];
    numPtsPerSlice = this->DataDimensions[0] * 
        this->DataDimensions[1];

    // Create the scalar array for the volume. Set the element size for
    // the data we will read. Get a writable pointer to the scalar data
    // so we can read data into it.
    switch ( this->ScalarType ) {
    case VTK_SHORT:
        shortScalars = vtkShortArray::New();
        shortScalars->Allocate(numPts);
        destData = (void*) shortScalars->WritePointer(0, numPts);
        short_destData = (short *)destData;
        scalars = (vtkDataArray*) shortScalars;
        elementSize = sizeof( short );
        break;
    case VTK_FLOAT:
        floatScalars = vtkFloatArray::New();
        floatScalars->Allocate(numPts);
        destData = (void*) floatScalars->WritePointer(0, numPts);
        float_destData = (float *)destData;
        scalars = (vtkDataArray*) floatScalars;
        elementSize = sizeof( float );
        break;
    default:
        vtkErrorMacro(<< "Volume type not supported.");
        return NULL;
    }
    
    if ( NULL == scalars ) {
        vtkErrorMacro(<< "Couldn't allocate scalars array.");
        return NULL;
    } 

    // For each slice..
    numReadTotal = 0;
    for( sliceNumber = 0; sliceNumber < this->DataDimensions[2]; sliceNumber++ ) {

        numReadSlice = 0;

        // Generate the file name.
        sprintf( sliceFileName, "%s_%03d.%s", 
                 this->FilePrefix, sliceNumber, this->SliceFileNameExtension );
        
        // Open the file.
        fp = fopen( sliceFileName, "rb" );
        if( !fp ) {
            vtkErrorMacro(<< "Can't find/open file: " << sliceFileName);
            return NULL;
        }

        // Read in a time point. We need to do this element by element so
        // we can do byte swapping.
        // Skip the time points we don't want.
        fseek( fp, this->CurTimePoint * numPts, SEEK_SET );

        for( int nY = 0; nY < this->DataDimensions[1]; nY++ ) {
            for( int nX = 0; nX < this->DataDimensions[0]; nX++ ) {
                switch ( this->ScalarType ) {
                case VTK_SHORT:
                    numRead = vtkIbrowserIO::ReadShort( fp, s );
                    if( 1 != numRead ) {
                        vtkErrorMacro(<< "Error reading a short slice "
                                      << sliceNumber << " x " << nX 
                                      << " y " << nY << endl);
                        return NULL;
                    }
                    *short_destData++ = s;
                    break;
                case VTK_FLOAT:
                    numRead = vtkIbrowserIO::ReadFloat( fp, f );
                    if( 1 != numRead ) {
                        vtkErrorMacro(<< "Error reading a float slice "
                                      << sliceNumber << " x " << nX 
                                      << " y " << nY << endl);
                        return NULL;
                    }
                    *float_destData++ = f;
                    break;
                default:
                    vtkErrorMacro(<< "Volume type not supported.");
                    return NULL;
                }
                numReadSlice += numRead;
                numReadTotal += numRead;
            }
        }

        if( numReadSlice != numPtsPerSlice ) {
            vtkErrorMacro(<<"Trying to read " << numPtsPerSlice << " elements "
                          << "for slice " << sliceNumber
                          << ", but only got " << numReadSlice << " of them.");
            scalars->Delete();
            return NULL;
        }
        vtkDebugMacro(<< "Read in " << sliceFileName);
        // Close the file.
        fclose(fp);

    }
  
    if( numReadTotal != numPts ) {
        vtkErrorMacro(<<"Trying to read " << numPts << " elements for volume, "
                      << "but only got " << numRead << " of them.");
        scalars->Delete();
        return NULL;
    }

    // return the scalars.
    return scalars;
}



//--------------------------------------------------------------------------------------
void vtkBVolReader::ReadVolumeHeader()
{
    FILE *fp;
    char fileName[1024];
    char headerFileName[1024];
    char input[1024];
    char* line;
    float tlr, tla, tls, trr, tra, trs, brr, bra, brs, xr, xa, xs, yr, ya, ys;
    int sliceNumber;
    int numSlices;
    int found;
    int error;
    struct stat fileInfo;

    // If we don't have a stem, file the stem from the file prefix or
    // name we have. If we still don't have one after that, return.
    if( NULL == this->Stem ) { 
        FindStemFromFilePrefixOrFileName();
        if( NULL == this->Stem ) {
            vtkErrorMacro(<< "Couldn't parse file name to find stem." );
            return;
        }
    }

    // Guess our scalar type and set the file name extension.
    GuessTypeFromStem();
    if( VTK_VOID == this->ScalarType ) {
        vtkErrorMacro(<< "Couldn't guess scalar type." );
        return;
    }
    switch( this->ScalarType ) {
    case VTK_FLOAT:
        SetSliceFileNameExtension( "bfloat" );
        break;
    case VTK_SHORT:
        SetSliceFileNameExtension( "bshort" );
        break;
    default:
        vtkErrorMacro(<< "Unrecognized scalar type." );
        return;
        break;
    }
    
    // Look for a .bhdr file or a .hdr file. If we get one, 
    // extract info from it. Otherwise just use defaults.
    sprintf( headerFileName, "%s%s.bhdr", this->DirName, this->Stem );
  
    fp = fopen( headerFileName, "r" );
    if( NULL != fp ) {

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
                    sscanf(line, "%*s %f", &this->DataSpacing[2]);
                else if(strncmp(line, "image_te: ", 10) == 0)
                    sscanf(line, "%*s %f", &this->TE);
                else if(strncmp(line, "image_tr: ", 10) == 0)
                    sscanf(line, "%*s %f", &this->TR);
                else if(strncmp(line, "image_ti: ", 10) == 0)
                    sscanf(line, "%*s %f", &this->TI);
                else if(strncmp(line, "flip_angle: ", 10) == 0)
                    sscanf(line, "%*s %lf", &this->FlipAngle);
                else if(strncmp(line, "top_left_r: ", 12) == 0)
                    sscanf(line, "%*s %g", &tlr);
                else if(strncmp(line, "top_left_a: ", 12) == 0)
                    sscanf(line, "%*s %g", &tla);
                else if(strncmp(line, "top_left_s: ", 12) == 0)
                    sscanf(line, "%*s %g", &tls);
                else if(strncmp(line, "top_right_r: ", 13) == 0)
                    sscanf(line, "%*s %g", &trr);
                else if(strncmp(line, "top_right_a: ", 13) == 0)
                    sscanf(line, "%*s %g", &tra);
                else if(strncmp(line, "top_right_s: ", 13) == 0)
                    sscanf(line, "%*s %g", &trs);
                else if(strncmp(line, "bottom_right_r: ", 16) == 0)
                    sscanf(line, "%*s %g", &brr);
                else if(strncmp(line, "bottom_right_a: ", 16) == 0)
                    sscanf(line, "%*s %g", &bra);
                else if(strncmp(line, "bottom_right_s: ", 16) == 0)
                    sscanf(line, "%*s %g", &brs);
                else if(strncmp(line, "normal_r: ", 10) == 0)
                    sscanf(line, "%*s %g", &this->RASMatrix[6]);
                else if(strncmp(line, "normal_a: ", 10) == 0)
                    sscanf(line, "%*s %g", &this->RASMatrix[7]);
                else if(strncmp(line, "normal_s: ", 10) == 0)
                    sscanf(line, "%*s %g", &this->RASMatrix[8]);
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
        sprintf( headerFileName, "%s%s_000.hdr", this->DirName, this->Stem );

        fp = fopen( headerFileName, "r" );
        if( NULL == fp ) {
            vtkErrorMacro(<< "ReadVolumeHeader: Couldn't open header for slice 000." );
            return;
        }
        fscanf(fp, "%*d %*d %d %*d", &this->NumTimePoints);
        fclose(fp);

    } else {
        
        // No .bhdr file, so we'll get our info from the number of slice
        // files and a .hdr file from one of the slices.
  
        // Try to open the header for slice 0. Read in the x dimension, y
        // dimension, and number of time points.
        sprintf( headerFileName, "%s/%s_000.hdr", this->DirName, this->Stem );

        fp = fopen( headerFileName, "r" );
        if( NULL == fp ) {
            vtkErrorMacro(<< "ReadVolumeHeader: Couldn't open header for slice 000." );
            return;
        }
        fscanf(fp, "%d %d %d %*d", &this->DataDimensions[0],
               &this->DataDimensions[1], &this->NumTimePoints);
        fclose(fp);

        // Look for all the slice files. Start at slice 000 and try to
        // open each one. Find as many as we can. This will be our z
        // dimension.
        numSlices = 0;
        sliceNumber = 0;
        found = 1;
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
        }
        this->DataDimensions[2] = numSlices;

        // We don't have any spacing information, so assign defaults.
        this->DataSpacing[0] = 1.0;
        this->DataSpacing[1] = 1.0;
        this->DataSpacing[2] = 1.0;
    }

}



//--------------------------------------------------------------------------------------
void vtkBVolReader::FindStemFromFilePrefixOrFileName() {

    struct stat fileInfo;
    int error;
    char *slash, *dot, *stemStart, *underscore;
    char fileName[1024];
    char directory[1024];
    char tmpdir[1024];
    char stem[1024];
    char tmpstem [1024];

    // We want to get the this->Stem, which is the 'stem' of the file
    // name. We'll look in FilePrefix and FileName. Is FilePrefix is set
    // and is a valid stem, great, use that. If we don't have a
    // FilePrefix or it's not a valid stem, try to calc the stem from
    // the FilePrefix or FileName. (FileName up until underscore in the
    // case of /path/to/data/stem_001.bfloat or
    // /path/to/data/stem_001.hdr, or FileName up until last dot in the
    // case of /path/to/data/stem.bhdr).

    if( (NULL != this->FilePrefix) &&  (0 != strlen( this->FilePrefix )) ) {
        // If this is a valid stem, we'll be able to find
        // stem_000.bfloat or stem_000.bshort: looking...
        sprintf( fileName, "%s_000.bfloat", this->FilePrefix );
        error = stat( fileName, &fileInfo );
        if( !error ) {
            if( S_ISREG( fileInfo.st_mode ) ) {
                SetStem( this->FilePrefix );
                return; }
        }
        sprintf( fileName, "%s_000.bshort", this->FilePrefix );
        error = stat( fileName, &fileInfo );
        if( !error ) {
            if( S_ISREG( fileInfo.st_mode ) ) {
                SetStem( this->FilePrefix );
                return; }
        }
    } else 


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
        vtkErrorMacro(<< "oops, neither FilePrefix nor FileName set");
        return;
    }

    // Find the last slash. If we get one, mark the next character as
    // the beginning of the fileName. Otherwise, use the first char in the
    // string as the beginning of the fileName.
    slash = strrchr( fileName, '/' );
    
    if( NULL == slash ) {
        // no '/' exists in fileName
        // so put stem pointer at
        // beginning of fileName and
        // copy . into the directory.
        stemStart = fileName;
        sprintf( tmpdir, "." );

    } else {
        // mark the stem pointer to the char just after the '/'
        stemStart = slash + 1;
        strcpy(tmpstem, stemStart);
        stemStart = slash + 1;
        // Then set the slash to null char.
        // Copy everything up to null char as the directory.
        *slash = '\0';
        strcpy( tmpdir, fileName );  
    }
    sprintf(directory, "%s/", tmpdir);

    // If the stem is a null char, file name is no good.
    if( *stemStart == '\0' ) {
        vtkErrorMacro(<< "Bad file name: " << this->FileName );
        return;
    }

    // Find the last dot, then look at the extension. If it's bshort or
    // bfloat, or bhdr or hdr, set it to a null char. This clips the stem
    // part at the end of the string.
    dot = strrchr( tmpstem, '.' );
    if( NULL != dot ) {
        if( strcmp(dot, ".bshort") == 0 || strcmp(dot, ".bfloat") == 0 ||
            strcmp(dot, ".bhdr") == 0 || (strcmp(dot, ".hdr")==0) ) {
            *dot = '\0';
        }
    }

    // Find the last underscore. If we didn't get one, then just the
    // region betwen the stem start and the dot (which we set to null)
    // is the stem. If we did get it, and it's actually the underscore
    // between the stem and the dot, set it to null, then copy the stem.
    underscore = strrchr( tmpstem, '_' );
    if( NULL != underscore ) {
        *underscore = '\0';
    }
    strcpy(stem, tmpstem);    
    
    
    // Copy the directory and stem into the FilePrefix.
    sprintf( tmpstem, "%s%s", directory, stem );
    SetFilePrefix( tmpstem );
    SetStem( stem );
    SetDirName( directory );

}



//--------------------------------------------------------------------------------------
void vtkBVolReader::GuessTypeFromStem() {

    char stem[1024];
    char testFileName[1024];
    char* dot;
    struct stat fileInfo;
    int error;

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

    strcpy( stem, this->FilePrefix );

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

    vtkErrorMacro(<< "Couldn't find stem.");
    this->ScalarType = VTK_VOID;
}


//--------------------------------------------------------------------------------------
void vtkBVolReader::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkVolumeReader::PrintSelf( os, indent );

    os << indent << "Data Dimensions: (" << this->DataDimensions[0] << ", "
       << this->DataDimensions[1] << ", " << this->DataDimensions[2] << ")\n";
    os << indent << "Data Spacing: (" << this->DataSpacing[0] << ", "
       << this->DataSpacing[1] << ", " << this->DataSpacing[2] << ")\n";
    os << indent << "Scalar type: " << this->ScalarType << endl;
    os << indent << "Number of time points: " << this->NumTimePoints << endl;
    os << indent << "Current time point: " << this->CurTimePoint << endl;
}
