/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: PrincipalCurvatures.cxx,v $
  Date:      $Date: 2006/01/13 16:49:40 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
/*  ==================================================
    Module: vtkFluxDiffusion
    Author: Karl Krissian
    Email:  karl@bwh.harvard.edu

    This module implements a version of anisotropic diffusion published in 
    
    "Flux-Based Anisotropic Diffusion Applied to Enhancement of 3D Angiographiam"
    Karl Krissian
    IEEE Trans. Medical Imaging, 21(11), pp 1440-1442, nov 2002.
    
    It aims at restoring 2D and 3D images with the ability to preserve
    small and elongated structures.
    It comes with a Tcl/Tk interface for the '3D Slicer'.
    ==================================================
    Copyright (C) 2002  Karl Krissian

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    ================================================== 
    The full GNU Lesser General Public License file is in vtkFluxDiffusion/LesserGPL_license.txt
*/

//
//  Code by Prof. Luis Alvarez Leon
//  University of Las Palmas of Gran Canaria
//

#include <stdio.h>
#include <math.h>
#define ABS(x) ((x)>0?(x):-(x))

namespace FluxDiffusion {

/********************************************************************/
/*** CALCULO DEL autovector0 DE AUTOVALOR 0 de UNA MATRIZ 2x2   ******/
/********************************************************************/
int autovector0(double a,double b,double c, float paso[3])
     //double a,b,c;
     //float paso[3];
{
  double p;
  paso[0]=0;
  if(ABS(a)>ABS(c)){
      paso[1]=b;
      paso[2]=-a; 
  }
  else{ /* ABS(a)<ABS(c) */
      paso[1]=c;
      paso[2]=-b; 
  }
  p=paso[1]*paso[1]+paso[2]*paso[2];
  if(p<=0) return(-1);
  p=sqrt(p);
  paso[1]/=p;
  paso[2]/=p;
  return(0);

}





/********************************************************************/
/**  PROGRAMA QUE CALCULA LAS DIRECCIONES NORMALIZADAS Y CURVATURAS */
/******* PRINCIPALES DE UNA SUPERFICIE. DEVUELVE 0 SI TERMINA BIEN **/
/********************************************************************/

int CurvaturasPrincipales(float H[3][3],
              float p[3],
              float vmax[3],
              float vmin[3],
              float *lmax,
              float *lmin,
              float umbral)
     //float H[3][3];  /* MATRIZ HESSIANA  */
     //float p[3];     /* VECTOR GRADIENTE */
     //float vmax[3],vmin[3];  /* VECTORES SALIDA CON LAS DIRECCIONES DE MAX y MIN VAR.*/
     //float *lmax,*lmin;  /* CURVATURAS PRINCIPALES */
     //float umbral;       /* UMBRAL MINIMO DE LA NORMA CUADRADO DEL GRADIENTE PARA HACER EL CALCULO */
{
  float P[3][3],A[3][3],p1[3],p2[3],p3[3],paso[3];
  double a,b,c,d,e,p2norm;
  int i,j,k,k1,k2;
  double pnorm=p[0]*p[0]+p[1]*p[1]+p[2]*p[2];

  /* SALGO CON -1 SI LA NORMA DEL GRADIENTE ES MENOR QUE UMBRAL */
  if(pnorm<=umbral)  
    return(-1);

  /* NORMALIZO EL VECTOR GRADIENTE Y LO GUARDO EN p1[3]*/
  pnorm=sqrt((double) pnorm);
  for(i=0;i<3;i++)
    p1[i]=p[i]/pnorm;


 /* CALCULO CALCULO A=(Id-pxp/p^2)H(Id-pxp/p^2) (VERSION OPTIMIZADA)*/
  
  for(i=0;i<3;i++){
    paso[i]=H[i][0]*p1[0];
    for(j=1;j<3;j++)
    paso[i]+=H[i][j]*p1[j];
  }
  a=paso[0]*p1[0]+paso[1]*p1[1]+paso[2]*p1[2];

  for(i=0;i<3;i++)
    for(j=i;j<3;j++)
      A[i][j]=H[i][j]-paso[i]*p1[j]+(a*p1[j]-paso[j])*p1[i]; 

  for(i=0;i<3;i++)
    for(j=0;j<i;j++)
      A[i][j]=A[j][i];


  /* CALCULO 2 VECTORES ORTONORMALES A p1[3] (VERSION OPTIMIZADA) */
  k=0;
  for(i=1;i<3;i++)
    if(ABS(p1[i])>ABS(p1[k]))
      k=i;
  k1=(k+1)%3;
  k2=(k+2)%3;
  p2[k1]=p1[k];
  p2[k]=-p1[k1];
  p2[k2]=0;
  p2norm=p2[k]*p2[k]+p2[k1]*p2[k1];
  p2norm=sqrt(p2norm);
  p2[k]/=p2norm; 
  p2[k1]/=p2norm;  

  p3[k]=-p1[k2]*p2[k1];
  p3[k1]=p1[k2]*p2[k];
  p3[k2]=p1[k]*p2[k1]-p1[k1]*p2[k];


  /* CONSTRUYO LA MATRIZ DE ROTACION P[3][3] COMPUESTA POR p1[3],p2[3] y p3[3] */ 
  for(i=0;i<3;i++){
    P[i][0]=p1[i];
    P[i][1]=p2[i];
    P[i][2]=p3[i];
  }

  /* CALCULO LA MATRIZ SIMETRICA 2x2 DADA POR a=p2^T*A*p2, b=p2^T*A*p3, c=p3^T*A*p3 */
  for(i=0;i<3;i++)
    paso[i]=A[i][0]*p2[0]+A[i][1]*p2[1]+A[i][2]*p2[2];
  a=paso[0]*p2[0]+paso[1]*p2[1]+paso[2]*p2[2]; 
  for(i=0;i<3;i++)
    paso[i]=A[i][0]*p3[0]+A[i][1]*p3[1]+A[i][2]*p3[2];
  b=paso[0]*p2[0]+paso[1]*p2[1]+paso[2]*p2[2]; 
  c=paso[0]*p3[0]+paso[1]*p3[1]+paso[2]*p3[2]; 

 

  /* CALCULO LOS AUTOVECTORES Y AUTOVALORES DE LA MATRIZ ANTERIOR,         */
  /*  Y LOS GUARDO EN LAS POSICIONES 1 y 2 DEL VECTOR paso[3],             */
  /*  LA POSICION paso[0]=0. HAY UN CASO ESPECIAL CUANDO LOS DOS AUTOVALORES     */
  /*  SON IGUALES, EN CUYO CASO LA FUNCION autovalor0 DEVUELVE -1        */
  d=sqrt((c-a)*(c-a)+4*b*b);
  e=c+a;
  if(e>0){
    *lmax=0.5*(e+d);
    if( autovector0((a-*lmax),b,(c-*lmax),paso)==-1){  
      paso[0]=0;
      paso[1]=1;
      paso[2]=0;
    } 
    for(i=0;i<3;i++)
      vmax[i]=0;
    for(i=0;i<3;i++)
      for(j=0;j<3;j++)
        vmax[i]+=P[i][j]*paso[j];
    *lmin=0.5*(e-d);
    if( autovector0((a-*lmin),b,(c-*lmin),paso)==-1){  
      paso[0]=0;
      paso[1]=0;
      paso[2]=1;
    }
    for(i=0;i<3;i++)
      vmin[i]=0;
    for(i=0;i<3;i++)
      for(j=0;j<3;j++)
        vmin[i]+=P[i][j]*paso[j];
  }
  else{
    *lmin=0.5*(e+d);
    if( autovector0((a-*lmin),b,(c-*lmin),paso)==-1){  
      paso[0]=0;
      paso[1]=0;
      paso[2]=1;
    }
    for(i=0;i<3;i++)
      vmin[i]=0;
    for(i=0;i<3;i++)
      for(j=0;j<3;j++)
        vmin[i]+=P[i][j]*paso[j];
    *lmax=0.5*(e-d);
    if( autovector0((a-*lmax),b,(c-*lmax),paso)==-1){  
      paso[0]=0;
      paso[1]=1;
      paso[2]=0;
    }
    for(i=0;i<3;i++)
      vmax[i]=0;
    for(i=0;i<3;i++)
      for(j=0;j<3;j++)
        vmax[i]+=P[i][j]*paso[j];
  }

  /* NORMALIZO LOS AUTOVALORES PARA OBTENER LAS CURVATURAS PRINCIPALES */
  *lmax/=-pnorm;
  *lmin/=-pnorm;

  //  printf("vmin %f %f %f \n", vmin[0], vmin[1], vmin[2]);
 
  return(0);

}




/********************************************************************/
/**  PROGRAMA QUE CALCULA LAS CURVATURAS */
/******* PRINCIPALES DE UNA SUPERFICIE. DEVUELVE 0 SI TERMINA BIEN **/
/********************************************************************/

int CurvaturasPrincipales(float H[3][3],
              float p[3],
              float *lmax,
              float *lmin,
              float umbral)
     //float H[3][3];  /* MATRIZ HESSIANA  */
     //float p[3];     /* VECTOR GRADIENTE */
     //float *lmax,*lmin;  /* CURVATURAS PRINCIPALES */
     //float umbral;       /* UMBRAL MINIMO DE LA NORMA CUADRADO DEL GRADIENTE PARA HACER EL CALCULO */
{
  float P[3][3],A[3][3],p1[3],p2[3],p3[3],paso[3];
  double a,b,c,d,e,p2norm;
  int i,j,k,k1,k2;
  double pnorm=p[0]*p[0]+p[1]*p[1]+p[2]*p[2];

  /* SALGO CON -1 SI LA NORMA DEL GRADIENTE ES MENOR QUE UMBRAL */
  if(pnorm<=umbral)  
    return(-1);

  /* NORMALIZO EL VECTOR GRADIENTE Y LO GUARDO EN p1[3]*/
  pnorm=sqrt((double) pnorm);
  for(i=0;i<3;i++)
    p1[i]=p[i]/pnorm;


 /* CALCULO CALCULO A=(Id-pxp/p^2)H(Id-pxp/p^2) (VERSION OPTIMIZADA)*/
  
  for(i=0;i<3;i++){
    paso[i]=H[i][0]*p1[0];
    for(j=1;j<3;j++)
    paso[i]+=H[i][j]*p1[j];
  }
  a=paso[0]*p1[0]+paso[1]*p1[1]+paso[2]*p1[2];

  for(i=0;i<3;i++)
    for(j=i;j<3;j++)
      A[i][j]=H[i][j]-paso[i]*p1[j]+(a*p1[j]-paso[j])*p1[i]; 

  for(i=0;i<3;i++)
    for(j=0;j<i;j++)
      A[i][j]=A[j][i];


  /* CALCULO 2 VECTORES ORTONORMALES A p1[3] (VERSION OPTIMIZADA) */
  k=0;
  for(i=1;i<3;i++)
    if(ABS(p1[i])>ABS(p1[k]))
      k=i;
  k1=(k+1)%3;
  k2=(k+2)%3;
  p2[k1]=p1[k];
  p2[k]=-p1[k1];
  p2[k2]=0;
  p2norm=p2[k]*p2[k]+p2[k1]*p2[k1];
  p2norm=sqrt(p2norm);
  p2[k]/=p2norm; 
  p2[k1]/=p2norm;  

  p3[k]=-p1[k2]*p2[k1];
  p3[k1]=p1[k2]*p2[k];
  p3[k2]=p1[k]*p2[k1]-p1[k1]*p2[k];


  /* CONSTRUYO LA MATRIZ DE ROTACION P[3][3] COMPUESTA POR p1[3],p2[3] y p3[3] */ 
  for(i=0;i<3;i++){
    P[i][0]=p1[i];
    P[i][1]=p2[i];
    P[i][2]=p3[i];
  }

  /* CALCULO LA MATRIZ SIMETRICA 2x2 DADA POR a=p2^T*A*p2, b=p2^T*A*p3, c=p3^T*A*p3 */
  for(i=0;i<3;i++)
    paso[i]=A[i][0]*p2[0]+A[i][1]*p2[1]+A[i][2]*p2[2];
  a=paso[0]*p2[0]+paso[1]*p2[1]+paso[2]*p2[2]; 
  for(i=0;i<3;i++)
    paso[i]=A[i][0]*p3[0]+A[i][1]*p3[1]+A[i][2]*p3[2];
  b=paso[0]*p2[0]+paso[1]*p2[1]+paso[2]*p2[2]; 
  c=paso[0]*p3[0]+paso[1]*p3[1]+paso[2]*p3[2]; 

 

  /* CALCULO LOS AUTOVECTORES Y AUTOVALORES DE LA MATRIZ ANTERIOR,         */
  /*  Y LOS GUARDO EN LAS POSICIONES 1 y 2 DEL VECTOR paso[3],             */
  /*  LA POSICION paso[0]=0. HAY UN CASO ESPECIAL CUANDO LOS DOS AUTOVALORES     */
  /*  SON IGUALES, EN CUYO CASO LA FUNCION autovalor0 DEVUELVE -1        */
  d=sqrt((c-a)*(c-a)+4*b*b);
  e=c+a;
  if(e>0){
    *lmax=0.5*(e+d);
    *lmin=0.5*(e-d);
  }
  else{
    *lmin=0.5*(e+d);
    *lmax=0.5*(e-d);
  }

  /* NORMALIZO LOS AUTOVALORES PARA OBTENER LAS CURVATURAS PRINCIPALES */
  *lmax/=-pnorm;
  *lmin/=-pnorm;

  return(1);

}

}
