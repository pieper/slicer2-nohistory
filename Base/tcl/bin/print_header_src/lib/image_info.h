#include <sys/param.h>
#define II_ERROR -1
#define II_OK 0
#define    MAX_NUM_IMAGES    1024
typedef unsigned short PIXEL; 
typedef struct {
    char    patname[40];  /* patient name */
    char    date[40]; /* date of study scan */
        char    patient_orientation[10];  /* a combination of  2 of: A P R L F H */
        char    patient_position[10]; /* HFP HFS HFDR HFDL FFDL FFDR FFP FFS */
    char     hospital_name[40]; /* name of hospital */
    char     patient_id[13]; /* the unique patient ID */
    unsigned short exam_number;  /* the exam or study number */
    short     patient_age; /* age of patient */
    char     patient_sex[3]; /* M or F */
    char    exam_modality[10]; /* scan modality i.e. MR,  CT */
    unsigned short    series_number; /* series associated with this image */
    char    study_desc[256]; /* study description */
    char    series_desc[256]; /* series description */
    int    cols; /* formerly x_resolution - the number of pixels across the image*/
    int    rows; /* formerly y_resolution - the number of rows of pixels in  the image*/
    int    bytes_per_slice; /* number of bytes of data in the image */
    int    header_size; /* number of bytes in the header */
    float    pixel_xsize; /* formerly pixel_size - x and y size are potentially different w/ dicom  measured in mm */
    float    pixel_ysize; /* formerly pixel_size in mm */
    float    fov; /* field of view of image in mm */
    float    aspect; /* aspect ratio - the ratio of pixel_size in Z direction to it's in-plane resolution */
    float    thick; /* image thickness in mm */
    float    space; /* the space bewteen slices */
    int    slice_number; /* number of this image */
    char    file_pattern[80]; /* describes how to format an image i.e. %s.%03d for our dicom, genesis, and signa images */
    char    filename[MAXPATHLEN]; /* filename of this image */
    int    byte_order; /*"bigendian" or "littleendian" */
    int    image_type_num; /* a number assiociated with the type of this image i.e. signa = 1, siemens = 3 */
    char    input_prefix[MAXPATHLEN]; /* file prefix - typically the part
of the string describing filename up to I */
    int     number_echoes; /* number of channels or echoes associated with this image */
    int     echo_number; /* echo number of this image */
    int    bytes_per_pixel; /* bytes per pixel - usually 2  */
    int     compressed; /* 1 --> compressed  */
    int     first_slice; /* first slice in the series of this image */
    int     last_slice; /* last slice in the series of this image */
    int    number_of_slices; /* number of slices in the series of this image */

    int     num_missing; /* number of slices missing in this series */
    
    char    image_type_text[80]; /* text describing the type of this image - i.e. "siemens" */
    char    output_prefix[MAXPATHLEN]; /* output prefix if applicable */
    char    suffix[80]; /*   if images are compress, this will contain ".gz" or ".Z"*/
    PIXEL    *image ; /* pointer to this image, currently not used  */
    caddr_t    header; /* pointer to header of this image, currently not used  */
    int     status; /* -1 ==> something is wrong */
    int    num_data_bytes_in_volume; /* amount of data in the volume of data associated with this image */
    int    num_header_bytes_in_volume; /* amount of bytes of header  in the volume of data associated with this image */
    int    missing[MAX_NUM_IMAGES]; /* describes which images are missing from this series,  if any */
    int    swap; /* set to 1 if the data is swapped from Sun byte order */


/*
co-ordinate information next 
*/
    float     coord_center_r;
    float     coord_center_a;
    float     coord_center_s;
    float     coord_normal_r;
    float     coord_normal_a;
    float     coord_normal_s;
    float     coord_r_top_left;
    float     coord_a_top_left;
    float     coord_s_top_left;
    float     coord_r_top_right;
    float     coord_a_top_right;
    float     coord_s_top_right;
    float     coord_r_bottom_right;
    float     coord_a_bottom_right;
    float     coord_s_bottom_right;
} IMAGE_INFO;
typedef struct {
    PIXEL    *volume;
    PIXEL     *headers;
} VOLUME;
