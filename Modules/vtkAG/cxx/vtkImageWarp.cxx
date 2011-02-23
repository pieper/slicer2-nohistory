/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWarp.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
#include "vtkImageCast.h"
#include "vtkImageGaussianSmooth.h"
#include "vtkImageHistogramNormalization.h"
#include "vtkImageMathematics.h"
#include "vtkImageReslice.h"
#include "vtkImageResliceST.h"
#include "vtkImageShrink3D.h"
#include "vtkImageTransformIntensity.h"
#include "vtkImageWarp.h"
#include "vtkImageWarpForce.h"
#include "vtkImageWarpDMForce.h"
#include "vtkImageWarpOFForce.h"
#include "vtkObjectFactory.h"
#include "vtkImageExtractComponents.h"
#include "vtkImageAppendComponents.h"

#ifdef WIN32
#include <float.h>
#endif

//Modified by Liu
//using namespace std;

#include <vtkStructuredPointsWriter.h>
using namespace std;


static void Write(vtkImageData* image,const char* filename)
{
  vtkStructuredPointsWriter* writer = vtkStructuredPointsWriter::New();
  writer->SetFileTypeToBinary();
  writer->SetInput(image);
  writer->SetFileName(filename);
  writer->Write();
  writer->Delete();
}

vtkImageWarp* vtkImageWarp::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageWarp");
  if(ret)
    {
    return (vtkImageWarp*)ret;
    }
  // If the factory was unable to create the object, then create it here.i
  return new vtkImageWarp;
}

vtkImageWarp::vtkImageWarp()
{
  this->MinimumIterations=0;
  this->MaximumIterations=50;
  this->MinimumLevel=-1;
  this->MaximumLevel=-1;
  // the following makes the filter (0.25,0.5,0.25)
  this->MinimumStandardDeviation=sqrt(-1./(2.*log(.5)));
  this->MaximumStandardDeviation=1.25;
  this->Verbose=0;
  this->ForceType=VTK_IMAGE_WARP_DM;
  this->UseSSD=1;
  this->SSDEpsilon=1e-3;
  this->Interpolation=1; // linear

  this->Target=0;
  this->Source=0;
  this->Mask=0;
  this->GeneralTransform=vtkGeneralTransform::New();
  this->WorkTransform=vtkGridTransform::New();
  this->IntensityTransform=0;
  // Modified by Caan
  this->ResliceTensors=1;
 // this->ResliceTensors=1;
}

vtkImageWarp::~vtkImageWarp()
{
  this->SetTarget(0);
  this->SetSource(0);
  this->SetMask(0);
  if(this->WorkTransform)
    {
    this->WorkTransform->Delete();
    }
  if(this->GeneralTransform)
    {
    this->GeneralTransform->Delete();
    }
  if(this->IntensityTransform)
    {
    this->IntensityTransform->Delete();
    }
}

bool vtkImageWarp::IsMaximumLevel(int l, int* ext)
{
  // if defined by user
  if(this->MaximumLevel>=0)
    {
    return l>this->MaximumLevel;
    }

  // shrink untill all dimensions < 60
  if(ext[1]-ext[0] < 60 &&
     ext[3]-ext[2] < 60 &&
     ext[5]-ext[4] < 60)
    {
    return true;
    }
  
  return false;
}

