00010000020003bd
00010000020003fa
*/

/* classes used for instanciation
/* classes used for invoke
00010000020003bd
0001000002000004
00010000020003fa
*/

#ifndef _OZ00010000020001a1P_H_
#define _OZ00010000020001a1P_H_

#include "0001000002ffffff/private.h"
#include "00010000020003bd/public.h"
#include "000100000200019a/public.h"
#include "000100000200019a/public.h"
#include "0001000002fffffd/public.h"
#include "0001000002000004/public.h"
#include "00010000020003fa/public.h"

#ifndef _OZ00010000020001a1TYPE_
#define _OZ00010000020001a1TYPE_

typedef struct OZ00010000020001a1Record_Rec {
} OZ00010000020001a1Record_Rec, *OZ00010000020001a1Record;

typedef struct OZ00010000020001a1Record_Rec_Sub {
  struct OZ_HeaderRec head;
  struct OZ00010000020001a1Record_Rec data;
} OZ00010000020001a1Record_Rec_Sub, *OZ00010000020001a1Record_Sub;

#endif _OZ00010000020001a1TYPE_


#ifndef _OBJECT_IMAGE_COMPILE_

extern void _oz_00010000020001a1_Copy (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object , OZ_Object );

extern void _oz_00010000020001a1_CopyDirectoryElement (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object , OZ_Object );

extern OZ_Object _oz_00010000020001a1_Execute (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern int _oz_00010000020001a1_IsExists (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern int _oz_00010000020001a1_IsPlainFile (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern int _oz_00010000020001a1_IsSecureFile (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern OZ_Array _oz_00010000020001a1_PrependOZHOME (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Array );

extern OZ_Array _oz_00010000020001a1_List (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern void _oz_00010000020001a1_MakeDirectory (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern void _oz_00010000020001a1_Move (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object , OZ_Object );

extern void _oz_00010000020001a1_Remove (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern void _oz_00010000020001a1_RemoveDirectory (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern OZ_Array _oz_00010000020001a1_ResizeArray (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Array , unsigned int );

extern void _oz_00010000020001a1_Symlink (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object , OZ_Object );

extern void _oz_00010000020001a1_Tar (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object , OZ_Object , OZ_Object );

extern void _oz_00010000020001a1_Touch (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object );

extern void _oz_00010000020001a1_Untar (OZ_Object , struct OZ00010000020001a1Record_Rec *, OZ_Object , OZ_Object );

#endif _OBJECT_IMAGE_COMPILE_

#endif _OZ00010000020001a1P_H_
