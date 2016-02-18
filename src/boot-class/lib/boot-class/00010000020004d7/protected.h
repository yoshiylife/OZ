#define _OZ00010000020004d7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004d6 1
#define OZClassPart0001000002fffffe_0_in_00010000020004d6 1
#define OZClassPart00010000020004d6_0_in_00010000020004d6 0

typedef struct OZ00010000020004d7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020004d7Part_Rec, *OZ00010000020004d7Part;

#ifdef OZ_ObjectPart_Collection_ProjectLinkSS_
#undef OZ_ObjectPart_Collection_ProjectLinkSS_
#endif
#define OZ_ObjectPart_Collection_ProjectLinkSS_ OZ00010000020004d7Part

#endif _OZ00010000020004d7P_H_
