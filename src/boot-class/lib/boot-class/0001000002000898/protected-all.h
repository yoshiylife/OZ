#ifndef _PROTECTED_ALL_0001000002000898_H
#define _PROTECTED_ALL_0001000002000898_H

#ifndef _OZ0001000002000898P_H_
#define _OZ0001000002000898P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000897 1
#define OZClassPart0001000002fffffe_0_in_0001000002000897 1
#define OZClassPart0001000002000897_0_in_0001000002000897 0

typedef struct OZ0001000002000898Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000898Part_Rec, *OZ0001000002000898Part;

#ifdef OZ_ObjectPart_Collection_MirrorOperation_
#undef OZ_ObjectPart_Collection_MirrorOperation_
#endif
#define OZ_ObjectPart_Collection_MirrorOperation_ OZ0001000002000898Part

#endif _OZ0001000002000898P_H_


#endif _PROTECTED_ALL_0001000002000898_H
