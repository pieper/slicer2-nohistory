/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDisplayTracts.cxx,v $
  Date:      $Date: 2007/03/15 19:43:22 $
  Version:   $Revision: 1.21 $

=========================================================================auto=*/
#include "vtkDisplayTracts.h"
#include "vtkRenderer.h"
#include "vtkTubeFilter2.h"
#include "vtkTransformPolyDataFilter.h"
#include "vtkClipPolyData.h"
#include "vtkMergePoints.h"
#include "vtkCell.h"
#include "vtkPolyData.h"
#include "vtkUnsignedCharArray.h"
#include "vtkCellData.h"
#include "vtkMergeDataObjectFilter.h"
#include "vtkFieldData.h"

//------------------------------------------------------------------------------
vtkDisplayTracts* vtkDisplayTracts::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDisplayTracts");
  if(ret)
    {
      return (vtkDisplayTracts*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkDisplayTracts;
}

//----------------------------------------------------------------------------
vtkDisplayTracts::vtkDisplayTracts()
{
  // The user must set these for the class to function.
  this->Renderers = vtkCollection::New();
  

  // Initialize transforms to identity, 
  // so if the user doesn't set them it's okay.
  this->WorldToTensorScaledIJK = vtkTransform::New();

  // input collections
  this->Streamlines = NULL;

 // 1 actor has 1 mapper and 1 append filter. 
 // The input to the append filter is 1 item of the Tube and Streamline group.
 // The element of the group is a collecion of streamlines and tube filters. T
 // This way an actor will mapped a set of fibers.
  this->StreamlinesGroup = vtkCollection::New();
  this->ClippedStreamlinesGroup = vtkCollection::New();
  this->MergeFiltersGroup = vtkCollection::New();
  this->TubeFiltersGroup = vtkCollection::New();
  this->TransformFiltersGroup = vtkCollection::New();

  // internal/output collections
  this->Mappers = vtkCollection::New();
  this->Actors = vtkCollection::New();
  this->AppendFilters = vtkCollection::New();

  // Flat collection of clipped streamlines
  this->ClippedStreamlines = vtkCollection::New();
 
  this->activeStreamlines = NULL;
  this->activeClippedStreamlines = NULL;
  this->activeMergeFilters = NULL;
  this->activeTubeFilters = NULL;
  this->activeTransformFilters = NULL;
  this->activeAppendFilter = NULL;
  this->activeMapper = NULL;
  this->activeActor = NULL;

  // Streamline parameters for all streamlines
  this->ScalarVisibility=0;
  this->Clipping=0;
  this->ClipFunction = NULL;

  // for tube filter
  this->TubeRadius = 0.5;
  this->TubeNumberOfSides = 4;
 
  // user-accessible property and lookup table for all streamlines
  this->StreamlineProperty = vtkProperty::New();
  this->StreamlineLookupTable = vtkLookupTable::New();
  // default: make 0 dark blue, not red
  this->StreamlineLookupTable->SetHueRange(.6667, 0.0);

  // the number of actors displayed in the scene
  this->NumberOfVisibleActors=0;

  // Max number of fibers per group. This number is a trade off between
  // graphics performance (having less actor) and searching performance (time spend searching for fibers
  // in a group);
  this->NumberOfStreamlinesPerActor = 100;

}

//----------------------------------------------------------------------------
vtkDisplayTracts::~vtkDisplayTracts()
{
  this->DeleteAllStreamlines();

  this->Renderers->Delete();
  if (this->Streamlines != NULL)
    this->Streamlines->Delete();
  this->Mappers->Delete();
  this->Actors->Delete();

  this->StreamlinesGroup->Delete();
  this->ClippedStreamlinesGroup->Delete();
  this->MergeFiltersGroup->Delete();
  this->TubeFiltersGroup->Delete();
  this->TransformFiltersGroup->Delete();
  this->AppendFilters->Delete();

  this->ClippedStreamlines->Delete();

  this->StreamlineLookupTable->Delete();
  this->StreamlineProperty->Delete();
}

//----------------------------------------------------------------------------
void vtkDisplayTracts::SetScalarVisibility(int value)
{
  vtkPolyDataMapper *currMapper;

  // test if we are changing the value before looping through all streamlines
  if (this->ScalarVisibility != value)
    {
      this->ScalarVisibility = value;
      // apply this to ALL streamlines
      // traverse actor collection and make all visible
      this->Mappers->InitTraversal();
      currMapper= (vtkPolyDataMapper *)this->Mappers->GetNextItemAsObject();
      while(currMapper)
        {
          this->SetMapperVisibility(currMapper);
          currMapper= (vtkPolyDataMapper *)this->Mappers->GetNextItemAsObject();      
        }
    }
}

void vtkDisplayTracts::SetMapperVisibility(vtkPolyDataMapper *currMapper)
{
  // value = 0; Use cell data to color. Choose field data of name "Color"
  // This field data is generated during the streamline creation.
  // value =1; Use Scalars in PointData to color the streamline. 
  if (this->ScalarVisibility == 0) {
    currMapper->ScalarVisibilityOn();
    currMapper->SetScalarModeToUseCellFieldData();
    currMapper->SetColorModeToDefault();
    currMapper->SelectColorArray("Color");
   } else {
    currMapper->ScalarVisibilityOn();
    currMapper->SetScalarModeToUsePointData();
    currMapper->SetColorModeToMapScalars();
   }
}

//----------------------------------------------------------------------------
void vtkDisplayTracts::SetClipping(int value)
{

  vtkCollection *currStreamlines;
  vtkCollection *currTransFilters, *currClippedStreamlines;
  vtkHyperStreamline *currStreamline;
  vtkTransformPolyDataFilter *currTransFilter;
#if (VTK_MAJOR_VERSION >= 5)
   vtkPolyDataAlgorithm *clippedStreamline;
#else
  vtkPolyDataSource *clippedStreamline;
#endif
  
  // test if we are changing the value before looping through all streamlines
  if (this->Clipping != value)
    {

      if (value)
        {
          if (!this->ClipFunction)
            {
              vtkErrorMacro("Set the ClipFunction before turning clipping on");
              return;
            }
        }

      this->Clipping = value;

      int numGroups = this->StreamlinesGroup->GetNumberOfItems();
      // clear storage for these streamlines
      for (int i=0 ;i < numGroups; i++) {
        ((vtkCollection *) this->ClippedStreamlinesGroup->GetItemAsObject(i))->RemoveAllItems();
       }
      // apply this to ALL streamlines
      // traverse streamline collection and clip each one
      this->StreamlinesGroup->InitTraversal();
      this->TransformFiltersGroup->InitTraversal();
      this->ClippedStreamlinesGroup->InitTraversal();

      currStreamlines = (vtkCollection *)
        this->StreamlinesGroup->GetNextItemAsObject();
      currClippedStreamlines = (vtkCollection *)
        this->ClippedStreamlinesGroup->GetNextItemAsObject();
      currTransFilters = (vtkCollection *)
        this->TransformFiltersGroup->GetNextItemAsObject();

      //Foreach Group
      while (currStreamlines && currClippedStreamlines && currTransFilters)
        {
           //
           currStreamline = (vtkHyperStreamline *)
                currStreamlines->GetNextItemAsObject();
           currTransFilter = (vtkTransformPolyDataFilter *)
                currTransFilters->GetNextItemAsObject();
           while (currStreamline && currTransFilter)
            {
            // clip or not, depending on this->Clipping
            clippedStreamline = this->ClipStreamline(currStreamline,currClippedStreamlines);

            // Make sure we are displaying clipped streamline
            // this corresponds to contents of ClippedStreamlines collection
            currTransFilter->SetInput(clippedStreamline->GetOutput());

            currTransFilter = (vtkTransformPolyDataFilter *)
                currTransFilters->GetNextItemAsObject();
            currStreamline = (vtkHyperStreamline *)
                currStreamlines->GetNextItemAsObject();
            }

           currStreamlines = (vtkCollection *)
                this->StreamlinesGroup->GetNextItemAsObject();
           currClippedStreamlines = (vtkCollection *)
                this->ClippedStreamlinesGroup->GetNextItemAsObject();
           currTransFilters = (vtkCollection *)
                this->TransformFiltersGroup->GetNextItemAsObject();

        }
    }

}

// Handle clipping/not clipping a single streamline
//----------------------------------------------------------------------------
//BTX
#if (VTK_MAJOR_VERSION >= 5)
vtkPolyDataAlgorithm *
#else
vtkPolyDataSource *
#endif
vtkDisplayTracts::ClipStreamline(vtkHyperStreamline *currStreamline, vtkCollection *activeClippedStreamlineGroup)
//ETX
{

  if (this->Clipping) 
    {
      
      // Turn clipping on
      // Put a clipped streamline onto the collection
      vtkClipPolyData *currClipper = vtkClipPolyData::New();
      currClipper->SetInput(currStreamline->GetOutput());
      currClipper->SetClipFunction(this->ClipFunction);
      //currClipper->SetValue(0.0);
      currClipper->Update();
      
      this->activeClippedStreamlines->AddItem((vtkObject *) currClipper);
      
      // The object survives as long as it is on the
      // collection. (until clipping is turned off)
      currClipper->Delete();

      return currClipper;
    }
  else
    {
      // Turn clipping off
      // Put the original streamline onto the collection
      activeClippedStreamlines->AddItem((vtkObject *) currStreamline);
      return currStreamline;
    }

}


// Set the properties of one streamline's graphics objects as requested
// by the user
//----------------------------------------------------------------------------
void vtkDisplayTracts::ApplyUserSettingsToGraphicsObject(int index)
{
  vtkPolyDataMapper *currMapper;
  vtkActor *currActor;
  vtkCollection *currTransFilters, *currTubeFilters;
  currActor = (vtkActor *) this->Actors->GetItemAsObject(index);
  currMapper = (vtkPolyDataMapper *) this->Mappers->GetItemAsObject(index);
  currTransFilters = (vtkCollection *) this->TransformFiltersGroup->GetItemAsObject(index);
  currTubeFilters = (vtkCollection *) this->TubeFiltersGroup->GetItemAsObject(index);

  // set the Actor's properties according to the sample 
  // object that the user can access.
  currActor->GetProperty()->SetAmbient(this->StreamlineProperty->GetAmbient());
  currActor->GetProperty()->SetDiffuse(this->StreamlineProperty->GetDiffuse());
  currActor->GetProperty()->SetSpecular(this->StreamlineProperty->GetSpecular());
  currActor->GetProperty()->SetSpecularPower(this->StreamlineProperty->GetSpecularPower());
  currActor->GetProperty()->SetColor(this->StreamlineProperty->GetColor()); 

  // Set the scalar visibility as desired by the user
  currMapper->SetLookupTable(this->StreamlineLookupTable);
  currMapper->UseLookupTableScalarRangeOn();
  this->SetMapperVisibility(currMapper);

  // Set the tube width and number of sides as desired by the user
 for (int i= 0; i< currTubeFilters->GetNumberOfItems(); i++)
    {
    ((vtkTubeFilter2 *) currTubeFilters->GetItemAsObject(i))->SetRadius(this->TubeRadius);
    ((vtkTubeFilter2 *) currTubeFilters->GetItemAsObject(i))->SetNumberOfSides(this->TubeNumberOfSides);
    }

}

int vtkDisplayTracts::IsPropertyEqual(vtkProperty *a, vtkProperty *b)
{
  int p1,p2,p3,p4;

  vtkDebugMacro(<<" In IsPropertyEqual");
  if (a == NULL || b == NULL) {
    return 0;
  }
   p1 = (a->GetAmbient() == b->GetAmbient());
   p2 = (a->GetDiffuse() == b->GetDiffuse());
   p3 = (a->GetSpecular() == b->GetSpecular());
   p4 = (a->GetSpecularPower() == b->GetSpecularPower());
   //p5 = (a->GetColor()[0] == b->GetColor()[0] && 
   //      a->GetColor()[1] == b->GetColor()[1] && 
   //      a->GetColor()[2] == b->GetColor()[2]);
   if (p1 && p2 && p3 && p4) { // && p5) {
     return p1;
   } else {
     if (p1) {
       return !p1;
     } else {
       return p1;
     }
   }
}

void vtkDisplayTracts::UpdateAllTubeFiltersWithCurrentSettings()
{
  vtkTubeFilter2 *currTubeFilter;
  vtkCollection *currTubeFilters;

  this->TubeFiltersGroup->InitTraversal();
  currTubeFilters = (vtkCollection *)this->TubeFiltersGroup->GetNextItemAsObject();
  while(currTubeFilters)
    {
      vtkDebugMacro( << "Updating tube filter Group" << currTubeFilters);

       currTubeFilters->InitTraversal();
       currTubeFilter = (vtkTubeFilter2 *)currTubeFilters->GetNextItemAsObject();
       while(currTubeFilter)
         {
            // Set the tube width and number of sides as desired by the user
            currTubeFilter->SetRadius(this->TubeRadius);     
            currTubeFilter->SetNumberOfSides(this->TubeNumberOfSides);
            currTubeFilter = (vtkTubeFilter2 *)currTubeFilters->GetNextItemAsObject();
         }
       currTubeFilters = (vtkCollection *)this->TubeFiltersGroup->GetNextItemAsObject();
    }
}

void vtkDisplayTracts::SetActiveGroup (int groupindex) 
{

   vtkDebugMacro(<<"Setting an active Group");
   this->activeStreamlines = (vtkCollection *) this->StreamlinesGroup->GetItemAsObject(groupindex);
   this->activeTubeFilters = (vtkCollection *) this->TubeFiltersGroup->GetItemAsObject(groupindex);
   this->activeClippedStreamlines = (vtkCollection *) this->ClippedStreamlinesGroup->GetItemAsObject(groupindex);
   this->activeMergeFilters = (vtkCollection *)
   this->MergeFiltersGroup->GetItemAsObject(groupindex);
   this->activeTransformFilters = (vtkCollection *) this->TransformFiltersGroup->GetItemAsObject(groupindex);
   this->activeAppendFilter = (vtkAppendPolyData *) this->AppendFilters->GetItemAsObject(groupindex);
   this->activeActor = (vtkActor *) this->Actors->GetItemAsObject(groupindex);
   this->activeMapper =  (vtkPolyDataMapper *) this->Mappers->GetItemAsObject(groupindex);
}

void vtkDisplayTracts::AddNewGroup() 
{
  vtkCollection  *newStreamlinesGroup;
  vtkCollection  *newTubeFiltersGroup;
  vtkCollection  *newTransformFiltersGroup;
  vtkCollection  *newClippedStreamlinesGroup;
  vtkCollection  *newMergeFiltersGroup;
  vtkAppendPolyData *newAppendFilter;

  vtkDebugMacro(<<"Adding new group");

  newStreamlinesGroup = vtkCollection::New();
  this->StreamlinesGroup->AddItem(newStreamlinesGroup);
  newTubeFiltersGroup = vtkCollection::New();
  this->TubeFiltersGroup->AddItem(newTubeFiltersGroup);
  newClippedStreamlinesGroup = vtkCollection::New();
  this->ClippedStreamlinesGroup->AddItem(newClippedStreamlinesGroup);
  newTransformFiltersGroup = vtkCollection::New();
  this->TransformFiltersGroup->AddItem(newTransformFiltersGroup);
  newMergeFiltersGroup = vtkCollection::New();
  this->MergeFiltersGroup->AddItem(newMergeFiltersGroup);

  //Add interface to Graphic pipeline
  newAppendFilter = vtkAppendPolyData::New();
  this->AppendFilters->AddItem(newAppendFilter);

  // Delete object. Adding to the collection increments the reference count
}

void vtkDisplayTracts::FindStreamline(vtkHyperStreamline *currStreamline,int & groupIndex, int & indexInGroup)
{

  int numGroups = this->StreamlinesGroup->GetNumberOfItems();
  int item;

  vtkDebugMacro(<<"Number of Groups: "<<numGroups);
  for (int i = 0; i< numGroups; i++) 
   {
     item = ((vtkCollection *) this->StreamlinesGroup->GetItemAsObject(i))->IsItemPresent(currStreamline); 
     if (item > 0) {
        groupIndex = i;
        indexInGroup = item-1;
        return;
     }
   }

   groupIndex = -1;
   indexInGroup = -1;
}

void vtkDisplayTracts::FindStreamlineInGroup(vtkHyperStreamline *currStreamline,int groupIndex, int & indexInGroup)
{

  int numGroups = this->StreamlinesGroup->GetNumberOfItems();
  int item;

  vtkDebugMacro(<<"Number of Groups: "<<numGroups);
  
  if (groupIndex >= numGroups ) {
    indexInGroup = -1;
    return;
  }
  
  item = ((vtkCollection *) this->StreamlinesGroup->GetItemAsObject(groupIndex))->IsItemPresent(currStreamline); 
  if (item > 0) {
    indexInGroup = item-1;
    return;
  }

  indexInGroup = -1;
}


// Find a streamline after being selected from the user interface
//----------------------------------------------------------------------------
void vtkDisplayTracts::FindStreamline(vtkCellPicker *picker,int &groupIndex, int &indexInGroup)
{

  vtkActor *pickedActor = picker->GetActor();
  groupIndex = this->GetStreamlineGroupIndexFromActor(pickedActor);
  indexInGroup = this->GetStreamlineIndexFromActor(groupIndex,picker);

}

void vtkDisplayTracts::FindStreamlineInGroup(vtkCellPicker *picker,int groupIndex, int &indexInGroup)
{

  indexInGroup = this->GetStreamlineIndexFromActor(groupIndex,picker);

}

// Get color properties of a single streamline
//----------------------------------------------------------------------------
void vtkDisplayTracts::GetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char &R, unsigned char &G, unsigned char &B, unsigned char &A)
{
  int groupIndex, indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;

  this->FindStreamline(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);

  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");

  if (colorarray == NULL) {
    //cout<<"Fiber does not have a color assigned"<<endl;
    return;
  }
  R=(unsigned char) colorarray->GetComponent(0,0);
  G=(unsigned char) colorarray->GetComponent(0,1);
  B=(unsigned char) colorarray->GetComponent(0,2);
  A=(unsigned char) colorarray->GetComponent(0,3);
}

