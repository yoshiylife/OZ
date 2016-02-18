#define _PROTECTED_ALL_000100000200025a_H

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
#ifndef _OZ000100000200025aP_H_
#define _OZ000100000200025aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000259 1
#define OZClassPart0001000002fffffe_0_in_0001000002000259 1
#define OZClassPart00010000020001a6_0_in_0001000002000259 -1
#define OZClassPart00010000020001a7_0_in_0001000002000259 -1
#define OZClassPart0001000002000259_0_in_0001000002000259 0

typedef struct OZ000100000200025aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200025aPart_Rec, *OZ000100000200025aPart;

#ifdef OZ_ObjectPart_NewClassListFileReader
#undef OZ_ObjectPart_NewClassListFileReader
#endif
#define OZ_ObjectPart_NewClassListFileReader OZ000100000200025aPart

#endif _OZ000100000200025aP_H_


#endif _PROTECTED_ALL_000100000200025a_H
