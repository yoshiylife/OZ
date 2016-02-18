#define _PROTECTED_ALL_000100000200001d_H

#ifndef _OZ000100000200001dP_H_
#define _OZ000100000200001dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200001c 1
#define OZClassPart0001000002fffffe_0_in_000100000200001c 1
#define OZClassPart000100000200001c_0_in_000100000200001c 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200001dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200001dPart_Rec, *OZ000100000200001dPart;

#ifdef OZ_ObjectPart_Collection_OIDAsKey_global_CopyOfPrimaryCopyScheme_0___
#undef OZ_ObjectPart_Collection_OIDAsKey_global_CopyOfPrimaryCopyScheme_0___
#endif
#define OZ_ObjectPart_Collection_OIDAsKey_global_CopyOfPrimaryCopyScheme_0___ OZ000100000200001dPart

#endif _OZ000100000200001dP_H_


#endif _PROTECTED_ALL_000100000200001d_H
