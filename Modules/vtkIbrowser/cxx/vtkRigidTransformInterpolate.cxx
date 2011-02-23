/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkRigidTransformInterpolate.cxx,v $
  Date:      $Date: 2006/01/13 16:23:08 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkRigidTransformInterpolate - Reads Nearly Raw Raster Data files
// .SECTION Description
// vtkRigidTransformInterpolate 
// Uses Quaternion code from vtkMath to interpolated between two rigid transform matrices
//

//
// .SECTION See Also
// vtkObject
//

#include "vtkRigidTransformInterpolate.h"

#include "vtkMatrix4x4.h"
#include "vtkMath.h"

vtkCxxRevisionMacro(vtkRigidTransformInterpolate, "$Revision: 1.6 $");
vtkStandardNewMacro(vtkRigidTransformInterpolate);

/*
 * quaternion interpolation functions translated to vtk
 * from various web resources including:
 * http://www.comp.leeds.ac.uk/royr/gi31/exercises/iri_quat.c
 */

#define QX 1
#define QY 2
#define QZ 3
#define QW 0

//----------------------------------------------------------------------------
// In-place normalization of the supplied quaternion
//
template<class T>
 inline void vtkQuaternionNormalize (T quat[4])
{
    T length;

    length = quat[QW] * quat[QW] + quat[QX] * quat[QX] +
             quat[QY] * quat[QY] + quat[QZ] * quat[QZ];

    if( length > 0.1 ) {
        length = (T) sqrt( (double) length );
        quat[QW] /= length;
        quat[QX] /= length;
        quat[QY] /= length;
        quat[QZ] /= length;
    }
}


//----------------------------------------------------------------------------
// Calculate the unit quaternion that is a 'T'th of the way from quat0 to quat1
// and put it in quatT
//
template<class T1, class T2>
 inline void vtkQuaternionSlerp (T1 quat0[4], T1 quat1[4], T1 quatT[4], T2 T)
{
    T1 to1[4];
    T1 DELTA, omega, cosom, sinom, scale0, scale1;
    DELTA = 0.01;

    /* calc cosine */
    cosom = quat0[QX] * quat1[QX] + quat0[QY] * quat1[QY] + 
            quat0[QZ] * quat1[QZ] + quat0[QW] * quat1[QW];

    /* adjust signs (if necessary) */
    if ( cosom < 0.0 ){ 
        cosom = -cosom; 
        to1[QX] = - quat1[QX];
        to1[QY] = - quat1[QY];
        to1[QZ] = - quat1[QZ];
        to1[QW] = - quat1[QW];
    } else  {
        to1[QX] = quat1[QX];
        to1[QY] = quat1[QY];
        to1[QZ] = quat1[QZ];
        to1[QW] = quat1[QW];
    }


    /* calculate coefficients */
    if ( (1.0 - cosom) > DELTA ) {
        /* standard case (slerp) */
        omega = acos(cosom);
        sinom = sin(omega);
        scale0 = sin((1.0 - T) * omega) / sinom;
        scale1 = sin(T * omega) / sinom;
    } else {        
        /* "from" and "to" quaternions are very close so we can do a linear interpolation */
        scale0 = 1.0 - T;
        scale1 = T;
    }

    /* calculate final values */
    quatT[QX] = scale0 * quat0[QX] + scale1 * to1[QX];
    quatT[QY] = scale0 * quat0[QY] + scale1 * to1[QY];
    quatT[QZ] = scale0 * quat0[QZ] + scale1 * to1[QZ];
    quatT[QW] = scale0 * quat0[QW] + scale1 * to1[QW];

    /* Normalise in case of rounding error */
    vtkQuaternionNormalize ( quatT );
}



//----------------------------------------------------------------------------
void vtkRigidTransformInterpolate::Interpolate()
{
    if ( !this->M0 || !this->M1 || !this->MT ) 
    {
        vtkErrorMacro( "Need to set endpoints (M0 and M1) and interpolated matrix (MT)" );
        return;
    }

    vtkFloatingPointType T0[3], T1[3];
    vtkFloatingPointType A0[3][3], A1[3][3], AT[3][3];
    vtkFloatingPointType Q0[4], Q1[4], QT[4];
    int i,j;

    // extract the translation vector and the upper 3x3 rotation matrix
    for (i = 0; i < 3; i++)
    {   
        T0[i] = this->M0->GetElement(i,3);
        T1[i] = this->M1->GetElement(i,3);
        for (j = 0; j < 3; j++)
        {
            A0[i][j] = this->M0->GetElement(i,j);
            A1[i][j] = this->M1->GetElement(i,j);
        }
    }

    // interpolate the quaternion portion
    
    vtkMath *math = vtkMath::New();

    math->Matrix3x3ToQuaternion (A0, Q0);
    math->Matrix3x3ToQuaternion (A1, Q1);
    vtkQuaternionSlerp (Q0, Q1, QT, this->T);
    math->QuaternionToMatrix3x3 (QT, AT);

    // fill the interpolated matrix
    this->MT->Identity();
    for (i = 0; i < 3; i++)
    {   
        this->MT->SetElement(i, 3, T0[i] + this->T * (T1[i] - T0[i]));
        for (j = 0; j < 3; j++)
        {
            this->MT->SetElement(i,j,AT[i][j]);
        }
    } 

    math->Delete();

}


//----------------------------------------------------------------------------
void vtkRigidTransformInterpolate::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);
  vtkIndent subindent = indent.GetNextIndent();
  if ( this->M0 ) { this->M0->PrintSelf(os,subindent); }
  if ( this->M1 ) { this->M1->PrintSelf(os,subindent); }
  if ( this->MT ) { this->MT->PrintSelf(os,subindent); }
  os << indent << "T = " << this->T << "\n";
}