// Get color properties of a single streamline
//----------------------------------------------------------------------------
void vtkDisplayTracts::GetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char RGBA[4])
{
  this->GetStreamlineRGBA(currStreamline,RGBA[0],RGBA[1],RGBA[2],RGBA[3]);

}

void vtkDisplayTracts::GetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char RGB[3])
{
  unsigned char tmp;
  this->GetStreamlineRGBA(currStreamline,RGB[0],RGB[1],RGB[2],tmp);
}

void vtkDisplayTracts::GetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char &R, unsigned char &G, unsigned char &B)
{
  unsigned char tmp;
  this->GetStreamlineRGBA(currStreamline,R,B,G,tmp);
}


void vtkDisplayTracts::SetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char R, unsigned char G, unsigned char B, unsigned char A)
{
  int groupIndex, indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;
  this->FindStreamline(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  if (colorarray == NULL) {
      return;
  }

  colorarray->SetComponent(0,0,R);
  colorarray->SetComponent(0,1,G);
  colorarray->SetComponent(0,2,B);
  colorarray->SetComponent(0,3,A);
  colorarray->SetComponent(1,0,R);
  colorarray->SetComponent(1,1,G);
  colorarray->SetComponent(1,2,B);
  colorarray->SetComponent(1,3,A);
  // Input has changed
  currMergeFilter->GetDataObject()->Modified();

}

// Changes color properties of a single streamline
//----------------------------------------------------------------------------
void vtkDisplayTracts::SetStreamlineRGBA(vtkHyperStreamline *currStreamline, unsigned char RGBA[4])
{
  this->SetStreamlineRGBA(currStreamline,RGBA[0],RGBA[1],RGBA[2],RGBA[3]);
}


void vtkDisplayTracts::SetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char R, unsigned char G, unsigned char B)
{

 int groupIndex, indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;
  this->FindStreamline(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  if (colorarray == NULL) {
      return;
  }

  colorarray->SetComponent(0,0,R);
  colorarray->SetComponent(0,1,G);
  colorarray->SetComponent(0,2,B);
  colorarray->SetComponent(1,0,R);
  colorarray->SetComponent(1,1,G);
  colorarray->SetComponent(1,2,B);

  // Input has changed
  currMergeFilter->GetDataObject()->Modified();

}

void vtkDisplayTracts::SetStreamlineRGB(vtkHyperStreamline *currStreamline, unsigned char RGB[3])
{
  this->SetStreamlineRGB(currStreamline,RGB[0],RGB[1],RGB[2]);
}

void vtkDisplayTracts::SetStreamlineOpacity(vtkHyperStreamline *currStreamline, unsigned char opacity)
{

  int groupIndex, indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;

  this->FindStreamline(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  colorarray->SetComponent(0,3,opacity);
  colorarray->SetComponent(1,3,opacity);
  // Input has changed
  currMergeFilter->GetDataObject()->Modified();
}

void vtkDisplayTracts::GetStreamlineOpacity(vtkHyperStreamline *currStreamline, unsigned char &opacity)
{
  int groupIndex, indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;

  this->FindStreamline(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *)currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  opacity= (unsigned char) colorarray->GetComponent(0,3);
}

// Changes color properties of a single streamline by knowing the group index
//----------------------------------------------------------------------------
void vtkDisplayTracts::SetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char R, unsigned char G, unsigned char B, unsigned char A)
{
  int indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;
  this->FindStreamlineInGroup(currStreamline,groupIndex,indexInGroup);
  if (indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  if (colorarray == NULL) {
      return;
  }

  colorarray->SetComponent(0,0,R);
  colorarray->SetComponent(0,1,G);
  colorarray->SetComponent(0,2,B);
  colorarray->SetComponent(0,3,A);
  colorarray->SetComponent(1,0,R);
  colorarray->SetComponent(1,1,G);
  colorarray->SetComponent(1,2,B);
  colorarray->SetComponent(1,3,A);
  // Input has changed
  currMergeFilter->GetDataObject()->Modified();
}

void vtkDisplayTracts::SetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char RGBA[4])
{
  this->SetStreamlineRGBAInGroup(currStreamline,groupIndex,RGBA[0],RGBA[1],RGBA[2],RGBA[3]);
}

void vtkDisplayTracts::SetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char R, unsigned char G, unsigned char B)
{
  unsigned char opacity;
  this->GetStreamlineOpacityInGroup(currStreamline, groupIndex,opacity);
  this->SetStreamlineRGBAInGroup(currStreamline,groupIndex,R,G,B,opacity);
}

