#define _PROTECTED_ALL_0001000002000328_H

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
#ifndef _OZ0001000002000328P_H_
#define _OZ0001000002000328P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000327 1
#define OZClassPart0001000002fffffe_0_in_0001000002000327 1
#define OZClassPart00010000020001a6_0_in_0001000002000327 -1
#define OZClassPart00010000020001a7_0_in_0001000002000327 -1
#define OZClassPart0001000002000327_0_in_0001000002000327 0

typedef struct OZ0001000002000328Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000328Part_Rec, *OZ0001000002000328Part;

#ifdef OZ_ObjectPart_PrivateDotsFileReader
#undef OZ_ObjectPart_PrivateDotsFileReader
#endif
#define OZ_ObjectPart_PrivateDotsFileReader OZ0001000002000328Part

#endif _OZ0001000002000328P_H_


#endif _PROTECTED_ALL_0001000002000328_H
