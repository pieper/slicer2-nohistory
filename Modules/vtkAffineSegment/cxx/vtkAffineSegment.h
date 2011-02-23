/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAffineSegment.h,v $
  Date:      $Date: 2006/01/06 17:57:13 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtkAffineSegment__h
#define __vtkAffineSegment__h 



#include <vtkImageToImageFilter.h>
#include "vtkImageData.h"

#include "vtkAffineSegmentConfigure.h"

#ifdef _WIN32 // WINDOWS

//#include <assert.h> 
//don't use asserts to avoid program crash

#include <vector>
#include <algorithm>
#include <iostream>

#else // UNIX

#include <vector.h>
#include <algo.h>

#endif


#define MAJOR_VERSION 3
#define MINOR_VERSION 1
#define DATE_VERSION "2004-5-27/20:00EST"

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

// pretty big
#define INF 1e20 

// outside margin
#define BAND_OUT 3

#define GRANULARITY_PROGRESS 20

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

typedef enum fmstatus { fmsDONE, fmsKNOWN, fmsTRIAL, fmsFAR, fmsOUT } FMstatus;
#define MASK_BIT 256

struct FMnode {
  FMstatus status;
  float T;
  int leafIndex;
};

struct FMleaf {
  int nodeIndex;
};

// these typedef are for tclwrapper...
typedef std::vector<FMleaf> VecFMleaf;
typedef std::vector<int> VecInt;
typedef std::vector<float> VecFloat;
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

class VTK_AFFINESEGMENT_EXPORT vtkAffineSegment : public vtkImageToImageFilter
{
 public:
  bool somethingReallyWrong;

  double powerSpeed;

  int nNeighbors; // =6 pb wrap, cannot be defined as constant
  int arrayShiftNeighbor[27];
  double arrayDistanceNeighbor[27];
  int tmpNeighborhood[125]; // allocate it here so that we do not have to

  float dx; 
  float dy;
  float dz;

  float invDx2;
  float invDy2;
  float invDz2;

  bool initialized;
  bool firstCall;

  FMnode *node;  // arrival time and status for all voxels

  short* outdata; // output
  short* indata;  // input

  // size of the indata (=size outdata, node, inhomo)
  int dimX;
  int dimY;
  int dimZ;
  int dimXY; // dimX*dimY
  int dimXYZ; // dimX*dimY*dimZ
  // coeficients of the RAS2IJK matrix
  float m11;
  float m12;
  float m13;
  float m14;

  float m21;
  float m22;
  float m23;
  float m24;

  float m31;
  float m32;
  float m33;
  float m34;

  float m41;
  float m42;
  float m43;
  float m44;

  int label;
  int depth;
  
  int nPointsEvolution;
  int nPointsBeforeLeakEvolution;
  int nEvolutions;

  VecInt knownPoints;
  // vector<int> knownPoints

  VecInt seedPoints;
  // vector<int> seedPoints

  // minheap used by the fast marching algorithm
  VecFMleaf tree;
  //  vector<FMleaf> tree;


  bool firstPassThroughShow;
  bool already_computed;
  bool Contract;

  FILE *fpc;
  //data arrays used
  VecInt zero_set;
  float *phi_hat;
  float *eucl_phi;
  VecFloat phi_ext;
  VecFloat eucl_ext;
  float *phi_hat_x;
  float *phi_hat_y;
  float *phi_hat_z;
  VecFloat phi_ext_x;
  VecFloat phi_ext_y;
  VecFloat phi_ext_z;
  float *temp_phi_ext;
  float *temp_eucl_phi;
  float *temp_phi_ext_x;
  float *temp_phi_ext_y;
  float *temp_phi_ext_z;
  float *level_set;
  float *sdist;
  double dt;
  VecInt inside_sphere;

  int NumberOfIterations;
  int Evolve;
  int Inflation;
  int NumberOfContractions;  
  int InitialSize;

  int shiftNeighbor(int n);
  double distanceNeighbor(int n);
  float computeT(int index );
  
  // minheap methods
  bool emptyTree(void);
  void downTree(int index);
  void upTree(int index);
  int indexFather(int index);

  //void setSeed(int index,float val );
  FMleaf removeSmallest( void );
  void insert(const FMleaf leaf);

  float speed(int index );

  bool minHeapIsSorted( void );
  

  /* perform one step of fast marching
     return the leaf which has just been added to fmsKNOWN */
  float step( int *indx );
  void ComputeAffine_phihat(short *inData);
  void Compute_phi_hat_xyz(float *inData);
  void Compute_Extension(vtkAffineSegment *self);
  void Initialize_sdist(bool isnegative);
  void MakeNegative_Inside();
  void Calculate_SignedDistance(vtkAffineSegment *self,int evolve_upto,bool make_negative);
  void FindInitialBoundary();

  void Allocate_Space();
  void Release_Space();

 public:

  void vtkErrorWrapper( char* s)
    {
      vtkErrorMacro( << s );
    };

  static vtkAffineSegment *New();

  vtkTypeMacro(vtkAffineSegment,vtkImageToImageFilter);

  vtkAffineSegment();
  ~vtkAffineSegment();
  void unInit( void );

  void PrintSelf(ostream& os, vtkIndent indent);

  void init(int dimX, int dimY, int dimZ, int depth, double dx, double dy, double dz);

  void setActiveLabel(int label);

  //void initNewExpansion( void );

  int nValidSeeds( void );

  void setNPointsEvolution( int n );

  void setInData(short* data);
  void setOutData(short* data);

  void setRAStoIJKmatrix(float m11, float m12, float m13, float m14,
             float m21, float m22, float m23, float m24,
             float m31, float m32, float m33, float m34,
             float m41, float m42, float m43, float m44);

  int addSeed( float r, float a, float s );

  void show();

  void AffineContract() { Contract = true;}

  char * cxxVersionString(void)
    {
      char *text = new char[100];
      
      sprintf(text,"%d.%d \t(%s)",MAJOR_VERSION,MINOR_VERSION,DATE_VERSION);
      return text;
    }; 

  int cxxMajorVersion(void)
    {
      return MAJOR_VERSION;
    };

  void tweak(char *name, double value);

  // Get/Set the number of iterations of smoothing that is to be done
  vtkSetMacro(NumberOfIterations,int);
  vtkGetMacro(NumberOfIterations,int);

  vtkSetMacro(Evolve,int);
  vtkGetMacro(Evolve,int);

  vtkSetMacro(Inflation,int);
  vtkGetMacro(Inflation,int);

  vtkSetMacro(NumberOfContractions,int);
  vtkGetMacro(NumberOfContractions,int);

  vtkSetMacro(InitialSize,int);

 void Reset();
 void OutputReset();
 protected:
 void ThreadedExecute(vtkImageData *inData, 
                                  vtkImageData *outData,
                                  int outExt[6], int id);

  
/*
 friend static void vtkAffineSegmentInflation(vtkAffineSegment *self,
                     vtkImageData *inData, short *inPtr,
                     vtkImageData *outData, short *outPtr, 
                     int outExt[6], int id);
  
 friend static void vtkAffineSegmentContract(vtkAffineSegment *self,
                     vtkImageData *inData, short *inPtr,
                     vtkImageData *outData, short *outPtr, 
                     int outExt[6], int id);*/
};

#endif