void vtkDisplayTracts::SetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char RGB[3])
{
  this->SetStreamlineRGBInGroup(currStreamline,groupIndex,RGB[0],RGB[1],RGB[2]);
}


// Get color properties of a single streamline
//----------------------------------------------------------------------------
void vtkDisplayTracts::GetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char &R, unsigned char &G, unsigned char &B, unsigned char &A)
{
  int indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;

  this->FindStreamlineInGroup(currStreamline,groupIndex,indexInGroup);
  if (indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);

  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");

  if (colorarray == NULL) {
    //cout<<"Fiber does not have a color assigned"<<endl;
    return;
  }
  R=(unsigned char) colorarray->GetComponent(0,0);
  G=(unsigned char) colorarray->GetComponent(0,1);
  B=(unsigned char) colorarray->GetComponent(0,2);
  A=(unsigned char) colorarray->GetComponent(0,3);
}

void vtkDisplayTracts::GetStreamlineRGBAInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char RGBA[4])
{
  this->GetStreamlineRGBAInGroup(currStreamline,groupIndex,RGBA[0],RGBA[1],RGBA[2],RGBA[3]);

}

void vtkDisplayTracts::GetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char RGB[3])
{
  unsigned char tmp;
  this->GetStreamlineRGBAInGroup(currStreamline,groupIndex,RGB[0],RGB[1],RGB[2],tmp);
}

