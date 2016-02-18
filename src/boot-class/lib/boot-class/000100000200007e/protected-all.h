#define _PROTECTED_ALL_000100000200007e_H

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
#ifndef _OZ000100000200007eP_H_
#define _OZ000100000200007eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200007d 1
#define OZClassPart0001000002fffffe_0_in_000100000200007d 1
#define OZClassPart00010000020001a6_0_in_000100000200007d -1
#define OZClassPart00010000020001a7_0_in_000100000200007d -1
#define OZClassPart000100000200007d_0_in_000100000200007d 0

typedef struct OZ000100000200007ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200007ePart_Rec, *OZ000100000200007ePart;

#ifdef OZ_ObjectPart_ClassListFileReader
#undef OZ_ObjectPart_ClassListFileReader
#endif
#define OZ_ObjectPart_ClassListFileReader OZ000100000200007ePart

#endif _OZ000100000200007eP_H_


#endif _PROTECTED_ALL_000100000200007e_H
