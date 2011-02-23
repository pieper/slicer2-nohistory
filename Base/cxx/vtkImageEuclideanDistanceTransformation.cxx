/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageEuclideanDistanceTransformation.cxx,v $
  Date:      $Date: 2006/01/06 17:56:41 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkImageEuclideanDistanceTransformation.cxx,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:56:41 $
  Version:   $Revision: 1.9 $
  Thanks:    Olivier Cuisenaire who developed this class
             URL: http://ltswww.epfl.ch/~cuisenai
         Email: Olivier.Cuisenaire@epfl.ch

Copyright (c)  Olivier Cuisenaire

This software is copyrighted by Ken Martin, Will Schroeder and Bill Lorensen.
The following terms apply to all files associated with the software unless
explicitly disclaimed in individual files. This copyright specifically does
not apply to the related textbook "The Visualization Toolkit" ISBN
013199837-4 published by Prentice Hall which is covered by its own copyright.

The authors hereby grant permission to use, copy, and distribute this
software and its documentation for any purpose, provided that existing
copyright notices are retained in all copies and that this notice is included
verbatim in any distributions. Additionally, the authors grant permission to
modify this software and its documentation for any purpose, provided that
such modifications are not distributed without the explicit consent of the
authors and that existing copyright notices are retained in all copies. Some
of the algorithms implemented by this software are patented, observe all
applicable patent law.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON AN
"AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


=========================================================================*/
#include <math.h>
// #include "vtkImageCache.h"
#include "vtkImageEuclideanDistanceTransformation.h"


//----------------------------------------------------------------------------
// This defines the default values for the EDT parameters 
vtkImageEuclideanDistanceTransformation::vtkImageEuclideanDistanceTransformation()
{
  this->MaximumDistance = VTK_INT_MAX;
  this->Initialize = 1;
  this->ConsiderAnisotropy = 1;
}

//----------------------------------------------------------------------------
// This extent of the components changes to real and imaginary values.
void vtkImageEuclideanDistanceTransformation::ExecuteInformation(vtkImageData *input, vtkImageData *output)
{
  output->SetNumberOfScalarComponents(1);
  output->SetScalarType(VTK_FLOAT);
}

//----------------------------------------------------------------------------
// This method tells the superclass that the whole input array is needed
// to compute any output region.
void vtkImageEuclideanDistanceTransformation::ComputeInputUpdateExtent(int inExt[6], 
                           int outExt[6])
{
  int *extent;
  
  // Assumes that the input update extent has been initialized to output ...
  extent = this->GetInput()->GetWholeExtent();
  memcpy(inExt, outExt, 6 * sizeof(int));
  inExt[this->Iteration*2] = extent[this->Iteration*2];
  inExt[this->Iteration*2 + 1] = extent[this->Iteration*2 + 1];
}