void vtkDisplayTracts::GetStreamlineRGBInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char &R, unsigned char &G, unsigned char &B)
{
  unsigned char tmp;
  this->GetStreamlineRGBAInGroup(currStreamline,groupIndex,R,G,B,tmp);
}


void vtkDisplayTracts::SetStreamlineOpacityInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char opacity)
{

  int indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;

  this->FindStreamlineInGroup(currStreamline,groupIndex,indexInGroup);
  if (indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *) currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  colorarray->SetComponent(0,3,opacity);
  colorarray->SetComponent(1,3,opacity);
  // Input has changed
  currMergeFilter->GetDataObject()->Modified();
}

void vtkDisplayTracts::GetStreamlineOpacityInGroup(vtkHyperStreamline *currStreamline, int groupIndex, unsigned char &opacity)
{
  int indexInGroup;
  vtkMergeDataObjectFilter *currMergeFilter;

  this->FindStreamlineInGroup(currStreamline,groupIndex,indexInGroup);
  if (groupIndex == -1 || indexInGroup == -1) {
    return;
  }
  vtkCollection *currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupIndex);
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(indexInGroup);
  vtkUnsignedCharArray *colorarray = (vtkUnsignedCharArray *) ((vtkPolyData *)currMergeFilter->GetDataObject())->GetFieldData()->GetArray("Color");
  opacity= (unsigned char) colorarray->GetComponent(0,3);
}


