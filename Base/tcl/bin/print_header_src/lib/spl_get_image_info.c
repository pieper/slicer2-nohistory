
/*
 * ++
 * 
 * Module:      spl_get_image_info.c
 * 
 * Version:     1
 * 
 * Facility:    I/O routine
 * 
 * Abstract:    These routines provide i/o support SPL images
 * input files.
 * 
 * Currently supports: 1 signa    - signa files with headers 
                       2 genesis  - genesis files with headers 
                       3 siemens  - siemens files with headers 
                       4 noh2dvax - 2d * files, noheaders, 
                       5 spect    - spect "brick"
                       6 dicom    - dicom files, any modality
 * 
 * 
 * Environment: Sun Unix
 * 
 * Author[s]: M. C. Anderson, S. Warfield, M. Halle, S. Davis
 * 
 * Modified by: , : version
 * 
 * 
 */

/*
 * Include files:
 */

#include <stdio.h>
#include <math.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/param.h>
#include <unistd.h>
#ifdef  GNU
#include <string.h>
#else
#include <string.h>
#endif
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <assert.h>
#include <errno.h>
#include "image_info_private.h"
#include "offsets.h"
#include "datadict.h"


#include "signa_header.h"
#include "genesis_hdr_def.h"
#include "genesis_pixeldata.h"
#include "imageFileOffsets.h"
#include "spect.h"
#include <time.h>
struct tm *tmptr,*localtime();
long  my_clock;
long  folly;

extern double   pow();


static char *(find_data_element_in_header ());

/*
 * Macros:
 */

#define MISSING_MAX 5
#define MAXNAMLEN 255
#define SAGGITAL 1 
#define AXIAL 2 
#define CORONAL 3 
/*
 * Typedefs
 */

typedef void ImageInfo;


typedef struct {
  unsigned        sign:1;
  unsigned        exponent:7;
  unsigned        mantissa:24;
}               DG_FLOAT;

/*
 * Own storage:
 */

#ifndef lint
static char    *sccs_id = "@(#)spl_get_image_info.c 6.18";
#endif

int             npixels;

/*
 * signa-specific variables
 */
IMAGE          *image;
SERIES         *series;
STUDY          *study;
char            line[MAXPATHLEN];
float           my_dg_to_sun();
/*
 * genesis-specific variables
 */
int             variable_header_count;
int             exam_offset;
int             series_offset;
int             image_offset;
int             num_elements;
unsigned short  ushortval;
char exam_type[3]; /* needed for coordinate system info */
int se_entry;
int se_position;


/*
 * siemens-specific variables
 */

float           f_correct();
float           floatval, floatval2, floatval3,floatval4,floatval5,floatval6;
float           cross_product1, cross_product2,cross_product3;
float           zoom_factor;
int             intval;
char            junk[MAXPATHLEN];

/*
 * SPECT-specific variables
 */
SPECT_HEADER    *s_header;
/*
 * DICOM-specific variables
 */
   static unsigned short groups[100];
   static unsigned short elements[100];
   int             dd_index;
   char            *out_string;
   int             current_group, current_element;
   int             shortval;
   char            current_vr[3];
   char            current_desc[MAXPATHLEN];
   char            buf[MAXPATHLEN];
   char            pat_age[2];
   static unsigned short length;

/*
 * general-purpose variables
 */
