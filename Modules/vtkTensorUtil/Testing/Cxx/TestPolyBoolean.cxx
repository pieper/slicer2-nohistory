#include "vtkPolyBoolean.h"
#include "vtkSphereSource.h"

int TestPolyBoolean(int, char *[])
{
  vtkSphereSource *s1 = vtkSphereSource::New();
  vtkSphereSource *s2 = vtkSphereSource::New();
  vtkSphereSource *s3 = vtkSphereSource::New();


  vtkPolyBoolean *pb = vtkPolyBoolean::New();
  pb-> SetOperation (0);

  pb-> SetInput (s1-> GetOutput());
  pb-> SetPolyDataB (s2-> GetOutput());
  pb-> Update();

  return 0;
}
