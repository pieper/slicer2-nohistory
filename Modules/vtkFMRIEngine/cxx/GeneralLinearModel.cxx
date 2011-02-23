/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: GeneralLinearModel.cxx,v $
  Date:      $Date: 2006/01/13 16:45:54 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/


#include "GeneralLinearModel.h"
#include "vnl/vnl_matrix.h" 
#include "vnl/algo/vnl_matrix_inverse.h" 
#include "vnl/vnl_vector.h" 

int *GeneralLinearModel::Dimensions = NULL;
float **GeneralLinearModel::DesignMatrix = NULL;
float **GeneralLinearModel::AR1DesignMatrix = NULL;
int *GeneralLinearModel::whitening = NULL;

int GeneralLinearModel::FitModel(float *timeCourse, float *beta, float *chisq)
{
    int i, j;
    
    if ( AR1DesignMatrix == NULL && *whitening == 1 ) {
        cout << "AR(1) Design matrix has not been set.\n";
        return 1;
    }
    
    if (DesignMatrix == NULL || Dimensions == NULL) 
    {
        cout << "Design matrix has not been set.\n";
        return 1;
    }

    // set y vector by the timeCourse array
    vnl_vector<float> y;
    y.set_size(Dimensions[0]);
    y.copy_in(timeCourse);

    // set X, which is a vnl_matrix object
    // X holds design matrix
    vnl_matrix<float> X;
    X.set_size(Dimensions[0], Dimensions[1]);
    if ( *whitening  ) {
        for (i = 0; i < Dimensions[0]; i++) {
            for(j = 0; j < Dimensions[1]; j++) {
                X.put(i, j, AR1DesignMatrix[i][j]);
            }
        }
    } else {
        for (i = 0; i < Dimensions[0]; i++) {
            for(j = 0; j < Dimensions[1]; j++) {
                X.put(i, j, DesignMatrix[i][j]);
            }
        }
    }

    // beta = (X'X)^-1 X' y
    // beta is an array of estimated coefficients from the linear best-fit
    vnl_matrix<float> tmp = X.transpose() * X;
    vnl_matrix_inverse<float> inv(tmp);

    tmp = inv * X.transpose();
    vnl_vector<float> c = y;
    c.pre_multiply(tmp);
    for(j = 0; j < Dimensions[1]; j++)
    {
        beta[j] = c.get(j);
    }

    // compute chisq
    *chisq = ComputeResiduals(beta, timeCourse, Dimensions[0], Dimensions[1]);

    return 0;
}



float GeneralLinearModel::ComputeResiduals(float *beta, float *timeCourse, int numSamples, int numRegressors)
{
    // This method computes chisq when the parameter estimate
    // beta is used to fit observed data Y to the linear model
    // Y = Xbeta + e
    // The residuals are found by subtracting the model from the data:
    // e = Y-Xbeta.
    // The observed data Y is given by a float array 
    //
    // ALSO: modify this routine to take a design matrix as parameter.
    // THAT WAY, we can use with prewhitened design matrix too.

    int i, j;
    double zz;
    float e, chisq = 0.0;

    // compute residuals: e = Y-X*beta.
    for ( i = 0; i < numSamples; i++ ) 
    {
        // first compute X*beta:
        
        if ( *whitening ) {
            for (zz = 0.0, j = 0; j < numRegressors; j++) {
                zz = zz + (double)(AR1DesignMatrix[i][j] * beta[j]);
            }
        } else {
        for (zz = 0.0, j = 0; j < numRegressors; j++) {
                zz = zz + (double)(DesignMatrix[i][j] * beta[j]);
            }
        }
        // now compute e= Y-X*beta:
        e = timeCourse[i] - (float)zz;

        // and compute chisq 
        chisq += (e * e);
    }

    return chisq;
}




int GeneralLinearModel::SetDesignMatrix(vtkFloatArray *designMat)
{
    int noOfRegressors = designMat->GetNumberOfComponents();

    if (Dimensions == NULL)
    {
        Dimensions = new int[2];
        if (Dimensions == NULL) 
        {
            cout << "Memory allocation failed for Dimensions in class GeneralLinearModel.\n";
            return 1;
        }
    }  

    // Number of volumes
    Dimensions[0] = designMat->GetNumberOfTuples();
    // Number of evs (predictors)
    Dimensions[1] = noOfRegressors;

    if (DesignMatrix == NULL)
    {
        DesignMatrix = new float *[Dimensions[0]];
        if (DesignMatrix == NULL) 
        {
            cout << "Memory allocation failed for DesignMatrix in class GeneralLinearModel.\n";
            return 1;
        }

        for (int i = 0; i < Dimensions[0]; i++)
        {
            DesignMatrix[i] = new float[Dimensions[1]];
            for (int j = 0; j < Dimensions[1]; j++)
            {
                DesignMatrix[i][j] = designMat->GetComponent(i,j);
            }
        } 
    }

    return 0;
}


int GeneralLinearModel::SetAR1DesignMatrix(vtkFloatArray *designMat)
{
    // number of regressor columns
    int noOfRegressors = designMat->GetNumberOfComponents();
    // number of volumes: this is not getting set properly.
    int noOfSamples = designMat->GetNumberOfTuples ( );
    
    // allocate once per model-fitting, but reuse for each voxel.
    if (AR1DesignMatrix == NULL)
    {
        AR1DesignMatrix = new float *[noOfSamples];

        if (AR1DesignMatrix == NULL) 
        {
            cout << "Memory allocation failed for AR1DesignMatrix in class GeneralLinearModel.\n";
            return 1;
        }
        for (int i = 0; i < noOfSamples; i++)
            {
                AR1DesignMatrix[i] = new float [noOfRegressors];
            }
    }

    for (int i = 0; i < noOfSamples; i++)
        {
            for (int j = 0; j < noOfRegressors; j++)
            {
                AR1DesignMatrix[i][j] = designMat->GetComponent(i,j);
            }
        } 
    return 0;
}




int GeneralLinearModel::SetWhitening (int status)
{
    if (whitening == NULL)
        whitening = new int;
    
    if ( status != 1 && status != 0 ) {
        cout << "Improper value for pre-whitening flag.\n";
        return 1;
    } else {
        *whitening = status;
    }
    return 0;
}



void GeneralLinearModel::Free()
{

    if (DesignMatrix != NULL)
        {
            for (int i = 0; i < Dimensions[0]; i++)
                {
                    delete [] DesignMatrix[i];
                } 
            delete [] DesignMatrix;
            DesignMatrix = NULL;
        
        }

    if (AR1DesignMatrix != NULL)
        {
            for (int i = 0; i < Dimensions[0]; i++)
                {
                    delete [] AR1DesignMatrix[i];
                } 
            delete [] AR1DesignMatrix;
            AR1DesignMatrix = NULL;
        }
    
    if (Dimensions != NULL)
        {
            delete [] Dimensions;
            Dimensions = NULL;
        }
}


