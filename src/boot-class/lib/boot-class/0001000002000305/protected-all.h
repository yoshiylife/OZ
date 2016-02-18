#define _PROTECTED_ALL_0001000002000305_H

#ifndef _PROTECTED_ALL_00010000020001a7_H
#define _PROTECTED_ALL_00010000020001a7_H

#ifndef _OZ00010000020001a7P_H_
#define _OZ00010000020001a7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001a6 1
#define OZClassPart0001000002fffffe_0_in_00010000020001a6 1
#define OZClassPart00010000020001a6_0_in_00010000020001a6 0

typedef struct OZ00010000020001a7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaTokenReader;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001a7Part_Rec, *OZ00010000020001a7Part;

#ifdef OZ_ObjectPart_FileReader
#undef OZ_ObjectPart_FileReader
#endif
#define OZ_ObjectPart_FileReader OZ00010000020001a7Part

#endif _OZ00010000020001a7P_H_


#endif _PROTECTED_ALL_00010000020001a7_H
#ifndef _OZ0001000002000305P_H_
#define _OZ0001000002000305P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000304 1
#define OZClassPart0001000002fffffe_0_in_0001000002000304 1
#define OZClassPart00010000020001a6_0_in_0001000002000304 -1
#define OZClassPart00010000020001a7_0_in_0001000002000304 -1
#define OZClassPart0001000002000304_0_in_0001000002000304 0

typedef struct OZ0001000002000305Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000305Part_Rec, *OZ0001000002000305Part;

#ifdef OZ_ObjectPart_PrivateDotiFileReader
#undef OZ_ObjectPart_PrivateDotiFileReader
#endif
#define OZ_ObjectPart_PrivateDotiFileReader OZ0001000002000305Part

#endif _OZ0001000002000305P_H_


#endif _PROTECTED_ALL_0001000002000305_H
