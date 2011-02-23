/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageSmooth.cxx,v $
  Date:      $Date: 2006/02/28 19:19:40 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkImageSmooth.cxx,v $
  Language:  C++
  Date:      $Date: 2006/02/28 19:19:40 $
  Version:   $Revision: 1.7 $

  Copyright (c) 1993-2002 Ken Martin, Will Schroeder, Bill Lorensen 
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

#ifdef _WIN32
#define _USE_MATH_DEFINES
#endif

#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#if defined(__sun)
#include <ieeefp.h>
#endif

#include "vtkImageSmooth.h"

#include "vtkImageData.h"
#include "vtkObjectFactory.h"

#define DEBUG
//#undef DEBUG
//----------------------------------------------------------------------------

//vtkCxxRevisionMacro(vtkImageSmooth, "$Revision: 1.7 $");
//vtkStandardNewMacro(vtkImageSmooth);

//----------------------------------------------------------------------------


vtkImageSmooth* vtkImageSmooth::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageSmooth");
  if(ret)
    {
      return (vtkImageSmooth*)ret;
    }

  // If the factory was unable to create the object, then create it here.
  return new vtkImageSmooth;
}

vtkImageSmooth::vtkImageSmooth()
{
  NumberOfIterations = 5;
}

//----------------------------------------------------------------------------

vtkImageSmooth::~vtkImageSmooth()
{
  
}

//----------------------------------------------------------------------------

void vtkImageSmooth::ExecuteInformation(vtkImageData *inData, 
                                     vtkImageData *outData)
{
  this->vtkImageToImageFilter::ExecuteInformation(inData, outData);

  //  if (this->OutputScalarType != -1)
  // {
  // outData->SetScalarType(this->OutputScalarType);
  // }
}

float vtkImageSmooth::Init()
{
    //NumberOfIterations = 10;
    if(Dimensions == 3)
       dt = 0.2;
    else
       dt = 0.7;

    return 1.0;
}

/* This method performs 3D smoothing using gaussian curvature and sign of Mean curvature */
// this is kappa^(1/4) smoothing