int i;
char ctmp[2];
char *token;
char *dot;
char *zero;
int is_compressed = 0;
unsigned short convertShortFromGE();
unsigned char *findUncompressedSizeOfCompressedFile();
int first,last;
int acquisition;
ImageInfo *spl_get_image_info(char *filename)
{
  ImageInfo_private *p;
  int             swap;
  double          res;
  FILE           *fp = NULL;
  char           *newfname = NULL;
  unsigned char  *tmpdata = NULL;
  int             readCompressed = 0;
  long            fsize = -1;

  p = (ImageInfo_private *)malloc(sizeof(ImageInfo_private));
/*
init some stuff to make spl_read_image happy
*/
  p->header = NULL;
  p->image = NULL;
  p->header_size = 0;
 
  readCompressed = 0;
  readCompressed = fileIsCompressed(filename, &newfname);
  if (readCompressed == 1) {
    tmpdata = findUncompressedSizeOfCompressedFile(newfname, &fsize);
    assert(tmpdata != NULL);
    free(newfname);
    p->header_size  = headerSize(fsize);
    is_compressed = 1;
  } else {
    /* open the file */
    fp = fopen(filename, "rb");
    if (fp == NULL) {
      fprintf(stderr, "Failed to open file \"%s\"\n", filename);
      perror("spl_get_image_info");
      return ((void *) NULL);
    }
    fsize = fileSize(filename);
    if (fsize == -1) {
      return ((void *) NULL);
    }
    p->header_size = headerSize(fsize);
    if (p->header_size == -1) {
      return ((void *) NULL);
    }
  }
/*
now get header
*/
  if(p->header != NULL){
    free(p->header);
  }
  p->header = malloc(p->header_size * sizeof(unsigned char) );
  if (readCompressed == 1) {
    for (i = 0; i < p->header_size; i++) {
      p->header[i] = tmpdata[i];
    }
    free(tmpdata);
  } else {
    /* Read the header */
    if (fread(p->header, sizeof(unsigned char), p->header_size, fp) < p->header_size) {
      fprintf(stderr, "Failed reading the header\n");
      fclose(fp);
      return ((void *) NULL);
    }
    fclose(fp);
  }  
 
 
  npixels = (fsize - p->header_size) / (sizeof(unsigned short));
 
  if (npixels == -1) {
    fprintf(stderr, "can't read %s\n", filename);
    free(p->image);
    free(p->header);
    p->status = -1;
    return(p);
  }


  /*
   * set resolution based on npixels - this value will be ovewritten
   * later in cases where the image is not square 
   */
  res = (double) (npixels);
  res = sqrt(res);
  p->swap = 1; /* default */
  p->cols = p->rows = res;
    if (is_compressed){
      p->compressed=1;
/*
file is known to be compressed, but the input filename may not 
contain the correct suffix - 
*/
      if (access (filename, R_OK) == 0){ 
/* filename already has correct suffix */

        dot = strrchr(filename, '.');
        if (strcmp(dot,".gz") == 0){
          strcpy(p->suffix,".gz");
        }
        else if( strcmp(dot,".Z") == 0){
          strcpy(p->suffix,".Z");
        }
      }
      else {
/*
filename is compressed, but we were given the filename
without the correct suffix
*/
          sprintf(line,"%s.gz",filename);
          if (access (line, R_OK) == 0){ 
              strcpy(p->suffix,".gz");
          }
          else{
              sprintf(line,"%s.Z",filename);
              if (access (line, R_OK) == 0){ 
                  strcpy(p->suffix,".Z");
              }
              else{
                  fprintf(stderr,"unknown suffix for file \n%s\n",filename);
              }
          }
      }
    }
    else{
        p->compressed=0;
        strcpy(p->suffix,"<none>");
    }
/*
set a few defaults here which will be overwritten later
*/
      strcpy(p->patient_orientation,"N/A");
      strcpy(p->patient_position,"N/A ");
      strcpy(p->image_type,"N/A");
      strcpy(p->sop_instance_uid,"N/A");
      strcpy(p->image_time,"N/A");
      strcpy(p->manufacturer,"N/A");
      strcpy(p->referring_physician,"N/A");
      strcpy(p->physician_reading_study,"N/A");
      strcpy(p->manufacturers_model_name,"N/A");
      strcpy(p->anatomic_structure,"N/A");
      strcpy(p->birth_date,"N/A");
      strcpy(p->birth_weight,"N/A");
      strcpy(p->weight,"N/A");
      strcpy(p->body_part_examined,"N/A");
      strcpy(p->repetition_time,"N/A");
      strcpy(p->echo_time,"N/A");
      strcpy(p->inversion_time,"N/A");
      strcpy(p->reconstruction_diameter,"N/A");
      strcpy(p->generator_power,"N/A");
      strcpy(p->series_in_study,"N/A");
      strcpy(p->images_in_acquisition,"N/A");
      p->bits_stored = -1;
      p->high_bit = -1;
      strcpy(p->rescale_intercept,"N/A");
      strcpy(p->rescale_slope,"N/A");
      strcpy(p->requested_proc_desc,"N/A");
      p->bits_allocated = -1;

      p->gantry_tilt = 0.0;

      p->coord_center_r = 1;
      p->coord_center_a = 0;
      p->coord_center_s = 0;

      p->coord_normal_r = 0;
      p->coord_normal_a = 1;
      p->coord_normal_s = 0;

      p->coord_r_top_left = 0;
      p->coord_a_top_left = 0;
      p->coord_s_top_left = 1;

      p->coord_r_top_right = 0;
      p->coord_a_top_right = 0;
      p->coord_s_top_right = 0;

      p->coord_r_bottom_right = 1;
      p->coord_a_bottom_right = 0;
      p->coord_s_bottom_right = 0;


  switch (p->header_size) {

  case 14336:  /* signa */

    p->byte_order = 0;
    p->bytes_per_pixel = 2;
    p->bytes_per_slice = p->bytes_per_pixel * p->cols * p->rows;
    /*
     * get some memory for temporary structs to hold the different parts of
     * the header
     */
    study = (STUDY *) malloc(sizeof(STUDY));
    if (study == NULL) {
      perror("spl_get_image_info");
      free(p->image);
      return(p);
    }
    series = (SERIES *) malloc(sizeof(SERIES));
    if (series == NULL) {
      perror("spl_get_image_info");
      free(p->image);
      return(p);
    }
    image = (IMAGE *) malloc(sizeof(IMAGE));
    if (image == NULL) {
      perror("spl_get_image_info");
      free(p->image);
      return(p);
    }
    memcpy(study, &p->header[STHDR_START * 2], sizeof(STUDY));
    memcpy(series, &p->header[SEHDR_START * 2], sizeof(SERIES));
    memcpy(image, &p->header[IHDR_START * 2], sizeof(IMAGE));

    memcpy(p->patname, study->sthdr_pnm, 32);
 
      sprintf(p->date,"%d/%d/%d",(int)study->sthdr_idate[1],(int)study->sthdr_idate[0],(int)study->sthdr_idate[2]);
/*
    memcpy(p->date, study->sthdr_date, 9);
*/
    memcpy(p->study_desc, study->sthdr_desc, 60);
    memcpy(p->series_desc, series->sehdr_desc, 120);
    memcpy(p->hospital_name, study->sthdr_hosp, 32);
    memcpy(p->patient_id, study->sthdr_pid, 12);
    sscanf(study->sthdr_stnum,"%d\n",&folly);
    p->exam_number = (short)folly;
    sscanf(study->sthdr_age,"%d\n",&folly);
    p->patient_age = (short)folly;
    sscanf(series->sehdr_sernum,"%d\n",&folly);
    p->series_number = folly;
    if(strcmp(study->sthdr_sex,"M") == 0)
/*
it's a boy!!
*/
      strcpy(p->patient_sex,"M");
    else
/*
it's a girl!!
*/
      strcpy(p->patient_sex,"F");
    strcpy(p->exam_modality, "MR");
/*
    p->patient_position = series->sehdr_pos;
*/
    p->pixel_xsize = my_dg_to_sun(&image->ihdr_pixsiz);
    p->image_location = my_dg_to_sun(&image->ihdr_locatn);
    p->pixel_ysize = my_dg_to_sun(&image->ihdr_pixsiz);
    p->thick = my_dg_to_sun(&image->ihdr_thick);
    p->space = my_dg_to_sun(&image->ihdr_space);
/*
get image number from actual file name, not header
*/
    if ((token = (char *) strrchr (filename, '/')) != NULL) {
       if ((dot = (char *) strchr (token, '.')) != NULL) {
                sscanf (dot, ".%03d", &p->slice_number);
        }
       else {
          fprintf(stderr,"cant figure out image number for file %s\n",filename);
          exit(0);
        }
    }
    else {
       dot = (char *) strchr (filename,'.');
       sscanf (dot, ".%03d", &p->slice_number);
    }

    p->fov = p->cols * p->pixel_xsize;
    p->aspect = (p->thick + p->space) / p->pixel_xsize;
    strcpy(p->image_type_text, "sig2d");
    strcpy (p->filename, filename);
    p->image_type_num = 1;
    p->number_echoes = image->ihdr_necho;
    if(p->number_echoes == 0) p->number_echoes = 1;
    p->echo_number = image->ihdr_echon;
    if(p->echo_number == 0) p->echo_number = 1;
    strncpy(p->input_prefix,filename,(strlen(filename)-strlen(dot)));
    p->input_prefix[strlen(filename)-strlen(dot)] =  '\0';
    strcpy(p->file_pattern,"%s.%03d");
    free(study);
    free(series);
    free(image);
    p->status = 1;
    break;
  case 4096: /* SIEMENS CT */
    strcpy(p->exam_modality,"CT");
    p->byte_order = 1;
    p->bytes_per_pixel = 2;
    p->bytes_per_slice = p->bytes_per_pixel * p->cols * p->rows;
/*
swap image bytes - siemens uses "vax" byte order 
    swab(p->image,p->image,p->cols*p->cols*2);
*/
    p->swap = 2; /* little endian */
    p->number_echoes = 1;
    p->echo_number = 1;
    strcpy(p->image_type_text, "siemens");
    strcpy (p->filename, filename);
    floatval = f_correct(&p->header[SYSTEM_INFO_OFFSET + 112]);
    zoom_factor = f_correct(&p->header[RECON_INFO_OFFSET + 52]);
    p->pixel_xsize = floatval / zoom_factor;
    p->fov = p->cols * p->pixel_xsize;
    memcpy(line, &p->header[IMAGE_TEXT_OFFSET + 181], 12);
    sscanf(line, "%s %d", junk, &intval);
    p->thick = (float) intval;
    p->aspect = (p->thick + p->space) / p->pixel_xsize;
    memcpy(p->patname, &p->header[IMAGE_TEXT_OFFSET + 96], 25);
    memcpy(p->hospital_name, &p->header[IMAGE_TEXT_OFFSET + 30], 30);
    memcpy(p->patient_id, &p->header[IMAGE_TEXT_OFFSET + 121], 13);
    
    memcpy(ctmp,&p->header[SIEMENS_PAT_INFO_OFFSET+118],1);
    if(strncmp(ctmp,"F",1) == 0)
      strcpy(p->patient_sex,"F");
    else
      strcpy(p->patient_sex,"M");
    p->exam_number = 1;
    p->series_number = 1;
    memcpy(p->date, &p->header[SCAN_INFO_OFFSET + 28], 23);
    p->image_type_num = 3;
    strcpy(p->file_pattern,"%s%05d.ima");
/*
set some descriptive info from the header
*/
    memcpy(p->study_desc, &p->header[SIEMENS_MEAS_PARAM_OFFSET + 24], 22);
    memcpy(p->series_desc, &p->header[SIEMENS_MEAS_PARAM_OFFSET + 24], 22);
/*
get image number from actual file name, not header
*/
    if ((token = (char *) strrchr (filename, '/')) != NULL) {
       if ((zero = (char *) strchr (token, '0')) != NULL) {
                sscanf (zero, "%05d", &p->slice_number);
        }
        else{
          fprintf(stderr,"cant figure out image number for file %s\n",filename);
          exit(0);
        }
    }
    else{
       zero = (char *) strchr (filename,'0');
       sscanf (zero, "%05d", &p->slice_number);
    }
/*
get non-conventional siemens filenames in order to support more robust 
I/O - i.e. we want to be able to read files like "segment00001.ima"
*/
    strncpy(p->input_prefix,filename,(strlen(filename)-strlen(zero)));
    p->input_prefix[strlen(filename)-strlen(zero)] =  '\0';
    p->status = 1;
    break;


  case 0:  /* no header */
    strcpy(p->exam_modality,"unknown");
    p->byte_order = 1;
    p->bytes_per_pixel = 2;
    p->bytes_per_slice = p->bytes_per_pixel * p->cols * p->rows;
    p->number_echoes = 1;
    p->echo_number = 1;
    strcpy(p->image_type_text, "noh2d");
    strcpy (p->filename, filename);
    p->pixel_xsize = 1.0;
    p->pixel_ysize = 1.0;
    p->fov = p->cols * p->pixel_xsize;
    p->thick = 1.0;
    p->aspect = (p->thick + p->space) / p->pixel_xsize;
    strcpy(p->patname, "unknown");
    p->image_type_num = 4;
    strcpy(p->file_pattern,"%s.%d");
/*
get image number from actual file name, not header
*/
    if ((token = (char *) strrchr (filename, '/')) != NULL) {
       if ((dot = (char *) strchr (token, '.')) != NULL) {
                sscanf (dot, ".%d", &p->slice_number);
        }
        else{
          fprintf(stderr,"cant figure out image number for file %s\n",filename);
          exit(0);
        }
    }
    else{
       dot = (char *) strchr (filename,'.');
       sscanf (dot, ".%d", &p->slice_number);
    }
    strncpy(p->input_prefix,filename,(strlen(filename)-strlen(dot)));
    p->input_prefix[strlen(filename)-strlen(dot)] =  '\0';


    sprintf (line, p->file_pattern, p->input_prefix,p->slice_number);
    if (access (line, R_OK) == 0){
/*
we have a valid noheader file of %s.%d format
*/
       strcpy(p->file_pattern,"%s.%d");
    }  
/*
now try to correct for simon's image type i.e. I.001 w/ no header
*/
    else {
      sprintf(line,"%s.%03d",p->input_prefix,p->slice_number);
      if (access (line, R_OK) == 0){
        strcpy(p->file_pattern,"%s.%03d");
      }
/*
now try for compressed 
*/
      else {
        strcat(line,".gz");
        if (access (line, R_OK) == 0){
          strcpy(p->file_pattern,"%s.%03d");
        }
        else{
          sprintf (line, p->file_pattern, p->input_prefix, p->slice_number);
          strcat(line,".Z");
          if (access (line, R_OK) == 0){
            strcpy(p->file_pattern,"%s.%03d");
          }
        }
      }
    }
    p->status = 1;
    break;
  case 1576960:  /* spect - strange val is due to assumptions made by readANY */
    strcpy(p->exam_modality,"spect");
    p->byte_order = 1;
/*
spect will always come in a 128*128*2*64 volume w/ a 4k header
*/
    p->bytes_per_pixel = 2;
    p->header_size = 4096;
    p->cols = 128;
    p->rows = 128;
    p->bytes_per_slice = p->bytes_per_pixel * p->cols * p->rows;
    p->pixel_xsize = 1.0;
    p->pixel_ysize = 1.0;
    p->fov = p->cols * p->pixel_xsize;
    p->thick = 1.0;
    p->aspect = (p->thick + p->space) / p->pixel_xsize;
/*
swap image bytes - spect uses "vax" byte order
    swab(p->image,p->image,p->cols*p->cols*2);
*/
    p->number_echoes = 1;
    p->swap = 2;
    p->echo_number = 1;
    p->slice_number = 1; 
    strcpy(p->image_type_text, "spect");
    p->image_type_num = 5; 
    s_header = (SPECT_HEADER *) malloc(sizeof(SPECT_HEADER));
    if (s_header == NULL) {
      perror("spl_get_image_info");
      free(p->image);
      return(p);
    }
    memcpy(s_header, &p->header, sizeof(SPECT_HEADER));
    strncpy (p->filename, s_header->patient_name,30);

    p->pixel_xsize = 3.0;
    p->pixel_ysize = 3.0;
    p->fov = p->cols * p->pixel_xsize;
    p->thick = 3.0;
    p->aspect = (p->thick + p->space) / p->pixel_xsize;
    memcpy(p->patname, &p->header[IMAGE_TEXT_OFFSET + 96], 25);
    strcpy(p->file_pattern,"%s");
    break;

  default:
    /*
     * good chance it's a genesis or DICOM image
     */
    if (strncmp((char *) p->header, "IMGF", 4) == 0) {
      p->byte_order = 0;
      p->bytes_per_pixel = 2;
      p->bytes_per_slice = p->bytes_per_pixel * p->cols * p->rows;
      memcpy((char *) &variable_header_count, &p->header[IMG_P_SUITE], 4);
      exam_offset = variable_header_count + EX_HDR_START;
      series_offset = variable_header_count + SE_HDR_START;
      image_offset = variable_header_count + IM_HDR_START;
      memcpy((char *) p->manufacturers_model_name, &p->header[0 + _SU_prodid], 4);
/*
work out patient position here  and print it in the dicom style:
patint position appears to be derived from the se_entry and se_position
tags in the genesis header:
se_entry =1 -> HF (headfirst)
se_entry =2 -> FF (feetfirst)
se_postion = 1 -> S (suppine)
se_postion = 2 -> P (prone)
se_postion = 4 -> DL (Left Lateral Decubitis)
se_postion = 8 -> DR (Right Lateral Decubitis)

valid DICOM PatientPositions are:

        "HFS",  "Head First Supine",
        "HFP",  "Head First Prone",
        "HFDL", "Head First Decubitus Left",
        "HFDR", "Head First Decubitus Right",
        "FFS",  "Feet First Supine",
        "FFP",  "Feet First Prone",
        "FFDL", "Feet First Decubitus Left",
        "FFDR", "Feet First Decubitus Right",

so we can derive a correct value from this 
*/
      memcpy((char *) &se_position, &p->header[series_offset + _SE_position], 4);
      memcpy((char *) &se_entry, &p->header[series_offset + _SE_entry], 4);
      if(se_entry == 1 && se_position == 1){
          strcpy(p->patient_position,"HFS");
      }
      else if(se_entry == 1 && se_position == 2){
          strcpy(p->patient_position,"HFP");
      }
      else if(se_entry == 1 && se_position == 4){
          strcpy(p->patient_position,"HFDL");
      }
      else if(se_entry == 1 && se_position == 8){
          strcpy(p->patient_position,"HFDR");
      }
      else if(se_entry == 2 && se_position == 1){
          strcpy(p->patient_position,"FFS");
      }
      else if(se_entry == 2 && se_position == 2){
          strcpy(p->patient_position,"FFP");
      }
      else if(se_entry == 2 && se_position == 4){
          strcpy(p->patient_position,"FFDL");
      }
      else if(se_entry == 2 && se_position == 8){
          strcpy(p->patient_position,"FFDR");
      }

      printf("ENTRY AND POSITION ARE %d %d \n",se_entry, se_position);
/*
genesis may be either CT or MR, with different header offsets for each ...
*/
      memcpy(exam_type,&p->header[exam_offset+_EX_ex_typ],3);
      if (strncmp(exam_type,"MR",2) == 0){
        strcpy(p->exam_modality,"MR");
        memcpy((char *) &ushortval, &p->header[image_offset + _MR_numecho], 2);
        p->number_echoes = ushortval;
        if(p->number_echoes == 0) p->number_echoes = 1;
        memcpy((char *) &ushortval, &p->header[image_offset + _MR_echonum], 2);
        p->echo_number = ushortval;
        if(p->echo_number == 0) p->echo_number = 1;
        memcpy((char *) &ushortval, &p->header[image_offset + _MR_im_seno], 2);
        p->series_number = ushortval;
        memcpy((char *) &p->pixel_xsize, &p->header[image_offset + _MR_pixsize_X], 4);
        memcpy((char *) &p->pixel_ysize, &p->header[image_offset + _MR_pixsize_Y], 4);
        memcpy((char *) &p->fov, &p->header[image_offset + _MR_dfov], 4);
        memcpy((char *) &p->thick, &p->header[image_offset + _MR_slthick], 4);
        memcpy((char *) &p->space, &p->header[image_offset + _MR_scanspacing], 4);
        memcpy((char *) &p->image_location, &p->header[image_offset + _MR_loc], 4);
/*
coordinate information  
*/


        memcpy((char *) &p->coord_center_r, &p->header[image_offset + _MR_ctr_R], 4);
        memcpy((char *) &p->coord_center_a, &p->header[image_offset + _MR_ctr_A], 4);
        memcpy((char *) &p->coord_center_s, &p->header[image_offset + _MR_ctr_S], 4);

        memcpy((char *) &p->coord_normal_r, &p->header[image_offset + _MR_norm_R], 4);
        memcpy((char *) &p->coord_normal_a, &p->header[image_offset + _MR_norm_A], 4);
        memcpy((char *) &p->coord_normal_s, &p->header[image_offset + _MR_norm_S], 4);
  
        memcpy((char *) &p->coord_r_top_left, &p->header[image_offset + _MR_tlhc_R], 4);
        memcpy((char *) &p->coord_a_top_left, &p->header[image_offset + _MR_tlhc_A], 4);
        memcpy((char *) &p->coord_s_top_left, &p->header[image_offset + _MR_tlhc_S], 4);
  
        memcpy((char *) &p->coord_r_top_right, &p->header[image_offset + _MR_trhc_R], 4);
        memcpy((char *) &p->coord_a_top_right, &p->header[image_offset + _MR_trhc_A], 4);
        memcpy((char *) &p->coord_s_top_right, &p->header[image_offset + _MR_trhc_S], 4);

        memcpy((char *) &p->coord_r_bottom_right, &p->header[image_offset + _MR_brhc_R], 4);
        memcpy((char *) &p->coord_a_bottom_right, &p->header[image_offset + _MR_brhc_A], 4);
        memcpy((char *) &p->coord_s_bottom_right, &p->header[image_offset + _MR_brhc_S], 4);
      }
      else if (strncmp(exam_type,"CT",2) == 0){
        strcpy(p->exam_modality,"CT");
        p->number_echoes = 1;
        p->echo_number = 1;
        memcpy((char *) &ushortval, &p->header[image_offset + _CT_im_seno], 2);
        p->series_number = ushortval;
        memcpy((char *) &p->pixel_xsize, &p->header[image_offset + _CT_pixsize_X], 4);
        memcpy((char *) &p->gantry_tilt, &p->header[image_offset + _CT_gantilt], 4);
        memcpy((char *) &p->pixel_ysize, &p->header[image_offset + _CT_pixsize_Y], 4);
        memcpy((char *) &p->fov, &p->header[image_offset + _CT_dfov], 4);
        memcpy((char *) &p->thick, &p->header[image_offset + _CT_slthick], 4);
        memcpy((char *) &p->space, &p->header[image_offset + _CT_scanspacing], 4);
        memcpy((char *) &p->image_location, &p->header[image_offset + _CT_loc], 4);
        memcpy((char *) &p->coord_center_r, &p->header[image_offset + _CT_ctr_R], 4);
        memcpy((char *) &p->coord_center_a, &p->header[image_offset + _CT_ctr_A], 4);
        memcpy((char *) &p->coord_center_s, &p->header[image_offset + _CT_ctr_S], 4);
 
        memcpy((char *) &p->coord_normal_r, &p->header[image_offset + _CT_norm_R], 4);
        memcpy((char *) &p->coord_normal_a, &p->header[image_offset + _CT_norm_A], 4);
        memcpy((char *) &p->coord_normal_s, &p->header[image_offset + _CT_norm_S], 4);
        memcpy((char *) &p->coord_r_top_left, &p->header[image_offset + _CT_tlhc_R], 4);
        memcpy((char *) &p->coord_a_top_left, &p->header[image_offset + _CT_tlhc_A], 4);
        memcpy((char *) &p->coord_s_top_left, &p->header[image_offset + _CT_tlhc_S], 4);
  
        memcpy((char *) &p->coord_r_top_right, &p->header[image_offset + _CT_trhc_R], 4);
        memcpy((char *) &p->coord_a_top_right, &p->header[image_offset + _CT_trhc_A], 4);
        memcpy((char *) &p->coord_s_top_right, &p->header[image_offset + _CT_trhc_S], 4);
 
        memcpy((char *) &p->coord_r_bottom_right, &p->header[image_offset + _CT_brhc_R], 4);
        memcpy((char *) &p->coord_a_bottom_right, &p->header[image_offset + _CT_brhc_A], 4);   
        memcpy((char *) &p->coord_s_bottom_right, &p->header[image_offset + _CT_brhc_S], 4);   
      }
      else {
          fprintf(stdout,"unknown image type %s\n",exam_type);
      }

      p->aspect = (p->thick + p->space) / p->pixel_xsize;
      memcpy((char*)&my_clock,(char*)&p->header[series_offset+_SE_se_actual_dt], 4);
      tmptr=localtime(&my_clock);
      sprintf(p->date,"%d/%d/%02d",tmptr->tm_mon+1,tmptr->tm_mday,
        tmptr->tm_year%100);
      sprintf(p->time,"%02d:%02d:%02d",tmptr->tm_hour,tmptr->tm_min,tmptr->tm_sec);

/*
get image number from actual file name, not header
*/
    if ((token = (char *) strrchr (filename, '/')) != NULL) {
       if ((dot = (char *) strchr (token, '.')) != NULL) {
                sscanf (dot, ".%03d", &p->slice_number);
        }
        else{
          fprintf(stderr,"cant figure out image number for file %s\n",filename);
          exit(0);
        }
    }
    else{
       dot = (char *) strchr (filename,'.');
       sscanf (dot, ".%03d", &p->slice_number);
    }

    strcpy(p->file_pattern,"%s.%03d");
    strcpy(p->image_type_text, "genesis");
    strcpy(p->filename, filename);
    strncpy(p->input_prefix,filename,(strlen(filename) -strlen(dot)));
    p->input_prefix[strlen(filename)-strlen(dot)] =  '\0';
    p->image_type_num = 2;
    memcpy(p->study_desc, &p->header[exam_offset + _EX_ex_desc], 23);
    memcpy(p->series_desc, &p->header[series_offset + _SE_se_desc], 30);
    memcpy(p->patname, &p->header[exam_offset + _EX_patname], 25);
    memcpy(p->hospital_name, &p->header[exam_offset + _EX_hospname], 33);
    memcpy(p->referring_physician, &p->header[exam_offset + _EX_refphy], 33);
    memcpy(p->patient_id, &p->header[exam_offset + _EX_patid], 13);
    memcpy((char *) &ushortval, &p->header[exam_offset + _EX_patage], 2);
    p->patient_age = ushortval;
    memcpy((char *) &ushortval, &p->header[exam_offset + _EX_patsex], 2);
    if ( ushortval == 2)
      strcpy(p->patient_sex,"F");
    else if ( ushortval == 1) 
      strcpy(p->patient_sex,"M");
    else 
      strcpy(p->patient_sex,"?");
    memcpy((char *) &ushortval, &p->header[exam_offset + _EX_ex_no], 2);
    p->exam_number = ushortval;

    p->status = 1;
    break;
    }
/****************************************************************
try dicom format
****************************************************************/
    else if (1 == 1) {

/*
get a bunch of info from the dicom header - these are the fields
we're interested in
*/
   groups[0] = 0x8; elements[0] = 0x8; /* Image Type CS */
   groups[1] = 0x8; elements[1] = 0x18;  /* SOP Instance UID UI */
   groups[2] = 0x8; elements[2] = 0x20;  /* study  date DA*/
   groups[3] = 0x8; elements[3] = 0x33;  /* Image Time TM */
   groups[4] = 0x8; elements[4] = 0x0060;   /* modality CS*/
   groups[5] = 0x8; elements[5] = 0x0070;  /* Manufacturer LO */
   groups[6] = 0x8; elements[6] = 0x0080;   /* hospital name LO*/
   groups[7] = 0x8; elements[7] =  0x0090;  /* Referring Physician's Name PN */
   groups[8] = 0x8; elements[8] = 0x1030;   /* study desc LO*/
   groups[9] = 0x8; elements[9] = 0x103e;   /* series desc LO*/
   groups[10] = 0x8; elements[10] = 0x1060;   /* Name of Physician(s) Reading Study PN */
   groups[11] = 0x8; elements[11] = 0x1090;  /* Manufacturer's Model Name LO*/
   groups[12]= 0x8; elements[12]=  0x2208;  /* Anatomic Structure CS */
   groups[13] = 0x10; elements[13] = 0x10;      /* patname PN*/
   groups[14] = 0x10; elements[14] = 0x0020;    /* patient id LO*/
   groups[15] = 0x10; elements[15] =  0x0030;  /* Patient's Birth Date DA */
   groups[16] = 0x10; elements[16] = 0x0040;    /* patient sex CS*/
   groups[17] = 0x10; elements[17] = 0x1010;    /* patient age AS*/
   groups[18] = 0x10; elements[18] = 0x1030;  /* Patient's Weight DS */
   groups[19] = 0x18; elements[19] = 0x15;      /* Body Part Examined CS */
   groups[20] = 0x18; elements[20] = 0x0050;    /* thickness DS*/
   groups[21] = 0x18; elements[21] = 0x80;  /* Repetition Time DS */
   groups[22] = 0x18; elements[22] = 0x81;  /* Echo Time DS */
   groups[23] = 0x18; elements[23] = 0x82;      /* Inversion Time DS */
   groups[24] = 0x18; elements[24] = 0x0086;    /* echo number(s) IS*/
   groups[25] = 0x18; elements[25] = 0x0088;    /* space between slices DS*/
   groups[26] = 0x18; elements[26] = 0x1100;    /* Reconstruction Diameter DS */
   groups[27] = 0x18; elements[27] = 0x1170;    /* Generator Power IS */
   groups[28] = 0x18; elements[28] = 0x5100;    /* Patient Position CS*/
   groups[29] = 0x20; elements[29] = 0x0010;    /* exam number SH*/
   groups[30] = 0x20; elements[30] = 0x0011;    /* series number IS*/
   groups[31] = 0x20; elements[31] = 0x0013;    /* image number IS*/
   groups[32] = 0x20; elements[32] = 0x0020;    /* Patient Orientation */
   groups[33] = 0x20; elements[33] = 0x1000;    /* Series in Study IS */
   groups[34] = 0x20; elements[34] = 0x1002;    /* Images in Acquisition IS */
   groups[35] = 0x20; elements[35] = 0x1041;    /* Slice Location DS*/
   groups[36] = 0x28; elements[36] = 0x0010;    /* xres US*/
   groups[37] = 0x28; elements[37] = 0x0011;    /* yres US*/
   groups[38] = 0x28; elements[38] = 0x0030;    /* pixsize_x  \ pixsize_y DS*/
   groups[39] = 0x28; elements[39] = 0x0101;    /* Bits Stored US */
   groups[40] = 0x28; elements[40] = 0x0102;    /* High Bit US */
   groups[41] = 0x28; elements[41] = 0x1052;    /* Rescale Intercept DS */
   groups[42] = 0x28; elements[42] = 0x1053;    /* Rescale Slope DS */
   groups[43] = 0x32; elements[43] = 0x1060;    /* Requested Procedure Description LO */
   groups[44] = 0x28; elements[44] = 0x0100;    /* Bits Allocated US */

   groups[45] = 0x18; elements[45] = 0x1120;    /* gantry_tilt DS*/
/*
need next 2 to get the image co-ordinates
*/
   groups[46] = 0x20; elements[46] = 0x0032;    /* Image position */
   groups[47] = 0x20; elements[47] = 0x0037;    /* Image Orientation  */
   num_elements = 47;

/*
get the info for each group/element pair
    */
 
 
      dd_index = find_element_in_data_dictionary(groups[0],
                                                 elements[0]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 38) length = 38;
              strncpy(p->image_type,out_string,length);
          }
          else{
              strcpy(p->image_type,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[1],
                                                 elements[1]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 64) length = 64;
              strncpy(p->sop_instance_uid,out_string,length);
          }
          else{
              strcpy(p->sop_instance_uid,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[2],
                                                 elements[2]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->date,out_string,length);
          }
          else{
              strcpy(p->date,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[3],
                                                 elements[3]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->image_time,out_string,length);
          }
          else{
              strcpy(p->image_time,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[4],
                                                 elements[4]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->exam_modality,out_string,length);
          }
          else{
              strcpy(p->exam_modality,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[5],
                                                 elements[5]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 64) length = 64;
              strncpy(p->manufacturer,out_string,length);
          }
          else{
              strcpy(p->manufacturer,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[6],
                                                 elements[6]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->hospital_name,out_string,length);
          }
          else{
              strcpy(p->hospital_name,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[7],
                                                 elements[7]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 64) length = 64;
              strncpy(p->referring_physician,out_string,length);
          }
          else{
              strcpy(p->referring_physician,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[8],
                                                 elements[8]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->study_desc,out_string,length);
          }
          else{
              strcpy(p->study_desc,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[9],
                                                 elements[9]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->series_desc,out_string,length);
          }
          else{
              strcpy(p->series_desc,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[10],
                                                 elements[10]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 64) length = 64;
              strncpy(p->physician_reading_study,out_string,length);
          }
          else{
              strcpy(p->physician_reading_study,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[11],
                                                 elements[11]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 64) length = 64;
              strncpy(p->manufacturers_model_name,out_string,length);
          }
          else{
              strcpy(p->manufacturers_model_name,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[12],
                                                 elements[12]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->anatomic_structure,out_string,length);
          }
          else{
              strcpy(p->anatomic_structure,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[13],
                                                 elements[13]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->patname,out_string,length);
          }
          else{
              strcpy(p->patname,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[14],
                                                 elements[14]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->patient_id,out_string,length);
          }
          else{
              strcpy(p->patient_id,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[15],
                                                 elements[15]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->birth_date,out_string,length);
          }
          else{
              strcpy(p->birth_date,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[16],
                                                 elements[16]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              strncpy(p->patient_sex,out_string,length);
          }
          else{
              strcpy(p->patient_sex,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[17],
                                                 elements[17]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%d", &shortval);
              p->patient_age = shortval;
          }
          else{
              p->patient_age = 0;
          }
      }
      dd_index = find_element_in_data_dictionary(groups[18],
                                                 elements[18]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->weight,out_string,length);
          }
          else{
              strcpy(p->weight,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[19],
                                                 elements[19]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->body_part_examined,out_string,length);
          }
          else{
              strcpy(p->body_part_examined,"N/A");
          }
      }
      dd_index = find_element_in_data_dictionary(groups[20],
                                                 elements[20]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%f", &floatval);
              p->thick = floatval;
          }
          else{
/*
  set to 1 to keep slicer happy
*/
              p->thick = 1.0;
          }
      }
      dd_index = find_element_in_data_dictionary(groups[21],
                                                 elements[21]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->repetition_time,out_string,length);
          }
          else{
              strcpy(p->repetition_time,"N/A");
          }
      }  
      
      
      dd_index = find_element_in_data_dictionary(groups[22],
                                                 elements[22]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->echo_time,out_string,length);
          }
          else{
              strcpy(p->echo_time,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[23],
                                                 elements[23]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->inversion_time,out_string,length);
          }
          else{
              strcpy(p->inversion_time,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[24],
                                                 elements[24]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%d", &shortval);
              p->echo_number = shortval;
          }
          else{
              p->echo_number = 0;
          }
      }
      dd_index = find_element_in_data_dictionary(groups[25],
                                                 elements[25]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%f", &floatval);
              p->space = floatval;
          }
          else{
              p->space = 0.0;
          }
      }