// Make Streamlines Group, ClippedStreamline Group, Merge Filter, Tube Filter group and Transform Filter group.
// The fibers in Streamlines Collection would be splitted in groups. Each group would have an actor associated to it.
void vtkDisplayTracts::CreateGroupObjects()
{
  int numGroups, numStreamlinesInGroups;
  int numStreamlines;
  #if (VTK_MAJOR_VERSION >= 5)
    vtkPolyDataAlgorithm *currClippedStreamline;
  #else
    vtkPolyDataSource *currClippedStreamline;
  #endif
  vtkHyperStreamline *currStreamline;
  vtkTubeFilter2 *currTubeFilter;
  vtkTransformPolyDataFilter *currTransFilter;
  vtkMergeDataObjectFilter *currMergeFilter;
  double color[3];
  double opacity;

  numGroups = this->StreamlinesGroup->GetNumberOfItems();
  numStreamlinesInGroups = 0;
  for (int i=0; i<numGroups; i++) {
    numStreamlinesInGroups += ((vtkCollection *) this->StreamlinesGroup->GetItemAsObject(i))->GetNumberOfItems();
  }

  // Check number of streamlines in the flat collection that comes from vtkSeedTracts.
  numStreamlines = this->Streamlines->GetNumberOfItems();

  vtkDebugMacro(<<"Streamlines in Group: "<<numStreamlinesInGroups<< " Total num of Streamlines: "<< numStreamlines);

  // All the streamlines are allocated in groups
  if (numStreamlines == numStreamlinesInGroups) {
    return;
  }

  // Dummy transformation to populate in all the fibers
  vtkTransform *currTransform=vtkTransform::New();
  currTransform->SetMatrix(this->WorldToTensorScaledIJK->GetMatrix());
  currTransform->Inverse();

  // Get color information to fill cell data field.
  this->StreamlineProperty->GetColor(color);
  opacity=this->StreamlineProperty->GetOpacity();


   // Add new streamlines to group
  for (int i=numStreamlinesInGroups ; i< numStreamlines; i++)
   {

    // Check num streamlines in the last group
    vtkCollection *lastStreamlinesGroup = (vtkCollection *) this->StreamlinesGroup->GetItemAsObject(numGroups-1);
    vtkDebugMacro(<<"LastStreamline: "<<lastStreamlinesGroup);
    if (lastStreamlinesGroup == NULL )
     {
      // Create new group to allocate new streamlines
      this->AddNewGroup();
      numGroups++;
     // Set active the group that we have just created
      this->SetActiveGroup(numGroups-1);
     } 
    else if (lastStreamlinesGroup->GetNumberOfItems() <= this->NumberOfStreamlinesPerActor) 
     {
      // Check if the last group has the same actor properties that the one we want to create.
      // if not, we should create a brand new group
      this->SetActiveGroup(numGroups-1);
      if (this->activeActor != NULL && !(this->IsPropertyEqual(this->activeActor->GetProperty(),this->StreamlineProperty))) {
            this->AddNewGroup();
            numGroups++;
            this->SetActiveGroup(numGroups-1);
       }
     }
    else 
     {
      // Create a new group because the active one is full
      this->AddNewGroup();
      numGroups++;
      this->SetActiveGroup(numGroups-1);
     }

    vtkDebugMacro(<<"Adding objects to the group");
    // Adding streamline to selected group
    currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
    this->activeStreamlines->AddItem(this->Streamlines->GetItemAsObject(i));

    // Creating objects that handle that streamlines
    currTubeFilter = vtkTubeFilter2::New();
    currTransFilter = vtkTransformPolyDataFilter::New();
    currClippedStreamline =
        this->ClipStreamline(currStreamline,this->activeClippedStreamlines);

   // Add color information in Cell Data
   // The default color is the one that is pass in StreamlineProperty.
   // Thereafter, the color can be modified by changing the FieldData "Color"
   // for a given streamline.

    // Creating dummy dataset with color info in the field data
    // data would be used to merge with the current streamline.
    vtkUnsignedCharArray *colorarray = vtkUnsignedCharArray::New();
    colorarray->SetNumberOfComponents(4);
    colorarray->SetNumberOfTuples(2);
    colorarray->SetComponent(0,0,(unsigned char) (255*color[0]));
    colorarray->SetComponent(0,1,(unsigned char) (255*color[1]));
    colorarray->SetComponent(0,2,(unsigned char) (255*color[2]));
    colorarray->SetComponent(0,3,(unsigned char) (255*opacity));
    colorarray->SetComponent(1,0,(unsigned char) (255*color[0]));
    colorarray->SetComponent(1,1,(unsigned char) (255*color[1]));
    colorarray->SetComponent(1,2,(unsigned char) (255*color[2]));
    colorarray->SetComponent(1,3,(unsigned char) (255*opacity));
    colorarray->SetName("Color");
    vtkPolyData *dataset = vtkPolyData::New();
    vtkFieldData *fd = vtkFieldData::New();
    fd->AddArray(colorarray);
    dataset->SetFieldData(fd);

    currMergeFilter = vtkMergeDataObjectFilter::New();
    currMergeFilter->SetInput(currClippedStreamline->GetOutput());
    currMergeFilter->SetDataObject(dataset);
    currMergeFilter->SetOutputFieldToCellDataField();

    colorarray->Delete();
    fd->Delete();
    dataset->Delete();

    this->activeMergeFilters->AddItem((vtkObject *) currMergeFilter);
    this->activeTransformFilters->AddItem((vtkObject *)currTransFilter);
    this->activeTubeFilters->AddItem((vtkObject *)currTubeFilter);

    // Create transformation matrix to place streamline in scene
    currTransFilter->SetTransform(currTransform);

    // Set tube params
    currTubeFilter->SetRadius(this->TubeRadius);
    currTubeFilter->SetNumberOfSides(this->TubeNumberOfSides);

    // This is already added in ClippedStreamline method.
    //activeClippedStreamlinesGroup->AddItem((vtkObject *)currClippedStreamline);

     // Hook up the pipeline  involving the objects that generate
    // the data
    vtkDebugMacro(<<"Hooking up pipeline");
    currTransFilter->SetInput((vtkPolyData *) currMergeFilter->GetOutput());
    currTubeFilter->SetInput(currTransFilter->GetOutput());

    // Connect Group pipeline to Append Filter.
    // Append Filer is the interface between the Group Pipeline and
    // the Graphics Object Pipeline (actor, mapper....)
     this->activeAppendFilter->AddInput(currTubeFilter->GetOutput());
   }

  currTransform->Delete();   // Set Matrix info in Transform filters

}