//----------------------------------------------------------------------------
// This templated execute method handles any type input, but the output
// is always floats.
template <class T>
/* static */
void vtkImageEuclideanDistanceTransformationExecute(vtkImageEuclideanDistanceTransformation *self,
             vtkImageData *inData, int inExt[6], T *inPtr,
             vtkImageData *outData, int outExt[6], float *outPtr,
             int id)
{

  int inMin0, inMax0;
  int inInc0, inInc1, inInc2;
  T *inPtr0, *inPtr1, *inPtr2;
  //
  int outMin0, outMax0, outMin1, outMax1, outMin2, outMax2;
  int outInc0, outInc1, outInc2;
  float *outPtr0, *outPtr1, *outPtr2;
  //
  int idx0, idx1, idx2, inSize0;
  // int numberOfComponents;
  unsigned long count = 0;
  //  unsigned long target;
  float maxDist;

  float *sq;
  float *buff,buffer;
  int df,a,b,n;
  float m;

  float spacing,spacing2;

  // Reorder axes (The outs here are just placeholdes
  self->PermuteExtent(inExt, inMin0, inMax0, outMin1,outMax1,outMin2,outMax2);
  self->PermuteExtent(outExt, outMin0,outMax0,outMin1,outMax1,outMin2,outMax2);
  self->PermuteIncrements(inData->GetIncrements(), inInc0, inInc1, inInc2);
  self->PermuteIncrements(outData->GetIncrements(), outInc0, outInc1, outInc2);
  
  inSize0 = inMax0 - inMin0 + 1;
  
  maxDist = self->GetMaximumDistance();

  // precompute sq[]. Anisotropy is handled here by using Spacing information

  buff= (float *)calloc(outMax0+1,sizeof(float));

  sq = (float *)calloc(inSize0*2+2,sizeof(float));
  for(df=2*inSize0+1;df>inSize0;df--) sq[df]=maxDist;

  if ( self->GetConsiderAnisotropy() )
    { 
      spacing = inData->GetSpacing()[ self->GetIteration() ];
      spacing2 = spacing*spacing;
      for(df=inSize0;df>=0;df--) sq[df]=df*df*spacing2;
    }
  else
    {
      for(df=inSize0;df>=0;df--) sq[df]=df*df;
      spacing2=1;
    }

  // First iteration is special, we may need to initialise the image by setting
  // all non-zero values to maxDist
  
  if( ( self->GetIteration() == 0 ) && ( self->GetInitialize() == 1 ) )
    {      
      inPtr2 = inPtr;
      outPtr2 = outPtr;
      for (idx2 = outMin2; idx2 <= outMax2; ++idx2)
    {
      inPtr1 = inPtr2;
      outPtr1 = outPtr2;
      for (idx1 = outMin1; idx1 <= outMax1; ++idx1)
        {
          inPtr0 = inPtr1;
          outPtr0 = outPtr1;
          
          for (idx0 = outMin0; idx0 <= outMax0; ++idx0)
        {
          if( *inPtr0 == 0 )
            *outPtr0 = 0;
          else
            *outPtr0 = maxDist;
          
          inPtr0 += inInc0;
          outPtr0 += outInc0;
        }
          
          inPtr1 += inInc1;
          outPtr1 += outInc1;
        }
      inPtr2 += inInc2;
      outPtr2 += outInc2;
    }
    }
  else   // Other iterations are normal. We just copy inData to outData.
    {
      inPtr2 = inPtr;
      outPtr2 = outPtr;
      for (idx2 = outMin2; idx2 <= outMax2; ++idx2)
    {
      inPtr1 = inPtr2;
      outPtr1 = outPtr2;
      for (idx1 = outMin1; idx1 <= outMax1; ++idx1)
        {
          inPtr0 = inPtr1;
          outPtr0 = outPtr1;
          
          for (idx0 = outMin0; idx0 <= outMax0; ++idx0)
        {
          *outPtr0 = *inPtr0 ;
          inPtr0 += inInc0;
          outPtr0 += outInc0;
        }
          inPtr1 += inInc1;
          outPtr1 += outInc1;
        }
      inPtr2 += inInc2;
      outPtr2 += outInc2;
    }
    }

  if( self->GetIteration() == 0 ) // First iteration is special 
    {
      outPtr2 = outPtr;
      for (idx2 = outMin2; idx2 <= outMax2; ++idx2)
    {
      outPtr1 = outPtr2;
      for (idx1 = outMin1; idx1 <= outMax1; ++idx1)
        {
          outPtr0 = outPtr1;
          df= inSize0 ;
          for (idx0 = outMin0; idx0 <= outMax0; ++idx0)
        {
          if(*outPtr0 != 0)
            {
              df++ ;
              if(sq[df] < *outPtr0) 
            *outPtr0 = sq[df];
            }
          else df=0;

          outPtr0 += outInc0;
        }
          
          outPtr0 -= outInc0;
          df= inSize0 ;
          for (idx0 = outMax0; idx0 >= outMin0; --idx0)
        {
          if(*outPtr0 != 0)
            {
              df++ ;
              if(sq[df] < *outPtr0) 
            *outPtr0 = sq[df];
            }
          else df=0;
          
          outPtr0 -= outInc0;
        }

          outPtr1 += outInc1;
        }
      outPtr2 += outInc2;
    }      
    }
  else // next iterations are all identical. 
    {     
      
     outPtr2 = outPtr;
      for (idx2 = outMin2; idx2 <= outMax2; ++idx2)
    {
    
      outPtr1 = outPtr2;
      for (idx1 = outMin1; idx1 <= outMax1; ++idx1)
        {

          outPtr0 = outPtr1;

          // Buffer current values 

          for (idx0 = outMin0; idx0 <= outMax0; ++idx0)
        {
          buff[idx0]= *outPtr0;
          outPtr0 += outInc0;
        }
    
          // forward scan 

          a=0; buffer=buff[ outMin0 ];
              outPtr0 = outPtr1;
          outPtr0 += outInc0;

          for (idx0 = outMin0+1; idx0 <= outMax0; ++idx0)
        {
          if(a>0) a--;
          if(buff[idx0]>buffer+sq[1]) 
            {
              b=(int)(floor)((((buff[idx0]-buffer)/spacing2)-1)/2); 
              if((idx0+b)>outMax0) b=(outMax0)-idx0;
              
              for(n=a;n<=b;n++) 
            {
              m=buffer+sq[n+1];
              if(buff[idx0+n]<=m) n=b;  
              else if(m<*(outPtr0+n*outInc0)) *(outPtr0+n*outInc0)=m;
            }
              a=b; 
            }
          else
            a=0;
          
          buffer=buff[idx0];
          outPtr0 += outInc0;
        }
          
          outPtr0 -= 2*outInc0;
          a=0;
          buffer=buff[outMax0];
    
          for(idx0=outMax0-1;idx0>=outMin0; --idx0) 
        {
          if(a>0) a--;
          if(buff[idx0]>buffer+sq[1]) {
            b=(int)(floor)((((buff[idx0]-buffer)/spacing2)-1)/2); 
            if((idx0-b)<outMin0) b=idx0-outMin0;
            
            for(n=a;n<=b;n++) {
              m=buffer+sq[n+1];
              if(buff[idx0-n]<=m) 
            n=b;
            else if(m<*(outPtr0-n*outInc0)) *(outPtr0-n*outInc0)=m;
            }
            a=b;  
          }
          else
            a=0;
          buffer=buff[idx0];
          outPtr0 -= outInc0;
        }
          outPtr1 += outInc1;
        }
      outPtr2 += outInc2;         
    }    
      }
    
  free(buff);
  free(sq);
}