/*
  DICOM gives spacing as the distance between center slices -
  our apps think of spacing as "the empty space between slices"
  so we'll consider spacing in that way
*/
      p->space = p->space - p->thick;
/*
  things dont work well with negative spacing, so set it to zero
*/
      if ( p->space < 0.0) p->space = 0.0;
      
      dd_index = find_element_in_data_dictionary(groups[26],
                                                 elements[26]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->reconstruction_diameter,out_string,length);
          }
          else{
              strcpy(p->reconstruction_diameter,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[27],
                                                 elements[27]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->generator_power,out_string,length);
          }
          else{
              strcpy(p->generator_power,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[28],
                                                 elements[28]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 10) length = 10;
              strncpy(p->patient_position,out_string,length);
          }
          else{
              strcpy(p->patient_position,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[29],
                                                 elements[29]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%d", &shortval);
              p->exam_number = shortval;
          }
          else{
              p->exam_number = 0;
          }    
      }
      dd_index = find_element_in_data_dictionary(groups[30], 
                                                 elements[30]); 
      if (dd_index != -1) { 
          out_string = (char *) find_data_element_in_header(p); 
          if (out_string != NULL) { 
              sscanf(out_string,"%d", &shortval); 
              p->series_number = shortval; 
          } 
          else{ 
              p->series_number = 0; 
          }     
      }  
      dd_index = find_element_in_data_dictionary(groups[31], 
                                                 elements[31]); 
      if (dd_index != -1) { 
          out_string = (char *) find_data_element_in_header(p); 
          if (out_string != NULL) { 
              sscanf(out_string,"%d", &shortval); 
              p->slice_number = intval; 
          } 
          else{ 
              p->slice_number = 0; 
          }     
      }
      dd_index = find_element_in_data_dictionary(groups[32],
                                                 elements[32]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 10) length = 10;
              strncpy(p->patient_orientation,out_string,length);
          }
          else{
              strcpy(p->patient_orientation,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[33],
                                                 elements[33]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->series_in_study,out_string,length);
          }
          else{
              strcpy(p->series_in_study,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[34],
                                                 elements[34]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->images_in_acquisition,out_string,length);
          }
          else{
              strcpy(p->images_in_acquisition,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[35],
                                                 elements[35]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%f", &floatval);
              p->image_location = floatval;
          }
          else{
/*       
         set to -999 to keep slicer happy
*/
              p->image_location = -999.0;
          }
      }
