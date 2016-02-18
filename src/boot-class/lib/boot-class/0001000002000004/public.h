*/

/* classes used for instanciation
/* classes used for invoke
*/

#ifndef _OZ0001000002000004P_H_
#define _OZ0001000002000004P_H_

#include "0001000002ffffff/private.h"
#include "0001000002fffffd/public.h"

#ifndef _OZ0001000002000004TYPE_
#define _OZ0001000002000004TYPE_

typedef struct OZ0001000002000004Record_Rec {
} OZ0001000002000004Record_Rec, *OZ0001000002000004Record;

typedef struct OZ0001000002000004Record_Rec_Sub {
  struct OZ_HeaderRec head;
  struct OZ0001000002000004Record_Rec data;
} OZ0001000002000004Record_Rec_Sub, *OZ0001000002000004Record_Sub;

#endif _OZ0001000002000004TYPE_


#ifndef _OBJECT_IMAGE_COMPILE_

extern int _oz_0001000002000004_AtoI (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern int _oz_0001000002000004_Compare (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array , OZ_Array );

extern OZ_Array _oz_0001000002000004_Concatenate (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array , OZ_Array );

extern OZ_Array _oz_0001000002000004_Copy (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array , OZ_Array );

extern OZ_Array _oz_0001000002000004_Duplicate (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern void _oz_0001000002000004_Free (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern unsigned int _oz_0001000002000004_Hash (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern int _oz_0001000002000004_IsEqual (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array , OZ_Array );

extern OZ_Array _oz_0001000002000004_ItoA (OZ_Object , struct OZ0001000002000004Record_Rec *, int );

extern unsigned int _oz_0001000002000004_Length (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern OZ_Array _oz_0001000002000004_ToLower (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern OZ_Array _oz_0001000002000004_ToUpper (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern OID _oz_0001000002000004_Str2OID (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array );

extern int _oz_0001000002000004_StrChr (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array , char );

extern int _oz_0001000002000004_StrRChr (OZ_Object , struct OZ0001000002000004Record_Rec *, OZ_Array , char );

#endif _OBJECT_IMAGE_COMPILE_

#endif _OZ0001000002000004P_H_
