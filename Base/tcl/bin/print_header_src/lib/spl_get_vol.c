
/*
 * ++
 * 
 * Module:      get_image_info.c
 * 
 * Version:     1
 * 
 * Facility:    I/O routine
 * 
 * Abstract:    These routines provide i/o support for a variety of medical
 * input files.
 * 
 * Currently supports: 1 signa - signa files with headers 2 genesis - genesis
 * files with headers 3 siemens - siemens files with headers noh2dvax - 2d
 * files, noheaders, VAX byte order noh2d - 2d files, noheaders
 * 
 * 
 * Environment: Sun Unix
 * 
 * Author[s]: M. C. Anderson, S. Warfield
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
#include <sys/param.h>
#include <sys/types.h>
#include <sys/file.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "image_info.h"

/*
 * Macros:
 */

/*
 * Typedefs
 */

/*
 * Own storage:
 */

#ifndef lint
static char    *sccs_id = "@(#)get_image_info.c 6.18";
#endif

int             status;
static PIXEL    *image_ptr;
static PIXEL    *header_ptr;
int             header_inc,slice_inc;

VOLUME
* spl_get_vol(p,v,increment)
IMAGE_INFO *p;
VOLUME     *v;
int        increment;
{
int     i;
char    filename[MAXPATHLEN];


  if((v->volume) == NULL){
    v->volume = (PIXEL *) malloc ( p->num_data_bytes_in_volume);
    if (v->volume == NULL) {
      perror("spl_get_vol");
      p->status = -1;
      return(NULL);
    } 
    else{
      fprintf(stderr,"allocated image space for %d pixels\n",p->num_data_bytes_in_volume);
    } 
  }
  if (v->headers == NULL){
    v->headers = (PIXEL *) malloc ( p->num_header_bytes_in_volume);
    if (v->headers == NULL) {
      perror("spl_get_vol");
      p->status = -1;
      return(NULL);
    } 
    else{
      fprintf(stderr,"allocated %d bytes for %d headers\n",p->num_header_bytes_in_volume,p->number_of_slices);
    }    
  }
  image_ptr=v->volume;
  header_ptr=v->headers;
  header_inc = p->header_size / sizeof(PIXEL);
  slice_inc = p->bytes_per_slice  / sizeof(PIXEL);
  for(i=p->first_slice;i<=p->last_slice;i+=increment,image_ptr += slice_inc,header_ptr+=slice_inc){
    switch (p->image_type_num) {

    case 1: case 2: /* signa and genesis */
        sprintf(filename,"%s.%03d",p->input_prefix,i);
        break;
    case 3:
        sprintf(filename,"%s%05d.ima",p->input_prefix,i);
        break;
    case 4:
        sprintf(filename,"%s.%d",p->input_prefix,i);
        break;
    default:
        fprintf(stderr,"bad file type %d %s \n",p->image_type_num,p->image_type_text);
        p->status=-1;
        break;
    }
    
    status = readANYfile(filename, &header_ptr, &p->header_size,
                       &image_ptr, &p->bytes_per_slice);
    if (status == -1) {
      fprintf(stderr, "can't read %s\n", filename);
      free(p->image);
      free(p->header);
      p->status = -1;
      return(NULL);
    }
    else{
      fprintf(stderr,"read image  %s for volume\n",filename);
    }
  }
  return(v);
}
