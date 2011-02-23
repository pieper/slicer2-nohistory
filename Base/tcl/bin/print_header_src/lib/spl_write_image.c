
/*
 * ++
 * 
 * Module:      spl_write_image.c
 * 
 * Version:     1
 * 
 * Facility:    I/O routine
 * 
 * Abstract:    write an image to disk
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
#include "image_info_private.h"

/*
 * Macros:
 */
/*
 * Typedefs
 */

typedef void ImageInfo;

/*
 * Own storage:
 */


int             status;

int
spl_write_image(file_prefix, header_buffer,data_buffer,ii,image_number)
char file_prefix[MAXPATHLEN];
unsigned char *header_buffer;
PIXEL *data_buffer;
ImageInfo     *ii;
int image_number;
{
FILE *file_ptr;
char filename[MAXPATHLEN];

    ImageInfo_private *iip = (ImageInfo_private *)ii;
    sprintf(filename,iip->file_pattern,file_prefix, image_number);
    file_ptr = fopen(filename,"w");
    if (file_ptr == NULL){
      fprintf(stderr,"cant open file %s\n for writing",filename);
      return(-1);
    }
    if (iip->header_size > 0){ 
      status = fwrite(header_buffer,sizeof(unsigned char),iip->header_size,file_ptr);
      if (status == 0){
        perror("spl_write_image");
        fprintf(stderr,"cant write header for %s\n",filename);
        return(-1);
      }
    }
    if (iip->swap == 2){
      swab(data_buffer,data_buffer,iip->bytes_per_slice);
    }
    status = fwrite(data_buffer,1,iip->bytes_per_slice,file_ptr);
    if (status == 0){
      perror("spl_write_image");
      fprintf(stderr,"cant write data for %s\n",filename);
      return(-1);
    }
    else{
      fprintf(stderr,"wrote image  %s \n",filename);
    }
    status = fclose(file_ptr);
    if (status == EOF){
      perror("spl_write_image");
      fprintf(stderr,"cant close file %s\n",filename);
      return(-1);
    } 
    return;
}