// Make actors, mappers, and lookup tables as needed for streamlines
// in the collection.
//----------------------------------------------------------------------------
void vtkDisplayTracts::CreateGraphicsObjects()
{
  int numActorsCreated, numStreamlinesGroup;
#if (VTK_MAJOR_VERSION >= 5)
  //vtkPolyDataAlgorithm *currStreamline;
#else
  //vtkPolyDataSource *currStreamline;
#endif
  vtkPolyDataMapper *currMapper;
  vtkActor *currActor;
  //vtkTransform *currTransform;
  vtkRenderer *currRenderer;
  //vtkTransformPolyDataFilter *currTransFilter;

  //vtkCollection *currStreamlines;
  //vtkCollection *currTransFilters;
  vtkAppendPolyData *currAppendFilter;


  // Find out how many streamlines we have, and if they all have actors
  //numStreamlines = this->Streamlines->GetNumberOfItems();
  //numActorsCreated = this->Actors->GetNumberOfItems();
  numStreamlinesGroup = this->StreamlinesGroup->GetNumberOfItems();
  numActorsCreated = this->Actors->GetNumberOfItems();


  vtkDebugMacro(<< "in CreateGraphicsObjects " << numActorsCreated << "  " << numStreamlinesGroup);

  // If we have already made all of the objects needed, stop here.
  //if (numActorsCreated == numStreamlinesGroup) 
  //  return;

 // check if we need transform and tube filters, then stop here.
  if (numActorsCreated == numStreamlinesGroup) 
   {
     //this->ApplyUserSettingsToGraphicsObject(numStreamlinesGroup-1);
     return;
   }


  // Make actors and etc. for all streamlines that need them
  while (numActorsCreated < numStreamlinesGroup) 
    {

      // Now create the objects needed
      currActor = vtkActor::New();
      this->Actors->AddItem((vtkObject *)currActor);
      currMapper = vtkPolyDataMapper::New();
      this->Mappers->AddItem((vtkObject *)currMapper);
      //currTransFilter = vtkTransformPolyDataFilter::New();
      //this->TransformFilters->AddItem((vtkObject *) currTransFilter);   
      currAppendFilter = (vtkAppendPolyData *)
      this->AppendFilters->GetItemAsObject(numActorsCreated);

      // Apply user's visualization settings to these objects
      this->ApplyUserSettingsToGraphicsObject(numActorsCreated);

      // Hook up the pipeline
      vtkDebugMacro(<<"Attaching Graphic pipeline for actor "<<numActorsCreated);

      currMapper->SetInput(currAppendFilter->GetOutput());
      currActor->SetMapper(currMapper);

      // add to the scene (to each renderer)
      // This is the same as MainAddActor in Main.tcl.
      this->Renderers->InitTraversal();
      currRenderer= (vtkRenderer *)this->Renderers->GetNextItemAsObject();
      while(currRenderer)
        {
          currRenderer->AddActor(currActor);
          currRenderer= (vtkRenderer *)this->Renderers->GetNextItemAsObject();
        }
      
      // Increment the count of actors we have created
      numActorsCreated++;
    }

  // For debugging print this info again
  // Find out how many streamlines Groups we have, and if they all have actors
  numStreamlinesGroup = this->StreamlinesGroup->GetNumberOfItems();
  numActorsCreated = this->Actors->GetNumberOfItems();
  vtkDebugMacro(<< "in CreateGraphicsObjects " << numActorsCreated << "  " << numStreamlinesGroup);

}


void vtkDisplayTracts::AddStreamlinesToScene()
{
  vtkActor *currActor;
  int index;

  // make group objects if needed
  vtkDebugMacro(<< "Creating Group objects");
  this->CreateGroupObjects();

  // make graphics objects if needed
  vtkDebugMacro(<< "Creating Graphic objects");
  this->CreateGraphicsObjects();

  // traverse actor collection and make all visible
  // only do the ones that are not visible now
  // this code assumes any invisible ones are at the end of the
  // list since they were just created.
  index = this->NumberOfVisibleActors;
  while (index < this->Actors->GetNumberOfItems())
    {
      currActor = (vtkActor *) this->Actors->GetItemAsObject(index);
      currActor->VisibilityOn();
      index++;
    }

  // the number of actors displayed in the scene
  this->NumberOfVisibleActors=this->Actors->GetNumberOfItems();
}



//----------------------------------------------------------------------------
void vtkDisplayTracts::RemoveStreamlinesFromScene()
{
  vtkActor *currActor;

  // traverse actor collection and make all invisible
  this->Actors->InitTraversal();
  currActor= (vtkActor *)this->Actors->GetNextItemAsObject();
  while(currActor)
    {
      currActor->VisibilityOff();
      currActor= (vtkActor *)this->Actors->GetNextItemAsObject();      
    }

  // the number of actors displayed in the scene
  this->NumberOfVisibleActors=0;
}

