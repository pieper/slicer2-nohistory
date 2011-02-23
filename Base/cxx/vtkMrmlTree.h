/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlTree.h,v $
  Date:      $Date: 2006/02/14 20:40:15 $
  Version:   $Revision: 1.19 $

=========================================================================auto=*/
// .NAME vtkMrmlTree - a list of actors
// .SECTION Description
// vtkMrmlTree represents and provides methods to manipulate a list of
// MRML objects. The list is core and duplicate
// entries are not prevented.
//
// SECTION Transforms
//  The question is: in what order are transforms applied?
//  Twice in vtkMrmlTree.cxx, we set tran->PreMultiply();
//  The result is that if we traverse a MRML tree, and we
//  run into transforms M1 and then M2 as we traverse down
//  the tree, the resulting transform is M = M1*M2.
//
//  Just to be clear, given the following structure:
//  Transform
//    Matrix: M1
//    Transform
//      Matrix: M2
//      Matrix: M3
//      Volume: V1
//      Model:  Model1
//    End Transform
//  End Transform
//
// Then the effective transform applied to V1 is  M1*M2*M3.
// Note that the Transform is the RAS to World transform for the volume V1.
// It is the same for the Model, Model1. Though, the RasToWld matrix is
// only set explicitly for models and volumes.
//
// .SECTION see also
// vtkMrmlNode vtkCollection 

#ifndef __vtkMrmlTree_h
#define __vtkMrmlTree_h