void vtkImageWarp::CreatePyramid()
{
  // Modified by Liu.
  int l;

  vtkDebugMacro("CreatePyramid");

  this->GetTarget()->Update();
  this->GetSource()->Update();

  this->Targets.push_back(this->GetTarget()); 
  this->Sources.push_back(this->GetSource());
  if(this->GetMask())
    {
    vtkImageCast* c = vtkImageCast::New();
    c->SetOutputScalarTypeToUnsignedChar();

    this->Masks.push_back(vtkImageData::New()); 
    c->SetInput(this->GetMask());
    c->SetOutput(this->Masks[0]);
    this->Masks[0]->Update();
    this->Masks[0]->SetSource(0);

    c->Delete();
    }
  
  // Shrink data for each level
  vtkImageShrink3D* Shrink = vtkImageShrink3D::New();
  if(this->GetInterpolation()==0)
    {
    Shrink->AveragingOff();
    }
  else
    {
    Shrink->AveragingOn();
    }
// Modified by Liu,
//  for(int l=1;!this->IsMaximumLevel(l,this->Targets[l-1]->GetWholeExtent());++l)
  for( l=1;!this->IsMaximumLevel(l,this->Targets[l-1]->GetWholeExtent());++l)
    {
    int* ext=this->Targets[l-1]->GetWholeExtent();

    int sx=ext[1]-ext[0] < 60 ? 1 : 2;
    int sy=ext[3]-ext[2] < 60 ? 1 : 2;
    int sz=ext[5]-ext[4] < 60 ? 1 : 2;
    Shrink->SetShrinkFactors(sx,sy,sz);

    this->Targets.push_back(vtkImageData::New());
    Shrink->SetInput(this->Targets[l-1]);
    Shrink->SetOutput(this->Targets[l]);
    this->Targets[l]->Update();
    this->Targets[l]->SetSource(0);
    
    this->Sources.push_back(vtkImageData::New());
    Shrink->SetInput(this->Sources[l-1]);
    Shrink->SetOutput(this->Sources[l]);
    this->Sources[l]->Update();
    this->Sources[l]->SetSource(0);

    if(this->GetMask())
      {
      cout << "Masking" << endl;
      cout.flush();
      this->Masks.push_back(vtkImageData::New());
      Shrink->SetInput(this->Masks[l-1]);
      Shrink->SetOutput(this->Masks[l]);
      this->Masks[l]->Update();
      this->Masks[l]->SetSource(0);
      }
    }

  Shrink->Delete();
//  for(int l=0;l<int(this->Targets.size());++l)
// Modified by Liu,
  for(l=0;l<int(this->Targets.size());++l)
    {
    this->Displacements.push_back(vtkImageData::New());
    this->Displacements[l]->SetScalarType(VTK_FLOAT);
    this->Displacements[l]->SetNumberOfScalarComponents(3);
    this->Displacements[l]->SetSpacing(this->Targets[l]->GetSpacing());
    this->Displacements[l]->SetOrigin(this->Targets[l]->GetOrigin());
    this->Displacements[l]->SetExtent(this->Targets[l]->GetWholeExtent());
    this->Displacements[l]->Update();
    this->Displacements[l]->AllocateScalars();
    }

  // null data or it might seg fault...
  vtkImageData* def=this->Displacements[this->Targets.size()-1];
  int* dims=def->GetDimensions();
  memset(def->GetScalarPointer(),0,dims[0]*dims[1]*dims[2]*
     def->GetNumberOfScalarComponents()*def->GetScalarSize());
}

void vtkImageWarp::FreePyramid()
{
  vtkDebugMacro("FreePyramid");

  //Modified by Liu.
  

  //typedef vector<vtkImageData*>::size_type size_t;
  typedef vector<vtkImageData*>::size_type size_t;
  size_t l;

  // Modified by Liu
  //for(size_t l=1;l<this->Targets.size();++l)
  for( l=1;l<this->Targets.size();++l)
    {
    this->Targets[l]->Delete();
    }
  this->Targets.clear();
  //Modified by Liu
//  for(size_t l=1;l<this->Sources.size();++l)
  for( l=1;l<this->Sources.size();++l)

    {
    this->Sources[l]->Delete();
    }
  this->Sources.clear();

  //Modifiedf by Liu
//  for(size_t l=0;l<this->Masks.size();++l)
  for( l=0;l<this->Masks.size();++l)
    {
    this->Masks[l]->Delete();
    }
  this->Masks.clear();
// Modified by Liu
//  for(size_t l=0;l<this->Displacements.size();++l)
  for( l=0;l<this->Displacements.size();++l)
    {
    this->Displacements[l]->Delete();
    }
  this->Displacements.clear();
}

void vtkImageWarp::UpdatePyramid(int level)
{
  vtkDebugMacro("UpdatePyramid: Level=" << level);
  if(level > 0)
    {
    vtkImageReslice* Scale=vtkImageReslice::New();
    Scale->SetInput(this->Displacements[level]);
    Scale->SetOutput(this->Displacements[level-1]);
    Scale->SetOutputOrigin(this->Displacements[level-1]->GetOrigin());
    Scale->SetOutputSpacing(this->Displacements[level-1]->GetSpacing());
    Scale->SetOutputExtent(this->Displacements[level-1]->GetWholeExtent());
    Scale->SetInterpolationModeToLinear();
    Scale->WrapOff();
    Scale->MirrorOff();

    this->Displacements[level-1]->Update();
    this->Displacements[level-1]->SetSource(0);

    Scale->Delete();
    }
}