template <class IT, class OT>
static void vtkImageSmooth3D(vtkImageSmooth *self,
                               vtkImageData *inData, IT *,
                               vtkImageData *outData, OT *outPtr,
                               int outExt[6], int id)
{

  int idxR, idxY, idxZ;
  int maxY, maxZ;
  int rowLength;
  float *temp_ptr;
/*  float *edge_ptr = 0;*/
  
  double lx,ly,lxx,lyy,lxy,lzz,lz, lyz, lxz;
  double kapa4, kapa4_mean;

  unsigned long frame_size;
  unsigned long shift_xyz;
  unsigned long xyz;
  unsigned long count = 1;
  unsigned long target;
  unsigned long offset_xf;

  int x,y,z;


  rowLength = (outExt[1] - outExt[0]+1)*inData->GetNumberOfScalarComponents();
  maxY = outExt[3] - outExt[2] + 1; 
  maxZ = outExt[5] - outExt[4] + 1;

  target = (unsigned long)((maxZ+1)*(maxY+1)/50.0);;
  target++;


  temp_ptr = (float*) calloc(maxZ*maxY*rowLength,sizeof(float));
  if(temp_ptr == NULL)
      return;

  //make a copy of original data, before we modify it
  outData->CopyAndCastFrom(inData,outExt);


  vtkFloatingPointType dx,dy,dz;
  dx = inData->GetSpacing()[0];
  dy = inData->GetSpacing()[1];
  dz = inData->GetSpacing()[2];
  if((dx <= 0) || (dy <= 0) || (dz <= 0))
      dx = dy = dz = 1.0;

  if(self->Init() == 0.0) {
      //self->vtkErrorMacro("Missing input");
      return;
  }

  for(int iter = 0;!self->AbortExecute && iter < self->NumberOfIterations;iter++)
  {

        for (idxZ = 0; idxZ < maxZ; idxZ++)
         {
            for (idxY = 0;idxY < maxY; idxY++)
            {
                
                if (!id)
                {
                    if (!(count%target))
                    {
                    self->UpdateProgress(count/(self->NumberOfIterations * 50.0*target));
                    }
                    count++;
                }

                frame_size = rowLength*maxY;
                xyz = idxY*rowLength+idxZ*frame_size;
                offset_xf = xyz+frame_size; //for offset in z-direction

                /* idxR + xyz gives our current position */

                for (idxR = 0; idxR < rowLength; idxR++)
                    {

                    /* at the boundaries we need to do some special things
                       so that we have access to the correct data or else we will crash
                       as we will access data not present */
                      if((idxR == 0) || (idxR == rowLength-1) || (idxY == 0) || (idxY == maxY-1) || (idxZ == 0) || (idxZ == maxZ-1)) 
                        {
                            if(idxZ == 0)
                            {
                                lz = (1/(2*dz)) * (outPtr[idxR+offset_xf] - outPtr[idxR+xyz]);
                                lzz = (1/(dz*dz)) * 2 * lz;

                                if((idxR != 0) && (idxR != rowLength -1))
                                    lxz = (1/(4*dx*dz)) * (outPtr[idxR+1+offset_xf] - outPtr[idxR+1+xyz] - outPtr[idxR-1+offset_xf]
                                              + outPtr[idxR-1+xyz]);

                                if(idxR == rowLength -1 )
                                    lxz = (1/(4*dx*dz)) * (outPtr[idxR+offset_xf] - outPtr[idxR+xyz] - outPtr[idxR-1+offset_xf]
                                               + outPtr[idxR-1+xyz]);

                                if(idxR == 0)
                                    lxz = (1/(4*dx*dz)) * (outPtr[idxR+1+offset_xf] - outPtr[idxR+1+xyz] - outPtr[idxR+offset_xf]
                                              + outPtr[idxR+xyz]);

                                if((idxY != 0) && (idxY != maxY -1))
                                    lyz = (1/(4*dy*dz)) * (outPtr[idxR+rowLength+offset_xf] - outPtr[idxR+rowLength+xyz] -
                                              outPtr[idxR-rowLength+offset_xf] + outPtr[idxR+xyz-rowLength]);
                                if(idxY == 0)
                                    lyz = (1/(4*dy*dz)) * (outPtr[idxR+rowLength+offset_xf] - outPtr[idxR+rowLength+xyz] -
                                              outPtr[idxR+offset_xf] + outPtr[idxR+xyz]);
                                if(idxY == maxY-1)
                                    lyz = (1/(4*dy*dz)) * (outPtr[idxR+offset_xf] - outPtr[idxR+xyz] -
                                                outPtr[idxR-rowLength+offset_xf] + outPtr[idxR+xyz-rowLength]);


                            }

                            if(idxZ == maxZ-1)
                            {

                                lz = (1/(2*dz)) * (outPtr[idxR+xyz] - outPtr[idxR+xyz-frame_size]);
                                lzz = (1/(dz*dz)) * 2 * lz;

                                if((idxR != 0) && (idxR != rowLength -1))
                                    lxz = (1/(4*dx*dz)) * (outPtr[idxR+1+xyz] - outPtr[idxR+xyz+1-frame_size] - outPtr[idxR-1+xyz]
                                              + outPtr[idxR+xyz-1-frame_size]);
                                if(idxR == 0)
                                    lxz = (1/(4*dx*dz)) * (outPtr[idxR+1+xyz] - outPtr[idxR+xyz+1-frame_size] - outPtr[idxR+xyz]
                                              + outPtr[idxR+xyz-frame_size]);
                                if(idxR == rowLength-1)
                                    lxz = (1/(4*dx*dz)) * (outPtr[idxR+xyz] - outPtr[idxR+xyz-frame_size] - outPtr[idxR-1+xyz]
                                              + outPtr[idxR+xyz-1-frame_size]);


                                if((idxY != 0) && (idxY != maxY -1))
                                    lyz = (1/(4*dy*dz)) * (outPtr[idxR+rowLength+xyz] - outPtr[idxR+xyz+rowLength-frame_size] -
                                              outPtr[idxR-rowLength+xyz] + outPtr[idxR+xyz-rowLength-frame_size]);
                                if(idxY == 0)
                                    lyz = (1/(4*dy*dz)) * (outPtr[idxR+rowLength+xyz] - outPtr[idxR+xyz+rowLength-frame_size] -
                                              outPtr[idxR+xyz] + outPtr[idxR+xyz-frame_size]);
                                if(idxY == maxY-1)
                                    lyz = (1/(4*dy*dz)) * (outPtr[idxR+xyz] - outPtr[idxR+xyz-frame_size] -
                                              outPtr[idxR-rowLength+xyz] + outPtr[idxR+xyz-rowLength-frame_size]);
                                
                            } 


                            if(idxR == 0)
                            {
                                lx = (1/(2*dx)) * (outPtr[(idxR+1)+xyz] - outPtr[idxR+xyz]);
                                lxx = (1/(dx*dx)) * (outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR+xyz]);
                                if(idxY == 0)
                                {
                                  ly = (1/(2*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR +xyz]);
                                  lyy = (1/(dy*dy)) * (outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz]);
                                  lxy = (1/(4*dx*dy)) * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz] -
                                      outPtr[idxR+xyz+rowLength] + outPtr[idxR+xyz]);
                                }
                                else if(idxY == maxY-1)
                                {
                                  ly = (1/(2*dy)) * (outPtr[idxR+xyz] - outPtr[idxR +xyz-rowLength]);
                                  lyy = (1/(dy*dy)) * (outPtr[idxR+xyz] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                                  lxy = (1/(4*dx*dy)) * (outPtr[idxR+1+xyz] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                                }
                                else
                                {
                                ly = (1/(2*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR +xyz-rowLength]);
                                lyy = (1/(dy*dy)) * (outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                                lxy = (1/(4*dx*dy)) * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR+xyz+rowLength] + outPtr[idxR+xyz-rowLength]);
                                }

                            }

                            if(idxR == rowLength-1)
                            {
                                lx = (1/(2*dx)) * (outPtr[idxR+xyz] - outPtr[idxR-1+xyz]);
                                lxx = (1/(dx*dx)) * (outPtr[idxR+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz]);
                                if(idxY == 0)
                                { 
                                  ly = (1/(2*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR +xyz]);
                                  lyy = (1/(dy*dy)) * (outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz]);
                                  lxy = (1/(4*dx*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz]);
                                }
                                 else if(idxY == maxY -1)
                                {
                                  ly = (1/(2*dy)) * (outPtr[idxR+xyz] - outPtr[idxR +xyz-rowLength]);
                                  lyy = (1/(dy*dy)) * (outPtr[idxR+xyz] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                                  lxy = (1/(4*dx*dy)) * (outPtr[idxR+xyz] - outPtr[idxR+xyz-rowLength] -
                                      outPtr[idxR-1+xyz] + outPtr[idxR-1+xyz-rowLength]);
                                }
                                 else
                                {
                                ly = (1/(2*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR +xyz-rowLength]);
                                lyy = (1/(dy*dy)) * (outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                                lxy = (1/(4*dx*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz-rowLength] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz-rowLength]);
                                }

                            }

                            if((idxY == 0) && (idxR != 0) && (idxR != rowLength-1))
                            {
                                lx = (1/(2*dx)) * (outPtr[(idxR+1)+xyz] - outPtr[idxR-1+xyz]);
                                ly = (1/(2*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz]);
                                lxx = (1/(dx*dx)) * (outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz]);
                                lyy = (1/(dy*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz]);
                                lxy = (1/(4*dx*dy)) * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz]);
                            }

                            if((idxY == maxY-1) && (idxR != 0) && (idxR != rowLength-1))
                             {
                                lx = (1/(2*dx)) * (outPtr[(idxR+1)+xyz] - outPtr[idxR-1+xyz]);
                                ly = (1/(2*dy)) * (outPtr[idxR+xyz] - outPtr[idxR+xyz-rowLength]);
                                lxx = (1/(dx*dx)) * (outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz]);
                                lyy = (1/(dy*dy)) * (-1*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                                lxy = (1/(4*dx*dy)) * (outPtr[idxR+1+xyz] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR-1+xyz] + outPtr[idxR-1+xyz-rowLength]);
                            }
                            

                            kapa4 = (((lyy*lzz-lyz*lyz)*lx*lx) + ((lxx*lzz-lxz*lxz)*ly*ly) + ((lxx*lyy-lxy*lxy)*lz*lz) +
                                     (2*lx*ly*(lxz*lyz-lxy*lzz)) + (2*ly*lz*(lxy*lxz-lyz*lxx)) +
                                     (2*lx*lz*(lxy*lyz-lxz*lyy)));
                            

                            kapa4_mean = ((lx*lx*(lyy+lzz)) + (ly * ly *(lzz+lxx)) + (lz*lz*(lxx+lyy)) -
                            (2*lx*ly*lxy) - (2*ly*lz*lyz) - (2*lx*lz*lxz));

                            if(kapa4 < 0)
                                    kapa4 = pow(-kapa4,0.25);
                            else
                                    kapa4 = pow(kapa4,0.25); 

                            /* use the sign of mean curvature */
                            if(kapa4_mean < 0)
                                  kapa4 = -kapa4;

                            temp_ptr[idxR+xyz] = kapa4;

                            

                            continue;
                    } //end if (the BIG OR's)

                        /*if not on any of the boundaries of the cube, compute
                          as normal stuff */

                        lx = (1/(2*dx)) * (outPtr[(idxR+1)+xyz] - outPtr[idxR-1+xyz]);
                        ly = (1/(2*dy)) * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz-rowLength]);
                        lz = (1/(2*dz)) * (outPtr[idxR+offset_xf] - outPtr[idxR+xyz-frame_size]);

                        lxx = (1/(dx*dx)) * (outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz]);
                        lyy = (1/(dy*dy)) * (outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength]);
                        lzz = (1/(dz*dz)) * (outPtr[idxR+offset_xf] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-frame_size]);


                        lxy = (1/(4*dx*dy)) * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz-rowLength]);
                        lyz = (1/(4*dy*dz)) * (outPtr[idxR+rowLength+offset_xf] - outPtr[idxR+rowLength+xyz-frame_size] -
                                              outPtr[idxR-rowLength+offset_xf] + outPtr[idxR+xyz-rowLength-frame_size]);
                        lxz = (1/(4*dx*dz)) * (outPtr[idxR+1+offset_xf] - outPtr[idxR+1+xyz-frame_size] - outPtr[idxR-1+offset_xf]
                                              + outPtr[idxR+xyz-1-frame_size]);

                        // this is gaussian curvature                      
                        kapa4 = (((lyy*lzz-lyz*lyz)*lx*lx) + ((lxx*lzz-lxz*lxz)*ly*ly) + ((lxx*lyy-lxy*lxy)*lz*lz) +
                                     (2*lx*ly*(lxz*lyz-lxy*lzz)) + (2*ly*lz*(lxy*lxz-lyz*lxx)) +
                                     (2*lx*lz*(lxy*lyz-lxz*lyy))); 

                        //calculate mean curvature so that we can use its sign
                        kapa4_mean = ((lx*lx*(lyy+lzz)) + (ly * ly *(lzz+lxx)) + (lz*lz*(lxx+lyy)) -
                            (2*lx*ly*lxy) - (2*ly*lz*lyz) - (2*lx*lz*lxz));

                        if(kapa4 < 0)
                            kapa4 = pow(-kapa4,0.25);
                        else
                            kapa4 = pow(kapa4,0.25); 
                        

                        /* use the sign of mean curvature. Without using this, the algorithm is highly
                           unstable and basically blows up. Using the sign of H instead of K gives the right
                           smoothing effect. */
                            if(kapa4_mean < 0)
                                  kapa4 = -kapa4;

                       /* We are not going to divide by gradient, since it takes a huge number of iterations
                          to smooth the image. we have to set a value of 1.0 for dt and take about 200 iterations
                          to smooth the image compared to 3 iterations if we dont divide by gradient every time.

                        if(iter == 0)
                          edge_ptr[idxR+xyz] = (1+lx*lx+ly*ly+lz*lz);*/

                        //our temporary storage of curvature data
                        temp_ptr[idxR+xyz] = kapa4;

                } //end for(idxR < rowLength)

            } //end for(idxY < maxY)



        } //end for(idxZ < maxZ)


        //modify our data based on this smoothing time-step
