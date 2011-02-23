/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWireEdgeWeights.cxx,v $
  Date:      $Date: 2006/01/13 15:39:24 $
  Version:   $Revision: 1.37 $

=========================================================================auto=*/
#include "vtkImageLiveWireEdgeWeights.h"
#include "vtkObjectFactory.h"
#include <math.h>
#include <time.h>

//------------------------------------------------------------------------------
vtkImageLiveWireEdgeWeights* vtkImageLiveWireEdgeWeights::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageLiveWireEdgeWeights");
  if(ret)
    {
      return (vtkImageLiveWireEdgeWeights*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageLiveWireEdgeWeights;
}

// inverse "Gaussian": low cost for good edges
inline float GaussianC(float x, float mean, float var)
{
  // This is the time bottleneck of this filter.
  // So only bother to compute the gaussian if this is a 
  // "good feature" (with a value close to the mean).
  // Else return the max value of 1.
  //    float tmp = x-mean;
  //    if (tmp < var)
  //      return(1 - exp(-(tmp*tmp)/(2*var))/sqrt(6.28318*var));  
  //    else
  //      return 1;

  // we need between 0 and 1 always, so:
  // forget about the scale factor.  the feature weight does this.
  // so just do the e^-((x-u)^2/2*sigma^2)

  float tmp = x-mean;
  return(1 - exp( -(tmp*tmp)/(2*var) ));  

}

//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageLiveWireEdgeWeights::vtkImageLiveWireEdgeWeights()
{
  // all inputs 
  this->NumberOfRequiredInputs = 1;
  this->NumberOfInputs = 0;

  this->FileName = NULL;
  this->TrainingFileName = NULL;

  this->MaxEdgeWeight = 255;
  this->EdgeDirection = DOWN_EDGE;

  this->NumberOfFeatures = 6;

  this->FeatureSettings = new featureProperties[this->NumberOfFeatures];

  this->Neighborhood = 3; // 3x3 neighborhood

  this->TrainingMode = 0;
  this->TrainingComputeRunningTotals = 0;
  this->NumberOfTrainingPoints = 0;
  this->RunningNumberOfTrainingPoints = 0;
  this->TrainingAverages = new float[this->NumberOfFeatures];
  this->TrainingVariances = new float[this->NumberOfFeatures];

  for (int i=0; i < this->NumberOfFeatures; i++)
    {
      this->TrainingAverages[i] = 0;
      // don't allow 0 variance to be calculated (will break Gaussian).
      this->TrainingVariances[i] = 0.01;
    }
}


//----------------------------------------------------------------------------
vtkImageLiveWireEdgeWeights::~vtkImageLiveWireEdgeWeights()
{
  if (this->FileName != NULL)
    {
      delete [] this->FileName;
    }

  if (this->TrainingFileName != NULL)
    {
      delete [] this->TrainingFileName;
    }

  if (this->FeatureSettings != NULL)
    {
      delete [] this->FeatureSettings;
    }

  if (this->TrainingAverages != NULL)
    {
      delete [] this->TrainingAverages;
    }
  if (this->TrainingVariances != NULL)
    {
      delete [] this->TrainingVariances;
    }
}

//----------------------------------------------------------------------------
// Description:
// Dump training settings to a file
void vtkImageLiveWireEdgeWeights::WriteFeatureSettings()
{
  ofstream file;

  if (this->TrainingFileName)
    {
      file.open(this->TrainingFileName);
      if (file.fail())
    {
      vtkErrorMacro("Could not open file %" << this->TrainingFileName);
      return;
    }  
    }
  else 
    {
      vtkErrorMacro("FileName has not been set");
      return;
    }

  // output the features  
  for (int i=0; i < this->NumberOfFeatures; i++)
    {
     //   file << this->GetWeightForFeature(i) << ' ' 
//         << this->TrainingAverages[i]    << ' '  
//         << this->TrainingVariances[i]   << endl;

      file << this->GetWeightForFeature(i) << ' ' 
       << this->TrainingAverages[i]    << ' '  
       << this->TrainingVariances[i]   << ' '
       << this->GetParamForFeature(i,0) << ' '  
       << this->GetParamForFeature(i,1) << endl;
    }
  
  file.close();
}

void vtkImageLiveWireEdgeWeights::TrainingModeOn()
{
  this->TrainingMode = 1;
  
  for (int i=0; i < this->NumberOfFeatures; i++)
    {
      this->TrainingAverages[i] = 0;
      // don't allow 0 variance to be calculated (will break Gaussian).
      this->TrainingVariances[i] = 0.01;
    }

}

void vtkImageLiveWireEdgeWeights::TrainingModeOff()
{
  this->TrainingMode = 0;
}


//----------------------------------------------------------------------------
// Description:
// Output training settings to a file (already opened)
void vtkImageLiveWireEdgeWeights::AppendFeatureSettings(ofstream& of)
{

  // output the features
  
  for (int i=0; i < this->NumberOfFeatures; i++)
    {
      of << this->GetWeightForFeature(i) << ' ' 
     << this->GetParamForFeature(i,0)    << ' '  
     << this->GetParamForFeature(i,1)   << endl;
    }

}

//----------------------------------------------------------------------------
// Description:
// Output training settings to a file (already opened)
void vtkImageLiveWireEdgeWeights::GetFeatureSettingsString(char *settings)
{
  char set[40];

  // append the features
  for (int i=0; i < this->NumberOfFeatures; i++)
    {
      sprintf(set, "%9f.4", this->GetWeightForFeature(i));
      strcat(settings, set);

      sprintf(set, "%9f.4", this->GetParamForFeature(i,0));
      strcat(settings, set);

      sprintf(set, "%9f.4", this->GetParamForFeature(i,1));
      strcat(settings, set);
    }
}

//----------------------------------------------------------------------------
// Description:
// Set the direction of the weighted graph edges 
// that this filter should output
void vtkImageLiveWireEdgeWeights::SetEdgeDirection(int dir)
{

  if (this->Neighborhood != 3) 
    {
      vtkErrorMacro("Only neighborhood width of 3 supported now");
      return;      
    }

  // This confusing code is following the "graph edges are
  // cracks between pixels" method of creating the 
  // Livewire input graph.  So the center of the filter
  // kernel is *between* two pixels.


  // set up filter directionality
  // ----------------------------------------------
  // From paper, layout of neighborhood is:
  // t | u
  //   ^
  // p | q  (p,q = the "bel" whose upward edge we are computing)
  // v | w
  // I want clockwise segmentation, so "q" should be inside the contour.

  // compute these edges at each pixel, x:
  //
  //  ->  ^
  //  | x |
  //  V  <-
  //
  // then the right and down arrows belong to the upper left corner
  // and the other two to the lower right corner.
  // so shifting output images will give the correct:
  //
  //    ^
  //  <-|->
  //    V
  // where each pixel has the correct weight for 
  // all of one corner's outward paths
  // (segmentation is done on the borders between pixels)
  
  // neighborhood looks like:
  // 6 7 8
  // 3 4 5
  // 0 1 2

  // rotate neighborhood for all edges.
      
  switch (dir) 
    {
    case UP_EDGE:
      {
    //      | 7 | 8 |        | t | u |
    //          ^       OR       ^
    // bel: | 4 | 5 |        | p | q |
    //      | 1 | 2 |        | v | w |
    //
    t = 7; 
    u = 8;
    p = 4;
    q = 5;
    v = 1;
    w = 2;
    this->EdgeDirection = dir;
    break;
      }
    case DOWN_EDGE:
      {
    //      | 6 | 7 |        | w | v |
    // bel: | 3 | 4 |   OR   | q | p |
    //          v                v
    //      | 0 | 1 |        | u | t |
    //
    t = 1; 
    u = 0;
    p = 4;
    q = 3;
    v = 7;
    w = 6;
    this->EdgeDirection = dir;
    break;
      }
    case LEFT_EDGE:
      {
    //  6   7  8              u   q  w
    //  -- <- --        OR    -- <- --
    //  3   4  5              t   p  v
    t = 3; 
    u = 6;
    p = 4;
    q = 7;
    v = 5;
    w = 8;
    this->EdgeDirection = dir;
    break;
      }
    case RIGHT_EDGE:
      {
    //  3  4   5              v  p   t
    //  -- -> --        OR    -- -> --
    //  0  1   2              w  q   u
    t = 5; 
    u = 2;
    p = 4;
    q = 1;
    v = 3;
    w = 0;
    this->EdgeDirection = dir;
    break;
      }
    default:
      {
    cout << "ERROR in vtkImageLiveWireEdgeWeights: "
         << "bad edge direction of: "
         << dir
         << "Defaulting to UP_EDGE" << '\n';
    this->SetEdgeDirection(UP_EDGE);
    break;
      }
    }

}

void vtkImageLiveWireEdgeWeights::GetKernelIndices(int &t_, int &u_, 
                           int &p_, int &q_, 
                           int &v_, int &w_)
{
  t_ = this->t;
  u_ = this->u;
  p_ = this->p;
  q_ = this->q;
  v_ = this->v;
  w_ = this->w;

}
//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
// For every pixel in the foreground, if a neighbor is in the background,
// then the pixel becomes background.
template <class T>
static void vtkImageLiveWireEdgeWeightsExecute(vtkImageLiveWireEdgeWeights *self,
                          vtkImageData **inDatas, T **inPtrs,
                          vtkImageData *outData,
                          int outExt[6], int id)
{
  // For looping though output (and input) pixels.
  int outMin0, outMax0, outMin1, outMax1, outMin2, outMax2;
  int outIdx0, outIdx1, outIdx2;
  int inInc0, inInc1, inInc2;
  int outInc0, outInc1, outInc2;
  T *inPtr0, *inPtr1, *inPtr2;
  // pointers to training data image
  T *inTPtr0, *inTPtr1, *inTPtr2;
  T *outPtr0, *outPtr1, *outPtr2;
  // For looping through hood pixels
  int hoodMin0, hoodMax0, hoodMin1, hoodMax1, hoodMin2, hoodMax2;
  int hoodIdx0, hoodIdx1, hoodIdx2;
  int offsetPtr0, offsetPtr1, offsetPtr2;
  int *nPtr0, *nPtr1, *nPtr2;
  // The extent of the whole input image
  int inImageMin0, inImageMin1, inImageMin2;
  int inImageMax0, inImageMax1, inImageMax2;
  T *outPtr = (T*)outData->GetScalarPointerForExtent(outExt);
  unsigned long count = 0;
  unsigned long target;
  int t,u,p,q,v,w;
  int numFeatures, neighborhoodWidth;

  //clock_t tStart, tEnd, tDiff;
  //tStart = clock();
  
  // how many features to compute per voxel
  numFeatures = self->GetNumberOfFeatures();
  
  // Get information to march through data
  inDatas[0]->GetIncrements(inInc0, inInc1, inInc2); 
  self->GetInput()->GetWholeExtent(inImageMin0, inImageMax0, inImageMin1,
                   inImageMax1, inImageMin2, inImageMax2);
  outData->GetIncrements(outInc0, outInc1, outInc2); 
  outMin0 = outExt[0];   outMax0 = outExt[1];
  outMin1 = outExt[2];   outMax1 = outExt[3];
  outMin2 = outExt[4];   outMax2 = outExt[5];

  // Neighborhood around current voxel
  // Lauren we only handle Neighborhood == 3 now
  hoodMin0 = - 1;
  hoodMin1 = - 1;
  hoodMin2 = 0;

  hoodMax0 = 1;
  hoodMax1 = 1;
  hoodMax2 = 0;

  // in and out should be marching through corresponding pixels.
  target = (unsigned long)((outMax2-outMin2+1)*
               (outMax1-outMin1+1)/50.0);
  target++;

  // only 3 is supported now
  neighborhoodWidth = self->GetNeighborhood();

  // get indices into neighborhood for this edge orientation
  self->GetKernelIndices(t,u,p,q,v,w);

  // offsets to index into neighborhood pixels
  int *n = new int[neighborhoodWidth*neighborhoodWidth];
  
  // loop through neighborhood indices and record offsets 
  // from inPtr0 in n[] array 
  offsetPtr2 = inInc0*hoodMin0 + inInc1*hoodMin1 + inInc2*hoodMin2;
  nPtr2 = n;
  for (hoodIdx2 = hoodMin2; hoodIdx2 <= hoodMax2; ++hoodIdx2)
    {
      offsetPtr1 = offsetPtr2;
      nPtr1 = nPtr2;
      for (hoodIdx1 = hoodMin1; hoodIdx1 <= hoodMax1; ++hoodIdx1)
    {
      offsetPtr0 = offsetPtr1;
      nPtr0 = nPtr1;
      for (hoodIdx0 = hoodMin0; hoodIdx0 <= hoodMax0; ++hoodIdx0)
        {
          // store offset into n array
          *nPtr0 = offsetPtr0;          
          offsetPtr0 += inInc0;
          nPtr0++;          
        }//for0
      offsetPtr1 += inInc1;
      nPtr1 += neighborhoodWidth;
    }//for1
      offsetPtr2 += inInc2;
      nPtr2 += neighborhoodWidth*neighborhoodWidth;
    }//for2  
  
  // scale factor (edges go from 1 to this number)
  int maxEdge = self->GetMaxEdgeWeight();

  // temporary storage of features computed at a voxel
  float *features = new float[numFeatures];

  // storage of training data
  float *average = self->GetTrainingAverages();      
  float *variance = self->GetTrainingVariances();      
  int numberOfTrainingPoints = 0;

  // compute normalization factor
  float sumOfWeights = 0;
  for (int i = 0; i < numFeatures; i++) 
    {
      sumOfWeights += self->GetWeightForFeature(i);
    }

  // factor to scale output values from 1 to maxEdge.
  float edgeFactor = maxEdge/sumOfWeights;


  // loop through pixels of output
  outPtr2 = outPtr;
  inPtr2 = inPtrs[0];
  inTPtr2 = inPtrs[1];
  for (outIdx2 = outMin2; outIdx2 <= outMax2; outIdx2++)
    {
      outPtr1 = outPtr2;
      inPtr1 = inPtr2;
      inTPtr1 = inTPtr2;
      for (outIdx1 = outMin1; 
       !self->AbortExecute && outIdx1 <= outMax1; outIdx1++)
    {
      if (!id) 
        {
          if (!(count%target))
        {
          self->UpdateProgress(count/(50.0*target));
        }
          count++;
        }
          
      outPtr0 = outPtr1;
      inPtr0 = inPtr1;
      inTPtr0 = inTPtr1;
      for (outIdx0 = outMin0; outIdx0 <= outMax0; outIdx0++)
        {
          // ---- Neighborhood Operations ---- //

          // make sure *entire* kernel is within boundaries
          // this is a bit faster and we don't care about edges of image
          if (outIdx0 + hoodMin0 >= inImageMin0 &&
          outIdx0 + hoodMax0 <= inImageMax0 &&
          outIdx1 + hoodMin1 >= inImageMin1 &&
          outIdx1 + hoodMax1 <= inImageMax1 &&
          outIdx2 + hoodMin2 >= inImageMin2 &&
          outIdx2 + hoodMax2 <= inImageMax2)
        {
          // FEATURES
          // 0: in pix magnitude = q 
          // 1: out pix magnitude = p
          // 2: outpix-inpix = p-q
          // 3: gradient = (1/3)*(p+t+v-u-q-w)                
          // 4: gradient = (1/2)*(p+t/2+v/2 -u-q/2-w/2)
          // 5: gradient = (1/4)*(p-u + t-q + p-w + v-q)
          // ----------------------------------------------
          if (neighborhoodWidth == 3) 
            {
              T *ptr = inPtr0;
              // Compute various features:
              // Lauren we assume NumberOfFeatures = 6
              features[0] = *(ptr+n[q]); 
              features[1] = *(ptr+n[p]);
              features[2] = *(ptr+n[p]) - *(ptr+n[q]);

              features[3] = .333333*(*(ptr+n[p])+*(ptr+n[t])+*(ptr+n[v])-*(ptr+n[u])-*(ptr+n[q])-*(ptr+n[w]));

              features[4] = .5*(*(ptr+n[p])+*(ptr+n[t])/2+*(ptr+n[v])/2
                    -*(ptr+n[u])-*(ptr+n[q])/2-*(ptr+n[w])/2);
              features[5] = .25*(*(ptr+n[p])-*(ptr+n[u]) + *(ptr+n[t])-*(ptr+n[q]) + 
                     *(ptr+n[p])-*(ptr+n[w]) + *(ptr+n[v])-*(ptr+n[q]));
            }
          else
            {
              // we don't handle other neighorhood sizes
              memset(features,0,numFeatures*sizeof(float));
            }

          // TRAINING
          // If we are in training mode, need to compute
          // average values of each feature over certain
          // points in the image
          // ----------------------------------------------
          if (self->GetTrainingMode()) 
            {
              // if this (inside, or 'q') pixel is in the
              // segmented area, and its neighboring
              // outside, or 'p', pixel, is NOT.
              if (*(inTPtr0 + n[q]) == 1 && *(inTPtr0 + n[p]) == 0){
            //cout << "point: " << outIdx0 << " " << outIdx1;
            for (int i=0;i<numFeatures;i++)
              {
                // train each feature at this spot
                average[i] += features[i];
                variance[i] += (features[i])*(features[i]);
              }        
            numberOfTrainingPoints++;
              }      
            }

          // convert features to an edge weight
          featureProperties *props;
          float sum = 0;
          for (int i=0;i<numFeatures;i++)
            {
              props = self->GetFeatureSettings(i);

              // don't compute slow gaussian if weight is 0
              if (props->Weight != 0) 
            {
              sum += props->Weight*GaussianC(features[i],props->TransformParams[0],props->TransformParams[1]);

            }
            }
          // each feature is between 0 and its Weight.  
          // normalize sum to 1 and multiply by max edge cost.
          *outPtr0 = (T) (sum*edgeFactor);

          if ((int)(*outPtr0) > maxEdge) 
            {
              cout << "ERROR in vtkImageLWEdgeWeights: edge cost too high " << *outPtr0 << '\n';
            }
              
        }  // end if whole kernel in bounds
          else
        {
          // handle boundaries: default output equal to max edge value
          *outPtr0 = maxEdge;
        }

          // ---- End Neighborhood Operations ---- //
          
          inPtr0 += inInc0;
          inTPtr0 += inInc0;
          outPtr0 += outInc0;
        }//for0
      inPtr1 += inInc1;
      inTPtr1 += inInc1;
      outPtr1 += outInc1;
    }//for1
      inPtr2 += inInc2;
      inTPtr2 += inInc2;
      outPtr2 += outInc2;
    }//for2

  // Clean up temp storage
  if (n != NULL) 
    {
      delete [] n;
    }
  if (features != NULL) 
    {
      delete [] features;
    }

  // Finish training computations
  if (self->GetTrainingMode()) 
    {
      // increment the running number of points
      int numPoints = self->GetRunningNumberOfTrainingPoints();
      numPoints += numberOfTrainingPoints;
      self->SetRunningNumberOfTrainingPoints(numPoints);

      //cout << "total points: " << numPoints << "num points: " << numberOfTrainingPoints << '\n';

      // if we are not doing running totals (multi-slice training), 
      // finish computing averages.
      // (this could also be the last slice of a running total)
      if (!self->GetTrainingComputeRunningTotals())
    {
      // if we trained on any points
      if (numPoints > 0) {
        
        // then divide by total number of pixels
        for (int i=0;i<numFeatures;i++)
          {
        average[i] = average[i]/numPoints;
        //cout << "avg: " << average[i] << " ";
        variance[i] = variance[i]/numPoints - (average[i])*(average[i]);
        //cout << "var: " << variance[i] << " ";
          }              
        //cout << '\n';
        
        // set the total number of points used to compute the averages
        self->SetNumberOfTrainingPoints(numPoints);
        
        // clear the running total
        self->SetRunningNumberOfTrainingPoints(0);
        
        // set this filter's settings to the trained ones.
        for (int f=0;f<numFeatures;f++)
          {
        self->SetParamForFeature(f,0,average[f]);
        self->SetParamForFeature(f,1,variance[f]);
          }
      }
      else {
        cout << "No contour points to train on!" << '\n';
      }

      // turn off Training Mode since we are done
      self->TrainingModeOff();
    }
    }

  //tEnd = clock();
  //tDiff = tEnd - tStart;
  //cout << "time: " << tDiff << '\n';
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageLiveWireEdgeWeights::ThreadedExecute(vtkImageData **inDatas, 
                         vtkImageData *outData,
                         int outExt[6], int id)
{
  void *inPtrs[3];
  int inExt[6];

  // if we are training, we want one thread to handle everything.
  // else we want each thread to do part of the image.

//    if (this->TrainingMode)
//      {
//        // thread 0 does it all, so return if id > 0
//        if (id > 0)
//      return;
      
//        // set extents to be the whole size of the output 
//        // (same as input size)
//        outData->GetWholeExtent(outExt);
//        memcpy(inExt, outExt, 6*sizeof(int));      

//      }
//    else
//      {
//        // input extent is same as output extent 
//        // (each thread gets its own chunk)
//        memcpy(inExt, outExt, 6*sizeof(int));
//      }


  // TEMPORARY FIX: make the 0th thread do everything.
  // this is to try to avoid bug during livewire apply
  // when vtkImageReformat.cxx crashes.  Seems like its
  // inPtr is set to nil during its execution.
  // this has not been seen on single procesor machines, so
  // pretend that's what we are.
  //
  // thread 0 does it all, so return if id > 0
  if (id > 0)
    return;
  
  // set extents to be the whole size of the output 
  // (same as input size)
  outData->GetWholeExtent(outExt);
  memcpy(inExt, outExt, 6*sizeof(int));  
  // END TEMPORARY FIX

  //for (int i = 0; i < 6; i++)
  //printf("id: %d ext %d: %d\n", id, i, inExt[i]);

  inPtrs[0] = inDatas[0]->GetScalarPointerForExtent(inExt);

  if (this->NumberOfInputs > 1)
    {
      inPtrs[1] = inDatas[1]->GetScalarPointerForExtent(inExt);
    }
  if (this->NumberOfInputs > 2)
    {
      inPtrs[2] = inDatas[2]->GetScalarPointerForExtent(inExt);
    }

  switch (inDatas[0]->GetScalarType())
    {
    case VTK_DOUBLE:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (double **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_FLOAT:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (float **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_LONG:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (long **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_INT:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (int **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_UNSIGNED_INT:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (unsigned int **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_SHORT:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (short **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_UNSIGNED_SHORT:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (unsigned short **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_CHAR:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (char **)(inPtrs), 
                    outData, outExt, id);
      break;
    case VTK_UNSIGNED_CHAR:
      vtkImageLiveWireEdgeWeightsExecute(this, inDatas, (unsigned char **)(inPtrs), 
                    outData, outExt, id);
      break;
    default:
      vtkErrorMacro(<< "Execute: Unknown input ScalarType");
      return;
    }

}

//----------------------------------------------------------------------------
// Make sure both the inputs are the same size. Doesn't really change 
// the output. Just performs a sanity check
void vtkImageLiveWireEdgeWeights::ExecuteInformation(vtkImageData **inputs,
                             vtkImageData *vtkNotUsed(output))
{
  int *in1Ext, *in2Ext;

  // we require that all inputs have been set.
  if (this->NumberOfInputs < this->NumberOfRequiredInputs)
    {
      vtkErrorMacro(<< "ExecuteInformation: Expected " << this->NumberOfRequiredInputs << " inputs, got only " << this->NumberOfInputs);
      return;      
    }
  

  // Check that all extents are the same.
  in1Ext = inputs[0]->GetWholeExtent();
  for (int i = 1; i < this->NumberOfInputs; i++) 
    {
      in2Ext = inputs[i]->GetWholeExtent();
      
      if (in1Ext[0] != in2Ext[0] || in1Ext[1] != in2Ext[1] || 
      in1Ext[2] != in2Ext[2] || in1Ext[3] != in2Ext[3] || 
      in1Ext[4] != in2Ext[4] || in1Ext[5] != in2Ext[5])
    {
      vtkErrorMacro("ExecuteInformation: Inputs 0 and " << i <<
            " are not the same size. " 
            << in1Ext[0] << " " << in1Ext[1] << " " 
            << in1Ext[2] << " " << in1Ext[3] << " vs: "
            << in2Ext[0] << " " << in2Ext[1] << " " 
            << in2Ext[2] << " " << in2Ext[3] );
      return;
    }
    }
}

//----------------------------------------------------------------------------
void vtkImageLiveWireEdgeWeights::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageMultipleInputFilter::PrintSelf(os,indent);

  // numbers
  os << indent << "MaxEdgeWeight: "<< this->MaxEdgeWeight << "\n";
  os << indent << "EdgeDirection: "<< this->EdgeDirection << "\n";
  os << indent << "NumberOfFeatures: "<< this->NumberOfFeatures << "\n";
  os << indent << "Neighborhood: "<< this->Neighborhood << "\n";
  os << indent << "TrainingMode: "<< this->TrainingMode << "\n";
  os << indent << "TrainingComputeRunningTotals: "<< this->TrainingComputeRunningTotals << "\n";
  os << indent << "RunningNumberOfTrainingPoints: "<< this->RunningNumberOfTrainingPoints << "\n";
  os << indent << "NumberOfTrainingPoints: "<< this->NumberOfTrainingPoints << "\n";

  // strings
  os << indent << "FileName: "<< this->FileName << "\n";
  os << indent << "TrainingFileName: "<< this->TrainingFileName << "\n";

  // arrays
  int idx;
  os << indent << "TrainingAverages:\n" << indent 
     << "(" << this->TrainingAverages[0];
  for (idx = 1; idx < this->NumberOfFeatures; ++idx)
  {
    os << indent << ", " << this->TrainingAverages[idx];
  }
  os << ")\n";
  os << indent << "TrainingVariances:\n" << indent 
     << "(" << this->TrainingVariances[0];
  for (idx = 1; idx < this->NumberOfFeatures; ++idx)
  {
    os << indent << ", " << this->TrainingVariances[idx];
  }
  os << ")\n";
}


//----------------------------------------------------------------------------
// Helper classes
//----------------------------------------------------------------------------

featureProperties::featureProperties()
{
  //this->Transform = &featureProperties::GaussianCost;
  this->Transform = NULL;
  this->NumberOfParams = 2;
  this->TransformParams = new float[this->NumberOfParams];
  this->TransformParams[0] = 0;
  this->TransformParams[1] = 1;
  this->Weight = 1;
}

featureProperties::~featureProperties()
{
  if (this->TransformParams != NULL) 
    {
      delete [] this->TransformParams;
    }
}

float featureProperties::GaussianCost(float x)
{
  float mean = this->TransformParams[0];
  float var = this->TransformParams[1];
  return(exp(-((x-mean)*(x-mean))/(2*var))/sqrt(6.28318*var));  
}


