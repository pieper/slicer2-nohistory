/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGraphicsFactoryAddition.cxx,v $
  Date:      $Date: 2006/01/06 17:58:07 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkObjectFactory.h"

#include "vtkGraphicsFactoryAddition.h"
#include "vtkToolkits.h"
#include "vtkDebugLeaks.h"

// if using some sort of opengl, then include these files
#if defined(VTK_USE_OGLR) || defined(_WIN32) || defined(VTK_USE_COCOA) || defined(VTK_USE_CARBON)
#include "vtkOpenGLActor.h"
#include "vtkOpenGLCamera.h"
#include "vtkOpenGLImageActor.h"
#include "vtkOpenGLLight.h"
#include "vtkOpenGLProperty.h"
#include "vtkOpenGLPolyDataMapper.h"
#include "vtkOpenGLRenderer.h"
#include "vtkOpenGLTexture.h"
#include "vtkOpenGLVolumeTextureMapper2D.h"
#include "vtkOpenGLVolumeTextureMapper3D.h"
#include "vtkOpenGLVolumeRayCastMapper.h"
#endif

// Win32 specific stuff
#ifdef _WIN32
# ifndef VTK_USE_OGLR
#  include "vtkWin32OpenGLRenderWindow.h"
#  include "vtkWin32RenderWindowInteractor.h"
#  define VTK_DISPLAY_WIN32_OGL
# endif // VTK_USE_OGLR
#endif

// Apple OSX stuff
#ifdef VTK_USE_CARBON
# include "vtkCarbonRenderWindow.h"
# include "vtkCarbonRenderWindowInteractor.h"
# define VTK_DISPLAY_CARBON
#endif

#ifdef VTK_USE_COCOA
# include "vtkCocoaRenderWindow.h"
# include "vtkCocoaRenderWindowInteractor.h"
# define VTK_DISPLAY_COCOA
#endif

// X OpenGL stuff
#ifdef VTK_USE_OGLR
# include "vtkXRenderWindowInteractor.h"
# include "vtkXOpenGLRenderWindow.h"
# define VTK_DISPLAY_X11_OGL
#endif

#if defined(VTK_USE_MANGLED_MESA)
#include "vtkMesaActor.h"
#include "vtkMesaCamera.h"
#include "vtkMesaImageActor.h"
#include "vtkMesaLight.h"
#include "vtkMesaProperty.h"
#include "vtkMesaPolyDataMapper.h"
#include "vtkMesaRenderer.h"
#include "vtkMesaTexture.h"
#include "vtkMesaVolumeTextureMapper2D.h"
#include "vtkMesaVolumeRayCastMapper.h"
#include "vtkXMesaRenderWindow.h"
#endif

#include "vtkCriticalSection.h"

#include "stdlib.h"

static vtkSimpleCriticalSection vtkUseMesaClassesCriticalSection;
int vtkGraphicsFactoryAddition::UseMesaClasses = 0;

vtkCxxRevisionMacro(vtkGraphicsFactoryAddition, "$Revision: 1.3 $");
vtkStandardNewMacro(vtkGraphicsFactoryAddition);

const char *vtkGraphicsFactoryAddition::GetRenderLibrary()
{
  const char *temp;
  
  // first check the environment variable
  temp = getenv("VTK_RENDERER");
  
  // Backward compatibility
  if ( temp )
    {
    if (!strcmp("oglr",temp))
      {
      temp = "OpenGL";
      }
    else if (!strcmp("woglr",temp))
      {
      temp = "Win32OpenGL";
      }
    else if (strcmp("OpenGL",temp) && 
             strcmp("Win32OpenGL",temp))
      {
      vtkGenericWarningMacro(<<"VTK_RENDERER set to unsupported type:" << temp);
      temp = NULL;
      }
    }

  // if nothing is set then work down the list of possible renderers
  if ( !temp )
    {
#ifdef VTK_DISPLAY_X11_OGL
    temp = "OpenGL";
#endif
#ifdef VTK_DISPLAY_WIN32_OGL
    temp = "Win32OpenGL";
#endif
#ifdef VTK_DISPLAY_CARBON
    temp = "CarbonOpenGL";
#endif
#ifdef VTK_DISPLAY_COCOA
    temp = "CocoaOpenGL";
#endif
    }
  
  return temp;
}

