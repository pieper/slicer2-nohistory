#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkDoubleArray.h"
#include "vtkImageToImageFilter.h"
#include "vtkTensorMask.h"
#include "vtkImageEllipsoidSource.h"

int TestTensorMask(int, char *[])
{
  vtkImageData *img = vtkImageData::New();
  img->SetDimensions(6,6,6);
  vtkIdType numPts = img->GetNumberOfPoints();

  vtkDoubleArray *tensors = vtkDoubleArray::New();
  tensors->SetNumberOfComponents(9);
  tensors->SetName("TestTensors");
  tensors->SetNumberOfTuples(numPts);
  img->GetPointData()->SetTensors( tensors );
  img->Update();
  img->Print ( cout );
  memset( tensors->GetPointer(0), 0, 9*numPts*sizeof(double));

  vtkImageEllipsoidSource *sphere = vtkImageEllipsoidSource::New();
  sphere->SetWholeExtent (0, 511, 0, 255, 0, 0);
  sphere->SetCenter (128, 128, 0);
  sphere->SetRadius (80, 80, 1);

  vtkTensorMask *mask = vtkTensorMask::New();
  mask->SetImageInput ( img );
  mask->SetMaskInput ( sphere->GetOutput() );
  mask->SetMaskedOutputValue (100, 128, 200);
  mask->NotMaskOn();
  mask->Update();


  sphere->Delete();
  tensors->Delete();
  img->Delete();
  mask->Delete();

  return 0;
}
