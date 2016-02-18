00010000020003bd
*/

/* classes used for instanciation
/* classes used for invoke
00010000020003bd
*/

#ifndef _OZ000100000200017aP_H_
#define _OZ000100000200017aP_H_

#include "0001000002ffffff/private.h"
#include "00010000020003bd/public.h"
#include "0001000002fffffd/public.h"

#ifndef _OZ000100000200017aTYPE_
#define _OZ000100000200017aTYPE_

typedef struct OZ000100000200017aRecord_Rec {
} OZ000100000200017aRecord_Rec, *OZ000100000200017aRecord;

typedef struct OZ000100000200017aRecord_Rec_Sub {
  struct OZ_HeaderRec head;
  struct OZ000100000200017aRecord_Rec data;
} OZ000100000200017aRecord_Rec_Sub, *OZ000100000200017aRecord_Sub;

#endif _OZ000100000200017aTYPE_


#ifndef _OBJECT_IMAGE_COMPILE_

extern OZ_Object _oz_000100000200017a_GetEnv (OZ_Object , struct OZ000100000200017aRecord_Rec *, OZ_Array );

#endif _OBJECT_IMAGE_COMPILE_

#endif _OZ000100000200017aP_H_
