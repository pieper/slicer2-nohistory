/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGLMVolumeGenerator.cxx,v $
  Date:      $Date: 2006/01/31 17:48:00 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

#include "vtkGLMVolumeGenerator.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkCommand.h"

#include "vnl/vnl_matrix.h" 
#include "vnl/algo/vnl_matrix_inverse.h" 


vtkStandardNewMacro(vtkGLMVolumeGenerator);


vtkGLMVolumeGenerator::vtkGLMVolumeGenerator()
{
    this->StandardError = 0.0;
    this->SizeOfContrastVector = 0;
    this->PreWhitening = 0;
    this->beta = NULL; 
    this->ContrastVector = NULL;
    this->DesignMatrix = NULL;

    this->X = NULL;
    this->WX = NULL;
    this->C = NULL;
}


vtkGLMVolumeGenerator::~vtkGLMVolumeGenerator()
{
    if (this->beta != NULL)
        {
            delete [] this->beta;
        }
    if (this->X != NULL)
        {
            delete ((vnl_matrix<float> *)this->X);
        }
    if (this->WX != NULL)
        {
            delete ((vnl_matrix<float> *)this->WX);
        }
    if (this->C != NULL)
        {
            delete ((vnl_matrix<float> *)this->C);
        }
}


void vtkGLMVolumeGenerator::SetContrastVector(vtkIntArray *vec)
{
    this->ContrastVector = vec;
    this->SizeOfContrastVector = this->ContrastVector->GetNumberOfTuples();
    this->beta = new float [this->SizeOfContrastVector]; 
    if (this->beta == NULL)
    {
        vtkErrorMacro( << "Memory allocation failed.");
        return;
    }

    // instantiate C
    if (this->C == NULL)
    {
        this->C = new vnl_matrix<float>;
    }

    ((vnl_matrix<float> *)this->C)->set_size(1, this->SizeOfContrastVector);
    for (int i = 0; i < this->SizeOfContrastVector; i++)
    {
        ((vnl_matrix<float> *)this->C)->put(0, i, vec->GetComponent(i,0));
    } 
}


void vtkGLMVolumeGenerator::SetDesignMatrix(vtkFloatArray *designMat)
{
    this->DesignMatrix = designMat;
    int rows = this->DesignMatrix->GetNumberOfTuples();
    int cols = this->DesignMatrix->GetNumberOfComponents();

    // instantiate design matrix X
    if (this->X == NULL)
   {
        this->X = new vnl_matrix<float>;
    }
    ((vnl_matrix<float> *)this->X)->set_size(rows, cols);
    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            ((vnl_matrix<float> *)this->X)->put(i, j, designMat->GetComponent(i,j));
        }
    }

    // instantiate pre-whitened design matrix WX
    // and initialize it with components of X
    if (this->WX == NULL)
    {
        this->WX = new vnl_matrix<float>;
        ((vnl_matrix<float> *)this->WX)->set_size(rows,cols);
    }
    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            ((vnl_matrix<float> *)this->WX)->put(i, j, designMat->GetComponent(i,j));
        }
    }
}




void vtkGLMVolumeGenerator::ComputeStandardError(float rss, float corrCoeff)
{
    // for each voxel, after a linear modeling (best fit)
    // we'll have a list of beta (one for each regressor) and
    // a chisq (or rss) - the sum of squares of the residuals from the best-fit
    // the standard error se = sqrt(mrss*(C*pinv(X'*X)*C'));
    // where C - contrast row vector
    //       X - design matrix
    //       pinv - Moore-Penrose pseudoinverse
    // if pre-whitening data and residuals, compute
    // se = sqrt (mrss * (C*pinv(WX'*WX)*C') )
    // -----
    // SOMETHING TO DEBUG AND TEST:
    // worsley looks to compute se= sqrt(mrss*(C * pinv(WX) * AVA' * (pinv(WX))' * C'))
    // where AVA' is proportional to or equal to I, giving
    // se= sqrt (  mrss * (C * pinv(WX)  * (pinv(WX))' * C' )  )
    // which seems different from sqrt (  mrss * ( C * pinv(WX'*WX) * C' ) )
    // Try both of these and see if they make a difference...
    // Well golly, they seem to give the same result.
    // -----

    // calculate mrss
    int rows = this->DesignMatrix->GetNumberOfTuples();
    int cols = this->DesignMatrix->GetNumberOfComponents();
    int df = rows-cols;
    float mrss  = rss / df;

    int i, j;
    float v1, v0, v;
    
    // format the design matrix for vnl 
    float norm = (float) (sqrt ( (double) (1.0- (corrCoeff*corrCoeff))));
    for (j=0; j<cols; j++) {
        if ( this->PreWhitening == 0 ) {
            ((vnl_matrix<float> *)this->X)->put(0, j, this->DesignMatrix->GetComponent(0,j));
        } else {
        // format the design matrix and pre-whiten at this voxel
            ((vnl_matrix<float> *)this->WX)->put(0, j, this->DesignMatrix->GetComponent(0,j));
            for (i=1; i<rows; i++) {
                v1 = this->DesignMatrix->GetComponent (i,j);
                v0 = this->DesignMatrix->GetComponent(i-1,j);
                v =  (v1 - (corrCoeff*v0)) / norm;
                ((vnl_matrix<float> *)this->WX)->put(i, j, v);
            }
        }
    }

    // calculate pinv(WX'*WX) if whitening
    // or calculate pinv(X'*X) if not whitening.
    // (commented out for testing)
    // ------------------------------------------------------
    vnl_matrix<float> A;
    if ( this->PreWhitening == 0 ) {
        A = *((vnl_matrix<float> *)this->X);
    } else {
        A = *((vnl_matrix<float> *)this->WX);
    }
    vnl_matrix<float> B;
    vnl_matrix<float> Binv;

    B = A.transpose() * A;
    vnl_matrix_inverse<float> Pinv(B);
    Binv = Pinv.pinverse(cols);

    // calculate C*pinv(WX'*WX)*C' 
    // or calculate C*pinv(X'*X)*C' if not whitening.
    // ------------------------------------------------------
    vnl_matrix<float> D = *((vnl_matrix<float> *)this->C);
    vnl_matrix<float> E = D * Binv * D.transpose();
    v = E.get(0, 0);

    // standard error: se = sqrt(mrss*(C*pinv(X'*X)*C'))
    // ------------------------------------------------------
    this->StandardError = (float)sqrt(fabs(mrss * v));


    // TEST: se= sqrt (  mrss * (C * pinv(WX)  * (pinv(WX))' * C' )  )
    // This computation of the se is as recommended in:
    // Worsley, K.J., Liao, C., Aston, J., Petre, V., Duncan, G.H., Morales, F., Evans, A.C.
    // (2002). A general statistical analysis for fMRI data. NeuroImage, 15:1:15.
    // NOTE:
    // This implementation computes the degrees of freedom
    // as rows-cols, which will be correct if all rows and cols of the
    // design matrix are linearly independent. If the design is not
    // orthogonal, however, the dof will be overestimated here.
    // The correct computation of dof would be to compute Rank(X)
    // or Rank(WX), if pre-whitening is used. This takes longer!
    //vnl_matrix<float> Ainv;
    //vnl_matrix_inverse<float> WXinv(A);
    //Ainv = WXinv.pinverse(cols);    
    //B = D * Ainv * Ainv.transpose() * D.transpose();
    //v = B.get(0,0);
    //this->StandardError = (float)sqrt(fabs(mrss * v));
    // This implementation appears to give the same result as the one above.
    
}


