#define _PROTECTED_ALL_000100000200000d_H

#ifndef _OZ000100000200000dP_H_
#define _OZ000100000200000dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200000c 1
#define OZClassPart0001000002fffffe_0_in_000100000200000c 1
#define OZClassPart000100000200000c_0_in_000100000200000c 0

typedef struct OZ000100000200000dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozID;

  /* protected (zero) */
} OZ000100000200000dPart_Rec, *OZ000100000200000dPart;

#ifdef OZ_ObjectPart_ArchitectureID
#undef OZ_ObjectPart_ArchitectureID
#endif
#define OZ_ObjectPart_ArchitectureID OZ000100000200000dPart

#endif _OZ000100000200000dP_H_


#endif _PROTECTED_ALL_000100000200000d_H
