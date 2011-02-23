/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkNeuroendoscopy.h,v $
  Date:      $Date: 2007/07/02 18:56:34 $
  Version:   $Revision: 1.2 $


=========================================================================auto=*/
#ifndef __vtkNeuroendoscopy_h
#define __vtkNeuroendoscopy_h

//#include "vtkObjectFactory.h"
#include "vtkObject.h"

#include <vtkNeuroendoscopyConfigure.h>
//#include <itkVersion.h>


class VTK_NEUROENDOSCOPY_EXPORT vtkNeuroendoscopy  : public vtkObject {
public:
    static vtkNeuroendoscopy *New();
    //void PrintSelf(ostream& os, vtkIndent indent);
   // char *GetEndoscopyNEWVersion();
 vtkTypeMacro(vtkNeuroendoscopy, vtkObject);

    // p - p value
    // dof - degrees of freedom 
    // The function returns t statistic.
    double p2t(double p, long dof);

    // Description:
    // Converts t statistic to p value
    // t - t statistic 
    // dof - degrees of freedom 
    // The function returns p value
    double t2p(double t, long dof);
};
#endif
