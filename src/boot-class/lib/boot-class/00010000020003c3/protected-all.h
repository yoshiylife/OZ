#define _PROTECTED_ALL_00010000020003c3_H

#ifndef _PROTECTED_ALL_00010000020003e3_H
#define _PROTECTED_ALL_00010000020003e3_H

#ifndef _OZ00010000020003e3P_H_
#define _OZ00010000020003e3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003e2 1
#define OZClassPart0001000002fffffe_0_in_00010000020003e2 1
#define OZClassPart00010000020003e2_0_in_00010000020003e2 0

typedef struct OZ00010000020003e3Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020003e3Part_Rec, *OZ00010000020003e3Part;

#ifdef OZ_ObjectPart_Token
#undef OZ_ObjectPart_Token
#endif
#define OZ_ObjectPart_Token OZ00010000020003e3Part

#endif _OZ00010000020003e3P_H_


#endif _PROTECTED_ALL_00010000020003e3_H
#ifndef _OZ00010000020003c3P_H_
#define _OZ00010000020003c3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003c2 1
#define OZClassPart0001000002fffffe_0_in_00010000020003c2 1
#define OZClassPart00010000020003e2_0_in_00010000020003c2 -1
#define OZClassPart00010000020003e3_0_in_00010000020003c2 -1
#define OZClassPart00010000020003c2_0_in_00010000020003c2 0

typedef struct OZ00010000020003c3Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozContent;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020003c3Part_Rec, *OZ00010000020003c3Part;

#ifdef OZ_ObjectPart_StringToken
#undef OZ_ObjectPart_StringToken
#endif
#define OZ_ObjectPart_StringToken OZ00010000020003c3Part

#endif _OZ00010000020003c3P_H_


#endif _PROTECTED_ALL_00010000020003c3_H
