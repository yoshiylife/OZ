#define _PROTECTED_ALL_000100000200052a_H

#ifndef _OZ000100000200052aP_H_
#define _OZ000100000200052aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000529 1
#define OZClassPart0001000002fffffe_0_in_0001000002000529 1
#define OZClassPart0001000002000529_0_in_0001000002000529 0

typedef struct OZ000100000200052aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200052aPart_Rec, *OZ000100000200052aPart;

#ifdef OZ_ObjectPart_Collection_Token_
#undef OZ_ObjectPart_Collection_Token_
#endif
#define OZ_ObjectPart_Collection_Token_ OZ000100000200052aPart

#endif _OZ000100000200052aP_H_


#endif _PROTECTED_ALL_000100000200052a_H