vtkObject* vtkGraphicsFactoryAddition::CreateInstance(const char* vtkclassname )
{
  // first check the object factory
  vtkObject *ret = vtkObjectFactory::CreateInstance(vtkclassname);
  if (ret)
    {
    return ret;
    }
  // if the factory failed to create the object,
  // then destroy it now, as vtkDebugLeaks::ConstructClass was called
  // with vtkclassname, and not the real name of the class
#ifdef VTK_DEBUG_LEAKS
  vtkDebugLeaks::DestructClass(vtkclassname);
#endif
  const char *rl = vtkGraphicsFactoryAddition::GetRenderLibrary();
  
#ifdef VTK_USE_OGLR
  if (!strcmp("OpenGL",rl))
    {
    if(strcmp(vtkclassname, "vtkRenderWindow") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkXMesaRenderWindow::New();
        }
#endif
      return vtkXOpenGLRenderWindow::New();
      }
    }
  if(strcmp(vtkclassname, "vtkRenderWindowInteractor") == 0)
    {
    return vtkXRenderWindowInteractor::New();
    }
#endif

#ifdef VTK_DISPLAY_WIN32_OGL
  if(strcmp(vtkclassname, "vtkRenderWindowInteractor") == 0)
    {
    return vtkWin32RenderWindowInteractor::New();
    }
  if (!strcmp("Win32OpenGL",rl))
    {
    if(strcmp(vtkclassname, "vtkRenderWindow") == 0)
      {
      return vtkWin32OpenGLRenderWindow::New();
      }
    }
#endif

#ifdef VTK_USE_CARBON
  if(strcmp(vtkclassname, "vtkRenderWindowInteractor") == 0)
    {
    return vtkCarbonRenderWindowInteractor::New();
    }
  if(strcmp(vtkclassname, "vtkRenderWindow") == 0)
    {
    return vtkCarbonRenderWindow::New();
    }
#endif
#ifdef VTK_USE_COCOA
  if(strcmp(vtkclassname, "vtkRenderWindowInteractor") == 0)
    {
    return vtkCocoaRenderWindowInteractor::New();
    }
  if(strcmp(vtkclassname, "vtkRenderWindow") == 0)
    {
    return vtkCocoaRenderWindow::New();
    }
#endif

#if defined(VTK_USE_OGLR) || defined(_WIN32) || defined(VTK_USE_COCOA) || defined(VTK_USE_CARBON)
  if (!strcmp("OpenGL",rl) || !strcmp("Win32OpenGL",rl) || !strcmp("CarbonOpenGL",rl) || !strcmp("CocoaOpenGL",rl))
    {
    if(strcmp(vtkclassname, "vtkActor") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaActor::New();
        }
#endif
      return vtkOpenGLActor::New();
      }
    if(strcmp(vtkclassname, "vtkCamera") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaCamera::New();
        }
#endif
      return vtkOpenGLCamera::New();
      }
    if(strcmp(vtkclassname, "vtkImageActor") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaImageActor::New();
        }
#endif
      return vtkOpenGLImageActor::New();
      }
    if(strcmp(vtkclassname, "vtkLight") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaLight::New();
        }
#endif
      return vtkOpenGLLight::New();
      }
    if(strcmp(vtkclassname, "vtkProperty") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaProperty::New();
        }
#endif
      return vtkOpenGLProperty::New();
      }
    if(strcmp(vtkclassname, "vtkPolyDataMapper") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaPolyDataMapper::New();
        }
#endif
      return vtkOpenGLPolyDataMapper::New();
      }
    if(strcmp(vtkclassname, "vtkRenderer") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaRenderer::New();
        }
#endif
      return vtkOpenGLRenderer::New();
      }
    if(strcmp(vtkclassname, "vtkTexture") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaTexture::New();
        }
#endif
      return vtkOpenGLTexture::New();
      }
    if(strcmp(vtkclassname, "vtkVolumeTextureMapper2D") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaVolumeTextureMapper2D::New();
        }
#endif
      return vtkOpenGLVolumeTextureMapper2D::New();
      }
//---------------------------------------------------------
if(strcmp(vtkclassname, "vtkVolumeTextureMapper3D") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaVolumeTextureMapper3D::New();
        }
#endif
      return vtkOpenGLVolumeTextureMapper3D::New();
      }
//----------------------------------------------------------
    if(strcmp(vtkclassname, "vtkVolumeRayCastMapper") == 0)
      {
#if defined(VTK_USE_MANGLED_MESA)
      if ( vtkGraphicsFactoryAddition::UseMesaClasses )
        {
        return vtkMesaVolumeRayCastMapper::New();
        }
#endif
      return vtkOpenGLVolumeRayCastMapper::New();
      }
    }
#endif
        
  return 0;
}

void vtkGraphicsFactoryAddition::SetUseMesaClasses(int use)
{
  vtkUseMesaClassesCriticalSection.Lock();
  vtkGraphicsFactoryAddition::UseMesaClasses = use;
  vtkUseMesaClassesCriticalSection.Unlock();
}

int vtkGraphicsFactoryAddition::GetUseMesaClasses()
{
  return vtkGraphicsFactoryAddition::UseMesaClasses;
}

//----------------------------------------------------------------------------

