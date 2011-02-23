
/*
 * ++
 * 
 * Module:      spl_put_vol.c
 * 
 * Version:     1
 * 
 * Facility:    I/O routine
 * 
 * Abstract:    write a volume to disk
 * 
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

extern  IMAGE_INFO   p;

/*
 * Own storage:
 */

#ifndef lint
static char    *sccs_id = "@(#)get_image_info.c 6.18";
#endif

int   status;
PIXEL *image_ptr;
PIXEL *header_ptr;


int
spl_put_vol(p,v,increment)
IMAGE_INFO *p;
VOLUME *v;
int     increment;

{
int     i;
char    filename[MAXPATHLEN];
FILE    *file_ptr;

  if (v->volume == NULL){
    fprintf(stderr,"cant write null volume!!\n");
    p->status = -1;
    return(-1);
  }
  if (v->headers == NULL && p->image_type_num != 4){
    fprintf(stderr,"cant write null headers!!\n");
    p->status = -1;
    return(-1);
  }
  image_ptr=v->volume;
  header_ptr=v->headers;
  for(i=p->first_slice;i<=p->last_slice;i+=increment,image_ptr += p->bytes_per_slice/sizeof(PIXEL),header_ptr+=p->header_size/sizeof(PIXEL)){
    switch (p->image_type_num) {

    case 1: case 2: /* signa and genesis */
        sprintf(filename,"%s.%03d",p->output_prefix,i);
        break;
    case 3:
        sprintf(filename,"%s%05d.ima",p->output_prefix,i);
        break;
    case 4:
        sprintf(filename,"%s.%d",p->output_prefix,i);
        break;
    default:
        fprintf(stderr,"bad file type %d %s \n",p->image_type_num,p->image_type_text);
        p->status=-1;
        return(-1);
        break;
    }
    file_ptr = fopen(filename,"w");
    if (file_ptr == NULL){
      fprintf(stderr,"cant open file %s\n for writing",filename);
      p->status=-1;
      return(-1);
    }
    if(p->image_type_num != 4){ /* dont write that NULL header */
      status = fwrite((char *)header_ptr,1,p->header_size,file_ptr);
      if (status == 0){
        perror("spl_put_vol");
        fprintf(stderr,"cant write header for %s\n",filename);
        p->status = -1;
        return(-1);
      }
    }
    status = fwrite(image_ptr,1,p->bytes_per_slice,file_ptr);
    if (status == 0){
      perror("spl_put_vol");
      fprintf(stderr,"cant write header for %s\n",filename);
      p->status = -1;
      return(-1);
    }
    else{
      fprintf(stderr,"wrote image  %s for volume\n",filename);
    }
    status = fclose(image_ptr);
    if (status == EOF){
      perror("spl_put_vol");
      fprintf(stderr,"cant close file %s\n",filename);
      p->status = -1;
      return(-1);
    } 
  }
  return;
}