//----------------------------------------------------------------------------
// This method is passed input and output Datas, and executes the EuclideanDistanceTransformation
// algorithm to fill the output from the input.
// Not threaded yet.
void vtkImageEuclideanDistanceTransformation::ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
                  int outExt[6], int threadId)
{
  void *inPtr, *outPtr;
  int inExt[6];

  this->ComputeInputUpdateExtent(inExt, outExt);  
  inPtr = inData->GetScalarPointerForExtent(inExt);
  outPtr = outData->GetScalarPointerForExtent(outExt);

  if(threadId==0) this->UpdateProgress((this->GetIteration()+1.0)/3.0);
  
  // this filter expects that the output be floats.
  if (outData->GetScalarType() != VTK_FLOAT)
    {
      vtkErrorMacro(<< "Execute: Output must be be type float.");
      return;
    }
  
  // this filter expects input to have 1 or two components
  if (outData->GetNumberOfScalarComponents() != 1 )
    {
      vtkErrorMacro(<< "Execute: Cannot handle more than 1 components");
      return;
    }
  
  // choose which templated function to call.
  switch (inData->GetScalarType())
    {
    case VTK_FLOAT:
      vtkImageEuclideanDistanceTransformationExecute(this, inData, inExt, (float *)(inPtr), 
             outData, outExt, (float *)(outPtr), threadId);
      break;
    case VTK_INT:
      vtkImageEuclideanDistanceTransformationExecute(this, inData, inExt, (int *)(inPtr),
             outData, outExt, (float *)(outPtr), threadId);
      break;
    case VTK_SHORT:
      vtkImageEuclideanDistanceTransformationExecute(this, inData, inExt, (short *)(inPtr),
             outData, outExt, (float *)(outPtr), threadId);
      break;
    case VTK_UNSIGNED_SHORT:
      vtkImageEuclideanDistanceTransformationExecute(this, inData, inExt, (unsigned short *)(inPtr), 
             outData, outExt, (float *)(outPtr), threadId);
      break;
    case VTK_UNSIGNED_CHAR:
      vtkImageEuclideanDistanceTransformationExecute(this, inData, inExt, (unsigned char *)(inPtr),
             outData, outExt, (float *)(outPtr), threadId);
      break;
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}



//----------------------------------------------------------------------------
// For streaming and threads.  Splits output update extent into num pieces.
// This method needs to be called num times.  Results must not overlap for
// consistent starting extent.  Subclass can override this method.
// This method returns the number of peices resulting from a successful split.
// This can be from 1 to "total".  
// If 1 is returned, the extent cannot be split.
int vtkImageEuclideanDistanceTransformation::SplitExtent(int splitExt[6], int startExt[6], 
                 int num, int total)
{
  int splitAxis;
  int min, max;

  vtkDebugMacro("SplitExtent: ( " << startExt[0] << ", " << startExt[1] << ", "
        << startExt[2] << ", " << startExt[3] << ", "
        << startExt[4] << ", " << startExt[5] << "), " 
        << num << " of " << total);

  // start with same extent
  memcpy(splitExt, startExt, 6 * sizeof(int));

  splitAxis = 2;
  min = startExt[4];
  max = startExt[5];
  while ((splitAxis == this->Iteration) || (min == max))
    {
    splitAxis--;
    if (splitAxis < 0)
      { // cannot split
      vtkDebugMacro("  Cannot Split");
      return 1;
      }
    min = startExt[splitAxis*2];
    max = startExt[splitAxis*2+1];
    }

  // determine the actual number of pieces that will be generated
  if ((max - min + 1) < total)
    {
    total = max - min + 1;
    }
  
  if (num >= total)
    {
    vtkDebugMacro("  SplitRequest (" << num 
          << ") larger than total: " << total);
    return total;
    }
  
  // determine the extent of the piece
  splitExt[splitAxis*2] = min + (max - min + 1)*num/total;
  if (num == total - 1)
    {
    splitExt[splitAxis*2+1] = max;
    }
  else
    {
    splitExt[splitAxis*2+1] = (min-1) + (max - min + 1)*(num+1)/total;
    }
  
  vtkDebugMacro("  Split Piece: ( " <<splitExt[0]<< ", " <<splitExt[1]<< ", "
        << splitExt[2] << ", " << splitExt[3] << ", "
        << splitExt[4] << ", " << splitExt[5] << ")");
  fflush(stderr);

  return total;
}

  
