void vtkGLMVolumeGenerator::SimpleExecute(vtkImageData *input, vtkImageData* output)
{

    // This brain activation detection is implemented as recommended in:
    // Worsley, K.J., Liao, C., Aston, J., Petre, V., Duncan, G.H., Morales, F., Evans, A.C.
    // (2002). A general statistical analysis for fMRI data. NeuroImage, 15:1:15.
    // Here, we assume to use a fully efficient estimator (the residuals and data have been
    // prewhitened so that the matrix AVA is proportional or equal to the Identity matrix,
    // and the degrees of freedom are (timepoints - residuals). If the design is overspecified,
    // then these assumptions may not be correct.

    if (input == NULL)
    {
        vtkErrorMacro( << "No input image data in this filter.");
        return;
    }

    // for progress update (bar)
    unsigned long count = 0;
    unsigned long target;
    float corrCoeff;

    // Sets up properties for output vtkImageData
    int imgDim[3];  
    input->GetDimensions(imgDim);
    output->SetScalarType(VTK_FLOAT);
    output->SetOrigin(input->GetOrigin());
    output->SetSpacing(input->GetSpacing());
    output->SetNumberOfScalarComponents(1);
    output->SetDimensions(imgDim[0], imgDim[1], imgDim[2]);
    output->AllocateScalars();
  
    target = (unsigned long)(imgDim[0]*imgDim[1]*imgDim[2] / 50.0);
    target++;

    int indx = 0;
    vtkDataArray *scalarsOutput = output->GetPointData()->GetScalars();
    vtkDataArray *scalarsInput = input->GetPointData()->GetScalars();

    // Voxel iteration through the entire image volume
    for (int kk = 0; kk < imgDim[2]; kk++)
    {
        for (int jj = 0; jj < imgDim[1]; jj++)
        {
            for (int ii = 0; ii < imgDim[0]; ii++)
            {
                // computes: multiplies contrast vector by beta vector.
                float contrastedBeta = 0.0;
                float rss = 0.0; // = chisq
                int yy = 0;
                // there are as many betas (regression weights) as contrast vector elements.
                for (int d = 0; d < this->SizeOfContrastVector; d++) {
                    this->beta[d] = scalarsInput->GetComponent(indx, yy++);
                    contrastedBeta = contrastedBeta +
                        ( this->beta[d] * ((int)this->ContrastVector->GetComponent(d, 0)) );
                }
                rss = scalarsInput->GetComponent(indx, yy++);
                corrCoeff = scalarsInput->GetComponent(indx, yy);
                ComputeStandardError(rss, corrCoeff);

                // t statistic 
                // t= C*B/SE;
                // where B - beta matrix after linear modeling
                //     C - contrast vector
                //     SE - standard error
                //     t - test statistic
                float t = 0.0; 
                if (this->StandardError != 0.0)
                {
                    t = contrastedBeta / this->StandardError; 
                }

                scalarsOutput->SetComponent(indx++, 0, t);

                if (!(count%target))
                {
                    UpdateProgress(count / (50.0*target));
                }
                count++;
            }
        } 
    }

    delete [] this->beta;

    // Scales the scalar values in the activation volume between 0 - 100
    vtkFloatingPointType range[2];
    output->GetScalarRange(range);
    this->LowRange = range[0];
    this->HighRange = range[1];
}


