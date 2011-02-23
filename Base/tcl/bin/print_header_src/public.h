
/* Mark's SPL IO include file */

#ifndef __PUBLIC_H_INCLUDED
#define __PUBLIC_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

typedef void ImageInfo;

ImageInfo *spl_get_image_info(char *path);
int spl_read_image(unsigned char **headerBuffer, unsigned  short         **data,ImageInfo     *ii,int           image_number);

int ii_get_int(ImageInfo *info, char *kw, int *f);
int ii_get_float(ImageInfo *info, char *kw, float *f);

int ii_get_string(ImageInfo *info, char *kw, char *str, int maxlen);
int ii_get_char(ImageInfo *info, char *kw, char *str, int maxlen);

int ii_get_floatv(ImageInfo *info, char *kw, float *f, int nfloats);

int ii_get_intv(ImageInfo *info, char *kw, int *d, int nints);

int ii_get_bytev(ImageInfo *info, char *kw, unsigned char *b, int nbytes);

#ifdef __cplusplus
}
#endif

#endif
