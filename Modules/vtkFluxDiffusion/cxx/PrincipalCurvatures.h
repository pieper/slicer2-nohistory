/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: PrincipalCurvatures.h,v $
  Date:      $Date: 2006/01/06 17:57:40 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
/*  ==================================================
    Module: vtkFluxDiffusion
    Author: Karl Krissian
    Email:  karl@bwh.harvard.edu

    This module implements a version of anisotropic diffusion published in 
    
    "Flux-Based Anisotropic Diffusion Applied to Enhancement of 3D Angiographiam"
    Karl Krissian
    IEEE Trans. Medical Imaging, 21(11), pp 1440-1442, nov 2002.
    
    It aims at restoring 2D and 3D images with the ability to preserve
    small and elongated structures.
    It comes with a Tcl/Tk interface for the '3D Slicer'.
    ==================================================
    Copyright (C) 2002  Karl Krissian

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    ================================================== 
    The full GNU Lesser General Public License file is in vtkFluxDiffusion/LesserGPL_license.txt
*/



//
//  Code by Prof. Luis Alvarez Leon
//  University of Las Palmas of Gran Canaria
//



#ifndef CURVATURAS_PRINCIPALES_HPP
#define CURVATURAS_PRINCIPALES_HPP

namespace FluxDiffusion {

#include <vtkFluxDiffusionConfigure.h>

//BTX
int CurvaturasPrincipales(float H[3][3],
              float p[3],
              float vmax[3],
              float vmin[3],
              float *lmax,
              float *lmin,
              float umbral);

// Without eigenvectors
int CurvaturasPrincipales(float H[3][3],
              float p[3],
              float *lmax,
              float *lmin,
              float umbral);

//ETX

}

#endif // CURVATURAS_PRINCIPALES_HPP
