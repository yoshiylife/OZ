#ifndef _PROTECTED_ALL_00010000020007b8_H
#define _PROTECTED_ALL_00010000020007b8_H

#ifndef _OZ00010000020007b8P_H_
#define _OZ00010000020007b8P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007b7 1
#define OZClassPart0001000002fffffe_0_in_00010000020007b7 1
#define OZClassPart00010000020007b7_0_in_00010000020007b7 0

typedef struct OZ00010000020007b8Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozSubdirectories;
  OZ_Object ozEntries;
  OZ_Object ozDebug;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020007b8Part_Rec, *OZ00010000020007b8Part;

#ifdef OZ_ObjectPart_Directory_global_ResolvableObject_
#undef OZ_ObjectPart_Directory_global_ResolvableObject_
#endif
#define OZ_ObjectPart_Directory_global_ResolvableObject_ OZ00010000020007b8Part

#endif _OZ00010000020007b8P_H_


#endif _PROTECTED_ALL_00010000020007b8_H