#include "vtkCollection.h"
#include "vtkMrmlNode.h"
#include "vtkMrmlVolumeNode.h"
#include "vtkMrmlModelNode.h"
#include "vtkMrmlTransformNode.h"
#include "vtkMrmlMatrixNode.h"
#include "vtkMrmlColorNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlTree : public vtkCollection
{
public:
  static vtkMrmlTree *New();
  vtkTypeMacro(vtkMrmlTree,vtkCollection);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  void Write(char *filename);

  // Description:
  // Add a path to the list.
  void AddItem(vtkMrmlNode *n) {
    this->vtkCollection::AddItem((vtkObject *)n);};

  // Description:
  // Remove a path from the list.
  void RemoveItem(vtkMrmlNode *n) {
    this->vtkCollection::RemoveItem((vtkObject *)n);};

  // Description:
  // Determine whether a particular node is present. Returns its position
  // in the list.
  int IsItemPresent(vtkMrmlNode *n) {
    return this->vtkCollection::IsItemPresent((vtkObject *)n);};

  // Description:
  // Get the next path in the list.
  vtkMrmlNode *GetNextItem() {
    return (vtkMrmlNode *)(this->GetNextItemAsObject());};

  vtkMrmlVolumeNode *GetNextVolume() {
    return (vtkMrmlVolumeNode*)this->GetNextItemByClass("vtkMrmlVolumeNode");};
  vtkMrmlModelNode *GetNextModel() {
    return (vtkMrmlModelNode*)this->GetNextItemByClass("vtkMrmlModelNode");};
  vtkMrmlTransformNode *GetNextTransform() {
    return (vtkMrmlTransformNode*)this->GetNextItemByClass("vtkMrmlTransformNode");};
  vtkMrmlMatrixNode *GetNextMatrix() {
    return (vtkMrmlMatrixNode*)this->GetNextItemByClass("vtkMrmlMatrixNode");};
  vtkMrmlColorNode *GetNextColor() {
    return (vtkMrmlColorNode*)this->GetNextItemByClass("vtkMrmlColorNode");};

  vtkMrmlVolumeNode *InitVolumeTraversal() {
    return (vtkMrmlVolumeNode*)this->InitTraversalByClass("vtkMrmlVolumeNode");};
  vtkMrmlModelNode *InitModelTraversal() {
    return (vtkMrmlModelNode*)this->InitTraversalByClass("vtkMrmlModelNode");};
  vtkMrmlTransformNode *InitTransformTraversal() {
    return (vtkMrmlTransformNode*)this->InitTraversalByClass("vtkMrmlTransformNode");};
  vtkMrmlMatrixNode *InitMatrixTraversal() {
    return (vtkMrmlMatrixNode*)this->InitTraversalByClass("vtkMrmlMatrixNode");};
  vtkMrmlColorNode *InitColorTraversal() {
    return (vtkMrmlColorNode*)this->InitTraversalByClass("vtkMrmlColorNode");};

  vtkMrmlNode* GetNthItem(int n);
  vtkMrmlVolumeNode *GetNthVolume(int n) {
    return (vtkMrmlVolumeNode*)this->GetNthItemByClass(n, "vtkMrmlVolumeNode");};
  vtkMrmlModelNode *GetNthModel(int n) {
    return (vtkMrmlModelNode*)this->GetNthItemByClass(n, "vtkMrmlModelNode");};
  vtkMrmlTransformNode *GetNthTransform(int n) {
    return (vtkMrmlTransformNode*)this->GetNthItemByClass(n, "vtkMrmlTransformNode");};
  vtkMrmlMatrixNode *GetNthMatrix(int n) {
    return (vtkMrmlMatrixNode*)this->GetNthItemByClass(n, "vtkMrmlMatrixNode");};
  vtkMrmlColorNode *GetNthColor(int n) {
    return (vtkMrmlColorNode*)this->GetNthItemByClass(n, "vtkMrmlColorNode");};

  int GetNumberOfVolumes() {
    return this->GetNumberOfItemsByClass("vtkMrmlVolumeNode");};
  int GetNumberOfModels() {
    return this->GetNumberOfItemsByClass("vtkMrmlModelNode");};
  int GetNumberOfTransforms() {
    return this->GetNumberOfItemsByClass("vtkMrmlTransformNode");};
  int GetNumberOfMatrices() {
    return this->GetNumberOfItemsByClass("vtkMrmlMatrixNode");};
  int GetNumberOfColors() {
    return this->GetNumberOfItemsByClass("vtkMrmlColorNode");};

  void ComputeTransforms();

  void InsertAfterItem( vtkMrmlNode *item, vtkMrmlNode *newItem);
  void InsertBeforeItem( vtkMrmlNode *item, vtkMrmlNode *newItem);

  // Description:
  // Compute the Transform for one node
  // The second just gets the matrix
  // There is no check that the node actually exists. The function
  // sometimes crash without it.
  void ComputeNodeTransform( vtkMrmlNode *node, vtkTransform *xform );
  void ComputeNodeTransform( vtkMrmlNode *node, vtkMatrix4x4 *xform );

    // Description:
    // The reader should set this code at the end of the update.
    // The error code contains a possible error that occured while
    // writing the file.
    vtkGetMacro(ErrorCode, unsigned long );
    
protected:
  vtkMrmlTree() {};
  ~vtkMrmlTree() {};
  vtkMrmlTree(const vtkMrmlTree&);
  void operator=(const vtkMrmlTree&);

  vtkMrmlNode *InitTraversalByClass(const char *className);
  int GetNumberOfItemsByClass(const char *className);
  vtkMrmlNode* GetNthItemByClass(int n, const char *className);
  vtkMrmlNode *GetNextItemByClass(const char *className);

     // Description:
    // The reader should set this code at the end of the update.
    // The error code contains a possible error that occured while
    // writing the file.
    vtkSetMacro( ErrorCode, unsigned long );
private:
  // hide the standard AddItem from the user and the compiler.
  void AddItem(vtkObject *o) { this->vtkCollection::AddItem(o); };
  void RemoveItem(vtkObject *o) { this->vtkCollection::RemoveItem(o); };
  void RemoveItem(int i) { this->vtkCollection::RemoveItem(i); };
  int  IsItemPresent(vtkObject *o) { return this->vtkCollection::IsItemPresent(o);};
    unsigned long ErrorCode;
};

#endif