int temp;
int final;
        for(z = 0; z < maxZ;z++)
        {
            for(y = 0;y< maxY;y++)
            {
                shift_xyz = y*rowLength+z*frame_size;
                for(x=0;x<rowLength;x++)
                {   
                    temp = (int)(self->dt * temp_ptr[x+shift_xyz]);
                    final = (int)(outPtr[x+shift_xyz] + (OT)temp);

                    /* do the comparison *before* the cast */
                    if(final > 255)
                        outPtr[x+shift_xyz] = 255;
                    else
                      if(final < 0)
                        outPtr[x+shift_xyz] = 0;
                      else
                        outPtr[x+shift_xyz] = (OT)(final);
                }
            }
        }



    } //end for(iterations )

        
    

    if(!temp_ptr)
      free(temp_ptr);
/*
#ifdef DEBUG
    if(!fp)
        fclose(fp);
#endif
*/

 return;

}


//----------------------------------------------------------------------------

// This templated function executes the filter for any type of data.
// this method performs 2D smoothing, ie. kappa^(1/3) smoothing.

template <class IT, class OT>
static void vtkImageSmoothExecute(vtkImageSmooth *self,
                               vtkImageData *inData, IT *,
                               vtkImageData *outData, OT *outPtr,
                               int outExt[6], int id)
{

  int idxR, idxY, idxZ;
  int maxY, maxZ;
  int rowLength;
  float *temp_ptr;
  float *edge_ptr;

  float lx,ly,lxx,lyy,lxy,kapa;
  unsigned long shift_xyz;
  unsigned long xyz;
  unsigned long count = 1;
  unsigned long target;
  int x,y,z;

/*
# ifdef DEBUG
        FILE *fp;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkImageSmooth\\outtest.txt","w+");
    Fflush(fp);


        if(fp == NULL)
        return;
#endif

  */

  // find the region to loop over

  rowLength = (outExt[1] - outExt[0]+1)*inData->GetNumberOfScalarComponents();
  maxY = outExt[3] - outExt[2] + 1; 
  maxZ = outExt[5] - outExt[4] + 1;
  target = (unsigned long)((maxZ+1)*(maxY+1)/50.0);;
  target++;
  if(self->Init() == 0.0) {
      //self->vtkErrorMacro("Missing input");
      return;
  }

  //make a copy of original data, before we modify it
  outData->CopyAndCastFrom(inData,outExt);

  // Get increments to march through data 

  temp_ptr = (float*) calloc((maxZ)*(maxY)*rowLength,sizeof(float));
  if(temp_ptr == NULL)
      return;

  edge_ptr = (float*) calloc((maxZ)*(maxY)*rowLength,sizeof(float));
  if(edge_ptr == NULL)
      return;

/*
#ifdef DEBUG

  fprintf(fp,"scalar size %s\n",inData->GetScalarTypeAsString());
  fprintf(fp,"Rows = %d, Y = %d, Z = %ld, points = %ld\n",rowLength,maxY,maxZ,inData->GetNumberOfPoints);
 fprintf(fp,"OutExt[0] = %d, [1] = %d, [2] = %d, [3] = %d, [4] = %d, [5] = %d\n",outExt[0],outExt[1],
             outExt[2],outExt[3],outExt[4],outExt[5]);
 fprintf(fp,"dims[0] = %d, [1] = %d, [2] = %d\n",dims[0],dims[1],dims[2]);

  fflush(fp);

#endif
*/

  for(int iter = 0;!self->AbortExecute && iter < self->NumberOfIterations;iter++)
  {

        for (idxZ = 0; idxZ < maxZ; idxZ++)
         {
            for (idxY = 0;idxY < maxY; idxY++)
            {
                
                if (!id)
                {
                    if (!(count%target))
                    {
                    self->UpdateProgress(count/(self->NumberOfIterations * 50.0*target));
                    }
                    count++;
                }

                xyz = idxY*rowLength+idxZ*maxY*rowLength;
                for (idxR = 0; idxR < rowLength; idxR++)
                    {

                    /* at the boundaries we need to do some special things
                       so that we have access to the correct data or else we will crash
                       as we will access data not present */
                        if((idxR == 0) || (idxR == rowLength-1) || (idxY == 0) || (idxY == maxY-1)) 
                        {
                            if((idxR == 0) && (idxY != 0) && (idxY != maxY-1))
                            {
                                lx = 0.5 * (outPtr[(idxR+1)+xyz] - outPtr[idxR+xyz]);
                                ly = 0.5 * (outPtr[idxR+xyz+rowLength] - outPtr[idxR +xyz-rowLength]);
                                lxx = 2 * outPtr[idxR+1+xyz] - 2 * outPtr[idxR+xyz];
                                lyy = outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength];
                                lxy = 0.25 * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR+xyz+rowLength] + outPtr[idxR+xyz-rowLength]);

                                kapa = (ly*ly*lxx - 2*lx*ly*lxy + lx*lx*lyy); 
                                if(kapa < 0)
                                    kapa = -1 * pow(-kapa,1/3);
                                else
                                    kapa = pow(kapa,1/3); 

                                if(iter == 0)
                                    edge_ptr[idxR+xyz] = 1 + lx*lx + ly*ly;

                                temp_ptr[idxR+xyz] = kapa; 

                                continue;
                            }

                            if(idxR == rowLength-1)
                            {
                                lx = 0.5 * (outPtr[idxR+xyz] - outPtr[idxR-1+xyz]);
                                ly = 0.5 * (outPtr[idxR+xyz+rowLength] - outPtr[idxR +xyz-rowLength]);
                                lxx = 2 * outPtr[idxR-1+xyz] - 2 * outPtr[idxR+xyz];
                                lyy = outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength];
                                lxy = 0.25 * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz-rowLength] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz-rowLength]);
                                kapa = (ly*ly*lxx - 2*lx*ly*lxy + lx*lx*lyy); 
                                if(kapa < 0)
                                    kapa = -1 * pow(-kapa,1/3);
                                else
                                    kapa = pow(kapa,1/3); 

                                if(iter == 0)
                                    edge_ptr[idxR+xyz] = 1 + lx*lx + ly*ly;

                                temp_ptr[idxR+xyz] = kapa; 
                                continue;
                            }

                            if(idxY == 0)
                            {
                                lx = 0.5 * (outPtr[(idxR+1)+xyz] - outPtr[idxR-1+xyz]);
                                ly = 0.5 * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz]);
                                lxx = outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz];
                                lyy = outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz];
                                lxy = 0.25 * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz]);
                                kapa = (ly*ly*lxx - 2*lx*ly*lxy + lx*lx*lyy); 
                                if(kapa < 0)
                                    kapa = -1 * pow(-kapa,1/3);
                                else
                                    kapa = pow(kapa,1/3); 

                                if(iter == 0)
                                    edge_ptr[idxR+xyz] = 1 + lx*lx + ly*ly;

                                temp_ptr[idxR+xyz] = kapa; 
                                continue;
                            }


                            if(idxY == maxY-1)
                             {
                                lx = 0.5 * (outPtr[(idxR+1)+xyz] - outPtr[idxR-1+xyz]);
                                ly = 0.5 * (outPtr[idxR+xyz] - outPtr[idxR+xyz-rowLength]);
                                lxx = outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz];
                                lyy = -1*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength];
                                lxy = 0.25 * (outPtr[idxR+1+xyz] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR-1+xyz] + outPtr[idxR-1+xyz-rowLength]);
                                kapa = (ly*ly*lxx - 2*lx*ly*lxy + lx*lx*lyy); 
                                if(kapa < 0)
                                    kapa = -1 * pow(-kapa,1/3);
                                else
                                    kapa = pow(kapa,1/3); 

                                if(iter == 0)
                                    edge_ptr[idxR+xyz] = 1 + lx*lx + ly*ly;

                                temp_ptr[idxR+xyz] = kapa; 
                                continue;
                            }

                            

                            continue;
                        }

                        lx = 0.5 * (outPtr[(idxR+1)+xyz] - outPtr[idxR-1+xyz]);

                        ly = 0.5 * (outPtr[idxR+xyz+rowLength] - outPtr[idxR+xyz-rowLength]);

                        lxx = outPtr[(idxR+1)+xyz] - 2 * outPtr[idxR+xyz] + outPtr[idxR-1+xyz];

                        
                        lyy = outPtr[idxR+xyz+rowLength] - 2*outPtr[idxR+xyz] + outPtr[idxR+xyz-rowLength];

                        

                        lxy = 0.25 * (outPtr[idxR+1+xyz+rowLength] - outPtr[idxR+1+xyz-rowLength] -
                                      outPtr[idxR-1+xyz+rowLength] + outPtr[idxR-1+xyz-rowLength]);

                        
                        
                        kapa = (ly*ly*lxx - 2*lx*ly*lxy + lx*lx*lyy); 
                        if(kapa < 0)
                            kapa = -1 * pow(-kapa,1/3);
                        else
                            kapa = pow(kapa,1/3); 

                        if(iter == 0)
                           edge_ptr[idxR+xyz] = 1 + lx*lx + ly*ly;

                        temp_ptr[idxR+xyz] = kapa; 
                    
            
                          }
                /*
              #ifdef DEBUG
                fprintf(fp,"Completed %d Rows\n",idxY);
                #endif */

            } //for idxY
            /*
        #ifdef DEBUG
            fprintf(fp,"Completed %d frames\n",idxZ);
            #endif */
         }

   /* update our image from the smoothed data */
        for(z = 0; z < maxZ;z++)
        {
            for(y = 0;y< maxY;y++)
            {
                shift_xyz = y*rowLength+z*maxY*rowLength;
                for(x=0;x<rowLength;x++)
                    outPtr[x+shift_xyz] = (OT)(outPtr[x+shift_xyz] + 
                         self->dt * (temp_ptr[x+shift_xyz]/edge_ptr[x+shift_xyz]));
            }
        }
            

  } //numberof iterations


  if(!temp_ptr)
      free(temp_ptr);

  if(!edge_ptr)
      free(edge_ptr);
 /*
#ifdef DEBUG
  if(!fp)
     fclose(fp);
#endif
  */