//----------------------------------------------------------------------------
void vtkDisplayTracts::DeleteAllStreamlines()
{
  int numGroups, i;

  i=0;
  numGroups = this->StreamlinesGroup->GetNumberOfItems();
  while (i < numGroups)
    {
      vtkDebugMacro( << "Deleting streamline group " << i);
      // always delete the first streamline from the collections
      // (they change size as we do this, shrinking away)
      this->DeleteAllStreamlinesInGroup(i);
      i++;
    }

  // Make sure the group collection is empty
  this->StreamlinesGroup->RemoveAllItems();
  this->ClippedStreamlinesGroup->RemoveAllItems();
  this->MergeFiltersGroup->RemoveAllItems();
  this->TubeFiltersGroup->RemoveAllItems();
  this->TransformFiltersGroup->RemoveAllItems();

  // Make sure the collection is empty
  this->AppendFilters->RemoveAllItems();
  this->Mappers->RemoveAllItems();
  this->Actors->RemoveAllItems(); 
}

//----------------------------------------------------------------------------
void vtkDisplayTracts::DeleteAllStreamlinesInGroup(int groupindex)
{
  
  int numStreamlines, i;
  vtkCollection *currStreamlines;
  i=0;
  currStreamlines = (vtkCollection *)this->StreamlinesGroup->GetItemAsObject(groupindex);
  numStreamlines = currStreamlines->GetNumberOfItems();
  while (i < numStreamlines)
    {
     vtkDebugMacro( << "Deleting group" << i);
     // always delete the first streamline from the collections
     // (they change size as we do this, shrinking away)     
     this->DeleteStreamlineInGroup(groupindex,0);
     i++;
    }
}


// Delete all of the DISPLAY objects created for one streamline 
//----------------------------------------------------------------------------
void vtkDisplayTracts::DeleteStreamlineInGroup(int groupindex, int index)
{

  vtkHyperStreamline *currStreamline;
  #if (VTK_MAJOR_VERSION >= 5)
   vtkPolyDataAlgorithm *currClippedStreamline;
  #else
   vtkPolyDataSource *currClippedStreamline;
  #endif
  vtkTransformPolyDataFilter *currTransFilter;
  vtkTubeFilter2 *currTubeFilter;
  vtkMergeDataObjectFilter *currMergeFilter;
  vtkAppendPolyData *currAppendFilter;
  vtkRenderer *currRenderer;
  //vtkLookupTable *currLookupTable;
  vtkPolyDataMapper *currMapper;
  vtkActor *currActor;

  vtkCollection *currStreamlines;
  vtkCollection *currClippedStreamlines;
  vtkCollection *currMergeFilters;
  vtkCollection *currTubeFilters;
  vtkCollection *currTransFilters;

  currStreamlines = (vtkCollection *) this->StreamlinesGroup->GetItemAsObject(groupindex);
  currClippedStreamlines = (vtkCollection *)this->ClippedStreamlinesGroup->GetItemAsObject(groupindex);
  currMergeFilters = (vtkCollection *) this->MergeFiltersGroup->GetItemAsObject(groupindex);
  currTubeFilters = (vtkCollection *) this->TubeFiltersGroup->GetItemAsObject(groupindex);
  currTransFilters = (vtkCollection *) this->TransformFiltersGroup->GetItemAsObject(groupindex);
  currAppendFilter = (vtkAppendPolyData *) this->AppendFilters->GetItemAsObject(groupindex);

  int numStreamlinesInGroup = currStreamlines->GetNumberOfItems();
 
  vtkDebugMacro( << "Delete streamline" );
  // Remove from collection.
  // If we are clipping this should delete the clipper object.
  // Otherwise it removes a reference to the streamline object still 
  // on the Streamlines collection.
  //this->ClippedStreamlines->RemoveItem(index);

  currStreamline = (vtkHyperStreamline *)
    currStreamlines->GetItemAsObject(index);
  if (currStreamline != NULL)
    {
      currStreamlines->RemoveItem(index);
      //currStreamline->Delete();
    }

  vtkDebugMacro (<< "Delete Clipped streamlines" );

  currClippedStreamline = 
  #if (VTK_MAJOR_VERSION >= 5)
  (vtkPolyDataAlgorithm *)
  #else
  (vtkPolyDataSource *)
  #endif
    currClippedStreamlines->GetItemAsObject(index);
  if (currClippedStreamline != NULL)
    {
      currClippedStreamlines->RemoveItem(index);
      //currClippedStreamline->Delete();
    }

  vtkDebugMacro( << "Delete MergeFilter" );
  currMergeFilter = (vtkMergeDataObjectFilter *) currMergeFilters->GetItemAsObject(index);
  if (currMergeFilter != NULL)
    {
      currMergeFilters->RemoveItem(index);
      currMergeFilter->Delete();
    }

  vtkDebugMacro( << "Delete transformFilter" );
  currTransFilter = (vtkTransformPolyDataFilter *) currTransFilters->GetItemAsObject(index);
  if (currTransFilter != NULL)
    {
      currTransFilters->RemoveItem(index);
      currTransFilter->Delete();
    }

  vtkDebugMacro( << "Delete tubeAppendFiltersFilter" );
   currTubeFilter = (vtkTubeFilter2 *) currTubeFilters->GetItemAsObject(index);
  if (currTubeFilter != NULL)
    {
      // Disconnect the tube from the appender: 
      //interface between group level and graphic level
      currAppendFilter->RemoveInput(currTubeFilter->GetOutput());
      currTubeFilters->RemoveItem(index);
      currTubeFilter->Delete();
    }


  // If this is the last streamline in the group. Then remove the graphic objects
  // actor, renderer, and mapper and remove group item in group collection
  if (numStreamlinesInGroup == 1) {

    if (currStreamlines != NULL) {
        this->StreamlinesGroup->RemoveItem(groupindex);
        currStreamlines->Delete();
    }

    if (currClippedStreamlines != NULL) {
        this->ClippedStreamlinesGroup->RemoveItem(groupindex);
        currClippedStreamlines->Delete();
    }

    if (currMergeFilters != NULL) {
        this->MergeFiltersGroup->RemoveItem(groupindex);
        currMergeFilters->Delete();
    }

    if (currTransFilters != NULL) {
        this->TransformFiltersGroup->RemoveItem(groupindex);
        currTransFilters->Delete();
    }

    if (currTubeFilters != NULL) {
        this->TubeFiltersGroup->RemoveItem(groupindex);
        currTubeFilters->Delete();
    }

    vtkDebugMacro( << "Deleting actor " << groupindex);
    currActor = (vtkActor *) this->Actors->GetItemAsObject(groupindex);
    if (currActor != NULL)
    {
      if (currActor->GetVisibility()) {
          currActor->VisibilityOff();
          this->NumberOfVisibleActors--;
     } 
      // Remove from the scene (from each renderer)
      // Just like MainRemoveActor in Main.tcl.
      // Don't delete the renderers since they are input.
      this->Renderers->InitTraversal();
      currRenderer= (vtkRenderer *)this->Renderers->GetNextItemAsObject();
      while(currRenderer)
        {
          vtkDebugMacro( << "Delete actor from renderer " << currRenderer);
          currRenderer->RemoveActor(currActor);
          currRenderer= (vtkRenderer *)this->Renderers->GetNextItemAsObject();
        }

      // Delete the actors, this class created them
      this->Actors->RemoveItem(groupindex);
      currActor->Delete();
    }

    vtkDebugMacro( << "Delete mapper" );
    currMapper = (vtkPolyDataMapper *) this->Mappers->GetItemAsObject(groupindex);
    if (currMapper != NULL)
        {
        this->Mappers->RemoveItem(groupindex);
        currMapper->Delete();
        }
    vtkDebugMacro( << "Delete appender" );
    currAppendFilter = (vtkAppendPolyData *) this->AppendFilters->GetItemAsObject(groupindex);
    if (currAppendFilter != NULL)
        {
        this->AppendFilters->RemoveItem(groupindex);
        currAppendFilter->Delete();
        }
   }

}

