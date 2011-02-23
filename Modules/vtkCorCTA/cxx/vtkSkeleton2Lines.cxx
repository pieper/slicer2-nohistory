/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSkeleton2Lines.cxx,v $
  Date:      $Date: 2007/03/15 19:43:22 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/

#include "vtkSkeleton2Lines.h"
#include "DynTable.h"
#include "vtkObjectFactory.h"
#include "vtkPolyData.h"
#include "vtkCellArray.h"


vtkSkeleton2Lines* vtkSkeleton2Lines::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkSkeleton2Lines");
  if(ret)
    {
    return (vtkSkeleton2Lines*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkSkeleton2Lines;

} // vtkSkeleton2Lines::New()


//----------------------------------------------------------------------
// Construct object to extract all of the input data.
//
vtkSkeleton2Lines::vtkSkeleton2Lines()
{

  InputImage = NULL;
  OutputPoly = NULL;
  
  MinPoints=1;

} // vtkSkeleton2Lines::vtkSkeleton2Lines()


//----------------------------------------------------------------------
// Construct object to extract all of the input data.
//
vtkSkeleton2Lines::~vtkSkeleton2Lines()
{
  if (InputImage) InputImage->Delete();

} // vtkSkeleton2Lines::~vtkSkeleton2Lines()


//CoordOK already defined in vtkThinning.cxx
//extern unsigned char CoordOK(vtkImageData*,int,int,int);

//----------------------------------------------------------------------
unsigned char vtkSkeleton2Lines::CoordOK(vtkImageData* im,int x,int y,int z)
{
  return (x>=0 && y>=0 && z>=0 && 
        x<im->GetDimensions()[0] &&
    y<im->GetDimensions()[1] && 
    z<im->GetDimensions()[2]);
}


//----------------------------------------------------------------------
void vtkSkeleton2Lines::Init_Pos()
//   --------
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


void vtkSkeleton2Lines::Init()
{
  InputImage = vtkImageData::New();
  InputImage->SetDimensions(this->GetInput()->GetDimensions());
  InputImage->SetSpacing(this->GetInput()->GetSpacing());
  InputImage->SetScalarType(VTK_UNSIGNED_SHORT);
  InputImage->SetNumberOfScalarComponents(1);
  InputImage->AllocateScalars();
  InputImage->DeepCopy(this->GetInput());
    
  tx = InputImage->GetDimensions()[0];
  ty = InputImage->GetDimensions()[1];
  tz = InputImage->GetDimensions()[2];
  txy = tx*ty;
    
  OutputPoly = this->GetOutput();
}

//-----------------------------------------------------
void vtkSkeleton2Lines::ExecuteData(vtkDataObject* output)
{

  vtkImageData*   neighbors;
  vtkImageData*   endpoints;
  int          x,y,z;
  int          x0,y0,z0;
  int          x1,y1,z1;
  int          x2,y2,z2;
  int          l;
  int          l0,n;
  unsigned int   iPoint; // point index

  int          n_lines;
  TableauDyn<extremity> tab_ext;
  int          found;
  int          e;

  float meanx, meany, meanz;
  short pointid0, pointid1;
  vtkImageData* pointid;
  vtkImageData* loopid;
  vtkPoints* surfPoints;
  vtkCellArray* surfCell;
  vtkIdList* pointIds;
  vtkFloatingPointType        origin[3];
  vtkFloatingPointType        spacing[3];
  unsigned short *inputPtr, *pointidPtr, *neighborsPtr;
  short * loopidPtr;
  unsigned char *endpointsPtr;


  //fprintf(stderr,"vtkSkeleton2Lines execution...\n");
  if (this->GetInput() == NULL)
  {
    vtkErrorMacro("Missing input");
    return;
  }

  Init();
  
  this->GetInput()->GetOrigin(origin[0],origin[1],origin[2]);
  this->GetInput()->GetSpacing(spacing[0],spacing[1],spacing[2]);

  pointid = vtkImageData::New();
  pointid->SetDimensions(this->GetInput()->GetDimensions());
  pointid->SetSpacing(this->GetInput()->GetSpacing());
  pointid->SetScalarType(VTK_UNSIGNED_SHORT);
  pointid->SetNumberOfScalarComponents(1);
  pointid->AllocateScalars();
  
  loopid = vtkImageData::New();
  loopid->SetDimensions(this->GetInput()->GetDimensions());
  loopid->SetSpacing(this->GetInput()->GetSpacing());
  loopid->SetScalarType(VTK_SHORT);
  loopid->SetNumberOfScalarComponents(1);
  loopid->AllocateScalars();
  
  //Init loop id to -1 (0 index is used)
  loopidPtr=(short*)loopid->GetScalarPointer();
  for (int i = 0 ; i< loopid->GetNumberOfPoints() ; i++) {
     *loopidPtr = -1;
     loopidPtr++;
  }   
  
  //fprintf(stderr,"pointid image allocated...\n");

  surfPoints = vtkPoints::New();
  //fprintf(stderr,"point array allocated...\n");
  
  surfCell = vtkCellArray::New();
  surfCell->SetTraversalLocation(0);
  
  pointIds = vtkIdList::New();

  Init_Pos();
  //fprintf(stderr,"neighbor positions initialized...\n");

  //------------ Check the number of neighbors -------------------
  //----------- Add the points to the surface with their numbers
  neighbors = vtkImageData::New();
  neighbors->SetDimensions(this->GetInput()->GetDimensions());
  neighbors->SetSpacing(this->GetInput()->GetSpacing());
  neighbors->SetScalarType(VTK_UNSIGNED_SHORT);
  neighbors->SetNumberOfScalarComponents(1);
  neighbors->AllocateScalars();
  //fprintf(stderr,"neighbor image allocated...\n");

  // This image allows to avoid going twice through the same connection
  // by avoiding creating lines on points having more than 2 neighbors
  endpoints = vtkImageData::New();
  endpoints->SetDimensions(this->GetInput()->GetDimensions());
  endpoints->SetSpacing(this->GetInput()->GetSpacing());
  endpoints->SetScalarType(VTK_UNSIGNED_CHAR);
  endpoints->SetNumberOfScalarComponents(1);
  endpoints->AllocateScalars();
  
  endpointsPtr=(unsigned char*)endpoints->GetScalarPointer();
  for (int i = 0 ; i< loopid->GetNumberOfPoints() ; i++) {
     *endpointsPtr = 0;
     endpointsPtr++;
  }   
  
  
  //fprintf(stderr,"end point image allocated...\n");
  this->UpdateProgress(0.1);

  inputPtr=(unsigned short*)InputImage->GetScalarPointer();
  neighborsPtr=(unsigned short*)neighbors->GetScalarPointer();

  iPoint = 0;
  
  for(z=0;z<=tz-1;z++) {
  for(y=0;y<=ty-1;y++) {
  for(x=0;x<=tx-1;x++) {

    n = 0;
    if (*inputPtr > 0) {

      // Add the point and update the pointid image
      
      //don't care about spacing and origin, because it screws up the result...
      //simply insert x y z
      //We should care though to comply with a polydata filter that gives point in physical space.
      //So far let us keep like that.
      //surfPoints->InsertPoint(iPoint,(x*spacing[0])-origin[0],(y*spacing[1])-origin[1],(z*spacing[2])-origin[2]);
      surfPoints->InsertPoint(iPoint,x,y,z);

      pointidPtr=(unsigned short*)pointid->GetScalarPointer(x,y,z);
      *pointidPtr=iPoint;
      iPoint++;

      // Compute the number of neighbors
      for(l=0;l<=26;l++) {
        if (l==13) continue;
        x1 = x+neighbors_place[l][0];
        y1 = y+neighbors_place[l][1];
        z1 = z+neighbors_place[l][2];

        if (CoordOK(InputImage,x1,y1,z1) && *(unsigned short*)InputImage->GetScalarPointer(x1,y1,z1)>0) {
      n++;
        }
      }
    }

    if (n==1 || n>2) {
      tab_ext += extremity(x,y,z);
    }

    endpointsPtr=(unsigned char*)endpoints->GetScalarPointer(x,y,z);
    if (n>2) {
      *endpointsPtr=1;
    } else {
      *endpointsPtr=0;
    }

    *neighborsPtr=n;
    inputPtr++;
    neighborsPtr++;
  }
  }
  }
  this->UpdateProgress(0.45);

 //Check for local loops in 2x2x2 neighborhoods and extract mean point of loops
 vtkIdType inc[3];
 InputImage->GetIncrements(inc);
  
  for(z=0;z<=tz-2;z++) {
  for(y=0;y<=ty-2;y++) {
    inputPtr = (unsigned short*)InputImage->GetScalarPointer(0,y,z);
  for(x=0;x<=tx-2;x++) {
    
        n = ((*inputPtr) > 0) + (*(inputPtr+inc[0]) > 0) + (*(inputPtr+inc[1]) > 0) + (*(inputPtr+inc[0]+inc[1]) > 0) + 
        (*(inputPtr+inc[2]) > 0) + (*(inputPtr+inc[0]+inc[2]) > 0) + (*(inputPtr+inc[1]+inc[2]) > 0) + (*(inputPtr+inc[0]+inc[1]+inc[2]) > 0);
    
    if (n>2) {
    
      cout<<x<<" "<<y<<" "<<z<<"--->n="<<n<<endl;
      //compute the mean and store the id point
      meanx = meany = meanz = 0;
      for (z1 = z; z1<=z+1;z1++)
        for (y1 = y;y1<=y+1;y1++)
          for(x1 = x;x1<=x+1;x1++) {
          
            if((*(unsigned short *)InputImage->GetScalarPointer(x1,y1,z1))>0) {
             meanx += x1;
             meany += y1;
             meanz += z1; 
             //Buffer the point id of the loop point
             loopidPtr=(short*)loopid->GetScalarPointer(x1,y1,z1);
             *loopidPtr=iPoint;
            
        } 
        }  
          
          //Add point to the centerline     
          surfPoints->InsertPoint(iPoint,meanx*1.0/n,meany*1.0/n,meanz*1.0/n); 
          iPoint++;
       
     } //end iff
     inputPtr++;
    } //end for x
   }// end for y
  }//end for z             


  //--------------- Create the lines ----------------------
  n_lines = 0;
  //inputPtr=(unsigned short*)InputImage->GetScalarPointer();
  for(e=0;e<=tab_ext.NbElts()-1;e++) {

    x0 = tab_ext[e].x;
    y0 = tab_ext[e].y;
    z0 = tab_ext[e].z;

    l0 = 0;

    while (*(unsigned short*)neighbors->GetScalarPointer(x0,y0,z0) > 0) {

      //surfCell->InsertNextCell(1000);
      //surfCell->InsertCellPoint(*(unsigned short*)pointid->GetScalarPointer(x0,y0,z0));
      pointIds->InsertNextId(*(unsigned short*)pointid->GetScalarPointer(x0,y0,z0));
      
      //fprintf(stderr,"%03d : %2d %2d %2d Begin \n",n_lines,x0,y0,z0);
      neighborsPtr=(unsigned short*)neighbors->GetScalarPointer(x0,y0,z0);
      *neighborsPtr=*neighborsPtr-1;

      // look for the positive link
      // beginning at the position of the last found positive neighbor
      found = FALSE;

      for(l=l0;l<=26;l++) {

        if (l==13) continue;
        x1 = x0+neighbors_place[l][0];
        y1 = y0+neighbors_place[l][1];
        z1 = z0+neighbors_place[l][2];
        if (CoordOK(InputImage,x1,y1,z1) && *(unsigned short*)neighbors->GetScalarPointer(x1,y1,z1)>0) {
          found = TRUE;
          // position on the next neighbor 
          l0 = l+1;
          break;
        }
      }

      if (!found) {
        vtkErrorMacro("General mess");
        //Deallocate and return
        neighbors->Delete();
        pointid->Delete();
        loopid->Delete();
        endpoints->Delete();
        surfCell->Delete();
        surfPoints->Delete();
        return;
      }

      // Decide if the line must be created
      pointid1 =  (*(short*)loopid->GetScalarPointer(x1,y1,z1));
      pointid0 =  (*(short*)loopid->GetScalarPointer(x0,y0,z0));
      if (pointid0>-1 && (pointid0 == pointid1)) {
        neighborsPtr=(unsigned short*)neighbors->GetScalarPointer(x1,y1,z1);
        *neighborsPtr=*neighborsPtr-1;
        continue;
      } else {
        // Insert new line
    pointIds->Reset();
       if (pointid0 > -1) {
         pointIds->InsertNextId(pointid0);
       }
       pointIds->InsertNextId(*(unsigned short*)pointid->GetScalarPointer(x0,y0,z0));
        
       }    
    
    
      // 1. follow the line
      while (found && *(unsigned short*)neighbors->GetScalarPointer(x1,y1,z1)==2 && !(*(unsigned char*)endpoints->GetScalarPointer(x1,y1,z1))) {
        // search for the next point
        found = FALSE;

        for(l=0;l<=26;l++) {

          if (l==13) continue;
          x2 = x1+neighbors_place[l][0];
          y2 = y1+neighbors_place[l][1];
          z2 = z1+neighbors_place[l][2];

          if (!((x2==x0)&&(y2==y0)&&(z2==z0)) &&
                CoordOK(InputImage,x2,y2,z2) &&
             *(unsigned short*)neighbors->GetScalarPointer(x2,y2,z2)>0) {
             neighborsPtr=(unsigned short*)neighbors->GetScalarPointer(x1,y1,z1);
             *neighborsPtr=0;
             x0 = x1;
             y0 = y1;
             z0 = z1;
             // Add the point to the line
             //surfCell->InsertCellPoint(*(unsigned short*)pointid->GetScalarPointer(x0,y0,z0));
             pointIds->InsertNextId(*(unsigned short*)pointid->GetScalarPointer(x0,y0,z0));
            //fprintf(stderr,"(%2d %2d %2d) ",x0,y0,z0);
            x1 = x2;
            y1 = y2;
            z1 = z2;
            found = TRUE;
            break;
          }

        }

        if (!found) {
        fprintf(stderr,"Next point not found (%d %d %d) \n",x1,y1,z1);
        }
            
      }

      //surfCell->InsertCellPoint(*(unsigned short*)pointid->GetScalarPointer(x1,y1,z1));
      pointIds->InsertNextId(*(unsigned short*)pointid->GetScalarPointer(x1,y1,z1));
      
      if ((*(short*)loopid->GetScalarPointer(x1,y1,z1)) > -1 ) {
        pointIds->InsertNextId(*(short*)loopid->GetScalarPointer(x1,y1,z1));
      }
      
      //surfCell->UpdateCellCount(n_points);
      // is the line long enough?
      if (pointIds->GetNumberOfIds() > MinPoints) {
        surfCell->InsertNextCell(pointIds);
      }
      pointIds->Reset();
      //pointIds = vtkIdList::New();
      //fprintf(stderr,"%03d : %2d %2d %2d End \n",n_lines,x1,y1,z1);

      neighborsPtr=(unsigned short*)neighbors->GetScalarPointer(x1,y1,z1);
      *neighborsPtr=*neighborsPtr-1;
      
      n_lines++;

      // reset x0
      x0 = tab_ext[e].x;
      y0 = tab_ext[e].y;
      z0 = tab_ext[e].z;

    }

  }
  this->UpdateProgress(0.9);

  neighbors->Delete();
  pointid->Delete();
  loopid->Delete();
  endpoints->Delete();
  
  
  OutputPoly->SetLines(surfCell);
  OutputPoly->SetPoints(surfPoints);
  
  surfCell->Delete();
  surfPoints->Delete();
  pointIds->Delete();
  this->UpdateProgress(1.0);

} // Func_Skeleton2lines


//----------------------------------------------------------------------
void vtkSkeleton2Lines::PrintSelf(ostream& os, vtkIndent indent)
{
  // Nothing for the moment ...
}
