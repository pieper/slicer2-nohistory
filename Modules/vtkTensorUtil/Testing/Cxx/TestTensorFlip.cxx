#include "vtkTensorFlip.h"
#include "vtkImageData.h"
#include "vtkFloatArray.h"
#include "vtkPointData.h"
#include "vtkStructuredPointsWriter.h"
#include "vtkImageMathematics.h"

int TestTensorFlip(int, char *[])
{
  vtkImageData *img = vtkImageData::New();
  img->SetDimensions(6,6,6);
  vtkIdType numPts = img->GetNumberOfPoints();

  vtkFloatArray *tensors = vtkFloatArray::New();
  tensors->SetNumberOfComponents(9);
  tensors->SetName("TestTensors");
  tensors->SetNumberOfTuples(numPts);
  img->GetPointData()->SetTensors( tensors );

  // Initialize
  const float templat[9] = { 1,0,0,0,2,3,0,4,5 };
  for(vtkIdType i = 0; i < numPts; ++i )
    {
    memcpy( tensors->GetPointer(9*i), templat, 9*sizeof(float));
    }
  img->Update();
  img->Print ( cout );

  vtkTensorFlip * flip = vtkTensorFlip::New();
  flip->SetInput( img );
  flip->Update();

  vtkImageMathematics *math = vtkImageMathematics::New();
  math->SetInput1( img );
  math->SetInput2( flip->GetOutput() );
  math->SetOperationToSubtract();

  tensors->Delete();
  flip->Delete();
  img->Delete();
  math->Delete();

  return 0;
}
