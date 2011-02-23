/* 
 * Here is where system computed values get stored.
 * These values should only change when the target compile platform changes.
 */

#define VTKAFFINESEGMENT_BUILD_SHARED_LIBS
#ifndef VTKAFFINESEGMENT_BUILD_SHARED_LIBS
#define VTKAFFINESEGMENT_STATIC
#endif

#if defined(WIN32) && !defined(VTKAFFINESEGMENT_STATIC)
#pragma warning ( disable : 4275 )

#if defined(vtkAffineSegment_EXPORTS)
#define VTK_AFFINESEGMENT_EXPORT __declspec( dllexport ) 
#else
#define VTK_AFFINESEGMENT_EXPORT __declspec( dllimport ) 
#endif
#else
#define VTK_AFFINESEGMENT_EXPORT
#endif
