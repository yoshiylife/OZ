#ifndef _OZ00010000020006cfP_H_
#define _OZ00010000020006cfP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006ce 1
#define OZClassPart0001000002fffffe_0_in_00010000020006ce 1
#define OZClassPart00010000020006ce_0_in_00010000020006ce 0

typedef struct OZ00010000020006cfPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020006cfPart_Rec, *OZ00010000020006cfPart;

#ifdef OZ_ObjectPart_Collection_Assoc_String_Package__
#undef OZ_ObjectPart_Collection_Assoc_String_Package__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_Package__ OZ00010000020006cfPart

#endif _OZ00010000020006cfP_H_