template <class T1, class T2>
static void vtkImageWarpSSDExecute2(vtkImageData* t,T1* tptr,
                                      vtkImageData* s,T2* sptr,
                                      vtkImageData* m, int* ext,double& res)
{
  unsigned char* mptr = 0;
  if(m)
    {
    mptr=(unsigned char*)(m->GetScalarPointerForExtent(ext));
    }

//  int weight[5];
  int comp=t->GetNumberOfScalarComponents();
  
  double ssd=0;
  for(int z=ext[4];z<=ext[5];++z)
    {
    for(int y=ext[2];y<=ext[3];++y)
      {
      for(int x=ext[0];x<=ext[1];++x)
        {
        double v=0;
        for(int c=0;c<comp;++c)
          {
      v += pow(double(*tptr) - double(*sptr), (double)2.);
          ++tptr;
          ++sptr;
          }
        if(mptr)
          {
          v*=*mptr/255.;
          }
        ssd+=v;

        if(mptr)
          {
          ++mptr;
          }
        }
      }
      //cout << "z: " << z
      //     << " ssd " << ssd
      //     << "." << endl;
      //cout.flush();
    }
  int* dims=t->GetDimensions();
  int n=dims[0]*dims[1]*dims[2];
  res=sqrt(ssd)/n;
      //cout << "n: " << n
      //     << " ssd " << ssd
      //     << " res " << res
      //     << "." << endl;
      //cout.flush();
}