// Delete all of the DISPLAY objects created for one streamline 
//----------------------------------------------------------------------------
vtkHyperStreamline* vtkDisplayTracts::GetStreamlineInGroup(int groupindex, int index)
{
 vtkCollection *currStreamlines;
 currStreamlines = (vtkCollection *)this->StreamlinesGroup->GetItemAsObject(groupindex);
 return (vtkHyperStreamline *) currStreamlines->GetItemAsObject(index);
}

// This is the delete called from the user interface where the
// actor has been picked with the mouse.
//----------------------------------------------------------------------------
void vtkDisplayTracts::DeleteStreamline(vtkCellPicker *picker)
{
  int groupindex,index;

  vtkActor *pickedActor = picker->GetActor();
  groupindex = this->GetStreamlineGroupIndexFromActor(pickedActor);
  index = this->GetStreamlineIndexFromActor(groupindex,picker);

  if (index >=0 && groupindex >=0)
    {
      this->DeleteStreamlineInGroup(groupindex,index);
    }
}

// Get the index into all of the collections corresponding to the picked
// actor.
//----------------------------------------------------------------------------
int vtkDisplayTracts::GetStreamlineGroupIndexFromActor(vtkActor *pickedActor)
{
  int groupindex;

  vtkDebugMacro( << "Picked actor (present?): " << pickedActor);
  // find the actor on the collection.
  // nonzero index means item was found.
  groupindex = this->Actors->IsItemPresent(pickedActor);

  // the index returned was 1-based but actually to get items
  // from the list we must use 0-based indices.  Very
  // strange but this is necessary.
  groupindex--;

  // so now "not found" is -1, and >=0 are valid indices
  return(groupindex);
}

// Get the index into all of the collections corresponding to the picked
// actor.
//----------------------------------------------------------------------------
int vtkDisplayTracts::GetStreamlineIndexFromActor(int groupindex,vtkCellPicker *picker)
{

 vtkCollection *currTubeFilters = (vtkCollection *) this->TubeFiltersGroup->GetItemAsObject(groupindex);

 if (currTubeFilters == NULL) {
    return -1;
 }

 //Point id of the first point of the picked cell

 vtkAppendPolyData *currAppender =  (vtkAppendPolyData *)(this->AppendFilters->GetItemAsObject(groupindex));

 vtkCell *cell =currAppender->GetOutput()->GetCell(picker->GetCellId());
 vtkIdType ptId = cell->GetPointId(0);

 double *pt = currAppender->GetOutput()->GetPoint(ptId);
 vtkTubeFilter2 * currTubeFilter;
 vtkMergePoints *loc = vtkMergePoints::New();

 //cout<<"Pick point id: "<<ptId<<" Points coordinate: "<<pt[0]<<" "<<pt[1]<<" "<<pt[2]<<endl;
 vtkPoints *p;
 int result;
 double testp[3];
 for (int i = 0; i < currTubeFilters->GetNumberOfItems(); i++)
   {
   currTubeFilter = (vtkTubeFilter2 *)currTubeFilters->GetItemAsObject(i);
   if (currTubeFilter == NULL)
     {
     continue;
     }
   //loc->SetDataSet(currTubeFilter->GetOutput());
   //result = loc->IsInsertedPoint(pt[0],pt[1],pt[2]);
   p = currTubeFilter->GetOutput()->GetPoints();
   result = -1;
   for (int j=0; j<p->GetNumberOfPoints();j++) {
        p->GetPoint(j,testp);
        if (testp[0] == pt[0] && testp[1] == pt[1] && testp[2] == pt[2]) {
            result = j;
            break;
        }
   }

   if (result >-1)
     {
      //Bingo
      //cout<<"Bingo: Fiber to remove num: "<<i<<endl;
      loc->Delete();
      return i;
     }
   }
  
loc->Delete();

//We didn't find the point that the picker chose.
return  -1;

}


vtkCollection *vtkDisplayTracts::GetClippedStreamlines() {

  int numGroups, numItems;
  vtkCollection *currStreamlines;
  numGroups = this->ClippedStreamlinesGroup->GetNumberOfItems();
  // Empty the collection
  this->ClippedStreamlines->RemoveAllItems();

  for (int i=0; i< numGroups; i++)
    {
     currStreamlines = (vtkCollection *) this->ClippedStreamlinesGroup->GetItemAsObject(i);
     numItems = currStreamlines->GetNumberOfItems();
     for (int k=0; k< numItems; k++) {
        this->ClippedStreamlines->AddItem(currStreamlines->GetItemAsObject(k));
     }
    }
   return this->ClippedStreamlines;
}
