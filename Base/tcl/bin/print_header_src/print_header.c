/*
simple program to print header information for a variety of different
datatypes
*/


#include <stdio.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/param.h>
#include "public.h"

#define FALSE 0
#define TRUE 1
main(argc,argv)
int argc;
char *argv[];
{
char filename[MAXPATHLEN];
char output_filename[MAXPATHLEN];
int i;
void *dicom; /* a generic pointer */
void *tempptr; /* a generic pointer */
int status;
int testint;
float testfloat;
float floatarr[100];
char testchar[MAXPATHLEN];
int maxlen = MAXPATHLEN;
/*
use following params to build 
filename
*/
int  pixels_expected;
int  tmpslicenumber;
unsigned char *header_buffer = NULL;
unsigned short *io_buffer;

/*
parameters for verbose mode
*/

int  verbose = FALSE;
char tmpfilename[MAXPATHLEN];
char tmpfilepattern[MAXPATHLEN];
char tmpfileprefix[MAXPATHLEN];
char tmpadjecentimage[MAXPATHLEN];
int  tmpnumber_echos;
int  tmpimagenumber;
float  tmpimagelocation;

  
    if ((argc != 2) && (argc != 3)) {
      printf("usage: print_header [-v] image_file_name\n");
      exit(-1);
    }
    if (argc == 2) {
      strcpy(filename,argv[1]);
    }
    else if (argc == 3) {
      strcpy(filename,argv[2]);
      if(strcmp(argv[1],"-v") != 0){ 
        printf("illegal flag %s !!\n",argv[1]);
      }
      else{
        verbose = TRUE;
      }
    }
    
/*
get image information
*/
    printf("print_header V1.0\n");
    dicom = (void *)spl_get_image_info(filename);
    if(dicom == (void *)-1 || dicom == (void *)NULL) {
        printf("cant open file %s\n",filename);
        exit(-1);
    }

    status = ii_get_char(dicom, "input_prefix", testchar, maxlen);
    if (status == -1){
      printf("error getting input_prefix\n");
    }
    else {
      printf("input_prefix = %s\n",testchar);
    }
    status = ii_get_char(dicom, "output_prefix", testchar, maxlen);
    if (status == -1){
      printf("error getting output_prefix\n");
    }
    else {
      printf("output_prefix = %s\n",testchar);
    }
    status = ii_get_char(dicom, "suffix", testchar, maxlen);
    if (status == -1){
      printf("error getting suffix\n");
    }
    else {
      printf("suffix = %s\n",testchar);
    }
    status = ii_get_char(dicom, "file_pattern", testchar, maxlen);
    if (status == -1){
      printf("error getting file_pattern\n");
    }
    else {
      printf("filename_format = %s\n",testchar);
    }
    status = ii_get_char(dicom, "patient_name", testchar, maxlen);
    if (status == -1){
      printf("error getting patient_name\n");
    }
    else {
      printf("patient_name = %s\n",testchar);
    }
    status = ii_get_char(dicom, "patient_sex", testchar, maxlen);
    if (status == -1){
      printf("error getting patient_sex\n");
    }
    else {
      printf("patient_sex = %s\n",testchar);
    }
    status = ii_get_char(dicom, "date", testchar, maxlen);
    if (status == -1){
      printf("error getting date\n");
    }
    else {
      printf("date = %s\n",testchar);
    }
    status = ii_get_char(dicom, "time", testchar, maxlen);
    if (status == -1){
      printf("error getting time\n");
    }
    else {
      printf("time_hr_min_sec = %s\n",testchar);
    }
    status = ii_get_char(dicom, "study_desc", testchar, maxlen);
    if (status == -1){
      printf("error getting study_desc\n");
    }
    else {
      printf("study_desc = %s\n",testchar);
    }
    status = ii_get_char(dicom, "series_desc", testchar, maxlen);
    if (status == -1){
      printf("error getting series_desc\n");
    }
    else {
      printf("series_desc = %s\n",testchar);
    }
    status = ii_get_char(dicom, "hospital_name", testchar, maxlen);
    if (status == -1){
      printf("error getting hospital_name\n");
    }
    else {
      printf("hospital_name = %s\n",testchar);
    }
    status = ii_get_char(dicom, "patient_id", testchar, maxlen);
    if (status == -1){
      printf("error getting patient_id\n");
    }
    else {
      printf("patient_id = %s\n",testchar);
    }
    status = ii_get_char(dicom, "exam_modality", testchar, maxlen);
    if (status == -1){
      printf("error getting exam_modality\n");
    }
    else {
      printf("exam_modality = %s\n",testchar);
    }
    status = ii_get_char(dicom, "image_type_text", testchar, maxlen);
    if (status == -1){
      printf("error getting image_type_text\n");
    }
    else {
      printf("image_type_text = %s\n",testchar);
    }
/*
for now, most of these are only dicom fields
*/
    status = ii_get_char(dicom, "image_type", testchar, maxlen);
      if (status == -1){
        printf("error getting image_type\n");
      }
      else {
        printf("image_type = %s\n",testchar);
      }
    status = ii_get_char(dicom, "sop_instance_uid", testchar, maxlen);
      if (status == -1){
        printf("error getting sop_instance_uid\n");
      }
      else {
        printf("sop_instance_uid = %s\n",testchar);
      }
    status = ii_get_char(dicom, "image_time", testchar, maxlen);
      if (status == -1){
        printf("error getting image_time\n");
      }
      else {
        printf("image_time = %s\n",testchar);
      }
    status = ii_get_char(dicom, "manufacturer", testchar, maxlen);
      if (status == -1){
        printf("error getting manufacturer\n");
      }
      else {
        printf("manufacturer = %s\n",testchar);
      }
    status = ii_get_char(dicom, "referring_physician", testchar, maxlen);
      if (status == -1){
        printf("error getting referring_physician\n");
      }
      else {
        printf("referring_physician = %s\n",testchar);
      }
    status = ii_get_char(dicom, "physician_reading_study", testchar, maxlen);
      if (status == -1){
        printf("error getting physician_reading_study\n");
      }
      else {
        printf("physician_reading_study = %s\n",testchar);
      }
    status = ii_get_char(dicom, "manufacturers_model_name", testchar, maxlen);
      if (status == -1){
        printf("error getting manufacturers_model_name\n");
      }
      else {
        printf("manufacturers_model_name = %s\n",testchar);
      }
    status = ii_get_char(dicom, "anatomic_structure", testchar, maxlen);
      if (status == -1){
        printf("error getting anatomic_structure\n");
      }
      else {
        printf("anatomic_structure = %s\n",testchar);
      }
    status = ii_get_char(dicom, "birth_date", testchar, maxlen);
      if (status == -1){
        printf("error getting birth_date\n");
      }
      else {
        printf("birth_date = %s\n",testchar);
      }
/* gotta add this!!!
    status = ii_get_char(dicom, "birth_weight", testchar, maxlen);
      if (status == -1){
        printf("error getting birth_weight\n");
      }
      else {
        printf("birth_weight = %s\n",testchar);
      }
*/
    status = ii_get_char(dicom, "weight", testchar, maxlen);
      if (status == -1){
        printf("error getting weight\n");
      }
      else {
        printf("weight = %s\n",testchar);
      }
    status = ii_get_char(dicom, "body_part_examined", testchar, maxlen);
      if (status == -1){
        printf("error getting body_part_examined\n");
      }
      else {
        printf("body_part_examined = %s\n",testchar);
      }
    status = ii_get_char(dicom, "repetition_time", testchar, maxlen);
      if (status == -1){
        printf("error getting repetition_time\n");
      }
      else {
        printf("repetition_time = %s\n",testchar);
      }
    status = ii_get_char(dicom, "echo_time", testchar, maxlen);
      if (status == -1){
        printf("error getting echo_time\n");
      }
      else {
        printf("echo_time = %s\n",testchar);
      }
    status = ii_get_char(dicom, "inversion_time", testchar, maxlen);
      if (status == -1){
        printf("error getting inversion_time\n");
      }
      else {
        printf("inversion_time = %s\n",testchar);
      }
    status = ii_get_char(dicom, "reconstruction_diameter", testchar, maxlen);
      if (status == -1){
        printf("error getting reconstruction_diameter\n");
      }
      else {
        printf("reconstruction_diameter = %s\n",testchar);
      }
    status = ii_get_char(dicom, "generator_power", testchar, maxlen);
      if (status == -1){
        printf("error getting generator_power\n");
      }
      else {
        printf("generator_power = %s\n",testchar);
      }
    status = ii_get_char(dicom, "series_in_study", testchar, maxlen);
      if (status == -1){
        printf("error getting series_in_study\n");
      }
      else {
        printf("series_in_study = %s\n",testchar);
      }
    status = ii_get_char(dicom, "images_in_acquisition", testchar, maxlen);
      if (status == -1){
        printf("error getting images_in_acquisition\n");
      }
      else {
        printf("images_in_acquisition = %s\n",testchar);
      }
    status = ii_get_char(dicom, "rescale_intercept", testchar, maxlen);
      if (status == -1){
        printf("error getting rescale_intercept\n");
      }
      else {
        printf("rescale_intercept = %s\n",testchar);
      }
    status = ii_get_char(dicom, "rescale_slope", testchar, maxlen);
      if (status == -1){
        printf("error getting rescale_slope\n");
      }
      else {
        printf("rescale_slope = %s\n",testchar);
      }
    status = ii_get_char(dicom, "requested_proc_desc", testchar, maxlen);
      if (status == -1){
        printf("error getting requested_proc_desc\n");
      }
      else {
        printf("requested_proc_desc = %s\n",testchar);
      }







/*
get integer fields next
*/

    status = ii_get_int(dicom, "patient_age", &testint);
    if (status == -1){
      printf("error getting patient_age\n");
    }
    else {
      printf("patient_age = %d\n",testint);
    }
    status = ii_get_int(dicom, "x_resolution", &testint);
    if (status == -1){
      printf("error getting x_resolution\n");
    }
    else {
      printf("x_resolution = %d\n",testint);
    }

    status = ii_get_int(dicom, "y_resolution", &testint);
    if (status == -1){
      printf("error getting y_resolution\n");
    }
    else {
      printf("y_resolution = %d\n",testint);
    }
    status = ii_get_int(dicom, "bytes_per_slice", &testint);
    if (status == -1){
      printf("error getting bytes_per_slice\n");
    }
    else {
      printf("bytes_per_slice = %d\n",testint);
    }
    status = ii_get_int(dicom, "header_size", &testint);
    if (status == -1){
      printf("error getting header_size\n");
    }
    else {
      printf("header_size = %d\n",testint);
    }
    status = ii_get_int(dicom, "slice_number", &testint);
    if (status == -1){
      printf("error getting slice_number\n");
    }
    else {
      printf("slice_number = %d\n",testint);
    }
    status = ii_get_int(dicom, "image_type_num", &testint);
    if (status == -1){
      printf("error getting image_type_num\n");
    }
    else {
      printf("image_type_num = %d\n",testint);
    }
    status = ii_get_int(dicom, "byte_order", &testint);
    if (status == -1){
      printf("error getting byte_order\n");
    }
    else {
      printf("byte_order = %d\n",testint);
    }
    status = ii_get_int(dicom, "status", &testint);
    if (status == -1){
      printf("error getting status\n");
    }
    else {
      printf("status = %d\n",testint);
    }
    status = ii_get_int(dicom, "number_echoes", &testint);
    if (status == -1){
      printf("error getting number_echoes\n");
    }
    else {
      printf("number_echoes = %d\n",testint);
    }
    status = ii_get_int(dicom, "echo_number", &testint);
    if (status == -1){
      printf("error getting echo_number\n");
    }
    else {
      printf("echo_number = %d\n",testint);
    }
    status = ii_get_int(dicom, "compressed", &testint);
    if (status == -1){
      printf("error getting compressed\n");
    }
    else {
      printf("compressed = %d\n",testint);
    }
    status = ii_get_int(dicom, "first_slice", &testint);
    if (status == -1){
      printf("error getting first_slice\n");
    }
    else {
      printf("first_slice = %d\n",testint);
    }
    status = ii_get_int(dicom, "last_slice", &testint);
    if (status == -1){
      printf("error getting last_slice\n");
    }
    else {
      printf("last_slice = %d\n",testint);
    }
    status = ii_get_int(dicom, "num_missing", &testint);
    if (status == -1){
      printf("error getting num_missing\n");
    }
    else {
      printf("num_missing = %d\n",testint);
    }
    status = ii_get_int(dicom, "bytes_per_pixel", &testint);
    if (status == -1){
      printf("error getting bytes_per_pixel\n");
    }
    else {
      printf("bytes_per_pixel = %d\n",testint);
    }
    status = ii_get_int(dicom, "num_bytes_data", &testint);
    if (status == -1){
      printf("error getting num_bytes_data\n");
    }
    else {
      printf("num_bytes_data = %d\n",testint);
    }
    status = ii_get_int(dicom, "num_bytes_header", &testint);
    if (status == -1){
      printf("error getting num_bytes_header\n");
    }
    else {
      printf("num_bytes_header = %d\n",testint);
    }
    status = ii_get_int(dicom, "bits_stored", &testint);
    if (status == -1){
      printf("error getting bits_stored\n");
    }
    else {
      printf("bits_stored = %d\n",testint);
    }
    status = ii_get_int(dicom, "high_bit", &testint);
    if (status == -1){
      printf("error getting high_bit\n");
    }
    else {
      printf("high_bit = %d\n",testint);
    }
    status = ii_get_int(dicom, "bits_allocated", &testint);
    if (status == -1){
      printf("error getting bits_allocated\n");
    }
    else {
      printf("bits_allocated = %d\n",testint);
    }

    status = ii_get_char(dicom, "patient_position", testchar, maxlen);
    if (status == -1){
      printf("error getting patient_position\n");
    }
    else {
      printf("patient_position = %s\n",testchar);
    }
    status = ii_get_char(dicom, "patient_orientation", testchar, maxlen);
    if (status == -1){
      printf("error getting patient_orientation\n");
    }
    else {
      printf("patient_orientation = %s\n",testchar);
    }
    status = ii_get_int(dicom, "number_of_slices", &testint);
    if (status == -1){
      printf("error getting number_of_slices\n");
    }
    else {
      printf("number_of_slices = %d\n",testint);
    }
    status = ii_get_int(dicom, "exam_number", &testint);
    if (status == -1){
      printf("error getting exam_number\n");
    }
    else {
      printf("exam_number = %d\n",testint);
    }
    status = ii_get_int(dicom, "series_number", &testint);
    if (status == -1){
      printf("error getting series_number\n");
    }
    else {
      printf("series_number = %d\n",testint);
    }
    status = ii_get_float(dicom, "gantry_tilt", &testfloat);
    if (status == -1){
      printf("error getting gantry_tilt\n");
    }
    else {
    printf("gantry_tilt = %f\n",testfloat);
    }
    status = ii_get_float(dicom, "pixel_xsize", &testfloat);
    if (status == -1){
      printf("error getting pixelxsiz\n");
    }
    else {
    printf("pixel_xsize = %f\n",testfloat);
    }
    status = ii_get_float(dicom, "pixel_ysize", &testfloat);
    if (status == -1){
      printf("error getting pixel_ysiz\n");
    }
    else {
    printf("pixel_ysize = %f\n",testfloat);
    }
    status = ii_get_float(dicom, "fov",&testfloat);
    if (status == -1){
      printf("error getting fov\n");
    }
    else {
      printf("fov =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "aspect",&testfloat);
    if (status == -1){
      printf("error getting aspect\n");
    }
    else {
      printf("aspect =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "thick",&testfloat);
    if (status == -1){
      printf("error getting thick\n");
    }
    else {
      printf("thick =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "space",&testfloat);
    if (status == -1){
      printf("error getting space\n");
    }
    else {
      printf("space =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "image_location",&testfloat);
    if (status == -1){
      printf("error getting image_location\n");
    }
    else {
      printf("image_location =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_center_r",&testfloat);
    if (status == -1){
      printf("error getting coord_center_r\n");
    }
    else {
      printf("coord_center_r =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_center_a",&testfloat);
    if (status == -1){
      printf("error getting coord_center_a\n");
    }
    else {
      printf("coord_center_a =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_center_s",&testfloat);
    if (status == -1){
      printf("error getting coord_center_s\n");
    }
    else {
      printf("coord_center_s =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_normal_r",&testfloat);
    if (status == -1){
      printf("error getting coord_normal_r\n");
    }
    else {
      printf("coord_normal_r =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_normal_a",&testfloat);
    if (status == -1){
      printf("error getting coord_normal_a\n");
    }
    else {
      printf("coord_normal_a =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_normal_s",&testfloat);
    if (status == -1){
      printf("error getting coord_normal_s\n");
    }
    else {
      printf("coord_normal_s =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_r_top_left",&testfloat);
    if (status == -1){
      printf("error getting coord_r_top_left\n");
    }
    else {
      printf("coord_r_top_left =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_a_top_left",&testfloat);
    if (status == -1){
      printf("error getting coord_a_top_left\n");
    }
    else {
      printf("coord_a_top_left =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_s_top_left",&testfloat);
    if (status == -1){
      printf("error getting coord_s_top_left\n");
    }
    else {
      printf("coord_s_top_left =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_r_top_right",&testfloat);
    if (status == -1){
      printf("error getting coord_r_top_right\n");
    }
    else {
      printf("coord_r_top_right =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_a_top_right",&testfloat);
    if (status == -1){
      printf("error getting coord_a_top_right\n");
    }
    else {
      printf("coord_a_top_right =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_s_top_right",&testfloat);
    if (status == -1){
      printf("error getting coord_s_top_right\n");
    }
    else {
      printf("coord_s_top_right =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_r_bottom_right",&testfloat);
    if (status == -1){
      printf("error getting coord_r_bottom_right\n");
    }
    else {
      printf("coord_r_bottom_right =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_a_bottom_right",&testfloat);
    if (status == -1){
      printf("error getting coord_a_bottom_right\n");
    }
    else {
      printf("coord_a_bottom_right =  %f\n",testfloat);
    }
    status = ii_get_float(dicom, "coord_s_bottom_right",&testfloat);
    if (status == -1){
      printf("error getting coord_s_bottom_right\n");
    }
    else {
      printf("coord_s_bottom_right =  %f\n",testfloat);
    }
/*
now get float vectors
*/
    status = ii_get_floatv(dicom, "imagepositionpatient",floatarr, 3);
    if (status == -1){
      printf("error getting imagepositionpatient\n");
    }
    else {
      printf("imagepositionpatient =  %f %f %f\n",floatarr[0],floatarr[1],floatarr[2]);
    }
    status = ii_get_floatv(dicom, "imageorientationpatient",floatarr, 6);
    if (status == -1){
      printf("error getting imageorientationpatient\n");
    }
    else {
      printf("imageorientationpatient =  %f %f %f %f %f %f\n",floatarr[0],floatarr[1],floatarr[2],floatarr[3],floatarr[4],floatarr[5]);
    }
    if( verbose == TRUE){
        printf("verbose mode!!\n");
/*
if -v option is selected, try to glean some additional information here
*/
/*
/*
calculate interval here - interval appears to be the distance between
adjacent image locations so we need:
file prefix
image number
number_echos
*/
    status = ii_get_char(dicom, "input_prefix", tmpfileprefix, maxlen);
    status = ii_get_char(dicom, "file_pattern", tmpfilepattern, maxlen);
    status = ii_get_int(dicom, "slice_number", &tmpimagenumber);
    status = ii_get_int(dicom, "number_echoes", &tmpnumber_echos);
    status = ii_get_float(dicom, "image_location",&tmpimagelocation);
    sprintf(tmpadjecentimage,tmpfilepattern,tmpfileprefix,tmpimagenumber+tmpnumber_echos);
    printf("adj fn = %s\n",tmpadjecentimage);

    tempptr = (void *)spl_get_image_info(tmpadjecentimage);
    status = ii_get_float(tempptr, "image_location",&testfloat);
    if (status == -1){
      printf("error getting image_location for adjacent slice\n");
    }
    else {
      printf("interval =  %f\n",tmpimagelocation-testfloat);
    }
    }

}

