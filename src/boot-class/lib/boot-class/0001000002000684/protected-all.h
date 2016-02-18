#define _PROTECTED_ALL_0001000002000684_H

#ifndef _OZ0001000002000684P_H_
#define _OZ0001000002000684P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000683 1
#define OZClassPart0001000002fffffe_0_in_0001000002000683 1
#define OZClassPart0001000002000683_0_in_0001000002000683 0

typedef struct OZ0001000002000684Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozSubdirectories;
  OZ_Object ozEntries;
  OZ_Object ozDebug;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000684Part_Rec, *OZ0001000002000684Part;

#ifdef OZ_ObjectPart_Directory_Package_
#undef OZ_ObjectPart_Directory_Package_
#endif
#define OZ_ObjectPart_Directory_Package_ OZ0001000002000684Part

#endif _OZ0001000002000684P_H_


#endif _PROTECTED_ALL_0001000002000684_H