return;

}


//----------------------------------------------------------------------------

// called if 2D smoothing is to be done
template <class T>
static void vtkImageSmoothExecute1(vtkImageSmooth *self,
                                vtkImageData *inData, T *inPtr,
                                vtkImageData *outData,
                                int outExt[6], int id)
{
  void *outPtr = outData->GetScalarPointerForExtent(outExt);
  
    switch (outData->GetScalarType())
    {
      vtkTemplateMacro7(vtkImageSmoothExecute, self, inData, inPtr,
                      outData, (VTK_TT *)(outPtr),outExt, id);

    default:
      vtkGenericWarningMacro("Execute: Unknown input ScalarType");
      return;
      }
}

// called if 3D smoothing is to be done
template <class T>
static void vtkImageSmoothExecute3D(vtkImageSmooth *self,
                                vtkImageData *inData, T *inPtr,
                                vtkImageData *outData,
                                int outExt[6], int id)
{
  void *outPtr = outData->GetScalarPointerForExtent(outExt);
  
    switch (outData->GetScalarType())
    {
      vtkTemplateMacro7(vtkImageSmooth3D, self, inData, inPtr,
                      outData, (VTK_TT *)(outPtr),outExt, id);

    default:
      vtkGenericWarningMacro("Execute: Unknown input ScalarType");
      return;
      }
}

