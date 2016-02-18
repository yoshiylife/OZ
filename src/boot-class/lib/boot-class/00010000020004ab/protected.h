#define _OZ00010000020004abP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004aa 1
#define OZClassPart0001000002fffffe_0_in_00010000020004aa 1
#define OZClassPart0001000002000499_0_in_00010000020004aa -2
#define OZClassPart000100000200049a_0_in_00010000020004aa -2
#define OZClassPart00010000020004af_0_in_00010000020004aa -1
#define OZClassPart00010000020004b0_0_in_00010000020004aa -1
#define OZClassPart00010000020004aa_0_in_00010000020004aa 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020004abPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020004abPart_Rec, *OZ00010000020004abPart;

#ifdef OZ_ObjectPart_OrderedCollection_OIDAsKey_0__
#undef OZ_ObjectPart_OrderedCollection_OIDAsKey_0__
#endif
#define OZ_ObjectPart_OrderedCollection_OIDAsKey_0__ OZ00010000020004abPart

#endif _OZ00010000020004abP_H_
