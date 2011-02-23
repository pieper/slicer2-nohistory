/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkThinning.cxx,v $
  Date:      $Date: 2007/03/15 19:43:22 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/

#include "vtkThinning.h"
#include "vtkObjectFactory.h"
#include "vtkStructuredPointsWriter.h"
#include "vtkPointData.h"

//
//  Code by Karl Krissian
//  University of Las Palmas of Gran Canaria
//  and Surgical Planning Lab, BWH
//  transferred to VTK by Arne Hans
//  Surgical Planning Lab
//  Brigham and Women's Hospital
//


#define FALSE    0
#define TRUE     1




//-----------------------------------------------------------------------
vtkThinning* vtkThinning::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkThinning");
  if(ret)
    {
    return (vtkThinning*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkThinning;

} // vtkThinning::New()


//----------------------------------------------------------------------
// Construct object to extract all of the input data.
//
vtkThinning::vtkThinning()
{

  input_image   = NULL;
  OutputImage  = NULL;
  Criterion     = NULL;

  MinCriterionThreshold = 0;
  MaxEndpointThreshold = 1000;
  
  UseLineEndpoints = TRUE;
  UseFiducialEndpoints = FALSE;
  UseSurfaceEndpoints = FALSE;

} // vtkThinning::vtkThinning()


//----------------------------------------------------------------------
// Construct object to extract all of the input data.
//
vtkThinning::~vtkThinning()
{
  if (input_image) input_image->Delete();
  //if (OutputImage) OutputImage->Delete();

} // vtkThinning::~vtkThinning()


//----------------------------------------------------------------------
void vtkThinning::Init()
{

  if (this->GetInput() == NULL) {
    vtkErrorMacro("Missing input");
    return;
  }
  else {

    input_image = vtkImageData::New();
    input_image->SetDimensions(this->GetInput()->GetDimensions());
    input_image->SetSpacing(this->GetInput()->GetSpacing());
    input_image->SetScalarType(VTK_UNSIGNED_SHORT);
    input_image->SetNumberOfScalarComponents(1);
    input_image->AllocateScalars();
    input_image->DeepCopy(this->GetInput());
    
    
    tx = input_image->GetDimensions()[0];
    ty = input_image->GetDimensions()[1];
    tz = input_image->GetDimensions()[2];
    txy = tx*ty;
    
    //--- OutputImage
    OutputImage = this->GetOutput();
    OutputImage->SetDimensions(input_image->GetDimensions());
    OutputImage->SetSpacing(input_image->GetSpacing());
    OutputImage->SetScalarType(VTK_UNSIGNED_SHORT);
    OutputImage->SetNumberOfScalarComponents(1);
    OutputImage->AllocateScalars();
  }
    

} // vtkThinning::InitParam()






//----------------------------------------------------------------------
void vtkThinning::Thin_init_pos( )
//                -------------
{

  int i,j,k,n;

  for(i=0;i<=2;i++) {
    for(j=0;j<=2;j++) {
      for(k=0;k<=2;k++) {

        n                   = i+j*3+k*9;
        pos[i][j][k]        = n;
        neighbors_pos[n]    = i-1+((j-1)+(k-1)*ty)*tx;
        neighbors_place[n][0] = i-1;
        neighbors_place[n][1] = j-1;
        neighbors_place[n][2] = k-1;

      }
    }
  }

} // Thin_init_pos()


//----------------------------------------------------------------------
void vtkThinning::init_neighborhoods()
//                ------------------
{

  
    int i,j,k;
    int i1,j1,k1;
    int n,nb1,nb2;
    Boolean n1_ok,n2_ok;

  for(i=0;i<=2;i++) {
  for(j=0;j<=2;j++) {
  for(k=0;k<=2;k++) {

    n  = pos[i][j][k];
    nb1 = 0;
    nb2 = 0;

    n1_ok = ((i!=1)||(j!=1)||(k!=1));
    n2_ok = ((i==1)||(j==1)||(k==1));

    for(i1=-1;i1<=1;i1++) {
    for(j1=-1;j1<=1;j1++) {
    for(k1=-1;k1<=1;k1++) {

      if (i+i1<0) continue;
      if (j+j1<0) continue;
      if (k+k1<0) continue;

      if (i+i1>2) continue;
      if (j+j1>2) continue;
      if (k+k1>2) continue;

      if ((i1==0)&&(j1==0)&&(k1==0)) continue;
  
      if (n1_ok)
      if ((i+i1 != 1)||(j+j1 != 1)||(k+k1 != 1)) {
        nb1++;
        N26_star[n][nb1] = pos[i+i1][j+j1][k+k1];
      }

      if (n2_ok)
      if ((i+i1 == 1)||(j+j1 == 1)||(k+k1 == 1)) {
        if ( ((i1==0)&&((j1==0)||(k1==0))) || ((j1==0)&&(k1==0)) ) {
      nb2++;
      N18[n][nb2] = pos[i+i1][j+j1][k+k1];
    }
      }

    }
    }
    }

    N26_star[n][0] = nb1;
    N18     [n][0] = nb2;

  }
  }
  }

} // init_neighborhoods()


//----------------------------------------------------------------------
unsigned char vtkThinning::CoordOK(vtkImageData* im,int x,int y,int z)
{
  return (x>=0 && y>=0 && z>=0 && 
        x<im->GetDimensions()[0] &&
    y<im->GetDimensions()[1] && 
    z<im->GetDimensions()[2]);
}


//----------------------------------------------------------------------
Boolean vtkThinning::IsLineEndPoint(vtkImageData* im, int x, int y, int z)
//                   ----------
{
  
    int n,nb;
    int x1,y1,z1;

  if (!(*(unsigned short*)im->GetScalarPointer(x,y,z))) return FALSE;

  nb = 0;
  for(n=0;n<=26;n++) {
    x1 = x+neighbors_place[n][0];
    y1 = y+neighbors_place[n][1];
    z1 = z+neighbors_place[n][2];
    
    if (CoordOK(im,x1,y1,z1) && (*(unsigned short*)im->GetScalarPointer(x1,y1,z1))>0  ) nb++;
    if (nb>2) break;

  }

  return (nb==2);
}
//--------------------------------------------------------------------------
//  Check if a point is a surface border point: 26-connected case
// Add an extra test to make sure it is not a line end point.
// we want only surfaces here...
Boolean vtkThinning::IsSurfaceEndPoint(vtkImageData* im, int x, int y, int z) {
  int i, j, count = 0;
  int x1,y1,z1;
  int planes26[9][8][3]= {
    { {0, -1, -1}, {0, 0, -1}, {0, 1, -1}, {0, 1, 0},
      {0, 1, 1},   {0, 0, 1}, {0, -1, 1},  {0, -1, 0}
    },
    
    { {-1, 0, -1}, {0, 0, -1}, {1, 0, -1}, {1, 0, 0},  
      {1, 0, 1},   {0, 0, 1}, {-1, 0, 1},  {-1, 0, 0}
    },
    
    {
      {-1, -1, 0}, {0, -1, 0}, {1, -1, 0}, {1, 0, 0},
      {1, 1, 0}, {0, 1, 0}, {-1, 1, 0}, {-1, 0, 0}
    },
    
    {
      {-1, -1, -1}, {0, 0, -1}, {1, 1, -1}, {1, 1, 0},
      {1, 1, 1}, {0, 0, 1}, {-1, -1, 1},{-1, -1, 0} 
    },
    
    {
      {1, -1, -1}, {0, 0, -1}, {-1, 1, -1}, {-1, 1, 0},
      {-1, 1, 1}, {0, 0, 1}, {1, -1, 1}, {1, -1, 0}
    },
    
    {
      {-1, -1, -1}, {-1, 0, -1}, {-1, 1, -1}, {0, 1, 0}, 
      {1, 1, 1}, {1, 0, 1}, {1, -1, 1}, {0, -1, 0}
    },
    
    {
      {1, -1, -1}, {1, 0, -1}, {1, 1, -1}, {0, 1, 0}, 
      {-1, 1, 1},  {-1, 0, 1}, {-1, -1, 1},{0, -1, 0}
    },
    
    {
      {-1, -1, -1},{0, -1, -1},{1, -1, -1},{1, 0, 0},
      {1, 1, 1}, {0, 1, 1}, {-1, 1, 1}, {-1, 0, 0}
    },
    
    {
      {-1, 1, -1},{0, 1, -1},{1, 1, -1},{1, 0, 0},
      {1, -1, 1},{0, -1, 1},{-1, -1, 1}, {-1, 0, 0}
    }
  };
  
  if (!(*(unsigned short*)im->GetScalarPointer(x,y,z))) return FALSE;

  if (IsLineEndPoint(im,x,y,z)) {
      return FALSE;
  }
    
  for (j=0; j<9; j++) { 
    count = 0;
    for (i=0; i<8; i++) {
      x1=x+planes26[j][i][0]; 
      y1=y+planes26[j][i][1]; 
      z1=z+planes26[j][i][2];
      if (CoordOK(im,x1,y1,z1) && (*(unsigned short*)im->GetScalarPointer(x1,y1,z1))>0  )
    count++;
    }
    if (count==1) return TRUE;
  }
  return FALSE;
}
//--------------------------------------------------------------------------
//  Check if a point is an end point 
Boolean vtkThinning::IsEndPoint(vtkImageData* im, int x, int y, int z) {
  char Line, Surface;
  Line = UseLineEndpoints;
  Surface = UseSurfaceEndpoints;
  if ((Line=='1')&&(Surface=='1')) {
    return ((IsLineEndPoint(im,x,y,z))||(IsSurfaceEndPoint(im,x,y,z)));
  }
  if (Line=='1') {
    //     fprintf(stderr,"Line %d\n",1);
     return (IsLineEndPoint(im,x,y,z));
   }
  if (Surface=='1') {
    //     fprintf(stderr,"Surf %d\n",1);
     return (IsSurfaceEndPoint(im,x,y,z));
  }
  fprintf(stderr,"What the f**k?\n");
  return 0;
}


//----------------------------------------------------------------------
void vtkThinning::ParseCC( int* domain, 
//                -------
               int neighborhood[27][27], 
               int* cc,
               int point, 
               int num_cc )
{

   
    int l;
    int neighbor;
    int list[27];
    int size;

  cc[point] = num_cc;
  list[0] = point;
  size = 1;

  while (size>0) {
    size--;
    point = list[size];
    
    for(l=1;l<=neighborhood[point][0];l++) {
      neighbor = neighborhood[point][l];
      if ((domain[neighbor])&&(cc[neighbor] == 0)) {
        cc[neighbor] = num_cc;
    list[size]   = neighbor;
        size++;
      }
    }
  }

} // ParseCC()




//----------------------------------------------------------------------
Boolean vtkThinning::IsSimple(vtkImageData* im, int x, int y, int z, int& cstar, int& cbar)
//                   --------
{

  int cc[27];
  int i,j,k,n,n1;
  int nb_cc;
  int domain[27];

  // position of the points 6-adjacents to the central point
  int six_adj[6] = {4,10,12,14,16,22};

  cstar = cbar = 0;

  if (!(CoordOK(im,x,y,z))) return FALSE;

  // First Check: C*(P) = 1

  nb_cc = 0;

  for(n=0;n<=26;n++) {
    cc[n] = 0;
  }

  for(i=0;i<=2;i++) {
  for(j=0;j<=2;j++) {
  for(k=0;k<=2;k++) {
    n = pos[i][j][k];
    if (CoordOK(im,x+i-1,y+j-1,z+k-1))
      domain[n] = (N26_star[n][0]) && 
              (*(unsigned short*)im->GetScalarPointer(x+i-1,y+j-1,z+k-1));
    else
      domain[n] = 0;
  }
  }
  }

  for(n=0;n<=26;n++) {
    // if the point is in the domain
    // and is not yet connected: create new connected component
    if ((domain[n])&&(cc[n] == 0)) {
      nb_cc++;
      // Parse the connected component
      ParseCC(domain,N26_star,cc,n,nb_cc);
    }
  }

  cstar = nb_cc;

  // Second Check: C-(P) = 1

  nb_cc = 0;

  for(n=0;n<=26;n++) {
    cc[n] = 0;
  }

  for(i=0;i<=2;i++) {
  for(j=0;j<=2;j++) {
  for(k=0;k<=2;k++) {
    n = pos[i][j][k];
    if (CoordOK(im,x+i-1,y+j-1,z+k-1))
      domain[n] = (N18[n][0]) && 
              (!(*(unsigned short*)im->GetScalarPointer(x+i-1,y+j-1,z+k-1)));
    else
      domain[n] = 0;
  }
  }
  }

  for(n=0;n<=5;n++) {
    n1 = six_adj[n];
    // if the point is in the domain
    // and is not yet connected: create new connected component
    if (( domain[n1]) && (cc[n1] == 0)) {
      nb_cc++;
      // Parse the connect component
      ParseCC(domain,N18,cc,n1,nb_cc);
    }
  }

  cbar = nb_cc;
  return ((cstar == 1) && (cbar==1));

} // IsSimple()




//----------------------------------------------------------------------
void vtkThinning::ExecuteData(vtkDataObject* output)
{
    vtkImageData*   im_heap;
    vtkImageData*   im_Criterion;
    vtkImageData*   endpoint_Criterion;

    int             x,y,z;
    int             x1,y1,z1;
    int             i,j,k;
    Boolean         contour;
    TrialPoint      p;
    int             it;
    int             remove_number;
    int             cstar,cbar;
    vtkMinHeap<TrialPoint>  heap;
    unsigned long   n;
    unsigned short *heapPtr,*outputPtr,*inputPtr;
 
  //fprintf(stderr,"vtkThinning execution...\n");
  
  Init();
  //fprintf(stderr,"init done...\n");

  Thin_init_pos();
  //fprintf(stderr,"init_pos done...\n");

  init_neighborhoods();
  //fprintf(stderr,"init_neighborhoods done...\n");

  im_heap = vtkImageData::New();
  im_heap->SetDimensions(this->GetInput()->GetDimensions());
  im_heap->SetSpacing(this->GetInput()->GetSpacing());
  im_heap->SetScalarType(VTK_UNSIGNED_SHORT);
  im_heap->SetNumberOfScalarComponents(1);
  im_heap->AllocateScalars();
  //fprintf(stderr,"heap image allocated...\n");

  //im_Criterion = new_image(Criterion);
  im_Criterion = Criterion;
  endpoint_Criterion = EndpointCriterion;
  //fprintf(stderr,"criterion image allocated and copied, extent %d,%d,%d...\n",im_Criterion->GetDimensions()[0],im_Criterion->GetDimensions()[1],im_Criterion->GetDimensions()[2]);
  this->UpdateProgress(0.1);

  heapPtr = (unsigned short*)im_heap->GetScalarPointer();

  for(n=0; n<(unsigned long)(im_heap->GetPointData()->GetScalars()->GetNumberOfTuples()); n++) {
    *heapPtr = 0;
    heapPtr++;
  }


  outputPtr = (unsigned short*)OutputImage->GetScalarPointer();
  inputPtr = (unsigned short*)input_image->GetScalarPointer();

  for(n=0; n<(unsigned long)(input_image->GetPointData()->GetScalars()->GetNumberOfTuples()); n++) {

    if (*inputPtr>0)
      *outputPtr=255;
    else
      *outputPtr=0;

    outputPtr++;
    inputPtr++;
  }

  double scalarRange[2];
  endpoint_Criterion->GetScalarRange(scalarRange);
  //fprintf(stderr,"%f\n",scalarRange[0]);
  // Initialize the heap to the contour points which are simple
  for(z=1;z<=OutputImage->GetDimensions()[2]-2;z++) {
    for(y=1;y<=OutputImage->GetDimensions()[1]-2;y++) {
      outputPtr=(unsigned short*)OutputImage->GetScalarPointer(1,y,z);
      for(x=1;x<=OutputImage->GetDimensions()[0]-2;x++) {
    contour = FALSE;
    if (*outputPtr) {
      for(n=0;n<=26;n++) {
        if (!(*(outputPtr+neighbors_pos[n]))) {
          contour=TRUE;
          break;
        }
      }
    }
    if ((contour) && IsSimple(OutputImage,x,y,z,cstar,cbar) ) {
      double order;
      if (im_Criterion==endpoint_Criterion){
        order = im_Criterion->GetScalarComponentAsFloat(x,y,z,0);
      }
      else {
        order = (0 - (im_Criterion->GetScalarComponentAsFloat(x,y,z,0) * scalarRange[0])) - endpoint_Criterion->GetScalarComponentAsFloat(x,y,z,0); 
      }
      //    fprintf(stderr,"%f\n",order);
      heap += TrialPoint(x,y,z,order);
      heapPtr=(unsigned short*)im_heap->GetScalarPointer(x,y,z);
      *heapPtr=1;
    }
    outputPtr++;
      }
    }
  }
  //fprintf(stderr,"heap initialized, size is %d...\n",heap.Size());
  this->UpdateProgress(0.2);


  it = 0;
  remove_number = 1;

  
  while (heap.Size()>0) {

    it++;
    //if ((it%1000==0))
    //  fprintf(stderr,"iteration %5d, heap size %5d \n",it,heap.Size());

    p = heap.GetMin();
    //    if (p.value > MaxEndpointThreshold) break;
    
    double endpoint_value = endpoint_Criterion->GetScalarComponentAsFloat(p.x,p.y,p.z,0);
    double MaxEndpointThreshold_value = MaxEndpointThreshold;
    if (im_Criterion==endpoint_Criterion){
      endpoint_value = -endpoint_Criterion->GetScalarComponentAsFloat(p.x,p.y,p.z,0);
      MaxEndpointThreshold_value = -MaxEndpointThreshold; 
    }
    if ( IsSimple(OutputImage,p.x,p.y,p.z,cstar,cbar) ) {
      if ( 
        (im_Criterion->GetScalarComponentAsFloat(p.x,p.y,p.z,0) < MinCriterionThreshold )
      || 
        ( !(IsEndPoint(OutputImage,p.x,p.y,p.z)) ) 
      ||
        ( (IsEndPoint(OutputImage,p.x,p.y,p.z)) && (endpoint_value>MaxEndpointThreshold_value) )
        ) { 
        // remove P
    outputPtr=(unsigned short*)OutputImage->GetScalarPointer(p.x,p.y,p.z);
    *outputPtr=0;
    
        // set im_heap to 2 to say the point has already been parsed
    heapPtr=(unsigned short*)im_heap->GetScalarPointer(p.x,p.y,p.z);
    *heapPtr=2;
    
    //    im_removed->BufferPos(p.x,p.y,p.z);
    //    im_removed->SetValue(remove_number);
    //        remove_number++;
    
    // Add neighbors to the heap
        for(n=0;n<=26;n++) {
      x1 = p.x+neighbors_place[n][0];
          y1 = p.y+neighbors_place[n][1];
          z1 = p.z+neighbors_place[n][2];
          if ( !(CoordOK(OutputImage,x1,y1,z1))) continue;
          if (*(outputPtr+neighbors_pos[n])==255 ) {
            if ( ((*(unsigned short*)im_heap->GetScalarPointer(x1,y1,z1))==0) &&
         IsSimple(OutputImage,x1,y1,z1,cstar,cbar)) {
          double order;
          order = (0 - (im_Criterion->GetScalarComponentAsFloat(x1,y1,z1,0) * scalarRange[0])) - endpoint_Criterion->GetScalarComponentAsFloat(x1,y1,z1,0); 
          //if (order!=0) fprintf(stderr,"%f\n",order);
          heap += TrialPoint(x1,y1,z1,order);
          heapPtr=(unsigned short*)im_heap->GetScalarPointer(x1,y1,z1);
          *heapPtr=1;
            }
          }
        }
      } else {
    outputPtr=(unsigned short*)OutputImage->GetScalarPointer(p.x,p.y,p.z);
    *outputPtr=127;
      }
    } else {
      // set im_heap to 2 to say the point has already been parsed
      heapPtr=(unsigned short*)im_heap->GetScalarPointer(p.x,p.y,p.z);
      *heapPtr=0;
    }    

  }
  this->UpdateProgress(0.9);

  im_heap->Delete();

//   for (i=0;i<2;i++){ 
//     for(z=0;z<=OutputImage->GetDimensions()[2]-1;z++) {
//     for(y=0;y<=OutputImage->GetDimensions()[1]-1;y++) {
//     for(x=0;x<=OutputImage->GetDimensions()[0]-1;x++) {    
//       outputPtr=(unsigned short*)OutputImage->GetScalarPointer(x,y,z);
//       if ((*outputPtr)&&(IsSimple(OutputImage,x,y,z,cstar,cbar))) {
//     *outputPtr=0;
//       }
//     }
//     }
//     }
//   }

  for(z=1;z<=OutputImage->GetDimensions()[2]-1;z++) {
  for(y=1;y<=OutputImage->GetDimensions()[1]-1;y++) {
  for(x=1;x<=OutputImage->GetDimensions()[0]-1;x++) {
    outputPtr=(unsigned short*)OutputImage->GetScalarPointer(x,y,z);
    if (*outputPtr) {
      *outputPtr=127; 

//       //        *outputPtr=127;
//       IsSimple(OutputImage,x,y,z,cstar,cbar);
//       if (cbar==0)  
//     // interior point
//     *outputPtr=1;
//       if (cstar==0) 
//     // isolated point
//     *outputPtr=2;
//       if ((cbar==1) && (cstar==1)) 
//     // simple point
//     *outputPtr=3;
//       if ((cbar==1) && (cstar==2)) {
//     // curve point
//     *outputPtr=4;
//     int count=0;
//     for(i=-1;i<=1;i++) {
//         for(j=-1;j<=1;j++) {
//         for(k=-1;k<=1;k++) {    
//       if (OutputImage->GetScalarComponentAsFloat(x+i,y+j,z+k,0))
//         count++;
//     }
//     }
//     }
//     // if more than 2 neighbors(count>3) then junction
//     if (count>3)
//       *outputPtr=5;
//       }      
//       if ((cbar==1) && (cstar>2)) 
//     // curve junction point
//     *outputPtr=5;
//       if ((cbar==2) && (cstar==1)) 
//     // surface point
//     *outputPtr=6;
//       if ((cbar==2) && (cstar>2)) 
//     // surface-curve junction point
//     *outputPtr=7;
//       if ((cbar>2) && (cstar==1)) 
//     // surface-surface junction point
//     *outputPtr=8;
//       if ((cbar>2) && (cstar>=2)) 
//     // surfaces-curves junction point
//     *outputPtr=9;
      int count=1;
      for (i=-1;i<=1;i++){
      for (j=-1;j<=1;j++){
      for (k=-1;k<=1;k++){
    if ((i*i+j*j+k*k)==1) {
      if (OutputImage->GetScalarComponentAsFloat(x+i,y+j,z+k,0)){
        count++;
      }
    }
      }
      }
      }
      *outputPtr=count; 
    }
  }
  }
  }
//   outputPtr=(unsigned short*)OutputImage->GetScalarPointer();
//   for(z=0;z<=OutputImage->GetDimensions()[2]-2;z++) {
//   for(y=0;y<=OutputImage->GetDimensions()[1]-2;y++) {
//   for(x=0;x<=OutputImage->GetDimensions()[0]-2;x++) {    
//     if (*outputPtr>0.0) {
//       int count=0;
//       for (i=0;i<=1;i++){
//     for (j=0;j<=1;j++){
//       for (k=0;k<=1;k++){
//          if (OutputImage->GetScalarComponentAsFloat(x+i,y+j,z+k,0)>0.0)
//            count++;
//       }
//     }
//       }
//       *outputPtr=count; 
//     }
//     outputPtr++;
//   }
//   }
//   }

  //fprintf(stderr,"Done!\n");
  this->UpdateProgress(1.0);
  

} // vtkThinning::Execute()




//----------------------------------------------------------------------
void vtkThinning::PrintSelf(ostream& os, vtkIndent indent)
{
  // Nothing for the moment ...
}