/*
  skip x,y res already set
*/
      dd_index = find_element_in_data_dictionary(groups[38],
                                                 elements[38]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
/*
  since dicom spec allows characters bwtween the x and y pixel
  sizes, we'll just have to assume square pixels for now unless
  the x, y vals are separated by \\ which seems to be what many
  sites use.
*/
              sscanf(out_string,"%f\\%f", &floatval,&floatval2);
              p->pixel_xsize = floatval;
              if(floatval2 > .001)
                  p->pixel_ysize = floatval2;
              else
                  p->pixel_ysize = floatval;
          }
          else{
/*
  set to 1.0 for slicer if value is unknown
*/
              p->pixel_xsize = 1.0;
              p->pixel_ysize = 1.0;
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[39],
                                                 elements[39]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              memcpy((char *) &shortval,&out_string,2);
/*
  sscanf((char *) out_string,"%d", &shortval);
*/
              p->bits_stored = shortval;
          }
          else{
              p->bits_stored = 0;
          }
      }
      dd_index = find_element_in_data_dictionary(groups[40],
                                                 elements[40]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              swab(out_string,out_string,2);
              sscanf(out_string,"%d", &shortval);
              p->high_bit = shortval;
          }
          else{
              p->high_bit = 0;
          }
      }
      dd_index = find_element_in_data_dictionary(groups[41],
                                                 elements[41]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->rescale_intercept,out_string,length);
          }
          else{
              strcpy(p->rescale_intercept,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[42],
                                                 elements[42]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 32) length = 32;
              strncpy(p->rescale_slope,out_string,length);
          }
          else{
              strcpy(p->rescale_slope,"N/A");
          }
      }  
      dd_index = find_element_in_data_dictionary(groups[43],
                                                 elements[43]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              if(length > 64) length = 64;
              strncpy(p->requested_proc_desc,out_string,length);
          }
          else{
              strcpy(p->requested_proc_desc,"N/A");
          }
      }  

      dd_index = find_element_in_data_dictionary(groups[44],
                                                 elements[44]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              swab(out_string,out_string,2);
              sscanf(out_string,"%d", &shortval);
              p->bits_allocated = shortval;
          }
          else{
              p->bits_allocated = 0;
          }    
      }
      
      dd_index = find_element_in_data_dictionary(groups[45],
                                                 elements[45]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%f", &floatval);
              p->gantry_tilt = floatval;
          }
      }  
