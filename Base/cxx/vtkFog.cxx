/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkFog.cxx,v $
  Date:      $Date: 2006/01/06 17:56:38 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

#include "vtkFog.h"
#include "vtkRenderWindow.h"
#include "vtkObjectFactory.h"

#ifndef VTK_IMPLEMENT_MESA_CXX
#include <GL/gl.h>
#endif


//----------------------------------------------------------------------
//
//
vtkFog::vtkFog()
//      ------
{
  this->FogEnabled = 0;
  this->FogStart   = 0;
  this->FogEnd     = 100;

} // constructor vtkFog()

//----------------------------------------------------------------------
// return the correct type of Renderer 
//
vtkFog *vtkFog::New()
//              ---
{ 

  //  printf("vtkFog::New() \n");
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkFog");
  if(ret)
  {
    return (vtkFog*)ret;
  }

  return  new vtkFog;
} // New()



// Implement base class method.
void vtkFog::Render(vtkRenderer *ren)
{

  //  printf("vtkFog::Render() begin \n");

    vtkRenderWindow* renwin;

    renwin = ren->GetRenderWindow();
    renwin->MakeCurrent();

  // Fog,  Karl Krissian
  if (!this->FogEnabled)
    {
      //      fprintf(stderr,"glDisable(GL_FOG) %d ", this->Fog);
      glDisable (GL_FOG);
    }
  else 
    {
      //  fprintf(stderr,"glEnable(GL_FOG)");
      glEnable(GL_FOG);
      glFogi(  GL_FOG_MODE,  GL_LINEAR);
      float bg[3];
      for (int i = 0; i < 3; i++)
        {
        bg[i] = ren->GetBackground()[i];
        }
      glFogfv( GL_FOG_COLOR, bg);
               //      glFogf(  GL_FOG_DENSITY, _density);
      glHint(  GL_FOG_HINT,    GL_DONT_CARE);
      glFogf(  GL_FOG_START,   FogStart);
      glFogf(  GL_FOG_END,     FogEnd);
      
    }

  //  printf("vtkFog::Render() end \n");

}

