/* 
 * Here is where system computed values get stored.
 * These values should only change when the target compile platform changes.
 */

#define VTKIBROWSER_BUILD_SHARED_LIBS
#ifndef VTKIBROWSER_BUILD_SHARED_LIBS
#define VTKIBROWSER_STATIC
#endif

#if defined(WIN32) && !defined(VTKIBROWSER_STATIC)
#pragma warning ( disable : 4275 )

#if defined(vtkIbrowser_EXPORTS)
#define VTK_IBROWSER_EXPORT __declspec( dllexport ) 
#else
#define VTK_IBROWSER_EXPORT __declspec( dllimport ) 
#endif
#else
#define VTK_IBROWSER_EXPORT
#endif