/*
  now get the RAS information for the image co-ordinates
*/
      dd_index = find_element_in_data_dictionary(groups[46],
                                                 elements[46]);
      if (dd_index != -1) {
          out_string = (char *) find_data_element_in_header(p);
          if (out_string != NULL) {
              sscanf(out_string,"%f\\%f\\%f", &floatval,&floatval2,&floatval3);
              p->imagepositionpatient[0] = floatval;
              p->imagepositionpatient[1] = floatval2;
              p->imagepositionpatient[2] = floatval3;
              
          }
      }  
      
      dd_index = find_element_in_data_dictionary(groups[47],
                                                 elements[47]);
      if (dd_index != -1) {
        out_string = (char *) find_data_element_in_header(p);
        if (out_string != NULL) {
            sscanf(out_string,"%f\\%f\\%f\\%f\\%f\\%f", &floatval,&floatval2,&floatval3,&floatval4,&floatval5,&floatval6);
            p->imageorientationpatient[0] = floatval;
            p->imageorientationpatient[1] = floatval2;
            p->imageorientationpatient[2] = floatval3;
            p->imageorientationpatient[3] = floatval4;
            p->imageorientationpatient[4] = floatval5;
            p->imageorientationpatient[5] = floatval6;
            cross_product1 = floatval2*floatval6-floatval3*floatval5;
            cross_product2 = floatval3*floatval4-floatval*floatval6;
            cross_product3 = floatval*floatval5-floatval2*floatval4;
            printf("cross_product = (%f,%f,%f)\n",cross_product1,cross_product2,cross_product3);
            printf("cross_product(abs) = (%f,%f,%f)\n",abs(cross_product1),abs(cross_product2),abs(cross_product3));
/*
  looks like we can determine sag/axial/cor from cross-product
*/
            if(cross_product1 > .9 || cross_product1 < -.9) {printf("saggital!\n"); acquisition = SAGGITAL;}
            if(cross_product2 > .9 || cross_product2 < -.9) {printf("coronal!\n"); acquisition = CORONAL;}
            if(cross_product3 > .9 || cross_product3 < -.9) {printf("axial!\n"); acquisition = AXIAL;}
        }
      } 
      
