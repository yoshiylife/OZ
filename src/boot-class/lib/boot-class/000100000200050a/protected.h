#define _OZ000100000200050aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000509 1
#define OZClassPart0001000002fffffe_0_in_0001000002000509 1
#define OZClassPart0001000002000509_0_in_0001000002000509 0

typedef struct OZ000100000200050aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200050aPart_Rec, *OZ000100000200050aPart;

#ifdef OZ_ObjectPart_Collection_Linkable_
#undef OZ_ObjectPart_Collection_Linkable_
#endif
#define OZ_ObjectPart_Collection_Linkable_ OZ000100000200050aPart

#endif _OZ000100000200050aP_H_