//----------------------------------------------------------------------------

// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.

void vtkImageSmooth::ThreadedExecute(vtkImageData *inData, 
                                  vtkImageData *outData,
                                  int outExt[6], int id)
{
  int inExt[6];
  void *inPtr = inData->GetScalarPointerForExtent(outExt);

  //extend our image for computations
    this->ComputeInputUpdateExtent(inExt,outExt);
    
     if(Dimensions == 2)
        switch (inData->GetScalarType())
        {
          vtkTemplateMacro6(vtkImageSmoothExecute1, this, 
                        inData, (VTK_TT *)(inPtr), outData, outExt, id);
        default:
          vtkErrorMacro(<< "Execute: Unknown ScalarType");
          return;
        } 
     
     if(Dimensions == 3)
        switch (inData->GetScalarType())
        {
          vtkTemplateMacro6(vtkImageSmoothExecute3D, this, 
                        inData, (VTK_TT *)(inPtr), outData, outExt, id);
        default:
          vtkErrorMacro(<< "Execute: Unknown ScalarType");
          return;
        } 

    return;
}

//----------------------------------------------------------------------------
void vtkImageSmooth::ComputeInputUpdateExtent(int inExt[6], 
                int outExt[6])
{
  int *wholeExtent;
  int idx, border;

  border = 2;

  // copy
  memcpy((void *)inExt, (void *)outExt, 6 * sizeof(int));
  // Expand filtered axes
  wholeExtent = this->GetInput()->GetWholeExtent();

  for (idx = 0; idx < 3; ++idx)
    {
    inExt[idx*2] -= border;
    if (inExt[idx*2] < wholeExtent[idx*2])
      {
      inExt[idx*2] = wholeExtent[idx*2];
      }

    inExt[idx*2+1] += border;
    if (inExt[idx*2+1] > wholeExtent[idx*2+1])
      {
      inExt[idx*2+1] = wholeExtent[idx*2+1];
      }
    }

}


void vtkImageSmooth::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os,indent);

  // os << indent << "Smooth: " << this->Smooth << "\n";
  // os << indent << "Output Scalar Type: " << this->OutputScalarType << "\n";
}