/*
  set RAS based on acquisition
*/
      if (acquisition == AXIAL){
          
/*
  try this ....
*/
          p->coord_center_s =  p->image_location;
          
/*
  imagepositionpatient is the upper left hand corner of the image
  so we will try to set it as the RAS top left
*/
          p->coord_r_top_left = p->imagepositionpatient[0]; 
          p->coord_a_top_left = p->imagepositionpatient[1];
          p->coord_s_top_left = p->imagepositionpatient[2]; 
          
          p->coord_r_top_right = p->coord_r_top_left + p->cols*p->pixel_xsize;
          p->coord_a_top_right = p->imagepositionpatient[1];
          p->coord_s_top_right = p->imagepositionpatient[2]; 
          
          p->coord_r_bottom_right = p->coord_r_top_right;
          p->coord_a_bottom_right = p->imagepositionpatient[1] - p->rows*p->pixel_ysize;
          if(p->imagepositionpatient[1] < 0) p->coord_a_bottom_right = p->imagepositionpatient[1] + p->rows*p->pixel_ysize;
          if(p->imagepositionpatient[1] > 0) p->coord_a_bottom_right = p->imagepositionpatient[1] - p->rows*p->pixel_ysize;
          p->coord_s_bottom_right = p->imagepositionpatient[2];
          
/*
  now try convert ala Clunie 
*/
          p->coord_r_top_left = -p->coord_r_top_left;
          p->coord_a_top_left = -p->coord_a_top_left;
          
          p->coord_r_top_right = -p->coord_r_top_right;
          p->coord_a_top_right = -p->coord_a_top_right;
          
          p->coord_r_bottom_right = -p->coord_r_bottom_right;
          p->coord_a_bottom_right = -p->coord_a_bottom_right;
          
/*
  calc center ... looks dicey need fov here for calculation
*/
          p->fov = p->cols * p->pixel_xsize;
          
          if(p->coord_r_top_left < 0) p->coord_center_r = p->coord_r_top_left + (p->fov / 2.0);
          if(p->coord_r_top_left > 0) p->coord_center_r = p->coord_r_top_left - (p->fov / 2.0);
          if(p->coord_a_top_left < 0) p->coord_center_a = p->coord_a_top_left + (p->fov / 2.0);
          if(p->coord_a_top_left > 0) p->coord_center_a = p->coord_a_top_left - (p->fov / 2.0);
/*
  if(p->coord_s_top_left < 0) p->coord_center_s = p->coord_s_top_left + (p->fov / 2.0);
  if(p->coord_s_top_left > 0) p->coord_center_s = p->coord_s_top_left - (p->fov / 2.0);
*/
          
      }
      else if (acquisition == SAGGITAL){
          printf("saggital\n");
/*
  try this ....
*/       
          p->coord_center_r =  p->image_location;
          
/*
  imagepositionpatient is the upper left hand corner of the image
  so we will try to set it as the RAS top left
*/
          p->coord_r_top_left = p->image_location;
          p->coord_a_top_left = -p->imagepositionpatient[1];
          p->coord_s_top_left = p->imagepositionpatient[2];
          
          p->coord_r_top_right = p->image_location;
          p->coord_a_top_right = p->imagepositionpatient[1];
          p->coord_s_top_right = p->imagepositionpatient[2];
          
          p->coord_r_bottom_right = p->image_location;
          p->coord_a_bottom_right = p->imagepositionpatient[1];
          p->coord_s_bottom_right = p->imagepositionpatient[1];
          
          
/*
  calc center ... looks dicey need fov here for calculation
*/
          p->fov = p->cols * p->pixel_xsize;
          
          if(p->coord_r_top_left < 0) p->coord_center_r = p->coord_r_top_left + (p->fov / 2.0);
          if(p->coord_r_top_left > 0) p->coord_center_r = p->coord_r_top_left - (p->fov / 2.0);
          if(p->coord_a_top_left < 0) p->coord_center_a = p->coord_a_top_left + (p->fov / 2.0);
          if(p->coord_a_top_left > 0) p->coord_center_a = p->coord_a_top_left - (p->fov / 2.0);
          if(p->coord_s_top_left < 0) p->coord_center_s = p->coord_s_top_left + (p->fov / 2.0);
          if(p->coord_s_top_left > 0) p->coord_center_s = p->coord_s_top_left - (p->fov / 2.0);
          
      }
      else if (acquisition == CORONAL){
          printf("coronal\n");
/*
  need fov for coronal
*/
          p->fov = p->cols * p->pixel_xsize;
/*
  try this ....
*/
          p->coord_center_a =  p->image_location;
          
/*
  imagepositionpatient is the upper left hand corner of the image
  so we will try to set it as the RAS top left
*/
          p->coord_r_top_left = -p->imagepositionpatient[0];
          p->coord_a_top_left = p->image_location;
          p->coord_s_top_left = p->imagepositionpatient[2];
          
          p->coord_r_top_right = p->coord_r_top_left - p->fov;
          p->coord_a_top_right = p->image_location;
          p->coord_s_top_right = p->coord_s_top_left;
          
          p->coord_r_bottom_right = p->coord_r_top_right;
          p->coord_a_bottom_right = p->image_location;
          p->coord_s_bottom_right = p->coord_s_top_right - p->fov;
          
          
          
          if(p->coord_r_top_left < 0) p->coord_center_r = p->coord_r_top_left + (p->fov / 2.0);
          if(p->coord_r_top_left > 0) p->coord_center_r = p->coord_r_top_left - (p->fov / 2.0);
          p->coord_center_a = p->image_location;
          p->coord_center_s = (p->coord_s_bottom_right+p->coord_s_top_left)/ 2.0;
          
      }
      
/*
***********************ignore blather below for now******************
now we need to:
1) scale i,j,k by voxel size pixel_xsize(px) pixel_ysize(py) thickness(pz)
2) multiply rcs 3x3 by ijk
3) add patient postition to resulting position

pxi   0   0     rx   cx   sx    patpos x
0    pyj  0  *  ry   cy   sy  + patpos y
0     0  pzk    rz   cz   sz    patpos z

=

pxi*rx  pxi*cx   pxi*sx
pyj*ry  pyj*cy   pyj*sy
pzk*rz  pzk*cz   pzk*sz 

*/


      strcpy(p->image_type_text, "dicom");
      p->image_type_num = 6;
      p->byte_order = 1;
      p->aspect = (p->thick + p->space) / p->pixel_xsize;

/*
get image number from actual file name, not header
*/
      if ((token = (char *) strrchr (filename, '/')) != NULL) {
          if ((dot = (char *) strchr (token, '.')) != NULL) {
              sscanf (dot, ".%03d", &p->slice_number);
          }
          else{
              fprintf(stderr,"cant figure out image number for file %s\n",filename);
              exit(0);
          }
      }    
      else{
          dot = (char *) strchr (filename,'.');
          sscanf (dot, ".%d", &p->slice_number);
      }
      strncpy(p->input_prefix,filename,(strlen(filename)-strlen(dot)));
      p->input_prefix[strlen(filename)-strlen(dot)] =  '\0';
      
