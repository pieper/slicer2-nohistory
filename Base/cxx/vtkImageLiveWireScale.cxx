/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWireScale.cxx,v $
  Date:      $Date: 2006/02/27 19:21:50 $
  Version:   $Revision: 1.16 $

=========================================================================auto=*/
#include "vtkImageLiveWireScale.h"

#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkImageProgressIterator.h"

#include <math.h>
#include <time.h>

//------------------------------------------------------------------------------
vtkImageLiveWireScale* vtkImageLiveWireScale::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageLiveWireScale");
  if(ret)
    {
    return (vtkImageLiveWireScale*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageLiveWireScale;
}

//----------------------------------------------------------------------------
// Constructor sets default values
vtkImageLiveWireScale::vtkImageLiveWireScale()
{  
  this->ScaleFactor = 1;

  this->UseTransformationFunction = 0;
  this->TransformationFunctionNumber = 0;

  this->UseUpperCutoff = 0;
  this->UpperCutoff = 1;
  this->UseLowerCutoff = 0;
  this->LowerCutoff = 0;

}

//----------------------------------------------------------------------------
vtkImageLiveWireScale::~vtkImageLiveWireScale()
{

}

//----------------------------------------------------------------------------
vtkFloatingPointType vtkImageLiveWireScale::TransformationFunction(vtkFloatingPointType intensity, vtkFloatingPointType max,
                          vtkFloatingPointType min) 
{
  if (this->UseUpperCutoff)
    {
      max = this->UpperCutoff;
      if (min > this->UpperCutoff) 
    {
      vtkErrorMacro("Oops, min value higher than upper cutoff!");
      min = this->UpperCutoff - 1;
    }
      if (intensity > this->UpperCutoff)
    intensity = this->UpperCutoff;
    }

  if (this->UseLowerCutoff)
    {
      min = this->LowerCutoff;
      if (max < this->LowerCutoff) 
    {
      vtkErrorMacro("Oops, max value lower than lower cutoff!");
      max = this->LowerCutoff + 1;
    }
      if (intensity < this->LowerCutoff)
    intensity = this->LowerCutoff;
    }

  // try to spread the data out in the output range
  vtkFloatingPointType range = max-min;
  vtkFloatingPointType x = intensity - min;
  vtkFloatingPointType x_frac = x/range;

  switch (this->TransformationFunctionNumber)
    {
    case INVERSE_LINEAR_RAMP:
      //return (this->ScaleFactor - (intensity*this->ScaleFactor)/max);
      return (this->ScaleFactor - x_frac*this->ScaleFactor);
      break;
    case ONE_OVER_X:
      // scale * (1/1+x), where x = intensity/max
      // note: This should be done a bit better (min now is scale/2)
      // do 1/(1+x^2)
      //return (this->ScaleFactor*range/(range + x));
      return (this->ScaleFactor/(1 + x_frac*x_frac));
      break;
    default:
      vtkErrorMacro("Oops, no transformation function set!");
      return 0;
      break;
    }

}


// //----------------------------------------------------------------------------
// // This templated function executes the filter for any type of data.
// template <class T>
// static void vtkImageLiveWireScaleExecute(vtkImageLiveWireScale *self,
//                       vtkImageData *inData, T *inPtr,
//                       vtkImageData *outData, vtkFloatingPointType *outPtr)
// {
//   int outExt[6];
//   unsigned long count = 0;
//   unsigned long target;
//   int outMin0, outMax0, outMin1, outMax1, outMin2, outMax2;
//   int outIdx0, outIdx1, outIdx2;
//   int inInc0, inInc1, inInc2;
//   int outInc0, outInc1, outInc2;
//   T *inPtr0, *inPtr1, *inPtr2;
//   vtkFloatingPointType *outPtr0, *outPtr1, *outPtr2;
//   int inImageMin0, inImageMin1, inImageMin2;
//   int inImageMax0, inImageMax1, inImageMax2;
//   clock_t tStart, tEnd, tDiff;
//   T pix;
//   int scaleFactor;

//   tStart = clock();
//   scaleFactor = self->GetScaleFactor();

//   // Get information to march through data
//   inData->GetIncrements(inInc0, inInc1, inInc2); 
//   self->GetInput()->GetWholeExtent(inImageMin0, inImageMax0, inImageMin1,
//                    inImageMax1, inImageMin2, inImageMax2);
//   outData->GetIncrements(outInc0, outInc1, outInc2); 
//   outData->GetExtent(outExt);
//   outMin0 = outExt[0];   outMax0 = outExt[1];
//   outMin1 = outExt[2];   outMax1 = outExt[3];
//   outMin2 = outExt[4];   outMax2 = outExt[5];
    
//   // in and out should be marching through corresponding pixels.
//   inPtr = (T *)(inData->GetScalarPointerForExtent(inData->GetExtent()));
//   //inPtr = (T *)(inData->GetScalarPointer(outMin0, outMin1, outMin2));

//   target = (unsigned long)((outMax2-outMin2+1)*(outMax1-outMin1+1)/50.0);
//   target++;

//   // note: this code assumes that the image is all >= 0 already. (!!!!!!)
//   T max, min;
//   double imgRange[2];
//   inData->GetScalarRange(imgRange);
//   min = (T) imgRange[0];
//   max = (T) imgRange[1];

//   return;

//   // use max, min info to scale input:

//   //  try transformation function
//   if (self->GetUseTransformationFunction())
//     {
//       //cout << "using transformation fcn" << endl;
//       // loop through input and produce output:
//       // output = input pixel/max
//       outPtr2 = outPtr;
//       inPtr2 = inPtr;
//       for (outIdx2 = outMin2; outIdx2 <= outMax2; outIdx2++)
//     {
//       outPtr1 = outPtr2;
//       inPtr1 = inPtr2;
//       for (outIdx1 = outMin1; 
//            !self->AbortExecute && outIdx1 <= outMax1; outIdx1++)
//         {
//           if (!(count%target)) 
//         {
//           self->UpdateProgress(count/(50.0*target));
//         }
//           count++;
      
//           outPtr0 = outPtr1;
//           inPtr0 = inPtr1;
//           for (outIdx0 = outMin0; outIdx0 <= outMax0; outIdx0++)
//         {
//           //*outPtr0 = self->TransformationFunction(*inPtr0, max, min);
//           *outPtr0 = *inPtr0;

//           inPtr0 += inInc0;
//           outPtr0 += outInc0;
//         }//for0
//           inPtr1 += inInc1;
//           outPtr1 += outInc1;
//         }//for1
//       inPtr2 += inInc2;
//       outPtr2 += outInc2;
//     }//for2
      
//     } // end use transformation

//   // default: just shift and scale
//   else
//     {
//       //cout << "using default shift and scale" << endl;
//       T range = max - min;
//       if (range == 0) 
//     range = 1;
      
//       // loop through input and produce output:
//       // output = input pixel/max
//       outPtr2 = outPtr;
//       inPtr2 = inPtr;
//       for (outIdx2 = outMin2; outIdx2 <= outMax2; outIdx2++)
//     {
//       outPtr1 = outPtr2;
//       inPtr1 = inPtr2;
//       for (outIdx1 = outMin1; 
//            !self->AbortExecute && outIdx1 <= outMax1; outIdx1++)
//         {
//           if (!(count%target)) 
//         {
//           self->UpdateProgress(count/(50.0*target));
//         }
//           count++;
      
//           outPtr0 = outPtr1;
//           inPtr0 = inPtr1;
//           for (outIdx0 = outMin0; outIdx0 <= outMax0; outIdx0++)
//         {

//           ////*outPtr0 = (*inPtr0 * scaleFactor)/max;
//           //*outPtr0 = (*inPtr0-min) * scaleFactor/range;
//           *outPtr0 = *inPtr0;

//           inPtr0 += inInc0;
//           outPtr0 += outInc0;
//         }//for0
//           inPtr1 += inInc1;
//           outPtr1 += outInc1;
//         }//for1
//       inPtr2 += inInc2;
//       outPtr2 += outInc2;
//     }//for2

//     } // end if in basic case: no transformation, no LUT

//   tEnd = clock();
//   tDiff = tEnd - tStart;
//   cout << "LW scale time: " << tDiff << endl;
// }

    
//----------------------------------------------------------------------------
void vtkImageLiveWireScale::ExecuteInformation(vtkImageData *vtkNotUsed(input), 
                        vtkImageData *output)
{
  output->SetNumberOfScalarComponents(1);
  output->SetScalarType(VTK_FLOAT);
}

//----------------------------------------------------------------------------
void vtkImageLiveWireScale::UpdateData(vtkDataObject *data)
{
  
  if (! this->GetInput() || ! this->GetOutput())
    {
    vtkErrorMacro("Update: Input or output is not set.");
    return;
    }
  
  // call the superclass update which will cause an execute.
  this->Superclass::UpdateData(data);
}

//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
template <class IT, class OT>
void vtkImageLiveWireScaleExecute(vtkImageLiveWireScale *self,
                         vtkImageData *inData,
                         vtkImageData *outData,
                         int outExt[6], int id, IT *, OT *)
{
  vtkImageIterator<IT> inIt(inData, outExt);
  vtkImageProgressIterator<OT> outIt(outData, outExt, self, id);

   IT max, min;
   double imgRange[2];
   inData->GetScalarRange(imgRange);
   min = (IT) imgRange[0];
   max = (IT) imgRange[1];
   IT range = max - min;
   if (range == 0) range = 1;
   int scaleFactor = self->GetScaleFactor();

  // Loop through output pixels
  while (!outIt.IsAtEnd())
    {
    IT* inSI = inIt.BeginSpan();
    OT* outSI = outIt.BeginSpan();
    OT* outSIEnd = outIt.EndSpan();

      while (outSI != outSIEnd)
        {
        // now process the components

          if (self->GetUseTransformationFunction())
            {
              *outSI = static_cast<OT> 
                (self->TransformationFunction(*inSI, max, min));
            }
          else
            {
              *outSI = static_cast<OT> ((*inSI-min) * scaleFactor/range);
            }

          ++outSI;
          ++inSI;
        }

    inIt.NextSpan();
    outIt.NextSpan();
    }
}



//----------------------------------------------------------------------------
template <class T>
void vtkImageLiveWireScaleExecute(vtkImageLiveWireScale *self,
                         vtkImageData *inData,
                         vtkImageData *outData, int outExt[6], int id,
                         T *)
{
  switch (outData->GetScalarType())
    {
    vtkTemplateMacro7(vtkImageLiveWireScaleExecute, self, 
                      inData, outData, outExt, id,
                      static_cast<T *>(0), static_cast<VTK_TT *>(0));
    default:
      vtkGenericWarningMacro("Execute: Unknown output ScalarType");
      return;
    }
}




//----------------------------------------------------------------------------
// This method is passed a input and output region, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the regions data types.
void vtkImageLiveWireScale::ThreadedExecute(vtkImageData *inData, 
                                   vtkImageData *outData,
                                   int outExt[6], int id)
{
  vtkDebugMacro(<< "Execute: inData = " << inData 
                << ", outData = " << outData);
  
  switch (inData->GetScalarType())
    {
    vtkTemplateMacro6(vtkImageLiveWireScaleExecute, this, inData, 
                      outData, outExt, id, static_cast<VTK_TT *>(0));
    default:
      vtkErrorMacro(<< "Execute: Unknown input ScalarType");
      return;
    }
}

//----------------------------------------------------------------------------
void vtkImageLiveWireScale::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);

  // numbers
  os << indent << "ScaleFactor: "<< this->ScaleFactor << "\n";
  os << indent << "UpperCutoff: "<< this->UpperCutoff << "\n";
  os << indent << "LowerCutoff: "<< this->LowerCutoff << "\n";
  os << indent << "UseUpperCutoff: "<< this->UseUpperCutoff << "\n";
  os << indent << "UseLowerCutoff: "<< this->UseLowerCutoff << "\n";
  os << indent << "UseTransformationFunction: "<< this->UseTransformationFunction << "\n";
  os << indent << "TransformationFunctionNumber: "<< this->TransformationFunctionNumber << "\n";

}

