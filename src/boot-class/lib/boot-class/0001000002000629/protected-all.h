#define _PROTECTED_ALL_0001000002000629_H

#ifndef _OZ0001000002000629P_H_
#define _OZ0001000002000629P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000628 1
#define OZClassPart0001000002fffffe_0_in_0001000002000628 1
#define OZClassPart0001000002000628_0_in_0001000002000628 0

typedef struct OZ0001000002000629Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000629Part_Rec, *OZ0001000002000629Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_ProjectLinkSS__
#undef OZ_ObjectPart_Collection_Assoc_String_ProjectLinkSS__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_ProjectLinkSS__ OZ0001000002000629Part

#endif _OZ0001000002000629P_H_


#endif _PROTECTED_ALL_0001000002000629_H