/* 
this is how RISG currently does it  we will use the same convention
i.e. whatever.001 - there appears to be no naming convention for dicom
 */
      strcpy(p->file_pattern,"%s.%03d"); 
      p->bytes_per_pixel = 2; /* cant find this in header, we'll assume 2 for now */
      p->bytes_per_slice = p->bytes_per_pixel * p->cols * p->rows;
    }
    else{
        fprintf(stderr,"file %s not supported!\n",filename);
        free(p->image);
        free(p->header);
        p->status = -1;
        return(p);
    }
  }
/*
now get series information
*/
  p->num_missing = 0;
  first = 1;
  last = MAX_NUM_IMAGES;
  p->number_of_slices = 0;
  p->first_slice = p->slice_number;
  p->last_slice = p->slice_number;
  
  for (i = p->slice_number;i>= first;i--) {
      sprintf (line, p->file_pattern, p->input_prefix,i);
      if (access (line, R_OK) == 0){
          p->number_of_slices++; 
          p->first_slice = i;
      }
      else {
          strcat(line,".gz");
          if (access (line, R_OK) == 0){
              p->number_of_slices++;
              p->first_slice = i;
          }
          else{
              sprintf (line, p->file_pattern, p->input_prefix, i );
              strcat(line,".Z");
              if (access (line, R_OK) == 0){
                  p->number_of_slices++;
                  p->first_slice = i;
              }
              else{
                  p->missing[i]=1;
                  p->num_missing++;
                  if(p->num_missing >= MISSING_MAX){
                      last = i;
                      break;
                  }
              }
          }  
      }
  }
/*
now clear missing files that are not really
missing, but are less than the first slice 
*/
  for(i = first;i< p->first_slice;i++) {
      if(p->missing[i] == 1) {
          p->missing[i] = 0;
          p->num_missing--;
      }
  }
  for (i = p->slice_number+1;i<= MAX_NUM_IMAGES;i++) {
      sprintf (line, p->file_pattern, p->input_prefix,i);
      if (access (line, R_OK) == 0){
          p->number_of_slices++;
          p->last_slice = i;
      }  
      else {
          strcat(line,".gz");
          if (access (line, R_OK) == 0){
              p->number_of_slices++;
              p->last_slice = i;
          }
          else{
              sprintf (line, p->file_pattern, p->input_prefix, i );
              strcat(line,".Z");
              if (access (line, R_OK) == 0){
                  p->number_of_slices++;
                  p->last_slice = i;
              }
              else{
                  p->missing[i]=1;
                  p->num_missing++;
                  if(p->num_missing >= MISSING_MAX){
                      break;
                  }
              }  
          }
      }  
  }  
/*
  now clear missing files that are not really
  missing, but are greater than the last slice 
*/
  for(i = p->last_slice+1;i< MAX_NUM_IMAGES;i++) {
      if (p->missing[i] == 1) {
          p->missing[i] = 0;
          p->num_missing--;
      }
  }
  
  p->num_data_bytes_in_volume=p->cols*p->rows*p->number_of_slices*p->bytes_per_pixel;
  p->num_header_bytes_in_volume=p->number_of_slices*p->header_size;
  
  return(p);
}

int ii_get_int(ImageInfo *ii, char *kw, int *intp)
{
  ImageInfo_private *iip = (ImageInfo_private *)ii;

  if(strcmp(kw,"x_resolution") == 0){
      *intp = iip->cols;
  }
  else if(strcmp(kw,"y_resolution") == 0){
      *intp = iip->rows;
  }
  else if(strcmp(kw,"rows") == 0){
      *intp = iip->rows;
  }
  else if(strcmp(kw,"cols") == 0){
      *intp = iip->cols;
  }
  else if(strcmp(kw,"bytes_per_slice") == 0){
      *intp = iip->bytes_per_slice;
  }
  else if(strcmp(kw,"number_of_slices") == 0){
      *intp = iip->number_of_slices;
  }
  else if(strcmp(kw,"header_size") == 0){
      *intp = iip->header_size;
  }
  else if(strcmp(kw,"slice_number") == 0){
      *intp = iip->slice_number;
  }
  else if(strcmp(kw,"image_type_num") == 0){
      *intp = iip->image_type_num;
  }
  else if(strcmp(kw,"byte_order") == 0){
      *intp = iip->byte_order;
  }
  else if(strcmp(kw,"status") == 0){
      *intp = iip->status;
  }
  else if(strcmp(kw,"number_echoes") == 0){
      *intp = iip->number_echoes;
  }
  else if(strcmp(kw,"echo_number") == 0){
      *intp = iip->echo_number;
  }
  else if(strcmp(kw,"compressed") == 0){
      *intp = iip->compressed;
  }
  else if(strcmp(kw,"first_slice") == 0){
      *intp = iip->first_slice;
  }
  else if(strcmp(kw,"last_slice") == 0){
      *intp = iip->last_slice;
  }
  else if(strcmp(kw,"num_missing") == 0){
      *intp = iip->num_missing;
  }
  else if(strcmp(kw,"patient_age") == 0){
      *intp = iip->patient_age;
  }
  else if(strcmp(kw,"bytes_per_pixel") == 0){
      *intp = iip->bytes_per_pixel;
  }
  else if(strcmp(kw,"num_bytes_data") == 0){
      *intp = iip->num_data_bytes_in_volume;
  }
  else if(strcmp(kw,"num_bytes_header") == 0){
      *intp = iip->num_header_bytes_in_volume;
  }
  else if(strcmp(kw,"swap") == 0){
      *intp = iip->swap;
  }
  else if(strcmp(kw,"exam_number") == 0){
      *intp = iip->exam_number;
  }
  else if(strcmp(kw,"series_number") == 0){
      *intp = iip->series_number;
  }
  else if(strcmp(kw,"bits_stored") == 0){
      *intp = iip->bits_stored;
  }
  else if(strcmp(kw,"high_bit") == 0){
      *intp = iip->high_bit;
  }
  else if(strcmp(kw,"bits_allocated") == 0){
      *intp = iip->bits_allocated;
  }
  else {
    fprintf(stderr,"unknown int keyword %s\n",kw);
    return II_ERROR;
  }
  return II_OK;
}

