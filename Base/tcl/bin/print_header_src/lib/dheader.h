/*============================================================================**

dheader.h

Platform: Sun UltraSPARC 2170 / Solaris 2.5.1 / DeJarnette AN/API

Revision History:
1997?       sdd  Creation of original read_image.h on SunOS 4.1.4
1997.09.02  sdd  Port from SunOS and rewrite

**============================================================================*/

#include "anilib.h"

#define UNKNOWN_ELEMENT -0x0001  /* !!! must be different from CHAR_ELEMENT et al
                                        in anilib.h */

enum vr { VR_UNKNOWN=0, VR_CHAR, VR_US, VR_SS, VR_UL, VR_SL,
          VR_FLOAT, VR_DOUBLE, VR_VAR, VR_SEQ, VR_DELIM };

struct wanted_elem {
   UINT16 group;
   UINT16 elem;
   char vr[3];
   int type;   /* one of enum vr */
   union {
      char   *c;
      UINT16 *us;
      INT16  *ss;
      UINT32 *ul;
      INT32  *sl;
      float  *f;
      double *d;
   } valp;
   int status;  /* <=-3 = error
                     -2 = element found, but with no value
                     -1 = element not found
                      0 = didn't try (e.g., encountered error before seeking this elem)
                    >=1 = byte-length of value (VM could be >1) */
};

int dheader(const char *, const int, struct wanted_elem *);

/*============================================================================**
   EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF  EOF
**============================================================================*/