template <class T>
static void vtkImageWarpSSDExecute1(vtkImageData* t,T* tptr,
                                    vtkImageData* s,vtkImageData* m,
                                    int* ext,double& res)
{
  void* sptr = s->GetScalarPointerForExtent(ext);
  switch (t->GetScalarType())
    {
    vtkTemplateMacro7(vtkImageWarpSSDExecute2,t,tptr,s,(VTK_TT *)sptr,m,ext,res);
    default:
      vtkGenericWarningMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}

double vtkImageWarp::SSD(vtkImageData* t,vtkImageData* s,vtkImageData* m)
{
  int* ext = t->GetExtent();
  s->SetUpdateExtent(ext);

  t->Update();
  s->Update();
  if(m)
    {
    m->Update();
    }

  void* tptr = t->GetScalarPointerForExtent(ext);

  double res=0;
  switch (t->GetScalarType())
    {
    vtkTemplateMacro6(vtkImageWarpSSDExecute1,t,(VTK_TT *)tptr,s,m,ext,res);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return -1;
    }
  return res;
}

// float vtkImageWarp::MaxDispDiff(vtkImageData* t,vtkImageData* s,vtkImageData* m)
// {
//   int* ext = t->GetExtent();
//   s->SetUpdateExtent(ext);

//   t->Update();
//   s->Update();
//   if(m)
//     {
//     m->Update();
//     }

//   float* tptr = (float*)(t->GetScalarPointerForExtent(ext));
//   float* sptr = (float*)(s->GetScalarPointerForExtent(ext));
//   unsigned char* mptr = 0;
//   if(m)
//     {
//     mptr=(unsigned char*)(m->GetScalarPointerForExtent(ext));
//     }

//   float max=0;
//   float diff;
//   for(int z=ext[4];z<=ext[5];++z)
//     {
//     for(int y=ext[2];y<=ext[3];++y)
//       {
//       for(int x=ext[0];x<=ext[1];++x)
//     {
//     if(!mptr || *mptr)
//       {
//           for(int c=0;c<3;++c)
//             {
//             diff=fabs(*tptr-*sptr);
//             if(diff>max)
//               {
//               max=diff;
//               }
//             ++tptr;
//             ++sptr;
//             }
//           }
//     else
//       {
//       tptr+=3;
//       sptr+=3;
//       }
//     if(mptr)
//       {
//       ++mptr;
//       }
//     }
//       }
//     }
//   return max;
// }

// this is how it should work:
// for many iterations do:
// - compute intensity correction for every channel according
//   to current deformation
// - apply intensity correction to initial source image
// - compute forces:
//     for every channel:
//     = compute gradient
//     = resample gradient & channel
//     = use result to compute force for this channel
//     add all channel forces together to provide the final force.
// - add forces to current deformation
// - smooth deformation
// 
// this means I have to resample a gradient + 2 images for every
// channel, for every iteration.  that's just too much for me.  it
// would probably be possible to pack everything together in one big
// class that does everything and cut down things to 1 or 2
// resamplings, but I prefered to stay away from that option.  might
// be an error, but I haven't felt the need to go that way yet.
//
// hence, I just resample the image (all channels at the same time)
// and compute gradient forces for each channel.  this implies only 1
// resampling.  With a bit of luck, that doesn't change the result
// much.
//
// this it how it works:
// for many iterations do:
// - resample source image
// - compute intensity correction for every channel
// - apply intensity correction to resliced source image
// - compute forces:
//     for every channel:
//     = compute gradient
//     = use result to compute force for this channel
//     add all channel forces together to provide the final force.
// - add forces to current deformation
// - smooth deformation
void vtkImageWarp::InternalUpdate()
{
  vtkDebugMacro("Execute");
  this->CreatePyramid();

  // works better with reversed transfo.  I have no clue why this is
  // the way it is.  I just don't get inverses...
  this->GeneralTransform->Identity();
  this->GeneralTransform->Inverse();
  this->GeneralTransform->PostMultiply();
  this->GeneralTransform->Concatenate(this->WorkTransform);

  float ssde=this->GetSSDEpsilon();
  float MinStdDev=this->GetMinimumStandardDeviation();
  float StdDev=this->GetMaximumStandardDeviation();
  int reslicetensorinterv=5;
  
  if(StdDev < MinStdDev)
    {
    StdDev=MinStdDev;
    }
  for(int l=this->Displacements.size()-1;l>-1;--l)
    {
      cout << "Level: " << l
       << "MinimumLevel " <<this->MinimumLevel 
       << "." << endl;
      cout.flush();

    if(l>=this->MinimumLevel)
      {
      int* dims = this->Targets[l]->GetDimensions();
      if(this->Verbose)
        {
        cout << "Level: " << l
             << ". Size: " << dims[0] << " " << dims[1] << " " << dims[2]
             << ". Max iter: " << (l+1)*this->MaximumIterations
             << ". Std dev: " << StdDev
             << "." << endl;
        }

      vtkImageData* mask=0;
      if(this->Masks.size()!=0)
        {
        mask=this->Masks[l];
        }

      // Build the registration pipeline at level l
      // Set Transform to current displacement grid.
      this->WorkTransform->SetDisplacementGrid(this->Displacements[l]);
      
     
      // where the hell can I find a portable include file 
      // that defines DBL_MAX?
      // double lastssd=DBL_MAX;
      //double lastssd=10000000000.0;
      double lastssd=VTK_DOUBLE_MAX;
      double ssd=0;
      for(int i=0;i<(l+1)*this->MaximumIterations;++i)
        {


            // pipeline objects
            vtkImageReslice* reslice = 0;
            // As tensor reorientation is very slow, only do it
            // every reslicetensorinterv steps.
            if(!this->ResliceTensors)
              {
              reslice = vtkImageReslice::New();
              }
              else
              {
                if(i%reslicetensorinterv)
                  {
                  reslice = vtkImageReslice::New();
                  }
                  else
                  {
                  reslice = vtkImageResliceST::New();
                  }
              }
            vtkImageTransformIntensity* transint = vtkImageTransformIntensity::New();
        vtkImageGaussianSmooth* tsmooth = vtkImageGaussianSmooth::New();
        vtkImageGaussianSmooth* ssmooth = vtkImageGaussianSmooth::New();

            vtkImageWarpForce* force = 0;

            switch(this->ForceType)
              {
              case VTK_IMAGE_WARP_DM:
                force = vtkImageWarpDMForce::New();
                break;
              case VTK_IMAGE_WARP_OF:
                force = vtkImageWarpOFForce::New();
                break;
              default:
                vtkErrorMacro(<< "Unknown warp force");
                break;
              }
            vtkImageMathematics* addvelo = vtkImageMathematics::New();
            vtkImageGaussianSmooth* smooth = vtkImageGaussianSmooth::New();
            vtkImageExtractComponents* extracts = vtkImageExtractComponents::New();
            vtkImageExtractComponents* extractt = vtkImageExtractComponents::New();
    vtkImageAppendComponents* append= vtkImageAppendComponents::New();
        vtkImageData* tmp=vtkImageData::New();
        // reslice source
            reslice->SetInput(this->Sources[l]);
            reslice->SetResliceTransform(this->GeneralTransform);
            reslice->SetInformationInput(this->Targets[l]);
            reslice->WrapOff();
            reslice->MirrorOff();
            reslice->SetInterpolationMode(this->GetInterpolation());
            reslice->ReleaseDataFlagOn();
reslice->Update();
            
        extractt->SetInput(this->Targets[l]);
        extracts->SetInput(reslice->GetOutput());
        
        // Loop over channels, since intensity correction is done per channel
        for(int comp=0;comp<(this->Targets[l]->GetNumberOfScalarComponents());comp++)
        {
        
          extractt->SetComponents(comp);
          extracts->SetComponents(comp);

          // find intensity correction
              // initialize intensity transformation
              if(this->IntensityTransform)
            {
            this->IntensityTransform->SetTarget(extractt->GetOutput());
            this->IntensityTransform->SetSource(extracts->GetOutput());
            this->IntensityTransform->SetMask(mask);
            }
              // correct source intensities
          transint->SetInput(extracts->GetOutput());
              transint->SetIntensityTransform(this->IntensityTransform);
              transint->Update();
              if (!comp) {
            tmp->DeepCopy(transint->GetOutput());
          } else {
        append->SetInput(0,tmp);
        append->SetInput(1,transint->GetOutput());
        append->Update();
        tmp->DeepCopy(append->GetOutput());
          }
        }

       // smooth target     
        tsmooth->SetInput(this->Targets[l]);     
        tsmooth->SetStandardDeviations(StdDev,StdDev,StdDev);     
tsmooth->Update();
        // smooth source     
        //ssmooth->SetInput(append->GetOutput());     
        ssmooth->SetInput(tmp);
    ssmooth->SetStandardDeviations(StdDev,StdDev,StdDev);     

    ssmooth->Update();
            // compute force    
            force->SetTarget(tsmooth->GetOutput());                 
            force->SetSource(ssmooth->GetOutput());
            //force->SetTarget(this->Targets[l]);
            //force->SetSource(transint->GetOutput());
            force->SetDisplacement(this->Displacements[l]);
            force->SetMask(mask);
          
            // combine previous and new forces
            addvelo->SetInput1(this->Displacements[l]);
            addvelo->SetInput2(force->GetOutput());
            addvelo->SetOperationToAdd();
          
            // smooth deformation
            smooth->SetInput(addvelo->GetOutput());
            smooth->SetStandardDeviations(StdDev,StdDev,StdDev);
smooth->Update();
            if(this->UseSSD)
              {
              //ssd=this->SSD(this->Targets[l],transint->GetOutput(),mask);
              ssd=this->SSD(tsmooth->GetOutput(),ssmooth->GetOutput(),mask);
          
          }
            if(this->Verbose)
              {
              cout << "\r  Iteration " << i << ":";
                  if(this->UseSSD)
                    { 
                    cout << " SSD=" << ssd
                         << " Diff=" << lastssd-ssd
                         << " Epsilon=" << lastssd*ssde
                         << "          ";
                    }
              cout.flush();
              }

            if(this->UseSSD &&
               ((lastssd-ssd)<=(lastssd*ssde)) &&
               (i>=this->MinimumIterations))
              {
              break;
              }
            lastssd = ssd;

            // This triggers the warping.
            smooth->Update();
            this->Displacements[l]->DeepCopy(smooth->GetOutput());
    tmp->Delete();     
            extractt->Delete();
            extracts->Delete();
            append->Delete();
        reslice->Delete();
            transint->Delete();
            force->Delete();
        tsmooth->Delete();
        ssmooth->Delete();
            addvelo->Delete();
            smooth->Delete();

        } // end i (iterations)

      
      if(this->Verbose)
        {
        cout << endl;
        }
      }
    
      // if at last level, decrease smoothing
      if(l==0  && StdDev>MinStdDev)
        {
        StdDev-=0.25;
        if(StdDev<MinStdDev)
          {
          StdDev=MinStdDev;
          }
        l=1;
        }
      else
        {
        cout << "Update pyramid...";
        this->UpdatePyramid(l);
        cout << "Done" << endl;
      }
    }
    
    // what we computed is the inverse displacement, so we need to add
    // the displacement the transform, and invert it so it represents a
    // forward transform.
    if(this->Verbose)
     {  cout << "start invert displacement " ;
        cout.flush();
     }
  
    this->SetDisplacementGrid(this->Displacements[0]);
    this->Inverse();
  
    this->FreePyramid();

    this->vtkGridTransform::InternalUpdate();
    if(this->Verbose)
     {  cout << "Finish free pyramid and internal update for vtkGridTransform "; 
        cout.flush();
     }
}

void vtkImageWarp::PrintSelf(::ostream& os, vtkIndent indent)
{
  
  this->vtkGridTransform::PrintSelf(os,indent);

  os << indent << "MinimumIterations: " << this->GetMinimumIterations() << "\n";
  os << indent << "MaximumIterations: " << this->GetMaximumIterations() << "\n";
  os << indent << "MaximumLevel: " << this->GetMaximumLevel() << "\n";
  os << indent << "MinimumStandardDeviation: " << this->GetMinimumStandardDeviation() << "\n";
  os << indent << "MaximumStandardDeviation: " << this->GetMaximumStandardDeviation() << "\n";
  os << indent << "UseSSD: " << (this->GetUseSSD() ? "On" : "Off") << "\n";

  os << indent << "Target: " << this->Target << "\n";
  if(this->Target)
    {
    this->Target->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "Source: " << this->Source << "\n";
  if(this->Source)
    {
    this->Source->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "Mask: " << this->Mask << "\n";
  if(this->Mask)
    {
    this->Mask->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "GeneralTransform: " << this->GeneralTransform << "\n";
  if(this->GeneralTransform)
    {
    this->GeneralTransform->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "WorkTransform: " << this->WorkTransform << "\n";
  if(this->WorkTransform)
    {
    this->WorkTransform->PrintSelf(os,indent.GetNextIndent());
    }
  os << indent << "IntensityTransform: " << this->IntensityTransform << "\n";
  if(this->IntensityTransform)
    {
    this->IntensityTransform->PrintSelf(os,indent.GetNextIndent());
    }
  
  //typedef vector<vtkImageData*>::size_type size_t;
  //for(size_t i=0;i<this->Targets.size();++i)
  
  // Modified by Liu. cancelled std::
  typedef vector<vtkImageData*>::size_type size_t;
   size_t i;

  for(i=0;i<this->Targets.size();++i) 
  {
    os << indent << "Targets[" << i << "]: " << this->Targets[i] << "\n";
    if(this->Targets[i])
      {
      this->Targets[i]->PrintSelf(os,indent.GetNextIndent());
      }
    }
  //for(size_t i=0;i<this->Sources.size();++i)
  // Modified by Liu.
  for( i=0;i<this->Sources.size();++i)
    {
    os << indent << "Sources[" << i << "]: " << this->Sources[i] << "\n";
    if(this->Sources[i])
      {
      this->Sources[i]->PrintSelf(os,indent.GetNextIndent());
      }
    }
  //for(size_t i=0;i<this->Masks.size();++i)
  // Modified by Liu
  for( i=0;i<this->Masks.size();++i)

  {
    os << indent << "Masks[" << i << "]: " << this->Masks[i] << "\n";
    if(this->Masks[i])
      {
      this->Masks[i]->PrintSelf(os,indent.GetNextIndent());
      }
    }
   
  //for(size_t i=0;i<this->Displacements.size();++i)
  //Modified by Liu
  for( i=0;i<this->Displacements.size();++i)
    {
    os << indent << "Displacements[" << i << "]: " << this->Displacements[i] << "\n";
    if(this->Displacements[i])
      {
      this->Displacements[i]->PrintSelf(os,indent.GetNextIndent());
      }
    }
}