int 
ii_get_float(ImageInfo *ii, char *kw, float *f)
{
  ImageInfo_private *iip = (ImageInfo_private *)ii;
  if(strcmp(kw,"pixel_xsize") == 0){
      *f = iip->pixel_xsize;
  }
  else if(strcmp(kw,"pixel_ysize") == 0){
      *f = iip->pixel_ysize;
  }
  else if(strcmp(kw,"gantry_tilt") == 0){
      *f = iip->gantry_tilt;
  }
  else if(strcmp(kw,"fov") == 0){
      *f = iip->fov;
  }
  else if(strcmp(kw,"aspect") == 0){
      *f = iip->aspect;
  }
  else if(strcmp(kw,"thick") == 0){
      *f = iip->thick;
  }
  else if(strcmp(kw,"space") == 0){
      *f = iip->space;
  }
  else if(strcmp(kw,"image_location") == 0){
      *f = iip->image_location;
  }
  else if(strcmp(kw,"coord_center_r") == 0){
      *f = iip->coord_center_r;
  }
  else if(strcmp(kw,"coord_center_a") == 0){
      *f = iip->coord_center_a;
  }
  else if(strcmp(kw,"coord_center_s") == 0){
      *f = iip->coord_center_s;
  }
  else if(strcmp(kw,"coord_normal_r") == 0){
      *f = iip->coord_normal_r;
  }
  else if(strcmp(kw,"coord_normal_a") == 0){
      *f = iip->coord_normal_a;
  }
  else if(strcmp(kw,"coord_normal_s") == 0){
      *f = iip->coord_normal_s;
  }
  else if(strcmp(kw,"coord_r_top_left") == 0){
      *f = iip->coord_r_top_left;
  }
  else if(strcmp(kw,"coord_a_top_left") == 0){
      *f = iip->coord_a_top_left;
  }
  else if(strcmp(kw,"coord_s_top_left") == 0){
      *f = iip->coord_s_top_left;
  }
  else if(strcmp(kw,"coord_r_top_right") == 0){
      *f = iip->coord_r_top_right;
  }
  else if(strcmp(kw,"coord_a_top_right") == 0){
      *f = iip->coord_a_top_right;
  }
  else if(strcmp(kw,"coord_s_top_right") == 0){
      *f = iip->coord_s_top_right;
  }
  else if(strcmp(kw,"coord_r_bottom_right") == 0){
      *f = iip->coord_r_bottom_right;
  }
  else if(strcmp(kw,"coord_a_bottom_right") == 0){
      *f = iip->coord_a_bottom_right;
  }
  else if(strcmp(kw,"coord_s_bottom_right") == 0){
      *f = iip->coord_s_bottom_right;
  }
  else {
    fprintf(stderr,"unknown float keyword %s\n",kw);
  }
}
int 
ii_get_char(ImageInfo *ii, char *kw, char  *c, int maxhchars)
{
  ImageInfo_private *iip = (ImageInfo_private *)ii;
  if(strcmp(kw,"image_type_text") == 0){
      strcpy(c,iip->image_type_text);
  }
  else if(strcmp(kw,"filename") == 0){
      strcpy(c,iip->filename);
  }
  else if(strcmp(kw,"input_prefix") == 0){
      strncpy(c,iip->input_prefix,strlen(iip->input_prefix));
      c[strlen(iip->input_prefix)]='\0';
  }
  else if(strcmp(kw,"output_prefix") == 0){
      strcpy(c,iip->output_prefix);
  }
  else if(strcmp(kw,"suffix") == 0){
      strcpy(c,iip->suffix);
  }
  else if(strcmp(kw,"patient_position") == 0){
      strcpy(c,iip->patient_position);
  }
  else if(strcmp(kw,"patient_orientation") == 0){
      strcpy(c,iip->patient_orientation);
  }
  else if(strcmp(kw,"file_pattern") == 0){
      strcpy(c,iip->file_pattern);
  }
  else if(strcmp(kw,"date") == 0){
      strcpy(c,iip->date);
  }
  else if(strcmp(kw,"time") == 0){
      strcpy(c,iip->time);
  }
  else if(strcmp(kw,"study_desc") == 0){
      strcpy(c,iip->study_desc);
  }
  else if(strcmp(kw,"series_desc") == 0){
      strcpy(c,iip->series_desc);
  }
  else if(strcmp(kw,"patient_sex") == 0){
      strcpy(c,iip->patient_sex);
  }
  else if(strcmp(kw,"hospital_name") == 0){
      strcpy(c,iip->hospital_name);
  }
  else if(strcmp(kw,"patient_id") == 0){
      strcpy(c,iip->patient_id);
  }
  else if(strcmp(kw,"exam_modality") == 0){
      strcpy(c,iip->exam_modality);
  }
  else if(strcmp(kw,"patient_name") == 0){
      strcpy(c,iip->patname);
  }
  else if(strcmp(kw,"image_type") == 0){
      strcpy(c,iip->image_type);
  }
  else if(strcmp(kw,"sop_instance_uid") == 0){
      strcpy(c,iip->sop_instance_uid);
  }
  else if(strcmp(kw,"image_time") == 0){
      strcpy(c,iip->image_time);
  }
  else if(strcmp(kw,"manufacturer") == 0){
      strcpy(c,iip->manufacturer);
  }
  else if(strcmp(kw,"referring_physician") == 0){
      strcpy(c,iip->referring_physician);
  }
  else if(strcmp(kw,"physician_reading_study") == 0){
      strcpy(c,iip->physician_reading_study);
  }
  else if(strcmp(kw,"manufacturers_model_name") == 0){
      strcpy(c,iip->manufacturers_model_name);
  }
  else if(strcmp(kw,"anatomic_structure") == 0){
      strcpy(c,iip->anatomic_structure);
  }
  else if(strcmp(kw,"birth_date") == 0){
      strcpy(c,iip->birth_date);
  }
  else if(strcmp(kw,"birth_weight") == 0){
      strcpy(c,iip->birth_weight);
  }
  else if(strcmp(kw,"weight") == 0){
      strcpy(c,iip->weight);
  }
  else if(strcmp(kw,"body_part_examined") == 0){
      strcpy(c,iip->body_part_examined);
  }
  else if(strcmp(kw,"repetition_time") == 0){
      strcpy(c,iip->repetition_time);
  }
  else if(strcmp(kw,"echo_time") == 0){
      strcpy(c,iip->echo_time);
  }
  else if(strcmp(kw,"inversion_time") == 0){
      strcpy(c,iip->inversion_time);
  }
  else if(strcmp(kw,"reconstruction_diameter") == 0){
      strcpy(c,iip->reconstruction_diameter);
  }
  else if(strcmp(kw,"generator_power") == 0){
      strcpy(c,iip->generator_power);
  }
  else if(strcmp(kw,"series_in_study") == 0){
      strcpy(c,iip->series_in_study);
  }
  else if(strcmp(kw,"images_in_acquisition") == 0){
      strcpy(c,iip->images_in_acquisition);
  }
  else if(strcmp(kw,"rescale_intercept") == 0){
      strcpy(c,iip->rescale_intercept);
  }
  else if(strcmp(kw,"rescale_slope") == 0){
      strcpy(c,iip->rescale_slope);
  }
  else if(strcmp(kw,"requested_proc_desc") == 0){
      strcpy(c,iip->requested_proc_desc);
  }
  else {
    fprintf(stderr,"unknown char keyword %s\n",kw);
    return II_ERROR;
  }
  return II_OK;
}


int
ii_get_intv(ImageInfo *ii, char *kw, int *intp,int nints)
{
int ctr = 0;
  ImageInfo_private *iip = (ImageInfo_private *)ii;
  if(strcmp(kw,"missing") == 0){
      for(ctr=0;ctr<nints;ctr++){
        *intp++  = iip->missing[ctr];
      }
  }
  else {
    fprintf(stderr,"unknown float keyword %s\n",kw);
  }
} 

int
ii_get_floatv(ImageInfo *ii, char *kw, float *f,int nfloats)
{
int ctr = 0;
  ImageInfo_private *iip = (ImageInfo_private *)ii;
  if(strcmp(kw,"imagepositionpatient") == 0){
      for(ctr=0;ctr<nfloats;ctr++){
        *f++  = iip->imagepositionpatient[ctr];
      }
  }
  else if(strcmp(kw,"imageorientationpatient") == 0){
      for(ctr=0;ctr<nfloats;ctr++){
        *f++  = iip->imageorientationpatient[ctr];
      }
  }
  else {
    fprintf(stderr,"unknown float keyword %s\n",kw);
  }
} 

float
my_dg_to_sun(field)
  char            field[4];
{
  DG_FLOAT        number;
  float           result;
/*
#ifdef  GNU
  bcopy(field, &number, 4);
#else
#endif
*/
  memcpy(&number, field, 4);
  if (number.sign == 0 &&
      number.exponent == 0 &&
      number.mantissa == 0)
    return (0.0);
 
  result = (float) number.mantissa / (1 << 24) *
    pow(16.0, (float) number.exponent - 64.0);
 
  return ((number.sign == 0) ? result : -result);
}
 
float
f_correct(cs)
  char           *cs;
{
  union thingy {
    float           f_hold;
    char            c_hold[4];
  }               real_one;
 
  real_one.c_hold[0] = cs[1];
  real_one.c_hold[1] = cs[0];
  real_one.c_hold[2] = cs[3];
  real_one.c_hold[3] = cs[2];
 
  return (real_one.f_hold);
}

int
spl_free_image_info(ImageInfo *ii)
{

  if (ii != NULL) {
    free((void *)ii);
    ii = NULL;
  }
  return(II_OK);
}

static char *
find_data_element_in_header(p)
  ImageInfo_private *p;
{
   /*
    * set up a list of group/element pairs that we will try to find in the
    * header
    */
   int             n;
   int             k;
   int             i;
   int             offset;
   int             bytes_this_element, bytes_to_end_of_grp;
   short int             group, element;
   unsigned char a;
   int i_string;
   /*
    * now find each of the group/element pairs selected above in the header
    */
   if(out_string != NULL) free (out_string);

   offset = -1;
   i = 0;

   while (i < (p->header_size)-4) {

      memcpy((char *) &group,&p->header[i],2);
      memcpy((char *) &element,&p->header[i+2],2);
      memcpy((char *) &length,&p->header[i+4],2);

/*
we'll always assume a little-endian DICOM image  - 
hence the swap here 
*/
      swab((char *) &group,(char *) &group,2);
      swab((char *) &element,(char *) &element,2);
      swab((char *) &length,(char *) &length,2);
      if(length > 0 && length < 2048){
        out_string = (char *)malloc(length * sizeof(char) );
      }  
/*
need this for zero-length strings in the header
*/
      else{
          length = 20;
          out_string = (char *)malloc(length * sizeof(char) );
      }  

/*
we've located the tag in the header - now we extract it to a string
*/

      if(group == current_group && element == current_element ){
        for(k=0;k<length;k++){
          out_string[k] = (unsigned char) p->header[i+8+k];
        } 
        return(out_string);
      }  
      i++;
   }
   return (NULL);
 
}

/*****************************************************************************/
/*
 * find the group/element pair in the data dictionary
 */
int
find_element_in_data_dictionary(group, element)
   int             group;
   int             element;
{
   int             k;

   for (k = 0; k < num_data__dictionary_elements; k++) {
      sscanf(datadict[k], "%04x %04x %2s\n", &current_group, &current_element,current_vr);
      if (current_group == group && current_element == element) {
        memset(buf, NULL, MAXPATHLEN);
        memset(current_desc, NULL, MAXPATHLEN);
        memcpy(buf, datadict[k], strlen(datadict[k]));
        memcpy(current_desc, (char *) &buf[14], strlen(datadict[k]) - 16);
        return (k);
        break;
      }  
   }   
   return (-1);
}

