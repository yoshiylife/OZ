00010000020003bd
*/

/* classes used for instanciation
/* classes used for invoke
00010000020003bd
*/

#ifndef _OZ000100000200029eP_H_
#define _OZ000100000200029eP_H_

#include "0001000002ffffff/private.h"
#include "00010000020003bd/public.h"
#include "000100000200006e/public.h"
#include "0001000002000404/public.h"
#include "0001000002000043/public.h"
#include "0001000002fffffd/public.h"

#ifndef _OZ000100000200029eTYPE_
#define _OZ000100000200029eTYPE_

typedef struct OZ000100000200029eRecord_Rec {
} OZ000100000200029eRecord_Rec, *OZ000100000200029eRecord;

typedef struct OZ000100000200029eRecord_Rec_Sub {
  struct OZ_HeaderRec head;
  struct OZ000100000200029eRecord_Rec data;
} OZ000100000200029eRecord_Rec_Sub, *OZ000100000200029eRecord_Sub;

#endif _OZ000100000200029eTYPE_


#ifndef _OBJECT_IMAGE_COMPILE_

extern OZ_Object _oz_000100000200029e_ToString (OZ_Object , struct OZ000100000200029eRecord_Rec *, OID );

extern OID _oz_000100000200029e_ToCID (OZ_Object , struct OZ000100000200029eRecord_Rec *, OZ_Object );

extern OID _oz_000100000200029e_ToVID (OZ_Object , struct OZ000100000200029eRecord_Rec *, OZ_Object );

extern OID _oz_000100000200029e_ToCCID (OZ_Object , struct OZ000100000200029eRecord_Rec *, OZ_Object );

#endif _OBJECT_IMAGE_COMPILE_

#endif _OZ000100000200029eP_H_
