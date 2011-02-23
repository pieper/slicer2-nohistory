#include "vtkImageData.h"
#include "vtkFloatArray.h"
#include "vtkImageGetTensorComponents.h"
#include "vtkPointData.h"

int TestImageGetTensorComponents(int, char *[])
{

  vtkImageData * img = vtkImageData::New();
  img->SetScalarTypeToUnsignedChar();
  img->SetDimensions (10,10,10);
  img-> AllocateScalars();

  vtkFloatArray *aFloatTensors = vtkFloatArray::New();
  //aFloatTensors-> Allocate (1, 1);
  aFloatTensors-> SetNumberOfComponents (9);
  const int numTens = 10*10*10;
  aFloatTensors-> SetNumberOfTuples (numTens);
  aFloatTensors-> SetName ( "aFloatTensors" );
  for ( int i=0;  i < aFloatTensors->GetNumberOfTuples(); ++i)
    for ( int j=0;  j < aFloatTensors->GetNumberOfComponents(); ++j)
      aFloatTensors ->SetComponent (i ,j, 1);

  img->GetPointData()->SetTensors (aFloatTensors);
  vtkDataArray *tensors = img->GetPointData()->GetTensors();
  //tensors->Print(cout);
  img->GetPointData()-> GetTensors()-> SetName ("TestTensors");

  for (int  i = 0; i<numTens; ++i)
    tensors-> SetTuple9 (i, 1, 2, 3, 4, 5, 6, 7, 8, 9);


  vtkImageGetTensorComponents *getTens = vtkImageGetTensorComponents::New();
  getTens ->SetInput (img);
  getTens ->Update();

  img-> Print(cout);
  getTens-> GetOutput()-> Print(cout);


  return 0;
}
