/* 
 * Here is where system computed values get stored.
 * These values should only change when the target compile platform changes.
 */

#define VTKEMATLASBRAINCLASSIFIER_BUILD_SHARED_LIBS
#ifndef VTKEMATLASBRAINCLASSIFIER_BUILD_SHARED_LIBS
#define VTKEMATLASBRAINCLASSIFIER_STATIC
#endif

#if defined(WIN32) && !defined(VTKEMATLASBRAINCLASSIFIER_STATIC)
#pragma warning ( disable : 4275 )

#if defined(vtkEMAtlasBrainClassifier_EXPORTS)
#define VTK_EMATLASBRAINCLASSIFIER_EXPORT __declspec( dllexport ) 
#else
#define VTK_EMATLASBRAINCLASSIFIER_EXPORT __declspec( dllimport ) 
#endif
#else
#define VTK_EMATLASBRAINCLASSIFIER_EXPORT
#endif
