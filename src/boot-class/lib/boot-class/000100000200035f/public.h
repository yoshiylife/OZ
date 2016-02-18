*/

/* classes used for instanciation
/* classes used for invoke
*/

#ifndef _OZ000100000200035fP_H_
#define _OZ000100000200035fP_H_

#include "0001000002ffffff/private.h"
#include "0001000002000404/public.h"

#ifndef _OZ000100000200035fTYPE_
#define _OZ000100000200035fTYPE_

typedef struct OZ000100000200035fRecord_Rec {
  unsigned int ozKind;
  OID ozPublicVID;
  OID ozProtectedVID;
  OID ozImplementationVID;
} OZ000100000200035fRecord_Rec, *OZ000100000200035fRecord;

typedef struct OZ000100000200035fRecord_Rec_Sub {
  struct OZ_HeaderRec head;
  struct OZ000100000200035fRecord_Rec data;
} OZ000100000200035fRecord_Rec_Sub, *OZ000100000200035fRecord_Sub;

#endif _OZ000100000200035fTYPE_


#ifndef _OBJECT_IMAGE_COMPILE_

extern void _oz_000100000200035f_Set (OZ_Object , struct OZ000100000200035fRecord_Rec *, unsigned int , OID , OID , OID );

#endif _OBJECT_IMAGE_COMPILE_

#endif _OZ000100000200035fP_H_
